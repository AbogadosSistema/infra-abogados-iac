import json

def lambda_handler(event, context):
    print("Lambda reportes OK - evento:", event)

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Lambda reportes OK",
            "input": event,
        }),
    }