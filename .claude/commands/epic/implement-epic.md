---
name: implement-epic
description: Execute multiple sprints in parallel based on dependency graph from sprint-plan.md for epic workflows
argument-hint: [epic-slug]
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash(git add:*), Bash(git commit:*), Bash(git status:*), Task]
---

# /implement-epic — Parallel Sprint Execution

<context>
**User Input**: $ARGUMENTS

**Current Branch**: !`git branch --show-current 2>$null || echo "none"`

**Epic Directory**: !`dir /b /ad epics 2>$null | head -1 || echo "none"`

**Sprint Plan**: @epics/*/sprint-plan.md

**Total Sprints**: !`grep -c "^## Sprint S" epics/*/sprint-plan.md 2>$null || echo "0"`

**Execution Layers**: !`grep -c "^| Layer |" epics/*/sprint-plan.md 2>$null || echo "0"`

**Locked Contracts**: !`grep -c "^####.*Contract" epics/*/sprint-plan.md 2>$null || echo "0"`

**Git Status**: !`git status --short 2>$null || echo "clean"`

**Epic Artifacts** (after execution):
- @epics/*/sprints/S*/tasks.md (completed tasks per sprint)
- @epics/*/contracts/*.yaml (locked API contracts)
- @epics/*/workflow-state.yaml (epic status)
- @epics/*/audit-report.xml (effectiveness metrics)
</context>

<objective>
Execute multiple sprints in parallel based on dependency graph for epic workflows.

Parallel sprint execution workflow:
1. Detect epic workspace and load sprint-plan.md
2. Validate sprint directories, tasks, and contract files
3. Execute layers sequentially (sprints within layer run in parallel)
4. Launch specialist agents per sprint subsystem
5. Monitor progress and consolidate results
6. Auto-trigger workflow audit after completion
7. Present epic summary with velocity metrics

**Key principles**:
- **Dependency-driven parallelism**: Layers execute sequentially, sprints within layer run in parallel
- **Contract locking**: API contracts locked before implementation to enable parallel work
- **Specialist routing**: Backend sprints → backend-dev agent, Frontend → frontend-shipper, etc.
- **True parallel execution**: SINGLE message with multiple Task tool calls
- **Automatic auditing**: Effectiveness metrics captured after implementation

**Workflow position**: `epic → clarify → plan → tasks → implement-epic → optimize → preview → ship`
</objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent epic execution errors.

1. **Never assume sprint plan structure**
   - Always Read sprint-plan.md to verify structure
   - Quote actual layer dependencies and sprint IDs
   - Verify sprint directories exist before launching agents

2. **Never claim sprint completion without reading status**
   - Read workflow-state.yaml for each sprint
   - Quote actual status: "completed" or "failed"
   - Check contract violations are 0 before proceeding

3. **Never skip contract validation**
   - Verify all locked contracts exist as .yaml files
   - Check consumed contracts are accessible to consumers
   - Block layer progression if contract violations detected

4. **Verify parallel agent launches**
   - Confirm SINGLE message with multiple Task tool calls
   - Check all agents for layer launched together
   - Monitor agent responses for completion status

5. **Never invent velocity metrics**
   - Read actual duration from sprint workflow-state.yaml
   - Calculate multiplier from real data: expected_hours / actual_hours
   - Quote audit scores from audit-report.xml

**Why**: Fabricated epic results hide parallelization failures, contract violations, and bottlenecks. Accurate reading ensures epic workflows deliver promised velocity improvements.

---

<process>

### Step 1: Detect Epic Workspace and Load Sprint Plan

**Verify epic workspace:**
```bash
# Check for sprint-plan.md
if [ ! -f "epics/*/sprint-plan.md" ]; then
  echo "ERROR: No epic workspace detected"
  echo "Expected: epics/*/sprint-plan.md"
  exit 1
fi

EPIC_DIR=$(dirname $(find epics -name "sprint-plan.md" | head -1))
echo "Epic Directory: $EPIC_DIR"
```

**Read sprint-plan.md:**
```javascript
const sprintPlan = await Read(`${EPIC_DIR}/sprint-plan.md`);

const metadata = sprintPlan.sprint_plan.metadata;
const sprints = sprintPlan.sprint_plan.sprints.sprint;
const layers = sprintPlan.sprint_plan.execution_layers.layer;

log(`Epic: ${metadata.epic_slug}`);
log(`Total Sprints: ${metadata.total_sprints}`);
log(`Execution Strategy: ${metadata.execution_strategy}`);
log(`Estimated Duration: ${metadata.total_estimated_hours}h`);
```

### Step 2: Validate Sprint Directories and Contracts

**Check all sprint directories exist:**
```javascript
for (const sprint of sprints) {
  const sprintDir = `${EPIC_DIR}/sprints/${sprint.id}`;
  if (!fs.existsSync(sprintDir)) {
    throw new Error(`Sprint directory missing: ${sprintDir}`);
  }

  const tasksFile = `${sprintDir}/tasks.md`;
  if (!fs.existsSync(tasksFile)) {
    throw new Error(`Sprint tasks missing: ${tasksFile}`);
  }
}
```

**Verify contract files exist:**
```javascript
const contracts = sprintPlan.sprint_plan.sprints.sprint
  .flatMap(s => s.contracts_locked?.api_contract || []);

for (const contract of contracts) {
  const contractPath = `${EPIC_DIR}/${contract}`;
  if (!fs.existsSync(contractPath)) {
    throw new Error(`Contract missing: ${contractPath}`);
  }
}
```

### Step 3: Execute Layers Sequentially

**For each layer, execute all sprints in parallel (if layer.parallelizable):**

```javascript
for (const layer of layers) {
  console.log(`\n========================================`);
  console.log(`Executing Layer ${layer.num}: ${layer.sprint_ids}`);
  console.log(`Parallelizable: ${layer.parallelizable}`);
  console.log(`Dependencies: ${layer.dependencies || 'None'}`);
  console.log(`Rationale: ${layer.rationale}`);
  console.log(`========================================\n`);

  // Get sprints for this layer
  const layerSprints = layer.sprint_ids.split(',').map(id =>
    sprints.find(s => s.id === id)
  );

  if (layer.parallelizable && layerSprints.length > 1) {
    // CRITICAL: Launch all sprints in SINGLE message with multiple Task tool calls
    await executeSprintsInParallel(layerSprints, layer.num);
  } else {
    // Sequential execution (dependencies require it)
    for (const sprint of layerSprints) {
      await executeSprintSequential(sprint, layer.num);
    }
  }

  // Verify layer completion before proceeding
  for (const sprint of layerSprints) {
    const sprintStatus = checkSprintStatus(`${EPIC_DIR}/sprints/${sprint.id}`);
    if (sprintStatus !== 'completed') {
      throw new Error(`Sprint ${sprint.id} failed - cannot proceed to next layer`);
    }
  }

  log(`✅ Layer ${layer.num} completed successfully`);
}
```

### Step 4: Launch Parallel Sprint Agents (CRITICAL)

**IMPORTANT: Use SINGLE message with multiple Task tool calls**

When launching parallel sprints, you MUST invoke all Task tools in a single message to enable true parallel execution.

**Example for 3 parallel sprints in Layer 1:**

```markdown
I'm going to launch 3 sprints in parallel using specialist agents:
- S01: Backend API (backend-dev agent)
- S04: DevOps Infrastructure (general-purpose agent)
- S05: Documentation (general-purpose agent)

(Then invoke 3 Task tools in the SAME message)
```

**Agent Selection per Sprint:**
- Backend/Database sprints → `backend-dev` agent
- Frontend/UI sprints → `frontend-shipper` agent
- Testing sprints → `test-architect` or `qa-test` agent
- Mixed/Integration sprints → `general-purpose` agent
- Infrastructure/DevOps → `general-purpose` agent

**Sprint Agent Prompt Template:**

```text
Execute Sprint {SPRINT_ID}: {SPRINT_NAME}

**Sprint Context:**
- Epic Directory: {EPIC_DIR}
- Sprint ID: {SPRINT_ID}
- Sprint Directory: {EPIC_DIR}/sprints/{SPRINT_ID}
- Tasks File: {EPIC_DIR}/sprints/{SPRINT_ID}/tasks.md
- Subsystems: {SUBSYSTEMS}
- Dependencies: {DEPENDENCIES} (from previous layers)

**Contracts:**
{IF contracts_to_lock}
- Lock these contracts (producer role):
  {LIST contracts_to_lock}
- Generate OpenAPI 3.0 specs from plan.md API design section
- Write to: {EPIC_DIR}/contracts/*.yaml
{ENDIF}

{IF contracts_consumed}
- Consume these contracts (consumer role):
  {LIST contracts_consumed}
- Generate typed API clients from OpenAPI specs
- Strict adherence required (no deviations)
{ENDIF}

**Workflow:**
1. Read tasks from {EPIC_DIR}/sprints/{SPRINT_ID}/tasks.md
2. {IF contracts_to_lock}Lock API contracts before implementation{ENDIF}
3. Execute each task with TDD workflow:
   - Red: Write failing test
   - Green: Implement to pass test
   - Refactor: Improve without changing behavior
   - Commit: Atomic commit per task
4. Run sprint-level test suite
5. **Update sprint workflow-state.yaml** (CRITICAL - must happen after completion):
   ```yaml
   # {EPIC_DIR}/sprints/{SPRINT_ID}/workflow-state.yaml
   sprint:
     id: {SPRINT_ID}
     status: completed  # or failed if tests fail
     started_at: {ISO_TIMESTAMP}
     completed_at: {ISO_TIMESTAMP}
     duration_hours: {ACTUAL_HOURS}

   tasks:
     total: {TOTAL_TASKS}
     completed: {COMPLETED_TASKS}
     failed: {FAILED_TASKS}

   tests:
     total: {TOTAL_TESTS}
     passed: {PASSED_TESTS}
     failed: {FAILED_TESTS}
     coverage_percent: {COVERAGE}

   contracts:
     locked: [{LIST_OF_CONTRACTS}]
     consumed: [{LIST_OF_CONTRACTS}]
     violations: 0  # Must be 0 to proceed
   ```

**Requirements:**
- TDD strictly enforced (tests before code)
- Atomic commits per task (rollback-friendly)
- Pattern consistency with plan.md
- Anti-duplication checks (scan before creating)
- Contract compliance verification
- Performance benchmarks captured

**Return Summary:**
- Completed tasks: {count}
- Tests passed: {count}
- Contracts locked: {list}
- Contract violations: {count} (must be 0)
- Duration: {hours}h
- Status: completed | failed | blocked

**On Failure:**
- Auto-rollback to last good commit
- Document blocker in sprint status
- Do NOT proceed if critical
```

### Step 5: Monitor Sprint Progress

**While sprints are executing:**

```javascript
// Agents execute in parallel
// Each agent updates its sprint's workflow-state.yaml

// Poll sprint status files
const sprintStatuses = layerSprints.map(s => ({
  id: s.id,
  status: readYAML(`${EPIC_DIR}/sprints/${s.id}/workflow-state.yaml`).status,
  progress: readYAML(`${EPIC_DIR}/sprints/${s.id}/workflow-state.yaml`).tasks_completed
}));

// Display progress
console.log(`Sprint Progress (Layer ${layerNum}):`);
for (const status of sprintStatuses) {
  console.log(`  ${status.id}: ${status.status} (${status.progress}% complete)`);
}
```

**Failure handling:**
```javascript
// If any sprint fails, block layer progression
const failedSprints = sprintStatuses.filter(s => s.status === 'failed');
if (failedSprints.length > 0) {
  throw new Error(`Sprint failures in Layer ${layerNum}: ${failedSprints.map(s => s.id).join(', ')}`);
}
```

### Step 6: Consolidate Sprint Results

**After layer completes, consolidate results:**

```javascript
const layerResults = {
  layer_num: layerNum,
  sprints_completed: layerSprints.length,
  total_tasks: 0,
  total_tests: 0,
  duration_hours: 0,
  contracts_locked: [],
  contract_violations: []
};

for (const sprint of layerSprints) {
  const sprintState = readYAML(`${EPIC_DIR}/sprints/${sprint.id}/workflow-state.yaml`);

  layerResults.total_tasks += sprintState.tasks_completed;
  layerResults.total_tests += sprintState.tests_passed;
  layerResults.duration_hours += sprintState.duration_hours;

  if (sprintState.contracts_locked) {
    layerResults.contracts_locked.push(...sprintState.contracts_locked);
  }

  if (sprintState.contract_violations) {
    layerResults.contract_violations.push(...sprintState.contract_violations);
  }
}

// Verify no contract violations
if (layerResults.contract_violations.length > 0) {
  throw new Error(`Contract violations detected in Layer ${layerNum}: ${JSON.stringify(layerResults.contract_violations)}`);
}

log(`✅ Layer ${layerNum} Results:`);
log(`  Sprints: ${layerResults.sprints_completed}`);
log(`  Tasks: ${layerResults.total_tasks}`);

// **CRITICAL: Update epic-level workflow-state.yaml after layer completion**
const epicState = readYAML(`${EPIC_DIR}/workflow-state.yaml`);
epicState.layers.completed += 1;
epicState.sprints.completed += layerResults.sprints_completed;

writeYAML(`${EPIC_DIR}/workflow-state.yaml`, epicState);

log(`📊 Epic Progress: Layer ${epicState.layers.completed}/${epicState.layers.total} complete`);
log(`  Tests: ${layerResults.total_tests}`);
log(`  Duration: ${layerResults.duration_hours}h`);
log(`  Contracts Locked: ${layerResults.contracts_locked.length}`);
```

### Step 7: Auto-Trigger Workflow Audit

**After all layers complete, trigger audit:**

```bash
# Epic implementation complete, now audit workflow effectiveness
/audit-workflow
```

**What the audit does:**
- Analyzes sprint parallelization effectiveness
- Calculates actual velocity multiplier vs expected
- Identifies bottlenecks in critical path
- Detects inefficiencies in dependency graph
- Generates improvement recommendations

**Output:** `{EPIC_DIR}/audit-report.xml`

### Step 8: Commit Epic Implementation

```bash
git add epics/*/sprints/*/
git add epics/*/contracts/*.yaml
git add epics/*/workflow-state.yaml
git add epics/*/audit-report.xml

git commit -m "feat(epic): complete epic with parallel sprint execution

[EPIC SUMMARY]
Epic: ${epic_slug}
Total Sprints: ${total_sprints}
Execution Strategy: ${execution_strategy}

[VELOCITY METRICS]
Expected Duration: ${expected_hours}h (sequential)
Actual Duration: ${actual_hours}h (parallel)
Velocity Multiplier: ${multiplier}x

[SPRINT RESULTS]
$(sprints.map(s => \`- \${s.id}: \${s.tasks_completed} tasks, \${s.tests_passed} tests, \${s.duration_hours}h\`).join('\n'))

[CONTRACTS]
Locked: ${contracts_locked.length}
Violations: ${contract_violations.length} (must be 0)

[AUDIT SCORE]
Overall: ${audit_score}/100
Bottlenecks: ${bottlenecks.length}
Recommendations: ${recommendations.length}

Next: /optimize

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Step 9: Present Epic Summary

**Display to user:**

```
✅ Epic Implementation Complete

Epic: ${epic_slug}
Total Sprints: ${total_sprints}
Execution Strategy: ${execution_strategy}

Sprint Results:
$(sprints.map(s => \`
  \${s.id}: \${s.name}
    Status: ✅ Completed
    Tasks: \${s.tasks_completed}
    Tests: \${s.tests_passed}
    Duration: \${s.duration_hours}h
    Contracts: \${s.contracts_locked?.length || 0} locked, \${s.contracts_consumed?.length || 0} consumed
\`).join('\n'))

Velocity Metrics:
  Expected (sequential): ${expected_hours}h
  Actual (parallel): ${actual_hours}h
  Velocity Multiplier: ${multiplier}x
  Time Saved: ${time_saved}h

Contract Compliance:
  Locked: ${contracts_locked.length}
  Violations: ${contract_violations.length} ✅

Audit Score: ${audit_score}/100
  Phase Efficiency: ${phase_efficiency}/100
  Sprint Parallelization: ${parallelization_score}/100
  Quality Gates: ${quality_gates_score}/100
  Documentation: ${docs_score}/100

Bottlenecks Detected:
$(bottlenecks.map(b => \`  - \${b.description} (impact: \${b.impact})\`).join('\n'))

Recommendations:
$(recommendations.map(r => \`  - \${r.title}: \${r.description}\`).join('\n'))

Artifacts Generated:
  ✅ sprints/*/tasks.md (all completed)
  ✅ contracts/*.yaml (${contracts_locked.length} locked)
  ✅ audit-report.xml
  ✅ workflow-state.yaml (updated)

Next: /optimize (quality gates + apply audit recommendations)
```

</process>

<success_criteria>
**Epic implementation successfully completed when:**

1. **All layers executed**:
   - All execution layers from sprint-plan.md processed sequentially
   - Parallel sprints within each layer completed successfully
   - No failed or blocked sprints remain

2. **Contract compliance verified**:
   - All locked contracts exist as .yaml files in epics/*/contracts/
   - No contract violations detected (count = 0)
   - Consumed contracts accessible to all consumers

3. **Sprint results consolidated**:
   - All sprint workflow-state.yaml files show status: completed
   - Task completion counts accurate
   - Test results aggregated correctly

4. **Velocity metrics calculated**:
   - Actual duration captured from sprint statuses
   - Velocity multiplier calculated: expected_hours / actual_hours
   - Time saved documented

5. **Workflow audit completed**:
   - audit-report.xml generated with effectiveness metrics
   - Audit score ≥70/100
   - Bottlenecks and recommendations documented

6. **Git commits clean**:
   - All sprint code committed atomically
   - Locked contracts committed
   - Epic summary commit with velocity metrics
   - No uncommitted changes remain
</success_criteria>

<verification>
**Before marking epic implementation complete, verify:**

1. **Read sprint-plan.md execution layers**:
   ```bash
   grep "^| Layer |" epics/*/sprint-plan.md
   ```
   All layers should be processed

2. **Check all sprint statuses**:
   ```bash
   grep "status:" epics/*/sprints/*/workflow-state.yaml
   ```
   All should show "completed"

3. **Verify contract violations are zero**:
   ```bash
   grep "contract_violations:" epics/*/sprints/*/workflow-state.yaml
   ```
   All counts should be 0

4. **Confirm audit report exists**:
   ```bash
   cat epics/*/audit-report.xml
   ```
   Should contain audit score and recommendations

5. **Check git commits**:
   ```bash
   git log --oneline -5
   ```
   Should show epic implementation commit

6. **Validate locked contracts**:
   ```bash
   ls epics/*/contracts/*.yaml
   ```
   Should list all locked API contracts

**Never claim epic completion without reading all sprint workflow-state.yaml files.**
</verification>

<output>
**Files created/modified by this command:**

**Sprint implementations** (epics/NNN-slug/sprints/S*/):
- tasks.md — All tasks marked as completed per sprint
- workflow-state.yaml — Sprint status, task counts, test results, contract info
- Source code files (varies by sprint subsystem)

**API Contracts** (epics/NNN-slug/contracts/):
- *.yaml — OpenAPI 3.0 specifications for locked contracts
- Contract files enable parallel work by defining API boundaries

**Epic tracking** (epics/NNN-slug/):
- workflow-state.yaml — Epic-level status with layer completion
- audit-report.xml — Effectiveness metrics, bottlenecks, recommendations

**Git commits**:
- Atomic commits per task per sprint
- Sprint completion commits
- Epic summary commit with velocity metrics

**Console output**:
- Layer-by-layer execution progress
- Sprint status monitoring
- Velocity metrics and time saved
- Audit score and recommendations
- Next action recommendation (/optimize)
</output>

---

## Quick Reference

### Parallel Execution Model

**Layer structure:**
- Layer 1: Independent sprints (S01, S04, S05) → parallel
- Layer 2: Dependent sprints (S02, S06) → depends on Layer 1
- Layer 3: Integration sprints (S03) → depends on Layer 2

**Critical rule:**
Launch all parallel sprints in SINGLE message with multiple Task tool calls.

### Agent Routing

- Backend sprints → `backend-dev`
- Frontend sprints → `frontend-shipper`
- Database sprints → `database-architect`
- Testing sprints → `test-architect` or `qa-test`
- Mixed sprints → `general-purpose`
- Infrastructure → `general-purpose`

### Contract Workflow

**Producer role** (locks contracts):
1. Read API design from plan.md
2. Generate OpenAPI 3.0 spec
3. Write to epics/*/contracts/*.yaml
4. Implement API following spec

**Consumer role** (consumes contracts):
1. Read locked contract from epics/*/contracts/*.yaml
2. Generate typed API client
3. Use client in implementation
4. Report violations if contract changes

### Error Handling

**Sprint failure:**
- Auto-rollback to last good commit
- Mark sprint as failed in workflow-state.yaml
- Block layer progression
- Present error to user for manual fix

**Contract violation:**
- Detect during consolidation
- Block layer progression
- Report violating sprint and expected vs actual
- Require fix before continuing
