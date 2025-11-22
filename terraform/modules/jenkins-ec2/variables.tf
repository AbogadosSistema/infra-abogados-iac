variable "resource_prefix" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "allowed_cidrs" {
  description = "CIDRs que pueden acceder al puerto 8080 de Jenkins"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "Nombre del key pair para SSH (opcional). Dejar null si no usarás SSH."
  type        = string
  default     = null
}

variable "common_tags" {
  type = map(string)
}
