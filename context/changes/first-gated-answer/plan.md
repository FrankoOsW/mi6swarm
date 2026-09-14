# Gated Answer Quality (Test Rollout Phase 2) Implementation Plan

## Overview

Land the Risk #1 quality harness for the first gated answer: a hand-authored fixture oracle, then a skip-gated contract + integration suite that proves grounding/refusal and session/CSRF/provider-failure boundaries **when a real answer surface exists**. Do not implement the product `/ask` API, GAIP client, or an unauthenticated stub. Finish by filling `test-plan.md` §6.3 with the shipped cookbook.

## Current State Analysis

SSO Phases 2–5 are complete. `LoginRequiredMiddleware` (`src/core/middleware.py`) gates every path except `/health`, `/health/`, `/auth/error/`, `/logout/`, `/oidc/`, and static. `CsrfViewMiddleware` is on; no view is `csrf_exempt`. Root `tests/` already has `anonymous_client` / `authenticated_client` (`tests/conftest.py`) and auth/settings tests. Default Django `Client` does **not** enforce CSRF (logout POST is untokened).

`context/changes/first-gated-answer/research.md` (2026-09-07) is **stale on auth**: it still claims every route is public and SSO is only Phase 1. Treat current middleware as ground truth. Research remains authoritative for: Q&A is greenfield on Django `core` JSON views; LLM via GAIP `chat.completions` not Toqan; tests live in root `tests/`; new routes must not join the health allowlist; POST + session needs CSRF.

There is **no** answer route, LLM client, fixture corpus, or response schema in `src/` or `tests/`. Product FRs for sourced answers / “I don’t know” live in `context/foundation/prd.md` (Guardrails, US-01 AC, FR-005, Accuracy NFR). Flat SSO authorization (authenticated vs not; no RBAC) is PRD Access Control.

**Hypothesis investigation (from research + current code):** Risk #1 cannot be empirically proven until an answer application boundary exists. Session gating for a *future* JSON POST is already the default unless the path is added to `EXEMPT_PATHS`.

## Desired End State

- A checked-in fixture corpus encodes questions, fixed evidence, supported facts, and forbidden invented facts **independent of any model**.
- Fixture self-tests fail if the corpus is internally inconsistent or looks copied from implementation output.
- When (and only when) a real answer surface exists, pytest fails if: evidence-missing paths return a confident unsourced answer; mixed grounded/invented completions surface forbidden facts; anonymous clients get an answer; CSRF-less cookie POSTs succeed; expired sessions still call GAIP; provider errors become confident answers.
- Until that surface exists, those tests **skip** with an explicit reason — they must not pass as a false green.
- `test-plan.md` §6.3 documents how to add a JSON API quality test in this repo.
- Verify: `pipenv run pytest tests/ -v` stays green; CI `tests/* --cov=src/` still meets coverage; no new path in `EXEMPT_PATHS`.

### Key Discoveries:

- Auth gate is already live: `src/core/middleware.py:4-28` (`EXEMPT_PATHS` + `/oidc/` + static). Research.md auth sections are stale.
- CSRF is on (`src/config/settings/base.py:29`) but untested: `tests/test_auth.py:45` POSTs `/logout/` without `enforce_csrf_checks=True`.
- JSON convention: function views + `JsonResponse` in `src/core/views.py:8-17`; URLs in `src/core/urls.py:5-10`.
- Test layout: root `tests/` only — CI is `pipenv run pytest tests/* --cov=src/` (`.gitlab/.unit_tests.yml:10`). Do not put pytest under `src/core/tests/`.
- LLM: none in Pipfile; GAIP OpenAI-compatible `chat.completions` is the researched edge (`research.md` follow-up). Mock that edge, not Toqan polling.
- Coverage omit list includes `src/config/settings/production.py`; new `src/` modules will count toward `--cov-fail-under=80`. This plan adds tests, not production modules, so coverage should not regress.

## What We're NOT Doing

- Implementing the answer HTTP API, retrieval, specialist routing, or GAIP client.
- Inventing a locked production URL or JSON schema (no canonical `POST /ask` in product code).
- Adding an unauthenticated `/ask` stub, or adding any answer path to `EXEMPT_PATHS`.
- Live GAIP, live Okta, Playwright, or LLM-as-judge in CI (AI-native grader dated **2026-09-14**: do not use where deterministic source/refusal/forbidden-claim checks suffice).
- Persistence, conversation history, IDOR/ownership, follow-ups, supervisor routing, live data MCP.
- A dedicated fixture-authoring skill — cookbook §6.3 is the pattern until it proves reusable.
- FastAPI `app/` resurrection; Toqan as the service LLM.
- Authoring GitHub Actions / changing CI YAML (gates already collect `tests/*`).

## Implementation Approach

Cost × signal order:

1. **Always-on fixture oracle** (cheapest, independent of product). Hand-author goldens; validate the corpus itself.
2. **Skip-gated contract + HTTP/provider integration** in one suite. Activate by implementing a tiny test-side surface hook when the product lands a real boundary — not by shipping a stub to make tests green.
3. **Cookbook** last, from what actually shipped.

Skip gate: `tests/support/answer_surface.py` exposes `answer_surface_available()`. Default `False`. Product work later sets it true by pointing at a real application-layer callable **and** (for HTTP cases) a resolvable Django route. Tests must not discover the surface by scraping implementation output or by calling a live model.

## Critical Implementation Details

**Skip vs false green.** A missing answer API must `pytest.skip` with reason `answer-surface-missing`. An empty 200 JSON body, a stub that always returns `"ok"`, or asserting `status_code in (200, 302)` is a failed design.

**CSRF in tests.** Session POST assertions must use `Client(enforce_csrf_checks=True)` (or equivalent). Reusing the default client would miss the browser-session failure mode.

**External LLM boundary.** Patch/mock only the GAIP `chat.completions` HTTP/SDK edge. Do not mock the grounding/refusal function under test. Scripted completions are inputs; fixture `supported_facts` / `forbidden_facts` are the oracle.

**Auth research stale.** Do not re-open SSO. Reuse `anonymous_client` / `authenticated_client`. `force_login` proves LoginRequired + session for the answer path; it still does not prove Okta callback (existing lesson).

## Phase 1: Fixture oracle foundation

### Overview

Check in a hand-authored answer-quality corpus and tests that the corpus is usable as an independent oracle. Runnable immediately. No Django answer view required.

### Changes Required:

#### 1. Fixture corpus

**File**: `tests/fixtures/answer_quality/`

**Intent**: Encode Risk #1 scenarios as data, not as “whatever the model said.” Each case is authored from evidence first; expected outcomes are derived from that evidence.

**Contract**: One file per case (JSON or YAML). Required fields: `id`, `question`, `evidence` (list of `{source_id, text}`), `expected` (`grounded` | `refuse`), `supported_facts` (atomic claim strings that **may** appear), `forbidden_facts` (atomic claim strings that **must not** appear in a successful grounded answer), `allowed_source_ids`. Cases that **must** exist:

- `weekly-refresh-grounded` — evidence states Dataset A refreshes weekly; `supported_facts` include weekly refresh; `forbidden_facts` include a 90-day retention claim **not** in evidence.
- `empty-evidence-refuse` — `evidence: []`; `expected: refuse`.
- `irrelevant-evidence-refuse` — evidence is on-keyword but contains no answer-supporting fact; `expected: refuse`.
- `mixed-invention` — same as grounded plus an explicit forbidden invented fact for the scripted-completion test in Phase 2.

Source IDs must be unique, stable, and obviously fake (e.g. `fixture://dataset-a`). No live URLs.

- **Behavior asserted:** corpus fields are complete and internally consistent (`expected=refuse` ⇒ empty `supported_facts` or no required citations; `expected=grounded` ⇒ non-empty `allowed_source_ids` and `supported_facts` subset of evidence).
- **Regression caught:** goldens that cannot fail an invented fact (missing `forbidden_facts`) or that snapshot model prose as the only expected answer.
- **Research source:** test-plan Risk #1; PRD Guardrails + FR-005; research “fixture corpus” gap.
- **Edge/error/boundary:** irrelevant-but-similar evidence (keyword overlap, no fact).
- **Anti-pattern avoided:** oracle copied from model or implementation output; exact-answer-text goldens.

#### 2. Fixture loader and self-tests

**File**: `tests/support/answer_quality.py`, `tests/test_answer_quality_fixtures.py`

**Intent**: Load fixtures once, reject malformed files at collection/test time, and prove the weekly-refresh case would fail if an answer asserted the 90-day invention.

**Contract**: Loader raises on missing fields or `supported_facts` that cannot be found in `evidence` text. Self-tests: (1) all cases load; (2) grounded case’s forbidden 90-day claim is **absent** from evidence; (3) a helper `claims_violated(answer_text, case)` returns the 90-day claim when given a mixed invented paragraph. No network, no Django view.

### Success Criteria:

#### Automated Verification:

- Fixture files exist under `tests/fixtures/answer_quality/` with the four required cases
- Loader rejects a deliberately incomplete fixture in a unit test
- `pipenv run pytest tests/test_answer_quality_fixtures.py -v` passes
- `pipenv run pytest tests/ -v` still passes
- `pipenv run ruff check tests/` passes

#### Manual Verification:

- Open `weekly-refresh-grounded` and confirm `forbidden_facts` were written from the author’s intent, not from a model transcript
- Confirm no fixture file contains a full expected answer paragraph copied from a chat completion

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 2: Conditional answer-quality suite

### Overview

Add contract + integration tests that **skip** until a real answer surface exists, then enforce grounding/refusal, session, CSRF, and safe provider-failure behavior. Combined into one phase (cost × signal: contract assertions first in file order, then HTTP/provider). Do not unskip by adding a public stub.

### Changes Required:

#### 1. Surface hook (skip gate)

**File**: `tests/support/answer_surface.py`

**Intent**: Keep product URL/schema unfixed while making tests actionable later. Default: no surface.

**Contract**: `answer_surface_available() -> bool` is False until both are set: (a) `SUBMIT_QUESTION` — callable the contract tests invoke with `(question, evidence)` or equivalent, returning a structured result the tests can inspect for text, provenance/source ids, and refusal; (b) `ANSWER_HTTP` — object with `path` or reverse name **and** HTTP method used by integration tests. Document in comments that implementers of the product slice fill these against real `core` code, never against a health-style exemption. Tests import this module; they do not hard-code `/ask`.

#### 2. Grounding / refusal contract tests

**File**: `tests/test_answer_quality.py` (contract section)

**Intent**: Prove Risk #1 at the application boundary with fixture oracles and **scripted** provider output. Paraphrase of supported facts is allowed; invented facts are not.

**Contract**: Entire class/module `pytest.mark.skipif(not answer_surface_available(), reason="answer-surface-missing")`. Drive `SUBMIT_QUESTION` with fixture evidence. Mock GAIP `chat.completions` at the SDK/HTTP edge with scripted strings. Assertions:

| Sub-check | Behavior asserted | Regression caught | Research source | Edge/error/boundary | Anti-pattern avoided |
|-----------|-------------------|-------------------|-----------------|---------------------|----------------------|
| Grounded paraphrase | Result is not a refusal; provenance ⊆ `allowed_source_ids`; every `supported_facts` item is entailed (substring or normalized claim match — **not** full-answer equality) | Dropping citations while still returning prose | Risk #1; FR-005 | Valid paraphrase that does not copy evidence verbatim | Exact golden answer text; “non-empty string means pass” |
| Empty evidence | Explicit refusal / don’t-know; no `forbidden_facts`; no source ids outside fixture (none expected) | Confident answer with empty retrieval | PRD “I don’t know”; research validation layer | `evidence: []` | Oracle = model returned text |
| Irrelevant evidence | Same as empty: refuse, not a best-effort guess | Keyword-matching retrieval treated as proof | Risk #1 must-challenge | On-topic docs with no answering fact | Implementation-mirror of retriever scores |
| Mixed invention | Scripted completion contains weekly refresh **and** 90-day retention → not a successful grounded answer (refuse or strip/fail closed); `forbidden_facts` absent from any successful payload | Validator that only checks “has some citation” | Risk #1 mixed claims | Partial grounding + extra fact | Citations-only oracle |
| Provider timeout | Safe non-answer (deterministic error/refusal contract). Must not look like a sourced specialist answer | Exception swallowed into hallucinated JSON | research gunicorn blocking + timeout | Simulated timeout/exception from mocked client | Generic “not 200” with a 200 body that still answers |
| Provider 401 / malformed | Same safe non-answer | Auth-error or garbage completion rendered as confident copy | research GAIP keys/401 | 401; JSON that is not a chat completion | Copying error payload into `answer` |

Do not assert HTTP status codes in this section (schema unfixed). Assert observable refusal vs grounded + claims/provenance.

#### 3. Session, CSRF, and GAIP-not-called integration

**File**: `tests/test_answer_quality.py` (HTTP section) and optionally `tests/test_answer_http.py` if the file grows.

**Intent**: Authorization when the API exists: unauthenticated clients cannot get an answer; authenticated CSRF-valid session can reach the boundary; CSRF and session expiry are real.

**Contract**: Same skip gate. Use pytest-django `Client`. Anonymous uses `anonymous_client`. CSRF cases construct `Client(enforce_csrf_checks=True)` + `force_login` + cookie/token (`HTTP_X_CSRFTOKEN` after `ensure_csrf_cookie` / GET of a cookie-setting path). Mock the same GAIP edge; for unauthenticated and expired-session cases, assert the mock was **not** called.

| Sub-check | Behavior asserted | Regression caught | Research source | Edge/error/boundary | Anti-pattern avoided |
|-----------|-------------------|-------------------|-----------------|---------------------|----------------------|
| Anonymous | No answer JSON success; redirect to `LOGIN_URL` `/oidc/authenticate/` (302) | Unauthenticated 200 from a stub | middleware `EXEMPT_PATHS`; research “do not join health allowlist”; SSO complete | GET and POST if method allows | Treating 200 on an unauth stub as a gated product; adding the path to exemptions |
| Auth + CSRF | Authenticated, valid token, request reaches answer boundary (not 302 to login, not 403 CSRF) | LoginRequired applied but CSRF forgotten | CSRF middleware; research POST+session | Token present | `csrf_exempt` to make the test pass |
| Auth − CSRF | Same session, `enforce_csrf_checks=True`, no token → 403 | Default test Client hiding CSRF | logout test currently untokened | Missing header | “CSRF disabled in tests is equivalent to production” |
| Expired session | After logout POST (or session flush), answer request redirects to login; GAIP mock not called | Stale session still billed/answered | `tests/test_auth.py` logout pattern | Session cleared mid-client | force_login-only happy path |
| Exemption invariant | Answer HTTP path is **not** a member of `EXEMPT_PATHS` and does not start with `/oidc/` | “Just add it next to `/health`” | `src/core/middleware.py:4` | Trailing-slash twin | Health-style public probe for Q&A |

### Success Criteria:

#### Automated Verification:

- `pipenv run pytest tests/test_answer_quality.py -v` exits 0; when surface is absent, collected tests skip with `answer-surface-missing` (not pass)
- `pipenv run pytest tests/test_answer_quality.py -v` does not skip fixture self-tests in Phase 1 files
- A unit test of the skip helper proves `answer_surface_available()` is False in this repo state
- `pipenv run pytest tests/ -v` passes
- `pipenv run ruff check tests/` passes
- No production `src/` answer view or GAIP client added by this phase
- `EXEMPT_PATHS` in `src/core/middleware.py` unchanged

#### Manual Verification:

- Confirm skipped tests are not reported as passed protection for Risk #1
- Confirm no new URL was registered solely to unskip the suite
- Spot-check mixed-invention assertions: a successful grounded payload containing “90 days” would fail

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 3: Cookbook completion

### Overview

Replace `test-plan.md` §6.3 TBD with the shipped pattern so later `/10x-tdd` can add a JSON API quality test without inventing oracles. Record Phase 2 notes in §6.4. Do not rewrite §1–§5 strategy except the Phase 2 **Status** cell if the orchestrator expects `planned`/`implementing`/`complete` from artifacts (Status `complete` for rollout Phase 2 stays **false** until the skip gate lifts and the suite runs unskipped in a later product slice).

### Changes Required:

#### 1. §6.3 JSON API cookbook

**File**: `context/foundation/test-plan.md`

**Intent**: Make “how do I add a test for X” answerable for gated JSON Q&A.

**Contract**: Replace “TBD — see §3 Phase 2” with:

- **Location:** `tests/test_answer_quality.py`, `tests/test_answer_quality_fixtures.py`, `tests/fixtures/answer_quality/`, `tests/support/answer_surface.py`
- **Naming:** `test_<behavior>_when_<condition>`; fixture ids kebab-case
- **Reference:** mixed-invention + anonymous redirect + CSRF 403 examples
- **Run:** `pipenv run pytest tests/test_answer_quality_fixtures.py tests/test_answer_quality.py -v`
- **Pattern:** hand-author `supported_facts` / `forbidden_facts`; skip if `answer_surface_available()` is false; mock GAIP `chat.completions` at the edge; `Client(enforce_csrf_checks=True)` for POST; never add the answer path to `EXEMPT_PATHS`
- **When NOT to use (AI-native):** LLM-as-judge / live model — **checked: 2026-09-14**. Use only if a deterministic claim/provenance check cannot express the failure; not for this gate.

#### 2. §6.4 notes

**File**: `context/foundation/test-plan.md` (§6.4)

**Intent**: Record that fixtures shipped before the API; Risk #1 empirical coverage waits on a real surface.

**Contract**: One short bullet: Phase 2 harness is skip-gated; do not mark test-plan §3 Phase 2 `complete` until tests run unskipped against production-path code (still not a stub). Research.md auth paragraphs remain historically stale.

### Success Criteria:

#### Automated Verification:

- `rg "TBD — see §3 Phase 2" context/foundation/test-plan.md` finds no matches
- §6.3 contains Location, Naming, Reference, Run, Pattern
- `pipenv run pytest tests/ -v` still passes

#### Manual Verification:

- A teammate could add a fifth fixture case from §6.3 alone
- §1–§5 risk map text is unchanged except any Status cell the implementer is explicitly allowed to touch

---

## Testing Strategy

### Unit Tests:

- Fixture schema/load errors
- `claims_violated` on mixed 90-day invention vs clean paraphrase
- `answer_surface_available()` false by default

### Integration Tests:

- Skip-gated: grounding/refusal/provider contract via `SUBMIT_QUESTION`
- Skip-gated: anonymous 302, CSRF 403 vs token success, expired session, exemption invariant

### Manual Testing Steps:

1. Read `weekly-refresh-grounded` and confirm forbidden retention claim is absent from evidence
2. Run pytest `-rs` and read skip reasons
3. Confirm middleware allowlist diff is empty
4. After a future product slice fills `answer_surface.py`, re-run without skips and try a mixed completion

## Performance Considerations

Fixtures are small and in-process. No live LLM. Skip-gated tests add negligible CI time. Do not add network timeouts to CI.

## Migration Notes

No data migration. `research.md` is not rewritten in this change (historical); implementers must prefer current `src/core/middleware.py` over research auth claims.

When the product slice lands, fill `tests/support/answer_surface.py` in **that** change (or a follow-up test phase), then unskip. Still no `/health`-style exemption.

## References

- Related research: `context/changes/first-gated-answer/research.md`
- Quality contract: `context/foundation/test-plan.md` (§2 Risk #1, §3 Phase 2, §6.3 TBD)
- PRD: Guardrails, US-01 AC, FR-005, Accuracy NFR, Access Control
- Auth tests to extend, not replace: `tests/test_auth.py`, `tests/conftest.py`
- Middleware allowlist: `src/core/middleware.py:4`
- Lesson: do not treat `force_login` as Okta callback proof (`context/foundation/lessons.md`)

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Fixture oracle foundation

#### Automated

- [x] 1.1 Fixture files exist under `tests/fixtures/answer_quality/` with the four required cases — 425d562
- [x] 1.2 Loader rejects a deliberately incomplete fixture in a unit test — 425d562
- [x] 1.3 `pipenv run pytest tests/test_answer_quality_fixtures.py -v` passes — 425d562
- [x] 1.4 `pipenv run pytest tests/ -v` still passes — 425d562
- [x] 1.5 `pipenv run ruff check tests/` passes — 425d562

#### Manual

- [x] 1.6 Open `weekly-refresh-grounded` and confirm `forbidden_facts` were written from the author’s intent, not from a model transcript — 425d562
- [x] 1.7 Confirm no fixture file contains a full expected answer paragraph copied from a chat completion — 425d562

### Phase 2: Conditional answer-quality suite

#### Automated

- [x] 2.1 `pipenv run pytest tests/test_answer_quality.py -v` exits 0; when surface is absent, collected tests skip with `answer-surface-missing` (not pass) — dd64c5a
- [x] 2.2 `pipenv run pytest tests/test_answer_quality.py -v` does not skip fixture self-tests in Phase 1 files — dd64c5a
- [x] 2.3 A unit test of the skip helper proves `answer_surface_available()` is False in this repo state — dd64c5a
- [x] 2.4 `pipenv run pytest tests/ -v` passes — dd64c5a
- [x] 2.5 `pipenv run ruff check tests/` passes — dd64c5a
- [x] 2.6 No production `src/` answer view or GAIP client added by this phase — dd64c5a
- [x] 2.7 `EXEMPT_PATHS` in `src/core/middleware.py` unchanged — dd64c5a

#### Manual

- [x] 2.8 Confirm skipped tests are not reported as passed protection for Risk #1 — dd64c5a
- [x] 2.9 Confirm no new URL was registered solely to unskip the suite — dd64c5a
- [x] 2.10 Spot-check mixed-invention assertions: a successful grounded payload containing “90 days” would fail — dd64c5a

### Phase 3: Cookbook completion

#### Automated

- [x] 3.1 `rg "TBD — see §3 Phase 2" context/foundation/test-plan.md` finds no matches — 09fc013
- [x] 3.2 §6.3 contains Location, Naming, Reference, Run, Pattern — 09fc013
- [x] 3.3 `pipenv run pytest tests/ -v` still passes — 09fc013

#### Manual

- [x] 3.4 A teammate could add a fifth fixture case from §6.3 alone — 09fc013
- [x] 3.5 §1–§5 risk map text is unchanged except any Status cell the implementer is explicitly allowed to touch — 09fc013
