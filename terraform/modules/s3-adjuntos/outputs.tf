# terraform/modules/s3-adjuntos/outputs.tf
output "bucket_name" {
  description = "Nombre del bucket de adjuntos"
  value       = aws_s3_bucket.adjuntos.bucket
}

output "bucket_arn" {
  description = "ARN del bucket de adjuntos"
  value       = aws_s3_bucket.adjuntos.arn
}

output "kms_key_arn" {
  description = "ARN de la clave KMS usada para datos (S3/DynamoDB)"
  value       = aws_kms_key.data.arn
}
