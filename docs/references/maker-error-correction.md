# MAKER Error Correction (v10.1+)

Based on "Solving a Million-Step LLM Task with Zero Errors" (arXiv:2511.09030).

## Core Concepts

### Maximal Decomposition

Smaller tasks = higher reliability

- Score 1-3 (Atomic): ~95% success
- Score 4-6 (Compound): ~85% success
- Score 7-10 (Complex): ~70% success → DECOMPOSE

### First-to-ahead-by-k Voting

Multiple agents vote, k-ahead wins

- Formula: `p_correct = p^k / (p^k + (1-p)^k)`
- k=2 with 70% agents → 84% accuracy

### Red-Flagging

Discard suspicious outputs, don't repair

- Long responses → confusion
- Format errors → reasoning errors
- Retry fresh, don't patch

## Configuration Files

- `.spec-flow/config/red-flags.yaml` — Output validation and retry rules
- `.spec-flow/config/voting.yaml` — Multi-agent voting settings
- `.spec-flow/learnings/error-rates.yaml` — Success rate tracking

## Task Complexity Scoring

Add 1 point for each:

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

Tasks scoring >5 should be decomposed.

## Voting-Enabled Operations

- code_review (k=2, 3 agents)
- breaking_change_detection (k=2, conservative tie-breaker)
- spec_validation (k=2, haiku model)
- security_review (unanimous required)

## Model Selection (c/p optimization)

Minimize cost per success, not just cost:

- **Haiku** (1x): Atomic tasks, simple validation
- **Sonnet** (3x): Compound tasks, code review
- **Opus** (15x): Complex decisions, security

See `docs/maker-integration.md` for full documentation.
