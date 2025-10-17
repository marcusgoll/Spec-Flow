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

# Extract incomplete tasks for a specific priority from tasks.md
extract_priority_tasks() {
  local tasks_file="$1"
  local priority="$2"  # e.g., "P2" or "P3"
  local notes_file="$3"

  if [ ! -f "$tasks_file" ]; then
    return 1
  fi

  # Find all tasks with the given priority that are not completed
  local tasks=()

  while IFS= read -r line; do
    # Match task lines with priority marker
    if echo "$line" | grep -q "^T[0-9]\{3\}.*\[$priority\]"; then
      TASK_ID=$(echo "$line" | grep -o "^T[0-9]\{3\}")

      # Check if task is completed in NOTES.md
      if ! grep -q "✅ $TASK_ID" "$notes_file" 2>/dev/null; then
        # Task is incomplete, extract description
        TASK_DESC=$(echo "$line" | sed 's/^T[0-9]\{3\} //' | sed 's/\[US[0-9]\] //' | sed 's/\[P[0-9]\] //' | sed 's/\[P\] //')
        tasks+=("$TASK_DESC")
      fi
    fi
  done < "$tasks_file"

  # Output tasks as newline-separated list
  printf '%s\n' "${tasks[@]}"
}

# Format enhancement entry for roadmap
format_enhancement_entry() {
  local parent_slug="$1"
  local priority="$2"
  local task_count="$3"
  local task_list="$4"
  local parent_area="${5:-app}"
  local parent_role="${6:-all}"
  local parent_impact="${7:-3}"

  # Generate slug for enhancement
  local enhancement_slug="${parent_slug}-${priority,,}-enhancements"

  # Calculate ICE score based on parent feature and priority
  local impact=$parent_impact
  local effort=2  # Default: 1-2 weeks
  local confidence="0.9"  # High confidence (already specified)

  # Adjust impact based on priority
  if [ "$priority" = "P3" ]; then
    impact=$((impact - 1))
    [ $impact -lt 1 ] && impact=1
  fi

  # Calculate score: Impact * Confidence / Effort
  local score
  score=$(awk "BEGIN {printf \"%.2f\", $impact * $confidence / $effort}")

  # Build requirements list from tasks
  local requirements=""
  while IFS= read -r task; do
    [ -z "$task" ] && continue
    requirements="${requirements}  - [$priority] $task\n"
  done <<< "$task_list"

  # Format entry
  cat <<EOF
### $enhancement_slug
- **Title**: $(echo "$parent_slug" | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g') - $priority Enhancements
- **Area**: $parent_area
- **Role**: $parent_role
- **Impact**: $impact | **Effort**: $effort | **Confidence**: $confidence | **Score**: $score
- **Parent Feature**: $parent_slug
- **Requirements**:
$(echo -e "$requirements")- **Spec**: specs/$parent_slug/spec.md ($priority section)
- **Tasks**: $task_count tasks
EOF
}

# Add future enhancements to roadmap when shipping MVP
add_future_enhancements_to_roadmap() {
  local feature_dir="$1"
  local slug="$2"

  if [ ! -d "$feature_dir" ]; then
    echo "Error: Feature directory not found: $feature_dir" >&2
    return 1
  fi

  local tasks_file="$feature_dir/tasks.md"
  local notes_file="$feature_dir/NOTES.md"
  local spec_file="$feature_dir/spec.md"

  if [ ! -f "$tasks_file" ]; then
    echo "Error: tasks.md not found: $tasks_file" >&2
    return 1
  fi

  # Extract metadata from spec if available
  local area="app"
  local role="all"
  local impact="3"

  if [ -f "$spec_file" ]; then
    # Try to extract area, role, impact from spec metadata
    area=$(grep -i "^Area:" "$spec_file" | head -1 | sed 's/Area: *//' | tr '[:upper:]' '[:lower:]' || echo "app")
    role=$(grep -i "^Role:" "$spec_file" | head -1 | sed 's/Role: *//' | tr '[:upper:]' '[:lower:]' || echo "all")
    impact=$(grep -i "^Impact:" "$spec_file" | head -1 | sed 's/Impact: *//' | grep -o "[0-9]" | head -1 || echo "3")
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 Capturing Future Enhancements in Roadmap"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  local added_count=0

  # Process P2 tasks
  local p2_tasks
  p2_tasks=$(extract_priority_tasks "$tasks_file" "P2" "$notes_file")

  if [ -n "$p2_tasks" ]; then
    local p2_count
    p2_count=$(echo "$p2_tasks" | grep -c "." || echo 0)

    if [ "$p2_count" -gt 0 ]; then
      echo "Adding P2 enhancements to roadmap..."

      local p2_entry
      p2_entry=$(format_enhancement_entry "$slug" "P2" "$p2_count" "$p2_tasks" "$area" "$role" "$impact")

      local p2_slug="${slug}-p2-enhancements"

      # Add to Next section
      add_feature_to_section "Next" "$p2_entry" "$p2_slug"

      echo "  ✅ Created: $p2_slug ($p2_count tasks)"
      echo "  ✅ Added to: Next section"
      ((added_count++))
    fi
  fi

  # Process P3 tasks
  local p3_tasks
  p3_tasks=$(extract_priority_tasks "$tasks_file" "P3" "$notes_file")

  if [ -n "$p3_tasks" ]; then
    local p3_count
    p3_count=$(echo "$p3_tasks" | grep -c "." || echo 0)

    if [ "$p3_count" -gt 0 ]; then
      echo ""
      echo "Adding P3 features to roadmap..."

      local p3_entry
      p3_entry=$(format_enhancement_entry "$slug" "P3" "$p3_count" "$p3_tasks" "$area" "$role" "$impact")

      local p3_slug="${slug}-p3-features"

      # Add to Later section
      add_feature_to_section "Later" "$p3_entry" "$p3_slug"

      echo "  ✅ Created: $p3_slug ($p3_count tasks)"
      echo "  ✅ Added to: Later section"
      ((added_count++))
    fi
  fi

  echo ""

  if [ "$added_count" -eq 0 ]; then
    echo "ℹ️  No P2/P3 tasks found to add to roadmap"
    return 0
  fi

  echo "📋 Future enhancements captured in roadmap!"
  echo ""
  echo "To implement later:"
  [ -n "$p2_tasks" ] && [ "$p2_count" -gt 0 ] && echo "  /spec-flow ${slug}-p2-enhancements"
  [ -n "$p3_tasks" ] && [ "$p3_count" -gt 0 ] && echo "  /spec-flow ${slug}-p3-features"
  echo ""

  return 0
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
export -f extract_priority_tasks
export -f format_enhancement_entry
export -f add_future_enhancements_to_roadmap
