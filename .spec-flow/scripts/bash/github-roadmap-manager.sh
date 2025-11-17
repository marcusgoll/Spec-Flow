#!/bin/bash

# github-roadmap-manager.sh - GitHub Issues roadmap management functions
#
# Provides functions to manage roadmap via GitHub Issues with ICE scoring
#
# Version: 1.0.0
# Requires: gh CLI OR GITHUB_TOKEN environment variable

set -e

# ============================================================================
# AUTHENTICATION & CONFIGURATION
# ============================================================================

# Check if GitHub authentication is available
check_github_auth() {
  if gh auth status &>/dev/null; then
    echo "gh_cli"
    return 0
  elif [ -n "$GITHUB_TOKEN" ]; then
    echo "api"
    return 0
  else
    echo "none"
    return 1
  fi
}

# Get repository owner/name
get_repo_info() {
  local auth_method
  auth_method=$(check_github_auth)

  if [ "$auth_method" = "gh_cli" ]; then
    gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo ""
  elif [ "$auth_method" = "api" ]; then
    local remote_url
    remote_url=$(git config --get remote.origin.url 2>/dev/null || echo "")
    echo "$remote_url" | sed -E 's/.*github\.com[:/](.*)\.git/\1/' | sed 's/\.git$//'
  else
    echo ""
  fi
}

# ============================================================================
# METADATA FUNCTIONS
# ============================================================================

# Parse metadata frontmatter from issue body
parse_metadata_from_body() {
  local body="$1"

  # Extract YAML frontmatter between --- delimiters
  local frontmatter
  frontmatter=$(echo "$body" | awk '/^---$/,/^---$/ {if (!/^---$/) print}')

  if [ -z "$frontmatter" ]; then
    echo "{}"
    return 1
  fi

  # Parse metadata values
  local area
  area=$(echo "$frontmatter" | grep "area:" | sed 's/.*area: *//' | tr -d ' ')
  local role
  role=$(echo "$frontmatter" | grep "role:" | sed 's/.*role: *//' | tr -d ' ')
  local slug
  slug=$(echo "$frontmatter" | grep "slug:" | sed 's/.*slug: *//' | tr -d ' ')

  # Return JSON
  cat <<EOF
{
  "area": "${area:-app}",
  "role": "${role:-all}",
  "slug": "${slug:-unknown}"
}
EOF
}

# Generate metadata frontmatter for issue body
generate_metadata_frontmatter() {
  local area="${1:-app}"
  local role="${2:-all}"
  local slug="$3"
  local epic="$4"
  local sprint="$5"

  cat <<EOF
---
metadata:
  area: $area
  role: $role
  slug: $slug$([ -n "$epic" ] && echo "
  epic: $epic")$([ -n "$sprint" ] && echo "
  sprint: $sprint")
---
EOF
}

# ============================================================================
# ISSUE OPERATIONS
# ============================================================================

# Create a roadmap issue with metadata frontmatter
create_roadmap_issue() {
  local title="$1"
  local body="$2"
  local area="${3:-app}"
  local role="${4:-all}"
  local slug="$5"
  local labels="${6:-type:feature,status:backlog}"
  local epic="$7"
  local sprint="$8"

  local repo
  repo=$(get_repo_info)
  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  # Generate frontmatter
  local frontmatter
  frontmatter=$(generate_metadata_frontmatter "$area" "$role" "$slug" "$epic" "$sprint")

  # Combine frontmatter with body
  local full_body
  full_body=$(cat <<EOF
$frontmatter

$body
EOF
)

  # Add area and role labels
  local all_labels="$labels,area:$area,role:$role"

  # Add epic and sprint labels if provided
  [ -n "$epic" ] && all_labels="$all_labels,epic:$epic"
  [ -n "$sprint" ] && all_labels="$all_labels,sprint:$sprint"

  # Create issue
  local auth_method
  auth_method=$(check_github_auth)

  if [ "$auth_method" = "gh_cli" ]; then
    gh issue create \
      --repo "$repo" \
      --title "$title" \
      --body "$full_body" \
      --label "$all_labels"
  elif [ "$auth_method" = "api" ]; then
    # Use GitHub API
    local api_url="https://api.github.com/repos/$repo/issues"
    local label_array
    label_array=$(echo "$all_labels" | jq -R 'split(",") | map(gsub("^ +| +$";""))')

    local json_body
    json_body=$(jq -n \
      --arg title "$title" \
      --arg body "$full_body" \
      --argjson labels "$label_array" \
      '{title: $title, body: $body, labels: $labels}')

    curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" \
      -d "$json_body"
  else
    echo "Error: No GitHub authentication available" >&2
    return 1
  fi
}

# Get issue by slug (searches in frontmatter)
get_issue_by_slug() {
  local slug="$1"
  local repo
  repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  local auth_method
  auth_method=$(check_github_auth)

  if [ "$auth_method" = "gh_cli" ]; then
    # Search for issues containing the slug
    gh issue list \
      --repo "$repo" \
      --search "slug: $slug in:body" \
      --json number,title,body,state,labels \
      --limit 1
  elif [ "$auth_method" = "api" ]; then
    local api_url="https://api.github.com/search/issues"
    local query="repo:$repo slug: $slug in:body"

    curl -s -G \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" \
      --data-urlencode "q=$query" \
      --data-urlencode "per_page=1" | \
      jq '.items[0] // empty'
  else
    echo "Error: No GitHub authentication available" >&2
    return 1
  fi
}

# update_issue_ice removed - no longer using ICE scores

# Mark issue as in progress
mark_issue_in_progress() {
  local slug="$1"
  local repo
  repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  # Find issue by slug
  local issue
  issue=$(get_issue_by_slug "$slug")

  if [ -z "$issue" ] || [ "$issue" = "null" ]; then
    echo "⚠️  Issue with slug '$slug' not found in roadmap" >&2
    return 1
  fi

  local issue_number
  issue_number=$(echo "$issue" | jq -r '.number')

  # Add in-progress label, remove backlog/next/later labels
  local auth_method
  auth_method=$(check_github_auth)

  if [ "$auth_method" = "gh_cli" ]; then
    gh issue edit "$issue_number" \
      --repo "$repo" \
      --remove-label "status:backlog,status:next,status:later" \
      --add-label "status:in-progress"
  elif [ "$auth_method" = "api" ]; then
    local api_url="https://api.github.com/repos/$repo/issues/$issue_number"

    # Get current labels
    local current_labels
    current_labels=$(curl -s \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" | jq -r '.labels[].name')

    # Filter out status labels and add in-progress
    local new_labels
    new_labels=$(echo "$current_labels" | grep -v "^status:" | tr '\n' ',' | sed 's/,$//')
    new_labels="$new_labels,status:in-progress"

    # Update
    local label_array
    label_array=$(echo "$new_labels" | jq -R 'split(",") | map(gsub("^ +| +$";""))')
    local json_body
    json_body=$(jq -n --argjson labels "$label_array" '{labels: $labels}')

    curl -s -X PATCH \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" \
      -d "$json_body"
  fi

  echo "✅ Marked issue #$issue_number as In Progress in roadmap"
}

# Mark issue as shipped
mark_issue_shipped() {
  local slug="$1"
  local version="$2"
  local date="${3:-$(date +%Y-%m-%d)}"
  local prod_url="${4:-}"

  local repo
  repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  # Find issue by slug
  local issue
  issue=$(get_issue_by_slug "$slug")

  if [ -z "$issue" ] || [ "$issue" = "null" ]; then
    echo "⚠️  Issue with slug '$slug' not found in roadmap" >&2
    return 1
  fi

  local issue_number
  issue_number=$(echo "$issue" | jq -r '.number')

  # Add shipped label, close issue
  local auth_method
  auth_method=$(check_github_auth)

  # Prepare comment with deployment info
  local comment="🚀 **Shipped in v$version**\n\n"
  comment="${comment}**Date**: $date\n"
  if [ -n "$prod_url" ]; then
    comment="${comment}**Production URL**: $prod_url\n"
  fi

  if [ "$auth_method" = "gh_cli" ]; then
    # Add labels
    gh issue edit "$issue_number" \
      --repo "$repo" \
      --remove-label "status:in-progress,status:next,status:backlog,status:later" \
      --add-label "status:shipped"

    # Add comment
    echo -e "$comment" | gh issue comment "$issue_number" --repo "$repo" --body-file -

    # Close issue
    gh issue close "$issue_number" --repo "$repo" --reason "completed"
  elif [ "$auth_method" = "api" ]; then
    local api_url="https://api.github.com/repos/$repo/issues/$issue_number"

    # Get current labels
    local current_labels
    current_labels=$(curl -s \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" | jq -r '.labels[].name')

    # Filter out status labels and add shipped
    local new_labels
    new_labels=$(echo "$current_labels" | grep -v "^status:" | tr '\n' ',' | sed 's/,$//')
    new_labels="$new_labels,status:shipped"

    # Update labels and close
    local label_array
    label_array=$(echo "$new_labels" | jq -R 'split(",") | map(gsub("^ +| +$";""))')
    local json_body
    json_body=$(jq -n \
      --argjson labels "$label_array" \
      '{state: "closed", labels: $labels}')

    curl -s -X PATCH \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" \
      -d "$json_body"

    # Add comment
    local comment_url="$api_url/comments"
    local comment_body
    comment_body=$(jq -n --arg body "$comment" '{body: $body}')

    curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$comment_url" \
      -d "$comment_body"
  fi

  echo "✅ Marked issue #$issue_number as Shipped (v$version) in roadmap"
}

# List issues by status label
list_issues_by_status() {
  local status="$1" # backlog, next, later, in-progress, shipped
  local repo
  repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  local auth_method
  auth_method=$(check_github_auth)
  local label="status:$status"

  if [ "$auth_method" = "gh_cli" ]; then
    gh issue list \
      --repo "$repo" \
      --label "$label" \
      --json number,title,body,labels,state \
      --limit 100
  elif [ "$auth_method" = "api" ]; then
    local api_url="https://api.github.com/repos/$repo/issues"

    curl -s -G \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" \
      --data-urlencode "labels=$label" \
      --data-urlencode "per_page=100" \
      --data-urlencode "state=all"
  fi
}

# Suggest adding a discovered feature (create draft issue)
suggest_feature_addition() {
  local description="$1"
  local context="${2:-unknown}"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "💡 Discovered Potential Feature"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Context: $context"
  echo ""
  echo "Description:"
  echo "  $description"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  read -r -p "Create GitHub issue for this feature? (yes/no/later): " response

  case "$response" in
    yes|y|Y)
      echo ""
      echo "Creating GitHub issue..."

      # Generate slug from description
      local slug
      slug=$(echo "$description" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | cut -c1-30)

      # Create issue with defaults
      local title="$description"
      local body="## Problem\n\nDiscovered during: $context\n\n## Proposed Solution\n\nTo be determined\n\n## Requirements\n\n- [ ] To be defined"

      create_roadmap_issue "$title" "$body" 3 3 0.7 "app" "all" "$slug" "type:feature,status:backlog,needs-clarification"

      echo "✅ Created GitHub issue for: $description"
      ;;
    later|l|L)
      # Save to local markdown for later review
      local discovered_file=".spec-flow/memory/discovered-features.md"

      if [ ! -f "$discovered_file" ]; then
        mkdir -p "$(dirname "$discovered_file")"
        cat > "$discovered_file" <<EOF
# Discovered Features

Features discovered during development. Review and create GitHub issues as needed.

---

EOF
      fi

      cat >> "$discovered_file" <<EOF
## $(date +%Y-%m-%d) - Discovered in: $context

**Description**: $description

**Action**: Create GitHub issue or run: \`/roadmap add "$description"\`

---

EOF

      echo "📝 Saved to discovered features. Review later in: $discovered_file"
      ;;
    *)
      echo "⏭️  Skipped"
      ;;
  esac
}

# ============================================================================
# ROADMAP MANAGEMENT FUNCTIONS
# ============================================================================

# Move issue to different status section
move_issue_to_section() {
  local slug="$1"
  local target_status="$2"  # backlog, next, in-progress, later, blocked, shipped

  local repo
  repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  # Validate target status
  case "$target_status" in
    backlog|next|later|in-progress|blocked|shipped)
      # Valid status
      ;;
    *)
      echo "Error: Invalid status '$target_status'. Must be: backlog, next, in-progress, later, blocked, shipped" >&2
      return 1
      ;;
  esac

  # Find issue by slug
  local issue
  issue=$(get_issue_by_slug "$slug")

  if [ -z "$issue" ] || [ "$issue" = "null" ]; then
    echo "⚠️  Issue with slug '$slug' not found in roadmap" >&2
    return 1
  fi

  local issue_number
  issue_number=$(echo "$issue" | jq -r '.number')

  local auth_method
  auth_method=$(check_github_auth)

  if [ "$auth_method" = "gh_cli" ]; then
    # Get current labels
    local current_labels
    current_labels=$(gh issue view "$issue_number" --repo "$repo" --json labels --jq '.labels[].name' | tr '\n' ' ')

    # Remove ALL status:* labels (enforce exactly one invariant)
    local labels_to_remove=""
    for label in $current_labels; do
      if [[ "$label" =~ ^status: ]]; then
        labels_to_remove="$labels_to_remove,$label"
      fi
    done
    labels_to_remove="${labels_to_remove#,}"  # Remove leading comma

    # Remove old status labels
    if [ -n "$labels_to_remove" ]; then
      gh issue edit "$issue_number" --repo "$repo" --remove-label "$labels_to_remove"
    fi

    # Add new status label
    gh issue edit "$issue_number" --repo "$repo" --add-label "status:$target_status"

    # If moving to in-progress, enforce milestone check
    if [ "$target_status" = "in-progress" ]; then
      local milestone
      milestone=$(gh issue view "$issue_number" --repo "$repo" --json milestone --jq '.milestone.title // empty')

      if [ -z "$milestone" ]; then
        echo ""
        echo "⚠️  Issue #$issue_number has no milestone assigned"
        echo ""
        echo "Available milestones:"
        list_milestones
        echo ""
        read -r -p "Assign milestone (leave blank to skip): " milestone_name

        if [ -n "$milestone_name" ]; then
          gh issue edit "$issue_number" --repo "$repo" --milestone "$milestone_name"
          echo "✅ Assigned milestone: $milestone_name"
        fi
      fi
    fi

    # If moving to shipped, close the issue
    if [ "$target_status" = "shipped" ]; then
      gh issue close "$issue_number" --repo "$repo" --reason "completed"
    fi

  elif [ "$auth_method" = "api" ]; then
    local api_url="https://api.github.com/repos/$repo/issues/$issue_number"

    # Get current labels
    local current_labels
    current_labels=$(curl -s \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" | jq -r '.labels[].name')

    # Filter out ALL status:* labels
    local new_labels
    new_labels=$(echo "$current_labels" | grep -v "^status:" | tr '\n' ',' | sed 's/,$//')
    new_labels="$new_labels,status:$target_status"

    # Update labels
    local label_array
    label_array=$(echo "$new_labels" | jq -R 'split(",") | map(gsub("^ +| +$";""))')

    local json_body
    if [ "$target_status" = "shipped" ]; then
      json_body=$(jq -n --argjson labels "$label_array" '{state: "closed", labels: $labels}')
    else
      json_body=$(jq -n --argjson labels "$label_array" '{labels: $labels}')
    fi

    curl -s -X PATCH \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" \
      -d "$json_body" > /dev/null
  fi

  echo "✅ Moved issue #$issue_number ($slug) to status:$target_status"
}

# Search roadmap issues by keyword, label, or milestone
search_roadmap() {
  local query="$1"

  local repo
  repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  local auth_method
  auth_method=$(check_github_auth)

  # Parse filter syntax: label:value or milestone:value
  local label_filters=""
  local milestone_filter=""
  local keyword_query=""

  # Split query by spaces and process each term
  for term in $query; do
    if [[ "$term" =~ ^label:(.+)$ ]]; then
      label_filters="$label_filters ${BASH_REMATCH[1]}"
    elif [[ "$term" =~ ^milestone:(.+)$ ]]; then
      milestone_filter="${BASH_REMATCH[1]}"
    else
      keyword_query="$keyword_query $term"
    fi
  done

  if [ "$auth_method" = "gh_cli" ]; then
    local search_query="repo:$repo"

    # Add keyword search
    if [ -n "$keyword_query" ]; then
      search_query="$search_query $keyword_query"
    fi

    # Add milestone filter
    if [ -n "$milestone_filter" ]; then
      search_query="$search_query milestone:\"$milestone_filter\""
    fi

    # Use gh issue list with search
    local gh_cmd="gh issue list --repo $repo --search \"$search_query\""

    # Add label filters
    for label in $label_filters; do
      gh_cmd="$gh_cmd --label \"$label\""
    done

    gh_cmd="$gh_cmd --json number,title,labels,milestone,state --limit 50"

    eval "$gh_cmd"

  elif [ "$auth_method" = "api" ]; then
    local api_search_url="https://api.github.com/search/issues"
    local search_terms="repo:$repo"

    if [ -n "$keyword_query" ]; then
      search_terms="$search_terms $keyword_query"
    fi

    if [ -n "$label_filters" ]; then
      for label in $label_filters; do
        search_terms="$search_terms label:$label"
      done
    fi

    if [ -n "$milestone_filter" ]; then
      search_terms="$search_terms milestone:\"$milestone_filter\""
    fi

    curl -s -G \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_search_url" \
      --data-urlencode "q=$search_terms" \
      --data-urlencode "per_page=50" | \
      jq '.items'
  fi
}

# Show roadmap summary with counts by status and milestone
show_roadmap_summary() {
  local repo
  repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  local auth_method
  auth_method=$(check_github_auth)

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📊 ROADMAP SUMMARY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [ "$auth_method" = "gh_cli" ]; then
    # Count by status
    echo "By Status:"
    local backlog_count=$(gh issue list --repo "$repo" --label "status:backlog" --json number --jq 'length')
    local next_count=$(gh issue list --repo "$repo" --label "status:next" --json number --jq 'length')
    local later_count=$(gh issue list --repo "$repo" --label "status:later" --json number --jq 'length')
    local in_progress_count=$(gh issue list --repo "$repo" --label "status:in-progress" --json number --jq 'length')
    local blocked_count=$(gh issue list --repo "$repo" --label "status:blocked" --json number --jq 'length')
    local shipped_count=$(gh issue list --repo "$repo" --label "status:shipped" --state closed --json number --jq 'length')

    echo "  Backlog: $backlog_count"
    echo "  Next: $next_count"
    echo "  Later: $later_count"
    echo "  In Progress: $in_progress_count"
    echo "  Blocked: $blocked_count"
    echo "  Shipped: $shipped_count"
    echo ""

    # Count by milestone
    echo "By Milestone:"
    local milestones
    milestones=$(gh api "repos/$repo/milestones?state=all&per_page=100" --jq '.[] | "\(.title)|\(.open_issues)|\(.closed_issues)"')

    if [ -z "$milestones" ]; then
      echo "  (No milestones defined)"
    else
      while IFS='|' read -r title open closed; do
        local total=$((open + closed))
        echo "  $title: $total issues ($open open, $closed closed)"
      done <<< "$milestones"
    fi
    echo ""

    # Show top 5 in Backlog (oldest first = highest priority)
    echo "Top 5 in Backlog (creation order priority):"
    local top_backlog
    top_backlog=$(gh issue list --repo "$repo" --label "status:backlog" --json number,title,createdAt --limit 5 --jq '.[] | "#\(.number) \(.title) (Created: \(.createdAt[:10]))"')

    if [ -z "$top_backlog" ]; then
      echo "  (Empty)"
    else
      echo "$top_backlog" | nl -w2 -s'. '
    fi
    echo ""

    # Show issues in Next
    echo "In Next (ready to start):"
    local next_issues
    next_issues=$(gh issue list --repo "$repo" --label "status:next" --json number,title --jq '.[] | "#\(.number) \(.title)"')

    if [ -z "$next_issues" ]; then
      echo "  (Empty)"
    else
      echo "$next_issues" | nl -w2 -s'. '
    fi
    echo ""

    # Show currently in progress
    echo "In Progress:"
    local in_progress_issues
    in_progress_issues=$(gh issue list --repo "$repo" --label "status:in-progress" --json number,title,milestone --jq '.[] | "#\(.number) \(.title) [Milestone: \(.milestone.title // "None")]"')

    if [ -z "$in_progress_issues" ]; then
      echo "  (None)"
    else
      echo "$in_progress_issues" | nl -w2 -s'. '
    fi

  elif [ "$auth_method" = "api" ]; then
    local api_url="https://api.github.com/repos/$repo/issues"

    # Count by status (simplified for API)
    echo "By Status:"
    local backlog_count=$(curl -s -G "$api_url" --data-urlencode "labels=status:backlog" --data-urlencode "per_page=1" -H "Authorization: token $GITHUB_TOKEN" -I | grep -i "^link:" | sed -n 's/.*page=\([0-9]*\)>; rel="last".*/\1/p')
    backlog_count=${backlog_count:-0}
    echo "  Backlog: $backlog_count"

    # Similar for other statuses...
    echo "  (API summary limited - use gh CLI for full details)"
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# Delete roadmap issue (close with wont-fix label)
delete_roadmap_issue() {
  local slug="$1"

  local repo
  repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  # Find issue by slug
  local issue
  issue=$(get_issue_by_slug "$slug")

  if [ -z "$issue" ] || [ "$issue" = "null" ]; then
    echo "⚠️  Issue with slug '$slug' not found in roadmap" >&2
    return 1
  fi

  local issue_number
  issue_number=$(echo "$issue" | jq -r '.number')
  local issue_title
  issue_title=$(echo "$issue" | jq -r '.title')

  echo ""
  echo "⚠️  About to delete roadmap issue:"
  echo "  #$issue_number: $issue_title"
  echo ""
  read -r -p "Are you sure? (yes/no): " confirm

  if [ "$confirm" != "yes" ]; then
    echo "❌ Cancelled"
    return 1
  fi

  local auth_method
  auth_method=$(check_github_auth)

  if [ "$auth_method" = "gh_cli" ]; then
    # Add wont-fix label and close
    gh issue edit "$issue_number" --repo "$repo" --add-label "wont-fix"
    gh issue close "$issue_number" --repo "$repo" --reason "not planned"

  elif [ "$auth_method" = "api" ]; then
    local api_url="https://api.github.com/repos/$repo/issues/$issue_number"

    # Get current labels and add wont-fix
    local current_labels
    current_labels=$(curl -s \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" | jq -r '.labels[].name')

    local new_labels
    new_labels=$(echo "$current_labels" | tr '\n' ',' | sed 's/,$//')
    new_labels="$new_labels,wont-fix"

    local label_array
    label_array=$(echo "$new_labels" | jq -R 'split(",") | map(gsub("^ +| +$";""))')

    local json_body
    json_body=$(jq -n --argjson labels "$label_array" '{state: "closed", labels: $labels}')

    curl -s -X PATCH \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" \
      -d "$json_body" > /dev/null
  fi

  echo "✅ Deleted issue #$issue_number from roadmap (closed with wont-fix)"
}

# ============================================================================
# MILESTONE MANAGEMENT FUNCTIONS
# ============================================================================

# List all milestones
list_milestones() {
  local repo
  repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  local auth_method
  auth_method=$(check_github_auth)

  if [ "$auth_method" = "gh_cli" ]; then
    gh api "repos/$repo/milestones?state=all&per_page=100" \
      --jq '.[] | "  \(.title) - \(.open_issues) open, \(.closed_issues) closed (Due: \(.due_on // "No due date"))"'

  elif [ "$auth_method" = "api" ]; then
    curl -s \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$repo/milestones?state=all&per_page=100" | \
      jq -r '.[] | "  \(.title) - \(.open_issues) open, \(.closed_issues) closed (Due: \(.due_on // "No due date"))"'
  fi
}

# Create a new milestone
create_milestone() {
  local title="$1"
  local due_date="$2"  # YYYY-MM-DD format (optional)
  local description="$3"  # Optional

  if [ -z "$title" ]; then
    echo "Error: Milestone title required" >&2
    return 1
  fi

  local repo
  repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  local auth_method
  auth_method=$(check_github_auth)

  if [ "$auth_method" = "gh_cli" ]; then
    local gh_cmd="gh api repos/$repo/milestones -f title=\"$title\""

    if [ -n "$due_date" ]; then
      # Convert to ISO 8601 format with time
      local due_iso="${due_date}T23:59:59Z"
      gh_cmd="$gh_cmd -f due_on=\"$due_iso\""
    fi

    if [ -n "$description" ]; then
      gh_cmd="$gh_cmd -f description=\"$description\""
    fi

    eval "$gh_cmd"
    echo "✅ Created milestone: $title"

  elif [ "$auth_method" = "api" ]; then
    local api_url="https://api.github.com/repos/$repo/milestones"

    local json_body
    json_body=$(jq -n \
      --arg title "$title" \
      --arg desc "${description:-}" \
      --arg due "${due_date:+${due_date}T23:59:59Z}" \
      '{title: $title, description: $desc, due_on: ($due | select(length > 0))}')

    curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" \
      -d "$json_body" > /dev/null

    echo "✅ Created milestone: $title"
  fi
}

# Plan milestone by assigning backlog issues to it
plan_milestone() {
  local milestone_name="$1"

  if [ -z "$milestone_name" ]; then
    echo "Error: Milestone name required" >&2
    return 1
  fi

  local repo
  repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  local auth_method
  auth_method=$(check_github_auth)

  # Check if milestone exists
  local milestone_exists
  if [ "$auth_method" = "gh_cli" ]; then
    milestone_exists=$(gh api "repos/$repo/milestones" --jq ".[] | select(.title == \"$milestone_name\") | .title")
  elif [ "$auth_method" = "api" ]; then
    milestone_exists=$(curl -s \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$repo/milestones" | \
      jq -r ".[] | select(.title == \"$milestone_name\") | .title")
  fi

  if [ -z "$milestone_exists" ]; then
    echo "❌ Milestone '$milestone_name' does not exist" >&2
    echo ""
    echo "Available milestones:"
    list_milestones
    return 1
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 MILESTONE PLANNING: $milestone_name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Backlog issues (creation order = priority):"
  echo ""

  # Show backlog issues
  if [ "$auth_method" = "gh_cli" ]; then
    local backlog_issues
    backlog_issues=$(gh issue list --repo "$repo" --label "status:backlog" --json number,title,createdAt --limit 20)

    if [ "$(echo "$backlog_issues" | jq 'length')" -eq 0 ]; then
      echo "  (No backlog issues)"
      return 0
    fi

    echo "$backlog_issues" | jq -r '.[] | "#\(.number) \(.title) (Created: \(.createdAt[:10]))"' | nl -w2 -s'. '
    echo ""

    # Interactive assignment
    echo "Enter issue numbers to assign to '$milestone_name' (space-separated, or 'done'):"
    read -r -p "> " issue_numbers

    if [ "$issue_numbers" = "done" ] || [ -z "$issue_numbers" ]; then
      echo "✅ Milestone planning complete"
      return 0
    fi

    # Assign issues
    for num in $issue_numbers; do
      # Remove # prefix if present
      num="${num#\#}"

      gh issue edit "$num" --repo "$repo" --milestone "$milestone_name"
      echo "  ✅ Assigned #$num to $milestone_name"
    done

    echo ""
    echo "✅ Milestone planning complete"

  elif [ "$auth_method" = "api" ]; then
    echo "  (API milestone planning not fully implemented - use gh CLI)"
  fi
}

# ============================================================================
# EPIC LABEL MANAGEMENT
# ============================================================================

# Create epic label dynamically
create_epic_label() {
  local epic_name="$1"
  local description="$2"  # Optional
  local color="${3:-8B5CF6}"  # Default: purple (epic color)

  if [ -z "$epic_name" ]; then
    echo "Error: Epic name required" >&2
    return 1
  fi

  local repo
  repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  local label_name="epic:$epic_name"
  local auth_method
  auth_method=$(check_github_auth)

  # Check if label already exists
  local label_exists
  if [ "$auth_method" = "gh_cli" ]; then
    label_exists=$(gh label list --repo "$repo" --json name --jq ".[] | select(.name == \"$label_name\") | .name")
  elif [ "$auth_method" = "api" ]; then
    label_exists=$(curl -s \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$repo/labels/$label_name" | \
      jq -r '.name // empty')
  fi

  if [ -n "$label_exists" ]; then
    echo "ℹ️  Epic label '$label_name' already exists"
    return 0
  fi

  # Create the label
  if [ "$auth_method" = "gh_cli" ]; then
    local gh_cmd="gh label create \"$label_name\" --repo $repo --color $color"

    if [ -n "$description" ]; then
      gh_cmd="$gh_cmd --description \"$description\""
    else
      gh_cmd="$gh_cmd --description \"Epic: $epic_name\""
    fi

    eval "$gh_cmd"
    echo "✅ Created epic label: $label_name"

  elif [ "$auth_method" = "api" ]; then
    local api_url="https://api.github.com/repos/$repo/labels"

    local label_description="${description:-Epic: $epic_name}"
    local json_body
    json_body=$(jq -n \
      --arg name "$label_name" \
      --arg desc "$label_description" \
      --arg color "$color" \
      '{name: $name, description: $desc, color: $color}')

    curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" \
      -d "$json_body" > /dev/null

    echo "✅ Created epic label: $label_name"
  fi
}

# List all epic labels
list_epic_labels() {
  local repo
  repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  local auth_method
  auth_method=$(check_github_auth)

  echo ""
  echo "Epic Labels:"
  echo ""

  if [ "$auth_method" = "gh_cli" ]; then
    gh label list --repo "$repo" --json name,description --jq '.[] | select(.name | startswith("epic:")) | "  \(.name) - \(.description // "No description")"'

  elif [ "$auth_method" = "api" ]; then
    curl -s \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$repo/labels?per_page=100" | \
      jq -r '.[] | select(.name | startswith("epic:")) | "  \(.name) - \(.description // "No description")"'
  fi

  echo ""
}

# Export functions
export -f check_github_auth
export -f get_repo_info
export -f parse_metadata_from_body
export -f generate_metadata_frontmatter
export -f create_roadmap_issue
export -f get_issue_by_slug
export -f mark_issue_in_progress
export -f mark_issue_shipped
export -f list_issues_by_status
export -f suggest_feature_addition
export -f move_issue_to_section
export -f search_roadmap
export -f show_roadmap_summary
export -f delete_roadmap_issue
export -f list_milestones
export -f create_milestone
export -f plan_milestone
export -f create_epic_label
export -f list_epic_labels
