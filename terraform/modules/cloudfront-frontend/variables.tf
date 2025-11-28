# terraform/modules/cloudfront-frontend/variables.tf

variable "project_name" {
  type        = string
  description = "Nombre del proyecto (para tags)"
}

variable "env" {
  type        = string
  description = "Entorno (dev, qa, prod)"
}

variable "resource_prefix" {
  type        = string
  description = "Prefijo común para nombres de recursos"
}

variable "aws_region" {
  type        = string
  description = "Región AWS"
}

variable "common_tags" {
  type        = map(string)
  description = "Tags comunes para todos los recursos"
}

variable "s3_bucket_id" {
  type        = string
  description = "ID/nombre del bucket S3 que sirve el frontend"
}

variable "s3_bucket_arn" {
  type        = string
  description = "ARN del bucket S3 que sirve el frontend"
}

variable "origin_domain_name" {
  type        = string
  description = "Domain name regional del bucket S3 (para usar como origin en CloudFront)"
}

variable "web_acl_arn" {
  type        = string
  description = "ARN del Web ACL de WAFv2 para asociar con la distribución (opcional)"
  default     = ""
}
