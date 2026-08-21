# import uvicorn
# from fastapi import FastAPI, Request
import logging

# from contextlib import asynccontextmanager
import os
import time
from typing import Any

# from structlog.testing import capture_logs
from urllib.parse import quote as url_encode

import structlog
import uvicorn
from asgi_correlation_id import CorrelationIdMiddleware
from asgi_correlation_id.context import correlation_id

# from ddtrace.contrib.asgi.middleware import TraceMiddleware
from fastapi import FastAPI, Request, Response
from olx_otel_lib import flush_baselines, get_meter, setup_telemetry, shutdown
from pydantic.deprecated.tools import parse_obj_as
from uvicorn.protocols.utils import get_path_with_query_string

from src import config as c
from src.custom_logging import setup_logging
from src.models import Message
from src.sentry import setup_sentry

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
setup_logging(json_logs=True, log_level=LOG_LEVEL)
setup_sentry()
tracer = setup_telemetry(service_name=os.getenv('OTEL_SERVICE_NAME'))
flush_baselines()
app = FastAPI(
    title=c.title,
    docs_url="/docs" if c.show_docs else None,
    version=c.version,
)


@app.middleware("http")
async def logging_middleware(request: Request, call_next) -> Response:
    structlog.contextvars.clear_contextvars()
    # These context vars will be added to all log entries emitted during the request
    request_id = correlation_id.get()
    structlog.contextvars.bind_contextvars(request_id=request_id)
    start_time = time.perf_counter_ns()

    # If the call_next raises an error, we still want to return our own 500 response,
    # so we can add headers to it (process time, request ID...)
    response = Response(status_code=500)
    try:
        response = await call_next(request)
    except Exception:
        # TODO: Validate that we don't swallow exceptions (unit test?)
        structlog.stdlib.get_logger("api.error").exception("Uncaught exception")
        raise
    finally:
        end_time = time.perf_counter_ns()
        processing_time_ms = (end_time - start_time) / 1e6
        status_code = response.status_code
        url = get_path_with_query_string(request.scope)
        path = url_encode(request.scope["path"])
        client_host = request.client.host if request.client else "unknown"
        client_port = request.client.port if request.client else 0
        http_method = request.method
        http_version = request.scope["http_version"]
        access_logger = structlog.get_logger("api.access")
        access_logger.info(
            f"""{client_host}:{client_port} - "{http_method} {url} HTTP/{http_version}" {status_code}""",
            http={
                "url": str(request.url),
                "path": str(path),
                "status_code": status_code,
                "method": http_method,
                "version": http_version,
            },
            network={"client": {"ip": client_host, "port": client_port}},
            duration_ms=processing_time_ms,
        )
        response.headers["X-Process-Time"] = str(processing_time_ms)
        return response


# This middleware must be placed after the logging, to populate the context with the request ID
# NOTE: Why last??
# Answer: middlewares are applied in the reverse order of when they are added (you can verify this
# by debugging `app.middleware_stack` and recursively drilling down the `app` property).
# app.add_middleware(RouterMiddleware)
app.add_middleware(CorrelationIdMiddleware)


@app.get("/hello")
def hello():
    custom_structlog_logger = structlog.stdlib.get_logger("my.structlog.logger")
    custom_structlog_logger.info("This is an info message from Structlog")
    custom_structlog_logger.warning(
        "This is a warning message from Structlog, with attributes",
        an_extra="attribute",
    )
    custom_structlog_logger.error("This is an error message from Structlog")

    custom_logging_logger = logging.getLogger("my.logging.logger")
    custom_logging_logger.info("This is an info message from standard logger")
    custom_logging_logger.warning(
        "This is a warning message from standard logger, with attributes",
        extra={"another_extra": "attribute"},
    )

    return "Hello, World!"


@app.get("/ready")
@app.get("/health")
async def health_check():
    """Health check endpoint. Required for Kubernetes liveness and readiness probes."""
    return {
        "status": "healthy",
        "message": f"Hello! This is {c.title} speaking.",
    }


@app.get("/")
async def root(reponse_model=Message) -> Any:
    return {"message": "Hello, World!"}


# force a sentry erorr trace
@app.get("/error")
async def error(one: int, two: int):
    """Example with traceback"""
    return one / two


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000, log_config=None)
