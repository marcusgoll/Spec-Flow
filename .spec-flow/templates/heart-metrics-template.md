# HEART Metrics: [Feature Name]

**Feature**: `[feature-slug]`
**Created**: [DATE]
**Measurement Window**: 7 days (rolling)

---

## HEART Framework

> **Goal**: Define measurable success criteria using Google's HEART framework.
> **Constraint**: All metrics MUST be Claude Code-measurable (logs, DB queries, Lighthouse, no external dashboards).

### Metrics Table

| Dimension | Goal | Signal | Metric | Target | Guardrail | Measurement Source |
|-----------|------|--------|--------|--------|-----------|-------------------|
| **Happiness** | [User satisfaction outcome] | [Observable behavior] | [Quantified measure] | [e.g., <2% error rate] | [Don't harm: e.g., P95 <500ms] | `grep -c 'level":"error' logs/errors/*.json` |
| **Engagement** | [Depth of interaction] | [Usage pattern] | [Frequency/duration] | [e.g., 3+ sessions/week] | [Max: e.g., <5min session] | `SELECT AVG(duration_sec) FROM feature_metrics WHERE...` |
| **Adoption** | [New user activation] | [First-time usage] | [Signup/conversion rate] | [e.g., +20% signups] | [Cost: <$5 CAC] | `SELECT COUNT(*) FROM users WHERE created_at >= ...` |
| **Retention** | [Repeat usage] | [Return visits] | [7-day return rate] | [e.g., 40% return] | [Churn: <10%/month] | `SELECT COUNT(DISTINCT user_id) FROM user_sessions WHERE...` |
| **Task Success** | [Core job completed] | [Completion event] | [Success rate] | [e.g., 85% complete] | [Time: <30s P95] | `grep 'event":"[feature].completed' logs/metrics/*.jsonl \| wc -l` |

---

## Example: AKTR Upload Redesign

| Dimension | Goal | Signal | Metric | Target | Guardrail | Measurement Source |
|-----------|------|--------|--------|--------|-----------|-------------------|
| **Happiness** | Reduce upload errors | Error-free uploads | Error rate | <2% (was 5%) | P95 response time <10s | `grep -c '"event":"upload.error"' logs/metrics/$(date +%Y-%m-%d).jsonl` |
| **Engagement** | Increase feature usage | Upload frequency | Uploads per user per week | 2+ (was 1.2) | Session duration <5min | `SELECT user_id, COUNT(*) FROM feature_metrics WHERE feature='aktr_upload' AND created_at >= NOW() - INTERVAL '7 days' GROUP BY user_id` |
| **Adoption** | Drive free → paid conversion | First upload to subscribe | Conversion rate | +15% (5% → 5.75%) | Cost per conversion <$10 | `SELECT COUNT(*) FROM users WHERE plan='paid' AND created_at >= ...` |
| **Retention** | Keep users coming back | Return within 7 days | 7-day return rate | 40% (was 25%) | Churn <10%/month | `SELECT COUNT(DISTINCT user_id) / (SELECT COUNT(*) FROM users WHERE created_at < NOW() - INTERVAL '7 days') FROM user_sessions WHERE created_at >= NOW() - INTERVAL '7 days'` |
| **Task Success** | Faster time-to-insight | Upload → first ACS code visible | Time-to-first-code | <8s (was 15s) | Extraction P95 <10s | `SELECT AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) FROM extraction_logs WHERE created_at >= NOW() - INTERVAL '7 days'` |

---

## Performance Metrics (Lighthouse CI)

**FCP (First Contentful Paint)**: <1.5s
**TTI (Time to Interactive)**: <3.5s
**CLS (Cumulative Layout Shift)**: <0.1
**LCP (Largest Contentful Paint)**: <2.5s

**Measurement**:
```bash
lhci collect --url="http://localhost:3000/[feature-url]" --numberOfRuns=5
cat .lighthouseci/results/*.json | jq '{
  fcp: .audits["first-contentful-paint"].numericValue,
  tti: .audits.interactive.numericValue,
  cls: .audits["cumulative-layout-shift"].numericValue,
  lcp: .audits["largest-contentful-paint"].numericValue
}'
```

---

## Hypothesis

**Problem**: [Current pain point with evidence]
**Solution**: [Proposed change]
**Prediction**: [Specific improvement with magnitude]

**Example**:
- **Problem**: 15s average time-to-insight causes 25% abandonment (logs show 25% never reach results)
- **Solution**: Inline preview (no redirect) + progress indicator
- **Prediction**: Time-to-insight <8s will reduce abandonment to <10% (+15% task completion)

---

## Measurement Queries

### SQL Queries (save to `design/features/[feat]/queries/`)

**Task Success Rate** (`task_success.sql`):
```sql
SELECT
  DATE(created_at) as date,
  COUNT(*) FILTER (WHERE outcome = 'success') * 100.0 / COUNT(*) as success_rate
FROM feature_metrics
WHERE feature = '[feature-slug]'
  AND created_at >= NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date;
```

**A/B Test Results** (`ab_test.sql`):
```sql
SELECT
  variant,
  COUNT(*) as sample_size,
  AVG(value) as avg_outcome,
  STDDEV(value) as stddev
FROM feature_metrics
WHERE feature = '[feature-slug]'
  AND outcome = '[metric-name]'
  AND created_at >= NOW() - INTERVAL '7 days'
GROUP BY variant;
```

### Log Patterns (structured JSON logs)

**Event Count** (task completion):
```bash
grep '"event":"[feature].completed"' logs/metrics/*.jsonl | wc -l
```

**Error Rate**:
```bash
total=$(grep '"feature":"[feature-slug]"' logs/metrics/$(date +%Y-%m-%d).jsonl | wc -l)
errors=$(grep '"event":"[feature].error"' logs/metrics/$(date +%Y-%m-%d).jsonl | wc -l)
echo "scale=2; ($errors / $total) * 100" | bc
```

**Duration (P95)**:
```bash
grep '"event":"[feature].completed"' logs/metrics/*.jsonl | \
  jq -r '.duration' | \
  sort -n | \
  awk '{a[NR]=$1} END {print a[int(NR*0.95)]}'
```

---

## Quality Gates

**Before `/design-variations`**:
- [ ] All HEART dimensions have targets defined
- [ ] Measurement sources are Claude Code-accessible (SQL, logs, Lighthouse)
- [ ] Hypothesis is specific and testable
- [ ] Guardrails protect against regressions

**After `/measure-heart`**:
- [ ] All metrics collected successfully
- [ ] Results compared to targets (pass/fail)
- [ ] Recommendation: Keep / Iterate / Rollback
- [ ] Winning patterns upstreamed to design system (if keep)

---

## Notes

**Data Collection Setup**:
1. Dual instrumentation: PostHog (dashboards) + JSON logs (Claude measurement)
2. Database tracking: `feature_metrics` table for A/B tests
3. Server timing: Response headers for API performance
4. Lighthouse CI: Automated performance checks in CI/CD

**Measurement Cadence**:
- Daily: Error rates, performance (Lighthouse)
- Weekly: HEART metrics (7-day rolling window)
- Per-release: A/B test results, comparison to baseline

---

**Template Version**: 1.0
**Last Updated**: [ISO timestamp]
