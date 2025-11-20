# Git Workflow Integration Guide

This document shows where to add commit sections to each Spec-Flow command.

## Summary of Changes

All phase commands need a "COMMIT ARTIFACTS" section added before their final RETURN section.

---

## Command Updates

### /specify (specify.md)

**Add before RETURN section:**

````markdown
## COMMIT SPECIFICATION

**After creating spec.md, commit the artifacts:**

```bash
# Stage specification artifacts
git add specs/$SLUG/spec.md
git add specs/$SLUG/visuals/ 2>/dev/null || true
git add specs/$SLUG/NOTES.md 2>/dev/null || true

# Commit with descriptive message
git commit -m "docs(spec): create specification for $SLUG

- Feature: $FEATURE_DESCRIPTION
- Acceptance criteria defined
- User stories outlined
- Technical requirements specified"

# Verify commit
COMMIT_HASH=$(git rev-parse --short HEAD)
echo "✅ Specification committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""
```
````

**Why:** Spec is the foundation - commit it immediately for rollback safety.

**Rollback:** `git reset --hard HEAD~1` (reverts spec creation)

````

---

### /clarify (clarify.md)

**Add before RETURN section:**

```markdown
## COMMIT CLARIFICATIONS

**After updating spec.md, commit the changes:**

```bash
# Stage updated specification
git add specs/$SLUG/spec.md

# Count clarifications resolved
CLARIFICATION_COUNT=$(grep -c "^###" specs/$SLUG/spec.md | head -5)

# Commit with clarifications listed
git commit -m "docs(clarify): resolve clarifications for $SLUG

Clarifications resolved:
$(grep "^### " specs/$SLUG/spec.md | sed 's/^### /- /' | head -5)

Total: $CLARIFICATION_COUNT updates"

# Verify commit
COMMIT_HASH=$(git rev-parse --short HEAD)
echo "✅ Clarifications committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""
````

**Why:** Clarifications change requirements - commit to track evolution.

**Rollback:** `git reset --hard HEAD~1` (reverts clarifications)

````

---

### /plan (plan.md)

**Add before RETURN section:**

```markdown
## COMMIT PLAN

**After creating plan.md and research.md, commit the artifacts:**

```bash
# Stage planning artifacts
git add specs/$SLUG/plan.md
git add specs/$SLUG/research.md

# Extract key decisions for commit message
KEY_DECISIONS=$(grep "^- " specs/$SLUG/plan.md | head -3 | sed 's/^/  /')

# Commit with plan summary
git commit -m "docs(plan): create implementation plan for $SLUG

Architecture decisions:
$KEY_DECISIONS

REUSE opportunities identified
Complexity assessed
Timeline estimated"

# Verify commit
COMMIT_HASH=$(git rev-parse --short HEAD)
echo "✅ Plan committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""
````

**Why:** Plan guides implementation - commit before tasks created.

**Rollback:** `git reset --hard HEAD~1` (reverts plan)

````

---

### /tasks (tasks.md)

**Add before RETURN section:**

```markdown
## COMMIT TASKS

**After creating tasks.md, commit the task breakdown:**

```bash
# Stage task artifacts
git add specs/$SLUG/tasks.md
git add specs/$SLUG/checklists/ 2>/dev/null || true

# Count tasks by priority
TASK_COUNT=$(grep -c "^T[0-9]\{3\}" specs/$SLUG/tasks.md)
P1_COUNT=$(grep -c "\[P1\]" specs/$SLUG/tasks.md || echo "0")
P2_COUNT=$(grep -c "\[P2\]" specs/$SLUG/tasks.md || echo "0")
P3_COUNT=$(grep -c "\[P3\]" specs/$SLUG/tasks.md || echo "0")

# Detect format
TASK_FORMAT="TDD"
grep -q "\[US[0-9]\]" specs/$SLUG/tasks.md && TASK_FORMAT="User Story"

# Commit with task breakdown
git commit -m "docs(tasks): create task breakdown for $SLUG

- Total tasks: $TASK_COUNT
- Format: $TASK_FORMAT
- Breakdown: P1=$P1_COUNT, P2=$P2_COUNT, P3=$P3_COUNT
- Checklists: $(ls specs/$SLUG/checklists/*.md 2>/dev/null | wc -l) files"

# Verify commit
COMMIT_HASH=$(git rev-parse --short HEAD)
echo "✅ Tasks committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""
````

**Why:** Tasks define work scope - commit before implementation.

**Rollback:** `git reset --hard HEAD~1` (reverts tasks)

````

---

### /analyze (analyze.md)

**Add before RETURN section:**

```markdown
## COMMIT ANALYSIS

**After creating analysis-report.md, commit the report:**

```bash
# Stage analysis artifacts
git add specs/$SLUG/analysis-report.md

# Extract issue summary
CRITICAL_COUNT=$(grep -c "CRITICAL" specs/$SLUG/analysis-report.md || echo "0")
ISSUE_COUNT=$(grep -c "Issue:" specs/$SLUG/analysis-report.md || echo "0")

# Commit with analysis summary
git commit -m "docs(analyze): create cross-artifact analysis for $SLUG

- Consistency checks performed
- Issues found: $ISSUE_COUNT
- Critical blockers: $CRITICAL_COUNT
- Ready for implementation: $([ $CRITICAL_COUNT -eq 0 ] && echo 'YES' || echo 'NO')"

# Verify commit
COMMIT_HASH=$(git rev-parse --short HEAD)
echo "✅ Analysis committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""
````

**Why:** Analysis validates design - commit before implementing.

**Rollback:** `git reset --hard HEAD~1` (reverts analysis)

````

---

### /implement (implement.md)

**Already has commit instructions (lines 587, 593, 599) but they're vague. Enhance them:**

**Update lines 587-599 to be explicit:**

```markdown
### TDD Phases (strict sequential order)

**RED Phase** [RED]:
- Write failing test first
- Test must fail for right reason
- Provide test output as evidence
- **Commit immediately:**
  ```bash
  git add .
  git commit -m "test(red): TXXX write failing test

Test: $TEST_NAME
Expected: FAILED (ImportError/NotImplementedError)
Evidence: $(pytest output | head -3)"
````

**GREEN Phase** [GREEN→TXXX]:

- Minimal implementation to pass RED test
- Run tests, must pass
- **Commit when tests pass:**
  ```bash
  git add .
  git commit -m "feat(green): TXXX implement to pass test
  ```

Implementation: $SUMMARY
Tests: All passing ($PASS/$TOTAL)
Coverage: $COV% (+$DELTA%)"

````

**REFACTOR Phase** [REFACTOR]:
- Clean up code (DRY, KISS)
- Tests must stay green
- **Commit after refactor:**
```bash
git add .
git commit -m "refactor: TXXX clean up implementation

Improvements: $IMPROVEMENTS
Tests: Still passing
Coverage: Maintained"
````

````

**Also add at end of /implement (before RETURN):**

```markdown
## COMMIT FINAL IMPLEMENTATION

**After all tasks complete, final commit:**

```bash
# Check task completion
COMPLETED=$(grep -c "^✅ T[0-9]\{3\}" specs/$SLUG/NOTES.md)
TOTAL=$(grep -c "^T[0-9]\{3\}" specs/$SLUG/tasks.md)

# Stage all implementation artifacts
git add .

# Commit with implementation summary
if [ "$TASK_FORMAT" = "user-story" ] && [ "$MVP_SHIPPED" = "true" ]; then
  # MVP commit
  git commit -m "feat(mvp): complete P1 (MVP) implementation for $SLUG

MVP tasks: $P1_COMPLETE/$P1_TOTAL ✅
Tests: All passing
Coverage: Backend $BACKEND_COV%, Frontend $FRONTEND_COV%

Deferred to roadmap: P2 ($P2_COUNT), P3 ($P3_COUNT)"
else
  # Full implementation commit
  git commit -m "feat(implement): complete implementation for $SLUG

Tasks: $COMPLETED/$TOTAL ✅
Tests: All passing
Coverage: $TOTAL_COV%"
fi

# Verify commit
COMMIT_HASH=$(git rev-parse --short HEAD)
echo "✅ Implementation committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""
````

**Why:** Implementation is the most critical phase - commit frequently.

**Rollback:**

- Entire implementation: `git reset --hard <commit-before-implement>`
- Single task: `git revert <task-commit-hash>`

````

---

### /optimize (optimize.md)

**Add before RETURN section:**

```markdown
## COMMIT OPTIMIZATION

**After creating reports and applying improvements, commit:**

```bash
# Stage optimization artifacts
git add specs/$SLUG/optimization-report.md
git add specs/$SLUG/code-review-report.md
git add .  # Include any code improvements

# Extract scores for commit message
PERF_SCORE=$(grep "Performance:" specs/$SLUG/optimization-report.md | grep -o "[0-9]*" | head -1)
SECURITY_ISSUES=$(grep "Security issues:" specs/$SLUG/optimization-report.md | grep -o "[0-9]*" | head -1)

# Commit with optimization summary
git commit -m "docs(optimize): complete optimization review for $SLUG

- Performance: $PERF_SCORE/100 (all endpoints <500ms)
- Security: $SECURITY_ISSUES issues fixed
- Code quality: Lint/type checks passing
- Accessibility: Violations addressed
- Improvements: Applied per code review"

# Verify commit
COMMIT_HASH=$(git rev-parse --short HEAD)
echo "✅ Optimization committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""
````

**Why:** Optimization changes code - commit before deployment.

**Rollback:** `git reset --hard HEAD~1` (reverts optimizations)

````

---

### /preview (preview.md)

**Add before RETURN section:**

```markdown
## COMMIT RELEASE NOTES

**After creating release-notes.md, commit:**

```bash
# Stage release artifacts
git add specs/$SLUG/release-notes.md

# Extract version for commit message
VERSION=$(grep "^## Version" specs/$SLUG/release-notes.md | head -1 | grep -o "[0-9.]*")

# Commit with release summary
git commit -m "docs(preview): create release notes for $SLUG v$VERSION

Changes documented
Breaking changes noted
Manual testing checklist ready
Release ready for staging"

# Verify commit
COMMIT_HASH=$(git rev-parse --short HEAD)
echo "✅ Release notes committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""
````

**Why:** Release notes document what's shipping - commit before deployment.

**Rollback:** `git reset --hard HEAD~1` (reverts release notes)

````

---

## Clean Working Tree Verification

**Add to START of each command (after loading feature):**

```markdown
## VERIFY CLEAN WORKING TREE

**Before starting this phase, ensure previous phase committed:**

```bash
# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠️  **UNCOMMITTED CHANGES DETECTED**"
  echo ""
  git status --short
  echo ""
  echo "Previous phase did not commit changes."
  echo ""
  echo "**Options:**"
  echo "  1. Commit: git add . && git commit -m '...'"
  echo "  2. Stash: git stash"
  echo "  3. Discard: git restore . (DANGER)"
  echo ""
  read -p "Proceed anyway? (yes/no): " response
  [ "$response" != "yes" ] && exit 1
fi

echo "✅ Working tree clean - ready to proceed"
echo ""
````

````

---

## Agent Brief Updates

### backend-dev.md

**Add section after "Task Completion Protocol":**

```markdown
## Git Workflow (MANDATORY)

**Every meaningful change MUST be committed for rollback safety.**

### Commit Frequency

**TDD Workflow:**
- RED phase: Commit failing test
- GREEN phase: Commit passing implementation
- REFACTOR phase: Commit improvements

**Command sequence:**
```bash
# After RED test
git add api/tests/test_message.py
git commit -m "test(red): T015 write failing test for Message model"

# After GREEN implementation
git add api/app/models/message.py api/tests/
git commit -m "feat(green): T015 implement Message model to pass test"

# After REFACTOR improvements
git add api/app/models/message.py
git commit -m "refactor: T015 improve Message model with base class"
````

### Commit Verification

**After every commit, verify:**

```bash
git log -1 --oneline
# Should show your commit message

git rev-parse --short HEAD
# Should show commit hash (e.g., a1b2c3d)
```

### Task Completion Requirement

**task-tracker REQUIRES commit hash:**

```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId "T015" \
  -Notes "..." \
  -Evidence "..." \
  -Coverage "..." \
  -CommitHash "$(git rev-parse --short HEAD)" \  # REQUIRED!
  -FeatureDir "$FEATURE_DIR"
```

**If CommitHash empty:** Git Workflow Enforcer Skill will block completion.

### Rollback Procedures

**If implementation fails:**

```bash
# Discard uncommitted changes
git restore .

# OR revert last commit
git reset --hard HEAD~1
```

**If specific task needs revert:**

```bash
# Find commit for task
git log --oneline --grep="T015"

# Revert that specific commit
git revert <commit-hash>
```

### Commit Message Templates

**Test commits:**

```
test(red): T015 write failing test for Message model
```

**Implementation commits:**

```
feat(green): T015 implement Message model to pass test
```

**Refactor commits:**

```
refactor: T015 improve Message model with base class
```

**Fix commits:**

```
fix: T015 correct Message model validation
```

### Critical Rules

1. **Commit after every TDD phase** (RED, GREEN, REFACTOR)
2. **Never mark task complete without commit**
3. **Always provide commit hash to task-tracker**
4. **Verify commit succeeded** before proceeding
5. **Use conventional commit format** for consistency

````

### frontend-dev.md

**Add same "Git Workflow (MANDATORY)" section as backend-dev.md**

Just replace examples:
```bash
# Frontend examples
git add apps/app/components/MessageForm.tsx
git commit -m "feat(green): T002 implement MessageForm component"
````

---

## Expected Git History

After completing all phases, git log should show:

```bash
$ git log --oneline

a1b2c3d docs(preview): create release notes for user-messaging v1.2.0
b2c3d4e docs(optimize): complete optimization review for user-messaging
c3d4e5f feat(mvp): complete P1 (MVP) implementation for user-messaging
d4e5f6g refactor: T015 improve Message model with base class
e5f6g7h feat(green): T015 implement Message model to pass test
f6g7h8i test(red): T015 write failing test for Message model
g7h8i9j feat(green): T014 implement MessageForm component
h8i9j0k test(red): T014 write failing test for MessageForm
... (more task commits)
i9j0k1l docs(analyze): create cross-artifact analysis for user-messaging
j0k1l2m docs(tasks): create task breakdown for user-messaging (25 tasks)
k1l2m3n docs(plan): create implementation plan for user-messaging
l2m3n4o docs(spec): create specification for user-messaging
m3n4o5p feat: create feature branch feat/001-user-messaging
```

**Benefits:**

- ✅ Clean history showing workflow progression
- ✅ Every commit is a potential rollback point
- ✅ Easy to find when bugs were introduced
- ✅ Audit trail for compliance
- ✅ Git bisect friendly (can binary search for bugs)

---

## Rollback Scenarios

### Scenario 1: Spec has error, need to restart

```bash
# Reset to before spec creation
git log --oneline --grep="docs(spec)"  # Find spec commit
git reset --hard <commit-before-spec>

# Re-run /specify with corrections
/specify "Corrected feature description"
```

### Scenario 2: Task T015 introduced bug

```bash
# Find T015 commits
git log --oneline --grep="T015"

# Revert GREEN commit (keeps test)
git revert <green-commit-hash>

# OR revert all T015 commits
git revert <red-commit>..<refactor-commit>
```

### Scenario 3: Entire implementation phase needs redo

```bash
# Find implement start
git log --oneline --grep="docs(analyze)"  # Last commit before implement

# Reset to before implementation
git reset --hard <analyze-commit>

# Re-run /implement with fixes
/implement
```

### Scenario 4: MVP shipped but P2 breaking

```bash
# Find MVP commit
git log --oneline --grep="feat(mvp)"

# Create hotfix branch
git checkout -b hotfix/mvp-issues <mvp-commit>

# Fix issues
# Deploy hotfix

# OR reset MVP and re-implement P1
git reset --hard <mvp-commit>
# Fix P1 tasks
/implement
```

---

## Integration Summary

**Total files to modify:**

- 8 commands: specify, clarify, plan, tasks, analyze, implement, optimize, preview
- 2 agent briefs: backend-dev, frontend-dev
- 1 new skill: git-workflow-enforcer (DONE ✅)

**Total additions:**

- ~50 lines per command (commit section)
- ~100 lines per agent (git workflow section)
- ~600 lines total

**Token impact:**

- Git Workflow Skill: +600 tokens when triggered
- Command overhead: Minimal (git commands execute quickly)

**Safety improvement:**

- Before: 0-2 commits per feature (only PR merges)
- After: 20-50 commits per feature (every phase + every task)
- Rollback granularity: 25x improvement
