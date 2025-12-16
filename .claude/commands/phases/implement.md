---
name: implement
description: Execute all implementation tasks from tasks.md with test-driven development, parallel batching, and atomic commits
argument-hint: "[feature-slug] [--dry-run]"
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

**Current Branch**: !`git branch --show-current 2>/dev/null || echo "none"`

**Feature Directory**: !`python .spec-flow/scripts/spec-cli.py check-prereqs --json --paths-only 2>/dev/null | jq -r '.FEATURE_DIR'`

**Pending Tasks**: Auto-detected from ${BASE_DIR}/\*/tasks.md

**Completed Tasks**: Auto-detected from ${BASE_DIR}/\*/tasks.md

**Git Status**: !`git status --short 2>/dev/null || echo "clean"`

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

### Step 0: WORKFLOW DETECTION

**Detect workflow using centralized skill** (see `.claude/skills/workflow-detection/SKILL.md`):

1. Run detection: `bash .spec-flow/scripts/utils/detect-workflow-paths.sh`
2. Parse JSON: Extract `type`, `base_dir`, `slug` from output
3. If detection fails: Use AskUserQuestion fallback
4. Set paths:
   - `TASKS_FILE="${BASE_DIR}/${SLUG}/tasks.md"`
   - `WORKFLOW_STATE="${BASE_DIR}/${SLUG}/state.yaml"`

---

### Step 0.1: DRY-RUN MODE DETECTION

**Check for --dry-run flag** (see `.claude/skills/dry-run/SKILL.md`):

```bash
DRY_RUN="false"
if [[ "$ARGUMENTS" == *"--dry-run"* ]]; then
  DRY_RUN="true"
  ARGUMENTS=$(echo "$ARGUMENTS" | sed 's/--dry-run//g' | xargs)
  echo "DRY-RUN MODE ENABLED"
fi
```

**If DRY_RUN is true:**

1. Read tasks.md to count pending/completed tasks
2. Read domain-memory.yaml (if exists) for feature count
3. Output dry-run summary and exit:

```
════════════════════════════════════════════════════════════════════════════════
DRY-RUN MODE: No changes will be made
════════════════════════════════════════════════════════════════════════════════

📋 CURRENT STATE:
  Feature: ${BASE_DIR}/${SLUG}/
  Phase: implement
  Tasks remaining: N of M

📝 FILES THAT WOULD BE MODIFIED:
  ✎ ${BASE_DIR}/${SLUG}/domain-memory.yaml
    - features[F001].status: pending → completed
    - features[F002].status: pending → in_progress
  ✎ ${BASE_DIR}/${SLUG}/tasks.md (checkboxes marked)
  ✎ ${BASE_DIR}/${SLUG}/state.yaml (phase progress)
  ✎ src/... (implementation files)
  ✎ src/...test... (test files)

🤖 AGENTS THAT WOULD BE SPAWNED:
  For each pending feature in domain-memory.yaml:
    worker → Implement feature atomically with TDD

  Specialist routing:
    backend-dev → For Python/FastAPI tasks
    frontend-dev → For React/Next.js tasks
    database-architect → For schema tasks
    api-contracts → For OpenAPI tasks

🔄 TDD CYCLE PER TASK:
  1. Write failing tests (Red)
  2. Implement feature (Green)
  3. Refactor if needed
  4. Update domain-memory.yaml
  5. Commit changes

🔀 GIT OPERATIONS:
  • git add (after each task)
  • git commit -m "feat: [task description]" (per task)

════════════════════════════════════════════════════════════════════════════════
DRY-RUN COMPLETE: 0 actual changes made
Run `/implement` to execute N remaining tasks
════════════════════════════════════════════════════════════════════════════════
```

**Exit after dry-run summary. Do NOT proceed to normal execution.**

---

### Step 0.5: ITERATION DETECTION

**Check if workflow is in iteration mode** (gaps from previous `/optimize`):

1. Read `state.yaml` for `iteration.current` and `iteration.max_iterations`
2. If `current > 1`: Filter tasks to current iteration section only
3. If `current > max_iterations`: Block with error (prevent scope creep)
4. Update iteration state after completion

**Key variables set:**
- `ITERATION_MODE`: true/false
- `ITERATION_NUMBER`: 1, 2, or 3 (max default)

---

### Step 0.55: LOAD USER PREFERENCES

**Load preferences from** `.spec-flow/config/user-preferences.yaml`:

| Preference | Default | Effect |
|------------|---------|--------|
| `migrations.strictness` | `blocking` | blocking/warning/auto_apply |
| `automation.auto_approve_minor` | `false` | Skip review for formatting |
| `automation.ci_mode_default` | `false` | Non-interactive mode |

Use `load-preferences.sh` utility to extract values.

---

### Step 0.6: MIGRATION ENFORCEMENT

**Pre-flight check**: Block if migrations not applied (see `docs/references/migration-safety.md`).

1. Check `state.yaml` for `has_migrations: true`
2. Run `check-migration-status.sh --json` to detect pending migrations
3. Apply strictness policy from preferences:

| Strictness | Behavior |
|------------|----------|
| `blocking` (default) | Exit with error, show apply command |
| `warning` | Log warning, continue |
| `auto_apply` | Run migrations automatically |

**Why block?** 40% of implementation failures trace to missing migrations.

---

### Step 0.7: MOCKUP COMPONENT EXTRACTION (UI-First Only)

**Pre-condition**: `ui_first: true` AND `mockup_approval.status: approved` in state.yaml

**Invoke mockup-extraction skill** (`.claude/skills/mockup-extraction/SKILL.md`):

1. Scan mockup HTML files for repeated components
2. Map CSS to Tailwind utilities
3. Generate `prototype-patterns.md` with:
   - Component inventory with occurrence counts
   - CSS to Tailwind mapping
   - TypeScript interface definitions
   - Interactive states (hover, focus, disabled, loading)

**Why?** Prevents 40-60% of visual fidelity issues.

---

### Step 0.8: DOMAIN MEMORY WORKER PATTERN

**Pre-condition**: `domain-memory.yaml` exists in feature directory

**If present**, use isolated Worker pattern (see `.claude/skills/domain-memory/SKILL.md`):

```
While remaining features > 0:
  1. Spawn Task(worker) with domain-memory.yaml path
  2. Worker implements ONE feature, updates disk, exits
  3. Read updated domain-memory.yaml
  4. Repeat until all features complete
```

**Key behaviors:**
- Orchestrator is lightweight (reads disk, spawns Task)
- Workers are isolated (fresh context per spawn)
- Disk is source of truth (domain-memory.yaml)
- Auto-retry up to 3 times before blocking

**If not present**, fall back to batch mode (Step 1).

---

### Step 1: PARSE AND GROUP TASKS

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

### Step 1.4.5: Ultrathink Checkpoint — Craft, Don't Code

> **Philosophy**: "Would a junior developer understand this in 5 minutes?"

Before executing each task batch, apply the anti-duplication ritual.

**Display thinking prompt** (once per batch):

```
┌─────────────────────────────────────────────────────────────┐
│ 💭 ULTRATHINK CHECKPOINT: Craft, Don't Code                 │
├─────────────────────────────────────────────────────────────┤
│ Before implementing, always ask:                            │
│                                                             │
│ • Have I searched for similar patterns? (mgrep first!)      │
│ • Can I extend existing code instead of creating new?       │
│ • Does this abstraction earn its complexity?                │
│ • Would a junior dev understand this in 5 minutes?          │
└─────────────────────────────────────────────────────────────┘
```

**Pre-Coding Ritual** (execute before EACH new file creation):

```bash
# Step 1: Anti-duplication search
echo "=== Anti-Duplication Check ==="

# Use mgrep for semantic search (finds similar by meaning)
TASK_DESCRIPTION="[task description from tasks.md]"
mgrep "$TASK_DESCRIPTION"

# If mgrep unavailable, fallback to Grep
Grep "similar pattern keywords" --type ts
```

**Decision tree after search:**

```
Search Results:
  │
  ├─ Found similar code
  │   └─ Q: "Can we extend this instead of creating new?"
  │       ├─ Yes → Extend existing file (preferred)
  │       └─ No → Document why in NOTES.md, then create new
  │
  └─ No similar code found
      └─ Proceed with new implementation
         └─ Follow existing codebase patterns (from plan.md)
```

**Abstraction check** (for new files):

```markdown
## Abstraction Justification

| New File | Justification | Alternatives Considered |
|----------|---------------|------------------------|
| [path] | [why this earns its complexity] | [what was ruled out] |
```

**Quality questions per task:**

Before writing code, answer mentally:
1. **Reuse**: Did I search for existing patterns?
2. **Simplicity**: Is this the simplest approach that works?
3. **Clarity**: Would someone understand this without comments?
4. **Testability**: Can this be tested in isolation?

**If creating an abstraction** (interface, base class, utility):

```json
{
  "question": "You're about to create a new abstraction. Does it earn its complexity?",
  "header": "Abstraction",
  "multiSelect": false,
  "options": [
    {"label": "Yes, multiple consumers", "description": "This will be used by 2+ implementations"},
    {"label": "Yes, complex logic", "description": "Encapsulates genuinely complex behavior"},
    {"label": "No, premature", "description": "I should inline this for now"},
    {"label": "Skip check", "description": "I've already considered this"}
  ]
}
```

**Red flags to catch:**

- Creating interface with only 1 implementation
- Adding "for future use" code
- Generic utility for a single use case
- Inheritance hierarchy deeper than 2 levels

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

### Step 1.7: CONTINUOUS QUALITY CHECKS

**After each batch group of 3-4 tasks**, run `continuous-checks.sh`:

```bash
bash .spec-flow/scripts/bash/continuous-checks.sh --batch-num $BATCH_NUM --feature-dir "$FEATURE_DIR"
```

**5 Checks Performed** (target: < 30s total):

| Check | Tool | Auto-fix |
|-------|------|----------|
| Linting | ESLint/Ruff | Yes |
| Type checking | tsc/mypy (incremental) | No |
| Unit tests | Related tests only | No |
| Coverage delta | Compare to baseline | No |
| Dead code | Unused exports | No (warning) |

**On failure**: Fix now (recommended), continue anyway, or abort batch.

**Skip when**: Iteration 2+, `--no-checks` flag, documentation-only batch.

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

Auto-invoking /debug to investigate failures and generate regression tests...
```

**Auto-invoke /debug** with test failure context:

```bash
# Extract failed test info and invoke /debug
/debug $FEATURE_SLUG --type=test --component={backend|frontend} --non-interactive
```

This will:
1. Run verification checks on the failing component
2. Analyze test failure logs
3. **Auto-generate regression test** for the bug (Step 3.5)
4. Update error-log.md with failure details
5. Return with actionable fix recommendations

**After /debug completes**, present results:

```
Debug session complete for test failures

Error log updated: specs/{slug}/error-log.md (Entry #N)
Regression test generated: tests/regression/regression-ERR-XXXX-{slug}.test.ts

Fix the identified issues, then re-run /implement to continue.
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
