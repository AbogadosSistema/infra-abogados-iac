# terraform/modules/sns-ses-notificaciones/variables.tf

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
  description = "Prefijo para nombres de recursos"
}

variable "aws_region" {
  type        = string
  description = "Región AWS"
}

variable "common_tags" {
  type        = map(string)
  description = "Tags comunes para todos los recursos"
}

variable "ses_sender_email" {
  type        = string
  description = "Dirección FROM verificada en SES para enviar recordatorios"
}
