# Perpetual Learning System (v10.0+)

Continuously improves workflow efficiency through pattern detection and self-learning capabilities. Learnings persist across npm package updates and accumulate over time.

## Overview

The learning system passively observes workflow execution, detects patterns, and auto-applies safe optimizations while requiring approval for high-risk changes.

**Key capabilities**:

- Performance pattern detection (tool selection, context-aware recommendations)
- Anti-pattern detection (failure prevention, warning system)
- Custom abbreviation learning (project-specific terminology)
- CLAUDE.md optimization (system prompt improvements with approval)

## Learning Categories

### 1. Performance Patterns

**File**: `.spec-flow/learnings/performance-patterns.yaml`

- Auto-applied optimizations
- Tool selection recommendations based on context
- Time-saving strategies
- Confidence threshold: ≥0.90 for auto-apply

Example pattern:

```yaml
id: "grep-before-read-001"
name: "Use Grep before Read for large files"
confidence: 0.95
time_saved_avg: 2.5s
recommendation: "Use Grep with pattern before Read for files >1000 lines"
auto_applied: true
```

### 2. Anti-Patterns

**File**: `.spec-flow/learnings/anti-patterns.yaml`

- Failure pattern detection
- Automatic warnings before risky operations
- Prevention strategies
- Triggers on operations with ≥2 historical failures

Example anti-pattern:

```yaml
id: "schema-without-migration-001"
name: "Editing schema without migration"
severity: "high"
failure_rate: 1.0
warning_message: "Never edit schema.prisma directly"
prevention: "Run migration first: prisma migrate dev"
auto_warn: true
```

### 3. Custom Abbreviations

**File**: `.spec-flow/learnings/custom-abbreviations.yaml`

- Project-specific terminology expansion
- Consistent naming patterns
- Auto-expansion in specs and tasks
- Confidence threshold: ≥0.80

Example abbreviation:

```yaml
abbr: "auth"
expansion: "JWT-based authentication with refresh tokens"
confidence: 0.98
usage_count: 15
auto_expand: true
```

### 4. CLAUDE.md Tweaks

**File**: `.spec-flow/learnings/claude-md-tweaks.yaml`

- System prompt optimizations (requires approval)
- Agent preference patterns
- Workflow-specific guidance
- Always marked as high-risk

Example tweak:

```yaml
id: "prefer-backend-dev-agent-001"
category: "agent_preference"
confidence: 0.92
impact: "medium"
status: "pending"
content: |
  ### Agent Selection
  - For FastAPI endpoints, prefer backend-dev agent over general-purpose
approval_required: true
```

## Risk Classification

Learnings are classified into three risk levels:

**Low Risk** (auto-apply):

- Confidence ≥0.90
- Impact: "low" or "none"
- Examples: performance patterns, abbreviations
- Applied automatically without user approval

**Medium Risk** (suggest):

- Confidence 0.70-0.89
- Impact: "medium"
- Presented to user for approval

**High Risk** (require approval):

- CLAUDE.md modifications (always high-risk)
- Confidence <0.70
- Impact: "high"
- Requires explicit user approval via `/heal-workflow`

## Learning Workflow

### Phase 1: Passive Observation

```bash
# Non-blocking data collection during workflow phases
.spec-flow/scripts/bash/learning-collector.sh collect-after-phase /implement
```

Collects:

- Task execution metrics (duration, success, tools used, retries)
- Tool performance (operation type, file sizes, duration)
- Quality gate results (failures, issues found)
- Agent effectiveness (success rates, patterns)

### Phase 2: Pattern Detection

```bash
# Statistical analysis (runs during /audit-workflow)
.spec-flow/scripts/bash/analyze-learnings.sh --apply-auto
```

Analyzes:

- Groups observations by context
- Calculates confidence scores (statistical significance ≥0.95)
- Detects patterns with ≥3 occurrences (configurable)
- Classifies risk levels

### Phase 3: Auto-Apply or Approval

Low-risk patterns:

- Automatically applied to learning files
- Used immediately in next workflow execution
- Logged in `.spec-flow/learnings/learning-metadata.yaml`

High-risk patterns:

- Added to pending approval queue
- Reviewed via `/workflow-health --detailed`
- Applied via `/heal-workflow` after user approval

## Storage Structure

```
.spec-flow/learnings/
├── performance-patterns.yaml      # Auto-applied optimizations
├── anti-patterns.yaml             # Failure prevention
├── custom-abbreviations.yaml      # Project terminology
├── claude-md-tweaks.yaml          # System prompt improvements (pending)
├── learning-metadata.yaml         # Statistics, health, migration history
├── observations/                  # Raw data (temporary)
│   ├── task-observations-YYYYMMDD.yaml
│   ├── tool-observations-YYYYMMDD.yaml
│   └── quality-gate-observations-YYYYMMDD.yaml
└── archive/                       # Version archives
    ├── v9.4.0/
    └── v10.0.0/
```

## Migration System

Learnings persist across npm package updates via migration system:

**Before npm update**:

```bash
# Archive current learnings
.spec-flow/scripts/bash/migrate-learnings.sh --from 9.4.0 --to 10.0.0 --dry-run
```

**After npm update**:

```bash
# Auto-detect and migrate
.spec-flow/scripts/bash/migrate-learnings.sh --auto
```

**Migration workflow**:

1. Archives current learnings to `.spec-flow/learnings/archive/v{version}/`
2. Applies schema migrations (add fields, rename keys)
3. Merges archived learnings with new schema
4. Updates metadata with migration history

**Committed to git**: All learning files should be committed to preserve knowledge across team members and machines.

## Configuration

Enable/disable via `/init-preferences` or edit `.spec-flow/config/user-preferences.yaml`:

```yaml
learning:
  # Master switch
  enabled: true

  # Auto-apply low-risk patterns
  auto_apply_low_risk: true

  # Require approval for high-risk changes
  require_approval_high_risk: true

  # Allow CLAUDE.md optimization (with approval)
  claude_md_optimization: true

  # Detection thresholds
  thresholds:
    pattern_detection_min_occurrences: 3
    statistical_significance: 0.95
```

## Scripts and Utilities

**Collection**:

- `.spec-flow/scripts/bash/learning-collector.sh` - Passive observation
- `.spec-flow/scripts/powershell/learning-collector.ps1` - Windows version

**Analysis**:

- `.spec-flow/scripts/python/pattern-detector.py` - Statistical analysis
- `.spec-flow/scripts/bash/analyze-learnings.sh` - Orchestration

**Application**:

- `.spec-flow/scripts/bash/auto-apply-learnings.sh` - Apply low-risk patterns
- `.spec-flow/scripts/bash/optimize-claude-md.sh` - Append to CLAUDE.md (with approval)

**Migration**:

- `.spec-flow/scripts/bash/migrate-learnings.sh` - Preserve across updates

## Usage Examples

**Check pending learnings**:

```bash
bash .spec-flow/scripts/bash/optimize-claude-md.sh --list-pending
```

**Apply approved CLAUDE.md tweak**:

```bash
bash .spec-flow/scripts/bash/optimize-claude-md.sh --apply tweak-001 --approve
```

**View learning statistics**:

```bash
/workflow-health --detailed
```

**Manual pattern analysis**:

```bash
bash .spec-flow/scripts/bash/analyze-learnings.sh --apply-auto
```
