---
description: Generate concrete TDD tasks from design artifacts (no generic placeholders)
---

Create tasks from: specs/$FEATURE/plan.md

## MENTAL MODEL

**Workflow**: spec-flow -> clarify -> plan -> tasks -> analyze -> implement -> optimize -> debug -> preview -> phase-1-ship -> validate-staging -> phase-2-ship

**State machine:**
- Load design artifacts  Extract concrete details  Generate tasks  Suggest next

**Auto-suggest:**
- When complete  `/analyze`

## ANALYZE DESIGN ARTIFACTS

Load from `specs/NNN-feature/`:
- **plan.md**  [EXISTING], [NEW], [ARCHITECTURE]
- **data-model.md**  entities, fields, relationships
- **contracts/*.yaml**  API endpoints, schemas
- **research.md**  decisions, patterns
- **visuals/README.md**  UX patterns (if applicable)

## GENERATE CONCRETE TASKS

**Concrete (NOT generic):**
-  `T011 [P] Create [Entity] model in src/models/[entity].py`
-  `T011 [P] Create Message model in api/src/modules/chat/models/message.py`

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

## OUTPUT TO tasks.md

**Header:**
```markdown
# Tasks: [Feature Name]

[CODEBASE REUSE ANALYSIS]
Scanned: api/src/**/*.py, apps/**/*.tsx

[EXISTING - REUSE]
-  DatabaseService (api/src/services/database_service.py)

[NEW - CREATE]
-  MessageService (no existing)
```

**Tasks (25-30 max) with TDD Phases:**
- Phase 3.1: Setup (T001-T005)
- Phase 3.2: RED - Write Failing Tests (T006-T015)
- Phase 3.3: GREEN - Minimal Implementation (T016-T023)
- Phase 3.4: REFACTOR - Clean Up (T024-T027)
- Phase 3.5: Integration & Polish (T028-T030)

**TDD Structure (per feature/behavior):**
```
T006 [RED] Write failing test: Message validates content length
T016 [GREENT006] Implement Message.validate_content() to pass T006
T024 [REFACTOR] Extract validation to MessageValidator (tests stay green)
```

**Ordering:**
- RED  GREEN  REFACTOR loop per behavior
- Dependencies: Models  Services  Endpoints
- [P] = Parallel (different files, no dependencies)
- Each task tagged with [RED], [GREENTNN], or [REFACTOR]

## TEST GUARDRAILS

**Speed Requirements:**
- Unit tests: <2s each
- Integration tests: <10s each
- Full suite: <6 min total

**Clarity Requirements:**
- One behavior per test
- Descriptive names: `test_anonymous_user_cannot_save_message_without_auth()`
- Given-When-Then structure in test body

**Anti-Fragility:**
-  NO UI snapshots (brittle, break on CSS changes)
-  USE role/text queries (accessible, resilient)
-  USE data-testid for dynamic content only
-  NO "prop-mirror" tests (test behavior, not implementation)

**Examples:**
```typescript
//  Bad: Prop-mirror test (tests implementation)
expect(component.props.isOpen).toBe(true)

//  Good: Behavior test (tests user outcome)
expect(screen.getByRole('dialog')).toBeVisible()

//  Bad: Snapshot (fragile)
expect(wrapper).toMatchSnapshot()

//  Good: Semantic assertion (resilient)
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

 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

## RETURN

Brief summary:
```
 Tasks generated: specs/NNN/tasks.md (N tasks)

 Summary:
- Breakdown: N setup, N tests, N impl, N integration, N polish
- Reuse: N existing modules/services
- Patterns: N reference implementations
- NOTES.md: Phase 2 checkpoint

 Next: /analyze
Optional: /compact planning (if needed before analysis)
```


