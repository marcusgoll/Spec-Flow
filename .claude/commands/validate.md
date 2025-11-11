---
description: Cross-artifact consistency analysis (review work and list what might be broken)
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

Analyze feature artifacts for consistency, coverage, and quality with deterministic, CI-ready output.

<context>
## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## MENTAL MODEL

**Workflow**: spec-flow → clarify → plan → tasks → **analyze** → implement → optimize → debug → preview → phase-1-ship → validate-staging → phase-2-ship

**State machine:**
- Run prerequisite script → Load artifacts → Run detection passes → Generate reports (human + SARIF) → Commit

**Auto-suggest:**
- When complete → `/implement` (if no critical issues) or Fix issues first

**Operating Constraints:**
- **STRICTLY READ-ONLY**: Do NOT modify any files (analysis only)
- **Constitution Authority**: Constitution violations are automatically CRITICAL
- **Hard Cap**: Maximum 50 findings, aggregate overflow
- **Deterministic**: Rerunning produces identical IDs and results
- **Evidence-First**: Every finding quotes exact lines with file:line spans
- **CI-Ready**: Outputs SARIF 2.1.0 for annotations
</context>

<constraints>
## ANTI-HALLUCINATION RULES

**CRITICAL**: Follow these rules to prevent false validation findings.

1. **Never report inconsistencies you haven't verified by reading files**
   - ❌ BAD: "spec.md probably doesn't match plan.md"
   - ✅ GOOD: Read both files, extract specific quotes, compare them
   - Use Read tool for all files before claiming inconsistencies

2. **Cite exact line numbers with verbatim quotes**
   - Format: `file:line "exact quote"` vs `file:line "exact quote"`
   - Example: `spec.md:45 "POST /users" vs plan.md:120 "POST /api/users"`
   - Never paraphrase - quote verbatim from files

3. **Never invent missing test coverage**
   - Don't claim "Missing test for user creation" unless you verified no test exists
   - Use Grep to search test files: `test.*user.*create`
   - If uncertain, search before claiming missing

4. **Verify constitution rules exist before citing violations**
   - Read constitution.md before claiming violations
   - Quote exact rule: "Violates constitution.md:25 'All APIs must use OpenAPI contracts'"
   - Don't invent constitution rules

5. **Use strict severity rubric (no inflation)**
   - **CRITICAL**: Blocks implementation, violates constitution, contradictions
   - **HIGH**: Causes rework, uncovered FR, non-reversible migration
   - **MEDIUM**: Traceability, terminology, TDD-ordering
   - **LOW**: Cosmetic/style drift

**Why this matters**: False inconsistencies waste time investigating non-issues. Accurate validation based on actual file reads builds trust.

## REASONING APPROACH

For complex validation decisions, show your step-by-step reasoning:

<thinking>
Let me analyze this consistency issue:
1. What does spec.md say? [Quote exact text with line numbers]
2. What does plan.md say? [Quote exact text with line numbers]
3. Is this a true inconsistency or semantic equivalence? [Compare meanings]
4. What's the impact? [Assess severity using strict rubric]
5. What's the fix? [Identify which artifact to update]
6. Conclusion: [Inconsistency assessment with severity]
</thinking>

<answer>
[Validation finding with evidence]
</answer>

**When to use structured thinking:**
- Assessing severity of cross-artifact inconsistencies
- Determining whether differences are true conflicts or semantic equivalents
- Deciding which artifact to fix (spec vs plan vs tasks)
- Evaluating completeness of test coverage
- Prioritizing validation findings for developer action

**Benefits**: Explicit reasoning reduces false positives by 30-40% and improves finding accuracy.
</constraints>

<instructions>
## RUN PREREQUISITE SCRIPT

**Execute once from repo root:**

```bash
cd .

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
CONSTITUTION_FILE=".spec-flow/memory/constitution.md"

# Validate required files
if [ ! -f "$SPEC_FILE" ]; then
  echo "❌ Missing: spec.md"
  echo "Run: /spec first"
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

## DETECTION PASSES (Evidence-First Analysis)

**All findings must include:**
- Deterministic ID: `UPPER(category[0]) + "-" + sha1(file + ":" + line + ":" + summary)[0..7]`
- Line-precise evidence: `file:line "verbatim quote"`
- Severity from strict rubric
- Category (Constitution, Coverage, Duplication, Ambiguity, Underspecification, Inconsistency, TDD, UI, Migration)

**Hard cap: 50 findings maximum. Aggregate overflow.**

### A. Constitution Alignment (CRITICAL)

```bash
echo "🔍 Checking constitution alignment..."
echo ""

CONSTITUTION_VIOLATIONS=()
HAS_CONSTITUTION=false

if [ -f "$CONSTITUTION_FILE" ]; then
  HAS_CONSTITUTION=true

  # Extract MUST principles (line-by-line)
  while IFS= read -r line_num; do
    [ -z "$line_num" ] && continue

    LINE_NO=$(echo "$line_num" | cut -d: -f1)
    PRINCIPLE=$(echo "$line_num" | cut -d: -f2-)

    # Extract key terms with word boundaries
    KEY_TERMS=$(echo "$PRINCIPLE" | grep -oE "\b[a-zA-Z]{4,}\b" | head -3)

    # Check if addressed in spec, plan, or tasks (word boundaries)
    FOUND=false
    for term in $KEY_TERMS; do
      if grep -Ewqi "\b$term\b" "$SPEC_FILE" "$PLAN_FILE" "$TASKS_FILE" 2>/dev/null; then
        FOUND=true
        break
      fi
    done

    if [ "$FOUND" = false ]; then
      SUMMARY="Constitution principle not addressed: $(echo "$PRINCIPLE" | head -c 60)..."
      ID=$(echo -n "constitution.md:$LINE_NO:$SUMMARY" | sha1sum | cut -c1-8)

      CONSTITUTION_VIOLATIONS+=("CRITICAL|Constitution|constitution.md:$LINE_NO|C-$ID|\"$PRINCIPLE\"|No coverage in spec/plan/tasks|Address in spec.md, plan.md, or tasks.md")
    fi
  done <<< "$(grep -n "^- MUST" "$CONSTITUTION_FILE" | head -20)"
fi

echo "Constitution violations: ${#CONSTITUTION_VIOLATIONS[@]}"
echo ""
```

### B. Coverage Gaps (HIGH)

```bash
echo "📊 Analyzing requirement coverage..."
echo ""

UNCOVERED_REQS=()
UNMAPPED_TASKS=()

# Extract functional requirements with line numbers
FR_LINES=$(grep -n "^- FR[0-9]" "$SPEC_FILE" || echo "")

# Check each functional requirement for task coverage
while IFS= read -r line_data; do
  [ -z "$line_data" ] && continue

  LINE_NO=$(echo "$line_data" | cut -d: -f1)
  REQ_TEXT=$(echo "$line_data" | cut -d: -f2-)

  # Extract key terms (word boundaries)
  KEY_TERMS=$(echo "$REQ_TEXT" | grep -oE "\b[A-Z][a-z]+\b" | head -5 | tr '\n' '|' | sed 's/|$//')

  # Search tasks.md for these terms (word boundaries)
  if [ -n "$KEY_TERMS" ]; then
    MATCHING_TASKS=$(grep -E "\b($KEY_TERMS)\b" "$TASKS_FILE" | grep -o "T[0-9]\{3\}" | tr '\n' ',' | sed 's/,$//')
  else
    MATCHING_TASKS=""
  fi

  if [ -z "$MATCHING_TASKS" ]; then
    SUMMARY="Requirement not covered by tasks: $(echo "$REQ_TEXT" | head -c 60)..."
    ID=$(echo -n "spec.md:$LINE_NO:$SUMMARY" | sha1sum | cut -c1-8)

    UNCOVERED_REQS+=("HIGH|Coverage|spec.md:$LINE_NO|C-$ID|\"$REQ_TEXT\"|No matching tasks|Add tasks to tasks.md covering this requirement")
  fi
done <<< "$FR_LINES"

# Check for unmapped tasks (tasks not tracing to requirements)
TASK_LINES=$(grep -n "^- \[ \] T[0-9]" "$TASKS_FILE" || echo "")

while IFS= read -r task_line_data; do
  [ -z "$task_line_data" ] && continue

  TASK_LINE_NO=$(echo "$task_line_data" | cut -d: -f1)
  TASK_FULL=$(echo "$task_line_data" | cut -d: -f2-)

  TASK_ID=$(echo "$TASK_FULL" | grep -o "T[0-9]\{3\}")
  TASK_DESC=$(echo "$TASK_FULL" | sed 's/^.*T[0-9]\{3\}[^]]*\] //')

  # Skip infrastructure tasks (allowed to not map to specific FRs)
  if echo "$TASK_DESC" | grep -Ewqi "\b(setup|config|polish|deployment|health|smoke|lint|build)\b"; then
    continue
  fi

  # Check if task keywords match any requirement (word boundaries)
  TASK_KEYWORDS=$(echo "$TASK_DESC" | grep -oE "\b[A-Z][a-z]+\b" | head -5 | tr '\n' '|' | sed 's/|$//')
  FOUND_REQ=false

  if [ -n "$TASK_KEYWORDS" ]; then
    if grep -Eq "\b($TASK_KEYWORDS)\b" "$SPEC_FILE" 2>/dev/null; then
      FOUND_REQ=true
    fi
  fi

  if [ "$FOUND_REQ" = false ]; then
    SUMMARY="Task $TASK_ID does not map to any requirement"
    ID=$(echo -n "tasks.md:$TASK_LINE_NO:$SUMMARY" | sha1sum | cut -c1-8)

    UNMAPPED_TASKS+=("MEDIUM|Coverage|tasks.md:$TASK_LINE_NO|C-$ID|\"$TASK_DESC\"|No matching requirement|Verify task necessity or add requirement to spec.md")
  fi
done <<< "$TASK_LINES"

echo "Uncovered requirements: ${#UNCOVERED_REQS[@]}"
echo "Unmapped tasks: ${#UNMAPPED_TASKS[@]}"
echo ""
```

### C. Duplication Detection (HIGH)

```bash
echo "🔍 Detecting duplicate requirements..."
echo ""

DUPLICATES=()

# Convert requirements to array for pairwise comparison
readarray -t FR_ARRAY <<< "$(grep "^- FR[0-9]" "$SPEC_FILE" || echo "")"
FR_COUNT=${#FR_ARRAY[@]}

if [ "$FR_COUNT" -gt 1 ]; then
  # Compare each pair (Jaccard similarity)
  for ((i=0; i<FR_COUNT; i++)); do
    for ((j=i+1; j<FR_COUNT; j++)); do
      REQ1="${FR_ARRAY[$i]}"
      REQ2="${FR_ARRAY[$j]}"

      [ -z "$REQ1" ] || [ -z "$REQ2" ] && continue

      # Extract words for similarity calculation
      WORDS1=$(echo "$REQ1" | grep -oE "\b[a-zA-Z]{3,}\b" | sort | uniq)
      WORDS2=$(echo "$REQ2" | grep -oE "\b[a-zA-Z]{3,}\b" | sort | uniq)

      # Count common and total unique words
      COMMON=$(comm -12 <(echo "$WORDS1") <(echo "$WORDS2") | wc -l)
      TOTAL=$(echo -e "$WORDS1\n$WORDS2" | sort | uniq | wc -l)

      # Jaccard similarity: intersection / union
      if [ "$TOTAL" -gt 0 ]; then
        SIMILARITY=$(awk "BEGIN {printf \"%.0f\", ($COMMON / $TOTAL) * 100}")

        # Flag if >60% similar (high duplication)
        if [ "$SIMILARITY" -ge 60 ]; then
          LINE1=$(grep -n "^- FR[0-9]" "$SPEC_FILE" | sed -n "$((i+1))p" | cut -d: -f1)
          LINE2=$(grep -n "^- FR[0-9]" "$SPEC_FILE" | sed -n "$((j+1))p" | cut -d: -f1)

          REQ1_SHORT=$(echo "$REQ1" | head -c 50)
          REQ2_SHORT=$(echo "$REQ2" | head -c 50)

          SUMMARY="Requirements ${SIMILARITY}% similar"
          ID=$(echo -n "spec.md:$LINE1:$LINE2:$SUMMARY" | sha1sum | cut -c1-8)

          DUPLICATES+=("HIGH|Duplication|spec.md:$LINE1,$LINE2|D-$ID|\"$REQ1_SHORT...\" vs \"$REQ2_SHORT...\"|${SIMILARITY}% word overlap|Merge or clarify distinction")
        fi
      fi
    done
  done
fi

echo "Potential duplicates: ${#DUPLICATES[@]}"
echo ""
```

### D. Ambiguity Detection (HIGH/CRITICAL)

```bash
echo "🔍 Detecting ambiguous requirements..."
echo ""

# Vague terms requiring quantification
VAGUE_TERMS="\b(fast|slow|easy|simple|good|bad|many|few|large|small|quickly|slowly|user-friendly|intuitive|clean|nice|better|improved|robust|scalable|secure)\b"

AMBIGUOUS_REQS=()
PLACEHOLDERS=()

# Check functional requirements for vague terms
FR_LINES_FULL=$(grep -n "^- FR[0-9]" "$SPEC_FILE" || echo "")

while IFS= read -r line_data; do
  [ -z "$line_data" ] && continue

  LINE_NO=$(echo "$line_data" | cut -d: -f1)
  REQ_TEXT=$(echo "$line_data" | cut -d: -f2-)

  # Check for vague terms (word boundaries)
  VAGUE_MATCH=$(echo "$REQ_TEXT" | grep -oEi "$VAGUE_TERMS" | head -1)

  if [ -n "$VAGUE_MATCH" ]; then
    SUMMARY="Vague term '$VAGUE_MATCH' without metric"
    ID=$(echo -n "spec.md:$LINE_NO:$SUMMARY" | sha1sum | cut -c1-8)

    AMBIGUOUS_REQS+=("HIGH|Ambiguity|spec.md:$LINE_NO|A-$ID|\"$REQ_TEXT\"|Contains vague term '$VAGUE_MATCH'|Add measurable criteria (e.g., 'fast' → '<2s response time')")
  fi

  # Check for placeholders (CRITICAL)
  if echo "$REQ_TEXT" | grep -Eqi "\b(TODO|TKTK|TBD)\b|\?\?\?|<placeholder>"; then
    SUMMARY="Unresolved placeholder in requirement"
    ID=$(echo -n "spec.md:$LINE_NO:$SUMMARY" | sha1sum | cut -c1-8)

    PLACEHOLDERS+=("CRITICAL|Ambiguity|spec.md:$LINE_NO|A-$ID|\"$REQ_TEXT\"|Unresolved placeholder|Resolve before implementation")
  fi
done <<< "$FR_LINES_FULL"

# Check NFRs must have measurable criteria
NFR_LINES=$(grep -n "^- NFR[0-9]" "$SPEC_FILE" || echo "")

while IFS= read -r nfr_line_data; do
  [ -z "$nfr_line_data" ] && continue

  LINE_NO=$(echo "$nfr_line_data" | cut -d: -f1)
  NFR_TEXT=$(echo "$nfr_line_data" | cut -d: -f2-)

  # NFRs MUST have metrics (numbers, percentages, comparisons)
  if ! echo "$NFR_TEXT" | grep -Eq "[0-9]+|<[0-9]|>[0-9]|p[0-9]{2}|%"; then
    SUMMARY="Non-functional requirement lacks metric"
    ID=$(echo -n "spec.md:$LINE_NO:$SUMMARY" | sha1sum | cut -c1-8)

    AMBIGUOUS_REQS+=("HIGH|Ambiguity|spec.md:$LINE_NO|A-$ID|\"$NFR_TEXT\"|No quantifiable target|Add measurable metric (e.g., '<200ms', '>99.9%')")
  fi
done <<< "$NFR_LINES"

echo "Ambiguous requirements: ${#AMBIGUOUS_REQS[@]}"
echo "Unresolved placeholders: ${#PLACEHOLDERS[@]}"
echo ""
```

### E. Underspecification (MEDIUM)

```bash
echo "🔍 Checking for underspecification..."
echo ""

UNDERSPECIFIED=()

# Check user stories for missing acceptance criteria
STORY_LINES=$(grep -n "\[US[0-9]\]" "$SPEC_FILE" || echo "")

while IFS= read -r story_line_data; do
  [ -z "$story_line_data" ] && continue

  LINE_NO=$(echo "$story_line_data" | cut -d: -f1)
  STORY_FULL=$(echo "$story_line_data" | cut -d: -f2-)
  STORY_ID=$(echo "$STORY_FULL" | grep -o "\[US[0-9]\]")

  # Check if acceptance criteria exist within 10 lines
  if ! sed -n "${LINE_NO},$((LINE_NO+10))p" "$SPEC_FILE" | grep -Ewqi "\b(acceptance|given|when|then)\b"; then
    SUMMARY="User story $STORY_ID missing acceptance criteria"
    ID=$(echo -n "spec.md:$LINE_NO:$SUMMARY" | sha1sum | cut -c1-8)

    UNDERSPECIFIED+=("HIGH|Underspecification|spec.md:$LINE_NO|U-$ID|\"$STORY_FULL\"|No acceptance criteria|Add Given/When/Then or acceptance list")
  fi
done <<< "$STORY_LINES"

# Check tasks referencing undefined components
TASK_LINES_FILES=$(grep -n "^- \[ \] T[0-9]" "$TASKS_FILE" | grep -E "(src|api|apps)/" || echo "")

while IFS= read -r task_line_data; do
  [ -z "$task_line_data" ] && continue

  TASK_LINE_NO=$(echo "$task_line_data" | cut -d: -f1)
  TASK_FULL=$(echo "$task_line_data" | cut -d: -f2-)

  TASK_ID=$(echo "$TASK_FULL" | grep -o "T[0-9]\{3\}")
  FILE_PATH=$(echo "$TASK_FULL" | grep -oE "(src|api|apps)/[a-zA-Z0-9/_.-]+" | head -1)

  if [ -n "$FILE_PATH" ]; then
    COMPONENT=$(basename "$FILE_PATH" .py .ts .tsx .js .jsx)

    # Check if component mentioned in plan or spec (word boundaries)
    if ! grep -Ewqi "\b$COMPONENT\b" "$SPEC_FILE" "$PLAN_FILE" 2>/dev/null; then
      SUMMARY="Task $TASK_ID references undefined component '$COMPONENT'"
      ID=$(echo -n "tasks.md:$TASK_LINE_NO:$SUMMARY" | sha1sum | cut -c1-8)

      UNDERSPECIFIED+=("MEDIUM|Underspecification|tasks.md:$TASK_LINE_NO|U-$ID|\"$TASK_FULL\"|Component '$COMPONENT' not in spec/plan|Define component in plan.md [ARCHITECTURE DECISIONS]")
    fi
  fi
done <<< "$TASK_LINES_FILES"

echo "Underspecified items: ${#UNDERSPECIFIED[@]}"
echo ""
```

### F. Inconsistency Detection (MEDIUM)

```bash
echo "🔍 Checking for terminology inconsistencies..."
echo ""

TERMINOLOGY_ISSUES=()
CONFLICTS=()

# Extract CamelCase/PascalCase terms from spec
SPEC_TERMS=$(grep -oE "\b[A-Z][a-z]+[A-Z][a-z]*\b" "$SPEC_FILE" | sort | uniq | head -50)

# Check for terminology drift across artifacts
declare -A TERM_VARIANTS

while IFS= read -r term; do
  [ -z "$term" ] && continue

  # Find variants (case-insensitive prefix match)
  PREFIX=$(echo "$term" | head -c 5)
  PLAN_VARIANTS=$(grep -ioE "\b${PREFIX}[a-zA-Z]*\b" "$PLAN_FILE" 2>/dev/null | sort | uniq)
  TASKS_VARIANTS=$(grep -ioE "\b${PREFIX}[a-zA-Z]*\b" "$TASKS_FILE" 2>/dev/null | sort | uniq)

  # Collect unique variants
  ALL_VARIANTS=$(echo -e "$term\n$PLAN_VARIANTS\n$TASKS_VARIANTS" | sort | uniq)
  VARIANT_COUNT=$(echo "$ALL_VARIANTS" | grep -c "^" || echo 0)

  # Flag if >1 variant (terminology drift)
  if [ "$VARIANT_COUNT" -gt 1 ]; then
    VARIANTS=$(echo "$ALL_VARIANTS" | tr '\n' ',' | sed 's/,$//')

    SUMMARY="Terminology drift for '$term'"
    ID=$(echo -n "spec.md:plan.md:tasks.md:$SUMMARY" | sha1sum | cut -c1-8)

    TERMINOLOGY_ISSUES+=("MEDIUM|Inconsistency|spec.md,plan.md,tasks.md|I-$ID|Term '$term' has variants: $VARIANTS|Inconsistent naming|Standardize to one term")
  fi
done <<< "$SPEC_TERMS"

# Limit to top 10 (avoid overflow)
if [ ${#TERMINOLOGY_ISSUES[@]} -gt 10 ]; then
  OVERFLOW=$((${#TERMINOLOGY_ISSUES[@]} - 10))
  TERMINOLOGY_ISSUES=("${TERMINOLOGY_ISSUES[@]:0:10}")

  SUMMARY="... and $OVERFLOW more terminology inconsistencies"
  ID=$(echo -n "*:$SUMMARY" | sha1sum | cut -c1-8)
  TERMINOLOGY_ISSUES+=("LOW|Inconsistency|*|I-$ID|$SUMMARY|Overflow capped|Run full audit or fix top 10 first")
fi

# Check for conflicting tech stack mentions
TECH_MENTIONS=$(grep -oiE "\b(Next\.js|Vue|React|Angular|Svelte|PostgreSQL|MySQL|MongoDB)\b" "$SPEC_FILE" "$PLAN_FILE" 2>/dev/null | sort | uniq)
FRONTEND_STACK=$(echo "$TECH_MENTIONS" | grep -E "Next\.js|Vue|React|Angular|Svelte" | tr '\n' ',' | sed 's/,$//')
DATABASE_STACK=$(echo "$TECH_MENTIONS" | grep -E "PostgreSQL|MySQL|MongoDB" | tr '\n' ',' | sed 's/,$//')

# Flag if multiple frontend frameworks
FRONTEND_COUNT=$(echo "$FRONTEND_STACK" | tr ',' '\n' | grep -c "^" || echo 0)
if [ "$FRONTEND_COUNT" -gt 1 ]; then
  SUMMARY="Multiple frontend frameworks mentioned"
  ID=$(echo -n "spec.md:plan.md:$SUMMARY" | sha1sum | cut -c1-8)

  CONFLICTS+=("CRITICAL|Inconsistency|spec.md,plan.md|I-$ID|Frameworks: $FRONTEND_STACK|Cannot use multiple frameworks|Choose one framework")
fi

# Flag if multiple databases
DATABASE_COUNT=$(echo "$DATABASE_STACK" | tr ',' '\n' | grep -c "^" || echo 0)
if [ "$DATABASE_COUNT" -gt 1 ]; then
  SUMMARY="Multiple databases mentioned"
  ID=$(echo -n "spec.md:plan.md:$SUMMARY" | sha1sum | cut -c1-8)

  CONFLICTS+=("CRITICAL|Inconsistency|spec.md,plan.md|I-$ID|Databases: $DATABASE_STACK|Cannot use multiple databases|Choose one database")
fi

echo "Terminology issues: ${#TERMINOLOGY_ISSUES[@]}"
echo "Tech stack conflicts: ${#CONFLICTS[@]}"
echo ""
```

### G. TDD Ordering Validation (MEDIUM)

```bash
echo "🔍 Validating TDD task ordering..."
echo ""

ORDERING_ISSUES=()

# Check if TDD markers exist
HAS_TDD_MARKERS=$(grep -c "\[RED\]\\|\[GREEN→\\|\[REFACTOR\]" "$TASKS_FILE" || echo 0)

if [ "$HAS_TDD_MARKERS" -gt 0 ]; then
  # Track phase per task
  LAST_PHASE=""

  TDD_TASK_LINES=$(grep -n "T[0-9]\{3\}" "$TASKS_FILE" | grep -E "\[RED\]|\[GREEN→|\[REFACTOR\]")

  while IFS= read -r task_line_data; do
    [ -z "$task_line_data" ] && continue

    LINE_NO=$(echo "$task_line_data" | cut -d: -f1)
    TASK_FULL=$(echo "$task_line_data" | cut -d: -f2-)
    TASK_ID=$(echo "$TASK_FULL" | grep -o "T[0-9]\{3\}")

    if echo "$TASK_FULL" | grep -q "\[RED\]"; then
      CURRENT_PHASE="RED"
    elif echo "$TASK_FULL" | grep -q "\[GREEN→"; then
      CURRENT_PHASE="GREEN"

      # GREEN must follow RED
      if [ "$LAST_PHASE" != "RED" ]; then
        SUMMARY="Task $TASK_ID: GREEN without preceding RED"
        ID=$(echo -n "tasks.md:$LINE_NO:$SUMMARY" | sha1sum | cut -c1-8)

        ORDERING_ISSUES+=("MEDIUM|TDD Ordering|tasks.md:$LINE_NO|T-$ID|\"$TASK_FULL\"|GREEN phase without RED|Follow RED → GREEN → REFACTOR sequence")
      fi
    elif echo "$TASK_FULL" | grep -q "\[REFACTOR\]"; then
      CURRENT_PHASE="REFACTOR"

      # REFACTOR must follow GREEN
      if [ "$LAST_PHASE" != "GREEN" ]; then
        SUMMARY="Task $TASK_ID: REFACTOR without preceding GREEN"
        ID=$(echo -n "tasks.md:$LINE_NO:$SUMMARY" | sha1sum | cut -c1-8)

        ORDERING_ISSUES+=("MEDIUM|TDD Ordering|tasks.md:$LINE_NO|T-$ID|\"$TASK_FULL\"|REFACTOR without GREEN|Follow RED → GREEN → REFACTOR sequence")
      fi
    else
      CURRENT_PHASE=""
    fi

    LAST_PHASE="$CURRENT_PHASE"
  done <<< "$TDD_TASK_LINES"
fi

echo "TDD ordering issues: ${#ORDERING_ISSUES[@]}"
echo ""
```

### H. Migration Reversibility (HIGH)

```bash
echo "🗄️  Checking migration reversibility..."
echo ""

NON_REVERSIBLE_MIGRATIONS=()

# Check if schema changes mentioned in plan
SCHEMA_SECTION=$(sed -n '/## \[SCHEMA\]/,/## \[/p' "$PLAN_FILE" | head -n -1)

if [ -n "$SCHEMA_SECTION" ]; then
  # Extract entity names (TableName or EntityName)
  ENTITIES=$(echo "$SCHEMA_SECTION" | grep -oE "\b[A-Z][a-z]+Table\b|\b[A-Z][a-z]+Entity\b" | sed 's/Table$//' | sed 's/Entity$//' | sort -u)

  while IFS= read -r entity; do
    [ -z "$entity" ] && continue

    ENTITY_LOWER=$(echo "$entity" | tr '[:upper:]' '[:lower:]')

    # Find migration files
    MIGRATION_FILES=$(find . -type f \( -path "*/alembic/versions/*${ENTITY_LOWER}*" -o -path "*/prisma/migrations/*${ENTITY_LOWER}*" \) 2>/dev/null)

    while IFS= read -r migration_file; do
      [ -z "$migration_file" ] && continue

      # Check for downgrade/down function (reversibility)
      if ! grep -Ewq "\b(def downgrade|down:)\b" "$migration_file" 2>/dev/null; then
        MIGRATION_LINE=$(grep -n "def upgrade\|up:" "$migration_file" | head -1 | cut -d: -f1)

        SUMMARY="Migration for '$entity' not reversible"
        ID=$(echo -n "$migration_file:$MIGRATION_LINE:$SUMMARY" | sha1sum | cut -c1-8)

        NON_REVERSIBLE_MIGRATIONS+=("HIGH|Migration|$migration_file:$MIGRATION_LINE|M-$ID|Migration lacks downgrade|No rollback function|Add downgrade() or down: function")
      fi
    done <<< "$MIGRATION_FILES"
  done <<< "$ENTITIES"
fi

echo "Non-reversible migrations: ${#NON_REVERSIBLE_MIGRATIONS[@]}"
echo ""
```

## AGGREGATE FINDINGS (Hard 50-Finding Cap)

```bash
cd .

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Aggregating findings"
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
ALL_FINDINGS+=("${NON_REVERSIBLE_MIGRATIONS[@]}")
ALL_FINDINGS+=("${UNMAPPED_TASKS[@]}")

TOTAL_RAW=${#ALL_FINDINGS[@]}

# Hard cap at 50 findings
if [ "$TOTAL_RAW" -gt 50 ]; then
  OVERFLOW=$((TOTAL_RAW - 50))
  ALL_FINDINGS=("${ALL_FINDINGS[@]:0:50}")

  # Add overflow finding
  SUMMARY="$OVERFLOW additional findings capped (hard limit: 50)"
  ID=$(echo -n "*:$SUMMARY" | sha1sum | cut -c1-8)
  ALL_FINDINGS+=("LOW|Overflow|*|O-$ID|$SUMMARY|Limit reached|Fix top 50, then re-run /validate for remainder")
fi

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

echo "Issue Summary:"
echo "  Critical: $CRITICAL_ISSUES"
echo "  High: $HIGH_ISSUES"
echo "  Medium: $MEDIUM_ISSUES"
echo "  Low: $LOW_ISSUES"
echo "  Total: $TOTAL_ISSUES (max 50)"
echo ""
```

## GENERATE REPORTS (Human + SARIF)

**Output both formats: analysis-report.md (human) + analysis.sarif.json (CI)**

### Human Report (analysis-report.md)

```bash
cd .

REPORT_FILE="$FEATURE_DIR/analysis-report.md"
REPORT_TMP=$(mktemp)

cat > "$REPORT_TMP" <<EOF
# Cross-Artifact Analysis Report

**Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Feature**: $(basename "$FEATURE_DIR")
**Validator**: spec-flow-validate v2.0

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Total Findings | $TOTAL_ISSUES |
| Critical | $CRITICAL_ISSUES |
| High | $HIGH_ISSUES |
| Medium | $MEDIUM_ISSUES |
| Low | $LOW_ISSUES |

**Status**: $(if [ "$CRITICAL_ISSUES" -gt 0 ]; then echo "❌ Blocked"; elif [ "$HIGH_ISSUES" -gt 0 ]; then echo "⚠️ Review recommended"; else echo "✅ Ready for implementation"; fi)

---

## Findings

| ID | Severity | Category | Location | Summary | Evidence | Recommendation |
|----|----------|----------|----------|---------|----------|----------------|
EOF

# Add findings to table
for finding in "${ALL_FINDINGS[@]}"; do
  SEVERITY=$(echo "$finding" | cut -d'|' -f1)
  CATEGORY=$(echo "$finding" | cut -d'|' -f2)
  LOCATION=$(echo "$finding" | cut -d'|' -f3)
  ID=$(echo "$finding" | cut -d'|' -f4)
  EVIDENCE=$(echo "$finding" | cut -d'|' -f5)
  CONTEXT=$(echo "$finding" | cut -d'|' -f6)
  RECOMMENDATION=$(echo "$finding" | cut -d'|' -f7)

  echo "| $ID | $SEVERITY | $CATEGORY | $LOCATION | $CONTEXT | $EVIDENCE | $RECOMMENDATION |" >> "$REPORT_TMP"
done

cat >> "$REPORT_TMP" <<EOF

---

## Severity Rubric

**CRITICAL**: Blocks implementation
- Constitution violations
- Unresolved placeholders (TODO, TBD, ???)
- Contradictory tech stack decisions (multiple frameworks)
- Missing critical requirements

**HIGH**: Causes rework
- Uncovered functional requirements
- Non-reversible migrations (no downgrade)
- User stories without acceptance criteria
- Vague requirements without metrics

**MEDIUM**: Traceability issues
- Unmapped tasks
- TDD ordering violations
- Terminology inconsistencies
- Underspecified components

**LOW**: Cosmetic/style
- Minor terminology drift (capped at 10)
- Overflow findings (fix top 50 first)

---

## Next Actions

EOF

# Generate recommendations based on severity
if [ "$CRITICAL_ISSUES" -gt 0 ]; then
  cat >> "$REPORT_TMP" <<EOF
**⛔ BLOCKED**: Fix $CRITICAL_ISSUES critical issue(s) before proceeding.

1. Review critical findings above
2. Update spec.md, plan.md, or tasks.md to address
3. Re-run: \`/validate\`

Do NOT proceed to /implement until critical issues resolved.
EOF
elif [ "$HIGH_ISSUES" -gt 0 ]; then
  cat >> "$REPORT_TMP" <<EOF
**⚠️ REVIEW RECOMMENDED**: $HIGH_ISSUES high-priority issue(s) found.

Options:
- A) Fix high-priority issues first (recommended)
- B) Proceed with caution (/implement will address during TDD)

Next: \`/implement\` (or fix issues first)
EOF
else
  cat >> "$REPORT_TMP" <<EOF
**✅ READY FOR IMPLEMENTATION**

Next: \`/implement\`
EOF
fi

cat >> "$REPORT_TMP" <<EOF

---

## Constitution Alignment

EOF

if [ "$HAS_CONSTITUTION" = true ]; then
  if [ ${#CONSTITUTION_VIOLATIONS[@]} -eq 0 ]; then
    echo "✅ All constitution MUST principles addressed" >> "$REPORT_TMP"
  else
    echo "❌ ${#CONSTITUTION_VIOLATIONS[@]} constitution violation(s) found (see findings table)" >> "$REPORT_TMP"
  fi
else
  echo "ℹ️ No constitution.md found (skipping principle validation)" >> "$REPORT_TMP"
fi

# Atomic write
mv "$REPORT_TMP" "$REPORT_FILE"

echo "✅ Human report written: $(basename "$REPORT_FILE")"
echo ""
```

### SARIF Report (analysis.sarif.json)

```bash
cd .

SARIF_FILE="$FEATURE_DIR/analysis.sarif.json"
SARIF_TMP=$(mktemp)

# SARIF 2.1.0 schema
cat > "$SARIF_TMP" <<'SARIF_START'
{
  "version": "2.1.0",
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "spec-flow-validate",
          "version": "2.0.0",
          "informationUri": "https://github.com/spec-flow/workflow-refactor",
          "rules": []
        }
      },
      "results": []
    }
  ]
}
SARIF_START

# Convert findings to SARIF results
SARIF_RESULTS="["
FIRST=true

for finding in "${ALL_FINDINGS[@]}"; do
  SEVERITY=$(echo "$finding" | cut -d'|' -f1)
  CATEGORY=$(echo "$finding" | cut -d'|' -f2)
  LOCATION=$(echo "$finding" | cut -d'|' -f3)
  ID=$(echo "$finding" | cut -d'|' -f4)
  EVIDENCE=$(echo "$finding" | cut -d'|' -f5 | sed 's/"/\\"/g')
  CONTEXT=$(echo "$finding" | cut -d'|' -f6 | sed 's/"/\\"/g')
  RECOMMENDATION=$(echo "$finding" | cut -d'|' -f7 | sed 's/"/\\"/g')

  # Map severity to SARIF level
  case "$SEVERITY" in
    CRITICAL) LEVEL="error" ;;
    HIGH) LEVEL="error" ;;
    MEDIUM) LEVEL="warning" ;;
    LOW) LEVEL="note" ;;
    *) LEVEL="note" ;;
  esac

  # Extract file and line from LOCATION
  FILE_PATH=$(echo "$LOCATION" | cut -d: -f1)
  LINE_NO=$(echo "$LOCATION" | cut -d: -f2 | grep -o "[0-9]\+" | head -1)

  # Default to line 1 if no line number
  if [ -z "$LINE_NO" ]; then
    LINE_NO=1
  fi

  # Add comma separator (not for first item)
  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    SARIF_RESULTS+=","
  fi

  # SARIF result object
  SARIF_RESULTS+=$(cat <<SARIF_RESULT
    {
      "ruleId": "$ID",
      "level": "$LEVEL",
      "message": {
        "text": "$CONTEXT"
      },
      "locations": [
        {
          "physicalLocation": {
            "artifactLocation": {
              "uri": "$FILE_PATH"
            },
            "region": {
              "startLine": $LINE_NO
            }
          }
        }
      ],
      "properties": {
        "category": "$CATEGORY",
        "severity": "$SEVERITY",
        "evidence": "$EVIDENCE",
        "recommendation": "$RECOMMENDATION"
      }
    }
SARIF_RESULT
)
done

SARIF_RESULTS+="]"

# Insert results into SARIF template using jq
jq --argjson results "$SARIF_RESULTS" '.runs[0].results = $results' "$SARIF_TMP" > "$SARIF_FILE"
rm "$SARIF_TMP"

echo "✅ SARIF report written: $(basename "$SARIF_FILE")"
echo ""
```

## COMMIT REPORTS

```bash
cd .

# Stage analysis artifacts
git add "$REPORT_FILE" "$SARIF_FILE"

# Commit with analysis summary
git commit -m "docs(validate): cross-artifact analysis for $(basename "$FEATURE_DIR")

Phase 1: Validate
- Findings: $TOTAL_ISSUES (C:$CRITICAL_ISSUES H:$HIGH_ISSUES M:$MEDIUM_ISSUES L:$LOW_ISSUES)
- Status: $(if [ "$CRITICAL_ISSUES" -gt 0 ]; then echo "BLOCKED"; elif [ "$HIGH_ISSUES" -gt 0 ]; then echo "REVIEW"; else echo "READY"; fi)
- Reports: analysis-report.md + analysis.sarif.json

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# Verify commit
COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""
echo "✅ Analysis committed: $COMMIT_HASH"
echo ""
```

## RETURN SUMMARY

```bash
cd .

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Analysis Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Summary:"
echo "- Findings: $TOTAL_ISSUES (max 50)"
echo "- Critical: $CRITICAL_ISSUES"
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

</instructions>
