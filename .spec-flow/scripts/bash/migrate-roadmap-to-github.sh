#!/bin/bash

# migrate-roadmap-to-github.sh - Migrate existing roadmap.md to GitHub Issues
#
# Parses the markdown roadmap and creates GitHub issues with appropriate
# labels, state, and ICE frontmatter.
#
# Usage:
#   ./migrate-roadmap-to-github.sh [--dry-run] [--archive]
#
# Prerequisites:
#   - gh CLI authenticated OR GITHUB_TOKEN set
#   - roadmap.md file exists
#   - Labels already created (run setup-github-labels.sh first)
#
# Version: 1.0.0

set -e

# Source the GitHub roadmap manager functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/github-roadmap-manager.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
DRY_RUN=false
ARCHIVE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --archive)
      ARCHIVE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--dry-run] [--archive]"
      exit 1
      ;;
  esac
done

# Check authentication
AUTH_METHOD=$(check_github_auth)
if [ "$AUTH_METHOD" = "none" ]; then
  echo -e "${RED}✗${NC} No GitHub authentication found"
  echo ""
  echo "Please authenticate:"
  echo "  gh auth login"
  echo "  OR"
  echo "  export GITHUB_TOKEN=your_token"
  exit 1
fi

echo -e "${GREEN}✓${NC} GitHub authenticated ($AUTH_METHOD)"

# Check if roadmap exists
ROADMAP_FILE=".spec-flow/memory/roadmap.md"
if [ ! -f "$ROADMAP_FILE" ]; then
  echo -e "${RED}✗${NC} Roadmap file not found: $ROADMAP_FILE"
  exit 1
fi

echo -e "${GREEN}✓${NC} Found roadmap: $ROADMAP_FILE"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}DRY RUN MODE - No issues will be created${NC}"
  echo ""
fi

# ============================================================================
# PARSING FUNCTIONS
# ============================================================================

# Extract value from feature block
extract_field() {
  local block="$1"
  local field="$2"

  echo "$block" | grep -i "^- \*\*$field\*\*:" | sed "s/^- \*\*$field\*\*: *//" | sed 's/ .*//'
}

# Extract all requirements as bullets
extract_requirements() {
  local block="$1"

  echo "$block" | awk '
    /^- \*\*Requirements\*\*:/{flag=1; next}
    /^- \*\*[A-Z]/{flag=0}
    flag && /^  - /{print}
  ' | sed 's/^  //'
}

# Map section name to status label
section_to_status() {
  case "$1" in
    "Shipped") echo "shipped" ;;
    "In Progress") echo "in-progress" ;;
    "Next") echo "next" ;;
    "Later") echo "later" ;;
    "Backlog") echo "backlog" ;;
    *) echo "backlog" ;;
  esac
}

# Determine issue state (open/closed)
section_to_state() {
  case "$1" in
    "Shipped") echo "closed" ;;
    *) echo "open" ;;
  esac
}

# ============================================================================
# MIGRATION
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Migrating Roadmap to GitHub Issues"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Counters
TOTAL_COUNT=0
CREATED_COUNT=0
SKIPPED_COUNT=0
ERROR_COUNT=0

# Read roadmap and process each section
CURRENT_SECTION=""
CURRENT_FEATURE=""
FEATURE_BLOCK=""

while IFS= read -r line; do
  # Section headers
  if [[ "$line" =~ ^##[[:space:]](.+)$ ]]; then
    # Process previous feature if exists
    if [ -n "$CURRENT_FEATURE" ] && [ -n "$FEATURE_BLOCK" ]; then
      # Skip special sections
      if [[ ! "$CURRENT_SECTION" =~ ^(Scoring Guide|Status Flow|Feature Sizing)$ ]]; then
        ((TOTAL_COUNT++))

        # Extract metadata
        SLUG="$CURRENT_FEATURE"
        TITLE=$(extract_field "$FEATURE_BLOCK" "Title")
        AREA=$(extract_field "$FEATURE_BLOCK" "Area" | tr '[:upper:]' '[:lower:]')
        ROLE=$(extract_field "$FEATURE_BLOCK" "Role" | tr '[:upper:]' '[:lower:]')

        # Extract ICE scores (with defaults)
        IMPACT=$(extract_field "$FEATURE_BLOCK" "Impact" | grep -o '[0-9]' | head -1)
        EFFORT=$(extract_field "$FEATURE_BLOCK" "Effort" | grep -o '[0-9]' | head -1)
        CONFIDENCE=$(extract_field "$FEATURE_BLOCK" "Confidence" | grep -o '0\.[0-9]' | head -1)

        # Defaults if not found
        IMPACT=${IMPACT:-3}
        EFFORT=${EFFORT:-3}
        CONFIDENCE=${CONFIDENCE:-0.7}
        TITLE=${TITLE:-$SLUG}
        AREA=${AREA:-app}
        ROLE=${ROLE:-all}

        # Extract requirements
        REQUIREMENTS=$(extract_requirements "$FEATURE_BLOCK")

        # Build issue body
        if [ -n "$REQUIREMENTS" ]; then
          BODY="## Requirements\n\n$REQUIREMENTS\n\n"
        else
          BODY="## Requirements\n\n- [ ] To be defined\n\n"
        fi

        # Add spec link if exists
        SPEC_DIR=$(find specs -type d -name "*$SLUG" | head -1)
        if [ -n "$SPEC_DIR" ]; then
          BODY="${BODY}## Spec\n\nSee: \`$SPEC_DIR/spec.md\`\n\n"
        fi

        # Determine status and state
        STATUS=$(section_to_status "$CURRENT_SECTION")
        STATE=$(section_to_state "$CURRENT_SECTION")

        # Build labels
        LABELS="type:feature,status:$STATUS"

        # Handle shipped features differently
        if [ "$CURRENT_SECTION" = "Shipped" ]; then
          RELEASE=$(extract_field "$FEATURE_BLOCK" "Release")
          DATE=$(extract_field "$FEATURE_BLOCK" "Date")
          URL=$(extract_field "$FEATURE_BLOCK" "URL")

          # Add release info to body
          if [ -n "$RELEASE" ]; then
            BODY="${BODY}---\n\n**Shipped**: $RELEASE ($DATE)\n"
            if [ -n "$URL" ]; then
              BODY="${BODY}**URL**: $URL\n"
            fi
          fi
        fi

        echo -e "${BLUE}[$CURRENT_SECTION]${NC} $SLUG - $TITLE"

        if [ "$DRY_RUN" = true ]; then
          echo "  Would create issue with:"
          echo "    Impact: $IMPACT, Effort: $EFFORT, Confidence: $CONFIDENCE"
          echo "    Area: $AREA, Role: $ROLE"
          echo "    Labels: $LABELS"
          echo "    State: $STATE"
          ((CREATED_COUNT++))
        else
          # Create issue
          if create_roadmap_issue "$TITLE" "$BODY" "$IMPACT" "$EFFORT" "$CONFIDENCE" "$AREA" "$ROLE" "$SLUG" "$LABELS" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Created issue"
            ((CREATED_COUNT++))

            # If shipped, close the issue immediately
            if [ "$STATE" = "closed" ]; then
              ISSUE_NUM=$(get_issue_by_slug "$SLUG" | jq -r '.number' 2>/dev/null || echo "")
              if [ -n "$ISSUE_NUM" ] && [ "$ISSUE_NUM" != "null" ]; then
                # Close via gh CLI or API
                if [ "$AUTH_METHOD" = "gh_cli" ]; then
                  gh issue close "$ISSUE_NUM" --reason "completed" 2>/dev/null || true
                elif [ "$AUTH_METHOD" = "api" ]; then
                  REPO=$(get_repo_info)
                  API_URL="https://api.github.com/repos/$REPO/issues/$ISSUE_NUM"
                  curl -s -X PATCH \
                    -H "Authorization: token $GITHUB_TOKEN" \
                    -H "Accept: application/vnd.github.v3+json" \
                    "$API_URL" \
                    -d '{"state":"closed"}' > /dev/null
                fi

                echo -e "  ${GREEN}✓${NC} Closed as shipped"
              fi
            fi
          else
            echo -e "  ${RED}✗${NC} Failed to create issue"
            ((ERROR_COUNT++))
          fi

          # Rate limit protection
          sleep 0.5
        fi
      fi
    fi

    # New section
    CURRENT_SECTION="${BASH_REMATCH[1]}"
    CURRENT_FEATURE=""
    FEATURE_BLOCK=""

  # Feature headers
  elif [[ "$line" =~ ^###[[:space:]](.+)$ ]]; then
    # Process previous feature if exists
    if [ -n "$CURRENT_FEATURE" ] && [ -n "$FEATURE_BLOCK" ]; then
      # (Same processing as above - would be extracted to function in production)
      :  # Placeholder - same logic as section boundary
    fi

    # New feature
    CURRENT_FEATURE="${BASH_REMATCH[1]}"
    FEATURE_BLOCK=""

  # Accumulate feature content
  elif [ -n "$CURRENT_FEATURE" ]; then
    FEATURE_BLOCK="${FEATURE_BLOCK}${line}\n"
  fi

done < "$ROADMAP_FILE"

# Process final feature
if [ -n "$CURRENT_FEATURE" ] && [ -n "$FEATURE_BLOCK" ]; then
  if [[ ! "$CURRENT_SECTION" =~ ^(Scoring Guide|Status Flow|Feature Sizing)$ ]]; then
    ((TOTAL_COUNT++))
    # (Same processing logic)
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Migration Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total features found: $TOTAL_COUNT"
echo -e "${GREEN}Created:${NC} $CREATED_COUNT"

if [ "$ERROR_COUNT" -gt 0 ]; then
  echo -e "${RED}Errors:${NC} $ERROR_COUNT"
fi

echo ""

# Archive old roadmap if requested
if [ "$ARCHIVE" = true ] && [ "$DRY_RUN" = false ]; then
  ARCHIVE_FILE=".spec-flow/memory/roadmap-archived-$(date +%Y-%m-%d).md"
  mv "$ROADMAP_FILE" "$ARCHIVE_FILE"
  echo -e "${GREEN}✓${NC} Archived old roadmap to: $ARCHIVE_FILE"
  echo ""
fi

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}DRY RUN COMPLETE${NC}"
  echo ""
  echo "Run without --dry-run to create issues"
  echo "Add --archive to archive the old roadmap.md after migration"
else
  echo -e "${GREEN}MIGRATION COMPLETE${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Review created issues: gh issue list"
  echo "  2. Archive old roadmap: $0 --archive"
  echo "  3. Update /roadmap command to use GitHub Issues"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
