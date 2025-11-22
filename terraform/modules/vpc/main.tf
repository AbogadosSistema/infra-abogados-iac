// Obtener zonas de disponibilidad disponibles en la región
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-vpc"
    }
  )
}

// Subred privada para las Lambdas (usamos la primera AZ disponible)
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-private-a"
      Tier = "private"
    }
  )
}

/*
  NOTA:
  - No creamos Internet Gateway ni NAT Gateway.
  - Más adelante, en este mismo módulo, añadiremos los VPC Endpoints
    (S3, DynamoDB, SNS) que aparecen en el diagrama.
*/