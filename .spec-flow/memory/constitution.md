# Engineering Constitution

**Version**: 1.1.0
**Last Updated**: 2025-10-16
**Status**: Active

> This document defines the core engineering principles that govern all feature development in this project. Every specification, plan, and implementation must align with these principles.

---

## Purpose

The Engineering Constitution serves as the Single Source of Truth (SSOT) for engineering standards and decision-making. When in doubt, refer to these principles. When principles conflict with convenience, principles win.

---

## Project Configuration

**Project Type**: Auto-detected on first `/feature` run

**Deployment Model**: staging-prod _(auto-detected, can be overridden)_

**Available Models**:
- `staging-prod` - Full staging validation before production (recommended)
- `direct-prod` - Direct production deployment without staging
- `local-only` - Local builds only, no remote deployment

**Auto-Detection Logic**:

The deployment model is automatically detected based on repository configuration:

1. **staging-prod** - All of the following are true:
   - Git remote configured (`git remote -v | grep origin`)
   - Staging branch exists (`git show-ref refs/heads/staging` or `refs/remotes/origin/staging`)
   - Staging workflow exists (`.github/workflows/deploy-staging.yml`)

2. **direct-prod** - When:
   - Git remote configured
   - No staging branch or staging workflow

3. **local-only** - When:
   - No git remote configured

**Manual Override**:

To override auto-detection, set the deployment model explicitly:

```
Deployment Model: staging-prod
```

_(Write exactly one of: staging-prod, direct-prod, local-only)_

**Workflow Paths by Model**:

| Model | Post-Implementation Workflow |
|-------|------------------------------|
| staging-prod | /optimize → /preview → /phase-1-ship → /validate-staging → /phase-2-ship |
| direct-prod | /optimize → /preview → /deploy-prod |
| local-only | /optimize → /preview → /build-local |

**Unified Command**: Use `/ship` after `/implement` to automatically execute the appropriate workflow based on deployment model.

**Quick Changes**: For small bug fixes, refactors, or enhancements (<100 LOC), use `/quick "description"` instead of full `/feature` workflow.

---

## Roadmap Management

**Philosophy**: The roadmap is the Single Source of Truth (SSOT) for feature planning and delivery status. Features move through a defined lifecycle from planning to production.

### Roadmap Lifecycle

**Sections**:
1. **Backlog** - Ideas and future features (not prioritized)
2. **Later** - Planned but low priority
3. **Next** - Prioritized for upcoming work
4. **In Progress** - Currently being developed
5. **Shipped** - Deployed to production

**Automatic Transitions**:
- `/spec-flow` → Marks feature as "In Progress" in roadmap
- `/ship` (Phase S.5) → Marks feature as "Shipped" with version and date

### Feature Discovery

During implementation, the workflow may discover potential features not yet in the roadmap:

**Detection Patterns**:
- Comments containing: "future work", "TODO", "later", "phase 2", "out of scope"
- Spec sections marked as out-of-scope with future potential

**User Prompt**:
When discovered features are found, the workflow prompts:
```
💡 Discovered Potential Feature
Context: [where it was found]
Description: [feature description]

Add to roadmap? (yes/no/later):
```

**Actions**:
- **yes**: Immediately add to roadmap (prompts for /roadmap command)
- **later**: Save to `.spec-flow/memory/discovered-features.md` for batch review
- **no**: Skip (not tracked)

### Roadmap Format

Each feature in roadmap must have:
```markdown
### 001-feature-slug

- **Title**: Human-readable feature name
- **Area**: Component or domain (e.g., Auth, UI, API)
- **Role**: User role or persona (e.g., End User, Admin)
- **ICE Score**: Impact (1-10), Confidence (1-10), Ease (1-10) [only for unshipped features]
```

**Shipped Features** (additional metadata):
```markdown
### 001-feature-slug

- **Title**: Human-readable feature name
- **Area**: Component or domain
- **Role**: User role or persona
- **Date**: 2025-10-16
- **Release**: v1.2.3
- **URL**: https://app.example.com (optional)
```

### Roadmap Commands

- `/roadmap` - Interactive roadmap management
- `/roadmap add "Feature description"` - Add new feature
- `/roadmap prioritize` - Re-prioritize features using ICE scores
- `/roadmap review` - Review discovered features

---

## Version Management

**Philosophy**: Every production deployment increments the semantic version and creates a git tag. Versions track feature releases and enable rollback.

### Semantic Versioning

**Format**: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes (user-facing API changes, data migrations)
- **MINOR**: New features (backward-compatible enhancements)
- **PATCH**: Bug fixes (backward-compatible corrections)

**Detection Logic**:
- Spec or ship report contains "breaking change" → MAJOR bump
- Spec contains "fix", "bug", "patch", or "hotfix" → PATCH bump
- Default → MINOR bump (new feature)

### Automatic Version Bumping

**When**: During `/ship` Phase S.5 (after deployment succeeds)

**Process**:
1. Read current version from `package.json`
2. Analyze spec and ship report for bump type
3. Calculate new version (e.g., 1.2.0 → 1.3.0)
4. Update `package.json`
5. Create annotated git tag: `v1.3.0`
6. Generate release notes from ship report
7. Update roadmap with version number

**Non-Blocking**: If `package.json` doesn't exist or version bump fails, workflow continues with warning

### Release Notes

**Auto-Generated from Ship Report**:
```markdown
# Release v1.3.0

**Date**: 2025-10-16

## Features

### Feature Title

[Summary from ship report]

## Changes

[Changes from ship report]

## Deployment

- **Production URL**: https://app.example.com
- **Release Tag**: v1.3.0
- **Feature Spec**: specs/001-feature-slug/spec.md
```

**Location**: `RELEASE_NOTES.md` (root directory)

### Git Tags

**Format**: `v1.3.0` (annotated tags)

**Message**: `Release v1.3.0 - Auto-bumped (minor)`

**Pushing Tags**:
- Tags created locally during `/ship`
- Push to remote: `git push origin v1.3.0`
- Tags enable rollback and release tracking

### Version Policies

1. **Never manually edit versions** - Always use `/ship` workflow
2. **Never skip versions** - Sequential increments only
3. **Tag before pushing** - Create tag locally, verify, then push
4. **Breaking changes require planning** - Major bumps need stakeholder approval

---

## Deployment Quality Gates

**Quality gates** are automated checks that must pass before deployment can proceed.

### Pre-flight Validation

**When**: Before any deployment (staging or production)

**Checks**:
- ✅ Environment variables configured in GitHub secrets
- ✅ Production build succeeds locally
- ✅ Docker images build successfully
- ✅ CI workflow configuration valid
- ✅ Dependencies checked for outdated packages

**Blocking**: Yes - deployment fails if pre-flight fails

**Override**: Not recommended - fix issues and retry

### Code Review Gate

**When**: During `/optimize` phase

**Checks**:
- ✅ No critical code quality issues
- ✅ Performance benchmarks met
- ✅ Accessibility standards (WCAG 2.1 AA)
- ✅ Security scan completed

**Blocking**: Yes - critical issues must be resolved

### Rollback Capability Gate

**When**: After staging deployment, before production (staging-prod model only)

**Checks**:
- ✅ Deployment IDs extracted from staging logs
- ✅ Rollback test executed (actual Vercel alias change)
- ✅ Previous deployment verified live
- ✅ Roll-forward to current deployment verified

**Blocking**: Yes - production deployment fails if rollback test fails

**Purpose**: Ensures ability to quickly rollback if production deployment causes issues

---

## Manual Gates

**Manual gates** require human approval before proceeding. The workflow pauses for testing and validation.

### Preview Gate

**Location**: After `/optimize`, before deployment

**Purpose**: Manual UI/UX validation on local development server

**Process**:
1. Run `/preview` to start local dev server
2. Test feature functionality thoroughly
3. Verify UI/UX across different screen sizes
4. Check keyboard navigation and accessibility
5. Test error states and edge cases
6. When satisfied, run `/ship continue` to proceed

**Required for**: All deployment models

**Rationale**: Automated tests can't catch all UX issues - human testing is essential

### Staging Validation Gate

**Location**: After staging deployment, before production

**Applies to**: staging-prod model only

**Purpose**: Validate feature in real staging environment

**Process**:
1. Staging deployed via `/phase-1-ship`
2. Run `/validate-staging` for automated health checks
3. Manually test feature on staging URL
4. Verify E2E tests passed in GitHub Actions
5. Check Lighthouse CI scores
6. Confirm rollback capability tested
7. When approved, run `/ship continue` for production deployment

**Required for**: staging-prod model only (direct-prod and local-only skip this)

**Rationale**: Production-like environment testing catches issues that local testing misses

---

## Rollback Strategy

**Philosophy**: Every production deployment must be reversible within 5 minutes.

### Deployment ID Tracking

**What**: Unique identifiers for each deployment (Vercel URLs, Docker images, Railway IDs)

**Storage**:
- `specs/NNN-slug/deployment-metadata.json` - Human-readable
- `specs/NNN-slug/workflow-state.json` - Machine-readable state

**Extraction**: Automatic from GitHub Actions workflow logs

### Rollback Testing (staging-prod only)

**When**: During `/validate-staging` phase

**Process**:
1. Load previous deployment ID from state
2. Execute: `vercel alias set <previous-id> <staging-url>`
3. Wait for DNS propagation (15 seconds)
4. Verify previous deployment is live (check HTTP headers)
5. Roll forward: `vercel alias set <current-id> <staging-url>`
6. Verify current deployment is live again

**Blocking**: If rollback test fails, production deployment is blocked

### Production Rollback

**When to rollback**:
- Critical bugs discovered post-deployment
- Performance degradation
- Security vulnerability
- High error rates

**How to rollback**:
```bash
# For Vercel deployments
vercel alias set <previous-deployment-id> <production-url> --token=$VERCEL_TOKEN

# For Railway/other platforms
# Use platform's UI or CLI rollback feature

# For manual git revert
git revert <commit-sha>
git push
```

**Deployment IDs**: Found in ship reports (`*-ship-report.md`) or `deployment-metadata.json`

---

## Core Principles

### 1. Specification First

**Principle**: Every feature begins with a written specification that defines requirements, success criteria, and acceptance tests before any code is written.

**Why**: Specifications prevent scope creep, align stakeholders, and create an auditable trail of decisions.

**Implementation**:
- Use `/spec-flow` to create specifications from roadmap entries
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

This constitution evolves with the project. To propose changes:

1. Run `/constitution "describe proposed change"`
2. Claude will update the constitution and bump the version:
   - **MAJOR**: Removed principle or added mandatory requirement
   - **MINOR**: Added principle or expanded guidance
   - **PATCH**: Fixed typo or updated date
3. Review the diff and approve/reject
4. Commit the updated constitution

---

## Project Documentation

**Location**: `docs/project/`

Comprehensive project-level design documentation providing the foundation for all features:

**Core Documents** (8 files):
1. **overview.md** - Vision, users, scope, success metrics, timeline
2. **system-architecture.md** - Components, integrations, Mermaid diagrams
3. **tech-stack.md** - Technology choices with rationale
4. **data-architecture.md** - ERD, storage strategy, data lifecycle
5. **api-strategy.md** - REST patterns, auth, versioning
6. **capacity-planning.md** - Micro → scale tiers with cost models
7. **deployment-strategy.md** - CI/CD, environments, rollback procedures
8. **development-workflow.md** - Git flow, PR process, Definition of Done

**Initialization**: Run `/init-project` once per project (one-time setup)

**Maintenance**: Update docs when:
- Adding new service/component → update `system-architecture.md`
- Changing tech stack → update `tech-stack.md`
- Scaling to next tier → update `capacity-planning.md`
- Adjusting deployment strategy → update `deployment-strategy.md`
- Team process changes → update `development-workflow.md`

**Workflow Integration**:
All features MUST align with project architecture:
- `/roadmap` - Checks `overview.md` for vision alignment, out-of-scope boundaries
- `/spec` - References project docs during Phase 0 research
- `/plan` - Heavily integrates with all 8 docs for architecture decisions
- `/tasks` - Follows patterns from `tech-stack.md`, `api-strategy.md`
- `/implement` - Adheres to `development-workflow.md` standards

**Benefits**:
- Single Source of Truth for "what we're building"
- Faster onboarding (new dev/AI reads 8 docs, understands project)
- Consistent features (all align with project architecture)
- Better estimates (capacity planning informs scoping)
- Prevents tech drift (documented stack stops arbitrary changes)

---

## References

- **Spec-Flow Commands**: `.claude/commands/`
- **Templates**: `.spec-flow/templates/`
- **Roadmap**: `.spec-flow/memory/roadmap.md`
- **Design Inspirations**: `.spec-flow/memory/design-inspirations.md`
- **Project Documentation**: `docs/project/` (see above)

---

**Maintained by**: Engineering Team + Claude Code
**Review Cycle**: Quarterly or after major project milestones
