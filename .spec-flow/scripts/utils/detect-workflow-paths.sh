#!/bin/bash
# detect-workflow-paths.sh
# Detects workflow type (epic vs feature) and returns base directory
#
# Detection priority (as per user preference):
# 1. Workspace files (epics/*/epic-spec.md OR specs/*/spec.md)
# 2. Git branch pattern (epic/* OR feature/*)
# 3. state.yaml (workflow_type field)
# 4. Return failure code for fallback to AskUserQuestion
#
# Output: JSON object with workflow information including worktree detection
# Exit codes: 0=success, 1=detection failed

set -e

# Get current branch safely
get_current_branch() {
    git branch --show-current 2>/dev/null || echo "unknown"
}

# Detect if current directory is a worktree
detect_worktree() {
    # Get the current git directory
    local git_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null || echo "")

    if [ -z "$git_dir" ]; then
        echo '{"is_worktree":false}'
        return
    fi

    # In a worktree, git_dir is .git/worktrees/<name>
    # In main worktree, git_dir is .git
    if [[ "$git_dir" == *"/worktrees/"* ]] || [[ "$git_dir" == *"\\worktrees\\"* ]]; then
        # This is a worktree
        local worktree_path
        worktree_path=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

        # Check if this is a managed worktree (under worktrees/ directory)
        if [[ "$worktree_path" == */worktrees/* ]] || [[ "$worktree_path" == *\\worktrees\\* ]]; then
            # Extract type and slug from path
            # Path format: .../worktrees/{type}/{slug}
            local path_suffix="${worktree_path##*/worktrees/}"
            [ -z "$path_suffix" ] && path_suffix="${worktree_path##*\\worktrees\\}"

            local type="${path_suffix%%/*}"
            [ -z "$type" ] && type="${path_suffix%%\\*}"

            local slug="${path_suffix##*/}"
            [ -z "$slug" ] && slug="${path_suffix##*\\}"

            echo "{\"is_worktree\":true,\"worktree_path\":\"$worktree_path\",\"worktree_type\":\"$type\",\"worktree_slug\":\"$slug\"}"
        else
            # Worktree but not managed by our system
            echo "{\"is_worktree\":true,\"worktree_path\":\"$worktree_path\",\"worktree_type\":\"unknown\",\"worktree_slug\":\"unknown\"}"
        fi
    else
        # Not a worktree (main repository)
        echo '{"is_worktree":false}'
    fi
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

# Priority 3: Check state.yaml
detect_from_state() {
    # Check epic state.yaml
    if ls epics/*/state.yaml 1>/dev/null 2>&1; then
        local state_file=$(ls epics/*/state.yaml 2>/dev/null | head -n 1)
        local workflow_type=$(grep "^workflow_type:" "$state_file" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "unknown")

        if [ "$workflow_type" = "epic" ]; then
            local epic_dir=$(dirname "$state_file")
            local epic_slug=$(basename "$epic_dir")
            echo "{\"type\":\"epic\",\"base_dir\":\"epics\",\"slug\":\"$epic_slug\",\"branch\":\"$(get_current_branch)\",\"source\":\"state\"}"
            return 0
        fi
    fi

    # Check feature state.yaml
    if ls specs/*/state.yaml 1>/dev/null 2>&1; then
        local state_file=$(ls specs/*/state.yaml 2>/dev/null | head -n 1)
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

# Merge worktree info with workflow detection result
merge_worktree_info() {
    local workflow_json="$1"
    local worktree_json="$2"

    # Parse values from both JSON objects
    local type=$(echo "$workflow_json" | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
    local base_dir=$(echo "$workflow_json" | grep -o '"base_dir":"[^"]*"' | cut -d'"' -f4)
    local slug=$(echo "$workflow_json" | grep -o '"slug":"[^"]*"' | cut -d'"' -f4)
    local branch=$(echo "$workflow_json" | grep -o '"branch":"[^"]*"' | cut -d'"' -f4)
    local source=$(echo "$workflow_json" | grep -o '"source":"[^"]*"' | cut -d'"' -f4)

    local is_worktree=$(echo "$worktree_json" | grep -o '"is_worktree":[^,}]*' | cut -d':' -f2)
    local worktree_path=$(echo "$worktree_json" | grep -o '"worktree_path":"[^"]*"' | cut -d'"' -f4)
    local worktree_type=$(echo "$worktree_json" | grep -o '"worktree_type":"[^"]*"' | cut -d'"' -f4)
    local worktree_slug=$(echo "$worktree_json" | grep -o '"worktree_slug":"[^"]*"' | cut -d'"' -f4)

    # Build merged JSON
    local merged="{\"type\":\"$type\",\"base_dir\":\"$base_dir\",\"slug\":\"$slug\",\"branch\":\"$branch\",\"source\":\"$source\",\"is_worktree\":$is_worktree"

    if [ "$is_worktree" = "true" ]; then
        merged="${merged},\"worktree_path\":\"$worktree_path\",\"worktree_type\":\"$worktree_type\",\"worktree_slug\":\"$worktree_slug\""
    fi

    merged="${merged}}"
    echo "$merged"
}

# Main detection logic
main() {
    # Detect worktree status
    local worktree_info
    worktree_info=$(detect_worktree)

    # Try each detection method in priority order
    local workflow_result=""

    if workflow_result=$(detect_from_files); then
        merge_worktree_info "$workflow_result" "$worktree_info"
        return 0
    fi

    if workflow_result=$(detect_from_branch); then
        merge_worktree_info "$workflow_result" "$worktree_info"
        return 0
    fi

    if workflow_result=$(detect_from_state); then
        merge_worktree_info "$workflow_result" "$worktree_info"
        return 0
    fi

    # All detection methods failed
    local failed_result="{\"type\":\"unknown\",\"base_dir\":\"unknown\",\"slug\":\"unknown\",\"branch\":\"$(get_current_branch)\",\"source\":\"none\",\"error\":\"Could not detect workflow type\"}"
    merge_worktree_info "$failed_result" "$worktree_info" >&2
    return 1
}

# Run main detection
main
