# terraform/modules/lambda-reportes/main.tf
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

// Solo permisos de lectura sobre la tabla
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]

    resources = [var.dynamodb_table_arn]
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

  environment {
    variables = {
      TABLE_NAME  = var.dynamodb_table_name
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