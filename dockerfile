#Imagen base de Python
FROM python:3.12-slim

#Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app_clima2.py"]
