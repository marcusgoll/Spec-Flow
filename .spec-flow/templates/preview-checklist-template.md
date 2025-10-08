# Manual Testing Checklist

**Feature**: [Feature Name]
**Tester**: [Your Name]
**Date**: [YYYY-MM-DD]

## Development Server URLs

- **Marketing**: http://localhost:3000
- **App**: http://localhost:3001
- **API**: http://localhost:8000/docs

---

## Functionality Testing

### Core Features
- [ ] Feature works as expected
- [ ] All buttons/links functional
- [ ] Forms submit successfully
- [ ] Data displays correctly

### User Flows
- [ ] Happy path works end-to-end
- [ ] Alternative flows work
- [ ] User can navigate back/forward

---

## Visual & UX Testing

### Layout & Design
- [ ] Layout matches mockups/visuals
- [ ] Spacing and alignment correct
- [ ] Typography consistent
- [ ] Colors match design system

### Responsive Design
- [ ] Desktop (1920x1080)
- [ ] Laptop (1366x768)
- [ ] Tablet (768x1024)
- [ ] Mobile (375x667)

### Interactions
- [ ] Hover states work
- [ ] Focus states visible (keyboard navigation)
- [ ] Animations smooth
- [ ] Loading states display

---

## Error & Edge Cases

### Error Handling
- [ ] Form validation errors display
- [ ] API errors display user-friendly messages
- [ ] Network failure handled gracefully
- [ ] Timeout handling works

### Edge Cases
- [ ] Empty states display correctly
- [ ] Long content doesn't break layout
- [ ] Special characters handled
- [ ] Boundary values (min/max) work

---

## Accessibility

### Keyboard Navigation
- [ ] Tab order logical
- [ ] All interactive elements reachable
- [ ] Escape key closes modals/dialogs
- [ ] Enter/Space activate buttons

### Screen Reader
- [ ] Alt text on images
- [ ] ARIA labels where needed
- [ ] Headings hierarchical (h1 → h2 → h3)
- [ ] Form fields labeled

### Color & Contrast
- [ ] Sufficient contrast (WCAG AA)
- [ ] Color not sole indicator
- [ ] Focus indicators visible

---

## Cross-Browser (Optional)

- [ ] Chrome/Edge
- [ ] Firefox
- [ ] Safari

---

## Issues Found

*List any issues discovered during testing:*

1.
2.
3.

---

## Sign-off

- [ ] All critical tests passed
- [ ] No blocking issues found
- [ ] Ready for `/phase-1-ship` (staging deployment)

**Tester Signature**: __________________
**Date**: __________________

---

*This checklist was generated from template because no testing checklist was found in spec.md*
