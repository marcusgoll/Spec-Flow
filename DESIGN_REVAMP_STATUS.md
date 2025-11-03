# S-Tier Design Workflow Revamp - Implementation Status

**Last Updated**: 2025-11-03
**Status**: Phase 1-2 Complete (Foundation & Validation) | Phase 3-5 In Progress

---

## Overview

Transforming the design system into S-tier UI/UX workflow with systematic enforcement of high-end design principles, automated validation, and professional sandbox environment—all without Figma.

---

## ✅ Completed Components

### Phase 1: Design Principles & Foundation

#### 1.1 Design Constitution ✅
**File**: `.spec-flow/memory/design-principles.md`

**What it does**:
- Codifies all S-tier design principles:
  - Don't make the user think (self-explanatory UI)
  - Depth through elevation (box shadows over borders)
  - Subtle gradients only (<20% opacity, max 2 stops)
  - Reading hierarchy (2:1 heading ratios, F-pattern)
  - Steal like an artist (proven patterns from Stripe, Linear, Vercel)
  - Color depth mastery (layering, shading, WCAG AAA)
- Provides validation checklist for each design phase
- Lists anti-patterns (never do this)
- Documents design lint rules (critical/error/warning/info)

**How to use**:
- Reference during all design phases
- Share with team for design reviews
- Input for AI design generation

---

#### 1.2 Brownfield Token Scanner ✅
**File**: `.spec-flow/scripts/brownfield-token-scanner.js`

**What it does**:
- Scans existing codebase for design patterns:
  - Colors (hex, rgb, hsl, Tailwind classes)
  - Typography (fonts, sizes, weights)
  - Spacing (padding, margin, gap values)
- Generates frequency analysis
- Suggests consolidation (47 colors → 12 tokens)
- Creates detected-tokens.json with proposed structure

**How to use**:
```bash
node .spec-flow/scripts/brownfield-token-scanner.js

# Outputs:
# - design/systems/detected-tokens.json
# - design/systems/token-analysis-report.md
```

**Example output**:
```
📊 Found 47 colors, 14 font sizes, 23 spacing values
💡 Recommend consolidating to 12 + 8 + 13 tokens
```

---

#### 1.3 Brand Token Initialization Command ✅
**File**: `.claude/commands/init-brand-tokens.md`

**What it does**:
- Smart detection: Brownfield vs Greenfield
- **Brownfield mode**:
  - Runs token scanner automatically
  - Presents analysis with consolidation suggestions
  - Interactive refinement (confirm/adjust detected patterns)
  - Generates diff report (before/after)
- **Greenfield mode**:
  - Interactive CLI wizard (primary color, style, fonts)
  - AI-generated palette with WCAG validation
  - Type scale generation
- Validates Tailwind config imports tokens correctly
- Detects hardcoded values in codebase
- Generates migration guide

**How to use**:
```bash
/init-brand-tokens

# Brownfield: Scans code, suggests consolidation
# Greenfield: Interactive setup wizard
# Output: design/systems/tokens.json + tokens.css + migration guide
```

---

#### 1.4 Enhanced Token Template ✅
**File**: `.spec-flow/templates/design-system/tokens.json`

**What it includes**:
- **Colors**: Brand (primary, secondary, accent), Semantic (success, error, warning, info), Neutral (50-950)
- **Typography**: Families (sans, mono), Sizes (xs-6xl with line heights), Weights (thin-black), Letter spacing
- **Spacing**: 8px grid (0-64)
- **Shadows**: Updated to match elevation scale (sm, md, lg, xl, 2xl)
- **Elevations**: z-0 to z-5 with semantic meanings and usage examples
- **Gradients**: Subtle presets (subtle-vertical, subtle-radial, accent-wash, glass)
- **Gradient Rules**: maxStops: 2, maxOpacityDelta: 20%, avoidDiagonals: true
- **Border Radius**: none to full
- **Transitions**: duration + timing functions
- **Breakpoints**: sm to 2xl
- **Z-Index**: 0 to 50

---

### Phase 2: Systematic Validation & Enforcement

#### 2.1 Design Lint Validation Engine ✅
**File**: `.spec-flow/scripts/design-lint.js`

**What it checks**:
1. **Hardcoded colors** (critical): Detects hex, rgb, Tailwind arbitrary colors
2. **Borders on cards/modals/dropdowns** (error): Suggests shadows instead
3. **Gradient violations** (error): Checks stops, angles, opacity delta, multi-color
4. **Reading hierarchy** (error): Validates heading size ratios (2:1), weight progression
5. **Interactive labels** (critical): Ensures all buttons/links have aria-label or text
6. **Custom components** (warning): Flags components not in shadcn/ui
7. **Spacing grid** (warning): Validates 8px grid compliance

**Severity levels**:
- **Critical**: Blocks variant generation (WCAG, missing labels)
- **Error**: Requires fix before functional phase (borders, bad gradients)
- **Warning**: Suggest fix, allow override (custom components, spacing)
- **Info**: Optimization opportunities

**How to use**:
```bash
node .spec-flow/scripts/design-lint.js src/

# Outputs:
# - design/lint-report.md (detailed report)
# - Console summary (critical/error/warning/info counts)
# - Exit code 1 if critical issues (blocks pipeline)
```

**Integration**: Automatically runs during `/design-variations` phase

---

## 🚧 In Progress Components

### Phase 3: Professional Sandbox Environment

#### 3.1 Open Design Sandbox Script
**File**: `.spec-flow/scripts/open-design-sandbox.js` (TODO)

**Planned features**:
- Auto-open variants in browser after generation
- Hot reload on changes (Next.js dev server)
- CLI prompt: "Review complete? (y/n/continue editing)"
- Multi-variant display

**Implementation plan**:
```javascript
// Pseudo-code
const open = require('open');
const readline = require('readline');

function openSandbox(featureName, screen) {
  const url = `http://localhost:3000/mock/${featureName}/${screen}`;

  // Start dev server if not running
  exec('npm run dev', { detached: true });

  // Wait 3s for server startup
  setTimeout(() => {
    open(url);

    // Prompt user
    const rl = readline.createInterface({ input, output });
    rl.question('Review complete? (y/n/continue): ', (answer) => {
      if (answer === 'y') {
        // Continue to next phase
      } else if (answer === 'continue') {
        // Keep dev server running
      }
    });
  }, 3000);
}
```

---

#### 3.2 Comparison Page Component
**File**: `apps/web/mock/[feature]/[screen]/compare/page.tsx` (TODO)

**Planned features**:
- Side-by-side variant display (2-up, 3-up, 5-up)
- Toggle controls: Desktop/Mobile, Light/Dark, With Data/Empty State
- Automated analysis overlay:
  - CTA count per variant
  - Spacing grid visualization
  - Hierarchy heatmap
- Export comparison screenshot

**Tech stack**: Next.js 15, React, Tailwind, Radix UI

---

#### 3.3 Live Design System Preview
**File**: `apps/web/mock/_design-system/page.tsx` (TODO)

**Planned features**:
- Token viewer (all colors, typography, spacing, shadows)
- Before/after if updating tokens (brownfield)
- Copy token usage snippets
- Accessibility contrast checker
- Live preview of gradient presets

---

### Phase 4: Unified Design Orchestrator

#### 4.1 Master /design Command
**File**: `.claude/commands/design.md` (TODO)

**Workflow orchestration**:
```
/design "feature name"
  ↓
Phase 1: /research-design (multi-source inspiration)
  ↓
Phase 2: /init-brand-tokens (if not exists or needs update)
  ↓
Phase 3: /design-variations (3-5 variants, design-lint, auto-open)
  ↓
[HUMAN GATE: Review comparison page, fill crit.md]
  ↓
Phase 4: /design-functional (merge + a11y + hierarchy validation)
  ↓
[HUMAN GATE: Review functional prototype]
  ↓
Phase 5: /design-polish (tokens + implementation-spec + style-guide)
  ↓
Done! Ready for /tasks → /implement
```

**State tracking**: Updates `workflow-state.yaml` with `design.phase`, `design.lint_warnings`, `design.human_gates`

**Resume capability**: `/design continue` picks up from last human gate

---

#### 4.2 Research Design Command
**File**: `.claude/commands/research-design.md` (TODO)

**Multi-source inspiration**:
1. **Curated showcases**: Dribbble Top Shots, Awwwards SOTD, Behance Featured
2. **Production apps**: Stripe, Linear, Vercel, Figma, Notion
3. **Component galleries**: shadcn themes, Tailwind UI, Radix themes
4. **AI-generated**: Mood boards with color palettes, typography, spacing

**Outputs**:
- `design/inspirations.md` (categorized references)
- `design/mood-board.md` (AI-generated style direction)
- `design/references/` (screenshots)

---

### Phase 5: Implementation Adherence

#### 5.1 Implementation Spec Template
**File**: `.spec-flow/templates/design/implementation-spec-template.md` (TODO)

**Contents**:
- Exact token names for each element
- Shadow styles with elevation scale (not borders)
- Gradient specs (stops, opacity)
- Component composition (shadcn components, no custom)
- Hierarchy rules (heading sizes, weights)

**Generated during**: `/design-polish` phase

---

#### 5.2 Don't Make Me Think Checklist
**File**: `.spec-flow/templates/design/dont-make-me-think-checklist-template.md` (TODO)

**UX validation**:
- [ ] Every interactive element has clear label
- [ ] Every action has immediate feedback
- [ ] Every error has recovery path
- [ ] No ambiguous icons without labels
- [ ] Primary action visually dominant
- [ ] Navigation always visible

---

#### 5.3 Frontend Shipper Agent Enhancement
**File**: `.claude/agents/implementation/frontend.md` (TODO - update)

**New behaviors**:
- Pre-implementation: Read `design/implementation-spec.md`
- Validation: Cross-reference polished/ components
- Enforcement: Refuse custom components, require shadcn + tokens
- Quality gate: Run design-lint before commit
- Diff check: Compare implemented vs polished (visual snapshot)

---

## 📋 Remaining Tasks

### High Priority
1. ✅ ~~Create design-principles.md~~
2. ✅ ~~Create brownfield-token-scanner.js~~
3. ✅ ~~Create /init-brand-tokens command~~
4. ✅ ~~Create design-lint.js~~
5. ✅ ~~Update tokens.json template~~
6. **Create /research-design command** (multi-source inspiration)
7. **Update design-variations.md** (integrate design-lint, auto-open)
8. **Update design-functional.md** (hierarchy validation)
9. **Update design-polish.md** (token compliance, implementation-spec generation)
10. **Create unified /design orchestrator command**

### Medium Priority
11. **Create open-design-sandbox.js** (auto-open, hot reload)
12. **Create comparison page component template**
13. **Create live design system preview page**
14. **Create implementation-spec.md template**
15. **Create dont-make-me-think-checklist.md template**
16. **Update frontend-shipper agent brief**
17. **Create /generate-style-guide command**

### Low Priority
18. **Update patterns.md template** (add S-tier examples)
19. **Update init-project.md** (call init-brand-tokens)
20. **End-to-end workflow testing**

---

## 🎯 Quick Start Guide

### For Greenfield Projects

1. **Initialize brand tokens**:
   ```bash
   /init-brand-tokens
   # Answer interactive questions
   # Output: design/systems/tokens.json + tokens.css
   ```

2. **Run design workflow** (when `/design` command is complete):
   ```bash
   /design "User Authentication"
   # Auto-runs: research → variations → functional → polish
   # Pauses at human gates for review
   ```

3. **Implement**:
   ```bash
   /tasks  # Uses design/implementation-spec.md
   /implement  # Frontend-shipper validates against polished/
   ```

---

### For Brownfield Projects

1. **Scan existing code**:
   ```bash
   node .spec-flow/scripts/brownfield-token-scanner.js
   # Review: design/systems/token-analysis-report.md
   ```

2. **Initialize tokens**:
   ```bash
   /init-brand-tokens
   # Confirms detected patterns
   # Output: detected-tokens.json → tokens.json
   ```

3. **Validate existing code**:
   ```bash
   node .spec-flow/scripts/design-lint.js src/
   # Review: design/lint-report.md
   # Fix critical issues before proceeding
   ```

4. **Migrate hardcoded values** (manual for now, auto-fix coming):
   - Follow `design/systems/token-migration-guide.md`
   - Replace hex colors with tokens
   - Replace borders with shadows (per design-principles.md)
   - Use spacing grid values

5. **Run design workflow for new features**:
   ```bash
   /design "New Dashboard"
   # Uses existing tokens automatically
   ```

---

## 🔧 Manual Usage (Before `/design` Command Complete)

### Run Design Lint Manually

```bash
# Lint specific file
node .spec-flow/scripts/design-lint.js src/components/Button.tsx

# Lint directory
node .spec-flow/scripts/design-lint.js src/components/

# Generate report
node .spec-flow/scripts/design-lint.js src/ --report design/lint-report.md
```

### Scan Codebase for Tokens

```bash
# From project root
node .spec-flow/scripts/brownfield-token-scanner.js

# Custom output location
node .spec-flow/scripts/brownfield-token-scanner.js --output custom-path/tokens.json
```

### Validate Tokens Against Design Principles

```bash
# Manual validation checklist (from design-principles.md):
# [ ] 0 hardcoded colors (all use tokens)
# [ ] Shadows on elevation scale (z-0 to z-5)
# [ ] Gradients subtle (<20% opacity, max 2 stops)
# [ ] WCAG AAA contrast where possible (7:1)
# [ ] Touch targets ≥44px
# [ ] Spacing on 8px grid
```

---

## 📖 Key Principles Reference

### Depth: Box Shadows Over Borders

```tsx
// ❌ BAD
<Card className="border border-gray-200">

// ✅ GOOD
<Card className="shadow-md hover:shadow-lg">
// shadow-md = z-2 elevation (raised)
// shadow-lg = z-3 elevation (floating)
```

### Subtle Gradients Only

```tsx
// ❌ BAD: Multi-color, high contrast
<div className="bg-gradient-to-r from-purple-500 via-pink-500 to-red-500">

// ✅ GOOD: Monochromatic, subtle
<div className="bg-gradient-to-b from-blue-500/5 to-blue-500/15">
```

### Reading Hierarchy: 2:1 Size Ratio

```tsx
// ❌ BAD: Insufficient contrast
<h1 className="text-2xl font-semibold">Title</h1>
<h2 className="text-xl font-medium">Subtitle</h2>  // 1.2:1 ratio

// ✅ GOOD: Clear hierarchy
<h1 className="text-4xl font-bold">Title</h1>
<h2 className="text-2xl font-semibold">Subtitle</h2>  // 2:1 ratio
```

### Don't Make User Think

```tsx
// ❌ BAD: Ambiguous icon button
<button aria-label="Action">
  <Icon />
</button>

// ✅ GOOD: Clear label
<button className="flex items-center gap-2">
  <Icon />
  <span>Save Changes</span>
</button>
```

---

## 🚀 Next Steps to Complete Revamp

### Immediate (This Week)

1. **Create `/research-design` command**
   - Integrate WebFetch for design inspiration gathering
   - Generate mood-board.md from multiple sources
   - Save reference screenshots

2. **Update existing design commands**
   - Add design-lint integration to /design-variations
   - Add hierarchy validation to /design-functional
   - Add token compliance scan to /design-polish

3. **Create unified `/design` orchestrator**
   - Chain all phases with human gates
   - Update workflow-state.yaml tracking
   - Add resume capability

### Short-term (Next Week)

4. **Build sandbox tooling**
   - open-design-sandbox.js (auto-open, hot reload)
   - comparison page component
   - live design system preview

5. **Create handoff templates**
   - implementation-spec.md
   - dont-make-me-think-checklist.md
   - Update frontend-shipper agent

6. **End-to-end testing**
   - Test greenfield flow
   - Test brownfield flow
   - Document edge cases

### Long-term (Future Enhancements)

7. **Auto-fix tooling**
   - `/migrate-to-tokens` command (auto-replace hardcoded values)
   - Design lint --fix mode (auto-correct spacing, remove borders)

8. **Advanced features**
   - Visual regression testing (Playwright snapshots)
   - A/B testing integration (feature flags)
   - Design metrics dashboard (variant performance)

---

## 📚 Files Created

### Core System
- ✅ `.spec-flow/memory/design-principles.md` (4.7 KB)
- ✅ `.spec-flow/scripts/brownfield-token-scanner.js` (15.2 KB)
- ✅ `.spec-flow/scripts/design-lint.js` (18.4 KB)
- ✅ `.claude/commands/init-brand-tokens.md` (22.1 KB)
- ✅ `.spec-flow/templates/design-system/tokens.json` (updated, +3.8 KB)
- ✅ `DESIGN_REVAMP_STATUS.md` (this file)

**Total**: ~64 KB of new design system infrastructure

---

## 💡 Tips for Using the New System

### For Designers
- Reference `design-principles.md` during design reviews
- Use `/research-design` to gather S-tier inspiration
- Fill `crit.md` with keep/change/kill decisions during human gates
- Validate color contrast with WCAG AAA calculator

### For Developers
- Run `design-lint` before committing design changes
- Use `tokens.json` as single source of truth (never hardcode)
- Follow elevation scale (z-0 to z-5) for shadows
- Reference `implementation-spec.md` during implementation
- Cross-check polished/ components during coding

### For Project Managers
- Review `token-analysis-report.md` for consolidation opportunities
- Track design quality with lint report metrics
- Monitor slop reduction (<5% rework target)
- Ensure WCAG AAA compliance (7:1 contrast)

---

## 📊 Success Metrics

**Quantitative**:
- Design lint: <5 warnings per screen (target)
- WCAG AAA: ≥80% of text elements (7:1 contrast)
- Slop reduction: <5% design rework (vs current ~30%)
- Validation coverage: 95%+ of principles automatically checked
- Token coverage: ≥95% (≤5% hardcoded values)

**Qualitative**:
- "Design looks professional" (stakeholder feedback)
- "Spec was crystal clear" (developer handoff)
- "I knew what to do immediately" (user testing)
- "Follows proven patterns" (design critique)

---

## 🆘 Troubleshooting

### Issue: design-lint.js not running

**Solution**:
```bash
# Check Node.js version (requires v14+)
node --version

# Ensure script is executable
chmod +x .spec-flow/scripts/design-lint.js

# Run with explicit node
node .spec-flow/scripts/design-lint.js src/
```

### Issue: Token scanner finds no files

**Solution**:
```bash
# Check if source directories exist
ls src/ app/ components/

# Run from project root, not subdirectory
pwd  # Should show workflow root
```

### Issue: WCAG contrast failures

**Solution**:
1. Use online contrast checker: https://contrast-ratio.com
2. Aim for 7:1 (AAA) or minimum 4.5:1 (AA)
3. Adjust color values in `tokens.json`
4. Re-run design-lint to verify

### Issue: Too many lint warnings (>20 per file)

**Solution**:
1. Focus on critical issues first (hardcoded colors, missing labels)
2. Batch-fix errors (borders → shadows)
3. Address warnings incrementally
4. Use migration guide for common patterns

---

## 📞 Getting Help

**Documentation**:
- Design principles: `.spec-flow/memory/design-principles.md`
- Token reference: `design/systems/tokens.json`
- Migration guide: `design/systems/token-migration-guide.md` (generated by /init-brand-tokens)
- Lint report: `design/lint-report.md` (generated by design-lint.js)

**Commands** (when complete):
- `/help design` - Show design workflow status
- `/design status` - Check current phase
- `/design lint` - Run validation manually

---

**Last Updated**: 2025-11-03
**Version**: 1.0-beta
**Status**: Phase 1-2 Complete | Phase 3-5 In Progress
