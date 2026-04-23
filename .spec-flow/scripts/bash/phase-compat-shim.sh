#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"
# shellcheck source=.spec-flow/scripts/bash/shared-lib.sh
source "$SCRIPT_DIR/shared-lib.sh"

PHASE="${1:-}"
if [[ -z "$PHASE" ]]; then
    echo "Usage: phase-compat-shim.sh <tasks|validate|implement|preview> [feature] [flags]" >&2
    exit 1
fi
shift || true

JSON_OUT=false
FEATURE=""
EXTRA_ARGS=()

while (( "$#" )); do
    case "$1" in
        --json)
            JSON_OUT=true
            ;;
        --help|-h)
            cat <<EOF
Usage: ${PHASE}-workflow.sh [feature-slug] [flags]

Compatibility shim for the ${PHASE} phase in this checkout.
The installed workflow command remains the supported execution surface.
EOF
            exit 0
            ;;
        --*)
            EXTRA_ARGS+=("$1")
            ;;
        *)
            if [[ -z "$FEATURE" ]]; then
                FEATURE="$1"
            else
                EXTRA_ARGS+=("$1")
            fi
            ;;
    esac
    shift
done

PYTHON_CMD="$(resolve_python_cmd)"

emit_json_error() {
    local error_code="$1"
    local message="$2"
    local hint="$3"
    local workflow_type="${4:-}"
    local feature_dir="${5:-}"
    local missing_payload="${6:-}"

    PHASE_JSON="$PHASE" \
    ERROR_JSON="$error_code" \
    MESSAGE_JSON="$message" \
    HINT_JSON="$hint" \
    WORKFLOW_TYPE_JSON="$workflow_type" \
    FEATURE_DIR_JSON="$feature_dir" \
    MISSING_JSON="$missing_payload" \
    "$PYTHON_CMD" - <<'PY'
import json
import os
import sys

payload = {
    "phase": os.environ["PHASE_JSON"],
    "status": "error",
    "error": os.environ["ERROR_JSON"],
    "message": os.environ["MESSAGE_JSON"],
}
hint = os.environ.get("HINT_JSON", "")
workflow_type = os.environ.get("WORKFLOW_TYPE_JSON", "")
feature_dir = os.environ.get("FEATURE_DIR_JSON", "")
missing = [item for item in os.environ.get("MISSING_JSON", "").splitlines() if item]

if hint:
    payload["hint"] = hint
if workflow_type:
    payload["workflow_type"] = workflow_type
if feature_dir:
    payload["feature_dir"] = feature_dir
if missing:
    payload["missing"] = missing

json.dump(payload, sys.stdout)
sys.stdout.write("\n")
PY
}

emit_error() {
    local error_code="$1"
    local message="$2"
    local hint="$3"
    local workflow_type="${4:-}"
    local feature_dir="${5:-}"
    local missing_payload="${6:-}"

    if $JSON_OUT; then
        emit_json_error "$error_code" "$message" "$hint" "$workflow_type" "$feature_dir" "$missing_payload"
    else
        echo "❌ $message" >&2
        if [[ -n "$hint" ]]; then
            echo "$hint" >&2
        fi
    fi
    exit 1
}

repo_root="$(get_repo_root)"
cd "$repo_root"

target_ref="$FEATURE"
if [[ -z "$target_ref" ]]; then
    target_ref="$(git branch --show-current 2>/dev/null || echo "")"
fi
if [[ -z "$target_ref" ]]; then
    target_ref="current workflow"
fi

feature_dir=""
if ! feature_dir="$(resolve_feature_dir "$FEATURE" 2>/dev/null)"; then
    emit_error \
        "feature_not_found" \
        "Feature or epic not found: $target_ref" \
        "Run the phase from a real specs/<slug> or epics/<slug> directory, or pass a valid workflow slug."
fi

workflow_type="$(detect_workflow_type "$feature_dir")"
spec_file="$feature_dir/spec.md"
if [[ "$workflow_type" == "epic" ]]; then
    spec_file="$feature_dir/epic-spec.md"
fi

missing=()
case "$PHASE" in
    tasks)
        [[ -f "$spec_file" ]] || missing+=("$(basename "$spec_file")")
        [[ -f "$feature_dir/plan.md" ]] || missing+=("plan.md")
        phase_message="The shared /tasks runtime is not shipped in this checkout."
        phase_hint="Use the installed /tasks workflow command. In this checkout, task generation remains adapter-owned."
        ;;
    validate)
        [[ -f "$spec_file" ]] || missing+=("$(basename "$spec_file")")
        [[ -f "$feature_dir/plan.md" ]] || missing+=("plan.md")
        [[ -f "$feature_dir/tasks.md" ]] || missing+=("tasks.md")
        phase_message="The shared /validate runtime is not shipped in this checkout."
        phase_hint="Use the installed /validate workflow command. The direct spec-cli path only provides compatibility preflight here."
        ;;
    implement)
        [[ -f "$feature_dir/tasks.md" ]] || missing+=("tasks.md")
        phase_message="The shared /implement runtime is not shipped in this checkout."
        phase_hint="Use the installed /implement workflow command. The direct spec-cli path only provides compatibility preflight here."
        ;;
    preview)
        phase_message="The shared /preview runtime is not shipped in this checkout."
        phase_hint="Use the installed /preview workflow command if your adapter ships it, or run preview manually in the consumer project."
        ;;
    *)
        emit_error \
            "unsupported_phase" \
            "Unsupported compatibility phase: $PHASE" \
            "Expected one of: tasks, validate, implement, preview."
        ;;
esac

if (( ${#missing[@]} > 0 )); then
    missing_text="$(printf '%s\n' "${missing[@]}")"
    emit_error \
        "missing_required_artifacts" \
        "Missing required artifact(s) for /$PHASE: ${missing[*]}" \
        "Complete the earlier workflow phases in $feature_dir before invoking /$PHASE." \
        "$workflow_type" \
        "$feature_dir" \
        "$missing_text"
fi

emit_error \
    "shared_phase_runtime_not_shipped" \
    "$phase_message" \
    "$phase_hint" \
    "$workflow_type" \
    "$feature_dir"
