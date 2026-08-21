---
title: GitLab Integration
description: Description of the GitLab Integration template, which sets up a GitLab CI/CD pipeline for deploying your service to Kubernetes (EKS) using ArgoCD.
category: infrastructure
tags: [gitlab, ci/cd, kubernetes, eks]
---

# GitLab Integration

## What Is This?

When you provision a service through the S2 web interface, this template generates the root `.gitlab-ci.yml` file that defines your CI/CD pipeline stages and reusable rule templates. It provides the foundation that all other integration templates (ArgoCD, Atlantis, etc.) build upon.

## What Gets Created in Your Repository

```
mi6swarm/
├── .gitlab-ci.yml       # Root pipeline definition (auto-generated)
└── .gitlab/             # ✏️ Place your custom CI jobs here
```

## What the Pipeline Defines

The generated `.gitlab-ci.yml` includes:

**Stages** (in order):
1. `pre-build` - actions like validation of cache, linting
2. `build-binary`  - running build of binary
3. `test` - executing unit, integration tests
4. `build` - additional stage that can substitute for build-binary if tests should be executed before builds
5. `docker` - creating docker image
6. `analyze` - static code analysis
7. `security` - sonarqube
8. `pre-deploy-staging` - imperative actions that should happen before deployment, like contract checking
9. `deploy-staging` - deployment to staging
10. `post-deploy-staging` - checking the deployment success in imperative way (recommended way to do it is to do Workflow object for ArgoCD)
11. `pre-deploy-production`
12. `deploy-production`
13. `post-deploy-production`

**Reusable rule templates:**
- `.run_on_master_and_mr` — runs on the default branch and merge requests
- `.run_on_master` — runs only on the default branch
- `.run_on_mr` — runs only on merge requests
- `.run_on_hotfix` — runs only on merge requests from `hotfix/*` branches
- `.run_on_master_and_mr_and_hotfix` — runs on the default branch, merge requests, and hotfix MRs
- `.run_on_master_and_hotfix` — runs on the default branch and hotfix MRs

**Auto-include:** All `.yml` files from the `.gitlab/` directory are automatically included via `include: '.gitlab/**.yml'`.

## What You Should Not Edit

> ⚠️ **Modifying `.gitlab-ci.yml` is not recommended.** This file is auto-generated and will be overwritten on integration updates. If you must edit it, be aware that when S2 re-renders the template, your changes will be overwritten. In that case, you will need to manually revert the auto-generated changes and reintroduce your edits after each update.

## What You Can Edit

### Adding Custom CI Jobs

To add custom jobs to the pipeline, create new `.yml` files in the `.gitlab/` directory. They are automatically included via the `include: '.gitlab/**.yml'` directive in the root pipeline.

**Example** — `.gitlab/.gitlab-ci-tests.yml`:

```yaml
unit-tests:
  stage: test
  extends: .run_on_master_and_mr
  image: python:3.12
  script:
    - pip install -r requirements.txt
    - pytest
```

Use the pre-defined stages and rule templates from the root pipeline. Other integration templates (e.g., ArgoCD deployment jobs) also place their files in `.gitlab/`.
