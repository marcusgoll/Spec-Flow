#!/usr/bin/env bash
# Worktree Context Utilities
# Root orchestration utilities for worktree-based development
# Used by workflow commands to operate on worktrees without changing cwd

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh" 2>/dev/null || true

# Color codes (fallback if common.sh not available)
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[1;33m}"
BLUE="${BLUE:-\033[0;34m}"
NC="${NC:-\033[0m}"

# Logging functions (fallback if common.sh not available)
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# =============================================================================
# CORE FUNCTIONS
# =============================================================================

# Detect if running inside a studio worktree (worktrees/studio/agent-N/)
# Returns: Agent ID (e.g., "agent-1") or empty string if not in studio
detect_studio_context() {
    local current_path
    current_path=$(pwd)

    # Check for studio worktree pattern: worktrees/studio/agent-N
    if [[ "$current_path" == *"/worktrees/studio/"* ]]; then
        # Extract agent ID from path
        local agent_id
        agent_id=$(echo "$current_path" | sed 's|.*/worktrees/studio/||' | cut -d'/' -f1)

        if [[ "$agent_id" =~ ^agent-[0-9]+$ ]]; then
            echo "$agent_id"
            return 0
        fi
    fi

    # Also check git worktree info for studio branches
    local git_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null || echo "")

    if [[ -n "$git_dir" ]] && [[ "$git_dir" == *"/worktrees/"* ]]; then
        # Extract worktree name from git-dir path
        local worktree_name
        worktree_name=$(basename "$(dirname "$git_dir")" 2>/dev/null || echo "")

        if [[ "$worktree_name" =~ ^agent-[0-9]+$ ]]; then
            echo "$worktree_name"
            return 0
        fi
    fi

    echo ""
    return 1
}

# Get namespaced branch name for studio context
# Usage: get_namespaced_branch "feature" "001-auth"
# Returns: "studio/agent-1/feature/001-auth" if in studio, else "feature/001-auth"
get_namespaced_branch() {
    local workflow_type="$1"
    local slug="$2"
    local studio_agent

    studio_agent=$(detect_studio_context)

    if [[ -n "$studio_agent" ]]; then
        # In studio context: namespace with agent ID
        echo "studio/$studio_agent/$workflow_type/$slug"
    else
        # Normal context: standard branch naming
        echo "$workflow_type/$slug"
    fi
}

# Check if current context is studio mode
# Returns: 0 if in studio, 1 if not
is_studio_mode() {
    local studio_agent
    studio_agent=$(detect_studio_context)
    [[ -n "$studio_agent" ]]
}

# =============================================================================
# WORKTREE SAFETY FUNCTIONS (v11.8)
# =============================================================================

# Find all active worktrees with in-progress features/epics
# Returns: JSON array of active worktrees with their feature info
find_active_worktrees() {
    local root_path
    root_path=$(get_root_path 2>/dev/null || pwd)

    local active_worktrees="[]"

    # Check feature worktrees
    if [[ -d "$root_path/worktrees/feature" ]]; then
        for wt_dir in "$root_path/worktrees/feature/"*/; do
            if [[ -d "$wt_dir" ]]; then
                local slug
                slug=$(basename "$wt_dir")
                local state_file="$wt_dir/specs/$slug/state.yaml"

                if [[ -f "$state_file" ]]; then
                    local status
                    status=$(yq eval '.status // "unknown"' "$state_file" 2>/dev/null || echo "unknown")
                    if [[ "$status" == "in_progress" ]]; then
                        local phase
                        phase=$(yq eval '.phase // "unknown"' "$state_file" 2>/dev/null || echo "unknown")
                        active_worktrees=$(echo "$active_worktrees" | jq --arg path "$wt_dir" --arg slug "$slug" --arg type "feature" --arg phase "$phase" '. + [{"path": $path, "slug": $slug, "type": $type, "phase": $phase}]')
                    fi
                fi
            fi
        done
    fi

    # Check epic worktrees
    if [[ -d "$root_path/worktrees/epic" ]]; then
        for wt_dir in "$root_path/worktrees/epic/"*/; do
            if [[ -d "$wt_dir" ]]; then
                local slug
                slug=$(basename "$wt_dir")
                local state_file="$wt_dir/epics/$slug/state.yaml"

                if [[ -f "$state_file" ]]; then
                    local status
                    status=$(yq eval '.status // "unknown"' "$state_file" 2>/dev/null || echo "unknown")
                    if [[ "$status" == "in_progress" ]]; then
                        local phase
                        phase=$(yq eval '.phase // "unknown"' "$state_file" 2>/dev/null || echo "unknown")
                        active_worktrees=$(echo "$active_worktrees" | jq --arg path "$wt_dir" --arg slug "$slug" --arg type "epic" --arg phase "$phase" '. + [{"path": $path, "slug": $slug, "type": $type, "phase": $phase}]')
                    fi
                fi
            fi
        done
    fi

    echo "$active_worktrees"
}

# Check if we're in root and should be blocked from making changes
# Returns: JSON with safety status and recommended actions
check_root_safety() {
    local root_path
    root_path=$(get_root_path 2>/dev/null || pwd)
    local current_path
    current_path=$(pwd)

    # Load preferences
    local enforce_isolation
    enforce_isolation=$(bash "$root_path/.spec-flow/scripts/utils/load-preferences.sh" --key "worktrees.enforce_isolation" --default "true" 2>/dev/null || echo "true")
    local root_protection
    root_protection=$(bash "$root_path/.spec-flow/scripts/utils/load-preferences.sh" --key "worktrees.root_protection" --default "strict" 2>/dev/null || echo "strict")

    # Check if we're in a worktree
    if is_in_worktree; then
        cat <<EOF
{
    "safe": true,
    "in_worktree": true,
    "message": "Operating in worktree - safe to make changes",
    "action": "proceed"
}
EOF
        return 0
    fi

    # We're in root - check for active worktrees
    local active_worktrees
    active_worktrees=$(find_active_worktrees)
    local active_count
    active_count=$(echo "$active_worktrees" | jq 'length')

    if [[ "$active_count" -eq 0 ]]; then
        cat <<EOF
{
    "safe": true,
    "in_worktree": false,
    "message": "No active worktrees - safe to start new work",
    "action": "proceed",
    "active_worktrees": []
}
EOF
        return 0
    fi

    # There are active worktrees - apply protection level
    case "$root_protection" in
        strict)
            cat <<EOF
{
    "safe": false,
    "in_worktree": false,
    "message": "Active worktrees detected - changes blocked from root",
    "action": "switch_to_worktree",
    "protection_level": "strict",
    "active_worktrees": $active_worktrees
}
EOF
            return 1
            ;;
        prompt)
            cat <<EOF
{
    "safe": false,
    "in_worktree": false,
    "message": "Active worktrees detected - user should choose where to work",
    "action": "prompt_user",
    "protection_level": "prompt",
    "active_worktrees": $active_worktrees
}
EOF
            return 1
            ;;
        none)
            cat <<EOF
{
    "safe": true,
    "in_worktree": false,
    "message": "Root protection disabled - proceeding with caution",
    "action": "proceed_with_warning",
    "protection_level": "none",
    "active_worktrees": $active_worktrees
}
EOF
            return 0
            ;;
    esac
}

# Get worktree path for a specific feature or epic slug
# Usage: get_worktree_for_workflow "feature" "001-auth"
# Returns: Worktree path or empty string
get_worktree_for_workflow() {
    local workflow_type="$1"
    local slug="$2"
    local root_path
    root_path=$(get_root_path 2>/dev/null || pwd)

    local worktree_path="$root_path/worktrees/$workflow_type/$slug"

    if [[ -d "$worktree_path" ]]; then
        echo "$worktree_path"
    else
        echo ""
    fi
}

# Generate switch instructions for user
# Usage: generate_switch_instructions "feature" "001-auth" "/path/to/worktree"
generate_switch_instructions() {
    local workflow_type="$1"
    local slug="$2"
    local worktree_path="$3"

    cat <<EOF

════════════════════════════════════════════════════════════════════════════════
⚠️  WORKTREE ISOLATION - Please switch to the correct workspace
════════════════════════════════════════════════════════════════════════════════

Active $workflow_type: $slug
Worktree path: $worktree_path

To continue working on this $workflow_type, run:

    cd "$worktree_path" && claude

Then run: /$workflow_type continue

════════════════════════════════════════════════════════════════════════════════

EOF
}

# Get the root repository path (main worktree, not a child worktree)
# Returns: Absolute path to the main git repository
get_root_path() {
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null || echo "")

    if [[ -z "$git_common_dir" ]]; then
        log_error "Not in a git repository"
        return 1
    fi

    # If we're in main repo, --git-common-dir returns .git
    # If we're in worktree, it returns path to main repo's .git
    if [[ "$git_common_dir" == ".git" ]]; then
        # We're in main repo
        pwd
    else
        # We're in a worktree, extract main repo path
        # git_common_dir is like /path/to/main/repo/.git
        dirname "$git_common_dir"
    fi
}

# Check if current working directory is inside a worktree (not main repo)
# Returns: 0 if in worktree, 1 if in main repo
is_in_worktree() {
    local git_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null || echo "")

    if [[ -z "$git_dir" ]]; then
        return 1  # Not in git repo at all
    fi

    # If git-dir contains "/worktrees/", we're in a worktree
    [[ "$git_dir" == *"/worktrees/"* ]]
}

# Get current worktree info (if in a worktree)
# Returns: JSON with worktree details including studio context
get_current_worktree_info() {
    if ! is_in_worktree; then
        echo '{"is_worktree": false, "is_studio": false}'
        return 0
    fi

    local root_path
    root_path=$(get_root_path)
    local current_path
    current_path=$(pwd)
    local branch
    branch=$(git branch --show-current 2>/dev/null || echo "")

    # Extract worktree type and slug from path
    # Expected: worktrees/{type}/{slug} or worktrees/studio/agent-N
    local worktree_type=""
    local worktree_slug=""
    local studio_agent=""
    local is_studio="false"

    # Check for studio worktree first
    if [[ "$current_path" == *"/worktrees/studio/"* ]]; then
        is_studio="true"
        worktree_type="studio"
        studio_agent=$(echo "$current_path" | sed 's|.*/worktrees/studio/||' | cut -d'/' -f1)
        worktree_slug="$studio_agent"
    elif [[ "$current_path" == *"/worktrees/feature/"* ]]; then
        worktree_type="feature"
        worktree_slug=$(echo "$current_path" | sed 's|.*/worktrees/feature/||' | cut -d'/' -f1)
    elif [[ "$current_path" == *"/worktrees/epic/"* ]]; then
        worktree_type="epic"
        worktree_slug=$(echo "$current_path" | sed 's|.*/worktrees/epic/||' | cut -d'/' -f1)
    fi

    cat <<EOF
{
    "is_worktree": true,
    "is_studio": $is_studio,
    "studio_agent": "$studio_agent",
    "worktree_path": "$current_path",
    "root_path": "$root_path",
    "branch": "$branch",
    "worktree_type": "$worktree_type",
    "worktree_slug": "$worktree_slug"
}
EOF
}

# Run a command in a specific worktree without changing cwd
# Usage: run_in_worktree "/path/to/worktree" "command to run"
# Returns: Exit code of the command
run_in_worktree() {
    local worktree_path="$1"
    shift
    local cmd="$*"

    if [[ ! -d "$worktree_path" ]]; then
        log_error "Worktree path does not exist: $worktree_path"
        return 1
    fi

    # Verify it's a valid git worktree
    if [[ ! -f "$worktree_path/.git" ]] && [[ ! -d "$worktree_path/.git" ]]; then
        log_error "Not a valid git worktree: $worktree_path"
        return 1
    fi

    # Run command in subshell with worktree as cwd
    (cd "$worktree_path" && eval "$cmd")
}

# Run git command in a specific worktree using -C flag (no subshell)
# Usage: git_in_worktree "/path/to/worktree" "status" "--short"
# Returns: Exit code of git command
git_in_worktree() {
    local worktree_path="$1"
    shift

    if [[ ! -d "$worktree_path" ]]; then
        log_error "Worktree path does not exist: $worktree_path"
        return 1
    fi

    git -C "$worktree_path" "$@"
}

# Get list of all active worktrees managed by worktree-manager.sh
# Usage: get_active_worktrees [--json]
# Returns: List of worktrees or JSON array
get_active_worktrees() {
    local json_output="${1:-}"
    local root_path
    root_path=$(get_root_path)

    if [[ "$json_output" == "--json" ]]; then
        bash "$root_path/.spec-flow/scripts/bash/worktree-manager.sh" list --json 2>/dev/null || echo "[]"
    else
        bash "$root_path/.spec-flow/scripts/bash/worktree-manager.sh" list 2>/dev/null || echo "No worktrees found"
    fi
}

# Get worktree path for a given slug
# Usage: get_worktree_path_for_slug "001-auth-system"
# Returns: Absolute path to worktree or empty string
get_worktree_path_for_slug() {
    local slug="$1"
    local root_path
    root_path=$(get_root_path)

    bash "$root_path/.spec-flow/scripts/bash/worktree-manager.sh" get-path "$slug" 2>/dev/null || echo ""
}

# =============================================================================
# MERGE AND SYNC FUNCTIONS
# =============================================================================

# Merge worktree branch back to main/master
# Usage: merge_worktree_to_main "slug" [--no-delete]
# Returns: 0 on success, 1 on failure
merge_worktree_to_main() {
    local slug="$1"
    local no_delete="${2:-}"

    local worktree_path
    worktree_path=$(get_worktree_path_for_slug "$slug")

    if [[ -z "$worktree_path" ]]; then
        log_error "Worktree not found for slug: $slug"
        return 1
    fi

    # Get branch name from worktree
    local branch
    branch=$(git_in_worktree "$worktree_path" branch --show-current)

    if [[ -z "$branch" ]]; then
        log_error "Could not determine branch for worktree: $slug"
        return 1
    fi

    local root_path
    root_path=$(get_root_path)
    local main_branch
    main_branch=$(git -C "$root_path" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

    log_info "Merging $branch into $main_branch..."

    # Ensure worktree has no uncommitted changes
    if ! git_in_worktree "$worktree_path" diff --quiet 2>/dev/null; then
        log_error "Worktree has uncommitted changes. Commit or stash before merging."
        return 1
    fi

    # Fetch latest from worktree branch
    (
        cd "$root_path"

        # Fetch the worktree's branch into root
        git fetch . "$worktree_path:$branch" 2>/dev/null || true

        # Checkout main branch
        git checkout "$main_branch"

        # Merge with no-ff to preserve history
        git merge --no-ff "$branch" -m "Merge $branch from worktree

Worktree: $worktree_path
Slug: $slug

🤖 Generated with [Claude Code](https://claude.com/claude-code)
Co-Authored-By: Claude <noreply@anthropic.com>"
    )

    local merge_result=$?

    if [[ $merge_result -eq 0 ]]; then
        log_success "Successfully merged $branch into $main_branch"

        # Optionally remove worktree
        if [[ "$no_delete" != "--no-delete" ]]; then
            log_info "Removing worktree: $slug"
            bash "$root_path/.spec-flow/scripts/bash/worktree-manager.sh" remove "$slug" --force 2>/dev/null || true
        fi

        return 0
    else
        log_error "Merge failed. Resolve conflicts manually."
        return 1
    fi
}

# Sync state files from worktree back to root (for observation)
# Usage: sync_worktree_state "/path/to/worktree"
# Returns: 0 on success
sync_worktree_state() {
    local worktree_path="$1"
    local root_path
    root_path=$(get_root_path)

    if [[ ! -d "$worktree_path" ]]; then
        log_error "Worktree path does not exist: $worktree_path"
        return 1
    fi

    # Find state.yaml in worktree
    local state_file=""

    # Check specs/ directory
    if [[ -d "$worktree_path/specs" ]]; then
        state_file=$(find "$worktree_path/specs" -maxdepth 2 -name "state.yaml" -type f 2>/dev/null | head -1)
    fi

    # Check epics/ directory if not found
    if [[ -z "$state_file" ]] && [[ -d "$worktree_path/epics" ]]; then
        state_file=$(find "$worktree_path/epics" -maxdepth 2 -name "state.yaml" -type f 2>/dev/null | head -1)
    fi

    if [[ -z "$state_file" ]]; then
        log_warning "No state.yaml found in worktree: $worktree_path"
        return 0
    fi

    # Extract relative path and copy to root
    local relative_path="${state_file#$worktree_path/}"
    local dest_path="$root_path/$relative_path"
    local dest_dir
    dest_dir=$(dirname "$dest_path")

    mkdir -p "$dest_dir"
    cp "$state_file" "$dest_path"

    log_success "Synced state from worktree: $relative_path"
    return 0
}

# =============================================================================
# WORKTREE LIFECYCLE HELPERS
# =============================================================================

# Create worktree for feature or epic
# Usage: create_worktree_for "feature" "001-auth-system" "feature/001-auth-system"
# Returns: Worktree path on success, empty on failure
create_worktree_for() {
    local type="$1"
    local slug="$2"
    local branch="$3"

    local root_path
    root_path=$(get_root_path)

    local result
    result=$(bash "$root_path/.spec-flow/scripts/bash/worktree-manager.sh" create "$type" "$slug" "$branch" 2>&1)

    if [[ $? -eq 0 ]]; then
        # Extract path from result
        echo "$result" | grep "WORKTREE_PATH:" | cut -d' ' -f2
    else
        log_error "Failed to create worktree: $result"
        echo ""
    fi
}

# Cleanup merged worktrees
# Usage: cleanup_merged_worktrees [--dry-run]
# Returns: Number of worktrees cleaned up
cleanup_merged_worktrees() {
    local dry_run="${1:-}"
    local root_path
    root_path=$(get_root_path)

    if [[ "$dry_run" == "--dry-run" ]]; then
        bash "$root_path/.spec-flow/scripts/bash/worktree-manager.sh" cleanup --dry-run
    else
        bash "$root_path/.spec-flow/scripts/bash/worktree-manager.sh" cleanup
    fi
}

# =============================================================================
# TASK AGENT HELPERS
# =============================================================================

# Generate worktree context block for Task() agent prompts
# Usage: generate_worktree_context "/path/to/worktree"
# Returns: Markdown block to include in agent prompt
generate_worktree_context() {
    local worktree_path="$1"

    if [[ -z "$worktree_path" ]]; then
        # No worktree mode
        echo ""
        return 0
    fi

    cat <<EOF
**WORKTREE CONTEXT**
Path: $worktree_path

CRITICAL: Execute this as your FIRST action:
\`\`\`bash
cd "$worktree_path"
\`\`\`

All subsequent paths are relative to this worktree.
Git commits stay local to this worktree's branch.
Do NOT merge or push - the orchestrator handles that.

EOF
}

# Extract worktree-relative path from a main-repo-relative path
# Fixes path duplication bug where worktree path gets nested inside itself
# Usage: extract_worktree_relative_path "specs/001-auth" "/path/to/worktree"
# Usage: extract_worktree_relative_path "epics/004-web-app/sprints/S01" "/path/to/worktree"
# Returns: The path relative to worktree root (same as input for valid paths)
extract_worktree_relative_path() {
    local main_repo_path="$1"
    local worktree_path="${2:-}"

    # If the path contains "worktrees/" prefix, strip it and extract relative part
    # This handles the duplication bug: worktrees/epic/004-190/epics/004-190
    if [[ "$main_repo_path" == *"/worktrees/"* ]]; then
        # Find where specs/ or epics/ starts after worktrees/
        local relative_path
        if [[ "$main_repo_path" == *"/specs/"* ]]; then
            relative_path="specs/${main_repo_path##*/specs/}"
        elif [[ "$main_repo_path" == *"/epics/"* ]]; then
            relative_path="epics/${main_repo_path##*/epics/}"
        else
            # Extract just the slug from the path
            relative_path=$(basename "$main_repo_path")
        fi
        echo "$relative_path"
        return 0
    fi

    # If path starts with specs/ or epics/, it's already correct
    if [[ "$main_repo_path" == specs/* ]] || [[ "$main_repo_path" == epics/* ]]; then
        echo "$main_repo_path"
        return 0
    fi

    # For bare slugs, try to detect the correct prefix
    local slug="$main_repo_path"
    if [[ -n "$worktree_path" ]]; then
        if [[ -d "$worktree_path/specs/$slug" ]]; then
            echo "specs/$slug"
            return 0
        elif [[ -d "$worktree_path/epics/$slug" ]]; then
            echo "epics/$slug"
            return 0
        fi
    fi

    # Default: return as-is
    echo "$main_repo_path"
}

# Get the feature/epic slug from any path format
# Usage: extract_slug_from_path "specs/001-auth/domain-memory.yaml"
# Usage: extract_slug_from_path "worktrees/feature/001-auth/specs/001-auth"
# Returns: The slug (e.g., "001-auth")
extract_slug_from_path() {
    local path="$1"

    # Handle various path formats
    # Format 1: specs/001-auth/... or epics/001-auth/...
    if [[ "$path" =~ specs/([^/]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    elif [[ "$path" =~ epics/([^/]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi

    # Format 2: worktrees/type/slug/...
    if [[ "$path" =~ worktrees/[^/]+/([^/]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi

    # Fallback: return basename
    basename "$path"
}

# =============================================================================
# CLI INTERFACE
# =============================================================================

show_help() {
    cat <<EOF
Worktree Context Utilities

Usage: worktree-context.sh <command> [args...]

Commands:
  root                    Get root repository path
  in-worktree             Check if in worktree (exit 0 = yes, 1 = no)
  info                    Get current worktree info (JSON with studio context)
  run <path> <cmd>        Run command in worktree
  git <path> <git-args>   Run git command in worktree
  list [--json]           List active worktrees
  path <slug>             Get worktree path for slug
  merge <slug>            Merge worktree branch to main
  sync <path>             Sync state from worktree
  create <type> <slug> <branch>  Create new worktree
  cleanup [--dry-run]     Remove merged worktrees
  context <path>          Generate Task() agent context block
  relative-path <path> [worktree]  Extract worktree-relative path (fixes duplication)
  extract-slug <path>     Extract feature/epic slug from any path format

Studio Context Commands (v11.8):
  studio-detect           Detect studio context, returns agent ID or empty
  studio-mode             Check if in studio mode (exit 0 = yes, 1 = no)
  studio-branch <type> <slug>  Get namespaced branch for studio context

Worktree Safety Commands (v11.8):
  find-active             Find all worktrees with in-progress features/epics (JSON)
  check-safety            Check if safe to make changes from current location (JSON)
  get-worktree <type> <slug>   Get worktree path for a feature/epic
  switch-instructions <type> <slug> <path>  Generate instructions for switching

Examples:
  worktree-context.sh root
  worktree-context.sh run /path/to/worktree "npm test"
  worktree-context.sh merge 001-auth-system
  worktree-context.sh context /path/to/worktree
  worktree-context.sh relative-path "worktrees/epic/004-190/epics/004-190"
  worktree-context.sh extract-slug "specs/001-auth/domain-memory.yaml"

Studio Examples:
  worktree-context.sh studio-detect
  # Returns: agent-1 (if in studio worktree) or empty

  worktree-context.sh studio-branch feature 001-auth
  # Returns: studio/agent-1/feature/001-auth (if in studio)
  # Returns: feature/001-auth (if not in studio)
EOF
}

# Main CLI handler
main() {
    local cmd="${1:-help}"
    shift || true

    case "$cmd" in
        root)
            get_root_path
            ;;
        in-worktree)
            is_in_worktree
            ;;
        info)
            get_current_worktree_info
            ;;
        run)
            run_in_worktree "$@"
            ;;
        git)
            git_in_worktree "$@"
            ;;
        list)
            get_active_worktrees "$@"
            ;;
        path)
            get_worktree_path_for_slug "$@"
            ;;
        merge)
            merge_worktree_to_main "$@"
            ;;
        sync)
            sync_worktree_state "$@"
            ;;
        create)
            create_worktree_for "$@"
            ;;
        cleanup)
            cleanup_merged_worktrees "$@"
            ;;
        context)
            generate_worktree_context "$@"
            ;;
        relative-path)
            extract_worktree_relative_path "$@"
            ;;
        extract-slug)
            extract_slug_from_path "$@"
            ;;
        studio-detect)
            detect_studio_context
            ;;
        studio-mode)
            is_studio_mode
            ;;
        studio-branch)
            get_namespaced_branch "$@"
            ;;
        find-active)
            find_active_worktrees
            ;;
        check-safety)
            check_root_safety
            ;;
        get-worktree)
            get_worktree_for_workflow "$@"
            ;;
        switch-instructions)
            generate_switch_instructions "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $cmd"
            show_help
            exit 1
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
