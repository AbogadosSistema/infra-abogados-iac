# terraform/modules/backup-dynamodb-audiencias/variables.tf
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

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
}

variable "dynamodb_table_arn" {
  description = "ARN de la tabla DynamoDB de audiencias"
  type        = string
}
