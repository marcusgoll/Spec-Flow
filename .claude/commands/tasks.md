---
description: Generate concrete TDD tasks from design artifacts (no generic placeholders)
---

Create tasks from: specs/$SLUG/plan.md

## LOAD FEATURE

**Get feature from argument or current branch:**

```bash
if [ -n "$ARGUMENTS" ]; then
  SLUG="$ARGUMENTS"
else
  SLUG=$(git branch --show-current)
fi

FEATURE_DIR="specs/$SLUG"
PLAN_FILE="$FEATURE_DIR/plan.md"
```

**Validate feature exists:**
```bash
if [ ! -d "$FEATURE_DIR" ]; then
  echo "❌ Feature not found: $FEATURE_DIR"
  exit 1
fi
```

**Validate plan exists:**
```bash
if [ ! -f "$PLAN_FILE" ]; then
  echo "❌ Missing: $PLAN_FILE"
  echo "Run /plan first"
  exit 1
fi
```

**Validate plan.md has required sections:**
```bash
REQUIRED_SECTIONS=(
  "[ARCHITECTURE DECISIONS]"
  "[EXISTING INFRASTRUCTURE - REUSE]"
  "[NEW INFRASTRUCTURE - CREATE]"
)

MISSING_SECTIONS=()
for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -q "$section" "$PLAN_FILE"; then
    MISSING_SECTIONS+=("$section")
  fi
done

if [ ${#MISSING_SECTIONS[@]} -gt 0 ]; then
  echo "⚠️  plan.md missing sections:"
  for section in "${MISSING_SECTIONS[@]}"; do
    echo "    - $section"
  done
  echo ""
  echo "Regenerate: /plan $SLUG"
  exit 1
fi
```

## MENTAL MODEL

**Workflow**: spec-flow → clarify → plan → tasks → analyze → implement → optimize → debug → preview → phase-1-ship → validate-staging → phase-2-ship

**State machine:**
- Load design artifacts → Extract concrete details → Generate tasks → Suggest next

**Auto-suggest:**
- When complete → `/analyze`

## ANALYZE DESIGN ARTIFACTS

**Load from specs/$SLUG/:**

```bash
PLAN_FILE="$FEATURE_DIR/plan.md"
CONTRACTS_DIR="$FEATURE_DIR/contracts"
ERROR_LOG="$FEATURE_DIR/error-log.md"
VISUALS="$FEATURE_DIR/visuals/README.md"

# Extract sections from consolidated plan.md
ARCHITECTURE=$(sed -n '/## \[ARCHITECTURE DECISIONS\]/,/## \[/p' "$PLAN_FILE" | head -n -1)
EXISTING_REUSE=$(sed -n '/## \[EXISTING INFRASTRUCTURE - REUSE\]/,/## \[/p' "$PLAN_FILE" | head -n -1)
NEW_CREATE=$(sed -n '/## \[NEW INFRASTRUCTURE - CREATE\]/,/## \[/p' "$PLAN_FILE" | head -n -1)
SCHEMA=$(sed -n '/## \[SCHEMA\]/,/## \[/p' "$PLAN_FILE" | head -n -1)
CI_CD_IMPACT=$(sed -n '/## \[CI\/CD IMPACT\]/,/## \[/p' "$PLAN_FILE" | head -n -1)
DEPLOYMENT=$(sed -n '/## \[DEPLOYMENT ACCEPTANCE\]/,/## \[/p' "$PLAN_FILE" | head -n -1)

# Read contracts (if exist)
if [ -d "$CONTRACTS_DIR" ]; then
  API_CONTRACTS=$(find "$CONTRACTS_DIR" -name "*.yaml" -o -name "*.yml")
fi

# Check for visual specs (UI features)
if [ -f "$VISUALS" ]; then
  HAS_UX_SPECS=true
fi
```

**Check if UI design was completed:**

```bash
# Check for polished designs from /design-polish
POLISHED_SCREENS=$(find apps/web/mock/$SLUG -path "*/polished/page.tsx" 2>/dev/null)

if [ -n "$POLISHED_SCREENS" ]; then
  HAS_UI_DESIGN=true
  UI_SCREEN_COUNT=$(echo "$POLISHED_SCREENS" | wc -l)
  echo "✅ UI design found: $UI_SCREEN_COUNT polished screen(s)"
else
  HAS_UI_DESIGN=false
  echo "ℹ️  No UI design (backend-only feature)"
fi
```

## VALIDATE TEMPLATES

**Check test pattern templates:**

```bash
TEST_PATTERNS=".spec-flow/templates/test-patterns.md"

if [ ! -f "$TEST_PATTERNS" ]; then
  echo "⚠️  Test patterns template not found: $TEST_PATTERNS"
  echo "Creating basic test patterns..."

  mkdir -p .spec-flow/templates

  cat > "$TEST_PATTERNS" <<'EOF'
# Test Patterns

## Unit Test Template (TypeScript)
\`\`\`typescript
describe('ComponentName', () => {
  it('should [expected behavior] when [condition]', () => {
    // Given
    const input = setupTestData();

    // When
    const result = functionUnderTest(input);

    // Then
    expect(result).toBe(expectedValue);
  });
});
\`\`\`

## Integration Test Template (Python)
\`\`\`python
def test_feature_behavior():
    # Given
    test_data = create_test_data()

    # When
    result = feature_function(test_data)

    # Then
    assert result.status == "success"
\`\`\`

## E2E Test Template (Playwright)
\`\`\`typescript
test('user completes [action]', async ({ page }) => {
  // Given: User on page
  await page.goto('/feature');

  // When: User performs action
  await page.click('[data-testid="submit"]');

  // Then: Expected outcome
  await expect(page.getByText('Success')).toBeVisible();
});
\`\`\`
EOF

  echo "  ✅ Created basic test patterns"
fi
```

## GENERATE CONCRETE TASKS

**Concrete (NOT generic):**
- ❌ `T011 [P] Create [Entity] model in src/models/[entity].py`
- ✅ `T011 [P] Create Message model in api/src/modules/chat/models/message.py`

**Each task includes:**
1. Concrete file path
2. Exact fields/methods/signatures
3. REUSE markers (what existing code to use)
4. Pattern reference (similar file to follow)
5. From reference (which design doc)

**Example:**
```
T011 [P] Create Message model in `api/src/modules/chat/models/message.py`
- Fields: id (UUID), channel_id (FK), user_id (FK), content (str, max 4000), created_at
- Relationships: belongs_to Channel, belongs_to User
- REUSE: Base model (api/src/models/base.py)
- Pattern: api/src/models/notification.py
- From: data-model.md Message entity
```

## GENERATE UI PROMOTION TASKS (if polished designs exist)

**If HAS_UI_DESIGN = true:**

```bash
if [ "$HAS_UI_DESIGN" = true ]; then
  echo ""
  echo "Generating UI promotion tasks..."

  # Count polished screens
  SCREEN_COUNT=$(echo "$POLISHED_SCREENS" | wc -l)

  cat >> "$FEATURE_DIR/tasks.md" <<EOF

---

## Phase 3.3: UI Promotion (from polished prototypes)

**Context**: Polished screens exist in apps/web/mock/$SLUG/
**Goal**: Promote to production routes in apps/app/

**IMPORTANT**: Polished designs are REFERENCE MOCKUPS showing final design with:
- ✅ Brand tokens applied (colors, fonts, shadows)
- ✅ Design system components (from ui-inventory.md)
- ✅ Accessibility validated (WCAG AA)
- ❌ Mock data only (NOT wired to backend)
- ❌ No analytics instrumentation
- ❌ No feature flags

**Implementation tasks**:
1. Build REAL backend integration (API calls, state management)
2. Use polished mockup as DESIGN REFERENCE (copy layout, tokens, components)
3. Add real data handling (loading, error states, validation)
4. Add analytics instrumentation (PostHog + logs + DB)
5. Add feature flags (A/B testing)
6. Test with real data (E2E tests with actual API)

EOF

  # Generate tasks per screen
  TASK_NUM=1

  for polished_file in $POLISHED_SCREENS; do
    SCREEN=$(echo "$polished_file" | sed 's|.*/\([^/]*\)/polished/.*|\1|')

    cat >> "$FEATURE_DIR/tasks.md" <<EOF
### Screen: $SCREEN

T$(printf "%03d" $TASK_NUM) [P] Create production route with real API integration
- **File**: apps/app/$SLUG/$SCREEN/page.tsx
- **Reference mockup**: apps/web/mock/$SLUG/$SCREEN/polished/page.tsx
- **Design**: Copy layout, components, tokens, a11y from polished mockup
- **Backend**: Wire to API endpoints (see contracts/*.yaml)
- **State**: Add loading, success, error states (React Query or SWR)
- **Analytics**: Track events from design/analytics.md
- **Validation**: Client-side + server-side error handling
- **Pattern**: apps/app/existing-feature/*.tsx (similar integration)
- **From**: spec.md User Scenarios

T$(printf "%03d" $((TASK_NUM + 1))) [RED] Write E2E test for $SCREEN user flow
- **File**: tests/e2e/$SLUG/$SCREEN.spec.ts
- **Test**: Complete user journey (load → interact → success)
- **Real data**: Use real API, real database, real file processing
- **NOT mocked**: API responses, user authentication
- **Pattern**: tests/e2e/existing-feature/*.spec.ts
- **From**: spec.md User Scenarios

T$(printf "%03d" $((TASK_NUM + 2))) [GREEN→T$(printf "%03d" $((TASK_NUM + 1)))] Implement API integration
- **File**: apps/app/$SLUG/$SCREEN/page.tsx
- **Add**: File validation (client-side + server-side)
- **Add**: Upload progress tracking (0-100%)
- **Add**: Error handling (network, validation, server errors)
- **Add**: Success redirect with result ID
- **Use**: React Query useMutation for API calls
- **Pattern**: apps/app/file-upload/handler.tsx

T$(printf "%03d" $((TASK_NUM + 3))) [P] Add analytics instrumentation
- **Events**: From design/analytics.md (page_view, action, completed, error)
- **PostHog**: posthog.capture(event, properties)
- **Logs**: logger.info({ event, ...properties, timestamp })
- **DB**: POST /api/metrics ({ feature, variant, outcome, value })
- **Pattern**: Triple instrumentation for HEART metrics

T$(printf "%03d" $((TASK_NUM + 4))) [P] Add feature flag wrapper
- **Flag**: NEXT_PUBLIC_${SLUG^^}_ENABLED
- **Component**: apps/app/$SLUG/layout.tsx
- **Logic**: Hash-based rollout (0% → 5% → 25% → 50% → 100%)
- **Override**: Team always enabled (TEAM_USER_IDS)
- **From**: CI/CD IMPACT section in plan.md

EOF

    TASK_NUM=$((TASK_NUM + 5))
  done

  echo "  ✅ Added $((SCREEN_COUNT * 5)) UI promotion tasks"
fi
```

## OUTPUT TO tasks.md

**Header:**
```markdown
# Tasks: [Feature Name]

[CODEBASE REUSE ANALYSIS]
Scanned: api/src/**/*.py, apps/**/*.tsx

[EXISTING - REUSE]
- ✅ DatabaseService (api/src/services/database_service.py)

[NEW - CREATE]
- 🆕 MessageService (no existing)
```

**Tasks (25-35 max) with TDD Phases:**
- Phase 3.0: Database Setup (T001-T003) - if schema changes exist
- Phase 3.1: Setup (T004-T008)
- Phase 3.2: RED - Write Failing Tests (T009-T018)
- Phase 3.3: GREEN - Minimal Implementation (T019-T026)
- Phase 3.4: REFACTOR - Clean Up (T027-T030)
- Phase 3.5: Integration & Testing (T031-T035)
- Phase 3.6: Error Handling & Resilience (T036-T040)
- Phase 3.7: Deployment Preparation (T041-T043)
- Phase 3.8: UI Promotion (if polished designs exist)

**TDD Structure (per feature/behavior):**
```
T009 [RED] Write failing test: Message validates content length
T019 [GREEN→T009] Implement Message.validate_content() to pass T009
T027 [REFACTOR] Extract validation to MessageValidator (tests stay green)
```

**Ordering:**
- RED → GREEN → REFACTOR loop per behavior
- Dependencies: Migrations → Models → Services → Endpoints → UI
- [P] = Parallel (different files, no dependencies)
- [DEPENDS: TNN] = Must wait for task TNN to complete
- Each task tagged with [RED], [GREEN→TNN], or [REFACTOR]

## Phase 3.0: Database Setup (if migration-plan.md exists)

```markdown
T001 [P] Generate database migration
- **Tool**: Alembic (Python) or Prisma (TypeScript)
- **Fields**: From plan.md [SCHEMA] section
- **Command**: alembic revision --autogenerate -m "Add [entity] table"
- **Test**: Migration up/down works (alembic upgrade head; alembic downgrade -1)
- **From**: migration-plan.md

T002 [P] Add database indexes for performance
- **Indexes**: From plan.md [PERFORMANCE TARGETS] section
- **Verify**: EXPLAIN ANALYZE shows index usage
- **Pattern**: api/alembic/versions/existing_migration.py

T003 [P] Add Row Level Security policies
- **File**: api/sql/policies/[entity]_rls.sql
- **Rules**: From plan.md [SECURITY] section
- **Pattern**: api/sql/policies/existing_rls.sql
```

## Phase 3.6: Error Handling & Resilience

```markdown
T036 [RED] Write test: API returns 400 for invalid input
T037 [GREEN→T036] Add validation middleware
T038 [REFACTOR] Extract validation to reusable decorator

T039 [RED] Write test: API returns 500 with error_id for unexpected failures
T040 [GREEN→T039] Add global error handler with error tracking
T041 [REFACTOR] Create ErrorTracker service (logs to Sentry + DB)

T042 [P] Add retry logic with exponential backoff
- **Pattern**: api/src/utils/retry_decorator.py
- **From**: plan.md [DEPLOYMENT ACCEPTANCE] section
```

## Phase 3.7: Deployment Preparation

```markdown
T043 [P] Document rollback procedure in NOTES.md
- **Command**: Standard 3-command rollback (see docs/ROLLBACK_RUNBOOK.md)
- **Feature flag**: Kill switch (NEXT_PUBLIC_FEATURE_ENABLED=0)
- **Database**: Reversible migration (downgrade script)
- **From**: plan.md [DEPLOYMENT ACCEPTANCE]

T044 [P] Add health check endpoint for feature
- **Endpoint**: /api/health/[feature]
- **Check**: Database connection, service available
- **Return**: { status: "ok", dependencies: {...} }
- **From**: plan.md [CI/CD IMPACT] smoke tests

T045 [P] Add smoke tests to CI pipeline
- **File**: tests/smoke/test_[feature].py
- **Tests**: Critical path only (<90s total)
- **From**: plan.md [CI/CD IMPACT]
```

## TEST GUARDRAILS

**Speed Requirements:**
- Unit tests: <2s each
- Integration tests: <10s each
- Full suite: <6 min total

**Coverage Requirements:**
- Unit tests: ≥80% line coverage (models, services, utils)
- Integration tests: ≥60% line coverage (API endpoints, database)
- E2E tests: ≥90% critical path coverage (user flows)
- New code: 100% coverage (no untested lines in new features)
- Modified code: Coverage cannot decrease
- Critical paths: Must have E2E test

**Measurement:**
- Python: `pytest --cov=api --cov-report=term-missing`
- TypeScript: `jest --coverage`
- E2E: Playwright trace for failed scenarios

**Quality gates:**
- All tests must pass before merge
- Coverage thresholds enforced in CI
- No skipped tests without JIRA ticket

**Clarity Requirements:**
- One behavior per test
- Descriptive names: `test_anonymous_user_cannot_save_message_without_auth()`
- Given-When-Then structure in test body

**Anti-Fragility:**
- ❌ NO UI snapshots (brittle, break on CSS changes)
- ✅ USE role/text queries (accessible, resilient)
- ✅ USE data-testid for dynamic content only
- ❌ NO "prop-mirror" tests (test behavior, not implementation)

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

**Reference:** `.spec-flow/templates/test-patterns.md` for copy-paste templates

## GIT COMMIT

```bash
git add specs/${FEATURE}/tasks.md
git commit -m "design:tasks: generate N concrete TDD tasks

- N tasks (setup, tests, impl, integration, polish)
- REUSE markers for existing modules
- TDD ordering enforced

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

## UPDATE NOTES.md

After generating tasks.md, update NOTES.md with Phase 2 checkpoint and summary:

```bash
# Source the template
source .spec-flow/templates/notes-update-template.sh

# Count tasks by type
TOTAL_TASKS=$(grep -c "^T[0-9]" "$FEATURE_DIR/tasks.md")
RED_TASKS=$(grep -c "\[RED\]" "$FEATURE_DIR/tasks.md")
GREEN_TASKS=$(grep -c "\[GREEN\]" "$FEATURE_DIR/tasks.md")
PROMOTION_TASKS=$(grep -c "\[P\]" "$FEATURE_DIR/tasks.md")
SETUP_TASKS=$(grep -c "setup\|migration\|config" "$FEATURE_DIR/tasks.md")

# Add Phase 2 Summary
update_notes_summary "$FEATURE_DIR" "2" \
  "Total tasks: $TOTAL_TASKS" \
  "TDD trios: $RED_TASKS behaviors (RED → GREEN → REFACTOR)" \
  "UI promotion tasks: $PROMOTION_TASKS" \
  "Setup/config tasks: $SETUP_TASKS" \
  "Task file: specs/$SLUG/tasks.md"

# Add Phase 2 checkpoint
update_notes_checkpoint "$FEATURE_DIR" "2" "Tasks" \
  "Tasks generated: $TOTAL_TASKS" \
  "TDD coverage: $RED_TASKS test-first behaviors" \
  "Ready for: /analyze"

update_notes_timestamp "$FEATURE_DIR"
```

## AUTO-COMPACTION

In `/flow` mode, auto-compaction runs after task generation:
- ✅ Preserve: Task breakdown, priorities, error log, reuse analysis
- ❌ Remove: Verbose task descriptions, research details
- Strategy: Moderate (planning-to-implementation transition)

**Manual compact instruction (standalone mode):**
```bash
/compact "keep task breakdown, priorities, and error log"
```

**When to compact:**
- Auto: After `/tasks` in `/flow` mode
- Manual: If context >60k tokens before `/analyze`

## RETURN

Brief summary:
```
✅ Tasks generated: specs/$SLUG/tasks.md (N tasks)

📊 Summary:
- Total: N tasks (X setup, Y tests, Z impl, W integration)
- TDD trios: N behaviors (RED → GREEN → REFACTOR)
- Reuse: N existing modules
- UI tasks: N promotion tasks (if polished designs exist)
- Dependencies: Documented in task descriptions

NOTES.md: Phase 2 checkpoint added

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 NEXT: /analyze
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/analyze will:
1. Read tasks.md (task breakdown)
2. Scan codebase for patterns (anti-duplication check)
3. Validate architecture decisions (no conflicts)
4. Identify risks (complexity, dependencies)
5. Generate implementation hints (concrete examples)
6. Update error-log.md (potential issues)

Output: specs/$SLUG/artifacts/analysis-report.md

Duration: ~5 minutes
```
