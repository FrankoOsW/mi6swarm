---
change_id: sso-auth-scaffold
title: SSO Auth Scaffold - Okta OIDC Integration
status: implementing
created: 2026-08-30
updated: 2026-09-10
roadmap_ref: F-01
prd_refs:
  - FR-001
  - Access Control
---

# SSO Auth Scaffold

## Summary

Integrate Okta OIDC authentication into the Django app so users can log in with their OLX corporate identity. This is the gating foundation for all user-facing features.

## Scope

- Okta OIDC integration via mozilla-django-oidc
- Database-backed sessions
- All routes protected except /health
- Local logout (Django session only)
- DEBUG-only auth bypass for development

## Out of Scope

- Single logout (SLO) to Okta
- Role-based access control (flat access per PRD)
- FastAPI authentication (using Django only)
- Custom user profile UI

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| SSO Provider | Okta | OLX enterprise standard |
| Framework | Django only | Mature auth ecosystem, admin for user management |
| Session storage | Database-backed | Simple, persistent, works with Django admin |
| Route protection | All except /health | Secure by default per PRD |
| Logout behavior | Local only | Simple, user can quickly re-login |
| Dev testing | Okta dev tenant + bypass | Real flow tested; bypass speeds iteration |
