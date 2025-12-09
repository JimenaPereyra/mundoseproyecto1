

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
  #Puerto App
  ingress {
    from_port = 5000
    to_port   = 5000
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
  associate_public_ip_address = var.assign_public_ip
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name = "proyectofinal"


#   user_data = <<-EOT
#     #!/bin/bash
# # Add Docker's official GPG key:
# sudo apt update
# sudo apt install ca-certificates curl
# sudo install -m 0755 -d /etc/apt/keyrings
# sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
# sudo chmod a+r /etc/apt/keyrings/docker.asc
# 
# # Add the repository to Apt sources:
# sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
# Types: deb
# URIs: https://download.docker.com/linux/ubuntu
# Suites: $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$${VERSION_CODENAME}}")
# Components: stable
# Signed-By: /etc/apt/keyrings/docker.asc
# EOF
# 
# sudo apt update
# sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# 
# sudo systemctl status docker
# sudo systemctl start docker
# 
# echo "${{ secrets.EC2_SSH_PRIVATE_KEY }}" > ssh_key.pem
# chmod 600 ssh_key.pem
# 
# ssh -o StrictHostKeyChecking=no -i ssh_key.pem ubuntu@$EC2_IP << 'EOF'
# sudo apt-get update -y
# sudo apt-get install -y git
# 
# if [ ! -d "proyecto" ]; then
#       git clone https://github.com/JimenaPereyra/mundoseproyecto1.git proyecto
# fi
# 
# cd proyecto
# 
# # Exportar variables (poner aquí tus secrets)
# export WEATHER_API_KEY="${WEATHER_API_KEY}"
# export SECRET_KEY="${SECRET_KEY}"
# 
# sudo docker-compose down
# sudo docker-compose up -d --build
# EOF
# env:
#    WEATHER_API_KEY: ${{ secrets.WEATHER_API_KEY }}
#    SECRET_KEY: ${{ secrets.SECRET_KEY }}
#    # curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# 
#    # chmod +x /usr/local/bin/docker-compose
#   EOT 


 tags = { Name = "clima-app-instance" }
}

output "instance_public_ip" {
  value = aws_instance.app.public_ip
}

output "instance_id" {
  value = aws_instance.app.id
}
