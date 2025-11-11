---
description: Generate concrete TDD tasks from design artifacts (no generic placeholders)
---

Create tasks from: specs/$SLUG/plan.md

<context>
## MENTAL MODEL

**Workflow**: spec → clarify → plan → tasks → implement → optimize → preview → ship

**State machine**: Load design artifacts → Extract user stories → Map to tasks → Generate by story priority

**Philosophy**:
- **Traceable**: Every task links to exact source lines in plan/spec
- **Deterministic**: Same inputs always produce same outputs
- **Verifiable**: All paths checked via git, all sections checked via grep
- **User story organization**: One phase per story for clear progress tracking

**Auto-suggest**: When complete → `/validate`

**Prerequisites**:
- Git repository
- jq installed (JSON parsing)
- Feature spec and plan completed (spec.md, plan.md exist)
</context>

<constraints>
## ANTI-HALLUCINATION RULES

**CRITICAL**: Follow these rules to prevent creating impossible tasks.

1. **Never create tasks for code you haven't verified exists**
   - ❌ BAD: "T001: Update the UserService.create_user method"
   - ✅ GOOD: First search for UserService, then create task based on what exists
   - Use Glob to find files before creating file modification tasks

2. **Cite plan.md when deriving tasks**
   - Each task should trace to plan.md section
   - Example: "T001 implements data model from plan.md:45-60"
   - Don't create tasks not mentioned in the plan

3. **Verify test file locations before creating test tasks**
   - Before task "Add test_user_service.py", check if tests/ directory exists
   - Use Glob to find test patterns: `**/test_*.py` or `**/*_test.py`
   - Don't assume test structure matches your expectations

4. **Quote acceptance criteria from spec.md exactly**
   - Copy user story acceptance criteria verbatim to task AC
   - Don't paraphrase or add unstated criteria
   - If criteria missing, flag: "[NEEDS: Acceptance criteria for...]"

5. **Verify dependencies between tasks**
   - Before marking T002 depends on T001, confirm T001 creates what T002 needs
   - Don't create circular dependencies
   - Check plan.md for intended sequence

**Why this matters**: Hallucinated tasks create impossible work. Tasks referencing non-existent code waste implementation time. Clear, verified tasks reduce implementation errors by 50-60%.

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
## UNIFIED TASK GENERATION SCRIPT

**Execute complete task generation workflow in one unified script:**

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ERROR TRAP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

on_error() {
  echo "⚠️  Error in /tasks. Cleaning up."
  exit 1
}
trap on_error ERR

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TOOL PREFLIGHT CHECKS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ Missing required tool: $1"
    echo ""
    case "$1" in
      git)
        echo "Install: https://git-scm.com/downloads"
        ;;
      jq)
        echo "Install: brew install jq (macOS) or apt install jq (Linux)"
        echo "         https://stedolan.github.io/jq/download/"
        ;;
      *)
        echo "Check documentation for installation"
        ;;
    esac
    exit 1
  }
}

need git
need jq

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SETUP - Deterministic repo root
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cd "$(git rev-parse --show-toplevel)"

# Get feature from argument or current branch
if [ -n "$ARGUMENTS" ]; then
  SLUG="$ARGUMENTS"
else
  SLUG=$(git branch --show-current)
fi

FEATURE_DIR="specs/$SLUG"
PLAN_FILE="$FEATURE_DIR/plan.md"
SPEC_FILE="$FEATURE_DIR/spec.md"
TASKS_FILE="$FEATURE_DIR/tasks.md"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# VALIDATE FEATURE EXISTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ ! -d "$FEATURE_DIR" ]; then
  echo "❌ Feature not found: $FEATURE_DIR"
  echo ""
  echo "Fix: Run /spec to create feature first"
  echo "     Or provide correct feature slug: /tasks <slug>"
  exit 1
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# VALIDATE REQUIRED FILES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ ! -f "$PLAN_FILE" ]; then
  echo "❌ Missing: $PLAN_FILE"
  echo ""
  echo "Fix: Run /plan first to generate implementation plan"
  exit 1
fi

if [ ! -f "$SPEC_FILE" ]; then
  echo "❌ Missing: $SPEC_FILE"
  echo ""
  echo "Fix: Run /spec first to create feature specification"
  exit 1
fi

echo "Feature: $SLUG"
echo "Plan: $PLAN_FILE"
echo "Spec: $SPEC_FILE"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LOAD DESIGN ARTIFACTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Optional files
DATA_MODEL="$FEATURE_DIR/data-model.md"
CONTRACTS_DIR="$FEATURE_DIR/contracts"
RESEARCH="$FEATURE_DIR/research.md"
VISUALS="$FEATURE_DIR/visuals/README.md"
ERROR_LOG="$FEATURE_DIR/error-log.md"

# Extract sections from plan.md
echo "Loading design artifacts from plan.md..."

# Claude Code extracts key sections here:
# ARCHITECTURE=$(sed -n '/## \[ARCHITECTURE DECISIONS\]/,/## \[/p' "$PLAN_FILE" | head -n -1)
# EXISTING_REUSE=$(sed -n '/## \[EXISTING INFRASTRUCTURE - REUSE\]/,/## \[/p' "$PLAN_FILE" | head -n -1)
# NEW_CREATE=$(sed -n '/## \[NEW INFRASTRUCTURE - CREATE\]/,/## \[/p' "$PLAN_FILE" | head -n -1)
# SCHEMA=$(sed -n '/## \[SCHEMA\]/,/## \[/p' "$PLAN_FILE" | head -n -1)
# CI_CD_IMPACT=$(sed -n '/## \[CI\/CD IMPACT\]/,/## \[/p' "$PLAN_FILE" | head -n -1)
# DEPLOYMENT=$(sed -n '/## \[DEPLOYMENT ACCEPTANCE\]/,/## \[/p' "$PLAN_FILE" | head -n -1)

# Extract user stories from spec.md
# USER_STORIES=$(grep -E "^(As a|As an)" "$SPEC_FILE" | sed 's/\[P\([0-9]\)\]/@PRIORITY:\1/')

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CHECK FOR POLISHED UI DESIGNS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

POLISHED_SCREENS=$(find apps/web/mock/$SLUG -path "*/polished/page.tsx" 2>/dev/null || echo "")
if [ -n "$POLISHED_SCREENS" ]; then
  HAS_UI_DESIGN=true
  UI_SCREEN_COUNT=$(echo "$POLISHED_SCREENS" | wc -l)
  echo "✅ Found $UI_SCREEN_COUNT polished UI designs"
else
  HAS_UI_DESIGN=false
  echo "ℹ️  No polished UI designs found (backend/API feature)"
fi

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SCAN CODEBASE FOR REUSE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "🔍 Scanning codebase for reuse patterns..."

# Scan for models
EXISTING_MODELS=$(find . -path "*/models/*.py" -o -path "*/models/*.ts" 2>/dev/null | head -20 || echo "")

# Scan for services
EXISTING_SERVICES=$(find . -path "*/services/*.py" -o -path "*/services/*.ts" 2>/dev/null | head -20 || echo "")

# Scan for endpoints
EXISTING_ENDPOINTS=$(find . -path "*/routes/*.py" -o -path "*/api/*.ts" 2>/dev/null | head -20 || echo "")

# Scan for UI components
EXISTING_COMPONENTS=$(find . -path "*/components/*.tsx" -o -path "*/components/*.jsx" 2>/dev/null | head -20 || echo "")

echo "✅ Codebase scan complete"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TASK GENERATION (Claude Code performs here)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Claude Code generates tasks.md based on:
# 1. Analyze User Stories (from spec.md)
#    - Extract user stories with priorities (P1, P2, P3...)
#    - Map entities, endpoints, UI components → stories they serve
#    - Identify story dependencies
#    - Generate independent test criteria per story
#
# 2. Map Components to Stories
#    - From data-model.md: Map entities → user stories
#    - From contracts/: Map endpoints → user stories
#    - From plan.md: Shared infrastructure → Setup phase
#
# 3. Generate Dependency Graph
#    - Story completion order
#    - Identify blocking prerequisites
#
# 4. Identify Parallel Opportunities
#    - Tasks that can run in parallel (different files, no deps)
#
# 5. Define MVP Strategy
#    - MVP Scope: Phase 3 (US1) only
#    - Incremental delivery: US1 → staging → US2 → US3
#
# Output structure:
# - [CODEBASE REUSE ANALYSIS]
# - [DEPENDENCY GRAPH]
# - [PARALLEL EXECUTION OPPORTUNITIES]
# - [IMPLEMENTATION STRATEGY]
# - Phase 1: Setup
# - Phase 2: Foundational (blocking prerequisites)
# - Phase 3+: User Stories (one per story)
# - Phase N: Polish & Cross-Cutting Concerns
# - [TEST GUARDRAILS] (if tests requested)

echo "Generating tasks.md..."
echo ""

# Claude Code writes tasks.md with format:
# - [ ] [TID] [P?] [Story?] Description with file path
#   - REUSE: ExistingService (path/to/service.py)
#   - Pattern: path/to/similar/file.py
#   - From: design-doc.md section

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# UPDATE NOTES.md
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Count tasks
TOTAL_TASKS=$(grep -c "^- \[ \] T[0-9]" "$TASKS_FILE" 2>/dev/null || echo 0)
SETUP_TASKS=$(grep -c "^- \[ \] T[0-9].*Phase 1" "$TASKS_FILE" 2>/dev/null || echo 0)
STORY_TASKS=$(grep -c "\[US[0-9]\]" "$TASKS_FILE" 2>/dev/null || echo 0)
PARALLEL_TASKS=$(grep -c "\[P\]" "$TASKS_FILE" 2>/dev/null || echo 0)

# Add Phase 2 checkpoint
cat >> "$FEATURE_DIR/NOTES.md" <<EOF

## Phase 2: Tasks ($(date '+%Y-%m-%d %H:%M' 2>/dev/null || date))

**Summary**:
- Total tasks: $TOTAL_TASKS
- User story tasks: $STORY_TASKS
- Parallel opportunities: $PARALLEL_TASKS
- Setup tasks: $SETUP_TASKS
- Task file: specs/$SLUG/tasks.md

**Checkpoint**:
- ✅ Tasks generated: $TOTAL_TASKS
- ✅ User story organization: Complete
- ✅ Dependency graph: Created
- ✅ MVP strategy: Defined (US1 only)
- 📋 Ready for: /validate

EOF

echo "✅ Updated NOTES.md with Phase 2 checkpoint"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GIT COMMIT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

git add specs/${SLUG}/tasks.md specs/${SLUG}/NOTES.md

git commit -m "$(cat <<COMMITMSG
design:tasks: generate $TOTAL_TASKS concrete tasks organized by user story

- $TOTAL_TASKS tasks (setup, foundational, US1-USN, polish)
- $STORY_TASKS user story tasks
- $PARALLEL_TASKS parallel opportunities
- REUSE markers for existing modules
- Dependency graph + parallel opportunities
- MVP strategy (US1 only for first release)

Artifacts:
- specs/$SLUG/tasks.md ($TOTAL_TASKS tasks)
- specs/$SLUG/NOTES.md (Phase 2 checkpoint)

Next: /validate

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
COMMITMSG
)"

# Verify commit succeeded
COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""
echo "✅ Tasks committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# RETURN - Summary and next steps
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ TASKS GENERATED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "File: specs/$SLUG/tasks.md"
echo ""
echo "📊 Summary:"
echo "- Total: $TOTAL_TASKS tasks"
echo "- User story tasks: $STORY_TASKS (organized by priority)"
echo "- Parallel opportunities: $PARALLEL_TASKS tasks marked [P]"
echo "- Setup tasks: $SETUP_TASKS"

if [ "$HAS_UI_DESIGN" = true ]; then
  echo "- UI promotion: $UI_SCREEN_COUNT screens to promote"
fi

echo ""
echo "📋 Task organization:"
echo "- Phase 1 (Setup): Infrastructure and dependencies"
echo "- Phase 2 (Foundational): Blocking prerequisites"
echo "- Phase 3+ (User Stories): Story-specific implementation"
echo "- Phase N (Polish): Cross-cutting concerns"
echo ""
echo "NOTES.md: Phase 2 checkpoint added"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 NEXT: /validate"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "/validate will:"
echo "1. Read tasks.md (task breakdown)"
echo "2. Scan codebase for patterns (anti-duplication check)"
echo "3. Validate architecture decisions (no conflicts)"
echo "4. Identify risks (complexity, dependencies)"
echo "5. Generate implementation hints (concrete examples)"
echo "6. Update error-log.md (potential issues)"
echo ""
echo "Output: specs/$SLUG/analysis-report.md"
echo ""
echo "Duration: ~5 minutes"
```

## TASK ORGANIZATION RULES

**Format (GitHub-compatible checkboxes):**
```
- [ ] [TID] [P?] [Story?] Description with file path
  - REUSE: ExistingService (path/to/service.py)
  - Pattern: path/to/similar/file.py
  - From: design-doc.md section
```

**Components:**
1. **Checkbox**: `- [ ]` (GitHub-trackable)
2. **Task ID**: Sequential (T001, T002, T003...)
3. **[P] marker**: Parallelizable (different files, no blocking deps)
4. **[Story] label**: [US1], [US2], [US3] for user story tasks
5. **Description**: Concrete action + exact file path
6. **REUSE**: What existing code to use
7. **Pattern**: Similar file to follow
8. **From**: Which design doc section

**Examples:**
- ✅ `- [ ] T001 Create project structure per implementation plan`
- ✅ `- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py`
  - REUSE: JWTService (src/services/jwt_service.py)
  - Pattern: src/middleware/rate_limit.py
- ✅ `- [ ] T012 [P] [US1] Create User model in api/src/models/user.py`
  - Fields: id (UUID), email (unique), password_hash, created_at
  - REUSE: BaseModel (api/src/models/base.py)
  - Pattern: api/src/models/notification.py
  - From: data-model.md User entity

**NO generic placeholders:**
- ❌ `Create [Entity] model in src/models/[entity].py`
- ✅ `Create Message model in api/src/modules/chat/models/message.py`

## OUTPUT STRUCTURE (tasks.md)

### Header Sections

```markdown
# Tasks: [Feature Name]

## [CODEBASE REUSE ANALYSIS]
Scanned: api/src/**/*.py, apps/**/*.tsx

[EXISTING - REUSE]
- ✅ DatabaseService (api/src/services/database_service.py)
- ✅ BaseModel (api/src/models/base.py)

[NEW - CREATE]
- 🆕 MessageService (no existing pattern)

## [DEPENDENCY GRAPH]
Story completion order:
1. Phase 2: Foundational (blocks all stories)
2. Phase 3: US1 [P1] - User registration (independent)
3. Phase 4: US2 [P2] - User login (depends on US1 User model)

## [PARALLEL EXECUTION OPPORTUNITIES]
- US1: T010, T011, T012 (different files, no dependencies)
- US2: T020, T021 (after US1 models created)

## [IMPLEMENTATION STRATEGY]
**MVP Scope**: Phase 3 (US1) only
**Incremental delivery**: US1 → staging validation → US2 → US3
**Testing approach**: [TDD required|Optional - integration only|E2E only]
```

### Phase 1: Setup

```markdown
## Phase 1: Setup

- [ ] T001 Create project structure per plan.md tech stack
  - Files: src/, tests/, config/
  - Pattern: existing-feature/ structure
  - From: plan.md [PROJECT STRUCTURE]

- [ ] T002 [P] Install dependencies from plan.md
  - Files: package.json, requirements.txt
  - Libraries: [list from plan.md]
  - From: plan.md [ARCHITECTURE DECISIONS]
```

### Phase 2: Foundational

```markdown
## Phase 2: Foundational (blocking prerequisites)

**Goal**: Infrastructure that blocks all user stories

- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py
  - REUSE: JWTService (src/services/jwt_service.py)
  - Pattern: src/middleware/rate_limit.py
  - From: plan.md [EXISTING INFRASTRUCTURE - REUSE]

- [ ] T006 [P] Create database connection pool in src/db/connection.py
  - REUSE: DatabaseService (src/services/database_service.py)
  - Pattern: src/db/postgres_pool.py
  - From: plan.md [SCHEMA]
```

### Phase 3+: User Stories (one per story)

```markdown
## Phase 3: User Story 1 [P1] - User can register account

**Story Goal**: New users create accounts with email/password

**Independent Test Criteria**:
- [ ] User submits valid registration → account created in DB
- [ ] User submits duplicate email → 400 error with message
- [ ] Registration confirmed via email link → account activated

### Setup (if story-specific infrastructure needed)

- [ ] T010 [P] [US1] Create User table migration in api/alembic/versions/xxx_create_user.py
  - Fields: id (UUID PK), email (unique), password_hash, created_at
  - Indexes: email (unique), created_at
  - Pattern: api/alembic/versions/existing_migration.py
  - From: plan.md [SCHEMA]

### Tests (if explicitly requested in spec.md)

- [ ] T011 [P] [US1] Write test: User model validates email format
  - File: tests/unit/models/test_user.py
  - Given-When-Then structure
  - Pattern: tests/unit/models/test_notification.py
  - Coverage: ≥80% (new code must be 100%)

- [ ] T012 [P] [US1] Write test: UserService creates account with valid data
  - File: tests/integration/services/test_user_service.py
  - Real database (test DB)
  - Pattern: tests/integration/services/test_notification_service.py

### Implementation

- [ ] T015 [US1] Create User model in api/src/models/user.py
  - Fields: id, email, password_hash, created_at
  - Methods: validate_email(), set_password()
  - REUSE: BaseModel (api/src/models/base.py)
  - Pattern: api/src/models/notification.py
  - From: data-model.md User entity

- [ ] T016 [US1] Create UserService in api/src/services/user_service.py
  - Methods: create_user(), validate_email(), hash_password()
  - REUSE: DatabaseService (api/src/services/database_service.py)
  - Pattern: api/src/services/notification_service.py
  - From: plan.md [NEW INFRASTRUCTURE - CREATE]

- [ ] T017 [US1] Create POST /api/users endpoint in api/src/routes/users.py
  - Request: { email, password }
  - Response: { user_id, email, created_at }
  - Validation: Email format, password strength
  - REUSE: AuthMiddleware (src/middleware/auth.py)
  - Pattern: api/src/routes/notifications.py
  - From: contracts/user-registration.yaml

### Integration

- [ ] T020 [US1] Write E2E test for registration flow
  - File: tests/e2e/test_user_registration.spec.ts
  - Test: Complete user journey (form → API → DB → email)
  - Real data: Actual API, real database
  - Pattern: tests/e2e/test_notification_flow.spec.ts
  - Coverage: ≥90% critical path
```

### Phase N: Polish & Cross-Cutting Concerns

```markdown
## Phase N: Polish & Cross-Cutting Concerns

### Error Handling & Resilience

- [ ] T080 Add global error handler in src/middleware/error_handler.py
  - Returns 500 with error_id for tracking
  - Logs to Sentry + error-log.md
  - REUSE: ErrorTracker (src/services/error_tracker.py)
  - Pattern: src/middleware/request_logger.py

- [ ] T081 [P] Add retry logic with exponential backoff
  - Decorator: @retry(max_attempts=3, backoff_factor=2)
  - Pattern: src/utils/retry_decorator.py
  - From: plan.md [DEPLOYMENT ACCEPTANCE]

### Deployment Preparation

- [ ] T085 Document rollback procedure in NOTES.md
  - Command: Standard 3-command rollback (see docs/ROLLBACK_RUNBOOK.md)
  - Feature flag: Kill switch (NEXT_PUBLIC_FEATURE_ENABLED=0)
  - Database: Reversible migration (downgrade script)
  - From: plan.md [DEPLOYMENT ACCEPTANCE]

- [ ] T086 [P] Add health check endpoint in src/routes/health.py
  - Endpoint: /api/health/[feature]
  - Check: Database connection, service available
  - Return: { status: "ok", dependencies: {...} }
  - Pattern: src/routes/health_checks.py
  - From: plan.md [CI/CD IMPACT]

- [ ] T087 [P] Add smoke tests to CI pipeline
  - File: tests/smoke/test_[feature].py
  - Tests: Critical path only (<90s total)
  - Pattern: tests/smoke/test_existing_feature.py
  - From: plan.md [CI/CD IMPACT]

### UI Promotion (if HAS_UI_DESIGN = true)

- [ ] T090 [US1] Promote polished mockup to production in apps/app/[slug]/page.tsx
  - **Reference mockup**: apps/web/mock/[slug]/polished/page.tsx
  - **Design**: Copy layout, components, tokens, a11y from mockup
  - **Backend**: Wire to API endpoints (see contracts/*.yaml)
  - **State**: Add loading, success, error states (React Query)
  - **Analytics**: Track events from design/analytics.md
  - **Validation**: Client-side + server-side error handling
  - Pattern: apps/app/existing-feature/page.tsx
  - From: spec.md User Scenarios

- [ ] T091 [US1] Add analytics instrumentation
  - **Events**: From design/analytics.md (page_view, action, completed, error)
  - **PostHog**: posthog.capture(event, properties)
  - **Logs**: logger.info({ event, ...properties, timestamp })
  - **DB**: POST /api/metrics ({ feature, variant, outcome, value })
  - Pattern: Triple instrumentation for HEART metrics

- [ ] T092 [US1] Add feature flag wrapper
  - **Flag**: NEXT_PUBLIC_${SLUG^^}_ENABLED
  - **Component**: apps/app/[slug]/layout.tsx
  - **Logic**: Hash-based rollout (0% → 5% → 25% → 50% → 100%)
  - **Override**: Team always enabled (TEAM_USER_IDS)
  - From: plan.md [CI/CD IMPACT]
```

## TEST GUARDRAILS (if tests requested)

**Only include this section if spec.md requests tests or TDD approach**

```markdown
## [TEST GUARDRAILS]

**Speed Requirements:**
- Unit tests: <2s each
- Integration tests: <10s each
- E2E tests: <30s each
- Full suite: <6 min total

**Coverage Requirements:**
- New code: 100% coverage (no untested lines in new features)
- Unit tests: ≥80% line coverage
- Integration tests: ≥60% line coverage
- E2E tests: ≥90% critical path coverage
- Modified code: Coverage cannot decrease

**Measurement:**
- Python: `pytest --cov=api --cov-report=term-missing`
- TypeScript: `jest --coverage`
- E2E: Playwright trace for failed scenarios

**Quality Gates:**
- All tests must pass before merge
- Coverage thresholds enforced in CI
- No skipped tests without JIRA ticket

**Clarity Requirements:**
- One behavior per test
- Descriptive names: `test_anonymous_user_cannot_save_message_without_auth()`
- Given-When-Then structure in test body

**Anti-Patterns:**
- ❌ NO UI snapshots (brittle, break on CSS changes)
- ❌ NO "prop-mirror" tests (test behavior, not implementation)
- ✅ USE role/text queries (accessible, resilient)
- ✅ USE data-testid for dynamic content only

**Examples:**
```typescript
// ❌ Bad: Prop-mirror test (tests implementation)
expect(component.props.isOpen).toBe(true)

// ✅ Good: Behavior test (tests user outcome)
expect(screen.getByRole('dialog')).toBeVisible()

// ❌ Bad: Snapshot (fragile)
expect(wrapper).toMatchSnapshot()

// ✅ Good: Semantic assertion (resilient)
expect(screen.getByText('Message sent')).toBeInTheDocument()
```

**Reference**: `.spec-flow/templates/test-patterns.md` for copy-paste templates
```

</instructions>
