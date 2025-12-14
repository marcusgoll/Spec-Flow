---
name: fix-ci
description: Diagnose and fix CI/deployment blockers for pull requests to enable safe deployment
argument-hint: [pr-number]
allowed-tools: [Bash, Read, Write, Edit, Grep, Glob, Task, TodoWrite, AskUserQuestion]
---

# /fix-ci — CI Blocker Resolution

<context>
**Arguments**: $ARGUMENTS

**Current Branch**: !`git branch --show-current 2>/dev/null || echo "none"`

**PR from Current Branch**: !`gh pr list --head $(git branch --show-current 2>/dev/null) --json number,title,state -q '.[0]' 2>/dev/null || echo "null"`

**GitHub CLI**: !`gh auth status 2>&1 | head -1 || echo "not authenticated"`

**Git Status**: !`git status --short | head -5`
</context>

<objective>
Diagnose and fix CI blockers for a pull request.

**Mission**: Act as a deployment doctor — diagnose, auto-fix, delegate, validate.

**What This Command Does**:
1. Load PR context (checks, files, reviews)
2. Categorize failures (lint, types, tests, build, deploy)
3. Auto-fix simple issues (formatting, linting)
4. Delegate complex issues to specialist agents
5. Validate deployment readiness

**Risk Level**: MEDIUM — May push auto-fix commits to PR branch
</objective>

<anti-hallucination>
## Critical Rules

1. **Never claim fixes without verification** — Run commands, check exit codes
2. **Quote real CI output** — Use `gh pr checks` for actual errors
3. **Read PR diff first** — Don't guess root cause without evidence
4. **Verify check status** — Poll `gh pr checks` after pushes
5. **No fabricated URLs** — Only report URLs from actual CI logs
</anti-hallucination>

<process>

## Step 1: Parse PR Number

**If argument provided**: Use it as PR number
**If no argument**: Detect from current branch

```bash
# Get PR number from current branch
gh pr list --head $(git branch --show-current) --json number -q '.[0].number'
```

**If no PR found**: Show usage and exit
```
Usage: /fix-ci <pr-number>
Example: /fix-ci 123

Or run from a branch with an open PR.
```

## Step 2: Load PR Context

Fetch PR data:
```bash
gh pr view $PR_NUMBER --json title,baseRefName,headRefName,state,mergeable,reviewDecision,files
```

Extract:
- `PR_TITLE` — PR title
- `PR_BASE` — Base branch (main, production, etc.)
- `PR_HEAD` — Head branch (feature branch)
- `PR_STATE` — State (OPEN, MERGED, CLOSED)
- `PR_MERGEABLE` — Merge status
- `PR_REVIEW` — Review decision (APPROVED, CHANGES_REQUESTED, etc.)

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Fixing CI for PR #{number}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: {title}
Branch: {head} → {base}
State: {state}
```

## Step 3: Detect Deployment Phase

| Base Branch | Phase | Environment | Next Command |
|-------------|-------|-------------|--------------|
| `main` | 1 | staging | `/ship --staging` |
| `production` | 2 | production | `/ship --prod` |
| other | 0 | unknown | — |

Display phase context.

## Step 4: Fetch Check Statuses

```bash
gh pr checks $PR_NUMBER --json name,state,conclusion,detailsUrl
```

Count by status:
- PENDING — Still running
- SUCCESS — Passed
- FAILURE — Failed

Display summary:
```
Checks: {success} passing, {failure} failing, {pending} pending
```

## Step 5: Categorize Failures

Group failing checks by type:

| Pattern in Name | Category |
|-----------------|----------|
| `lint`, `eslint`, `ruff` | lint |
| `type`, `typescript`, `mypy` | types |
| `test`, `jest`, `pytest` | tests |
| `build` | build |
| `deploy`, `vercel`, `railway` | deploy |
| `smoke` | smoke |
| `e2e`, `playwright` | e2e |

For each failing check, extract:
- Check name
- Details URL (for logs)
- Category

Display categorized failures:
```
Failures by category:
  lint: 1 check
  types: 2 checks
  build: 1 check
```

## Step 6: Initialize TodoWrite

Create task list for tracking:

```javascript
TodoWrite({
  todos: [
    {content: "Auto-fix lint/format issues", status: "pending", activeForm: "Auto-fixing lint"},
    {content: "Analyze type errors", status: "pending", activeForm: "Analyzing types"},
    {content: "Analyze test failures", status: "pending", activeForm: "Analyzing tests"},
    {content: "Diagnose build failures", status: "pending", activeForm: "Diagnosing build"},
    {content: "Validate deployment gates", status: "pending", activeForm: "Validating gates"}
  ]
})
```

Only include tasks for categories with failures.

## Step 7: Auto-Fix Lint/Format

**If lint failures detected**:

1. Checkout PR branch (if not already):
   ```bash
   git fetch origin $PR_HEAD && git checkout $PR_HEAD
   ```

2. Detect project type and run auto-fix:

   **Node.js** (package.json exists):
   ```bash
   npm run lint -- --fix || pnpm lint --fix
   npm run format || pnpm format
   ```

   **Python** (pyproject.toml or requirements.txt):
   ```bash
   ruff check --fix .
   ruff format .
   ```

   **Rust** (Cargo.toml):
   ```bash
   cargo fmt
   cargo clippy --fix --allow-dirty
   ```

   **Go** (go.mod):
   ```bash
   gofmt -w .
   go mod tidy
   ```

3. If changes made, commit and push:
   ```bash
   git add .
   git diff --cached --quiet || git commit -m "style: auto-fix lint/format via /fix-ci

   🤖 Generated with Claude Code
   Co-Authored-By: Claude <noreply@anthropic.com>"
   git push origin $PR_HEAD
   ```

4. Post PR comment:
   ```bash
   gh pr comment $PR_NUMBER --body "✅ Auto-fixed lint/format issues. CI re-running."
   ```

Mark TodoWrite task as completed.

## Step 8: Analyze Type Errors

**If type failures detected**:

1. Run type checker locally to get full error output:

   **Node.js**:
   ```bash
   npx tsc --noEmit 2>&1
   ```

   **Python**:
   ```bash
   mypy . 2>&1
   ```

2. Extract error summary (file:line references)

3. **Delegate to type-enforcer agent**:
   ```
   Task({
     subagent_type: "type-enforcer",
     description: "Fix type errors in PR #$PR_NUMBER",
     prompt: "Fix the following type errors in the codebase:

   ## Type Errors
   {type_error_output}

   ## Changed Files
   {list of changed files from PR}

   ## Instructions
   1. Read each file with type errors
   2. Fix the type issues while preserving functionality
   3. Run type checker to verify fixes
   4. Commit changes with message: fix(types): resolve type errors

   Do NOT change logic or behavior, only fix type annotations."
   })
   ```

4. Post PR comment with delegation notice:
   ```bash
   gh pr comment $PR_NUMBER --body "❌ Type errors detected. Delegating to type-enforcer agent.

   Errors found:
   {first 5 errors}

   Run locally: \`npx tsc --noEmit\` or \`mypy .\`"
   ```

Mark TodoWrite task as completed (delegated).

## Step 9: Analyze Test Failures

**If test failures detected**:

1. Identify failing test files from CI logs:
   ```bash
   gh run view $RUN_ID --log 2>&1 | grep -E "FAIL|ERROR" | head -20
   ```

2. **Delegate to debugger agent**:
   ```
   Task({
     subagent_type: "debugger",
     description: "Fix test failures in PR #$PR_NUMBER",
     prompt: "Investigate and fix test failures:

   ## Failing Tests
   {test failure output}

   ## Changed Files
   {list of changed files from PR}

   ## Instructions
   1. Read failing test files
   2. Read the implementation files they test
   3. Determine if tests are wrong or implementation is wrong
   4. Fix the appropriate files
   5. Run tests locally to verify
   6. Commit with message: fix(tests): resolve test failures"
   })
   ```

3. Post PR comment:
   ```bash
   gh pr comment $PR_NUMBER --body "❌ Test failures detected. Delegating to debugger agent.

   Failing tests:
   {first 5 failures}

   Run locally: \`npm test\` or \`pytest\`"
   ```

Mark TodoWrite task as completed (delegated).

## Step 10: Diagnose Build Failures

**If build failures detected**:

1. Fetch build logs:
   ```bash
   gh run view $RUN_ID --log 2>&1 | grep -A 5 "error" | head -30
   ```

2. Common causes checklist:
   - Missing dependencies
   - TypeScript/compilation errors
   - Missing environment variables
   - Import path issues
   - Memory limits

3. Try local build:
   ```bash
   npm run build 2>&1 || pnpm build 2>&1
   ```

4. Post diagnostic comment:
   ```bash
   gh pr comment $PR_NUMBER --body "❌ Build failures detected.

   Common causes:
   - Missing dependencies
   - TypeScript errors
   - Missing env vars
   - Import path issues

   Error excerpt:
   \`\`\`
   {first 10 lines of error}
   \`\`\`

   Check CI logs: {details_url}"
   ```

Mark TodoWrite task as completed (diagnosed).

## Step 11: Check Rate Limits

**If deploy failures detected**, check for quota issues:

```bash
gh run view $RUN_ID --log 2>&1 | grep -iE "rate limit|quota|429|too many"
```

**If rate limited**:
```bash
gh pr comment $PR_NUMBER --body "⚠️ Deployment quota or rate limit reached.

Options:
1. Wait for quota reset
2. Run local validation: \`npm run build && npm test\`
3. Use preview mode for next deployment attempt

This is NOT a code issue - it's a platform limit."
```

## Step 12: Validate Deployment Gates

Check all gates for current phase:

| Gate | Check | Required |
|------|-------|----------|
| CI Checks | All SUCCESS | Yes |
| Review | APPROVED | Yes |
| Mergeable | MERGEABLE | Yes |
| Smoke Tests | No smoke failures | Phase 1 |
| Staging Validation | Report approved | Phase 2 |

Count gates passed vs. total.

## Step 13: Post Final Status

**If all gates pass**:
```bash
gh pr comment $PR_NUMBER --body "## ✅ Ready for {environment}

All gates passed:
- ✅ CI checks green
- ✅ Review approved
- ✅ No merge conflicts
{phase-specific gates}

Next: \`{next_command}\`"
```

**If gates fail**:
```bash
gh pr comment $PR_NUMBER --body "## ⚠️ Not ready for {environment}

Gates: {passed}/{total} passing

Remaining blockers:
{list of failing gates}

See comments above for details."
```

## Step 14: Display CLI Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Summary: PR #{number}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase: {phase} ({environment})
Gates: {passed}/{total} passed

Actions taken:
  {list of actions}

{If all gates pass:}
✅ Ready for {environment}
Next: {next_command}

{If gates fail:}
❌ {remaining} gate(s) failing
Next: Address blockers, re-run /fix-ci {pr_number}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

</process>

<verification>
Before completing, verify:

1. **PR comment posted**:
   ```bash
   gh pr view $PR_NUMBER --comments | tail -10
   ```

2. **Auto-fixes committed** (if applied):
   ```bash
   git log -1 --oneline
   ```

3. **Check statuses accurate**:
   ```bash
   gh pr checks $PR_NUMBER
   ```

4. **TodoWrite updated**: All tasks marked completed or delegated
</verification>

<examples>

## Example 1: Lint Failures Auto-Fixed

```
> /fix-ci 123

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Fixing CI for PR #123
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: Add user profile page
Branch: feature/user-profile → main
State: OPEN

Phase: 1 (staging)

Checks: 4 passing, 1 failing, 0 pending

Failures by category:
  lint: 1 check

Auto-fixing lint issues...
  Running: npm run lint -- --fix
  ✓ 3 files auto-fixed
  Committing and pushing...
  ✓ Pushed fix commit

Posted PR comment: "✅ Auto-fixed lint/format issues."

Waiting for CI to re-run...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Summary: PR #123
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Actions taken:
  - Auto-fixed lint issues (3 files)
  - Pushed fix commit
  - CI re-running

Next: Wait for CI, then /fix-ci 123 to verify
```

## Example 2: Multiple Failures, Delegation

```
> /fix-ci 456

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Fixing CI for PR #456
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: Implement payment processing
Branch: feature/payments → main
State: OPEN

Phase: 1 (staging)

Checks: 2 passing, 3 failing, 0 pending

Failures by category:
  lint: 1 check
  types: 1 check
  tests: 1 check

Auto-fixing lint issues...
  ✓ 1 file auto-fixed, pushed

Analyzing type errors...
  Found 5 type errors
  Delegating to type-enforcer agent...
  ✓ Agent spawned

Analyzing test failures...
  Found 2 failing tests
  Delegating to debugger agent...
  ✓ Agent spawned

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Summary: PR #456
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Actions taken:
  - Auto-fixed lint (1 file)
  - Delegated type errors to type-enforcer
  - Delegated test failures to debugger

Gates: 1/4 passed

❌ Blockers remain
Next: Wait for agents, re-run /fix-ci 456
```

## Example 3: All Gates Pass

```
> /fix-ci 789

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Fixing CI for PR #789
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: Update dashboard layout
Branch: feature/dashboard → main
State: OPEN

Phase: 1 (staging)

Checks: 5 passing, 0 failing, 0 pending

No failures detected!

Validating gates...
  ✅ CI checks: all green
  ✅ Review: approved
  ✅ Mergeable: yes
  ✅ Smoke tests: passing

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Summary: PR #789
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Gates: 4/4 passed

✅ Ready for staging
Next: /ship --staging
```

</examples>

<notes>

## Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- PR exists and is open
- Local checkout available (for auto-fixes)

## Phase Detection

| Base Branch | Phase | Deployment Target |
|-------------|-------|-------------------|
| main | 1 | staging |
| production | 2 | production |
| other | 0 | unknown |

## Gate Requirements

**Phase 1** (staging):
- CI checks green
- Review approved
- No merge conflicts
- Smoke tests pass

**Phase 2** (production):
- CI checks green
- Review approved
- No merge conflicts
- Staging validation complete
- Deployment metadata present

## When to Re-run

Re-run `/fix-ci` after:
- CI completes from auto-fix push
- Delegated agents complete their work
- Manual fixes are pushed
- Reviews are updated

## Integration with /ship

After `/fix-ci` shows all gates passing:
- Phase 1: Run `/ship --staging`
- Phase 2: Run `/ship --prod`

</notes>
