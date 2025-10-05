#!/usr/bin/env bash
# Cross-platform equivalent of calculate-tokens.ps1

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: calculate-tokens.sh --feature-dir <path> [--phase planning|implementation|optimization|auto] [--json] [--verbose]

Estimate token counts for a Spec-Flow feature directory using a 4-characters-per-token heuristic.
EOF
}

FEATURE_DIR=""
PHASE="auto"
JSON_OUT=false
VERBOSE=false

while (( $# )); do
    case "$1" in
        --feature-dir)
            shift
            FEATURE_DIR="${1:-}"
            ;;
        --phase)
            shift
            PHASE="${1:-auto}"
            ;;
        --json) JSON_OUT=true ;;
        --verbose) VERBOSE=true ;;
        -h|--help)
            usage
            exit 0
            ;;
        --*)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
        *)
            if [ -z "$FEATURE_DIR" ]; then
                FEATURE_DIR="$1"
            else
                echo "Unexpected argument: $1" >&2
                usage
                exit 1
            fi
            ;;
    esac
    shift
done

if [ -z "$FEATURE_DIR" ]; then
    echo "--feature-dir is required" >&2
    usage
    exit 1
fi

if [ ! -d "$FEATURE_DIR" ]; then
    echo "Feature directory not found: $FEATURE_DIR" >&2
    exit 1
fi

estimate_tokens() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo 0
        return
    fi
    python - "$file" <<'PY'
import math, sys
path = sys.argv[1]
try:
    with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
        data = fh.read()
except FileNotFoundError:
    print(0)
    raise SystemExit
chars = len(data)
print(math.ceil(chars / 4))
PY
}

detect_phase() {
    local notes="$FEATURE_DIR/NOTES.md"
    if [ ! -f "$notes" ]; then
        echo "planning"
        return
    fi
    local content
    content="$(tr -d '\r' < "$notes")"
    if echo "$content" | grep -qiE 'Phase [5-7].*Completed'; then
        echo "optimization"
    elif echo "$content" | grep -qiE 'Phase [3-4].*Completed'; then
        echo "implementation"
    else
        echo "planning"
    fi
}

if [ "$PHASE" = "auto" ]; then
    PHASE="$(detect_phase)"
fi

case "$PHASE" in
    planning) BUDGET=75000; THRESH=60000 ;;
    implementation) BUDGET=100000; THRESH=80000 ;;
    optimization) BUDGET=125000; THRESH=100000 ;;
    *) echo "Invalid phase: $PHASE" >&2; exit 1 ;;
esac

artifacts=(
    "spec.md"
    "plan.md"
    "research.md"
    "tasks.md"
    "NOTES.md"
    "error-log.md"
    "data-model.md"
    "quickstart.md"
    "visuals/README.md"
)

TOTAL=0
breakdown_files=()
breakdown_tokens=()

for artifact in "${artifacts[@]}"; do
    file="$FEATURE_DIR/$artifact"
    if [ -f "$file" ]; then
        tokens="$(estimate_tokens "$file")"
        breakdown_files+=("$artifact")
        breakdown_tokens+=("$tokens")
        TOTAL=$((TOTAL + tokens))
    fi
done

if [ -d "$FEATURE_DIR/artifacts" ]; then
    while IFS= read -r file; do
        tokens="$(estimate_tokens "$file")"
        rel="artifacts/${file##*/}"
        breakdown_files+=("$rel")
        breakdown_tokens+=("$tokens")
        TOTAL=$((TOTAL + tokens))
    done < <(find "$FEATURE_DIR/artifacts" -maxdepth 1 -type f 2>/dev/null)
fi

REMAINING=$((BUDGET - TOTAL))
if [ $BUDGET -gt 0 ]; then
    PERCENT=$(python - <<PY
print(round(($TOTAL / $BUDGET) * 100, 1))
PY
)
else
    PERCENT=0
fi
if [ $TOTAL -gt $THRESH ]; then
    SHOULD_COMPACT=true
else
    SHOULD_COMPACT=false
fi

if $JSON_OUT; then
    breakdown_rows="$({
        for idx in "${!breakdown_files[@]}"; do
            printf '%s\t%s\n' "${breakdown_files[$idx]}" "${breakdown_tokens[$idx]}"
        done
    })"
    env \
        FEATURE_DIR="$FEATURE_DIR" \
        PHASE="$PHASE" \
        TOTAL="$TOTAL" \
        BUDGET="$BUDGET" \
        THRESH="$THRESH" \
        REMAINING="$REMAINING" \
        PERCENT="$PERCENT" \
        SHOULD_COMPACT="$SHOULD_COMPACT" \
        BREAKDOWN_ROWS="$breakdown_rows" \
        python <<'PY'
import json
import os

feature_dir = os.environ["FEATURE_DIR"]
phase = os.environ["PHASE"]
total = int(os.environ["TOTAL"])
budget = int(os.environ["BUDGET"])
threshold = int(os.environ["THRESH"])
remaining = int(os.environ["REMAINING"])
percent = float(os.environ["PERCENT"])
should_compact = os.environ["SHOULD_COMPACT"].lower() == "true"
pairs = [line.split('\t', 1) for line in os.environ.get("BREAKDOWN_ROWS", "").splitlines() if line.strip()]
breakdown = {name: int(tokens) for name, tokens in pairs}
print(json.dumps({
    "featureDir": feature_dir,
    "phase": phase,
    "totalTokens": total,
    "budget": budget,
    "compactionThreshold": threshold,
    "remaining": remaining,
    "percentUsed": percent,
    "shouldCompact": should_compact,
    "breakdown": breakdown
}))
PY
else
    if $VERBOSE; then
        echo "Token breakdown:"
        for idx in "${!breakdown_files[@]}"; do
            printf '  %s: %s tokens\n' "${breakdown_files[$idx]}" "${breakdown_tokens[$idx]}"
        done
        echo
    fi
    printf 'Tokens: %d / %d (%s%%)\n' "$TOTAL" "$BUDGET" "$PERCENT"
    echo "Phase: $PHASE"
    printf 'Threshold: %d tokens (80%%)\n' "$THRESH"
    printf 'Remaining: %d tokens\n' "$REMAINING"
    echo
    if $SHOULD_COMPACT; then
        echo "Compaction recommended (exceeded threshold)."
        echo "Run: .spec-flow/scripts/bash/compact-context.sh --feature-dir '$FEATURE_DIR' --phase '$PHASE'"
    else
        python - <<PY
threshold = $THRESH
margin = threshold - $TOTAL
if threshold > 0:
    margin_pct = round((margin / threshold) * 100, 1)
else:
    margin_pct = 0
print(f"Within budget ({margin_pct}% margin until compaction)")
PY
    fi
fi
