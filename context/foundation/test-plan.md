# Test Plan

> Phased test rollout for this project. Strategy is frozen at the top
> (§1–§5); cookbook patterns at the bottom (§6) fill in as phases ship.
> Read before writing any new test.
>
> Refresh: re-run `/10x-test-plan --refresh` when stale (see §8).
>
> Last updated: 2026-09-14

## 1. Strategy

Tests follow three non-negotiable principles for this project:

1. **Cost × signal.** The cheapest test that gives a real signal for the
   risk wins. Do not promote to e2e because e2e "feels safer." Do not put a
   vision model on top of a deterministic visual diff that already catches
   the regression.
2. **User concerns are first-class evidence.** Risks anchored in "the team
   is worried about X, and the failure would surface somewhere in `<area>`"
   carry the same weight as PRD lines or hot-spot data.
3. **Risks are scenarios, not code locations.** This plan documents *what
   could fail* and *why we believe it's likely* — drawn from documents,
   interview, and codebase *signal* (churn, structure, test base). It does
   NOT claim to know which line owns the failure. That knowledge is
   produced by `/10x-research` during each rollout phase. If the plan and
   research disagree about where the failure lives, research is the
   ground truth.

Hot-spot scope used for likelihood weighting: `src/`, `tests/` (5 commits
in the last 30 days — thin history; likelihood leans on change docs and
interview).

**Lean scope decision (2026-09-11):** Rollout starts with two phases only.
Broader Module 3 items (extra risks, hot-spot-only phase, AI-native hooks,
CI gate wiring) are deferred — see §7 and §8.

## 2. Risk Map

The top failure scenarios this project must protect against, ordered by
risk = impact × likelihood. Risks are failure scenarios in user / business
terms, not test names. The Source column cites the *evidence that surfaced
this risk* — never a specific file as "where the failure lives".

| # | Risk (failure scenario) | Impact | Likelihood | Source (evidence — not anchor) |
|---|-------------------------|--------|------------|--------------------------------|
| 1 | Analyst receives a **confident wrong answer** (hallucination or unstated assumption) and trusts it | High | Medium (rises when Q&A ships) | interview Q1; PRD Guardrails + FR-005; `first-gated-answer` research (Q&A greenfield) |
| 2 | **Authenticated product unusable** — broken OIDC/session or redirects so analysts cannot use the swarm | High | High | `sso-auth-scaffold` change/plan (F-01); hot-spot dir `src/config/settings` (7 touches/30d) |
| 3 | **Production-only settings** wrong — Okta env validation, cookies, or probe-related behavior works locally, fails in cluster | High | Medium | interview Q3; `sso-auth-scaffold` plan-brief; hot-spot dir `src/config/settings` |
| 4 | **Dev auth bypass or DEBUG-only paths effective in production**, weakening the corporate gate | High | Low–Medium | `sso-auth-scaffold` plan (OIDC_BYPASS decision); abuse lens |
| 5 | **Liveness misleading** — health checks pass while login or core user routes fail | Medium | Medium | interview Q4; sparse test base (redirect + health only) |

### Risk Response Guidance

| Risk | What would prove protection | Must challenge | Context `/10x-research` must ground | Likely cheapest layer | Anti-pattern to avoid |
|------|-----------------------------|----------------|--------------------------------------|-----------------------|-----------------------|
| #1 | Response refuses or shows provenance when evidence is missing; fixed fixture Q&A fails if answer invents facts | "Green test because the model returned text" | Answer entry point, validation layer, fixture corpus, external LLM boundary | Contract/integration with golden inputs (when Q&A exists) | Oracle copied from model or implementation output |
| #2 | Unauthenticated client → login redirect; authenticated session → protected route succeeds; `/health` stays public | "302 on `/` means full OIDC callback works" | Middleware order, OIDC URL include, session backend, login URL | pytest-django `Client` integration with controlled OIDC mocks | Mocking so heavily that callback and session creation are never exercised |
| #3 | Under production settings module, missing Okta env fails fast; secure cookie flags set as intended | "If it runs locally, prod settings are equivalent" | Which settings module loads per `DJANGO_SETTINGS_MODULE`, env var contract | Settings-focused tests (import/isolate production module) | Testing only base settings |
| #4 | Bypass flag has no effect when `DEBUG` is false | "Unset env implies safe default" | Where bypass is read, interaction with `DEBUG` | Matrix test across settings modules | Single-environment test only |
| #5 | Deliberate break of auth or `/` path still returns 200 on `/health` | "`/health` alone is enough release signal" | Route allowlist vs protected paths | Two-route test in same module | CI that only asserts health JSON |

## 3. Phased Rollout

Each row is a discrete rollout phase. Status vocabulary is fixed for the
orchestrator parser.

| # | Phase name | Goal (one line) | Risks covered | Test types | Status | Change folder |
|---|------------|-----------------|---------------|------------|--------|---------------|
| 1 | Auth & settings floor | Finish SSO test debt + prod settings guards; establish pytest patterns | #2, #3, #4, #5 | pytest-django integration, settings tests | complete | sso-auth-scaffold |
| 2 | Gated answer quality | Grounding, refusal, and session boundaries for first Q&A slice | #1 (+ authorization when API exists) | contract + integration with fixtures | planned | first-gated-answer |

## 4. Stack

| Layer | Tool | Version | Notes |
|-------|------|---------|-------|
| unit + integration | pytest + pytest-django | (Pipfile) | `DJANGO_SETTINGS_MODULE=config.settings.base`; tests in root `tests/` |
| API mocking | none yet — see Phase 1 | — | Prefer edge mocks for OIDC HTTP, not internal modules |
| e2e | none yet | — | Real Okta not default; defer full browser e2e |
| accessibility | none | — | No marketing UI in scope |
| AI-native | none yet — Module 3 later lessons | n/a | Do not layer vision/hooks before classic floor exists |

**Stack grounding tools (current session):**
- Docs: none (Context7 not exposed) — stack from `pyproject.toml` and Pipfile; checked: 2026-09-11
- Search: Cursor WebSearch available — not used for this write; checked: 2026-09-11
- Runtime/browser: none — not used; checked: 2026-09-11
- Provider/platform: GitLab MCP available — future MR/CI gate reads; not used; checked: 2026-09-11

## 5. Quality Gates

| Gate | Where | Required? | Catches |
|------|-------|-----------|---------|
| ruff (lint) | local + CI | required | syntactic issues |
| pytest `tests/` | local + CI | required after Phase 1 | auth/settings regressions |
| coverage on `src/` | CI | planned (existing `--cov=src/`) | untested auth paths |
| post-edit test hook | agent loop | planned — Module 3 later | edit-time regressions |
| e2e (Playwright / real Okta) | CI | not planned in lean scope | — |
| Atlantis/terraform validation | Atlantis | out of app test suite | infra apply/plan (see §7) |

## 6. Cookbook Patterns

### 6.1 Adding a unit or settings test

- **Location:** `tests/test_settings.py` (and sibling `tests/test_*.py` at repo root).
- **Naming:** `test_<behavior>_when_<condition>` (pytest functions, not Django `TestCase` classes unless DB is required).
- **Reference:** `tests/test_settings.py` — production fail-fast for missing Okta env; file-level assertion that `production.py` does not mention `OIDC_BYPASS`.
- **Run:** `pipenv run pytest tests/test_settings.py -v`
- **Pattern:** isolate production settings with a subprocess + `DJANGO_SETTINGS_MODULE=config.settings.production` so the already-configured test process is not mutated. Do not import `config.settings.production` into the pytest process.

### 6.2 Adding a Django integration test (auth)

- **Location:** `tests/test_auth.py` (CI collects `tests/*` only — do not put pytest files under `src/core/tests/`).
- **Naming:** `test_<behavior>`; fixtures `anonymous_client` and `authenticated_client` in `tests/conftest.py`.
- **Reference:** `tests/test_auth.py` — unauthenticated `/` → `/oidc/authenticate/`; `/health` public; `force_login` session on `/`; `OIDC_BYPASS` only with `DEBUG=True`; `/logout/` clears session.
- **Run:** `pipenv run pytest tests/test_auth.py -v`
- **Pattern:** pytest-django `Client` + `force_login`. Use `@override_settings` for the DEBUG × bypass matrix. Do not mock mozilla-django-oidc internals; do not treat a 302 on `/` as proof that the Okta callback works.

### 6.3 Adding a test for a new JSON API endpoint

- **Location:** `tests/test_answer_quality.py`, `tests/test_answer_quality_fixtures.py`, `tests/fixtures/answer_quality/`, `tests/support/answer_surface.py`.
- **Naming:** `test_<behavior>_when_<condition>`; fixture ids kebab-case.
- **Reference:** `tests/test_answer_quality.py` — mixed-invention (`test_rejects_grounded_success_when_completion_mixes_invented_retention`); anonymous redirect (`test_redirects_to_login_when_anonymous`); CSRF 403 (`test_returns_403_when_authenticated_without_csrf`).
- **Run:** `pipenv run pytest tests/test_answer_quality_fixtures.py tests/test_answer_quality.py -v`
- **Pattern:** Hand-author `supported_facts` / `forbidden_facts` from evidence (not from model prose). Skip contract/HTTP cases when `answer_surface_available()` is false (`reason="answer-surface-missing"`). Mock GAIP `chat.completions` at `GAIP_CHAT_COMPLETIONS_PATCH_TARGET`. Use `Client(enforce_csrf_checks=True)` for session POST. Never add the answer path to `EXEMPT_PATHS`.
- **When NOT to use (AI-native):** LLM-as-judge / live model — **checked: 2026-09-14**. Use only if a deterministic claim/provenance check cannot express the failure; not for this gate.

### 6.4 Per-rollout-phase notes

- **Lean rollout (2026-09-11):** Phase 1 delivery continues in existing
  `sso-auth-scaffold` (plan Phase 5 testing + remaining auth sub-phases).
  Phase 2 reuses `first-gated-answer` research; plan when SSO floor is green.
- **Phase 2 harness (2026-09-14):** Fixture oracle + skip-gated contract/HTTP
  suite shipped. Do not mark §3 Phase 2 `complete` until those tests run
  unskipped against production-path code (still not a stub). `research.md`
  auth paragraphs remain historically stale (SSO middleware is live).

## 7. What We Deliberately Don't Test

Exclusions from Phase 2 interview and the lean-scope decision. Re-evaluate
via `/10x-test-plan --refresh` when triggers in §8 fire.

- **Marketing / static UI snapshots** — noisy, low signal for an internal
  JSON/API-first service. (Source: interview Q5.)
- **Atlantis / Terraform apply paths in pytest** — infra init pain is real
  but belongs in IaC/Atlantis workflows, not the Django app suite.
  (Source: interview Q2.)
- **Default e2e against live Okta or production** — slow and flaky; prefer
  mocked token/callback integration unless a named phase requires smoke.
- **Generated boilerplate and template README drift** — fix docs separately;
  do not snapshot FastAPI template paths deprecated for this product.

### Deferred for a future refresh (not forgotten)

Recorded so a later `/10x-test-plan --refresh` can promote items without
re-litigating the lean start:

| Deferred item | Why deferred now | Promote when |
|---------------|------------------|--------------|
| Separate **hot-spot hardening** rollout phase | Merged into Phase 1 while `src/core` and settings churn | Churn continues after Phase 1 `complete` and tests still miss middleware/error paths |
| **IDOR / answer ownership** abuse scenario | No answer API or persisted Q&A resources yet | `first-gated-answer` (or successor) exposes user-scoped answer storage |
| **AI-native layer** (post-edit hooks, browser MCP, vision) | Module 3 Lesson 1 is strategy only | Later Module 3 lessons wire hooks/MCP; classic floor must exist first |
| **Quality-gates wiring** as its own rollout phase | CI/hook YAML is a later lesson | `test-plan.md` §5 rows still `planned` and team ready to enforce |
| **Foundation PRD/roadmap on disk** | Copied into `context/foundation/` on 2026-09-11 from the 10x sandbox | `--refresh` if PRD/roadmap status diverges from live change folders |
| Expanded **6-risk** map (full interview synthesis) | User chose lean 5-risk / 2-phase rollout | Q&A in production or incident proves hallucination/IDOR needs earlier priority |

## 8. Freshness Ledger

- Strategy (§1–§5) last reviewed: 2026-09-11
- Stack versions last verified: 2026-09-11
- AI-native tool references last verified: 2026-09-11

Refresh (`/10x-test-plan --refresh`) when:

- a new top-3 risk surfaces from the roadmap or archive,
- a recommended tool's `checked:` date is older than three months,
- the project's tech stack changes (new framework, new test runner),
- §7 negative-space or the **Deferred** table no longer matches what the
  team believes,
- Phase 2 ships and Risks #1 / IDOR need explicit rows in §2.
