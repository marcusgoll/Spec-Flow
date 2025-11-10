---
description: Generate design artifacts from feature spec (research + design + context plan)
scripts:
  sh: scripts/bash/setup-plan.sh --json "{ARGS}"
  ps: scripts/powershell/setup-plan.ps1 -Json "{ARGS}"
---

Design implementation for: $ARGUMENTS

<context>
## MENTAL MODEL

**Workflow**: spec-flow → clarify → plan → tasks → analyze → implement → optimize → debug → preview → phase-1-ship → validate-staging → phase-2-ship

**Phases:**
- Phase 0: Research & Discovery → research.md (single source of truth)
- Phase 1: Design & Contracts → data-model.md, contracts/, budgets.json, quickstart.md, plan.md

**State machine:**
- Setup → Tool checks → Constitution check → Phase 0 (Research) → Phase 1 (Design) → Validate → Commit → Suggest next

**Auto-suggest:**
- UI features → `/tasks` (design phase optional)
- Backend features → `/tasks`

**Operating Constraints:**
- **Headless**: No interactive prompts (use --yes flag or PLAN_ASSUME_YES=1)
- **Atomic**: All writes via mktemp → validate → mv
- **Deterministic**: Outputs hash-verifiable and idempotent
- **Contract-First**: OpenAPI 3.1.0 + JSON Schema 2020-12 + RFC 9457 Problem Details
- **Budget-Enforced**: Lighthouse budgets.json enforced via CI gates
- **Security-Gated**: ASVS controls mapped, Conventional Commits enforced
</context>

## USER INPUT

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## SETUP

**Run setup script from repo root:**

```bash
# Execute script and parse JSON output
OUTPUT=$({SCRIPT})

# Parse JSON to get paths (all must be absolute)
FEATURE_SPEC=$(echo "$OUTPUT" | jq -r '.feature_spec')
IMPL_PLAN=$(echo "$OUTPUT" | jq -r '.impl_plan')
SPECS_DIR=$(echo "$OUTPUT" | jq -r '.specs_dir')
BRANCH=$(echo "$OUTPUT" | jq -r '.branch')
FEATURE_DIR=$(dirname "$FEATURE_SPEC")
SLUG=$(basename "$FEATURE_DIR")

# Validate paths exist
[ ! -f "$FEATURE_SPEC" ] && echo "Error: Spec not found at $FEATURE_SPEC" && exit 1
[ ! -d "$FEATURE_DIR" ] && echo "Error: Feature dir not found at $FEATURE_DIR" && exit 1

echo "Feature: $SLUG"
echo "Spec: $FEATURE_SPEC"
echo "Branch: $BRANCH"
echo ""

# Get commit SHA for artifact stamping
COMMIT_SHA=$(git rev-parse --short HEAD)
echo "Commit: $COMMIT_SHA"
echo ""
```

## TOOL DEPENDENCY CHECKS (hard fail if missing)

**Ensure required tools are available:**

```bash
check_tool() {
  local tool="$1"
  local install_hint="$2"

  if ! command -v "$tool" &>/dev/null; then
    echo "❌ Missing required tool: $tool"
    echo "Install: $install_hint"
    exit 1
  fi
}

echo "🔧 Checking tool dependencies..."
echo ""

check_tool "jq" "brew install jq (macOS) | apt install jq (Linux) | choco install jq (Windows)"
check_tool "yq" "brew install yq (macOS) | apt install yq (Linux) | choco install yq (Windows)"
check_tool "git" "Install from https://git-scm.com"

# Check for Redocly CLI (OpenAPI validation)
if ! command -v "redocly" &>/dev/null && ! npx --yes @redocly/cli --version &>/dev/null 2>&1; then
  echo "⚠️  Warning: Redocly CLI not found (OpenAPI contract validation will be skipped)"
  echo "Install: npm install -g @redocly/cli"
  echo ""
fi

# Check for Lighthouse CI (budgets validation)
if ! command -v "lhci" &>/dev/null && ! npx --yes @lhci/cli --version &>/dev/null 2>&1; then
  echo "⚠️  Warning: Lighthouse CI not found (budget validation will be skipped)"
  echo "Install: npm install -g @lhci/cli"
  echo ""
fi

echo "✅ Core tools available"
echo ""
```

## ENVIRONMENT FLAGS

**Parse flags for headless operation:**

```bash
# Check for headless mode flags
ASSUME_YES="${PLAN_ASSUME_YES:-0}"
ALLOW_AMBIGUOUS="${PLAN_ALLOW_AMBIGUOUS:-0}"
STRICT_MODE="${PLAN_STRICT:-1}"

# Parse command-line flags
for arg in "$@"; do
  case "$arg" in
    --yes|-y)
      ASSUME_YES=1
      ;;
    --allow-ambiguous)
      ALLOW_AMBIGUOUS=1
      ;;
    --no-strict)
      STRICT_MODE=0
      ;;
  esac
done

echo "Mode: $([ "$ASSUME_YES" = "1" ] && echo "Headless" || echo "Interactive")"
echo "Strict: $([ "$STRICT_MODE" = "1" ] && echo "Enabled" || echo "Disabled")"
echo ""
```

## LOAD CONTEXT

**Load spec and constitution:**

```bash
# Constitution file for alignment check
CONSTITUTION_FILE=".spec-flow/memory/constitution.md"

# Validate spec is clarified (non-blocking warning)
REMAINING_CLARIFICATIONS=$(grep -c "\[NEEDS CLARIFICATION\]" "$FEATURE_SPEC" || echo 0)
if [ "$REMAINING_CLARIFICATIONS" -gt 0 ]; then
  echo "⚠️  Warning: $REMAINING_CLARIFICATIONS ambiguities remain in spec"
  echo ""

  if [ "$STRICT_MODE" = "1" ] && [ "$ASSUME_YES" != "1" ]; then
    echo "STRICT MODE: Cannot proceed with ambiguities"
    echo "Options:"
    echo "  1. Run: /clarify (recommended)"
    echo "  2. Use: --allow-ambiguous flag"
    exit 1
  elif [ "$ALLOW_AMBIGUOUS" = "1" ]; then
    echo "Continuing with ambiguities (--allow-ambiguous flag set)"
    echo ""
  fi
fi

# Read spec and constitution for planning
echo "Loading feature spec and constitution..."
echo ""
```

## CONSTITUTION CHECK (Quality Gate)

**Verify feature aligns with mission and values:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📜 CONSTITUTION CHECK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Read constitution if exists
if [ -f "$CONSTITUTION_FILE" ]; then
  echo "Checking feature against constitution.md..."

  # Claude Code: Read constitution and spec, verify alignment
  # Check for violations of:
  # - Mission alignment
  # - Value constraints
  # - Technical principles
  # - Quality standards

  # Track violations
  CONSTITUTION_VIOLATIONS=()

  # Example checks (Claude Code implements actual logic):
  # - Does feature support core mission?
  # - Does it violate privacy principles?
  # - Does it compromise security standards?
  # - Does it create technical debt against principles?

  # If violations found:
  if [ ${#CONSTITUTION_VIOLATIONS[@]} -gt 0 ]; then
    echo "⚠️  Constitution violations detected:"
    for violation in "${CONSTITUTION_VIOLATIONS[@]}"; do
      echo "  - $violation"
    done
    echo ""
    echo "Violations must be justified or feature redesigned."
    echo "ERROR: Cannot proceed with unjustified violations."
    exit 1
  else
    echo "✅ Feature aligns with constitution"
  fi
else
  echo "⚠️  No constitution.md found - skipping alignment check"
fi

echo ""
```

## TEMPLATE VALIDATION

**Verify required templates exist:**

```bash
REQUIRED_TEMPLATES=(
  ".spec-flow/templates/error-log-template.md"
  ".spec-flow/templates/lighthouse-budget-template.json"
)

for template in "${REQUIRED_TEMPLATES[@]}"; do
  if [ ! -f "$template" ]; then
    echo "Error: Missing required template: $template"
    echo "Run: git checkout main -- .spec-flow/templates/"
    exit 1
  fi
done
```

## DETECT FEATURE TYPE

**Check if UI design needed (using yq):**

```bash
HAS_SCREENS=false
SCREEN_COUNT=0

if [ -f "$FEATURE_DIR/design/screens.yaml" ]; then
  # Count screens using yq (proper YAML parser)
  SCREEN_COUNT=$(yq '.screens | length' "$FEATURE_DIR/design/screens.yaml" 2>/dev/null || echo 0)
  if [ "$SCREEN_COUNT" -gt 0 ]; then
    HAS_SCREENS=true
  fi
fi

# Store for use in RETURN section (atomic write)
PLANNING_CONTEXT_TMP=$(mktemp)
cat > "$PLANNING_CONTEXT_TMP" <<EOF
UI_FEATURE=$HAS_SCREENS
SCREEN_COUNT=$SCREEN_COUNT
EOF
mv "$PLANNING_CONTEXT_TMP" "$FEATURE_DIR/.planning-context"

echo "Feature type: $([ "$HAS_SCREENS" = true ] && echo "UI ($SCREEN_COUNT screens)" || echo "Backend/API")"
echo ""
```

**Detection logic:**
- screens.yaml exists? Use yq to count screen nodes
- At least 1 screen? UI feature = true
- No screens.yaml or empty? Backend feature = false

## PHASE 0: RESEARCH & DISCOVERY

**Prevent duplication - scan before designing:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 PHASE 0: RESEARCH & DISCOVERY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Initialize reuse tracking
REUSABLE_COMPONENTS=()
NEW_COMPONENTS=()
RESEARCH_DECISIONS=()
UNKNOWNS=()

# Determine research depth based on feature classification
NOTES_FILE="$FEATURE_DIR/NOTES.md"

if grep -q "Backend/API feature (no special artifacts)" "$NOTES_FILE" 2>/dev/null ||
   grep -q "Auto-classified: Simple feature" "$NOTES_FILE" 2>/dev/null; then
  RESEARCH_MODE="minimal"
  echo "Research mode: Minimal (simple feature)"
else
  RESEARCH_MODE="full"
  echo "Research mode: Full (complex feature)"
fi
echo ""

# PROJECT DOCUMENTATION INTEGRATION (Mandatory if exists)
PROJECT_DOCS_DIR="docs/project"
HAS_PROJECT_DOCS=false

# Check if project documentation exists
if [ -d "$PROJECT_DOCS_DIR" ]; then
  HAS_PROJECT_DOCS=true
  echo "✅ Project documentation found - loading architecture context"
  echo ""

  # Verify required documentation files exist
  REQUIRED_DOCS=("tech-stack.md" "data-architecture.md" "api-strategy.md")
  MISSING_DOCS=()

  for doc in "${REQUIRED_DOCS[@]}"; do
    if [ ! -f "$PROJECT_DOCS_DIR/$doc" ]; then
      MISSING_DOCS+=("$doc")
    fi
  done

  if [ ${#MISSING_DOCS[@]} -gt 0 ]; then
    echo "⚠️  WARNING: Missing required project documentation:"
    for doc in "${MISSING_DOCS[@]}"; do
      echo "   - $PROJECT_DOCS_DIR/$doc"
    done
    echo ""
    echo "These files are critical for accurate planning."
    echo "Recommendation: Run /init-project to generate project documentation"
    echo ""

    if [ "$STRICT_MODE" = "1" ] && [ "$ASSUME_YES" != "1" ]; then
      echo "STRICT MODE: Cannot proceed without complete project docs"
      echo "Use: --no-strict or --yes flag to bypass"
      exit 1
    elif [ "$ASSUME_YES" = "1" ]; then
      echo "Continuing without complete project docs (--yes flag set)"
      echo ""
    fi
  fi

  # Read and parse project documentation
  echo "📚 Reading project documentation..."

  # PRIORITY 1: Parse tech-stack.md (prevents hallucination)
  if [ -f "$PROJECT_DOCS_DIR/tech-stack.md" ]; then
    echo "  → tech-stack.md"
    # Extract tech stack from markdown table
    FRONTEND_STACK=$(grep "| Frontend |" "$PROJECT_DOCS_DIR/tech-stack.md" 2>/dev/null | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}' || echo "Not specified")
    BACKEND_STACK=$(grep "| Backend |" "$PROJECT_DOCS_DIR/tech-stack.md" 2>/dev/null | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}' || echo "Not specified")
    DATABASE_STACK=$(grep "| Database |" "$PROJECT_DOCS_DIR/tech-stack.md" 2>/dev/null | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}' || echo "Not specified")
    STYLING_STACK=$(grep "| Styling |" "$PROJECT_DOCS_DIR/tech-stack.md" 2>/dev/null | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}' || echo "Not specified")
    STATE_MGMT=$(grep "| State Management |" "$PROJECT_DOCS_DIR/tech-stack.md" 2>/dev/null | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}' || echo "Not specified")

    RESEARCH_DECISIONS+=("Frontend: $FRONTEND_STACK (from tech-stack.md)")
    RESEARCH_DECISIONS+=("Backend: $BACKEND_STACK (from tech-stack.md)")
    RESEARCH_DECISIONS+=("Database: $DATABASE_STACK (from tech-stack.md)")
    RESEARCH_DECISIONS+=("Styling: $STYLING_STACK (from tech-stack.md)")
    RESEARCH_DECISIONS+=("State: $STATE_MGMT (from tech-stack.md)")
  fi

  # PRIORITY 2: Parse data-architecture.md (prevents duplicate entities)
  if [ -f "$PROJECT_DOCS_DIR/data-architecture.md" ]; then
    echo "  → data-architecture.md"
    EXISTING_ENTITIES=$(grep -E "^### |^## " "$PROJECT_DOCS_DIR/data-architecture.md" 2>/dev/null | grep -v "ERD\|Entity\|Architecture\|Overview" | sed 's/^#* //' | tr '\n' ', ' | sed 's/, $//' || echo "Not documented")
    NAMING_CONVENTION=$(grep -i "naming convention" "$PROJECT_DOCS_DIR/data-architecture.md" -A 2 2>/dev/null | tail -1 | sed 's/^[*-] //' || echo "Not specified")

    RESEARCH_DECISIONS+=("Existing Entities: $EXISTING_ENTITIES (from data-architecture.md)")
    RESEARCH_DECISIONS+=("Naming Convention: $NAMING_CONVENTION (from data-architecture.md)")
  fi

  # PRIORITY 3: Parse api-strategy.md (ensures API consistency)
  if [ -f "$PROJECT_DOCS_DIR/api-strategy.md" ]; then
    echo "  → api-strategy.md"
    API_STYLE=$(grep -E "REST|GraphQL|tRPC|gRPC" "$PROJECT_DOCS_DIR/api-strategy.md" 2>/dev/null | head -1 | sed 's/^[*-] //' | sed 's/:.*//' || echo "REST")
    AUTH_PROVIDER=$(grep -i "auth.*provider\|authentication.*provider" "$PROJECT_DOCS_DIR/api-strategy.md" -A 1 2>/dev/null | tail -1 | sed 's/^[*-] //' || echo "Not specified")
    API_VERSIONING=$(grep -i "versioning" "$PROJECT_DOCS_DIR/api-strategy.md" -A 2 2>/dev/null | grep -E "/v[0-9]|version" | head -1 || echo "Not specified")

    RESEARCH_DECISIONS+=("API Style: $API_STYLE (from api-strategy.md)")
    RESEARCH_DECISIONS+=("Auth Provider: $AUTH_PROVIDER (from api-strategy.md)")
    RESEARCH_DECISIONS+=("API Versioning: $API_VERSIONING (from api-strategy.md)")
  fi

  # PRIORITY 4: Parse capacity-planning.md (performance targets)
  if [ -f "$PROJECT_DOCS_DIR/capacity-planning.md" ]; then
    echo "  → capacity-planning.md"
    SCALE_TIER=$(grep -i "scale tier\|tier:" "$PROJECT_DOCS_DIR/capacity-planning.md" 2>/dev/null | head -1 | grep -oE "micro|small|medium|large" || echo "micro")
    API_RESPONSE_TARGET=$(grep -i "API response\|p95\|response time" "$PROJECT_DOCS_DIR/capacity-planning.md" 2>/dev/null | grep -oE "[0-9]+ms" | head -1 || echo "200ms")

    RESEARCH_DECISIONS+=("Scale Tier: $SCALE_TIER (from capacity-planning.md)")
    RESEARCH_DECISIONS+=("API Response Target: $API_RESPONSE_TARGET (from capacity-planning.md)")
  fi

  # OPTIONAL: Parse system-architecture.md, deployment-strategy.md, development-workflow.md
  if [ -f "$PROJECT_DOCS_DIR/system-architecture.md" ]; then
    echo "  → system-architecture.md"
    ARCHITECTURE_STYLE=$(grep -i "monolith\|microservices\|serverless" "$PROJECT_DOCS_DIR/system-architecture.md" 2>/dev/null | head -1 | grep -oE "monolith|microservices|serverless" || echo "monolith")
    RESEARCH_DECISIONS+=("Architecture: $ARCHITECTURE_STYLE (from system-architecture.md)")
  fi

  if [ -f "$PROJECT_DOCS_DIR/deployment-strategy.md" ]; then
    echo "  → deployment-strategy.md"
    DEPLOYMENT_MODEL=$(grep -i "staging-prod\|direct-prod\|local-only" "$PROJECT_DOCS_DIR/deployment-strategy.md" 2>/dev/null | head -1 | grep -oE "staging-prod|direct-prod|local-only" || echo "staging-prod")
    DEPLOYMENT_PLATFORM=$(grep -i "platform:" "$PROJECT_DOCS_DIR/deployment-strategy.md" 2>/dev/null | head -1 | sed 's/.*: //' || echo "Not specified")
    RESEARCH_DECISIONS+=("Deployment: $DEPLOYMENT_MODEL on $DEPLOYMENT_PLATFORM (from deployment-strategy.md)")
  fi

  echo "✅ Project documentation loaded successfully"
  echo ""

else
  echo "ℹ️  No project documentation found at $PROJECT_DOCS_DIR"
  echo ""
  echo "Project documentation provides:"
  echo "  • Tech stack (prevents hallucination)"
  echo "  • Existing entities (prevents duplication)"
  echo "  • API patterns (ensures consistency)"
  echo "  • Performance targets (better design)"
  echo ""

  if [ "$STRICT_MODE" = "1" ] && [ "$ASSUME_YES" != "1" ]; then
    echo "STRICT MODE: Cannot proceed without project docs"
    echo "Recommendation: Run /init-project (one-time setup, ~10 minutes)"
    echo "Or use: --no-strict flag to bypass"
    exit 1
  elif [ "$ASSUME_YES" = "1" ]; then
    echo "⚠️  Proceeding without project documentation (--yes flag set)"
    echo "   Planning may make assumptions about tech stack and architecture"
    echo ""
  fi
fi
```

**Research depth optimization:**
- **Minimal** (2-3 tools for simple features): Read spec, grep keywords, optional glob
- **Full** (5-15 tools for complex, **2-5 if project docs exist**): Above + modules, patterns, WebSearch (skip if docs exist)

**Document decisions and generate research.md (single source of truth):**

```bash
RESEARCH_FILE="$FEATURE_DIR/research.md"
RESEARCH_TMP=$(mktemp)

cat > "$RESEARCH_TMP" <<EOF
# Research & Discovery: $SLUG

$(if [ "$HAS_PROJECT_DOCS" = true ]; then
  echo "## Project Documentation Context"
  echo ""
  echo "**Source**: \`docs/project/\` (project-level architecture)"
  echo ""
  echo "### Tech Stack"
  echo "- **Frontend**: ${FRONTEND_STACK:-Not specified}"
  echo "- **Backend**: ${BACKEND_STACK:-Not specified}"
  echo "- **Database**: ${DATABASE_STACK:-Not specified}"
  echo "- **Styling**: ${STYLING_STACK:-Not specified}"
  echo "- **State**: ${STATE_MGMT:-Not specified}"
  echo "- **API Style**: ${API_STYLE:-REST}"
  echo "- **Auth**: ${AUTH_PROVIDER:-Not specified}"
  echo ""
  echo "### Performance & Scale"
  echo "- **Scale Tier**: ${SCALE_TIER:-micro}"
  echo "- **API Response Target (p95)**: ${API_RESPONSE_TARGET:-200ms}"
  echo ""
  echo "### Architecture & Deployment"
  echo "- **Architecture**: ${ARCHITECTURE_STYLE:-monolith}"
  echo "- **Deployment Model**: ${DEPLOYMENT_MODEL:-staging-prod}"
  echo "- **Platform**: ${DEPLOYMENT_PLATFORM:-Not specified}"
  echo ""
  echo "---"
  echo ""
fi)

## Research Decisions

$(if [ ${#RESEARCH_DECISIONS[@]} -gt 0 ]; then
  for decision in "${RESEARCH_DECISIONS[@]}"; do
    echo "- $decision"
  done
else
  echo "No research decisions documented yet."
fi)

---

## Components to Reuse (${#REUSABLE_COMPONENTS[@]} found)

$(for component in "${REUSABLE_COMPONENTS[@]}"; do
  echo "- $component"
done)

---

## New Components Needed (${#NEW_COMPONENTS[@]} required)

$(for component in "${NEW_COMPONENTS[@]}"; do
  echo "- $component"
done)

---

## Unknowns & Questions

$(if [ ${#UNKNOWNS[@]} -gt 0 ]; then
  for unknown in "${UNKNOWNS[@]}"; do
    echo "- ⚠️  $unknown"
  done
else
  echo "None - all technical questions resolved"
fi)

---

**Artifact Metadata:**
- Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Commit: $COMMIT_SHA
- Hash: $(echo -n "$SLUG-$COMMIT_SHA" | sha256sum | cut -c1-8)
EOF

# Validate and move atomically
if grep -q "Research & Discovery" "$RESEARCH_TMP"; then
  mv "$RESEARCH_TMP" "$RESEARCH_FILE"
  echo "✅ Generated research.md (hash: $(sha256sum "$RESEARCH_FILE" | cut -c1-8))"
else
  echo "❌ Failed to generate research.md"
  rm "$RESEARCH_TMP"
  exit 1
fi
echo ""
```

## PHASE 1: DESIGN & CONTRACTS

**Prerequisites**: research.md complete, unknowns resolved

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎨 PHASE 1: DESIGN & CONTRACTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
```

### Step 1: Generate data-model.md (atomic)

**Extract entities from feature spec:**

```bash
DATA_MODEL_FILE="$FEATURE_DIR/data-model.md"
DATA_MODEL_TMP=$(mktemp)

cat > "$DATA_MODEL_TMP" <<EOF
# Data Model: $SLUG

## Entities

### [Entity Name]
**Purpose**: [description]

**Fields**:
- \`id\`: UUID (PK)
- \`field_name\`: Type - [description]
- \`created_at\`: Timestamp
- \`updated_at\`: Timestamp

**Relationships**:
- Has many: [related entity]
- Belongs to: [parent entity]

**Validation Rules**:
- [field]: [constraint] (from requirement FR-XXX)

**State Transitions** (if applicable):
- Initial → Active (on creation)
- Active → Archived (on deletion)

---

## Database Schema (Mermaid)

\`\`\`mermaid
erDiagram
    users ||--o{ preferences : has
    users {
        uuid id PK
        string email
        timestamp created_at
    }
    preferences {
        uuid id PK
        uuid user_id FK
        jsonb settings
        timestamp updated_at
    }
\`\`\`

---

## API Schemas

**Request/Response Schemas**: See contracts/api.yaml

**State Shape** (frontend):
\`\`\`typescript
interface FeatureState {
  data: Data | null
  loading: boolean
  error: Error | null
}
\`\`\`

---

**Artifact Metadata:**
- Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Commit: $COMMIT_SHA
EOF

mv "$DATA_MODEL_TMP" "$DATA_MODEL_FILE"
echo "✅ Generated data-model.md (hash: $(sha256sum "$DATA_MODEL_FILE" | cut -c1-8))"
echo ""
```

### Step 2: Generate OpenAPI 3.1.0 contracts with RFC 9457 Problem Details (atomic)

**Generate valid OpenAPI specs from functional requirements:**

```bash
mkdir -p "$FEATURE_DIR/contracts"

CONTRACTS_FILE="$FEATURE_DIR/contracts/api.yaml"
CONTRACTS_TMP=$(mktemp)

cat > "$CONTRACTS_TMP" <<EOF
openapi: 3.1.0
info:
  title: ${SLUG} API
  version: 1.0.0
  description: API contract for ${SLUG} feature
  contact:
    name: API Support
    url: https://example.com/support

jsonSchemaDialect: "https://json-schema.org/draft/2020-12/schema"

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: https://api-staging.example.com/v1
    description: Staging
  - url: http://localhost:8000/v1
    description: Development

components:
  schemas:
    # RFC 9457 Problem Details for HTTP APIs
    # Reference: https://www.rfc-editor.org/rfc/rfc9457.html
    ProblemDetails:
      type: object
      properties:
        type:
          type: string
          format: uri
          description: URI reference identifying the problem type
          example: https://api.example.com/problems/validation-error
        title:
          type: string
          description: Short human-readable summary
          example: Validation Error
        status:
          type: integer
          description: HTTP status code
          example: 400
        detail:
          type: string
          description: Human-readable explanation specific to this occurrence
          example: The 'email' field must be a valid email address
        instance:
          type: string
          format: uri
          description: URI reference identifying the specific occurrence
          example: /api/v1/users/12345
        trace_id:
          type: string
          description: Unique identifier for tracing and log correlation
          example: a3f8d2e1b9c4f7a2
      required:
        - type
        - title
        - status

    # Feature-specific schemas
    FeatureData:
      type: object
      properties:
        id:
          type: string
          format: uuid
          description: Unique identifier
        name:
          type: string
          description: Feature name
        created_at:
          type: string
          format: date-time
          description: Creation timestamp
      required:
        - id
        - name

  responses:
    # Standard error responses (RFC 9457)
    BadRequest:
      description: Bad request - validation failed
      content:
        application/problem+json:
          schema:
            \$ref: '#/components/schemas/ProblemDetails'
          examples:
            validation_error:
              value:
                type: https://api.example.com/problems/validation-error
                title: Validation Error
                status: 400
                detail: The 'email' field must be a valid email address
                instance: /api/v1/${SLUG}
                trace_id: a3f8d2e1b9c4f7a2

    Unauthorized:
      description: Unauthorized - authentication required
      content:
        application/problem+json:
          schema:
            \$ref: '#/components/schemas/ProblemDetails'

    InternalServerError:
      description: Internal server error
      content:
        application/problem+json:
          schema:
            \$ref: '#/components/schemas/ProblemDetails'

paths:
  /api/v1/${SLUG}:
    get:
      summary: List ${SLUG} resources
      operationId: list${SLUG}
      tags:
        - ${SLUG}
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
            maximum: 100
        - name: offset
          in: query
          schema:
            type: integer
            default: 0
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      \$ref: '#/components/schemas/FeatureData'
                  pagination:
                    type: object
                    properties:
                      total:
                        type: integer
                      limit:
                        type: integer
                      offset:
                        type: integer
        '400':
          \$ref: '#/components/responses/BadRequest'
        '401':
          \$ref: '#/components/responses/Unauthorized'
        '500':
          \$ref: '#/components/responses/InternalServerError'

tags:
  - name: ${SLUG}
    description: ${SLUG} feature endpoints

EOF

# Validate OpenAPI schema with yq
if ! yq eval '.' "$CONTRACTS_TMP" >/dev/null 2>&1; then
  echo "❌ Failed to generate valid YAML"
  rm "$CONTRACTS_TMP"
  exit 1
fi

# Validate OpenAPI version is 3.1.0
OAS_VERSION=$(yq eval '.openapi' "$CONTRACTS_TMP")
if [ "$OAS_VERSION" != "3.1.0" ]; then
  echo "❌ Invalid OpenAPI version: $OAS_VERSION (must be 3.1.0)"
  rm "$CONTRACTS_TMP"
  exit 1
fi

# Validate JSON Schema dialect is declared
JSON_SCHEMA_DIALECT=$(yq eval '.jsonSchemaDialect' "$CONTRACTS_TMP")
if [ "$JSON_SCHEMA_DIALECT" != "https://json-schema.org/draft/2020-12/schema" ]; then
  echo "❌ Missing or invalid jsonSchemaDialect (must be https://json-schema.org/draft/2020-12/schema)"
  rm "$CONTRACTS_TMP"
  exit 1
fi

# Validate Problem Details schema exists (RFC 9457)
if ! yq eval '.components.schemas.ProblemDetails' "$CONTRACTS_TMP" >/dev/null 2>&1; then
  echo "❌ Missing ProblemDetails schema (RFC 9457 required)"
  rm "$CONTRACTS_TMP"
  exit 1
fi

# Validate with Redocly CLI if available
if command -v redocly &>/dev/null || npx --yes @redocly/cli --version &>/dev/null 2>&1; then
  echo "🔍 Validating OpenAPI contract with Redocly CLI..."
  if command -v redocly &>/dev/null; then
    redocly lint "$CONTRACTS_TMP" --format=stylish || {
      echo "⚠️  Contract validation warnings (non-blocking)"
    }
  else
    npx --yes @redocly/cli lint "$CONTRACTS_TMP" --format=stylish || {
      echo "⚠️  Contract validation warnings (non-blocking)"
    }
  fi
  echo ""
fi

mv "$CONTRACTS_TMP" "$CONTRACTS_FILE"
echo "✅ Generated contracts/api.yaml (OpenAPI 3.1.0 + RFC 9457, hash: $(sha256sum "$CONTRACTS_FILE" | cut -c1-8))"
echo ""
```

### Step 3: Generate Lighthouse budgets.json (atomic)

**Performance budgets as first-class artifact:**

```bash
BUDGETS_FILE="$FEATURE_DIR/budgets.json"
BUDGETS_TMP=$(mktemp)

# Use targets from project docs or defaults
API_TARGET="${API_RESPONSE_TARGET:-200ms}"
API_TARGET_NUM=$(echo "$API_TARGET" | grep -oE '[0-9]+')

cat > "$BUDGETS_TMP" <<EOF
{
  "lighthouse": {
    "performance": 85,
    "accessibility": 95,
    "best-practices": 90,
    "seo": 90,
    "pwa": 0
  },
  "timings": {
    "fcp": 1500,
    "lcp": 2500,
    "tti": 3000,
    "tbt": 200,
    "cls": 0.1,
    "si": 3000
  },
  "resourceSizes": {
    "total": 300000,
    "script": 150000,
    "stylesheet": 50000,
    "image": 100000,
    "font": 50000
  },
  "api": {
    "response_time_p95_ms": ${API_TARGET_NUM:-200},
    "response_time_p99_ms": $((API_TARGET_NUM * 2)),
    "throughput_rps": 100
  },
  "metadata": {
    "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "commit": "$COMMIT_SHA",
    "feature": "$SLUG",
    "scale_tier": "${SCALE_TIER:-micro}"
  }
}
EOF

# Validate JSON
if jq empty "$BUDGETS_TMP" 2>/dev/null; then
  mv "$BUDGETS_TMP" "$BUDGETS_FILE"
  echo "✅ Generated budgets.json (hash: $(sha256sum "$BUDGETS_FILE" | cut -c1-8))"
else
  echo "❌ Failed to generate valid budgets.json"
  rm "$BUDGETS_TMP"
  exit 1
fi
echo ""
```

### Step 4: Generate quickstart.md (atomic)

**Integration scenarios for developers:**

```bash
QUICKSTART_FILE="$FEATURE_DIR/quickstart.md"
QUICKSTART_TMP=$(mktemp)

cat > "$QUICKSTART_TMP" <<EOF
# Quickstart: $SLUG

## Scenario 1: Initial Setup

\`\`\`bash
# Install dependencies
pnpm install

# Run migrations
cd api && uv run alembic upgrade head

# Seed test data (if applicable)
uv run python scripts/seed_${SLUG}.py

# Start dev servers
pnpm dev
\`\`\`

## Scenario 2: Validation

\`\`\`bash
# Run tests
pnpm test
cd api && uv run pytest tests/${SLUG}/

# Check types
pnpm type-check

# Lint
pnpm lint

# Validate OpenAPI contract (Redocly CLI)
npx @redocly/cli lint specs/${SLUG}/contracts/api.yaml
\`\`\`

## Scenario 3: Manual Testing

1. Navigate to: http://localhost:3000/${SLUG}
2. Verify: [expected behavior]
3. Check: [validation steps]

## Scenario 4: Budget Validation

\`\`\`bash
# Run Lighthouse CI with budgets
npx @lhci/cli autorun --budgets-file=specs/${SLUG}/budgets.json

# Check API performance
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:8000/api/v1/${SLUG}
\`\`\`

---

**Artifact Metadata:**
- Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Commit: $COMMIT_SHA
EOF

mv "$QUICKSTART_TMP" "$QUICKSTART_FILE"
echo "✅ Generated quickstart.md (hash: $(sha256sum "$QUICKSTART_FILE" | cut -c1-8))"
echo ""
```

### Step 5: Generate consolidated plan.md (atomic)

**Comprehensive architecture document:**

```bash
PLAN_FILE="$FEATURE_DIR/plan.md"
PLAN_TMP=$(mktemp)

cat > "$PLAN_TMP" <<EOF
# Implementation Plan: ${SLUG}

## [RESEARCH DECISIONS]

**Source**: research.md (single source of truth)

**Summary**:
- Stack: ${FRONTEND_STACK:-TBD}, ${BACKEND_STACK:-TBD}, ${DATABASE_STACK:-TBD}
- Components to reuse: ${#REUSABLE_COMPONENTS[@]}
- New components needed: ${#NEW_COMPONENTS[@]}

---

## [ARCHITECTURE DECISIONS]

**Stack**:
- Frontend: ${FRONTEND_STACK:-Not specified}
- Backend: ${BACKEND_STACK:-Not specified}
- Database: ${DATABASE_STACK:-Not specified}
- State Management: ${STATE_MGMT:-Not specified}
- Deployment: ${DEPLOYMENT_PLATFORM:-Not specified}

**Patterns**:
- API Style: ${API_STYLE:-REST}
- API Contract: OpenAPI 3.1.0 + JSON Schema 2020-12
- Error Format: RFC 9457 Problem Details
- Auth: ${AUTH_PROVIDER:-Not specified}

**Dependencies** (new packages required):
- [package-name@version]: [purpose]

---

## [STRUCTURE]

**Directory Layout** (follow existing patterns):

\`\`\`
api/src/
├── modules/${SLUG}/
│   ├── controller.py
│   ├── service.py
│   ├── repository.py
│   └── schemas.py
└── tests/
    └── ${SLUG}/

apps/app/
├── app/(authed)/${SLUG}/
│   ├── page.tsx
│   └── components/
└── components/${SLUG}/
\`\`\`

**Module Organization**:
- [Module name]: [purpose and responsibilities]

---

## [DATA MODEL]

**Source**: data-model.md

**Summary**:
- Entities: [count]
- Relationships: [key relationships]
- Migrations required: [Yes/No]

---

## [PERFORMANCE TARGETS]

**From budgets.json** (enforced via Lighthouse CI):
- Lighthouse Performance: ≥85
- Lighthouse Accessibility: ≥95
- FCP: <1.5s
- LCP: <2.5s
- TTI: <3s
- API Response (p95): <${API_TARGET_NUM:-200}ms

**Scale Tier**: ${SCALE_TIER:-micro}

**SLIs/SLOs**:
- **Availability**: 99.9% uptime (43.2 min/month error budget)
- **Latency**: API p95 <${API_TARGET_NUM:-200}ms, p99 <$((API_TARGET_NUM * 2))ms
- **Error Rate**: <0.5% of requests result in 5xx errors
- **Success Rate**: ≥99.5% of requests return 2xx or expected 4xx

---

## [SECURITY]

**Authentication**: ${AUTH_PROVIDER:-Not specified}

**Authorization**: [RBAC model and RLS policies]

**Input Validation**:
- Request schemas: contracts/api.yaml (OpenAPI 3.1.0 + JSON Schema 2020-12)
- Schema validation: Enforced at API gateway

**Rate Limiting**:
- Policy: 100 requests/min per user, burst capacity 50
- Response: HTTP 429 with RFC 9457 Problem Details
- Headers: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset, Retry-After

**CORS**:
- Allowed origins: From env var ALLOWED_ORIGINS (whitelist only)
- Credentials: Same-origin only

**Error Handling**:
- Format: RFC 9457 Problem Details (application/problem+json)
- Trace IDs: UUID v4 for request tracking and log correlation
- Error types URI: https://api.example.com/problems/[error-type]
- Never leak stack traces in production

**Data Protection**:
- PII handling: [scrubbing strategy]
- Encryption at rest: AES-256 for sensitive fields
- Encryption in transit: TLS 1.3+ only
- Secret management: HashiCorp Vault / AWS Secrets Manager

**OWASP ASVS Compliance**:
- **Controls Touched**:
  - V1.4: Access Control Architecture
  - V4.1: Access Control Design
  - V5.1: Input Validation
  - V8.1: Data Protection
  - V13.1: API Security
- **Verification Level**: Level 2 (standard web applications)
- **Reference**: https://owasp.org/www-project-application-security-verification-standard/

---

## [EXISTING INFRASTRUCTURE - REUSE]

**Source**: research.md

**Components** (${#REUSABLE_COMPONENTS[@]} found):
$(for component in "${REUSABLE_COMPONENTS[@]}"; do
  echo "- $component"
done)

---

## [NEW INFRASTRUCTURE - CREATE]

**Components** (${#NEW_COMPONENTS[@]} needed):
$(for component in "${NEW_COMPONENTS[@]}"; do
  echo "- $component"
done)

---

## [CI/CD IMPACT]

**Platform**: ${DEPLOYMENT_PLATFORM:-Not specified}
**Deployment Model**: ${DEPLOYMENT_MODEL:-staging-prod}

**Environment Variables**:
- New required: [list]
- Changed: [list]

**Database Migrations**:
- Required: [Yes/No]
- Reversible: [Yes/No]

**Smoke Tests**:
- Route: /api/v1/${SLUG}/health
- Expected: 200, {"status": "ok"}

---

## [CI QUALITY GATES] (blocking)

**1. Conventional Commits Enforcement**:
- Format: \`type(scope): subject\`
- Tool: commitlint with @commitlint/config-conventional
- Enforcement: .github/workflows/verify.yml
- Failure: PR blocked

**2. Lighthouse Performance Budget**:
- Budget file: specs/${SLUG}/budgets.json
- Tool: Lighthouse CI with \`lhci autorun --budgets-file=...\`
- Thresholds: Performance ≥85, Accessibility ≥95, Best Practices ≥90
- Enforcement: .github/workflows/verify.yml
- Failure: PR blocked with budget report

**3. OpenAPI Contract Validation**:
- Tool: \`@redocly/cli lint specs/${SLUG}/contracts/api.yaml\`
- Validates: OpenAPI 3.1.0 + RFC 9457 Problem Details schema
- Checks: No breaking changes without version bump
- Enforcement: CI validates on every PR
- Failure: PR blocked

**4. Security Baseline**:
- Tool: npm audit / pip-audit / cargo audit
- SAST: CodeQL / Semgrep
- Secret scanning: GitGuardian / TruffleHog
- Failure: PR blocked on critical CVEs or leaked secrets

**5. Test Coverage Gate**:
- Minimum: 80% lines, 70% branches
- Tool: Jest (frontend), pytest-cov (backend)
- Failure: PR blocked if coverage drops

---

## [DEPLOYMENT ACCEPTANCE]

**Production Invariants**:
- No breaking env var changes without migration
- Backward-compatible API changes only (use versioning for breaking)
- Database migrations are reversible
- Feature flags default to 0% in production
- Performance budgets enforced (budgets.json)

**Staging Acceptance** (Gherkin format):
\`\`\`gherkin
Given user visits https://app-staging.example.com/${SLUG}
When user clicks primary CTA
Then feature works without errors
  And response time <2s
  And no console errors
  And Lighthouse performance ≥85
  And API response time <${API_TARGET_NUM:-200}ms (p95)
\`\`\`

**Rollback Plan**:
- Deploy IDs tracked in: specs/${SLUG}/NOTES.md
- Rollback commands: See docs/ROLLBACK_RUNBOOK.md
- Special considerations: [None / Migration downgrade required / Feature flag required]

**Artifact Strategy** (build-once-promote-many):
- Web: Vercel prebuilt artifact (.vercel/output/)
- API: Docker image ghcr.io/org/api:${COMMIT_SHA} (NOT :latest)
- Build in: .github/workflows/verify.yml
- Deploy to staging: .github/workflows/deploy-staging.yml (uses prebuilt)
- Promote to production: .github/workflows/promote.yml (same artifact, SHA: ${COMMIT_SHA})

---

## [INTEGRATION SCENARIOS]

**Source**: quickstart.md

**Summary**:
- Initial setup documented
- Validation workflow defined
- Manual testing steps provided
- Budget validation included

---

**Artifact Metadata:**
- Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Commit: $COMMIT_SHA
- Immutable: true
- Hash: $(echo -n "$SLUG-$COMMIT_SHA" | sha256sum | cut -c1-8)
EOF

mv "$PLAN_TMP" "$PLAN_FILE"
echo "✅ Generated plan.md (hash: $(sha256sum "$PLAN_FILE" | cut -c1-8))"
echo ""
```

### Step 6: Initialize error-log.md (atomic)

```bash
ERROR_LOG_FILE="$FEATURE_DIR/error-log.md"
ERROR_LOG_TMP=$(mktemp)

cat > "$ERROR_LOG_TMP" <<EOF
# Error Log: ${SLUG}

## Planning Phase (Phase 0-2)
None yet.

## Implementation Phase (Phase 3-4)
[Populated during /tasks and /implement]

## Testing Phase (Phase 5)
[Populated during /debug and /preview]

## Deployment Phase (Phase 6-7)
[Populated during staging validation and production deployment]

---

## Error Template

**Error ID**: ERR-[NNN]
**Phase**: [Planning/Implementation/Testing/Deployment]
**Date**: YYYY-MM-DD HH:MM
**Component**: [api/frontend/database/deployment]
**Severity**: [Critical/High/Medium/Low]

**Description**:
[What happened]

**Root Cause**:
[Why it happened]

**Resolution**:
[How it was fixed]

**Prevention**:
[How to prevent in future]

**Related**:
- Spec: [link to requirement]
- Code: [file:line]
- Commit: [sha]

---

**Artifact Metadata:**
- Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Commit: $COMMIT_SHA
EOF

mv "$ERROR_LOG_TMP" "$ERROR_LOG_FILE"
echo "✅ Generated error-log.md (hash: $(sha256sum "$ERROR_LOG_FILE" | cut -c1-8))"
echo ""
```

### Step 7: Validate unresolved questions

**Check for critical unknowns before committing:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ VALIDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for unresolved unknowns in research.md
UNRESOLVED_COUNT=$(grep -c "⚠️" "$FEATURE_DIR/research.md" 2>/dev/null || echo 0)

if [ "$UNRESOLVED_COUNT" -gt 0 ]; then
  echo "⚠️  WARNING: $UNRESOLVED_COUNT unresolved questions in research.md"
  echo ""
  echo "Unresolved questions:"
  grep "⚠️" "$FEATURE_DIR/research.md"
  echo ""

  if [ "$STRICT_MODE" = "1" ]; then
    echo "STRICT MODE: Cannot proceed with critical unknowns."
    echo "Resolve questions in research.md before committing."
    exit 1
  else
    echo "Continuing with unresolved questions (strict mode disabled)"
    echo ""
  fi
else
  echo "✅ All technical questions resolved"
fi

# Validate all artifacts have proper hashes
echo "🔐 Validating artifact integrity..."
for artifact in "$RESEARCH_FILE" "$DATA_MODEL_FILE" "$CONTRACTS_FILE" "$BUDGETS_FILE" "$QUICKSTART_FILE" "$PLAN_FILE" "$ERROR_LOG_FILE"; do
  if [ -f "$artifact" ]; then
    hash=$(sha256sum "$artifact" | cut -c1-8)
    echo "  ✓ $(basename "$artifact"): $hash"
  else
    echo "  ❌ Missing: $(basename "$artifact")"
    exit 1
  fi
done

echo ""
```

## GIT COMMIT (Conventional Commits)

**Commit all planning artifacts:**

```bash
REUSABLE_COUNT=${#REUSABLE_COMPONENTS[@]}
NEW_COUNT=${#NEW_COMPONENTS[@]}

# Use Conventional Commits format
COMMIT_MSG="design(plan): complete architecture with reuse analysis

[ARCHITECTURE DECISIONS]
- Stack: ${FRONTEND_STACK:-TBD}, ${BACKEND_STACK:-TBD}, ${DATABASE_STACK:-TBD}
- API: ${API_STYLE:-REST} with OpenAPI 3.1.0 + JSON Schema 2020-12
- Error Format: RFC 9457 Problem Details
- Performance Budget: Enforced (budgets.json)

[EXISTING - REUSE] (${REUSABLE_COUNT} components)
"

# List reusable components
for component in "${REUSABLE_COMPONENTS[@]}"; do
  COMMIT_MSG="${COMMIT_MSG}
- ${component}"
done

COMMIT_MSG="${COMMIT_MSG}

[NEW - CREATE] (${NEW_COUNT} components)
"

# List new components
for component in "${NEW_COMPONENTS[@]}"; do
  COMMIT_MSG="${COMMIT_MSG}
- ${component}"
done

COMMIT_MSG="${COMMIT_MSG}

Artifacts:
- specs/${SLUG}/research.md (research decisions + component reuse)
- specs/${SLUG}/data-model.md (entity definitions + relationships)
- specs/${SLUG}/contracts/api.yaml (OpenAPI 3.1.0 + RFC 9457 + JSON Schema 2020-12)
- specs/${SLUG}/budgets.json (Lighthouse budgets - enforced)
- specs/${SLUG}/quickstart.md (integration scenarios)
- specs/${SLUG}/plan.md (consolidated architecture + quality gates)
- specs/${SLUG}/error-log.md (initialized for tracking)

Quality Gates (CI blocking):
- Conventional Commits (commitlint)
- Lighthouse budgets (lhci)
- OpenAPI validation (Redocly CLI)
- Security baseline (critical CVEs)
- Test coverage (80% lines, 70% branches)

Next: /tasks

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git add "$FEATURE_DIR/"
git commit -m "$COMMIT_MSG"

# Verify commit succeeded
COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""
echo "✅ Plan committed: $COMMIT_HASH (Conventional Commits format)"
echo ""
git log -1 --oneline
echo ""
```

<constraints>
## ANTI-HALLUCINATION RULES

**CRITICAL**: Follow these rules to prevent making up architectural decisions.

1. **Never speculate about existing patterns you have not read**
   - ❌ BAD: "The app probably follows a services pattern"
   - ✅ GOOD: "Let me search for existing service files to understand current patterns"
   - Use Grep to find patterns: `class.*Service`, `interface.*Repository`

2. **Cite existing code when recommending reuse**
   - When suggesting to reuse UserService, cite: `api/app/services/user.py:20-45`
   - When referencing patterns, cite: `api/app/core/database.py:12-18 shows our DB session pattern`
   - Don't invent reusable components that don't exist

3. **Admit when codebase exploration is needed**
   - If unsure about tech stack, say: "I need to read package.json and search for imports"
   - If uncertain about patterns, say: "Let me search the codebase for similar implementations"
   - Never make up directory structures, module names, or import paths

4. **Quote from spec.md exactly when planning**
   - Don't paraphrase requirements - quote user stories verbatim
   - Example: "According to spec.md:45-48: '[exact quote]', therefore we need..."
   - If spec is ambiguous, flag it rather than assuming intent

5. **Verify dependencies exist before recommending**
   - Before suggesting "use axios for HTTP", check package.json
   - Before recommending libraries, search existing imports
   - Don't suggest packages that aren't installed

**Why this matters**: Hallucinated architecture leads to plans that can't be implemented. Plans based on non-existent patterns create unnecessary refactoring. Accurate planning grounded in actual code saves 40-50% of implementation rework.

## REASONING APPROACH

For complex architecture decisions, show your step-by-step reasoning:

<thinking>
Let me analyze this design choice:
1. What does spec.md require? [Quote requirements]
2. What existing patterns can I reuse? [Cite file:line from codebase]
3. What are the architectural options? [List 2-3 approaches]
4. What are the trade-offs? [Performance, maintainability, complexity]
5. What does constitution.md prefer? [Quote architectural principles]
6. Conclusion: [Recommended approach with justification]
</thinking>

<answer>
[Architecture decision based on reasoning]
</answer>

**When to use structured thinking:**
- Choosing architectural patterns (e.g., REST vs GraphQL, monolith vs microservices)
- Selecting libraries or frameworks (e.g., Redux vs Context API)
- Designing database schemas (normalization vs denormalization)
- Planning file/folder structure for new features
- Deciding on code reuse vs new implementation

**Benefits**: Explicit reasoning reduces architectural rework by 30-40% and improves maintainability.
</constraints>

<instructions>
## RETURN

**Brief summary with conditional next steps:**

```bash
REUSABLE_COUNT=${#REUSABLE_COMPONENTS[@]}
NEW_COUNT=${#NEW_COMPONENTS[@]}
DECISION_COUNT=${#RESEARCH_DECISIONS[@]}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ PLANNING COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Feature: ${SLUG}"
echo "Plan: ${FEATURE_DIR}/plan.md"
echo "Commit: ${COMMIT_SHA}"
echo ""
echo "Summary:"
echo "- Research decisions: ${DECISION_COUNT}"
echo "- Components to reuse: ${REUSABLE_COUNT}"
echo "- New components needed: ${NEW_COUNT}"

# Check if migration plan exists
if [ -f "$FEATURE_DIR/migration-plan.md" ]; then
  echo "- Database migration: Required (see migration-plan.md)"
fi

echo ""
echo "Artifacts created (all hash-verified):"
echo "  - research.md (research decisions + component reuse)"
echo "  - data-model.md (entity definitions + relationships)"
echo "  - contracts/api.yaml (OpenAPI 3.1.0 + RFC 9457 + JSON Schema 2020-12)"
echo "  - budgets.json (Lighthouse budgets - enforced via CI)"
echo "  - quickstart.md (integration scenarios)"
echo "  - plan.md (consolidated architecture + quality gates)"
echo "  - error-log.md (initialized for tracking)"
echo ""
echo "Quality Gates (CI blocking):"
echo "  - Conventional Commits (commitlint)"
echo "  - Lighthouse budgets (≥85 perf, ≥95 a11y)"
echo "  - OpenAPI validation (Redocly CLI)"
echo "  - Security baseline (block on critical CVEs)"
echo "  - Test coverage (≥80% lines)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 NEXT: /tasks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "/tasks will:"
echo "1. Generate concrete tasks from plan.md"
echo "2. Create tasks.json (canonical) + tasks.md (rendered)"
echo "3. Validate dependency graph (DAG)"
echo "4. Quote acceptance criteria from spec.md"
echo "5. Verify all file paths via git ls-files"
echo ""
echo "Duration: ~2-3 minutes"
echo ""
```
</instructions>
