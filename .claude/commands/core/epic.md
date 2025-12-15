---
description: Execute multi-sprint epic workflow from interactive scoping through deployment with parallel sprint execution and self-improvement
argument-hint: "[epic description | slug | continue | next] [--deep | --auto]"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task, AskUserQuestion, TodoWrite, SlashCommand, Skill
version: 7.1
updated: 2025-12-14
---

<objective>
Orchestrate multi-sprint epic delivery through **isolated phase agents spawned via Task()** with parallel sprint execution and comprehensive quality gates.

**Command**: `/epic [epic description | slug | continue | next]`

**CRITICAL ARCHITECTURE** (v7.0 - Domain Memory v2):

This orchestrator is **ultra-lightweight**. You MUST:
1. Read state from disk (state.yaml, interaction-state.yaml, domain-memory.yaml)
2. Spawn isolated phase agents via **Task tool** - NEVER execute phases inline
3. Handle user Q&A when agents return questions
4. Update state.yaml after each phase
5. NEVER carry implementation details in your context

**Key Difference from /feature**:
- Epic creates sprint-level domain-memory.yaml files for parallel execution
- Implementation spawns multiple workers across sprints simultaneously
- More sophisticated dependency tracking between sprints

**Benefits**: Unlimited epic complexity, 3-5x faster delivery via parallelism, observable progress, resumable at any point.
</objective>

<context>
**User Input**: $ARGUMENTS

**Project State**: !`test -d docs/project && echo "initialized" || echo "missing"`

**Git Configuration**:
- Remote: !`git remote -v 2>/dev/null | head -1 | grep -q origin && echo "configured" || echo "none"`
- Current branch: !`git branch --show-current 2>/dev/null || echo "none"`
- Staging workflow: !`test -f .github/workflows/deploy-staging.yml && echo "present" || echo "missing"`

**Epic Workspace**: !`ls -d epics/*/ 2>/dev/null | head -3 || echo "none"`

**Workflow State**: @epics/*/state.yaml

**Planning Depth Preference**: !`bash .spec-flow/scripts/utils/load-preferences.sh --key "planning.auto_deep_mode" --default "false" 2>/dev/null || echo "false"`

**Epic Trigger for Deep Planning**: !`bash .spec-flow/scripts/utils/load-preferences.sh --key "planning.deep_planning_triggers.epic_features" --default "true" 2>/dev/null || echo "true"`

**Auto-ship preference**: !`bash .spec-flow/scripts/utils/load-preferences.sh --key "deployment.auto_ship" --default "false" 2>/dev/null || echo "false"`

**Auto-merge preference**: !`bash .spec-flow/scripts/utils/load-preferences.sh --key "deployment.auto_merge" --default "false" 2>/dev/null || echo "false"`

**Auto-finalize preference**: !`bash .spec-flow/scripts/utils/load-preferences.sh --key "deployment.auto_finalize" --default "true" 2>/dev/null || echo "true"`

**Studio context (multi-agent isolation)**: !`bash .spec-flow/scripts/bash/worktree-context.sh studio-detect 2>/dev/null || echo ""`

**Worktree context**: !`bash .spec-flow/scripts/bash/worktree-context.sh info 2>/dev/null || echo '{"is_worktree": false}'`
</context>

<planning_depth>
## Planning Depth Mode for Epics

**NOTE**: Epics automatically trigger ultrathink/deep planning by default via `deep_planning_triggers.epic_features: true`.

**Flags in $ARGUMENTS**:
- `--deep` → Explicitly force ultrathink (redundant for epics, but explicit)
- `--auto` → Use preferences AND continue through ship→finalize without stopping
- Neither → Interactive mode, still uses deep planning for epics

**Epic-specific benefits of ultrathink**:
- Assumption questioning across multiple sprints
- Codebase soul analysis informs sprint boundaries
- Minimum viable architecture prevents over-engineering
- Design alternatives help sprint prioritization

**State tracking**:
```yaml
# In epics/NNN-slug/state.yaml
planning:
  mode: deep
  ultrathink_enabled: true
  triggered_by: epic_features  # or explicit_flag
```
</planning_depth>

<auto_mode>
## Auto Mode (--auto flag) for Epics

When `--auto` flag is present, the epic workflow runs end-to-end without stopping:

**Full auto-mode behavior** (when `--auto` flag is set):
1. **Planning**: Use deep planning (epics always trigger ultrathink)
2. **Implementation**: Execute all sprints in parallel per dependency layers
3. **Ship**: Check CI, auto-merge when passing (if `deployment.auto_merge: true`)
4. **Finalize**: Run /finalize automatically with epic walkthrough generation

**Preference-controlled auto-ship** (v11.7):
- `deployment.auto_ship: true` → Continue from optimize → ship → finalize without stopping
- `deployment.auto_merge: true` → Auto-merge PR when CI passes (no production approval prompt)
- `deployment.auto_finalize: true` → Run /finalize automatically after successful deployment

**Parse --auto flag at start**:
```bash
AUTO_MODE="false"
if [[ "$ARGUMENTS" == *"--auto"* ]]; then
  AUTO_MODE="true"
  AUTO_SHIP=$(bash .spec-flow/scripts/utils/load-preferences.sh --key "deployment.auto_ship" --default "false" 2>/dev/null || echo "false")
  AUTO_MERGE=$(bash .spec-flow/scripts/utils/load-preferences.sh --key "deployment.auto_merge" --default "false" 2>/dev/null || echo "false")
  AUTO_FINALIZE=$(bash .spec-flow/scripts/utils/load-preferences.sh --key "deployment.auto_finalize" --default "true" 2>/dev/null || echo "true")
fi
```

**State tracking**:
```yaml
# In epics/NNN-slug/state.yaml
auto_mode:
  enabled: true
  auto_ship: true   # Continue optimize → ship → finalize
  auto_merge: true  # Auto-merge when CI passes
  auto_finalize: true
```
</auto_mode>

<studio_mode>
## Studio Mode (Multi-Agent Isolation) (v11.8)

When running in a studio worktree (`worktrees/studio/agent-N/`), the epic workflow automatically:

1. **Detects studio context** - Auto-detected from working directory
2. **Namespaces branches** - `studio/agent-N/epic/XXX-slug` instead of `epic/XXX-slug`
3. **Creates PRs for merging** - Studio agents always create PRs (like a real dev team)
4. **Prevents git conflicts** - Each agent has isolated branches

**Detection (automatic, no user action needed):**
```bash
STUDIO_AGENT=$(bash .spec-flow/scripts/bash/worktree-context.sh studio-detect 2>/dev/null || echo "")
IS_STUDIO_MODE=$([[ -n "$STUDIO_AGENT" ]] && echo "true" || echo "false")
```

**Branch naming in studio mode:**
```bash
# Get namespaced branch (handles studio detection automatically)
BRANCH=$(bash .spec-flow/scripts/bash/worktree-context.sh studio-branch "epic" "$SLUG" 2>/dev/null)
# Returns: "studio/agent-1/epic/001-auth" in studio mode
# Returns: "epic/001-auth" in normal mode
```

**State tracking (in state.yaml):**
```yaml
studio:
  enabled: true
  agent_id: agent-1
  branch_namespace: studio/agent-1
  merge_strategy: pr  # Always PR in studio mode
```

**Ship behavior in studio mode:**
- Always creates PR instead of direct merge
- PR targets `main` branch from `studio/agent-N/epic/XXX-slug`
- Auto-merge enabled via GitHub branch protection (no manual review needed)
- CI gates validate the change before merge
</studio_mode>

<process>

## PHASE 0.5: Worktree Safety Check (v11.8)

**Before any work, verify we're in a safe location.**

### Step 0.5.1: Check Root Safety

```bash
SAFETY_CHECK=$(bash .spec-flow/scripts/bash/worktree-context.sh check-safety 2>/dev/null || echo '{"safe": true}')
IS_SAFE=$(echo "$SAFETY_CHECK" | jq -r '.safe')
ACTION=$(echo "$SAFETY_CHECK" | jq -r '.action')
```

### Step 0.5.2: Handle Safety Check Result

**If IS_SAFE is false AND ACTION is "switch_to_worktree" (strict mode):**

Parse active worktrees and display switch instructions:
```bash
ACTIVE_WORKTREES=$(echo "$SAFETY_CHECK" | jq -r '.active_worktrees')
```

Output:
```
════════════════════════════════════════════════════════════════════════════════
⚠️  WORKTREE ISOLATION ACTIVE
════════════════════════════════════════════════════════════════════════════════

You're in the root repository with active feature/epic worktrees.
For safety, changes should be made from within the appropriate worktree.

Active worktrees:
${FOR EACH worktree in ACTIVE_WORKTREES}
  • ${worktree.type}/${worktree.slug} (phase: ${worktree.phase})
    Path: ${worktree.path}
${END FOR}

Options:
  1. Switch to an existing worktree: cd [path] && claude
  2. Start a NEW epic (will create new worktree): proceed with /epic "new description"

════════════════════════════════════════════════════════════════════════════════
```

**If argument is NOT "continue" and NOT empty (starting new epic):**
- Proceed to PHASE 1 (new epic will get its own worktree)

**If argument is "continue":**
- Use AskUserQuestion to ask which worktree to switch to
- Display switch instructions and STOP (user must run from worktree)

**If IS_SAFE is false AND ACTION is "prompt_user" (prompt mode):**

Use AskUserQuestion:
```
Question: "Active worktrees detected. Where would you like to work?"
Header: "Workspace"
Options:
  - label: "Switch to existing worktree"
    description: "Continue work in an existing feature/epic worktree"
  - label: "Start new epic here"
    description: "Create a new worktree for this epic"
  - label: "Work in root (unsafe)"
    description: "Make changes directly in root (not recommended)"
```

Handle user choice accordingly.

**If IS_SAFE is true:**
- Proceed to PHASE 1

---

## PHASE 1: Initialize Epic Workspace

**User Input:**
```text
$ARGUMENTS
```

### Step 1.1: Parse Arguments, Detect Mode, and Studio Context

Determine the mode from arguments:
- If argument is "continue" → Resume mode (skip to PHASE 1.5)
- If argument is "next" → Select from backlog
- If argument starts with slug/number → Lookup mode
- Otherwise → New epic creation

**Detect studio context (v11.8):**
```bash
STUDIO_AGENT=$(bash .spec-flow/scripts/bash/worktree-context.sh studio-detect 2>/dev/null || echo "")
IS_STUDIO_MODE="false"
if [[ -n "$STUDIO_AGENT" ]]; then
  IS_STUDIO_MODE="true"
  echo "Studio mode: $STUDIO_AGENT"
fi
```

**Get studio-aware branch name:**
```bash
# Auto-detects studio context and namespaces branch appropriately
BRANCH=$(bash .spec-flow/scripts/bash/worktree-context.sh studio-branch "epic" "$SLUG" 2>/dev/null)
# Returns: "studio/agent-1/epic/001-auth" in studio mode
# Returns: "epic/001-auth" in normal mode
```

### Step 1.2: Create Epic Workspace (New Epic)

For new epics, run the epic creation script:

```bash
bash .spec-flow/scripts/bash/create-new-epic.sh --json "$ARGUMENTS"
```

After the script completes, read the created state file:

```bash
EPIC_DIR=$(ls -td epics/[0-9]*-* 2>/dev/null | head -1)
echo "Epic directory: $EPIC_DIR"
cat "$EPIC_DIR/state.yaml"
```

### Step 1.3: Initialize Interaction State

```bash
bash .spec-flow/scripts/bash/interaction-manager.sh init "$EPIC_DIR"
```

### Step 1.3.5: Store Studio Context in State (v11.8)

If in studio mode, record it in state.yaml:
```bash
if [ "$IS_STUDIO_MODE" = "true" ]; then
  yq eval '.studio.enabled = true' -i "$EPIC_DIR/state.yaml"
  yq eval '.studio.agent_id = "'$STUDIO_AGENT'"' -i "$EPIC_DIR/state.yaml"
  yq eval '.studio.branch_namespace = "studio/'$STUDIO_AGENT'"' -i "$EPIC_DIR/state.yaml"
  yq eval '.studio.merge_strategy = "pr"' -i "$EPIC_DIR/state.yaml"
fi
```

### Step 1.4: Display Autopilot Banner

Output this to the user (with studio context if active):
```
════════════════════════════════════════════════════════════════════════════════
🤖 EPIC AUTOPILOT - Domain Memory v2 with Parallel Sprints
════════════════════════════════════════════════════════════════════════════════
All phases execute via isolated Task() agents
Sprint execution parallelized via dependency graph
Progress tracked in: $EPIC_DIR/state.yaml
Questions batched and asked in main context
Resume anytime with: /epic continue
${IS_STUDIO_MODE == "true" ? "
Studio Agent: $STUDIO_AGENT
Branch: $BRANCH (namespaced for multi-agent isolation)
Merge strategy: PR (auto-merge when CI passes)
" : ""}════════════════════════════════════════════════════════════════════════════════
```

### Step 1.5: Continue Mode (Resume)

If argument was "continue":

```bash
WORKFLOW_INFO=$(bash .spec-flow/scripts/utils/detect-workflow-paths.sh 2>/dev/null)
EPIC_DIR=$(echo "$WORKFLOW_INFO" | jq -r '"\(.base_dir)/\(.slug)"')
echo "Resuming epic: $EPIC_DIR"
cat "$EPIC_DIR/state.yaml"
```

Check for pending questions and resume from current phase.

---

## PHASE 2: Domain Memory Initialization

**YOU MUST spawn the Initializer agent via Task tool.**

Check if domain-memory.yaml exists:
```bash
EPIC_DIR=$(ls -td epics/[0-9]*-* 2>/dev/null | head -1)
test -f "$EPIC_DIR/domain-memory.yaml" && echo "EXISTS" || echo "MISSING"
```

**If MISSING, use the Task tool with these EXACT parameters:**

```
Task tool call:
  subagent_type: "initializer"
  description: "Initialize epic domain memory"
  prompt: |
    Initialize domain memory for this EPIC.

    Epic directory: [insert EPIC_DIR value]
    Description: [insert epic description from state.yaml]
    Workflow type: epic

    Your task:
    1. Read the epic description from state.yaml
    2. Expand it into high-level goals (epic-level domain-memory.yaml)
    3. Create placeholder structure for sprint-level domain memory
    4. EXIT immediately after creating the file - do NOT implement anything

    Note: Sprint-level domain-memory.yaml files will be created after /plan phase
    determines the actual sprints.

    Return a summary of what was initialized.
```

After the Task completes, verify domain-memory.yaml was created:
```bash
cat "$EPIC_DIR/domain-memory.yaml"
```

---

## PHASE 3: Execute Phase Loop

**CRITICAL: You MUST spawn each phase as an isolated Task() agent. NEVER execute phase logic inline.**

### Epic Phase Configuration

| Phase | Agent Type | Next Phase | Notes |
|-------|------------|------------|-------|
| spec | spec-phase-agent | clarify | Creates epic-spec.md |
| clarify | clarify-phase-agent | plan | Optional, if ambiguity detected |
| plan | plan-phase-agent | tasks | Creates plan.md + sprint-plan.md |
| tasks | tasks-phase-agent | analyze | Creates tasks.md for all sprints |
| analyze | analyze-phase-agent | implement | Validates artifacts |
| implement | SlashCommand(/implement-epic) | optimize | **Delegates to parallel sprint execution** |
| optimize | optimize-phase-agent | ship | Runs quality gates |
| ship | ship-staging-phase-agent | finalize | Deploys to staging/prod |
| finalize | finalize-phase-agent | complete | Generates walkthrough.md |

### For Each Phase, Follow This Exact Pattern:

#### Step 3.1: Read Current State

```bash
EPIC_DIR=$(ls -td epics/[0-9]*-* 2>/dev/null | head -1)
CURRENT_PHASE=$(yq eval '.phase' "$EPIC_DIR/state.yaml")
echo "Current phase: $CURRENT_PHASE"
```

#### Step 3.2: Check for Pending Answers

```bash
PENDING=$(bash .spec-flow/scripts/bash/interaction-manager.sh get-pending "$EPIC_DIR" 2>/dev/null)
echo "Pending questions: $PENDING"
```

#### Step 3.3: Spawn Phase Agent via Task Tool

**YOU MUST use the Task tool. Example for spec phase:**

```
Task tool call:
  subagent_type: "spec-phase-agent"
  description: "Execute epic spec phase"
  prompt: |
    Execute the SPEC phase for this EPIC.

    Epic directory: [EPIC_DIR]
    Workflow type: epic

    Instructions:
    1. Read state.yaml to understand the epic
    2. Research the codebase for existing patterns
    3. Generate epic-spec.md with requirements and sprint breakdown hints
    4. If you need user input, return a structured response (see below)
    5. If complete, return success status

    IMPORTANT: If you need to ask the user questions, DO NOT use AskUserQuestion.
    Instead, return this structured response and EXIT:

    ---NEEDS_INPUT---
    questions:
      - id: Q001
        question: "What type of epic is this?"
        header: "Epic Type"
        multi_select: false
        options:
          - label: "New feature"
            description: "Brand new functionality"
          - label: "Enhancement"
            description: "Improve existing features"
          - label: "Refactoring"
            description: "Improve code structure"
    resume_from: "after_scoping"
    ---END_NEEDS_INPUT---

    If complete, return:
    ---COMPLETED---
    artifacts_created:
      - path: epic-spec.md
        type: specification
    summary: "Created epic specification with N subsystems identified"
    next_phase: plan
    ---END_COMPLETED---
```

#### Step 3.4: Handle Agent Result

**If agent returned NEEDS_INPUT:**

1. Parse the questions from the agent's response
2. Use AskUserQuestion tool to ask the user (you CAN use this in main context)
3. Save answers:
   ```bash
   bash .spec-flow/scripts/bash/interaction-manager.sh save-answers "$EPIC_DIR" '[answers JSON]'
   ```
4. Re-spawn the SAME phase agent with answers included in prompt

**If agent returned COMPLETED:**

1. Update state.yaml:
   ```bash
   yq eval '.phases.[PHASE_NAME] = "completed"' -i "$EPIC_DIR/state.yaml"
   yq eval '.phase = "[NEXT_PHASE]"' -i "$EPIC_DIR/state.yaml"
   ```
2. Mark phase complete:
   ```bash
   bash .spec-flow/scripts/bash/interaction-manager.sh mark-phase-complete "$EPIC_DIR" "[PHASE_NAME]"
   ```
3. Proceed to next phase

**If agent returned FAILED:**

1. Update state.yaml:
   ```bash
   yq eval '.phases.[PHASE_NAME] = "failed"' -i "$EPIC_DIR/state.yaml"
   yq eval '.status = "failed"' -i "$EPIC_DIR/state.yaml"
   ```
2. Output error message to user
3. Instruct user to fix and run `/epic continue`
4. STOP the workflow

---

## PHASE 4: Planning Phase (Sprint Breakdown)

When the plan phase completes, it should create:
- `plan.md` - Architecture and approach
- `sprint-plan.md` - Sprint breakdown with dependency graph

**After plan phase, create sprint-level domain memory:**

```bash
# Read sprint count from sprint-plan.md
SPRINT_COUNT=$(grep -c "^## Sprint S" "$EPIC_DIR/sprint-plan.md" || echo "0")

# Create sprint directories with domain-memory.yaml
for i in $(seq -w 1 $SPRINT_COUNT); do
    SPRINT_DIR="$EPIC_DIR/sprints/S$i"
    mkdir -p "$SPRINT_DIR"

    if [ ! -f "$SPRINT_DIR/domain-memory.yaml" ]; then
        # Spawn initializer for each sprint
        echo "Creating domain-memory for Sprint S$i..."
    fi
done
```

For each sprint without domain-memory.yaml, spawn initializer:

```
Task tool call:
  subagent_type: "initializer"
  description: "Initialize sprint domain memory"
  prompt: |
    Initialize domain memory for Sprint S[N] of this epic.

    Epic directory: [EPIC_DIR]
    Sprint directory: [EPIC_DIR]/sprints/S[N]
    Sprint plan: Read from [EPIC_DIR]/sprint-plan.md

    Extract features for Sprint S[N] and create sprint-level domain-memory.yaml.
    EXIT immediately after creating the file.
```

---

## PHASE 5: Implementation Phase (Delegation)

**The implement phase delegates to `/implement-epic` for parallel sprint execution.**

When current phase is "implement":

### Step 5.1: Delegate to /implement-epic

**Use SlashCommand to invoke the dedicated sprint orchestrator:**

```
SlashCommand:
  command: "/implement-epic"
```

The `/implement-epic` command handles:
- Reading sprint dependencies from sprint-plan.md
- Executing sprints layer by layer (parallel within layers)
- Spawning workers for each sprint
- Waiting for layer completion
- Validating results and contract compliance
- Updating state when complete

See `.claude/commands/epic/implement-epic.md` for full implementation details.

### Step 5.2: Handle Result

**If /implement-epic completes successfully:**
- State will be updated to phase: optimize
- Proceed to PHASE 6 (quality gates)

**If /implement-epic fails:**
- Error will be reported with specific sprint that failed
- User instructed to fix and run `/epic continue`
- Workflow stops until issue resolved

---

## PHASE 5.5: Auto-Mode Ship and Finalize (v11.7)

**When optimize phase completes in auto mode, continue through ship and finalize automatically.**

Check for auto-mode after optimize phase completes:
```bash
AUTO_MODE=$(yq eval '.auto_mode.enabled // false' "$EPIC_DIR/state.yaml")
AUTO_SHIP=$(yq eval '.auto_mode.auto_ship // false' "$EPIC_DIR/state.yaml")
AUTO_MERGE=$(yq eval '.auto_mode.auto_merge // false' "$EPIC_DIR/state.yaml")
AUTO_FINALIZE=$(yq eval '.auto_mode.auto_finalize // true' "$EPIC_DIR/state.yaml")
```

**If optimize phase just completed AND auto_mode is enabled:**

### Step 5.5.1: Proceed to Ship Phase Automatically

```
SlashCommand:
  command: "/ship --auto"
```

The `--auto` flag tells /ship to:
- Skip production approval prompt
- Auto-merge PR when CI passes (if `auto_merge: true`)
- Continue to finalize automatically

### Step 5.5.2: After Ship Completes, Proceed to Finalize

If `/ship` returns successfully and `auto_finalize: true`:
```
SlashCommand:
  command: "/finalize"
```

The finalize phase for epics generates:
- `walkthrough.md` - Comprehensive epic documentation
- CHANGELOG updates
- GitHub release with all sprint summaries
- Roadmap issue closures

### Step 5.5.3: Update State After Full Workflow Completion

```bash
yq eval '.status = "completed"' -i "$EPIC_DIR/state.yaml"
yq eval '.completed_at = "'$(date -Iseconds)'"' -i "$EPIC_DIR/state.yaml"
```

**Non-auto mode behavior (default):**
After optimize completes, display summary and wait for user to run `/ship` manually.

---

## PHASE 6: Completion

When all phases complete:

1. Update final state:
   ```bash
   yq eval '.status = "completed"' -i "$EPIC_DIR/state.yaml"
   yq eval '.completed_at = "'$(date -Iseconds)'"' -i "$EPIC_DIR/state.yaml"
   ```

2. Output completion banner:
   ```
   ════════════════════════════════════════════════════════════════════════════════
   ✅ EPIC COMPLETE
   ════════════════════════════════════════════════════════════════════════════════
   Epic: [slug]
   Sprints: [N] completed
   Duration: [calculated from started_at]
   Phases: spec → plan → tasks → implement → optimize → ship → finalize
   ════════════════════════════════════════════════════════════════════════════════

   Walkthrough: [EPIC_DIR]/walkthrough.md
   ════════════════════════════════════════════════════════════════════════════════
   ```

</process>

<continue_mode>

## Resuming Interrupted Epics

When argument is "continue":

### Step 1: Detect Active Workflow

```bash
WORKFLOW_INFO=$(bash .spec-flow/scripts/utils/detect-workflow-paths.sh 2>/dev/null)
EPIC_DIR=$(echo "$WORKFLOW_INFO" | jq -r '"\(.base_dir)/\(.slug)"')
WORKFLOW_TYPE=$(echo "$WORKFLOW_INFO" | jq -r '.type')

# Verify this is an epic
if [ "$WORKFLOW_TYPE" != "epic" ]; then
    echo "Error: This is a $WORKFLOW_TYPE workflow, not an epic"
    echo "Use /feature continue for features"
    exit 1
fi

echo "Resuming: $EPIC_DIR"
```

### Step 2: Read Current State

```bash
cat "$EPIC_DIR/state.yaml"
CURRENT_PHASE=$(yq eval '.phase' "$EPIC_DIR/state.yaml")
echo "Current phase: $CURRENT_PHASE"
```

### Step 3: Check for Pending Questions

```bash
PENDING=$(bash .spec-flow/scripts/bash/interaction-manager.sh get-pending "$EPIC_DIR" 2>/dev/null)
```

If pending questions exist, ask user via AskUserQuestion and save answers.

### Step 4: Check Sprint Progress (if in implement phase)

```bash
# Check which sprints are complete/in-progress
for sprint_dir in "$EPIC_DIR/sprints/"*/; do
    SPRINT=$(basename "$sprint_dir")
    STATUS=$(yq eval '.status' "$sprint_dir/domain-memory.yaml" 2>/dev/null || echo "pending")
    echo "$SPRINT: $STATUS"
done
```

### Step 5: Resume Phase Loop

Continue from CURRENT_PHASE using the same Task() spawning pattern.

</continue_mode>

<error_handling>

## Failure Handling

**On any phase failure:**

1. The phase agent will return FAILED status
2. Update state.yaml with failure status
3. Output clear error message with:
   - Which phase failed
   - Which sprint (if during implementation)
   - Error details from agent
   - File paths to check
   - Command to resume: `/epic continue`

**Sprint-specific failures:**

If a sprint worker fails:
1. Mark that sprint as failed in its domain-memory.yaml
2. Continue with other sprints in the same layer if they're independent
3. Block dependent sprints in subsequent layers
4. Report all failures at end of layer

**Never fabricate success. Always read actual state from disk.**

</error_handling>

<anti_hallucination>

## CRITICAL: Anti-Hallucination Rules

1. **NEVER execute phase logic inline** - Always spawn via Task tool
2. **NEVER claim completion without reading state.yaml**
3. **NEVER skip phases** - Follow the sequence from state.yaml
4. **NEVER guess agent results** - Parse actual returned content
5. **ALWAYS verify artifacts exist** after agent claims creation
6. **ALWAYS check sprint dependencies** before parallel execution
7. **NEVER run dependent sprints before their prerequisites complete**

</anti_hallucination>

<examples>

## Correct Usage Examples

### Starting a New Epic

User: `/epic "User authentication with OAuth 2.1 and MFA"`

You do:
1. Run create-new-epic.sh to initialize
2. Initialize interaction state
3. Check domain-memory.yaml (MISSING)
4. **Task(initializer)** to create epic domain-memory.yaml
5. Read state.yaml → phase is "spec"
6. **Task(spec-phase-agent)** to create epic-spec.md
7. Handle result (needs_input or completed)
8. Continue with **Task(plan-phase-agent)** which creates sprint-plan.md
9. Create sprint directories with domain-memory.yaml for each
10. **Task(tasks-phase-agent)** to create tasks.md
11. **Task(analyze-phase-agent)** to validate
12. **SlashCommand(/implement-epic)** for parallel sprint execution
13. **Task(optimize-phase-agent)** for quality gates
14. **Task(ship-phase-agent)** for deployment
15. **Task(finalize-phase-agent)** for walkthrough.md

### Resuming an Epic

User: `/epic continue`

You do:
1. Detect workflow via detect-workflow-paths.sh
2. Verify it's an epic workflow
3. Read state.yaml → phase is "implement"
4. **SlashCommand(/implement-epic)** to resume sprint execution
5. Continue through remaining phases (optimize → ship → finalize)

</examples>

<philosophy>

## Design Principles

**Orchestrator is stateless** - All knowledge comes from disk files

**Task() is mandatory** - Every phase runs in isolated agent context

**Parallel sprints via layers** - Dependency graph enables simultaneous execution

**Questions batch to main** - Agents return questions, main asks user

**Workers are atomic** - One sprint (or feature) per spawn, exit immediately

**State is observable** - All progress visible in YAML files at epic and sprint level

</philosophy>

<success_criteria>

## Epic Successfully Completed When:

1. **All artifacts generated**:
   - epic-spec.md (zero placeholders)
   - plan.md (architecture decisions)
   - sprint-plan.md (dependency graph)
   - tasks.md (all sprint tasks)
   - walkthrough.md (post-mortem)

2. **All sprints complete**:
   - Each sprint's domain-memory.yaml shows status: completed
   - All features within sprints completed

3. **Quality gates passed**:
   - All tests passing
   - No critical security issues
   - Performance benchmarks met
   - Accessibility compliant

4. **Deployment successful**:
   - Code deployed to target environment
   - Deployment metadata recorded

5. **State correctly recorded**:
   - state.yaml shows status: completed
   - All phase statuses show completed
   - No blocking failures

</success_criteria>
