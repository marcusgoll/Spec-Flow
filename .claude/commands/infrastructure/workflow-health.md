---
name: workflow-health
description: Display workflow health dashboard with velocity trends, quality metrics, and improvement tracking
argument-hint: [--detailed | --trends | --compare]
allowed-tools: [Read, Grep, Glob]
version: 5.0
updated: 2025-11-19
---

# /workflow-health — Workflow Health Dashboard

**Purpose**: Aggregate metrics across all completed epics to show workflow system health, velocity trends, and continuous improvement effectiveness.

**Command**: `/workflow-health [--detailed | --trends | --compare]`

**When to use**:

- Check workflow system health across all epics
- Identify velocity trends over time
- Measure ROI of workflow improvements
- Compare epic performance

---

<instructions>

## Workflow Health Analysis

### Step 1: Discover Completed Epics

**Scan for all epic workspaces:**

```bash
EPIC_DIRS=$(find epics -maxdepth 1 -type d -name '[0-9]*' | sort)
EPIC_COUNT=$(echo "$EPIC_DIRS" | wc -l)
```

**Filter for completed epics:**

```bash
COMPLETED_EPICS=()
for dir in $EPIC_DIRS; do
  if grep -q "status: completed" "$dir/state.yaml"; then
    COMPLETED_EPICS+=("$dir")
  fi
done

COMPLETED_COUNT=${#COMPLETED_EPICS[@]}
```

### Step 2: Aggregate Core Metrics

**For each completed epic, extract:**

```javascript
const epicMetrics = [];

for (const epicDir of completedEpics) {
  const state = readYAML(`${epicDir}/state.yaml`);
  const audit = readXML(`${epicDir}/audit-report.xml`); // if exists
  const walkthrough = readXML(`${epicDir}/walkthrough.md`); // if exists

  epicMetrics.push({
    number: extractNumber(epicDir),
    slug: extractSlug(epicDir),
    start_date: state.created_at,
    end_date: state.completed_at,
    duration_hours: calculateDuration(state),
    velocity_multiplier: audit?.velocity_impact?.actual_multiplier || "N/A",
    sprint_count: state.sprints?.length || 0,
    tasks_completed: state.tasks_completed || 0,
    quality_score: audit?.overall_score || "N/A",
    improvements_applied: countHealingReports(epicDir),
  });
}
```

### Step 3: Calculate Aggregate Statistics

**Velocity trends:**

```javascript
const velocityStats = {
  average: calculateAverage(epicMetrics.map((e) => e.velocity_multiplier)),
  trend: calculateTrend(epicMetrics.map((e) => e.velocity_multiplier)),
  best: Math.max(...epicMetrics.map((e) => e.velocity_multiplier)),
  worst: Math.min(...epicMetrics.map((e) => e.velocity_multiplier)),
};

// Trend calculation
// Positive = improving over time
// Negative = degrading over time
const trend = linearRegression(
  epicMetrics.map((e, i) => ({ x: i, y: e.velocity_multiplier }))
).slope;
```

**Quality trends:**

```javascript
const qualityStats = {
  average: calculateAverage(epicMetrics.map((e) => e.quality_score)),
  trend: calculateTrend(epicMetrics.map((e) => e.quality_score)),
  passing_rate:
    epicMetrics.filter((e) => e.quality_score >= 80).length /
    epicMetrics.length,
};
```

**Duration trends:**

```javascript
const durationStats = {
  average_hours: calculateAverage(epicMetrics.map((e) => e.duration_hours)),
  trend: calculateTrend(epicMetrics.map((e) => e.duration_hours)),
  total_hours: sum(epicMetrics.map((e) => e.duration_hours)),
};
```

**Improvement effectiveness:**

```javascript
const improvementStats = {
  total_improvements_applied: sum(
    epicMetrics.map((e) => e.improvements_applied)
  ),
  average_per_epic: calculateAverage(
    epicMetrics.map((e) => e.improvements_applied)
  ),
  epics_with_improvements: epicMetrics.filter((e) => e.improvements_applied > 0)
    .length,
};
```

### Step 4: Display Dashboard

**Default view (summary):**

```
Workflow Health Dashboard
═══════════════════════════════════════════════════════════════

📊 OVERVIEW
────────────────────────────────────────────────────────────────
Total Epics Completed: 5
Total Work Hours: 180h
Average Epic Duration: 36h
Total Improvements Applied: 12

🚀 VELOCITY
────────────────────────────────────────────────────────────────
Average Velocity Multiplier: 3.6x
Best: 4.5x (003-dashboard-epic)
Worst: 2.8x (001-auth-epic)
Trend: ↗ +0.3x per epic (improving)

✅ QUALITY
────────────────────────────────────────────────────────────────
Average Quality Score: 87/100 (B+)
Passing Rate (≥80): 100% (5/5)
Trend: ↗ +2 points per epic (improving)

⏱️ DURATION
────────────────────────────────────────────────────────────────
Average Duration: 36h
Trend: ↘ -4h per epic (improving)

Epic Timeline:
001-auth-epic       ████████████████████ 48h (v3.2x, q85)
002-payments-epic   ████████████████     40h (v3.5x, q86)
003-dashboard-epic  █████████████        32h (v4.5x, q90)
004-api-v2-epic     ████████████         30h (v3.8x, q88)
005-notifications   ██████████           24h (v4.0x, q89)

🔧 CONTINUOUS IMPROVEMENT
────────────────────────────────────────────────────────────────
Improvements Applied: 12 total (2.4 avg per epic)
Epics with Improvements: 5/5 (100%)

Improvement Categories:
  Phase modifications:    5 (42%)
  Gate adjustments:       3 (25%)
  Custom skills:          2 (17%)
  Config changes:         2 (17%)

ROI: High (avg 2.5h saved per epic per improvement)

📈 TRENDS SUMMARY
────────────────────────────────────────────────────────────────
✓ Velocity:   Improving (+0.3x per epic)
✓ Quality:    Improving (+2 pts per epic)
✓ Duration:   Improving (-4h per epic)
✓ Adoption:   100% of epics using workflow

Health Status: ✅ HEALTHY

────────────────────────────────────────────────────────────────
Run with --detailed for per-epic breakdown
Run with --trends for historical charts
Run with --compare to compare epic performance
```

### Step 5: Detailed View (--detailed flag)

**Per-epic breakdown:**

```
Epic Detailed Analysis
═══════════════════════════════════════════════════════════════

001: auth-epic
────────────────────────────────────────────────────────────────
Duration: 48h (2025-11-01 to 2025-11-03)
Sprints: 3 (S01, S02, S03)
Tasks: 28 completed
Velocity: 3.2x (below avg 3.6x)
Quality: 85/100 (B, below avg 87)

Phase Breakdown:
  Specification:    2.0h  (4.2%)
  Clarification:    1.5h  (3.1%)
  Planning:         3.0h  (6.2%)
  Tasks:            0.5h  (1.0%)
  Implementation:   38h   (79.2%) ← bottleneck
  Optimization:     2.0h  (4.2%)
  Preview:          1.0h  (2.1%)

Bottlenecks:
  ⚠ Implementation: 79% of total time
  ⚠ Sprint S02 underestimated (12h vs 6h)

Improvements Applied: 2
  - Adaptive clarification (saved 45min on next epic)
  - Auto-skip preview (saved 1.5h on backend epics)

Strengths:
  ✓ Contract-locking prevented integration bugs
  ✓ Research phase identified OAuth 2.1 early

Lessons Learned:
  → Frontend tasks need 1.8x estimation multiplier
  → Lock contracts before parallel work

────────────────────────────────────────────────────────────────

002: payments-epic
────────────────────────────────────────────────────────────────
... (similar breakdown)

────────────────────────────────────────────────────────────────
```

### Step 6: Trends View (--trends flag)

**Historical trend charts:**

```
Velocity Trend (Last 5 Epics)
═══════════════════════════════════════════════════════════════

 5.0x │
      │                                    ●  ●
 4.5x │                         ●
      │
 4.0x │                    ●
      │
 3.5x │               ●
      │
 3.0x │          ●
      │
 2.5x │
      └────────────────────────────────────────────────
         001   002   003   004   005    Epic

Trend: ↗ +0.3x per epic (linear regression)
Forecast (next 3 epics): 4.3x, 4.6x, 4.9x

────────────────────────────────────────────────────────────────

Quality Trend (Last 5 Epics)
═══════════════════════════════════════════════════════════════

100  │                                      ●
     │                                 ●  ●
 90  │                            ●
     │
 85  │                    ●
     │
 80  │          ●
     │
 75  │
     └────────────────────────────────────────────────
         001   002   003   004   005    Epic

Trend: ↗ +2 points per epic
Forecast (next 3 epics): 91, 93, 95

────────────────────────────────────────────────────────────────

Duration Trend (Last 5 Epics)
═══════════════════────────────════════────────────────════════

50h  │    ●
     │
45h  │
     │        ●
40h  │
     │            ●
35h  │                ●
     │
30h  │                    ●
     │
25h  │
     └────────────────────────────────────────────────
         001   002   003   004   005    Epic

Trend: ↘ -4h per epic (improving)
Forecast (next 3 epics): 20h, 16h, 12h

────────────────────────────────────────────────────────────────
```

### Step 7: Comparison View (--compare flag)

**Compare epic performance:**

```
Epic Comparison Matrix
═══════════════════════════════════════════════════════════════

                  001    002    003    004    005    Avg
                  auth   pay    dash   api    notif
────────────────────────────────────────────────────────────────
Duration (h)      48     40     32     30     24     34.8
Velocity (x)      3.2    3.5    4.5    3.8    4.0    3.8
Quality (/100)    85     86     90     88     89     87.6
Sprints           3      4      2      3      2      2.8
Tasks             28     35     18     24     16     24.2
Improvements      2      3      2      3      2      2.4
────────────────────────────────────────────────────────────────

Best Performers:
🥇 Velocity:  003-dashboard-epic (4.5x)
🥇 Quality:   003-dashboard-epic (90/100)
🥇 Speed:     005-notifications (24h)

Most Improved:
📈 001 → 005: Velocity +0.8x (3.2x → 4.0x)
📈 001 → 005: Quality +4pts (85 → 89)
📈 001 → 005: Duration -24h (48h → 24h) = 50% faster

Pattern Analysis:
✓ Smaller epics (≤3 sprints) consistently faster
✓ UI-heavy epics benefit most from preview auto-skip
✓ Contract-first approach improves with each epic

────────────────────────────────────────────────────────────────
```

### Step 8: Health Alerts

**Detect workflow health issues:**

```javascript
const alerts = [];

// Velocity degradation
if (velocityStats.trend < 0) {
  alerts.push({
    severity: "warning",
    category: "velocity",
    message: `Velocity declining by ${Math.abs(velocityStats.trend)}x per epic`,
    recommendation: "Run /audit-workflow to identify bottlenecks",
  });
}

// Quality degradation
if (qualityStats.trend < 0) {
  alerts.push({
    severity: "warning",
    category: "quality",
    message: `Quality score declining by ${Math.abs(
      qualityStats.trend
    )} pts per epic`,
    recommendation: "Review quality gates effectiveness",
  });
}

// Duration increasing
if (durationStats.trend > 0) {
  alerts.push({
    severity: "warning",
    category: "duration",
    message: `Epic duration increasing by ${durationStats.trend}h per epic`,
    recommendation: "Check for scope creep or estimation issues",
  });
}

// Low improvement adoption
if (improvementStats.average_per_epic < 1) {
  alerts.push({
    severity: "info",
    category: "improvement",
    message: "Low improvement adoption rate",
    recommendation: "Consider running /heal-workflow more frequently",
  });
}
```

**Display alerts:**

```
⚠️ HEALTH ALERTS
────────────────────────────────────────────────────────────────
No critical issues detected

💡 RECOMMENDATIONS
────────────────────────────────────────────────────────────────
✓ Workflow is healthy - maintain current practices
→ Consider applying 3 deferred improvements from past audits
→ Next milestone: Achieve 5.0x velocity average

────────────────────────────────────────────────────────────────
```

### Step 9: Export Options

**Offer data export:**

```
Export workflow health data?

1. Export to CSV (for spreadsheet analysis)
2. Export to JSON (for programmatic access)
3. Generate PDF report (for stakeholders)
4. No export
```

**CSV export example:**

```csv
epic_number,slug,start_date,end_date,duration_hours,velocity_multiplier,sprint_count,tasks_completed,quality_score,improvements_applied
001,auth-epic,2025-11-01,2025-11-03,48,3.2,3,28,85,2
002,payments-epic,2025-11-04,2025-11-06,40,3.5,4,35,86,3
...
```

</instructions>

---

## Success Criteria

- All completed epics discovered and loaded
- Core metrics aggregated across all epics
- Velocity, quality, and duration trends calculated
- Dashboard displayed with appropriate level of detail
- Health alerts generated if issues detected
- Comparison view shows relative performance
- Historical trends visualized with forecasts
- Export options offered for data analysis

---

## Anti-Hallucination Rules

1. **Only include completed epics**
   Check state.yaml status before including in metrics.

2. **Calculate trends from actual data**
   Use linear regression, don't estimate trends.

3. **Don't invent metrics not in artifacts**
   All metrics must come from state.yaml, audit-report.xml, or walkthrough.md.

4. **Show N/A for missing data**
   If audit report doesn't exist, show 'N/A', don't fabricate scores.

5. **Quote file sources for all metrics**
   Each metric should be traceable to source artifact.

---

## Integration Points

**Aggregates data from:**

- `epics/*/state.yaml` (phase timing, completion status)
- `epics/*/audit-report.xml` (velocity, quality scores)
- `epics/*/healing-report.xml` (improvements applied)
- `epics/*/walkthrough.md` (lessons learned)

**Used by:**

- Project stakeholders (progress reporting)
- Developers (workflow effectiveness validation)
- `/heal-workflow` (improvement prioritization)

---

## References

- [DORA Metrics](https://dora.dev) - Delivery velocity benchmarks
- [Perpetual Learning](docs/references/perpetual-learning.md) - Self-improvement system
