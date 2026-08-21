---
title: OpsLevel Integration
description: Learn how to use the OpsLevel Integration to connect your service to OpsLevel for enhanced monitoring, management, and governance.
category: infrastructure
tags: [opslevel, monitoring, management, governance]
---

# OpsLevel Integration

## What Is This?

When you provision a service through the S2, this template generates an `opslevel.yml` file that registers your service in [OpsLevel](https://app.opslevel.com/) — the service catalog used for ownership, governance, and operational visibility. The file is automatically synced by OpsLevel's GitLab integration.

## What Gets Created in Your Repository

```
mi6swarm/
└── opslevel.yml    # OpsLevel service descriptor (auto-generated)
```

## What Gets Configured

The generated `opslevel.yml` registers your service with:

| Field | Value | Source |
|---|---|---|
| Name | Service name | S2 provisioning form |
| Owner | Team UID | Automatically from your team |
| Lifecycle | Service lifecycle stage | S2 provisioning form (e.g., `PoC`) |
| Tier | Service tier | S2 provisioning form (e.g., `tier-4`) |
| Description | Service description | S2 provisioning form |
| Aliases | Service UID | Auto-generated |
| Repository | GitLab project path | Auto-linked |
| Tags | OpsLevel cost tags from production | Auto-generated |
| Tools | ArgoCD links (staging + production) | Auto-generated |

**Properties:**
- `creation_source: ServiceShaper` — marks the service as created by S2

**Tools:**
- ArgoCD App Production — link to your production ArgoCD application
- ArgoCD App Staging — link to your staging ArgoCD application

**Tags:**
- All production cost tags (business unit, team, tier, etc.)
- `unified_renovate: daily` (if Renovate integration is enabled)

## What You Can Edit

> ⚠️ **Modifying `opslevel.yml` is not recommended.** This file is auto-generated and will be overwritten on integration updates. 
If you must edit it (e.g., to add custom tools or tags), be aware that when S2 re-renders the template, your changes will be overwritten. In that case, you will need to manually revert the auto-generated changes and reintroduce your edits after each update.

<!-- TODO: https://naspersclassifieds.atlassian.net/browse/OSP-949 -->

Changes to service metadata (name, owner, tier, lifecycle, description) should be made through the **S2 web interface**, which will re-render the file with updated values.
