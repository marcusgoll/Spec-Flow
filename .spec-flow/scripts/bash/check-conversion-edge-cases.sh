#!/usr/bin/env bash
# Check for common HTML → TSX conversion edge cases
# Optional guidance script (skippable with --no-guidance)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

REPO_ROOT="$(resolve_repo_root)"

log_info "Checking for HTML → TSX conversion edge cases..."
log_info ""

# Find workspace
WORKSPACE=""
if [ -d "$REPO_ROOT/epics" ]; then
    for epic_dir in "$REPO_ROOT"/epics/*/; do
        if [ -f "${epic_dir}epic-spec.md" ] && [ ! -f "${epic_dir}completed/epic-spec.md" ]; then
            WORKSPACE="$epic_dir"
            break
        fi
    done
fi

if [ -z "$WORKSPACE" ] && [ -d "$REPO_ROOT/specs" ]; then
    for spec_dir in "$REPO_ROOT"/specs/*/; do
        if [ -f "${spec_dir}spec.md" ] && [ ! -f "${spec_dir}completed/spec.md" ]; then
            WORKSPACE="$spec_dir"
            break
        fi
    done
fi

if [ -z "$WORKSPACE" ]; then
    log_error "No active epic or feature found."
    exit 1
fi

MOCKUPS_DIR="${WORKSPACE}mockups"

if [ ! -d "$MOCKUPS_DIR" ]; then
    log_warn "No mockups directory found. Skipping edge case checks."
    exit 0
fi

EDGE_CASES_REPORT="${WORKSPACE}conversion-edge-cases.md"

# Create edge cases report
cat > "$EDGE_CASES_REPORT" << 'EOF'
# HTML → TSX Conversion Edge Cases

This checklist covers common edge cases when converting HTML blueprints to TSX components.
Review each section to ensure production-ready implementation.

## 1. Complex Interactions

**Blueprint shows end state, but TSX needs transition logic:**

- [ ] Form submission flows (loading → success/error)
- [ ] Modal open/close animations
- [ ] Dropdown menu interactions
- [ ] Accordion expand/collapse
- [ ] Tab switching with state persistence
- [ ] Infinite scroll / pagination
- [ ] Search with debouncing

**Action items:**
- Add useState/useReducer for state management
- Implement transition animations with framer-motion or CSS
- Handle loading/error states beyond what blueprint shows

---

## 2. Dynamic Data

**API responses may differ from mockup assumptions:**

- [ ] API shape matches blueprint expectations
- [ ] Null/undefined field handling
- [ ] Array.map() keys added for lists
- [ ] Empty state when API returns []
- [ ] Error boundaries for failed API calls
- [ ] Loading skeletons match blueprint layout

**Action items:**
- Define TypeScript interfaces for API responses
- Add error boundary components
- Implement fallback UI for missing data
- Use optional chaining (?.) for nested properties

---

## 3. Responsive Behavior

**Mobile layouts may need different component structure:**

- [ ] Hamburger menu for mobile nav
- [ ] Touch-friendly button sizes (min 44x44px)
- [ ] Stack cards on mobile, grid on desktop
- [ ] Hide/show elements at breakpoints
- [ ] Responsive typography (clamp, viewport units)
- [ ] Mobile-specific gestures (swipe, pull-to-refresh)

**Action items:**
- Use Tailwind responsive prefixes (sm:, md:, lg:)
- Test on mobile viewport (375px width minimum)
- Ensure all interactive elements meet WCAG AA touch targets

---

## 4. Performance

**Large lists and images need optimization:**

- [ ] Virtualized lists for 100+ items (react-window)
- [ ] Image optimization (next/image for Next.js)
- [ ] Lazy loading for off-screen components
- [ ] Code splitting for heavy components
- [ ] Memoization for expensive calculations (useMemo)
- [ ] Debounce/throttle for frequent events

**Action items:**
- Identify lists with >50 items → use virtual scrolling
- Replace <img> with Next.js Image component
- Use React.lazy() + Suspense for route-based splitting
- Wrap expensive renders with React.memo()

---

## 5. Accessibility

**Keyboard navigation and screen reader support:**

- [ ] Focus management (dialogs trap focus)
- [ ] Keyboard shortcuts documented (? key for help)
- [ ] ARIA live regions for dynamic updates
- [ ] Screen reader announcements for state changes
- [ ] Skip links for navigation
- [ ] Focus visible outlines (not removed with outline: none)

**Action items:**
- Test with keyboard only (no mouse)
- Run axe DevTools or Lighthouse accessibility audit
- Add aria-live="polite" for notifications
- Implement focus trapping for modals (use react-focus-lock)

---

## 6. TypeScript Types

**Blueprint doesn't specify types:**

- [ ] Component prop interfaces defined
- [ ] API response types match reality
- [ ] Event handler types (React.MouseEvent, etc.)
- [ ] Ref types (React.RefObject<HTMLDivElement>)
- [ ] Generic component types (<T,> for reusable components)
- [ ] Strict null checks enabled

**Action items:**
- No implicit any types allowed
- Use discriminated unions for variants (type="button" | "submit")
- Extract common types to shared types file

---

## 7. State Management

**Blueprint shows UI, but where does state live?**

- [ ] Local state (useState) vs context vs global store
- [ ] Form state (react-hook-form or controlled inputs)
- [ ] URL state (query params for filters/search)
- [ ] Server state caching (React Query, SWR)
- [ ] Optimistic updates for mutations

**Action items:**
- Keep state as local as possible (avoid context overuse)
- Use React Query for server state
- Use URL params for shareable/bookmarkable state
- Implement optimistic UI for better UX

---

## 8. Error Handling

**Blueprint only shows happy path:**

- [ ] Network errors (timeout, offline)
- [ ] Validation errors (client + server)
- [ ] 404 / 403 / 500 error pages
- [ ] Fallback UI when chunks fail to load
- [ ] Retry logic for transient failures
- [ ] User-friendly error messages (no stack traces)

**Action items:**
- Add error boundary at route level
- Implement retry button for failed requests
- Show user-friendly error messages
- Log errors to monitoring (Sentry, etc.)

---

## 9. Forms

**Blueprint shows form layout, but validation needs implementation:**

- [ ] Client-side validation (immediate feedback)
- [ ] Server-side validation (display errors from API)
- [ ] Field-level validation (onBlur)
- [ ] Submit button disabled while loading
- [ ] Success message / redirect after submit
- [ ] Form reset after successful submission

**Action items:**
- Use react-hook-form for complex forms
- Add yup or zod schema validation
- Disable submit button during API call
- Clear form or redirect after success

---

## 10. Routing

**Blueprint doesn't show routing logic:**

- [ ] Next.js Link components (not <a> tags)
- [ ] useRouter for programmatic navigation
- [ ] Prefetching for fast navigation
- [ ] Loading states during route changes
- [ ] 404 page for invalid routes
- [ ] Route guards (redirect if not authenticated)

**Action items:**
- Replace <a href> with <Link href>
- Use useRouter().push() for dynamic navigation
- Add loading.tsx or Suspense boundaries
- Implement middleware for auth checks

---

## Summary Checklist

Quick reference for all edge cases:

- [ ] Complex interactions implemented (not just end states)
- [ ] Dynamic data handled (null checks, empty states)
- [ ] Responsive behavior tested on mobile
- [ ] Performance optimized (lazy loading, virtualization)
- [ ] Accessibility tested (keyboard, screen reader)
- [ ] TypeScript types fully defined
- [ ] State management strategy chosen
- [ ] Error handling comprehensive
- [ ] Forms validated client + server
- [ ] Routing configured properly

---

**Status:** Review each section and check off items as you implement them.

**Tips:**
- Don't try to handle all edge cases at once
- Prioritize based on feature criticality
- Use TDD to catch edge cases early
- Test in browser DevTools with throttling/offline mode

EOF

log_info "✅ Edge case checklist created: ${EDGE_CASES_REPORT}"
log_info ""
log_info "Review the checklist and check off items as you implement them."
log_info ""
log_info "Common edge cases to watch for:"
log_info "  1. Complex interactions (forms, modals, animations)"
log_info "  2. Dynamic data (API shape, null handling)"
log_info "  3. Responsive behavior (mobile layouts)"
log_info "  4. Performance (large lists, image optimization)"
log_info "  5. Accessibility (keyboard nav, screen readers)"
log_info "  6. TypeScript types (no implicit any)"
log_info "  7. State management (local vs context vs global)"
log_info "  8. Error handling (network errors, validation)"
log_info "  9. Forms (validation, submit handling)"
log_info " 10. Routing (Next.js Link, route guards)"
log_info ""
log_info "💡 Tip: Use TDD to catch edge cases early!"

exit 0
