---
starter_id: django
package_manager: uv
project_name: 10xmi6swarm
hints:
  language_family: python
  team_size: solo
  deployment_target: self-host
  ci_provider: gitlab-ci
  ci_default_flow: auto-deploy-on-merge
  bootstrapper_confidence: verified
  path_taken: standard
  quality_override: false
  self_check_answers: null
  has_auth: true
  has_payments: false
  has_realtime: false
  has_ai: true
  has_background_jobs: false
---

## Why this stack

A Python web-app for an internal AI agent swarm with SSO auth and LLM-powered knowledge synthesis. Django is the recommended default for (web-app, python) — it ships auth, ORM, admin, and migrations out of the box, which covers the conversation history and user management needs. All four agent-friendly criteria pass: Django uses conventions the agent can follow, is popular in Python training data, and has current documentation. Bootstrapper confidence is verified, so scaffolding will be smooth. Deployment targets company self-hosted infrastructure via GitLab CI with auto-deploy on merge. Auth and AI feature flags are set; payments, realtime, and background jobs are out of scope per PRD.

## Lived-repo alignment (2026-09-11)

This hand-off was written for a greenfield `uv` + `django-admin startproject` named `10xmi6swarm`. The GitLab service (`mi6swarm-ss` / `olxeu/mi6/mi6swarm`) already exists. Follow **intent** (Django, GitLab CI, self-host, SSO + AI) and the **lived stack**, not the starter CLI:

| Hand-off | Lived in this repo |
|----------|-------------------|
| `package_manager: uv` | **Pipenv** (`Pipfile`); lesson: commit `Pipfile.lock` |
| `project_name: 10xmi6swarm` | Service `mi6swarm`, layout `src/` |
| Django from `startproject` | Service Shaper Django; split settings `base` / `local` / `production` |
| Python 3.12 (AGENTS.md in the sandbox) | **Python 3.11** (`Dockerfile`: `python:3.11-alpine`) |
| Django 5.2.15 in the sandbox | **Django 5.2.1** in `Pipfile` |

Do not re-run `/10x-bootstrapper` into this repo.
