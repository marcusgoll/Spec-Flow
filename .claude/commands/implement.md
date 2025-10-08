---
description: Execute tasks with TDD, anti-duplication checks, pattern following (parallel execution)
---

Execute tasks from: specs/$SLUG/tasks.md

## MENTAL MODEL

**Parallel Execution**: Group independent tasks by domain → Launch agents in parallel → Auto-handle failures → Commit batches

**No Stops Unless**: Blocking error, missing context, user clarification required

**Speed**: 3-5x faster via parallel agent execution

## LOAD FEATURE

```bash
SLUG="${ARGUMENTS:-$(git branch --show-current)}"
FEATURE_DIR="specs/$SLUG"
TASKS_FILE="$FEATURE_DIR/tasks.md"
ERROR_LOG="$FEATURE_DIR/error-log.md"
NOTES_FILE="$FEATURE_DIR/NOTES.md"

[ ! -d "$FEATURE_DIR" ] && echo "❌ Feature not found: $FEATURE_DIR" && exit 1
[ ! -f "$TASKS_FILE" ] && echo "❌ Run /tasks first" && exit 1
```

## PARSE TASKS & DETECT PARALLEL BATCHES

```bash
# Extract incomplete tasks
mapfile -t ALL_TASKS < <(grep "^T[0-9]\{3\}" "$TASKS_FILE")
PENDING_TASKS=()

for task in "${ALL_TASKS[@]}"; do
  TASK_ID=$(echo "$task" | grep -o "^T[0-9]\{3\}")
  grep -q "✅ $TASK_ID" "$NOTES_FILE" 2>/dev/null || PENDING_TASKS+=("$task")
done

echo "📋 ${#PENDING_TASKS[@]} tasks to execute (parallel batches)"
```

## GROUP INTO PARALLEL BATCHES

```bash
# Detect task dependencies and domain
group_tasks_by_dependency() {
  local batches=()
  local current_batch=()
  local last_domain=""

  for task in "${PENDING_TASKS[@]}"; do
    TASK_ID=$(echo "$task" | grep -o "^T[0-9]\{3\}")
    TASK_PHASE=$(echo "$task" | grep -o "\[RED\]\|\[GREEN→T[0-9]\{3\}\]\|\[REFACTOR\]\|\[P\]")
    TASK_DESC=$(echo "$task" | sed 's/^T[0-9]\{3\} \[.*\] //')

    # Detect domain (backend/frontend/database/tests)
    DOMAIN=""
    [[ "$TASK_DESC" =~ api/.*\.py|backend|service|endpoint ]] && DOMAIN="backend"
    [[ "$TASK_DESC" =~ apps/.*\.tsx|frontend|component|page ]] && DOMAIN="frontend"
    [[ "$TASK_DESC" =~ migration|alembic|schema|database ]] && DOMAIN="database"
    [[ "$TASK_DESC" =~ test.*\.py|\.test\.ts|spec\.ts ]] && DOMAIN="tests"
    [[ -z "$DOMAIN" ]] && DOMAIN="general"

    # TDD phases must stay sequential (GREEN depends on RED, REFACTOR depends on GREEN)
    if [[ "$TASK_PHASE" =~ GREEN|REFACTOR ]]; then
      # Flush current batch (dependency boundary)
      [[ ${#current_batch[@]} -gt 0 ]] && batches+=("${current_batch[@]}") && current_batch=()
      current_batch=("$TASK_ID:$DOMAIN:$TASK_DESC")
      batches+=("${current_batch[@]}")
      current_batch=()
      continue
    fi

    # Group parallel tasks by domain (max 3-4 per batch for clarity)
    if [ "$DOMAIN" != "$last_domain" ] || [ ${#current_batch[@]} -ge 3 ]; then
      [[ ${#current_batch[@]} -gt 0 ]] && batches+=("${current_batch[@]}")
      current_batch=()
    fi

    current_batch+=("$TASK_ID:$DOMAIN:$TASK_DESC")
    last_domain="$DOMAIN"
  done

  # Flush remaining
  [[ ${#current_batch[@]} -gt 0 ]] && batches+=("${current_batch[@]}")

  echo "${batches[@]}"
}

BATCHES=($(group_tasks_by_dependency))
```

## EXECUTE BATCHES IN PARALLEL

```bash
for batch in "${BATCHES[@]}"; do
  IFS='|' read -ra TASKS_IN_BATCH <<< "$batch"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀 Batch: ${#TASKS_IN_BATCH[@]} tasks (parallel)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Prepare parallel agent invocations
  for task_info in "${TASKS_IN_BATCH[@]}"; do
    IFS=':' read -r TASK_ID DOMAIN TASK_DESC <<< "$task_info"

    echo "  → $TASK_ID [$DOMAIN]: $TASK_DESC"

    # Determine agent
    AGENT=""
    case "$DOMAIN" in
      backend) AGENT="backend-dev" ;;
      frontend) AGENT="frontend-shipper" ;;
      database) AGENT="database-architect" ;;
      tests) AGENT="qa-test" ;;
      *) AGENT="general-purpose" ;;
    esac

    # Gather context for agent
    CONTEXT="Feature: $SLUG\nTask: $TASK_ID\n"
    [[ -f "$FEATURE_DIR/spec.md" ]] && CONTEXT+="Spec: $FEATURE_DIR/spec.md\n"

    # Extract REUSE markers if exist
    REUSE=$(grep -A 5 "^$TASK_ID" "$TASKS_FILE" | grep "REUSE:" | sed 's/.*REUSE: //' | head -3)
    [[ -n "$REUSE" ]] && CONTEXT+="REUSE: $REUSE\n"

    # Launch agent (Claude Code will run these in parallel if multiple in same message)
    echo ""
    echo "Invoking Task tool for $TASK_ID with $AGENT agent..."

    # Use Task tool - will be invoked in parallel with others in same message
    # Actual invocation happens via Claude Code Task tool
  done

  echo ""
  echo "⏳ Waiting for batch to complete..."
  echo ""

  # Claude Code: Invoke all agents for this batch in parallel using Task tool
  # This is done by making multiple Task() calls in a single response message
  #
  # For each task in batch:
  #   Task(
  #     subagent_type=AGENT,
  #     description="$TASK_ID: $TASK_DESC",
  #     prompt=f"""Implement: {TASK_DESC}
  #
  #     Context: {CONTEXT}
  #
  #     Requirements:
  #     - TDD if RED/GREEN/REFACTOR phase
  #     - REUSE files if marked
  #     - Run tests, provide evidence
  #     - Auto-rollback on failure
  #     - Commit when complete
  #
  #     Return: Summary, files changed, test results, verification status
  #     """
  #   )

  # Validate batch results
  for task_info in "${TASKS_IN_BATCH[@]}"; do
    IFS=':' read -r TASK_ID DOMAIN TASK_DESC <<< "$task_info"

    # Check if task completed (agent should have updated NOTES.md)
    if grep -q "✅ $TASK_ID" "$NOTES_FILE" 2>/dev/null; then
      echo "✅ $TASK_ID complete"
    else
      echo "⚠️  $TASK_ID - check agent output"
      echo "  ⚠️  $TASK_ID: Agent did not complete" >> "$ERROR_LOG"
    fi
  done

  echo "✅ Batch complete"
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All tasks complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

## IMPLEMENTATION EXECUTION (Claude Code)

**When Claude Code invokes /implement, follow this pattern:**

1. **Parse batches** from bash logic above
2. **For each batch**: Launch parallel Task() calls in single message
3. **Task parameters per agent**:

```python
# Example: 3 tasks in parallel batch (backend, frontend, database)

Task(
  subagent_type="backend-dev",
  description="T001: Create Message model",
  prompt=f"""
Task T001: Create Message model in api/app/models/message.py

Context:
- Feature: {SLUG}
- REUSE: api/app/models/user.py (pattern)
- Spec: {FEATURE_DIR}/spec.md

Requirements:
- SQLAlchemy model with validation
- TDD: Write failing test first if [RED] phase
- Run pytest api/tests/, provide evidence
- Auto-rollback on failure
- Commit when tests pass
- Update NOTES.md: "✅ T001: Create Message model"

Return: Files changed, test results, verification status
  """
)

Task(
  subagent_type="frontend-shipper",
  description="T002: Create MessageForm component",
  prompt=f"""
Task T002: Create MessageForm component in apps/app/components/MessageForm.tsx

Context:
- Feature: {SLUG}
- Polished mockup: apps/web/mock/{SLUG}/message-form/polished/
- Design tokens: design/systems/tokens.json
- REUSE: apps/app/components/Form.tsx

Requirements:
- Copy layout from polished mockup
- Add real API integration (NOT in mockup)
- Add analytics instrumentation
- Run pnpm test, provide evidence
- Auto-rollback on failure
- Commit when complete
- Update NOTES.md: "✅ T002: MessageForm component"

Return: Files changed, test results, verification status
  """
)

Task(
  subagent_type="database-architect",
  description="T003: Add messages table migration",
  prompt=f"""
Task T003: Generate Alembic migration for messages table

Context:
- Feature: {SLUG}
- Existing migrations: api/alembic/versions/
- Schema: api/app/models/message.py

Requirements:
- Generate migration: uv run alembic revision --autogenerate
- Test up/down cycle
- Auto-rollback on failure
- Commit migration file
- Update NOTES.md: "✅ T003: messages table migration"

Return: Migration file, test results, verification status
  """
)
```

## AGENT EXECUTION GUIDELINES

**Agents must follow these rules:**

### TDD Phases (strict sequential order)

**RED Phase** [RED]:
- Write failing test first
- Test must fail for right reason
- Provide test output as evidence
- Auto-rollback if test passes (wrong!)
- Commit: `test(red): TXXX write failing test`

**GREEN Phase** [GREEN→TXXX]:
- Minimal implementation to pass RED test
- Run tests, must pass
- Auto-rollback on failure → log to error-log.md
- Commit: `feat(green): TXXX implement to pass test`

**REFACTOR Phase** [REFACTOR]:
- Clean up code (DRY, KISS)
- Tests must stay green
- Auto-rollback if tests break
- Commit: `refactor: TXXX clean up implementation`

### Auto-Rollback (NO prompts)

**On failure:**
```bash
git restore .
echo "⚠️  TXXX: Auto-rolled back (test failure)" >> error-log.md
# Continue to next task
```

### REUSE Enforcement

**Before implementing:**
1. Check REUSE markers in tasks.md
2. Read referenced files
3. Import/extend existing code
4. Flag if claimed REUSE but no import

### Polished Mockup Integration (frontend only)

**If `apps/web/mock/$SLUG/[screen]/polished/` exists:**
- Copy: Layout, components, tokens, a11y
- Add: Real API calls, state, analytics, feature flags
- Remove: Mock data, console.logs, "Mock" labels

## VALIDATION & QUALITY GATES

**Agents must provide evidence:**
- Test execution output (pass/fail, execution time)
- Coverage numbers if applicable
- Lint/type-check status
- Verification that REUSE files were actually imported

**Quality gates (agents auto-enforce):**
- Tests <2s (unit), <10s (integration), <6min (suite)
- Coverage ≥80% line/branch
- No snapshots in frontend tests (use semantic queries)
- Lint/type-check clean

## NOTES.md CHECKPOINTS

**Agents must update after each task:**
```markdown
✅ TXXX [PHASE]: Task description
  - Evidence: pytest/jest output ✓
  - Coverage: XX% (+ΔΔ%)
  - Committed: [git hash]
```

## CONSTRAINTS

- **Parallel execution**: 3-5 tasks per batch (independent domains)
- **TDD strict**: RED → GREEN → REFACTOR (sequential within batch)
- **Auto-rollback**: No prompts, log failures to error-log.md
- **REUSE enforcement**: Verify imports, fail if pattern file missing
- **Commit per task**: Include evidence in commit message

## RETURN

**After batch completion:**
```
✅ Batch N complete (X tasks)
  - Backend: T001, T003 ✓
  - Frontend: T002 ✓
  - Tests: 18/18 passing
  - Coverage: 85% average
  - Failures: None (or logged in error-log.md)

Next batch: N+1 (Y tasks pending)
```

**On /implement completion:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ All tasks complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: XX tasks executed
Time: ~3-5x faster (parallel execution)
Failures: N (see error-log.md)

Next: /optimize
```
