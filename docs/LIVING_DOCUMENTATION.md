# Living Documentation Guide

**Purpose**: Learn how to use hierarchical CLAUDE.md files for efficient AI context navigation and automatic documentation updates.

**Version**: 4.0.0

---

## Table of Contents

1. [Overview](#overview)
2. [Hierarchy](#hierarchy)
3. [Token Efficiency](#token-efficiency)
4. [Automatic Updates](#automatic-updates)
5. [Health Checks](#health-checks)
6. [Usage Examples](#usage-examples)
7. [Troubleshooting](#troubleshooting)

---

## Overview

Living documentation is a paradigm shift from traditional static docs:

| **Traditional Documentation** | **Living Documentation** |
|-------------------------------|--------------------------|
| Static markdown files | Auto-updated with code changes |
| Becomes stale after weeks | Always fresh (timestamps) |
| Manual sync required | Atomic updates during workflow |
| 12,000 tokens to read all docs | 500 tokens for context navigation |
| No velocity tracking | Real-time progress metrics |

**Key Benefit**: Documentation never lags behind code because updates happen atomically during implementation, not as a separate task.

---

## Hierarchy

The Spec-Flow workflow uses a 4-level hierarchy of CLAUDE.md files:

```
Root CLAUDE.md (451 lines - workflow overview)
  │
  ├─ Project CLAUDE.md (~100 lines - active features, tech stack)
  │   │
  │   ├─ Domain CLAUDE.md (future - backend/, frontend/ patterns)
  │   │   │
  │   │   └─ Feature CLAUDE.md (~80 lines - current progress, specialists)
```

### 1. Root CLAUDE.md (this repo)

**Location**: `CLAUDE.md`

**Purpose**: Workflow system documentation (commands, architecture, quality gates)

**Token Cost**: ~3,000 tokens

**Content**:
- Core commands (`/feature`, `/spec`, `/plan`, `/tasks`, `/implement`, `/ship`)
- Workflow state machine
- Project design workflow (`/init-project`)
- Deployment models (staging-prod, direct-prod, local-only)
- Quality gates and coding standards
- Recent changes (links to CHANGELOG.md for details)

**When to Read**: Once per session to understand workflow mechanics

**Update Frequency**: Rarely (only for workflow system changes)

---

### 2. Project CLAUDE.md (user repos)

**Location**: `CLAUDE.md` (in project root)

**Purpose**: High-level project context aggregation

**Token Cost**: ~2,000 tokens (vs 12,000 for reading all project docs)

**Content**:
- Active features (from `specs/*/workflow-state.yaml`)
- Tech stack summary (condensed from `docs/project/tech-stack.md`)
- Common patterns (from all `plan.md` REUSE sections)
- Quick links to detailed project docs

**When to Read**: Start of each feature to understand project context

**Auto-Generated**:
- On `/init-project` (initial creation)
- After `/ship-staging` (feature in staging)
- After `/ship-prod` or `/deploy-prod` (feature shipped)

**Example**:

```markdown
# Project Context

> **Token Cost**: ~2,000 tokens (vs 12,000 for reading all project docs)
> **Last Updated**: 2025-11-08T14:30:00

## Active Features

- **001-auth-flow**: Phase ship:staging (in_progress)
- **002-dashboard**: Phase implement (in_progress)

## Tech Stack Summary

### Frontend
  - **Framework**: Next.js 14 (App Router, TypeScript, Tailwind CSS)
  - **State**: Zustand (global state)

### Backend
  - **Framework**: FastAPI 0.104+ (Python 3.11+)
  - **Database**: PostgreSQL 15+ (with Alembic migrations)

### Deployment
  - **Platform**: Vercel (frontend) + Railway (backend)
  - **Model**: staging-prod

## Common Patterns

- **UserService.create_user()** - `api/src/services/user.py:42-58`
- **withAuth() HOC** - `frontend/src/hocs/withAuth.tsx:12-34`

## Quick Links

**Project Documentation**:
- [Overview](docs/project/overview.md) - Vision, users, scope
- [Tech Stack](docs/project/tech-stack.md) - Technology choices (full details)
- [Data Architecture](docs/project/data-architecture.md) - ERD, schemas
- [API Strategy](docs/project/api-strategy.md) - REST/GraphQL patterns

**Features**:
- [001-auth-flow](specs/001-auth-flow/CLAUDE.md)
- [002-dashboard](specs/002-dashboard/CLAUDE.md)
```

---

### 3. Domain CLAUDE.md (future feature)

**Location**: `backend/CLAUDE.md`, `frontend/CLAUDE.md`, etc.

**Purpose**: Domain-specific patterns and context

**Status**: ⏳ Phase 4 (planned)

**Content** (planned):
- Domain-specific reusable code
- Common patterns for this domain
- Domain conventions and best practices
- Links to feature CLAUDE.md files in this domain

---

### 4. Feature CLAUDE.md (user repos)

**Location**: `specs/NNN-slug/CLAUDE.md`

**Purpose**: Immediate context for current feature work

**Token Cost**: ~500 tokens (vs 8,000 for reading all feature artifacts)

**Content**:
- Current phase and progress (from `workflow-state.yaml`)
- Recent progress (last 3 completed tasks from `NOTES.md`)
- Relevant specialists (phase-specific agent briefs)
- Quick commands for this feature
- Navigation to detailed artifacts

**When to Read**: During feature implementation to get fresh context

**Auto-Generated**:
- On `/feature` creation (initial generation)
- On `/feature continue` (refresh with latest progress)
- After `/implement` task completion (via task-tracker)

**Example**:

```markdown
# Feature: User Authentication Flow

> **Purpose**: Quick context for AI when working on this feature
> **Token Cost**: ~500 tokens (vs 8,000 for reading all artifacts)
> **Last Updated**: 2025-11-08T14:30:00

## Current Phase

**Phase**: implementation
**Status**: in_progress
**Progress**: 12/25 tasks completed (48%)

## Recent Progress

- ✅ T010: Create user registration endpoint - 45min (2025-11-08 13:15)
- ✅ T011: Add password hashing with bcrypt - 30min (2025-11-08 13:45)
- ✅ T012: Create login endpoint with JWT - 60min (2025-11-08 14:30)

**Velocity**: 45 min/task avg | 3.5 tasks/day | ETA: 2025-11-10 16:00

## Relevant Specialists

### Backend Development
- **Brief**: `.claude/agents/implementation/backend.md`
- **Capabilities**: API design, authentication, database integration
- **When to use**: Tasks involving backend logic, endpoints, or database

### Frontend Development
- **Brief**: `.claude/agents/implementation/frontend.md`
- **Capabilities**: React components, state management, API integration
- **When to use**: Tasks involving UI components or client-side logic

### QA Testing
- **Brief**: `.claude/agents/quality/qa-tester.md`
- **Capabilities**: E2E tests, integration tests, test plans
- **When to use**: After core implementation for validation

## Quick Commands

```bash
# Continue implementation
/feature continue

# Update living docs manually
.spec-flow/scripts/bash/generate-feature-claude-md.sh specs/001-auth-flow

# Health check
.spec-flow/scripts/bash/health-check-docs.sh --max-age 7
```

## Navigation

**Artifacts**:
- [Spec](spec.md) - Requirements and acceptance criteria
- [Plan](plan.md) - Design decisions and architecture
- [Tasks](tasks.md) - Implementation checklist with velocity
- [NOTES](NOTES.md) - Implementation journal with timestamps

**State**:
- [workflow-state.yaml](workflow-state.yaml) - Machine-readable state
```

---

## Token Efficiency

### Before Living Documentation

**Typical context loading**:

```
Read docs/project/overview.md           → 1,500 tokens
Read docs/project/tech-stack.md         → 2,000 tokens
Read docs/project/data-architecture.md  → 1,800 tokens
Read docs/project/api-strategy.md       → 1,200 tokens
Read docs/project/capacity-planning.md  → 1,000 tokens
Read specs/001-auth/spec.md             → 1,500 tokens
Read specs/001-auth/plan.md             → 2,500 tokens
Read specs/001-auth/tasks.md            → 1,200 tokens
Read specs/001-auth/NOTES.md            →   800 tokens
Read specs/001-auth/workflow-state.yaml →   200 tokens

Total: ~13,700 tokens
```

### After Living Documentation

**Efficient context loading**:

```
Read CLAUDE.md (root)                   → 3,000 tokens (once per session)
Read CLAUDE.md (project)                → 2,000 tokens (start of feature)
Read specs/001-auth/CLAUDE.md           →   500 tokens (during work)

Total: ~5,500 tokens (60% reduction)

If deeper context needed:
Read specs/001-auth/plan.md (first 100 lines) → +800 tokens
Total: ~6,300 tokens (54% reduction)
```

**Benefits**:
- **60% fewer tokens** for typical context loading
- **Faster context switches** between features
- **Always current** - no stale information
- **Guided discovery** - links to detailed docs when needed

---

## Automatic Updates

Living documentation updates atomically with code changes during the workflow:

### 1. Feature CLAUDE.md Updates

**Triggers**:
- `/feature "description"` - Initial creation with basic structure
- `/feature continue` - Refresh with latest progress
- Task completion (via task-tracker) - After each task finishes

**Content Updated**:
- Current phase and status
- Progress percentage (completed/total tasks)
- Last 3 completed tasks with timestamps
- Velocity metrics (avg time/task, completion rate, ETA)
- Relevant specialists for current phase

**Scripts**:
- Bash: `.spec-flow/scripts/bash/generate-feature-claude-md.sh`
- PowerShell: `.spec-flow/scripts/powershell/generate-feature-claude-md.ps1`

### 2. Project CLAUDE.md Updates

**Triggers**:
- `/init-project` - Initial creation after project docs generated
- `/ship-staging` - After feature deployed to staging
- `/ship-prod` or `/deploy-prod` - After feature deployed to production

**Content Updated**:
- Active features list (from workflow-state.yaml files)
- Common patterns (from all plan.md REUSE sections)
- Tech stack summary (if docs/project/tech-stack.md changed)

**Scripts**:
- Bash: `.spec-flow/scripts/bash/generate-project-claude-md.sh`
- PowerShell: `.spec-flow/scripts/powershell/generate-project-claude-md.ps1`

### 3. Artifact Living Sections

Living sections within feature artifacts update during implementation:

#### spec.md - Implementation Status

**Triggers**:
- Task agents during `/implement` when discovering deviations or fulfilling requirements

**Content Updated**:
- Requirements fulfilled (FR-001, FR-002, etc.)
- Deviations from spec (vendor changes, approach changes)
- Performance actuals vs targets

**Script**:
```bash
# Mark requirement fulfilled
.spec-flow/scripts/bash/update-spec-status.sh --type requirement \
  --data '{"id":"FR-001","status":"fulfilled","tasks":"T001-T003"}' \
  specs/001-auth

# Add deviation
.spec-flow/scripts/bash/update-spec-status.sh --type deviation \
  --data '{"id":"FR-004","name":"Email verification","original":"Postmark","actual":"SendGrid","reason":"Cost","impact":"Minor"}' \
  specs/001-auth
```

#### plan.md - Discovered Patterns

**Triggers**:
- Task agents during `/implement` when discovering reusable code not found in Phase 0 research

**Content Updated**:
- Reuse additions (new reusable code found during implementation)
- Architecture adjustments (schema changes, new dependencies)
- Integration discoveries (third-party APIs, internal services)

**Script**:
```bash
# Add discovered pattern
.spec-flow/scripts/bash/update-plan-patterns.sh --type reuse \
  --data '{"name":"UserService.create_user()","path":"api/src/services/user.py:42-58","task":"T013","purpose":"User creation with validation","reusable":"Any endpoint creating users"}' \
  specs/001-auth
```

#### tasks.md - Progress Summary

**Triggers**:
- Task-tracker after each task completion

**Content Updated**:
- Overall progress (completed/total, percentage)
- Velocity metrics (avg time/task, completion rate, ETA)
- Recent completions (last 3 tasks)
- Bottlenecks (tasks >1.5x average time)
- Current sprint status

**Script** (called automatically by task-tracker):
```powershell
# Regenerate Progress Summary
.spec-flow/scripts/powershell/update-tasks-summary.ps1 -FeatureDir "specs/001-auth"
```

---

## Health Checks

Detect stale CLAUDE.md files that haven't been updated recently:

### health-check-docs.sh

**Purpose**: Scan all CLAUDE.md files and flag ones older than threshold

**Usage**:

```bash
# Check with default 7-day threshold
.spec-flow/scripts/bash/health-check-docs.sh

# Check with custom threshold
.spec-flow/scripts/bash/health-check-docs.sh --max-age 3

# JSON output for automation
.spec-flow/scripts/bash/health-check-docs.sh --json
```

**Output**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Living Documentation Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total CLAUDE.md files: 3
Freshness threshold: 7 days

[spec-flow][warn] ⚠️  Found 1 stale CLAUDE.md file(s):

  ❌ specs/001-auth/CLAUDE.md (12d old)

Run regeneration scripts to update:
  - Feature CLAUDE.md: .spec-flow/scripts/bash/generate-feature-claude-md.sh specs/001-auth
  - Project CLAUDE.md: .spec-flow/scripts/bash/generate-project-claude-md.sh

Fresh files: 2
  ✅ CLAUDE.md (2d old)
  ✅ specs/002-dashboard/CLAUDE.md (1d old)
```

**When to Run**:
- Weekly as part of maintenance
- Before starting work on a stale feature
- In CI/CD as a quality gate (optional)

---

## Usage Examples

### Example 1: Starting a New Feature

```bash
# 1. Check project context (once)
# Read: CLAUDE.md (project) - 2,000 tokens
cat CLAUDE.md

# 2. Create feature
/feature "User authentication flow"

# Feature CLAUDE.md auto-generated at specs/001-auth-flow/CLAUDE.md

# 3. Read feature context during work
# Read: specs/001-auth-flow/CLAUDE.md - 500 tokens
cat specs/001-auth-flow/CLAUDE.md

# Total: 2,500 tokens (vs 13,700 for reading all docs)
```

### Example 2: Resuming Work on Existing Feature

```bash
# 1. Read feature context
# Read: specs/001-auth-flow/CLAUDE.md - 500 tokens
cat specs/001-auth-flow/CLAUDE.md

# Shows last 3 tasks completed, current progress, relevant specialists

# 2. Continue implementation
/feature continue

# Feature CLAUDE.md refreshed with latest progress

# Total: 500 tokens (context already loaded)
```

### Example 3: Switching Between Features

```bash
# Working on feature A
cat specs/001-auth-flow/CLAUDE.md  # 500 tokens

# Switch to feature B
cat specs/002-dashboard/CLAUDE.md  # 500 tokens

# Switch back to feature A
cat specs/001-auth-flow/CLAUDE.md  # 500 tokens (already cached)

# No need to re-read all project docs - just feature context
```

### Example 4: Manual Documentation Update

```bash
# Completed a task manually (not via task-tracker)
# Update feature CLAUDE.md manually

.spec-flow/scripts/bash/generate-feature-claude-md.sh specs/001-auth-flow

# Or PowerShell
pwsh -File .spec-flow/scripts/powershell/generate-feature-claude-md.ps1 -FeatureDir "specs/001-auth-flow"
```

---

## Troubleshooting

### Problem: Feature CLAUDE.md Not Updating

**Symptoms**: CLAUDE.md shows outdated progress, missing recent tasks

**Causes**:
1. Task-tracker not used (manual task completion)
2. Script execution failed silently
3. NOTES.md format incorrect

**Solutions**:

```bash
# 1. Check NOTES.md format
# Expected: ✅ T001: Description - 20min (2025-11-08 16:45)
cat specs/001-auth/NOTES.md | grep "✅"

# 2. Manually regenerate
.spec-flow/scripts/bash/generate-feature-claude-md.sh specs/001-auth

# 3. Check for errors
.spec-flow/scripts/bash/generate-feature-claude-md.sh specs/001-auth 2>&1
```

---

### Problem: Project CLAUDE.md Missing Patterns

**Symptoms**: Common patterns section empty or outdated

**Causes**:
1. plan.md Discovered Patterns section not populated
2. Pattern format incorrect
3. Script didn't scan all features

**Solutions**:

```bash
# 1. Check plan.md format
# Expected: - ✅ **PatternName** ...
cat specs/*/plan.md | grep -A 2 "Discovered Patterns"

# 2. Manually add pattern to plan.md
.spec-flow/scripts/bash/update-plan-patterns.sh --type reuse \
  --data '{"name":"AuthMiddleware","path":"backend/src/middleware/auth.py:10-25","task":"T007","purpose":"JWT validation"}' \
  specs/001-auth

# 3. Regenerate project CLAUDE.md
.spec-flow/scripts/bash/generate-project-claude-md.sh
```

---

### Problem: Health Check Shows All Files Stale

**Symptoms**: health-check-docs.sh flags all CLAUDE.md files as stale

**Causes**:
1. "Last Updated" timestamp missing in files
2. File modification time not updated by scripts
3. Threshold too aggressive

**Solutions**:

```bash
# 1. Check for timestamps in files
grep "Last Updated" CLAUDE.md specs/*/CLAUDE.md

# 2. Regenerate all with fresh timestamps
.spec-flow/scripts/bash/generate-project-claude-md.sh
for dir in specs/*/; do
  .spec-flow/scripts/bash/generate-feature-claude-md.sh "$dir"
done

# 3. Use longer threshold
.spec-flow/scripts/bash/health-check-docs.sh --max-age 14
```

---

### Problem: Token Count Higher Than Expected

**Symptoms**: Reading CLAUDE.md uses more tokens than advertised

**Causes**:
1. CLAUDE.md file grew larger (more features)
2. Reading multiple CLAUDE.md files
3. Also reading linked detailed docs

**Solutions**:

```bash
# 1. Check file sizes
wc -l CLAUDE.md specs/*/CLAUDE.md

# 2. Use token calculator
.spec-flow/scripts/bash/calculate-tokens.sh --feature-dir specs/001-auth

# 3. Read only what you need
# Instead of reading full project docs, read project CLAUDE.md
cat CLAUDE.md  # 2,000 tokens

# Then read detailed doc only if needed
cat docs/project/tech-stack.md  # +2,000 tokens (only when necessary)
```

---

## Best Practices

1. **Read CLAUDE.md First**: Always start by reading the relevant CLAUDE.md file before diving into detailed docs
2. **Trust Velocity Metrics**: Use ETA and completion rate from tasks.md to plan work
3. **Update Patterns**: When discovering reusable code, add it to plan.md immediately
4. **Run Health Checks Weekly**: Catch stale documentation before it becomes a problem
5. **Use Task-Tracker**: Complete tasks via task-tracker to ensure automatic updates
6. **Link, Don't Duplicate**: CLAUDE.md should link to detailed docs, not duplicate content
7. **Keep It Concise**: CLAUDE.md files should be 50-100 lines, not 500+

---

## See Also

- [CLAUDE_MD_HIERARCHY.md](CLAUDE_MD_HIERARCHY.md) - Technical reference for hierarchy structure
- [CHANGELOG.md](../CHANGELOG.md) - Version history with living documentation features
- [README.md](../README.md) - Quick start guide
- [architecture.md](architecture.md) - Overall workflow architecture

---

*This guide is part of the Spec-Flow Workflow Kit v4.0.0. Last updated: 2025-11-08*
