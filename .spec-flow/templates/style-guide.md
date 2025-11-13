# Style Guide

**Project**: [PROJECT_NAME]  
**Last Updated**: [DATE]  
**Version**: 1.0.0

This guide is the single source of truth for visual and interaction rules. If a design, component, or line of CSS conflicts with this guide, this guide wins.

---

## 0) How to use this guide
- **Design**: prototype with system tokens only (no hardcoded colors/sizes).  
- **Code**: import `design/systems/tokens.css` and use Tailwind classes mapped to tokens.  
- **QA**: run `design-lint.js` and axe-core; block merges on failing gates (see §8).

---

## 1) Foundations

### Core principles
1) **Content first**: layout guides the eye; decoration never competes with copy.  
2) **Predictable rhythm**: spacing is on the 8-pt grid; hierarchy is obvious at a squint.  
3) **Semantic color**: brand for actions, neutral for structure, semantic for feedback.  
4) **Accessibility by default**: contrast, focus, and target sizes are not optional.

### Readability rules
- **Line length**: 50–75 characters or max-width 600–700px for long text containers.  
- **Letter spacing**: displays slightly tighter, CTAs slightly wider (details in §3).  
- **Hierarchy at a squint**: main heading and primary CTA must dominate when blurred.

---

## 2) Color System (OKLCH-first)

Use OKLCH for tokens with sRGB fallbacks. Never hardcode hex/rgb in components.

```css
/* tokens.css (excerpt) */
:root {
  /* Brand */
  --brand-primary: oklch(0.55 0.22 250);
  --brand-primary-fg: oklch(0.98 0 0);
  --brand-primary-hover: oklch(0.50 0.22 250);

  /* Semantic */
  --semantic-success: oklch(0.50 0.15 140);
  --semantic-success-bg: oklch(0.95 0.05 140);
  --semantic-success-fg: oklch(0.35 0.15 140);

  --semantic-error: oklch(0.55 0.22 25);
  --semantic-error-bg: oklch(0.95 0.05 25);
  --semantic-error-fg: oklch(0.40 0.22 25);

  /* Neutral 50→950 */
  --neutral-50: oklch(0.98 0 0);
  --neutral-100: oklch(0.96 0 0);
  --neutral-200: oklch(0.92 0 0);
  --neutral-400: oklch(0.74 0 0);
  --neutral-600: oklch(0.48 0 0);
  --neutral-800: oklch(0.26 0 0);
  --neutral-950: oklch(0.10 0 0);
}

/* Legacy fallback (~8% of browsers) */
@supports not (color: oklch(0% 0 0)) {
  :root {
    --brand-primary: #3b82f6;
    --brand-primary-fg: #ffffff;
    /* ...map the rest */
  }
}
````

**Usage rules**

* **CTAs & links** → brand primary.
* **Headings & structure** → neutral scale.
* **Feedback** → semantic tokens only (never ad-hoc greens/reds).

---

## 3) Typography

**Families**

* Sans: `Inter, system-ui, -apple-system, 'Segoe UI', sans-serif`
* Mono: `JetBrains Mono, Consolas, monospace` (code, numeric tables)

**Scale**

| Level   | Size | LH  | Weight | Use             | Tailwind                    |
| ------- | ---- | --- | ------ | --------------- | --------------------------- |
| Hero    | 60px | 1.0 | 700    | Landing hero    | `text-6xl leading-none`     |
| Display | 48px | 1.0 | 700    | Page titles     | `text-5xl leading-tight`    |
| Heading | 36px | 1.1 | 600    | Section headers | `text-4xl leading-snug`     |
| Title   | 24px | 1.3 | 600    | Card titles     | `text-2xl leading-normal`   |
| Body    | 16px | 1.5 | 400    | Paragraphs      | `text-base leading-relaxed` |
| Caption | 14px | 1.4 | 400    | Secondary text  | `text-sm leading-normal`    |

**Tracking**

* Display: `-tracking-px` (≈ −0.025em)
* Body: default
* CTA: `tracking-wide` (≈ +0.025em)

**Numbers**

* Use `tabular-nums` for tables and dashboards.

---

## 4) Spacing & Layout (8-pt grid)

* Multiples of 4/8 only: 4, 8, 12, 16, 24, 32, 48, 64, 96, 128.
* **Baseline**: 16 or 24.
* **Group separation**: at least 2× the item spacing.
* **Consistent section gaps** across a page.

**Breakpoints**

* `sm:640`, `md:768`, `lg:1024`, `xl:1280`, `2xl:1536`

**Container**

```tsx
<div className="
  px-4 py-6 sm:px-6 sm:py-8 lg:px-8 lg:py-12
  max-w-7xl mx-auto
">...</div>
```

---

## 5) Visual Elements

**Shadows over borders** (except dividers, inputs, tables)

| Elevation | Tailwind   | Use                 |
| --------- | ---------- | ------------------- |
| z-1       | shadow-sm  | inputs, light cards |
| z-2       | shadow-md  | default cards       |
| z-3       | shadow-lg  | buttons, tabs       |
| z-4       | shadow-xl  | menus, popovers     |
| z-5       | shadow-2xl | modals              |

**Radius**

* Default `rounded-md` (8px), large surfaces `rounded-lg/xl`, pills `rounded-full`.

**Gradients**

* Monochromatic only, <20% opacity delta, vertical/horizontal. No diagonals, no rainbow.

**Background texture**

* Optional subtle noise ≤ 3–5% opacity.

**Motion**

* 75–150 ms micro, 300 ms page/modal, easing: ease-out in, ease-in out.

**Focus**

* Always show: `ring-2 ring-brand-primary ring-offset-2`.

---

## 6) Components (patterns, not pixels)

**Buttons**

* Height ≥ 44px; px-4 py-2; `font-medium` + `tracking-wide`.
* Variants: primary (brand), secondary (neutral-200), outline, ghost, destructive (semantic-error).
* States: hover darken + `shadow-sm`, active `scale-95`, focus ring, disabled `opacity-50`.

**Forms**

* Inputs height 44px; `border-neutral-300`; focus ring brand; inline validation.

**Cards**

* `p-6`, `bg-white`, `shadow-md` → hover `shadow-lg`, `rounded-lg`. Avoid thick borders.

**Nav**

* Sticky, 64px desktop / 56px mobile; `border-b neutral-200`; Logo → Nav → Actions.

**Modals**

* Overlay `neutral-900/50`; content `shadow-2xl rounded-lg p-6`; ESC and “X” close.

**Tables**

* `tabular-nums`; `px-4 py-3`; header `bg-neutral-100 font-semibold`; row hover `bg-neutral-50`.

**States**

* Empty: icon 48–64px, heading `text-xl`, helpful CTA.
* Error: semantic-error colors, details in monospace, clear retry.
* Loading: spinner 32px or skeletons.

---

## 7) Accessibility

**Contrast**

* Minimum: **4.5:1** normal text, **3:1** large text (≥24px regular or ≥18.66px bold).
* Target: **AAA 7:1** for body text where feasible.
* Validate combinations during design and in CI.

**Target sizes**

* **AA (WCAG 2.2)**: minimum **24×24 px** for interactive targets with exceptions.
* **Preferred**: **44×44 px** for comfortable touch.
* All interactive elements must be reachable by keyboard, have visible focus, and clear labels/ARIA.

**Semantics**

* Headings in order, labels bound with `htmlFor`, icon-only buttons have `aria-label`.
* Live regions for async feedback; never color-only indicators.

---

## 8) Tailwind v4 Integration

* Use **CSS variables as the source of truth** and reference them in Tailwind.
* Keep the theme surface small; avoid duplicating tokens inside `theme.extend.colors`.

```js
// tailwind.config.ts (v4+ style; minimal and variable-driven)
export default {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        brand: {
          primary: "var(--brand-primary)",
          primaryFg: "var(--brand-primary-fg)"
        },
        semantic: {
          success: "var(--semantic-success)",
          error: "var(--semantic-error)"
        },
        neutral: {
          50: "var(--neutral-50)",
          100: "var(--neutral-100)",
          200: "var(--neutral-200)",
          400: "var(--neutral-400)",
          600: "var(--neutral-600)",
          800: "var(--neutral-800)",
          950: "var(--neutral-950)"
        }
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
        mono: ["JetBrains Mono", "monospace"]
      }
    }
  }
};
```

---

## 9) Quality Gates (blockers vs warnings)

**Block PR if:**

* Tailwind config missing/broken.
* Any primary text/background fails **WCAG 1.4.3**.
* Interactive target under **24×24 px** with no valid exception.
* Design-lint finds hardcoded colors or arbitrary spacing in app code.

**Warn (fix soon):**

* 20–200 arbitrary values; non-critical contrast under AAA; custom fonts not optimized.

**Tooling**

* `design-lint.js`: grep for hex/rgb/hsl and `[Npx]` spacing.
* `@axe-core/playwright` or pa11y CI for a11y.
* Lighthouse CI: ≥90 accessibility, ≥85 performance.

---

## 10) Do / Don’t quick sheet

**Do**

* Use brand for CTAs, semantic for feedback, neutral for structure.
* Keep line length 50–75 chars, large clear headings, generous white space.
* Show focus rings and inline validation, confirm destructive actions.

**Don’t**

* Hardcode colors, mix random spacing, or hide focus indicators.
* Use brand color for headings or error states.
* Depend on color alone to convey meaning.

---

## Appendices

* Tokens: `design/systems/tokens.json`
* Inventory: `design/systems/ui-inventory.md`
* Lint script: `.spec-flow/scripts/design-lint.js`
