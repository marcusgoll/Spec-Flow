# Mockup Approval Checklist: {FEATURE_NAME}

**Feature Slug**: {NNN-slug}
**Mockup Location**: `specs/{NNN-slug}/mockups/`
**Mockup Type**: {single-screen | multi-screen}
**Screen Count**: {N screens}
**Review Date**: {YYYY-MM-DD}
**Reviewer**: {Name/Email}

---

## Review Instructions

### How to Review Mockups

**For multi-screen features** (≥3 screens):

1. Open navigation hub: `open specs/{NNN-slug}/mockups/index.html`
2. Use keyboard shortcuts:
   - **1-9 keys**: Navigate to screen by number
   - **H key**: Return to hub (index.html)
   - **S key**: Cycle through states (Success → Loading → Error → Empty)
   - **Esc**: Close modals/dialogs

**For single-screen features**:

1. Open mockup: `open specs/{NNN-slug}/mockups/{screen-name}.html`
2. Press **S key** to cycle through states

---

## Multi-Screen Flow Review

**Skip this section for single-screen features**

### Navigation Hub (index.html)

- [ ] Hub page loads without errors
- [ ] All screens listed with descriptions
- [ ] User flow diagram displayed and accurate
- [ ] Keyboard shortcuts documented (1-9, H, S)
- [ ] Screen cards clickable and keyboard-accessible
- [ ] Number keys (1-9) navigate to correct screens
- [ ] Screen count matches spec.md user stories

**Notes**:

```
[Add notes about hub page issues or improvements needed]
```

### Screen Navigation Wiring

- [ ] All screens link back to hub via breadcrumb
- [ ] Interactive elements (buttons, links) navigate correctly
- [ ] Multi-step flows match user journey (spec.md)
- [ ] H key returns to hub from any screen
- [ ] No broken links or 404 errors
- [ ] Forward navigation matches flow diagram

**Notes**:

```
[Add notes about navigation issues]
```

---

## Visual Review

- [ ] Layout matches design intent
- [ ] Spacing follows 8pt grid (all values divisible by 4/8)
- [ ] Typography is readable (line length 50-75 chars, max-w-[600px] to max-w-[700px])
- [ ] Colors use tokens.css CSS variables (no hardcoded hex/rgb/hsl)
- [ ] Components from ui-inventory.md are reused where possible
- [ ] Passes squint test (CTAs and headlines stand out when blurred)

## Interaction Review

- [ ] Mock data demonstrates dynamic content realistically
- [ ] Loading states are shown (skeleton screens, spinners)
- [ ] Error states are shown (validation errors, API failures)
- [ ] Empty states are shown (no data scenarios)
- [ ] Success states are shown (confirmations, completions)

## Accessibility (WCAG 2.1 AA)

- [ ] Color contrast ≥4.5:1 for normal text (AA)
- [ ] Color contrast ≥3:1 for large text (AA)
- [ ] Interactive elements ≥24x24px touch targets
- [ ] Keyboard navigation works (Tab, Enter, Escape)
- [ ] Screen reader labels present (aria-label, aria-describedby)
- [ ] Focus indicators visible (2px outline, 3:1 contrast per WCAG 2.2)

## Tokens.css Compliance

- [ ] Links to `design/systems/tokens.css` (relative path from mockup location)
- [ ] Uses CSS variables from tokens.css (not hardcoded values)
- [ ] Colors: `var(--brand-*)`, `var(--neutral-*)`, `var(--semantic-*)`
- [ ] Spacing: `var(--space-1)` through `var(--space-64)` (8pt grid)
- [ ] Typography: `var(--text-*)`, `var(--font-weight-*)`, `var(--line-height-*)`
- [ ] Shadows: `var(--shadow-*)` for elevation
- [ ] Radius: `var(--radius-*)` for rounded corners
- [ ] No arbitrary spacing values (e.g., no `padding: 13px` - use token scale)

## Component Reuse

- [ ] Checked `design/systems/ui-inventory.md` for existing components
- [ ] Reused shadcn/ui primitives where applicable (Button, Card, Sheet, Dialog, Tabs, Input, Select)
- [ ] Reused custom components where applicable (LoadingState, ErrorState, EmptyState)
- [ ] New custom components are justified (no equivalent in inventory)

## Responsiveness

- [ ] Mobile (320px-768px): Layout adapts, text readable, touch targets adequate
- [ ] Tablet (768px-1024px): Layout uses available space effectively
- [ ] Desktop (1024px+): Layout doesn't stretch beyond comfortable reading width

---

## Design Lint Results (Automated Quality Checks)

**Manual review recommended** - Automated design linting will be available in future version.

### Current Manual Checks

**Color Contrast** (use browser DevTools or online checker):

- [ ] All text has ≥4.5:1 contrast ratio (normal text)
- [ ] Large text (≥18pt or ≥14pt bold) has ≥3:1 contrast ratio
- [ ] Focus indicators have ≥4.5:1 contrast ratio

**Touch Target Sizes** (measure with browser DevTools):

- [ ] All interactive elements ≥24x24px (preferred: 44x44px)
- [ ] Buttons, links, form inputs meet minimum size
- [ ] Icon-only buttons are large enough

**Design Token Usage** (inspect HTML source):

- [ ] No hardcoded colors (search for `#`, `rgb(`, `hsl(`)
- [ ] No hardcoded spacing (search for `px` in style attributes)
- [ ] All values use CSS variables from tokens.css

**Component Reuse** (check against ui-inventory.md):

- [ ] Existing components used where applicable
- [ ] New components justified in plan.md Design System Constraints
- [ ] No duplicate implementations of existing components

### Linting Summary

- [ ] ✅ No critical issues (blocking approval)
- [ ] ⚠️ [N] warnings (review and justify)
- [ ] ℹ️ [N] info messages (non-blocking)

**Critical Issues** (must fix before approval):

```
[List any critical issues found during manual review]
Example:
- screen-01-login.html:45 - Color #3b82f6 hardcoded (use var(--color-brand-primary))
- screen-02-dashboard.html:78 - Touch target 18x18px (increase to ≥24x24px)
```

**Warnings** (review and justify):

```
[List warnings found during manual review]
Example:
- screen-01-login.html:23 - Contrast ratio 4.3:1 (slightly below 4.5:1, acceptable for large text)
```

**Component Reuse Rate**: {X}% (target: 85%+)
**Token Compliance**: {X}% (target: 95%+)

---

## Approval Decision

- [ ] **APPROVED** - Ready to convert to Next.js and implement
- [ ] **REQUEST CHANGES** - Specific feedback below

---

## Requested Changes

<!-- If requesting changes, provide specific, actionable feedback: -->

**Visual Issues**:

<!-- e.g., "Increase spacing between cards from var(--space-3) to var(--space-6)" -->

**Interaction Issues**:

<!-- e.g., "Add loading spinner when mock data is 'fetching'" -->

**Accessibility Issues**:

<!-- e.g., "Primary button has 3.8:1 contrast - needs 4.5:1 minimum" -->

**Token Compliance Issues**:

<!-- e.g., "Hardcoded #3B82F6 on line 45 - use var(--brand-primary) instead" -->

---

## Style Guide Update Suggestions

<!-- If user requests changes that require new tokens (e.g., "make primary color more vibrant"), agent will propose tokens.css updates here: -->

**Proposed Token Changes**:

<!-- Agent will populate this section with proposed updates to design/systems/tokens.css -->

**Action Required**:

- [ ] Approve token update (agent will update tokens.css and regenerate mockup)
- [ ] Reject and keep current token

---

## Approval Metadata

**Approved By**: {Name/Email}
**Approved At**: {YYYY-MM-DD HH:MM}
**Mockup Version**: {Git commit hash or iteration number}
**Design Iterations**: {Number of revisions before approval}
**Screens Reviewed**: {N} / {N}
**Component Reuse Rate**: {X}%
**Token Compliance**: {X}%

### Workflow State Update

**After approval, update state.yaml**:

```yaml
# In specs/{NNN-slug}/state.yaml
manual_gates:
  mockup_approval:
    status: approved # or needs_changes
    approved_at: "2025-11-17T14:30:00Z"
    approved_by: "user@example.com"
    screens_reviewed: { N }
    critical_issues: 0
    warnings: { N }
    component_reuse_rate: "{X}%"
    token_compliance: "{X}%"
```

**Then continue feature workflow**:

```bash
/feature continue
# or
/implement
```

---

## Next Steps (After Approval)

1. Agent will convert approved HTML mockup to Next.js format
2. Agent will map CSS variables to Tailwind utilities (or keep as CSS modules)
3. Agent will wire mock JSON data to API endpoints (from contracts/\*.yaml)
4. Agent will extract shared components to components/ui/ or components/shared/
5. Implementation will preserve all accessibility features from mockup

**Reference Mockup Path**: `specs/{NNN-slug}/mockups/{screen-name}.html`

---

## Appendix: Quick Reference

### Keyboard Shortcuts

**Multi-Screen Navigation** (provided by navigation.js):

- **1-9 keys**: Navigate to screen by number
- **H key**: Return to hub (index.html)
- **Esc**: Close modals/dialogs
- **Tab**: Navigate focusable elements
- **Enter/Space**: Activate focused element

**State Switching** (provided by state-switcher.js):

- **S key**: Cycle state (Success → Loading → Error → Empty)
- State persists in sessionStorage during review

### Design Token Quick Reference

See `design/systems/tokens.css` for complete token list.

**Colors**:

- Brand: `--color-brand-primary`, `--color-brand-secondary`
- Semantic: `--color-semantic-error`, `--color-semantic-success`, `--color-semantic-warning`, `--color-semantic-info`
- Text: `--color-text-primary`, `--color-text-secondary`, `--color-text-tertiary`
- Background: `--color-background-page`, `--color-background-surface`, `--color-background-accent`
- Border: `--color-border-default`, `--color-border-subtle`

**Spacing** (8pt grid):

- `--space-1` = 4px, `--space-2` = 8px, `--space-3` = 12px, `--space-4` = 16px
- `--space-6` = 24px, `--space-8` = 32px, `--space-12` = 48px, `--space-16` = 64px

**Typography**:

- `--text-xs` = 12px, `--text-sm` = 14px, `--text-base` = 16px, `--text-lg` = 18px
- `--text-xl` = 20px, `--text-2xl` = 24px, `--text-3xl` = 30px, `--text-4xl` = 36px

**Shadows**:

- `--shadow-sm`, `--shadow-md`, `--shadow-lg`

**Border Radius**:

- `--radius-sm` = 4px, `--radius-md` = 8px, `--radius-lg` = 12px, `--radius-full` = 9999px

**Motion Timing**:

- `--duration-fast` = 150ms, `--duration-normal` = 200ms, `--duration-slow` = 300ms

### WCAG 2.1 AA Checklist

- ✅ Touch targets ≥24x24px (44x44px preferred)
- ✅ Color contrast ≥4.5:1 for normal text
- ✅ Color contrast ≥3:1 for large text (≥18pt or ≥14pt bold)
- ✅ Focus indicators ≥2px outline with ≥4.5:1 contrast
- ✅ Form labels associated with inputs (for/id)
- ✅ ARIA labels on icon-only buttons
- ✅ Semantic HTML (<button>, <nav>, <main>, <form>)
- ✅ Heading hierarchy (h1 → h2 → h3, no skipping)
- ✅ Alt text for images (meaningful), empty alt for decorative
- ✅ Keyboard navigation works for all interactions

---

**Template Version**: 2.0.0
**Last Updated**: 2025-11-17
**Spec-Flow Workflow Kit**
