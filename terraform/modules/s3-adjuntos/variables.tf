# terraform/modules/s3-adjuntos/variables.tf
variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "env" {
  description = "Entorno (dev, prod, etc.)"
  type        = string
}

variable "resource_prefix" {
  description = "Prefijo para nombres de recursos (ej: ia-law-dev)"
  type        = string
}

variable "common_tags" {
  description = "Tags comunes para los recursos"
  type        = map(string)
  default     = {}
}
