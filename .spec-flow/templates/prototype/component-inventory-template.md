# Component Inventory from Prototype

> Extracted on [DATE] from [SCREEN_COUNT] prototype screens
> This informs component build order during implementation

## Inventory Summary

| Metric | Value |
|--------|-------|
| Total Components | [TOTAL_COUNT] |
| Must Build (3+ occurrences) | [MUST_COUNT] |
| Should Build (2 occurrences) | [SHOULD_COUNT] |
| Consider (1 occurrence) | [CONSIDER_COUNT] |

## Component Priority Matrix

| Component | Occurrences | Screens | Variants | States | Priority |
|-----------|-------------|---------|----------|--------|----------|
| Button | [N] | [screens] | [N] | [N] | Must build |
| Card | [N] | [screens] | [N] | [N] | Must build |
| Input | [N] | [screens] | [N] | [N] | Must build |
| Avatar | [N] | [screens] | [N] | [N] | Should build |
| Badge | [N] | [screens] | [N] | [N] | Should build |
| Modal | [N] | [screens] | [N] | [N] | Consider |

## Recommended Build Order

Based on dependencies and occurrence frequency:

### Layer 1: Foundation (build first)
1. **Button** - Used everywhere, no dependencies
2. **Input** - Forms depend on this
3. **Badge** - Status indicators, no dependencies

### Layer 2: Layout
4. **Card** - Layout building block
5. **Container** - Page structure

### Layer 3: Composite
6. **Form** - Combines Input, Button
7. **Modal** - Overlay component
8. **Avatar** - User display

### Layer 4: Feature-Specific
9. **[Component]** - [Feature-specific component]

---

## Detailed Component Specifications

<!-- Repeat for each component -->

### Button

**Source Screens**: login.html, signup.html, dashboard.html, settings.html
**Occurrences**: [N]
**Priority**: Must build

**Detected Variants**:
- `primary` - Main action buttons
- `secondary` - Secondary actions
- `outline` - Tertiary actions
- `ghost` - Minimal buttons
- `danger` - Destructive actions

**Detected Sizes**:
- `sm` - Compact buttons
- `md` - Default size
- `lg` - Prominent buttons

**Detected States**:
- Default
- Hover
- Focus
- Disabled
- Loading

**Recommended tv() Definition**:
```typescript
import { tv, type VariantProps } from 'tailwind-variants';

export const button = tv({
  base: 'inline-flex items-center justify-center gap-2 rounded-md font-medium transition-all duration-100 focus:outline-none focus:ring-2 focus:ring-offset-2',
  variants: {
    variant: {
      primary: 'bg-primary text-white hover:bg-primary-hover focus:ring-primary/30',
      secondary: 'bg-secondary text-white hover:bg-secondary-hover focus:ring-secondary/30',
      outline: 'border border-primary text-primary bg-transparent hover:bg-primary/10',
      ghost: 'text-primary bg-transparent hover:bg-primary/10',
      danger: 'bg-error text-white hover:bg-error-hover focus:ring-error/30'
    },
    size: {
      sm: 'px-3 py-1.5 text-sm',
      md: 'px-4 py-2 text-base',
      lg: 'px-6 py-3 text-lg'
    },
    disabled: {
      true: 'opacity-50 cursor-not-allowed pointer-events-none'
    },
    loading: {
      true: 'pointer-events-none'
    }
  },
  defaultVariants: {
    variant: 'primary',
    size: 'md'
  }
});

export type ButtonVariants = VariantProps<typeof button>;
```

---

### Card

**Source Screens**: dashboard.html, list.html
**Occurrences**: [N]
**Priority**: Must build

**Detected Variants**:
- `default` - Standard card with border
- `elevated` - Card with shadow
- `interactive` - Hoverable card

**Detected Slots**:
- `base` - Card container
- `header` - Card header area
- `body` - Card content area
- `footer` - Card footer/actions

**Recommended tv() Definition**:
```typescript
import { tv, type VariantProps } from 'tailwind-variants';

export const card = tv({
  slots: {
    base: 'rounded-lg bg-surface overflow-hidden',
    header: 'px-4 py-3 border-b border-neutral-200',
    body: 'px-4 py-4',
    footer: 'px-4 py-3 border-t border-neutral-200 bg-neutral-50',
    title: 'text-lg font-semibold text-neutral-900',
    description: 'text-sm text-neutral-500'
  },
  variants: {
    variant: {
      default: { base: 'border border-neutral-200' },
      elevated: { base: 'shadow-md' },
      interactive: { base: 'border border-neutral-200 hover:border-primary hover:shadow-md cursor-pointer transition-all' }
    },
    padding: {
      sm: { body: 'px-3 py-2' },
      md: { body: 'px-4 py-4' },
      lg: { body: 'px-6 py-6' }
    }
  },
  defaultVariants: {
    variant: 'default',
    padding: 'md'
  }
});

export type CardVariants = VariantProps<typeof card>;
```

---

### Input

**Source Screens**: login.html, signup.html, create.html
**Occurrences**: [N]
**Priority**: Must build

**Detected Variants**:
- `default` - Standard input
- `error` - Error state
- `success` - Valid state

**Detected Sizes**:
- `sm`, `md`, `lg`

**Recommended tv() Definition**:
```typescript
import { tv, type VariantProps } from 'tailwind-variants';

export const input = tv({
  base: 'w-full rounded-md border bg-surface px-3 py-2 text-base transition-colors focus:outline-none focus:ring-2',
  variants: {
    variant: {
      default: 'border-neutral-300 focus:border-primary focus:ring-primary/30',
      error: 'border-error focus:border-error focus:ring-error/30 text-error',
      success: 'border-success focus:border-success focus:ring-success/30'
    },
    size: {
      sm: 'px-2 py-1 text-sm',
      md: 'px-3 py-2 text-base',
      lg: 'px-4 py-3 text-lg'
    },
    disabled: {
      true: 'bg-neutral-100 cursor-not-allowed opacity-60'
    }
  },
  defaultVariants: {
    variant: 'default',
    size: 'md'
  }
});

export type InputVariants = VariantProps<typeof input>;
```

---

## Brownfield Analysis

> If existing components detected, this section shows integration strategy

### Existing Components Detected

| Component | Existing File | Integration Mode |
|-----------|---------------|------------------|
| [Component] | [path] | [Use/Extend/Wrap/Create] |

### Gap Summary

- **Use as-is**: [N] components (exact match)
- **Extend**: [N] components (add variants)
- **Wrap**: [N] components (different API)
- **Create new**: [N] components (no match)

---

## Next Steps

1. Review component priorities and adjust if needed
2. During `/implement`, components will be built in recommended order
3. Use tv() definitions as starting point for implementation
4. Reference this inventory during code review for consistency
