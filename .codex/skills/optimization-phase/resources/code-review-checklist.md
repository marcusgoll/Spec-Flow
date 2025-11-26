# Code Review Checklist

**Purpose**: Pre-commit validation checklist.

---

## Checklist

### Functionality
- [ ] All requirements from spec.md implemented
- [ ] Edge cases handled
- [ ] Error handling present

### Testing
- [ ] Test coverage ≥80%
- [ ] All tests passing
- [ ] Integration tests included

### Performance
- [ ] API p50 <200ms, p95 <500ms
- [ ] Page load <2s (if UI)
- [ ] No N+1 queries

### Security
- [ ] No SQL injection vulnerabilities
- [ ] XSS prevention in place
- [ ] Authentication/authorization checked
- [ ] npm audit clean

### Accessibility (if UI)
- [ ] WCAG 2.1 AA compliant
- [ ] Keyboard navigation works
- [ ] Screen reader compatible

### Code Quality
- [ ] No DRY violations (<3 duplicates)
- [ ] Functions <50 lines
- [ ] No magic numbers
- [ ] Clear variable names

### Documentation
- [ ] JSDoc/docstrings present
- [ ] README updated (if needed)
- [ ] API documentation generated

**See [../reference.md](../reference.md#checklist) for detailed items**
