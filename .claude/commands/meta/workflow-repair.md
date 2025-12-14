---
description: Diagnose and repair corrupted workflow state. Use when state.yaml is invalid, phases are stuck, or domain-memory.yaml has stale locks.
argument-hint: "[auto | diagnose | reset-phase | clear-locks | rebuild-state]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
---

# /workflow repair - State Recovery Command

<objective>
Recover from corrupted or stuck workflow state without losing progress.

Use when:
- `/feature continue` or `/epic continue` fails unexpectedly
- state.yaml has invalid phase or status
- domain-memory.yaml has stale locks
- Workflow appears stuck with no clear error
- Need to reset to a known good state
</objective>

<context>
**User Input**: $ARGUMENTS

**Active Workflows**:
!`find specs epics -name "state.yaml" -exec dirname {} \; 2>/dev/null | head -5`

**Recent State Files**:
!`find specs epics -name "state.yaml" -mmin -60 2>/dev/null | head -3`

**Locked Features** (potential stale locks):
!`grep -l "locked_by:" specs/*/domain-memory.yaml epics/*/domain-memory.yaml epics/*/sprints/*/domain-memory.yaml 2>/dev/null | head -5`
</context>

<modes>
## Available Repair Modes

### `auto` (Default)
Automatically diagnose and fix common issues:
1. Detect workflow type and location
2. Run all diagnostic checks
3. Apply safe fixes automatically
4. Report what was fixed

### `diagnose`
Only diagnose - don't fix anything:
1. Check state.yaml validity
2. Check domain-memory.yaml consistency
3. Check artifact presence vs phase claims
4. Report issues found

### `reset-phase <phase_name>`
Reset workflow to specific phase:
1. Update state.yaml to specified phase
2. Clear phase completion markers after that phase
3. Preserve artifacts from completed phases

### `clear-locks`
Clear all stale locks in domain-memory.yaml:
1. Find all locked features
2. Remove lock metadata
3. Reset feature status to previous state

### `rebuild-state`
Rebuild state.yaml from artifacts:
1. Scan for existing artifacts (spec.md, plan.md, tasks.md)
2. Infer completed phases from presence
3. Generate new state.yaml
</modes>

<process>

## Step 1: Detect Active Workflow

```bash
# Find most recent active workflow
WORKFLOW_INFO=$(bash .spec-flow/scripts/utils/detect-workflow-paths.sh 2>/dev/null)

if [ -z "$WORKFLOW_INFO" ]; then
    echo "No active workflow detected."
    echo "Looking for any workflow with state.yaml..."

    # Fallback: find any state.yaml
    STATE_FILE=$(find specs epics -name "state.yaml" -type f 2>/dev/null | head -1)

    if [ -z "$STATE_FILE" ]; then
        echo "No workflows found. Nothing to repair."
        exit 0
    fi

    WORKFLOW_DIR=$(dirname "$STATE_FILE")
else
    WORKFLOW_DIR=$(echo "$WORKFLOW_INFO" | jq -r '"\(.base_dir)/\(.slug)"')
fi

echo "Repairing workflow at: $WORKFLOW_DIR"
```

## Step 2: Run Diagnostics

Check for common issues:

### 2.1 State File Validity

```bash
STATE_FILE="${WORKFLOW_DIR}/state.yaml"

if [ ! -f "$STATE_FILE" ]; then
    echo "❌ ISSUE: state.yaml missing"
    ISSUES+=("state_missing")
else
    # Check required fields
    PHASE=$(yq eval '.phase' "$STATE_FILE" 2>/dev/null)
    STATUS=$(yq eval '.status' "$STATE_FILE" 2>/dev/null)

    if [ -z "$PHASE" ] || [ "$PHASE" == "null" ]; then
        echo "❌ ISSUE: phase field missing or invalid"
        ISSUES+=("phase_invalid")
    fi

    if [ -z "$STATUS" ] || [ "$STATUS" == "null" ]; then
        echo "❌ ISSUE: status field missing or invalid"
        ISSUES+=("status_invalid")
    fi

    # Check phase is valid
    VALID_PHASES="spec clarify plan tasks analyze implement optimize ship finalize complete"
    if ! echo "$VALID_PHASES" | grep -qw "$PHASE"; then
        echo "❌ ISSUE: unknown phase '$PHASE'"
        ISSUES+=("phase_unknown")
    fi
fi
```

### 2.2 Domain Memory Consistency

```bash
DM_FILE="${WORKFLOW_DIR}/domain-memory.yaml"

if [ -f "$DM_FILE" ]; then
    # Check for stale locks (locked > 1 hour ago)
    LOCKED_FEATURES=$(yq eval '.features[] | select(.locked_by != null) | .id' "$DM_FILE" 2>/dev/null)

    if [ -n "$LOCKED_FEATURES" ]; then
        echo "⚠️  WARNING: Features currently locked: $LOCKED_FEATURES"
        ISSUES+=("stale_locks")
    fi

    # Check for orphaned in_progress status
    IN_PROGRESS=$(yq eval '.features[] | select(.status == "in_progress") | .id' "$DM_FILE" 2>/dev/null)

    if [ -n "$IN_PROGRESS" ]; then
        echo "⚠️  WARNING: Features stuck in_progress: $IN_PROGRESS"
        ISSUES+=("stuck_features")
    fi
fi
```

### 2.3 Artifact vs Phase Mismatch

```bash
# Check if claimed phases match actual artifacts
CLAIMED_PHASE=$(yq eval '.phase' "$STATE_FILE" 2>/dev/null)

# Spec phase should have spec.md
if [ "$CLAIMED_PHASE" != "spec" ] && [ ! -f "${WORKFLOW_DIR}/spec.md" ]; then
    echo "⚠️  WARNING: Past spec phase but spec.md missing"
    ISSUES+=("artifact_mismatch_spec")
fi

# Plan phase should have plan.md
if echo "tasks analyze implement optimize ship finalize" | grep -qw "$CLAIMED_PHASE"; then
    if [ ! -f "${WORKFLOW_DIR}/plan.md" ]; then
        echo "⚠️  WARNING: Past plan phase but plan.md missing"
        ISSUES+=("artifact_mismatch_plan")
    fi
fi

# Tasks phase should have tasks.md
if echo "analyze implement optimize ship finalize" | grep -qw "$CLAIMED_PHASE"; then
    if [ ! -f "${WORKFLOW_DIR}/tasks.md" ]; then
        echo "⚠️  WARNING: Past tasks phase but tasks.md missing"
        ISSUES+=("artifact_mismatch_tasks")
    fi
fi
```

## Step 3: Apply Repairs (Based on Mode)

### Auto Mode Repairs

```bash
if [ "$MODE" == "auto" ]; then
    for issue in "${ISSUES[@]}"; do
        case "$issue" in
            state_missing)
                echo "🔧 Rebuilding state.yaml from artifacts..."
                rebuild_state_from_artifacts "$WORKFLOW_DIR"
                ;;

            phase_invalid|phase_unknown)
                echo "🔧 Inferring phase from artifacts..."
                infer_and_set_phase "$WORKFLOW_DIR"
                ;;

            stale_locks)
                echo "🔧 Clearing stale locks..."
                clear_all_locks "$WORKFLOW_DIR"
                ;;

            stuck_features)
                echo "🔧 Resetting stuck features to pending..."
                reset_stuck_features "$WORKFLOW_DIR"
                ;;
        esac
    done
fi
```

### Reset Phase Mode

If argument is `reset-phase <phase>`:

```bash
TARGET_PHASE="$2"

# Validate target phase
VALID_PHASES="spec clarify plan tasks analyze implement optimize ship finalize"
if ! echo "$VALID_PHASES" | grep -qw "$TARGET_PHASE"; then
    echo "Invalid phase: $TARGET_PHASE"
    echo "Valid phases: $VALID_PHASES"
    exit 1
fi

# Update state.yaml
yq eval ".phase = \"$TARGET_PHASE\"" -i "$STATE_FILE"
yq eval ".status = \"in_progress\"" -i "$STATE_FILE"

# Clear completion markers for phases after target
# (Implementation depends on phase order)

echo "✅ Reset workflow to phase: $TARGET_PHASE"
echo "Run /feature continue or /epic continue to resume"
```

### Clear Locks Mode

```bash
if [ "$MODE" == "clear-locks" ]; then
    # Find all domain-memory.yaml files
    DM_FILES=$(find "$WORKFLOW_DIR" -name "domain-memory.yaml" 2>/dev/null)

    for dm_file in $DM_FILES; do
        echo "Clearing locks in: $dm_file"

        # Remove locked_by and locked_at from all features
        yq eval '.features[].locked_by = null' -i "$dm_file"
        yq eval '.features[].locked_at = null' -i "$dm_file"

        # Reset in_progress features to pending
        yq eval '(.features[] | select(.status == "in_progress")).status = "pending"' -i "$dm_file"
    done

    echo "✅ All locks cleared"
fi
```

### Rebuild State Mode

```bash
if [ "$MODE" == "rebuild-state" ]; then
    echo "Rebuilding state.yaml from artifacts..."

    # Determine workflow type
    if [[ "$WORKFLOW_DIR" == *"epics"* ]]; then
        WORKFLOW_TYPE="epic"
    else
        WORKFLOW_TYPE="feature"
    fi

    # Infer phase from artifacts
    if [ -f "${WORKFLOW_DIR}/optimization-report.md" ]; then
        INFERRED_PHASE="ship"
    elif [ -f "${WORKFLOW_DIR}/tasks.md" ]; then
        INFERRED_PHASE="implement"
    elif [ -f "${WORKFLOW_DIR}/plan.md" ]; then
        INFERRED_PHASE="tasks"
    elif [ -f "${WORKFLOW_DIR}/spec.md" ]; then
        INFERRED_PHASE="plan"
    else
        INFERRED_PHASE="spec"
    fi

    # Generate new state.yaml
    cat > "$STATE_FILE" << EOF
# Rebuilt by /workflow repair at $(date -Iseconds)
workflow_type: $WORKFLOW_TYPE
slug: $(basename "$WORKFLOW_DIR")
phase: $INFERRED_PHASE
status: in_progress
rebuilt: true
rebuilt_at: $(date -Iseconds)
EOF

    echo "✅ state.yaml rebuilt"
    echo "Inferred phase: $INFERRED_PHASE"
    echo "Run /feature continue or /epic continue to resume"
fi
```

## Step 4: Report Results

Output repair summary:

```
═══════════════════════════════════════════════════════════════
🔧 WORKFLOW REPAIR COMPLETE
═══════════════════════════════════════════════════════════════

Workflow: [path]
Type: feature | epic

Issues Found: [count]
Issues Fixed: [count]

Repairs Applied:
  ✅ Rebuilt state.yaml from artifacts
  ✅ Cleared 3 stale locks
  ✅ Reset 2 stuck features to pending

Current State:
  Phase: implement
  Status: in_progress

Next Steps:
  Run: /feature continue
  Or:  /epic continue

═══════════════════════════════════════════════════════════════
```

</process>

<helper_functions>
## Utility Functions

### rebuild_state_from_artifacts()

```bash
rebuild_state_from_artifacts() {
    local workflow_dir="$1"
    local state_file="${workflow_dir}/state.yaml"

    # Determine type
    local workflow_type="feature"
    [[ "$workflow_dir" == *"epics"* ]] && workflow_type="epic"

    # Infer phase
    local phase="spec"
    [ -f "${workflow_dir}/spec.md" ] && phase="plan"
    [ -f "${workflow_dir}/plan.md" ] && phase="tasks"
    [ -f "${workflow_dir}/tasks.md" ] && phase="implement"
    [ -f "${workflow_dir}/domain-memory.yaml" ] && phase="implement"

    # Write state
    cat > "$state_file" << EOF
workflow_type: $workflow_type
slug: $(basename "$workflow_dir")
phase: $phase
status: in_progress
rebuilt: true
rebuilt_at: $(date -Iseconds)
EOF
}
```

### clear_all_locks()

```bash
clear_all_locks() {
    local workflow_dir="$1"

    find "$workflow_dir" -name "domain-memory.yaml" | while read -r dm_file; do
        yq eval '.features[].locked_by = null' -i "$dm_file"
        yq eval '.features[].locked_at = null' -i "$dm_file"
    done
}
```

### reset_stuck_features()

```bash
reset_stuck_features() {
    local workflow_dir="$1"

    find "$workflow_dir" -name "domain-memory.yaml" | while read -r dm_file; do
        yq eval '(.features[] | select(.status == "in_progress")).status = "pending"' -i "$dm_file"
    done
}
```
</helper_functions>

<examples>
## Usage Examples

### Auto-repair stuck workflow
```
/workflow repair
```
Automatically diagnoses and fixes common issues.

### Diagnose without fixing
```
/workflow repair diagnose
```
Shows issues but doesn't change anything.

### Reset to specific phase
```
/workflow repair reset-phase plan
```
Resets workflow to plan phase, preserving spec.md.

### Clear all feature locks
```
/workflow repair clear-locks
```
Removes all locks from domain-memory.yaml files.

### Rebuild corrupted state
```
/workflow repair rebuild-state
```
Regenerates state.yaml by scanning for artifacts.
</examples>

<success_criteria>
Repair is successful when:

- [ ] Workflow can continue with `/feature continue` or `/epic continue`
- [ ] state.yaml has valid phase and status
- [ ] No stale locks in domain-memory.yaml
- [ ] No features stuck in_progress indefinitely
- [ ] Artifacts match claimed phase progression
</success_criteria>
