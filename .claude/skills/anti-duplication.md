---
name: anti-duplication
description: Before implementing new code (endpoints, components, services, models), search the codebase for existing patterns to reuse. Prevent code duplication by finding and suggesting similar implementations. Auto-trigger when user asks to create, implement, add, or build new functionality.
allowed-tools: Read, Grep, Glob
---

# Anti-Duplication: Code Reuse Enforcer

**Purpose**: Search codebase before implementing to find existing patterns, enforce REUSE markers, and prevent duplicate code.

**Philosophy**: "Code is read more than written. Find it before you write it."

---

## When to Trigger

Auto-invoke this Skill when you detect these patterns in user requests or task descriptions:

**Creation Keywords:**
- "create new endpoint"
- "implement new component"
- "add new service"
- "write new model"
- "build new feature"

**Implementation Keywords:**
- "implement task T001"
- "start implementing"
- "begin work on"
- "add functionality"

**REUSE Markers (from tasks.md):**
- Tasks with `REUSE:` annotations
- Example: `T001 [RED] Create Message model  REUSE: api/app/models/user.py`

**Anti-Patterns to Block:**
- Implementing without checking existing code
- Ignoring REUSE markers
- Creating duplicate logic

---

## Pre-Implementation Checklist

Before allowing implementation, run this checklist:

### Step 1: Extract Task Context

```bash
# Parse task description to understand what's being built
TASK_TYPE=""  # endpoint|component|service|model|migration|test

# Detect type from description
if [[ "$TASK_DESC" =~ endpoint|route|api ]]; then
  TASK_TYPE="endpoint"
elif [[ "$TASK_DESC" =~ component|tsx|jsx ]]; then
  TASK_TYPE="component"
elif [[ "$TASK_DESC" =~ service|business\ logic ]]; then
  TASK_TYPE="service"
elif [[ "$TASK_DESC" =~ model|schema|database ]]; then
  TASK_TYPE="model"
elif [[ "$TASK_DESC" =~ migration|alembic ]]; then
  TASK_TYPE="migration"
elif [[ "$TASK_DESC" =~ test|spec ]]; then
  TASK_TYPE="test"
fi
```

### Step 2: Search for Similar Patterns

**For Endpoints:**
```bash
# Search for similar route patterns
rg "router\.(get|post|put|delete)" api/app/api/v1/routers/ -A 3

# Look for similar path parameters
rg "/{id}|/{slug}" api/app/api/v1/routers/

# Find validation patterns
rg "Depends\(|validate_" api/app/api/v1/routers/
```

**For Components:**
```bash
# Search for similar React components
find apps/app/components -name "*.tsx" -type f | head -10

# Look for similar UI patterns
rg "export (default )?function|export const.*FC" apps/app/components/ | head -10

# Find similar form/input components
rg "useState|useForm|Controller" apps/app/components/ -l
```

**For Services:**
```bash
# Search for existing service patterns
find api/app/services -name "*.py" -type f

# Look for similar business logic
rg "class.*Service|async def.*_service" api/app/services/
```

**For Models:**
```bash
# Search for similar SQLAlchemy models
rg "class.*\(Base\)" api/app/models/

# Find field patterns
rg "Column\(|relationship\(" api/app/models/ -A 1
```

### Step 3: Verify REUSE Markers

If task has `REUSE:` markers:

```bash
# Extract REUSE files from task description
REUSE_FILES=$(echo "$TASK_DESC" | grep -o "REUSE:.*" | sed 's/REUSE: //')

# Verify each file exists
for file in $REUSE_FILES; do
  if [ ! -f "$file" ]; then
    echo "❌ REUSE file not found: $file"
    echo "   Update task or create the file first"
    exit 1
  else
    echo "✅ REUSE file exists: $file"
  fi
done
```

### Step 4: Present Findings to User

**If Similar Code Found:**

```markdown
🔍 **ANTI-DUPLICATION CHECK**

Before implementing, I found existing patterns you can reuse:

**Similar Implementations:**
1. api/app/api/v1/routers/study_plans.py (GET /study-plans/{id})
   - Pattern: FastAPI router with path parameter
   - Validation: Pydantic model dependency injection
   - Error handling: HTTPException with status codes

2. api/app/api/v1/routers/users.py (POST /users/)
   - Pattern: Create endpoint with validation
   - Database: SQLAlchemy async session
   - Response: Pydantic schema serialization

**REUSE Recommendations:**
- Copy router structure from study_plans.py
- Reuse validation pattern from users.py
- Follow error handling convention (404 for not found)

**Next Steps:**
1. Read the suggested files: Use Read tool
2. Copy the pattern and adapt for your use case
3. Import shared utilities instead of rewriting

Proceed with implementation? (yes/no)
```

**If REUSE Markers Not Verified:**

```markdown
⚠️  **REUSE VALIDATION FAILED**

Task specifies REUSE files, but they don't exist:

**Missing Files:**
❌ api/app/models/user.py (specified in task)

**Actions:**
1. Verify the REUSE path is correct
2. If file exists elsewhere, update the task
3. If file doesn't exist, remove REUSE marker or create it first

Cannot proceed until REUSE markers are valid.
```

---

## Implementation Guidelines

### When to Allow Implementation

**Green Light (Proceed):**
- User reviewed existing patterns and chose to adapt
- REUSE files verified and will be imported
- No duplicate logic found in search
- User explicitly approved after seeing duplicates

**Yellow Light (Suggest, then proceed):**
- Similar patterns found, but user wants custom implementation
- REUSE markers present and valid
- Existing code is outdated or doesn't fit use case

**Red Light (Block):**
- REUSE markers point to non-existent files
- User hasn't reviewed existing patterns when obvious duplicates exist
- Task description conflicts with existing implementation

### How to Present Options

```markdown
**Option A: Reuse existing pattern** (Recommended - faster, tested)
- Read: api/app/models/user.py
- Copy: Base model structure, validation patterns
- Adapt: Change fields for Message model
- Time: ~10 minutes

**Option B: Implement from scratch**
- Research: SQLAlchemy best practices
- Write: New model with validation
- Test: Create comprehensive test suite
- Time: ~45 minutes

Which approach do you prefer?
```

---

## Search Strategies by Domain

### Backend (FastAPI/Python)

**Endpoints:**
```bash
# Find similar HTTP methods
rg "@router\.(get|post|put|patch|delete)" api/app/api/v1/routers/

# Search for authentication patterns
rg "Depends.*current_user|get_current_user" api/app/

# Find validation examples
rg "def validate_|ValidationError" api/app/
```

**Services:**
```bash
# Search for service classes
rg "class.*Service" api/app/services/

# Find async patterns
rg "async def" api/app/services/ -A 2

# Look for error handling
rg "try:|except.*Exception" api/app/services/
```

**Models:**
```bash
# Find SQLAlchemy models
rg "class.*\(Base\)" api/app/models/

# Search for relationships
rg "relationship\(|ForeignKey\(" api/app/models/

# Find validation logic
rg "@validates|@hybrid_property" api/app/models/
```

### Frontend (React/TypeScript)

**Components:**
```bash
# Find functional components
rg "export (default )?function|export const.*FC<" apps/app/components/

# Search for hooks usage
rg "useState|useEffect|useQuery" apps/app/components/ -l

# Find form patterns
rg "useForm|Controller|Field" apps/app/components/
```

**Pages:**
```bash
# Find Next.js pages
find apps/app/pages -name "*.tsx" -type f

# Search for data fetching
rg "getServerSideProps|getStaticProps" apps/app/pages/

# Find API routes
find apps/app/pages/api -name "*.ts" -type f
```

**Hooks:**
```bash
# Find custom hooks
find apps/app/hooks -name "use*.ts" -type f

# Search for state management
rg "createContext|useContext" apps/app/

# Find API client hooks
rg "useQuery|useMutation" apps/app/hooks/
```

### Database (Migrations/Alembic)

**Migrations:**
```bash
# Find recent migrations
ls -lt api/alembic/versions/*.py | head -5

# Search for table creation
rg "create_table|op\.create" api/alembic/versions/

# Find column patterns
rg "sa\.Column\(|sa\.Integer|sa\.String" api/alembic/versions/
```

---

## Common Duplication Scenarios

### Scenario 1: CRUD Endpoints

**Before:**
User: "Create POST /api/v1/messages/ endpoint"

**Anti-Duplication Response:**
```markdown
🔍 Found 3 existing POST endpoints with similar patterns:

1. **POST /api/v1/study-plans/** (api/app/api/v1/routers/study_plans.py:45)
   - Validation: Pydantic schema
   - Database: SQLAlchemy create pattern
   - Response: 201 with created resource

2. **POST /api/v1/users/** (api/app/api/v1/routers/users.py:23)
   - Auth: Requires current_user dependency
   - Validation: Custom email validator
   - Error handling: 409 for duplicates

**Recommended REUSE:**
- Copy create pattern from study_plans.py
- Add auth dependency from users.py if needed
- Follow 201 response convention

Proceed with these patterns? (yes/no)
```

### Scenario 2: React Form Components

**Before:**
User: "Create MessageForm component"

**Anti-Duplication Response:**
```markdown
🔍 Found existing form components:

1. **StudyPlanForm.tsx** (apps/app/components/forms/StudyPlanForm.tsx)
   - react-hook-form integration
   - zod validation schema
   - Error display pattern
   - Submit handler with loading state

2. **UserProfileForm.tsx** (apps/app/components/forms/UserProfileForm.tsx)
   - Form field components
   - Accessibility labels
   - Success/error toast notifications

**Suggested Approach:**
1. Read StudyPlanForm.tsx for react-hook-form pattern
2. Copy validation and error handling
3. Reuse form field components from UserProfileForm
4. Adapt schema for message fields

This saves ~30 minutes of setup work.

Proceed with REUSE approach? (yes/no)
```

### Scenario 3: Service Layer Logic

**Before:**
User: "Create MessageService for sending messages"

**Anti-Duplication Response:**
```markdown
🔍 Found existing service patterns:

1. **study_plan_service.py** (api/app/services/study_plan_service.py)
   - Async database operations
   - Error handling with custom exceptions
   - Transaction management

2. **notification_service.py** (api/app/services/notification_service.py)
   - External API integration
   - Retry logic with exponential backoff
   - Logging pattern

**Key Patterns to REUSE:**
- Service class structure from study_plan_service.py
- Async context manager pattern
- Error handling conventions
- If sending external notifications, copy retry logic from notification_service.py

**Next Step:**
Read these files to understand the patterns, then implement MessageService following the same structure.

Ready to proceed? (yes/no)
```

---

## Integration with Spec-Flow Workflow

### During /implement Phase

When implementing tasks, this Skill should:

1. **Parse task description** to understand what's being built
2. **Extract REUSE markers** if present in tasks.md
3. **Search codebase** for similar patterns
4. **Present findings** to user with concrete examples
5. **Verify REUSE files** exist before proceeding
6. **Allow implementation** only after user reviews duplicates

### During /plan Phase

When planning implementation:

1. **Identify reusable components** from existing codebase
2. **Suggest REUSE markers** for tasks.md
3. **Estimate time savings** from reusing vs. building new
4. **Flag potential conflicts** with existing implementations

---

## Examples

### Example 1: Backend Endpoint with REUSE

**Task:**
```
T015 [GREEN→T014] Implement GET /api/v1/messages/{id} endpoint
REUSE: api/app/api/v1/routers/study_plans.py (GET pattern)
```

**Anti-Duplication Check:**
```markdown
✅ REUSE file verified: api/app/api/v1/routers/study_plans.py

Checking for duplicates...

🔍 Similar endpoint found:
- api/app/api/v1/routers/study_plans.py:get_study_plan()
  - Pattern: @router.get("/{id}")
  - Validation: UUID path parameter
  - Error: HTTPException 404 if not found
  - Response: Pydantic schema

**Recommended Implementation:**
1. Read study_plans.py:45-68 (get_study_plan function)
2. Copy router pattern and error handling
3. Adapt query for Message model
4. Return MessageSchema response

Estimated time: ~15 minutes (vs. ~45 from scratch)

Proceed? (yes)
```

### Example 2: React Component without REUSE

**Task:**
```
T022 [P] Create MessageList component to display messages
```

**Anti-Duplication Check:**
```markdown
No REUSE marker found. Searching for similar components...

🔍 Found 2 list components:

1. **StudyPlanList.tsx** (apps/app/components/lists/StudyPlanList.tsx)
   - Pattern: map() over items array
   - Loading state: Skeleton components
   - Empty state: EmptyState component
   - Pagination: useQuery with page param

2. **NotificationList.tsx** (apps/app/components/lists/NotificationList.tsx)
   - Pattern: Virtualized list (react-window)
   - Real-time updates: useSubscription hook
   - Item actions: Delete/mark read

**Questions:**
1. Will this list be paginated? → Use StudyPlanList pattern
2. Does it need real-time updates? → Add useSubscription from NotificationList
3. How many items expected? → If >100, use virtualization

**Recommendation:**
Start with StudyPlanList.tsx pattern, add real-time if needed.

Add REUSE marker to task? (yes/no)
```

---

## Anti-Duplication Rules

1. **Always search before implementing** (endpoints, components, services, models)
2. **Verify REUSE markers** point to existing files
3. **Present findings** before allowing user to proceed
4. **Suggest time savings** when reusing existing code
5. **Block implementation** if REUSE markers invalid
6. **Allow custom implementation** if user explicitly chooses after review

---

## Constraints

- **Read-only operations**: Use Glob, Grep, Read only (no file modifications)
- **Fast searches**: Limit results to top 5 matches
- **Relevant results**: Filter by file type and domain
- **Token efficiency**: Show file path + line range, not full file content
- **User decision**: Present options, let user choose approach

---

## Return Format

**Search Results:**
```markdown
🔍 ANTI-DUPLICATION SEARCH RESULTS

Task: {TASK_DESC}
Type: {TASK_TYPE}

**Existing Patterns Found:**
1. {FILE_PATH}:{LINE_RANGE}
   - Pattern: {PATTERN_DESCRIPTION}
   - REUSE: {WHAT_TO_COPY}

2. {FILE_PATH}:{LINE_RANGE}
   - Pattern: {PATTERN_DESCRIPTION}
   - REUSE: {WHAT_TO_COPY}

**Recommendation:**
{SUGGESTION_TO_REUSE_OR_BUILD_NEW}

**Time Estimate:**
- Reuse approach: ~{XX} minutes
- Build from scratch: ~{YY} minutes

Proceed with reuse? (yes/no)
```

**No Duplicates Found:**
```markdown
🔍 ANTI-DUPLICATION SEARCH RESULTS

Task: {TASK_DESC}
Type: {TASK_TYPE}

No similar implementations found. This appears to be a new pattern.

**Proceed with implementation** - No duplicates to avoid.
```

**REUSE Validation Failed:**
```markdown
❌ REUSE VALIDATION FAILED

Task specifies REUSE files that don't exist:
- {FILE_PATH} (not found)

**Actions:**
1. Verify path is correct
2. Update task with correct path
3. Remove REUSE marker if file doesn't exist

Cannot proceed until REUSE markers are fixed.
```
