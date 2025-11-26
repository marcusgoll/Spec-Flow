# Deploy Status — Reference Documentation

**Version**: 2.0
**Updated**: 2025-11-20

This document provides comprehensive reference material for the `/deploy-status` command, including status display logic, output examples, and integration details.

---

## Table of Contents

1. [Status Display Logic](#status-display-logic)
2. [Data Extraction](#data-extraction)
3. [Output Examples](#output-examples)
4. [Integration with /ship](#integration-with-ship)
5. [Next Steps Logic](#next-steps-logic)
6. [Error Conditions](#error-conditions)

---

## Status Display Logic

The deploy-status command reads `state.yaml` and displays a comprehensive view of the deployment workflow.

### Data Structures

The status display reads these sections from state.yaml:

```yaml
feature:
  slug: "001-user-auth"
  title: "User Authentication System"
  created: "2025-10-16T12:00:00Z"
  last_updated: "2025-10-16T14:30:00Z"

deployment_model: "staging-prod" # or "direct-prod", "local-only"

workflow:
  phase: "ship:optimize"
  status: "in_progress" # or "completed", "failed", "pending"
  completed_phases:
    - spec-flow
    - clarify
    - plan
    - tasks
    - analyze
    - implement
  failed_phases: [] # List of failed phases
  manual_gates:
    preview:
      status: "pending" # or "approved", "rejected"
      timestamp: "2025-10-16T15:00:00Z"
    validate-staging:
      status: "pending"

quality_gates:
  pre_flight:
    passed: true
    timestamp: "2025-10-16T14:00:00Z"
  code_review:
    passed: true
    timestamp: "2025-10-16T14:30:00Z"

deployment:
  staging:
    deployed: true
    url: "https://staging.myapp.com"
    timestamp: "2025-10-16T16:15:00Z"
    commit_sha: "abc1234567890"
    deployment_ids:
      marketing: "marketing-xyz789.vercel.app"
      app: "app-def456.vercel.app"
      api: "ghcr.io/org/api:sha123abc"
  production:
    deployed: false
```

### Display Sections

The status display consists of 8 main sections:

1. **Feature Information**

   - Title
   - Slug
   - Created timestamp
   - Last updated timestamp

2. **Deployment Model**

   - Model type (staging-prod, direct-prod, local-only)
   - Deployment path description

3. **Current Status**

   - Current phase
   - Workflow status with emoji indicator

4. **Completed Phases**

   - List of all completed phases with checkmarks

5. **Failed Phases** (if any)

   - List of failed phases with X marks

6. **Manual Gates** (if defined)

   - Gate name and status (pending, approved, rejected)

7. **Quality Gates** (if defined)

   - Gate name and pass/fail status

8. **Deployment Information**

   - Staging deployment details (URL, timestamp, commit, IDs)
   - Production deployment details (URL, timestamp, commit, version, IDs)

9. **Next Steps**
   - Context-aware suggestions based on current status
   - Actionable commands to continue workflow

---

## Data Extraction

### Feature Information

Extract basic feature metadata:

```bash
FEATURE_SLUG=$(yq eval '.feature.slug' "$STATE_FILE")
FEATURE_TITLE=$(yq eval '.feature.title' "$STATE_FILE")
CREATED=$(yq eval '.feature.created' "$STATE_FILE")
LAST_UPDATED=$(yq eval '.feature.last_updated' "$STATE_FILE")
```

Display:

```
📦 Feature Information
─────────────────────────────────────────────
Title: User Authentication System
Slug: 001-user-auth
Created: 2025-10-16T12:00:00Z
Updated: 2025-10-16T14:30:00Z
```

### Deployment Model

Extract and interpret deployment model:

```bash
DEPLOYMENT_MODEL=$(yq eval '.deployment_model' "$STATE_FILE")

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
```

Display:

```
🎯 Deployment Model
─────────────────────────────────────────────
Model: staging-prod
Path: Staging → Validation → Production
```

### Current Status

Extract current phase and status with emoji indicators:

```bash
CURRENT_PHASE=$(yq eval '.workflow.phase' "$STATE_FILE")
WORKFLOW_STATUS=$(yq eval '.workflow.status' "$STATE_FILE")

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
esac
```

Display:

```
📍 Current Status
─────────────────────────────────────────────
Phase: ship:optimize
Status: 🔄 IN PROGRESS
```

### Completed Phases

Extract completed phases list:

```bash
COMPLETED_PHASES=$(yq eval '.workflow.completed_phases[]' "$STATE_FILE" 2>/dev/null)

if [ -z "$COMPLETED_PHASES" ]; then
  echo "No phases completed yet"
else
  echo "$COMPLETED_PHASES" | while read -r phase; do
    echo "  ✅ $phase"
  done
fi
```

Display:

```
✅ Completed Phases
─────────────────────────────────────────────
  ✅ spec-flow
  ✅ clarify
  ✅ plan
  ✅ tasks
  ✅ analyze
  ✅ implement
```

### Failed Phases

Extract failed phases (if any):

```bash
FAILED_PHASES=$(yq eval '.workflow.failed_phases[]' "$STATE_FILE" 2>/dev/null)

if [ -n "$FAILED_PHASES" ]; then
  echo "❌ Failed Phases"
  echo "─────────────────────────────────────────────"
  echo "$FAILED_PHASES" | while read -r phase; do
    echo "  ❌ $phase"
  done
fi
```

### Manual Gates

Extract manual gate statuses:

```bash
MANUAL_GATES=$(yq eval '.workflow.manual_gates | to_entries | .[] | .key + ":" + .value.status' "$STATE_FILE" 2>/dev/null)

if [ -n "$MANUAL_GATES" ]; then
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
    esac
  done
fi
```

Display:

```
🚪 Manual Gates
─────────────────────────────────────────────
  ⏸️  preview: PENDING
  ✅ validate-staging: APPROVED
```

### Quality Gates

Extract quality gate results:

```bash
QUALITY_GATES=$(yq eval '.quality_gates | to_entries | .[] | .key + ":" + (.value.passed | tostring)' "$STATE_FILE" 2>/dev/null)

if [ -n "$QUALITY_GATES" ]; then
  echo "$QUALITY_GATES" | while IFS=: read -r gate passed; do
    if [ "$passed" = "true" ]; then
      echo "  ✅ $gate: PASSED"
    else
      echo "  ❌ $gate: FAILED"
    fi
  done
fi
```

Display:

```
🔒 Quality Gates
─────────────────────────────────────────────
  ✅ pre_flight: PASSED
  ✅ code_review: PASSED
```

### Deployment Information

Extract staging and production deployment details:

```bash
# Staging
STAGING_DEPLOYED=$(yq eval '.deployment.staging.deployed' "$STATE_FILE" 2>/dev/null)

if [ "$STAGING_DEPLOYED" = "true" ]; then
  STAGING_URL=$(yq eval '.deployment.staging.url // "Not recorded"' "$STATE_FILE")
  STAGING_TIMESTAMP=$(yq eval '.deployment.staging.timestamp // "Unknown"' "$STATE_FILE")
  STAGING_COMMIT=$(yq eval '.deployment.staging.commit_sha // "Unknown"' "$STATE_FILE")

  echo "Staging:"
  echo "  URL: $STAGING_URL"
  echo "  Deployed: $STAGING_TIMESTAMP"
  echo "  Commit: ${STAGING_COMMIT:0:7}"

  # Deployment IDs
  STAGING_IDS=$(yq eval '.deployment.staging.deployment_ids | to_entries | .[] | .key + ":" + .value' "$STATE_FILE" 2>/dev/null)
  if [ -n "$STAGING_IDS" ]; then
    echo "  IDs:"
    echo "$STAGING_IDS" | while IFS=: read -r service id; do
      echo "    - $service: $id"
    done
  fi
fi

# Production (similar structure)
PROD_DEPLOYED=$(yq eval '.deployment.production.deployed' "$STATE_FILE" 2>/dev/null)

if [ "$PROD_DEPLOYED" = "true" ]; then
  # Extract production details (URL, timestamp, commit, version, IDs)
  # Display production section
fi
```

Display:

```
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
```

---

## Output Examples

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
📚 Helpful Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/ship continue    - Resume workflow from last phase
/deploy status      - Show this status display
/validate-staging - Validate staging environment
/preview          - Start local preview for testing

📁 Feature directory: specs/001-user-auth/
📄 State file: specs/001-user-auth/state.yaml

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Example 2: Manual Gate Pending (Preview)

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

The `/ship` command can invoke deploy-status via the `status` argument:

```bash
# In /ship command
if [ "$1" = "status" ]; then
  /deploy-status
  exit 0
fi
```

This allows users to check status using either:

- `/deploy-status`
- `/deploy status`
- `/ship status`

---

## Next Steps Logic

The "Next Steps" section provides context-aware guidance based on workflow status:

### Status: completed

```bash
if [ "$WORKFLOW_STATUS" = "completed" ]; then
  if [ "$CURRENT_PHASE" = "ship:finalize" ] || [ "$CURRENT_PHASE" = "finalize" ]; then
    # Workflow fully complete
    echo "✅ Workflow complete! Feature successfully shipped."
    echo "Monitor production for issues:"
    echo "  - Check error logs"
    echo "  - Monitor performance metrics"
    echo "  - Review user feedback"
  else
    # Phase complete, ready for next phase
    NEXT_PHASE=$(get_next_phase "$FEATURE_DIR")
    echo "Ready for next phase: $NEXT_PHASE"
    echo "Continue workflow:"
    echo "  /ship continue"
  fi
fi
```

### Status: in_progress

```bash
if [ "$WORKFLOW_STATUS" = "in_progress" ]; then
  echo "Current phase in progress: $CURRENT_PHASE"
  echo "Wait for current phase to complete, then:"
  echo "  /ship continue"
fi
```

### Status: failed

```bash
if [ "$WORKFLOW_STATUS" = "failed" ]; then
  echo "❌ Workflow failed at: $CURRENT_PHASE"
  echo "Check logs in: $FEATURE_DIR"
  echo "After fixing issues, retry:"
  echo "  /ship continue"
fi
```

### Status: pending

```bash
if [ "$WORKFLOW_STATUS" = "pending" ]; then
  # Check if it's a manual gate
  PREVIEW_STATUS=$(yq eval '.workflow.manual_gates.preview.status // "none"' "$STATE_FILE")
  VALIDATION_STATUS=$(yq eval '.workflow.manual_gates."validate-staging".status // "none"' "$STATE_FILE")

  if [ "$PREVIEW_STATUS" = "pending" ]; then
    echo "⏸️  Waiting for preview approval"
    echo "Complete manual testing, then:"
    echo "  /ship continue"
  elif [ "$VALIDATION_STATUS" = "pending" ]; then
    echo "⏸️  Waiting for staging validation"
    echo "Run staging validation:"
    echo "  /validate-staging"
    echo "Then continue:"
    echo "  /ship continue"
  else
    echo "Ready to continue"
    echo "Resume workflow:"
    echo "  /ship continue"
  fi
fi
```

---

## Error Conditions

### No Feature Directory

If `specs/*/` directory doesn't exist:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Deployment Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ No features found

Create a new feature with: /spec-flow "Feature Name"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### No state.yaml

If state file doesn't exist in feature directory:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Deployment Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  No workflow state found for: specs/001-user-auth/

This feature may have been created before state tracking was implemented.
Create a new feature with: /spec-flow "Feature Name"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Auto-migration from JSON

If workflow-state.json exists but state.yaml doesn't:

```bash
# Auto-migrate from JSON to YAML
if [ ! -f "$STATE_FILE" ] && [ -f "$FEATURE_DIR/workflow-state.json" ]; then
  echo "🔄 Migrating workflow state to YAML..." >&2
  yq eval -P "$FEATURE_DIR/workflow-state.json" > "$STATE_FILE"
fi
```

---

## References

### Related Commands

- `/ship` - Deployment orchestration
- `/ship continue` - Resume workflow
- `/validate-staging` - Staging environment validation
- `/preview` - Local preview for testing

### Related Files

- `state.yaml` - Deployment workflow state
- `.spec-flow/scripts/bash/workflow-state.sh` - State management functions

---

## Notes

**Characteristics:**

- **Real-time**: Status reflects current workflow state
- **Comprehensive**: Shows all phases, gates, and deployments
- **Actionable**: Provides clear next steps
- **Context-aware**: Adapts display based on deployment model
- **Helpful**: Includes command suggestions
- **Safe**: No state modifications (read-only)

**Display Features:**

- Unicode box characters for visual hierarchy
- Emoji indicators for status (🔄, ✅, ❌, ⏸️)
- Section separators for readability
- Truncated commit SHAs (first 7 characters)
- Helpful commands footer
- Feature directory and state file paths

**Deployment Models:**

- **staging-prod**: Staging → Validation → Production
- **direct-prod**: Direct to Production
- **local-only**: Local Build Only

**Status Values:**

- **in_progress**: Phase currently executing
- **completed**: Phase finished successfully
- **failed**: Phase encountered errors
- **pending**: Waiting for manual approval or next trigger

**Gate Types:**

- **Manual Gates**: Require user approval (preview, validate-staging)
- **Quality Gates**: Automated checks (pre_flight, code_review, rollback_capability)
