---
description: Apply parallel execution optimization to detect and parallelize independent operations for 3-5x speedup
argument-hint: [optional: context or phase to optimize]
allowed-tools: Skill(parallel-execution-optimizer)
---

<objective>
Delegate parallel execution optimization to the parallel-execution-optimizer skill for: $ARGUMENTS

This routes to specialized skill containing dependency analysis patterns, batching strategies, and phase-specific parallelization workflows.
</objective>

<process>
1. Use Skill tool to invoke parallel-execution-optimizer skill
2. Pass user's request or context: $ARGUMENTS
3. Let skill analyze dependencies and orchestrate parallel execution
</process>

<success_criteria>
- Skill successfully invoked
- Arguments passed correctly to skill
- Parallel execution strategy applied with 2-5x speedup
</success_criteria>
