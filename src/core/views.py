from django.contrib.auth import logout
from django.http import JsonResponse
from django.shortcuts import redirect, render
from django.urls import reverse


def health(request):
    return JsonResponse({"status": "healthy"})


def index(request):
    return JsonResponse({
        "service": "mi6swarm",
        "version": "0.1.0",
        "status": "ok",
    })


def oidc_error(request):
    return render(
        request,
        "core/oidc_error.html",
        {"login_url": reverse("oidc_authentication_init")},
    )


def logout_view(request):
    logout(request)
    return redirect("/")
