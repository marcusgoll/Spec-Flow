#!/usr/bin/env bash
# Feature Classification Engine
# Analyzes feature description and outputs classification flags
#
# Usage: classify-feature.sh "feature description"
# Output: JSON with classification flags
#
# Flags:
#   HAS_UI - Feature involves user interface components
#   IS_IMPROVEMENT - Enhancement to existing functionality (vs new feature)
#   HAS_METRICS - Feature involves analytics, tracking, or KPIs
#   HAS_DEPLOYMENT_IMPACT - Feature affects infrastructure, CI/CD, or deployment

set -uo pipefail

# Color output
BLUE='\033[0;34m'
NC='\033[0m'

# Input validation
if [ -z "${1:-}" ]; then
    echo '{"error": "No feature description provided", "HAS_UI": false, "IS_IMPROVEMENT": false, "HAS_METRICS": false, "HAS_DEPLOYMENT_IMPACT": false}'
    exit 1
fi

DESCRIPTION="$1"
DESCRIPTION_LOWER=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]')

# Classification keywords (pipe-separated regex patterns)
UI_KEYWORDS="ui|frontend|component|form|modal|button|dashboard|page|screen|view|dialog|menu|navbar|sidebar|tab|panel|card|input|dropdown|checkbox|radio|toggle|slider|tooltip|notification|toast|popup|overlay|layout|responsive|mobile|desktop|theme|style|css|tailwind|animation|transition"

IMPROVEMENT_KEYWORDS="improve|enhance|optimize|refactor|fix|update|upgrade|better|faster|cleaner|simplify|streamline|modernize|migrate|consolidate|reduce|increase|boost|performance|speed|efficiency"

METRICS_KEYWORDS="metric|analytics|track|measure|kpi|dashboard|report|insight|statistic|counter|gauge|histogram|telemetry|observability|monitor|alert|threshold|trend|chart|graph|visualization|data.point|aggregate|rollup"

DEPLOY_KEYWORDS="deploy|infrastructure|docker|kubernetes|k8s|ci|cd|pipeline|env|environment|staging|production|rollback|blue.green|canary|health.check|load.balancer|nginx|aws|gcp|azure|vercel|railway|heroku|terraform|ansible|helm|github.actions|workflow"

# Classification functions
classify_ui() {
    if echo "$DESCRIPTION_LOWER" | grep -qiE "$UI_KEYWORDS"; then
        echo "true"
    else
        echo "false"
    fi
}

classify_improvement() {
    if echo "$DESCRIPTION_LOWER" | grep -qiE "$IMPROVEMENT_KEYWORDS"; then
        echo "true"
    else
        echo "false"
    fi
}

classify_metrics() {
    if echo "$DESCRIPTION_LOWER" | grep -qiE "$METRICS_KEYWORDS"; then
        echo "true"
    else
        echo "false"
    fi
}

classify_deployment() {
    if echo "$DESCRIPTION_LOWER" | grep -qiE "$DEPLOY_KEYWORDS"; then
        echo "true"
    else
        echo "false"
    fi
}

# Calculate confidence based on keyword match count
calculate_confidence() {
    local keywords="$1"
    local count
    count=$(echo "$DESCRIPTION_LOWER" | grep -oiE "$keywords" | wc -l | tr -d ' ')

    if [ "$count" -ge 3 ]; then
        echo "high"
    elif [ "$count" -ge 1 ]; then
        echo "medium"
    else
        echo "low"
    fi
}

# Run classification
HAS_UI=$(classify_ui)
IS_IMPROVEMENT=$(classify_improvement)
HAS_METRICS=$(classify_metrics)
HAS_DEPLOYMENT_IMPACT=$(classify_deployment)

# Calculate confidence scores
UI_CONFIDENCE=$(calculate_confidence "$UI_KEYWORDS")
IMPROVEMENT_CONFIDENCE=$(calculate_confidence "$IMPROVEMENT_KEYWORDS")
METRICS_CONFIDENCE=$(calculate_confidence "$METRICS_KEYWORDS")
DEPLOY_CONFIDENCE=$(calculate_confidence "$DEPLOY_KEYWORDS")

# Determine recommended workflow
RECOMMENDED_WORKFLOW="standard"
if [ "$HAS_UI" = "true" ] && [ "$UI_CONFIDENCE" != "low" ]; then
    RECOMMENDED_WORKFLOW="ui-first"
fi

# Output JSON
cat << EOF
{
  "description": "$DESCRIPTION",
  "flags": {
    "HAS_UI": $HAS_UI,
    "IS_IMPROVEMENT": $IS_IMPROVEMENT,
    "HAS_METRICS": $HAS_METRICS,
    "HAS_DEPLOYMENT_IMPACT": $HAS_DEPLOYMENT_IMPACT
  },
  "confidence": {
    "ui": "$UI_CONFIDENCE",
    "improvement": "$IMPROVEMENT_CONFIDENCE",
    "metrics": "$METRICS_CONFIDENCE",
    "deployment": "$DEPLOY_CONFIDENCE"
  },
  "recommended_workflow": "$RECOMMENDED_WORKFLOW"
}
EOF
