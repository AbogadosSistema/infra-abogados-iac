# terraform/modules/lambda-notificaciones/variables.tf

variable "function_name" {
  type        = string
  description = "Nombre de la función Lambda de notificaciones"
}

variable "source_dir" {
  type        = string
  description = "Directorio con el código fuente de la Lambda"
}

variable "handler" {
  type        = string
  description = "Handler de la Lambda, por ejemplo handler.lambda_handler"
}

variable "runtime" {
  type        = string
  description = "Runtime de la Lambda, por ejemplo python3.11"
}

variable "env" {
  type        = string
  description = "Entorno (dev, qa, prod)"
}

variable "resource_prefix" {
  type        = string
  description = "Prefijo para nombres de recursos"
}

variable "common_tags" {
  type        = map(string)
  description = "Tags comunes para todos los recursos"
}

variable "sns_topic_arn" {
  type        = string
  description = "ARN del topic SNS donde se publican los recordatorios"
}
