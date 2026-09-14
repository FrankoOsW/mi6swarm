import os
import subprocess
import sys
from pathlib import Path

import pytest

PRODUCTION_SETTINGS = Path("src/config/settings/production.py")


def test_production_settings_file_has_no_oidc_bypass():
    text = PRODUCTION_SETTINGS.read_text(encoding="utf-8")
    assert "OIDC_BYPASS" not in text


def _load_production_settings(extra_env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env.update(
        {
            "DJANGO_SECRET_KEY": "test-secret-not-for-prod",
            "DJANGO_SETTINGS_MODULE": "config.settings.production",
            "PYTHONPATH": "src",
            "ALLOWED_HOSTS": "localhost",
            "CSRF_TRUSTED_ORIGINS": "https://localhost",
        }
    )
    env.update(extra_env)
    return subprocess.run(
        [
            sys.executable,
            "-c",
            "from django.conf import settings; settings.DEBUG",
        ],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )


@pytest.mark.parametrize(
    ("missing", "fragment"),
    [
        ("OKTA_DOMAIN", "OKTA_DOMAIN"),
        ("OIDC_RP_CLIENT_ID", "OIDC_RP_CLIENT_ID"),
        ("OIDC_RP_CLIENT_SECRET", "OIDC_RP_CLIENT_SECRET"),
    ],
)
def test_production_settings_fail_fast_when_okta_env_missing(missing, fragment):
    okta_env = {
        "OKTA_DOMAIN": "example.okta.com",
        "OIDC_RP_CLIENT_ID": "client-id",
        "OIDC_RP_CLIENT_SECRET": "client-secret",
    }
    okta_env[missing] = ""
    result = _load_production_settings(okta_env)
    assert result.returncode != 0
    assert fragment in result.stderr


def test_production_settings_set_secure_cookies_when_okta_configured():
    env = os.environ.copy()
    env.update(
        {
            "DJANGO_SECRET_KEY": "test-secret-not-for-prod",
            "DJANGO_SETTINGS_MODULE": "config.settings.production",
            "PYTHONPATH": "src",
            "ALLOWED_HOSTS": "localhost",
            "CSRF_TRUSTED_ORIGINS": "https://localhost",
            "OKTA_DOMAIN": "example.okta.com",
            "OIDC_RP_CLIENT_ID": "client-id",
            "OIDC_RP_CLIENT_SECRET": "client-secret",
        }
    )
    script = (
        "from django.conf import settings; "
        "assert settings.SESSION_COOKIE_SECURE is True; "
        "assert settings.CSRF_COOKIE_SECURE is True; "
        "assert getattr(settings, 'OIDC_BYPASS', False) is False"
    )
    result = subprocess.run(
        [sys.executable, "-c", script],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == 0, result.stderr
