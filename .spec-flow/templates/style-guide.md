# Style Guide

**Project**: [PROJECT_NAME]
**Last Updated**: [DATE]
**Version**: 1.0.0

This comprehensive style guide serves as the single source of truth for all design decisions. It replaces multi-phase design workflows with clear, enforceable rules that AI and humans can follow consistently.

## Philosophy

**"Content is the star of the show"** - Design elements should enhance, not distract. Every visual choice should serve the user's goal of completing tasks quickly and confidently.

**Clean website definition**: Clean doesn't mean minimal. Clean means thoughtful—things aren't sized and spaced randomly. There's a rhythm that makes the layout easy to navigate and predictable for the user.

---

## 1. Foundation

### Core Design Principles

#### 1. Break Up Large Chunks of Text
**Rule**: Aim for 50 to 75 characters OR about 600px to 700px maximum width per line.

**Why**: Readability drops dramatically beyond 75 characters. Users scan, don't read word-by-word.

**Implementation**:
```tsx
// ✅ Correct
<div className="max-w-[700px]">
  <p className="text-base leading-relaxed">
    This paragraph will naturally wrap at 50-75 characters depending on font size,
    making it easy to scan and comfortable to read.
  </p>
</div>

// ❌ Wrong
<div className="w-full">
  <p className="text-base">
    This paragraph stretches across the entire viewport width, making it extremely difficult to read on desktop screens because the eye has to travel too far horizontally...
  </p>
</div>
```

#### 2. Bullet Points Are a Designer's Best Friend
**Rule**: Our brains love lists. Bullet points with icons are fire.

**Why**: Lists force you to think critically about copy structure. Icons add visual hierarchy and scanability.

**Implementation**:
```tsx
// ✅ Correct - Bullet points with icons
<ul className="space-y-3">
  <li className="flex items-start gap-3">
    <CheckCircleIcon className="w-5 h-5 text-semantic-success-fg mt-0.5 shrink-0" />
    <span className="text-neutral-700">Easy to scan with icon providing visual anchor</span>
  </li>
  <li className="flex items-start gap-3">
    <CheckCircleIcon className="w-5 h-5 text-semantic-success-fg mt-0.5 shrink-0" />
    <span className="text-neutral-700">Consistent spacing creates rhythm</span>
  </li>
</ul>

// ❌ Wrong - Dense paragraph
<p>
  Easy to scan with icon providing visual anchor. Consistent spacing creates rhythm. Multiple ideas crammed together without visual separation.
</p>
```

#### 3. Use a Consistent Spacing System (8pt Grid)
**Rule**: All elements are spaced by multiples of 8 (or 4 for micro-adjustments).

**Why**: Creates predictable rhythm. Prevents random spacing that looks "off."

**Implementation**:
```tsx
// ✅ Correct - 8pt grid (4, 8, 12, 16, 24, 32, 48, 64...)
<div className="space-y-8">  {/* 32px */}
  <section className="space-y-4 p-6">  {/* 16px spacing, 24px padding */}
    <h2 className="mb-2">Title</h2>  {/* 8px margin */}
    <p>Content</p>
  </section>
</div>

// ❌ Wrong - Arbitrary values
<div className="space-y-[23px]">
  <section className="space-y-[15px] p-[27px]">
    <h2 className="mb-[11px]">Title</h2>
    <p>Content</p>
  </section>
</div>
```

#### 4. Layout Rules
**Rules**:
1. **Start with a baseline value** (usually 16px or 24px)
2. **Separate groups by at least double** (if items are 8px apart, groups are 16px+ apart)
3. **Keep the distance between big groups similar** (consistency creates rhythm)
4. **Use ratios for line heights**:
   - Display: 1 to 1 ratio (text-5xl line-height: 1)
   - Paragraph: 1 to 1.5 ratio (text-base leading-relaxed: 1.5)

**Implementation**:
```tsx
// ✅ Correct - Baseline + double spacing
<div className="space-y-12">  {/* 48px between major sections */}
  <section className="space-y-6">  {/* 24px between groups */}
    <div className="space-y-2">  {/* 8px between related items */}
      <h3 className="text-2xl font-semibold leading-tight">Heading</h3>
      <p className="text-sm text-neutral-600">Subheading</p>
    </div>
    <div className="space-y-2">  {/* Another group, 8px internally */}
      <p className="text-base leading-relaxed">Paragraph</p>
    </div>
  </section>
</div>
```

#### 5. Refine Text with Letter-Spacing
**Rules**:
- **Display fonts**: -1px (scanability)
- **Body text**: 0px/default (legibility)
- **CTAs**: +1px or +0.05em (clickability)

**Why**: Letter-spacing affects readability at different sizes. Large text needs tighter spacing; buttons need looser spacing for emphasis.

**Implementation**:
```tsx
// ✅ Correct
<h1 className="text-5xl font-bold -tracking-px">  {/* -0.025em */}
  Display Heading
</h1>
<p className="text-base tracking-normal">  {/* 0 */}
  Body text with default spacing for optimal legibility.
</p>
<Button className="tracking-wide">  {/* +0.025em */}
  Call to Action
</Button>

// ❌ Wrong
<h1 className="text-5xl font-bold tracking-widest">
  T o o   W i d e
</h1>
<Button className="tracking-tighter">
  TooTight
</Button>
```

#### 6. Font Superfamilies (Character Size Matching)
**Rule**: If the characters are drastically different in size and spacing, the user's eyes have to bounce to read the text.

**Why**: Visual consistency. Mixing fonts with different x-heights or character widths creates visual chaos.

**Implementation**:
```tsx
// ✅ Correct - Similar x-heights
<div className="font-sans">  {/* Inter */}
  <h1 className="font-bold">Heading in Inter</h1>
  <p>Body text also in Inter (consistent x-height)</p>
  <code className="font-mono">Code in monospace</code>  {/* Different context, OK */}
</div>

// ❌ Wrong - Mismatched x-heights
<div>
  <h1 className="font-serif">Heading in Times</h1>  {/* Tall x-height */}
  <p className="font-sans">Body in Arial</p>  {/* Short x-height */}
</div>
```

#### 7. Find Color Palettes with Dev Tools (CSS Overview)
**Rule**: Favor OKLCH over Hex colors. Use browser DevTools CSS Overview to audit color usage.

**Why**: OKLCH is perceptually uniform (consistent brightness across hues). Hex can create accidental contrast issues.

**Implementation**:
```tsx
// ✅ Correct - OKLCH with semantic tokens
<Button className="bg-brand-primary text-neutral-50">
  {/* brand-primary: oklch(0.55 0.22 250) */}
  Primary Action
</Button>

// ❌ Wrong - Hardcoded hex
<Button style={{ backgroundColor: '#3b82f6', color: '#ffffff' }}>
  Primary Action
</Button>
```

**Audit Process**:
1. Open Chrome DevTools → More Tools → CSS Overview
2. Capture page overview
3. Check Colors section: Should see 10-15 colors max (not 50+)
4. Consolidate similar colors into design tokens

#### 8. Be Subtle with Design Elements
**Rule**: Use gradients, soft textured backgrounds, and shadows. Don't overdesign. Keep the main thing, the main thing.

**Guidelines**:
- Gradients: Monochromatic, <20% opacity delta, vertical or horizontal (no diagonals)
- Shadows: Soft, small blur radius (4-12px)
- Textures: Subtle noise, <5% opacity
- Borders: Avoid on cards (use shadows instead)

**Implementation**:
```tsx
// ✅ Correct - Subtle gradient
<Card className="bg-gradient-to-b from-neutral-50 to-neutral-100 shadow-md">
  {/* 10% opacity delta, monochromatic, vertical */}
</Card>

// ❌ Wrong - Overdesigned
<Card className="bg-gradient-to-br from-purple-500 via-pink-500 to-red-500 border-4 border-gold shadow-2xl">
  {/* Rainbow gradient, thick border, harsh shadow */}
</Card>
```

#### 9. Use the Squint Test to See Hierarchy
**Rule**: Step back, squint until design blurs. What stands out? Headlines and CTAs should jump out.

**How to Apply**:
1. Step back from your design
2. Squint until it becomes blurry
3. What stands out first? (Should be: primary CTA, main heading)
4. If page turns into a blob, increase contrast/size of key elements

**Implementation**:
```tsx
// ✅ Correct - Clear hierarchy
<section className="space-y-8">
  <h1 className="text-5xl font-bold text-neutral-900">  {/* Passes squint test */}
    Main Headline Stands Out
  </h1>
  <p className="text-base text-neutral-700">
    Supporting text recedes into background when squinting.
  </p>
  <Button size="lg" className="bg-brand-primary text-white shadow-lg">
    {/* Large, high contrast CTA stands out */}
    Primary Action
  </Button>
</section>

// ❌ Wrong - No hierarchy
<section>
  <h1 className="text-xl font-normal text-neutral-600">
    Heading Too Small and Light
  </h1>
  <p className="text-lg text-neutral-700">
    Body text same visual weight as heading.
  </p>
  <Button size="sm" variant="ghost">
    Invisible CTA
  </Button>
</section>
```

### Token System Overview

Design tokens are the atomic values of the design system. All components reference tokens, never hardcoded values.

**Token Categories**:
- **Colors**: Brand, semantic, neutral palettes (OKLCH format)
- **Typography**: Font families, sizes, weights, line heights
- **Spacing**: 8pt grid scale (0, 4, 8, 12, 16, 24, 32, 48, 64, 96, 128)
- **Shadows**: Elevation scale (z-0 to z-5)
- **Radii**: Border radius scale (none, sm, md, lg, xl, full)
- **Motion**: Timing functions, durations

**Location**: `design/systems/tokens.json`

---

## 2. Colors

### OKLCH Color System

**Why OKLCH?**
- Perceptually uniform (50% lightness looks 50% bright across all hues)
- Predictable contrast ratios
- Wider gamut than sRGB (future-proof)
- Easy to generate scales (vary lightness, keep chroma/hue constant)

**Format**: `oklch(L C H / A)`
- L = Lightness (0-1, where 1 = white)
- C = Chroma (0-0.4, where 0 = gray)
- H = Hue (0-360, where 0 = red, 120 = green, 240 = blue)
- A = Alpha (0-1, optional)

### Brand Colors

**Primary** - Main brand color (CTAs, links, key actions)
```css
--brand-primary: oklch(0.55 0.22 250);  /* Blue */
--brand-primary-hover: oklch(0.50 0.22 250);  /* Darker on hover */
```

**Secondary** - Supporting brand color (accents, highlights)
```css
--brand-secondary: oklch(0.60 0.15 180);  /* Teal */
```

**Accent** - Emphasis color (badges, notifications)
```css
--brand-accent: oklch(0.65 0.20 340);  /* Pink */
```

### Semantic Colors

**Success** - Positive feedback (saved, completed, approved)
```css
--semantic-success: oklch(0.50 0.15 140);  /* Green */
--semantic-success-bg: oklch(0.95 0.05 140);  /* Light green bg */
--semantic-success-fg: oklch(0.35 0.15 140);  /* Dark green text */
```

**Error** - Negative feedback (failed, rejected, invalid)
```css
--semantic-error: oklch(0.55 0.22 25);  /* Red */
--semantic-error-bg: oklch(0.95 0.05 25);
--semantic-error-fg: oklch(0.40 0.22 25);
```

**Warning** - Caution (pending, review needed)
```css
--semantic-warning: oklch(0.65 0.18 80);  /* Yellow */
--semantic-warning-bg: oklch(0.95 0.08 80);
--semantic-warning-fg: oklch(0.45 0.18 80);
```

**Info** - Neutral information (tips, notices)
```css
--semantic-info: oklch(0.55 0.18 230);  /* Blue */
--semantic-info-bg: oklch(0.95 0.05 230);
--semantic-info-fg: oklch(0.40 0.18 230);
```

### Neutral Palette

**Scale**: 50 (lightest) to 950 (darkest)

```css
--neutral-50: oklch(0.98 0.00 0);   /* Almost white */
--neutral-100: oklch(0.96 0.00 0);
--neutral-200: oklch(0.92 0.00 0);
--neutral-300: oklch(0.86 0.00 0);
--neutral-400: oklch(0.74 0.00 0);
--neutral-500: oklch(0.58 0.00 0);  /* Mid gray */
--neutral-600: oklch(0.48 0.00 0);
--neutral-700: oklch(0.38 0.00 0);
--neutral-800: oklch(0.26 0.00 0);
--neutral-900: oklch(0.18 0.00 0);
--neutral-950: oklch(0.10 0.00 0);  /* Almost black */
```

### Context-Aware Color Mapping

**Purpose-Based Usage**:

#### Buttons & CTAs → Brand Primary
```tsx
// ✅ Correct
<Button className="bg-brand-primary text-neutral-50">Primary Action</Button>
<Button className="bg-neutral-200 text-neutral-900">Secondary</Button>

// ❌ Wrong
<Button className="bg-neutral-900">Primary Action</Button>  {/* Brand reserved for CTAs */}
```

#### Headings & Structure → Neutral
```tsx
// ✅ Correct
<h1 className="text-neutral-900">Page Title</h1>
<h2 className="text-neutral-800">Section Title</h2>
<p className="text-neutral-700">Body text</p>
<span className="text-neutral-600">Secondary text</span>

// ❌ Wrong
<h1 className="text-brand-primary">Page Title</h1>  {/* Don't use brand for structure */}
```

#### Backgrounds → Neutral 50/100
```tsx
// ✅ Correct
<div className="bg-neutral-50">Page background</div>
<Card className="bg-white">Card on neutral background</Card>

// ❌ Wrong
<div className="bg-brand-primary-50">Page background</div>  {/* Too much brand color */}
```

#### Feedback → Semantic
```tsx
// ✅ Correct
<Alert className="bg-semantic-success-bg border-semantic-success">
  <AlertDescription className="text-semantic-success-fg">
    Profile saved successfully
  </AlertDescription>
</Alert>

// ❌ Wrong
<Alert className="bg-green-100 border-green-500 text-green-900">
  {/* Use semantic tokens, not arbitrary greens */}
</Alert>
```

### Do/Don't Examples

**Do**: Use brand colors sparingly (CTAs, links, key interactions)
```tsx
<nav className="bg-white border-neutral-200">
  <Logo className="text-brand-primary" />  {/* Brand in logo OK */}
  <Button className="bg-brand-primary">Sign Up</Button>  {/* CTA uses brand */}
</nav>
```

**Don't**: Overuse brand colors everywhere
```tsx
<nav className="bg-brand-primary">  {/* Too much brand */}
  <Logo className="text-white" />
  <Button className="bg-brand-primary-dark">Sign Up</Button>
</nav>
```

**Do**: Use semantic colors for feedback
```tsx
<form>
  <Input aria-invalid className="border-semantic-error" />
  <p className="text-semantic-error-fg">Email is required</p>
</form>
```

**Don't**: Use brand colors for errors
```tsx
<form>
  <Input className="border-brand-primary" />  {/* Brand not for errors */}
  <p className="text-brand-primary">Email is required</p>
</form>
```

---

## 3. Typography

### Font Families

**Sans-serif** (Primary)
```css
font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
```
- Use for: Body text, headings, UI components
- Variable font features: Enable tabular-nums for tables

**Monospace** (Code)
```css
font-family: 'JetBrains Mono', 'Fira Code', 'Consolas', monospace;
```
- Use for: Code blocks, technical data, fixed-width content

### Type Scale

**6 Levels** (with line-height ratios):

| Level | Size | Line Height | Weight | Usage | Tailwind |
|-------|------|-------------|--------|-------|----------|
| Hero | 60px | 1.0 (60px) | Bold (700) | Landing page hero | text-6xl leading-none font-bold |
| Display | 48px | 1.0 (48px) | Bold (700) | Page titles | text-5xl leading-tight font-bold |
| Heading | 36px | 1.1 (40px) | Semibold (600) | Section headings | text-4xl leading-snug font-semibold |
| Title | 24px | 1.3 (32px) | Semibold (600) | Card titles | text-2xl leading-normal font-semibold |
| Body | 16px | 1.5 (24px) | Regular (400) | Paragraphs | text-base leading-relaxed |
| Caption | 14px | 1.4 (20px) | Regular (400) | Secondary text | text-sm leading-normal |

### Letter-Spacing Rules

**Display Fonts** (-1px or -0.025em): Improves scanability at large sizes
```tsx
<h1 className="text-5xl font-bold -tracking-px">Display Heading</h1>
```

**Body Text** (0px or default): Optimal legibility
```tsx
<p className="text-base tracking-normal">Paragraph text</p>
```

**CTAs** (+1px or +0.05em): Increases clickability perception
```tsx
<Button className="tracking-wide">Call to Action</Button>
```

### Line Length (Characters Per Line)

**Rule**: 50-75 characters OR 600-700px maximum width

**Implementation**:
```tsx
// ✅ Correct
<article className="max-w-[700px]">
  <p className="text-base leading-relaxed">
    This paragraph will wrap naturally at 50-75 characters,
    making it comfortable to read without excessive eye movement.
  </p>
</article>

// ❌ Wrong
<article className="w-full">
  <p>This stretches across the entire viewport...</p>
</article>
```

### Font Features

**Tabular Numbers** (for tables, dashboards)
```tsx
<td className="tabular-nums">1,234.56</td>  {/* Digits align vertically */}
```

**Slashed Zero** (for code, technical content)
```css
font-feature-settings: "zero" 1;
```

**Oldstyle Figures** (for body text, optional)
```css
font-feature-settings: "onum" 1;
```

### Hierarchy Examples

**6-Level Hierarchy**:
```tsx
<article className="space-y-8">
  <h1 className="text-6xl font-bold -tracking-px leading-none text-neutral-900">
    Hero Heading (Level 1)
  </h1>
  <h2 className="text-5xl font-bold -tracking-px leading-tight text-neutral-900">
    Display Heading (Level 2)
  </h2>
  <h3 className="text-4xl font-semibold leading-snug text-neutral-800">
    Section Heading (Level 3)
  </h3>
  <h4 className="text-2xl font-semibold leading-normal text-neutral-800">
    Card Title (Level 4)
  </h4>
  <p className="text-base leading-relaxed text-neutral-700">
    Body paragraph text (Level 5)
  </p>
  <span className="text-sm leading-normal text-neutral-600">
    Caption or secondary text (Level 6)
  </span>
</article>
```

### Do/Don't Examples

**Do**: Use 2:1 size ratio between levels
```tsx
<h2 className="text-4xl">Title (36px)</h2>
<p className="text-lg">Subtitle (18px)</p>  {/* 2:1 ratio */}
```

**Don't**: Use similar sizes for different levels
```tsx
<h2 className="text-2xl">Title (24px)</h2>
<p className="text-xl">Subtitle (20px)</p>  {/* Too close */}
```

---

## 4. Spacing & Layout

### 8pt Grid System

**Scale**: All spacing values are multiples of 4 or 8

| Tailwind | Pixels | Multiples | Usage |
|----------|--------|-----------|-------|
| 0 | 0px | 0 | None |
| 1 | 4px | 4×1 | Micro spacing (icon padding) |
| 2 | 8px | 8×1 | Base unit (tight spacing) |
| 3 | 12px | 4×3 | Small spacing |
| 4 | 16px | 8×2 | Default spacing |
| 6 | 24px | 8×3 | Comfortable spacing |
| 8 | 32px | 8×4 | Section spacing |
| 12 | 48px | 8×6 | Group spacing |
| 16 | 64px | 8×8 | Major section spacing |
| 24 | 96px | 8×12 | Page section spacing |
| 32 | 128px | 8×16 | Hero spacing |

### Layout Rules

#### Rule 1: Start with a Baseline Value
**Baseline**: 16px or 24px (space-4 or space-6)

```tsx
// ✅ Correct - 24px baseline
<div className="space-y-6">  {/* 24px between elements */}
  <Element />
  <Element />
</div>
```

#### Rule 2: Separate Groups by at Least Double
**If items are 8px apart, groups are 16px+ apart**

```tsx
// ✅ Correct
<div className="space-y-8">  {/* 32px between groups */}
  <div className="space-y-2">  {/* 8px between items */}
    <Item />
    <Item />
  </div>
  <div className="space-y-2">  {/* Another group */}
    <Item />
    <Item />
  </div>
</div>
```

#### Rule 3: Keep Distance Between Big Groups Similar
**Consistency creates rhythm**

```tsx
// ✅ Correct - Same spacing between sections
<div className="space-y-16">  {/* 64px between all sections */}
  <Section1 />
  <Section2 />
  <Section3 />
</div>

// ❌ Wrong - Random spacing
<div>
  <Section1 className="mb-8" />
  <Section2 className="mb-16" />
  <Section3 className="mb-4" />
</div>
```

#### Rule 4: Use Ratios for Line Heights
- **Display**: 1 to 1 ratio (leading-none or leading-tight)
- **Paragraph**: 1 to 1.5 ratio (leading-relaxed)

```tsx
// ✅ Correct
<h1 className="text-5xl leading-tight">Display (1:1)</h1>
<p className="text-base leading-relaxed">Paragraph (1:1.5)</p>
```

### Breakpoints

**Mobile-first approach**:

| Breakpoint | Min Width | Typical Device |
|------------|-----------|----------------|
| sm | 640px | Large phone, small tablet |
| md | 768px | Tablet |
| lg | 1024px | Desktop |
| xl | 1280px | Large desktop |
| 2xl | 1536px | Extra large desktop |

**Usage**:
```tsx
<div className="
  px-4 py-6           // Mobile: 16px padding, 24px vertical
  sm:px-6 sm:py-8     // Tablet: 24px padding, 32px vertical
  lg:px-8 lg:py-12    // Desktop: 32px padding, 48px vertical
  max-w-7xl mx-auto   // Constrain width, center
">
  Responsive container
</div>
```

### Component Spacing Patterns

**Form Fields**:
```tsx
<div className="space-y-4">  {/* 16px between fields */}
  <div className="space-y-2">  {/* 8px between label and input */}
    <Label>Email</Label>
    <Input />
  </div>
  <div className="space-y-2">
    <Label>Password</Label>
    <Input />
  </div>
</div>
```

**Card Content**:
```tsx
<Card className="p-6 space-y-4">  {/* 24px padding, 16px spacing */}
  <CardHeader className="space-y-2">  {/* 8px in header */}
    <CardTitle>Title</CardTitle>
    <CardDescription>Description</CardDescription>
  </CardHeader>
  <CardContent>Content</CardContent>
</Card>
```

---

## 5. Visual Elements

### Shadows & Elevation

**Principle**: Use shadows for depth, not borders (except dividers)

**Elevation Scale** (z-index metaphor):

| Level | Shadow | Usage | Tailwind |
|-------|--------|-------|----------|
| z-0 | none | Flat elements | shadow-none |
| z-1 | Subtle | Cards, inputs | shadow-sm |
| z-2 | Default | Elevated cards | shadow-md |
| z-3 | Raised | Buttons, tabs | shadow-lg |
| z-4 | Floating | Dropdowns, popovers | shadow-xl |
| z-5 | Modal | Modals, dialogs | shadow-2xl |

**Examples**:
```tsx
// ✅ Correct - Shadows for depth
<Card className="shadow-md hover:shadow-lg transition-shadow">
  Card with elevation
</Card>

// ❌ Wrong - Borders on cards
<Card className="border-2 border-gray-300">
  Flat card with border (looks dated)
</Card>
```

**When to use borders**:
- Dividers only (Separator component)
- Input field outlines (focus states)
- Table cell borders

### Border Radius

**Scale**:

| Size | Radius | Usage | Tailwind |
|------|--------|-------|----------|
| None | 0px | Square elements | rounded-none |
| SM | 4px | Small buttons, badges | rounded-sm |
| MD | 8px | Default (cards, inputs) | rounded-md |
| LG | 12px | Large buttons, panels | rounded-lg |
| XL | 16px | Hero cards | rounded-xl |
| Full | 9999px | Pills, avatars | rounded-full |

### Gradients

**Rule**: Monochromatic, <20% opacity delta, vertical or horizontal only

**Examples**:
```tsx
// ✅ Correct - Subtle monochromatic gradient
<div className="bg-gradient-to-b from-neutral-50 to-neutral-100">
  {/* 10% opacity delta (98% → 96%), vertical */}
</div>

<div className="bg-gradient-to-t from-brand-primary/5 to-brand-primary/15">
  {/* 10% opacity delta (5% → 15%), vertical accent */}
</div>

// ❌ Wrong - Rainbow gradient
<div className="bg-gradient-to-br from-purple-500 via-pink-500 to-red-500">
  {/* Multi-color, diagonal - too loud */}
</div>

// ❌ Wrong - High contrast
<div className="bg-gradient-to-r from-black to-white">
  {/* Too harsh */}
</div>
```

### Soft Textured Backgrounds

**Usage**: Subtle noise texture (<5% opacity)

```tsx
<div className="relative bg-neutral-50">
  <div className="absolute inset-0 opacity-[0.03]" style={{
    backgroundImage: "url('data:image/svg+xml,...')"  {/* Noise texture */}
  }} />
  <div className="relative">Content</div>
</div>
```

### Motion & Transitions

**Timing Functions**:
- **ease-out**: Element entering view (default)
- **ease-in**: Element leaving view
- **ease-in-out**: Element changing state

**Durations**:
- **75ms**: Micro-interactions (hover, focus)
- **150ms**: Component transitions (dropdown, tooltip)
- **300ms**: Page transitions, modals
- **500ms**: Complex animations

**Examples**:
```tsx
// ✅ Correct - Subtle hover
<Button className="transition-all duration-150 hover:shadow-lg hover:scale-105">
  Hover Me
</Button>

// ❌ Wrong - Too slow
<Button className="transition-all duration-1000">
  Sluggish
</Button>
```

### Focus States

**Rule**: Always show focus (ring-2 ring-brand-primary ring-offset-2)

```tsx
// ✅ Correct
<Button className="focus:ring-2 focus:ring-brand-primary focus:ring-offset-2">
  Accessible button
</Button>

// ❌ Wrong
<Button className="focus:outline-none">
  No focus indicator (inaccessible)
</Button>
```

---

## 6. Components (Lightweight Guidelines)

### Buttons

**Purpose**: Primary user actions

**Key Specs**:
- Height: 44px minimum (touch target)
- Padding: Horizontal 2x vertical (px-4 py-2 for default)
- Border-radius: rounded-md (default), rounded-lg (large)
- Font: Medium weight (600), tracking-wide (+0.05em)

**Variants**:
- **Default**: bg-brand-primary, text-neutral-50, shadow-sm on hover
- **Secondary**: bg-neutral-200, text-neutral-900, no shadow
- **Outline**: border-neutral-300, hover:bg-neutral-100
- **Ghost**: transparent, hover:bg-neutral-100
- **Destructive**: bg-semantic-error, text-white, shadow-sm on hover

**States**:
- Hover: Darken 1 step, add shadow-sm
- Active: scale-95, darken 2 steps
- Focus: ring-2 ring-brand-primary ring-offset-2
- Disabled: opacity-50, cursor-not-allowed

**Base Component**: shadcn/ui Button

**Usage**:
```tsx
<Button>Primary Action</Button>
<Button variant="secondary">Secondary</Button>
<Button variant="destructive" size="sm">Delete</Button>
```

### Forms

**Purpose**: Data input and validation

**Key Specs**:
- Height: 44px (consistent with buttons)
- Padding: px-3 py-2
- Border: border-neutral-300, focus:border-brand-primary
- Focus: ring-2 ring-brand-primary ring-offset-0
- Invalid: border-semantic-error, ring-semantic-error

**Pattern**: Inline validation (Stripe-style)
```tsx
<div className="space-y-2">
  <Label htmlFor="email">Email</Label>
  <Input
    id="email"
    type="email"
    aria-invalid={hasError}
    aria-describedby="email-error"
    className="focus:ring-2 focus:ring-brand-primary"
  />
  {hasError && (
    <p id="email-error" className="text-sm text-semantic-error-fg flex items-center gap-1">
      <AlertCircleIcon className="w-4 h-4" />
      Please enter a valid email
    </p>
  )}
</div>
```

**Base Components**: shadcn/ui Input, Label, Textarea, Select

### Cards

**Purpose**: Grouped content with elevation

**Key Specs**:
- Padding: p-6 (24px)
- Background: bg-white
- Shadow: shadow-md (default), shadow-lg (hover)
- Border-radius: rounded-lg
- Border: Use shadows, not borders

**Pattern**: Header → Content → Footer
```tsx
<Card className="shadow-md hover:shadow-lg transition-shadow">
  <CardHeader className="space-y-2">
    <CardTitle className="text-2xl font-semibold">Title</CardTitle>
    <CardDescription className="text-neutral-600">Description</CardDescription>
  </CardHeader>
  <CardContent className="space-y-4">
    Content here
  </CardContent>
  <CardFooter className="flex justify-between">
    <Button variant="ghost">Cancel</Button>
    <Button>Save</Button>
  </CardFooter>
</Card>
```

**Base Component**: shadcn/ui Card

### Navigation

**Purpose**: Site/app navigation

**Key Specs**:
- Height: 64px (desktop), 56px (mobile)
- Padding: px-6 (desktop), px-4 (mobile)
- Background: bg-white, border-b border-neutral-200
- Sticky: sticky top-0 z-50

**Pattern**: Logo → Nav Items → Actions
```tsx
<nav className="sticky top-0 z-50 bg-white border-b border-neutral-200">
  <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
    <Logo />
    <div className="hidden md:flex items-center gap-6">
      <NavLink>Home</NavLink>
      <NavLink>About</NavLink>
    </div>
    <Button>Sign Up</Button>
  </div>
</nav>
```

### Modals & Overlays

**Purpose**: Focus attention, block background interaction

**Key Specs**:
- Overlay: bg-neutral-900/50 (50% opacity)
- Modal: bg-white, shadow-2xl, rounded-lg
- Width: max-w-md (default), max-w-2xl (large)
- Padding: p-6
- Close: X icon top-right, ESC key

**Pattern**:
```tsx
<Dialog>
  <DialogTrigger asChild>
    <Button>Open Modal</Button>
  </DialogTrigger>
  <DialogContent className="max-w-md">
    <DialogHeader>
      <DialogTitle>Modal Title</DialogTitle>
      <DialogDescription>Description text</DialogDescription>
    </DialogHeader>
    <div className="space-y-4">Content</div>
    <DialogFooter>
      <Button variant="outline">Cancel</Button>
      <Button>Confirm</Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

**Base Component**: shadcn/ui Dialog

### Lists

**Purpose**: Display bullet points with icons (Core Rule #2)

**Key Specs**:
- Spacing: space-y-3 (12px between items)
- Icon size: w-5 h-5 (20px)
- Icon color: text-semantic-success-fg or text-brand-primary
- Icon position: items-start (top-aligned)

**Pattern**:
```tsx
<ul className="space-y-3">
  <li className="flex items-start gap-3">
    <CheckCircleIcon className="w-5 h-5 text-semantic-success-fg mt-0.5 shrink-0" />
    <span className="text-neutral-700">Feature description with icon</span>
  </li>
  <li className="flex items-start gap-3">
    <CheckCircleIcon className="w-5 h-5 text-semantic-success-fg mt-0.5 shrink-0" />
    <span className="text-neutral-700">Another feature</span>
  </li>
</ul>
```

### Tables

**Purpose**: Tabular data display

**Key Specs**:
- Font: tabular-nums (digits align)
- Cell padding: px-4 py-3
- Header: bg-neutral-100, font-semibold
- Borders: border-neutral-200 (horizontal only)
- Hover: hover:bg-neutral-50 (rows)

**Pattern**:
```tsx
<Table>
  <TableHeader>
    <TableRow>
      <TableHead>Name</TableHead>
      <TableHead className="text-right tabular-nums">Value</TableHead>
    </TableRow>
  </TableHeader>
  <TableBody>
    <TableRow className="hover:bg-neutral-50">
      <TableCell>Item 1</TableCell>
      <TableCell className="text-right tabular-nums">1,234.56</TableCell>
    </TableRow>
  </TableBody>
</Table>
```

**Base Component**: shadcn/ui Table

### Feedback (Alerts, Toasts)

**Purpose**: System feedback messages

**Key Specs (Alerts)**:
- Padding: p-4
- Background: semantic-{type}-bg
- Border: border-semantic-{type}
- Icon: semantic-{type}-fg, w-5 h-5
- Border-radius: rounded-md

**Pattern**:
```tsx
<Alert className="bg-semantic-info-bg border-semantic-info">
  <InfoIcon className="w-5 h-5 text-semantic-info-fg" />
  <AlertTitle className="text-semantic-info-fg">Note</AlertTitle>
  <AlertDescription className="text-semantic-info-fg">
    Processing may take 2-3 minutes.
  </AlertDescription>
</Alert>
```

**Base Components**: shadcn/ui Alert, Toast

---

## 7. Patterns

### Bullet Points with Icons (Core Rule #2)

**When to use**: Feature lists, benefits, checklists, instructions

**Pattern**:
```tsx
<ul className="space-y-3 max-w-[700px]">
  {features.map(feature => (
    <li key={feature.id} className="flex items-start gap-3">
      <feature.icon className="w-5 h-5 text-brand-primary mt-0.5 shrink-0" />
      <div>
        <h4 className="font-semibold text-neutral-900">{feature.title}</h4>
        <p className="text-sm text-neutral-700">{feature.description}</p>
      </div>
    </li>
  ))}
</ul>
```

### Responsive Behavior

**Mobile-first approach**:
```tsx
<div className="
  grid grid-cols-1       // Mobile: 1 column
  sm:grid-cols-2         // Tablet: 2 columns
  lg:grid-cols-3         // Desktop: 3 columns
  gap-4                  // 16px gap
  sm:gap-6               // 24px gap on tablet
  lg:gap-8               // 32px gap on desktop
">
  {items.map(item => <Card key={item.id}>{item}</Card>)}
</div>
```

### Empty States

**Key Specs**:
- Icon: w-12 h-12, text-neutral-400
- Heading: text-xl font-semibold
- Description: text-neutral-600, max-w-md
- CTA: Button below description

**Pattern**:
```tsx
<div className="flex flex-col items-center justify-center py-12 space-y-4">
  <InboxIcon className="w-12 h-12 text-neutral-400" />
  <div className="text-center space-y-2">
    <h3 className="text-xl font-semibold text-neutral-900">No messages yet</h3>
    <p className="text-neutral-600 max-w-md">
      When you receive messages, they'll appear here.
    </p>
  </div>
  <Button>Send your first message</Button>
</div>
```

### Error States

**Key Specs**:
- Icon: w-12 h-12, text-semantic-error-fg
- Heading: text-xl font-semibold, text-neutral-900
- Description: text-neutral-700
- Error details: text-sm text-neutral-600, font-mono
- CTA: Button or link to retry/support

**Pattern**:
```tsx
<div className="flex flex-col items-center justify-center py-12 space-y-4">
  <AlertCircleIcon className="w-12 h-12 text-semantic-error-fg" />
  <div className="text-center space-y-2">
    <h3 className="text-xl font-semibold text-neutral-900">
      Failed to load data
    </h3>
    <p className="text-neutral-700 max-w-md">
      We encountered an error while fetching your data.
    </p>
    {errorCode && (
      <p className="text-sm text-neutral-600 font-mono">Error: {errorCode}</p>
    )}
  </div>
  <Button onClick={retry}>Try Again</Button>
</div>
```

### Loading States

**Key Specs**:
- Spinner: w-8 h-8, animate-spin
- Text: text-neutral-600
- Optional: Skeleton UI for content placeholders

**Pattern (Spinner)**:
```tsx
<div className="flex flex-col items-center justify-center py-12 space-y-4">
  <Loader2Icon className="w-8 h-8 animate-spin text-brand-primary" />
  <p className="text-neutral-600">Loading...</p>
</div>
```

**Pattern (Skeleton)**:
```tsx
<Card className="p-6 space-y-4">
  <Skeleton className="h-8 w-48" />  {/* Title */}
  <Skeleton className="h-4 w-full" />  {/* Line 1 */}
  <Skeleton className="h-4 w-3/4" />  {/* Line 2 */}
</Card>
```

### Accessibility Patterns

**Keyboard Navigation**:
- All interactive elements focusable (no tabindex="-1" unless managed)
- Focus visible (ring-2 ring-brand-primary ring-offset-2)
- Skip links for main content
- Tab order follows visual order

**Screen Reader Support**:
- Semantic HTML (nav, main, section, article)
- ARIA labels for icons (aria-label or sr-only text)
- ARIA live regions for dynamic content
- Form field associations (label htmlFor, aria-describedby)

**Color Contrast**:
- WCAG AA minimum (4.5:1 for normal text, 3:1 for large text)
- WCAG AAA preferred (7:1 for normal text, 4.5:1 for large text)
- Test with contrast checker tools

**Example**:
```tsx
<Button
  className="focus:ring-2 focus:ring-brand-primary focus:ring-offset-2"
  aria-label="Save changes"
>
  <SaveIcon className="w-5 h-5" aria-hidden="true" />
  <span className="sr-only">Save changes</span>  {/* Screen reader only */}
</Button>
```

---

## 8. Implementation

### Tailwind CSS Integration

**Config Requirements** (tailwind.config.js):
```js
module.exports = {
  theme: {
    extend: {
      colors: {
        brand: {
          primary: 'oklch(0.55 0.22 250)',
          // ... other brand colors
        },
        semantic: {
          success: { /* oklch values */ },
          error: { /* oklch values */ },
          // ... other semantic colors
        },
        neutral: {
          50: 'oklch(0.98 0.00 0)',
          // ... full neutral scale
        }
      },
      spacing: {
        // 8pt grid already in Tailwind default
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      }
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ]
}
```

### Component Usage from ui-inventory.md

**Before creating custom components**:
1. Check `design/systems/ui-inventory.md`
2. Use shadcn/ui primitives (Button, Input, Card, etc.)
3. Compose primitives (don't build from scratch)
4. Only create custom if no primitive exists

**Component Library Location**: `/app/components/ui/*` (shadcn/ui components)

### Validation Rules

**Automated Checks** (design-lint.js):
1. **No hardcoded colors**: Grep for hex (#), rgb(), hsl()
2. **No arbitrary spacing**: Grep for [Npx] syntax
3. **Component usage**: Verify components from ui-inventory.md
4. **Shadows not borders**: Cards use shadow-*, not border-*
5. **Typography hierarchy**: Verify 2:1 ratio between levels
6. **Letter-spacing**: Display -tracking-px, Body tracking-normal, CTAs tracking-wide
7. **Line length**: Text containers max-w-[700px]
8. **Focus states**: All interactive elements have focus:ring-*

**Run validation**:
```bash
node .spec-flow/scripts/design-lint.js apps/app/
```

### Testing Requirements

**Visual Tests** (Playwright):
- Snapshot tests for key components
- Responsive tests (mobile, tablet, desktop)
- Squint test validation (blur test)

**Accessibility Tests**:
- axe-core integration (pa11y or @axe-core/playwright)
- Keyboard navigation tests
- Screen reader tests (NVDA, JAWS, VoiceOver)

**Performance Tests**:
- Lighthouse CI (>90 accessibility, >85 performance)
- Bundle size monitoring (<100KB JS initial)

---

## Appendix: Token Reference

**Full token specification**: `design/systems/tokens.json`

**Component library**: `design/systems/ui-inventory.md`

**Validation script**: `.spec-flow/scripts/design-lint.js`

---

## Changelog

### v1.0.0 (Initial)
- Established 8 core sections
- Documented core 9 rules
- Created OKLCH color system
- Defined 8pt grid spacing
- Lightweight component guidelines
