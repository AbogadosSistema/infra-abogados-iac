# terraform/modules/observabilidad/main.tf
locals {
  name_prefix = "${var.resource_prefix}-${var.env}"
}

# Tópico SNS para alarmas operacionales (NO es el mismo de recordatorios)
resource "aws_sns_topic" "alarms" {
  name = "${local.name_prefix}-ops-alarms"

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-sns-ops-alarms"
    }
  )
}

# Suscripción por email para alarmas (tendrás que confirmar por correo)
resource "aws_sns_topic_subscription" "email" {
  count = var.alarm_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ============================
# Alarmas de Lambda
# ============================

# 1) Errores de Lambda (Errors)  -> YA EXISTENTE
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = toset(var.lambda_function_names)

  alarm_name          = "${local.name_prefix}-lambda-errors-${each.value}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  alarm_description  = "Alarma cuando la Lambda ${each.value} registra >= 1 error en 1 minuto."
  treat_missing_data = "notBreaching"

  dimensions = {
    FunctionName = each.value
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-cw-alarm-errors-${each.value}"
    }
  )
}

# 2) Throttling de Lambda (Throttles)
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  for_each = toset(var.lambda_function_names)

  alarm_name          = "${local.name_prefix}-lambda-throttles-${each.value}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  alarm_description  = "Alarma cuando la Lambda ${each.value} registra throttling (Throttles >= 1 en 1 minuto)."
  treat_missing_data = "notBreaching"

  dimensions = {
    FunctionName = each.value
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-cw-alarm-throttles-${each.value}"
    }
  )
}

# ============================
# Alarmas API Gateway HTTP (5xx)
# ============================

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  count = var.api_gateway_api_id != "" ? 1 : 0

  alarm_name          = "${local.name_prefix}-api-5xx"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  alarm_description  = "Alarma cuando la API HTTP registra errores 5xx (5XXError >= 1 en 1 minuto)."
  treat_missing_data = "notBreaching"

  dimensions = {
    ApiId = var.api_gateway_api_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-cw-alarm-api-5xx"
    }
  )
}