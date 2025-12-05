# MAKER Integration Guide

**Version**: 1.0.0
**Based on**: "Solving a Million-Step LLM Task with Zero Errors" (arXiv:2511.09030)

## Overview

This guide documents the integration of MAKER (Massively Decomposed Agentic Processes) concepts into Spec-Flow to improve workflow reliability and scalability.

**Key insight from MAKER**: "By smashing intelligence into a million pieces, it is possible to build AI that is efficient, safe, and reliable."

## Core MAKER Concepts

### 1. Maximal Agentic Decomposition (MAD)

**Principle**: Break tasks into the smallest possible subtasks where each agent focuses on a single step with minimal context.

**Why it works**:
- Avoids context confusion that accumulates in long chains
- Each agent's role is highly focused and simple
- Enables use of smaller, cheaper LLMs
- Creates modularity that enables error correction

**Spec-Flow implementation**:
- Task complexity scoring in `/tasks` phase
- Warning when task score > 5
- Automatic decomposition suggestions for complex tasks

### 2. First-to-ahead-by-k Voting

**Principle**: Error correction via multiple independent samples. A candidate must be k votes ahead of any other to win.

**Key formula**:
```
p_correct = p^k / (p^k + (1-p)^k)
```

**Example accuracy improvements**:
| Single Agent | k=2 (3 agents) | k=3 (5 agents) |
|-------------|----------------|----------------|
| 70% | 84% | 91% |
| 80% | 94% | 97% |
| 90% | 98% | 99.7% |

**Spec-Flow implementation**:
- Multi-agent voting skill for critical decisions
- Configurable via `.spec-flow/config/voting.yaml`
- Applied to: code review, breaking change detection, spec validation

### 3. Red-Flagging

**Principle**: Discard suspicious outputs rather than trying to repair them.

**Red flags identified by MAKER**:
1. **Overly long responses** - Indicates confusion, self-destructive analysis loops
2. **Incorrectly formatted responses** - Correlates with reasoning errors

**Key insight**: "Bad behaviors are correlated in LLMs" - if one thing is wrong, other things likely are too.

**Spec-Flow implementation**:
- Red flag configuration in `.spec-flow/config/red-flags.yaml`
- Automatic discard and retry instead of repair
- Tracked in learning system for pattern detection

### 4. Error Decorrelation

**Principle**: Independent sampling is crucial. Correlated errors can defeat voting mechanisms.

**Techniques**:
- Temperature-based resampling
- Prompt paraphrasing
- Different model providers (optional)

**Spec-Flow implementation**:
- Temperature variation between voting agents
- Optional prompt variation
- Optional model mixing

## Configuration Files

### Red Flags (`.spec-flow/config/red-flags.yaml`)

Controls when agent outputs are discarded vs retried:

```yaml
agent_output_validation:
  max_response_tokens: 2000
  format_strict: true
  max_retries: 5

red_flags:
  - response_length_exceeded
  - format_validation_failed
  - contains_uncertainty_markers
  - circular_reasoning_detected
```

### Voting (`.spec-flow/config/voting.yaml`)

Controls multi-agent voting behavior:

```yaml
global:
  enabled: true
  default_strategy: "first_to_ahead_by_k"
  default_k: 2
  default_agents: 3

operations:
  code_review:
    enabled: true
    strategy: "first_to_ahead_by_k"
    k: 2
    agents: 3
```

### Error Rates (`.spec-flow/learnings/error-rates.yaml`)

Tracks historical success rates for adaptive behavior:

```yaml
task_types:
  api_endpoint:
    samples: 47
    success_rate: 0.94
    avg_retries: 1.2
    recommended_model: "sonnet"
```

## Task Complexity Scoring

Each task receives a complexity score from 1-10:

| Score | Level | Description | Reliability |
|-------|-------|-------------|-------------|
| 1-3 | Atomic | Single operation | ~95% |
| 4-6 | Compound | 2-4 operations | ~85% |
| 7-10 | Complex | Multiple dependencies | ~70% |

**Scoring criteria** (add 1 point each):
1. Multiple files modified
2. Cross-subsystem work
3. External dependency
4. Conditional logic
5. State management
6. Error handling
7. Integration point
8. Unclear requirements
9. No existing pattern
10. High-stakes operation

**Recommendation**: Decompose tasks scoring > 5

## Cost Optimization

MAKER introduces the concept of **cost per success (c/p)**, not just cost:

```
c/p = model_cost / success_rate
```

**Model selection guidance**:
- **Haiku** (cost: 1x): Atomic tasks, simple validations
- **Sonnet** (cost: 3x): Compound tasks, code review
- **Opus** (cost: 15x): Complex tasks, architecture decisions

**When voting pays off**:
- 3 agents with haiku at 70% accuracy = 84% correct
- Cost: 3x haiku
- c/p improvement: 3.0 / 0.84 = 3.57 vs 1.0 / 0.70 = 1.43
- Voting is 2.5x more cost-effective for reliability

## Workflow Integration

### /tasks Phase

Complexity scoring is added during task generation:

```markdown
## Complexity Analysis

| Score Range | Count | Recommendation |
|-------------|-------|----------------|
| 1-3 (Atomic) | 18 | ✅ Proceed |
| 4-6 (Compound) | 8 | ⚠️ Monitor |
| 7-10 (Complex) | 2 | ❌ DECOMPOSE |
```

### /implement Phase

Before executing each task:
1. Check complexity score
2. If score > 5, warn about potential difficulties
3. If task fails 2x, suggest decomposition
4. Track success rate for learning

### /optimize Phase

Quality gates can use voting:
- Code review: 3 agents vote on pass/fail
- Security scan: Unanimous agreement required
- Breaking change detection: Conservative tie-breaker

## Scaling Properties

MAKER's key mathematical insight:

**Without decomposition** (traditional approach):
```
Cost ∝ exp(number_of_steps)
```

**With maximal decomposition**:
```
Cost ∝ steps × ln(steps)
```

This log-linear scaling is what makes million-step tasks feasible.

## Implementation Phases

### Phase 1: Red-Flagging (Implemented)
- Added `.spec-flow/config/red-flags.yaml`
- Configured response length limits
- Strict format validation
- Discard-and-retry strategy

### Phase 2: Voting (Implemented)
- Added `.spec-flow/config/voting.yaml`
- Created multi-agent-voting skill
- First-to-k voting algorithm
- Applied to code review, breaking changes

### Phase 3: Task Granularity (Implemented)
- Added complexity scoring to /tasks
- Warning for score > 5
- Decomposition suggestions
- Learning integration

### Phase 4: Error Rate Learning (Implemented)
- Added `.spec-flow/learnings/error-rates.yaml`
- Track per-task-type success rates
- Model recommendation based on history
- Adaptive threshold adjustment

## Best Practices

### 1. Prefer Decomposition Over Complexity

**Instead of**:
```
Task: Implement authentication with OAuth2, session management, and token refresh
```

**Decompose to**:
```
T01: Create OAuth2 callback endpoint (score: 3)
T02: Implement token validation (score: 2)
T03: Create session middleware (score: 3)
T04: Add token refresh logic (score: 2)
```

### 2. Use Voting for Critical Decisions

Enable voting for:
- Security-sensitive operations
- Breaking change detection
- Architecture decisions
- Final code review before deploy

### 3. Discard Bad Outputs, Don't Repair

When an agent produces:
- Overly long responses
- Format errors
- Uncertainty markers

**Don't**: Try to extract useful parts
**Do**: Discard completely and retry fresh

### 4. Track and Learn

The learning system tracks:
- Success rates by task type
- Success rates by complexity score
- Success rates by model
- Red flag occurrences

Use this data to:
- Adjust model selection
- Modify complexity thresholds
- Identify problematic task types

## Troubleshooting

### High Failure Rate for Task Type

1. Check complexity score distribution
2. Consider model upgrade for that task type
3. Enable voting if success rate < 85%
4. Review decomposition opportunities

### Voting Not Reaching Consensus

1. Check if red-flagging is too aggressive
2. Verify decorrelation is enabled
3. Consider increasing k value
4. Review output format requirements

### Cost Higher Than Expected

1. Check if voting is enabled unnecessarily
2. Review model selection for simple tasks
3. Consider disabling voting for atomic tasks
4. Track c/p (cost per success) not just cost

## References

- **MAKER Paper**: arXiv:2511.09030 "Solving a Million-Step LLM Task with Zero Errors"
- **Voting Configuration**: `.spec-flow/config/voting.yaml`
- **Red Flag Configuration**: `.spec-flow/config/red-flags.yaml`
- **Error Rates Tracking**: `.spec-flow/learnings/error-rates.yaml`
- **Multi-Agent Voting Skill**: `.claude/skills/multi-agent-voting/SKILL.md`
- **Task Complexity Scoring**: `.claude/skills/task-breakdown-phase/reference.md`
