# Visual References for [Feature Name]

## Overview
[1-paragraph summary: sites analyzed, patterns discovered, key insights]

---

## Reference Sites Analyzed

### [Site Name] - [Component/Feature]
**URL**: [live link]
**Status**: ✅ Analyzed via mcp__chrome-devtools on [date]

**Layout**:
- Header: [height]px, [describe layout]
- Navigation: [structure, placement, sticky/fixed]
- Content: [max-width, padding, grid/flex]
- Spacing: [specific measurements]

**Colors**:
- Primary: [hex] - [usage]
- Secondary: [hex] - [usage]
- Background: [hex] - [light/dark]
- Text: [hex] - [primary, secondary, disabled]
- Accents: [hex] - [success, error, warning]

**Typography**:
- Headings: [font-family] - [H1: XXpx, H2: XXpx, H3: XXpx]
- Body: [font-family] - [base: XXpx, line-height]
- Weight: [regular: 400, medium: 500, bold: 700]

**UI Components**:
- **Buttons**: [height]px, [padding], [border-radius], [states: hover, focus, active, disabled]
- **Inputs**: [height]px, [padding], [border, focus states], [label position]
- **Cards**: [border-radius]px, [shadow], [padding]

**UX Patterns**:
- **[Pattern Name]**: [description, why it works, when to use]

**Interaction States**:
- Loading: [spinner, skeleton, progress]
- Empty: [messaging, illustrations, CTAs]
- Error: [inline, toasts, color coding]
- Success: [confirmations, animations]

**Responsive**:
- Desktop (>1024px): [changes]
- Tablet (768-1024px): [changes]
- Mobile (<768px): [changes, hamburger, stacked]

**Accessibility**:
- Focus: [visible, [X]px outline, contrast]
- Color contrast: [ratios, WCAG compliance]
- Keyboard: [tab order, shortcuts]
- ARIA: [labels, roles, descriptions]

**Key Insights**:
- [Specific observation with measurement or behavior]
- [Specific observation with measurement or behavior]

---

## Design Principles Extracted

### [Principle Name] - [Brief tagline]
**Description**: [What it is, why it matters, evidence]

**Example from research**:
- [Site]: [specific instance]
- [Site]: [specific instance]

**Apply to CFIPros**:
- [Specific recommendation]
- [Component where applies]

**Don't**:
- [Anti-pattern to avoid]

---

## Implementation Recommendations

### DO
- [ ] [Specific recommendation #1]
- [ ] [Specific recommendation #2]
- [ ] [Specific recommendation #3]

### DON'T
- [ ] [Anti-pattern #1 - why avoid]
- [ ] [Anti-pattern #2 - why avoid]

### CONSIDER
- [ ] [Optional enhancement #1]
- [ ] [Optional enhancement #2]

---

## Component Specifications

### [Component Name - e.g., Auth Button]
**Ref**: [Which site(s)]

**Measurements**:
- Width: [auto / XXXpx / XX%]
- Height: [XX]px
- Padding: [XX]px horizontal, [XX]px vertical
- Border-radius: [XX]px
- Font-size: [XX]px
- Font-weight: [XXX]

**Colors**:
- Default: [background, text, border]
- Hover/Active/Disabled: [state changes]

**Behavior**:
- [Click interaction, loading, success/error states]

---

## Accessibility Checklist

- [ ] Visible focus indicators
- [ ] Color contrast meets WCAG 2.1 AA (4.5:1 normal, 3:1 large text)
- [ ] Error states use icon + text, not color alone
- [ ] Form labels always visible (not placeholder-only)
- [ ] Touch targets ≥44x44px for mobile
- [ ] Keyboard navigation follows logical tab order
- [ ] Motion can be disabled (prefers-reduced-motion)
- [ ] Images have alt text

---

## Mobile-First Considerations

**Observed patterns**:
- [Pattern 1: description]
- [Pattern 2: description]

**Breakpoints**:
- Mobile: [XXX]px and below
- Tablet: [XXX]px to [XXX]px
- Desktop: [XXX]px and above

**CFIPros priorities**:
1. [Priority #1 - e.g., "Auth flow perfect on mobile"]
2. [Priority #2]
3. [Priority #3]

---

## Resources

**Reference Sites**:
1. [Site name]: [URL]
2. [Site name]: [URL]

**Tools Used**:
- mcp__chrome-devtools for snapshots
- Browser DevTools for measurements

---

**Last Updated**: [ISO timestamp]
**Analyzed By**: Claude Code via mcp__chrome-devtools
