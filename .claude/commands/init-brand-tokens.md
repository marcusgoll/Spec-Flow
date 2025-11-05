# /init-brand-tokens

**Purpose**: Initialize or update brand tokens for the design system with intelligent brownfield scanning or greenfield creation.

**When to use**:
- During `/init-project` (first-time project setup)
- Before first `/design` command (lazy initialization)
- When updating existing design system
- When migrating from ad-hoc styles to systematic tokens

**Philosophy**: Smart detection eliminates guesswork. Brownfield projects scan existing patterns, greenfield projects use guided creation.

---

## Agent Brief

**Role**: Design System Architect

**Objective**: Create or update `design/systems/tokens.json` with:
- Brownfield: Detected patterns from codebase analysis
- Greenfield: AI-generated palette with accessibility validation
- Validation: Tailwind config imports, hardcoded value detection

---

## Input Context

**Read these files**:
1. `docs/project/tech-stack.md` — Framework detection (Next.js, React, Vue)
2. `docs/project/overview.md` — Brand context, target users
3. `design/systems/tokens.json` — Check if exists (update mode)
4. `tailwind.config.js` or `tailwind.config.ts` — Validate token imports
5. Package files — Detect Tailwind version, color packages

**Check for existing code**:
- Source files: `src/`, `app/`, `components/`, `pages/`, `styles/`
- Extensions: `.tsx`, `.jsx`, `.ts`, `.js`, `.css`, `.scss`

---

## Workflow

### Phase 0: Detection

**Determine project mode**:

```bash
if [ -d "src" ] || [ -d "app" ] || [ -d "components" ]; then
  if grep -r "className.*bg-\|text-\|border-" src/ app/ components/ >/dev/null 2>&1; then
    MODE="brownfield"  # Existing code detected
  else
    MODE="greenfield"  # Empty project
  fi
else
  MODE="greenfield"  # No source directories
fi
```

**Check if tokens exist**:

```bash
if [ -f "design/systems/tokens.json" ]; then
  TOKENS_EXIST=true
  echo "📦 Existing tokens detected"
  echo ""
  echo "Options:"
  echo "1. Update tokens (scan codebase for new patterns)"
  echo "2. Regenerate tokens (start fresh)"
  echo "3. Keep existing tokens (exit)"
  # Prompt user for choice
else
  TOKENS_EXIST=false
fi
```

---

### Phase 1: Brownfield Scanning

**If MODE="brownfield"**:

#### Step 1.1: Run Token Scanner

```bash
echo "🔍 Scanning codebase for design patterns..."
echo ""

node .spec-flow/scripts/brownfield-token-scanner.js

# Generates:
# - design/systems/detected-tokens.json
# - design/systems/token-analysis-report.md
```

#### Step 1.2: Present Analysis

Read `design/systems/token-analysis-report.md` and summarize:

```
📊 Codebase Analysis Results:

Colors:
  - 47 unique colors detected
  - Top 5: #3b82f6 (52×), #ffffff (48×), #1f2937 (34×), #10b981 (18×), #ef4444 (12×)
  - Recommendation: Consolidate to 12 tokens (5 semantic + 7 neutral)

Typography:
  - 3 font families: Inter (primary), system-ui (fallback), Fira Code (mono)
  - 14 font sizes detected
  - Recommendation: Use 8-size type scale

Spacing:
  - 23 unique spacing values
  - Most common: 16px (64×), 8px (52×), 24px (38×), 32px (28×)
  - Recommendation: 8px grid (12 values)

💡 Next: Review detected-tokens.json and confirm/adjust proposed token structure
```

#### Step 1.3: Interactive Refinement

Use `AskUserQuestion` tool to confirm/adjust detected patterns:

```json
{
  "questions": [
    {
      "question": "Primary color detected as #3b82f6 (blue). Confirm or change?",
      "header": "Primary",
      "multiSelect": false,
      "options": [
        { "label": "Confirm #3b82f6", "description": "Use detected blue as primary" },
        { "label": "Use #8b5cf6 (purple)", "description": "Second most common color" },
        { "label": "Custom color", "description": "Provide hex code manually" }
      ]
    },
    {
      "question": "Font families: Inter (primary), Fira Code (mono). Confirm?",
      "header": "Fonts",
      "multiSelect": false,
      "options": [
        { "label": "Confirm Inter + Fira Code", "description": "Use detected fonts" },
        { "label": "Change fonts", "description": "Provide custom font stack" }
      ]
    }
  ]
}
```

#### Step 1.4: Consolidation

Generate consolidated `tokens.json` from `detected-tokens.json` + user refinements:

- Map detected colors → semantic tokens (primary, secondary, accent, success, error, warning, info)
- Reduce font sizes to 8-value scale (xs, sm, base, lg, xl, 2xl, 3xl, 4xl)
- Normalize spacing to 8px grid (0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24)
- Add elevation scale (z-0 to z-5) from design-principles.md
- Add subtle gradient presets

**Diff report** (show user what changed):

```diff
Before: 47 colors → After: 12 tokens
Before: 14 font sizes → After: 8 sizes
Before: 23 spacing values → After: 13 values

Removed duplicates:
  - #3b82f7, #3b81f6 → consolidated to primary (#3b82f6)
  - 15px, 17px → normalized to base (16px) and lg (18px)
```

---

### Phase 2: Greenfield Creation

**If MODE="greenfield"**:

#### Step 2.1: Brand Discovery

Use `AskUserQuestion` tool for guided setup:

```json
{
  "questions": [
    {
      "question": "What is your primary brand color?",
      "header": "Primary",
      "multiSelect": false,
      "options": [
        { "label": "Blue (#3b82f6)", "description": "Professional, trustworthy (SaaS)" },
        { "label": "Purple (#8b5cf6)", "description": "Creative, innovative (design tools)" },
        { "label": "Green (#10b981)", "description": "Growth, success (fintech, health)" },
        { "label": "Custom hex code", "description": "Provide your brand color" }
      ]
    },
    {
      "question": "What is your project's visual style?",
      "header": "Style",
      "multiSelect": false,
      "options": [
        { "label": "Minimal (Stripe, Linear)", "description": "Clean, lots of whitespace, subtle shadows" },
        { "label": "Bold (Figma, Notion)", "description": "Strong colors, clear hierarchy, playful accents" },
        { "label": "Technical (Vercel, GitHub)", "description": "Monospace, dark themes, code-focused" }
      ]
    },
    {
      "question": "Primary font style?",
      "header": "Typography",
      "multiSelect": false,
      "options": [
        { "label": "Inter (geometric sans)", "description": "Modern, readable, web-optimized" },
        { "label": "Geist (humanist sans)", "description": "Vercel's font, technical elegance" },
        { "label": "System fonts", "description": "Native, fast loading" }
      ]
    }
  ]
}
```

#### Step 2.2: Generate OKLCH Palette

Based on user answers, generate full token structure using OKLCH color space:

**OKLCH Format**: `oklch(L% C H)` where:
- L = Lightness (0-100%)
- C = Chroma (0-0.4+, typically 0.0-0.25)
- H = Hue (0-360°)

**If primary=#3b82f6 (blue), style=Minimal**:

```json
{
  "meta": {
    "colorSpace": "oklch",
    "fallbackSpace": "srgb",
    "version": "2.0.0",
    "browserSupport": {
      "oklch": "92% (Chrome 111+, Safari 15.4+, Firefox 113+)",
      "fallback": "8% (legacy browsers)"
    }
  },
  "colors": {
    "brand": {
      "primary": {
        "oklch": "oklch(59.69% 0.156 261.45)",
        "fallback": "#3b82f6",
        "description": "Primary brand color"
      },
      "secondary": {
        "oklch": "oklch(58.23% 0.167 271.45)",
        "fallback": "#6366f1",
        "description": "Derived: primary + 10° hue shift"
      },
      "accent": {
        "oklch": "oklch(67.89% 0.152 164.57)",
        "fallback": "#10b981",
        "description": "Complementary green"
      }
    },
    "semantic": {
      "success": {
        "bg": {
          "oklch": "oklch(95% 0.02 145)",
          "fallback": "#D1FAE5"
        },
        "fg": {
          "oklch": "oklch(25% 0.12 145)",
          "fallback": "#047857"
        },
        "border": {
          "oklch": "oklch(85% 0.05 145)",
          "fallback": "#A7F3D0"
        },
        "icon": {
          "oklch": "oklch(35% 0.13 145)",
          "fallback": "#059669"
        }
      },
      "error": {
        "bg": {
          "oklch": "oklch(95% 0.02 27)",
          "fallback": "#FEE2E2"
        },
        "fg": {
          "oklch": "oklch(30% 0.18 27)",
          "fallback": "#991B1B"
        },
        "border": {
          "oklch": "oklch(85% 0.08 27)",
          "fallback": "#FECACA"
        },
        "icon": {
          "oklch": "oklch(40% 0.20 27)",
          "fallback": "#DC2626"
        }
      },
      "warning": {
        "bg": {
          "oklch": "oklch(95% 0.02 85)",
          "fallback": "#FEF3C7"
        },
        "fg": {
          "oklch": "oklch(30% 0.12 85)",
          "fallback": "#92400E"
        },
        "border": {
          "oklch": "oklch(85% 0.08 85)",
          "fallback": "#FDE68A"
        },
        "icon": {
          "oklch": "oklch(45% 0.14 85)",
          "fallback": "#F59E0B"
        }
      },
      "info": {
        "bg": {
          "oklch": "oklch(95% 0.02 261)",
          "fallback": "#DBEAFE"
        },
        "fg": {
          "oklch": "oklch(30% 0.12 261)",
          "fallback": "#1E3A8A"
        },
        "border": {
          "oklch": "oklch(85% 0.05 261)",
          "fallback": "#BFDBFE"
        },
        "icon": {
          "oklch": "oklch(59.69% 0.156 261.45)",
          "fallback": "#3b82f6"
        }
      }
    },
    "neutral": {
      "50": {
        "oklch": "oklch(98% 0 0)",
        "fallback": "#fafafa"
      },
      "100": {
        "oklch": "oklch(96% 0 0)",
        "fallback": "#f5f5f5"
      },
      "200": {
        "oklch": "oklch(90% 0 0)",
        "fallback": "#e5e5e5"
      },
      "400": {
        "oklch": "oklch(64% 0 0)",
        "fallback": "#a3a3a3"
      },
      "600": {
        "oklch": "oklch(42% 0 0)",
        "fallback": "#525252"
      },
      "800": {
        "oklch": "oklch(23% 0 0)",
        "fallback": "#262626"
      },
      "950": {
        "oklch": "oklch(11% 0 0)",
        "fallback": "#0a0a0a"
      }
    }
  },
  "focus": {
    "ring": {
      "width": "2px",
      "color": {
        "oklch": "oklch(59.69% 0.156 261.45)",
        "fallback": "#3b82f6"
      },
      "offset": "2px",
      "wcag": "WCAG 2.2 Focus Appearance 2.4.13 (3:1 minimum)"
    }
  },
  "motion": {
    "duration": {
      "instant": "0ms",
      "fast": "150ms",
      "base": "200ms",
      "slow": "300ms",
      "slower": "500ms"
    },
    "easing": {
      "standard": "cubic-bezier(0.4, 0.0, 0.2, 1)",
      "decelerate": "cubic-bezier(0.0, 0.0, 0.2, 1)",
      "accelerate": "cubic-bezier(0.4, 0.0, 1, 1)",
      "sharp": "cubic-bezier(0.4, 0.0, 0.6, 1)"
    },
    "reducedMotion": {
      "duration": "0ms",
      "easing": "linear",
      "mediaQuery": "@media (prefers-reduced-motion: reduce)"
    }
  },
  "dataViz": {
    "categorical": {
      "okabe-ito": {
        "orange": {
          "oklch": "oklch(68.29% 0.151 58.43)",
          "fallback": "#E69F00",
          "description": "Colorblind-safe orange"
        },
        "skyBlue": {
          "oklch": "oklch(70.17% 0.099 232.66)",
          "fallback": "#56B4E9",
          "description": "Colorblind-safe sky blue"
        },
        "bluishGreen": {
          "oklch": "oklch(59.78% 0.108 164.04)",
          "fallback": "#009E73",
          "description": "Colorblind-safe bluish green"
        },
        "yellow": {
          "oklch": "oklch(94.47% 0.152 102.85)",
          "fallback": "#F0E442",
          "description": "Colorblind-safe yellow"
        },
        "blue": {
          "oklch": "oklch(32.30% 0.115 264.05)",
          "fallback": "#0072B2",
          "description": "Colorblind-safe blue"
        },
        "vermillion": {
          "oklch": "oklch(54.72% 0.199 29.23)",
          "fallback": "#D55E00",
          "description": "Colorblind-safe vermillion"
        },
        "reddishPurple": {
          "oklch": "oklch(42.14% 0.152 327.11)",
          "fallback": "#CC79A7",
          "description": "Colorblind-safe reddish purple"
        },
        "black": {
          "oklch": "oklch(0% 0 0)",
          "fallback": "#000000",
          "description": "Colorblind-safe black"
        }
      }
    }
  }
}
```

**Automated WCAG Contrast Calculation** (using colorjs.io):

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

**Validation Output**:

```
✅ success.fg on success.bg: 10.23:1 (AAA) ✓
✅ error.fg on error.bg: 9.87:1 (AAA) ✓
✅ warning.fg on warning.bg: 8.45:1 (AAA) ✓
✅ info.fg on info.bg: 10.12:1 (AAA) ✓
✅ primary on white: 4.83:1 (AA for large text)
⚠️ primary on neutral-200: Adjusted to ensure 4.5:1 minimum
```

**Semantic Token Structure**:
- `.bg` = Background (paint, large areas)
- `.fg` = Foreground/Text (ink, readable text)
- `.border` = Border/Outline (edges, dividers)
- `.icon` = Icon/Glyph fill (visual indicators)

#### Step 2.3: Typography Scale

Generate type scale based on font choice, including OpenType features:

```json
{
  "typography": {
    "families": {
      "sans": "Inter, system-ui, -apple-system, sans-serif",
      "mono": "Fira Code, Consolas, monospace"
    },
    "sizes": {
      "xs": "0.75rem",   // 12px
      "sm": "0.875rem",  // 14px
      "base": "1rem",    // 16px
      "lg": "1.125rem",  // 18px
      "xl": "1.25rem",   // 20px
      "2xl": "1.5rem",   // 24px
      "3xl": "1.875rem", // 30px
      "4xl": "2.25rem"   // 36px
    },
    "weights": {
      "normal": "400",
      "medium": "500",
      "semibold": "600",
      "bold": "700"
    },
    "lineHeights": {
      "tight": "1.25",
      "snug": "1.375",
      "normal": "1.5",
      "relaxed": "1.625",
      "loose": "2"
    },
    "letterSpacing": {
      "tighter": "-0.05em",
      "tight": "-0.025em",
      "normal": "0",
      "wide": "0.025em",
      "wider": "0.05em"
    },
    "features": {
      "tabular": {
        "property": "font-variant-numeric",
        "value": "tabular-nums",
        "description": "Monospaced numbers for tables/dashboards",
        "useCase": "Financial data, metrics, comparison tables"
      },
      "slashedZero": {
        "property": "font-variant-numeric",
        "value": "slashed-zero",
        "description": "Slashed zero for O/0 clarity",
        "useCase": "API keys, serial numbers, technical documentation"
      },
      "oldstyle": {
        "property": "font-variant-numeric",
        "value": "oldstyle-nums",
        "description": "Lowercase numbers for body text",
        "useCase": "Editorial content, long-form text"
      },
      "lining": {
        "property": "font-variant-numeric",
        "value": "lining-nums",
        "description": "All-caps numbers for headings",
        "useCase": "Headlines, UI labels, buttons"
      },
      "proportional": {
        "property": "font-variant-numeric",
        "value": "proportional-nums",
        "description": "Variable-width numbers for body text",
        "useCase": "Paragraphs, narrative content"
      }
    }
  }
}
```

---

### Phase 3: Elevation & Effects

**Add elevation scale with light/dark mode shadows** (from design-principles.md):

```json
{
  "shadows": {
    "light": {
      "none": "none",
      "sm": {
        "value": "0 1px 2px oklch(0% 0 0 / 0.05)",
        "fallback": "0 1px 2px rgba(0, 0, 0, 0.05)"
      },
      "md": {
        "value": "0 4px 6px oklch(0% 0 0 / 0.07), 0 2px 4px oklch(0% 0 0 / 0.06)",
        "fallback": "0 4px 6px rgba(0, 0, 0, 0.07), 0 2px 4px rgba(0, 0, 0, 0.06)"
      },
      "lg": {
        "value": "0 10px 15px oklch(0% 0 0 / 0.1), 0 4px 6px oklch(0% 0 0 / 0.08)",
        "fallback": "0 10px 15px rgba(0, 0, 0, 0.1), 0 4px 6px rgba(0, 0, 0, 0.08)"
      },
      "xl": {
        "value": "0 20px 25px oklch(0% 0 0 / 0.12), 0 10px 10px oklch(0% 0 0 / 0.08)",
        "fallback": "0 20px 25px rgba(0, 0, 0, 0.12), 0 10px 10px rgba(0, 0, 0, 0.08)"
      },
      "2xl": {
        "value": "0 25px 50px oklch(0% 0 0 / 0.15), 0 12px 20px oklch(0% 0 0 / 0.12)",
        "fallback": "0 25px 50px rgba(0, 0, 0, 0.15), 0 12px 20px rgba(0, 0, 0, 0.12)"
      }
    },
    "dark": {
      "none": "none",
      "sm": {
        "value": "0 1px 2px oklch(0% 0 0 / 0.30)",
        "fallback": "0 1px 2px rgba(0, 0, 0, 0.30)",
        "rationale": "6x opacity increase (0.05 → 0.30) for depth in dark backgrounds"
      },
      "md": {
        "value": "0 4px 6px oklch(0% 0 0 / 0.35), 0 2px 4px oklch(0% 0 0 / 0.30)",
        "fallback": "0 4px 6px rgba(0, 0, 0, 0.35), 0 2px 4px rgba(0, 0, 0, 0.30)",
        "rationale": "5x opacity increase (0.07 → 0.35, 0.06 → 0.30)"
      },
      "lg": {
        "value": "0 10px 15px oklch(0% 0 0 / 0.40), 0 4px 6px oklch(0% 0 0 / 0.32)",
        "fallback": "0 10px 15px rgba(0, 0, 0, 0.40), 0 4px 6px rgba(0, 0, 0, 0.32)",
        "rationale": "4x opacity increase (0.1 → 0.40, 0.08 → 0.32)"
      },
      "xl": {
        "value": "0 20px 25px oklch(0% 0 0 / 0.48), 0 10px 10px oklch(0% 0 0 / 0.32)",
        "fallback": "0 20px 25px rgba(0, 0, 0, 0.48), 0 10px 10px rgba(0, 0, 0, 0.32)",
        "rationale": "4x opacity increase (0.12 → 0.48, 0.08 → 0.32)"
      },
      "2xl": {
        "value": "0 25px 50px oklch(0% 0 0 / 0.60), 0 12px 20px oklch(0% 0 0 / 0.48)",
        "fallback": "0 25px 50px rgba(0, 0, 0, 0.60), 0 12px 20px rgba(0, 0, 0, 0.48)",
        "rationale": "4x opacity increase (0.15 → 0.60, 0.12 → 0.48)"
      }
    }
  },
  "elevations": {
    "z-0": "Base layer (page background)",
    "z-1": "Slightly raised (cards, inputs)",
    "z-2": "Raised (hover states, active cards)",
    "z-3": "Floating (dropdowns, popovers)",
    "z-4": "Modal content",
    "z-5": "Tooltips, top-level modals"
  }
}
```

**Add subtle gradient presets**:

```json
{
  "gradients": {
    "subtle-vertical": "linear-gradient(to bottom, var(--color-neutral-50), var(--color-neutral-100))",
    "subtle-radial": "radial-gradient(circle at top, var(--color-primary)/5, transparent)",
    "accent-wash": "linear-gradient(to bottom, var(--color-primary)/5, var(--color-primary)/15)",
    "glass": "linear-gradient(135deg, rgba(255,255,255,0.1), rgba(255,255,255,0.05))"
  },
  "gradientRules": {
    "maxStops": 2,
    "maxOpacityDelta": "20%",
    "preferredAngles": ["to bottom", "to top", "to right", "to left"],
    "avoidDiagonals": true
  }
}
```

---

### Phase 4: Tailwind Integration

#### Step 4.1: Validate Tailwind Config

Read `tailwind.config.js` or `tailwind.config.ts`:

```javascript
// Expected structure
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: 'var(--color-primary)',
        secondary: 'var(--color-secondary)',
        // ... should import from tokens.json
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        // ... should match typography.families
      }
    }
  }
}
```

**Validation checks**:
- [ ] Config file exists
- [ ] Colors defined in `theme.extend.colors`
- [ ] Colors use CSS variables (`var(--color-*)`) or direct token imports
- [ ] Font families match tokens.json
- [ ] Box shadow scale matches elevation scale

**If validation fails**:

```
⚠️ Tailwind config issues detected:

1. tailwind.config.js not found
   → Create config with: npx tailwindcss init

2. Colors not using CSS variables
   → Update theme.extend.colors to use var(--color-primary)

3. Shadow scale incomplete
   → Add boxShadow: { sm, md, lg, xl, 2xl } from tokens.json

Run /fix-tailwind-config to auto-correct
```

#### Step 4.2: Generate CSS Variables with OKLCH

Create `design/systems/tokens.css`:

```css
:root {
  /* Brand colors (OKLCH with sRGB fallback) */
  --color-primary: oklch(59.69% 0.156 261.45);
  --color-primary-fallback: #3b82f6;
  --color-secondary: oklch(58.23% 0.167 271.45);
  --color-secondary-fallback: #6366f1;
  --color-accent: oklch(67.89% 0.152 164.57);
  --color-accent-fallback: #10b981;

  /* Semantic colors (bg/fg/border/icon structure) */
  --color-success-bg: oklch(95% 0.02 145);
  --color-success-fg: oklch(25% 0.12 145);
  --color-success-border: oklch(85% 0.05 145);
  --color-success-icon: oklch(35% 0.13 145);

  --color-error-bg: oklch(95% 0.02 27);
  --color-error-fg: oklch(30% 0.18 27);
  --color-error-border: oklch(85% 0.08 27);
  --color-error-icon: oklch(40% 0.20 27);

  --color-warning-bg: oklch(95% 0.02 85);
  --color-warning-fg: oklch(30% 0.12 85);
  --color-warning-border: oklch(85% 0.08 85);
  --color-warning-icon: oklch(45% 0.14 85);

  --color-info-bg: oklch(95% 0.02 261);
  --color-info-fg: oklch(30% 0.12 261);
  --color-info-border: oklch(85% 0.05 261);
  --color-info-icon: oklch(59.69% 0.156 261.45);

  /* Neutral palette */
  --color-neutral-50: oklch(98% 0 0);
  --color-neutral-100: oklch(96% 0 0);
  --color-neutral-200: oklch(90% 0 0);
  --color-neutral-400: oklch(64% 0 0);
  --color-neutral-600: oklch(42% 0 0);
  --color-neutral-800: oklch(23% 0 0);
  --color-neutral-950: oklch(11% 0 0);

  /* Focus tokens (WCAG 2.2) */
  --focus-ring-width: 2px;
  --focus-ring-color: oklch(59.69% 0.156 261.45);
  --focus-ring-offset: 2px;

  /* Motion tokens */
  --motion-duration-instant: 0ms;
  --motion-duration-fast: 150ms;
  --motion-duration-base: 200ms;
  --motion-duration-slow: 300ms;
  --motion-duration-slower: 500ms;

  --motion-easing-standard: cubic-bezier(0.4, 0.0, 0.2, 1);
  --motion-easing-decelerate: cubic-bezier(0.0, 0.0, 0.2, 1);
  --motion-easing-accelerate: cubic-bezier(0.4, 0.0, 1, 1);
  --motion-easing-sharp: cubic-bezier(0.4, 0.0, 0.6, 1);

  /* Typography */
  --font-sans: Inter, system-ui, -apple-system, sans-serif;
  --font-mono: Fira Code, Consolas, monospace;

  /* Typography features */
  --font-feature-tabular: "tnum" on;
  --font-feature-slashed-zero: "zero" on;
  --font-feature-oldstyle: "onum" on;
  --font-feature-lining: "lnum" on;

  /* Spacing (8px grid) */
  --spacing-1: 0.25rem;  /* 4px */
  --spacing-2: 0.5rem;   /* 8px */
  /* ... */

  /* Shadows - Light mode (elevation) */
  --shadow-sm: 0 1px 2px oklch(0% 0 0 / 0.05);
  --shadow-md: 0 4px 6px oklch(0% 0 0 / 0.07), 0 2px 4px oklch(0% 0 0 / 0.06);
  --shadow-lg: 0 10px 15px oklch(0% 0 0 / 0.1), 0 4px 6px oklch(0% 0 0 / 0.08);
  --shadow-xl: 0 20px 25px oklch(0% 0 0 / 0.12), 0 10px 10px oklch(0% 0 0 / 0.08);
  --shadow-2xl: 0 25px 50px oklch(0% 0 0 / 0.15), 0 12px 20px oklch(0% 0 0 / 0.12);
}

/* Dark mode shadows (3-6x opacity increase) */
@media (prefers-color-scheme: dark) {
  :root {
    --shadow-sm: 0 1px 2px oklch(0% 0 0 / 0.30);
    --shadow-md: 0 4px 6px oklch(0% 0 0 / 0.35), 0 2px 4px oklch(0% 0 0 / 0.30);
    --shadow-lg: 0 10px 15px oklch(0% 0 0 / 0.40), 0 4px 6px oklch(0% 0 0 / 0.32);
    --shadow-xl: 0 20px 25px oklch(0% 0 0 / 0.48), 0 10px 10px oklch(0% 0 0 / 0.32);
    --shadow-2xl: 0 25px 50px oklch(0% 0 0 / 0.60), 0 12px 20px oklch(0% 0 0 / 0.48);
  }
}

/* Reduced motion (accessibility) */
@media (prefers-reduced-motion: reduce) {
  :root {
    --motion-duration-instant: 0ms;
    --motion-duration-fast: 0ms;
    --motion-duration-base: 0ms;
    --motion-duration-slow: 0ms;
    --motion-duration-slower: 0ms;
    --motion-easing-standard: linear;
    --motion-easing-decelerate: linear;
    --motion-easing-accelerate: linear;
    --motion-easing-sharp: linear;
  }
}

/* OKLCH fallback for legacy browsers (8%) */
@supports not (color: oklch(0% 0 0)) {
  :root {
    --color-primary: var(--color-primary-fallback);
    --color-secondary: var(--color-secondary-fallback);
    --color-accent: var(--color-accent-fallback);
    /* Add fallbacks for all OKLCH colors */
  }
}
```

**Import instruction**:

Add to `app/globals.css` or `styles/globals.css`:

```css
@import './design/systems/tokens.css';
```

---

### Phase 5: Hardcoded Value Detection

**Scan codebase for violations**:

```bash
echo "🔍 Scanning for hardcoded values..."

# Find hardcoded colors
grep -rn "#[0-9a-fA-F]\{6\}" src/ app/ components/ --include="*.tsx" --include="*.jsx" > violations-colors.txt

# Find non-token classes
grep -rn "bg-\[#\|text-\[#\|border-\[#" src/ app/ components/ --include="*.tsx" --include="*.jsx" > violations-arbitrary.txt

# Count violations
COLOR_COUNT=$(wc -l < violations-colors.txt)
ARBITRARY_COUNT=$(wc -l < violations-arbitrary.txt)
TOTAL=$((COLOR_COUNT + ARBITRARY_COUNT))
```

**Report violations**:

```
⚠️ Found ${TOTAL} hardcoded values in codebase:

Hardcoded hex colors: ${COLOR_COUNT}
  - src/components/Button.tsx:42: backgroundColor: '#3b82f6'
  - app/dashboard/page.tsx:18: className="bg-[#ffffff]"

Arbitrary Tailwind values: ${ARBITRARY_COUNT}
  - components/Card.tsx:12: className="p-[15px]"
  - components/Modal.tsx:8: className="shadow-[0_4px_8px_rgba(0,0,0,0.1)]"

Recommendation:
  1. Replace hardcoded colors with token references
  2. Use standard spacing scale (p-4 instead of p-[15px])
  3. Use elevation scale (shadow-md instead of arbitrary shadow)

Run /migrate-to-tokens to auto-fix (creates PR with changes)
```

---

## Output Artifacts

### 1. `design/systems/tokens.json`

**Full token structure** (see template in Phase 2.2, 2.3, Phase 3)

### 2. `design/systems/tokens.css`

**CSS variables** (see Phase 4.2)

### 3. `design/systems/token-analysis-report.md` (Brownfield only)

**Codebase scan results**:
- Detected patterns with frequency
- Consolidation suggestions
- Before/after diff

### 4. `design/systems/token-migration-guide.md`

**Developer guide**:

```markdown
# Token Migration Guide

## Quick Reference

### Colors
- Hardcoded: `#3b82f6` → Token: `bg-primary` or `var(--color-primary)`
- Tailwind arbitrary: `bg-[#3b82f6]` → Token: `bg-primary`

### Spacing
- Hardcoded: `padding: 15px` → Token: `p-4` (16px)
- Arbitrary: `p-[15px]` → Token: `p-4`

### Shadows
- Hardcoded: `box-shadow: 0 4px 8px rgba(0,0,0,0.1)` → Token: `shadow-md`
- Arbitrary: `shadow-[0_4px_8px_rgba(0,0,0,0.1)]` → Token: `shadow-md`

## Migration Steps

1. **Find all violations**:
   ```bash
   grep -rn "#[0-9a-fA-F]{6}" src/ app/ components/
   ```

2. **Replace with tokens**:
   - Use design/systems/tokens.json as reference
   - Match closest semantic token (not just visual match)
   - Prefer CSS variables for dynamic values

3. **Validate**:
   ```bash
   npm run lint
   npm run test
   ```

4. **Design lint**:
   ```bash
   node .spec-flow/scripts/design-lint.js
   ```

## Before/After Examples

### Button Component

**Before**:
```tsx
<button
  className="px-6 py-3"
  style={{ backgroundColor: '#3b82f6', color: '#ffffff' }}
>
  Save
</button>
```

**After**:
```tsx
<button className="px-6 py-3 bg-primary text-white shadow-sm hover:shadow-md">
  Save
</button>
```

### Card Component

**Before**:
```tsx
<div
  className="p-[20px] rounded-lg"
  style={{
    backgroundColor: '#ffffff',
    boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
    border: '1px solid #e5e5e5'
  }}
>
  {children}
</div>
```

**After** (following design principles):
```tsx
<div className="p-5 rounded-lg bg-white shadow-md">
  {children}
</div>
```

Note: Border removed (use shadow for depth per design-principles.md)
```

---

## Quality Gates

**Before proceeding to next phase**:

- [ ] `tokens.json` generated with all sections (colors, typography, spacing, shadows, gradients)
- [ ] CSS variables file created (`tokens.css`)
- [ ] Tailwind config validated (imports tokens correctly)
- [ ] Brownfield: Hardcoded values detected and reported (<100 violations allowed, else block)
- [ ] Greenfield: All colors pass WCAG AA minimum (4.5:1 for text)
- [ ] Migration guide generated
- [ ] User confirmed token structure (brownfield: interactive refinement, greenfield: guided setup)

**Blocks design workflow if**:
- Tailwind config broken (syntax errors)
- WCAG AAA contrast failures on primary text colors (7:1 required)
- >200 hardcoded violations in brownfield (too risky to proceed, must migrate first)

**Warnings (non-blocking)**:
- <100 hardcoded violations (suggest migration, allow continue)
- Some colors only meet AA (4.5:1), not AAA (7:1)
- Custom font families not web-optimized (suggest Inter, Geist, or system fonts)

---

## Usage Examples

### First-time greenfield project

```bash
/init-brand-tokens

# Prompts:
# - Primary color? (Blue/Purple/Green/Custom)
# - Visual style? (Minimal/Bold/Technical)
# - Font? (Inter/Geist/System)

# Generates:
# - design/systems/tokens.json
# - design/systems/tokens.css
# - design/systems/token-migration-guide.md

# Output:
✅ Brand tokens initialized
📦 12 color tokens, 8 font sizes, 13 spacing values
🎨 Tailwind config validated
📖 Next: Run /design to create UI variants
```

### Brownfield project with existing styles

```bash
/init-brand-tokens

# Scans codebase...
📊 Found 47 colors, 14 font sizes, 23 spacing values
💡 Recommend consolidating to 12 + 8 + 13 tokens

# Prompts:
# - Confirm primary color #3b82f6? (Yes/Change/Custom)
# - Confirm fonts Inter + Fira Code? (Yes/Change)

# Generates:
# - design/systems/detected-tokens.json (raw scan)
# - design/systems/tokens.json (consolidated)
# - design/systems/token-analysis-report.md
# - design/systems/token-migration-guide.md

⚠️ Found 47 hardcoded values in codebase
📖 See token-migration-guide.md for migration steps
🔧 Run /migrate-to-tokens to auto-fix

# Output:
✅ Tokens initialized from existing codebase
📊 Before: 47 colors → After: 12 tokens (74% reduction)
🎨 Tailwind config validated
⚠️ 47 hardcoded values detected (suggest migration)
```

### Update existing tokens

```bash
/init-brand-tokens

# Detects existing tokens.json
📦 Existing tokens detected

# Prompts:
# 1. Update tokens (scan for new patterns)
# 2. Regenerate tokens (start fresh)
# 3. Keep existing (exit)

# If option 1:
🔍 Scanning for new patterns...
📊 Found 8 new colors, 2 new spacing values
💡 Suggest adding to tokens.json

# Shows diff and prompts confirmation
```

---

## Success Criteria

**Quantitative**:
- Token coverage: ≥95% of colors use tokens (≤5% hardcoded)
- WCAG AAA: ≥80% of text elements (7:1 contrast)
- Token consolidation: Reduce unique values by ≥60% (brownfield)
- Tailwind config: 100% of tokens imported correctly

**Qualitative**:
- Developer feedback: "Clear migration guide"
- Design critique: "Consistent color usage"
- User testing: "High contrast, readable"
- Automated: Design lint <5 warnings per file

---

**Related Commands**:
- `/design` — Use tokens during variant generation
- `/migrate-to-tokens` — Auto-fix hardcoded values
- `/design-lint` — Validate token usage

**Agent**: Design System Architect (`no specific agent, run in main instance`)

**Estimated Duration**: 15-30 minutes (brownfield), 10-15 minutes (greenfield)
