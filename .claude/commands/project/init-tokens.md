---
name: init-brand-tokens
description: Generate OKLCH design tokens with WCAG validation, shadcn/ui integration, and Tailwind v4 theming via 8 customization questions
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash(node *), Bash(pnpm *), Bash(npm *), Bash(npx *), Bash(git rev-parse:*), AskUserQuestion]
argument-hint: [--from-prototype | --shadcn] (optional flags)
---

# /init-brand-tokens — Design System Token Generation

<context>
**Git Root**: !`git rev-parse --show-toplevel 2>/dev/null || echo "."`

**Existing Tokens**: !`test -f design/systems/tokens.json && echo "exists" || echo "missing"`

**Tailwind Config**: !`test -f tailwind.config.js && echo "found (js)" || test -f tailwind.config.ts && echo "found (ts)" || echo "missing"`

**Node Version**: !`node --version 2>/dev/null || echo "not installed"`

**Project Mode**: !`test -d app -o -d src -o -d components && echo "brownfield (UI exists)" || echo "greenfield (new project)"`

**Reference Documentation**: @.claude/skills/design-tokens/SKILL.md
</context>

<objective>
Initialize design system tokens in `design/systems/tokens.json` and `tokens.css` using OKLCH color space with WCAG 2.1 AA contrast validation. Optionally generates shadcn/ui-compatible `components.json` and CSS variable aliases.

**Modes**:
- **Brownfield**: Scan existing code (UI, emails, PDFs, CLI, charts, docs) for color/type/spacing patterns, consolidate duplicates
- **Greenfield**: Ask 8 customization questions, generate new OKLCH palette with semantic tokens + shadcn integration
- **From Prototype** (--from-prototype): Extract and formalize colors from discovery prototype's theme.yaml
- **shadcn Integration** (--shadcn): Generate shadcn/ui-compatible configuration alongside OKLCH tokens

**When to use**:
- During `/init-project`, before first `/design`
- After `/prototype discover` to formalize quick-picked palette
- When migrating ad-hoc styles to systematic tokens
- When setting up shadcn/ui components with custom theming

**Surfaces covered**: UI components, MJML/HTML emails, PDF styling, CLI colors, data viz, docs, discovery prototypes, shadcn/ui components
</objective>

## Anti-Hallucination Rules

1. **Never run script without checking dependencies**
   - Verify Node.js installed with `node --version`
   - Check colorjs.io, picocolors, fs-extra in package.json
   - If missing, install with: `pnpm add -D colorjs.io picocolors fs-extra`

2. **Always read generated artifacts before confirming**
   - Read design/systems/tokens.json after generation
   - Read design/systems/tokens.css after generation
   - Quote actual token values when presenting results

3. **Verify Tailwind wiring validation results**
   - Don't claim success without reading validation output
   - Report actual errors/warnings from script
   - Quote file paths for any wiring issues found

4. **Check for existing tokens before regenerating**
   - If tokens.json exists, ask user: update, regenerate, or keep existing
   - Never overwrite without confirmation

---

## shadcn/ui Customization Questions (8 Total)

When in greenfield mode or when `--shadcn` flag is provided, ask these 8 questions to generate a complete design system:

### Question 1: Style Preset
```json
{
  "question": "Visual style preset?",
  "header": "Style",
  "multiSelect": false,
  "options": [
    {"label": "Default (Recommended)", "description": "Clean, balanced - shadcn 'default' style, comfortable density"},
    {"label": "New York", "description": "Refined, sophisticated - shadcn 'new-york' style"},
    {"label": "Minimal", "description": "Ultra-clean, lots of whitespace - spacious density"},
    {"label": "Bold", "description": "Strong visual presence - compact density"}
  ]
}
```

### Question 2: Base Color (Primary Brand Hue)
```json
{
  "question": "Primary brand color?",
  "header": "Base Color",
  "multiSelect": false,
  "options": [
    {"label": "Blue (Recommended)", "description": "Trust, tech, professional - OKLCH hue 250"},
    {"label": "Purple", "description": "Creative, premium - OKLCH hue 285"},
    {"label": "Green", "description": "Growth, eco, finance - OKLCH hue 150"},
    {"label": "Orange", "description": "Energy, friendly - OKLCH hue 50"},
    {"label": "Red", "description": "Bold, urgent - OKLCH hue 25"},
    {"label": "Custom", "description": "Enter custom OKLCH hue value (0-360)"}
  ]
}
```

### Question 3: Theme Mode
```json
{
  "question": "Theme mode support?",
  "header": "Theme",
  "multiSelect": false,
  "options": [
    {"label": "System preference (Recommended)", "description": "Follow OS light/dark setting"},
    {"label": "Light only", "description": "Light background, dark text only"},
    {"label": "Dark only", "description": "Dark background, light text only"},
    {"label": "User toggleable", "description": "Both modes with manual toggle"}
  ]
}
```

### Question 4: Icon Library
```json
{
  "question": "Icon library?",
  "header": "Icons",
  "multiSelect": false,
  "options": [
    {"label": "Lucide (Recommended)", "description": "Clean line icons, shadcn default - lucide-react"},
    {"label": "Heroicons", "description": "Solid + outline variants - @heroicons/react"},
    {"label": "Phosphor", "description": "6 weight variants - @phosphor-icons/react"}
  ]
}
```

### Question 5: Font Family
```json
{
  "question": "Primary font family?",
  "header": "Font",
  "multiSelect": false,
  "options": [
    {"label": "Inter (Recommended)", "description": "Modern sans-serif, excellent readability"},
    {"label": "Geist", "description": "Vercel's modern font family"},
    {"label": "Plus Jakarta Sans", "description": "Geometric, friendly character"},
    {"label": "System default", "description": "Use OS system font stack"}
  ]
}
```

### Question 6: Border Radius
```json
{
  "question": "Border radius style?",
  "header": "Radius",
  "multiSelect": false,
  "options": [
    {"label": "Medium (Recommended)", "description": "Modern, balanced - 8px/0.5rem"},
    {"label": "None", "description": "Brutalist, stark - 0"},
    {"label": "Small", "description": "Minimal, technical - 4px/0.25rem"},
    {"label": "Large", "description": "Friendly, soft - 12px/0.75rem"},
    {"label": "Full", "description": "Playful, pill-shaped - 9999px"}
  ]
}
```

### Question 7: Menu Color
```json
{
  "question": "Menu background style?",
  "header": "Menu Color",
  "multiSelect": false,
  "options": [
    {"label": "Background (Recommended)", "description": "Uses page background color"},
    {"label": "Surface elevated", "description": "Slightly elevated card style with shadow"},
    {"label": "Primary tint", "description": "Subtle primary color wash (5% opacity)"},
    {"label": "Glass effect", "description": "Transparent with backdrop blur"}
  ]
}
```

### Question 8: Menu Accent
```json
{
  "question": "Menu active indicator style?",
  "header": "Menu Accent",
  "multiSelect": false,
  "options": [
    {"label": "Left border (Recommended)", "description": "3px border-left on active items"},
    {"label": "Background highlight", "description": "Full background color on active"},
    {"label": "Icon tint", "description": "Only icon changes to primary color"},
    {"label": "Combined", "description": "Border + subtle background highlight"}
  ]
}
```

---

<process>

### Step 1: Check Prerequisites

1. Verify Node.js installed
2. Check for required dependencies in package.json
3. If missing, install: `pnpm add -D colorjs.io picocolors fs-extra`
4. Navigate to git root

### Step 2: Detect Mode

**Check for flags first:**
```bash
# If --from-prototype flag provided
if [[ "$ARGUMENTS" == *"--from-prototype"* ]]; then
    MODE="prototype"
    # Check prototype exists
    test -f design/prototype/theme.yaml || echo "ERROR: No prototype theme. Run '/prototype discover' first."
fi

# If --shadcn flag provided
if [[ "$ARGUMENTS" == *"--shadcn"* ]]; then
    SHADCN_MODE="true"
    # Will ask 8 customization questions and generate components.json
fi
```

**Auto-detection (if no flag):**
- Prototype: `design/prototype/theme.yaml` exists and user confirms
- Greenfield: No `app/`, `src/`, or `components/` directories
- Brownfield: Directories exist + contains hex colors or arbitrary Tailwind values

**If tokens.json exists**:
- Ask user: Update tokens (scan for new patterns), Regenerate (start fresh), or Keep existing

**If prototype theme.yaml exists (and no --from-prototype):**
```json
{
  "question": "Found discovery prototype with palette. Use it as base for tokens?",
  "header": "Source",
  "multiSelect": false,
  "options": [
    {"label": "Yes, use prototype palette", "description": "Formalize quick-picked colors with WCAG validation"},
    {"label": "No, start fresh", "description": "Ignore prototype, generate new palette"},
    {"label": "Scan codebase", "description": "Brownfield scan of existing code"}
  ]
}
```

### Step 3: Execute Token Generation

**If MODE = "prototype" (--from-prototype):**

1. **Read prototype theme.yaml:**
   ```bash
   cat design/prototype/theme.yaml
   ```

2. **Extract palette values:**
   - Read `theme.palette.primary`, `secondary`, `accent`
   - Read semantic colors (success, warning, error, info)
   - Read neutral scale
   - Note the "vibe" for metadata

3. **Validate WCAG contrast:**
   - Test each color pair for 4.5:1 contrast ratio
   - Auto-adjust lightness if contrast fails
   - Report adjustments made

4. **Generate production tokens:**
   - Write to `design/systems/tokens.json`
   - Add metadata: `source: "prototype"`, `vibe: "[VIBE]"`
   - Include sRGB fallbacks for each OKLCH color

5. **Sync back to prototype:**
   - Update `design/prototype/theme.yaml` to reference system tokens
   - Set `extends: "../systems/tokens.css"`
   - Preserve any prototype-specific overrides

6. **Display summary:**
   ```
   ✅ Tokens extracted from prototype

   Source: design/prototype/theme.yaml (Modern SaaS vibe)

   Colors formalized:
     Primary:   oklch(55% 0.2 270) → oklch(52% 0.2 270) [adjusted for contrast]
     Secondary: oklch(60% 0.15 300) [no change]
     Accent:    oklch(70% 0.18 180) [no change]

   WCAG Validation:
     ✓ All text pairs meet 4.5:1 contrast
     ⚠ 2 colors adjusted for accessibility

   Generated:
     • design/systems/tokens.json
     • design/systems/tokens.css

   Prototype updated to use system tokens.
   ```

**If MODE = "brownfield" or "greenfield":**

Run the orchestrator script:
```bash
node .spec-flow/scripts/init-brand-tokens.mjs
```

**Script operations** (automated):
1. Detect mode (brownfield vs greenfield)
2. Scan existing code for patterns (brownfield) OR ask minimal questions (greenfield)
3. Consolidate to semantic tokens (colors, typography, spacing, shadows, motion, data viz)
4. WCAG contrast validation + auto-fix (≥4.5:1 ratio)
5. Emit tokens.json and tokens.css artifacts
6. Validate Tailwind v4 wiring
7. Report style debt (hardcoded colors, arbitrary Tailwind values)

### Step 4: shadcn/ui Integration (if --shadcn or greenfield)

**Ask 8 customization questions** (see questions above):
1. Style preset → determines shadcn style + density
2. Base color → generates OKLCH primary scale
3. Theme mode → configures light/dark CSS variables
4. Icon library → sets iconLibrary in components.json
5. Font family → configures next/font in layout.tsx
6. Border radius → sets --radius CSS variable
7. Menu color → generates menu background tokens
8. Menu accent → generates menu active state tokens

**Generate shadcn-compatible configuration:**

1. **Create components.json** (project root):
```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "{style_preset}",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "app/globals.css",
    "baseColor": "neutral",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  },
  "iconLibrary": "{icon_library}"
}
```

2. **Add shadcn variable aliases to tokens.css**:
```css
/* shadcn/ui CSS Variable Aliases */
/* Maps OKLCH tokens to shadcn expected variables */

:root {
  /* Core colors */
  --background: var(--color-neutral-50);
  --foreground: var(--color-neutral-900);
  --card: var(--color-neutral-50);
  --card-foreground: var(--color-neutral-900);
  --popover: var(--color-neutral-50);
  --popover-foreground: var(--color-neutral-900);
  --primary: var(--color-primary-600);
  --primary-foreground: var(--color-neutral-50);
  --secondary: var(--color-neutral-100);
  --secondary-foreground: var(--color-neutral-900);
  --muted: var(--color-neutral-100);
  --muted-foreground: var(--color-neutral-500);
  --accent: var(--color-neutral-100);
  --accent-foreground: var(--color-neutral-900);
  --destructive: var(--color-error-600);
  --destructive-foreground: var(--color-neutral-50);
  --border: var(--color-neutral-200);
  --input: var(--color-neutral-200);
  --ring: var(--color-primary-600);
  --radius: {border_radius};

  /* Menu-specific (custom extension) */
  --menu: var(--color-menu-background);
  --menu-hover: var(--color-menu-hover);
  --menu-active: var(--color-menu-active);
  --menu-accent: var(--color-menu-accent);
}

/* Dark mode */
.dark {
  --background: var(--color-neutral-950);
  --foreground: var(--color-neutral-50);
  --card: var(--color-neutral-900);
  --card-foreground: var(--color-neutral-50);
  --popover: var(--color-neutral-900);
  --popover-foreground: var(--color-neutral-50);
  --primary: var(--color-primary-500);
  --primary-foreground: var(--color-neutral-950);
  --secondary: var(--color-neutral-800);
  --secondary-foreground: var(--color-neutral-50);
  --muted: var(--color-neutral-800);
  --muted-foreground: var(--color-neutral-400);
  --accent: var(--color-neutral-800);
  --accent-foreground: var(--color-neutral-50);
  --destructive: var(--color-error-500);
  --destructive-foreground: var(--color-neutral-50);
  --border: var(--color-neutral-800);
  --input: var(--color-neutral-800);
  --ring: var(--color-primary-500);
}
```

3. **Generate menu tokens in tokens.json** based on menu_color and menu_accent choices.

4. **Install icon library dependency**:
```bash
# Based on icon_library choice
pnpm add lucide-react        # if Lucide
pnpm add @heroicons/react    # if Heroicons
pnpm add @phosphor-icons/react  # if Phosphor
```

5. **Configure next/font in app/layout.tsx** (if Next.js detected):
```typescript
import { Inter } from 'next/font/google'  // or Geist, Plus_Jakarta_Sans

const fontSans = Inter({
  subsets: ['latin'],
  variable: '--font-sans',
})
```

### Step 5: Review Generated Artifacts

**Read and present**:
- `design/systems/tokens.json` - Token definitions with OKLCH and sRGB fallbacks
- `design/systems/tokens.css` - CSS variables for all tokens (including shadcn aliases)
- `components.json` - shadcn/ui configuration (if --shadcn)
- `design/systems/violations-colors.txt` - Hardcoded hex colors (if brownfield)
- `design/systems/violations-arbitrary.txt` - Arbitrary Tailwind values (if brownfield)

### Step 6: Validate Tailwind Wiring

**Checks performed**:
- Tailwind config exists
- `globals.css` imports `design/systems/tokens.css`
- Colors use CSS variables (not hardcoded)
- Contrast ratios meet WCAG 2.1 AA (≥4.5:1)

**Report validation status**: Pass/warnings/errors

### Step 7: Display Next Steps

```
✅ Token initialization complete

Generated artifacts:
  - design/systems/tokens.json (token definitions)
  - design/systems/tokens.css (CSS variables + shadcn aliases)
  {If --shadcn}
  - components.json (shadcn/ui configuration)
  - Icon library: {icon_library} installed
  - Font: {font_family} configured in layout.tsx

{If --shadcn}
shadcn/ui Integration:
  Style:    {style_preset}
  Radius:   {border_radius}
  Theme:    {theme_mode}
  Menu:     {menu_color} background, {menu_accent} accent

  Ready to add components:
    npx shadcn@latest add button
    npx shadcn@latest add card
    npx shadcn@latest add dropdown-menu

{If brownfield}
Style debt detected:
  - {N} hardcoded hex colors
  - {M} arbitrary Tailwind values
  - See violations-colors.txt and violations-arbitrary.txt

Next steps:
  1. Review design/systems/tokens.json
  2. Import tokens.css in your globals.css
  3. Run 'pnpm run tokens:validate' to check wiring
  4. {If --shadcn} Add shadcn components: npx shadcn@latest add [component]
  5. {If brownfield} Migrate top offenders (see SKILL.md migration guides)

Tailwind wiring: {PASS|WARN|FAIL}
{List any warnings or errors}
```

</process>

<success_criteria>
**Token generation successfully completed when:**

1. **Dependencies installed**: colorjs.io, picocolors, fs-extra in package.json
2. **Script executed**: init-brand-tokens.mjs ran without errors
3. **Artifacts generated**:
   - design/systems/tokens.json exists with valid JSON
   - design/systems/tokens.css exists with CSS variables
   - (if --shadcn) components.json exists in project root
   - (if --shadcn) Icon library package installed
4. **WCAG validation passed**: All text color pairings ≥4.5:1 contrast ratio
5. **Tailwind wiring validated**: Config exists, tokens.css imported in globals.css
6. **shadcn aliases present**: CSS variables map OKLCH tokens to shadcn expected names
7. **Results presented**: Token structure, validation status, next steps displayed to user
</success_criteria>

<verification>
**Before marking complete, verify:**

1. **Read generated tokens.json**:
   ```bash
   cat design/systems/tokens.json | head -50
   ```
   Should show valid JSON with meta, colors, typography, spacing sections

2. **Check tokens.css created**:
   ```bash
   ls -lh design/systems/tokens.css
   ```
   Should exist with reasonable file size (>5KB)

3. **Verify script output**:
   - Check for success message from script
   - Confirm no fatal errors in output
   - Review any warnings or auto-fix messages

4. **Confirm Tailwind wiring**:
   - Read globals.css to verify tokens.css import
   - Check tailwind.config for CSS variable usage

**Never claim completion without reading tokens.json and tokens.css.**
</verification>

<output>
**Files created/modified by this command:**

**Token artifacts**:
- design/systems/tokens.json — Token definitions (OKLCH + sRGB fallbacks)
- design/systems/tokens.css — CSS variables for all tokens + shadcn aliases

**shadcn/ui artifacts** (if --shadcn flag):
- components.json — shadcn/ui CLI configuration
- app/layout.tsx — Font configuration (next/font)
- app/globals.css — Token imports and CSS variables

**Brownfield scan artifacts** (if applicable):
- design/systems/detected-tokens.json — All detected patterns with usage counts
- design/systems/token-analysis-report.md — Consolidation opportunities
- design/systems/violations-colors.txt — Hardcoded hex colors (file:line:color)
- design/systems/violations-arbitrary.txt — Arbitrary Tailwind values (file:line:value)

**Console output**:
- Mode detection (brownfield vs greenfield vs shadcn)
- Questionnaire responses (8 customization choices)
- Consolidation summary (before/after counts)
- WCAG validation results
- Tailwind wiring status
- shadcn integration status
- Style debt report (if brownfield)
- Next steps guidance
</output>

---

## Quick Reference

**When to use**:
- During `/init-project` workflow
- Before first `/design` command
- When migrating ad-hoc styles to design system
- When design tokens file is missing or outdated

**Token coverage**:
- Colors: Brand (primary/secondary/accent), Semantic (success/error/warning/info), Neutral (11 shades)
- Typography: Families, sizes (8 values), weights, line heights, letter spacing
- Spacing: 4px grid (13 values)
- Shadows: Light/dark mode variants
- Motion: Duration, easing
- Data viz: Okabe-Ito (color-blind-safe), sequential, diverging scales

**Quality gates**:
- FAIL: Tailwind missing, tokens.css not imported, contrast <4.5:1, >200 violations
- WARN: 20-200 violations, data-viz not applied, some text only AA not AAA

**For detailed technical documentation**, see: `.claude/skills/design-tokens/SKILL.md`
