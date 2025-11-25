# terraform/modules/s3-frontend/variables.tf
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

variable "common_tags" {
  type        = map(string)
  description = "Tags comunes para todos los recursos"
}

variable "index_document" {
  type        = string
  description = "Documento principal del sitio estático"
  default     = "index.html"
}

variable "error_document" {
  type        = string
  description = "Documento de error del sitio estático"
  default     = "index.html"
}
