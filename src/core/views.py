from django.http import JsonResponse


def health(request):
    return JsonResponse({"status": "healthy"})


def index(request):
    return JsonResponse({
        "service": "mi6swarm",
        "version": "0.1.0",
        "status": "ok",
    })
