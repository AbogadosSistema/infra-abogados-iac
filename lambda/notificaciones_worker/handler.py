# lambda/notificaciones_worker/handler.py

import json
import os

import boto3

SES_REGION = os.environ.get("SES_REGION") or os.environ.get("AWS_REGION") or "us-east-1"
SENDER_EMAIL = os.environ.get("SENDER_EMAIL")  # Debe estar verificado en SES


ses = boto3.client("ses", region_name=SES_REGION)


def _build_email_subject(payload: dict) -> str:
    env = payload.get("env", "dev")
    id_audiencia = payload.get("id_audiencia", "sin-id")
    return f"[{env}] Recordatorio de audiencia {id_audiencia}"


def _build_email_body(payload: dict) -> str:
    id_audiencia = payload.get("id_audiencia", "N/A")
    fecha = payload.get("fecha", "N/A")
    sala = payload.get("sala", "N/A")
    estado = payload.get("estado", "PENDIENTE")
    abogado_id = payload.get("abogado_id", "N/A")
    mensaje_extra = payload.get("mensaje_extra") or ""
    disparado_por = payload.get("disparado_por", "sistema")

    lineas = [
        "Estimado/a,",
        "",
        "Le recordamos que tiene una audiencia programada:",
        f"- ID de audiencia: {id_audiencia}",
        f"- Fecha y hora:    {fecha}",
        f"- Sala:            {sala}",
        f"- Estado:          {estado}",
        f"- Abogado:         {abogado_id}",
        "",
    ]

    if mensaje_extra:
        lineas.append("Mensaje adicional:")
        lineas.append(mensaje_extra)
        lineas.append("")

    lineas.extend(
        [
            f"Este recordatorio fue generado por: {disparado_por}",
            "",
            "Saludos cordiales,",
            "Sistema de Gestión de Audiencias",
        ]
    )

    return "\n".join(lineas)


def _send_email(destinatario: str, payload: dict):
    if not SENDER_EMAIL:
        raise RuntimeError(
            "SENDER_EMAIL no está configurado en las variables de entorno."
        )

    subject = _build_email_subject(payload)
    body_text = _build_email_body(payload)

    ses.send_email(
        Source=SENDER_EMAIL,
        Destination={
            "ToAddresses": [destinatario],
        },
        Message={
            "Subject": {"Data": subject, "Charset": "UTF-8"},
            "Body": {
                "Text": {"Data": body_text, "Charset": "UTF-8"},
            },
        },
    )


def lambda_handler(event, context):
    """
    Esta Lambda se suscribe al topic SNS de notificaciones.

    Recibe eventos en el formato estándar de SNS:

    {
      "Records": [
        {
          "Sns": {
            "MessageId": "...",
            "Subject": "...",
            "Message": "{... JSON del recordatorio ...}",
            ...
          }
        }
      ]
    }
    """
    records = event.get("Records", [])
    resultados = []

    for record in records:
        try:
            sns_msg = record.get("Sns", {})
            message_str = sns_msg.get("Message", "{}")
            payload = json.loads(message_str)

            destinatario = payload.get("destinatario_email")
            if not destinatario:
                print("Mensaje SNS sin destinatario_email, se omite:", payload)
                continue

            _send_email(destinatario, payload)

            resultados.append(
                {
                    "message_id": sns_msg.get("MessageId"),
                    "destinatario": destinatario,
                    "status": "ENVIADO",
                }
            )
        except Exception as e:
            print("Error procesando registro SNS:", e)
            resultados.append(
                {
                    "status": "ERROR",
                    "error": str(e),
                }
            )

    return {
        "statusCode": 200,
        "body": json.dumps({"resultados": resultados}),
    }
