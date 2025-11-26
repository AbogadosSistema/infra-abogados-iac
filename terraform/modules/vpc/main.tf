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

# -------------------------
# Route table pública (0.0.0.0/0 -> IGW)
# -------------------------
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

# -------------------------
# Route table privada (sin salida directa a internet)
# -------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-private-rt"
    }
  )
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# -------------------------
# Security Group para Lambdas en la subred privada
# -------------------------
resource "aws_security_group" "lambda" {
  name        = "${var.resource_prefix}-lambda-sg"
  description = "Security group para Lambdas en subred privada"
  vpc_id      = aws_vpc.this.id

  # Las Lambdas no reciben tráfico entrante directo desde internet,
  # pero sí necesitan hablar con los VPC Endpoints (SNS, S3, DynamoDB).
  # Permitimos tráfico interno entre recursos con este mismo SG en 443.
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    self      = true
  }

  # Salida libre: no hay NAT Gateway, por lo que solo podrán
  # alcanzar servicios accesibles por rutas internas / endpoints.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-lambda-sg"
    }
  )
}

# -------------------------
# VPC Endpoints - Gateway para S3 y DynamoDB
# (usados por la subred privada)
# -------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private.id]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-vpce-s3"
    }
  )
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private.id]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-vpce-dynamodb"
    }
  )
}

# -------------------------
# VPC Endpoint - Interface para SNS
# -------------------------
resource "aws_vpc_endpoint" "sns" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.aws_region}.sns"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id]
  security_group_ids  = [aws_security_group.lambda.id]
  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-vpce-sns"
    }
  )
}

/*
  NOTA:
  - No creamos NAT Gateway (para reducir costo).
  - Las Lambdas en la subred privada acceden a servicios AWS
    solo mediante VPC Endpoints (DynamoDB, S3, SNS).
*/
