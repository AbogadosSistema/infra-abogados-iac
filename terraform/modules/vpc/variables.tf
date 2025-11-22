variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
}

variable "env" {
  type        = string
  description = "Entorno (dev, prod, etc.)"
}

variable "resource_prefix" {
  type        = string
  description = "Prefijo para nombres de recursos (ej: ia-law-dev)"
}

variable "aws_region" {
  type        = string
  description = "Región AWS"
}

variable "common_tags" {
  type        = map(string)
  description = "Tags comunes para todos los recursos"
  default     = {}
}