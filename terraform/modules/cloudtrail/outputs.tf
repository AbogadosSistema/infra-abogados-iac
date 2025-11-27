# terraform/modules/cloudtrail/outputs.tf

output "trail_arn" {
  description = "ARN del CloudTrail principal"
  value       = aws_cloudtrail.this.arn
}

output "logs_bucket_name" {
  description = "Nombre del bucket S3 donde se guardan los logs de CloudTrail"
  value       = aws_s3_bucket.cloudtrail.bucket
}