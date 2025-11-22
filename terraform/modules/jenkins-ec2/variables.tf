variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
}

variable "env" {
  type        = string
  description = "Entorno (dev, prod, etc.)"
}

variable "resource_prefix" {
  type        = string
  description = "Prefijo para recursos, ej: ia-law-dev"
}

variable "aws_region" {
  type        = string
  description = "Región AWS"
}

variable "vpc_id" {
  type        = string
  description = "ID de la VPC donde vive Jenkins"
}

variable "subnet_id" {
  type        = string
  description = "Subred (pública o con salida a Internet) donde se lanza la instancia de Jenkins"
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2 para Jenkins"
  default     = "t3.small"
}

variable "key_name" {
  type        = string
  description = "Nombre del par de claves EC2 para acceso SSH"
}

variable "common_tags" {
  type        = map(string)
  description = "Tags comunes"
  default     = {}
}
