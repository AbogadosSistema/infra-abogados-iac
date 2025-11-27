# lambda/audiencias/handler.py

import json
import os
import decimal
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ.get("TABLE_NAME")
table = dynamodb.Table(TABLE_NAME)


# ---------------------------
# Helpers
# ---------------------------

class DecimalEncoder(json.JSONEncoder):
    """Permite serializar Decimals de DynamoDB a JSON."""

    def default(self, obj):
        if isinstance(obj, decimal.Decimal):
            if obj % 1 == 0:
                return int(obj)
            return float(obj)
        return super().default(obj)


def _response(status_code: int, body: dict):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
        },
        "body": json.dumps(body, cls=DecimalEncoder),
    }


def _parse_body(event):
    body = event.get("body")
    if not body:
        return {}
    if isinstance(body, dict):
        return body
    try:
        return json.loads(body)
    except json.JSONDecodeError:
        return {}


def _get_claims(event):
    """Extrae claims del JWT (Cognito HTTP API v2)."""
    return (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("jwt", {})
        .get("claims", {})
        or {}
    )


def _get_groups_from_claims(claims):
    """Extrae lista de grupos (roles) desde cognito:groups."""
    raw = claims.get("cognito:groups")
    if isinstance(raw, list):
        return raw

    if isinstance(raw, str):
        # Puede venir como 'ADMINISTRADOR' o como '["ADMINISTRADOR"]'
        try:
            if raw.startswith("["):
                parsed = json.loads(raw)
                if isinstance(parsed, list):
                    return parsed
        except Exception:
            pass
        return [raw]

    return []


def _get_username_from_claims(claims):
    return (
        claims.get("cognito:username")
        or claims.get("username")
        or claims.get("email")
    )


def _now_iso():
    return datetime.now(timezone.utc).isoformat()


# ---------------------------
# Lógica de negocio
# ---------------------------

def handle_health(event):
    return _response(
        200,
        {
            "message": "Lambda audiencias OK",
            "input": {
                "routeKey": event.get("requestContext", {}).get("routeKey"),
            },
        },
    )


def handle_get_audiencias(event, claims):
    """GET /audiencias

    - ADMINISTRADOR: ve todas (con filtros opcionales).
    - ABOGADO: solo sus audiencias (abogado_id = username o custom:abogado_id).
    - SECRETARIA: audiencias de los abogados asignados (custom:abogados_asignados).
    """
    groups = _get_groups_from_claims(claims)
    username = _get_username_from_claims(claims)

    qs = event.get("queryStringParameters") or {}
    filtro_estado = qs.get("estado")
    filtro_abogado = qs.get("abogado_id")

    # Construimos un FilterExpression según el rol
    filter_expr = None

    if "ADMINISTRADOR" in groups:
        # Admin ve todo, con filtros opcionales
        if filtro_abogado:
            filter_expr = Attr("abogado_id").eq(filtro_abogado)
        if filtro_estado:
            expr_estado = Attr("estado").eq(filtro_estado)
            filter_expr = expr_estado if filter_expr is None else filter_expr & expr_estado

    elif "ABOGADO" in groups:
        # Abogado solo ve las suyas
        abogado_id_claim = claims.get("custom:abogado_id") or username
        filter_expr = Attr("abogado_id").eq(abogado_id_claim)
        if filtro_estado:
            filter_expr = filter_expr & Attr("estado").eq(filtro_estado)

    elif "SECRETARIA" in groups:
        # Secretaria ve audiencias de abogados asignados.
        # Se asume un claim custom:abogados_asignados con IDs separados por coma, ej: "abogado1,abogado2"
        raw_asignados = claims.get("custom:abogados_asignados", "")
        abogados_asignados = [
            a.strip() for a in raw_asignados.split(",") if a.strip()
        ]
        if not abogados_asignados:
            return _response(
                403,
                {
                    "message": "SECRETARIA sin abogados asignados (custom:abogados_asignados vacío).",
                },
            )

        # Si viene abogado_id en query, filtramos solo por ese dentro de la lista
        if filtro_abogado and filtro_abogado in abogados_asignados:
            filter_expr = Attr("abogado_id").eq(filtro_abogado)
        else:
            # Construimos expr abogado_id IN (lista). DynamoDB no tiene IN directo, así que usamos OR.
            expr = None
            for a in abogados_asignados:
                cond = Attr("abogado_id").eq(a)
                expr = cond if expr is None else expr | cond
            filter_expr = expr

        if filtro_estado:
            filter_expr = filter_expr & Attr("estado").eq(filtro_estado)

    else:
        return _response(
            403,
            {"message": "Rol no autorizado para listar audiencias."},
        )

    scan_kwargs = {}
    if filter_expr is not None:
        scan_kwargs["FilterExpression"] = filter_expr

    items = []
    resp = table.scan(**scan_kwargs)
    items.extend(resp.get("Items", []))
    # Si algún día hay paginación:
    while "LastEvaluatedKey" in resp:
        resp = table.scan(
            ExclusiveStartKey=resp["LastEvaluatedKey"], **scan_kwargs
        )
        items.extend(resp.get("Items", []))

    return _response(
        200,
        {
            "items": items,
            "count": len(items),
        },
    )


def handle_post_audiencia(event, claims):
    """POST /audiencias: crear audiencia."""
    body = _parse_body(event)

    required = ["id_audiencia", "abogado_id", "fecha", "sala", "estado"]
    missing = [f for f in required if not body.get(f)]
    if missing:
        return _response(
            400,
            {
                "message": "Campos obligatorios faltantes.",
                "missing": missing,
            },
        )

    item = {
        "id_audiencia": body["id_audiencia"],
        "abogado_id": body["abogado_id"],
        "fecha": body["fecha"],
        "sala": body["sala"],
        "estado": body["estado"],
        "created_at": _now_iso(),
    }

    # Campos opcionales
    opcionals = ["secretaria_id", "descripcion", "tipo", "juzgado"]
    for f in opcionals:
        if f in body:
            item[f] = body[f]

    try:
        table.put_item(
            Item=item,
            ConditionExpression=Attr("id_audiencia").not_exists(),
        )
    except table.meta.client.exceptions.ConditionalCheckFailedException:
        return _response(
            409,
            {
                "message": "Ya existe una audiencia con ese id_audiencia.",
            },
        )

    return _response(
        201,
        {
            "message": "Audiencia creada.",
            "item": item,
        },
    )


def handle_put_audiencia(event, claims):
    """PUT /audiencias: actualizar audiencia existente."""
    body = _parse_body(event)
    id_audiencia = body.get("id_audiencia")

    if not id_audiencia:
        return _response(
            400, {"message": "id_audiencia es obligatorio para actualizar."}
        )

    # Campos que se pueden actualizar
    updatable_fields = ["abogado_id", "fecha", "sala", "estado", "descripcion", "tipo", "juzgado"]
    set_expr_parts = []
    expr_attr_values = {}
    for f in updatable_fields:
        if f in body:
            set_expr_parts.append(f"{f} = :{f}")
            expr_attr_values[f":{f}"] = body[f]

    if not set_expr_parts:
        return _response(
            400,
            {"message": "No se enviaron campos para actualizar."},
        )

    # Siempre actualizamos updated_at
    set_expr_parts.append("updated_at = :updated_at")
    expr_attr_values[":updated_at"] = _now_iso()

    update_expr = "SET " + ", ".join(set_expr_parts)

    try:
        resp = table.update_item(
            Key={"id_audiencia": id_audiencia},
            UpdateExpression=update_expr,
            ExpressionAttributeValues=expr_attr_values,
            ConditionExpression=Attr("id_audiencia").exists(),
            ReturnValues="ALL_NEW",
        )
    except table.meta.client.exceptions.ConditionalCheckFailedException:
        return _response(
            404,
            {"message": "La audiencia no existe."},
        )

    return _response(
        200,
        {
            "message": "Audiencia actualizada.",
            "item": resp.get("Attributes", {}),
        },
    )


def handle_delete_audiencia(event, claims):
    """DELETE /audiencias: marcar como cancelada (soft delete)."""

    qs = event.get("queryStringParameters") or {}
    id_audiencia = qs.get("id_audiencia")

    if not id_audiencia:
        # También permitimos pasarlo en body
        body = _parse_body(event)
        id_audiencia = body.get("id_audiencia")

    if not id_audiencia:
        return _response(
            400,
            {
                "message": "id_audiencia es obligatorio para eliminar/cancelar.",
            },
        )

    try:
        resp = table.update_item(
            Key={"id_audiencia": id_audiencia},
            UpdateExpression="SET estado = :estado, cancelada_en = :cancelada_en",
            ExpressionAttributeValues={
                ":estado": "CANCELADA",
                ":cancelada_en": _now_iso(),
            },
            ConditionExpression=Attr("id_audiencia").exists(),
            ReturnValues="ALL_NEW",
        )
    except table.meta.client.exceptions.ConditionalCheckFailedException:
        return _response(
            404,
            {"message": "La audiencia no existe."},
        )

    return _response(
        200,
        {
            "message": "Audiencia marcada como CANCELADA.",
            "item": resp.get("Attributes", {}),
        },
    )


# ---------------------------
# Handler principal
# ---------------------------

def lambda_handler(event, context):
    """
    Enruta según routeKey de API Gateway HTTP API v2.

    Rutas:
      - GET  /health
      - GET  /audiencias
      - POST /audiencias
      - PUT  /audiencias
      - DELETE /audiencias
    """
    route_key = (
        event.get("requestContext", {})
        .get("routeKey", "")
        .upper()
    )

    if route_key == "GET /HEALTH":
        return handle_health(event)

    claims = _get_claims(event)

    if route_key == "GET /AUDIENCIAS":
        return handle_get_audiencias(event, claims)

    if route_key == "POST /AUDIENCIAS":
        return handle_post_audiencia(event, claims)

    if route_key == "PUT /AUDIENCIAS":
        return handle_put_audiencia(event, claims)

    if route_key == "DELETE /AUDIENCIAS":
        return handle_delete_audiencia(event, claims)

    # Ruta no soportada
    return _response(
        404,
        {
            "message": f"Ruta no soportada: {route_key}",
        },
    )
