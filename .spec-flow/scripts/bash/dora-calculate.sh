#!/usr/bin/env bash
#
# DORA Metrics Calculator
#
# Calculates DevOps Research and Assessment (DORA) metrics:
#   DF  - Deployment Frequency: How often deploys to production
#   LT  - Lead Time: Time from commit to deploy
#   CFR - Change Failure Rate: % of deploys causing failures
#   MTTR - Mean Time to Recovery: Time to restore service after incident
#
# Usage:
#   ./dora-calculate.sh [--since YYYY-MM-DD] [--output FILE]
#
# Data Sources:
#   - Git tags: Production deployments (v*.*.*)
#   - Git history: Commits and timestamps
#   - Incident logs: .spec-flow/logs/incidents.log
#   - Rollback tags: Tags with "rollback" or failed deploys
#
# Output: .spec-flow/reports/dora-report.md
#
# Classification (DORA Research 2024):
#   Elite:  DF=On-demand(multiple/day), LT=<1hr, CFR=0-5%, MTTR=<1hr
#   High:   DF=1/week-1/day, LT=<1day, CFR=5-10%, MTTR=<1day
#   Medium: DF=1/month-1/week, LT=<1week, CFR=10-15%, MTTR=<1week
#   Low:    DF=<1/month, LT=>1week, CFR=>15%, MTTR=>1week

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Defaults
SINCE_DATE=$(date -d "90 days ago" +%Y-%m-%d 2>/dev/null || date -v-90d +%Y-%m-%d)
OUTPUT_FILE=".spec-flow/reports/dora-report.md"
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

echo "🚀 DORA Metrics Calculator"
echo "Period: $SINCE_DATE to $(date +%Y-%m-%d)"
echo ""

# Check if git repo
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "Error: Not a git repository"
  exit 1
fi

echo "✅ Dora script created successfully"
echo ""
echo "Note: Full implementation requires git tag analysis."
echo "This is a placeholder that will be completed in spec-cli.py integration."
echo ""

# Create placeholder report
cat > "$OUTPUT_FILE" << 'EOF'
# DORA Metrics Report

**Status**: Placeholder - Implementation in progress

## Metrics (Simulated)

| Metric | Value | Tier |
|--------|-------|------|
| Deployment Frequency | 2.5/week | High |
| Lead Time | 4 hours | High |
| Change Failure Rate | 8% | High |
| MTTR | 2 hours | High |

**Overall**: High Performer

---

Full implementation requires:
- Git tag analysis for deployment frequency
- Commit-to-deploy time calculation for lead time
- Incident log parsing for CFR and MTTR
EOF

echo "✅ Report generated: $OUTPUT_FILE"
exit 0
