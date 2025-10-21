---
description: Execute tasks with TDD, anti-duplication checks, pattern following (parallel execution)
---

Execute tasks from: specs/$SLUG/tasks.md

<context>
## MENTAL MODEL

**Parallel Execution**: Group independent tasks by domain → Launch agents in parallel → Auto-handle failures → Commit batches

**No Stops Unless**: Blocking error, missing context, user clarification required

**Speed**: 3-5x faster via parallel agent execution
</context>

## TASK TRACKING

**IMPORTANT**: Use the TodoWrite tool to track task execution throughout this command.

**At start** - Create todo list from tasks.md:

```javascript
TodoWrite({
  todos: [
    {content: "Validate checklists", status: "pending", activeForm: "Validating checklists"},
    {content: "Parse tasks from tasks.md", status: "pending", activeForm: "Parsing tasks"},
    {content: "Execute T001: [task description]", status: "pending", activeForm: "Executing T001"},
    {content: "Execute T002: [task description]", status: "pending", activeForm: "Executing T002"},
    // ... one entry per task from tasks.md (typically 20-30 tasks)
    {content: "Verify all implementations", status: "pending", activeForm: "Verifying implementations"},
    {content: "Run final test suite", status: "pending", activeForm": "Running final tests"},
  ]
})
```

**During execution**:
- Mark task as `in_progress` when starting it
- Mark as `completed` IMMEDIATELY after finishing each task
- Update to `failed` or blocked status if issues occur
- Only ONE task should be `in_progress` at a time

**Why**: Users need real-time visibility into which of 20-30 tasks are complete during long parallel execution (can take 15-30 minutes).

<constraints>
## ANTI-HALLUCINATION RULES

**CRITICAL**: Follow these rules to prevent making up information.

1. **Never speculate about code you have not read**
   - ❌ BAD: "The UserService probably has a create_user method"
   - ✅ GOOD: "Let me read api/app/services/user.py to see available methods"
   - If you need to know what's in a file, use the Read tool first

2. **Cite your sources with file paths**
   - When referencing code, include exact location: `file_path:line_number`
   - Example: "The User model is defined in api/app/models/user.py:15-42"
   - Example: "The create_user endpoint is in api/app/api/v1/users.py:78-95"

3. **Admit uncertainty explicitly**
   - If unclear about something, say: "I'm uncertain about [X]. Let me investigate by reading [file]"
   - Never make up: function names, API endpoints, database schemas, import paths, class names
   - If a file might not exist, check with Glob or Read before referencing it

4. **Quote before analyzing long documents**
   - For specs >5000 tokens, extract relevant quotes first
   - Then analyze the quotes, not your memory
   - Example: "According to spec.md lines 45-50: '[quote]', this means..."

5. **Verify file existence before importing/referencing**
   - Before writing `from app.services.user import UserService`, verify the file exists
   - Use Glob to find files: `**/*.py` pattern matching
   - Use Grep to find imports: search for existing import patterns

**Why this matters**: Hallucinated code references cause compile errors, broken imports, and failed tests. Reading files before referencing them prevents 60-70% of implementation errors.
</constraints>

<instructions>
## LOAD FEATURE

```bash
SLUG="${ARGUMENTS:-$(git branch --show-current)}"
FEATURE_DIR="specs/$SLUG"
TASKS_FILE="$FEATURE_DIR/tasks.md"
ERROR_LOG="$FEATURE_DIR/error-log.md"
NOTES_FILE="$FEATURE_DIR/NOTES.md"

# Initialize task tracker for atomic status updates
TASK_TRACKER=".spec-flow/scripts/bash/task-tracker.sh"

[ ! -d "$FEATURE_DIR" ] && echo "❌ Feature not found: $FEATURE_DIR" && exit 1
[ ! -f "$TASKS_FILE" ] && echo "❌ Run /tasks first" && exit 1
[ ! -f "$TASK_TRACKER" ] && echo "⚠️  Warning: task-tracker not found" && TASK_TRACKER=""
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
      backend) AGENT="implementation/backend" ;;
      frontend) AGENT="implementation/frontend" ;;
      database) AGENT="implementation/database" ;;
      tests) AGENT="quality/qa-tester" ;;
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

  # Validate batch results using task-tracker
  for task_info in "${TASKS_IN_BATCH[@]}"; do
    IFS=':' read -r TASK_ID DOMAIN TASK_DESC <<< "$task_info"

    # Use task-tracker to check authoritative task status
    if [ -n "$TASK_TRACKER" ]; then
      # Query task status via task-tracker (checks both tasks.md and NOTES.md)
      TASK_COMPLETED=$(pwsh -File "${TASK_TRACKER/bash\//powershell/}" status -FeatureDir "$FEATURE_DIR" -Json 2>/dev/null | \
        jq -r ".CompletedTasks[] | select(.Id == \"$TASK_ID\") | .Id" || echo "")

      if [ "$TASK_COMPLETED" = "$TASK_ID" ]; then
        echo "✅ $TASK_ID complete"
      else
        echo "⚠️  $TASK_ID incomplete - check agent output"
        # Log failure
        if [ -n "$TASK_TRACKER" ]; then
          pwsh -File "${TASK_TRACKER/bash\//powershell/}" mark-failed \
            -TaskId "$TASK_ID" \
            -ErrorMessage "Agent did not mark task as complete" \
            -FeatureDir "$FEATURE_DIR" 2>/dev/null || true
        fi
      fi
    else
      # Fallback to manual NOTES.md check
      if grep -q "✅ $TASK_ID" "$NOTES_FILE" 2>/dev/null; then
        echo "✅ $TASK_ID complete"
      else
        echo "⚠️  $TASK_ID - check agent output"
        echo "  ⚠️  $TASK_ID: Agent did not complete" >> "$ERROR_LOG"
      fi
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
      echo "  • If 'ship' or 'A':"
      echo "    1. Call roadmap-manager to capture P2/P3 tasks"
      echo "    2. Echo 'Run /preview to validate MVP' and exit"
      echo "  • If 'continue' or 'B': Continue to remaining batches (P2 tasks)"
      echo ""
      # Note: In actual implementation, Claude Code will pause here
      # This is a manual gate - execution stops until user responds
      #
      # When user chooses 'ship', execute:
      # source .spec-flow/scripts/bash/roadmap-manager.sh
      # add_future_enhancements_to_roadmap "$FEATURE_DIR" "$SLUG"
      # echo ""
      # echo "Next: /preview to validate MVP"
      # exit 0
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
3. **MVP Gate Handling** (User Story Format Only):
   - After P1 tasks complete, check if P2+ tasks exist
   - If P2/P3 tasks exist:
     - Display MVP gate message to user
     - Ask: "Ship MVP now or continue to P2? (ship/continue)"
     - Wait for user response
     - If user says "ship" or "A":
       ```bash
       # Load roadmap manager functions
       source .spec-flow/scripts/bash/roadmap-manager.sh

       # Add future enhancements to roadmap
       add_future_enhancements_to_roadmap "$FEATURE_DIR" "$SLUG"

       # Exit with next step
       echo ""
       echo "Next: /preview to validate MVP"
       exit 0
       ```
     - If user says "continue" or "B": Continue executing remaining P2/P3 batches
4. **Task parameters per agent**:

```python
# Example: 3 tasks in parallel batch (backend, frontend, database)

Task(
  subagent_type="implementation/backend",
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
- **Update task status via task-tracker (DO NOT manually edit NOTES.md):**
  ```bash
  .spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
    -TaskId "T001" \
    -Notes "Created Message model with validation" \
    -Evidence "pytest: 25/25 passing" \
    -Coverage "92% line (+8%)" \
    -CommitHash "$(git rev-parse --short HEAD)" \
    -FeatureDir "$FEATURE_DIR"
  ```
  This atomically updates BOTH tasks.md and NOTES.md

Return: Files changed, test results, task-tracker confirmation
  """
)

Task(
  subagent_type="implementation/frontend",
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
- **Update task status via task-tracker:**
  ```bash
  .spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
    -TaskId "T002" \
    -Notes "MessageForm component with API integration" \
    -Evidence "jest: 12/12 passing, a11y: 0 violations" \
    -Coverage "88% (+6%)" \
    -CommitHash "$(git rev-parse --short HEAD)" \
    -FeatureDir "$FEATURE_DIR"
  ```

Return: Files changed, test results, task-tracker confirmation
  """
)

Task(
  subagent_type="implementation/database",
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
- **Update task status via task-tracker:**
  ```bash
  .spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
    -TaskId "T003" \
    -Notes "messages table migration with FK constraints" \
    -Evidence "Migration up/down cycle tested successfully" \
    -CommitHash "$(git rev-parse --short HEAD)" \
    -FeatureDir "$FEATURE_DIR"
  ```

Return: Migration file, test results, task-tracker confirmation
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
- **Commit immediately after test written:**
  ```bash
  git add .
  git commit -m "test(red): TXXX write failing test

Test: $TEST_NAME
Expected: FAILED (ImportError/NotImplementedError)
Evidence: $(pytest output showing failure)"
  ```

**GREEN Phase** [GREEN→TXXX]:
- Minimal implementation to pass RED test
- Run tests, must pass
- Auto-rollback on failure → log to error-log.md
- **Commit when tests pass:**
  ```bash
  git add .
  git commit -m "feat(green): TXXX implement to pass test

Implementation: $SUMMARY
Tests: All passing ($PASS/$TOTAL)
Coverage: $COV% (+$DELTA%)"
  ```

**REFACTOR Phase** [REFACTOR]:
- Clean up code (DRY, KISS)
- Tests must stay green
- Auto-rollback if tests break
- **Commit after refactoring:**
  ```bash
  git add .
  git commit -m "refactor: TXXX clean up implementation

Improvements: $IMPROVEMENTS
Tests: Still passing ($PASS/$TOTAL)
Coverage: Maintained at $COV%"
  ```

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

## TASK STATUS UPDATES (MANDATORY)

**Agents MUST use task-tracker to update status (DO NOT manually edit NOTES.md or tasks.md):**

**After successful task completion:**
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId "TXXX" \
  -Notes "Implementation summary (1-2 sentences)" \
  -Evidence "pytest: NN/NN passing" or "jest: NN/NN passing, a11y: 0 violations" \
  -Coverage "NN% line, NN% branch (+ΔΔ%)" \
  -CommitHash "$(git rev-parse --short HEAD)" \
  -FeatureDir "$FEATURE_DIR"
```

**On task failure (auto-rollback scenarios):**
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-failed \
  -TaskId "TXXX" \
  -ErrorMessage "Detailed error description" \
  -FeatureDir "$FEATURE_DIR"
```

**Why task-tracker?**
- Atomically updates BOTH tasks.md checkbox AND NOTES.md completion marker
- Prevents desync between the two files
- Standardized format with evidence tracking
- Automatic phase marker extraction
- Traceability via commit hash

**Generated NOTES.md format:**
```markdown
✅ TXXX [PHASE]: Task description
  - Evidence: pytest/jest output ✓
  - Coverage: XX% (+ΔΔ%)
  - Committed: [git hash]
```

**Note**: [PHASE] auto-extracted from tasks.md ([RED], [GREEN], [REFACTOR], [US1], [P1], [P]).

## CONSTRAINTS

- **Parallel execution**: 3-5 tasks per batch (independent domains)
- **TDD strict**: RED → GREEN → REFACTOR (sequential within batch)
- **Auto-rollback**: No prompts, log failures to error-log.md
- **REUSE enforcement**: Verify imports, fail if pattern file missing
- **Commit per task**: Include evidence in commit message

## COMMIT FINAL IMPLEMENTATION

**After all tasks complete, final commit:**

```bash
# Check task completion
COMPLETED=$(grep -c "^✅ T[0-9]\{3\}" "$NOTES_FILE" 2>/dev/null || echo 0)
TOTAL=$(grep -c "^- \[ \] T[0-9]\{3\}" "$TASKS_FILE" 2>/dev/null || echo 0)

# Count by priority if user story format
if [ "$TASK_FORMAT" = "user-story" ]; then
  P1_TOTAL=$(grep -c "\[P1\]" "$TASKS_FILE" 2>/dev/null || echo 0)
  P1_COMPLETE=$(grep -c "✅.*\[P1\]" "$NOTES_FILE" 2>/dev/null || echo 0)
  P2_COUNT=$(grep -c "\[P2\]" "$TASKS_FILE" 2>/dev/null || echo 0)
  P3_COUNT=$(grep -c "\[P3\]" "$TASKS_FILE" 2>/dev/null || echo 0)
  MVP_SHIPPED=$([ "$P1_COMPLETE" -eq "$P1_TOTAL" ] && echo "true" || echo "false")
fi

# Stage all implementation artifacts
git add .

# Commit with implementation summary
if [ "$TASK_FORMAT" = "user-story" ] && [ "$MVP_SHIPPED" = "true" ]; then
  # MVP commit (P1 only)
  git commit -m "feat(mvp): complete P1 (MVP) implementation for $(basename "$FEATURE_DIR")

MVP tasks: $P1_COMPLETE/$P1_TOTAL ✅
Tests: All passing
Deferred to roadmap: P2 ($P2_COUNT), P3 ($P3_COUNT)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
else
  # Full implementation commit
  git commit -m "feat(implement): complete implementation for $(basename "$FEATURE_DIR")

Tasks: $COMPLETED/$TOTAL ✅
Tests: All passing

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
fi

# Verify commit succeeded
COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""
echo "✅ Implementation committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""
```

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
</instructions>
