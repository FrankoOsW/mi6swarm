from __future__ import annotations

from types import SimpleNamespace
from unittest.mock import patch

import pytest
from django.conf import settings
from django.contrib.auth import get_user_model
from django.test import Client

from core.middleware import EXEMPT_PATHS
from tests.support.answer_quality import claim_present, claims_violated, load_all_cases
from tests.support.answer_surface import (
    ANSWER_HTTP,
    GAIP_CHAT_COMPLETIONS_PATCH_TARGET,
    SUBMIT_QUESTION,
    answer_http_method,
    answer_http_path,
    answer_surface_available,
)

SKIP_MISSING = pytest.mark.skipif(
    not answer_surface_available(),
    reason="answer-surface-missing",
)

GROUNDED_PARAPHRASE = (
    "According to the catalog note, Dataset A is refreshed every week."
)
MIXED_COMPLETION = (
    "Dataset A is refreshed every week. Dataset A retains data for 90 days."
)

def test_answer_surface_available_is_false_in_this_repo():
    assert SUBMIT_QUESTION is None
    assert ANSWER_HTTP is None
    assert answer_surface_available() is False


def _cases():
    return load_all_cases()


def _result_mapping(result):
    if isinstance(result, dict):
        return result
    return {
        "text": getattr(result, "text", getattr(result, "answer", "")),
        "refused": getattr(result, "refused", getattr(result, "refusal", False)),
        "error": getattr(result, "error", None),
        "source_ids": getattr(
            result, "source_ids", getattr(result, "provenance", [])
        ),
    }


def _text(result) -> str:
    data = _result_mapping(result)
    return str(data.get("text") or data.get("answer") or "")


def _source_ids(result) -> list[str]:
    data = _result_mapping(result)
    raw = data.get("source_ids") or data.get("provenance") or []
    return [str(item) for item in raw]


def _is_refusal(result) -> bool:
    data = _result_mapping(result)
    refused = data.get("refused")
    if refused is None:
        refused = data.get("refusal")
    if isinstance(refused, str):
        return bool(refused.strip())
    return bool(refused)


def _has_transport_error(result) -> bool:
    return bool(_result_mapping(result).get("error"))


def _is_successful_grounded(result) -> bool:
    return (
        not _is_refusal(result)
        and not _has_transport_error(result)
        and bool(_text(result).strip())
    )


def _completion(content: str):
    return SimpleNamespace(
        choices=[SimpleNamespace(message=SimpleNamespace(content=content))]
    )


def _patch_gaip():
    target = GAIP_CHAT_COMPLETIONS_PATCH_TARGET
    if not target:
        pytest.fail(
            "Set GAIP_CHAT_COMPLETIONS_PATCH_TARGET to the product "
            "chat.completions callable when enabling the answer surface"
        )
    return patch(target)


@SKIP_MISSING
class TestAnswerQualityContract:
    def test_returns_grounded_paraphrase_when_evidence_supports_weekly_refresh(self):
        case = _cases()["weekly-refresh-grounded"]
        with _patch_gaip() as mock_create:
            mock_create.return_value = _completion(GROUNDED_PARAPHRASE)
            result = SUBMIT_QUESTION(case["question"], case["evidence"])

        mock_create.assert_called()
        assert not _is_refusal(result)
        assert not _has_transport_error(result)
        assert set(_source_ids(result)) <= set(case["allowed_source_ids"])
        for fact in case["supported_facts"]:
            assert claim_present(_text(result), fact)
        assert claims_violated(_text(result), case) == []

    def test_refuses_when_evidence_is_empty(self):
        case = _cases()["empty-evidence-refuse"]
        with _patch_gaip() as mock_create:
            mock_create.return_value = _completion(
                "Dataset A is refreshed every week. Dataset A retains data for 90 days."
            )
            result = SUBMIT_QUESTION(case["question"], case["evidence"])

        assert _is_refusal(result)
        assert not _has_transport_error(result)
        assert not _is_successful_grounded(result)
        assert claims_violated(_text(result), case) == []
        assert _source_ids(result) == []

    def test_refuses_when_evidence_is_irrelevant(self):
        case = _cases()["irrelevant-evidence-refuse"]
        with _patch_gaip() as mock_create:
            mock_create.return_value = _completion(
                "Dataset A is refreshed every week because it powers billing."
            )
            result = SUBMIT_QUESTION(case["question"], case["evidence"])

        assert _is_refusal(result)
        assert not _has_transport_error(result)
        assert not _is_successful_grounded(result)
        assert claims_violated(_text(result), case) == []

    def test_rejects_grounded_success_when_completion_mixes_invented_retention(self):
        case = _cases()["mixed-invention"]
        with _patch_gaip() as mock_create:
            mock_create.return_value = _completion(MIXED_COMPLETION)
            result = SUBMIT_QUESTION(case["question"], case["evidence"])

        mock_create.assert_called()
        assert not _is_successful_grounded(result)
        assert claims_violated(_text(result), case) == []

    def test_returns_safe_non_answer_when_provider_times_out(self):
        case = _cases()["weekly-refresh-grounded"]
        with _patch_gaip() as mock_create:
            mock_create.side_effect = TimeoutError("gaip-timeout")
            result = SUBMIT_QUESTION(case["question"], case["evidence"])

        mock_create.assert_called()
        assert not _is_successful_grounded(result)
        assert claims_violated(_text(result), case) == []

    def test_returns_safe_non_answer_when_provider_returns_401_or_malformed(self):
        case = _cases()["weekly-refresh-grounded"]
        with _patch_gaip() as mock_create:
            mock_create.side_effect = PermissionError("401 Unauthorized")
            result = SUBMIT_QUESTION(case["question"], case["evidence"])

        mock_create.assert_called()
        assert not _is_successful_grounded(result)
        assert claims_violated(_text(result), case) == []

        with _patch_gaip() as mock_create:
            mock_create.return_value = {"not": "a chat completion"}
            result = SUBMIT_QUESTION(case["question"], case["evidence"])

        mock_create.assert_called()
        assert not _is_successful_grounded(result)
        assert "not a chat completion" not in _text(result).casefold()


def _request_answer(client, *, include_csrf: bool = False, question: str = "How often does Dataset A refresh?"):
    path = answer_http_path()
    method = answer_http_method()
    extra = {}
    if include_csrf:
        client.get("/")
        token = client.cookies.get("csrftoken")
        if token is not None:
            extra["HTTP_X_CSRFTOKEN"] = token.value
    payload = {"question": question}
    if method == "GET":
        return client.get(path, payload, **extra)
    return client.post(path, payload, content_type="application/json", **extra)


@SKIP_MISSING
class TestAnswerHttp:
    @pytest.fixture
    def csrf_client(self, db):
        client = Client(enforce_csrf_checks=True)
        user = get_user_model().objects.create_user(
            username="csrf-analyst",
            email="csrf@example.com",
            password="unused-for-oidc",
        )
        client.force_login(user)
        return client

    def test_redirects_to_login_when_anonymous(self, anonymous_client):
        with _patch_gaip() as mock_create:
            post_response = anonymous_client.post(
                answer_http_path(),
                {"question": "How often does Dataset A refresh?"},
                content_type="application/json",
            )
            get_response = anonymous_client.get(answer_http_path())

        assert post_response.status_code == 302
        assert post_response.url == settings.LOGIN_URL
        assert get_response.status_code == 302
        assert get_response.url == settings.LOGIN_URL
        mock_create.assert_not_called()

    def test_reaches_answer_boundary_when_authenticated_with_csrf(self, csrf_client):
        with _patch_gaip() as mock_create:
            mock_create.return_value = _completion(GROUNDED_PARAPHRASE)
            response = _request_answer(csrf_client, include_csrf=True)

        assert response.status_code != 302
        assert response.status_code != 403
        mock_create.assert_called()

    def test_returns_403_when_authenticated_without_csrf(self, csrf_client):
        if answer_http_method() == "GET":
            pytest.skip("CSRF does not apply to GET")
        with _patch_gaip() as mock_create:
            response = csrf_client.post(
                answer_http_path(),
                {"question": "How often does Dataset A refresh?"},
                content_type="application/json",
            )

        assert response.status_code == 403
        mock_create.assert_not_called()

    def test_redirects_to_login_when_session_expired(self, authenticated_client):
        authenticated_client.post("/logout/")
        with _patch_gaip() as mock_create:
            response = _request_answer(authenticated_client)

        assert response.status_code == 302
        assert response.url == settings.LOGIN_URL
        mock_create.assert_not_called()

    def test_answer_path_is_not_login_exempt(self):
        path = answer_http_path()
        variants = {path, path.rstrip("/") or "/", f"{path.rstrip('/')}/"}
        assert variants.isdisjoint(EXEMPT_PATHS)
        for variant in variants:
            assert not variant.startswith("/oidc/")
