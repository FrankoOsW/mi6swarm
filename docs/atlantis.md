---
title: Atlantis Integration
description: Infrastructure as Code with Terraform and Atlantis
category: infrastructure
tags: [atlantis, terraform, terragrunt, infrastructure-as-code, aws]
---

# Atlantis Integration

## What Is This?

When you provision a service through the S2 web interface, this template generates a complete Infrastructure as Code (IaC) setup managed by [Atlantis](https://www.runatlantis.io/) (Terraform + Terragrunt). After provisioning, your service repository will contain Terraform modules for **core infrastructure**, **logging**, and **monitoring** — deployed across **staging** and **production** environments automatically.

## What Gets Created in Your Repository

After provisioning, the following structure is added to your service repository:

```
mi6swarm/
├── atlantis.yaml                            # Atlantis project configuration
├── assets-cd/
│   ├── core/                                # Core infrastructure (IAM roles, ESO)
│   │   ├── terragrunt.hcl                   # Terragrunt config (auto-generated)
│   │   ├── sources/
│   │   │   ├── irsa_iam.tf                  # IRSA IAM role (auto-generated)
│   │   │   ├── eso_iam.tf                   # ESO IAM role + policy (auto-generated)
│   │   │   ├── variables.tf                 # Input variables (auto-generated)
│   │   │   ├── network_variables.tf         # Network variables (auto-generated)
│   │   │   ├── network_data.tf              # Network data sources (auto-generated)
│   │   │   ├── data.tf                      # AWS data sources (auto-generated)
│   │   │   ├── locals.tf                    # Local values (auto-generated)
│   │   │   ├── providers.tf                 # AWS provider (auto-generated)
│   │   │   └── versions.tf                  # Terraform version constraints (auto-generated)
│   │   └── environments/
│   │       ├── staging/
│   │       │   ├── environment.hcl          # Staging account config (auto-generated)
│   │       │   └── eu-west-1/
│   │       │       ├── terragrunt.hcl       # Region include (auto-generated)
│   │       │       ├── terraform.tfvars     # EKS cluster OIDC (auto-generated)
│   │       │       ├── tags.auto.tfvars     # Cost tags (auto-generated)
│   │       │       └── network.auto.tfvars  # VPC, subnets, AZs (auto-generated)
│   │       └── production/
│   │           └── ...                      # Same structure as staging
│   ├── logging/                             # Unified Logging (Kinesis stream)
│   │   ├── terragrunt.hcl                   # Terragrunt config (auto-generated)
│   │   ├── sources/
│   │   │   ├── kinesis.tf                   # Logging stream module (auto-generated)
│   │   │   ├── variables.tf                 # Input variables (auto-generated)
│   │   │   ├── providers.tf                 # AWS provider (auto-generated)
│   │   │   └── versions.tf                  # Terraform version constraints (auto-generated)
│   │   └── environments/
│   │       ├── staging/
│   │       │   ├── environment.hcl          # Staging account config (auto-generated)
│   │       │   └── eu-west-1/
│   │       │       ├── terragrunt.hcl       # Region include (auto-generated)
│   │       │       ├── terraform.tfvars     # ✏️ Logging settings (editable)
│   │       │       └── tags.auto.tfvars     # Cost tags (auto-generated)
│   │       └── production/
│   │           └── ...                      # Same structure as staging
│   └── monitoring/                          # Observability (New Relic alerts + dashboards)
│       ├── terragrunt.hcl                   # Terragrunt config (auto-generated)
│       ├── sources/
│       │   ├── monitoring.tf                # Observability essentials module (auto-generated)
│       │   ├── variables.tf                 # Input variables (auto-generated)
│       │   ├── data.tf                      # New Relic data source (auto-generated)
│       │   ├── providers.tf                 # AWS + New Relic providers (auto-generated)
│       │   └── versions.tf                  # Terraform version constraints (auto-generated)
│       └── environments/
│           └── production/
│               ├── environment.hcl          # Production account config (auto-generated)
│               └── eu-west-1/
│                   ├── terragrunt.hcl       # Region include (auto-generated)
│                   ├── terraform.tfvars     # ✏️ Monitoring settings (editable)
│                   └── tags.auto.tfvars     # Cost tags (auto-generated)
```

## How Infrastructure Deployment Works

1. You create a **merge request** (MR) in your service repository that modifies files under `assets-cd/`.
2. Atlantis automatically runs `terragrunt plan` for affected projects and posts the plan as an MR comment.
3. After reviewing the plan, the user provides MR approval.
4. Now Atlantis will run `terragrunt apply` on the given project after the user writes `terragrunt apply -p <project>` comment, or on all projects if the user writes `terragrunt apply` comment.

Atlantis auto-detects which projects are affected based on file changes — each project watches its own `sources/**/*.tf`, `**/*.hcl`, `**/*.tfvars`, and `**/*.yaml` files.

### How to Re-Execute a Plan

- `terragrunt plan -p <project>` - Plan a single project
- `terragrunt plan` - Plan all projects

### How to Unlock a Workspace and What It Is Used For

Each integration update of the repository keeps a separate workspace (one per MR) and only one can be active at a time. Workspaces are named like `<project name>!<MR number>`. Sometimes a user might need to apply one integration before another. For example:
Repository A has three MRs:

 - #16 (first executed)
 - #17
 - #18

Now user can't run terragrunt apply on `MR#17` because workspace is locked on `MR#17`. User needs to comment atlantis unlock in `MR#16` in order to run terragrunt on `MR#17`. After `MR#17` is successfully applied `MR#16` or `MR#18` are ready for terragrunt without unlocking (successful apply unlocks workspace automatically)

### Atlantis Projects

The `atlantis.yaml` file defines the following projects:

| Project | Directory | Environments |
|---|---|---|
| `core` | `assets-cd/core/environments/{env}/{region}` | Staging + Production |
| `logging` | `assets-cd/logging/environments/{env}/{region}` | Staging + Production |
| `monitoring` | `assets-cd/monitoring/environments/{env}/{region}` | Production only |
| `custom-infrastructure` | `assets-cd/custom-infrastructure/environments/{env}/{region}` | Staging + Production |

All projects require MR approval before apply (`apply_requirements: [approved]`) and use Terraform v1.8.5 with Terragrunt.

## What Each Module Creates

### Core (`assets-cd/core/`)

Provisions the foundational IAM infrastructure:

- **IRSA IAM Role** — an IAM role for Kubernetes service accounts (via `terraform-aws-modules/iam`), allowing pods in your namespace to assume AWS permissions. Created as `<service-slug>-irsa-<region>`.
- **ESO IAM Role** — an IAM role for External Secrets Operator, granting access to AWS Secrets Manager for secrets prefixed with your service slug. Created as `<service-slug>-eso-<region>`.
- **Network Data** — looks up VPC, subnet, and availability zone details for use by other resources.

### Logging (`assets-cd/logging/`)

Provisions a Unified Logging stream:

- **Kinesis Stream** — creates a logging stream (via `tf-unified-logging-stream`) that collects logs from your service. Configures alert notifications to your team's Slack channels and email.

### Monitoring (`assets-cd/monitoring/`)

Provisions New Relic observability essentials (production only):

- **Dashboards** — overview, application, Kubernetes, networking, changes, and RDS pages
- **Alert Conditions** — pre-configured (but disabled by default) alerts for:
  - ALB: requests anomalies, error rate, latency
  - APM: requests anomalies, error rate, latency, Apdex
  - Kubernetes: high CPU, high memory, excessive restarts
- **Alert Workflows** — routes alerts to your team's Slack channels via New Relic workflows

## What You Can Edit

> ⚠️ **DO NOT modify auto-generated files** (marked with the header _"This file is auto-generated from a template"_). These files are overwritten on template updates. Your changes will be lost.

### Customizing Alert Settings

New Relic alert thresholds can be customized per environment using `custom.auto.tfvars` files. The monitoring module includes the following configurable alerts:

| Alert | Location |
|---|---|
| ALB Requests Anomaly | `assets-cd/monitoring/environments/production/eu-west-1/custom.auto.tfvars` |
| ALB Error Rate | Same location |
| ALB Latency | Same location |
| APM Requests Anomaly | Same location |
| APM Error Rate | Same location |
| APM Latency | Same location |
| APM Apdex | Same location |
| Kubernetes High CPU | Same location |
| Kubernetes High Memory | Same location |
| Kubernetes Excessive Restarts | Same location |

#### How to Override Alert Settings

Create or edit `custom.auto.tfvars` in your monitoring environment directory. You only need to specify the attributes you want to change; all other values default to those in `terraform.tfvars`.

**Example 1: Enable ALB requests alert with custom thresholds**

```hcl
alb_requests_alert = {
  status                       = true
  warning_deviation_threshold  = 5
  critical_deviation_threshold = 8
}
```

Missing attributes automatically use defaults:
- `warning_duration = 120`
- `critical_duration = 120`
- `aggregation_window = 60`
- `aggregation_delay = 120`

**Example 2: Adjust Kubernetes memory alert thresholds**

```hcl
high_memory_alert = {
  status              = true
  warning_threshold   = 80
  critical_threshold  = 92
}
```

**Example 3: Modify multiple alerts**

```hcl
alb_latency_alert = {
  status             = true
  critical_threshold = 200
}

apm_errors_alert = {
  status             = true
  warning_threshold  = 5
}

high_cpu_alert = {
  status             = true
}
```

#### Alert Configuration Schema

Each alert supports the following attributes (all optional with intelligent defaults):

**Anomaly-based alerts** (ALB & APM requests):
```hcl
{
  status                       = bool                # Enable/disable alert (default: false)
  warning_deviation_threshold  = number              # Standard deviations (default: 4)
  warning_duration             = number              # Seconds (default: 120)
  critical_deviation_threshold = number              # Standard deviations (default: 6)
  critical_duration            = number              # Seconds (default: 120)
  aggregation_window           = number              # Seconds (default: 60)
  aggregation_delay            = number              # Seconds (default: 120)
}
```

**Threshold-based alerts** (errors, latency, resource utilization):
```hcl
{
  status             = bool                 # Enable/disable alert (default: false)
  warning_threshold  = number                # Alert threshold (varies by alert type)
  warning_duration   = number                # Seconds (default: 60)
  critical_threshold = number                # Alert threshold (varies by alert type)
  critical_duration  = number                # Seconds (default: 60)
  aggregation_window = number                # Seconds (default: 60)
  aggregation_delay  = number                # Seconds (default: 120)
}
```

#### Default Alert Settings

Refer to `terraform.tfvars` in your environment directory for the default threshold values. All defaults are defined as object attributes in `sources/variables.tf`, so partial overrides merge seamlessly with defaults.
