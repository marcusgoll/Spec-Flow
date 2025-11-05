# Project Configuration

**Version**: 1.0.0
**Last Updated**: [AUTO-GENERATED]
**Project**: [PROJECT_NAME]

> This document defines project-specific configuration settings that control workflow behavior. These settings are auto-detected but can be overridden.

---

## Deployment Model

**Current**: [DEPLOY_MODEL] _(auto-detected, can be overridden)_

**Available Models**:
- `staging-prod` - Full staging validation before production (recommended)
- `direct-prod` - Direct production deployment without staging
- `local-only` - Local builds only, no remote deployment

**Auto-Detection Logic**:

The deployment model is automatically detected based on repository configuration:

1. **staging-prod** - All of the following are true:
   - Git remote configured (`git remote -v | grep origin`)
   - Staging branch exists (`git show-ref refs/heads/staging` or `refs/remotes/origin/staging`)
   - Staging workflow exists (`.github/workflows/deploy-staging.yml`)

2. **direct-prod** - When:
   - Git remote configured
   - No staging branch or staging workflow

3. **local-only** - When:
   - No git remote configured

**Manual Override**:

To override auto-detection, update the **Current** line above with:
```
**Current**: staging-prod
```

_(Write exactly one of: staging-prod, direct-prod, local-only)_

---

## Workflow Paths by Model

| Model | Post-Implementation Workflow |
|-------|------------------------------|
| staging-prod | /optimize → /preview → /ship-staging → /validate-staging → /ship-prod |
| direct-prod | /optimize → /preview → /deploy-prod |
| local-only | /optimize → /preview → /build-local |

**Unified Command**: Use `/ship` after `/implement` to automatically execute the appropriate workflow based on deployment model.

---

## Quick Changes Policy

**Quick Changes**: For small bug fixes, refactors, or enhancements (<100 LOC), use `/quick "description"` instead of full `/feature` workflow.

**Criteria for Quick Changes**:
- Bug fixes
- Refactoring without behavior changes
- Documentation updates
- Configuration changes
- Small enhancements (<100 lines of code)

**When NOT to use Quick Changes**:
- New features (always use `/feature`)
- Breaking API changes
- Database schema changes
- Security-sensitive changes

---

## Scale Tier

**Current**: [SCALE] _(from capacity-planning.md)_

**Available Tiers**:
- `micro` - 100 users, simple CRUD, minimal infrastructure
- `small` - 1,000 users, basic features, some optimization
- `medium` - 10,000 users, complex features, scaling considerations
- `large` - 100,000+ users, distributed systems, high performance

**Impact on Effort Estimates**:
- micro tier: Features take 1-2 sprints
- small tier: Features take 2-3 sprints
- medium tier: Features take 3-5 sprints
- large tier: Features take 5-8 sprints

_(Scale tier is set in `docs/project/capacity-planning.md` and used by `/roadmap` for effort estimation)_

---

## References

- Deployment Strategy: `docs/project/deployment-strategy.md`
- Capacity Planning: `docs/project/capacity-planning.md`
- Engineering Principles: `docs/project/engineering-principles.md`
