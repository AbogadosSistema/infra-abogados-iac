# terraform/modules/cloudtrail/variables.tf

variable "project_name" {
  description = "Nombre base del proyecto (para contexto)"
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

variable "aws_region" {
  description = "Región AWS donde se habilita CloudTrail"
  type        = string
}

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
}

variable "log_retention_days" {
  description = "Días de retención de logs de CloudTrail en S3"
  type        = number
  default     = 365
}
