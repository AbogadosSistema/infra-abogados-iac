# terraform/modules/s3-frontend/main.tf
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.resource_prefix}-frontend"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-frontend"
    }
  )
}

# Configuración de sitio estático
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

# Permitir acceso público de solo lectura (luego esto irá detrás de CloudFront)
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "frontend_public" {
  statement {
    sid = "AllowPublicRead"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.frontend.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "frontend_public" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend_public.json
}
