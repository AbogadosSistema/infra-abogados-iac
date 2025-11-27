# terraform/modules/dynamodb-audiencias/main.tf
resource "aws_dynamodb_table" "audiencias" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"

  # Clave primaria simple alineada con las Lambdas:
  # id_audiencia es la partición principal.
  hash_key = "id_audiencia"

  attribute {
    name = "id_audiencia"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-audiencias"
    }
  )
}
