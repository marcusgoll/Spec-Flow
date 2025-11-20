# Remaining Phase Enhancements Implementation Guide

This document outlines the enhancements needed for the remaining phase commands to complete the Epic-Driven Adaptive Workflow transformation (v5.0).

## Status Summary

✅ **COMPLETED:**

- `/epic` command created
- XML templates (epic-spec.xml, sprint-plan.xml, walkthrough.xml)
- Infrastructure commands (audit-workflow, heal-workflow, workflow-health)
- Taches' meta commands, skills, and agents integrated
- `/clarify` enhanced with auto-invoke + AskUserQuestion

🔨 **REMAINING:**

- `/plan` - Meta-prompting integration
- `/tasks` - Sprint breakdown with dependency graph
- `/implement` - Parallel sprint execution
- `/optimize` - Workflow audit integration
- `/preview` - Adaptive gating logic
- `/finalize` - Walkthrough generation
- Epic agent brief

---

## 1. /plan Enhancement (Meta-Prompting Integration)

**Location:** `.claude/commands/phases/plan.md`

**Changes Needed:**

### Add Meta-Prompting Section (Before existing logic)

````markdown
## META-PROMPTING WORKFLOW (New in v5.0)

**For epic workflows**, use meta-prompting to generate research → plan pipeline:

### Step 1: Generate Research Prompt

```bash
/create-prompt "Research technical approach for: [epic objective from epic-spec.xml]"
```
````

**The create-prompt skill will:**

- Detect purpose: Research
- Ask contextual questions (depth, sources, output format)
- Generate research prompt in `.prompts/001-[epic-slug]-research/`
- Reference project docs (@docs/project/tech-stack.md, @docs/project/architecture.md)
- Specify XML output: research.xml with metadata

### Step 2: Execute Research Prompt

```bash
/run-prompt 001-[epic-slug]-research
```

**Output:** `.prompts/001-[epic-slug]-research/research.xml`

- Findings with confidence levels
- Dependencies identified
- Open questions flagged
- Assumptions documented

### Step 3: Generate Plan Prompt

```bash
/create-prompt "Create implementation plan based on research findings"
```

**The create-prompt skill will:**

- Reference research.xml from previous step
- Generate plan prompt in `.prompts/002-[epic-slug]-plan/`
- Specify plan.xml output with phases, dependencies, constraints

### Step 4: Execute Plan Prompt

```bash
/run-prompt 002-[epic-slug]-plan
```

**Output:** `.prompts/002-[epic-slug]-plan/plan.xml`

- Architecture decisions
- Implementation phases
- Risk assessment
- Resource requirements

### Step 5: Convert to Legacy Format (If Needed)

For compatibility with existing workflow, convert XML to markdown:

```bash
# Read plan.xml
# Extract architecture decisions, phases, risks
# Write to traditional plan.md format
```

**Detection Logic:**

```javascript
const isEpic = fs.existsSync("epics/*/epic-spec.xml");
if (isEpic) {
  // Use meta-prompting workflow
  runMetaPrompting();
} else {
  // Use traditional planning workflow
  runTraditionalPlanning();
}
```

````

### Integration Points

- Reads: `epic-spec.xml` (if epic), `spec.md` (if feature)
- Outputs: `research.xml`, `plan.xml` (epics) OR `plan.md` (features)
- Next phase: `/tasks`

---

## 2. /tasks Enhancement (Sprint Breakdown)

**Location:** `.claude/commands/phases/tasks.md`

**Changes Needed:**

### Add Sprint Decomposition Logic

```markdown
## EPIC SPRINT BREAKDOWN (New in v5.0)

**For epic workflows**, decompose plan into sprints with dependency graph:

### Step 1: Detect Epic vs Feature

```javascript
const isEpic = fs.existsSync(workspaceDir + '/epic-spec.xml');
const planPath = isEpic ? 'plan.xml' : 'plan.md';
````

### Step 2: Analyze Complexity

```javascript
// Read plan to understand phases and subsystems
const plan = readXML("plan.xml");
const estimatedHours = calculateEstimate(plan.phases);
const subsystems = plan.subsystems; // backend, frontend, database, etc.

// Determine if multi-sprint
const needsMultiplesprints = estimatedHours > 16 || subsystems.length > 2;
```

### Step 3: Create Sprint Boundaries

```javascript
if (needsMultipleSprints) {
  // Group tasks by subsystem and dependencies
  const sprints = {
    S01: {
      name: "Backend API",
      subsystems: ["backend", "database"],
      dependencies: [],
      tasks: filterTasksBySubsystem(allTasks, ["backend", "database"]),
    },
    S02: {
      name: "Frontend UI",
      subsystems: ["frontend"],
      dependencies: ["S01"], // needs backend API
      tasks: filterTasksBySubsystem(allTasks, ["frontend"]),
    },
    S03: {
      name: "Integration & Tests",
      subsystems: ["backend", "frontend", "testing"],
      dependencies: ["S01", "S02"],
      tasks: filterTasksBySubsystem(allTasks, ["testing"]),
    },
  };
}
```

### Step 4: Build Dependency Graph

```javascript
const dependencyGraph = {
  layers: [
    { num: 1, sprints: ["S01"], parallelizable: true, dependencies: [] },
    { num: 2, sprints: ["S02"], parallelizable: false, dependencies: ["S01"] },
    {
      num: 3,
      sprints: ["S03"],
      parallelizable: false,
      dependencies: ["S01", "S02"],
    },
  ],
};
```

### Step 5: Lock API Contracts

```javascript
// Identify contracts that must be locked before parallel work
const contracts = identifyContracts(sprints);

for (const contract of contracts) {
  // Create OpenAPI schema or GraphQL schema
  generateContract(contract, {
    path: `contracts/api/${contract.name}.yaml`,
    producer: contract.producer_sprint,
    consumers: contract.consumer_sprints,
  });
}
```

### Step 6: Generate sprint-plan.xml

Use template: `.spec-flow/templates/sprint-plan.xml`

Fill in:

- Sprint metadata (IDs, names, estimates)
- Dependencies between sprints
- Execution layers for parallel execution
- Locked contracts
- Critical path analysis

````

### Integration Points

- Reads: `plan.xml` (epics) OR `plan.md` (features)
- Outputs: `sprint-plan.xml` (epics) OR `tasks.md` (features)
- Next phase: `/implement`

---

## 3. /implement Enhancement (Parallel Execution)

**Location:** `.claude/commands/phases/implement.md`

**Changes Needed:**

### Add Parallel Sprint Execution

```markdown
## PARALLEL SPRINT EXECUTION (New in v5.0)

**For epic workflows**, execute sprints in parallel based on dependency graph:

### Step 1: Load Sprint Plan

```javascript
const sprintPlan = readXML('sprint-plan.xml');
const layers = sprintPlan.execution_layers.layer;
````

### Step 2: Execute Layers Sequentially

```javascript
for (const layer of layers) {
  console.log(`Executing Layer ${layer.number}: ${layer.sprint_ids}`);

  if (
    layer.parallelizable === "true" &&
    layer.sprint_ids.split(",").length > 1
  ) {
    // Launch parallel Task agents (MUST be in single message)
    await executeParallelSprints(layer.sprint_ids.split(","));
  } else {
    // Execute single sprint
    await executeSprint(layer.sprint_ids);
  }

  // Wait for layer to complete before next layer
  await waitForLayerCompletion(layer.number);
}
```

### Step 3: Launch Parallel Task Agents

**CRITICAL:** All parallel Task invocations must be in a SINGLE message:

```javascript
function executeParallelSprints(sprintIds) {
  // Build array of Task tool calls
  const taskCalls = sprintIds.map((sprintId) => ({
    subagent_type: "backend-dev", // or frontend-dev, database-architect
    description: `Implement sprint ${sprintId}`,
    prompt: `
      Implement sprint: ${sprintId}

      Context:
      - Epic spec: @epic-spec.xml
      - Research: @research.xml
      - Plan: @plan.xml
      - Tasks: @tasks.xml (filter to sprint_id=${sprintId})
      - Contracts: @contracts/api/*.yaml

      Requirements:
      - TDD: Write tests first
      - Type safety: No implicit any
      - Contract compliance: Follow locked API contracts
      - Anti-duplication: Reuse existing patterns

      Output: Implementation in sprints/${sprintId}/
    `,
  }));

  // Invoke ALL tasks in SINGLE message
  return TaskParallel(taskCalls);
}
```

### Step 4: Monitor Progress

```javascript
// Show progress across sprints
console.log(`
Layer 1/3: S01 (backend) ✓ Complete
Layer 2/3: S02 (frontend) → In progress (65%)
Layer 3/3: S03 (integration) → Pending
`);
```

### Step 5: Consolidate Results

```javascript
const results = [];
for (const sprint of completedSprints) {
  results.push({
    sprint_id: sprint.id,
    status: sprint.status,
    tasks_completed: sprint.tasks_completed,
    tests_passing: sprint.tests_passing,
    duration_hours: sprint.duration,
  });
}

// Write consolidated report
writeResults("implementation-report.xml", results);
```

### Step 6: Auto-Audit

After all sprints complete:

```bash
/audit-workflow
```

````

### Integration Points

- Reads: `sprint-plan.xml` (epics) OR `tasks.md` (features)
- Outputs: Implementation in `sprints/*/` (epics) OR `src/` (features)
- Triggers: `/audit-workflow` (auto)
- Next phase: `/optimize`

---

## 4. /optimize Enhancement (Workflow Audit)

**Location:** `.claude/commands/phases/optimize.md`

**Changes Needed:**

### Add Workflow Audit Integration

```markdown
## WORKFLOW AUDIT INTEGRATION (New in v5.0)

**After quality gates**, run workflow audit:

### Existing Quality Gates

(Keep existing logic for performance, security, accessibility, code quality)

### Add Workflow Audit Step

```bash
# After all quality gates pass/fail
echo "Running workflow effectiveness audit..."

/audit-workflow
````

**Audit analyzes:**

- Phase efficiency (time vs value)
- Bottleneck detection
- Sprint parallelization effectiveness
- Quality gate effectiveness
- Documentation quality

**Output:** `audit-report.xml` in epic/feature workspace

````

### Integration Points

- Runs after: Quality gates complete
- Outputs: `audit-report.xml`
- Next phase: `/preview` or `/ship`

---

## 5. /preview Enhancement (Adaptive Gating)

**Location:** `.claude/commands/phases/preview.md`

**Changes Needed:**

### Add Adaptive Auto-Skip Logic

```markdown
## ADAPTIVE PREVIEW GATING (New in v5.0)

**Analyze complexity to determine if manual preview needed:**

### Step 1: Complexity Analysis

```javascript
const epic = readXML('epic-spec.xml');
const sprints = epic ? readXML('sprint-plan.xml').sprints : null;

const complexity = {
  is_epic: !!epic,
  sprint_count: sprints ? sprints.sprint.length : 1,
  has_ui_changes: detectUIChanges(),
  subsystems: epic ? epic.subsystems : detectSubsystems()
};

// Determine if preview needed
const needsPreview =
  complexity.has_ui_changes ||
  complexity.sprint_count > 2 ||
  complexity.subsystems.includes('frontend');
````

### Step 2: Auto-Skip Decision

```javascript
if (!needsPreview) {
  console.log("✅ Preview auto-skipped: No UI changes, small epic");

  // Run AI pre-flight checks anyway
  runAutomatedChecks();

  // Update workflow state
  updateWorkflowState({
    preview: {
      status: "skipped",
      reason: "No UI changes detected, backend-only epic",
      automated_checks: "passed",
    },
  });

  return { skipped: true };
}
```

### Step 3: AI Pre-Flight Checks (Always Run)

```javascript
const preFlightChecks = {
  accessibility: runAccessibilityScan(),
  visual_regression: runVisualRegression(),
  integration_smoke: runSmokeTests(),
};

// Generate preview-report.xml
writePreviewReport(preFlightChecks);
```

### Step 4: Manual Preview (If Needed)

(Keep existing manual preview logic for UI-heavy epics)

````

### Integration Points

- Reads: `epic-spec.xml`, `sprint-plan.xml`
- Outputs: `preview-report.xml`
- Next phase: `/ship`

---

## 6. /finalize Enhancement (Walkthrough Generation)

**Location:** `.claude/commands/phases/finalize.md`

**Changes Needed:**

### Add Walkthrough Generation

```markdown
## WALKTHROUGH GENERATION (New in v5.0)

**After deployment complete**, generate comprehensive walkthrough:

### Step 1: Gather All Artifacts

```javascript
const artifacts = {
  epic_spec: readXML('epic-spec.xml'),
  research: readXML('research.xml'),
  plan: readXML('plan.xml'),
  sprint_plan: readXML('sprint-plan.xml'),
  tasks: readXML('tasks.xml'),
  workflow_state: readYAML('workflow-state.yaml'),
  audit_report: readXML('audit-report.xml'),
  optimization_report: readXML('optimization-report.xml')
};
````

### Step 2: Calculate Metrics

```javascript
const metrics = {
  duration: calculateDuration(artifacts.workflow_state),
  velocity_multiplier: artifacts.audit_report.velocity_impact.actual_multiplier,
  sprint_count: artifacts.sprint_plan.sprints.sprint.length,
  tasks_completed: artifacts.tasks.task.filter((t) => t.status === "completed")
    .length,
  quality_score: artifacts.audit_report.overall_score,
};
```

### Step 3: Extract Key Information

```javascript
const walkthrough = {
  overview: extractOverview(artifacts),
  phases_completed: extractPhases(artifacts.workflow_state),
  sprints_summary: extractSprints(
    artifacts.sprint_plan,
    artifacts.workflow_state
  ),
  validation: extractValidation(artifacts.optimization_report),
  key_files_modified: extractFileChanges(),
  next_steps: extractNextSteps(artifacts.audit_report),
  summary: extractSummary(artifacts),
};
```

### Step 4: Generate walkthrough.md

Use template: `.spec-flow/templates/walkthrough.xml`

Fill all sections with actual data from artifacts.

### Step 5: Run Post-Mortem Audit

```bash
/audit-workflow
```

### Step 6: Pattern Detection (After 2-3 Epics)

```javascript
const completedEpics = countCompletedEpics();

if (completedEpics >= 2) {
  // Analyze patterns across epics
  const patterns = detectPatterns(getAllEpics());

  // Suggest custom skills/commands
  if (patterns.code_generation.frequency >= 3) {
    console.log(`
🔍 Pattern Detected: ${patterns.code_generation.name}
   Frequency: ${patterns.code_generation.frequency}x
   Suggestion: Create custom skill to automate this

   Run: /create-agent-skills to generate
    `);
  }
}
```

### Step 7: Self-Healing Offer

```bash
# After audit complete, offer to apply improvements
echo "Workflow audit complete. Apply improvements?"

# Use AskUserQuestion
AskUserQuestion({
  questions: [{
    question: "Apply workflow improvements discovered in audit?",
    header: "Self-Healing",
    multiSelect: false,
    options: [
      { label: "Yes, apply now", description: "Run /heal-workflow automatically" },
      { label: "Review first", description: "I'll run /heal-workflow manually" },
      { label: "Skip", description: "Defer improvements to next epic" }
    ]
  }]
});

if (userChoice === "Yes, apply now") {
  /heal-workflow
}
```

````

### Integration Points

- Reads: All epic artifacts
- Outputs: `walkthrough.md`, updated `audit-report.xml`
- Triggers: `/audit-workflow`, optionally `/heal-workflow`
- Updates: `CHANGELOG.md`, `README.md`, Project `CLAUDE.md`

---

## 7. Epic Agent Brief

**Location:** `.claude/agents/phase/epic.md`

**Content:**

```markdown
---
name: epic
description: Epic orchestrator agent for multi-sprint workflow coordination
tools: Read, Write, Edit, Bash, Task, AskUserQuestion
model: sonnet
---

<role>
You are an epic orchestrator agent responsible for coordinating multi-sprint workflows with parallel execution and adaptive self-improvement.
</role>

<capabilities>
- Auto-detect epic vs feature complexity
- Auto-invoke /clarify based on ambiguity analysis
- Orchestrate research → plan → sprint breakdown pipeline
- Coordinate parallel sprint execution via dependency graph
- Monitor cross-sprint progress
- Generate comprehensive walkthrough documentation
- Trigger workflow audits and self-healing
</capabilities>

<workflow>
1. **Epic Specification**: Generate epic-spec.xml from user goal
2. **Clarification**: Auto-invoke if ambiguity score > 30
3. **Meta-Prompting**: Research → Plan pipeline via /create-prompt + /run-prompt
4. **Sprint Breakdown**: Analyze plan, create sprint-plan.xml with dependency graph
5. **Parallel Implementation**: Execute sprints in layers based on dependencies
6. **Quality Gates**: Run optimization with workflow audit
7. **Adaptive Preview**: Auto-skip for non-UI epics
8. **Deployment**: Unified /ship orchestration
9. **Walkthrough**: Generate comprehensive epic summary
10. **Self-Healing**: Audit → Heal cycle for continuous improvement
</workflow>

<anti_patterns>
- Never skip ambiguity detection (always calculate score)
- Never execute dependent sprints before dependencies complete
- Never skip workflow audit after implementation
- Never fabricate velocity metrics (read from actual timing data)
- Never skip walkthrough generation (critical for learning)
</anti_patterns>

<integration>
**Commands orchestrated:**
- /epic (entry point)
- /clarify (auto-invoked)
- /create-prompt + /run-prompt (meta-prompting)
- /plan, /tasks, /implement, /optimize, /preview, /ship, /finalize

**Artifacts produced:**
- epic-spec.xml
- research.xml, plan.xml (via meta-prompting)
- sprint-plan.xml
- walkthrough.md
- audit-report.xml

**Self-improvement:**
- /audit-workflow (after implement, during optimize, after finalize)
- /heal-workflow (apply improvements)
- /workflow-health (aggregate metrics)
</integration>
````

---

## Implementation Priority

1. **High Priority** (Critical for epic workflow):

   - `/plan` meta-prompting
   - `/tasks` sprint breakdown
   - `/implement` parallel execution
   - `/finalize` walkthrough generation

2. **Medium Priority** (Enhances experience):

   - `/optimize` workflow audit integration
   - `/preview` adaptive gating
   - Epic agent brief

3. **Low Priority** (Can defer):
   - Additional polish on commands
   - Extended examples
   - Advanced error handling

---

## Testing Strategy

**After implementation, test with sample epic:**

1. Create test epic: "User authentication with OAuth 2.1"
2. Run through full workflow: `/epic → /clarify → /plan → /tasks → /implement → /optimize → /preview → /ship → /finalize`
3. Validate:
   - XML artifacts generated correctly
   - Meta-prompting produces research.xml and plan.xml
   - Sprint decomposition creates valid dependency graph
   - Parallel execution launches multiple Task agents
   - Walkthrough.md contains comprehensive summary
   - Audit report identifies improvements

**Expected results:**

- 3-5x velocity improvement (vs sequential)
- All XML artifacts valid and complete
- Workflow audit score ≥ 80/100
- Walkthrough documents lessons learned

---

## Next Steps After Implementation

1. **Documentation**: Update CLAUDE.md and README.md
2. **Examples**: Add sample epic walkthroughs
3. **Migration Guide**: Help users transition from /feature to /epic
4. **Backwards Compatibility**: Ensure /feature still works
5. **Release**: Version 5.0.0 with breaking changes documented
