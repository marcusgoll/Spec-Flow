---
name: audit-workflow
description: Audit workflow effectiveness and generate improvement recommendations after epic completion
argument-hint: [epic-slug | auto]
allowed-tools: [Read, Grep, Glob, Task, Write]
version: 5.0
updated: 2025-11-19
---

# /audit-workflow — Workflow Effectiveness Analysis

**Purpose**: Analyze completed epic workflow to identify bottlenecks, quality issues, and improvement opportunities. Auto-runs after /implement and /finalize phases.

**Command**: `/audit-workflow [epic-slug | auto]`

**When to use**:

- Auto-triggered after `/implement` completes
- Auto-triggered during `/optimize` phase
- Auto-triggered after `/finalize` for post-mortem
- Manual invocation to analyze current epic

---

<instructions>

## Workflow Audit Process

### Step 1: Locate Epic Workspace

**If epic-slug provided:**

```bash
EPIC_DIR="epics/$ARGUMENTS"
```

**If "auto" or no argument:**

```bash
# Find most recent epic
EPIC_DIR=$(ls -td epics/*/ | head -1)
```

**Validate workspace exists:**

```bash
test -d "$EPIC_DIR" && echo "found" || echo "not found"
```

If not found, error: "No epic workspace found. Run /epic first."

### Step 2: Read Epic Artifacts

**Load all epic data for analysis:**

```bash
# Core artifacts
- epic-spec.md (requirements)
- state.yaml (phase tracking)
- sprint-plan.md (dependencies, execution plan)
- tasks.md (task breakdown)
- research.md (research findings)
- plan.md (architecture plan)

# Execution artifacts
- NOTES.md (implementation notes)
- sprints/*/implementation logs
- optimization-report.xml (quality gates)
```

**Extract key metrics:**

- Total phases completed
- Time spent per phase
- Tasks completed vs total
- Quality gate pass/fail rates
- Sprint execution times
- Parallel execution efficiency

### Step 3: Analyze Workflow Effectiveness

**Analysis focus areas** (execute inline - no agent delegation):

1. **Phase efficiency** - time vs value delivered per phase
2. **Bottleneck detection** - which phases took longest
3. **Quality gate effectiveness** - caught issues early?
4. **Sprint parallelization** - actual vs potential speedup
5. **Documentation quality** - XML artifacts complete?
6. **Process adherence** - skipped phases, manual overrides

**Output target:** `audit-report.xml` with findings and recommendations

### Step 4: Bottleneck Detection

**Analyze phase timing:**

```yaml
# From state.yaml
phases:
  specification:
    duration: 2h
    value_score: high
  clarification:
    duration: 1.5h
    value_score: high
  planning:
    duration: 3h
    value_score: high
  tasks:
    duration: 0.5h
    value_score: medium
  implementation:
    duration: 24h # BOTTLENECK: 70% of total time
    value_score: high
  optimization:
    duration: 2h
    value_score: medium
```

**Calculate bottleneck score:**

```
Bottleneck = (phase_duration / total_duration) * (1 / value_score)

If bottleneck_score > 0.5: Flag as major bottleneck
If bottleneck_score > 0.3: Flag as moderate bottleneck
```

**Example findings:**

- "Implementation phase is 70% of total time but high value - acceptable"
- "Clarification phase is 10% of time but low value - consider better upfront spec"
- "Optimization phase caught 0 critical issues - gate may be redundant"

### Step 5: Sprint Parallelization Analysis

**Compare actual vs potential:**

```xml
<sprint_analysis>
  <potential_speedup>
    <sequential_hours>48</sequential_hours>
    <parallel_hours>16</parallel_hours>
    <max_speedup>3.0x</max_speedup>
  </potential_speedup>

  <actual_speedup>
    <sequential_hours>48</sequential_hours>
    <parallel_hours>12</parallel_hours>
    <actual_speedup>4.0x</actual_speedup>
  </actual_speedup>

  <efficiency>
    <percentage>133%</percentage> <!-- exceeded expectations -->
    <reason>S02 and S03 had fewer dependencies than estimated</reason>
  </efficiency>

  <missed_opportunities>
    <!-- Were there sprints that could have run parallel but didn't? -->
    <opportunity sprint_a="S04" sprint_b="S05">
      <reason>Dependency analysis missed that these are independent</reason>
      <potential_time_saved_hours>6</potential_time_saved_hours>
    </opportunity>
  </missed_opportunities>
</sprint_analysis>
```

### Step 6: Quality Gate Effectiveness

**Analyze which gates caught issues:**

```xml
<quality_gate_analysis>
  <gate name="tests" phase="implementation">
    <issues_caught>12</issues_caught>
    <severity_critical>0</severity_critical>
    <severity_high>3</severity_high>
    <severity_medium>9</severity_medium>
    <effectiveness>high</effectiveness>
    <recommendation>Continue - catching issues early</recommendation>
  </gate>

  <gate name="security" phase="optimize">
    <issues_caught>2</issues_caught>
    <severity_critical>0</severity_critical>
    <severity_high>0</severity_high>
    <severity_medium>2</severity_medium>
    <effectiveness>medium</effectiveness>
    <recommendation>Continue - provides safety net</recommendation>
  </gate>

  <gate name="preview" phase="preview">
    <issues_caught>0</issues_caught>
    <manual_time_hours>1.5</manual_time_hours>
    <effectiveness>low</effectiveness>
    <recommendation>Consider auto-skip for non-UI epics</recommendation>
  </gate>
</quality_gate_analysis>
```

### Step 7: Documentation Quality Assessment

**Check XML artifact completeness:**

```javascript
const artifacts = [
  'epic-spec.md',
  'research.md',
  'plan.md',
  'sprint-plan.md',
  'tasks.md'
];

for (const artifact of artifacts) {
  checkCompleteness(artifact, {
    required_tags: [...],
    metadata_present: true,
    references_valid: true
  });
}
```

**Score documentation:**

- Complete (all tags present): 10 pts
- Missing optional tags: -1 pt each
- Missing required tags: -5 pts each
- Broken references: -2 pts each
- Total score: /10

### Step 8: Pattern Detection

**Identify recurring patterns across epics:**

```javascript
// If this is 2nd or 3rd epic, analyze patterns
if (completed_epics >= 2) {
  detectPatterns({
    code_patterns: [
      "Service class structure",
      "Repository pattern usage",
      "Error handling approach",
      "Validation logic",
    ],
    workflow_patterns: [
      "Always clarify authentication approaches",
      "Always research database options",
      "Backend sprints consistently underestimated",
    ],
    tooling_opportunities: [
      "Generate service boilerplate (detected 3x)",
      "Auto-create CRUD endpoints (detected 5x)",
      "Standard error middleware (copied 4x)",
    ],
  });
}
```

**Suggest custom skills:**

```xml
<pattern_detection>
  <pattern id="service-boilerplate" frequency="3" confidence="high">
    <description>All services follow DI + Repository pattern</description>
    <suggestion>
      <type>custom_skill</type>
      <name>create-service-boilerplate</name>
      <benefit>Save 30min per service, ensure consistency</benefit>
      <effort>2 hours to build skill</effort>
    </suggestion>
  </pattern>

  <pattern id="api-crud" frequency="5" confidence="high">
    <description>CRUD endpoints follow OpenAPI contract pattern</description>
    <suggestion>
      <type>custom_command</type>
      <name>/generate-crud</name>
      <benefit>Save 1h per entity, prevent contract violations</benefit>
      <effort>3 hours to build command</effort>
    </suggestion>
  </pattern>
</pattern_detection>
```

### Step 9: Generate Audit Report

**Create audit-report.xml:**

```xml
<audit_report>
  <metadata>
    <epic_slug>{{EPIC_SLUG}}</epic_slug>
    <audit_timestamp>{{TIMESTAMP}}</audit_timestamp>
    <auditor_version>5.0</auditor_version>
  </metadata>

  <overall_score>
    <score>85</score> <!-- out of 100 -->
    <grade>B+</grade>
    <summary>
      Strong execution with 4x velocity improvement. Main opportunity:
      reduce clarification phase overhead with better upfront specifications.
    </summary>
  </overall_score>

  <phase_efficiency>
    <!-- For each phase, include efficiency metrics -->
  </phase_efficiency>

  <bottlenecks>
    <!-- Major, moderate, minor bottlenecks -->
  </bottlenecks>

  <sprint_parallelization>
    <!-- Actual vs potential speedup analysis -->
  </sprint_parallelization>

  <quality_gate_effectiveness>
    <!-- Which gates caught issues -->
  </quality_gate_effectiveness>

  <documentation_quality>
    <!-- XML artifact completeness scores -->
  </documentation_quality>

  <pattern_detection>
    <!-- Recurring patterns and tooling opportunities -->
  </pattern_detection>

  <recommendations>
    <immediate priority="high">
      <!-- Action items for next epic -->
    </immediate>

    <short_term priority="medium">
      <!-- Improvements for next 2-3 epics -->
    </short_term>

    <long_term priority="low">
      <!-- Strategic workflow improvements -->
    </long_term>
  </recommendations>

  <custom_tooling_suggestions>
    <!-- Project-specific skills/commands to generate -->
  </custom_tooling_suggestions>
</audit_report>
```

### Step 10: Present Findings

**Display summary:**

```
Epic Workflow Audit Complete
────────────────────────────────────────

Epic: 001-auth-epic
Overall Score: 85/100 (B+)

Velocity: 4.0x (exceeded 3.0x target by 33%)

Top 3 Strengths:
✓ Parallel sprint execution saved 36h
✓ Contract-locking prevented integration bugs
✓ Meta-prompting research identified OAuth 2.1 early

Top 3 Opportunities:
⚠ Clarification phase overhead (1.5h for simple questions)
⚠ Preview gate caught 0 issues but took 1.5h (consider auto-skip)
⚠ Sprint S02 underestimated by 100% (12h vs 6h estimated)

Pattern Detection:
🔍 Detected 3 code generation opportunities
🔍 Suggested 2 custom skills: create-service-boilerplate, generate-crud

Recommendations:
→ Immediate: Improve sprint estimation for frontend work
→ Short-term: Build custom service boilerplate skill
→ Long-term: Add auto-skip logic for preview gate on non-UI epics

Full report: epics/001-auth-epic/audit-report.xml
```

**Offer next actions:**

```
What would you like to do?

1. Review detailed audit report
2. Apply recommended improvements via /heal-workflow
3. Generate suggested custom skills
4. Continue to next phase
5. Other
```

</instructions>

---

## Success Criteria

- Epic workspace located and validated
- All artifacts read and parsed
- Phase efficiency calculated for each phase
- Bottlenecks identified with severity scores
- Sprint parallelization analyzed (actual vs potential)
- Quality gates effectiveness measured
- Documentation quality assessed
- Pattern detection performed (if 2+ epics completed)
- audit-report.xml generated with actionable recommendations
- Summary presented with next-step options

---

## Anti-Hallucination Rules

1. **Always read state.yaml for actual phase durations**
   Never estimate or guess timing - use recorded timestamps.

2. **Calculate metrics from data, don't invent scores**
   All scores must be derived from measurable data.

3. **Pattern detection requires 2+ completed epics**
   Don't suggest patterns from single epic.

4. **Custom tooling suggestions must show frequency**
   Only suggest if pattern detected 3+ times.

5. **Quote specific examples from artifacts**
   When citing issues, include file:line references.

---

## Integration Points

**Auto-triggered by:**

- `/implement` (after all sprints complete)
- `/optimize` (during quality gate phase)
- `/finalize` (post-mortem analysis)

**Outputs used by:**

- `/heal-workflow` (applies approved improvements)
- `/workflow-health` (aggregates metrics across epics)
- Pattern analyzer (detects custom tooling opportunities)

---

## References

- [DORA Metrics](https://dora.dev) - Delivery velocity and quality
- [Pattern Detection Documentation](docs/references/perpetual-learning.md)
