# terraform/modules/waf/variables.tf
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

variable "common_tags" {
  type        = map(string)
  description = "Tags comunes para todos los recursos"
}

variable "scope" {
  type        = string
  description = "Scope de WAFv2: REGIONAL o CLOUDFRONT"
  default     = "REGIONAL"
}

# Solo para recursos regionales (ALB, API REST, etc.)
variable "resource_arn" {
  type        = string
  description = "ARN del recurso regional a asociar cuando scope = REGIONAL"
  default     = ""
}
