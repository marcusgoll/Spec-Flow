#!/bin/bash
# pre-compact-handoff.sh - PreCompact hook for generating handoff documents
#
# Triggers on: auto (automatic compaction), manual (user-triggered)
#
# This hook generates a handoff document before context compaction to preserve
# critical state and decisions for the next context window.
#
# Note: PreCompact hooks are informational only - they cannot block compaction.
# The goal is to capture state quickly before context is lost.
#
# Version: 1.0.0

set -e

# Read JSON input from stdin
INPUT=$(cat)

# Parse trigger type
TRIGGER=$(echo "$INPUT" | grep -o '"trigger":"[^"]*"' | cut -d'"' -f4 || echo "auto")

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

# Create sessions directory if needed
SESSIONS_DIR="$WORKFLOW_DIR/sessions"
mkdir -p "$SESSIONS_DIR"

# Generate timestamp
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
SESSION_ID=$(date +%Y%m%d-%H%M%S)

# Get current state
STATE_FILE="$WORKFLOW_DIR/state.yaml"
PHASE="unknown"
STATUS="unknown"

if [ -f "$STATE_FILE" ] && command -v yq &> /dev/null; then
    PHASE=$(yq eval '.workflow.phase' "$STATE_FILE" 2>/dev/null || echo "unknown")
    STATUS=$(yq eval '.workflow.status' "$STATE_FILE" 2>/dev/null || echo "unknown")
fi

# Get task progress
TASKS_FILE="$WORKFLOW_DIR/tasks.md"
TASKS_TOTAL=0
TASKS_COMPLETED=0
CURRENT_TASK=""

if [ -f "$TASKS_FILE" ]; then
    TASKS_TOTAL=$(grep -c '^\- \[' "$TASKS_FILE" 2>/dev/null || echo "0")
    TASKS_COMPLETED=$(grep -c '^\- \[x\]' "$TASKS_FILE" 2>/dev/null || echo "0")
    # Get first uncompleted task
    CURRENT_TASK=$(grep -m1 '^\- \[ \]' "$TASKS_FILE" 2>/dev/null | sed 's/^- \[ \] //' || echo "None pending")
fi

# Get recent NOTES entries (last 10 lines of relevant content)
NOTES_FILE="$WORKFLOW_DIR/NOTES.md"
RECENT_NOTES=""
if [ -f "$NOTES_FILE" ]; then
    RECENT_NOTES=$(tail -20 "$NOTES_FILE" 2>/dev/null | head -10 || echo "")
fi

# Generate handoff document
HANDOFF_FILE="$SESSIONS_DIR/handoff-$SESSION_ID.md"
LATEST_HANDOFF="$SESSIONS_DIR/latest-handoff.md"

cat > "$HANDOFF_FILE" <<EOF
# Session Handoff: $WORKFLOW_SLUG

> Generated: $TIMESTAMP
> Trigger: Context compaction ($TRIGGER)
> Phase: $PHASE
> Status: $STATUS

## Quick Resume

\`\`\`bash
# Continue this workflow:
EOF

if [ "$WORKFLOW_TYPE" = "feature" ]; then
    echo "/feature continue" >> "$HANDOFF_FILE"
else
    echo "/epic continue" >> "$HANDOFF_FILE"
fi

cat >> "$HANDOFF_FILE" <<EOF
\`\`\`

## Current State

| Metric | Value |
|--------|-------|
| Workflow Type | $WORKFLOW_TYPE |
| Slug | $WORKFLOW_SLUG |
| Current Phase | $PHASE |
| Phase Status | $STATUS |
| Tasks Progress | $TASKS_COMPLETED / $TASKS_TOTAL |

## Next Task

$CURRENT_TASK

## Key Artifacts

- State: \`$BASE_DIR/$WORKFLOW_SLUG/state.yaml\`
- Tasks: \`$BASE_DIR/$WORKFLOW_SLUG/tasks.md\`
- Notes: \`$BASE_DIR/$WORKFLOW_SLUG/NOTES.md\`
EOF

if [ -f "$WORKFLOW_DIR/plan.md" ]; then
    echo "- Plan: \`$BASE_DIR/$WORKFLOW_SLUG/plan.md\`" >> "$HANDOFF_FILE"
fi

if [ -f "$WORKFLOW_DIR/spec.md" ]; then
    echo "- Spec: \`$BASE_DIR/$WORKFLOW_SLUG/spec.md\`" >> "$HANDOFF_FILE"
fi

cat >> "$HANDOFF_FILE" <<EOF

## Recent Activity

\`\`\`
$RECENT_NOTES
\`\`\`

## Critical Reminders

1. Read state.yaml for complete workflow state
2. Check tasks.md for task completion status
3. Review NOTES.md for decisions and blockers
4. Use \`/context next\` for detailed next steps

---

*This handoff was automatically generated before context compaction.*
*Session ID: $SESSION_ID*
EOF

# Create symlink to latest handoff
cp "$HANDOFF_FILE" "$LATEST_HANDOFF"

# Add session marker to NOTES.md if it exists
if [ -f "$NOTES_FILE" ]; then
    # Add session boundary marker
    {
        echo ""
        echo "---"
        echo ""
        echo "## Session Boundary: $TIMESTAMP"
        echo ""
        echo "*Context compaction occurred. Handoff saved to: sessions/handoff-$SESSION_ID.md*"
        echo ""
    } >> "$NOTES_FILE"
fi

# Update state.yaml with session info
if [ -f "$STATE_FILE" ] && command -v yq &> /dev/null; then
    yq eval -i --arg ts "$TIMESTAMP" --arg sid "$SESSION_ID" \
        '.session.last_handoff_at = $ts | .session.last_handoff_id = $sid' \
        "$STATE_FILE" 2>/dev/null || true
fi

# Output confirmation (visible to user briefly before compaction)
echo ""
echo "Handoff document generated: sessions/handoff-$SESSION_ID.md"
echo ""

exit 0
