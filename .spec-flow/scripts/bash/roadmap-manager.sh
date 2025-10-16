#!/bin/bash

# roadmap-manager.sh - Roadmap management functions for Spec-Flow
#
# Provides functions to manage roadmap status throughout the feature lifecycle:
# - Mark features as in-progress when starting
# - Mark features as shipped when deploying
# - Suggest adding discovered features
# - Query feature status in roadmap
#
# Version: 1.0.0
# Requires: None (uses standard bash tools)

set -e

ROADMAP_FILE=".spec-flow/memory/roadmap.md"

# Check if feature exists in roadmap and return its status
get_feature_status() {
  local slug="$1"

  if [ ! -f "$ROADMAP_FILE" ]; then
    echo "not_found"
    return 1
  fi

  # Search for feature in different sections
  if grep -A 20 "^### $slug" "$ROADMAP_FILE" | head -1 | grep -q "### $slug"; then
    # Found the feature, now determine which section
    local line_num
    line_num=$(grep -n "^### $slug" "$ROADMAP_FILE" | head -1 | cut -d: -f1)

    # Find the section header above this line
    local section_line
    section_line=$(head -n "$line_num" "$ROADMAP_FILE" | grep -n "^## " | tail -1 | cut -d: -f1)

    if [ -z "$section_line" ]; then
      echo "unknown"
      return 0
    fi

    local section
    section=$(sed -n "${section_line}p" "$ROADMAP_FILE" | sed 's/^## //')

    case "$section" in
      "Shipped")
        echo "shipped"
        ;;
      "In Progress")
        echo "in_progress"
        ;;
      "Next")
        echo "next"
        ;;
      "Later")
        echo "later"
        ;;
      "Backlog")
        echo "backlog"
        ;;
      *)
        echo "unknown"
        ;;
    esac
  else
    echo "not_found"
    return 1
  fi
}

# Mark feature as in progress (move from Backlog/Next to In Progress)
mark_feature_in_progress() {
  local slug="$1"

  if [ ! -f "$ROADMAP_FILE" ]; then
    echo "Error: Roadmap not found: $ROADMAP_FILE" >&2
    return 1
  fi

  local status
  status=$(get_feature_status "$slug")

  if [ "$status" = "not_found" ]; then
    echo "⚠️  Feature '$slug' not found in roadmap" >&2
    return 1
  fi

  if [ "$status" = "in_progress" ]; then
    # Already in progress
    return 0
  fi

  if [ "$status" = "shipped" ]; then
    echo "⚠️  Feature '$slug' already shipped" >&2
    return 1
  fi

  # Extract the feature block
  local feature_block
  feature_block=$(extract_feature_block "$slug")

  if [ -z "$feature_block" ]; then
    echo "Error: Could not extract feature block for $slug" >&2
    return 1
  fi

  # Remove from current location
  remove_feature_from_section "$slug"

  # Add to In Progress section
  add_feature_to_section "In Progress" "$feature_block" "$slug"

  echo "✅ Marked '$slug' as In Progress in roadmap"
}

# Mark feature as shipped (move to Shipped section with metadata)
mark_feature_shipped() {
  local slug="$1"
  local version="$2"
  local date="$3"
  local prod_url="${4:-}"

  if [ ! -f "$ROADMAP_FILE" ]; then
    echo "Error: Roadmap not found: $ROADMAP_FILE" >&2
    return 1
  fi

  local status
  status=$(get_feature_status "$slug")

  if [ "$status" = "not_found" ]; then
    echo "⚠️  Feature '$slug' not found in roadmap" >&2
    return 1
  fi

  if [ "$status" = "shipped" ]; then
    # Already shipped, update metadata
    echo "Feature already shipped, updating metadata..."
  fi

  # Extract feature title and basic info
  local feature_info
  feature_info=$(extract_feature_basic_info "$slug")

  # Remove from current location
  remove_feature_from_section "$slug"

  # Create shipped entry (without ICE scores)
  local shipped_block
  shipped_block=$(cat <<EOF
### $slug
$feature_info
- **Date**: $date
- **Release**: v$version
EOF
)

  if [ -n "$prod_url" ]; then
    shipped_block=$(cat <<EOF
$shipped_block
- **URL**: $prod_url
EOF
)
  fi

  # Add to Shipped section (at the top, newest first)
  insert_at_section_start "Shipped" "$shipped_block"

  echo "✅ Marked '$slug' as Shipped (v$version) in roadmap"
}

# Suggest adding a discovered feature to the roadmap
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
  read -r -p "Add to roadmap? (yes/no/later): " response

  case "$response" in
    yes|y|Y)
      echo ""
      echo "Adding to roadmap using /roadmap command..."
      echo ""
      # Note: This would call the roadmap command
      # For now, we'll just save to discovered features
      save_discovered_feature "$description" "$context"
      echo "💡 Tip: Run: /roadmap add \"$description\""
      ;;
    later|l|L)
      save_discovered_feature "$description" "$context"
      echo "📝 Saved to discovered features. Review later with:"
      echo "   cat .spec-flow/memory/discovered-features.md"
      ;;
    *)
      echo "⏭️  Skipped"
      ;;
  esac
}

# Save discovered feature for later review
save_discovered_feature() {
  local description="$1"
  local context="$2"

  local discovered_file=".spec-flow/memory/discovered-features.md"

  # Create file if doesn't exist
  if [ ! -f "$discovered_file" ]; then
    mkdir -p "$(dirname "$discovered_file")"
    cat > "$discovered_file" <<EOF
# Discovered Features

Features discovered during development that could be added to the roadmap.

---

EOF
  fi

  # Append discovered feature
  cat >> "$discovered_file" <<EOF
## $(date +%Y-%m-%d) - Discovered in: $context

**Description**: $description

**Action**: Review and add to roadmap with: \`/roadmap add "$description"\`

---

EOF

  echo "✅ Saved to: $discovered_file"
}

# Helper: Extract full feature block from roadmap
extract_feature_block() {
  local slug="$1"

  # Find the feature header and extract until the next feature or section
  awk "/^### $slug\$/{flag=1; next} /^###|^##/{flag=0} flag" "$ROADMAP_FILE"
}

# Helper: Extract basic feature info (title, area, role)
extract_feature_basic_info() {
  local slug="$1"

  # Extract lines between feature header and next header, filter for basic info
  awk "/^### $slug\$/{flag=1; next} /^###|^##/{flag=0} flag" "$ROADMAP_FILE" | \
    grep -E "^\- \*\*(Title|Area|Role):" || echo ""
}

# Helper: Remove feature from its current section
remove_feature_from_section() {
  local slug="$1"

  # Create temp file
  local temp_file="${ROADMAP_FILE}.tmp"

  # Remove feature block (from ### slug until next ### or ##)
  awk "/^### $slug\$/{flag=1; next} /^###|^##/{flag=0} flag{next} {print}" "$ROADMAP_FILE" > "$temp_file"

  # Also remove the feature header line
  grep -v "^### $slug\$" "$temp_file" > "${ROADMAP_FILE}.tmp2"
  mv "${ROADMAP_FILE}.tmp2" "$temp_file"

  mv "$temp_file" "$ROADMAP_FILE"
}

# Helper: Add feature to a specific section
add_feature_to_section() {
  local section="$1"
  local feature_block="$2"
  local slug="$3"

  local temp_file="${ROADMAP_FILE}.tmp"

  # Find the section and add feature at the end of that section
  awk -v section="## $section" -v slug="$slug" -v block="$feature_block" '
    $0 ~ section {
      in_section=1
      print
      next
    }
    /^##/ && in_section {
      # Reached next section, insert feature before it
      print "### " slug
      print block
      print ""
      in_section=0
    }
    {print}
    END {
      if (in_section) {
        # Section was last, append feature
        print "### " slug
        print block
        print ""
      }
    }
  ' "$ROADMAP_FILE" > "$temp_file"

  mv "$temp_file" "$ROADMAP_FILE"
}

# Helper: Insert feature at start of section (for Shipped - newest first)
insert_at_section_start() {
  local section="$1"
  local feature_block="$2"

  local temp_file="${ROADMAP_FILE}.tmp"

  awk -v section="## $section" -v block="$feature_block" '
    $0 ~ section {
      print
      # Print some space then the new feature
      print ""
      print block
      print ""
      next
    }
    {print}
  ' "$ROADMAP_FILE" > "$temp_file"

  mv "$temp_file" "$ROADMAP_FILE"
}

# Export functions (for sourcing)
export -f get_feature_status
export -f mark_feature_in_progress
export -f mark_feature_shipped
export -f suggest_feature_addition
export -f save_discovered_feature
export -f extract_feature_block
export -f extract_feature_basic_info
export -f remove_feature_from_section
export -f add_feature_to_section
export -f insert_at_section_start
