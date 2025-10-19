---
name: spec-compliance-validator
description: Before implementing tasks, verify they align with spec requirements to prevent scope creep and rework. Auto-trigger when starting implementation, creating endpoints, or building features. Check task description matches spec, endpoints match OpenAPI contract, and UI matches design mockups. Block implementation if requirements conflict with spec.
allowed-tools: Read, Grep
---

# Spec Compliance Validator: Prevent Scope Creep

**Purpose**: Verify task implementation aligns with spec requirements before coding to prevent drift, scope creep, and rework.

**Philosophy**: "The spec is the contract. Implement what's specified, not what you imagine."

---

## The Problem

**Implementations drift from spec:**

**Scenario 1: Extra Features (Scope Creep)**
```markdown
# Spec says:
"Display list of messages with content and timestamp"

# Developer implements:
- Message list ✓
- Message content ✓
- Timestamp ✓
- Reply button (NOT in spec)
- Edit button (NOT in spec)
- Delete button (NOT in spec)
- Real-time updates (NOT in spec)
```

**Result:** Over-engineered, untested features that weren't requested

**Scenario 2: Missing Requirements**
```markdown
# Spec says:
"Messages must support markdown formatting and @mentions"

# Developer implements:
- Plain text messages ✗ (spec requires markdown)
- No @mention support ✗ (spec requires @mentions)
```

**Result:** Incomplete feature that doesn't meet requirements

**Scenario 3: API Contract Violation**
```markdown
# OpenAPI contract says:
GET /api/v1/messages/{id}
Response: { id, content, user_id, created_at }

# Developer implements:
GET /api/v1/messages/{id}
Response: { message_id, text, author, timestamp }
```

**Result:** API contract violation breaks frontend integration

---

## The Solution: Pre-Implementation Validation

**Before coding, verify:**

1. **Task matches spec requirements** (no extra/missing features)
2. **API endpoints match OpenAPI contract** (exact schema)
3. **UI components match design mockups** (visual + functional)
4. **Acceptance criteria are testable** (concrete verification)
5. **No conflicting requirements** (spec vs. task consistency)

---

## When to Trigger

Auto-invoke this Skill when detecting:

**Implementation Start:**
- "implement task T001"
- "start implementing"
- "begin work on"
- "create endpoint"
- "build component"

**Feature Keywords:**
- "add feature"
- "new functionality"
- "implement requirement"
- "create API"
- "build UI"

**Domain-Specific:**
- "create endpoint /api/v1/..."
- "implement component MessageList"
- "add database migration"

---

## Pre-Implementation Checklist

### Step 1: Load Spec Requirements

```bash
# Locate spec file
FEATURE_DIR="specs/$SLUG"
SPEC_FILE="$FEATURE_DIR/spec.md"

if [ ! -f "$SPEC_FILE" ]; then
  echo "⚠️  Spec not found: $SPEC_FILE"
  echo "   Run /specify first to create spec"
  exit 1
fi

# Extract relevant sections
echo "📋 Loading spec requirements..."
```

**Read Spec Sections:**
```bash
# Get functional requirements
rg "^## Functional Requirements" "$SPEC_FILE" -A 50

# Get API endpoints (if backend task)
rg "^### Endpoints|^## API Design" "$SPEC_FILE" -A 20

# Get UI requirements (if frontend task)
rg "^### User Interface|^## UI Components" "$SPEC_FILE" -A 20

# Get acceptance criteria
rg "^## Acceptance Criteria|^## Success Criteria" "$SPEC_FILE" -A 30
```

### Step 2: Parse Task Requirements

```bash
# Extract task description
TASK_DESC=$(grep "^$TASK_ID" "$TASKS_FILE")

# Identify what's being built
TASK_ENTITY=""  # endpoint|component|model|migration|service

# Extract entity name
if [[ "$TASK_DESC" =~ "endpoint" ]]; then
  TASK_ENTITY="endpoint"
  # Extract endpoint path: e.g., "GET /api/v1/messages/{id}"
  ENDPOINT_PATH=$(echo "$TASK_DESC" | grep -o "/api/v[0-9]/[^ ]*")
elif [[ "$TASK_DESC" =~ "component" ]]; then
  TASK_ENTITY="component"
  # Extract component name: e.g., "MessageList"
  COMPONENT_NAME=$(echo "$TASK_DESC" | grep -oP "[A-Z][a-zA-Z]+(?=\s|$)")
elif [[ "$TASK_DESC" =~ "model" ]]; then
  TASK_ENTITY="model"
  # Extract model name: e.g., "Message"
  MODEL_NAME=$(echo "$TASK_DESC" | grep -oP "(?<=model |class )[A-Z][a-zA-Z]+")
fi
```

### Step 3: Verify Against Spec

#### For Backend Endpoints

**Check 1: Endpoint exists in spec**
```bash
# Search spec for endpoint definition
if ! grep -q "$ENDPOINT_PATH" "$SPEC_FILE"; then
  echo "⚠️  **SPEC VIOLATION: Endpoint not in spec**"
  echo ""
  echo "Task wants to create: $ENDPOINT_PATH"
  echo "Spec endpoints:"
  grep -oP "(?<=(GET|POST|PUT|PATCH|DELETE) )/api/v[0-9]/[^ ]*" "$SPEC_FILE"
  echo ""
  echo "Is this the correct endpoint? Update task or spec."
fi
```

**Check 2: Endpoint method matches**
```bash
# Extract HTTP method from task
TASK_METHOD=$(echo "$TASK_DESC" | grep -oP "(GET|POST|PUT|PATCH|DELETE)")

# Extract method from spec
SPEC_METHOD=$(grep "$ENDPOINT_PATH" "$SPEC_FILE" | grep -oP "(GET|POST|PUT|PATCH|DELETE)")

if [ "$TASK_METHOD" != "$SPEC_METHOD" ]; then
  echo "⚠️  **METHOD MISMATCH**"
  echo "   Task: $TASK_METHOD $ENDPOINT_PATH"
  echo "   Spec: $SPEC_METHOD $ENDPOINT_PATH"
  echo "   Which is correct?"
fi
```

**Check 3: OpenAPI contract alignment**
```bash
# Check if OpenAPI contract exists
CONTRACT_FILE="contracts/openapi.yaml"

if [ -f "$CONTRACT_FILE" ]; then
  # Verify endpoint in contract
  if ! grep -q "$ENDPOINT_PATH" "$CONTRACT_FILE"; then
    echo "⚠️  **CONTRACT VIOLATION**"
    echo "   Endpoint $ENDPOINT_PATH not in OpenAPI contract"
    echo "   Update contracts/openapi.yaml first (contract-first development)"
  else
    echo "✅ Endpoint found in OpenAPI contract"

    # Extract response schema from contract
    echo "   Response schema:"
    sed -n "/$ENDPOINT_PATH/,/responses:/p" "$CONTRACT_FILE" | tail -20
  fi
fi
```

#### For Frontend Components

**Check 1: Component in spec**
```bash
# Search spec for component mention
if ! grep -qi "$COMPONENT_NAME" "$SPEC_FILE"; then
  echo "⚠️  **SPEC VIOLATION: Component not mentioned in spec**"
  echo ""
  echo "Task wants to create: $COMPONENT_NAME"
  echo "Spec components:"
  grep -oP "(?<=component: |### )[A-Z][a-zA-Z]+" "$SPEC_FILE"
  echo ""
  echo "Is this component needed? Verify with spec."
fi
```

**Check 2: Design mockup exists**
```bash
# Check for polished mockup
MOCKUP_DIR="apps/web/mock/$SLUG/$COMPONENT_NAME/polished"

if [ -d "$MOCKUP_DIR" ]; then
  echo "✅ Polished mockup found: $MOCKUP_DIR"
  echo "   Implement UI matching mockup layout and components"
else
  echo "⚠️  No polished mockup for $COMPONENT_NAME"
  echo "   Spec should define UI requirements or provide mockup"
  echo "   Check: $FEATURE_DIR/visuals/ for design references"
fi
```

**Check 3: Props/API match spec**
```bash
# Extract component props from spec
SPEC_PROPS=$(grep -A 10 "Props:" "$SPEC_FILE" | grep "^-")

if [ -n "$SPEC_PROPS" ]; then
  echo "   Spec defines props:"
  echo "$SPEC_PROPS" | sed 's/^/     /'
  echo ""
  echo "   Ensure implementation matches these props exactly"
fi
```

#### For Database Models

**Check 1: Model in spec**
```bash
# Search spec for model/schema definition
if ! grep -qi "model: $MODEL_NAME\|schema: $MODEL_NAME" "$SPEC_FILE"; then
  echo "⚠️  **SPEC VIOLATION: Model not defined in spec**"
  echo ""
  echo "Task wants to create: $MODEL_NAME model"
  echo "Spec models:"
  grep -oP "(?<=Model: |### )[A-Z][a-zA-Z]+(?= Model)" "$SPEC_FILE"
  echo ""
  echo "Is this model needed? Verify with spec."
fi
```

**Check 2: Fields match spec**
```bash
# Extract model fields from spec
SPEC_FIELDS=$(sed -n "/Model: $MODEL_NAME/,/^##/p" "$SPEC_FILE" | grep "^-")

if [ -n "$SPEC_FIELDS" ]; then
  echo "   Spec defines fields:"
  echo "$SPEC_FIELDS" | sed 's/^/     /'
  echo ""
  echo "   Ensure model includes ALL required fields"
fi
```

### Step 4: Check for Scope Creep

**Detect extra features not in spec:**

```bash
# Common scope creep keywords
CREEP_KEYWORDS=(
  "also add"
  "while we're at it"
  "might as well"
  "additional feature"
  "extra functionality"
  "nice to have"
)

for keyword in "${CREEP_KEYWORDS[@]}"; do
  if grep -qi "$keyword" <<< "$TASK_DESC"; then
    echo "⚠️  **POSSIBLE SCOPE CREEP DETECTED**"
    echo "   Task contains: '$keyword'"
    echo "   Verify this feature is in the spec before implementing"
  fi
done
```

**Detect missing requirements:**

```bash
# Extract "must" requirements from spec
MUST_REQUIREMENTS=$(grep -i "must\|required\|shall" "$SPEC_FILE" | head -10)

echo "📋 **REQUIRED FEATURES (from spec):**"
echo "$MUST_REQUIREMENTS" | sed 's/^/  /'
echo ""
echo "Ensure task implementation includes ALL required features."
```

---

## Validation Results

### Validation Pass (Allow Implementation)

```markdown
✅ **SPEC COMPLIANCE VERIFIED**

**Task:** T015 - Create GET /api/v1/messages/{id} endpoint

**Checks Passed:**
✅ Endpoint exists in spec (line 127)
✅ HTTP method matches (GET)
✅ OpenAPI contract aligned (contracts/openapi.yaml:45)
✅ Response schema defined (MessageSchema)
✅ No scope creep detected
✅ All required fields present (id, content, user_id, created_at)

**Spec Requirements:**
- Authentication: Required (current_user dependency)
- Validation: UUID path parameter
- Error handling: 404 if message not found
- Response: 200 with MessageSchema

**Ready to implement** following spec requirements.

Proceed? (yes)
```

### Validation Warning (Proceed with Caution)

```markdown
⚠️  **SPEC COMPLIANCE WARNINGS**

**Task:** T022 - Create MessageList component

**Warnings:**
⚠️  No polished mockup found in apps/web/mock/$SLUG/MessageList/
⚠️  Component not explicitly mentioned in spec (implied from requirements)

**Inferred Requirements (from spec):**
- Display list of messages
- Show content and timestamp
- Pagination support (limit/offset)
- Empty state when no messages

**Recommendation:**
1. Verify component is needed with product owner
2. Use existing list component pattern (StudyPlanList.tsx)
3. Keep UI minimal (match spec requirements only)

Proceed with caution? (yes/no)
```

### Validation Failure (Block Implementation)

```markdown
❌ **SPEC VIOLATION: Implementation Blocked**

**Task:** T030 - Add real-time message updates with WebSockets

**Issues:**
❌ Real-time updates NOT in spec
❌ WebSockets NOT mentioned in requirements
❌ No acceptance criteria for real-time functionality

**Spec Requirements (Messaging):**
- List messages (pagination)
- Send message (POST endpoint)
- Edit message (PUT endpoint)
- Delete message (DELETE endpoint)

**Real-time updates:** NOT SPECIFIED

**Actions:**
Option A: Update spec to include real-time requirements (run /specify)
Option B: Remove WebSocket implementation from task (out of scope)
Option C: Defer to future enhancement (add to roadmap as P3)

**Cannot proceed until spec is updated or task is adjusted.**

Blocked - resolve spec conflict first.
```

---

## Scope Creep Prevention

### Common Scope Creep Scenarios

**Scenario 1: "While We're At It" Features**

**Task:**
```
T015 - Implement Message model. While we're at it, add support for attachments and reactions.
```

**Spec Says:**
```
Message model: id, content, user_id, created_at
```

**Validator Response:**
```markdown
⚠️  **SCOPE CREEP DETECTED**

Task wants to add:
- ❌ Attachments (NOT in spec)
- ❌ Reactions (NOT in spec)

Spec defines:
- ✅ id, content, user_id, created_at

**Recommendation:**
- Implement spec requirements only (Message fields)
- Defer attachments/reactions to future enhancements
- Add to roadmap as P3 tasks if needed

Remove scope creep or update spec first.
```

**Scenario 2: Over-Engineering**

**Task:**
```
T022 - Create MessageList component with infinite scroll, virtual rendering, and optimistic updates
```

**Spec Says:**
```
Display messages with pagination (limit/offset)
```

**Validator Response:**
```markdown
⚠️  **OVER-ENGINEERING DETECTED**

Task includes advanced features:
- ⚠️  Infinite scroll (NOT in spec)
- ⚠️  Virtual rendering (NOT in spec)
- ⚠️  Optimistic updates (NOT in spec)

Spec requires:
- ✅ Pagination (limit/offset)

**Recommendation:**
- Implement simple pagination first (spec requirement)
- Test with users before adding complexity
- Defer advanced features to P2/P3 if needed

Keep it simple (KISS principle).
```

**Scenario 3: Missing Acceptance Criteria**

**Task:**
```
T015 - Implement message validation
```

**Spec Says:**
```
(No validation requirements specified)
```

**Validator Response:**
```markdown
⚠️  **VAGUE REQUIREMENTS**

Task: "Implement message validation"
Spec: No validation rules defined

**Questions:**
- What fields are required?
- Min/max length for content?
- Allowed characters?
- Rate limiting?

**Actions:**
1. Clarify validation rules in spec (run /clarify)
2. Add acceptance criteria to spec
3. Then implement with clear requirements

Cannot implement without clear requirements.
```

---

## Contract-First Validation (Backend)

### OpenAPI Contract Check

**Before implementing endpoint, verify contract:**

```bash
CONTRACT_FILE="contracts/openapi.yaml"

# Extract endpoint definition
ENDPOINT_DEF=$(sed -n "/$ENDPOINT_PATH:/,/^  \//p" "$CONTRACT_FILE")

if [ -z "$ENDPOINT_DEF" ]; then
  echo "❌ **CONTRACT MISSING**"
  echo ""
  echo "Endpoint $ENDPOINT_PATH not in OpenAPI contract."
  echo ""
  echo "**Contract-First Development:**"
  echo "1. Add endpoint to contracts/openapi.yaml"
  echo "2. Define request/response schemas"
  echo "3. Validate contract: spectral lint contracts/openapi.yaml"
  echo "4. Then implement endpoint matching contract"
  echo ""
  echo "Cannot proceed without contract definition."
  exit 1
fi

echo "✅ OpenAPI contract found"
echo ""
echo "Contract definition:"
echo "$ENDPOINT_DEF" | sed 's/^/  /'
echo ""
echo "Implement endpoint matching this exact schema."
```

### Schema Alignment Check

**Verify request/response schemas:**

```bash
# Extract response schema from contract
RESPONSE_SCHEMA=$(sed -n "/$ENDPOINT_PATH:/,/responses:/p" "$CONTRACT_FILE" | \
  grep -A 10 "200:" | \
  grep "schema:")

if [ -n "$RESPONSE_SCHEMA" ]; then
  SCHEMA_REF=$(echo "$RESPONSE_SCHEMA" | grep -oP "(?<=\$ref: ')[^']+")

  echo "   Response schema: $SCHEMA_REF"
  echo ""
  echo "   Ensure Pydantic model matches this schema exactly"

  # Extract schema definition
  sed -n "/$SCHEMA_REF:/,/^  [A-Z]/p" "$CONTRACT_FILE" | head -20
fi
```

---

## Design Mockup Validation (Frontend)

### Polished Mockup Check

**Verify mockup exists and matches spec:**

```bash
MOCKUP_DIR="apps/web/mock/$SLUG/$COMPONENT_NAME/polished"

if [ ! -d "$MOCKUP_DIR" ]; then
  echo "⚠️  **NO POLISHED MOCKUP**"
  echo ""
  echo "Component: $COMPONENT_NAME"
  echo "Expected: $MOCKUP_DIR"
  echo ""
  echo "**Options:**"
  echo "A) Create polished mockup first (run /design-functional)"
  echo "B) Implement from spec description (if mockup not needed)"
  echo "C) Use existing component as reference (add REUSE marker)"
  echo ""
  echo "Recommend: Create mockup for consistent UI/UX"
else
  echo "✅ Polished mockup found: $MOCKUP_DIR"

  # List mockup files
  echo ""
  echo "Mockup files:"
  ls "$MOCKUP_DIR" | sed 's/^/  - /'
  echo ""
  echo "**Implementation Guidelines:**"
  echo "- Copy: Layout, components, tokens, a11y attributes"
  echo "- Add: Real API calls, state management, analytics"
  echo "- Remove: Mock data, console.logs, 'Mock' labels"
fi
```

---

## Integration with Spec-Flow Workflow

### During /implement Phase

**Before each task implementation:**

1. **Load spec requirements** for task domain (endpoint/component/model)
2. **Verify task aligns** with spec (no extra/missing features)
3. **Check contract** if backend (OpenAPI alignment)
4. **Check mockup** if frontend (polished design exists)
5. **Detect scope creep** (extra features not in spec)
6. **Block or warn** if spec violation detected
7. **Allow implementation** only if spec-compliant

**Result:** Zero scope creep, exact spec implementation, no rework

---

## Examples

### Example 1: Backend Endpoint Validation

**Task:**
```
T015 [GREEN→T014] Implement GET /api/v1/messages/{id} endpoint
```

**Spec Compliance Check:**
```markdown
🔍 **SPEC COMPLIANCE CHECK**

**Task:** T015 - GET /api/v1/messages/{id}

**Checking spec...**
✅ Endpoint in spec: spec.md:127
✅ HTTP method: GET (matches spec)
✅ Authentication: Required (current_user dependency)

**Checking OpenAPI contract...**
✅ Contract definition: contracts/openapi.yaml:45
✅ Response schema: MessageSchema
✅ Required fields: id, content, user_id, created_at

**Checking implementation requirements...**
✅ Path parameter: id (UUID validation)
✅ Error handling: 404 if message not found
✅ Response code: 200 on success

**SPEC COMPLIANCE: VERIFIED ✅**

Ready to implement following spec requirements.

Proceed with implementation.
```

### Example 2: Frontend Component with Missing Mockup

**Task:**
```
T022 [P] Create MessageList component
```

**Spec Compliance Check:**
```markdown
🔍 **SPEC COMPLIANCE CHECK**

**Task:** T022 - MessageList component

**Checking spec...**
⚠️  Component name not explicitly in spec
✅ Inferred from requirement: "Display list of messages"

**Checking design mockup...**
❌ Polished mockup not found: apps/web/mock/user-messaging/MessageList/polished/

**Inferred Requirements:**
- Display messages (content, timestamp, author)
- Pagination (limit/offset from spec)
- Empty state ("No messages yet")
- Loading state (skeleton)

**Recommendation:**
Option A: Create polished mockup first (run /design-functional)
Option B: Use StudyPlanList.tsx as REUSE pattern (similar list component)
Option C: Implement minimal UI from spec description

**SPEC COMPLIANCE: WARNING ⚠️**

Proceed with caution - no mockup to follow.

Recommend: Use StudyPlanList.tsx as REUSE pattern.
```

### Example 3: Scope Creep Blocked

**Task:**
```
T030 [P] Add real-time message updates with WebSockets and typing indicators
```

**Spec Compliance Check:**
```markdown
🔍 **SPEC COMPLIANCE CHECK**

**Task:** T030 - Real-time updates with WebSockets

**Checking spec...**
❌ Real-time updates NOT in spec
❌ WebSockets NOT mentioned in requirements
❌ Typing indicators NOT in acceptance criteria

**Spec Requirements (Messaging):**
- List messages (pagination) ✓
- Send message ✓
- Edit message ✓
- Delete message ✓

**Real-time features:** NOT SPECIFIED

**SPEC COMPLIANCE: VIOLATION ❌**

**Actions:**
Option A: Update spec to include real-time requirements (run /clarify + /specify)
Option B: Remove real-time features from task (out of scope for MVP)
Option C: Defer to future enhancement (add to roadmap as P3)

**Cannot proceed - implementation doesn't match spec.**

Resolve spec conflict first.
```

---

## Spec Compliance Rules

1. **Spec is the contract** - Implement exactly what's specified, nothing more, nothing less
2. **Contract-first (backend)** - Update OpenAPI contract before implementing endpoints
3. **Design-first (frontend)** - Follow polished mockups for UI components
4. **No scope creep** - Block extra features not in spec
5. **No vague requirements** - Require clear acceptance criteria before implementing
6. **Allow flexibility** - Warn but don't block reasonable inferences from spec
7. **Evidence required** - Link to spec section, contract line, or mockup file

---

## Constraints

- **Read-only operations**: Use Read, Grep only (no file modifications)
- **Fast validation**: Complete checks in <5 seconds
- **Relevant checks**: Only validate what's being implemented (endpoint/component/model)
- **Clear feedback**: Show spec requirements vs. task implementation
- **User decision**: Present issues, let user decide to proceed or adjust

---

## Return Format

**Spec Compliance Verified:**
```markdown
✅ **SPEC COMPLIANCE VERIFIED**

**Task:** {TASK_ID} - {TASK_DESC}

**Checks Passed:**
{LIST_OF_CHECKS}

**Spec Requirements:**
{EXTRACTED_REQUIREMENTS}

**Ready to implement** following spec requirements.

Proceed? (yes)
```

**Spec Compliance Warning:**
```markdown
⚠️  **SPEC COMPLIANCE WARNINGS**

**Task:** {TASK_ID} - {TASK_DESC}

**Warnings:**
{LIST_OF_WARNINGS}

**Inferred Requirements:**
{GUESSED_REQUIREMENTS}

**Recommendation:**
{SUGGESTED_ACTIONS}

Proceed with caution? (yes/no)
```

**Spec Violation (Blocked):**
```markdown
❌ **SPEC VIOLATION: Implementation Blocked**

**Task:** {TASK_ID} - {TASK_DESC}

**Issues:**
{LIST_OF_VIOLATIONS}

**Spec Requirements:**
{ACTUAL_SPEC_REQUIREMENTS}

**Actions:**
{REQUIRED_FIXES}

Cannot proceed until spec is updated or task is adjusted.
```
