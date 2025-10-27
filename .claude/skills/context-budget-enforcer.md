---
name: context-budget-enforcer
description: "Monitor and enforce token budgets across workflow phases. Auto-compact context at 80% threshold using phase-aware strategies (planning: 75K, implementation: 100K, optimization: 125K). Auto-triggers when token usage exceeds budget or before heavy operations (brainstorming, research, task batching). Prevents context overflow and OOM errors."
allowed-tools: Read, Bash
---

# Context Budget Enforcer: Token Management Optimizer

**Purpose**: Prevent context overflow by monitoring token usage and auto-compacting when budgets are exceeded.

**Philosophy**: "Context is finite. Monitor continuously, compact proactively, optimize ruthlessly."

---

## When to Trigger

**Auto-invoke when detecting these patterns**:

### Phase Start
- "/spec" (spec phase: 75K budget)
- "/plan" (planning phase: 75K budget)
- "/tasks" (tasks phase: 50K budget)
- "/implement" (implementation phase: 100K budget)
- "/optimize" (optimization phase: 125K budget)

### Before Heavy Operations
- "/roadmap brainstorm deep" (~40-60K tokens)
- "research extensively" (~30-50K tokens)
- "parallel task batching" (~80K tokens)
- "generate design variations" (~50K+ tokens)

### Budget Threshold Exceeded
- Current token count > 80% of phase budget
- Approaching 150K context limit (global warning)
- Context growth rate > 10K tokens/command

---

## Phase-Based Token Budgets

### Budget Table

| Phase | Budget | Critical Files | Compaction Strategy |
|-------|--------|----------------|---------------------|
| **Specification** | 75K | spec.md, NOTES.md, roadmap | Lightweight (keep spec, compress NOTES) |
| **Planning** | 75K | plan.md, research.md, reuse-analysis.md | Medium (keep plan outline, summarize research) |
| **Tasks** | 50K | tasks.md, plan.md | Lightweight (keep tasks, compress plan) |
| **Implementation** | 100K | tasks.md, code files, tests | Heavy (aggressive test compression, code summaries) |
| **Optimization** | 125K | optimization-report.md, code review, benchmarks | Heavy (keep critical issues, compress passed checks) |

### Budget Calculation

**Current context size** (example for planning phase):
```bash
# Calculate token usage for critical files
TOKEN_COUNT=0

# Specs directory files
for file in specs/NNN-slug/*.md; do
  LINES=$(wc -l < "$file")
  # Rough estimate: 4 tokens per line average
  TOKENS=$((LINES * 4))
  TOKEN_COUNT=$((TOKEN_COUNT + TOKENS))
  echo "$file: ~$TOKENS tokens"
done

# Project docs (if loaded)
if [ -d "docs/project" ]; then
  for file in docs/project/*.md; do
    LINES=$(wc -l < "$file")
    TOKENS=$((LINES * 4))
    TOKEN_COUNT=$((TOKEN_COUNT + TOKENS))
    echo "$file: ~$TOKENS tokens"
  done
fi

# Codebase context (if reading files)
# Add token counts for Read operations

echo ""
echo "📊 Total context usage: ~$TOKEN_COUNT tokens"
echo "📋 Phase budget: 75000 tokens (planning)"
PERCENTAGE=$((TOKEN_COUNT * 100 / 75000))
echo "📈 Usage: $PERCENTAGE%"

if [ $PERCENTAGE -gt 80 ]; then
  echo "⚠️  WARNING: Approaching budget limit"
  echo "   Recommend compaction before next operation"
fi
```

**Output example**:
```
specs/001-auth/spec.md: ~4,200 tokens
specs/001-auth/NOTES.md: ~1,800 tokens
specs/001-auth/plan.md: ~12,500 tokens
specs/001-auth/research.md: ~18,000 tokens
docs/project/overview.md: ~6,400 tokens
docs/project/tech-stack.md: ~5,200 tokens
docs/project/system-architecture.md: ~8,900 tokens
docs/project/api-strategy.md: ~7,100 tokens

📊 Total context usage: ~64,100 tokens
📋 Phase budget: 75000 tokens (planning)
📈 Usage: 85%

⚠️  WARNING: Approaching budget limit
   Recommend compaction before next operation
```

---

## Compaction Strategies

### Strategy 1: Lightweight Compaction (Spec & Tasks Phases)

**Target**: Reduce context by 30%

**Actions**:
```bash
# Compress NOTES.md (keep headers, summarize content)
# Before: 1,800 tokens → After: 600 tokens

# Compress roadmap (keep top 10 features)
# Before: 15,000 tokens → After: 3,000 tokens

# Compress research.md (keep only conclusions)
# Before: 18,000 tokens → After: 5,000 tokens

# Keep critical files unchanged:
# - spec.md (no compression)
# - tasks.md (no compression)
```

**Expected reduction**: ~25K tokens → savings of 30%

**Command**:
```bash
.spec-flow/scripts/bash/compact-context.sh \
  --feature-dir specs/NNN-slug \
  --phase spec \
  --strategy lightweight
```

---

### Strategy 2: Medium Compaction (Planning Phase)

**Target**: Reduce context by 60%

**Actions**:
```bash
# Compress plan.md (keep outline + critical sections)
# Before: 12,500 tokens → After: 4,000 tokens

# Compress research.md (executive summary only)
# Before: 18,000 tokens → After: 2,000 tokens

# Compress reuse-analysis.md (keep recommendations)
# Before: 8,000 tokens → After: 1,500 tokens

# Compress NOTES.md (keep decision log)
# Before: 1,800 tokens → After: 400 tokens

# Keep unchanged:
# - spec.md (no compression)
# - workflow-state.yaml (no compression)
```

**Expected reduction**: ~40K tokens → savings of 60%

**Command**:
```bash
.spec-flow/scripts/bash/compact-context.sh \
  --feature-dir specs/NNN-slug \
  --phase plan \
  --strategy medium
```

---

### Strategy 3: Heavy Compaction (Implementation & Optimization Phases)

**Target**: Reduce context by 90%

**Actions**:
```bash
# Compress tasks.md (keep incomplete tasks + summary)
# Before: 28,000 tokens (28 tasks with details) → After: 3,000 tokens

# Compress test files (keep failing test names only)
# Before: 45,000 tokens (test code) → After: 2,000 tokens

# Compress code files (keep function signatures only)
# Before: 60,000 tokens (implementation code) → After: 8,000 tokens

# Compress optimization-report.md (keep critical issues)
# Before: 25,000 tokens → After: 5,000 tokens

# Keep unchanged:
# - workflow-state.yaml
# - error-log.md (if exists)
```

**Expected reduction**: ~140K tokens → savings of 90%

**Command**:
```bash
.spec-flow/scripts/bash/compact-context.sh \
  --feature-dir specs/NNN-slug \
  --phase implementation \
  --strategy heavy
```

---

## Budget Enforcement Rules

### Rule 1: Pre-Operation Budget Check

**Before ANY heavy operation** (brainstorm, research, task generation):

```bash
CURRENT_TOKENS=64100
OPERATION_ESTIMATE=40000  # Deep brainstorm
PHASE_BUDGET=75000

PROJECTED=$((CURRENT_TOKENS + OPERATION_ESTIMATE))
PROJECTED_PERCENTAGE=$((PROJECTED * 100 / PHASE_BUDGET))

if [ $PROJECTED_PERCENTAGE -gt 100 ]; then
  echo "❌ BUDGET EXCEEDED (projected)"
  echo ""
  echo "Current usage: $CURRENT_TOKENS tokens (85%)"
  echo "Operation estimate: $OPERATION_ESTIMATE tokens"
  echo "Projected total: $PROJECTED tokens ($PROJECTED_PERCENTAGE%)"
  echo "Phase budget: $PHASE_BUDGET tokens"
  echo ""
  echo "BLOCKING: Must compact context before operation"
  echo ""
  echo "Recommended compaction:"
  .spec-flow/scripts/bash/compact-context.sh \
    --feature-dir specs/NNN-slug \
    --phase plan \
    --strategy medium \
    --dry-run
  exit 1
fi
```

---

### Rule 2: Real-Time Monitoring

**During operation execution**:

```bash
# Monitor token growth
TOKENS_START=64100
TOKENS_CURRENT=72000
TOKENS_GROWTH=$((TOKENS_CURRENT - TOKENS_START))

if [ $TOKENS_GROWTH -gt 10000 ]; then
  echo "⚠️  WARNING: Rapid context growth detected"
  echo "   Start: $TOKENS_START tokens"
  echo "   Current: $TOKENS_CURRENT tokens"
  echo "   Growth: $TOKENS_GROWTH tokens (+$((TOKENS_GROWTH * 100 / TOKENS_START))%)"
  echo ""
  echo "   Recommend pausing to compact"
fi
```

---

### Rule 3: Auto-Compact at 80% Threshold

**Automatic compaction when budget exceeded**:

```bash
CURRENT_TOKENS=61000
PHASE_BUDGET=75000
PERCENTAGE=$((CURRENT_TOKENS * 100 / PHASE_BUDGET))

if [ $PERCENTAGE -gt 80 ]; then
  echo "🔄 AUTO-COMPACTING: Budget at $PERCENTAGE%"
  echo ""

  # Select strategy based on phase
  case "$CURRENT_PHASE" in
    spec|tasks)
      STRATEGY="lightweight"
      ;;
    plan)
      STRATEGY="medium"
      ;;
    implementation|optimization)
      STRATEGY="heavy"
      ;;
  esac

  # Run compaction
  .spec-flow/scripts/bash/compact-context.sh \
    --feature-dir specs/NNN-slug \
    --phase "$CURRENT_PHASE" \
    --strategy "$STRATEGY"

  # Verify reduction
  TOKENS_AFTER=$(calculate_tokens)
  SAVINGS=$((CURRENT_TOKENS - TOKENS_AFTER))
  SAVINGS_PERCENTAGE=$((SAVINGS * 100 / CURRENT_TOKENS))

  echo ""
  echo "✅ Compaction complete"
  echo "   Before: $CURRENT_TOKENS tokens"
  echo "   After: $TOKENS_AFTER tokens"
  echo "   Savings: $SAVINGS tokens ($SAVINGS_PERCENTAGE%)"
  echo ""
fi
```

---

### Rule 4: Global Limit (150K Hard Cap)

**Claude Code has a ~150-200K context window limit**:

```bash
CURRENT_TOKENS=145000
GLOBAL_LIMIT=150000

if [ $CURRENT_TOKENS -gt $GLOBAL_LIMIT ]; then
  echo "❌ CRITICAL: Global context limit exceeded"
  echo ""
  echo "Current usage: $CURRENT_TOKENS tokens"
  echo "Global limit: $GLOBAL_LIMIT tokens"
  echo ""
  echo "BLOCKING: Immediate heavy compaction required"
  echo "          Consider phase restart if compaction insufficient"
  exit 1
fi
```

---

## Token Estimation Guidelines

### File Size Estimates

| File Type | Tokens per Line | Example |
|-----------|----------------|---------|
| Markdown (prose) | 4-6 | spec.md, README |
| Markdown (code-heavy) | 3-4 | tasks.md with code blocks |
| Python code | 2-3 | models, services, routes |
| TypeScript/JSX | 2-4 | components, hooks |
| Test code | 2-3 | pytest, Jest |
| JSON/YAML | 1-2 | config files, state |

### Operation Estimates

| Operation | Estimated Tokens | Notes |
|-----------|-----------------|-------|
| `/roadmap brainstorm quick` | 15-20K | 2-3 searches, 5 ideas |
| `/roadmap brainstorm deep` | 40-60K | 8-12 searches, 10 ideas |
| `/spec` creation | 10-15K | spec.md + NOTES.md |
| `/plan` generation | 30-50K | plan.md + research.md + reuse analysis |
| `/tasks` breakdown | 15-25K | 20-30 tasks with acceptance criteria |
| `/implement` (20 tasks) | 80-120K | Code + tests + task updates |
| `/optimize` | 40-60K | Benchmarks + code review + reports |
| Reading project docs (all 8) | 20-25K | overview through deployment-strategy |

---

## Integration with Workflow Commands

### /spec Phase

**Budget**: 75K tokens
**Pre-flight check**:
```bash
# Before running /spec
calculate_tokens specs/NNN-slug
# If > 60K (80% of 75K): Compact roadmap, NOTES.md
```

---

### /plan Phase

**Budget**: 75K tokens
**Pre-flight check**:
```bash
# Before running /plan (reads all 8 project docs ~20K)
calculate_tokens specs/NNN-slug
# Current: 15K (spec.md, NOTES.md)
# Operation: 50K (plan + research + project docs)
# Projected: 65K ✓ (under budget)
```

**Mid-operation check**:
```bash
# After research phase (before reuse analysis)
# If > 60K: Compact research.md to executive summary
```

---

### /implement Phase

**Budget**: 100K tokens
**Pre-flight check**:
```bash
# Before running /implement
calculate_tokens specs/NNN-slug
# Current: 65K (spec, plan, tasks, research)
# Operation: 80K (code + tests)
# Projected: 145K ❌ (exceeds budget)

# Auto-compact: Medium strategy on plan + research
# After compact: 40K
# Projected: 120K ⚠️ (still over, use heavy strategy)
# After heavy compact: 25K
# Projected: 105K ✓ (over budget but acceptable for impl phase)
```

**During implementation**:
```bash
# After completing 10 tasks (halfway)
# If > 80K: Compact completed task details in tasks.md
```

---

### /optimize Phase

**Budget**: 125K tokens (highest budget - needs full code context)
**Pre-flight check**:
```bash
# Before running /optimize
calculate_tokens specs/NNN-slug
# Current: 105K (spec, plan, tasks, code, tests)
# Operation: 60K (benchmarks, code review, reports)
# Projected: 165K ❌ (exceeds budget)

# Auto-compact: Heavy strategy
# After compact: 30K (keep only critical task summaries + code signatures)
# Projected: 90K ✓ (under budget)
```

---

## Compaction Script Usage

### Manual Compaction

**Calculate current usage**:
```bash
.spec-flow/scripts/bash/calculate-tokens.sh \
  --feature-dir specs/NNN-slug

# Output:
# 📊 Token usage for specs/001-auth:
#    spec.md: 4,200 tokens
#    plan.md: 12,500 tokens
#    tasks.md: 8,000 tokens
#    Total: 24,700 tokens
```

**Dry-run compaction** (preview savings):
```bash
.spec-flow/scripts/bash/compact-context.sh \
  --feature-dir specs/NNN-slug \
  --phase plan \
  --strategy medium \
  --dry-run

# Output:
# 🔍 Dry-run compaction (medium strategy):
#    plan.md: 12,500 → 4,000 (-68%)
#    research.md: 18,000 → 2,000 (-89%)
#    Total savings: 24,500 tokens (-65%)
```

**Execute compaction**:
```bash
.spec-flow/scripts/bash/compact-context.sh \
  --feature-dir specs/NNN-slug \
  --phase plan \
  --strategy medium

# Output:
# ✅ Compaction complete (medium strategy)
#    Before: 64,100 tokens
#    After: 22,600 tokens
#    Savings: 41,500 tokens (65%)
```

---

## Quality Checklist

Before allowing operations to proceed:

- [ ] **Token usage calculated** for current phase
- [ ] **Budget threshold checked** (< 80% of phase budget)
- [ ] **Operation estimate** added to current usage
- [ ] **Projected total** under phase budget
- [ ] **Compaction executed** if over threshold
- [ ] **Savings verified** (target reduction achieved)
- [ ] **Critical files preserved** (spec.md, workflow-state.yaml)

---

## Performance Impact

**Token Overhead**: ~200-500 tokens per budget check (minimal)

**Optimization**:
- Cache token counts (avoid repeated calculation)
- Only check before heavy operations (not every command)
- Use efficient estimation (avoid full tokenization)

**Expected Duration**: < 5 seconds per check, < 30 seconds per compaction

---

## Common Compaction Scenarios

### Scenario 1: Planning Phase Over Budget

**Situation**:
```
Current: 68K tokens (spec + plan + research + project docs)
Operation: /tasks (estimate 20K)
Projected: 88K (exceeds 75K budget)
```

**Resolution**:
```bash
# Compact research.md (18K → 2K)
# Savings: 16K tokens
# After: 52K tokens
# Projected: 72K ✓ (under budget)
```

---

### Scenario 2: Implementation Phase Runaway Context

**Situation**:
```
Current: 145K tokens (spec + plan + tasks + code + tests)
Global limit: 150K
5K tokens from OOM error
```

**Resolution**:
```bash
# Heavy compaction:
# - tasks.md: 28K → 3K (completed tasks summary)
# - test files: 45K → 2K (test names only)
# - code files: 60K → 8K (function signatures)
# Savings: 120K tokens
# After: 25K tokens ✓ (crisis averted)
```

---

### Scenario 3: Optimization Phase with Full Context

**Situation**:
```
Current: 105K tokens (full implementation context)
Operation: /optimize (estimate 60K)
Projected: 165K (exceeds 125K budget)
```

**Resolution**:
```bash
# Medium compaction (preserve code context for review):
# - research.md: 18K → 2K
# - NOTES.md: 2K → 400
# - completed tasks: 15K → 2K
# Savings: 32K tokens
# After: 73K tokens
# Projected: 133K ⚠️ (over budget but acceptable for optimization)
```

---

## Error Handling

**If compaction fails**:
```bash
echo "❌ Compaction failed"
echo ""
echo "Troubleshooting:"
echo "1. Check file permissions: ls -l specs/NNN-slug/"
echo "2. Verify backup exists: ls specs/NNN-slug/.compact-backup/"
echo "3. Restore from backup: cp specs/NNN-slug/.compact-backup/* specs/NNN-slug/"
echo "4. Report issue: github.com/spec-flow/issues"
```

**If budget still exceeded after compaction**:
```bash
echo "⚠️  Budget still exceeded after compaction"
echo ""
echo "Options:"
echo "  A) Restart phase (lose progress, fresh context)"
echo "  B) Continue with warning (risk OOM)"
echo "  C) Split feature into smaller parts"
read -p "Choice (A/B/C): " choice

case $choice in
  A|a)
    echo "Restarting phase..."
    # Reset workflow-state.yaml to previous phase
    ;;
  B|b)
    echo "⚠️  Proceeding with elevated OOM risk"
    ;;
  C|c)
    echo "Feature split recommended"
    echo "Create child features in roadmap, link dependencies"
    ;;
esac
```

---

## References

- **Scripts**:
  - `.spec-flow/scripts/bash/calculate-tokens.sh`
  - `.spec-flow/scripts/bash/compact-context.sh`
  - `.spec-flow/scripts/powershell/calculate-tokens.ps1`
  - `.spec-flow/scripts/powershell/compact-context.ps1`
- **Token budgets**: `CLAUDE.md` (Phase-based token budgets section)
- **Compaction strategies**: `docs/architecture.md` (Context management section)

---

_This skill enforces token budgets to prevent context overflow and maintain workflow performance._
