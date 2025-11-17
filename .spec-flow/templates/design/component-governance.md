# Component Governance

**Project**: {{PROJECT_NAME}}
**Last Updated**: {{LAST_UPDATED}}
**Version**: 1.0.0

---

## Overview

This document defines component interaction standards, state requirements, animation defaults, and loading patterns for {{PROJECT_NAME}}. It ensures consistent component behavior across all features.

**Purpose**: Establish guardrails for component design to prevent inconsistent user experiences.

---

## Component States

### Required States

**Minimum**: {{COMPONENT_STATES}}

{{#if STATES_BASIC}}
**Basic States** (Hover + Active only):
- **Default**: Resting state
- **Hover**: Pointer over component
- **Active**: Component being clicked/pressed

**Use Cases**: Minimal UIs, content-first applications
{{/if}}

{{#if STATES_EXTENDED}}
**Extended States** (Add Disabled + Loading):
- **Default**: Resting state
- **Hover**: Pointer over component
- **Active**: Component being clicked/pressed
- **Disabled**: Component unavailable (grayed out, not clickable)
- **Loading**: Async action in progress

**Use Cases**: Interactive applications, forms, data-driven UIs
{{/if}}

{{#if STATES_COMPLETE}}
**Complete States** (Add Error + Success):
- **Default**: Resting state
- **Hover**: Pointer over component
- **Active**: Component being clicked/pressed
- **Focus**: Keyboard focus indicator
- **Disabled**: Component unavailable
- **Loading**: Async action in progress
- **Error**: Validation failure or error condition
- **Success**: Successful completion

**Use Cases**: Complex applications, multi-step workflows, forms with validation
{{/if}}

{{#if STATES_COMPREHENSIVE}}
**Comprehensive States** (All 8+ states):
- **Default**: Resting state
- **Hover**: Pointer over component
- **Active**: Component being clicked/pressed
- **Focus**: Keyboard focus indicator
- **Disabled**: Component unavailable
- **Loading**: Async action in progress
- **Error**: Validation failure or error condition
- **Success**: Successful completion
- **Warning**: Caution state (reversible action)
- **Empty**: No data to display (empty state)

**Use Cases**: Enterprise applications, admin panels, complex workflows
{{/if}}

### State Implementation

**Button States**:
```css
/* Default */
.button {
  background: var(--color-primary-600);
  color: white;
  cursor: pointer;
}

/* Hover */
.button:hover {
  background: var(--color-primary-700);
}

/* Active */
.button:active {
  background: var(--color-primary-800);
}

/* Focus */
.button:focus {
  outline: 2px solid var(--color-primary-600);
  outline-offset: 2px;
}

/* Disabled */
.button:disabled {
  background: var(--color-neutral-300);
  color: var(--color-neutral-500);
  cursor: not-allowed;
  opacity: 0.6;
}

/* Loading */
.button[aria-busy="true"] {
  position: relative;
  color: transparent; /* Hide text */
}

.button[aria-busy="true"]::after {
  content: "";
  position: absolute;
  width: 16px;
  height: 16px;
  border: 2px solid white;
  border-top-color: transparent;
  border-radius: 50%;
  animation: spin 600ms linear infinite;
}
```

**Input States**:
```css
/* Default */
.input {
  border: 1px solid var(--color-neutral-300);
  background: white;
}

/* Focus */
.input:focus {
  border-color: var(--color-primary-600);
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

/* Error */
.input[aria-invalid="true"] {
  border-color: var(--color-error-600);
}

/* Disabled */
.input:disabled {
  background: var(--color-neutral-100);
  color: var(--color-neutral-500);
  cursor: not-allowed;
}

/* Success (optional) */
.input.success {
  border-color: var(--color-success-600);
}
```

---

## Animation Standards

### Defaults

**Duration**: {{ANIMATION_DURATION}}
**Easing**: {{ANIMATION_EASING}}

```css
:root {
  --duration-instant: 0ms;
  --duration-fast: {{DURATION_FAST}}ms;
  --duration-normal: {{DURATION_NORMAL}}ms;
  --duration-slow: {{DURATION_SLOW}}ms;

  --easing-linear: linear;
  --easing-ease: {{EASING_FUNCTION}};
  --easing-ease-in: cubic-bezier(0.4, 0, 1, 1);
  --easing-ease-out: cubic-bezier(0, 0, 0.2, 1);
  --easing-ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
}
```

{{#if DURATION_150}}
**Fast Animations** (150ms):
- Hover states
- Focus indicators
- Tooltips
- Small UI changes
{{/if}}

{{#if DURATION_300}}
**Normal Animations** (300ms):
- Dropdowns
- Modals
- Slide-ins
- Fade-ins
- Page transitions
{{/if}}

{{#if DURATION_500}}
**Slow Animations** (500ms):
- Complex transitions
- Page loads
- Multi-step animations
- Hero animations
{{/if}}

### Easing Functions

{{#if EASING_EASE_IN_OUT}}
**Ease-in-out** (default):
```css
transition: opacity 300ms ease-in-out;
```
- Smooth start and end
- General purpose
- Best for most UI transitions
{{/if}}

{{#if EASING_CUBIC}}
**Custom Cubic Bezier**:
```css
transition: transform 300ms cubic-bezier(0.34, 1.56, 0.64, 1);
```
- Brand-specific motion
- Bouncy or snappy effects
- Use sparingly for emphasis
{{/if}}

### Reduced Motion

**Respect User Preferences**:
```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

**Exceptions** (essential animations only):
- Loading spinners (slowed, not removed)
- Progress bars (instant updates)
- Focus indicators (instant, no transition)

---

## Interaction Patterns

### Hover Intent

**Strategy**: {{HOVER_INTENT}}

{{#if HOVER_INSTANT}}
**Instant Hover**:
```css
.button:hover {
  background: var(--color-primary-700);
  transition: background 150ms ease-in-out;
}
```
- No delay
- Immediate feedback
- Best for desktop-first apps
{{/if}}

{{#if HOVER_DELAYED}}
**Delayed Hover** (200ms):
```javascript
let hoverTimeout;
element.addEventListener('mouseenter', () => {
  hoverTimeout = setTimeout(() => {
    element.classList.add('hovered');
  }, 200);
});
element.addEventListener('mouseleave', () => {
  clearTimeout(hoverTimeout);
  element.classList.remove('hovered');
});
```
- Prevents accidental hovers
- Smoother for trackpad users
{{/if}}

{{#if HOVER_TOUCH_FRIENDLY}}
**Touch-Friendly** (no hover states):
```css
/* Only show hover on devices with hover capability */
@media (hover: hover) {
  .button:hover {
    background: var(--color-primary-700);
  }
}

/* Touch devices: rely on :active instead */
.button:active {
  background: var(--color-primary-800);
}
```
- No hover on touch devices
- Use :active for touch feedback
- Best for mobile-first apps
{{/if}}

### Click/Tap Feedback

**Visual Feedback Required**:
- Scale: `transform: scale(0.98)` on active
- Color: Darker shade on active
- Ripple effect (Material Design style)

**Haptic Feedback** (mobile):
```javascript
// Trigger device vibration on critical actions
navigator.vibrate(50); // 50ms vibration
```

---

## Loading Patterns

### Pattern: {{LOADING_PATTERN}}

{{#if LOADING_SPINNER}}
**Spinner**:
```html
<div class="spinner" role="status" aria-label="Loading">
  <svg viewBox="0 0 50 50">
    <circle cx="25" cy="25" r="20" fill="none" stroke="currentColor" stroke-width="4" />
  </svg>
</div>
```

```css
.spinner {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
```

**Use Cases**:
- Small components (buttons, cards)
- Quick operations (< 2 seconds)
- Indeterminate progress
{{/if}}

{{#if LOADING_SKELETON}}
**Skeleton Screens**:
```html
<div class="skeleton skeleton-text"></div>
<div class="skeleton skeleton-avatar"></div>
<div class="skeleton skeleton-card"></div>
```

```css
.skeleton {
  background: linear-gradient(
    90deg,
    var(--color-neutral-200) 0%,
    var(--color-neutral-300) 50%,
    var(--color-neutral-200) 100%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}

@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

.skeleton-text {
  height: 1rem;
  border-radius: 4px;
}

.skeleton-avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
}

.skeleton-card {
  width: 100%;
  height: 200px;
  border-radius: 8px;
}
```

**Use Cases**:
- Page loads
- Content-heavy screens
- List/grid views
- Slower operations (> 2 seconds)

**Benefits**:
- Perceived performance improvement
- Clearer layout structure
- Less jarring than spinners
{{/if}}

{{#if LOADING_PROGRESS}}
**Progress Bars**:
```html
<div class="progress" role="progressbar" aria-valuenow="65" aria-valuemin="0" aria-valuemax="100">
  <div class="progress-bar" style="width: 65%"></div>
</div>
<span class="sr-only">65% complete</span>
```

```css
.progress {
  height: 8px;
  background: var(--color-neutral-200);
  border-radius: 4px;
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  background: var(--color-primary-600);
  transition: width 300ms ease-out;
}
```

**Use Cases**:
- File uploads
- Multi-step forms
- Long-running processes (> 5 seconds)
- Determinate progress (known duration)
{{/if}}

{{#if LOADING_SHIMMER}}
**Shimmer Effect**:
```css
.shimmer {
  position: relative;
  overflow: hidden;
  background: var(--color-neutral-100);
}

.shimmer::after {
  content: "";
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  background: linear-gradient(
    90deg,
    transparent,
    rgba(255, 255, 255, 0.5),
    transparent
  );
  animation: shimmer 2s infinite;
}

@keyframes shimmer {
  from { transform: translateX(-100%); }
  to { transform: translateX(100%); }
}
```

**Use Cases**:
- Image placeholders
- Lazy-loaded content
- Cards before data loads
{{/if}}

### Loading State Accessibility

**ARIA Attributes**:
```html
<!-- Button loading -->
<button aria-busy="true" aria-label="Saving changes">
  <span aria-hidden="true"><!-- Spinner --></span>
</button>

<!-- Section loading -->
<div aria-busy="true" aria-live="polite" aria-label="Loading dashboard data">
  <!-- Skeleton content -->
</div>

<!-- Completion announcement -->
<div role="status" aria-live="polite" aria-atomic="true">
  Data loaded successfully.
</div>
```

---

## Empty States

### Guidelines

**Every list/table/grid MUST have an empty state.**

**Components**:
1. **Icon or Illustration** (optional, recommended)
2. **Heading**: "No [items] yet" or similar
3. **Description**: Why it's empty, what user can do
4. **Primary Action**: CTA button to create first item

**Example**:
```html
<div class="empty-state">
  <svg class="empty-icon"><!-- Icon --></svg>
  <h3>No projects yet</h3>
  <p>Create your first project to get started with task tracking.</p>
  <button class="button-primary">Create Project</button>
</div>
```

```css
.empty-state {
  text-align: center;
  padding: var(--space-12);
  color: var(--color-text-secondary);
}

.empty-icon {
  width: 64px;
  height: 64px;
  margin-bottom: var(--space-4);
  opacity: 0.5;
}
```

**Tone**: {{EMPTY_STATE_TONE}}

{{#if EMPTY_FRIENDLY}}
- "Nothing here yet. Create your first project!"
- Encouraging, action-oriented
{{/if}}

{{#if EMPTY_NEUTRAL}}
- "No data available. Add an item to get started."
- Professional, clear
{{/if}}

---

## Error Handling

### Error States

**Component Error Display**:
```html
<div class="alert alert-error" role="alert">
  <svg class="alert-icon"><!-- Error icon --></svg>
  <div class="alert-content">
    <strong>Error</strong>
    <p>{{ERROR_MESSAGE}}</p>
  </div>
  <button class="alert-dismiss" aria-label="Dismiss error">×</button>
</div>
```

**Form Validation Errors**:
```html
<div class="form-field">
  <label for="email">Email</label>
  <input
    type="email"
    id="email"
    aria-invalid="true"
    aria-describedby="email-error">
  <span id="email-error" class="error-message" role="alert">
    Please enter a valid email address.
  </span>
</div>
```

### Error Message Tone

**Tone**: {{ERROR_MESSAGE_TONE}}

{{#if ERROR_FRIENDLY}}
**Friendly**:
- "Oops! Something went wrong."
- "We couldn't save your changes. Please try again."
- Never blame the user
{{/if}}

{{#if ERROR_TECHNICAL}}
**Technical**:
- "Error: Invalid input."
- "Failed to connect to server (ERR_CONNECTION_REFUSED)."
- Include error codes for debugging
{{/if}}

**Structure**: [Problem] + [Solution]
- ✅ "File too large. Maximum size is 5MB."
- ❌ "Error uploading file."

---

## Success Feedback

### Success States

**Inline Success**:
```html
<div class="alert alert-success" role="status" aria-live="polite">
  <svg class="alert-icon"><!-- Checkmark icon --></svg>
  <div class="alert-content">
    <strong>Success</strong>
    <p>Changes saved successfully.</p>
  </div>
</div>
```

**Toast Notifications**:
```html
<div class="toast toast-success" role="status" aria-live="polite">
  <svg class="toast-icon"><!-- Checkmark --></svg>
  <span>Project created!</span>
</div>
```

```css
.toast {
  position: fixed;
  bottom: var(--space-4);
  right: var(--space-4);
  padding: var(--space-4);
  background: var(--color-success-600);
  color: white;
  border-radius: var(--rounded-lg);
  box-shadow: var(--shadow-lg);
  animation: slide-in-up 300ms ease-out;
}

@keyframes slide-in-up {
  from {
    transform: translateY(100%);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}
```

**Auto-Dismiss**: 4-6 seconds for success, indefinite for errors

---

## Component Checklist

**Before Shipping ANY Component**:

- [ ] All {{COMPONENT_STATES}} states implemented
- [ ] Animations respect `prefers-reduced-motion`
- [ ] Keyboard navigation works (Tab, Enter, Space, Esc)
- [ ] Focus indicator visible ({{FOCUS_INDICATOR_STYLE}})
- [ ] ARIA labels for screen readers
- [ ] Loading state for async actions
- [ ] Error state with helpful message
- [ ] Empty state if applicable
- [ ] Contrast meets WCAG {{WCAG_LEVEL}} (≥{{CONTRAST_REQUIREMENT}})
- [ ] Tested on mobile (touch-friendly)
- [ ] Tested with screen reader (NVDA/VoiceOver)
- [ ] Documented in component library

---

## References

- **Design Tokens**: `design/systems/tokens.css`
- **Brand Guidelines**: `docs/design/brand-guidelines.md`
- **Visual Language**: `docs/design/visual-language.md`
- **Accessibility Standards**: `docs/design/accessibility-standards.md`

---

**Document Owner**: {{DOCUMENT_OWNER}}
**Last Review**: {{LAST_REVIEW_DATE}}
**Next Review**: {{NEXT_REVIEW_DATE}}
