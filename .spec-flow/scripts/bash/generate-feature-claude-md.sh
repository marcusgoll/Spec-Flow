#!/usr/bin/env bash
# Generate feature-level CLAUDE.md with context, progress, and relevant agents
#
# IMPORTANT: This script generates STATUS and CONTEXT aggregation, NOT behavioral
# instructions. Behavioral instructions live in the root CLAUDE.md (human-written).
# This follows the "don't auto-generate instructions" best practice from context
# engineering guidelines.
#
# Output includes:
# - Current phase and progress status
# - Recent activity from NOTES.md
# - Next task to work on
# - Key artifacts for navigation
# - Phase-specific agent recommendations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

show_help() {
    cat <<'EOF'
Usage: generate-feature-claude-md.sh [--json] <feature-dir>

Generate or update feature-level CLAUDE.md with current context, progress,
and relevant specialist agents for the current phase.

Arguments:
  feature-dir     Path to feature directory (e.g., specs/001-auth-flow)

Example:
  generate-feature-claude-md.sh specs/001-auth-flow
EOF
}

JSON_OUT=false

while (( $# )); do
    case "$1" in
        --json) JSON_OUT=true ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --*)
            log_error "Unknown option: $1"
            exit 1
            ;;
        *)
            break
            ;;
    esac
    shift
done

if [ $# -eq 0 ]; then
    log_error "Provide a feature directory path."
    show_help
    exit 1
fi

FEATURE_DIR="$1"
CLAUDE_MD_FILE="$FEATURE_DIR/CLAUDE.md"
STATE_FILE="$FEATURE_DIR/state.yaml"
SPEC_FILE="$FEATURE_DIR/spec.md"

if [ ! -f "$STATE_FILE" ]; then
    log_error "No state.yaml found in $FEATURE_DIR"
    exit 1
fi

# Extract feature name from directory
FEATURE_SLUG=$(basename "$FEATURE_DIR")
FEATURE_NAME=$(echo "$FEATURE_SLUG" | sed 's/^[0-9]\+-//' | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')

# Read workflow state using yq (if available) or fallback to grep/sed
read_yaml_value() {
    local file="$1"
    local key="$2"

    if command -v yq >/dev/null 2>&1; then
        yq eval "$key" "$file" 2>/dev/null || echo ""
    else
        # Fallback: simple grep/sed parsing for basic YAML
        grep -E "^\s*${key##*.}:" "$file" 2>/dev/null | sed 's/^[^:]*:[[:space:]]*//' || echo ""
    fi
}

CURRENT_PHASE=$(read_yaml_value "$STATE_FILE" ".workflow.phase")
STATUS=$(read_yaml_value "$STATE_FILE" ".workflow.status")

# Extract GitHub issue number from spec.md if it exists
GITHUB_ISSUE=""
if [ -f "$SPEC_FILE" ]; then
    GITHUB_ISSUE=$(grep -oP 'GitHub Issue.*#\K\d+' "$SPEC_FILE" 2>/dev/null | head -1 || echo "")
fi

# Calculate task completion percentage
TASKS_FILE="$FEATURE_DIR/tasks.md"
TASK_PROGRESS="0/0 (0%)"
if [ -f "$TASKS_FILE" ]; then
    TOTAL_TASKS=$(grep -cE '^\s*-\s*\[.?\]' "$TASKS_FILE" 2>/dev/null || echo "0")
    COMPLETED_TASKS=$(grep -cE '^\s*-\s*\[[Xx]\]' "$TASKS_FILE" 2>/dev/null || echo "0")
    if [ "$TOTAL_TASKS" -gt 0 ]; then
        PERCENTAGE=$(( COMPLETED_TASKS * 100 / TOTAL_TASKS ))
        TASK_PROGRESS="$COMPLETED_TASKS/$TOTAL_TASKS ($PERCENTAGE%)"
    fi
fi

# Extract recent progress from NOTES.md
RECENT_PROGRESS=""
if [ -f "$FEATURE_DIR/NOTES.md" ]; then
    RECENT_PROGRESS=$("$SCRIPT_DIR/extract-notes-summary.sh" --count 3 "$FEATURE_DIR" 2>/dev/null || echo "")
fi

# Determine next task from tasks.md
NEXT_TASK="Check tasks.md"
if [ -f "$TASKS_FILE" ]; then
    NEXT_TASK=$(grep -m 1 -E '^\s*-\s*\[\s\]\s*T[0-9]+' "$TASKS_FILE" 2>/dev/null | sed 's/^\s*-\s*\[\s\]\s*//' || echo "Check tasks.md")
fi

# Determine relevant agents based on current phase
get_relevant_agents() {
    local phase="$1"

    case "$phase" in
        spec|clarify)
            cat <<'AGENTS'
### Specification Agents (Current Phase)
- `spec-phase-agent` - Generate comprehensive feature specifications
- `clarify-phase-agent` - Reduce ambiguity via targeted questions

### Support Agents
- `/spec` - Create feature specification
- `/clarify` - Ask clarifying questions
AGENTS
            ;;
        plan)
            cat <<'AGENTS'
### Planning Agents (Current Phase)
- `plan-phase-agent` - Research + design + architecture planning
- `Explore` - Fast codebase exploration for reuse patterns

### Support Agents
- `/plan` - Generate design artifacts
AGENTS
            ;;
        tasks)
            cat <<'AGENTS'
### Task Breakdown Agents (Current Phase)
- `tasks-phase-agent` - Generate concrete TDD tasks with acceptance criteria

### Support Agents
- `/tasks` - Generate task breakdown
AGENTS
            ;;
        validate)
            cat <<'AGENTS'
### Validation Agents (Current Phase)
- `analyze-phase-agent` - Cross-artifact consistency validation

### Support Agents
- `/validate` - Analyze spec/plan/tasks consistency
AGENTS
            ;;
        implement*)
            cat <<'AGENTS'
### Implementation Commands & Agents (Current Phase)
- `/implement` - Orchestrates parallel specialist execution
- `backend-dev` - Backend/API implementation
- `frontend-dev` - Frontend/UI implementation
- `database-architect` - Schema design and migrations
- `contracts-sdk` - API contract management

### Support Agents (As Needed)
- `debugger` - Error investigation
- `/debug` - Debug errors
AGENTS
            ;;
        optimize)
            cat <<'AGENTS'
### Optimization Agents (Current Phase)
- `optimize-phase-agent` - Performance, security, accessibility review
- `senior-code-reviewer` - Code quality and KISS/DRY enforcement
- `qa-test` - Test coverage and quality assurance

### Support Agents
- `/optimize` - Production readiness validation
AGENTS
            ;;
        preview)
            cat <<'AGENTS'
### Preview Agents (Current Phase)
- `preview-phase-agent` - Manual UI/UX testing orchestration

### Support Agents
- `/preview` - Start local dev server for manual testing
AGENTS
            ;;
        ship*)
            cat <<'AGENTS'
### Deployment Agents (Current Phase)
- `ship-staging-phase-agent` - Deploy to staging environment
- `ship-prod-phase-agent` - Promote to production
- `ci-cd-release` - CI/CD and release management

### Support Agents
- `/ship` - Unified deployment orchestrator
- `/ship-staging` - Deploy to staging
- `/ship-prod` - Promote to production
AGENTS
            ;;
        *)
            echo "### Available Agents"
            echo "- See \`.claude/agents/\` for full specialist catalog"
            ;;
    esac
}

RELEVANT_AGENTS=$(get_relevant_agents "$CURRENT_PHASE")

# Determine related features (dependencies)
RELATED_FEATURES=""
if [ -f "$SPEC_FILE" ]; then
    # Look for "Depends on" or "Builds on" in spec
    RELATED_FEATURES=$(grep -E '(Depends on|Builds on|Blocks|Related)' "$SPEC_FILE" 2>/dev/null | head -3 || echo "")
fi

# Generate CLAUDE.md
LAST_UPDATED=$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')

cat > "$CLAUDE_MD_FILE" <<CLAUDE_MD
# Feature Context: $FEATURE_NAME

**Last Updated**: $LAST_UPDATED

## Current Phase
**Phase**: $CURRENT_PHASE
**Status**: $STATUS
**Progress**: $TASK_PROGRESS

## Recent Progress (from NOTES.md)
$RECENT_PROGRESS

**Next**: $NEXT_TASK

## Key Artifacts
- \`spec.md\` - Feature requirements and acceptance criteria
- \`plan.md\` - Technical design and architecture approach
- \`tasks.md\` - Task breakdown with progress tracking
- \`NOTES.md\` - Complete implementation journal with detailed notes
- \`state.yaml\` - Machine-readable workflow state

$(if [ -n "$GITHUB_ISSUE" ]; then
    echo "**GitHub Issue**: #$GITHUB_ISSUE"
fi)

## Relevant Specialists for This Feature

$RELEVANT_AGENTS

## Quick Commands
- **Resume work**: \`/feature continue\`
- **Check status**: \`/help\`
- **Deploy**: \`/ship\`
- **Health check**: Run health-check script to detect stale docs

$(if [ -n "$RELATED_FEATURES" ]; then
    echo "## Related Features"
    echo "$RELATED_FEATURES"
fi)

## Navigation
- Project overview: \`docs/project/CLAUDE.md\` (if exists)
- Root workflow guide: \`CLAUDE.md\`
- Architecture docs: \`docs/project/system-architecture.md\`

---

<!--
This file aggregates current STATUS and CONTEXT from workflow artifacts.
It is NOT behavioral instructions - those are in the root CLAUDE.md.
Auto-regenerated by: .spec-flow/scripts/bash/generate-feature-claude-md.sh
-->

*Regenerate with:* \`.spec-flow/scripts/bash/generate-feature-claude-md.sh $FEATURE_DIR\`
CLAUDE_MD

# Quality gate: warn if output exceeds threshold
LINE_COUNT=$(wc -l < "$CLAUDE_MD_FILE" 2>/dev/null || echo "0")
if [ "$LINE_COUNT" -gt 200 ]; then
    log_warn "Generated CLAUDE.md exceeds 200 lines ($LINE_COUNT). Consider simplifying."
elif [ "$LINE_COUNT" -gt 100 ]; then
    log_info "Generated CLAUDE.md has $LINE_COUNT lines (threshold: 100 warn, 200 max)"
fi

if [ "$JSON_OUT" = false ]; then
    log_info "Generated $CLAUDE_MD_FILE"
    log_info "Phase: $CURRENT_PHASE | Progress: $TASK_PROGRESS"
fi

if [ "$JSON_OUT" = true ]; then
    echo "{\"success\": true, \"file\": \"$CLAUDE_MD_FILE\", \"phase\": \"$CURRENT_PHASE\", \"progress\": \"$TASK_PROGRESS\"}"
fi
