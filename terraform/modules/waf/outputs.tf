# terraform/modules/waf/outputs.tf
output "web_acl_arn" {
  description = "ARN del WebACL de WAF"
  value       = aws_wafv2_web_acl.this.arn
}
