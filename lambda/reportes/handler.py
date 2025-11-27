# lambda/reportes/handler.py

import json
import os
import decimal
from datetime import datetime
from collections import Counter

import boto3
from boto3.dynamodb.conditions import Attr

# ---------------------------
# Configuración DynamoDB
# ---------------------------

TABLE_NAME = (
    os.environ.get("TABLE_NAME")
    or os.environ.get("DYNAMODB_TABLE_NAME")
)
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


# ---------------------------
# Helpers genéricos
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


def _parse_qs(event):
    return event.get("queryStringParameters") or {}


def _parse_iso(date_str: str):
    """
    Intenta parsear ISO 'YYYY-MM-DD' o 'YYYY-MM-DDTHH:MM:SSZ'.
    Devuelve datetime o None.
    """
    if not date_str:
        return None
    try:
        if "T" in date_str:
            # 2025-12-01T09:00:00Z
            return datetime.fromisoformat(
                date_str.replace("Z", "+00:00")
            )
        # 2025-12-01
        return datetime.fromisoformat(date_str)
    except Exception:
        return None


# ---------------------------
# Filtro base por rol
# ---------------------------

def _build_role_filter(claims, qs):
    """
    Devuelve (filter_expr, error_msg).
    filter_expr: expresión de filtro de boto3 (o None para sin restricción por abogado).
    error_msg: string si hay error de permisos; si es None, ok.
    """
    groups = _get_groups_from_claims(claims)
    username = _get_username_from_claims(claims)
    qs_abogado = qs.get("abogado_id")

    # ADMIN: puede ver todo, opcionalmente filtrar por abogado_id de querystring
    if "ADMINISTRADOR" in groups:
        if qs_abogado:
            return Attr("abogado_id").eq(qs_abogado), None
        return None, None

    # ABOGADO: solo sus audiencias
    if "ABOGADO" in groups:
        abogado_id_claim = claims.get("custom:abogado_id") or username
        return Attr("abogado_id").eq(abogado_id_claim), None

    # SECRETARIA: abogados asignados
    if "SECRETARIA" in groups:
        raw_asignados = claims.get("custom:abogados_asignados", "")
        abogados_asignados = [
            a.strip() for a in raw_asignados.split(",") if a.strip()
        ]
        if not abogados_asignados:
            return None, (
                "SECRETARIA sin abogados asignados "
                "(custom:abogados_asignados vacío)."
            )

        # Si se pidió abogado_id concreto y está en la lista, filtramos solo ese
        if qs_abogado and qs_abogado in abogados_asignados:
            return Attr("abogado_id").eq(qs_abogado), None

        # Si no, OR de todos los asignados
        expr = None
        for a in abogados_asignados:
            cond = Attr("abogado_id").eq(a)
            expr = cond if expr is None else expr | cond
        return expr, None

    return None, "Rol no autorizado para consultar reportes."


def _scan_with_filter(base_filter, extra_filter=None):
    """
    Hace un scan con un filtro base de rol y un filtro extra (estado/fecha).
    """
    if base_filter is not None and extra_filter is not None:
        filter_expr = base_filter & extra_filter
    elif base_filter is not None:
        filter_expr = base_filter
    else:
        filter_expr = extra_filter

    scan_kwargs = {}
    if filter_expr is not None:
        scan_kwargs["FilterExpression"] = filter_expr

    items = []
    resp = table.scan(**scan_kwargs)
    items.extend(resp.get("Items", []))

    while "LastEvaluatedKey" in resp:
        resp = table.scan(
            ExclusiveStartKey=resp["LastEvaluatedKey"], **scan_kwargs
        )
        items.extend(resp.get("Items", []))

    return items


def _build_summary_by_estado(items):
    counter = Counter()
    for it in items:
        estado = it.get("estado", "DESCONOCIDO")
        counter[estado] += 1
    return dict(counter)


# ---------------------------
# Reportes
# ---------------------------

def _reporte_por_abogado(event, claims):
    """
    GET /reportes?tipo=por_abogado&abogado_id=...&desde=YYYY-MM-DD&hasta=YYYY-MM-DD

    - Admin: puede pedir cualquier abogado_id.
    - Abogado: se ignora abogado_id de query y se usa el suyo.
    - Secretaria: filtrada por abogados asignados.
    """
    qs = _parse_qs(event)

    # Rango de fechas (opcional, pero recomendado)
    desde = _parse_iso(qs.get("desde"))
    hasta = _parse_iso(qs.get("hasta"))

    if (qs.get("desde") or qs.get("hasta")) and (not desde or not hasta):
        return _response(
            400,
            {
                "message": (
                    "Formato de fechas inválido. Usa 'YYYY-MM-DD' "
                    "o 'YYYY-MM-DDTHH:MM:SSZ'."
                )
            },
        )

    base_filter, err = _build_role_filter(claims, qs)
    if err:
        return _response(403, {"message": err})

    # Si tenemos rango de fechas, filtramos por fecha BETWEEN en DynamoDB (strings ISO).
    extra_filter = None
    if desde and hasta:
        # Usamos las strings originales para between
        extra_filter = Attr("fecha").between(
            qs.get("desde"),
            qs.get("hasta"),
        )

    items = _scan_with_filter(base_filter, extra_filter)

    # También filtramos por fechas en Python por seguridad
    if desde and hasta:
        items_filtered = []
        for it in items:
            f = _parse_iso(it.get("fecha", ""))
            if not f:
                continue
            if desde <= f <= hasta:
                items_filtered.append(it)
        items = items_filtered

    resumen = _build_summary_by_estado(items)

    return _response(
        200,
        {
            "tipo": "por_abogado",
            "filtros": {
                "abogado_id": qs.get("abogado_id"),
                "desde": qs.get("desde"),
                "hasta": qs.get("hasta"),
            },
            "total_audiencias": len(items),
            "resumen_por_estado": resumen,
            "items": items,
        },
    )


def _reporte_por_estado(event, claims):
    """
    GET /reportes?tipo=por_estado&estado=PENDIENTE&desde=...&hasta=...

    Devuelve audiencias por estado (PENDIENTE, REALIZADA, CANCELADA, etc.)
    respetando siempre el alcance del rol (ADMIN, ABOGADO, SECRETARIA).
    """
    qs = _parse_qs(event)
    estado = qs.get("estado", "PENDIENTE")

    desde = _parse_iso(qs.get("desde"))
    hasta = _parse_iso(qs.get("hasta"))

    if (qs.get("desde") or qs.get("hasta")) and (not desde or not hasta):
        return _response(
            400,
            {
                "message": (
                    "Formato de fechas inválido. Usa 'YYYY-MM-DD' "
                    "o 'YYYY-MM-DDTHH:MM:SSZ'."
                )
            },
        )

    base_filter, err = _build_role_filter(claims, qs)
    if err:
        return _response(403, {"message": err})

    # Filtro por estado
    extra_filter = Attr("estado").eq(estado)

    # Si también hay rango de fechas, combinamos
    if desde and hasta:
        extra_filter = extra_filter & Attr("fecha").between(
            qs.get("desde"),
            qs.get("hasta"),
        )

    items = _scan_with_filter(base_filter, extra_filter)

    # Filtrado fino por fecha en Python (opcional pero más seguro)
    if desde and hasta:
        items_filtered = []
        for it in items:
            f = _parse_iso(it.get("fecha", ""))
            if not f:
                continue
            if desde <= f <= hasta:
                items_filtered.append(it)
        items = items_filtered

    resumen = _build_summary_by_estado(items)

    return _response(
        200,
        {
            "tipo": "por_estado",
            "filtros": {
                "estado": estado,
                "desde": qs.get("desde"),
                "hasta": qs.get("hasta"),
            },
            "total_audiencias": len(items),
            "resumen_por_estado": resumen,
            "items": items,
        },
    )


# ---------------------------
# Handler principal
# ---------------------------

def lambda_handler(event, context):
    """
    RUTA: GET /reportes

    Querystring:
      - tipo=por_abogado | por_estado   (por defecto: por_estado)
      - abogado_id=...                  (por_abogado)
      - estado=PENDIENTE|REALIZADA|...  (por_estado, default PENDIENTE)
      - desde=YYYY-MM-DD(THH:MM:SSZ)
      - hasta=YYYY-MM-DD(THH:MM:SSZ)
    """
    route_key = (
        event.get("requestContext", {})
        .get("routeKey", "")
        .upper()
    )

    if route_key != "GET /REPORTES":
        return _response(
            404,
            {"message": f"Ruta no soportada en reportes: {route_key}"},
        )

    claims = _get_claims(event)
    qs = _parse_qs(event)
    tipo = (qs.get("tipo") or "por_estado").lower()

    if tipo == "por_abogado":
        return _reporte_por_abogado(event, claims)

    # default: por_estado
    return _reporte_por_estado(event, claims)
