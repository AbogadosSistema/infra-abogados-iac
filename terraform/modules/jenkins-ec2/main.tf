########################################
# Módulo Jenkins EC2
########################################

########################################
# Security Group para Jenkins
########################################

resource "aws_security_group" "jenkins_sg" {
  # Usamos name_prefix para evitar error de grupo duplicado
  name_prefix = "${var.resource_prefix}-jenkins-"
  description = "Security Group para Jenkins"
  vpc_id      = var.vpc_id

  # HTTP para Jenkins en 8080
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH por si necesitamos entrar a la máquina
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

########################################
# AMI para Jenkins (Amazon Linux 2)
########################################

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

########################################
# EC2 para Jenkins
########################################

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = var.key_name

  # Script de instalación de Jenkins (con Java 17, AWS CLI y Checkov)
   user_data = <<-EOF
              #!/bin/bash
              set -xe

              # -----------------------
              # Actualizar paquetes base
              # -----------------------
              yum update -y

              # -----------------------
              # AWS CLI (para hablar con AWS)
              # -----------------------
              yum install -y awscli

              # -----------------------
              # Python 3.8 + pip (para Checkov)
              # Amazon Linux 2 usa amazon-linux-extras para python3.8
              # -----------------------
              if ! command -v python3.8 >/dev/null 2>&1; then
                amazon-linux-extras enable python3.8
                yum clean metadata
                yum install -y python3.8
              fi

              # Asegurar pip para python3.8
              python3.8 -m ensurepip --upgrade || true
              python3.8 -m pip install --upgrade pip

              # -----------------------
              # Instalar Checkov
              # Fijamos versión <3.0.0 para evitar problemas con dependencias nuevas
              # -----------------------
              python3.8 -m pip install "checkov<3.0.0"

              # Poner checkov en el PATH global si no está
              if ! command -v checkov >/dev/null 2>&1; then
                CHECKOV_BIN="$(python3.8 -m site --user-base)/bin/checkov"
                if [ -f "$CHECKOV_BIN" ] && [ ! -f /usr/local/bin/checkov ]; then
                  ln -s "$CHECKOV_BIN" /usr/local/bin/checkov
                fi
              fi

              # -----------------------
              # Java 17 (requerido por Jenkins moderno)
              # -----------------------
              yum install -y java-17-amazon-corretto-headless

              # -----------------------
              # Repositorio de Jenkins
              # -----------------------
              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

              # -----------------------
              # Jenkins + Git
              # -----------------------
              yum install -y jenkins git

              # -----------------------
              # Habilitar y arrancar Jenkins
              # -----------------------
              systemctl daemon-reload
              systemctl enable jenkins
              systemctl start jenkins
              EOF
              
  user_data_replace_on_change = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-jenkins"
    }
  )
}

########################################
# Elastic IP para Jenkins
########################################

resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins.id
  domain   = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.resource_prefix}-jenkins-eip"
    }
  )
}
