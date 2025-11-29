#Imagen base de Python
FROM python:3.12-slim

# crear usuario no-root
RUN groupadd -r app && useradd -r -g app app

#Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# asegurar permisos (para user "app")
RUN chown -R app:app /app

USER app

EXPOSE 5000

CMD ["python", "app_clima2.py"]
