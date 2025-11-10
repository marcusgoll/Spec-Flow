---
description: Generate concrete, testable TDD tasks from design artifacts with hard verification
---

Create tasks from: specs/$SLUG/plan.md
Output: specs/$SLUG/tasks.json (canonical), specs/$SLUG/tasks.md (rendered)

<constraints>
## GUARANTEES

1. **Deterministic**: same inputs → identical outputs (IDs, order, hashes)
2. **Verifiable**: every file path and section reference exists before emit
3. **Traceable**: each task cites exact plan/spec sections (line ranges)
4. **Machine-readable**: JSON is the source of truth; MD is derived
5. **Acyclic**: dependency graph must be a DAG or generation fails
6. **No placeholders**: zero "[Entity]" or "[file]" strings permitted

## ANTI-HALLUCINATION RULES (ENFORCED)

**Refuse to create a task unless**:
   a) The referenced file exists (checked via `git ls-files`) OR is marked [NEW], and
   b) The referenced section exists (verified in plan/spec), and
   c) Acceptance criteria are quoted verbatim from spec.md when present

**If an item is missing**, stop with a precise error report listing:
   - Missing paths, missing sections, missing AC
   - Provide exact line numbers where issues occur

## REASONING APPROACH

For complex task breakdown decisions, show your step-by-step reasoning:

<thinking>
Let me analyze this task structure:
1. What does plan.md specify? [Quote implementation steps]
2. How can I break this into atomic tasks? [List potential tasks]
3. What are the dependencies? [Identify blocking relationships]
4. What can run in parallel? [Group independent tasks]
5. Are tasks testable? [Verify each has clear acceptance criteria]
6. Conclusion: [Task breakdown with justification]
</thinking>

<answer>
[Task breakdown based on reasoning]
</answer>

**When to use structured thinking:**
- Breaking down large features into 20-30 atomic tasks
- Determining task dependencies (what blocks what)
- Deciding task granularity (too small vs too large)
- Writing testable acceptance criteria
- Grouping tasks for parallel execution

**Benefits**: Explicit reasoning reduces task rework by 30-40% and improves execution parallelism.
</constraints>

<instructions>
## PHASE 0: LOAD FEATURE

**Get feature from argument or current branch:**

```bash
if [ -n "$ARGUMENTS" ]; then
  SLUG="$ARGUMENTS"
else
  SLUG=$(git branch --show-current)
fi

FEATURE_DIR="specs/$SLUG"
PLAN_FILE="$FEATURE_DIR/plan.md"
SPEC_FILE="$FEATURE_DIR/spec.md"
DATA_MODEL="$FEATURE_DIR/data-model.md"
CONTRACTS_DIR="$FEATURE_DIR/contracts"
RESEARCH="$FEATURE_DIR/research.md"
```

**Validate feature exists:**

```bash
if [ ! -d "$FEATURE_DIR" ]; then
  echo "❌ Feature not found: $FEATURE_DIR"
  exit 1
fi
```

**Validate required files:**

```bash
if [ ! -f "$PLAN_FILE" ]; then
  echo "❌ Missing: $PLAN_FILE"
  echo "Run /plan first"
  exit 1
fi

if [ ! -f "$SPEC_FILE" ]; then
  echo "❌ Missing: $SPEC_FILE"
  echo "Run /specify first"
  exit 1
fi
```

## PHASE 1: PARSE & VERIFY INPUTS (fail-fast)

**Resolve absolute paths:**

```bash
PLAN_ABS=$(realpath "$PLAN_FILE")
SPEC_ABS=$(realpath "$SPEC_FILE")
```

**Normalize file existence by VCS truth:**

```bash
# Function to check if file exists in git repository
exists_in_repo() {
  git ls-files --error-unmatch "$1" >/dev/null 2>&1
  return $?
}

# Function to check if path is marked for creation
is_new_file() {
  [[ "$1" == *"[NEW]"* ]] && return 0
  return 1
}
```

**Extract and verify required sections from plan.md:**

```bash
# Required headings that must exist
required_sections=(
  "## \\[ARCHITECTURE DECISIONS\\]"
  "## \\[EXISTING INFRASTRUCTURE - REUSE\\]"
  "## \\[NEW INFRASTRUCTURE - CREATE\\]"
  "## \\[SCHEMA\\]"
  "## \\[CI\\/CD IMPACT\\]"
  "## \\[DEPLOYMENT ACCEPTANCE\\]"
)

MISSING_SECTIONS=()
for heading in "${required_sections[@]}"; do
  if ! grep -qE "$heading" "$PLAN_ABS"; then
    MISSING_SECTIONS+=("$heading")
  fi
done

if [ ${#MISSING_SECTIONS[@]} -gt 0 ]; then
  echo "❌ plan.md missing required headings:"
  printf '  - %s\n' "${MISSING_SECTIONS[@]}"
  exit 1
fi
```

**Extract user stories with priorities from spec.md:**

```bash
# Parse user stories: "As a user... [P1]"
# Format: line_number:content
mapfile -t USER_STORIES < <(grep -nE "^(As a|As an).*\\[P[1-9]\\]" "$SPEC_ABS" || true)

if [ ${#USER_STORIES[@]} -eq 0 ]; then
  echo "❌ No prioritized user stories found in spec.md"
  echo "User stories must follow format: 'As a [role], I want [goal] [P1]'"
  exit 1
fi

echo "✅ Found ${#USER_STORIES[@]} user stories"
```

**Ensure research unknowns resolved:**

```bash
if [ -f "$RESEARCH" ]; then
  UNRESOLVED=$(grep -c "⚠️" "$RESEARCH" 2>/dev/null || echo 0)
  if [ "$UNRESOLVED" -gt 0 ]; then
    echo "❌ Unresolved questions in research.md: $UNRESOLVED"
    echo "Run /clarify to resolve unknowns before generating tasks"
    exit 1
  fi
fi
```

**Extract acceptance criteria from spec.md:**

```bash
# Find all acceptance criteria blocks
# Format: - [ ] Given... When... Then...
mapfile -t AC_LINES < <(grep -nE "^- \\[ \\] (Given|When|Then)" "$SPEC_ABS" || true)

echo "✅ Found ${#AC_LINES[@]} acceptance criteria"
```

## PHASE 2: CODEBASE DISCOVERY (bounded, repo-truth)

**Discover test roots by language:**

```bash
# Python test patterns
PY_TEST_FILES=$(git ls-files | grep -E '^tests/.*\.py$|.*/tests/.*\.py$' | head -20 || true)
PY_TEST_ROOT=$(echo "$PY_TEST_FILES" | head -1 | sed 's|/[^/]*$||' || echo "")

# TypeScript/JavaScript test patterns
TS_TEST_FILES=$(git ls-files | grep -E '\.spec\.ts$|\.test\.ts$|\.spec\.tsx$' | head -20 || true)
TS_TEST_ROOT=$(echo "$TS_TEST_FILES" | head -1 | sed 's|/[^/]*$||' || echo "")

# E2E test patterns
E2E_TEST_FILES=$(git ls-files | grep -E 'e2e/.*\.spec\.' | head -10 || true)
E2E_TEST_ROOT=$(echo "$E2E_TEST_FILES" | head -1 | sed 's|/[^/]*$||' || echo "")
```

**Discover existing patterns to reuse:**

```bash
# Models
EXISTING_MODELS=$(git ls-files | grep -E '(models?|entities)/.*\.(py|ts|tsx)$' | head -20 || true)

# Services
EXISTING_SERVICES=$(git ls-files | grep -E 'services?/.*\.(py|ts|tsx)$' | head -20 || true)

# API endpoints
EXISTING_ENDPOINTS=$(git ls-files | grep -E '(routes?|api|endpoints?)/.*\.(py|ts|tsx)$' | head -20 || true)

# UI components
EXISTING_COMPONENTS=$(git ls-files | grep -E 'components?/.*\.(tsx|jsx)$' | head -20 || true)

# Middleware
EXISTING_MIDDLEWARE=$(git ls-files | grep -E 'middleware/.*\.(py|ts)$' | head -10 || true)
```

**Document reuse opportunities:**

```bash
echo "[CODEBASE REUSE ANALYSIS]"
echo "Repository root: $(git rev-parse --show-toplevel)"
echo ""
echo "[DISCOVERED PATTERNS]"
echo "Models: $(echo "$EXISTING_MODELS" | wc -l) files"
echo "Services: $(echo "$EXISTING_SERVICES" | wc -l) files"
echo "Endpoints: $(echo "$EXISTING_ENDPOINTS" | wc -l) files"
echo "Components: $(echo "$EXISTING_COMPONENTS" | wc -l) files"
echo ""
```

## PHASE 3: GENERATE CANONICAL TASKS.JSON

**Mental model**: Build tasks as structured data first, validate, then render to Markdown.

**Task ID stability strategy**:
1. Sort tasks by: phase (setup → foundational → story → polish), then priority, then appearance
2. Generate content hash: `sha1(description + files + from.section)`
3. Assign sequential IDs (T001, T002...) in sort order
4. Store hash in JSON for cross-run stability verification

**Build task list:**

For each user story:
1. **Extract from spec.md**:
   - Story text, priority (P1-P9)
   - Acceptance criteria (quoted verbatim)
   - Line numbers for traceability

2. **Extract from plan.md**:
   - Implementation steps (with line ranges)
   - Required infrastructure (REUSE vs CREATE)
   - Schemas, endpoints, components

3. **Generate tasks**:
   - Setup tasks (project structure, dependencies)
   - Foundational tasks (blocking infrastructure)
   - Story tasks (per user story, priority order)
   - Polish tasks (error handling, deployment prep)

4. **For each task, verify**:
   - File paths exist via `git ls-files` OR marked [NEW]
   - Sections exist in source documents
   - Acceptance criteria quoted if present
   - Dependencies reference valid task IDs

**Example task object structure:**

```json
{
  "id": "T012",
  "hash": "a3f5c89e",
  "story": "US1",
  "priority": 1,
  "description": "Create User model in api/src/models/user.py",
  "phase": "story",
  "phase_label": "Phase 3: User Story 1 [P1]",
  "files": ["api/src/models/user.py"],
  "from": {
    "doc": "data-model.md",
    "section": "User Entity",
    "start_line": 42,
    "end_line": 78
  },
  "reuse": [
    {
      "name": "BaseModel",
      "path": "api/src/models/base.py"
    }
  ],
  "pattern": ["api/src/models/notification.py"],
  "depends_on": ["T005"],
  "parallelizable": true,
  "acceptance_criteria": [
    {
      "text": "Given a valid email, When user submits registration, Then account is created in database",
      "from_spec": true,
      "spec_line": 85
    }
  ],
  "test_required": true
}
```

**Verification loop**:

```bash
# For each task candidate:
for task in "${TASK_CANDIDATES[@]}"; do
  # 1. Verify file paths
  for file in "${task.files[@]}"; do
    if ! is_new_file "$file" && ! exists_in_repo "$file"; then
      echo "❌ Task $task.id references non-existent file: $file"
      ERRORS+=("$task.id: missing file $file")
    fi
  done

  # 2. Verify source sections
  if ! grep -qF "$task.from.section" "$task.from.doc"; then
    echo "❌ Task $task.id references missing section: $task.from.section"
    ERRORS+=("$task.id: missing section $task.from.section in $task.from.doc")
  fi

  # 3. Verify reuse paths
  for reuse_path in "${task.reuse[@]}"; do
    if ! exists_in_repo "$reuse_path"; then
      echo "❌ Task $task.id REUSE path not found: $reuse_path"
      ERRORS+=("$task.id: REUSE path missing $reuse_path")
    fi
  done

  # 4. Verify pattern paths
  for pattern_path in "${task.pattern[@]}"; do
    if ! exists_in_repo "$pattern_path"; then
      echo "❌ Task $task.id pattern not found: $pattern_path"
      ERRORS+=("$task.id: pattern missing $pattern_path")
    fi
  done

  # 5. Verify AC quoted from spec
  if [ "$task.story" != "" ] && [ ${#task.acceptance_criteria[@]} -eq 0 ]; then
    echo "⚠️  Task $task.id (story task) has no acceptance criteria"
    WARNINGS+=("$task.id: missing acceptance criteria")
  fi
done

# Fail if any errors
if [ ${#ERRORS[@]} -gt 0 ]; then
  echo ""
  echo "❌ Task generation failed with ${#ERRORS[@]} errors:"
  printf '  - %s\n' "${ERRORS[@]}"
  exit 1
fi
```

## PHASE 4: BUILD DEPENDENCY GRAPH & VALIDATE DAG

**Extract dependencies:**

```bash
# Build adjacency list: task_id → [dependent_task_ids]
# Example: T001 → [T005, T006] means T005 and T006 depend on T001
```

**Detect cycles using DFS:**

```bash
# Pseudocode for cycle detection:
function detect_cycles(graph):
  visited = {}
  rec_stack = {}
  cycles = []

  for node in graph:
    if not visited[node]:
      if dfs(node, visited, rec_stack, [], cycles):
        # Cycle detected
        return false

  return cycles.length == 0

function dfs(node, visited, rec_stack, path, cycles):
  visited[node] = true
  rec_stack[node] = true
  path.append(node)

  for neighbor in graph[node]:
    if not visited[neighbor]:
      if dfs(neighbor, visited, rec_stack, path, cycles):
        return true
    elif rec_stack[neighbor]:
      # Cycle found
      cycle_start = path.index(neighbor)
      cycles.append(path[cycle_start:])
      return true

  rec_stack[node] = false
  path.pop()
  return false
```

**Fail if cycles detected:**

```bash
if [ ${#CYCLES[@]} -gt 0 ]; then
  echo "❌ Dependency graph contains cycles:"
  for cycle in "${CYCLES[@]}"; do
    echo "  - Cycle: $cycle"
  done
  exit 1
fi

echo "✅ Dependency graph is acyclic (DAG validated)"
```

**Identify parallel opportunities:**

```bash
# Tasks are parallelizable if:
# 1. They have parallelizable: true flag
# 2. They operate on different files
# 3. They have no dependency relationship (direct or transitive)

PARALLEL_GROUPS=()
for phase in setup foundational story polish; do
  parallel_tasks=$(jq -r ".tasks[] | select(.phase == \"$phase\" and .parallelizable == true) | .id" tasks.json)
  if [ -n "$parallel_tasks" ]; then
    PARALLEL_GROUPS+=("$phase: $parallel_tasks")
  fi
done
```

**Generate story completion order:**

```bash
# Topological sort of stories based on dependencies
# Output: [Phase 2: Foundational, Phase 3: US1, Phase 4: US2, ...]
```

## PHASE 5: WRITE TASKS.JSON

**Generate complete JSON structure:**

```json
{
  "version": "1.0",
  "feature": {
    "slug": "$SLUG",
    "name": "Feature Name from spec.md",
    "feature_dir": "specs/$SLUG"
  },
  "metadata": {
    "generated_at": "2025-11-10T14:30:00Z",
    "plan_file": "specs/$SLUG/plan.md",
    "spec_file": "specs/$SLUG/spec.md",
    "data_model_file": "specs/$SLUG/data-model.md",
    "contracts_dir": "specs/$SLUG/contracts"
  },
  "tasks": [...],
  "dependency_graph": {
    "is_acyclic": true,
    "cycles": [],
    "story_order": [...],
    "parallel_opportunities": [...]
  },
  "implementation_strategy": {
    "mvp_scope": "Phase 3 (US1) only",
    "incremental_delivery": ["US1 → staging", "US2 → staging", "US3 → production"],
    "testing_approach": "TDD required"
  },
  "statistics": {
    "total_tasks": 25,
    "setup_tasks": 2,
    "foundational_tasks": 5,
    "story_tasks": 15,
    "polish_tasks": 3,
    "parallel_tasks": 12,
    "test_tasks": 8,
    "reuse_count": 6
  }
}
```

**Write to file:**

```bash
TASKS_JSON="$FEATURE_DIR/tasks.json"
echo "$JSON_OUTPUT" > "$TASKS_JSON"
echo "✅ Generated: $TASKS_JSON"
```

## PHASE 6: VALIDATE AGAINST SCHEMA

**Use JSON schema validator:**

```bash
# Node.js (ajv-cli)
npx ajv validate \
  -s .spec-flow/templates/tasks.schema.json \
  -d "$TASKS_JSON"

# Python (jsonschema)
python3 -c "
import json
import jsonschema

with open('.spec-flow/templates/tasks.schema.json') as f:
  schema = json.load(f)

with open('$TASKS_JSON') as f:
  data = json.load(f)

try:
  jsonschema.validate(data, schema)
  print('✅ tasks.json validates against schema')
except jsonschema.ValidationError as e:
  print(f'❌ Schema validation failed: {e.message}')
  exit(1)
"
```

**Fail if validation fails:**

```bash
if [ $? -ne 0 ]; then
  echo "❌ tasks.json does not conform to schema"
  exit 1
fi
```

## PHASE 7: RENDER TASKS.MD FROM TASKS.JSON

**Read canonical JSON:**

```bash
TASKS_DATA=$(cat "$TASKS_JSON")
```

**Generate Markdown header:**

```markdown
# Tasks: ${FEATURE_NAME}

> **Source of truth**: `tasks.json` (canonical)
> **This file**: Generated from tasks.json on ${TIMESTAMP}
> **Do not edit manually** — changes will be overwritten

## [CODEBASE REUSE ANALYSIS]
Scanned: ${REPO_ROOT}

[EXISTING - REUSE]
${REUSE_LIST}

[NEW - CREATE]
${CREATE_LIST}

## [DEPENDENCY GRAPH]
Story completion order:
${STORY_ORDER}

## [PARALLEL EXECUTION OPPORTUNITIES]
${PARALLEL_GROUPS}

## [IMPLEMENTATION STRATEGY]
**MVP Scope**: ${MVP_SCOPE}
**Incremental delivery**: ${DELIVERY_SEQUENCE}
**Testing approach**: ${TESTING_APPROACH}
```

**Render tasks by phase:**

```markdown
## Phase 1: Setup

- [ ] T001 Create project structure per plan.md tech stack
  - Files: src/, tests/, config/
  - Pattern: existing-feature/ structure
  - From: plan.md L45-L67 [PROJECT STRUCTURE]

- [ ] T002 [P] Install dependencies from plan.md
  - Files: package.json, requirements.txt
  - Libraries: [list from plan.md]
  - From: plan.md L102-L125 [ARCHITECTURE DECISIONS]

## Phase 2: Foundational (blocking prerequisites)

**Goal**: Infrastructure that blocks all user stories

- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py
  - REUSE: JWTService (src/services/jwt_service.py)
  - Pattern: src/middleware/rate_limit.py
  - From: plan.md L200-L215 [EXISTING INFRASTRUCTURE - REUSE]

## Phase 3: User Story 1 [P1] - User can register account

**Story Goal**: New users create accounts with email/password

**Independent Test Criteria**:
- [ ] Given a valid email, When user submits registration, Then account created in DB
- [ ] Given duplicate email, When user registers, Then 400 error with message
- [ ] Given registration confirmed, When email link clicked, Then account activated

### Implementation

- [ ] T012 [P] [US1] Create User model in api/src/models/user.py
  - Fields: id, email, password_hash, created_at
  - Methods: validate_email(), set_password()
  - REUSE: BaseModel (api/src/models/base.py)
  - Pattern: api/src/models/notification.py
  - From: data-model.md L42-L78 [User Entity]
  - AC:
    - "Given a valid email, When user submits registration, Then account is created in database" (spec.md L85)
```

**Write rendered Markdown:**

```bash
TASKS_MD="$FEATURE_DIR/tasks.md"
echo "$MARKDOWN_OUTPUT" > "$TASKS_MD"
echo "✅ Rendered: $TASKS_MD"
```

## PHASE 8: DIFF CHECK

**Compare with previous version:**

```bash
if [ -f "$TASKS_JSON.old" ]; then
  if diff -q "$TASKS_JSON" "$TASKS_JSON.old" >/dev/null; then
    echo "ℹ️  No changes to tasks.json"
    exit 0
  else
    echo "📝 Tasks updated"
    diff "$TASKS_JSON.old" "$TASKS_JSON" | head -20
  fi
fi

# Backup current version
cp "$TASKS_JSON" "$TASKS_JSON.old"
```

## PHASE 9: UPDATE NOTES.MD

**Count tasks:**

```bash
TOTAL_TASKS=$(jq '.statistics.total_tasks' "$TASKS_JSON")
SETUP_TASKS=$(jq '.statistics.setup_tasks' "$TASKS_JSON")
STORY_TASKS=$(jq '.statistics.story_tasks' "$TASKS_JSON")
PARALLEL_TASKS=$(jq '.statistics.parallel_tasks' "$TASKS_JSON")
REUSE_COUNT=$(jq '.statistics.reuse_count' "$TASKS_JSON")
```

**Add Phase 2 checkpoint:**

```bash
cat >> "$FEATURE_DIR/NOTES.md" <<EOF

## Phase 2: Tasks ($(date '+%Y-%m-%d %H:%M'))

**Summary**:
- Total tasks: $TOTAL_TASKS
- User story tasks: $STORY_TASKS
- Parallel opportunities: $PARALLEL_TASKS
- Setup tasks: $SETUP_TASKS
- Reuse count: $REUSE_COUNT
- Task files: tasks.json (canonical), tasks.md (rendered)

**Verification**:
- ✅ All file paths verified via git ls-files
- ✅ All sections traced to plan/spec with line numbers
- ✅ Dependency graph validated (acyclic DAG)
- ✅ JSON schema validation passed
- ✅ Acceptance criteria quoted from spec.md

**Checkpoint**:
- ✅ Tasks generated: $TOTAL_TASKS
- ✅ User story organization: Complete
- ✅ Dependency graph: Created (no cycles)
- ✅ MVP strategy: Defined
- 📋 Ready for: /validate

EOF
```

## PHASE 10: GIT COMMIT

**Commit with Conventional Commits:**

```bash
git add "$TASKS_JSON" "$TASKS_MD" "$FEATURE_DIR/NOTES.md"

git commit -m "$(cat <<EOF
design:tasks: generate $TOTAL_TASKS concrete tasks for $SLUG

- $TOTAL_TASKS tasks (setup, foundational, story, polish)
- $REUSE_COUNT REUSE markers for existing modules
- Dependency graph validated (acyclic DAG)
- MVP strategy: ${MVP_SCOPE}
- All paths verified via git ls-files
- All sections traced with line numbers

Artifacts:
- tasks.json (canonical source of truth)
- tasks.md (rendered from JSON)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"

# Verify commit succeeded
COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""
echo "✅ Tasks committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""
```

## PHASE 11: RETURN SUMMARY

```
✅ Tasks generated: specs/$SLUG/tasks.json + tasks.md

📊 Summary:
- Total: $TOTAL_TASKS tasks
- User story tasks: $STORY_TASKS (organized by priority P1, P2, P3...)
- Parallel opportunities: $PARALLEL_TASKS tasks marked [P]
- REUSE: $REUSE_COUNT existing modules identified
- MVP scope: ${MVP_SCOPE}

📋 Task breakdown:
- Phase 1 (Setup): $SETUP_TASKS tasks
- Phase 2 (Foundational): $FOUNDATIONAL_TASKS tasks
- Phase 3+ (User Stories): $STORY_TASKS tasks
- Phase N (Polish): $POLISH_TASKS tasks

🔍 Verification:
- ✅ All file paths verified (git ls-files or [NEW])
- ✅ All sections traced to source docs (line numbers)
- ✅ Dependency graph validated (acyclic DAG)
- ✅ JSON schema validation passed
- ✅ Acceptance criteria quoted from spec.md

📁 Artifacts:
- tasks.json: Canonical source of truth (machine-readable)
- tasks.md: Human-readable rendering
- NOTES.md: Phase 2 checkpoint added

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 NEXT: /validate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/validate will:
1. Read tasks.json (task breakdown)
2. Scan codebase for patterns (anti-duplication check)
3. Validate architecture decisions (no conflicts)
4. Identify risks (complexity, dependencies)
5. Generate implementation hints (concrete examples)
6. Update error-log.md (potential issues)

Output: specs/$SLUG/artifacts/analysis-report.md

Duration: ~5 minutes
```
</instructions>

## MENTAL MODEL

**Workflow**: spec → clarify → plan → tasks → validate → implement → optimize → debug → preview → ship

**State machine**: Load design artifacts → Verify all paths → Extract user stories → Map to tasks → Generate JSON (canonical) → Validate schema → Render MD → Commit with provenance

**Philosophy**:
- **JSON first**: tasks.json is the source of truth, tasks.md is a view
- **Fail fast**: Stop on first verification failure with precise error
- **Traceable**: Every task links to exact source lines in plan/spec
- **Deterministic**: Same inputs always produce same outputs
- **Verifiable**: All paths checked via git, all sections checked via grep

**Auto-suggest**: When complete → `/validate`
