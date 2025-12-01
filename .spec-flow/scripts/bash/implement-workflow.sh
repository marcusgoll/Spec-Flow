---

## Implementation Workflow

<instructions>

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ERROR TRAP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

on_error() {
  echo "⚠️  Error in /implement. Check error-log.md for details."
  exit 1
}
trap on_error ERR

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TOOL PREFLIGHT CHECKS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ Missing required tool: $1"
    echo ""
    case "$1" in
      git)
        echo "Install: https://git-scm.com/downloads"
        ;;
      jq)
        echo "Install: brew install jq (macOS) or apt install jq (Linux)"
        echo "         https://stedolan.github.io/jq/download/"
        ;;
      *)
        echo "Check documentation for installation"
        ;;
    esac
    exit 1
  }
}

need git
need jq

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SETUP - Deterministic repo root
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cd "$(git rev-parse --show-toplevel)"

SLUG="${ARGUMENTS:-$(git branch --show-current)}"
FEATURE_DIR="specs/$SLUG"
TASKS_FILE="$FEATURE_DIR/tasks.md"
NOTES_FILE="$FEATURE_DIR/NOTES.md"
ERROR_LOG="$FEATURE_DIR/error-log.md"
TRACKER=".spec-flow/scripts/bash/task-tracker.sh"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# VALIDATE FEATURE EXISTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ ! -d "$FEATURE_DIR" ]; then
  echo "❌ Feature not found: $FEATURE_DIR"
  echo ""
  echo "Fix: Run /spec to create feature first"
  echo "     Or provide correct feature slug: /implement <slug>"
  exit 1
fi

if [ ! -f "$TASKS_FILE" ]; then
  echo "❌ Missing: $TASKS_FILE"
  echo ""
  echo "Fix: Run /tasks first to generate task breakdown"
  exit 1
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PREFLIGHT VALIDATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Checklist validation (non-blocking warning)
if [ -d "$FEATURE_DIR/checklists" ]; then
  INCOMPLETE=$(grep -c "^- \[ \]" "$FEATURE_DIR"/checklists/*.md 2>/dev/null || echo 0)
  if [ "$INCOMPLETE" -gt 0 ]; then
    echo "⚠️  Checklists have $INCOMPLETE incomplete item(s) (continuing anyway)"
    echo ""
  fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MOCKUP APPROVAL CHECK (UI-first features)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check if feature has HTML mockups requiring approval
MOCKUPS=$(find "$FEATURE_DIR/mockups" -name "*.html" 2>/dev/null || echo "")
if [ -n "$MOCKUPS" ]; then
  MOCKUP_COUNT=$(echo "$MOCKUPS" | wc -l)
  echo "🎨 Found $MOCKUP_COUNT HTML mockup(s) - checking approval status..."

  # Check state.yaml for mockup approval status
  if [ -f "$FEATURE_DIR/state.yaml" ]; then
    APPROVAL_STATUS=$(grep -A 5 "mockup_approval:" "$FEATURE_DIR/state.yaml" | grep "status:" | awk '{print $2}' || echo "")

    if [ "$APPROVAL_STATUS" != "approved" ]; then
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "❌ BLOCKED: Mockup approval required"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "📋 Mockup Location: $FEATURE_DIR/mockups/"
      echo "📝 Checklist: $FEATURE_DIR/mockup-approval-checklist.md"
      echo ""
      echo "📖 Review Process:"
      echo "1. Open HTML mockups in your browser:"
      echo "   $(echo "$MOCKUPS" | head -3 | sed 's/^/   - /')"
      if [ "$MOCKUP_COUNT" -gt 3 ]; then
        echo "   ... and $((MOCKUP_COUNT - 3)) more"
      fi
      echo ""
      echo "2. Press 'S' key in browser to cycle through states:"
      echo "   - Success (normal data)"
      echo "   - Loading (spinner/skeleton)"
      echo "   - Error (error message)"
      echo "   - Empty (no data)"
      echo ""
      echo "3. Review against checklist:"
      echo "   - Visual (layout, spacing, colors, tokens.css compliance)"
      echo "   - Interaction (all states visible)"
      echo "   - Accessibility (WCAG 2.1 AA)"
      echo "   - Component reuse (ui-inventory.md)"
      echo ""
      echo "4. Approve or request changes in checklist"
      echo ""
      echo "5. Update state.yaml:"
      echo "   workflow:"
      echo "     manual_gates:"
      echo "       mockup_approval:"
      echo "         status: approved"
      echo "         approved_at: $(date '+%Y-%m-%d %H:%M:%S')"
      echo ""
      echo "6. Run: /feature continue"
      echo ""
      echo "💡 Tip: If requesting changes, agent can propose tokens.css updates"
      echo "        (e.g., 'make primary color more vibrant')"
      echo ""
      exit 1
    fi

    echo "✅ Mockup approved - proceeding with implementation"
    echo ""
  else
    echo "⚠️  WARNING: No state.yaml found - cannot verify mockup approval"
    echo "   Continuing anyway (assuming brownfield project or manual approval)"
    echo ""
  fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MIGRATION ENFORCEMENT (v10.5 - Migration Safety)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check if feature requires migrations (from /plan phase)
HAS_MIGRATIONS="false"
if [ -f "$FEATURE_DIR/state.yaml" ]; then
  HAS_MIGRATIONS=$(grep "has_migrations:" "$FEATURE_DIR/state.yaml" 2>/dev/null | awk '{print $2}' || echo "false")
fi

# Also check for migration-plan.md existence
if [ -f "$FEATURE_DIR/migration-plan.md" ]; then
  HAS_MIGRATIONS="true"
fi

if [ "$HAS_MIGRATIONS" = "true" ]; then
  echo "🗄️  Migration check required (feature has schema changes)"
  echo ""

  # Run migration status detection
  MIGRATION_CHECK_SCRIPT=".spec-flow/scripts/bash/check-migration-status.sh"
  if [ -f "$MIGRATION_CHECK_SCRIPT" ]; then
    MIGRATION_STATUS=$("$MIGRATION_CHECK_SCRIPT" --json 2>/dev/null) || MIGRATION_EXIT=$?
    MIGRATION_EXIT=${MIGRATION_EXIT:-0}

    if [ "$MIGRATION_EXIT" -eq 0 ]; then
      PENDING=$(echo "$MIGRATION_STATUS" | jq -r '.pending // false')
      PENDING_COUNT=$(echo "$MIGRATION_STATUS" | jq -r '.pending_count // 0')
      TOOL=$(echo "$MIGRATION_STATUS" | jq -r '.tool // "unknown"')
      APPLY_CMD=$(echo "$MIGRATION_STATUS" | jq -r '.apply_command // ""')

      if [ "$PENDING" = "true" ]; then
        # Read user preference for strictness
        MIGRATION_STRICTNESS="blocking"
        if [ -f ".spec-flow/config/user-preferences.yaml" ]; then
          MIGRATION_STRICTNESS=$(grep -A 5 "migrations:" .spec-flow/config/user-preferences.yaml 2>/dev/null | grep "strictness:" | awk '{print $2}' || echo "blocking")
        fi
        MIGRATION_STRICTNESS=${MIGRATION_STRICTNESS:-blocking}

        case "$MIGRATION_STRICTNESS" in
          blocking)
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "❌ BLOCKED: $PENDING_COUNT pending $TOOL migrations detected"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Tests will fail without applied migrations. You must:"
            echo "  1. Apply migrations: $APPLY_CMD"
            echo "  2. Re-run /implement after migrations applied"
            echo ""
            echo "To change this behavior, update .spec-flow/config/user-preferences.yaml:"
            echo "  migrations:"
            echo "    strictness: warning  # or auto_apply"
            echo ""
            exit 1
            ;;
          warning)
            echo "⚠️  WARNING: $PENDING_COUNT pending $TOOL migrations detected"
            echo "  Apply before running tests: $APPLY_CMD"
            echo "  Continuing anyway (strictness: warning)"
            echo ""
            ;;
          auto_apply)
            echo "🔄 AUTO-APPLY: Applying $PENDING_COUNT $TOOL migrations"
            if eval "$APPLY_CMD"; then
              echo "✅ Migrations applied successfully"
            else
              echo "❌ Migration auto-apply failed. Manual intervention required."
              echo ""
              echo "Run: $APPLY_CMD"
              exit 1
            fi
            echo ""
            ;;
        esac
      else
        echo "✅ Migrations up-to-date ($TOOL)"
        echo ""
      fi
    elif [ "$MIGRATION_EXIT" -eq 2 ]; then
      echo "⚠️  No migration tool detected - skipping migration check"
      echo "   (If using custom migrations, ensure they are applied manually)"
      echo ""
    else
      echo "⚠️  Migration check failed - continuing anyway"
      echo ""
    fi
  else
    echo "⚠️  Migration check script not found - skipping check"
    echo "   ($MIGRATION_CHECK_SCRIPT)"
    echo ""
  fi
else
  echo "   No migrations required for this feature"
  echo ""
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PARSE TASKS AND DETECT BATCHES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Collect tasks not yet marked ✅ in NOTES.md
mapfile -t ALL < <(grep "^T[0-9]\{3\}" "$TASKS_FILE" || true)
PENDING=()

for task in "${ALL[@]}"; do
  id=$(echo "$task" | grep -o "^T[0-9]\{3\}" || true)
  if [ -n "$id" ]; then
    if ! grep -q "✅ $id" "$NOTES_FILE" 2>/dev/null; then
      PENDING+=("$task")
    fi
  fi
done

if [ ${#PENDING[@]} -eq 0 ]; then
  echo "✅ All tasks already completed"
  echo ""
  echo "Next: /optimize (auto-continues from /feature)"
  exit 0
fi

echo "📋 ${#PENDING[@]} tasks to execute"
echo ""

# Detect TDD phase and domain for batching
tag_phase() {
  local line="$1"
  if [[ "$line" =~ \[RED\] ]]; then
    echo "RED"
  elif [[ "$line" =~ \[GREEN\] ]]; then
    echo "GREEN"
  elif [[ "$line" =~ \[REFACTOR\] ]]; then
    echo "REFACTOR"
  else
    echo "NA"
  fi
}

tag_domain() {
  local line="$1"
  if [[ "$line" =~ api/|backend|\.py|endpoint ]]; then
    echo "backend"
  elif [[ "$line" =~ apps/|frontend|\.tsx|component|page ]]; then
    echo "frontend"
  elif [[ "$line" =~ migration|schema|alembic|sql ]]; then
    echo "database"
  elif [[ "$line" =~ test.|\.test\.|\.spec\.|tests/ ]]; then
    echo "tests"
  else
    echo "general"
  fi
}

# Build batches: TDD phases run alone; others grouped by domain (max 4 per batch)
BATCHES=()
batch=""
last_dom=""
count=0

for row in "${PENDING[@]}"; do
  id=$(echo "$row" | grep -o "^T[0-9]\{3\}" || echo "")
  if [ -z "$id" ]; then
    continue
  fi

  phase=$(tag_phase "$row")
  dom=$(tag_domain "$row")
  desc=$(echo "$row" | sed -E 's/^T[0-9]{3}(\s*\[[^]]+\])*\s*//')

  item="$id:$dom:$phase:$desc"

  # TDD phases run as single-task batches (sequential dependency)
  if [[ "$phase" =~ ^(RED|GREEN|REFACTOR)$ ]]; then
    if [ -n "$batch" ]; then
      BATCHES+=("$batch")
      batch=""
      last_dom=""
      count=0
    fi
    BATCHES+=("$item")
    continue
  fi

  # Group parallel tasks by domain (max 4 per batch for clarity)
  if [[ "$dom" != "$last_dom" || $count -ge 4 ]]; then
    if [ -n "$batch" ]; then
      BATCHES+=("$batch")
    fi
    batch=""
    count=0
  fi

  batch="${batch}${batch:+|}$item"
  last_dom="$dom"
  count=$((count+1))
done

if [ -n "$batch" ]; then
  BATCHES+=("$batch")
fi

echo "📦 Organized into ${#BATCHES[@]} batches"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INITIALIZE TODO TRACKER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "📝 Creating implementation progress tracker..."

# Build dynamic TodoWrite list from batches
# Note: TodoWrite tool call happens in agent context, not bash script
# This section documents the structure that will be created

TOTAL_STEPS=$((${#BATCHES[@]} + 4))
echo "✅ Progress tracker ready ($TOTAL_STEPS steps)"
echo ""

# Expected structure (created by agent):
# - Validate preflight checks [completed]
# - Parse tasks and detect batches [completed]
# - Execute batch group 1 (batches 1-3) [pending]
# - Execute batch group 2 (batches 4-6) [pending]
# - ... one per group
# - Verify all implementations [pending]
# - Commit final summary [pending]

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# EXECUTE BATCHES VIA PARALLEL SPECIALIST AGENTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Stop bash script execution - orchestration now happens in Claude Code context
# The agent will read this script output and execute the following orchestration logic:

```

</instructions>

---

## Direct Specialist Orchestration

After task parsing completes, Claude Code orchestrates specialist agents directly (no implement-phase-agent wrapper).

### Orchestration Logic

**Step 1: Group Batches for Parallel Execution**

```javascript
// Parse batch output from bash script
const batches = parseBatchesFromScript(); // Array of {id, domain, phase, tasks[]}
const PARALLEL_GROUP_SIZE = 3;
const groups = chunkArray(batches, PARALLEL_GROUP_SIZE);

console.log(`📦 ${batches.length} batches organized into ${groups.length} groups`);
```

**Step 2: Execute Each Batch Group in Parallel**

For each group, launch multiple Task() calls in a **single message** for true parallelism:

```javascript
for (const [groupNum, group] of groups.entries()) {
  console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
  console.log(`🚀 Batch Group ${groupNum + 1}: Batches ${group.map(b => b.id).join(', ')} (PARALLEL)`);
  console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);

  // Display batches in group
  for (const batch of group) {
    console.log(`Batch ${batch.id}:`);
    for (const task of batch.tasks) {
      console.log(`  → ${task.id} [${task.domain} ${task.phase}]: ${task.desc}`);
    }
  }

  // CRITICAL: Launch all Task() calls in SINGLE message for parallelism
  const taskPromises = group.map(batch => {
    const specialist = mapDomainToSpecialist(batch.domain);
    const prompt = buildBatchPrompt(batch, FEATURE_DIR, TASKS_FILE, NOTES_FILE);

    return Task({
      subagent_type: specialist,
      description: `Batch ${batch.id}: ${batch.domain} tasks`,
      prompt: prompt
    });
  });

  // Wait for all batches in group to complete
  console.log(`⏳ Waiting for ${group.length} specialists to complete...`);
  const results = await Promise.all(taskPromises);

  // Process results
  const allSuccess = results.every(r => r.status === 'success');
  if (!allSuccess) {
    const failed = results.filter(r => r.status !== 'success');
    console.log(`⚠️  ${failed.length} batches failed, see error-log.md`);
  }

  // Checkpoint commit for group
  Bash(`
    git add . 2>/dev/null || true
    if [ -n "$(git status --porcelain)" ]; then
      git commit -m "feat: implement batch group ${groupNum + 1}

Batch group: ${groupNum + 1}/${groups.length}
Batches: ${group.map(b => b.id).join(', ')}
Specialists: ${group.map(b => mapDomainToSpecialist(b.domain)).join(', ')}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    fi
  `);

  console.log(`✅ Batch group ${groupNum + 1} complete`);

  // Update TodoWrite to mark group completed
  TodoWrite({
    todos: updateGroupStatus(groupNum, 'completed')
  });
}
```

**Step 3: Domain to Specialist Mapping**

```javascript
function mapDomainToSpecialist(domain) {
  const mapping = {
    'backend': 'backend-dev',
    'frontend': 'frontend-dev',
    'database': 'database-architect',
    'tests': 'qa-test',
    'general': 'general-purpose'
  };
  return mapping[domain] || 'general-purpose';
}
```

**Step 4: Build Batch Prompt for Specialist**

```javascript
function buildBatchPrompt(batch, featureDir, tasksFile, notesFile) {
  return `Execute the following tasks in strict TDD order if phases are specified.

**Feature Directory**: ${featureDir}
**Tasks File**: ${tasksFile}
**Notes File**: ${notesFile}

**Tasks in This Batch**:
${batch.tasks.map(t => `- ${t.id} [${t.phase || 'GENERAL'}]: ${t.desc}`).join('\n')}

**Instructions**:
1. Read ${tasksFile} for full task requirements and acceptance criteria
2. Check for REUSE markers and read referenced files before implementing
3. For TDD phases ([RED], [GREEN], [REFACTOR]):
   - RED: Write failing test first, verify it fails, commit
   - GREEN: Minimal implementation to pass test, commit when passing
   - REFACTOR: Clean up code while keeping tests green, commit
4. For general tasks: Implement, test, commit
5. **Task Completion Tracking** (MANDATORY after EACH successful task):
   - Call task-tracker to mark task complete and update Progress Summary
   - Format: .spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes -TaskId "TXXX" -Notes "Implementation summary (1-2 sentences)" -Evidence "pytest: NN/NN passing" -Coverage "NN% line, NN% branch" -CommitHash "$(git rev-parse --short HEAD)" -Duration "XXmin" -FeatureDir "${featureDir}"
   - Example: .spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes -TaskId "T001" -Notes "Created Message model with validation" -Evidence "pytest: 25/25 passing" -Coverage "92% line, 88% branch" -CommitHash "$(git rev-parse --short HEAD)" -Duration "15min" -FeatureDir "${featureDir}"
   - This updates both tasks.md checkbox AND NOTES.md AND Progress Summary velocity metrics
6. **Error Handling** (MANDATORY):
   - On test failure: Call task-tracker mark-failed BEFORE rollback
   - On linting error: Log to error-log.md with full error output
   - On git conflict: Log to error-log.md, do not auto-resolve
   - On REUSE file missing: Log to error-log.md, skip task
   - Format: .spec-flow/scripts/bash/task-tracker.sh mark-failed -TaskId "TXXX" -ErrorMessage "Full error details including stack trace" -FeatureDir "${featureDir}"
   - After logging: git restore . (rollback changes)
   - Continue to next task (do not abort batch)

**Commit Format** (one per task):
\`\`\`
${batch.tasks[0].phase === 'RED' ? 'test(red)' : batch.tasks[0].phase === 'GREEN' ? 'feat(green)' : batch.tasks[0].phase === 'REFACTOR' ? 'refactor' : 'feat'}: ${batch.tasks[0].id} <summary>

${batch.tasks[0].phase ? `Phase: ${batch.tasks[0].phase}` : ''}
Tests: <status>
Coverage: <percentage>
\`\`\`

**Return** (JSON):
{
  "batch_id": "${batch.id}",
  "status": "success|failed",
  "tasks_completed": ["T001", "T002"],
  "tasks_failed": [],
  "files_changed": 5,
  "test_results": "10/10 passing",
  "coverage": "85% (+5%)"
}`;
}
```

### Parallel Execution Rules

1. **Launch all Task() calls in single message** - This is critical for true parallelism
2. **Wait for all to complete** - Use Promise.all() to collect results
3. **Checkpoint commit per group** - Create atomic commit after each group completes
4. **Update TodoWrite progress** - Mark groups as completed in real-time

### Error Handling

- **Test failures**: Specialist MUST call task-tracker mark-failed BEFORE rollback, then continues
- **Missing REUSE files**: Specialist MUST log via task-tracker mark-failed, then continues
- **Git conflicts**: Specialist MUST log via task-tracker mark-failed, abort batch, exit 1
- **Linting failures**: Specialist MUST log via task-tracker mark-failed, rollback, continues
- **Verification failures**: Record partial results via mark-failed, do not proceed to next group

---

<instructions>

```bash

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# VALIDATE ALL IMPLEMENTATIONS (Single Pass)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Validating all task completions..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for batch in "${BATCHES[@]}"; do
  IFS='|' read -ra TASKS <<< "$batch"

  for t in "${TASKS[@]}"; do
    IFS=':' read -r id dom phase desc <<< "$t"

    # Check authoritative status once
    if [ -x "$TRACKER" ]; then
      COMPLETED=$("$TRACKER" status -FeatureDir "$FEATURE_DIR" -Json 2>/dev/null | \
        jq -r ".CompletedTasks[] | select(.Id == \"$id\") | .Id" 2>/dev/null || echo "")

      if [ "$COMPLETED" = "$id" ]; then
        echo "✅ $id complete"
      else
        echo "⚠️  $id incomplete"
        FAILED_TASKS+=("$id")
      fi
    else
      # Fallback to NOTES.md check
      if grep -q "✅ $id" "$NOTES_FILE" 2>/dev/null; then
        echo "✅ $id complete"
      else
        echo "⚠️  $id incomplete"
        FAILED_TASKS+=("$id")
        echo "  ⚠️  $id: Not completed" >> "$ERROR_LOG"
      fi
    fi
  done
done

echo ""

# Report failures
if [ ${#FAILED_TASKS[@]} -gt 0 ]; then
  echo "❌ ${#FAILED_TASKS[@]} tasks incomplete: ${FAILED_TASKS[*]}"
  echo ""
  echo "Review error-log.md for details"
  exit 2
fi

echo "✅ All tasks validated successfully"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WRAP-UP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Calculate completion statistics
TOTAL=$(grep -c "^T[0-9]\{3\}" "$TASKS_FILE" 2>/dev/null || echo "0")
COMPLETED=$(grep -c "^✅ T[0-9]\{3\}" "$NOTES_FILE" 2>/dev/null || echo "0")
FILES_CHANGED=$(git diff --name-only main 2>/dev/null | wc -l || echo "0")
ERROR_COUNT=$(grep -c "❌\|⚠️" "$ERROR_LOG" 2>/dev/null || echo "0")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All batches complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Summary:"
echo "  Tasks: $COMPLETED/$TOTAL completed"
echo "  Files changed: $FILES_CHANGED"
echo "  Errors logged: $ERROR_COUNT"
echo ""

# Update workflow state
if [ -f .spec-flow/scripts/bash/workflow-state.sh ]; then
  source .spec-flow/scripts/bash/workflow-state.sh
  update_workflow_phase "$FEATURE_DIR" "implement" "completed" 2>/dev/null || true
fi

echo "Next: /optimize (auto-continues from /feature)"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INFRASTRUCTURE RECOMMENDATIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ -f .spec-flow/scripts/bash/detect-infrastructure-needs.sh ]; then
  INFRA_NEEDS=$(.spec-flow/scripts/bash/detect-infrastructure-needs.sh all 2>/dev/null || echo '{}')

  # Check for feature flag needs (branch age >18h)
  FLAG_NEEDED=$(echo "$INFRA_NEEDS" | jq -r '.flag_needed.needed // false')
  if [ "$FLAG_NEEDED" = "true" ]; then
    BRANCH_AGE=$(echo "$INFRA_NEEDS" | jq -r '.flag_needed.branch_age_hours')
    SLUG=$(echo "$INFRA_NEEDS" | jq -r '.flag_needed.slug')

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  BRANCH AGE WARNING: ${BRANCH_AGE}h (24h limit)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Consider adding a feature flag to merge daily:"
    echo "  /flag-add ${SLUG}_enabled --reason \"Large feature - daily merges\""
    echo ""
    echo "This allows merging incomplete work behind a flag."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
  fi

  # Check for contract bump needs (API changes)
  CONTRACT_BUMP_NEEDED=$(echo "$INFRA_NEEDS" | jq -r '.contract_bump.needed // false')
  if [ "$CONTRACT_BUMP_NEEDED" = "true" ]; then
    CHANGED_COUNT=$(echo "$INFRA_NEEDS" | jq -r '.contract_bump.changed_files | length')

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔌 API CHANGES DETECTED ($CHANGED_COUNT files)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Consider updating API contracts:"
    echo ""
    echo "  1. If breaking change:"
    echo "     /contract-bump major --reason \"Breaking change description\""
    echo ""
    echo "  2. If backward-compatible:"
    echo "     /contract-bump minor --reason \"New endpoint added\""
    echo ""
    echo "  3. Verify all consumers still work:"
    echo "     /contract-verify"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
  fi

  # Check for fixture refresh needs (migrations)
  FIXTURE_REFRESH_NEEDED=$(echo "$INFRA_NEEDS" | jq -r '.fixture_refresh.needed // false')
  if [ "$FIXTURE_REFRESH_NEEDED" = "true" ]; then
    MIGRATION_COUNT=$(echo "$INFRA_NEEDS" | jq -r '.fixture_refresh.migration_files | length')

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗄️  DATABASE MIGRATIONS DETECTED ($MIGRATION_COUNT files)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Consider refreshing test fixtures:"
    echo "  /fixture-refresh --env production --anonymize"
    echo ""
    echo "This ensures tests use realistic, up-to-date data."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
  fi
fi

```

</instructions>

---

## Agent Execution Rules

The bash script above delegates to Claude Code for actual task execution. Claude Code invokes appropriate agents via the Task tool based on task domain.

### TDD Phases (strict sequential order)

**RED Phase `[RED]`**:
- Write failing test first
- Test must fail for right reason
- Provide test output as evidence
- Auto-rollback if test passes (wrong!)
- Commit immediately:
  ```bash
  git add .
  git commit -m "test(red): TXXX write failing test

  Test: $TEST_NAME
  Expected: FAILED (ImportError/NotImplementedError)
  Evidence: $(pytest output showing failure)"
  ```

**GREEN Phase `[GREEN→TXXX]`**:
- Minimal implementation to pass RED test
- Run tests, must pass
- Auto-rollback on failure → log to error-log.md
- Commit when tests pass:
  ```bash
  git add .
  git commit -m "feat(green): TXXX implement to pass test

  Implementation: $SUMMARY
  Tests: All passing ($PASS/$TOTAL)
  Coverage: $COV% (+$DELTA%)"
  ```

**REFACTOR Phase `[REFACTOR]`**:
- Clean up code (DRY, KISS)
- Tests must stay green
- Auto-rollback if tests break
- Commit after refactoring:
  ```bash
  git add .
  git commit -m "refactor: TXXX clean up implementation

  Improvements: $IMPROVEMENTS
  Tests: Still passing ($PASS/$TOTAL)
  Coverage: Maintained at $COV%"
  ```

### Auto-Rollback (no prompts)

On failure:
```bash
# CRITICAL: Log error BEFORE rollback
.spec-flow/scripts/bash/task-tracker.sh mark-failed \
  -TaskId "TXXX" \
  -ErrorMessage "Test failure: $(cat test-output.log | tail -20)" \
  -FeatureDir "$FEATURE_DIR"

# Then rollback changes
git restore .

# Continue to next task (do not exit)
```

### REUSE Enforcement

Before implementing:
1. Check REUSE markers in tasks.md
2. Read referenced files
3. Import/extend existing code
4. Flag if claimed REUSE but no import

### Task Status Updates (mandatory)

**CRITICAL**: You MUST call task-tracker for EVERY task (success or failure)

After successful task completion:
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId "TXXX" \
  -Notes "Implementation summary (1-2 sentences)" \
  -Evidence "pytest: NN/NN passing" or "jest: NN/NN passing, a11y: 0 violations" \
  -Coverage "NN% line, NN% branch (+ΔΔ%)" \
  -CommitHash "$(git rev-parse --short HEAD)" \
  -Duration "XXmin" \
  -FeatureDir "$FEATURE_DIR"
```

**What this does**:
- Updates tasks.md checkbox from [ ] to [X]
- Appends to NOTES.md with ✅ TXXX: Description - duration (timestamp)
- Updates Progress Summary section with velocity metrics (avg time, ETA, bottlenecks)
- Enables automatic velocity tracking and bottleneck detection

On task failure:
```bash
# MANDATORY: Log error before rollback
.spec-flow/scripts/bash/task-tracker.sh mark-failed \
  -TaskId "TXXX" \
  -ErrorMessage "Detailed error description with stack trace and error output" \
  -FeatureDir "$FEATURE_DIR"

# Then rollback if needed
git restore .
```

**What this does**:
- Appends to error-log.md with ❌ TXXX and error details
- Does NOT update tasks.md (leaves checkbox unchecked for retry)
- Enables debugging with complete error history

---

## Error Handling

- **Test failures**: Log via task-tracker mark-failed, auto-rollback, continue to next task
  ```bash
  .spec-flow/scripts/bash/task-tracker.sh mark-failed \
    -TaskId "T001" \
    -ErrorMessage "pytest failed: 3/18 tests failing (see full output)" \
    -FeatureDir "$FEATURE_DIR"
  git restore .
  ```
- **Missing REUSE files**: Log error, skip task, continue batch
  ```bash
  .spec-flow/scripts/bash/task-tracker.sh mark-failed \
    -TaskId "T002" \
    -ErrorMessage "REUSE file not found: src/services/auth.ts (claimed in REUSE marker)" \
    -FeatureDir "$FEATURE_DIR"
  ```
- **Git conflicts**: Log conflict details, abort commit, instruct user to resolve, exit
  ```bash
  .spec-flow/scripts/bash/task-tracker.sh mark-failed \
    -TaskId "T003" \
    -ErrorMessage "Git conflict in src/models/user.ts - manual resolution required" \
    -FeatureDir "$FEATURE_DIR"
  exit 1
  ```
- **Linting failures**: Log linting errors, rollback, continue
  ```bash
  .spec-flow/scripts/bash/task-tracker.sh mark-failed \
    -TaskId "T004" \
    -ErrorMessage "ESLint: 5 errors in src/components/Button.tsx (see eslint output)" \
    -FeatureDir "$FEATURE_DIR"
  git restore .
  ```
- **Verification failures**: Log partial results, do not proceed to next phase
  ```bash
  .spec-flow/scripts/bash/task-tracker.sh mark-failed \
    -TaskId "VERIFY" \
    -ErrorMessage "Verification failed: 12/25 tasks passing tests, 13 tasks have failures" \
    -FeatureDir "$FEATURE_DIR"
  exit 2
  ```

---

## References

- TDD red-green-refactor: https://martinfowler.com/bliki/TestDrivenDevelopment.html
- Atomic commits per task: https://sethrobertson.github.io/GitBestPractices
- WIP limits reduce context switching: https://en.wikipedia.org/wiki/Kanban_(development)#Work-in-progress_limits
- Parallel speedup (Amdahl's Law): https://en.wikipedia.org/wiki/Amdahl%27s_law

---

## Philosophy

**Parallel execution with sequential safety**: Group independent tasks by domain; run TDD phases sequentially to respect dependencies.

**Atomic commits per task**: One commit per task with clear message and test evidence. Makes bisect/rollback sane.

**Auto-rollback on failure**: No prompts; ALWAYS log via task-tracker mark-failed BEFORE rollback, then continue. Speed over ceremony.

**REUSE enforcement**: Verify imports before claiming reuse. Log via mark-failed if pattern file missing, then skip task.

**WIP limits**: One batch `in_progress` at a time reduces context switching and improves throughput.

**Fail fast, fail loud**: MANDATORY error logging via task-tracker mark-failed for ALL failures (test, lint, REUSE, conflict). Never pretend success. Exit with meaningful codes: 0 (success), 1 (error), 2 (verification failed).
