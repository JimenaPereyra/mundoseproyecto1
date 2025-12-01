data "aws_availability_zones" "azs" {}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "clima-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.azs.names[0]
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

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io jq
    systemctl enable --now docker

    # optional: docker login if you want to pull private images (credentials via AWS Secrets or passed env)
    # Pull and run the app (pass SECRET/WEATHER_API_KEY as env)
    docker pull ${var.dockerhub_username}/app_clima2:${var.image_tag} || docker pull ${var.dockerhub_username}/app_clima2:latest
    docker rm -f clima-app || true
    docker run -d -p 80:5000 \
      -e SECRET_KEY="${var.weather_api_key}" \
      -e WEATHER_API_KEY="${var.weather_api_key}" \
      --name clima-app ${var.dockerhub_username}/app_clima2:${var.image_tag}
    sudo usermod -aG docker ubuntu
  EOF

  tags = { Name = "clima-app-instance" }
}

output "instance_public_ip" {
  value = aws_instance.app.public_ip
}

output "instance_id" {
  value = aws_instance.app.id
}
