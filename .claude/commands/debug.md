---
description: Debug errors and update error-log.md with systematic tracking
---

# Debug: Systematic Error Resolution

**Command**: `/debug [feature-slug]` or `/debug --from-optimize [flags]`

**Purpose**: Diagnose errors, delegate to specialists, apply fixes, and systematically track learnings in error-log.md.

**When to use**:
- Test failures, build errors, runtime bugs, UI issues
- Performance regressions
- Auto-invoked by `/optimize` for code review issues

**Workflow position**: `implement → **debug** → optimize → preview → phase-1-ship`

---

## MENTAL MODEL

You are a **systematic debugger** with two modes:

**Manual Mode** (user-invoked):
1. Gather context (git status, logs, recent changes)
2. Reproduce error (run tests, build, inspect logs)
3. Identify root cause
4. Route to appropriate specialist agent
5. Apply fix, verify, commit
6. Update error-log.md with learnings

**Structured Mode** (from `/optimize --from-optimize`):
1. Parse structured input (issue ID, severity, category, file, description)
2. Route directly to specialist based on category
3. Apply minimal fix per recommendation
4. Verify (lint, types, tests)
5. Update error-log.md with issue ID reference
6. Return to /optimize for next issue

**Philosophy**: Every error is a learning opportunity. Document failures, symptoms, root causes, and what was retired/corrected. The error-log.md becomes the project's debugging knowledge base.

**Token efficiency**: Delegate complex debugging to specialists. Only gather minimal context needed for routing. Let agents do the deep investigation.

---

## INPUTS

**Manual mode (user-invoked)**:
- Feature slug (from argument or current branch)
- Interactive error description
- Error type (test, build, runtime, UI, performance)
- Component (backend, frontend, database, integration)

**Structured mode (from /optimize)**:
- `--from-optimize` flag
- `--issue-id=CR###`
- `--severity=CRITICAL|HIGH|MEDIUM|LOW`
- `--category=Contract|KISS|DRY|Security|Type|Test|Database`
- `--file=path/to/file`
- `--line=NNN`
- `--description="..."`
- `--recommendation="..."`

---

## EXECUTION PHASES

### Phase 1: LOAD FEATURE

```bash
#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Debug: Systematic Error Resolution"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Parse arguments
STRUCTURED_MODE=false
ISSUE_ID=""
SEVERITY=""
CATEGORY=""
FILE=""
LINE=""
DESCRIPTION=""
RECOMMENDATION=""

if [ -n "$ARGUMENTS" ]; then
  # Check for structured mode flag
  if [[ "$ARGUMENTS" =~ --from-optimize ]]; then
    STRUCTURED_MODE=true
    echo "✅ Mode: Structured (from /optimize)"
    echo ""

    # Parse flags
    ARGS="$ARGUMENTS"
    while [[ "$ARGS" =~ --([^=]+)=([^ ]+) ]]; do
      FLAG="${BASH_REMATCH[1]}"
      VALUE="${BASH_REMATCH[2]}"

      case "$FLAG" in
        issue-id) ISSUE_ID="$VALUE" ;;
        severity) SEVERITY="$VALUE" ;;
        category) CATEGORY="$VALUE" ;;
        file) FILE="$VALUE" ;;
        line) LINE="$VALUE" ;;
        description) DESCRIPTION="$VALUE" ;;
        recommendation) RECOMMENDATION="$VALUE" ;;
      esac

      # Remove processed flag
      ARGS=$(echo "$ARGS" | sed "s/--$FLAG=$VALUE//")
    done

    # Validate structured input
    if [ -z "$ISSUE_ID" ] || [ -z "$SEVERITY" ] || [ -z "$CATEGORY" ] || [ -z "$FILE" ]; then
      echo "❌ Missing required flags for structured mode"
      echo ""
      echo "Required:"
      echo "  --issue-id=CR###"
      echo "  --severity=CRITICAL|HIGH|MEDIUM|LOW"
      echo "  --category=Contract|KISS|DRY|Security|Type|Test|Database"
      echo "  --file=path/to/file"
      echo ""
      echo "Optional:"
      echo "  --line=NNN"
      echo "  --description=\"...\""
      echo "  --recommendation=\"...\""
      exit 1
    fi

    echo "Issue: $ISSUE_ID ($SEVERITY)"
    echo "Category: $CATEGORY"
    echo "File: $FILE:$LINE"
    echo ""

    # Extract feature slug from file path
    if [[ "$FILE" =~ specs/([^/]+)/ ]]; then
      SLUG="${BASH_REMATCH[1]}"
    else
      SLUG=$(git branch --show-current)
    fi
  else
    # Manual mode with explicit feature
    SLUG="$ARGUMENTS"
    echo "✅ Mode: Manual (explicit feature)"
    echo ""
  fi
else
  # Auto-detect from current branch
  SLUG=$(git branch --show-current)
  echo "✅ Mode: Manual (auto-detected)"
  echo ""
fi

# Validate feature directory
FEATURE_DIR="specs/$SLUG"
if [ ! -d "$FEATURE_DIR" ]; then
  echo "❌ Feature not found: $FEATURE_DIR"
  echo ""
  echo "Usage:"
  echo "  /debug                          # Auto-detect from branch"
  echo "  /debug feature-slug             # Explicit feature"
  echo "  /debug --from-optimize [flags]  # Structured mode"
  exit 1
fi

ERROR_LOG="$FEATURE_DIR/error-log.md"
SPEC_FILE="$FEATURE_DIR/spec.md"
TASKS_FILE="$FEATURE_DIR/tasks.md"
NOTES_FILE="$FEATURE_DIR/NOTES.md"

echo "Feature: $SLUG"
echo "Error log: $ERROR_LOG"
echo ""
```

---

### Phase 1.5: LOAD DEBUG CONTEXT (MANDATORY)

**Always read NOTES.md for debugging context:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📖 Loading Debug Context"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f "$NOTES_FILE" ]; then
  echo "Checking NOTES.md for similar issues..."
  echo ""

  # Show blocker sections (past error resolutions)
  if grep -q "## Blockers" "$NOTES_FILE"; then
    echo "## Past Blockers & Resolutions"
    sed -n '/## Blockers/,/^## /p' "$NOTES_FILE" | head -30
    echo ""
  fi

  # Show key decisions (may explain unexpected behavior)
  if grep -q "## Key Decisions" "$NOTES_FILE"; then
    echo "## Architecture Decisions (may explain behavior)"
    sed -n '/## Key Decisions/,/^## /p' "$NOTES_FILE" | head -30
    echo ""
  fi

  # Show system components (for dependency issues)
  if grep -q "## System Components" "$NOTES_FILE"; then
    echo "## System Components Analysis"
    sed -n '/## System Components/,/^## /p' "$NOTES_FILE" | head -20
    echo ""
  fi

  echo "✅ Debug context loaded"
  echo ""
else
  echo "⚠️  No NOTES.md found (first time debugging this feature)"
  echo ""
fi

# Also show recent error log entries if exist
if [ -f "$ERROR_LOG" ] && [ -s "$ERROR_LOG" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 Recent Error Log Entries"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Show last 3 entries
  grep -A 10 "^### Entry" "$ERROR_LOG" | tail -40
  echo ""
fi
```

**Why always read for /debug:**
- Past error resolutions may apply to current issue
- Architecture decisions may explain unexpected behavior
- Similar blockers may have documented workarounds
- System components help diagnose dependency issues

---

### Phase 2: CREATE ERROR LOG (if missing)

```bash
# Create error log template if doesn't exist
if [ ! -f "$ERROR_LOG" ]; then
  echo "⚠️  Error log not found, creating template..."
  echo ""

  cat > "$ERROR_LOG" <<'EOF'
# Error Log

**Purpose**: Track failures, root causes, and learnings during implementation.

## Format

Each entry follows this structure:

```markdown
### Entry N: YYYY-MM-DD - Brief Title

**Failure**: What broke (specific component or behavior)
**Symptom**: Observable behavior (error messages, stack traces, incorrect output)
**Learning**: Root cause and key insights (why it happened, how to prevent)
**Ghost Context Cleanup**: Retired artifacts or corrected assumptions

[Optional: During T0NN task-name if during implementation]
[Optional: From /optimize auto-fix (Issue ID: CR###) if structured mode]
```

## Guidelines

- **Be specific**: Include file paths, function names, error codes
- **Include context**: Task IDs, timestamps, related commits
- **Document learnings**: What we learned that prevents future similar issues
- **Ghost context**: What was removed, deprecated, or corrected

## Categories

- **Test Failures**: Unit tests, integration tests, E2E tests
- **Build Errors**: Compilation failures, dependency issues
- **Runtime Errors**: API failures, crashes, exceptions
- **UI Bugs**: Layout issues, interaction problems, visual regressions
- **Performance**: Slow queries, memory leaks, bundle size
- **Security**: Vulnerabilities, authorization issues
- **Integration**: API mismatches, data format issues

---

EOF

  echo "✅ Error log template created"
  echo ""
fi
```

---

### Phase 2.5: DEPLOYMENT DIAGNOSTICS (if deployment-related error)

```bash
# Check if error is deployment-related
if [ "$STRUCTURED_MODE" = false ]; then
  if [[ "$ERROR_DESCRIPTION" =~ deploy|vercel|railway|staging|production|CI|workflow ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Deployment Diagnostics"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check recent Vercel deployments
    echo "Recent Vercel deployments:"
    RECENT_VERCEL=$(vercel ls --limit 5 2>/dev/null || echo "")

    if [ -n "$RECENT_VERCEL" ]; then
      echo "$RECENT_VERCEL" | grep -E "ERROR|FAILED|READY" | head -5 | sed 's/^/  /'

      # Get most recent failed deployment
      FAILED_DEPLOY=$(echo "$RECENT_VERCEL" | grep "ERROR" | head -1 | awk '{print $1}')

      if [ -n "$FAILED_DEPLOY" ]; then
        echo ""
        echo "Last Vercel failure logs (deployment: $FAILED_DEPLOY):"
        vercel logs "$FAILED_DEPLOY" 2>/dev/null | tail -30 | sed 's/^/  /' || echo "  Unable to fetch logs"
      fi
    else
      echo "  No recent Vercel deployments found"
    fi

    echo ""

    # Check recent Railway deployments
    if command -v railway &> /dev/null; then
      echo "Recent Railway deployments:"
      RECENT_RAILWAY=$(railway deployments --limit 5 --json 2>/dev/null || echo "")

      if [ -n "$RECENT_RAILWAY" ]; then
        echo "$RECENT_RAILWAY" | jq -r '.[] | "\(.status) - \(.createdAt) - \(.id)"' | head -5 | sed 's/^/  /'

        # Get most recent failed deployment
        FAILED_RAILWAY=$(echo "$RECENT_RAILWAY" | jq -r '.[] | select(.status=="FAILED") | .id' | head -1)

        if [ -n "$FAILED_RAILWAY" ]; then
          echo ""
          echo "Last Railway failure logs (deployment: $FAILED_RAILWAY):"
          railway logs --deployment "$FAILED_RAILWAY" 2>/dev/null | tail -30 | sed 's/^/  /' || echo "  Unable to fetch logs"
        fi
      else
        echo "  No recent Railway deployments found"
      fi
    else
      echo "  Railway CLI not installed (skip Railway check)"
    fi

    echo ""

    # Check for common deployment failure patterns
    echo "Common failure patterns:"
    echo ""

    # Function size limit
    if vercel logs 2>/dev/null | grep -q "Function size"; then
      echo "  ⚠️  Function size limit exceeded"
      echo "     Fix: Reduce bundle size or split functions"
      echo ""
    fi

    # Memory limit
    if railway logs 2>/dev/null | grep -q "out of memory\|OOM"; then
      echo "  ⚠️  Out of memory"
      echo "     Fix: Increase Railway memory or optimize code"
      echo ""
    fi

    # Timeout
    if vercel logs 2>/dev/null | grep -q "FUNCTION_INVOCATION_TIMEOUT\|timeout"; then
      echo "  ⚠️  Function timeout"
      echo "     Fix: Optimize slow operations or increase timeout"
      echo ""
    fi

    # Missing environment variables
    if vercel logs 2>/dev/null | grep -q "undefined.*env\|environment variable"; then
      echo "  ⚠️  Missing environment variable"
      echo "     Fix: Run /check-env staging (or production)"
      echo ""
    fi

    # Build errors
    if vercel logs 2>/dev/null | grep -q "Build failed\|npm ERR\|error TS"; then
      echo "  ⚠️  Build errors"
      echo "     Fix: Run /preflight to test builds locally"
      echo ""
    fi

    # Docker image issues
    if railway logs 2>/dev/null | grep -q "Failed to pull image\|image not found"; then
      echo "  ⚠️  Docker image issues"
      echo "     Fix: Run /dry-run to test Docker builds"
      echo ""
    fi

    # Check GitHub Actions failures
    echo "Recent GitHub Actions failures:"
    GH_FAILURES=$(gh run list --workflow=deploy-staging.yml --status=failure --limit 3 --json conclusion,displayTitle,createdAt 2>/dev/null || echo "")

    if [ -n "$GH_FAILURES" ]; then
      echo "$GH_FAILURES" | jq -r '.[] | "  \(.displayTitle) - \(.createdAt)"'

      # Get most recent failed run
      FAILED_RUN_ID=$(echo "$GH_FAILURES" | jq -r '.[0].databaseId' 2>/dev/null || echo "")

      if [ -n "$FAILED_RUN_ID" ]; then
        echo ""
        echo "Last workflow failure logs (run: $FAILED_RUN_ID):"
        gh run view "$FAILED_RUN_ID" --log-failed 2>/dev/null | tail -30 | sed 's/^/  /' || echo "  Unable to fetch logs"
      fi
    else
      echo "  No recent workflow failures"
    fi

    echo ""
    echo "Deployment diagnostics complete"
    echo ""
  fi
fi
```

---

### Phase 3: LOAD CONTEXT (manual mode only)

```bash
if [ "$STRUCTURED_MODE" = false ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Gathering Context"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Git status
  echo "Git status:"
  CHANGED_FILES=$(git status --short | head -10)
  if [ -z "$CHANGED_FILES" ]; then
    echo "  (working tree clean)"
  else
    echo "$CHANGED_FILES" | sed 's/^/  /'
  fi
  echo ""

  # Recent commits
  echo "Recent commits:"
  git log -5 --oneline --decorate | sed 's/^/  /'
  echo ""

  # Check for existing error log entries
  ENTRY_COUNT=$(grep -c "^### Entry" "$ERROR_LOG" 2>/dev/null || echo 0)
  echo "Error log: $ENTRY_COUNT existing entries"

  if [ "$ENTRY_COUNT" -gt 0 ]; then
    echo ""
    echo "Recent errors:"
    grep "^### Entry" "$ERROR_LOG" | tail -3 | sed 's/^/  /'
  fi

  echo ""

  # Check for current task (if in NOTES.md)
  if [ -f "$NOTES_FILE" ]; then
    CURRENT_TASK=$(grep "✅ T[0-9]" "$NOTES_FILE" 2>/dev/null | tail -1 | grep -o "T[0-9]*" || echo "")
    if [ -n "$CURRENT_TASK" ]; then
      echo "Current task: $CURRENT_TASK"
      echo ""
    fi
  fi
fi
```

---

### Phase 4: GATHER ERROR DESCRIPTION

```bash
if [ "$STRUCTURED_MODE" = false ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Error Description"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Gather error description
  echo "Describe the issue:"
  echo "  (e.g., 'Test test_create_user failing with IntegrityError')"
  read -p "> " ERROR_DESCRIPTION

  if [ -z "$ERROR_DESCRIPTION" ]; then
    echo "❌ No description provided"
    exit 1
  fi

  echo ""

  # Categorize error
  echo "Error type:"
  echo "  1. Test failure"
  echo "  2. Build error"
  echo "  3. Runtime error"
  echo "  4. UI bug"
  echo "  5. Performance issue"
  echo "  6. Other"
  read -p "Choose (1-6): " ERROR_TYPE_NUM

  case "$ERROR_TYPE_NUM" in
    1) ERROR_TYPE="test" ;;
    2) ERROR_TYPE="build" ;;
    3) ERROR_TYPE="runtime" ;;
    4) ERROR_TYPE="ui" ;;
    5) ERROR_TYPE="performance" ;;
    *) ERROR_TYPE="other" ;;
  esac

  echo ""

  # Component
  echo "Component:"
  echo "  1. Backend API"
  echo "  2. Frontend"
  echo "  3. Database"
  echo "  4. Integration"
  read -p "Choose (1-4): " COMPONENT_NUM

  case "$COMPONENT_NUM" in
    1) COMPONENT="backend" ;;
    2) COMPONENT="frontend" ;;
    3) COMPONENT="database" ;;
    *) COMPONENT="integration" ;;
  esac

  echo ""
  echo "Summary:"
  echo "  Description: $ERROR_DESCRIPTION"
  echo "  Type: $ERROR_TYPE"
  echo "  Component: $COMPONENT"
  echo ""
fi
```

---

### Phase 5: REPRODUCE ERROR (manual mode only)

```bash
if [ "$STRUCTURED_MODE" = false ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Reproducing Error"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  case "$ERROR_TYPE" in
    test)
      echo "Running tests to reproduce..."
      echo ""

      if [ "$COMPONENT" = "backend" ]; then
        cd api
        echo "Backend tests:"
        uv run pytest -v 2>&1 | tee /tmp/test-output.log
        TEST_RESULT=${PIPESTATUS[0]}
        cd ..

        if [ $TEST_RESULT -ne 0 ]; then
          echo ""
          echo "Test failures found:"
          grep -A 5 "FAILED" /tmp/test-output.log | head -20
        fi
      elif [ "$COMPONENT" = "frontend" ]; then
        cd apps/app
        echo "Frontend tests:"
        pnpm test 2>&1 | tee /tmp/test-output.log
        TEST_RESULT=${PIPESTATUS[0]}
        cd ../..

        if [ $TEST_RESULT -ne 0 ]; then
          echo ""
          echo "Test failures found:"
          grep -A 5 "FAIL" /tmp/test-output.log | head -20
        fi
      fi
      ;;

    build)
      echo "Building to reproduce..."
      echo ""

      if [ "$COMPONENT" = "backend" ]; then
        cd api
        echo "Backend build:"
        uv run python -m compileall app/ 2>&1 | tee /tmp/build-output.log
        BUILD_RESULT=${PIPESTATUS[0]}
        cd ..
      elif [ "$COMPONENT" = "frontend" ]; then
        cd apps/app
        echo "Frontend build:"
        pnpm build 2>&1 | tee /tmp/build-output.log
        BUILD_RESULT=${PIPESTATUS[0]}
        cd ../..

        if [ $BUILD_RESULT -ne 0 ]; then
          echo ""
          echo "Build errors found:"
          grep -i "error" /tmp/build-output.log | head -20
        fi
      fi
      ;;

    runtime)
      echo "Runtime error debugging:"
      echo "  1. Check application logs"
      echo "     Backend: tail -f api/logs/app.log"
      echo "     Frontend: Browser console (F12)"
      echo ""
      echo "  2. Use interactive REPL (see Phase 6)"
      echo ""
      echo "  3. Add debug logging and reproduce"
      echo ""
      ;;

    ui)
      echo "UI debugging:"
      echo "  1. Open app in browser: http://localhost:3001"
      echo "  2. Use DevTools (F12):"
      echo "     - Elements: Inspect DOM/CSS"
      echo "     - Console: Check errors"
      echo "     - Network: Check failed requests"
      echo ""
      echo "  3. Test in different viewports"
      echo ""

      # Check if dev server running
      if curl -sf http://localhost:3001 >/dev/null 2>&1; then
        echo "✅ Dev server running: http://localhost:3001"
      else
        echo "⚠️  Dev server not running"
        echo "   Start: cd apps/app && pnpm dev"
      fi
      echo ""
      ;;

    performance)
      echo "Performance profiling:"
      echo "  Frontend:"
      echo "    - Browser DevTools → Performance tab"
      echo "    - Record interaction, analyze timeline"
      echo "    - Check bundle size: pnpm analyze"
      echo ""
      echo "  Backend:"
      echo "    - Add timing logs around slow operations"
      echo "    - Use EXPLAIN ANALYZE for slow queries"
      echo "    - Check for N+1 query problems"
      echo ""
      ;;
  esac

  echo ""
fi
```

---

### Phase 6: INTERACTIVE DEBUGGING (manual mode only)

```bash
if [ "$STRUCTURED_MODE" = false ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Interactive Debugging"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  echo "Options:"
  echo "  1. Interactive REPL (Python/Node)"
  echo "  2. Tail logs (real-time)"
  echo "  3. Skip (proceed to agent delegation)"
  read -p "Choose (1-3): " DEBUG_OPTION

  case "$DEBUG_OPTION" in
    1)
      echo ""
      if [ "$COMPONENT" = "backend" ]; then
        echo "Python REPL with app context..."
        echo ""

        cd api

        # Create debug script
        cat > /tmp/debug_context.py <<'PYEOF'
import sys
sys.path.insert(0, '.')

from app.main import app
from app.database import SessionLocal
from app.models import *

print("Available:")
print("  - app: FastAPI application")
print("  - SessionLocal: Database session factory")
print("  - All models imported")
print("")
print("Example: db = SessionLocal(); users = db.query(User).all()")
print("Ctrl+D to exit")
print("")
PYEOF

        uv run python -i /tmp/debug_context.py || true
        cd ..

      elif [ "$COMPONENT" = "frontend" ]; then
        echo "Node REPL with app context..."
        echo ""

        cd apps/app

        node --experimental-repl-await <<'NODEOF'
console.log('Available:');
console.log('  - Use await for async operations');
console.log('  - Import modules with require() or dynamic import()');
console.log('  - Ctrl+D to exit');
console.log('');
NODEOF

        cd ../..
      fi

      echo ""
      ;;

    2)
      echo ""
      echo "Available logs:"
      echo "  1. Backend API (uvicorn)"
      echo "  2. Frontend dev server"
      echo "  3. Database queries"
      echo "  4. All (multiplexed)"
      read -p "Choose (1-4): " LOG_CHOICE

      case "$LOG_CHOICE" in
        1)
          if [ -f "api/logs/app.log" ]; then
            echo ""
            echo "Tailing backend logs (Ctrl+C to stop):"
            tail -f api/logs/app.log
          else
            echo ""
            echo "⚠️  Backend log not found"
            echo "   Start backend: cd api && uv run uvicorn app.main:app --reload"
          fi
          ;;
        2)
          if [ -f "/tmp/app-dev.log" ]; then
            echo ""
            echo "Tailing frontend logs (Ctrl+C to stop):"
            tail -f /tmp/app-dev.log
          else
            echo ""
            echo "⚠️  Frontend log not found"
            echo "   Start frontend: cd apps/app && pnpm dev"
          fi
          ;;
        3)
          if [ -f "api/logs/db.log" ]; then
            echo ""
            echo "Tailing database logs (Ctrl+C to stop):"
            tail -f api/logs/db.log
          else
            echo ""
            echo "⚠️  Database log not found"
          fi
          ;;
        4)
          echo ""
          echo "Multiplexed logs (Ctrl+C to stop):"
          tail -f api/logs/*.log /tmp/*-dev.log 2>/dev/null || echo "No logs found"
          ;;
      esac

      echo ""
      ;;

    *)
      echo ""
      echo "Skipping interactive debugging"
      echo ""
      ;;
  esac
fi
```

---

### Phase 7: ROUTE TO SPECIALIST

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Routing to Specialist"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Determine agent based on mode and context
if [ "$STRUCTURED_MODE" = true ]; then
  # Structured mode: Route based on category
  case "$CATEGORY" in
    "Contract Violation")
      if [[ "$FILE" =~ ^api/ ]]; then
        SELECTED_AGENT="cfipros-backend-dev"
      else
        SELECTED_AGENT="cfipros-frontend-shipper"
      fi
      ;;
    "KISS"|"DRY")
      if [[ "$FILE" =~ ^api/ ]]; then
        SELECTED_AGENT="cfipros-backend-dev"
      else
        SELECTED_AGENT="cfipros-frontend-shipper"
      fi
      ;;
    "Security")
      SELECTED_AGENT="cfipros-debugger"
      ;;
    "Type Safety")
      if [[ "$FILE" =~ ^api/ ]]; then
        SELECTED_AGENT="cfipros-backend-dev"
      else
        SELECTED_AGENT="cfipros-frontend-shipper"
      fi
      ;;
    "Test Coverage")
      SELECTED_AGENT="cfipros-qa-test"
      ;;
    "Database")
      SELECTED_AGENT="cfipros-database-architect"
      ;;
    *)
      SELECTED_AGENT="cfipros-debugger"
      ;;
  esac

  echo "Category: $CATEGORY"
  echo "Agent: $SELECTED_AGENT"
  echo ""

else
  # Manual mode: Route based on component and error type
  if [ "$COMPONENT" = "backend" ]; then
    if [ "$ERROR_TYPE" = "test" ] || [ "$ERROR_TYPE" = "runtime" ]; then
      SELECTED_AGENT="cfipros-debugger"
    elif [ "$ERROR_TYPE" = "build" ]; then
      SELECTED_AGENT="cfipros-backend-dev"
    else
      SELECTED_AGENT="cfipros-debugger"
    fi
  elif [ "$COMPONENT" = "frontend" ]; then
    if [ "$ERROR_TYPE" = "test" ] || [ "$ERROR_TYPE" = "ui" ]; then
      SELECTED_AGENT="cfipros-debugger"
    elif [ "$ERROR_TYPE" = "build" ]; then
      SELECTED_AGENT="cfipros-frontend-shipper"
    else
      SELECTED_AGENT="cfipros-debugger"
    fi
  elif [ "$COMPONENT" = "database" ]; then
    SELECTED_AGENT="cfipros-database-architect"
  else
    SELECTED_AGENT="cfipros-debugger"
  fi

  echo "Component: $COMPONENT"
  echo "Error type: $ERROR_TYPE"
  echo "Agent: $SELECTED_AGENT"
  echo ""
fi

# Create delegation context
DELEGATION_FILE="/tmp/debug-delegation-$SLUG.md"

if [ "$STRUCTURED_MODE" = true ]; then
  # Structured mode context
  cat > "$DELEGATION_FILE" <<EOF
# Debug Delegation: $ISSUE_ID ($SEVERITY)

**Agent**: $SELECTED_AGENT
**Feature**: $SLUG
**Error Log**: $ERROR_LOG

## Task

Fix the following code review issue:

**Issue ID**: $ISSUE_ID
**Severity**: $SEVERITY
**Category**: $CATEGORY
**File**: $FILE:$LINE
**Description**: $DESCRIPTION
**Recommendation**: $RECOMMENDATION

## Expected Output

1. Root cause identified
2. Minimal fix applied (following recommendation)
3. Verification completed:
   - Lint/type checks pass
   - Existing tests pass
   - New tests added if needed
4. Files changed (list with paths)
5. Brief summary of fix

## Files to Review

- $FILE
$(if [ -n "$(git diff --name-only HEAD | grep "^$FILE")" ]; then
  echo "- (file has uncommitted changes)"
fi)

## Quality Gates

Before returning:
- \`\`\`bash
  # Backend
  cd api
  uv run ruff check . && uv run mypy app/ && uv run pytest

  # Frontend
  cd apps/app
  pnpm lint && pnpm type-check && pnpm test
  \`\`\`
EOF

else
  # Manual mode context
  cat > "$DELEGATION_FILE" <<EOF
# Debug Delegation: $ERROR_DESCRIPTION

**Agent**: $SELECTED_AGENT
**Feature**: $SLUG
**Error Log**: $ERROR_LOG

## Task

Debug and fix: $ERROR_DESCRIPTION

**Error Type**: $ERROR_TYPE
**Component**: $COMPONENT

## Context

$(if [ -f /tmp/test-output.log ]; then
  echo "### Test Output"
  echo ""
  echo "\`\`\`"
  tail -50 /tmp/test-output.log
  echo "\`\`\`"
  echo ""
elif [ -f /tmp/build-output.log ]; then
  echo "### Build Output"
  echo ""
  echo "\`\`\`"
  tail -50 /tmp/build-output.log
  echo "\`\`\`"
  echo ""
fi)

### Changed Files

\`\`\`
$(git status --short)
\`\`\`

### Recent Commits

\`\`\`
$(git log -5 --oneline)
\`\`\`

## Expected Output

1. Root cause identified
2. Fix applied
3. Verification completed (lint, types, tests)
4. Files changed (list with paths)
5. Brief summary of fix
EOF

fi

echo "Delegation context: $DELEGATION_FILE"
echo ""

# Agent invocation
echo "Delegating to agent..."
echo ""
echo "The agent will:"
echo "  1. Analyze the error/issue"
echo "  2. Apply appropriate fix"
echo "  3. Run verification (lint, types, tests)"
echo "  4. Update error log if needed"
echo ""
echo "Review delegation: $DELEGATION_FILE"
echo ""

# Note: In actual implementation, this would invoke the Task tool
# Task tool with:
#   subagent_type: $SELECTED_AGENT
#   description: Fix $ERROR_DESCRIPTION (or $ISSUE_ID)
#   prompt: $(cat $DELEGATION_FILE)

echo "Press Enter when agent completes or Ctrl+C to cancel..."
read

# Parse agent result (if available)
AGENT_RESULT="/tmp/agent-result-$SLUG.json"
if [ -f "$AGENT_RESULT" ]; then
  AGENT_SUCCESS=$(jq -r '.fix_applied' "$AGENT_RESULT" 2>/dev/null || echo "unknown")
  AGENT_FILES=$(jq -r '.files_changed[]' "$AGENT_RESULT" 2>/dev/null | tr '\n' ' ')
  AGENT_ROOT_CAUSE=$(jq -r '.root_cause' "$AGENT_RESULT" 2>/dev/null || echo "See fix details")
  AGENT_CHANGES=$(jq -r '.changes_summary' "$AGENT_RESULT" 2>/dev/null || echo "See git diff")
  AGENT_NOTES=$(jq -r '.notes // "None"' "$AGENT_RESULT" 2>/dev/null)

  echo ""
  echo "✅ Agent completed"
  echo "   Fix applied: $AGENT_SUCCESS"
  echo "   Files changed: $AGENT_FILES"
  echo "   Root cause: $AGENT_ROOT_CAUSE"
  echo ""
else
  echo ""
  echo "⚠️  Agent result not found"
  echo "   Assuming agent completed manually"
  echo ""

  # Manual extraction
  echo "What was the root cause?"
  read -p "> " AGENT_ROOT_CAUSE

  echo ""
  echo "What files were changed?"
  read -p "> " AGENT_FILES

  echo ""
  echo "Brief summary of fix?"
  read -p "> " AGENT_CHANGES

  echo ""
  AGENT_NOTES="Manual fix"
  AGENT_SUCCESS="true"
fi
```

---

### Phase 8: VERIFY FIX

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Verifying Fix"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

VERIFICATION_PASSED=true

# Detect affected area from changed files
if [ -n "$AGENT_FILES" ]; then
  CHANGED_FILES="$AGENT_FILES"
elif [ -n "$FILE" ]; then
  CHANGED_FILES="$FILE"
else
  CHANGED_FILES=$(git diff --name-only HEAD | tr '\n' ' ')
fi

echo "Changed files: $CHANGED_FILES"
echo ""

# Backend verification
if echo "$CHANGED_FILES" | grep -q "api/"; then
  echo "Backend verification:"

  # Lint
  echo "  Running ruff..."
  cd api
  uv run ruff check . --quiet
  if [ $? -eq 0 ]; then
    echo "  ✅ Lint passed"
  else
    echo "  ❌ Lint failed"
    VERIFICATION_PASSED=false
  fi

  # Types
  echo "  Running mypy..."
  uv run mypy app/ --no-error-summary 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "  ✅ Types passed"
  else
    echo "  ❌ Types failed"
    VERIFICATION_PASSED=false
  fi

  # Tests
  echo "  Running tests..."
  uv run pytest --quiet 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "  ✅ Tests passed"
  else
    echo "  ❌ Tests failed"
    VERIFICATION_PASSED=false
  fi

  cd ..
  echo ""
fi

# Frontend verification
if echo "$CHANGED_FILES" | grep -q "apps/"; then
  echo "Frontend verification:"

  # Determine which app
  if echo "$CHANGED_FILES" | grep -q "apps/app"; then
    APP_DIR="apps/app"
  else
    APP_DIR="apps/marketing"
  fi

  cd "$APP_DIR"

  # Lint
  echo "  Running eslint..."
  pnpm lint --quiet 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "  ✅ Lint passed"
  else
    echo "  ❌ Lint failed"
    VERIFICATION_PASSED=false
  fi

  # Types
  echo "  Running tsc..."
  pnpm type-check 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "  ✅ Types passed"
  else
    echo "  ❌ Types failed"
    VERIFICATION_PASSED=false
  fi

  # Tests
  echo "  Running tests..."
  pnpm test --run --silent 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "  ✅ Tests passed"
  else
    echo "  ❌ Tests failed"
    VERIFICATION_PASSED=false
  fi

  cd ../..
  echo ""
fi

if [ "$VERIFICATION_PASSED" = true ]; then
  echo "✅ All verification passed"
else
  echo "❌ Verification failed"
  echo "   Fix issues before committing"
fi

echo ""
```

---

### Phase 9: UPDATE ERROR LOG

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Updating Error Log"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get next entry number
LAST_ENTRY=$(grep "^### Entry" "$ERROR_LOG" | tail -1 | grep -o "[0-9]*" | head -1)
if [ -z "$LAST_ENTRY" ]; then
  NEXT_ENTRY=1
else
  NEXT_ENTRY=$((LAST_ENTRY + 1))
fi

echo "Entry #$NEXT_ENTRY"
echo ""

# Gather entry details based on mode
if [ "$STRUCTURED_MODE" = true ]; then
  # Structured mode: Use issue details
  FAILURE_TEXT="$DESCRIPTION"
  SYMPTOM_TEXT="Code review found $SEVERITY $CATEGORY issue at $FILE:$LINE"
  LEARNING_TEXT="$AGENT_ROOT_CAUSE"
  GHOST_CONTEXT="${AGENT_NOTES:-None}"
  ENTRY_TITLE="[$ISSUE_ID] $CATEGORY Fix"

else
  # Manual mode: Collect details
  echo "What broke? (Failure)"
  echo "  Current: ${ERROR_DESCRIPTION:-(not set)}"
  read -p "> " FAILURE_INPUT
  FAILURE_TEXT="${FAILURE_INPUT:-$ERROR_DESCRIPTION}"

  echo ""
  echo "Observable behavior? (Symptom)"
  echo "  (error messages, stack traces, incorrect output)"
  read -p "> " SYMPTOM_TEXT

  echo ""
  echo "Root cause? (Learning)"
  echo "  Current: ${AGENT_ROOT_CAUSE:-(not set)}"
  read -p "> " LEARNING_INPUT
  LEARNING_TEXT="${LEARNING_INPUT:-$AGENT_ROOT_CAUSE}"

  echo ""
  echo "What was retired/corrected? (Ghost Context)"
  read -p "> " GHOST_CONTEXT

  ENTRY_TITLE=$(echo "$ERROR_DESCRIPTION" | head -c 60)
fi

# Append entry
cat >> "$ERROR_LOG" <<EOF

### Entry $NEXT_ENTRY: $(date +%Y-%m-%d) - $ENTRY_TITLE

**Failure**: $FAILURE_TEXT
**Symptom**: $SYMPTOM_TEXT
**Learning**: $LEARNING_TEXT
**Ghost Context Cleanup**: $GHOST_CONTEXT

$(if [ "$STRUCTURED_MODE" = true ]; then
  echo "**From /optimize auto-fix** (Issue ID: $ISSUE_ID)"
else
  # Check if during task
  CURRENT_TASK=$(grep "✅ T[0-9]" "$NOTES_FILE" 2>/dev/null | tail -1 | grep -o "T[0-9]*" || echo "")
  if [ -n "$CURRENT_TASK" ]; then
    echo "**During $CURRENT_TASK**"
  fi
fi)
EOF

echo ""
echo "✅ Error log updated: Entry $NEXT_ENTRY"
echo ""

# Show entry
echo "Preview:"
tail -15 "$ERROR_LOG" | sed 's/^/  /'
echo ""
```

---

### Phase 10: COMMIT FIX

```bash
if [ "$VERIFICATION_PASSED" = true ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Committing Fix"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Stage changes
  git add "$ERROR_LOG"

  if [ -n "$CHANGED_FILES" ]; then
    for file in $CHANGED_FILES; do
      if [ -f "$file" ]; then
        git add "$file"
      fi
    done
  else
    # Stage all changes
    git add .
  fi

  # Generate commit message
  if [ "$STRUCTURED_MODE" = true ]; then
    COMMIT_MSG="fix: resolve $CATEGORY issue ($ISSUE_ID)

$DESCRIPTION

Root cause: $LEARNING_TEXT
Fix: $AGENT_CHANGES

Updated error-log.md with Entry $NEXT_ENTRY

From /optimize auto-fix

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
  else
    COMMIT_MSG="fix: $(echo "$ERROR_DESCRIPTION" | head -c 60)

Error: $FAILURE_TEXT
Root cause: $LEARNING_TEXT
Fix: $(echo "$CHANGED_FILES" | tr ' ' ', ')

Updated error-log.md with Entry $NEXT_ENTRY

$(if [ -n "$CURRENT_TASK" ]; then
  echo "Completed during: $CURRENT_TASK"
fi)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
  fi

  # Commit
  git commit -m "$COMMIT_MSG"

  if [ $? -eq 0 ]; then
    echo "✅ Changes committed"

    COMMIT_SHA=$(git rev-parse --short HEAD)
    echo "   Commit: $COMMIT_SHA"
  else
    echo "❌ Commit failed"
    exit 1
  fi

  echo ""

  # Offer to push
  read -p "Push to origin? (y/N): " PUSH_CHANGES
  if [ "$PUSH_CHANGES" = "y" ]; then
    CURRENT_BRANCH=$(git branch --show-current)
    git push origin "$CURRENT_BRANCH"
    echo "✅ Changes pushed to $CURRENT_BRANCH"
  fi

  echo ""
else
  echo "⚠️  Skipping commit (verification failed)"
  echo "   Fix issues and re-run /debug"
  echo ""
fi
```

---

### Phase 11: FINAL REPORT

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Debug Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$STRUCTURED_MODE" = true ]; then
  # Structured mode report
  echo "🆔 Issue ID: $ISSUE_ID"
  echo "📊 Severity: $SEVERITY"
  echo "🏷️  Category: $CATEGORY"
  echo "📂 File: $FILE:$LINE"
  echo ""

  if [ "$AGENT_SUCCESS" = "true" ]; then
    echo "✅ Fix applied"
  else
    echo "❌ Fix not applied"
  fi

  echo "📂 Files changed: $AGENT_FILES"
  echo ""

  if [ "$VERIFICATION_PASSED" = true ]; then
    echo "🧪 Verification: Lint ✅, Types ✅, Tests ✅"
  else
    echo "🧪 Verification: Failed (see above)"
  fi

  echo ""
  echo "📝 Error log: Entry $NEXT_ENTRY added (linked to $ISSUE_ID)"
  echo ""

  if [ "$VERIFICATION_PASSED" = true ]; then
    echo "🔄 Return to /optimize for next issue"
  else
    echo "⚠️  Fix verification issues before continuing"
  fi

else
  # Manual mode report
  echo "🐛 Error: $ERROR_DESCRIPTION"
  echo "🔍 Root cause: $LEARNING_TEXT"
  echo ""

  if [ "$AGENT_SUCCESS" = "true" ]; then
    echo "✅ Fix: $AGENT_CHANGES"
  else
    echo "⏸️  In progress"
  fi

  echo ""
  echo "📝 Error log: Entry $NEXT_ENTRY added"
  echo ""

  if [ "$VERIFICATION_PASSED" = true ]; then
    echo "🧪 Verification: All checks passed"
  else
    echo "🧪 Verification: Failed (see above)"
  fi

  echo ""
  echo "📂 Files changed: $CHANGED_FILES"
  echo ""

  if [ "$VERIFICATION_PASSED" = true ]; then
    echo "Next: Continue with /implement or run /optimize"
  else
    echo "Next: Fix verification issues and re-run /debug"
  fi
fi

echo ""

# Cleanup temp files
rm -f /tmp/test-output.log /tmp/build-output.log /tmp/debug_context.py
rm -f "$DELEGATION_FILE"
```

---

## ERROR HANDLING

**Error log missing**: Creates template before proceeding

**Specialist agent unavailable**: Falls back to manual debugging, documents findings in error-log

**Agent timeout (>5min)**: User cancels agent, can provide manual debugging or skip

**Fix verification fails**: Documents partial findings, marks as "in-progress" in error-log

**No reproduction**: Documents attempted steps in error-log with "Unable to reproduce" note

**Git conflicts**: Aborts commit, instructs user to resolve conflicts first

---

## CONSTRAINTS

- ALWAYS update error-log.md (even if fix unsuccessful)
- Include timestamps and task IDs when applicable
- Be specific about ghost context (file paths, variables)
- Commit error-log.md with fix (single atomic commit)
- One debugging session per /debug invocation
- In structured mode, return control to /optimize after completion

---

## RETURN

**Manual mode** (user-invoked):
- 🐛 Error: [brief description]
- 🔍 Root cause: [identified cause]
- ✅ Fix: [what was changed] OR ⏸️ In progress
- 📝 error-log.md: Entry N added
- 🧪 Verification: [tests passing/failing]
- 📂 Files changed: [list]
- Next: Continue with /implement or fix remaining issues

**Structured mode** (from /optimize):
- 🆔 Issue ID: [CR###]
- 📊 Severity: [CRITICAL/HIGH/MEDIUM/LOW]
- 🏷️ Category: [Contract/KISS/DRY/Security/etc]
- ✅ Fix applied: [Yes/No]
- 📂 Files changed: [list]
- 🧪 Verification: Lint [✅/❌], Types [✅/❌], Tests [✅/❌]
- 📝 error-log.md: Entry N added (linked to issue ID)
- 🔄 Return to /optimize: [for next issue or completion]
