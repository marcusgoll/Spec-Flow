---
description: Orchestrate full feature workflow with isolated phase contexts (optimized)
---

Orchestrate feature delivery through isolated phase agents for maximum efficiency.

<context>
## MENTAL MODEL

**Architecture**: Orchestrator-Workers with Phase Isolation
- **Orchestrator** (`/feature`): Lightweight state tracking, phase progression
- **Phase Agents**: Isolated contexts, fresh token budget, parallel execution
- **Implementation**: `implement-phase-agent` with intelligent task batching
  - Analyzes task dependencies
  - Groups independent tasks into parallel batches
  - Executes batches sequentially with parallel Task() calls per batch

**Benefits**:
- 67% token reduction (240k → 80k per feature)
- 2-3x faster (isolated contexts, no /compact overhead)
- 2x faster implementation (parallel task batching)
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
</context>

<constraints>
## ANTI-HALLUCINATION RULES

**CRITICAL**: Follow these rules to prevent workflow failures from false assumptions.

1. **Never assume phase completion without checking workflow-state.yaml**
   - ❌ BAD: "Spec phase probably completed"
   - ✅ GOOD: Read workflow-state.yaml, quote exact phase status
   - Use Read tool on workflow-state.yaml before determining next phase

2. **Cite actual phase agent outputs when reporting progress**
   - When phase completes: "spec-phase-agent returned: {summary: '...', status: 'completed'}"
   - Quote actual JSON returned by agents
   - Don't paraphrase agent outputs - include key details verbatim

3. **Never skip phases based on assumptions**
   - Don't say "This is simple, we can skip validation"
   - Follow workflow-state.yaml phase sequence exactly
   - If phase marked required, run it - don't bypass

4. **Verify deployment model before selecting workflow path**
   - Read .git/config, .github/workflows/ to detect model
   - Quote evidence: "No staging branch found per `git branch -a` → direct-prod model"
   - Don't assume model - detect it from actual project structure

5. **Never fabricate phase summaries for display**
   - Only show phase summaries actually returned by agents
   - If agent returns error, show error - don't make up success message
   - Quote workflow-state.yaml for historical phase status

**Why this matters**: Skipped phases lead to incomplete features. False phase completion claims hide failures. Accurate workflow orchestration based on actual state ensures all quality gates execute properly.

## REASONING APPROACH

For complex workflow orchestration decisions, show your step-by-step reasoning:

<thinking>
Let me analyze this workflow decision:
1. What phase are we in? [Quote workflow-state.yaml current phase]
2. What did the last phase produce? [List artifacts created]
3. Are prerequisites met for next phase? [Check required artifacts exist]
4. What failures occurred? [List any failed phases, error counts]
5. Should we retry, skip, or abort? [Assess based on failure severity]
6. Conclusion: [Next phase decision with justification]
</thinking>

<answer>
[Workflow decision based on reasoning]
</answer>

**When to use structured thinking:**
- Deciding whether to skip /clarify phase (no ambiguities vs >3 questions)
- Determining which deployment workflow to follow (staging-prod vs direct-prod vs local-only)
- Assessing whether to retry failed phase or abort
- Evaluating whether to continue workflow after partial failures
- Choosing between automatic progression vs manual gate

**Benefits**: Explicit reasoning reduces workflow errors by 30-40% and prevents skipped phases.
</constraints>

<instructions>
## PARSE ARGUMENTS

**Get feature description, continue mode, or next mode:**

If `$ARGUMENTS` is empty, show usage:
```
Usage: /feature [feature description]
   or: /feature continue
   or: /feature next

Examples:
  /feature "Student progress tracking dashboard"
  /feature continue
  /feature next
```

If `$ARGUMENTS` is "continue":
- Set `CONTINUE_MODE = true`
- Load workflow state from `specs/*/workflow-state.yaml`
- Resume from last completed phase

Else if `$ARGUMENTS` is "next":
- Set `NEXT_MODE = true`
- Query GitHub Issues for highest priority roadmap item
- Extract slug and feature description
- Initialize new workflow with auto-fetched feature

Else:
- Set `CONTINUE_MODE = false`
- Set `NEXT_MODE = false`
- Set `FEATURE_DESCRIPTION = $ARGUMENTS`
- Initialize new workflow

## FETCH NEXT FEATURE

**Only execute if `NEXT_MODE = true`:**

```bash
# Check GitHub authentication
if ! command -v gh &> /dev/null; then
  echo "❌ GitHub CLI (gh) not installed"
  echo "Install: https://cli.github.com"
  exit 1
fi

# Verify authentication
if ! gh auth status &> /dev/null; then
  echo "❌ GitHub authentication required"
  echo "Run: gh auth login"
  exit 1
fi

# Get repository info
REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
if [ -z "$REPO" ]; then
  echo "❌ Not in a GitHub repository"
  exit 1
fi

echo "🔍 Searching for highest priority roadmap item..."
echo ""

# Query GitHub Issues for highest priority feature in status:next
# Sort by priority labels (high → medium → low)
NEXT_ISSUE=$(gh issue list \
  --repo "$REPO" \
  --label "status:next,type:feature" \
  --json number,title,body,labels \
  --limit 50 | jq -r '
    map(select(.labels | any(.name | startswith("priority:")))) |
    sort_by(
      .labels[] |
      select(.name | startswith("priority:")) |
      .name |
      if . == "priority:high" then 1
      elif . == "priority:medium" then 2
      elif . == "priority:low" then 3
      else 4 end
    ) |
    first // empty')

# If no items in status:next, fall back to status:backlog
if [ -z "$NEXT_ISSUE" ]; then
  echo "⚠️  No items found in status:next, checking status:backlog..."
  echo ""

  NEXT_ISSUE=$(gh issue list \
    --repo "$REPO" \
    --label "status:backlog,type:feature" \
    --json number,title,body,labels \
    --limit 50 | jq -r '
      map(select(.labels | any(.name | startswith("priority:")))) |
      sort_by(
        .labels[] |
        select(.name | startswith("priority:")) |
        .name |
        if . == "priority:high" then 1
        elif . == "priority:medium" then 2
        elif . == "priority:low" then 3
        else 4 end
      ) |
      first // empty')
fi

# If still no items found, error
if [ -z "$NEXT_ISSUE" ]; then
  echo "❌ No roadmap items found in status:next or status:backlog"
  echo ""
  echo "Create a roadmap item first:"
  echo "  /roadmap add \"Feature description\""
  echo ""
  echo "Or use /feature with a description:"
  echo "  /feature \"Your feature description\""
  exit 1
fi

# Extract issue details
ISSUE_NUMBER=$(echo "$NEXT_ISSUE" | jq -r '.number')

# CRITICAL: Update issue status to in-progress IMMEDIATELY to prevent race conditions
# This must happen before any other operations to ensure multiple worktrees don't select the same issue
echo "📌 Claiming issue #$ISSUE_NUMBER (updating status to in-progress)..."
gh issue edit "$ISSUE_NUMBER" \
  --remove-label "status:next" \
  --remove-label "status:backlog" \
  --add-label "status:in-progress" \
  --repo "$REPO" 2>/dev/null || {
    echo "⚠️  Warning: Could not update issue status (may already be claimed)"
  }
echo ""

ISSUE_TITLE=$(echo "$NEXT_ISSUE" | jq -r '.title')
ISSUE_BODY=$(echo "$NEXT_ISSUE" | jq -r '.body // ""')

# Extract slug from YAML frontmatter in issue body
# Expected format: slug: "feature-slug"
EXTRACTED_SLUG=$(echo "$ISSUE_BODY" | grep -oP '^slug:\s*"\K[^"]+' | head -1)

# If no slug in frontmatter, generate from title
if [ -z "$EXTRACTED_SLUG" ]; then
  echo "⚠️  No slug found in issue frontmatter, generating from title..."
  EXTRACTED_SLUG=$(echo "$ISSUE_TITLE" |
    tr '[:upper:]' '[:lower:]' |
    sed 's/[^a-z0-9-]/-/g' |
    sed 's/--*/-/g' |
    sed 's/^-//;s/-$//' |
    cut -c1-20 |
    sed 's/-$//')
fi

# Extract feature description from title
FEATURE_DESCRIPTION="$ISSUE_TITLE"

# Display confirmation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Feature Claimed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Issue: #$ISSUE_NUMBER"
echo "Title: $ISSUE_TITLE"
echo "Slug: $EXTRACTED_SLUG"
echo "Status: ✅ in-progress (claimed)"
echo ""

# Extract priority and ICE score for display
PRIORITY=$(echo "$NEXT_ISSUE" | jq -r '.labels[] | select(.name | startswith("priority:")) | .name' | sed 's/priority://')
ICE_IMPACT=$(echo "$ISSUE_BODY" | grep -oP '^impact:\s*\K\d+' | head -1)
ICE_CONFIDENCE=$(echo "$ISSUE_BODY" | grep -oP '^confidence:\s*\K\d+' | head -1)
ICE_EFFORT=$(echo "$ISSUE_BODY" | grep -oP '^effort:\s*\K[\d.]+' | head -1)

if [ -n "$ICE_IMPACT" ] && [ -n "$ICE_CONFIDENCE" ] && [ -n "$ICE_EFFORT" ]; then
  ICE_SCORE=$(echo "scale=2; ($ICE_IMPACT * $ICE_CONFIDENCE) / $ICE_EFFORT" | bc)
  echo "Priority: $PRIORITY (ICE Score: $ICE_SCORE)"
  echo "  Impact: $ICE_IMPACT | Confidence: $ICE_CONFIDENCE | Effort: $ICE_EFFORT"
else
  echo "Priority: $PRIORITY"
fi
echo ""
echo "Starting feature workflow..."
echo ""

# Continue with normal workflow using extracted values
SLUG="$EXTRACTED_SLUG"
```

**Important**: After fetching, continue to GENERATE FEATURE SLUG section (which will use the extracted SLUG), then proceed normally through the workflow.

## GENERATE FEATURE SLUG

**Generate slug from feature description before any file/branch operations:**

**Skip if already set by NEXT_MODE:**

```bash
# If SLUG already set (from /feature next), skip generation
if [ -z "$SLUG" ]; then
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

  echo "📝 Generated slug: $SLUG"
  echo "   From: $FEATURE_DESCRIPTION"
  echo ""
else
  echo "📝 Using slug from roadmap: $SLUG"
  echo ""
fi

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
n# Start timing for spec-flow phase
start_phase_timing "$FEATURE_DIR" "spec-flow"

# If using /feature next, store GitHub issue number for tracking
if [ -n "$ISSUE_NUMBER" ]; then
  yq eval -i ".feature.github_issue = $ISSUE_NUMBER" "$FEATURE_DIR/workflow-state.yaml"
  echo "🔗 Linked to GitHub Issue #$ISSUE_NUMBER"
fi

echo "✅ Workflow state initialized: $FEATURE_DIR/workflow-state.yaml"
echo ""

# Source roadmap management functions
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  source .spec-flow/scripts/bash/github-roadmap-manager.sh 2>/dev/null || {
    echo "⚠️  Roadmap management not available on Windows (use PowerShell)"
  }
else
  source .spec-flow/scripts/bash/github-roadmap-manager.sh
fi

# Mark feature as in progress in roadmap (GitHub Issues)
mark_issue_in_progress "$SLUG" 2>/dev/null || {
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
n# Complete timing for spec-flow phase
complete_phase_timing "$FEATURE_DIR" "spec-flow"
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

**Use implement-phase-agent for fresh context and parallel task execution:**

```
Task(
  subagent_type="implement-phase-agent",
  description="Phase 4: Execute Implementation",
  prompt=f"""
Execute Phase 4: Implementation in isolated context with intelligent task batching.

Feature Directory: {FEATURE_DIR}
Feature Slug: {SLUG}
Project Type: {PROJECT_TYPE}

Previous Phase Summaries:
- Spec: {SPEC_SUMMARY}
- Plan: {PLAN_SUMMARY}
- Tasks: {TASKS_SUMMARY}

IMPORTANT CONTEXT:
- Feature directory exists: {FEATURE_DIR}
- Workflow state initialized: {FEATURE_DIR}/workflow-state.yaml
- Tasks defined: {FEATURE_DIR}/tasks.md
- Implementation notes: {FEATURE_DIR}/NOTES.md

Your task:
1. Read workflow context from NOTES.md, workflow-state.yaml, tasks.md
2. Analyze task dependencies to identify parallel batching opportunities
3. Group independent tasks into batches
4. Execute each batch using parallel Task() calls
5. Wait for batch completion before starting dependent batches
6. Update NOTES.md with progress after each batch
7. Return structured summary with completion stats

Expected output format:
{{
  "status": "completed" | "failed" | "blocked",
  "summary": "Brief completion summary with stats",
  "stats": {{
    "total_tasks": <number>,
    "completed_tasks": <number>,
    "files_changed": <number>,
    "error_count": <number>,
    "batches_executed": <number>
  }},
  "blockers": ["List of blocking issues if status != completed"],
  "key_decisions": ["Key implementation decisions made"]
}}

Refer to your agent brief (.claude/agents/phase/implement.md) for full instructions including:
- Dependency analysis algorithm
- Batch execution strategy
- Error handling and recovery
- Progress tracking format

CRITICAL: Use fresh context by reading from files - do not assume context from previous phases.
  """
)
```

**Validate phase completion:**

```bash
# Parse agent result
AGENT_RESULT=$(cat /tmp/implement-agent-result.json 2>/dev/null || echo '{}')
STATUS=$(echo "$AGENT_RESULT" | jq -r '.status // "unknown"')
SUMMARY=$(echo "$AGENT_RESULT" | jq -r '.summary // "No summary"')
COMPLETED=$(echo "$AGENT_RESULT" | jq -r '.stats.completed_tasks // 0')
TOTAL=$(echo "$AGENT_RESULT" | jq -r '.stats.total_tasks // 0')
ERRORS=$(echo "$AGENT_RESULT" | jq -r '.stats.error_count // 0')
BATCHES=$(echo "$AGENT_RESULT" | jq -r '.stats.batches_executed // 0')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Implementation Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Summary: $SUMMARY"
echo "Tasks: $COMPLETED/$TOTAL completed"
echo "Batches: $BATCHES executed"
echo "Errors: $ERRORS logged"
echo ""

# Check for blockers
if [ "$STATUS" != "completed" ]; then
  echo "❌ Implementation blocked"
  echo ""
  echo "Blockers:"
  echo "$AGENT_RESULT" | jq -r '.blockers[]'
  echo ""
  echo "Error log: $FEATURE_DIR/error-log.md"
  echo ""
  echo "Options:"
  echo "  1. Fix blockers manually and run: /feature continue"
  echo "  2. Review agent output above for guidance"
  echo ""

  update_workflow_phase "$FEATURE_DIR" "implement" "failed"
  exit 1
fi

# Check completion threshold
if [ "$COMPLETED" -lt "$TOTAL" ]; then
  COMPLETION_RATE=$(echo "scale=2; $COMPLETED * 100 / $TOTAL" | bc)
  echo "⚠️  Incomplete: $COMPLETION_RATE% of tasks completed"
  echo ""
  echo "Fix remaining tasks and run: /feature continue"
  update_workflow_phase "$FEATURE_DIR" "implement" "failed"
  exit 1
fi

echo "✅ Implementation complete ($COMPLETED/$TOTAL tasks, $BATCHES batches)"
echo ""

# Store phase summary
yq eval -i ".workflow.phases.implement.summary = \"$SUMMARY\"" "$FEATURE_DIR/workflow-state.yaml"
yq eval -i ".workflow.phases.implement.stats = {}" "$FEATURE_DIR/workflow-state.yaml"
yq eval -i ".workflow.phases.implement.stats.completed = $COMPLETED" "$FEATURE_DIR/workflow-state.yaml"
yq eval -i ".workflow.phases.implement.stats.total = $TOTAL" "$FEATURE_DIR/workflow-state.yaml"
yq eval -i ".workflow.phases.implement.stats.batches = $BATCHES" "$FEATURE_DIR/workflow-state.yaml"

update_workflow_phase "$FEATURE_DIR" "implement" "completed"
```

**Auto-continue to Phase 5 (Optimization):**
   ```bash
   echo ""
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   echo "🔧 Auto-continuing to Phase 5: Optimization"
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   echo ""

   # Call /optimize directly (handles parallel execution internally)
   /optimize

   # Check if optimization completed successfully
   if ! test_phase_completed "$FEATURE_DIR" "optimize"; then
     echo "❌ Optimization failed. Review issues and run: /feature continue"
     exit 1
   fi

   # Check for critical code review issues
   CRITICAL_ISSUES=0
   if [ -f "$FEATURE_DIR/code-review.md" ]; then
     CRITICAL_ISSUES=$(grep -c "Severity: CRITICAL" "$FEATURE_DIR/code-review.md" 2>/dev/null || echo 0)
   fi

   if [ "$CRITICAL_ISSUES" -gt 0 ]; then
     echo ""
     echo "❌ $CRITICAL_ISSUES critical code review issues found"
     echo "Review: $FEATURE_DIR/code-review.md"
     echo ""
     echo "Options:"
     echo "  1. Fix issues manually and run: /feature continue"
     echo "  2. Re-run /optimize with auto-fix enabled"
     echo ""
     exit 1
   fi

   echo "✅ Optimization complete - no critical issues"
   ```

6. **Auto-continue to Phase 6 (Ship):**
   ```bash
   echo ""
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   echo "🚀 Auto-continuing to Phase 6: Ship"
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   echo ""

   # Call /ship directly (handles all deployment phases and manual gates)
   /ship

   # If /ship completes, workflow is done
   echo ""
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   echo "🎉 Feature Workflow Complete!"
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   echo ""
   echo "Feature: $SLUG"
   echo "Summary: $FEATURE_DIR/ship-summary.md"
   echo ""
n   # Display comprehensive timing summary
   display_workflow_summary "$FEATURE_DIR"
   ```

### Completion

The `/feature` command now automatically continues from implementation through optimization to deployment, stopping only at:
- **Blocking errors**: Build failures, critical code review issues, deployment failures
- **Manual gates**: MVP gate (during implement), pre-flight approval, preview testing, staging validation (all handled by respective commands)

To resume after a manual gate or fix blocking errors:
```bash
/feature continue
```

### Old Phases (Removed)

The following phase descriptions are removed as they're now handled by auto-continue:
- Phase 5: Optimization (handled by `/optimize` call)
- Manual Gates: Preview, Staging Validation (handled by `/ship` command)
- Phase 6 & 7: Deployment phases (handled by `/ship` command)

## Resume After Manual Gates or Errors

If the workflow stops at a manual gate or encounters an error, you can resume with:

```bash
/feature continue
```

This will:
- Load the most recent feature from `workflow-state.yaml`
- Determine which phase was in progress or failed
- Resume from that phase automatically

**Resume conditions:**
- If implementation incomplete → Retry `/implement`
- If optimization failed → Retry `/optimize`
- If critical issues found → Fix then retry
- If at manual gate → Continue to next phase

**Example:**
```bash
# Workflow stopped after preview manual gate
/feature continue
# → Continues to /ship deployment phases
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
</instructions>
