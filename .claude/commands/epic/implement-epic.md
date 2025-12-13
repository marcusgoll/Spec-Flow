---
name: implement-epic
description: Execute multiple sprints in parallel based on dependency graph from sprint-plan.md for epic workflows
argument-hint: [epic-slug] [--auto-mode]
allowed-tools:
  [
    Read,
    Write,
    Edit,
    Grep,
    Glob,
    Bash(git add:*),
    Bash(git commit:*),
    Bash(git status:*),
    Task,
  ]
---

# /implement-epic — Parallel Sprint Execution

<context>
**User Input**: $ARGUMENTS

**Current Branch**: !`git branch --show-current 2>/dev/null || echo "none"`

**Epic Directory**: !`ls -d epics/*/ 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "none"`

**Worktree Context**: !`bash .spec-flow/scripts/bash/worktree-context.sh info 2>/dev/null || echo '{"is_worktree": false}'`

**Worktree Auto-Create**: !`bash .spec-flow/scripts/utils/load-preferences.sh --key "worktrees.auto_create" --default "true" 2>/dev/null || echo "true"`

**Sprint Plan**: @epics/\*/sprint-plan.md

**Total Sprints**: !`grep -c "^## Sprint S" epics/*/sprint-plan.md 2>/dev/null || echo "0"`

**Execution Layers**: !`grep -c "^| Layer |" epics/*/sprint-plan.md 2>/dev/null || echo "0"`

**Locked Contracts**: !`grep -c "^####.*Contract" epics/*/sprint-plan.md 2>/dev/null || echo "0"`

**Git Status**: !`git status --short 2>/dev/null || echo "clean"`

**Epic Artifacts** (after execution):

- @epics/_/sprints/S_/tasks.md (completed tasks per sprint)
- @epics/_/contracts/_.yaml (locked API contracts)
- @epics/\*/state.yaml (epic status)
- @epics/\*/audit-report.xml (effectiveness metrics)
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
- **Specialist routing**: Backend sprints → backend-dev agent, Frontend → frontend-dev, etc.
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

   - Read state.yaml for each sprint
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
   - Read actual duration from sprint state.yaml
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

### Step 1.5: Read Auto-Mode Setting

**Load auto_mode from workflow state or CLI arguments:**

```javascript
// Check CLI arguments first (highest priority)
const args = "$ARGUMENTS".trim();
const hasAutoModeFlag = args.includes("--auto-mode");

// Fall back to state.yaml if no CLI flag
let autoMode = hasAutoModeFlag;

if (!hasAutoModeFlag) {
  const workflowState = readYAML(`${EPIC_DIR}/state.yaml`);
  autoMode = workflowState.epic.auto_mode || false;
}

// Display mode to user
if (autoMode) {
  log(
    "🤖 Auto-mode enabled - will attempt auto-fixes for non-critical failures"
  );
  log("🛑 Will stop only for: CI failures, security issues, deployment errors");
  log("🔄 Fixable issues (tests, builds, infrastructure) will be auto-retried");
} else {
  log("📋 Interactive mode - will pause for all failures");
}

// Store for use in error handling
global.AUTO_MODE = autoMode;
```

**Auto-mode contract:**

- **Stop for**: CI pipeline failures, security scan failures, deployment errors (critical blockers)
- **Auto-retry for**: Test failures, build failures, npm install errors, infrastructure issues (fixable issues)
- **Retry attempts**: 2-3 attempts with progressive delays (5s, 10s, 30s)
- **Auto-fix strategies**: `npm cache clean`, `docker restart`, rebuild, re-run tests

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
const contracts = sprintPlan.sprint_plan.sprints.sprint.flatMap(
  (s) => s.contracts_locked?.api_contract || []
);

for (const contract of contracts) {
  const contractPath = `${EPIC_DIR}/${contract}`;
  if (!fs.existsSync(contractPath)) {
    throw new Error(`Contract missing: ${contractPath}`);
  }
}
```

### Step 2.5: Failure Classification and Auto-Fix Utilities

**CRITICAL**: These functions enable auto-mode to distinguish between critical blockers (must stop) and fixable issues (can auto-retry).

**Classify failure type:**

```javascript
/**
 * Classify sprint failure into critical blocker or fixable issue
 * @param {string} sprintId - Sprint identifier (e.g., "S01")
 * @returns {"critical" | "fixable" | "unknown"} - Failure classification
 */
function classifyFailure(sprintId) {
  const sprintState = readYAML(`${EPIC_DIR}/sprints/${sprintId}/state.yaml`);

  // Critical blockers (MUST stop, even in auto-mode)
  if (sprintState.ci_pipeline_failed) {
    return {
      type: "critical",
      reason: "CI pipeline failure detected",
      details: sprintState.ci_error || "GitHub Actions/GitLab CI failed",
    };
  }

  if (sprintState.security_scan_failed) {
    return {
      type: "critical",
      reason: "Security vulnerabilities detected",
      details: sprintState.security_issues || "High/Critical CVEs found",
    };
  }

  if (sprintState.deployment_failed) {
    return {
      type: "critical",
      reason: "Deployment failure",
      details:
        sprintState.deployment_error || "Production/Staging deployment crashed",
    };
  }

  // Fixable issues (CAN auto-retry in auto-mode)
  if (sprintState.tests_failed && !sprintState.ci_pipeline_failed) {
    return {
      type: "fixable",
      reason: "Test failures (not CI-related)",
      details: `${sprintState.tests_failed_count || 0} tests failing`,
      strategies: ["re-run-tests", "check-dependencies", "clear-cache"],
    };
  }

  if (sprintState.build_failed) {
    return {
      type: "fixable",
      reason: "Build failure",
      details: sprintState.build_error || "Build compilation/bundling failed",
      strategies: ["clear-cache", "reinstall-deps", "rebuild"],
    };
  }

  if (sprintState.dependencies_failed) {
    return {
      type: "fixable",
      reason: "Dependency installation failure",
      details: sprintState.dependency_error || "npm/pip/cargo install failed",
      strategies: ["clean-install", "clear-lockfile", "check-registry"],
    };
  }

  if (sprintState.infrastructure_issues) {
    return {
      type: "fixable",
      reason: "Infrastructure issues",
      details:
        sprintState.infra_error || "Docker/database/services unavailable",
      strategies: ["restart-services", "check-ports", "verify-env"],
    };
  }

  if (sprintState.type_check_failed) {
    return {
      type: "fixable",
      reason: "Type checking errors",
      details: sprintState.type_errors || "TypeScript/mypy errors",
      strategies: ["add-type-annotations", "fix-imports", "update-types"],
    };
  }

  // Unknown failure type - treat as critical by default for safety
  return {
    type: "unknown",
    reason: "Unclassified failure",
    details: sprintState.status_message || "Sprint failed for unknown reason",
  };
}
```

**Attempt auto-fix strategies:**

```javascript
/**
 * Attempt to automatically fix sprint failures using known strategies
 * @param {string} sprintId - Sprint identifier
 * @param {Object} failureClassification - Result from classifyFailure()
 * @returns {Promise<{success: boolean, strategy: string, attempts: number}>}
 */
async function attemptAutoFix(sprintId, failureClassification) {
  const { type, strategies } = failureClassification;

  if (type !== "fixable" || !strategies) {
    return { success: false, reason: "Not fixable or no strategies available" };
  }

  log(
    `🔄 Auto-fix: Attempting to fix ${sprintId} using ${strategies.length} strategies...`
  );

  for (let attempt = 1; attempt <= 3; attempt++) {
    for (const strategy of strategies) {
      log(`  Attempt ${attempt}/3: Trying strategy '${strategy}'...`);

      try {
        const result = await executeFixStrategy(sprintId, strategy);

        if (result.success) {
          log(`  ✅ Strategy '${strategy}' succeeded!`);

          // Verify sprint is now completed
          const newState = readYAML(
            `${EPIC_DIR}/sprints/${sprintId}/state.yaml`
          );
          if (newState.sprint.status === "completed") {
            log(`✅ Auto-fix successful: ${sprintId} now completed`);
            return { success: true, strategy, attempts: attempt };
          }
        }
      } catch (error) {
        log(`  ⚠️  Strategy '${strategy}' failed: ${error.message}`);
        continue; // Try next strategy
      }
    }

    // Wait before next retry (progressive delay)
    if (attempt < 3) {
      const delay = attempt * 5000; // 5s, 10s, 15s
      log(`  Waiting ${delay / 1000}s before next attempt...`);
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }

  log(
    `❌ Auto-fix failed: All ${strategies.length} strategies exhausted after 3 attempts`
  );
  return { success: false, reason: "All strategies failed", attempts: 3 };
}
```

**Execute fix strategy:**

```javascript
/**
 * Execute a specific fix strategy for a sprint
 * @param {string} sprintId - Sprint identifier
 * @param {string} strategy - Fix strategy name
 * @returns {Promise<{success: boolean, output: string}>}
 */
async function executeFixStrategy(sprintId, strategy) {
  const sprintDir = `${EPIC_DIR}/sprints/${sprintId}`;

  switch (strategy) {
    case "re-run-tests":
      log(`    Running tests again (may be flaky tests)...`);
      const testResult = await execCommand(`cd ${sprintDir} && npm test`, {
        timeout: 120000,
      });
      return { success: testResult.exitCode === 0, output: testResult.stdout };

    case "check-dependencies":
      log(`    Verifying all dependencies installed...`);
      const depsResult = await execCommand(`cd ${sprintDir} && npm list`, {
        timeout: 30000,
      });
      if (!depsResult.success) {
        log(`    Missing dependencies detected, installing...`);
        await execCommand(`cd ${sprintDir} && npm install`, {
          timeout: 120000,
        });
      }
      return { success: true };

    case "clear-cache":
      log(`    Clearing build/test caches...`);
      await execCommand(
        `cd ${sprintDir} && rm -rf .next .cache coverage node_modules/.cache`
      );
      await execCommand(`cd ${sprintDir} && npm run build`, {
        timeout: 180000,
      });
      return { success: true };

    case "clean-install":
      log(`    Performing clean npm install...`);
      await execCommand(`cd ${sprintDir} && npm cache clean --force`);
      await execCommand(
        `cd ${sprintDir} && rm -rf node_modules package-lock.json`
      );
      const installResult = await execCommand(
        `cd ${sprintDir} && npm install`,
        { timeout: 300000 }
      );
      return { success: installResult.exitCode === 0 };

    case "reinstall-deps":
      log(`    Reinstalling dependencies with --force...`);
      const forceResult = await execCommand(
        `cd ${sprintDir} && npm install --force`,
        { timeout: 120000 }
      );
      return { success: forceResult.exitCode === 0 };

    case "rebuild":
      log(`    Rebuilding from scratch...`);
      await execCommand(`cd ${sprintDir} && rm -rf dist build .next`);
      const buildResult = await execCommand(
        `cd ${sprintDir} && npm run build`,
        { timeout: 180000 }
      );
      return { success: buildResult.exitCode === 0 };

    case "restart-services":
      log(`    Restarting Docker services...`);
      await execCommand(`docker-compose down`, { timeout: 30000 });
      await execCommand(`docker-compose up -d`, { timeout: 120000 });
      await new Promise((resolve) => setTimeout(resolve, 10000)); // Wait for services to start
      return { success: true };

    case "check-ports":
      log(`    Checking for port conflicts...`);
      const portCheck = await execCommand(`lsof -ti:3000,5432,6379 || true`);
      if (portCheck.stdout.trim()) {
        log(`    Port conflicts detected, killing processes...`);
        await execCommand(`lsof -ti:3000,5432,6379 | xargs kill -9 || true`);
      }
      return { success: true };

    case "verify-env":
      log(`    Verifying environment variables...`);
      const envResult = await execCommand(
        `cd ${sprintDir} && node -e "console.log(process.env.NODE_ENV)"`
      );
      return { success: envResult.exitCode === 0 };

    default:
      log(`    ⚠️  Unknown strategy: ${strategy}`);
      return {
        success: false,
        output: `Strategy '${strategy}' not implemented`,
      };
  }
}
```

### Step 2.6: Create Sprint Worktrees (If Preference Enabled)

**Check worktree preference and create isolated worktrees for each sprint:**

```javascript
// Load worktree preferences
const worktreeAutoCreate = await execCommand(
  `bash .spec-flow/scripts/utils/load-preferences.sh --key "worktrees.auto_create" --default "true"`
);
const isInWorktree = await execCommand(
  `bash .spec-flow/scripts/bash/worktree-context.sh in-worktree && echo "true" || echo "false"`
);

// Store worktree paths for later use
const sprintWorktreePaths = {};

if (worktreeAutoCreate.stdout.trim() === "true" && isInWorktree.stdout.trim() === "false") {
  log("🌳 Creating isolated worktrees for each sprint...");

  for (const sprint of sprints) {
    const sprintSlug = `${metadata.epic_slug}-${sprint.id}`;
    const sprintBranch = `epic/${metadata.epic_slug}/${sprint.id}`;

    // Create worktree for this sprint
    const createResult = await execCommand(
      `bash .spec-flow/scripts/bash/worktree-context.sh create "epic" "${sprintSlug}" "${sprintBranch}"`
    );

    if (createResult.stdout.trim()) {
      const worktreePath = createResult.stdout.trim();
      sprintWorktreePaths[sprint.id] = worktreePath;

      // Update sprint state.yaml with worktree info
      const sprintStateFile = `${EPIC_DIR}/sprints/${sprint.id}/state.yaml`;
      await execCommand(
        `yq eval '.git.worktree_enabled = true' -i "${sprintStateFile}"`
      );
      await execCommand(
        `yq eval '.git.worktree_path = "${worktreePath}"' -i "${sprintStateFile}"`
      );

      log(`  ✅ ${sprint.id}: ${worktreePath}`);
    }
  }

  log(`🌳 Created ${Object.keys(sprintWorktreePaths).length} worktrees for parallel execution`);
} else {
  log("📁 Worktrees disabled or already in worktree - sprints will share main repository");
}

// Store for Task() agent prompts
global.SPRINT_WORKTREE_PATHS = sprintWorktreePaths;
```

**Benefits of sprint worktrees:**
- Each sprint has isolated git state (no staging conflicts)
- Parallel agents can commit without coordination
- Root orchestrator handles merges after completion
- Clean rollback per sprint if needed

---

### Step 2.75: Frontend Mockup Approval Gate (Optional)

**If epic has Frontend subsystem and mockups exist**, provide optional approval gate:

```javascript
const mockupsDir = `${EPIC_DIR}/mockups`;
const hasMockups =
  fs.existsSync(mockupsDir) &&
  fs.existsSync(`${mockupsDir}/epic-overview.html`);

if (hasMockups) {
  log("\n📐 Frontend blueprints detected");
  log(`   Location: ${mockupsDir}`);
  log(`   Open epic-overview.html in browser to review designs`);
  log("");

  // In auto-mode, notify and continue automatically
  if (global.AUTO_MODE) {
    log(
      "🤖 Auto-mode: Blueprints approved automatically, proceeding to implementation"
    );
  } else {
    // Interactive mode: Offer optional pause
    const shouldIterate = await AskUserQuestion({
      questions: [
        {
          question:
            "Would you like to iterate on blueprint designs before implementation?",
          header: "Blueprint Review",
          multiSelect: false,
          options: [
            {
              label: "No, continue",
              description:
                "Blueprints approved, proceed with TSX implementation",
            },
            {
              label: "Yes, pause",
              description: "Pause to edit HTML blueprints with Claude Code",
            },
          ],
        },
      ],
    });

    if (shouldIterate.answers["Blueprint Review"] === "Yes, pause") {
      log("\n⏸️  Pausing for blueprint iteration");
      log("   1. Edit HTML files in mockups/ directory");
      log("   2. Refresh browser to preview changes");
      log("   3. Use design tokens from tokens.css");
      log("   4. When ready, run /implement-epic continue");
      log("");
      throw new Error("Blueprint iteration requested - workflow paused");
    }
  }

  // Generate TSX conversion helpers
  log("📝 Extracting blueprint patterns for TSX conversion...");
  await Bash({
    command: "bash .spec-flow/scripts/bash/extract-blueprint-patterns.sh",
    description: "Extract Tailwind class patterns from blueprints",
  });

  // Optional: Check for common edge cases (skippable with --skip-validation)
  const skipValidation = "$ARGUMENTS".includes("--skip-validation");
  if (!skipValidation) {
    log("🔍 Generating edge case checklist...");
    await Bash({
      command: "bash .spec-flow/scripts/bash/check-conversion-edge-cases.sh",
      description: "Generate HTML → TSX conversion edge case checklist",
    });
  }

  log("✅ Blueprint review complete, proceeding to implementation");
  log("");
}
```

**Blueprint approval behavior**:

- **Auto-mode** (`--auto`): Notify and continue automatically
- **Interactive mode** (default): Optional pause to iterate
- **Validation** (default): Extract patterns + edge cases
- **Skip validation** (`--skip-validation`): Skip pattern extraction

---

### Step 2.8: Domain Memory Worker Pattern (v11.0)

**Initialize and use Domain Memory for atomic feature execution within sprints.**

When sprint-level domain-memory.yaml files exist, use the Worker pattern for isolated feature execution:

```javascript
// Check for sprint-level domain memory files
for (const sprint of sprints) {
  const sprintDir = `${EPIC_DIR}/sprints/${sprint.id}`;
  const domainMemoryFile = `${sprintDir}/domain-memory.yaml`;

  if (!fs.existsSync(domainMemoryFile)) {
    log(`📝 Initializing domain memory for Sprint ${sprint.id}...`);

    // Generate from tasks.md if it exists
    const tasksFile = `${sprintDir}/tasks.md`;
    if (fs.existsSync(tasksFile)) {
      await Bash({
        command: `.spec-flow/scripts/bash/domain-memory.sh generate-from-tasks ${sprintDir}`,
        description: `Generate domain memory for Sprint ${sprint.id}`
      });
    } else {
      await Bash({
        command: `.spec-flow/scripts/bash/domain-memory.sh init ${sprintDir}`,
        description: `Initialize domain memory for Sprint ${sprint.id}`
      });
    }
  }
}

log("✅ Sprint domain memory files ready");
```

**Worker-Based Sprint Execution:**

When domain memory is available, sprints use the Worker loop pattern:

```javascript
async function executeSprintWithWorkers(sprintDir, sprintId) {
  const domainMemoryFile = `${sprintDir}/domain-memory.yaml`;

  // Read domain memory to check remaining features
  let remaining = getUntestedOrFailingFeatures(domainMemoryFile);

  log(`📋 Sprint ${sprintId}: ${remaining.length} features to implement`);

  while (remaining.length > 0) {
    log(`\n── Spawning Worker for Sprint ${sprintId} ──\n`);

    // Spawn isolated Worker via Task tool
    // CRITICAL: Each Worker gets fresh context, no memory of previous runs
    const workerResult = await Task({
      subagent_type: "worker",  // Uses .claude/agents/domain/worker.md
      prompt: `
        Execute ONE feature from sprint domain memory:

        Sprint directory: ${sprintDir}
        Sprint ID: ${sprintId}
        Domain memory: ${domainMemoryFile}

        Boot-up ritual:
        1. READ domain-memory.yaml from disk
        2. RUN baseline tests (verify no regressions)
        3. PICK one failing/untested feature (highest priority)
        4. LOCK the feature
        5. IMPLEMENT that ONE feature
        6. RUN tests
        7. UPDATE domain-memory.yaml status
        8. COMMIT changes
        9. EXIT (even if more work remains)

        CRITICAL: Work on exactly ONE feature, then EXIT.
      `
    });

    log(`✅ Worker completed: ${workerResult.status}`);
    log(`   Feature: ${workerResult.feature_id}`);

    // Re-read domain memory to get updated state
    remaining = getUntestedOrFailingFeatures(domainMemoryFile);
    log(`   Remaining features: ${remaining.length}`);
  }

  log(`\n✅ Sprint ${sprintId} complete - all features passing`);
}
```

**Parallel Sprint Workers:**

For parallel layers, spawn Workers for multiple sprints in SINGLE message:

```javascript
async function executeParallelSprintsWithWorkers(layerSprints) {
  // CRITICAL: Single message with multiple Task calls for true parallelism
  const workerPromises = layerSprints.map(sprint => {
    const sprintDir = `${EPIC_DIR}/sprints/${sprint.id}`;

    return Task({
      subagent_type: "worker",
      run_in_background: true,  // Run in parallel
      prompt: `
        Execute ONE feature from sprint domain memory:
        Sprint directory: ${sprintDir}
        Sprint ID: ${sprint.id}
        Domain memory: ${sprintDir}/domain-memory.yaml

        [Same boot-up ritual as above]
      `
    });
  });

  // Wait for all Workers to complete
  const results = await Promise.all(workerPromises);

  // Check if any Workers found remaining work
  const sprintsWithRemainingWork = [];
  for (const sprint of layerSprints) {
    const remaining = getUntestedOrFailingFeatures(
      `${EPIC_DIR}/sprints/${sprint.id}/domain-memory.yaml`
    );
    if (remaining.length > 0) {
      sprintsWithRemainingWork.push(sprint.id);
    }
  }

  // If work remains, spawn more Workers
  if (sprintsWithRemainingWork.length > 0) {
    log(`🔄 ${sprintsWithRemainingWork.length} sprints have remaining work`);
    // Recursive call to continue Workers
  }
}
```

**Benefits of Worker Pattern for Epics:**

1. **True isolation**: Each Worker has fresh context, no cross-contamination
2. **Parallel sprint execution**: Workers for different sprints run simultaneously
3. **Observable progress**: domain-memory.yaml shows exact status at any point
4. **Automatic retry**: Failed features retried up to 3 times before blocking
5. **Resumable**: `/epic continue` picks up from last domain memory state

**Fallback to Agent Pattern:**

If domain-memory.yaml doesn't exist for a sprint, fall back to the traditional agent execution pattern (Step 3 below).

---

### Step 3: Execute Layers Sequentially

**For each layer, execute all sprints in parallel (if layer.parallelizable):**

```javascript
for (const layer of layers) {
  console.log(`\n========================================`);
  console.log(`Executing Layer ${layer.num}: ${layer.sprint_ids}`);
  console.log(`Parallelizable: ${layer.parallelizable}`);
  console.log(`Dependencies: ${layer.dependencies || "None"}`);
  console.log(`Rationale: ${layer.rationale}`);
  console.log(`========================================\n`);

  // Get sprints for this layer
  const layerSprints = layer.sprint_ids
    .split(",")
    .map((id) => sprints.find((s) => s.id === id));

  if (layer.parallelizable && layerSprints.length > 1) {
    // CRITICAL: Launch all sprints in SINGLE message with multiple Task tool calls
    await executeSprintsInParallel(layerSprints, layer.num);
  } else {
    // Sequential execution (dependencies require it)
    for (const sprint of layerSprints) {
      await executeSprintSequential(sprint, layer.num);
    }
  }

  // Verify layer completion before proceeding (with auto-retry in auto-mode)
  for (const sprint of layerSprints) {
    // CRITICAL: Verify sprint state.yaml exists (agents must create it)
    const sprintStateFile = `${EPIC_DIR}/sprints/${sprint.id}/state.yaml`;

    if (!fs.existsSync(sprintStateFile)) {
      log(
        `⚠️  WARNING: Sprint ${sprint.id} completed but state.yaml not found`
      );
      log(`   Agent may have forgotten to create state file`);
      log(`   Creating minimal fallback state.yaml...`);

      // Create minimal fallback state (agent should have done this)
      const fallbackState = {
        sprint: {
          id: sprint.id,
          status: "completed",
          completed_at: new Date().toISOString(),
          duration_hours: "unknown",
          note: "Auto-generated fallback - agent did not create state.yaml",
        },
        tasks: {
          total: "unknown",
          completed: "unknown",
          failed: 0,
        },
        tests: {
          total: "unknown",
          passed: "unknown",
          failed: 0,
          coverage_percent: "unknown",
        },
      };

      fs.writeFileSync(sprintStateFile, yaml.dump(fallbackState));
      log(`✅ Fallback state.yaml created for ${sprint.id}`);
    }

    const sprintStatus = checkSprintStatus(`${EPIC_DIR}/sprints/${sprint.id}`);

    if (sprintStatus !== "completed") {
      // Classify the failure to determine if auto-fix is possible
      const failureClassification = classifyFailure(sprint.id);

      log(`❌ Sprint ${sprint.id} failed: ${failureClassification.reason}`);
      log(`   Details: ${failureClassification.details}`);

      // In auto-mode with fixable issue, attempt auto-fix
      if (global.AUTO_MODE && failureClassification.type === "fixable") {
        log(`🔄 Auto-mode enabled - attempting auto-fix for ${sprint.id}...`);

        const autoFixResult = await attemptAutoFix(
          sprint.id,
          failureClassification
        );

        if (autoFixResult.success) {
          log(
            `✅ Auto-fix successful: ${sprint.id} recovered using '${autoFixResult.strategy}' (${autoFixResult.attempts} attempts)`
          );
          continue; // Proceed to next sprint
        } else {
          log(`❌ Auto-fix failed: All strategies exhausted for ${sprint.id}`);
          log(`   ${autoFixResult.reason}`);
        }
      }

      // Stop if: (1) Critical blocker OR (2) Auto-fix failed OR (3) Interactive mode
      if (failureClassification.type === "critical") {
        throw new Error(
          `❌ CRITICAL BLOCKER: Sprint ${sprint.id} failed with critical issue\n` +
            `   Reason: ${failureClassification.reason}\n` +
            `   Details: ${failureClassification.details}\n` +
            `   Action: Manual intervention required - cannot proceed to next layer`
        );
      } else {
        throw new Error(
          `❌ Sprint ${sprint.id} failed - cannot proceed to next layer\n` +
            `   Reason: ${failureClassification.reason}\n` +
            `   Details: ${failureClassification.details}\n` +
            `   ${
              global.AUTO_MODE
                ? "Auto-fix attempts exhausted"
                : "Manual fix required (not in auto-mode)"
            }`
        );
      }
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
- Frontend/UI sprints → `frontend-dev` agent
- Testing sprints → `test-architect` or `qa-test` agent
- Mixed/Integration sprints → `general-purpose` agent
- Infrastructure/DevOps → `general-purpose` agent

**Sprint Agent Prompt Template:**

````text
Execute Sprint {SPRINT_ID}: {SPRINT_NAME}

**Sprint Context:**
- Epic Directory: {EPIC_DIR}
- Sprint ID: {SPRINT_ID}
- Sprint Directory: {EPIC_DIR}/sprints/{SPRINT_ID}
- Tasks File: {EPIC_DIR}/sprints/{SPRINT_ID}/tasks.md
- Subsystems: {SUBSYSTEMS}
- Dependencies: {DEPENDENCIES} (from previous layers)

{IF SPRINT_WORKTREE_PATH}
**WORKTREE CONTEXT**
Path: {SPRINT_WORKTREE_PATH}

CRITICAL: Execute this as your FIRST action before any other commands:
```bash
cd "{SPRINT_WORKTREE_PATH}"
```

All paths are relative to this worktree.
Git commits stay LOCAL to this worktree's branch.
Do NOT merge or push - the orchestrator handles that after all sprints complete.
{ENDIF}

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
5. **Update sprint state.yaml** (CRITICAL - must happen after completion):
   ```yaml
   # {EPIC_DIR}/sprints/{SPRINT_ID}/state.yaml
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
````

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

**On Failure (auto-mode aware):**

**Auto-mode:**

- Classify failure (critical vs fixable)
- If fixable: Attempt 2-3 auto-fix retries
- If fixed: Continue automatically
- If critical or auto-fix exhausted: Stop and document

**Interactive mode:**

- Auto-rollback to last good commit
- Document blocker in sprint status with classification
- Do NOT proceed if critical
- User runs `/epic continue` after manual fix

````

### Step 5: Monitor Sprint Progress

**While sprints are executing:**

```javascript
// Agents execute in parallel
// Each agent updates its sprint's state.yaml

// Poll sprint status files
const sprintStatuses = layerSprints.map(s => ({
  id: s.id,
  status: readYAML(`${EPIC_DIR}/sprints/${s.id}/state.yaml`).status,
  progress: readYAML(`${EPIC_DIR}/sprints/${s.id}/state.yaml`).tasks_completed
}));

// Display progress
console.log(`Sprint Progress (Layer ${layerNum}):`);
for (const status of sprintStatuses) {
  console.log(`  ${status.id}: ${status.status} (${status.progress}% complete)`);
}
````

**Failure handling (with auto-retry in auto-mode):**

```javascript
// If any sprint fails, attempt auto-fix in auto-mode before blocking
const failedSprints = sprintStatuses.filter((s) => s.status === "failed");

if (failedSprints.length > 0) {
  log(
    `❌ ${
      failedSprints.length
    } sprint(s) failed in Layer ${layerNum}: ${failedSprints
      .map((s) => s.id)
      .join(", ")}`
  );

  // Try to auto-fix each failed sprint in auto-mode
  if (global.AUTO_MODE) {
    log(`🔄 Auto-mode enabled - attempting to recover failed sprints...`);

    for (const failedSprint of failedSprints) {
      const failureClassification = classifyFailure(failedSprint.id);

      log(`  Sprint ${failedSprint.id}: ${failureClassification.reason}`);

      if (failureClassification.type === "fixable") {
        const autoFixResult = await attemptAutoFix(
          failedSprint.id,
          failureClassification
        );

        if (autoFixResult.success) {
          log(
            `  ✅ ${failedSprint.id} recovered using '${autoFixResult.strategy}'`
          );
          // Remove from failedSprints list
          const index = failedSprints.indexOf(failedSprint);
          failedSprints.splice(index, 1);
        } else {
          log(`  ❌ ${failedSprint.id} could not be auto-fixed`);
        }
      } else if (failureClassification.type === "critical") {
        log(`  🛑 ${failedSprint.id} has CRITICAL blocker - cannot auto-fix`);
      }
    }

    // Re-check if any sprints still failed after auto-fix attempts
    if (failedSprints.length === 0) {
      log(`✅ All failed sprints recovered - Layer ${layerNum} can proceed`);
      return; // Continue to next layer
    }
  }

  // Still have failures - classify if critical or not
  const criticalFailures = failedSprints.filter((s) => {
    const classification = classifyFailure(s.id);
    return classification.type === "critical";
  });

  if (criticalFailures.length > 0) {
    throw new Error(
      `❌ CRITICAL BLOCKERS in Layer ${layerNum}: ${criticalFailures
        .map((s) => s.id)
        .join(", ")}\n` +
        `   These failures require manual intervention\n` +
        `   Cannot proceed to next layer`
    );
  } else {
    throw new Error(
      `❌ Sprint failures in Layer ${layerNum}: ${failedSprints
        .map((s) => s.id)
        .join(", ")}\n` +
        `   ${
          global.AUTO_MODE
            ? "Auto-fix attempts exhausted"
            : "Manual fixes required (not in auto-mode)"
        }\n` +
        `   Cannot proceed to next layer`
    );
  }
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
  contract_violations: [],
};

for (const sprint of layerSprints) {
  const sprintState = readYAML(`${EPIC_DIR}/sprints/${sprint.id}/state.yaml`);

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
  throw new Error(
    `Contract violations detected in Layer ${layerNum}: ${JSON.stringify(
      layerResults.contract_violations
    )}`
  );
}

log(`✅ Layer ${layerNum} Results:`);
log(`  Sprints: ${layerResults.sprints_completed}`);
log(`  Tasks: ${layerResults.total_tasks}`);

// **CRITICAL: Update epic-level state.yaml after layer completion**
const epicState = readYAML(`${EPIC_DIR}/state.yaml`);
epicState.layers.completed += 1;
epicState.sprints.completed += layerResults.sprints_completed;

writeYAML(`${EPIC_DIR}/state.yaml`, epicState);

log(
  `📊 Epic Progress: Layer ${epicState.layers.completed}/${epicState.layers.total} complete`
);
log(`  Tests: ${layerResults.total_tests}`);
log(`  Duration: ${layerResults.duration_hours}h`);
log(`  Contracts Locked: ${layerResults.contracts_locked.length}`);

// **CRITICAL: Commit layer completion atomically (per-layer commit)**
const SPRINT_IDS = layerSprints.map((s) => s.id).join(", ");
const LAYER_NUM = layerNum;

execSync(
  `git add epics/${EPIC_SLUG}/sprints/${layerSprints
    .map((s) => s.id)
    .join("/ epics/${EPIC_SLUG}/sprints/")}/`
);
execSync(`git add epics/${EPIC_SLUG}/state.yaml`);
execSync(`git commit -m "feat(epic): complete layer ${LAYER_NUM} (sprints ${SPRINT_IDS})

Duration: ${layerResults.duration_hours}h
Tasks: ${layerResults.total_tasks}
Tests: ${layerResults.total_tests} passing
Coverage: ${layerResults.coverage_percent || "N/A"}%
Contracts locked: ${layerResults.contracts_locked.length}

Layer ${LAYER_NUM} of ${epicState.layers.total} complete
Epic progress: ${epicState.sprints.completed}/${epicState.sprints.total} sprints

Next layer: ${LAYER_NUM + 1} (or optimization if final)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"`);

log(`✅ Layer ${LAYER_NUM} committed to git`);
```

**Alternative (recommended): Use git-workflow-enforcer skill:**

```javascript
// Invoke skill to auto-generate commit
await executeCommand(
  `/meta:enforce-git-commits --phase "epic-layer-${LAYER_NUM}"`
);
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

### Step 8: Commit Epic Audit Results (Final Summary Commit)

**Note:** Individual layer commits were already made in Step 6 after each layer completed. This final commit captures the audit results and epic summary.

```bash
# Commit audit results and final workflow state
git add epics/*/audit-report.xml
git add epics/*/state.yaml

git commit -m "feat(epic): complete ${epic_slug} with ${multiplier}x velocity

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
  ✅ state.yaml (updated)

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

   - All locked contracts exist as .yaml files in epics/\*/contracts/
   - No contract violations detected (count = 0)
   - Consumed contracts accessible to all consumers

3. **Sprint results consolidated**:

   - All sprint state.yaml files show status: completed
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
   grep "status:" epics/*/sprints/*/state.yaml
   ```

   All should show "completed"

3. **Verify contract violations are zero**:

   ```bash
   grep "contract_violations:" epics/*/sprints/*/state.yaml
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

**Never claim epic completion without reading all sprint state.yaml files.**
</verification>

<output>
**Files created/modified by this command:**

**Sprint implementations** (epics/NNN-slug/sprints/S\*/):

- tasks.md — All tasks marked as completed per sprint
- state.yaml — Sprint status, task counts, test results, contract info
- Source code files (varies by sprint subsystem)

**API Contracts** (epics/NNN-slug/contracts/):

- \*.yaml — OpenAPI 3.0 specifications for locked contracts
- Contract files enable parallel work by defining API boundaries

**Epic tracking** (epics/NNN-slug/):

- state.yaml — Epic-level status with layer completion
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
- Frontend sprints → `frontend-dev`
- Database sprints → `database-architect`
- Testing sprints → `test-architect` or `qa-test`
- Mixed sprints → `general-purpose`
- Infrastructure → `general-purpose`

### Contract Workflow

**Producer role** (locks contracts):

1. Read API design from plan.md
2. Generate OpenAPI 3.0 spec
3. Write to epics/_/contracts/_.yaml
4. Implement API following spec

**Consumer role** (consumes contracts):

1. Read locked contract from epics/_/contracts/_.yaml
2. Generate typed API client
3. Use client in implementation
4. Report violations if contract changes

### Error Handling

**Sprint failure (auto-mode aware):**

**In auto-mode:**

1. Classify failure type (critical vs fixable)
2. If fixable: Attempt auto-fix with 2-3 retries
   - Try strategies: re-run tests, clean install, rebuild, restart services
   - Progressive delays: 5s, 10s, 15s between attempts
3. If auto-fix succeeds: Continue to next sprint/layer
4. If auto-fix fails: Follow interactive mode flow below
5. If critical blocker: Skip auto-fix, stop immediately

**In interactive mode (or after auto-fix exhausted):**

1. Mark sprint as failed in state.yaml
2. Classify as critical or fixable for user guidance
3. Block layer progression
4. Present error with details and classification
5. User must manually fix and run `/epic continue`

**Critical blockers (stop always, even in auto-mode):**

- CI pipeline failures (GitHub Actions, GitLab CI)
- Security scan failures (High/Critical CVEs)
- Deployment failures (production/staging crashes)

**Fixable issues (auto-retry in auto-mode):**

- Test failures (not CI-related)
- Build failures (compilation/bundling)
- Dependency installation failures
- Infrastructure issues (Docker, ports, services)
- Type checking errors

**Contract violation:**

- Detect during consolidation
- Block layer progression
- Report violating sprint and expected vs actual
- Require fix before continuing
