# Accessibility Standards

**Project**: {{PROJECT_NAME}}
**Last Updated**: {{LAST_UPDATED}}
**Version**: 1.0.0
**WCAG Level**: {{WCAG_LEVEL}}

---

## Overview

This document defines accessibility standards for {{PROJECT_NAME}} to ensure inclusive access for all users, including those using assistive technologies.

**Compliance Target**: WCAG 2.1 Level {{WCAG_LEVEL}}

**Philosophy**: Accessibility is not optional—it's a core requirement for every component and feature.

---

## WCAG Compliance

### Level {{WCAG_LEVEL}} Requirements

{{#if WCAG_AA}}
**WCAG 2.1 AA** (Standard - Recommended):
- **Contrast**: ≥4.5:1 for normal text, ≥3:1 for large text (18px+)
- **Keyboard**: All functionality accessible via keyboard
- **Focus**: Visible focus indicators on all interactive elements
- **Labels**: All form inputs have labels
- **Headings**: Proper heading hierarchy (H1 → H2 → H3)
- **Alt Text**: All images have descriptive alt text
- **Color**: Information not conveyed by color alone
{{/if}}

{{#if WCAG_AAA}}
**WCAG 2.1 AAA** (Enhanced - High Contrast):
- **Contrast**: ≥7:1 for normal text, ≥4.5:1 for large text
- **Audio**: Captions AND sign language for all video
- **Timing**: No time limits on content
- **Interruptions**: Can be postponed or suppressed
- **Re-authentication**: Data preserved after session timeout
- **All AA requirements** (see above)
{{/if}}

{{#if WCAG_A}}
**WCAG 2.1 A** (Minimum):
- **Keyboard**: Basic keyboard access
- **Alt Text**: Non-text content has alternatives
- **Captions**: Pre-recorded audio has captions
- **Contrast**: No specific requirements
- **Note**: Level A is NOT recommended for production apps
{{/if}}

### Automated Testing

**Required Tools**:
- **axe DevTools** (browser extension)
- **Lighthouse** (Chrome DevTools)
- **Pa11y** (CI pipeline)

**CI Quality Gate**:
```bash
# Fail build if critical accessibility violations found
pa11y-ci --threshold 0 --level error
```

---

## Color & Contrast

### Contrast Requirements

**Text Contrast**: {{CONTRAST_REQUIREMENT}}

{{#if CONTRAST_4_5}}
**WCAG AA (4.5:1 ratio)**:
- Normal text (< 18px): ≥4.5:1
- Large text (≥18px or ≥14px bold): ≥3:1
- UI components: ≥3:1 (borders, icons, focus indicators)
{{/if}}

{{#if CONTRAST_7}}
**WCAG AAA (7:1 ratio)**:
- Normal text: ≥7:1
- Large text: ≥4.5:1
- UI components: ≥3:1
{{/if}}

**Auto-Fix Strategy**:
- All tokens.css colors automatically validated
- OKLCH color space adjustments for perceptually uniform contrast
- Lightness adjusted until ratio met
- Original colors preserved in comments

**Example**:
```css
/* Original: #3b82f6 (contrast: 3.2:1 ❌) */
/* Fixed:    #2563eb (contrast: 4.7:1 ✅) */
--color-text-primary: #2563eb;
```

### Color-Blind Safe Palettes

**Deuteranopia & Protanopia** (red-green):
- Avoid red/green for success/error
- Use blue/yellow or blue/orange instead
- Semantic colors: Green (success) + Red (error) + Blue (info) + Orange (warning)

**Tritanopia** (blue-yellow):
- Avoid blue/yellow combinations
- Use red/green or red/blue instead

**Best Practice**: Always pair color with icons or text labels
- ✅ Green checkmark icon + "Success" text
- ❌ Green background alone

### Non-Color Indicators

**Required**: Information MUST NOT be conveyed by color alone.

**Examples**:
- Form validation: Icon + color + text message
- Chart data: Patterns + colors
- Links: Underline + color + hover state
- Status: Icon + badge + tooltip

---

## Keyboard Navigation

### Standards

**Requirement**: All functionality accessible via keyboard (no mouse required).

**Tab Order**: {{KEYBOARD_NAV_STANDARD}}

{{#if KEYBOARD_STANDARD}}
**Standard Tab Order**:
- Logical flow (left-to-right, top-to-bottom)
- Skip repetitive content (skip links)
- Modal traps focus (Escape to close)
- No keyboard traps (can always exit)
{{/if}}

{{#if KEYBOARD_SHORTCUTS}}
**Custom Keyboard Shortcuts**:
- **Global**: Clearly documented, avoid conflicts
- **Context**: Component-specific shortcuts disclosed
- **Override**: User can disable or remap shortcuts

**Example Shortcuts**:
- `?`: Show keyboard shortcuts help
- `/`: Focus search input
- `Escape`: Close modal/dropdown
- `Ctrl+S`: Save (standard shortcuts only)
{{/if}}

{{#if KEYBOARD_SKIP_LINKS}}
**Skip Links**:
- "Skip to main content" (first tab stop)
- "Skip to navigation"
- "Skip to footer"
- Visible on focus, hidden otherwise
{{/if}}

### Focus Management

**Focus Indicators**: {{FOCUS_INDICATOR_STYLE}}

{{#if FOCUS_OUTLINE}}
**Outline Style**:
```css
:focus {
  outline: 2px solid var(--color-primary-600);
  outline-offset: 2px;
}
```
- Minimum: 2px thickness
- Color: High contrast (≥3:1 against background)
- Never: `outline: none` without replacement
{{/if}}

{{#if FOCUS_RING}}
**Ring Style** (Tailwind-inspired):
```css
:focus {
  outline: none;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.5);
}
```
- Softer appearance than outline
- Respects border-radius
- 3-4px ring width
{{/if}}

{{#if FOCUS_UNDERLINE}}
**Underline Style**:
```css
a:focus {
  text-decoration: underline;
  text-decoration-thickness: 2px;
  text-underline-offset: 2px;
}
```
- Use for text links
- Combine with color change
{{/if}}

{{#if FOCUS_GLOW}}
**Glow Style**:
```css
:focus {
  box-shadow: 0 0 8px 2px var(--color-primary-400);
}
```
- Dramatic, brand-forward
- Ensure ≥3:1 contrast
{{/if}}

**Focus Order**:
1. Skip links (if present)
2. Header navigation
3. Main content
4. Sidebar (if present)
5. Footer navigation

**Modal Focus Trap**:
```javascript
// Focus first element in modal on open
modal.querySelector('button, [href], input, select, textarea').focus();

// Trap Tab key inside modal
document.addEventListener('keydown', (e) => {
  if (e.key === 'Tab') {
    // Cycle within modal only
  }
});

// Return focus to trigger on close
triggerButton.focus();
```

---

## Motion & Animation

### Preferences

**Motion Policy**: {{MOTION_PREFERENCE}}

{{#if MOTION_FULL}}
**Full Animations** (default):
- Smooth transitions on state changes
- Decorative animations for delight
- Loading animations and skeletons

**Reduced Motion Override**:
```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```
{{/if}}

{{#if MOTION_RESPECT}}
**Respect prefers-reduced-motion** (default):
```css
/* Default: No animation */
.element {
  transition: none;
}

/* Only animate if user hasn't opted out */
@media (prefers-reduced-motion: no-preference) {
  .element {
    transition: opacity 300ms ease-in-out;
  }
}
```
- All animations gated behind media query
- Essential animations (loading) use reduced-motion fallback
{{/if}}

{{#if MOTION_MINIMAL}}
**Minimal Motion** (always):
- No decorative animations
- Instant state changes
- Loading indicators only (minimal movement)
{{/if}}

### Animation Guidelines

**Allowed Animations** (even with prefers-reduced-motion):
- Loading spinners (slow rotation, <5s per rotation)
- Progress bars (linear movement)
- Focus indicators (instant, no transition)

**Prohibited** (if prefers-reduced-motion):
- Parallax scrolling
- Auto-playing video
- Infinite loops (carousels)
- Sudden flashes (seizure risk)

**WCAG 2.3.1 - Three Flashes**:
- NO content flashes more than 3 times per second
- Flashing content = strobing/rapid brightness changes
- Seizure risk threshold

---

## Screen Readers

### Priority Level

**Support**: {{SCREEN_READER_PRIORITY}}

{{#if SCREEN_READER_STANDARD}}
**Standard Support**:
- Semantic HTML (headings, lists, nav, main, aside)
- Alt text on all images
- Form labels (explicit `<label>` elements)
- ARIA landmarks (basic: banner, main, contentinfo)
- ARIA live regions for dynamic content
{{/if}}

{{#if SCREEN_READER_ENHANCED}}
**Enhanced ARIA**:
- All standard support (above) PLUS:
- ARIA descriptions (`aria-describedby`)
- ARIA states (`aria-expanded`, `aria-selected`)
- ARIA properties (`aria-labelledby`, `aria-controls`)
- Custom components with full ARIA patterns
- Announcements for all async actions
{{/if}}

{{#if SCREEN_READER_OPTIMIZED}}
**Optimized Landmarks**:
- Granular landmark structure
- Search landmark for search forms
- Multiple navigation landmarks (labeled)
- Complementary for sidebars
- Region for major page sections
- Skip-to-region links
{{/if}}

### ARIA Patterns

**Interactive Components**:

**Dropdown Menu**:
```html
<button aria-expanded="false" aria-controls="menu-1" aria-haspopup="true">
  Options
</button>
<ul id="menu-1" role="menu" hidden>
  <li role="menuitem"><a href="#1">Item 1</a></li>
  <li role="menuitem"><a href="#2">Item 2</a></li>
</ul>
```

**Tab Panel**:
```html
<div role="tablist" aria-label="Settings">
  <button role="tab" aria-selected="true" aria-controls="panel-1">General</button>
  <button role="tab" aria-selected="false" aria-controls="panel-2">Security</button>
</div>
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1">
  General settings content...
</div>
```

**Modal Dialog**:
```html
<div role="dialog" aria-modal="true" aria-labelledby="modal-title">
  <h2 id="modal-title">Confirm Delete</h2>
  <p>Are you sure you want to delete this item?</p>
  <button>Cancel</button>
  <button>Delete</button>
</div>
```

**Live Regions**:
```html
<!-- Polite: Wait for pause (form validation) -->
<div aria-live="polite" aria-atomic="true">
  Email must be a valid format.
</div>

<!-- Assertive: Interrupt immediately (errors) -->
<div aria-live="assertive" role="alert">
  Failed to save changes. Please try again.
</div>
```

### Testing with Screen Readers

**Primary Targets**:
- **NVDA** (Windows, free)
- **JAWS** (Windows, paid, most popular)
- **VoiceOver** (macOS/iOS, built-in)
- **TalkBack** (Android, built-in)

**Test Checklist**:
- [ ] All content accessible via screen reader alone
- [ ] Navigation clear and logical
- [ ] Interactive elements announce state (expanded, selected)
- [ ] Form errors read aloud
- [ ] Dynamic content changes announced
- [ ] No "click here" or "read more" without context

---

## Form Accessibility

### Labels

**Requirement**: Every input MUST have an associated label.

**Explicit Labels** (preferred):
```html
<label for="email">Email Address</label>
<input type="email" id="email" name="email" required>
```

**Implicit Labels** (avoid):
```html
<label>
  Email Address
  <input type="email" name="email" required>
</label>
```

**aria-label** (only if visual label missing):
```html
<input type="search" aria-label="Search projects" placeholder="Search...">
```

### Validation

**Error Announcements**:
```html
<label for="password">Password</label>
<input
  type="password"
  id="password"
  aria-invalid="true"
  aria-describedby="password-error">
<span id="password-error" role="alert">
  Password must be at least 8 characters.
</span>
```

**Success Announcements**:
```html
<div aria-live="polite" role="status">
  Form submitted successfully!
</div>
```

### Required Fields

**Visual Indicators**:
- Asterisk (*) in label
- "(required)" text
- Color NOT sole indicator

**ARIA**:
```html
<label for="name">Name <span aria-label="required">*</span></label>
<input type="text" id="name" required aria-required="true">
```

---

## Images & Media

### Alt Text Guidelines

**Informative Images**:
```html
<img src="chart.png" alt="Bar chart showing 45% increase in sales from Q1 to Q2">
```

**Decorative Images**:
```html
<img src="decorative-border.png" alt="" role="presentation">
```

**Functional Images** (buttons, links):
```html
<button>
  <img src="trash-icon.svg" alt="Delete item">
</button>
```

**Complex Images** (charts, diagrams):
```html
<figure>
  <img src="complex-chart.png" alt="Revenue by quarter">
  <figcaption>
    Detailed description: Q1: $45k, Q2: $65k, Q3: $70k, Q4: $90k.
    Shows steady 20-30% quarterly growth throughout 2024.
  </figcaption>
</figure>
```

### Video & Audio

{{#if WCAG_AA}}
**WCAG AA Requirements**:
- Pre-recorded audio: Captions required
- Pre-recorded video: Captions OR audio description
- Live video: Captions required (best effort)
{{/if}}

{{#if WCAG_AAA}}
**WCAG AAA Requirements**:
- Pre-recorded audio: Captions + transcript
- Pre-recorded video: Captions + audio description + sign language
- Live video: Captions required
{{/if}}

**Captions**:
- Accurate transcription (≥99% accuracy)
- Speaker identification
- Sound effects described ("[door slams]")
- Positioned to not obscure important content

---

## Quality Assurance

### Accessibility Checklist

**Every Component MUST**:
- [ ] Meet WCAG {{WCAG_LEVEL}} contrast ratios
- [ ] Work with keyboard only (no mouse)
- [ ] Have visible focus indicators
- [ ] Work with screen reader (test with NVDA/VoiceOver)
- [ ] Respect prefers-reduced-motion
- [ ] Have proper ARIA labels (if not semantic HTML)
- [ ] Pass automated axe/Pa11y scan (0 critical violations)

**Every Form MUST**:
- [ ] All inputs have labels
- [ ] Required fields marked visually AND semantically
- [ ] Errors announced to screen readers (aria-live)
- [ ] Validation triggered on blur (not on keystroke)
- [ ] Submit button clearly labeled

**Every Page MUST**:
- [ ] H1 heading (one per page)
- [ ] Proper heading hierarchy (no skips)
- [ ] Landmarks (header, nav, main, footer)
- [ ] Skip link (if navigation > 3 links)
- [ ] Page title describes content

### Testing Strategy

**Automated** (60% coverage):
- CI pipeline: `pa11y-ci` on every PR
- Pre-commit hook: `axe-core` on modified files
- Lighthouse accessibility score ≥95

**Manual** (40% coverage):
- Screen reader testing (NVDA, VoiceOver)
- Keyboard-only navigation
- Color-blind simulation (browser DevTools)
- Real user testing (if possible)

---

## References

- **WCAG 2.1 Guidelines**: https://www.w3.org/WAI/WCAG21/quickref/
- **ARIA Authoring Practices**: https://www.w3.org/WAI/ARIA/apg/
- **WebAIM Contrast Checker**: https://webaim.org/resources/contrastchecker/
- **Design Tokens**: `design/systems/tokens.css`
- **Brand Guidelines**: `docs/design/brand-guidelines.md`

---

**Document Owner**: {{DOCUMENT_OWNER}}
**Last Review**: {{LAST_REVIEW_DATE}}
**Next Review**: {{NEXT_REVIEW_DATE}}
