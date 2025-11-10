# Accessibility Audit

**Purpose**: Validate WCAG 2.1 AA compliance for UI features.

**When to run**: Only if HAS_UI=true (feature has frontend components)

---

## Automated Testing

**Using Lighthouse CI**:
```bash
lhci autorun --url=http://localhost:3000
# Check: Accessibility score ≥90
```

**Using axe-core**:
```bash
npm install -D @axe-core/cli
axe http://localhost:3000 --tags wcag2a,wcag2aa
```

---

## WCAG 2.1 AA Requirements

**Level A (Must have)**:
- [ ] Text alternatives for images (alt text)
- [ ] Keyboard navigation (no mouse required)
- [ ] Color contrast ≥4.5:1 (normal text)
- [ ] No seizure-inducing flashing

**Level AA (Must have)**:
- [ ] Color contrast ≥4.5:1 (normal text), ≥3:1 (large text)
- [ ] Resize text up to 200% without loss of functionality
- [ ] Focus indicators visible
- [ ] Error identification and suggestions

---

## Manual Checks

**Keyboard Navigation**:
```
1. Tab through all interactive elements
2. Verify focus visible
3. Verify logical tab order
4. Test Escape/Enter keys
```

**Screen Reader** (NVDA/JAWS/VoiceOver):
```
1. Navigate page structure (headings, landmarks)
2. Test form inputs (labels read correctly)
3. Test error messages (announced)
4. Test dynamic content (live regions)
```

---

## Results Format

```markdown
## Accessibility Results

### Automated Testing
- Lighthouse score: 94/100 ✅
- axe-core: 3 issues found
  - Critical: 0 ✅
  - Serious: 1 ❌ (color contrast on button)
  - Moderate: 2 (missing ARIA labels)

### Manual Testing
- Keyboard navigation: ✅ Passed
- Screen reader (NVDA): ⚠️ Form error not announced
```

**See [../reference.md](../reference.md#accessibility) for complete WCAG checklist**
