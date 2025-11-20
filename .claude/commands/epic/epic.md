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

**Workflow State**: @epics/*/workflow-state.yaml
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
   const hasAutoFlag = args.includes('--auto');
   const hasInteractiveFlag = args.includes('--interactive');
   const hasNoInput = args.includes('--no-input');
   const epicDescription = args.replace(/--auto|--interactive|--no-input/g, '').trim();

   let selectedMode;

   if (hasNoInput || hasAutoFlag) {
       selectedMode = 'auto';  // CI/automation override
   } else if (hasInteractiveFlag) {
       selectedMode = 'interactive';  // Explicit interactive override
   } else {
       selectedMode = $preferredMode;  // Use config/history preference
   }
   ```

4. **If no explicit override, ask user with smart suggestions:**
   ```javascript
   // Only prompt if no flag provided and not in CI mode
   if (!hasAutoFlag && !hasInteractiveFlag && !hasNoInput) {
       // Use AskUserQuestion with learned preferences
       const options = [
           {
               label: history.last_used_mode === 'auto'
                   ? `Auto (last used, ${history.usage_count.auto}/${history.total_uses} times) ⭐`
                   : 'Auto',
               description: 'Skip all prompts, run until blocker'
           },
           {
               label: history.last_used_mode === 'interactive'
                   ? `Interactive (last used, ${history.usage_count.interactive}/${history.total_uses} times) ⭐`
                   : 'Interactive',
               description: 'Pause at spec review and plan review'
           }
       ];

       // Show prompt with smart suggestions
       // Mark last-used with ⭐ if preferences.ui.recommend_last_used === true
       // Show usage stats if preferences.ui.show_usage_stats === true
   }
   ```

5. **Create/update workflow-state.yaml and track usage:**
   ```yaml
   # epics/{EPIC_SLUG}/workflow-state.yaml
   epic:
     number: {EPIC_NUMBER}
     slug: {EPIC_SLUG}
     title: {EPIC_TITLE}
     auto_mode: {true|false}  # Based on selectedMode
     started_at: {ISO_TIMESTAMP}
     current_phase: specification

   phases:
     specification:
       status: in_progress
       started_at: {ISO_TIMESTAMP}
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
       status: {auto_skipped|pending}  # auto_skipped if auto_mode: true
       blocking: {false|true}  # false if auto_mode: true
       skipped_at: {ISO_TIMESTAMP}  # if auto_skipped
     plan_review:
       status: {auto_skipped|pending}  # auto_skipped if auto_mode: true
       blocking: {false|true}  # false if auto_mode: true
       skipped_at: {ISO_TIMESTAMP}  # if auto_skipped

   sprints:
     total: 0  # Updated after planning
     completed: 0
     failed: 0

   layers:
     total: 0  # Updated after planning
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
        {label: "New feature", description: "Brand new functionality"},
        {label: "Enhancement", description: "Improve existing features"},
        {label: "Refactoring", description: "Improve code without changing behavior"},
        {label: "Infrastructure", description: "Dev tools, CI/CD, monitoring"}
      ]
    },
    {
      question: "What subsystems are involved?",
      header: "Subsystems",
      multiSelect: true,
      options: [
        {label: "Backend API", description: "Server-side logic and endpoints"},
        {label: "Frontend UI", description: "User interface components"},
        {label: "Database", description: "Schema changes or data migrations"},
        {label: "Infrastructure", description: "Deployment, monitoring, CI/CD"}
      ]
    },
    {
      question: "What's the complexity level?",
      header: "Complexity",
      multiSelect: false,
      options: [
        {label: "Small (2-3 sprints)", description: "~1 week, clear requirements"},
        {label: "Medium (4-6 sprints)", description: "2-3 weeks, some unknowns"},
        {label: "Large (7+ sprints)", description: "1+ month, significant research needed"}
      ]
    }
  ]
})
```

**Generate epic specification (Markdown format):**
```bash
# Create epic workspace
mkdir -p epics/NNN-slug

# Generate epic-spec.md using template
# Template location: .spec-flow/templates/epic-spec.md
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

**PAUSE (Interactive Mode Only)**: Review epic-spec.md. User can run `/clarify` if ambiguous, or continue to planning.

**When paused (interactive mode):**
- Display: "📋 Spec review complete. Continue to planning? (y/n)"
- If approved, update workflow-state.yaml:
  ```yaml
  manual_gates:
    spec_review:
      status: approved
      approved_at: {ISO_TIMESTAMP}
      approved_by: user
  ```

**If auto-mode enabled**:
- Skip this PAUSE - proceed directly to Step 1.5
- Manual gate already set to "auto_skipped" in workflow-state.yaml (from Step 0.1)

### Step 1.5: Interactive Epic Scoping (Question Bank-Driven) **NEW in v5.0**

**Purpose**: Use centralized question bank to systematically scope the epic with structured AskUserQuestion calls, eliminating ambiguity before planning.

**When to invoke**: Always run for new epics. Skip if resuming with `/epic continue`.

#### Load Question Bank

```bash
# Read epic question bank
cat .claude/skills/epic/references/question-bank.md
```

**Question bank contains**:
- Initial scoping (business goal, subsystem selection) - 2 questions
- Scope refinement (backend, frontend, database, integrations) - 0-4 questions (conditional)
- Success metrics (measurement, targets) - 2 questions
- Dependencies & constraints - 2 questions
- Complexity assessment - 2 questions

**Total**: 8-9 questions across 5 rounds

#### Execute 5-Round Interactive Scoping

**Round 1: Initial Scoping (2 questions)**

Use question bank templates:
- `initial_scoping.business_goal`
- `initial_scoping.subsystem_selection`

```javascript
AskUserQuestion({
  questions: [
    questionBank.initial_scoping.business_goal,
    questionBank.initial_scoping.subsystem_selection
  ]
});
```

**Apply answers to epic-spec.md atomically**:
- business_goal → `## Objective` > `### Business Value`
- subsystem_selection → `## Subsystems` (update **Involved** field for each selected)

**Round 2: Scope Refinement (0-4 questions, conditional)**

**Based on subsystem_selection answers**, ask relevant follow-ups:

```javascript
const refinementQuestions = [];

if (selectedSubsystems.includes("Backend API")) {
  refinementQuestions.push(questionBank.scope_refinement.backend_scope);
}
if (selectedSubsystems.includes("Frontend UI")) {
  refinementQuestions.push(questionBank.scope_refinement.frontend_scope);
}
if (selectedSubsystems.includes("Database")) {
  refinementQuestions.push(questionBank.scope_refinement.database_scope);
}
if (selectedSubsystems.includes("External integrations")) {
  refinementQuestions.push(questionBank.scope_refinement.integration_scope);
}

if (refinementQuestions.length > 0) {
  AskUserQuestion({ questions: refinementQuestions });
}
```

**Apply answers to epic-spec.md**:
- backend_scope → Add details to `### Backend` section
- frontend_scope → Add details to `### Frontend` section
- database_scope → Add details to `### Database` section
- integration_scope → Add details to `### Infrastructure` section

**Round 3: Success Metrics (2 questions)**

```javascript
AskUserQuestion({
  questions: [
    questionBank.success_metrics.measurement_approach,
    questionBank.success_metrics.target_values
  ]
});

// If "Specific targets" selected, follow-up:
if (answers["Targets"] === "Specific targets") {
  const customTargets = answers["Targets_custom"];
  // Parse and apply to epic-spec.md
}
```

**Apply answers to epic-spec.md**:
- measurement_approach → `### Success Metrics` section
- target_values → `### Success Metrics` section (actual target values)

**Round 4: Dependencies & Constraints (2 questions)**

```javascript
AskUserQuestion({
  questions: [
    questionBank.dependencies_and_constraints.external_dependencies,
    questionBank.dependencies_and_constraints.constraints
  ]
});
```

**Apply answers to epic-spec.md**:
- external_dependencies → `## Dependencies` section
- constraints → `### Constraints` section (time, budget, tech, etc.)

**Round 5: Complexity Assessment (2 questions)**

```javascript
AskUserQuestion({
  questions: [
    questionBank.complexity_assessment.technical_complexity,
    questionBank.complexity_assessment.sprint_estimate
  ]
});

// Warn if 7+ sprints selected
if (answers["Sprint Estimate"] === "7+ sprints") {
  console.log("⚠️  WARNING: Consider breaking this into multiple smaller epics for better parallelization and faster feedback.");
}
```

**Apply answers to epic-spec.md**:
- technical_complexity → YAML frontmatter `complexity` field
- sprint_estimate → Document in `## Overview` section

#### Progress Indicators

**Show progress after each round**:
- `🔍 Epic Scoping: Round 1/5 (Initial scoping)`
- `📝 Applied: Business Goal → New capability`
- `📝 Applied: Subsystems → Backend API, Frontend UI, Database`
- `🔍 Epic Scoping: Round 2/5 (Scope refinement)`
- ... and so on

#### Final Output

**After 5 rounds complete**:
1. All epic-spec.md placeholders filled
2. Zero ambiguities remaining
3. Ready for /plan without needing /clarify

**Display completion summary**:
```
✅ Epic Scoping Complete (9 questions answered)

📊 Epic Summary:
  Business Goal: New capability
  Subsystems: Backend API, Frontend UI, Database (3)
  Success Metrics: User adoption (target: 80% within 30 days)
  Dependencies: Third-party APIs (Stripe payment integration)
  Constraints: Time constraint (2-week deadline)
  Complexity: Medium
  Estimated Sprints: 3-4 sprints

📋 Next Steps:
  1. Review epic-spec.md for accuracy
  2. Run /plan to generate research → plan → sprint breakdown
  3. Run /epic continue to execute automated workflow
```

**Velocity benefit**: 5-10 minute interactive scoping vs 30+ minute unstructured discussion (3-6x faster)

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
- Mark clarification phase complete in workflow-state.yaml

**Expected outcome**: With 5-round interactive scoping (Step 1.5), most epics have ambiguity score < 30 and skip /clarify entirely.

**If clear** (score ≤ 30), skip /clarify and proceed to planning.

### Step 3: Meta-Prompting for Research & Planning

**Use meta-prompting system to generate research → plan pipeline:**

```bash
/create-prompt "Research technical approach for: [epic objective]"
```

**The create-prompt skill will:**
1. Detect purpose: Research
2. Ask contextual questions (depth, sources, output format)
3. Generate research prompt in `.prompts/001-[epic-slug]-research/`
4. Reference relevant project docs (@docs/project/tech-stack.md)
5. Specify XML output format with metadata

**Auto-execute research prompt:**
```bash
/run-prompt 001-[epic-slug]-research
```

**Research outputs:**
- `.prompts/001-[epic-slug]-research/research.xml`
- Contains: findings, confidence levels, dependencies, open questions, assumptions

**Generate planning prompt:**
```bash
/create-prompt "Create implementation plan based on research"
```

**The create-prompt skill will:**
1. Detect purpose: Plan
2. Reference research.xml from step above
3. Generate plan prompt in `.prompts/002-[epic-slug]-plan/`
4. Specify plan.xml output with phases, tasks, constraints

**Auto-execute plan prompt:**
```bash
/run-prompt 002-[epic-slug]-plan
```

**Plan outputs:**
- `.prompts/002-[epic-slug]-plan/plan.xml`
- Contains: architecture decisions, implementation phases, dependencies, risks

**PAUSE (Interactive Mode Only)**: Review research.md and plan.md. If approved, continue to sprint breakdown.

**When paused (interactive mode):**
- Display: "📋 Plan review complete. Continue to sprint breakdown? (y/n)"
- If approved, update workflow-state.yaml:
  ```yaml
  manual_gates:
    plan_review:
      status: approved
      approved_at: {ISO_TIMESTAMP}
      approved_by: user

  phases:
    research:
      status: completed
      completed_at: {ISO_TIMESTAMP}
    planning:
      status: completed
      completed_at: {ISO_TIMESTAMP}
  ```

**If auto-mode enabled**:
- Skip this PAUSE - proceed directly to Step 4
- Manual gate already set to "auto_skipped" in workflow-state.yaml (from Step 0.1)
- Update phases status automatically:
  ```yaml
  phases:
    research:
      status: completed
      completed_at: {ISO_TIMESTAMP}
    planning:
      status: completed
      completed_at: {ISO_TIMESTAMP}
  ```

### Step 4: Sprint Breakdown with Dependency Graph

**Invoke /tasks with epic context:**
```bash
/tasks
```

**The /tasks phase will:**
1. Read plan.xml to understand phases
2. Analyze complexity and identify sprint boundaries
3. Build dependency graph between sprints
4. Lock API contracts (OpenAPI schemas) for parallel work
5. Generate sprint-plan.xml with execution layers

**Sprint plan structure:**
```xml
<sprint_plan>
  <sprints>
    <sprint id="S01" name="auth-backend">
      <dependencies></dependencies>
      <estimated_hours>16</estimated_hours>
      <subsystems>backend, database</subsystems>
      <contracts_locked>
        <api_contract>contracts/api/auth-v1.yaml</api_contract>
      </contracts_locked>
    </sprint>

    <sprint id="S02" name="auth-frontend">
      <dependencies>S01</dependencies>
      <estimated_hours>20</estimated_hours>
      <subsystems>frontend</subsystems>
    </sprint>

    <sprint id="S03" name="auth-integration">
      <dependencies>S01, S02</dependencies>
      <estimated_hours>12</estimated_hours>
      <subsystems>backend, frontend</subsystems>
    </sprint>
  </sprints>

  <execution_layers>
    <layer num="1">
      <sprint_ids>S01</sprint_ids>
      <parallelizable>true</parallelizable>
    </layer>
    <layer num="2">
      <sprint_ids>S02</sprint_ids>
      <parallelizable>false</parallelizable>
      <depends_on_layer>1</depends_on_layer>
    </layer>
    <layer num="3">
      <sprint_ids>S03</sprint_ids>
      <parallelizable>false</parallelizable>
      <depends_on_layer>2</depends_on_layer>
    </layer>
  </execution_layers>
</sprint_plan>
```

**Also generates tasks.xml:**
- All tasks across all sprints
- Task-level dependencies
- Sprint assignments
- Acceptance criteria per task

### Step 5: Parallel Sprint Implementation

**Invoke /implement-epic for parallel sprint execution:**
```bash
/implement-epic
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

### Step 7: Preview (Adaptive Manual Gate)

**Analyze epic complexity to determine if preview needed:**
- Small epic (≤2 sprints, no UI changes) → Auto-skip preview
- Major epic (>2 sprints OR UI changes) → Require manual preview

**If preview required:**
```bash
/preview
```

**The /preview phase will:**
1. Run AI pre-flight checks:
   - Accessibility scan (automated)
   - Visual regression (screenshot comparison)
   - Integration smoke tests
2. Generate preview-report.xml with auto-checks
3. If manual review needed:
   - Start local dev server
   - Present preview checklist
   - Wait for user sign-off
4. Update workflow-state.yaml with approval

**If preview auto-skipped:**
- Record in workflow-state.yaml: `preview.status: skipped, reason: "Small epic, no UI changes"`

### Step 8: Unified Deployment

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

### Step 9: Walkthrough Generation & Self-Improvement

**Invoke /finalize:**
```bash
/finalize
```

**The /finalize phase will:**
1. Generate walkthrough.md in epic workspace:
   ```xml
   <walkthrough>
     <overview>
       <epic_goal>...</epic_goal>
       <business_value>...</business_value>
       <duration>Start: 2025-11-19, End: 2025-11-25 (6 days)</duration>
       <velocity>Expected: 3x, Actual: 4.2x</velocity>
     </overview>

     <phases_completed>
       <phase name="research">
         <duration>2 hours</duration>
         <key_findings>OAuth 2.1 recommended, JWT tokens for sessions</key_findings>
         <artifacts>research.xml, API contracts locked</artifacts>
       </phase>
       <phase name="planning">
         <duration>1.5 hours</duration>
         <key_decisions>PostgreSQL for sessions, httpOnly cookies for tokens</key_decisions>
         <artifacts>plan.xml, sprint-plan.xml</artifacts>
       </phase>
       <phase name="implementation">
         <duration>16 hours</duration>
         <sprints_completed>S01 (8h), S02 (12h), S03 (6h) - S02 ran parallel with S03</sprints_completed>
         <artifacts>Implementation in sprints/S01, S02, S03</artifacts>
       </phase>
       <phase name="optimization">
         <duration>2 hours</duration>
         <quality_gates>All passed (tests: ✓, security: ✓, performance: ✓, accessibility: ✓)</quality_gates>
         <artifacts>optimization-report.xml</artifacts>
       </phase>
     </phases_completed>

     <validation>
       <quality_gates>
         <gate name="tests" status="passed">98% coverage, 142/142 passing</gate>
         <gate name="security" status="passed">0 critical, 2 medium (triaged as acceptable)</gate>
         <gate name="performance" status="passed">API p95: 87ms (target: <200ms)</gate>
         <gate name="accessibility" status="passed">WCAG 2.1 AA compliant, 0 violations</gate>
       </quality_gates>
       <deployment>
         <staging>Deployed v1.5.0-rc.1, validated 2025-11-24</staging>
         <production>Promoted to v1.5.0, deployed 2025-11-25</production>
       </deployment>
     </validation>

     <key_files_modified>
       <category name="backend">
         <file path="src/auth/middleware.ts">JWT validation middleware added</file>
         <file path="src/auth/service.ts">OAuth 2.1 integration</file>
         <file path="src/models/Session.ts">Session model with PostgreSQL storage</file>
       </category>
       <category name="frontend">
         <file path="components/LoginForm.tsx">OAuth login flow</file>
         <file path="hooks/useAuth.ts">Authentication state management</file>
       </category>
       <category name="infrastructure">
         <file path="migrations/20251119_sessions_table.sql">Session table migration</file>
         <file path="contracts/api/auth-v1.yaml">Authentication API contract</file>
       </category>
     </key_files_modified>

     <next_steps>
       <future_enhancement priority="high">Add MFA support (2FA via SMS/authenticator app)</future_enhancement>
       <future_enhancement priority="medium">Social login (Google, GitHub)</future_enhancement>
       <technical_debt>Token refresh logic uses polling (should use refresh tokens)</technical_debt>
       <monitoring>Watch auth_failures_total metric, alert if >5% error rate</monitoring>
     </next_steps>

     <summary>
       <what_worked>
         - Parallel sprint execution saved 8 hours (S02 and S03 overlap)
         - API contract locking prevented integration bugs
         - Meta-prompting research phase identified OAuth 2.1 early
       </what_worked>
       <what_struggled>
         - Sprint S02 took 12h vs 8h estimated (token storage complexity)
         - Bottleneck: Cookie SameSite policy required research
       </what_struggled>
       <lessons_learned>
         - Lock contracts before any parallel work (saved rework)
         - Research phase crucial for architectural decisions
         - Parallel execution 4.2x faster than sequential (exceeded 3x target)
       </lessons_learned>
       <velocity_impact>
         Expected: 3x faster
         Actual: 4.2x faster
         Reason: S02/S03 had less dependencies than estimated, ran 60% parallel
       </velocity_impact>
     </summary>
   </walkthrough>
   ```

2. Run post-mortem audit:
   ```bash
   /audit-workflow
   ```

3. Pattern detection (after 2-3 epics):
   - Analyze completed epics for recurring patterns
   - Detect code generation opportunities
   - Suggest custom skills for detected patterns
   - Generate project-specific commands/hooks

4. Self-healing:
   ```bash
   /heal-workflow
   ```
   - Apply approved workflow improvements
   - Update skills based on learnings

5. Update documentation:
   - CHANGELOG.md
   - README.md
   - Project CLAUDE.md (add epic summary)

6. Archive epic artifacts:
   - Move prompts to completed/
   - Mark epic complete in workflow-state.yaml

**Outputs:**
- walkthrough.md (comprehensive epic summary)
- workflow-improvements.xml (self-improvement suggestions)
- Updated project documentation

## Handle Continue Mode

**When resuming with `/epic continue`:**
- Read `epics/NNN-slug/workflow-state.yaml` to find current phase
- Find first phase with status `in_progress` or `failed`
- Resume from that phase
- If manual gate was pending, proceed past it

## Error Handling

**If any phase fails:**
- Read error details from workflow-state.yaml
- Check relevant log files in epics/NNN-slug/
- Present clear error message with file paths
- Suggest fixes based on error type
- Tell user to fix and run `/epic continue`

**Common failure modes:**
- Epic ambiguity → auto-runs `/clarify`
- Planning failures → check plan.xml for missing context
- Sprint dependency violations → check sprint-plan.xml
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
   - Deployment metadata recorded in workflow-state.yaml
   - GitHub release created (if applicable)

4. **Self-improvement completed**:
   - Workflow audit executed (/audit-workflow)
   - Patterns analyzed and documented
   - Workflow improvements identified
   - Project documentation updated

5. **State correctly recorded**:
   - workflow-state.yaml marks epic as completed
   - All phase statuses accurately reflect reality
   - Manual gates properly recorded (approved/skipped)
</success_criteria>

<verification>
**Before marking epic complete, verify:**

1. **Read workflow-state.yaml**: Confirm all phases show `status: completed`
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
- workflow-state.yaml — Current phase, gates, deployment metadata
- optimization-report.xml — Quality gate results
- audit-report.xml — Workflow effectiveness metrics
- deployment-metadata.json — Deployment URLs, IDs, timestamps

**Sprint directories** (epics/NNN-slug/sprints/S01/, S02/, ...):
- Implementation code for each sprint
- Sprint-specific test results
- Sprint error logs (if failures occurred)

**Prompts** (.prompts/NNN-epic-slug-research/, NNN-epic-slug-plan/):
- Prompt files for meta-prompting system
- research.xml and plan.xml outputs

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

All steps read/write `epics/<NNN-slug>/workflow-state.yaml`.

**Todo list example:**

```javascript
TodoWrite({
  todos: [
    {content:"Parse args, initialize epic state",status:"completed",activeForm:"Initialized"},
    {content:"Auto-check: /init-project (if needed)",status:"completed",activeForm:"Project initialized"},
    {content:"Phase 0: Epic specification",status:"completed",activeForm:"Created epic-spec.md"},
    {content:"Phase 0.5: Clarification (auto-invoked)",status:"completed",activeForm:"Resolved ambiguities"},
    {content:"Manual gate: Epic spec review",status:"completed",activeForm:"Spec approved"},
    {content:"Phase 1: Meta-prompting research",status:"completed",activeForm:"Research complete"},
    {content:"Phase 1: Meta-prompting planning",status:"completed",activeForm:"Plan complete"},
    {content:"Manual gate: Plan review",status:"completed",activeForm:"Plan approved"},
    {content:"Phase 2: Sprint breakdown (auto)",status:"completed",activeForm:"Sprint plan generated"},
    {content:"Phase 3: Parallel implementation Layer 1",status:"completed",activeForm:"S01 complete"},
    {content:"Phase 3: Parallel implementation Layer 2",status:"in_progress",activeForm:"S02 implementing"},
    {content:"Phase 3: Parallel implementation Layer 3",status:"pending",activeForm:"S03 pending"},
    {content:"Phase 3: Workflow audit (auto)",status:"pending",activeForm:"Auditing workflow"},
    {content:"Phase 4: Optimization (auto)",status:"pending",activeForm:"Running quality gates"},
    {content:"Phase 5: Preview (adaptive)",status:"pending",activeForm:"Preview validation"},
    {content:"Phase 6: Unified deployment",status:"pending",activeForm:"Deploying"},
    {content:"Phase 7: Walkthrough + self-improvement",status:"pending",activeForm:"Finalizing epic"}
  ]
})
```

**Rules**:
- Exactly one phase is `in_progress`
- **Manual gates**: Epic spec review (gate #1), Plan review (gate #2), Staging validation (gate #3, from /ship)
- **Auto-progression**: After plan approval, automatically execute through deployment
- **Adaptive preview**: Small epics skip, major epics require manual
- Deployment phases adapt to model: `staging-prod`, `direct-prod`, or `local-only`

---

## Anti-Hallucination Rules

1. **Never claim phase completion without quoting `workflow-state.yaml`**
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

**State truth lives in `workflow-state.yaml`**
Never guess; always read, quote, and update atomically.

**Meta-prompting for research & planning**
Isolated sub-agents with XML outputs prevent context pollution.

**Parallel sprint execution**
Dependency graph enables 3-5x velocity improvement.

**Adaptive preview gating**
Small epics skip manual preview, major epics require it.

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
