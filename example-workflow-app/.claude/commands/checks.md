---
description: Fix CI/deployment blockers after /ship creates PR
---

Get PR ready for deployment: $ARGUMENTS

## MENTAL MODEL

**Mission:** Deployment doctor - diagnose -> fix -> delegate -> validate

**State awareness:**
- Feature branch -> Staging readiness (Phase 1 gate)
- Staging branch -> Production readiness (Phase 2 gate)
- Auto-detect context from branch or PR base

**Progressive disclosure:**
- Show only relevant blockers and fixes
- Collapse fixed items after updates
- Link to full logs, don't dump everything

## INITIALIZE

Auto-detect PR number from arguments or current branch:

```bash
# Parse from arguments: "pr 123", "#123", "123", "review pr 123"
if [[ "$ARGUMENTS" =~ ([0-9]+) ]]; then
  PR_NUMBER="${BASH_REMATCH[1]}"
else
  # Get PR for current branch via GitHub MCP
  CURRENT_BRANCH=$(git branch --show-current)
  # mcp__github__search_pull_requests with head filter
fi
```

## READ CONTEXT

Use GitHub MCP to gather full PR context:

**Essential data:**
1. **PR metadata**  `mcp__github__get_pull_request`
   - Title, description, author, labels, base/head branches, state

2. **Check status**  `mcp__github__get_pull_request_status`
   - Check runs, conclusions, job names, workflow URLs

3. **Changed files**  `mcp__github__get_pull_request_files`
   - Paths, additions, deletions (infer affected areas)

4. **Reviews**  `mcp__github__get_pull_request_reviews` + `_review_comments`
   - Requested changes, unresolved comments

5. **Job logs (failures only)**  `mcp__github__get_job_logs`
   - `failed_only: true`, `tail_lines: 50`

## ANALYZE & FIX

### 1. Categorize Blockers

**Infer from job names and logs:**
- *Lint check*  lint errors (ESLint, Ruff)
- *Type check*  type errors (TypeScript, MyPy)
- *Tests*  test failures (Jest, Pytest)
- *Build*  compilation errors (Next.js)
- *E2E*  Playwright failures
- *Deploy*  Vercel/Railway errors
- *Smoke*  Health check failures

**Infer areas from changed files:**
- `apps/marketing/**`  marketing
- `apps/app/**`  app
- `api/**`  api

### 2. Fix or Delegate

**Auto-fix (commit directly):**
- Lint: `pnpm lint --fix` or `uv run ruff check --fix`
- Format: `pnpm format` or `uv run ruff format`
- Simple types: Add missing props, fix imports

**Delegate to agents:**
```bash
# Test failures
Task(debugger): "PR #${PR_NUMBER}: Fix test in ${FILE}
Error: ${MESSAGE}
Reproduce: ${COMMAND}"

# Backend bugs
Task(backend-dev): "PR #${PR_NUMBER}: Fix ${ENDPOINT}
Error: ${STACK_TRACE}
Files: ${FILES}"

# Frontend bugs
Task(frontend-shipper): "PR #${PR_NUMBER}: Fix ${COMPONENT}
TypeScript: ${ERROR}
Context: ${CODE}"

# Review feedback
Task(senior-code-reviewer): "PR #${PR_NUMBER}: Address review
Comments: ${FEEDBACK}
Files: ${FILES}"
```

**Deployment analysis (Vercel MCP):**
- `mcp__vercel__get_deployment`  Check build status
- `mcp__vercel__get_deployment_build_logs`  Diagnose failures
- Common issues: missing env vars, invalid config, lockfile outdated
- Suggest fixes in PR comment

### 3. Post Progress

After each fix or delegation:

```javascript
mcp__github__add_issue_comment({
  owner: "[owner]",
  repo: "monorepo",
  issue_number: PR_NUMBER,
  body: "##  Deployment Doctor Update\n\n**Fixed:**  ${FIXES}\n**In Progress:**  ${DELEGATED}\n**Remaining:**  ${BLOCKERS}\n\n---\n /checks"
})
```

### 4. Validate Readiness

**Staging readiness (from feature branch):**
-  All CI checks passing
-  Review approved (1+)
-  No merge conflicts
-  No deployment failures

**Production readiness (from staging branch):**
-  Staging validation complete (`staging-validation-report.md` with " Yes")
-  E2E tests passed on staging
-  Manual testing complete
-  All smoke tests green

Post verdict:

```markdown
##  Ready for ${ENVIRONMENT}

**All gates passed:**
-  CI checks green
-  Review approved
-  No conflicts
${PHASE_SPECIFIC_GATES}

**Next:** `/ship` ${PHASE_NOTE}

---
 /checks
```

## PRINCIPLES

**Concise output:**
- PR comments <30 lines
- Show first 3 errors per category
- Link to full logs

**Smart delegation:**
- Always delegate: test failures, complex bugs
- Never delegate: lint --fix, format, typos

**Commit strategy:**
- One commit per category: "fix: resolve ESLint errors"
- Include `/checks` in message
- Push immediately

**Safety:**
- Never force push
- Never skip CI
- Never merge (only prepare)
- Redact secrets

## INTEGRATION WITH /SHIP

**When called by /ship:**
1. /ship creates PR (Phase 1 or 2)
2. CI fails
3. /ship delegates: `/checks pr ${PR_NUMBER}`
4. /checks diagnoses and resolves
5. /checks posts verdict: ready/not ready
6. /ship continues or stops

**When to suggest /ship:**
- After all blockers resolved
- Feature branch  Phase 1 (staging)
- Staging branch  Phase 2 (production)

## RETURN

Brief summary of actions:

```
 PR #${PR_NUMBER} Status

**Actions:**
-  Auto-fixed: ${CATEGORY} (${AREA})
-  Delegated: ${CATEGORY} to ${AGENT}
-  Posted: Progress comment

**Verdict:** ${READY_STATUS}
**Next:** ${NEXT_STEP}
```



