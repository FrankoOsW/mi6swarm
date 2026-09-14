# SSO Auth Scaffold Implementation Plan

## Overview

Integrate Okta OIDC authentication into the Django app using mozilla-django-oidc. Users will log in with their OLX corporate identity; sessions are stored in the database. All routes except `/health` require authentication. This is the gating foundation (F-01) that unlocks all user-facing slices.

## Current State Analysis

The codebase has two frameworks, but we're using Django only for auth:

- **Django app** (`src/`): Standard auth middleware configured but not wired to SSO
- **FastAPI app** (`app/`): Exists but will be deprecated or kept internal-only
- **Session config**: Secure cookies enabled in production (`src/config/settings/production.py:28-29`)
- **No OIDC packages**: Pipfile has no mozilla-django-oidc, social-auth, or similar
- **No User model extensions**: Using Django's default User model

### Key Discoveries:

- `src/config/settings/base.py:12-21` — INSTALLED_APPS has standard Django auth
- `src/config/settings/base.py:23-32` — Middleware stack has SessionMiddleware and AuthenticationMiddleware
- `src/core/views.py:4-13` — Simple JsonResponse views, no auth decorators
- `src/config/urls.py:4-7` — Routes include /admin/ and core app at /

## Desired End State

After this plan completes:

1. **Users can log in via Okta**: Clicking "Login" redirects to Okta, returns with a valid session
2. **All routes are protected**: Any request without a valid session redirects to login (except /health)
3. **Sessions persist in database**: Django session table stores authenticated sessions
4. **Auth errors show friendly messages**: Expired tokens or Okta errors redirect to login with explanation
5. **Developers can bypass auth locally**: DEBUG=True + OIDC_BYPASS=True skips Okta for fast iteration

### Verification:

```bash
# With valid Okta session:
curl -b cookies.txt http://localhost:8000/ → 200 OK

# Without session:
curl http://localhost:8000/ → 302 redirect to /oidc/authenticate/

# Health endpoint always accessible:
curl http://localhost:8000/health → 200 OK
```

## What We're NOT Doing

- **Single logout (SLO)**: Local logout only; user stays logged into Okta
- **Role-based access control**: Flat access model per PRD — all authenticated users are equal
- **FastAPI authentication**: Django handles all auth; FastAPI app is deprecated
- **Custom user profile page**: No UI for viewing/editing profile in MVP
- **Remember me / persistent sessions**: Standard session expiry only
- **Multi-factor authentication handling**: Okta handles MFA; we just receive the token

## Implementation Approach

Use mozilla-django-oidc, the most mature Django OIDC library. It provides:
- OIDC authentication backend
- Login/logout/callback views
- Session management
- Token refresh (though we're using local logout)

The flow:
1. User hits protected route → middleware redirects to `/oidc/authenticate/`
2. Django redirects to Okta login
3. User authenticates with Okta
4. Okta redirects back to `/oidc/callback/` with auth code
5. Django exchanges code for tokens, creates session, redirects to original URL

---

## Phase 1: Dependencies & Settings

### Overview

Install mozilla-django-oidc and configure OIDC settings for Okta integration.

### Changes Required:

#### 1. Add OIDC dependency

**File**: `Pipfile`

**Intent**: Add mozilla-django-oidc package for Okta OIDC authentication.

**Contract**: Add to `[packages]` section: `mozilla-django-oidc = "*"`

#### 2. Configure OIDC settings

**File**: `src/config/settings/base.py`

**Intent**: Add OIDC configuration for Okta, including discovery URL, client credentials (from env), and session settings.

**Contract**: Add to INSTALLED_APPS: `'mozilla_django_oidc'`. Add OIDC settings block with:
- `OIDC_RP_CLIENT_ID` / `OIDC_RP_CLIENT_SECRET` from environment
- `OIDC_OP_AUTHORIZATION_ENDPOINT`, `OIDC_OP_TOKEN_ENDPOINT`, `OIDC_OP_USER_ENDPOINT`, `OIDC_OP_JWKS_ENDPOINT` from Okta discovery
- `OIDC_RP_SIGN_ALGO = "RS256"`
- `LOGIN_REDIRECT_URL = "/"`
- `LOGOUT_REDIRECT_URL = "/"`

#### 3. Add auth bypass setting for development

**File**: `src/config/settings/local.py`

**Intent**: Allow developers to bypass OIDC in local development for faster iteration.

**Contract**: Add `OIDC_BYPASS = env.bool("OIDC_BYPASS", default=False)` — only effective when DEBUG=True.

#### 4. Update environment template

**File**: `.env.example` (create if not exists)

**Intent**: Document required environment variables for OIDC configuration.

**Contract**: Add variables: `OIDC_RP_CLIENT_ID`, `OIDC_RP_CLIENT_SECRET`, `OKTA_DOMAIN`, `OIDC_BYPASS`.

### Success Criteria:

#### Automated Verification:

- Pipfile lock regenerates cleanly: `pipenv lock`
- Django settings load without error: `python src/manage.py check`
- OIDC settings are present: `python -c "from config.settings.base import *; print(OIDC_RP_SIGN_ALGO)"`

#### Manual Verification:

- Environment variables documented in .env.example
- Settings match Okta app configuration

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 2: User Model & Migrations

### Overview

Configure Django's User model to work with OIDC claims. The default User model is sufficient for MVP; we just need to ensure migrations are in place.

### Changes Required:

#### 1. Configure authentication backend

**File**: `src/config/settings/base.py`

**Intent**: Tell Django to use OIDC for authentication while keeping ModelBackend for admin/superuser access.

**Contract**: Add `AUTHENTICATION_BACKENDS` setting with `mozilla_django_oidc.auth.OIDCAuthenticationBackend` and `django.contrib.auth.backends.ModelBackend`.

#### 2. Create initial migrations for session storage

**File**: `src/core/migrations/` (generated)

**Intent**: Ensure Django session and auth tables exist in the database.

**Contract**: Run `python src/manage.py migrate` — this creates `django_session`, `auth_user`, and related tables.

### Success Criteria:

#### Automated Verification:

- Migrations apply cleanly: `python src/manage.py migrate --check`
- Auth backends configured: `python -c "from django.conf import settings; print(settings.AUTHENTICATION_BACKENDS)"`

#### Manual Verification:

- Database has session and user tables (check via Django shell or DB client)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 3: Auth Middleware & URLs

### Overview

Wire up OIDC URLs (login, logout, callback) and add middleware to protect routes.

### Changes Required:

#### 1. Add OIDC URLs

**File**: `src/config/urls.py`

**Intent**: Mount mozilla-django-oidc URLs for login, logout, and callback endpoints.

**Contract**: Add `path('oidc/', include('mozilla_django_oidc.urls'))` to urlpatterns.

#### 2. Create login-required middleware

**File**: `src/core/middleware.py` (create)

**Intent**: Redirect unauthenticated requests to login, except for /health and /oidc/ paths.

**Contract**: Create `LoginRequiredMiddleware` class that:
- Allows `/health`, `/oidc/`, and static files without auth
- Checks `request.user.is_authenticated`
- Redirects to `/oidc/authenticate/` if not authenticated
- Respects `OIDC_BYPASS` setting when `DEBUG=True`

#### 3. Register middleware

**File**: `src/config/settings/base.py`

**Intent**: Add the login-required middleware to the middleware stack.

**Contract**: Add `'core.middleware.LoginRequiredMiddleware'` to MIDDLEWARE after AuthenticationMiddleware.

#### 4. Update health endpoint to be explicit

**File**: `src/core/views.py`

**Intent**: Ensure health endpoint works without authentication for K8s probes.

**Contract**: No code change needed — middleware will exempt /health path.

### Success Criteria:

#### Automated Verification:

- URL routes resolve: `python src/manage.py show_urls | grep oidc`
- Middleware loads: `python src/manage.py check`
- Health endpoint accessible: `curl http://localhost:8000/health` returns 200

#### Manual Verification:

- Unauthenticated request to / redirects to /oidc/authenticate/
- /health returns 200 without authentication
- /oidc/authenticate/ redirects to Okta (or shows bypass if OIDC_BYPASS=True)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 4: Error Handling & UX

### Overview

Add user-friendly error handling for auth failures and a logout endpoint.

### Changes Required:

#### 1. Add OIDC error handling view

**File**: `src/core/views.py`

**Intent**: Handle OIDC authentication errors with a user-friendly message and retry option.

**Contract**: Add `oidc_error` view that renders a simple error page with "Authentication failed. Please try again." and a login link. Configure `OIDC_AUTHENTICATION_CALLBACK_FAILURE_REDIRECT_URL` in settings.

#### 2. Add logout view

**File**: `src/core/views.py`

**Intent**: Clear Django session (local logout only, not Okta SLO).

**Contract**: Add `logout_view` that calls `django.contrib.auth.logout()` and redirects to `/`.

#### 3. Add logout URL

**File**: `src/core/urls.py`

**Intent**: Wire up the logout endpoint.

**Contract**: Add `path('logout/', views.logout_view, name='logout')` to urlpatterns.

#### 4. Configure Django messages for flash notifications

**File**: `src/config/settings/base.py`

**Intent**: Enable Django messages framework for auth feedback.

**Contract**: Ensure `django.contrib.messages` is in INSTALLED_APPS and `MessageMiddleware` is in MIDDLEWARE (already present by default).

### Success Criteria:

#### Automated Verification:

- Logout URL resolves: `python src/manage.py show_urls | grep logout`
- Error view exists: `python -c "from core.views import oidc_error"`

#### Manual Verification:

- Visiting /logout clears session and redirects to / (which then redirects to login)
- OIDC errors show friendly message with retry option

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 5: Testing & Dev Bypass

### Overview

Add integration tests for auth flow and ensure the DEBUG bypass works correctly.

### Changes Required:

#### 1. Create auth tests

**File**: `src/core/tests/test_auth.py` (create)

**Intent**: Test the authentication flow, middleware behavior, and bypass functionality.

**Contract**: Test cases for:
- Unauthenticated request redirects to login
- Health endpoint accessible without auth
- Authenticated request returns 200
- OIDC_BYPASS allows access when DEBUG=True
- Logout clears session

#### 2. Add test fixtures for authenticated user

**File**: `src/core/tests/conftest.py` (create)

**Intent**: Provide pytest fixtures for authenticated and unauthenticated test clients.

**Contract**: Create `authenticated_client` fixture that logs in a test user, and `anonymous_client` fixture.

#### 3. Document bypass in README

**File**: `README.md`

**Intent**: Document how to use the auth bypass for local development.

**Contract**: Add section explaining `OIDC_BYPASS=True` usage and security warning that it must never be enabled in production.

### Success Criteria:

#### Automated Verification:

- All auth tests pass: `pytest src/core/tests/test_auth.py -v`
- No bypass in production settings: `grep -r "OIDC_BYPASS" src/config/settings/production.py` returns nothing

#### Manual Verification:

- With OIDC_BYPASS=True and DEBUG=True, can access protected routes without Okta
- With OIDC_BYPASS=False or DEBUG=False, must authenticate via Okta
- README documents the bypass clearly

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Testing Strategy

### Unit Tests:

- Middleware allows /health without auth
- Middleware redirects unauthenticated requests
- Middleware respects OIDC_BYPASS when DEBUG=True
- Logout view clears session

### Integration Tests:

- Full OIDC flow with mock Okta responses (using responses library to mock HTTP)
- Session persists across requests
- Session expires correctly

### Manual Testing Steps:

1. Start app with OIDC_BYPASS=False
2. Visit http://localhost:8000/ — should redirect to Okta
3. Complete Okta login — should redirect back to app
4. Verify session persists on page refresh
5. Click logout — should clear session and redirect to login
6. Test with OIDC_BYPASS=True — should skip Okta entirely

## Performance Considerations

- **Session lookup**: Database-backed sessions add ~1-2ms per request. Acceptable for MVP; can migrate to Redis later if needed.
- **OIDC token validation**: mozilla-django-oidc caches JWKS keys. No per-request Okta calls after initial login.
- **Middleware overhead**: LoginRequiredMiddleware is a simple boolean check; negligible impact.

## Migration Notes

- **Database migration**: Phase 2 creates session and auth tables. Run `migrate` before deploying.
- **Environment variables**: Must set `OIDC_RP_CLIENT_ID`, `OIDC_RP_CLIENT_SECRET`, `OKTA_DOMAIN` before app starts.
- **Okta app registration**: Need to register this app in Okta admin console with callback URL `/oidc/callback/`.

## References

- Roadmap: F-01 in `context/foundation/roadmap.md`
- PRD: FR-001, Access Control section
- mozilla-django-oidc docs: https://mozilla-django-oidc.readthedocs.io/
- Django session settings: `src/config/settings/base.py:60-75`
- Existing middleware stack: `src/config/settings/base.py:23-32`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Dependencies & Settings

#### Automated

- [x] 1.1 Pipfile lock regenerates cleanly — 2f1a507
- [x] 1.2 Django settings load without error — 2f1a507
- [x] 1.3 OIDC settings are present — 2f1a507

#### Manual

- [x] 1.4 Environment variables documented in .env.example — 2f1a507
- [x] 1.5 Settings match Okta app configuration — 2f1a507

### Phase 2: User Model & Migrations

#### Automated

- [x] 2.1 Migrations apply cleanly — a80beae
- [x] 2.2 Auth backends configured — a80beae

#### Manual

- [x] 2.3 Database has session and user tables — a80beae

### Phase 3: Auth Middleware & URLs

#### Automated

- [x] 3.1 URL routes resolve (oidc paths) — 29d4e3f
- [x] 3.2 Middleware loads — 29d4e3f
- [x] 3.3 Health endpoint accessible without auth — 29d4e3f

#### Manual

- [x] 3.4 Unauthenticated request redirects to login — 29d4e3f
- [ ] 3.5 /oidc/authenticate/ redirects to Okta

### Phase 4: Error Handling & UX

#### Automated

- [x] 4.1 Logout URL resolves — 29d4e3f
- [x] 4.2 Error view exists — 29d4e3f

#### Manual

- [ ] 4.3 /logout clears session and redirects
- [x] 4.4 OIDC errors show friendly message

### Phase 5: Testing & Dev Bypass

#### Automated

- [x] 5.1 All auth tests pass
- [x] 5.2 No bypass in production settings

#### Manual

- [ ] 5.3 OIDC_BYPASS works in development
- [x] 5.4 OIDC_BYPASS disabled blocks without Okta
- [ ] 5.5 README documents bypass
