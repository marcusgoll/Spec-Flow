---
name: finalize-phase
description: "Capture lessons from /finalize phase (workflow completion, artifact archival). Auto-triggers when: completing feature workflow, updating roadmap, archiving artifacts. Updates when: incomplete documentation, roadmap not updated, artifacts not archived."
allowed-tools: Read, Write, Edit, Grep, Bash
---

# Finalize Phase: Lessons Learned

**Capability**: Learn from workflow finalization to ensure complete documentation, roadmap updates, and proper archival.

**When I trigger**:
- `/finalize` starts → Load lessons to guide completion checklist
- Finalize complete → Detect if steps skipped, documentation incomplete
- Error: Missing artifacts or roadmap updates → Capture

**Supporting files**:
- [reference.md](reference.md) - Finalization checklist, archival procedures, documentation standards
- [examples.md](examples.md) - Complete finalization vs rushed cleanup

---

## Common Pitfalls (Auto-Updated)

### 🚫 Roadmap Not Updated

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Medium (roadmap stale, lost tracking)

**Prevention**:
1. Move feature from "In Progress" to "Shipped" in roadmap
2. Add links to ship report and production URL
3. Update feature status with completion date

---

### 🚫 Incomplete Documentation

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Medium (knowledge loss, onboarding friction)

**Prevention**:
1. Verify release notes created
2. Update README if user-facing feature
3. Archive all artifacts (spec, plan, tasks, reports)

---

## Successful Patterns (Auto-Updated)

### ✅ Complete Finalization Checklist

**Approach**:
- [ ] Roadmap updated (moved to "Shipped")
- [ ] Release notes created
- [ ] Ship report archived
- [ ] Production URL documented
- [ ] README updated (if applicable)
- [ ] Branch deleted (if no longer needed)

**Results**: Clean workflow completion, knowledge preserved

---

## Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Complete finalizations | 100% | Not tracked | - |
| Documentation completeness | 100% | Not tracked | - |

**Updated**: Not yet tracked
