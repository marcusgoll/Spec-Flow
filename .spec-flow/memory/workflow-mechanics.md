# Workflow Mechanics

**Version**: 1.0.0
**Last Updated**: 2025-11-04
**Status**: Active

> This document defines how the Spec-Flow workflow operates. These are system mechanics managed by the workflow team - users should not modify this file.

---

## Roadmap Management

**Philosophy**: The roadmap is the Single Source of Truth (SSOT) for feature planning and delivery status. Features move through a defined lifecycle from planning to production.

### Roadmap Lifecycle

**Backend**: GitHub Issues with label-based state management

**Sections** (via labels):

1. **Backlog** (`status:backlog`) - Ideas and future features (not prioritized)
2. **Later** (`status:later`) - Planned but low priority
3. **Next** (`status:next`) - Prioritized for upcoming work
4. **In Progress** (`status:in-progress`) - Currently being developed
5. **Shipped** (`status:shipped`) - Deployed to production

**Automatic Transitions**:

- `/feature` → Marks feature as `status:in-progress` in GitHub Issues
- `/ship` (Phase S.5) → Marks feature as `status:shipped` with version and date

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

- **yes**: Immediately add to roadmap (runs `/roadmap add`)
- **later**: Save to `.spec-flow/memory/discovered-features.md` for batch review
- **no**: Skip (not tracked)

### GitHub Issue Format

Each feature in roadmap must have:

- **Title**: Human-readable feature name
- **Labels**: `type:feature`, `area:*`, `role:*`, `status:*`, `priority:*`, `size:*`
- **Body**: Problem, solution, requirements (markdown)
- **Frontmatter**: ICE scoring in YAML

**Shipped Features** (additional metadata via comment):

```markdown
---
Shipped: 2025-10-16
Release: v1.2.3
Production URL: https://app.example.com
---
```

### Roadmap Commands

- `/roadmap` - Interactive roadmap management
- `/roadmap add "Feature description"` - Add new feature
- `/roadmap brainstorm` - Generate feature ideas (quick or deep)
- `/roadmap prioritize` - Re-prioritize features using ICE scores
- `/roadmap ship <slug>` - Mark feature as shipped

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

1. Staging deployed via `/ship-staging`
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
- `specs/NNN-slug/state.yaml` - Machine-readable state

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

## Project Documentation Integration

**Location**: `docs/project/`

Comprehensive project-level design documentation providing the foundation for all features:

**Core Documents** (10 files):

1. **overview.md** - Vision, users, scope, success metrics, timeline
2. **system-architecture.md** - Components, integrations, Mermaid diagrams
3. **tech-stack.md** - Technology choices with rationale
4. **data-architecture.md** - ERD, storage strategy, data lifecycle
5. **api-strategy.md** - REST patterns, auth, versioning
6. **capacity-planning.md** - Micro → scale tiers with cost models
7. **deployment-strategy.md** - CI/CD, environments, rollback procedures
8. **development-workflow.md** - Git flow, PR process, Definition of Done
9. **engineering-principles.md** - 8 core engineering principles
10. **project-configuration.md** - Deployment model, scale tier, quick changes policy

**Initialization**: Run `/init-project` once per project (one-time setup)

**Maintenance**: Update docs when:

- Adding new service/component → update `system-architecture.md`
- Changing tech stack → update `tech-stack.md`
- Scaling to next tier → update `capacity-planning.md`
- Adjusting deployment strategy → update `deployment-strategy.md`
- Team process changes → update `development-workflow.md`
- Engineering standards evolve → update `engineering-principles.md`
- Deployment model changes → update `project-configuration.md`

**Workflow Integration**:
All features MUST align with project architecture:

- `/roadmap` - Checks `overview.md` for vision alignment, `tech-stack.md` for technical feasibility, `capacity-planning.md` for effort estimates
- `/spec` - References project docs during Phase 0 research
- `/plan` - Heavily integrates with all 10 docs for architecture decisions
- `/tasks` - Follows patterns from `tech-stack.md`, `api-strategy.md`
- `/implement` - Adheres to `development-workflow.md` and `engineering-principles.md` standards
- `/optimize` - Enforces `engineering-principles.md` quality standards

**Benefits**:

- Single Source of Truth for "what we're building"
- Faster onboarding (new dev/AI reads 10 docs, understands project)
- Consistent features (all align with project architecture)
- Better estimates (capacity planning informs scoping)
- Prevents tech drift (documented stack stops arbitrary changes)
- Clear engineering standards (principles guide quality gates)

---

## References

- **Spec-Flow Commands**: `.claude/commands/`
- **Templates**: `.spec-flow/templates/`
- **GitHub Roadmap**: GitHub Issues (per-project)
- **Design Inspirations**: `.spec-flow/memory/design-inspirations.md`
- **Design Principles**: `.spec-flow/memory/design-principles.md`
- **Project Documentation**: `docs/project/` (10 files)
