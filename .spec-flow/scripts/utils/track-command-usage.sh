#!/usr/bin/env bash

# Track command usage to build learning system
#
# Usage:
#   .spec-flow/scripts/utils/track-command-usage.sh "epic" "auto"
#
# Records command mode selection in command-history.yaml

set -e

command_name="$1"
mode="$2"
history_path="${3:-.spec-flow/memory/command-history.yaml}"

# Validate arguments
if [[ -z "$command_name" ]] || [[ -z "$mode" ]]; then
    echo "Usage: $0 <command> <mode> [history_path]" >&2
    echo "Example: $0 epic auto" >&2
    exit 1
fi

# Check if history file exists
if [[ ! -f "$history_path" ]]; then
    echo "Command history file not found at $history_path" >&2
    exit 1
fi

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
