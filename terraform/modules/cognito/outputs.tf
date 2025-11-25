# terraform/modules/cognito/outputs.tf
output "user_pool_id" {
  description = "ID del User Pool de Cognito"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "ARN del User Pool de Cognito"
  value       = aws_cognito_user_pool.this.arn
}

output "app_client_id" {
  description = "ID del App Client de Cognito"
  value       = aws_cognito_user_pool_client.app.id
}
