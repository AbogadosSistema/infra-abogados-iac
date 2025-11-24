# terraform/modules/s3-adjuntos/main.tf
// Clave KMS dedicada a datos (S3 + DynamoDB)
resource "aws_kms_key" "data" {
  description         = "${var.project_name}-${var.env} data key"
  enable_key_rotation = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-kms-data"
    }
  )
}

resource "aws_kms_alias" "data_alias" {
  name          = "alias/${var.resource_prefix}-kms-data"
  target_key_id = aws_kms_key.data.key_id
}

// Bucket privado para adjuntos de audiencias
resource "aws_s3_bucket" "adjuntos" {
  bucket = "${var.resource_prefix}-adjuntos"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-adjuntos"
    }
  )
}

// Bloqueo de acceso público
resource "aws_s3_bucket_public_access_block" "adjuntos_block" {
  bucket = aws_s3_bucket.adjuntos.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// Cifrado en reposo con KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "adjuntos_sse" {
  bucket = aws_s3_bucket.adjuntos.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data.arn
    }
  }
}
