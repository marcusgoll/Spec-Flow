#!/usr/bin/env bash
# NOTES.md Update Template
# Reusable functions for consistent NOTES.md updates across workflow commands

set -euo pipefail

# Function: Update NOTES.md with phase checkpoint
# Usage: update_notes_checkpoint <feature_dir> <phase_num> <phase_name> <metrics_array>
# Example: update_notes_checkpoint "$FEATURE_DIR" "0.5" "Clarify" "Questions answered:$ANSWERED_COUNT" "Ambiguities remaining:$REMAINING_COUNT"
update_notes_checkpoint() {
  local feature_dir="$1"
  local phase_num="$2"
  local phase_name="$3"
  shift 3
  local metrics=("$@")

  local notes_file="$feature_dir/NOTES.md"

  if [ ! -f "$notes_file" ]; then
    echo "ERROR: NOTES.md not found at $notes_file" >&2
    return 1
  fi

  # Check if checkpoint already exists
  if grep -q "Phase $phase_num ($phase_name):" "$notes_file"; then
    echo "INFO: Phase $phase_num checkpoint already exists, updating..." >&2
    # Remove old checkpoint (will be replaced)
    sed -i "/- .*Phase $phase_num ($phase_name):/,/^$/d" "$notes_file"
  fi

  # Append new checkpoint
  cat >> "$notes_file" <<EOF

## Checkpoints
- ✅ Phase $phase_num ($phase_name): $(date -u +"%Y-%m-%d")
EOF

  # Add metrics if provided
  for metric in "${metrics[@]}"; do
    echo "  - $metric" >> "$notes_file"
  done

  echo "" >> "$notes_file"
}

# Function: Update Last Updated timestamp
# Usage: update_notes_timestamp <feature_dir>
update_notes_timestamp() {
  local feature_dir="$1"
  local notes_file="$feature_dir/NOTES.md"

  if [ ! -f "$notes_file" ]; then
    echo "ERROR: NOTES.md not found at $notes_file" >&2
    return 1
  fi

  # Remove old timestamp
  sed -i '/^## Last Updated/,/^$/d' "$notes_file"

  # Append new timestamp
  cat >> "$notes_file" <<EOF

## Last Updated
$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
}

# Function: Add phase summary section
# Usage: update_notes_summary <feature_dir> <phase_num> <summary_lines>
# Example: update_notes_summary "$FEATURE_DIR" "2" "Total tasks: 41" "Critical path: 15 tasks"
update_notes_summary() {
  local feature_dir="$1"
  local phase_num="$2"
  shift 2
  local summary_lines=("$@")

  local notes_file="$feature_dir/NOTES.md"

  if [ ! -f "$notes_file" ]; then
    echo "ERROR: NOTES.md not found at $notes_file" >&2
    return 1
  fi

  # Check if summary already exists
  if grep -q "### Phase $phase_num Summary" "$notes_file"; then
    echo "INFO: Phase $phase_num summary already exists, updating..." >&2
    sed -i "/### Phase $phase_num Summary/,/^$/d" "$notes_file"
  fi

  # Insert summary before Checkpoints section
  local temp_file=$(mktemp)
  awk -v phase="$phase_num" '
    /^## Checkpoints/ && !done {
      print ""
      print "### Phase " phase " Summary"
      done=1
    }
    { print }
  ' "$notes_file" > "$temp_file"

  mv "$temp_file" "$notes_file"

  # Add summary lines
  for line in "${summary_lines[@]}"; do
    sed -i "/### Phase $phase_num Summary/a - $line" "$notes_file"
  done
}

# Function: Add context budget tracking
# Usage: update_notes_context_budget <feature_dir> <phase_num> <token_count> <artifact_name>
update_notes_context_budget() {
  local feature_dir="$1"
  local phase_num="$2"
  local token_count="$3"
  local artifact_name="$4"

  local notes_file="$feature_dir/NOTES.md"

  if [ ! -f "$notes_file" ]; then
    echo "ERROR: NOTES.md not found at $notes_file" >&2
    return 1
  fi

  # Check if Context Budget section exists
  if ! grep -q "^## Context Budget" "$notes_file"; then
    # Add section before Last Updated
    sed -i '/^## Last Updated/i## Context Budget\n' "$notes_file"
  fi

  # Add or update phase entry
  if grep -q "- Phase $phase_num:" "$notes_file"; then
    sed -i "s/- Phase $phase_num:.*$/- Phase $phase_num: $token_count tokens ($artifact_name)/" "$notes_file"
  else
    sed -i "/^## Context Budget/a - Phase $phase_num: $token_count tokens ($artifact_name)" "$notes_file"
  fi
}

# Function: Initialize NOTES.md with standard structure
# Usage: init_notes <feature_dir> <feature_name>
init_notes() {
  local feature_dir="$1"
  local feature_name="$2"
  local notes_file="$feature_dir/NOTES.md"

  if [ -f "$notes_file" ]; then
    echo "INFO: NOTES.md already exists at $notes_file" >&2
    return 0
  fi

  cat > "$notes_file" <<EOF
# Feature: $feature_name

## Overview
[To be filled during spec generation]

## Research Findings
[Populated during research phase]

## Feature Classification
- UI screens: [Auto-detected from screens.yaml presence]
- Improvement: [Auto-detected from spec keywords]
- Measurable: [Auto-detected from heart-metrics.md presence]
- Deployment impact: [Manual - requires human judgment]

## System Components Analysis
[Populated during system component check]

## Checkpoints
- Phase 0 \spec-flow): $(date -u +"%Y-%m-%d")

## Last Updated
$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

  echo "INFO: Created NOTES.md at $notes_file" >&2
}

# Export functions for sourcing
export -f update_notes_checkpoint
export -f update_notes_timestamp
export -f update_notes_summary
export -f update_notes_context_budget
export -f init_notes

