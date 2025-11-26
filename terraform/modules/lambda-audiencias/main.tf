# terraform/modules/lambda-audiencias/main.tf
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/lambda.zip"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.resource_prefix}-${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(
    var.common_tags,
    {
      Name = "${var.function_name}-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# NUEVO: permisos para Lambda en VPC (crear ENIs, logs de red, etc.)
resource "aws_iam_role_policy_attachment" "vpc_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Permisos de DynamoDB + S3
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]

    resources = [var.dynamodb_table_arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = ["${var.s3_bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.resource_prefix}-${var.function_name}-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = aws_iam_role.this.arn
  handler       = var.handler
  runtime       = var.runtime

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # NUEVO: ejecutar dentro de la VPC (subred privada + SG de Lambdas)
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = {
      TABLE_NAME  = var.dynamodb_table_name
      BUCKET_NAME = var.s3_bucket_name
      ENVIRONMENT = var.env
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = var.function_name
    }
  )
}
