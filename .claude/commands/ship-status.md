# /ship-status - Deployment Status Visualization

**Purpose**: Display comprehensive deployment workflow status, showing current phase, completed tasks, quality gates, and deployment information.

**Usage**: `/ship-status` or `/ship status`

**When to Use**:
- Check current deployment progress
- See which phases are complete
- View quality gate results
- Check deployment URLs and IDs
- Determine next steps

---

## Status Display

```bash
#!/bin/bash
set -e

# Source state management functions
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../../.spec-flow/scripts/bash/workflow-state.sh"
else
  source .spec-flow/scripts/bash/workflow-state.sh
fi

# Find most recent feature directory
FEATURE_DIR=$(ls -td specs/*/ 2>/dev/null | head -1)

if [ -z "$FEATURE_DIR" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📊 Deployment Status"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "❌ No features found"
  echo ""
  echo "Create a new feature with: /spec-flow \"Feature Name\""
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

STATE_FILE="$FEATURE_DIR/workflow-state.yaml"

# Auto-migrate from JSON if needed
if [ ! -f "$STATE_FILE" ] && [ -f "$FEATURE_DIR/workflow-state.json" ]; then
  echo "🔄 Migrating workflow state to YAML..." >&2
  yq eval -P "$FEATURE_DIR/workflow-state.json" > "$STATE_FILE"
fi

if [ ! -f "$STATE_FILE" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📊 Deployment Status"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "⚠️  No workflow state found for: $FEATURE_DIR"
  echo ""
  echo "This feature may have been created before state tracking was implemented."
  echo "Create a new feature with: /spec-flow \"Feature Name\""
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

# Load state
FEATURE_SLUG=$(yq eval '.feature.slug' "$STATE_FILE")
FEATURE_TITLE=$(yq eval '.feature.title' "$STATE_FILE")
CREATED=$(yq eval '.feature.created' "$STATE_FILE")
LAST_UPDATED=$(yq eval '.feature.last_updated' "$STATE_FILE")
DEPLOYMENT_MODEL=$(yq eval '.deployment_model' "$STATE_FILE")
CURRENT_PHASE=$(yq eval '.workflow.phase' "$STATE_FILE")
WORKFLOW_STATUS=$(yq eval '.workflow.status' "$STATE_FILE")

# Display header
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Deployment Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Feature information
echo "📦 Feature Information"
echo "─────────────────────────────────────────────"
echo "Title: $FEATURE_TITLE"
echo "Slug: $FEATURE_SLUG"
echo "Created: $CREATED"
echo "Updated: $LAST_UPDATED"
echo ""

# Deployment model
echo "🎯 Deployment Model"
echo "─────────────────────────────────────────────"
echo "Model: $DEPLOYMENT_MODEL"

case "$DEPLOYMENT_MODEL" in
  staging-prod)
    echo "Path: Staging → Validation → Production"
    ;;
  direct-prod)
    echo "Path: Direct to Production"
    ;;
  local-only)
    echo "Path: Local Build Only"
    ;;
esac

echo ""

# Current status
echo "📍 Current Status"
echo "─────────────────────────────────────────────"
echo "Phase: $CURRENT_PHASE"

case "$WORKFLOW_STATUS" in
  in_progress)
    echo "Status: 🔄 IN PROGRESS"
    ;;
  completed)
    echo "Status: ✅ COMPLETED"
    ;;
  failed)
    echo "Status: ❌ FAILED"
    ;;
  pending)
    echo "Status: ⏸️  PENDING"
    ;;
  *)
    echo "Status: $WORKFLOW_STATUS"
    ;;
esac

echo ""

# Completed phases
echo "✅ Completed Phases"
echo "─────────────────────────────────────────────"

COMPLETED_PHASES=$(yq eval '.workflow.completed_phases[]' "$STATE_FILE" 2>/dev/null)

if [ -z "$COMPLETED_PHASES" ]; then
  echo "No phases completed yet"
else
  echo "$COMPLETED_PHASES" | while read -r phase; do
    echo "  ✅ $phase"
  done
fi

echo ""

# Failed phases (if any)
FAILED_PHASES=$(yq eval '.workflow.failed_phases[]' "$STATE_FILE" 2>/dev/null)

if [ -n "$FAILED_PHASES" ]; then
  echo "❌ Failed Phases"
  echo "─────────────────────────────────────────────"
  echo "$FAILED_PHASES" | while read -r phase; do
    echo "  ❌ $phase"
  done
  echo ""
fi

# Manual gates
MANUAL_GATES=$(yq eval '.workflow.manual_gates | to_entries | .[] | .key + ":" + .value.status' "$STATE_FILE" 2>/dev/null)

if [ -n "$MANUAL_GATES" ]; then
  echo "🚪 Manual Gates"
  echo "─────────────────────────────────────────────"

  echo "$MANUAL_GATES" | while IFS=: read -r gate status; do
    case "$status" in
      pending)
        echo "  ⏸️  $gate: PENDING"
        ;;
      approved)
        echo "  ✅ $gate: APPROVED"
        ;;
      rejected)
        echo "  ❌ $gate: REJECTED"
        ;;
      *)
        echo "  ❓ $gate: $status"
        ;;
    esac
  done

  echo ""
fi

# Quality gates
QUALITY_GATES=$(yq eval '.quality_gates | to_entries | .[] | .key + ":" + (.value.passed | tostring)' "$STATE_FILE" 2>/dev/null)

if [ -n "$QUALITY_GATES" ]; then
  echo "🔒 Quality Gates"
  echo "─────────────────────────────────────────────"

  echo "$QUALITY_GATES" | while IFS=: read -r gate passed; do
    if [ "$passed" = "true" ]; then
      echo "  ✅ $gate: PASSED"
    else
      echo "  ❌ $gate: FAILED"
    fi
  done

  echo ""
fi

# Deployment information
echo "🌐 Deployment Information"
echo "─────────────────────────────────────────────"

# Staging
STAGING_DEPLOYED=$(yq eval '.deployment.staging.deployed' "$STATE_FILE" 2>/dev/null)

if [ "$STAGING_DEPLOYED" = "true" ]; then
  echo "Staging:"

  STAGING_URL=$(yq eval '.deployment.staging.url // "Not recorded"' "$STATE_FILE")
  STAGING_TIMESTAMP=$(yq eval '.deployment.staging.timestamp // "Unknown"' "$STATE_FILE")
  STAGING_COMMIT=$(yq eval '.deployment.staging.commit_sha // "Unknown"' "$STATE_FILE")

  echo "  URL: $STAGING_URL"
  echo "  Deployed: $STAGING_TIMESTAMP"
  echo "  Commit: ${STAGING_COMMIT:0:7}"

  # Deployment IDs
  STAGING_IDS=$(yq eval '.deployment.staging.deployment_ids | to_entries | .[] | .key + ":" + .value' "$STATE_FILE" 2>/dev/null)

  if [ -n "$STAGING_IDS" ]; then
    echo "  IDs:"
    echo "$STAGING_IDS" | while IFS=: read -r service id; do
      if [ -n "$id" ]; then
        echo "    - $service: $id"
      fi
    done
  fi

  echo ""
fi

# Production
PROD_DEPLOYED=$(yq eval '.deployment.production.deployed' "$STATE_FILE" 2>/dev/null)

if [ "$PROD_DEPLOYED" = "true" ]; then
  echo "Production:"

  PROD_URL=$(yq eval '.deployment.production.url // "Not recorded"' "$STATE_FILE")
  PROD_TIMESTAMP=$(yq eval '.deployment.production.timestamp // "Unknown"' "$STATE_FILE")
  PROD_COMMIT=$(yq eval '.deployment.production.commit_sha // "Unknown"' "$STATE_FILE")
  PROD_VERSION=$(yq eval '.deployment.production.version // "Unknown"' "$STATE_FILE")

  echo "  URL: $PROD_URL"
  echo "  Deployed: $PROD_TIMESTAMP"
  echo "  Commit: ${PROD_COMMIT:0:7}"

  if [ "$PROD_VERSION" != "Unknown" ] && [ "$PROD_VERSION" != "null" ]; then
    echo "  Version: $PROD_VERSION"
  fi

  # Deployment IDs
  PROD_IDS=$(yq eval '.deployment.production.deployment_ids | to_entries | .[] | .key + ":" + .value' "$STATE_FILE" 2>/dev/null)

  if [ -n "$PROD_IDS" ]; then
    echo "  IDs:"
    echo "$PROD_IDS" | while IFS=: read -r service id; do
      if [ -n "$id" ]; then
        echo "    - $service: $id"
      fi
    done
  fi

  echo ""
fi

if [ "$STAGING_DEPLOYED" != "true" ] && [ "$PROD_DEPLOYED" != "true" ]; then
  echo "No deployments yet"
  echo ""
fi

# Next steps
echo "➡️  Next Steps"
echo "─────────────────────────────────────────────"

case "$WORKFLOW_STATUS" in
  completed)
    if [ "$CURRENT_PHASE" = "ship:finalize" ] || [ "$CURRENT_PHASE" = "finalize" ]; then
      echo "✅ Workflow complete! Feature successfully shipped."
      echo ""
      echo "Monitor production for issues:"
      echo "  - Check error logs"
      echo "  - Monitor performance metrics"
      echo "  - Review user feedback"
    else
      NEXT_PHASE=$(get_next_phase "$FEATURE_DIR")

      if [ -n "$NEXT_PHASE" ]; then
        echo "Ready for next phase: $NEXT_PHASE"
        echo ""
        echo "Continue workflow:"
        echo "  /ship continue"
      else
        echo "✅ All phases complete!"
      fi
    fi
    ;;

  in_progress)
    echo "Current phase in progress: $CURRENT_PHASE"
    echo ""
    echo "Wait for current phase to complete, then:"
    echo "  /ship continue"
    ;;

  failed)
    echo "❌ Workflow failed at: $CURRENT_PHASE"
    echo ""
    echo "Check logs in: $FEATURE_DIR"
    echo ""
    echo "After fixing issues, retry:"
    echo "  /ship continue"
    ;;

  pending)
    # Check if it's a manual gate
    PREVIEW_STATUS=$(yq eval '.workflow.manual_gates.preview.status // "none"' "$STATE_FILE")
    VALIDATION_STATUS=$(yq eval '.workflow.manual_gates."validate-staging".status // "none"' "$STATE_FILE")

    if [ "$PREVIEW_STATUS" = "pending" ]; then
      echo "⏸️  Waiting for preview approval"
      echo ""
      echo "Complete manual testing, then:"
      echo "  /ship continue"
    elif [ "$VALIDATION_STATUS" = "pending" ]; then
      echo "⏸️  Waiting for staging validation"
      echo ""
      echo "Run staging validation:"
      echo "  /validate-staging"
      echo ""
      echo "Then continue:"
      echo "  /ship continue"
    else
      echo "Ready to continue"
      echo ""
      echo "Resume workflow:"
      echo "  /ship continue"
    fi
    ;;

  *)
    echo "Status: $WORKFLOW_STATUS"
    echo ""
    echo "Resume workflow:"
    echo "  /ship continue"
    ;;
esac

echo ""

# Footer with helpful commands
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 Helpful Commands"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "/ship continue    - Resume workflow from last phase"
echo "/ship status      - Show this status display"
echo "/validate-staging - Validate staging environment"
echo "/preview          - Start local preview for testing"
echo ""
echo "📁 Feature directory: $FEATURE_DIR"
echo "📄 State file: $STATE_FILE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
```

---

## Status Output Examples

### Example 1: Feature in Progress

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Deployment Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Feature Information
─────────────────────────────────────────────
Title: User Authentication System
Slug: 001-user-auth
Created: 2025-10-16T12:00:00Z
Updated: 2025-10-16T14:30:00Z

🎯 Deployment Model
─────────────────────────────────────────────
Model: staging-prod
Path: Staging → Validation → Production

📍 Current Status
─────────────────────────────────────────────
Phase: ship:optimize
Status: 🔄 IN PROGRESS

✅ Completed Phases
─────────────────────────────────────────────
  ✅ spec-flow
  ✅ clarify
  ✅ plan
  ✅ tasks
  ✅ analyze
  ✅ implement

🔒 Quality Gates
─────────────────────────────────────────────
  ✅ pre_flight: PASSED

🌐 Deployment Information
─────────────────────────────────────────────
No deployments yet

➡️  Next Steps
─────────────────────────────────────────────
Current phase in progress: ship:optimize

Wait for current phase to complete, then:
  /ship continue

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Example 2: Manual Gate Pending

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Deployment Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Feature Information
─────────────────────────────────────────────
Title: User Authentication System
Slug: 001-user-auth
Created: 2025-10-16T12:00:00Z
Updated: 2025-10-16T15:45:00Z

🎯 Deployment Model
─────────────────────────────────────────────
Model: staging-prod
Path: Staging → Validation → Production

📍 Current Status
─────────────────────────────────────────────
Phase: ship:preview
Status: ⏸️  PENDING

✅ Completed Phases
─────────────────────────────────────────────
  ✅ spec-flow
  ✅ clarify
  ✅ plan
  ✅ tasks
  ✅ analyze
  ✅ implement
  ✅ ship:optimize
  ✅ ship:preview

🚪 Manual Gates
─────────────────────────────────────────────
  ⏸️  preview: PENDING

🔒 Quality Gates
─────────────────────────────────────────────
  ✅ pre_flight: PASSED
  ✅ code_review: PASSED

🌐 Deployment Information
─────────────────────────────────────────────
No deployments yet

➡️  Next Steps
─────────────────────────────────────────────
⏸️  Waiting for preview approval

Complete manual testing, then:
  /ship continue

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Example 3: Deployed to Staging

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Deployment Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Feature Information
─────────────────────────────────────────────
Title: User Authentication System
Slug: 001-user-auth
Created: 2025-10-16T12:00:00Z
Updated: 2025-10-16T16:30:00Z

🎯 Deployment Model
─────────────────────────────────────────────
Model: staging-prod
Path: Staging → Validation → Production

📍 Current Status
─────────────────────────────────────────────
Phase: ship:validate-staging
Status: ⏸️  PENDING

✅ Completed Phases
─────────────────────────────────────────────
  ✅ spec-flow
  ✅ clarify
  ✅ plan
  ✅ tasks
  ✅ analyze
  ✅ implement
  ✅ ship:optimize
  ✅ ship:preview
  ✅ ship:phase-1-ship

🚪 Manual Gates
─────────────────────────────────────────────
  ✅ preview: APPROVED
  ⏸️  validate-staging: PENDING

🔒 Quality Gates
─────────────────────────────────────────────
  ✅ pre_flight: PASSED
  ✅ code_review: PASSED

🌐 Deployment Information
─────────────────────────────────────────────
Staging:
  URL: https://staging.myapp.com
  Deployed: 2025-10-16T16:15:00Z
  Commit: abc1234
  IDs:
    - marketing: marketing-xyz789.vercel.app
    - app: app-def456.vercel.app
    - api: ghcr.io/org/api:sha123abc

➡️  Next Steps
─────────────────────────────────────────────
⏸️  Waiting for staging validation

Run staging validation:
  /validate-staging

Then continue:
  /ship continue

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Example 4: Complete Deployment

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Deployment Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Feature Information
─────────────────────────────────────────────
Title: User Authentication System
Slug: 001-user-auth
Created: 2025-10-16T12:00:00Z
Updated: 2025-10-16T17:00:00Z

🎯 Deployment Model
─────────────────────────────────────────────
Model: staging-prod
Path: Staging → Validation → Production

📍 Current Status
─────────────────────────────────────────────
Phase: ship:finalize
Status: ✅ COMPLETED

✅ Completed Phases
─────────────────────────────────────────────
  ✅ spec-flow
  ✅ clarify
  ✅ plan
  ✅ tasks
  ✅ analyze
  ✅ implement
  ✅ ship:optimize
  ✅ ship:preview
  ✅ ship:phase-1-ship
  ✅ ship:validate-staging
  ✅ ship:phase-2-ship
  ✅ ship:finalize

🚪 Manual Gates
─────────────────────────────────────────────
  ✅ preview: APPROVED
  ✅ validate-staging: APPROVED

🔒 Quality Gates
─────────────────────────────────────────────
  ✅ pre_flight: PASSED
  ✅ code_review: PASSED
  ✅ rollback_capability: PASSED

🌐 Deployment Information
─────────────────────────────────────────────
Staging:
  URL: https://staging.myapp.com
  Deployed: 2025-10-16T16:15:00Z
  Commit: abc1234
  IDs:
    - marketing: marketing-xyz789.vercel.app
    - app: app-def456.vercel.app
    - api: ghcr.io/org/api:sha123abc

Production:
  URL: https://myapp.com
  Deployed: 2025-10-16T16:50:00Z
  Commit: abc1234
  Version: 1.2.0
  IDs:
    - marketing: marketing-prod123.vercel.app
    - app: app-prod456.vercel.app
    - api: ghcr.io/org/api:sha123abc

➡️  Next Steps
─────────────────────────────────────────────
✅ Workflow complete! Feature successfully shipped.

Monitor production for issues:
  - Check error logs
  - Monitor performance metrics
  - Review user feedback

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Integration with /ship

The `/ship` command calls this status display via the `status` argument:

```bash
if [ "$1" = "status" ]; then
  /ship-status
  exit 0
fi
```

---

## Notes

- **Real-time**: Status reflects current workflow state
- **Comprehensive**: Shows all phases, gates, and deployments
- **Actionable**: Provides clear next steps
- **Context-aware**: Adapts display based on deployment model
- **Helpful**: Includes command suggestions
- **Safe**: No state modifications (read-only)

This command provides essential visibility into the deployment workflow without modifying any state.
