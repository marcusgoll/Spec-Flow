#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS_SCRIPT="$SCRIPT_DIR/../powershell/task-tracker.ps1"

# Parse arguments
ACTION=""
TASK_ID=""
ERROR_MESSAGE=""
NOTES=""
EVIDENCE=""
COVERAGE=""
COMMIT_HASH=""
DURATION="est"
FEATURE_DIR=""
JSON_OUTPUT=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        mark-failed)
            ACTION="mark-failed"
            shift
            ;;
        -TaskId)
            TASK_ID="$2"
            shift 2
            ;;
        -ErrorMessage)
            ERROR_MESSAGE="$2"
            shift 2
            ;;
        -Notes)
            NOTES="$2"
            shift 2
            ;;
        -Evidence)
            EVIDENCE="$2"
            shift 2
            ;;
        -Coverage)
            COVERAGE="$2"
            shift 2
            ;;
        -CommitHash)
            COMMIT_HASH="$2"
            shift 2
            ;;
        -Duration)
            DURATION="$2"
            shift 2
            ;;
        -FeatureDir)
            FEATURE_DIR="$2"
            shift 2
            ;;
        -Json)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            # Unknown argument - pass to PowerShell
            break
            ;;
    esac
done

# If action is mark-failed, handle it natively in bash
if [[ "$ACTION" == "mark-failed" ]]; then
    # Validate required parameters
    if [[ -z "$TASK_ID" ]]; then
        echo "Error: TaskId required for mark-failed action" >&2
        exit 1
    fi
    if [[ -z "$ERROR_MESSAGE" ]]; then
        echo "Error: ErrorMessage required for mark-failed action" >&2
        exit 1
    fi

    # Determine feature directory
    if [[ -z "$FEATURE_DIR" ]]; then
        # Find most recent feature directory
        SPECS_DIR=".spec-flow/memory/specs"
        if [[ ! -d "$SPECS_DIR" ]]; then
            SPECS_DIR="specs"
        fi

        if [[ ! -d "$SPECS_DIR" ]]; then
            echo "Error: No specs directory found. Run /feature first." >&2
            exit 1
        fi

        FEATURE_DIR=$(find "$SPECS_DIR" -maxdepth 1 -type d -not -name "$(basename "$SPECS_DIR")" -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

        if [[ -z "$FEATURE_DIR" ]]; then
            echo "Error: No feature directories found in $SPECS_DIR" >&2
            exit 1
        fi
    fi

    ERROR_LOG="$FEATURE_DIR/error-log.md"
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

    # Create error-log.md if it doesn't exist
    if [[ ! -f "$ERROR_LOG" ]]; then
        echo "# Error Log" > "$ERROR_LOG"
        echo "" >> "$ERROR_LOG"
    fi

    # Append error entry
    {
        echo ""
        echo "## ❌ $TASK_ID - $TIMESTAMP"
        echo ""
        echo "**Error:** $ERROR_MESSAGE"
        echo ""
        echo "**Status:** Needs retry or investigation"
        echo ""
        echo "---"
        echo ""
    } >> "$ERROR_LOG"

    # Output result
    if [[ "$JSON_OUTPUT" == true ]]; then
        cat <<EOF
{
  "Success": true,
  "TaskId": "$TASK_ID",
  "Message": "Task $TASK_ID marked as failed in error-log.md",
  "ErrorLogFile": "$ERROR_LOG",
  "Timestamp": "$TIMESTAMP"
}
EOF
    else
        echo "Task $TASK_ID marked as failed in error-log.md"
    fi

    exit 0
fi

# For all other actions, delegate to PowerShell
if command -v pwsh >/dev/null 2>&1; then
    exec pwsh -NoLogo -NoProfile -File "$PS_SCRIPT" "$@"
elif command -v powershell >/dev/null 2>&1; then
    exec powershell -NoLogo -NoProfile -File "$PS_SCRIPT" "$@"
else
    echo "PowerShell 7+ is required to run task-tracker." >&2
    exit 1
fi

