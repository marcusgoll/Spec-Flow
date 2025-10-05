---
description: Debug errors and update error-log.md with systematic tracking
---

Debug issue for: specs/$FEATURE

## LOAD CONTEXT

1. **Check prerequisites**:
   ```bash
   pwsh -NoProfile -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Json
   # or
   .spec-flow/scripts/bash/check-prerequisites.sh --json
   ```
   Parse FEATURE_DIR from output

2. **Load error log**:
   ```bash
   Read specs/$FEATURE/error-log.md
   ```
   Review recent entries to avoid repeating known issues

3. **Gather context**:
   ```bash
   # Check git status for unstaged changes
   git status

   # Check recent commits
   git log -5 --oneline

   # Check for test failures
   cd api && uv run pytest --lf || true
   cd apps/app && pnpm test --lastFailed || true
   ```

## PARSE ERROR DESCRIPTION

From user input, identify:
- **Error type**: Build failure, test failure, runtime error, UI bug, performance issue
- **Component**: Backend API, Frontend, Database, Integration
- **Symptoms**: Error messages, stack traces, incorrect behavior
- **Context**: Task ID (if during /implement), file paths, reproduction steps

## STRUCTURED INPUT (from /optimize)

When invoked with `--from-optimize` flag, accept structured issue input from code review:

### Input Format

```bash
# Flags passed from /optimize auto-fix:
--from-optimize              # Indicates structured input mode
--issue-id="CR001"           # Issue ID from code-review-report.md
--severity="CRITICAL"         # CRITICAL, HIGH, MEDIUM, LOW
--category="Contract Violation"  # Contract Violation, KISS, DRY, Security, Type Safety, Test Coverage, Database
--file="api/app/routes/users.py"  # File path
--line="45"                  # Line number
--description="Response schema missing 'email' field required by OpenAPI contract"
--recommendation="Add email: str field to UserResponse schema"
```

### Parse Structured Input

When `--from-optimize` flag is present:

1. **Skip manual context gathering** (already provided)
2. **Extract structured fields**:
   ```bash
   ISSUE_ID=$1
   SEVERITY=$2
   CATEGORY=$3
   FILE=$4
   LINE=$5
   DESCRIPTION=$6
   RECOMMENDATION=$7
   ```

3. **Validate inputs**:
   - Issue ID format: CR###
   - Severity: CRITICAL | HIGH | MEDIUM | LOW
   - Category: Known category type
   - File: Valid file path

### Route Based on Category

Based on issue category, route to appropriate specialist agent:

**Contract Violation**:
- Backend contracts  spec-flow-backend-dev
- Frontend contracts  spec-flow-frontend-shipper
- Fix: Update schema/endpoint to match OpenAPI contract

**KISS (Keep It Simple)**:
- Backend  spec-flow-backend-dev
- Frontend  spec-flow-frontend-shipper
- Fix: Simplify complex code, remove unnecessary abstraction

**DRY (Don't Repeat Yourself)**:
- Backend  spec-flow-backend-dev
- Frontend  spec-flow-frontend-shipper
- Fix: Extract duplicate code into shared utility/service

**Security**:
- Backend/Frontend  spec-flow-debugger
- Fix: Apply security patch, add validation, fix vulnerability

**Type Safety**:
- Backend  spec-flow-backend-dev (add Python types)
- Frontend  spec-flow-frontend-shipper (add TypeScript types)
- Fix: Add missing type annotations, fix type errors

**Test Coverage**:
- All  spec-flow-qa-test
- Fix: Add missing unit/integration tests

**Database**:
- Schema/queries  spec-flow-database-architect
- Fix: Update schema, optimize query, fix migration

### Structured Agent Invocation

```bash
# Example for Contract Violation
Task tool with:
  subagent_type: "spec-flow-backend-dev"  # or appropriate agent
  description: "Fix $CATEGORY issue: $ISSUE_ID"
  prompt: "Fix the following $SEVERITY code review issue:

  **Issue ID**: $ISSUE_ID
  **Category**: $CATEGORY
  **File**: $FILE:$LINE
  **Description**: $DESCRIPTION
  **Recommendation**: $RECOMMENDATION

  Apply minimal fix following the recommendation.

  Steps:
  1. Read the file at $FILE
  2. Locate line $LINE and surrounding context
  3. Apply fix as recommended
  4. Verify fix with quality gates:
     - Lint/type checks
     - Existing tests pass
     - Add new tests if needed

  Return:
  - Root cause identified
  - Files changed (list with paths)
  - Fix applied (what was changed)
  - Verification status (lint, types, tests)
  - Any side effects or notes"
```

### Return Structured Result

Agent should return in structured format:

```json
{
  "issue_id": "CR001",
  "fix_applied": true,
  "root_cause": "Response schema missing required field from OpenAPI contract",
  "files_changed": [
    "api/app/routes/users.py",
    "api/app/schemas/user.py"
  ],
  "changes_summary": "Added email: str field to UserResponse schema",
  "verification": {
    "lint": "pass",
    "type_check": "pass",
    "tests": "pass"
  },
  "error_log_entry": "Entry N added",
  "side_effects": "None",
  "notes": "Contract now matches OpenAPI specification"
}
```

### Update Error Log (Structured Mode)

When fix completes, append entry to error-log.md:

```markdown
### Entry N: YYYY-MM-DD - [$ISSUE_ID] $CATEGORY Fix

**Failure**: $DESCRIPTION
**Symptom**: Code review found $SEVERITY issue at $FILE:$LINE
**Learning**: $ROOT_CAUSE (from agent response)
**Ghost Context Cleanup**: [Any deprecated patterns or assumptions]

**Fix Applied**: $CHANGES_SUMMARY
**Files Changed**: [list from agent response]
**Verification**: Lint , Types , Tests 

**From /optimize auto-fix** (Issue ID: $ISSUE_ID)
```

## ROUTE TO SPECIALIST (Enhanced with /route-agent)

**Use `/route-agent` for intelligent routing:**

```bash
# Analyze error type and determine appropriate specialist
ERROR_DOMAIN=$(analyze-error-domain "$ERROR_TYPE" "$COMPONENT" "$FILE_PATHS")

# Route to specialist using /route-agent helper
/route-agent "$ERROR_DOMAIN" "$ERROR_DESCRIPTION"
```

**Routing decision tree** (from `/route-agent`):
- Backend API/Services  spec-flow-debugger or spec-flow-backend-dev
- Frontend UI/Components  spec-flow-debugger or spec-flow-frontend-shipper
- Database Issues  spec-flow-database-architect
- Test Failures  spec-flow-qa-test
- Performance Issues  Use Chrome DevTools MCP + spec-flow-debugger

### Routing Examples

#### Backend Bug
```bash
Input: "API endpoint returning 500 error on POST /api/users"
Analysis:
  - Domain: Backend API
  - Component: api/app/routes/users.py
  - Error type: Runtime error
Route: spec-flow-debugger
Context: error-log.md, stack trace, recent commits
```

#### Frontend Bug
```bash
Input: "Button not clickable on mobile viewport"
Analysis:
  - Domain: Frontend UI
  - Component: apps/app/components/Button.tsx
  - Error type: UI bug
Route: spec-flow-debugger + Chrome DevTools MCP
Context: CSS styles, responsive design specs, visuals/README.md
```

#### Database Bug
```bash
Input: "Migration failing with constraint violation"
Analysis:
  - Domain: Database
  - Component: api/alembic/versions/
  - Error type: Migration error
Route: spec-flow-database-architect
Context: data-model.md, existing migrations, schema definitions
```

### Manual Debugging (Chrome DevTools)

For live frontend debugging:

```bash
# Take snapshot of problematic page
mcp__chrome-devtools__take_snapshot

# Check console errors
mcp__chrome-devtools__list_console_messages

# Inspect network requests
mcp__chrome-devtools__list_network_requests

# Take screenshot for reference
mcp__chrome-devtools__take_screenshot

# Performance profiling (if performance issue)
mcp__chrome-devtools__performance_start_trace --reload=true --autoStop=true
```

### Performance Issues
**Frontend Performance**:
```bash
# Use Chrome DevTools performance profiling
mcp__chrome-devtools__performance_start_trace --reload=true --autoStop=true

# Analyze insights
mcp__chrome-devtools__performance_analyze_insight --insightName="[insight]"
```

**Backend Performance**:
```bash
# Use spec-flow-debugger with performance focus
Task tool with performance profiling instructions
```

## CAPTURE DEBUG FINDINGS

After specialist completes debugging, extract:
- **Failure**: What broke (e.g., "Authentication middleware rejected valid tokens")
- **Symptom**: Observable behavior (e.g., "401 Unauthorized on /api/me endpoint")
- **Learning**: Root cause (e.g., "JWT secret mismatch between .env and config.py")
- **Ghost Context Cleanup**: What was retired/corrected (e.g., "Removed stale JWT_SECRET_KEY from .env.example")

## UPDATE ERROR LOG

Append new entry to `specs/$FEATURE/error-log.md`:

```markdown
### Entry N: YYYY-MM-DD - [Brief Title]

**Failure**: [What broke]
**Symptom**: [Observable behavior with error messages]
**Learning**: [Root cause and key insights]
**Ghost Context Cleanup**: [Retired artifacts, corrected assumptions, removed dead code]

[Optional: During T0NN task-name if applicable]
```

## GIT COMMIT

After error-log.md updated and fix applied:

```bash
git add specs/${FEATURE}/error-log.md
git add [fixed files]
git commit -m "fix: [brief description of fix]

Error: [what broke]
Root cause: [why it broke]
Fix: [what was changed]

Updated error-log.md with Entry N

Completed during: [task ID] (if applicable)

 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

## WORKFLOW EXAMPLES

### Example 1: Test Failure
```
User: "Test test_create_message is failing"

1. Load error-log.md (check for similar past failures)
2. Run pytest with verbose output to capture full error
3. Identify error type: Test failure (backend)
4. Route to spec-flow-debugger agent
5. Agent reproduces, identifies missing FK constraint
6. Agent applies fix, verifies tests pass
7. Update error-log.md:
   - Failure: "test_create_message raises IntegrityError"
   - Symptom: "FOREIGN KEY constraint failed on channel_id"
   - Learning: "Message model missing FK relationship to Channel"
   - Ghost Context: "Corrected data-model.md to include FK constraint"
8. Git commit fix + error-log update
```

### Example 2: UI Bug
```
User: "Button is not clickable on mobile"

1. Load error-log.md
2. Identify error type: UI bug (frontend)
3. Route to Chrome DevTools:
   - Resize page to mobile dimensions
   - Take snapshot
   - Inspect button element
   - Check CSS z-index and pointer-events
4. Identify issue: Overlay covering button
5. Apply fix: Adjust z-index in CSS
6. Update error-log.md:
   - Failure: "Button unresponsive on mobile viewport"
   - Symptom: "Clicks not registering below 768px width"
   - Learning: "Modal overlay z-index higher than button container"
   - Ghost Context: "Removed debug overlay from previous UI test"
7. Git commit fix + error-log update
```

### Example 3: Performance Regression
```
User: "Dashboard loading very slow after last merge"

1. Load error-log.md
2. Identify error type: Performance issue (frontend)
3. Route to Chrome DevTools performance:
   - Start trace with reload
   - Analyze LCP/CLS insights
   - Check network waterfall
4. Identify issue: Synchronous API calls, no code splitting
5. Route to spec-flow-debugger for code-level fix
6. Agent applies async/await, adds dynamic imports
7. Update error-log.md:
   - Failure: "Dashboard FCP >5s (target: <1.5s)"
   - Symptom: "Blocking API calls delayed render"
   - Learning: "Missing await on Promise.all, large bundle loaded eagerly"
   - Ghost Context: "Retired synchronous data fetching pattern"
8. Git commit fix + error-log update
```

## ERROR HANDLING

- **error-log.md missing**: Warn user, create from template before proceeding
- **Specialist agent unavailable**: Fall back to manual debugging, document findings in error-log
- **Agent timeout (>5min)**: Cancel agent, ask user for manual debugging or skip
- **Fix verification fails**: Document partial findings, mark as "in-progress" in error-log
- **No repro**: Document attempted steps in error-log with "Unable to reproduce" note

## CONSTRAINTS

- ALWAYS update error-log.md (even if fix unsuccessful)
- Include timestamps and task IDs when applicable
- Be specific about ghost context (file paths, variables)
- Commit error-log.md separately or with fix
- One debugging session per /debug invocation

## RETURN

Brief summary:

**Manual mode** (user-invoked):
-  Error: [brief description]
-  Root cause: [identified cause]
-  Fix: [what was changed] OR  In progress
-  error-log.md: Entry N added
-  Verification: [tests passing/failing]
-  Files changed: [list]
- Next: Continue with `/implement` or fix remaining issues

**Structured mode** (from /optimize --from-optimize):
-  Issue ID: [CR###]
-  Severity: [CRITICAL/HIGH/MEDIUM/LOW]
-  Category: [Contract/KISS/DRY/Security/etc]
-  Fix applied: [Yes/No]
-  Files changed: [list]
-  Verification: Lint [/], Types [/], Tests [/]
-  error-log.md: Entry N added (linked to issue ID)
-  Return to /optimize: [for next issue or completion]


