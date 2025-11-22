data "aws_ami" "jenkins" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "jenkins" {
  name        = "${var.resource_prefix}-jenkins-sg"
  description = "Security Group para Jenkins"
  vpc_id      = var.vpc_id

  # Acceso HTTP a Jenkins (8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  # (Opcional) SSH si algún día le pones key pair y quieres entrar
  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = var.allowed_cidrs
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-jenkins-sg"
    }
  )
}

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.jenkins.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  associate_public_ip_address = true

  key_name = var.key_name 

  user_data = <<-EOF
              #!/bin/bash
              yum update -y

              # Java para Jenkins
              amazon-linux-extras install java-openjdk11 -y

              # Repo oficial de Jenkins
              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

              # Instalar Jenkins y Git
              yum install -y jenkins git

              systemctl enable jenkins
              systemctl start jenkins
              EOF

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-jenkins"
      Role = "jenkins"
    }
  )
}
