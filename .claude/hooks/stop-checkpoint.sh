#!/bin/bash
# stop-checkpoint.sh - Stop hook for checkpointing workflow state
#
# Triggers on: Claude Code session stop/exit
#
# This hook saves a checkpoint of the current workflow state and optionally
# can signal to continue autopilot execution.
#
# Output: JSON with optional {"decision": "block"} to continue autopilot
#
# Version: 1.0.0

set -e

# Read JSON input from stdin
INPUT=$(cat)

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source detect-workflow-paths if available
DETECT_SCRIPT="$REPO_ROOT/.spec-flow/scripts/utils/detect-workflow-paths.sh"

# Detect active workflow
WORKFLOW_INFO=""
WORKFLOW_TYPE=""
WORKFLOW_SLUG=""
BASE_DIR=""

if [ -f "$DETECT_SCRIPT" ]; then
    WORKFLOW_INFO=$("$DETECT_SCRIPT" 2>/dev/null || echo "")

    if [ -n "$WORKFLOW_INFO" ]; then
        WORKFLOW_TYPE=$(echo "$WORKFLOW_INFO" | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
        WORKFLOW_SLUG=$(echo "$WORKFLOW_INFO" | grep -o '"slug":"[^"]*"' | cut -d'"' -f4)
        BASE_DIR=$(echo "$WORKFLOW_INFO" | grep -o '"base_dir":"[^"]*"' | cut -d'"' -f4)
    fi
fi

# Exit early if no active workflow
if [ -z "$WORKFLOW_TYPE" ] || [ "$WORKFLOW_TYPE" = "unknown" ]; then
    exit 0
fi

# Determine workflow directory
WORKFLOW_DIR="$REPO_ROOT/$BASE_DIR/$WORKFLOW_SLUG"

if [ ! -d "$WORKFLOW_DIR" ]; then
    exit 0
fi

# Get current state
STATE_FILE="$WORKFLOW_DIR/state.yaml"
PHASE="unknown"
STATUS="unknown"

if [ -f "$STATE_FILE" ] && command -v yq &> /dev/null; then
    PHASE=$(yq eval '.workflow.phase' "$STATE_FILE" 2>/dev/null || echo "unknown")
    STATUS=$(yq eval '.workflow.status' "$STATE_FILE" 2>/dev/null || echo "unknown")
fi

# Generate timestamp
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Update state.yaml with stop checkpoint
if [ -f "$STATE_FILE" ] && command -v yq &> /dev/null; then
    yq eval -i --arg ts "$TIMESTAMP" \
        '.session.last_checkpoint_at = $ts | .session.checkpoint_type = "stop"' \
        "$STATE_FILE" 2>/dev/null || true
fi

# Add checkpoint marker to NOTES.md
NOTES_FILE="$WORKFLOW_DIR/NOTES.md"
if [ -f "$NOTES_FILE" ]; then
    # Check if session was recently marked (within last few lines)
    RECENT_MARKER=$(tail -5 "$NOTES_FILE" | grep -c "Session Boundary:" || echo "0")

    # Only add stop checkpoint if no recent session boundary
    if [ "$RECENT_MARKER" = "0" ]; then
        {
            echo ""
            echo "---"
            echo ""
            echo "## Session Checkpoint: $TIMESTAMP"
            echo ""
            echo "Phase: $PHASE | Status: $STATUS"
            echo ""
        } >> "$NOTES_FILE"
    fi
fi

# Check for uncommitted changes and warn
UNCOMMITTED_COUNT=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

if [ "$UNCOMMITTED_COUNT" -gt 0 ]; then
    echo ""
    echo "Warning: $UNCOMMITTED_COUNT uncommitted changes in working directory"
    echo "Consider committing before ending session to preserve work."
    echo ""
fi

# Check if we should continue autopilot
# This could be enhanced to check for incomplete phase work
CONTINUE_AUTOPILOT=false

# Check if we're in the middle of implementation with incomplete tasks
if [ "$PHASE" = "implement" ] && [ "$STATUS" = "in_progress" ]; then
    TASKS_FILE="$WORKFLOW_DIR/tasks.md"
    if [ -f "$TASKS_FILE" ]; then
        TASKS_REMAINING=$(grep -c '^\- \[ \]' "$TASKS_FILE" 2>/dev/null || echo "0")

        # If tasks remain and we're in autopilot mode, signal to continue
        # Note: This is a conservative approach - only continue if explicitly enabled
        if [ "$TASKS_REMAINING" -gt 0 ]; then
            # Check for autopilot flag in state
            AUTOPILOT_ENABLED=$(yq eval '.session.autopilot_enabled // false' "$STATE_FILE" 2>/dev/null || echo "false")

            if [ "$AUTOPILOT_ENABLED" = "true" ]; then
                CONTINUE_AUTOPILOT=true
            fi
        fi
    fi
fi

# Output JSON response
if [ "$CONTINUE_AUTOPILOT" = "true" ]; then
    # Signal to continue autopilot (block the stop)
    echo '{"decision": "block", "reason": "Autopilot enabled with remaining tasks"}'
else
    # Allow stop, output checkpoint confirmation
    echo ""
    echo "Checkpoint saved for $WORKFLOW_TYPE: $WORKFLOW_SLUG"
    echo "Phase: $PHASE | Status: $STATUS"
    echo ""
    echo "Resume with: /$WORKFLOW_TYPE continue"
    echo ""
fi

exit 0
