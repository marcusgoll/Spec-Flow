---
name: help
description: Analyze workflow state and provide context-aware guidance with visual progress indicators and recommended next steps
argument-hint: [verbose]
allowed-tools: [Read, Bash, Task]
version: 2.0
updated: 2025-12-14
---

# /help — Context-Aware Workflow Guidance (Thin Wrapper)

> **v2.0 Architecture**: This command analyzes state inline for speed, with detailed rendering logic in the help-agent brief.

<context>
**Arguments**: $ARGUMENTS

**Active Feature**: !`ls -td specs/[0-9]*-* 2>/dev/null | head -1 || echo "none"`

**State Exists**: !`test -f "$(ls -td specs/[0-9]*-* 2>/dev/null | head -1)/state.yaml" 2>/dev/null && echo "yes" || echo "no"`
</context>

<objective>
Provide contextual help based on current workflow state.

**Six Contexts** (mutually exclusive):
1. `no_feature` - No specs/ directory, show getting started
2. `no_state` - Feature dir exists but state.yaml missing
3. `blocked` - Workflow failed, show recovery options
4. `manual_gate` - Waiting for approval, show checklist
5. `complete` - All phases done, show next feature options
6. `active` - In progress, show current phase and next steps

**Architecture**: Inline analysis for fast response. Agent brief at `.claude/agents/phase/help-agent.md` contains rendering templates.
</objective>

<process>

## Step 1: Detect Context

```bash
FEATURE_DIR=$(ls -td specs/[0-9]*-* 2>/dev/null | head -1)

if [ -z "$FEATURE_DIR" ]; then
    CONTEXT="no_feature"
elif [ ! -f "$FEATURE_DIR/state.yaml" ]; then
    CONTEXT="no_state"
else
    STATUS=$(yq eval '.workflow.status' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown")
    PREVIEW=$(yq eval '.workflow.manual_gates.preview.status' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "null")
    STAGING=$(yq eval '.workflow.manual_gates.validate_staging.status' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "null")

    if [ "$STATUS" = "failed" ]; then
        CONTEXT="blocked"
    elif [ "$PREVIEW" = "pending" ] || [ "$STAGING" = "pending" ]; then
        CONTEXT="manual_gate"
    elif [ "$STATUS" = "completed" ]; then
        CONTEXT="complete"
    else
        CONTEXT="active"
    fi
fi

echo "Context: $CONTEXT"
echo "Feature: $FEATURE_DIR"
```

## Step 2: Render Based on Context

**Read rendering templates from agent brief**: `.claude/agents/phase/help-agent.md`

### no_feature

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧭 Spec-Flow Workflow - Getting Started
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You're not currently in a feature workflow.

📋 CORE (4 commands)
  /feature "desc"        Start feature (2-8h)
  /epic "desc"           Start epic (>16h)
  /quick "desc"          Quick fix (<30min)
  /help                  This guidance

📋 PHASES (9 commands)
  /spec → /clarify → /plan → /tasks → /validate
  /implement → /optimize → /debug → /finalize

📋 DEPLOYMENT: /ship, /build-local, /fix-ci
📋 PROJECT: /init, /roadmap, /prototype, /constitution
📋 QUALITY: /gate ci, /gate sec
📋 META: /create, /context

💡 First time? Run /init to create project documentation.
💡 Run /help verbose for complete command reference.
```

### no_state

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Workflow State Not Found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature directory: {FEATURE_DIR}/
State file: missing

**Recovery:**
1. Delete directory and restart: /feature "description"
2. Copy template: .spec-flow/templates/state.yaml
3. Continue: /feature continue
```

### blocked

Load from state.yaml:
- `workflow.phase` - Failed phase
- `workflow.failed_phases[]` - All failures
- `feature.slug` - Feature name

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Workflow Blocked
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {slug}
Phase: {phase} (failed)

**Recovery:**
1. View errors: @ {FEATURE_DIR}/error-log.md
2. Debug: /debug
3. Resume: /feature continue
```

### manual_gate

Determine gate type from state.yaml manual_gates.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛑 MANUAL GATE: {Gate Type}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {slug}

**Checklist:**
☐ Test functionality
☐ Verify UI/UX
☐ Check accessibility
☐ Test error states

**Actions:**
  ✅ /ship continue (approve)
  ❌ /debug (fix issues)
  🛑 /ship abort (cancel)
```

### complete

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Feature Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {slug}
Version: {production.version}

**Next:**
🚀 /feature "desc" - New feature
🎯 /feature next - From roadmap
📋 /roadmap - View backlog
```

### active

Load progress from state.yaml:
- Current phase
- Completed phases count
- Deployment model

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧭 Current Workflow State
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {slug}
Branch: {branch}
Phase: {phase} ({status})
Progress: {completed}/{total} phases

**Progress Indicators:**
{emoji for each phase based on status}

**Next:** /feature continue
```

## Step 3: Verbose Mode (if requested)

If $ARGUMENTS contains "verbose" or "--all":

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Complete Command Reference
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Full command listing - see help-agent.md for template]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 ARCHIVED (46 commands in _archived/)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Access via: /_archived/<command-name>
```

</process>

<success_criteria>
- Context correctly detected (1 of 6)
- Output matches context with appropriate guidance
- Next steps are actionable commands
- Verbose mode shows extended reference when requested
</success_criteria>

<notes>
**v2.0 Changes**:
- Reduced from 470 lines to ~120 lines
- Context detection inline for speed
- Rendering templates in help-agent.md
- Removed complex inline bash blocks

**Reference**: See `.claude/agents/phase/help-agent.md` for detailed rendering templates and verbose mode content.
</notes>
