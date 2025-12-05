# CLAUDE.md Hierarchy Reference

**Purpose**: Technical reference for the hierarchical CLAUDE.md file structure used in the Spec-Flow workflow.

**Audience**: Contributors, advanced users, AI agents

**Version**: 10.7.0

---

## Table of Contents

1. [Architecture](#architecture)
2. [File Specifications](#file-specifications)
3. [Generation Scripts](#generation-scripts)
4. [Update Triggers](#update-triggers)
5. [Token Cost Analysis](#token-cost-analysis)
6. [Data Flow](#data-flow)
7. [Integration Points](#integration-points)

---

## Architecture

### Hierarchy Levels

```
Level 0: Root CLAUDE.md (workflow system)
  └─ Location: D:\Coding\workflow\CLAUDE.md
  └─ Scope: Essential instructions (WHAT/WHY/HOW), not reference material
  └─ Tokens: ~1,500 (87% reduction from v10.6.0)
  └─ Updates: Manually (workflow releases)
  └─ Deep dives: docs/references/*.md (progressive disclosure)

Level 1: Project CLAUDE.md (user repos)
  └─ Location: {project-root}/CLAUDE.md
  └─ Scope: Active features, tech stack, common patterns
  └─ Tokens: ~2,000 (vs 12,000 for all project docs)
  └─ Updates: /init-project, /ship-staging, /ship-prod

Level 2: Domain CLAUDE.md (future)
  └─ Location: {project-root}/backend/CLAUDE.md, frontend/CLAUDE.md
  └─ Scope: Domain-specific patterns, conventions
  └─ Tokens: ~1,000 (estimated)
  └─ Updates: On domain pattern discovery
  └─ Status: Phase 4 (future enhancement)

Level 3: Feature CLAUDE.md (user repos)
  └─ Location: {project-root}/specs/NNN-slug/CLAUDE.md
  └─ Scope: Current progress, specialists, navigation
  └─ Tokens: ~500 (vs 8,000 for all feature artifacts)
  └─ Updates: /feature, task-tracker, /feature continue
```

### Design Principles

1. **Cascading Context**: Each level provides progressively more specific context
2. **Token Efficiency**: Higher levels condense lower-level detail
3. **Context vs Instructions**: Auto-generated files aggregate STATUS/CONTEXT; human-written files contain BEHAVIORAL INSTRUCTIONS
4. **WHAT/WHY/HOW Framework**: Root CLAUDE.md uses structured sections for clarity
5. **Progressive Disclosure**: Deep dives live in docs/references/, not inline
6. **Deterministic Validation**: Scripts validate quality; Claude handles creative work
7. **Navigation First**: Links to detailed docs, not duplication

---

## File Specifications

### Level 0: Root CLAUDE.md

**Template**: N/A (manually maintained)

**Content Structure** (v10.7.0 WHAT/WHY/HOW framework):

```markdown
# CLAUDE.md

One-liner description of the project/workflow.

## WHAT This Is
Brief purpose and scope (2-3 paragraphs max).

## WHY This Approach Works
- Key principle 1
- Key principle 2
- Key principle 3

## HOW To Use It
### Quick Start
Essential commands and workflows.

### Essential Commands
Core command reference (brief).

### Deployment Models
staging-prod, direct-prod, local-only (brief).

### Quality Gates
Blocking and manual gates (brief).

### Directory Structure
Key directories only.

## Deep References
Links to docs/references/*.md for detailed documentation:
- Git Worktrees, Perpetual Learning, Workflow Detection, etc.

## Agent Briefs
Specialist categories (brief).

## Coding Standards
Essential conventions only.
```

**Key Distinction**: Root CLAUDE.md contains BEHAVIORAL INSTRUCTIONS (human-written).
Project and Feature CLAUDE.md files contain CONTEXT AGGREGATION (auto-generated).

**Progressive Disclosure**: Deep-dive content lives in `docs/references/`:
- git-worktrees.md, perpetual-learning.md, workflow-detection.md
- migration-safety.md, maker-error-correction.md, feedback-loops.md
- epic-blueprints.md, artifact-archival.md

**Generation**: Manual editing (workflow maintainers only)

**Target Length**: 200-300 lines (was 400-500 in v10.6.0)

**Quality Validation**: `.spec-flow/scripts/bash/audit-claude-md.sh`

---

### Level 1: Project CLAUDE.md

**Template**: Dynamic (no template file)

**Content Structure**:

```markdown
# Project Context

> **Purpose**: High-level project navigation
> **Token Cost**: ~2,000 tokens (vs 12,000 for all docs)
> **Last Updated**: {ISO 8601 timestamp}

## Active Features

- **{slug}**: Phase {phase} ({status})
  [From: specs/*/state.yaml]

## Tech Stack Summary

### Frontend

- {key technologies from docs/project/tech-stack.md}

### Backend

- {key technologies from docs/project/tech-stack.md}

### Database

- {key technologies from docs/project/tech-stack.md}

### Deployment

- {key technologies from docs/project/tech-stack.md}

## Common Patterns

- **{pattern-name}** - `{file-path}`
  [From: specs/*/plan.md REUSE sections]

## Quick Links

**Project Documentation**:

- [Overview](docs/project/overview.md)
- [Tech Stack](docs/project/tech-stack.md)
- [Data Architecture](docs/project/data-architecture.md)
- {... all project docs}

**Features**:

- [{slug}](specs/{slug}/CLAUDE.md)
  [For each feature with CLAUDE.md]
```

**Generation**:

- Script: `.spec-flow/scripts/bash/generate-project-claude-md.sh`
- PowerShell: `.spec-flow/scripts/powershell/generate-project-claude-md.ps1`

**Target Length**: 80-120 lines

**Data Sources**:

1. `specs/*/state.yaml` → Active features
2. `docs/project/tech-stack.md` → Tech stack (condensed)
3. `specs/*/plan.md` → Common patterns (REUSE sections)

---

### Level 3: Feature CLAUDE.md

**Template**: Dynamic (no template file)

**Content Structure**:

````markdown
# Feature: {Feature Name}

> **Purpose**: Quick context for AI
> **Token Cost**: ~500 tokens (vs 8,000 for all artifacts)
> **Last Updated**: {ISO 8601 timestamp}

## Current Phase

**Phase**: {phase}
**Status**: {status}
**Progress**: {completed}/{total} tasks ({percentage}%)
[From: state.yaml]

## Recent Progress

- ✅ {taskId}: {description} - {duration}min ({timestamp})
  [From: NOTES.md, last 3 completions]

**Velocity**: {avg}min/task | {rate}tasks/day | ETA: {eta}

## Relevant Specialists

### {Specialist Category}

- **Brief**: `.claude/agents/{category}/{agent}.md`
- **Capabilities**: {brief description}
- **When to use**: {usage guidance}
  [Phase-specific agents based on current phase]

## Quick Commands

```bash
# Continue implementation
/feature continue

# Update docs manually
{script command for this feature}

# Health check
.spec-flow/scripts/bash/health-check-docs.sh
```
````

## Navigation

**Artifacts**:

- [Spec](spec.md) - Requirements
- [Plan](plan.md) - Design
- [Tasks](tasks.md) - Checklist
- [NOTES](NOTES.md) - Journal

**State**:

- [state.yaml](state.yaml)

```

**Generation**:
- Script: `.spec-flow/scripts/bash/generate-feature-claude-md.sh`
- PowerShell: `.spec-flow/scripts/powershell/generate-feature-claude-md.ps1`

**Target Length**: 70-100 lines

**Data Sources**:
1. `state.yaml` → Current phase, status, progress
2. `NOTES.md` → Recent completions with timestamps
3. `tasks.md` → Total tasks, completion count
4. Phase mapping → Relevant specialist agents

---

## Generation Scripts

### generate-project-claude-md.sh

**Location**: `.spec-flow/scripts/bash/generate-project-claude-md.sh`

**Purpose**: Generate project-level CLAUDE.md aggregation

**Algorithm**:

```

1. Find Active Features:

   - Scan specs/\*/state.yaml
   - Extract phase and status
   - Filter: status != "completed" && status != "failed"

2. Extract Tech Stack:

   - Read docs/project/tech-stack.md
   - Extract sections: Frontend, Backend, Database, Deployment
   - Take first 5 bullet points per section

3. Extract Common Patterns:

   - Scan specs/\*/plan.md files
   - Find "### Reuse Additions" sections
   - Extract pattern names and paths
   - Deduplicate by name

4. Generate Markdown:
   - Combine all sections
   - Add timestamp
   - Write to CLAUDE.md (project root)

````

**Usage**:

```bash
# Generate to default location
.spec-flow/scripts/bash/generate-project-claude-md.sh

# Generate to custom location
.spec-flow/scripts/bash/generate-project-claude-md.sh --output /path/to/output.md

# JSON output for automation
.spec-flow/scripts/bash/generate-project-claude-md.sh --json
````

**Exit Codes**:

- 0: Success
- 1: Missing prerequisites (yq not found)

---

### generate-feature-claude-md.sh

**Location**: `.spec-flow/scripts/bash/generate-feature-claude-md.sh`

**Purpose**: Generate feature-level CLAUDE.md with current context

**Algorithm**:

```
1. Extract Current State:
   - Read state.yaml
   - Get: phase, status, completed_phases

2. Calculate Progress:
   - Count tasks in tasks.md (all)
   - Count completed tasks (marked [x] or [X])
   - Calculate percentage

3. Extract Recent Progress:
   - Read NOTES.md
   - Find last 3 lines matching: ✅ T\d+: .* - \d+min \(\d{4}-\d{2}-\d{2} \d{2}:\d{2}\)
   - Parse taskId, description, duration, timestamp

4. Calculate Velocity:
   - Average time per task (from NOTES.md)
   - Completion rate (tasks/day, last 2 days)
   - ETA based on remaining tasks

5. Determine Relevant Specialists:
   - Map current phase → agent categories
   - spec/clarify → [research, plan]
   - plan → [backend, frontend, database, api-contracts]
   - tasks → [task-breakdown]
   - implement → [backend, frontend, qa-tester, test-coverage]
   - optimize → [code-reviewer, qa-tester]
   - ship → [release, code-reviewer]

6. Generate Markdown:
   - Combine all sections
   - Add timestamp
   - Write to {feature-dir}/CLAUDE.md
```

**Usage**:

```bash
# Generate for specific feature
.spec-flow/scripts/bash/generate-feature-claude-md.sh specs/001-auth-flow

# JSON output
.spec-flow/scripts/bash/generate-feature-claude-md.sh specs/001-auth-flow --json
```

**Exit Codes**:

- 0: Success
- 1: Missing prerequisites (yq not found)
- 2: Feature directory not found

---

### extract-notes-summary.sh

**Location**: `.spec-flow/scripts/bash/extract-notes-summary.sh`

**Purpose**: Parse NOTES.md for recent task completions

**Algorithm**:

```
1. Read NOTES.md
2. Find lines matching pattern:
   ✅ T\d+: (.+?) - (\d+)min \((\d{4}-\d{2}-\d{2} \d{2}:\d{2})\)
3. Extract:
   - taskId (e.g., "T001")
   - description
   - duration (minutes)
   - timestamp (ISO format)
4. Return last N completions (default: 3)
```

**Usage**:

```bash
# Get last 3 completions
.spec-flow/scripts/bash/extract-notes-summary.sh specs/001-auth-flow

# Get last 5 completions
.spec-flow/scripts/bash/extract-notes-summary.sh --count 5 specs/001-auth-flow

# JSON output
.spec-flow/scripts/bash/extract-notes-summary.sh --json specs/001-auth-flow
```

---

### health-check-docs.sh

**Location**: `.spec-flow/scripts/bash/health-check-docs.sh`

**Purpose**: Detect stale CLAUDE.md files

**Algorithm**:

```
1. Find all CLAUDE.md files recursively
2. For each file:
   a. Get file modification time
   b. Calculate age in days
   c. Extract "Last Updated" timestamp from content (if present)
   d. Flag if age > threshold (default: 7 days)
3. Categorize:
   - stale: older than threshold
   - fresh: within threshold
   - warnings: missing "Last Updated" timestamp
4. Output report or JSON
```

**Usage**:

```bash
# Default 7-day threshold
.spec-flow/scripts/bash/health-check-docs.sh

# Custom threshold
.spec-flow/scripts/bash/health-check-docs.sh --max-age 3

# JSON output
.spec-flow/scripts/bash/health-check-docs.sh --json
```

**Exit Codes**:

- 0: All files fresh
- 1: Stale files detected

---

## Update Triggers

### Automatic Triggers

| Trigger             | Level   | Script                     | When                   |
| ------------------- | ------- | -------------------------- | ---------------------- |
| `/feature "desc"`   | Feature | generate-feature-claude-md | Feature creation       |
| `/feature continue` | Feature | generate-feature-claude-md | Resume feature         |
| Task completion     | Feature | generate-feature-claude-md | After task-tracker     |
| `/init-project`     | Project | generate-project-claude-md | Project initialization |
| `/ship-staging`     | Project | generate-project-claude-md | Staging deployment     |
| `/ship-prod`        | Project | generate-project-claude-md | Production deployment  |
| `/deploy-prod`      | Project | generate-project-claude-md | Direct prod deployment |

### Manual Triggers

```bash
# Regenerate feature CLAUDE.md
.spec-flow/scripts/bash/generate-feature-claude-md.sh specs/001-auth-flow

# Regenerate project CLAUDE.md
.spec-flow/scripts/bash/generate-project-claude-md.sh

# Regenerate all feature CLAUDE.md files
for dir in specs/*/; do
  .spec-flow/scripts/bash/generate-feature-claude-md.sh "$dir"
done
```

---

## Token Cost Analysis

### Traditional Approach (Before v4.0.0)

**Scenario**: Start work on feature with context loading

```
Step 1: Understand project
  Read docs/project/overview.md           → 1,500 tokens
  Read docs/project/tech-stack.md         → 2,000 tokens
  Read docs/project/data-architecture.md  → 1,800 tokens
  Read docs/project/api-strategy.md       → 1,200 tokens

Step 2: Understand feature
  Read specs/001-auth/spec.md             → 1,500 tokens
  Read specs/001-auth/plan.md             → 2,500 tokens
  Read specs/001-auth/tasks.md            → 1,200 tokens
  Read specs/001-auth/NOTES.md            →   800 tokens

Step 3: Check state
  Read specs/001-auth/state.yaml →   200 tokens

Total: 12,700 tokens
```

### Hierarchical CLAUDE.md Approach (v4.0.0+)

**Scenario**: Same context loading with hierarchy

```
Step 1: Understand project (aggregated)
  Read CLAUDE.md (project root)           → 2,000 tokens

Step 2: Understand feature (aggregated)
  Read specs/001-auth/CLAUDE.md           →   500 tokens

Step 3: Dive deeper if needed
  Read specs/001-auth/plan.md (100 lines) →   800 tokens

Total: 3,300 tokens (74% reduction)
```

### Token Savings by Scenario

| Scenario                | Traditional | Hierarchical | Savings |
| ----------------------- | ----------- | ------------ | ------- |
| Start new feature       | 12,700      | 2,500        | 80%     |
| Resume existing feature | 8,000       | 500          | 94%     |
| Switch between features | 8,000 × N   | 500 × N      | 94%     |
| Review project context  | 6,500       | 2,000        | 69%     |

---

## Data Flow

### Feature CLAUDE.md Generation

```
Input Sources:
  ├─ state.yaml
  │   └─ Extract: phase, status, completed_phases
  │
  ├─ tasks.md
  │   └─ Count: total tasks, completed tasks
  │
  ├─ NOTES.md
  │   └─ Parse: last 3 completions with timestamps
  │
  └─ Phase mapping (in script)
      └─ Map: phase → relevant specialist agents

Processing:
  ├─ Calculate progress percentage
  ├─ Calculate velocity metrics
  ├─ Determine ETA
  └─ Generate markdown sections

Output:
  └─ specs/NNN-slug/CLAUDE.md
      ├─ Header (purpose, token cost, timestamp)
      ├─ Current Phase section
      ├─ Recent Progress section
      ├─ Relevant Specialists section
      ├─ Quick Commands section
      └─ Navigation section
```

### Project CLAUDE.md Generation

```
Input Sources:
  ├─ specs/*/state.yaml (all features)
  │   └─ Extract: feature slug, phase, status
  │
  ├─ docs/project/tech-stack.md
  │   └─ Extract: Frontend, Backend, Database, Deployment sections
  │
  └─ specs/*/plan.md (all features)
      └─ Extract: Reuse Additions patterns

Processing:
  ├─ Filter active features (not completed/failed)
  ├─ Condense tech stack (first 5 items per section)
  ├─ Deduplicate patterns by name
  └─ Generate markdown sections

Output:
  └─ CLAUDE.md (project root)
      ├─ Header (purpose, token cost, timestamp)
      ├─ Active Features section
      ├─ Tech Stack Summary section
      ├─ Common Patterns section
      └─ Quick Links section
```

---

## Integration Points

### Workflow Commands

**`/feature` command** (`.claude/commands/feature.md`):

```bash
# Line ~50: After feature directory creation
echo "📝 Generating feature CLAUDE.md..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  pwsh -NoProfile -File .spec-flow/scripts/powershell/generate-feature-claude-md.ps1 -FeatureDir "$FEATURE_DIR"
else
  .spec-flow/scripts/bash/generate-feature-claude-md.sh "$FEATURE_DIR"
fi
```

**`/init-project` command** (`.claude/commands/init-project.md`):

```bash
# Line ~530: After project docs generation, before git commit
echo "📝 Generating project CLAUDE.md..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  pwsh -NoProfile -File .spec-flow/scripts/powershell/generate-project-claude-md.ps1
else
  .spec-flow/scripts/bash/generate-project-claude-md.sh
fi
```

**`/ship-prod` command** (`.claude/commands/ship-prod.md`):

```bash
# Line ~1195: After Phase 2.13.5, before Phase 2.14
echo "Regenerating project CLAUDE.md..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  pwsh -NoProfile -File .spec-flow/scripts/powershell/generate-project-claude-md.ps1 2>/dev/null || echo "⚠️  Non-blocking"
else
  .spec-flow/scripts/bash/generate-project-claude-md.sh 2>/dev/null || echo "⚠️  Non-blocking"
fi
```

### Task Tracker

**`task-tracker.ps1`** (`.spec-flow/scripts/powershell/task-tracker.ps1`):

```powershell
# Line ~200: After task completion, after NOTES.md update
$updateSummaryScript = Join-Path $PSScriptRoot "update-tasks-summary.ps1"
if (Test-Path $updateSummaryScript) {
    try {
        & $updateSummaryScript -FeatureDir $featureDir -ErrorAction SilentlyContinue | Out-Null
    } catch {
        Write-Warning "Could not update Progress Summary: $_"
    }
}

# Then regenerate feature CLAUDE.md
$generateScript = Join-Path $PSScriptRoot "generate-feature-claude-md.ps1"
if (Test-Path $generateScript) {
    try {
        & $generateScript -FeatureDir $featureDir -ErrorAction SilentlyContinue | Out-Null
    } catch {
        Write-Warning "Could not regenerate feature CLAUDE.md: $_"
    }
}
```

### Implement Command

**`/implement` command** (`.claude/commands/implement.md`):

```bash
# Line ~250: Living Documentation Updates section
# Provides examples for task agents to update spec.md, plan.md, feature CLAUDE.md
# Updates are optional (SHOULD) not required (MUST)
```

---

## Quality Validation (v10.7.0)

### audit-claude-md.sh

Deterministic validation of CLAUDE.md quality, avoiding the "LLM as linter" anti-pattern.

**Location**: `.spec-flow/scripts/bash/audit-claude-md.sh`

**Purpose**: Score CLAUDE.md files on quality metrics (0-100 scale)

**Scoring Weights**:
| Component | Weight |
|-----------|--------|
| Line count | 30% |
| Vague language | 25% |
| Strong modals (MUST/SHOULD/NEVER) | 15% |
| Required sections | 15% |
| External references | 10% |
| Freshness | 5% |

**Grades**:
- A (80-100): Excellent
- B (60-79): Good
- C (40-59): Needs Improvement
- F (0-39): Critical

**Usage**:
```bash
# Audit all CLAUDE.md files
.spec-flow/scripts/bash/audit-claude-md.sh --verbose

# Audit specific file
.spec-flow/scripts/bash/audit-claude-md.sh path/to/CLAUDE.md
```

### Hook Validation

**Location**: `.claude/hooks/claude-md-validator.sh`

**Purpose**: Warn-only validation on CLAUDE.md edits (non-blocking)

**Configuration**: `.spec-flow/config/claude-md-rules.yaml`

---

## Version History

| Version | Date       | Changes                                          |
| ------- | ---------- | ------------------------------------------------ |
| 10.7.0  | 2025-12-01 | WHAT/WHY/HOW framework, progressive disclosure, quality validation |
| 4.0.0   | 2025-11-08 | Initial release of hierarchical CLAUDE.md system |

---

## See Also

- [LIVING_DOCUMENTATION.md](LIVING_DOCUMENTATION.md) - User guide for living documentation
- [CHANGELOG.md](../CHANGELOG.md) - Full version history
- [README.md](../README.md) - Quick start guide
- [docs/references/](../references/) - Deep-dive reference documentation

---

_This reference is part of the Spec-Flow Workflow Kit v10.7.0. Last updated: 2025-12-01_
