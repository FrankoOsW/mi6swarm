<!-- IMPL-REVIEW-REPORT -->
# Implementation Review: SSO Auth Scaffold

- **Plan**: context/changes/sso-auth-scaffold/plan.md
- **Scope**: Phases 1–5 of 5
- **Date**: 2026-09-14
- **Verdict**: NEEDS ATTENTION
- **Findings**: 0 critical · 2 warnings · 2 observations

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| Plan Adherence | WARNING |
| Scope Discipline | PASS |
| Safety & Quality | WARNING |
| Architecture | PASS |
| Pattern Consistency | PASS |
| Success Criteria | WARNING |

## Findings

### F1 — Pipfile.lock never committed

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Plan Adherence / Success Criteria
- **Location**: Pipfile; no Pipfile.lock on disk
- **Detail**: Phase 1 marked lock complete. Local `pipenv lock` fails on private `python-otel` (olx-pypi).
- **Fix A ⭐ Recommended**: Generate Pipfile.lock in CI and commit it.
- **Decision**: ACCEPTED — generate lock in CI later (python-otel not resolvable locally)

### F2 — Logout is a GET that is auth-exempt

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: src/core/views.py
- **Detail**: GET logout diverges from Django 5.2 POST-only LogoutView.
- **Fix**: `@require_POST` on logout_view; tests assert GET 405 and POST clears session.
- **Decision**: FIXED

### F3 — OIDC HTTP timeout is unbounded

- **Severity**: observation
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: src/config/settings/base.py
- **Detail**: mozilla-django-oidc default timeout is None.
- **Fix**: `OIDC_TIMEOUT = 10`
- **Decision**: FIXED

### F4 — Tests never exercise the OIDC callback

- **Severity**: observation
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Success Criteria
- **Location**: tests/test_auth.py
- **Detail**: force_login does not prove code exchange.
- **Fix**: Callback tests: missing code / error param → `/auth/error/`; code+state with mocked `authenticate` creates a session.
- **Decision**: FIXED + ACCEPTED-AS-RULE: Do not treat force_login tests as proof the OIDC callback works
