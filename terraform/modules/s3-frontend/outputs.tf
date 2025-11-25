# terraform/modules/s3-frontend/outputs.tf
output "bucket_name" {
  description = "Nombre del bucket S3 para el frontend"
  value       = aws_s3_bucket.frontend.bucket
}

output "website_endpoint" {
  description = "Endpoint del sitio estático en S3"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}
