output "function_name" {
  value       = aws_lambda_function.this.function_name
  description = "Nombre de la función Lambda de reportes"
}

output "function_arn" {
  value       = aws_lambda_function.this.arn
  description = "ARN de la función Lambda de reportes"
}

output "role_arn" {
  value       = aws_iam_role.this.arn
  description = "ARN del rol IAM de la función"
}