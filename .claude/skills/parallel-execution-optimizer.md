---
name: parallel-execution-optimizer
description: "Identify and execute independent operations in parallel for 3-5x speedup. Auto-analyzes task dependencies, groups into batches, launches parallel Task() calls. Applies to: /optimize (5 checks), /ship pre-flight (5 checks), /design-variations (N screens), /implement (task batching). Auto-triggers when detecting multiple independent operations in a phase."
allowed-tools: Read, Bash
---

# Parallel Execution Optimizer: Workflow Throughput Accelerator

**Purpose**: Maximize workflow performance by executing independent operations concurrently instead of sequentially.

**Philosophy**: "Time is finite. Identify parallelism, batch intelligently, execute concurrently."

---

## When to Trigger

**Auto-invoke when detecting these patterns**:

### Multi-Check Phases
- "/optimize" (5 parallel checks: performance, security, accessibility, code review, migrations)
- "/ship pre-flight" (5 parallel checks: env vars, build, docker, CI config, dependencies)
- "/validate" (3 parallel checks: spec compliance, plan consistency, breaking changes)

### Multi-Screen Design
- "/design-variations" (N screens → N parallel agents)
- "/design-functional" (N screens → N parallel merge operations)

### Implementation Batching
- "/implement" with 10+ tasks (analyze dependencies → create batches → parallel execution)

### Research Operations
- "/roadmap brainstorm deep" (8-12 parallel web searches)
- "/plan research" (multiple parallel domain scans)

---

## Parallelization Patterns

### Pattern 1: Independent Checks (All-or-Nothing)

**Use case**: Multiple validation checks that don't depend on each other

**Example**: /optimize phase
```
Sequential (v2.2.0):
Performance → Security → Accessibility → Code Review → Migrations
   2min        3min         2min            5min           1min
Total: 13 minutes

Parallel (v2.3.0):
Performance ┐
Security    ├─→ All run simultaneously
Accessibility│
Code Review   │
Migrations    ┘
Total: 5 minutes (max of all durations)

Speedup: 2.6x (13min → 5min)
```

**Implementation**:
```typescript
// Launch all 5 checks in parallel with Task() calls
const results = await Promise.all([
  Task({
    subagent_type: "qa-tester",
    prompt: "Run performance benchmarks...",
    description: "Performance check"
  }),
  Task({
    subagent_type: "qa-tester",
    prompt: "Run security scan...",
    description: "Security check"
  }),
  Task({
    subagent_type: "qa-tester",
    prompt: "Run accessibility audit...",
    description: "Accessibility check"
  }),
  Task({
    subagent_type: "code-reviewer",
    prompt: "Review code quality...",
    description: "Code review"
  }),
  Task({
    subagent_type: "database",
    prompt: "Validate migrations...",
    description: "Migration check"
  })
]);

// Aggregate results
const critical = results.filter(r => r.severity === 'critical');
if (critical.length > 0) {
  // Block deployment
}
```

**Bash equivalent** (background jobs):
```bash
# Launch all checks in background
performance_check &
PID_PERF=$!

security_check &
PID_SEC=$!

accessibility_check &
PID_A11Y=$!

code_review_check &
PID_REVIEW=$!

migration_check &
PID_MIGRATE=$!

# Wait for all to complete
wait $PID_PERF $PID_SEC $PID_A11Y $PID_REVIEW $PID_MIGRATE

# Aggregate results from logs
# Block if any critical issues found
```

---

### Pattern 2: Batch Execution (Dependency-Aware)

**Use case**: Multiple tasks with dependencies (some parallel, some sequential)

**Example**: /implement phase with 20 tasks
```
Sequential (naive):
T1 → T2 → T3 → T4 → T5 → ... → T20
Total: 20 × 4min avg = 80 minutes

Parallel batching (intelligent):
Batch 1 (3 tasks in parallel): T1, T2, T3 → 4min
Batch 2 (5 tasks in parallel): T4-T8 → 8min
Batch 3 (7 tasks in parallel): T9-T15 → 10min
Batch 4 (5 tasks in parallel): T16-T20 → 8min
Total: 30 minutes

Speedup: 2.7x (80min → 30min)
```

**Dependency analysis algorithm**:
```python
def analyze_dependencies(tasks):
    """
    Analyze task dependencies and group into batches

    Returns: List of batches, where each batch contains independent tasks
    """
    # Build dependency graph
    graph = {}
    for task in tasks:
        graph[task.id] = {
            'depends_on': task.dependencies,
            'blocked_by': []
        }

    # Find independent tasks (no dependencies)
    batch_1 = [t for t in tasks if len(t.dependencies) == 0]

    # Iteratively find next batch (tasks whose dependencies are in previous batches)
    batches = [batch_1]
    completed = set(t.id for t in batch_1)

    remaining = [t for t in tasks if t not in batch_1]

    while remaining:
        # Tasks ready to run: all dependencies completed
        ready = [t for t in remaining if all(dep in completed for dep in t.dependencies)]

        if not ready:
            # Circular dependency or missing dependency
            raise ValueError(f"Circular dependency detected in tasks: {remaining}")

        batches.append(ready)
        completed.update(t.id for t in ready)
        remaining = [t for t in remaining if t not in ready]

    return batches

# Example output:
# Batch 1: [T001_DB_Schema, T002_API_Routes, T003_Frontend_Setup]  # Independent
# Batch 2: [T005_User_Model, T006_Session_Model, T007_Auth_Endpoints, T008_Login_Component]  # Depend on Batch 1
# Batch 3: [T010_Integration_Tests, T011_E2E_Tests]  # Depend on Batch 2
```

**Execution**:
```bash
# Batch 1: 3 independent tasks
execute_task T001 &
execute_task T002 &
execute_task T003 &
wait  # Wait for all batch 1 to complete

# Batch 2: 4 tasks (all depend on batch 1)
execute_task T005 &
execute_task T006 &
execute_task T007 &
execute_task T008 &
wait  # Wait for all batch 2 to complete

# Batch 3: 2 final tasks
execute_task T010 &
execute_task T011 &
wait
```

---

### Pattern 3: Parallel Research (Independent Queries)

**Use case**: Multiple web searches or file scans that don't depend on each other

**Example**: /roadmap brainstorm deep
```
Sequential:
Search 1 → Search 2 → Search 3 → ... → Search 8
Total: 8 × 15sec avg = 2 minutes

Parallel:
Search 1 ┐
Search 2 ├─→ All searches simultaneously
Search 3 │
...      │
Search 8 ┘
Total: 15 seconds (max of all durations)

Speedup: 8x (120sec → 15sec)
```

**Implementation**:
```bash
# Sequential (slow)
for topic in "${SEARCH_TOPICS[@]}"; do
  results=$(web_search "$topic")
  echo "$results" >> brainstorm-results.txt
done

# Parallel (fast)
for topic in "${SEARCH_TOPICS[@]}"; do
  (web_search "$topic" >> brainstorm-results-$topic.txt) &
done

wait  # Wait for all searches to complete

# Aggregate results
cat brainstorm-results-*.txt > brainstorm-results.txt
```

---

### Pattern 4: Parallel Screen Generation

**Use case**: Multiple UI screens with same generation process

**Example**: /design-variations with 5 screens
```
Sequential:
Screen 1 → Screen 2 → Screen 3 → Screen 4 → Screen 5
  5min       5min       5min       5min       5min
Total: 25 minutes

Parallel:
Screen 1 ┐
Screen 2 ├─→ All screens generated simultaneously
Screen 3 │
Screen 4 │
Screen 5 ┘
Total: 5 minutes (1x generation time)

Speedup: 5x (25min → 5min)
```

**Implementation**:
```typescript
// Get list of screens from spec
const screens = [
  'Dashboard',
  'Student List',
  'Progress Detail',
  'Settings',
  'Profile'
];

// Launch parallel agents for each screen
const agents = screens.map(screen =>
  Task({
    subagent_type: "frontend-shipper",
    prompt: `Generate 3 grayscale design variations for ${screen} screen...`,
    description: `Design ${screen} screen`
  })
);

// Wait for all to complete
const results = await Promise.all(agents);

// Aggregate designs into visuals/ directory
```

---

## Parallelization Decision Tree

```
Analyze operation
    |
    v
Are there multiple sub-operations?
    |-- No --> Execute sequentially (no parallelism)
    |
    v (Yes)
Do sub-operations have dependencies?
    |-- No --> Pattern 1: Independent Checks (all parallel)
    |
    v (Yes)
Can dependencies be grouped into batches?
    |-- No --> Execute sequentially (dependencies too complex)
    |
    v (Yes)
How many batches?
    |-- 2-3 batches --> Pattern 2: Batch Execution (dependency-aware)
    |-- 4+ batches --> Consider sequential (too much overhead)
    |
    v
Are sub-operations research/queries?
    |-- Yes --> Pattern 3: Parallel Research (web searches)
    |
    v (No)
Are sub-operations UI generations?
    |-- Yes --> Pattern 4: Parallel Screen Generation
    |
    v (No)
Default: Sequential execution (no clear pattern)
```

---

## Optimal Batch Sizing

### Batch Size Guidelines

| Parallelism Factor | Batch Size | Use Case |
|-------------------|------------|----------|
| Low (2-3 parallel) | 2-3 tasks | Small feature, simple dependencies |
| Medium (4-5 parallel) | 4-5 tasks | Standard feature, moderate complexity |
| High (6-10 parallel) | 6-10 tasks | Large feature, many independent tasks |
| Too high (10+ parallel) | Avoid | Risk of resource exhaustion, hard to debug |

### Why Optimal Batch Size Matters

**Too small** (1 task per batch):
- ❌ No parallelization benefit
- ❌ Overhead of batch management
- ❌ Sequential execution in disguise

**Too large** (10+ tasks per batch):
- ❌ Higher failure risk (more tasks = more points of failure)
- ❌ Harder debugging (which task failed?)
- ❌ Resource contention (CPU, memory, API rate limits)

**Optimal** (2-5 tasks per batch):
- ✅ Good parallelization benefit
- ✅ Manageable failure isolation
- ✅ Easy debugging
- ✅ Resource-efficient

---

## Parallelization Rules

### Rule 1: Same Domain, Different Entities → PARALLEL

**Example**: Creating multiple models
```
✅ PARALLEL:
- User model
- Post model
- Comment model

Reason: Same domain (database models), different entities (no shared files)
```

---

### Rule 2: Different Domains → PARALLEL

**Example**: Database + API + Frontend setup
```
✅ PARALLEL:
- Database schema (migrations)
- API route setup (FastAPI routes)
- Frontend component setup (React components)

Reason: Different domains (DB vs API vs UI), no file conflicts
```

---

### Rule 3: Sequential Dependencies → SEQUENTIAL

**Example**: Schema → Model → API → UI
```
❌ NOT PARALLEL:
- Database schema
- User model (depends on schema)
- Auth API endpoint (depends on model)
- Login component (depends on API)

Reason: Each task depends on previous (sequential chain)
```

**Batched alternative**:
```
✅ BATCHED:
Batch 1: Database schema
Batch 2: User model + Post model (both depend on schema)
Batch 3: Auth API + Post API (depend on models)
Batch 4: Login component + Feed component (depend on APIs)
```

---

### Rule 4: Shared Resources → SEQUENTIAL

**Example**: Modifying same file
```
❌ NOT PARALLEL:
- Add GET /users endpoint (routes/users.py)
- Add POST /users endpoint (routes/users.py)

Reason: Both modify same file (merge conflict risk)
```

**Alternative**:
```
✅ SEQUENTIAL or GROUPED:
Option A: Execute sequentially (safe)
Option B: Group into single task "Add user endpoints" (efficient)
```

---

## Integration with Workflow Phases

### /optimize Phase (5 Parallel Checks)

**Before** (sequential):
```bash
# Step 1: Performance benchmarks
run_performance_benchmarks

# Step 2: Security scan
run_security_scan

# Step 3: Accessibility audit
run_accessibility_audit

# Step 4: Code review
run_code_review

# Step 5: Migration validation
run_migration_validation

# Total: 13 minutes
```

**After** (parallel):
```bash
# Launch all 5 checks in parallel
run_performance_benchmarks > logs/perf.log 2>&1 &
PID_PERF=$!

run_security_scan > logs/security.log 2>&1 &
PID_SEC=$!

run_accessibility_audit > logs/a11y.log 2>&1 &
PID_A11Y=$!

run_code_review > logs/review.log 2>&1 &
PID_REVIEW=$!

run_migration_validation > logs/migrate.log 2>&1 &
PID_MIGRATE=$!

# Wait for all to complete
wait $PID_PERF $PID_SEC $PID_A11Y $PID_REVIEW $PID_MIGRATE

# Aggregate results
aggregate_optimization_results

# Total: 5 minutes (4-5x speedup)
```

---

### /ship Pre-flight (5 Parallel Checks)

**Before** (sequential):
```bash
check_env_vars       # 1min
build_frontend       # 3min
build_docker         # 4min
validate_ci_config   # 1min
check_dependencies   # 2min

# Total: 11 minutes
```

**After** (parallel):
```bash
check_env_vars &
build_frontend &
build_docker &
validate_ci_config &
check_dependencies &

wait

# Total: 4 minutes (3-4x speedup)
```

---

### /implement Phase (Intelligent Batching)

**Task list example**:
```
T001: Database schema (independent)
T002: API routes setup (independent)
T003: Frontend setup (independent)
T005: User model (depends on T001)
T006: Session model (depends on T001)
T007: Auth endpoints (depends on T002, T005)
T008: Login component (depends on T003)
T009: Register component (depends on T003)
T010: Integration tests (depends on T007)
T011: E2E tests (depends on T008, T009)
```

**Batch analysis**:
```
Batch 1 (3 tasks): T001, T002, T003  # All independent → PARALLEL
Batch 2 (4 tasks): T005, T006, T007, T008  # Mixed dependencies → PARALLEL (within constraints)
  - T005, T006 depend on T001 ✓
  - T007 depends on T002, T005 ✓
  - T008 depends on T003 ✓
Batch 3 (2 tasks): T010, T011  # Final tests → PARALLEL
```

**Execution**:
```bash
# Batch 1: 4 minutes (max of 3 tasks)
execute_parallel T001 T002 T003

# Batch 2: 8 minutes (max of 4 tasks)
execute_parallel T005 T006 T007 T008

# Batch 3: 6 minutes (max of 2 tasks)
execute_parallel T010 T011

# Total: 18 minutes
# Sequential would be: 11 tasks × 4min avg = 44 minutes
# Speedup: 2.4x
```

---

## Monitoring Parallel Execution

### Progress Tracking

**Challenge**: How to track progress of N parallel operations?

**Solution**: Shared state file + polling
```bash
# Shared state file
STATE_FILE="parallel-progress.json"

# Initialize state
cat > "$STATE_FILE" <<EOF
{
  "total": 5,
  "completed": 0,
  "operations": {
    "performance": "running",
    "security": "running",
    "accessibility": "running",
    "code_review": "running",
    "migrations": "running"
  }
}
EOF

# Each operation updates state on completion
update_progress() {
  local operation=$1
  local status=$2

  jq ".operations.$operation = \"$status\" | .completed += 1" "$STATE_FILE" > tmp.$$ && mv tmp.$$ "$STATE_FILE"
}

# Monitor progress (in separate process)
monitor_progress() {
  while true; do
    COMPLETED=$(jq -r '.completed' "$STATE_FILE")
    TOTAL=$(jq -r '.total' "$STATE_FILE")

    echo -ne "\rProgress: $COMPLETED/$TOTAL complete"

    if [ "$COMPLETED" = "$TOTAL" ]; then
      echo ""
      break
    fi

    sleep 1
  done
}

# Launch monitor in background
monitor_progress &

# Run parallel operations...
```

---

### Error Handling in Parallel Execution

**Challenge**: If 1 of 5 parallel operations fails, what happens?

**Strategy 1: Fail-fast** (stop all on first failure)
```bash
# Launch parallel operations
op1 & PID1=$!
op2 & PID2=$!
op3 & PID3=$!

# Monitor for failures
while kill -0 $PID1 $PID2 $PID3 2>/dev/null; do
  if ! kill -0 $PID1 2>/dev/null; then
    if ! wait $PID1; then
      echo "Operation 1 failed, killing others"
      kill $PID2 $PID3
      exit 1
    fi
  fi
  # Similar checks for PID2, PID3...
done
```

**Strategy 2: Complete-all** (let all finish, aggregate errors)
```bash
# Launch all operations
op1 & PID1=$!
op2 & PID2=$!
op3 & PID3=$!

# Wait for all to finish
wait $PID1; STATUS1=$?
wait $PID2; STATUS2=$?
wait $PID3; STATUS3=$?

# Aggregate failures
FAILURES=()
[ $STATUS1 -ne 0 ] && FAILURES+=("Operation 1")
[ $STATUS2 -ne 0 ] && FAILURES+=("Operation 2")
[ $STATUS3 -ne 0 ] && FAILURES+=("Operation 3")

if [ ${#FAILURES[@]} -gt 0 ]; then
  echo "Failed operations: ${FAILURES[*]}"
  exit 1
fi
```

**Recommended**: Use **Complete-all** strategy for validation checks (want full report), **Fail-fast** for implementation tasks (save time on failures).

---

## Performance Expectations

### Speedup Calculations

**Formula**: Speedup = Sequential Time / Parallel Time

**Examples**:

| Operation | Sequential | Parallel | Speedup |
|-----------|-----------|----------|---------|
| /optimize (5 checks) | 13min | 5min | 2.6x |
| /ship pre-flight (5 checks) | 11min | 4min | 2.8x |
| /design-variations (5 screens) | 25min | 5min | 5.0x |
| /implement (20 tasks, 4 batches) | 80min | 30min | 2.7x |
| /roadmap brainstorm (8 searches) | 2min | 15sec | 8.0x |

**Average speedup**: 3-5x for typical workflows

---

### Diminishing Returns

**Amd's Law**: Speedup limited by sequential portion

**Example**:
```
Workflow phases:
- Sequential setup: 5 minutes (can't parallelize)
- Parallel checks: 13 minutes → 5 minutes (parallelize)
- Sequential aggregation: 2 minutes (can't parallelize)

Total sequential: 20 minutes
Total parallel: 12 minutes
Speedup: 1.7x (not 2.6x due to sequential portions)
```

**Takeaway**: Focus parallelization efforts on longest-running operations for maximum impact.

---

## Quality Checklist

Before applying parallelization:

- [ ] **Dependencies analyzed** (independent operations identified)
- [ ] **Batch size optimal** (2-5 tasks per batch)
- [ ] **No shared resources** (avoid file conflicts)
- [ ] **Error handling strategy** (fail-fast or complete-all)
- [ ] **Progress monitoring** (shared state file)
- [ ] **Speedup estimated** (calculate expected improvement)
- [ ] **Fallback plan** (revert to sequential if issues)

---

## References

- **Workflow v2.3.0**: Auto-continue + parallel execution (CLAUDE.md)
- **Implement phase batching**: Sub-agent architecture (CLAUDE.md)
- **Scripts**:
  - `.spec-flow/scripts/bash/parallel-executor.sh` (future)
  - `.spec-flow/scripts/bash/dependency-analyzer.sh` (future)

---

_This skill optimizes workflow throughput by intelligent parallel execution of independent operations._
