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
