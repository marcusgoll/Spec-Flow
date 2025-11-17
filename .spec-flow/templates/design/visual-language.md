# Visual Language

**Project**: {{PROJECT_NAME}}
**Last Updated**: {{LAST_UPDATED}}
**Version**: 1.0.0

---

## Overview

This document defines the complete visual system for {{PROJECT_NAME}}, including color palettes, typography scales, spacing systems, and visual treatments. All values are implemented in `design/systems/tokens.css`.

**Token Architecture**:
- **Layer 1**: Primitives (color scales, spacing, typography)
- **Layer 2**: Semantic (text, background, border colors)
- **Layer 3**: Component (button, input, card styles)

---

## Color System

### Color Strategy

**Palette Size**: {{COLOR_PALETTE_SIZE}}
**Neutrals Approach**: {{NEUTRALS_APPROACH}}
**Semantic Colors**: {{SEMANTIC_COLOR_NEEDS}}

### Primary Palette

**Base Color**: {{PRIMARY_COLOR}}

**Scale (50-950)**:

```css
--color-primary-50:  {{PRIMARY_50}}   /* Lightest - backgrounds */
--color-primary-100: {{PRIMARY_100}}  /* Very light - hover states */
--color-primary-200: {{PRIMARY_200}}  /* Light */
--color-primary-300: {{PRIMARY_300}}
--color-primary-400: {{PRIMARY_400}}
--color-primary-500: {{PRIMARY_500}}  /* Base color */
--color-primary-600: {{PRIMARY_600}}  /* Hover states */
--color-primary-700: {{PRIMARY_700}}  /* Active states */
--color-primary-800: {{PRIMARY_800}}
--color-primary-900: {{PRIMARY_900}}  /* Darkest - text on light */
--color-primary-950: {{PRIMARY_950}}  /* Ultra dark */
```

**Usage Guidelines**:
- `50-200`: Backgrounds, subtle accents
- `300-500`: Borders, icons, non-critical UI
- `600-700`: Primary actions, links, interactive elements
- `800-950`: Text on light backgrounds, emphasis

### Neutral Palette

**Approach**: {{NEUTRALS_APPROACH}}

{{#if NEUTRALS_TRUE_GRAY}}
**True Grays** (R=G=B):
- Characteristics: Pure achromatic grays
- Use Cases: Text, borders, backgrounds
- Emotional Feel: Professional, neutral, clean
{{/if}}

{{#if NEUTRALS_WARM}}
**Warm Grays** (slight red/yellow tint):
- Characteristics: Inviting, comfortable
- Use Cases: Content-heavy applications, reading-focused UIs
- Hex Tint: +5° hue shift toward red-yellow
{{/if}}

{{#if NEUTRALS_COOL}}
**Cool Grays** (slight blue tint):
- Characteristics: Technical, modern, digital
- Use Cases: Developer tools, dashboards, data UIs
- Hex Tint: +5° hue shift toward blue
{{/if}}

{{#if NEUTRALS_BRAND_TINTED}}
**Brand-Tinted Grays** ({{PRIMARY_COLOR}} tint):
- Characteristics: Cohesive with brand, subtle personality
- Use Cases: All surfaces, reinforces brand identity
- Calculation: OKLCH mix of neutral + 5% primary hue
{{/if}}

**Scale**:

```css
--color-neutral-50:  {{NEUTRAL_50}}
--color-neutral-100: {{NEUTRAL_100}}
--color-neutral-200: {{NEUTRAL_200}}
--color-neutral-300: {{NEUTRAL_300}}
--color-neutral-400: {{NEUTRAL_400}}
--color-neutral-500: {{NEUTRAL_500}}  /* Base neutral */
--color-neutral-600: {{NEUTRAL_600}}
--color-neutral-700: {{NEUTRAL_700}}
--color-neutral-800: {{NEUTRAL_800}}
--color-neutral-900: {{NEUTRAL_900}}
--color-neutral-950: {{NEUTRAL_950}}
```

### Semantic Colors

**Purpose**: Communicate state and meaning independent of brand colors.

{{#if HAS_SUCCESS_COLOR}}
**Success** (Green):
```css
--color-success-500: {{SUCCESS_500}}  /* Base: OKLCH(0.6, 0.15, 140°) */
--color-success-600: {{SUCCESS_600}}  /* Hover */
--color-success-700: {{SUCCESS_700}}  /* Active */
```
- **Usage**: Confirmations, completed states, positive feedback
- **Text Contrast**: ≥4.5:1 on white (WCAG AA)
{{/if}}

{{#if HAS_WARNING_COLOR}}
**Warning** (Yellow/Orange):
```css
--color-warning-500: {{WARNING_500}}  /* Base: OKLCH(0.7, 0.15, 80°) */
--color-warning-600: {{WARNING_600}}  /* Hover */
--color-warning-700: {{WARNING_700}}  /* Active */
```
- **Usage**: Caution messages, reversible actions, important notices
- **Text Contrast**: ≥4.5:1 on white
{{/if}}

{{#if HAS_ERROR_COLOR}}
**Error** (Red):
```css
--color-error-500: {{ERROR_500}}  /* Base: OKLCH(0.55, 0.18, 20°) */
--color-error-600: {{ERROR_600}}  /* Hover */
--color-error-700: {{ERROR_700}}  /* Active */
```
- **Usage**: Error messages, destructive actions, validation failures
- **Text Contrast**: ≥4.5:1 on white
{{/if}}

{{#if HAS_INFO_COLOR}}
**Info** (Blue):
```css
--color-info-500: {{INFO_500}}  /* Base: OKLCH(0.6, 0.15, 250°) */
--color-info-600: {{INFO_600}}  /* Hover */
--color-info-700: {{INFO_700}}  /* Active */
```
- **Usage**: Informational messages, help tooltips, neutral notifications
{{/if}}

### Surface Colors

**Levels**: {{SURFACE_COLOR_LEVELS}}

```css
/* Light Mode */
--color-background-primary:   #ffffff    /* Base surface */
--color-background-secondary: {{NEUTRAL_50}}   /* Elevated cards */
--color-background-tertiary:  {{NEUTRAL_100}}  /* Nested elements */
--color-background-inverse:   {{NEUTRAL_900}}  /* Dark mode toggle */

/* Dark Mode (auto-generated inverse) */
@media (prefers-color-scheme: dark) {
  --color-background-primary:   {{NEUTRAL_900}}
  --color-background-secondary: {{NEUTRAL_800}}
  --color-background-tertiary:  {{NEUTRAL_700}}
  --color-background-inverse:   #ffffff
}
```

**Elevation Strategy**:
- **Level 0** (primary): Page background, base layer
- **Level 1** (secondary): Cards, panels, modals
- **Level 2** (tertiary): Dropdowns, popovers, tooltips

### Text Colors

**WCAG Compliance**: All text colors meet {{CONTRAST_REQUIREMENT}} contrast ratio.

```css
/* Light Mode */
--color-text-primary:   {{TEXT_PRIMARY}}    /* Body text (contrast: {{TEXT_PRIMARY_RATIO}}:1) */
--color-text-secondary: {{TEXT_SECONDARY}}  /* Subdued text */
--color-text-tertiary:  {{TEXT_TERTIARY}}   /* Placeholder text */
--color-text-inverse:   {{TEXT_INVERSE}}    /* Text on dark backgrounds */
--color-text-link:      {{TEXT_LINK}}       /* Hyperlinks */
--color-text-link-hover:{{TEXT_LINK_HOVER}} /* Hovered links */

/* Dark Mode */
@media (prefers-color-scheme: dark) {
  --color-text-primary:   {{TEXT_PRIMARY_DARK}}
  --color-text-secondary: {{TEXT_SECONDARY_DARK}}
  --color-text-tertiary:  {{TEXT_TERTIARY_DARK}}
  --color-text-inverse:   {{TEXT_INVERSE_DARK}}
}
```

**Auto-Fix Report**:
- Original text color: {{TEXT_ORIGINAL}}
- Fixed to meet WCAG AA: {{TEXT_FIXED}}
- Contrast ratio: {{TEXT_CONTRAST_RATIO}}:1 ✅

---

## Typography

### Font Families

**Sans-Serif** (Primary):
```css
--font-sans: {{FONT_SANS}}
```
- **Style**: {{TYPOGRAPHY_STYLE}}
- **Fallback**: system-ui, -apple-system, sans-serif
- **Use Cases**: UI, headings, body text, buttons

**Monospace** (Code):
```css
--font-mono: {{FONT_MONO}}
```
- **Fallback**: Consolas, Monaco, monospace
- **Use Cases**: Code blocks, terminal output, technical data

{{#if HAS_SERIF}}
**Serif** (Optional):
```css
--font-serif: {{FONT_SERIF}}
```
- **Use Cases**: Long-form content, editorial layouts
{{/if}}

### Type Scale

**Strategy**: {{TYPE_SCALE}}

{{#if TYPE_SCALE_CONSERVATIVE}}
**Conservative Scale** (6 sizes):
```css
--text-sm:   0.875rem  /* 14px */
--text-base: 1rem      /* 16px - base */
--text-lg:   1.125rem  /* 18px */
--text-xl:   1.25rem   /* 20px */
--text-2xl:  1.5rem    /* 24px */
--text-3xl:  1.875rem  /* 30px */
```
- **Rationale**: Minimal variation, clear hierarchy
- **Use Cases**: Data-heavy UIs, dashboards
{{/if}}

{{#if TYPE_SCALE_STANDARD}}
**Standard Scale** (8 sizes):
```css
--text-xs:   0.75rem   /* 12px */
--text-sm:   0.875rem  /* 14px */
--text-base: 1rem      /* 16px - base */
--text-lg:   1.125rem  /* 18px */
--text-xl:   1.25rem   /* 20px */
--text-2xl:  1.5rem    /* 24px */
--text-3xl:  1.875rem  /* 30px */
--text-4xl:  2.25rem   /* 36px */
```
- **Rationale**: Balanced hierarchy, flexible
- **Use Cases**: General applications
{{/if}}

{{#if TYPE_SCALE_EXPRESSIVE}}
**Expressive Scale** (10+ sizes):
```css
--text-xs:   0.75rem   /* 12px */
--text-sm:   0.875rem  /* 14px */
--text-base: 1rem      /* 16px - base */
--text-lg:   1.125rem  /* 18px */
--text-xl:   1.25rem   /* 20px */
--text-2xl:  1.5rem    /* 24px */
--text-3xl:  1.875rem  /* 30px */
--text-4xl:  2.25rem   /* 36px */
--text-5xl:  3rem      /* 48px */
--text-6xl:  3.75rem   /* 60px */
--text-7xl:  4.5rem    /* 72px */
```
- **Rationale**: Dramatic hierarchy, editorial focus
- **Use Cases**: Marketing sites, content platforms
{{/if}}

### Font Weights

**Available Weights**: {{FONT_WEIGHTS}}

```css
--font-normal:   400
--font-medium:   500   /* Optional */
--font-semibold: 600   /* Optional */
--font-bold:     700
```

**Usage**:
- **400 (Normal)**: Body text, paragraphs
- **500 (Medium)**: Subtle emphasis, UI labels
- **600 (Semibold)**: Section headings, card titles
- **700 (Bold)**: Page headings, strong emphasis

### Line Heights

**System**: {{LINE_HEIGHT_SYSTEM}}

{{#if LINE_HEIGHT_FIXED}}
**Fixed** (1.5 everywhere):
```css
--leading-normal: 1.5
```
- **Rationale**: Consistent vertical rhythm
- **Use Cases**: Data-heavy UIs, technical content
{{/if}}

{{#if LINE_HEIGHT_RESPONSIVE}}
**Responsive** (varies by size):
```css
--leading-tight:   1.25  /* Headings */
--leading-normal:  1.5   /* Body text */
--leading-relaxed: 1.75  /* Long-form content */
```
- **Rationale**: Optimized readability per context
- **Use Cases**: Mixed content types (headings + paragraphs)
{{/if}}

### Heading Styles

**Case**: {{HEADING_STYLE}}

{{#if HEADING_UPPERCASE}}
**Uppercase**: All headings in UPPERCASE
- Creates visual separation
- Use sparingly (accessibility concern for dyslexia)
{{/if}}

{{#if HEADING_SENTENCE}}
**Sentence case**: First word capitalized
- Modern, approachable
- Matches conversational tone
{{/if}}

{{#if HEADING_TITLE}}
**Title case**: Major Words Capitalized
- Traditional, formal
- Clear hierarchy markers
{{/if}}

---

## Spacing System

### Base Unit

**Preference**: {{DENSITY_PREFERENCE}}
**Base Unit**: {{SPACING_BASE_UNIT}}px

### Scale

```css
--space-0:  0
--space-1:  {{SPACING_1}}   /* {{SPACING_BASE_UNIT}}px */
--space-2:  {{SPACING_2}}   /* {{SPACING_BASE_UNIT * 2}}px */
--space-3:  {{SPACING_3}}   /* {{SPACING_BASE_UNIT * 3}}px */
--space-4:  {{SPACING_4}}   /* {{SPACING_BASE_UNIT * 4}}px */
--space-5:  {{SPACING_5}}   /* {{SPACING_BASE_UNIT * 5}}px */
--space-6:  {{SPACING_6}}   /* {{SPACING_BASE_UNIT * 6}}px */
--space-8:  {{SPACING_8}}   /* {{SPACING_BASE_UNIT * 8}}px */
--space-10: {{SPACING_10}}  /* {{SPACING_BASE_UNIT * 10}}px */
--space-12: {{SPACING_12}}  /* {{SPACING_BASE_UNIT * 12}}px */
--space-16: {{SPACING_16}}  /* {{SPACING_BASE_UNIT * 16}}px */
```

**Usage Guidelines**:
- `0-2`: Tight spacing (form fields, list items)
- `3-4`: Component padding (buttons, inputs)
- `5-6`: Card padding, section spacing
- `8-12`: Page margins, major sections
- `16+`: Layout gutters, page-level spacing

---

## Border Radius

**Style**: {{BORDER_RADIUS_STYLE}}

```css
--rounded-none: 0
--rounded-sm:   {{ROUNDED_SM}}
--rounded:      {{ROUNDED_DEFAULT}}  /* Default */
--rounded-md:   {{ROUNDED_MD}}
--rounded-lg:   {{ROUNDED_LG}}
--rounded-xl:   {{ROUNDED_XL}}
--rounded-2xl:  {{ROUNDED_2XL}}
--rounded-full: 9999px  /* Pills, avatars */
```

{{#if BORDER_RADIUS_SHARP}}
**Sharp** (0-2px):
- Modern, technical aesthetic
- Clear boundaries
{{/if}}

{{#if BORDER_RADIUS_ROUNDED}}
**Rounded** (4-8px):
- Friendly, approachable
- Balanced softness
{{/if}}

{{#if BORDER_RADIUS_VERY_ROUNDED}}
**Very Rounded** (12-16px):
- Playful, modern
- Strong brand personality
{{/if}}

**Usage**:
- **Buttons**: `--rounded` ({{ROUNDED_DEFAULT}})
- **Inputs**: `--rounded-md` ({{ROUNDED_MD}})
- **Cards**: `--rounded-lg` ({{ROUNDED_LG}})
- **Modals**: `--rounded-xl` ({{ROUNDED_XL}})
- **Avatars**: `--rounded-full`

---

## Shadows & Elevation

**Style**: {{SHADOW_STYLE}}

{{#if SHADOW_MINIMAL}}
**Minimal** (subtle elevation):
```css
--shadow-sm:  0 1px 2px 0 rgb(0 0 0 / 0.05)
--shadow:     0 1px 3px 0 rgb(0 0 0 / 0.1)
--shadow-md:  0 4px 6px -1px rgb(0 0 0 / 0.1)
--shadow-lg:  0 10px 15px -3px rgb(0 0 0 / 0.1)
```
- Characteristics: Very subtle depth
- Use Cases: Modern, flat designs
{{/if}}

{{#if SHADOW_BOLD}}
**Bold** (strong depth):
```css
--shadow-sm:  0 2px 4px 0 rgb(0 0 0 / 0.1)
--shadow:     0 4px 8px 0 rgb(0 0 0 / 0.15)
--shadow-md:  0 8px 16px -2px rgb(0 0 0 / 0.15)
--shadow-lg:  0 16px 32px -4px rgb(0 0 0 / 0.2)
```
- Characteristics: Noticeable elevation
- Use Cases: Material Design-inspired UIs
{{/if}}

**Elevation Layers**:
1. **Base** (no shadow): Page background
2. **Card** (`--shadow`): Elevated content
3. **Dropdown** (`--shadow-md`): Floating panels
4. **Modal** (`--shadow-lg`): Overlay content

---

## Iconography

**Style**: {{ICON_STYLE}}

{{#if ICON_OUTLINE}}
**Outline Icons**:
- Characteristics: Stroke-based, minimal, clean
- Weight: 1.5-2px strokes
- Libraries: Heroicons Outline, Lucide, Feather
{{/if}}

{{#if ICON_SOLID}}
**Solid Icons**:
- Characteristics: Filled shapes, bold, clear
- Use Cases: Active states, primary actions
- Libraries: Heroicons Solid, Font Awesome Solid
{{/if}}

{{#if ICON_DUOTONE}}
**Duotone Icons**:
- Characteristics: Two-color, layered depth
- Use Cases: Feature highlights, marketing
- Libraries: Font Awesome Duotone, custom set
{{/if}}

**Sizing**:
- `16px`: Inline with text (sm)
- `20px`: Default UI icons
- `24px`: Prominent actions (md)
- `32px`: Feature highlights (lg)
- `48px+`: Hero sections (xl)

---

## Illustrations

**Style**: {{ILLUSTRATION_STYLE}}

{{#if ILLUSTRATION_ABSTRACT}}
**Abstract**:
- Geometric shapes, patterns
- Brand colors only (2-3 per composition)
- Symbolic, minimal detail
{{/if}}

{{#if ILLUSTRATION_PICTORIAL}}
**Pictorial**:
- Recognizable objects and scenes
- Friendly, approachable style
- Moderate detail, stylized realism
{{/if}}

{{#if ILLUSTRATION_PHOTOGRAPHY}}
**Photography**:
- Real photography, authentic moments
- Color treatment: {{PHOTOGRAPHY_TREATMENT}}
- Style: {{PHOTOGRAPHY_STYLE}}
{{/if}}

---

## References

- **Design Tokens**: `design/systems/tokens.css`
- **Brand Guidelines**: `docs/design/brand-guidelines.md`
- **Accessibility Standards**: `docs/design/accessibility-standards.md`
- **Component Governance**: `docs/design/component-governance.md`

---

**Document Owner**: {{DOCUMENT_OWNER}}
**Last Review**: {{LAST_REVIEW_DATE}}
**Next Review**: {{NEXT_REVIEW_DATE}}
