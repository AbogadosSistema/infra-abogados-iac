# terraform/modules/waf/outputs.tf
output "web_acl_arn" {
  description = "ARN del Web ACL de WAFv2"
  value       = aws_wafv2_web_acl.this.arn
}
