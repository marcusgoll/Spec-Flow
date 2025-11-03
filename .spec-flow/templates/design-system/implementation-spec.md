# Implementation Specification: [Feature Name]

**Status**: Ready for Implementation
**Phase**: Design → Implementation Handoff
**Generated**: [Date]
**Design Lead**: Claude Code (design-polish phase)
**Implementation Target**: frontend-shipper agent

---

## Overview

This specification documents the final polished design from Phase 3 (design-polish) and provides implementation guidance to ensure 100% fidelity between design artifacts and production code.

**Design Directory**: `design/[feature-slug]/`
**Prototype Location**: `mock/[screen-id]/polished/`
**Token Source**: `design/design-system/tokens.json`
**Component Library**: `design/design-system/ui-inventory.md`

---

## Design Artifacts Reference

### Core Files

- **Polished Prototypes**: `mock/*/polished/*.tsx`
- **Brand Tokens**: `design/design-system/tokens.json`
- **Component Inventory**: `design/design-system/ui-inventory.md`
- **Pattern Library**: `design/design-system/patterns.md`
- **Design Lint Report**: `design/lint-report.md` (100% compliance required)
- **Hierarchy Analysis**: `design/hierarchy-analysis.md`

### Validation Results

**Design Lint Status**: ✅ PASSED (0 critical, 0 errors)
**Token Compliance**: 100% (all hardcoded values eliminated)
**Elevation Scale Compliance**: ✅ z-0 to z-5 used correctly
**Gradient Compliance**: ✅ Subtle, monochromatic, 2-stop max
**Hierarchy Validation**: ✅ 2:1 heading ratios, F-pattern optimized
**WCAG Compliance**: AAA (7:1 contrast minimum)

---

## Screens and Components

### Screen 1: [Screen Name]

**File**: `mock/[screen-id]/polished/[screen-name].tsx`
**Route**: `/[route-path]`
**Layout**: [App layout / Marketing layout / Dashboard layout]
**Viewport Breakpoints**: Mobile (320px), Tablet (768px), Desktop (1024px), Wide (1440px)

#### Component Breakdown

| Component | Source | Variant | Props | Usage |
|-----------|--------|---------|-------|-------|
| `Button` | shadcn/ui | `default`, `ghost` | `size="lg"`, `className="..."` | Primary CTA, secondary actions |
| `Card` | shadcn/ui | `default` | `className="shadow-md"` | Content container, z-1 elevation |
| `Input` | shadcn/ui | `default` | `type="text"`, `placeholder="..."` | Form fields |
| `Label` | shadcn/ui | `default` | `htmlFor="..."` | Form labels with proper association |
| `Dialog` | shadcn/ui | `default` | `open={...}`, `onOpenChange={...}` | Modal overlays, z-4 elevation |

#### Layout Structure

```
[Screen Name]
├─ Container (max-w-7xl, mx-auto, px-4)
│  ├─ Header Section
│  │  ├─ Heading (text-4xl, font-bold, text-gray-900)
│  │  └─ Subheading (text-lg, text-gray-600)
│  ├─ Content Grid (grid-cols-1 md:grid-cols-2 lg:grid-cols-3, gap-6)
│  │  ├─ Card 1 (shadow-md hover:shadow-lg, transition-shadow)
│  │  ├─ Card 2
│  │  └─ Card 3
│  └─ Footer Section
```

#### Elevation Map

- **z-0 (Base)**: Page background, section backgrounds
- **z-1 (Raised)**: Cards, input fields (`shadow-sm`)
- **z-2 (Hover)**: Card hover states (`shadow-md` → `shadow-lg`)
- **z-3 (Floating)**: Dropdown menus, popovers (`shadow-xl`)
- **z-4 (Modal)**: Dialog content, modal overlays (`shadow-2xl`)
- **z-5 (Tooltip)**: Tooltips, highest priority overlays

#### Color Usage

**From tokens.json**:
- **Primary**: `blue-600` (buttons, links, focus states)
- **Text Primary**: `gray-900` (headings, body text)
- **Text Secondary**: `gray-600` (subtext, captions)
- **Background**: `white` (base), `gray-50` (alternating sections)
- **Border**: `gray-200` (minimal usage, prefer shadows)
- **Accent**: `blue-50` (subtle backgrounds for highlights)

#### Typography Scale

**From tokens.json**:
- **Display**: `text-5xl` (64px, font-bold, leading-tight) - Hero headings
- **H1**: `text-4xl` (36px, font-bold, leading-tight) - Page titles
- **H2**: `text-2xl` (24px, font-semibold, leading-snug) - Section headings (1.5x H3)
- **H3**: `text-lg` (18px, font-medium, leading-normal) - Subsections (2x body)
- **Body**: `text-base` (16px, font-normal, leading-relaxed) - Primary text
- **Caption**: `text-sm` (14px, font-normal, leading-normal) - Secondary text

**Hierarchy Ratio**: 2:1 between heading levels (H2 is 2x H3, H3 is 2x caption)

#### Spacing Grid

**From tokens.json** (4px base grid):
- **xs**: `space-1` (4px) - Tight spacing, icon-to-text
- **sm**: `space-2` (8px) - Form field vertical spacing
- **md**: `space-4` (16px) - Card padding, section spacing
- **lg**: `space-6` (24px) - Component margins
- **xl**: `space-8` (32px) - Section margins
- **2xl**: `space-12` (48px) - Large section breaks

#### Interactions

**Hover States**:
- **Buttons**: `hover:bg-blue-700` (primary), `hover:bg-gray-100` (ghost)
- **Cards**: `hover:shadow-lg` (elevation z-1 → z-2)
- **Links**: `hover:underline`, `hover:text-blue-700`

**Focus States** (Keyboard Navigation):
- **All Interactive**: `focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2`
- **Skip Links**: Hidden until focused, `focus:not-sr-only`

**Transitions**:
- **Shadow**: `transition-shadow duration-200` (smooth elevation changes)
- **Color**: `transition-colors duration-150` (button hover, link hover)
- **Transform**: `transition-transform duration-200` (scale on hover for cards)

**Loading States**:
- **Skeleton**: `animate-pulse bg-gray-200` (content loading)
- **Spinner**: `animate-spin` (form submission, async actions)

#### Responsive Behavior

**Mobile (320px - 767px)**:
- Single column layout (`grid-cols-1`)
- Stack navigation vertically
- Full-width cards
- Reduced padding (`px-4` instead of `px-6`)
- Smaller font sizes (scale down by 0.875x)

**Tablet (768px - 1023px)**:
- Two-column grid (`md:grid-cols-2`)
- Horizontal navigation with hamburger menu
- Moderate padding (`px-6`)
- Standard font sizes

**Desktop (1024px+)**:
- Three-column grid (`lg:grid-cols-3`)
- Full horizontal navigation
- Maximum padding (`px-8`)
- Optional larger font sizes for hero sections

#### Accessibility Requirements

**ARIA Labels**:
- All buttons have `aria-label` if icon-only
- All form fields have associated `<Label>` with `htmlFor`
- All modals have `aria-labelledby` and `aria-describedby`
- All images have meaningful `alt` text (not "image" or filename)

**Keyboard Navigation**:
- All interactive elements are focusable (no `tabindex="-1"` on actionable items)
- Modals trap focus (use `Dialog` from shadcn/ui with built-in focus trap)
- Skip links provided for main content (`<a href="#main">Skip to content</a>`)
- Escape key closes modals, dropdowns, popovers

**Screen Reader Support**:
- Semantic HTML (`<header>`, `<main>`, `<nav>`, `<footer>`)
- ARIA roles where semantic HTML insufficient (`role="alert"` for toasts)
- Live regions for dynamic content (`aria-live="polite"` for status updates)
- Hidden labels for icon-only buttons (`<span className="sr-only">...</span>`)

**Color Contrast**:
- All text meets WCAG AAA (7:1 contrast minimum)
- Primary text on white: `gray-900` (14.5:1)
- Secondary text on white: `gray-600` (7.3:1)
- Links on white: `blue-600` (8.2:1)
- Disabled text: `gray-400` (4.5:1 - WCAG AA only, clearly disabled)

---

## Implementation Checklist

### Pre-Implementation

- [ ] Read `tokens.json` completely - memorize color, typography, spacing scales
- [ ] Read `ui-inventory.md` - understand all available components
- [ ] Read `patterns.md` - understand composition patterns and anti-patterns
- [ ] Review all polished prototypes in `mock/*/polished/`
- [ ] Read `hierarchy-analysis.md` - understand F-pattern and heading ratios
- [ ] Confirm design lint passes with 100% compliance

### During Implementation

- [ ] Use ONLY components from `ui-inventory.md` (shadcn/ui)
- [ ] Use ONLY colors from `tokens.json` (no hex, rgb, hsl, arbitrary values)
- [ ] Use ONLY spacing from `tokens.json` (4px grid: space-1, space-2, etc.)
- [ ] Use ONLY typography from `tokens.json` (text-base, text-lg, etc.)
- [ ] Use ONLY shadows from elevation scale (shadow-sm to shadow-2xl)
- [ ] Apply elevation correctly (z-0 for base, z-1 for cards, z-4 for modals)
- [ ] Implement all hover states with `transition-shadow` or `transition-colors`
- [ ] Implement all focus states with `focus:ring-2 focus:ring-blue-500`
- [ ] Add ARIA labels to all icon-only buttons
- [ ] Associate all form fields with labels using `htmlFor`
- [ ] Implement keyboard navigation (tab order, escape key, enter key)
- [ ] Test with screen reader (NVDA, JAWS, or VoiceOver)
- [ ] Verify 2:1 heading hierarchy (measure actual rendered sizes)
- [ ] Verify F-pattern layout (important content top-left, top-horizontal, left-vertical)
- [ ] Use subtle gradients ONLY where specified (check gradient rules in tokens.json)
- [ ] Minimize border usage (prefer shadows for depth)
- [ ] Ensure all images have meaningful alt text
- [ ] Test responsive breakpoints (320px, 768px, 1024px, 1440px)

### Post-Implementation

- [ ] Run design lint on implementation: `node .spec-flow/scripts/design-lint.js app/`
- [ ] Verify 0 critical, 0 errors (warnings acceptable if justified)
- [ ] Run Lighthouse accessibility audit (score ≥ 95)
- [ ] Run axe-core accessibility scan (0 violations)
- [ ] Test keyboard navigation (no mouse, full flow completion)
- [ ] Test screen reader (NVDA or VoiceOver, full flow narration)
- [ ] Visual regression test (Playwright screenshot comparison)
- [ ] Cross-browser test (Chrome, Firefox, Safari, Edge)
- [ ] Performance test (Lighthouse performance score ≥ 90)
- [ ] Mobile test (iOS Safari, Android Chrome, various screen sizes)

---

## Acceptance Criteria

### Visual Fidelity

1. **Pixel-Perfect Match**: Production UI matches polished prototype within 2px tolerance
2. **Color Accuracy**: All colors match `tokens.json` exactly (no approximations)
3. **Typography Match**: Font sizes, weights, line heights match specification
4. **Spacing Consistency**: All spacing adheres to 4px grid from tokens
5. **Shadow Fidelity**: Elevation scale used correctly (z-0 to z-5)

### Interaction Fidelity

1. **Hover States**: All interactive elements have hover feedback
2. **Focus States**: All focusable elements have visible focus indicator
3. **Transitions**: All state changes are smooth (200ms duration)
4. **Loading States**: Skeleton screens or spinners for async operations
5. **Error States**: Clear error messages with red-600 color and alert icon

### Accessibility Compliance

1. **WCAG AAA**: All text contrast ≥ 7:1 (Lighthouse audit passes)
2. **Keyboard Navigation**: Full functionality without mouse
3. **Screen Reader**: All content and actions are announced correctly
4. **ARIA Labels**: All icon-only buttons and form fields have labels
5. **Focus Management**: Modal focus trapping, logical tab order

### Code Quality

1. **No Hardcoded Values**: Design lint passes with 0 critical, 0 errors
2. **Component Reuse**: All UI from shadcn/ui (no custom components unless specified)
3. **TypeScript**: Strict mode enabled, no `any` types
4. **Performance**: Lighthouse performance score ≥ 90
5. **Responsive**: All breakpoints tested and functional

---

## Testing Strategy

### Unit Tests (Vitest + React Testing Library)

```typescript
// Example: Button component
describe('Button', () => {
  it('applies correct variant styles', () => {
    const { container } = render(<Button variant="default">Click me</Button>)
    expect(container.firstChild).toHaveClass('bg-blue-600', 'hover:bg-blue-700')
  })

  it('has accessible label', () => {
    render(<Button aria-label="Close dialog"><XIcon /></Button>)
    expect(screen.getByLabelText('Close dialog')).toBeInTheDocument()
  })
})
```

### Accessibility Tests (axe-core)

```typescript
import { axe, toHaveNoViolations } from 'jest-axe'

expect.extend(toHaveNoViolations)

it('has no accessibility violations', async () => {
  const { container } = render(<Screen />)
  const results = await axe(container)
  expect(results).toHaveNoViolations()
})
```

### Visual Regression Tests (Playwright)

```typescript
import { test, expect } from '@playwright/test'

test('screen matches design', async ({ page }) => {
  await page.goto('/screen-route')
  await expect(page).toHaveScreenshot('screen-baseline.png', {
    maxDiffPixels: 100, // 2px tolerance across screen
  })
})

test('hover states match design', async ({ page }) => {
  await page.goto('/screen-route')
  await page.hover('[data-testid="primary-button"]')
  await expect(page).toHaveScreenshot('button-hover.png')
})
```

### Manual Testing Checklist

**Responsive Design**:
- [ ] Test on iPhone SE (375px width)
- [ ] Test on iPad (768px width)
- [ ] Test on MacBook (1440px width)
- [ ] Test on 4K monitor (2560px width)

**Keyboard Navigation**:
- [ ] Tab through all interactive elements in logical order
- [ ] Verify visible focus indicator on all elements
- [ ] Escape closes modals, dropdowns, popovers
- [ ] Enter activates buttons, submits forms
- [ ] Space toggles checkboxes, activates buttons

**Screen Reader** (NVDA or VoiceOver):
- [ ] All headings announced with correct level
- [ ] All form fields announced with associated label
- [ ] All buttons announced with clear action
- [ ] All images announced with meaningful alt text
- [ ] All modals announced with title and description
- [ ] All status updates announced via live regions

**Cross-Browser**:
- [ ] Chrome (latest stable)
- [ ] Firefox (latest stable)
- [ ] Safari (latest stable)
- [ ] Edge (latest stable)

---

## Design System Validation

### Run Design Lint

```bash
node .spec-flow/scripts/design-lint.js app/[feature-path]
```

**Expected Output**:
```
✅ Design Lint Report
   Critical: 0
   Errors: 0
   Warnings: 0-3 (acceptable if documented)
   Info: 0-5 (optimization suggestions)

✅ Token Compliance: 100%
✅ Elevation Scale: Correct usage
✅ Gradient Compliance: Pass
✅ Hierarchy Validation: 2:1 ratios maintained
```

### Run Accessibility Audit

```bash
npm run lighthouse -- --only-categories=accessibility
npm run axe-scan
```

**Expected Output**:
```
Lighthouse Accessibility: 100/100
axe-core Violations: 0
WCAG Level: AAA
```

---

## Implementation Notes

### Component Import Pattern

```typescript
// ✅ Correct - import from design system
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { Input } from '@/components/ui/input'

// ❌ Wrong - custom components not in ui-inventory.md
import { CustomButton } from './custom-button'
```

### Token Usage Pattern

```typescript
// ✅ Correct - use tokens from Tailwind config
<div className="text-gray-900 bg-white space-y-4 shadow-md">

// ❌ Wrong - hardcoded values
<div style={{ color: '#1a1a1a', backgroundColor: '#ffffff', padding: '16px' }}>
<div className="text-[#1a1a1a] bg-[#ffffff] space-y-[16px]">
```

### Elevation Usage Pattern

```typescript
// ✅ Correct - semantic elevation
<Card className="shadow-sm hover:shadow-md transition-shadow"> // z-1 → z-2
<Dialog>
  <DialogContent className="shadow-2xl"> // z-4 modal
    <Button>Close</Button>
  </DialogContent>
</Dialog>

// ❌ Wrong - arbitrary shadow values
<Card className="shadow-[0_4px_12px_rgba(0,0,0,0.1)]">
<Dialog className="shadow-lg"> // Too weak for modal
```

### Accessibility Pattern

```typescript
// ✅ Correct - full accessibility
<Button aria-label="Close dialog" onClick={onClose}>
  <XIcon className="h-4 w-4" aria-hidden="true" />
</Button>

<Label htmlFor="email">Email</Label>
<Input id="email" type="email" />

// ❌ Wrong - missing labels
<Button onClick={onClose}>
  <XIcon />
</Button>

<Input type="email" placeholder="Email" /> // Placeholder is not a label
```

---

## Anti-Patterns to Avoid

### Visual Anti-Patterns

❌ **Big Colorful Gradients**
```typescript
// Wrong - multi-color, high contrast
<div className="bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600">
```

✅ **Subtle Monochromatic Gradients**
```typescript
// Correct - single color, subtle opacity
<div className="bg-gradient-to-b from-blue-50 to-white">
```

---

❌ **Borders for Depth**
```typescript
// Wrong - border creates flat appearance
<Card className="border-2 border-gray-300">
```

✅ **Shadows for Depth**
```typescript
// Correct - shadow creates elevation
<Card className="shadow-md hover:shadow-lg transition-shadow">
```

---

❌ **Inconsistent Heading Hierarchy**
```typescript
// Wrong - random sizes
<h1 className="text-6xl">Title</h1>
<h2 className="text-2xl">Section</h2> // Too small (3:1 ratio)
<h3 className="text-xl">Subsection</h3> // Too close to H2 (1.2:1 ratio)
```

✅ **2:1 Heading Ratios**
```typescript
// Correct - clear hierarchy
<h1 className="text-4xl font-bold">Title</h1> // 36px
<h2 className="text-2xl font-semibold">Section</h2> // 24px (1.5x H3)
<h3 className="text-lg font-medium">Subsection</h3> // 18px (2x body)
```

---

❌ **Hardcoded Spacing**
```typescript
// Wrong - arbitrary spacing
<div className="space-y-[13px] px-[22px]">
```

✅ **4px Grid Spacing**
```typescript
// Correct - token-based spacing
<div className="space-y-4 px-6"> // 16px, 24px (4px multiples)
```

---

❌ **Missing Accessibility**
```typescript
// Wrong - no keyboard or screen reader support
<div onClick={handleClick} className="cursor-pointer">
  <TrashIcon />
</div>
```

✅ **Full Accessibility**
```typescript
// Correct - semantic, keyboard, screen reader
<Button
  onClick={handleClick}
  aria-label="Delete item"
  className="focus:ring-2 focus:ring-blue-500"
>
  <TrashIcon aria-hidden="true" />
</Button>
```

---

## Design Handoff Checklist

**Designer Responsibilities** (design-polish phase):
- [x] Generate polished prototypes in `mock/*/polished/`
- [x] Validate 100% token compliance (design lint passes)
- [x] Document component usage in this spec
- [x] Document interactions (hover, focus, transitions)
- [x] Document accessibility requirements (ARIA, keyboard nav)
- [x] Create hierarchy analysis report
- [x] Validate elevation scale usage
- [x] Validate gradient compliance
- [x] Create visual regression baseline screenshots

**Developer Responsibilities** (frontend-shipper agent):
- [ ] Read all design artifacts before starting
- [ ] Implement using ONLY design system components
- [ ] Follow token usage patterns strictly
- [ ] Implement all interactions as specified
- [ ] Add comprehensive accessibility features
- [ ] Write unit tests for components
- [ ] Write visual regression tests
- [ ] Run design lint on implementation
- [ ] Run accessibility audits (Lighthouse, axe-core)
- [ ] Test keyboard navigation manually
- [ ] Test screen reader manually
- [ ] Test responsive breakpoints
- [ ] Document any deviations from spec (with justification)

---

## Support and Questions

**Design Questions**: Reference `.spec-flow/memory/design-principles.md`
**Token Questions**: Reference `design/design-system/tokens.json`
**Component Questions**: Reference `design/design-system/ui-inventory.md`
**Pattern Questions**: Reference `design/design-system/patterns.md`
**Accessibility Questions**: Reference WCAG 2.1 AAA guidelines

**Blockers**:
- If design lint fails on implementation, review `design/lint-report.md`
- If accessibility audit fails, review violations and consult WCAG documentation
- If visual regression fails, compare screenshots and update baseline if intentional
- If component not in ui-inventory.md, request design review before creating custom component

---

## Changelog

| Date | Change | Author |
|------|--------|--------|
| [Date] | Initial handoff from design-polish phase | Claude Code |

---

**End of Implementation Specification**

This document is the contract between design and implementation. 100% fidelity is expected. Any deviations must be documented and justified.
