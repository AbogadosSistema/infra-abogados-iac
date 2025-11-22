output "vpc_id" {
  description = "ID de la VPC principal"
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Lista de subredes privadas donde vivirán las Lambdas"
  value       = [aws_subnet.private_a.id]
}