# terraform/modules/observabilidad/variables.tf
variable "project_name" {
  description = "Nombre base del proyecto"
  type        = string
}

variable "env" {
  description = "Nombre del entorno (dev, prod, etc.)"
  type        = string
}

variable "resource_prefix" {
  description = "Prefijo para nombres de recursos (ej: ia-law-dev)"
  type        = string
}

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
}

variable "lambda_function_names" {
  description = "Lista de nombres de funciones Lambda a monitorear"
  type        = list(string)
}

variable "alarm_email" {
  description = "Correo donde se enviarán las alarmas de CloudWatch"
  type        = string
}

# NUEVO: ID de la HTTP API (para alarmas 5xx)
variable "api_gateway_api_id" {
  description = "ID de la HTTP API (para alarmas 5xx). Dejar vacío para no crear la alarma."
  type        = string
  default     = ""
}
