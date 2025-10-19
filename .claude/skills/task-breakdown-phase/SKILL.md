---
name: task-breakdown-phase
description: "Capture lessons from /tasks phase. Auto-triggers when: starting /tasks, generating task breakdown, validating acceptance criteria. Updates when: tasks too large (>1 day), missing acceptance criteria, unclear task descriptions."
allowed-tools: Read, Write, Edit, Grep, Bash
---

# Task Breakdown Phase: Lessons Learned

> **Dynamic data**: Frequencies, metrics, and usage statistics are tracked in [learnings.md](learnings.md) (preserved across npm updates).

**Capability**: Learn from task generation to ensure right-sized tasks, clear acceptance criteria, and proper sequencing.

**When I trigger**:
- `/tasks` starts → Load lessons to guide task sizing and criteria definition
- Tasks complete → Detect if tasks too large, missing criteria, poor sequencing
- Error: Task took >2 days → Capture for decomposition guidance

**Supporting files**:
- [reference.md](reference.md) - Task sizing guidelines, acceptance criteria templates, sequencing patterns
- [examples.md](examples.md) - Good tasks (0.5-1 day, clear AC) vs bad tasks (>2 days, vague AC)

---

## Common Pitfalls (Auto-Updated)

### 🚫 Tasks Too Large (>1 Day)

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: High (blocks progress, unclear completion)

**Detection**:
```bash
# After task generation, flag large tasks
grep -E "complexity: (high|very high)" specs/$SLUG/tasks.md | while read -r line; do
  echo "⚠️  Large task detected: $line"
  echo "Consider: Break into 2-3 smaller subtasks"
done
```

**Prevention**:
1. Target: 0.5-1 day per task (4-8 hours)
2. If task >1 day: decompose into subtasks
3. Use task templates for consistent sizing

---

### 🚫 Missing or Vague Acceptance Criteria

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Medium (unclear when done, rework risk)

**Detection**:
```bash
# After task generation, check AC quality
grep -A 5 "### Acceptance Criteria" specs/$SLUG/tasks.md | grep -c "✓"
# Should have 2-4 checkboxes per task
```

**Prevention**:
1. Each task has 2-4 testable acceptance criteria
2. Use "Given-When-Then" format for clarity
3. Include success metrics where applicable

---

## Successful Patterns (Auto-Updated)

### ✅ Right-Sized Task Example

**Approach**:
```markdown
### Task 15: Create Student Progress API Endpoint

**Complexity**: Medium (6-8 hours)

**Implementation**:
1. Create GET /api/v1/students/{id}/progress endpoint
2. Join students + lessons + time_logs tables
3. Calculate completion rate + time spent
4. Return JSON with schema validation

**Acceptance Criteria**:
- ✓ Endpoint returns 200 with valid student ID
- ✓ Response includes: completion_rate, time_spent, last_activity
- ✓ Returns 404 for invalid student ID
- ✓ Response time <500ms for 500 lessons (95th percentile)
```

**Results**: Clear scope, testable, completable in one session

---

## Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Avg task size | 0.5-1 day | Not tracked | - |
| Tasks with clear AC | 100% | Not tracked | - |
| Task rework rate | <5% | Not tracked | - |

**Updated**: Not yet tracked
