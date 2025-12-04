#!/usr/bin/env bash

# Track command usage to build learning system
#
# Usage:
#   # Track a command usage
#   .spec-flow/scripts/utils/track-command-usage.sh track "epic" "auto"
#
#   # Get usage statistics for a command
#   .spec-flow/scripts/utils/track-command-usage.sh stats "epic"
#
#   # Get last used mode for a command
#   .spec-flow/scripts/utils/track-command-usage.sh last "epic"
#
#   # Get usage count for a specific mode
#   .spec-flow/scripts/utils/track-command-usage.sh count "epic" "auto"
#
# Records command mode selection in command-history.yaml

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DEFAULT_HISTORY_PATH="$REPO_ROOT/.spec-flow/memory/command-history.yaml"

# Parse action
action="${1:-track}"
shift || true

command_name="$1"
mode="$2"
history_path="${3:-$DEFAULT_HISTORY_PATH}"

# Initialize history file if missing
init_history() {
  if [[ -f "$history_path" ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$history_path")"
  cat > "$history_path" <<'EOF'
# Command Usage History
# Automatically tracks command mode usage to learn user preferences
# DO NOT EDIT MANUALLY - Updated automatically by commands

feature:
  last_used_mode: null
  usage_count:
    auto: 0
    interactive: 0
  last_updated: null

epic:
  last_used_mode: null
  usage_count:
    auto: 0
    interactive: 0
  last_updated: null

tasks:
  last_used_mode: null
  usage_count:
    standard: 0
    ui-first: 0
  last_updated: null

init-project:
  last_used_mode: null
  usage_count:
    interactive: 0
    ci: 0
  last_updated: null

run-prompt:
  last_used_mode: null
  usage_count:
    auto-detect: 0
    parallel: 0
    sequential: 0
  last_updated: null

schema_version: "1.0"
EOF
  echo "Initialized command history at $history_path" >&2
}

# Get usage statistics for AskUserQuestion
get_stats() {
  local cmd="$1"

  if [[ ! -f "$history_path" ]]; then
    echo "{}"
    return 0
  fi

  local content
  content=$(cat "$history_path")

  # Extract last used mode
  local last_used
  last_used=$(echo "$content" | awk -v cmd="$cmd" '
    $0 ~ "^" cmd ":" { in_cmd=1; next }
    in_cmd && /^[a-z]/ { in_cmd=0 }
    in_cmd && /last_used_mode:/ { gsub(/.*last_used_mode: */, ""); print; exit }
  ')
  [[ "$last_used" == "null" ]] && last_used=""

  # Extract usage counts
  local counts
  counts=$(echo "$content" | awk -v cmd="$cmd" '
    $0 ~ "^" cmd ":" { in_cmd=1; next }
    in_cmd && /^[a-z]/ { exit }
    in_cmd && /usage_count:/ { in_usage=1; next }
    in_usage && /^  [a-z]/ { in_usage=0 }
    in_usage && /^ *[a-z-]+:/ {
      gsub(/^ */, "")
      split($0, parts, ": ")
      if (parts[2] != "0" && parts[2] != "") {
        printf "%s:%s ", parts[1], parts[2]
      }
    }
  ')

  # Calculate total
  local total=0
  for pair in $counts; do
    count="${pair##*:}"
    total=$((total + count))
  done

  # Output as JSON for easy parsing
  echo "{\"last_used\": \"$last_used\", \"total\": $total, \"counts\": \"$counts\"}"
}

# Get last used mode for a command
get_last() {
  local cmd="$1"

  if [[ ! -f "$history_path" ]]; then
    echo ""
    return 0
  fi

  local content
  content=$(cat "$history_path")

  local last_used
  last_used=$(echo "$content" | awk -v cmd="$cmd" '
    $0 ~ "^" cmd ":" { in_cmd=1; next }
    in_cmd && /^[a-z]/ { in_cmd=0 }
    in_cmd && /last_used_mode:/ { gsub(/.*last_used_mode: */, ""); print; exit }
  ')

  [[ "$last_used" == "null" ]] && last_used=""
  echo "$last_used"
}

# Get usage count for a specific mode
get_count() {
  local cmd="$1"
  local mode="$2"

  if [[ ! -f "$history_path" ]]; then
    echo "0"
    return 0
  fi

  local content
  content=$(cat "$history_path")

  local count
  count=$(echo "$content" | awk -v cmd="$cmd" -v m="$mode" '
    $0 ~ "^" cmd ":" { in_cmd=1; next }
    in_cmd && /^[a-z]/ { exit }
    in_cmd && /usage_count:/ { in_usage=1; next }
    in_usage && /^  [a-z]/ { in_usage=0 }
    in_usage && $1 ~ m ":" { gsub(/.*: */, ""); print; exit }
  ')

  [[ -z "$count" || "$count" == "null" ]] && count="0"
  echo "$count"
}

# Handle actions
case "$action" in
  track|record)
    # Original tracking functionality
    if [[ -z "$command_name" ]] || [[ -z "$mode" ]]; then
      echo "Usage: $0 track <command> <mode> [history_path]" >&2
      echo "Example: $0 track epic auto" >&2
      exit 1
    fi

    # Initialize if needed
    init_history
    ;;

  stats)
    if [[ -z "$command_name" ]]; then
      echo "Usage: $0 stats <command>" >&2
      exit 1
    fi
    get_stats "$command_name"
    exit 0
    ;;

  last)
    if [[ -z "$command_name" ]]; then
      echo "Usage: $0 last <command>" >&2
      exit 1
    fi
    get_last "$command_name"
    exit 0
    ;;

  count)
    if [[ -z "$command_name" ]] || [[ -z "$mode" ]]; then
      echo "Usage: $0 count <command> <mode>" >&2
      exit 1
    fi
    get_count "$command_name" "$mode"
    exit 0
    ;;

  init)
    init_history
    exit 0
    ;;

  *)
    # Assume track action for backwards compatibility
    if [[ -n "$action" && -n "$command_name" ]]; then
      # Shift arguments back
      mode="$command_name"
      command_name="$action"
      action="track"
      init_history
    else
      echo "Usage: $0 <track|stats|last|count|init> <command> [mode]" >&2
      exit 1
    fi
    ;;
esac

# Only continue for track action

# Get current timestamp in ISO 8601 format
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Read current history
history_content=$(cat "$history_path")

# Extract current usage count for the mode
current_count=$(echo "$history_content" |
    sed -n "/$command_name:/,/^[a-z]/p" |
    grep "  $mode:" |
    sed 's/.*: *//' || echo "0")

# Calculate new count
new_count=$((current_count + 1))

# Create temporary file for updates
temp_file=$(mktemp)

# Update history content
# 1. Update last_used_mode
# 2. Update usage_count for the mode
# 3. Update last_updated timestamp

awk -v cmd="$command_name" \
    -v mode="$mode" \
    -v new_count="$new_count" \
    -v timestamp="$timestamp" '
BEGIN {
    in_command = 0
    in_usage_count = 0
}
{
    # Detect command section start
    if ($0 ~ "^" cmd ":") {
        in_command = 1
        print $0
        next
    }

    # Detect next command (end of current section)
    if (in_command && /^[a-z]/) {
        in_command = 0
        in_usage_count = 0
    }

    # Update last_used_mode
    if (in_command && /last_used_mode:/) {
        print "  last_used_mode: " mode
        next
    }

    # Detect usage_count section
    if (in_command && /usage_count:/) {
        in_usage_count = 1
        print $0
        next
    }

    # Update mode count within usage_count
    if (in_usage_count && $1 == mode ":") {
        print "    " mode ": " new_count
        next
    }

    # Update last_updated timestamp
    if (in_command && /last_updated:/) {
        print "  last_updated: " timestamp
        next
    }

    # End of usage_count section
    if (in_usage_count && /^  [a-z]/) {
        in_usage_count = 0
    }

    # Print line as-is
    print $0
}
' "$history_path" > "$temp_file"

# Replace original file with updated content
mv "$temp_file" "$history_path"

echo "Updated command history: $command_name -> $mode (count: $new_count)" >&2
