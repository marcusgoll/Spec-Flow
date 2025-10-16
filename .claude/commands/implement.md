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

## CHECKLIST VALIDATION (Quality Gate)

```bash
# Only run if checklists directory exists
if [ -d "$FEATURE_DIR/checklists" ]; then
  echo "📋 Validating requirement checklists..."

  # Initialize counters
  declare -A CHECKLIST_STATUS
  TOTAL_CHECKLISTS=0
  INCOMPLETE_CHECKLISTS=0

  # Scan all checklist files
  for checklist_file in "$FEATURE_DIR/checklists"/*.md; do
    [ ! -f "$checklist_file" ] && continue

    CHECKLIST_NAME=$(basename "$checklist_file")
    TOTAL_ITEMS=$(grep -c "^- \[[ Xx]\]" "$checklist_file" || echo "0")
    COMPLETED_ITEMS=$(grep -c "^- \[[Xx]\]" "$checklist_file" || echo "0")
    INCOMPLETE_ITEMS=$((TOTAL_ITEMS - COMPLETED_ITEMS))

    CHECKLIST_STATUS["$CHECKLIST_NAME"]="$TOTAL_ITEMS|$COMPLETED_ITEMS|$INCOMPLETE_ITEMS"
    TOTAL_CHECKLISTS=$((TOTAL_CHECKLISTS + 1))

    [ $INCOMPLETE_ITEMS -gt 0 ] && INCOMPLETE_CHECKLISTS=$((INCOMPLETE_CHECKLISTS + 1))
  done

  # Display status table if any checklists exist
  if [ $TOTAL_CHECKLISTS -gt 0 ]; then
    echo ""
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│ Checklist Validation Status                                 │"
    echo "├─────────────────┬───────┬───────────┬────────────┬─────────┤"
    echo "│ Checklist       │ Total │ Completed │ Incomplete │ Status  │"
    echo "├─────────────────┼───────┼───────────┼────────────┼─────────┤"

    for checklist_name in "${!CHECKLIST_STATUS[@]}"; do
      IFS='|' read -r total completed incomplete <<< "${CHECKLIST_STATUS[$checklist_name]}"
      status=$([ $incomplete -eq 0 ] && echo "✓ PASS" || echo "✗ FAIL")
      printf "│ %-15s │ %5s │ %9s │ %10s │ %-7s │\n" \
        "$checklist_name" "$total" "$completed" "$incomplete" "$status"
    done

    echo "└─────────────────┴───────┴───────────┴────────────┴─────────┘"
    echo ""

    # Gate: Ask user if incomplete
    if [ $INCOMPLETE_CHECKLISTS -gt 0 ]; then
      echo "⚠️  $INCOMPLETE_CHECKLISTS checklist(s) have incomplete items."
      echo ""
      echo "Checklists validate requirement quality BEFORE implementation."
      echo "Proceeding with incomplete checklists may result in:"
      echo "  • Ambiguous requirements causing rework"
      echo "  • Missing edge cases discovered during implementation"
      echo "  • Inconsistent requirements across domains"
      echo ""
      echo "USER PROMPT: Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
      # Claude Code: Pause here and ask user for confirmation
      # If user says "no": exit and recommend completing checklists first
      # If user says "yes": continue to task execution
    else
      echo "✅ All checklists complete. Proceeding with implementation."
    fi
  fi
fi
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

## DETECT TASK FORMAT

```bash
# Auto-detect task format to select appropriate parser
if grep -q "\[US[0-9]\]" "$TASKS_FILE"; then
  TASK_FORMAT="user-story"
  echo "📋 Format: User story (MVP-first delivery)"
elif grep -q "\[RED\]\|\[GREEN→T[0-9]\{3\}\]" "$TASKS_FILE"; then
  TASK_FORMAT="tdd-phase"
  echo "📋 Format: TDD phase (classic workflow)"
else
  # Default to TDD if ambiguous
  TASK_FORMAT="tdd-phase"
  echo "📋 Format: TDD phase (default)"
fi
echo ""
```

## GROUP INTO PARALLEL BATCHES

```bash
# TDD Phase Parser (classic workflow)
parse_tdd_tasks() {
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

# User Story Parser (MVP-first delivery)
parse_user_story_tasks() {
  local batches=()
  local current_batch=()

  # Group tasks by Priority (P1, P2, P3), then Story (US1, US2), then Domain
  declare -A tasks_by_priority_story

  for task in "${PENDING_TASKS[@]}"; do
    TASK_ID=$(echo "$task" | grep -o "^T[0-9]\{3\}")

    # Extract markers
    STORY_ID=$(echo "$task" | grep -o "\[US[0-9]\]" | grep -o "[0-9]" || echo "0")
    PRIORITY=$(echo "$task" | grep -o "\[P[0-9]\]" | grep -o "[0-9]" || echo "9")
    PARALLEL=$(echo "$task" | grep -o "\[P\]")
    TDD_PHASE=$(echo "$task" | grep -o "\[RED\]\|\[GREEN→T[0-9]\{3\}\]\|\[REFACTOR\]")

    # Extract description (handle various marker formats)
    TASK_DESC=$(echo "$task" | sed 's/^T[0-9]\{3\} //' | sed 's/\[US[0-9]\] //' | sed 's/\[P[0-9]\] //' | sed 's/\[P\] //')

    # Detect domain
    DOMAIN="general"
    [[ "$TASK_DESC" =~ api/|backend/|service|endpoint|\.py ]] && DOMAIN="backend"
    [[ "$TASK_DESC" =~ frontend/|component|page|apps/|\.tsx|\.jsx ]] && DOMAIN="frontend"
    [[ "$TASK_DESC" =~ migration|alembic|schema|database|sql ]] && DOMAIN="database"
    [[ "$TASK_DESC" =~ test.*\.py|\.test\.|\.spec\.|tests/ ]] && DOMAIN="tests"

    # Group key: priority.story (e.g., "1.1" for P1 US1)
    GROUP_KEY="${PRIORITY}.${STORY_ID}"

    # Store with all metadata (task_id:domain:story:priority:tdd_phase:description)
    tasks_by_priority_story[$GROUP_KEY]+="$TASK_ID:$DOMAIN:$STORY_ID:$PRIORITY:$TDD_PHASE:$TASK_DESC|"
  done

  # Sort by priority, then story (numeric sort on "priority.story")
  for key in $(echo "${!tasks_by_priority_story[@]}" | tr ' ' '\n' | sort -n); do
    IFS='|' read -ra TASKS_IN_GROUP <<< "${tasks_by_priority_story[$key]}"

    # Further group by domain within story (max 3 per batch for clarity)
    current_batch=()
    local last_domain=""

    for task_info in "${TASKS_IN_GROUP[@]}"; do
      [[ -z "$task_info" ]] && continue

      IFS=':' read -r tid dom sid pri phase desc <<< "$task_info"

      # TDD phases must stay sequential (GREEN depends on RED)
      if [[ "$phase" =~ GREEN|REFACTOR ]]; then
        # Flush current batch
        if [ ${#current_batch[@]} -gt 0 ]; then
          batches+=("$(IFS='|'; echo "${current_batch[*]}")")
          current_batch=()
        fi
        # Add TDD task as single-task batch
        batches+=("$task_info")
        last_domain=""
        continue
      fi

      # Group parallel tasks by domain (max 3 per batch)
      if [ "$dom" != "$last_domain" ] || [ ${#current_batch[@]} -ge 3 ]; then
        if [ ${#current_batch[@]} -gt 0 ]; then
          batches+=("$(IFS='|'; echo "${current_batch[*]}")")
          current_batch=()
        fi
      fi

      current_batch+=("$task_info")
      last_domain="$dom"
    done

    # Flush remaining tasks in story
    if [ ${#current_batch[@]} -gt 0 ]; then
      batches+=("$(IFS='|'; echo "${current_batch[*]}")")
      current_batch=()
    fi
  done

  echo "${batches[@]}"
}

# Route to appropriate parser based on format
if [ "$TASK_FORMAT" = "user-story" ]; then
  BATCHES=($(parse_user_story_tasks))
else
  BATCHES=($(parse_tdd_tasks))
fi

echo "📦 Organized into ${#BATCHES[@]} batches"
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
```

## MVP GATE (User Story Format Only)

```bash
# Check if all P1 tasks complete (MVP gate for user story format)
if [ "$TASK_FORMAT" = "user-story" ]; then
  P1_TOTAL=$(grep -c "\[P1\]" "$TASKS_FILE" 2>/dev/null || echo 0)
  P1_COMPLETE=$(grep -c "✅.*\[P1\]" "$NOTES_FILE" 2>/dev/null || echo 0)

  if [ "$P1_TOTAL" -gt 0 ] && [ "$P1_COMPLETE" -eq "$P1_TOTAL" ]; then
    # Check if P2 tasks exist
    P2_EXISTS=$(grep -q "\[P2\]" "$TASKS_FILE" && echo "true" || echo "false")

    if [ "$P2_EXISTS" = "true" ]; then
      P2_TOTAL=$(grep -c "\[P2\]" "$TASKS_FILE" 2>/dev/null || echo 0)

      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "🎯 MVP GATE: Priority 1 Complete"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "All P1 (MVP) stories implemented: $P1_COMPLETE/$P1_TOTAL tasks ✅"
      echo ""
      echo "Remaining work:"
      echo "  • P2 enhancements: $P2_TOTAL tasks"
      echo ""
      echo "Options:"
      echo "  A) Ship MVP now → /preview then /phase-1-ship"
      echo "  B) Continue to P2 enhancements"
      echo ""
      echo "USER PROMPT: Ship MVP now or continue to P2? (ship/continue)"
      echo ""
      echo "Claude Code: Wait for user response"
      echo "  • If 'ship' or 'A': Echo 'Run /preview to validate MVP' and exit"
      echo "  • If 'continue' or 'B': Continue to remaining batches (P2 tasks)"
      echo ""
      # Note: In actual implementation, Claude Code will pause here
      # This is a manual gate - execution stops until user responds
    fi
  fi
fi
```

## COMPLETION SUMMARY

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All tasks complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

## IMPLEMENTATION EXECUTION (Claude Code)

**When Claude Code invokes /implement, follow this pattern:**

0. **Checklist Validation** (Pre-flight Quality Gate):
   - Execute checklist validation logic from CHECKLIST VALIDATION section
   - If checklists exist and have incomplete items:
     - Display the status table to user
     - Ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     - Wait for user response
     - If user says "no" or "wait" or "stop": Exit with message "Complete checklists first before implementing"
     - If user says "yes" or "proceed" or "continue": Continue to step 1
   - If all checklists complete or no checklists exist: Continue to step 1 automatically

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

**User Story Format:**
```markdown
✅ TXXX [USN] [PN]: Task description
  - Evidence: pytest/jest output ✓
  - Coverage: XX% (+ΔΔ%)
  - Committed: [git hash]
```

**TDD Phase Format:**
```markdown
✅ TXXX [PHASE]: Task description
  - Evidence: pytest/jest output ✓
  - Coverage: XX% (+ΔΔ%)
  - Committed: [git hash]
```

**Note**: Format auto-detected based on task markers. [USN] = User Story number (e.g., [US1]), [PN] = Priority (e.g., [P1]), [PHASE] = TDD phase (e.g., [RED], [GREEN]).

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
