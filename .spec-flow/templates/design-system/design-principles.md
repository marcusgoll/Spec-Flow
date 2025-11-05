# Design System Principles

**Version**: 2.0.0 (OKLCH Update)
**Last Updated**: 2025-11-05
**Project**: Design System Tokens

> This document defines the core design principles for building accessible, performant, and maintainable user interfaces using OKLCH color tokens.

---

## Overview

This design system follows modern web standards with OKLCH color space for perceptually uniform colors, semantic token naming for clarity, and comprehensive accessibility support.

**Key Features**:
- OKLCH color space (perceptually uniform)
- Semantic token structure (bg/fg/border/icon)
- WCAG 2.2 Focus Appearance compliance
- Motion tokens with reduced-motion support
- Colorblind-safe data visualization palette
- Dark mode shadow optimization

---

## Color System

### OKLCH Color Space

**What is OKLCH?**

OKLCH is a perceptually uniform color space that makes it easier to create accessible color scales and maintain consistent lightness across hues.

**Format**: `oklch(L% C H)`
- **L** = Lightness (0-100%)
- **C** = Chroma/saturation (0-0.4+, typically 0.0-0.25)
- **H** = Hue (0-360 degrees)

**Benefits**:
- **Perceptually uniform**: Equal lightness values appear equally bright across all hues
- **Predictable adjustments**: Changing L by 10% looks the same across all colors
- **Wide gamut**: Supports P3 color space (50% more colors than sRGB)
- **Future-proof**: Modern browsers support OKLCH natively

**Browser Support**:
-  Chrome 111+ (March 2023)
-  Safari 15.4+ (March 2022)
-  Firefox 113+ (May 2023)
-   92% global coverage (as of 2025)
- = Automatic fallback to sRGB for legacy browsers (8%)

**Example**:

```json
{
  "primary": {
    "oklch": "oklch(59.69% 0.156 261.45)",
    "fallback": "#3b82f6",
    "description": "Primary brand color"
  }
}
```

**CSS Usage**:

```css
:root {
  --color-primary: oklch(59.69% 0.156 261.45);
  --color-primary-fallback: #3b82f6;
}

/* Modern browsers use OKLCH */
.button-primary {
  background: var(--color-primary);
}

/* Legacy browser fallback */
@supports not (color: oklch(0% 0 0)) {
  :root {
    --color-primary: var(--color-primary-fallback);
  }
}
```

### Semantic Token Structure

**Ink vs Paint Philosophy**

Colors have different use cases: backgrounds (paint), text (ink), borders (outlines), and icons (glyphs). Each requires different contrast and visual weight.

**Token Naming Convention**:
- `.bg` = Background (paint, large areas)
- `.fg` = Foreground/Text (ink, readable text)
- `.border` = Border/Outline (edges, dividers)
- `.icon` = Icon/Glyph fill (visual indicators)

**Example**:

```json
{
  "semantic": {
    "success": {
      "bg": {
        "oklch": "oklch(95% 0.02 145)",
        "fallback": "#D1FAE5",
        "description": "Success background (light green)"
      },
      "fg": {
        "oklch": "oklch(25% 0.12 145)",
        "fallback": "#047857",
        "description": "Success text (dark green)",
        "wcag": "AAA on success.bg (10.2:1)"
      },
      "border": {
        "oklch": "oklch(85% 0.05 145)",
        "fallback": "#A7F3D0",
        "description": "Success border (medium green)"
      },
      "icon": {
        "oklch": "oklch(35% 0.13 145)",
        "fallback": "#059669",
        "description": "Success icon fill"
      }
    }
  }
}
```

**Usage**:

```jsx
<div className="bg-success-bg border border-success-border text-success-fg">
  <CheckIcon className="text-success-icon" />
  <span>Success message</span>
</div>
```

**Benefits**:
-  Clear semantic meaning (no ambiguous `DEFAULT`, `light`, `dark`)
-  Automated WCAG contrast validation
-  Consistent visual hierarchy
-  Easy to maintain and extend

### WCAG Contrast Requirements

**Minimum Ratios**:
- **AAA (body text)**: 7:1 or higher
- **AA (large text)**: 4.5:1 minimum
- **AA (UI components)**: 3:1 minimum

**Automated Validation**:

All semantic tokens are validated during generation using `colorjs.io`:

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

**Example Output**:

```
 success.fg on success.bg: 10.23:1 (AAA) 
 error.fg on error.bg: 9.87:1 (AAA) 
 warning.fg on warning.bg: 8.45:1 (AAA) 
 info.fg on info.bg: 10.12:1 (AAA) 
```

---

## Focus Tokens (WCAG 2.2)

### Focus Appearance 2.4.13

**Requirements** (WCAG 2.2 Level AA):
- **Minimum width**: 2px
- **Minimum contrast**: 3:1 against background
- **Minimum offset**: 2px from focused element
- **Visible on all interactive elements**: buttons, links, inputs

**Token Structure**:

```json
{
  "focus": {
    "ring": {
      "width": "2px",
      "color": {
        "oklch": "oklch(59.69% 0.156 261.45)",
        "fallback": "#3b82f6"
      },
      "offset": "2px",
      "wcag": "WCAG 2.2 Focus Appearance 2.4.13 (3:1 minimum)",
      "description": "Focus indicator for keyboard navigation"
    },
    "outline": {
      "width": "3px",
      "color": {
        "oklch": "oklch(59.69% 0.156 261.45)",
        "fallback": "#3b82f6"
      },
      "style": "solid",
      "description": "Alternative focus style for high contrast mode"
    }
  }
}
```

**CSS Implementation**:

```css
:focus-visible {
  outline: var(--focus-ring-width) solid var(--focus-ring-color);
  outline-offset: var(--focus-ring-offset);
}

/* High contrast mode */
@media (prefers-contrast: high) {
  :focus-visible {
    outline-width: var(--focus-outline-width);
  }
}
```

**Usage Guidelines**:
-  Always use `:focus-visible` (not `:focus`) to avoid mouse focus rings
-  Test with keyboard navigation (Tab, Shift+Tab, Enter, Space)
-  Ensure focus indicator is visible on all backgrounds
-  Maintain 3:1 contrast ratio against adjacent colors

---

## Motion Tokens

### Duration and Easing

**Token Structure**:

```json
{
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
      "mediaQuery": "@media (prefers-reduced-motion: reduce)",
      "description": "Accessibility: disable animations for users who prefer reduced motion"
    }
  }
}
```

### Reduced Motion (Accessibility)

**WCAG 2.1 Success Criterion 2.3.3**: Provide users with the ability to disable motion animations.

**CSS Implementation**:

```css
:root {
  --motion-duration-fast: 150ms;
  --motion-duration-base: 200ms;
  --motion-easing-standard: cubic-bezier(0.4, 0.0, 0.2, 1);
}

/* Disable animations for users who prefer reduced motion */
@media (prefers-reduced-motion: reduce) {
  :root {
    --motion-duration-fast: 0ms;
    --motion-duration-base: 0ms;
    --motion-easing-standard: linear;
  }

  *,
  *::before,
  *::after {
    animation-duration: 0ms !important;
    transition-duration: 0ms !important;
  }
}
```

**Usage**:

```jsx
// React component example
<motion.div
  initial={{ opacity: 0 }}
  animate={{ opacity: 1 }}
  transition={{
    duration: 0.2, // Respects reduced-motion via CSS var
    ease: [0.4, 0.0, 0.2, 1]
  }}
>
  Content
</motion.div>
```

**Guidelines**:
-  Always provide `prefers-reduced-motion` fallback
-  Set animation duration to `0ms` (not `1ms`)
-  Test with system setting: macOS (System Preferences ’ Accessibility ’ Display ’ Reduce motion)
- L Never override user preferences with `!important` on animations

---

## Data Visualization

### Okabe-Ito Colorblind-Safe Palette

**Why Okabe-Ito?**

8-color categorical palette designed by Masataka Okabe and Kei Ito (2008) that is distinguishable by all color vision types, including deuteranopia, protanopia, and tritanopia.

**Token Structure**:

```json
{
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

**Usage**:

```jsx
// Chart.js example
const chartColors = [
  'var(--dataviz-orange)',
  'var(--dataviz-sky-blue)',
  'var(--dataviz-bluish-green)',
  'var(--dataviz-yellow)',
  'var(--dataviz-blue)',
  'var(--dataviz-vermillion)',
  'var(--dataviz-reddish-purple)',
  'var(--dataviz-black)'
];
```

**Guidelines**:
-  Use for categorical data (categories, groups, labels)
-  Limit to 8 categories maximum
-  Add texture/patterns for additional distinction
- L Don't use for sequential data (use lightness scale instead)
- L Don't use for diverging data (use two-hue scale instead)

---

## Dark Mode

### Shadow Opacity Adjustment

**Problem**: RGBA shadows with the same opacity in light and dark mode appear muddy and flat in dark themes.

**Solution**: Increase shadow opacity by 3-6x in dark mode to maintain depth perception.

**Token Structure**:

```json
{
  "shadows": {
    "light": {
      "sm": {
        "value": "0 1px 2px oklch(0% 0 0 / 0.05)",
        "fallback": "0 1px 2px rgba(0, 0, 0, 0.05)"
      }
    },
    "dark": {
      "sm": {
        "value": "0 1px 2px oklch(0% 0 0 / 0.30)",
        "fallback": "0 1px 2px rgba(0, 0, 0, 0.30)",
        "rationale": "6x opacity increase (0.05 ’ 0.30) prevents muddy appearance"
      }
    }
  }
}
```

**Opacity Multipliers**:

| Light Mode | Dark Mode | Multiplier | Use Case |
|------------|-----------|------------|----------|
| 0.05       | 0.30      | 6x         | Small shadows (cards) |
| 0.07       | 0.35      | 5x         | Medium shadows (dropdowns) |
| 0.10       | 0.40      | 4x         | Large shadows (modals) |
| 0.12       | 0.48      | 4x         | XL shadows (overlays) |
| 0.15       | 0.60      | 4x         | 2XL shadows (top-level) |

**CSS Implementation**:

```css
:root {
  /* Light mode shadows */
  --shadow-sm: 0 1px 2px oklch(0% 0 0 / 0.05);
  --shadow-md: 0 4px 6px oklch(0% 0 0 / 0.07), 0 2px 4px oklch(0% 0 0 / 0.06);
}

/* Dark mode shadows (3-6x opacity increase) */
@media (prefers-color-scheme: dark) {
  :root {
    --shadow-sm: 0 1px 2px oklch(0% 0 0 / 0.30);
    --shadow-md: 0 4px 6px oklch(0% 0 0 / 0.35), 0 2px 4px oklch(0% 0 0 / 0.30);
  }
}
```

**Guidelines**:
-  Always use separate light/dark shadow tokens
-  Test shadows on dark backgrounds (not just inverted UI)
-  Increase opacity for larger shadows (more depth = more shadow)
- L Don't use the same opacity values for light and dark mode

---

## Typography Features

### OpenType Font Variants

**Token Structure**:

```json
{
  "typography": {
    "features": {
      "tabular": {
        "property": "font-variant-numeric",
        "value": "tabular-nums",
        "cssClass": "font-feature-tabular",
        "description": "Monospaced numbers for tables/dashboards",
        "useCase": "Financial data, metrics, comparison tables"
      },
      "slashedZero": {
        "property": "font-variant-numeric",
        "value": "slashed-zero",
        "cssClass": "font-feature-slashed-zero",
        "description": "Slashed zero for O/0 clarity",
        "useCase": "API keys, serial numbers, technical documentation"
      },
      "oldstyle": {
        "property": "font-variant-numeric",
        "value": "oldstyle-nums",
        "cssClass": "font-feature-oldstyle",
        "description": "Lowercase numbers for body text",
        "useCase": "Editorial content, long-form text"
      },
      "lining": {
        "property": "font-variant-numeric",
        "value": "lining-nums",
        "cssClass": "font-feature-lining",
        "description": "All-caps numbers for headings",
        "useCase": "Headlines, UI labels, buttons"
      }
    }
  }
}
```

**CSS Implementation**:

```css
/* Tabular numbers (monospaced) */
.font-feature-tabular {
  font-variant-numeric: tabular-nums;
  /* or */
  font-feature-settings: "tnum" on;
}

/* Slashed zero */
.font-feature-slashed-zero {
  font-variant-numeric: slashed-zero;
  /* or */
  font-feature-settings: "zero" on;
}
```

**Usage**:

```jsx
// Financial dashboard
<div className="font-feature-tabular text-2xl font-semibold">
  $1,234,567.89
</div>

// API key display
<code className="font-feature-slashed-zero">
  API-KEY-0123456789
</code>
```

---

## Best Practices

### Color Usage

 **DO**:
- Use semantic tokens (success.fg, error.bg) not arbitrary colors
- Validate WCAG contrast ratios during design
- Provide OKLCH with sRGB fallback for all colors
- Test colors in light and dark modes

L **DON'T**:
- Use RGB hex values directly in components
- Rely on visual perception for contrast (use tools)
- Skip browser fallbacks (8% of users)
- Use the same colors for light and dark mode

### Accessibility

 **DO**:
- Test with keyboard navigation (Tab, Enter, Space)
- Provide `:focus-visible` styles (2px ring, 3:1 contrast)
- Support `prefers-reduced-motion` media query
- Use colorblind-safe palettes for data viz

L **DON'T**:
- Rely on color alone to convey meaning
- Use mouse-only interactions
- Override user's reduced motion preference
- Use <3:1 contrast for focus indicators

### Dark Mode

 **DO**:
- Increase shadow opacity by 3-6x
- Test on actual dark backgrounds (not just inverted)
- Provide separate light/dark token values
- Use `@media (prefers-color-scheme: dark)`

L **DON'T**:
- Invert colors programmatically
- Use the same shadow opacity for light and dark
- Assume users want dark mode at night (respect system preference)

---

## Resources

**OKLCH Color Space**:
- [OKLCH in CSS](https://developer.chrome.com/blog/css-color-4/)
- [colorjs.io Library](https://colorjs.io/)
- [OKLCH Color Picker](https://oklch.com/)

**WCAG Guidelines**:
- [WCAG 2.2 Focus Appearance 2.4.13](https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html)
- [WCAG 2.1 Motion Animations 2.3.3](https://www.w3.org/WAI/WCAG21/Understanding/animation-from-interactions.html)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

**Colorblind-Safe Palettes**:
- [Okabe-Ito Palette](https://jfly.uni-koeln.de/color/)
- [Colorblind Simulator](https://www.color-blindness.com/coblis-color-blindness-simulator/)

**Tools**:
- [colorjs.io](https://colorjs.io/) - OKLCH conversion and WCAG contrast
- [Tailwind CSS v3.3+](https://tailwindcss.com/docs/customizing-colors#using-css-variables) - OKLCH support
- [Figma OKLCH Plugin](https://www.figma.com/community/plugin/1231839690509869048/OKLCH-Color-Picker)

---

**Version History**:
- v2.0.0 (2025-11-05): OKLCH upgrade, semantic tokens, WCAG 2.2 focus, motion tokens, data viz
- v1.0.0 (2024-10-06): Initial RGB-based design system
