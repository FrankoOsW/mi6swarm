from django.urls import path

from . import views

urlpatterns = [
    path("health", views.health, name="health"),
    path("auth/error/", views.oidc_error, name="oidc_error"),
    path("logout/", views.logout_view, name="logout"),
    path("", views.index, name="index"),
]
