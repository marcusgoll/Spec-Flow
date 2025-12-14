# Agent Routing Guide

> When to use which agent for implementation work

## Quick Decision Tree

```
Is this a workflow phase (spec, plan, tasks, optimize, ship)?
├── Yes → Use PHASE AGENT (spec-agent, plan-agent, etc.)
└── No → Continue...

Is domain-memory.yaml present?
├── Yes → Use WORKER (domain/worker.md)
│         Worker reads domain memory, picks ONE feature, implements, exits
└── No → Continue...

Is this sprint-level work in an epic?
├── Yes → Use SPECIALIST based on sprint domain:
│         • Backend-only sprint → backend-dev
│         • Frontend-only sprint → frontend-dev
│         • Database sprint → database-architect
│         • Testing sprint → qa-test
│         • Mixed/unclear → general-purpose
└── No → Use WORKER with initialized domain memory
```

## Agent Categories

### 1. Phase Agents (Workflow Orchestration)

**Location**: `.claude/agents/phase/*-agent.md`

**When to use**: Always spawned by orchestrator commands (`/feature`, `/epic`), never directly.

| Agent | Spawned By | Purpose |
|-------|------------|---------|
| spec-agent | /feature, /epic | Generate specification |
| clarify-agent | /clarify | Resolve ambiguities |
| plan-agent | /plan | Create implementation plan |
| tasks-agent | /tasks | Break down into TDD tasks |
| optimize-agent | /optimize | Run quality gates |
| ship-agent | /ship | Handle deployment |
| finalize-agent | /finalize | Archive and document |

**Key trait**: Return structured results (`---COMPLETED---`, `---NEEDS_INPUT---`, `---FAILED---`)

### 2. Worker Agent (Atomic Implementation)

**Location**: `.claude/agents/domain/worker.md`

**When to use**:
- `domain-memory.yaml` exists in feature/sprint directory
- Implementing individual features from a backlog
- Default for `/implement` phase

**How it works**:
1. Reads domain-memory.yaml
2. Picks ONE failing/untested feature
3. Implements with TDD
4. Updates domain-memory.yaml
5. Commits and EXITs (even if more work remains)

**Key trait**: Atomic, stateless, disciplined. Never works on more than one feature.

**Example spawn**:
```
Task tool call:
  subagent_type: "worker"
  prompt: |
    Implement ONE feature from domain memory.
    Feature directory: specs/001-auth
    Domain memory: specs/001-auth/domain-memory.yaml
```

### 3. Specialist Agents (Domain Experts)

**Location**: `.claude/agents/implementation/*.md`

**When to use**:
- Sprint-level work in epics (no domain-memory.yaml)
- Clear domain boundary (backend-only, frontend-only)
- Complex domain-specific work requiring deep expertise

| Agent | Use When |
|-------|----------|
| backend-dev | API endpoints, services, business logic |
| frontend-dev | UI components, pages, client-side |
| database-architect | Schemas, migrations, queries |
| api-contracts | OpenAPI specs, SDK generation |
| qa-test | Test creation, coverage gaps |

**Example spawn**:
```
Task tool call:
  subagent_type: "backend-dev"
  prompt: |
    Implement Sprint S01: Backend API
    Sprint directory: epics/001-app/sprints/S01
    Tasks: epics/001-app/sprints/S01/tasks.md
```

### 4. Quality Agents (Code Review & Analysis)

**Location**: `.claude/agents/quality/**/*.md`

**When to use**: Quality checks, not implementation. Spawned by `/optimize`, `/review`, etc.

| Agent | Purpose |
|-------|---------|
| code-reviewer | Review code for issues |
| security-sentry | Security vulnerability scan |
| accessibility-auditor | WCAG compliance |
| performance-profiler | Performance analysis |
| type-enforcer | TypeScript strict checking |

## Common Patterns

### Pattern 1: Feature Implementation (Default)

```
/feature "Add auth" →
  1. Orchestrator creates specs/001-auth/
  2. Spawns spec-agent → spec.md
  3. Spawns plan-agent → plan.md
  4. Spawns tasks-agent → tasks.md
  5. Initializes domain-memory.yaml
  6. Loop: Spawns worker → implements ONE feature → exits
  7. When all features done → spawns optimize-agent
```

**Agent flow**: Phase agents → Worker (looped) → Quality agents

### Pattern 2: Epic with Sprints

```
/epic "Build app" →
  1. Orchestrator creates epics/001-app/
  2. Spawns spec-agent → epic-spec.md
  3. Spawns plan-agent → plan.md + sprint-plan.md
  4. Creates sprint directories
  5. For each layer (parallel within layer):
     - Backend sprints → backend-dev agent
     - Frontend sprints → frontend-dev agent
  6. After all layers → optimize-agent
```

**Agent flow**: Phase agents → Specialists (parallel per layer) → Quality agents

### Pattern 3: Epic with Domain Memory (Hybrid)

```
/epic with domain-memory.yaml per sprint →
  1. Same as Pattern 2, but...
  2. Each sprint uses workers instead of specialists
  3. Worker reads sprint's domain-memory.yaml
  4. Implements one feature at a time
```

**When to use**: When sprint tasks are granular and benefit from atomic execution

## Decision Examples

### Example 1: "Add login endpoint"
- Single feature → /feature workflow
- domain-memory.yaml will be created
- **Use: worker** (loops until all features done)

### Example 2: "Build e-commerce checkout" (epic)
- Multiple subsystems → /epic workflow
- Sprint S01 is backend-only, S02 is frontend-only
- **Use: backend-dev for S01, frontend-dev for S02**

### Example 3: "Fix 5 bugs in auth module"
- Small scope → /quick workflow
- No domain memory (too small)
- **Use: quick-worker** (direct implementation)

### Example 4: "Refactor database schema"
- Database-focused work
- **Use: database-architect** (specialist)

## Anti-Patterns

### ❌ Don't: Use specialist when domain-memory exists
If `domain-memory.yaml` is present, the worker pattern is expected. Using a specialist would bypass the atomic feature tracking.

### ❌ Don't: Use worker for phase work
Workers implement features, not workflow phases. Spec generation needs spec-agent, not worker.

### ❌ Don't: Mix specialists in same sprint
Each sprint should have ONE agent type. Don't spawn backend-dev AND frontend-dev for same sprint.

### ❌ Don't: Spawn agents directly as user
Agents are spawned by orchestrator commands. Users run `/feature`, `/epic`, `/implement` - not Task(agent).

## Routing Logic for implement-epic.md

When implementing a sprint, determine agent type:

```bash
# Check if sprint has domain-memory.yaml
if [ -f "${SPRINT_DIR}/domain-memory.yaml" ]; then
    AGENT_TYPE="worker"
else
    # Route by subsystem from sprint-plan.md
    SUBSYSTEM=$(get_sprint_subsystem "$SPRINT_ID")
    case "$SUBSYSTEM" in
        backend|api)      AGENT_TYPE="backend-dev" ;;
        frontend|ui)      AGENT_TYPE="frontend-dev" ;;
        database)         AGENT_TYPE="database-architect" ;;
        testing)          AGENT_TYPE="qa-test" ;;
        *)                AGENT_TYPE="general-purpose" ;;
    esac
fi
```

## Summary Table

| Situation | Agent | Why |
|-----------|-------|-----|
| Workflow phase (spec, plan, etc.) | Phase agent | Structured phase execution |
| domain-memory.yaml exists | worker | Atomic feature implementation |
| Backend sprint (no DM) | backend-dev | Domain expertise |
| Frontend sprint (no DM) | frontend-dev | Domain expertise |
| Database work | database-architect | Schema expertise |
| Quality checks | Quality agents | Analysis, not implementation |
| Quick fix (<100 LOC) | quick-worker | Fast, direct |
