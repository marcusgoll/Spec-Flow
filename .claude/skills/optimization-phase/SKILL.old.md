---
name: optimization-phase
description: "Standard Operating Procedure for /optimize phase. Covers performance benchmarking, accessibility audit, security review, and code quality checks."
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Optimization Phase: Standard Operating Procedure

> **Training Guide**: Step-by-step procedures for executing the `/optimize` command to ensure production readiness.

**Supporting references**:
- [reference.md](reference.md) - Performance benchmarks, accessibility checklist, security review guidelines
- [examples.md](examples.md) - Good optimizations (measurable improvements) vs premature optimization

---

## Phase Overview

**Purpose**: Validate feature meets performance, accessibility, security, and code quality standards before deployment.

**Inputs**:
- Implemented feature (from /implement phase)
- Test suite (unit + integration + E2E)
- spec.md with success criteria

**Outputs**:
- `specs/NNN-slug/optimization-report.md` - Performance, accessibility, security audit results
- `specs/NNN-slug/code-review-report.md` - Code quality review findings
- Updated `workflow-state.yaml`

**Expected duration**: 1-2 hours

---

## Prerequisites

**Environment checks**:
- [ ] Implementation phase completed
- [ ] All tests passing
- [ ] Feature works end-to-end
- [ ] Development/staging environment available for testing

**Knowledge requirements**:
- Performance benchmarking tools (Lighthouse, profilers)
- Accessibility standards (WCAG 2.1 AA)
- Security best practices (OWASP Top 10)
- Code quality metrics

---

## Execution Steps

### Step 1: Performance Benchmarking

**Actions**:
1. **Backend performance** (if applicable):
   ```bash
   # API endpoint response times
   curl -w "%{time_total}\n" -o /dev/null -s http://localhost:3000/api/endpoint
   # Target: <500ms (95th percentile)

   # Database query performance
   # Run EXPLAIN ANALYZE on slow queries
   # Target: <100ms per query
   ```

2. **Frontend performance** (if HAS_UI=true):
   ```bash
   # Lighthouse performance audit
   npx lighthouse http://localhost:3000 --only-categories=performance --output=json
   # Target: Score ≥85

   # Core Web Vitals
   # - FCP (First Contentful Paint): <1.5s
   # - LCP (Largest Contentful Paint): <2.5s
   # - CLS (Cumulative Layout Shift): <0.1
   # - FID (First Input Delay): <100ms
   ```

3. **Document results**:
   ```markdown
   ## Performance Results

   **Backend**:
   - API response time: 287ms (95th percentile) ✓ Target: <500ms
   - Database queries: 45ms average ✓ Target: <100ms
   - No N+1 query problems ✓

   **Frontend** (if applicable):
   - Lighthouse Performance: 92/100 ✓ Target: ≥85
   - FCP: 1.2s ✓ Target: <1.5s
   - LCP: 2.1s ✓ Target: <2.5s
   - CLS: 0.05 ✓ Target: <0.1
   ```

**Quality check**: All performance targets met, documented in optimization-report.md.

---

### Step 2: Accessibility Audit (if HAS_UI=true)

**Actions**:
1. **Automated accessibility scan**:
   ```bash
   # Lighthouse accessibility audit
   npx lighthouse http://localhost:3000 --only-categories=accessibility --output=json
   # Target: Score ≥95

   # axe-core scan
   npm run test:a11y
   # Target: 0 violations
   ```

2. **Manual accessibility checks**:
   - [ ] Keyboard navigation works (Tab, Enter, Escape)
   - [ ] Focus indicators visible
   - [ ] Screen reader compatible (test with NVDA/VoiceOver)
   - [ ] Color contrast ≥4.5:1 for normal text, ≥3:1 for large text
   - [ ] ARIA labels on interactive elements
   - [ ] Alt text on images
   - [ ] Form fields labeled properly

3. **Document results**:
   ```markdown
   ## Accessibility Results

   **Automated scans**:
   - Lighthouse Accessibility: 98/100 ✓ Target: ≥95
   - axe-core violations: 0 ✓ Target: 0

   **Manual checks**:
   - Keyboard navigation: ✓ All interactive elements accessible
   - Focus indicators: ✓ Visible on all focusable elements
   - Screen reader: ✓ Tested with NVDA, all content announced correctly
   - Color contrast: ✓ All text meets WCAG AA standards (≥4.5:1)
   - ARIA labels: ✓ All buttons and inputs properly labeled
   ```

**Quality check**: Lighthouse ≥95, all manual checks passed, documented in optimization-report.md.

---

### Step 3: Security Review

**Actions**:
1. **Authentication/Authorization**:
   - [ ] Authentication required for protected endpoints
   - [ ] Authorization checks user permissions
   - [ ] Session management secure (HTTP-only cookies, secure flag)
   - [ ] JWT tokens properly validated (if used)

2. **Input Validation**:
   - [ ] All user inputs validated (type, format, range)
   - [ ] SQL injection prevented (parameterized queries)
   - [ ] XSS prevented (input sanitization, output encoding)
   - [ ] CSRF protection implemented (if applicable)

3. **Data Protection**:
   - [ ] Sensitive data encrypted at rest (if applicable)
   - [ ] TLS/HTTPS used for data in transit
   - [ ] No secrets in code (use environment variables)
   - [ ] No PII logged

4. **Security headers** (if HAS_UI=true):
   ```bash
   # Check security headers
   curl -I http://localhost:3000

   # Expected headers:
   # - Content-Security-Policy
   # - X-Frame-Options: DENY
   # - X-Content-Type-Options: nosniff
   # - Strict-Transport-Security
   ```

5. **Document results**:
   ```markdown
   ## Security Results

   **Authentication/Authorization**: ✓ All protected endpoints require authentication
   **Input Validation**: ✓ All inputs validated, SQL injection prevented
   **Data Protection**: ✓ TLS enabled, no secrets in code
   **Security Headers**: ✓ CSP, X-Frame-Options, HSTS configured

   **Vulnerabilities found**: None
   ```

**Quality check**: No security vulnerabilities, documented in optimization-report.md.

---

### Step 4: Code Quality Review

**Actions**:
1. **Code duplication check**:
   ```bash
   # Check for duplicate code
   npx jscpd src/
   # Target: <5% duplication

   # Or manual review of plan.md reuse strategy
   ```

2. **Code coverage**:
   ```bash
   # Backend coverage
   pytest --cov=api --cov-report=term-missing
   # Target: ≥80% for business logic

   # Frontend coverage
   npm test -- --coverage
   # Target: ≥80% for business logic
   ```

3. **Linting and formatting**:
   ```bash
   # Run linters
   npm run lint
   pylint api/
   # Target: 0 errors

   # Check formatting
   npm run format:check
   black --check api/
   # Target: All files formatted
   ```

4. **Code complexity**:
   - [ ] No functions >50 lines
   - [ ] No deeply nested conditionals (>3 levels)
   - [ ] No God objects (classes with >10 methods)

5. **Documentation**:
   - [ ] Public APIs have docstrings
   - [ ] Complex logic has comments
   - [ ] README updated (if needed)

6. **Document results**:
   ```markdown
   ## Code Quality Results

   **Code Duplication**: 2.3% ✓ Target: <5%
   **Test Coverage**:
   - Backend: 87% ✓ Target: ≥80%
   - Frontend: 82% ✓ Target: ≥80%
   **Linting**: 0 errors ✓
   **Formatting**: All files formatted ✓
   **Complexity**: All functions <50 lines ✓
   **Documentation**: All public APIs documented ✓
   ```

**Quality check**: Code quality meets standards, documented in code-review-report.md.

---

### Step 5: Cross-Reference Success Criteria

**Actions**:
1. Read success criteria from spec.md
2. For each criterion, verify it's met with evidence:
   ```markdown
   ## Success Criteria Validation

   ### From spec.md

   1. "User can complete registration in <3 minutes"
      - **Measured**: Average 2.1 minutes (PostHog funnel) ✓
      - **Evidence**: e2e/registration.spec.ts passes

   2. "API response time <500ms for 95th percentile"
      - **Measured**: 287ms (95th percentile) ✓
      - **Evidence**: Performance benchmark results above

   3. "Lighthouse accessibility score ≥95"
      - **Measured**: 98/100 ✓
      - **Evidence**: Accessibility audit results above

   4. "95% of user searches return results in <1 second"
      - **Measured**: 97% of searches <1s ✓
      - **Evidence**: Search performance logs
   ```

**Quality check**: All success criteria from spec.md are met with evidence.

---

### Step 6: Generate Optimization Report

**Actions**:
1. Render `optimization-report.md` from template with:
   - Performance benchmarks
   - Accessibility audit results
   - Security review findings
   - Code quality metrics
   - Success criteria validation

2. Include recommendations (if any):
   ```markdown
   ## Recommendations

   **Optional optimizations** (can defer to future):
   - Cache dashboard data for 10 minutes (would reduce DB queries by 80%)
   - Add database index on `student_id, lesson_id` (would improve query time from 45ms to 15ms)
   - Implement image lazy loading (would improve LCP by ~200ms)

   **Required fixes** (blocking deployment):
   - None
   ```

**Quality check**: optimization-report.md is complete and comprehensive.

---

### Step 7: Code Review Checklist

**Actions**:
Run through comprehensive code review checklist:

**Architecture**:
- [ ] Follows existing patterns
- [ ] Separation of concerns (data/business/presentation layers)
- [ ] No tight coupling
- [ ] Reuses existing utilities/components

**Code Quality**:
- [ ] No code duplication (<5%)
- [ ] Type hints on all functions
- [ ] Docstrings on public APIs
- [ ] Meaningful variable names
- [ ] No magic numbers (use constants)

**Testing**:
- [ ] Test coverage ≥80% for business logic
- [ ] All tests pass
- [ ] TDD followed (tests before code)
- [ ] Tests are maintainable (no test smells)

**Performance**:
- [ ] No N+1 query problems
- [ ] Database indexes on foreign keys
- [ ] Pagination for large datasets
- [ ] No blocking operations on main thread (if UI)

**Security**:
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities
- [ ] Authentication/authorization implemented
- [ ] No secrets in code

**Accessibility** (if HAS_UI):
- [ ] Lighthouse ≥95
- [ ] Keyboard navigation works
- [ ] ARIA labels present
- [ ] Color contrast meets WCAG AA

**Quality check**: All checklist items satisfied or documented exceptions.

---

### Step 8: Final Validation

**Actions**:
1. Run full test suite one last time:
   ```bash
   # Backend tests
   pytest

   # Frontend tests
   npm test

   # E2E tests
   npx playwright test
   ```

2. Verify all quality gates passed:
   - [ ] Performance targets met
   - [ ] Accessibility score ≥95 (if HAS_UI)
   - [ ] No security vulnerabilities
   - [ ] Code quality standards met
   - [ ] All success criteria validated
   - [ ] All tests passing

3. Update workflow-state.yaml:
   ```yaml
   currentPhase: optimization
   status: completed
   qualityGates:
     performance: passed
     accessibility: passed
     security: passed
     codeQuality: passed
   ```

**Quality check**: All quality gates passed, ready for preview/deployment.

---

### Step 9: Commit Optimization

**Actions**:
```bash
git add specs/NNN-slug/optimization-report.md specs/NNN-slug/code-review-report.md
git commit -m "docs: complete optimization for <feature-name>

Performance:
- API response: 287ms ✓ Target: <500ms
- Lighthouse: 92/100 ✓ Target: ≥85
- FCP: 1.2s ✓ Target: <1.5s

Accessibility:
- Lighthouse: 98/100 ✓ Target: ≥95
- Manual checks: All passed ✓

Security:
- No vulnerabilities found ✓
- All endpoints protected ✓

Code Quality:
- Test coverage: 87% ✓ Target: ≥80%
- Code duplication: 2.3% ✓ Target: <5%
- Linting: 0 errors ✓

All quality gates passed - ready for deployment
"
```

**Quality check**: Optimization committed, ready for next phase (preview or deployment).

---

## Common Mistakes to Avoid

### 🚫 Performance Target Missed

**Impact**: Poor UX, user churn, production issues

**Scenario**:
```
API response time: 1.2s (target: <500ms)
Lighthouse Performance: 45/100 (target: ≥85)
Result: Feature deployed, users complain about slowness
```

**Prevention**:
1. Run benchmarks before marking optimization complete
2. Profile slow functions/queries
3. Add database indexes where needed
4. Implement caching for expensive operations
5. Use pagination for large datasets

**Tools**:
```bash
# Profile slow API endpoints
time curl http://localhost:3000/api/slow-endpoint

# Profile database queries
EXPLAIN ANALYZE SELECT ...

# Profile frontend performance
npx lighthouse http://localhost:3000 --view
```

---

### 🚫 Accessibility Failures

**Impact**: Excludes users with disabilities, legal/compliance risk

**Scenario**:
```
Lighthouse Accessibility: 72/100 (target: ≥95)
Issues:
- No ARIA labels on buttons
- Color contrast too low (2.8:1, need 4.5:1)
- Keyboard navigation broken
```

**Prevention**:
1. Run Lighthouse accessibility audit
2. Test keyboard navigation manually
3. Use automated tools (axe-core)
4. Test with screen reader (NVDA/VoiceOver)
5. Check color contrast with tools

---

### 🚫 Security Vulnerabilities

**Impact**: Data breaches, legal liability, reputation damage

**Scenario**:
```
SQL injection vulnerability in search endpoint
XSS vulnerability in user profile
No authentication on admin endpoints
```

**Prevention**:
1. Use parameterized queries (never string concatenation)
2. Sanitize all user inputs
3. Require authentication on all protected endpoints
4. Use security headers (CSP, X-Frame-Options)
5. No secrets in code (use environment variables)

---

### 🚫 Low Test Coverage

**Impact**: Undetected bugs, regression risk

**Scenario**:
```
Test coverage: 45% (target: ≥80%)
Critical business logic untested
```

**Prevention**:
- Enforce TDD (tests before code)
- Focus coverage on business logic (not UI glue code)
- Run coverage reports regularly
- Block merge if coverage drops

---

### 🚫 Premature Optimization

**Impact**: Wasted time, increased complexity

**Scenario**:
```
Spent 2 days optimizing function that runs once per day
Added complex caching layer for infrequently accessed data
```

**Prevention**:
- Measure first, optimize second
- Focus on hot paths (frequently executed code)
- Profile to find actual bottlenecks
- Optimize for current bottlenecks, not hypothetical ones

---

## Best Practices

### ✅ Optimization Checklist

**Use systematic approach**:
```markdown
## Optimization Checklist

**Performance**:
- [ ] API <500ms (95th percentile)
- [ ] Frontend FCP <1.5s
- [ ] Database queries optimized
- [ ] No N+1 queries

**Accessibility** (if HAS_UI):
- [ ] Lighthouse ≥95
- [ ] Keyboard nav works
- [ ] Screen reader compatible
- [ ] Color contrast meets WCAG AA

**Security**:
- [ ] No SQL injection
- [ ] No XSS vulnerabilities
- [ ] Authentication/authorization
- [ ] No secrets in code

**Code Quality**:
- [ ] Test coverage ≥80%
- [ ] Code duplication <5%
- [ ] Linting passes
- [ ] All tests pass
```

**Result**: Systematic validation, nothing missed

---

### ✅ Evidence-Based Validation

**For each success criterion, provide evidence**:
```markdown
## Success Criteria Validation

1. "API response <500ms"
   - Measured: 287ms ✓
   - Tool: curl -w "%{time_total}"
   - Sample size: 100 requests

2. "Lighthouse ≥95"
   - Measured: 98/100 ✓
   - Tool: npx lighthouse
   - URL: http://localhost:3000
```

**Result**: Objective proof all criteria met

---

### ✅ Actionable Recommendations

**Separate required fixes from nice-to-haves**:
```markdown
## Required Fixes (Blocking):
- None

## Optional Improvements (Future):
- Cache dashboard data (80% query reduction)
- Add lazy loading (200ms LCP improvement)
```

**Result**: Clear next steps, deployment not blocked by nice-to-haves

---

## Phase Checklist

**Pre-phase checks**:
- [ ] Implementation complete
- [ ] All tests passing
- [ ] Feature works end-to-end

**During phase**:
- [ ] Performance benchmarks run
- [ ] Accessibility audit complete (if HAS_UI)
- [ ] Security review complete
- [ ] Code quality checks complete
- [ ] Success criteria validated

**Post-phase validation**:
- [ ] optimization-report.md created
- [ ] code-review-report.md created
- [ ] All quality gates passed
- [ ] Reports committed
- [ ] workflow-state.yaml updated

---

## Quality Standards

**Optimization quality targets**:
- Performance: API <500ms, FCP <1.5s, Lighthouse ≥85
- Accessibility: Lighthouse ≥95 (if HAS_UI)
- Security: No vulnerabilities
- Code quality: Coverage ≥80%, duplication <5%

**What makes good optimization**:
- Measurable improvements (with before/after metrics)
- All targets met with evidence
- Systematic approach (checklist-driven)
- Actionable recommendations (if any)
- Focus on actual bottlenecks (not premature optimization)

**What makes bad optimization**:
- Missing benchmarks (no measurements)
- Targets not met but phase marked complete
- Premature optimization (optimizing non-bottlenecks)
- No evidence for success criteria
- Accessibility/security skipped

---

## Completion Criteria

**Phase is complete when**:
- [ ] All benchmarks run
- [ ] All quality gates passed
- [ ] Success criteria validated
- [ ] Reports generated and committed
- [ ] workflow-state.yaml shows `currentPhase: optimization` and `status: completed`

**Ready to proceed to next phase** (`/preview`):
- [ ] Performance targets met
- [ ] Accessibility score ≥95 (if HAS_UI)
- [ ] No security vulnerabilities
- [ ] Code quality standards met

---

## Troubleshooting

**Issue**: Performance targets not met
**Solution**: Profile code, add indexes, implement caching, use pagination, optimize queries

**Issue**: Accessibility score <95
**Solution**: Run axe-core for specific issues, add ARIA labels, fix color contrast, test keyboard nav

**Issue**: Security vulnerabilities found
**Solution**: Use parameterized queries, sanitize inputs, add authentication, enable security headers

**Issue**: Test coverage <80%
**Solution**: Identify untested code with coverage report, add missing tests, focus on business logic

---

_This SOP guides the optimization phase. Refer to reference.md for benchmarking details and examples.md for optimization patterns._
