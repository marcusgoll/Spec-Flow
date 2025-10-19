# Skill Update Mechanism

This document explains how to integrate automatic skill updates into workflow commands.

## Overview

Each workflow command should detect noteworthy events (mistakes, successful patterns, threshold exceedances) and update the corresponding skill file automatically. This enables the workflow to learn and improve over time.

## Update Trigger Points

### Specification Phase (`/specify`)

**Location**: End of `/specify` command, before RETURN statement

**Triggers**:
```bash
# Count clarifications
CLARIFICATIONS=$(grep -c "\[NEEDS CLARIFICATION" specs/$SLUG/spec.md)

# Update skill if threshold exceeded
if [ $CLARIFICATIONS -gt 3 ]; then
  # Increment frequency counter
  SKILL_FILE=".claude/skills/specification-phase/SKILL.md"
  CURRENT_FREQ=$(grep "Frequency:" "$SKILL_FILE" | grep "Over-Clarification" | sed 's/.*(\([0-9]\).*/\1/')
  NEW_FREQ=$((CURRENT_FREQ + 1))

  # Update last seen date
  TODAY=$(date +%Y-%m-%d)

  # Update skill file (this is pseudo-code - actual implementation may vary)
  # sed -i "s/Frequency: ★☆☆☆☆ ($CURRENT_FREQ/Frequency: ★★☆☆☆ ($NEW_FREQ/" "$SKILL_FILE"
  # sed -i "s/Last seen: Never/Last seen: $TODAY/" "$SKILL_FILE"
fi
```

**Thresholds**:
- Clarifications >3 → Update "Over-Clarification" pitfall
- Classification mismatch → Update "Wrong Classification" pitfall
- Roadmap slug not found → Update "Roadmap Slug Mismatch" pitfall

---

### Clarification Phase (`/clarify`)

**Location**: End of `/clarify` command, after spec.md integration

**Triggers**:
```bash
# Count questions
QUESTION_COUNT=$(grep -c "^## Question" specs/$SLUG/clarifications.md)

# Check if spec integration complete
REMAINING_MARKERS=$(grep -c "\[NEEDS CLARIFICATION" specs/$SLUG/spec.md)

# Update skill if issues detected
if [ $QUESTION_COUNT -gt 3 ] || [ $REMAINING_MARKERS -gt 0 ]; then
  SKILL_FILE=".claude/skills/clarification-phase/SKILL.md"
  # Update frequency counters and last seen dates
fi
```

**Thresholds**:
- Questions >3 → Update "Too Many Questions" pitfall
- Compound questions detected → Update "Vague Questions" pitfall
- `[NEEDS CLARIFICATION]` markers remain → Update "Missing Integration" pitfall

---

### Planning Phase (`/plan`)

**Location**: End of `/plan` command, after plan.md created

**Triggers**:
```bash
# Count research tools used (approximate from logs)
RESEARCH_TOOLS=$(grep -c "Grep\|Glob\|Read" plan-generation.log 2>/dev/null || echo 0)

# Check for reuse strategy documentation
REUSE_MENTIONED=$(grep -c "Reuse Strategy\|reuse\|existing" specs/$SLUG/plan.md)

# Update skill if thresholds not met
if [ $RESEARCH_TOOLS -lt 5 ] || [ $REUSE_MENTIONED -lt 2 ]; then
  SKILL_FILE=".claude/skills/planning-phase/SKILL.md"
  # Update metrics or patterns
fi
```

**Thresholds**:
- Research tools <5 → Update "Insufficient Research" pitfall
- Reuse strategy missing → Update "Missing Reuse" pitfall

---

### Task Breakdown Phase (`/tasks`)

**Location**: End of `/tasks` command, after tasks.md created

**Triggers**:
```bash
# Check task sizes
grep -E "Complexity: (high|very high)" specs/$SLUG/tasks.md | while read -r line; do
  echo "⚠️  Large task detected: $line"
  # Update skill file
done

# Check acceptance criteria
TASKS_WITH_AC=$(grep -c "### Acceptance Criteria" specs/$SLUG/tasks.md)
TOTAL_TASKS=$(grep -c "^### Task" specs/$SLUG/tasks.md)

if [ $TASKS_WITH_AC -lt $TOTAL_TASKS ]; then
  SKILL_FILE=".claude/skills/task-breakdown-phase/SKILL.md"
  # Update "Missing Acceptance Criteria" pitfall
fi
```

**Thresholds**:
- High/very high complexity tasks → Update "Tasks Too Large" pitfall
- Tasks missing acceptance criteria → Update "Missing AC" pitfall

---

### Analysis Phase (`/analyze`)

**Location**: End of `/analyze` command, after analysis-report.md created

**Triggers**:
```bash
# Check for inconsistencies found
INCONSISTENCIES=$(grep -c "❌ Inconsistency" specs/$SLUG/analysis-report.md)

# Check for breaking changes
BREAKING_CHANGES=$(grep -c "⚠️ Breaking change" specs/$SLUG/analysis-report.md)

# Update skill metrics
SKILL_FILE=".claude/skills/analysis-phase/SKILL.md"
# Log inconsistencies and breaking changes found
```

**Thresholds**:
- Inconsistencies found → Log count in metrics
- Breaking changes detected → Log count in metrics

---

### Implementation Phase (`/implement`)

**Location**: During task execution, after each task completes

**Triggers**:
```bash
# Check if tests exist for implementation
IMPL_FILES=$(find specs/$SLUG -name "*.py" -not -path "*/tests/*")
for impl_file in $IMPL_FILES; do
  test_file=$(echo "$impl_file" | sed 's/app/tests/' | sed 's/.py/_test.py/')
  if [ ! -f "$test_file" ]; then
    SKILL_FILE=".claude/skills/implementation-phase/SKILL.md"
    # Update "Implementation Without Tests" pitfall
  fi
done

# Check for duplicate code
# (can use tools like jscpd or manual grep patterns)
```

**Thresholds**:
- Test file missing for implementation → Update "Missing Tests" pitfall
- Duplicate code detected → Update "Duplicate Code" pitfall

---

### Optimization Phase (`/optimize`)

**Location**: End of `/optimize` command, after checks complete

**Triggers**:
```bash
# Check performance benchmarks
# (pseudo-code - actual implementation depends on tooling)
RESPONSE_TIME=$(curl -w "%{time_total}" -s -o /dev/null http://localhost:3000/api/endpoint)
if (( $(echo "$RESPONSE_TIME > 0.5" | bc -l) )); then
  SKILL_FILE=".claude/skills/optimization-phase/SKILL.md"
  # Update "Performance Target Missed" pitfall
fi

# Check Lighthouse score
LIGHTHOUSE_SCORE=$(lighthouse http://localhost:3000 --only-categories=accessibility --output=json | jq '.categories.accessibility.score')
if (( $(echo "$LIGHTHOUSE_SCORE < 0.95" | bc -l) )); then
  SKILL_FILE=".claude/skills/optimization-phase/SKILL.md"
  # Update "Accessibility Failures" pitfall
fi
```

**Thresholds**:
- API response time >500ms → Update "Performance Target Missed"
- Lighthouse score <95 → Update "Accessibility Failures"

---

### Debug Phase (`/debug`)

**Location**: End of `/debug` command, after error-log.md updated

**Triggers**:
```bash
# Check for recurring errors
ERROR_MSG="$1"  # Error message being debugged
COUNT=$(grep -c "$ERROR_MSG" error-log.md)

if [ $COUNT -gt 2 ]; then
  SKILL_FILE=".claude/skills/debug-phase/SKILL.md"
  # Update "Recurring Errors" pitfall
fi

# Check if error entry has required fields
ERROR_ENTRY=$(grep -A 10 "## Error" error-log.md | tail -10)
if ! echo "$ERROR_ENTRY" | grep -q "Date\|Component\|Steps to Reproduce"; then
  SKILL_FILE=".claude/skills/debug-phase/SKILL.md"
  # Update "Insufficient Error Context" pitfall
fi
```

**Thresholds**:
- Error seen >2 times → Update "Recurring Errors" pitfall
- Error entry missing required fields → Update "Insufficient Context" pitfall

---

### Preview Phase (`/preview`)

**Location**: End of `/preview` command, after manual testing

**Triggers**:
```bash
# Checklist validation (user confirms)
# Update skill based on issues found during preview
# (This is typically manual - user reports issues)
```

---

### Staging Validation Phase (Manual gate)

**Location**: During `/phase-1-ship` validation gate

**Triggers**:
```bash
# Check if validation steps completed
# Update skill based on validation outcomes
```

---

### Staging Deployment Phase (`/phase-1-ship`)

**Location**: End of `/phase-1-ship` command, after deployment

**Triggers**:
```bash
# Check deployment success
if ! grep -q "Deployment successful" deploy.log; then
  SKILL_FILE=".claude/skills/staging-deployment-phase/SKILL.md"
  # Update deployment failure metrics
fi

# Check health endpoint
curl -f http://staging-url/health || {
  SKILL_FILE=".claude/skills/staging-deployment-phase/SKILL.md"
  # Update "Health Checks Not Configured" pitfall
}
```

**Thresholds**:
- Deployment failed → Update failure metrics
- Health check failed → Update "Missing Health Checks" pitfall

---

### Checks Phase (`/checks`)

**Location**: End of `/checks` command, after CI failures fixed

**Triggers**:
```bash
# Check failure type
FAILURE_TYPE=$(grep -m 1 "Error:" ci-output.log | sed 's/.*Error: //')

# Check if recurring
COUNT=$(grep -c "$FAILURE_TYPE" .github/workflows/*.log)
if [ $COUNT -gt 2 ]; then
  SKILL_FILE=".claude/skills/checks-phase/SKILL.md"
  # Update "Recurring Check Failures" pitfall
  # Add fix pattern to successful patterns
fi
```

**Thresholds**:
- Check failure seen >2 times → Update "Recurring Failures" pitfall

---

### Production Deployment Phase (`/phase-2-ship`)

**Location**: End of `/phase-2-ship` command, after production deployment

**Triggers**:
```bash
# Check deployment success
if ! grep -q "Production deployment successful" deploy.log; then
  SKILL_FILE=".claude/skills/production-deployment-phase/SKILL.md"
  # Update deployment failure metrics
fi

# Check if rollback plan documented
if ! grep -q "Rollback" specs/$SLUG/*ship-report.md; then
  SKILL_FILE=".claude/skills/production-deployment-phase/SKILL.md"
  # Update "Missing Rollback Plan" pitfall
fi
```

**Thresholds**:
- Production deployment failed → Update failure metrics
- Rollback plan missing → Update "Missing Rollback" pitfall

---

### Finalize Phase (`/finalize`)

**Location**: End of `/finalize` command, after workflow completion

**Triggers**:
```bash
# Check roadmap updated
if ! grep -q "### $SLUG" .spec-flow/memory/roadmap.md | grep -A 5 "Shipped"; then
  SKILL_FILE=".claude/skills/finalize-phase/SKILL.md"
  # Update "Roadmap Not Updated" pitfall
fi

# Check documentation complete
if [ ! -f "specs/$SLUG/release-notes.md" ]; then
  SKILL_FILE=".claude/skills/finalize-phase/SKILL.md"
  # Update "Incomplete Documentation" pitfall
fi
```

**Thresholds**:
- Roadmap not updated → Update "Roadmap Not Updated" pitfall
- Release notes missing → Update "Incomplete Documentation" pitfall

---

### Roadmap Integration (`/roadmap`)

**Location**: End of `/roadmap` command, after roadmap updates

**Triggers**:
```bash
# Check for out-of-sync features
grep -A 5 "## In Progress" .spec-flow/memory/roadmap.md | while read -r line; do
  SLUG=$(echo "$line" | grep "^### " | sed 's/### //')
  if [ -f "specs/$SLUG/*-ship-report.md" ]; then
    SKILL_FILE=".claude/skills/roadmap-integration/SKILL.md"
    # Update "Roadmap Out of Sync" pitfall
  fi
done
```

**Thresholds**:
- Shipped feature still in "In Progress" → Update "Out of Sync" pitfall
- Missing spec links → Update "Missing Links" pitfall

---

## Implementation Notes

### Frequency Counter Format

```markdown
**Frequency**: ★★★☆☆ (3/5 - seen occasionally)
```

- 0 occurrences: ★☆☆☆☆
- 1-2 occurrences: ★★☆☆☆
- 3-4 occurrences: ★★★☆☆
- 5-7 occurrences: ★★★★☆
- 8+ occurrences: ★★★★★

### Last Seen Date Format

```markdown
**Last seen**: 2025-01-15 (feature: student-progress-dashboard)
```

### Metrics Tracking

Update metrics table at end of each phase:

```bash
# Update metrics (pseudo-code)
# sed -i "s/| Avg clarifications | [0-9.]* |/| Avg clarifications | 2.3 |/" "$SKILL_FILE"
```

---

## Future Enhancements

1. **Automated frequency updates**: Script to parse skill files and update star ratings
2. **Metrics dashboard**: Aggregate skill metrics across all phases
3. **Trend analysis**: Plot metrics over time to show improvement
4. **Pattern suggestions**: AI-powered suggestions based on accumulated patterns

---

_This document serves as a reference for integrating skill updates into workflow commands. Actual implementation may vary based on command structure and available tooling._
