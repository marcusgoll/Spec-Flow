---
name: debug-phase
description: "Capture lessons from /debug phase. Auto-triggers when: starting /debug, investigating errors, updating error-log.md. Updates when: recurring error patterns, insufficient error context, missing root cause analysis."
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Debug Phase: Lessons Learned

**Capability**: Learn from debugging sessions to identify error patterns, improve error tracking, and prevent recurrence.

**When I trigger**:
- `/debug` starts → Load lessons to guide root cause analysis and error classification
- Debug complete → Detect if root cause unclear, insufficient logging, pattern not recognized
- Error: Same error recurs → Capture for pattern detection

**Supporting files**:
- [reference.md](reference.md) - Error classification matrix, debugging workflow, logging best practices
- [examples.md](examples.md) - Good debugging (systematic, documented) vs bad (trial-and-error)
- [scripts/error-classifier.sh](scripts/error-classifier.sh) - Classifies errors by type and severity

---

## Common Pitfalls (Auto-Updated)

### 🚫 Recurring Errors Not Recognized

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: High (wasted debugging time, user frustration)

**Detection**:
```bash
# Check error-log.md for duplicate error messages
ERROR_MSG="Connection timeout"
COUNT=$(grep -c "$ERROR_MSG" error-log.md)
if [ $COUNT -gt 2 ]; then
  echo "⚠️  Recurring error: $ERROR_MSG (seen $COUNT times)"
fi
```

**Prevention**:
1. Before debugging, search error-log.md for similar errors
2. If recurring: implement permanent fix, not workaround
3. Document root cause in error-log.md

---

### 🚫 Insufficient Error Context

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Medium (hard to reproduce, longer debug time)

**Detection**:
```bash
# Check if error entry has required fields
grep -A 10 "## Error" error-log.md | grep -E "(Date|Component|Error Message|Steps to Reproduce)"
# All 4 fields should be present
```

**Prevention**:
1. Log error with: timestamp, component, message, stack trace, user context
2. Include steps to reproduce
3. Add relevant code snippets

---

## Successful Patterns (Auto-Updated)

### ✅ Systematic Debugging Workflow

**Approach**:
1. Search error-log.md for similar errors
2. Reproduce error consistently
3. Isolate root cause (binary search, logging)
4. Implement fix + test
5. Document in error-log.md with ERR-XXXX ID

**Results**: Faster debugging, knowledge accumulation

---

## Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Avg debug time | <2 hours | Not tracked | - |
| Error recurrence rate | <10% | Not tracked | - |
| Errors documented | 100% | Not tracked | - |

**Updated**: Not yet tracked
