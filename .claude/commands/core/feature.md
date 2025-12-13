---
description: Execute feature development workflow from specification through production deployment with automated quality gates
argument-hint: [description|slug|continue|next|epic:<name>|epic:<name>:sprint:<num>|sprint:<num>]
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task, AskUserQuestion, TodoWrite, SlashCommand
version: 5.0
updated: 2025-12-09
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

Worktree preference:
!`bash .spec-flow/scripts/utils/load-preferences.sh --key "worktrees.auto_create" --default "true" 2>/dev/null || echo "true"`
</context>

<process>

## PHASE 1: Initialize Feature Workspace

**User Input:**
```text
$ARGUMENTS
```

### Step 1.1: Parse Arguments and Initialize

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

### Step 1.1.5: Create Worktree (If Preference Enabled)

Check worktree context and preference:

```bash
# Check if already in a worktree
IS_WORKTREE=$(bash .spec-flow/scripts/bash/worktree-context.sh in-worktree && echo "true" || echo "false")

# Check worktree auto-create preference
WORKTREE_AUTO=$(bash .spec-flow/scripts/utils/load-preferences.sh --key "worktrees.auto_create" --default "true" 2>/dev/null)

echo "In worktree: $IS_WORKTREE"
echo "Auto-create worktree: $WORKTREE_AUTO"
```

**If NOT in worktree AND auto_create is true:**

```bash
if [ "$IS_WORKTREE" = "false" ] && [ "$WORKTREE_AUTO" = "true" ]; then
    # Get feature slug and branch
    FEATURE_SLUG=$(yq eval '.slug' "$FEATURE_DIR/state.yaml")
    FEATURE_BRANCH="feature/$FEATURE_SLUG"

    # Create worktree
    WORKTREE_PATH=$(bash .spec-flow/scripts/bash/worktree-context.sh create "feature" "$FEATURE_SLUG" "$FEATURE_BRANCH")

    if [ -n "$WORKTREE_PATH" ]; then
        # Update state.yaml with worktree info
        yq eval ".git.worktree_enabled = true" -i "$FEATURE_DIR/state.yaml"
        yq eval ".git.worktree_path = \"$WORKTREE_PATH\"" -i "$FEATURE_DIR/state.yaml"
        echo "Created worktree at: $WORKTREE_PATH"
    fi
fi
```

**Read worktree path for Task() agents:**

```bash
WORKTREE_PATH=$(yq eval '.git.worktree_path // ""' "$FEATURE_DIR/state.yaml")
WORKTREE_ENABLED=$(yq eval '.git.worktree_enabled // false' "$FEATURE_DIR/state.yaml")
echo "Worktree enabled: $WORKTREE_ENABLED"
echo "Worktree path: $WORKTREE_PATH"
```

### Step 1.2: Initialize Interaction State

```bash
bash .spec-flow/scripts/bash/interaction-manager.sh init "$FEATURE_DIR"
```

### Step 1.3: Display Autopilot Banner

Output this to the user:
```
════════════════════════════════════════════════════════════════════════════════
🤖 AUTOPILOT MODE - Domain Memory v2
════════════════════════════════════════════════════════════════════════════════
All phases execute via isolated Task() agents
Progress tracked in: $FEATURE_DIR/state.yaml
Questions batched and asked in main context
Resume anytime with: /feature continue
════════════════════════════════════════════════════════════════════════════════
```

---

## PHASE 2: Domain Memory Initialization

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

2. Spawn a worker agent for ONE feature only:

```
Task tool call:
  subagent_type: "worker"
  description: "Implement one feature"
  prompt: |
    Implement ONE feature from the domain memory.

    Feature directory: [FEATURE_DIR]

    ${WORKTREE_ENABLED == "true" ? "
    **WORKTREE CONTEXT**
    Path: $WORKTREE_PATH

    CRITICAL: Execute this FIRST before any other commands:
    ```bash
    cd \"$WORKTREE_PATH\"
    ```

    All paths are relative to this worktree.
    Git commits stay local to worktree branch.
    Do NOT merge or push - orchestrator handles that.
    " : ""}

    Instructions:
    1. ${WORKTREE_ENABLED == "true" ? "cd to worktree path" : ""}
    2. Read domain-memory.yaml
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
