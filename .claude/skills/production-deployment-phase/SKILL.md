---
name: production-deployment-phase
description: "Capture lessons from /phase-2-ship (production deployment). Auto-triggers when: promoting to production, creating release tags, monitoring post-deploy. Updates when: production deploy failures, rollback needed, monitoring alerts missed."
allowed-tools: Read, Write, Edit, Grep, Bash
---

# Production Deployment Phase: Lessons Learned

**Capability**: Learn from production deployments to ensure safe releases, proper monitoring, and quick rollback capability.

**When I trigger**:
- `/phase-2-ship` starts → Load lessons to guide production promotion and monitoring
- Deployment complete → Detect if monitoring insufficient, rollback plan unclear
- Error: Production deploy failed or required rollback → Capture root cause

**Supporting files**:
- [reference.md](reference.md) - Production deploy checklist, rollback procedures, monitoring setup
- [examples.md](examples.md) - Smooth production deploys vs incidents

---

## Common Pitfalls (Auto-Updated)

### 🚫 Missing Rollback Plan

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Critical (extended downtime if issues arise)

**Prevention**:
1. Document rollback steps before deploying
2. Keep previous version tagged and deployable
3. Test rollback procedure in staging

---

### 🚫 Insufficient Post-Deploy Monitoring

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: High (delayed incident detection)

**Detection**:
```bash
# Verify monitoring active after deploy
curl -f http://production-url/health || echo "⚠️  Production health check failed"
```

**Prevention**:
1. Monitor for 30 minutes post-deploy
2. Check error rates, response times, user activity
3. Verify alerts fire correctly

---

## Successful Patterns (Auto-Updated)

### ✅ Safe Production Deployment

**Approach**:
1. Staging fully validated (all checks pass)
2. Deploy during low-traffic window
3. Monitor health checks for 30 minutes
4. Verify user flows work
5. Create release notes and tag version

**Results**: Smooth production releases, quick issue detection

---

## Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Production deploy success | ≥98% | Not tracked | - |
| Rollback frequency | <5% | Not tracked | - |
| Deploy duration | <15 min | Not tracked | - |

**Updated**: Not yet tracked
