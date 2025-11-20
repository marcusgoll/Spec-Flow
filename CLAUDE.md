# CLAUDE.md

Spec-Flow Workflow Kit: Slash commands transform product ideas into production releases via spec-driven development.

## Workflow State Machines

### Feature (≤16h, single subsystem, clear requirements)

```
/feature → /clarify? → /plan → /tasks → /validate → /implement → /ship
```

Ship workflows (model auto-detected):
- **staging-prod**: /optimize → /preview → /ship-staging → /validate-staging → /ship-prod → /finalize
- **direct-prod**: /optimize → /preview → /deploy-prod → /finalize
- **local-only**: /optimize → /preview → /build-local → /finalize

Deployment detection:
- staging-prod: git remote + staging branch + `.github/workflows/deploy-staging.yml`
- direct-prod: git remote + no staging
- local-only: no git remote

### Epic (>16h, multiple subsystems, research required)

```
/epic → /init-project? → /clarify? → /plan → /tasks → /implement-epic → /optimize → /preview → /ship → /finalize
```

Differences from /feature:
- Auto-triggers /init-project if missing
- /clarify auto-invoked if ambiguity >30
- /plan uses meta-prompting (research → plan via sub-agents)
- /tasks builds dependency graph, locks API contracts
- /implement-epic executes sprints in parallel layers
- Artifacts: XML (epic-spec.xml, plan.xml, sprint-plan.xml, walkthrough.md)
- Auto-triggers /audit-workflow after implementation
- /preview adaptive gating (auto-skip if ≤2 sprints + no UI)

### UI-First Workflow

```
/feature → /clarify → /plan → /tasks --ui-first → [MOCKUP APPROVAL] → /implement → /ship
```

Mockup approval gate:
- Trigger: After /tasks --ui-first
- Location: specs/NNN-slug/mockups/*.html
- Checklist: mockup-approval-checklist.md
- Blocks /implement until: workflow-state.yaml manual_gates.mockup_approval.status = approved
- Continue: /feature continue

## Project Initialization

### /init-project

Generates 8 docs in docs/project/:
1. overview.md — Vision, users, scope, metrics
2. system-architecture.md — C4 diagrams, components, data flows
3. tech-stack.md — Technology choices, rationale
4. data-architecture.md — ERD, schemas, storage
5. api-strategy.md — REST/GraphQL patterns, auth, versioning
6. capacity-planning.md — Scaling model, cost
7. deployment-strategy.md — CI/CD, environments, rollback
8. development-workflow.md — Git flow, PR process, DoD

Interactive: 15 questions (~10min)
Brownfield: Auto-scans package.json, migrations, docker-compose.yml

### /init-project --with-design

Adds 4 design docs in docs/design/:
1. brand-guidelines.md
2. visual-language.md
3. accessibility-standards.md
4. component-governance.md

Generates design/systems/:
- tokens.css — WCAG AA compliant, OKLCH color space
- tokens.json

Interactive: 48 questions (~20-30min)
Brownfield: Scans existing tokens.css, flags WCAG violations

Greenfield: Auto-creates GitHub Issue #1 project-foundation (HIGH priority)
Foundation blocks all other features

## Commands

### Phase Commands
- /feature "name" — Create feature spec
- /epic "goal" — Multi-sprint complex work
- /clarify — Reduce ambiguity via AskUserQuestion
- /plan — Generate design artifacts
- /tasks — Generate concrete TDD tasks (--ui-first for mockups)
- /validate — Cross-artifact consistency
- /implement — Execute tasks with TDD (feature workflow)
- /implement-epic — Execute sprints in parallel layers (epic workflow)
- /optimize — Quality gates (performance, security, accessibility, code)
- /preview — Manual UI/UX testing
- /ship — Unified deployment orchestrator
- /ship-staging — Deploy to staging
- /validate-staging — Manual staging testing
- /ship-prod — Tagged promotion to production
- /deploy-prod — Direct production deployment
- /build-local — Local build validation
- /finalize — Documentation, housekeeping

### Workflow Health (v5.0)
- /audit-workflow — Analyze effectiveness (auto-runs after /implement, /implement-epic, /optimize, /finalize)
- /heal-workflow — Apply improvements with approval
- /workflow-health — Aggregate metrics dashboard (--detailed, --trends, --compare)

### Context Management
- /create-prompt — Generate Claude-to-Claude prompts
- /run-prompt <N> — Execute prompts in sub-agents (--parallel, --sequential)
- /whats-next — Handoff document for fresh context
- /add-to-todos — Capture ideas for later
- /check-todos — Resume from backlog
- /audit-skill — Evaluate skill quality
- /audit-slash-command — Audit command effectiveness
- /heal-skill — Apply skill corrections

### Project & Roadmap
- /init-project — Initialize design docs
- /init-project --with-design — Include design system
- /roadmap — Manage features via GitHub Issues (brainstorm, prioritize, track)
- /help — Context-aware workflow guidance (--verbose for state details)

### Infrastructure (Deprecated/Removed)
Contract, flag, metrics, scheduler commands removed in v6.0+

## Artifacts by Command

| Command | Outputs |
|---------|---------|
| /feature | spec.md, NOTES.md, visuals/README.md, workflow-state.yaml |
| /plan | plan.md, research.md |
| /tasks | tasks.md, mockup-approval-checklist.md (UI-first) |
| /validate | analysis-report.md |
| /implement | Task completions (feature workflow) |
| /implement-epic | Sprint results, contracts/*.yaml, audit-report.xml (epic workflow) |
| /optimize | optimization-report.md, code-review-report.md |
| /preview | release-notes.md |
| /ship-staging | staging-ship-report.md, deployment-metadata.json |
| /ship-prod | production-ship-report.md, GitHub release |
| /deploy-prod | production-ship-report.md |
| /build-local | local-build-report.md |
| /epic | epic-spec.xml, plan.xml, sprint-plan.xml, walkthrough.md |

## State Management

workflow-state.yaml tracks:
- Current phase, status
- Completed/failed phases
- Quality gates (pre-flight, code-review, rollback)
- Manual gates (mockup-approval, preview, staging-validation)
- Deployment info (URLs, IDs, timestamps)
- Artifact paths

## Quality Gates

### Blocking
- Pre-flight: env vars, build, docker, CI config
- Code review: No critical issues, performance, WCAG 2.1 AA, security
- Rollback (staging-prod only): Test actual rollback before production

### Manual (pause for approval)
- Mockup approval (UI-first only)
- Preview (local dev testing)
- Staging validation (staging-prod only)

Resume: /ship continue or /feature continue

## Living Documentation (v4.0)

Hierarchical CLAUDE.md:
```
Root CLAUDE.md (workflow overview)
  ↓ Project CLAUDE.md (active features, tech stack)
    ↓ Feature CLAUDE.md (current progress, specialists)
```

Token cost:
- Traditional: 12,700 tokens
- Hierarchical: 2,500 tokens (80% reduction)
- Resume work: 500 tokens (94% reduction)

Auto-updates:
- Feature CLAUDE.md: /feature, task completion, /feature continue
- Project CLAUDE.md: /init-project, /ship-staging, /ship-prod, /deploy-prod

Living sections:
- spec.md → Implementation Status
- plan.md → Discovered Patterns
- tasks.md → Progress Summary (velocity, ETA, bottlenecks)

Health check: `.spec-flow/scripts/bash/health-check-docs.sh`

## Directory Structure

- .claude/agents/ — Specialist briefs
- .claude/commands/ — Command specs
- .claude/skills/ — Reusable workflows
- .spec-flow/memory/ — Workflow mechanics
- .spec-flow/templates/ — Artifact scaffolds
- .spec-flow/scripts/ — Automation (powershell/, bash/)
- specs/NNN-slug/ — Feature working directories
- docs/project/ — Project design docs
- docs/design/ — Design system (if --with-design)
- design/systems/ — tokens.css, tokens.json

## Agent Organization

Phase: spec, clarify, plan, tasks, validate, implement, optimize, ship-staging, ship-prod, finalize, epic

Implementation: backend, frontend, database, api-contracts, test-architect

Quality/Code: code-reviewer, refactor-planner, refactor-surgeon, type-enforcer, cleanup-janitor

Quality/Testing: qa-tester, test-coverage, api-fuzzer, accessibility-auditor, ux-polisher

Quality/Security: security-sentry, performance-profiler, error-budget-guardian

Quality/DevTools: debug, auto-error-resolver, web-research-specialist

Quality/Operations: dependency-curator, data-modeler, observability-plumber, ci-sentry

Quality/Deployment: release, git-steward, docs-scribe, release-manager

Load briefs from .claude/agents/ for context

## Coding Standards

Markdown: Sentence-case headings, wrap ~100 chars, imperative voice, bullets for checklists

PowerShell: 4-space indent, Verb-Noun names, comment help, no aliases, support -WhatIf

Shell: POSIX-friendly, set -e, document required tools

Naming: kebab-case files, CamelCase only for PowerShell modules

Commits: Conventional Commits (feat/fix/docs/chore/refactor/test), <75 chars, imperative

## Context Management

Token budgets: Planning (75k), Implementation (100k), Optimization (125k)
Auto-compact at 80% threshold
Scripts:
- .spec-flow/scripts/bash/calculate-tokens.sh
- .spec-flow/scripts/bash/compact-context.sh
- .spec-flow/scripts/powershell/calculate-tokens.ps1
- .spec-flow/scripts/powershell/compact-context.ps1

## Question Banks (v5.0)

Use AskUserQuestion extensively:
- .claude/skills/clarify/references/question-bank.md (40+ feature questions)
- .claude/skills/epic/references/question-bank.md (8-9 epic scoping questions)

Batch 2-3 related questions, multiSelect for subsystems, conditional rounds for progressive refinement

## Workflow Integration

/roadmap reads: overview.md, tech-stack.md, capacity-planning.md

/spec reads: tech-stack.md, api-strategy.md, data-architecture.md, system-architecture.md

/plan reads: ALL 8 project docs (generates research.md)

/tasks --ui-first reads: visual-language.md, brand-guidelines.md, accessibility-standards.md

/implement reads: component-governance.md, visual-language.md

/implement-epic reads: sprint-plan.xml, epic-spec.xml, plan.xml, locked API contracts

## References

- README.md — Quick start
- docs/architecture.md — Workflow structure
- docs/commands.md — Command catalog
- docs/LIVING_DOCUMENTATION.md — Hierarchical context guide
- CONTRIBUTING.md — Branching, PRs, releases
- AGENTS.md — Contributor guide
- CHANGELOG.md — Version history
