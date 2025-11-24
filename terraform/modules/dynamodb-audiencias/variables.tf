# terraform/modules/dynamodb-audiencias/variables.tf
variable "table_name" {
  description = "Nombre de la tabla de audiencias"
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

variable "kms_key_arn" {
  description = "ARN de la clave KMS para cifrado de la tabla"
  type        = string
}