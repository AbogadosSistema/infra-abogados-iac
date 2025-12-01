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

  # Atributo personalizado para SECRETARIA:
  # lista de IDs de abogados asignados (ej: "abogado1,abogado2")
  schema {
    name                = "abogados_asignados"   # en el token será custom:abogados_asignados
    attribute_data_type = "String"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 512
    }
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

  # Flujos de autenticación "clásicos" (útiles para CLI, etc.)
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
  ]

  supported_identity_providers = ["COGNITO"]

  # ==== Hosted UI / OAuth ====
  allowed_oauth_flows_user_pool_client = true

  # Dejamos habilitado código + implícito
  allowed_oauth_flows = [
    "code",
    "implicit",
  ]

  allowed_oauth_scopes = [
    "openid",
    "email",
    "profile",
  ]

  # Deben coincidir EXACTAMENTE con la redirect_uri que use el frontend
  callback_urls = [
    var.oauth_callback_url,
  ]

  logout_urls = [
    var.oauth_logout_url,
  ]
}

# ============================
# Grupos de roles de aplicación
# ============================

resource "aws_cognito_user_group" "administrador" {
  name         = "ADMINISTRADOR"
  user_pool_id = aws_cognito_user_pool.this.id
  description  = "Rol de administrador: gestiona todas las audiencias del sistema"
  precedence   = 1
}

resource "aws_cognito_user_group" "secretaria" {
  name         = "SECRETARIA"
  user_pool_id = aws_cognito_user_pool.this.id
  description  = "Rol de secretaria: registra y reporta audiencias de abogados asignados"
  precedence   = 2
}

resource "aws_cognito_user_group" "abogado" {
  name         = "ABOGADO"
  user_pool_id = aws_cognito_user_pool.this.id
  description  = "Rol de abogado: consulta y reporta sus propias audiencias"
  precedence   = 3
}
