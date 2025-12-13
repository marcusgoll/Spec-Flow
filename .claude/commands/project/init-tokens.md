---
name: init-brand-tokens
description: Generate OKLCH design tokens with WCAG validation and Tailwind v4 integration by scanning existing code, prototype, or creating new palette
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash(node *), Bash(pnpm *), Bash(npm *), Bash(git rev-parse:*), AskUserQuestion]
argument-hint: [--from-prototype] (optional - extract tokens from discovery prototype)
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
Initialize design system tokens in `design/systems/tokens.json` and `tokens.css` using OKLCH color space with WCAG 2.1 AA contrast validation.

**Modes**:
- **Brownfield**: Scan existing code (UI, emails, PDFs, CLI, charts, docs) for color/type/spacing patterns, consolidate duplicates
- **Greenfield**: Ask minimal questions, generate new OKLCH palette with semantic tokens
- **From Prototype** (--from-prototype): Extract and formalize colors from discovery prototype's theme.yaml

**When to use**:
- During `/init-project`, before first `/design`
- After `/prototype discover` to formalize quick-picked palette
- When migrating ad-hoc styles to systematic tokens

**Surfaces covered**: UI components, MJML/HTML emails, PDF styling, CLI colors, data viz, docs, discovery prototypes
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

<process>

### Step 1: Check Prerequisites

1. Verify Node.js installed
2. Check for required dependencies in package.json
3. If missing, install: `pnpm add -D colorjs.io picocolors fs-extra`
4. Navigate to git root

### Step 2: Detect Mode

**Check for --from-prototype flag first:**
```bash
# If --from-prototype flag provided
if [[ "$ARGUMENTS" == *"--from-prototype"* ]]; then
    MODE="prototype"
    # Check prototype exists
    test -f design/prototype/theme.yaml || echo "ERROR: No prototype theme. Run '/prototype discover' first."
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

### Step 4: Review Generated Artifacts

**Read and present**:
- `design/systems/tokens.json` - Token definitions with OKLCH and sRGB fallbacks
- `design/systems/tokens.css` - CSS variables for all tokens
- `design/systems/violations-colors.txt` - Hardcoded hex colors (if brownfield)
- `design/systems/violations-arbitrary.txt` - Arbitrary Tailwind values (if brownfield)

### Step 5: Validate Tailwind Wiring

**Checks performed**:
- Tailwind config exists
- `globals.css` imports `design/systems/tokens.css`
- Colors use CSS variables (not hardcoded)
- Contrast ratios meet WCAG 2.1 AA (≥4.5:1)

**Report validation status**: Pass/warnings/errors

### Step 6: Display Next Steps

```
✅ Token initialization complete

Generated artifacts:
  - design/systems/tokens.json (token definitions)
  - design/systems/tokens.css (CSS variables)

{If brownfield}
Style debt detected:
  - {N} hardcoded hex colors
  - {M} arbitrary Tailwind values
  - See violations-colors.txt and violations-arbitrary.txt

Next steps:
  1. Review design/systems/tokens.json
  2. Import tokens.css in your globals.css
  3. Run 'pnpm run tokens:validate' to check wiring
  4. {If brownfield} Migrate top offenders (see SKILL.md migration guides)

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
4. **WCAG validation passed**: All text color pairings ≥4.5:1 contrast ratio
5. **Tailwind wiring validated**: Config exists, tokens.css imported in globals.css
6. **Results presented**: Token structure, validation status, next steps displayed to user
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
- design/systems/tokens.css — CSS variables for all tokens

**Brownfield scan artifacts** (if applicable):
- design/systems/detected-tokens.json — All detected patterns with usage counts
- design/systems/token-analysis-report.md — Consolidation opportunities
- design/systems/violations-colors.txt — Hardcoded hex colors (file:line:color)
- design/systems/violations-arbitrary.txt — Arbitrary Tailwind values (file:line:value)

**Console output**:
- Mode detection (brownfield vs greenfield)
- Consolidation summary (before/after counts)
- WCAG validation results
- Tailwind wiring status
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
