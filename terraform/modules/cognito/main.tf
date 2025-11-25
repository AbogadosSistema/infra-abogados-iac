# terraform/modules/cognito/main.tf
resource "aws_cognito_user_pool" "this" {
  name = "${var.resource_prefix}-${var.env}-users"

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-${var.env}-user-pool"
    }
  )
}

resource "aws_cognito_user_pool_client" "app" {
  name         = "${var.resource_prefix}-${var.env}-frontend"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = false

  prevent_user_existence_errors = "ENABLED"

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  supported_identity_providers = ["COGNITO"]
}
