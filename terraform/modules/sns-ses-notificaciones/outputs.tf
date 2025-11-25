# terraform/modules/sns-ses-notificaciones/outputs.tf

output "sns_topic_arn" {
  description = "ARN del topic SNS de notificaciones"
  value       = aws_sns_topic.notificaciones.arn
}

output "sns_topic_name" {
  description = "Nombre del topic SNS de notificaciones"
  value       = aws_sns_topic.notificaciones.name
}

output "ses_sender_identity_arn" {
  description = "ARN de la identidad de correo en SES"
  value       = aws_sesv2_email_identity.sender.arn
}
