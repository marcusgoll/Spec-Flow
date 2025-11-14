# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository. When addressing the user, sacrifice grammar for the sake of concision.

## Overview

The Spec-Flow Workflow Kit orchestrates feature delivery through a series of slash commands that transform product ideas into production releases via Spec-Driven Development. Each command produces auditable artifacts and hands context to the next specialist.

## Core Commands

Run commands in sequence to move features through the workflow:

**Windows (PowerShell 7.3+):**

```powershell
# Validate environment
pwsh -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Json

# Create new feature
pwsh -File .spec-flow/scripts/powershell/create-new-feature.ps1 "Feature Name"

# Calculate token budget
pwsh -File .spec-flow/scripts/powershell/calculate-tokens.ps1 -FeatureDir specs/NNN-slug

# Compact context when over budget
pwsh -File .spec-flow/scripts/powershell/compact-context.ps1 -FeatureDir specs/NNN-slug -Phase "implementation"
```

**macOS/Linux (Bash 5+):**

```bash
# Validate environment
.spec-flow/scripts/bash/check-prerequisites.sh --json

# Create new feature
.spec-flow/scripts/bash/create-new-feature.sh "Feature Name"

# Calculate token budget
.spec-flow/scripts/bash/calculate-tokens.sh --feature-dir specs/NNN-slug

# Compact context when over budget
.spec-flow/scripts/bash/compact-context.sh --feature-dir specs/NNN-slug --phase implementation
```

## Workflow State Machine

Features progress through fixed phases with automatic state tracking:

```
/feature → /clarify (if needed) → /plan → /tasks → /validate → /implement
  ↓
/ship (unified deployment orchestrator)
  ↓
Model-specific workflow:
  • staging-prod: /optimize → /preview → /ship-staging → /validate-staging → /ship-prod
  • direct-prod: /optimize → /preview → /deploy-prod
  • local-only: /optimize → /preview → /build-local
```

**Unified Deployment**:

- Use `/ship` after `/implement` to automatically execute the appropriate deployment workflow
- Deployment model is auto-detected (staging-prod, direct-prod, or local-only)
- Use `/ship continue` to resume after manual gates or failures
- Use `/ship status` to check current progress
- Commands are defined in `.claude/commands/`

**Navigation & Help**:

- Use `/help` anytime to see where you are in the workflow and what to do next
- Shows current phase, completed phases, blockers, and recommended next steps
- Context-aware: different output based on whether you're in a feature, at a manual gate, or blocked
- Run `/help verbose` for detailed state information (quality gates, deployments, artifacts)

**UI-First Workflow** (for features with screens/components):

```
/feature → /clarify → /plan → /tasks --ui-first
  ↓
Creates HTML mockups in specs/NNN-slug/mockups/
  ↓
[MANUAL GATE: Mockup Approval]
  ↓
/implement (converts HTML → Next.js)
  ↓
/ship (deployment workflow)
```

**Benefits**:
- Approve design before implementation investment
- Live design iteration (tokens.css updates refresh in browser)
- Component reuse enforced (checks ui-inventory.md)
- Accessibility validated early (WCAG 2.1 AA)
- All states demonstrated (loading, error, empty, success)

**Usage**: Add `--ui-first` flag to `/tasks` command for features requiring UI design

## Project Design Workflow

**When to use**: Before building any features, run `/init-project` to create comprehensive project-level design documentation.

**Philosophy**: "Planning is 80% of the project, 20% code." — Project design documentation ensures every feature aligns with system architecture from day one.

### One-Time Project Initialization

```bash
/init-project
```

**Purpose**: Generate 8 comprehensive project documentation files in `docs/project/`

**Interactive Setup** (15 questions, ~10 minutes):
- Project type: greenfield (new) or brownfield (existing codebase)
- Project vision and target users
- Scale tier: micro / small / medium / large
- Team size: solo / small / medium / large
- Tech stack: database, frontend, backend, deployment platform
- Architecture style: monolith / microservices / serverless
- API style: REST / GraphQL / tRPC / gRPC
- Auth provider: Clerk / Auth0 / custom / none
- Deployment model: staging-prod / direct-prod / local-only
- Git workflow: GitHub Flow / Git Flow / Trunk-Based
- Budget constraints and privacy requirements

### Generated Documentation (8 Files)

**Location**: `docs/project/`

1. **overview.md** — Vision, users, scope, success metrics, competitive landscape
2. **system-architecture.md** — C4 diagrams, components, data flows, security architecture
3. **tech-stack.md** — All technology choices with rationale and alternatives rejected
4. **data-architecture.md** — ERD (Mermaid), entity schemas, storage strategy, migrations
5. **api-strategy.md** — REST/GraphQL patterns, auth, versioning, error handling (RFC 7807)
6. **capacity-planning.md** — Scaling from micro (100 users) to 1000x growth with cost model
7. **deployment-strategy.md** — CI/CD pipeline, environments (dev/staging/prod), rollback
8. **development-workflow.md** — Git flow, PR process, testing strategy, Definition of Done

### Brownfield Project Scanning

**If existing codebase detected**, the project-architect agent automatically scans:

**Tech Stack Detection**:
- `package.json` → Node.js, React, Next.js, TypeScript
- `requirements.txt` / `pyproject.toml` → Python, FastAPI, Django
- `Cargo.toml` → Rust
- `go.mod` → Go

**Database Detection**:
- Dependencies: `pg` (PostgreSQL), `mysql2` (MySQL), `mongoose` (MongoDB)
- Migration files: `**/migrations/*.sql`, `**/alembic/versions/*.py`

**Architecture Pattern**:
- `/services/`, `/microservices/` directories → microservices
- Monorepo structure (`/apps/*`, `/packages/*`) → monolith
- `docker-compose.yml` with multiple services → microservices

**Deployment Platform**:
- `vercel.json` → Vercel
- `railway.json` → Railway
- `.github/workflows/deploy.yml` → GitHub Actions (inspect for platform)
- `Dockerfile` + AWS config → AWS

**Result**: Reduces unknowns by 20-30%, fills docs with accurate existing patterns

### Workflow Integration

**All subsequent commands reference project docs**:

**`/roadmap`**:
- Reads `overview.md` → validates new features against project vision and scope
- Reads `tech-stack.md` → suggests only technically-feasible features (brainstorm)
- Reads `capacity-planning.md` → adjusts effort estimates by scale tier (brainstorm)

**`/spec`**:
- Reads `tech-stack.md` → avoids suggesting wrong technologies
- Reads `api-strategy.md` → follows established REST/GraphQL patterns
- Reads `data-architecture.md` → reuses existing schemas, follows naming conventions
- Reads `system-architecture.md` → identifies integration points

**`/plan`**:
- Reads ALL 8 project docs during Phase 0 (Research)
- Extracts tech stack, architecture constraints, API patterns, data schemas
- Generates `research.md` with project context section
- Ensures plan aligns with capacity tier, deployment model, and cost constraints

**Benefits**:
- **Prevents hallucination** — Tech stack is documented, not guessed
- **Ensures consistency** — All features use same auth, API style, database
- **Avoids duplication** — ERD shows existing entities, preventing redundant tables
- **Speeds up features** — /spec and /plan have full context from day one

### When to Update Project Docs

**Rarely** — Project docs are stable, change infrequently

**Update when**:
- Major tech stack change (e.g., migrating PostgreSQL → MongoDB)
- Architecture evolution (e.g., monolith → microservices)
- New integration (e.g., adding Stripe payments)
- Scale tier increase (e.g., micro → small)

**How to update**: Edit `docs/project/*.md` files directly, then commit

**Anti-pattern**: Don't regenerate with `/init-project` — you'll lose customizations

### Example Output

**Greenfield project** (minimal info):
- Vision, users from questionnaire
- Many `[NEEDS CLARIFICATION]` sections (user fills later)
- Reasonable defaults (e.g., monolith for solo dev)

**Brownfield project** (rich scan):
- Auto-detected tech stack from `package.json`, `requirements.txt`
- Generated ERD from Alembic migrations
- Detected API patterns from existing routes
- Fewer `[NEEDS CLARIFICATION]` (more inferred from code)

### Next Steps After `/init-project`

**For Greenfield Projects** (new codebase):
1. **Review** `docs/project/` files
2. **Fill** any `[NEEDS CLARIFICATION]` sections
3. **Foundation issue auto-created** → GitHub Issue `#1 project-foundation` (HIGH priority)
4. **Build foundation first**: `/feature "project-foundation"`
   - Scaffolds project with documented tech stack (Next.js, Tailwind, PostgreSQL, etc.)
   - Sets up dev environment, linting, deployment config
   - CRITICAL: All other features depend on this
5. **Then add features**: `/roadmap` or `/feature "your-feature"`

**For Brownfield Projects** (existing codebase):
1. **Review** `docs/project/` files
2. **Fill** any `[NEEDS CLARIFICATION]` sections
3. **No foundation needed** → Existing code detected
4. **Start building features**: `/roadmap` or `/feature "your-feature"`

All features will now align with your documented architecture.

## Recent Changes

**Current Version**: v4.0.0 (2025-11-08)

### Latest Updates

**v4.0.0**: Living Documentation & Hierarchical CLAUDE.md
- Automatic documentation updates during implementation (no manual sync)
- Feature-level and project-level CLAUDE.md files for efficient AI context navigation
- 96% token reduction (500 tokens vs 12,000 for project context)
- Velocity tracking and bottleneck detection in tasks.md
- Health checks for stale documentation

**v3.0.0**: Style Guide Approach
- 75-85% faster UI development
- 82-88% fewer tokens per screen
- Zero manual design gates

**v2.5.0**: Constitution Cleanup
- Split constitution.md into focused files (engineering-principles, project-configuration, workflow-mechanics)

**v2.4.0**: Roadmap & Foundation Improvements
- Technical validation for `/roadmap brainstorm`
- Auto-create foundation issue for greenfield projects

**See [CHANGELOG.md](CHANGELOG.md) for complete version history**

---

## Living Documentation (v4.0.0)

**Problem Solved**: Traditional documentation becomes stale within weeks, requiring manual synchronization with code changes. Reading all project documentation consumes 12,000+ tokens, slowing AI context loading.

**Solution**: Hierarchical CLAUDE.md files that auto-update during workflow execution, providing token-efficient context navigation.

### Hierarchical CLAUDE.md Files

```
Root CLAUDE.md (workflow overview - 451 lines)
  ↓
Project CLAUDE.md (active features, tech stack - ~100 lines)
  ↓
Feature CLAUDE.md (current progress, specialists - ~80 lines)
```

**Token Efficiency**:
- **Before**: 12,700 tokens to load full context (all project + feature docs)
- **After**: 2,500 tokens with hierarchy (80% reduction)
- **Resume work**: 500 tokens (feature CLAUDE.md only - 94% reduction)

### Automatic Updates

Documentation updates atomically with code changes:

**Feature CLAUDE.md** (`specs/NNN-slug/CLAUDE.md`):
- **Triggers**: `/feature`, task completion (via task-tracker), `/feature continue`
- **Content**: Current phase/progress, last 3 completed tasks, velocity metrics, relevant specialists
- **Token Cost**: ~500 tokens (vs 8,000 for reading all feature artifacts)

**Project CLAUDE.md** (project root):
- **Triggers**: `/init-project`, `/ship-staging`, `/ship-prod`, `/deploy-prod`
- **Content**: Active features, condensed tech stack, common patterns discovered
- **Token Cost**: ~2,000 tokens (vs 12,000 for reading all project docs)

**Living Artifact Sections**:
- `spec.md` → **Implementation Status** (requirements fulfilled, deviations, performance actuals)
- `plan.md` → **Discovered Patterns** (reusable code found during implementation)
- `tasks.md` → **Progress Summary** (velocity, ETA, bottlenecks)

### Velocity Tracking

Every task completion automatically updates velocity metrics in tasks.md:

```
Progress Summary:
- Total Tasks: 25
- Completed: 12 (48%)
- Average Time: 45 min/task
- Completion Rate: 3.5 tasks/day
- ETA: 2025-11-10 16:00

Bottlenecks:
- T006-T009 (Migration tasks): 90min vs 30min estimated
  Reason: RLS policy complexity
  Impact: +1 hour overall delay
```

### Health Checks

Detect stale documentation before it becomes a problem:

```bash
# Scan for CLAUDE.md files older than 7 days
.spec-flow/scripts/bash/health-check-docs.sh

# Output:
❌ specs/001-auth/CLAUDE.md (12d old)
✅ specs/002-dashboard/CLAUDE.md (1d old)
```

### Usage Example

**Starting a new feature**:

```bash
# 1. Read project context (once)
cat CLAUDE.md  # 2,000 tokens - active features, tech stack

# 2. Create feature
/feature "User authentication"
# Auto-generates specs/001-auth/CLAUDE.md

# 3. Work on feature
cat specs/001-auth/CLAUDE.md  # 500 tokens - current progress, specialists

# Total: 2,500 tokens (vs 12,700 traditional approach - 80% savings)
```

**Resuming work**:

```bash
# Read feature context only
cat specs/001-auth/CLAUDE.md  # 500 tokens

# Shows: last 3 tasks, velocity, ETA, next steps
# No need to re-read project docs
```

**See [docs/LIVING_DOCUMENTATION.md](docs/LIVING_DOCUMENTATION.md) for complete guide**

---

## Architecture

**Directory structure:**

- `.claude/agents/` — Persona briefs for specialists (backend, frontend, QA, release)
- `.claude/commands/` — Command specifications with inputs, outputs, and auto-progression
- `.spec-flow/memory/` — Workflow mechanics (workflow system files)
- `.spec-flow/templates/` — Markdown scaffolds for specs, plans, tasks, reports, style-guide
- `.spec-flow/scripts/powershell/` — Windows/cross-platform automation
- `.spec-flow/scripts/bash/` — macOS/Linux automation
- `specs/NNN-slug/` — Feature working directories created by `/feature`

**Context management:**

- Phase-based token budgets: Planning (75k), Implementation (100k), Optimization (125k)
- Auto-compact at 80% threshold using phase-aware strategies
- Compaction reduces context by 90%/60%/30% depending on phase
- Run `calculate-tokens` before heavy operations to check budget

## Key Artifacts

Each command produces structured outputs:

| Command             | Artifacts                                                         |
| ------------------- | ----------------------------------------------------------------- |
| `/feature`          | `spec.md`, `NOTES.md`, `visuals/README.md`, `workflow-state.yaml` |
| `/plan`             | `plan.md`, `research.md`                                          |
| `/tasks`            | `tasks.md` (20-30 tasks), `mockup-approval-checklist.md` (UI-first) |
| `/validate`         | `analysis-report.md`                                              |
| `/implement`        | Implementation checklist + task completion                        |
| `/ship`             | `ship-summary.md`, state updates, deployment orchestration        |
| `/optimize`         | `optimization-report.md`, `code-review-report.md`                 |
| `/preview`          | `release-notes.md`, preview checklist                             |
| `/ship-staging`     | `staging-ship-report.md`, `deployment-metadata.json`              |
| `/validate-staging` | Staging sign-off summary, rollback test results                   |
| `/ship-prod`        | `production-ship-report.md`, release version                      |
| `/deploy-prod`      | `production-ship-report.md`, deployment IDs                       |
| `/build-local`      | `local-build-report.md`, build artifacts analysis                 |
| `/deploy-status`    | Real-time deployment status display                               |

**State Management**: All commands update `workflow-state.yaml` with:

- Current phase and status
- Completed/failed phases
- Quality gates (pre-flight, code review, rollback capability)
- Manual gates (preview, staging validation)
- Deployment information (URLs, IDs, timestamps)
- Artifact paths

## Deployment Models

The workflow automatically detects and adapts to three deployment models:

### staging-prod (Recommended)

- **Detection**: Git remote + staging branch + `.github/workflows/deploy-staging.yml`
- **Workflow**: optimize → preview → ship-staging → validate-staging → ship-prod
- **Features**: Full staging validation, rollback testing, production promotion
- **Use for**: Production applications, team projects, critical deployments

### direct-prod

- **Detection**: Git remote + no staging branch/workflow
- **Workflow**: optimize → preview → deploy-prod
- **Features**: Direct production deployment, deployment ID tracking
- **Use for**: Simple applications, solo developers, rapid iteration
- **Risk**: Higher (no staging validation)

### local-only

- **Detection**: No git remote configured
- **Workflow**: optimize → preview → build-local
- **Features**: Local build validation, security scanning, artifact analysis
- **Use for**: Local development, prototypes, desktop applications

**Override**: Set deployment model explicitly in `.spec-flow/memory/constitution.md`

## Quality Gates

### Pre-flight Validation (Blocking)

- Environment variables configured
- Production build succeeds
- Docker images build
- CI configuration valid
- Dependencies checked

**Blocks deployment if failed**

### Code Review Gate (Blocking)

- No critical code quality issues
- Performance benchmarks met
- Accessibility standards (WCAG 2.1 AA)
- Security scan completed

**Blocks deployment if critical issues found**

### Rollback Capability Gate (staging-prod only, Blocking)

- Deployment IDs extracted from logs
- Rollback test executed (actual Vercel alias change)
- Previous deployment verified live
- Roll-forward verified

**Blocks production if rollback test fails**

### Manual Gates (Pause for approval)

- **Mockup Approval**: HTML mockup review before implementation (UI-first features only)
- **Preview**: Manual UI/UX testing on local dev server
- **Staging Validation**: Manual testing in staging environment (staging-prod only)

**Mockup Approval Gate** (UI-first features):
- **Trigger**: After `/tasks --ui-first` generates HTML mockups
- **Location**: `specs/NNN-slug/mockups/*.html`
- **Review Checklist**: `specs/NNN-slug/mockup-approval-checklist.md`
- **Blocks**: `/implement` execution until approved
- **Workflow**:
  1. Open HTML mockup in browser (links to `design/systems/tokens.css`)
  2. Press 'S' key to cycle through states (Success/Loading/Error/Empty)
  3. Review visual design, interactions, accessibility, tokens.css compliance
  4. Request changes if needed (agent proposes tokens.css updates)
  5. Update `workflow-state.yaml`: `manual_gates.mockup_approval.status: approved`
  6. Run `/feature continue` to proceed with implementation

**Preview & Staging Gates**:

**Requires `/ship continue` to proceed**

## Coding Standards

**Markdown:**

- Sentence-case headings
- Wrap near 100 characters
- Imperative voice for instructions
- Bullets for checklists

**PowerShell scripts:**

- Four-space indentation
- `Verb-Noun` function names
- Comment-based help
- No aliases in scripts
- Support `-WhatIf` where feasible

**Shell scripts:**

- POSIX-friendly
- Exit on error (`set -e`)
- Document required tools in header

**Naming:**

- Use `kebab-case` for all files (e.g., `agent-brief.md`)
- CamelCase only for PowerShell modules

## Commit Convention

Follow Conventional Commits:

- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation
- `chore:` maintenance
- `refactor:` code restructure
- `test:` test additions

Example: `docs: refresh debugger brief`

Keep subjects under 75 characters, imperative mood.

## Testing

No CI pipeline yet. Validate locally before submitting:

- PowerShell: `Invoke-Pester -Path tests`
- Shell: Test with `-WhatIf` flags or dry-run modes
- Markdown: Preview in renderer, verify token estimates with `calculate-tokens`

## Agent Briefs

Specialist agents are organized in `.claude/agents/` by category:

**Phase Orchestrators** (`phase/`):

- `spec.md`, `clarify.md`, `plan.md`, `tasks.md`, `validate.md`, `implement.md`, `optimize.md`, `ship-staging.md`, `ship-prod.md`, `finalize.md`

**Implementation Specialists** (`implementation/`):

- `backend.md` — Backend/API implementation
- `frontend.md` — Frontend/UI implementation
- `database.md` — Database architecture and migrations
- `api-contracts.md` — API contract management
- `test-architect.md` — TDD test suite generation from acceptance criteria

**Quality Specialists** (`quality/`):

**Code Quality** (`quality/code-quality/`):
- `code-reviewer.md` — Code review (KISS/DRY enforcement)
- `refactor-planner.md` — Refactoring analysis and planning
- `refactor-surgeon.md` — Safe refactoring with minimal blast radius
- `type-enforcer.md` — TypeScript strict type safety enforcement
- `cleanup-janitor.md` — Dead code removal and codebase normalization

**Testing & Validation** (`quality/testing/`):
- `qa-tester.md` — QA and testing
- `test-coverage.md` — Test coverage enhancement
- `api-fuzzer.md` — API contract robustness testing
- `accessibility-auditor.md` — WCAG 2.1 AA compliance validation
- `ux-polisher.md` — UI interaction state completeness review

**Security & Performance** (`quality/security/`):
- `security-sentry.md` — Security vulnerability scanning and blocking
- `performance-profiler.md` — Performance bottleneck identification
- `error-budget-guardian.md` — SLO impact assessment for hot path changes

**Development Tools** (`quality/dev-tools/`):
- `debug.md` — Error triage and debugging
- `auto-error-resolver.md` — Automatic compilation error fixes
- `web-research-specialist.md` — Creative search for solutions and debugging

**Operations & Infrastructure** (`quality/operations/`):
- `dependency-curator.md` — Dependency management and deduplication
- `data-modeler.md` — Schema design and migration planning
- `observability-plumber.md` — Production instrumentation and tracing
- `ci-sentry.md` — CI/CD pipeline optimization and flaky test quarantine

**Deployment** (`quality/deployment/`):
- `release.md` — CI/CD and release management
- `git-steward.md` — Commit organization and PR preparation
- `docs-scribe.md` — ADR and CHANGELOG generation after merges
- `release-manager.md` — Release notes and deployment artifact preparation

When working with agents, load the relevant brief for context on capabilities and responsibilities.

## Philosophy

1. **Specification first** — Every artifact traces to explicit requirements
2. **Agents as teammates** — Commands encode expectations for alignment
3. **Context discipline** — Token budgets measured, compacted, recycled
4. **Ship in stages** — Staging and production have dedicated rituals with human gates

## References

- `README.md` — Quick start and script reference
- `docs/architecture.md` — High-level workflow structure
- `docs/commands.md` — Command catalog
- `CONTRIBUTING.md` — Branching, PRs, release process
- `AGENTS.md` — Contributor guide for this repo
