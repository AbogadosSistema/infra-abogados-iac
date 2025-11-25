# terraform/modules/api-gateway/main.tf
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.resource_prefix}-${var.env}-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Authorization", "Content-Type"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-${var.env}-http-api"
    }
  )
}

# --- Integraciones Lambda ---

resource "aws_apigatewayv2_integration" "audiencias" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.audiencias_lambda_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "reportes" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.reportes_lambda_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# --- Authorizer JWT (Cognito) ---

resource "aws_apigatewayv2_authorizer" "jwt_auth" {
  api_id           = aws_apigatewayv2_api.http_api.id
  name             = "${var.resource_prefix}-${var.env}-jwt-authorizer"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [var.cognito_app_client_id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${var.cognito_user_pool_id}"
  }
}

# --- Rutas ---

# Ruta pública /health (sin auth)
resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.audiencias.id}"

  authorization_type = "NONE"
}

# Ruta protegida /audiencias (JWT)
resource "aws_apigatewayv2_route" "audiencias" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /audiencias"
  target    = "integrations/${aws_apigatewayv2_integration.audiencias.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_auth.id
}

# Ruta protegida /reportes (JWT)
resource "aws_apigatewayv2_route" "reportes" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /reportes"
  target    = "integrations/${aws_apigatewayv2_integration.reportes.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_auth.id
}

# --- Stage dev ---

resource "aws_apigatewayv2_stage" "dev" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = var.env
  auto_deploy = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-${var.env}-http-stage"
    }
  )
}

# --- Permisos Lambda para API Gateway ---

resource "aws_lambda_permission" "apigw_audiencias" {
  statement_id  = "AllowAPIGatewayInvokeAudiencias"
  action        = "lambda:InvokeFunction"
  function_name = var.audiencias_lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_reportes" {
  statement_id  = "AllowAPIGatewayInvokeReportes"
  action        = "lambda:InvokeFunction"
  function_name = var.reportes_lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
