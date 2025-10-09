---
description: Generate design artifacts from feature spec (research + design + context plan)
---

Design implementation for: $ARGUMENTS

## MENTAL MODEL

**Workflow**:\spec-flow -> clarify -> plan -> tasks -> analyze -> implement -> optimize -> debug -> preview -> phase-1-ship -> validate-staging -> phase-2-ship

**State machine:**
- Load feature -> Research codebase -> Design artifacts -> Document plan -> Suggest next

**Auto-suggest:**
- When complete -> `/tasks`

## USAGE

**Arguments:**
```bash
/plan              # Plan spec in current branch
/plan [slug]       # Plan specific feature by slug
```

**Examples:**
- `/plan` → Uses current git branch name as slug
- `/plan csv-export` → Plans specs/csv-export/spec.md

## LOAD FEATURE

**Get feature from argument or current branch:**

```bash
# Determine slug
if [ -n "$ARGUMENTS" ]; then
  SLUG="$ARGUMENTS"
else
  SLUG=$(git branch --show-current)
fi

# Set paths
FEATURE_DIR="specs/$SLUG"
FEATURE_SPEC="$FEATURE_DIR/spec.md"

# Validate spec exists
if [ ! -f "$FEATURE_SPEC" ]; then
  echo "Error: Spec not found at $FEATURE_SPEC"
  echo "Run \spec-flow first"
  exit 1
fi

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
```

## TEMPLATE VALIDATION

**Verify required templates exist:**

```bash
REQUIRED_TEMPLATES=(
  "\spec-flow/templates/error-log-template.md"
)

for template in "${REQUIRED_TEMPLATES[@]}"; do
  if [ ! -f "$template" ]; then
    echo "Error: Missing required template: $template"
    echo "Run: git checkout main -- \spec-flow/templates/"
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

## RESEARCH CODEBASE (Scaled: 2-15 tool calls)

**Prevent duplication - scan before designing:**

**Initialize reuse tracking:**
```bash
REUSABLE_COMPONENTS=()
NEW_COMPONENTS=()
RESEARCH_DECISIONS=()
```

**Determine research depth based on feature classification:**
```bash
# Check if simple feature (from NOTES.md classification)
if grep -q "Backend/API feature (no special artifacts)" "$NOTES_FILE" ||
   grep -q "Auto-classified: Simple feature" "$NOTES_FILE"; then
  RESEARCH_MODE="minimal"
  echo "Research mode: Minimal (simple feature)"
else
  RESEARCH_MODE="full"
  echo "Research mode: Full (complex feature)"
fi
echo ""
```

**Minimal research** (2-3 tools for simple features):
1. **Read spec**: Extract requirements, NFRs, deployment considerations
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
```

**Output**: Findings documented in plan.md [RESEARCH DECISIONS] section

## DESIGN ARTIFACTS

**Generate consolidated `plan.md`:**

```markdown
# Implementation Plan: [Feature Name]

## [RESEARCH DECISIONS]

### Decision: [Technology/Pattern Choice]
- **Decision**: [what chosen]
- **Rationale**: [why this over alternatives]
- **Alternatives**: [what rejected and why]
- **Source**: [link/file/research]

[Repeat for each major decision]

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

## [SCHEMA]

**Database Tables** (if applicable):

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

**API Schemas** (OpenAPI):
- See: contracts/api.yaml

**State Shape** (frontend):
\`\`\`typescript
interface FeatureState {
  data: Data | null
  loading: boolean
  error: Error | null
}
\`\`\`

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

**From quickstart perspective:**

### Scenario 1: Initial Setup
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

### Scenario 2: Validation
\`\`\`bash
# Run tests
pnpm test
cd api && uv run pytest tests/[feature]/

# Check types
pnpm type-check

# Lint
pnpm lint
\`\`\`

### Scenario 3: Manual Testing
1. Navigate to: http://localhost:3000/feature
2. Verify: [expected behavior]
3. Check: [validation steps]
```

**Generate `contracts/` directory with API specs:**

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
```

**Initialize `error-log.md` with structure:**

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
- specs/${SLUG}/plan.md (consolidated architecture + design)
- specs/${SLUG}/contracts/api.yaml (OpenAPI specs)
- specs/${SLUG}/error-log.md (initialized for tracking)

Next: /tasks

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git add "$FEATURE_DIR/"
git commit -m "$COMMIT_MSG"
```

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
echo "  - plan.md (consolidated architecture + design)"
echo "  - contracts/api.yaml (OpenAPI specs)"
echo "  - error-log.md (initialized for tracking)"

# Update NOTES.md with Phase 1 checkpoint and summary
source \spec-flow/templates/notes-update-template.sh

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
  "Artifacts: plan.md, contracts/api.yaml, error-log.md" \
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

