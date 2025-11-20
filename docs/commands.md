# Slash Command Reference

Complete reference of all available workflow commands in Spec-Flow v6.11.0.

## Quick Navigation

- [Core Commands](#core-commands) - Essential workflow orchestration
- [Phase Commands](#phase-commands) - Individual workflow phases
- [Epic Commands](#epic-commands) - Multi-sprint workflows
- [Deployment Commands](#deployment-commands) - Staging and production deployment
- [Build Commands](#build-commands) - Local builds and branch enforcement
- [Project Commands](#project-commands) - Project initialization and configuration
- [Quality Commands](#quality-commands) - Quality gates and CI fixes
- [Infrastructure Commands](#infrastructure-commands) - Workflow health and optimization
- [Meta Commands](#meta-commands) - Developer tools and utilities
- [Internal Commands](#internal-commands) - Repository maintenance (not in npm package)

---

## Core Commands

Core orchestration commands for feature development workflows.

| Command | Description |
|---------|-------------|
| `/feature [description\|slug\|continue\|next\|epic:<name>\|epic:<name>:sprint:<num>\|sprint:<num>]` | Execute feature development workflow from specification through production deployment with automated quality gates and manual approval checkpoints |
| `/quick <description>` | Implement small bug fixes and features (<100 LOC) without full workflow. Use for single-file changes, bug fixes, refactors, and minor enhancements that can be completed in under 30 minutes. |
| `/help [verbose]` | Analyze workflow state and provide context-aware guidance with visual progress indicators and recommended next steps |
| `/route-agent [task description]` | Analyze task and route to specialist agent (backend, frontend, database, qa, debugger, or reviewer) using scoring algorithm and shared routing rules |

**Usage Example:**
```bash
# Start a new feature
/feature "Add dark mode toggle to user settings"

# Quick fix
/quick "Fix typo in welcome message"

# Resume current feature
/feature continue

# Get workflow guidance
/help
```

---

## Phase Commands

Individual workflow phases - can be run standalone or via `/feature` orchestration.

| Command | Description |
|---------|-------------|
| `/spec <feature-description> [--interactive] [--yes] [--skip-clarify]` | Generate complete feature specification with research, requirements analysis, and quality gates |
| `/clarify [spec-identifier or empty for auto-detect]` | Reduce spec ambiguity via targeted questions with adaptive auto-invocation (planning is 80% of success) |
| `/plan [feature-name or epic-slug]` | Generate implementation plan from spec using research-driven design (meta-prompting for epics) |
| `/tasks [--ui-first]` | Generate TDD task breakdown from plan.md with test-first sequencing and mockup-first mode (--ui-first) |
| `/validate [feature-slug] [--quick\|--constitution]` | Analyze spec, plan, and tasks for consistency violations, breaking changes, and constitution compliance. Generates analysis-report.md with CRITICAL/MAJOR/MINOR findings. |
| `/implement [feature-slug]` | Execute all implementation tasks from tasks.md with test-driven development, parallel batching, and atomic commits |
| `/optimize [feature-slug or empty for auto-detection]` | Run parallel quality gates (performance, security, accessibility, code review, migrations, Docker) and block deployment on failures |
| `/debug [feature-slug] [options]` | Execute systematic debugging workflow via spec-cli.py, track failures in error-log.md, and generate session reports |
| `/finalize` | Finalize documentation (CHANGELOG, README, help docs), update GitHub milestones/releases, and cleanup branches after production deployment |

**Usage Example:**
```bash
# Create specification
/spec "User authentication with OAuth 2.1"

# Clarify ambiguities
/clarify

# Generate implementation plan
/plan

# Break down into tasks (with UI-first mockups)
/tasks --ui-first

# Validate consistency
/validate

# Implement
/implement

# Run quality gates
/optimize

# Finalize after deployment
/finalize
```

---

## Epic Commands

Multi-sprint workflows for complex features (>16 hours, multiple subsystems).

| Command | Description |
|---------|-------------|
| `/epic [epic description \| slug \| continue \| next]` | Execute multi-sprint epic workflow from interactive scoping through deployment with parallel sprint execution and self-improvement |
| `/implement-epic [epic-slug]` | Execute multiple sprints in parallel based on dependency graph from sprint-plan.xml for epic workflows |

**Usage Example:**
```bash
# Start an epic
/epic "User authentication with OAuth 2.1"

# Resume epic
/epic continue

# Implement epic sprints in parallel
/implement-epic auth-system
```

**When to use `/epic` vs `/feature`:**
- Use `/epic` for: >16 hours, multiple subsystems, 2-5 sprints, >5 API endpoints, >3 database tables
- Use `/feature` for: ≤16 hours, single subsystem, 1 sprint, ≤5 endpoints, ≤3 tables

---

## Deployment Commands

Staging and production deployment workflows.

| Command | Description |
|---------|-------------|
| `/ship [continue\|status]` | Deploy feature through automated staging validation to production with rollback testing |
| `/ship-staging [feature-slug]` | Create PR to main with auto-merge, triggering staging deployment via CI/CD pipeline with health checks and deployment metadata capture |
| `/validate-staging` | Validate staging deployment before production through automated test review, rollback capability testing, and guided manual validation |
| `/ship-prod [--version major\|minor\|patch]` | Automated staging→production promotion via git tag creation, triggering GitHub Actions deployment, and creating GitHub release |
| `/deploy-prod` | Deploy feature directly to production by triggering GitHub Actions workflow, monitoring deployment, extracting rollback IDs, and verifying health |
| `/deploy-status` | Display comprehensive deployment workflow status showing current phase, completed tasks, quality gates, and deployment information |
| `/deployment-budget` | Display Vercel and Railway deployment quota usage with 24h rolling window analysis, quota reset predictions, and deployment strategy recommendations |
| `/validate-deploy [staging\|production]` | Validate deployment readiness by simulating production builds, Docker images, and migrations locally to catch failures before consuming CI/CD quota |

**Usage Example:**
```bash
# Deploy to staging (staging-prod model)
/ship-staging

# Validate staging deployment
/validate-staging

# Promote to production
/ship-prod

# Or direct to production (direct-prod model)
/deploy-prod

# Check deployment status
/deploy-status

# Check deployment quota
/deployment-budget
```

---

## Build Commands

Local builds and branch management.

| Command | Description |
|---------|-------------|
| `/build-local` | Build and validate locally for projects without remote deployment (prototypes, experiments, local-only dev) |
| `/branch-enforce [--fix] [--verbose] [--json] [--current-branch-only] [--max-hours N] [--warn-hours N] [--default-branch NAME] [--no-color]` | Audit branches for age violations and enforce trunk-based development (warn 18h, block 24h unless feature-flagged) |

**Usage Example:**
```bash
# Build locally (local-only model)
/build-local

# Check branch age
/branch-enforce

# Fix stale branches
/branch-enforce --fix
```

---

## Project Commands

Project initialization, roadmap management, and configuration.

| Command | Description |
|---------|-------------|
| `/init-project ["project-name"] [--with-design] [--update\|--force\|--write-missing-only] [--config FILE] [--ci] [--non-interactive]` | Generate 8 project design documents (overview, architecture, tech-stack, data, API, capacity, deployment, workflow) via interactive questionnaire or config file |
| `/init-brand-tokens` | Generate OKLCH design tokens with WCAG validation and Tailwind v4 integration by scanning existing code or creating new palette |
| `/roadmap [add\|brainstorm\|move\|delete\|search\|list\|milestone\|epic] [additional args]` | Manage product roadmap via GitHub Issues (brainstorm, prioritize, track). Auto-validates features against project vision (from overview.md) before adding to roadmap. |
| `/constitution <action>: <description>` | Add, update, or remove engineering principles in docs/project/engineering-principles.md with atomic versioned commits |
| `/update-project-config <configuration change description>` | Update project configuration settings (deployment model, scale tier, quick changes policy) with atomic commits |

**Usage Example:**
```bash
# Initialize project docs
/init-project

# Initialize with design system
/init-project --with-design

# Initialize brand tokens
/init-brand-tokens

# Manage roadmap
/roadmap add "User authentication"
/roadmap brainstorm
/roadmap list

# Update constitution
/constitution "add: A11Y - Accessibility | policy=WCAG 2.1 AA minimum"

# Update project config
/update-project-config "Change deployment model to staging-prod"
```

---

## Quality Commands

Quality gates and CI/CD integration.

| Command | Description |
|---------|-------------|
| `/fix-ci [pr-number]` | Diagnose and fix CI/deployment blockers for pull requests to enable safe deployment |
| `/gate-ci [--epic <epic-name>] [--verbose]` | Run CI quality gate checks (tests, linters, type checks, coverage ≥80%) before epic state transition |
| `/gate-sec` | Run security quality gate (SAST, secrets detection, dependency scanning) to ensure no HIGH/CRITICAL security issues before deployment |

**Usage Example:**
```bash
# Fix CI failures
/fix-ci 123

# Run CI quality gate
/gate-ci

# Run security gate
/gate-sec
```

---

## Infrastructure Commands

Workflow health monitoring and self-improvement.

| Command | Description |
|---------|-------------|
| `/audit-workflow` | Analyze workflow effectiveness and generate improvement recommendations after epic completion |
| `/heal-workflow` | Apply workflow improvements discovered during audit with approval workflow |
| `/workflow-health` | Display workflow health dashboard with velocity trends, quality metrics, and improvement tracking |

**Usage Example:**
```bash
# Audit workflow after epic
/audit-workflow

# Apply improvements
/heal-workflow

# View health dashboard
/workflow-health
/workflow-health --detailed
/workflow-health --trends
```

---

## Meta Commands

Developer tools for creating commands, skills, agents, and prompts.

| Command | Description |
|---------|-------------|
| `/add-to-todos <todo-description>` | Add todo item to TO-DOS.md with context from conversation |
| `/check-todos` | List outstanding todos and select one to work on |
| `/create-agent-skill [skill description or requirements]` | Create or edit Claude Code skills with expert guidance on structure and best practices |
| `/create-hook` | Invoke create-hooks skill for expert guidance on Claude Code hook development |
| `/create-meta-prompt [task description]` | Create optimized prompts for Claude-to-Claude pipelines (research → plan → implement) |
| `/create-prompt [task description]` | Expert prompt engineer that creates optimized, XML-structured prompts with intelligent depth selection |
| `/create-slash-command [command description or requirements]` | Create a new slash command following best practices and patterns |
| `/create-subagent [agent idea or description]` | Create specialized Claude Code subagents with expert guidance |
| `/audit-skill <skill-path>` | Audit skill for YAML compliance, pure XML structure, progressive disclosure, and best practices |
| `/audit-slash-command <command-path>` | Audit slash command file for YAML, arguments, dynamic context, tool restrictions, and content quality |
| `/audit-subagent <subagent-path>` | Audit subagent configuration for role definition, prompt quality, tool selection, XML structure compliance, and effectiveness |
| `/heal-skill [optional: specific issue to fix]` | Heal skill documentation by applying corrections discovered during execution with approval workflow |
| `/whats-next` | Analyze the current conversation and create a handoff document for continuing this work in a fresh context |
| `/run-prompt <prompt-number(s)-or-name> [--parallel\|--sequential]` | Delegate one or more prompts to fresh sub-task contexts with parallel or sequential execution |
| `/anti-duplication [optional: what you want to implement]` | Search codebase for existing patterns before implementing new code to prevent duplication |
| `/breaking-change-detector [optional: change description]` | Detect breaking API/schema/interface changes before implementation and suggest safe migration paths |
| `/caching-strategy [optional: operation to cache]` | Apply intelligent caching to avoid redundant work and speed up workflow execution by 20-40% |
| `/hallucination-detector [optional: technical suggestion to validate]` | Detect and prevent hallucinated technical decisions by validating against project's documented tech stack |
| `/parallel-optimize [optional: context or phase to optimize]` | Apply parallel execution optimization to detect and parallelize independent operations for 3-5x speedup |
| `/resolve-dependencies [package manager command, e.g., "npm install react@18"]` | Detect and resolve package dependency conflicts before installation (npm, pip, cargo, composer) |
| `/sync-task-status [optional task operation, e.g., "mark T001 complete"]` | Enforce atomic task status updates through task-tracker (prevent manual edits to NOTES.md/tasks.md) |
| `/enforce-git-commits [optional: phase/task context]` | Enforce git commits after phases/tasks with auto-commit and safety checks |
| `/announce-release [optional: version number]` | Post release announcement to X (Twitter) with GitHub link reply |

**Usage Example:**
```bash
# Create development artifacts
/create-slash-command "New command for XYZ"
/create-agent-skill "Skill for ABC"
/create-subagent "Agent for DEF"

# Audit artifacts
/audit-skill .claude/skills/my-skill/SKILL.md
/audit-slash-command .claude/commands/my-command.md

# Prevent issues
/anti-duplication "user authentication"
/breaking-change-detector "Change API endpoint /v1/users to /v2/users"
/hallucination-detector "Use React Query for data fetching"

# Optimize workflow
/parallel-optimize
/caching-strategy

# Task management
/add-to-todos "Investigate performance bottleneck"
/check-todos
```

---

## Internal Commands

Repository maintenance commands (not included in npm package).

| Command | Description |
|---------|-------------|
| `/create-prompt [task description]` | Expert prompt engineer that creates optimized, XML-structured prompts with intelligent depth selection |
| `/release [--skip-build] [--skip-npm] [--skip-github] [--announce]` | Automate complete release workflow for Spec-Flow package (version bump, CHANGELOG, git tag, GitHub release, npm publish) |
| `/repo-hygiene [check\|fix\|docs\|commands\|install\|all]` | Maintain public repository documentation, command inventory, installation guides, and file hygiene (internal use only - not in npm package) |

**Usage Example:**
```bash
# Release new version
/release

# Check repository hygiene
/repo-hygiene check

# Fix all hygiene issues
/repo-hygiene all
```

---

## Command Summary

**Total Commands: 62**

- Core: 4
- Phase: 9
- Epic: 2
- Deployment: 8
- Build: 2
- Project: 5
- Quality: 3
- Infrastructure: 3
- Meta: 23
- Internal: 3

---

## Getting Help

**In Claude Code:**
- Type `/help` to see context-aware guidance for your current workflow state
- Type `/help verbose` for detailed state information

**Documentation:**
- [Getting Started Guide](getting-started.md)
- [Architecture Overview](architecture.md)
- [CLAUDE.md](../CLAUDE.md) - Complete workflow reference

**Support:**
- [GitHub Issues](https://github.com/marcusgoll/Spec-Flow/issues)
- [README](../README.md)

---

*Last updated: 2025-11-20 | Spec-Flow v6.11.0*
