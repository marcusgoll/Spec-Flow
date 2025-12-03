---
description: Execute feature development workflow from specification through production deployment with automated quality gates and manual approval checkpoints
argument-hint: [description|slug|continue|next|epic:<name>|epic:<name>:sprint:<num>|sprint:<num>] [--auto | --interactive | --no-input]
allowed-tools: Bash(python .spec-flow/scripts/spec-cli.py:*), Bash(git:*), Read(specs/**), Read(state.yaml), Read(.github/**), SlashCommand(/spec), SlashCommand(/clarify), SlashCommand(/plan), SlashCommand(/tasks), SlashCommand(/design-*), SlashCommand(/analyze), SlashCommand(/implement), SlashCommand(/optimize), SlashCommand(/ship-staging), SlashCommand(/ship-prod), SlashCommand(/finalize), TodoWrite
version: 3.0
updated: 2025-12-02
---

<objective>
Orchestrate complete feature delivery through isolated phase agents with strict state tracking, explicit manual gates, and zero assumption drift.

**Command**: `/feature [feature description | slug | continue | next | epic:<name> | epic:<name>:sprint:<num> | sprint:<num>] [--auto | --interactive | --no-input]`

**Flags**:

- `--auto`: Run in auto mode - bypass all interactive prompts except critical blockers (CI failures, security issues, deployment errors)
- `--interactive`: Force interactive mode - pause at spec review and plan review (overrides config/history)
- `--no-input`: Non-interactive mode for CI/CD - same as --auto but explicitly signals automation context

**When to use**: From idea selection through production deployment. Pauses only at manual gates (interactive mode) or blocking failures (auto mode).

**Architecture**:

- **Orchestrator** (`/feature`): Moves one phase at a time, updates `state.yaml`, never invents state
- **Phase Commands**: `/spec`, `/plan`, `/tasks`, `/implement`, `/optimize`, `/ship` execute isolated phases
- **Specialist Agents**: Implementation directly launches backend-dev, frontend-dev, database-architect in parallel

**Benefits**: Smaller token budgets per phase, faster execution, quality preserved by same slash commands and gates
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
## Step 0.1: Load User Preferences (3-Tier System)

**Determine execution mode using 3-tier preference system:**

1. **Load configuration file** (Tier 1 - lowest priority):

   ```powershell
   # Load from .spec-flow/config/user-preferences.yaml
   $preferences = & .spec-flow/scripts/utils/load-preferences.ps1 -Command "feature"
   $configMode = $preferences.commands.feature.default_mode  # "interactive" or "auto"
   ```

2. **Load command history** (Tier 2 - medium priority, overrides config):

   ```powershell
   # Load from .spec-flow/memory/command-history.yaml
   $history = & .spec-flow/scripts/utils/load-command-history.ps1 -Command "feature"

   if ($history.last_used_mode -and $history.total_uses -gt 0) {
       $preferredMode = $history.last_used_mode  # Use learned preference
       $usageStats = $history.usage_count  # For display: "used 8/10 times"
   } else {
       $preferredMode = $configMode  # Fall back to config
   }
   ```

3. **Check command-line flags** (Tier 3 - highest priority, overrides everything):

   ```javascript
   const args = "$ARGUMENTS".trim();
   const hasAutoFlag = args.includes("--auto");
   const hasInteractiveFlag = args.includes("--interactive");
   const hasNoInput = args.includes("--no-input");
   const featureDescription = args
     .replace(/--auto|--interactive|--no-input/g, "")
     .trim();

   let selectedMode;

   if (hasNoInput || hasAutoFlag) {
     selectedMode = "auto"; // CI/automation override
   } else if (hasInteractiveFlag) {
     selectedMode = "interactive"; // Explicit interactive override
   } else {
     selectedMode = $preferredMode; // Use config/history preference
   }
   ```

4. **If no explicit override, ask user with smart suggestions:**

   Only prompt if no flag provided and not in CI mode. Use AskUserQuestion with learned preferences:

   ```javascript
   AskUserQuestion({
     questions: [{
       question: "How should this feature workflow run?",
       header: "Mode",
       multiSelect: false,
       options: [
         {
           label: history.last_used_mode === "auto"
             ? "Auto (last used) ⭐"
             : "Auto",
           description: "Skip spec/plan reviews, run until blocker"
         },
         {
           label: history.last_used_mode === "interactive"
             ? "Interactive (last used) ⭐"
             : "Interactive",
           description: "Pause at spec review and plan review"
         }
       ]
     }]
   });
   ```

   **Smart defaults behavior:**

   - If `preferences.commands.feature.skip_mode_prompt === true` AND default_mode is set: Use configured default without asking
   - If `preferences.ui.recommend_last_used === true`: Mark last-used option with ⭐
   - If user has strong preference (>80% usage of one mode): Can auto-select without prompting
   - Otherwise: Always prompt user to choose

   **Skip prompt when preference is clear:**

   ```javascript
   const skipPrompt =
     preferences.commands?.feature?.skip_mode_prompt === true ||
     (history.total_uses >= 5 &&
      (history.usage_count.auto / history.total_uses > 0.8 ||
       history.usage_count.interactive / history.total_uses > 0.8));

   if (skipPrompt) {
     selectedMode = preferredMode;  // Use learned/configured preference
     console.log(`Using ${selectedMode} mode (from preferences)`);
   } else {
     // Show AskUserQuestion prompt above
   }
   ```

5. **Track usage for learning system:**

   ```powershell
   # Display selected mode
   if ($selectedMode -eq 'auto') {
       "🤖 Auto-mode enabled - will run automatically until blocker"
   } else {
       "📋 Interactive mode - will pause at reviews"
   }

   # Track this usage for learning system
   & .spec-flow/scripts/utils/track-command-usage.ps1 -Command "feature" -Mode $selectedMode
   ```

**If auto-mode selected:**

- Bypass all PAUSE points (spec review, plan review)
- Only stop for critical blockers: CI failures, security issues, deployment errors, staging validation

**If interactive mode selected:**

- Follow standard workflow with manual PAUSE points at spec and plan review

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
2. Execute workflow phases based on current state
3. Handle manual gates appropriately
4. Resume from correct phase if using `continue` mode
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

### Phase 0: Specification (Manual Gate #1)

```bash
/spec
```

**Interactive Mode - Pause Point**: Review `spec.md` for completeness and accuracy.

- Verify all requirements captured
- Check for ambiguities or missing context
- Run `/feature continue` when approved to proceed to planning

**Auto Mode**: Skip pause, proceed directly to clarification check and planning.

**If ambiguity detected**, conditional clarification phase:

```bash
/clarify
```

### Phase 1: Planning (Manual Gate #2)

```bash
/plan
```

**Interactive Mode - Pause Point**: Review `plan.md` and `research.md` for technical approach.

- Verify architecture decisions
- Check for code reuse opportunities
- Validate technical feasibility
- Run `/feature continue` when approved

**Auto Mode**: Skip pause, proceed directly to task breakdown.

**After plan approval (or auto-skip), workflow proceeds automatically through phases 2-6**

### Automatic Execution After Plan Approval

**Phase 2: Task Breakdown** (automatic):

```bash
/tasks
```

**Phase 3: Cross-Artifact Analysis** (automatic):

```bash
/analyze
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

<manual_gates>

## Manual Approval Gates

**Three explicit pause points requiring human approval (Interactive Mode only):**

**In Auto Mode**: Gates #1 and #2 are auto-skipped. Gate #3 (Staging Validation) always requires validation but runs automated checks.

### Gate #1: Specification Review (after /spec)

- Location: `specs/NNN-slug/spec.md`
- **Interactive Mode**: Pause for human review
- **Auto Mode**: Auto-skipped (status: `auto_skipped` in state.yaml)
- Checklist:
  - [ ] All requirements captured
  - [ ] Acceptance criteria clear
  - [ ] No ambiguities remaining
- Resume: `/feature continue`

### Gate #2: Planning Review (after /plan)

- Location: `specs/NNN-slug/plan.md`, `specs/NNN-slug/research.md`
- **Interactive Mode**: Pause for human review
- **Auto Mode**: Auto-skipped (status: `auto_skipped` in state.yaml)
- Checklist:
  - [ ] Technical approach sound
  - [ ] Architecture decisions justified
  - [ ] Code reuse opportunities identified
  - [ ] Dependencies documented
- Resume: `/feature continue`
- **Note**: After this gate, phases 2-6 execute automatically

### Gate #3: Staging Validation (after /ship-staging)

- Location: Staging environment URL (from deployment)
- **Both Modes**: Runs automated validation (E2E tests, Lighthouse, health checks)
- **Interactive Mode**: Pauses for additional manual testing
- **Auto Mode**: Proceeds after automated checks pass (blocks only on failures)
- Checklist:
  - [ ] UI/UX tested across browsers and devices
  - [ ] Accessibility verified (keyboard nav, screen readers)
  - [ ] Performance acceptable (load times, responsiveness)
  - [ ] Integration with existing features working
  - [ ] Error handling and edge cases validated
- Resume: `/feature continue` to promote to production
  </manual_gates>

<continue_mode>

## Resuming Interrupted Features

When running `/feature continue`:

1. **Detect feature workspace and branch:**

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
      content: "Manual gate: Spec review",
      status: "pending",
      activeForm: "Awaiting spec approval",
    },
    {
      content: "Phase 0.5: Clarification (conditional)",
      status: "pending",
      activeForm: "Resolving clarifications",
    },
    {
      content: "Phase 1: Planning",
      status: "pending",
      activeForm: "Creating plan",
    },
    {
      content: "Manual gate: Plan review",
      status: "pending",
      activeForm: "Awaiting plan approval",
    },
    {
      content: "Phase 2: Task breakdown (auto)",
      status: "pending",
      activeForm: "Generating tasks",
    },
    {
      content: "Phase 2a–2c: Design workflow (UI only, auto)",
      status: "pending",
      activeForm: "Running design workflow",
    },
    {
      content: "Phase 3: Cross-artifact analysis (auto)",
      status: "pending",
      activeForm: "Validating artifacts",
    },
    {
      content: "Phase 4: Implementation (auto)",
      status: "pending",
      activeForm: "Implementing tasks",
    },
    {
      content: "Phase 5: Optimization (auto)",
      status: "pending",
      activeForm: "Optimizing code",
    },
    {
      content: "Phase 6: Ship to staging (auto)",
      status: "pending",
      activeForm: "Deploying to staging",
    },
    {
      content: "Manual gate: Staging validation",
      status: "pending",
      activeForm: "Awaiting staging approval",
    },
    {
      content: "Phase 7: Ship to production",
      status: "pending",
      activeForm: "Deploying to production",
    },
    {
      content: "Phase 8: Finalize documentation (auto)",
      status: "pending",
      activeForm: "Finalizing documentation",
    },
  ],
});
```

**Rules**:

- Exactly one phase is `in_progress` at a time
- **Interactive Mode**: Manual gates pause at spec review (gate #1), plan review (gate #2), staging validation (gate #3)
- **Auto Mode**: Gates #1 and #2 auto-skipped; only blocks on critical failures or gate #3 automated checks
- Auto-progression: After plan approval (or auto-skip), phases 2-6 execute automatically
- Deployment phases adapt to model: `staging-prod`, `direct-prod`, or `local-only`
- Any blocker (test failure, build error, quality gate, CI failure) pauses workflow for user review

**State.yaml auto_mode tracking:**

```yaml
feature:
  number: NNN
  slug: feature-slug
  auto_mode: true|false  # Tracks execution mode
  started_at: ISO_TIMESTAMP

manual_gates:
  spec_review:
    status: pending|approved|auto_skipped
    blocking: true|false  # false if auto_mode
  plan_review:
    status: pending|approved|auto_skipped
    blocking: true|false  # false if auto_mode
  staging_validation:
    status: pending|passed|failed
    blocking: true  # Always blocking
```
  </workflow_tracking>

<success_criteria>
Feature workflow is complete when:

- ✅ Feature initialized with unique slug and directory structure
- ✅ All required phases executed in sequence
- ✅ Manual gates approved by user OR auto-skipped (spec, plan)
- ✅ Staging validation passed (automated checks in auto-mode, manual review in interactive)
- ✅ All quality gates passed (tests, optimization, security)
- ✅ Feature deployed to production successfully
- ✅ Documentation finalized and merged
- ✅ `state.yaml` shows all phases with status `completed`
- ✅ `state.yaml` manual_gates show `approved` or `auto_skipped`
- ✅ No blocking failures or errors in state file
- ✅ GitHub issue updated to shipped status (if applicable)
  </success_criteria>

<examples>
## Usage Examples

**Start next priority feature (interactive):**

```bash
/feature next
```

**Start feature in auto-mode (no manual pauses):**

```bash
/feature "Add dark mode toggle" --auto
```

**Force interactive mode (overrides config/history):**

```bash
/feature "User authentication" --interactive
```

**CI/CD non-interactive mode:**

```bash
/feature next --no-input
```

**Start feature from epic:**

```bash
/feature epic:aktr
```

**Start specific sprint in epic (auto-mode):**

```bash
/feature epic:aktr:sprint:S02 --auto
```

**Resume interrupted feature:**

```bash
/feature continue
```

**Lookup specific feature:**

```bash
/feature "user authentication"
```

**Start from feature description:**

```bash
/feature "Add dark mode toggle to settings"
```

</examples>

<philosophy>
## Design Principles

**State truth lives in `state.yaml`**

- Never guess; always read, quote, and update atomically
- State file is single source of truth for workflow status
- `auto_mode` field tracks execution mode for entire feature lifecycle

**Phases are isolated**

- Each agent reads context from disk (NOTES.md, tasks.md, spec.md)
- Returns structured JSON with no hidden handoffs
- Clear boundaries prevent state drift

**Manual gates are mode-dependent**

- **Interactive Mode**: Three manual gates pause for human review (spec, plan, staging)
- **Auto Mode**: Gates #1 and #2 auto-skipped; only critical blockers pause execution
- 3-tier preference system: config → history → flags (highest priority)
- User preference learned from usage history

**Auto-progression after plan approval (or auto-skip)**

- After plan review (or auto-skip), automatically execute: tasks → validate → implement → optimize → ship-staging
- Reduces manual intervention for execution phases
- Auto mode enables full automation for CI/CD pipelines

**Test in staging, not locally**

- All UI/UX, accessibility, performance, and integration testing in staging
- No local preview gate required
- Auto mode runs automated validation; interactive mode adds manual testing

**Deployment model adapts**

- Detect `staging-prod`, `direct-prod`, or `local-only` from repo structure
- Adjust phases accordingly based on detected model

**Fail fast, fail loud**

- Record failures in state immediately
- Never pretend success
- Any blocker (CI failure, security issue, quality gate) pauses workflow
- Resume with `/feature continue` after fix
  </philosophy>
