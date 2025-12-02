

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "clima-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = var.availability_zone
  tags = { Name = "clima-subnet" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sg" {
  name = "clima-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# Puerto SSH
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Reemplazar por tu IP/32 en producción
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puerto Grafana
  ingress {
    from_port = 3000
    to_port   = 3000
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# Puerto Prometheus
  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "app" {
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name = "proyectofinal"

  user_data = <<'EOF'
#!/bin/bash
set -e

# ===============================
# 1 Actualizar paquetes
# ===============================
apt-get update -y
apt-get upgrade -y

# ===============================
# 2 Instalar Docker + Git + curl
# ===============================
apt-get install -y docker.io git curl

# Habilitar Docker
systemctl enable --now docker

# Agregar usuario ubuntu al grupo docker
usermod -aG docker ubuntu

# ===============================
# 3 Instalar Docker Compose v2
# ===============================
DOCKER_COMPOSE_VERSION="v2.20.2"
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verificar instalación
docker --version
docker-compose version

# ===============================
# 4 Clonar repositorio con docker-compose
# ===============================
cd /home/ubuntu
if [ ! -d "proyecto" ]; then
    git clone https://github.com/JimenaPereyra/mundoseproyecto1.git proyecto
fi
cd proyecto

# ===============================
# 5 Exportar variables necesarias para tu app
# ===============================
export WEATHER_API_KEY="${var.weather_api_key}"
export SECRET_KEY="${var.weather_api_key}"

# ===============================
# 6 Construir y levantar contenedores
# ===============================
docker-compose up -d --build

# ===============================
# 7 Permisos y limpieza
# ===============================
chown -R ubuntu:ubuntu /home/ubuntu/proyecto

EOF


  tags = { Name = "clima-app-instance" }
}

output "instance_public_ip" {
  value = aws_instance.app.public_ip
}

output "instance_id" {
  value = aws_instance.app.id
}
