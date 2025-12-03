# Mockup Extraction Rules

## Component Detection Patterns

### HTML Element Patterns

| Component Type | HTML Selectors | Attributes |
|---------------|----------------|------------|
| Button | `button`, `a.btn`, `[role="button"]` | `type`, `disabled` |
| Card | `.card`, `article`, `[role="article"]` | - |
| Form Field | `.form-group`, `.field`, `label + input` | `required`, `disabled` |
| Alert | `.alert`, `[role="alert"]` | `aria-live` |
| Modal | `.modal`, `[role="dialog"]` | `aria-modal` |
| Navigation | `nav`, `.nav`, `.navbar` | `aria-label` |
| List | `ul.list`, `ol`, `[role="list"]` | - |
| Table | `table`, `.table` | - |
| Badge | `.badge`, `.tag`, `.chip` | - |
| Avatar | `.avatar`, `img.avatar` | - |

### CSS Class Patterns

```regex
# Button variants
\.btn-(primary|secondary|outline|ghost|danger|link)

# Size modifiers
\.(sm|md|lg|xl)$
\.(small|medium|large)$

# State modifiers
\.(active|disabled|loading|error|success)

# Layout patterns
\.(flex|grid|container|row|col)

# Spacing patterns
\.(p|m|gap)-\d+
```

## Extraction Priority Matrix

| Criteria | Weight | Threshold |
|----------|--------|-----------|
| Occurrence count | 40% | 3+ = must extract |
| Variant count | 25% | 2+ variants = higher priority |
| State complexity | 20% | 3+ states = higher priority |
| Interactive | 15% | Interactive = higher priority |

## Variant Detection

### Identifying Variants

Look for CSS class modifiers that change:
1. **Color**: `primary`, `secondary`, `success`, `error`
2. **Size**: `sm`, `md`, `lg`, `xl`
3. **Style**: `outline`, `ghost`, `filled`, `flat`
4. **State**: `active`, `disabled`, `loading`

### Consolidating Variants

When same component has multiple variants:

```html
<!-- All these are Button variants -->
<button class="btn btn-primary">Primary</button>
<button class="btn btn-secondary">Secondary</button>
<button class="btn btn-outline">Outline</button>
<button class="btn btn-sm">Small</button>
<button class="btn btn-lg">Large</button>
```

Extract as single component with `variant` and `size` props.

## State Detection

### Interactive States

```css
/* Detect these pseudo-class patterns */
:hover     → hover:* Tailwind classes
:focus     → focus:* Tailwind classes
:active    → active:* Tailwind classes
:disabled  → disabled:* Tailwind classes
```

### Visual States

```html
<!-- Loading state indicator -->
<button class="btn btn-loading">
  <span class="spinner"></span>
</button>

<!-- Error state -->
<input class="form-input form-input--error">

<!-- Empty state -->
<div class="empty-state">No items found</div>
```

## Output Requirements

Each extracted component must include:

1. **Source tracking**: List of files where component appears
2. **HTML structure**: Semantic markup pattern
3. **CSS classes**: All classes used with explanations
4. **Tailwind mapping**: Equivalent utility classes
5. **State matrix**: All states and their styling
6. **Props interface**: TypeScript interface for component
7. **tv() definition**: tailwind-variants code (if tv installed)

## tailwind-variants (tv) Mapping Rules

### Variant Categories to tv() Keys

| Mockup Pattern | tv() Key | Example |
|---------------|----------|---------|
| `.btn-primary`, `.btn-secondary` | `variants.variant` | `variant: { primary: '...', secondary: '...' }` |
| `.btn-sm`, `.btn-lg` | `variants.size` | `size: { sm: '...', lg: '...' }` |
| `.btn-outline`, `.btn-ghost` | `variants.variant` | Merge with color variants |
| `disabled` attribute | `variants.disabled` | `disabled: { true: '...' }` |
| `.loading` class | `variants.loading` | `loading: { true: '...' }` |

### Multi-Part Components to Slots

When component has distinct child elements:

| Mockup Structure | tv() Slot |
|-----------------|-----------|
| `.card` (container) | `slots.base` |
| `.card-header` | `slots.header` |
| `.card-body` | `slots.body` |
| `.card-footer` | `slots.footer` |
| `.card-title` | `slots.title` |

### State to Compound Variants

Complex state combinations use compoundVariants:

```typescript
compoundVariants: [
  // When both loading AND primary
  { loading: true, variant: 'primary', class: 'bg-primary/80' },
  // When disabled with any variant
  { disabled: true, class: 'opacity-50 cursor-not-allowed' }
]
```

### Responsive Variants (Manual in Tailwind v4)

Since Tailwind v4 removed responsive variant auto-generation:

```typescript
// DON'T: responsive: true (removed in TV v3 for TW v4)
// DO: Apply responsive classes in base/variants manually

const container = tv({
  base: 'p-4 md:p-6 lg:p-8',  // Responsive in base
  variants: {
    layout: {
      stack: 'flex flex-col md:flex-row',  // Responsive in variant
      grid: 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3'
    }
  }
});
```

### Default Variants

Map mockup "default" or most common variant:

```typescript
defaultVariants: {
  variant: 'primary',  // Most common button variant in mockups
  size: 'md'          // Most common size in mockups
}
```

## Brownfield Detection Rules

### Component Library Detection

| Check | Library | Integration Strategy |
|-------|---------|---------------------|
| `@radix-ui/*` in deps | Radix | Primitives - style only |
| `components/ui/` dir + shadcn patterns | shadcn/ui | Extend existing |
| `@chakra-ui/react` in deps | Chakra | Use chakra props |
| `@mui/material` in deps | MUI | Use sx prop / styled |
| `tailwind-variants` in deps | TV Ready | Generate tv() directly |

### Existing Component Matching

1. **Exact match**: Same name, same variants → Skip extraction
2. **Partial match**: Same name, fewer variants → Extend
3. **API mismatch**: Same function, different props → Wrap
4. **No match**: New component → Create

### Token Source Detection

| File Pattern | Token Format | Action |
|--------------|--------------|--------|
| `tailwind.config.js` | Tailwind theme | Direct use |
| `tokens.json` | Style Dictionary | Convert to CSS vars |
| `theme.ts` | JS Object | Convert to CSS vars |
| `variables.css` | CSS Custom Props | Parse and map |

## Quality Gates

Before marking extraction complete:

- [ ] All components with 3+ occurrences extracted
- [ ] All variants documented with visual differences
- [ ] All interactive states mapped to Tailwind
- [ ] No hardcoded colors, spacing, or sizes remain
- [ ] Props interfaces are type-safe
- [ ] tv() definitions generated (if tailwind-variants installed)
- [ ] Gap analysis complete (brownfield projects)
- [ ] Integration mode assigned per component (Create/Extend/Wrap/Map/Use)
