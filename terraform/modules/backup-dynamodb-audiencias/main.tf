#terraform/modules/backup-dynamodb-audiencias/main.tf
locals {
  name_prefix = "${var.resource_prefix}-${var.env}"
}

# Vault donde se almacenarán los backups
resource "aws_backup_vault" "this" {
  name = "${local.name_prefix}-backup-vault"

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-backup-vault"
    }
  )
}

# Rol que usará AWS Backup para ejecutar los backups
data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "backup" {
  name               = "${local.name_prefix}-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-backup-role"
    }
  )
}

# Adjuntamos política administrada para que AWS Backup pueda operar
resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Plan de backup: diario, retención 30 días
resource "aws_backup_plan" "this" {
  name = "${local.name_prefix}-backup-plan"

  rule {
    rule_name         = "${local.name_prefix}-dynamodb-audiencias-daily"
    target_vault_name = aws_backup_vault.this.name

    # Backup diario a las 03:00 UTC
    schedule = "cron(0 3 * * ? *)"

    lifecycle {
      delete_after = 30
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${local.name_prefix}-backup-plan"
    }
  )
}

# Selección: aplicar el plan a la tabla de audiencias
resource "aws_backup_selection" "audiencias" {
  name         = "${local.name_prefix}-audiencias-selection"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.this.id

  resources = [
    var.dynamodb_table_arn,
  ]
}
