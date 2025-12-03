# Gap Analysis: Mockup Components vs Existing Codebase

> Generated during mockup extraction for brownfield projects.
> This section is appended to prototype-patterns.md when existing components are detected.

## Brownfield Context

| Attribute | Detected Value |
|-----------|----------------|
| Component Library | [COMPONENT_LIB] |
| Design Tokens Source | [TOKEN_SOURCE] |
| Variant API | [VARIANT_API] |
| UI Directory | [UI_DIR] |

## Component Comparison Matrix

| Mockup Component | Existing Match | Integration Mode | Priority | Gap Details |
|-----------------|----------------|------------------|----------|-------------|
| [COMPONENT_1] | [MATCH_1] | [MODE_1] | [P0-P3] | [GAP_1] |
| [COMPONENT_2] | [MATCH_2] | [MODE_2] | [P0-P3] | [GAP_2] |

## Integration Modes Reference

### Use (P4 - No action required)
Exact match exists. Use existing component as-is.

```typescript
// No code changes needed
import { Button } from '@/components/ui/button';
```

### Map (P3 - Alias only)
Same function, different name in mockup. Create re-export.

```typescript
// Create alias in components/ui/index.ts
export { dialog as modal } from './dialog';
export type { DialogProps as ModalProps } from './dialog';
```

### Extend (P1 - Add variants)
Component exists but missing variants from mockup.

```typescript
import { tv } from 'tailwind-variants';
import { existingButton } from '@/components/ui/button';

export const button = tv({
  extend: existingButton,
  variants: {
    variant: {
      // New variants from mockup
      ghost: 'text-primary bg-transparent hover:bg-primary/10',
      danger: 'bg-error text-white hover:bg-error-hover'
    }
  }
});
```

### Wrap (P2 - Compatibility layer)
Different API between mockup and existing. Create wrapper.

```typescript
import { tv } from 'tailwind-variants';

// Mockup uses "Alert" with variant prop
// Existing uses "Toast" with type prop
export const alert = tv({
  base: 'p-4 rounded-lg border',
  variants: {
    variant: {
      info: 'bg-info/10 border-info text-info',
      success: 'bg-success/10 border-success text-success',
      warning: 'bg-warning/10 border-warning text-warning',
      error: 'bg-error/10 border-error text-error'
    }
  }
});

// React wrapper component
export function Alert({ variant, children }) {
  return <div className={alert({ variant })}>{children}</div>;
}
```

### Create (P0 - New component)
No existing match. Generate full tv() component.

```typescript
import { tv, type VariantProps } from 'tailwind-variants';

export const avatar = tv({
  base: 'relative inline-flex shrink-0 overflow-hidden rounded-full',
  variants: {
    size: {
      sm: 'h-8 w-8 text-xs',
      md: 'h-10 w-10 text-sm',
      lg: 'h-12 w-12 text-base',
      xl: 'h-16 w-16 text-lg'
    }
  },
  defaultVariants: { size: 'md' }
});

export type AvatarVariants = VariantProps<typeof avatar>;
```

## Detailed Gap Analysis

### Components to Create (P0)

<!-- List components with no existing match -->

#### [NEW_COMPONENT_NAME]
- **Source Screens**: [screen1.html, screen2.html]
- **Occurrences**: [N]
- **Variants Needed**: [list]
- **States Needed**: [list]

**tv() Definition**:
```typescript
export const [component] = tv({
  base: '[base classes]',
  variants: {
    variant: { /* ... */ },
    size: { /* ... */ }
  }
});
```

### Components to Extend (P1)

<!-- List components that need additional variants -->

#### [EXISTING_COMPONENT_NAME]
- **Existing File**: `[path/to/component.tsx]`
- **Current Variants**: [existing variants]
- **Missing Variants**: [variants from mockup not in existing]
- **Missing States**: [states from mockup not in existing]

**Extension Code**:
```typescript
// Add to existing component
variants: {
  variant: {
    // Keep existing...
    [newVariant]: '[new classes]'
  }
}
```

### Components to Wrap (P2)

<!-- List components with different APIs -->

#### [COMPONENT_NAME]
- **Mockup API**: `<[MockupName] variant="[type]" />`
- **Existing API**: `<[ExistingName] type="[type]" />`
- **Wrapper Strategy**: [describe mapping]

### Components to Map (P3)

<!-- List components that just need aliases -->

| Mockup Name | Existing Name | File Path |
|-------------|---------------|-----------|
| Modal | Dialog | components/ui/dialog.tsx |

### Skip List (P4 - Use as-is)

Components with exact matches - no extraction needed:

```yaml
skip_extraction:
  - component_name  # Exact match in [path]
```

## Token Alignment

### Colors

| Mockup Token | Existing Token | Status |
|--------------|----------------|--------|
| `--color-primary` | `--primary` | Rename needed |
| `--color-error` | `--destructive` | Rename needed |
| `--color-neutral-500` | `--muted-foreground` | Map |

### Spacing

| Mockup Token | Existing Token | Status |
|--------------|----------------|--------|
| `--space-4` | Tailwind `p-4` | Direct map |

## Migration Checklist

- [ ] Create new components (P0)
- [ ] Extend existing components with new variants (P1)
- [ ] Build wrapper components for API mismatches (P2)
- [ ] Add alias exports for renamed components (P3)
- [ ] Update imports in feature code
- [ ] Align design tokens if needed
- [ ] Run visual regression tests
