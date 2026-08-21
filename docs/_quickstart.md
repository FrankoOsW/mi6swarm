---
title: Quickstart Guide
description: How to start with a new service created by Service Shaper.
category: quickstart
tags:
  - quickstart
  - guide
---
Quickstart instructions are not available for this service template.
<!-- Quickstart instructions for integration template: Atlantis -->
## Atlantis

### Overview

Integrates Atlantis for automated Terraform pull request workflows. Atlantis runs `terraform plan` and `terraform apply` directly from merge requests, enabling infrastructure changes to follow the same review process as application code.

### What's Next

After provisioning, Terraform changes in your repository will be automatically planned and applied via merge request comments. Configure your Atlantis project settings and Terraform workspace as needed.

<!-- Quickstart instructions for integration template: ArgoCD -->
## ArgoCD

### Overview

Integrates ArgoCD-based continuous deployment into your service. ArgoCD watches your Git repository and automatically syncs application state to Kubernetes, providing GitOps-style delivery with drift detection and automated rollbacks.

### What's Next

After provisioning, your deployment manifests will be managed by ArgoCD. Configure your application's sync policy, health checks, and rollback strategy in the generated ArgoCD application manifest.

<!-- Quickstart instructions for integration template: RDS -->
## Generic RDS

### Overview

Provisions an AWS RDS database instance for your service. Supports multiple database engines (PostgreSQL, MySQL, etc.) and provides a managed, scalable relational database with automated backups and failover.

### What's Next

Once provisioned, database connection details will be available through environment variables. Configure your application's database driver and connection pool, and customize instance settings (size, storage, engine version) via Terraform variables.

<!-- Quickstart instructions for integration template: CDN -->
## CDN

### Overview

Adds CDN (Content Delivery Network) infrastructure to your service for serving static assets with low latency across global edge locations. Use this when your application needs fast delivery of images, scripts, stylesheets, or other static content.

### What's Next

Once provisioned, configure your CDN distribution settings including origin, cache behaviors, and custom domain. Update your application to serve static assets through the CDN endpoint.

<!-- Quickstart instructions for integration template: OpsLevel -->
## OpsLevel

### Overview

Integrates your service with OpsLevel for service catalog management. Provides visibility into service ownership, maturity levels, and compliance with organizational standards through a centralized catalog.

### What's Next

After provisioning, your service will be registered in the OpsLevel catalog. Configure service metadata, tier, lifecycle stage, and ownership to track operational maturity and compliance.

<!-- Quickstart instructions for integration template: Docker -->
## Docker

### Overview

Adds Docker image build and push pipeline to your service. Configures CI/CD to build your application's Docker image and publish it to the container registry, making it available for deployment to Kubernetes or other container runtimes.

### What's Next

After provisioning, your CI/CD pipeline will automatically build and push Docker images on each commit. Review the Dockerfile and build configuration to optimize image size and build times.

<!-- Quickstart instructions for integration template: Ingress perftest -->
## Performance Testing

### Overview

Adds performance testing infrastructure and pipeline configuration to your service. Enables automated load testing as part of your CI/CD workflow to catch performance regressions before they reach production.

### What's Next

After provisioning, configure your performance test scenarios, thresholds, and target environments. Integrate the test results into your deployment gates to prevent performance regressions.

<!-- Quickstart instructions for integration template: Elasticache integration -->
## ElastiCache

### Overview

Provisions an AWS ElastiCache cluster (Redis or Memcached) for your service. Use this when your application needs a managed in-memory cache or message broker for session storage, caching, rate limiting, or pub/sub messaging.

### What's Next

Once provisioned, connection details will be available through environment variables. Configure your application to connect to the ElastiCache endpoint and tune cluster settings (node type, replicas, parameter groups) via the Terraform variables.
