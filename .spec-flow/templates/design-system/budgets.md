# Performance & Accessibility Budgets

**Non-negotiable thresholds for production releases**

All budgets are validated in `/optimize` phase before shipping to production.

---

## Core Web Vitals (Google)

### Largest Contentful Paint (LCP)
**Target**: ≤ 2.5s (75th percentile)

**What it measures**: Time until largest content element is visible

**How to measure**:
```bash
# Lighthouse CI (automated)
pnpm lighthouse:ci

# Manual (Chrome DevTools)
# Performance tab → Timings → LCP
```

**How to optimize**:
- Optimize images (WebP, lazy loading, Next.js Image)
- Preload critical resources (`<link rel="preload">`)
- Minimize render-blocking CSS/JS
- Use CDN for static assets

---

### First Input Delay (FID)
**Target**: ≤ 100ms (75th percentile)

**What it measures**: Time from first user interaction to browser response

**How to measure**:
```bash
# Real User Monitoring (PostHog)
# Field data only (lab tests use TBT instead)
```

**How to optimize**:
- Split long tasks (use `setTimeout` to yield to main thread)
- Code splitting (dynamic imports)
- Web Workers for heavy computation
- Defer non-critical scripts

---

### Cumulative Layout Shift (CLS)
**Target**: ≤ 0.1 (75th percentile)

**What it measures**: Visual stability (unexpected layout shifts)

**How to measure**:
```bash
# Lighthouse CI (automated)
pnpm lighthouse:ci

# Manual (Chrome DevTools)
# Performance tab → Experience → CLS
```

**How to optimize**:
- Reserve space for images/ads (`width` + `height` attrs)
- Avoid inserting content above existing content
- Use CSS `transform` instead of position changes
- Preload web fonts (`<link rel="preload" as="font">`)

---

### Interaction to Next Paint (INP)
**Target**: ≤ 200ms (75th percentile)

**Replacing FID as Core Web Vital in 2024**

**What it measures**: Responsiveness to all user interactions

**How to optimize**:
- Same as FID optimization
- Profile with Chrome DevTools Performance tab
- Minimize JavaScript execution time

---

## Page Load Metrics

### First Contentful Paint (FCP)
**Target**: ≤ 1.5s

**What it measures**: Time until first text/image renders

**Optimization**: Same as LCP (render-blocking resources)

---

### Time to Interactive (TTI)
**Target**: ≤ 3.0s

**What it measures**: Time until page is fully interactive

**Optimization**:
- Reduce JavaScript bundle size
- Code splitting (route-based)
- Lazy load non-critical components

---

### Speed Index
**Target**: ≤ 3.0s

**What it measures**: How quickly content is visually populated

**Optimization**: Same as FCP/LCP

---

## Bundle Size Budgets

### Initial JavaScript Bundle
**Target**: ≤ 200 KB (gzipped)

**What it measures**: First-load JS (critical path)

**How to measure**:
```bash
# Next.js build output
pnpm build

# Bundle analyzer
pnpm analyze
```

**How to optimize**:
- Dynamic imports (`next/dynamic`)
- Tree shaking (ES6 modules)
- Remove unused dependencies
- Use lighter alternatives (date-fns → day.js)

---

### Total JavaScript Bundle
**Target**: ≤ 500 KB (gzipped)

**What it measures**: All JS loaded for current route

**Optimization**: Same as initial bundle

---

### CSS Bundle
**Target**: ≤ 50 KB (gzipped)

**What it measures**: Tailwind CSS output

**How to optimize**:
- PurgeCSS (automatic in production)
- Remove unused Tailwind utilities
- Avoid `@apply` in components (use utilities directly)

---

### Image Optimization
**Target**:
- Hero images: ≤ 100 KB
- Thumbnails: ≤ 20 KB
- Icons: Use SVG or icon font

**Formats**:
- WebP (primary)
- AVIF (progressive enhancement)
- PNG fallback

**Tools**:
- Next.js Image component (automatic optimization)
- Squoosh.app (manual compression)

---

## Lighthouse Scores

### Performance
**Target**: ≥ 85

**Measured in Lighthouse CI**

**Factors**:
- FCP, LCP, TTI, Speed Index, TBT, CLS
- Bundle size
- Render-blocking resources

---

### Accessibility
**Target**: ≥ 95

**Automated checks**:
- Color contrast (4.5:1 normal text, 3:1 large text)
- ARIA labels (buttons, inputs, landmarks)
- Keyboard navigation (focusable, no traps)
- Form labels (explicit association)
- Alt text (images, icons)
- Heading hierarchy (h1 → h2 → h3, no skips)

**Manual checks** (required for 100 score):
- Screen reader testing (NVDA/VoiceOver)
- Keyboard-only navigation
- Focus visible on all interactive elements
- Skip links for main content

---

### Best Practices
**Target**: ≥ 90

**Checks**:
- HTTPS
- No console errors
- Modern image formats (WebP)
- No deprecated APIs
- Proper CSP headers

---

### SEO
**Target**: ≥ 90

**Checks**:
- Meta tags (title, description)
- Valid HTML
- Mobile-friendly (viewport meta tag)
- Crawlable (robots.txt, sitemap.xml)

---

## Accessibility Compliance (WCAG 2.1 AA)

### Color Contrast
**Target**:
- Normal text (16px): ≥ 4.5:1
- Large text (18px+): ≥ 3:1
- UI components: ≥ 3:1

**How to measure**:
```bash
# Automated (axe-core in Playwright tests)
pnpm test:a11y

# Manual (browser DevTools)
# Inspect element → Accessibility pane → Contrast ratio
```

**Tools**:
- Contrast checker: https://webaim.org/resources/contrastchecker/
- Palette generator: https://leonardocolor.io/

---

### Touch Targets
**Target**: ≥ 44x44 pixels (iOS HIG, Material Design)

**What it measures**: Minimum tappable area

**How to validate**:
```tsx
// Buttons, links, interactive elements
<Button className="min-h-[44px] min-w-[44px]">
  Click me
</Button>

// Or use padding to expand hit area
<button className="p-3">
  Icon only
</button>
```

---

### Keyboard Navigation
**Requirements**:
- All interactive elements focusable (Tab)
- Focus visible (2px ring)
- Enter/Space activate buttons
- ESC closes modals/dropdowns
- Arrow keys navigate lists/menus
- No keyboard traps

**How to test**:
1. Disconnect mouse
2. Tab through entire page
3. Verify focus visible
4. Verify all actions reachable
5. Verify ESC closes modals

---

### Screen Reader Support
**Requirements**:
- Semantic HTML (nav, main, article, section)
- ARIA landmarks (role="banner", "navigation", "main")
- ARIA labels (aria-label, aria-labelledby, aria-describedby)
- Live regions (aria-live="polite", aria-atomic="true")
- Form labels (explicit <label> or aria-label)

**How to test**:
- NVDA (Windows): Free
- VoiceOver (macOS): Built-in (Cmd+F5)
- JAWS (Windows): Commercial

---

## Monitoring & Enforcement

### Pre-commit Hooks
**Enforced**:
- Lighthouse CI (performance + a11y)
- Bundle size check (initial ≤ 200 KB)
- axe-core tests (a11y violations)

**Location**: `.husky/pre-commit`

---

### Pre-push Hooks
**Enforced**:
- Smoke tests (critical paths)
- TypeScript type check
- ESLint (max warnings: 0)

**Location**: `.husky/pre-push`

---

### CI/CD Pipeline
**Enforced**:
- Lighthouse CI (all budgets)
- Bundle size regression (fail if >10% increase)
- Visual regression (Percy snapshots)
- E2E tests (Playwright)

**Location**: `.github/workflows/verify.yml`

---

### Production Monitoring
**Tools**:
- PostHog (Core Web Vitals, custom events)
- Sentry (error tracking, performance)
- Vercel Analytics (real user monitoring)

**Alerts**:
- LCP > 2.5s (75th percentile)
- CLS > 0.1 (75th percentile)
- Error rate > 1%
- API p95 > 500ms

---

## Budget Exceptions

**When to request exception:**
- Third-party scripts (analytics, ads) - document impact
- Rich media features (video players) - lazy load
- Complex interactions (maps, charts) - code split

**Process**:
1. Document in `specs/NNN-feature/artifacts/optimization-report.md`
2. Explain why budget cannot be met
3. Show mitigation strategy (lazy load, code split, defer)
4. Get approval from tech lead before shipping

---

## References

- Google Web Vitals: https://web.dev/vitals/
- WCAG 2.1 AA: https://www.w3.org/WAI/WCAG21/quickref/?currentsidebar=%23col_overview&levels=aa
- Lighthouse scoring: https://developer.chrome.com/docs/lighthouse/performance/performance-scoring/
- Next.js optimization: https://nextjs.org/docs/pages/building-your-application/optimizing

**Last updated**: 2025-10-06
