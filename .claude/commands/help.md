---
description: Show contextual help for current workflow state and next steps
---

Display your current workflow state and recommended next steps based on where you are in the Spec-Flow workflow.

## Usage

```bash
/help          # Show current workflow state and next steps
/help verbose  # Show detailed state information
```

## Overview

The `/help` command analyzes your current context and provides:
- Where you are in the workflow
- What phases you've completed
- What's blocking you (if anything)
- What to do next

Works in multiple contexts:
1. **Outside feature** - Show available commands to start workflow
2. **In feature** - Show current phase and next steps
3. **At manual gate** - Show gate requirements and approval command
4. **Blocked** - Show errors and recovery options
5. **Complete** - Show summary and next feature options

## Step 1: Detect Context

First, determine where the user is in the workflow:

```bash
# Find most recent feature directory
FEATURE_DIR=$(ls -td specs/*/ 2>/dev/null | head -1)

if [ -z "$FEATURE_DIR" ]; then
  CONTEXT="no_feature"
else
  CONTEXT="in_feature"
  FEATURE_DIR="${FEATURE_DIR%/}"  # Remove trailing slash
  STATE_FILE="$FEATURE_DIR/workflow-state.yaml"

  # Auto-migrate from JSON if needed
  if [ ! -f "$STATE_FILE" ] && [ -f "$FEATURE_DIR/workflow-state.json" ]; then
    if command -v yq &> /dev/null; then
      yq eval -P "$FEATURE_DIR/workflow-state.json" > "$STATE_FILE"
      echo "Migrated workflow-state.json to YAML format"
    fi
  fi

  # Check if state file exists
  if [ ! -f "$STATE_FILE" ]; then
    CONTEXT="no_state"
  fi
fi

# Check for verbose mode
VERBOSE_MODE=false
if [[ "${1:-}" == "verbose" ]] || [[ "${1:-}" == "detail" ]]; then
  VERBOSE_MODE=true
fi
```

## Step 2: Check Prerequisites

```bash
# Check if yq is available (required for reading YAML)
if [ "$CONTEXT" != "no_feature" ] && ! command -v yq &> /dev/null; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  yq not installed"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "The /help command requires yq to read workflow state."
  echo ""
  echo "Install yq:"
  echo "  macOS:   brew install yq"
  echo "  Linux:   wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
  echo "  Windows: choco install yq"
  echo ""
  echo "Then run /help again."
  exit 1
fi
```

## Step 3: Load Workflow State (If In Feature)

```bash
if [ "$CONTEXT" = "in_feature" ]; then
  # Read state using yq
  CURRENT_PHASE=$(yq eval '.workflow.phase' "$STATE_FILE" 2>/dev/null || echo "unknown")
  WORKFLOW_STATUS=$(yq eval '.workflow.status' "$STATE_FILE" 2>/dev/null || echo "unknown")
  DEPLOYMENT_MODEL=$(yq eval '.deployment_model' "$STATE_FILE" 2>/dev/null || echo "unknown")
  FEATURE_SLUG=$(yq eval '.feature.slug' "$STATE_FILE" 2>/dev/null || echo "unknown")
  BRANCH_NAME=$(yq eval '.feature.branch_name' "$STATE_FILE" 2>/dev/null || echo "unknown")

  # Count completed phases
  COMPLETED_PHASES=$(yq eval '.workflow.completed_phases[]' "$STATE_FILE" 2>/dev/null)
  COMPLETED_COUNT=$(echo "$COMPLETED_PHASES" | grep -v '^$' | wc -l | tr -d ' ')

  # Get failed phases
  FAILED_PHASES=$(yq eval '.workflow.failed_phases[]' "$STATE_FILE" 2>/dev/null)

  # Check manual gates
  PREVIEW_GATE=$(yq eval '.workflow.manual_gates.preview.status' "$STATE_FILE" 2>/dev/null || echo "null")
  STAGING_GATE=$(yq eval '.workflow.manual_gates.validate_staging.status' "$STATE_FILE" 2>/dev/null || echo "null")

  # Determine total phases based on deployment model
  case "$DEPLOYMENT_MODEL" in
    "staging-prod")
      TOTAL_PHASES=11
      ;;
    "direct-prod")
      TOTAL_PHASES=8
      ;;
    "local-only")
      TOTAL_PHASES=8
      ;;
    *)
      TOTAL_PHASES=10
      ;;
  esac
fi
```

## Step 4: Render Context-Specific Output

### Context 1: No Feature (Outside Workflow)

```bash
if [ "$CONTEXT" = "no_feature" ]; then
  cat << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧭 Spec-Flow Workflow - Getting Started
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You're not currently in a feature workflow.

📋 Available Commands:

**Start a new feature:**
  /feature "Feature description"      Full workflow (2-8 hours)
  /feature next                       Start highest priority roadmap item
  /quick "Bug fix description"        Quick fix (<30 min, <100 LOC)

**Manage roadmap:**
  /roadmap add "Feature description"  Add feature to backlog
  /roadmap brainstorm                 Generate feature ideas
  /roadmap prioritize                 Sort features by ICE score

**Project setup:**
  /init-project                       Create project design docs (one-time)

**Continue existing feature:**
  /feature continue                   Resume last feature workflow

📚 Documentation:
  - README.md             Quick start guide
  - docs/architecture.md  Workflow structure
  - docs/commands.md      Command reference
  - CLAUDE.md             Full workflow guide

💡 First time? Run /init-project to create comprehensive project documentation.
EOF
  exit 0
fi
```

### Context 2: No State File (Corrupted/Missing)

```bash
if [ "$CONTEXT" = "no_state" ]; then
  cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Workflow State Not Found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature directory detected: $FEATURE_DIR/
But workflow-state.yaml is missing or corrupted.

**Possible causes:**
1. State file was deleted
2. Feature created outside /feature command
3. State file corrupted

**Recovery options:**

1. **Start fresh:**
   If feature not started yet:
   - Delete $FEATURE_DIR/ directory
   - Run: /feature "Feature description"

2. **Manual recovery:**
   - Copy template: .spec-flow/templates/workflow-state.yaml
   - Edit manually with feature details
   - Continue workflow with /feature continue

3. **Get help:**
   Ask for manual recovery steps

💡 This usually happens if state file was manually deleted.
   The workflow needs this file to track progress.
EOF
  exit 0
fi
```

### Context 3: Blocked by Errors

```bash
# Check if workflow has failed phases or is in failed status
if [ "$WORKFLOW_STATUS" = "failed" ] || [ -n "$FAILED_PHASES" ]; then
  cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Workflow Blocked
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: $FEATURE_SLUG
Phase: $CURRENT_PHASE (failed)

EOF

  if [ -n "$FAILED_PHASES" ]; then
    echo "**Failed Phases:**"
    echo "$FAILED_PHASES" | while read -r phase; do
      if [ -n "$phase" ]; then
        echo "❌ $phase"
      fi
    done
    echo ""
  fi

  if [ -f "$FEATURE_DIR/error-log.md" ]; then
    echo "**Recent Errors:**"
    tail -20 "$FEATURE_DIR/error-log.md" | head -10
    echo ""
    echo "View full log: cat $FEATURE_DIR/error-log.md"
    echo ""
  fi

  cat << EOF
**Recovery Options:**

1. **Fix issues manually:**
   - Review error log: cat $FEATURE_DIR/error-log.md
   - Fix each blocker
   - Resume: /feature continue

2. **Get help debugging:**
   - Analyze errors: /debug
   - The debug agent will triage and suggest fixes

3. **View context:**
   - Tasks: cat $FEATURE_DIR/tasks.md
   - Plan: cat $FEATURE_DIR/plan.md
   - Spec: cat $FEATURE_DIR/spec.md

💡 After fixing issues, run: /feature continue
EOF
  exit 0
fi
```

### Context 4: At Manual Gate

```bash
# Check if at manual gate (preview or staging validation)
if [ "$PREVIEW_GATE" = "pending" ] || [ "$STAGING_GATE" = "pending" ]; then

  if [ "$PREVIEW_GATE" = "pending" ]; then
    GATE_NAME="Preview Testing"
    GATE_PHASE="ship:preview"
  else
    GATE_NAME="Staging Validation"
    GATE_PHASE="ship:validate-staging"
  fi

  cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛑 MANUAL GATE: $GATE_NAME
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: $FEATURE_SLUG
Phase: $GATE_PHASE (waiting for approval)

EOF

  if [ "$PREVIEW_GATE" = "pending" ]; then
    cat << 'EOF'
The local dev server should be running. Please complete:

**Testing Checklist:**
☐ 1. Test all feature functionality
☐ 2. Verify UI/UX across screen sizes
☐ 3. Test accessibility (keyboard, screen readers)
☐ 4. Test error states and edge cases
☐ 5. Check performance (no lag)

**Server:**
  Local: http://localhost:3000
  Status: npm run dev (should be running)

**After Testing:**
  ✅ Approve: /ship continue
  ❌ Issues: /debug (fix issues first)
  🛑 Abort:   /ship abort

**What happens next:**
  → Deploy to staging environment
  → Run automated validation
  → Manual staging validation gate
  → Deploy to production
EOF
  else
    cat << EOF
Staging deployment is live. Please complete:

**Testing Checklist:**
☐ 1. Test all feature functionality in staging
☐ 2. Verify data integrity and migrations
☐ 3. Test integrations with external services
☐ 4. Check monitoring and logs
☐ 5. Verify rollback capability

**Staging Environment:**
EOF
    STAGING_URL=$(yq eval '.deployment.staging.url' "$STATE_FILE" 2>/dev/null || echo "unknown")
    echo "  URL: $STAGING_URL"
    echo ""
    cat << 'EOF'

**After Testing:**
  ✅ Approve: /ship continue
  ❌ Issues: /debug (fix issues first)
  🛑 Rollback: /ship rollback

**What happens next:**
  → Deploy to production
  → Create release version
  → Update roadmap to "shipped"
EOF
  fi
  exit 0
fi
```

### Context 5: Feature Complete

```bash
# Check if all phases completed
if [ "$WORKFLOW_STATUS" = "completed" ] && echo "$COMPLETED_PHASES" | grep -q "finalize"; then

  PRODUCTION_VERSION=$(yq eval '.deployment.production.version' "$STATE_FILE" 2>/dev/null || echo "unknown")
  PRODUCTION_URL=$(yq eval '.deployment.production.url' "$STATE_FILE" 2>/dev/null || echo "unknown")
  ROADMAP_STATUS=$(yq eval '.feature.roadmap_status' "$STATE_FILE" 2>/dev/null || echo "unknown")

  cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Feature Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: $FEATURE_SLUG
Version: $PRODUCTION_VERSION
Roadmap: $ROADMAP_STATUS

✅ All phases completed
EOF

  if [ "$PRODUCTION_URL" != "unknown" ] && [ "$PRODUCTION_URL" != "null" ]; then
    echo "📦 Production URL: $PRODUCTION_URL"
  fi

  echo ""
  echo "**Artifacts:**"

  if [ -f "$FEATURE_DIR/spec.md" ]; then
    echo "📄 Spec:          $FEATURE_DIR/spec.md"
  fi
  if [ -f "$FEATURE_DIR/plan.md" ]; then
    echo "📄 Plan:          $FEATURE_DIR/plan.md"
  fi
  if [ -f "$FEATURE_DIR/tasks.md" ]; then
    echo "📄 Tasks:         $FEATURE_DIR/tasks.md"
  fi
  if [ -f "$FEATURE_DIR/ship-summary.md" ]; then
    echo "📄 Ship Report:   $FEATURE_DIR/ship-summary.md"
  fi
  if [ -f "$FEATURE_DIR/release-notes.md" ]; then
    echo "📄 Release Notes: $FEATURE_DIR/release-notes.md"
  fi

  cat << 'EOF'

**Next Steps:**
🚀 Start new feature: /feature "description"
🎯 Pick from roadmap: /feature next
📋 View roadmap: /roadmap
🔍 Check metrics: /metrics

💡 Great work! The feature is shipped and documented.
EOF
  exit 0
fi
```

### Context 6: In Feature - Active Phase

```bash
# Default: Show current progress
cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧭 Current Workflow State
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: $FEATURE_SLUG
Branch: $BRANCH_NAME
Directory: $FEATURE_DIR/

📍 Current Phase: $CURRENT_PHASE ($WORKFLOW_STATUS)
✅ Completed: $COMPLETED_COUNT/$TOTAL_PHASES phases
📦 Deployment Model: $DEPLOYMENT_MODEL

**Progress:**
EOF

# Helper function to get phase emoji
get_phase_status() {
  local phase_name="$1"

  # Check if failed
  if echo "$FAILED_PHASES" | grep -q "^$phase_name$"; then
    echo "❌"
    return
  fi

  # Check if completed
  if echo "$COMPLETED_PHASES" | grep -q "^$phase_name$"; then
    echo "✅"
    return
  fi

  # Check if current
  if [ "$CURRENT_PHASE" = "$phase_name" ] || [[ "$CURRENT_PHASE" == *"$phase_name"* ]]; then
    echo "⏳"
    return
  fi

  # Otherwise pending
  echo "⬜"
}

# Show phases based on deployment model
echo "$(get_phase_status 'spec-flow') spec-flow     Specification"
echo "$(get_phase_status 'plan') plan          Implementation plan"
echo "$(get_phase_status 'tasks') tasks         Task breakdown"
echo "$(get_phase_status 'analyze') analyze       Cross-artifact validation"
echo "$(get_phase_status 'implement') implement     Execute tasks"
echo "$(get_phase_status 'optimize') optimize      Code review & quality"
echo "$(get_phase_status 'preview') preview       Manual testing gate"

# Deployment-specific phases
case "$DEPLOYMENT_MODEL" in
  "staging-prod")
    echo "$(get_phase_status 'ship-staging') ship-staging  Deploy to staging"
    echo "$(get_phase_status 'validate') validate      Staging validation gate"
    echo "$(get_phase_status 'ship-prod') ship-prod    Deploy to production"
    ;;
  "direct-prod")
    echo "$(get_phase_status 'deploy-prod') deploy-prod   Deploy to production"
    ;;
  "local-only")
    echo "$(get_phase_status 'build-local') build-local   Local build validation"
    ;;
esac

echo "$(get_phase_status 'finalize') finalize      Documentation & cleanup"

echo ""
echo "**Next Steps:**"

# Provide context-specific recommendations
case "$CURRENT_PHASE" in
  *"spec"*|*"clarify"*|*"plan"*|*"tasks"*|*"analyze"*)
    echo "1. Continue workflow: /feature continue"
    echo "2. View spec: cat $FEATURE_DIR/spec.md"
    if [ "$CURRENT_PHASE" = "tasks" ] || [ "$CURRENT_PHASE" = "analyze" ]; then
      echo "3. View plan: cat $FEATURE_DIR/plan.md"
    fi
    ;;
  *"implement"*)
    echo "1. Continue implementation: /feature continue"
    echo "2. View tasks: cat $FEATURE_DIR/tasks.md"
    echo "3. Check progress: cat $FEATURE_DIR/NOTES.md"
    echo "4. Debug issues: /debug"
    ;;
  *"optimize"*)
    echo "1. Continue optimization: /feature continue"
    echo "2. View code review: cat $FEATURE_DIR/code-review-report.md"
    echo "3. Fix issues: /debug"
    ;;
  *"preview"*)
    echo "1. Test locally: npm run dev"
    echo "2. After testing: /ship continue"
    echo "3. If issues: /debug"
    ;;
  *"ship"*|*"deploy"*|*"build"*)
    echo "1. Continue deployment: /ship continue"
    echo "2. Check status: /deploy-status"
    echo "3. If issues: /fix-ci"
    ;;
  *"finalize"*)
    echo "1. Complete finalization: /feature continue"
    echo "2. View ship report: cat $FEATURE_DIR/ship-summary.md"
    ;;
  *)
    echo "1. Continue workflow: /feature continue"
    echo "2. View documentation: cat $FEATURE_DIR/spec.md"
    ;;
esac

echo ""
echo "**Workflow Path** ($DEPLOYMENT_MODEL):"
case "$DEPLOYMENT_MODEL" in
  "staging-prod")
    echo "implement → optimize → preview → ship-staging → validate → ship-prod → finalize"
    ;;
  "direct-prod")
    echo "implement → optimize → preview → deploy-prod → finalize"
    ;;
  "local-only")
    echo "implement → optimize → preview → build-local → finalize"
    ;;
  *)
    echo "implement → optimize → preview → ship → finalize"
    ;;
esac

echo ""
echo "💡 Tip: The workflow auto-continues after each phase completes."
echo "   Manual gates will pause for your approval."

# If verbose mode, show additional details
if [ "$VERBOSE_MODE" = true ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📊 Detailed State Information"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Show quality gates
  echo "**Quality Gates:**"
  PRE_FLIGHT=$(yq eval '.quality_gates.pre_flight.passed' "$STATE_FILE" 2>/dev/null || echo "null")
  CODE_REVIEW=$(yq eval '.quality_gates.code_review.passed' "$STATE_FILE" 2>/dev/null || echo "null")
  ROLLBACK=$(yq eval '.quality_gates.rollback_capability.passed' "$STATE_FILE" 2>/dev/null || echo "null")

  if [ "$PRE_FLIGHT" != "null" ]; then
    if [ "$PRE_FLIGHT" = "true" ]; then
      echo "✅ Pre-flight checks: passed"
    else
      echo "❌ Pre-flight checks: failed"
    fi
  fi

  if [ "$CODE_REVIEW" != "null" ]; then
    if [ "$CODE_REVIEW" = "true" ]; then
      echo "✅ Code review: passed"
    else
      echo "❌ Code review: failed"
    fi
  fi

  if [ "$ROLLBACK" != "null" ]; then
    if [ "$ROLLBACK" = "true" ]; then
      echo "✅ Rollback capability: tested"
    else
      echo "⬜ Rollback capability: not tested"
    fi
  fi

  echo ""

  # Show deployment info if available
  STAGING_DEPLOYED=$(yq eval '.deployment.staging.deployed' "$STATE_FILE" 2>/dev/null || echo "false")
  PRODUCTION_DEPLOYED=$(yq eval '.deployment.production.deployed' "$STATE_FILE" 2>/dev/null || echo "false")

  if [ "$STAGING_DEPLOYED" = "true" ] || [ "$PRODUCTION_DEPLOYED" = "true" ]; then
    echo "**Deployment Status:**"
    if [ "$STAGING_DEPLOYED" = "true" ]; then
      STAGING_URL=$(yq eval '.deployment.staging.url' "$STATE_FILE" 2>/dev/null || echo "unknown")
      echo "📦 Staging: $STAGING_URL"
    fi
    if [ "$PRODUCTION_DEPLOYED" = "true" ]; then
      PRODUCTION_URL=$(yq eval '.deployment.production.url' "$STATE_FILE" 2>/dev/null || echo "unknown")
      PRODUCTION_VERSION=$(yq eval '.deployment.production.version' "$STATE_FILE" 2>/dev/null || echo "unknown")
      echo "🚀 Production: $PRODUCTION_URL ($PRODUCTION_VERSION)"
    fi
    echo ""
  fi

  # Show GitHub issue if linked
  GITHUB_ISSUE=$(yq eval '.feature.github_issue' "$STATE_FILE" 2>/dev/null || echo "null")
  if [ "$GITHUB_ISSUE" != "null" ] && [ "$GITHUB_ISSUE" != "0" ]; then
    echo "**GitHub Integration:**"
    echo "🔗 Issue #$GITHUB_ISSUE"
    echo ""
  fi

  # Show all completed phases with check
  echo "**Completed Phases:**"
  if [ -n "$COMPLETED_PHASES" ]; then
    echo "$COMPLETED_PHASES" | while read -r phase; do
      if [ -n "$phase" ]; then
        echo "✅ $phase"
      fi
    done
  else
    echo "(none yet)"
  fi
fi
```

## Summary

The `/help` command provides contextual, actionable guidance at every stage of the workflow:

- **Detects context** automatically (no arguments needed)
- **Shows progress** with visual indicators
- **Highlights blockers** prominently when stuck
- **Suggests next command** always
- **Adapts to deployment model** (staging-prod / direct-prod / local-only)
- **Handles edge cases** (missing state, corrupted files)

Run `/help` anytime you're unsure what to do next!
