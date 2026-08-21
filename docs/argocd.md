---
title: ArgoCD Integration
description: Learn how to use the ArgoCD Integration to set up continuous deployment for your service on Kubernetes (EKS) with ArgoCD.
category: infrastructure
tags: [argocd, continuous-deployment, kubernetes, eks]
---

# ArgoCD Integration

## What Is This?

When you provision a service through the S2 web interface, this template generates a complete ArgoCD-based continuous deployment setup for your service on Kubernetes (EKS). After provisioning, your service repository will contain everything needed to deploy to **staging** and **production** environments — no manual setup required.

## What Gets Created in Your Repository

After provisioning, the following structure is added to your service repository:

```
mi6swarm/
├── .gitlab/
│   └── .gitlab-ci-deployment.yml    # Deployment pipeline (staging + production)
├── assets-cd/
│   ├── argocd/
│   │   ├── production.yaml          # ArgoCD Application definition for production
│   │   └── staging.yaml             # ArgoCD Application definition for staging
│   └── kubernetes/
│       ├── Chart.yaml               # Helm chart (uses common-resource-templates)
│       ├── environments/
│       │   ├── production/
│       │   │   ├── values.yaml      # Production configuration (auto-generated)
│       │   │   └── custom-values.yaml  # ✏️ YOUR production overrides
│       │   └── staging/
│       │       ├── values.yaml      # Staging configuration (auto-generated)
│       │       └── custom-values.yaml  # ✏️ YOUR staging overrides
│       ├── migrations/              # Place your SQL migration files here (if RDS enabled)
│       └── templates/
│           ├── namespace.yaml       # Namespace (auto-generated)
│           ├── resources.yaml       # Main resources — Deployment, Service, HPA, etc. (auto-generated)
│           ├── service_account.yaml # IAM service account (auto-generated)
│           └── workflow-rbac.yaml   # Argo Workflows RBAC (auto-generated)
```

## What You Can Edit

> ⚠️ **DO NOT modify auto-generated files** (marked with the header _"This file is auto-generated from a template"_). These files are overwritten on template updates. Your changes will be lost.

### 1. Custom Helm Values (most common)

To override default configuration, edit the `custom-values.yaml` files:

- `assets-cd/kubernetes/environments/staging/custom-values.yaml` — staging overrides
- `assets-cd/kubernetes/environments/production/custom-values.yaml` — production overrides

These files are loaded **after** the auto-generated `values.yaml`, so any values you set here take precedence.

**Common overrides:**

```yaml
# Change resource limits
applications:
  mi6swarm:
    containers:
      app:
        resources:
          limits:
            cpu: "1000m"
            memory: "1Gi"
          requests:
            cpu: "500m"
            memory: "1Gi"

# Change autoscaling
    autoscaling:
      minReplicas: "5"
      maxReplicas: "20"

# Change health check path
    containers:
      mi6swarm:
        readinessProbe:
          httpGet:
            path: /ready
        livenessProbe:
          httpGet:
            path: /healthz

# Add environment variables
    containers:
      mi6swarm:
        envs:
          MY_CUSTOM_VAR: "my-value"
          FEATURE_FLAG_X: "true"
```

### 2. Database Migrations

If your service has RDS enabled, place SQL migration files in:

```
assets-cd/kubernetes/migrations/
```

Migrations are executed automatically before deployment using Flyway via Argo Workflows. Files should follow the Flyway naming convention (e.g., `V1__create_tables.sql`, `V2__add_index.sql`).

### 3. GitLab CI Extensions

To add custom CI jobs (e.g., tests, linting, security scans), create new `.yml` files in the `.gitlab/` directory. Do **not** edit `.gitlab/.gitlab-ci-deployment.yml`.

## Default Configuration

The template generates the following defaults for your service. Override them via `custom-values.yaml` if needed.

### Application

| Setting | Staging | Production |
|---|---|---|
| Controller | Deployment | Deployment |
| Container port | 8000 | 8000 |
| Health check path | `/health` | `/health` |
| Image pull policy | IfNotPresent | IfNotPresent |

### Scaling

| Setting | Staging | Production |
|---|---|---|
| HPA min replicas | 1 | 3 |
| HPA max replicas | 3 | 10 |
| Topology spread | soft | soft |
| Hibernate support | Yes (if enabled via S2) | No |

### Resources

| Setting | Staging | Production |
|---|---|---|
| CPU request | 200m | 200m |
| CPU limit | 600m | 600m |
| Memory request | 500Mi | 500Mi |
| Memory limit | 500Mi | 500Mi |

### Rolling Update Strategy

| Setting | Staging | Production |
|---|---|---|
| maxUnavailable | 30% | 5% |
| maxSurge | 30% | 20% |

### Health Probes

| Probe | Initial Delay | Period | Timeout | Failure Threshold |
|---|---|---|---|---|
| Readiness | 0s | 20s | 5s | 3 |
| Liveness | 30s | 20s | 5s | 3 |
| Startup | 30s | 20s | 5s | 3 |
