import os

from fastapi import FastAPI

from . import config as c

SENTRY_DSN = os.environ.get("SENTRY_DSN", "")
SENTRY_ENVIRONMENT = os.environ.get("APPLICATION_ENVIRONMENT", "")

if SENTRY_DSN and SENTRY_ENVIRONMENT:
    import sentry_sdk

    sentry_sdk.init(
        dsn=SENTRY_DSN,
        environment=SENTRY_ENVIRONMENT,
        traces_sample_rate=1.0,
        profiles_sample_rate=1.0,
    )

app = FastAPI(
    title=c.title,
    docs_url="/docs" if c.show_docs else None,
)


@app.get("/health")
async def health_check():
    """Health check endpoint. Required for Kubernetes liveness and readiness probes."""
    return {
        "status": "healthy",
        "message": f"Hello! This is {c.title} speaking.",
    }


@app.get("/")
async def root():
    return {"message": "Hello World"}
