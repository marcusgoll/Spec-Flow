---
name: staging-deployment-phase
description: "Standard Operating Procedure for /ship-staging phase. Deploy feature to staging with auto-merge."
allowed-tools: Read, Edit, Bash
---

# Staging Deployment Phase: Standard Operating Procedure

> **Training Guide**: Deploy feature to staging environment for validation.

## Phase Overview
**Purpose**: Deploy to staging, run migrations, verify health
**Inputs**: Merged PR, passing CI
**Outputs**: Staging deployment, ship report
**Expected duration**: 15-30 minutes

## Execution Steps
1. Verify PR merged to main
2. Run database migrations (if any)
3. Deploy to staging environment
4. Run health checks
5. Verify deployment successful
6. Generate staging ship report

## Common Mistakes
- Deployment failures
- Migration issues
- Health check failures

## Completion Criteria
- [ ] Deployed to staging
- [ ] Health checks pass
- [ ] Ship report generated

_This SOP guides staging deployment._
