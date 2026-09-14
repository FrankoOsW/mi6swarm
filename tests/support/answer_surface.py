"""Skip gate for gated-answer quality tests.

Fill these against real `core` application code when the product answer surface
lands. Do not point them at a health-style exemption, an unauthenticated stub,
or a live model.

``SUBMIT_QUESTION``
    Callable invoked as ``(question, evidence)`` (or equivalent) that returns a
    structured result the tests can inspect for answer text, provenance/source
    ids, and refusal.

``ANSWER_HTTP``
    Mapping or object with HTTP ``method`` and either a URL ``path`` or a Django
    reverse ``name``. Used only by the integration tests.

``GAIP_CHAT_COMPLETIONS_PATCH_TARGET``
    Dotted path of the GAIP OpenAI-compatible ``chat.completions`` create
    callable. Tests patch this edge; they do not mock the grounding/refusal
    function under test.
"""

from __future__ import annotations

from typing import Any, Callable

SUBMIT_QUESTION: Callable[..., Any] | None = None
ANSWER_HTTP: Any = None
GAIP_CHAT_COMPLETIONS_PATCH_TARGET: str | None = None


def answer_surface_available() -> bool:
    """Return True when a real application answer surface is wired for tests."""
    return callable(SUBMIT_QUESTION) and ANSWER_HTTP is not None


def answer_http_path() -> str:
    """Resolve the answer HTTP path from ``ANSWER_HTTP``."""
    spec = ANSWER_HTTP
    path = _attr(spec, "path")
    if path:
        return str(path)
    name = _attr(spec, "name")
    if not name:
        raise RuntimeError("ANSWER_HTTP must provide path or Django reverse name")
    from django.urls import reverse

    return reverse(str(name))


def answer_http_method() -> str:
    """Return the HTTP method declared on ``ANSWER_HTTP`` (default POST)."""
    spec = ANSWER_HTTP
    method = _attr(spec, "method") or "POST"
    return str(method).upper()


def _attr(spec: Any, key: str) -> Any:
    if spec is None:
        return None
    if isinstance(spec, dict):
        return spec.get(key)
    return getattr(spec, key, None)
