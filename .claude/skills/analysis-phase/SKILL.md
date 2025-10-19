---
name: analysis-phase
description: "Capture lessons from /analyze phase. Auto-triggers when: starting /analyze, checking cross-artifact consistency, detecting breaking changes. Updates when: inconsistencies found, missing impact analysis, incomplete change detection."
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Analysis Phase: Lessons Learned

**Capability**: Learn from analysis execution to catch inconsistencies, assess impacts, and validate readiness for implementation.

**When I trigger**:
- `/analyze` starts → Load lessons to guide consistency checks and impact assessment
- Analysis complete → Detect if inconsistencies missed, impacts underestimated
- Error: Breaking change not caught → Capture for detection improvement

**Supporting files**:
- [reference.md](reference.md) - Consistency check matrix, impact assessment rubric, breaking change detection
- [examples.md](examples.md) - Good analysis (catches issues early) vs missed issues (caught in implementation)

---

## Common Pitfalls (Auto-Updated)

### 🚫 Spec-Plan-Tasks Inconsistency

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: High (implementation confusion, rework)

**Detection**:
```bash
# Check if spec requirements match plan design
SPEC_FEATURES=$(grep "^- " specs/$SLUG/spec.md | wc -l)
PLAN_COMPONENTS=$(grep "^### Component" specs/$SLUG/plan.md | wc -l)
if [ $((SPEC_FEATURES - PLAN_COMPONENTS)) -gt 2 ]; then
  echo "⚠️  Spec-Plan mismatch: $SPEC_FEATURES requirements, $PLAN_COMPONENTS components"
fi
```

**Prevention**:
1. Verify each spec requirement has corresponding plan component
2. Check each plan component has matching tasks
3. Validate acceptance criteria align with spec success criteria

---

### 🚫 Undetected Breaking Changes

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Critical (production issues, rollback risk)

**Detection**:
```bash
# Check for API signature changes
git diff main specs/$SLUG/plan.md | grep -E "(endpoint|schema|response)" | while read -r line; do
  echo "⚠️  Potential breaking change: $line"
done
```

**Prevention**:
1. Compare API contracts before/after
2. Check database schema migrations
3. Validate backward compatibility

---

## Successful Patterns (Auto-Updated)

### ✅ Consistency Matrix

**Approach**:
```markdown
## Cross-Artifact Validation

| Requirement | Spec ✓ | Plan ✓ | Tasks ✓ | Status |
|-------------|--------|--------|---------|--------|
| Dashboard displays completion rate | ✓ | ✓ | ✓ | Consistent |
| Teacher access control (assigned only) | ✓ | ✓ | ✓ | Consistent |
| Export to CSV | ✓ | ✗ | ✗ | Missing from plan/tasks |
```

**Results**: Catches missing requirements before implementation

---

## Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Inconsistencies detected | Track all | Not tracked | - |
| Breaking changes caught | 100% | Not tracked | - |
| Analysis false positives | <10% | Not tracked | - |

**Updated**: Not yet tracked
