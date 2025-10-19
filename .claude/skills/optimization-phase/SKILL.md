---
name: optimization-phase
description: "Capture lessons from /optimize phase. Auto-triggers when: starting /optimize, running performance checks, code review, accessibility audit. Updates when: performance targets missed, accessibility failures, code quality issues."
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Optimization Phase: Lessons Learned

> **Dynamic data**: Frequencies, metrics, and usage statistics are tracked in [learnings.md](learnings.md) (preserved across npm updates).

**Capability**: Learn from optimization checks to ensure performance, accessibility, security, and code quality standards are met.

**When I trigger**:
- `/optimize` starts → Load lessons to guide performance benchmarks and quality checks
- Optimization complete → Detect if targets missed, quality gates failed
- Error: Performance regression or accessibility failure → Capture for prevention

**Supporting files**:
- [reference.md](reference.md) - Performance benchmarks, accessibility checklist, security review guidelines
- [examples.md](examples.md) - Good optimizations (measurable improvements) vs premature optimization

---

## Common Pitfalls (Auto-Updated)

### 🚫 Performance Target Missed

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: High (poor UX, user churn)

**Detection**:
```bash
# Run performance benchmark
RESPONSE_TIME=$(curl -w "%{time_total}" -s -o /dev/null http://localhost:3000/api/endpoint)
if (( $(echo "$RESPONSE_TIME > 0.5" | bc -l) )); then
  echo "⚠️  Performance target missed: ${RESPONSE_TIME}s (target: <0.5s)"
fi
```

**Prevention**:
1. Run benchmarks before marking optimization complete
2. Profile slow queries/functions
3. Add indexes, caching, pagination as needed

---

### 🚫 Accessibility Failures

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Medium (excludes users, legal risk)

**Detection**:
```bash
# Run Lighthouse accessibility audit
lighthouse http://localhost:3000 --only-categories=accessibility --output=json | jq '.categories.accessibility.score'
# Target: ≥0.95 (95%)
```

**Prevention**:
1. Add ARIA labels to interactive elements
2. Ensure keyboard navigation works
3. Test with screen reader

---

## Successful Patterns (Auto-Updated)

### ✅ Optimization Checklist

**Approach**:
- [ ] Performance: API <500ms, FCP <1.5s
- [ ] Accessibility: Lighthouse ≥95, keyboard nav works
- [ ] Security: No secrets in code, SQL injection prevented
- [ ] Code quality: No duplication, tests passing

**Results**: Systematic validation, no regressions

---

## Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| API response time | <500ms | Not tracked | - |
| Lighthouse score | ≥95 | Not tracked | - |
| Code quality score | ≥85 | Not tracked | - |

**Updated**: Not yet tracked
