import json

def lambda_handler(event, context):
    print("Lambda notificaciones OK - evento:", event)

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Lambda notificaciones OK",
            "input": event,
        }),
    }