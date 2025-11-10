# Project Documentation Integration

**Purpose**: Load all 8 project documentation files to understand constraints and established patterns before planning implementation.

**When to execute**: Always at the start of planning phase (Step 1.5)

---

## Project Documentation Files

**Location**: `docs/project/`

**Required reading** (8 files):
1. **overview.md** - Project vision, users, scope, success metrics
2. **system-architecture.md** - C4 diagrams, components, data flows
3. **tech-stack.md** - Technology choices with rationale
4. **data-architecture.md** - ERD, entity schemas, migrations
5. **api-strategy.md** - REST/GraphQL patterns, auth, versioning
6. **capacity-planning.md** - Scale tier, performance targets
7. **deployment-strategy.md** - CI/CD, environments, rollback
8. **development-workflow.md** - Git flow, PR process, testing

---

## Loading Strategy

### If Project Docs Exist

```bash
PROJECT_DOCS_DIR="docs/project"

if [ -d "$PROJECT_DOCS_DIR" ]; then
  echo "✅ Project documentation found"

  # Read all 8 files
  for doc in overview system-architecture tech-stack data-architecture \
             api-strategy capacity-planning deployment-strategy development-workflow; do
    if [ -f "$PROJECT_DOCS_DIR/$doc.md" ]; then
      echo "Reading $doc.md..."
      # Claude Code: Read docs/project/$doc.md
    fi
  done
else
  echo "⚠️  No project documentation - run /init-project first"
fi
```

### Extract Key Constraints

From **tech-stack.md**:
- Backend framework (FastAPI, Django, Express)
- Frontend framework (Next.js, React, Vue)
- Database (PostgreSQL, MySQL, MongoDB)
- ORM (Prisma, SQLAlchemy, TypeORM)

From **api-strategy.md**:
- API style (REST, GraphQL, tRPC)
- Auth provider (Clerk, Auth0, custom)
- Versioning strategy (URL, header)

From **data-architecture.md**:
- Existing entities and schemas
- Naming conventions
- Migration tool

---

## Benefits

**Prevents**:
- ❌ Suggesting wrong technologies (Django when FastAPI documented)
- ❌ Violating naming conventions
- ❌ Creating duplicate entities

**Ensures**:
- ✅ Alignment with documented architecture
- ✅ Consistent technology choices
- ✅ Schema reuse and extension

**See [../reference.md](../reference.md#project-docs) for detailed extraction examples**
