# Execution Patterns

This reference provides detailed examples of correct and incorrect parallel execution patterns.

## Core Principle

**Parallel execution requires sending a SINGLE message with MULTIPLE tool calls.**

Multiple messages = sequential execution (each waits for previous)
Single message with multiple tool calls = parallel execution (all run concurrently)

## Correct Pattern: Single Message, Multiple Tools

```
Message 1:
  Tool call 1: Task(security-sentry, "Scan for auth vulnerabilities")
  Tool call 2: Task(performance-profiler, "Benchmark API endpoints")
  Tool call 3: Task(accessibility-auditor, "WCAG 2.1 AA audit")
```

All three agents launch simultaneously and run in parallel.

## Incorrect Pattern: Multiple Messages

```
Message 1:
  Tool call 1: Task(security-sentry, "Scan for auth vulnerabilities")

Message 2:
  Tool call 2: Task(performance-profiler, "Benchmark API endpoints")

Message 3:
  Tool call 3: Task(accessibility-auditor, "WCAG 2.1 AA audit")
```

These run sequentially because Message 2 waits for Message 1 to complete, Message 3 waits for Message 2, etc.

## Message Structure for Parallel Execution

Each tool call in the parallel batch must:

1. **Be complete**: Include all required parameters (subagent_type, description, prompt)
2. **Be independent**: Not reference outputs from other parallel operations
3. **Have full context**: Each agent receives all information it needs in its prompt
4. **Be self-contained**: No placeholders or "to be filled in later" values

### Example: /optimize Phase Parallelization

**Correct** (5 operations in single message):

```
Message:
  Task(
    subagent_type: "security-sentry",
    description: "Security audit",
    prompt: "Audit the authentication implementation in src/auth/ for vulnerabilities. Check for: SQL injection, XSS, CSRF, secrets in code, weak password hashing."
  )

  Task(
    subagent_type: "performance-profiler",
    description: "Performance benchmarking",
    prompt: "Benchmark API endpoints in src/api/. Measure p50/p95 latency. Identify N+1 queries, missing indexes, slow operations. Target: <200ms p50, <500ms p95."
  )

  Task(
    subagent_type: "accessibility-auditor",
    description: "Accessibility audit",
    prompt: "Audit UI components in src/components/ for WCAG 2.1 AA compliance. Check keyboard navigation, ARIA labels, color contrast, screen reader compatibility."
  )

  Task(
    subagent_type: "type-enforcer",
    description: "Type safety validation",
    prompt: "Scan TypeScript files for type safety violations. Check for: implicit any, unsafe casts, missing null checks, untyped external APIs."
  )

  Task(
    subagent_type: "dependency-curator",
    description: "Dependency audit",
    prompt: "Audit package.json dependencies. Run npm audit. Check for: critical vulnerabilities, outdated packages, duplicate dependencies, unused packages."
  )
```

All 5 agents launch and run concurrently. Total time = longest operation (typically performance-profiler at ~4 minutes).

**Incorrect** (same operations, but sequential):

```
Message 1:
  Task(security-sentry, ...)

Message 2:
  Task(performance-profiler, ...)

Message 3:
  Task(accessibility-auditor, ...)

Message 4:
  Task(type-enforcer, ...)

Message 5:
  Task(dependency-curator, ...)
```

These run one-by-one. Total time = sum of all operations (~15 minutes).

## Handling Tool Call Failures

When running parallel tool calls, some may fail while others succeed.

### Failure Types

1. **Agent error**: Agent crashes or times out
2. **Blocking issue found**: Agent detects critical problem (e.g., security vulnerability)
3. **Dependency missing**: Agent needs output from another operation
4. **Resource contention**: System runs out of memory/CPU

### Failure Handling Strategy

After parallel batch completes:

1. **Collect results**: Gather outputs from all successful operations
2. **Identify failures**: Determine which operations failed and why
3. **Categorize failures**:
   - **Blocking**: Critical issues that halt pipeline (security vulnerability)
   - **Non-blocking**: Warnings that allow continuation (minor performance issue)
   - **Retryable**: Transient failures (timeout, resource contention)
4. **Decide action**:
   - If blocking failure: Halt workflow, report to user, don't proceed
   - If non-blocking failure: Log warning, continue with next layer
   - If retryable failure: Retry failed operations individually

### Example: Security Vulnerability Blocks Pipeline

```
Batch 1 results:
  ✅ security-sentry: CRITICAL - SQL injection in user login endpoint
  ✅ performance-profiler: OK - All benchmarks passed
  ✅ accessibility-auditor: OK - WCAG 2.1 AA compliant
  ✅ type-enforcer: OK - No type violations
  ✅ dependency-curator: WARNING - 2 outdated packages

Decision: HALT - Critical security issue must be fixed before deployment
Action: Report findings, do not proceed to next phase
```

### Example: Minor Issues Allow Continuation

```
Batch 1 results:
  ✅ security-sentry: OK - No vulnerabilities
  ✅ performance-profiler: WARNING - One endpoint at 250ms (target 200ms)
  ✅ accessibility-auditor: OK - WCAG 2.1 AA compliant
  ✅ type-enforcer: OK - No type violations
  ✅ dependency-curator: WARNING - 2 outdated packages

Decision: CONTINUE - Warnings logged, no blocking issues
Action: Document warnings in optimization-report.md, proceed to next phase
```

## Batching Across Layers

When operations have dependencies, group into layers and execute layer-by-layer.

### Example: /implement Phase with Dependencies

**Task dependency graph**:
```
T001 (User model) → no deps
T002 (Product model) → no deps
T003 (User endpoints) → depends on T001
T004 (Product endpoints) → depends on T002
T005 (User tests) → depends on T001, T003
T006 (Product tests) → depends on T002, T004
```

**Execution plan** (3 batches):

**Batch 1** (Layer 0 - no dependencies):
```
Message 1:
  Task(implement-task, "T001: Create User model")
  Task(implement-task, "T002: Create Product model")
```

Wait for Batch 1 to complete.

**Batch 2** (Layer 1 - depends on Layer 0):
```
Message 2:
  Task(implement-task, "T003: User CRUD endpoints (uses T001)")
  Task(implement-task, "T004: Product CRUD endpoints (uses T002)")
```

Wait for Batch 2 to complete.

**Batch 3** (Layer 2 - depends on Layer 1):
```
Message 3:
  Task(implement-task, "T005: User tests (uses T001, T003)")
  Task(implement-task, "T006: Product tests (uses T002, T004)")
```

**Time savings**:
- Sequential: 6 tasks × 20 min = 120 minutes
- Parallel (3 batches): 3 batches × 25 min = 75 minutes
- **Speedup**: 1.6x

## Optimal Batch Sizes

**Too small** (1 operation per batch):
- No parallelism benefit
- Sequential execution in disguise

**Too large** (20 operations per batch):
- Resource exhaustion (memory, CPU)
- Difficult to debug failures
- Overwhelming system

**Optimal** (3-8 operations per batch):
- Balanced parallelism
- Manageable resource usage
- Easy to identify failures
- Good speedup without overwhelming system

### Heuristics

- **3-5 operations**: Ideal for most cases
- **6-8 operations**: Maximum for complex operations (agents running 5+ minutes)
- **1-2 operations**: Only when operations are heavy (10+ minute runtime each)

If you have 20 independent operations:
- **Don't do**: Single batch with 20 operations
- **Do**: 4 batches of 5 operations each

## Monitoring Parallel Execution

While operations run in parallel, you cannot see real-time progress. Plan for this:

1. **Give clear descriptions**: Each tool call should have descriptive `description` parameter
2. **Set expectations**: Tell user "Launching 5 quality checks in parallel, will take ~5 minutes"
3. **Handle timeouts**: Some agents may take longer than expected
4. **Aggregate results clearly**: After batch completes, summarize findings concisely

## Summary

**DO**:
- Send single message with multiple tool calls for parallel execution
- Ensure each tool call is complete and independent
- Group operations into layers based on dependencies
- Keep batches to 3-8 operations
- Handle failures gracefully (blocking vs non-blocking)

**DON'T**:
- Send multiple messages thinking they'll run in parallel
- Use placeholders or forward references in tool calls
- Launch 20+ operations in single batch
- Parallelize operations with dependencies
- Ignore failures (always check results before proceeding)
