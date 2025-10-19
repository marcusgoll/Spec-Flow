---
name: roadmap-integration
description: "Capture lessons from /roadmap usage (brainstorm, prioritize, track features). Auto-triggers when: using /roadmap, linking specs to roadmap, moving features between states. Updates when: roadmap sync issues, missing links, state transitions unclear."
allowed-tools: Read, Write, Edit, Grep, Bash
---

# Roadmap Integration: Lessons Learned

**Capability**: Learn from roadmap usage to maintain clean feature tracking, proper state transitions, and spec linkage.

**When I trigger**:
- `/roadmap` used → Load lessons to guide roadmap updates
- Feature state changed → Detect if links missing, transition invalid
- Error: Roadmap out of sync with specs → Capture sync pattern

**Supporting files**:
- [reference.md](reference.md) - Roadmap structure, state transitions, linking conventions
- [examples.md](examples.md) - Well-maintained roadmap vs stale roadmap

---

## Common Pitfalls (Auto-Updated)

### 🚫 Roadmap Out of Sync

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Medium (lost visibility, planning confusion)

**Detection**:
```bash
# Check if shipped features still in "In Progress"
grep -A 5 "## In Progress" .spec-flow/memory/roadmap.md | while read -r line; do
  SLUG=$(echo "$line" | grep "^### " | sed 's/### //')
  [ -f "specs/$SLUG/*-ship-report.md" ] && echo "⚠️  Shipped feature still in progress: $SLUG"
done
```

**Prevention**:
1. Update roadmap when feature state changes
2. Move to "Shipped" when production deployed
3. Add links to spec and ship report

---

### 🚫 Missing Spec Links

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Low (navigation friction)

**Prevention**:
1. Add spec link when moving to "In Progress"
2. Add ship report link when moving to "Shipped"
3. Use consistent linking format

---

## Successful Patterns (Auto-Updated)

### ✅ Roadmap State Machine

**States**:
1. **Backlog** → Feature brainstormed, not prioritized
2. **Prioritized** → Moved up, ready for spec work
3. **In Progress** → Spec exists, work started
4. **Shipped** → Production deployed

**Transitions**:
- Backlog → Prioritized: User prioritizes
- Prioritized → In Progress: `/specify` creates spec
- In Progress → Shipped: `/phase-2-ship` completes
- Any → Backlog: Deprioritized

**Results**: Clear feature lifecycle visibility

---

## Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Roadmap sync rate | ≥95% | Not tracked | - |
| Features with links | 100% | Not tracked | - |

**Updated**: Not yet tracked
