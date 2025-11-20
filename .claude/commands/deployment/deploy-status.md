---
description: Display comprehensive deployment workflow status showing current phase, completed tasks, quality gates, and deployment information
allowed-tools: [Read, Bash(ls:*), Bash(yq:*), Bash(cat:*), Bash(grep:*), Bash(wc:*), Bash(test:*)]
argument-hint: (no arguments - displays status for most recent feature)
---

<context>
Most recent feature directory: !`ls -td specs/*/ 2>/dev/null | head -1 | tr -d '\n'`

Workflow state file exists: !`test -f $(ls -td specs/*/ 2>/dev/null | head -1)workflow-state.yaml && echo "✅ Found" || echo "❌ Missing"`

Current phase: !`yq eval '.workflow.phase // "unknown"' $(ls -td specs/*/ 2>/dev/null | head -1)workflow-state.yaml 2>/dev/null || echo "N/A"`

Workflow status: !`yq eval '.workflow.status // "unknown"' $(ls -td specs/*/ 2>/dev/null | head -1)workflow-state.yaml 2>/dev/null || echo "N/A"`

Deployment model: !`yq eval '.deployment_model // "unknown"' $(ls -td specs/*/ 2>/dev/null | head -1)workflow-state.yaml 2>/dev/null || echo "N/A"`
</context>

<objective>
Display a comprehensive, formatted view of the current deployment workflow status.

**What it does:**
- Shows feature metadata (title, slug, timestamps)
- Displays deployment model and path
- Shows current phase and workflow status
- Lists completed and failed phases
- Shows manual gate statuses (preview, staging validation)
- Shows quality gate results (pre-flight, code review, rollback)
- Displays deployment information (staging/production URLs, commits, IDs)
- Provides context-aware next steps

**Operating constraints:**
- **Read-Only** — Never modifies workflow-state.yaml
- **Most Recent Feature** — Automatically uses latest specs/*/ directory
- **Auto-Migration** — Detects workflow-state.json and suggests migration
- **Graceful Degradation** — Handles missing sections elegantly

**Dependencies:**
- At least one feature directory in specs/
- workflow-state.yaml file in feature directory
- yq command-line tool for YAML parsing
</objective>

<process>
1. **Find most recent feature directory**:
   ```bash
   FEATURE_DIR=$(ls -td specs/*/ 2>/dev/null | head -1)
   ```
   - Use `ls -td` to sort by modification time (newest first)
   - If no features found, display error message and exit

2. **Locate workflow state file**:
   ```bash
   STATE_FILE="$FEATURE_DIR/workflow-state.yaml"
   ```
   - Check if STATE_FILE exists
   - If not, check for workflow-state.json and suggest migration
   - If neither exists, display helpful error

3. **Extract feature information** using yq:
   - Feature slug: `.feature.slug`
   - Feature title: `.feature.title`
   - Created timestamp: `.feature.created`
   - Last updated timestamp: `.feature.last_updated`

4. **Extract deployment model**:
   - Deployment model: `.deployment_model`
   - Interpret model type:
     - `staging-prod` → "Path: Staging → Validation → Production"
     - `direct-prod` → "Path: Direct to Production"
     - `local-only` → "Path: Local Build Only"

5. **Extract current status**:
   - Current phase: `.workflow.phase`
   - Workflow status: `.workflow.status`
   - Map status to emoji:
     - `in_progress` → 🔄 IN PROGRESS
     - `completed` → ✅ COMPLETED
     - `failed` → ❌ FAILED
     - `pending` → ⏸️  PENDING

6. **Extract completed phases**:
   - Completed phases list: `.workflow.completed_phases[]`
   - Display each phase with ✅ checkmark
   - If empty, show "No phases completed yet"

7. **Extract failed phases** (if any):
   - Failed phases list: `.workflow.failed_phases[]`
   - Display each phase with ❌ X mark
   - Only show section if failures exist

8. **Extract manual gates** (if defined):
   - Manual gates: `.workflow.manual_gates | to_entries`
   - For each gate, extract name and status
   - Map status to emoji:
     - `pending` → ⏸️  PENDING
     - `approved` → ✅ APPROVED
     - `rejected` → ❌ REJECTED

9. **Extract quality gates** (if defined):
   - Quality gates: `.quality_gates | to_entries`
   - For each gate, extract name and passed boolean
   - Display with ✅ PASSED or ❌ FAILED

10. **Extract deployment information**:
    - **Staging**:
      - Deployed: `.deployment.staging.deployed`
      - If deployed, extract: URL, timestamp, commit SHA, deployment IDs
      - Truncate commit SHA to first 7 characters
    - **Production**:
      - Deployed: `.deployment.production.deployed`
      - If deployed, extract: URL, timestamp, commit SHA, version, deployment IDs
    - If neither deployed, show "No deployments yet"

11. **Determine next steps** based on workflow status:
    - **completed**:
      - If current phase is "finalize", show completion message with monitoring tips
      - Otherwise, show "Ready for next phase" with `/ship continue`
    - **in_progress**:
      - Show "Current phase in progress" with "Wait for completion"
    - **failed**:
      - Show error message with feature directory path
      - Suggest `/ship continue` after fixing
    - **pending**:
      - Check manual gates for pending status
      - If preview pending: "Complete manual testing, then /ship continue"
      - If validation pending: "Run /validate-staging, then /ship continue"
      - Otherwise: "Resume workflow: /ship continue"

12. **Format output** with visual hierarchy:
    - Use Unicode box characters (━, ─) for section separators
    - Use emoji indicators for status visualization
    - Section headers: 📦, 🎯, 📍, ✅, ❌, 🚪, 🔒, 🌐, ➡️, 📚
    - Include helpful commands footer:
      - /ship continue
      - /deploy status
      - /validate-staging
      - /preview
    - Show feature directory and state file paths

See `.claude/skills/deploy-status/references/reference.md` for detailed data extraction procedures, status display examples, and next steps logic.
</process>

<verification>
Before completing, verify:
- Feature directory found successfully
- workflow-state.yaml file read correctly
- All sections extracted without errors
- Status emoji indicators applied correctly
- Manual and quality gates displayed if present
- Deployment information shown for staging/production if deployed
- Next steps are context-aware based on current status
- Output formatted with clear visual hierarchy
- Helpful commands footer included
</verification>

<success_criteria>
**Data extraction:**
- Feature metadata displayed (title, slug, created, updated)
- Deployment model correctly interpreted
- Current phase and status shown with emoji
- All completed phases listed with checkmarks
- Failed phases shown if any exist

**Gate status:**
- Manual gates displayed with status emoji
- Quality gates shown with pass/fail indicators
- Only display gate sections if gates exist in state file

**Deployment information:**
- Staging deployment details if deployed (URL, timestamp, commit, IDs)
- Production deployment details if deployed (URL, timestamp, commit, version, IDs)
- "No deployments yet" if neither deployed

**Next steps guidance:**
- Context-aware based on workflow status
- Actionable commands provided
- Specific instructions for manual gates
- Clear completion message when workflow done

**Visual formatting:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Deployment Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Feature Information
─────────────────────────────────────────────
Title: {title}
Slug: {slug}
Created: {timestamp}
Updated: {timestamp}

🎯 Deployment Model
─────────────────────────────────────────────
Model: {model}
Path: {path description}

📍 Current Status
─────────────────────────────────────────────
Phase: {current_phase}
Status: {emoji} {STATUS}

✅ Completed Phases
─────────────────────────────────────────────
  ✅ {phase1}
  ✅ {phase2}

{Optional sections: Failed Phases, Manual Gates, Quality Gates}

🌐 Deployment Information
─────────────────────────────────────────────
{Staging/Production details or "No deployments yet"}

➡️  Next Steps
─────────────────────────────────────────────
{Context-aware guidance}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 Helpful Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/ship continue    - Resume workflow from last phase
/deploy status      - Show this status display
/validate-staging - Validate staging environment
/preview          - Start local preview for testing

📁 Feature directory: {feature_dir}
📄 State file: {state_file}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
</success_criteria>

<standards>
**Industry Standards:**
- **YAML Parsing**: [yq](https://mikefarah.gitbook.io/yq/) for reliable YAML data extraction
- **Unicode Box Drawing**: [Wikipedia](https://en.wikipedia.org/wiki/Box-drawing_character) for visual hierarchy

**Workflow Standards:**
- Read-only operations (never modify state)
- Graceful error handling for missing data
- Auto-migration detection for JSON → YAML
- Context-aware next steps based on current status
- Clear visual hierarchy with section separators
- Emoji indicators for quick status recognition
</standards>

<notes>
**Command location**: `.claude/commands/deployment/deploy-status.md`

**Reference documentation**: Detailed data extraction procedures, output examples (4 scenarios), next steps logic, error conditions, and integration details are in `.claude/skills/deploy-status/references/reference.md`.

**Version**: v2.0 (2025-11-20) — Refactored to XML structure, added dynamic context, tool restrictions

**Usage aliases:**
- `/deploy-status`
- `/deploy status`
- `/ship status` (via /ship integration)

**Error handling:**
- **No features found**: Display helpful error with `/spec-flow` suggestion
- **No workflow-state.yaml**: Detect and suggest migration if JSON exists
- **Missing sections**: Gracefully skip optional sections (gates, deployments)

**Status emoji mapping:**
- 🔄 = in_progress (phase executing)
- ✅ = completed (phase finished)
- ❌ = failed (phase encountered errors)
- ⏸️ = pending (waiting for approval/trigger)

**Deployment models:**
- **staging-prod**: Two-stage deployment (staging validation before production)
- **direct-prod**: Single-stage deployment (direct to production)
- **local-only**: No remote deployment (local build validation only)

**Gate types:**
- **Manual Gates**: preview, validate-staging (require user approval)
- **Quality Gates**: pre_flight, code_review, rollback_capability (automated checks)

**Related commands:**
- `/ship` - Deployment orchestration (can call `/deploy-status` via `status` arg)
- `/ship continue` - Resume workflow from last phase
- `/validate-staging` - Staging environment validation
- `/preview` - Local preview for testing

**Integration:**
The `/ship` command can invoke this command via:
```bash
if [ "$1" = "status" ]; then
  /deploy-status
  exit 0
fi
```

**Characteristics:**
- Real-time status reflecting current workflow state
- Comprehensive view of all phases, gates, and deployments
- Actionable next steps with specific commands
- Context-aware guidance based on deployment model
- Safe read-only operations (no state modifications)
</notes>
