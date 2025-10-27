---
name: breaking-change-detector
description: "Detect and warn about breaking API/schema changes before implementation. Auto-trigger when modifying API routes, database schemas, or public interfaces. Validates changes against api-strategy.md versioning rules. Suggests migration paths for breaking changes. Prevents: removing endpoints, changing request/response formats, dropping database columns, modifying function signatures without deprecation."
allowed-tools: Read, Grep, Bash
---

# Breaking Change Detector: API/Schema Change Validator

**Purpose**: Prevent accidental breaking changes to APIs, database schemas, and public interfaces.

**Philosophy**: "Breaking changes break users. Detect them early, version them properly, provide migration paths."

---

## When to Trigger

**Auto-invoke when detecting these patterns**:

### API Changes
- "remove endpoint"
- "delete route"
- "change API"
- "modify endpoint"
- "add required field"
- "remove field from response"
- "change HTTP method"

### Database Schema Changes
- "drop column"
- "remove table"
- "change column type"
- "add NOT NULL constraint"
- "remove foreign key"
- "rename table/column"

### Public Interface Changes
- "remove function"
- "change function signature"
- "delete export"
- "modify interface"
- "breaking change"

---

## Breaking Change Detection Rules

### 1. API Endpoint Changes (Breaking)

**Breaking changes**:
- ❌ Removing an endpoint
- ❌ Changing HTTP method (GET → POST)
- ❌ Adding required parameter
- ❌ Removing field from response
- ❌ Changing response format
- ❌ Changing URL path

**Non-breaking changes**:
- ✅ Adding optional parameter
- ✅ Adding field to response
- ✅ Adding new endpoint
- ✅ Deprecating (with notice period)

**Detection logic**:
```bash
# Compare current API routes with proposed changes
CURRENT_ROUTES=$(grep -r "@router\.(get|post|put|delete)" api/app/api/v1/routers/ -h)
PROPOSED_CHANGE="Remove /api/v1/students endpoint"

# Check if removing existing endpoint
if echo "$PROPOSED_CHANGE" | grep -qi "remove.*endpoint"; then
  ENDPOINT=$(echo "$PROPOSED_CHANGE" | grep -oP '/api/v[0-9]+/[a-z]+')

  if echo "$CURRENT_ROUTES" | grep -q "$ENDPOINT"; then
    echo "❌ BREAKING CHANGE DETECTED: Removing existing endpoint"
    echo ""
    echo "   Endpoint: $ENDPOINT"
    echo "   Impact: Existing clients will receive 404 errors"
    echo ""
    echo "   Options:"
    echo "   A) Deprecate instead (add deprecation notice, remove in v2)"
    echo "   B) Create /api/v2/ with new structure"
    echo "   C) Keep endpoint, mark as deprecated in docs"
    echo ""
    return 1
  fi
fi
```

---

### 2. Request/Response Format Changes (Breaking)

**Breaking changes**:
- ❌ Adding required field to request
- ❌ Removing field from response
- ❌ Changing field type (string → int)
- ❌ Changing field name

**Non-breaking changes**:
- ✅ Adding optional field to request
- ✅ Adding field to response
- ✅ Deprecating field (keep in response but mark deprecated)

**Detection logic**:
```bash
# Check Pydantic schemas for changes
CURRENT_SCHEMA=$(grep -A 20 "class StudentCreate" api/app/schemas/student.py)
PROPOSED_CHANGE="Add required field: email"

# Check if making optional field required
if echo "$CURRENT_SCHEMA" | grep -q "email: Optional"; then
  if echo "$PROPOSED_CHANGE" | grep -qi "required.*email"; then
    echo "❌ BREAKING CHANGE DETECTED: Making optional field required"
    echo ""
    echo "   Field: email (currently Optional)"
    echo "   Proposed: Required"
    echo "   Impact: Existing API calls without 'email' will fail validation"
    echo ""
    echo "   Options:"
    echo "   A) Keep as optional, add default value"
    echo "   B) Create /api/v2/ with required email"
    echo "   C) Add migration: email defaults to 'legacy@example.com'"
    echo ""
    return 1
  fi
fi
```

---

### 3. Database Schema Changes (Breaking)

**Breaking changes**:
- ❌ DROP COLUMN
- ❌ ALTER COLUMN type (incompatible)
- ❌ ADD NOT NULL (without default)
- ❌ DROP TABLE
- ❌ DROP FOREIGN KEY

**Non-breaking changes**:
- ✅ ADD COLUMN (nullable or with default)
- ✅ CREATE TABLE
- ✅ ADD INDEX
- ✅ ALTER COLUMN (compatible, e.g., VARCHAR(50) → VARCHAR(100))

**Detection logic**:
```bash
# Check migration file for breaking changes
MIGRATION_FILE="alembic/versions/abc123_update_students.py"

# Scan for DROP COLUMN
if grep -q "op.drop_column" "$MIGRATION_FILE"; then
  COLUMN=$(grep "op.drop_column" "$MIGRATION_FILE" | grep -oP "'\K[^']+(?=')" | tail -1)
  TABLE=$(grep "op.drop_column" "$MIGRATION_FILE" | grep -oP "'\K[^']+(?=')" | head -1)

  echo "❌ BREAKING CHANGE DETECTED: Dropping column"
  echo ""
  echo "   Table: $TABLE"
  echo "   Column: $COLUMN"
  echo "   Impact: Existing code reading this column will fail"
  echo ""
  echo "   Migration path:"
  echo "   1. Mark column as deprecated (add migration comment)"
  echo "   2. Update all code to stop using column"
  echo "   3. Deploy code changes"
  echo "   4. Wait 1-2 weeks (ensure no usage)"
  echo "   5. Then drop column in separate migration"
  echo ""
  return 1
fi

# Scan for ADD NOT NULL without default
if grep -q "nullable=False" "$MIGRATION_FILE"; then
  if ! grep -q "server_default" "$MIGRATION_FILE"; then
    echo "❌ BREAKING CHANGE DETECTED: Adding NOT NULL without default"
    echo ""
    echo "   Impact: Existing rows with NULL will fail constraint"
    echo ""
    echo "   Fix: Add server_default or default value"
    echo "   Example: sa.Column('email', sa.String, nullable=False, server_default='unknown@example.com')"
    echo ""
    return 1
  fi
fi
```

---

### 4. Function Signature Changes (Breaking)

**Breaking changes**:
- ❌ Removing function parameter
- ❌ Changing parameter type (int → str)
- ❌ Reordering parameters
- ❌ Removing function export

**Non-breaking changes**:
- ✅ Adding optional parameter (with default)
- ✅ Adding new function
- ✅ Deprecating function (keep old, add new)

**Detection logic**:
```bash
# Check for function signature changes
CURRENT_FUNC=$(grep -A 5 "def create_student" api/app/services/student_service.py)
PROPOSED_CHANGE="Remove 'instructor_id' parameter"

# Check if removing parameter
if echo "$PROPOSED_CHANGE" | grep -qi "remove.*parameter"; then
  PARAM=$(echo "$PROPOSED_CHANGE" | grep -oP "'\K[^']+")

  if echo "$CURRENT_FUNC" | grep -q "$PARAM"; then
    echo "❌ BREAKING CHANGE DETECTED: Removing function parameter"
    echo ""
    echo "   Function: create_student"
    echo "   Parameter: $PARAM"
    echo "   Impact: Existing calls with this parameter will fail"
    echo ""
    echo "   Options:"
    echo "   A) Keep parameter, make it optional (default=None)"
    echo "   B) Deprecate function, create create_student_v2"
    echo "   C) Add migration guide for callers"
    echo ""
    return 1
  fi
fi
```

---

## Versioning Strategies

### API Versioning (Per api-strategy.md)

**Read versioning strategy from project docs**:
```bash
if [ -f "docs/project/api-strategy.md" ]; then
  VERSIONING=$(grep -A 3 "## Versioning" docs/project/api-strategy.md | tail -2)
  echo "📋 Project versioning strategy:"
  echo "$VERSIONING"
fi
```

**Strategy 1: URL Versioning** (recommended)
```
Current: /api/v1/students
Breaking change: Create /api/v2/students
Migration: Support both v1 and v2 simultaneously
Deprecation: Announce v1 deprecation, sunset after 6-12 months
```

**Strategy 2: Header Versioning**
```
Current: Accept-Version: v1
Breaking change: Accept-Version: v2
Migration: Support both versions in same endpoint
```

**Strategy 3: Deprecation Without Versioning** (simple apps)
```
Step 1: Add deprecation notice (X-Deprecated: true header)
Step 2: Log usage of deprecated endpoint
Step 3: After usage drops to 0, remove endpoint
```

---

### Database Migration Strategies

**Strategy 1: Expand-Contract Pattern**
```
Step 1 (Expand): Add new column (nullable)
        Deploy: Code reads from both old and new column
Step 2 (Migrate): Background job migrates data old→new
        Deploy: Code writes to both old and new column
Step 3 (Contract): Drop old column
        Deploy: Code only uses new column
```

**Example**:
```python
# Migration 1: Expand (add new column)
def upgrade():
    op.add_column('students', sa.Column('email_address', sa.String(255), nullable=True))

# Migration 2: Migrate data
def upgrade():
    op.execute("UPDATE students SET email_address = email WHERE email_address IS NULL")

# Migration 3: Contract (drop old column, make new required)
def upgrade():
    op.alter_column('students', 'email_address', nullable=False)
    op.drop_column('students', 'email')
```

---

## Breaking Change Checklist

**Before approving breaking change**:

- [ ] **Impact Assessment**: How many clients/users affected?
- [ ] **Versioning**: Is new version created (/api/v2/)?
- [ ] **Migration Path**: Clear steps for clients to migrate?
- [ ] **Deprecation Notice**: Announced with timeline?
- [ ] **Backward Compatibility**: Old version still supported during transition?
- [ ] **Documentation**: Migration guide written?
- [ ] **Testing**: Both old and new versions tested?
- [ ] **Monitoring**: Usage tracking for old version?

**Approval Required**:
```bash
echo "⚠️  BREAKING CHANGE requires approval"
echo ""
echo "Complete checklist above, then get approval from:"
echo "- Tech lead (architecture review)"
echo "- Product (user impact assessment)"
echo "- Support (migration communication plan)"
echo ""
read -p "Approved? (y/N): " APPROVED
if [[ ! "$APPROVED" =~ ^[Yy]$ ]]; then
  echo "Breaking change blocked - get approval first"
  return 1
fi
```

---

## Auto-Fix Suggestions

### API Breaking Change → Versioning
```bash
# Detected: Removing /api/v1/students endpoint
# Suggested fix:

echo "✅ Suggested fix: Create /api/v2/ instead"
echo ""
echo "1. Keep /api/v1/students (deprecated)"
echo "2. Create /api/v2/students (new design)"
echo "3. Update api-strategy.md (add v2 versioning)"
echo ""
echo "Example:"
cat <<'EOF'
# api/app/api/v1/routers/students.py (keep, add deprecation)
@router.get("/api/v1/students", deprecated=True)
async def get_students_v1():
    # Add deprecation header
    return {"deprecated": True, "migrate_to": "/api/v2/students"}

# api/app/api/v2/routers/students.py (new)
@router.get("/api/v2/students")
async def get_students_v2():
    # New implementation
    return {...}
EOF
```

### Database Breaking Change → Expand-Contract
```bash
# Detected: DROP COLUMN email
# Suggested fix:

echo "✅ Suggested fix: Use Expand-Contract pattern"
echo ""
echo "Migration sequence:"
echo "1. Add new column email_address (nullable)"
echo "2. Backfill data: email → email_address"
echo "3. Update code to use email_address"
echo "4. Deploy code"
echo "5. Wait 1-2 weeks (monitor old column usage)"
echo "6. Drop old column email"
```

---

## Integration with api-strategy.md

**Read documented versioning strategy**:
```bash
if [ -f "docs/project/api-strategy.md" ]; then
  # Extract versioning strategy
  VERSIONING_STRATEGY=$(sed -n '/## Versioning/,/^##/p' docs/project/api-strategy.md | grep -v "^##")

  echo "📋 Following documented versioning strategy:"
  echo "$VERSIONING_STRATEGY"
  echo ""
  echo "Ensure breaking change follows this strategy."
fi
```

**Update api-strategy.md if creating new version**:
```bash
if [ "$NEW_API_VERSION" = "v2" ]; then
  echo "ℹ️  Remember to update api-strategy.md:"
  echo "   - Add /api/v2/ versioning section"
  echo "   - Document breaking changes from v1"
  echo "   - Add migration guide"
fi
```

---

## Performance Impact

**Token Overhead**: ~1-3K tokens per breaking change check

**Optimization**:
- Only check when modifying existing code (not new features)
- Cache current API routes/schemas (avoid repeated reads)
- Skip check if no project docs exist

**Expected Duration**: < 10 seconds per check

---

## Quality Checklist

Before allowing breaking change:

- [ ] Breaking change identified and documented
- [ ] Versioning strategy selected (URL/header/deprecation)
- [ ] Migration path defined (expand-contract for DB, v2 for API)
- [ ] Impact assessment completed (users affected, timeline)
- [ ] Deprecation notice prepared (docs, headers, logs)
- [ ] Backward compatibility maintained (dual support during transition)
- [ ] api-strategy.md updated (if creating new version)
- [ ] Approval obtained (tech lead, product, support)

---

## References

- **API Strategy Doc**: `docs/project/api-strategy.md`
- **Semantic Versioning**: https://semver.org/
- **Expand-Contract Pattern**: https://www.martinfowler.com/bliki/ParallelChange.html
- **API Versioning Guide**: https://stripe.com/docs/api/versioning
