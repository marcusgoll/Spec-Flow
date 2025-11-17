# Brand Guidelines

**Project**: {{PROJECT_NAME}}
**Last Updated**: {{LAST_UPDATED}}
**Version**: 1.0.0

---

## Overview

This document defines the brand personality, voice, and visual direction for {{PROJECT_NAME}}. These guidelines ensure consistent brand expression across all touchpoints and prevent "design drift" during feature development.

**Purpose**: Freeze design decisions before implementation to maintain cohesive brand identity.

---

## Brand Personality

### Core Identity

**Brand Archetype**: {{BRAND_PERSONALITY}}

**Emotional Response**: {{TARGET_EMOTIONAL_RESPONSE}}

**Brand Keywords**:
{{#each BRAND_KEYWORDS}}
- {{this}}
{{/each}}

### Personality Spectrum

```
Playful ←──────●──────→ Serious
Minimal ←──────●──────→ Rich
Bold    ←──────●──────→ Subtle
Modern  ←──────●──────→ Classic
Tech    ←──────●──────→ Human
```

*Note: Markers (●) indicate brand position on each spectrum*

---

## Competitive Differentiation

**How we differ from competitors**:

{{COMPETITIVE_DIFFERENTIATION}}

**Key Differentiators**:
- Visual: {{VISUAL_DIFFERENTIATION}}
- Tone: {{TONE_DIFFERENTIATION}}
- Experience: {{EXPERIENCE_DIFFERENTIATION}}

---

## Brand Voice

### Tone Guidelines

**Primary Tone**: {{PRIMARY_TONE}}

**Voice Characteristics**:
{{#if IS_PLAYFUL}}
- **Playful**: Use conversational language, occasional humor, friendly emojis (sparingly)
- **Examples**: "Let's get started!" vs "Proceed to initialization"
{{/if}}
{{#if IS_SERIOUS}}
- **Serious**: Professional language, clear instructions, no frivolity
- **Examples**: "Begin setup process" vs "Let's dive in!"
{{/if}}
{{#if IS_MINIMAL}}
- **Minimal**: Concise copy, remove unnecessary words, direct communication
- **Examples**: "Save changes" vs "Click here to save your changes"
{{/if}}

### Writing Principles

1. **Clarity over cleverness** - Users should understand immediately
2. **Consistency** - Same terms for same concepts across all surfaces
3. **User-first language** - "Your dashboard" not "The dashboard"
4. **Action-oriented** - Lead with verbs ("Create project" not "Project creation")

### Microcopy Standards

**Button Labels**:
- Primary actions: {{BUTTON_PRIMARY_STYLE}} (e.g., "Create Account" vs "Sign Up")
- Secondary actions: {{BUTTON_SECONDARY_STYLE}} (e.g., "Cancel" vs "Go Back")
- Destructive actions: {{BUTTON_DESTRUCTIVE_STYLE}} (e.g., "Delete Forever" vs "Remove")

**Error Messages**:
- Tone: {{ERROR_MESSAGE_TONE}} (e.g., "Oops! Something went wrong" vs "Error: Invalid input")
- Structure: [Problem] + [Solution] (e.g., "File too large. Maximum size is 5MB.")
- Blame: Never blame the user (e.g., "This file format isn't supported" vs "You uploaded the wrong format")

**Success Messages**:
- Tone: {{SUCCESS_MESSAGE_TONE}} (e.g., "All set!" vs "Operation completed successfully")
- Confirmation: State what happened (e.g., "Project created" vs "Success")

**Empty States**:
- Tone: {{EMPTY_STATE_TONE}} (e.g., "Nothing here yet. Create your first project!" vs "No data available")
- Guidance: Always provide next action

---

## Visual Direction

### Primary Color

**Hex**: {{PRIMARY_COLOR}}
**Meaning**: {{PRIMARY_COLOR_MEANING}}
**Usage**: Primary actions, links, brand accents

### Visual Style

**Style**: {{VISUAL_STYLE}}

{{#if VISUAL_STYLE_MODERN}}
**Characteristics**:
- Clean, minimal interfaces
- Generous whitespace
- Sans-serif typography
- Subtle shadows and depth
- Geometric shapes
{{/if}}

{{#if VISUAL_STYLE_CLASSIC}}
**Characteristics**:
- Traditional layouts
- Structured hierarchy
- Serif typography for headings
- Defined borders and sections
- Organic shapes and flourishes
{{/if}}

### Typography Direction

**Primary Font Style**: {{TYPOGRAPHY_STYLE}}

{{#if TYPOGRAPHY_GEOMETRIC}}
- **Font Family**: Geometric sans-serif (Inter, SF Pro, Montserrat)
- **Character**: Modern, clean, technical
- **Use Cases**: UI, headings, body text
{{/if}}

{{#if TYPOGRAPHY_HUMANIST}}
- **Font Family**: Humanist sans-serif (Open Sans, Nunito, Lato)
- **Character**: Friendly, approachable, readable
- **Use Cases**: Body text, long-form content
{{/if}}

{{#if TYPOGRAPHY_MONOSPACE}}
- **Font Family**: Monospace (Fira Code, Consolas, JetBrains Mono)
- **Character**: Technical, code-focused, precise
- **Use Cases**: Code blocks, technical UI, data tables
{{/if}}

### Density & Spacing

**Preference**: {{DENSITY_PREFERENCE}}

{{#if DENSITY_COMPACT}}
- **Base Unit**: 4px
- **Philosophy**: Information-dense, power-user optimized
- **Use Cases**: Dashboards, data tables, admin panels
{{/if}}

{{#if DENSITY_COMFORTABLE}}
- **Base Unit**: 6px (default)
- **Philosophy**: Balanced readability and information density
- **Use Cases**: General applications, mixed content types
{{/if}}

{{#if DENSITY_SPACIOUS}}
- **Base Unit**: 8px
- **Philosophy**: Generous breathing room, content-first
- **Use Cases**: Marketing sites, content platforms, mobile apps
{{/if}}

---

## Brand Applications

### Logo Usage

**Logo File**: `design/assets/logo.svg`

**Minimum Size**: {{LOGO_MIN_SIZE}}px
**Clear Space**: {{LOGO_CLEAR_SPACE}}
**Background**: {{LOGO_BACKGROUND_REQUIREMENTS}}

**Don'ts**:
- [ ] Don't rotate the logo
- [ ] Don't change logo colors outside brand palette
- [ ] Don't add effects (shadows, outlines, gradients)
- [ ] Don't use low-resolution versions

### Imagery Style

**Style**: {{ILLUSTRATION_STYLE}}

{{#if ILLUSTRATION_ABSTRACT}}
- **Characteristics**: Geometric shapes, minimal detail, symbolic representation
- **Color Usage**: Brand colors only, 2-3 colors per illustration
- **Style Examples**: Abstract patterns, icon compositions, data visualizations
{{/if}}

{{#if ILLUSTRATION_PICTORIAL}}
- **Characteristics**: Recognizable objects, moderate detail, friendly style
- **Color Usage**: Full brand palette, realistic but stylized
- **Style Examples**: Spot illustrations, scene compositions, character designs
{{/if}}

{{#if ILLUSTRATION_PHOTOGRAPHY}}
- **Characteristics**: Real photography, authentic moments
- **Color Treatment**: Natural or brand-tinted overlays
- **Style Examples**: Product photography, user testimonials, team photos
{{/if}}

---

## Multi-Surface Consistency

### UI Applications

- **Web**: Full brand expression, rich interactions
- **Mobile**: Simplified UI, touch-optimized spacing
- **Desktop Apps**: Native platform conventions with brand overlay

### Non-UI Applications

**Email**:
- **Tone**: {{EMAIL_TONE}}
- **Header**: Logo + brand color accent
- **Body**: Simplified typography, web-safe fonts
- **CTA Buttons**: Brand primary color

**PDF Documents**:
- **Headers/Footers**: Brand colors, logo placement
- **Typography**: System fonts matching brand style
- **Data Tables**: Neutral colors, brand accent for highlights

**CLI/Terminal**:
- **Color Usage**: ANSI color codes matching brand palette
- **Success**: Green (or brand equivalent)
- **Errors**: Red (or brand equivalent)
- **Info**: Brand primary color

**Charts & Data Visualization**:
- **Color Palette**: Semantic colors + brand accent
- **Accessibility**: High contrast, colorblind-safe palettes
- **Consistency**: Same chart style across all dashboards

---

## Governance

### Decision Authority

**Brand Changes**: {{BRAND_CHANGE_AUTHORITY}}
**Token Updates**: {{TOKEN_UPDATE_AUTHORITY}}
**Exceptions**: {{EXCEPTION_AUTHORITY}}

### Change Management

**Approval Process**:
1. Propose change in `docs/design/proposals/`
2. Review against brand guidelines
3. Approve via {{APPROVAL_MECHANISM}}
4. Update tokens.css and documentation
5. Communicate to team

**Version Control**:
- All brand assets in `design/assets/`
- Version changes in CHANGELOG.md
- Tag releases: `brand-v1.1.0`

### Quality Assurance

**Review Checklist**:
- [ ] Matches brand personality spectrum
- [ ] Uses approved color palette
- [ ] Follows typography system
- [ ] Meets WCAG {{WCAG_LEVEL}} contrast requirements
- [ ] Consistent with existing components
- [ ] Documented in style guide if new pattern

---

## References

- **Design Tokens**: `design/systems/tokens.css`
- **Visual Language**: `docs/design/visual-language.md`
- **Accessibility Standards**: `docs/design/accessibility-standards.md`
- **Component Governance**: `docs/design/component-governance.md`

---

**Document Owner**: {{DOCUMENT_OWNER}}
**Last Review**: {{LAST_REVIEW_DATE}}
**Next Review**: {{NEXT_REVIEW_DATE}}
