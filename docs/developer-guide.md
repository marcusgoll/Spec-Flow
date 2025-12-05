# Spec-Flow Developer Guide

A comprehensive technical guide for developers using the Spec-Flow workflow toolkit with Claude Code.

---

## Table of Contents

1. [Quickstart](#quickstart)
2. [Core Concepts](#core-concepts)
   - [Slash Commands](#slash-commands)
   - [Subagents](#subagents)
   - [Hooks](#hooks)
3. [Workflow Walkthroughs](#workflow-walkthroughs)
   - [Project Initialization](#project-initialization-workflow)
   - [Feature Workflow](#feature-workflow)
   - [Epic Workflow](#epic-workflow)
   - [Quick Changes](#quick-changes-workflow)
4. [Slash Command Reference](#slash-command-reference)
5. [Subagent Reference](#subagent-reference)
6. [Hook Reference](#hook-reference)

---

## Quickstart

### Prerequisites

- Claude Code CLI installed and configured
- Git repository initialized
- Node.js/Python environment (depending on your stack)

### Your First Feature (5 minutes)

```bash
# 1. Initialize your project (one-time setup)
/init

# 2. Start a feature
/feature "Add user profile editing"

# That's it! The workflow automatically:
# - Creates specification (spec.md)
# - Generates implementation plan (plan.md)
# - Breaks down into tasks (tasks.md)
# - Implements with TDD
# - Runs quality gates
# - Deploys to staging/production
```

### Quick Fix (< 30 minutes)

```bash
# For small changes that don't need full planning
/quick "Fix login button alignment on mobile"
```

### Resume Interrupted Work

```bash
# If a session ends mid-workflow
/feature continue
# or
/epic continue
```

---

## Core Concepts

### Slash Commands

Slash commands are executable prompts that trigger specific workflows. They live in `.claude/commands/` and are invoked with `/command-name`.

**How They Work:**

1. You type `/feature "description"` in Claude Code
2. Claude reads the command file (`.claude/commands/core/feature.md`)
3. The command's instructions guide Claude through the workflow
4. Claude executes each step, creating artifacts and updating state

**Anatomy of a Slash Command:**

```yaml
---
name: feature
description: Execute feature development workflow
argument-hint: [description|continue|next]
allowed-tools: [Read, Write, Edit, Bash, Task]
---

# Command content with XML-structured instructions
<objective>What this command does</objective>
<process>Step-by-step execution guide</process>
<success_criteria>Definition of done</success_criteria>
```

**Key Properties:**

| Property | Purpose |
|----------|---------|
| `description` | Shown in `/help` listings |
| `argument-hint` | Shows expected input format |
| `allowed-tools` | Restricts which tools Claude can use |

**Command Organization:**

```
.claude/commands/
├── core/           # Primary user commands (feature, help, quick)
├── phases/         # Workflow phases (spec, plan, tasks, implement, optimize)
├── deployment/     # Shipping commands (ship, ship-staging, ship-prod)
├── quality/        # Quality gates (gate, fix-ci)
├── project/        # Project management (roadmap, constitution)
├── epic/           # Epic orchestration
├── meta/           # Tooling creation (create, context)
└── infrastructure/ # Workflow maintenance (audit-workflow, heal-workflow)
```

---

### Subagents

Subagents are specialized AI assistants that handle specific domains. They're launched via the `Task` tool and run in isolated contexts.

**How They Work:**

1. A slash command (like `/implement`) needs specialized work done
2. It launches a subagent via `Task(subagent_type: "backend-dev", ...)`
3. The subagent reads its brief from `.claude/agents/` and executes
4. Results are returned to the parent command

**Anatomy of a Subagent:**

```yaml
---
name: backend-dev
description: Implements FastAPI backend features using TDD
model: sonnet  # or opus, haiku
tools: Read, Write, Edit, Bash, Grep, Glob
---

<role>Your expertise and mission</role>
<technical_stack>Fixed technologies to use</technical_stack>
<workflow>Step-by-step execution process</workflow>
<constraints>Rules and limitations</constraints>
<output_format>Expected return structure</output_format>
```

**Agent Categories:**

| Category | Agents | Purpose |
|----------|--------|---------|
| **Phase** | spec, plan, tasks, validate, implement, optimize, ship | Workflow phase execution |
| **Implementation** | backend-dev, frontend-dev, database-architect, api-contracts | Domain-specific coding |
| **Quality** | code-reviewer, security-sentry, performance-profiler | Code quality assurance |
| **Testing** | qa-tester, test-coverage, api-fuzzer, accessibility-auditor | Test creation and auditing |
| **Operations** | ci-sentry, data-modeler, observability-plumber | Infrastructure and ops |

**When Subagents Are Used:**

- `/implement` launches `backend-dev`, `frontend-dev`, `database-architect` in parallel
- `/optimize` launches quality agents for security, performance, accessibility checks
- Complex tasks that benefit from specialized expertise

---

### Hooks

Hooks are shell scripts that execute automatically in response to Claude Code events. They enable workflow state persistence across sessions.

**How They Work:**

1. Configure hooks in `.claude/settings.local.json`
2. When an event occurs (session start, stop, compact), the hook script runs
3. The script receives JSON input on stdin with event details
4. The script's stdout is displayed to the user

**Hook Events:**

| Event | Trigger | Use Case |
|-------|---------|----------|
| `SessionStart` | Claude Code session begins | Restore workflow state, display context |
| `Stop` | Session ends | Save checkpoint, warn about uncommitted work |
| `PreCompact` | Before context compaction | Generate handoff document for next context |
| `PreToolUse` | Before a tool runs | Validate or modify tool calls |
| `PostToolUse` | After a tool runs | Track changes, validate results |

**Configuration Example:**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/session-start-restore.sh"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/pre-compact-handoff.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/stop-checkpoint.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Workflow Walkthroughs

### Project Initialization Workflow

**Command:** `/init`

**Purpose:** Set up project documentation and configuration. Run once when starting a new project.

**What It Does:**

1. **Project Documentation** (`/init` or `/init project-name`)
   - Runs interactive questionnaire (15 questions)
   - Generates 8 docs in `docs/project/`:
     - `overview.md` - Project vision and goals
     - `system-architecture.md` - High-level architecture
     - `tech-stack.md` - Technologies and versions
     - `data-architecture.md` - Database and data flow
     - `api-strategy.md` - API design principles
     - `capacity-planning.md` - Scale and performance targets
     - `deployment-strategy.md` - CI/CD and environments
     - `development-workflow.md` - Team practices

2. **User Preferences** (`/init --preferences`)
   - Configures command defaults
   - Sets automation levels (auto-approve, CI mode)
   - Enables/disables learning features

3. **Design Tokens** (`/init --tokens`)
   - Generates OKLCH color palette with WCAG validation
   - Creates `design/systems/tokens.css` and `tokens.json`
   - Sets up Tailwind v4 integration

**Example Session:**

```bash
# Full project setup
/init

# Output:
# Starting project initialization...
#
# Question 1/15: What is your project name?
# [User answers questions...]
#
# Generated:
# - docs/project/overview.md
# - docs/project/system-architecture.md
# - docs/project/tech-stack.md
# - docs/project/data-architecture.md
# - docs/project/api-strategy.md
# - docs/project/capacity-planning.md
# - docs/project/deployment-strategy.md
# - docs/project/development-workflow.md
```

**Variants:**

```bash
/init                      # Project docs (interactive)
/init --preferences        # Configure user defaults
/init --tokens             # Generate design tokens
/init --with-design        # Project docs + design system
/init --ci                 # Non-interactive mode
```

---

### Feature Workflow

**Command:** `/feature "description"`

**Purpose:** Develop a single-subsystem feature from idea to production.

**Typical Duration:** 2-8 hours

**Phase Sequence:**

```
/feature "Add dark mode toggle"
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 0: Specification (/spec)                              │
│ - Analyzes requirements                                     │
│ - Creates spec.md with FR/NFR requirements                  │
│ - Generates user scenarios (Gherkin format)                 │
│ - If ambiguity detected → auto-runs /clarify                │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: Planning (/plan)                                   │
│ - Researches existing code for reuse                        │
│ - Designs architecture approach                             │
│ - Creates plan.md with implementation strategy              │
│ - Identifies reusable components                            │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 2: Task Breakdown (/tasks)                            │
│ - Creates concrete TDD tasks (20-30 tasks typical)          │
│ - Orders by dependency and domain                           │
│ - Generates tasks.md with acceptance criteria               │
│ - UI-first mode: --ui-first creates mockups first           │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 3: Validation (/phases:validate)                      │
│ - Cross-checks spec, plan, and tasks for consistency        │
│ - Identifies breaking changes                               │
│ - Generates analysis-report.md                              │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 4: Implementation (/implement)                        │
│ - Executes tasks with TDD (Red → Green → Refactor)          │
│ - Launches specialist agents in parallel                    │
│ - Updates task checkboxes as completed                      │
│ - Commits atomically per task                               │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 5: Optimization (/optimize)                           │
│ - Performance benchmarking                                  │
│ - Security scanning                                         │
│ - Accessibility audit (WCAG 2.1 AA)                         │
│ - Code quality review                                       │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 6-7: Deployment (/ship)                               │
│ - Deploys to staging (if staging-prod model)                │
│ - Runs automated validation                                 │
│ - Promotes to production                                    │
│ - Creates GitHub release                                    │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 8: Finalization (/finalize)                           │
│ - Updates CHANGELOG                                         │
│ - Archives artifacts to completed/                          │
│ - Updates roadmap status                                    │
└─────────────────────────────────────────────────────────────┘
```

**Artifacts Created:**

```
specs/001-dark-mode-toggle/
├── spec.md              # Requirements and scenarios
├── plan.md              # Architecture and approach
├── tasks.md             # Implementation tasks
├── NOTES.md             # Session notes and decisions
├── state.yaml           # Workflow state tracking
├── checklists/          # Quality checklists
├── mockups/             # HTML mockups (if UI-first)
└── visuals/             # Diagrams and screenshots
```

**Usage Examples:**

```bash
# Start new feature from description
/feature "Add user profile editing with avatar upload"

# Start from GitHub issue
/feature next                    # Picks highest priority issue

# Resume interrupted feature
/feature continue

# Start feature from epic sprint
/feature epic:auth:sprint:S02
```

---

### Epic Workflow

**Command:** `/epic "goal"`

**Purpose:** Orchestrate complex multi-sprint features that span multiple subsystems.

**Typical Duration:** 1-4 weeks (multiple sprints)

**When to Use Epic vs Feature:**

| Characteristic | Feature | Epic |
|----------------|---------|------|
| Duration | < 16 hours | > 16 hours |
| Sprints | 1 | 2+ |
| Subsystems | Single | Multiple |
| Parallelization | Within sprint | Across sprints |

**Phase Sequence:**

```
/epic "User authentication with OAuth 2.1"
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 0: Auto-Initialize (if needed)                         │
│ - Checks for docs/project/                                   │
│ - Prompts to run /init if missing                            │
│ - Checks for prototype (optional UI sync)                    │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Epic Specification                                   │
│ - Interactive scoping (8-9 structured questions)             │
│ - Creates epic-spec.md                                       │
│ - Identifies subsystems involved                             │
│ - Estimates complexity (small/medium/large)                  │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 2: Clarification (if needed)                            │
│ - Runs ambiguity score algorithm                             │
│ - Auto-runs /clarify if score > 30                           │
│ - Updates epic-spec.md with answers                          │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 3: Meta-Prompting Research & Planning                   │
│ - Launches isolated research agent                           │
│ - Creates research.md with findings                          │
│ - Launches isolated planning agent                           │
│ - Creates plan.md with architecture                          │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 4: Sprint Breakdown                                     │
│ - Analyzes plan complexity                                   │
│ - Creates sprint-plan.md with dependency graph               │
│ - Identifies parallel execution layers                       │
│ - Locks API contracts for parallel work                      │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 5: Parallel Sprint Implementation (/implement-epic)     │
│ - Executes sprints in dependency order                       │
│ - Parallel execution within each layer                       │
│ - Continuous validation (TDD, type safety)                   │
│ - Progress: "Layer 1/3: S01 ✓, Layer 2/3: S02 → 65%"        │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 6: Optimization & Quality Gates (/optimize)             │
│ - Cross-sprint quality checks                                │
│ - Integration testing                                        │
│ - Workflow audit for effectiveness                           │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 7: Unified Deployment (/ship)                           │
│ - Auto-detects deployment model                              │
│ - Deploys all sprints together                               │
│ - Creates GitHub release                                     │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 8: Walkthrough & Self-Improvement (/finalize)           │
│ - Generates walkthrough.md (comprehensive post-mortem)       │
│ - Runs /audit-workflow for pattern detection                 │
│ - Applies /heal-workflow for improvements                    │
│ - Updates project documentation                              │
└─────────────────────────────────────────────────────────────┘
```

**Artifacts Created:**

```
epics/001-oauth-auth/
├── epic-spec.md         # Epic requirements and scope
├── research.md          # Technical research findings
├── plan.md              # Architecture and approach
├── sprint-plan.md       # Dependency graph and layers
├── tasks.md             # All tasks across sprints
├── walkthrough.md       # Post-mortem and lessons
├── state.yaml           # Workflow state
├── NOTES.md             # Session notes
├── sprints/
│   ├── S01/             # Sprint 1 implementation
│   ├── S02/             # Sprint 2 implementation
│   └── S03/             # Sprint 3 implementation
├── contracts/
│   └── api/             # Locked API contracts
└── artifacts/           # Supporting documents
```

**Usage Examples:**

```bash
# Start new epic
/epic "User authentication with OAuth 2.1, MFA, and session management"

# Resume epic
/epic continue

# Start next priority epic from backlog
/epic next
```

---

### Quick Changes Workflow

**Command:** `/quick "description"`

**Purpose:** Implement small changes without full workflow overhead.

**Typical Duration:** < 30 minutes

**Scope Limits:**

- Less than 100 lines of code
- Fewer than 5 files
- Single concern
- No breaking changes

**Good Candidates:**

| Type | Examples |
|------|----------|
| Bug fixes | UI glitches, logic errors, null checks |
| Small refactors | Rename variables, extract functions |
| Internal improvements | Logging, error messages, constants |
| Documentation | README updates, code comments |
| Config tweaks | Environment variables, build settings |

**Not Suitable For:**

- New features with UI components
- Database schema changes
- API contract changes
- Security-sensitive code
- Changes affecting > 5 files

**Process:**

```
/quick "Fix login button alignment on mobile"
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. Validate Scope                                            │
│ - Checks if change is appropriate for /quick                 │
│ - Recommends /feature if too complex                         │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Detect Domain                                             │
│ - Identifies if frontend, backend, or docs                   │
│ - Routes to appropriate specialist agent                     │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Create Branch                                             │
│ - Creates quick/fix-login-button-alignment                   │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Implement                                                 │
│ - Makes targeted changes                                     │
│ - Follows existing patterns                                  │
│ - If UI change: enforces style guide                         │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Run Tests                                                 │
│ - Auto-detects test framework                                │
│ - Runs relevant tests                                        │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Commit                                                    │
│ - Creates atomic commit                                      │
│ - Shows summary and next steps                               │
└─────────────────────────────────────────────────────────────┘
```

**Output:**

```
✅ Quick change complete!

Branch: quick/fix-login-button-alignment
Files changed: 1
Commit: a1b2c3d

Next steps:
  • Review changes: git show
  • Merge to main: git checkout main && git merge quick/fix-login-button-alignment
  • Push: git push origin main
```

---

## Slash Command Reference

### Core Commands

| Command | Purpose |
|---------|---------|
| `/feature [desc\|continue\|next]` | Feature development workflow |
| `/epic [desc\|continue\|next]` | Multi-sprint epic workflow |
| `/quick <description>` | Quick implementation (< 100 LOC) |
| `/help [verbose]` | Context-aware guidance |
| `/init [--preferences\|--tokens]` | Project initialization |

### Phase Commands

| Command | Purpose | Artifacts |
|---------|---------|-----------|
| `/spec <description>` | Generate specification | spec.md, NOTES.md |
| `/clarify` | Resolve ambiguities | Updated spec.md |
| `/plan` | Generate implementation plan | plan.md, research.md |
| `/tasks [--ui-first]` | Create TDD task breakdown | tasks.md |
| `/phases:validate` | Cross-artifact analysis | analysis-report.md |
| `/implement` | Execute tasks with TDD | Code, tests, commits |
| `/optimize` | Quality gates | optimization-report.md |
| `/finalize` | Complete workflow | CHANGELOG, archives |
| `/phases:debug` | Debug errors | error-log.md |

### Deployment Commands

| Command | Purpose |
|---------|---------|
| `/ship` | Unified deployment orchestrator |
| `/ship [continue\|status]` | Resume or check deployment |
| `/deployment:ship-staging` | Deploy to staging |
| `/deployment:ship-prod` | Promote to production |
| `/deployment:deploy-status` | Check deployment status |
| `/deployment:validate-staging` | Manual staging validation |
| `/deployment:validate-deploy` | Validate without deploying |
| `/deployment:deployment-budget` | Check deployment quotas |
| `/build:build-local` | Local build (no deployment) |

### Quality Commands

| Command | Purpose |
|---------|---------|
| `/quality:gate` | Run quality checks |
| `/quality:fix-ci [pr-number]` | Fix CI blockers |

### Project Commands

| Command | Purpose |
|---------|---------|
| `/project:roadmap [action]` | Manage product roadmap |
| `/project:constitution <action>` | Update engineering principles |
| `/project:prototype [action]` | Manage project prototype |
| `/project:init-brand-tokens` | Generate design tokens |

### Meta Commands

| Command | Purpose |
|---------|---------|
| `/meta:create [prompt\|command\|agent]` | Create custom tooling |
| `/meta:context [next\|todos\|add]` | Context management |
| `/meta:run-prompt <number>` | Execute stored prompts |

### Infrastructure Commands

| Command | Purpose |
|---------|---------|
| `/infrastructure:audit-workflow` | Audit workflow effectiveness |
| `/infrastructure:heal-workflow` | Apply workflow improvements |
| `/infrastructure:workflow-health` | Display health dashboard |

---

## Subagent Reference

### Phase Agents

| Agent | Purpose | Triggered By |
|-------|---------|--------------|
| `spec-phase-agent` | Create feature specifications | `/spec` |
| `clarify-phase-agent` | Resolve ambiguities | `/clarify` |
| `plan-phase-agent` | Generate implementation plans | `/plan` |
| `tasks-phase-agent` | Create TDD task breakdown | `/tasks` |
| `analyze-phase-agent` | Cross-artifact validation | `/phases:validate` |
| `optimize-phase-agent` | Quality optimization | `/optimize` |
| `ship-staging-phase-agent` | Staging deployment | `/ship` |
| `ship-prod-phase-agent` | Production deployment | `/ship` |
| `finalize-phase-agent` | Workflow completion | `/finalize` |
| `epic` | Epic orchestration | `/epic` |

### Implementation Agents

| Agent | Domain | Key Capabilities |
|-------|--------|------------------|
| `backend-dev` | FastAPI/Python | TDD, contract-first, performance validation |
| `frontend-dev` | Next.js/React | TDD, design system compliance, accessibility |
| `database-architect` | PostgreSQL | Schema design, migrations, optimization |
| `api-contracts` | OpenAPI/GraphQL | Contract management, SDK generation |
| `platform` | CI/CD | Deployment, feature flags, infrastructure |
| `test-architect` | Testing | TDD, test specification, fixtures |
| `qa-tester` | QA | Automated test suites, QA plans |

### Quality Agents

| Agent | Focus | Standards |
|-------|-------|-----------|
| `code-reviewer` | Contract compliance | KISS/DRY principles |
| `refactor-planner` | Refactoring plans | Risk assessment |
| `refactor-surgeon` | Surgical refactoring | Minimal blast radius |
| `type-enforcer` | TypeScript safety | No implicit any |
| `cleanup-janitor` | Dead code removal | Deletion over addition |

### Testing Agents

| Agent | Focus | Standards |
|-------|-------|-----------|
| `test-coverage` | Coverage gaps | Behavior verification |
| `api-fuzzer` | API security | Malicious payload testing |
| `accessibility-auditor` | WCAG compliance | WCAG 2.1 AA |
| `ux-polisher` | UI polish | Design system consistency |
| `design-lint` | Design validation | Token compliance |
| `design-scout` | Component reuse | Pattern consistency |

### Security & Performance Agents

| Agent | Focus | Thresholds |
|-------|-------|------------|
| `security-sentry` | Vulnerability assessment | CRITICAL/HIGH blocking |
| `performance-profiler` | Bottleneck elimination | >200ms API triggers |
| `error-budget-guardian` | SLO risk assessment | Hot path protection |
| `observability-plumber` | Logging and tracing | Production debugging |

### Operations Agents

| Agent | Focus | Use Case |
|-------|-------|----------|
| `ci-sentry` | CI/CD pipeline | Flaky test triage, cache optimization |
| `data-modeler` | Database migrations | Zero-downtime patterns |
| `dependency-curator` | Package management | Security, bundle size |
| `debugger` | Bug investigation | Root cause analysis |
| `web-research-specialist` | Technical research | GitHub Issues, Stack Overflow |

### Documentation Agents

| Agent | Focus | Artifacts |
|-------|-------|-----------|
| `docs-scribe` | ADRs, CHANGELOG | Architecture decisions |
| `git-steward` | Git hygiene | Atomic commits, PR descriptions |
| `release-manager` | Release preparation | Notes, upgrade guides |
| `ci-cd-release` | Release automation | GitHub Actions, rollback |

---

## Hook Reference

### session-start-restore.sh

**Event:** `SessionStart` (startup, resume, compact)

**Purpose:** Restore workflow state when a session begins.

**Behavior:**

1. Detects active workflow (feature or epic)
2. Reads `state.yaml` for current phase and status
3. Displays restoration banner with context
4. Sets environment variables for session
5. Shows handoff document if available

**Output Example:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Active Workflow Detected
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Type:   feature
  Slug:   001-dark-mode-toggle
  Title:  Add dark mode toggle to settings
  Phase:  implement
  Status: in_progress
  Tasks:  12/25 completed

  Continue: /feature continue

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### stop-checkpoint.sh

**Event:** `Stop` (session end)

**Purpose:** Save checkpoint when session ends.

**Behavior:**

1. Detects active workflow
2. Updates `state.yaml` with checkpoint timestamp
3. Adds session marker to `NOTES.md`
4. Warns about uncommitted changes
5. Optionally blocks stop if autopilot enabled

**Output Example:**

```
Warning: 3 uncommitted changes in working directory
Consider committing before ending session to preserve work.

Checkpoint saved for feature: 001-dark-mode-toggle
Phase: implement | Status: in_progress

Resume with: /feature continue
```

---

### pre-compact-handoff.sh

**Event:** `PreCompact` (before context compaction)

**Purpose:** Generate handoff document before context is lost.

**Behavior:**

1. Creates `sessions/handoff-{timestamp}.md`
2. Captures current phase, status, and progress
3. Extracts recent notes and decisions
4. Lists key artifacts for next context
5. Provides quick resume command

**Handoff Document Structure:**

```markdown
# Session Handoff: 001-dark-mode-toggle

> Generated: 2025-12-04T10:30:00Z
> Phase: implement
> Status: in_progress

## Quick Resume

/feature continue

## Current State

| Metric | Value |
|--------|-------|
| Tasks Progress | 12 / 25 |
| Current Phase | implement |

## Next Task

T013: Implement theme toggle component

## Key Artifacts

- State: specs/001-dark-mode-toggle/state.yaml
- Tasks: specs/001-dark-mode-toggle/tasks.md
- Plan: specs/001-dark-mode-toggle/plan.md

## Recent Activity

[Last 10 lines from NOTES.md]
```

---

### Configuration

**File:** `.claude/settings.local.json`

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/session-start-restore.sh"
          }
        ]
      },
      {
        "matcher": "resume",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/session-start-restore.sh"
          }
        ]
      },
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/session-start-restore.sh"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/pre-compact-handoff.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/stop-checkpoint.sh"
          }
        ]
      }
    ]
  },
  "disableAllHooks": false
}
```

---

## Additional Resources

- **README.md** - Quick start guide
- **docs/commands.md** - Detailed command documentation
- **docs/architecture.md** - System architecture
- **CHANGELOG.md** - Version history
- **.claude/skills/** - Skill documentation for advanced usage
