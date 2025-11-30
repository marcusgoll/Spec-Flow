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
