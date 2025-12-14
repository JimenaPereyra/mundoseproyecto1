Aplicación del Clima — README
Este repositorio contiene el código fuente de una aplicación web de clima desarrollada en Python usando Flask, que consulta la API de OpenWeatherMap para obtener información meteorológica en tiempo real. 
Se encuentra containerizada con Docker, desplegada automáticamente en AWS EC2 mediante Terraform y con un pipeline CI/CD en GitHub Actions que incorpora calidad, seguridad y observabilidad.
________________________________________

Características Principales:
•	Consulta de clima por ciudad utilizando la API de OpenWeather.
•	Métricas expuestas en /metrics para Prometheus.
•	Dashboard de observabilidad preconfigurado en Grafana.
•	Tests automatizados con pytest y cobertura (pytest-cov)
•	Análisis de calidad de código con SonarCloud.
•	Análisis de seguridad de imágenes Docker con Snyk.
•	Generación de SBOM (CycloneDX) con Syft.
•	CI/CD completo con build, test, scan, push y deploy automático.  

Requisitos previos
Para poder usar y ejecutar este proyecto correctamente, necesitás contar con:
✔️ 1. Cuenta en OpenWeatherMap
La aplicación usa la API pública de OpenWeatherMap. Debés obtener una API Key desde: https://openweathermap.org/api
Luego, configurar la key como variable de entorno:
WEATHER_API_KEY="tu_api_key"
O almacenarla en las GitHub Secrets (recomendado).
✔️ 2. Se requiere una cuenta activa de AWS.
 Crear un Key Pair en AWS EC2 (ej: proyectofinal)
Generar clave SSH localmente
Credenciales necesarias (Github Secrets):
AWS_ACCESS_KEY_ID   (Access Key del usuario IAM).
AWS_SECRET_ACCESS_KEY  (Secret Key del usuario IAM)
AWS_REGION  (Región AWS (ej: us-east-1))
EC2_SSH_PRIVATE_KEY  (Clave privada SSH (PEM))
SSH_PUBLIC_KEY (Clave pública SSH).
✔️ 3. Se requiere una cuenta en SonarCloud.
Se puede iniciar sesión con GitHub, crear la organización y generar token de análisis.
Secret Requerido: 
SONAR_TOKEN  (Token de SonarCloud)

✔️ 4. Se requiere una cuenta en Snyk.
Se crea la cuenta en https://snyk.io y se genera el token.
Secret requerido:
SNYK_TOKEN (Token de Snyk)
✔️ 5. Docker Hub .
Utilizamos dockerhub para publicar la imagen.
Secrets requeridos: 
DOCKERHUB_USERNAME (Usuario DockerHub)
DOCKERHUB_TOKEN (Access Token Docker Hub)

________________________________________
Estructura del proyecto
El repositorio contiene:
.
├── app_clima2.py          # Aplicación principal Flask
├── templates/             # index HTML 
├── static/                # Estilo de la aplicacion
├── tests/                 # Pruebas automatizadas con pytest
├── prometheus/            # Configuracion de prometheus
├── grafana/               # Configuracion de grafana
├── Dockerfile             # Construcción de la imagen Docker
├── Docker-compose.yml     # Orquestacion de app + prometheus + grafana
├── requirements.txt       # Dependencias de producción
├── requirements-dev.txt   # Dependencias de desarrollo y testing
├── sonar-project.properties # Configuración para SonarCloud
├── terraform/             # Infraestructura como código (si aplica)
└── README.md

terraform/ # Infraestructura como código (AWS)
 ├── main.tf
 ├── variables.tf
 ├── providers.tf
 └── outputs.tf


grafana/ # Configuración Grafana
 ├── datasources/
 │    └── datasources.yml
 └── dashboards/
      ├── dashboard.yml
      └── dashboard.json


prometheus/ # Configuración Prometheus
 └── prometheus.yml


________________________________________
Versiones y dependencias
   Versiones utilizadas
•	Python: 3.x (recomendado 3.10+)
•	Flask: 3.1.2
•	Requests: 2.31.0
•	Flask-WTF: 1.2.2
•	Pytest: 8.4.2
•	Pytest-cov: 5.0.0
•	Coverage: última versión estable
Dependencias
Producción – requirements.txt
Flask==3.1.2
requests==2.31.0
Flask-WTF==1.2.2
Desarrollo / Testing – requirements-dev.txt
pytest==8.4.2
pytest-cov==5.0.0
coverage
Instalación recomendada:
pip install -r requirements.txt
pip install -r requirements-dev.txt
________________________________________
Endpoints de la aplicación
Endpoint	Método	Descripción
/	GET	Interfaz web HTML
/clima?ciudad=	GET	Devuelve clima de la ciudad
/health	GET	Healthcheck de la app
/metrics	GET	Métricas Prometheus
________________________________________
CI/CD Pipeline
Pipeline: CI/CD - App Clima2
Etapas
1.	Checkout del código
2.	Setup Python 3.12
3.	Instalación de dependencias
4.	Tests + Coverage
5.	SonarCloud Scan
6.	Build & Push Docker Image
7.	SBOM con Syft
8.	Security Scan con Snyk
9.	Deploy automático en AWS con Terraform
El deploy se ejecuta únicamente sobre la rama main.
________________________________________

Docker
Dockerfile
•	Imagen base: python:3.12-slim
•	Usuario no-root
•	Puerto expuesto: 5000
Docker Compose
Servicios incluidos:
•	app_clima
•	prometheus
•	grafana
________________________________________
Testing
Los tests están ubicados en la carpeta tests/.
Los tests están implementados con pytest y cubren:
•	Casos exitosos y errores del endpoint /clima
•	Cache hit
•	Healthcheck
•	Métricas Prometheus
•	Home page
________________________________________
Integración con SonarCloud
El proyecto incluye un archivo sonar-project.properties con:
sonar.projectKey=JimenaPereyra_mundoseproyecto1
sonar.organization=jimenapereyra
sonar.host.url=https://sonarcloud.io

# Código fuente
sonar.sources=.
sonar.exclusions=tests/**

# Tests
sonar.tests=tests
sonar.test.inclusions=tests/**/*.py
sonar.python.coverage.reportPaths=coverage.xml

# Exclusiones recomendadas
sonar.exclusions=**/.venv/**,**/venv/**,**/__pycache__/**
________________________________________
Infraestructura (Terraform)
La gestión de infraestructura se realiza con Terraform.
Es necesario tener instalado: - Terraform - Credenciales para el proveedor en uso (AWS / GCP / Azure según la configuración del proyecto)
Comandos básicos:
terraform init
terraform plan
terraform apply
________________________________________
Observabilidad 
Prometheus
•	Scrapea métricas cada 15 segundos
•	Target: app_clima:5000/metrics
Métricas expuestas
•	Requests totales y por endpoint
•	Latencia de requests (P95)
•	Latencia API OpenWeather
•	Cache hits / misses
•	Ciudad más consultada
•	Payload size
•	Healthchecks ejecutados
Grafana
•	Datasource auto-provisionado
•	Dashboard incluido: Clima App - Observabilidad
•	Acceso por defecto: http://localhost:3000






