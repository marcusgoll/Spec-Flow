---
name: planning-phase
description: "Capture lessons from /plan phase. Auto-triggers when: starting /plan, detecting code duplication opportunities, missing reuse patterns. Updates when: duplicate code written, failed to identify reusable patterns, research depth insufficient."
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Planning Phase: Lessons Learned

**Capability**: Learn from plan generation to maximize code reuse, identify patterns, and ensure research completeness before implementation.

**When I trigger**:
- `/plan` starts → Load lessons to guide research and reuse detection
- Plan complete → Detect if duplication opportunities missed, insufficient research
- Error: Duplicate code implemented → Capture pattern for future prevention

**Supporting files**:
- [reference.md](reference.md) - Reuse detection strategies, research depth matrix, design pattern catalog
- [examples.md](examples.md) - Good plans (high reuse) vs bad plans (reinventing wheels)
- [scripts/verify-reuse.sh](scripts/verify-reuse.sh) - Script to detect reusable code patterns

---

## Common Pitfalls (Auto-Updated)

### 🚫 Missing Code Reuse Opportunities

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: High (duplicate code, technical debt)

**Detection**:
```bash
# After planning, check for similar patterns in codebase
grep -r "class.*Model" api/app/models/*.py | wc -l
# If >5 models exist, verify plan mentions reusing base model patterns
```

**Prevention**:
1. Search codebase for similar features before designing
2. Identify base classes, utilities, patterns to reuse
3. Document reuse strategy in plan.md

---

### 🚫 Insufficient Research Depth

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Medium (implementation surprises, rework)

**Detection**:
```bash
# Count research tools used in plan generation
RESEARCH_TOOLS=$(grep -c "Grep\|Glob\|Read" plan-generation.log)
if [ $RESEARCH_TOOLS -lt 5 ]; then
  echo "⚠️  Research may be insufficient: $RESEARCH_TOOLS tools used (target: 5+)"
fi
```

**Prevention**:
1. For complex features: 8-12 research tools
2. For standard features: 5-8 tools
3. For simple features: 3-5 tools

---

## Successful Patterns (Auto-Updated)

### ✅ Reuse Strategy Documentation

**Success rate**: Not yet tracked
**Approach**:
```markdown
## Reuse Strategy

**Existing patterns to leverage**:
- BaseModel class (api/app/models/base.py) - timestamps, soft delete
- StandardController (api/app/controllers/base.py) - CRUD operations
- ValidationMixin (api/app/utils/validation.py) - input validation

**New patterns to create**:
- StudentProgressCalculator - reusable across dashboard + reports
```

**Results**: Reduces implementation time, maintains consistency

---

## Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Code reuse rate | ≥60% | Not tracked | - |
| Research depth | 5-12 tools | Not tracked | - |
| Plan completeness | ≥90% | Not tracked | - |

**Updated**: Not yet tracked
