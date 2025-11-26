# terraform/modules/observabilidad/outputs.tf
output "alarms_topic_arn" {
  description = "ARN del tópico SNS usado para alarmas"
  value       = aws_sns_topic.alarms.arn
}
