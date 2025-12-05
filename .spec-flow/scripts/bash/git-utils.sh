#!/usr/bin/env bash
# git-utils.sh - Shared git utilities for Spec-Flow workflow scripts
#
# This library provides common git operations used across workflow scripts to
# eliminate code duplication and ensure consistent behavior.
#
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/git-utils.sh"
#
# Version: 1.0.0

# Prevent multiple sourcing
[[ -n "${_SPEC_FLOW_GIT_UTILS_LOADED:-}" ]] && return 0
_SPEC_FLOW_GIT_UTILS_LOADED=1

# Source shared-lib for logging if available
_GIT_UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$_GIT_UTILS_DIR/shared-lib.sh" ]]; then
    # shellcheck source=/dev/null
    source "$_GIT_UTILS_DIR/shared-lib.sh"
fi

# ============================================================================
# REPOSITORY VALIDATION
# ============================================================================

# Check if we're inside a git repository
# Usage: if is_git_repo; then ... fi
is_git_repo() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# Check if we're inside a git repository (exit with error if not)
# Usage: require_git_repo
require_git_repo() {
    if ! is_git_repo; then
        echo "Error: Not inside a git repository" >&2
        return 1
    fi
}

# Get the repository root directory
# Usage: REPO_ROOT=$(get_git_root)
get_git_root() {
    git rev-parse --show-toplevel 2>/dev/null
}

# ============================================================================
# BRANCH OPERATIONS
# ============================================================================

# Get the current branch name
# Usage: BRANCH=$(get_current_branch)
get_current_branch() {
    git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Check if a branch exists (local)
# Usage: if branch_exists "feature-branch"; then ... fi
branch_exists() {
    local branch="${1:?Branch name required}"
    git rev-parse --verify --quiet "$branch" >/dev/null 2>&1
}

# Check if a remote branch exists
# Usage: if remote_branch_exists "origin/main"; then ... fi
remote_branch_exists() {
    local remote_branch="${1:?Remote branch required}"
    git ls-remote --heads origin "${remote_branch#origin/}" 2>/dev/null | grep -q .
}

# Get the default branch name (main or master)
# Usage: DEFAULT_BRANCH=$(get_default_branch)
get_default_branch() {
    # Try to get from remote HEAD
    local default
    default=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

    if [[ -n "$default" ]]; then
        echo "$default"
        return 0
    fi

    # Fallback: check if main exists, then master
    if branch_exists "main" || remote_branch_exists "origin/main"; then
        echo "main"
    elif branch_exists "master" || remote_branch_exists "origin/master"; then
        echo "master"
    else
        echo "main"  # Default assumption
    fi
}

# Create and checkout a new branch (or checkout if exists)
# Usage: checkout_branch "feature-branch" [--create]
checkout_branch() {
    local branch="${1:?Branch name required}"
    local create="${2:-}"

    if branch_exists "$branch"; then
        git checkout "$branch" 2>/dev/null
    elif [[ "$create" == "--create" ]]; then
        git checkout -b "$branch" 2>/dev/null
    else
        echo "Error: Branch '$branch' does not exist" >&2
        return 1
    fi
}

# Get the merge base between current branch and target
# Usage: BASE=$(get_merge_base "main")
get_merge_base() {
    local target="${1:-$(get_default_branch)}"
    git merge-base HEAD "$target" 2>/dev/null
}

# ============================================================================
# WORKING TREE STATUS
# ============================================================================

# Check if working tree is clean (no uncommitted changes)
# Usage: if is_working_tree_clean; then ... fi
is_working_tree_clean() {
    [[ -z "$(git status --porcelain 2>/dev/null)" ]]
}

# Check if there are staged changes
# Usage: if has_staged_changes; then ... fi
has_staged_changes() {
    ! git diff --cached --quiet 2>/dev/null
}

# Check if there are unstaged changes
# Usage: if has_unstaged_changes; then ... fi
has_unstaged_changes() {
    ! git diff --quiet 2>/dev/null
}

# Check if there are untracked files
# Usage: if has_untracked_files; then ... fi
has_untracked_files() {
    [[ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]]
}

# Ensure working tree is clean (exit with error if not)
# Usage: require_clean_working_tree
require_clean_working_tree() {
    if ! is_working_tree_clean; then
        echo "Error: Working tree has uncommitted changes" >&2
        echo "Hint: Commit or stash your changes first" >&2
        git status --short >&2
        return 1
    fi
}

# Get list of changed files compared to a base
# Usage: CHANGED=$(get_changed_files "main")
get_changed_files() {
    local base="${1:-$(get_default_branch)}"
    git diff --name-only "$base"... 2>/dev/null
}

# ============================================================================
# COMMIT OPERATIONS
# ============================================================================

# Stage files for commit
# Usage: stage_files "file1.txt" "file2.txt"
# Usage: stage_files --all
stage_files() {
    if [[ "$1" == "--all" ]]; then
        git add -A 2>/dev/null
    else
        git add "$@" 2>/dev/null
    fi
}

# Create a commit with conventional commit message
# Usage: create_commit "feat" "add new feature" ["Optional body"]
create_commit() {
    local type="${1:?Commit type required (feat, fix, docs, etc.)}"
    local message="${2:?Commit message required}"
    local body="${3:-}"

    local full_message="$type: $message"

    if [[ -n "$body" ]]; then
        full_message="$full_message

$body"
    fi

    git commit -m "$full_message" 2>/dev/null
}

# Get the last commit hash (short)
# Usage: HASH=$(get_last_commit_hash)
get_last_commit_hash() {
    git rev-parse --short HEAD 2>/dev/null
}

# Get the last commit message
# Usage: MSG=$(get_last_commit_message)
get_last_commit_message() {
    git log -1 --format=%s 2>/dev/null
}

# Get commit author info
# Usage: AUTHOR=$(get_commit_author)
get_commit_author() {
    local commit="${1:-HEAD}"
    git log -1 --format='%an <%ae>' "$commit" 2>/dev/null
}

# Get commit timestamp
# Usage: TIMESTAMP=$(get_commit_timestamp)
get_commit_timestamp() {
    local commit="${1:-HEAD}"
    local format="${2:-%ci}"  # Default: ISO 8601 format
    git log -1 --format="$format" "$commit" 2>/dev/null
}

# ============================================================================
# REMOTE OPERATIONS
# ============================================================================

# Check if a remote exists
# Usage: if has_remote "origin"; then ... fi
has_remote() {
    local remote="${1:-origin}"
    git remote -v 2>/dev/null | grep -q "$remote"
}

# Get the remote URL
# Usage: URL=$(get_remote_url "origin")
get_remote_url() {
    local remote="${1:-origin}"
    git remote get-url "$remote" 2>/dev/null
}

# Push current branch to remote
# Usage: push_branch [--set-upstream]
push_branch() {
    local branch
    branch=$(get_current_branch)

    if [[ "$1" == "--set-upstream" ]] || [[ "$1" == "-u" ]]; then
        git push -u origin "$branch" 2>/dev/null
    else
        git push origin "$branch" 2>/dev/null
    fi
}

# Check if current branch is ahead of remote
# Usage: if is_ahead_of_remote; then ... fi
is_ahead_of_remote() {
    local ahead
    ahead=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo "0")
    [[ "$ahead" -gt 0 ]]
}

# Check if current branch is behind remote
# Usage: if is_behind_remote; then ... fi
is_behind_remote() {
    local behind
    behind=$(git rev-list --count "HEAD..@{u}" 2>/dev/null || echo "0")
    [[ "$behind" -gt 0 ]]
}

# ============================================================================
# TAG OPERATIONS
# ============================================================================

# Get the latest version tag
# Usage: VERSION=$(get_latest_tag)
get_latest_tag() {
    git tag -l "v*" --sort=-creatordate 2>/dev/null | head -1
}

# List all version tags (sorted)
# Usage: TAGS=$(list_version_tags)
list_version_tags() {
    git tag -l "v*" --sort=-version:refname 2>/dev/null
}

# Check if a tag exists
# Usage: if tag_exists "v1.0.0"; then ... fi
tag_exists() {
    local tag="${1:?Tag name required}"
    git rev-parse --verify --quiet "refs/tags/$tag" >/dev/null 2>&1
}

# Create an annotated tag
# Usage: create_tag "v1.0.0" "Release version 1.0.0"
create_tag() {
    local tag="${1:?Tag name required}"
    local message="${2:-$tag}"

    if tag_exists "$tag"; then
        echo "Error: Tag '$tag' already exists" >&2
        return 1
    fi

    git tag -a "$tag" -m "$message" 2>/dev/null
}

# Delete a tag (local only)
# Usage: delete_tag "v1.0.0"
delete_tag() {
    local tag="${1:?Tag name required}"
    git tag -d "$tag" 2>/dev/null
}

# Push tags to remote
# Usage: push_tags
push_tags() {
    git push origin --tags 2>/dev/null
}

# ============================================================================
# LOG & HISTORY
# ============================================================================

# Get commit log with format
# Usage: COMMITS=$(get_commit_log 10 "%h %s")
get_commit_log() {
    local count="${1:-10}"
    local format="${2:-%h %s}"
    git log -n "$count" --format="$format" 2>/dev/null
}

# Get commits since a tag or commit
# Usage: COMMITS=$(get_commits_since "v1.0.0")
get_commits_since() {
    local since="${1:?Reference required}"
    git log --oneline "$since"..HEAD 2>/dev/null
}

# Count commits since a reference
# Usage: COUNT=$(count_commits_since "v1.0.0")
count_commits_since() {
    local since="${1:?Reference required}"
    git rev-list --count "$since"..HEAD 2>/dev/null
}

# ============================================================================
# DIFF OPERATIONS
# ============================================================================

# Get diff statistics
# Usage: STATS=$(get_diff_stats "main")
get_diff_stats() {
    local base="${1:-$(get_default_branch)}"
    git diff --stat "$base"... 2>/dev/null
}

# Get added/removed line counts
# Usage: read ADDED REMOVED < <(get_diff_line_counts "main")
get_diff_line_counts() {
    local base="${1:-$(get_default_branch)}"
    git diff --numstat "$base"... 2>/dev/null | awk '{add+=$1; del+=$2} END {print add, del}'
}

# ============================================================================
# WORKTREE OPERATIONS
# ============================================================================

# Check if worktrees are supported
# Usage: if supports_worktrees; then ... fi
supports_worktrees() {
    git worktree list >/dev/null 2>&1
}

# List worktrees
# Usage: list_worktrees
list_worktrees() {
    git worktree list 2>/dev/null
}

# Check if a worktree exists for a path
# Usage: if worktree_exists "/path/to/worktree"; then ... fi
worktree_exists() {
    local path="${1:?Path required}"
    git worktree list --porcelain 2>/dev/null | grep -q "worktree $path"
}

# Add a new worktree
# Usage: add_worktree "/path/to/worktree" "branch-name"
add_worktree() {
    local path="${1:?Path required}"
    local branch="${2:?Branch required}"

    if worktree_exists "$path"; then
        echo "Error: Worktree already exists at '$path'" >&2
        return 1
    fi

    git worktree add "$path" "$branch" 2>/dev/null
}

# Remove a worktree
# Usage: remove_worktree "/path/to/worktree"
remove_worktree() {
    local path="${1:?Path required}"
    git worktree remove "$path" 2>/dev/null
}

# ============================================================================
# EXPORTS
# ============================================================================

# Export all functions for use in subshells
export -f is_git_repo require_git_repo get_git_root
export -f get_current_branch branch_exists remote_branch_exists get_default_branch
export -f checkout_branch get_merge_base
export -f is_working_tree_clean has_staged_changes has_unstaged_changes has_untracked_files
export -f require_clean_working_tree get_changed_files
export -f stage_files create_commit get_last_commit_hash get_last_commit_message
export -f get_commit_author get_commit_timestamp
export -f has_remote get_remote_url push_branch is_ahead_of_remote is_behind_remote
export -f get_latest_tag list_version_tags tag_exists create_tag delete_tag push_tags
export -f get_commit_log get_commits_since count_commits_since
export -f get_diff_stats get_diff_line_counts
export -f supports_worktrees list_worktrees worktree_exists add_worktree remove_worktree
