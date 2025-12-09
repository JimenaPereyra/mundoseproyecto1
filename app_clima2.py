import os
import time
import json
from datetime import datetime, timezone
from flask import Flask, render_template, request, jsonify, Response
from  flask_wtf.csrf import  CSRFProtect
import requests
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

logger = logging.getLogger(__name__)

#para las metricas

from prometheus_client import (
    Gauge, Counter, Histogram, Summary,
    generate_latest, CONTENT_TYPE_LATEST
)
import threading



app = Flask(__name__)

app.config['SECRET_KEY']=os.getenv('SECRET_KEY', 'test-secret-key') #NOSONAR

csrf = CSRFProtect(app)

API_KEY = os.getenv("WEATHER_API_KEY")

# ================================
# MÉTRICAS PROMETHEUS
# ================================

# ----- Métricas OpenWeather -----
temperature_gauge = Gauge(
    "clima_last_temperature",
    "Última temperatura obtenida (°C)",
    ["city"]
)

api_latency = Histogram(
    "clima_openweather_latency_seconds",
    "Latencia de llamadas a la API de OpenWeather"
)

cache_hits = Counter(
    "clima_cache_hits_total",
    "Cantidad de aciertos en cache"
)

cache_misses = Counter(
    "clima_cache_misses_total",
    "Cantidad de fallos en cache"
)

healthcheck_counter = Counter(
    "clima_health_checks_total",
    "Total de healthchecks ejecutados"
)

# ----- Métricas de la APP -----
REQUEST_COUNT = Counter(
    "app_requests_total",
    "Total de requests recibidos",
    ["endpoint", "method"]
)

REQUEST_ERRORS = Counter(
    "app_request_errors_total",
    "Total de errores por endpoint",
    ["endpoint", "type"]
)

REQUEST_LATENCY = Histogram(
    "app_request_latency_seconds",
    "Latencia por request",
    ["endpoint"]
)

CITY_QUERIES = Counter(
    "app_city_queries_total",
    "Cantidad de consultas por ciudad",
    ["city"]
)

CITY_MOST_QUERIED = Gauge(
    "app_city_most_queried",
    "Ciudad con más consultas (cambia dinámicamente)"
)

PAYLOAD_SIZE = Summary(
    "app_response_payload_bytes",
    "Tamaño de las respuestas en bytes"
)

# Contador interno para determinar ciudad más consultada
city_counter = {}
city_counter_lock = threading.Lock()

# -------------------------
# Cache simple en memoria
# -------------------------
# cache structure: { "ciudad_lower": {"temp": 20.1, "ts": 1234567890} }
cache = {}
CACHE_TTL = int(os.getenv("CACHE_TTL_SECONDS", "60"))  # segundos
cache_lock = threading.Lock()

# -------------------------
# Helpers
# -------------------------
def update_city_metrics(city_name: str):
    """Actualizar counters y gauge de ciudad más consultada."""
    cname = city_name.lower()
    with city_counter_lock:
        city_counter[cname] = city_counter.get(cname, 0) + 1
        CITY_QUERIES.labels(city=cname).inc()
        # actualizar gauge con el máximo actual
        top_count = max(city_counter.values())
        CITY_MOST_QUERIED.set(top_count)


def get_cached(ciudad: str):
    """Devuelve temp si está en cache y no expiró, sino None."""
    key = ciudad.lower()
    with cache_lock:
        data = cache.get(key)
        if not data:
            return None
        if (time.time() - data["ts"]) > CACHE_TTL:
            # expired
            del cache[key]
            return None
        return data["temp"]


def set_cache(ciudad: str, temp: float):
    key = ciudad.lower()
    with cache_lock:
        cache[key] = {"temp": temp, "ts": time.time()}


# ================================
# HOME
# ================================


@app.route("/")
def home():
    REQUEST_COUNT.labels(endpoint="/", method="GET").inc()
    return render_template("index.html")

@app.route("/health", methods=["GET"])
def health():
    # Simple health check endpoint
    healthcheck_counter.inc()
    REQUEST_COUNT.labels(endpoint="/health", method="GET").inc()
    return jsonify({"status": "ok", "timestamp": datetime.now(timezone.utc).isoformat()}), 200



@app.route("/clima", methods=["GET"])
def clima():

    REQUEST_COUNT.labels(endpoint=request.endpoint,method=request.method).inc()
    start_request = time.perf_counter()

    ciudad = request.args.get("ciudad")
    if not ciudad:

        REQUEST_ERRORS.labels(endpoint=request.endpoint, type="missing_city").inc()
        duration = time.perf_counter() - start_request
        REQUEST_LATENCY.labels(endpoint=request.endpoint).observe(duration)

        return jsonify({"error": "Debe ingresar una ciudad"}), 400

    ciudad_norm = ciudad.strip().lower()
    # Primero, intentar cache
    cached_temp = get_cached(ciudad_norm)
    if cached_temp is not None:
        cache_hits.inc()
        # actualizar métricas relacionadas
        update_city_metrics(ciudad_norm)
        temperature_gauge.labels(city=ciudad_norm).set(cached_temp)
        duration = time.perf_counter() - start_request
        REQUEST_LATENCY.labels(endpoint=request.endpoint).observe(duration)
        payload = {"ciudad": ciudad_norm, "temp": cached_temp, "cached": True}
        PAYLOAD_SIZE.observe(len(json.dumps(payload).encode("utf-8")))
        return jsonify(payload)

    # Cache miss
    cache_misses.inc()

    # Llamada externa a OpenWeather con medición de latencia
    openw_start = time.perf_counter()
    try:
        url = f"https://api.openweathermap.org/data/2.5/weather?q={ciudad}&appid={API_KEY}&units=metric&lang=es"
        resp = requests.get(url, timeout=15)
    except requests.RequestException as e:
        logger.error(f"Error consultando OpenWeather: {e}")
        raise

        # Error de conexión/timeout al llamar OpenWeather
        REQUEST_ERRORS.labels(endpoint=request.endpoint, type="openweather_connection").inc()
        duration = time.perf_counter() - start_request
        REQUEST_LATENCY.labels(endpoint=request.endpoint).observe(duration)
        return jsonify({"error": "Error al conectar con el servicio de clima"}), 502
    openw_duration = time.perf_counter() - openw_start
    api_latency.observe(openw_duration)

    # Procesar respuesta
    try:
        datos = resp.json()
    except ValueError:
        REQUEST_ERRORS.labels(endpoint=request.endpoint, type="openweather_bad_json").inc()
        duration = time.perf_counter() - start_request
        REQUEST_LATENCY.labels(endpoint=request.endpoint).observe(duration)
        return jsonify({"error": "Respuesta inválida del servicio de clima"}), 502

    if resp.status_code != 200:
        REQUEST_ERRORS.labels(endpoint=request.endpoint, type="openweather_status").inc()
        duration = time.perf_counter() - start_request
        REQUEST_LATENCY.labels(endpoint=request.endpoint).observe(duration)
        return jsonify({"error": "Ciudad no encontrada"}), 404

    temp = datos.get("main", {}).get("temp")
    nombre = datos.get("name", ciudad)

    # Actualizar cache y métricas
    if temp is not None:
        set_cache(ciudad_norm, temp)
        temperature_gauge.labels(city=ciudad_norm).set(temp)

    # actualizar métricas de ciudad y request
    update_city_metrics(ciudad_norm)
    duration = time.perf_counter() - start_request
    REQUEST_LATENCY.labels(endpoint=request.endpoint).observe(duration)

    resultado = {
        "ciudad": nombre,
        "temp": temp,
        "descripcion": datos.get("weather", [{}])[0].get("description", ""),
        "cached": False,
    }

    # payload size
    PAYLOAD_SIZE.observe(len(json.dumps(resultado).encode("utf-8")))

    return jsonify(resultado)

@app.route("/metrics")
def metrics():
    # endpoint que devuelve todas las métricas Prometheus
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

# ================================
# MAIN
# ================================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

