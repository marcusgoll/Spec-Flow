---
name: help
description: Analyze workflow state and provide context-aware guidance with visual progress indicators and recommended next steps
argument-hint: [verbose]
allowed-tools:
  [
    Read,
    Bash(ls:*),
    Bash(yq:*),
    Bash(cat:*),
    Bash(echo:*),
    Bash(wc:*),
    Bash(grep:*),
    Bash(tail:*),
  ]
---

<objective>
Analyze the current workflow context (feature directory, workflow state, phase progress) and provide contextual help including:
- Current workflow state with visual progress
- Completed/pending/failed phases
- Blockers or manual gates requiring attention
- Specific next commands based on current phase
- Deployment model awareness (staging-prod/direct-prod/local-only)
- Detailed state information in verbose mode
</objective>

<process>
## Step 1: Detect Workflow Context

! `FEATURE_DIR=$(ls -td specs/*/ 2>/dev/null | head -1 | sed 's:/$::'); if [ -z "$FEATURE_DIR" ]; then echo "no_feature"; else echo "$FEATURE_DIR"; fi`

! `if [ "$FEATURE_DIR" = "no_feature" ]; then echo "no_feature"; elif [ ! -f "$FEATURE_DIR/state.yaml" ]; then echo "no_state"; else echo "in_feature"; fi`

## Step 2: Load Workflow State (if in feature)

! `if [ -f "$FEATURE_DIR/state.yaml" ]; then yq eval '.workflow.phase' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown"; fi`

! `if [ -f "$FEATURE_DIR/state.yaml" ]; then yq eval '.workflow.status' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown"; fi`

! `if [ -f "$FEATURE_DIR/state.yaml" ]; then yq eval '.deployment_model' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown"; fi`

! `if [ -f "$FEATURE_DIR/state.yaml" ]; then yq eval '.feature.slug' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown"; fi`

! `if [ -f "$FEATURE_DIR/state.yaml" ]; then yq eval '.feature.branch_name' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown"; fi`

! `if [ -f "$FEATURE_DIR/state.yaml" ]; then yq eval '.workflow.completed_phases[]' "$FEATURE_DIR/state.yaml" 2>/dev/null | wc -l | tr -d ' '; fi`

! `if [ -f "$FEATURE_DIR/state.yaml" ]; then yq eval '.workflow.failed_phases[]' "$FEATURE_DIR/state.yaml" 2>/dev/null; fi`

! `if [ -f "$FEATURE_DIR/state.yaml" ]; then yq eval '.workflow.manual_gates.preview.status' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "null"; fi`

! `if [ -f "$FEATURE_DIR/state.yaml" ]; then yq eval '.workflow.manual_gates.validate_staging.status' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "null"; fi`

## Step 3: Render Context-Specific Help

Based on detected context, provide appropriate guidance:

**Context 1: No Feature Directory**

- Show getting started commands (/feature, /roadmap, /init-project)
- Link to documentation

**Context 2: Missing State File**

- Show recovery options
- Explain how to manually restore or start fresh

**Context 3: Workflow Blocked (failed status)**

- Show failed phases
- Display recent errors from error-log.md
- Provide recovery commands (/debug, /feature continue)

**Context 4: At Manual Gate (preview or staging validation)**

- Show testing checklist
- Display environment URL
- Provide approval/abort commands

**Context 5: Feature Complete**

- Show completion summary
- Display production version and URL
- List generated artifacts
- Suggest next feature commands

**Context 6: Active Phase (default)**

- Show progress bar with emoji indicators
- Display current phase and status
- Show completed/total phases
- Provide phase-specific next steps
- Display workflow path for deployment model

**Verbose Mode** (if $ARGUMENTS contains "verbose"):

- Show quality gate status (pre-flight, code-review, rollback)
- Display deployment URLs and versions
- Show GitHub issue link if available
- List all completed phases
  </process>

<success_criteria>
Help output is successful when:

- Workflow context correctly detected (6 possible contexts)
- Current phase and progress accurately displayed
- Next steps are specific and actionable
- Blockers or errors prominently highlighted
- Manual gates show clear approval/abort instructions
- Deployment model correctly reflected in workflow path
- Verbose mode provides additional detail when requested
  </success_criteria>

---

Based on the detected context above, here is your current workflow state:

## Context Detection

! `CONTEXT=$(if [ "$FEATURE_DIR" = "no_feature" ]; then echo "no_feature"; elif [ ! -f "$FEATURE_DIR/state.yaml" ]; then echo "no_state"; else WORKFLOW_STATUS=$(yq eval '.workflow.status' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown"); PREVIEW_GATE=$(yq eval '.workflow.manual_gates.preview.status' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "null"); STAGING_GATE=$(yq eval '.workflow.manual_gates.validate_staging.status' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "null"); COMPLETED_PHASES=$(yq eval '.workflow.completed_phases[]' "$FEATURE_DIR/state.yaml" 2>/dev/null); if [ "$WORKFLOW_STATUS" = "failed" ]; then echo "blocked"; elif [ "$PREVIEW_GATE" = "pending" ] || [ "$STAGING_GATE" = "pending" ]; then echo "manual_gate"; elif [ "$WORKFLOW_STATUS" = "completed" ] && echo "$COMPLETED_PHASES" | grep -q "finalize"; then echo "complete"; else echo "active"; fi; fi); echo "$CONTEXT"`

---

### No Feature - Getting Started

If CONTEXT is "no_feature":

```
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
```

---

### Missing State File

If CONTEXT is "no_state":

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Workflow State Not Found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature directory detected: ! `echo "$FEATURE_DIR"`/
But state.yaml is missing or corrupted.

**Possible causes:**
1. State file was deleted
2. Feature created outside /feature command
3. State file corrupted

**Recovery options:**

1. **Start fresh:**
   If feature not started yet:
   - Delete ! `echo "$FEATURE_DIR"`/ directory
   - Run: /feature "Feature description"

2. **Manual recovery:**
   - Copy template: .spec-flow/templates/state.yaml
   - Edit manually with feature details
   - Continue workflow with /feature continue

3. **Get help:**
   Ask for manual recovery steps

💡 This usually happens if state file was manually deleted.
   The workflow needs this file to track progress.
```

---

### Workflow Blocked

If CONTEXT is "blocked":

! `CURRENT_PHASE=$(yq eval '.workflow.phase' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown")`

! `FEATURE_SLUG=$(yq eval '.feature.slug' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown")`

! `FAILED_PHASES=$(yq eval '.workflow.failed_phases[]' "$FEATURE_DIR/state.yaml" 2>/dev/null)`

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Workflow Blocked
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: ! `echo "$FEATURE_SLUG"`
Phase: ! `echo "$CURRENT_PHASE"` (failed)

**Failed Phases:**
! `echo "$FAILED_PHASES" | while read -r phase; do [ -n "$phase" ] && echo "❌ $phase"; done`

```

! `if [ -f "$FEATURE_DIR/error-log.md" ]; then echo "**Recent Errors:**"; tail -20 "$FEATURE_DIR/error-log.md" | head -10; echo ""; echo "View full log: @ $FEATURE_DIR/error-log.md"; echo ""; fi`

```
**Recovery Options:**

1. **Fix issues manually:**
   - Review error log: @ ! `echo "$FEATURE_DIR"`/error-log.md
   - Fix each blocker
   - Resume: /feature continue

2. **Get help debugging:**
   - Analyze errors: /debug
   - The debug agent will triage and suggest fixes

3. **View context:**
   - Tasks: @ ! `echo "$FEATURE_DIR"`/tasks.md
   - Plan: @ ! `echo "$FEATURE_DIR"`/plan.md
   - Spec: @ ! `echo "$FEATURE_DIR"`/spec.md

💡 After fixing issues, run: /feature continue
```

---

### Manual Gate

If CONTEXT is "manual_gate":

! `PREVIEW_GATE=$(yq eval '.workflow.manual_gates.preview.status' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "null")`

! `STAGING_GATE=$(yq eval '.workflow.manual_gates.validate_staging.status' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "null")`

! `if [ "$PREVIEW_GATE" = "pending" ]; then echo "Preview Testing|ship:preview"; elif [ "$STAGING_GATE" = "pending" ]; then echo "Staging Validation|ship:validate-staging"; fi`

For preview gate:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛑 MANUAL GATE: Preview Testing
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: ! `echo "$FEATURE_SLUG"`
Phase: ship:preview (waiting for approval)

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
```

For staging gate:

! `STAGING_URL=$(yq eval '.deployment.staging.url' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown")`

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛑 MANUAL GATE: Staging Validation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: ! `echo "$FEATURE_SLUG"`
Phase: ship:validate-staging (waiting for approval)

Staging deployment is live. Please complete:

**Testing Checklist:**
☐ 1. Test all feature functionality in staging
☐ 2. Verify data integrity and migrations
☐ 3. Test integrations with external services
☐ 4. Check monitoring and logs
☐ 5. Verify rollback capability

**Staging Environment:**
  URL: ! `echo "$STAGING_URL"`

**After Testing:**
  ✅ Approve: /ship continue
  ❌ Issues: /debug (fix issues first)
  🛑 Rollback: /ship rollback

**What happens next:**
  → Deploy to production
  → Create release version
  → Update roadmap to "shipped"
```

---

### Feature Complete

If CONTEXT is "complete":

! `PRODUCTION_VERSION=$(yq eval '.deployment.production.version' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown")`

! `PRODUCTION_URL=$(yq eval '.deployment.production.url' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown")`

! `ROADMAP_STATUS=$(yq eval '.feature.roadmap_status' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown")`

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Feature Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: ! `echo "$FEATURE_SLUG"`
Version: ! `echo "$PRODUCTION_VERSION"`
Roadmap: ! `echo "$ROADMAP_STATUS"`

✅ All phases completed
```

! `if [ "$PRODUCTION_URL" != "unknown" ] && [ "$PRODUCTION_URL" != "null" ]; then echo "📦 Production URL: $PRODUCTION_URL"; fi`

```
**Artifacts:**
```

! `if [ -f "$FEATURE_DIR/spec.md" ]; then echo "📄 Spec:          @ $FEATURE_DIR/spec.md"; fi`

! `if [ -f "$FEATURE_DIR/plan.md" ]; then echo "📄 Plan:          @ $FEATURE_DIR/plan.md"; fi`

! `if [ -f "$FEATURE_DIR/tasks.md" ]; then echo "📄 Tasks:         @ $FEATURE_DIR/tasks.md"; fi`

! `if [ -f "$FEATURE_DIR/ship-summary.md" ]; then echo "📄 Ship Report:   @ $FEATURE_DIR/ship-summary.md"; fi`

! `if [ -f "$FEATURE_DIR/release-notes.md" ]; then echo "📄 Release Notes: @ $FEATURE_DIR/release-notes.md"; fi`

```
**Next Steps:**
🚀 Start new feature: /feature "description"
🎯 Pick from roadmap: /feature next
📋 View roadmap: /roadmap

💡 Great work! The feature is shipped and documented.
```

---

### Active Workflow

If CONTEXT is "active":

! `CURRENT_PHASE=$(yq eval '.workflow.phase' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown")`

! `WORKFLOW_STATUS=$(yq eval '.workflow.status' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown")`

! `DEPLOYMENT_MODEL=$(yq eval '.deployment_model' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown")`

! `FEATURE_SLUG=$(yq eval '.feature.slug' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown")`

! `BRANCH_NAME=$(yq eval '.feature.branch_name' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown")`

! `COMPLETED_COUNT=$(yq eval '.workflow.completed_phases[]' "$FEATURE_DIR/state.yaml" 2>/dev/null | wc -l | tr -d ' ')`

! `TOTAL_PHASES=$(case "$DEPLOYMENT_MODEL" in "staging-prod") echo "11";; "direct-prod") echo "8";; "local-only") echo "8";; *) echo "10";; esac)`

! `COMPLETED_PHASES=$(yq eval '.workflow.completed_phases[]' "$FEATURE_DIR/state.yaml" 2>/dev/null)`

! `FAILED_PHASES=$(yq eval '.workflow.failed_phases[]' "$FEATURE_DIR/state.yaml" 2>/dev/null)`

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧭 Current Workflow State
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: ! `echo "$FEATURE_SLUG"`
Branch: ! `echo "$BRANCH_NAME"`
Directory: @ ! `echo "$FEATURE_DIR"`/

📍 Current Phase: ! `echo "$CURRENT_PHASE"` (! `echo "$WORKFLOW_STATUS"`)
✅ Completed: ! `echo "$COMPLETED_COUNT"`/! `echo "$TOTAL_PHASES"` phases
📦 Deployment Model: ! `echo "$DEPLOYMENT_MODEL"`

**Progress:**
```

! `get_status() { local phase="$1"; if echo "$FAILED_PHASES" | grep -q "^$phase$"; then echo "❌"; elif echo "$COMPLETED_PHASES" | grep -q "^$phase$"; then echo "✅"; elif [ "$CURRENT_PHASE" = "$phase" ] || [[ "$CURRENT_PHASE" == *"$phase"* ]]; then echo "⏳"; else echo "⬜"; fi; }; echo "$(get_status 'spec-flow') spec-flow     Specification"; echo "$(get_status 'plan') plan          Implementation plan"; echo "$(get_status 'tasks') tasks         Task breakdown"; echo "$(get_status 'analyze') analyze       Cross-artifact validation"; echo "$(get_status 'implement') implement     Execute tasks"; echo "$(get_status 'optimize') optimize      Code review & quality"; echo "$(get_status 'preview') preview       Manual testing gate"; case "$DEPLOYMENT_MODEL" in "staging-prod") echo "$(get_status 'ship-staging') ship-staging  Deploy to staging"; echo "$(get_status 'validate') validate      Staging validation gate"; echo "$(get_status 'ship-prod') ship-prod    Deploy to production";; "direct-prod") echo "$(get_status 'deploy-prod') deploy-prod   Deploy to production";; "local-only") echo "$(get_status 'build-local') build-local   Local build validation";; esac; echo "$(get_status 'finalize') finalize      Documentation & cleanup"`

```
**Next Steps:**
```

! `case "$CURRENT_PHASE" in *"spec"*|*"clarify"*|*"plan"*|*"tasks"*|*"analyze"*) echo "1. Continue workflow: /feature continue"; echo "2. View spec: @ $FEATURE_DIR/spec.md"; if [ "$CURRENT_PHASE" = "tasks" ] || [ "$CURRENT_PHASE" = "analyze" ]; then echo "3. View plan: @ $FEATURE_DIR/plan.md"; fi;; *"implement"*) echo "1. Continue implementation: /feature continue"; echo "2. View tasks: @ $FEATURE_DIR/tasks.md"; echo "3. Check progress: @ $FEATURE_DIR/NOTES.md"; echo "4. Debug issues: /debug";; *"optimize"*) echo "1. Continue optimization: /feature continue"; echo "2. View code review: @ $FEATURE_DIR/code-review-report.md"; echo "3. Fix issues: /debug";; *"preview"*) echo "1. Test locally: npm run dev"; echo "2. After testing: /ship continue"; echo "3. If issues: /debug";; *"ship"*|*"deploy"*|*"build"*) echo "1. Continue deployment: /ship continue"; echo "2. Check status: /deploy-status"; echo "3. If issues: /fix-ci";; *"finalize"*) echo "1. Complete finalization: /feature continue"; echo "2. View ship report: @ $FEATURE_DIR/ship-summary.md";; *) echo "1. Continue workflow: /feature continue"; echo "2. View documentation: @ $FEATURE_DIR/spec.md";; esac`

```
**Workflow Path** (! `echo "$DEPLOYMENT_MODEL"`):
```

! `case "$DEPLOYMENT_MODEL" in "staging-prod") echo "implement → optimize → preview → ship-staging → validate → ship-prod → finalize";; "direct-prod") echo "implement → optimize → preview → deploy-prod → finalize";; "local-only") echo "implement → optimize → preview → build-local → finalize";; *) echo "implement → optimize → preview → ship → finalize";; esac`

```
💡 Tip: The workflow auto-continues after each phase completes.
   Manual gates will pause for your approval.
```

---

### Verbose Mode (if $ARGUMENTS contains "verbose")

! `if [[ "${ARGUMENTS:-}" == *"verbose"* ]] && [ "$CONTEXT" = "active" ]; then echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "📊 Detailed State Information"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo ""; echo "**Quality Gates:**"; PRE_FLIGHT=$(yq eval '.quality_gates.pre_flight.passed' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "null"); CODE_REVIEW=$(yq eval '.quality_gates.code_review.passed' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "null"); ROLLBACK=$(yq eval '.quality_gates.rollback_capability.passed' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "null"); if [ "$PRE_FLIGHT" != "null" ]; then [ "$PRE_FLIGHT" = "true" ] && echo "✅ Pre-flight checks: passed" || echo "❌ Pre-flight checks: failed"; fi; if [ "$CODE_REVIEW" != "null" ]; then [ "$CODE_REVIEW" = "true" ] && echo "✅ Code review: passed" || echo "❌ Code review: failed"; fi; if [ "$ROLLBACK" != "null" ]; then [ "$ROLLBACK" = "true" ] && echo "✅ Rollback capability: tested" || echo "⬜ Rollback capability: not tested"; fi; echo ""; STAGING_URL=$(yq eval '.deployment.staging.url' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown"); PRODUCTION_URL=$(yq eval '.deployment.production.url' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown"); PRODUCTION_VERSION=$(yq eval '.deployment.production.version' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "unknown"); STAGING_DEPLOYED=$(yq eval '.deployment.staging.deployed' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "false"); PRODUCTION_DEPLOYED=$(yq eval '.deployment.production.deployed' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "false"); if [ "$STAGING_DEPLOYED" = "true" ] || [ "$PRODUCTION_DEPLOYED" = "true" ]; then echo "**Deployment Status:**"; [ "$STAGING_DEPLOYED" = "true" ] && echo "📦 Staging: $STAGING_URL"; [ "$PRODUCTION_DEPLOYED" = "true" ] && echo "🚀 Production: $PRODUCTION_URL ($PRODUCTION_VERSION)"; echo ""; fi; GITHUB_ISSUE=$(yq eval '.feature.github_issue' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "null"); if [ "$GITHUB_ISSUE" != "null" ] && [ "$GITHUB_ISSUE" != "0" ]; then echo "**GitHub Integration:**"; echo "🔗 Issue #$GITHUB_ISSUE"; echo ""; fi; echo "**Completed Phases:**"; if [ -n "$COMPLETED_PHASES" ]; then echo "$COMPLETED_PHASES" | while read -r phase; do [ -n "$phase" ] && echo "✅ $phase"; done; else echo "(none yet)"; fi; fi`
