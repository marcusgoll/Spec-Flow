# Mockup Approval Checklist: {FEATURE_NAME}

**Mockup Location**: `specs/{NNN-slug}/mockups/`

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

**Approved By**: <!-- User name -->
**Approved At**: <!-- Timestamp -->
**Mockup Version**: <!-- Git commit hash or iteration number -->
**Design Iterations**: <!-- Number of revisions before approval -->

---

## Next Steps (After Approval)

1. Agent will convert approved HTML mockup to Next.js format
2. Agent will map CSS variables to Tailwind utilities (or keep as CSS modules)
3. Agent will wire mock JSON data to API endpoints (from contracts/*.yaml)
4. Agent will extract shared components to components/ui/ or components/shared/
5. Implementation will preserve all accessibility features from mockup

**Reference Mockup Path**: `specs/{NNN-slug}/mockups/{screen-name}.html`
