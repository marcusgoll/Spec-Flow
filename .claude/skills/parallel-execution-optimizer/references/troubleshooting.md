# Troubleshooting Parallel Execution

Common issues when applying parallel execution optimization and how to resolve them.

## Performance Not Improving

### Symptom
Parallel execution takes same time (or longer) than sequential execution.

### Possible Causes

**1. Operations too small**

Each operation takes <1 minute, so parallel coordination overhead exceeds savings.

**Solution**: Only parallelize operations taking ≥1 minute each.

**Example**:
```
Bad: Parallelize reading 3 small files (5 seconds each)
Good: Parallelize 3 quality checks (3-5 minutes each)
```

**2. Resource contention**

All operations compete for same resource (CPU, disk I/O, network).

**Solution**: Reduce batch size or sequence operations.

**Example**:
```
Bad: Launch 5 CPU-intensive operations in parallel on 2-core machine
Good: Launch 2 operations at a time across 3 batches
```

**3. Operations not actually independent**

Hidden dependency forces sequential execution despite parallel structure.

**Solution**: Review dependency graph, identify hidden dependencies, sequence operations.

**Example**:
```
Bad:
  Batch 1: Generate code, Write tests (tests need generated code)
Good:
  Batch 1: Generate code
  Batch 2: Write tests
```

**4. Longest operation dominates**

One operation takes 10 minutes, others take 1 minute. Total time = 10 minutes regardless.

**Solution**: Break down long operation into smaller parallelizable pieces, or accept limited speedup.

**Example**:
```
Sequential: A(10m) + B(1m) + C(1m) = 12 minutes
Parallel: max(10m, 1m, 1m) = 10 minutes
Speedup: Only 1.2x (not worth complexity)
```

**5. System resources exhausted**

Too many parallel operations exhaust RAM/CPU, slowing all operations.

**Solution**: Reduce batch size from 10 to 3-5 operations.

## Race Conditions

### Symptom
Operations fail or produce inconsistent results when run in parallel, but succeed when run sequentially.

### Possible Causes

**1. Shared file writes**

Both operations write to same file, causing corruption.

**Solution**: Sequence operations or use atomic file operations.

**Example**:
```
Bad:
  Parallel: Update package.json (add lodash), Update package.json (add axios)
Good:
  Sequential: Update package.json (add both packages in single operation)
```

**2. Database race condition**

Both operations update same database record.

**Solution**: Use database transactions or sequence operations.

**Example**:
```
Bad:
  Parallel: Set user.status="active", Increment user.login_count
Good:
  Sequential: Update user (set status, increment count) in transaction
```

**3. Git conflicts**

Both operations commit to same branch.

**Solution**: Sequence git operations or use separate branches.

**Example**:
```
Bad:
  Parallel: Commit file A, Commit file B
Good:
  Sequential: Stage file A, Stage file B, Commit both
```

## Agents Failing

### Symptom
One or more agents in parallel batch fail with errors.

### Possible Causes

**1. Missing dependency output**

Agent expects output from another parallel operation that hasn't completed.

**Solution**: Move dependent operation to later layer.

**Example**:
```
Bad:
  Layer 0: Generate User model, Write User model tests
Good:
  Layer 0: Generate User model
  Layer 1: Write User model tests
```

**2. Resource exhaustion**

Too many agents running simultaneously exhaust system resources.

**Solution**: Reduce batch size.

**Example**:
```
Bad: Launch 20 agents in single batch
Good: Launch 5 agents across 4 batches
```

**3. Agent timeout**

Operation takes longer than expected, causing timeout.

**Solution**: Increase timeout or split operation into smaller pieces.

**4. Network failure**

Agent fetching external resources fails due to network issue.

**Solution**: Retry failed operations individually or add fallback.

## Results Not Aggregating Correctly

### Symptom
After parallel batch completes, aggregating results produces incorrect output.

### Possible Causes

**1. Missing result from failed agent**

One agent failed, but aggregation proceeded assuming all succeeded.

**Solution**: Check all agent results before aggregating. Handle failures explicitly.

**Example**:
```
Bad:
  Run 5 agents in parallel
  Aggregate results (assuming 5 results)

Good:
  Run 5 agents in parallel
  Check results: 4 succeeded, 1 failed
  If critical failure: halt, report error
  If non-critical: log warning, aggregate 4 results
```

**2. Results in wrong format**

Agent returned unexpected format, breaking aggregation logic.

**Solution**: Validate agent output format before aggregating.

**3. Order-dependent aggregation**

Aggregation logic assumes results arrive in specific order, but parallel execution doesn't guarantee order.

**Solution**: Make aggregation order-independent or sort results before aggregating.

## Debugging Strategy

### Step 1: Reproduce Sequentially

Run operations sequentially to establish baseline:
- Do all operations succeed when run sequentially?
- What is the total time?
- What outputs are produced?

If operations fail sequentially, fix those issues before attempting parallelization.

### Step 2: Identify Difference

Compare sequential vs parallel execution:
- Which operations fail in parallel but succeed in sequential?
- Are outputs different between sequential and parallel?
- Is timing significantly different?

### Step 3: Analyze Dependencies

Review dependency graph for operation that fails:
- Does it depend on another operation's output?
- Does it write to shared resources?
- Does it assume specific ordering?

### Step 4: Isolate Problem

Test failing operation in isolation:
- Run single failing operation alone
- Run failing operation with suspected dependency sequentially
- Run failing operation in small batch (2-3 operations)

### Step 5: Fix Root Cause

Based on analysis:
- If dependency found: Move to later layer
- If shared resource: Sequence or use atomic operations
- If resource contention: Reduce batch size
- If timeout: Increase timeout or split operation

### Step 6: Verify Fix

Re-run parallel execution with fix applied:
- All operations succeed?
- Results identical to sequential baseline?
- Time savings achieved?

## Common Error Messages

### "File not found: X"

**Meaning**: Operation tried to read file that another operation should have created.

**Cause**: Data dependency not respected (operation in wrong layer).

**Solution**: Move file-reading operation to layer after file-creating operation.

### "Merge conflict in git"

**Meaning**: Multiple operations tried to commit to same branch simultaneously.

**Cause**: Git operations not sequenced properly.

**Solution**: Sequence all git commits or batch changes into single commit.

### "Database deadlock detected"

**Meaning**: Multiple operations tried to lock same database records.

**Cause**: Database race condition.

**Solution**: Use transactions or sequence database operations.

### "Out of memory"

**Meaning**: Too many operations running simultaneously exhausted RAM.

**Cause**: Batch size too large.

**Solution**: Reduce batch size from 10 to 3-5 operations.

### "Agent timeout after 10 minutes"

**Meaning**: Operation took longer than expected timeout.

**Cause**: Operation is too complex or blocked.

**Solution**: Increase timeout, split into smaller operations, or check for blocking issues.

## Best Practices for Avoiding Issues

**1. Start small**

Don't immediately parallelize 20 operations. Start with 2-3, verify correctness, then scale up.

**2. Build dependency graph carefully**

Spend time analyzing dependencies before executing. Mistakes here cause failures.

**3. Test with sequential baseline**

Always run operations sequentially first to establish correctness baseline.

**4. Monitor resources**

Check CPU, RAM, disk I/O during parallel execution. If resources are maxed, reduce batch size.

**5. Handle failures gracefully**

Always check agent results before proceeding. Distinguish blocking vs non-blocking failures.

**6. Keep batches reasonable**

3-5 operations per batch is sweet spot. Larger batches risk resource exhaustion and are harder to debug.

**7. Document execution plan**

Write down layers, batches, and expected speedup before executing. Helps debug if things go wrong.

**8. Validate outputs**

After parallel execution, compare outputs to sequential baseline to verify correctness.

## Summary

**Performance issues**: Check operation size, resource contention, hidden dependencies, batch size.

**Race conditions**: Identify shared resources, sequence conflicting operations, use atomic operations.

**Agent failures**: Verify dependencies, reduce batch size, increase timeouts, retry on transient failures.

**Aggregation issues**: Validate all results, handle missing results, make aggregation order-independent.

**Debugging**: Reproduce sequentially, identify difference, analyze dependencies, isolate problem, fix root cause, verify fix.

**Prevention**: Start small, build careful dependency graph, test sequentially first, monitor resources, handle failures, keep batches reasonable.
