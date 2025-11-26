# terraform/modules/lambda-reportes/variables.tf
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
  description = "Runtime de la Lambda"
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

# NUEVO: VPC
variable "subnet_ids" {
  description = "Subredes donde se ejecutará la Lambda (VPC)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security Groups asociados a la Lambda"
  type        = list(string)
}
