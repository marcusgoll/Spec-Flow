---
name: production-deployment-phase
description: "Standard Operating Procedure for /ship-prod phase. Automated staging→production promotion."
allowed-tools: Read, Edit, Bash
---

# Production Deployment Phase: Standard Operating Procedure

> **Training Guide**: Promote staging to production with versioning and release.

## Phase Overview
**Purpose**: Production deployment with version bump and release
**Inputs**: Validated staging deployment
**Outputs**: Production deployment, release version, production ship report
**Expected duration**: 15-30 minutes

## Execution Steps
1. Verify staging validation complete
2. Bump version (semantic versioning)
3. Deploy to production
4. Run health checks
5. Create git release tag
6. Generate production ship report
7. Monitor post-deploy

## Common Mistakes
- Production deploy failures
- Rollback needed
- Monitoring alerts missed

## Completion Criteria
- [ ] Deployed to production
- [ ] Version bumped and tagged
- [ ] Health checks pass
- [ ] Monitoring configured

_This SOP guides production deployment._
