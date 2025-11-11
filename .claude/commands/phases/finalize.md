---
description: Post-deploy documentation + housekeeping
internal: true
version: 2.0
updated: 2025-11-10
---

# /finalize — Complete Documentation & Cleanup After Deployment

**Purpose**
Finalize docs, roadmap, and housekeeping after a **successful production deployment**.

**Dependencies**
- A finished prod deploy (`/ship` → `deploy-prod`), with `workflow-state.yaml` containing:
  - `feature.title`, `feature.slug`
  - `deployment.production.url`
  - `deployment.production.run_id` (for linking logs)
  - `version` (MAJOR.MINOR.PATCH)

**Execution model**
- **Idempotent**: safe to re-run; completed tasks are skipped
- **Deterministic**: no prompts, no editors
- **Tracked**: every step mirrored in **TodoWrite**

---

## MENTAL MODEL

You are a **post-deployment finalizer** that updates documentation and housekeeping with zero manual intervention.

**Philosophy**: Deployment is not done until the docs are updated, roadmap is current, and branches are cleaned. Finalize automates this paperwork using industry standards.

**Standards**:
- **Changelog**: Keep a Changelog format
- **Versioning**: Semantic Versioning (SemVer)
- **Badges**: Shields.io static badges
- **GitHub**: Official gh CLI and REST API

**Token efficiency**: No prompts, no editors, pure automation. TodoWrite tracks every step for resumability.

---

## PRECONDITIONS

```bash
# Required CLIs
for c in gh jq yq git; do
  command -v "$c" >/dev/null || { echo "❌ missing: $c"; exit 1; }
done

# Auth must be valid
gh auth status >/dev/null || { echo "❌ gh not authenticated"; exit 1; }
```

**Reference**: `gh auth status` verifies CLI authentication before any API use ([GitHub CLI Manual](https://cli.github.com/manual/gh_auth_status))

---

## STEP 0 — Initialize & Create Todo List (MANDATORY)

**CRITICAL**: Create TodoWrite list **IMMEDIATELY** to track all finalization tasks.

```js
TodoWrite({
  todos: [
    { content: "Load feature context and version info", status: "completed", activeForm: "Loading context" },
    { content: "Update CHANGELOG.md", status: "pending", activeForm: "Updating CHANGELOG.md" },
    { content: "Update README.md (version badge + features)", status: "pending", activeForm: "Updating README.md" },
    { content: "Generate user docs (help article)", status: "pending", activeForm: "Generating help article" },
    { content: "Update API docs (if endpoints changed)", status: "pending", activeForm: "Updating API docs" },
    { content: "Close current milestone", status: "pending", activeForm: "Closing milestone" },
    { content: "Create next milestone", status: "pending", activeForm: "Creating next milestone" },
    { content: "Update roadmap issue to 'shipped'", status: "pending", activeForm: "Updating roadmap issue" },
    { content: "Commit & push documentation changes", status: "pending", activeForm: "Committing documentation" },
    { content: "Cleanup feature branch (safe)", status: "pending", activeForm: "Cleaning up branch" }
  ]
})
```

**Load context**:

```bash
FEATURE_DIR="$(ls -td specs/*/ | head -1)"
STATE="${FEATURE_DIR%/}/workflow-state.yaml"

TITLE="$(yq -r '.feature.title' "$STATE")"
SLUG="$(yq -r '.feature.slug'  "$STATE")"
PROD_URL="$(yq -r '.deployment.production.url // ""' "$STATE")"
VERSION="$(yq -r '.version' "$STATE")"     # e.g., 1.3.0
```

---

## STEP 1 — CHANGELOG.md (Keep a Changelog + SemVer)

**Standard**: Follow [Keep a Changelog](https://keepachangelog.com/) and [Semantic Versioning](https://semver.org/)

```bash
DATE="$(date +%F)"
CHANGELOG="CHANGELOG.md"

# Create if missing
[[ -f $CHANGELOG ]] || cat > $CHANGELOG <<'EOF'
# Changelog

All notable changes to this project will be documented in this file.

This format follows [Keep a Changelog](https://keepachangelog.com/)
and this project adheres to [Semantic Versioning](https://semver.org/).
EOF

# Collect notable commits since last tag or last version line
LAST_TAG="$(git describe --tags --abbrev=0 2>/dev/null || true)"
RANGE="${LAST_TAG:+${LAST_TAG}..HEAD}"

ADDED="$(git log --pretty='- %s' --grep='^feat:'  $RANGE)"
FIXED="$(git log --pretty='- %s' --grep='^fix:'   $RANGE)"
CHANGED="$(git log --pretty='- %s' --grep='^refactor:' $RANGE)"
SECURITY="$(git log --pretty='- %s' --grep='^security:' $RANGE)"

# Prepend new section
TMP="$(mktemp)"
{
  echo "## [v${VERSION}] - ${DATE}"
  [[ -n "$ADDED" ]]    && { echo ""; echo "### Added"; echo "$ADDED"; }
  [[ -n "$FIXED" ]]    && { echo ""; echo "### Fixed"; echo "$FIXED"; }
  [[ -n "$CHANGED" ]]  && { echo ""; echo "### Changed"; echo "$CHANGED"; }
  [[ -n "$SECURITY" ]] && { echo ""; echo "### Security"; echo "$SECURITY"; }
  echo ""
  cat "$CHANGELOG"
} > "$TMP" && mv "$TMP" "$CHANGELOG"
```

**After completion**:
- **Update TodoWrite**: Mark "Update CHANGELOG.md" as `completed`
- Mark "Update README.md" as `in_progress`

---

## STEP 2 — README.md (Version Badge + Features)

**Standard**: Use [Shields.io](https://shields.io/) static badges

```bash
README="README.md"
[[ -f $README ]] || touch $README

# Ensure a version badge exists (idempotent replace or append)
grep -q 'img.shields.io/badge/version-' "$README" \
  && sed -i 's#img.shields.io/badge/version-[^)]*#img.shields.io/badge/version-v'"$VERSION"'-blue#g' "$README" \
  || sed -i '1i ![Version](https://img.shields.io/badge/version-v'"$VERSION"'-blue)\n' "$README"

# Append feature line (once)
LINE=" - 🎉 **${TITLE}** — shipped in v${VERSION}"
grep -qF "$LINE" "$README" || {
  # Ensure Features section exists
  grep -q "^## Features" "$README" || printf "\n## Features\n" >> "$README"
  # Add feature below Features heading
  sed -i "/^## Features/a $LINE" "$README"
}
```

**After completion**:
- **Update TodoWrite**: Mark "Update README.md" as `completed`
- Mark "Generate user docs" as `in_progress`

---

## STEP 3 — User Docs (Help Article)

```bash
DOC_DIR="docs/help/features"
mkdir -p "$DOC_DIR"
DOC_FILE="${DOC_DIR}/${SLUG}.md"

cat > "$DOC_FILE" <<EOF
# ${TITLE}

**Version**: v${VERSION}
**Released**: ${DATE}

## Overview

Short summary (from spec.md).

## How to Use

Step-by-step (from user stories).

## Features

- Pulled from acceptance criteria.

## Screenshots

<!-- Add or link assets -->

## Troubleshooting

Common issues and resolutions.
EOF

# Ensure index exists and link entry
INDEX="docs/help/README.md"
mkdir -p "$(dirname "$INDEX")"
grep -q "features/${SLUG}.md" "$INDEX" 2>/dev/null || {
  [[ -f "$INDEX" ]] || echo "# Help Documentation" > "$INDEX"
  printf "\n## Features\n\n- [%s](features/%s.md) — v%s\n" "$TITLE" "$SLUG" "$VERSION" >> "$INDEX"
}
```

**After completion**:
- **Update TodoWrite**: Mark "Generate user docs" as `completed`
- Mark "Update API docs" as `in_progress`

---

## STEP 4 — API Docs (Conditional)

```bash
# Heuristic: if spec/plan mentioned API changes, update docs/API_ENDPOINTS.md
if rg -n "API|endpoint|route" "$FEATURE_DIR/spec.md" "$FEATURE_DIR/plan.md" >/dev/null 2>&1; then
  APIDOC="docs/API_ENDPOINTS.md"
  mkdir -p "$(dirname "$APIDOC")"
  [[ -f "$APIDOC" ]] || echo "# API Endpoints" > "$APIDOC"

  # Append/update a minimal endpoint block (ensure no duplicates)
  BLOCK="### ${TITLE} (v${VERSION})"
  grep -qF "$BLOCK" "$APIDOC" || cat >> "$APIDOC" <<EOF

${BLOCK}

- **Method**: [GET|POST|PUT|DELETE]
- **Path**: /api/[endpoint]
- **Auth**: [Required|Optional]
- **Request**: [Body schema]
- **Response**: [Response schema]

EOF
else
  echo "ℹ️  No API changes detected, skipping API documentation"
fi
```

**After completion**:
- **Update TodoWrite**: Mark "Update API docs" as `completed` (even if skipped)
- Mark "Close current milestone" as `in_progress`

---

## STEP 5 — Milestones (Close Current, Create Next)

**Reference**: Uses [GitHub REST milestones API](https://docs.github.com/en/rest/issues/milestones) via `gh api`

```bash
# Close current (best-effort; non-blocking if absent)
CUR_MINOR="$(echo "$VERSION" | awk -F. '{print $1"."$2}')"
CUR_MS_JSON="$(gh api repos/:owner/:repo/milestones --jq '.[] | select(.title | test("^v?'$CUR_MINOR'\\.x$"))' 2>/dev/null || true)"

if [[ -n "$CUR_MS_JSON" ]]; then
  CUR_MS_NUM="$(jq -r '.number' <<<"$CUR_MS_JSON")"
  echo "Closing milestone #${CUR_MS_NUM} (v${CUR_MINOR}.x)"
  gh api -X PATCH "repos/:owner/:repo/milestones/$CUR_MS_NUM" -f state=closed >/dev/null 2>&1 || true
else
  echo "ℹ️  No milestone found for v${CUR_MINOR}.x"
fi

# Create next minor (e.g., 1.3.0 -> 1.4.0)
NEXT_MINOR="$(echo "$VERSION" | awk -F. '{printf "%d.%d.0", $1, $2+1}')"
DUE_ON="$(date -u -d '+14 days' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v+14d +%Y-%m-%dT%H:%M:%SZ)"

echo "Creating next milestone: v${NEXT_MINOR} (due: ${DUE_ON})"
gh api repos/:owner/:repo/milestones \
  -f title="v$NEXT_MINOR" \
  -f due_on="$DUE_ON" \
  >/dev/null 2>&1 || echo "ℹ️  Milestone v${NEXT_MINOR} already exists or creation failed"
```

**After completion**:
- **Update TodoWrite**: Mark "Close current milestone" and "Create next milestone" as `completed`
- Mark "Update roadmap issue" as `in_progress`

---

## STEP 6 — Roadmap Issue → Shipped

**Reference**: Uses [gh issue](https://cli.github.com/manual/gh_issue) commands

```bash
ISSUE_JSON="$(gh issue list --label 'type:feature' --search "slug: ${SLUG}" --json number --limit 1 2>/dev/null || true)"
NUM="$(jq -r '.[0].number // empty' <<<"$ISSUE_JSON")"

if [[ -n "$NUM" ]]; then
  echo "Updating roadmap issue #${NUM} to 'shipped'"

  gh issue edit "$NUM" \
    --add-label "status:shipped" \
    --remove-label "status:in-progress" \
    >/dev/null 2>&1 || true

  gh issue comment "$NUM" --body "$(cat <<TXT
🚀 Shipped in v${VERSION} on ${DATE}

**Production**: ${PROD_URL:-N/A}

See [release notes](https://github.com/:owner/:repo/releases/tag/v${VERSION})
TXT
)" >/dev/null 2>&1 || true
else
  echo "ℹ️  No roadmap issue found for slug: ${SLUG}"
fi
```

**After completion**:
- **Update TodoWrite**: Mark "Update roadmap issue" as `completed`
- Mark "Commit & push documentation" as `in_progress`

---

## STEP 7 — Commit & Push Docs

```bash
git add CHANGELOG.md README.md docs/ 2>/dev/null || true

if git diff --cached --quiet; then
  echo "ℹ️  No documentation changes to commit"
else
  git commit -m "docs: finalize v${VERSION} documentation

- Update CHANGELOG.md with v${VERSION} section
- Update README.md version badge and features list
- Add help article for ${TITLE}
- Update API documentation (conditional)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" || true

  git push || echo "⚠️  Push failed (may need to pull first)"
fi
```

**After completion**:
- **Update TodoWrite**: Mark "Commit & push documentation" as `completed`
- Mark "Cleanup feature branch" as `in_progress`

---

## STEP 8 — Branch Cleanup (Safe)

```bash
# Only delete if merged and not checked out
FEATURE_BRANCH="$(yq -r '.workflow.git.feature_branch // ""' "$STATE")"

if [[ -n "$FEATURE_BRANCH" ]]; then
  CURRENT="$(git branch --show-current)"

  # Switch to main if on feature branch
  if [[ "$CURRENT" == "$FEATURE_BRANCH" ]]; then
    git checkout -q main 2>/dev/null || git checkout -q master 2>/dev/null || true
  fi

  # Only delete if fully merged (safe)
  if git branch --merged | grep -q " ${FEATURE_BRANCH}$"; then
    echo "Deleting merged branch: ${FEATURE_BRANCH}"
    git branch -d "$FEATURE_BRANCH" 2>/dev/null || true
    git push origin --delete "$FEATURE_BRANCH" >/dev/null 2>&1 || true
  else
    echo "ℹ️  Branch ${FEATURE_BRANCH} not fully merged, skipping deletion"
  fi
else
  echo "ℹ️  No feature branch to clean up"
fi
```

**After completion**:
- **Update TodoWrite**: Mark "Cleanup feature branch" as `completed`

---

## STEP 9 — Summary

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 Finalization Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Version: v${VERSION}
Feature: ${SLUG}
Date: ${DATE}

### Files Updated

- ✅ CHANGELOG.md (Keep a Changelog format)
- ✅ README.md (Shields.io badge + features)
- ✅ docs/help/features/${SLUG}.md (help article)
- ✅ docs/API_ENDPOINTS.md (conditional)

### GitHub

- ✅ Closed milestone: v${CUR_MINOR}.x
- ✅ Created next milestone: v${NEXT_MINOR} (due: [date])
- ✅ Updated roadmap issue to "shipped" (if found)

### Git

- ✅ Committed documentation changes
- ✅ Pushed to main
- ✅ Cleaned up feature branch (if merged)

### Next Steps

1. Review documentation accuracy
2. Announce release (social media, blog, email)
3. Monitor user feedback and error logs
4. Plan next feature from roadmap

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Full workflow complete: /feature → /ship → /finalize ✅
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Deployment logs: gh run view $(yq -r '.deployment.production.run_id // "N/A"' "$STATE") --log
```

---

## ERROR RECOVERY

**Idempotency**: Re-running `/finalize` is safe. Completed tasks are skipped based on TodoWrite state.

**If any step fails**:

1. **Update TodoWrite**: Keep failed task as `in_progress`
2. Display specific error with fix instructions
3. User runs `/finalize` again to resume

**Example error handling**:

```bash
# If git push fails
if ! git push; then
  echo "❌ Git push failed"
  echo ""
  echo "Likely cause: Need to pull changes first"
  echo "Fix: git pull --rebase && /finalize"
  exit 1
fi
```

**GitHub API safety**:

- All `gh` commands use `|| true` to avoid blocking entire workflow
- Optional steps (milestones, roadmap) are logged but don't fail finalization
- Rate limiting is handled gracefully with warnings

**Branch cleanup safety**:

- Uses `-d` (safe delete) not `-D` (force delete)
- Only deletes if `git branch --merged` confirms merge
- Never deletes if unmerged changes exist

---

## CONSTRAINTS

**TodoWrite discipline**:

- Create list at Step 0 (before any work)
- Update after EVERY step completion
- Mark as `completed` only if operation succeeded
- Mark as `completed` (with note) if optional step skipped

**Standards compliance**:

- CHANGELOG: [Keep a Changelog](https://keepachangelog.com/)
- Versioning: [Semantic Versioning](https://semver.org/)
- Badges: [Shields.io](https://shields.io/)
- GitHub: Official [gh CLI](https://cli.github.com/manual/) and [REST API](https://docs.github.com/en/rest)

**No prompts**:

- All operations are deterministic
- No editors (vi, nano, etc.)
- No user input required
- Safe to run in CI/CD

**Idempotency**:

- Safe to re-run multiple times
- Completed tasks are skipped
- Duplicate prevention (grep -q checks)
- Best-effort operations with graceful degradation

---

## NOTES

**Workflow dispatch**: If you later auto-trigger releases via GitHub Actions, the target workflow must declare `on: workflow_dispatch`. Use `gh workflow run` and `gh run watch` to dispatch and monitor ([gh workflow run](https://cli.github.com/manual/gh_workflow_run)).

**Milestone discovery**: Assumes milestones are named `vX.Y.x` (e.g., `v1.2.x`). Adjust regex in Step 5 if using different naming.

**Date format**: Uses ISO-8601 (`YYYY-MM-DD`) for CHANGELOG dates per Keep a Changelog standard.

**Artifact linking**: Production deployment logs can be viewed via `gh run view <run-id> --log` using the `run_id` from `workflow-state.yaml`.
