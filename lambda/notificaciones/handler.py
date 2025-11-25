# lambda/notificaciones/handler.py
import json
import os
import boto3

sns = boto3.client("sns")

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")


def lambda_handler(event, context):
    print("Evento recibido:", json.dumps(event))

    # Permitimos dos formatos:
    # 1) Invocación directa: {"subject": "...", "message": "..."}
    # 2) Invocación vía API Gateway HTTP: {"body": "{...json...}"}
    payload = event

    # Si viene de API Gateway, "body" suele ser un string JSON
    if isinstance(event, dict) and "body" in event:
        body = event["body"]
        if isinstance(body, str):
            try:
                payload = json.loads(body)
            except Exception:
                payload = {"raw_body": body}

    subject = payload.get("subject", "Recordatorio de audiencia")
    message = payload.get(
        "message",
        "Este es un recordatorio generado por el sistema de audiencias.",
    )

    if not SNS_TOPIC_ARN:
        raise RuntimeError("SNS_TOPIC_ARN no está configurado en variables de entorno")

    # Publicar en el tópico SNS
    resp = sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=subject[:100],  # SNS limita el Subject a 100 caracteres
        Message=message,
    )

    print("Mensaje publicado en SNS. MessageId:", resp["MessageId"])

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "ok": True,
                "sns_message_id": resp["MessageId"],
            }
        ),
    }
