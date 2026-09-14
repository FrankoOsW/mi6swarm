from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Mapping

REQUIRED_FIELDS = (
    "id",
    "question",
    "evidence",
    "expected",
    "supported_facts",
    "forbidden_facts",
    "allowed_source_ids",
)

EXPECTED_VALUES = frozenset({"grounded", "refuse"})

CORPUS_DIR = Path(__file__).resolve().parent.parent / "fixtures" / "answer_quality"


class FixtureError(ValueError):
    """Raised when an answer-quality fixture is missing fields or internally inconsistent."""


def _as_str_list(value: Any, field: str, *, path: Path) -> list[str]:
    if not isinstance(value, list) or any(not isinstance(item, str) or not item.strip() for item in value):
        raise FixtureError(f"{path.name}: {field} must be a list of non-empty strings")
    return value


def _normalize(text: str) -> str:
    return " ".join(text.casefold().split())


def _evidence_blob(evidence: list[dict[str, str]]) -> str:
    return " ".join(item["text"] for item in evidence)


def _parse_evidence(raw: Any, *, path: Path) -> list[dict[str, str]]:
    if not isinstance(raw, list):
        raise FixtureError(f"{path.name}: evidence must be a list")
    parsed: list[dict[str, str]] = []
    seen_ids: set[str] = set()
    for item in raw:
        if not isinstance(item, dict) or set(item) != {"source_id", "text"}:
            raise FixtureError(
                f"{path.name}: each evidence item must be an object with source_id and text only"
            )
        source_id = item["source_id"]
        text = item["text"]
        if not isinstance(source_id, str) or not source_id.strip():
            raise FixtureError(f"{path.name}: evidence.source_id must be a non-empty string")
        if not isinstance(text, str) or not text.strip():
            raise FixtureError(f"{path.name}: evidence.text must be a non-empty string")
        if source_id in seen_ids:
            raise FixtureError(f"{path.name}: duplicate evidence source_id {source_id!r}")
        seen_ids.add(source_id)
        parsed.append({"source_id": source_id, "text": text})
    return parsed


def load_case(path: Path) -> dict[str, Any]:
    """Load and validate one answer-quality fixture file.

    Args:
        path: Path to a JSON fixture.

    Returns:
        The validated fixture mapping.

    Raises:
        FixtureError: If required fields are missing or the corpus is inconsistent.
    """
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise FixtureError(f"{path.name}: invalid JSON ({exc})") from exc
    if not isinstance(payload, dict):
        raise FixtureError(f"{path.name}: fixture must be a JSON object")

    missing = [field for field in REQUIRED_FIELDS if field not in payload]
    if missing:
        raise FixtureError(f"{path.name}: missing required fields: {', '.join(missing)}")

    case_id = payload["id"]
    question = payload["question"]
    expected = payload["expected"]
    if not isinstance(case_id, str) or not case_id.strip():
        raise FixtureError(f"{path.name}: id must be a non-empty string")
    if not isinstance(question, str) or not question.strip():
        raise FixtureError(f"{path.name}: question must be a non-empty string")
    if expected not in EXPECTED_VALUES:
        raise FixtureError(f"{path.name}: expected must be 'grounded' or 'refuse'")

    evidence = _parse_evidence(payload["evidence"], path=path)
    supported_facts = _as_str_list(payload["supported_facts"], "supported_facts", path=path)
    forbidden_facts = _as_str_list(payload["forbidden_facts"], "forbidden_facts", path=path)
    allowed_source_ids = _as_str_list(
        payload["allowed_source_ids"], "allowed_source_ids", path=path
    )

    evidence_ids = {item["source_id"] for item in evidence}
    unknown_allowed = [sid for sid in allowed_source_ids if sid not in evidence_ids]
    if unknown_allowed:
        raise FixtureError(
            f"{path.name}: allowed_source_ids not present in evidence: {unknown_allowed}"
        )

    blob = _normalize(_evidence_blob(evidence))
    for fact in supported_facts:
        if _normalize(fact) not in blob:
            raise FixtureError(
                f"{path.name}: supported_facts item not found in evidence text: {fact!r}"
            )
    for fact in forbidden_facts:
        if blob and _normalize(fact) in blob:
            raise FixtureError(
                f"{path.name}: forbidden_facts item appears in evidence text: {fact!r}"
            )

    if expected == "refuse":
        if supported_facts:
            raise FixtureError(f"{path.name}: expected=refuse requires empty supported_facts")
        if allowed_source_ids:
            raise FixtureError(f"{path.name}: expected=refuse requires empty allowed_source_ids")
    else:
        if not supported_facts:
            raise FixtureError(f"{path.name}: expected=grounded requires non-empty supported_facts")
        if not allowed_source_ids:
            raise FixtureError(
                f"{path.name}: expected=grounded requires non-empty allowed_source_ids"
            )
        if not forbidden_facts:
            raise FixtureError(
                f"{path.name}: expected=grounded requires non-empty forbidden_facts"
            )

    return {
        "id": case_id,
        "question": question,
        "evidence": evidence,
        "expected": expected,
        "supported_facts": supported_facts,
        "forbidden_facts": forbidden_facts,
        "allowed_source_ids": allowed_source_ids,
        "path": path,
    }


def load_all_cases(corpus_dir: Path | None = None) -> dict[str, dict[str, Any]]:
    """Load every JSON fixture from the answer-quality corpus.

    Args:
        corpus_dir: Optional override directory; defaults to the checked-in corpus.

    Returns:
        Mapping of fixture id to validated case.

    Raises:
        FixtureError: If no files are found, ids collide, or any file is invalid.
    """
    directory = corpus_dir or CORPUS_DIR
    paths = sorted(directory.glob("*.json"))
    if not paths:
        raise FixtureError(f"no JSON fixtures found in {directory}")

    cases: dict[str, dict[str, Any]] = {}
    for path in paths:
        case = load_case(path)
        case_id = case["id"]
        if case_id in cases:
            raise FixtureError(f"duplicate fixture id {case_id!r}")
        cases[case_id] = case
    return cases


def claims_violated(answer_text: str, case: Mapping[str, Any]) -> list[str]:
    """Return forbidden facts that appear in answer text.

    Matching is case-insensitive and whitespace-normalized substring search.
    Paraphrase of supported facts is not checked here.

    Args:
        answer_text: Candidate answer prose.
        case: Loaded fixture mapping with ``forbidden_facts``.

    Returns:
        Forbidden claim strings found in ``answer_text``, in fixture order.
    """
    haystack = _normalize(answer_text)
    return [fact for fact in case["forbidden_facts"] if _normalize(fact) in haystack]
