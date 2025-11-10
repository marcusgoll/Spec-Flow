# Report Generation

**Purpose**: Generate optimization-report.md and code-review-report.md.

---

## optimization-report.md Format

```markdown
# Optimization Report

**Feature**: User Authentication
**Date**: 2025-11-10
**Status**: ✅ Passed

## Performance Results

### API Performance
- POST /api/auth/login: p50=120ms ✅, p95=280ms ✅
- GET /api/auth/me: p50=45ms ✅, p95=95ms ✅

### Page Load Performance
- Login page: LCP=1.2s ✅, TTI=2.1s ✅

## Security Results
- npm audit: 0 vulnerabilities ✅
- Code review: No SQL injection, XSS prevented ✅

## Accessibility Results (WCAG 2.1 AA)
- Lighthouse score: 96/100 ✅
- axe-core: 0 critical issues ✅
- Keyboard navigation: ✅ Passed

## Test Coverage
- Statements: 87% ✅
- Branches: 82% ✅
- Functions: 94% ✅

## Blocking Issues
None

## Recommendations
- Add rate limiting to login endpoint (future improvement)
```

---

## code-review-report.md Format

```markdown
# Code Review Report

**Feature**: User Authentication
**Reviewer**: Claude Code
**Date**: 2025-11-10

## Critical Issues (Blocking)
None

## High Priority
None

## Medium Priority
1. **Code Duplication** - UserValidator has similar logic in 2 files
   - Files: src/validators/user.ts, src/services/auth.ts
   - Recommendation: Extract to shared utility

## Low Priority
1. **Magic Number** - JWT expiration hardcoded as 3600
   - File: src/services/auth.ts:42
   - Recommendation: Move to config file

## Summary
- Critical: 0
- High: 0
- Medium: 1
- Low: 1

Overall: ✅ Ready for deployment
```

**See [../reference.md](../reference.md#reports) for complete templates**
