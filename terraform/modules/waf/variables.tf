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
  description = "Ámbito del WAF (REGIONAL o CLOUDFRONT)"
}

variable "resource_arn" {
  type        = string
  description = "ARN del recurso a proteger (ALB, API REST, CloudFront, etc.). Dejar vacío para no asociar todavía."
  default     = ""
}
