#!/bin/bash

# setup-github-labels.sh - Create GitHub labels for roadmap management
#
# Creates a comprehensive label schema for managing features
#
# Usage:
#   ./setup-github-labels.sh [--dry-run]
#
# Prerequisites:
#   - gh CLI authenticated OR GITHUB_TOKEN environment variable set
#
# Version: 1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
DRY_RUN=false
if [ "$1" = "--dry-run" ]; then
  DRY_RUN=true
  echo -e "${YELLOW}DRY RUN MODE - No labels will be created${NC}"
  echo ""
fi

# Check authentication
USE_GH_CLI=false
if gh auth status &>/dev/null; then
  echo -e "${GREEN}✓${NC} GitHub CLI authenticated"
  USE_GH_CLI=true
elif [ -n "$GITHUB_TOKEN" ]; then
  echo -e "${GREEN}✓${NC} GITHUB_TOKEN found"
  USE_GH_CLI=false
else
  echo -e "${RED}✗${NC} No GitHub authentication found"
  echo ""
  echo "Please authenticate with GitHub:"
  echo "  Option 1: gh auth login"
  echo "  Option 2: export GITHUB_TOKEN=your_token"
  exit 1
fi

# Get repository info
if [ "$USE_GH_CLI" = true ]; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")

  if [ -z "$REPO" ]; then
    echo -e "${RED}✗${NC} Not in a GitHub repository or no remote configured"
    echo ""
    echo "Please run this script from a repository with a GitHub remote"
    exit 1
  fi

  echo -e "${GREEN}✓${NC} Repository: $REPO"
else
  # Extract repo from git remote URL
  REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")

  if [ -z "$REMOTE_URL" ]; then
    echo -e "${RED}✗${NC} No git remote found"
    exit 1
  fi

  # Parse owner/repo from URL
  REPO=$(echo "$REMOTE_URL" | sed -E 's/.*github\.com[:/](.*)\.git/\1/' | sed 's/\.git$//')
  echo -e "${GREEN}✓${NC} Repository: $REPO"
fi

echo ""

# Function to create a label
create_label() {
  local name="$1"
  local description="$2"
  local color="$3"

  if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}[DRY RUN]${NC} Would create: $name ($color) - $description"
    return 0
  fi

  if [ "$USE_GH_CLI" = true ]; then
    # Use gh CLI
    if gh label create "$name" --description "$description" --color "$color" --repo "$REPO" 2>/dev/null; then
      echo -e "${GREEN}✓${NC} Created: $name"
    elif gh label edit "$name" --description "$description" --color "$color" --repo "$REPO" 2>/dev/null; then
      echo -e "${YELLOW}↻${NC} Updated: $name"
    else
      echo -e "${RED}✗${NC} Failed: $name"
      return 1
    fi
  else
    # Use GitHub API
    local api_url="https://api.github.com/repos/$REPO/labels"

    # Try to create label
    local response
    response=$(curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" \
      -d "{\"name\":\"$name\",\"description\":\"$description\",\"color\":\"$color\"}")

    if echo "$response" | grep -q '"id"'; then
      echo -e "${GREEN}✓${NC} Created: $name"
    else
      # Try to update existing label
      response=$(curl -s -X PATCH \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$api_url/$name" \
        -d "{\"description\":\"$description\",\"color\":\"$color\"}")

      if echo "$response" | grep -q '"id"'; then
        echo -e "${YELLOW}↻${NC} Updated: $name"
      else
        echo -e "${RED}✗${NC} Failed: $name"
        return 1
      fi
    fi
  fi

  return 0
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Creating GitHub Labels"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Priority Labels (optional - for manual prioritization only)
echo "Priority Labels (manual use):"
create_label "priority:high" "High priority - manual override" "d73a4a"
create_label "priority:medium" "Medium priority - manual override" "fb8c00"
create_label "priority:low" "Low priority - manual override" "fef2c0"
echo ""

# Type Labels (blue/purple spectrum)
echo "Type Labels:"
create_label "type:feature" "New feature or functionality" "1d76db"
create_label "type:enhancement" "Enhancement to existing feature" "5319e7"
create_label "type:bug" "Bug or defect" "d73a4a"
create_label "type:task" "Task or chore" "0e8a16"
echo ""

# Area Labels (green spectrum)
echo "Area Labels:"
create_label "area:backend" "Backend/API code" "0e8a16"
create_label "area:frontend" "Frontend/UI code" "1d76db"
create_label "area:api" "API endpoints and contracts" "006b75"
create_label "area:infra" "Infrastructure and DevOps" "5319e7"
create_label "area:design" "Design and UX" "e99695"
create_label "area:marketing" "Marketing pages and content" "fbca04"
echo ""

# Role Labels (orange spectrum)
echo "Role Labels:"
create_label "role:all" "All users" "fb8c00"
create_label "role:free" "Free tier users" "fef2c0"
create_label "role:student" "Student users" "fbca04"
create_label "role:cfi" "CFI (instructor) users" "d4c5f9"
create_label "role:school" "School/organization users" "c2e0c6"
echo ""

# Status Labels (workflow states)
echo "Status Labels:"
create_label "status:backlog" "Backlog - not yet prioritized" "ededed"
create_label "status:next" "Next - queued for implementation" "c2e0c6"
create_label "status:later" "Later - future consideration" "fef2c0"
create_label "status:in-progress" "In Progress - actively being worked on" "1d76db"
create_label "status:shipped" "Shipped - deployed to production" "0e8a16"
create_label "status:blocked" "Blocked - waiting on dependency" "d73a4a"
echo ""

# Size Labels (effort estimation)
echo "Size Labels:"
create_label "size:small" "Small - < 1 day" "c2e0c6"
create_label "size:medium" "Medium - 1-2 weeks" "fbca04"
create_label "size:large" "Large - 2-4 weeks" "fb8c00"
create_label "size:xl" "Extra Large - 4+ weeks (consider splitting)" "d73a4a"
echo ""

# Sprint Labels (time-boxed iterations)
echo "Sprint Labels:"
create_label "sprint:S01" "Sprint 1 (Week 1-2)" "c2e0c6"
create_label "sprint:S02" "Sprint 2 (Week 3-4)" "c2e0c6"
create_label "sprint:S03" "Sprint 3 (Week 5-6)" "c2e0c6"
create_label "sprint:S04" "Sprint 4 (Week 7-8)" "c2e0c6"
create_label "sprint:S05" "Sprint 5 (Week 9-10)" "c2e0c6"
create_label "sprint:S06" "Sprint 6 (Week 11-12)" "c2e0c6"
create_label "sprint:S07" "Sprint 7 (Week 13-14)" "c2e0c6"
create_label "sprint:S08" "Sprint 8 (Week 15-16)" "c2e0c6"
create_label "sprint:S09" "Sprint 9 (Week 17-18)" "c2e0c6"
create_label "sprint:S10" "Sprint 10 (Week 19-20)" "c2e0c6"
create_label "sprint:S11" "Sprint 11 (Week 21-22)" "c2e0c6"
create_label "sprint:S12" "Sprint 12 (Week 23-24)" "c2e0c6"
echo ""

# Special Labels
echo "Special Labels:"
create_label "blocked" "Blocked by dependency or external factor" "d73a4a"
create_label "good-first-issue" "Good for newcomers" "7057ff"
create_label "help-wanted" "Extra attention needed" "008672"
create_label "wont-fix" "Will not be implemented" "ffffff"
create_label "duplicate" "Duplicate of another issue" "cfd3d7"
create_label "needs-clarification" "Needs more information or clarification" "d876e3"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}DRY RUN COMPLETE${NC}"
  echo ""
  echo "Run without --dry-run to create labels"
else
  echo -e "${GREEN}LABELS CREATED SUCCESSFULLY${NC}"
  echo ""
  echo "You can now:"
  echo "  1. View labels: gh label list --repo $REPO"
  echo "  2. Create issues with these labels"
  echo "  3. Run migration script to import existing roadmap"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
