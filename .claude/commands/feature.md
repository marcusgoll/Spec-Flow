---
description: Orchestrate full feature workflow with isolated phase contexts (optimized)
---

Orchestrate feature delivery through isolated phase agents for maximum efficiency.

## MENTAL MODEL

**Architecture**: Orchestrator-Workers with Phase Isolation
- **Orchestrator** (`/feature`): Lightweight state tracking, phase progression
- **Phase Agents**: Isolated contexts, call slash commands, return summaries
- **Implementation**: `/implement` called directly (spawns worker agents: backend-dev, frontend-shipper, etc.)
  - Note: Phase 4 bypasses phase agent due to sub-agent spawning limits

**Benefits**:
- 67% token reduction (240k → 80k per feature)
- 2-3x faster (isolated contexts, no /compact overhead)
- Same quality (slash commands unchanged)

## WORKFLOW TRACKING

**IMPORTANT**: Use the TodoWrite tool to track feature workflow progress throughout this command.

**At start** - Create todo list (adapt based on feature complexity and deployment model):

```javascript
// Example for full staging-prod workflow:
TodoWrite({
  todos: [
    {content: "Parse arguments and initialize workflow state", status: "pending", activeForm: "Initializing workflow"},
    {content: "Phase 0: Create specification", status: "pending", activeForm: "Creating specification"},
    {content: "Phase 0.5: Resolve clarifications (if needed)", status: "pending", activeForm: "Resolving clarifications"},
    {content: "Phase 1: Create plan with reuse analysis", status: "pending", activeForm: "Creating plan"},
    {content: "Phase 2: Generate task breakdown", status: "pending", activeForm: "Generating tasks"},
    {content: "Phase 2a-c: Design workflow (if UI feature)", status: "pending", activeForm: "Running design workflow"},
    {content: "Phase 3: Cross-artifact validation", status: "pending", activeForm: "Validating artifacts"},
    {content: "Phase 4: Execute implementation", status: "pending", activeForm: "Implementing tasks"},
    {content: "Phase 5: Code review and optimization", status: "pending", activeForm: "Optimizing code"},
    {content: "Manual Gate: Preview testing", status: "pending", activeForm: "Awaiting preview approval"},
    {content: "Phase 6: Deploy to staging", status: "pending", activeForm: "Deploying to staging"},
    {content: "Manual Gate: Staging validation", status: "pending", activeForm: "Awaiting staging approval"},
    {content: "Phase 7: Deploy to production", status: "pending", activeForm: "Deploying to production"},
    {content: "Phase 7.5: Finalize documentation", status: "pending", activeForm: "Finalizing documentation"},
  ]
})

// For local-only projects, omit deployment phases (6, 7)
// For direct-prod projects, omit staging phases (6, staging validation)
// For non-UI features, omit design workflow (2a-c)
```

**During execution**:
- **Adapt** todos based on detected project type and feature characteristics
- Skip Phase 0.5 if no clarifications needed
- Skip Phase 2a-c if feature has no UI components
- Adjust deployment phases based on deployment model (staging-prod, direct-prod, local-only)
- Mark each phase as `in_progress` when starting
- Mark as `completed` IMMEDIATELY after phase finishes successfully
- Pause at manual gates - keep as `pending` until user runs `/feature continue` with approval
- Update to `blocked` if phase encounters critical issues
- Only ONE phase should be `in_progress` at a time

**Why**: The /feature workflow orchestrates 8-14 phases (depending on project type and feature complexity) and can take 1-3 hours end-to-end with manual gates. Users need clear visibility into which phase is active, which phases remain, and where manual intervention is required. This is especially important since phases run in isolated contexts via specialized agents.

## PARSE ARGUMENTS

**Get feature description or continue mode:**

If `$ARGUMENTS` is empty, show usage:
```
Usage: /feature [feature description]
   or: /feature continue

Examples:
  /feature "Student progress tracking dashboard"
  /feature continue
```

If `$ARGUMENTS` is "continue":
- Set `CONTINUE_MODE = true`
- Load workflow state from `specs/*/workflow-state.yaml`
- Resume from last completed phase

Else:
- Set `CONTINUE_MODE = false`
- Set `FEATURE_DESCRIPTION = $ARGUMENTS`
- Initialize new workflow

## GENERATE FEATURE SLUG

**Generate slug from feature description before any file/branch operations:**

```bash
# Generate concise short-name from feature description (2-4 words, action-noun format)
# This must happen BEFORE branch creation since branch name includes slug
SLUG=$(echo "$FEATURE_DESCRIPTION" |
  tr '[:upper:]' '[:lower:]' |
  # Remove common filler words and phrases
  sed 's/\bwe want to\b//g; s/\bI want to\b//g; s/\bget our\b//g' |
  sed 's/\bto a\b//g; s/\bwith\b//g; s/\bfor the\b//g' |
  sed 's/\bbefore moving on to\b//g; s/\bother features\b//g' |
  sed 's/\ba\b//g; s/\ban\b//g; s/\bthe\b//g' |
  # Preserve technical terms by keeping alphanumeric
  sed 's/\bimplement\b/add/g; s/\bcreate\b/add/g' |
  # Convert to hyphen-separated
  sed 's/[^a-z0-9-]/-/g' |
  sed 's/--*/-/g' |
  sed 's/^-//;s/-$//' |
  # Take first 20 chars (approx 2-4 words)
  cut -c1-20 |
  sed 's/-$//')

# Validate slug is not empty
if [ -z "$SLUG" ]; then
  echo "❌ Error: Invalid feature description (results in empty slug)"
  echo "Provided: $FEATURE_DESCRIPTION"
  exit 1
fi

# Prevent path traversal
if [[ "$SLUG" == *".."* ]] || [[ "$SLUG" == *"/"* ]]; then
  echo "❌ Error: Invalid characters in feature slug"
  exit 1
fi

echo "📝 Generated slug: $SLUG"
echo "   From: $FEATURE_DESCRIPTION"
echo ""
```

## DETECT PROJECT TYPE

**Run project type detection:**

```bash
# Use detection script (bash or PowerShell based on OS)
if command -v bash &> /dev/null; then
  PROJECT_TYPE=$(bash .spec-flow/scripts/bash/detect-project-type.sh)
else
  PROJECT_TYPE=$(pwsh -File .spec-flow/scripts/powershell/detect-project-type.ps1)
fi

echo "📦 Project type: $PROJECT_TYPE"
echo ""
```

**Project types:**
- `local-only` - No remote repo, workflow ends at `/optimize`
- `remote-staging-prod` - Full staging → production workflow
- `remote-direct` - Remote repo, direct to main (no staging)

## BRANCH MANAGEMENT

**Purpose**: Ensure clean worktree and create feature branch if on main/master

**Process**:

```bash
# Check if in git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "⚠️  Git not detected, continuing without branch"
  BRANCH_NAME="local"

  # Still need feature number for directory creation
  MAX_NUM=0
  while IFS= read -r dir; do
    if [[ $dir =~ ([0-9]{3})- ]]; then
      NUM=$((10#${BASH_REMATCH[1]}))
      if (( NUM > MAX_NUM )); then
        MAX_NUM=$NUM
      fi
    fi
  done < <(find specs -maxdepth 1 -mindepth 1 -type d 2>/dev/null || true)

  FEATURE_NUM=$(printf '%03d' $((MAX_NUM + 1)))
else
  # Check for clean worktree
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "❌ Worktree is not clean. Please commit or stash changes first:"
    echo ""
    git status --short
    echo ""
    echo "Options:"
    echo "  git stash          # Stash uncommitted changes"
    echo "  git commit -am \"\" # Commit changes"
    echo "  git reset --hard   # Discard all changes (DANGER)"
    exit 1
  fi

  # Get current branch
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

  # Calculate feature number (needed for directory creation)
  # Find next available number by looking at existing spec directories
  MAX_NUM=0
  while IFS= read -r dir; do
    if [[ $dir =~ ([0-9]{3})- ]]; then
      NUM=$((10#${BASH_REMATCH[1]}))
      if (( NUM > MAX_NUM )); then
        MAX_NUM=$NUM
      fi
    fi
  done < <(find specs -maxdepth 1 -mindepth 1 -type d 2>/dev/null || true)

  FEATURE_NUM=$(printf '%03d' $((MAX_NUM + 1)))

  # If on main or master, create feature branch
  if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
    echo "📍 Currently on $CURRENT_BRANCH"
    echo "Creating feature branch..."
    echo ""

    # Generate branch name: feature/NNN-slug
    BASE_BRANCH_NAME="feature/$FEATURE_NUM-$SLUG"
    BRANCH_NAME="$BASE_BRANCH_NAME"

    # Check if branch exists, handle conflicts
    COUNTER=2
    while git rev-parse --verify --quiet "$BRANCH_NAME" >/dev/null 2>&1; do
      BRANCH_NAME="$BASE_BRANCH_NAME-$COUNTER"
      COUNTER=$((COUNTER + 1))
    done

    # Create and checkout new branch
    git checkout -b "$BRANCH_NAME"
    echo "✅ Created feature branch: $BRANCH_NAME"
  else
    BRANCH_NAME="$CURRENT_BRANCH"
    echo "📍 Continuing on current branch: $BRANCH_NAME"
  fi
fi

echo ""
```

**State Updates**:
- Store branch name in workflow-state.yaml for tracking

## INITIALIZE WORKFLOW STATE

**Create or load workflow state file:**

State file location: `specs/$SLUG/workflow-state.yaml` (per-feature state tracking)

**For new workflows:**

```bash
# Source state management functions
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  source .spec-flow/scripts/bash/workflow-state.sh 2>/dev/null || {
    echo "⚠️  Workflow state management not available on Windows (use PowerShell)"
    # Fallback to basic tracking if needed
  }
else
  source .spec-flow/scripts/bash/workflow-state.sh
fi

# Create feature directory with number prefix (NNN-slug format)
# Feature number was already calculated during branch creation above
FEATURE_DIR="specs/$FEATURE_NUM-$SLUG"
mkdir -p "$FEATURE_DIR"

# Initialize comprehensive workflow state
# This creates workflow-state.yaml with:
# - Feature metadata (slug, title, branch_name, timestamps, roadmap_status)
# - Deployment model (auto-detected: staging-prod, direct-prod, local-only)
# - Workflow phases tracking
# - Quality gates and manual gates
# - Deployment state (staging, production)
# - Artifacts paths
initialize_workflow_state "$FEATURE_DIR" "$SLUG" "$FEATURE_DESCRIPTION" "$BRANCH_NAME"

echo "✅ Workflow state initialized: $FEATURE_DIR/workflow-state.yaml"
echo ""

# Source roadmap management functions
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  source .spec-flow/scripts/bash/roadmap-manager.sh 2>/dev/null || {
    echo "⚠️  Roadmap management not available on Windows (use PowerShell)"
  }
else
  source .spec-flow/scripts/bash/roadmap-manager.sh
fi

# Mark feature as in progress in roadmap
mark_feature_in_progress "$SLUG" 2>/dev/null || {
  echo "Note: Could not update roadmap (feature may not be in roadmap yet)"
}
echo ""
```

**For continue mode:**

```bash
# Find most recent feature directory
FEATURE_DIR=$(ls -td specs/*/ | head -1)
STATE_FILE="$FEATURE_DIR/workflow-state.yaml"

# Auto-migrate from JSON if needed
if [ ! -f "$STATE_FILE" ] && [ -f "$FEATURE_DIR/workflow-state.json" ]; then
  echo "🔄 Migrating workflow state to YAML..."
  yq eval -P "$FEATURE_DIR/workflow-state.json" > "$STATE_FILE"
fi

if [ ! -f "$STATE_FILE" ]; then
  echo "❌ No workflow state found. Run /feature with a feature description first."
  exit 1
fi

# Source state management functions
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  source .spec-flow/scripts/bash/workflow-state.sh 2>/dev/null
else
  source .spec-flow/scripts/bash/workflow-state.sh
fi

# Get current phase and status
CURRENT_PHASE=$(yq eval '.workflow.phase' "$STATE_FILE")
WORKFLOW_STATUS=$(yq eval '.workflow.status' "$STATE_FILE")

echo "Resuming from: $CURRENT_PHASE (status: $WORKFLOW_STATUS)"
echo ""

# Determine next phase
NEXT_PHASE=$(get_next_phase "$FEATURE_DIR")

if [ -z "$NEXT_PHASE" ]; then
  echo "✅ Workflow already complete!"
  exit 0
fi

echo "Continuing with: $NEXT_PHASE"
echo ""
```

**State Schema:**

The new state file includes comprehensive tracking:
- **Feature metadata**: slug, title, created/updated timestamps
- **Deployment model**: staging-prod, direct-prod, or local-only (auto-detected)
- **Workflow tracking**: current phase, completed phases, failed phases
- **Manual gates**: preview, validate-staging (with approval status)
- **Quality gates**: pre-flight, code review, rollback capability
- **Deployment state**: staging and production (URLs, IDs, timestamps)
- **Artifacts**: Paths to all generated documents
- **Token budget**: Phase-based tracking with compaction alerts

This enables:
- Resume capability via `/ship continue`
- Status visualization via `/deploy-status`
- Deployment model adaptation
- Quality gate blocking
- Rollback capability tracking

## EXECUTION STRATEGY

### Phase 0: Specification (DESIGN)

**Invoke phase agent with minimal context:**

Use Task tool:
```
Task(
  subagent_type="phase/spec",
  description="Phase 0: Create Specification",
  prompt=f"""
Execute Phase 0: Specification in isolated context.

Feature Description: {FEATURE_DESCRIPTION}
Feature Slug: {SLUG}
Feature Number: {FEATURE_NUM}
Project Type: {PROJECT_TYPE}

IMPORTANT CONTEXT:
- The feature branch has already been created: {BRANCH_NAME}
- The feature directory has already been created: specs/{FEATURE_NUM}-{SLUG}/
- Workflow state file already initialized

Your task:
1. Set environment variables for /specify to use:
   - export SLUG="{SLUG}"
   - export FEATURE_NUM="{FEATURE_NUM}"
2. Call /specify slash command with feature description
3. /specify will detect these env vars and skip branch/directory creation
4. Extract key information from resulting spec.md at specs/{FEATURE_NUM}-{SLUG}/
5. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)
```

**Validate phase completion:**

```bash
# Parse result JSON
if [ "$STATUS" != "completed" ]; then
  echo "❌ Phase 0 blocked: $SUMMARY"
  echo "Blockers:"
  # Print blockers from result

  # Update state to failed
  update_workflow_phase "$FEATURE_DIR" "spec-flow" "failed"
  exit 1
fi

# Update workflow state: mark spec-flow phase complete
update_workflow_phase "$FEATURE_DIR" "spec-flow" "completed"

# Store phase summary in artifacts
ARTIFACT_PATH="$FEATURE_DIR/spec.md"
yq eval -i ".artifacts.spec = \"$ARTIFACT_PATH\"" "$STATE_FILE"

# Log progress
echo "✅ Phase 0 complete: $SUMMARY"
echo "Key decisions:"
# Print key_decisions from result
echo ""

# Check if clarification needed
if [ "$NEEDS_CLARIFICATION" = "true" ]; then
  NEXT_PHASE="clarify"
  update_workflow_phase "$FEATURE_DIR" "clarify" "in_progress"
else
  NEXT_PHASE="plan"
  update_workflow_phase "$FEATURE_DIR" "plan" "in_progress"
fi
```

### Phase 0.5: Clarification (CONDITIONAL)

**Only execute if Phase 0 identified clarifications needed:**

```
if needs_clarification:
  Task(
    subagent_type="phase/clarify",
    description="Phase 0.5: Resolve Clarifications",
    prompt=f"""
Execute Phase 0.5: Clarification in isolated context.

Feature Slug: {SLUG}
Previous Phase Summary: {SPEC_SUMMARY}

Your task:
1. Call /clarify slash command
2. Extract clarification results
3. Return structured JSON summary

Refer to your agent brief for full instructions.
    """
  )

  # Validate, store summary, log progress
```

### Phase 1: Planning (DESIGN)

**Invoke phase agent:**

```
Task(
  subagent_type="phase/plan",
  description="Phase 1: Create Plan",
  prompt=f"""
Execute Phase 1: Planning in isolated context.

Feature Slug: {SLUG}
Previous Phase Summary: {SPEC_SUMMARY}
Project Type: {PROJECT_TYPE}

Your task:
1. Call /plan slash command
2. Extract architecture decisions and reuse opportunities
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)

# Validate, store summary, log progress
```

### Phase 2: Task Breakdown (DESIGN)

**Invoke phase agent:**

```
Task(
  subagent_type="phase/tasks",
  description="Phase 2: Create Tasks",
  prompt=f"""
Execute Phase 2: Task Breakdown in isolated context.

Feature Slug: {SLUG}
Previous Phase Summary: {PLAN_SUMMARY}
Project Type: {PROJECT_TYPE}

Your task:
1. Call /tasks slash command
2. Extract task statistics and breakdown
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)

# Validate, store summary, log progress
```

### Phase 2a/2b/2c: Design Workflow (UI Features Only - OPTIONAL)

**Check if UI feature requires design workflow:**

```bash
# Read HAS_UI classification from spec
HAS_UI=$(grep "^- UI screens:" specs/$FEATURE_NUM-$SLUG/NOTES.md | grep -o "true\|false" || echo "false")

if [ "$HAS_UI" = "true" ]; then
  # Check if design workflow was previously disabled
  DESIGN_ENABLED=$(yq eval '.design_workflow.enabled' specs/$FEATURE_NUM-$SLUG/workflow-state.yaml 2>/dev/null || echo "null")

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎨 UI Feature Detected"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "This feature has UI components (screens.yaml created in /specify)."
  echo ""

  # Show re-enable message if previously skipped
  if [ "$DESIGN_ENABLED" = "false" ]; then
    echo "⚠️  Design workflow was previously skipped for this feature."
    echo ""
  fi

  echo "Design Workflow (3-phase pipeline):"
  echo "  Phase 2a: /design-variations → 3-5 grayscale variants per screen"
  echo "  Phase 2b: /design-functional → merge variants + a11y + tests"
  echo "  Phase 2c: /design-polish → brand tokens + performance"
  echo ""
  echo "Benefits:"
  echo "  ✓ Explore UI approaches before coding"
  echo "  ✓ Validate UX with mockups"
  echo "  ✓ Jobs principles enforced (≤2 clicks, no tooltips)"
  echo "  ✓ Design system compliance (tokens, a11y, performance)"
  echo ""
  echo "Options:"
  echo "  [y] Yes - Run design workflow (recommended for UI features)"
  echo "  [n] No - Skip to implementation (manual UI coding)"
  echo ""
  read -p "Run design workflow? (y/n): " RUN_DESIGN

  if [[ "$RUN_DESIGN" =~ ^[Yy]$ ]]; then
    # Update workflow state
    yq eval '.design_workflow.enabled = true' -i specs/$FEATURE_NUM-$SLUG/workflow-state.yaml

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⏳ Phase 2a: Design Variations"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Call /design-variations
    /design-variations $SLUG

    yq eval '.design_workflow.phases.variations = "completed"' -i specs/$FEATURE_NUM-$SLUG/workflow-state.yaml

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 HUMAN CHECKPOINT: Review Variants"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Action required:"
    echo "  1. Open: http://localhost:3000/mock/$SLUG/[screen]"
    echo "  2. Review all variants (test states with ?state=)"
    echo "  3. Fill: specs/$FEATURE_NUM-$SLUG/design/crit.md"
    echo "  4. Mark Keep/Change/Kill decisions for each variant"
    echo ""
    echo "After completing crit.md, resume with:"
    echo "  /feature continue"
    echo ""

    # Pause for human review
    exit 0

  else
    echo ""
    echo "Skipping design workflow. UI will be coded manually in Phase 4."
    yq eval '.design_workflow.enabled = false' -i specs/$FEATURE_NUM-$SLUG/workflow-state.yaml
  fi
fi

# If continuing from design workflow checkpoint
if yq eval '.design_workflow.enabled' specs/$FEATURE_NUM-$SLUG/workflow-state.yaml | grep -q "true"; then
  VARIATIONS_STATUS=$(yq eval '.design_workflow.phases.variations' specs/$FEATURE_NUM-$SLUG/workflow-state.yaml)
  FUNCTIONAL_STATUS=$(yq eval '.design_workflow.phases.functional' specs/$FEATURE_NUM-$SLUG/workflow-state.yaml)
  POLISH_STATUS=$(yq eval '.design_workflow.phases.polish' specs/$FEATURE_NUM-$SLUG/workflow-state.yaml)

  if [ "$VARIATIONS_STATUS" = "completed" ] && [ "$FUNCTIONAL_STATUS" = "not_started" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⏳ Phase 2b: Design Functional"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Call /design-functional
    /design-functional $SLUG

    yq eval '.design_workflow.phases.functional = "completed"' -i specs/$FEATURE_NUM-$SLUG/workflow-state.yaml

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 HUMAN CHECKPOINT: Review Functional Prototype"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Action required:"
    echo "  1. Open: http://localhost:3000/mock/$SLUG/[screen]/functional"
    echo "  2. Test keyboard navigation (Tab, Enter, Space, ESC)"
    echo "  3. Test screen reader (NVDA or VoiceOver)"
    echo "  4. Verify all merged components correct"
    echo ""
    echo "After approval, resume with:"
    echo "  /feature continue"
    echo ""

    # Pause for human review
    exit 0
  fi

  if [ "$FUNCTIONAL_STATUS" = "completed" ] && [ "$POLISH_STATUS" = "not_started" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⏳ Phase 2c: Design Polish"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Call /design-polish
    /design-polish $SLUG

    yq eval '.design_workflow.phases.polish = "completed"' -i specs/$FEATURE_NUM-$SLUG/workflow-state.yaml

    echo ""
    echo "✅ Design workflow complete"
    echo "   Production-ready prototypes: apps/web/mock/$SLUG/*/polished/"
    echo ""
  fi
fi
```

### Phase 3: Analysis (VALIDATION)

**Invoke phase agent:**

```
Task(
  subagent_type="phase/validate",
  description="Phase 3: Cross-Artifact Analysis",
  prompt=f"""
Execute Phase 3: Analysis in isolated context.

Feature Slug: {SLUG}
Previous Phase Summaries:
- Spec: {SPEC_SUMMARY}
- Plan: {PLAN_SUMMARY}
- Tasks: {TASKS_SUMMARY}

Your task:
1. Call /analyze slash command
2. Extract critical issues and validation results
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)

# Check for critical issues (block if found)
# Validate, store summary, log progress
```

### Phase 4: Implementation (EXECUTION)

**Call /implement directly (cannot use phase agent due to sub-agent spawning limits):**

```bash
# Update state (start phase 4)
# Set current_phase = 4, status = "in_progress", record start timestamp

# Execute /implement slash command directly
# This command spawns parallel worker agents internally
# Cannot use implement-phase-agent because sub-agents can't spawn sub-agents
echo "⏳ Phase 4: Implementation"
echo ""
```

**Execute in sequence:**

1. **Run /implement command:**
   - INVOKE: `/implement` (use SlashCommand tool)
   - WAIT: For completion
   - NOTE: This command handles parallel worker agents (backend-dev, frontend-shipper, etc.)
   - VERIFY: All tasks completed

2. **Extract implementation statistics:**
   ```bash
   FEATURE_DIR="specs/$SLUG"
   NOTES_FILE="$FEATURE_DIR/NOTES.md"
   TASKS_FILE="$FEATURE_DIR/tasks.md"
   ERROR_LOG="$FEATURE_DIR/error-log.md"

   # Detect task format (user-story vs tdd-phase)
   TASK_FORMAT="tdd-phase"  # default
   grep -q "\[US[0-9]\]" "$TASKS_FILE" && TASK_FORMAT="user-story"

   if [ "$TASK_FORMAT" = "user-story" ]; then
     # Track by priority/user story
     P1_TOTAL=$(grep -c "\[P1\]" "$TASKS_FILE" 2>/dev/null || echo 0)
     P1_COMPLETE=$(grep -c "✅.*\[P1\]" "$NOTES_FILE" 2>/dev/null || echo 0)
     P2_TOTAL=$(grep -c "\[P2\]" "$TASKS_FILE" 2>/dev/null || echo 0)
     P2_COMPLETE=$(grep -c "✅.*\[P2\]" "$NOTES_FILE" 2>/dev/null || echo 0)
     P3_TOTAL=$(grep -c "\[P3\]" "$TASKS_FILE" 2>/dev/null || echo 0)
     P3_COMPLETE=$(grep -c "✅.*\[P3\]" "$NOTES_FILE" 2>/dev/null || echo 0)

     COMPLETED_COUNT=$((P1_COMPLETE + P2_COMPLETE + P3_COMPLETE))
     TOTAL_TASKS=$((P1_TOTAL + P2_TOTAL + P3_TOTAL))
   else
     # Track by total tasks (TDD format)
     COMPLETED_COUNT=$(grep -c "^✅ T[0-9]\{3\}" "$NOTES_FILE" || echo "0")
     TOTAL_TASKS=$(grep -c "^T[0-9]\{3\}" "$TASKS_FILE" || echo "0")
   fi

   # Get files changed
   FILES_CHANGED=$(git diff --name-only main | wc -l)

   # Check for errors
   ERROR_COUNT=$(grep -c "❌\|⚠️" "$ERROR_LOG" 2>/dev/null || echo "0")
   ```

3. **Create phase summary:**
   ```bash
   if [ "$TASK_FORMAT" = "user-story" ]; then
     SUMMARY="Implemented P1: $P1_COMPLETE/$P1_TOTAL, P2: $P2_COMPLETE/$P2_TOTAL, P3: $P3_COMPLETE/$P3_TOTAL. Changed $FILES_CHANGED files."
   else
     SUMMARY="Implemented $COMPLETED_COUNT/$TOTAL_TASKS tasks. Changed $FILES_CHANGED files."
   fi
   ```
   - Extract key decisions from NOTES.md
   - Store in workflow-state.json phase_summaries
   - Include task_format in phase metadata

4. **Check for blockers:**
   - IF COMPLETED_COUNT < TOTAL_TASKS:
     - LOG: "❌ Implementation incomplete: {COMPLETED_COUNT}/{TOTAL_TASKS} tasks completed"
     - LOG: "Review: {ERROR_LOG}"
     - PAUSE: Exit workflow, return control to user
   - ELSE:
     - LOG: "✅ Implementation complete ({COMPLETED_COUNT}/{TOTAL_TASKS} tasks)"
     - CONTINUE to Phase 5 (no user input needed)

5. **Update state (complete phase 4):**
   - Add 4 to phases_completed
   - Record end timestamp
   - Update last_updated

### Phase 5: Optimization (QUALITY)

**Invoke phase agent:**

```
Task(
  subagent_type="phase/optimize",
  description="Phase 5: Code Review & Optimization",
  prompt=f"""
Execute Phase 5: Optimization in isolated context.

Feature Slug: {SLUG}
Previous Phase Summary: {IMPLEMENT_SUMMARY}

Your task:
1. Call /optimize slash command
2. Extract quality metrics and critical findings
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)

# Check for critical issues (block if found)
# Validate, store summary, log progress with metrics
```

### MANUAL GATE 1: Preview (USER VALIDATION)

**Pause for user validation:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎨 MANUAL GATE: PREVIEW"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next: /preview"
echo ""
echo "Action required:"
echo "1. Run /preview to start local dev server"
echo "2. Test UI/UX flows manually"
echo "3. Verify acceptance criteria from spec"
echo "4. When satisfied, continue: /feature continue"
echo ""

# Update workflow-state.yaml status to "awaiting_preview"
# Save and exit (user will run /feature continue after testing)
```

### Phase 6: Ship to Staging (DEPLOYMENT)

**Check project type (skip for local-only):**

```bash
PROJECT_TYPE=$(yq eval '.deployment_model' "$STATE_FILE")

if [ "$PROJECT_TYPE" = "local-only" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 Local-only project detected"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Skipping staging deployment (no remote repository configured)."
  echo ""
  echo "✅ Feature implementation complete!"
  echo ""
  echo "Next steps (manual deployment):"
  echo "  1. Review changes: git diff main"
  echo "  2. Merge to main: git checkout main && git merge \$FEATURE_BRANCH"
  echo "  3. Tag release: git tag v1.0.0"
  echo "  4. Deploy manually to your environment"
  echo ""

  # Mark workflow complete and exit
  exit 0
fi
```

**For remote projects, invoke phase agent:**

```
Task(
  subagent_type="phase/ship-staging",
  description="Phase 6: Deploy to Staging",
  prompt=f"""
Execute Phase 6: Ship to Staging in isolated context.

Feature Slug: {SLUG}
Project Type: {PROJECT_TYPE}

Your task:
1. Call /phase-1-ship slash command
2. Extract deployment status and PR info
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)

# Validate, store summary, log progress with PR/URL info
```

### MANUAL GATE 2: Validate Staging (USER VALIDATION)

**Pause for staging validation:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 MANUAL GATE: STAGING VALIDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next: /validate-staging"
echo ""
echo "Action required:"
echo "1. Test feature on staging environment"
echo "2. Verify E2E tests passed (GitHub Actions)"
echo "3. Check Lighthouse CI scores"
echo "4. When approved, continue: /feature continue"
echo ""

# Update workflow-state.yaml status to "awaiting_staging_validation"
# Save and exit
```

### Phase 7: Ship to Production (DEPLOYMENT)

**Invoke phase agent:**

```
Task(
  subagent_type="phase/ship-prod",
  description="Phase 7: Deploy to Production",
  prompt=f"""
Execute Phase 7: Ship to Production in isolated context.

Feature Slug: {SLUG}
Project Type: {PROJECT_TYPE}

Your task:
1. Call /phase-2-ship slash command
2. Extract deployment status and release version
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)

# Validate, store summary, log progress with release/URL info
```

### Phase 7.5: Finalize (DOCUMENTATION)

**Invoke phase agent:**

```
Task(
  subagent_type="phase/finalize",
  description="Phase 7.5: Finalize Documentation",
  prompt=f"""
Execute Phase 7.5: Finalization in isolated context.

Feature Slug: {SLUG}
Project Type: {PROJECT_TYPE}

Your task:
1. Call /finalize slash command
2. Extract documentation updates
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)

# Validate, store summary, mark workflow complete
```

### Completion

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Feature Workflow Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Feature: $SLUG"
echo "Status: Shipped to Production"
echo ""
echo "Summary:"
# Print phase summaries from workflow-state.yaml
echo ""
echo "Workflow state saved to specs/$SLUG/workflow-state.yaml"
```

## ERROR HANDLING

**If any phase fails:**

```bash
if [ "$STATUS" = "blocked" ]; then
  echo "❌ Phase $PHASE_NUM blocked"
  echo "Summary: $SUMMARY"
  echo ""
  echo "Blockers:"
  # Print blockers from result
  echo ""
  echo "Fix blockers and continue: /feature continue"

  # Save state with blocker info
  exit 1
fi
```

## BENEFITS SUMMARY

**Token Efficiency:**
- Traditional approach: ~240k tokens (cumulative context)
- `/feature` approach: ~80k tokens (isolated contexts)
- **Savings: 67%**

**Speed:**
- Isolated contexts start fresh (faster Claude response)
- No /compact overhead between phases
- **Improvement: 2-3x faster**

**Quality:**
- Slash commands unchanged (proven workflow)
- Phase agents add thin orchestration layer
- **Maintained: Same quality gates**
