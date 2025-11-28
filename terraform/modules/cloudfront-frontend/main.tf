# terraform/modules/cloudfront-frontend/main.tf

locals {
  name_prefix = "${var.resource_prefix}-${var.env}"
}

# Origin Access Control (OAC) para S3
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${local.name_prefix}-frontend-oac"
  description                       = "OAC para frontend estático en S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Distribución de CloudFront para el frontend
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  comment             = "${var.project_name} frontend (${var.env})"
  default_root_object = "index.html"

  # Asociar WAFv2 cuando se provee un ARN
  web_acl_id = var.web_acl_arn != "" ? var.web_acl_arn : null

  origin {
    domain_name = var.origin_domain_name
    origin_id   = "s3-frontend-origin"

    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-frontend-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    compress = true

    # Políticas administradas de AWS (estables) para S3 estático
    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # CORS-S3Origin
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # SPA / rutas directas: servir index.html ante 403/404
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-frontend-cdn"
    }
  )
}

# Bucket policy: permite solo a CloudFront (esta distribución) leer el bucket
data "aws_iam_policy_document" "s3_oac_policy" {
  statement {
    sid = "AllowCloudFrontServicePrincipalRead"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      var.s3_bucket_arn,
      "${var.s3_bucket_arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend_oac" {
  bucket = var.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_oac_policy.json
}
