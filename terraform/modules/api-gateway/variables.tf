# terraform/modules/api-gateway/variables.tf
variable "project_name" {
  type        = string
  description = "Nombre del proyecto (para tags)"
}

variable "env" {
  type        = string
  description = "Entorno (dev, qa, prod, etc.)"
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

variable "audiencias_lambda_arn" {
  type        = string
  description = "ARN de la Lambda de audiencias"
}

variable "reportes_lambda_arn" {
  type        = string
  description = "ARN de la Lambda de reportes"
}

variable "cognito_user_pool_id" {
  type        = string
  description = "ID del User Pool de Cognito para JWT"
}

variable "cognito_app_client_id" {
  type        = string
  description = "ID del App Client de Cognito (audience del JWT)"
}
