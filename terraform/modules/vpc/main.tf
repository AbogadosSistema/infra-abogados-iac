# terraform/modules/vpc/main.tf
// Zonas de disponibilidad disponibles en la región
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-vpc"
    }
  )
}

# Subred privada para Lambdas / endpoints
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidr
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

# Subred pública para Jenkins EC2 (y otros recursos que requieran IP pública)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-public-a"
      Tier = "public"
    }
  )
}

# Internet Gateway para salida a internet de la subred pública
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-igw"
    }
  )
}

# Route table pública (0.0.0.0/0 -> IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

/*
  NOTA:
  - No creamos NAT Gateway (todavía no lo necesitamos).
  - Más adelante, en este mismo módulo, añadiremos los VPC Endpoints
    (S3, DynamoDB, SNS) que aparecen en el diagrama.
*/
