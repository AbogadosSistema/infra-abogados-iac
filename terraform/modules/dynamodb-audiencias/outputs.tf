# terraform/modules/dynamodb-audiencias/outputs.tf
output "table_name" {
  description = "Nombre de la tabla de audiencias"
  value       = aws_dynamodb_table.audiencias.name
}

output "table_arn" {
  description = "ARN de la tabla de audiencias"
  value       = aws_dynamodb_table.audiencias.arn
}