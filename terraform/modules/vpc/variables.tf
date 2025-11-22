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
  description = "Prefijo para nombres de recursos (ej: ia-law-dev)"
}

variable "aws_region" {
  type        = string
  description = "Región AWS"
}

variable "common_tags" {
  type        = map(string)
  description = "Tags comunes para todos los recursos"
  default     = {}
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR de la VPC"
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR de la subred privada"
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR de la subred pública"
  default     = "10.0.0.0/24"
}
