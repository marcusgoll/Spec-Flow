#!/bin/bash
# detect-workflow-paths.sh
# Detects workflow type (epic vs feature) and returns base directory
#
# Detection priority (as per user preference):
# 1. Workspace files (epics/*/epic-spec.md OR specs/*/spec.md)
# 2. Git branch pattern (epic/* OR feature/*)
# 3. workflow-state.yaml (workflow_type field)
# 4. Return failure code for fallback to AskUserQuestion
#
# Output: JSON object with workflow information
# Exit codes: 0=success, 1=detection failed

set -e

# Get current branch safely
get_current_branch() {
    git branch --show-current 2>/dev/null || echo "unknown"
}

# Priority 1: Check for workspace files
detect_from_files() {
    # Check for epic workspace
    if ls epics/*/epic-spec.md 1>/dev/null 2>&1; then
        local epic_dir=$(dirname "$(ls epics/*/epic-spec.md 2>/dev/null | head -n 1)")
        local epic_slug=$(basename "$epic_dir")
        echo "{\"type\":\"epic\",\"base_dir\":\"epics\",\"slug\":\"$epic_slug\",\"branch\":\"$(get_current_branch)\",\"source\":\"files\"}"
        return 0
    fi

    # Check for feature workspace
    if ls specs/*/spec.md 1>/dev/null 2>&1; then
        local feature_dir=$(dirname "$(ls specs/*/spec.md 2>/dev/null | head -n 1)")
        local feature_slug=$(basename "$feature_dir")
        echo "{\"type\":\"feature\",\"base_dir\":\"specs\",\"slug\":\"$feature_slug\",\"branch\":\"$(get_current_branch)\",\"source\":\"files\"}"
        return 0
    fi

    return 1
}

# Priority 2: Check git branch pattern
detect_from_branch() {
    local current_branch=$(get_current_branch)

    # Check for epic branch pattern (epic/NNN-slug or epic/slug)
    if [[ "$current_branch" =~ ^epic/ ]]; then
        # Extract slug from branch name
        local slug="${current_branch#epic/}"
        echo "{\"type\":\"epic\",\"base_dir\":\"epics\",\"slug\":\"$slug\",\"branch\":\"$current_branch\",\"source\":\"branch\"}"
        return 0
    fi

    # Check for feature branch pattern (feature/NNN-slug or feature/slug)
    if [[ "$current_branch" =~ ^feature/ ]]; then
        # Extract slug from branch name
        local slug="${current_branch#feature/}"
        echo "{\"type\":\"feature\",\"base_dir\":\"specs\",\"slug\":\"$slug\",\"branch\":\"$current_branch\",\"source\":\"branch\"}"
        return 0
    fi

    return 1
}

# Priority 3: Check workflow-state.yaml
detect_from_state() {
    # Check epic workflow-state.yaml
    if ls epics/*/workflow-state.yaml 1>/dev/null 2>&1; then
        local state_file=$(ls epics/*/workflow-state.yaml 2>/dev/null | head -n 1)
        local workflow_type=$(grep "^workflow_type:" "$state_file" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "unknown")

        if [ "$workflow_type" = "epic" ]; then
            local epic_dir=$(dirname "$state_file")
            local epic_slug=$(basename "$epic_dir")
            echo "{\"type\":\"epic\",\"base_dir\":\"epics\",\"slug\":\"$epic_slug\",\"branch\":\"$(get_current_branch)\",\"source\":\"state\"}"
            return 0
        fi
    fi

    # Check feature workflow-state.yaml
    if ls specs/*/workflow-state.yaml 1>/dev/null 2>&1; then
        local state_file=$(ls specs/*/workflow-state.yaml 2>/dev/null | head -n 1)
        local workflow_type=$(grep "^workflow_type:" "$state_file" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "unknown")

        if [ "$workflow_type" = "feature" ]; then
            local feature_dir=$(dirname "$state_file")
            local feature_slug=$(basename "$feature_dir")
            echo "{\"type\":\"feature\",\"base_dir\":\"specs\",\"slug\":\"$feature_slug\",\"branch\":\"$(get_current_branch)\",\"source\":\"state\"}"
            return 0
        fi
    fi

    return 1
}

# Main detection logic
main() {
    # Try each detection method in priority order
    if detect_from_files; then
        return 0
    fi

    if detect_from_branch; then
        return 0
    fi

    if detect_from_state; then
        return 0
    fi

    # All detection methods failed
    echo "{\"type\":\"unknown\",\"base_dir\":\"unknown\",\"slug\":\"unknown\",\"branch\":\"$(get_current_branch)\",\"source\":\"none\",\"error\":\"Could not detect workflow type\"}" >&2
    return 1
}

# Run main detection
main
