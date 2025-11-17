---
description: Execute tasks with TDD, anti-duplication checks, pattern following (parallel execution)
version: 2.0
updated: 2025-11-17
---

# /implement — Parallel Task Execution with TDD

**Purpose**: Execute all tasks from `specs/<slug>/tasks.md` with parallel batching, strict TDD phases, auto-rollback on failure, and atomic commits.

**Command**: `/implement [slug]`

**When to use**: After `/tasks` completes. Runs all pending tasks, stopping only on critical blockers.

---

## Mental Model

**Flow**: preflight → execute (parallel batches) → wrap-up

**Parallelism**: Group independent tasks by domain; keep TDD phases sequential within a task. Speedup bounded by dependency share (Amdahl's Law).

**Do not stop unless**: Missing files, repo-wide test suite failure, git conflicts.

---

## Anti-Hallucination Rules

1. **Never speculate about code you have not read**
   Always `Read` files before referencing them.

2. **Cite your sources with file paths**
   Include exact location: `file_path:line_number`

3. **Admit uncertainty explicitly**
   Say "I'm uncertain about [X]. Let me investigate by reading [file]" instead of guessing.

4. **Quote before analyzing long documents**
   For specs >5000 tokens, extract relevant quotes first.

5. **Verify file existence before importing/referencing**
   Use Glob to find files; use Grep to find existing import patterns.

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

Use for: choosing implementation approaches, reuse decisions, debugging multi-step failures, prioritizing task order.

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

<instructions>
## USER INPUT

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Execute Implementation Workflow

Run the centralized spec-cli tool:

```bash
python .spec-flow/scripts/spec-cli.py implement "$ARGUMENTS"
```

**What the script does:**

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

**After script completes, you (LLM) must:**

## 1) Review Implementation Progress

**Check task completion:**
- Read updated tasks.md to see completed tasks
- Verify all tasks marked as completed (✅)
- Check for any blocked or failed tasks

**Review generated code:**
- Scan created/modified files
- Verify pattern consistency with plan.md
- Check for code duplication

## 2) Update Living Documentation

**When UI components were created during implementation:**

### a) Update ui-inventory.md

**For each new reusable component created in `components/ui/`:**

1. **Scan for new component files:**
   ```bash
   # Check what components were created
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

### b) Extract Approved Patterns

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

### c) Update Feature CLAUDE.md

**Trigger living documentation update for the feature:**

```bash
# Update specs/{NNN-slug}/CLAUDE.md with:
# - Last 3 completed tasks
# - Velocity metrics
# - Next steps

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

### d) Health Check (Optional)

**Run design health check** to verify documentation freshness:

```bash
.spec-flow/scripts/bash/design-health-check.sh --verbose
```

**Target metrics after implementation:**
- ui-inventory.md: <24 hours lag
- approved-patterns.md: Documented if pattern reused
- Feature CLAUDE.md: Updated with last 3 tasks
- Health score: ≥90%

## 3) Run Full Test Suite

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

## 3) Present Results to User

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

## 4) Suggest Next Action

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

</instructions>

---

## PARALLEL EXECUTION

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

---

## ERROR HANDLING

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

---

## ANTI-DUPLICATION

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

---

## COMMIT STRATEGY

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
