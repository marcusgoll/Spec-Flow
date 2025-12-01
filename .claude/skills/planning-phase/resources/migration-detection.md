# Migration Detection Reference

> Patterns and algorithms for detecting database schema changes from feature specs.

---

## Overview

Migration detection runs during the `/plan` phase to identify features that require database changes. Early detection ensures migration tasks are generated before implementation begins, preventing the common failure where tests run against an outdated schema.

---

## Detection Layers

### Layer 1: Pattern Matching (Fast, High Recall)

Scan spec.md for schema-change indicator keywords. If 3+ indicators found, migration detection confidence is HIGH.

#### Entity Keywords (1 point each)
```
store, persist, save, record, track, log, keep
create table, add column, new entity, new model
user profile, settings, preferences, history
table, column, field, schema, migration, database
```

#### Relationship Keywords (1 point each)
```
belongs to, has many, has one, one-to-many, many-to-many
foreign key, reference, link, associate, relate
parent, child, owner, owned by
```

#### Data Type Keywords (1 point each)
```
timestamp, datetime, date, boolean flag, enum, enumeration
JSON, JSONB, array, list of, set of
unique identifier, primary key, UUID, ID
integer, decimal, money, currency
text, varchar, string, blob, binary
```

#### Action Keywords (2 points each - higher confidence)
```
add X to Y, store X in database, persist X
track user's X, record when X happens
save to database, write to table
```

#### Scoring Algorithm
```python
def calculate_migration_confidence(spec_content):
    entity_count = count_matches(spec_content, ENTITY_KEYWORDS)
    relationship_count = count_matches(spec_content, RELATIONSHIP_KEYWORDS)
    datatype_count = count_matches(spec_content, DATATYPE_KEYWORDS)
    action_count = count_matches(spec_content, ACTION_KEYWORDS) * 2  # weighted

    total_score = entity_count + relationship_count + datatype_count + action_count

    if total_score >= 5:
        return {"needs_migration": True, "confidence": "high"}
    elif total_score >= 3:
        return {"needs_migration": True, "confidence": "medium"}
    elif total_score >= 1:
        return {"needs_migration": "maybe", "confidence": "low"}
    else:
        return {"needs_migration": False, "confidence": "high"}
```

---

### Layer 2: LLM Analysis (High Precision)

After pattern matching suggests database changes, use LLM analysis to:

1. **Confirm** schema changes are actually required
2. **Extract** specific entities/tables needed
3. **Identify** relationships between entities
4. **Classify** changes as additive vs breaking

#### LLM Prompt Template
```xml
<task>
Analyze this feature specification for database schema requirements.
</task>

<spec>
{spec_content}
</spec>

<existing_schema>
{data_architecture_md_content}
</existing_schema>

<questions>
1. Does this feature require NEW database tables? List them.
2. Does this feature require MODIFICATIONS to existing tables? List changes.
3. Are any changes BREAKING (column drops, renames, type changes)?
4. What relationships (foreign keys) are needed?
5. What indexes would improve query performance?
</questions>

<output_format>
{
  "needs_migration": true|false,
  "new_tables": [{"name": "...", "columns": [...], "relationships": [...]}],
  "modified_tables": [{"name": "...", "changes": [...]}],
  "breaking_changes": [{"table": "...", "change": "...", "impact": "..."}],
  "indexes": [{"table": "...", "columns": [...], "reason": "..."}]
}
</output_format>
```

---

## Integration Points

### Input Sources

1. **spec.md** (or epic-spec.md) - Feature requirements
2. **docs/project/data-architecture.md** - Existing schema ERD
3. **docs/project/tech-stack.md** - Database type (PostgreSQL, MySQL, etc.)
4. **package.json / requirements.txt** - Migration framework detection

### Output Artifacts

1. **migration-plan.md** - Detailed migration plan (if changes detected)
2. **state.yaml** - `has_migrations: true` flag
3. **plan.md** - Updated with Data Model section

---

## Framework Detection

Detect migration framework from project files:

### Alembic (Python)
```bash
# Check for Alembic indicators
[ -f "alembic.ini" ] ||
[ -f "api/alembic.ini" ] ||
[ -d "alembic/versions" ] ||
[ -d "api/alembic/versions" ] ||
grep -q "alembic" requirements.txt 2>/dev/null ||
grep -q "alembic" pyproject.toml 2>/dev/null
```

### Prisma (TypeScript/Node.js)
```bash
# Check for Prisma indicators
[ -f "prisma/schema.prisma" ] ||
[ -f "apps/web/prisma/schema.prisma" ] ||
grep -q '"prisma"' package.json 2>/dev/null ||
grep -q '"@prisma/client"' package.json 2>/dev/null
```

### Other Frameworks
```bash
# Knex.js
grep -q '"knex"' package.json 2>/dev/null

# Flyway
[ -f "flyway.conf" ] || [ -d "sql/migrations" ]

# Django
grep -q "django" requirements.txt 2>/dev/null && [ -d "*/migrations" ]

# Rails
[ -f "Gemfile" ] && grep -q "activerecord" Gemfile && [ -d "db/migrate" ]
```

---

## Example Detections

### Example 1: Clear Migration Needed
```markdown
## Requirements
- Users can create study plans
- Each study plan has multiple sessions
- Track completion status for each session
```

**Detection Result**:
- Keywords found: "create", "has multiple", "track", "status"
- Score: 4 (medium-high confidence)
- Entities: study_plans, sessions
- Relationships: study_plans has_many sessions

### Example 2: No Migration Needed
```markdown
## Requirements
- Add loading spinner to dashboard
- Improve error messages for API failures
```

**Detection Result**:
- Keywords found: 0
- Score: 0 (high confidence - no migration)
- UI-only changes

### Example 3: Ambiguous (Needs LLM)
```markdown
## Requirements
- Users should see their recently viewed items
```

**Detection Result**:
- Keywords found: "recently viewed" (maybe "track"?)
- Score: 1 (low confidence)
- **Requires LLM analysis**: Could be client-side storage OR new database table

---

## Breaking Change Detection

### Automatic Breaking Change Flags

| Change Type | Breaking | Safe Alternative |
|-------------|----------|------------------|
| DROP COLUMN | Yes | Archive column, deprecate |
| RENAME COLUMN | Yes | Add new column, dual-write |
| MODIFY TYPE (narrowing) | Yes | Add new column, migrate |
| DROP TABLE | Yes | Archive, soft-delete |
| REMOVE NULLABLE | Maybe | Backfill first, then constrain |
| ADD NOT NULL (no default) | Yes | Add with default, then remove |

### Safe (Non-Breaking) Changes

| Change Type | Safe | Notes |
|-------------|------|-------|
| ADD COLUMN (nullable) | Yes | Default to NULL |
| ADD COLUMN (with default) | Yes | Backfill automatic |
| ADD INDEX | Yes | May lock table briefly |
| ADD TABLE | Yes | No existing data affected |
| ADD RELATIONSHIP | Yes | If nullable FK |

---

## Configuration

Detection behavior can be configured in `user-preferences.yaml`:

```yaml
migrations:
  # Detection sensitivity
  detection_threshold: 3  # Minimum keyword score to trigger

  # Auto-generate migration-plan.md
  auto_generate_plan: true

  # LLM analysis for low-confidence detections
  llm_analysis_for_low_confidence: true
```

---

## Scripts

### Detection Script
```bash
.spec-flow/scripts/bash/check-migration-status.sh [--json] [--verbose]
```

### Usage in /plan
```bash
# Step 0.5: Migration Detection
SPEC_FILE="${BASE_DIR}/${SLUG}/spec.md"
MIGRATION_RESULT=$(bash .spec-flow/scripts/bash/detect-schema-changes.sh "$SPEC_FILE" --json)

if [ "$(echo "$MIGRATION_RESULT" | jq -r '.needs_migration')" = "true" ]; then
    # Generate migration-plan.md
    # Set HAS_MIGRATIONS=true in state.yaml
fi
```

---

*Reference document for Spec-Flow planning phase migration detection*
