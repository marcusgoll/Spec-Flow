#!/usr/bin/env bash
# shared-lib.sh - Shared library for Spec-Flow workflow scripts
#
# This library provides common functions used across workflow scripts to
# eliminate code duplication and ensure consistent behavior.
#
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/shared-lib.sh"
#
# Version: 1.0.0

# Prevent multiple sourcing
[[ -n "${_SPEC_FLOW_SHARED_LIB_LOADED:-}" ]] && return 0
_SPEC_FLOW_SHARED_LIB_LOADED=1

# Enable strict mode
set -Eeuo pipefail

# ============================================================================
# SCRIPT DIRECTORY AND REPO ROOT
# ============================================================================

# Get the directory containing the calling script
# Usage: SCRIPT_DIR=$(get_script_dir)
get_script_dir() {
    local src="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
    while [[ -L "$src" ]]; do
        local dir
        dir="$(cd -P "$(dirname "$src")" && pwd)"
        src="$(readlink "$src")"
        [[ $src != /* ]] && src="$dir/$src"
    done
    cd -P "$(dirname "$src")" && pwd
}

# Get the repository root directory
# Usage: REPO_ROOT=$(get_repo_root)
get_repo_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        # Fallback: traverse up from script directory
        local dir
        dir="$(get_script_dir)"
        local candidate
        candidate="$(cd "$dir/../.." 2>/dev/null && pwd)"
        if [[ -d "$candidate/specs" ]] || [[ -d "$candidate/.git" ]]; then
            printf "%s\n" "$candidate"
            return
        fi
        candidate="$(cd "$candidate/.." 2>/dev/null && pwd)"
        printf "%s\n" "$candidate"
    fi
}

# ============================================================================
# LOGGING
# ============================================================================

# Log levels with colors (if terminal supports it)
_supports_color() {
    [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]
}

log_info() {
    if _supports_color; then
        printf '\033[0;34m[spec-flow]\033[0m %s\n' "$1" >&2
    else
        printf '[spec-flow] %s\n' "$1" >&2
    fi
}

log_warn() {
    if _supports_color; then
        printf '\033[0;33m[spec-flow][warn]\033[0m %s\n' "$1" >&2
    else
        printf '[spec-flow][warn] %s\n' "$1" >&2
    fi
}

log_error() {
    if _supports_color; then
        printf '\033[0;31m[spec-flow][error]\033[0m %s\n' "$1" >&2
    else
        printf '[spec-flow][error] %s\n' "$1" >&2
    fi
}

log_success() {
    if _supports_color; then
        printf '\033[0;32m[spec-flow]\033[0m %s\n' "$1" >&2
    else
        printf '[spec-flow] %s\n' "$1" >&2
    fi
}

# ============================================================================
# ERROR HANDLING
# ============================================================================

# Setup error trap for a workflow phase
# Usage: setup_error_trap "phase_name" [cleanup_function]
# Example: setup_error_trap "/plan" cleanup_plan
setup_error_trap() {
    local phase_name="${1:-workflow}"
    local cleanup_fn="${2:-}"

    _workflow_error_handler() {
        local exit_code=$?
        local line_no=${BASH_LINENO[0]:-unknown}

        echo ""
        echo "⚠️  Error in $phase_name at line $line_no (exit code: $exit_code)"

        # Call cleanup function if provided
        if [[ -n "$cleanup_fn" ]] && declare -f "$cleanup_fn" >/dev/null 2>&1; then
            echo "Running cleanup..."
            "$cleanup_fn" || true
        fi

        exit "$exit_code"
    }

    trap '_workflow_error_handler' ERR
}

# ============================================================================
# TOOL PREFLIGHT CHECKS
# ============================================================================

# Check if a required tool is available
# Usage: need git jq yq
# Exits with error if any tool is missing
need() {
    local missing=()

    for tool in "$@"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing+=("$tool")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "❌ Missing required tool(s): ${missing[*]}"
        echo ""
        for tool in "${missing[@]}"; do
            case "$tool" in
                git)
                    echo "  $tool: https://git-scm.com/downloads"
                    ;;
                jq)
                    echo "  $tool: brew install jq (macOS) or apt install jq (Linux)"
                    echo "         https://stedolan.github.io/jq/download/"
                    ;;
                yq)
                    echo "  $tool: brew install yq (macOS) or snap install yq (Linux)"
                    echo "         https://github.com/mikefarah/yq#install"
                    ;;
                python|python3)
                    echo "  $tool: https://www.python.org/downloads/"
                    ;;
                node|npm|npx)
                    echo "  $tool: https://nodejs.org/en/download/"
                    ;;
                *)
                    echo "  $tool: Check documentation for installation"
                    ;;
            esac
        done
        exit 1
    fi
}

# Check if a tool is available (non-fatal)
# Usage: if has_tool yq; then ... fi
has_tool() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# FEATURE/WORKFLOW RESOLUTION
# ============================================================================

# Resolve feature directory from slug or current branch
# Usage: FEATURE_DIR=$(resolve_feature_dir "$slug_or_empty")
# Returns: absolute path to feature directory
resolve_feature_dir() {
    local slug="${1:-}"
    local repo_root
    repo_root="$(get_repo_root)"

    # If no slug provided, try to get from current branch
    if [[ -z "$slug" ]]; then
        slug=$(git branch --show-current 2>/dev/null || echo "")
    fi

    if [[ -z "$slug" ]]; then
        log_error "Cannot determine feature slug"
        return 1
    fi

    # Check specs/ first (feature workflows)
    if [[ -d "$repo_root/specs/$slug" ]]; then
        printf "%s/specs/%s\n" "$repo_root" "$slug"
        return 0
    fi

    # Check epics/ (epic workflows)
    if [[ -d "$repo_root/epics/$slug" ]]; then
        printf "%s/epics/%s\n" "$repo_root" "$slug"
        return 0
    fi

    # Not found
    log_error "Feature/epic not found: $slug"
    log_error "Searched: specs/$slug, epics/$slug"
    return 1
}

# Detect workflow type (feature or epic)
# Usage: WORKFLOW_TYPE=$(detect_workflow_type "$feature_dir")
# Returns: "feature" or "epic"
detect_workflow_type() {
    local feature_dir="${1:-}"

    if [[ -z "$feature_dir" ]]; then
        log_error "Feature directory required"
        return 1
    fi

    # Check for epic-spec.md (epic workflow)
    if [[ -f "$feature_dir/epic-spec.md" ]]; then
        echo "epic"
        return 0
    fi

    # Check for spec.md (feature workflow)
    if [[ -f "$feature_dir/spec.md" ]]; then
        echo "feature"
        return 0
    fi

    # Check directory path
    if [[ "$feature_dir" == */epics/* ]]; then
        echo "epic"
        return 0
    fi

    # Default to feature
    echo "feature"
}

# Validate feature directory exists and has required files
# Usage: validate_feature_dir "$feature_dir" [required_file1] [required_file2] ...
validate_feature_dir() {
    local feature_dir="$1"
    shift
    local required_files=("$@")

    if [[ ! -d "$feature_dir" ]]; then
        echo "❌ Feature directory not found: $feature_dir"
        echo ""
        echo "Fix: Run /spec or /epic to create feature first"
        return 1
    fi

    for file in "${required_files[@]}"; do
        local filepath="$feature_dir/$file"
        if [[ ! -f "$filepath" ]]; then
            echo "❌ Missing required file: $filepath"
            echo ""
            case "$file" in
                spec.md|epic-spec.md)
                    echo "Fix: Run /spec or /epic to create specification"
                    ;;
                plan.md)
                    echo "Fix: Run /plan to create implementation plan"
                    ;;
                tasks.md)
                    echo "Fix: Run /tasks to create task breakdown"
                    ;;
                *)
                    echo "Fix: Ensure previous workflow phases completed"
                    ;;
            esac
            return 1
        fi
    done

    return 0
}

# ============================================================================
# FILE UTILITIES
# ============================================================================

# Ensure a directory exists, creating it if necessary
# Usage: ensure_directory "/path/to/dir"
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
# Usage: TMPFILE=$(create_temp_file "prefix")
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
# Usage: TMPDIR=$(create_temp_dir "prefix")
create_temp_dir() {
    local prefix="${1:-spec-flow}"
    local tmpdir
    tmpdir=$(mktemp -d "/tmp/${prefix}.XXXXXX") || {
        log_error "Failed to create temporary directory"
        return 1
    }
    printf "%s\n" "$tmpdir"
}

# ============================================================================
# SAFE YQ OPERATIONS
# ============================================================================

# Safely update a YAML file field using yq with --arg
# Usage: safe_yq_set "$file" ".path.to.field" "$value"
safe_yq_set() {
    local file="$1"
    local path="$2"
    local value="$3"

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    # Use --arg to prevent injection
    yq eval -i --arg val "$value" "${path} = \$val" "$file"
}

# Safely read a YAML field using yq with --arg for dynamic paths
# Usage: VALUE=$(safe_yq_get "$file" ".path.to.field")
safe_yq_get() {
    local file="$1"
    local path="$2"

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    yq eval "$path" "$file"
}

# ============================================================================
# DATE/TIME UTILITIES (Cross-platform)
# ============================================================================

# Get current UTC timestamp in ISO8601 format
# Usage: TS=$(get_utc_timestamp)
get_utc_timestamp() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

# Parse ISO8601 timestamp to epoch seconds (cross-platform)
# Usage: EPOCH=$(parse_iso_date "2024-01-15T10:30:00Z")
parse_iso_date() {
    local iso_date="$1"

    # Try GNU date first (Linux)
    if date -d "$iso_date" +%s 2>/dev/null; then
        return 0
    fi

    # Try BSD date (macOS)
    if date -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso_date" +%s 2>/dev/null; then
        return 0
    fi

    # Fallback to Python
    if has_tool python3; then
        python3 -c "
from datetime import datetime
dt = datetime.fromisoformat('$iso_date'.replace('Z', '+00:00'))
print(int(dt.timestamp()))
" 2>/dev/null && return 0
    fi

    if has_tool python; then
        python -c "
from datetime import datetime
dt = datetime.fromisoformat('$iso_date'.replace('Z', '+00:00'))
print(int(dt.timestamp()))
" 2>/dev/null && return 0
    fi

    log_warn "Unable to parse date: $iso_date"
    return 1
}

# Calculate duration between two ISO8601 timestamps
# Usage: DURATION=$(calculate_duration "$start_iso" "$end_iso")
# Returns: duration in seconds
calculate_duration() {
    local start_iso="$1"
    local end_iso="$2"

    local start_epoch end_epoch
    start_epoch=$(parse_iso_date "$start_iso") || return 1
    end_epoch=$(parse_iso_date "$end_iso") || return 1

    echo $((end_epoch - start_epoch))
}

# Format seconds as human-readable duration
# Usage: FORMATTED=$(format_duration 3661)  # Returns "1h 1m"
format_duration() {
    local seconds=$1

    if [[ "$seconds" -lt 60 ]]; then
        echo "${seconds}s"
    elif [[ "$seconds" -lt 3600 ]]; then
        local minutes=$((seconds / 60))
        local secs=$((seconds % 60))
        echo "${minutes}m ${secs}s"
    else
        local hours=$((seconds / 3600))
        local minutes=$(((seconds % 3600) / 60))
        echo "${hours}h ${minutes}m"
    fi
}

# ============================================================================
# WORKFLOW STATE HELPERS
# ============================================================================

# Source workflow-state.sh if available
_load_workflow_state() {
    local script_dir
    script_dir="$(get_script_dir)"
    local state_script="$script_dir/workflow-state.sh"

    if [[ -f "$state_script" ]]; then
        # shellcheck source=/dev/null
        source "$state_script"
        return 0
    fi
    return 1
}

# Initialize workflow for a phase
# Usage: init_workflow_phase "/plan" "$feature_dir"
init_workflow_phase() {
    local phase="$1"
    local feature_dir="$2"

    setup_error_trap "$phase"

    if _load_workflow_state; then
        start_phase_timing "$feature_dir" "$phase" 2>/dev/null || true
    fi
}

# Complete workflow phase
# Usage: complete_workflow_phase "/plan" "$feature_dir"
complete_workflow_phase() {
    local phase="$1"
    local feature_dir="$2"

    if _load_workflow_state; then
        complete_phase_timing "$feature_dir" "$phase" 2>/dev/null || true
        update_workflow_phase "$feature_dir" "$phase" "completed" 2>/dev/null || true
    fi
}

# ============================================================================
# EXPORTS
# ============================================================================

# Export all functions for use in subshells
export -f get_script_dir get_repo_root
export -f log_info log_warn log_error log_success
export -f setup_error_trap
export -f need has_tool
export -f resolve_feature_dir detect_workflow_type validate_feature_dir
export -f ensure_directory create_temp_file create_temp_dir
export -f safe_yq_set safe_yq_get
export -f get_utc_timestamp parse_iso_date calculate_duration format_duration
export -f init_workflow_phase complete_workflow_phase
