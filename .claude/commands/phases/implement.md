---
name: implement
description: Execute all implementation tasks from tasks.md with test-driven development, parallel batching, and atomic commits
argument-hint: [feature-slug]
allowed-tools:
  [
    Read,
    Write,
    Edit,
    Grep,
    Glob,
    Bash(python .spec-flow/scripts/spec-cli.py:*),
    Bash(git add:*),
    Bash(git commit:*),
    Bash(git diff:*),
    Bash(git status:*),
    Bash(npm test:*),
    Bash(pnpm test:*),
    Bash(pytest:*),
  ]
---

# /implement — Task Execution with TDD

<context>
**User Input**: $ARGUMENTS

**Workflow Detection**: Auto-detected via workspace files, branch pattern, or state.yaml

**Current Branch**: !`git branch --show-current 2>$null || echo "none"`

**Feature Directory**: !`python .spec-flow/scripts/spec-cli.py check-prereqs --json --paths-only 2>$null | jq -r '.FEATURE_DIR'`

**Pending Tasks**: Auto-detected from ${BASE_DIR}/\*/tasks.md

**Completed Tasks**: Auto-detected from ${BASE_DIR}/\*/tasks.md

**Git Status**: !`git status --short 2>$null || echo "clean"`

**Mockup Approval Status** (if UI-first): Auto-detected from ${BASE_DIR}/\*/state.yaml

**Implementation Artifacts** (after script execution):

- @${BASE_DIR}/\*/tasks.md (updated with completed tasks)
- @${BASE_DIR}/\*/CLAUDE.md (living documentation)
- @design/systems/ui-inventory.md (if UI components created)
- @design/systems/approved-patterns.md (if patterns extracted)
  </context>

<objective>
Execute all tasks from ${BASE_DIR}/$ARGUMENTS/tasks.md with parallel batching, strict TDD phases, auto-rollback on failure, and atomic commits.

Implementation workflow:

1. Parse and group tasks from tasks.md by domain and TDD phase
2. Execute tasks directly using specialist agents (backend-dev, frontend-dev, etc.)
3. Track completion via tasks.md checkbox and NOTES.md updates
4. Update living documentation (UI inventory, approved patterns)
5. Run full test suite verification
6. Present results with next action recommendation

**Key principles**:

- **Test-Driven Development**: Red (failing test) → Green (passing) → Refactor (improve)
- **Parallel execution**: Group independent tasks by domain, speedup bounded by dependencies
- **Anti-duplication**: Use mgrep for semantic search before creating new implementations
- **Pattern following**: Apply plan.md recommended patterns consistently
- **Atomic commits**: One commit per task with descriptive message

**Workflow position**: `spec → clarify → plan → tasks → implement → optimize → preview → ship`
</objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent implementation errors.

1. **Never speculate about code you have not read**

   - Always Read files before referencing them
   - Verify file existence with Glob before importing

2. **Cite your sources with file paths**

   - Include exact location: `file_path:line_number`
   - Quote code snippets when analyzing

3. **Admit uncertainty explicitly**

   - Say "I'm uncertain about [X]. Let me investigate by reading [file]" instead of guessing
   - Use Grep to find existing import patterns before assuming

4. **Quote before analyzing long documents**

   - For specs >5000 tokens, extract relevant quotes first
   - Don't paraphrase - show verbatim text with line numbers

5. **Verify file existence before importing/referencing**
   - Use Glob to find files: `**/*.ts`, `**/*.tsx`
   - Use Grep to find existing patterns: `import.*Component`

6. **Anti-duplication with semantic search**
   - Use mgrep FIRST to find similar implementations by meaning
   - Example: `mgrep "components that display user profiles"` finds ProfileCard, UserView, AccountInfo
   - Only create new code if no suitable existing code is found

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

**Use for**: Choosing implementation approaches, reuse decisions, debugging multi-step failures, prioritizing task order.

---

## Workflow Tracking

Use TodoWrite to track batch **group** execution progress (parallel execution model).

**Initialize todos** (dynamically based on number of batch groups):

```javascript
// Calculate groups: Math.ceil(batches.length / 3)
// Example with 9 batches → 3 groups of 3

TodoWrite({
  todos: [
    {
      content: "Validate preflight checks",
      status: "completed",
      activeForm: "Preflight",
    },
    {
      content: "Parse tasks and detect batches",
      status: "completed",
      activeForm: "Parsing tasks",
    },
    {
      content: "Execute batch group 1 (tasks 1-3)",
      status: "in_progress",
      activeForm: "Executing batch group 1",
    },
    {
      content: "Execute batch group 2 (tasks 4-6)",
      status: "pending",
      activeForm: "Executing batch group 2",
    },
    {
      content: "Execute batch group 3 (tasks 7-9)",
      status: "pending",
      activeForm: "Executing batch group 3",
    },
    {
      content: "Run full test suite and commit",
      status: "pending",
      activeForm: "Wrapping up",
    },
  ],
});
```

**Update after each batch group completes** (mark completed, move in_progress forward).

---

<process>

### Step 0: WORKFLOW TYPE DETECTION

**Detect whether this is an epic or feature workflow:**

```bash
# Run detection utility (cross-platform)
if command -v bash >/dev/null 2>&1; then
    WORKFLOW_INFO=$(bash .spec-flow/scripts/utils/detect-workflow-paths.sh 2>/dev/null)
    DETECTION_EXIT=$?
else
    WORKFLOW_INFO=$(pwsh -File .spec-flow/scripts/utils/detect-workflow-paths.ps1 2>/dev/null)
    DETECTION_EXIT=$?
fi

# Parse detection result
if [ $DETECTION_EXIT -eq 0 ]; then
    WORKFLOW_TYPE=$(echo "$WORKFLOW_INFO" | jq -r '.type')
    BASE_DIR=$(echo "$WORKFLOW_INFO" | jq -r '.base_dir')
    SLUG=$(echo "$WORKFLOW_INFO" | jq -r '.slug')

    echo "✓ Detected $WORKFLOW_TYPE workflow"
    echo "  Base directory: $BASE_DIR/$SLUG"

    # Set file paths
    TASKS_FILE="${BASE_DIR}/${SLUG}/tasks.md"
    CLAUDE_MD="${BASE_DIR}/${SLUG}/CLAUDE.md"
    WORKFLOW_STATE="${BASE_DIR}/${SLUG}/state.yaml"
else
    echo "⚠ Could not auto-detect workflow type - using fallback"
fi
```

---

### Step 0.5: ITERATION DETECTION (v3.0 - Feedback Loop Support)

**NEW**: Check if workflow is in iteration mode and filter tasks accordingly.

```bash
# Read workflow state to check iteration
if [ -f "$WORKFLOW_STATE" ]; then
    CURRENT_ITERATION=$(yq eval '.iteration.current' "$WORKFLOW_STATE" 2>/dev/null || echo "1")
    MAX_ITERATIONS=$(yq eval '.iteration.max_iterations' "$WORKFLOW_STATE" 2>/dev/null || echo "3")

    if [ "$CURRENT_ITERATION" -gt 1 ]; then
        echo "🔄 Iteration Mode Detected"
        echo "  Current iteration: $CURRENT_ITERATION / $MAX_ITERATIONS"
        echo "  Executing supplemental tasks only (iteration $CURRENT_ITERATION)"

        # Check iteration limit
        if [ "$CURRENT_ITERATION" -gt "$MAX_ITERATIONS" ]; then
            echo "❌ ERROR: Iteration limit exceeded ($MAX_ITERATIONS)"
            echo ""
            echo "This workflow has reached the maximum allowed iterations."
            echo "Remaining gaps should be addressed in a new epic/feature."
            echo ""
            echo "To prevent scope creep and infinite iteration, the limit is enforced."
            exit 1
        fi

        # Set iteration flag for task filtering
        ITERATION_MODE=true
        ITERATION_NUMBER=$CURRENT_ITERATION
    else
        echo "  Iteration: 1 (initial implementation)"
        ITERATION_MODE=false
        ITERATION_NUMBER=1
    fi
else
    # No workflow state file - default to iteration 1
    ITERATION_MODE=false
    ITERATION_NUMBER=1
fi
```

**Task filtering logic:**

When `ITERATION_MODE=true`, the implementation script should:

1. Parse tasks.md for the current iteration section (e.g., "## Iteration 2: Gap Closure")
2. Execute only tasks marked with `**Iteration**: $ITERATION_NUMBER`
3. Skip all tasks from previous iterations
4. Update workflow state after completion:
   - Increment `iteration.total_iterations`
   - Add entry to `iteration.history`
   - Mark supplemental task batch as completed

**Example filtered task execution:**

```markdown
# tasks.md structure

### T001: Original task from iteration 1

**Iteration**: 1
**Status**: ✅ Completed

---

## Iteration 2: Gap Closure

### T031: Implement /v1/auth/me endpoint

**Iteration**: 2
**Status**: Pending
← This task WILL execute

### T032: Add tests for /v1/auth/me

**Iteration**: 2
**Status**: Pending
← This task WILL execute
```

**Performance benefit:**

- Iteration 2 with 3 tasks: ~10-30 minutes (vs full re-implementation: 2-4 hours)
- Targeted execution reduces context switching and test suite runtime
- Atomic iteration commits preserve ability to rollback to iteration 1

---

### Step 0.55: LOAD USER PREFERENCES

**Load user preferences that affect implementation behavior:**

```bash
# Load preference utility functions
source .spec-flow/scripts/utils/load-preferences.sh 2>/dev/null || true

# Load migration preferences
MIGRATION_STRICTNESS=$(get_preference_value --key "migrations.strictness" --default "blocking")
MIGRATION_AUTO_PLAN=$(get_preference_value --key "migrations.auto_generate_plan" --default "true")

# Load automation preferences
AUTO_APPROVE_MINOR=$(get_preference_value --key "automation.auto_approve_minor_changes" --default "false")
CI_MODE=$(get_preference_value --key "automation.ci_mode_default" --default "false")

# Load learning preferences
LEARNING_ENABLED=$(get_preference_value --key "learning.enabled" --default "true")
AUTO_APPLY_LOW_RISK=$(get_preference_value --key "learning.auto_apply_low_risk" --default "true")

echo "User Preferences Loaded:"
echo "  Migration Strictness: $MIGRATION_STRICTNESS"
echo "  Auto-approve Minor: $AUTO_APPROVE_MINOR"
echo "  CI Mode: $CI_MODE"
echo "  Learning: $( [ "$LEARNING_ENABLED" = "true" ] && echo "enabled" || echo "disabled" )"
```

**Preferences affecting implementation:**

| Preference | Phase | Effect |
|------------|-------|--------|
| `migrations.strictness` | Step 0.6 | blocking/warning/auto_apply |
| `automation.auto_approve_minor` | Commit | Skip review for formatting |
| `automation.ci_mode_default` | All steps | Non-interactive mode |
| `learning.enabled` | Pattern detection | Track successful patterns |

---

### Step 0.6: MIGRATION ENFORCEMENT (v10.5 - Migration Safety)

**Pre-flight check**: Block tests if migrations not applied.

```bash
# Check if feature requires migrations
HAS_MIGRATIONS=$(yq eval '.has_migrations // false' "$WORKFLOW_STATE" 2>/dev/null || echo "false")

if [ "$HAS_MIGRATIONS" = "true" ]; then
    echo "🗄️  Migration check required (feature has schema changes)"

    # Run migration status detection
    MIGRATION_STATUS=$(bash .spec-flow/scripts/bash/check-migration-status.sh --json 2>/dev/null)
    MIGRATION_EXIT=$?

    if [ $MIGRATION_EXIT -eq 0 ]; then
        PENDING=$(echo "$MIGRATION_STATUS" | jq -r '.pending')
        PENDING_COUNT=$(echo "$MIGRATION_STATUS" | jq -r '.pending_count')
        TOOL=$(echo "$MIGRATION_STATUS" | jq -r '.tool')
        APPLY_CMD=$(echo "$MIGRATION_STATUS" | jq -r '.apply_command')

        if [ "$PENDING" = "true" ]; then
            # Use loaded preference (from Step 0.55) or fallback to yq
            if [ -z "$MIGRATION_STRICTNESS" ]; then
                MIGRATION_STRICTNESS=$(yq eval '.migrations.strictness // "blocking"' .spec-flow/config/user-preferences.yaml 2>/dev/null || echo "blocking")
            fi

            case "$MIGRATION_STRICTNESS" in
                blocking)
                    echo "❌ BLOCKING: $PENDING_COUNT pending $TOOL migrations detected"
                    echo ""
                    echo "Tests will fail without applied migrations. You must:"
                    echo "  1. Apply migrations: $APPLY_CMD"
                    echo "  2. Re-run /implement after migrations applied"
                    echo ""
                    echo "To change this behavior, update .spec-flow/config/user-preferences.yaml:"
                    echo "  migrations:"
                    echo "    strictness: warning  # or auto_apply"
                    exit 1
                    ;;
                warning)
                    echo "⚠️  WARNING: $PENDING_COUNT pending $TOOL migrations detected"
                    echo "  Apply before running tests: $APPLY_CMD"
                    echo "  Continuing anyway (strictness: warning)"
                    ;;
                auto_apply)
                    echo "🔄 AUTO-APPLY: Applying $PENDING_COUNT $TOOL migrations"
                    eval "$APPLY_CMD"
                    if [ $? -ne 0 ]; then
                        echo "❌ Migration auto-apply failed. Manual intervention required."
                        exit 1
                    fi
                    echo "✅ Migrations applied successfully"
                    ;;
            esac
        else
            echo "✅ Migrations up-to-date ($TOOL)"
        fi
    elif [ $MIGRATION_EXIT -eq 2 ]; then
        echo "⚠️  No migration tool detected - skipping migration check"
    else
        echo "⚠️  Migration check failed - continuing anyway"
    fi
else
    echo "   No migrations required for this feature"
fi
```

**Strictness levels** (configured via user-preferences.yaml):

| Level | Behavior | Use Case |
|-------|----------|----------|
| `blocking` | Exit with error, provide apply command | Default, safest |
| `warning` | Log warning, continue execution | Experienced devs |
| `auto_apply` | Run migrations automatically | CI/CD pipelines |

**Why block before implementation?**

- Tests will fail against outdated schema (confusing errors)
- ORM models reference non-existent columns
- 40% of implementation failures trace to missing migrations
- Early failure saves debugging time

**Configuration** (`.spec-flow/config/user-preferences.yaml`):

```yaml
migrations:
  # How to handle pending migrations
  # blocking (default): Stop and require manual apply
  # warning: Log warning, continue
  # auto_apply: Automatically run migrations
  strictness: blocking

  # Detection sensitivity (keyword score threshold)
  detection_threshold: 3

  # Generate migration-plan.md during /plan
  auto_generate_plan: true
```

---

### Step 0.7: MOCKUP COMPONENT EXTRACTION (UI-First Only)

**Pre-condition**: Only execute if mockups exist and are approved (UI-first features).

```bash
# Check if this is a UI-first feature with approved mockups
UI_FIRST_MODE=$(yq eval '.ui_first // false' "$WORKFLOW_STATE" 2>/dev/null || echo "false")
MOCKUP_APPROVED=$(yq eval '.manual_gates.mockup_approval.status' "$WORKFLOW_STATE" 2>/dev/null || echo "pending")

if [ "$UI_FIRST_MODE" = "true" ] && [ "$MOCKUP_APPROVED" = "approved" ]; then
    echo "🎨 Mockup Component Extraction"
    echo "  Mode: UI-first with approved mockups"

    # Locate mockup files
    MOCKUP_DIR="${BASE_DIR}/${SLUG}/mockups"
    PROTOTYPE_DIR="design/prototype/screens"

    if [ -d "$MOCKUP_DIR" ]; then
        MOCKUP_SOURCE="$MOCKUP_DIR"
    elif [ -d "$PROTOTYPE_DIR" ]; then
        MOCKUP_SOURCE="$PROTOTYPE_DIR"
    else
        echo "⚠️  No mockup directory found - skipping extraction"
        MOCKUP_SOURCE=""
    fi

    if [ -n "$MOCKUP_SOURCE" ]; then
        echo "  Source: $MOCKUP_SOURCE"

        # Invoke mockup-extraction skill
        echo ""
        echo "Extracting component patterns from mockups..."
        echo "  ├── Identifying repeated components"
        echo "  ├── Mapping CSS to Tailwind utilities"
        echo "  ├── Documenting variants and states"
        echo "  └── Populating prototype-patterns.md"

        # Load mockup-extraction skill guidance
        # Skill: .claude/skills/mockup-extraction/SKILL.md

        # Generate prototype-patterns.md
        PATTERNS_FILE="${BASE_DIR}/${SLUG}/prototype-patterns.md"

        # Extraction output includes:
        # 1. Component inventory with occurrence counts
        # 2. CSS to Tailwind mapping table
        # 3. Component details (structure, classes, props)
        # 4. Visual fidelity checklist

        echo ""
        echo "✅ Component extraction complete"
        echo "  Output: $PATTERNS_FILE"
        echo "  Load patterns into context for implementation"
    fi
else
    if [ "$UI_FIRST_MODE" = "true" ]; then
        echo "⏸️  Mockup extraction skipped (mockups not yet approved)"
    else
        echo "   Not a UI-first feature - skipping mockup extraction"
    fi
fi
```

**Extraction workflow** (guided by mockup-extraction skill):

1. **Inventory mockup files**: List all HTML files in mockup directory
2. **Parse for components**: Identify buttons, cards, forms, alerts, navigation, etc.
3. **Count occurrences**: Track how many times each component appears across screens
4. **Score reusability**: 1 occurrence = inline OK, 2 = consider extraction, 3+ = must extract
5. **Map CSS to Tailwind**: Convert theme CSS variables to Tailwind utilities
6. **Document props**: Define TypeScript interfaces for each component
7. **List states**: Document all interactive states (hover, focus, disabled, loading)
8. **Generate prototype-patterns.md**: Output extraction results for implementation reference

**Why extraction matters**:
- Prevents 40-60% of visual fidelity issues
- Provides consistent component props across screens
- Maps mockup styling directly to production Tailwind classes
- Creates component inventory for tasks.md extraction tasks

---

### Step 0.8: DOMAIN MEMORY WORKER PATTERN (v11.0)

**NEW**: If domain-memory.yaml exists, use Worker pattern for isolated task execution.

```bash
DOMAIN_MEMORY_FILE="${BASE_DIR}/${SLUG}/domain-memory.yaml"

if [ -f "$DOMAIN_MEMORY_FILE" ]; then
    echo ""
    echo "🧠 Domain Memory Pattern Active"
    echo "   Using isolated Workers for atomic task execution"
    echo ""

    # Get current status
    .spec-flow/scripts/bash/domain-memory.sh status "${BASE_DIR}/${SLUG}"
fi
```

**Worker Loop Orchestration:**

When domain-memory.yaml exists, the orchestrator spawns isolated Workers instead of batching tasks:

```javascript
// Read domain memory to check for remaining work
const memoryFile = `${FEATURE_DIR}/domain-memory.yaml`;
let remaining = getUntestedOrFailingFeatures(memoryFile);

console.log(`📋 Features remaining: ${remaining.length}`);

while (remaining.length > 0) {
  console.log(`\n${"─".repeat(60)}`);
  console.log(`🔧 Spawning Worker for next feature...`);
  console.log(`${"─".repeat(60)}\n`);

  // Spawn isolated Worker via Task tool
  // CRITICAL: Each Worker gets fresh context, no memory of previous runs
  const workerResult = await Task({
    subagent_type: "worker",  // Uses .claude/agents/domain/worker.md
    prompt: `
      Execute ONE feature from domain memory:

      Feature directory: ${FEATURE_DIR}
      Domain memory: ${memoryFile}

      Boot-up ritual:
      1. READ domain-memory.yaml from disk
      2. RUN baseline tests (verify no regressions)
      3. PICK one failing/untested feature (highest priority)
      4. LOCK the feature
      5. IMPLEMENT that ONE feature
      6. RUN tests
      7. UPDATE domain-memory.yaml status
      8. COMMIT changes
      9. EXIT (even if more work remains)

      CRITICAL: Work on exactly ONE feature, then EXIT.
    `
  });

  // Worker has exited - read updated state from disk
  console.log(`\n✅ Worker completed: ${workerResult.status}`);
  console.log(`   Feature: ${workerResult.feature_id}`);
  console.log(`   Tests: ${workerResult.tests_passed ? "PASSED" : "FAILED"}`);

  // Re-read domain memory to get updated state
  remaining = getUntestedOrFailingFeatures(memoryFile);
  console.log(`   Remaining features: ${remaining.length}`);

  // If Worker failed, check if we should continue
  if (workerResult.status === "failed") {
    const feature = workerResult.feature_id;
    const attempts = getAttemptCount(memoryFile, feature);

    if (attempts >= 3) {
      console.log(`\n⚠️  Feature ${feature} failed 3 times - marking as blocked`);
      // Update status to blocked, continue with other features
    }
  }
}

console.log(`\n${"═".repeat(60)}`);
console.log(`✅ All features completed!`);
console.log(`${"═".repeat(60)}\n`);
```

**Key Behaviors:**

1. **Orchestrator is lightweight**: Only reads disk, spawns Task(), checks completion
2. **Workers are isolated**: Fresh context each spawn, no memory of previous Workers
3. **Disk is source of truth**: domain-memory.yaml is the only shared state
4. **One task per Worker**: Strict atomic progress, observable after each task
5. **Automatic retry**: Failed features get retried up to 3 times before blocking

**Fallback to Batch Mode:**

If domain-memory.yaml doesn't exist, fall back to traditional batch execution (Step 1 below).

```bash
if [ ! -f "$DOMAIN_MEMORY_FILE" ]; then
    echo "   Domain memory not found - using batch mode"
    echo "   (Generate with: .spec-flow/scripts/bash/domain-memory.sh generate-from-tasks ${BASE_DIR}/${SLUG})"
fi
```

---

### Step 1: PARSE AND GROUP TASKS (MANDATORY)

**You MUST execute tasks directly. Do not wait for scripts.**

#### 1.1 Read Pending Tasks

Read `${BASE_DIR}/${SLUG}/tasks.md` and extract all pending tasks:
- Tasks with `- [ ]` checkbox are pending
- Tasks with `- [x]` checkbox are complete

#### 1.2 Group Tasks by Domain

Categorize each task by domain for specialist routing:

| Pattern in Task | Domain | Specialist Agent |
|-----------------|--------|------------------|
| `api/`, `backend`, `.py`, `endpoint`, `service` | backend | backend-dev |
| `apps/`, `frontend`, `.tsx`, `.jsx`, `component`, `page` | frontend | frontend-dev |
| `migration`, `schema`, `alembic`, `prisma`, `sql` | database | database-architect |
| `test.`, `.test.`, `.spec.`, `tests/` | tests | qa-tester |
| Other | general | general-purpose |

#### 1.3 Group Tasks by TDD Phase

Tasks with phase markers execute sequentially:
- `[RED]` - Write failing test first
- `[GREEN]` - Implement to pass test
- `[REFACTOR]` - Clean up while keeping tests green

Tasks without phase markers can execute in parallel (if different files).

#### 1.4 Create Batch Groups

Group tasks for parallel execution:
- Max 3-4 tasks per batch (clarity over speed)
- Same domain tasks in same batch
- TDD phases run as single-task batches (sequential)

---

### Step 1.5: EXECUTE TASK BATCHES (MANDATORY)

**For each batch group, execute tasks using specialist agents.**

#### 1.5.1 TDD Task Execution

For tasks marked `[RED]`, `[GREEN]`, or `[REFACTOR]`:

**RED Phase:**
1. Write the failing test
2. Run test - MUST fail (for the right reason)
3. If test passes → something is wrong, investigate
4. Commit: `test(red): TXXX write failing test for {behavior}`

**GREEN Phase:**
1. Implement minimal code to pass the test
2. Run test - MUST pass
3. If test fails → fix implementation
4. Commit: `feat(green): TXXX implement {component}`

**REFACTOR Phase:**
1. Clean up code (DRY, KISS principles)
2. Run tests - MUST stay green
3. If tests break → revert, try simpler refactor
4. Commit: `refactor: TXXX clean up {component}`

#### 1.5.2 General Task Execution

For tasks without TDD markers:

1. Read task requirements and REUSE markers
2. Check referenced files exist (use Read tool)
3. Implement the task
4. Run relevant tests
5. Commit: `feat(TXXX): {summary}`

#### 1.5.3 Specialist Agent Invocation

For complex tasks, adopt the appropriate specialist persona:

1.  **Read the Agent Definition**:
    *   Backend: `.claude/agents/implementation/backend.md`
    *   Frontend: `.claude/agents/implementation/frontend.md`
    *   Database: `.claude/agents/implementation/database-architect.md`
    *   QA: `.claude/agents/quality/qa-tester.md`

2.  **Adopt Persona & Execute**:
    *   Follow the agent's `<workflow>` and `<constraints>` strictly.
    *   Execute the task using your available tools (`Read`, `Write`, `Bash`, etc.).
    *   Run tests to verify.

3.  **Return Results**:
    *   Files changed
    *   Test results
    *   Coverage

---

### Step 1.6: TASK COMPLETION TRACKING (MANDATORY)

**After EACH task completes successfully:**

#### 1.6.1 Update tasks.md Checkbox

Use Edit tool to change:
```markdown
- [ ] TXXX ...
```
to:
```markdown
- [x] TXXX ...
```

#### 1.6.2 Append to NOTES.md

Use Edit tool to append:
```markdown
✅ TXXX: {task title} - {duration}min ({timestamp})
   Evidence: {test results, e.g., "pytest: 25/25 passing"}
   Coverage: {percentage, e.g., "92% line, 88% branch"}
```

#### 1.6.3 Commit the Task

```bash
git add .
git commit -m "feat(TXXX): {summary}

Tests: {pass_count}/{total_count} passing
Coverage: {percentage}%

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

#### 1.6.4 On Task Failure

If a task fails (tests don't pass, error occurs):

1. **Log to error-log.md**:
```markdown
## ❌ TXXX - {timestamp}

**Error:** {detailed error message}
**Stack Trace:** {if applicable}
**Status:** Needs retry or investigation
```

2. **Rollback changes**: `git restore .`
3. **Do NOT update tasks.md checkbox**
4. **Continue to next task**

---

### Step 1.7: RUN CONTINUOUS QUALITY CHECKS (NEW - v10.16)

**After each batch group of 3-4 tasks completes**, run lightweight quality checks:

#### 1.7.1 When to Run

Run continuous checks when:
- A batch group (3-4 tasks) has been completed
- At least one task involved code changes
- NOT in iteration 2+ (gaps should be small, focus on completion)

Skip continuous checks when:
- Batch has < 3 tasks
- No code changes (documentation-only tasks)
- Iteration ≥ 2 (quality gates already ran in iteration 1)
- User passes `--no-checks` flag to /implement

#### 1.7.2 Execute Continuous Checks

```bash
# Run continuous checks for current batch
bash .spec-flow/scripts/bash/continuous-checks.sh \
  --batch-num $BATCH_NUM \
  --feature-dir "$FEATURE_DIR"
```

**Exit codes:**
- `0`: All checks passed, continue to next batch
- `1`: Some checks failed, user decision required
- `2`: Timeout exceeded (> 30s), consider reducing scope

#### 1.7.3 Checks Performed

The continuous-checks.sh script runs 5 lightweight checks:

1. **Linting** (auto-fix enabled)
   - ESLint, Prettier for frontend
   - Ruff, Black for backend
   - Auto-fixes applied, committed if successful

2. **Type Checking** (quick mode)
   - TypeScript: `tsc --noEmit --incremental`
   - Python: `mypy --incremental`
   - Changed files only

3. **Unit Tests** (related tests only)
   - Frontend: `pnpm test --findRelatedTests`
   - Backend: `pytest` on related test files
   - Fast feedback on new code

4. **Coverage Delta**
   - Check if coverage dropped since last batch
   - Baseline stored in `.baseline-coverage`
   - Warn if coverage decreased

5. **Dead Code Detection**
   - Detect new unused exports (TypeScript)
   - Flag potential cleanup opportunities
   - Non-blocking, warning only

#### 1.7.4 Handling Failures

If continuous checks fail:

**Option 1: Fix now and continue (recommended)**
```bash
# Review failures in batch log
cat .continuous-checks/batch-${BATCH_NUM}.log

# Fix the issues
# ... make corrections ...

# Commit fixes
git add .
git commit -m "fix: address continuous check failures from batch $BATCH_NUM"

# Re-run continuous checks
bash .spec-flow/scripts/bash/continuous-checks.sh --batch-num $BATCH_NUM --feature-dir "$FEATURE_DIR"
```

**Option 2: Continue anyway** (not recommended)
- Use for minor issues that don't block progress
- Issues will be caught again in /optimize
- Add TODO comments for tracking

**Option 3: Abort batch**
- For critical failures (build breaks, tests won't run)
- Rollback last task: `git reset --hard HEAD~1`
- Fix the blocking issue
- Resume /implement

#### 1.7.5 Performance Target

Continuous checks should complete in < 30 seconds:
- Linting + auto-fix: ~5-8s
- Type checking (incremental): ~5-10s
- Unit tests (related only): ~8-12s
- Coverage + dead code: ~2-5s

If checks exceed 30s, consider:
- Reducing batch size (2-3 tasks instead of 3-4)
- Skipping dead code detection (lowest value)
- Running some checks only in /optimize

#### 1.7.6 Continuous vs Full Quality Gates

**Continuous (after each batch)**:
- Fast (< 30s)
- Incremental (changed files only)
- Auto-fix enabled
- Warning-based (mostly non-blocking)
- Purpose: Catch issues early

**Full Quality Gates (/optimize phase)**:
- Comprehensive (10-15 min)
- Full codebase scan
- No auto-fix
- Blocking failures
- Purpose: Production-readiness validation

---

### Step 1.8: TDD WORKFLOW REFERENCE

**Strict TDD sequence per task:**

```
┌─────────────────────────────────────────────┐
│  RED: Write Failing Test                     │
│  ├── Create test file if needed              │
│  ├── Write test for expected behavior        │
│  ├── Run test → MUST FAIL                    │
│  └── Commit: test(red): TXXX                 │
├─────────────────────────────────────────────┤
│  GREEN: Make Test Pass                       │
│  ├── Write minimal implementation            │
│  ├── Run test → MUST PASS                    │
│  ├── Don't over-engineer                     │
│  └── Commit: feat(green): TXXX               │
├─────────────────────────────────────────────┤
│  REFACTOR: Clean Up                          │
│  ├── Remove duplication                      │
│  ├── Improve naming                          │
│  ├── Run tests → MUST STAY GREEN             │
│  └── Commit: refactor: TXXX                  │
└─────────────────────────────────────────────┘
```

### Step 2: Review Implementation Progress

**Check task completion:**

- Read updated tasks.md to see completed tasks
- Verify all tasks marked as completed (✅)
- Check for any blocked or failed tasks

**Review generated code:**

- Scan created/modified files
- Verify pattern consistency with plan.md
- Check for code duplication

### Step 3: Update Living Documentation

**When UI components were created during implementation:**

#### a) Update ui-inventory.md

**For each new reusable component created in `components/ui/`:**

1. **Scan for new component files:**

   ```bash
   git diff HEAD~1 --name-only | grep "components/ui/"
   ```

2. **Document each component** in `design/systems/ui-inventory.md`:

   ````markdown
   ### {ComponentName}

   **Source**: {file_path}
   **Type**: {shadcn/ui primitive | custom component}
   **Props**: {key props with types}
   **States**: {default, hover, focus, disabled, loading, error}
   **Accessibility**: {ARIA labels, keyboard navigation features}
   **Usage**:

   ```tsx
   import { {ComponentName} } from '@/components/ui/{component-name}'

   <{ComponentName} {prop}="{value}" />
   ```
   ````

   **Examples**:

   - {Usage in current feature}: {file_path}:{line}

   **Related Components**: {List related components}

   ```

   ```

3. **Commit documentation update:**

   ```bash
   git add design/systems/ui-inventory.md
   git commit -m "docs: add {ComponentName} to ui-inventory

   Component: {ComponentName} ({type})
   Features: {brief feature list}
   Location: {file_path}"
   ```

**Skip if:**

- Component is feature-specific (in app/ not components/ui/)
- Component is a one-off layout wrapper
- Component already documented in inventory

#### b) Extract Approved Patterns

**If mockups were approved and converted to production code:**

1. **Identify reusable layout patterns** (used in 2+ screens):

   - Form layouts
   - Navigation structures
   - Data display patterns (tables, cards, lists)
   - Modal/dialog patterns

2. **Document pattern** in `design/systems/approved-patterns.md`:

   ````markdown
   ## Pattern: {Pattern Name}

   **Used in**: {feature-001, feature-003} ({N} features)
   **Category**: {Form | Navigation | Data Display | Modal}

   ### Structure

   ```html
   {Simplified HTML structure showing pattern}
   ```
   ````

   ### Design Tokens

   - **Spacing**: {tokens used}
   - **Colors**: {tokens used}
   - **Typography**: {tokens used}

   ### When to Use

   {Description of appropriate use cases}

   ### Examples

   - {Feature name}: `{file_path}:{line}`
   - {Feature name}: `{file_path}:{line}`

   ### Accessibility

   - {Key accessibility features}
   - {Keyboard navigation support}
   - {ARIA attributes used}

   ```

   ```

3. **Commit pattern documentation:**

   ```bash
   git add design/systems/approved-patterns.md
   git commit -m "docs: extract {PatternName} approved pattern

   Pattern: {Pattern Name}
   Used in: {N} features
   Category: {category}"
   ```

**Extract patterns proactively:**

- Don't wait for duplication to occur
- Document patterns immediately after approval
- Include real code examples from the feature

#### c) Update Feature CLAUDE.md

**Trigger living documentation update for the feature:**

```bash
cat >> specs/{NNN-slug}/CLAUDE.md <<EOF

## Implementation Progress ($(date +%Y-%m-%d))

**Last 3 Tasks Completed**:
- {T###}: {task title} ({timestamp})
- {T###}: {task title} ({timestamp})
- {T###}: {task title} ({timestamp})

**Velocity**:
- Tasks completed: {completed} / {total} ({percent}%)
- Average time: {avg} min/task
- ETA: {estimated completion date}

**New Components Created**:
- {ComponentName} (components/ui/{file})
- {ComponentName} (components/ui/{file})

**Patterns Extracted**:
- {Pattern Name} (approved-patterns.md)

**Next Phase**: /optimize
EOF

git add specs/{NNN-slug}/CLAUDE.md
git commit -m "docs: update feature CLAUDE.md with implementation progress"
```

**Target metrics after implementation:**

- ui-inventory.md: <24 hours lag
- approved-patterns.md: Documented if pattern reused
- Feature CLAUDE.md: Updated with last 3 tasks
- Health score: ≥90%

### Step 4: Run Full Test Suite

**Execute test suite:**

```bash
# Backend tests
cd api && pytest

# Frontend tests
cd apps/app && pnpm test

# Integration tests
pnpm test:e2e
```

**Verify:**

- All tests passing
- No regressions introduced
- Code coverage maintained/improved

### Step 5: Present Results to User

**Summary format:**

```
Implementation Complete

Feature: {slug}
Tasks completed: {completed} / {total}
Test suite: {PASS|FAIL}

Code changes:
  Files created: {count}
  Files modified: {count}
  Lines added: {count}
  Lines removed: {count}

Commits:
  {List recent commits with hash and message}

Next: /optimize (recommended)
```

### Step 6: Suggest Next Action

**If all tests pass:**

```
✅ Implementation complete! All tests passing.

Recommended next steps:
  1. /optimize - Production readiness validation (performance, security, accessibility)
  2. /preview - Manual UI/UX testing before shipping
```

**If tests fail:**

```
❌ Test suite failing

Failed tests:
  {List failed tests}

Next: /debug to investigate and fix failures
```

**If tasks blocked:**

```
⚠️  {count} tasks blocked

Blocked tasks:
  {List blocked tasks with reason}

Resolution:
  1. Fix blockers (missing files, dependencies)
  2. Re-run /implement to continue
```

</process>

<success_criteria>
**Implementation successfully completed when:**

1. **All tasks completed**:

   - tasks.md shows all tasks marked with ✅
   - No blocked or failed tasks remaining
   - Each task has atomic git commit

2. **Full test suite passing**:

   - Backend tests: 100% passing
   - Frontend tests: 100% passing
   - Integration tests: 100% passing
   - Code coverage maintained or improved

3. **Living documentation updated**:

   - ui-inventory.md: New UI components documented (if applicable)
   - approved-patterns.md: Reusable patterns extracted (if applicable)
   - Feature CLAUDE.md: Implementation progress recorded

4. **Code quality verified**:

   - No code duplication (anti-duplication checks passed)
   - Patterns from plan.md applied consistently
   - All files follow project conventions

5. **Git commits clean**:

   - Atomic commits per task with descriptive messages
   - Final implementation summary commit
   - No uncommitted changes or conflicts

6. **Workflow state updated**:
   - state.yaml marks implementation phase complete
   - Next phase identified (/optimize recommended)
     </success_criteria>

<verification>
**Before marking implementation complete, verify:**

1. **Read tasks.md**:

   ```bash
   grep -E "^\- \[(x| )\]" specs/*/tasks.md
   ```

   All tasks should show ✅ (completed)

2. **Check test suite status**:

   ```bash
   # Run full test suite
   pnpm test && pytest
   ```

   Should show 100% passing

3. **Verify git commits**:

   ```bash
   git log --oneline -10
   ```

   Should show atomic commits per task + final summary

4. **Validate living documentation**:

   ```bash
   # Check UI inventory updated
   git diff HEAD~5 design/systems/ui-inventory.md

   # Check feature CLAUDE.md updated
   tail -20 specs/*/CLAUDE.md
   ```

5. **Check for uncommitted changes**:

   ```bash
   git status
   ```

   Should show clean working tree

6. **Verify no code duplication**:
   ```bash
   # Run duplication scanner if available
   .spec-flow/scripts/bash/detect-duplication.sh
   ```

**Never claim completion without reading tasks.md and verifying test suite.**
</verification>

<output>
**Files created/modified by this command:**

**Implementation code** (varies by feature):

- Source files (components, hooks, utils, services)
- Test files (unit, integration, e2e)
- Type definitions (if TypeScript)
- API routes/endpoints (if backend)

**Task tracking** (specs/NNN-slug/):

- tasks.md — All tasks marked as completed
- CLAUDE.md — Updated with implementation progress

**Living documentation** (design/systems/):

- ui-inventory.md — New UI components documented (if created)
- approved-patterns.md — Reusable patterns extracted (if applicable)

**Git commits**:

- Multiple atomic commits (one per task)
- Final implementation summary commit
- Documentation update commits

**Console output**:

- Implementation progress summary
- Test suite results
- Next action recommendation (/optimize or /debug)
  </output>

---

## Quick Reference

### Parallel Execution

**Batch groups:**

- Group 1: Independent frontend tasks
- Group 2: Independent backend tasks
- Group 3: Integration tasks (depends on Group 1 + 2)

**Within each group:**

- Tasks execute in parallel (up to 3 concurrent tasks)
- TDD phases remain sequential per task
- Failures in one task don't block others (rollback only that task)

**Performance:**

- Expected speedup: 2-3x for features with high parallelism
- Bottleneck: Integration tasks (require both frontend + backend)

### Error Handling

**Auto-rollback on failure:**

```
Task T005 failed at Green phase (test still failing)
→ Rollback T005 changes (git restore)
→ Mark T005 as blocked in tasks.md
→ Continue with next independent task
→ Log error to specs/{slug}/error-log.md
```

**Manual intervention required:**

- Repository-wide test suite failure (affects all tasks)
- Git conflicts (merge required)
- Missing external dependencies (API keys, services)

**Resume after fixing:**

Run `/implement` again - it will automatically detect pending tasks from tasks.md (tasks with `- [ ]` checkbox) and continue from where it left off.

### Anti-Duplication

**Before creating new code:**

1. Search for existing implementations (Grep, Glob)
2. Check plan.md REUSABLE_COMPONENTS section
3. Prefer importing existing code over duplication

**Example:**

```
Task T007: Create email validation function

Before implementing:
  → Grep for "validateEmail" in codebase
  → Found: utils/validators.ts:45 exports validateEmail
  → Decision: Import existing function instead of creating new one
  → Update imports, skip implementation
```

### Commit Strategy

**Atomic commits per task:**

```
feat(T005): implement user profile edit form

- Add ProfileEditForm component with validation
- Add PATCH /api/users/:id endpoint
- Add test coverage for edit flow

Implements: specs/001-user-profile/tasks.md T005
Source: plan.md:145-160

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

**Final implementation commit:**

```
feat(001-user-profile): complete implementation

Tasks completed: 25/25
Files created: 12
Files modified: 8

All tests passing (125 tests, 0 failures)

Next: /optimize

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```
