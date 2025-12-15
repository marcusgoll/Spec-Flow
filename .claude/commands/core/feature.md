---
description: Execute feature development workflow from specification through production deployment with automated quality gates
argument-hint: "[description|slug|continue|next|epic:<name>|epic:<name>:sprint:<num>|sprint:<num>] [--deep | --auto | --dry-run]"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task, AskUserQuestion, TodoWrite, SlashCommand, Skill
version: 5.1
updated: 2025-12-14
---

<objective>
Orchestrate complete feature delivery through **isolated phase agents spawned via Task()** with strict state tracking and true autopilot execution.

**Command**: `/feature [feature description | slug | continue | next | epic:<name> | epic:<name>:sprint:<num> | sprint:<num>]`

**CRITICAL ARCHITECTURE** (v5.0 - Domain Memory v2):

This orchestrator is **ultra-lightweight**. You MUST:
1. Read state from disk (state.yaml, interaction-state.yaml, domain-memory.yaml)
2. Spawn isolated phase agents via **Task tool** - NEVER execute phases inline
3. Handle user Q&A when agents return questions
4. Update state.yaml after each phase
5. NEVER carry implementation details in your context

**Benefits**: Unlimited feature complexity, observable progress, resumable at any point, each phase gets fresh context.
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

Worktree context:
!`bash .spec-flow/scripts/bash/worktree-context.sh info 2>/dev/null || echo '{"is_worktree": false}'`

Studio context (multi-agent isolation):
!`bash .spec-flow/scripts/bash/worktree-context.sh studio-detect 2>/dev/null || echo ""`

Worktree preference:
!`bash .spec-flow/scripts/utils/load-preferences.sh --key "worktrees.auto_create" --default "true" 2>/dev/null || echo "true"`

Planning depth preference:
!`bash .spec-flow/scripts/utils/load-preferences.sh --key "planning.auto_deep_mode" --default "false" 2>/dev/null || echo "false"`

Auto-ship preference:
!`bash .spec-flow/scripts/utils/load-preferences.sh --key "deployment.auto_ship" --default "false" 2>/dev/null || echo "false"`

Auto-merge preference:
!`bash .spec-flow/scripts/utils/load-preferences.sh --key "deployment.auto_merge" --default "false" 2>/dev/null || echo "false"`

Auto-finalize preference:
!`bash .spec-flow/scripts/utils/load-preferences.sh --key "deployment.auto_finalize" --default "true" 2>/dev/null || echo "true"`
</context>

<planning_depth>
## Planning Depth Mode (--deep / --auto)

**Flags in $ARGUMENTS**:
- `--deep` → Force ultrathink/craftsman planning for this feature
- `--auto` → Use preferences to determine depth (respects `auto_deep_mode`), AND continue through ship→finalize without stopping
- Neither → Interactive mode, respects preference triggers

**Pass flag to /plan phase**:
When spawning the plan-phase-agent, include the planning mode:
- If `--deep` in arguments: Pass `--deep` to /plan
- If `--auto` in arguments: Determine from preferences and pass appropriate flag
- Store planning_mode in state.yaml for reference

**State tracking**:
```yaml
# In state.yaml
planning:
  mode: deep  # or standard
  ultrathink_enabled: true
  craftsman_decision_generated: true
```
</planning_depth>

<auto_mode>
## Auto Mode (--auto flag)

When `--auto` flag is present, the workflow runs end-to-end without stopping:

**Full auto-mode behavior** (when `--auto` flag is set):
1. **Planning**: Skip spec/plan review prompts (use preferences for depth)
2. **Implementation**: Continue through all phases automatically
3. **Ship**: Check CI, auto-merge when passing (if `deployment.auto_merge: true`)
4. **Finalize**: Run /finalize automatically (if `deployment.auto_finalize: true`)

**Preference-controlled auto-ship** (v11.7):
- `deployment.auto_ship: true` → Continue from optimize → ship → finalize without stopping
- `deployment.auto_merge: true` → Auto-merge PR when CI passes (no production approval prompt)
- `deployment.auto_finalize: true` → Run /finalize automatically after successful deployment

**State tracking**:
```yaml
# In state.yaml
auto_mode:
  enabled: true
  auto_ship: true   # Continue optimize → ship → finalize
  auto_merge: true  # Auto-merge when CI passes
  auto_finalize: true
```
</auto_mode>

<studio_mode>
## Studio Mode (Multi-Agent Isolation) (v11.8)

When running in a studio worktree (`worktrees/studio/agent-N/`), the workflow automatically:

1. **Detects studio context** - Auto-detected from working directory
2. **Namespaces branches** - `studio/agent-N/feature/XXX-slug` instead of `feature/XXX-slug`
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
BRANCH=$(bash .spec-flow/scripts/bash/worktree-context.sh studio-branch "feature" "$SLUG" 2>/dev/null)
# Returns: "studio/agent-1/feature/001-auth" in studio mode
# Returns: "feature/001-auth" in normal mode
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
- PR targets `main` branch from `studio/agent-N/feature/XXX-slug`
- Auto-merge enabled via GitHub branch protection (no manual review needed)
- CI gates validate the change before merge
</studio_mode>

<dry_run_mode>
## Dry-Run Mode (--dry-run)

**When `--dry-run` is in $ARGUMENTS:**

Preview all operations without executing them. See `.claude/skills/dry-run/SKILL.md` for full specification.

**Detection:**
```bash
DRY_RUN="false"
if [[ "$ARGUMENTS" == *"--dry-run"* ]]; then
  DRY_RUN="true"
  ARGUMENTS=$(echo "$ARGUMENTS" | sed 's/--dry-run//g' | xargs)
fi
```

**If DRY_RUN is true:**
1. Output dry-run banner immediately
2. Execute all Read/Grep/Glob operations normally (for accurate context)
3. Simulate all Write/Edit operations (log what would be created/modified)
4. Simulate all Task() spawns (log agent type and expected outputs)
5. Simulate all git operations (log commands that would run)
6. At end, output standardized summary and exit

**Do NOT spawn any agents or create any files in dry-run mode.**
</dry_run_mode>

<process>

## PHASE 0: Mode Detection

### Step 0.1: Detect Dry-Run, Planning, and Auto Modes

**Parse flags from arguments:**
```bash
DRY_RUN="false"
DEEP_MODE="false"
AUTO_MODE="false"
CLEAN_ARGS="$ARGUMENTS"

if [[ "$ARGUMENTS" == *"--dry-run"* ]]; then
  DRY_RUN="true"
  CLEAN_ARGS=$(echo "$CLEAN_ARGS" | sed 's/--dry-run//g')
fi

if [[ "$ARGUMENTS" == *"--deep"* ]]; then
  DEEP_MODE="true"
  CLEAN_ARGS=$(echo "$CLEAN_ARGS" | sed 's/--deep//g')
fi

if [[ "$ARGUMENTS" == *"--auto"* ]]; then
  AUTO_MODE="true"
  CLEAN_ARGS=$(echo "$CLEAN_ARGS" | sed 's/--auto//g')
fi

CLEAN_ARGS=$(echo "$CLEAN_ARGS" | xargs)  # Trim whitespace
echo "Dry-run: $DRY_RUN, Deep: $DEEP_MODE, Auto: $AUTO_MODE, Args: $CLEAN_ARGS"
```

**If AUTO_MODE is true, load deployment preferences:**
```bash
if [ "$AUTO_MODE" = "true" ]; then
  AUTO_SHIP=$(bash .spec-flow/scripts/utils/load-preferences.sh --key "deployment.auto_ship" --default "false" 2>/dev/null || echo "false")
  AUTO_MERGE=$(bash .spec-flow/scripts/utils/load-preferences.sh --key "deployment.auto_merge" --default "false" 2>/dev/null || echo "false")
  AUTO_FINALIZE=$(bash .spec-flow/scripts/utils/load-preferences.sh --key "deployment.auto_finalize" --default "true" 2>/dev/null || echo "true")
  echo "Auto-ship: $AUTO_SHIP, Auto-merge: $AUTO_MERGE, Auto-finalize: $AUTO_FINALIZE"
fi
```

**Detect studio context (v11.8):**
```bash
STUDIO_AGENT=$(bash .spec-flow/scripts/bash/worktree-context.sh studio-detect 2>/dev/null || echo "")
IS_STUDIO_MODE="false"
if [[ -n "$STUDIO_AGENT" ]]; then
  IS_STUDIO_MODE="true"
  echo "Studio mode: $STUDIO_AGENT"
fi
```

**If DRY_RUN is true, output banner:**
```
════════════════════════════════════════════════════════════════════════════════
DRY-RUN MODE: No changes will be made
════════════════════════════════════════════════════════════════════════════════
```

---

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
  2. Start a NEW feature (will create new worktree): proceed with /feature "new description"

════════════════════════════════════════════════════════════════════════════════
```

**If argument is NOT "continue" and NOT empty (starting new feature):**
- Proceed to PHASE 1 (new feature will get its own worktree)

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
  - label: "Start new feature here"
    description: "Create a new worktree for this feature"
  - label: "Work in root (unsafe)"
    description: "Make changes directly in root (not recommended)"
```

Handle user choice accordingly.

**If IS_SAFE is true:**
- Proceed to PHASE 1

---

## PHASE 1: Initialize Feature Workspace

**User Input:**
```text
$ARGUMENTS
```

### Step 1.1: Parse Arguments and Initialize

**If DRY_RUN is true:**
```
Log: "WOULD EXECUTE: python .spec-flow/scripts/spec-cli.py feature '$CLEAN_ARGS'"
Log: "WOULD CREATE: specs/NNN-[slug]/state.yaml"
Log: "WOULD CREATE: specs/NNN-[slug]/NOTES.md"

# For accurate simulation, determine what the slug would be:
SLUG=$(echo "$CLEAN_ARGS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | head -c 40)
NEXT_NUM=$(ls -d specs/[0-9]*-* 2>/dev/null | wc -l)
NEXT_NUM=$((NEXT_NUM + 1))
FEATURE_DIR="specs/$(printf '%03d' $NEXT_NUM)-$SLUG"
echo "Would create feature directory: $FEATURE_DIR"
```

**If DRY_RUN is false (normal execution):**

Run the spec-cli tool to initialize the feature workspace:

```bash
python .spec-flow/scripts/spec-cli.py feature "$ARGUMENTS"
```

After the script completes, read the created state file to get the feature directory:

```bash
FEATURE_DIR=$(ls -td specs/[0-9]*-* 2>/dev/null | head -1)
echo "Feature directory: $FEATURE_DIR"
cat "$FEATURE_DIR/state.yaml"
```

### Step 1.1.5: Create Worktree and Branch (Studio-Aware)

**Handle worktree using centralized skill** (see `.claude/skills/worktree-context/SKILL.md`):

1. Check preference: `worktrees.auto_create` (default: true)
2. Check if already in worktree: `bash .spec-flow/scripts/bash/worktree-context.sh in-worktree`
3. **Get studio-aware branch name (v11.8):**
   ```bash
   # Auto-detects studio context and namespaces branch appropriately
   BRANCH=$(bash .spec-flow/scripts/bash/worktree-context.sh studio-branch "feature" "$SLUG" 2>/dev/null)
   # Returns: "studio/agent-1/feature/001-auth" in studio mode
   # Returns: "feature/001-auth" in normal mode
   ```
4. If NOT in worktree AND auto_create is true:
   - Create: `bash .spec-flow/scripts/bash/worktree-context.sh create "feature" "$SLUG" "$BRANCH"`
   - Store in state.yaml: `git.worktree_enabled`, `git.worktree_path`
5. **Store studio context in state.yaml (v11.8):**
   ```bash
   if [ "$IS_STUDIO_MODE" = "true" ]; then
     yq eval '.studio.enabled = true' -i "$FEATURE_DIR/state.yaml"
     yq eval '.studio.agent_id = "'$STUDIO_AGENT'"' -i "$FEATURE_DIR/state.yaml"
     yq eval '.studio.branch_namespace = "studio/'$STUDIO_AGENT'"' -i "$FEATURE_DIR/state.yaml"
     yq eval '.studio.merge_strategy = "pr"' -i "$FEATURE_DIR/state.yaml"
   fi
   ```
6. Read worktree info from state.yaml for Task() agent prompts

### Step 1.2: Initialize Interaction State

```bash
bash .spec-flow/scripts/bash/interaction-manager.sh init "$FEATURE_DIR"
```

### Step 1.3: Display Autopilot Banner

Output this to the user (with studio context if active):
```
════════════════════════════════════════════════════════════════════════════════
🤖 AUTOPILOT MODE - Domain Memory v2
════════════════════════════════════════════════════════════════════════════════
All phases execute via isolated Task() agents
Progress tracked in: $FEATURE_DIR/state.yaml
Questions batched and asked in main context
Resume anytime with: /feature continue
${IS_STUDIO_MODE == "true" ? "
Studio Agent: $STUDIO_AGENT
Branch: $BRANCH (namespaced for multi-agent isolation)
Merge strategy: PR (auto-merge when CI passes)
" : ""}════════════════════════════════════════════════════════════════════════════════
```

---

## PHASE 2: Domain Memory Initialization

**If DRY_RUN is true:**
```
Log: "WOULD SPAWN AGENT: initializer"
Log: "  Description: Initialize domain memory"
Log: "  Expected output: $FEATURE_DIR/domain-memory.yaml"
Log: "  Expected content: 3-8 sub-features expanded from description"
```
Skip to Phase 3 dry-run simulation.

**If DRY_RUN is false (normal execution):**

**YOU MUST spawn the Initializer agent via Task tool.**

Check if domain-memory.yaml exists:
```bash
FEATURE_DIR=$(ls -td specs/[0-9]*-* 2>/dev/null | head -1)
test -f "$FEATURE_DIR/domain-memory.yaml" && echo "EXISTS" || echo "MISSING"
```

**If MISSING, use the Task tool with these EXACT parameters:**

```
Task tool call:
  subagent_type: "initializer"
  description: "Initialize domain memory"
  prompt: |
    Initialize domain memory for this feature.

    Feature directory: [insert FEATURE_DIR value]
    Description: [insert feature description from state.yaml]
    Workflow type: feature

    Your task:
    1. Read the feature description from state.yaml
    2. Expand it into 3-8 concrete sub-features
    3. Create domain-memory.yaml with structured backlog
    4. EXIT immediately after creating the file - do NOT implement anything

    Return a summary of features created.
```

After the Task completes, verify domain-memory.yaml was created:
```bash
cat "$FEATURE_DIR/domain-memory.yaml"
```

---

## PHASE 3: Execute Phase Loop

**If DRY_RUN is true:**

Output the full dry-run summary and exit:

```
════════════════════════════════════════════════════════════════════════════════
DRY-RUN MODE: No changes will be made
════════════════════════════════════════════════════════════════════════════════

📁 FILES THAT WOULD BE CREATED:
  ✚ $FEATURE_DIR/state.yaml
  ✚ $FEATURE_DIR/NOTES.md
  ✚ $FEATURE_DIR/interaction-state.yaml
  ✚ $FEATURE_DIR/domain-memory.yaml (via initializer agent)
  ✚ $FEATURE_DIR/spec.md (via spec-phase-agent)
  ✚ $FEATURE_DIR/plan.md (via plan-phase-agent)
  ✚ $FEATURE_DIR/tasks.md (via tasks-phase-agent)
  ✚ $FEATURE_DIR/analysis-report.md (via analyze-phase-agent)
  ✚ $FEATURE_DIR/optimization-report.md (via optimize-phase-agent)

🤖 AGENTS THAT WOULD BE SPAWNED:
  1. initializer → Initialize domain memory (3-8 sub-features)
  2. spec-phase-agent → Generate feature specification
  3. clarify-phase-agent → Resolve requirement ambiguities
  4. plan-phase-agent → Create implementation plan
  5. tasks-phase-agent → Break down into TDD tasks
  6. analyze-phase-agent → Validate spec/plan/tasks consistency
  7. worker (N times) → Implement each feature atomically
  8. optimize-phase-agent → Run quality gates (5-10 checks)
  9. ship-staging-phase-agent → Deploy to staging
  10. finalize-phase-agent → Archive and document

🔀 GIT OPERATIONS THAT WOULD OCCUR:
  • git checkout -b feature/$SLUG (if not exists)
  • git add (after each phase completes)
  • git commit (after each phase completes)
  • git push origin feature/$SLUG (during ship phase)
  • gh pr create (during ship phase)

📊 WORKFLOW PHASES:
  init → spec → clarify → plan → tasks → analyze → implement → optimize → ship → finalize → complete

════════════════════════════════════════════════════════════════════════════════
DRY-RUN COMPLETE: 0 actual changes made
Run `/feature "$CLEAN_ARGS"` to execute these operations
════════════════════════════════════════════════════════════════════════════════
```

**Exit after dry-run summary. Do NOT proceed to normal execution.**

---

**If DRY_RUN is false (normal execution):**

**CRITICAL: You MUST spawn each phase as an isolated Task() agent. NEVER execute phase logic inline.**

### Phase Sequence

Execute these phases in order. For each phase:
1. Check current phase from state.yaml
2. Spawn the appropriate agent via Task tool
3. Handle the result (completed, needs_input, or failed)
4. Update state.yaml
5. Proceed to next phase or handle error

### Phase Configuration

| Phase | Agent Type | Next Phase |
|-------|------------|------------|
| spec | spec-phase-agent | clarify |
| clarify | clarify-phase-agent | plan |
| plan | plan-phase-agent | tasks |
| tasks | tasks-phase-agent | analyze |
| analyze | analyze-phase-agent | implement |
| implement | worker | optimize |
| optimize | optimize-phase-agent | ship |
| ship | ship-staging-phase-agent | finalize |
| finalize | finalize-phase-agent | complete |

**Auto-mode handling (--auto flag)**:
When `AUTO_MODE=true` (from Step 0.1), the workflow continues automatically through optimize → ship → finalize:

1. After **optimize** phase completes: Automatically proceed to **ship** phase (no pause)
2. During **ship** phase: Pass `--auto` flag to ship command to enable auto-merge
3. After **ship** completes: Automatically proceed to **finalize** phase
4. After **finalize** completes: Mark workflow complete

**Store auto_mode in state.yaml** after feature initialization:
```bash
if [ "$AUTO_MODE" = "true" ]; then
  yq eval '.auto_mode.enabled = true' -i "$FEATURE_DIR/state.yaml"
  yq eval '.auto_mode.auto_ship = '$AUTO_SHIP'' -i "$FEATURE_DIR/state.yaml"
  yq eval '.auto_mode.auto_merge = '$AUTO_MERGE'' -i "$FEATURE_DIR/state.yaml"
  yq eval '.auto_mode.auto_finalize = '$AUTO_FINALIZE'' -i "$FEATURE_DIR/state.yaml"
fi
```

### For Each Phase, Follow This Exact Pattern:

#### Step 3.1: Read Current State

```bash
FEATURE_DIR=$(ls -td specs/[0-9]*-* 2>/dev/null | head -1)
CURRENT_PHASE=$(yq eval '.phase' "$FEATURE_DIR/state.yaml")
echo "Current phase: $CURRENT_PHASE"
```

#### Step 3.2: Check for Pending Answers

```bash
PENDING=$(bash .spec-flow/scripts/bash/interaction-manager.sh get-pending "$FEATURE_DIR" 2>/dev/null)
echo "Pending questions: $PENDING"
```

#### Step 3.3: Spawn Phase Agent via Task Tool

**YOU MUST use the Task tool. Example for spec phase:**

```
Task tool call:
  subagent_type: "spec-phase-agent"
  description: "Execute spec phase"
  prompt: |
    Execute the SPEC phase for this feature.

    Feature directory: [FEATURE_DIR]

    Instructions:
    1. Read state.yaml to understand the feature
    2. Research the codebase for existing patterns
    3. Generate spec.md with requirements and acceptance criteria
    4. If you need user input, return a structured response (see below)
    5. If complete, return success status

    IMPORTANT: If you need to ask the user questions, DO NOT use AskUserQuestion.
    Instead, return this structured response and EXIT:

    ---NEEDS_INPUT---
    questions:
      - id: Q001
        question: "Your question here?"
        header: "Short Label"
        multi_select: false
        options:
          - label: "Option 1"
            description: "Description of option 1"
          - label: "Option 2"
            description: "Description of option 2"
    resume_from: "after_research"
    ---END_NEEDS_INPUT---

    If complete, return:
    ---COMPLETED---
    artifacts_created:
      - path: spec.md
        type: specification
    summary: "Brief summary of what was created"
    ---END_COMPLETED---
```

#### Step 3.4: Handle Agent Result

**If agent returned NEEDS_INPUT:**

1. Parse the questions from the agent's response
2. Use AskUserQuestion tool to ask the user (you CAN use this in main context)
3. Save answers:
   ```bash
   bash .spec-flow/scripts/bash/interaction-manager.sh save-answers "$FEATURE_DIR" '[answers JSON]'
   ```
4. Re-spawn the SAME phase agent with answers included in prompt

**If agent returned COMPLETED:**

1. Update state.yaml:
   ```bash
   yq eval '.phases.[PHASE_NAME] = "completed"' -i "$FEATURE_DIR/state.yaml"
   yq eval '.phase = "[NEXT_PHASE]"' -i "$FEATURE_DIR/state.yaml"
   ```
2. Mark phase complete:
   ```bash
   bash .spec-flow/scripts/bash/interaction-manager.sh mark-phase-complete "$FEATURE_DIR" "[PHASE_NAME]"
   ```
3. Proceed to next phase

**If agent returned FAILED:**

1. Update state.yaml:
   ```bash
   yq eval '.phases.[PHASE_NAME] = "failed"' -i "$FEATURE_DIR/state.yaml"
   yq eval '.status = "failed"' -i "$FEATURE_DIR/state.yaml"
   ```
2. Output error message to user
3. Instruct user to fix and run `/feature continue`
4. STOP the workflow

#### Step 3.5: Auto-Mode Ship and Finalize (v11.7)

**When optimize phase completes in auto mode, continue through ship and finalize automatically.**

Check for auto-mode after optimize phase:
```bash
AUTO_MODE=$(yq eval '.auto_mode.enabled // false' "$FEATURE_DIR/state.yaml")
AUTO_SHIP=$(yq eval '.auto_mode.auto_ship // false' "$FEATURE_DIR/state.yaml")
AUTO_MERGE=$(yq eval '.auto_mode.auto_merge // false' "$FEATURE_DIR/state.yaml")
AUTO_FINALIZE=$(yq eval '.auto_mode.auto_finalize // true' "$FEATURE_DIR/state.yaml")
```

**If optimize phase just completed AND auto_mode is enabled:**

1. **Proceed to ship phase automatically (no pause):**
   ```
   SlashCommand:
     command: "/ship --auto"
   ```

   The `--auto` flag tells /ship to:
   - Skip production approval prompt
   - Auto-merge PR when CI passes (if `auto_merge: true`)
   - Continue to finalize automatically (if `auto_finalize: true`)

2. **After ship completes, proceed to finalize:**
   If `/ship` returns successfully and `auto_finalize: true`:
   ```
   SlashCommand:
     command: "/finalize"
   ```

3. **Update state after full workflow completion:**
   ```bash
   yq eval '.status = "completed"' -i "$FEATURE_DIR/state.yaml"
   yq eval '.completed_at = "'$(date -Iseconds)'"' -i "$FEATURE_DIR/state.yaml"
   ```

**Non-auto mode behavior (default):**
After optimize completes, display summary and wait for user to run `/ship` manually.

---

## PHASE 4: Implementation Phase (Special Handling)

**The implement phase uses Domain Memory workers - one task at a time.**

When current phase is "implement":

1. Read worktree and domain-memory state:
   ```bash
   FEATURE_DIR=$(ls -td specs/[0-9]*-* 2>/dev/null | head -1)
   WORKTREE_PATH=$(yq eval '.git.worktree_path // ""' "$FEATURE_DIR/state.yaml")
   WORKTREE_ENABLED=$(yq eval '.git.worktree_enabled // false' "$FEATURE_DIR/state.yaml")
   ```

2. Extract feature slug and spawn a worker agent for ONE feature only:

   ```bash
   # Extract the feature slug (last component of FEATURE_DIR)
   FEATURE_SLUG=$(basename "$FEATURE_DIR")
   echo "Feature slug: $FEATURE_SLUG"
   ```

```
Task tool call:
  subagent_type: "worker"
  description: "Implement one feature"
  prompt: |
    Implement ONE feature from the domain memory.

    ## Path Context
    Feature slug: ${FEATURE_SLUG}
    Feature directory (main repo relative): ${FEATURE_DIR}
    Worktree enabled: ${WORKTREE_ENABLED}
    Worktree path: ${WORKTREE_PATH}

    ${WORKTREE_ENABLED == "true" ? "
    ## WORKTREE MODE (CRITICAL)

    You are operating in an isolated git worktree.

    **Step 1: Switch to worktree FIRST**
    ```bash
    cd \"${WORKTREE_PATH}\" || exit 1
    echo \"Working in: $(pwd)\"
    ```

    **Step 2: Reconstruct paths relative to worktree**
    After cd, the feature directory is at: specs/${FEATURE_SLUG}/
    Domain memory is at: specs/${FEATURE_SLUG}/domain-memory.yaml

    **Rules:**
    - All paths are relative to worktree root AFTER cd
    - Git commits stay local to worktree branch
    - Do NOT merge or push - orchestrator handles that
    " : "
    ## NORMAL MODE
    Feature directory: ${FEATURE_DIR}
    Domain memory: ${FEATURE_DIR}/domain-memory.yaml
    "}

    ## Instructions
    1. ${WORKTREE_ENABLED == "true" ? "cd to worktree path and verify" : "Verify feature directory exists"}
    2. Read domain-memory.yaml (use worktree-relative path if in worktree mode)
    3. Find the first feature with status "pending" or "in_progress"
    4. Implement ONLY that one feature using TDD
    5. Update domain-memory.yaml with your progress
    6. EXIT immediately after completing the feature

    Return:
    ---WORKER_COMPLETED---
    feature_id: F001
    status: completed
    files_changed:
      - path/to/file.py
    tests_added:
      - test_file.py
    ---END_WORKER_COMPLETED---
```

3. After worker completes, check if more features remain:
   ```bash
   REMAINING=$(yq eval '.features[] | select(.status != "completed") | .id' "$FEATURE_DIR/domain-memory.yaml" | wc -l)
   ```

4. If REMAINING > 0, spawn another worker (loop)
5. If REMAINING = 0, proceed to optimize phase

---

## PHASE 5: Completion

When all phases complete:

1. Update final state:
   ```bash
   yq eval '.status = "completed"' -i "$FEATURE_DIR/state.yaml"
   yq eval '.completed_at = "'$(date -Iseconds)'"' -i "$FEATURE_DIR/state.yaml"
   ```

2. Output completion banner:
   ```
   ════════════════════════════════════════════════════════════════════════════════
   ✅ FEATURE COMPLETE
   ════════════════════════════════════════════════════════════════════════════════
   Feature: [slug]
   Duration: [calculated from started_at]
   Phases completed: spec → plan → tasks → implement → optimize → ship → finalize
   ════════════════════════════════════════════════════════════════════════════════
   ```

</process>

<continue_mode>

## Resuming Interrupted Features

When argument is "continue":

### Step 1: Detect Active Workflow

```bash
WORKFLOW_INFO=$(bash .spec-flow/scripts/utils/detect-workflow-paths.sh 2>/dev/null)
FEATURE_DIR=$(echo "$WORKFLOW_INFO" | jq -r '.base_dir + "/" + .slug')
echo "Resuming: $FEATURE_DIR"
```

### Step 2: Read Current State

```bash
cat "$FEATURE_DIR/state.yaml"
CURRENT_PHASE=$(yq eval '.phase' "$FEATURE_DIR/state.yaml")
echo "Current phase: $CURRENT_PHASE"
```

### Step 3: Check for Pending Questions

```bash
PENDING=$(bash .spec-flow/scripts/bash/interaction-manager.sh get-pending "$FEATURE_DIR" 2>/dev/null)
```

If pending questions exist, ask user via AskUserQuestion and save answers.

### Step 4: Resume Phase Loop

Continue from CURRENT_PHASE using the same Task() spawning pattern described above.

</continue_mode>

<error_handling>

## Failure Handling

**On any phase failure:**

1. The phase agent will return FAILED status
2. Update state.yaml with failure status
3. Output clear error message with:
   - Which phase failed
   - Error details from agent
   - File paths to check
   - Command to resume: `/feature continue`

**Never fabricate success. Always read actual state from disk.**

</error_handling>

<anti_hallucination>

## CRITICAL: Anti-Hallucination Rules

1. **NEVER execute phase logic inline** - Always spawn via Task tool
2. **NEVER claim completion without reading state.yaml**
3. **NEVER skip phases** - Follow the sequence from state.yaml
4. **NEVER guess agent results** - Parse actual returned content
5. **ALWAYS verify artifacts exist** after agent claims creation

</anti_hallucination>

<examples>

## Correct Usage Examples

### Starting a New Feature

User: `/feature "Add user authentication"`

You do:
1. Run spec-cli.py to initialize
2. Initialize interaction state
3. Check domain-memory.yaml (MISSING)
4. **Task(initializer)** to create domain-memory.yaml
5. Read state.yaml → phase is "spec"
6. **Task(spec-phase-agent)** to create spec.md
7. Handle result (needs_input or completed)
8. Continue with **Task(plan-phase-agent)**, etc.

### Resuming a Feature

User: `/feature continue`

You do:
1. Detect workflow via detect-workflow-paths.sh
2. Read state.yaml → phase is "implement"
3. Check pending questions
4. Read domain-memory.yaml → find next incomplete feature
5. **Task(worker)** to implement one feature
6. Loop until all features complete
7. **Task(optimize-phase-agent)**, etc.

</examples>

<philosophy>

## Design Principles

**Orchestrator is stateless** - All knowledge comes from disk files

**Task() is mandatory** - Every phase runs in isolated agent context

**Questions batch to main** - Agents return questions, main asks user

**Workers are atomic** - One feature per spawn, exit immediately

**State is observable** - All progress visible in YAML files

</philosophy>
