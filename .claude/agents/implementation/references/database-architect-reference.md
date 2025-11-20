# Database Architect Agent - Reference Documentation

Complete reference for database schema design, migration safety, zero-downtime patterns, data validation, query optimization, and rollback procedures.

## Table of Contents

1. [Zero-Downtime Migration Patterns](#zero-downtime-migration-patterns)
2. [Migration Design Workflow](#migration-design-workflow)
3. [Data Validation Strategies](#data-validation-strategies)
4. [Rollback Planning](#rollback-planning)
5. [Schema Naming Conventions](#schema-naming-conventions)
6. [Index Strategy](#index-strategy)
7. [Query Performance Optimization](#query-performance-optimization)
8. [Migration Testing Protocol](#migration-testing-protocol)
9. [ORM Coordination](#orm-coordination)
10. [Common Migration Patterns](#common-migration-patterns)
11. [Error Handling](#error-handling)

---

## Zero-Downtime Migration Patterns

**Goal**: Apply schema changes without service interruption or data loss.

### Pattern 1: Add Nullable Column

**Scenario**: Add new column to existing table

**Steps**:
1. Add column as nullable (no default)
2. Deploy application code that handles null values
3. Backfill data
4. Make column non-nullable (if required)

**Migration up**:
```python
# Migration 001: Add nullable column
def upgrade():
    op.add_column('users', sa.Column('profile_url', sa.String(), nullable=True))

# Migration 002: Backfill data (separate migration)
def upgrade():
    # Backfill in batches to avoid locks
    connection = op.get_bind()
    connection.execute("""
        UPDATE users
        SET profile_url = 'https://example.com/default.jpg'
        WHERE profile_url IS NULL
        LIMIT 1000
    """)

# Migration 003: Make non-nullable (after backfill complete)
def upgrade():
    op.alter_column('users', 'profile_url', nullable=False)
```

**Migration down**:
```python
# Migration 003 rollback
def downgrade():
    op.alter_column('users', 'profile_url', nullable=True)

# Migration 002 rollback
def downgrade():
    # No-op for backfill rollback
    pass

# Migration 001 rollback
def downgrade():
    op.drop_column('users', 'profile_url')
```

### Pattern 2: Rename Column

**Scenario**: Rename `user_id` to `userId` without downtime

**Steps**:
1. Add new column `userId` (nullable)
2. Deploy dual-write code (writes to both columns)
3. Backfill new column from old column
4. Deploy read-from-new code
5. Drop old column

**Migration 001: Add new column**:
```python
def upgrade():
    op.add_column('posts', sa.Column('userId', sa.Integer(), nullable=True))
    op.create_foreign_key('fk_posts_userId', 'posts', 'users', ['userId'], ['id'])

def downgrade():
    op.drop_constraint('fk_posts_userId', 'posts')
    op.drop_column('posts', 'userId')
```

**Migration 002: Backfill**:
```python
def upgrade():
    op.execute("UPDATE posts SET userId = user_id WHERE userId IS NULL")

def downgrade():
    # No-op
    pass
```

**Migration 003: Make non-nullable**:
```python
def upgrade():
    op.alter_column('posts', 'userId', nullable=False)

def downgrade():
    op.alter_column('posts', 'userId', nullable=True)
```

**Migration 004: Drop old column** (after new code deployed):
```python
def upgrade():
    op.drop_constraint('fk_posts_user_id', 'posts')
    op.drop_column('posts', 'user_id')

def downgrade():
    op.add_column('posts', sa.Column('user_id', sa.Integer(), nullable=False))
    op.create_foreign_key('fk_posts_user_id', 'posts', 'users', ['user_id'], ['id'])
```

### Pattern 3: Change Column Type

**Scenario**: Change `user_id` from String to Integer

**Steps**:
1. Add new column with target type
2. Dual-write to both columns
3. Backfill new column
4. Switch reads to new column
5. Drop old column

**Migration**:
```python
def upgrade():
    # Add new column
    op.add_column('sessions', sa.Column('user_id_int', sa.Integer(), nullable=True))

    # Backfill (cast string to int)
    op.execute("""
        UPDATE sessions
        SET user_id_int = CAST(user_id AS INTEGER)
        WHERE user_id ~ '^[0-9]+$'
    """)

    # Create index on new column
    op.create_index('ix_sessions_user_id_int', 'sessions', ['user_id_int'])

def downgrade():
    op.drop_index('ix_sessions_user_id_int', 'sessions')
    op.drop_column('sessions', 'user_id_int')
```

---

## Migration Design Workflow

### Phase 1: Read Context

**Required inputs**:
- Task description from `tasks.md`
- Data model from `plan.md`
- Existing schema from `data-architecture.md`
- Existing migrations directory (e.g., `api/alembic/versions/`)

**Context loading**:
```bash
# Read task
cat specs/001-feature/tasks.md | grep -A 10 "T003"

# Read data model
cat specs/001-feature/plan.md | grep -A 50 "## Data Model"

# Check existing schema
cat docs/project/data-architecture.md | grep -A 20 "## ERD"

# List existing migrations
ls -l api/alembic/versions/
```

### Phase 2: Design Migration

**Checklist**:
- [ ] Reversible (up/down functions defined)
- [ ] Zero-downtime pattern (nullable → backfill → non-nullable)
- [ ] Indexes for foreign keys
- [ ] Indexes for frequently queried fields
- [ ] Data validation queries
- [ ] Rollback plan documented

**Migration template** (Alembic):
```python
"""Add user profiles table

Revision ID: 001_add_user_profiles
Revises: 000_initial
Create Date: 2025-11-20 10:00:00.000000
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = '001_add_user_profiles'
down_revision = '000_initial'
branch_labels = None
depends_on = None

def upgrade():
    # Create table
    op.create_table(
        'user_profiles',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('bio', sa.Text(), nullable=True),
        sa.Column('avatar_url', sa.String(255), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(), onupdate=sa.func.now())
    )

    # Create foreign key
    op.create_foreign_key(
        'fk_user_profiles_user_id',
        'user_profiles', 'users',
        ['user_id'], ['id'],
        ondelete='CASCADE'
    )

    # Create indexes
    op.create_index('ix_user_profiles_user_id', 'user_profiles', ['user_id'], unique=True)

def downgrade():
    op.drop_index('ix_user_profiles_user_id', 'user_profiles')
    op.drop_constraint('fk_user_profiles_user_id', 'user_profiles')
    op.drop_table('user_profiles')
```

### Phase 3: Test Migration Cycle

**Testing procedure**:
```bash
# 1. Apply migration up
alembic upgrade head

# 2. Validate data integrity
psql -d mydb -c "SELECT COUNT(*) FROM user_profiles;"
psql -d mydb -c "SELECT * FROM user_profiles WHERE user_id NOT IN (SELECT id FROM users);"

# 3. Test rollback (downgrade)
alembic downgrade -1

# 4. Verify rollback (table should be gone)
psql -d mydb -c "\dt user_profiles"  # Should error: relation does not exist

# 5. Re-apply migration (idempotency check)
alembic upgrade head

# 6. Verify re-application successful
psql -d mydb -c "SELECT COUNT(*) FROM user_profiles;"
```

**Success criteria**:
- ✅ Migration up succeeds
- ✅ Data validation queries return 0 integrity violations
- ✅ Migration down succeeds (rollback works)
- ✅ Migration up succeeds again (idempotent)

---

## Data Validation Strategies

### Validation Query Templates

**Check for orphaned foreign keys**:
```sql
-- After creating user_profiles table
SELECT COUNT(*) AS orphaned_records
FROM user_profiles
WHERE user_id NOT IN (SELECT id FROM users);
-- Expected: 0
```

**Check for NULL values in non-nullable columns**:
```sql
-- After making column non-nullable
SELECT COUNT(*) AS null_values
FROM users
WHERE email IS NULL;
-- Expected: 0
```

**Check for duplicate values in unique columns**:
```sql
-- After adding unique constraint
SELECT email, COUNT(*) AS count
FROM users
GROUP BY email
HAVING COUNT(*) > 1;
-- Expected: 0 rows
```

**Check data type constraints**:
```sql
-- After changing column type
SELECT COUNT(*) AS invalid_values
FROM sessions
WHERE user_id_int IS NULL AND user_id IS NOT NULL;
-- Expected: 0 (all strings cast to int successfully)
```

### Validation Protocol

**Run after every migration**:
```bash
# 1. Row count check (data not lost)
BEFORE=$(psql -t -c "SELECT COUNT(*) FROM users")
# ... run migration ...
AFTER=$(psql -t -c "SELECT COUNT(*) FROM users")
if [ "$BEFORE" != "$AFTER" ]; then
  echo "❌ Data loss detected: $BEFORE → $AFTER"
  alembic downgrade -1
  exit 1
fi

# 2. Integrity checks
VIOLATIONS=$(psql -t -c "SELECT COUNT(*) FROM user_profiles WHERE user_id NOT IN (SELECT id FROM users)")
if [ "$VIOLATIONS" -gt 0 ]; then
  echo "❌ Foreign key violations: $VIOLATIONS"
  alembic downgrade -1
  exit 1
fi

# 3. Query performance check
EXPLAIN_OUTPUT=$(psql -c "EXPLAIN ANALYZE SELECT * FROM user_profiles WHERE user_id = 123")
if echo "$EXPLAIN_OUTPUT" | grep -q "Seq Scan"; then
  echo "⚠️  Sequential scan detected (missing index?)"
fi
```

---

## Rollback Planning

### Rollback Documentation Template

Document in migration file or `NOTES.md`:

```markdown
## Rollback Plan: Migration 001_add_user_profiles

**Deployment order**:
1. Deploy migration to staging
2. Validate data integrity (0 violations)
3. Deploy migration to production
4. Monitor for 24 hours

**Rollback steps** (if issues detected):

### Option 1: Alembic Rollback
```bash
# Rollback one migration
alembic downgrade -1

# Verify rollback
psql -c "\dt user_profiles"  # Should not exist
```

### Option 2: Manual Rollback (if Alembic unavailable)
```sql
-- Drop indexes first
DROP INDEX IF EXISTS ix_user_profiles_user_id;

-- Drop foreign keys
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS fk_user_profiles_user_id;

-- Drop table
DROP TABLE IF EXISTS user_profiles;
```

**Data recovery** (if needed):
- Backup taken: 2025-11-20 10:00 (before migration)
- Restore command: `pg_restore -d mydb backup_20251120.dump`

**Rollback window**: 7 days (backups retained)
```

### Pre-Deployment Checklist

Before production migration:
- [ ] Tested on local development database
- [ ] Tested on staging environment
- [ ] Backup created and verified (can restore)
- [ ] Rollback tested successfully
- [ ] Query performance verified (<50ms for critical queries)
- [ ] Data validation queries return 0 violations
- [ ] Deployment order documented
- [ ] Rollback steps documented
- [ ] On-call engineer notified

---

## Schema Naming Conventions

**Table names**:
- Plural, lowercase, snake_case: `user_profiles`, `study_plans`
- Avoid abbreviations: `sessions` not `sess`

**Column names**:
- Lowercase, snake_case: `created_at`, `user_id`
- Use consistent suffixes:
  - `_id` for foreign keys: `user_id`
  - `_at` for timestamps: `created_at`, `updated_at`
  - `_url` for URLs: `avatar_url`, `profile_url`
  - `_count` for counts: `view_count`, `like_count`

**Index names**:
- Format: `ix_{table}_{column(s)}`
- Example: `ix_user_profiles_user_id`
- Unique indexes: `uq_{table}_{column(s)}`

**Foreign key names**:
- Format: `fk_{table}_{column}`
- Example: `fk_user_profiles_user_id`

**Constraint names**:
- Check: `ck_{table}_{constraint_description}`
- Example: `ck_users_email_format`

---

## Index Strategy

### When to Add Indexes

**Always index**:
- Primary keys (automatic)
- Foreign keys (manual in most databases)
- Columns in WHERE clauses of frequent queries
- Columns in JOIN conditions
- Columns in ORDER BY clauses

**Example**:
```python
# Create table with indexes
op.create_table(
    'posts',
    sa.Column('id', sa.Integer(), primary_key=True),  # Auto-indexed
    sa.Column('user_id', sa.Integer(), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=False),
    sa.Column('status', sa.String(20), nullable=False)
)

# Index foreign key
op.create_index('ix_posts_user_id', 'posts', ['user_id'])

# Index for frequent query: "posts by user, ordered by date"
op.create_index('ix_posts_user_created', 'posts', ['user_id', 'created_at'])

# Index for status filter
op.create_index('ix_posts_status', 'posts', ['status'])
```

### Composite Indexes

**Rule**: Most selective column first

**Example**: Query `SELECT * FROM posts WHERE user_id = 123 AND status = 'published' ORDER BY created_at DESC`

**Good index**:
```python
# user_id most selective (filters to small subset)
op.create_index('ix_posts_user_status_created', 'posts', ['user_id', 'status', 'created_at'])
```

**Bad index**:
```python
# status least selective (many posts have same status)
op.create_index('ix_posts_status_user_created', 'posts', ['status', 'user_id', 'created_at'])
```

### Index Maintenance

**Avoid over-indexing**:
- Each index adds write overhead
- Maximum ~5-6 indexes per table
- Drop unused indexes after monitoring

**Check index usage**:
```sql
-- PostgreSQL
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY schemaname, tablename;
```

---

## Query Performance Optimization

### Query Analysis Workflow

1. **Identify slow query** (from application logs or monitoring)
2. **Run EXPLAIN ANALYZE**
3. **Identify bottleneck** (sequential scan, missing index, poor join)
4. **Apply fix** (add index, rewrite query)
5. **Verify improvement**

### EXPLAIN ANALYZE Example

**Slow query**:
```sql
SELECT * FROM posts WHERE user_id = 123;
```

**EXPLAIN ANALYZE**:
```sql
EXPLAIN ANALYZE SELECT * FROM posts WHERE user_id = 123;

-- Output (BAD - sequential scan):
Seq Scan on posts  (cost=0.00..1000.00 rows=10 width=100) (actual time=50.123..52.456 rows=10 loops=1)
  Filter: (user_id = 123)
  Rows Removed by Filter: 9990
Planning Time: 0.123 ms
Execution Time: 52.567 ms
```

**Add index**:
```python
op.create_index('ix_posts_user_id', 'posts', ['user_id'])
```

**EXPLAIN ANALYZE after index**:
```sql
EXPLAIN ANALYZE SELECT * FROM posts WHERE user_id = 123;

-- Output (GOOD - index scan):
Index Scan using ix_posts_user_id on posts  (cost=0.29..8.31 rows=10 width=100) (actual time=0.015..0.025 rows=10 loops=1)
  Index Cond: (user_id = 123)
Planning Time: 0.078 ms
Execution Time: 0.045 ms
```

### Performance Targets

- **Critical queries**: <50ms execution time
- **Non-critical queries**: <200ms execution time
- **Batch operations**: <5s execution time

### Common Query Optimizations

**N+1 Query Problem**:
```python
# BAD: N+1 queries
users = db.query(User).all()
for user in users:
    posts = db.query(Post).filter(Post.user_id == user.id).all()  # N queries

# GOOD: Eager loading
users = db.query(User).options(joinedload(User.posts)).all()  # 1 query
```

**Missing WHERE Clause**:
```sql
-- BAD: Full table scan
SELECT * FROM posts ORDER BY created_at DESC LIMIT 10;

-- GOOD: Add filter
SELECT * FROM posts WHERE status = 'published' ORDER BY created_at DESC LIMIT 10;
```

---

## Migration Testing Protocol

### Local Testing

**Before committing migration**:
```bash
# 1. Clean database (start fresh)
alembic downgrade base

# 2. Apply all migrations
alembic upgrade head

# 3. Run data validation
pytest tests/integration/test_migrations.py

# 4. Test rollback
alembic downgrade -1

# 5. Verify rollback
pytest tests/integration/test_schema.py

# 6. Re-apply
alembic upgrade head
```

### Staging Testing

**After deploying to staging**:
```bash
# 1. Apply migration
alembic upgrade head

# 2. Run application tests
pytest tests/integration/

# 3. Check query performance
psql -c "EXPLAIN ANALYZE SELECT * FROM user_profiles WHERE user_id = 123"

# 4. Monitor for 24 hours
# Check logs for errors, slow queries, integrity violations

# 5. If issues found: Rollback
alembic downgrade -1
```

### Production Deployment

**Deployment checklist**:
- [ ] Tested on staging for 24+ hours
- [ ] Backup created and verified
- [ ] Off-peak deployment window scheduled
- [ ] On-call engineer available
- [ ] Rollback plan documented and tested
- [ ] Monitoring alerts configured

**Deployment steps**:
```bash
# 1. Create backup
pg_dump mydb > backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Apply migration
alembic upgrade head

# 3. Immediate validation
psql -c "SELECT COUNT(*) FROM user_profiles;"
psql -c "SELECT COUNT(*) FROM user_profiles WHERE user_id NOT IN (SELECT id FROM users);"

# 4. Monitor for 1 hour
# Check application logs, error rates, query performance

# 5. If issues: Rollback
alembic downgrade -1
```

---

## ORM Coordination

### Coordinate with Backend-Dev

**After schema changes**, backend-dev must:
1. Update ORM models to match new schema
2. Update repositories/DAOs
3. Update API serializers
4. Update tests

**Example coordination**:

**Database agent creates migration**:
```python
# Migration: Add profile_url column
op.add_column('users', sa.Column('profile_url', sa.String(255), nullable=True))
```

**Backend-dev updates ORM model**:
```python
# models/user.py
class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    email = Column(String(255), nullable=False)
    profile_url = Column(String(255), nullable=True)  # NEW
```

**Backend-dev updates API serializer**:
```python
# schemas/user.py
class UserResponse(BaseModel):
    id: int
    email: str
    profile_url: Optional[str] = None  # NEW
```

### Handoff Communication

**Database agent → Backend-dev**:
```markdown
## Migration 001_add_profile_url Complete

**Schema change**: Added `users.profile_url` column (String, nullable)

**ORM updates required**:
1. Update `models/user.py`: Add `profile_url` field
2. Update `schemas/user.py`: Add `profile_url` to UserResponse
3. Update `repositories/user.py`: Include `profile_url` in queries
4. Update tests: Add `profile_url` to test fixtures

**Migration file**: `api/alembic/versions/001_add_profile_url.py`
**Commit**: a1b2c3d
```

---

## Common Migration Patterns

### Pattern: Add Table

```python
def upgrade():
    op.create_table(
        'study_plans',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now())
    )

    op.create_foreign_key('fk_study_plans_user_id', 'study_plans', 'users', ['user_id'], ['id'])
    op.create_index('ix_study_plans_user_id', 'study_plans', ['user_id'])

def downgrade():
    op.drop_index('ix_study_plans_user_id', 'study_plans')
    op.drop_constraint('fk_study_plans_user_id', 'study_plans')
    op.drop_table('study_plans')
```

### Pattern: Add Column with Default

```python
def upgrade():
    # Add nullable first
    op.add_column('users', sa.Column('status', sa.String(20), nullable=True))

    # Backfill default value
    op.execute("UPDATE users SET status = 'active' WHERE status IS NULL")

    # Make non-nullable
    op.alter_column('users', 'status', nullable=False)

def downgrade():
    op.drop_column('users', 'status')
```

### Pattern: Add Unique Constraint

```python
def upgrade():
    # Remove duplicates first
    op.execute("""
        DELETE FROM users a USING users b
        WHERE a.id > b.id AND a.email = b.email
    """)

    # Add unique constraint
    op.create_unique_constraint('uq_users_email', 'users', ['email'])

def downgrade():
    op.drop_constraint('uq_users_email', 'users')
```

### Pattern: Add Check Constraint

```python
def upgrade():
    op.create_check_constraint(
        'ck_users_email_format',
        'users',
        "email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'"
    )

def downgrade():
    op.drop_constraint('ck_users_email_format', 'users')
```

---

## Error Handling

### Migration Failure Scenarios

**Scenario 1: Foreign key constraint violation**

**Error**:
```
alembic.exc.IntegrityError: (psycopg2.errors.ForeignKeyViolation)
insert or update on table "user_profiles" violates foreign key constraint "fk_user_profiles_user_id"
```

**Resolution**:
1. Rollback migration: `alembic downgrade -1`
2. Identify orphaned records: `SELECT * FROM user_profiles WHERE user_id NOT IN (SELECT id FROM users)`
3. Clean up data or adjust migration
4. Re-run migration

**Scenario 2: Unique constraint violation**

**Error**:
```
alembic.exc.IntegrityError: (psycopg2.errors.UniqueViolation)
duplicate key value violates unique constraint "uq_users_email"
```

**Resolution**:
1. Rollback migration
2. Remove duplicates before adding constraint:
   ```sql
   DELETE FROM users a USING users b
   WHERE a.id > b.id AND a.email = b.email
   ```
3. Re-run migration

**Scenario 3: Column type conversion failure**

**Error**:
```
alembic.exc.ProgrammingError: column "user_id" cannot be cast automatically to type integer
```

**Resolution**:
1. Rollback migration
2. Add explicit conversion with validation:
   ```sql
   -- Check for invalid values first
   SELECT * FROM sessions WHERE user_id !~ '^[0-9]+$';

   -- Clean up invalid values
   DELETE FROM sessions WHERE user_id !~ '^[0-9]+$';

   -- Then cast
   ALTER TABLE sessions ALTER COLUMN user_id TYPE INTEGER USING user_id::integer;
   ```

### Task Failure Reporting

**When migration fails**:
```bash
# 1. Rollback migration
alembic downgrade -1

# 2. Mark task failed
.spec-flow/scripts/bash/task-tracker.sh mark-failed \
  -TaskId "T003" \
  -ErrorMessage "Migration failed: Foreign key violation on user_profiles.user_id. Found 5 orphaned records." \
  -FeatureDir "specs/001-feature"

# 3. Return failure JSON
{
  "task_id": "T003",
  "status": "failed",
  "summary": "Failed: Foreign key constraint violation",
  "files_changed": [],
  "test_results": "Migration up: FAILED at CREATE FOREIGN KEY",
  "blockers": ["alembic.exc.IntegrityError: Foreign key violation - 5 orphaned records in user_profiles"]
}
```

---

## Best Practices

1. **Always test migration up/down cycle** before committing
2. **Use zero-downtime patterns** for production (nullable → backfill → non-nullable)
3. **Index all foreign keys** and frequently queried columns
4. **Validate data integrity** after every migration (0 violations expected)
5. **Document rollback steps** in migration comments or NOTES.md
6. **Create backups** before production migrations
7. **Test on staging** for 24+ hours before production
8. **Monitor query performance** after migrations (EXPLAIN ANALYZE)
9. **Coordinate with backend-dev** for ORM model updates
10. **Never manually edit tasks.md** - always use task-tracker for status updates

---

## Tooling Reference

### Alembic (Python/SQLAlchemy)

**Common commands**:
```bash
# Create new migration
alembic revision -m "add_user_profiles_table"

# Upgrade to latest
alembic upgrade head

# Downgrade one migration
alembic downgrade -1

# Show current version
alembic current

# Show migration history
alembic history
```

### Prisma (TypeScript/Node.js)

```bash
# Create migration
npx prisma migrate dev --name add_user_profiles

# Apply migrations
npx prisma migrate deploy

# Reset database
npx prisma migrate reset
```

### Flyway (Java)

```bash
# Migrate
flyway migrate

# Rollback
flyway undo

# Info
flyway info
```

---

## Examples

### Example 1: Add New Table

**Task**: Create `study_plans` table with RLS policies

**Steps**:
1. Read task from tasks.md
2. Design table with columns: id, user_id, name, created_at
3. Add foreign key to users table
4. Add index on user_id
5. Test migration up/down
6. Validate: 0 orphaned foreign keys
7. Update task-tracker

**Migration**:
```python
def upgrade():
    op.create_table(
        'study_plans',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now())
    )
    op.create_foreign_key('fk_study_plans_user_id', 'study_plans', 'users', ['user_id'], ['id'])
    op.create_index('ix_study_plans_user_id', 'study_plans', ['user_id'])

def downgrade():
    op.drop_index('ix_study_plans_user_id', 'study_plans')
    op.drop_constraint('fk_study_plans_user_id', 'study_plans')
    op.drop_table('study_plans')
```

**Result**: Migration tested successfully, 0 data loss, query performance <50ms

### Example 2: Add Column with Backfill

**Task**: Add `subscription_tier` column to users table (non-nullable, default 'free')

**Steps**:
1. Migration 1: Add nullable column
2. Backfill with default value
3. Migration 2: Make non-nullable

**Migration**:
```python
# Migration 001
def upgrade():
    op.add_column('users', sa.Column('subscription_tier', sa.String(20), nullable=True))

# Migration 002
def upgrade():
    op.execute("UPDATE users SET subscription_tier = 'free' WHERE subscription_tier IS NULL")
    op.alter_column('users', 'subscription_tier', nullable=False)
```

**Result**: Zero-downtime migration, all users have subscription_tier

### Example 3: Add Index for Slow Query

**Task**: Optimize query `SELECT * FROM posts WHERE user_id = ? AND status = 'published' ORDER BY created_at DESC`

**Steps**:
1. Run EXPLAIN ANALYZE (Sequential scan detected)
2. Create composite index on (user_id, status, created_at)
3. Re-run EXPLAIN ANALYZE (Index scan confirmed)
4. Verify query time: 52ms → 0.8ms (98% improvement)

**Migration**:
```python
def upgrade():
    op.create_index('ix_posts_user_status_created', 'posts', ['user_id', 'status', 'created_at'])

def downgrade():
    op.drop_index('ix_posts_user_status_created', 'posts')
```

**Result**: Query performance improved from 52ms to 0.8ms
