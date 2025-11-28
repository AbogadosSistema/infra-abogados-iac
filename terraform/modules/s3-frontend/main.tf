# terraform/modules/s3-frontend/main.tf

# Bucket para el frontend estático
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.resource_prefix}-frontend"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-frontend"
    }
  )
}

# Configuración de sitio estático (la dejamos activa, aunque el acceso real
# será a través de CloudFront apuntando al endpoint S3 "normal").
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

# Bloquear acceso público directo al bucket.
# Más adelante, CloudFront accederá usando OAC y una bucket policy específica.
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
