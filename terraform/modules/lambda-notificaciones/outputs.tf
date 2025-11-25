# terraform/modules/lambda-notificaciones/outputs.tf

output "function_name" {
  description = "Nombre de la función Lambda de notificaciones"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN de la función Lambda de notificaciones"
  value       = aws_lambda_function.this.arn
}

output "role_arn" {
  description = "ARN del rol IAM de la función"
  value       = aws_iam_role.this.arn
}
