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
  local auth_method=$(check_github_auth)

  if [ "$auth_method" = "gh_cli" ]; then
    gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo ""
  elif [ "$auth_method" = "api" ]; then
    local remote_url=$(git config --get remote.origin.url 2>/dev/null || echo "")
    echo "$remote_url" | sed -E 's/.*github\.com[:/](.*)\.git/\1/' | sed 's/\.git$//'
  else
    echo ""
  fi
}

# ============================================================================
# ICE SCORING FUNCTIONS
# ============================================================================

# Calculate ICE score from impact, effort, confidence
calculate_ice_score() {
  local impact="$1"
  local effort="$2"
  local confidence="$3"

  # ICE = (Impact × Confidence) / Effort
  awk "BEGIN {printf \"%.2f\", ($impact * $confidence) / $effort}"
}

# Parse ICE frontmatter from issue body
parse_ice_from_body() {
  local body="$1"

  # Extract YAML frontmatter between --- delimiters
  local frontmatter=$(echo "$body" | awk '/^---$/,/^---$/ {if (!/^---$/) print}')

  if [ -z "$frontmatter" ]; then
    echo "{}"
    return 1
  fi

  # Parse ICE values
  local impact=$(echo "$frontmatter" | grep "impact:" | sed 's/.*impact: *//' | tr -d ' ')
  local effort=$(echo "$frontmatter" | grep "effort:" | sed 's/.*effort: *//' | tr -d ' ')
  local confidence=$(echo "$frontmatter" | grep "confidence:" | sed 's/.*confidence: *//' | tr -d ' ')
  local area=$(echo "$frontmatter" | grep "area:" | sed 's/.*area: *//' | tr -d ' ')
  local role=$(echo "$frontmatter" | grep "role:" | sed 's/.*role: *//' | tr -d ' ')
  local slug=$(echo "$frontmatter" | grep "slug:" | sed 's/.*slug: *//' | tr -d ' ')

  # Return JSON
  cat <<EOF
{
  "impact": ${impact:-3},
  "effort": ${effort:-3},
  "confidence": ${confidence:-0.7},
  "area": "${area:-app}",
  "role": "${role:-all}",
  "slug": "${slug:-unknown}"
}
EOF
}

# Generate ICE frontmatter for issue body
generate_ice_frontmatter() {
  local impact="$1"
  local effort="$2"
  local confidence="$3"
  local area="${4:-app}"
  local role="${5:-all}"
  local slug="$6"
  local score=$(calculate_ice_score "$impact" "$effort" "$confidence")

  cat <<EOF
---
ice:
  impact: $impact
  effort: $effort
  confidence: $confidence
  score: $score
metadata:
  area: $area
  role: $role
  slug: $slug
---
EOF
}

# ============================================================================
# ISSUE OPERATIONS
# ============================================================================

# Create a roadmap issue with ICE frontmatter
create_roadmap_issue() {
  local title="$1"
  local body="$2"
  local impact="$3"
  local effort="$4"
  local confidence="$5"
  local area="${6:-app}"
  local role="${7:-all}"
  local slug="$8"
  local labels="${9:-type:feature,status:backlog}"

  local repo=$(get_repo_info)
  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  # Generate frontmatter
  local frontmatter=$(generate_ice_frontmatter "$impact" "$effort" "$confidence" "$area" "$role" "$slug")

  # Combine frontmatter with body
  local full_body=$(cat <<EOF
$frontmatter

$body
EOF
)

  # Add area and role labels
  local all_labels="$labels,area:$area,role:$role"

  # Determine size label based on effort
  case "$effort" in
    1) all_labels="$all_labels,size:small" ;;
    2) all_labels="$all_labels,size:small" ;;
    3) all_labels="$all_labels,size:medium" ;;
    4) all_labels="$all_labels,size:large" ;;
    5) all_labels="$all_labels,size:xl" ;;
  esac

  # Determine priority label based on ICE score
  local score=$(calculate_ice_score "$impact" "$effort" "$confidence")
  local priority="medium"
  if awk "BEGIN {exit !($score >= 1.5)}"; then
    priority="high"
  elif awk "BEGIN {exit !($score < 0.8)}"; then
    priority="low"
  fi
  all_labels="$all_labels,priority:$priority"

  # Create issue
  local auth_method=$(check_github_auth)

  if [ "$auth_method" = "gh_cli" ]; then
    gh issue create \
      --repo "$repo" \
      --title "$title" \
      --body "$full_body" \
      --label "$all_labels"
  elif [ "$auth_method" = "api" ]; then
    # Use GitHub API
    local api_url="https://api.github.com/repos/$repo/issues"
    local label_array=$(echo "$all_labels" | jq -R 'split(",") | map(gsub("^ +| +$";""))')

    local json_body=$(jq -n \
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
  local repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  local auth_method=$(check_github_auth)

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

# Update issue ICE scores
update_issue_ice() {
  local issue_number="$1"
  local impact="$2"
  local effort="$3"
  local confidence="$4"

  local repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  local auth_method=$(check_github_auth)

  # Get current issue body
  local current_body=""
  if [ "$auth_method" = "gh_cli" ]; then
    current_body=$(gh issue view "$issue_number" --repo "$repo" --json body -q .body)
  elif [ "$auth_method" = "api" ]; then
    local api_url="https://api.github.com/repos/$repo/issues/$issue_number"
    current_body=$(curl -s \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" | jq -r '.body')
  else
    echo "Error: No GitHub authentication available" >&2
    return 1
  fi

  # Parse existing metadata
  local metadata=$(parse_ice_from_body "$current_body")
  local area=$(echo "$metadata" | jq -r '.area')
  local role=$(echo "$metadata" | jq -r '.role')
  local slug=$(echo "$metadata" | jq -r '.slug')

  # Remove old frontmatter
  local body_without_frontmatter=$(echo "$current_body" | sed '/^---$/,/^---$/d' | sed '/^$/d')

  # Generate new frontmatter
  local new_frontmatter=$(generate_ice_frontmatter "$impact" "$effort" "$confidence" "$area" "$role" "$slug")

  # Combine
  local new_body=$(cat <<EOF
$new_frontmatter

$body_without_frontmatter
EOF
)

  # Update issue
  if [ "$auth_method" = "gh_cli" ]; then
    echo "$new_body" | gh issue edit "$issue_number" --repo "$repo" --body-file -
  elif [ "$auth_method" = "api" ]; then
    local api_url="https://api.github.com/repos/$repo/issues/$issue_number"
    local json_body=$(jq -n --arg body "$new_body" '{body: $body}')

    curl -s -X PATCH \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" \
      -d "$json_body"
  fi
}

# Mark issue as in progress
mark_issue_in_progress() {
  local slug="$1"
  local repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  # Find issue by slug
  local issue=$(get_issue_by_slug "$slug")

  if [ -z "$issue" ] || [ "$issue" = "null" ]; then
    echo "⚠️  Issue with slug '$slug' not found in roadmap" >&2
    return 1
  fi

  local issue_number=$(echo "$issue" | jq -r '.number')

  # Add in-progress label, remove backlog/next/later labels
  local auth_method=$(check_github_auth)

  if [ "$auth_method" = "gh_cli" ]; then
    gh issue edit "$issue_number" \
      --repo "$repo" \
      --remove-label "status:backlog,status:next,status:later" \
      --add-label "status:in-progress"
  elif [ "$auth_method" = "api" ]; then
    local api_url="https://api.github.com/repos/$repo/issues/$issue_number"

    # Get current labels
    local current_labels=$(curl -s \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" | jq -r '.labels[].name')

    # Filter out status labels and add in-progress
    local new_labels=$(echo "$current_labels" | grep -v "^status:" | tr '\n' ',' | sed 's/,$//')
    new_labels="$new_labels,status:in-progress"

    # Update
    local label_array=$(echo "$new_labels" | jq -R 'split(",") | map(gsub("^ +| +$";""))')
    local json_body=$(jq -n --argjson labels "$label_array" '{labels: $labels}')

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

  local repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  # Find issue by slug
  local issue=$(get_issue_by_slug "$slug")

  if [ -z "$issue" ] || [ "$issue" = "null" ]; then
    echo "⚠️  Issue with slug '$slug' not found in roadmap" >&2
    return 1
  fi

  local issue_number=$(echo "$issue" | jq -r '.number')

  # Add shipped label, close issue
  local auth_method=$(check_github_auth)

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
    local current_labels=$(curl -s \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" | jq -r '.labels[].name')

    # Filter out status labels and add shipped
    local new_labels=$(echo "$current_labels" | grep -v "^status:" | tr '\n' ',' | sed 's/,$//')
    new_labels="$new_labels,status:shipped"

    # Update labels and close
    local label_array=$(echo "$new_labels" | jq -R 'split(",") | map(gsub("^ +| +$";""))')
    local json_body=$(jq -n \
      --argjson labels "$label_array" \
      '{state: "closed", labels: $labels}')

    curl -s -X PATCH \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "$api_url" \
      -d "$json_body"

    # Add comment
    local comment_url="$api_url/comments"
    local comment_body=$(jq -n --arg body "$comment" '{body: $body}')

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
  local repo=$(get_repo_info)

  if [ -z "$repo" ]; then
    echo "Error: Could not determine repository" >&2
    return 1
  fi

  local auth_method=$(check_github_auth)
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
      local slug=$(echo "$description" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | cut -c1-30)

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

# Export functions
export -f check_github_auth
export -f get_repo_info
export -f calculate_ice_score
export -f parse_ice_from_body
export -f generate_ice_frontmatter
export -f create_roadmap_issue
export -f get_issue_by_slug
export -f update_issue_ice
export -f mark_issue_in_progress
export -f mark_issue_shipped
export -f list_issues_by_status
export -f suggest_feature_addition
