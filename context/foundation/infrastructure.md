---
project: 10xMI6Swarm
researched_at: 2026-08-20
recommended_platform: OLX Internal Kubernetes + ArgoCD
runner_up: Dokku (self-hosted)
context_type: mvp
tech_stack:
  language: python
  framework: django
  runtime: gunicorn
---

## Recommendation

**Deploy on OLX Internal Kubernetes with ArgoCD.**

This is the standard deployment path at OLX, using the established `infrastructure/europe/olxeu-pipeline-library` for CI/CD. The infrastructure is mature (Helm charts, ArgoCD GitOps, Kaniko image builds) and complies with corporate self-host mandate. While the initial setup has more moving parts than a simple PaaS, it eliminates external vendor dependency and integrates with existing OLX tooling (GitLab CI, container registry, secret management).

## Platform Comparison

| Platform | CLI-first | Managed | Agent-docs | Deploy API | MCP | Corp Policy | Total |
|----------|-----------|---------|------------|------------|-----|-------------|-------|
| **OLX K8s + ArgoCD** | Pass | Pass | Pass | Pass | Fail | **Pass** | 5/6 |
| Railway | Pass | Pass | Pass | Pass | **Pass** | Fail | 5/6 |
| Fly.io | Pass | Pass | Pass | Pass | Partial | Fail | 4.5/6 |
| Dokku | Pass | Pass | Pass | Pass | Fail | Pass* | 5/6 |
| Render | Pass | Pass | Partial | Pass | Pass | Fail | 4.5/6 |

*Dokku would require a separate self-hosted server outside OLX standard infra.

### Shortlisted Platforms

#### 1. OLX Kubernetes + ArgoCD (Recommended)

**Why it won**: Native OLX infrastructure, no external dependencies, complies with corporate self-host mandate. Uses established patterns (`olxeu-pipeline-library`), existing container registry (`registry.naspersclassifieds.com`), and GitOps deployment via ArgoCD. The Platform Team maintains the underlying infrastructure — you manage only the application layer (Helm chart, Dockerfile, CI config).

Key OLX infrastructure components discovered:
- GitLab CI runners: `eu-tooling-k8s`
- Pipeline library: `infrastructure/europe/olxeu-pipeline-library`
- ArgoCD templates: `/includes/argocd-deploy.yml`
- Image build: Kaniko via `/includes/kaniko.gitlab-ci.yml`
- Registry: `registry.naspersclassifieds.com`

#### 2. Dokku (Self-hosted)

**Why it scored second**: Battle-tested (11+ years, 32k GitHub stars), Heroku-style git-push deployment, works with GitLab CI via SSH. Would satisfy self-host requirement but requires provisioning a separate server outside standard OLX infra. Better for teams who want minimal K8s complexity and faster initial setup.

Gap vs recommendation: Requires separate infrastructure outside OLX standard path; no MCP integration; single-server architecture without built-in HA.

#### 3. Railway (External PaaS — Disqualified)

**Why it was considered**: Best-in-class MCP integration (`railway mcp install`, `railway agent`), excellent DX for AI projects, native agent tooling. Would have been top choice if external SaaS were allowed.

Gap vs recommendation: **Disqualified by corporate self-host mandate.** Data would leave OLX network; potential compliance issues for internal tool with access to competitive data.

## Anti-Bias Cross-Check: OLX K8s + ArgoCD

### Devil's Advocate — Weaknesses

1. **Steeper learning curve**: Helm charts + ArgoCD + GitLab CI pipeline = more configuration than simple `git push`
2. **No MCP integration**: kubectl/Helm/ArgoCD lack native MCP — agent parses CLI output for operations
3. **Onboarding time**: First deployment requires coordination with Platform Team (namespace, ArgoCD access, secrets)
4. **Overkill for MVP**: Enterprise-grade K8s for a single Django instance may be over-engineered
5. **Debugging complexity**: Issues may require K8s knowledge (pods, services, ingress, resource limits)

### Pre-Mortem — How This Could Fail

Six months after deploying to internal K8s, the team realized:
- Helm chart + ArgoCD configuration took 2 weeks instead of planned 2 days — no one on team knew Helm well
- Pod kept crashing with OOMKilled because resource limits were too low for LLM inference; debugging required Platform Team help
- Secret management (LLM API keys) required Vault integration, adding another week
- Hotfix deployments took 15 minutes (CI build + ArgoCD sync) vs. seconds on simpler platforms

### Unknown Unknowns

- **Namespace provisioning**: Does the team already have a K8s namespace, or does one need to be requested?
- **Ingress/DNS**: How to configure internal domain (e.g., `mi6swarm.internal.olx.com`)?
- **Secrets management**: Does OLX use External Secrets, Vault, or something else?
- **Resource quotas**: Does the namespace have CPU/RAM limits that might be too low for AI workloads?
- **SSO integration**: Is there an existing pattern for OLX SSO in K8s apps?

## Operational Story

How OLX K8s + ArgoCD operates day to day:

- **Preview deploys**: Branch deploys possible via ArgoCD ApplicationSets (configure per-branch preview environments). May require Platform Team setup for initial configuration. Preview URLs follow pattern like `mi6swarm-<branch>.preview.internal.olx.com`.

- **Secrets**: Environment variables stored in K8s Secrets, likely managed via External Secrets Operator synced from Vault or similar. Platform Team owns the secret store; you request secrets via ticket or self-service portal (verify with Platform Team).

- **Rollback**: ArgoCD UI or CLI (`argocd app rollback <app> <revision>`). Can also rollback by reverting Git commit and letting ArgoCD sync. Typical time-to-revert: 2-5 minutes after Git merge.

- **Approval**: Production deploys typically require MR approval in GitLab before ArgoCD syncs. Agent may stage changes; human approves merge to trigger deploy. Database migrations should be reviewed separately.

- **Logs**: `kubectl logs -f deployment/<app> -n <namespace>` for real-time. Historical logs likely aggregated in Grafana Loki or similar (verify with Platform Team). ArgoCD UI shows deployment events and sync status.

## Risk Register

| Risk | Source | Likelihood | Impact | Mitigation |
|------|--------|------------|--------|------------|
| OOMKilled pods from AI workloads | Pre-mortem | Medium | High | Request higher resource limits upfront; profile memory usage during dev |
| Slow onboarding (namespace, secrets) | Unknown unknowns | Medium | Medium | Start Platform Team conversation early; parallelize with app development |
| Helm chart complexity blocks team | Devil's advocate | Medium | Medium | Use existing OLX app as template (e.g., Satori pattern); consider Kustomize as simpler alternative |
| Secret rotation breaks LLM calls | Unknown unknowns | Low | High | Document secret dependencies; test rotation in staging first |
| ArgoCD sync delays hotfixes | Pre-mortem | Low | Medium | Configure auto-sync for staging; manual sync trigger for production emergencies |
| No MCP = agent errors on infra ops | Devil's advocate | Medium | Low | Keep infra ops human-supervised; agent focuses on app code, not kubectl |

## Lived-repo alignment (2026-09-11)

The platform choice (OLX K8s + ArgoCD / GitLab CI) **matches** this repo. Do **not** follow the greenfield Getting Started below as a first-time scaffold — `Dockerfile`, `.gitlab-ci.yml` (S2 includes), Helm under `assets-cd/`, and Atlantis already exist.

| Research note | Lived in this repo |
|---------------|-------------------|
| Example Dockerfile: `python:3.12-slim` + `requirements.txt` + `uv`/pip | **`python:3.11-alpine`**, Pipenv, `PYTHONPATH=/opt/app/src` |
| Example CI: `olxeu-pipeline-library` kaniko + argocd includes | **S2-generated** `.gitlab-ci.yml` + `.gitlab/**.yml` |
| “Create Helm from Satori” | Charts already under `assets-cd/` |
| SSO “unknown” | Being implemented as Okta OIDC (`sso-auth-scaffold`, F-01) |
| Atlantis | Present (`atlantis.yaml`); app pytest does **not** cover apply/plan |

Infra init / Atlantis pain is operational, not a product FR. Keep it out of the Django test suite (`context/foundation/test-plan.md` §7).

## Getting Started

1. **Request namespace and ArgoCD access** from Platform Team (likely via Jira ticket or Slack channel — verify internal process)

2. **Clone an existing OLX app** as template for Helm chart structure:
   ```bash
   # Example pattern from Satori project
   mkdir -p helm/charts/mi6swarm/templates
   # Copy deployment.yaml, service.yaml, values.yaml structure
   ```

3. **Create Dockerfile** for Django app:
   ```dockerfile
   FROM python:3.12-slim
   WORKDIR /app
   COPY requirements.txt .
   RUN pip install --no-cache-dir -r requirements.txt
   COPY . .
   RUN python manage.py collectstatic --noinput
   CMD ["gunicorn", "--bind", "0.0.0.0:8000", "config.wsgi:application"]
   ```

4. **Configure GitLab CI** using shared pipeline library:
   ```yaml
   include:
     - project: infrastructure/europe/olxeu-pipeline-library
       ref: master
       file: /includes/kaniko.gitlab-ci.yml
     - project: infrastructure/europe/olxeu-pipeline-library
       ref: master
       file: /includes/argocd-deploy.yml
   
   variables:
     ARGOCD_APP_NAME: mi6swarm
     # ... additional variables per pipeline library docs
   ```

5. **Test locally** before first deploy:
   ```bash
   docker build -t mi6swarm:local .
   docker run -p 8000:8000 mi6swarm:local
   ```

## Out of Scope

The following were not evaluated in this research:
- Docker image configuration (Dockerfile specifics for Django)
- CI/CD pipeline setup (detailed GitLab CI jobs beyond includes)
- Production-scale architecture (multi-region, HA, DR)
- SSO integration implementation (covered in PRD, separate from infra)
- Database provisioning (PostgreSQL setup within K8s)
