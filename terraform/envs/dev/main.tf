# terraform/envs/dev/main.tf
// Tags comunes para todos los recursos del entorno dev
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

// Módulo de red: VPC + subred privada y pública
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

// Módulo de S3 para frontend estático
module "s3_frontend" {
  source = "../../modules/s3-frontend"

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

  kms_key_arn = module.s3_adjuntos.kms_key_arn
}

// Lambda - Audiencias (CRUD)
module "lambda_audiencias" {
  source = "../../modules/lambda-audiencias"

  function_name = "${var.resource_prefix}-lambda-audiencias"
  source_dir    = "${path.root}/../../../lambda/audiencias"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"

  env             = var.env
  resource_prefix = var.resource_prefix
  common_tags     = local.common_tags

  dynamodb_table_name = module.dynamodb_audiencias.table_name
  dynamodb_table_arn  = module.dynamodb_audiencias.table_arn

  s3_bucket_name = module.s3_adjuntos.bucket_name
  s3_bucket_arn  = module.s3_adjuntos.bucket_arn

  # NUEVO: ejecutar dentro de la VPC (subred privada + SG de Lambdas)
  subnet_ids         = [module.vpc.private_subnet_id]
  security_group_ids = [module.vpc.lambda_security_group_id]
}

// Lambda - Reportes
module "lambda_reportes" {
  source = "../../modules/lambda-reportes"

  function_name = "${var.resource_prefix}-lambda-reportes"
  source_dir    = "${path.root}/../../../lambda/reportes"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"

  env             = var.env
  resource_prefix = var.resource_prefix
  common_tags     = local.common_tags

  dynamodb_table_name = module.dynamodb_audiencias.table_name
  dynamodb_table_arn  = module.dynamodb_audiencias.table_arn

  # NUEVO: VPC
  subnet_ids         = [module.vpc.private_subnet_id]
  security_group_ids = [module.vpc.lambda_security_group_id]
}

# ============================
# SNS + SES para notificaciones
# ============================
module "sns_ses_notificaciones" {
  source = "../../modules/sns-ses-notificaciones"

  project_name    = var.project_name
  env             = var.env
  resource_prefix = var.resource_prefix
  aws_region      = var.aws_region
  common_tags     = local.common_tags

  ses_sender_email = var.ses_sender_email
}

// Lambda - Notificaciones
module "lambda_notificaciones" {
  source = "../../modules/lambda-notificaciones"

  function_name = "${var.resource_prefix}-lambda-notificaciones"
  source_dir    = "${path.root}/../../../lambda/notificaciones"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"

  env             = var.env
  resource_prefix = var.resource_prefix
  common_tags     = local.common_tags

  # topic SNS donde publicará los recordatorios
  sns_topic_arn = module.sns_ses_notificaciones.sns_topic_arn

  # NUEVO: VPC
  subnet_ids         = [module.vpc.private_subnet_id]
  security_group_ids = [module.vpc.lambda_security_group_id]
}

// Jenkins EC2
module "jenkins_ec2" {
  source = "../../modules/jenkins-ec2"

  project_name    = var.project_name
  env             = var.env
  resource_prefix = var.resource_prefix
  aws_region      = var.aws_region
  common_tags     = local.common_tags

  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_id

  instance_type = "t3.small"
  key_name      = "ia-law-dev-jenkins-key"
}

# ============================
# Cognito (Auth de usuarios)
# ============================
module "cognito" {
  source = "../../modules/cognito"

  project_name    = var.project_name
  env             = var.env
  resource_prefix = var.resource_prefix
  aws_region      = var.aws_region
  common_tags     = local.common_tags
}

# ============================
# API Gateway HTTP + JWT
# ============================
module "api_gateway" {
  source = "../../modules/api-gateway"

  project_name    = var.project_name
  env             = var.env
  resource_prefix = var.resource_prefix
  aws_region      = var.aws_region
  common_tags     = local.common_tags

  audiencias_lambda_arn = module.lambda_audiencias.lambda_arn
  reportes_lambda_arn   = module.lambda_reportes.lambda_arn

  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_app_client_id = module.cognito.app_client_id
}

# ============================
# WAF para la API (scope REGIONAL)
# ============================
module "waf_api" {
  source = "../../modules/waf"

  project_name    = var.project_name
  env             = var.env
  resource_prefix = var.resource_prefix
  common_tags     = local.common_tags

  scope = "REGIONAL"
}

# ============================
# Observabilidad (CloudWatch + SNS)
# ============================
module "observabilidad" {
  source = "../../modules/observabilidad"

  project_name    = var.project_name
  env             = var.env
  resource_prefix = var.resource_prefix
  common_tags     = local.common_tags

  alarm_email = var.alarm_email

  lambda_function_names = [
    "${var.resource_prefix}-lambda-audiencias",
    "${var.resource_prefix}-lambda-reportes",
    "${var.resource_prefix}-lambda-notificaciones",
  ]
}
