import json
import pytest
from app_clima2 import app
import requests


@pytest.fixture
def client():
    app.config["TESTING"] = True
    return app.test_client()


def test_clima_sin_ciudad(client):
    """Debe devolver 400 si no se envía ciudad"""
    response = client.get("/clima")
    assert response.status_code == 400
    data = response.get_json()
    assert data["error"] == "Debe ingresar una ciudad"


def test_clima_ciudad_no_encontrada(client, monkeypatch):
    """Mockea requests.get para simular ciudad inexistente"""

    class MockResponse:
        status_code = 404

        def json(self):
            return {"message": "city not found"}

    monkeypatch.setattr(requests, "get", lambda url, *args, **kwargs: MockResponse())

    response = client.get("/clima?ciudad=Desconocida")
    assert response.status_code == 404
    assert response.get_json()["error"] == "Ciudad no encontrada"


def test_clima_exito(client, monkeypatch):
    """Mockea la API para simular una respuesta exitosa"""

    class MockResponse:
        status_code = 200

        def json(self):
            return {
                "name": "Buenos Aires",
                "main": {"temp": 22},
                "weather": [{"description": "cielo despejado"}],
            }

    monkeypatch.setattr(requests, "get", lambda url, *args, **kwargs: MockResponse())

    response = client.get("/clima?ciudad=Buenos Aires")
    assert response.status_code == 200

    data = response.get_json()
    assert data["ciudad"] == "Buenos Aires"
    assert data["temp"] == 22
    assert data["descripcion"] == "cielo despejado"

def test_home(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"<html" in response.data or response.mimetype == "text/html"

def test_metrics(client):
    response = client.get("/metrics")
    assert response.status_code == 200
    assert response.mimetype == "text/plain"
    assert b"# HELP" in response.data  # Las métricas empiezan así

def test_clima_error_conexion(client, monkeypatch):
    def raise_exception(*args, **kwargs):
        raise requests.RequestException("boom")

    monkeypatch.setattr(requests, "get", raise_exception)

    response = client.get("/clima?ciudad=Rosario")
    assert response.status_code == 502
    assert response.get_json()["error"] == "Error al conectar con el servicio de clima"

def test_clima_json_invalido(client, monkeypatch):
    class MockResponse:
        status_code = 200
        def json(self):
            raise ValueError("invalid json")

    monkeypatch.setattr(requests, "get", lambda *args, **kwargs: MockResponse())

    response = client.get("/clima?ciudad=Rosario")
    assert response.status_code == 502
    assert response.get_json()["error"] == "Respuesta inválida del servicio de clima"

def test_clima_cache_hit(client, monkeypatch):
    # Primero simulamos éxito
    class MockResponse:
        status_code = 200
        def json(self):
            return {
                "name": "Córdoba",
                "main": {"temp": 20},
                "weather": [{"description": "soleado"}],
            }

    monkeypatch.setattr(requests, "get", lambda *args, **kwargs: MockResponse())

    # Primer llamado -> guarda en cache
    client.get("/clima?ciudad=Córdoba")

    # Segundo llamado -> debería devolver cached=True
    response = client.get("/clima?ciudad=Córdoba")
    data = response.get_json()

    assert response.status_code == 200
    assert data["cached"] is True

def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data["status"] == "ok"
    assert "timestamp" in json_data
