---
description: Apply intelligent caching to avoid redundant work and speed up workflow execution by 20-40%
argument-hint: [optional: operation to cache]
allowed-tools: Skill(caching-strategy)
---

<objective>
Delegate caching optimization to the caching-strategy skill for: $ARGUMENTS

This skill eliminates redundant work by caching expensive operations (file reads, searches, API calls, computations) with appropriate TTLs and automatic invalidation.
</objective>

<process>
1. Use Skill tool to invoke caching-strategy skill
2. Pass operation context: $ARGUMENTS
3. Let skill identify cacheable operations
4. Implement caching with proper TTLs and invalidation
5. Monitor cache effectiveness (hit rate, time saved)
</process>

<success_criteria>
- Skill successfully invoked
- Cacheable operations identified (>100ms, idempotent, repeated)
- Appropriate TTLs set (file: mtime, network: 15-60min, computed: until changed)
- Cache invalidation working (no stale data)
- Hit rate >60%
- Time savings 20-40%
</success_criteria>
