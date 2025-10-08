# Deployment Tracking

This section tracks deployment metadata for rollback capability.

## Current Deployment

**Environment**: [staging|production]
**Deploy ID**: [vercel-deploy-id or git-sha]
**Deployed**: [YYYY-MM-DD HH:MM UTC]
**Status**: [healthy|degraded|unhealthy]
**Rollback Command**: See [Rollback Runbook](#rollback-commands)

## Deployment History

| Date | Environment | Deploy ID | Image SHA | Status | Notes |
|------|-------------|-----------|-----------|--------|-------|
| 2025-01-15 14:30 | production | abc123xyz | ghcr.io/.../api:def456 | ✅ healthy | v1.2.0 release |
| 2025-01-15 12:00 | staging | xyz789abc | ghcr.io/.../api:ghi789 | ✅ healthy | Feature XYZ testing |
| 2025-01-14 16:45 | production | old123old | ghcr.io/.../api:old456 | ⚠️  degraded | Rolled back due to error spike |

## Artifact URLs

**Current Production:**
- Frontend: https://[deploy-id].vercel.app
- Backend: ghcr.io/[org]/[repo]/api:[sha]
- Vercel Project: https://vercel.com/[org]/[project]/[deploy-id]

**Current Staging:**
- Frontend: https://[deploy-id]-staging.vercel.app
- Backend: ghcr.io/[org]/[repo]/api:[sha]

## Rollback Commands

See [docs/ROLLBACK_RUNBOOK.md](../../docs/ROLLBACK_RUNBOOK.md) for detailed procedures.

**Quick Rollback (3 commands):**

```bash
# 1. Find previous deploy ID (from table above)
PREVIOUS_DEPLOY_ID=old123old

# 2. Promote to production
vercel alias set $PREVIOUS_DEPLOY_ID cfipros.com --token=$VERCEL_TOKEN

# 3. Rollback backend
railway service update api --image ghcr.io/cfipros/monorepo/api:old456
```

## Monitoring Links

- **Sentry Releases**: https://sentry.io/organizations/[org]/releases/
- **Vercel Deployments**: https://vercel.com/[org]/[project]/deployments
- **Railway Deployments**: https://railway.app/project/[id]/deployments
- **GitHub Actions**: https://github.com/[org]/[repo]/actions

## Health Check Endpoints

- Frontend: https://app.cfipros.com/health
- Backend: https://api.cfipros.com/api/v1/health/detailed

## Incident Log

| Date | Severity | Issue | Resolution | Rollback? |
|------|----------|-------|------------|-----------|
| 2025-01-14 16:40 | high | Error rate spike (50 errors/5min) | Rolled back to previous deploy | ✅ Yes |
| 2025-01-10 10:15 | medium | Slow DB queries | Added index, no rollback needed | ❌ No |

## Notes

- Always test in staging before production
- Monitor Sentry for 15 minutes post-deployment
- Error rate >5% triggers auto-rollback
- Keep last 3 deployments for fast rollback
