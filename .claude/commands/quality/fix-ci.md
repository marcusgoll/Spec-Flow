---
name: fix-ci
description: Diagnose and fix CI/deployment blockers for pull requests to enable safe deployment
argument-hint: [pr-number]
allowed-tools: [Bash(gh *), Bash(git *), Bash(pnpm *), Bash(uv *), Bash(curl *), Bash(jq *), Bash(cd *), Bash(echo *), Bash(grep *), Bash(declare *), TodoWrite, Read, Write, Edit]
---

# /fix-ci — CI/Deployment Blocker Resolution

<context>
**PR Number**: $ARGUMENTS

**Current Branch**: !`git branch --show-current 2>/dev/null || echo "none"`

**PR Context** (if on PR branch): !`gh pr list --head $(git branch --show-current) --json number,title,state,baseRefName -q '.[0]' 2>/dev/null || echo "null"`

**GitHub CLI Status**: !`gh auth status 2>/dev/null | head -1 || echo "not authenticated"`

**Available Tools**: !`which gh git jq pnpm uv curl 2>/dev/null || echo "missing tools"`

**Repository Status**: !`git status --short | head -5 || echo "clean"`
</context>

<objective>
Diagnose and fix CI/deployment blockers for PR #$ARGUMENTS to make it deployment-ready.

**Mission**: Act as a deployment doctor — diagnose → auto-fix → delegate → validate.

**Scope**:
- Read PR context (checks, files, reviews, logs)
- Categorize blockers (lint, types, tests, build, deploy, smoke, e2e)
- Auto-fix simple issues (format/lint)
- Delegate complex issues (types, build, test debugging)
- Validate deployment readiness gates

**State awareness**:
- Base branch `main` → Phase 1 (feature → staging)
- Base branch `production` → Phase 2 (staging → production)
- Infer phase from PR base

**Deployment mode awareness**:
- **Preview mode**: Debug CI and workflows safely (preferred during triage)
- **Staging mode**: Updates staging domain; use only when explicitly shipping
- Default to **preview** to avoid burning quotas

**Progressive disclosure**:
- Show only relevant blockers/fixes
- Link to logs; don't dump giant logs into PR
- Keep PR bot comments <30 lines

**Prerequisites**:
- GitHub CLI (`gh`) installed and authenticated
- PR exists
- Local checkout of the PR head branch (needed for auto-fixes)
</objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent fabricating fixes or deployment status.

1. **Never claim a fix succeeded without re-running checks**
   - Always run `pnpm run lint` / `ruff check` / `mypy` / `pnpm build`
   - Report actual exit codes and status lines from command output
   - Don't say "fixed" until verification passes

2. **Quote real CI output when diagnosing**
   - Use `gh pr checks --json` and workflow run logs for exact errors
   - Include the failing check name and minimal excerpt (first relevant line)
   - Never guess at error messages

3. **Read the PR diff before guessing root cause**
   - Pull `gh pr view <n> --json files` to see changed files
   - Correlate failures to specific changed files
   - Don't assume cause without evidence

4. **Verify check status before claiming "green"**
   - After pushes, poll `gh pr checks` for actual statuses
   - Report current check state: PENDING, SUCCESS, FAILURE
   - Never claim all checks pass without verification

5. **Don't fabricate deployment URLs/IDs**
   - Only report URLs/IDs present in CI logs or `gh` output
   - Quote actual deployment logs when referencing URLs
   - If no deployment URL found, say so explicitly

**Why this matters**: Bad guesses waste time, greenwashing breaks production, fabricated URLs destroy credibility.

---

<process>

## STEP 1: Track Progress with TodoWrite

Initialize blocker tracking:

```javascript
TodoWrite({
  todos: [
    {content: "Load PR context and checks", status: "pending", activeForm: "Loading PR context"},
    {content: "Categorize blockers (lint/types/tests/build/deploy/smoke)", status: "pending", activeForm: "Categorizing blockers"},
    {content: "Auto-fix lint/format issues", status: "pending", activeForm: "Auto-fixing lint/format"},
    {content: "Fix or delegate type errors", status: "pending", activeForm: "Type fixes"},
    {content: "Fix or delegate test failures", status: "pending", activeForm: "Test fixes"},
    {content: "Diagnose build/deploy failures", status: "pending", activeForm: "Build/Deploy fixes"},
    {content: "Validate gates (checks/review/conflicts + phase-specific)", status: "pending", activeForm: "Validating gates"},
    {content: "Update PR with status", status: "pending", activeForm: "Updating PR"}
  ]
})
```

**Rules**:
- Only one `in_progress` at a time
- Flip to `completed` immediately after verified success
- Mark with failure reason and link to logs if stuck

---

## STEP 2: Load PR Context

**Parse PR number and fetch context**:

```bash
# If no argument, infer from current branch
if [ -z "$ARGUMENTS" ]; then
  CURRENT_BRANCH=$(git branch --show-current)
  PR_NUMBER=$(gh pr list --head "$CURRENT_BRANCH" --json number -q '.[0].number' 2>/dev/null)
  if [ -z "$PR_NUMBER" ]; then
    echo "Usage: /fix-ci <pr-number>"
    echo "Example: /fix-ci 123"
    exit 1
  fi
else
  if [[ "$ARGUMENTS" =~ ([0-9]+) ]]; then
    PR_NUMBER="${BASH_REMATCH[1]}"
  else
    echo "Provide a PR number."
    echo "Example: /fix-ci 123"
    exit 1
  fi
fi

# Validate and load core PR fields
PR_DATA=$(gh pr view "$PR_NUMBER" --json title,body,author,baseRefName,headRefName,state,mergeable,reviewDecision)
PR_TITLE=$(echo "$PR_DATA" | jq -r '.title')
PR_BASE=$(echo "$PR_DATA" | jq -r '.baseRefName')
PR_HEAD=$(echo "$PR_DATA" | jq -r '.headRefName')
PR_STATE=$(echo "$PR_DATA" | jq -r '.state')
PR_AUTHOR=$(echo "$PR_DATA" | jq -r '.author.login')
PR_MERGEABLE=$(echo "$PR_DATA" | jq -r '.mergeable')
PR_REVIEW=$(echo "$PR_DATA" | jq -r '.reviewDecision')
```

**Display PR info**:
```
Fixing CI for PR #$PR_NUMBER
Title: $PR_TITLE
Base: $PR_BASE
State: $PR_STATE
```

---

## STEP 3: Detect Deployment Phase

**Determine phase from base branch**:

```bash
PHASE=0; ENVIRONMENT="unknown"; NEXT_COMMAND=""

if [ "$PR_BASE" = "main" ]; then
  PHASE=1; ENVIRONMENT="staging"; NEXT_COMMAND="/ship-staging"
  echo "Phase 1: Feature → Staging"
elif [ "$PR_BASE" = "production" ]; then
  PHASE=2; ENVIRONMENT="production"; NEXT_COMMAND="/ship-prod"
  echo "Phase 2: Staging → Production"
else
  echo "Unknown base: $PR_BASE (expect main or production)"; PHASE=0
fi
```

---

## STEP 4: Read PR Checks and Files

**Fetch check statuses**:

```bash
CHECK_DATA=$(gh pr checks "$PR_NUMBER" --json name,state,conclusion,detailsUrl 2>/dev/null || echo "[]")
TOTAL_CHECKS=$(echo "$CHECK_DATA" | jq 'length')
PENDING=$(echo "$CHECK_DATA" | jq '[.[] | select(.state=="PENDING" or .state=="QUEUED" or .state=="IN_PROGRESS")] | length')
SUCCESS=$(echo "$CHECK_DATA" | jq '[.[] | select(.conclusion=="SUCCESS")] | length')
FAILURE=$(echo "$CHECK_DATA" | jq '[.[] | select(.conclusion=="FAILURE")] | length')

CHANGED_FILES=$(gh pr view "$PR_NUMBER" --json files -q '.files[].path')
```

**Display check summary**:
```
Checks: $SUCCESS passing, $FAILURE failing, $PENDING pending (total: $TOTAL_CHECKS)
```

---

## STEP 5: Categorize Failing Checks

**Group failures by type**:

```bash
declare -A FAILURES_BY_TYPE
RATE_LIMITED=false

echo "$CHECK_DATA" | jq -r '.[] | select(.conclusion=="FAILURE") | "\(.name)|\(.detailsUrl)"' \
| while IFS='|' read -r check_name check_url; do
  [ -z "$check_name" ] && continue
  category="other"
  [[ "$check_name" =~ [Ll]int ]] && category="lint"
  [[ "$check_name" =~ [Tt]ype|TypeScript|MyPy ]] && category="types"
  [[ "$check_name" =~ [Tt]est|Jest|Pytest ]] && category="tests"
  [[ "$check_name" =~ [Bb]uild ]] && category="build"
  [[ "$check_name" =~ [Dd]eploy|Vercel|Railway ]] && category="deploy"
  [[ "$check_name" =~ [Ss]moke ]] && category="smoke"
  [[ "$check_name" =~ E2E|e2e|Playwright ]] && category="e2e"

  FAILURES_BY_TYPE[$category]="${FAILURES_BY_TYPE[$category]}$check_name|$check_url
"

  # Check for quota/rate-limit in deploy jobs
  if [ "$category" = "deploy" ] && [[ "$check_url" =~ /runs/([0-9]+) ]]; then
    RUN_ID="${BASH_REMATCH[1]}"
    if gh run view "$RUN_ID" --log 2>/dev/null | grep -qiE "rate limit|quota|Too Many Requests"; then
      RATE_LIMITED=true
    fi
  fi
done
```

**Report categorized failures** to user and update TodoWrite.

---

## STEP 6: Handle Deployment Quota/Rate Limits

**If deployment quota hit**, post recovery guide:

```bash
if [ "$RATE_LIMITED" = true ]; then
  gh pr comment "$PR_NUMBER" --body "⚠️ Deployment quota or rate limit reached.

**Options**
1) Run local validation: \`pnpm run ci:validate\`
2) Use **preview mode** when re-running CI to avoid consuming staging/production quotas
3) Re-try after quota window resets

— generated by /fix-ci"
fi
```

**Switch to preview-mode validation** and skip staging deployment until quota resets.

---

## STEP 7: Auto-Fix Lint/Format Issues

**Checkout PR branch and run auto-fixers**:

```bash
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$PR_HEAD" ]; then
  git fetch origin "$PR_HEAD" && git checkout "$PR_HEAD"
fi

LINT_FIXED=false

# Marketing app
if echo "$CHANGED_FILES" | grep -q "^apps/marketing"; then
  cd apps/marketing && pnpm install --silent || true
  pnpm lint --fix || true
  cd ../..
  LINT_FIXED=true
fi

# Main app
if echo "$CHANGED_FILES" | grep -q "^apps/app"; then
  cd apps/app && pnpm install --silent || true
  pnpm lint --fix || true
  cd ../..
  LINT_FIXED=true
fi

# API (Python)
if echo "$CHANGED_FILES" | grep -q "^api/"; then
  cd api
  uv run ruff check --fix || true
  uv run ruff format || true
  cd ..
  LINT_FIXED=true
fi

# Commit and push auto-fixes
if [ "$LINT_FIXED" = true ] && [ -n "$(git status --porcelain)" ]; then
  git add . && git commit -m "fix: auto-fix lint/format via /fix-ci" && git push origin "$PR_HEAD"
  gh pr comment "$PR_NUMBER" --body "✅ Auto-fixed lint/format. CI re-running."
fi
```

**Update TodoWrite**: Mark "Auto-fix lint/format issues" as completed.

---

## STEP 8: Analyze Type Errors

**Run type checkers and report**:

```bash
TYPE_ERRORS=false

# Frontend type check
if echo "$CHANGED_FILES" | grep -q "^apps/app"; then
  cd apps/app && pnpm install --silent || true
  pnpm run type-check || TYPE_ERRORS=true
  cd ../..
fi

# Backend type check (Python)
if echo "$CHANGED_FILES" | grep -q "^api/"; then
  cd api
  uv run mypy app/ || TYPE_ERRORS=true
  cd ..
fi

# Delegate if type errors found
if [ "$TYPE_ERRORS" = true ]; then
  gh pr comment "$PR_NUMBER" --body "❌ Type errors detected. Delegating to type-enforcer agent.

Run locally: \`pnpm run type-check\` (frontend) or \`uv run mypy app/\` (backend)"
fi
```

**Update TodoWrite**: Mark type fixes as delegated if errors found.

---

## STEP 9: Analyze Build Failures

**Reproduce build failures locally**:

```bash
if [ -n "${FAILURES_BY_TYPE[build]}" ]; then
  BUILD_NOTE="Common causes: missing deps, TS errors, env vars, import paths, Node memory"
  echo "$BUILD_NOTE"

  # Try local builds
  if echo "$CHANGED_FILES" | grep -q "^apps/app"; then
    cd apps/app && pnpm install --silent || true
    rm -rf .next
    pnpm build || true
    cd ../..
  fi

  if echo "$CHANGED_FILES" | grep -q "^apps/marketing"; then
    cd apps/marketing && pnpm install --silent || true
    rm -rf .next
    pnpm build || true
    cd ../..
  fi

  gh pr comment "$PR_NUMBER" --body "❌ Build failures detected.

$BUILD_NOTE

Check CI logs for exact errors. Running local builds for diagnosis."
fi
```

---

## STEP 10: Analyze Test Failures

**Delegate test debugging**:

```bash
if [ -n "${FAILURES_BY_TYPE[tests]}" ]; then
  gh pr comment "$PR_NUMBER" --body "❌ Test failures detected. Delegating to debugger agent.

Run locally:
- Frontend: \`pnpm test\`
- Backend: \`pytest\`"
fi
```

---

## STEP 11: Validate Smoke Tests (Local)

**Run smoke tests if dev servers are running**:

```bash
FRONTEND_UP=false; BACKEND_UP=false

if curl -sf http://localhost:3001/health >/dev/null; then FRONTEND_UP=true; fi
if curl -sf http://localhost:8000/api/v1/health/healthz >/dev/null; then BACKEND_UP=true; fi

if [ "$FRONTEND_UP" = true ] && [ "$BACKEND_UP" = true ]; then
  # Run smoke-tagged tests
  cd apps/app && pnpm exec playwright test --grep "@smoke" --reporter=line || true; cd ../..
  cd api && pytest -m smoke --tb=short || true; cd ..
else
  gh pr comment "$PR_NUMBER" --body "⚠️ Skipped local smoke tests: dev servers not running.

Start servers first:
- Frontend: \`pnpm dev\` (port 3001)
- Backend: \`uvicorn app.main:app --reload\` (port 8000)"
fi
```

---

## STEP 12: Check Review Status

**Verify review approval**:

```bash
if [ "$PR_REVIEW" = "APPROVED" ]; then
  echo "✅ Review approved."
elif [ "$PR_REVIEW" = "CHANGES_REQUESTED" ]; then
  gh pr comment "$PR_NUMBER" --body "🔍 Changes requested in review. Delegating to senior-code-reviewer agent."
else
  echo "⏳ Review pending."
fi
```

---

## STEP 13: Update Deployment Tracking

**Ensure deployment metadata exists in feature notes**:

If `specs/$PR_HEAD/NOTES.md` doesn't have deployment metadata, add:

```markdown
## Deployment Metadata

| Date | Marketing Deploy ID | App Deploy ID | API Image Ref | Status |
|------|---------------------|---------------|---------------|--------|
| YYYY-MM-DD | [pending] | [pending] | [pending] | ⏳ Pending |
```

Commit on the feature branch if added.

---

## STEP 14: Validate Deployment Readiness Gates

**Check all gates for the current phase**:

```bash
GATES_PASSED=0; GATES_TOTAL=0

# Gate 1: CI checks
((GATES_TOTAL++)); [ "$FAILURE" -eq 0 ] && ((GATES_PASSED++))

# Gate 2: Review approval
((GATES_TOTAL++)); [ "$PR_REVIEW" = "APPROVED" ] && ((GATES_PASSED++))

# Gate 3: No merge conflicts
((GATES_TOTAL++)); [ "$PR_MERGEABLE" = "MERGEABLE" ] && ((GATES_PASSED++))

# Phase 1 specific: Smoke tests
if [ "$PHASE" -eq 1 ]; then
  ((GATES_TOTAL++))
  [ -z "${FAILURES_BY_TYPE[smoke]}" ] && ((GATES_PASSED++))
fi

# Phase 2 specific: Staging validation + deployment tracking
if [ "$PHASE" -eq 2 ]; then
  # Staging validation doc present and approved
  ((GATES_TOTAL++))
  VALIDATION_REPORT="specs/$PR_HEAD/staging-validation-report.md"
  if [ -f "$VALIDATION_REPORT" ] && grep -q "Ready for production: ✅ Yes" "$VALIDATION_REPORT" 2>/dev/null; then
    ((GATES_PASSED++))
  fi

  # Deployment metadata present
  ((GATES_TOTAL++))
  NOTES_FILE="specs/$PR_HEAD/NOTES.md"
  if [ -f "$NOTES_FILE" ] && grep -q "## Deployment Metadata" "$NOTES_FILE" 2>/dev/null; then
    ((GATES_PASSED++))
  fi
fi
```

---

## STEP 15: Post PR Status Comment

**If all gates pass**:

```bash
if [ "$GATES_PASSED" -eq "$GATES_TOTAL" ]; then
  PHASE_GATES=""
  [ "$PHASE" -eq 1 ] && PHASE_GATES="- ✅ Smoke tests passing"
  [ "$PHASE" -eq 2 ] && PHASE_GATES="- ✅ Staging validation complete
- ✅ Deployment tracking ready"

  gh pr comment "$PR_NUMBER" --body "## ✅ Ready for $ENVIRONMENT

- ✅ CI checks green
- ✅ Review approved
- ✅ No merge conflicts
$PHASE_GATES

Next: \`$NEXT_COMMAND\`"
fi
```

**If gates fail**:

```bash
if [ "$GATES_PASSED" -ne "$GATES_TOTAL" ]; then
  gh pr comment "$PR_NUMBER" --body "## ⚠️ Not ready for $ENVIRONMENT

Gates: $GATES_PASSED / $GATES_TOTAL passing

Blockers remain. See comments above for delegated items and logs."
fi
```

---

## STEP 16: Display CLI Summary

**Print concise summary**:

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary: PR #$PR_NUMBER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Phase: $PHASE ($ENVIRONMENT)"
echo "Gates: $GATES_PASSED / $GATES_TOTAL passed"
echo ""

if [ "$GATES_PASSED" -eq "$GATES_TOTAL" ]; then
  echo "✅ Ready for $ENVIRONMENT"
  echo ""
  echo "Next: $NEXT_COMMAND"
else
  echo "❌ Not ready - $((GATES_TOTAL - GATES_PASSED)) gate(s) failing"
  echo ""
  echo "Next: Address blockers, then re-run /fix-ci $PR_NUMBER"
fi
```

</process>

<success_criteria>
**CI fix workflow successfully completed when:**

1. **PR context loaded**: PR number, title, base, head, checks fetched and displayed
2. **Failures categorized**: All failing checks grouped by type (lint, types, tests, build, deploy, smoke, e2e)
3. **Auto-fixes applied**: Lint/format issues fixed and pushed if any
4. **Complex issues delegated**: Type errors, test failures, build failures delegated with clear context
5. **Gates validated**: All deployment readiness gates checked for current phase
6. **PR updated**: Status comment posted with clear next steps
7. **CLI summary displayed**: User sees concise summary with next command
8. **TodoWrite updated**: All tasks marked completed or delegated
</success_criteria>

<verification>
**Before marking /fix-ci complete, verify:**

1. **Check PR comment posted**:
   ```bash
   gh pr view $PR_NUMBER --comments | tail -20
   ```
   Should show /fix-ci generated comment

2. **Verify git operations if auto-fixes applied**:
   ```bash
   git log -1 --oneline
   ```
   Should show "fix: auto-fix lint/format via /fix-ci" if fixes were pushed

3. **Confirm check statuses reported accurately**:
   ```bash
   gh pr checks $PR_NUMBER --json name,conclusion -q '.[] | "\(.name): \(.conclusion)"'
   ```
   Should match reported status

4. **Validate gates calculation**:
   - CI checks: Quote actual FAILURE count
   - Review: Quote actual reviewDecision value
   - Mergeable: Quote actual mergeable status

**Never claim fixes succeeded without verifying check status or build output.**
</verification>

<output>
**Actions taken by this command:**

**PR analysis**:
- Loaded PR context (title, base, head, checks, files)
- Categorized failures by type
- Detected deployment phase (1 or 2)

**Auto-fixes** (if applicable):
- Ran lint --fix on changed apps/files
- Committed and pushed fixes if any changes made

**Delegations** (if applicable):
- Type errors → type-enforcer agent
- Test failures → debugger agent
- Build failures → logged for investigation
- Review changes requested → senior-code-reviewer agent

**PR comments**:
- Status comment with gate results
- Auto-fix confirmation (if fixes applied)
- Deployment quota warning (if rate limited)
- Delegation notices (if issues delegated)

**CLI output**:
- Summary with phase, gates passed/total
- Next command recommendation
</output>

---

## Notes

**Tool Requirements**:
- GitHub CLI (`gh`) - authenticated with repo access
- `jq` - JSON parsing
- `git` - version control operations
- `pnpm` - frontend package management (if frontend changes)
- `uv` - Python package management (if backend changes)
- `curl` - health check endpoints

**Phase Detection**:
- **Phase 1** (feature → staging): PR base is `main`
- **Phase 2** (staging → production): PR base is `production`

**Gate Requirements**:
- **Phase 1**: CI green, review approved, no conflicts, smoke tests pass
- **Phase 2**: CI green, review approved, no conflicts, staging validation complete, deployment metadata present

**Rate Limit Handling**: When deployment quota hit, switches to local validation and preview mode to conserve quota.
