# terraform/modules/lambda-audiencias/variables.tf
variable "function_name" {
  description = "Nombre de la función Lambda"
  type        = string
}

variable "source_dir" {
  description = "Directorio con el código fuente de la Lambda"
  type        = string
}

variable "handler" {
  description = "Handler de la Lambda (archivo.función)"
  type        = string
}

variable "runtime" {
  description = "Runtime de la Lambda (ej: python3.11)"
  type        = string
}

variable "env" {
  description = "Entorno (dev, prod, etc.)"
  type        = string
}

variable "resource_prefix" {
  description = "Prefijo para nombres de recursos"
  type        = string
}

variable "common_tags" {
  description = "Tags comunes"
  type        = map(string)
  default     = {}
}

variable "dynamodb_table_name" {
  description = "Nombre de la tabla de audiencias"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN de la tabla de audiencias"
  type        = string
}

variable "s3_bucket_name" {
  description = "Nombre del bucket de adjuntos"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN del bucket de adjuntos"
  type        = string
}