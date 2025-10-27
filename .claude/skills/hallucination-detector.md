---
name: hallucination-detector
description: "Detect and prevent hallucinated technical decisions during feature work. Auto-trigger when suggesting technologies, frameworks, APIs, database schemas, or external services. Validates all tech decisions against docs/project/tech-stack.md (single source of truth). Blocks suggestions that violate documented architecture. Requires evidence/citation for all technical choices. Prevents: wrong tech stack, duplicate entities, fake APIs, incompatible versions."
allowed-tools: Read, Grep
---

# Hallucination Detector: Technical Decision Validator

**Purpose**: Prevent hallucinated technical decisions by enforcing evidence-based recommendations from project documentation.

**Philosophy**: "Every technical decision must cite a source. If you can't cite it, you're probably hallucinating."

---

## When to Trigger

**Auto-invoke when detecting these patterns**:

### Technology Suggestions
- "use [framework]"
- "suggest using [library]"
- "install [package]"
- "should we use [tech]?"
- "let's use [database]"

### API Design
- "create endpoint"
- "design API"
- "add REST/GraphQL endpoint"
- "external API integration"

### Database Schema
- "create table"
- "add entity"
- "new model"
- "database schema"

### External Services
- "integrate with [service]"
- "use [third-party API]"
- "connect to [external system]"

---

## Validation Checklist

### Check 1: Tech Stack Validation

**Before suggesting ANY technology:**

```bash
# 1. Check if project docs exist
if [ ! -f "docs/project/tech-stack.md" ]; then
  echo "⚠️  WARNING: No tech-stack.md found"
  echo "   Proceeding without tech stack validation (high hallucination risk)"
  echo "   Strongly recommend: /init-project to document tech stack"
  return
fi

# 2. Extract suggested technology from user request/task
# Example: User says "let's use Django for the backend"
SUGGESTED_TECH="Django"
TECH_TYPE="backend" # or "frontend", "database", etc.

# 3. Read documented tech stack
DOCUMENTED_TECH=$(grep -A 1 "| Backend" docs/project/tech-stack.md | tail -1 | awk '{print $3}')

# 4. Compare suggested vs documented
if [ "$SUGGESTED_TECH" != "$DOCUMENTED_TECH" ]; then
  echo "❌ HALLUCINATION DETECTED: Tech stack violation"
  echo ""
  echo "   Suggested: $SUGGESTED_TECH"
  echo "   Documented: $DOCUMENTED_TECH (tech-stack.md:13)"
  echo ""
  echo "   This is likely a hallucination - you suggested tech not in the project docs."
  echo ""
  echo "   Options:"
  echo "   A) Use documented tech: $DOCUMENTED_TECH"
  echo "   B) If migrating tech stack, update tech-stack.md FIRST, then implement"
  echo "   C) Explain why different tech is needed (with evidence)"
  echo ""
  return 1
fi

echo "✅ Tech stack validated: $SUGGESTED_TECH matches docs (tech-stack.md:13)"
```

**Example Violations**:

| Suggested | Documented | Verdict | Reason |
|-----------|-----------|---------|--------|
| Django | FastAPI | ❌ BLOCK | Hallucinated - wrong framework |
| MongoDB | PostgreSQL | ❌ BLOCK | Hallucinated - wrong database |
| Vue | Next.js | ❌ BLOCK | Hallucinated - wrong frontend |
| Express | FastAPI | ❌ BLOCK | Hallucinated - different lang/framework |

**Example Valid**:
| Suggested | Documented | Verdict | Reason |
|-----------|-----------|---------|--------|
| FastAPI | FastAPI | ✅ PASS | Matches documented backend |
| PostgreSQL | PostgreSQL | ✅ PASS | Matches documented database |
| Next.js | Next.js | ✅ PASS | Matches documented frontend |

---

### Check 2: Entity Duplication Validation

**Before creating ANY database entity:**

```bash
# 1. Check if data-architecture.md exists
if [ ! -f "docs/project/data-architecture.md" ]; then
  echo "⚠️  WARNING: No data-architecture.md found"
  echo "   Proceeding without entity validation (risk of duplication)"
  return
fi

# 2. Extract proposed entity name from user request/task
# Example: User says "create User table"
PROPOSED_ENTITY="User"

# 3. Read existing entities from ERD
EXISTING_ENTITIES=$(grep -oP '(?<=erDiagram\n)(.*?)(?=```)' docs/project/data-architecture.md -z | grep -oP '[A-Z_]+(?= \{)')

# 4. Check for duplicates (case-insensitive)
if echo "$EXISTING_ENTITIES" | grep -qi "^${PROPOSED_ENTITY}$"; then
  echo "❌ HALLUCINATION DETECTED: Duplicate entity"
  echo ""
  echo "   Proposed entity: $PROPOSED_ENTITY"
  echo "   Existing entities: $EXISTING_ENTITIES"
  echo ""
  echo "   This is hallucination - entity already exists in data-architecture.md"
  echo ""
  echo "   Options:"
  echo "   A) Reuse existing $PROPOSED_ENTITY entity (add fields if needed)"
  echo "   B) Extend with new entity (e.g., UserProfile, UserSettings)"
  echo "   C) Verify entity doesn't exist and update data-architecture.md"
  echo ""
  grep -A 10 "${PROPOSED_ENTITY} {" docs/project/data-architecture.md
  echo ""
  return 1
fi

echo "✅ Entity validated: $PROPOSED_ENTITY does not exist (new entity allowed)"
```

**Example Violations**:

| Proposed Entity | Existing Entities | Verdict | Fix |
|----------------|-------------------|---------|-----|
| User | USER, STUDENT, LESSON | ❌ BLOCK | Reuse USER |
| Student | USER, STUDENT, LESSON | ❌ BLOCK | Reuse STUDENT |
| users | USER, STUDENT, LESSON | ❌ BLOCK | Reuse USER (case-insensitive match) |
| Lesson | USER, STUDENT, LESSON | ❌ BLOCK | Reuse LESSON |

**Example Valid**:
| Proposed Entity | Existing Entities | Verdict | Reason |
|----------------|-------------------|---------|--------|
| Progress | USER, STUDENT, LESSON | ✅ PASS | New entity, no duplication |
| Certificate | USER, STUDENT, LESSON | ✅ PASS | New entity |

---

### Check 3: API Pattern Validation

**Before creating ANY API endpoint:**

```bash
# 1. Check if api-strategy.md exists
if [ ! -f "docs/project/api-strategy.md" ]; then
  echo "⚠️  WARNING: No api-strategy.md found"
  echo "   Proceeding without API pattern validation"
  return
fi

# 2. Extract proposed endpoint from user request
# Example: User says "create /students endpoint"
PROPOSED_ENDPOINT="/students"

# 3. Read documented API patterns
API_STYLE=$(grep -A 1 "## API Style" docs/project/api-strategy.md | tail -1 | grep -oP '(REST|GraphQL|tRPC|gRPC)')
VERSIONING=$(grep -oP '/api/v[0-9]+/' docs/project/api-strategy.md | head -1)
AUTH_PROVIDER=$(grep -A 1 "## Authentication" docs/project/api-strategy.md | tail -1 | grep -oP '(Clerk|Auth0|Supabase|Firebase|JWT)')

# 4. Validate endpoint against patterns
# Check 4a: Versioning prefix
if [ -n "$VERSIONING" ]; then
  if [[ ! "$PROPOSED_ENDPOINT" =~ $VERSIONING ]]; then
    echo "❌ HALLUCINATION DETECTED: API versioning violation"
    echo ""
    echo "   Proposed: $PROPOSED_ENDPOINT"
    echo "   Required prefix: $VERSIONING (api-strategy.md:15)"
    echo ""
    echo "   Fix: $VERSIONING$PROPOSED_ENDPOINT"
    echo ""
    return 1
  fi
fi

# Check 4b: API style consistency
if [ "$API_STYLE" = "GraphQL" ]; then
  if [[ "$PROPOSED_ENDPOINT" =~ ^/[a-z]+ ]]; then
    echo "❌ HALLUCINATION DETECTED: API style violation"
    echo ""
    echo "   Proposed: $PROPOSED_ENDPOINT (REST-style)"
    echo "   Documented: GraphQL (api-strategy.md:8)"
    echo ""
    echo "   For GraphQL, use queries/mutations, not REST endpoints"
    echo ""
    return 1
  fi
fi

# Check 4c: Auth pattern
if [ "$AUTH_PROVIDER" = "Clerk" ]; then
  echo "ℹ️  Auth reminder: Use Clerk middleware (api-strategy.md:23)"
  echo "   Example: @require_auth decorator or Clerk JWT validation"
fi

echo "✅ API pattern validated: Follows $API_STYLE with $VERSIONING prefix"
```

**Example Violations**:

| Proposed | API Style | Versioning | Verdict | Fix |
|----------|-----------|-----------|---------|-----|
| /students | REST | /api/v1/ | ❌ BLOCK | Use /api/v1/students |
| /api/v2/students | REST | /api/v1/ | ⚠️ WARN | Wrong version (v2 not documented) |
| /students | GraphQL | N/A | ❌ BLOCK | Use GraphQL query, not REST |

---

### Check 4: External Service Validation

**Before integrating with ANY external service:**

```bash
# 1. Check if system-architecture.md exists
if [ ! -f "docs/project/system-architecture.md" ]; then
  echo "⚠️  WARNING: No system-architecture.md found"
  echo "   Proceeding without external service validation"
  return
fi

# 2. Extract proposed service from user request
# Example: User says "integrate with Stripe"
PROPOSED_SERVICE="Stripe"

# 3. Read documented external systems from C4 diagram
EXTERNAL_SYSTEMS=$(grep -oP 'System_Ext\([^,]+, "\K[^"]+' docs/project/system-architecture.md)

# 4. Check if service is documented
if ! echo "$EXTERNAL_SYSTEMS" | grep -qi "$PROPOSED_SERVICE"; then
  echo "⚠️  HALLUCINATION WARNING: Undocumented external service"
  echo ""
  echo "   Proposed: $PROPOSED_SERVICE"
  echo "   Documented services: $EXTERNAL_SYSTEMS"
  echo ""
  echo "   This service is not in system-architecture.md C4 diagram."
  echo ""
  echo "   Options:"
  echo "   A) Add $PROPOSED_SERVICE to system-architecture.md FIRST"
  echo "   B) Verify this integration is actually needed"
  echo "   C) Use documented service instead"
  echo ""
  read -p "Proceed with undocumented service? (y/N): " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    return 1
  fi
fi

echo "✅ External service validated: $PROPOSED_SERVICE is documented"
```

**Example External Systems** (from system-architecture.md):
- Clerk (Authentication)
- Stripe (Payments)
- Vercel (Hosting)
- Railway (Backend hosting)
- PostgreSQL (Database)

**Hallucination Examples**:
- ❌ "Let's use Auth0" (but Clerk is documented)
- ❌ "Integrate with PayPal" (but Stripe is documented)
- ❌ "Use AWS S3" (but no object storage documented)

---

### Check 5: Version Compatibility Validation

**Before suggesting package versions:**

```bash
# 1. Check if tech-stack.md documents versions
DOCUMENTED_VERSION=$(grep -A 1 "| Next.js" docs/project/tech-stack.md | tail -1 | awk '{print $4}')

# 2. Extract suggested version from user request
# Example: User says "upgrade to Next.js 15"
SUGGESTED_VERSION="15.x"

# 3. Validate compatibility
if [ -n "$DOCUMENTED_VERSION" ]; then
  MAJOR_DOCUMENTED=$(echo "$DOCUMENTED_VERSION" | cut -d. -f1)
  MAJOR_SUGGESTED=$(echo "$SUGGESTED_VERSION" | cut -d. -f1)

  if [ "$MAJOR_DOCUMENTED" != "$MAJOR_SUGGESTED" ]; then
    echo "⚠️  HALLUCINATION WARNING: Major version mismatch"
    echo ""
    echo "   Suggested: Next.js $SUGGESTED_VERSION"
    echo "   Documented: Next.js $DOCUMENTED_VERSION (tech-stack.md:12)"
    echo ""
    echo "   Major version upgrade requires:"
    echo "   1. Review breaking changes"
    echo "   2. Update tech-stack.md"
    echo "   3. Test thoroughly"
    echo ""
    read -p "Proceed with major upgrade? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
      return 1
    fi
  fi
fi

echo "✅ Version compatible: $SUGGESTED_VERSION"
```

---

## Evidence Requirement

**EVERY technical decision MUST cite a source:**

### Valid Citations

**From project docs** (preferred):
```
"Using PostgreSQL per tech-stack.md:14"
"Clerk authentication per api-strategy.md:23"
"Reusing Student entity from data-architecture.md:45"
"Following /api/v1/ versioning per api-strategy.md:15"
```

**From codebase scan** (brownfield):
```
"Detected Next.js 14.2.3 from package.json:5"
"Existing User model found at api/models/user.py:12"
"Current auth: Clerk middleware (api/middleware/auth.py:8)"
```

**From user requirements** (explicit):
```
"User requested Django (from questionnaire Q8)"
"User specified PostgreSQL in /init-project"
```

**From reasonable defaults** (last resort):
```
"PostgreSQL recommended for relational data (industry standard)"
"REST API recommended for simple CRUD (common pattern)"
```

### Invalid (Hallucination)

**No citation**:
```
❌ "Using MongoDB" (why? no source)
❌ "Let's use Express" (not documented anywhere)
❌ "Create User table" (doesn't check for duplicates)
```

**Made-up citations**:
```
❌ "Using MongoDB per tech-stack.md" (but tech-stack.md says PostgreSQL)
❌ "Clerk is documented" (but no docs exist)
```

**Assumption without verification**:
```
❌ "The app probably uses React Router" (needs to grep codebase)
❌ "I think we use Auth0" (needs to read api-strategy.md)
```

---

## Auto-Fix Suggestions

**When hallucination detected, suggest fixes:**

### Tech Stack Violation
```
❌ Detected: Suggesting Django
✅ Fix: Use FastAPI (per tech-stack.md:13)

Suggested code:
```python
# Before (hallucinated)
from django.db import models

# After (correct)
from fastapi import FastAPI
app = FastAPI()
```

### Duplicate Entity
```
❌ Detected: Creating new User table
✅ Fix: Reuse existing USER entity (data-architecture.md:45)

Suggested approach:
1. Read api/models/user.py to see existing fields
2. Add new fields if needed (migration)
3. Reuse existing entity, don't recreate
```

### API Pattern Violation
```
❌ Detected: /students endpoint
✅ Fix: /api/v1/students (per api-strategy.md:15)

Suggested code:
```python
# Before (hallucinated)
@router.get("/students")

# After (correct)
@router.get("/api/v1/students")
```

---

## Integration with Other Skills

### With project-docs-integration
```bash
# project-docs-integration extracts constraints
# hallucination-detector validates against constraints

# 1. Load constraints
source .claude/skills/project-docs-integration.md

# 2. Validate technical decisions
source .claude/skills/hallucination-detector.md
validate_tech_stack "$SUGGESTED_TECH" "$TECH_TYPE"
validate_entity_duplication "$PROPOSED_ENTITY"
validate_api_pattern "$PROPOSED_ENDPOINT"
```

### With anti-duplication
```bash
# anti-duplication finds existing code
# hallucination-detector validates against documented architecture

# Both skills prevent duplication but different scopes:
# - anti-duplication: code-level (files, functions, components)
# - hallucination-detector: architecture-level (tech stack, entities, APIs)
```

---

## Performance Impact

**Token Overhead**: ~1-2K tokens per validation check

**Optimization**:
- Cache project docs constraints (reuse across validations)
- Only validate when technical decision is being made
- Skip validation if no project docs exist (warn instead)

**Expected Duration**: < 5 seconds per check

---

## Error Handling

**Missing Project Docs**:
```bash
if [ ! -d "docs/project" ]; then
  echo "⚠️  WARNING: Hallucination detection disabled (no project docs)"
  echo "   Running without architecture validation"
  echo "   Strongly recommend: /init-project to enable validation"
  return 0 # Don't fail, just warn
fi
```

**Malformed Docs**:
```bash
if ! grep -q "| Backend" docs/project/tech-stack.md; then
  echo "⚠️  WARNING: tech-stack.md missing expected format"
  echo "   Hallucination detection may be incomplete"
  # Continue with partial validation
fi
```

---

## Quality Checklist

Before allowing technical decision:

- [ ] Tech stack validated against tech-stack.md
- [ ] Entity checked for duplication in data-architecture.md
- [ ] API pattern validated against api-strategy.md
- [ ] External service validated against system-architecture.md
- [ ] Version compatibility checked
- [ ] Source cited for technical decision
- [ ] If hallucination detected, user offered fix options

---

## Common Hallucination Patterns

**Pattern 1: Default to Popular Tech**
- ❌ Hallucination: "Let's use React" (defaults to popular choice)
- ✅ Correct: "Using Next.js per tech-stack.md:12"

**Pattern 2: Assume Standard Patterns**
- ❌ Hallucination: "Create User model" (assumes every app has User)
- ✅ Correct: "Check data-architecture.md first → USER exists, reuse it"

**Pattern 3: Invent External Services**
- ❌ Hallucination: "Integrate with SendGrid for emails" (not documented)
- ✅ Correct: "Check system-architecture.md → no email service documented, add SendGrid to C4 diagram first"

**Pattern 4: Guess Versions**
- ❌ Hallucination: "Use Next.js 15 (latest)" (doesn't check current version)
- ✅ Correct: "Check tech-stack.md → Next.js 14.2.x, major upgrade requires planning"

---

## References

- **Project Docs Integration Skill**: `.claude/skills/project-docs-integration.md`
- **Anti-Duplication Skill**: `.claude/skills/anti-duplication.md`
- **Tech Stack Template**: `.spec-flow/templates/project/tech-stack-template.md`
- **Data Architecture Template**: `.spec-flow/templates/project/data-architecture-template.md`
