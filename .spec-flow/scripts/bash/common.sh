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
