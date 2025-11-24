# terraform/modules/lambda-notificaciones/variables.tf
variable "function_name" {
  type        = string
  description = "Nombre de la función Lambda"
}

variable "source_dir" {
  type        = string
  description = "Directorio con el código fuente de la Lambda"
}

variable "handler" {
  type        = string
  description = "Handler de la Lambda (archivo.función)"
}

variable "runtime" {
  type        = string
  description = "Runtime de la Lambda"
}

variable "env" {
  type        = string
  description = "Entorno (dev, prod, etc.)"
}

variable "resource_prefix" {
  type        = string
  description = "Prefijo para nombres de recursos"
}

variable "common_tags" {
  type        = map(string)
  description = "Tags comunes"
  default     = {}
}