---
name: implement-epic
description: Execute multiple sprints in parallel based on dependency graph from sprint-plan.md
argument-hint: "[epic-slug] [--auto-mode]"
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Task, Skill
version: 2.0
---

# /implement-epic - Parallel Sprint Execution

<objective>
Execute sprints from sprint-plan.md using parallel workers within dependency layers.

**Workflow position**: `epic → plan → tasks → implement-epic → optimize → ship`

**Key principles**:
- Layers execute sequentially (dependencies respected)
- Sprints within a layer run in parallel (single message, multiple Task calls)
- Workers implement one feature at a time (Domain Memory pattern)
- Errors classified and handled via error-recovery skill
</objective>

<context>
**User Input**: $ARGUMENTS

**Epic Directory**: !`ls -td epics/[0-9]*-* 2>/dev/null | head -1`

**Sprint Plan**: !`cat epics/*/sprint-plan.md 2>/dev/null | head -30`

**Sprint Count**: !`grep -c "^## Sprint S" epics/*/sprint-plan.md 2>/dev/null || echo "0"`

**Execution Layers**: !`bash .spec-flow/scripts/bash/sprint-utils.sh layers "$(ls -td epics/[0-9]*-* 2>/dev/null | head -1)" 2>/dev/null`

**Auto Mode**: !`echo "$ARGUMENTS" | grep -q "\-\-auto-mode" && echo "enabled" || echo "disabled"`
</context>

<process>

## Step 1: Validate Prerequisites

```bash
EPIC_DIR=$(ls -td epics/[0-9]*-* 2>/dev/null | head -1)

if [ -z "$EPIC_DIR" ]; then
    echo "ERROR: No epic directory found"
    echo "Run /epic first to create an epic"
    exit 1
fi

# Validate sprint directories exist
bash .spec-flow/scripts/bash/sprint-utils.sh validate "$EPIC_DIR"
```

Read sprint-plan.md to understand execution layers:
```bash
cat "$EPIC_DIR/sprint-plan.md"
```

## Step 2: Initialize Domain Memory (If Missing)

For each sprint without domain-memory.yaml, initialize it:

```bash
for sprint_dir in "$EPIC_DIR/sprints"/*/; do
    if [ ! -f "${sprint_dir}/domain-memory.yaml" ]; then
        SPRINT_ID=$(basename "$sprint_dir")
        echo "Initializing domain memory for $SPRINT_ID..."

        # Use initializer agent
        Task(subagent_type="initializer", prompt="
            Initialize domain memory for sprint.
            Sprint directory: ${sprint_dir}
            Tasks file: ${sprint_dir}/tasks.md
            Workflow type: epic-sprint
        ")
    fi
done
```

## Step 3: Execute Layers Sequentially

For each execution layer from sprint-plan.md:

### 3.1 Get Layer Sprints

```bash
# Get sprints for current layer
LAYER_INFO=$(bash .spec-flow/scripts/bash/sprint-utils.sh layers "$EPIC_DIR" | sed -n "${LAYER_NUM}p")
SPRINT_IDS=$(echo "$LAYER_INFO" | jq -r '.sprints')
PARALLELIZABLE=$(echo "$LAYER_INFO" | jq -r '.parallelizable')
```

### 3.2 Launch Sprint Workers

**CRITICAL: Launch all parallel sprints in SINGLE message with multiple Task calls.**

For each sprint in the layer, spawn a worker:

```
Task tool call:
  subagent_type: "worker"
  run_in_background: true  # Enable parallel execution
  description: "Implement Sprint ${SPRINT_ID}"
  prompt: |
    Implement features from sprint domain memory.

    Sprint directory: ${EPIC_DIR}/sprints/${SPRINT_ID}
    Domain memory: ${EPIC_DIR}/sprints/${SPRINT_ID}/domain-memory.yaml

    Boot-up ritual:
    1. READ domain-memory.yaml
    2. RUN baseline tests
    3. PICK one pending/failing feature
    4. LOCK the feature
    5. IMPLEMENT with TDD
    6. UPDATE domain-memory.yaml
    7. COMMIT changes
    8. EXIT

    Work on ONE feature, then exit. Orchestrator will spawn you again for next feature.
```

See `.claude/agents/ROUTING.md` for agent selection rules.

### 3.3 Wait for Layer Completion

After launching all sprints in a layer, wait for completion:

```bash
# Check all sprint statuses
for sprint_id in $SPRINT_IDS; do
    STATUS=$(bash .spec-flow/scripts/bash/sprint-utils.sh status "$EPIC_DIR/sprints/$sprint_id" | jq -r '.status')

    if [ "$STATUS" != "completed" ]; then
        # Check if more features remain
        REMAINING=$(yq eval '.features[] | select(.status != "completed") | .id' "$EPIC_DIR/sprints/$sprint_id/domain-memory.yaml" | wc -l)

        if [ "$REMAINING" -gt 0 ]; then
            echo "Sprint $sprint_id has $REMAINING features remaining - spawning more workers"
            # Continue worker loop for this sprint
        fi
    fi
done
```

### 3.4 Handle Failures

If any sprint fails, use error-recovery skill:

```
Skill("error-recovery")
```

Apply the failure classification from the skill:
- **CRITICAL failures**: Stop workflow, report to user
- **FIXABLE failures**: Attempt auto-fix strategies (if --auto-mode)

```bash
# Check for critical failures
if bash .spec-flow/scripts/bash/sprint-utils.sh has-critical "$EPIC_DIR/sprints/$SPRINT_ID"; then
    echo "CRITICAL failure in $SPRINT_ID - stopping workflow"
    echo "Run /workflow repair to diagnose and fix"
    exit 1
fi
```

### 3.5 Consolidate Layer Results

```bash
LAYER_RESULTS=$(bash .spec-flow/scripts/bash/sprint-utils.sh consolidate "$EPIC_DIR" "$LAYER_NUM")
echo "$LAYER_RESULTS" | jq .

# Verify all sprints succeeded
ALL_SUCCEEDED=$(echo "$LAYER_RESULTS" | jq -r '.all_succeeded')
if [ "$ALL_SUCCEEDED" != "true" ]; then
    FAILED=$(echo "$LAYER_RESULTS" | jq -r '.failed_sprints')
    echo "Layer $LAYER_NUM failed: $FAILED"
    exit 1
fi
```

### 3.6 Proceed to Next Layer

Only after ALL sprints in current layer complete successfully, move to next layer.

## Step 4: Verify Contract Compliance

```bash
bash .spec-flow/scripts/bash/sprint-utils.sh check-contracts "$EPIC_DIR"

if [ $? -ne 0 ]; then
    echo "Contract violations detected - cannot proceed"
    echo "Fix contract mismatches and run /epic continue"
    exit 1
fi
```

## Step 5: Update Epic State

```bash
# Mark implementation complete
yq eval '.phase = "optimize"' -i "$EPIC_DIR/state.yaml"
yq eval '.implementation.status = "completed"' -i "$EPIC_DIR/state.yaml"
yq eval '.implementation.completed_at = "'$(date -Iseconds)'"' -i "$EPIC_DIR/state.yaml"
```

## Step 6: Trigger Workflow Audit

```bash
echo "Implementation complete - triggering workflow audit..."
```

Run `/audit-workflow` to analyze effectiveness and capture velocity metrics.

## Step 7: Present Summary

```
═══════════════════════════════════════════════════════════════
✅ EPIC IMPLEMENTATION COMPLETE
═══════════════════════════════════════════════════════════════

Epic: [slug]
Sprints Completed: [count]
Layers Executed: [count]

Sprint Results:
  S01: ✅ [tasks] tasks, [tests] tests
  S02: ✅ [tasks] tasks, [tests] tests
  ...

Contract Compliance: ✅ 0 violations

Next: /optimize (quality gates)

═══════════════════════════════════════════════════════════════
```

</process>

<worker_loop>
## Worker Loop Pattern

Each sprint uses the Domain Memory worker loop:

```
While sprint has pending/failing features:
    1. Spawn worker agent
    2. Worker reads domain-memory.yaml
    3. Worker picks ONE feature
    4. Worker implements + tests + commits
    5. Worker updates domain-memory.yaml
    6. Worker exits
    7. Loop back to step 1
```

This ensures:
- Fresh context for each feature (no context overflow)
- Observable progress (domain-memory.yaml updated on disk)
- Resumable at any point (/epic continue)
- Atomic commits per feature
</worker_loop>

<error_handling>
## Error Handling

Load error-recovery skill for failure classification:

```
Skill("error-recovery")
```

**Critical failures** (stop immediately):
- CI pipeline failures
- Security scan failures
- Deployment failures
- Contract violations > 0

**Fixable failures** (auto-retry in --auto-mode):
- Test failures (re-run, check deps)
- Build failures (clear cache, rebuild)
- Infrastructure issues (restart services)

If auto-fix fails after 3 attempts, escalate to user.

See `.claude/skills/error-recovery/SKILL.md` for full classification and strategies.
</error_handling>

<anti_hallucination>
## Anti-Hallucination Rules

1. **Read before claiming** - Always read state.yaml/domain-memory.yaml before reporting status
2. **Verify artifacts** - Check files exist after agents claim creation
3. **Use utilities** - Call sprint-utils.sh for status checks, don't guess
4. **Single message parallelism** - Launch parallel tasks in ONE message, not separate
5. **Quote actual data** - Report real numbers from state files, don't estimate
</anti_hallucination>

<success_criteria>
Implementation complete when:

- [ ] All sprints show status: completed in state.yaml
- [ ] All features show status: completed in domain-memory.yaml
- [ ] Contract violations = 0
- [ ] Epic state.yaml phase updated to "optimize"
- [ ] Git commits made for each feature
</success_criteria>

<references>
**Agent Routing**: `.claude/agents/ROUTING.md`
**Error Recovery**: `.claude/skills/error-recovery/SKILL.md`
**Sprint Utilities**: `.spec-flow/scripts/bash/sprint-utils.sh`
**Worker Agent**: `.claude/agents/domain/worker.md`
**State Recovery**: `/workflow repair`
</references>
