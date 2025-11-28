# terraform/modules/s3-frontend/outputs.tf
output "bucket_name" {
  description = "Nombre del bucket S3 para el frontend"
  value       = aws_s3_bucket.frontend.bucket
}

output "website_endpoint" {
  description = "Endpoint del sitio estático en S3 (modo website)"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "bucket_arn" {
  description = "ARN del bucket S3 para el frontend"
  value       = aws_s3_bucket.frontend.arn
}

output "bucket_regional_domain_name" {
  description = "Domain name regional del bucket (para usar como origin en CloudFront)"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}
