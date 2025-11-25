# terraform/modules/sns-ses-notificaciones/main.tf

# Topic SNS para notificaciones de recordatorios
resource "aws_sns_topic" "notificaciones" {
  name = "${var.resource_prefix}-${var.env}-notificaciones"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-${var.env}-sns-notificaciones"
    }
  )
}

# Identidad de correo en SES (FROM). AWS enviará un correo para verificarla.
resource "aws_sesv2_email_identity" "sender" {
  email_identity = var.ses_sender_email
}
