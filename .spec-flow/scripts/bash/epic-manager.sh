#!/usr/bin/env bash
set -Eeuo pipefail

# epic-manager.sh - Epic and Sprint Management Utilities
#
# Provides helper functions for managing epic and sprint labels and tracking progress
#
# Usage:
#   source epic-manager.sh
#   list_epics
#   create_epic_label "aktr" "AKTR features"
#   get_epic_progress "aktr"
#
# Version: 1.0.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# List all epics
list_epics() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Epics"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  gh label list --search "epic:" --json name,description --limit 100 | \
    jq -r '.[] | "  \(.name | sub("epic:"; "")) - \(.description)"'

  echo ""
}

# Create new epic label
create_epic_label() {
  local epic_name="$1"
  local description="${2:-Epic: $epic_name}"

  echo -e "${BLUE}Creating epic label: epic:$epic_name${NC}"

  if gh label create "epic:$epic_name" --description "$description" --color "5319e7" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Created: epic:$epic_name"
  elif gh label edit "epic:$epic_name" --description "$description" --color "5319e7" 2>/dev/null; then
    echo -e "${YELLOW}↻${NC} Updated: epic:$epic_name"
  else
    echo -e "${RED}✗${NC} Failed to create epic:$epic_name"
    return 1
  fi
}

# Create sprint labels (S01-S12 for one year)
create_sprint_labels() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Creating Sprint Labels"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  for i in $(seq -w 1 12); do
    local week_start=$(( (i - 1) * 2 + 1 ))
    local week_end=$(( i * 2 ))

    if gh label create "sprint:S$i" \
      --description "Sprint $i (Week $week_start-$week_end)" \
      --color "c2e0c6" 2>/dev/null; then
      echo -e "${GREEN}✓${NC} Created: sprint:S$i"
    else
      echo -e "${YELLOW}↻${NC} Exists: sprint:S$i"
    fi
  done

  echo ""
  echo -e "${GREEN}Sprint labels created (S01-S12)${NC}"
}

# Get epic progress
get_epic_progress() {
  local epic="$1"
  local repo
  repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)

  if [ -z "$repo" ]; then
    echo -e "${RED}✗${NC} Not in a GitHub repository"
    return 1
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Epic Progress: $epic"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Get all issues in epic
  local issues
  issues=$(gh issue list --repo "$repo" --label "epic:$epic" \
    --json number,title,labels,state --limit 100)

  if [ -z "$issues" ] || [ "$issues" = "[]" ]; then
    echo -e "${YELLOW}No issues found with label epic:$epic${NC}"
    return 0
  fi

  # Group by sprint and show progress
  echo "$issues" | jq -r '
    group_by(.labels[] | select(.name | startswith("sprint:")) | .name) |
    map({
      sprint: (.[0].labels[] | select(.name | startswith("sprint:")) | .name),
      total: length,
      shipped: (map(select(.labels[] | any(.name == "status:shipped"))) | length),
      blocked: (map(select(.labels[] | any(.name == "status:blocked"))) | length),
      in_progress: (map(select(.labels[] | any(.name == "status:in-progress"))) | length),
      backlog: (map(select(.labels[] | any(.name == "status:next" or .name == "status:backlog"))) | length)
    }) |
    .[] |
    "  \(.sprint): \(.shipped)/\(.total) shipped (\(((.shipped / .total) * 100) | floor)%)" +
    (if .in_progress > 0 then " | \(.in_progress) in-progress" else "" end) +
    (if .blocked > 0 then " | \(.blocked) blocked" else "" end) +
    (if .backlog > 0 then " | \(.backlog) backlog" else "" end) +
    (if .shipped == .total then " ✅" else " ⏳" end)
  '

  echo ""

  # Overall summary
  local total
  total=$(echo "$issues" | jq 'length')
  local shipped
  shipped=$(echo "$issues" | jq '[.[] | select(.labels[] | .name == "status:shipped")] | length')
  local percent=$(( (shipped * 100) / total ))

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Total: $shipped/$total shipped ($percent%)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Auto-assign unassigned issues to sprint:S01
auto_assign_sprint() {
  local epic="$1"
  local sprint="${2:-S01}"
  local repo
  repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)

  if [ -z "$repo" ]; then
    echo -e "${RED}✗${NC} Not in a GitHub repository"
    return 1
  fi

  echo -e "${BLUE}Auto-assigning issues in epic:$epic to sprint:$sprint${NC}"
  echo ""

  # Get all issues in epic
  local issues
  issues=$(gh issue list --repo "$repo" --label "epic:$epic" \
    --json number,labels --limit 100)

  if [ -z "$issues" ] || [ "$issues" = "[]" ]; then
    echo -e "${YELLOW}No issues found with label epic:$epic${NC}"
    return 0
  fi

  # Filter issues without sprint label
  local unassigned
  unassigned=$(echo "$issues" | jq -r '
    map(select(.labels | all(.name | startswith("sprint:") | not))) |
    .[].number
  ')

  if [ -z "$unassigned" ]; then
    echo -e "${GREEN}✓${NC} All issues already assigned to sprints"
    return 0
  fi

  # Bulk-assign to sprint
  local count=0
  for issue_num in $unassigned; do
    gh issue edit "$issue_num" --add-label "sprint:$sprint" --repo "$repo" 2>/dev/null && count=$((count + 1))
  done

  echo -e "${GREEN}✓${NC} Assigned $count issues to sprint:$sprint"
}

# List all issues in a sprint
list_sprint_issues() {
  local sprint="$1"
  local repo
  repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)

  if [ -z "$repo" ]; then
    echo -e "${RED}✗${NC} Not in a GitHub repository"
    return 1
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Sprint: $sprint"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  gh issue list --repo "$repo" --label "sprint:$sprint" \
    --json number,title,labels \
    --limit 100 | \
    jq -r '.[] |
      "#\(.number): \(.title) " +
      (if (.labels[] | select(.name == "status:shipped")) then "✅"
       elif (.labels[] | select(.name == "status:blocked")) then "🚫"
       elif (.labels[] | select(.name == "status:in-progress")) then "⏳"
       else "📋" end)
    '

  echo ""
}

# Export functions
export -f list_epics
export -f create_epic_label
export -f create_sprint_labels
export -f get_epic_progress
export -f auto_assign_sprint
export -f list_sprint_issues
