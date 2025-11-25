# terraform/modules/lambda-reportes/outputs.tf
output "function_name" {
  description = "Nombre de la función Lambda de reportes"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN de la función Lambda de reportes"
  value       = aws_lambda_function.this.arn
}

output "lambda_name" {
  description = "Alias: nombre de la Lambda de reportes"
  value       = aws_lambda_function.this.function_name
}

output "lambda_arn" {
  description = "Alias: ARN de la Lambda de reportes (para otros módulos)"
  value       = aws_lambda_function.this.arn
}

output "role_arn" {
  description = "ARN del rol IAM de la función"
  value       = aws_iam_role.this.arn
}
