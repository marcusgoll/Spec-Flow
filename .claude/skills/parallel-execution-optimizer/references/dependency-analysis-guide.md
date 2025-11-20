# Dependency Analysis Guide

This reference explains how to build dependency graphs, detect hidden dependencies, and handle edge cases in parallel execution optimization.

## Building Dependency Graphs

A dependency graph maps relationships between operations to identify which can run in parallel and which must run sequentially.

### Step 1: List All Operations

Enumerate every operation in the phase.

Example (/optimize):
1. Security scan
2. Performance benchmarking
3. Accessibility audit
4. Type safety validation
5. Dependency audit
6. Generate optimization report

### Step 2: Identify Dependencies

For each operation, ask:
- Does this operation **read** output from another operation?
- Does this operation **modify** state that another operation depends on?
- Does this operation **require** another operation to complete first?

Example analysis:
1. Security scan → No dependencies (reads codebase)
2. Performance benchmarking → No dependencies (reads codebase, runs tests)
3. Accessibility audit → No dependencies (reads UI components)
4. Type safety validation → No dependencies (reads TypeScript files)
5. Dependency audit → No dependencies (reads package.json)
6. Generate optimization report → **Depends on 1-5** (aggregates their outputs)

### Step 3: Assign to Layers

Group operations by dependency depth:

- **Layer 0**: Operations with zero dependencies
- **Layer 1**: Operations depending only on Layer 0
- **Layer 2**: Operations depending on Layer 0 or 1
- Continue...

Example:
```
Layer 0 (5 operations):
  - Security scan
  - Performance benchmarking
  - Accessibility audit
  - Type safety validation
  - Dependency audit

Layer 1 (1 operation):
  - Generate optimization report (needs all Layer 0 results)
```

### Step 4: Verify Independence Within Layers

Within each layer, verify operations are truly independent:

**Check for shared resources**:
- Do any operations write to the same files?
- Do any operations modify the same git branch/database?
- Do any operations compete for limited resources?

**Check for hidden dependencies**:
- Does operation A's side effect impact operation B?
- Are operations order-dependent (must run in sequence)?

If any operations within a layer are dependent, move one to a later layer.

## Types of Dependencies

### 1. Data Dependencies (Write-After-Read)

Operation B reads data that Operation A writes.

**Example**:
```
Operation A: Generate User model code
Operation B: Write tests for User model
```

B depends on A because it needs the generated code.

**Graph**:
```
Layer 0: Operation A
Layer 1: Operation B (depends on A)
```

### 2. Resource Dependencies (Write-After-Write)

Both operations write to the same resource (file, database, etc.).

**Example**:
```
Operation A: Update package.json (add lodash)
Operation B: Update package.json (add axios)
```

A and B cannot run in parallel due to race condition on package.json.

**Solution**: Sequence them or batch the changes into a single operation.

**Graph**:
```
Layer 0: Operation A
Layer 1: Operation B (must wait for A)
```

### 3. Temporal Dependencies (Must-Happen-Before)

Operation B logically requires Operation A to complete, even if no data flows between them.

**Example**:
```
Operation A: Create database tables
Operation B: Run migrations on tables
```

B cannot run before A, even though they touch different migration files.

**Graph**:
```
Layer 0: Operation A
Layer 1: Operation B (temporal dependency)
```

### 4. Side Effect Dependencies

Operation A's side effects impact Operation B's behavior.

**Example**:
```
Operation A: Install npm packages
Operation B: Run build (needs packages)
```

B depends on A's side effect (node_modules/ populated).

**Graph**:
```
Layer 0: Operation A
Layer 1: Operation B (side effect dependency)
```

## Detecting Hidden Dependencies

Some dependencies are subtle and easy to miss.

### Shared State

**Symptom**: Operations appear independent but both modify shared state.

**Example**:
```
Operation A: Update user profile in database
Operation B: Send email notification about profile update
```

B depends on A's database write completing, even if they seem logically separate.

**Detection**:
- Review all database writes
- Check for shared file modifications
- Identify operations touching same git branch

**Solution**: Sequence operations or use transactional semantics.

### Implicit Ordering

**Symptom**: Operations can technically run in any order, but produce different results.

**Example**:
```
Operation A: Append "foo" to log file
Operation B: Append "bar" to log file
```

If run in parallel, log file might contain "foobar" or "barfoo" non-deterministically.

**Detection**:
- Look for append operations on shared files
- Check for operations with non-commutative side effects
- Identify timestamp-dependent operations

**Solution**: Sequence operations or use atomic operations.

### Resource Contention

**Symptom**: Operations are logically independent but compete for limited resources.

**Example**:
```
Operation A: Build Docker image (CPU-intensive)
Operation B: Run integration tests (CPU-intensive)
Operation C: Compile TypeScript (CPU-intensive)
```

All three can run in parallel logically, but may exhaust CPU if run simultaneously.

**Detection**:
- Estimate resource usage for each operation
- Check available system resources (CPU cores, RAM, disk I/O)
- Monitor actual resource usage during execution

**Solution**: Limit batch size to avoid contention (e.g., 2-3 CPU-intensive operations at once).

### Cascading Failures

**Symptom**: One operation failing causes others to produce incorrect results.

**Example**:
```
Operation A: Fetch API schema from service
Operation B: Generate client code based on schema
Operation C: Write tests for generated client
```

If A fails (service down), B and C proceed with stale/missing schema, producing incorrect code and tests.

**Detection**:
- Identify operations that fail silently (don't throw errors)
- Check for operations using cached/default data when source unavailable
- Look for operations that "succeed" with partial results

**Solution**: Add explicit dependency (A → B → C) or validate outputs before proceeding.

## Edge Cases

### Idempotent vs Non-Idempotent Operations

**Idempotent**: Running operation multiple times produces same result.
**Non-idempotent**: Running operation multiple times produces different results.

**Example (idempotent)**:
```
Operation: Set user.status = "active" in database
```

Running twice has same effect as running once.

**Example (non-idempotent)**:
```
Operation: Increment user.login_count in database
```

Running twice increments by 2, not 1.

**Parallel execution impact**:
- Idempotent operations are **safe** to retry on failure
- Non-idempotent operations **must not** be retried without rollback

### Commutative vs Non-Commutative Operations

**Commutative**: Order doesn't matter (A then B = B then A).
**Non-commutative**: Order matters (A then B ≠ B then A).

**Example (commutative)**:
```
Operation A: Lint JavaScript files
Operation B: Lint CSS files
```

Running A then B produces same result as B then A.

**Example (non-commutative)**:
```
Operation A: Create database table
Operation B: Add column to table
```

Running A then B works. Running B then A fails (table doesn't exist).

**Parallel execution impact**:
- Commutative operations are **safe** to parallelize
- Non-commutative operations **must be sequenced**

### Transitive Dependencies

**Definition**: If A depends on B, and B depends on C, then A depends on C (transitively).

**Example**:
```
C: Create database schema
B: Run migrations (depends on C)
A: Seed test data (depends on B)
```

A transitively depends on C, even if not directly.

**Graph**:
```
Layer 0: C
Layer 1: B (depends on C)
Layer 2: A (depends on B, transitively depends on C)
```

**Detection**: Build full dependency chain for each operation.

**Impact**: When parallelizing, must respect transitive dependencies (A cannot run until C completes).

## Practical Examples

### Example 1: /optimize Phase

**Operations**:
1. Security scan (reads src/)
2. Performance benchmark (reads src/, runs tests)
3. Accessibility audit (reads src/components/)
4. Type check (reads src/, runs tsc)
5. Dependency audit (reads package.json)
6. Generate report (reads outputs from 1-5)

**Dependency analysis**:
- 1-5: No dependencies (all read-only, disjoint or shared read-only access)
- 6: Depends on 1-5 (reads their outputs)

**Graph**:
```
Layer 0: 1, 2, 3, 4, 5 (parallel - 5 operations)
Layer 1: 6 (sequential - 1 operation)
```

**Execution**:
- Batch 1: Launch operations 1-5 in single message (parallel)
- Batch 2: Launch operation 6 after Batch 1 completes

**Time**:
- Sequential: 3+4+3+2+2+1 = 15 minutes
- Parallel: max(3,4,3,2,2) + 1 = 5 minutes
- **Speedup**: 3x

### Example 2: /implement Phase with Task Dependencies

**Operations** (tasks):
```
T001: Create User model
T002: Create Product model
T003: Create Order model
T004: User CRUD endpoints (needs T001)
T005: Product CRUD endpoints (needs T002)
T006: Order CRUD endpoints (needs T003)
T007: User-Product relationship (needs T001, T002)
T008: User tests (needs T001, T004)
T009: Product tests (needs T002, T005)
T010: Integration tests (needs T004, T005, T006)
```

**Dependency analysis**:
- T001, T002, T003: No dependencies
- T004: Depends on T001
- T005: Depends on T002
- T006: Depends on T003
- T007: Depends on T001, T002
- T008: Depends on T001, T004
- T009: Depends on T002, T005
- T010: Depends on T004, T005, T006

**Graph**:
```
Layer 0: T001, T002, T003 (parallel - 3 tasks)
Layer 1: T004, T005, T006 (parallel - 3 tasks, depend on Layer 0)
Layer 2: T007, T008, T009 (parallel - 3 tasks, depend on Layer 0-1)
Layer 3: T010 (sequential - 1 task, depends on Layer 1)
```

**Execution**:
- Batch 1: T001, T002, T003 (parallel)
- Batch 2: T004, T005, T006 (parallel, wait for Batch 1)
- Batch 3: T007, T008, T009 (parallel, wait for Batch 2)
- Batch 4: T010 (sequential, wait for Batch 3)

**Time**:
- Sequential: 10 tasks × 20 min = 200 minutes
- Parallel: 4 batches × 25 min = 100 minutes
- **Speedup**: 2x

## Summary

**Building dependency graphs**:
1. List all operations
2. Identify dependencies (data, resource, temporal, side effect)
3. Assign to layers (Layer 0 = no deps, Layer N depends on Layer 0..N-1)
4. Verify independence within layers

**Detecting hidden dependencies**:
- Shared state (database writes, file modifications)
- Implicit ordering (append operations, timestamps)
- Resource contention (CPU, memory, I/O)
- Cascading failures (silent failures, partial results)

**Edge cases**:
- Idempotent vs non-idempotent (retry safety)
- Commutative vs non-commutative (order independence)
- Transitive dependencies (A→B→C means A depends on C)

**Key principle**: When in doubt, sequence operations. Parallelizing dependent operations causes race conditions and incorrect results. Always build the dependency graph first.
