---
name: checks-phase
description: "Capture lessons from /checks phase (fixing CI/deployment blockers after PR creation). Auto-triggers when: CI failures, deployment check failures, test failures block merge. Updates when: recurring check failures, unclear error messages, insufficient fix documentation."
allowed-tools: Read, Write, Edit, Grep, Bash
---

# Checks Phase: Lessons Learned

> **Dynamic data**: Frequencies, metrics, and usage statistics are tracked in [learnings.md](learnings.md) (preserved across npm updates).

**Capability**: Learn from CI/deployment check failures to speed up resolution and prevent recurrence.

**When I trigger**:
- `/checks` starts → Load lessons to guide failure diagnosis and fixes
- Checks complete → Detect if recurring failures, slow resolution, pattern not recognized
- Error: Same check fails repeatedly → Capture pattern

**Supporting files**:
- [reference.md](reference.md) - Common check failures, fix strategies, prevention patterns
- [examples.md](examples.md) - Quick fixes vs trial-and-error debugging
- [scripts/check-analyzer.sh](scripts/check-analyzer.sh) - Analyzes check failure logs for patterns

---

## Common Pitfalls (Auto-Updated)

### 🚫 Recurring Check Failures

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: High (blocks deployment, delays release)

**Detection**:
```bash
# Check for repeated failure types
FAILURE_TYPE="lint error"
COUNT=$(grep -c "$FAILURE_TYPE" .github/workflows/*.log)
if [ $COUNT -gt 2 ]; then
  echo "⚠️  Recurring check failure: $FAILURE_TYPE (seen $COUNT times)"
fi
```

**Prevention**:
1. Before submitting PR, run checks locally
2. If recurring: add pre-commit hook to catch early
3. Document fix in skill file for future reference

---

### 🚫 Unclear CI Error Messages

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Medium (slow diagnosis, frustration)

**Detection**:
```bash
# Check if error logs are verbose enough
if ! grep -q "Error:" ci-output.log; then
  echo "⚠️  CI error message may be unclear"
fi
```

**Prevention**:
1. Configure CI to output verbose errors
2. Add context to error messages (file, line number)
3. Include fix suggestions in CI output

---

## Successful Patterns (Auto-Updated)

### ✅ Common Check Failures & Fixes

**Pattern**: Linting errors
**Quick fix**: Run `npm run lint:fix` or `black .` before committing

**Pattern**: Test failures
**Quick fix**: Run tests locally, check for environment issues

**Pattern**: Build failures
**Quick fix**: Check for missing dependencies, run `npm install`

**Results**: Faster resolution, fewer retry cycles

---

## Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Avg time to fix checks | <30 min | Not tracked | - |
| Check failure recurrence | <10% | Not tracked | - |
| First-time pass rate | ≥85% | Not tracked | - |

**Updated**: Not yet tracked
