import json

def lambda_handler(event, context):
    print("Lambda audiencias OK - evento:", event)

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Lambda audiencias OK",
            "input": event,
        }),
    }