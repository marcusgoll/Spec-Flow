---
name: staging-deployment-phase
description: "Capture lessons from /phase-1-ship (staging deployment). Auto-triggers when: deploying to staging, running migrations, health checks. Updates when: deployment failures, migration issues, health check failures."
allowed-tools: Read, Write, Edit, Grep, Bash
---

# Staging Deployment Phase: Lessons Learned

**Capability**: Learn from staging deployments to ensure smooth deploys, safe migrations, and proper health validation.

**When I trigger**:
- `/phase-1-ship` starts → Load lessons to guide deployment and health checks
- Deployment complete → Detect if failures occurred, migrations risky, health checks insufficient
- Error: Staging deployment failed → Capture root cause

**Supporting files**:
- [reference.md](reference.md) - Deployment checklist, migration safety, health check patterns
- [examples.md](examples.md) - Successful deploys vs failed deploys
- [scripts/health-check-validator.sh](scripts/health-check-validator.sh) - Validates health checks before deploy

---

## Common Pitfalls (Auto-Updated)

### 🚫 Migration Failures

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Critical (data corruption, downtime)

**Detection**:
```bash
# Check migration ran successfully
if ! grep -q "Migration.*successful" deploy.log; then
  echo "⚠️  Migration may have failed"
fi
```

**Prevention**:
1. Test migrations on development database first
2. Create rollback migration before deploying
3. Backup database before running migrations

---

### 🚫 Health Checks Not Configured

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: High (undetected service failures)

**Detection**:
```bash
# Verify health endpoint responds
curl -f http://staging-url/health || echo "⚠️  Health check failed"
```

**Prevention**:
1. Add /health endpoint returning service status
2. Configure platform health checks (Railway, Vercel)
3. Verify health checks pass after deploy

---

## Successful Patterns (Auto-Updated)

### ✅ Safe Deployment Workflow

**Approach**:
1. Run tests locally (ensure passing)
2. Create PR and merge to staging branch
3. Deploy to staging environment
4. Run migrations (if applicable)
5. Verify health checks pass
6. Run smoke tests

**Results**: Smooth deployments, quick rollback if needed

---

## Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Staging deploy success rate | ≥95% | Not tracked | - |
| Migration failures | 0 | Not tracked | - |
| Deploy time | <10 min | Not tracked | - |

**Updated**: Not yet tracked
