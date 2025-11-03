# Don't Make Me Think Checklist

**Feature**: [Feature Name]
**Phase**: [Variations / Functional / Polish]
**Evaluator**: [Name]
**Date**: [Date]

---

## Overview

This checklist ensures your interface is intuitive, self-explanatory, and requires minimal cognitive effort from users. Based on Steve Krug's "Don't Make Me Think" principles, each item should be answered "Yes" for optimal usability.

**Scoring**:
- **Critical (🔴)**: Must be "Yes" - blocks progression if "No"
- **Important (🟡)**: Should be "Yes" - address before finalizing
- **Nice-to-have (🟢)**: Ideally "Yes" - optimize if time permits

**Target Score**: 100% Critical, 90%+ Important, 80%+ Nice-to-have

---

## 1. Visual Clarity

### Is it obvious what things are?

**🔴 Critical**:
- [ ] **Clickable elements look clickable** (buttons have depth/color, links are underlined or colored)
- [ ] **Non-clickable elements don't look clickable** (no hover effects on static text, no button-like styling on labels)
- [ ] **Primary action is visually dominant** (largest button, highest contrast, most prominent position)
- [ ] **Destructive actions are visually distinct** (red color, icon, confirmation required)
- [ ] **Disabled elements look disabled** (gray-400 color, reduced opacity, no hover effects)

**🟡 Important**:
- [ ] **Headings look like headings** (larger size, bolder weight, clear hierarchy)
- [ ] **Body text is clearly distinguishable** (gray-900 for primary, gray-600 for secondary)
- [ ] **Form fields are obviously interactive** (border, shadow on z-1, clear label association)
- [ ] **Images have clear purpose** (not decorative noise, support content)
- [ ] **Icons reinforce meaning** (not the sole conveyor of information, paired with text)

**🟢 Nice-to-have**:
- [ ] **Hover states provide clear affordance** (elevation increase, color change, cursor change)
- [ ] **Focus states are highly visible** (ring-2 ring-blue-500, clear indicator)
- [ ] **Loading states are informative** (skeleton screens show structure, spinners indicate progress)

**Phase-Specific**:
- **Variations**: Check each variant (3-5) for visual clarity consistency
- **Functional**: Verify all interactive elements have clear affordance
- **Polish**: Ensure brand application didn't reduce visual clarity

---

## 2. Navigation & Orientation

### Can users find what they need and know where they are?

**🔴 Critical**:
- [ ] **Users can answer "Where am I?"** (page title, breadcrumbs, or active nav indicator)
- [ ] **Users can answer "How did I get here?"** (clear navigation path, back button works)
- [ ] **Users can answer "Where can I go?"** (navigation is visible, links are clear)
- [ ] **Home link is in expected location** (top-left corner, logo is clickable)
- [ ] **Navigation doesn't disappear or move** (persistent across pages, sticky if needed)

**🟡 Important**:
- [ ] **Search is easy to find** (top-right corner, visible on all pages)
- [ ] **Navigation labels are clear** (no jargon, describe destination, not clever)
- [ ] **Active page is highlighted in nav** (different color, bold, or underline)
- [ ] **Breadcrumbs show clear path** (if deep hierarchy, show "Home > Category > Page")
- [ ] **Footer contains expected links** (About, Contact, Privacy, Terms)

**🟢 Nice-to-have**:
- [ ] **"Skip to content" link for keyboard users** (hidden until focused)
- [ ] **Mega menu is scannable** (if many nav items, grouped logically)
- [ ] **Recently visited pages are accessible** (browser history, or app history)

**Phase-Specific**:
- **Variations**: Test navigation visibility in each variant
- **Functional**: Verify navigation interactions (clicks, hovers, focus)
- **Polish**: Ensure navigation hierarchy is clear with final typography

---

## 3. Content Scannability

### Can users quickly understand what they're reading?

**🔴 Critical**:
- [ ] **Most important content is top-left** (F-pattern: users scan top-horizontal, then left-vertical)
- [ ] **Headings are descriptive** (tell users what the section is about, not vague)
- [ ] **Paragraphs are short** (3-4 sentences max, break up long text)
- [ ] **Key information stands out** (bold, color, larger size, or in callout box)
- [ ] **No walls of text** (every screen has visual breaks: headings, bullets, images)

**🟡 Important**:
- [ ] **Bullet points are used for lists** (easier to scan than paragraphs)
- [ ] **Text hierarchy is clear** (2:1 heading ratios, visual distinction between levels)
- [ ] **Links are descriptive** ("Learn about pricing" not "Click here")
- [ ] **Important words are at start of lines** (front-load information, don't bury key details)
- [ ] **Unnecessary words are eliminated** ("Get started" not "Click here to get started now")

**🟢 Nice-to-have**:
- [ ] **Callouts highlight key info** (cards, boxes, or colored backgrounds for important notes)
- [ ] **Images support text** (diagrams, screenshots, icons reinforce content)
- [ ] **White space improves readability** (generous margins, line height, section spacing)

**Phase-Specific**:
- **Variations**: Test different content layouts (tight vs. airy, linear vs. grid)
- **Functional**: Verify F-pattern with real content (not Lorem Ipsum)
- **Polish**: Ensure hierarchy ratios are 2:1 (measure actual rendered sizes)

---

## 4. Interactions & Affordance

### Are actions obvious and easy to perform?

**🔴 Critical**:
- [ ] **Users know what will happen before they click** (button labels are verbs: "Save", "Delete", "Cancel")
- [ ] **Primary action is obvious** (one clear CTA per screen, visually dominant)
- [ ] **Destructive actions require confirmation** ("Delete account" has confirmation dialog)
- [ ] **Forms show what's required** (asterisk or "Required" label, clear error messages)
- [ ] **Submit buttons are enabled only when valid** (or provide clear error on submit)

**🟡 Important**:
- [ ] **Related actions are grouped** (Save + Cancel together, not separated)
- [ ] **Secondary actions are less prominent** (ghost button, smaller size, or text link)
- [ ] **Undo is available for destructive actions** (or confirmation with preview of consequences)
- [ ] **Multi-step forms show progress** (stepper, progress bar, or "Step 2 of 5")
- [ ] **Long processes show feedback** (loading spinner, progress percentage, estimated time)

**🟢 Nice-to-have**:
- [ ] **Keyboard shortcuts are provided** (and documented, like "Ctrl+S to save")
- [ ] **Drag-and-drop is intuitive** (visual feedback, drop zones are clear)
- [ ] **Gestures work as expected** (swipe, pinch-to-zoom on mobile)

**Phase-Specific**:
- **Variations**: Test different interaction patterns (e.g., inline edit vs. modal)
- **Functional**: Verify all interactions work (hover, focus, click, keyboard)
- **Polish**: Ensure transitions are smooth (200ms duration, no jarring changes)

---

## 5. Feedback & Communication

### Do users know what's happening?

**🔴 Critical**:
- [ ] **Success messages are shown** (toast, banner, or inline message after actions)
- [ ] **Error messages are shown immediately** (inline below field, not hidden)
- [ ] **Loading states are shown** (spinner, skeleton, or progress bar during waits)
- [ ] **System status is visible** ("Saving...", "Saved!", "Error saving")
- [ ] **Errors explain what went wrong** ("Email is already registered" not "Error 409")

**🟡 Important**:
- [ ] **Errors explain how to fix** ("Use at least 8 characters" not "Invalid password")
- [ ] **Success messages are dismissible** (auto-dismiss after 5s, or manual close)
- [ ] **Error messages are near the error** (inline below field, not at top of page)
- [ ] **Confirmation dialogs are specific** ("Delete 5 items?" not "Are you sure?")
- [ ] **Progress is shown for long operations** (upload percentage, processing steps)

**🟢 Nice-to-have**:
- [ ] **Optimistic updates reduce perceived latency** (show success immediately, revert if fails)
- [ ] **Tooltips provide extra help** (on hover, explain complex features)
- [ ] **Empty states are helpful** ("No items yet. Create your first one!" with CTA)

**Phase-Specific**:
- **Variations**: Test different feedback locations (toast vs. inline vs. modal)
- **Functional**: Verify all feedback is implemented (success, error, loading)
- **Polish**: Ensure feedback uses correct colors (green-600 success, red-600 error)

---

## 6. Cognitive Load

### Is the interface simple and focused?

**🔴 Critical**:
- [ ] **Each page has one primary goal** (not trying to do too much)
- [ ] **Unnecessary elements are removed** (no decorative noise, every element has purpose)
- [ ] **Options are limited** (Hick's Law: fewer choices = faster decisions)
- [ ] **Forms ask only essential questions** (defer optional fields to later)
- [ ] **User isn't required to remember things** (show previous selection, provide defaults)

**🟡 Important**:
- [ ] **Related information is grouped** (use cards, sections, or white space to cluster)
- [ ] **Progressive disclosure hides complexity** (advanced options in "More" or collapse)
- [ ] **Smart defaults are provided** (pre-fill forms with likely values)
- [ ] **Similar pages have consistent layouts** (same positions for navigation, CTAs)
- [ ] **Jargon is avoided** (use plain language, explain technical terms)

**🟢 Nice-to-have**:
- [ ] **Onboarding guides new users** (tooltips, tours, or empty state instructions)
- [ ] **Shortcuts are available for power users** (keyboard shortcuts, bulk actions)
- [ ] **Personalization reduces noise** (show relevant content based on user context)

**Phase-Specific**:
- **Variations**: Test minimal vs. rich layouts (prefer minimal)
- **Functional**: Remove any elements that don't serve primary goal
- **Polish**: Verify final design is focused (not cluttered by brand elements)

---

## 7. Conventions & Patterns

### Does it work like users expect?

**🔴 Critical**:
- [ ] **Logo links to home** (top-left corner, universal expectation)
- [ ] **Forms follow expected order** (name before email, email before password)
- [ ] **Cancel buttons don't save changes** (no surprising side effects)
- [ ] **Confirmation buttons are on the right** ("Cancel" on left, "Confirm" on right)
- [ ] **Links are underlined or colored** (blue-600, or underline on hover)

**🟡 Important**:
- [ ] **Search icon is a magnifying glass** (universally recognized)
- [ ] **Menu icon is three lines** (hamburger icon on mobile)
- [ ] **Close icon is an X** (top-right of modals, universally expected)
- [ ] **Checkboxes for multiple, radio for single** (don't use checkboxes for single-select)
- [ ] **Date pickers use calendar UI** (not text input with manual typing)

**🟢 Nice-to-have**:
- [ ] **Common gestures work** (swipe to delete, pull to refresh on mobile)
- [ ] **Common shortcuts work** (Ctrl+S to save, Escape to close)
- [ ] **Colors follow conventions** (red for danger, green for success, blue for info)

**Phase-Specific**:
- **Variations**: Don't deviate from conventions without strong reason
- **Functional**: Verify all interactions follow expected patterns
- **Polish**: Ensure brand doesn't override conventions (e.g., don't make links green if brand is green)

---

## 8. Error Prevention & Recovery

### Are errors preventable and fixable?

**🔴 Critical**:
- [ ] **Required fields are marked** (asterisk, "Required" label, or disabled submit)
- [ ] **Validation happens early** (inline validation on blur, not only on submit)
- [ ] **Destructive actions require confirmation** ("Delete 50 items?" with checkbox)
- [ ] **Users can undo or cancel** (undo button, cancel button, or back button)
- [ ] **Errors are recoverable** (don't lose user's work, allow retry)

**🟡 Important**:
- [ ] **Forms validate as user types** (show green checkmark when valid, red X when invalid)
- [ ] **Constraints are shown upfront** ("Password must be 8+ characters" before typing)
- [ ] **Destructive actions are hard to trigger** (not next to safe actions, require confirmation)
- [ ] **Auto-save prevents data loss** (save drafts, preserve form state across refreshes)
- [ ] **Users can review before submitting** (preview screen, summary of changes)

**🟢 Nice-to-have**:
- [ ] **Suggestions help fix errors** ("Did you mean john@gmail.com?")
- [ ] **Partial progress is saved** (multi-step forms save each step)
- [ ] **Version history allows rollback** (see previous versions, restore)

**Phase-Specific**:
- **Variations**: Test different validation patterns (inline vs. on-submit)
- **Functional**: Verify all validation is implemented correctly
- **Polish**: Ensure error messages use correct tone (helpful, not accusatory)

---

## 9. Mobile & Responsive

### Does it work on all screen sizes?

**🔴 Critical**:
- [ ] **Touch targets are 44x44px minimum** (WCAG guideline, prevents mis-taps)
- [ ] **Text is readable without zoom** (16px minimum for body text)
- [ ] **Navigation is accessible on mobile** (hamburger menu, or simplified nav)
- [ ] **Forms are usable on mobile** (large inputs, proper input types)
- [ ] **Content fits without horizontal scroll** (responsive layout, no fixed widths)

**🟡 Important**:
- [ ] **Important content is above the fold** (mobile screens are short, prioritize)
- [ ] **Buttons are full-width on mobile** (easier to tap, less precision required)
- [ ] **Menus are finger-friendly** (spacing between items, large tap targets)
- [ ] **Images scale correctly** (responsive images, no pixelation or overflow)
- [ ] **Modal dialogs fit mobile screens** (no awkward scrolling within modals)

**🟢 Nice-to-have**:
- [ ] **Mobile-specific patterns are used** (swipe gestures, pull to refresh)
- [ ] **Desktop shortcuts are replaced** (hover tooltips → tap to reveal)
- [ ] **Landscape orientation works** (not broken when phone rotated)

**Phase-Specific**:
- **Variations**: Test each variant on mobile (320px width)
- **Functional**: Verify responsive breakpoints (320px, 768px, 1024px)
- **Polish**: Ensure mobile typography is readable (may need to scale down)

---

## 10. Accessibility

### Can everyone use it?

**🔴 Critical**:
- [ ] **All text has 7:1 contrast** (WCAG AAA, use contrast checker)
- [ ] **All interactive elements are keyboard accessible** (tab to navigate, enter to activate)
- [ ] **All images have alt text** (meaningful description, not "image")
- [ ] **All form fields have labels** (associated with `htmlFor`, visible on screen)
- [ ] **All icon-only buttons have aria-label** (screen reader announces purpose)

**🟡 Important**:
- [ ] **Focus indicator is visible** (ring-2 ring-blue-500, high contrast)
- [ ] **Color is not the only indicator** (use icons, text, or patterns in addition to color)
- [ ] **Headings are semantic** (h1, h2, h3 in order, not just styled text)
- [ ] **Links are distinguishable** (underlined or colored, not just bold)
- [ ] **Error messages are announced** (aria-live="polite" for screen readers)

**🟢 Nice-to-have**:
- [ ] **Skip links are provided** ("Skip to content" for keyboard users)
- [ ] **ARIA landmarks are used** (role="navigation", role="main", role="search")
- [ ] **Reduced motion is respected** (prefers-reduced-motion disables animations)

**Phase-Specific**:
- **Variations**: Check contrast in each variant (use Lighthouse)
- **Functional**: Verify keyboard navigation works (tab through all elements)
- **Polish**: Run axe-core scan (0 violations required)

---

## Scoring Summary

**Phase**: [Variations / Functional / Polish]

| Category | Critical (Pass/Total) | Important (Pass/Total) | Nice-to-have (Pass/Total) |
|----------|------------------------|-------------------------|----------------------------|
| 1. Visual Clarity | __ / 5 | __ / 5 | __ / 3 |
| 2. Navigation | __ / 5 | __ / 5 | __ / 3 |
| 3. Content | __ / 5 | __ / 5 | __ / 3 |
| 4. Interactions | __ / 5 | __ / 5 | __ / 3 |
| 5. Feedback | __ / 5 | __ / 5 | __ / 3 |
| 6. Cognitive Load | __ / 5 | __ / 5 | __ / 3 |
| 7. Conventions | __ / 5 | __ / 5 | __ / 3 |
| 8. Error Prevention | __ / 5 | __ / 5 | __ / 3 |
| 9. Mobile | __ / 5 | __ / 5 | __ / 3 |
| 10. Accessibility | __ / 5 | __ / 5 | __ / 3 |
| **TOTAL** | **__ / 50** | **__ / 50** | **__ / 30** |

**Critical Pass Rate**: ___% (Target: 100%)
**Important Pass Rate**: ___% (Target: 90%+)
**Nice-to-have Pass Rate**: ___% (Target: 80%+)

---

## Blockers (Critical failures)

List all Critical items that failed:

1. [Item description]
   - **Issue**: [What's wrong]
   - **Fix**: [How to resolve]
   - **Owner**: [Who will fix]
   - **Target**: [When will it be fixed]

---

## Improvement Areas (Important failures)

List all Important items that failed:

1. [Item description]
   - **Issue**: [What's wrong]
   - **Fix**: [How to resolve]
   - **Priority**: [High / Medium / Low]

---

## Future Enhancements (Nice-to-have failures)

List all Nice-to-have items that failed:

1. [Item description]
   - **Enhancement**: [What could be better]
   - **Benefit**: [Why it matters]
   - **Effort**: [Low / Medium / High]

---

## Phase Gate Decision

**Variations → Functional**:
- [ ] ✅ All Critical items pass (100%)
- [ ] ✅ At least 80% of Important items pass
- [ ] ✅ Selected variant is most intuitive (user testing or team consensus)

**Functional → Polish**:
- [ ] ✅ All Critical items pass (100%)
- [ ] ✅ At least 90% of Important items pass
- [ ] ✅ All interactions work correctly
- [ ] ✅ Accessibility audit passes (0 critical violations)

**Polish → Implementation**:
- [ ] ✅ All Critical items pass (100%)
- [ ] ✅ All Important items pass (100%)
- [ ] ✅ At least 80% of Nice-to-have items pass
- [ ] ✅ Design lint passes (0 critical, 0 errors)
- [ ] ✅ Final prototype is approved

**Decision**: [ ] PASS - Proceed to next phase | [ ] FAIL - Address blockers

---

## Tester Notes

**What worked well**:
- [Observation]

**What caused confusion**:
- [Observation]

**Suggestions for improvement**:
- [Suggestion]

**Overall impression**:
[Summary paragraph about intuitiveness, clarity, ease of use]

---

## Sign-off

**Phase**: [Variations / Functional / Polish]
**Status**: [Pass / Fail / Conditional Pass]
**Evaluator**: [Name]
**Date**: [Date]
**Next Action**: [Proceed to [Next Phase] / Fix blockers and re-evaluate]

---

**End of Don't Make Me Think Checklist**

This checklist should be completed at the end of each design phase (Variations, Functional, Polish) to ensure the interface is intuitive before progressing to the next phase or implementation.
