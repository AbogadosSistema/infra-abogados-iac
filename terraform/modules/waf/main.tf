# terraform/modules/waf/main.tf
resource "aws_wafv2_web_acl" "this" {
  name  = "${var.resource_prefix}-${var.env}-waf"
  scope = var.scope # "REGIONAL" ahora, "CLOUDFRONT" cuando tengamos CloudFront

  default_action {
    allow {}
  }

  # Regla de rate limiting por IP
  rule {
    name     = "RateLimitIP"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        aggregate_key_type    = "IP"
        limit                 = 2000
        evaluation_window_sec = 300
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.resource_prefix}-${var.env}-waf-rl"
      sampled_requests_enabled   = true
    }
  }

  # Conjunto administrado de reglas comunes de AWS
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.resource_prefix}-${var.env}-waf-common"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.resource_prefix}-${var.env}-waf"
    sampled_requests_enabled   = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-${var.env}-waf"
    }
  )
}

# ⚠️ La asociación ahora es OPCIONAL
resource "aws_wafv2_web_acl_association" "this" {
  count = length(var.resource_arn) > 0 ? 1 : 0

  resource_arn = var.resource_arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
