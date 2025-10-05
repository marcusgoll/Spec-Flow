#!/usr/bin/env bash
# Cross-platform equivalent of check-prerequisites.ps1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

show_help() {
    cat <<'EOF'
Usage: check-prerequisites.sh [OPTIONS]

Consolidated prerequisite checking for the Spec-Flow workflow.

Options:
  --json              Output results as JSON
  --require-tasks     Require tasks.md to exist (implementation phase)
  --include-tasks     Include tasks.md in AVAILABLE_DOCS
  --include-memories  Include memory files in output
  --paths-only        Print resolved paths without validation
  -h, --help          Show this help message
EOF
}

JSON_OUT=false
REQUIRE_TASKS=false
INCLUDE_TASKS=false
INCLUDE_MEMORIES=false
PATHS_ONLY=false

while (( $# )); do
    case "$1" in
        --json) JSON_OUT=true ;;
        --require-tasks) REQUIRE_TASKS=true ;;
        --include-tasks) INCLUDE_TASKS=true ;;
        --include-memories) INCLUDE_MEMORIES=true ;;
        --paths-only) PATHS_ONLY=true ;;
        -h|--help) show_help; exit 0 ;;
        *) log_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
    shift
done

mapfile -t ENV_VARS < <(feature_paths_env)
for kv in "${ENV_VARS[@]}"; do
    if [[ $kv == *=* ]]; then
        key="${kv%%=*}"
        value="${kv#*=}"
        export "$key=$value"
    fi
done

if $PATHS_ONLY; then
    if $JSON_OUT; then
        python - "$REPO_ROOT" "$CURRENT_BRANCH" "$FEATURE_DIR" "$INCLUDE_MEMORIES" <<'PY'
import json, sys
repo_root, branch, feature_dir, include_memories = sys.argv[1:5]
include_memories = include_memories.lower() == 'true'
paths = {
    "REPO_ROOT": repo_root,
    "CURRENT_BRANCH": branch,
    "FEATURE_DIR": feature_dir,
    "FEATURE_SPEC": f"{feature_dir}/spec.md",
    "IMPL_PLAN": f"{feature_dir}/plan.md",
    "TASKS": f"{feature_dir}/tasks.md",
    "RESEARCH": f"{feature_dir}/research.md",
    "DATA_MODEL": f"{feature_dir}/data-model.md",
    "QUICKSTART": f"{feature_dir}/quickstart.md",
    "CONTRACTS_DIR": f"{feature_dir}/contracts",
    "NOTES": f"{feature_dir}/NOTES.md",
    "ERROR_LOG": f"{feature_dir}/error-log.md",
    "VISUALS_DIR": f"{feature_dir}/visuals",
    "VISUALS_README": f"{feature_dir}/visuals/README.md",
    "ARTIFACTS_DIR": f"{feature_dir}/artifacts"
}
if include_memories:
    paths.update({
        "MEMORY_DIR": f"{repo_root}/.spec-flow/memory",
        "CONSTITUTION": f"{repo_root}/.spec-flow/memory/constitution.md",
        "ROADMAP": f"{repo_root}/.spec-flow/memory/roadmap.md",
        "DESIGN_INSPIRATIONS": f"{repo_root}/.spec-flow/memory/design-inspirations.md",
    })
json.dump({"PATHS": paths}, sys.stdout)
PY
    else
        cat <<EOF
REPO_ROOT: $REPO_ROOT
BRANCH: $CURRENT_BRANCH
FEATURE_DIR: $FEATURE_DIR
FEATURE_SPEC: $FEATURE_SPEC
IMPL_PLAN: $IMPL_PLAN
TASKS: $TASKS
RESEARCH: $RESEARCH
DATA_MODEL: $DATA_MODEL
QUICKSTART: $QUICKSTART
CONTRACTS_DIR: $CONTRACTS_DIR
NOTES: $NOTES
ERROR_LOG: $ERROR_LOG
VISUALS_DIR: $VISUALS_DIR
VISUALS_README: $VISUALS_README
ARTIFACTS_DIR: $ARTIFACTS_DIR
EOF
        if $INCLUDE_MEMORIES; then
            cat <<EOF
MEMORY_DIR: $MEMORY_DIR
CONSTITUTION: $CONSTITUTION
ROADMAP: $ROADMAP
DESIGN_INSPIRATIONS: $DESIGN_INSPIRATIONS
EOF
        fi
    fi
    exit 0
fi

if [ ! -d "$FEATURE_DIR" ]; then
    log_error "Feature directory not found: $FEATURE_DIR. Run /spec-flow first."
    exit 1
fi
if [ ! -f "$IMPL_PLAN" ]; then
    log_error "plan.md not found in $FEATURE_DIR. Run /plan first."
    exit 1
fi
if $REQUIRE_TASKS && [ ! -f "$TASKS" ]; then
    log_error "tasks.md not found in $FEATURE_DIR. Run /tasks first."
    exit 1
fi

AVAILABLE_DOCS=()
[[ -f "$RESEARCH" ]] && AVAILABLE_DOCS+=("research.md")
[[ -f "$DATA_MODEL" ]] && AVAILABLE_DOCS+=("data-model.md")
[[ -d "$CONTRACTS_DIR" && -n "$(find "$CONTRACTS_DIR" -maxdepth 1 -type f -print -quit 2>/dev/null)" ]] && AVAILABLE_DOCS+=("contracts/")
[[ -f "$QUICKSTART" ]] && AVAILABLE_DOCS+=("quickstart.md")
[[ -f "$NOTES" ]] && AVAILABLE_DOCS+=("NOTES.md")
[[ -f "$ERROR_LOG" ]] && AVAILABLE_DOCS+=("error-log.md")
[[ -f "$VISUALS_README" ]] && AVAILABLE_DOCS+=("visuals/README.md")
[[ -d "$ARTIFACTS_DIR" && -n "$(find "$ARTIFACTS_DIR" -maxdepth 1 -type f -print -quit 2>/dev/null)" ]] && AVAILABLE_DOCS+=("artifacts/")
if $INCLUDE_TASKS && [ -f "$TASKS" ]; then
    AVAILABLE_DOCS+=("tasks.md")
fi

MEMORY_DOCS=()
if $INCLUDE_MEMORIES; then
    [[ -f "$CONSTITUTION" ]] && MEMORY_DOCS+=("constitution.md")
    [[ -f "$ROADMAP" ]] && MEMORY_DOCS+=("roadmap.md")
    [[ -f "$DESIGN_INSPIRATIONS" ]] && MEMORY_DOCS+=("design-inspirations.md")
fi

if $JSON_OUT; then
    available_docs_payload="$({
        for doc in "${AVAILABLE_DOCS[@]-}"; do
            printf '%s\n' "$doc"
        done
    })"
    memory_docs_payload="$({
        for doc in "${MEMORY_DOCS[@]-}"; do
            printf '%s\n' "$doc"
        done
    })"
    env \
        FEATURE_DIR="$FEATURE_DIR" \
        INCLUDE_MEMORIES="$INCLUDE_MEMORIES" \
        AVAILABLE_DOCS_PAYLOAD="$available_docs_payload" \
        MEMORY_DOCS_PAYLOAD="$memory_docs_payload" \
        python <<'PY'
import json
import os

feature_dir = os.environ["FEATURE_DIR"]
include_memories = os.environ["INCLUDE_MEMORIES"].lower() == "true"
available = [line for line in os.environ.get("AVAILABLE_DOCS_PAYLOAD", "").splitlines() if line]
memory_docs = [line for line in os.environ.get("MEMORY_DOCS_PAYLOAD", "").splitlines() if line]
output = {"FEATURE_DIR": feature_dir, "AVAILABLE_DOCS": available}
if include_memories:
    output["MEMORY_DOCS"] = memory_docs
json.dump(output, sys.stdout)
PY
else
    echo "FEATURE_DIR:$FEATURE_DIR"
    echo 'AVAILABLE_DOCS:'
    for doc in "${AVAILABLE_DOCS[@]}"; do
        if [[ -f "$FEATURE_DIR/$doc" || -d "$FEATURE_DIR/${doc%/}" ]]; then
            echo "  [x] $doc"
        else
            echo "  [ ] $doc"
        fi
    done
    if $INCLUDE_MEMORIES; then
        echo
        echo 'MEMORY_DOCS:'
        for doc in "${MEMORY_DOCS[@]}"; do
            echo "  [x] $doc"
        done
    fi
fi
