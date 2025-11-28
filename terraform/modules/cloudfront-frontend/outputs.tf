# terraform/modules/cloudfront-frontend/outputs.tf

output "distribution_id" {
  description = "ID de la distribución de CloudFront del frontend"
  value       = aws_cloudfront_distribution.this.id
}

output "cdn_domain_name" {
  description = "Dominio de CloudFront (URL principal del frontend)"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_arn" {
  description = "ARN de la distribución de CloudFront del frontend"
  value       = aws_cloudfront_distribution.this.arn
}
