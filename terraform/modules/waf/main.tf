# terraform/modules/waf/main.tf
resource "aws_wafv2_web_acl" "this" {
  name        = "${var.resource_prefix}-${var.env}-waf"
  # Descripción compatible con la regex de AWS (sin paréntesis ni tildes)
  description = "WebACL ${var.project_name} ${var.env}"
  scope       = var.scope # REGIONAL o CLOUDFRONT

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.resource_prefix}-${var.env}-waf"
    sampled_requests_enabled   = true
  }

  # Regla administrada común (protección básica)
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

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

  # Reputación IP
  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.resource_prefix}-${var.env}-waf-ipreputation"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-${var.env}-waf"
    }
  )
}

# IMPORTANTE:
# - Para CloudFront (scope = "CLOUDFRONT"), NO se usa esta asociación.
# - Solo se usa para recursos REGIONAL (ALB, API REST, etc.).
resource "aws_wafv2_web_acl_association" "this" {
  count        = var.scope == "REGIONAL" && length(var.resource_arn) > 0 ? 1 : 0
  resource_arn = var.resource_arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
