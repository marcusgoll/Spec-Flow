# Tech Stack Validation

**Purpose**: Load documented tech stack from `tech-stack.md` to validate implementation choices and prevent hallucinated tech suggestions.

**When to execute**:
- Always before implementing any task
- Before suggesting alternative libraries or frameworks
- Before importing any new dependencies

---

## Step 1: Check for Tech Stack Documentation

```bash
TECH_STACK_DOC="docs/project/tech-stack.md"
HAS_TECH_STACK=false

if [ -f "$TECH_STACK_DOC" ]; then
  HAS_TECH_STACK=true
  echo "✅ Tech stack documentation found"
  echo ""

  # Read tech stack for validation
  # Claude Code: Read docs/project/tech-stack.md

  # Extract key sections (see extraction logic below)
else
  echo "⚠️  No tech stack documentation found"
  echo "   Run /init-project to document tech stack"
  echo "   (Implementation will proceed without validation)"
  echo ""
fi
```

---

## Step 2: Extract Technology Constraints

**Extraction logic** (from tech-stack.md):

```bash
# Extract technology versions from tech stack table
# Format: | Category | Technology | Version | Purpose |

# Backend
BACKEND_FRAMEWORK=$(grep -A 1 "| Backend" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $3}' | xargs)
BACKEND_VERSION=$(grep -A 1 "| Backend" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $4}' | xargs)

# Frontend
FRONTEND_FRAMEWORK=$(grep -A 1 "| Frontend" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $3}' | xargs)
FRONTEND_VERSION=$(grep -A 1 "| Frontend" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $4}' | xargs)

# Database
DATABASE=$(grep -A 1 "| Database" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $3}' | xargs)
DATABASE_VERSION=$(grep -A 1 "| Database" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $4}' | xargs)

# ORM
ORM=$(grep -A 1 "| ORM" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $3}' | xargs)

# Testing
BACKEND_TEST_FRAMEWORK=$(grep -A 1 "| Testing" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $3}' | xargs)
FRONTEND_TEST_FRAMEWORK=$(grep -A 1 "| UI Testing" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $3}' | xargs)

# Store for validation
export BACKEND_FRAMEWORK BACKEND_VERSION FRONTEND_FRAMEWORK FRONTEND_VERSION
export DATABASE DATABASE_VERSION ORM
export BACKEND_TEST_FRAMEWORK FRONTEND_TEST_FRAMEWORK

echo "📋 Tech Stack Constraints (from tech-stack.md):"
echo "   Backend: $BACKEND_FRAMEWORK $BACKEND_VERSION"
echo "   Frontend: $FRONTEND_FRAMEWORK $FRONTEND_VERSION"
echo "   Database: $DATABASE $DATABASE_VERSION"
echo "   ORM: $ORM"
echo "   Testing: $BACKEND_TEST_FRAMEWORK, $FRONTEND_TEST_FRAMEWORK"
echo ""
```

**Example extracted context**:
```
📋 Tech Stack Constraints (from tech-stack.md):
   Backend: FastAPI 0.110.0
   Frontend: Next.js 14.2
   Database: PostgreSQL 16
   ORM: SQLAlchemy 2.0
   Testing: pytest, Playwright
```

---

## Validation Rules

### Rule 1: No Alternative Frameworks (BLOCKING)

```bash
# Example violation: Suggesting Django when FastAPI documented
SUGGESTED_FRAMEWORK="Django"

if [ "$HAS_TECH_STACK" = true ] && [ "$SUGGESTED_FRAMEWORK" != "$BACKEND_FRAMEWORK" ]; then
  echo "❌ TECH STACK VIOLATION"
  echo ""
  echo "Documented tech stack:"
  echo "  Backend: $BACKEND_FRAMEWORK (tech-stack.md:12)"
  echo ""
  echo "Suggested implementation:"
  echo "  Backend: $SUGGESTED_FRAMEWORK"
  echo ""
  echo "Options:"
  echo "  A) Use documented tech ($BACKEND_FRAMEWORK)"
  echo "  B) Update tech-stack.md if migrating"
  echo "  C) Reject suggestion (enforce tech stack)"
  echo ""
  echo "BLOCKING: Cannot implement with wrong tech stack"
  exit 1
fi
```

### Rule 2: Version Compatibility (WARNING)

```bash
# Example: Using incompatible library version
SUGGESTED_LIBRARY="pydantic"
SUGGESTED_VERSION="1.10"
DOCUMENTED_VERSION="2.6"  # From tech-stack.md dependencies

MAJOR_SUGGESTED=$(echo "$SUGGESTED_VERSION" | cut -d. -f1)
MAJOR_DOCUMENTED=$(echo "$DOCUMENTED_VERSION" | cut -d. -f1)

if [ "$MAJOR_SUGGESTED" != "$MAJOR_DOCUMENTED" ]; then
  echo "⚠️  VERSION INCOMPATIBILITY DETECTED"
  echo ""
  echo "Documented version:"
  echo "  $SUGGESTED_LIBRARY $DOCUMENTED_VERSION (tech-stack.md:45)"
  echo ""
  echo "Suggested version:"
  echo "  $SUGGESTED_LIBRARY $SUGGESTED_VERSION"
  echo ""
  echo "Major version mismatch may cause breaking changes"
  echo "Review tech-stack.md before proceeding"
  echo ""
fi
```

### Rule 3: Test Framework Consistency (BLOCKING)

```bash
# Example: Using wrong test framework
TASK_DESCRIPTION="Write unit tests for StudentProgressService"
SUGGESTED_TEST_FRAMEWORK="unittest"  # Detected from task description

if [ "$HAS_TECH_STACK" = true ] && [ "$SUGGESTED_TEST_FRAMEWORK" != "$BACKEND_TEST_FRAMEWORK" ]; then
  echo "❌ TEST FRAMEWORK VIOLATION"
  echo ""
  echo "Documented test framework:"
  echo "  $BACKEND_TEST_FRAMEWORK (tech-stack.md:23)"
  echo ""
  echo "Suggested in task:"
  echo "  $SUGGESTED_TEST_FRAMEWORK"
  echo ""
  echo "Corrected task description:"
  echo "  'Write unit tests using $BACKEND_TEST_FRAMEWORK for StudentProgressService'"
  echo ""
  echo "BLOCKING: Use documented test framework"
  exit 1
fi
```

---

## Decision Tree

```
Start implementation task
    |
    v
Is tech-stack.md present?
    |-- No --> Proceed without validation (warn user)
    |
    v (Yes)
Extract: Backend, Frontend, Database, ORM, Testing frameworks
    |
    v
Does task suggest different framework?
    |-- Yes --> BLOCK: "Use documented framework or update tech-stack.md"
    |
    v (No)
Does task use incompatible library version?
    |-- Yes --> WARN: "Major version mismatch, review tech-stack.md"
    |
    v (No - or warning acknowledged)
Does task use wrong test framework?
    |-- Yes --> BLOCK: "Use documented test framework"
    |
    v (No)
✅ Validation passed, proceed to TDD workflow
```

---

## Integration with Hallucination Detector

This step works in conjunction with the `hallucination-detector` skill:
- **Hallucination detector**: Prevents suggesting wrong tech during spec/plan phases
- **Tech stack validation**: Enforces correct tech during implementation phase
- **Together**: 100% tech stack compliance across workflow

---

## Example Validation Scenarios

### Scenario 1: Wrong Backend Framework (BLOCKED)

```
Task 5: Implement authentication middleware

Suggested implementation:
  "Use Django middleware for authentication"

❌ TECH STACK VIOLATION

Documented tech stack:
  Backend: FastAPI 0.110.0 (tech-stack.md:12)

Suggested implementation:
  Backend: Django

BLOCKING: Cannot implement with wrong tech stack

✅ Corrected:
  "Use FastAPI middleware for authentication"
```

### Scenario 2: Wrong ORM (BLOCKED)

```
Task 8: Create Student model

Suggested implementation:
  "Use Django ORM for Student model"

❌ TECH STACK VIOLATION

Documented ORM:
  SQLAlchemy 2.0 (tech-stack.md:18)

Suggested ORM:
  Django ORM

BLOCKING: Use documented ORM (SQLAlchemy)

✅ Corrected:
  "Use SQLAlchemy declarative base for Student model"
```

### Scenario 3: Wrong Test Framework (BLOCKED)

```
Task 12: Write unit tests for StudentProgressService

Suggested implementation:
  "Use unittest framework"

❌ TEST FRAMEWORK VIOLATION

Documented test framework:
  pytest (tech-stack.md:23)

Suggested in task:
  unittest

BLOCKING: Use documented test framework

✅ Corrected:
  "Write unit tests using pytest for StudentProgressService"
```

### Scenario 4: Compatible Library Added (ALLOWED)

```
Task 15: Add email validation

Suggested library:
  "Install email-validator 2.1.0"

✅ VALIDATION PASSED

Reason:
  - No alternative email library documented
  - Version compatible with Python 3.11 (tech-stack.md:11)
  - No conflicts with documented dependencies

Proceed with implementation
```

---

## Performance Notes

**Token budget**: ~5-8K tokens (tech-stack.md is typically 2-4 pages)
**Performance impact**: <10 seconds (one-time read at start of implementation)
**Quality check**: Tech stack constraints loaded, validation rules active
