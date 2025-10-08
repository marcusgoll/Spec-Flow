---
description: Cross-artifact consistency analysis (review work and list what might be broken)
---

Analyze feature artifacts for consistency, coverage, and quality.

## MENTAL MODEL

**Workflow**:\spec-flow → clarify → plan → tasks → **analyze** → implement → optimize → debug → preview → phase-1-ship → validate-staging → phase-2-ship

**State machine:**
- Load artifacts → Scan issues → Generate report → Suggest next

**Auto-suggest:**
- When complete → `/implement` (if no critical issues) or Fix issues first

## LOAD FEATURE

**Get feature from argument or current branch:**

```bash
if [ -n "$ARGUMENTS" ]; then
  SLUG="$ARGUMENTS"
else
  SLUG=$(git branch --show-current)
fi

FEATURE_DIR="specs/$SLUG"
```

**Validate feature exists:**

```bash
if [ ! -d "$FEATURE_DIR" ]; then
  echo "❌ Feature not found: $FEATURE_DIR"
  echo "Available features:"
  ls specs/ | grep -v "archive"
  exit 1
fi

echo "✅ Feature loaded: $SLUG"
echo ""
```

## LOAD ARTIFACTS

**Load all feature artifacts:**

```bash
# Required files
SPEC_FILE="$FEATURE_DIR/spec.md"
PLAN_FILE="$FEATURE_DIR/plan.md"
TASKS_FILE="$FEATURE_DIR/tasks.md"

# Optional files
ERROR_LOG="$FEATURE_DIR/error-log.md"
POLISH_REPORT="$FEATURE_DIR/design/polish-report.md"
CRIT_FILE="$FEATURE_DIR/design/crit.md"
MIGRATION_PLAN="$FEATURE_DIR/migration-plan.md"
CONSTITUTION_FILE="\spec-flow/memory/constitution.md"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Loading artifacts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Validate required files exist
MISSING_FILES=()

if [ ! -f "$SPEC_FILE" ]; then
  MISSING_FILES+=("spec.md")
fi

if [ ! -f "$PLAN_FILE" ]; then
  MISSING_FILES+=("plan.md")
fi

if [ ! -f "$TASKS_FILE" ]; then
  MISSING_FILES+=("tasks.md")
fi

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
  echo "❌ Missing required files:"
  for file in "${MISSING_FILES[@]}"; do
    echo "    - $file"
  done
  echo ""
  echo "Run workflow:"
  echo "  1. \spec-flow $SLUG (if missing spec.md)"
  echo "  2. /plan $SLUG (if missing plan.md)"
  echo "  3. /tasks $SLUG (if missing tasks.md)"
  exit 1
fi

echo "✅ Required: spec.md, plan.md, tasks.md"
echo ""

# Check optional files
HAS_ERROR_LOG=false
HAS_UI_DESIGN=false
HAS_MIGRATIONS=false

if [ -f "$ERROR_LOG" ]; then
  echo "✅ error-log.md exists"
  HAS_ERROR_LOG=true
else
  echo "ℹ️  error-log.md not found (ok, will be created during implementation)"
fi

if [ -f "$POLISH_REPORT" ]; then
  echo "✅ polish-report.md exists (UI feature)"
  HAS_UI_DESIGN=true

  # Count polished screens
  POLISHED_SCREENS=$(find apps/web/mock/$SLUG -path "*/polished/page.tsx" 2>/dev/null | wc -l)
  echo "   Found $POLISHED_SCREENS polished screen(s)"
else
  echo "ℹ️  No polish-report.md (backend-only feature)"
fi

if [ -f "$MIGRATION_PLAN" ]; then
  echo "✅ migration-plan.md exists (schema changes)"
  HAS_MIGRATIONS=true
else
  echo "ℹ️  No migration-plan.md (no schema changes)"
fi

if [ -f "$CONSTITUTION_FILE" ]; then
  echo "✅ constitution.md available"
else
  echo "ℹ️  No constitution.md (skipping principle validation)"
fi

echo ""
```

## ANALYZE REQUIREMENT COVERAGE

**Extract requirements from spec.md:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Analyzing requirement coverage"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Extract functional requirements
FUNCTIONAL_REQS=$(sed -n '/^## Functional Requirements/,/^## /p' "$SPEC_FILE" | \
                  grep "^- " | \
                  sed 's/^- //')

FUNCTIONAL_COUNT=$(echo "$FUNCTIONAL_REQS" | grep -c "^" || echo 0)

if [ "$FUNCTIONAL_COUNT" -eq 0 ]; then
  echo "⚠️  No functional requirements found in spec.md"
  FUNCTIONAL_COUNT=0
else
  echo "Found $FUNCTIONAL_COUNT functional requirement(s)"
fi

# Extract NFRs
NFRS=$(sed -n '/^## Non-Functional Requirements/,/^## /p' "$SPEC_FILE" | \
       grep "^- " | \
       sed 's/^- //')

NFR_COUNT=$(echo "$NFRS" | grep -c "^" || echo 0)

if [ "$NFR_COUNT" -eq 0 ]; then
  echo "Found 0 non-functional requirements"
else
  echo "Found $NFR_COUNT non-functional requirement(s)"
fi

echo ""

# Map requirements to tasks
COVERED_REQS=0
UNCOVERED_REQS=()

echo "Mapping requirements to tasks..."
echo ""

# Create coverage map
COVERAGE_MAP="$FEATURE_DIR/coverage-map.tmp"

cat > "$COVERAGE_MAP" <<EOF
| Requirement | Covered | Task IDs | Notes |
|-------------|---------|----------|-------|
EOF

if [ "$FUNCTIONAL_COUNT" -gt 0 ]; then
  while IFS= read -r req; do
    [ -z "$req" ] && continue

    # Extract key terms from requirement (first 3 significant words)
    KEY_TERMS=$(echo "$req" | grep -oE "[A-Z][a-z]+|[0-9]+" | head -3 | tr '\n' ' ')

    # Search tasks.md for these terms
    MATCHING_TASKS=$(grep -n "T[0-9]\{3\}" "$TASKS_FILE" | \
                     grep -i "$KEY_TERMS" | \
                     grep -o "T[0-9]\{3\}" | \
                     tr '\n' ',' | \
                     sed 's/,$//')

    if [ -n "$MATCHING_TASKS" ]; then
      echo "| $(echo "$req" | head -c 50)... | ✅ | $MATCHING_TASKS | |" >> "$COVERAGE_MAP"
      ((COVERED_REQS++))
    else
      echo "| $(echo "$req" | head -c 50)... | ❌ | | No matching tasks |" >> "$COVERAGE_MAP"
      UNCOVERED_REQS+=("$req")
    fi
  done <<< "$FUNCTIONAL_REQS"
fi

if [ "$FUNCTIONAL_COUNT" -gt 0 ]; then
  COVERAGE_PERCENT=$(( COVERED_REQS * 100 / FUNCTIONAL_COUNT ))
else
  COVERAGE_PERCENT=0
fi

echo "Coverage: $COVERED_REQS/$FUNCTIONAL_COUNT ($COVERAGE_PERCENT%)"
echo ""

if [ ${#UNCOVERED_REQS[@]} -gt 0 ]; then
  echo "⚠️  Uncovered requirements:"
  for req in "${UNCOVERED_REQS[@]}"; do
    echo "    - $(echo "$req" | head -c 60)..."
  done
  echo ""
fi
```

## ANALYZE UI TASK COVERAGE

**If polished designs exist:**

```bash
if [ "$HAS_UI_DESIGN" = true ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎨 Analyzing UI task coverage"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # List polished screens
  POLISHED_SCREEN_FILES=$(find apps/web/mock/$SLUG -path "*/polished/page.tsx" 2>/dev/null)

  UI_COVERAGE_MAP="$FEATURE_DIR/ui-task-coverage.tmp"

  cat > "$UI_COVERAGE_MAP" <<EOF
| Screen | Has Production Task | Task IDs | Status |
|--------|---------------------|----------|--------|
EOF

  MISSING_UI_TASKS=()

  while IFS= read -r polished_file; do
    [ -z "$polished_file" ] && continue

    SCREEN=$(echo "$polished_file" | sed 's|.*/\([^/]*\)/polished/.*|\1|')

    # Check if tasks.md has production implementation task for this screen
    PRODUCTION_TASKS=$(grep -n "T[0-9]\{3\}" "$TASKS_FILE" | \
                       grep -i "$SCREEN" | \
                       grep -iE "production|implement|create.*route|build.*page" | \
                       grep -o "T[0-9]\{3\}" | \
                       tr '\n' ',' | \
                       sed 's/,$//')

    if [ -n "$PRODUCTION_TASKS" ]; then
      echo "| $SCREEN | ✅ | $PRODUCTION_TASKS | Ready |" >> "$UI_COVERAGE_MAP"
    else
      echo "| $SCREEN | ❌ | | Missing production task |" >> "$UI_COVERAGE_MAP"
      MISSING_UI_TASKS+=("Screen '$SCREEN' has polished design but no production implementation task")
    fi
  done <<< "$POLISHED_SCREEN_FILES"

  if [ ${#MISSING_UI_TASKS[@]} -gt 0 ]; then
    echo "⚠️  UI task issues:"
    for issue in "${MISSING_UI_TASKS[@]}"; do
      echo "    - $issue"
    done
    echo ""
  else
    echo "✅ All polished screens have production tasks"
    echo ""
  fi
fi
```

## ANALYZE MIGRATION COVERAGE

**If schema changes exist:**

```bash
if [ "$HAS_MIGRATIONS" = true ] || grep -q "## \[SCHEMA\]" "$PLAN_FILE" 2>/dev/null; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🗄️  Analyzing migration coverage"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Extract entities from migration-plan.md or plan.md SCHEMA section
  ENTITIES=""

  if [ -f "$MIGRATION_PLAN" ]; then
    ENTITIES=$(grep -E "^-|^\*" "$MIGRATION_PLAN" | \
               grep -oE "[A-Z][a-z]+Table|[A-Z][a-z]+" | \
               sort -u)
  elif grep -q "## \[SCHEMA\]" "$PLAN_FILE"; then
    ENTITIES=$(sed -n '/## \[SCHEMA\]/,/## \[/p' "$PLAN_FILE" | \
               grep -E "^-|^\*" | \
               grep -oE "[A-Z][a-z]+Table|[A-Z][a-z]+" | \
               sort -u)
  fi

  ENTITY_COUNT=$(echo "$ENTITIES" | grep -c "^" || echo 0)

  if [ "$ENTITY_COUNT" -eq 0 ]; then
    echo "⚠️  No entities found in migration plan"
    echo ""
  else
    echo "Found $ENTITY_COUNT database entities"
    echo ""

    MIGRATION_COVERAGE_MAP="$FEATURE_DIR/migration-coverage.tmp"

    cat > "$MIGRATION_COVERAGE_MAP" <<EOF
| Entity | Migration Task | Migration File | Reversible | Status |
|--------|---------------|----------------|------------|--------|
EOF

    MISSING_MIGRATION_TASKS=()
    NON_REVERSIBLE_MIGRATIONS=()

    while IFS= read -r entity; do
      [ -z "$entity" ] && continue

      # Check if tasks.md has migration task
      MIGRATION_TASK=$(grep -n "T[0-9]\{3\}" "$TASKS_FILE" | \
                       grep -i "migration" | \
                       grep -i "$entity" | \
                       grep -o "T[0-9]\{3\}" | \
                       head -1)

      # Check if migration file exists
      ENTITY_LOWER=$(echo "$entity" | tr '[:upper:]' '[:lower:]')
      MIGRATION_FILE=$(find api/alembic/versions -name "*${ENTITY_LOWER}*" 2>/dev/null | head -1)

      if [ -n "$MIGRATION_FILE" ]; then
        # Check if reversible (has downgrade function)
        if grep -q "def downgrade" "$MIGRATION_FILE"; then
          REVERSIBLE="✅"
        else
          REVERSIBLE="❌"
          NON_REVERSIBLE_MIGRATIONS+=("$entity: $(basename "$MIGRATION_FILE")")
        fi

        FILE_NAME=$(basename "$MIGRATION_FILE")
      else
        REVERSIBLE="N/A"
        FILE_NAME="Not created"
      fi

      if [ -n "$MIGRATION_TASK" ]; then
        echo "| $entity | ✅ $MIGRATION_TASK | $FILE_NAME | $REVERSIBLE | Ready |" >> "$MIGRATION_COVERAGE_MAP"
      else
        echo "| $entity | ❌ | $FILE_NAME | $REVERSIBLE | Missing task |" >> "$MIGRATION_COVERAGE_MAP"
        MISSING_MIGRATION_TASKS+=("Entity '$entity' missing migration task")
      fi
    done <<< "$ENTITIES"

    if [ ${#MISSING_MIGRATION_TASKS[@]} -gt 0 ]; then
      echo "⚠️  Migration task issues:"
      for issue in "${MISSING_MIGRATION_TASKS[@]}"; do
        echo "    - $issue"
      done
      echo ""
    fi

    if [ ${#NON_REVERSIBLE_MIGRATIONS[@]} -gt 0 ]; then
      echo "⚠️  Non-reversible migrations:"
      for issue in "${NON_REVERSIBLE_MIGRATIONS[@]}"; do
        echo "    - $issue"
      done
      echo ""
    fi

    if [ ${#MISSING_MIGRATION_TASKS[@]} -eq 0 ] && [ ${#NON_REVERSIBLE_MIGRATIONS[@]} -eq 0 ]; then
      echo "✅ All entities have reversible migration tasks"
      echo ""
    fi
  fi
fi
```

## DETECT DUPLICATE REQUIREMENTS

**Check for similar requirements:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Detecting duplicate requirements"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

DUPLICATES=()

if [ "$FUNCTIONAL_COUNT" -gt 1 ]; then
  # Convert requirements to array
  readarray -t REQ_ARRAY <<< "$FUNCTIONAL_REQS"

  # Compare each pair
  for ((i=0; i<${#REQ_ARRAY[@]}; i++)); do
    for ((j=i+1; j<${#REQ_ARRAY[@]}; j++)); do
      REQ1="${REQ_ARRAY[$i]}"
      REQ2="${REQ_ARRAY[$j]}"

      [ -z "$REQ1" ] || [ -z "$REQ2" ] && continue

      # Extract key terms
      TERMS1=$(echo "$REQ1" | tr ' ' '\n' | sort | uniq)
      TERMS2=$(echo "$REQ2" | tr ' ' '\n' | sort | uniq)

      # Count common terms
      COMMON=$(comm -12 <(echo "$TERMS1") <(echo "$TERMS2") | wc -l)
      TOTAL=$(echo "$TERMS1 $TERMS2" | tr ' ' '\n' | sort | uniq | wc -l)

      # If >60% overlap, flag as potential duplicate
      if [ "$COMMON" -gt 0 ] && [ "$TOTAL" -gt 0 ]; then
        SIMILARITY=$(( COMMON * 100 / TOTAL ))

        if [ "$SIMILARITY" -gt 60 ]; then
          DUPLICATES+=("R$((i+1)) and R$((j+1)): $SIMILARITY% similar")
        fi
      fi
    done
  done
fi

if [ ${#DUPLICATES[@]} -gt 0 ]; then
  echo "⚠️  Potential duplicates:"
  for dup in "${DUPLICATES[@]}"; do
    echo "    - $dup"
  done
  echo ""
else
  echo "✅ No duplicate requirements detected"
  echo ""
fi
```

## DETECT AMBIGUOUS REQUIREMENTS

**Check for vague language:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Detecting ambiguous requirements"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vague terms to flag
VAGUE_TERMS=(
  "fast"
  "slow"
  "easy"
  "simple"
  "good"
  "bad"
  "many"
  "few"
  "large"
  "small"
  "quickly"
  "slowly"
  "user-friendly"
  "intuitive"
  "clean"
  "nice"
  "better"
  "improved"
)

AMBIGUOUS_REQS=()

if [ "$FUNCTIONAL_COUNT" -gt 0 ]; then
  while IFS= read -r req; do
    [ -z "$req" ] && continue

    for term in "${VAGUE_TERMS[@]}"; do
      if echo "$req" | grep -qiw "$term"; then
        AMBIGUOUS_REQS+=("$(echo "$req" | head -c 60)... (contains '$term' without metric)")
        break
      fi
    done
  done <<< "$FUNCTIONAL_REQS"
fi

if [ ${#AMBIGUOUS_REQS[@]} -gt 0 ]; then
  echo "⚠️  Ambiguous requirements:"
  for amb in "${AMBIGUOUS_REQS[@]}"; do
    echo "    - $amb"
  done
  echo ""
  echo "Recommendation: Add measurable criteria"
  echo "  Example: 'fast' → '<2s response time (p95)'"
  echo ""
else
  echo "✅ No ambiguous requirements detected"
  echo ""
fi
```

## VALIDATE TDD ORDERING

**Check RED → GREEN → REFACTOR sequence:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Validating TDD task ordering"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ORDERING_ISSUES=()

# Extract all tasks with TDD phases
TASKS_WITH_PHASES=$(grep "T[0-9]\{3\}" "$TASKS_FILE" | \
                    grep -E "\[RED\]|\[GREEN→T[0-9]{3}\]|\[REFACTOR\]")

# Track current behavior
LAST_PHASE=""

while IFS= read -r task; do
  [ -z "$task" ] && continue

  TASK_ID=$(echo "$task" | grep -o "T[0-9]\{3\}")

  if echo "$task" | grep -q "\[RED\]"; then
    LAST_PHASE="RED"

  elif echo "$task" | grep -q "\[GREEN→"; then
    # Should follow RED
    if [ "$LAST_PHASE" != "RED" ]; then
      ORDERING_ISSUES+=("$TASK_ID: GREEN phase without preceding RED")
    fi
    LAST_PHASE="GREEN"

  elif echo "$task" | grep -q "\[REFACTOR\]"; then
    # Should follow GREEN
    if [ "$LAST_PHASE" != "GREEN" ]; then
      ORDERING_ISSUES+=("$TASK_ID: REFACTOR without preceding GREEN")
    fi
    LAST_PHASE="REFACTOR"
  fi
done <<< "$TASKS_WITH_PHASES"

if [ ${#ORDERING_ISSUES[@]} -gt 0 ]; then
  echo "⚠️  TDD ordering issues:"
  for issue in "${ORDERING_ISSUES[@]}"; do
    echo "    - $issue"
  done
  echo ""
  echo "Recommendation: Follow RED → GREEN → REFACTOR sequence"
  echo ""
else
  echo "✅ TDD ordering validated"
  echo ""
fi
```

## DETECT TERMINOLOGY CONFLICTS

**Check for inconsistent terms across files:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Checking terminology consistency"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Extract key terms from spec.md (CamelCase words)
SPEC_TERMS=$(grep -oE "[A-Z][a-z]+[A-Z][a-z]+" "$SPEC_FILE" | sort | uniq)

TERMINOLOGY_ISSUES=()

while IFS= read -r term; do
  [ -z "$term" ] && continue

  # Check if term appears differently in other files
  PLAN_VARIANTS=$(grep -io "${term:0:5}[a-z]*" "$PLAN_FILE" 2>/dev/null | sort | uniq)
  TASKS_VARIANTS=$(grep -io "${term:0:5}[a-z]*" "$TASKS_FILE" 2>/dev/null | sort | uniq)

  # If multiple variants found, flag
  ALL_VARIANTS=$(echo "$term $PLAN_VARIANTS $TASKS_VARIANTS" | tr ' ' '\n' | sort | uniq)
  VARIANT_COUNT=$(echo "$ALL_VARIANTS" | grep -c "^" || echo 0)

  if [ "$VARIANT_COUNT" -gt 1 ]; then
    VARIANTS=$(echo "$ALL_VARIANTS" | tr '\n' ',' | sed 's/,$//')
    TERMINOLOGY_ISSUES+=("$term: Found variants ($VARIANTS)")
  fi
done <<< "$SPEC_TERMS"

if [ ${#TERMINOLOGY_ISSUES[@]} -gt 0 ]; then
  echo "⚠️  Terminology inconsistencies:"
  for issue in "${TERMINOLOGY_ISSUES[@]:0:10}"; do  # Limit to 10
    echo "    - $issue"
  done
  if [ ${#TERMINOLOGY_ISSUES[@]} -gt 10 ]; then
    echo "    ... and $((${#TERMINOLOGY_ISSUES[@]} - 10)) more"
  fi
  echo ""
  echo "Recommendation: Standardize terminology across artifacts"
  echo ""
else
  echo "✅ Terminology consistent"
  echo ""
fi
```

## VALIDATE CONSTITUTION ALIGNMENT

**Check for constitution principles:**

```bash
if [ -f "$CONSTITUTION_FILE" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔍 Checking constitution alignment"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Extract MUST principles
  MUST_PRINCIPLES=$(grep "^- MUST" "$CONSTITUTION_FILE" | sed 's/^- MUST //')

  PRINCIPLE_COUNT=$(echo "$MUST_PRINCIPLES" | grep -c "^" || echo 0)

  if [ "$PRINCIPLE_COUNT" -gt 0 ]; then
    echo "Validating $PRINCIPLE_COUNT MUST principles"
    echo ""

    CONSTITUTION_VIOLATIONS=()

    while IFS= read -r principle; do
      [ -z "$principle" ] && continue

      # Extract key terms (first 2-3 words)
      KEY_TERMS=$(echo "$principle" | head -c 30 | grep -oE "[a-z]{4,}" | head -2)

      # Check if mentioned in spec or plan
      FOUND=false
      for term in $KEY_TERMS; do
        if grep -qi "$term" "$SPEC_FILE" "$PLAN_FILE" 2>/dev/null; then
          FOUND=true
          break
        fi
      done

      if [ "$FOUND" = false ]; then
        CONSTITUTION_VIOLATIONS+=("$(echo "$principle" | head -c 60)... (not addressed)")
      fi
    done <<< "$MUST_PRINCIPLES"

    if [ ${#CONSTITUTION_VIOLATIONS[@]} -gt 0 ]; then
      echo "⚠️  Constitution violations:"
      for violation in "${CONSTITUTION_VIOLATIONS[@]}"; do
        echo "    - $violation"
      done
      echo ""
    else
      echo "✅ All constitution principles addressed"
      echo ""
    fi
  fi
else
  echo "ℹ️  No constitution.md found (skipping principle validation)"
  echo ""
fi
```

## CALCULATE ISSUE SEVERITY

**Determine severity for each issue:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Calculating issue severity"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Critical: Constitution violations, zero coverage, missing core artifacts
CRITICAL_ISSUES=0
CRITICAL_ISSUE_LIST=()

if [ "$COVERAGE_PERCENT" -eq 0 ] && [ "$FUNCTIONAL_COUNT" -gt 0 ]; then
  ((CRITICAL_ISSUES++))
  CRITICAL_ISSUE_LIST+=("Zero requirement coverage")
fi

if [ -n "${CONSTITUTION_VIOLATIONS:-}" ] && [ ${#CONSTITUTION_VIOLATIONS[@]} -gt 0 ]; then
  CRITICAL_ISSUES=$((CRITICAL_ISSUES + ${#CONSTITUTION_VIOLATIONS[@]}))
  CRITICAL_ISSUE_LIST+=("${#CONSTITUTION_VIOLATIONS[@]} constitution violation(s)")
fi

# High: Uncovered requirements, ambiguous requirements, missing migration tasks
HIGH_ISSUES=0

if [ ${#UNCOVERED_REQS[@]} -gt 0 ]; then
  HIGH_ISSUES=${#UNCOVERED_REQS[@]}
fi

if [ ${#AMBIGUOUS_REQS[@]} -gt 0 ]; then
  HIGH_ISSUES=$((HIGH_ISSUES + ${#AMBIGUOUS_REQS[@]}))
fi

if [ -n "${MISSING_MIGRATION_TASKS:-}" ] && [ ${#MISSING_MIGRATION_TASKS[@]} -gt 0 ]; then
  HIGH_ISSUES=$((HIGH_ISSUES + ${#MISSING_MIGRATION_TASKS[@]}))
fi

if [ -n "${MISSING_UI_TASKS:-}" ] && [ ${#MISSING_UI_TASKS[@]} -gt 0 ]; then
  HIGH_ISSUES=$((HIGH_ISSUES + ${#MISSING_UI_TASKS[@]}))
fi

# Medium: Terminology drift, ordering issues, non-reversible migrations
MEDIUM_ISSUES=0

if [ ${#TERMINOLOGY_ISSUES[@]} -gt 0 ]; then
  MEDIUM_ISSUES=${#TERMINOLOGY_ISSUES[@]}
fi

if [ ${#ORDERING_ISSUES[@]} -gt 0 ]; then
  MEDIUM_ISSUES=$((MEDIUM_ISSUES + ${#ORDERING_ISSUES[@]}))
fi

if [ -n "${NON_REVERSIBLE_MIGRATIONS:-}" ] && [ ${#NON_REVERSIBLE_MIGRATIONS[@]} -gt 0 ]; then
  MEDIUM_ISSUES=$((MEDIUM_ISSUES + ${#NON_REVERSIBLE_MIGRATIONS[@]}))
fi

# Low: Duplicates
LOW_ISSUES=${#DUPLICATES[@]}

TOTAL_ISSUES=$((CRITICAL_ISSUES + HIGH_ISSUES + MEDIUM_ISSUES + LOW_ISSUES))

echo "Issue Summary:"
echo "  Critical: $CRITICAL_ISSUES"
echo "  High: $HIGH_ISSUES"
echo "  Medium: $MEDIUM_ISSUES"
echo "  Low: $LOW_ISSUES"
echo "  Total: $TOTAL_ISSUES"
echo ""
```

## GENERATE ANALYSIS REPORT

**Write comprehensive report:**

```bash
ANALYSIS_REPORT="$FEATURE_DIR/analysis.md"

echo "Writing analysis report: $ANALYSIS_REPORT"
echo ""

cat > "$ANALYSIS_REPORT" <<EOF
# Cross-Artifact Analysis Report

**Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Feature**: $SLUG

---

## Executive Summary

- Total Requirements: $FUNCTIONAL_COUNT
- Total Tasks: $(grep -c "^T[0-9]\{3\}" "$TASKS_FILE" || echo 0)
- Coverage: $COVERAGE_PERCENT%
- Critical Issues: $CRITICAL_ISSUES
- High Issues: $HIGH_ISSUES
- Medium Issues: $MEDIUM_ISSUES
- Low Issues: $LOW_ISSUES

**Status**: $(if [ "$CRITICAL_ISSUES" -gt 0 ]; then echo "❌ Blocked"; elif [ "$HIGH_ISSUES" -gt 0 ]; then echo "⚠️ Review recommended"; else echo "✅ Ready for implementation"; fi)

---

## Requirement Coverage

$(cat "$COVERAGE_MAP" 2>/dev/null || echo "No coverage data")

**Summary**: $COVERED_REQS/$FUNCTIONAL_COUNT requirements covered ($COVERAGE_PERCENT%)

---

EOF

# Add UI coverage if applicable
if [ "$HAS_UI_DESIGN" = true ]; then
  cat >> "$ANALYSIS_REPORT" <<EOF
## UI Task Coverage

$(cat "$UI_COVERAGE_MAP" 2>/dev/null || echo "No UI coverage data")

---

EOF
fi

# Add migration coverage if applicable
if [ -n "${MIGRATION_COVERAGE_MAP:-}" ] && [ -f "$MIGRATION_COVERAGE_MAP" ]; then
  cat >> "$ANALYSIS_REPORT" <<EOF
## Migration Coverage

$(cat "$MIGRATION_COVERAGE_MAP")

**Migration Health:**
- $(if [ ${#MISSING_MIGRATION_TASKS[@]} -eq 0 ]; then echo "✅"; else echo "❌"; fi) All entities have migration tasks
- $(if [ ${#NON_REVERSIBLE_MIGRATIONS[@]} -eq 0 ]; then echo "✅"; else echo "❌"; fi) All migrations have upgrade() and downgrade()

---

EOF
fi

# Add issues section
cat >> "$ANALYSIS_REPORT" <<EOF
## Issues Found

### Critical Issues ($CRITICAL_ISSUES)

EOF

if [ ${#CONSTITUTION_VIOLATIONS[@]} -gt 0 ]; then
  echo "**Constitution Violations:**" >> "$ANALYSIS_REPORT"
  for violation in "${CONSTITUTION_VIOLATIONS[@]}"; do
    echo "- $violation" >> "$ANALYSIS_REPORT"
  done
  echo "" >> "$ANALYSIS_REPORT"
fi

if [ "$COVERAGE_PERCENT" -eq 0 ] && [ "$FUNCTIONAL_COUNT" -gt 0 ]; then
  echo "- Zero requirement coverage (no requirements mapped to tasks)" >> "$ANALYSIS_REPORT"
  echo "" >> "$ANALYSIS_REPORT"
fi

cat >> "$ANALYSIS_REPORT" <<EOF
### High Issues ($HIGH_ISSUES)

EOF

if [ ${#UNCOVERED_REQS[@]} -gt 0 ]; then
  echo "**Uncovered Requirements:**" >> "$ANALYSIS_REPORT"
  for req in "${UNCOVERED_REQS[@]:0:10}"; do  # Limit to 10
    echo "- $(echo "$req" | head -c 80)" >> "$ANALYSIS_REPORT"
  done
  if [ ${#UNCOVERED_REQS[@]} -gt 10 ]; then
    echo "- ... and $((${#UNCOVERED_REQS[@]} - 10)) more" >> "$ANALYSIS_REPORT"
  fi
  echo "" >> "$ANALYSIS_REPORT"
fi

if [ ${#AMBIGUOUS_REQS[@]} -gt 0 ]; then
  echo "**Ambiguous Requirements:**" >> "$ANALYSIS_REPORT"
  for amb in "${AMBIGUOUS_REQS[@]:0:10}"; do
    echo "- $amb" >> "$ANALYSIS_REPORT"
  done
  if [ ${#AMBIGUOUS_REQS[@]} -gt 10 ]; then
    echo "- ... and $((${#AMBIGUOUS_REQS[@]} - 10)) more" >> "$ANALYSIS_REPORT"
  fi
  echo "" >> "$ANALYSIS_REPORT"
fi

if [ -n "${MISSING_MIGRATION_TASKS:-}" ] && [ ${#MISSING_MIGRATION_TASKS[@]} -gt 0 ]; then
  echo "**Missing Migration Tasks:**" >> "$ANALYSIS_REPORT"
  for task in "${MISSING_MIGRATION_TASKS[@]}"; do
    echo "- $task" >> "$ANALYSIS_REPORT"
  done
  echo "" >> "$ANALYSIS_REPORT"
fi

cat >> "$ANALYSIS_REPORT" <<EOF
### Medium Issues ($MEDIUM_ISSUES)

EOF

if [ ${#ORDERING_ISSUES[@]} -gt 0 ]; then
  echo "**TDD Ordering Issues:**" >> "$ANALYSIS_REPORT"
  for issue in "${ORDERING_ISSUES[@]}"; do
    echo "- $issue" >> "$ANALYSIS_REPORT"
  done
  echo "" >> "$ANALYSIS_REPORT"
fi

if [ ${#TERMINOLOGY_ISSUES[@]} -gt 0 ]; then
  echo "**Terminology Inconsistencies:**" >> "$ANALYSIS_REPORT"
  for issue in "${TERMINOLOGY_ISSUES[@]:0:10}"; do
    echo "- $issue" >> "$ANALYSIS_REPORT"
  done
  if [ ${#TERMINOLOGY_ISSUES[@]} -gt 10 ]; then
    echo "- ... and $((${#TERMINOLOGY_ISSUES[@]} - 10)) more" >> "$ANALYSIS_REPORT"
  fi
  echo "" >> "$ANALYSIS_REPORT"
fi

cat >> "$ANALYSIS_REPORT" <<EOF
### Low Issues ($LOW_ISSUES)

EOF

if [ ${#DUPLICATES[@]} -gt 0 ]; then
  echo "**Potential Duplicates:**" >> "$ANALYSIS_REPORT"
  for dup in "${DUPLICATES[@]}"; do
    echo "- $dup" >> "$ANALYSIS_REPORT"
  done
  echo "" >> "$ANALYSIS_REPORT"
fi

cat >> "$ANALYSIS_REPORT" <<EOF
---

## Recommendations

EOF

# Generate actionable recommendations
if [ ${#UNCOVERED_REQS[@]} -gt 0 ]; then
  cat >> "$ANALYSIS_REPORT" <<EOF
### Uncovered Requirements (HIGH)

Add tasks to tasks.md for missing requirements.

**Action**: Run \`/tasks $SLUG\` again with these requirements in focus.

EOF
fi

if [ ${#AMBIGUOUS_REQS[@]} -gt 0 ]; then
  cat >> "$ANALYSIS_REPORT" <<EOF
### Ambiguous Requirements (HIGH)

Replace vague language with measurable criteria.

**Example**: "fast" → "<2s response time (p95)"

**Action**: Update spec.md with specific metrics.

EOF
fi

if [ ${#ORDERING_ISSUES[@]} -gt 0 ]; then
  cat >> "$ANALYSIS_REPORT" <<EOF
### TDD Ordering Issues (MEDIUM)

Reorder tasks to follow RED → GREEN → REFACTOR sequence.

**Action**: Edit tasks.md to fix task ordering.

EOF
fi

cat >> "$ANALYSIS_REPORT" <<EOF
---

## Next Steps

$(if [ "$CRITICAL_ISSUES" -gt 0 ]; then
  echo "**⛔ BLOCKED**: Fix $CRITICAL_ISSUES critical issue(s) before proceeding."
  echo ""
  echo "1. Review critical issues above"
  echo "2. Update spec.md and/or plan.md"
  echo "3. Re-run: \`/analyze $SLUG\`"
elif [ "$HIGH_ISSUES" -gt 0 ]; then
  echo "**⚠️ REVIEW RECOMMENDED**: $HIGH_ISSUES high-priority issue(s) found."
  echo ""
  echo "Options:"
  echo "- A) Fix high-priority issues first (recommended)"
  echo "- B) Proceed with caution (/implement will address during TDD)"
  echo ""
  echo "Next: \`/implement $SLUG\` (or fix issues first)"
else
  echo "**✅ READY FOR IMPLEMENTATION**"
  echo ""
  echo "Next: \`/implement $SLUG\`"
fi)

EOF

echo "✅ Report written: $ANALYSIS_REPORT"
```

## AUTO-COMPACTION

In `/flow` mode, auto-compaction runs after analysis:
- ✅ Preserve: Critical issues, blocking concerns, analysis findings, coverage metrics
- ❌ Remove: Redundant task details, old research, duplicate information
- Strategy: Moderate (implementation phase)

**Manual compact instruction (standalone mode):**
```bash
/compact "preserve critical issues, blocking concerns, analysis findings, and coverage metrics"
```

**When to compact:**
- Auto: After `/analyze` in `/flow` mode
- Manual: If context >60k tokens before `/implement`
- PAUSE: If critical issues found (user must fix before continuing)

## RETURN

Brief summary:

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Analysis Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Report: specs/$SLUG/analysis.md"
echo ""
echo "📊 Summary:"
echo "- Requirements: $FUNCTIONAL_COUNT"
echo "- Tasks: $(grep -c "^T[0-9]\{3\}" "$TASKS_FILE" || echo 0)"
echo "- Coverage: $COVERAGE_PERCENT%"
echo "- Issues: $TOTAL_ISSUES (C:$CRITICAL_ISSUES H:$HIGH_ISSUES M:$MEDIUM_ISSUES L:$LOW_ISSUES)"
echo ""

if [ "$CRITICAL_ISSUES" -gt 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⛔ BLOCKED: $CRITICAL_ISSUES critical issue(s)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Fix critical issues before proceeding:"
  for issue in "${CRITICAL_ISSUE_LIST[@]}"; do
    echo "  - $issue"
  done
  echo ""
  echo "Then re-run: /analyze $SLUG"

elif [ "$HIGH_ISSUES" -gt 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  REVIEW RECOMMENDED: $HIGH_ISSUES high-priority issue(s)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Options:"
  echo "  A) Fix high-priority issues first (recommended)"
  echo "  B) Proceed with caution (/implement will address during TDD)"
  echo ""
  echo "Next: /implement $SLUG (or fix issues first)"

else
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ READY FOR IMPLEMENTATION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Next: /implement $SLUG"
  echo ""
  echo "/implement will:"
  echo "  1. Read tasks.md (execute $(grep -c "^T[0-9]\{3\}" "$TASKS_FILE" || echo 0) tasks)"
  echo "  2. Follow TDD (RED → GREEN → REFACTOR)"
  echo "  3. Reference polished mockups (if UI feature)"
  echo "  4. Commit after each task"
  echo "  5. Update error-log.md (track issues)"
  echo ""
  echo "Estimated duration: 2-4 hours"
fi

echo ""
```

