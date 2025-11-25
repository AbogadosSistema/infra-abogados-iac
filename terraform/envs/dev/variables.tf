variable "project_name" {
  description = "Nombre base del proyecto"
  type        = string
}

variable "env" {
  description = "Nombre del entorno (dev, prod, etc.)"
  type        = string
}

variable "aws_region" {
  description = "Región AWS"
  type        = string
}

variable "resource_prefix" {
  description = "Prefijo para nombres de recursos (ej: ia-law-dev)"
  type        = string
}

variable "ses_sender_email" {
  description = "Email verificado en SES que se usará como remitente"
  type        = string
}
