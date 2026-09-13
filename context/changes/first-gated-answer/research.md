---
date: 2026-09-07T22:16:07+02:00
researcher: michal.frankiewicz
git_commit: 2f1a50707a6f07a726363f1cd13058c25dde0a99
branch: fix/disable-ssl-redirect-for-health-probes
repository: mi6swarm
topic: "What does the codebase already provide for the first gated answer (authenticated Q&A)?"
tags: [research, codebase, django, oidc, sso, http-surfaces, agent-swarm, toqan, genai-platform]
status: complete
last_updated: 2026-09-07
last_updated_by: michal.frankiewicz
last_updated_note: "Added follow-up research for OLX LLM infrastructure, Toqan vs GenAI Platform, and Service Shaper integration"
---

# Research: First gated answer

**Date**: 2026-09-07T22:16:07+02:00
**Researcher**: michal.frankiewicz
**Git Commit**: 2f1a50707a6f07a726363f1cd13058c25dde0a99
**Branch**: fix/disable-ssl-redirect-for-health-probes
**Repository**: mi6swarm

## Research Question

`/10x-research first-gated-answer` — What does this repo already implement (auth gate, HTTP surfaces, agent/LLM pipeline, conventions) that should constrain planning the first authenticated question-and-answer feature?

## Summary

The product story (README / OpsLevel) describes an AI agent swarm that answers analyst questions. **None of that pipeline exists in code.** Runtime is a thin Django JSON service (`/` and `/health`) served by gunicorn. FastAPI under `app/` is a broken leftover and is not in the production image.

SSO is the intended gate (change `sso-auth-scaffold`, F-01). **Only Phase 1 is done**: `mozilla-django-oidc` is installed and OIDC settings exist. Auth backends, OIDC URL include, `LoginRequiredMiddleware`, logout/error UX, migrations, and auth tests are still open. Today **every Django route is public**.

A first gated answer is therefore: (1) **greenfield Q&A** on Django `core` views, following `JsonResponse` + root `tests/` conventions, and (2) **blocked on finishing SSO Phases 2–3** if “gated” means a real session. There is no PRD, roadmap, or contract-surfaces file on disk to cite product FRs — only SSO change docs and README copy.

## Detailed Findings

### Auth and route gating

- `mozilla_django_oidc` is in `INSTALLED_APPS` (`src/config/settings/base.py:20`) and `Pipfile` (`mozilla-django-oidc = "==4.0.1"`).
- Middleware includes Session + Authentication, **not** `LoginRequiredMiddleware` (`src/config/settings/base.py:24-33`).
- OIDC endpoints, scopes, and `LOGIN_URL = "/oidc/authenticate/"` are set (`src/config/settings/base.py:114-134`). **No** `AUTHENTICATION_BACKENDS`.
- Root URLconf has `admin/` + `core.urls` only — **no** `path("oidc/", include("mozilla_django_oidc.urls"))` (`src/config/urls.py:4-7`).
- `OIDC_BYPASS` exists only in local settings (`src/config/settings/local.py:11-13`) and is unused until middleware exists.
- Production already fail-fasts if Okta env vars are missing (`src/config/settings/production.py:33-41`). Secure cookies: `SESSION_COOKIE_SECURE` / `CSRF_COOKIE_SECURE`.
- User model: default Django User (no `AUTH_USER_MODEL`, no `src/core/models.py`).
- FastAPI `app/main.py` has public `/health` and `/` and **no auth**; Dockerfile copies `./src` only and runs gunicorn `config.wsgi:application`.

Implication: a new answer route added now would be as public as `/`. Prefer completing SSO middleware + backends (or an explicit temporary `@login_required` after those land) rather than a parallel FastAPI gate.

### HTTP surfaces and conventions

- Live routes: `GET /health` → `{"status": "healthy"}`; `GET /` → service card JSON (`src/core/urls.py:5-8`, `src/core/views.py:4-13`).
- No templates, forms, static source tree, OpenAPI, or DRF/Ninja. `TEMPLATES` is configured but unused.
- CSRF middleware is on; any future **POST** with session cookies needs a CSRF token.
- Tests live in **root** `tests/` (`tests/test_main.py`), pytest-django `Client`, `DJANGO_SETTINGS_MODULE = config.settings.base` in `pyproject.toml`. CI: `pipenv run pytest tests/* --cov=src/`. SSO plan’s `src/core/tests/` path does not exist — follow the root `tests/` layout unless Phase 5 deliberately changes it.
- Stale tooling: Makefile `uvicorn src.main:app`, `compose.yml` mounting `./app`, `LOGGING.md` FastAPI logger — do not extend these for the answer slice.
- Smallest extension point: new function view in `src/core/views.py` + `path(...)` in `src/core/urls.py` + `tests/test_*.py`. Do not add the path to any future middleware allowlist (only `/health`, `/oidc/`, static).

### Answer / agent / LLM pipeline

- README (`README.md:1-3`) and `opslevel.yml` describe supervisor routing to Traffic / autoplac.pl specialists and retrieval over GitLab ETL, Confluence, and vendor specs.
- Repo search for langchain, openai, anthropic, rag, embedding, supervisor, specialist, confluence, similarweb, autoplac hits **only** those catalog texts (excluding skill docs).
- **No** AI packages in `Pipfile`. No models, migrations, notebooks, or chat/query routes.
- Git history (Service Shaper → FastAPI-to-Django → SSO Phase 1) has no agent commits.

Implication: first gated answer is **fully greenfield** for generation, retrieval, and connectors. Reuse is the Django shell, deploy/CI, and (once finished) Okta session identity.

### Project conventions and missing foundation

- Dependencies: Pipenv + root `Pipfile`; dual PyPI + private `olx-pypi`. Lesson: **commit `Pipfile.lock`** with dependency changes (`context/foundation/lessons.md`). Lockfile is still absent.
- New env vars: `os.environ.get` in `base.py`; DEBUG-only flags in `local.py`; required-in-prod validation in `production.py`; document in `.env.example`.
- Missing on disk: `context/foundation/roadmap.md`, `prd.md`, `tech-stack.md`, `docs/reference/contract-surfaces.md`. Planning cannot cite FR numbers from foundation files.

## Code References

- `src/core/views.py:4-13` — only JSON views (`health`, `index`)
- `src/core/urls.py:5-8` — `/health` and `/`
- `src/config/urls.py:4-7` — admin + core; no OIDC include
- `src/config/settings/base.py:12-33` — apps and middleware (no login-required)
- `src/config/settings/base.py:114-134` — OIDC settings and `LOGIN_URL`
- `src/config/settings/local.py:11-13` — `OIDC_BYPASS` (dead until middleware)
- `src/config/settings/production.py:28-41` — secure cookies + required Okta vars
- `Pipfile:26-27` — `mozilla-django-oidc==4.0.1`; no LLM libs
- `tests/test_main.py:10-22` — unauthenticated 200 on `/` and `/health`
- `app/main.py:1-37` — leftover FastAPI; broken `from . import config`
- `Dockerfile` — copies `src/`, gunicorn WSGI on :8000
- `README.md:1-5` — product claim vs actual scaffold

## Architecture Insights

1. **Django is the only live app.** Treat FastAPI as dead code. Production is WSGI/gunicorn — keep first-answer views sync unless there is a strong reason to add ASGI.
2. **API-shaped service, not a UI.** First answer should be JSON (and CSRF-aware if POST) unless the plan explicitly adds templates.
3. **Secure-by-default once middleware exists.** New Q&A paths should not be health-style exemptions. `/health` must stay public for K8s probes (no trailing slash).
4. **Flat access.** SSO change forbids RBAC for MVP — any authenticated employee can use the answer endpoint equally.
5. **Identity is default User.** No profile/role model to hang domain routing on yet; specialist routing would be application logic, not Django permissions.
6. **Observability packages are present but unwired** (structlog, Sentry, New Relic, otel in Pipfile; Django `LOGGING` is console verbose). Do not assume they wrap a new LLM call.

## Historical Context (from prior changes)

- `context/changes/sso-auth-scaffold/change.md` — F-01 Okta OIDC, Django only, DB sessions, all routes except `/health`, local logout, DEBUG bypass. Status `impl_reviewed` after Phase 1.
- `context/changes/sso-auth-scaffold/plan.md` — Phases 2–5 still `[ ]` (backends, migrations, middleware, oidc URLs, logout, tests). Progress cites commit `2f1a507` for Phase 1.
- `context/changes/sso-auth-scaffold/plan-brief.md` — “SSO must work reliably; auth failures block the entire product.”
- `context/changes/sso-auth-scaffold/reviews/impl-review-phase-1.md` — production `ImproperlyConfigured` fix landed; Pipfile.lock still missing (accepted as recurring rule).
- `context/foundation/lessons.md` — always commit `Pipfile.lock` with Pipfile changes.

**Sequencing for this change:** `first-gated-answer` depends on SSO Phases 2–3 for a real gate. Building the answer JSON API in parallel is feasible; calling it “gated” is not until middleware + backends exist.

## Related Research

No other `research.md` artifacts under `context/changes/` or `context/archive/`. This is the first research document in the repo.

## Open Questions

1. **Sequencing:** Finish `sso-auth-scaffold` Phases 2–3 before implementing the answer route, or ship an unauthenticated stub and gate it in a follow-up?
2. **Product contract:** What is the MVP “answer”? Single POST `/ask` returning a string? Streaming? Persistence? Without PRD/roadmap on disk this is unfixed.
3. **LLM and retrieval:** Which model vendor and whether MVP includes RAG/connectors (Confluence/GitLab) vs a stubbed synthesizer — codebase cannot answer this (external research).
4. **Admin vs Okta:** Planned middleware does not exempt `/admin/` — confirm whether admin uses Okta or ModelBackend passwords.
5. **FastAPI `app/`:** Delete, ignore, or keep? Broken import; not in the image.
6. **Okta auth server path:** Hard-coded `/oauth2/default/` — confirm org authorization server id.
7. **POST + CSRF:** Browser form vs API client (token header vs session cookie) changes CSRF strategy.
8. **Foundation docs:** Restore or write `roadmap.md` / `prd.md` so later `/10x-plan` can cite FRs instead of README copy.

## Follow-up Research 2026-09-07T22:25:00+02:00

**Question:** How can mi6swarm use OLX LLM infrastructure? Is Toqan the right choice? How do we integrate OLX AI solutions with this Service Shaper (Django) app?

**Codebase check:** still no Toqan, GenAI Platform, OpenAI, or Bedrock references in application code. `.env.example` has Okta only.

### Direct answer

Use **GenAI Platform (GAIP)** as the LLM substrate for the Service Shaper backend. **Toqan is not the right LLM gateway for this service.** Toqan is the right **agent workspace / client** for analysts (and later as an MCP consumer of our tools). Do not call OpenAI/Anthropic vendor APIs directly from `mi6swarm`.

### OLX AI stack (three layers, different jobs)

| Layer | What it is | Fit for first gated answer |
| --- | --- | --- |
| **GenAI Platform (GAIP)** | Org LLM proxy: budgets, API keys, unified provider APIs | **Yes — call this from Django** |
| **Toqan** | Agentic workforce UI + poll-based Agent API (`sk_` keys per space) | **No as the model backend**; yes as a future client |
| **Envoy AI Gateway** | Central MCP front door (Okta/Auth0) for Toqan/Cursor | **Later** — expose tools, not the first `/ask` |

AICS CoE: Toqan is the recommended default for **internal human AI work** ([Toqan](https://naspersclassifieds.atlassian.net/wiki/spaces/AICOE/pages/60355248129/Toqan)). Product services that need a chat-completions call use GAIP, matching Motors AI Ad Summary ([CONS.D&E.DD-042](https://naspersclassifieds.atlassian.net/wiki/spaces/CARS/pages/60681355958/CONS.D+E.DD-042+AI+Ad+Summary)): “LLMs will be interacted with via GenAI Platform API — simple proxy + cost limit per API key.” A PDRE stub that called Toqan “OLX's internal LLM platform” also said **Toqan is replaceable** ([Toqan LLM Pipeline](https://naspersclassifieds.atlassian.net/wiki/spaces/PDRE/pages/60413673659/Toqan+LLM+Pipeline+pre-Alpha)) — that usage is a classifier pipeline, not the org gateway.

### Why Toqan is a weak fit as the service LLM

1. **API shape:** create conversation → poll `get_answer` (`in_progress` / `finished`). Not OpenAI `chat.completions`. Awkward behind gunicorn request/response and pytest.
2. **Identity:** `X-Api-Key` is bound to **one Agent/space**, not to a Service Shaper deployment. Prompt/tools live in Toqan’s UI, not in git.
3. **Latency / UX:** designed for agent workflows (n8n, files, tools), not a tight JSON `/ask`.
4. **Governance:** GAIP keys have sandbox vs deployment, monthly USD caps, Hydra usage telemetry. Toqan has tenant/space budgets aimed at people, not K8s workloads.
5. **Deprecated host:** `api.coco.prod.toqan.ai` / `api.coco.production.toqan.ai` migrate to `https://api.toqan.ai/api` by 2026-06-01 ([Toqan create conversation](https://toqan-api.readme.io/reference/post_create-conversation.md)).

Toqan **is** right if the MVP is “analysts chat in work.toqan.ai” and mi6swarm is only a **custom tool** those agents call. That inverts the product: README wants a service that answers questions, not a Toqan space.

### How to integrate GAIP with this Service Shaper app

Onboarding ([GAIP Getting started](https://naspersclassifieds.atlassian.net/wiki/spaces/GAIP/pages/58730578665/Getting+started)):

1. Need **Resource Manager** on a Console **Data project**.
2. Create a **GenAI application** linked to that project (optional Hydra stream for cost/usage).
   - Staging Console: `https://console-stg.data.olx.org`
   - Production: `https://console.data.olx.org/genai-platform`
3. Create API keys: **Sandbox** for local/PoC, **Deployment** (one per application) for prod. Optional monthly USD cap (80% Slack/email; 100% rejects). Keys expire with 401.
4. Store the secret like other prod secrets (not git). Local: env var; cluster: existing Service Shaper / ESO pattern.

Call pattern ([Provider native API - OpenAI](https://naspersclassifieds.atlassian.net/wiki/spaces/GAIP/pages/60515156070/Provider+native+API+-+OpenAI)):

```
https://platform.genai.olx.io/proxy/openai/v1
Authorization: Bearer <GENAI_PLATFORM_KEY>
POST .../chat/completions
```

Python: official `openai` SDK with `base_url` pointed at the GAIP proxy and `api_key=os.environ["GENAI_PLATFORM_KEY"]`. Demo notebooks: [genai-access-demo](https://git.naspersclassifieds.com/global-data-science/genai/platform/genai-access-demo/-/tree/main/notebooks/openai).

Bedrock/Claude path used by Claude Code (not required for MVP JSON ask): `https://platform.genai.olx.io/proxy/bedrock/v1` with `X-Api-Key: genai-sk-...` ([Using Claude Code with GenAI platform](https://naspersclassifieds.atlassian.net/wiki/spaces/DPM/pages/60415639956/Using+Claude+Code+with+GenAI+platform)).

**Django wiring (this repo):**

- Add `openai` (or `httpx`) via Pipfile + **commit Pipfile.lock** (`lessons.md`).
- Settings: `GENAI_PLATFORM_KEY`, `GENAI_PLATFORM_BASE_URL` defaulting to the OpenAI proxy; fail-fast in `production.py` like Okta.
- Keep the LLM client in a small module called from a `core` view — do not resurrect FastAPI `app/`.
- Gunicorn is sync; first slice should be a **blocking** completion with a timeout, not Toqan-style polling. Streaming needs ASGI later.
- GAIP identity is the **app key**, not the Okta user. End-user auth remains Django session (SSO). Do not expect per-analyst cost on GAIP without extra metadata ([n8n cost-tracking spike](https://naspersclassifieds.atlassian.net/wiki/spaces/GAIP/pages/60411052078): proxy only knows the API key).

### Where Toqan and Envoy still matter later

- **Analyst UX:** Toqan space with custom tools hitting gated mi6swarm HTTP (session or service auth TBD).
- **MCP:** Envoy AI Gateway already pilots Okta MCP for Cursor and Toqan (`mcp-authentication` v4, staging). Common-chart `envoy.aiGateway` is the Service Shaper attachment path ([evaluation](https://naspersclassifieds.atlassian.net/wiki/spaces/CORETECH/pages/60358688811/Envoy+AI+Gateway+evaluation+MCP+central+gateway)). That is **tool exposure**, not LLM proxying.
- **Data MCP:** Data Platform MCP is a Toqan/Cursor client of OLX data tools — complementary retrieval, not a replacement for GAIP.

### Recommendation for `/10x-plan first-gated-answer`

1. Finish or stub SSO so `/ask` is session-gated.
2. Onboard a GAIP application + sandbox key.
3. Django view: retrieve (stub or MCP later) → `chat.completions` via GAIP → `JsonResponse`.
4. Keep Toqan out of the request path for v1.
5. Defer Envoy MCP until there is a tool worth calling from Toqan/Cursor.

### Follow-up open questions

1. Which Data project should own the mi6swarm GenAI application (MI6 / market_monitor)?
2. Default model (`gpt-4o-mini` / `gpt-4.1-nano` vs Bedrock Claude) and monthly budget.
3. Network: can the Service Shaper prod cluster reach `platform.genai.olx.io` without extra mesh/VPN rules?
4. OpsLevel AI Governance fields once the app calls GAIP ([AI Governance property](https://naspersclassifieds.atlassian.net/wiki/spaces/DATA/pages/60724871274/AI+Governance+property+in+OpsLevel)).
