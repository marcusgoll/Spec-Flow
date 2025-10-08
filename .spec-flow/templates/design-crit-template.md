# Design Critique: [Feature Name]

**Feature**: `[feature-slug]`
**Phase**: Design Variations → Functional
**Reviewed**: [DATE]
**Reviewer**: [NAME]

---

## Overview

After `/design-variations` generated 3-5 variants per screen, this critique documents:
- Which variants to **KEEP** (merge into main)
- Which elements to **CHANGE** (modify before merging)
- Which to **KILL** (discard entirely)

**Next step**: `/design-functional` will merge selected pieces → `/mock/[feature]/[screen]/main`

---

## Screen: [screen-id]

**Variants reviewed**: v1, v2, v3, v4, v5
**URLs**: `/apps/web/mock/[feature]/[screen]/v1...v5`
**States tested**: `?state=default|loading|empty|error`

### Decision Matrix

| Variant | Verdict | Rationale (1 line max) |
|---------|---------|------------------------|
| v1 | KILL | Too cluttered; cognitive load too high |
| v2 | KEEP | Clean layout, clear CTA, good state handling |
| v3 | CHANGE | Good pattern but copy too verbose |
| v4 | KILL | Interaction pattern confusing (modal on modal) |
| v5 | CHANGE | Love the inline preview, hate the button placement |

### Selected Components (for main)

From variants above, merge these elements:

- **Layout**: v2 (stacked, mobile-first)
- **Primary CTA**: v2 (solid button, 52px height)
- **Inline Preview**: v5 (card with file info)
- **Error Handling**: v2 (inline alert, not toast)
- **Loading State**: v3 (skeleton, not spinner)

### Changes Required

Before merging to `main`:

1. **v3 copy**: Shorten heading from "Upload Your AKTR Report to Get Started" → "Upload AKTR Report"
2. **v5 button**: Move "Extract" button inside preview card (currently below)
3. **v2 spacing**: Reduce vertical gap from 32px → 24px (too much white space)

---

## Screen: [another-screen-id]

*(Repeat above structure for each screen)*

### Decision Matrix

| Variant | Verdict | Rationale |
|---------|---------|-----------|
| ... | ... | ... |

### Selected Components

...

### Changes Required

...

---

## Example: AKTR Upload Redesign

### Screen: upload

**Variants reviewed**: v1, v2, v3, v4, v5
**URLs**: `/apps/web/mock/aktr-upload-inline/upload/v1...v5`
**States tested**: `?state=default|uploading|preview|extracting|error`

#### Decision Matrix

| Variant | Verdict | Rationale |
|---------|---------|-----------|
| v1 | KILL | Two-step flow (upload → redirect) defeats inline hypothesis |
| v2 | KEEP | Inline preview nails the HEART hypothesis (faster time-to-insight) |
| v3 | CHANGE | Drag-drop visual is great, but states are confusing |
| v4 | KILL | Progress bar placement obscures file name |
| v5 | CHANGE | Love the compact preview card, but button hierarchy wrong |

#### Selected Components (for main)

- **Layout**: v2 (inline preview, no redirect)
- **Drag-Drop Zone**: v3 (visual cues for drag target)
- **Preview Card**: v5 (compact file info + thumbnail)
- **Primary CTA**: v2 ("Extract ACS Codes" inside preview)
- **Progress**: v2 (linear bar above preview, not inside)
- **Error Alert**: v2 (inline below upload, not modal)

#### Changes Required

1. **v3 states**: Merge `uploading` → `preview` transition (currently jumps)
2. **v5 button**: Change "Start Extraction" → "Extract ACS Codes" (clearer)
3. **v2 progress**: Add percentage text (not just visual bar)
4. **All variants**: Ensure error focus returns to "Try Again" button (a11y)

---

## Global Decisions (apply to all screens)

### Keep
- Grayscale palette (will apply brand tokens in Phase 3)
- 8px spacing grid
- System components only (no custom widgets)
- Inline errors (not toasts/modals)

### Change
- **Copy tone**: Less formal ("Drop your file" not "Please upload your file")
- **Button hierarchy**: Only ONE primary CTA per screen (current: 2 in v1)
- **Loading states**: Always show progress % (not just spinner)

### Kill
- Any variant with >2 clicks to complete primary action
- Modals for errors (use inline alerts)
- Placeholder-only labels (a11y violation)
- Custom components not in ui-inventory.md

---

## Jobs Principles Evaluation

Apply Steve Jobs design criteria to each variant:

### Variant Review Matrix

| Variant | One Action<br>(≤5 words) | Zero Instructions<br>(obvious?) | Details<br>(8px grid) | Smooth<br>(200-300ms) | Say No<br>(ONE job) | Question<br>(novel?) | Verdict |
|---------|--------------------------|----------------------------------|----------------------|----------------------|---------------------|---------------------|---------|
| v1 | ❌ "Upload, configure, extract" | ❌ Needs tooltip | ⚠️ Mixed | ✅ 250ms | ❌ Too many CTAs | ❌ Conventional | KILL |
| v2 | ✅ "Extract ACS codes" | ✅ Self-evident | ✅ 8/16/24px | ✅ 250ms | ✅ One CTA | ✅ Inline preview | KEEP |
| v3 | ✅ "Extract codes" | ⚠️ States unclear | ✅ Grid OK | ⚠️ 400ms | ✅ Focused | ⚠️ Partial | CHANGE |
| v4 | ❌ "Upload and process" | ❌ Modal confusion | ❌ Random | ❌ Instant | ❌ Multiple | ❌ Copy-paste | KILL |
| v5 | ✅ "Extract codes" | ✅ Obvious | ⚠️ 13px gaps | ✅ 250ms | ✅ One CTA | ✅ Progressive | CHANGE |

### Decision Tree Applied

**Auto-KILL criteria** (any variant meeting these):
- [ ] Primary action >5 words OR unclear
- [ ] Requires >2 clicks to complete
- [ ] Needs tooltips/instructions
- [ ] Multiple competing CTAs
- [ ] Custom component when system exists
- [ ] Copies competitor without innovation

**Auto-CHANGE criteria** (needs refinement):
- [ ] Spacing not 8px grid
- [ ] Transitions >300ms or <200ms
- [ ] Copy >2 lines per section
- [ ] States incomplete (missing error/empty)
- [ ] Hierarchy unclear (secondary looks primary)

**KEEP criteria** (high bar, must meet ALL):
- [ ] Primary action ≤5 words, immediately clear
- [ ] ≤2 clicks to complete
- [ ] Zero tooltips needed (self-evident)
- [ ] 8px grid spacing
- [ ] 200-300ms transitions
- [ ] One primary CTA per screen
- [ ] Novel approach (better than control)

### Verification Commands

Run these before submitting critique:

```bash
# Spacing audit (8px grid)
bash \spec-flow/scripts/verify-design-principles.sh

# Manual time test (5 users)
# - Invite 5 CFI students
# - No instructions given
# - Time: ALL <10s to complete primary action
# - Questions: 0 asked
# - Record results in NOTES.md
```

---

## Success Criteria Check

Before moving to `/design-functional`, confirm:

- [ ] One clear variant selected per screen (or hybrid clearly defined)
- [ ] All selected components exist in `design/systems/ui-inventory.md`
- [ ] Changes are specific and actionable (not vague "make it better")
- [ ] States are covered: default, loading, empty, error
- [ ] A11y issues noted and assigned to changes
- [ ] HEART hypothesis still intact (design serves the metric goal)

---

## Next Steps

**For Claude Code**:
```bash
/design-functional [feature-slug]
```

This will:
1. Read this crit.md
2. Merge selected components → `/mock/[feature]/[screen]/main`
3. Apply changes listed above
4. Add keyboard navigation + aria labels
5. Create Playwright tests (visual snapshots + a11y)
6. Define analytics event names (from HEART signals)

**Human checkpoint**: Review `/mock/[feature]/[screen]/main` before Phase 3 (polish).

---

## Notes

- Keep critique **concise** (1-line rationales, bullet changes)
- Focus on **user outcomes** (not aesthetics alone)
- Reference **HEART metrics** (does this design move the needle?)
- Stay **system-first** (reuse > customize)

---

**Template Version**: 1.0
**Last Updated**: [ISO timestamp]

