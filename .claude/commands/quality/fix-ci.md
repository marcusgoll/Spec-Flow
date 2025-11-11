---
description: Fix CI/deployment blockers after /ship creates PR
---

Get PR ready for deployment: $ARGUMENTS

<context>
## MENTAL MODEL

**Mission:** Deployment doctor — diagnose → fix → delegate → validate.

**Scope:**
- Read PR context (checks, files, reviews, logs)
- Categorize blockers (lint, types, tests, build, deploy, smoke, e2e)
- Auto-fix simple issues (format/lint)
- Delegate complex issues (types, build, test debugging)
- Validate deployment readiness and document gates

**State awareness:**
- Base branch `main` → Phase 1 (stage to staging)
- Base branch `production` → Phase 2 (promote to production)
- Infer phase from PR base

**Deployment mode awareness:**
- **Preview mode**: debug CI and workflows safely (preferred during triage)
- **Staging mode**: updates staging domain; use only when explicitly shipping to staging
- Default to **preview** to avoid burning quotas

**Progressive disclosure:**
- Show only relevant blockers/fixes
- Link to logs; do not dump giant logs into PR
- Keep PR bot comments <30 lines

**Prerequisites:**
- GitHub CLI (`gh`) installed and authenticated
- PR exists
- Local checkout of the PR head branch (needed for auto-fixes)
</context>

<constraints>
## ANTI-HALLUCINATION RULES

1) **Never claim a fix succeeded without re-running checks**
- Always run `pnpm run lint` / `ruff check` / `mypy` / `pnpm build` and report their real exit/status lines.

2) **Quote real CI output when diagnosing**
- Use `gh pr checks --json` and workflow run logs for exact errors.
- Include the failing check name and a minimal excerpt (first relevant line).

3) **Read the PR diff before guessing root cause**
- Pull `gh pr view <n> --json files` and correlate failures to changed files.

4) **Verify check status before claiming "green"**
- After pushes, poll `gh pr checks` and report actual statuses.

5) **Don't fabricate deployment URLs/IDs**
- Only report URLs/IDs present in CI logs or `gh` output.

**Why:** Bad guesses waste time, greenwashing breaks prod, fabricated URLs are clownish.
</constraints>

<instructions>
## BLOCKER TRACKING

Use TodoWrite to track progress:

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

Rules:
- Only one `in_progress` at a time.
- Flip to `completed` immediately after verified success.
- Mark `failed` with a one-line reason and a link to logs.

---

## LOAD PR

Parse PR number and fetch context:

```bash
# If no argument, infer from current branch
if [ -z "$ARGUMENTS" ]; then
  CURRENT_BRANCH=$(git branch --show-current)
  PR_NUMBER=$(gh pr list --head "$CURRENT_BRANCH" --json number -q '.[0].number' 2>/dev/null)
  if [ -z "$PR_NUMBER" ]; then
    echo "Usage: /fix-ci pr <number>   or   /fix-ci <number>"
    exit 1
  fi
else
  if [[ "$ARGUMENTS" =~ ([0-9]+) ]]; then
    PR_NUMBER="${BASH_REMATCH[1]}"
  else
    echo "Provide a PR number."
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

---

## DETECT DEPLOYMENT PHASE

```bash
PHASE=0; ENVIRONMENT="unknown"; NEXT_COMMAND=""

if [ "$PR_BASE" = "main" ]; then
  PHASE=1; ENVIRONMENT="staging"; NEXT_COMMAND="/phase-1-ship"
  echo "Phase 1: Feature → Staging"
elif [ "$PR_BASE" = "production" ]; then
  PHASE=2; ENVIRONMENT="production"; NEXT_COMMAND="/phase-2-ship"
  echo "Phase 2: Staging → Production"
else
  echo "Unknown base: $PR_BASE (expect main or production)"; PHASE=0
fi
```

---

## READ PR CONTEXT

```bash
CHECK_DATA=$(gh pr checks "$PR_NUMBER" --json name,state,conclusion,detailsUrl 2>/dev/null || echo "[]")
TOTAL_CHECKS=$(echo "$CHECK_DATA" | jq 'length')
PENDING=$(echo "$CHECK_DATA" | jq '[.[] | select(.state=="PENDING" or .state=="QUEUED" or .state=="IN_PROGRESS")] | length')
SUCCESS=$(echo "$CHECK_DATA" | jq '[.[] | select(.conclusion=="SUCCESS")] | length')
FAILURE=$(echo "$CHECK_DATA" | jq '[.[] | select(.conclusion=="FAILURE")] | length')

CHANGED_FILES=$(gh pr view "$PR_NUMBER" --json files -q '.files[].path')
```

---

## CATEGORIZE FAILURES

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

  # If it's a deploy job, dig logs for quota/rate-limit hints
  if [ "$category" = "deploy" ] && [[ "$check_url" =~ /runs/([0-9]+) ]]; then
    RUN_ID="${BASH_REMATCH[1]}"
    if gh run view "$RUN_ID" --log 2>/dev/null | grep -qiE "rate limit|quota|Too Many Requests"; then
      RATE_LIMITED=true
    fi
  fi
done
```

---

## HANDLE DEPLOYMENT QUOTA/RATE LIMIT

If deployment jobs hit quota or rate limits, post a compact recovery guide and switch to preview-mode validation:

- Validate locally: `pnpm run ci:validate` (lint, type, build, tests)
- Use preview deployments for CI debugging; reserve staging/promote only for gates

(See Vercel "Environments" and "Deployments" docs for behavior differences and quotas.)

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

---

## AUTO-FIX LINT/FORMAT

```bash
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$PR_HEAD" ]; then
  git fetch origin "$PR_HEAD" && git checkout "$PR_HEAD"
fi

LINT_FIXED=false

# Marketing
if echo "$CHANGED_FILES" | grep -q "^apps/marketing"; then
  cd apps/marketing && pnpm install --silent || true
  pnpm lint --fix || true
  cd ../..
  LINT_FIXED=true
fi

# App
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

if [ "$LINT_FIXED" = true ] && [ -n "$(git status --porcelain)" ]; then
  git add . && git commit -m "fix: auto-fix lint/format via /fix-ci" && git push origin "$PR_HEAD"
  gh pr comment "$PR_NUMBER" --body "✅ Auto-fixed lint/format. CI re-running."
fi
```

---

## ANALYZE TYPE ERRORS

```bash
TYPE_ERRORS=false

if echo "$CHANGED_FILES" | grep -q "^apps/app"; then
  cd apps/app && pnpm install --silent || true
  pnpm run type-check || TYPE_ERRORS=true
  cd ../..
fi

if echo "$CHANGED_FILES" | grep -q "^api/"; then
  cd api
  uv run mypy app/ || TYPE_ERRORS=true
  cd ..
fi

if [ "$TYPE_ERRORS" = true ]; then
  gh pr comment "$PR_NUMBER" --body "❌ Type errors detected. Delegating to specialist."
fi
```

---

## ANALYZE BUILD FAILURES

```bash
if [ -n "${FAILURES_BY_TYPE[build]}" ]; then
  BUILD_NOTE="Common causes: missing deps, TS errors, env vars, import paths, Node memory"
  echo "$BUILD_NOTE" > /tmp/build-note.txt

  # Try local builds to reproduce
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

  gh pr comment "$PR_NUMBER" --body "❌ Build failures. Investigating. See CI logs for exact errors."
fi
```

---

## ANALYZE TEST FAILURES

```bash
if [ -n "${FAILURES_BY_TYPE[tests]}" ]; then
  gh pr comment "$PR_NUMBER" --body "❌ Test failures. Delegating to cfipros-debugger."
fi
```

---

## VALIDATE SMOKE TESTS

```bash
FRONTEND_UP=false; BACKEND_UP=false

if curl -sf http://localhost:3001/health >/dev/null; then FRONTEND_UP=true; fi
if curl -sf http://localhost:8000/api/v1/health/healthz >/dev/null; then BACKEND_UP=true; fi

if [ "$FRONTEND_UP" = true ] && [ "$BACKEND_UP" = true ]; then
  # Tag smoke tests with @smoke and run via grep
  cd apps/app && pnpm exec playwright test --grep "@smoke" --reporter=line || true; cd ../..
  cd api && pytest -m smoke --tb=short || true; cd ..
else
  gh pr comment "$PR_NUMBER" --body "⚠️ Skipped local smoke: dev servers not running."
fi
```

---

## REVIEW STATUS

```bash
if [ "$PR_REVIEW" = "APPROVED" ]; then
  echo "Review approved."
elif [ "$PR_REVIEW" = "CHANGES_REQUESTED" ]; then
  gh pr comment "$PR_NUMBER" --body "🔍 Addressing requested changes. Delegated to senior-code-reviewer."
else
  echo "Review pending."
fi
```

---

## DEPLOYMENT TRACKING

Ensure `specs/$PR_HEAD/NOTES.md` includes:

```markdown
## Deployment Metadata

| Date | Marketing Deploy ID | App Deploy ID | API Image Ref | Status |
|------|---------------------|---------------|---------------|--------|
| YYYY-MM-DD | [pending] | [pending] | [pending] | ⏳ Pending |
```

Commit on the feature branch if added.

---

## READINESS GATES

```bash
GATES_PASSED=0; GATES_TOTAL=0

# 1. CI checks
((GATES_TOTAL++)); [ "$FAILURE" -eq 0 ] && ((GATES_PASSED++))

# 2. Review
((GATES_TOTAL++)); [ "$PR_REVIEW" = "APPROVED" ] && ((GATES_PASSED++))

# 3. Merge conflicts
((GATES_TOTAL++)); [ "$PR_MERGEABLE" = "MERGEABLE" ] && ((GATES_PASSED++))

# Phase-specific
if [ "$PHASE" -eq 1 ]; then
  ((GATES_TOTAL++))
  [ -z "${FAILURES_BY_TYPE[smoke]}" ] && ((GATES_PASSED++))
fi

if [ "$PHASE" -eq 2 ]; then
  ((GATES_TOTAL++))  # Staging validation doc present and approved
  VALIDATION_REPORT="specs/$PR_HEAD/staging-validation-report.md"
  if [ -f "$VALIDATION_REPORT" ] && grep -q "Ready for production: ✅ Yes" "$VALIDATION_REPORT" 2>/dev/null; then
    ((GATES_PASSED++))
  fi

  ((GATES_TOTAL++))  # Deployment metadata present
  NOTES_FILE="specs/$PR_HEAD/NOTES.md"
  if [ -f "$NOTES_FILE" ] && grep -q "## Deployment Metadata" "$NOTES_FILE" 2>/dev/null; then
    ((GATES_PASSED++))
  fi
fi

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
else
  gh pr comment "$PR_NUMBER" --body "## ⚠️ Not ready for $ENVIRONMENT

Blockers remain. See comments above for delegated items and logs."
fi
```

---

## RETURN (CLI Summary)

Print a short CLI summary of actions taken and the "Next" command based on gate status:

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
  echo "Next: Address blockers, then re-run /fix-ci"
fi
```

</instructions>
