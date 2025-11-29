import json
import handler  # se importa el handler.py del mismo directorio


def test_handle_health_direct():
    """handle_health debe devolver 200 y body {'status': 'ok'}."""
    resp = handler.handle_health({}, None)

    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["status"] == "ok"


def test_lambda_handler_routes_health():
    """lambda_handler debe rutear GET /health hacia handle_health correctamente."""
    event = {
        "routeKey": "GET /health",
        "requestContext": {
            "http": {
                "method": "GET",
                "path": "/health",
            }
        },
    }

    resp = handler.lambda_handler(event, None)

    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["status"] == "ok"


def test_lambda_handler_not_found():
    """Para rutas desconocidas debe devolver 404."""
    event = {
        "routeKey": "GET /unknown",
        "requestContext": {
            "http": {
                "method": "GET",
                "path": "/unknown",
            }
        },
    }

    resp = handler.lambda_handler(event, None)

    assert resp["statusCode"] == 404
