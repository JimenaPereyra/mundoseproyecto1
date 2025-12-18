# 🌦️ Aplicación del Clima — App Clima2

Aplicación web de consulta de clima desarrollada en **Python + Flask**, que consume la API de **OpenWeatherMap** para obtener información meteorológica en tiempo real.

La solución está **containerizada con Docker**, cuenta con **observabilidad completa (Prometheus + Grafana)**, **CI/CD automatizado con GitHub Actions**, análisis de **calidad y seguridad**, y **despliegue automático en AWS EC2 mediante Terraform**.

---
## 🎥 Demo de la aplicación

https://github.com/user-attachments/assets/d381b1e9-14b3-441e-8147-a8b3b95de37d


---
## ✨ Características principales

- 🌍 Consulta de clima por ciudad usando **OpenWeather API**
- 📈 Métricas expuestas en `/metrics` para **Prometheus**
- 📊 Dashboard de observabilidad preconfigurado en **Grafana**
- 🧪 Tests automatizados con **pytest** y **coverage**
- 🔍 Análisis de calidad de código con **SonarCloud**
- 🛡️ Análisis de seguridad de imágenes Docker con **Snyk**
- 📦 Generación de **SBOM (CycloneDX)** con **Syft**
- 🔄 CI/CD completo: build, test, scan, push y deploy automático.

---

## ✅ Requisitos previos

### 🌦️ OpenWeatherMap

- Crear cuenta en: https://openweathermap.org/api
- Generar una **API Key**

Variable requerida:
```bash

WEATHER_API_KEY="tu_api_key"
```

---

### ☁️ AWS (Deploy)

Se requiere una **cuenta activa de AWS**.

Configuración necesaria:
- Usuario IAM con permisos sobre EC2, VPC y Security Groups
- Key Pair para EC2 (ej: `proyectofinal`)
- Claves SSH

**GitHub Secrets requeridos:**

| Secret | Descripción |
|------|-------------|
| `AWS_ACCESS_KEY_ID` | Access Key del usuario IAM |
| `AWS_SECRET_ACCESS_KEY` | Secret Key del usuario IAM |
| `AWS_REGION` | Región AWS (ej: `us-east-1`) |
| `EC2_SSH_PRIVATE_KEY` | Clave privada SSH (PEM) |
| `SSH_PUBLIC_KEY` | Clave pública SSH |

---

### 🔍 SonarCloud

- Iniciar sesión con GitHub
- Crear organización
- Generar token

**Secret requerido:**
- `SONAR_TOKEN`

---

### 🛡️ Snyk

- Crear cuenta en https://snyk.io
- Generar API Token

**Secret requerido:**
- `SNYK_TOKEN`

---

### 🐳 Docker Hub

Se utiliza para publicar la imagen Docker.

**Secrets requeridos:**
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

Para descargar la imagen desde Docker Hub y generar el .tar se puede realizar lo siguiente:

**Pull de la imagen desde Doker Hub**
```bash

docker pull jimenapereyra/app_clima2:58fbd009
```

**Exportar la imagen a un .tar**

docker save jimepereyra/app_clima2:58fbd009 -o app_clima2_<TAG>.tar

En el pipeline se esta generando el artifact .tar

Con ello puede hacer:
docker load -i app_clima2_<TAG>.tar
docker run -d -p 8000:8000 jimepereyra/app_clima2:<TAG>



---

## 📁 Estructura del proyecto

```
.
├── app_clima2.py              # Aplicación principal Python - Flask 
├── docker-compose.yml         # App + Prometheus + Grafana
├── Dockerfile                 # Imagen Docker
├── requirements.txt           # Dependencias de producción
├── requirements-dev.txt       # Dependencias de desarrollo/testing
├── sonar-project.properties   # Configuración SonarCloud
├── tests/                     # Tests automatizados
│   └── test_app.py
├── templates/                 # Templates HTML
│   └── index.html
├── static/                    # CSS
│   └── estilo.css
├── prometheus/                # Configuración Prometheus
│   └── prometheus.yml
├── grafana/                   # Configuración Grafana
│   ├── datasources/
│   │   └── datasources.yml
│   └── dashboards/
│       ├── dashboard.yml
│       └── dashboard.json
├── terraform/                 # Infraestructura AWS
│   ├── main.tf
│   ├── variables.tf
│   ├── providers.tf
│   └── outputs.tf
└── README.md
```

---

## 🚀 Endpoints de la aplicación

| Endpoint | Método | Descripción |
|--------|--------|-------------|
| `/` | GET | Interfaz web HTML |
| `/clima?ciudad=` | GET | Devuelve clima de la ciudad |
| `/health` | GET | Healthcheck |
| `/metrics` | GET | Métricas Prometheus |

---

## 🔄 CI/CD Pipeline

**Pipeline:** `CI/CD - App Clima2`

### Etapas

1. 📥 Checkout del código
2. 🐍 Setup Python 3.12
3. 📦 Instalación de dependencias
4. 🧪 Tests + Coverage
5. 🔍 SonarCloud Scan
6. 🐳 Build & Push Docker Image
7. 📦 SBOM con Syft
8. 🛡️ Security Scan con Snyk
9. ☁️ Deploy automático en AWS con Terraform

📌 El deploy se ejecuta únicamente sobre la rama **main**.

---

## 🐳 Docker

### Dockerfile
- Imagen base: `python:3.12-slim`
- Usuario no-root
- Puerto expuesto: `5000`

### Docker Compose
Servicios incluidos:
- `app_clima`
- `prometheus`
- `grafana`

Levantar entorno local:
```bash
docker compose up -d --build
```

---

## 🧪 Testing

Los tests se encuentran en la carpeta `tests/` y cubren:

- ✔️ Casos exitosos y errores del endpoint `/clima`
- ✔️ Cache hit
- ✔️ Healthcheck
- ✔️ Métricas Prometheus
- ✔️ Home page

Ejecutar tests localmente:
```bash
pytest --cov=app_clima2 --cov-report=term
```

---

## ☁️ Infraestructura como Código (Terraform)

La infraestructura se gestiona mediante **Terraform**, permitiendo un despliegue reproducible y automatizado en **AWS EC2**.

### Recursos aprovisionados

- Instancia EC2
- Security Groups (puertos 22, 5000, 3000, 9090)
- Key Pair SSH
- Variables y outputs configurables

### Requisitos

- Terraform instalado (`>= 1.6`)
- Credenciales AWS configuradas (IAM)

### Comandos básicos

```bash
terraform init
terraform plan
terraform apply
```

📌 El deploy se ejecuta automáticamente desde el pipeline **solo en la rama `main`**.

---

## 📊 Observabilidad

### Prometheus
- Scrapea métricas cada 15 segundos
- Target: `app_clima:5000/metrics`

### Grafana
- Datasource auto-provisionado
- Dashboard incluido: **Clima App - Observabilidad**
- Acceso por defecto: http://localhost:3000

---

## 🧰 Versiones y dependencias

### Versiones utilizadas

| Componente | Versión |
|----------|---------|
| Python | 3.12 |
| Flask | 3.1.2 |
| Requests | 2.31.0 |
| Flask-WTF | 1.2.2 |
| Pytest | 8.4.2 |
| Pytest-cov | 5.0.0 |
| Coverage | Última versión estable |
| Docker | 24.x+ |
| Docker Compose | v2 |
| Terraform | 1.6+ |

### Dependencias

**Producción – `requirements.txt`**
```txt
Flask==3.1.2
requests==2.31.0
Flask-WTF==1.2.2
```

**Desarrollo / Testing – `requirements-dev.txt`**
```txt
pytest==8.4.2
pytest-cov==5.0.0
coverage
```

---
