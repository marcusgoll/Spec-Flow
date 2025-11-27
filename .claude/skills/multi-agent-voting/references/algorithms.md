# Voting Algorithms Reference

## First-to-ahead-by-k Algorithm

The MAKER paper's core voting mechanism for error correction.

### Mathematical Foundation

**Probability of correctness with k-ahead voting:**

```
p_correct = p^k / (p^k + (1-p)^k)
```

Where:
- p = individual agent accuracy
- k = votes ahead required for winner

**Example calculations:**

| p (accuracy) | k | p_correct |
|-------------|---|-----------|
| 0.60 | 2 | 0.69 |
| 0.70 | 2 | 0.84 |
| 0.80 | 2 | 0.94 |
| 0.70 | 3 | 0.91 |
| 0.80 | 3 | 0.97 |

### Pseudocode

```python
def first_to_ahead_by_k(agents, k, max_rounds=10):
    votes = []

    for round in range(max_rounds):
        # Get vote from next agent
        new_vote = sample_agent(agents)

        # Red-flag check
        if is_red_flagged(new_vote):
            continue  # Discard and resample

        votes.append(new_vote)

        # Count votes per candidate
        counts = Counter(votes)

        # Check for k-ahead winner
        sorted_candidates = counts.most_common()
        if len(sorted_candidates) >= 2:
            leader_count = sorted_candidates[0][1]
            runner_up_count = sorted_candidates[1][1]

            if leader_count - runner_up_count >= k:
                return sorted_candidates[0][0]  # Winner

        elif len(sorted_candidates) == 1:
            if counts[sorted_candidates[0][0]] >= k:
                return sorted_candidates[0][0]  # Unanimous so far

    # No consensus after max_rounds
    return ESCALATE_TO_USER
```

### Optimal k Selection

**Key insight from MAKER paper:**

```
k_min grows logarithmically with number of steps: O(ln s)
```

Practical guidance:
- **Low stakes** (spec validation): k=2
- **Medium stakes** (code review): k=2
- **High stakes** (breaking changes): k=2, but with tie_breaker = conservative
- **Critical** (security, architecture): k=3

### Cost Scaling

**With maximal decomposition (MAKER approach):**
```
Total cost = O(s * ln(s))
```

**Without decomposition:**
```
Total cost = O(exp(s))
```

The logarithmic scaling is what makes MAKER's approach practical for million-step tasks.

## Majority Voting

Simpler but less robust than k-ahead.

```python
def majority_vote(votes):
    counts = Counter(votes)
    total = len(votes)
    required = total // 2 + 1

    for candidate, count in counts.most_common():
        if count >= required:
            return candidate

    return TIE_BREAKER_VALUE
```

## Unanimous Voting

For critical decisions where any dissent matters.

```python
def unanimous_vote(votes):
    unique = set(votes)
    if len(unique) == 1:
        return unique.pop()
    return ESCALATE_TO_USER
```

## Weighted Voting

For mixed-model scenarios.

```python
def weighted_vote(votes_with_models, weights):
    weighted_counts = defaultdict(float)

    for vote, model in votes_with_models:
        weight = weights.get(model, 1.0)
        weighted_counts[vote] += weight

    winner = max(weighted_counts, key=weighted_counts.get)
    return winner
```

**Default weights:**
```yaml
opus: 2.0
sonnet: 1.5
haiku: 1.0
```

## Error Decorrelation

Critical for voting effectiveness - correlated errors can defeat voting.

### Temperature Variation

```python
def varied_temperatures(base=0.7, variation=0.2, n_agents=3):
    return [
        base - variation,  # 0.5
        base,              # 0.7
        base + variation   # 0.9
    ]
```

### Prompt Paraphrasing

Techniques:
1. **Rephrase question** - Same meaning, different words
2. **Reorder context** - Present information in different order
3. **Vary examples** - Use different few-shot examples

### Model Mixing

Most effective decorrelation but highest cost:
- Agent 1: haiku
- Agent 2: sonnet
- Agent 3: opus

Different model architectures produce more independent errors.

## Tie Breaking Strategies

When votes are tied:

1. **Conservative** - Choose the safer option
   - Breaking change detection: assume BREAKING
   - Security review: assume UNSAFE

2. **Optimistic** - Choose the positive option
   - Rarely recommended

3. **Resample** - Get more votes until k-ahead achieved

4. **Escalate** - Ask user to decide

## Red Flag Integration

Before counting any vote:

```python
def validate_vote(response, red_flags_config):
    # Check response length
    if len(response) > red_flags_config['max_tokens']:
        return DISCARD

    # Check format
    if not matches_expected_format(response):
        return DISCARD

    # Check uncertainty markers
    if count_uncertainty_markers(response) > threshold:
        return DISCARD

    return ACCEPT
```

Only accepted votes count toward consensus.
