---
name: implementation-phase
description: "Capture lessons from /implement phase. Auto-triggers when: starting /implement, executing tasks, running tests. Updates when: test failures, task blocked, TDD not followed, duplicate code written."
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Implementation Phase: Lessons Learned

**Capability**: Learn from implementation execution to improve test-first development, catch duplications, and ensure task completion quality.

**When I trigger**:
- `/implement` starts → Load lessons to guide TDD and anti-duplication checks
- Implementation complete → Detect if tests missing, duplication introduced, tasks incomplete
- Error: Test failure or blocked task → Capture root cause

**Supporting files**:
- [reference.md](reference.md) - TDD workflow, anti-duplication checklist, common blockers
- [examples.md](examples.md) - Good implementations (tests first) vs bad (tests after)
- [scripts/batch-validator.sh](scripts/batch-validator.sh) - Validates multiple tasks at once

---

## Common Pitfalls (Auto-Updated)

### 🚫 Implementation Without Tests

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: High (unverified code, regression risk)

**Detection**:
```bash
# Check if test files created for implementation files
find specs/$SLUG -name "*.py" | while read -r impl; do
  test_file=$(echo "$impl" | sed 's/app/tests/' | sed 's/.py/_test.py/')
  [ ! -f "$test_file" ] && echo "⚠️  Missing tests: $impl"
done
```

**Prevention**:
1. Write test first (red → green → refactor)
2. Verify test file exists before marking task complete
3. Run tests before committing

---

### 🚫 Duplicate Code Written

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Medium (technical debt, maintenance burden)

**Detection**:
```bash
# Check for similar code patterns
grep -r "def calculate_completion" specs/$SLUG | wc -l
# If >1, may indicate duplication
```

**Prevention**:
1. Search for existing similar functions before writing new code
2. Extract common logic to utility functions
3. Review plan.md reuse strategy

---

## Successful Patterns (Auto-Updated)

### ✅ TDD Workflow

**Approach**:
1. Write failing test for acceptance criteria
2. Implement minimal code to pass test
3. Refactor while keeping tests green
4. Mark task complete only when tests pass

**Results**: Fewer bugs, higher confidence, better design

---

## Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Test coverage | ≥80% | Not tracked | - |
| Tasks with tests | 100% | Not tracked | - |
| Code duplication | <5% | Not tracked | - |

**Updated**: Not yet tracked
