# lambda/notificaciones/handler.py

import json
import os
from datetime import datetime

import boto3

sns = boto3.client("sns")

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "dev")


# =========================
# Helpers genéricos
# =========================

def _response(status_code: int, body: dict):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
        },
        "body": json.dumps(body),
    }


def _get_claims(event):
    """
    Extrae claims desde el JWT de Cognito cuando se invoca vía
    API Gateway HTTP API (payload format 2.0).
    """
    return (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("jwt", {})
        .get("claims", {})
        or {}
    )


def _get_groups_from_claims(claims):
    """
    Extrae lista de grupos desde cognito:groups.
    Puede venir como:
      - lista ["ADMINISTRADOR", ...]
      - string "ADMINISTRADOR"
      - string '["ADMINISTRADOR"]'
    """
    raw = claims.get("cognito:groups")

    if isinstance(raw, list):
        return raw

    if isinstance(raw, str):
        # Intentamos parsear si parece JSON de lista
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
        or "desconocido"
    )


# =========================
# Handler principal
# =========================

def lambda_handler(event, context):
    """
    RUTA esperada: POST /notificaciones (protegida con JWT)

    Body esperado (JSON):
    {
      "tipo": "recordatorio_audiencia",
      "destinatario_email": "cliente@ejemplo.com",
      "id_audiencia": "A-123",
      "abogado_id": "abogado1",
      "fecha": "2025-12-01T09:00:00Z",
      "sala": "Sala 1",
      "estado": "PENDIENTE",
      "mensaje_extra": "texto opcional"
    }

    Esta Lambda NO envía el correo directamente: solo publica
    un mensaje estructurado en SNS. Un worker suscrito al topic
    (otra Lambda) se encarga de hablar con SES.
    """
    print("Evento recibido:", json.dumps(event))

    if not SNS_TOPIC_ARN:
        return _response(
            500,
            {"message": "SNS_TOPIC_ARN no está configurado en variables de entorno"},
        )

    # ---- Autorización por roles (Cognito) ----
    claims = _get_claims(event)
    groups = _get_groups_from_claims(claims)
    user = _get_username_from_claims(claims)

    # Solo ADMINISTRADOR y SECRETARIA pueden disparar notificaciones
    if not any(g in ["ADMINISTRADOR", "SECRETARIA"] for g in groups):
        return _response(
            403,
            {
                "message": "Solo ADMINISTRADOR o SECRETARIA pueden crear notificaciones.",
                "groups": groups,
            },
        )

    # ---- Parseo del body ----
    try:
        body_raw = event.get("body") or "{}"
        if event.get("isBase64Encoded"):
            import base64
            body_raw = base64.b64decode(body_raw).decode("utf-8")

        body = json.loads(body_raw)
    except Exception as e:
        print("Error parseando body:", e)
        return _response(400, {"message": "Body JSON inválido"})

    # Campos mínimos
    tipo = body.get("tipo", "recordatorio_audiencia")
    destinatario_email = body.get("destinatario_email")
    id_audiencia = body.get("id_audiencia")
    fecha = body.get("fecha")
    sala = body.get("sala")
    estado = body.get("estado", "PENDIENTE")

    if not destinatario_email:
        return _response(
            400,
            {"message": "El campo 'destinatario_email' es obligatorio."},
        )

    if not id_audiencia or not fecha:
        return _response(
            400,
            {
                "message": (
                    "Los campos 'id_audiencia' y 'fecha' son obligatorios "
                    "para el recordatorio de audiencia."
                )
            },
        )

    # ---- Construir payload para SNS ----
    message_payload = {
        "tipo": tipo,
        "destinatario_email": destinatario_email,
        "id_audiencia": id_audiencia,
        "abogado_id": body.get("abogado_id"),
        "fecha": fecha,
        "sala": sala,
        "estado": estado,
        "mensaje_extra": body.get("mensaje_extra"),
        "env": ENVIRONMENT,
        "disparado_por": user,
        "disparado_en": datetime.utcnow().isoformat() + "Z",
    }

    # ---- Publicar en SNS ----
    try:
        resp = sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=json.dumps(message_payload),
            Subject=f"[{ENVIRONMENT}] Recordatorio audiencia {id_audiencia}",
            MessageAttributes={
                "tipo": {
                    "DataType": "String",
                    "StringValue": tipo,
                }
            },
        )
    except Exception as e:
        print("Error publicando en SNS:", e)
        return _response(
            500,
            {"message": "Error publicando en SNS", "error": str(e)},
        )

    print("Mensaje publicado en SNS. MessageId:", resp.get("MessageId"))

    return _response(
        200,
        {
            "ok": True,
            "message": "Notificación publicada en SNS correctamente.",
            "sns_message_id": resp.get("MessageId"),
            "payload": message_payload,
        },
    )
