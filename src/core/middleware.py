from django.conf import settings
from django.shortcuts import redirect

EXEMPT_PATHS = frozenset({"/health", "/health/", "/auth/error/", "/logout/"})


class LoginRequiredMiddleware:
    """Redirect unauthenticated requests to OIDC login, except health, OIDC, and static."""

    def __init__(self, get_response):
        self.get_response = get_response
        static_url = settings.STATIC_URL or "/static/"
        if not static_url.startswith("/"):
            static_url = f"/{static_url}"
        self.exempt_prefixes = ("/oidc/", static_url)

    def __call__(self, request):
        if getattr(settings, "OIDC_BYPASS", False) and settings.DEBUG:
            return self.get_response(request)

        path = request.path
        if path in EXEMPT_PATHS or path.startswith(self.exempt_prefixes):
            return self.get_response(request)

        if request.user.is_authenticated:
            return self.get_response(request)

        return redirect(settings.LOGIN_URL)
