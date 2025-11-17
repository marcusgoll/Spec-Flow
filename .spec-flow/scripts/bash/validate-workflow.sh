## RUN PREREQUISITE SCRIPT

**Execute once from repo root:**

```bash
# Get absolute paths and validate artifacts exist
if command -v pwsh &> /dev/null; then
  # Windows/PowerShell
  PREREQ_JSON=$(pwsh -File scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks)
else
  # macOS/Linux/Git Bash
  PREREQ_JSON=$(scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks)
fi

# Parse JSON for paths
FEATURE_DIR=$(echo "$PREREQ_JSON" | jq -r '.FEATURE_DIR')
SPEC_FILE=$(echo "$PREREQ_JSON" | jq -r '.FEATURE_SPEC')
PLAN_FILE=$(echo "$PREREQ_JSON" | jq -r '.IMPL_PLAN')
TASKS_FILE=$(echo "$PREREQ_JSON" | jq -r '.TASKS')

# Validate required files
if [ ! -f "$SPEC_FILE" ]; then
  echo "❌ Missing: spec.md"
  echo "Run: /specify first"
  exit 1
fi

if [ ! -f "$PLAN_FILE" ]; then
  echo "❌ Missing: plan.md"
  echo "Run: /plan first"
  exit 1
fi

if [ ! -f "$TASKS_FILE" ]; then
  echo "❌ Missing: tasks.md"
  echo "Run: /tasks first"
  exit 1
fi
```

For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

## LOAD ARTIFACTS (Progressive Disclosure)

**Load only minimal necessary context from each artifact:**

### From spec.md:

```bash
# Extract sections (avoid loading full file into context)
OVERVIEW=$(sed -n '/^## Overview/,/^## /p' "$SPEC_FILE" | head -n -1)
FUNCTIONAL_REQS=$(sed -n '/^## Functional Requirements/,/^## /p' "$SPEC_FILE" | head -n -1)
NFRS=$(sed -n '/^## Non-Functional Requirements/,/^## /p' "$SPEC_FILE" | head -n -1)
USER_STORIES=$(sed -n '/^## User Stories/,/^## /p' "$SPEC_FILE" | head -n -1)
EDGE_CASES=$(sed -n '/^## Edge Cases/,/^## /p' "$SPEC_FILE" | head -n -1)

# Count requirements
FUNCTIONAL_COUNT=$(echo "$FUNCTIONAL_REQS" | grep -c "^- " || echo 0)
NFR_COUNT=$(echo "$NFRS" | grep -c "^- " || echo 0)
STORY_COUNT=$(echo "$USER_STORIES" | grep -c "^\[US[0-9]\]" || echo 0)
```

### From plan.md:

```bash
# Extract key sections
ARCHITECTURE=$(sed -n '/## \[ARCHITECTURE DECISIONS\]/,/## \[/p' "$PLAN_FILE" | head -n -1)
EXISTING_REUSE=$(sed -n '/## \[EXISTING INFRASTRUCTURE - REUSE\]/,/## \[/p' "$PLAN_FILE" | head -n -1)
NEW_CREATE=$(sed -n '/## \[NEW INFRASTRUCTURE - CREATE\]/,/## \[/p' "$PLAN_FILE" | head -n -1)
SCHEMA=$(sed -n '/## \[SCHEMA\]/,/## \[/p' "$PLAN_FILE" | head -n -1)
CI_CD_IMPACT=$(sed -n '/## \[CI\/CD IMPACT\]/,/## \[/p' "$PLAN_FILE" | head -n -1)
```

### From tasks.md:

```bash
# Extract task IDs, descriptions, phases
TASK_COUNT=$(grep -c "^- \[ \] T[0-9]" "$TASKS_FILE" || echo 0)
PARALLEL_TASKS=$(grep -c "\[P\]" "$TASKS_FILE" || echo 0)
STORY_TASKS=$(grep -c "\[US[0-9]\]" "$TASKS_FILE" || echo 0)

# Check for TDD markers
HAS_TDD_MARKERS=$(grep -c "\[RED\]\|\[GREEN\]\|\[REFACTOR\]" "$TASKS_FILE" || echo 0)

# Check for UI tasks
HAS_UI_TASKS=$(grep -c "polished.*production\|UI promotion" "$TASKS_FILE" || echo 0)

# Check for migration tasks
HAS_MIGRATION_TASKS=$(grep -c "migration\|alembic\|prisma" "$TASKS_FILE" || echo 0)
```

### From constitution (if exists):

```bash
CONSTITUTION_FILE=".spec-flow/memory/constitution.md"

if [ -f "$CONSTITUTION_FILE" ]; then
  HAS_CONSTITUTION=true
  MUST_PRINCIPLES=$(grep "^- MUST" "$CONSTITUTION_FILE" | sed 's/^- MUST //')
  PRINCIPLE_COUNT=$(echo "$MUST_PRINCIPLES" | grep -c "^" || echo 0)
else
  HAS_CONSTITUTION=false
  PRINCIPLE_COUNT=0
fi
```

## BUILD SEMANTIC MODELS

**Create internal representations (do not output raw artifacts):**

### Requirements Inventory:

```python
# Pseudo-code for semantic model
requirements = {}

for req in functional_requirements:
    # Generate stable key from imperative phrase
    # e.g., "User can upload file" → "user-can-upload-file"
    slug = generate_slug(req)
    requirements[slug] = {
        "text": req,
        "type": "functional",
        "tasks": [],  # Will populate during coverage mapping
        "covered": False
    }

for nfr in non_functional_requirements:
    slug = generate_slug(nfr)
    requirements[slug] = {
        "text": nfr,
        "type": "non-functional",
        "tasks": [],
        "covered": False
    }
```

### Task Coverage Mapping:

```python
# Map tasks to requirements
for task in tasks:
    # Extract keywords from task description
    keywords = extract_keywords(task.description)

    # Find matching requirements (semantic similarity)
    for req_slug, req_data in requirements.items():
        req_keywords = extract_keywords(req_data["text"])

        # Calculate similarity (Jaccard index)
        similarity = len(keywords & req_keywords) / len(keywords | req_keywords)

        if similarity > 0.3:  # Threshold
            requirements[req_slug]["tasks"].append(task.id)
            requirements[req_slug]["covered"] = True
```

### Constitution Rule Set:

```python
# Extract MUST principles
constitution_rules = []

for principle in must_principles:
    # Extract key terms
    key_terms = extract_keywords(principle)

    constitution_rules.append({
        "text": principle,
        "keywords": key_terms,
        "category": infer_category(principle)  # Architecture, Security, Testing, etc.
    })
```

## DETECTION PASSES (Token-Efficient Analysis)

**Focus on high-signal findings. Limit to 50 findings total.**

### A. Constitution Alignment (CRITICAL)

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Checking constitution alignment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CONSTITUTION_VIOLATIONS=()

if [ "$HAS_CONSTITUTION" = true ]; then
  while IFS= read -r principle; do
    [ -z "$principle" ] && continue

    # Extract key terms (first 3 significant words)
    KEY_TERMS=$(echo "$principle" | grep -oE "[a-z]{4,}" | head -3)

    # Check if addressed in spec, plan, or tasks
    FOUND=false
    for term in $KEY_TERMS; do
      if grep -qi "$term" "$SPEC_FILE" "$PLAN_FILE" "$TASKS_FILE" 2>/dev/null; then
        FOUND=true
        break
      fi
    done

    if [ "$FOUND" = false ]; then
      CONSTITUTION_VIOLATIONS+=("CRITICAL|Constitution|spec.md,plan.md,tasks.md|Constitution principle not addressed: $(echo "$principle" | head -c 60)...|Address in spec/plan/tasks")
    fi
  done <<< "$MUST_PRINCIPLES"
fi

echo "Constitution violations: ${#CONSTITUTION_VIOLATIONS[@]}"
echo ""
```

### B. Coverage Gaps

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Analyzing requirement coverage"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

UNCOVERED_REQS=()
UNMAPPED_TASKS=()

# Check each functional requirement for task coverage
while IFS= read -r req; do
  [ -z "$req" ] && continue

  # Extract key terms
  KEY_TERMS=$(echo "$req" | grep -oE "[A-Z][a-z]+|[0-9]+" | head -3 | tr '\n' ' ')

  # Search tasks.md for these terms
  MATCHING_TASKS=$(grep -n "^- \[ \] T[0-9]" "$TASKS_FILE" | \
                   grep -i "$KEY_TERMS" | \
                   grep -o "T[0-9]\{3\}" | \
                   tr '\n' ',' | \
                   sed 's/,$//')

  if [ -z "$MATCHING_TASKS" ]; then
    UNCOVERED_REQS+=("HIGH|Coverage|spec.md:L??|Requirement not covered by tasks: $(echo "$req" | head -c 60)...|Add tasks to tasks.md")
  fi
done <<< "$FUNCTIONAL_REQS"

# Check for unmapped tasks (tasks not tracing to requirements)
while IFS= read -r task_line; do
  [ -z "$task_line" ] && continue

  TASK_ID=$(echo "$task_line" | grep -o "T[0-9]\{3\}")
  TASK_DESC=$(echo "$task_line" | sed 's/^.*T[0-9]\{3\}[^]]*\] //')

  # Skip setup/polish tasks (allowed to not map to specific requirements)
  if echo "$TASK_DESC" | grep -qiE "setup|config|polish|deployment|health|smoke"; then
    continue
  fi

  # Check if task description keywords match any requirement
  TASK_KEYWORDS=$(echo "$TASK_DESC" | grep -oE "[A-Z][a-z]+" | head -3)
  FOUND_REQ=false

  for keyword in $TASK_KEYWORDS; do
    if echo "$FUNCTIONAL_REQS $NFRS" | grep -qi "$keyword"; then
      FOUND_REQ=true
      break
    fi
  done

  if [ "$FOUND_REQ" = false ]; then
    UNMAPPED_TASKS+=("MEDIUM|Coverage|tasks.md:L??|Task $TASK_ID does not map to any requirement|Verify task necessity or add requirement")
  fi
done <<< "$(grep "^- \[ \] T[0-9]" "$TASKS_FILE")"

echo "Uncovered requirements: ${#UNCOVERED_REQS[@]}"
echo "Unmapped tasks: ${#UNMAPPED_TASKS[@]}"
echo ""
```

### C. Duplication Detection

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
          DUPLICATES+=("HIGH|Duplication|spec.md:L$((i+1)),L$((j+1))|Requirements R$((i+1)) and R$((j+1)) are $SIMILARITY% similar|Merge or clarify distinction")
        fi
      fi
    done
  done
fi

echo "Potential duplicates: ${#DUPLICATES[@]}"
echo ""
```

### D. Ambiguity Detection

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Detecting ambiguous requirements"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vague terms to flag
VAGUE_TERMS=(
  "fast" "slow" "easy" "simple" "good" "bad"
  "many" "few" "large" "small" "quickly" "slowly"
  "user-friendly" "intuitive" "clean" "nice"
  "better" "improved" "robust" "scalable" "secure"
)

AMBIGUOUS_REQS=()
PLACEHOLDERS=()

# Check functional requirements
while IFS= read -r req; do
  [ -z "$req" ] && continue

  # Check for vague terms
  for term in "${VAGUE_TERMS[@]}"; do
    if echo "$req" | grep -qiw "$term"; then
      AMBIGUOUS_REQS+=("HIGH|Ambiguity|spec.md:L??|Requirement contains vague term '$term' without metric: $(echo "$req" | head -c 50)...|Add measurable criteria (e.g., 'fast' → '<2s response time')")
      break
    fi
  done

  # Check for placeholders
  if echo "$req" | grep -qiE "TODO|TKTK|\?\?\?|<placeholder>|TBD"; then
    PLACEHOLDERS+=("CRITICAL|Ambiguity|spec.md:L??|Requirement contains unresolved placeholder: $(echo "$req" | head -c 50)...|Resolve placeholder before implementation")
  fi
done <<< "$FUNCTIONAL_REQS"

# Check NFRs (more likely to need metrics)
while IFS= read -r nfr; do
  [ -z "$nfr" ] && continue

  # NFRs MUST have measurable criteria
  if ! echo "$nfr" | grep -qE "[0-9]+|<[0-9]|>[0-9]|p[0-9]{2}|%"; then
    AMBIGUOUS_REQS+=("HIGH|Ambiguity|spec.md:L??|Non-functional requirement lacks metric: $(echo "$nfr" | head -c 50)...|Add quantifiable target")
  fi
done <<< "$NFRS"

echo "Ambiguous requirements: ${#AMBIGUOUS_REQS[@]}"
echo "Unresolved placeholders: ${#PLACEHOLDERS[@]}"
echo ""
```

### E. Underspecification

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Checking for underspecification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

UNDERSPECIFIED=()

# Check for requirements with verbs but missing objects
while IFS= read -r req; do
  [ -z "$req" ] && continue

  # Check for action verbs without clear outcome
  if echo "$req" | grep -qiE "should|must|will" && ! echo "$req" | grep -qE "when|if|to|by|with"; then
    UNDERSPECIFIED+=("MEDIUM|Underspecification|spec.md:L??|Requirement has verb but unclear outcome: $(echo "$req" | head -c 50)...|Add condition or measurable outcome")
  fi
done <<< "$FUNCTIONAL_REQS"

# Check user stories for missing acceptance criteria
STORY_NO_CRITERIA=0
while IFS= read -r story_line; do
  [ -z "$story_line" ] && continue

  STORY_ID=$(echo "$story_line" | grep -o "\[US[0-9]\]")

  # Check if acceptance criteria exist for this story
  if ! grep -A10 "$STORY_ID" "$SPEC_FILE" | grep -q "Acceptance"; then
    UNDERSPECIFIED+=("HIGH|Underspecification|spec.md:L??|User story $STORY_ID missing acceptance criteria|Add testable acceptance criteria")
    ((STORY_NO_CRITERIA++))
  fi
done <<< "$USER_STORIES"

# Check tasks referencing undefined files/components
while IFS= read -r task_line; do
  [ -z "$task_line" ] && continue

  TASK_ID=$(echo "$task_line" | grep -o "T[0-9]\{3\}")

  # Extract file path from task
  FILE_PATH=$(echo "$task_line" | grep -oE "(src|api|apps)/[a-zA-Z0-9/_.-]+" | head -1)

  if [ -n "$FILE_PATH" ]; then
    # Check if component/entity mentioned in plan or spec
    COMPONENT=$(basename "$FILE_PATH" .py .ts .tsx .js)

    if ! grep -qi "$COMPONENT" "$SPEC_FILE" "$PLAN_FILE" 2>/dev/null; then
      UNDERSPECIFIED+=("MEDIUM|Underspecification|tasks.md:L??|Task $TASK_ID references component '$COMPONENT' not defined in spec/plan|Define in plan.md or spec.md")
    fi
  fi
done <<< "$(grep "^- \[ \] T[0-9]" "$TASKS_FILE")"

echo "Underspecified items: ${#UNDERSPECIFIED[@]}"
echo ""
```

### F. Inconsistency Detection

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Checking for inconsistencies"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TERMINOLOGY_ISSUES=()
CONFLICTS=()

# Extract key terms from spec (CamelCase words)
SPEC_TERMS=$(grep -oE "[A-Z][a-z]+[A-Z][a-z]+" "$SPEC_FILE" | sort | uniq)

# Check terminology consistency
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
    TERMINOLOGY_ISSUES+=("MEDIUM|Inconsistency|spec.md,plan.md,tasks.md|Terminology drift for '$term': variants ($VARIANTS)|Standardize terminology")
  fi
done <<< "$SPEC_TERMS"

# Limit terminology issues to top 10 (avoid overflow)
if [ ${#TERMINOLOGY_ISSUES[@]} -gt 10 ]; then
  TERMINOLOGY_OVERFLOW=$((${#TERMINOLOGY_ISSUES[@]} - 10))
  TERMINOLOGY_ISSUES=("${TERMINOLOGY_ISSUES[@]:0:10}")
  TERMINOLOGY_ISSUES+=("MEDIUM|Inconsistency|*|... and $TERMINOLOGY_OVERFLOW more terminology inconsistencies|Run full terminology audit")
fi

# Check for conflicting requirements
# Example: One requirement specifies Next.js, another specifies Vue
TECH_STACK_MENTIONS=$(grep -oiE "Next\.js|Vue|React|Angular|Svelte" "$SPEC_FILE" "$PLAN_FILE" | sort | uniq)
TECH_COUNT=$(echo "$TECH_STACK_MENTIONS" | grep -c "^" || echo 0)

if [ "$TECH_COUNT" -gt 1 ]; then
  CONFLICTS+=("CRITICAL|Inconsistency|spec.md,plan.md|Multiple frontend frameworks mentioned: $(echo "$TECH_STACK_MENTIONS" | tr '\n' ',' | sed 's/,$//')|Choose one framework")
fi

echo "Terminology issues: ${#TERMINOLOGY_ISSUES[@]}"
echo "Conflicts: ${#CONFLICTS[@]}"
echo ""
```

### G. TDD Ordering Validation (if applicable)

```bash
if [ "$HAS_TDD_MARKERS" -gt 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔍 Validating TDD task ordering"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  ORDERING_ISSUES=()

  # Track current phase
  LAST_PHASE=""

  while IFS= read -r task; do
    [ -z "$task" ] && continue

    TASK_ID=$(echo "$task" | grep -o "T[0-9]\{3\}")

    if echo "$task" | grep -q "\[RED\]"; then
      LAST_PHASE="RED"
    elif echo "$task" | grep -q "\[GREEN→"; then
      # Should follow RED
      if [ "$LAST_PHASE" != "RED" ]; then
        ORDERING_ISSUES+=("MEDIUM|TDD Ordering|tasks.md:L??|Task $TASK_ID: GREEN phase without preceding RED|Follow RED → GREEN → REFACTOR sequence")
      fi
      LAST_PHASE="GREEN"
    elif echo "$task" | grep -q "\[REFACTOR\]"; then
      # Should follow GREEN
      if [ "$LAST_PHASE" != "GREEN" ]; then
        ORDERING_ISSUES+=("MEDIUM|TDD Ordering|tasks.md:L??|Task $TASK_ID: REFACTOR without preceding GREEN|Follow RED → GREEN → REFACTOR sequence")
      fi
      LAST_PHASE="REFACTOR"
    fi
  done <<< "$(grep "T[0-9]\{3\}" "$TASKS_FILE" | grep -E "\[RED\]|\[GREEN→|\[REFACTOR\]")"

  echo "TDD ordering issues: ${#ORDERING_ISSUES[@]}"
  echo ""
fi
```

### H. UI Task Coverage (if applicable)

```bash
if [ "$HAS_UI_TASKS" -gt 0 ] || [ -d "apps/web/mock" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎨 Analyzing UI task coverage"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  MISSING_UI_TASKS=()

  # Find polished screens
  if [ -d "apps/web/mock" ]; then
    POLISHED_SCREENS=$(find apps/web/mock -path "*/polished/page.tsx" 2>/dev/null)

    while IFS= read -r polished_file; do
      [ -z "$polished_file" ] && continue

      SCREEN=$(echo "$polished_file" | sed 's|.*/\([^/]*\)/polished/.*|\1|')

      # Check if tasks.md has production implementation task for this screen
      if ! grep -qi "production.*$SCREEN\|$SCREEN.*production" "$TASKS_FILE"; then
        MISSING_UI_TASKS+=("HIGH|UI Coverage|tasks.md:L??|Polished screen '$SCREEN' has no production implementation task|Add UI promotion task for $SCREEN")
      fi
    done <<< "$POLISHED_SCREENS"
  fi

  echo "Missing UI production tasks: ${#MISSING_UI_TASKS[@]}"
  echo ""
fi
```

### I. Migration Coverage (if applicable)

```bash
if [ "$HAS_MIGRATION_TASKS" -gt 0 ] || echo "$SCHEMA" | grep -q "[A-Z][a-z]*Table"; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🗄️  Analyzing migration coverage"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  MISSING_MIGRATION_TASKS=()
  NON_REVERSIBLE_MIGRATIONS=()

  # Extract entities from SCHEMA section
  ENTITIES=$(echo "$SCHEMA" | grep -oE "[A-Z][a-z]+Table|[A-Z][a-z]+" | sort -u)

  while IFS= read -r entity; do
    [ -z "$entity" ] && continue

    # Check if tasks.md has migration task for this entity
    if ! grep -qi "migration.*$entity\|$entity.*migration" "$TASKS_FILE"; then
      MISSING_MIGRATION_TASKS+=("HIGH|Migration|tasks.md:L??|Entity '$entity' missing migration task|Add migration task for $entity")
    fi

    # Check if migration file exists and is reversible
    ENTITY_LOWER=$(echo "$entity" | tr '[:upper:]' '[:lower:]')
    MIGRATION_FILE=$(find . -path "*/alembic/versions/*${ENTITY_LOWER}*" -o -path "*/prisma/migrations/*${ENTITY_LOWER}*" 2>/dev/null | head -1)

    if [ -n "$MIGRATION_FILE" ]; then
      # Check for downgrade function (Alembic) or down migration (Prisma)
      if ! grep -q "def downgrade\|down:" "$MIGRATION_FILE" 2>/dev/null; then
        NON_REVERSIBLE_MIGRATIONS+=("HIGH|Migration|$MIGRATION_FILE|Migration for '$entity' not reversible (no downgrade)|Add downgrade/down function")
      fi
    fi
  done <<< "$ENTITIES"

  echo "Missing migration tasks: ${#MISSING_MIGRATION_TASKS[@]}"
  echo "Non-reversible migrations: ${#NON_REVERSIBLE_MIGRATIONS[@]}"
  echo ""
fi
```

## SEVERITY ASSIGNMENT

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Calculating issue severity"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Aggregate all findings
ALL_FINDINGS=()
ALL_FINDINGS+=("${CONSTITUTION_VIOLATIONS[@]}")
ALL_FINDINGS+=("${PLACEHOLDERS[@]}")
ALL_FINDINGS+=("${CONFLICTS[@]}")
ALL_FINDINGS+=("${UNCOVERED_REQS[@]}")
ALL_FINDINGS+=("${DUPLICATES[@]}")
ALL_FINDINGS+=("${AMBIGUOUS_REQS[@]}")
ALL_FINDINGS+=("${UNDERSPECIFIED[@]}")
ALL_FINDINGS+=("${TERMINOLOGY_ISSUES[@]}")
ALL_FINDINGS+=("${ORDERING_ISSUES[@]}")
ALL_FINDINGS+=("${MISSING_UI_TASKS[@]}")
ALL_FINDINGS+=("${MISSING_MIGRATION_TASKS[@]}")
ALL_FINDINGS+=("${NON_REVERSIBLE_MIGRATIONS[@]}")
ALL_FINDINGS+=("${UNMAPPED_TASKS[@]}")

# Count by severity
CRITICAL_ISSUES=0
HIGH_ISSUES=0
MEDIUM_ISSUES=0
LOW_ISSUES=0

for finding in "${ALL_FINDINGS[@]}"; do
  SEVERITY=$(echo "$finding" | cut -d'|' -f1)

  case "$SEVERITY" in
    CRITICAL) ((CRITICAL_ISSUES++)) ;;
    HIGH) ((HIGH_ISSUES++)) ;;
    MEDIUM) ((MEDIUM_ISSUES++)) ;;
    LOW) ((LOW_ISSUES++)) ;;
  esac
done

TOTAL_ISSUES=${#ALL_FINDINGS[@]}

# Limit to 50 findings (token efficiency)
if [ "$TOTAL_ISSUES" -gt 50 ]; then
  OVERFLOW=$((TOTAL_ISSUES - 50))
  ALL_FINDINGS=("${ALL_FINDINGS[@]:0:50}")
  ALL_FINDINGS+=("LOW|Overflow|*|... and $OVERFLOW more issues not shown|Run detailed analysis or fix top 50 first|")
fi

echo "Issue Summary:"
echo "  Critical: $CRITICAL_ISSUES"
echo "  High: $HIGH_ISSUES"
echo "  Medium: $MEDIUM_ISSUES"
echo "  Low: $LOW_ISSUES"
echo "  Total: $TOTAL_ISSUES (showing max 50)"
echo ""
```

## GENERATE ANALYSIS REPORT

**Compact table output:**

```bash
ANALYSIS_REPORT="$FEATURE_DIR/analysis.md"

echo "Writing analysis report: $ANALYSIS_REPORT"
echo ""

cat > "$ANALYSIS_REPORT" <<EOF
# Specification Analysis Report

**Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Feature**: $(basename "$FEATURE_DIR")

---

## Executive Summary

- Total Requirements: $((FUNCTIONAL_COUNT + NFR_COUNT))
- Total Tasks: $TASK_COUNT
- Coverage: $(if [ "$FUNCTIONAL_COUNT" -gt 0 ]; then echo "$(( (FUNCTIONAL_COUNT - ${#UNCOVERED_REQS[@]}) * 100 / FUNCTIONAL_COUNT ))%"; else echo "N/A"; fi)
- Critical Issues: $CRITICAL_ISSUES
- High Issues: $HIGH_ISSUES
- Medium Issues: $MEDIUM_ISSUES
- Low Issues: $LOW_ISSUES

**Status**: $(if [ "$CRITICAL_ISSUES" -gt 0 ]; then echo "❌ Blocked"; elif [ "$HIGH_ISSUES" -gt 0 ]; then echo "⚠️ Review recommended"; else echo "✅ Ready for implementation"; fi)

---

## Findings

| ID | Category | Severity | Location(s) | Summary | Recommendation |
|----|----------|----------|-------------|---------|----------------|
EOF

# Add findings to table
FINDING_ID=1
for finding in "${ALL_FINDINGS[@]}"; do
  SEVERITY=$(echo "$finding" | cut -d'|' -f1)
  CATEGORY=$(echo "$finding" | cut -d'|' -f2)
  LOCATION=$(echo "$finding" | cut -d'|' -f3)
  SUMMARY=$(echo "$finding" | cut -d'|' -f4)
  RECOMMENDATION=$(echo "$finding" | cut -d'|' -f5)

  # Generate stable ID based on category
  CATEGORY_PREFIX=$(echo "$CATEGORY" | head -c 1 | tr '[:lower:]' '[:upper:]')

  echo "| ${CATEGORY_PREFIX}${FINDING_ID} | $CATEGORY | $SEVERITY | $LOCATION | $SUMMARY | $RECOMMENDATION |" >> "$ANALYSIS_REPORT"
  ((FINDING_ID++))
done

cat >> "$ANALYSIS_REPORT" <<EOF

---

## Coverage Summary

| Requirement | Has Task? | Task IDs | Notes |
|-------------|-----------|----------|-------|
EOF

# Add coverage mapping (top 20 requirements)
REQ_COUNT=0
while IFS= read -r req; do
  [ -z "$req" ] && continue
  ((REQ_COUNT++))

  # Check if covered
  KEY_TERMS=$(echo "$req" | grep -oE "[A-Z][a-z]+" | head -3 | tr '\n' ' ')
  MATCHING_TASKS=$(grep -n "^- \[ \] T[0-9]" "$TASKS_FILE" | \
                   grep -i "$KEY_TERMS" | \
                   grep -o "T[0-9]\{3\}" | \
                   tr '\n' ',' | \
                   sed 's/,$//')

  if [ -n "$MATCHING_TASKS" ]; then
    COVERED="✅"
  else
    COVERED="❌"
    MATCHING_TASKS="None"
  fi

  REQ_SHORT=$(echo "$req" | head -c 50)
  echo "| $REQ_SHORT... | $COVERED | $MATCHING_TASKS | |" >> "$ANALYSIS_REPORT"

  # Limit to 20 rows
  if [ "$REQ_COUNT" -ge 20 ]; then
    REMAINING=$((FUNCTIONAL_COUNT - 20))
    if [ "$REMAINING" -gt 0 ]; then
      echo "| ... and $REMAINING more requirements | | | See full spec.md |" >> "$ANALYSIS_REPORT"
    fi
    break
  fi
done <<< "$FUNCTIONAL_REQS"

cat >> "$ANALYSIS_REPORT" <<EOF

---

## Metrics

- **Requirements**: $FUNCTIONAL_COUNT functional + $NFR_COUNT non-functional
- **Tasks**: $TASK_COUNT total ($STORY_TASKS story-specific, $PARALLEL_TASKS parallelizable)
- **User Stories**: $STORY_COUNT
- **Coverage**: $(if [ "$FUNCTIONAL_COUNT" -gt 0 ]; then echo "$(( (FUNCTIONAL_COUNT - ${#UNCOVERED_REQS[@]}) * 100 / FUNCTIONAL_COUNT ))%"; else echo "N/A"; fi) of requirements mapped to tasks
- **Ambiguity**: ${#AMBIGUOUS_REQS[@]} vague terms, ${#PLACEHOLDERS[@]} unresolved placeholders
- **Duplication**: ${#DUPLICATES[@]} potential duplicates
- **Critical Issues**: $CRITICAL_ISSUES

---

## Next Actions

EOF

# Generate recommendations based on severity
if [ "$CRITICAL_ISSUES" -gt 0 ]; then
  cat >> "$ANALYSIS_REPORT" <<EOF
**⛔ BLOCKED**: Fix $CRITICAL_ISSUES critical issue(s) before proceeding.

1. Review critical issues in findings table above
2. Update spec.md, plan.md, or tasks.md to address
3. Re-run: \`/validate\`

Do NOT proceed to /implement until critical issues resolved.
EOF
elif [ "$HIGH_ISSUES" -gt 0 ]; then
  cat >> "$ANALYSIS_REPORT" <<EOF
**⚠️ REVIEW RECOMMENDED**: $HIGH_ISSUES high-priority issue(s) found.

Options:
- A) Fix high-priority issues first (recommended)
- B) Proceed with caution (/implement will address during TDD)

Next: \`/implement\` (or fix issues first)
EOF
else
  cat >> "$ANALYSIS_REPORT" <<EOF
**✅ READY FOR IMPLEMENTATION**

Next: \`/implement\`

/implement will:
1. Execute tasks from tasks.md ($TASK_COUNT tasks)
2. Follow TDD where applicable (RED → GREEN → REFACTOR)
3. Reference polished mockups (if UI feature)
4. Commit after each task
5. Update error-log.md (track issues)

Estimated duration: 2-4 hours
EOF
fi

cat >> "$ANALYSIS_REPORT" <<EOF

---

## Constitution Alignment

EOF

if [ "$HAS_CONSTITUTION" = true ]; then
  if [ ${#CONSTITUTION_VIOLATIONS[@]} -eq 0 ]; then
    echo "✅ All constitution MUST principles addressed" >> "$ANALYSIS_REPORT"
  else
    echo "❌ ${#CONSTITUTION_VIOLATIONS[@]} constitution violation(s) found (see findings table)" >> "$ANALYSIS_REPORT"
  fi
else
  echo "ℹ️ No constitution.md found (skipping principle validation)" >> "$ANALYSIS_REPORT"
fi

echo "" >> "$ANALYSIS_REPORT"
echo "✅ Report written: $ANALYSIS_REPORT"
```

## OFFER REMEDIATION

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Remediation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$TOTAL_ISSUES" -gt 0 ]; then
  echo "Would you like me to suggest concrete remediation edits for the top issues?"
  echo "(This will NOT automatically apply changes - you must approve first)"
  echo ""
  echo "Reply 'yes' to see remediation suggestions, or 'no' to skip."

  # User will respond in next message
  # If 'yes', generate specific edit recommendations
  # If 'no', proceed to return summary
fi
```

## TASK STATUS CONSISTENCY CHECK

```bash
echo ""
echo "🔍 Validating task status consistency..."

# Check for task-tracker availability
TASK_TRACKER=".spec-flow/scripts/bash/task-tracker.sh"
if [ -f "$TASK_TRACKER" ]; then
  # Run task-tracker validation
  VALIDATION_RESULT=$(pwsh -File ".spec-flow/scripts/powershell/task-tracker.ps1" \
    validate -FeatureDir "$FEATURE_DIR" -Json 2>/dev/null || echo '{"Valid":false,"Issues":[]}')

  # Parse validation results
  IS_VALID=$(echo "$VALIDATION_RESULT" | jq -r '.Valid' 2>/dev/null || echo "false")
  ISSUE_COUNT=$(echo "$VALIDATION_RESULT" | jq -r '.Issues | length' 2>/dev/null || echo "0")

  if [ "$IS_VALID" != "true" ] && [ "$ISSUE_COUNT" -gt 0 ]; then
    echo "⚠️  Found $ISSUE_COUNT task status inconsistency issue(s)"
    echo "$VALIDATION_RESULT" | jq -r '.Issues[]' 2>/dev/null || echo "Unable to parse issues"
    echo ""
    echo "To fix inconsistencies, run:"
    echo "  pwsh -File .spec-flow/scripts/powershell/task-tracker.ps1 sync-status -FeatureDir \"$FEATURE_DIR\""
    echo ""
    MEDIUM_ISSUES=$((MEDIUM_ISSUES + 1))
  else
    echo "✅ Task status consistent (tasks.md ↔ NOTES.md)"
  fi
else
  echo "⚠️  task-tracker not found - skipping consistency check"
fi

echo ""
```

## COMMIT ANALYSIS

**After creating analysis report, commit the artifacts:**

```bash
# Stage analysis artifacts
git add "$ANALYSIS_REPORT"

# Commit with analysis summary
git commit -m "docs(analyze): create cross-artifact analysis for $(basename "$FEATURE_DIR")

- Consistency checks performed
- Issues found: $TOTAL_ISSUES
- Critical blockers: $CRITICAL_ISSUES
- Ready for implementation: $([ "$CRITICAL_ISSUES" -eq 0 ] && echo 'YES' || echo 'NO')

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# Verify commit succeeded
COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""
echo "✅ Analysis committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""
```

## RETURN

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Analysis Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Report: $(basename "$FEATURE_DIR")/analysis.md"
echo ""
echo "📊 Summary:"
echo "- Requirements: $((FUNCTIONAL_COUNT + NFR_COUNT))"
echo "- Tasks: $TASK_COUNT"
echo "- Coverage: $(if [ "$FUNCTIONAL_COUNT" -gt 0 ]; then echo "$(( (FUNCTIONAL_COUNT - ${#UNCOVERED_REQS[@]}) * 100 / FUNCTIONAL_COUNT ))%"; else echo "N/A"; fi)"
echo "- Issues: $TOTAL_ISSUES (C:$CRITICAL_ISSUES H:$HIGH_ISSUES M:$MEDIUM_ISSUES L:$LOW_ISSUES)"
echo ""

if [ "$CRITICAL_ISSUES" -gt 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⛔ BLOCKED: $CRITICAL_ISSUES critical issue(s)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Fix critical issues before proceeding"
  echo "Then re-run: /validate"
elif [ "$HIGH_ISSUES" -gt 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  REVIEW RECOMMENDED: $HIGH_ISSUES high-priority issue(s)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Next: /implement (or fix issues first)"
else
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ READY FOR IMPLEMENTATION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Next: /implement"
fi

echo ""
```
S"
echo "- High: $HIGH_ISSUES"
echo "- Medium: $MEDIUM_ISSUES"
echo "- Low: $LOW_ISSUES"
echo ""
echo "📄 Reports:"
echo "- Human: $(basename "$FEATURE_DIR")/analysis-report.md"
echo "- SARIF: $(basename "$FEATURE_DIR")/analysis.sarif.json"
echo ""

if [ "$CRITICAL_ISSUES" -gt 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⛔ BLOCKED: $CRITICAL_ISSUES critical issue(s)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Fix critical issues before proceeding"
  echo "Then re-run: /validate"
elif [ "$HIGH_ISSUES" -gt 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  REVIEW: $HIGH_ISSUES high-priority issue(s)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Next: /implement (or fix issues first)"
else
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ READY FOR IMPLEMENTATION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Next: /implement"
fi

echo ""
```

 "- High: $HIGH_ISSUES"
echo "- Medium: $MEDIUM_ISSUES"
echo "- Low: $LOW_ISSUES"
echo ""
echo "📄 Reports:"
echo "- Human: $(basename "$FEATURE_DIR")/analysis-report.md"
echo "- SARIF: $(basename "$FEATURE_DIR")/analysis.sarif.json"
echo ""

if [ "$CRITICAL_ISSUES" -gt 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⛔ BLOCKED: $CRITICAL_ISSUES critical issue(s)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Fix critical issues before proceeding"
  echo "Then re-run: /validate"
elif [ "$HIGH_ISSUES" -gt 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  REVIEW: $HIGH_ISSUES high-priority issue(s)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Next: /implement (or fix issues first)"
else
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ READY FOR IMPLEMENTATION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Next: /implement"
fi

echo ""
```

</instructions>
