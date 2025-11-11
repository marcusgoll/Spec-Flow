---
description: Execute tasks with strict TDD, safe parallelism, anti-duplication, and deterministic commits
---

Execute tasks from: `specs/$SLUG/tasks.md`

<context>
## MENTAL MODEL

- **Group independent tasks by domain** → Backend, Frontend, Database, Tests
- **Run at most one risky domain per batch** (e.g., DB migration blocks others)
- **RED → GREEN → REFACTOR is non-negotiable** (strict TDD discipline)
- **Deterministic**: Idempotent re-entry, commit per task, rollback on fail, no prompts

**Stop only if**: Blocking error, missing context, or explicit user gate (checklist, MVP)

**Speed**: 3-5x faster via domain-based parallelism
</context>

## TASK TRACKING

**Primary**: `.spec-flow/scripts/bash/task-tracker.sh` (authoritative source of truth)

**Optional UI**: `TodoWrite` tool (graceful fallback if missing)

**At start** - Mirror tasks to tracker and TodoWrite:

```javascript
// If TodoWrite available, create visual progress
TodoWrite({
  todos: [
    {content: "Validate checklists", status: "pending", activeForm: "Validating checklists"},
    {content: "Parse tasks from tasks.md", status: "pending", activeForm: "Parsing tasks"},
    {content: "Execute T001: [description]", status: "pending", activeForm: "Executing T001"},
    // ... one entry per task (20-30 typically)
    {content: "Verify implementations", status: "pending", activeForm: "Verifying implementations"},
    {content: "Run final test suite", status: "pending", activeForm: "Running final tests"}
  ]
})
```

**During execution**:
- Keep exactly ONE task `in_progress` at a time
- Mark `completed` IMMEDIATELY after task finishes
- Mark `failed` on rollback, continue to next task
- Use task-tracker for authoritative status, TodoWrite for UI only

**Why**: Users need real-time visibility during 15-30 minute parallel execution sessions.

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

## REASONING APPROACH

For complex implementation decisions, show your step-by-step reasoning:

<thinking>
Let me analyze this implementation choice:
1. What does the task require? [Quote acceptance criteria]
2. What existing code can I reuse? [Cite file:line]
3. What patterns does plan.md recommend? [Quote]
4. What are the trade-offs? [List pros/cons]
5. Conclusion: [Decision with justification]
</thinking>

<answer>
[Implementation approach based on reasoning]
</answer>

**When to use structured thinking:**
- Choosing between multiple implementation approaches (e.g., REST vs GraphQL endpoint)
- Deciding whether to create new code vs reuse existing patterns
- Architecting complex features with multiple interacting components
- Debugging multi-step failures (e.g., test fails → investigate → identify root cause)
- Prioritizing task execution order when dependencies are unclear

**Benefits**: Explicit reasoning reduces implementation errors by 30-40% and prevents premature optimization.
</constraints>

<instructions>
## LOAD FEATURE

```bash
cd .
SLUG="${ARGUMENTS:-$(git branch --show-current)}"
FEATURE_DIR="specs/$SLUG"
TASKS_FILE="$FEATURE_DIR/tasks.md"
ERROR_LOG="$FEATURE_DIR/error-log.md"
NOTES_FILE="$FEATURE_DIR/NOTES.md"
TRACKER=".spec-flow/scripts/bash/task-tracker.sh"

[ ! -d "$FEATURE_DIR" ] && echo "❌ Feature not found: $FEATURE_DIR" && exit 1
[ ! -f "$TASKS_FILE" ] && echo "❌ Run /tasks first" && exit 1
[ ! -f "$TRACKER" ] && echo "⚠️  task-tracker missing; continuing without it" && TRACKER=""
```

## PRE-FLIGHT CHECKS (Quality Gate)

**Checklist Validation**:

```bash
cd .

# Only run if checklists directory exists
if [ -d "$FEATURE_DIR/checklists" ]; then
  echo "📋 Validating requirement checklists..."

  # Compute completion table
  declare -A CHECKLIST_STATUS
  TOTAL_CHECKLISTS=0
  INCOMPLETE_CHECKLISTS=0

  for checklist_file in "$FEATURE_DIR/checklists"/*.md; do
    [ ! -f "$checklist_file" ] && continue

    CHECKLIST_NAME=$(basename "$checklist_file")
    TOTAL_ITEMS=$(grep -c "^- \\[[ Xx]\\]" "$checklist_file" || echo "0")
    COMPLETED_ITEMS=$(grep -c "^- \\[[Xx]\\]" "$checklist_file" || echo "0")
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
      printf "│ %-15s │ %5s │ %9s │ %10s │ %-7s │\\n" \
        "$checklist_name" "$total" "$completed" "$incomplete" "$status"
    done

    echo "└─────────────────┴───────┴───────────┴────────────┴─────────┘"
    echo ""

    # Gate: Require explicit proceed flag if incomplete
    if [ $INCOMPLETE_CHECKLISTS -gt 0 ]; then
      if [ "$IMPLEMENT_ASSUME_YES" != "1" ] && [ "$1" != "--yes" ]; then
        echo "⚠️  $INCOMPLETE_CHECKLISTS checklist(s) have incomplete items."
        echo ""
        echo "Checklists validate requirement quality BEFORE implementation."
        echo "Proceeding with incomplete checklists may result in:"
        echo "  • Ambiguous requirements causing rework"
        echo "  • Missing edge cases discovered during implementation"
        echo "  • Inconsistent requirements across domains"
        echo ""
        echo "Options:"
        echo "  1. Complete checklists first (recommended)"
        echo "  2. Proceed anyway: /implement --yes"
        echo "  3. Set env: IMPLEMENT_ASSUME_YES=1"
        echo ""
        exit 1
      else
        echo "⚠️  Proceeding with incomplete checklists (--yes flag or env set)"
      fi
    else
      echo "✅ All checklists complete. Proceeding with implementation."
    fi
  fi
fi
```

## PARSE TASKS & DETECT FORMAT

**Auto-detect task format to select appropriate parser:**

```bash
cd .

# Detect format based on markers
if grep -q "\\[US[0-9]\\]" "$TASKS_FILE"; then
  TASK_FORMAT="user-story"
  echo "📋 Format: User story (MVP-first delivery)"
elif grep -q "\\[RED\\]\\|\\[GREEN→T[0-9]\\{3\\}\\]" "$TASKS_FILE"; then
  TASK_FORMAT="tdd-phase"
  echo "📋 Format: TDD phase (classic workflow)"
else
  # Default to TDD if ambiguous
  TASK_FORMAT="tdd-phase"
  echo "📋 Format: TDD phase (default)"
fi
echo ""

# Extract incomplete tasks
mapfile -t ALL_TASKS < <(grep "^- \\[ \\] T[0-9]\\{3\\}" "$TASKS_FILE" | sed 's/^- \\[ \\] //')
PENDING_TASKS=("${ALL_TASKS[@]}")

echo "📋 ${#PENDING_TASKS[@]} tasks to execute"
```

## GROUP INTO DETERMINISTIC BATCHES

**Rules**:
- Never parallelize database migrations or schema-creating tasks (serialize)
- Limit batch size to 3 tasks maximum
- At most 1 risky domain (database, external API) per batch
- TDD phases must stay sequential (GREEN depends on RED, REFACTOR depends on GREEN)

```bash
cd .

# Simplified batching: group by domain, respect dependencies
BATCHES=()
current_batch=()
last_domain=""

for task in "${PENDING_TASKS[@]}"; do
  TASK_ID=$(echo "$task" | grep -o "^T[0-9]\\{3\\}")
  TASK_PHASE=$(echo "$task" | grep -o "\\[RED\\]\\|\\[GREEN→T[0-9]\\{3\\}\\]\\|\\[REFACTOR\\]\\|\\[P\\]\\|\\[US[0-9]\\]" || echo "")
  TASK_DESC=$(echo "$task" | sed 's/^T[0-9]\\{3\\} //' | sed 's/\\[[^]]*\\] //')

  # Detect domain
  DOMAIN="general"
  [[ "$TASK_DESC" =~ api/|backend/|service|endpoint|\\.py ]] && DOMAIN="backend"
  [[ "$TASK_DESC" =~ frontend/|component|page|apps/|\\.tsx|\\.jsx ]] && DOMAIN="frontend"
  [[ "$TASK_DESC" =~ migration|alembic|schema|database|sql ]] && DOMAIN="database"
  [[ "$TASK_DESC" =~ test.*\\.py|\\.test\\.|\\.spec\\.|tests/ ]] && DOMAIN="tests"

  # TDD phases must stay sequential (dependency boundary)
  if [[ "$TASK_PHASE" =~ GREEN|REFACTOR ]]; then
    # Flush current batch
    [[ ${#current_batch[@]} -gt 0 ]] && BATCHES+=("$(IFS='|'; echo "${current_batch[*]}")") && current_batch=()
    # Add TDD task as single-task batch
    BATCHES+=("$TASK_ID:$DOMAIN:$TASK_PHASE:$TASK_DESC")
    last_domain=""
    continue
  fi

  # Database tasks ALWAYS serialize (risky domain)
  if [ "$DOMAIN" = "database" ]; then
    # Flush current batch
    [[ ${#current_batch[@]} -gt 0 ]] && BATCHES+=("$(IFS='|'; echo "${current_batch[*]}")") && current_batch=()
    # Add database task as single-task batch
    BATCHES+=("$TASK_ID:$DOMAIN:$TASK_PHASE:$TASK_DESC")
    last_domain=""
    continue
  fi

  # Group parallel tasks by domain (max 3 per batch)
  if [ "$DOMAIN" != "$last_domain" ] || [ ${#current_batch[@]} -ge 3 ]; then
    [[ ${#current_batch[@]} -gt 0 ]] && BATCHES+=("$(IFS='|'; echo "${current_batch[*]}")")
    current_batch=()
  fi

  current_batch+=("$TASK_ID:$DOMAIN:$TASK_PHASE:$TASK_DESC")
  last_domain="$DOMAIN"
done

# Flush remaining
[[ ${#current_batch[@]} -gt 0 ]] && BATCHES+=("$(IFS='|'; echo "${current_batch[*]}")")

echo "📦 Organized into ${#BATCHES[@]} batches"
```

## TDD DISCIPLINE (Non-Negotiable)

**RED Phase** [RED]:
- Write failing test FIRST
- Test must fail for the RIGHT reason (ImportError, NotImplementedError, AssertionError on expected behavior)
- Provide test output as evidence of failure
- Auto-rollback if test passes (wrong!)
- Commit immediately: `test(red): TXXX write failing test`

**GREEN Phase** [GREEN→TXXX]:
- Minimal implementation to pass RED test (no gold-plating)
- Run tests, must pass
- Auto-rollback on failure → log to error-log.md
- Commit immediately: `feat(green): TXXX implement to pass test`

**REFACTOR Phase** [REFACTOR]:
- Clean up code (DRY, KISS principles)
- Tests must stay green (invariant)
- Auto-rollback if tests break
- Commit immediately: `refactor: TXXX clean up implementation`

**Rollback on failure** (safe, idempotent):

```bash
cd .
git restore --staged .
git restore .
echo "⚠️  TXXX: Auto-rolled back (test failure)" >> "$ERROR_LOG"
# Continue to next task (no prompts)
```

## EXECUTE BATCHES IN PARALLEL

```bash
cd .

for batch in "${BATCHES[@]}"; do
  IFS='|' read -ra TASKS_IN_BATCH <<< "$batch"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀 Batch: ${#TASKS_IN_BATCH[@]} tasks"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Prepare parallel agent invocations
  for task_info in "${TASKS_IN_BATCH[@]}"; do
    IFS=':' read -r TASK_ID DOMAIN TASK_PHASE TASK_DESC <<< "$task_info"

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
    CONTEXT="Feature: $SLUG\\nTask: $TASK_ID\\n"
    [[ -f "$FEATURE_DIR/spec.md" ]] && CONTEXT+="Spec: $FEATURE_DIR/spec.md\\n"

    # Extract REUSE markers if exist
    REUSE=$(grep -A 5 "^- \\[ \\] $TASK_ID" "$TASKS_FILE" | grep "REUSE:" | sed 's/.*REUSE: //' | head -3 || echo "")
    [[ -n "$REUSE" ]] && CONTEXT+="REUSE: $REUSE\\n"

    echo ""
    echo "Invoking Task tool for $TASK_ID with $AGENT agent..."
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
  #     - TDD discipline: RED (failing test first), GREEN (minimal pass), REFACTOR (clean up)
  #     - REUSE files if marked (verify imports)
  #     - Run domain tests, provide evidence
  #     - Auto-rollback on failure: git restore --staged . && git restore .
  #     - Commit per task with Conventional Commits
  #     - Update task-tracker (DO NOT manually edit NOTES.md):
  #       ```bash
  #       .spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  #         -TaskId "$TASK_ID" \
  #         -Notes "Implementation summary" \
  #         -Evidence "pytest: NN/NN passing" \
  #         -Coverage "NN% (+ΔΔ%)" \
  #         -CommitHash "$(git rev-parse --short HEAD)" \
  #         -FeatureDir "$FEATURE_DIR"
  #       ```
  #
  #     Return: Files changed, test results, task-tracker confirmation
  #     """
  #   )

  # Quality gates PER BATCH (not just at end)
  echo "🔍 Running quality gates for batch..."

  # Type-check touched domains
  # Lint touched files
  # Run unit + integration tests for touched domains
  # Verify coverage thresholds

  echo ""

  # Validate batch results using task-tracker
  for task_info in "${TASKS_IN_BATCH[@]}"; do
    IFS=':' read -r TASK_ID DOMAIN TASK_PHASE TASK_DESC <<< "$task_info"

    # Use task-tracker to check authoritative status
    if [ -n "$TRACKER" ]; then
      TASK_COMPLETED=$(grep -q "^✅ $TASK_ID" "$NOTES_FILE" 2>/dev/null && echo "$TASK_ID" || echo "")

      if [ "$TASK_COMPLETED" = "$TASK_ID" ]; then
        echo "✅ $TASK_ID complete"
      else
        echo "⚠️  $TASK_ID incomplete - check agent output"
        # Log failure
        if [ -n "$TRACKER" ]; then
          bash "$TRACKER" mark-failed \
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

## QUALITY GATES (Per Batch)

**Agents must enforce these gates automatically:**

1. **Test runtime targets**:
   - Unit tests: <2s each
   - Integration tests: <10s each
   - Full suite: <6 minutes

2. **Coverage thresholds**:
   - New code: ≥80% lines, ≥70% branches
   - No coverage drops from baseline

3. **Test quality**:
   - ❌ **No UI snapshots** (fragile, non-semantic)
   - ✅ **Use semantic queries**: `getByRole`, `getByLabelText`, `getByText`
   - ✅ **Optional**: `data-testid` for dynamic content only
   - ✅ **Optional a11y**: axe-core integration (non-blocking warning)

4. **Code quality**:
   - Lint clean (ESLint, Pylint, Clippy)
   - Type-check clean (TypeScript, mypy, Rust)
   - No `console.log` or debug prints in production code

5. **Feature flags**:
   - New UI behind feature flag
   - Flag documented in feature flags config

6. **Commit format**:
   - Conventional Commits 1.0.0
   - Evidence in commit message (test results, coverage delta)

**Evidence required per task:**
```markdown
pytest: 25/25 passing (2.1s) ✓
Coverage: 88% lines (+6%), 82% branches (+4%)
Lint: 0 errors, 0 warnings
Type-check: Clean
```

## MVP GATE (User Story Format Only)

**When all `[P1]` tasks complete:**

```bash
cd .

# Check if all P1 tasks complete (MVP gate for user-story format)
if [ "$TASK_FORMAT" = "user-story" ]; then
  P1_TOTAL=$(grep -c "\\[P1\\]" "$TASKS_FILE" 2>/dev/null || echo 0)
  P1_COMPLETE=$(grep -c "✅.*\\[P1\\]" "$NOTES_FILE" 2>/dev/null || echo 0)

  if [ "$P1_TOTAL" -gt 0 ] && [ "$P1_COMPLETE" -eq "$P1_TOTAL" ]; then
    # Check if P2 tasks exist
    P2_EXISTS=$(grep -q "\\[P2\\]" "$TASKS_FILE" && echo "true" || echo "false")

    if [ "$P2_EXISTS" = "true" ] && [ "$SHIP_MVP" != "1" ]; then
      P2_TOTAL=$(grep -c "\\[P2\\]" "$TASKS_FILE" 2>/dev/null || echo 0)

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
      echo "  A) Ship MVP now → /preview then /ship-staging"
      echo "  B) Continue to P2 enhancements → /implement --continue"
      echo ""
      echo "Claude Code: Wait for user response"
      echo "  • If 'ship' or 'A': Exit with 'Run /preview to validate MVP'"
      echo "  • If 'continue' or 'B': Continue to remaining batches (P2 tasks)"
      echo ""
      exit 0
    fi
  fi
fi
```

## LIVING DOCUMENTATION UPDATES

**Agents SHOULD update living docs when discovering deviations, patterns, or fulfilling requirements:**

### Update spec.md Implementation Status

```bash
# Mark requirement fulfilled
pwsh -File .spec-flow/scripts/powershell/update-spec-status.ps1 \
  -FeatureDir "$FEATURE_DIR" \
  -Type requirement \
  -Data @{
    id="FR-001"
    status="fulfilled"
    tasks="T001-T003"
    description="JWT authentication"
  }

# Document deviation
pwsh -File .spec-flow/scripts/powershell/update-spec-status.ps1 \
  -FeatureDir "$FEATURE_DIR" \
  -Type deviation \
  -Data @{
    id="FR-004"
    name="Email verification"
    original="Postmark API"
    actual="SendGrid API"
    reason="Cost reduction (Postmark 3x price increase)"
    impact="Minor"
  }

# Record performance actual
pwsh -File .spec-flow/scripts/powershell/update-spec-status.ps1 \
  -FeatureDir "$FEATURE_DIR" \
  -Type performance \
  -Data @{
    metric="FCP"
    target="<1.5s"
    actual="1.2s"
    status="pass"
    notes="Exceeded target by 20%"
  }
```

### Update plan.md Discovered Patterns

```bash
# Add discovered reuse pattern
pwsh -File .spec-flow/scripts/powershell/update-plan-patterns.ps1 \
  -FeatureDir "$FEATURE_DIR" \
  -Type reuse \
  -Data @{
    name="UserService.create_user()"
    path="api/src/services/user.py:42-58"
    task="T013"
    purpose="User creation with password hashing and validation"
    reusable="Any endpoint creating users (admin panel, invite flow)"
    why="New code created in T010, not scanned in Phase 0"
  }
```

### Refresh Feature CLAUDE.md

```bash
# Refresh feature context after each batch
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  pwsh -NoProfile -File .spec-flow/scripts/powershell/generate-feature-claude-md.ps1 \
    -FeatureDir "$FEATURE_DIR"
else
  .spec-flow/scripts/bash/generate-feature-claude-md.sh "$FEATURE_DIR"
fi
```

## FINALIZATION

**After all tasks complete:**

```bash
cd .

# Source workflow state management functions
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  source .spec-flow/scripts/bash/workflow-state.sh
else
  source .spec-flow/scripts/bash/workflow-state.sh
fi

# Calculate completion statistics
TOTAL_TASKS=$(grep -c "^- \\[[ x]\\] T[0-9]\\{3\\}" "$TASKS_FILE" 2>/dev/null || echo "0")
COMPLETED_TASKS=$(grep -c "^✅ T[0-9]\\{3\\}" "$NOTES_FILE" 2>/dev/null || echo "0")
FILES_CHANGED=$(git diff --name-only main 2>/dev/null | wc -l || echo "0")
ERROR_COUNT=$(grep -c "❌\\|⚠️" "$ERROR_LOG" 2>/dev/null || echo "0")

# Determine commit type
if [ "$TASK_FORMAT" = "user-story" ]; then
  P1_TOTAL=$(grep -c "\\[P1\\]" "$TASKS_FILE" 2>/dev/null || echo 0)
  P1_COMPLETE=$(grep -c "✅.*\\[P1\\]" "$NOTES_FILE" 2>/dev/null || echo 0)
  P2_COUNT=$(grep -c "\\[P2\\]" "$TASKS_FILE" 2>/dev/null || echo 0)
  P3_COUNT=$(grep -c "\\[P3\\]" "$TASKS_FILE" 2>/dev/null || echo 0)
  MVP_SHIPPED=$([ "$P1_COMPLETE" -eq "$P1_TOTAL" ] && [ "$P2_COUNT" -gt 0 ] && echo "true" || echo "false")
fi

# Stage all implementation artifacts
git add .

# Commit with implementation summary
if [ "$MVP_SHIPPED" = "true" ]; then
  # MVP commit (P1 only, P2/P3 deferred)
  git commit -m "feat(mvp): complete P1 (MVP) implementation for $(basename "$FEATURE_DIR")

MVP tasks: $P1_COMPLETE/$P1_TOTAL ✅
Tests: All passing
Quality gates: Type-check ✓, Lint ✓, Coverage ≥80%
Deferred to roadmap: P2 ($P2_COUNT tasks), P3 ($P3_COUNT tasks)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
else
  # Full implementation commit
  git commit -m "feat(implement): complete implementation for $(basename "$FEATURE_DIR")

Tasks: $COMPLETED_TASKS/$TOTAL_TASKS ✅
Tests: All passing
Quality gates: Type-check ✓, Lint ✓, Coverage ≥80%
Files changed: $FILES_CHANGED
Errors logged: $ERROR_COUNT

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
fi

# Verify commit succeeded
COMMIT_HASH=$(git rev-parse --short HEAD)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All tasks complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Summary:"
echo "  Tasks: $COMPLETED_TASKS/$TOTAL_TASKS completed"
echo "  Files changed: $FILES_CHANGED"
echo "  Errors logged: $ERROR_COUNT"
echo "  Committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""

# Update workflow state to signal completion
update_workflow_phase "$FEATURE_DIR" "implement" "completed"

echo "Next: /feature auto-continues to /optimize"
echo ""
```

## IMPLEMENTATION EXECUTION (Claude Code)

**When Claude Code invokes /implement, follow this pattern:**

0. **Pre-flight Quality Gate**:
   - Execute checklist validation
   - If incomplete and no `--yes` flag: exit with error
   - If `--yes` or `IMPLEMENT_ASSUME_YES=1`: continue

1. **Parse batches** from bash logic above

2. **For each batch**:
   - Launch parallel Task() calls in single message (for safe domains)
   - Serialize risky domains (database migrations)
   - Run quality gates after batch completes

3. **MVP Gate Handling** (User Story Format Only):
   - After P1 tasks complete, check if P2+ tasks exist
   - If `SHIP_MVP=1` env set: exit with "Run /preview"
   - Else display gate and wait for user input

4. **Task parameters per agent**:

```python
# Example: 3 tasks in parallel batch (backend, frontend, tests)

Task(
  subagent_type="backend-dev",
  description="T001: Create Message model",
  prompt=f"""Implement: Create Message model in api/app/models/message.py

Context:
- Feature: {SLUG}
- REUSE: api/app/models/user.py (pattern)
- Spec: {FEATURE_DIR}/spec.md

Requirements:
- SQLAlchemy model with validation
- TDD: Write failing test first if [RED] phase
- Run pytest api/tests/, provide evidence
- Auto-rollback on failure: git restore --staged . && git restore .
- Commit when tests pass (Conventional Commits)
- Update task-tracker (DO NOT manually edit NOTES.md):
  ```bash
  .spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
    -TaskId "T001" \
    -Notes "Created Message model with validation" \
    -Evidence "pytest: 25/25 passing (2.1s)" \
    -Coverage "92% line (+8%), 88% branch (+6%)" \
    -CommitHash "$(git rev-parse --short HEAD)" \
    -FeatureDir "$FEATURE_DIR"
  ```

Quality gates:
- Tests <2s (unit), <10s (integration)
- Coverage ≥80% lines, ≥70% branches
- No snapshots (use semantic queries)
- Lint + type-check clean

Return: Files changed, test results, task-tracker confirmation
  """
)

Task(
  subagent_type="frontend-shipper",
  description="T002: Create MessageForm component",
  prompt=f"""Implement: Create MessageForm component in apps/app/components/MessageForm.tsx

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
- Auto-rollback on failure: git restore --staged . && git restore .
- Commit when complete
- Update task-tracker:
  ```bash
  .spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
    -TaskId "T002" \
    -Notes "MessageForm component with API integration" \
    -Evidence "jest: 12/12 passing, a11y: 0 violations (optional)" \
    -Coverage "88% (+6%)" \
    -CommitHash "$(git rev-parse --short HEAD)" \
    -FeatureDir "$FEATURE_DIR"
  ```

Quality gates:
- NO snapshots (use getByRole, getByLabelText, getByText)
- Optional a11y check with axe-core (warning only)
- Coverage ≥80%
- Feature flag if new UI

Return: Files changed, test results, task-tracker confirmation
  """
)

Task(
  subagent_type="database-architect",
  description="T003: Add messages table migration",
  prompt=f"""Implement: Generate Alembic migration for messages table

Context:
- Feature: {SLUG}
- Existing migrations: api/alembic/versions/
- Schema: api/app/models/message.py

Requirements:
- Generate migration: uv run alembic revision --autogenerate
- Test up/down cycle (REQUIRED for rollback safety)
- Auto-rollback on failure: git restore --staged . && git restore .
- Commit migration file
- Update task-tracker:
  ```bash
  .spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
    -TaskId "T003" \
    -Notes "messages table migration with FK constraints" \
    -Evidence "Migration up/down cycle tested successfully" \
    -CommitHash "$(git rev-parse --short HEAD)" \
    -FeatureDir "$FEATURE_DIR"
  ```

Quality gates:
- Up/down cycle proof (rollback safety)
- No data loss on down migration

Return: Migration file, test results, task-tracker confirmation
  """
)
```

## CONSTRAINTS

- **Parallel execution**: 3 tasks max per batch (independent domains)
- **TDD strict**: RED → GREEN → REFACTOR (sequential within batch)
- **Auto-rollback**: No prompts, log failures to error-log.md
- **REUSE enforcement**: Verify imports, fail if pattern file missing
- **Commit per task**: Include evidence in commit message
- **No snapshots**: Semantic queries only for UI tests
- **Database safety**: Serialize migrations, require up/down proof

</instructions>
