# terraform/envs/dev/outputs.tf
# ============================
# Outputs Jenkins (dev)
# ============================
output "jenkins_url" {
  description = "URL de Jenkins (dev)"
  value       = module.jenkins_ec2.jenkins_url
}

# ============================
# Outputs Frontend S3 (dev)
# ============================
output "frontend_bucket_name" {
  description = "Nombre del bucket S3 para el frontend"
  value       = module.s3_frontend.bucket_name
}

output "frontend_website_endpoint" {
  description = "Endpoint del sitio estático en S3"
  value       = module.s3_frontend.website_endpoint
}
# ============================
# Outputs API + Cognito (dev)
# ============================
output "api_gateway_endpoint" {
  description = "Endpoint base de la HTTP API (dev)"
  value       = module.api_gateway.api_endpoint
}

output "cognito_user_pool_id" {
  description = "ID del User Pool de Cognito (dev)"
  value       = module.cognito.user_pool_id
}

output "cognito_app_client_id" {
  description = "ID del App Client de Cognito (dev)"
  value       = module.cognito.app_client_id
}
