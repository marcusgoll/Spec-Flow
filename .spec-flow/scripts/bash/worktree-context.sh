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
# Returns: JSON with worktree details
get_current_worktree_info() {
    if ! is_in_worktree; then
        echo '{"is_worktree": false}'
        return 0
    fi

    local root_path
    root_path=$(get_root_path)
    local current_path
    current_path=$(pwd)
    local branch
    branch=$(git branch --show-current 2>/dev/null || echo "")

    # Extract worktree type and slug from path
    # Expected: worktrees/{type}/{slug}
    local worktree_type=""
    local worktree_slug=""

    if [[ "$current_path" == *"/worktrees/feature/"* ]]; then
        worktree_type="feature"
        worktree_slug=$(echo "$current_path" | sed 's|.*/worktrees/feature/||' | cut -d'/' -f1)
    elif [[ "$current_path" == *"/worktrees/epic/"* ]]; then
        worktree_type="epic"
        worktree_slug=$(echo "$current_path" | sed 's|.*/worktrees/epic/||' | cut -d'/' -f1)
    fi

    cat <<EOF
{
    "is_worktree": true,
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
  info                    Get current worktree info (JSON)
  run <path> <cmd>        Run command in worktree
  git <path> <git-args>   Run git command in worktree
  list [--json]           List active worktrees
  path <slug>             Get worktree path for slug
  merge <slug>            Merge worktree branch to main
  sync <path>             Sync state from worktree
  create <type> <slug> <branch>  Create new worktree
  cleanup [--dry-run]     Remove merged worktrees
  context <path>          Generate Task() agent context block

Examples:
  worktree-context.sh root
  worktree-context.sh run /path/to/worktree "npm test"
  worktree-context.sh merge 001-auth-system
  worktree-context.sh context /path/to/worktree
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
