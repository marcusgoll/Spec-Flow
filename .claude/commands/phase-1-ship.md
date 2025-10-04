---
description: Ship feature to staging with auto-merge
---

Ship feature to staging: $ARGUMENTS

## MENTAL MODEL

**Workflow**: spec-flow -> clarify -> plan -> tasks -> analyze -> implement -> optimize -> preview -> **phase-1-ship** -> validate-staging -> phase-2-ship

**State machine:**`n- Validate -> Create PR -> Enable auto-merge -> Wait for CI -> Report -> Next

**Auto-suggest:**
- After auto-merge  `/validate-staging`
- If CI fails  `/checks pr [number]`

## DETECT FEATURE

```bash
CURRENT_BRANCH=$(git branch --show-current)
FEATURE=$(echo "$CURRENT_BRANCH" | sed 's/^[0-9]*-//')
SPEC_DIR=$(find specs/ -maxdepth 1 -name "*${FEATURE}*" -type d | head -n 1)
```

## PRE-FLIGHT VALIDATION

### 1. Validate Current State

```bash
# Cannot ship from staging or main
if [[ "$CURRENT_BRANCH" == "staging" ]] || [[ "$CURRENT_BRANCH" == "main" ]]; then
  echo "Error: phase-1-ship runs from feature branches only"
  echo "Current branch: $CURRENT_BRANCH"
  echo ""
  echo "From staging -> use `/phase-2-ship`"
  exit 1
fi

# Check clean working tree
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: Uncommitted changes detected"
  echo "Commit or stash changes before shipping"
  exit 1
fi

# Validate optimization complete
if ! grep -q "Phase 5 (Optimize): Completed" "$SPEC_DIR/NOTES.md" 2>/dev/null; then
  echo "Error: /optimize not completed"
  echo "Run /optimize before shipping"
  exit 1
fi

# Check for existing PR
EXISTING_PR=$(gh pr list --head "$CURRENT_BRANCH" --json number --jq '.[0].number')
if [[ -n "$EXISTING_PR" ]]; then
  echo "Error: PR already exists (#$EXISTING_PR)"
  echo "Either:"
  echo "  1. Close PR and re-run /phase-1-ship"
  echo "  2. Use /checks pr $EXISTING_PR to fix failures"
  exit 1
fi
```

### 2. Load Metadata

```bash
# Extract feature info from spec.md
TITLE=$(grep "^# " "$SPEC_DIR/spec.md" | head -n 1 | sed 's/^# //')
SUMMARY=$(grep -A 5 "## Summary" "$SPEC_DIR/spec.md" | tail -n 4)

# Get optimization results
OPT_REPORT="$SPEC_DIR/artifacts/optimization-report.md"
```

## CREATE PULL REQUEST

### Generate PR Body

```markdown
##  Phase 1: Deploy to Staging

**Feature**: $TITLE

### Summary

$SUMMARY

### Optimization Results

Performance: [extract from $OPT_REPORT]
Security: [extract from $OPT_REPORT]
Accessibility: [extract from $OPT_REPORT]
Code Quality: [extract from $OPT_REPORT]

### Staging Deployment

After merge, this will deploy to:
- **Marketing**: https://<staging marketing url>
- **App**: https://app.<staging marketing url>
- **API**: https://api.<staging marketing url>

### CI/CD Checks

Auto-merge enabled. PR will merge automatically when:
-  Deploy to staging succeeds
-  Smoke tests pass
-  Lighthouse CI passes (Performance >90, A11y >95)
-  E2E tests pass

### Next Steps

1.  Auto-merge when checks pass
2. Manual validation: `/validate-staging`
3. Production: `/phase-2-ship` (from staging branch)

---
 Generated with [Claude Code](https://claude.com/claude-code)
```

### Create PR via GitHub MCP

```javascript
// Push current branch
git push -u origin $CURRENT_BRANCH

// Create PR
const pr = await mcp__github__create_pull_request({
  owner: "<github-owner>",  // or extract from git remote
  repo: "monorepo",
  title: `feat: ${TITLE} (Staging)`,
  head: CURRENT_BRANCH,
  base: "staging",
  body: [generated body above]
})

const PR_NUMBER = pr.number
const PR_URL = pr.html_url
```

## ENABLE AUTO-MERGE

Use the helper script for your platform:
> POSIX users: run `.spec-flow/scripts/bash/enable-auto-merge.sh` with the same arguments.

```powershell
$result = & .spec-flow/scripts/powershell/enable-auto-merge.ps1 `
  -Owner "<github-owner>" `
  -Repo "monorepo" `
  -PRNumber $PR_NUMBER `
  -MergeMethod "squash" `
  -Json

if ($result.success) {
  Write-Output " Auto-merge enabled on PR #$PR_NUMBER"
} else {
  Write-Output "  Auto-merge failed: $($result.error)"
  Write-Output "PR will require manual merge"
}
```

## WAIT FOR CI (Token-Efficient)

Use the wait script for your platform:
> POSIX users: run `.spec-flow/scripts/bash/wait-for-ci.sh` with the same arguments.

```powershell
Write-Output " Waiting for CI checks to complete..."
Write-Output "PR: $PR_URL"
Write-Output ""
Write-Output "Polling every 30s (token-efficient sleep)..."

$ciResult = & .spec-flow/scripts/powershell/wait-for-ci.ps1 `
  -Owner "<github-owner>" `
  -Repo "monorepo" `
  -PRNumber $PR_NUMBER `
  -Timeout 1200 `  # 20 minutes
  -Json

# Parse result
if ($ciResult.status -eq "SUCCESS") {
  Write-Output ""
  Write-Output " All CI checks passed!"
  Write-Output "PR #$PR_NUMBER auto-merged to staging"

  # Deployment starts automatically
  Write-Output ""
  Write-Output " Staging deployment in progress..."
  Write-Output "  Marketing: ${STAGING_MARKETING_URL:-<staging marketing url>}"
  Write-Output "  App: ${STAGING_APP_URL:-<staging app url>}"
  Write-Output "  API: ${STAGING_API_URL:-<staging api url>}"

} elseif ($ciResult.status -eq "FAILURE") {
  Write-Output ""
  Write-Output " CI checks failed"
  Write-Output "Failed checks: $($ciResult.failedChecks -join ', ')"
  Write-Output ""
  Write-Output "Next: /checks pr $PR_NUMBER to debug"
  exit 1

} else {
  Write-Output ""
  Write-Output "  Timeout: CI checks taking too long (>20 min)"
  Write-Output "Check manually: $PR_URL"
  exit 1
}
```

## CREATE STAGING SHIP REPORT

```bash
mkdir -p "$SPEC_DIR/artifacts"

cat > "$SPEC_DIR/artifacts/staging-ship-report.md" << EOF
# Staging Deployment Report

**Date**: $(date +%Y-%m-%d\ %H:%M)
**Feature**: $TITLE
**PR**: #$PR_NUMBER
**Branch**: $CURRENT_BRANCH  staging

## Deployment

**Status**:  Deployed to staging
**URLs**:
- Marketing: [staging marketing URL]
- App: [staging app URL]
- API: [staging API URL]

## CI/CD Results

**Auto-merge**:  Enabled
**Merge time**: [extract from GitHub API]
**CI duration**: [calculate from wait script]

### Checks Passed

-  Deploy to staging
-  Smoke tests
-  Lighthouse CI (Performance: XX, A11y: XX)
-  E2E tests

## Optimization Summary

[Copy from optimization-report.md]

## Next Steps

1. **Manual validation**: Run \`/validate-staging\`
2. **Production deploy**: After validation, run \`/phase-2-ship\` from staging branch

---
Generated by \`/phase-1-ship\`
EOF
```

## UPDATE NOTES.MD

```bash
cat >> "$SPEC_DIR/NOTES.md" << EOF

## Checkpoints
-  Phase 7 (Ship Staging): $(date +%Y-%m-%d)
  - PR: #$PR_NUMBER
  - Auto-merge: Enabled
  - CI passed: [duration]
  - Deployed: staging

## Context Budget
- Phase 7: N tokens

## Last Updated
$(date -Iseconds)
EOF
```

## GIT COMMIT

```bash
git add "$SPEC_DIR/"
git commit -m "integration:ship-staging: deploy to staging environment

PR: #$PR_NUMBER
Auto-merge: Enabled
CI checks: Passed
Deployed to: <staging marketing url>

Next: Manual validation via /validate-staging

 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push origin "$CURRENT_BRANCH"
```

## RETURN

Brief summary:
```
Phase 1: Feature  Staging Complete

PR: #$PR_NUMBER
URL: $PR_URL

Auto-merge:  Enabled
CI checks:  Passed
Merged to: staging

Staging deployment:
- Marketing: [staging marketing URL]
- App: [staging app URL]
- API: [staging API URL]

Report: $SPEC_DIR/artifacts/staging-ship-report.md

Next: /validate-staging
```





