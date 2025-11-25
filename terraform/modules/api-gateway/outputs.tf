# terraform/modules/api-gateway/outputs.tf
output "api_id" {
  description = "ID de la HTTP API"
  value       = aws_apigatewayv2_api.http_api.id
}

output "api_endpoint" {
  description = "URL base de la HTTP API"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "stage_arn" {
  description = "ARN del stage (para asociar WAF)"
  value       = aws_apigatewayv2_stage.dev.arn
}
