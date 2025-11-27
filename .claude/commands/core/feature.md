---
description: Execute feature development workflow from specification through production deployment with automated quality gates and manual approval checkpoints
argument-hint:
  [
    description|slug|continue|next|epic:<name>|epic:<name>:sprint:<num>|sprint:<num>,
  ]
allowed-tools: Bash(python .spec-flow/scripts/spec-cli.py:*), Bash(git:*), Read(specs/**), Read(state.yaml), Read(.github/**), SlashCommand(/spec), SlashCommand(/clarify), SlashCommand(/plan), SlashCommand(/tasks), SlashCommand(/design-*), SlashCommand(/analyze), SlashCommand(/implement), SlashCommand(/optimize), SlashCommand(/ship-staging), SlashCommand(/ship-prod), SlashCommand(/finalize), TodoWrite
version: 2.1
updated: 2025-11-20
---

<objective>
Orchestrate complete feature delivery through isolated phase agents with strict state tracking, explicit manual gates, and zero assumption drift.

**Command**: `/feature [feature description | slug | continue | next | epic:<name> | epic:<name>:sprint:<num> | sprint:<num>]`

**When to use**: From idea selection through production deployment. Pauses only at manual gates or blocking failures.

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
## User Input Handling

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

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

**Pause Point**: Review `spec.md` for completeness and accuracy.

- Verify all requirements captured
- Check for ambiguities or missing context
- Run `/feature continue` when approved to proceed to planning

**If ambiguity detected**, conditional clarification phase:

```bash
/clarify
```

### Phase 1: Planning (Manual Gate #2)

```bash
/plan
```

**Pause Point**: Review `plan.md` and `research.md` for technical approach.

- Verify architecture decisions
- Check for code reuse opportunities
- Validate technical feasibility
- Run `/feature continue` when approved

**After plan approval, workflow proceeds automatically through phases 2-6**

### Automatic Execution After Plan Approval

**Phase 2: Task Breakdown** (automatic):

```bash
/tasks
```

**Phase 2a-2c: Design Workflow** (UI features only, automatic):

```bash
/design-variations
/design-functional
/design-polish
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

**Three explicit pause points requiring human approval:**

### Gate #1: Specification Review (after /spec)

- Location: `specs/NNN-slug/spec.md`
- Checklist:
  - [ ] All requirements captured
  - [ ] Acceptance criteria clear
  - [ ] No ambiguities remaining
- Resume: `/feature continue`

### Gate #2: Planning Review (after /plan)

- Location: `specs/NNN-slug/plan.md`, `specs/NNN-slug/research.md`
- Checklist:
  - [ ] Technical approach sound
  - [ ] Architecture decisions justified
  - [ ] Code reuse opportunities identified
  - [ ] Dependencies documented
- Resume: `/feature continue`
- **Note**: After this gate, phases 2-6 execute automatically

### Gate #3: Staging Validation (after /ship-staging)

- Location: Staging environment URL (from deployment)
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
- Manual gates: Spec review (gate #1), Plan review (gate #2), Staging validation (gate #3)
- Auto-progression: After plan approval, phases 2-6 execute automatically
- Deployment phases adapt to model: `staging-prod`, `direct-prod`, or `local-only`
- Any blocker (test failure, build error, quality gate) pauses workflow for user review
  </workflow_tracking>

<success_criteria>
Feature workflow is complete when:

- ✅ Feature initialized with unique slug and directory structure
- ✅ All required phases executed in sequence
- ✅ Manual gates approved by user (spec, plan, staging validation)
- ✅ All quality gates passed (tests, optimization, security)
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

**Phases are isolated**

- Each agent reads context from disk (NOTES.md, tasks.md, spec.md)
- Returns structured JSON with no hidden handoffs
- Clear boundaries prevent state drift

**Manual gates are explicit**

- Three manual gates pause workflow for human review
- Each gate has clear checklist and resume command
- No automatic progression past manual gates

**Auto-progression after plan approval**

- After plan review, automatically execute: tasks → validate → implement → optimize → ship-staging
- Reduces manual intervention for execution phases

**Test in staging, not locally**

- All UI/UX, accessibility, performance, and integration testing in staging
- No local preview gate required

**Deployment model adapts**

- Detect `staging-prod`, `direct-prod`, or `local-only` from repo structure
- Adjust phases accordingly based on detected model

**Fail fast, fail loud**

- Record failures in state immediately
- Never pretend success
- Any blocker pauses workflow and requires `/feature continue` after fix
  </philosophy>
