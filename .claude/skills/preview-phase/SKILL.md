---
name: preview-phase
description: "Capture lessons from /preview phase. Auto-triggers when: starting /preview, validating UI/UX, testing user flows. Updates when: broken user flows, accessibility issues, visual regressions."
allowed-tools: Read, Write, Edit, Grep, Bash
---

# Preview Phase: Lessons Learned

**Capability**: Learn from manual testing and preview validation to catch UX issues before deployment.

**When I trigger**:
- `/preview` starts → Load lessons to guide manual testing checklist
- Preview complete → Detect if user flows broken, visual issues missed
- Error: Issue found in staging that should have been caught in preview → Capture

**Supporting files**:
- [reference.md](reference.md) - Manual testing checklist, user flow validation, visual regression detection
- [examples.md](examples.md) - Thorough preview (catches issues) vs rushed preview (misses issues)

---

## Common Pitfalls (Auto-Updated)

### 🚫 Incomplete User Flow Testing

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: High (broken production UX)

**Prevention**:
1. Test happy path + 2-3 error scenarios
2. Test on different screen sizes (mobile, tablet, desktop)
3. Verify all links and buttons work

---

### 🚫 Accessibility Not Validated

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Medium (excludes users)

**Prevention**:
1. Test keyboard navigation (Tab, Enter, Esc)
2. Test with screen reader (NVDA, VoiceOver)
3. Check color contrast in browser devtools

---

## Successful Patterns (Auto-Updated)

### ✅ Comprehensive Preview Checklist

**Approach**:
- [ ] Happy path: User completes main workflow successfully
- [ ] Error handling: Invalid inputs show clear errors
- [ ] Responsive: Works on mobile + desktop
- [ ] Accessibility: Keyboard nav + screen reader friendly
- [ ] Performance: Page loads <3s, interactions <500ms

**Results**: Catches issues before staging deployment

---

## Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Issues caught in preview | Track all | Not tracked | - |
| Staging bugs from preview | <2 | Not tracked | - |

**Updated**: Not yet tracked
