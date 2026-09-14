import pytest
from django.contrib.auth import get_user_model


@pytest.fixture
def anonymous_client(client):
    return client


@pytest.fixture
def authenticated_client(client, db):
    user = get_user_model().objects.create_user(
        username="analyst",
        email="analyst@example.com",
        password="unused-for-oidc",
    )
    client.force_login(user)
    return client
