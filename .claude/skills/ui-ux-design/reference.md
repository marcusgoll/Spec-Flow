# UI/UX Design Reference Guide

## Jobs Principles Checklist

Steve Jobs' design philosophy distilled into actionable validation criteria.

### 1. Focus

**Principle**: One primary action per screen. Remove everything else.

**Validation**:
- [ ] Screen has ONE primary CTA (not 2-3 equally weighted buttons)
- [ ] Primary action describable in ≤5 words
- [ ] Secondary actions visually subordinate (ghost/outline variants)
- [ ] No "button soup" (≤3 total actions per screen)

**Examples**:
- ✅ Upload screen: "Upload Report" (primary), "Learn More" (ghost)
- ❌ Upload screen: "Upload", "Scan", "Convert", "Extract" (all primary)

---

### 2. Simplicity

**Principle**: ≤2 clicks to complete primary action. No tooltips needed.

**Validation**:
- [ ] Primary task completable in ≤2 clicks
- [ ] Zero tooltips or help icons (design explains itself)
- [ ] Instructions not needed (5 users can complete without asking)
- [ ] Error states guide recovery (not just "Error occurred")

**Time Test**:
```
Give 5 users the screen (no instructions).
- If ALL complete primary action <10 seconds → PASS
- If ANY ask "what do I do?" → FAIL (too complex)
```

**Examples**:
- ✅ Upload: Click zone → File picker opens (1 click)
- ❌ Upload: Click "Choose File" → Modal → Click "Browse" → File picker (3 clicks)

---

### 3. Details Matter

**Principle**: Spacing on 8px grid. Animations 200-300ms. Perfect alignment.

**Validation**:
- [ ] All spacing divisible by 8px (padding, margin, gaps)
- [ ] Transitions 200-300ms with easing (not instant, not sluggish)
- [ ] Visual hierarchy clear (size, weight, color contrast)
- [ ] Micro-interactions present (hover, focus, active states)

**Verification Script**:
```bash
# Check spacing compliance
.spec-flow/scripts/verify-design-principles.sh --check-spacing

# Check animation timing
grep -nE "duration-[0-9]+" $POLISHED_FILE | \
  grep -v "duration-200\|duration-300" | \
  wc -l  # Should be 0
```

**Examples**:
- ✅ Card padding: p-6 (24px = 8px × 3)
- ❌ Card padding: p-[23px] (arbitrary value)
- ✅ Hover transition: transition-colors duration-200
- ❌ Hover transition: transition duration-500 (too slow)

---

### 4. Innovation

**Principle**: Don't just copy competitors. Question assumptions. Test opposite approaches.

**Validation**:
- [ ] At least 2 variants break from conventional patterns
- [ ] Hypothesis documented (why will this be better?)
- [ ] A/B test plan defined (how to measure success?)
- [ ] HEART metric targeted (which dimension improves?)

**Variant Requirement**:
```
If competitors use modals → Test inline flow
If competitors redirect → Test same-page updates
If competitors show progress bar → Test percentage + ETA
```

**Examples**:
- ✅ AKTR Upload variants: v2 inline (breaks redirect convention), v5 progressive disclosure (breaks upfront pattern)
- ❌ 5 variants all using modal approach (no innovation)

---

## Variant Quality Guidelines

### Small Diffs (Change One Thing at a Time)

**Rule**: Each variant should test ONE hypothesis.

**Good Variance**:
```
v1: Redirect flow (baseline)
v2: Inline preview (tests same-page hypothesis)
v3: Modal confirmation (tests progressive disclosure)
```

**Bad Variance**:
```
v2 vs v1: Inline + different copy + progress bar + new layout
(Too many changes - can't isolate what works)
```

---

### System Components Only

**Rule**: Use only components from `ui-inventory.md`. No custom widgets.

**Why**: Maintains consistency, reduces maintenance burden, enables theming.

**Validation**:
```bash
# Check imports
grep "^import.*from" $VARIANT_FILE | \
  grep -v "@/components/ui" | \
  grep -v "next/" | \
  grep -v "react" | \
  wc -l  # Should be 0
```

**If component needed but not in inventory**:
1. Propose in `design/systems/proposals/[component].md`
2. Add to `ui-inventory.md` first
3. Then use in variants

---

### Real Copy (No Lorem Ipsum)

**Rule**: All variants use real copy from `copy.md`.

**Why**: Copy affects layout decisions. "Lorem ipsum" hides problems.

**Examples**:
- ✅ "Upload AKTR Report" (real, specific)
- ❌ "Upload Your File" (generic)
- ❌ "Lorem ipsum dolor sit amet" (placeholder)

---

### Mobile-First Responsive

**Rule**: All variants work on mobile (375px width).

**Validation**:
```bash
# Test at common breakpoints
375px  # Mobile (iPhone SE)
768px  # Tablet
1440px # Desktop
```

**Breakpoint Usage**:
```tsx
// Mobile-first approach
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
  // Single column on mobile
  // Two columns on tablet (md)
  // Three columns on desktop (lg)
</div>
```

---

## Design System Compliance

### Colors: All from tokens.json

**Rule**: No hardcoded color values. All colors from design tokens.

**Forbidden**:
```tsx
<div className="bg-[#0066FF]">  // ❌ Hardcoded hex
<div style={{ backgroundColor: 'rgb(0, 102, 255)' }}>  // ❌ Inline RGB
```

**Allowed**:
```tsx
<div className="bg-brand-primary">  // ✅ Design token
<div className="text-neutral-600">  // ✅ Neutral palette
<div className="border-semantic-error">  // ✅ Semantic token
```

**Token Structure** (tokens.json):
```json
{
  "colors": {
    "brand": { "primary": { "DEFAULT": "#0066FF", "50": "...", "600": "..." } },
    "semantic": { "success": { "DEFAULT": "...", "light": "...", "dark": "..." } },
    "neutral": { "50": "...", "100": "...", "900": "..." }
  }
}
```

---

### Components: All from ui-inventory.md

**Rule**: No custom components. Use catalog only.

**Available Components** (check ui-inventory.md):
- Button (variants: default, outline, ghost, destructive)
- Card (with CardHeader, CardTitle, CardContent)
- Input, Label, Textarea
- Alert (variants: default, destructive)
- Progress, Badge, Skeleton
- Dialog, Sheet, Dropdown Menu

**If component missing**:
1. Check if existing component can be styled differently
2. Propose new component in `design/systems/proposals/`
3. Add to ui-inventory.md with examples
4. Then use in designs

---

### Spacing: System Scale Only

**Rule**: Use system spacing scale (4px base). No arbitrary values.

**Forbidden**:
```tsx
<div className="p-[17px]">  // ❌ Arbitrary value
<div className="m-[23px]">  // ❌ Not on scale
```

**Allowed**:
```tsx
<div className="p-4">  // ✅ 16px (4 × 4)
<div className="m-6">  // ✅ 24px (6 × 4)
<div className="gap-8">  // ✅ 32px (8 × 4)
```

**Scale** (4px base):
```
1 = 4px
2 = 8px
3 = 12px
4 = 16px
5 = 20px
6 = 24px
8 = 32px
10 = 40px
12 = 48px
16 = 64px
20 = 80px
24 = 96px
```

---

### Typography: System Fonts Only

**Rule**: Use font-sans or font-mono from tokens.json.

**Forbidden**:
```tsx
<p className="font-[Roboto]">  // ❌ Arbitrary font
<p style={{ fontFamily: 'Arial' }}>  // ❌ Inline style
```

**Allowed**:
```tsx
<p className="font-sans">  // ✅ System sans-serif
<code className="font-mono">  // ✅ System monospace
```

**Font Definition** (tokens.json):
```json
{
  "typography": {
    "fontFamily": {
      "sans": ["Inter", "system-ui", "-apple-system", "sans-serif"],
      "mono": ["JetBrains Mono", "Consolas", "monospace"]
    }
  }
}
```

---

## Cleanup Patterns

### Git Tag Format

**Pattern**: `design-variants-{SLUG}-{TIMESTAMP}`

**Example**: `design-variants-aktr-upload-20250119-143022`

**Tag Message Template**:
```
Design variants for {SLUG} before cleanup

Variants preserved: v1, v2, v3, v4, v5
Merged into: functional/
Review date: 2025-01-19 14:30:22 UTC

Design decisions (from crit.md):
- Layout: v2 (inline preview)
- Drag-drop: v3 (visual cues)
- Progress: v2 (linear bar with percentage)
- Error: v2 (inline alert, not modal)

To restore variants:
  git checkout {TAG_NAME}
  git checkout {TAG_NAME} -- apps/web/mock/{SLUG}/
```

---

### Folders to Delete

**After functional merge**:
```
Delete:
- $MOCK_DIR/$SCREEN/v1/
- $MOCK_DIR/$SCREEN/v2/
- $MOCK_DIR/$SCREEN/v3/
- $MOCK_DIR/$SCREEN/v4/
- $MOCK_DIR/$SCREEN/v5/
- $MOCK_DIR/$SCREEN/compare/ (optional)

Keep:
- $MOCK_DIR/$SCREEN/functional/
- $MOCK_DIR/$SCREEN/page.tsx (variant index - optional)
```

**After polish**:
```
Delete (optional):
- $MOCK_DIR/$SCREEN/functional/ (if keeping only polished)

Keep:
- $MOCK_DIR/$SCREEN/polished/
```

---

### Restore Command

**Full restoration**:
```bash
# Restore all variants from tag
TAG_NAME="design-variants-aktr-upload-20250119-143022"
git checkout $TAG_NAME -- apps/web/mock/aktr-upload/
```

**Single screen restoration**:
```bash
# Restore one screen's variants
git checkout $TAG_NAME -- apps/web/mock/aktr-upload/upload/v2/
```

---

## Accessibility Quick Reference

### WCAG 2.1 AA Requirements

**Color Contrast**:
- Normal text: ≥4.5:1
- Large text (18pt+): ≥3:1
- UI components: ≥3:1

**Keyboard Navigation**:
- All interactive elements reachable via Tab
- Enter/Space activates buttons
- ESC closes modals/dialogs
- No keyboard traps

**ARIA Labels**:
- Form inputs: Associated <label> or aria-label
- Icon-only buttons: aria-label describing action
- Progress indicators: aria-label with status
- Live regions: aria-live for dynamic updates

**Focus Management**:
- Visible focus indicator (2px ring)
- Focus returns after modal close
- Auto-focus on error recovery actions

---

## Performance Quick Reference

### Web Vitals Targets

**First Contentful Paint (FCP)**:
- Target: <1.5s
- Optimization: Reduce render-blocking resources, lazy load below-fold

**Largest Contentful Paint (LCP)**:
- Target: <2.5s
- Optimization: Optimize images (Next.js Image), preload critical resources

**Cumulative Layout Shift (CLS)**:
- Target: <0.1
- Optimization: Reserve space for images, avoid inserting content above viewport

**Time to Interactive (TTI)**:
- Target: <3s
- Optimization: Code split heavy components, defer non-critical JS

---

### Optimization Checklist

- [ ] Images: Next.js <Image> with lazy loading
- [ ] Code splitting: dynamic() imports for Dialog, Tooltip, heavy components
- [ ] Lazy loading: Below-fold content in <Suspense>
- [ ] Bundle size: Check with `pnpm analyze`
- [ ] Lighthouse score: Performance ≥90, Accessibility ≥95

---

_This reference will be expanded with real examples and patterns as features flow through the design workflow._
