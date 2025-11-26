# terraform/modules/backup-dynamodb-audiencias/outputs.tf
output "backup_vault_name" {
  description = "Nombre del Backup Vault usado para la tabla de audiencias"
  value       = aws_backup_vault.this.name
}

output "backup_plan_id" {
  description = "ID del plan de backup configurado"
  value       = aws_backup_plan.this.id
}
