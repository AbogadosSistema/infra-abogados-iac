# lambda/audiencias/handler.py
import json
import os
from decimal import Decimal
from datetime import datetime
import logging

import boto3
from botocore.exceptions import ClientError

# ----------------- logging base -----------------
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# ----------------- DynamoDB -----------------
dynamodb = boto3.resource("dynamodb")

# Aceptar cualquiera de los dos nombres (por Terraform usamos DYNAMODB_TABLE_NAME)
TABLE_NAME = os.environ.get("DYNAMODB_TABLE_NAME") or os.environ.get("TABLE_NAME")

if not TABLE_NAME:
    logger.error(
        "No se encontró DYNAMODB_TABLE_NAME ni TABLE_NAME en las variables de entorno."
    )
    table = None
else:
    logger.info(f"Inicializando DynamoDB.Table con nombre: {TABLE_NAME}")
    table = dynamodb.Table(TABLE_NAME)


def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError(f"Tipo no serializable: {type(obj)}")


def build_response(status_code, body):
    """
    Envuelve la respuesta en el formato esperado por HTTP API (Lambda proxy).
    Si hubiera un error al serializar el body, lo registramos y devolvemos
    un 500 sencillo.
    """
    try:
        body_str = json.dumps(body, default=decimal_default)
    except Exception as e:
        logger.error("Error serializando body de respuesta: %s", e, exc_info=True)
        status_code = 500
        body_str = json.dumps({"message": "Error interno serializando respuesta"})

    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
            "Access-Control-Allow-Methods": "GET,POST,DELETE,OPTIONS",
        },
        "body": body_str,
    }


def get_claims(event):
    """Extrae claims de JWT en HTTP API (APIGW v2 + JWT authorizer)."""
    rc = event.get("requestContext", {})
    auth = rc.get("authorizer") or {}
    jwt = auth.get("jwt") or {}
    claims = jwt.get("claims") or {}

    try:
        logger.info("Claims JWT extraídos: %s", json.dumps(claims, default=str))
    except Exception:
        logger.warning("No se pudieron loguear los claims JWT.")

    return claims


def get_role_context(event):
    """
    Obtiene:
      - rol: ADMINISTRADOR / SECRETARIA / ABOGADO
      - username: nombre de usuario Cognito (admin1, abogado1, etc.)
      - abogados_asignados: lista de abogados asignados a la SECRETARIA
    El rol se toma de cognito:groups (preferido) y como fallback de custom:rol.
    """
    claims = get_claims(event)

    username = claims.get("cognito:username") or claims.get("username")

    # cognito:groups puede venir como lista o como string "ADMINISTRADOR,OTRO"
    groups_claim = claims.get("cognito:groups")
    if isinstance(groups_claim, list):
        groups = groups_claim
    elif isinstance(groups_claim, str):
        groups = [g.strip() for g in groups_claim.split(",") if g.strip()]
    else:
        groups = []

    role_order = ["ADMINISTRADOR", "SECRETARIA", "ABOGADO"]
    rol = None
    for r in role_order:
        if r in groups:
            rol = r
            break

    # Fallback a atributo custom, por si acaso
    if not rol:
        custom_rol = claims.get("custom:rol")
        if custom_rol in role_order:
            rol = custom_rol

    # Atributo custom de secretaria, ej. "abogado1,abogado2"
    abogados_asignados_raw = claims.get("custom:abogados_asignados")
    if isinstance(abogados_asignados_raw, str):
        abogados_asignados = [
            a.strip() for a in abogados_asignados_raw.split(",") if a.strip()
        ]
    else:
        abogados_asignados = []

    logger.info(
        "Contexto de rol: rol=%s, username=%s, abogados_asignados=%s",
        rol,
        username,
        abogados_asignados,
    )

    return rol, username, abogados_asignados


# ----------- Handlers de rutas -----------


def handle_health(event, context):
    logger.info("handle_health llamado.")
    return build_response(200, {"status": "ok"})


def handle_get_audiencias(event, context):
    logger.info("handle_get_audiencias llamado.")

    if table is None:
        # Error de configuración de Lambda / Terraform
        return build_response(
            500,
            {
                "message": (
                    "Tabla DynamoDB no configurada en la Lambda "
                    "(faltan TABLE_NAME / DYNAMODB_TABLE_NAME)."
                )
            },
        )

    try:
        rol, username, abogados_asignados = get_role_context(event)

        if not rol:
            return build_response(
                403, {"message": "Rol no encontrado para listar audiencias."}
            )

        # Para la demo hacemos scan (está bien por poco volumen)
        try:
            data = table.scan()
        except ClientError as e:
            logger.error("Error de DynamoDB al hacer scan: %s", e, exc_info=True)
            code = e.response.get("Error", {}).get("Code")
            if code == "ResourceNotFoundException":
                return build_response(
                    500,
                    {
                        "message": (
                            f"La tabla DynamoDB '{TABLE_NAME}' no existe o "
                            "no es accesible para esta Lambda."
                        )
                    },
                )
            return build_response(
                500, {"message": "Error en DynamoDB al listar audiencias."}
            )

        items = data.get("Items", []) or []

        if rol == "ADMINISTRADOR":
            visibles = items
        elif rol == "ABOGADO":
            visibles = [it for it in items if it.get("abogado_id") == username]
        elif rol == "SECRETARIA":
            asignados = set(abogados_asignados)
            visibles = [it for it in items if it.get("abogado_id") in asignados]
        else:
            return build_response(
                403, {"message": "Rol no autorizado para listar audiencias."}
            )

        return build_response(
            200,
            {
                "rol": rol,
                "usuario": username,
                "total": len(visibles),
                "items": visibles,
            },
        )

    except Exception as e:
        logger.error("Error inesperado en handle_get_audiencias: %s", e, exc_info=True)
        return build_response(
            500, {"message": "Error interno al listar audiencias."}
        )


def handle_post_audiencia(event, context):
    logger.info("handle_post_audiencia llamado.")

    rol, username, _ = get_role_context(event)

    if rol not in ("ADMINISTRADOR", "SECRETARIA"):
        return build_response(
            403,
            {
                "message": "Solo ADMINISTRADOR o SECRETARIA pueden crear audiencias."
            },
        )

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return build_response(400, {"message": "Body JSON inválido."})

    requeridos = ["id_audiencia", "abogado_id", "fecha", "sala", "estado"]
    faltan = [f for f in requeridos if f not in body]
    if faltan:
        return build_response(
            400,
            {"message": "Faltan campos obligatorios: " + ", ".join(faltan)},
        )

    item = {
        "id_audiencia": body["id_audiencia"],
        "abogado_id": body["abogado_id"],
        "fecha": body["fecha"],
        "sala": body["sala"],
        "estado": body["estado"],
        "creado_por": username,
        "creado_en": datetime.utcnow().isoformat(),
    }

    if "descripcion" in body:
        item["descripcion"] = body["descripcion"]

    try:
        table.put_item(Item=item)
    except ClientError as e:
        logger.error("Error de DynamoDB al crear audiencia: %s", e, exc_info=True)
        return build_response(
            500, {"message": "Error en DynamoDB al crear la audiencia."}
        )

    return build_response(201, {"message": "Audiencia creada.", "item": item})


def handle_delete_audiencia(event, context):
    logger.info("handle_delete_audiencia llamado.")

    rol, username, _ = get_role_context(event)

    if rol not in ("ADMINISTRADOR", "SECRETARIA"):
        return build_response(
            403,
            {
                "message": "Solo ADMINISTRADOR o SECRETARIA pueden cancelar audiencias."
            },
        )

    params = event.get("queryStringParameters") or {}
    aud_id = params.get("id_audiencia")
    if not aud_id:
        return build_response(
            400,
            {"message": "Debes enviar ?id_audiencia=... en la URL."},
        )

    try:
        table.update_item(
            Key={"id_audiencia": aud_id},
            UpdateExpression=(
                "SET #estado = :nuevo, cancelado_por = :user, cancelado_en = :fecha"
            ),
            ExpressionAttributeNames={"#estado": "estado"},
            ExpressionAttributeValues={
                ":nuevo": "CANCELADA",
                ":user": username,
                ":fecha": datetime.utcnow().isoformat(),
            },
        )
    except ClientError as e:
        logger.error("Error de DynamoDB al cancelar audiencia: %s", e, exc_info=True)
        return build_response(
            500, {"message": "Error en DynamoDB al cancelar la audiencia."}
        )

    return build_response(
        200, {"message": f"Audiencia {aud_id} cancelada (soft delete)."}
    )


# ----------- Router principal -----------


def lambda_handler(event, context):
    # Log mínimo para depurar problemas de routing
    logger.info(
        "Evento recibido (resumen): %s",
        json.dumps(
            {
                "routeKey": event.get("routeKey"),
                "rawPath": event.get("rawPath"),
                "method": event.get("requestContext", {})
                .get("http", {})
                .get("method"),
                "path": event.get("requestContext", {})
                .get("http", {})
                .get("path"),
            },
            default=str,
        ),
    )

    route_key = event.get("routeKey", "")
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    raw_path = event.get("requestContext", {}).get("http", {}).get("path") or event.get(
        "rawPath", ""
    )

    if not route_key and method and raw_path:
        route_key = f"{method} {raw_path}"

    try:
        if route_key.startswith("GET /health"):
            return handle_health(event, context)

        if route_key.startswith("GET /audiencias"):
            return handle_get_audiencias(event, context)

        if route_key.startswith("POST /audiencias"):
            return handle_post_audiencia(event, context)

        if route_key.startswith("DELETE /audiencias"):
            return handle_delete_audiencia(event, context)

        return build_response(404, {"message": f"Ruta no soportada: {route_key}"})
    except Exception as e:
        logger.error("Error inesperado en lambda_handler: %s", e, exc_info=True)
        return build_response(500, {"message": "Error interno en la Lambda."})
