# Usuario ADMINISTRADOR
resource "aws_cognito_user" "admin1" {
  user_pool_id       = module.cognito.user_pool_id
  username           = "admin1"
  temporary_password = "Admin123!" # solo para demo

  attributes = {
    email          = "admin1@example.com"
    email_verified = "true" # marcar como verificado
  }

  message_action = "SUPPRESS" # no enviar correo
}

resource "aws_cognito_user_in_group" "admin1_admin" {
  user_pool_id = module.cognito.user_pool_id
  username     = aws_cognito_user.admin1.username
  group_name   = "ADMINISTRADOR"
}

# Usuario ABOGADO
resource "aws_cognito_user" "abogado1" {
  user_pool_id       = module.cognito.user_pool_id
  username           = "abogado1"
  temporary_password = "Abogado123!"

  attributes = {
    email          = "abogado1@example.com"
    email_verified = "true"
  }

  message_action = "SUPPRESS"
}

resource "aws_cognito_user_in_group" "abogado1_abogado" {
  user_pool_id = module.cognito.user_pool_id
  username     = aws_cognito_user.abogado1.username
  group_name   = "ABOGADO"
}

# Usuario SECRETARIA (con atributo custom)
resource "aws_cognito_user" "secretaria1" {
  user_pool_id       = module.cognito.user_pool_id
  username           = "secretaria1"
  temporary_password = "Secretaria123!"

  attributes = {
    email                       = "secretaria1@example.com"
    email_verified              = "true"
    "custom:abogados_asignados" = "abogado1"
  }

  message_action = "SUPPRESS"
}

resource "aws_cognito_user_in_group" "secretaria1_secretaria" {
  user_pool_id = module.cognito.user_pool_id
  username     = aws_cognito_user.secretaria1.username
  group_name   = "SECRETARIA"
}
