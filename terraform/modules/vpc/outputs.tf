output "vpc_id" {
  description = "ID de la VPC principal"
  value       = aws_vpc.this.id
}

# Compatibilidad con lo que ya tenías (lista con la subred privada)
output "private_subnet_ids" {
  description = "Lista de subredes privadas donde vivirán las Lambdas"
  value       = [aws_subnet.private_a.id]
}

# Outputs más específicos para wiring con otros módulos
output "private_subnet_id" {
  description = "ID de la subred privada principal"
  value       = aws_subnet.private_a.id
}

output "public_subnet_id" {
  description = "ID de la subred pública (para Jenkins EC2)"
  value       = aws_subnet.public_a.id
}