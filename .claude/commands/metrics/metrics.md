---
description: Measure HEART metrics from local sources (logs, DB, Lighthouse) and compare to targets
---

Measure HEART metrics for: $ARGUMENTS

## MENTAL MODEL

**Purpose**: Validate if feature met HEART hypothesis using Claude Code-accessible sources

**Measurement sources**:
- SQL queries → `feature_metrics` table (A/B test results)
- Structured logs → `logs/metrics/*.jsonl` (event counts, durations)
- Lighthouse CI → `.lighthouseci/results/*.json` (performance)
- Database queries → aggregate tables (retention, adoption)

**Output**: Pass/Fail per metric + recommendation (keep/iterate/rollback)

---

## VALIDATE INPUTS

**Before measuring, confirm experiment has run:**

```bash
FEATURE_SLUG="$ARGUMENTS"
FEATURE_DIR=$(find design/features -name "*$FEATURE_SLUG*" -type d | head -1)

# Check HEART metrics file exists
HEART_FILE="$FEATURE_DIR/heart-metrics.md"

if [ ! -f "$HEART_FILE" ]; then
  echo "❌ Missing: $HEART_FILE"
  echo "Run \spec-flow to create HEART metrics plan"
  exit 1
fi

# Check experiment design exists
EXPERIMENT_FILE="$FEATURE_DIR/experiment.md"

if [ ! -f "$EXPERIMENT_FILE" ]; then
  echo "❌ Missing: $EXPERIMENT_FILE"
  echo "Run \spec-flow to create experiment design"
  exit 1
fi

# Check feature has shipped (at least to staging)
INSTRUMENTATION_EXISTS=$(grep -r "$FEATURE_SLUG" apps/*/pages apps/*/app || echo "")

if [ -z "$INSTRUMENTATION_EXISTS" ]; then
  echo "⚠️  Feature not found in codebase"
  echo "Has this feature shipped? Measurement requires live instrumentation."
  exit 1
fi
```

---

## COLLECT METRICS

### Phase 1: SQL Queries (Database)

**Read measurement queries from**:
- `design/features/$FEATURE_SLUG/queries/*.sql`
- `design/features/$FEATURE_SLUG/heart-metrics.md` (inline queries)

**Execute all SQL queries**, save results:

```bash
# Create results directory
mkdir -p design/features/$FEATURE_SLUG/results/

# Task completion rate
if [ -f "design/features/$FEATURE_SLUG/queries/task_completion.sql" ]; then
  psql -d cfipros -f design/features/$FEATURE_SLUG/queries/task_completion.sql \
    -o design/features/$FEATURE_SLUG/results/task_completion.json \
    --json
fi

# Time-to-insight (duration metrics)
if [ -f "design/features/$FEATURE_SLUG/queries/time_to_insight.sql" ]; then
  psql -d cfipros -f design/features/$FEATURE_SLUG/queries/time_to_insight.sql \
    -o design/features/$FEATURE_SLUG/results/time_to_insight.json \
    --json
fi

# A/B test results (variant comparison)
if [ -f "design/features/$FEATURE_SLUG/queries/ab_test.sql" ]; then
  psql -d cfipros -f design/features/$FEATURE_SLUG/queries/ab_test.sql \
    -o design/features/$FEATURE_SLUG/results/ab_test.json \
    --json
fi

# Retention (7-day return rate)
if [ -f "design/features/$FEATURE_SLUG/queries/retention.sql" ]; then
  psql -d cfipros -f design/features/$FEATURE_SLUG/queries/retention.sql \
    -o design/features/$FEATURE_SLUG/results/retention.json \
    --json
fi
```

**Example SQL execution** (task_completion.sql):
```sql
-- File: design/features/aktr-upload-inline/queries/task_completion.sql
SELECT
  variant,
  COUNT(*) FILTER (WHERE outcome = 'task_completion' AND value = 1) * 100.0 / COUNT(*) as completion_rate,
  COUNT(*) as sample_size
FROM feature_metrics
WHERE feature = 'aktr_inline_preview'
  AND created_at >= NOW() - INTERVAL '7 days'
GROUP BY variant;
```

**Example output** (results/task_completion.json):
```json
[
  {"variant": "control", "completion_rate": 65.2, "sample_size": 385},
  {"variant": "treatment", "completion_rate": 84.8, "sample_size": 390}
]
```

### Phase 2: Structured Logs

**Parse JSON logs** for event counts and durations:

```bash
# Count events by type
grep "\"feature\":\"$FEATURE_SLUG\"" logs/metrics/*.jsonl | \
  jq -r '.event' | \
  sort | uniq -c | \
  jq -R 'split(" ") | {count: .[1], event: .[2]}' | \
  jq -s '.' > design/features/$FEATURE_SLUG/results/event_counts.json

# Duration metrics (P50, P95 for time_to_insight)
grep "\"event\":\"[^\"]*first_code_visible\"" logs/metrics/*.jsonl | \
  jq -r '.time_to_insight_ms' | \
  sort -n | \
  awk '{a[NR]=$1} END {
    print "{\"p50\":" a[int(NR*0.5)] ",\"p95\":" a[int(NR*0.95)] ",\"count\":" NR "}"
  }' > design/features/$FEATURE_SLUG/results/time_to_insight_logs.json

# Error rate
total=$(grep "\"feature\":\"$FEATURE_SLUG\"" logs/metrics/$(date +%Y-%m-%d).jsonl | wc -l)
errors=$(grep "\"event\":\"[^\"]*error\"" logs/metrics/$(date +%Y-%m-%d).jsonl | grep "\"feature\":\"$FEATURE_SLUG\"" | wc -l)
error_rate=$(echo "scale=2; ($errors / $total) * 100" | bc)
echo "{\"error_rate\":$error_rate,\"total_events\":$total,\"errors\":$errors}" > \
  design/features/$FEATURE_SLUG/results/error_rate.json
```

### Phase 3: Lighthouse CI (Performance)

**Run Lighthouse** on feature URLs:

```bash
# Read URLs from experiment.md or heart-metrics.md
FEATURE_URLS=$(grep -oP 'http://localhost:3000/[^\s]+' design/features/$FEATURE_SLUG/experiment.md)

# Collect Lighthouse data (5 runs for statistical reliability)
lhci collect \
  --url="http://localhost:3000/$FEATURE_URL" \
  --numberOfRuns=5 \
  --config=.lighthouserc.json

# Extract metrics
cat .lighthouseci/results/*.json | jq '{
  fcp: .audits["first-contentful-paint"].numericValue,
  tti: .audits.interactive.numericValue,
  cls: .audits["cumulative-layout-shift"].numericValue,
  lcp: .audits["largest-contentful-paint"].numericValue,
  performance_score: .categories.performance.score,
  accessibility_score: .categories.accessibility.score
}' > design/features/$FEATURE_SLUG/results/lighthouse.json
```

---

## COMPARE TO TARGETS

**Read HEART targets** from `heart-metrics.md`:

Example targets:
```
Happiness: Error rate <2% (was 5%)
Engagement: 2+ uploads/user/week (was 1.2)
Task Success: 85% completion (was 65%)
Time-to-insight: <8s P50 (was 15s)
```

**Compare actual vs. target:**

```bash
# Load targets from heart-metrics.md (parse markdown table)
# Load actuals from results/*.json

# Simple comparison script (bash + jq)
cat > design/features/$FEATURE_SLUG/results/compare.sh <<'EOF'
#!/bin/bash

# Read targets (example: manually extracted from heart-metrics.md)
TASK_SUCCESS_TARGET=85
TIME_TO_INSIGHT_TARGET=8000  # ms
ERROR_RATE_TARGET=2  # percent

# Read actuals
TASK_SUCCESS_ACTUAL=$(jq -r '.[0].completion_rate' task_completion.json)
TIME_TO_INSIGHT_ACTUAL=$(jq -r '.p50' time_to_insight_logs.json)
ERROR_RATE_ACTUAL=$(jq -r '.error_rate' error_rate.json)

# Compare
echo "{"
echo "  \"task_success\": {\"target\": $TASK_SUCCESS_TARGET, \"actual\": $TASK_SUCCESS_ACTUAL, \"pass\": $([ $(echo "$TASK_SUCCESS_ACTUAL >= $TASK_SUCCESS_TARGET" | bc) -eq 1 ] && echo "true" || echo "false")},"
echo "  \"time_to_insight\": {\"target\": $TIME_TO_INSIGHT_TARGET, \"actual\": $TIME_TO_INSIGHT_ACTUAL, \"pass\": $([ $(echo "$TIME_TO_INSIGHT_ACTUAL <= $TIME_TO_INSIGHT_TARGET" | bc) -eq 1 ] && echo "true" || echo "false")},"
echo "  \"error_rate\": {\"target\": $ERROR_RATE_TARGET, \"actual\": $ERROR_RATE_ACTUAL, \"pass\": $([ $(echo "$ERROR_RATE_ACTUAL <= $ERROR_RATE_TARGET" | bc) -eq 1 ] && echo "true" || echo "false")}"
echo "}"
EOF

chmod +x design/features/$FEATURE_SLUG/results/compare.sh
cd design/features/$FEATURE_SLUG/results && ./compare.sh > comparison.json
```

---

## GENERATE RESULTS REPORT

**Create**: `design/features/$FEATURE_SLUG/results.md`

```markdown
# HEART Measurement Results: [Feature Name]

**Feature**: [feature-slug]
**Measurement Window**: [START_DATE] to [END_DATE] (7 days)
**Sample Size**: N users (X control, Y treatment)
**Status**: [PASS | PARTIAL | FAIL]

---

## HEART Metrics Summary

| Dimension | Target | Actual | Status | Delta |
|-----------|--------|--------|--------|-------|
| **Happiness** (Error rate) | <2% | 1.8% | ✅ PASS | -0.2% (better) |
| **Engagement** (Uploads/user/week) | 2+ | 2.3 | ✅ PASS | +0.3 (better) |
| **Adoption** (New signups) | +20% | +18% | ⚠️ NEAR | -2% (close) |
| **Retention** (7-day return) | 40% | 42% | ✅ PASS | +2% (better) |
| **Task Success** (Completion rate) | 85% | 84.8% | ✅ PASS | -0.2% (near) |
| **Time-to-Insight** (P50) | <8s | 7.9s | ✅ PASS | -0.1s (better) |

**Overall**: 5/6 PASS, 1/6 NEAR (83% pass rate)

---

## Hypothesis Validation

**Hypothesis**: Inline preview (no redirect) will reduce time-to-insight to <8s and increase task completion to 85%

**Result**: ✅ **VALIDATED**
- Time-to-insight: 7.9s (target: <8s) — **PASS**
- Task completion: 84.8% (target: 85%) — **NEAR** (within 0.2%)

**Confidence**: High (sample size: 775 users, p-value: 0.03 < 0.05)

---

## A/B Test Results

| Variant | Completion Rate | Time-to-Insight (P50) | Sample Size |
|---------|-----------------|----------------------|-------------|
| Control | 65.2% | 15.2s | 385 |
| Treatment | 84.8% | 7.9s | 390 |
| **Delta** | **+19.6%** | **-7.3s (-48%)** | 775 total |

**Statistical Significance**:
- Chi-square (completion): χ² = 45.2, p < 0.001 ✅ Significant
- T-test (time): t = 12.8, p < 0.001 ✅ Significant

**Conclusion**: Treatment significantly outperforms control on both primary metrics.

---

## Guardrails Check

| Guardrail | Threshold | Actual | Status |
|-----------|-----------|--------|--------|
| Error rate | <5% | 1.8% | ✅ PASS |
| P95 extraction time | <10s | 9.2s | ✅ PASS |
| Server CPU | <80% | 42% | ✅ PASS |
| Memory usage | <85% | 58% | ✅ PASS |
| Lighthouse Performance | ≥85 | 92 | ✅ PASS |
| Lighthouse A11y | ≥95 | 100 | ✅ PASS |

**Overall**: All guardrails passed ✅

---

## Performance Metrics (Lighthouse)

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| FCP | <1.5s | 1.2s | ✅ PASS |
| TTI | <3.5s | 2.8s | ✅ PASS |
| CLS | <0.15 | 0.08 | ✅ PASS |
| LCP | <3.0s | 2.1s | ✅ PASS |
| Performance Score | ≥85 | 92 | ✅ PASS |
| Accessibility Score | ≥95 | 100 | ✅ PASS |

**Conclusion**: All performance budgets met ✅

---

## Recommendation

**Decision**: ✅ **KEEP** (Ramp to 100%)

**Rationale**:
1. Hypothesis validated (time-to-insight <8s, task completion near 85%)
2. Statistical significance achieved (p < 0.001)
3. All guardrails passed (error rate, performance, a11y)
4. Positive delta on all HEART dimensions
5. No user complaints or negative feedback

**Action Plan**:
1. ✅ Ramp feature flag to 100% (all users)
2. ✅ Systemize pattern (upstream inline preview to design system)
3. ✅ Document learnings (add to design-inspirations.md)
4. ✅ Monitor for 7 days post-100% (watch for regressions)
5. ✅ Archive experiment results (close experiment.md)

**Systemize Wins**:
- Component: Inline preview pattern (add to ui-inventory.md)
- Principle: "Same-page flows reduce abandonment" (add to design-inspirations.md)
- A11y: Progress announcements pattern (document in a11y guide)

---

## Measurement Sources

**SQL Queries**:
- `queries/task_completion.sql` → Completion rate by variant
- `queries/time_to_insight.sql` → P50/P95 duration by variant
- `queries/ab_test.sql` → Statistical significance tests
- `queries/retention.sql` → 7-day return rate

**Structured Logs**:
- `logs/metrics/*.jsonl` → Event counts, error rates, durations
- Parsed with: `grep + jq + awk`

**Lighthouse CI**:
- `.lighthouseci/results/*.json` → Performance scores (FCP, TTI, CLS, LCP)

**All raw data**: `design/features/[feat]/results/*.json`

---

**Generated**: [ISO timestamp]
**Measured By**: Claude Code `/metrics`
```

---

## GIT COMMIT

```bash
git add design/features/$FEATURE_SLUG/results/
git add design/features/$FEATURE_SLUG/results.md
git commit -m "measure: HEART metrics for $FEATURE_SLUG

Measurement Results:
- Hypothesis: ✅ VALIDATED (time-to-insight <8s, task completion 84.8%)
- A/B test: Treatment +19.6% completion, -48% time (-7.3s)
- Statistical significance: p < 0.001 (highly significant)
- Guardrails: ✅ All passed (error <2%, perf >85, a11y 100)
- Recommendation: KEEP (ramp to 100%)

Sources:
- SQL: feature_metrics table (775 users, 7 days)
- Logs: logs/metrics/*.jsonl (event counts, durations)
- Lighthouse: .lighthouseci/results/*.json (perf scores)

Next: Systemize wins (add inline preview pattern to design system)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## OUTPUT (Return to user)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ HEART MEASUREMENT COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: [feature-name]
Window: 7 days ([START] to [END])
Sample: N users (X control, Y treatment)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 RESULTS SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

HEART Metrics:
✅ Happiness (error rate): 1.8% (target: <2%)
✅ Engagement (uploads/user/week): 2.3 (target: 2+)
⚠️  Adoption (new signups): +18% (target: +20%, NEAR)
✅ Retention (7-day return): 42% (target: 40%)
✅ Task Success (completion): 84.8% (target: 85%, NEAR)
✅ Time-to-Insight (P50): 7.9s (target: <8s)

Overall: 5/6 PASS, 1/6 NEAR (83% success rate)

A/B Test (Control vs. Treatment):
- Completion: 65.2% → 84.8% (+19.6%) ✅
- Time-to-insight: 15.2s → 7.9s (-7.3s, -48%) ✅
- Statistical significance: p < 0.001 ✅

Guardrails:
✅ Error rate <5% (actual: 1.8%)
✅ P95 extraction <10s (actual: 9.2s)
✅ Lighthouse Performance ≥85 (actual: 92)
✅ Lighthouse A11y ≥95 (actual: 100)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 RECOMMENDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Decision: ✅ KEEP (Ramp to 100%)

Rationale:
1. Hypothesis validated (time <8s ✅, completion near 85% ✅)
2. Statistically significant (p < 0.001, sample: 775 users)
3. All guardrails passed (error, perf, a11y)
4. Positive delta on all HEART dimensions
5. No user complaints

Action Plan:
1. Ramp feature flag to 100% (all users)
2. Systemize pattern:
   - Add "inline preview" to ui-inventory.md
   - Document "same-page flows reduce abandonment" in design-inspirations.md
   - Update a11y guide with progress announcements pattern
3. Monitor for 7 days (watch for regressions)
4. Archive experiment (close experiment.md)

Alternative (if FAIL):
- ITERATE: Reduce to 5%, refine based on feedback
- ROLLBACK: Set feature flag to 0%, revert to control

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 ARTIFACTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Detailed report: design/features/[feat]/results.md
Raw data: design/features/[feat]/results/*.json

Measurement sources:
- SQL queries: [N] queries executed
- Structured logs: [N] events parsed
- Lighthouse CI: [N] runs analyzed

All data accessible via Claude Code tools (no external dashboards required)
```

---

## QUALITY GATES

**Before returning, verify:**
- [ ] All SQL queries executed successfully
- [ ] Structured logs parsed (event counts, error rates, durations)
- [ ] Lighthouse data collected (if performance metric)
- [ ] Comparison to targets complete (actual vs. target per metric)
- [ ] Statistical significance calculated (if A/B test)
- [ ] Guardrails checked (all passed/failed documented)
- [ ] Recommendation clear (KEEP/ITERATE/ROLLBACK + rationale)
- [ ] results.md complete (all sections filled)

**Reject if:**
- ❌ Insufficient sample size (<100 users per variant)
- ❌ Measurement window too short (<7 days for weekly metrics)
- ❌ Missing data sources (SQL or logs incomplete)
- ❌ No comparison to targets (can't determine pass/fail)

---

## NOTES

**Measurement cadence**: Run after 7-14 days (enough data for statistical power)

**Sample size**: Minimum 385 users per variant (calculated for 15% MDE, 80% power, α=0.05)

**Statistical tests**:
- Categorical (completion rate): Chi-square test
- Continuous (time-to-insight): T-test (or Mann-Whitney if non-normal)
- Use Python scipy.stats if needed (export data → calculate)

**Confidence levels**:
- p < 0.05: Significant ✅
- p < 0.10: Marginally significant ⚠️
- p ≥ 0.10: Not significant ❌

**What if data missing?**
- SQL fails: Check if `feature_metrics` table exists, instrumentation shipped
- Logs empty: Check if dual instrumentation implemented (PostHog + logs)
- Lighthouse fails: Ensure dev server running (`pnpm dev`)

---

**Command Version**: 1.0
**Last Updated**: 2025-10-05

