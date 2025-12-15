#!/usr/bin/env bash
set -Eeuo pipefail

# Feature workflow orchestration script
# Handles argument parsing, GitHub issue selection, and phase execution

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$REPO_ROOT"

# Parse command line arguments
ARGUMENTS="${1:-}"

if [ -z "$ARGUMENTS" ]; then
  echo "Usage: /feature [slug | \"feature description\" | continue | next | epic:<name> | epic:<name>:sprint:<num> | sprint:<num>]"
  echo ""
  echo "Examples:"
  echo "  /feature next                    - Next priority issue"
  echo "  /feature epic:aktr               - Next issue from epic (auto-selects incomplete sprint)"
  echo "  /feature epic:aktr:sprint:S02    - Specific sprint in epic"
  echo "  /feature sprint:S01              - Next issue from any sprint S01"
  echo "  /feature continue                - Resume last feature"
  exit 1
fi

MODE=""
SEARCH_TERM=""
CONTINUE_MODE=false
NEXT_MODE=false
EPIC_FILTER=""
SPRINT_FILTER=""
SLUG=""
FEATURE_DESCRIPTION=""
ISSUE_NUMBER=""

case "$ARGUMENTS" in
  continue)
    CONTINUE_MODE=true
    MODE="continue"
    ;;
  next)
    NEXT_MODE=true
    MODE="next"
    ;;
  epic:*:sprint:*)
    # Extract epic and sprint from epic:aktr:sprint:S02
    EPIC_FILTER=$(echo "$ARGUMENTS" | sed -n 's/^epic:\([^:]*\):sprint:.*/\1/p')
    SPRINT_FILTER=$(echo "$ARGUMENTS" | sed -n 's/^epic:[^:]*:sprint:\(.*\)/\1/p')
    MODE="epic-sprint"
    ;;
  epic:*)
    # Extract epic from epic:aktr
    EPIC_FILTER="${ARGUMENTS#epic:}"
    MODE="epic"
    ;;
  sprint:*)
    # Extract sprint from sprint:S01
    SPRINT_FILTER="${ARGUMENTS#sprint:}"
    MODE="sprint"
    ;;
  *)
    SEARCH_TERM="$ARGUMENTS"
    MODE="lookup"
    ;;
esac

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CONTINUE LAST FEATURE (MODE=continue)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ "$CONTINUE_MODE" = true ]; then
  # Find most recently modified feature directory (cross-platform)
  if [ ! -d "specs" ]; then
    echo "❌ No specs/ directory found"
    exit 1
  fi

  LAST_FEATURE=$(ls -td specs/[0-9]*-* 2>/dev/null | head -1)

  if [ -z "$LAST_FEATURE" ]; then
    echo "❌ No existing features found in specs/"
    exit 1
  fi

  SLUG=$(basename "$LAST_FEATURE" | sed 's/^[0-9]*-//')
  FEATURE_DESCRIPTION=$(grep -m1 "^# " "$LAST_FEATURE/spec.md" 2>/dev/null | sed 's/^# //' || echo "$SLUG")

  echo "📋 Continuing last feature: $SLUG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Feature: $FEATURE_DESCRIPTION"
  echo "  Directory: $LAST_FEATURE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# FETCH NEXT FEATURE (MODE=next)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ "$NEXT_MODE" = true ]; then
  gh auth status >/dev/null || { echo "❌ gh not authenticated. Run: gh auth login"; exit 1; }
  REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner) || { echo "❌ Not in a GitHub repo"; exit 1; }

  JSON=$(gh issue list --repo "$REPO" --label "status:next,type:feature" --json number,title,body,labels --limit 50)
  if [ -z "$JSON" ] || [ "$JSON" = "[]" ]; then
    JSON=$(gh issue list --repo "$REPO" --label "status:backlog,type:feature" --json number,title,body,labels --limit 50)
  fi
  [ -z "$JSON" ] && { echo "❌ No next/backlog items"; exit 1; }

  # Pick first issue (GitHub returns in creation order)
  ISSUE=$(echo "$JSON" | jq -r 'first')

  ISSUE_NUMBER=$(echo "$ISSUE" | jq -r .number)
  ISSUE_TITLE=$(echo "$ISSUE" | jq -r .title)
  ISSUE_BODY=$(echo "$ISSUE" | jq -r '.body // ""')

  # Claim immediately to avoid race conditions
  gh issue edit "$ISSUE_NUMBER" --remove-label "status:next" --remove-label "status:backlog" --add-label "status:in-progress" --repo "$REPO" >/dev/null || true

  SLUG=$(echo "$ISSUE_BODY" | grep -oP '^slug:\s*"\K[^"]+' | head -1)
  if [ -z "$SLUG" ]; then
    SLUG=$(echo "$ISSUE_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g;s/--*/-/g;s/^-//;s/-$//' | cut -c1-20)
  fi

  FEATURE_DESCRIPTION="$ISSUE_TITLE"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LOOKUP FEATURE (MODE=lookup)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ "$MODE" = "lookup" ] && [ -n "$SEARCH_TERM" ]; then
  # Check if GitHub is available (optional for local-only workflows)
  GH_AVAILABLE=false
  if gh auth status >/dev/null 2>&1; then
    if gh repo view --json nameWithOwner --jq .nameWithOwner >/dev/null 2>&1; then
      GH_AVAILABLE=true
      REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
    fi
  fi

  if [ "$GH_AVAILABLE" = true ]; then
    # Try to find matching GitHub issue
    MATCH=$(gh issue list --repo "$REPO" --label "type:feature" --json number,title,body,labels --limit 100 |
      jq -r --arg term "$SEARCH_TERM" '
        map(select((.body | test("slug:\\s*\"" + $term + "\"")) or (.title | ascii_downcase | contains($term | ascii_downcase)))) | first')

    if [ -n "$MATCH" ] && [ "$MATCH" != "null" ]; then
      ISSUE_NUMBER=$(echo "$MATCH" | jq -r .number)
      ISSUE_TITLE=$(echo "$MATCH" | jq -r .title)
      ISSUE_BODY=$(echo "$MATCH" | jq -r '.body // ""')
      gh issue edit "$ISSUE_NUMBER" --remove-label "status:next" --remove-label "status:backlog" --add-label "status:in-progress" --repo "$REPO" >/dev/null || true
      SLUG=$(echo "$ISSUE_BODY" | grep -oP '^slug:\s*"\K[^"]+' | head -1)
      [ -z "$SLUG" ] && SLUG=$(echo "$ISSUE_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g;s/--*/-/g;s/^-//;s/-$//' | cut -c1-30)
      FEATURE_DESCRIPTION="$ISSUE_TITLE"
    else
      # No matching issue found - use search term as description (local-only mode)
      echo "ℹ️  No matching roadmap item found. Creating local feature..."
      FEATURE_DESCRIPTION="$SEARCH_TERM"
    fi
  else
    # GitHub not available - local-only workflow
    echo "ℹ️  GitHub not available. Creating local feature..."
    FEATURE_DESCRIPTION="$SEARCH_TERM"
  fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# EPIC/SPRINT SELECTION (MODE=epic, epic-sprint, sprint)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [[ "$MODE" == "epic" || "$MODE" == "epic-sprint" || "$MODE" == "sprint" ]]; then
  gh auth status >/dev/null || { echo "❌ gh not authenticated. Run: gh auth login"; exit 1; }
  REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner) || { echo "❌ Not in a GitHub repo"; exit 1; }

  # Build label filter based on mode
  LABEL_FILTER="type:feature"

  if [ -n "$EPIC_FILTER" ]; then
    LABEL_FILTER="$LABEL_FILTER,epic:$EPIC_FILTER"
  fi

  if [ "$MODE" = "epic-sprint" ] && [ -n "$SPRINT_FILTER" ]; then
    LABEL_FILTER="$LABEL_FILTER,sprint:$SPRINT_FILTER"
  fi

  if [ "$MODE" = "sprint" ] && [ -n "$SPRINT_FILTER" ]; then
    LABEL_FILTER="$LABEL_FILTER,sprint:$SPRINT_FILTER"
  fi

  echo "🔍 Searching for issues with labels: $LABEL_FILTER"
  echo ""

  # Fetch issues
  JSON=$(gh issue list --repo "$REPO" --label "$LABEL_FILTER" --json number,title,body,labels,state --limit 100)

  if [ -z "$JSON" ] || [ "$JSON" = "[]" ]; then
    if [ "$MODE" = "epic" ]; then
      # Check if epic has any issues (without sprint filter)
      EPIC_JSON=$(gh issue list --repo "$REPO" --label "type:feature,epic:$EPIC_FILTER" --json number,labels --limit 100)

      if [ -z "$EPIC_JSON" ] || [ "$EPIC_JSON" = "[]" ]; then
        echo "❌ No issues found with label epic:$EPIC_FILTER"
        echo "   Create epic label: gh label create \"epic:$EPIC_FILTER\" --description \"Epic: $EPIC_FILTER\" --color \"5319e7\""
        exit 1
      fi

      # Epic exists but no sprint labels - auto-create sprint:S01
      echo "✨ No sprints found in epic:$EPIC_FILTER - auto-creating sprint:S01"

      # Get all issue numbers in epic
      ISSUE_NUMBERS=$(echo "$EPIC_JSON" | jq -r '.[].number')

      # Bulk-assign to sprint:S01
      for ISSUE_NUM in $ISSUE_NUMBERS; do
        gh issue edit "$ISSUE_NUM" --add-label "sprint:S01" --repo "$REPO" >/dev/null 2>&1 || true
      done

      echo "✅ Assigned $(echo "$ISSUE_NUMBERS" | wc -w) issues to sprint:S01"
      echo ""

      # Re-fetch with sprint filter
      SPRINT_FILTER="S01"
      LABEL_FILTER="type:feature,epic:$EPIC_FILTER,sprint:S01"
      JSON=$(gh issue list --repo "$REPO" --label "$LABEL_FILTER" --json number,title,body,labels,state --limit 100)
    else
      echo "❌ No issues found with labels: $LABEL_FILTER"
      exit 1
    fi
  fi

  # Auto-detect next incomplete sprint if MODE=epic (no explicit sprint specified)
  if [ "$MODE" = "epic" ] && [ -z "$SPRINT_FILTER" ]; then
    # Extract unique sprint labels from all epic issues
    ALL_EPIC_ISSUES=$(gh issue list --repo "$REPO" --label "type:feature,epic:$EPIC_FILTER" --json labels --limit 100)
    SPRINTS=$(echo "$ALL_EPIC_ISSUES" | jq -r '.[].labels[] | select(.name | startswith("sprint:")) | .name' | sort -u)

    # Find first incomplete sprint
    FOUND_SPRINT=false
    for SPRINT_LABEL in $SPRINTS; do
      SPRINT_NUM="${SPRINT_LABEL#sprint:}"

      # Get all issues in this sprint
      SPRINT_ISSUES=$(echo "$JSON" | jq -r --arg sprint "$SPRINT_LABEL" '
        map(select(.labels[] | .name == $sprint))
      ')

      # Count incomplete issues (not shipped and not blocked)
      INCOMPLETE_COUNT=$(echo "$SPRINT_ISSUES" | jq -r '
        map(select(
          (.labels[] | .name != "status:shipped") and
          (.labels[] | .name != "status:blocked")
        )) | length
      ')

      TOTAL_COUNT=$(echo "$SPRINT_ISSUES" | jq -r 'length')

      if [ "$INCOMPLETE_COUNT" -gt 0 ]; then
        echo "✅ Found incomplete sprint: $SPRINT_NUM ($INCOMPLETE_COUNT/$TOTAL_COUNT remaining)"
        SPRINT_FILTER="$SPRINT_NUM"
        FOUND_SPRINT=true
        break
      else
        echo "   Sprint $SPRINT_NUM: $TOTAL_COUNT/$TOTAL_COUNT complete ✅"
      fi
    done
    echo ""

    if [ "$FOUND_SPRINT" = false ]; then
      echo "🎉 All sprints in epic:$EPIC_FILTER are complete!"
      echo ""
      echo "Create next sprint with:"
      echo "  /roadmap add \"Feature name\" --epic $EPIC_FILTER --sprint SXX"
      exit 0
    fi

    # Re-filter by discovered sprint
    LABEL_FILTER="type:feature,epic:$EPIC_FILTER,sprint:$SPRINT_FILTER"
    JSON=$(gh issue list --repo "$REPO" --label "$LABEL_FILTER" --json number,title,body,labels,state --limit 100)
  fi

  # Filter to only issues that are available (status:next or status:backlog)
  AVAILABLE_JSON=$(echo "$JSON" | jq -r '
    map(select(
      (.labels[] | .name == "status:next") or
      (.labels[] | .name == "status:backlog")
    ))
  ')

  # Sort by epic name (alphabetical) if multiple epics, then by creation order
  # GitHub returns issues in creation order by default
  ISSUE=$(echo "$AVAILABLE_JSON" | jq -r '
    sort_by(
      [.labels[] | select(.name | startswith("epic:")) | .name] | .[0] // "zzz"
    ) | first
  ')

  if [ -z "$ISSUE" ] || [ "$ISSUE" = "null" ]; then
    echo "❌ No available issues in $LABEL_FILTER"
    echo "   (All issues may be in-progress, shipped, or blocked)"
    exit 1
  fi

  ISSUE_NUMBER=$(echo "$ISSUE" | jq -r .number)
  ISSUE_TITLE=$(echo "$ISSUE" | jq -r .title)
  ISSUE_BODY=$(echo "$ISSUE" | jq -r '.body // ""')

  # Claim immediately
  gh issue edit "$ISSUE_NUMBER" \
    --remove-label "status:next" --remove-label "status:backlog" \
    --add-label "status:in-progress" \
    --repo "$REPO" >/dev/null || true

  # Extract slug
  SLUG=$(echo "$ISSUE_BODY" | grep -oP '^slug:\s*"\K[^"]+' | head -1)
  if [ -z "$SLUG" ]; then
    SLUG=$(echo "$ISSUE_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g;s/--*/-/g;s/^-//;s/-$//' | cut -c1-20)
  fi

  FEATURE_DESCRIPTION="$ISSUE_TITLE"

  # Display selection summary
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 Selected Issue from Epic/Sprint"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  [ -n "$EPIC_FILTER" ] && echo "  Epic: $EPIC_FILTER"
  [ -n "$SPRINT_FILTER" ] && echo "  Sprint: $SPRINT_FILTER"
  echo "  Issue: #$ISSUE_NUMBER"
  echo "  Title: $ISSUE_TITLE"
  echo "  Slug: $SLUG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GENERATE FEATURE SLUG (if not provided)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ -z "$SLUG" ]; then
  [ -z "$FEATURE_DESCRIPTION" ] && { echo "❌ Provide a description or use /feature next"; exit 1; }
  SLUG=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/\b\(we want to\|i want to\|with\|for the\|to a\)\b//g' | sed 's/[^a-z0-9-]/-/g;s/--*/-/g;s/^-//;s/-$//' | cut -c1-20)
fi

[[ "$SLUG" == *".."* || "$SLUG" == *"/"* ]] && { echo "❌ Invalid slug"; exit 1; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DETECT PROJECT TYPE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if command -v bash >/dev/null 2>&1; then
  PROJECT_TYPE=$(bash .spec-flow/scripts/bash/detect-project-type.sh)
else
  PROJECT_TYPE=$(pwsh -File .spec-flow/scripts/powershell/detect-project-type.ps1)
fi

echo "Project type: $PROJECT_TYPE"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WORKTREE CONFIGURATION (v11.8)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WORKTREE_AUTO_CREATE=$(bash .spec-flow/scripts/bash/utils/load-preferences.sh --key "worktrees.auto_create" --default "true" 2>/dev/null || echo "true")
WORKTREE_PATH=""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BRANCH MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH_NAME="local"
  MAX_NUM=$(find specs -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sed -n 's#specs/\([0-9]\{3\}\)-.*#\1#p' | sort -n | tail -1)
  FEATURE_NUM=$(printf '%03d' $((10#${MAX_NUM:-0} + 1)))
else
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "❌ Dirty worktree. Commit/stash or reset before proceeding."
    exit 1
  fi

  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

  MAX_NUM=$(find specs -maxdepth 1 -mindepth 1 -type d | sed -n 's#specs/\([0-9]\{3\}\)-.*#\1#p' | sort -n | tail -1)
  FEATURE_NUM=$(printf '%03d' $((10#${MAX_NUM:-0} + 1)))

  if [[ "$CURRENT_BRANCH" =~ ^(main|master)$ ]]; then
    BASE="feature/$FEATURE_NUM-$SLUG"
    BRANCH_NAME="$BASE"
    i=2; while git rev-parse --verify --quiet "$BRANCH_NAME" >/dev/null 2>&1; do BRANCH_NAME="$BASE-$i"; i=$((i+1)); done

    # Create worktree or regular branch based on preference
    if [ "$WORKTREE_AUTO_CREATE" = "true" ]; then
      echo "Creating worktree for feature..."
      WORKTREE_RESULT=$(bash .spec-flow/scripts/bash/worktree-manager.sh --json create "feature" "$FEATURE_NUM-$SLUG" "$BRANCH_NAME" 2>&1)
      if [ $? -eq 0 ]; then
        # Extract worktree path from JSON result
        WORKTREE_PATH=$(echo "$WORKTREE_RESULT" | grep -o '"worktree_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)"/\1/')
        if [ -n "$WORKTREE_PATH" ] && [ -d "$WORKTREE_PATH" ]; then
          echo "✅ Worktree created: $WORKTREE_PATH"
          cd "$WORKTREE_PATH"
        else
          echo "⚠️ Worktree creation returned empty path, falling back to regular branch"
          git checkout -b "$BRANCH_NAME"
        fi
      else
        echo "⚠️ Worktree creation failed, falling back to regular branch"
        echo "   Error: $WORKTREE_RESULT"
        git checkout -b "$BRANCH_NAME"
      fi
    else
      git checkout -b "$BRANCH_NAME"
    fi
  else
    BRANCH_NAME="$CURRENT_BRANCH"
  fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INITIALIZE WORKFLOW STATE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

FEATURE_DIR="specs/$FEATURE_NUM-$SLUG"
mkdir -p "$FEATURE_DIR"

# Source helpers (bash or PowerShell variant)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  source .spec-flow/scripts/bash/workflow-state.sh 2>/dev/null || true
else
  source .spec-flow/scripts/bash/workflow-state.sh
fi

initialize_workflow_state "$FEATURE_DIR" "$SLUG" "${FEATURE_DESCRIPTION:-$SLUG}" "$BRANCH_NAME"
start_phase_timing "$FEATURE_DIR" "spec-flow"

[ -n "$ISSUE_NUMBER" ] && yq -i ".feature.github_issue = $ISSUE_NUMBER" "$FEATURE_DIR/state.yaml" || true

# Add worktree info to state.yaml (v11.8)
if [ -n "$WORKTREE_PATH" ]; then
  yq -i '.git.worktree_enabled = true' "$FEATURE_DIR/state.yaml" 2>/dev/null || true
  yq -i ".git.worktree_path = \"$WORKTREE_PATH\"" "$FEATURE_DIR/state.yaml" 2>/dev/null || true
fi

# Optional: generate feature CLAUDE.md
.spec-flow/scripts/bash/generate-feature-claude-md.sh "$FEATURE_DIR" 2>/dev/null || true

echo ""
echo "✅ Feature initialized: $FEATURE_NUM-$SLUG"
echo "   Branch: $BRANCH_NAME"
echo "   Directory: $FEATURE_DIR"
[ -n "$ISSUE_NUMBER" ] && echo "   GitHub Issue: #$ISSUE_NUMBER"
if [ -n "$WORKTREE_PATH" ]; then
  echo "   Worktree: $WORKTREE_PATH"
  echo ""
  echo "📂 Working directory: $WORKTREE_PATH"
  echo "💡 Run 'cd $WORKTREE_PATH' to continue development"
fi
echo ""

# Exit here - LLM will handle phase execution through slash commands
exit 0
