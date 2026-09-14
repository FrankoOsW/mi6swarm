import pytest
from django.test import override_settings
from unittest.mock import patch

from core.middleware import EXEMPT_PATHS

LOGIN_EXEMPT_PATHS = frozenset({"/health", "/health/", "/auth/error/", "/logout/"})


def test_unauthenticated_request_redirects_to_login(anonymous_client):
    response = anonymous_client.get("/")
    assert response.status_code == 302
    assert response.url == "/oidc/authenticate/"


def test_health_endpoint_accessible_without_auth(anonymous_client):
    response = anonymous_client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_login_exempt_paths_are_frozen():
    assert EXEMPT_PATHS == LOGIN_EXEMPT_PATHS


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

    get_logout = authenticated_client.get("/logout/")
    assert get_logout.status_code == 405

    logout_response = authenticated_client.post("/logout/")
    assert logout_response.status_code == 302
    assert logout_response.url == "/"

    after = authenticated_client.get("/")
    assert after.status_code == 302
    assert after.url == "/oidc/authenticate/"


def test_oidc_callback_without_code_redirects_to_auth_error(anonymous_client):
    response = anonymous_client.get("/oidc/callback/")
    assert response.status_code == 302
    assert response.url == "/auth/error/"


def test_oidc_callback_error_param_redirects_to_auth_error(anonymous_client):
    response = anonymous_client.get("/oidc/callback/", {"error": "access_denied"})
    assert response.status_code == 302
    assert response.url == "/auth/error/"


@pytest.mark.django_db
@patch("mozilla_django_oidc.views.auth.authenticate")
def test_oidc_callback_with_code_creates_session(mock_authenticate, client, django_user_model):
    user = django_user_model.objects.create_user(
        username="oidc-analyst",
        email="oidc@example.com",
    )
    user.backend = "mozilla_django_oidc.auth.OIDCAuthenticationBackend"
    mock_authenticate.return_value = user

    session = client.session
    session["oidc_states"] = {"state-1": {"nonce": "nonce-1", "code_verifier": None}}
    session.save()

    response = client.get("/oidc/callback/", {"code": "auth-code", "state": "state-1"})
    assert response.status_code == 302
    assert response.url == "/"
    mock_authenticate.assert_called_once()

    after = client.get("/")
    assert after.status_code == 200
    assert after.json()["service"] == "mi6swarm"
