// Tags comunes para todos los recursos del entorno dev
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

// Módulo de red: VPC + subred privada
module "vpc" {
  source = "../../modules/vpc"

  project_name    = var.project_name
  env             = var.env
  resource_prefix = var.resource_prefix
  aws_region      = var.aws_region
  common_tags     = local.common_tags
}