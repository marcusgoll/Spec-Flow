# Perpetual Learning System

This directory contains the perpetual learning system that continuously improves workflow performance based on observed patterns and project-specific behaviors.

## Directory Structure

```
.spec-flow/learnings/
├── performance-patterns.yaml      # What works well (auto-applied)
├── anti-patterns.yaml              # What to avoid (auto-warning)
├── custom-abbreviations.yaml       # Project-specific shortcuts
├── claude-md-tweaks.yaml           # System prompt optimizations (requires approval)
├── learning-metadata.yaml          # Versioning, stats, and health
├── observations/                   # Raw data collected during workflow
│   ├── task-observations-*.yaml    # Task completion data
│   ├── tool-observations-*.yaml    # Tool usage patterns
│   └── quality-gate-*.yaml         # Quality gate results
└── archive/                        # Historical learnings by version
    ├── v9.4.0/
    └── v10.0.0/
```

## Learning Categories

### 1. Performance Patterns (Low-Risk, Auto-Applied)

**File**: `performance-patterns.yaml`

**Purpose**: Capture what works well in this project

**Threshold**: confidence >= 0.90, occurrences >= 3

**Auto-Applied**: Yes

**Examples**:
- "Use Grep before Read for large files (saves 2-3 seconds)"
- "Prefer backend-dev agent for FastAPI features (15% faster)"
- "Run tests before committing (catches 80% of bugs early)"

**Schema**:
```yaml
- id: "pattern-001"
  name: "Pattern name"
  description: "What it does"
  confidence: 0.95
  occurrences: 12
  time_saved_avg: 2.5
  last_observed: "2025-11-21T10:00:00Z"
  context: "Where this applies"
  recommendation: "What to do"
  auto_applied: true
```

### 2. Anti-Patterns (Auto-Warning)

**File**: `anti-patterns.yaml`

**Purpose**: Detect and prevent repeated mistakes

**Threshold**: failure_rate >= 0.50, occurrences >= 2

**Auto-Applied**: Generates warnings, doesn't block

**Examples**:
- "Never edit schema.prisma without creating migration (caused 3 deploy failures)"
- "Always run tests before committing (prevents 80% of CI failures)"
- "Check migrations before schema edits (prevents data loss)"

**Schema**:
```yaml
- id: "antipattern-001"
  name: "Anti-pattern name"
  description: "What went wrong"
  severity: "high"
  occurrences: 3
  failure_rate: 1.0
  last_observed: "2025-11-21T09:00:00Z"
  context: "Where this applies"
  warning_message: "⚠️  Warning to display"
  prevention: "How to avoid"
  auto_warn: true
```

### 3. Custom Abbreviations (Auto-Expand)

**File**: `custom-abbreviations.yaml`

**Purpose**: Learn project-specific terminology

**Threshold**: confidence >= 0.90, usage_count >= 5

**Auto-Applied**: Expands in specs and plans

**Examples**:
- "auth" → "JWT-based authentication with refresh tokens and httpOnly cookies"
- "dash" → "Admin dashboard with role-based access control"
- "rls" → "Row-level security using Postgres RLS policies"

**Schema**:
```yaml
- abbr: "auth"
  expansion: "Full expansion"
  description: "Detailed explanation"
  confidence: 0.98
  usage_count: 15
  last_used: "2025-11-21T10:30:00Z"
  context: "Where this applies"
  examples:
    - "Example usage 1"
    - "Example usage 2"
  auto_expand: true
```

### 4. CLAUDE.md Tweaks (High-Risk, Approval Required)

**File**: `claude-md-tweaks.yaml`

**Purpose**: Optimize root CLAUDE.md system prompt

**Threshold**: confidence >= 0.92, impact assessment required

**Auto-Applied**: No - requires manual approval via `/heal-workflow`

**Examples**:
- "Prefer backend-dev agent for FastAPI features (15% faster)"
- "Reduce clarify questions from 6 to 3 for this project (45min savings)"
- "Auto-skip preview for backend-only changes (no UI to test)"

**Schema**:
```yaml
- id: "tweak-001"
  category: "agent_preference"
  name: "Tweak name"
  description: "What this does"
  rationale: "Why it helps"
  confidence: 0.92
  evidence:
    - "Data point 1"
    - "Data point 2"
  impact: "medium"
  status: "pending"
  created: "2025-11-21T11:00:00Z"
  applied: null
  content: |
    Markdown text to append
  approval_required: true
```

## Workflow Integration

### Phase Hooks (Passive Collection)

**When**: After phase completion
**Where**: All phase commands (spec, plan, tasks, implement, optimize, ship)
**Script**: `.spec-flow/scripts/bash/learning-collector.sh`

**Collected Data**:
- Tool usage patterns (which tools, success/failure, duration)
- Task completion metrics (time, retries, blockers)
- Quality gate results (which gates caught issues, false positive rate)
- Agent selection patterns (which agents used, task completion times)

**Storage**: `.spec-flow/learnings/observations/*.yaml`

**No Performance Impact**: Runs in background, never blocks workflow

### Analysis Trigger Points

**Automatic**:
- After `/audit-workflow` (end of epic)
- After `/finalize` (end of feature)
- Every 10 features/epics (batch analysis)

**Manual**:
- `/analyze-learnings` (on-demand analysis)

### Application Workflow

**Low-Risk (Auto-Applied)**:
1. Pattern detected with confidence >= 0.90
2. Auto-applied to future workflows
3. Notification shown: "✓ Applied 3 learnings automatically"
4. Logged to `learning-metadata.yaml`

**High-Risk (Approval Required)**:
1. CLAUDE.md tweak detected with confidence >= 0.92
2. Added to pending approvals in `claude-md-tweaks.yaml`
3. User runs `/heal-workflow` to review
4. User approves/rejects via AskUserQuestion
5. If approved: Appends to CLAUDE.md, marks as applied
6. If rejected: Marks as rejected, never suggests again

## NPM Update Protection

### Problem
Running `npm install` or `pnpm update` could overwrite `.spec-flow/` directory and lose learnings.

### Solution
1. **Learnings committed to git** - Never in `.gitignore`
2. **Migration scripts detect version changes** - Runs on workflow start
3. **Archive old learnings before migration** - Preserves history
4. **Schema versioning** - Maintains compatibility

### Migration Process

**Trigger**: Workflow detects version change (reads `package.json`)

**Steps**:
1. Archive current learnings to `.spec-flow/learnings/archive/v{old}/`
2. Run migration script: `.spec-flow/scripts/bash/migrate-learnings.sh`
3. Merge old learnings with new schema
4. Update `learning-metadata.yaml` with migration record
5. Continue workflow with migrated learnings

**Example**:
```bash
# Detected version change: 9.4.0 → 10.0.0
echo "🔄 Migrating learnings from v9.4.0 to v10.0.0..."

# Archive old learnings
mkdir -p .spec-flow/learnings/archive/v9.4.0
cp -r .spec-flow/learnings/*.yaml .spec-flow/learnings/archive/v9.4.0/

# Run migration
bash .spec-flow/scripts/bash/migrate-learnings.sh --from 9.4.0 --to 10.0.0

# Update metadata
yq eval '.last_migrated = "2025-11-21T12:00:00Z"' -i .spec-flow/learnings/learning-metadata.yaml

echo "✅ Migration complete"
```

## User Preferences Integration

### Configuration

**File**: `.spec-flow/config/user-preferences.yaml`

**Settings**:
```yaml
learning:
  enabled: true  # Master switch
  auto_apply_low_risk: true  # Auto-apply performance patterns
  require_approval_high_risk: true  # Always true for CLAUDE.md tweaks
  claude_md_optimization: true  # Allow CLAUDE.md modifications

  thresholds:
    pattern_detection_min_occurrences: 3
    statistical_significance: 0.95
```

### Init Preferences Questions

Run `/init-preferences` to configure:

1. **Enable perpetual learning system?** (yes/no)
2. **Auto-apply low-risk learnings?** (yes/no/approve-all)
3. **Allow CLAUDE.md auto-optimization?** (yes/no)

## Commands

### Learning Management

**`/analyze-learnings`** - Manually trigger pattern analysis

**`/show-learnings [category]`** - Display current learnings
- `/show-learnings performance` - Performance patterns
- `/show-learnings antipatterns` - Anti-patterns
- `/show-learnings abbreviations` - Custom abbreviations
- `/show-learnings tweaks` - Pending CLAUDE.md tweaks
- `/show-learnings all` - Everything

**`/reset-learnings [category]`** - Clear learnings (fresh start)
- `/reset-learnings performance` - Clear performance patterns
- `/reset-learnings all` - Clear everything (requires confirmation)

**`/export-learnings`** - Backup learnings to portable file
```bash
/export-learnings
# Creates: .spec-flow/learnings/export-2025-11-21.yaml
```

**`/import-learnings <file>`** - Restore learnings from backup
```bash
/import-learnings .spec-flow/learnings/export-2025-11-21.yaml
```

## Health Monitoring

### Health Check

**Automatic**: After every 10 learnings recorded

**Manual**: `bash .spec-flow/scripts/bash/health-check-learnings.sh`

**Checks**:
- Patterns with low confidence (<0.5) flagged for review
- Pending approvals exceeding threshold (default: 10)
- Stale patterns not observed in 60+ days
- Conflicting patterns (e.g., contradictory recommendations)

### Health Status

**Stored**: `learning-metadata.yaml`

**Values**:
- `good` - All checks passing
- `degraded` - Minor issues detected
- `needs_attention` - Critical issues require review

**Example Issue**:
```yaml
health_issues:
  - issue: "5 patterns with confidence < 0.5 should be reviewed"
    severity: "low"
    detected: "2025-11-21T12:30:00Z"
```

## Examples

### Example 1: Performance Pattern (Auto-Applied)

**Observation**:
- 12 times: Used Grep before Read for large files
- Average time saved: 2.5 seconds per search
- Context: Files >1000 lines in backend directory

**Pattern Detected** (after 3 occurrences):
```yaml
- id: "grep-before-read-001"
  name: "Use Grep before Read for large files"
  description: "Using Grep to search large files before reading saves 2-3 seconds per search"
  confidence: 0.95
  occurrences: 12
  time_saved_avg: 2.5
  context: "Files >1000 lines in this project"
  recommendation: "Use Grep with pattern first, then Read only matching files"
  auto_applied: true
```

**Auto-Application**:
- Future workflows automatically suggest Grep before Read
- Project CLAUDE.md gets hint: "Tip: Search before reading for files >1000 lines"
- No user action required

### Example 2: Anti-Pattern (Auto-Warning)

**Observation**:
- 3 times: Edited `schema.prisma` without creating migration
- Result: 3 deployment failures (100% failure rate)
- Context: Prisma database schema changes

**Anti-Pattern Detected** (after 2 failures):
```yaml
- id: "schema-without-migration-001"
  name: "Editing schema.prisma without creating migration"
  description: "Direct schema edits without migrations caused 3 deployment failures"
  severity: "high"
  occurrences: 3
  failure_rate: 1.0
  context: "Prisma database schema changes"
  warning_message: "⚠️  Never edit schema.prisma directly - always create migrations first"
  prevention: "Run 'npx prisma migrate dev' before changing schema"
  auto_warn: true
```

**Auto-Warning**:
- Pre-flight checks warn if `schema.prisma` changed without migration
- Project CLAUDE.md gets: "Never edit schema.prisma without migration"
- Doesn't block, just warns

### Example 3: Custom Abbreviation (Auto-Expand)

**Observation**:
- User says "auth" 15 times
- Always means: "JWT-based authentication with refresh tokens and httpOnly cookies"
- Context: Authentication and security features

**Abbreviation Detected** (after 5 uses):
```yaml
- abbr: "auth"
  expansion: "JWT-based authentication with refresh tokens and httpOnly cookies"
  description: "User authentication system using JWT access tokens (15min TTL) and refresh tokens (7 day TTL) stored in httpOnly cookies"
  confidence: 0.98
  usage_count: 15
  context: "Authentication and security features"
  examples:
    - "Add auth to user dashboard"
    - "Implement auth for admin panel"
  auto_expand: true
```

**Auto-Expansion**:
- When user says "Add auth", spec expands to full description
- Ensures consistency across features
- Project CLAUDE.md lists abbreviations

### Example 4: CLAUDE.md Tweak (Approval Required)

**Observation**:
- 8 backend tasks completed
- backend-dev agent: average 16min per task
- general-purpose agent: average 19min per task
- Speedup: 15% with backend-dev

**Tweak Detected**:
```yaml
- id: "prefer-backend-dev-agent-001"
  category: "agent_preference"
  name: "Prefer backend-dev agent for FastAPI features"
  description: "Using backend-dev agent instead of general-purpose for FastAPI tasks improves completion speed by 15%"
  confidence: 0.92
  evidence:
    - "Task T045: 12min with backend-dev vs 14min with general-purpose"
    - "Task T067: 18min with backend-dev vs 21min with general-purpose"
    - "Average speedup: 15% across 8 backend tasks"
  impact: "medium"
  status: "pending"
  content: |
    ### Agent Selection
    - For Python FastAPI features, prefer backend-dev agent over general-purpose agent
    - backend-dev agent includes specialized FastAPI context and TDD workflows
    - Average task completion 15% faster for backend work
  approval_required: true
```

**Approval Workflow**:
1. User runs `/heal-workflow` (or prompted after `/finalize`)
2. AskUserQuestion shows tweak with evidence
3. User approves → Appends to CLAUDE.md, marks as applied
4. User rejects → Marks as rejected, never suggests again

## Best Practices

### For Users

1. **Review learnings periodically** - Run `/show-learnings all` monthly
2. **Approve valuable tweaks** - High-quality CLAUDE.md optimizations compound
3. **Reset stale patterns** - If project changes significantly, reset learnings
4. **Export before major changes** - Backup learnings before refactors
5. **Trust the system** - Low-risk auto-applications are conservative (90% confidence)

### For Developers

1. **Never block workflow** - Learning collection is passive, never interrupts
2. **Batch analysis** - Don't analyze after every task, wait for statistical significance
3. **Evidence over intuition** - Only suggest tweaks with solid data
4. **Clear rollback** - Always allow users to undo auto-applications
5. **Privacy first** - Never collect PII, only patterns and metrics

## Troubleshooting

### "Learnings not auto-applying"

**Check**:
1. `learning.enabled: true` in user-preferences.yaml
2. `learning.auto_apply_low_risk: true` in user-preferences.yaml
3. Pattern confidence >= 0.90
4. Pattern occurrences >= 3

**Fix**: Run `/show-learnings performance` to verify patterns exist

### "Too many pending approvals"

**Symptom**: `/heal-workflow` shows 20+ pending tweaks

**Cause**: Threshold too low or too much variation

**Fix**: Increase `min_confidence_for_auto_apply` in learning-metadata.yaml

### "Learnings lost after npm update"

**Cause**: Learnings not committed to git

**Fix**:
1. Add to `.gitignore`: `!.spec-flow/learnings/` (force include)
2. Commit learnings: `git add .spec-flow/learnings/ && git commit -m "chore: preserve learnings"`
3. Run migration script to restore from archive

### "Conflicting patterns detected"

**Symptom**: Health check reports conflicts

**Example**: Pattern A says "Use X", Pattern B says "Avoid X"

**Fix**: Run `/show-learnings all`, review context, delete stale pattern

## Version History

- **v1.0** (2025-11-21) - Initial perpetual learning system
  - Performance patterns (auto-apply)
  - Anti-patterns (auto-warn)
  - Custom abbreviations (auto-expand)
  - CLAUDE.md tweaks (approval required)
  - NPM update protection
  - User preference integration
