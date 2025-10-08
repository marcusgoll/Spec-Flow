---
description: Execute tasks with TDD, anti-duplication checks, pattern following
---

Execute tasks from: specs/$SLUG/tasks.md

## LOAD FEATURE

**Get feature from argument or current branch:**

```bash
if [ -n "$ARGUMENTS" ]; then
  SLUG="$ARGUMENTS"
else
  SLUG=$(git branch --show-current)
fi

FEATURE_DIR="specs/$SLUG"
TASKS_FILE="$FEATURE_DIR/tasks.md"
PLAN_FILE="$FEATURE_DIR/plan.md"
ERROR_LOG="$FEATURE_DIR/error-log.md"
NOTES_FILE="$FEATURE_DIR/NOTES.md"
```

**Validate feature exists:**

```bash
if [ ! -d "$FEATURE_DIR" ]; then
  echo "❌ Feature not found: $FEATURE_DIR"
  echo "Available features:"
  ls specs/ | grep -v "archive"
  exit 1
fi

if [ ! -f "$TASKS_FILE" ]; then
  echo "❌ Missing: $TASKS_FILE"
  echo "Run /tasks first"
  exit 1
fi

echo "✅ Feature loaded: $SLUG"
echo "📋 Tasks file: $TASKS_FILE"
echo ""
```

## LOAD CONTEXT (CONDITIONAL)

**Selectively read NOTES.md only when relevant:**

```bash
# Check if NOTES.md has relevant historical context
NEEDS_CONTEXT=false

if [ -f "$NOTES_FILE" ]; then
  # Read if decisions, blockers, or alternatives are documented
  if grep -qi "decision\|blocker\|alternative\|tried\|workaround" "$NOTES_FILE"; then
    NEEDS_CONTEXT=true
  fi
fi

# Also read if error-log.md has entries (debugging mode)
if [ -f "$ERROR_LOG" ] && [ -s "$ERROR_LOG" ]; then
  NEEDS_CONTEXT=true
fi

# Load context if needed
if [ "$NEEDS_CONTEXT" = true ]; then
  echo "📖 Loading historical context from NOTES.md..."
  echo ""

  # Show relevant sections only (not full file)
  if grep -q "## Key Decisions" "$NOTES_FILE"; then
    echo "## Key Decisions"
    sed -n '/## Key Decisions/,/^## /p' "$NOTES_FILE" 2>/dev/null | head -20
    echo ""
  fi

  if grep -q "## Blockers" "$NOTES_FILE"; then
    echo "## Previous Blockers"
    sed -n '/## Blockers/,/^## /p' "$NOTES_FILE" 2>/dev/null | head -20
    echo ""
  fi

  echo "✅ Context loaded"
  echo ""
else
  echo "✅ No historical context needed (clean implementation)"
  echo ""
fi
```

**Token savings:** Only read NOTES.md when decisions/blockers exist, not on every task.

## PARSE TASKS

**Extract all tasks from tasks.md:**

```bash
# Parse task list
TASKS=$(grep "^T[0-9]\{3\}" "$TASKS_FILE" | sed 's/\[.*\]//' | sed 's/^/  /')

# Count tasks
TOTAL_TASKS=$(echo "$TASKS" | wc -l)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Executing $TOTAL_TASKS tasks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$TASKS"
echo ""

# Check for checkpoint (if resuming)
LAST_CHECKPOINT=$(grep "✅ T[0-9]" "$NOTES_FILE" 2>/dev/null | tail -1 | grep -o "T[0-9]\{3\}")

if [ -n "$LAST_CHECKPOINT" ]; then
  echo "🔄 Resuming from checkpoint: $LAST_CHECKPOINT"
  echo ""
fi
```

## EXECUTE TASKS (Main Loop)

**For each task in tasks.md:**

```bash
CURRENT_TASK=1

while IFS= read -r task_line; do
  # Parse task ID and description
  TASK_ID=$(echo "$task_line" | grep -o "^T[0-9]\{3\}")
  TASK_PHASE=$(echo "$task_line" | grep -o "\[RED\]\|\[GREEN→T[0-9]\{3\}\]\|\[REFACTOR\]\|\[P\]")
  TASK_DESC=$(echo "$task_line" | sed 's/^T[0-9]\{3\} \[.*\] //')

  # Skip if already completed
  if grep -q "✅ $TASK_ID" "$NOTES_FILE" 2>/dev/null; then
    echo "⏭️  $TASK_ID already complete (skipping)"
    ((CURRENT_TASK++))
    continue
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎯 $TASK_ID [$CURRENT_TASK/$TOTAL_TASKS]"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Task: $TASK_DESC"
  echo "Phase: $TASK_PHASE"
  echo ""

  # Read task context (REUSE files, patterns, polished mockups)
  read_task_context "$TASK_ID" "$TASK_DESC"

  # Route to specialist agent or execute directly
  AGENT=$(determine_agent "$TASK_DESC")

  if [ -n "$AGENT" ]; then
    echo "🤖 Routing to specialist: $AGENT"
    route_to_agent "$AGENT" "$TASK_ID" "$TASK_DESC"
  else
    # Execute task based on phase
    case "$TASK_PHASE" in
      *RED*)
        execute_red_phase "$TASK_ID" "$TASK_DESC"
        ;;
      *GREEN*)
        execute_green_phase "$TASK_ID" "$TASK_DESC"
        ;;
      *REFACTOR*)
        execute_refactor_phase "$TASK_ID" "$TASK_DESC"
        ;;
      *P*)
        execute_standard_task "$TASK_ID" "$TASK_DESC"
        ;;
    esac
  fi

  # Update checkpoint
  echo "  ✅ $TASK_ID: $(echo "$TASK_DESC" | head -c 60)..." >> "$NOTES_FILE"

  ((CURRENT_TASK++))

done < <(grep "^T[0-9]\{3\}" "$TASKS_FILE")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All tasks complete ($TOTAL_TASKS/$TOTAL_TASKS)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

## READ TASK CONTEXT

**Before implementing task, read referenced files:**

```bash
read_task_context() {
  local task_id="$1"
  local task_desc="$2"

  # Extract file paths mentioned in task
  REUSE_FILES=$(grep -A 10 "^$task_id" "$TASKS_FILE" | grep "REUSE:" | sed 's/.*REUSE: //')
  PATTERN_FILES=$(grep -A 10 "^$task_id" "$TASKS_FILE" | grep "Pattern:" | sed 's/.*Pattern: //')

  # Read REUSE files
  if [ -n "$REUSE_FILES" ]; then
    echo "📖 Reading REUSE files..."
    while IFS= read -r file; do
      if [ -f "$file" ]; then
        echo "  ✓ $file"
        # Claude reads file
      else
        echo "  ⚠️  Not found: $file"
      fi
    done <<< "$REUSE_FILES"
    echo ""
  fi

  # Read pattern files
  if [ -n "$PATTERN_FILES" ]; then
    echo "📖 Reading pattern files..."
    while IFS= read -r file; do
      if [ -f "$file" ]; then
        echo "  ✓ $file"
        # Claude reads file
      else
        echo "  ⚠️  Not found: $file"
      fi
    done <<< "$PATTERN_FILES"
    echo ""
  fi

  # Check for polished mockup reference (UI tasks)
  if echo "$task_desc" | grep -q "apps/app\|frontend\|component"; then
    SCREEN_NAME=$(extract_screen_from_task "$task_desc")
    POLISHED_MOCKUP="apps/web/mock/$SLUG/$SCREEN_NAME/polished/page.tsx"

    if [ -f "$POLISHED_MOCKUP" ]; then
      echo "🎨 Polished mockup available: $POLISHED_MOCKUP"
      echo ""
      echo "Design guidance:"
      echo "  - Copy: Layout, components, design tokens, a11y patterns"
      echo "  - Add: Real API integration, state management, error handling"
      echo "  - Add: Analytics instrumentation (PostHog + logs + DB)"
      echo "  - Add: Feature flags (A/B testing)"
      echo "  - Remove: Mock data, console.logs, 'Mock' labels"
      echo ""
      # Claude reads mockup for design reference
    fi

    # Read design artifacts if available
    if [ -f "specs/$SLUG/design/polish-report.md" ]; then
      echo "🎨 Reading design tokens from polish-report.md"
      # Claude reads polish report
    fi
    if [ -f "design/systems/tokens.json" ]; then
      echo "🎨 Loading design system tokens"
      # Claude reads design tokens
    fi
  fi
}
```

## AGENT ROUTING

**Determine specialist agent based on task domain:**

```bash
determine_agent() {
  local task_desc="$1"

  # Extract file path from task description
  local task_file=$(echo "$task_desc" | grep -o "[^ ]*/[^ ]*\.[a-z]*" | head -1)

  # Routing decision tree
  if [[ "$task_file" == api/**/*.py ]] && [[ "$task_desc" != *"test"* ]]; then
    echo "cfipros-backend-dev"
  elif [[ "$task_file" == apps/**/*.tsx ]] || [[ "$task_file" == apps/**/*.ts ]]; then
    echo "cfipros-frontend-shipper"
  elif [[ "$task_file" == api/alembic/** ]] || [[ "$task_desc" == *"migration"* ]]; then
    echo "cfipros-database-architect"
  elif [[ "$task_file" == **/tests/** ]] || [[ "$task_desc" == *"test"* ]]; then
    echo "cfipros-qa-test"
  elif [[ "$task_desc" == *"bug"* ]] || [[ "$task_desc" == *"error"* ]] || [[ "$task_desc" == *"fix"* ]]; then
    echo "cfipros-debugger"
  else
    echo ""  # No specialist, execute manually
  fi
}

route_to_agent() {
  local agent="$1"
  local task_id="$2"
  local task_desc="$3"

  # Prepare context for agent
  local context=$(cat <<EOF
Task: $task_id
Description: $task_desc
Feature: $SLUG
Plan: specs/$SLUG/plan.md
Tasks: specs/$SLUG/tasks.md
Error Log: specs/$SLUG/error-log.md
EOF
)

  echo "Delegating to $agent..."
  echo ""

  # Call /route-agent if available
  if command -v /route-agent &> /dev/null; then
    /route-agent "$agent" "$task_id" "$context"
  else
    echo "ℹ️  Agent routing not available, proceeding with manual implementation"
    echo ""
  fi
}
```

## TDD PHASE EXECUTION

### RED Phase: Write Failing Test

```bash
execute_red_phase() {
  local task_id="$1"
  local task_desc="$2"

  echo "🔴 RED Phase: Write failing test"
  echo ""

  # Extract test file path from task description
  TEST_FILE=$(echo "$task_desc" | grep -o "[^ ]*test[^ ]*\.py\|[^ ]*spec\.ts\|[^ ]*\.test\.ts" | head -1)

  if [ -z "$TEST_FILE" ]; then
    echo "⚠️  No test file specified in task"
    echo "Enter test file path:"
    read TEST_FILE
  fi

  echo "Test file: $TEST_FILE"
  echo ""

  # Claude writes the failing test
  # Example: test_message_validation.py
  # - Test expresses desired behavior
  # - Uses GIVEN/WHEN/THEN structure
  # - Clear assertions

  echo "Running test (should fail for correct reason)..."
  echo ""

  # Run test based on file extension
  if [[ "$TEST_FILE" == *.py ]]; then
    TEST_OUTPUT=$(uv run pytest "$TEST_FILE" -v 2>&1) || true
    TEST_RESULT=$?
  elif [[ "$TEST_FILE" == *.spec.ts ]] || [[ "$TEST_FILE" == *.test.ts ]]; then
    TEST_OUTPUT=$(pnpm test "$TEST_FILE" 2>&1) || true
    TEST_RESULT=$?
  fi

  # Display test output
  echo "$TEST_OUTPUT"
  echo ""

  # Validate failure reason
  if [ $TEST_RESULT -eq 0 ]; then
    echo "❌ ERROR: Test passed when it should fail"
    echo "RED phase requires test to fail for correct reason"
    exit 1
  fi

  echo "Capture failure reason:"
  FAILURE_REASON=$(echo "$TEST_OUTPUT" | grep -E "Error|error|FAILED" | head -3)
  echo "$FAILURE_REASON"
  echo ""

  read -p "Did test fail for correct reason? (y/n): " FAIL_CORRECT

  if [ "$FAIL_CORRECT" != "y" ]; then
    echo "❌ Test not failing correctly. Review and fix."
    exit 1
  fi

  echo "✅ Test failing as expected (RED phase complete)"
  echo ""

  # Store evidence
  echo "$TEST_OUTPUT" > "$FEATURE_DIR/test-evidence-$task_id.txt"

  # Commit RED phase
  git add "$TEST_FILE"
  git commit -m "test(red): $task_id write failing test

RED phase: Test must fail
Task: $task_desc
File: $TEST_FILE
Expected failure: $FAILURE_REASON

Completed: $task_id/$TOTAL_TASKS

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

  echo "✅ $task_id [RED]: Committed"
}
```

### GREEN Phase: Minimal Implementation

```bash
execute_green_phase() {
  local task_id="$1"
  local task_desc="$2"

  echo "🟢 GREEN Phase: Implement to pass test"
  echo ""

  # Extract RED test reference
  RED_TASK=$(echo "$task_desc" | grep -o "GREEN→T[0-9]\{3\}" | grep -o "T[0-9]\{3\}")

  if [ -n "$RED_TASK" ]; then
    echo "Implementing to pass test: $RED_TASK"
    echo ""
  fi

  # Extract implementation file from task
  IMPL_FILE=$(echo "$task_desc" | grep -o "[^ ]*/[^ ]*\.py\|[^ ]*/[^ ]*\.tsx\|[^ ]*/[^ ]*\.ts" | head -1)

  echo "Implementation file: $IMPL_FILE"
  echo ""

  # Claude writes minimal implementation
  # - Uses REUSE markers for imports
  # - Follows pattern from pattern file
  # - Minimal code to pass test (no over-engineering)

  echo "Running tests (should pass now)..."
  echo ""

  # Run all tests for this module
  if [[ "$IMPL_FILE" == *.py ]]; then
    MODULE=$(dirname "$IMPL_FILE")
    TEST_OUTPUT=$(uv run pytest "$MODULE" -v 2>&1)
    TEST_RESULT=$?
  elif [[ "$IMPL_FILE" == *.tsx ]] || [[ "$IMPL_FILE" == *.ts ]]; then
    TEST_OUTPUT=$(pnpm test -- --testPathPattern="$(dirname "$IMPL_FILE")" 2>&1)
    TEST_RESULT=$?
  fi

  # Display test output
  echo "$TEST_OUTPUT"
  echo ""

  if [ $TEST_RESULT -ne 0 ]; then
    echo "❌ Tests not passing"
    echo ""
    echo "Options:"
    echo "  A) Debug (stay in current state)"
    echo "  B) Rollback (restore to last commit)"
    echo "  C) Skip (mark failed, continue)"
    read -p "Choose: " OPTION

    case "$OPTION" in
      A|a)
        /debug "$task_id"
        ;;
      B|b)
        git restore .
        echo "Rolled back to last commit"
        exit 1
        ;;
      C|c)
        echo "⚠️  $task_id: FAILED (skipped)" >> "$ERROR_LOG"
        return
        ;;
    esac
  fi

  echo "✅ Tests passing (GREEN phase complete)"
  echo ""

  # Extract coverage from output
  COVERAGE=$(echo "$TEST_OUTPUT" | grep -o "[0-9]*%" | tail -1)

  # Store evidence
  echo "$TEST_OUTPUT" > "$FEATURE_DIR/test-evidence-$task_id.txt"

  # Commit GREEN phase
  git add "$IMPL_FILE"
  git commit -m "feat(green): $task_id implement to pass test

GREEN phase: Test now passes
Implements: $(basename "$IMPL_FILE" .py .tsx .ts)
Passes test: $RED_TASK
Coverage: $COVERAGE

Completed: $task_id/$TOTAL_TASKS (passes $RED_TASK)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

  echo "✅ $task_id [GREEN]: Committed"
}
```

### REFACTOR Phase: Clean Up

```bash
execute_refactor_phase() {
  local task_id="$1"
  local task_desc="$2"

  echo "♻️  REFACTOR Phase: Clean up (tests stay green)"
  echo ""

  # Extract files to refactor
  FILES=$(echo "$task_desc" | grep -o "[^ ]*/[^ ]*\.py\|[^ ]*/[^ ]*\.tsx\|[^ ]*/[^ ]*\.ts")

  echo "Refactoring: $FILES"
  echo ""

  # Claude refactors code
  # - Extract duplicated code
  # - Apply DRY principle
  # - Rename for clarity
  # - Improve structure
  # - Tests MUST stay green

  echo "Running tests (must stay green)..."
  echo ""

  # Run full test suite for affected modules
  if echo "$FILES" | grep -q "\.py"; then
    TEST_OUTPUT=$(uv run pytest -v 2>&1)
    TEST_RESULT=$?
  elif echo "$FILES" | grep -q "\.tsx\|\.ts"; then
    TEST_OUTPUT=$(pnpm test 2>&1)
    TEST_RESULT=$?
  fi

  # Display test output
  echo "$TEST_OUTPUT"
  echo ""

  if [ $TEST_RESULT -ne 0 ]; then
    echo "❌ Tests broken by refactor"
    echo "Rolling back changes..."
    git restore .
    exit 1
  fi

  echo "✅ Tests still green (REFACTOR phase complete)"
  echo ""

  # Store evidence
  echo "$TEST_OUTPUT" > "$FEATURE_DIR/test-evidence-$task_id.txt"

  # Commit REFACTOR phase
  git add .
  git commit -m "refactor: $task_id clean up implementation

REFACTOR phase: Tests stay green
Improved: $task_desc
Tests: All passing (maintained coverage)

Completed: $task_id/$TOTAL_TASKS

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

  echo "✅ $task_id [REFACTOR]: Committed"
}
```

### Standard Task (Non-TDD)

```bash
execute_standard_task() {
  local task_id="$1"
  local task_desc="$2"

  echo "📝 Standard task execution"
  echo ""

  # Determine task type
  if echo "$task_desc" | grep -q "backend\|api/\|\.py"; then
    execute_backend_task "$task_id" "$task_desc"
  elif echo "$task_desc" | grep -q "frontend\|apps/\|\.tsx\|\.ts"; then
    execute_frontend_task "$task_id" "$task_desc"
  elif echo "$task_desc" | grep -q "migration\|alembic"; then
    execute_migration_task "$task_id" "$task_desc"
  else
    echo "Executing generic task..."
    # Claude implements task based on description
  fi
}
```

## BACKEND TASK EXECUTION

**Example: Database Model**

```bash
execute_backend_task() {
  local task_id="$1"
  local task_desc="$2"

  echo "🐍 Backend task: $task_desc"
  echo ""

  # Example: Create Message model
  # File: api/app/models/message.py

  # Read REUSE files for patterns
  # Implement following SQLAlchemy patterns
  # Add validation methods
  # Include relationships

  # Validate implementation
  echo "Validating backend code..."

  # Type check
  cd api && uv run mypy app/models/ --no-error-summary

  # Lint
  uv run ruff check app/models/

  # Format
  uv run black app/models/

  # Run tests
  uv run pytest tests/unit/test_models.py -v

  cd ..

  echo "✅ Backend validation complete"
}
```

**Example: API Endpoint**

```python
# api/app/api/v1/messages.py

from fastapi import APIRouter, Depends, HTTPException, status
from app.models.message import Message
from app.services.message_service import MessageService  # REUSE
from app.auth.dependencies import get_current_user

router = APIRouter(prefix='/api/v1/messages', tags=['messages'])

@router.post('/', status_code=status.HTTP_201_CREATED)
async def create_message(
    content: str,
    channel_id: int,
    current_user = Depends(get_current_user),
    message_service: MessageService = Depends()
):
    """Create new message in channel"""
    try:
        message = await message_service.create(
            content=content,
            channel_id=channel_id,
            user_id=current_user.id
        )
        return message
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
```

## FRONTEND TASK EXECUTION

**When polished mockup exists:**

```bash
execute_frontend_task() {
  local task_id="$1"
  local task_desc="$2"

  echo "⚛️  Frontend task: $task_desc"
  echo ""

  # Check for polished mockup
  SCREEN_NAME=$(extract_screen_from_task "$task_desc")
  POLISHED_MOCKUP="apps/web/mock/$SLUG/$SCREEN_NAME/polished/page.tsx"

  if [ -f "$POLISHED_MOCKUP" ]; then
    echo "🎨 Using polished mockup as design reference"
    echo "   Source: $POLISHED_MOCKUP"
    echo ""

    # Build production implementation
    # - Copy layout, components, tokens from polished mockup
    # - Add real API integration (React Query, fetch)
    # - Add real state management
    # - Add analytics instrumentation
    # - Add feature flags
    # - Remove mock data

    implement_production_from_mockup "$POLISHED_MOCKUP" "$task_desc"
  else
    echo "ℹ️  No polished mockup (direct implementation)"
    echo ""

    # Direct implementation without mockup
    # - Follow design system (ui-inventory.md)
    # - Use existing components
    # - Add real functionality
  fi

  # Validate implementation
  echo "Validating frontend code..."

  cd apps/app

  # Type check
  pnpm type-check

  # Lint
  pnpm lint

  # Run tests
  pnpm test

  cd ../..

  echo "✅ Frontend validation complete"
}

implement_production_from_mockup() {
  local mockup_file="$1"
  local task_desc="$2"

  # Extract production route from task
  PRODUCTION_ROUTE=$(echo "$task_desc" | grep -o "apps/app/[^ ]*")

  echo "Creating production file: $PRODUCTION_ROUTE"
  echo ""

  # Read polished mockup for design reference
  # (Claude reads mockup file)

  # Build production implementation:
  # 1. Copy layout structure from mockup
  # 2. Copy component usage from mockup
  # 3. Copy design tokens/classNames from mockup
  # 4. Add real API integration (NOT in mockup)
  # 5. Add real state management (NOT in mockup)
  # 6. Add analytics (NOT in mockup)
  # 7. Add feature flags (NOT in mockup)
  # 8. Remove mock data from mockup
  # 9. Remove "Mock" labels from mockup

  # Example production implementation:
  cat > "$PRODUCTION_ROUTE" <<'EOF'
'use client';

import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useAnalytics } from '@/lib/analytics';
import { useFeatureFlag } from '@/lib/feature-flags';

export default function UploadProduction() {
  const [file, setFile] = useState<File | null>(null);
  const analytics = useAnalytics();
  const isEnabled = useFeatureFlag('feature_flag_name');

  // REAL API integration (NOT in mockup)
  const uploadMutation = useMutation({
    mutationFn: async (file: File) => {
      analytics.track('upload.started', { file_size: file.size });

      const formData = new FormData();
      formData.append('file', file);

      const res = await fetch('/api/endpoint', {
        method: 'POST',
        body: formData,
      });

      if (!res.ok) throw new Error('Upload failed');
      return res.json();
    },
    onSuccess: (data) => {
      analytics.track('upload.success', { result_count: data.results.length });
    },
    onError: (error) => {
      analytics.track('upload.error', { error: error.message });
    },
  });

  // SAME UI as polished mockup (layout, tokens, components)
  return (
    <Card className="border-neutral-200 shadow-md">
      <CardHeader>
        <CardTitle className="font-sans text-neutral-900">Upload File</CardTitle>
        <p className="text-sm text-neutral-600">Description text</p>
      </CardHeader>
      <CardContent>
        <Button
          onClick={() => file && uploadMutation.mutate(file)}
          disabled={!file || uploadMutation.isPending}
          className="bg-brand-primary hover:bg-brand-primary-600"
        >
          {uploadMutation.isPending ? 'Uploading...' : 'Upload'}
        </Button>

        {uploadMutation.isError && (
          <Alert variant="destructive">
            Upload failed. Please try again.
          </Alert>
        )}
      </CardContent>
    </Card>
  );
}
EOF
}
```

## DATABASE MIGRATION EXECUTION

```bash
execute_migration_task() {
  local task_id="$1"
  local task_desc="$2"

  echo "🗄️  Migration task: $task_desc"
  echo ""

  # Generate migration
  cd api

  echo "Generating migration..."
  uv run alembic revision --autogenerate -m "$(echo "$task_desc" | sed 's/.*: //')"

  # Get latest migration file
  MIGRATION_FILE=$(ls -t alembic/versions/*.py | head -1)

  echo "Migration file: $MIGRATION_FILE"
  echo ""

  # Test migration
  echo "Testing migration up/down cycle..."

  # Upgrade
  uv run alembic upgrade head
  if [ $? -ne 0 ]; then
    echo "❌ Migration upgrade failed"
    cd ..
    exit 1
  fi

  # Downgrade
  uv run alembic downgrade -1
  if [ $? -ne 0 ]; then
    echo "❌ Migration downgrade failed"
    uv run alembic upgrade head  # Restore
    cd ..
    exit 1
  fi

  # Upgrade again
  uv run alembic upgrade head
  if [ $? -ne 0 ]; then
    echo "❌ Migration re-upgrade failed"
    cd ..
    exit 1
  fi

  echo "✅ Migration validated (up/down/up works)"

  # Run migration tests if they exist
  if [ -f "tests/migrations/test_$(basename "$MIGRATION_FILE")" ]; then
    echo "Running migration tests..."
    uv run pytest "tests/migrations/test_$(basename "$MIGRATION_FILE")" -v
  fi

  cd ..

  echo "✅ Migration complete"
}
```

## EVIDENCE REQUIREMENTS (MANDATORY)

**Every test execution MUST show:**
- ✅ Command run: `pytest [path] -v` or `pnpm test [path]`
- ✅ Pass/fail status with test names
- ✅ Execution time (<2s unit, <10s integration, <6min suite)
- ✅ Coverage delta (if applicable)
- ✅ Failure reason (RED phase only)

**If no evidence found:**
```
⚠️ WARNING: No test execution evidence for $task_id
Required: pytest/jest output showing pass/fail
Run tests now? (Y/n)
```

**Evidence validation:**
```bash
# Check test was actually run
git log -1 --grep="$task_id" | grep -E "PASS|FAIL"
# If not found → prompt for test execution
```

## GUARDRAIL VALIDATION (before marking complete)

**Speed Check:**
```bash
# Unit tests <2s
if [[ "$TEST_FILE" == *.py ]]; then
  uv run pytest "$TEST_FILE" --durations=5
elif [[ "$TEST_FILE" == *.spec.ts ]]; then
  pnpm test "$TEST_FILE" --verbose
fi
# Flag if any test >2s → "Optimize: Mock DB calls"

# Suite <6min
time pytest api/tests/
# If >360s → "FAIL: Suite too slow, refactor tests"
```

**Quality Check:**
```bash
# One behavior per test (check assertions)
pytest "$TEST_FILE" --collect-only | wc -l
# Should match number of behaviors tested

# No snapshots (frontend)
grep -r "toMatchSnapshot" apps/app/tests/
# If found → "FAIL: Remove snapshots, use semantic queries"

# Prefer accessible queries
grep -c "getByRole\|getByText" apps/app/tests/ vs grep -c "getByTestId"
# Ratio >70% is good
```

**Validation Output:**
```
✅ Speed: All tests <2s (avg: 0.9s, max: 1.8s)
✅ Suite: 4.2s total (<6min ✓)
✅ Clarity: 12 tests, 14 assertions (1.2 avg)
✅ Accessible: 9/12 use role/text (75%)
❌ FAIL: Found 2 snapshots → Action: Replace with semantic assertions
```

## UPDATE NOTES.md (checkpoint per task)

```markdown
## Checkpoints
- ✅ T006 [RED]: Content validation test (failing as expected)
  - Evidence: pytest output showing AttributeError ✓
  - Committed: abc1234

- ✅ T016 [GREEN]: Implement Message.validate_content()
  - Evidence: pytest output showing PASS (0.8s) ✓
  - Coverage: 85% (+15%)
  - Committed: def5678

- ✅ T024 [REFACTOR]: Extract MessageValidator
  - Evidence: All tests green (12/12, 4.2s) ✓
  - Improved: Extracted validator, added constant
  - Committed: ghi9012
```

## AUTO-COMPACTION

In `/flow` mode, auto-compaction runs after implementation:
- ✅ Preserve: Last 20 task checkpoints, full error log, implementation notes, decisions, architecture
- ❌ Remove: Old research, verbose task descriptions, early checkpoints (keep last 20)
- Strategy: Moderate (implementation phase)

**Manual compact instruction (standalone mode):**
```bash
/compact "keep last 20 task checkpoints, full error log, and implementation notes"
```

**When to compact:**
- Auto: After `/implement` in `/flow` mode
- Manual: After every 10 tasks or if context >70k tokens
- Compaction frequency: More aggressive than planning (preserve recent work only)

## RECOVERY MODE

If Claude Code crashes mid-task:

1. Read NOTES.md → find last checkpoint
2. Read error-log.md → check for recent failures
3. Check git log → last commit
4. Check git status → unstaged changes
5. Prompt:
```
Last checkpoint: T015 completed
Recent error-log entries: N (review with /debug if needed)
Unstaged: api/src/modules/chat/services/message_service.py

Resume T016 (MessageService)?
A) Continue (commit current state)
B) Rollback (discard changes, restart T016)
C) Review (show diff first)
D) Debug (run /debug to investigate issues)
```

## REUSE VALIDATION

Before marking task complete:
1. Verify REUSE markers reference real files: `grep -l "import.*DatabaseService" [task-file]`
2. Check pattern file exists: `test -f api/src/modules/notifications/service.py`
3. If missing: Fail task with "Pattern file not found: [path]", don't proceed
4. Validate imports compile: Run type-check or linter on new file
5. Flag if claimed reuse but no import statement found

## CONSTRAINTS

**TDD Workflow (strict):**
- RED → GREEN → REFACTOR loop (no exceptions)
- RED: Test MUST fail for right reason, evidence required
- GREEN: Minimal code to pass, evidence required
- REFACTOR: Tests MUST stay green, evidence required

**Code Quality:**
- REUSE: Check task markers, read referenced files first
- Pattern: Follow similar file structure
- JSDoc/docstrings: Add @see tags to reused code
- One task at a time (no batching)

**Process:**
- Commit after EVERY task (RED, GREEN, REFACTOR phases)
- Update NOTES.md with evidence checkpoints
- Compact every 10 tasks
- Validate guardrails before marking complete

## RETURN (per task)

Brief update:
- ✅ T0NN: [task name] - COMPLETED
- 📝 Files: [changed files]
- 🧪 Tests: N passing, coverage NN%
- ♻️  Reused: [services/modules]
- 📝 NOTES.md: Checkpoint added
- 🔄 Context: NN,NNN/100,000 tokens (implementation phase)

**If UI feature with polished mockup**:
- 🎨 Production route created: apps/app/$SLUG/[route]/
- 📖 Design reference: apps/web/mock/$SLUG/[screen]/polished/
- 🔌 Real API integration added
- 📊 Analytics instrumented
- 🚩 Feature flag configured
- ✅ Budgets validated
