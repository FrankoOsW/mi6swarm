# SSO Auth Scaffold — Plan Brief

> Full plan: `context/changes/sso-auth-scaffold/plan.md`

## What & Why

Integrate Okta OIDC authentication so OLX employees can log in with their corporate identity. This is the gating foundation (F-01) that unlocks all user-facing features — per PRD, "SSO must work reliably; auth failures block the entire product."

## Starting Point

Django app exists with standard auth middleware configured but not wired to any SSO provider. No OIDC packages installed, no user model extensions. FastAPI app also exists but will be deprecated — auth goes through Django only.

## Desired End State

Users visit the app, get redirected to Okta, authenticate with their OLX credentials, and return with a valid session. All routes except `/health` require authentication. Developers can bypass auth locally for fast iteration.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
|----------|--------|------------------|--------|
| SSO Provider | Okta | OLX enterprise standard | Plan |
| Framework for auth | Django only | Mature OIDC ecosystem (mozilla-django-oidc), admin for user management | Plan |
| Session storage | Database-backed | Simple, persistent, works with existing Django setup | Plan |
| Route protection | All except /health | Secure by default; matches PRD "all authenticated employees have equal access" | Plan |
| Logout behavior | Local only | Simple UX; user can quickly re-login without Okta credentials | Plan |
| Dev testing | Okta dev tenant + bypass | Real flow tested; DEBUG-only bypass speeds iteration | Plan |

## Scope

**In scope:**
- Okta OIDC integration via mozilla-django-oidc
- Database-backed sessions
- LoginRequiredMiddleware protecting all routes except /health
- Local logout endpoint
- Auth error handling with friendly messages
- DEBUG-only auth bypass for development
- Integration tests for auth flow

**Out of scope:**
- Single logout (SLO) to Okta
- Role-based access control (flat access per PRD)
- FastAPI authentication
- Custom user profile UI
- Remember me / persistent sessions

## Architecture / Approach

```
User → Request → LoginRequiredMiddleware → Protected Route
         ↓ (if not authenticated)
    /oidc/authenticate/ → Okta Login → /oidc/callback/ → Session Created → Original URL
```

Using mozilla-django-oidc which provides:
- OIDC authentication backend
- Login/logout/callback views
- Session management with Django's session framework

## Phases at a Glance

| Phase | What it delivers | Key risk |
|-------|------------------|----------|
| 1. Dependencies & Settings | OIDC package installed, settings configured | Okta client credentials must be available |
| 2. User Model & Migrations | Auth backend configured, DB tables created | Migration conflicts if other changes pending |
| 3. Auth Middleware & URLs | All routes protected, OIDC endpoints wired | Middleware ordering matters |
| 4. Error Handling & UX | Friendly error messages, logout endpoint | Edge cases in error flows |
| 5. Testing & Dev Bypass | Tests pass, bypass documented | Bypass must never reach production |

**Prerequisites:** Okta app registered with callback URL, client credentials available as env vars
**Estimated effort:** ~2-3 sessions across 5 phases

## Open Risks & Assumptions

- Assumes Okta is the correct SSO provider (confirmed in planning)
- Assumes Okta dev tenant is available for testing
- DEBUG-only bypass is a security-sensitive pattern — must be enforced never to reach production
- Database must support Django sessions (PostgreSQL assumed from infra)

## Success Criteria (Summary)

- Unauthenticated users are redirected to Okta login
- Authenticated users can access all routes
- /health remains accessible for K8s probes
- Developers can bypass auth locally with OIDC_BYPASS=True
