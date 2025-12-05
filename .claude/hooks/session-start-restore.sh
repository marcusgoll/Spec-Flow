#!/bin/bash
# session-start-restore.sh - SessionStart hook for Spec-Flow workflow state restoration
#
# Triggers on: startup, resume, compact (post-compaction is critical for multi-context)
#
# This hook detects active workflows and displays context to help Claude resume work
# after context compaction or session restarts.
#
# Input: JSON on stdin with session_id, trigger_type, transcript_path, cwd
# Output: Stdout displayed to user, optionally writes to CLAUDE_ENV_FILE
#
# Version: 1.0.0

set -e

# Read JSON input from stdin
INPUT=$(cat)

# Parse trigger type (startup, resume, compact)
TRIGGER=$(echo "$INPUT" | grep -o '"type":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "unknown")

# Fallback detection from various JSON formats
if [ "$TRIGGER" = "unknown" ] || [ -z "$TRIGGER" ]; then
    TRIGGER=$(echo "$INPUT" | grep -o '"trigger_type":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
fi

# Get script directory for sourcing utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source detect-workflow-paths if available
DETECT_SCRIPT="$REPO_ROOT/.spec-flow/scripts/utils/detect-workflow-paths.sh"

# Attempt workflow detection
WORKFLOW_INFO=""
WORKFLOW_TYPE=""
WORKFLOW_SLUG=""
BASE_DIR=""
STATE_FILE=""

if [ -f "$DETECT_SCRIPT" ]; then
    WORKFLOW_INFO=$("$DETECT_SCRIPT" 2>/dev/null || echo "")

    if [ -n "$WORKFLOW_INFO" ]; then
        WORKFLOW_TYPE=$(echo "$WORKFLOW_INFO" | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
        WORKFLOW_SLUG=$(echo "$WORKFLOW_INFO" | grep -o '"slug":"[^"]*"' | cut -d'"' -f4)
        BASE_DIR=$(echo "$WORKFLOW_INFO" | grep -o '"base_dir":"[^"]*"' | cut -d'"' -f4)
    fi
fi

# Determine state file path
if [ "$WORKFLOW_TYPE" = "feature" ] && [ -n "$WORKFLOW_SLUG" ]; then
    STATE_FILE="$REPO_ROOT/specs/$WORKFLOW_SLUG/state.yaml"
elif [ "$WORKFLOW_TYPE" = "epic" ] && [ -n "$WORKFLOW_SLUG" ]; then
    STATE_FILE="$REPO_ROOT/epics/$WORKFLOW_SLUG/state.yaml"
fi

# Check if state file exists
if [ -f "$STATE_FILE" ] && command -v yq &> /dev/null; then
    # Extract state information
    PHASE=$(yq eval '.workflow.phase' "$STATE_FILE" 2>/dev/null || echo "unknown")
    STATUS=$(yq eval '.workflow.status' "$STATE_FILE" 2>/dev/null || echo "unknown")
    TITLE=$(yq eval '.feature.title // .epic.title' "$STATE_FILE" 2>/dev/null || echo "$WORKFLOW_SLUG")
    LAST_UPDATED=$(yq eval '.feature.last_updated // .epic.last_updated' "$STATE_FILE" 2>/dev/null || echo "unknown")

    # Count completed tasks if tasks.md exists
    TASKS_FILE=""
    if [ "$WORKFLOW_TYPE" = "feature" ]; then
        TASKS_FILE="$REPO_ROOT/specs/$WORKFLOW_SLUG/tasks.md"
    elif [ "$WORKFLOW_TYPE" = "epic" ]; then
        TASKS_FILE="$REPO_ROOT/epics/$WORKFLOW_SLUG/tasks.md"
    fi

    TASKS_TOTAL=0
    TASKS_COMPLETED=0
    if [ -f "$TASKS_FILE" ]; then
        TASKS_TOTAL=$(grep -c '^\- \[' "$TASKS_FILE" 2>/dev/null || echo "0")
        TASKS_COMPLETED=$(grep -c '^\- \[x\]' "$TASKS_FILE" 2>/dev/null || echo "0")
    fi

    # Persist workflow context to CLAUDE_ENV_FILE for session-wide access
    if [ -n "$CLAUDE_ENV_FILE" ]; then
        {
            echo "SPEC_FLOW_TYPE=$WORKFLOW_TYPE"
            echo "SPEC_FLOW_SLUG=$WORKFLOW_SLUG"
            echo "SPEC_FLOW_PHASE=$PHASE"
            echo "SPEC_FLOW_STATUS=$STATUS"
            echo "SPEC_FLOW_DIR=$BASE_DIR/$WORKFLOW_SLUG"
        } >> "$CLAUDE_ENV_FILE"
    fi

    # Display restoration banner
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ "$TRIGGER" = "compact" ]; then
        echo "Context compacted - workflow state restored from files"
    elif [ "$TRIGGER" = "resume" ]; then
        echo "Session resumed - workflow state restored"
    else
        echo "Active Workflow Detected"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Type:   $WORKFLOW_TYPE"
    echo "  Slug:   $WORKFLOW_SLUG"
    echo "  Title:  $TITLE"
    echo "  Phase:  $PHASE"
    echo "  Status: $STATUS"

    if [ "$TASKS_TOTAL" -gt 0 ]; then
        echo "  Tasks:  $TASKS_COMPLETED/$TASKS_TOTAL completed"
    fi

    echo ""

    # Check for handoff document (especially important after compaction)
    HANDOFF_FILE="$REPO_ROOT/$BASE_DIR/$WORKFLOW_SLUG/sessions/latest-handoff.md"
    if [ -f "$HANDOFF_FILE" ]; then
        echo "  Handoff available: $BASE_DIR/$WORKFLOW_SLUG/sessions/latest-handoff.md"
        echo ""
    fi

    # Check for NOTES.md session markers
    NOTES_FILE="$REPO_ROOT/$BASE_DIR/$WORKFLOW_SLUG/NOTES.md"
    if [ -f "$NOTES_FILE" ]; then
        # Get last session marker if exists
        LAST_SESSION=$(grep -E '^## Session:' "$NOTES_FILE" 2>/dev/null | tail -1 || echo "")
        if [ -n "$LAST_SESSION" ]; then
            echo "  Last session: $LAST_SESSION"
            echo ""
        fi
    fi

    # Suggest continuation command
    if [ "$WORKFLOW_TYPE" = "feature" ]; then
        echo "  Continue: /feature continue"
    elif [ "$WORKFLOW_TYPE" = "epic" ]; then
        echo "  Continue: /epic continue"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

else
    # No active workflow detected - silent exit for clean sessions
    if [ "$TRIGGER" = "startup" ]; then
        # Only show a minimal message on startup if no workflow
        :
    fi
fi

# Always exit successfully
exit 0
