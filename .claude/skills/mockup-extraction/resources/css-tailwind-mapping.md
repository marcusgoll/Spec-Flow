# CSS to Tailwind Mapping Reference

## Color Variables

### Brand Colors
| CSS Variable | Tailwind Utility |
|--------------|------------------|
| `var(--color-primary)` | `bg-primary`, `text-primary`, `border-primary` |
| `var(--color-primary-hover)` | `hover:bg-primary-hover` |
| `var(--color-secondary)` | `bg-secondary`, `text-secondary` |

### Semantic Colors
| CSS Variable | Tailwind Utility |
|--------------|------------------|
| `var(--color-success)` | `bg-success`, `text-success` |
| `var(--color-warning)` | `bg-warning`, `text-warning` |
| `var(--color-error)` | `bg-error`, `text-error` |
| `var(--color-info)` | `bg-info`, `text-info` |

### Neutral Scale
| CSS Variable | Tailwind Utility |
|--------------|------------------|
| `var(--color-neutral-50)` | `bg-neutral-50` |
| `var(--color-neutral-100)` | `bg-neutral-100` |
| `var(--color-neutral-200)` | `bg-neutral-200`, `border-neutral-200` |
| `var(--color-neutral-300)` | `bg-neutral-300` |
| `var(--color-neutral-400)` | `text-neutral-400` (placeholder) |
| `var(--color-neutral-500)` | `text-neutral-500` (secondary text) |
| `var(--color-neutral-600)` | `text-neutral-600` (body text) |
| `var(--color-neutral-700)` | `text-neutral-700` (headings) |
| `var(--color-neutral-800)` | `text-neutral-800` (primary text) |
| `var(--color-neutral-900)` | `text-neutral-900` (dark text) |

### Surface Colors
| CSS Variable | Tailwind Utility |
|--------------|------------------|
| `var(--color-surface)` | `bg-surface`, `bg-white` |
| `var(--color-background)` | `bg-background` |

## Spacing (8pt Grid)

| CSS Variable | Tailwind | Pixels |
|--------------|----------|--------|
| `var(--space-1)` | `p-1`, `m-1`, `gap-1` | 8px |
| `var(--space-2)` | `p-2`, `m-2`, `gap-2` | 16px |
| `var(--space-3)` | `p-3`, `m-3`, `gap-3` | 24px |
| `var(--space-4)` | `p-4`, `m-4`, `gap-4` | 32px |
| `var(--space-5)` | `p-5`, `m-5`, `gap-5` | 40px |
| `var(--space-6)` | `p-6`, `m-6`, `gap-6` | 48px |
| `var(--space-8)` | `p-8`, `m-8`, `gap-8` | 64px |
| `var(--space-10)` | `p-10`, `m-10`, `gap-10` | 80px |
| `var(--space-12)` | `p-12`, `m-12`, `gap-12` | 96px |

### Directional Spacing
| CSS Property | Tailwind |
|--------------|----------|
| `padding-top: var(--space-4)` | `pt-4` |
| `padding-bottom: var(--space-4)` | `pb-4` |
| `padding-left: var(--space-4)` | `pl-4` |
| `padding-right: var(--space-4)` | `pr-4` |
| `padding-inline: var(--space-4)` | `px-4` |
| `padding-block: var(--space-4)` | `py-4` |

## Typography

### Font Sizes
| CSS Variable | Tailwind |
|--------------|----------|
| `var(--text-xs)` | `text-xs` |
| `var(--text-sm)` | `text-sm` |
| `var(--text-base)` | `text-base` |
| `var(--text-lg)` | `text-lg` |
| `var(--text-xl)` | `text-xl` |
| `var(--text-2xl)` | `text-2xl` |
| `var(--text-3xl)` | `text-3xl` |
| `var(--text-4xl)` | `text-4xl` |

### Font Weights
| CSS Variable | Tailwind |
|--------------|----------|
| `var(--font-normal)` | `font-normal` |
| `var(--font-medium)` | `font-medium` |
| `var(--font-semibold)` | `font-semibold` |
| `var(--font-bold)` | `font-bold` |

### Line Heights
| CSS Variable | Tailwind |
|--------------|----------|
| `var(--leading-tight)` | `leading-tight` |
| `var(--leading-base)` | `leading-normal` |
| `var(--leading-relaxed)` | `leading-relaxed` |

### Font Families
| CSS Variable | Tailwind |
|--------------|----------|
| `var(--font-heading)` | `font-sans` (configure in tailwind.config) |
| `var(--font-body)` | `font-sans` |
| `var(--font-mono)` | `font-mono` |

## Border Radius

| CSS Variable | Tailwind |
|--------------|----------|
| `var(--radius-none)` | `rounded-none` |
| `var(--radius-sm)` | `rounded-sm` |
| `var(--radius-md)` | `rounded-md` |
| `var(--radius-lg)` | `rounded-lg` |
| `var(--radius-xl)` | `rounded-xl` |
| `var(--radius-full)` | `rounded-full` |

## Shadows

| CSS Variable | Tailwind |
|--------------|----------|
| `var(--shadow-sm)` | `shadow-sm` |
| `var(--shadow-md)` | `shadow-md` or `shadow` |
| `var(--shadow-lg)` | `shadow-lg` |
| `var(--shadow-xl)` | `shadow-xl` |

## Transitions

| CSS Variable | Tailwind |
|--------------|----------|
| `var(--transition-fast)` | `duration-100` |
| `var(--transition-base)` | `duration-150` |
| `var(--transition-slow)` | `duration-300` |

Common transition patterns:
```
transition: all var(--transition-base) → transition-all duration-150
transition: colors var(--transition-fast) → transition-colors duration-100
```

## Layout

### Display
| CSS Property | Tailwind |
|--------------|----------|
| `display: flex` | `flex` |
| `display: inline-flex` | `inline-flex` |
| `display: grid` | `grid` |
| `display: none` | `hidden` |
| `display: block` | `block` |

### Flexbox
| CSS Property | Tailwind |
|--------------|----------|
| `flex-direction: column` | `flex-col` |
| `flex-direction: row` | `flex-row` |
| `justify-content: center` | `justify-center` |
| `justify-content: space-between` | `justify-between` |
| `align-items: center` | `items-center` |
| `align-items: start` | `items-start` |
| `flex-wrap: wrap` | `flex-wrap` |
| `flex: 1` | `flex-1` |
| `flex-shrink: 0` | `shrink-0` |

### Grid
| CSS Property | Tailwind |
|--------------|----------|
| `grid-template-columns: repeat(2, 1fr)` | `grid-cols-2` |
| `grid-template-columns: repeat(3, 1fr)` | `grid-cols-3` |
| `grid-template-columns: repeat(4, 1fr)` | `grid-cols-4` |
| `gap: var(--space-4)` | `gap-4` |

### Width/Height
| CSS Property | Tailwind |
|--------------|----------|
| `width: 100%` | `w-full` |
| `max-width: var(--container-max)` | `max-w-screen-xl` |
| `height: 100%` | `h-full` |
| `min-height: 100vh` | `min-h-screen` |

## Interactive States

### Hover
```css
/* CSS */
.btn:hover { background: var(--color-primary-hover); }

/* Tailwind */
hover:bg-primary-hover
```

### Focus
```css
/* CSS */
.btn:focus { box-shadow: var(--focus-ring); }

/* Tailwind */
focus:ring-2 focus:ring-primary/30 focus:outline-none
```

### Disabled
```css
/* CSS */
.btn:disabled { opacity: 0.5; cursor: not-allowed; }

/* Tailwind */
disabled:opacity-50 disabled:cursor-not-allowed
```

### Active
```css
/* CSS */
.btn:active { transform: scale(0.98); }

/* Tailwind */
active:scale-[0.98]
```

## Z-Index Scale

| CSS Variable | Tailwind |
|--------------|----------|
| `var(--z-base)` | `z-0` |
| `var(--z-dropdown)` | `z-10` |
| `var(--z-sticky)` | `z-20` |
| `var(--z-fixed)` | `z-30` |
| `var(--z-modal-backdrop)` | `z-40` |
| `var(--z-modal)` | `z-50` |

## Common Component Patterns

### Button
```css
/* CSS */
.btn {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-2) var(--space-4);
  background: var(--color-primary);
  color: var(--color-surface);
  border-radius: var(--radius-md);
  transition: all var(--transition-fast);
}

/* Tailwind */
inline-flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-md transition-all duration-100
```

### Card
```css
/* CSS */
.card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
  padding: var(--space-4);
}

/* Tailwind */
bg-white rounded-lg shadow-md p-4
```

### Form Input
```css
/* CSS */
.form-input {
  width: 100%;
  padding: var(--space-2) var(--space-3);
  border: 1px solid var(--color-neutral-300);
  border-radius: var(--radius-md);
}

/* Tailwind */
w-full px-3 py-2 border border-neutral-300 rounded-md focus:ring-2 focus:ring-primary/30 focus:border-primary
```
