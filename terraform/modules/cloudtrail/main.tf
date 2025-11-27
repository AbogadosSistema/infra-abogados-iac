# terraform/modules/cloudtrail/main.tf

# Trail de CloudTrail a nivel cuenta/región para auditoría
# - Registra eventos de gestión (creación/cambio/borrado de recursos).
# - Envía logs a un bucket S3 dedicado.
# - Se puede usar en el informe para justificar auditoría de API/infra.

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${var.resource_prefix}-${var.env}-cloudtrail-logs"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-${var.env}-cloudtrail-logs"
    }
  )
}

# ACL privada explícita
resource "aws_s3_bucket_acl" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  acl    = "private"
}

# Cifrado en reposo (simple, con clave administrada por S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# (Opcional) política de ciclo de vida para no guardar logs eternamente
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "expire-after-365-days"
    status = "Enabled"

    # Filtro obligatorio: aplicamos la regla a todo el bucket
    filter {
      prefix = ""
    }

    expiration {
      days = var.log_retention_days
    }
  }
}

# Política del bucket para permitir que CloudTrail escriba logs
data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  statement {
    sid = "AWSCloudTrailAclCheck"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]
  }

  statement {
    sid = "AWSCloudTrailWrite"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy.json
}

# Trail principal
resource "aws_cloudtrail" "this" {
  name                          = "${var.resource_prefix}-${var.env}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  enable_logging                = true

  # Event selector sencillo: eventos de gestión (creación/cambio/borrado de recursos)
  # Esto cubre:
  # - Cambios de infraestructura (Terraform / consola).
  # - Cambios sobre APIs, Lambdas, Dynamo, etc. a nivel de AWS.
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-${var.env}-cloudtrail"
    }
  )
}
