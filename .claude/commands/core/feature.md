---
description: Execute feature development workflow from specification through production deployment with automated quality gates
argument-hint: [description|slug|continue|next|epic:<name>|epic:<name>:sprint:<num>|sprint:<num>]
allowed-tools: Bash(python .spec-flow/scripts/spec-cli.py:*), Bash(git:*), Read(specs/**), Read(state.yaml), Read(.github/**), SlashCommand(/spec), SlashCommand(/clarify), SlashCommand(/plan), SlashCommand(/tasks), SlashCommand(/phases:validate), SlashCommand(/implement), SlashCommand(/optimize), SlashCommand(/deployment:ship-staging), SlashCommand(/deployment:ship-prod), SlashCommand(/ship), SlashCommand(/finalize), TodoWrite
version: 4.0
updated: 2025-12-04
---

<objective>
Orchestrate complete feature delivery through isolated phase agents with strict state tracking and true autopilot execution.

**Command**: `/feature [feature description | slug | continue | next | epic:<name> | epic:<name>:sprint:<num> | sprint:<num>]`

**When to use**: From idea selection through production deployment. Executes automatically until completion, only pausing on critical failures.

**Architecture**:

- **Orchestrator** (`/feature`): Moves one phase at a time, updates `state.yaml`, never invents state
- **Phase Commands**: `/spec`, `/plan`, `/tasks`, `/implement`, `/optimize`, `/ship` execute isolated phases
- **Specialist Agents**: Implementation directly launches backend-dev, frontend-dev, database-architect in parallel

**Benefits**: True autopilot execution, smaller token budgets per phase, faster execution, quality preserved by automated gates
</objective>

<context>
**Current repository state**:

Git status:
!`git status --short`

Current branch:
!`git branch --show-current`

Recent features:
!`ls -t specs/ 2>/dev/null | head -5`

Active workflow state (if any):
!`find specs -name "state.yaml" -exec grep -l "status: in_progress\|status: failed" {} \; 2>/dev/null | head -3`

Deployment model detection:
!`git branch -r | grep -q "staging" && echo "staging-prod" || (git remote -v | grep -q "origin" && echo "direct-prod" || echo "local-only")`
</context>

<process>
## Step 0.1: Initialize Feature State

**Parse user input and initialize feature workspace via spec-cli.py.**

**Display autopilot mode:**

```
🤖 Autopilot enabled - executing automatically until completion or error
```

---

## User Input Handling

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). Strip any mode flags (--auto, --interactive, --no-input) before processing.

## Execute Feature Workflow

Run the centralized spec-cli tool:

```bash
python .spec-flow/scripts/spec-cli.py feature "$ARGUMENTS"
```

**What the script does:**

1. **Parse arguments** — Determines mode: next, continue, lookup, epic, sprint
2. **GitHub issue selection** (if applicable):
   - `next` mode: Selects highest-priority issue from status:next or status:backlog
   - `epic:name` mode: Auto-detects incomplete sprint and selects next issue
   - `epic:name:sprint:num` mode: Selects next issue from specific epic+sprint
   - `sprint:num` mode: Selects next issue from any sprint
   - `lookup` mode: Searches by slug or title
3. **Feature slug generation** — Auto-generates from issue title or description
4. **Project type detection** — Identifies project technology (fullstack, backend, frontend, etc.)
5. **Branch management** — Creates feature branch or uses existing branch
6. **Initialize workflow state** — Creates `specs/NNN-slug/` directory and `state.yaml`
7. **Generate feature CLAUDE.md** — Creates AI context navigation file

**After script completes:**

1. Verify feature initialization (number, slug, branch, directory, GitHub issue)
2. **Mark roadmap issue as in-progress (if exists)**:
   ```bash
   # Search for roadmap issue by feature slug
   ROADMAP_ISSUE=$(gh issue list --label "roadmap" --search "$FEATURE_SLUG in:body" --json number --jq '.[0].number' 2>/dev/null)

   if [ -n "$ROADMAP_ISSUE" ] && [ "$ROADMAP_ISSUE" != "null" ]; then
       # Mark issue in-progress via roadmap manager
       source .spec-flow/scripts/bash/github-roadmap-manager.sh
       mark_issue_in_progress "$FEATURE_SLUG"

       # Store issue number in state.yaml for /ship integration
       yq eval '.roadmap.issue_number = "'$ROADMAP_ISSUE'"' -i "specs/$FEATURE_SLUG/state.yaml"
       echo "✅ Linked to roadmap issue #$ROADMAP_ISSUE"
   fi
   ```
3. **Execute autopilot phase loop** (see below)

---

## Step 0.15: Apply Learned Patterns (NEW - v10.16)

**Auto-apply performance optimizations and patterns from perpetual learning system.**

```bash
# Check if auto-apply learnings is available
if [ -f ".spec-flow/scripts/bash/auto-apply-learnings.sh" ]; then
    echo ""
    echo "🧠 Checking for learned patterns to apply..."
    echo ""

    # Run pattern auto-apply
    bash .spec-flow/scripts/bash/auto-apply-learnings.sh before-tool "feature" "workflow_start" || true

    # Note: The script will:
    # - Apply performance patterns (confidence ≥0.90)
    # - Warn about anti-patterns (confidence ≥0.85)
    # - Expand custom abbreviations (confidence ≥0.95)
    # - Queue CLAUDE.md tweaks for approval (confidence ≥0.95)

    echo ""
fi
```

**Displays applied patterns:**

If patterns are auto-applied, you'll see output like:
```
🧠 Checking for learned patterns to apply...

💡 Performance patterns applied: 3
  - Use Glob instead of find for file search
  - Batch git commits (3-4 files)
  - Prefer Edit over Write for existing files

⚠️  Anti-patterns to avoid: 2
  - Don't edit schema files without migration
  - Avoid nested Task calls (use sequential execution)

🎯 Custom abbreviations available: 5
  - "auth" → "authentication"
  - "db" → "database"
  - "feat" → "feature"

✅ Learned patterns active in workflow
```

**Pending approvals:**

If CLAUDE.md tweaks need approval:
```
📝 CLAUDE.md tweaks pending approval: 1
  Review: .spec-flow/learnings/pending-approvals.yaml
  Apply: /heal-workflow
```

**Skip conditions:**

Auto-apply is skipped if:
- No learnings collected yet (first few workflows)
- Learning system disabled in preferences
- CI/non-interactive mode
- `.spec-flow/learnings/` directory doesn't exist

---

## Step 0.2: Autopilot Phase Orchestration

**CRITICAL**: This is the autopilot loop that drives the entire workflow. After initialization, execute each phase in sequence until completion or error.

### Determine Starting Phase

Read `state.yaml` to find current phase:

```bash
FEATURE_DIR=$(ls -td specs/[0-9]*-* 2>/dev/null | head -1)
STATE_FILE="$FEATURE_DIR/state.yaml"

# Read current phase status
CURRENT_PHASE=$(yq eval '.phase' "$STATE_FILE" 2>/dev/null || echo "init")
echo "Current phase: $CURRENT_PHASE"
```

### Phase Execution Loop

**Execute phases in sequence using SlashCommand:**

```javascript
const PHASES = [
  { name: "spec", command: "/spec", next: "clarify" },
  { name: "clarify", command: "/clarify", next: "plan", optional: true },
  { name: "plan", command: "/plan", next: "tasks" },
  { name: "tasks", command: "/tasks", next: "analyze" },
  { name: "analyze", command: "/phases:validate", next: "implement" },
  { name: "implement", command: "/implement", next: "optimize" },
  { name: "optimize", command: "/optimize", next: "ship" },
  { name: "ship", command: "/ship", next: "finalize" },
  { name: "finalize", command: "/finalize", next: "complete" }
];

// Find current phase index
let currentIndex = PHASES.findIndex(p => p.name === currentPhase);
if (currentIndex === -1) currentIndex = 0; // Start from beginning

// Execute phases in sequence
while (currentIndex < PHASES.length) {
  const phase = PHASES[currentIndex];

  console.log(`\n${"═".repeat(60)}`);
  console.log(`🔄 Executing Phase: ${phase.name.toUpperCase()}`);
  console.log(`${"═".repeat(60)}\n`);

  // Invoke phase command via SlashCommand
  await SlashCommand(phase.command);

  // Read state to check if phase succeeded
  const state = readYAML(STATE_FILE);
  const phaseStatus = state.phases?.[phase.name];

  if (phaseStatus === "failed") {
    console.log(`\n❌ Phase ${phase.name} FAILED`);
    console.log(`   Check ${FEATURE_DIR}/error-log.md for details`);
    console.log(`   Fix issues and run: /feature continue`);
    break;
  }

  if (phaseStatus === "skipped" && phase.optional) {
    console.log(`⏭️  Phase ${phase.name} skipped (optional)`);
  }

  // Advance to next phase
  currentIndex++;

  if (currentIndex >= PHASES.length) {
    console.log(`\n${"═".repeat(60)}`);
    console.log(`✅ FEATURE COMPLETE`);
    console.log(`${"═".repeat(60)}\n`);
  }
}
```

### Manual Gate Detection

**If a phase requires manual approval, pause the loop:**

```javascript
// Check for manual gates after phase completion
const manualGates = ["mockup_approval", "staging_validation"];

for (const gate of manualGates) {
  const gateStatus = state.gates?.[gate];

  if (gateStatus === "pending") {
    console.log(`\n⏸️  MANUAL GATE: ${gate.replace("_", " ")}`);
    console.log(`   Workflow paused for approval`);
    console.log(`   After approval, run: /feature continue`);

    // Update state to reflect pause
    state.status = "paused";
    state.paused_at = new Date().toISOString();
    state.paused_reason = gate;
    writeYAML(STATE_FILE, state);

    break; // Exit loop
  }
}
```

### Error Recovery

**On any phase failure:**

1. State is automatically saved by the phase command
2. Error details logged to `error-log.md`
3. User fixes issues manually
4. Resume with `/feature continue` which reads state and continues from failed phase

**Key principle**: The loop reads state after EVERY phase invocation. Never assume success - always verify from state.yaml.
   </process>

<workflow>
## Phase Sequence

### Step 0.5: Prototype Detection (Non-Blocking)

**Check for project prototype before starting specification:**

```bash
# Check if prototype exists
PROTOTYPE_EXISTS=$(test -f design/prototype/state.yaml && echo "true" || echo "false")
```

**If prototype exists:**

1. Analyze feature description for UI keywords:
   ```javascript
   const uiKeywords = [
     'screen', 'page', 'view', 'dashboard', 'modal', 'dialog',
     'form', 'list', 'table', 'settings', 'profile', 'wizard'
   ];
   const description = "$ARGUMENTS".toLowerCase();
   const hasUIIntent = uiKeywords.some(kw => description.includes(kw));
   ```

2. If UI intent detected, compare against prototype screen registry:
   ```bash
   # Read existing screens from prototype
   cat design/prototype/state.yaml
   ```

3. If new screen might be needed, soft prompt user via AskUserQuestion:
   ```json
   {
     "question": "This feature may introduce new UI screens. Update prototype first?",
     "header": "Prototype",
     "multiSelect": false,
     "options": [
       {"label": "Yes, update prototype", "description": "Add placeholder screens to prototype now (recommended for cohesive design)"},
       {"label": "Later", "description": "Skip for now, update prototype manually later"},
       {"label": "Not needed", "description": "This feature doesn't require new screens"}
     ]
   }
   ```

4. **If "Yes"**: Pause and suggest running `/prototype update`
5. **If "Later" or "Not needed"**: Continue to specification phase

**If no prototype exists**: Skip silently (backward compatible)

**Note**: This is a soft prompt, not a blocking gate. Features can proceed without prototype.

---

### Phase 0: Specification

```bash
/spec
```

Generates `spec.md` with requirements and acceptance criteria.

**If ambiguity detected**, auto-runs clarification phase:

```bash
/clarify
```

### Phase 1: Planning

```bash
/plan
```

Generates `plan.md` with architecture decisions and implementation approach.

**Auto-proceeds to task breakdown after completion.**

### Subsequent Phases (Automatic)

**Phase 2: Task Breakdown**:

```bash
/tasks
```

**Phase 3: Cross-Artifact Analysis** (automatic):

```bash
/phases:validate
```

**Phase 4: Implementation** (automatic):

```bash
/implement
```

**Phase 5: Optimization** (automatic):

```bash
/optimize
```

**Phase 6: Deploy to Staging** (automatic):

```bash
/ship-staging
```

**Automated Staging Validation**: Auto-generates validation report with E2E tests, Lighthouse scores, rollback test, and health checks. All testing happens in staging environment.

**Phase 7: Deploy to Production** (automatic after validation):

```bash
/ship-prod
```

**Phase 8: Finalization** (automatic):

```bash
/finalize
```

</workflow>

<automatic_flow>

## Automatic Workflow Flow

**All phases execute automatically without manual review gates.**

The workflow flows continuously from specification through deployment:

```
/spec → /clarify (if needed) → /plan → /tasks → /implement → /optimize → /ship → /finalize
```

**Only blocks on critical errors:**
- CI failures
- Security issues
- Quality gate failures (tests, performance, accessibility)
- Deployment errors

**Staging Validation** (after /ship-staging):
- Runs automated validation (E2E tests, Lighthouse, health checks)
- Proceeds automatically after automated checks pass
- Only blocks on validation failures

**Resume after errors:** `/feature continue`
</automatic_flow>

<continue_mode>

## Resuming Interrupted Features

When running `/feature continue`:

### Step 0: Session Context Restoration

**Check for handoff documents and session state:**

```bash
# Detect active workflow
WORKFLOW_INFO=$(bash .spec-flow/scripts/utils/detect-workflow-paths.sh 2>/dev/null)
SLUG=$(echo "$WORKFLOW_INFO" | grep -o '"slug":"[^"]*"' | cut -d'"' -f4)
FEATURE_DIR="specs/$SLUG"

# Display session status
bash .spec-flow/scripts/bash/session-manager.sh status 2>/dev/null || true

# Check for handoff document
if [ -f "$FEATURE_DIR/sessions/latest-handoff.md" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Handoff Available"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    # Show handoff summary (first 20 lines)
    head -20 "$FEATURE_DIR/sessions/latest-handoff.md"
    echo ""
    echo "Full handoff: $FEATURE_DIR/sessions/latest-handoff.md"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

# Start new session
bash .spec-flow/scripts/bash/session-manager.sh start 2>/dev/null || true
```

### Step 1: Detect feature workspace and branch

```bash
# Run detection utility to find feature workspace
WORKFLOW_INFO=$(bash .spec-flow/scripts/utils/detect-workflow-paths.sh 2>/dev/null || pwsh -File .spec-flow/scripts/utils/detect-workflow-paths.ps1 2>/dev/null)

   if [ $? -eq 0 ]; then
       WORKFLOW_TYPE=$(echo "$WORKFLOW_INFO" | jq -r '.type')
       BASE_DIR=$(echo "$WORKFLOW_INFO" | jq -r '.base_dir')
       SLUG=$(echo "$WORKFLOW_INFO" | jq -r '.slug')
       CURRENT_BRANCH=$(echo "$WORKFLOW_INFO" | jq -r '.branch')

       # Verify this is a feature workflow
       if [ "$WORKFLOW_TYPE" != "feature" ]; then
           echo "❌ Error: This is an $WORKFLOW_TYPE workflow, not a feature"
           echo "   Use /epic continue for epic workflows"
           exit 1
       fi

       # Check if on correct feature branch
       if [[ "$CURRENT_BRANCH" =~ ^feature/ ]]; then
           echo "✓ Detected feature branch: $CURRENT_BRANCH"
       else
           echo "⚠️  Warning: Not on a feature branch (current: $CURRENT_BRANCH)"
           echo "   Feature workspace detected at: specs/$SLUG"
       fi

       WORKFLOW_STATE_FILE="${BASE_DIR}/${SLUG}/state.yaml"
   else
       echo "❌ Error: Could not detect feature workspace"
       echo "   Run from project root with an active feature in specs/"
       exit 1
   fi
   ```

2. **Read state.yaml** to find current phase
3. Locate first phase with status `in_progress` or `failed`
4. Resume from that phase
5. If manual gate was pending, proceed past it
6. Continue workflow execution

7. **Check for iteration mode** (v3.0 - Feedback Loop Support):

   ```bash
   # Read iteration state
   CURRENT_ITERATION=$(yq eval '.iteration.current' "$WORKFLOW_STATE_FILE" 2>/dev/null || echo "1")

   if [ "$CURRENT_ITERATION" -gt 1 ]; then
       echo "🔄 Resuming Iteration $CURRENT_ITERATION"
       echo "   Gaps discovered during validation"
       echo "   Executing supplemental tasks only"
       echo ""

       # Show gap summary
       if [ -f "specs/$SLUG/gaps.md" ]; then
           IN_SCOPE_COUNT=$(yq eval '.gaps.in_scope_count' "$WORKFLOW_STATE_FILE" 2>/dev/null || echo "0")
           echo "   In-scope gaps: $IN_SCOPE_COUNT"
           echo "   Tasks generated: Check tasks.md (Iteration $CURRENT_ITERATION section)"
           echo ""
       fi

       # Resume from current phase in iteration workflow
       # Typically this will be "implement" phase after gap capture
       CURRENT_PHASE=$(yq eval '.phase' "$WORKFLOW_STATE_FILE" 2>/dev/null || echo "unknown")
       echo "   Resuming from: /$CURRENT_PHASE phase"
   fi
   ```

   **Iteration workflow resume logic:**

   - If iteration > 1 and phase = "implement": Execute supplemental tasks only
   - If iteration > 1 and phase = "optimize": Run iteration-specific quality gates
   - If iteration > 1 and phase = "ship-staging": Deploy iteration N to staging
   - After successful deployment: Loop back to validate-staging for convergence check

**State verification required:**

```bash
# Always read and quote actual state
cat $WORKFLOW_STATE_FILE
```

Never assume or fabricate phase status — always read the actual recorded state.
</continue_mode>

<error_handling>

## Failure Handling

**If any phase fails:**

1. Read error details from `state.yaml`
2. Check relevant log files in `specs/NNN-slug/`
3. Present clear error message with file paths
4. Suggest fixes based on error type
5. Instruct user to fix and run `/feature continue`

**Common failure modes:**

- **Spec ambiguity** → Run `/clarify` to resolve
- **Planning failures** → Check `plan.md` for missing context, review research findings
- **Implementation errors** → Check `error-log.md`, review task status in `tasks.md`
- **Quality gate failures** → Review `optimization-*.md` reports for specific issues
- **Deployment failures** → Check deployment logs, verify environment configuration

**Anti-Hallucination Rules:**

1. **Never claim phase completion without quoting `state.yaml`**

   - Always `Read` the file and print the actual recorded status

2. **Cite agent outputs**

   - When a phase finishes, paste the returned `{status, summary, stats}` keys

3. **Do not skip phases unless state marks them disabled**

   - Follow the recorded sequence; if required, run it

4. **Detect deployment model from repo**

   - Show evidence: `git branch -a`, presence of staging workflow files

5. **No fabricated summaries**
   - If an agent errors, show the error; don't invent success

**Why**: This prevents silent quality gaps and makes the workflow auditable against real artifacts.
</error_handling>

<workflow_tracking>

## State Management

All phases read/write `specs/<NNN-slug>/state.yaml`.

**Todo list example (staging-prod model):**

```javascript
TodoWrite({
  todos: [
    {
      content: "Parse args, initialize state",
      status: "completed",
      activeForm: "Initialized",
    },
    {
      content: "Phase 0: Specification",
      status: "pending",
      activeForm: "Creating spec",
    },
    {
      content: "Phase 0.5: Clarification (if needed)",
      status: "pending",
      activeForm: "Resolving clarifications",
    },
    {
      content: "Phase 1: Planning",
      status: "pending",
      activeForm: "Creating plan",
    },
    {
      content: "Phase 2: Task breakdown",
      status: "pending",
      activeForm: "Generating tasks",
    },
    {
      content: "Phase 3: Cross-artifact analysis",
      status: "pending",
      activeForm: "Validating artifacts",
    },
    {
      content: "Phase 4: Implementation",
      status: "pending",
      activeForm: "Implementing tasks",
    },
    {
      content: "Phase 5: Optimization",
      status: "pending",
      activeForm: "Optimizing code",
    },
    {
      content: "Phase 6: Ship to staging",
      status: "pending",
      activeForm: "Deploying to staging",
    },
    {
      content: "Phase 7: Ship to production",
      status: "pending",
      activeForm: "Deploying to production",
    },
    {
      content: "Phase 8: Finalize documentation",
      status: "pending",
      activeForm: "Finalizing documentation",
    },
  ],
});
```

**Rules**:

- Exactly one phase is `in_progress` at a time
- All phases execute automatically (true autopilot)
- Only blocks on critical failures: CI failures, security issues, quality gate failures, deployment errors
- Deployment phases adapt to model: `staging-prod`, `direct-prod`, or `local-only`
- Any blocker (test failure, build error, quality gate, CI failure) pauses workflow for user review
- Resume with `/feature continue` after fixing issues

**State.yaml tracking:**

```yaml
feature:
  number: NNN
  slug: feature-slug
  started_at: ISO_TIMESTAMP

phases:
  spec: completed|in_progress|failed
  plan: completed|in_progress|failed
  tasks: completed|in_progress|failed
  implement: completed|in_progress|failed
  optimize: completed|in_progress|failed
  ship: completed|in_progress|failed
  finalize: completed|in_progress|failed
```
  </workflow_tracking>

<success_criteria>
Feature workflow is complete when:

- ✅ Feature initialized with unique slug and directory structure
- ✅ All required phases executed in sequence
- ✅ All quality gates passed (tests, optimization, security, accessibility)
- ✅ Staging validation passed (automated checks)
- ✅ Feature deployed to production successfully
- ✅ Documentation finalized and merged
- ✅ `state.yaml` shows all phases with status `completed`
- ✅ No blocking failures or errors in state file
- ✅ GitHub issue updated to shipped status (if applicable)
</success_criteria>

<examples>
## Usage Examples

**Start next priority feature:**

```bash
/feature next
```

**Start feature from description:**

```bash
/feature "Add dark mode toggle to settings"
```

**Start feature from epic:**

```bash
/feature epic:aktr
```

**Start specific sprint in epic:**

```bash
/feature epic:aktr:sprint:S02
```

**Resume interrupted feature:**

```bash
/feature continue
```

**Lookup specific feature:**

```bash
/feature "user authentication"
```

</examples>

<philosophy>
## Design Principles

**State truth lives in `state.yaml`**

- Never guess; always read, quote, and update atomically
- State file is single source of truth for workflow status

**Phases are isolated**

- Each agent reads context from disk (NOTES.md, tasks.md, spec.md)
- Returns structured JSON with no hidden handoffs
- Clear boundaries prevent state drift

**True autopilot execution**

- All phases execute automatically without manual intervention
- Only blocks on critical failures: CI failures, security issues, quality gate failures
- Optimized for 3-person teams that trust the workflow

**Automatic quality gates**

- Automated validation at each phase transition
- No manual review gates - quality ensured by automated checks
- Staging validation runs automated E2E tests, Lighthouse, health checks

**Test in staging, not locally**

- All UI/UX, accessibility, performance, and integration testing in staging
- No local preview gate required
- Automated validation determines pass/fail

**Deployment model adapts**

- Detect `staging-prod`, `direct-prod`, or `local-only` from repo structure
- Adjust phases accordingly based on detected model

**Fail fast, fail loud**

- Record failures in state immediately
- Never pretend success
- Any blocker (CI failure, security issue, quality gate) pauses workflow
- Resume with `/feature continue` after fix
</philosophy>
