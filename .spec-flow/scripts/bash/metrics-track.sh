#!/usr/bin/env bash
#
# HEART Metrics Tracker
#
# Measures product success metrics from local sources:
#   H - Happiness: NPS score from user surveys
#   E - Engagement: DAU/MAU ratio from analytics
#   A - Adoption: New user signups from database
#   R - Retention: Cohort retention from user lifecycle
#   T - Task Success: Completion rate from telemetry
#
# Usage:
#   ./metrics-track.sh [--since YYYY-MM-DD] [--output FILE]
#
# Data Sources:
#   - Logs: .spec-flow/logs/analytics.log
#   - Database: Read from DATABASE_URL env var
#   - Surveys: .spec-flow/data/surveys.json
#   - Telemetry: .spec-flow/logs/telemetry.log
#
# Output: .spec-flow/reports/metrics-report.md

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Defaults
SINCE_DATE=$(date -d "30 days ago" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d)
OUTPUT_FILE=".spec-flow/reports/metrics-report.md"
REPORT_DIR=".spec-flow/reports"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --since)
      SINCE_DATE="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--since YYYY-MM-DD] [--output FILE]"
      exit 1
      ;;
  esac
done

# Create reports directory
mkdir -p "$REPORT_DIR"

echo "📊 HEART Metrics Tracker"
echo "Period: $SINCE_DATE to $(date +%Y-%m-%d)"
echo ""

# ============================================================================
# H - Happiness (NPS Score)
# ============================================================================

calculate_happiness() {
  local nps_score=0
  local survey_file=".spec-flow/data/surveys.json"

  if [ -f "$survey_file" ]; then
    # Parse NPS from surveys.json
    # NPS = % Promoters (9-10) - % Detractors (0-6)
    local promoters=$(jq '[.surveys[] | select(.rating >= 9)] | length' "$survey_file" 2>/dev/null || echo "0")
    local detractors=$(jq '[.surveys[] | select(.rating <= 6)] | length' "$survey_file" 2>/dev/null || echo "0")
    local total=$(jq '.surveys | length' "$survey_file" 2>/dev/null || echo "1")

    if [ "$total" -gt 0 ]; then
      nps_score=$(awk "BEGIN {printf \"%.1f\", (($promoters - $detractors) / $total) * 100}")
    fi

    echo "$nps_score"
  else
    echo "N/A"
  fi
}

# ============================================================================
# E - Engagement (DAU/MAU Ratio)
# ============================================================================

calculate_engagement() {
  local analytics_log=".spec-flow/logs/analytics.log"
  local dau_mau_ratio="N/A"

  if [ -f "$analytics_log" ]; then
    # Extract DAU (unique users in last 24 hours)
    local dau=$(grep "user_active" "$analytics_log" | \
                awk -v since="$SINCE_DATE" '$1 >= since' | \
                awk '{print $3}' | sort -u | wc -l)

    # Extract MAU (unique users in last 30 days)
    local mau=$(grep "user_active" "$analytics_log" | \
                awk '{print $3}' | sort -u | wc -l)

    if [ "$mau" -gt 0 ]; then
      dau_mau_ratio=$(awk "BEGIN {printf \"%.2f\", ($dau / $mau) * 100}")
    fi

    echo "$dau_mau_ratio%"
  else
    echo "N/A"
  fi
}

# ============================================================================
# A - Adoption (New User Signups)
# ============================================================================

calculate_adoption() {
  local signups="N/A"

  # Try to read from database if DATABASE_URL is set
  if [ -n "${DATABASE_URL:-}" ]; then
    # Example: PostgreSQL query for new signups
    # signups=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM users WHERE created_at >= '$SINCE_DATE'")
    echo "DB integration needed"
  else
    # Fallback: Read from local analytics log
    local analytics_log=".spec-flow/logs/analytics.log"
    if [ -f "$analytics_log" ]; then
      signups=$(grep "user_signup" "$analytics_log" | \
                awk -v since="$SINCE_DATE" '$1 >= since' | wc -l)
      echo "$signups"
    else
      echo "N/A"
    fi
  fi
}

# ============================================================================
# R - Retention (30-Day Cohort Retention)
# ============================================================================

calculate_retention() {
  local retention_rate="N/A"
  local analytics_log=".spec-flow/logs/analytics.log"

  if [ -f "$analytics_log" ]; then
    # Calculate 30-day cohort retention
    # Users who signed up 30 days ago and are still active today
    local cohort_date=$(date -d "30 days ago" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d)

    local cohort_users=$(grep "user_signup" "$analytics_log" | \
                        awk -v date="$cohort_date" '$1 == date' | \
                        awk '{print $3}' | sort -u)

    local cohort_size=$(echo "$cohort_users" | wc -l)

    if [ "$cohort_size" -gt 0 ]; then
      local retained=0
      while IFS= read -r user; do
        # Check if user was active in last 7 days
        if grep -q "user_active.*$user" "$analytics_log"; then
          ((retained++))
        fi
      done <<< "$cohort_users"

      retention_rate=$(awk "BEGIN {printf \"%.1f\", ($retained / $cohort_size) * 100}")
    fi

    echo "$retention_rate%"
  else
    echo "N/A"
  fi
}

# ============================================================================
# T - Task Success (Completion Rate)
# ============================================================================

calculate_task_success() {
  local success_rate="N/A"
  local telemetry_log=".spec-flow/logs/telemetry.log"

  if [ -f "$telemetry_log" ]; then
    # Calculate task completion rate from telemetry
    local tasks_started=$(grep "task_started" "$telemetry_log" | \
                         awk -v since="$SINCE_DATE" '$1 >= since' | wc -l)

    local tasks_completed=$(grep "task_completed" "$telemetry_log" | \
                           awk -v since="$SINCE_DATE" '$1 >= since' | wc -l)

    if [ "$tasks_started" -gt 0 ]; then
      success_rate=$(awk "BEGIN {printf \"%.1f\", ($tasks_completed / $tasks_started) * 100}")
    fi

    echo "$success_rate%"
  else
    echo "N/A"
  fi
}

# ============================================================================
# Load Targets from capacity-planning.md
# ============================================================================

load_targets() {
  local capacity_doc="docs/project/capacity-planning.md"
  local happiness_target="N/A"
  local engagement_target="N/A"
  local adoption_target="N/A"
  local retention_target="N/A"
  local task_success_target="N/A"

  if [ -f "$capacity_doc" ]; then
    # Parse targets from capacity planning doc
    # Expected format: "NPS Target: 50" or "DAU/MAU Target: 25%"
    happiness_target=$(grep -i "NPS Target" "$capacity_doc" | grep -oE '[0-9]+' | head -1 || echo "50")
    engagement_target=$(grep -i "DAU/MAU Target" "$capacity_doc" | grep -oE '[0-9]+' | head -1 || echo "25")
    adoption_target=$(grep -i "New User Target" "$capacity_doc" | grep -oE '[0-9]+' | head -1 || echo "100")
    retention_target=$(grep -i "Retention Target" "$capacity_doc" | grep -oE '[0-9]+' | head -1 || echo "70")
    task_success_target=$(grep -i "Task Success Target" "$capacity_doc" | grep -oE '[0-9]+' | head -1 || echo "85")
  else
    # Default targets if no capacity doc
    happiness_target="50"
    engagement_target="25"
    adoption_target="100"
    retention_target="70"
    task_success_target="85"
  fi

  echo "$happiness_target $engagement_target $adoption_target $retention_target $task_success_target"
}

# ============================================================================
# Calculate All Metrics
# ============================================================================

echo "Calculating metrics..."
echo ""

happiness=$(calculate_happiness)
engagement=$(calculate_engagement)
adoption=$(calculate_adoption)
retention=$(calculate_retention)
task_success=$(calculate_task_success)

# Load targets
read -r happiness_target engagement_target adoption_target retention_target task_success_target <<< "$(load_targets)"

# ============================================================================
# Compare Against Targets
# ============================================================================

compare_metric() {
  local current="$1"
  local target="$2"
  local name="$3"

  # Remove % sign if present
  current_val=$(echo "$current" | sed 's/%//')
  target_val=$(echo "$target" | sed 's/%//')

  # Skip if N/A
  if [ "$current" == "N/A" ]; then
    echo "⚠️  $name: $current (target: $target%) - No data"
    return
  fi

  # Compare
  if (( $(echo "$current_val >= $target_val" | bc -l) )); then
    echo -e "${GREEN}✅ $name: $current (target: $target%)${NC}"
  else
    echo -e "${RED}❌ $name: $current (target: $target%)${NC}"
  fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "HEART Metrics Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

compare_metric "$happiness" "$happiness_target" "Happiness (NPS)"
compare_metric "$engagement" "$engagement_target" "Engagement (DAU/MAU)"
echo "  Adoption (New Users): $adoption (target: $adoption_target)"
compare_metric "$retention" "$retention_target" "Retention (30-day)"
compare_metric "$task_success" "$task_success_target" "Task Success"

echo ""

# ============================================================================
# Generate Markdown Report
# ============================================================================

cat > "$OUTPUT_FILE" <<EOF
# HEART Metrics Report

**Generated**: $(date +%Y-%m-%d\ %H:%M:%S)
**Period**: $SINCE_DATE to $(date +%Y-%m-%d)

---

## Summary

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| **H**appiness (NPS) | $happiness | ${happiness_target}% | $([ "$happiness" != "N/A" ] && (( $(echo "${happiness%\%} >= $happiness_target" | bc -l) )) && echo "✅" || echo "❌") |
| **E**ngagement (DAU/MAU) | $engagement | ${engagement_target}% | $([ "$engagement" != "N/A" ] && (( $(echo "${engagement%\%} >= $engagement_target" | bc -l) )) && echo "✅" || echo "❌") |
| **A**doption (New Users) | $adoption | $adoption_target | $([ "$adoption" != "N/A" ] && (( $adoption >= $adoption_target )) && echo "✅" || echo "❌") |
| **R**etention (30-day) | $retention | ${retention_target}% | $([ "$retention" != "N/A" ] && (( $(echo "${retention%\%} >= $retention_target" | bc -l) )) && echo "✅" || echo "❌") |
| **T**ask Success | $task_success | ${task_success_target}% | $([ "$task_success" != "N/A" ] && (( $(echo "${task_success%\%} >= $task_success_target" | bc -l) )) && echo "✅" || echo "❌") |

---

## Detailed Metrics

### Happiness (NPS Score)

**Current**: $happiness
**Target**: ${happiness_target}%

**Definition**: Net Promoter Score from user surveys (% Promoters - % Detractors)

**Data Source**: \`.spec-flow/data/surveys.json\`

**Calculation**:
- Promoters (9-10 rating): $([[ -f ".spec-flow/data/surveys.json" ]] && jq '[.surveys[] | select(.rating >= 9)] | length' .spec-flow/data/surveys.json || echo "N/A")
- Detractors (0-6 rating): $([[ -f ".spec-flow/data/surveys.json" ]] && jq '[.surveys[] | select(.rating <= 6)] | length' .spec-flow/data/surveys.json || echo "N/A")

---

### Engagement (DAU/MAU Ratio)

**Current**: $engagement
**Target**: ${engagement_target}%

**Definition**: Daily Active Users / Monthly Active Users * 100

**Data Source**: \`.spec-flow/logs/analytics.log\`

**Interpretation**:
- <10%: Low engagement, users don't return frequently
- 10-20%: Moderate engagement, occasional use
- 20-40%: Good engagement, regular use
- >40%: Excellent engagement, daily habit

---

### Adoption (New User Signups)

**Current**: $adoption new users
**Target**: $adoption_target new users

**Definition**: Count of new user signups in reporting period

**Data Source**: Database (DATABASE_URL) or \`.spec-flow/logs/analytics.log\`

**Growth Rate**: $([ "$adoption" != "N/A" ] && echo "$((adoption * 100 / adoption_target))%" || echo "N/A") of target

---

### Retention (30-Day Cohort)

**Current**: $retention
**Target**: ${retention_target}%

**Definition**: % of users from 30-day-old cohort still active today

**Data Source**: \`.spec-flow/logs/analytics.log\`

**Interpretation**:
- <40%: Poor retention, users churning quickly
- 40-60%: Moderate retention, room for improvement
- 60-80%: Good retention, product stickiness
- >80%: Excellent retention, strong value proposition

---

### Task Success (Completion Rate)

**Current**: $task_success
**Target**: ${task_success_target}%

**Definition**: % of started tasks that are completed successfully

**Data Source**: \`.spec-flow/logs/telemetry.log\`

**Interpretation**:
- <70%: Poor UX, users struggling to complete tasks
- 70-85%: Moderate success rate, some friction
- 85-95%: Good UX, tasks are intuitive
- >95%: Excellent UX, frictionless experience

---

## Recommendations

$(
if [ "$happiness" != "N/A" ] && (( $(echo "${happiness%\%} < $happiness_target" | bc -l) )); then
  echo "- **Happiness**: NPS below target. Survey recent detractors to identify pain points."
fi

if [ "$engagement" != "N/A" ] && (( $(echo "${engagement%\%} < $engagement_target" | bc -l) )); then
  echo "- **Engagement**: DAU/MAU below target. Add features that encourage daily use (notifications, streaks, fresh content)."
fi

if [ "$adoption" != "N/A" ] && (( $adoption < $adoption_target )); then
  echo "- **Adoption**: New signups below target. Improve onboarding, referral programs, marketing."
fi

if [ "$retention" != "N/A" ] && (( $(echo "${retention%\%} < $retention_target" | bc -l) )); then
  echo "- **Retention**: 30-day retention below target. Improve first-week experience, send re-engagement emails."
fi

if [ "$task_success" != "N/A" ] && (( $(echo "${task_success%\%} < $task_success_target" | bc -l) )); then
  echo "- **Task Success**: Completion rate below target. Simplify UX, add guidance, fix error states."
fi
)

---

## Data Sources

- **Surveys**: \`.spec-flow/data/surveys.json\`
- **Analytics**: \`.spec-flow/logs/analytics.log\`
- **Database**: \`DATABASE_URL\` environment variable
- **Telemetry**: \`.spec-flow/logs/telemetry.log\`
- **Targets**: \`docs/project/capacity-planning.md\`

## Next Steps

1. Review metrics against targets
2. Identify metrics below target
3. Prioritize improvements based on impact
4. Re-run metrics monthly to track progress

---

**Generated by**: Spec-Flow Metrics Tracker
**Command**: \`/metrics\` or \`bash .spec-flow/scripts/bash/metrics-track.sh\`
EOF

echo "✅ Report generated: $OUTPUT_FILE"
echo ""
echo "View report:"
echo "  cat $OUTPUT_FILE"
echo ""

exit 0
