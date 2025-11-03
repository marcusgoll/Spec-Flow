# /research-design

**Purpose**: Gather S-tier design inspiration from multiple sources before creating UI variants. "Original ideas are overrated: steal like an artist."

**When to use**:
- Before `/design-variations` (first phase of design workflow)
- When redesigning existing features
- When seeking fresh design direction

**Philosophy**: Learn from the best. Stripe, Linear, Vercel, and Figma didn't invent their patterns—they refined proven UX. Study their choices, understand the "why", then adapt to your context.

---

## Agent Brief

**Role**: Design Researcher

**Objective**: Create comprehensive design inspiration package with:
1. Multi-source references (showcases, production apps, component galleries)
2. AI-generated mood board (color palettes, typography, spacing)
3. Categorized patterns (forms, dashboards, modals, empty states)
4. Screenshots saved locally for offline reference

---

## Input Context

**Read these files**:
1. `docs/project/overview.md` — Product vision, target users
2. `docs/project/tech-stack.md` — Frontend framework (Next.js, React, Vue)
3. `specs/[feature]/spec.md` — Feature requirements
4. `specs/[feature]/design/screens.yaml` — Screen inventory (if exists)
5. `.spec-flow/memory/design-principles.md` — S-tier principles to apply

**Feature context**:
- Feature name (e.g., "User Authentication", "Dashboard Analytics")
- Target screens (login, register, dashboard, settings)
- Interaction patterns (forms, tables, modals, charts)

---

## Workflow

### Phase 0: Research Strategy

**Determine research focus** based on feature type:

```
If feature has:
  - Forms → Focus on Stripe, Linear (inline validation, multi-step)
  - Dashboard → Focus on Vercel, Notion (metrics cards, data viz)
  - Tables → Focus on Airtable, Notion (sortable, filterable)
  - Modals → Focus on Figma, Linear (command palette, detail views)
  - Empty states → Focus on Linear, Notion (onboarding, templates)
  - Navigation → Focus on Linear, Figma (sidebar, breadcrumbs)
```

**Source priority**:
1. **Production apps** (highest quality, proven UX)
2. **Design showcases** (creative ideas, visual polish)
3. **Component galleries** (implementation reference)
4. **Academic research** (evidence-based patterns)

---

### Phase 1: Production App Research

**Target apps** (choose 3-5 based on feature type):

#### Stripe (stripe.com/docs, stripe.com/checkout)
- **Strengths**: Forms, inline validation, error handling, minimal design
- **Study**: Checkout flow, dashboard cards, documentation layout
- **Steal**: Single-field focus, real-time validation, clear CTAs

#### Linear (linear.app)
- **Strengths**: Sidebar navigation, command palette, issue detail, status indicators
- **Study**: Issue list, keyboard shortcuts, modal interactions
- **Steal**: Grayscale + single accent color, compact spacing, focus states

#### Vercel (vercel.com/dashboard)
- **Strengths**: Dashboard metrics, deployment cards, dark theme
- **Study**: Project cards, metrics visualization, status badges
- **Steal**: Card elevation, monospace numbers, subtle gradients

#### Figma (figma.com)
- **Strengths**: Canvas interface, layers panel, inspector, color picker
- **Study**: Toolbar, properties panel, component organization
- **Steal**: Tight spacing, icon clarity, contextual controls

#### Notion (notion.so)
- **Strengths**: Blocks editor, database views, empty states, onboarding
- **Study**: Template gallery, table/board/calendar views, slash commands
- **Steal**: Empty state CTAs, drag-drop feedback, smooth animations

**For each app, use WebFetch to analyze**:

```bash
WebFetch(url, prompt):
  url: https://stripe.com/checkout
  prompt: |
    Analyze this checkout page design:
    1. Color palette (primary, accent, neutral tones)
    2. Typography (font families, size scale, weight usage)
    3. Spacing patterns (padding, margins, gaps)
    4. Form design (layout, validation, error states)
    5. Visual hierarchy (what's emphasized, what's subtle)
    6. Micro-interactions (hover, focus, active states)

    Extract specific values where possible (font sizes, colors, spacing).
    Note what makes this design feel premium/professional.
```

**Create notes**: `specs/[feature]/design/inspirations.md`

```markdown
# Design Inspirations - [Feature Name]

**Research Date**: 2025-11-03

## Production Apps

### Stripe Checkout
**URL**: https://stripe.com/checkout
**Focus**: Form design, inline validation

**Color Palette**:
- Primary: #635BFF (purple)
- Accent: #00D924 (green)
- Neutral: #0A2540 (dark), #F6F9FC (light bg)
- Text: #1A1A1A (headings), #6A7383 (body)

**Typography**:
- Font: Inter
- Sizes: 28px (h1), 16px (body), 14px (labels), 12px (helper text)
- Weights: 600 (headings), 400 (body)
- Line height: 1.5 (body), 1.2 (headings)

**Spacing**:
- 8px grid observed
- Form fields: 16px padding, 12px gap between fields
- Card padding: 24px

**Form Patterns**:
- Single-field focus (one input visible at a time on mobile)
- Inline validation (check icon appears on valid input)
- Error messages below field, red text + icon
- Submit button full-width, high contrast
- Progress indicator (1/3, 2/3, 3/3)

**Steal This**:
- Real-time validation with green checkmark
- Focus state with thick blue outline
- Error recovery suggestions ("Did you mean @gmail.com?")

### Linear Issue Detail
**URL**: https://linear.app
**Focus**: Modal design, status indicators

[Similar detailed analysis...]

## Key Patterns Identified

### Forms
- Stripe: Single-field focus, inline validation
- Linear: Keyboard shortcuts (Cmd+K), autosave
- Pattern: Validate on blur, show success states, provide recovery

### Empty States
- Linear: "Create your first issue" with keyboard shortcut
- Notion: Template gallery with previews
- Pattern: Always provide CTA, show what's possible

[Continue...]
```

---

### Phase 2: Design Showcase Research

**Target showcases**:
- **Dribbble** (dribbble.com/shots/popular): Top shots, UI/UX category
- **Awwwards** (awwwards.com/websites/): Sites of the Day
- **Behance** (behance.net/featured): Featured projects, UI/UX

**Use WebFetch to analyze**:

```bash
WebFetch(url, prompt):
  url: https://dribbble.com/shots/popular/web-design
  prompt: |
    Extract the top 5 most popular web design shots.
    For each:
    1. Title and designer
    2. Color scheme (primary colors used)
    3. Design style (minimal, bold, technical, playful)
    4. Notable patterns (card design, navigation, typography)
    5. Link to shot

    Focus on clean, professional designs (not overly decorative).
```

**Filter for quality**:
- Prefer minimal over decorative
- Prefer functional over artistic
- Prefer real projects over concepts

**Add to inspirations.md**:

```markdown
## Design Showcases

### Dribbble Top Shots

#### "SaaS Dashboard Design" by [Designer]
**URL**: https://dribbble.com/shots/...
**Style**: Minimal, data-focused

**Color Scheme**: Blue (#3B82F6), Gray (#6B7280), White
**Notable Patterns**:
- Card-based metrics with large numbers
- Subtle background gradients (gray-50 to gray-100)
- Icons with brand color accents

**Steal This**: Metric card layout, icon + number + label pattern

[Continue with 4-5 more...]
```

---

### Phase 3: Component Gallery Research

**Target galleries**:
- **shadcn/ui themes** (ui.shadcn.com/themes): Pre-built themes
- **Tailwind UI** (tailwindui.com/components): Official components
- **Radix Themes** (radix-ui.com/themes): Radix design system

**Use WebFetch to analyze component patterns**:

```bash
WebFetch(url, prompt):
  url: https://ui.shadcn.com/themes
  prompt: |
    List available theme variants and their color schemes.
    For each theme:
    1. Name
    2. Primary color
    3. Accent color
    4. Background colors (light/dark)
    5. Use case (professional, playful, technical)

    Which theme best fits a [feature type] interface?
```

**Add to inspirations.md**:

```markdown
## Component Galleries

### shadcn/ui - "Slate" Theme
**URL**: https://ui.shadcn.com/themes/slate
**Best for**: Professional dashboards, data-heavy apps

**Colors**:
- Primary: Slate-900
- Accent: Blue-500
- Background: White / Slate-950 (dark mode)

**Components to Study**:
- Card with shadow-md elevation
- Button with hover:shadow-lg transition
- Input with focus ring-2 ring-offset-2
- Dialog with backdrop-blur

**Steal This**: Shadow-based depth, focus ring patterns, dark mode implementation

[Continue...]
```

---

### Phase 4: AI-Generated Mood Board

**Create mood board** based on gathered research:

**Generate color palette**:

```markdown
## AI-Generated Mood Board

### Color Palette

**Primary**: #3B82F6 (Blue)
- Inspired by: Stripe, Vercel, Tailwind UI
- Rationale: Professional, trustworthy, web-native
- WCAG AAA on white: ✅ (7.2:1)

**Accent**: #10B981 (Green)
- Inspired by: Stripe success states, Linear status indicators
- Rationale: Success, completion, positive feedback
- WCAG AAA on white: ✅ (7.8:1)

**Neutral Scale**:
- 50: #F9FAFB (backgrounds)
- 100: #F3F4F6 (subtle surfaces)
- 200: #E5E7EB (borders, dividers)
- 400: #9CA3AF (disabled states)
- 600: #4B5563 (secondary text)
- 800: #1F2937 (body text)
- 950: #030712 (headings)

**Usage**:
- Backgrounds: 50-100 (light mode), 900-950 (dark mode)
- Text: 800-950 (light mode), 50-200 (dark mode)
- Borders: 200-300 (light mode), 700-800 (dark mode)

### Typography

**Font Family**: Inter
- Inspired by: Stripe, Linear, Vercel, GitHub
- Rationale: Geometric sans, excellent readability, web-optimized
- Fallback: system-ui, -apple-system, sans-serif

**Type Scale**: 1.25x ratio (Major Third)
- xs: 12px (0.75rem) - Captions, labels
- sm: 14px (0.875rem) - Secondary text
- base: 16px (1rem) - Body text
- lg: 18px (1.125rem) - Emphasized text
- xl: 20px (1.25rem) - Small headings
- 2xl: 24px (1.5rem) - Section titles
- 3xl: 30px (1.875rem) - Page titles
- 4xl: 36px (2.25rem) - Hero headlines

**Weight Usage**:
- 400 (normal): Body text, descriptions
- 500 (medium): Emphasized text, labels
- 600 (semibold): Subheadings, buttons
- 700 (bold): Headings, CTAs

### Spacing

**8px Grid** (0.5rem base)
- Inspired by: Material Design, Tailwind, Linear
- Scale: 0, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96
- Rationale: Consistent rhythm, easy math, accessible tap targets

**Common Patterns**:
- Card padding: 24px (p-6)
- Button padding: 12px 24px (px-6 py-3)
- Form gaps: 16px (gap-4)
- Section spacing: 48px (space-y-12)

### Elevation (Shadows)

**Scale**: z-0 to z-5
- Inspired by: Material Design, shadcn/ui
- z-1 (sm): Cards on page
- z-2 (md): Hover states
- z-3 (lg): Dropdowns, popovers
- z-4 (xl): Modals, dialogs
- z-5 (2xl): Tooltips, alerts

**No borders on elevated elements** (per design-principles.md)

### Gradients

**Subtle vertical**: gray-50 → gray-100
- Usage: Page backgrounds, section backgrounds
- Opacity: 10% delta (within rules)

**Accent wash**: primary/5 → primary/15
- Usage: Hero sections, feature highlights
- Opacity: 10% delta (within rules)

### Visual Style

**Overall**: Minimal, professional, data-focused
- Inspired by: Stripe (clean), Linear (efficient), Vercel (technical)
- Characteristics:
  - Lots of whitespace (breathing room)
  - Clear hierarchy (size, weight, color)
  - Subtle depth (shadows, not borders)
  - High contrast text (WCAG AAA)
  - Minimal decoration (functional > ornamental)

**Micro-interactions**:
- Hover: Increase shadow (z-1 → z-2)
- Focus: Ring-2 ring-offset-2 ring-primary
- Active: Slight scale (scale-[0.98])
- Disabled: Opacity-50 + cursor-not-allowed

**Animation**: Fast, purposeful
- Duration: 150ms (fast), 200ms (base), 300ms (slow)
- Easing: ease-out (decelerate at end)
- What animates: shadows, opacity, transform (not color, layout)
```

---

### Phase 5: Pattern Library

**Extract reusable patterns** from research:

```markdown
## Pattern Library

### Forms

#### Inline Validation (Stripe-style)
**When**: On blur (not on every keystroke)
**Success**: Green checkmark icon, green border
**Error**: Red X icon, red border, error message below
**Helper text**: Gray, 12px, appears on focus

**Implementation**:
```tsx
<div className="space-y-1">
  <Label htmlFor="email">Email</Label>
  <div className="relative">
    <Input
      id="email"
      type="email"
      className={cn(
        error ? "border-error ring-error" : "",
        success ? "border-success ring-success" : ""
      )}
    />
    {success && <CheckIcon className="absolute right-3 top-3 text-success" />}
    {error && <XIcon className="absolute right-3 top-3 text-error" />}
  </div>
  {error && <p className="text-sm text-error">{error}</p>}
  {helperText && <p className="text-sm text-neutral-600">{helperText}</p>}
</div>
```

#### Multi-Step Form (Linear-style)
**Progress**: Step indicator (1/3, 2/3, 3/3)
**Navigation**: Back button, Next button (primary)
**Autosave**: Save state on every change (debounced 500ms)
**Keyboard**: Enter to advance, Escape to cancel

[Continue with more patterns...]

### Dashboards

#### Metric Card (Vercel-style)
**Layout**: Icon top-left, value center, label bottom
**Shadow**: shadow-sm default, shadow-md on hover
**Typography**: Monospace for numbers (large), sans for label (small)

**Implementation**:
```tsx
<Card className="p-6 shadow-sm hover:shadow-md transition-shadow">
  <div className="flex items-start justify-between">
    <Icon className="text-primary" />
    <Badge variant="success">+12%</Badge>
  </div>
  <div className="mt-4">
    <p className="text-4xl font-bold font-mono">1,234</p>
    <p className="text-sm text-neutral-600 mt-1">Active Users</p>
  </div>
</Card>
```

[Continue with more patterns...]

### Empty States

#### Linear-style
**Icon**: Large (48px), subtle color (neutral-400)
**Heading**: "No issues yet"
**Description**: "Create your first issue to get started"
**CTA**: Primary button with keyboard shortcut badge
**Secondary**: Link to docs/help

**Implementation**:
```tsx
<div className="flex flex-col items-center justify-center py-12 text-center">
  <EmptyIcon className="w-12 h-12 text-neutral-400 mb-4" />
  <h3 className="text-lg font-semibold text-neutral-900">No issues yet</h3>
  <p className="text-sm text-neutral-600 mt-2 max-w-sm">
    Create your first issue to start tracking your work
  </p>
  <div className="flex items-center gap-2 mt-6">
    <Button>
      Create Issue
      <Badge variant="outline" className="ml-2">C</Badge>
    </Button>
  </div>
  <a href="/docs" className="text-sm text-primary hover:underline mt-4">
    Learn more about issues
  </a>
</div>
```

[Continue...]
```

---

## Output Artifacts

### 1. `specs/[feature]/design/inspirations.md`

**Comprehensive inspiration document** with:
- Production app analysis (3-5 apps, detailed)
- Design showcase highlights (5-10 shots)
- Component gallery references (3-5 themes)
- Links to all sources

### 2. `specs/[feature]/design/mood-board.md`

**AI-generated style guide** with:
- Color palette (primary, accent, neutral with WCAG validation)
- Typography scale (fonts, sizes, weights)
- Spacing scale (8px grid)
- Elevation scale (shadows, no borders)
- Gradient presets (subtle, within rules)
- Visual style summary
- Micro-interaction specs

### 3. `specs/[feature]/design/pattern-library.md`

**Reusable UX patterns** extracted from research:
- Forms (inline validation, multi-step, autosave)
- Dashboards (metric cards, charts, filters)
- Tables (sorting, filtering, pagination)
- Modals (command palette, detail views)
- Empty states (onboarding, templates)
- Navigation (sidebar, breadcrumbs, tabs)

Each pattern includes:
- Description
- When to use
- Implementation example (TSX)
- Reference (which app inspired it)

### 4. `specs/[feature]/design/references/`

**Directory with screenshots**:
- `stripe-checkout.png`
- `linear-issue-detail.png`
- `vercel-dashboard.png`
- `dribbble-shot-1.png`
- [etc.]

**How to save**: During WebFetch, note URLs. Later, manually save screenshots or use automation.

---

## Quality Gates

**Before proceeding to /design-variations**:

- [ ] At least 3 production apps analyzed in detail
- [ ] Color palette generated with WCAG AAA validation
- [ ] Typography scale defined (8 sizes minimum)
- [ ] Spacing scale on 8px grid
- [ ] Elevation scale documented (z-0 to z-5)
- [ ] Pattern library has 5+ reusable patterns
- [ ] All patterns reference specific inspirations
- [ ] Mood board aligns with project overview.md (brand, target users)

**Blocks design if**:
- No production app references (must steal from the best)
- Color palette fails WCAG AA (4.5:1 minimum)
- No spacing scale defined (need systematic spacing)

**Warnings (non-blocking)**:
- <3 production apps (prefer 3-5)
- Typography scale <8 sizes (may need more range)
- No component gallery references (implementation will be harder)

---

## Usage Examples

### UI-heavy feature (Dashboard)

```bash
/research-design "Dashboard Analytics"

# Analyzes:
# - Vercel dashboard (metrics, deployment cards)
# - Linear dashboard (issue stats, velocity charts)
# - Notion database views (table, board, calendar)
# - Dribbble dashboard shots
# - Tailwind UI dashboard components

# Generates:
# - inspirations.md with detailed analysis
# - mood-board.md with color/typography/spacing
# - pattern-library.md with metric cards, chart patterns
# - references/ with screenshots

# Output:
✅ Researched 3 production apps, 5 showcase designs
📊 Generated mood board: Blue primary, Inter typography, 8px grid
📚 Extracted 8 reusable patterns (metric cards, filters, empty states)
📸 Saved 12 reference screenshots
📖 Next: Run /design-variations to create UI variants
```

### Form-heavy feature (User Authentication)

```bash
/research-design "User Authentication"

# Analyzes:
# - Stripe checkout (form design, inline validation)
# - Linear login (minimal, keyboard shortcuts)
# - Clerk sign-in components
# - Dribbble login shots
# - shadcn/ui form components

# Generates:
# - inspirations.md (Stripe focus, form patterns)
# - mood-board.md (professional, high contrast)
# - pattern-library.md (inline validation, password strength, social auth)
# - references/ with login/register screenshots

# Output:
✅ Researched 3 production apps (form-focused)
📊 Generated mood board: Stripe-inspired, single-field focus
📚 Extracted 6 form patterns (validation, password, social, MFA)
📸 Saved 8 reference screenshots
📖 Next: Run /design-variations with form patterns
```

---

## Integration with Workflow

**Called by**:
- `/design` (Phase 1, before variations)
- Manual invocation before redesigns

**Calls**:
- `WebFetch` (analyze production apps, showcases, galleries)
- None (terminal command, outputs markdown files)

**Used by**:
- `/design-variations` (references inspirations.md and mood-board.md)
- Frontend-shipper agent (references pattern-library.md during implementation)

**State tracking**:
```yaml
design:
  phase: research
  status: completed
  research:
    apps_analyzed: 3
    patterns_extracted: 8
    screenshots_saved: 12
  artifacts:
    - design/inspirations.md
    - design/mood-board.md
    - design/pattern-library.md
    - design/references/
```

---

## Success Criteria

**Quantitative**:
- ≥3 production apps analyzed
- ≥5 design showcase references
- ≥5 reusable patterns extracted
- ≥8 screenshots saved
- WCAG AAA colors (7:1 contrast)

**Qualitative**:
- "This looks like [Stripe/Linear/Vercel]" (designer feedback)
- "Patterns are clear and reusable" (developer feedback)
- "Mood board is inspiring" (stakeholder feedback)
- "References are high-quality" (design critique)

---

**Related Commands**:
- `/design-variations` — Use research to generate variants
- `/init-brand-tokens` — May reference mood-board colors

**Agent**: None (run in main instance, uses WebFetch)

**Estimated Duration**: 30-45 minutes
