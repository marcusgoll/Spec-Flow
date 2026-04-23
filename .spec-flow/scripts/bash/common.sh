#!/usr/bin/env bash
# Shared helpers for Spec-Flow shell tooling.
# shellcheck disable=SC2034

set -euo pipefail

log_info() {
    printf '[spec-flow] %s\n' "$1" >&2
}

log_warn() {
    printf '[spec-flow][warn] %s\n' "$1" >&2
}

log_error() {
    printf '[spec-flow][error] %s\n' "$1" >&2
}

script_dir() {
    local src="${BASH_SOURCE[0]}"
    while [ -L "$src" ]; do
        local dir
        dir="$(cd -P "$(dirname "$src")" && pwd)"
        src="$(readlink "$src")"
        [[ $src != /* ]] && src="$dir/$src"
    done
    cd -P "$(dirname "$src")" && pwd
}

resolve_repo_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
        return
    fi
    local dir
    dir="$(script_dir)"
    local candidate
    candidate="$(cd "$dir/../.." >/dev/null 2>&1 && pwd)"
    if [ -d "$candidate/specs" ] || [ -d "$candidate/.git" ]; then
        printf "%s\n" "$candidate"
        return
    fi
    candidate="$(cd "$candidate/.." >/dev/null 2>&1 && pwd)"
    printf "%s\n" "$candidate"
}

resolve_python_cmd() {
    if command -v python3 >/dev/null 2>&1; then
        printf "%s\n" "python3"
        return 0
    fi
    if command -v python >/dev/null 2>&1; then
        printf "%s\n" "python"
        return 0
    fi
    log_error "Python interpreter not found. Install python3 or python."
    return 1
}

feature_paths_env() {
    local repo_root current_branch has_git=false branch_name feature_dir specs_dir max_num next_num entry num

    repo_root="$(resolve_repo_root)"
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        has_git=true
    fi

    if [[ -n "${SPEC_FLOW_FEATURE:-}" ]]; then
        current_branch="$SPEC_FLOW_FEATURE"
    elif $has_git; then
        current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "main")"
    else
        specs_dir="$repo_root/specs"
        max_num=-1
        if [[ -d "$specs_dir" ]]; then
            while IFS= read -r entry; do
                if [[ $entry =~ /([0-9]{3})- ]]; then
                    num=$((10#${BASH_REMATCH[1]}))
                    if (( num > max_num )); then
                        max_num=$num
                    fi
                fi
            done < <(find "$specs_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
        fi
        if (( max_num >= 0 )); then
            next_num="$(printf '%03d' $((max_num + 1)))"
            current_branch="$next_num-feature"
        else
            current_branch="main"
        fi
    fi

    branch_name="${current_branch#feat/}"
    branch_name="${branch_name#fix/}"
    branch_name="${branch_name#chore/}"
    branch_name="${branch_name#docs/}"
    branch_name="${branch_name#test/}"
    branch_name="${branch_name#refactor/}"
    branch_name="${branch_name#ci/}"
    branch_name="${branch_name#build/}"
    feature_dir="$repo_root/specs/$branch_name"

    cat <<EOF
REPO_ROOT=$repo_root
CURRENT_BRANCH=$current_branch
HAS_GIT=$has_git
FEATURE_DIR=$feature_dir
FEATURE_SPEC=$feature_dir/spec.md
IMPL_PLAN=$feature_dir/plan.md
TASKS=$feature_dir/tasks.md
RESEARCH=$feature_dir/research.md
DATA_MODEL=$feature_dir/data-model.md
QUICKSTART=$feature_dir/quickstart.md
CONTRACTS_DIR=$feature_dir/contracts
NOTES=$feature_dir/NOTES.md
ERROR_LOG=$feature_dir/error-log.md
VISUALS_DIR=$feature_dir/visuals
VISUALS_README=$feature_dir/visuals/README.md
ARTIFACTS_DIR=$feature_dir/artifacts
MEMORY_DIR=$repo_root/.spec-flow/memory
CONSTITUTION=$repo_root/.spec-flow/memory/constitution.md
ROADMAP=$repo_root/.spec-flow/memory/roadmap.md
DESIGN_INSPIRATIONS=$repo_root/.spec-flow/memory/design-inspirations.md
EOF
}

# Ensure a directory exists, creating it if necessary
# Usage: ensure_directory "/path/to/dir"
# Returns: 0 on success, 1 on failure
ensure_directory() {
    local dir="$1"
    if [[ -z "$dir" ]]; then
        log_error "ensure_directory: directory path required"
        return 1
    fi
    if [[ ! -d "$dir" ]]; then
        if ! mkdir -p "$dir" 2>/dev/null; then
            log_error "Failed to create directory: $dir"
            return 1
        fi
        log_info "Created directory: $dir"
    fi
    return 0
}

# Create a secure temporary file with mktemp
# Usage: create_temp_file "prefix"
# Returns: path to temp file on stdout
create_temp_file() {
    local prefix="${1:-spec-flow}"
    local tmpfile
    tmpfile=$(mktemp "/tmp/${prefix}.XXXXXX") || {
        log_error "Failed to create temporary file"
        return 1
    }
    printf "%s\n" "$tmpfile"
}

# Create a secure temporary directory with mktemp
# Usage: create_temp_dir "prefix"
# Returns: path to temp directory on stdout
create_temp_dir() {
    local prefix="${1:-spec-flow}"
    local tmpdir
    tmpdir=$(mktemp -d "/tmp/${prefix}.XXXXXX") || {
        log_error "Failed to create temporary directory"
        return 1
    }
    printf "%s\n" "$tmpdir"
}

# Sanitize a string into a URL/filesystem-safe slug
# Usage: sanitize_slug "My Feature Name!"
# Returns: my-feature-name
sanitize_slug() {
    local input="$1"
    # Convert to lowercase, replace spaces/underscores with hyphens,
    # remove non-alphanumeric (except hyphens), collapse multiple hyphens
    echo "$input" \
        | tr '[:upper:]' '[:lower:]' \
        | tr ' _' '-' \
        | sed 's/[^a-z0-9-]//g' \
        | sed 's/-\+/-/g' \
        | sed 's/^-//' \
        | sed 's/-$//'
}

log_success() {
    printf '[spec-flow][ok] %s\n' "$1" >&2
}
