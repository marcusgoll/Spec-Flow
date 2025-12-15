#!/usr/bin/env bash
# Git Worktree Manager for Spec-Flow Workflow
# Manages worktree lifecycle for parallel epic/feature development

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

show_help() {
    cat <<'EOF'
Usage: worktree-manager.sh <command> [options]

Commands:
  create <type> <slug> <branch>  Create new worktree
  list                           List all worktrees
  remove <slug>                  Remove worktree
  exists <slug>                  Check if worktree exists (exit 0 if yes)
  get-path <slug>                Get absolute path to worktree
  sync <slug>                    Rebase worktree branch onto latest main
  cleanup [--dry-run]            Remove merged/stale worktrees
  link-memory <slug>             Create symlinks to shared memory

Options:
  --json                         Output in JSON format
  --dry-run                      Show what would be done
  -h, --help                     Show this help

Examples:
  # Create worktree for epic
  worktree-manager.sh create epic 001-auth-system epic/001-auth-system

  # List all worktrees
  worktree-manager.sh list --json

  # Cleanup merged worktrees
  worktree-manager.sh cleanup --dry-run
EOF
}

# ============================================================================
# Configuration
# ============================================================================

REPO_ROOT="$(resolve_repo_root)"
WORKTREES_DIR="$REPO_ROOT/worktrees"
MEMORY_DIR="$REPO_ROOT/.spec-flow/memory"
JSON_OUT=false
DRY_RUN=false

# ============================================================================
# Helper Functions
# ============================================================================

ensure_git_repo() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        log_error "Not inside a git repository"
        exit 1
    fi
}

branch_exists() {
    git rev-parse --verify --quiet "$1" >/dev/null 2>&1
}

worktree_exists() {
    local slug="$1"
    git worktree list --porcelain | grep -q "worktree $WORKTREES_DIR/[^/]*/$slug$"
}

get_worktree_path() {
    local slug="$1"
    # Search in both epic/ and feature/ subdirectories
    for type_dir in "$WORKTREES_DIR"/*; do
        [ -d "$type_dir" ] || continue
        local candidate="$type_dir/$slug"
        if [ -d "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

is_worktree_clean() {
    local worktree_path="$1"
    cd "$worktree_path" || return 1
    git diff --quiet && git diff --cached --quiet
}

get_worktree_branch() {
    local worktree_path="$1"
    cd "$worktree_path" || return 1
    git rev-parse --abbrev-ref HEAD
}

is_branch_merged() {
    local branch="$1"
    local base_branch="${2:-main}"

    # Check if branch exists in remote
    if ! git rev-parse --verify --quiet "origin/$branch" >/dev/null 2>&1; then
        # Local-only branch, not merged
        return 1
    fi

    # Check if merged into base branch
    local merge_base
    merge_base=$(git merge-base "$base_branch" "$branch" 2>/dev/null || echo "")
    local branch_head
    branch_head=$(git rev-parse "$branch" 2>/dev/null || echo "")

    [ -n "$merge_base" ] && [ "$merge_base" = "$branch_head" ]
}

# ============================================================================
# Command: create
# ============================================================================

cmd_create() {
    if [ $# -lt 3 ]; then
        log_error "Usage: worktree-manager.sh create <type> <slug> <branch>"
        exit 1
    fi

    local type="$1"      # epic or feature
    local slug="$2"      # 001-auth-system
    local branch="$3"    # epic/001-auth-system

    ensure_git_repo

    # Validate type
    if [[ ! "$type" =~ ^(epic|feature)$ ]]; then
        log_error "Type must be 'epic' or 'feature', got: $type"
        exit 1
    fi

    # Check if worktree already exists
    if worktree_exists "$slug"; then
        local existing_path
        existing_path=$(get_worktree_path "$slug")
        if $JSON_OUT; then
            python - <<PY
import json
print(json.dumps({
    "status": "exists",
    "worktree_path": "$existing_path",
    "branch": "$(get_worktree_branch "$existing_path")",
    "message": "Worktree already exists"
}))
PY
        else
            log_info "Worktree already exists: $existing_path"
            echo "WORKTREE_PATH: $existing_path"
            echo "BRANCH: $(get_worktree_branch "$existing_path")"
        fi
        return 0
    fi

    # Create type directory if needed
    local type_dir="$WORKTREES_DIR/$type"
    ensure_directory "$type_dir"

    local worktree_path="$type_dir/$slug"

    # Fetch latest from origin to ensure we're up to date (v11.8.4)
    log_info "Fetching latest from origin..."
    git fetch origin --quiet 2>/dev/null || log_warn "Could not fetch from origin (working offline?)"

    # Determine base branch (origin/main or origin/master)
    local base_branch="origin/main"
    if ! git rev-parse --verify --quiet "$base_branch" >/dev/null 2>&1; then
        base_branch="origin/master"
        if ! git rev-parse --verify --quiet "$base_branch" >/dev/null 2>&1; then
            base_branch="HEAD"  # Fallback to current HEAD if no remote
            log_warn "No origin/main or origin/master found, using HEAD"
        fi
    fi

    # Create or checkout branch
    if branch_exists "$branch"; then
        log_info "Branch '$branch' already exists, will link to worktree"
    else
        log_info "Creating new branch: $branch (from $base_branch)"
        git branch "$branch" "$base_branch" 2>/dev/null || log_warn "Branch creation skipped (may already exist)"
    fi

    # Create worktree
    log_info "Creating worktree: $worktree_path"
    if git worktree add "$worktree_path" "$branch" 2>/dev/null; then
        log_success "Worktree created successfully"
    else
        log_error "Failed to create worktree"
        exit 1
    fi

    # Create symlinks to shared memory
    cmd_link_memory "$slug"

    if $JSON_OUT; then
        python - <<PY
import json
print(json.dumps({
    "status": "created",
    "worktree_path": "$worktree_path",
    "branch": "$branch",
    "type": "$type",
    "slug": "$slug"
}))
PY
    else
        echo "WORKTREE_PATH: $worktree_path"
        echo "BRANCH: $branch"
        echo "TYPE: $type"
        echo "SLUG: $slug"
    fi
}

# ============================================================================
# Command: list
# ============================================================================

cmd_list() {
    ensure_git_repo

    if $JSON_OUT; then
        local worktrees_json="[]"
        local first=true

        while IFS= read -r line; do
            if [[ $line =~ ^worktree\ (.+)$ ]]; then
                local path="${BASH_REMATCH[1]}"
                # Only include worktrees in our managed directory
                if [[ "$path" == "$WORKTREES_DIR"* ]]; then
                    local branch=""
                    local head=""

                    # Read next lines for branch and HEAD
                    read -r branch_line || true
                    [[ $branch_line =~ ^branch\ refs/heads/(.+)$ ]] && branch="${BASH_REMATCH[1]}"

                    read -r head_line || true
                    [[ $head_line =~ ^HEAD\ ([a-f0-9]+)$ ]] && head="${BASH_REMATCH[1]}"

                    # Extract type and slug from path
                    local relative_path="${path#$WORKTREES_DIR/}"
                    local type="${relative_path%%/*}"
                    local slug="${relative_path#*/}"

                    if $first; then
                        worktrees_json="[{\"path\": \"$path\", \"branch\": \"$branch\", \"head\": \"$head\", \"type\": \"$type\", \"slug\": \"$slug\"}"
                        first=false
                    else
                        worktrees_json="${worktrees_json}, {\"path\": \"$path\", \"branch\": \"$branch\", \"head\": \"$head\", \"type\": \"$type\", \"slug\": \"$slug\"}"
                    fi
                fi
            fi
        done < <(git worktree list --porcelain)

        if ! $first; then
            worktrees_json="${worktrees_json}]"
        fi

        echo "$worktrees_json"
    else
        echo "Managed Worktrees:"
        echo "=================="

        local found=false
        while IFS= read -r line; do
            if [[ $line =~ ^worktree\ (.+)$ ]]; then
                local path="${BASH_REMATCH[1]}"
                if [[ "$path" == "$WORKTREES_DIR"* ]]; then
                    found=true
                    local branch=""

                    read -r branch_line || true
                    [[ $branch_line =~ ^branch\ refs/heads/(.+)$ ]] && branch="${BASH_REMATCH[1]}"

                    local relative_path="${path#$WORKTREES_DIR/}"
                    echo "  • $relative_path → $branch"
                fi
            fi
        done < <(git worktree list --porcelain)

        if ! $found; then
            echo "  (none)"
        fi
    fi
}

# ============================================================================
# Command: remove
# ============================================================================

cmd_remove() {
    if [ $# -lt 1 ]; then
        log_error "Usage: worktree-manager.sh remove <slug>"
        exit 1
    fi

    local slug="$1"
    ensure_git_repo

    if ! worktree_exists "$slug"; then
        log_error "Worktree not found: $slug"
        exit 1
    fi

    local worktree_path
    worktree_path=$(get_worktree_path "$slug")

    # Check if worktree has uncommitted changes
    if ! is_worktree_clean "$worktree_path"; then
        log_warn "Worktree has uncommitted changes: $worktree_path"
        if ! $DRY_RUN; then
            log_error "Cannot remove worktree with uncommitted changes. Commit or stash first."
            exit 1
        fi
    fi

    if $DRY_RUN; then
        log_info "[DRY-RUN] Would remove worktree: $worktree_path"
    else
        log_info "Removing worktree: $worktree_path"
        git worktree remove "$worktree_path" 2>/dev/null || {
            log_warn "Worktree remove failed, forcing..."
            git worktree remove --force "$worktree_path"
        }
        log_success "Worktree removed: $slug"
    fi

    if $JSON_OUT; then
        python - <<PY
import json
print(json.dumps({
    "status": "removed" if not $DRY_RUN else "dry-run",
    "slug": "$slug",
    "path": "$worktree_path"
}))
PY
    fi
}

# ============================================================================
# Command: exists
# ============================================================================

cmd_exists() {
    if [ $# -lt 1 ]; then
        log_error "Usage: worktree-manager.sh exists <slug>"
        exit 1
    fi

    local slug="$1"
    ensure_git_repo

    if worktree_exists "$slug"; then
        exit 0
    else
        exit 1
    fi
}

# ============================================================================
# Command: get-path
# ============================================================================

cmd_get_path() {
    if [ $# -lt 1 ]; then
        log_error "Usage: worktree-manager.sh get-path <slug>"
        exit 1
    fi

    local slug="$1"
    ensure_git_repo

    if worktree_exists "$slug"; then
        get_worktree_path "$slug"
    else
        log_error "Worktree not found: $slug"
        exit 1
    fi
}

# ============================================================================
# Command: sync (v11.8.4)
# ============================================================================

cmd_sync() {
    if [ $# -lt 1 ]; then
        log_error "Usage: worktree-manager.sh sync <slug>"
        exit 1
    fi

    local slug="$1"
    ensure_git_repo

    if ! worktree_exists "$slug"; then
        log_error "Worktree not found: $slug"
        exit 1
    fi

    local worktree_path
    worktree_path=$(get_worktree_path "$slug")

    # Fetch latest from origin
    log_info "Fetching latest from origin..."
    git fetch origin --quiet 2>/dev/null || log_warn "Could not fetch from origin"

    # Determine base branch
    local base_branch="origin/main"
    if ! git rev-parse --verify --quiet "$base_branch" >/dev/null 2>&1; then
        base_branch="origin/master"
        if ! git rev-parse --verify --quiet "$base_branch" >/dev/null 2>&1; then
            log_error "No origin/main or origin/master found"
            exit 1
        fi
    fi

    # Get current branch in worktree
    local current_branch
    current_branch=$(get_worktree_branch "$worktree_path")

    # Check if worktree is clean
    if ! is_worktree_clean "$worktree_path"; then
        log_error "Worktree has uncommitted changes. Commit or stash first."
        exit 1
    fi

    # Check how far behind we are
    local behind_count
    behind_count=$(cd "$worktree_path" && git rev-list --count HEAD.."$base_branch" 2>/dev/null || echo "0")

    if [ "$behind_count" = "0" ]; then
        log_success "Branch is already up to date with $base_branch"
        if $JSON_OUT; then
            echo '{"status": "up-to-date", "behind": 0}'
        fi
        return 0
    fi

    log_info "Branch is $behind_count commits behind $base_branch"

    if $DRY_RUN; then
        log_info "[DRY-RUN] Would rebase $current_branch onto $base_branch"
        if $JSON_OUT; then
            echo "{\"status\": \"dry-run\", \"behind\": $behind_count, \"base\": \"$base_branch\"}"
        fi
        return 0
    fi

    # Perform rebase
    log_info "Rebasing $current_branch onto $base_branch..."
    cd "$worktree_path" || exit 1

    if git rebase "$base_branch" 2>/dev/null; then
        log_success "Successfully rebased onto $base_branch"
        if $JSON_OUT; then
            echo "{\"status\": \"rebased\", \"behind\": 0, \"base\": \"$base_branch\"}"
        fi
    else
        log_error "Rebase failed. Resolve conflicts in $worktree_path then run 'git rebase --continue'"
        git rebase --abort 2>/dev/null || true
        if $JSON_OUT; then
            echo "{\"status\": \"conflict\", \"behind\": $behind_count, \"base\": \"$base_branch\"}"
        fi
        exit 1
    fi
}

# ============================================================================
# Command: cleanup
# ============================================================================

cmd_cleanup() {
    ensure_git_repo

    local removed_count=0
    local skipped_count=0

    log_info "Scanning for merged/stale worktrees..."

    while IFS= read -r line; do
        if [[ $line =~ ^worktree\ (.+)$ ]]; then
            local path="${BASH_REMATCH[1]}"

            # Only process managed worktrees
            if [[ "$path" != "$WORKTREES_DIR"* ]]; then
                continue
            fi

            local branch=""
            read -r branch_line || true
            [[ $branch_line =~ ^branch\ refs/heads/(.+)$ ]] && branch="${BASH_REMATCH[1]}"

            if [ -z "$branch" ]; then
                continue
            fi

            # Check if branch is merged
            if is_branch_merged "$branch"; then
                local slug="${path##*/}"

                if $DRY_RUN; then
                    log_info "[DRY-RUN] Would remove merged worktree: $slug (branch: $branch)"
                else
                    log_info "Removing merged worktree: $slug"
                    git worktree remove "$path" 2>/dev/null || \
                        git worktree remove --force "$path"
                fi

                ((removed_count++))
            else
                ((skipped_count++))
            fi
        fi
    done < <(git worktree list --porcelain)

    if $JSON_OUT; then
        python - <<PY
import json
print(json.dumps({
    "removed": $removed_count,
    "skipped": $skipped_count,
    "dry_run": $DRY_RUN
}))
PY
    else
        if [ $removed_count -eq 0 ]; then
            log_info "No merged worktrees to clean up"
        else
            log_success "Cleanup complete: $removed_count removed, $skipped_count kept"
        fi
    fi
}

# ============================================================================
# Command: link-memory
# ============================================================================

cmd_link_memory() {
    if [ $# -lt 1 ]; then
        log_error "Usage: worktree-manager.sh link-memory <slug>"
        exit 1
    fi

    local slug="$1"
    ensure_git_repo

    if ! worktree_exists "$slug"; then
        log_error "Worktree not found: $slug"
        exit 1
    fi

    local worktree_path
    worktree_path=$(get_worktree_path "$slug")

    local worktree_memory="$worktree_path/.spec-flow/memory"

    # Create .spec-flow directory in worktree if needed
    ensure_directory "$worktree_path/.spec-flow"

    # Remove existing memory directory/link if present
    if [ -e "$worktree_memory" ] || [ -L "$worktree_memory" ]; then
        rm -rf "$worktree_memory"
    fi

    # Create relative symlink to main memory directory
    local relative_memory
    relative_memory=$(realpath --relative-to="$worktree_path/.spec-flow" "$MEMORY_DIR")

    ln -s "$relative_memory" "$worktree_memory"

    log_success "Linked memory for worktree: $slug"
}

# ============================================================================
# Main Command Router
# ============================================================================

# Parse global flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_OUT=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Route to command
if [ $# -eq 0 ]; then
    log_error "No command specified"
    show_help
    exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
    create)
        cmd_create "$@"
        ;;
    list)
        cmd_list "$@"
        ;;
    remove)
        cmd_remove "$@"
        ;;
    exists)
        cmd_exists "$@"
        ;;
    get-path)
        cmd_get_path "$@"
        ;;
    sync)
        cmd_sync "$@"
        ;;
    cleanup)
        cmd_cleanup "$@"
        ;;
    link-memory)
        cmd_link_memory "$@"
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
