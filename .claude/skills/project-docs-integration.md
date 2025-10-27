---
name: project-docs-integration
description: "Ensure all workflow commands (/roadmap, /spec, /plan, /implement, etc.) read relevant project documentation before execution. Auto-trigger BEFORE any feature work to load architecture context (tech stack, API patterns, data model, deployment strategy). Prevents hallucination by enforcing 'docs/project/' as single source of truth for tech decisions. Cites sources in all generated artifacts."
allowed-tools: Read, Grep, Glob
---

# Project Docs Integration: Architecture Context Enforcer

**Purpose**: Load and validate project documentation before ANY feature work to prevent hallucination and ensure architectural consistency.

**Philosophy**: "The project docs are the single source of truth. Read them before making any technical decision."

---

## When to Trigger

**Auto-invoke BEFORE these commands**:
- `/roadmap add` → Read `overview.md` for vision alignment
- `/spec` → Read `tech-stack.md`, `api-strategy.md`, `data-architecture.md`, `system-architecture.md`
- `/plan` → Read ALL 8 docs from `docs/project/`
- `/implement` → Read `tech-stack.md`, `data-architecture.md` for validation
- `/design-variations` → Read `tech-stack.md` (frontend framework), `overview.md` (target users)
- Any task execution → Verify tech matches `tech-stack.md`

**Trigger Keywords**:
- "create", "implement", "add", "build" (any feature work)
- "/roadmap", "/spec", "/plan", "/tasks", "/implement"
- "suggest tech", "choose framework", "design API", "create entity"

---

## Pre-Execution Checklist

### Step 1: Check if Project Docs Exist

```bash
PROJECT_DOCS_DIR="docs/project"
HAS_PROJECT_DOCS=false

if [ -d "$PROJECT_DOCS_DIR" ]; then
  # Verify all 8 core docs exist
  REQUIRED_DOCS=(
    "overview.md"
    "system-architecture.md"
    "tech-stack.md"
    "data-architecture.md"
    "api-strategy.md"
    "capacity-planning.md"
    "deployment-strategy.md"
    "development-workflow.md"
  )

  MISSING_DOCS=()
  for doc in "${REQUIRED_DOCS[@]}"; do
    if [ ! -f "$PROJECT_DOCS_DIR/$doc" ]; then
      MISSING_DOCS+=("$doc")
    fi
  done

  if [ ${#MISSING_DOCS[@]} -eq 0 ]; then
    HAS_PROJECT_DOCS=true
    echo "✅ Project documentation found (8/8 docs)"
  else
    echo "⚠️  Project documentation incomplete (${#MISSING_DOCS[@]} missing)"
    echo "   Missing: ${MISSING_DOCS[*]}"
    echo "   Recommend: /init-project to generate missing docs"
  fi
else
  echo "ℹ️  No project documentation found"
  echo "   Run /init-project to create architecture docs (recommended)"
  echo "   Or: Proceed without project context (higher hallucination risk)"
fi
```

**Quality Gate**:
- If project docs don't exist → WARN user (don't block, but strongly recommend /init-project)
- If project docs incomplete → WARN about missing docs
- If project docs exist → PROCEED and load context

---

### Step 2: Map Phase to Relevant Docs

**Phase-to-Docs Mapping**:

| Phase/Command | Docs to Read | Priority |
|---------------|-------------|----------|
| `/roadmap add` | overview.md | Required |
| `/spec` | tech-stack.md, api-strategy.md, data-architecture.md, system-architecture.md | Required |
| `/plan` | ALL 8 docs | Required |
| `/tasks` | development-workflow.md (testing strategy) | Recommended |
| `/implement` | tech-stack.md, data-architecture.md | Required |
| `/optimize` | capacity-planning.md (performance targets) | Recommended |
| `/deploy` | deployment-strategy.md | Required |

**Read Strategy** (token optimization):
```bash
# Only read necessary docs for current phase
case "$CURRENT_PHASE" in
  roadmap)
    DOCS_TO_READ=("overview.md")
    ;;
  spec)
    DOCS_TO_READ=("tech-stack.md" "api-strategy.md" "data-architecture.md" "system-architecture.md")
    ;;
  plan)
    DOCS_TO_READ=("${REQUIRED_DOCS[@]}") # All 8 docs
    ;;
  implement)
    DOCS_TO_READ=("tech-stack.md" "data-architecture.md")
    ;;
  optimize)
    DOCS_TO_READ=("capacity-planning.md" "development-workflow.md")
    ;;
  deploy)
    DOCS_TO_READ=("deployment-strategy.md")
    ;;
esac
```

---

### Step 3: Extract Constraints from Docs

**For each doc read, extract key constraints**:

#### tech-stack.md → Technology Constraints
```bash
# Extract tech stack
FRONTEND_FRAMEWORK=$(grep -A 1 '| Frontend' docs/project/tech-stack.md | tail -1 | awk '{print $3}')
BACKEND_FRAMEWORK=$(grep -A 1 '| Backend' docs/project/tech-stack.md | tail -1 | awk '{print $3}')
DATABASE=$(grep -A 1 '| Database' docs/project/tech-stack.md | tail -1 | awk '{print $3}')
DEPLOYMENT_PLATFORM=$(grep -A 1 '| Deployment' docs/project/tech-stack.md | tail -1 | awk '{print $3}')

# Store for validation
declare -A TECH_CONSTRAINTS
TECH_CONSTRAINTS[frontend]="$FRONTEND_FRAMEWORK"
TECH_CONSTRAINTS[backend]="$BACKEND_FRAMEWORK"
TECH_CONSTRAINTS[database]="$DATABASE"
TECH_CONSTRAINTS[deployment]="$DEPLOYMENT_PLATFORM"
```

**Example extracted constraints**:
```
TECH_CONSTRAINTS[frontend] = "Next.js"
TECH_CONSTRAINTS[backend] = "FastAPI"
TECH_CONSTRAINTS[database] = "PostgreSQL"
TECH_CONSTRAINTS[deployment] = "Vercel (FE) + Railway (BE)"
```

---

#### api-strategy.md → API Constraints
```bash
# Extract API patterns
API_STYLE=$(grep -A 1 '## API Style' docs/project/api-strategy.md | tail -1 | grep -oP '(REST|GraphQL|tRPC|gRPC)')
AUTH_PROVIDER=$(grep -A 1 '## Authentication' docs/project/api-strategy.md | tail -1 | grep -oP '(Clerk|Auth0|Supabase|Firebase|JWT)')
VERSIONING_SCHEME=$(grep -A 1 '## Versioning' docs/project/api-strategy.md | tail -1 | grep -oP '/api/v[0-9]+/')
ERROR_FORMAT=$(grep -A 1 '## Error Format' docs/project/api-strategy.md | tail -1 | grep -oP '(RFC 7807|Custom)')

# Store constraints
declare -A API_CONSTRAINTS
API_CONSTRAINTS[style]="$API_STYLE"
API_CONSTRAINTS[auth]="$AUTH_PROVIDER"
API_CONSTRAINTS[versioning]="$VERSIONING_SCHEME"
API_CONSTRAINTS[error_format]="$ERROR_FORMAT"
```

---

#### data-architecture.md → Data Model Constraints
```bash
# Extract existing entities from ERD
ENTITIES=()
# Parse Mermaid ERD (look for entity declarations)
while IFS= read -r line; do
  if [[ "$line" =~ ([A-Z_]+)[[:space:]]*\{ ]]; then
    ENTITY="${BASH_REMATCH[1]}"
    ENTITIES+=("$ENTITY")
  fi
done < <(sed -n '/```mermaid/,/```/p' docs/project/data-architecture.md)

# Store constraints
declare -A DATA_CONSTRAINTS
DATA_CONSTRAINTS[entities]="${ENTITIES[*]}"

# Extract relationships (simplified)
RELATIONSHIPS=$(grep -oP '\|\|--o\{|\}o--\|\|' docs/project/data-architecture.md | wc -l)
DATA_CONSTRAINTS[relationship_count]="$RELATIONSHIPS"
```

**Example extracted entities**:
```
DATA_CONSTRAINTS[entities] = "USER STUDENT LESSON PROGRESS"
```

---

#### overview.md → Vision & Scope Constraints
```bash
# Extract vision
VISION=$(sed -n '/## Vision Statement/,/^$/p' docs/project/overview.md | tail -n +2 | head -n -1)

# Extract out-of-scope items
OUT_OF_SCOPE=()
while IFS= read -r line; do
  if [[ "$line" =~ ❌[[:space:]]+(.*) ]]; then
    OUT_OF_SCOPE+=("${BASH_REMATCH[1]}")
  fi
done < <(sed -n '/## Out of Scope/,/^##/p' docs/project/overview.md)

# Store constraints
declare -A VISION_CONSTRAINTS
VISION_CONSTRAINTS[vision]="$VISION"
VISION_CONSTRAINTS[out_of_scope]="${OUT_OF_SCOPE[*]}"
```

---

### Step 4: Inject Context into Current Phase

**Generate context block for phase command**:

```bash
# For /spec command
cat >> specs/NNN-slug/NOTES.md <<EOF

## Project Documentation Context

**Source**: \`docs/project/\` (read on $(date -I))

### Tech Stack (from tech-stack.md)
- **Frontend**: ${TECH_CONSTRAINTS[frontend]}
- **Backend**: ${TECH_CONSTRAINTS[backend]}
- **Database**: ${TECH_CONSTRAINTS[database]}
- **Deployment**: ${TECH_CONSTRAINTS[deployment]}

### API Strategy (from api-strategy.md)
- **API Style**: ${API_CONSTRAINTS[style]}
- **Auth**: ${API_CONSTRAINTS[auth]}
- **Versioning**: ${API_CONSTRAINTS[versioning]}
- **Error Format**: ${API_CONSTRAINTS[error_format]}

### Data Architecture (from data-architecture.md)
- **Existing Entities**: ${DATA_CONSTRAINTS[entities]}
- **Relationships**: ${DATA_CONSTRAINTS[relationship_count]} defined

### System Architecture (from system-architecture.md)
- **Components**: [List relevant components from C4 diagram]
- **Integration Points**: [Services this feature integrates with]

**Constraints**:
- ✅ **MUST** use ${TECH_CONSTRAINTS[frontend]} for frontend (per tech-stack.md)
- ✅ **MUST** use ${TECH_CONSTRAINTS[backend]} for backend (per tech-stack.md)
- ✅ **MUST** use ${TECH_CONSTRAINTS[database]} for database (per tech-stack.md)
- ✅ **MUST** follow ${API_CONSTRAINTS[style]} patterns (per api-strategy.md)
- ✅ **MUST** use ${API_CONSTRAINTS[auth]} for authentication (per api-strategy.md)
- ❌ **MUST NOT** create duplicate entities (check data-architecture.md first)
- ❌ **MUST NOT** suggest different tech stack (violates tech-stack.md)

EOF
```

---

### Step 5: Cite Sources in Generated Artifacts

**Enforcement**: ALL technical decisions MUST cite project docs

**Examples**:

**Good (cites source)**:
```markdown
## Tech Stack

- **Frontend**: Next.js 14.x (per tech-stack.md:12)
- **Backend**: FastAPI 0.110.x (per tech-stack.md:13)
- **Database**: PostgreSQL 15.x (per tech-stack.md:14)
- **Auth**: Clerk (per api-strategy.md:23)

**Rationale**: Using established tech stack documented in project architecture.
```

**Bad (no source)**:
```markdown
## Tech Stack

- **Frontend**: React (we'll use React)
- **Backend**: Node.js with Express (I think Express would work)
- **Database**: MongoDB (flexible schema is better)

**Rationale**: These are popular choices.
```

**Commit Message Citations**:
```bash
# Good
git commit -m "feat: add student progress endpoint

- Uses FastAPI (per tech-stack.md)
- REST pattern with /api/v1/ prefix (per api-strategy.md)
- Reuses Student entity from data-architecture.md
- Clerk auth validation (per api-strategy.md)"

# Bad
git commit -m "feat: add student progress endpoint

- Uses Express backend
- Created new User model"
```

---

## Validation Rules (Quality Gates)

### Block Execution If:

**1. Tech Stack Violation**:
```bash
# If suggesting tech not in tech-stack.md
SUGGESTED_TECH="Django"
DOCUMENTED_TECH="${TECH_CONSTRAINTS[backend]}"

if [ "$SUGGESTED_TECH" != "$DOCUMENTED_TECH" ]; then
  echo "❌ ERROR: Tech stack violation"
  echo "   Suggested: $SUGGESTED_TECH"
  echo "   Documented: $DOCUMENTED_TECH (tech-stack.md:13)"
  echo ""
  echo "   Options:"
  echo "   A) Use documented tech: $DOCUMENTED_TECH"
  echo "   B) Update tech-stack.md if migration needed"
  exit 1
fi
```

---

**2. Duplicate Entity Creation**:
```bash
# If creating entity that exists in data-architecture.md
NEW_ENTITY="User"
EXISTING_ENTITIES="${DATA_CONSTRAINTS[entities]}"

if echo "$EXISTING_ENTITIES" | grep -qi "$NEW_ENTITY"; then
  echo "❌ ERROR: Duplicate entity"
  echo "   New entity: $NEW_ENTITY"
  echo "   Existing: $EXISTING_ENTITIES (data-architecture.md)"
  echo ""
  echo "   Options:"
  echo "   A) Reuse existing $NEW_ENTITY entity"
  echo "   B) Extend existing $NEW_ENTITY with new fields"
  echo "   C) Create different entity name (e.g., UserProfile)"
  exit 1
fi
```

---

**3. API Pattern Violation**:
```bash
# If violating established API patterns
PROPOSED_ENDPOINT="/users"
VERSIONING_SCHEME="${API_CONSTRAINTS[versioning]}"

if [[ ! "$PROPOSED_ENDPOINT" =~ $VERSIONING_SCHEME ]]; then
  echo "❌ ERROR: API versioning violation"
  echo "   Proposed: $PROPOSED_ENDPOINT"
  echo "   Required prefix: $VERSIONING_SCHEME (api-strategy.md:15)"
  echo ""
  echo "   Fix: $VERSIONING_SCHEME$PROPOSED_ENDPOINT"
  exit 1
fi
```

---

### Warn (Don't Block) If:

**1. Out-of-Scope Feature**:
```bash
# If feature appears out of scope per overview.md
FEATURE_NAME="Flight planning tool"
OUT_OF_SCOPE="${VISION_CONSTRAINTS[out_of_scope]}"

if echo "$OUT_OF_SCOPE" | grep -qi "flight planning"; then
  echo "⚠️  WARNING: Potential scope violation"
  echo "   Feature: $FEATURE_NAME"
  echo "   Marked out-of-scope in overview.md"
  echo ""
  echo "   Out of scope items:"
  echo "$OUT_OF_SCOPE"
  echo ""
  read -p "Proceed anyway? (y/N): " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted. Review overview.md scope boundaries."
    exit 0
  fi
fi
```

---

**2. Missing Project Docs**:
```bash
# If project docs don't exist
if [ "$HAS_PROJECT_DOCS" = false ]; then
  echo "⚠️  WARNING: No project documentation found"
  echo "   Proceeding without architecture context"
  echo "   Risk: Higher chance of hallucination (wrong tech, duplicate entities)"
  echo ""
  echo "   Strongly recommend: /init-project to generate docs"
  echo ""
  read -p "Proceed without project docs? (y/N): " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted. Run /init-project first."
    exit 0
  fi
fi
```

---

## Integration with Existing Commands

### /roadmap Command Integration

**Add to .claude/commands/roadmap.md**:
```bash
# Before adding feature to roadmap
# 1. Check if project docs exist
source .claude/skills/project-docs-integration.md

# 2. If docs exist, validate against vision
if [ "$HAS_PROJECT_DOCS" = true ]; then
  # Read overview.md
  # Check vision alignment
  # Warn if out of scope
fi
```

---

### /spec Command Integration

**Add to .claude/commands/spec.md**:
```bash
# Before generating spec
# 1. Load project docs context
source .claude/skills/project-docs-integration.md

# 2. Extract constraints (tech stack, API, data)
# 3. Inject into NOTES.md
# 4. Use constraints when generating spec
```

---

### /plan Command Integration

**Add to .claude/commands/plan.md**:
```bash
# Phase 0: Research & Discovery
# 1. Load ALL 8 project docs
source .claude/skills/project-docs-integration.md

# 2. Generate research.md with project context section
# 3. Reference constraints throughout plan.md
```

---

### /implement Command Integration

**Add to .claude/commands/implement.md**:
```bash
# Before implementing each task
# 1. Validate tech against tech-stack.md
# 2. Check entities against data-architecture.md
# 3. Cite sources in commits
```

---

## Performance Optimization

**Token Budget**:
- Reading 1 doc (overview.md): ~2-3K tokens
- Reading 4 docs (spec phase): ~8-12K tokens
- Reading ALL 8 docs (plan phase): ~20-25K tokens
- Extracting constraints: ~1K tokens
- **Total overhead**: 5-25K tokens depending on phase

**Caching Strategy**:
```bash
# Cache extracted constraints (reuse across multiple tasks)
CONSTRAINTS_CACHE="/tmp/project-constraints-cache.json"

if [ -f "$CONSTRAINTS_CACHE" ]; then
  # Check if cache is fresh (docs not modified)
  DOCS_MODIFIED=$(find docs/project -name "*.md" -newer "$CONSTRAINTS_CACHE" | wc -l)

  if [ "$DOCS_MODIFIED" -eq 0 ]; then
    echo "✅ Using cached project constraints"
    source "$CONSTRAINTS_CACHE"
  else
    echo "⚠️  Project docs modified, re-reading..."
    # Re-extract constraints
  fi
else
  # First run, extract and cache
  # Extract constraints...
  # Save to cache
fi
```

---

## Error Handling

**Missing Docs**:
```bash
# If expected doc doesn't exist
if [ ! -f "docs/project/tech-stack.md" ]; then
  echo "⚠️  Warning: tech-stack.md not found"
  echo "   Proceeding without tech stack constraints"
  echo "   Higher risk of suggesting wrong technologies"
  # Don't fail, just warn
fi
```

**Malformed Docs**:
```bash
# If doc exists but can't be parsed
if ! grep -q '## Tech Stack' docs/project/tech-stack.md; then
  echo "⚠️  Warning: tech-stack.md missing expected structure"
  echo "   Expected: '## Tech Stack' section"
  echo "   Proceeding with limited constraint extraction"
fi
```

**Conflicting Constraints**:
```bash
# If different docs have conflicting info
if [ "$TECH_STACK_DB" != "$DATA_ARCH_DB" ]; then
  echo "⚠️  Warning: Constraint conflict detected"
  echo "   tech-stack.md says: $TECH_STACK_DB"
  echo "   data-architecture.md says: $DATA_ARCH_DB"
  echo ""
  echo "   Options:"
  echo "   A) Use tech-stack.md as authoritative"
  echo "   B) Manually review and fix inconsistency"
fi
```

---

## Quality Checklist

Before allowing feature work to proceed:

- [ ] Project docs checked (exist or user warned)
- [ ] Relevant docs read for current phase
- [ ] Constraints extracted (tech, API, data, vision)
- [ ] Context injected into phase artifacts (NOTES.md, research.md)
- [ ] Validation rules applied (block on tech/entity violations)
- [ ] Sources will be cited in generated artifacts

---

## References

- **Project Design Guide**: `docs/project-design-guide.md`
- **Project Templates**: `.spec-flow/templates/project/`
- **/init-project Command**: `.claude/commands/init-project.md`
- **Project-Architect Agent**: `.claude/agents/phase/project-architect.md`
