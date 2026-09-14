# Lessons Learned

> Append-only register of recurring rules and patterns. Re-read at start by /10x-frame, /10x-research, /10x-plan, /10x-plan-review, /10x-implement, /10x-impl-review.

## Commit Pipfile.lock with dependency changes

**Context**: Pipfile.lock missing after dependency additions

**Problem**: Progress marked "Pipfile lock regenerates cleanly" as complete but no Pipfile.lock was committed. Without the lock file, CI builds and other developers may get different dependency versions.

**Rule**: When adding or updating dependencies in Pipfile, always commit the regenerated Pipfile.lock. If local generation fails due to private registries, generate in CI where registry access is available and commit from there. If neither local nor CI generation is possible, discuss with the user how to proceed and provide clear instructions.

**Applies to**: All dependency changes in Python projects using Pipenv

## Do not treat force_login tests as proof the OIDC callback works

**Context**: Django auth tests under tests/test_auth.py; mozilla-django-oidc callback at /oidc/callback/

**Problem**: Green pytest with Client.force_login can pass while Okta code exchange, state/nonce, and redirect_uri are broken. Calling F-01 done from middleware tests alone ships a gate that was never exercised.

**Rule**: Treat OIDC callback/token exchange as a separate signal from LoginRequiredMiddleware tests. Do not mark SSO complete until a mocked or live callback path is proven.

**Applies to**: implement, impl-review

