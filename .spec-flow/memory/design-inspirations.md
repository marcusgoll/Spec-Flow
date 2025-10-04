# Spec-Flow Design Inspirations

**Purpose**: Global mood board of design patterns, styles, and interactions we admire. Reference this when creating specs or implementing UI features.

**Last updated**: 2025-10-03

---

## Landing Pages & Hero Sections

### Linear

**URL**: [https://linear.app](https://linear.app)
**What we like**:

* Single CTA above fold (no competing actions)
* Focused headline with power words (built for modern teams)
* Trust signals below hero (reduces clutter)
* Subtle fade-in animations (respect `prefers-reduced-motion`)
* Clean typography hierarchy (56px headline, 20px subheadline)

**Why relevant**: One primary CTA (Try it Free), secondary CTAs live below the fold. Keep copy tight and outcome-oriented.

---

### Notion

**URL**: [https://notion.so](https://notion.so)
**What we like**:

* Full-viewport hero on desktop (~80vh on mobile)
* Social proof placement below CTA
* Email capture optional (not forced)
* Large touch targets (52px CTA height)
* Motion disabled for users who request it

**Why relevant**: Let anonymous users try the extractor first; add social proof later (placeholders now). Mobile touch targets are non-negotiable.

---

### Vercel

**URL**: [https://vercel.com](https://vercel.com)
**What we like**:

* Left-aligned hero content; fast scannability
* Command palette pattern (power user affordance)
* Terminal-style transformation animation
* Subtle depth on CTAs (shadow, not glow)

**Why relevant**: Use a lightweight AKTR  ACS transform animation in product sections; keep overall theme light for readability.

---

### Stripe (Homepage Hero)

**URL**: [https://stripe.com](https://stripe.com)
**What we like**:

* Dense info without overwhelm; clear sectional rhythm
* Excellent OG/SEO defaults
* Clear secondary path just beneath primary CTA

**Why relevant**: Primary Try it Free with a nearby See Pricing. No button soup.

---

### Clockify (Heavy Inspiration)

**URL**: [https://clockify.com](https://clockify.com)
**What we like**:

* Straightforward hero with one action and plain-English benefits
* Section pattern: benefit  proof  CTA repeat
* Pricing clarity and simple illustrations

**Why relevant**: Our audience values speed and clarity. Mirror Clockifys calm, practical marketing voice and layout rhythm.

---

### WPMU DEV

**URL**: [https://wpmudev.com](https://wpmudev.com)
**What we like**:

* Clear, contrasty sections with strong headings
* Trust bars and badges that dont overpower
* Sticky pricing toggles with honest comparisons

**Why relevant**: Borrow the confidence scaffolding (trust bars, transparent policies) without clutter.

---

### Plaky

**URL**: [https://plaky.com](https://plaky.com)
**What we like**:

* Clean, airy hero and section spacing
* Screenshots framed in subtle device chrome
* Simple colored tags/chips for features

**Why relevant**: Use framed screenshots to communicate results quickly; chips for ACS areas/tasks in product pages.

---

### Pumble

**URL**: [https://pumble.com](https://pumble.com)
**What we like**:

* Conversational landing copy and friendly tone
* Transparent pricing boxes
* Clear who its for blocks

**Why relevant**: Create role-specific blocks (Students / CFIs / Schools) on the marketing home.

---

## Dashboards & Data Display

### Clockify (Time Tracking Dashboard)

**URL**: [https://clockify.me](https://clockify.me)
**What we like**:

* Clean data tables with alternating rows
* Inline editing without modal churn
* Quick filters above the table
* Export always visible

**Why relevant**: History and cohort views need quick filtering, inline actions, and permanent export affordances.

---

### GitHub (Lists & Activity)

**URL**: [https://github.com](https://github.com)
**What we like**:

* Dense tables that remain readable
* Clear empty/zero states with next action
* Keyboard-friendly focus states

**Why relevant**: Pragmatic density for History, Batch, Approvals. No mystery meat.

---

## Forms & Input Components

### GOV.UK Design System

**URL**: [https://design-system.service.gov.uk/components/](https://design-system.service.gov.uk/components/)
**What we like**:

* Clear labels, errors, and hints
* Generous spacing; obvious required fields
* Accessible patterns by default

**Why relevant**: Upload, consent, and settings forms must be unambiguous and accessible. Clarity over cleverness.

---

## Navigation & Menu Patterns

### Linear (Minimal Top Nav)

**URL**: [https://linear.app](https://linear.app)
**What we like**:

* Slim top bar; primary CTA is visually dominant
* Predictable hover/focus; no mega-menus

**Why relevant**: Marketing nav = Home, Product, Pricing, Docs, Sign in. Keep it predictable.

---

### Vercel Docs (TOC)

**URL**: [https://vercel.com/docs](https://vercel.com/docs)
**What we like**:

* Left TOC on desktop, collapsible on mobile
* Sticky in-page headings

**Why relevant**: Adopt for Docs/FAQ/Getting Started.

---

## Documentation & Learning Hubs

### Claude Docs

**URL**: [https://docs.claude.com/](https://docs.claude.com/)
**What we like**:

* Fast, relevant global search with keyboard shortcuts
* Sticky right-hand in-page nav + clear anchors
* Copy buttons on code snippets; pleasant callouts (note/warn/tip)
* Clean, high-contrast content area with generous line length control

**Why relevant**: Our Docs/Getting Started should feel instant and scannable. Add copy buttons for commands, callout styles for warnings, and a sticky in-page nav.

---

### Anthropic Academy (Skilljar)

**URL**: [https://anthropic.skilljar.com/](https://anthropic.skilljar.com/)
**What we like**:

* Course catalog with filters/tags and clear time estimates
* Progress tracking (resume where you left off)
* Certificates/badges presentation without heavy chrome
* Friendly, compact lesson pages with breadcrumbs

**Why relevant**: For future onboarding/learning tracks (Students/CFIs), mirror the resume/track progress pattern and clean catalog filtering; keep lessons lightweight with obvious next actions.

---

## Tables & List Views

### MUI Data Grid (Patterns only)

**URL**: [https://mui.com/x/react-data-grid/](https://mui.com/x/react-data-grid/)
**What we like**:

* Column pinning and density toggles
* Clear, conventional pagination

**Why relevant**: Recreate behaviors with Tailwind + shadcn; avoid heavy deps.

---

## Modals, Dialogs & Overlays

### Radix/Headless Patterns

**URL**: [https://www.radix-ui.com/primitives/docs/components/dialog](https://www.radix-ui.com/primitives/docs/components/dialog)
**What we like**:

* Proper focus traps, escape to close, aria labels
* Size variants; responsive behavior

**Why relevant**: Export/Share/Consent dialogs need robust a11y by default.

---

## Buttons, CTAs & Interactive Elements

### Linear Primary CTA

**URL**: [https://linear.app](https://linear.app)
**What we like**:

* 4852px height (desktop), solid fill
* 24px horizontal padding, 8px radius
* Hover = slightly darker + subtle shadow
* Debounced to prevent double-clicks

**Why relevant**: Use consistent primary CTA (Try it Free) across marketing and app.

---

### Stripe Secondary/Ghost

**URL**: [https://stripe.com](https://stripe.com)
**What we like**:

* Subtle secondary buttons that dont compete
* Icon-leading CTAs when helpful

**Why relevant**: Secondary = See Pricing, View Docs  never outshine primary.

---

## Loading States & Empty States

### Linear & GitHub (Skeletons)

**What we like**:

* Skeletons for tables/cards with short shimmer
* Empty states that prescribe one clear next step

**Why relevant**: Upload/Results/History must show progress and offer retry/next action immediately.

---

## Authentication & Onboarding

### Clerk (Defaults)

**URL**: [https://clerk.com](https://clerk.com)
**What we like**:

* Minimal fields; strong defaults
* Clear mobile ergonomics

**Why relevant**: Keep auth forms vanilla; post-auth should land users in the app with preserved deep link.

---

## Color & Typography Systems

### Brand Tokens (authoritative)

Use these tokens across marketing and app.

```css
:root {
  --background: oklch(0.9383 0.0042 236.4993);
  --foreground: oklch(0.3211 0 0);
  --card: oklch(1.0000 0 0);
  --card-foreground: oklch(0.3211 0 0);
  --popover: oklch(1.0000 0 0);
  --popover-foreground: oklch(0.3211 0 0);
  --primary: oklch(0.6230 0.2140 259.8150);
  --primary-foreground: oklch(1.0000 0 0);
  --secondary: oklch(0.9670 0.0029 264.5419);
  --secondary-foreground: oklch(0.4461 0.0263 256.8018);
  --muted: oklch(0.9846 0.0017 247.8389);
  --muted-foreground: oklch(0.5510 0.0234 264.3637);
  --accent: oklch(0.9119 0.0222 243.8174);
  --accent-foreground: oklch(0.3791 0.1378 265.5222);
  --destructive: oklch(0.6368 0.2078 25.3313);
  --destructive-foreground: oklch(1.0000 0 0);
  --border: oklch(0.9022 0.0052 247.8822);
  --input: oklch(0.9700 0.0029 264.5420);
  --ring: oklch(0.6397 0.1720 36.4421);
  --chart-1: oklch(0.7156 0.0605 248.6845);
  --chart-2: oklch(0.7875 0.0917 35.9616);
  --chart-3: oklch(0.5778 0.0759 254.1573);
  --chart-4: oklch(0.5016 0.0849 259.4902);
  --chart-5: oklch(0.4241 0.0952 264.0306);
  --sidebar: oklch(0.9030 0.0046 258.3257);
  --sidebar-foreground: oklch(0.3211 0 0);
  --sidebar-primary: oklch(0.6397 0.1720 36.4421);
  --sidebar-primary-foreground: oklch(1.0000 0 0);
  --sidebar-accent: oklch(0.9119 0.0222 243.8174);
  --sidebar-accent-foreground: oklch(0.3791 0.1378 265.5222);
  --sidebar-border: oklch(0.9276 0.0058 264.5313);
  --sidebar-ring: oklch(0.6397 0.1720 36.4421);
  --font-sans: Inter, sans-serif;
  --font-serif: Source Serif 4, serif;
  --font-mono: JetBrains Mono, monospace;
  --radius: 0.75rem;
  --shadow-2xs: 0px 1px 3px 0px hsl(0 0% 0% / 0.05);
  --shadow-xs: 0px 1px 3px 0px hsl(0 0% 0% / 0.05);
  --shadow-sm: 0px 1px 3px 0px hsl(0 0% 0% / 0.10), 0px 1px 2px -1px hsl(0 0% 0% / 0.10);
  --shadow: 0px 1px 3px 0px hsl(0 0% 0% / 0.10), 0px 1px 2px -1px hsl(0 0% 0% / 0.10);
  --shadow-md: 0px 1px 3px 0px hsl(0 0% 0% / 0.10), 0px 2px 4px -1px hsl(0 0% 0% / 0.10);
  --shadow-lg: 0px 1px 3px 0px hsl(0 0% 0% / 0.10), 0px 4px 6px -1px hsl(0 0% 0% / 0.10);
  --shadow-xl: 0px 1px 3px 0px hsl(0 0% 0% / 0.10), 0px 8px 10px -1px hsl(0 0% 0% / 0.10);
  --shadow-2xl: 0px 1px 3px 0px hsl(0 0% 0% / 0.25);
}

/* .dark variant provided by brand tokens */
```

**System guidance**:

* **Font**: Inter (sans), Source Serif 4 (serif), JetBrains Mono (mono).
* **Spacing**: 8px grid; base `--spacing: 0.25rem`.
* **Radius**: 12px (`--radius: 0.75rem`) for cards/buttons.
* **CTA**: Primary uses `--primary`; height 4852px.

---

## Animations & Transitions

### Framer Motion

**URL**: [https://framer.com/motion](https://framer.com/motion)
**What we like**:

* Spring physics (natural feel)
* Staggered list/card reveals
* Exit mirrors enter
* Always respect `prefers-reduced-motion`

**Why relevant**: Use *subtle only*. Short spring on AKTR  ACS visual; light staggers on card lists (200ms).

---

## Mobile Patterns

### Notion (Mobile)

**URL**: [https://notion.so](https://notion.so)
**What we like**:

* Full-width CTAs
* Stacked layouts; no horizontal scroll
* Higher line-height for readability
* Bottom-zone interactions prioritized

**Why relevant**: Expect 50%+ mobile traffic. Use full-width CTAs, vertical badge stacks, and avoid side-by-side grids below 360px.

---

## Usage Guidelines

**When to add entries:**

* Found inspiring design during research
* Team member shares a good example
* Pattern clearly solves a Spec-Flow problem

**What to capture:**

* Specific elements (buttons, animations, layout)
* Quick notes (why it works, where well use it)
* Relevance to Students / CFIs / Schools

**What NOT to do:**

* Dont duplicate feature READMEs (deeper dives live there)
* Dont add every site you see (quality > quantity)
* Dont add patterns that fight our values (simplicity, education-first)

---

**Maintained by**: Claude Code + Team

