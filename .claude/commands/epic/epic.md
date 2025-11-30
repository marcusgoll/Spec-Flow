---
description: Execute multi-sprint epic workflow from interactive scoping through deployment with parallel sprint execution and self-improvement
argument-hint: [epic description | slug | continue | next] [--auto | --interactive | --no-input]
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Task, AskUserQuestion, TodoWrite, SlashCommand, Skill]
version: 5.2
updated: 2025-11-20
---

# /epic — Epic-Level Workflow Orchestration

**Purpose**: Transform high-level product goals into coordinated multi-sprint implementations with parallel execution, self-adaptation, and comprehensive walkthrough documentation.

**Command**: `/epic [epic description | slug | continue | next] [--auto | --interactive | --no-input]`

**Flags**:

- `--auto`: Run in auto mode - bypass all interactive prompts except critical blockers (CI failures, security issues, deployment errors)
- `--interactive`: Force interactive mode - pause at spec review and plan review (overrides config/history)
- `--no-input`: Non-interactive mode for CI/CD - same as --auto but explicitly signals automation context

**When to use**: For complex features requiring multiple sprints (>2 sprints), cross-cutting concerns, or when automatic sprint decomposition and parallel execution would accelerate delivery.

---

## Mental Model

**Architecture: Epic Orchestrator + Meta-Prompting + Parallel Sprint Execution**

- **Orchestrator** (`/epic`): Manages epic lifecycle, auto-triggers /init-project if needed, coordinates sprint dependencies
- **Meta-Prompting**: Research → Plan → Implement pipeline with isolated sub-agent execution
- **Parallel Sprints**: Dependency graph analysis enables simultaneous sprint execution
- **Adaptive**: Analyzes patterns across epics, generates project-specific tooling

**Benefits**: 3-5x faster delivery, LLM-optimized XML documentation, self-improving workflow, project-aware tooling generation.

---

<context>
**User Input**: $ARGUMENTS

**Project State**: !`test -d docs/project && echo "initialized" || echo "missing"`

**Git Configuration**:

- Remote: !`git remote -v 2>$null | Select-String -Pattern "origin" -Quiet && echo "configured" || echo "none"`
- Current branch: !`git branch --show-current 2>$null || echo "none"`
- Staging workflow: !`test -f .github/workflows/deploy-staging.yml && echo "present" || echo "missing"`

**Epic Workspace**: !`dir /b /ad epics 2>$null || echo "none"`

**Workflow State**: @epics/\*/state.yaml
</context>

<objective>
Execute multi-sprint epic workflow for: $ARGUMENTS

Transform high-level product goals into coordinated multi-sprint implementations through:

1. Interactive scoping with question bank (8-9 structured questions)
2. Meta-prompted research and planning (isolated sub-agents)
3. Parallel sprint execution (dependency graph-driven)
4. Adaptive quality gates and deployment (model auto-detection)
5. Comprehensive walkthrough generation and self-improvement

**Deployment model** auto-detected from git configuration:

- staging-prod: Git remote + staging branch + staging workflow
- direct-prod: Git remote without staging infrastructure
- local-only: No git remote configured

**Auto-mode** (if --auto flag present):

- Skip spec review PAUSE
- Auto-execute research/planning prompts without "What's next?" prompt
- Skip plan review PAUSE
- Only stop for critical blockers: CI failures, security issues, deployment errors
  </objective>

<process>
### Step 0.1: Load User Preferences (3-Tier System)

**Determine execution mode using 3-tier preference system:**

1. **Load configuration file** (Tier 1 - lowest priority):

   ```powershell
   # Load from .spec-flow/config/user-preferences.yaml
   $preferences = & .spec-flow/scripts/utils/load-preferences.ps1 -Command "epic"
   $configMode = $preferences.commands.epic.default_mode  # "interactive" or "auto"
   ```

2. **Load command history** (Tier 2 - medium priority, overrides config):

   ```powershell
   # Load from .spec-flow/memory/command-history.yaml
   $history = & .spec-flow/scripts/utils/load-command-history.ps1 -Command "epic"

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
   const epicDescription = args
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

   ```javascript
   // Only prompt if no flag provided and not in CI mode
   if (!hasAutoFlag && !hasInteractiveFlag && !hasNoInput) {
     // Use AskUserQuestion with learned preferences
     const options = [
       {
         label:
           history.last_used_mode === "auto"
             ? `Auto (last used, ${history.usage_count.auto}/${history.total_uses} times) ⭐`
             : "Auto",
         description: "Skip all prompts, run until blocker",
       },
       {
         label:
           history.last_used_mode === "interactive"
             ? `Interactive (last used, ${history.usage_count.interactive}/${history.total_uses} times) ⭐`
             : "Interactive",
         description: "Pause at spec review and plan review",
       },
     ];

     // Show prompt with smart suggestions
     // Mark last-used with ⭐ if preferences.ui.recommend_last_used === true
     // Show usage stats if preferences.ui.show_usage_stats === true
   }
   ```

5. **Create/update state.yaml and track usage:**

   ```yaml
   # epics/{EPIC_SLUG}/state.yaml
   epic:
     number: { EPIC_NUMBER }
     slug: { EPIC_SLUG }
     title: { EPIC_TITLE }
     auto_mode: { true|false } # Based on selectedMode
     started_at: { ISO_TIMESTAMP }
     current_phase: specification

   phases:
     specification:
       status: in_progress
       started_at: { ISO_TIMESTAMP }
     research:
       status: pending
     planning:
       status: pending
     implementation:
       status: pending
     optimization:
       status: pending
     deployment:
       status: pending
     finalization:
       status: pending

   manual_gates:
     spec_review:
       status: { auto_skipped|pending } # auto_skipped if auto_mode: true
       blocking: { false|true } # false if auto_mode: true
       skipped_at: { ISO_TIMESTAMP } # if auto_skipped
     plan_review:
       status: { auto_skipped|pending } # auto_skipped if auto_mode: true
       blocking: { false|true } # false if auto_mode: true
       skipped_at: { ISO_TIMESTAMP } # if auto_skipped

   sprints:
     total: 0 # Updated after planning
     completed: 0
     failed: 0

   layers:
     total: 0 # Updated after planning
     completed: 0
   ```

   ```powershell
   # Display selected mode
   if ($selectedMode -eq 'auto') {
       "🤖 Auto-mode enabled - will run automatically until blocker"
       # manual_gates.*.status set to "auto_skipped"
   } else {
       "📋 Interactive mode - will pause at reviews"
       # manual_gates.*.status set to "pending"
   }

   # Track this usage for learning system
   & .spec-flow/scripts/utils/track-command-usage.ps1 -Command "epic" -Mode $selectedMode
   ```

**If auto-mode selected:**

- Bypass all PAUSE points (spec review, plan review)
- Auto-execute `/run-prompt` after `/create-prompt` (skip "What's next?" prompt)
- Only stop for critical blockers: CI failures, security issues, deployment errors

**If interactive mode selected:**

- Follow standard workflow with manual PAUSE points

### Step 0.2: Auto-Initialize Project (If Needed)

**Check for project initialization:**

```bash
test -d docs/project && echo "initialized" || echo "missing"
```

**If missing, auto-trigger project setup:**

1. Use AskUserQuestion tool:

   - **Question**: "No project documentation found. Initialize project now?"
   - **Options**:
     - "Yes, full setup" → Run /init-project + optional /init-brand-tokens
     - "Quick setup" → Run /init-project with minimal questions
     - "Skip" → Continue without project docs (not recommended)

2. If user selects initialization:
   - Run `/init-project` command
   - Detect project type: Check for `package.json`, `requirements.txt`, etc.
   - Ask: "Is this a UI project?" → If yes, run `/init-brand-tokens`
   - Ask: "Use default engineering principles?" → If no, run `/constitution`

**Once project initialized, proceed to epic creation.**

### Step 0.3: Prototype Detection (Non-Blocking)

**Check for project prototype before starting specification:**

```bash
# Check if prototype exists
PROTOTYPE_EXISTS=$(test -f design/prototype/state.yaml && echo "true" || echo "false")
```

**If prototype exists:**

1. Analyze epic description for UI keywords:
   ```javascript
   const uiKeywords = [
     'screen', 'page', 'view', 'dashboard', 'modal', 'dialog',
     'form', 'list', 'table', 'settings', 'profile', 'wizard',
     'UI', 'frontend', 'interface'
   ];
   const description = "$ARGUMENTS".toLowerCase();
   const hasUIIntent = uiKeywords.some(kw => description.includes(kw));
   ```

2. If UI intent detected, compare against prototype screen registry:
   ```bash
   # Read existing screens from prototype
   cat design/prototype/state.yaml
   ```

3. If new screens might be needed for this epic, soft prompt user via AskUserQuestion:
   ```json
   {
     "question": "This epic may require new UI screens. Update prototype first?",
     "header": "Prototype",
     "multiSelect": false,
     "options": [
       {"label": "Yes, update prototype", "description": "Add screens for this epic to prototype now (recommended for cohesive design)"},
       {"label": "Later", "description": "Skip for now, can update prototype during sprint planning"},
       {"label": "Not needed", "description": "This epic doesn't require new screens"}
     ]
   }
   ```

4. **If "Yes"**: Pause and suggest running `/prototype update`
5. **If "Later" or "Not needed"**: Continue to specification phase

**If no prototype exists**: Skip silently (backward compatible)

**Note**: This is a soft prompt, not a blocking gate. Epics can proceed without prototype.

---

### Step 1: Create Epic Specification

**Parse user input and detect complexity:**

- If description < 50 words → Likely simple feature, suggest `/feature` instead
- If description mentions multiple subsystems/phases → Epic candidate
- If unclear → Use AskUserQuestion to clarify scope

**Use AskUserQuestion extensively for clarification:**

```javascript
// Example questions (adaptive based on description analysis)
AskUserQuestion({
  questions: [
    {
      question: "What type of epic is this?",
      header: "Epic Type",
      multiSelect: false,
      options: [
        { label: "New feature", description: "Brand new functionality" },
        { label: "Enhancement", description: "Improve existing features" },
        {
          label: "Refactoring",
          description: "Improve code without changing behavior",
        },
        {
          label: "Infrastructure",
          description: "Dev tools, CI/CD, monitoring",
        },
      ],
    },
    {
      question: "What subsystems are involved?",
      header: "Subsystems",
      multiSelect: true,
      options: [
        {
          label: "Backend API",
          description: "Server-side logic and endpoints",
        },
        { label: "Frontend UI", description: "User interface components" },
        { label: "Database", description: "Schema changes or data migrations" },
        {
          label: "Infrastructure",
          description: "Deployment, monitoring, CI/CD",
        },
      ],
    },
    {
      question: "What's the complexity level?",
      header: "Complexity",
      multiSelect: false,
      options: [
        {
          label: "Small (2-3 sprints)",
          description: "~1 week, clear requirements",
        },
        {
          label: "Medium (4-6 sprints)",
          description: "2-3 weeks, some unknowns",
        },
        {
          label: "Large (7+ sprints)",
          description: "1+ month, significant research needed",
        },
      ],
    },
  ],
});
```

**Generate epic specification (Markdown format):**

```bash
# Step 1: Branch, Worktree, and Epic Workspace Creation
# Uses create-new-epic.sh script which handles:
# - Worktree creation (if worktrees.auto_create is true in user-preferences.yaml)
# - Git branch creation (fallback if worktrees disabled)
# - Epic directory structure (epics/NNN-slug/)
# - Initial files: epic-spec.md, state.yaml, NOTES.md
# - Subdirectories: visuals/, artifacts/, mockups/

# Execute the script with JSON output for parsing
EPIC_RESULT=$(bash .spec-flow/scripts/bash/create-new-epic.sh --json "$EPIC_DESCRIPTION")

# Parse results
EPIC_DIR=$(echo "$EPIC_RESULT" | grep -o '"EPIC_DIR": *"[^"]*"' | sed 's/"EPIC_DIR": *"//' | sed 's/"$//')
BRANCH_NAME=$(echo "$EPIC_RESULT" | grep -o '"BRANCH_NAME": *"[^"]*"' | sed 's/"BRANCH_NAME": *"//' | sed 's/"$//')
WORKTREE_ENABLED=$(echo "$EPIC_RESULT" | grep -o '"WORKTREE_ENABLED": *[^,}]*' | sed 's/"WORKTREE_ENABLED": *//')
WORKTREE_PATH=$(echo "$EPIC_RESULT" | grep -o '"WORKTREE_PATH": *"[^"]*"' | sed 's/"WORKTREE_PATH": *"//' | sed 's/"$//')
SLUG=$(echo "$EPIC_RESULT" | grep -o '"SLUG": *"[^"]*"' | sed 's/"SLUG": *"//' | sed 's/"$//')

echo ""
echo "Epic workspace created:"
echo "   Directory: $EPIC_DIR"
echo "   Branch: $BRANCH_NAME"
echo "   Worktree: $([[ "$WORKTREE_ENABLED" == "true" ]] && echo "Yes ($WORKTREE_PATH)" || echo "No")"
echo ""

# If worktree was created, switch to that directory for subsequent work
if [[ "$WORKTREE_ENABLED" == "true" && -n "$WORKTREE_PATH" ]]; then
    cd "$WORKTREE_PATH"
fi

# Script already created:
# - epic-spec.md (template with placeholders)
# - state.yaml (workflow state tracking)
# - NOTES.md (session notes)
# - visuals/, artifacts/, mockups/ directories

# Now proceed to populate epic-spec.md with structured scoping questions (Step 1.5)
```

**Epic specification structure:**

```markdown
---
number: NNN
slug: epic-slug
title: Epic Title
type: new-feature|enhancement|refactoring|infrastructure
complexity: small|medium|large
created: 2025-11-19
---

# Epic NNN: Epic Title

## Objective

### Business Value

What this delivers to users/business

### Success Metrics

How we measure success

### Constraints

Technical, time, or resource constraints

## Subsystems

### Backend

**Involved**: Yes/No
Changes needed

### Frontend

**Involved**: Yes/No
Changes needed

### Database

**Involved**: Yes/No
Changes needed

## Clarifications

<!-- Filled by /clarify phase -->
```

**Commit epic specification (atomic commit #1):**

```bash
# Auto-invoke git-workflow-enforcer skill for atomic commit
# Or manually commit if skill unavailable:

EPIC_SLUG=$(yq -r '.slug' epics/*/state.yaml)
EPIC_TYPE=$(yq -r '.epic.type // "epic"' epics/*/epic-spec.md)
COMPLEXITY=$(yq -r '.epic.complexity // "unknown"' epics/*/epic-spec.md)
SUBSYSTEMS=$(yq -r '.epic.subsystems | length // 0' epics/*/epic-spec.md)

git add epics/${EPIC_SLUG}/
git commit -m "docs(epic-spec): create specification for ${EPIC_SLUG}

Type: ${EPIC_TYPE}
Complexity: ${COMPLEXITY}
Subsystems: ${SUBSYSTEMS}

Next: /clarify (if needed) or research phase

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Alternative (recommended): Use git-workflow-enforcer skill:**

```bash
# Invoke skill to auto-generate commit
/meta:enforce-git-commits --phase "epic-specification"
```

**PAUSE (Interactive Mode Only)**: Review epic-spec.md. User can run `/clarify` if ambiguous, or continue to planning.

**When paused (interactive mode):**

- Display: "📋 Spec review complete. Continue to planning? (y/n)"
- If approved, update state.yaml:
  ```yaml
  manual_gates:
    spec_review:
      status: approved
      approved_at: { ISO_TIMESTAMP }
      approved_by: user
  ```

**If auto-mode enabled**:

- Skip this PAUSE - proceed directly to Step 1.5
- Manual gate already set to "auto_skipped" in state.yaml (from Step 0.1)

### Step 1.5: Interactive Epic Scoping (Question Bank-Driven)

**Purpose**: Systematically scope the epic with 5 rounds of structured questions (8-9 total), eliminating ambiguity before planning.

**When to invoke**: Always for new epics. Skip if resuming with `/epic continue`.

**Skill reference**: See `.claude/skills/epic-scoping/SKILL.md` for detailed implementation.

**Quick summary**:

1. **Round 1**: Business goal + subsystem selection (2 questions)
2. **Round 2**: Scope refinement per subsystem (0-4 conditional)
3. **Round 3**: Success metrics (2 questions)
4. **Round 4**: Dependencies & constraints (2 questions)
5. **Round 5**: Complexity assessment (2 questions)

**Output**: Fully populated epic-spec.md with zero ambiguities, ready for /plan.

**Velocity benefit**: 5-10 minutes vs 30+ minutes unstructured (3-6x faster)

### Step 2: Auto-Invoke Clarification (If Needed)

**NEW in v5.0**: With interactive scoping (Step 1.5), /clarify should **rarely** be needed for epics.

**Ambiguity check** (after interactive scoping):

- Count placeholders in epic-spec.md: `grep -c "\[NEEDS CLARIFICATION\]" epics/NNN-slug/epic-spec.md`
- Check for missing subsystems
- Verify success metrics defined
- Confirm constraints documented

**If ambiguities detected** (ambiguity score > 30):

```bash
/clarify
```

**The /clarify command will:**

- Use AskUserQuestion for 2-6 targeted questions
- Validate answers against project docs (tech-stack.md, architecture.md)
- Update epic-spec.md with clarifications
- Mark clarification phase complete in state.yaml

**Expected outcome**: With 5-round interactive scoping (Step 1.5), most epics have ambiguity score < 30 and skip /clarify entirely.

**If clear** (score ≤ 30), skip /clarify and proceed to planning.

### Step 3: Meta-Prompting for Research & Planning

**Purpose**: Use isolated sub-agents via `/create-prompt` and `/run-prompt` to generate research and planning artifacts.

**Skill reference**: See `.claude/skills/epic-meta-prompting/SKILL.md` for detailed implementation.

**Process summary**:

1. `/create-prompt "Research technical approach for: [epic objective]"` → generates research prompt
2. `/run-prompt 001-[epic-slug]-research` → executes research, outputs research.md
3. `/create-prompt "Create implementation plan based on research"` → generates plan prompt
4. `/run-prompt 002-[epic-slug]-plan` → executes planning, outputs plan.md
5. Commit both artifacts with `/meta:enforce-git-commits`

**Outputs**: `research.md` (findings, confidence, open questions) and `plan.md` (architecture, phases, risks)

**PAUSE (Interactive Mode Only)**: Review research.md and plan.md before sprint breakdown.

**Auto-mode**: Skips PAUSE, proceeds directly to Step 4.

### Step 4: Sprint Breakdown with Dependency Graph

**Purpose**: Generate sprint-plan.md with dependency graph and execution layers for parallel implementation.

**Skill reference**: See `.claude/skills/epic-sprints/SKILL.md` for detailed implementation.

**Invoke**: `/tasks` (reads plan.md, generates sprint breakdown)

**Process**:

1. Analyze complexity and identify sprint boundaries
2. Build dependency graph between sprints
3. Lock API contracts for parallel work
4. Generate execution layers for parallelization

**Outputs**:

- `sprint-plan.md` - Sprints with dependencies, hours, subsystems, locked contracts
- `tasks.md` - All tasks across sprints with acceptance criteria
- `contracts/api/*.yaml` - Locked API contracts

**Commit**: `/meta:enforce-git-commits --phase "epic-sprint-breakdown"`

### Step 5: Parallel Sprint Implementation

**Invoke /implement-epic for parallel sprint execution:**

```bash
# Read auto_mode from state.yaml
AUTO_MODE=$(yq -r '.epic.auto_mode // "false"' epics/*/state.yaml)

# Pass auto_mode flag to implement-epic
if [ "$AUTO_MODE" = "true" ]; then
    /implement-epic --auto-mode
else
    /implement-epic
fi
```

**The /implement-epic phase will:**

1. Read sprint-plan.md to get execution layers
2. For each layer:
   - Launch parallel Task agents (one per sprint in layer)
   - Each agent reads:
     - epic-spec.md (requirements)
     - research.md (findings)
     - plan.md (architecture)
     - tasks.md (filtered to sprint)
     - Locked API contracts
   - Wait for all agents in layer to complete
   - Validate outputs:
     - Tests passing
     - Types checking
     - Contracts respected
     - No breaking changes
3. Continuous validation during implementation:
   - TDD enforcement (tests first)
   - Type safety (no implicit any)
   - Anti-duplication (reuse existing)
   - Spec compliance (requirements met)
4. Consolidate results after each layer
5. Auto-audit workflow effectiveness

**Progress monitoring:**

```
Layer 1/3: S01 (auth-backend) ✓ Complete
Layer 2/3: S02 (auth-frontend) → In progress (65%)
Layer 3/3: S03 (auth-integration) → Pending
```

**After implementation complete, auto-run workflow audit:**

```bash
/audit-workflow
```

**Outputs:**

- Implementation across `epics/NNN-slug/sprints/S01/`, `S02/`, `S03/`
- Consolidated test results
- audit-report.xml with effectiveness metrics

### Step 6: Optimization & Quality Gates

**Invoke /optimize:**

```bash
/optimize
```

**The /optimize phase will:**

1. Run quality checks across all sprints:
   - Performance benchmarking
   - Accessibility audit (WCAG 2.1 AA)
   - Security scan (dependencies, secrets)
   - Code quality review (KISS, DRY)
   - Integration testing (cross-sprint validation)
2. Run workflow audit (effectiveness metrics)
3. Generate optimization-report.xml

**Quality gates (blocking):**

- All tests passing
- No critical security issues
- Performance benchmarks met
- Accessibility standards met
- No breaking API changes

**If gates fail, workflow pauses. User must fix and run `/epic continue`.**

**Commit optimization results (atomic commit #5):**

```bash
# Extract metadata for commit message
PERF_SCORE=$(yq -r '.performance.score // "N/A"' epics/${EPIC_SLUG}/optimization-report.md)
SEC_SCORE=$(yq -r '.security.score // "N/A"' epics/${EPIC_SLUG}/optimization-report.md)
A11Y_SCORE=$(yq -r '.accessibility.score // "N/A"' epics/${EPIC_SLUG}/optimization-report.md)
QUALITY_SCORE=$(yq -r '.code_quality.score // "N/A"' epics/${EPIC_SLUG}/optimization-report.md)

# Commit optimization results
git add epics/${EPIC_SLUG}/optimization-report.md
git commit -m "docs(epic-optimize): complete optimization for ${EPIC_SLUG}

Performance: ${PERF_SCORE}/100
Security: ${SEC_SCORE}/100
Accessibility: ${A11Y_SCORE}/100
Code quality: ${QUALITY_SCORE}/100

All quality gates passed

Next: /ship

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Alternative (recommended): Use git-workflow-enforcer skill:**

```bash
/meta:enforce-git-commits --phase "epic-optimize"
```

### Step 7: Unified Deployment

**Invoke /ship:**

```bash
/ship
```

**The /ship command will:**

1. Auto-detect deployment model from repo:
   - staging-prod: Has staging branch + .github/workflows/deploy-staging.yml
   - direct-prod: Has git remote, no staging
   - local-only: No git remote
2. Execute appropriate deployment workflow
3. Track deployment metadata
4. Create GitHub release (if staging-prod or direct-prod)

**No changes to /ship logic - it already handles all models.**

### Step 8: Walkthrough Generation & Self-Improvement

**Purpose**: Generate comprehensive walkthrough documentation and trigger workflow self-improvement.

**Skill reference**: See `.claude/skills/epic-walkthrough/SKILL.md` for detailed implementation.

**Invoke**: `/finalize`

**Process**:

1. Generate `walkthrough.md` with phases, quality gates, key files, lessons learned
2. Run `/audit-workflow` for post-mortem analysis
3. Pattern detection (after 2-3 epics) for code generation opportunities
4. Run `/heal-workflow` to apply approved improvements
5. Update documentation (CHANGELOG, README, CLAUDE.md)
6. Archive artifacts to `completed/`

**Outputs**:

- `walkthrough.md` - Comprehensive epic summary with velocity metrics
- `workflow-improvements.xml` - Self-improvement suggestions
- Updated project documentation

## Handle Continue Mode

**When resuming with `/epic continue`:**

1. **Detect epic workspace and branch:**

   ```bash
   # Run detection utility to find epic workspace
   WORKFLOW_INFO=$(bash .spec-flow/scripts/utils/detect-workflow-paths.sh 2>/dev/null || pwsh -File .spec-flow/scripts/utils/detect-workflow-paths.ps1 2>/dev/null)

   if [ $? -eq 0 ]; then
       WORKFLOW_TYPE=$(echo "$WORKFLOW_INFO" | jq -r '.type')
       BASE_DIR=$(echo "$WORKFLOW_INFO" | jq -r '.base_dir')
       SLUG=$(echo "$WORKFLOW_INFO" | jq -r '.slug')
       CURRENT_BRANCH=$(echo "$WORKFLOW_INFO" | jq -r '.branch')

       # Verify this is an epic workflow
       if [ "$WORKFLOW_TYPE" != "epic" ]; then
           echo "❌ Error: This is a $WORKFLOW_TYPE workflow, not an epic"
           echo "   Use /feature continue for feature workflows"
           exit 1
       fi

       # Check if on correct epic branch
       if [[ "$CURRENT_BRANCH" =~ ^epic/ ]]; then
           echo "✓ Detected epic branch: $CURRENT_BRANCH"
       else
           echo "⚠️  Warning: Not on an epic branch (current: $CURRENT_BRANCH)"
           echo "   Epic workspace detected at: epics/$SLUG"

           # Ask if user wants to switch branches
           AskUserQuestion({
             questions: [{
               question: "Switch to epic branch?",
               header: "Branch Switch",
               multiSelect: false,
               options: [
                 {label: "Yes", description: "Switch to epic/$SLUG branch"},
                 {label: "No", description: "Continue on current branch (not recommended)"}
               ]
             }]
           });

           if (userChoice === "Yes") {
               git checkout -b epic/$SLUG 2>/dev/null || git checkout epic/$SLUG
               echo "✓ Switched to epic/$SLUG"
           }
       fi
   else
       echo "❌ Error: Could not detect epic workspace"
       echo "   Run from project root with an active epic in epics/"
       exit 1
   fi
   ```

2. **Read workflow state:**

   - Read `epics/$SLUG/state.yaml` to find current phase
   - Find first phase with status `in_progress` or `failed`
   - Resume from that phase
   - If manual gate was pending, proceed past it

3. **Check for iteration mode** (v3.0 - Feedback Loop Support):

   ```bash
   # Read iteration state
   CURRENT_ITERATION=$(yq eval '.iteration.current' "epics/$SLUG/state.yaml" 2>/dev/null || echo "1")

   if [ "$CURRENT_ITERATION" -gt 1 ]; then
       echo "🔄 Resuming Iteration $CURRENT_ITERATION"
       echo "   Gaps discovered during validation"
       echo "   Executing supplemental tasks only"
       echo ""

       # Show gap summary
       if [ -f "epics/$SLUG/gaps.md" ]; then
           IN_SCOPE_COUNT=$(yq eval '.gaps.in_scope_count' "epics/$SLUG/state.yaml" 2>/dev/null || echo "0")
           echo "   In-scope gaps: $IN_SCOPE_COUNT"
           echo "   Tasks generated: Check tasks.md (Iteration $CURRENT_ITERATION section)"
           echo ""
       fi

       # Resume from current phase in iteration workflow
       # Typically this will be "implement" phase after gap capture
       CURRENT_PHASE=$(yq eval '.phase' "epics/$SLUG/state.yaml" 2>/dev/null || echo "unknown")
       echo "   Resuming from: /$CURRENT_PHASE phase"
   fi
   ```

   **Iteration workflow resume logic:**

   - If iteration > 1 and phase = "implement": Execute supplemental tasks only
   - If iteration > 1 and phase = "optimize": Run iteration-specific quality gates
   - If iteration > 1 and phase = "ship-staging": Deploy iteration N to staging
   - After successful deployment: Loop back to validate-staging for convergence check

## Error Handling

**If any phase fails:**

- Read error details from state.yaml
- Check relevant log files in epics/NNN-slug/
- Present clear error message with file paths
- Suggest fixes based on error type
- Tell user to fix and run `/epic continue`

**Common failure modes:**

- Epic ambiguity → auto-runs `/clarify`
- Planning failures → check plan.md for missing context
- Sprint dependency violations → check sprint-plan.md
- Implementation errors → check per-sprint error logs
- Quality gate failures → check optimization-report.xml
- Deployment failures → check deployment logs

</process>

<success_criteria>
**Epic successfully completed when:**

1. **All artifacts generated**:

   - epic-spec.md (fully populated, zero placeholders)
   - research.md (findings with confidence levels)
   - plan.md (architecture decisions and phases)
   - sprint-plan.md (dependency graph and execution layers)
   - walkthrough.md (comprehensive post-mortem)

2. **Quality gates passed**:

   - All tests passing (>95% coverage)
   - No critical security issues
   - Performance benchmarks met
   - Accessibility WCAG 2.1 AA compliant
   - No breaking API changes

3. **Deployment successful**:

   - Code deployed to target environment (staging/prod/local)
   - Deployment metadata recorded in state.yaml
   - GitHub release created (if applicable)

4. **Self-improvement completed**:

   - Workflow audit executed (/audit-workflow)
   - Patterns analyzed and documented
   - Workflow improvements identified
   - Project documentation updated

5. **State correctly recorded**:
   - state.yaml marks epic as completed
   - All phase statuses accurately reflect reality
   - Manual gates properly recorded (approved/skipped)
     </success_criteria>

<verification>
**Before marking epic complete, verify:**

1. **Read state.yaml**: Confirm all phases show `status: completed`
2. **Check artifact existence**:
   ```powershell
   Test-Path epics/NNN-slug/epic-spec.md
   Test-Path epics/NNN-slug/research.md
   Test-Path epics/NNN-slug/plan.md
   Test-Path epics/NNN-slug/sprint-plan.md
   Test-Path epics/NNN-slug/walkthrough.md
   ```
3. **Validate quality gates**: Read optimization-report.xml, confirm no blocking issues
4. **Confirm deployment**: Check deployment-metadata.json for successful deployment timestamp
5. **Verify git state**: Run `git log -1` to confirm final commit exists
6. **Check audit completion**: Verify audit-report.xml exists with effectiveness metrics

**Never claim completion without quoting these verification results.**
</verification>

<output>
**Files created/modified by this command:**

**Epic workspace** (epics/NNN-slug/):

- epic-spec.md — Epic requirements and scoping
- research.md — Technical research findings
- plan.md — Architecture decisions and implementation plan
- sprint-plan.md — Dependency graph and execution layers
- tasks.md — All tasks across sprints with acceptance criteria
- walkthrough.md — Comprehensive post-mortem and lessons learned
- state.yaml — Current phase, gates, deployment metadata
- optimization-report.xml — Quality gate results
- audit-report.xml — Workflow effectiveness metrics
- deployment-metadata.json — Deployment URLs, IDs, timestamps

**Sprint directories** (epics/NNN-slug/sprints/S01/, S02/, ...):

- Implementation code for each sprint
- Sprint-specific test results
- Sprint error logs (if failures occurred)

**Prompts** (.prompts/NNN-epic-slug-research/, NNN-epic-slug-plan/):

- Prompt files for meta-prompting system
- research.md and plan.md outputs

**API contracts** (contracts/api/):

- OpenAPI schemas for locked contracts (if applicable)

**Project documentation** (updated):

- CHANGELOG.md — Epic summary added
- README.md — Updated with new features
- CLAUDE.md (project) — Active epic status updated

**GitHub** (if git remote configured):

- New branch: epic/NNN-slug
- Pull request or direct commits
- GitHub release (if staging-prod or direct-prod)
  </output>

---

## Workflow Tracking

All steps read/write `epics/<NNN-slug>/state.yaml`.

**Todo list example:**

```javascript
TodoWrite({
  todos: [
    {
      content: "Parse args, initialize epic state",
      status: "completed",
      activeForm: "Initialized",
    },
    {
      content: "Auto-check: /init-project (if needed)",
      status: "completed",
      activeForm: "Project initialized",
    },
    {
      content: "Phase 0: Epic specification",
      status: "completed",
      activeForm: "Created epic-spec.md",
    },
    {
      content: "Phase 0.5: Clarification (auto-invoked)",
      status: "completed",
      activeForm: "Resolved ambiguities",
    },
    {
      content: "Manual gate: Epic spec review",
      status: "completed",
      activeForm: "Spec approved",
    },
    {
      content: "Phase 1: Meta-prompting research",
      status: "completed",
      activeForm: "Research complete",
    },
    {
      content: "Phase 1: Meta-prompting planning",
      status: "completed",
      activeForm: "Plan complete",
    },
    {
      content: "Manual gate: Plan review",
      status: "completed",
      activeForm: "Plan approved",
    },
    {
      content: "Phase 2: Sprint breakdown (auto)",
      status: "completed",
      activeForm: "Sprint plan generated",
    },
    {
      content: "Phase 3: Parallel implementation Layer 1",
      status: "completed",
      activeForm: "S01 complete",
    },
    {
      content: "Phase 3: Parallel implementation Layer 2",
      status: "in_progress",
      activeForm: "S02 implementing",
    },
    {
      content: "Phase 3: Parallel implementation Layer 3",
      status: "pending",
      activeForm: "S03 pending",
    },
    {
      content: "Phase 3: Workflow audit (auto)",
      status: "pending",
      activeForm: "Auditing workflow",
    },
    {
      content: "Phase 4: Optimization (auto)",
      status: "pending",
      activeForm: "Running quality gates",
    },
    {
      content: "Phase 5: Unified deployment",
      status: "pending",
      activeForm: "Deploying",
    },
    {
      content: "Phase 6: Walkthrough + self-improvement",
      status: "pending",
      activeForm: "Finalizing epic",
    },
  ],
});
```

**Rules**:

- Exactly one phase is `in_progress`
- **Manual gates**: Epic spec review (gate #1), Plan review (gate #2), Staging validation (gate #3, from /ship)
- **Auto-progression**: After plan approval, automatically execute through deployment
- Deployment phases adapt to model: `staging-prod`, `direct-prod`, or `local-only`

---

## Anti-Hallucination Rules

1. **Never claim phase completion without quoting `state.yaml`**
   Always `Read` the file and print the actual recorded status.

2. **Cite agent outputs**
   When a phase finishes, paste the returned `{status, summary, stats}` keys.

3. **Do not skip phases unless state marks them disabled**
   Follow the recorded sequence; if required, run it.

4. **Detect the deployment model from the repo**
   Show evidence: `git branch -a`, presence of staging workflow files.

5. **No fabricated summaries**
   If an agent errors, show the error; don't invent success.

6. **Always use AskUserQuestion for clarification**
   Never assume answers - ask user explicitly with options.

---

## Usage Examples

**Start new epic:**

```bash
/epic "User authentication with OAuth 2.1"
```

**Resume interrupted epic:**

```bash
/epic continue
```

**Start next priority epic from backlog:**

```bash
/epic next
```

---

## Philosophy

**Epics orchestrate multiple sprints**
Unlike `/feature` (single sprint), `/epic` coordinates 2+ sprints with dependencies.

**State truth lives in `state.yaml`**
Never guess; always read, quote, and update atomically.

**Meta-prompting for research & planning**
Isolated sub-agents with XML outputs prevent context pollution.

**Parallel sprint execution**
Dependency graph enables 3-5x velocity improvement.

**Self-improving workflow**
Audits after each epic, generates project-specific tooling.

**Comprehensive walkthrough**
walkthrough.md captures what worked, what struggled, lessons learned.

---

## References

- [Tâches Meta-Prompting System](https://github.com/taches-ai/claude-workflows)
- [OpenTelemetry Signals](https://opentelemetry.io/docs/concepts/signals)
- [DORA Metrics](https://dora.dev)
- [Trunk-Based Development](https://trunkbaseddevelopment.com)
