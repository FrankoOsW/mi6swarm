import os

from .base import *

DEBUG = True

SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "insecure-dev-key-change-in-production")

ALLOWED_HOSTS = ["localhost", "127.0.0.1", "0.0.0.0"]

# Auth bypass for local development - NEVER enable in production
# When True and DEBUG=True, LoginRequiredMiddleware allows all requests
OIDC_BYPASS = os.environ.get("OIDC_BYPASS", "false").lower() == "true"
