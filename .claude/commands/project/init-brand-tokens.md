---
description: Initialize or update design tokens with brownfield scanning or greenfield generation
---

# /init-brand-tokens — Design System Token Initialization

**Purpose**
Create or update `design/systems/tokens.json` and `tokens.css` by scanning existing code (brownfield) or generating a new palette (greenfield). Validate Tailwind wiring and flag style debt.

**Command**
`/init-brand-tokens`

**When to use**
During `/init-project`, before first `/design`, or when migrating ad-hoc styles to systematic tokens.

---

## Mental model

**Flow**: detect mode → scan/generate → consolidate → validate wiring → report debt

**Brownfield**: Scan existing code for patterns, consolidate, propose migrations.

**Greenfield**: Ask minimal questions, generate OKLCH palette with contrast validation.

---

## Detect mode

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

MODE="greenfield"
if [ -d app ] || [ -d src ] || [ -d components ]; then
  if grep -R -qE "className=.*(bg-|text-|border-)|#[0-9a-fA-F]{6}" app src components 2>/dev/null; then
    MODE="brownfield"
  fi
fi

TOKENS_EXIST=false
if [ -f design/systems/tokens.json ]; then
  TOKENS_EXIST=true
  echo "📦 Existing tokens detected"
  echo ""
  echo "Options:"
  echo "1) Update tokens (scan for new patterns)"
  echo "2) Regenerate tokens (start fresh)"
  echo "3) Keep existing (exit)"
  # Prompt user for choice
fi
```

---

## Brownfield path

### Scan existing code

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

echo "🔍 Scanning codebase for design patterns..."
echo ""

node .spec-flow/scripts/brownfield-token-scanner.js

# Generates:
# - design/systems/detected-tokens.json
# - design/systems/token-analysis-report.md
```

### Consolidate patterns

Read `design/systems/token-analysis-report.md` and propose:

* Colors → 12 semantic + 7 neutral shades
* Type scale → 8 sizes (xs, sm, base, lg, xl, 2xl, 3xl, 4xl)
* Spacing → 8px grid (~13 values)

**Ask minimal questions**:
- Confirm primary color (detected vs custom)
- Confirm font families (detected vs change)

### Generate tokens

Generate `design/systems/tokens.json` from detected patterns + user refinements:

* Map detected colors → semantic tokens (primary, secondary, accent, success, error, warning, info)
* Consolidate duplicate values (e.g., #3b82f7 and #3b81f6 → primary)
* Normalize spacing to 8px grid
* Add OKLCH representations with sRGB fallbacks

**Emit diff report**:

```
Before: 47 colors → After: 12 tokens (74% reduction)
Before: 14 font sizes → After: 8 sizes (43% reduction)
Before: 23 spacing values → After: 13 values (43% reduction)

Removed duplicates:
  - #3b82f7, #3b81f6 → primary (#3b82f6)
  - 15px, 17px → base (16px), lg (18px)
```

### Detect style debt

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

# Find hardcoded colors
grep -rnE "#[0-9a-fA-F]{6}" app src components --include="*.tsx" --include="*.jsx" > design/systems/violations-colors.txt 2>/dev/null || true

# Find arbitrary Tailwind values
grep -rnE "bg-\[|text-\[|border-\[|p-\[|m-\[|shadow-\[" app src components --include="*.tsx" --include="*.jsx" > design/systems/violations-arbitrary.txt 2>/dev/null || true

COLOR_COUNT=$(wc -l < design/systems/violations-colors.txt 2>/dev/null || echo 0)
ARBITRARY_COUNT=$(wc -l < design/systems/violations-arbitrary.txt 2>/dev/null || echo 0)
TOTAL=$((COLOR_COUNT + ARBITRARY_COUNT))

echo "⚠️  Found $TOTAL hardcoded values in codebase"
echo "  Hex colors: $COLOR_COUNT"
echo "  Arbitrary values: $ARBITRARY_COUNT"
echo ""
echo "See token-migration-guide.md for migration steps"
```

---

## Greenfield path

### Ask minimal questions

Use `AskUserQuestion` tool:

```json
{
  "questions": [
    {
      "question": "What is your primary brand color?",
      "header": "Primary",
      "multiSelect": false,
      "options": [
        {"label": "Blue (#3b82f6)", "description": "Professional, trustworthy (SaaS)"},
        {"label": "Purple (#8b5cf6)", "description": "Creative, innovative (design tools)"},
        {"label": "Green (#10b981)", "description": "Growth, success (fintech, health)"},
        {"label": "Custom hex code", "description": "Provide your brand color"}
      ]
    },
    {
      "question": "What is your project's visual style?",
      "header": "Style",
      "multiSelect": false,
      "options": [
        {"label": "Minimal (Stripe, Linear)", "description": "Clean, whitespace, subtle shadows"},
        {"label": "Bold (Figma, Notion)", "description": "Strong colors, playful accents"},
        {"label": "Technical (Vercel, GitHub)", "description": "Monospace, dark themes, code-focused"}
      ]
    },
    {
      "question": "Primary font style?",
      "header": "Typography",
      "multiSelect": false,
      "options": [
        {"label": "Inter (geometric sans)", "description": "Modern, readable, web-optimized"},
        {"label": "Geist (humanist sans)", "description": "Vercel's font, technical elegance"},
        {"label": "System fonts", "description": "Native, fast loading"}
      ]
    }
  ]
}
```

### Generate OKLCH palette

Based on user answers, generate token structure using OKLCH color space:

**OKLCH Format**: `oklch(L% C H)` where:
- L = Lightness (0-100%)
- C = Chroma (0-0.4, typically 0.0-0.25)
- H = Hue (0-360°)

**Token structure**:

```json
{
  "meta": {
    "colorSpace": "oklch",
    "fallbackSpace": "srgb",
    "version": "2.0.0"
  },
  "colors": {
    "brand": {
      "primary": {
        "oklch": "oklch(59.69% 0.156 261.45)",
        "fallback": "#3b82f6"
      },
      "secondary": {
        "oklch": "oklch(58.23% 0.167 271.45)",
        "fallback": "#6366f1"
      },
      "accent": {
        "oklch": "oklch(67.89% 0.152 164.57)",
        "fallback": "#10b981"
      }
    },
    "semantic": {
      "success": {
        "bg": {"oklch": "oklch(95% 0.02 145)", "fallback": "#D1FAE5"},
        "fg": {"oklch": "oklch(25% 0.12 145)", "fallback": "#047857"},
        "border": {"oklch": "oklch(85% 0.05 145)", "fallback": "#A7F3D0"},
        "icon": {"oklch": "oklch(35% 0.13 145)", "fallback": "#059669"}
      },
      "error": {
        "bg": {"oklch": "oklch(95% 0.02 27)", "fallback": "#FEE2E2"},
        "fg": {"oklch": "oklch(30% 0.18 27)", "fallback": "#991B1B"},
        "border": {"oklch": "oklch(85% 0.08 27)", "fallback": "#FECACA"},
        "icon": {"oklch": "oklch(40% 0.20 27)", "fallback": "#DC2626"}
      }
    },
    "neutral": {
      "50": {"oklch": "oklch(98% 0 0)", "fallback": "#fafafa"},
      "100": {"oklch": "oklch(96% 0 0)", "fallback": "#f5f5f5"},
      "200": {"oklch": "oklch(90% 0 0)", "fallback": "#e5e5e5"},
      "400": {"oklch": "oklch(64% 0 0)", "fallback": "#a3a3a3"},
      "600": {"oklch": "oklch(42% 0 0)", "fallback": "#525252"},
      "800": {"oklch": "oklch(23% 0 0)", "fallback": "#262626"},
      "950": {"oklch": "oklch(11% 0 0)", "fallback": "#0a0a0a"}
    }
  },
  "typography": {
    "families": {
      "sans": "Inter, system-ui, -apple-system, sans-serif",
      "mono": "Fira Code, Consolas, monospace"
    },
    "sizes": {
      "xs": "0.75rem",
      "sm": "0.875rem",
      "base": "1rem",
      "lg": "1.125rem",
      "xl": "1.25rem",
      "2xl": "1.5rem",
      "3xl": "1.875rem",
      "4xl": "2.25rem"
    }
  },
  "shadows": {
    "light": {
      "sm": {"value": "0 1px 2px oklch(0% 0 0 / 0.05)", "fallback": "0 1px 2px rgba(0, 0, 0, 0.05)"},
      "md": {"value": "0 4px 6px oklch(0% 0 0 / 0.07), 0 2px 4px oklch(0% 0 0 / 0.06)", "fallback": "0 4px 6px rgba(0, 0, 0, 0.07), 0 2px 4px rgba(0, 0, 0, 0.06)"}
    },
    "dark": {
      "sm": {"value": "0 1px 2px oklch(0% 0 0 / 0.30)", "fallback": "0 1px 2px rgba(0, 0, 0, 0.30)"},
      "md": {"value": "0 4px 6px oklch(0% 0 0 / 0.35), 0 2px 4px oklch(0% 0 0 / 0.30)", "fallback": "0 4px 6px rgba(0, 0, 0, 0.35), 0 2px 4px rgba(0, 0, 0, 0.30)"}
    }
  },
  "motion": {
    "duration": {
      "fast": "150ms",
      "base": "200ms",
      "slow": "300ms"
    },
    "easing": {
      "standard": "cubic-bezier(0.4, 0.0, 0.2, 1)",
      "decelerate": "cubic-bezier(0.0, 0.0, 0.2, 1)"
    }
  },
  "dataViz": {
    "categorical": {
      "okabe-ito": {
        "orange": {"oklch": "oklch(68.29% 0.151 58.43)", "fallback": "#E69F00"},
        "skyBlue": {"oklch": "oklch(70.17% 0.099 232.66)", "fallback": "#56B4E9"},
        "bluishGreen": {"oklch": "oklch(59.78% 0.108 164.04)", "fallback": "#009E73"}
      }
    }
  }
}
```

### Validate contrast

**Automated WCAG contrast calculation** (using colorjs.io):

```javascript
import Color from 'colorjs.io';

function calculateContrast(color1, color2) {
  const c1 = new Color(color1);
  const c2 = new Color(color2);
  const ratio = Math.abs(c1.contrast(c2, 'WCAG21'));

  return {
    ratio: ratio.toFixed(2),
    passAA: ratio >= 4.5,
    passAAA: ratio >= 7.0,
    level: ratio >= 7.0 ? 'AAA' : ratio >= 4.5 ? 'AA' : 'FAIL'
  };
}
```

**Validation output**:

```
✅ success.fg on success.bg: 10.23:1 (AAA)
✅ error.fg on error.bg: 9.87:1 (AAA)
✅ warning.fg on warning.bg: 8.45:1 (AAA)
✅ info.fg on info.bg: 10.12:1 (AAA)
✅ primary on white: 4.83:1 (AA for large text)
⚠️  primary on neutral-200: Adjusted to ensure 4.5:1 minimum
```

---

## Validate Tailwind wiring

### Check config

Read `tailwind.config.js` or `tailwind.config.ts`:

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

if [ ! -f tailwind.config.js ] && [ ! -f tailwind.config.ts ]; then
  echo "⚠️  Tailwind config not found"
  echo "Create with: npx tailwindcss init"
  echo ""
fi
```

**Validation checks**:
- Config file exists
- Colors use CSS variables (`var(--color-*)`)
- Font families match tokens
- Shadow scale matches elevation scale

### Generate CSS variables

Create `design/systems/tokens.css`:

```css
:root {
  /* Brand colors (OKLCH with sRGB fallback) */
  --color-primary: oklch(59.69% 0.156 261.45);
  --color-primary-fallback: #3b82f6;
  --color-secondary: oklch(58.23% 0.167 271.45);
  --color-accent: oklch(67.89% 0.152 164.57);

  /* Semantic colors */
  --color-success-bg: oklch(95% 0.02 145);
  --color-success-fg: oklch(25% 0.12 145);
  --color-error-bg: oklch(95% 0.02 27);
  --color-error-fg: oklch(30% 0.18 27);

  /* Neutral palette */
  --color-neutral-50: oklch(98% 0 0);
  --color-neutral-100: oklch(96% 0 0);
  --color-neutral-950: oklch(11% 0 0);

  /* Typography */
  --font-sans: Inter, system-ui, -apple-system, sans-serif;
  --font-mono: Fira Code, Consolas, monospace;

  /* Shadows - Light mode */
  --shadow-sm: 0 1px 2px oklch(0% 0 0 / 0.05);
  --shadow-md: 0 4px 6px oklch(0% 0 0 / 0.07), 0 2px 4px oklch(0% 0 0 / 0.06);

  /* Motion */
  --motion-duration-fast: 150ms;
  --motion-easing-standard: cubic-bezier(0.4, 0.0, 0.2, 1);
}

/* Dark mode shadows (4-6x opacity increase) */
@media (prefers-color-scheme: dark) {
  :root {
    --shadow-sm: 0 1px 2px oklch(0% 0 0 / 0.30);
    --shadow-md: 0 4px 6px oklch(0% 0 0 / 0.35), 0 2px 4px oklch(0% 0 0 / 0.30);
  }
}

/* Reduced motion (accessibility) */
@media (prefers-reduced-motion: reduce) {
  :root {
    --motion-duration-fast: 0ms;
    --motion-duration-base: 0ms;
    --motion-easing-standard: linear;
  }
}

/* OKLCH fallback for legacy browsers (~8%) */
@supports not (color: oklch(0% 0 0)) {
  :root {
    --color-primary: var(--color-primary-fallback);
    --color-secondary: var(--color-secondary-fallback);
  }
}
```

**Import instruction**:

Add to `app/globals.css` or `styles/globals.css`:

```css
@import './design/systems/tokens.css';
```

---

## Quality gates

**Fail (block next phase) if**:
- Tailwind config missing/broken (syntax errors)
- Primary text contrast < 4.5:1 on light or dark surfaces
- Brownfield: >200 hardcoded style violations

**Warn (non-blocking) if**:
- 20–200 violations: output counts and top offenders
- Some text only AA (4.5:1) not AAA (7:1)
- Custom font families not web-optimized

---

## Outputs

1. `design/systems/tokens.json` — Full token structure (colors, typography, spacing, shadows, motion)
2. `design/systems/tokens.css` — CSS variables with OKLCH and fallbacks
3. `design/systems/token-analysis-report.md` — Brownfield scan results (if applicable)
4. `design/systems/token-migration-guide.md` — Quick reference for migrating hardcoded values
5. `design/systems/violations-*.txt` — Debt logs (if violations found)

---

## Migration quick rules

**Replace hardcoded values with tokens**:

* Hex colors: `#3b82f6` → `bg-primary` or `var(--color-primary)`
* Arbitrary spacing: `p-[15px]` → `p-4` (16px)
* Arbitrary shadows: `shadow-[0_4px_8px_rgba(0,0,0,0.1)]` → `shadow-md`
* Prefer semantic over literal (success/error/info) where intent exists

---

## Error handling

* **Missing Tailwind config**: Show creation snippet, non-blocking
* **Contrast failures**: Auto-adjust lightness until ≥4.5:1 ratio achieved
* **Scan failures**: Continue with empty detected-tokens.json, warn user
* **OKLCH support**: Auto-fallback to sRGB for legacy browsers via `@supports`

---

## References

* OKLCH color space: https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/oklch
* WCAG contrast requirements: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html
* Color.js (contrast calculation): https://colorjs.io/docs/contrast.html
* Tailwind CSS v4 (CSS variables): https://tailwindcss.com/docs/v4-beta
* Okabe-Ito palette (colorblind-safe): https://jfly.uni-koeln.de/color/

---

## Philosophy

**OKLCH over sRGB/HSL**
Perceptually uniform color space yields saner ramps and better contrast control. Fallback to sRGB for legacy browsers.

**Contrast-first**
Validate all text elements against WCAG AA minimum (4.5:1). Target AAA (7:1) for body text.

**Consolidate debt**
Brownfield scanning identifies duplicates; propose 60%+ reduction in unique values.

**CSS variables everywhere**
Tailwind v4 direction; single source of truth for design tokens.

**Accessibility built-in**
Reduced motion, focus ring, colorblind-safe data viz (Okabe-Ito palette).
