<!-- IMPL-REVIEW-REPORT -->
# Implementation Review: Gated Answer Quality

- **Plan**: context/changes/first-gated-answer/plan.md
- **Scope**: Phase 1–3 of 3
- **Date**: 2026-09-14
- **Verdict**: NEEDS ATTENTION
- **Findings**: 0 critical 2 warnings 1 observation

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| Plan Adherence | PASS |
| Scope Discipline | PASS |
| Safety & Quality | WARNING |
| Architecture | PASS |
| Pattern Consistency | PASS |
| Success Criteria | PASS |

## Findings

### F1 — EXEMPT_PATHS invariant is skip-gated

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: tests/test_answer_quality.py:250
- **Detail**: `test_answer_path_is_not_login_exempt` is skip-gated, so adding a Q&A path to `EXEMPT_PATHS` can CI-green until an answer surface exists.
- **Fix A ⭐ Recommended**: Add an always-on freeze of today’s `EXEMPT_PATHS` in `tests/test_auth.py`.
  - Strength: Catches “just add it next to /health” before the answer API exists.
  - Tradeoff: Extra test outside the skip-gated file.
  - Confidence: HIGH — middleware set is already known.
  - Blind spot: Won’t know the future answer path until product work lands.
- **Fix B**: Leave as planned; document in §6.4 that allowlist coverage waits on the product slice.
- **Decision**: FIXED via Fix A (`tests/test_auth.py::test_login_exempt_paths_are_frozen`)

### F2 — Refusal helper treats any `error` as a refuse

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: tests/test_answer_quality.py:68
- **Detail**: `_is_refusal()` treated truthy `error` as refusal; contract tests did not assert GAIP was called on model-reaching paths.
- **Fix**: Split structured refusal from transport `error`; require refusal shape on refuse cases; `mock_create.assert_called()` where the model should be reached.
- **Decision**: FIXED (`_has_transport_error`; grounded/mixed/provider-failure assert GAIP called)

### F3 — Small extras that support the plan

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Scope Discipline
- **Location**: tests/support/answer_quality.py:178
- **Detail**: `claim_present`, `GAIP_CHAT_COMPLETIONS_PATCH_TARGET`, HTTP helpers, `tests/support/__init__.py`, and `plan-brief.md` were not named as deliverables.
- **Fix**: Leave in place; they are the skip-gate and oracle helpers.
- **Decision**: FIXED (left in place)
