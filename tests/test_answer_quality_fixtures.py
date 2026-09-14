import json
from pathlib import Path

import pytest

from tests.support.answer_quality import (
    FixtureError,
    claims_violated,
    load_all_cases,
    load_case,
)

REQUIRED_CASE_IDS = frozenset(
    {
        "weekly-refresh-grounded",
        "empty-evidence-refuse",
        "irrelevant-evidence-refuse",
        "mixed-invention",
    }
)

INVENTED_RETENTION = "Dataset A retains data for 90 days"
MIXED_INVENTED_PARAGRAPH = (
    "Dataset A is refreshed every week. Dataset A retains data for 90 days."
)


def test_all_required_cases_load():
    cases = load_all_cases()
    assert REQUIRED_CASE_IDS <= set(cases)


def test_weekly_refresh_forbidden_90_day_claim_is_absent_from_evidence():
    case = load_all_cases()["weekly-refresh-grounded"]
    evidence_text = " ".join(item["text"] for item in case["evidence"])
    assert INVENTED_RETENTION not in evidence_text
    assert INVENTED_RETENTION in case["forbidden_facts"]


def test_claims_violated_returns_90_day_claim_when_answer_invents_retention():
    case = load_all_cases()["weekly-refresh-grounded"]
    assert claims_violated(MIXED_INVENTED_PARAGRAPH, case) == [INVENTED_RETENTION]
    paraphrase = "Dataset A refreshes on a weekly cadence according to the catalog note."
    assert claims_violated(paraphrase, case) == []


def test_loader_rejects_incomplete_fixture(tmp_path: Path):
    path = tmp_path / "broken.json"
    path.write_text(json.dumps({"id": "broken", "question": "What?"}), encoding="utf-8")
    with pytest.raises(FixtureError, match="missing required fields"):
        load_case(path)


def test_loader_rejects_supported_fact_missing_from_evidence(tmp_path: Path):
    path = tmp_path / "unsupported.json"
    path.write_text(
        json.dumps(
            {
                "id": "unsupported",
                "question": "How often does Dataset A refresh?",
                "evidence": [
                    {
                        "source_id": "fixture://dataset-a/catalog-note",
                        "text": "Dataset A is refreshed every week.",
                    }
                ],
                "expected": "grounded",
                "supported_facts": ["Dataset A is replicated to a public bucket"],
                "forbidden_facts": [INVENTED_RETENTION],
                "allowed_source_ids": ["fixture://dataset-a/catalog-note"],
            }
        ),
        encoding="utf-8",
    )
    with pytest.raises(FixtureError, match="supported_facts item not found"):
        load_case(path)
