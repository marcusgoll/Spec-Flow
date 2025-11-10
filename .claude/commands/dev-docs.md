# /dev-docs - Create Task-Scoped Documentation

**Purpose**: Generate task-scoped persistence documents for pausing/resuming work.

**Usage**: `/dev-docs "task-name"`

---

## What This Command Does

Creates three-file documentation structure in `dev/active/[task-name]/`:

1. **`[task-name]-plan.md`** - Strategic overview (WHAT & WHY)
   - Executive summary
   - Current state vs future state
   - Implementation phases

2. **`[task-name]-context.md`** - Key context (WHERE & HOW)
   - Files referenced
   - Architectural decisions
   - Dependencies

3. **`[task-name]-tasks.md`** - Progress tracking (WHEN)
   - Checklist format
   - Task status (completed/pending)
   - Progress percentage

---

## When to Use

**Use dev docs when**:
- Working on long-running tasks (>1 day)
- Need to pause and resume work frequently
- Complex tasks requiring context preservation
- Collaborating with team (handoff documentation)

**Don't use when**:
- Simple tasks (<1 hour)
- Already have feature-level CLAUDE.md (use that instead)
- Task is part of existing `/implement` workflow

---

## Example Usage

```bash
# During implementation phase
/dev-docs "database-migrations"

# Generates:
dev/active/database-migrations/
├── database-migrations-plan.md       # Strategic overview
├── database-migrations-context.md    # Key files, decisions
└── database-migrations-tasks.md      # Checklist format
```

---

## Integration with Spec-Flow

**Complements living docs**:
- **Feature CLAUDE.md**: Feature-scoped, permanent (survives shipping)
- **Dev docs**: Task-scoped, temporary (deleted after task completion)

**Workflow integration**:
- Auto-updated during `/implement` phase
- Used for pause/resume workflows
- Referenced in `NOTES.md`

---

## Agent Invocation

This command uses the **general-purpose agent** to:
1. Parse task name from arguments
2. Read `specs/NNN-slug/spec.md` and `plan.md` for context
3. Generate three template files in `dev/active/[task-name]/`
4. Populate with current task information

---

## Implementation

Execute the generation script:

```bash
# Bash
.spec-flow/scripts/bash/generate-dev-docs.sh --task-name "$TASK_NAME" --feature-dir "$FEATURE_DIR"

# PowerShell
.spec-flow/scripts/powershell/generate-dev-docs.ps1 -TaskName "$TASK_NAME" -FeatureDir "$FEATURE_DIR"
```

---

## Quality Check

After generation, verify:
- [ ] Three files created in `dev/active/[task-name]/`
- [ ] Plan file has executive summary
- [ ] Context file lists key files
- [ ] Tasks file has checklist format

---

**See also**:
- `docs/LIVING_DOCUMENTATION.md` - Living docs overview
- `.spec-flow/templates/dev-docs/` - Template files
