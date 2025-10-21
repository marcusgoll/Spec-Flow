---
description: Generate design artifacts from feature spec (research + design + context plan)
scripts:
  sh: scripts/bash/setup-plan.sh --json "{ARGS}"
  ps: scripts/powershell/setup-plan.ps1 -Json "{ARGS}"
---

Design implementation for: $ARGUMENTS

<context>
## MENTAL MODEL

**Workflow**: spec-flow -> clarify -> plan -> tasks -> analyze -> implement -> optimize -> debug -> preview -> phase-1-ship -> validate-staging -> phase-2-ship

**Phases:**
- Phase 0: Research & Discovery → research.md
- Phase 1: Design & Contracts → data-model.md, contracts/, quickstart.md, plan.md

**State machine:**
- Setup -> Constitution check -> Phase 0 (Research) -> Phase 1 (Design) -> Agent update -> Commit -> Suggest next

**Auto-suggest:**
- UI features → `/design-variations` or `/tasks`
- Backend features → `/tasks`
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
# For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot'
# (or double-quote if possible: "I'm Groot")

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
```

## LOAD CONTEXT

**Load spec and constitution:**

```bash
# Constitution file for alignment check
CONSTITUTION_FILE=".spec-flow/memory/constitution.md"

# Validate spec is clarified (optional check)
REMAINING_CLARIFICATIONS=$(grep -c "\[NEEDS CLARIFICATION\]" "$FEATURE_SPEC" || echo 0)
if [ "$REMAINING_CLARIFICATIONS" -gt 0 ]; then
  echo "⚠️  Warning: $REMAINING_CLARIFICATIONS ambiguities remain in spec"
  echo ""
  echo "Recommend: /clarify (resolve ambiguities first)"
  echo "Or: Continue to /plan (clarify later)"
  echo ""
  read -p "Continue? (Y/n): " continue_choice

  if [[ "$continue_choice" =~ ^[Nn]$ ]]; then
    echo "Aborted. Run /clarify to resolve ambiguities."
    exit 0
  fi
fi

# Read spec and constitution for planning
echo "Loading feature spec and constitution..."
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

**Check if UI design needed:**

```bash
HAS_SCREENS=false
SCREEN_COUNT=0

if [ -f "$FEATURE_DIR/design/screens.yaml" ]; then
  # Count screens (lines starting with 2 spaces + letter)
  SCREEN_COUNT=$(grep -c "^  [a-z]" "$FEATURE_DIR/design/screens.yaml" 2>/dev/null || echo 0)
  if [ "$SCREEN_COUNT" -gt 0 ]; then
    HAS_SCREENS=true
  fi
fi

# Store for use in RETURN section
echo "UI_FEATURE=$HAS_SCREENS" > "$FEATURE_DIR/.planning-context"
echo "SCREEN_COUNT=$SCREEN_COUNT" >> "$FEATURE_DIR/.planning-context"
```

**Detection logic:**
- screens.yaml exists? Check for screen definitions
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
```

**Minimal research** (2-3 tools for simple features):
1. **Read spec**: Extract requirements, NFRs, deployment considerations, unknowns
2. **Grep keywords**: Quick scan for similar patterns to reuse
3. **Glob modules** (optional): If integration needed with existing code

**Full research** (5-15 tools for complex features):
1-3. Minimal research (above)
4. **Glob modules**: `api/src/modules/*`, `api/src/services/*`, `apps/*/components/**`, `apps/*/lib/**`
5-6. **Read similar modules**: Study patterns, categorize as reusable or inspiration
   - If reusable: `REUSABLE_COMPONENTS+=("api/src/services/auth: JWT validation")`
   - If new needed: `NEW_COMPONENTS+=("api/src/services/csv-parser: New capability")`
7. **WebSearch best practices**: If novel pattern (not in codebase)
8. **Read design-inspirations.md**: If UI-heavy feature
9-10. **Read integration points**: Auth, billing, storage services (if complex integration)
11-15. **Deep dive - Read related modules**: If complex integration across multiple systems
16. **Read visuals/README.md**: UX patterns (if exists)

**Document decisions:**
```bash
RESEARCH_DECISIONS+=("Stack choice: Next.js App Router (existing pattern)")
RESEARCH_DECISIONS+=("State: SWR for data fetching (reuse apps/app/lib/swr)")
RESEARCH_DECISIONS+=("Auth: Clerk middleware (reuse existing setup)")

# Track unknowns that need clarification
UNKNOWNS+=("Performance threshold for CSV parsing unclear")
UNKNOWNS+=("Rate limiting strategy not specified")
```

**Generate research.md:**

```bash
RESEARCH_FILE="$FEATURE_DIR/research.md"

cat > "$RESEARCH_FILE" <<EOF
# Research & Discovery: $SLUG

## Research Decisions

$(for decision in "${RESEARCH_DECISIONS[@]}"; do
  echo "### Decision: $decision"
  echo ""
  echo "- **Decision**: [what chosen]"
  echo "- **Rationale**: [why this over alternatives]"
  echo "- **Alternatives**: [what rejected and why]"
  echo "- **Source**: [link/file/research]"
  echo ""
done)

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

EOF

echo "✅ Generated research.md"
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

### Step 1: Generate data-model.md

**Extract entities from feature spec:**

```bash
DATA_MODEL_FILE="$FEATURE_DIR/data-model.md"

cat > "$DATA_MODEL_FILE" <<'EOF'
# Data Model: $SLUG

## Entities

### [Entity Name]
**Purpose**: [description]

**Fields**:
- `id`: UUID (PK)
- `field_name`: Type - [description]
- `created_at`: Timestamp
- `updated_at`: Timestamp

**Relationships**:
- Has many: [related entity]
- Belongs to: [parent entity]

**Validation Rules**:
- [field]: [constraint] (from requirement FR-XXX)
- [field]: [constraint] (from requirement FR-YYY)

**State Transitions** (if applicable):
- Initial → Active (on creation)
- Active → Archived (on deletion)
- Active → Suspended (on violation)

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
EOF

echo "✅ Generated data-model.md"
echo ""
```

### Step 2: Generate API contracts

**Generate OpenAPI specs from functional requirements:**

```bash
mkdir -p "$FEATURE_DIR/contracts"

cat > "$FEATURE_DIR/contracts/api.yaml" <<'EOF'
openapi: 3.0.0
info:
  title: [Feature] API
  version: 1.0.0
paths:
  /api/v1/[feature]:
    get:
      summary: [description]
      parameters: []
      responses:
        200:
          description: Success
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
        400:
          description: Bad request
        401:
          description: Unauthorized
        500:
          description: Server error
EOF

echo "✅ Generated contracts/api.yaml"
echo ""
```

### Step 3: Generate quickstart.md

**Integration scenarios for developers:**

```bash
QUICKSTART_FILE="$FEATURE_DIR/quickstart.md"

cat > "$QUICKSTART_FILE" <<'EOF'
# Quickstart: $SLUG

## Scenario 1: Initial Setup

\`\`\`bash
# Install dependencies
pnpm install

# Run migrations
cd api && uv run alembic upgrade head

# Seed test data
uv run python scripts/seed_[feature].py

# Start dev servers
pnpm dev
\`\`\`

## Scenario 2: Validation

\`\`\`bash
# Run tests
pnpm test
cd api && uv run pytest tests/[feature]/

# Check types
pnpm type-check

# Lint
pnpm lint
\`\`\`

## Scenario 3: Manual Testing

1. Navigate to: http://localhost:3000/feature
2. Verify: [expected behavior]
3. Check: [validation steps]
EOF

echo "✅ Generated quickstart.md"
echo ""
```

### Step 4: Generate consolidated plan.md

**Comprehensive architecture document:**

```markdown
# Implementation Plan: [Feature Name]

## [RESEARCH DECISIONS]

See: research.md for full research findings

**Summary**:
- Stack: [choices from research.md]
- Components to reuse: ${#REUSABLE_COMPONENTS[@]}
- New components needed: ${#NEW_COMPONENTS[@]}

---

## [ARCHITECTURE DECISIONS]

**Stack**:
- Frontend: [Next.js App Router / React / etc.]
- Backend: [FastAPI / Express / etc.]
- Database: [PostgreSQL / MongoDB / etc.]
- State Management: [SWR / Redux / Zustand / Context]
- Deployment: [Vercel / Railway / etc.]

**Patterns**:
- [Pattern name]: [description and rationale]
- [Pattern name]: [description and rationale]

**Dependencies** (new packages required):
- [package-name@version]: [purpose]

---

## [STRUCTURE]

**Directory Layout** (follow existing patterns):

\`\`\`
api/src/
├── modules/[feature]/
│   ├── controller.py
│   ├── service.py
│   ├── repository.py
│   └── schemas.py
└── tests/
    └── [feature]/

apps/app/
├── app/(authed)/[feature]/
│   ├── page.tsx
│   └── components/
└── components/[feature]/
\`\`\`

**Module Organization**:
- [Module name]: [purpose and responsibilities]

---

## [DATA MODEL]

See: data-model.md for complete entity definitions

**Summary**:
- Entities: [count]
- Relationships: [key relationships]
- Migrations required: [Yes/No]

---

## [PERFORMANCE TARGETS]

**From spec.md NFRs** (or defaults from design/systems/budgets.md):
- NFR-003: API response time <500ms (95th percentile)
- NFR-004: Frontend FCP <1.5s, TTI <3s
- NFR-005: Database queries <100ms

**Lighthouse Targets**:
- Performance: ≥85
- Accessibility: ≥95
- Best Practices: ≥90
- SEO: ≥90

---

## [SECURITY]

**Authentication Strategy**:
- [Clerk middleware / JWT / etc.]
- Protected routes: [list]

**Authorization Model**:
- RBAC: [roles and permissions]
- RLS policies: [database-level security]

**Input Validation**:
- Request schemas: [Zod / Pydantic / etc.]
- Rate limiting: [100 req/min per user]
- CORS: [allowed origins from env vars]

**Data Protection**:
- PII handling: [scrubbing strategy]
- Encryption: [at-rest / in-transit]

---

## [EXISTING INFRASTRUCTURE - REUSE] (${#REUSABLE_COMPONENTS[@]} components)

**Services/Modules**:
- api/src/services/auth: JWT token validation
- api/src/lib/storage: S3 file uploads
- apps/app/lib/swr: Data fetching hooks

**UI Components**:
- apps/app/components/ui/button: Primary CTA
- apps/app/components/ui/card: Container layout
- apps/app/components/ui/alert: Error messages

**Utilities**:
- api/src/utils/validation: Input sanitization
- apps/app/lib/format: Date/time formatting

---

## [NEW INFRASTRUCTURE - CREATE] (${#NEW_COMPONENTS[@]} components)

**Backend**:
- api/src/services/csv-parser: Parse AKTR CSV format
- api/src/modules/analytics: Track feature usage

**Frontend**:
- apps/app/app/(public)/feature/page.tsx: Main feature page
- apps/app/components/feature/widget: Custom widget

**Database**:
- Alembic migration: Add [table_name] table
- RLS policies: Row-level security for [table_name]

---

## [CI/CD IMPACT]

**From spec.md deployment considerations:**
- Platform: [Vercel edge middleware / Railway / etc.]
- Env vars: [list new/changed variables]
- Breaking changes: [Yes/No - details]
- Migration: [Yes/No - see migration-plan.md]

**Build Commands**:
- [No changes / New: pnpm build:feature / Changed: Added --experimental-flag]

**Environment Variables** (update secrets.schema.json):
- New required: FEATURE_FLAG_X, API_KEY_Y
- Changed: NEXT_PUBLIC_API_URL format
- Staging values: [values]
- Production values: [values]

**Database Migrations**:
- [No / Yes: migration-plan.md created]
- Dry-run required: [Yes/No]
- Reversible: [Yes/No]

**Smoke Tests** (for deploy-staging.yml and promote.yml):
- Route: /api/v1/feature/health
- Expected: 200, {"status": "ok"}
- Playwright: @smoke tag in tests/smoke/[feature].spec.ts

**Platform Coupling**:
- Vercel: [None / Edge middleware change / Ignored build step update]
- Railway: [None / Dockerfile change / Start command change]
- Dependencies: [None / New: package-x@1.2.3]

---

## [DEPLOYMENT ACCEPTANCE]

**Production Invariants** (must hold true):
- No breaking NEXT_PUBLIC_* env var changes without migration
- Backward-compatible API changes only (use versioning for breaking)
- Database migrations are reversible
- Feature flags default to 0% in production

**Staging Smoke Tests** (Given/When/Then):
\`\`\`gherkin
Given user visits https://app-staging.cfipros.vercel.app/feature
When user clicks primary CTA
Then feature works without errors
  And response time <2s
  And no console errors
  And Lighthouse performance ≥85
\`\`\`

**Rollback Plan**:
- Deploy IDs tracked in: specs/[slug]/NOTES.md (Deployment Metadata)
- Rollback commands: See docs/ROLLBACK_RUNBOOK.md
- Special considerations: [None / Must downgrade migration / Feature flag required]

**Artifact Strategy** (build-once-promote-many):
- Web (Marketing): Vercel prebuilt artifact (.vercel/output/)
- Web (App): Vercel prebuilt artifact (.vercel/output/)
- API: Docker image ghcr.io/cfipros/api:<commit-sha> (NOT :latest)
- Build in: .github/workflows/verify.yml
- Deploy to staging: .github/workflows/deploy-staging.yml (uses prebuilt)
- Promote to production: .github/workflows/promote.yml (same artifact)

---

## [INTEGRATION SCENARIOS]

See: quickstart.md for complete integration scenarios

**Summary**:
- Initial setup documented
- Validation workflow defined
- Manual testing steps provided

---

### Step 5: Initialize error-log.md

```bash
cat > "$FEATURE_DIR/error-log.md" <<EOF
# Error Log: [Feature Name]

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
EOF

echo "✅ Generated error-log.md"
echo ""
```

### Step 6: Validate unresolved questions

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
  echo "ERROR: Cannot proceed with critical unknowns."
  echo "Resolve questions in research.md before committing."
  exit 1
else
  echo "✅ All technical questions resolved"
fi

echo ""
```

## GIT COMMIT

**Commit all planning artifacts:**

```bash
REUSABLE_COUNT=${#REUSABLE_COMPONENTS[@]}
NEW_COUNT=${#NEW_COMPONENTS[@]}

COMMIT_MSG="design:plan: complete architecture with reuse analysis

[ARCHITECTURE DECISIONS]
- Stack: [choices from plan.md]
- Patterns: [decisions from plan.md]

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
- specs/${SLUG}/research.md (research decisions + component reuse analysis)
- specs/${SLUG}/data-model.md (entity definitions + relationships)
- specs/${SLUG}/quickstart.md (integration scenarios)
- specs/${SLUG}/plan.md (consolidated architecture + design)
- specs/${SLUG}/contracts/api.yaml (OpenAPI specs)
- specs/${SLUG}/error-log.md (initialized for tracking)

Next: /tasks

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git add "$FEATURE_DIR/"
git commit -m "$COMMIT_MSG"

# Verify commit succeeded
COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""
echo "✅ Plan committed: $COMMIT_HASH"
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
</constraints>

<instructions>
## CONTEXT MANAGEMENT

**Before proceeding to /tasks:**

If context feels large (long conversation with many research tools), run compaction:
```bash
/compact "preserve architecture decisions, reuse analysis, and schema"
```

Otherwise proceed directly to `/tasks`.

**No automatic tracking.** Manual compaction only if needed.

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
echo ""
echo "Summary:"
echo "- Research decisions: ${DECISION_COUNT}"
echo "- Components to reuse: ${REUSABLE_COUNT}"
echo "- New components needed: ${NEW_COUNT}"

# Check if migration plan exists
if [ -f "$FEATURE_DIR/migration-plan.md" ]; then
  echo "- Database migration: Required (see migration-plan.md)"
fi

# Check if deployment considerations exist
if grep -q "Deployment Considerations" "$FEATURE_SPEC"; then
  echo "- Deployment impact: See [CI/CD IMPACT] in plan.md"
fi

echo ""
echo "Artifacts created:"
echo "  - research.md (research decisions + component reuse)"
echo "  - data-model.md (entity definitions + relationships)"
echo "  - quickstart.md (integration scenarios)"
echo "  - plan.md (consolidated architecture + design)"
echo "  - contracts/api.yaml (OpenAPI specs)"
echo "  - error-log.md (initialized for tracking)"

# Update NOTES.md with Phase 1 checkpoint and summary
source .spec-flow/templates/notes-update-template.sh

# Calculate metrics
RESEARCH_LINES=$(wc -l < "$FEATURE_DIR/research.md" 2>/dev/null || echo 0)
HAS_MIGRATION=$([ -f "$FEATURE_DIR/migration-plan.md" ] && echo "Yes" || echo "No")

# Add Phase 1 Summary
update_notes_summary "$FEATURE_DIR" "1" \
  "Research depth: $RESEARCH_LINES lines" \
  "Key decisions: $DECISION_COUNT" \
  "Components to reuse: $REUSABLE_COUNT" \
  "New components: $NEW_COUNT" \
  "Migration needed: $HAS_MIGRATION"

# Add Phase 1 checkpoint
update_notes_checkpoint "$FEATURE_DIR" "1" "Plan" \
  "Artifacts: research.md, data-model.md, quickstart.md, plan.md, contracts/api.yaml, error-log.md" \
  "Research decisions: $DECISION_COUNT" \
  "Migration required: $HAS_MIGRATION"

update_notes_timestamp "$FEATURE_DIR"

echo ""
echo "NOTES.md: Phase 1 checkpoint and summary added"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 NEXT STEPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Load planning context
source "$FEATURE_DIR/.planning-context"

# Determine path based on UI detection
if [ "$HAS_SCREENS" = true ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎨 UI DESIGN PATH"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Detected: $SCREEN_COUNT screens in design/screens.yaml"
  echo ""
  echo "Recommended workflow (design-first):"
  echo ""
  echo "1. /design-variations $SLUG"
  echo "   Generate 3-5 grayscale variants per screen"
  echo "   Output: apps/web/mock/$SLUG/[screen]/[v1-v5]"
  echo "   Duration: ~5-10 minutes"
  echo ""
  echo "2. Review variants + fill crit.md"
  echo "   Open: http://localhost:3000/mock/$SLUG/[screen]"
  echo "   Decide: Keep/Change/Kill each variant"
  echo "   Compare: http://localhost:3000/mock/$SLUG/[screen]/compare"
  echo "   Duration: ~15-30 minutes (human)"
  echo ""
  echo "3. /design-functional $SLUG"
  echo "   Merge selected variants → functional prototype"
  echo "   Add: Keyboard nav, ARIA labels, Playwright tests"
  echo "   Output: apps/web/mock/$SLUG/[screen]/functional"
  echo "   Duration: ~10-15 minutes"
  echo ""
  echo "4. /tasks $SLUG"
  echo "   Generate implementation tasks from functional prototype"
  echo "   Output: specs/$SLUG/tasks.md"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚡ SKIP DESIGN (Power User)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Alternative workflow (skip to implementation):"
  echo ""
  echo "→ /tasks $SLUG"
  echo "  Generate tasks directly from spec.md + plan.md"
  echo "  Design decisions made during implementation"
  echo ""
else
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚙️  BACKEND PATH"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "No UI screens detected (backend/API/data feature)"
  echo ""
  echo "Next: /tasks $SLUG"
  echo ""
fi

echo ""
echo "Automated (full workflow):"
echo "  → /flow continue"
echo ""

# Optional compaction reminder if conversation is long
CONTEXT_CHECK=$(wc -l < /dev/stdin 2>/dev/null || echo 0)
if [ "$CONTEXT_CHECK" -gt 500 ]; then
  echo "💡 Tip: Long conversation detected"
  echo "   Consider: /compact before /tasks"
fi
```

</instructions>
