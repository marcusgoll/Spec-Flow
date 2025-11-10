#!/usr/bin/env bash
set -euo pipefail

# Generate dev docs (task-scoped persistence)
#
# Usage:
#   ./generate-dev-docs.sh --task-name "database-migrations" --feature-dir "specs/001-auth"
#
# Creates three files in dev/active/[task-name]/:
#   - [task-name]-plan.md (strategic overview)
#   - [task-name]-context.md (key files, decisions)
#   - [task-name]-tasks.md (checklist format)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Load common utilities
source "$SCRIPT_DIR/common.sh" || { echo "Error: common.sh not found"; exit 1; }

# --- Parse Arguments ---
TASK_NAME=""
FEATURE_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --task-name)
            TASK_NAME="$2"
            shift 2
            ;;
        --feature-dir)
            FEATURE_DIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 --task-name <name> --feature-dir <path>"
            exit 1
            ;;
    esac
done

# Validate arguments
if [ -z "$TASK_NAME" ]; then
    echo "Error: --task-name is required"
    exit 1
fi

if [ -z "$FEATURE_DIR" ]; then
    echo "Error: --feature-dir is required"
    exit 1
fi

# --- Setup Paths ---
DEV_DOCS_DIR="$PROJECT_ROOT/dev/active/$TASK_NAME"
TEMPLATES_DIR="$PROJECT_ROOT/.spec-flow/templates/dev-docs"

SPEC_FILE="$PROJECT_ROOT/$FEATURE_DIR/spec.md"
PLAN_FILE="$PROJECT_ROOT/$FEATURE_DIR/plan.md"

# Extract feature name from directory
FEATURE_SLUG=$(basename "$FEATURE_DIR")
FEATURE_NAME=$(grep -E "^# " "$SPEC_FILE" 2>/dev/null | head -1 | sed 's/^# //' || echo "$FEATURE_SLUG")

# Current date
DATE=$(date +%Y-%m-%d)
STATUS="In Progress"

# --- Create Output Directory ---
mkdir -p "$DEV_DOCS_DIR"

echo "📝 Generating dev docs for: $TASK_NAME"
echo "   Feature: $FEATURE_NAME"
echo "   Output: $DEV_DOCS_DIR"
echo ""

# --- Generate plan.md ---
PLAN_OUTPUT="$DEV_DOCS_DIR/${TASK_NAME}-plan.md"

if [ ! -f "$PLAN_OUTPUT" ]; then
    sed -e "s|{{TASK_NAME}}|$TASK_NAME|g" \
        -e "s|{{DATE}}|$DATE|g" \
        -e "s|{{FEATURE_NAME}}|$FEATURE_NAME|g" \
        -e "s|{{STATUS}}|$STATUS|g" \
        "$TEMPLATES_DIR/plan-template.md" > "$PLAN_OUTPUT"

    echo "✅ Created: ${TASK_NAME}-plan.md"
else
    echo "⏭️  Skipped: ${TASK_NAME}-plan.md (already exists)"
fi

# --- Generate context.md ---
CONTEXT_OUTPUT="$DEV_DOCS_DIR/${TASK_NAME}-context.md"

if [ ! -f "$CONTEXT_OUTPUT" ]; then
    sed -e "s|{{TASK_NAME}}|$TASK_NAME|g" \
        -e "s|{{DATE}}|$DATE|g" \
        -e "s|{{FEATURE_NAME}}|$FEATURE_NAME|g" \
        -e "s|{{FEATURE_SLUG}}|$FEATURE_SLUG|g" \
        -e "s|{{FILE_PATH_1}}|[Specify file path]|g" \
        -e "s|{{FILE_PATH_2}}|[Specify file path]|g" \
        -e "s|{{FILE_PATH_3}}|[Specify file path]|g" \
        -e "s|{{FILE_PATH_4}}|[Specify file path]|g" \
        -e "s|{{FILE_PATH_5}}|[Specify file path]|g" \
        -e "s|{{DOC_NAME}}|tech-stack|g" \
        "$TEMPLATES_DIR/context-template.md" > "$CONTEXT_OUTPUT"

    echo "✅ Created: ${TASK_NAME}-context.md"
else
    echo "⏭️  Skipped: ${TASK_NAME}-context.md (already exists)"
fi

# --- Generate tasks.md ---
TASKS_OUTPUT="$DEV_DOCS_DIR/${TASK_NAME}-tasks.md"

if [ ! -f "$TASKS_OUTPUT" ]; then
    sed -e "s|{{TASK_NAME}}|$TASK_NAME|g" \
        -e "s|{{DATE}}|$DATE|g" \
        -e "s|{{FEATURE_NAME}}|$FEATURE_NAME|g" \
        -e "s|{{TOTAL_TASKS}}|0|g" \
        -e "s|{{COMPLETED_TASKS}}|0|g" \
        -e "s|{{PROGRESS_PERCENTAGE}}|0|g" \
        -e "s|{{IN_PROGRESS_TASKS}}|0|g" \
        -e "s|{{BLOCKED_TASKS}}|0|g" \
        -e "s|{{ETA}}|TBD|g" \
        -e "s|{{COMPLETION_DATE}}|$DATE|g" \
        -e "s|{{START_DATE}}|$DATE|g" \
        -e "s|{{BLOCK_DATE}}|$DATE|g" \
        -e "s|{{DATE_1}}|$DATE|g" \
        -e "s|{{DATE_2}}|$DATE|g" \
        -e "s|{{AVG_TASKS_PER_DAY}}|0|g" \
        -e "s|{{REMAINING_TIME}}|TBD|g" \
        "$TEMPLATES_DIR/tasks-template.md" > "$TASKS_OUTPUT"

    echo "✅ Created: ${TASK_NAME}-tasks.md"
else
    echo "⏭️  Skipped: ${TASK_NAME}-tasks.md (already exists)"
fi

echo ""
echo "✨ Dev docs generated successfully!"
echo ""
echo "Next steps:"
echo "  1. Edit ${TASK_NAME}-plan.md with strategic overview"
echo "  2. Edit ${TASK_NAME}-context.md with key files and decisions"
echo "  3. Edit ${TASK_NAME}-tasks.md with concrete tasks"
echo ""
echo "Resume work:"
echo "  Read dev/active/${TASK_NAME}/*.md for full context"
