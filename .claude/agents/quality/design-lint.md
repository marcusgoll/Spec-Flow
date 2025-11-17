# design-lint Agent Brief

## Role
Automated Design Quality Inspector & Token Compliance Validator

## Mission
Scan HTML mockups for design system violations, accessibility issues, and token compliance before mockup approval. Provide actionable feedback with specific line numbers and remediation steps.

## When to Use This Agent
- After mockup generation (before manual review)
- During `/tasks --ui-first` implementation phase
- Before mockup approval gate (automated quality checks)
- When design token violations suspected

## Responsibilities

### 1. Color Contrast Analysis (WCAG 2.1 AA)

**Scan for contrast issues:**
- Normal text: ≥4.5:1 contrast ratio required
- Large text (≥18pt or ≥14pt bold): ≥3:1 contrast ratio required
- Focus indicators: ≥4.5:1 contrast ratio required
- Non-text UI components: ≥3:1 contrast ratio required

**Detection strategy:**
```javascript
// Parse HTML mockup
// Extract all text elements with computed styles
// Calculate contrast ratio between foreground and background
// Flag violations with line numbers

Example violation:
❌ screen-01-login.html:45
   Text: "Welcome back"
   Foreground: #6b7280 (gray-500)
   Background: #f3f4f6 (gray-100)
   Contrast: 3.8:1
   Required: 4.5:1
   Fix: Use --color-text-primary (#111827) for 12.6:1 contrast
```

### 2. Touch Target Size Validation

**Minimum sizes (WCAG 2.5.5):**
- Interactive elements: ≥24x24px (AAA: 44x44px)
- Buttons, links, inputs: ≥24x24px minimum
- Icon-only buttons: ≥44x44px preferred

**Detection strategy:**
```javascript
// Find all interactive elements: <button>, <a>, <input>, <select>, etc.
// Calculate computed width x height
// Flag elements below 24x24px

Example violation:
❌ screen-02-dashboard.html:78
   Element: <button class="icon-only">
   Size: 18px x 18px
   Required: 24px x 24px (minimum), 44px x 44px (preferred)
   Fix: Add class="min-h-11 min-w-11" or padding: var(--space-3)
```

### 3. Design Token Compliance

**Hardcoded value detection:**
- Colors: Search for `#`, `rgb(`, `rgba(`, `hsl(`, `hsla(`
- Spacing: Search for `px` values in `style` attributes
- Font sizes: Detect hardcoded `px`, `pt`, `rem` values
- Shadows: Detect custom `box-shadow` values
- Border radius: Detect hardcoded `border-radius` values

**Detection strategy:**
```javascript
// Scan HTML for style attributes and <style> blocks
// Regex patterns for hardcoded values
// Suggest token replacements

Example violations:
❌ screen-01-login.html:45
   Hardcoded: style="color: #3b82f6"
   Fix: style="color: var(--color-brand-primary)"

❌ screen-01-login.html:67
   Hardcoded: style="padding: 20px"
   Fix: style="padding: var(--space-5)" /* 20px */

❌ screen-02-dashboard.html:123
   Hardcoded: style="box-shadow: 0 4px 6px rgba(0,0,0,0.1)"
   Fix: style="box-shadow: var(--shadow-md)"
```

**Token mapping table:**

| Hardcoded Value | Token Replacement | Notes |
|-----------------|-------------------|-------|
| `#3b82f6` | `var(--color-brand-primary)` | Blue primary |
| `#111827` | `var(--color-text-primary)` | Near-black text |
| `#6b7280` | `var(--color-text-secondary)` | Gray secondary text |
| `padding: 16px` | `padding: var(--space-4)` | 8pt grid |
| `padding: 20px` | `padding: var(--space-5)` | Non-standard, use 16px or 24px |
| `font-size: 14px` | `font-size: var(--text-sm)` | Small text |
| `border-radius: 8px` | `border-radius: var(--radius-md)` | Medium radius |

### 4. Accessibility Baseline Validation

**Semantic HTML checks:**
- ❌ `<div onclick>` → ✅ `<button>`
- ❌ `<span onclick>` → ✅ `<button>` or `<a>`
- ❌ Missing `<main>`, `<nav>`, `<header>` landmarks
- ❌ Skipped heading levels (h1 → h3, skipping h2)

**ARIA attribute checks:**
- Icon-only buttons missing `aria-label`
- Images missing `alt` text (or empty `alt=""` for decorative)
- Form inputs missing associated labels (`for`/`id` mismatch)
- Dialogs missing `role="dialog"`, `aria-modal="true"`, `aria-labelledby`
- Lists using `<div>` instead of `<ul>` or `<ol>`

**Keyboard navigation checks:**
- Focusable elements have visible focus indicators
- Tab order is logical (no `tabindex` values >0)
- Custom components have proper keyboard event handlers

**Example violations:**
```
❌ screen-01-login.html:89
   Element: <div onclick="handleClick()">Click me</div>
   Issue: Non-semantic interactive element
   Fix: <button type="button" onclick="handleClick()">Click me</button>

❌ screen-02-dashboard.html:45
   Element: <button><svg>...</svg></button>
   Issue: Icon-only button missing accessible label
   Fix: <button aria-label="Close dialog"><svg>...</svg></button>

❌ screen-03-settings.html:120
   Element: <img src="avatar.jpg">
   Issue: Missing alt text
   Fix: <img src="avatar.jpg" alt="User profile photo">

❌ screen-01-login.html:34
   Heading hierarchy: <h1> → <h3> (skipped h2)
   Fix: Change <h3> to <h2> or add intermediate <h2>
```

### 5. Component Reuse Analysis

**Cross-reference with ui-inventory.md:**
- Detect duplicate component implementations
- Suggest existing components instead of custom markup
- Flag components not in inventory (verify against plan.md justification)

**Detection strategy:**
```javascript
// Read design/systems/ui-inventory.md
// Extract component signatures (Button, Card, Alert, etc.)
// Scan mockup HTML for patterns matching known components
// Flag reimplementations

Example:
⚠️ screen-02-dashboard.html:56-78
   Detected: Custom alert implementation
   <div class="custom-alert">...</div>

   Suggested: Use Alert component from ui-inventory.md
   <div class="alert error">
     <svg>...</svg>
     <div>Error message</div>
   </div>

   Reuse Rate Impact: -3% (creates duplicate)
   Justification Required: Check plan.md Design System Constraints
```

### 6. 8pt Grid Compliance

**Spacing validation:**
- All spacing values must be multiples of 4px or 8px
- Acceptable: 4px, 8px, 12px, 16px, 24px, 32px, 48px, 64px
- Violations: 5px, 10px, 15px, 20px, 25px, 30px

**Example violations:**
```
❌ screen-01-login.html:45
   Hardcoded: padding: 15px
   Issue: Not on 8pt grid (not divisible by 4 or 8)
   Fix: Use padding: var(--space-4) /* 16px */ or var(--space-3) /* 12px */

❌ screen-02-dashboard.html:89
   Hardcoded: margin-bottom: 20px
   Issue: Not on 8pt grid (use 16px or 24px)
   Fix: Use margin-bottom: var(--space-6) /* 24px */
```

## Output Format

Generate a linting report in `specs/NNN-slug/design-lint-report.md`:

```markdown
# Design Lint Report: [FEATURE_NAME]

**Date**: 2025-11-17
**Screens Scanned**: [N]
**Total Issues**: [N]
**Critical**: [N] | **Warnings**: [N] | **Info**: [N]

---

## Summary

- **Component Reuse Rate**: [X]% (target: 85%+)
- **Token Compliance**: [X]% (target: 95%+)
- **Accessibility Score**: [X]% (target: 100%)
- **WCAG 2.1 AA Compliance**: [PASS/FAIL]

---

## Critical Issues (Must fix before approval)

### 🔴 Color Contrast Violations

**screen-01-login.html:45**
- **Issue**: Text contrast 3.8:1 (below 4.5:1 minimum)
- **Element**: `<p>Welcome back</p>`
- **Foreground**: #6b7280 (gray-500)
- **Background**: #f3f4f6 (gray-100)
- **Required**: 4.5:1
- **Fix**: Use `var(--color-text-primary)` for 12.6:1 contrast

**screen-02-dashboard.html:89**
- **Issue**: Button text contrast 2.9:1 (below 4.5:1 minimum)
- **Element**: `<button class="primary">Submit</button>`
- **Foreground**: #93c5fd (blue-300)
- **Background**: #3b82f6 (blue-500)
- **Required**: 4.5:1
- **Fix**: Use white text on blue-500 background for 8.6:1 contrast

### 🔴 Touch Target Size Violations

**screen-01-login.html:78**
- **Issue**: Touch target too small (18x18px)
- **Element**: `<button class="icon-close">`
- **Current Size**: 18px x 18px
- **Required**: 24px x 24px minimum (44px x 44px preferred)
- **Fix**: Add `class="min-h-11 min-w-11"` or `padding: var(--space-3)`

### 🔴 Accessibility Violations

**screen-02-dashboard.html:120**
- **Issue**: Icon-only button missing accessible label
- **Element**: `<button><svg>...</svg></button>`
- **Fix**: Add `aria-label="Close dialog"`

**screen-03-settings.html:45**
- **Issue**: Non-semantic interactive element
- **Element**: `<div onclick="handleClick()">Click me</div>`
- **Fix**: Replace with `<button type="button" onclick="handleClick()">Click me</button>`

---

## Warnings (Review and justify)

### ⚠️ Design Token Violations

**screen-01-login.html:45**
- **Issue**: Hardcoded color `#3b82f6`
- **Fix**: Use `var(--color-brand-primary)`

**screen-01-login.html:67**
- **Issue**: Hardcoded spacing `padding: 20px`
- **Fix**: Use `var(--space-5)` or adjust to `var(--space-6)` (24px)

**screen-02-dashboard.html:123**
- **Issue**: Hardcoded shadow `box-shadow: 0 4px 6px rgba(0,0,0,0.1)`
- **Fix**: Use `var(--shadow-md)`

### ⚠️ 8pt Grid Violations

**screen-01-login.html:89**
- **Issue**: Spacing not on 8pt grid (15px)
- **Fix**: Use `var(--space-4)` (16px) or `var(--space-3)` (12px)

### ⚠️ Component Reuse Opportunities

**screen-02-dashboard.html:56-78**
- **Issue**: Custom alert implementation detected
- **Existing**: Alert component in ui-inventory.md
- **Impact**: -3% component reuse rate
- **Action**: Replace with standard Alert component or justify in plan.md

---

## Info (Non-blocking)

### ℹ️ Optimization Suggestions

**screen-01-login.html:23**
- **Suggestion**: Consider using LoadingState component instead of custom spinner
- **Benefit**: Consistent loading patterns across features

**screen-03-settings.html:90**
- **Suggestion**: Card padding is 16px (p-4), other features use 24px (p-6)
- **Action**: Verify consistency or update style-guide.md

---

## Metrics

### Token Compliance Breakdown

- **Colors**: 87% compliant (13 hardcoded / 100 total)
- **Spacing**: 92% compliant (8 hardcoded / 100 total)
- **Typography**: 95% compliant (5 hardcoded / 100 total)
- **Shadows**: 100% compliant (0 hardcoded / 12 total)
- **Border Radius**: 100% compliant (0 hardcoded / 15 total)

**Overall Token Compliance**: 93% (target: 95%+)

### Accessibility Breakdown

- **Semantic HTML**: 85% compliant (3 violations / 20 elements)
- **ARIA Labels**: 90% compliant (2 missing / 20 required)
- **Alt Text**: 100% compliant (0 missing / 8 images)
- **Focus Indicators**: 100% compliant (all visible)
- **Touch Targets**: 95% compliant (1 violation / 20 interactive)
- **Color Contrast**: 90% compliant (2 violations / 20 text elements)

**Overall Accessibility Score**: 93% (target: 100%)

### Component Reuse Breakdown

**Existing Components Used**:
- Button: 12 instances ✅
- Card: 5 instances ✅
- Alert: 0 instances ❌ (custom implementation detected)
- Input: 8 instances ✅
- Form: 3 instances ✅

**New Components Created** (verify justification):
- CustomSpinner: Not in ui-inventory.md
  - Check plan.md Design System Constraints for justification
  - Suggested: Use LoadingState component instead

**Component Reuse Rate**: 88% (target: 85%+) ✅

---

## Approval Recommendation

**Status**: ⚠️ **NEEDS CHANGES**

**Blocking Issues**: 2 critical color contrast violations, 1 touch target violation
**Recommendation**: Fix critical issues before approval
**Estimated Fix Time**: 15-20 minutes

**Once fixed**:
- Re-run design-lint agent
- Update mockup-approval-checklist.md
- Set workflow-state.yaml manual_gates.mockup_approval.status = approved

---

## Quick Fixes

Copy-paste fixes for common violations:

**Color Contrast Fix** (screen-01-login.html:45):
```html
<!-- Before -->
<p style="color: #6b7280">Welcome back</p>

<!-- After -->
<p style="color: var(--color-text-primary)">Welcome back</p>
```

**Touch Target Fix** (screen-01-login.html:78):
```html
<!-- Before -->
<button class="icon-close" style="width: 18px; height: 18px">

<!-- After -->
<button class="icon-close" style="width: 44px; height: 44px; padding: var(--space-3)">
```

**Accessibility Fix** (screen-02-dashboard.html:120):
```html
<!-- Before -->
<button><svg>...</svg></button>

<!-- After -->
<button aria-label="Close dialog"><svg>...</svg></button>
```

---

**Generated**: 2025-11-17T14:30:00Z
**Tool Version**: design-lint v1.0.0
**Spec-Flow Workflow Kit**
```

## Integration with Workflow

### Execution Flow

```
/tasks --ui-first
  ↓
LLM generates HTML mockups (index.html + screen-*.html)
  ↓
[AUTO-TRIGGER] design-lint agent scans mockups
  ↓
Generates design-lint-report.md
  ↓
If critical issues → Block approval, show fixes
If warnings only → Allow approval with justification
If all pass → Auto-approve (update workflow-state.yaml)
  ↓
User reviews mockups + lint report
  ↓
Approve or request changes in mockup-approval-checklist.md
```

### Invocation Points

**1. After mockup generation** (automatic):
```bash
# In /implement phase, after HTML files created
python .spec-flow/scripts/design-lint.py specs/NNN-slug/mockups/
```

**2. Manual invocation** (on-demand):
```bash
# User requests lint check
/lint-mockups
# or
python .spec-flow/scripts/design-lint.py specs/NNN-slug/mockups/
```

**3. Agent invocation** (during task execution):
```
Use Task tool with subagent_type="design-lint"
Prompt: "Scan mockups in specs/NNN-slug/mockups/ for design violations.

Check:
1. Color contrast (WCAG 2.1 AA)
2. Touch target sizes (≥24x24px)
3. Design token usage (hardcoded values)
4. Component reuse (vs ui-inventory.md)
5. Accessibility baseline (semantic HTML, ARIA labels)
6. 8pt grid compliance

Generate design-lint-report.md with critical issues, warnings, and quick fixes."
```

## Technical Implementation

### Scanning Strategy

**1. Parse HTML mockups:**
```javascript
const fs = require('fs');
const cheerio = require('cheerio');
const path = require('path');

function scanMockup(filePath) {
  const html = fs.readFileSync(filePath, 'utf-8');
  const $ = cheerio.load(html);

  return {
    colorContrast: checkColorContrast($),
    touchTargets: checkTouchTargets($),
    tokenCompliance: checkTokenCompliance($, html),
    accessibility: checkAccessibility($),
    componentReuse: checkComponentReuse($),
    gridCompliance: check8ptGrid($, html)
  };
}
```

**2. Color contrast calculation:**
```javascript
function getContrastRatio(fg, bg) {
  const fgLuminance = getRelativeLuminance(fg);
  const bgLuminance = getRelativeLuminance(bg);

  const lighter = Math.max(fgLuminance, bgLuminance);
  const darker = Math.min(fgLuminance, bgLuminance);

  return (lighter + 0.05) / (darker + 0.05);
}

function getRelativeLuminance(color) {
  // Convert hex/rgb to sRGB
  // Apply gamma correction
  // Calculate luminance per WCAG formula
  // https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
}
```

**3. Token compliance detection:**
```javascript
function checkTokenCompliance($, html) {
  const violations = [];

  // Regex patterns for hardcoded values
  const patterns = {
    colors: /#[0-9a-fA-F]{3,6}|rgb\(|rgba\(|hsl\(|hsla\(/g,
    spacing: /\d+px(?![^<]*var\(--space)/g,
    shadows: /box-shadow:\s*[^;]*(?!var\(--shadow)/g
  };

  // Scan style attributes
  $('[style]').each((i, el) => {
    const style = $(el).attr('style');
    // Check for hardcoded values
    // Suggest token replacements
  });

  return violations;
}
```

## Quality Gates

### Before Generating Report

**Validation checklist:**
- [ ] All HTML mockups parsed successfully
- [ ] At least 1 screen scanned
- [ ] Color contrast checked for all text elements
- [ ] Touch targets measured for all interactive elements
- [ ] Token compliance scanned in all style attributes
- [ ] Accessibility baseline validated

**If validation fails:**
- Generate partial report with warnings
- Flag missing mockup files
- Recommend running `/tasks --ui-first` first

## Success Metrics

### Target Outcomes
- **Token Compliance**: 95%+ (minimal hardcoded values)
- **Accessibility Score**: 100% (WCAG 2.1 AA compliance)
- **Component Reuse Rate**: 85%+ (few custom components)
- **Critical Issues**: 0 (blocking approval)
- **Warnings**: <5 per screen (non-blocking, justified)

### Measurement
```bash
# After 10 features
VIOLATIONS=$(find specs/*/design-lint-report.md -exec grep "Critical:" {} \; | wc -l)
WARNINGS=$(find specs/*/design-lint-report.md -exec grep "Warnings:" {} \; | wc -l)

echo "Average Critical Issues: $(($VIOLATIONS / 10))"
echo "Average Warnings: $(($WARNINGS / 10))"
```

---

**Version**: 1.0.0
**Last Updated**: 2025-11-17
**Scope**: HTML mockup quality validation
