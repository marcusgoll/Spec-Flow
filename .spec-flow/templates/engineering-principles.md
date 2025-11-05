# Engineering Principles

**Version**: 1.0.0
**Last Updated**: [AUTO-GENERATED]
**Project**: [PROJECT_NAME]

> This document defines the core engineering principles that govern all feature development in this project. Every specification, plan, and implementation must align with these principles.

---

## Purpose

The Engineering Principles serve as your team's engineering standards. When in doubt, refer to these principles. When principles conflict with convenience, principles win.

---

## Core Principles

### 1. Specification First

**Principle**: Every feature begins with a written specification that defines requirements, success criteria, and acceptance tests before any code is written.

**Why**: Specifications prevent scope creep, align stakeholders, and create an auditable trail of decisions.

**Implementation**:
- Use `/feature` to create specifications
- Specifications must define: purpose, user stories, acceptance criteria, out-of-scope items
- No implementation work starts until spec is reviewed and approved
- Changes to requirements require spec updates first

**Violations**:
- ❌ Starting implementation without a spec
- ❌ Adding features not in the spec without updating it first
- ❌ Skipping stakeholder review of specifications

---

### 2. Testing Standards

**Principle**: All production code must have automated tests with minimum 80% code coverage.

**Why**: Tests prevent regressions, document behavior, and enable confident refactoring.

**Implementation**:
- Unit tests for business logic (80%+ coverage required)
- Integration tests for API contracts
- E2E tests for critical user flows
- Tests written alongside implementation (not after)
- Use `/tasks` phase to include test tasks in implementation plan

**Violations**:
- ❌ Merging code without tests
- ❌ Skipping tests for "simple" features
- ❌ Writing tests only after implementation is complete

---

### 3. Performance Requirements

**Principle**: Define and enforce performance thresholds for all user-facing features.

**Why**: Performance is a feature, not an optimization task. Users abandon slow experiences.

**Implementation**:
- API responses: <200ms p50, <500ms p95
- Page loads: <2s First Contentful Paint, <3s Largest Contentful Paint
- Database queries: <50ms for reads, <100ms for writes
- Define thresholds in spec, measure in `/optimize` phase
- Use Lighthouse, Web Vitals, or similar tools for validation

**Violations**:
- ❌ Shipping features without performance benchmarks
- ❌ Ignoring performance regressions in code review
- ❌ N+1 queries, unbounded loops, blocking operations

---

### 4. Accessibility (a11y)

**Principle**: All UI features must meet WCAG 2.1 Level AA standards.

**Why**: Inclusive design reaches more users and is often legally required.

**Implementation**:
- Semantic HTML, ARIA labels where needed
- Keyboard navigation support (no mouse-only interactions)
- Color contrast ratios: 4.5:1 for text, 3:1 for UI components
- Screen reader testing during `/preview` phase
- Use automated tools (axe, Lighthouse) in `/optimize` phase

**Violations**:
- ❌ Mouse-only interactions
- ❌ Low contrast text
- ❌ Missing alt text, ARIA labels, or focus states

---

### 5. Security Practices

**Principle**: Security is not optional. All features must follow secure coding practices.

**Why**: Breaches destroy trust and can be catastrophic for users and the business.

**Implementation**:
- Input validation on all user-provided data
- Parameterized queries (no string concatenation for SQL)
- Authentication/authorization checks on all protected routes
- Secrets in environment variables, never committed to code
- Security review during `/optimize` phase

**Violations**:
- ❌ Trusting user input without validation
- ❌ Exposing sensitive data in logs, errors, or responses
- ❌ Hardcoded credentials or API keys

---

### 6. Code Quality

**Principle**: Code must be readable, maintainable, and follow established patterns.

**Why**: Code is read 10x more than it's written. Optimize for future maintainers.

**Implementation**:
- Follow project style guides (linters, formatters)
- Functions <50 lines, classes <300 lines
- Meaningful names (no `x`, `temp`, `data`)
- Comments explain "why", not "what"
- DRY (Don't Repeat Yourself): Extract reusable utilities
- KISS (Keep It Simple, Stupid): Simplest solution that works

**Violations**:
- ❌ Copy-pasting code instead of extracting functions
- ❌ Overly clever one-liners that obscure intent
- ❌ Skipping code review feedback

---

### 7. Documentation Standards

**Principle**: Document decisions, not just code. Future you will thank you.

**Why**: Context decays fast. Documentation preserves the "why" behind decisions.

**Implementation**:
- Update `NOTES.md` during feature development (decisions, blockers, pivots)
- API endpoints: Document request/response schemas (OpenAPI/Swagger)
- Complex logic: Add inline comments explaining rationale
- Breaking changes: Update CHANGELOG.md
- User-facing features: Update user docs

**Violations**:
- ❌ Undocumented API changes
- ❌ Empty NOTES.md after multi-week features
- ❌ Cryptic commit messages ("fix stuff", "updates")

---

### 8. Do Not Overengineer

**Principle**: Ship the simplest solution that meets requirements. Iterate later.

**Why**: Premature optimization wastes time and creates complexity debt.

**Implementation**:
- YAGNI (You Aren't Gonna Need It): Build for today, not hypothetical futures
- Use proven libraries instead of custom implementations
- Defer abstractions until patterns emerge (Rule of Three)
- Ship MVPs, gather feedback, iterate

**Violations**:
- ❌ Building frameworks when a library exists
- ❌ Abstracting after one use case
- ❌ Optimization without profiling data

---

## Conflict Resolution

When principles conflict (e.g., "ship fast" vs "test thoroughly"), prioritize in this order:

1. **Security** - Never compromise on security
2. **Accessibility** - Legal and ethical obligation
3. **Testing** - Prevents regressions, enables velocity
4. **Specification** - Alignment prevents waste
5. **Performance** - User experience matters
6. **Code Quality** - Long-term maintainability
7. **Documentation** - Preserves context
8. **Simplicity** - Avoid premature optimization

---

## Amendment Process

These principles evolve with your project. To propose changes:

1. Run `/update-project-config` with your proposed change
2. Review the diff
3. Commit if approved

**Versioning**:
- **MAJOR**: Removed principle or added mandatory requirement
- **MINOR**: Added principle or expanded guidance
- **PATCH**: Fixed typo or updated date

---

## References

- Project Overview: `docs/project/overview.md`
- Tech Stack: `docs/project/tech-stack.md`
- System Architecture: `docs/project/system-architecture.md`
