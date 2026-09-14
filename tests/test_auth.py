import pytest
from django.test import override_settings


def test_unauthenticated_request_redirects_to_login(anonymous_client):
    response = anonymous_client.get("/")
    assert response.status_code == 302
    assert response.url == "/oidc/authenticate/"


def test_health_endpoint_accessible_without_auth(anonymous_client):
    response = anonymous_client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_authenticated_request_returns_200(authenticated_client):
    response = authenticated_client.get("/")
    assert response.status_code == 200
    assert response.json()["service"] == "mi6swarm"


@override_settings(DEBUG=True, OIDC_BYPASS=True)
def test_oidc_bypass_allows_access_when_debug_true(anonymous_client):
    response = anonymous_client.get("/")
    assert response.status_code == 200
    assert response.json()["service"] == "mi6swarm"


@override_settings(DEBUG=False, OIDC_BYPASS=True)
def test_oidc_bypass_ignored_when_debug_false(anonymous_client):
    response = anonymous_client.get("/")
    assert response.status_code == 302
    assert response.url == "/oidc/authenticate/"


@pytest.mark.django_db
def test_logout_clears_session(authenticated_client):
    assert authenticated_client.get("/").status_code == 200

    logout_response = authenticated_client.get("/logout/")
    assert logout_response.status_code == 302
    assert logout_response.url == "/"

    after = authenticated_client.get("/")
    assert after.status_code == 302
    assert after.url == "/oidc/authenticate/"
