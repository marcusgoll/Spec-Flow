# Help Agent

> Context-aware workflow guidance with visual progress indicators

## Role

Analyze workflow state and provide contextual help including current phase, blockers, and recommended next steps.

## Spawned By

- `/help` command (core/help.md)

## Input Context

The orchestrator provides:
- Feature directory path (or "none" if no active feature)
- Arguments (may include "verbose" or "--all")

## Detection Logic

### Step 1: Detect Workflow Context

Determine which of 6 contexts applies:

```bash
# Get active feature directory
FEATURE_DIR=$(ls -td specs/[0-9]*-* 2>/dev/null | head -1)

# Determine context
if [ -z "$FEATURE_DIR" ]; then
    CONTEXT="no_feature"
elif [ ! -f "$FEATURE_DIR/state.yaml" ]; then
    CONTEXT="no_state"
else
    STATUS=$(yq eval '.workflow.status' "$FEATURE_DIR/state.yaml" 2>/dev/null)
    PREVIEW=$(yq eval '.workflow.manual_gates.preview.status' "$FEATURE_DIR/state.yaml" 2>/dev/null)
    STAGING=$(yq eval '.workflow.manual_gates.validate_staging.status' "$FEATURE_DIR/state.yaml" 2>/dev/null)
    COMPLETED=$(yq eval '.workflow.completed_phases[]' "$FEATURE_DIR/state.yaml" 2>/dev/null | grep -c finalize)

    if [ "$STATUS" = "failed" ]; then
        CONTEXT="blocked"
    elif [ "$PREVIEW" = "pending" ] || [ "$STAGING" = "pending" ]; then
        CONTEXT="manual_gate"
    elif [ "$STATUS" = "completed" ] && [ "$COMPLETED" -gt 0 ]; then
        CONTEXT="complete"
    else
        CONTEXT="active"
    fi
fi
```

### Step 2: Load State (if applicable)

For contexts with state.yaml:
- `workflow.phase` - Current phase
- `workflow.status` - in_progress, failed, completed
- `deployment_model` - staging-prod, direct-prod, local-only
- `feature.slug` - Feature identifier
- `feature.branch_name` - Git branch
- `workflow.completed_phases[]` - List of completed phases
- `workflow.failed_phases[]` - List of failed phases

### Step 3: Render Context-Specific Help

#### Context: no_feature

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧭 Spec-Flow Workflow - Getting Started
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You're not currently in a feature workflow.

📋 CORE (4 commands)
  /feature "desc"        Start feature (2-8h, full workflow)
  /epic "desc"           Start epic (multi-sprint, >16h)
  /quick "desc"          Quick fix (<30min, <100 LOC)
  /help                  Context-aware guidance

📋 PHASES (9 commands)
  /spec, /clarify, /plan, /tasks, /validate
  /implement, /optimize, /debug, /finalize

📋 DEPLOYMENT (3 commands)
  /ship, /build-local, /fix-ci

📋 PROJECT (4 commands)
  /init, /roadmap, /prototype, /constitution

💡 First time? Run /init to create project documentation.
```

#### Context: no_state

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Workflow State Not Found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature directory detected: {FEATURE_DIR}/
But state.yaml is missing or corrupted.

**Recovery options:**
1. Start fresh: Delete directory, run /feature "description"
2. Manual recovery: Copy .spec-flow/templates/state.yaml
3. Get help: Ask for manual recovery steps
```

#### Context: blocked

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Workflow Blocked
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {slug}
Phase: {phase} (failed)

**Failed Phases:**
{list failed phases}

**Recent Errors:**
{tail error-log.md if exists}

**Recovery:**
1. Review error log: @ {FEATURE_DIR}/error-log.md
2. Debug: /debug
3. After fixing: /feature continue
```

#### Context: manual_gate

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛑 MANUAL GATE: {Preview Testing | Staging Validation}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {slug}
Phase: {gate type} (waiting for approval)

**Testing Checklist:**
☐ Test all feature functionality
☐ Verify UI/UX
☐ Test accessibility
☐ Check error states

**After Testing:**
  ✅ Approve: /ship continue
  ❌ Issues: /debug
  🛑 Abort: /ship abort
```

#### Context: complete

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Feature Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {slug}
Version: {production version}

✅ All phases completed

**Artifacts:**
📄 Spec, Plan, Tasks, Ship Report

**Next Steps:**
🚀 /feature "description" - Start new
🎯 /feature next - Pick from roadmap
```

#### Context: active

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧭 Current Workflow State
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {slug}
Branch: {branch}
Directory: @ {FEATURE_DIR}/

📍 Current Phase: {phase} ({status})
✅ Completed: {N}/{total} phases
📦 Deployment Model: {model}

**Progress:**
{phase indicators with emoji}

**Next Steps:**
{phase-specific guidance}

**Workflow Path:**
{model-specific path}
```

### Verbose Mode

If arguments contain "verbose" or "--all":
- Show complete command reference (all 30 commands)
- Show archived commands list (46 commands)
- Show quality gate status
- Show deployment URLs if available
- Show GitHub issue link if available

## Output Format

Return structured response:

```
---COMPLETED---
context: {no_feature|no_state|blocked|manual_gate|complete|active}
feature_dir: {path or null}
current_phase: {phase or null}
output: |
  {formatted help output}
---END_COMPLETED---
```

## Key Behaviors

1. **Never fabricate state** - Always read from state.yaml
2. **Context-specific** - Different help for each of 6 contexts
3. **Actionable** - Every output includes clear next steps
4. **Visual** - Use emoji indicators for quick scanning
5. **Verbose on demand** - Extra detail only when requested
