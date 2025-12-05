# Quick Fix: Infinite Loop

**🚨 If you see repeated "Thinking..." or "Channelling..." messages**

---

## Immediate Actions (Choose One)

### Option 1: Interrupt (Fastest)
```
1. Press ESC multiple times
2. If stuck, press Ctrl+C
3. Close and restart Claude Code if still stuck
```

### Option 2: Reset Circuit Breaker
```bash
node .spec-flow/scripts/utils/circuit-breaker.mjs reset
```

### Option 3: Clear Cache
```bash
rm -rf .claude/tsc-cache/*
rm -f .spec-flow/cache/agent-circuit-breaker.json
```

---

## Prevention

Circuit breaker is now active with limits:
- **Max recursion depth**: 5 agent calls deep
- **Max frequency**: 10 calls/minute per agent
- **Cooldown**: 5 minutes after limit hit

---

## Check Status

```bash
# View circuit breaker status
node .spec-flow/scripts/utils/circuit-breaker.mjs status

# Check specific agent
node .spec-flow/scripts/utils/circuit-breaker.mjs check Plan
```

---

## More Info

See full documentation: `docs/INFINITE_LOOP_PREVENTION.md`

**Root Cause**: Agent spawning loop (fixed with circuit breaker)
**Status**: ✅ Resolved
**Date**: 2025-11-20
