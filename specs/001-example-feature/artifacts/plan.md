# Implementation Plan: Dark Mode Toggle

**Feature**: Dark Mode Toggle
**Branch**: `001-dark-mode-toggle`
**Estimated Effort**: 2 days
**Risk Level**: Low

## Overview

Implement a theme toggle that allows users to switch between light and dark modes, with persistence and system preference support. This is a foundational UX feature that improves accessibility and user comfort.

## Architecture Decisions

### 1. State Management: React Context
**Decision**: Use React Context API for theme state
**Rationale**:
- Lightweight (no external dependencies)
- Sufficient for global theme state
- Easy to test and maintain
**Alternatives Considered**:
- Redux: Overkill for simple boolean state
- Prop drilling: Unscalable, error-prone

### 2. Styling: CSS Custom Properties
**Decision**: Use CSS variables for theme tokens
**Rationale**:
- No runtime overhead (unlike CSS-in-JS)
- Easy to debug in DevTools
- Native browser support
- Simple implementation
**Alternatives Considered**:
- styled-components: Adds bundle size, runtime cost
- Separate CSS files: Harder to maintain, switching overhead

### 3. Persistence: localStorage
**Decision**: localStorage with fallbacks
**Rationale**:
- Simple API
- Persists across sessions
- Well-supported
**Fallback Chain**:
1. localStorage (primary)
2. sessionStorage (Safari private mode)
3. In-memory state (last resort)

### 4. System Preference: prefers-color-scheme
**Decision**: Respect system preference for first-time users
**Rationale**:
- Modern UX expectation
- Better default experience
- Follows platform conventions

## Implementation Phases

### Phase 1: Core Theme Infrastructure (4 hours)
1. Create `ThemeContext.tsx` with provider and hook
2. Define TypeScript interfaces for theme state
3. Implement system preference detection
4. Implement localStorage persistence with fallbacks
5. Add theme state management logic

**Deliverables**:
- `src/contexts/ThemeContext.tsx`
- `src/hooks/useTheme.ts`
- Unit tests for theme logic

### Phase 2: CSS Variables & Tokens (2 hours)
1. Define color tokens for light theme
2. Define color tokens for dark theme
3. Create CSS variable mappings
4. Add transition animations
5. Test color contrast ratios (WCAG AA)

**Deliverables**:
- `src/styles/tokens.css`
- `src/styles/themes.css`
- Accessibility audit report

### Phase 3: Toggle Component (3 hours)
1. Create `ThemeToggle.tsx` component
2. Implement sun/moon icon switching
3. Add tooltip for better UX
4. Add keyboard accessibility (Space/Enter)
5. Add focus indicators
6. Style for mobile and desktop

**Deliverables**:
- `src/components/ThemeToggle.tsx`
- Component tests
- Storybook stories (if applicable)

### Phase 4: Integration & FOUC Fix (2 hours)
1. Wrap App with ThemeProvider
2. Add inline script to prevent FOUC
3. Update global styles to use CSS variables
4. Test theme switching across all components
5. Verify persistence works

**Deliverables**:
- Updated `src/App.tsx`
- Updated `public/index.html`
- Integration tests

### Phase 5: Testing & Optimization (3 hours)
1. Write unit tests (ThemeContext, useTheme, ThemeToggle)
2. Write integration tests (persistence, system preference)
3. Write E2E tests (toggle flow)
4. Performance testing (measure switch time)
5. Cross-browser testing (Chrome, Firefox, Safari, Edge)
6. Accessibility audit (WCAG 2.1 AA)

**Deliverables**:
- Test suite (≥80% coverage)
- Performance report
- Accessibility report
- Browser compatibility matrix

## Technical Specifications

### File Structure
```
src/
├── contexts/
│   └── ThemeContext.tsx          # Theme provider and context
├── hooks/
│   └── useTheme.ts               # Custom hook for theme access
├── components/
│   ├── ThemeToggle.tsx           # Toggle button component
│   └── __tests__/
│       └── ThemeToggle.test.tsx
├── styles/
│   ├── tokens.css                # Color tokens
│   └── themes.css                # Theme definitions
└── App.tsx                       # Wrap with ThemeProvider
```

### API Surface

**ThemeContext**:
```typescript
interface ThemeContextValue {
  theme: 'light' | 'dark' | 'system'
  effectiveTheme: 'light' | 'dark'
  setTheme: (theme: 'light' | 'dark' | 'system') => void
}
```

**useTheme hook**:
```typescript
const { theme, effectiveTheme, setTheme } = useTheme()
```

**ThemeToggle component**:
```tsx
<ThemeToggle /> // No props needed, uses context
```

## Risk Assessment

### Low Risk
- ✅ Well-understood problem domain
- ✅ Proven patterns in industry
- ✅ No external dependencies
- ✅ Easy to test
- ✅ Reversible changes

### Mitigation Strategies

**Risk**: FOUC (Flash of Unstyled Content) on page load
**Mitigation**: Inline script in index.html to set theme before React hydration

**Risk**: localStorage not available (Safari private mode)
**Mitigation**: Graceful fallback chain (localStorage → sessionStorage → in-memory)

**Risk**: Contrast ratios fail WCAG
**Mitigation**: Use automated testing tools (axe, Lighthouse) during development

**Risk**: Performance degradation on theme switch
**Mitigation**: Use CSS variables (no JS required for repaints), benchmark target <200ms

## Dependencies

**No new dependencies required!**
- React (already in project)
- localStorage API (native)
- CSS custom properties (native)

## Testing Strategy

### Unit Tests
- ThemeProvider provides correct context
- useTheme hook returns expected values
- localStorage read/write works correctly
- Fallback chain works when localStorage unavailable
- System preference detection works

### Integration Tests
- Theme changes update CSS variables
- Preference persists after page refresh
- System preference respected for new users

### E2E Tests
- User can click toggle and see theme change
- Theme persists after browser close/reopen
- Toggle works on mobile and desktop

### Performance Tests
- Theme switch completes in <200ms (P95)
- No layout shift (CLS) during transition

## Success Criteria

- [ ] Toggle button visible in navigation on all pages
- [ ] Theme switches within 200ms (P95)
- [ ] Preference persists across sessions for ≥99% of users
- [ ] Both themes meet WCAG 2.1 AA contrast requirements
- [ ] Works in Chrome, Firefox, Safari, Edge (last 2 versions)
- [ ] Mobile responsive (≥320px screen width)
- [ ] All tests passing (≥80% coverage)
- [ ] No accessibility violations

## Rollout Plan

1. **Development**: Implement in feature branch `001-dark-mode-toggle`
2. **Code Review**: Submit PR, address feedback
3. **QA Testing**: Deploy to staging, manual QA across browsers/devices
4. **Staging Validation**: E2E tests, Lighthouse audit, accessibility scan
5. **Production Deploy**: Merge to main, deploy to production
6. **Monitoring**: Track toggle usage, error rates, performance metrics
7. **Iteration**: Gather user feedback, iterate if needed

## Timeline

- **Day 1 Morning**: Phases 1-2 (infrastructure + CSS)
- **Day 1 Afternoon**: Phase 3 (component)
- **Day 2 Morning**: Phase 4 (integration)
- **Day 2 Afternoon**: Phase 5 (testing + optimization)
- **Day 3**: Code review, QA, deployment
