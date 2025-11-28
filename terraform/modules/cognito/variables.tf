# terraform/modules/cognito/variables.tf
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
  description = "Prefijo para nombres de recursos"
}

variable "aws_region" {
  type        = string
  description = "Región AWS donde se despliega Cognito"
}

variable "common_tags" {
  type        = map(string)
  description = "Tags comunes para todos los recursos"
}

variable "oauth_callback_url" {
  type        = string
  description = "URL de devolución (callback) del flujo OAuth/Hosted UI"
}

variable "oauth_logout_url" {
  type        = string
  description = "URL de cierre de sesión (logout) del flujo OAuth/Hosted UI"
}
