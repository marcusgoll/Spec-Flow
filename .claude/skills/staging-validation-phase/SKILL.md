---
name: staging-validation-phase
description: "Capture lessons from staging validation (manual gate before production). Auto-triggers when: validating staging deployment, smoke testing, sign-off checklist. Updates when: validation steps skipped, smoke tests insufficient, sign-off unclear."
allowed-tools: Read, Write, Edit, Grep, Bash
---

# Staging Validation Phase: Lessons Learned

**Capability**: Learn from staging validation to ensure production-readiness through systematic checks before promoting to production.

**When I trigger**:
- Staging validation starts → Load lessons to guide smoke testing and sign-off
- Validation complete → Detect if checks skipped, tests insufficient
- Error: Production issue that staging validation should have caught → Capture

**Supporting files**:
- [reference.md](reference.md) - Smoke testing checklist, validation criteria, sign-off template
- [examples.md](examples.md) - Thorough validation vs rushed sign-off

---

## Common Pitfalls (Auto-Updated)

### 🚫 Smoke Tests Skipped

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Critical (broken production deploy)

**Prevention**:
1. Run smoke tests on staging before sign-off
2. Verify critical paths work (auth, main features)
3. Check staging environment health (database, services)

---

### 🚫 Unclear Sign-Off Criteria

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Medium (ambiguous production readiness)

**Prevention**:
1. Define explicit sign-off criteria in ship report
2. Document who signs off and when
3. Verify all criteria met before promoting

---

## Successful Patterns (Auto-Updated)

### ✅ Staging Validation Checklist

**Approach**:
- [ ] Smoke tests pass (critical paths work)
- [ ] Environment health check (database, services responsive)
- [ ] Visual inspection (UI looks correct)
- [ ] Performance check (response times acceptable)
- [ ] Error tracking active (monitoring alerts configured)

**Results**: Confident production promotion

---

## Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Staging validation time | <1 hour | Not tracked | - |
| Production issues from staging | <1 per month | Not tracked | - |

**Updated**: Not yet tracked
