# Experiment Design: [Feature Name]

**Feature**: `[feature-slug]`
**Hypothesis**: [Prediction with magnitude]
**Created**: [DATE]
**Status**: [Planning | Running | Completed | Rolled Back]

---

## Hypothesis

**Problem**: [Current pain point with evidence]
- Evidence: [Metrics, logs, user feedback]
- Impact: [Who affected, how often]

**Solution**: [Proposed change]
- Change: [Specific UI/UX modification]
- Mechanism: [Why this should work]

**Prediction**: [Specific, measurable outcome]
- Primary metric: [e.g., Time-to-insight <8s (currently 15s)]
- Expected improvement: [e.g., -47% reduction]
- Confidence: [Low | Medium | High]

---

## Example: AKTR Inline Upload

**Problem**: Upload → redirect → wait causes 25% abandonment
- Evidence: Logs show 25% of users never reach results page after upload
- Impact: Students abandon before seeing weak areas (core value prop)

**Solution**: Inline preview (no redirect) with real-time progress
- Change: Upload → preview → extract on same screen
- Mechanism: Reduces cognitive load, provides instant feedback

**Prediction**: Time-to-first-code <8s will reduce abandonment to <10%
- Primary metric: Task completion rate +20% (65% → 85%)
- Expected improvement: -47% time-to-insight (15s → 8s)
- Confidence: High (similar pattern works in design-inspirations.md)

---

## Variants

### Control (Baseline)
**Description**: Current experience (redirect flow)
- Upload screen → POST /api/extract → redirect → results page
- No progress indicator during extraction
- User sees blank screen 5-15s

**Implementation**: Existing `/aktr/upload` route
**Feature flag**: N/A (always served to control group)
**Metrics baseline**:
- Task completion: 65%
- Time-to-insight: 15s (median)
- Abandonment: 25%

### Treatment (Experiment)
**Description**: Inline preview with real-time progress
- Upload → inline preview → extract button → progress bar → results (same screen)
- WebSocket updates for extraction progress
- User stays on same URL throughout

**Implementation**: `/aktr/upload?variant=inline`
**Feature flag**: `aktr_inline_preview` (boolean, off by default)
**Metrics target**:
- Task completion: 85% (+20%)
- Time-to-insight: 8s (-47%)
- Abandonment: <10% (-15%)

---

## Sample Size & Duration

**Statistical Parameters**:
- Significance level: α = 0.05 (95% confidence)
- Power: 1-β = 0.80 (80% chance to detect effect)
- Minimum detectable effect: 15% relative improvement
- Expected baseline conversion: 65%

**Sample Size** (per variant):
```
n = 2 * (Z_α/2 + Z_β)² * p(1-p) / (MDE)²
n = 2 * (1.96 + 0.84)² * 0.65(1-0.65) / (0.15)²
n ≈ 385 users per variant
Total needed: 770 users
```

**Duration**:
- Daily traffic: ~50 users/day (anonymous + authenticated)
- Days needed: 770 / 50 = 15.4 days
- **Planned duration**: 21 days (3 weeks, includes buffer)
- **Start date**: [YYYY-MM-DD]
- **End date**: [YYYY-MM-DD]

---

## Ramp Plan

**Phase 1: Internal (Days 1-3)**
- Audience: Team only (manual feature flag override)
- Traffic: ~10 users
- Goal: Catch critical bugs, validate instrumentation

**Phase 2: 5% (Days 4-7)**
- Audience: Random 5% of new sessions
- Traffic: ~15 users
- Goal: Validate A/B split, monitor error rates
- **Kill switch trigger**: Error rate >5% OR P95 >15s

**Phase 3: 25% (Days 8-14)**
- Audience: Random 25% of new sessions
- Traffic: ~400 users (50% control, 50% treatment across 25% bucket)
- Goal: Accumulate statistical power
- **Kill switch trigger**: Error rate >3% OR negative trend on guardrails

**Phase 4: 50% (Days 15-21)**
- Audience: Random 50% of new sessions
- Traffic: ~525 users total
- Goal: Reach significance, validate at scale
- **Decision point**: Day 21 (keep, iterate, or rollback)

**Phase 5: 100% (Days 22+)**
- Audience: All users
- Goal: Full rollout if Phase 4 shows positive results
- Fallback: Instant rollback if production issues

---

## Instrumentation Plan

### Events to Track

**Control Group**:
```javascript
// Upload screen
posthog.capture('upload.page_view', { variant: 'control' });
posthog.capture('upload.file_selected', { variant: 'control', file_size: bytes });
posthog.capture('upload.submitted', { variant: 'control' });

// Results screen (after redirect)
posthog.capture('results.page_view', { variant: 'control', duration_from_upload: ms });
posthog.capture('results.first_code_visible', { variant: 'control', time_to_insight: ms });
```

**Treatment Group**:
```javascript
// All on same screen
posthog.capture('upload.page_view', { variant: 'treatment' });
posthog.capture('upload.file_selected', { variant: 'treatment', file_size: bytes });
posthog.capture('upload.preview_shown', { variant: 'treatment', preview_time: ms });
posthog.capture('upload.extract_clicked', { variant: 'treatment' });
posthog.capture('upload.extraction_progress', { variant: 'treatment', percent: 50 });
posthog.capture('upload.first_code_visible', { variant: 'treatment', time_to_insight: ms });
```

### Database Tracking (feature_metrics)

**Schema**:
```sql
INSERT INTO feature_metrics (feature, variant, user_id, outcome, value, metadata, created_at)
VALUES (
  'aktr_inline_preview',
  'treatment',  -- or 'control'
  '[user_id or session_id]',
  'time_to_insight',
  7854,  -- milliseconds
  '{"file_size": 2457600, "extraction_method": "vision"}',
  NOW()
);
```

**Outcomes tracked**:
- `time_to_insight` (ms from upload to first code visible)
- `task_completion` (boolean: reached results?)
- `abandonment` (boolean: left before completion?)
- `error_occurred` (boolean: any errors?)
- `extraction_duration` (ms for API call only)

### Structured Logs (logs/metrics/)

**Format** (JSON Lines):
```json
{"event":"upload.first_code_visible","variant":"treatment","time_to_insight":7854,"user_id":"anon_abc123","timestamp":1704124800000}
{"event":"upload.abandoned","variant":"control","duration_before_exit":3200,"user_id":"anon_xyz789","timestamp":1704124900000}
```

**Claude Code can parse**:
```bash
# Treatment group time-to-insight (P50, P95)
grep '"variant":"treatment"' logs/metrics/*.jsonl | \
  jq -r '.time_to_insight' | \
  sort -n | \
  awk '{a[NR]=$1} END {print "P50:", a[int(NR*0.5)], "P95:", a[int(NR*0.95)]}'
```

---

## Measurement Queries

### Task Completion Rate (SQL)

**Query** (`queries/task_completion.sql`):
```sql
SELECT
  variant,
  COUNT(*) FILTER (WHERE outcome = 'task_completion' AND value = 1) * 100.0 / COUNT(*) as completion_rate,
  COUNT(*) as sample_size
FROM feature_metrics
WHERE feature = 'aktr_inline_preview'
  AND created_at >= '[START_DATE]'
  AND created_at <= '[END_DATE]'
GROUP BY variant;
```

**Expected output**:
```
variant   | completion_rate | sample_size
----------|-----------------|------------
control   | 65.2            | 385
treatment | 84.8            | 385
```

### Time-to-Insight (SQL)

**Query** (`queries/time_to_insight.sql`):
```sql
SELECT
  variant,
  PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY value) as p50_ms,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY value) as p95_ms,
  AVG(value) as avg_ms,
  COUNT(*) as sample_size
FROM feature_metrics
WHERE feature = 'aktr_inline_preview'
  AND outcome = 'time_to_insight'
  AND created_at >= '[START_DATE]'
  AND created_at <= '[END_DATE]'
GROUP BY variant;
```

**Expected output**:
```
variant   | p50_ms | p95_ms | avg_ms | sample_size
----------|--------|--------|--------|------------
control   | 15200  | 28500  | 16800  | 385
treatment | 7900   | 12300  | 8400   | 385
```

### Statistical Significance (Chi-Square for completion, t-test for duration)

**Query** (`queries/significance.sql`):
```sql
-- Chi-square for task completion (categorical)
WITH variant_stats AS (
  SELECT
    variant,
    COUNT(*) FILTER (WHERE outcome = 'task_completion' AND value = 1) as successes,
    COUNT(*) as total
  FROM feature_metrics
  WHERE feature = 'aktr_inline_preview'
    AND created_at >= '[START_DATE]'
  GROUP BY variant
)
SELECT
  *,
  (successes * 1.0 / total) as rate,
  -- Claude will calculate chi-square manually or use Python scipy
  '[Run chi-square test in /measure-heart]' as significance
FROM variant_stats;

-- T-test for time-to-insight (continuous)
-- Export to CSV, run scipy.stats.ttest_ind in Python
COPY (
  SELECT variant, value as time_to_insight
  FROM feature_metrics
  WHERE feature = 'aktr_inline_preview'
    AND outcome = 'time_to_insight'
    AND created_at >= '[START_DATE]'
) TO STDOUT WITH CSV HEADER;
```

---

## Guardrails (Must Not Degrade)

| Metric | Baseline | Threshold | Kill Switch |
|--------|----------|-----------|-------------|
| Error rate | 2% | >5% | Immediate rollback |
| P95 extraction time | 10s | >15s | Immediate rollback |
| Server CPU | 40% | >80% | Throttle traffic |
| Memory usage | 60% | >85% | Throttle traffic |
| Anonymous conversion | 5% | <4% | Investigate, may rollback |

**Monitoring**:
- Errors: `grep -c '"event":"upload.error"' logs/metrics/$(date +%Y-%m-%d).jsonl`
- Performance: Lighthouse CI on `/aktr/upload` (both variants)
- Server: `docker stats api` (CPU, memory)

---

## Decision Criteria

**Keep (100% rollout)**:
- ✅ Task completion ≥+15% (p < 0.05)
- ✅ Time-to-insight ≤9s (P50, +50% acceptable miss)
- ✅ No guardrail violations
- ✅ Error rate <3%

**Iterate (partial rollback, refine)**:
- ⚠️ Positive trend but not significant (p > 0.05)
- ⚠️ One guardrail violated (investigate cause)
- ⚠️ Mixed results (completion up, time neutral)

**Rollback (revert to control)**:
- ❌ No improvement or negative (p > 0.10)
- ❌ Multiple guardrails violated
- ❌ User complaints/bug reports spike
- ❌ Error rate >5%

---

## Feature Flag Implementation

**Backend** (`api/app/core/config.py`):
```python
FEATURE_FLAGS = {
    "aktr_inline_preview": {
        "enabled": False,  # Master switch
        "rollout_percent": 0,  # 0-100
        "target_users": []  # Override for specific user IDs
    }
}
```

**Frontend** (`apps/app/lib/feature-flags.ts`):
```typescript
export function useFeatureFlag(flag: string): boolean {
  const { user } = useAuth();

  // Server-driven (PostHog, LaunchDarkly, or custom API)
  const flags = useFlags(); // From PostHog or custom hook

  return flags[flag] ?? false;
}

// Usage
const inlinePreview = useFeatureFlag('aktr_inline_preview');
```

**Assignment Strategy**:
- **Session-based**: Consistent variant for session duration (prevents flip-flopping)
- **User-based**: Authenticated users get consistent variant across sessions
- **Hash-based**: `hash(session_id) % 100 < rollout_percent`

---

## Rollback Plan

**Instant rollback** (if kill switch triggered):
```bash
# Set feature flag to 0%
curl -X PATCH /api/admin/feature-flags/aktr_inline_preview \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"rollout_percent": 0}'

# Redeploy without feature code (if flag insufficient)
git revert [FEATURE_COMMIT_SHA]
vercel --prod
```

**Graceful rollback** (if decision is "iterate"):
- Reduce to 5% while refining
- Document learnings in `design/features/[feat]/learnings.md`
- Plan v2 experiment

---

## Success Criteria Checklist

**Before launch**:
- [ ] Instrumentation tested (events fire to PostHog + logs + DB)
- [ ] SQL queries validated on staging data
- [ ] Feature flag works (0%, 5%, 25%, 50%, 100%)
- [ ] Kill switch tested (rollback from 25% → 0%)
- [ ] Guardrail alerts configured (error rate, P95, CPU)

**During experiment**:
- [ ] Daily check: error rates, guardrails
- [ ] Weekly check: sample size, early trends
- [ ] Day 7: Decide if safe to ramp 5% → 25%
- [ ] Day 14: Decide if safe to ramp 25% → 50%

**After experiment**:
- [ ] Run all measurement queries (task completion, time-to-insight, significance)
- [ ] Compare to hypothesis (did we hit targets?)
- [ ] Document in `results.md` (keep/iterate/rollback + why)
- [ ] If keep: Upstream pattern to design system

---

## Notes

- **Network effects**: If feature affects shared data (leaderboards, cohorts), use cluster/geo experiments
- **Spillover**: Anonymous → authenticated conversion might contaminate control if users switch mid-session
- **Novelty effect**: First week may show inflated results; focus on weeks 2-3 for stable trends

---

**Template Version**: 1.0
**Last Updated**: [ISO timestamp]
