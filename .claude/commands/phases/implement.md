---
description: Execute tasks with TDD, anti-duplication checks, pattern following (parallel execution)
---

# /implement — Parallel Task Execution with TDD

**Purpose**: Execute all tasks from `specs/<slug>/tasks.md` with parallel batching, strict TDD phases, auto-rollback on failure, and atomic commits.

**Command**: `/implement [slug]`

**When to use**: After `/tasks` completes. Runs all pending tasks, stopping only on critical blockers.

---

## Mental Model

**Flow**: preflight → execute (parallel batches) → wrap-up

**Parallelism**: Group independent tasks by domain; keep TDD phases sequential within a task. Speedup bounded by dependency share (Amdahl's Law).

**Do not stop unless**: Missing files, repo-wide test suite failure, git conflicts.

---

## Anti-Hallucination Rules

1. **Never speculate about code you have not read**
   Always `Read` files before referencing them.

2. **Cite your sources with file paths**
   Include exact location: `file_path:line_number`

3. **Admit uncertainty explicitly**
   Say "I'm uncertain about [X]. Let me investigate by reading [file]" instead of guessing.

4. **Quote before analyzing long documents**
   For specs >5000 tokens, extract relevant quotes first.

5. **Verify file existence before importing/referencing**
   Use Glob to find files; use Grep to find existing import patterns.

**Why**: Hallucinated code references cause compile errors, broken imports, and failed tests. Reading files before referencing prevents 60-70% of implementation errors.

---

## Reasoning Template

Use this template when making implementation decisions:

```text
<thinking>
1) What does the task require? [Quote acceptance criteria]
2) What existing code can I reuse? [Cite file:line]
3) What patterns does plan.md recommend? [Quote]
4) What are the trade-offs? [List pros/cons]
5) Conclusion: [Decision with justification]
</thinking>
<answer>
[Implementation approach based on reasoning]
</answer>
```

Use for: choosing implementation approaches, reuse decisions, debugging multi-step failures, prioritizing task order.

---

## Workflow Tracking

Use TodoWrite to track batch execution progress.

**Initialize todos**:

```javascript
TodoWrite({
  todos: [
    {content:"Validate preflight checks",status:"pending",activeForm:"Preflight"},
    {content:"Parse tasks and detect batches",status:"pending",activeForm:"Parsing tasks"},
    {content:"Execute batch 1",status:"pending",activeForm:"Running batch 1"},
    {content:"Execute batch 2",status:"pending",activeForm:"Running batch 2"},
    // ... one entry per batch (typically 5-10 batches)
    {content:"Verify all implementations",status:"pending",activeForm:"Verifying"},
    {content:"Commit final summary",status:"pending",activeForm:"Committing"}
  ]
})
```

**Rules**:
- Exactly one batch is `in_progress` at a time (WIP limit reduces context switching)
- Mark batch `completed` immediately after finishing
- Update to `failed` if batch encounters critical blocker

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
# EXECUTE BATCHES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

batch_num=0
for batch in "${BATCHES[@]}"; do
  batch_num=$((batch_num+1))
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀 Batch $batch_num/${#BATCHES[@]}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  IFS='|' read -ra TASKS <<< "$batch"

  # Display tasks in batch
  for t in "${TASKS[@]}"; do
    IFS=':' read -r id dom phase desc <<< "$t"
    echo "  → $id [$dom $phase]: $desc"
  done
  echo ""

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # EXECUTE TASKS IN BATCH (Claude Code performs)
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  # For each task in TASKS array, Claude Code will:
  # 1. Read task requirements from tasks.md
  # 2. Check for REUSE markers and read referenced files
  # 3. Implement according to TDD phase (RED/GREEN/REFACTOR) or general
  # 4. Run tests and verify acceptance criteria
  # 5. Update task tracker with status
  # 6. Commit with atomic commit message
  #
  # Claude Code uses appropriate agents based on domain:
  # - backend: backend-dev agent
  # - frontend: frontend-shipper agent
  # - database: database-architect agent
  # - tests: qa-test agent
  # - general: general-purpose agent
  #
  # Each agent returns: {files_changed, test_results, verification_status}

  # After batch completes, validate results
  for t in "${TASKS[@]}"; do
    IFS=':' read -r id dom phase desc <<< "$t"

    # Use task-tracker to check authoritative status
    if [ -x "$TRACKER" ]; then
      COMPLETED=$("$TRACKER" status -FeatureDir "$FEATURE_DIR" -Json 2>/dev/null | \
        jq -r ".CompletedTasks[] | select(.Id == \"$id\") | .Id" 2>/dev/null || echo "")

      if [ "$COMPLETED" = "$id" ]; then
        echo "✅ $id complete"
      else
        echo "⚠️  $id incomplete - check agent output"
        "$TRACKER" mark-failed -TaskId "$id" -ErrorMessage "Agent did not complete" -FeatureDir "$FEATURE_DIR" 2>/dev/null || true
      fi
    else
      # Fallback to NOTES.md check
      if grep -q "✅ $id" "$NOTES_FILE" 2>/dev/null; then
        echo "✅ $id complete"
      else
        echo "⚠️  $id incomplete"
        echo "  ⚠️  $id: Agent did not complete" >> "$ERROR_LOG"
      fi
    fi
  done

  echo ""
  echo "✅ Batch $batch_num complete"
  echo ""
done

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
git restore .
echo "⚠️  TXXX: Auto-rolled back (test failure)" >> error-log.md
# Continue to next task
```

### REUSE Enforcement

Before implementing:
1. Check REUSE markers in tasks.md
2. Read referenced files
3. Import/extend existing code
4. Flag if claimed REUSE but no import

### Task Status Updates (mandatory)

After successful task completion:
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId "TXXX" \
  -Notes "Implementation summary (1-2 sentences)" \
  -Evidence "pytest: NN/NN passing" or "jest: NN/NN passing, a11y: 0 violations" \
  -Coverage "NN% line, NN% branch (+ΔΔ%)" \
  -CommitHash "$(git rev-parse --short HEAD)" \
  -FeatureDir "$FEATURE_DIR"
```

On task failure:
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-failed \
  -TaskId "TXXX" \
  -ErrorMessage "Detailed error description" \
  -FeatureDir "$FEATURE_DIR"
```

---

## Error Handling

- **Test failures**: Auto-rollback, log to error-log.md, continue to next task
- **Missing REUSE files**: Fail task, log error, continue
- **Git conflicts**: Abort commit, instruct user to resolve, exit
- **Verification failures**: Record partial results, do not proceed

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

**Auto-rollback on failure**: No prompts; log failures and continue. Speed over ceremony.

**REUSE enforcement**: Verify imports before claiming reuse. Fail task if pattern file missing.

**WIP limits**: One batch `in_progress` at a time reduces context switching and improves throughput.

**Fail fast, fail loud**: Record failures in error-log.md; never pretend success. Exit with meaningful codes: 0 (success), 1 (error), 2 (verification failed).
