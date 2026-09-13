import pytest
from django.test import Client


@pytest.fixture
def client():
    return Client()


def test_root(client):
    response = client.get("/")
    assert response.status_code == 302
    assert response.url == "/oidc/authenticate/"


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
