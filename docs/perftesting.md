---
title: Perftesting Integration
description: Learn how to use the Perftesting Integration to set up loadtests for your service
category: infrastructure
tags: [perftesting, continuous-deployment]
---

# Perftesting Integration

## What is it?

This is a semi-automated GitLab CI/CD pipeline for service shaper applications that generates load tests on specified endpoints using the Encarno engine. The pipeline can perform simple load tests with configurable parameters or use production access logs as ammunition for more realistic traffic patterns.

## How to use it?

The pipeline uses GitLab CI/CD variables to configure the Encarno load testing engine. All test parameters must be set up through your repository's CI/CD variables. To perform a simple load test, specify your service's url in CI/CD variable `LOADTEST_URL` in your repository.

### Configuration Variables

- `LOADTEST_PROJECT`: Project identifier used for generating New Relic reports and S3 bucket subdirectories
- `LOADTEST_URL`: Target endpoint URL for load testing
- `LOADTEST_CONCURRENCY`: Number of concurrent users (default: "10")
- `LOADTEST_HOLD_FOR`: Duration to maintain load (default: "10m")
- `LOADTEST_RAMP_UP`: Time to ramp up to target load (default: "2m")
- `LOADTEST_THROUGHPUT`: Requests per second limit (default: "5")
- `LOADTEST_LABEL`: Label for test identification
- `AWS_ACCOUNT_ID`: AWS account ID for accessing resources
- `USE_AMMO_FROM_S3`: Enable production access logs as ammunition (default: "true")

## How to use production ammo?

Ammo is **enabled** by default when using this integration. This is how it works:

### Prerequisites

1. **Enable production ammo** by setting `USE_AMMO_FROM_S3: "true"` in your repositorieGitLab CI/CD variables
2. **Create a security group** that allows traffic from GitLab runners to your ALB
3. **Configure your ingress** with these required annotations:

```yaml
# From ArgoCD integration
annotations:
  alb.ingress.kubernetes.io/security-groups: <your-security-group-id>
  alb.ingress.kubernetes.io/load-balancer-attributes: access_logs.s3.enabled=true,access_logs.s3.bucket=<AWS_ACCOUNT_ID>-perftesting-access-logs,access_logs.s3.prefix=<LOADTEST_PROJECT>
```