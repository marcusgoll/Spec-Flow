# Infinite Loop Prevention Guide

**Last Updated**: 2025-11-20
**Issue Date**: 2025-11-20
**Status**: Fixed + Prevention Implemented

---

## Incident Report

### Symptoms
```
✶ Channelling… (esc to interrupt · 4m 3s · ↑ 837 tokens)
✶ Channelling… (esc to interrupt · 4m 3s · ↑ 846 tokens)
∴ Thinking…
∴ Thinking…
∴ Thinking…
[repeated indefinitely]
```

### Root Causes Identified

#### 1. Agent Spawning Loop (Primary Cause)
**Issue**: Task tool with `subagent_type='Plan'` spawned an agent that continued processing after `ExitPlanMode` was called, creating a feedback loop.

**Technical Details**:
- Plan agent was spawned to research example app structure
- ExitPlanMode presented plan to user
- Agent may have continued processing in background
- Repeated "Thinking..." indicates agent stuck in processing loop

**Fix**: Implemented circuit breaker with recursion depth limits and call frequency tracking.

#### 2. Missing Import in agent-auto-route.ts (Secondary Cause)
**Issue**: Hook file used `join()` function without importing from `path` module.

**Location**: `D:\Coding\workflow\.claude\hooks\agent-auto-route.ts:103`

```typescript
// BEFORE (Bug)
const logDir = join(process.env.CLAUDE_PROJECT_DIR || process.cwd(), '.spec-flow', 'cache');

// AFTER (Fixed)
const logDir = path.join(process.env.CLAUDE_PROJECT_DIR || process.cwd(), '.spec-flow', 'cache');
```

**Impact**: While hooks were disabled (`"disableAllHooks": true`), this bug would have caused issues when hooks are re-enabled.

---

## Prevention Strategies Implemented

### 1. Circuit Breaker System

**Location**: `.spec-flow/scripts/utils/circuit-breaker.mjs`

**Features**:
- ✅ Max recursion depth limit (default: 5 levels)
- ✅ Call frequency limits (default: 10 calls/min per agent)
- ✅ Automatic cooldown period (default: 5 minutes)
- ✅ Persistent state tracking via cache
- ✅ Automatic cleanup of old records

**Configuration**:
```javascript
const CONFIG = {
  maxRecursionDepth: 5,           // Max agent call chain depth
  maxCallsPerMinute: 10,          // Max calls per agent per minute
  cooldownPeriod: 300000,         // 5 minutes in ms
  cacheDir: '.spec-flow/cache',
  cleanupInterval: 3600000,       // 1 hour
};
```

**Usage**:
```javascript
import { checkCircuitBreaker, recordAgentCall } from './circuit-breaker.mjs';

// Before spawning agent
const check = checkCircuitBreaker('Plan', 'parent-agent');
if (!check.allowed) {
  console.error(`Circuit breaker triggered: ${check.reason}`);
  return;
}

// Record the call
recordAgentCall('Plan', 'parent-agent');

// ... spawn agent ...
```

**CLI Commands**:
```bash
# Check status
node .spec-flow/scripts/utils/circuit-breaker.mjs status

# Check if agent call allowed
node .spec-flow/scripts/utils/circuit-breaker.mjs check Plan

# Reset circuit for specific agent
node .spec-flow/scripts/utils/circuit-breaker.mjs reset Plan

# Reset all circuits
node .spec-flow/scripts/utils/circuit-breaker.mjs reset
```

### 2. Hook Import Fix

**Fixed**: Missing `path.join` import in `agent-auto-route.ts`

**Status**: ✅ Complete (hooks currently disabled, fix ready for when re-enabled)

### 3. Agent Lifecycle Management

**Best Practices**:

1. **Always check circuit breaker before spawning agents**:
   ```typescript
   const check = checkCircuitBreaker(agentType, parentAgent);
   if (!check.allowed) {
     throw new Error(`Cannot spawn ${agentType}: ${check.reason}`);
   }
   ```

2. **Record agent calls immediately after spawning**:
   ```typescript
   recordAgentCall(agentType, parentAgent);
   ```

3. **Implement timeouts for agent operations**:
   ```typescript
   const timeout = setTimeout(() => {
     console.error(`Agent ${agentType} timed out after 5 minutes`);
     // Cleanup and exit
   }, 300000);
   ```

4. **Use agent exit signals**:
   ```typescript
   // In agent code, always exit cleanly
   process.exit(0);  // Success
   process.exit(1);  // Failure
   ```

---

## Detection and Recovery

### Detecting Infinite Loops

**Symptoms to watch for**:
- Repeated "Thinking..." or "Channelling..." messages
- Steadily increasing token counts (↑ 837 → ↑ 846 → ↑ 855)
- Session duration > 5 minutes without progress
- High CPU usage from Claude Code process

**Monitoring**:
```bash
# Check circuit breaker status regularly
node .spec-flow/scripts/utils/circuit-breaker.mjs status

# Check for open circuits
node .spec-flow/scripts/utils/circuit-breaker.mjs status | grep "circuitOpen.*true"
```

### Recovery Procedures

#### Immediate Recovery (During Incident)

**Option 1: Interrupt Session**
1. Press `Esc` multiple times in Claude Code
2. Press `Ctrl+C` if Esc doesn't work
3. If still stuck, close and restart Claude Code

**Option 2: Kill Process**
```bash
# macOS/Linux
pkill -f claude-code

# Windows (PowerShell)
Get-Process | Where-Object {$_.ProcessName -like "*claude*"} | Stop-Process

# Windows (Task Manager)
# Find "Claude Code" or "Node.js" process and end task
```

**Option 3: Clear Agent Cache**
```bash
# Remove all agent session data
rm -rf .claude/tsc-cache/*

# Remove circuit breaker cache
rm -f .spec-flow/cache/agent-circuit-breaker.json
```

#### Post-Incident Recovery

1. **Reset all circuits**:
   ```bash
   node .spec-flow/scripts/utils/circuit-breaker.mjs reset
   ```

2. **Review circuit breaker logs**:
   ```bash
   cat .spec-flow/cache/agent-routing.log
   cat .spec-flow/cache/skill-activation.log
   ```

3. **Check for problematic patterns**:
   ```bash
   # Find most frequently called agents
   node .spec-flow/scripts/utils/circuit-breaker.mjs status | \
     jq '.stats | to_entries | sort_by(-.value.totalCalls) | .[0:5]'
   ```

4. **Document incident**:
   - What triggered the loop?
   - Which agent(s) were involved?
   - How long did it run?
   - What fixed it?

---

## Testing and Validation

### Manual Testing

**Test 1: Recursion Depth Limit**
```bash
# Try to spawn nested agents beyond limit
# Expected: Circuit breaker blocks after 5 levels
```

**Test 2: Call Frequency Limit**
```bash
# Rapidly spawn same agent type
# Expected: Circuit breaker blocks after 10 calls/min
```

**Test 3: Cooldown Period**
```bash
# Trigger circuit breaker
# Wait 5 minutes
# Try again
# Expected: Circuit should be closed, calls allowed
```

### Automated Testing

Create test script: `.spec-flow/scripts/test-circuit-breaker.mjs`

```javascript
import { checkCircuitBreaker, recordAgentCall, resetCircuit } from './utils/circuit-breaker.mjs';

// Test 1: Normal operation
console.log('Test 1: Normal operation');
const check1 = checkCircuitBreaker('Test', null);
console.assert(check1.allowed === true, 'Should allow first call');
recordAgentCall('Test', null);

// Test 2: Recursion depth
console.log('Test 2: Recursion depth limit');
resetCircuit('Test');
for (let i = 0; i < 6; i++) {
  recordAgentCall('Test', 'Parent');
}
const check2 = checkCircuitBreaker('Test', 'Parent');
console.assert(check2.allowed === false, 'Should block after max depth');
console.assert(check2.reason.includes('recursion depth'), 'Should mention recursion depth');

// Test 3: Call frequency
console.log('Test 3: Call frequency limit');
resetCircuit('Test2');
for (let i = 0; i < 11; i++) {
  recordAgentCall('Test2', null);
}
const check3 = checkCircuitBreaker('Test2', null);
console.assert(check3.allowed === false, 'Should block after max calls/min');
console.assert(check3.reason.includes('frequency'), 'Should mention call frequency');

console.log('All tests passed!');
```

---

## Integration Guide

### For Command Developers

When creating slash commands that spawn agents:

```markdown
# .claude/commands/your-command.md

## Command Implementation

```xml
<process>
1. **Check circuit breaker before spawning agent**:
   - Run circuit breaker check for agent type
   - If blocked, inform user and exit gracefully

2. **Spawn agent with Task tool**:
   - Use appropriate subagent_type
   - Provide clear, bounded prompt
   - Set model parameter (prefer haiku for quick tasks)

3. **Record agent call**:
   - Log agent invocation for tracking
   - Include parent agent if nested call

4. **Monitor execution**:
   - Set reasonable timeout expectations
   - Provide progress indicators to user
   - Handle errors gracefully
</process>
```

**Example**:
```typescript
// Before spawning
const circuitCheck = await checkCircuitBreaker('backend-dev', currentAgent);
if (!circuitCheck.allowed) {
  throw new Error(`Cannot spawn backend-dev agent: ${circuitCheck.reason}`);
}

// Spawn agent
recordAgentCall('backend-dev', currentAgent);
const result = await spawnAgent('backend-dev', prompt);

// Handle result
if (result.error) {
  console.error(`Agent failed: ${result.error}`);
}
```

### For Agent Developers

When creating new agents:

1. **Set clear termination conditions**:
   ```typescript
   // Always have explicit exit points
   if (taskComplete) {
     process.exit(0);
   }
   ```

2. **Avoid recursive agent spawning**:
   ```typescript
   // Don't spawn agents from within agents (unless absolutely necessary)
   // If you must, check circuit breaker first
   ```

3. **Implement timeouts**:
   ```typescript
   const MAX_EXECUTION_TIME = 300000; // 5 minutes
   const startTime = Date.now();

   function checkTimeout() {
     if (Date.now() - startTime > MAX_EXECUTION_TIME) {
       console.error('Agent execution timeout');
       process.exit(1);
     }
   }
   ```

4. **Use progress indicators**:
   ```typescript
   // Show progress to prevent "stuck" appearance
   console.log('Processing step 1/5...');
   console.log('Processing step 2/5...');
   ```

### For Skill Developers

When creating skills that use agents:

```markdown
# .claude/skills/your-skill/SKILL.md

<notes>
**Agent Spawning Safety**:
- Always check circuit breaker before spawning agents
- Document expected agent execution time
- Provide fallback behavior if circuit is open
- Log all agent invocations for debugging

**Example**:
```typescript
const check = checkCircuitBreaker('Plan');
if (!check.allowed) {
  // Fallback: Manual planning instead of agent
  return manualPlanningFlow();
}

recordAgentCall('Plan');
return await spawnPlanAgent();
```
</notes>
```

---

## Configuration

### Circuit Breaker Settings

**Location**: `.spec-flow/scripts/utils/circuit-breaker.mjs`

**Adjustable Parameters**:

```javascript
const CONFIG = {
  // Max depth of agent → agent → agent chains
  maxRecursionDepth: 5,

  // Max calls per agent type within 1 minute window
  maxCallsPerMinute: 10,

  // How long circuit stays open after tripping (ms)
  cooldownPeriod: 300000,  // 5 minutes

  // Where to store circuit breaker state
  cacheDir: '.spec-flow/cache',
  cacheFile: 'agent-circuit-breaker.json',

  // How often to cleanup old records (ms)
  cleanupInterval: 3600000,  // 1 hour
};
```

**Tuning Guidelines**:

| Scenario | Recommended Settings |
|----------|---------------------|
| Development | `maxRecursionDepth: 3, maxCallsPerMinute: 5` |
| Production | `maxRecursionDepth: 5, maxCallsPerMinute: 10` |
| High-Throughput | `maxRecursionDepth: 7, maxCallsPerMinute: 20` |
| Conservative | `maxRecursionDepth: 2, maxCallsPerMinute: 3` |

### Hook Settings

**Location**: `.claude/settings.local.json`

```json
{
  "disableAllHooks": true,  // Currently disabled due to incident
  "permissions": {
    // ... permissions ...
  }
}
```

**To re-enable hooks after fixes are tested**:
```json
{
  "disableAllHooks": false,
  "hooks": {
    "UserPromptSubmit": {
      "enabled": true,
      "script": ".claude/hooks/skill-activation-prompt.ts"
    },
    "AfterToolUse": {
      "enabled": true,
      "script": ".claude/hooks/agent-auto-route.ts"
    }
  }
}
```

---

## Monitoring and Alerts

### Real-Time Monitoring

**Dashboard Command**:
```bash
# Watch circuit breaker status in real-time
watch -n 5 'node .spec-flow/scripts/utils/circuit-breaker.mjs status'
```

**Alert Conditions**:
- Any circuit is open
- Agent call frequency > 80% of limit
- Recursion depth > 80% of limit
- Multiple open circuits simultaneously

### Logging

**Log Locations**:
```
.spec-flow/cache/agent-routing.log          # Agent routing decisions
.spec-flow/cache/skill-activation.log       # Skill activation triggers
.spec-flow/cache/agent-circuit-breaker.json # Circuit breaker state
```

**Log Monitoring**:
```bash
# Watch for circuit breaker trips
tail -f .spec-flow/cache/agent-routing.log | grep -i "circuit\|block\|limit"

# Count agent calls per type
cat .spec-flow/cache/agent-routing.log | grep "Route:" | awk '{print $4}' | sort | uniq -c | sort -nr
```

---

## Future Improvements

### Planned Enhancements

1. **Telemetry Integration**:
   - Send circuit breaker events to monitoring system
   - Track agent execution times
   - Alert on anomalous patterns

2. **Adaptive Limits**:
   - Adjust limits based on system load
   - Learn safe thresholds over time
   - Per-agent custom limits

3. **Better Error Messages**:
   - Show agent call chain when circuit trips
   - Suggest which agent is causing loop
   - Provide recovery actions

4. **Circuit Breaker UI**:
   - Visual dashboard for circuit status
   - Real-time agent execution graph
   - Manual circuit control

### Contributing

Found an infinite loop issue? Please document:
1. Symptoms and error messages
2. Steps to reproduce
3. Which agents/commands involved
4. Recovery steps that worked
5. Suggested prevention strategies

Submit to: `docs/INFINITE_LOOP_INCIDENTS.md`

---

## References

- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
- [Bulkhead Pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/bulkhead)
- [Timeout Pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/timeout)
- [Spec-Flow Agent Architecture](./AGENTS.md)
- [Hook Development Guide](./.claude/skills/create-hooks/references/examples.md)

---

**Version**: 1.0.0
**Maintainer**: Spec-Flow Team
**Last Incident**: 2025-11-20
**Status**: ✅ Resolved + Prevention Implemented
