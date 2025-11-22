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

// Módulo de S3 para adjuntos + KMS de datos
module "s3_adjuntos" {
  source = "../../modules/s3-adjuntos"

  project_name    = var.project_name
  env             = var.env
  resource_prefix = var.resource_prefix
  common_tags     = local.common_tags
}

// Módulo de DynamoDB para audiencias
module "dynamodb_audiencias" {
  source = "../../modules/dynamodb-audiencias"

  table_name      = "${var.resource_prefix}-audiencias"
  resource_prefix = var.resource_prefix
  common_tags     = local.common_tags

  // Reutilizamos la misma clave KMS que el bucket de adjuntos
  kms_key_arn = module.s3_adjuntos.kms_key_arn
}
