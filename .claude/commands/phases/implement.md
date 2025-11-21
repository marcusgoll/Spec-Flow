---
name: implement
description: Execute all implementation tasks from tasks.md with test-driven development, parallel batching, and atomic commits
argument-hint: [feature-slug]
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash(python .spec-flow/scripts/spec-cli.py:*), Bash(git add:*), Bash(git commit:*), Bash(git diff:*), Bash(git status:*), Bash(npm test:*), Bash(pnpm test:*), Bash(pytest:*)]
---

# /implement — Task Execution with TDD

<context>
**User Input**: $ARGUMENTS

**Workflow Detection**: Auto-detected via workspace files, branch pattern, or workflow-state.yaml

**Current Branch**: !`git branch --show-current 2>$null || echo "none"`

**Feature Directory**: !`python .spec-flow/scripts/spec-cli.py check-prereqs --json --paths-only 2>$null | jq -r '.FEATURE_DIR'`

**Pending Tasks**: Auto-detected from ${BASE_DIR}/*/tasks.md

**Completed Tasks**: Auto-detected from ${BASE_DIR}/*/tasks.md

**Git Status**: !`git status --short 2>$null || echo "clean"`

**Mockup Approval Status** (if UI-first): Auto-detected from ${BASE_DIR}/*/workflow-state.yaml

**Implementation Artifacts** (after script execution):
- @${BASE_DIR}/*/tasks.md (updated with completed tasks)
- @${BASE_DIR}/*/CLAUDE.md (living documentation)
- @design/systems/ui-inventory.md (if UI components created)
- @design/systems/approved-patterns.md (if patterns extracted)
</context>

<objective>
Execute all tasks from ${BASE_DIR}/$ARGUMENTS/tasks.md with parallel batching, strict TDD phases, auto-rollback on failure, and atomic commits.

Implementation workflow:
1. Run centralized spec-cli.py implement script with arguments
2. Review implementation progress (completed tasks, generated code)
3. Update living documentation (UI inventory, approved patterns)
4. Run full test suite verification
5. Present results with next action recommendation

**Key principles**:
- **Test-Driven Development**: Red (failing test) → Green (passing) → Refactor (improve)
- **Parallel execution**: Group independent tasks by domain, speedup bounded by dependencies
- **Anti-duplication**: Search existing code before creating new implementations
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
    {content:"Validate preflight checks",status:"completed",activeForm:"Preflight"},
    {content:"Parse tasks and detect batches",status:"completed",activeForm:"Parsing tasks"},
    {content:"Execute batch group 1 (tasks 1-3)",status:"in_progress",activeForm:"Executing batch group 1"},
    {content:"Execute batch group 2 (tasks 4-6)",status:"pending",activeForm:"Executing batch group 2"},
    {content:"Execute batch group 3 (tasks 7-9)",status:"pending",activeForm:"Executing batch group 3"},
    {content:"Run full test suite and commit",status:"pending",activeForm:"Wrapping up"}
  ]
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
else
    echo "⚠ Could not auto-detect workflow type - using fallback"
fi
```

---

### Step 1: Execute Implementation Script

Run the centralized spec-cli tool with feature slug:

```bash
python .spec-flow/scripts/spec-cli.py implement "$ARGUMENTS"
```

**Script operations** (automated):
1. **Preflight checks** — Validates git, jq, test runner installed
2. **Load tasks** — Parses tasks.md for all pending tasks
3. **Detect batches** — Groups independent tasks for parallel execution
4. **UI-first gate** — Checks mockup approval if --ui-first mode
5. **Execute batches** — Runs tasks in parallel groups (TDD: red → green → refactor)
6. **Anti-duplication** — Scans for existing implementations before creating new code
7. **Pattern following** — Applies plan.md recommended patterns consistently
8. **Auto-rollback** — Reverts changes on test failure
9. **Atomic commits** — Commits each task individually with descriptive message
10. **Full test suite** — Runs complete test suite after all tasks
11. **Git commit** — Final commit with implementation summary

**TDD workflow per task:**
1. **Red**: Write failing test (verify it fails)
2. **Green**: Implement minimal code to pass test
3. **Refactor**: Improve code quality without changing behavior
4. **Commit**: Atomic commit for this task

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
   ```markdown
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

   **Examples**:
   - {Usage in current feature}: {file_path}:{line}

   **Related Components**: {List related components}
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
   ```markdown
   ## Pattern: {Pattern Name}

   **Used in**: {feature-001, feature-003} ({N} features)
   **Category**: {Form | Navigation | Data Display | Modal}

   ### Structure

   ```html
   {Simplified HTML structure showing pattern}
   ```

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
   - workflow-state.yaml marks implementation phase complete
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
```bash
python .spec-flow/scripts/spec-cli.py implement "$SLUG" --continue
```

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
