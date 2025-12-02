

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


user_data = <<-EOF
#!/bin/bash
set -o pipefail
export DEBIAN_FRONTEND=noninteractive

LOG_FILE="/var/log/user-data-docker.log"
exec > >(tee -a ${LOG_FILE} | logger -t user-data -s 2>/dev/console) 2>&1

echo "== Inicio user_data Docker: $(date)"

# 0) Esperar fin de apt-daily para evitar locks
echo "== Esperando que apt-daily termine..."
for svc in apt-daily.service apt-daily-upgrade.service; do
  if systemctl list-units --type=service | grep -q "$svc"; then
    systemctl stop "$svc" || true
    systemctl kill "$svc" || true
  fi
done
tries=0
while fuser /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock >/dev/null 2>&1; do
  tries=$((tries+1))
  echo "Lock APT presente, intento $tries..."
  sleep 5
  [ $tries -gt 60 ] && { echo "Timeout esperando lock APT"; break; }
done

apt_retry() {
  local cmd="$*"
  local n=0
  until $cmd -o Dpkg::Lock::Timeout=60; do
    n=$((n+1))
    echo "apt intento $n falló: $cmd"
    [ $n -ge 5 ] && return 1
    sleep 5
  done
}

echo "== apt-get update"
apt_retry apt-get update -y || { echo "apt-get update falló"; exit 1; }

echo "== Instalando prereqs"
apt_retry apt-get install -y ca-certificates curl gnupg lsb-release software-properties-common || { echo "Inst prereqs falló"; exit 1; }

echo "== Configurando keyring Docker"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg || { echo "GPG Docker falló"; exit 1; }
chmod a+r /etc/apt/keyrings/docker.gpg

UBUNTU_CODENAME=$(lsb_release -cs)
echo "== Repo Docker para $UBUNTU_CODENAME"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable" \
  | tee /etc/apt/sources.list.d/docker.list >/dev/null

echo "== apt-get update (repo Docker)"
apt_retry apt-get update -y || { echo "apt update Docker repo falló"; exit 1; }

echo "== Instalando Docker Engine + plugins"
apt_retry apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || { echo "Inst Docker falló"; exit 1; }

echo "== Habilitando Docker"
systemctl enable --now docker || { echo "systemctl enable docker falló"; exit 1; }

if id "ubuntu" >/dev/null 2>&1; then
  usermod -aG docker ubuntu || true
  echo "Usuario ubuntu agregado al grupo docker"
fi

echo "== Validaciones"
docker --version || { echo "Docker no responde"; exit 1; }
docker compose version || { echo "Compose plugin no responde"; exit 1; }

echo "== Fin user_data Docker: $(date)"
EOF


 tags = { Name = "clima-app-instance" }
}

output "instance_public_ip" {
  value = aws_instance.app.public_ip
}

output "instance_id" {
  value = aws_instance.app.id
}
