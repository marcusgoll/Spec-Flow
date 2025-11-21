# Migration Integrity Report

**Generated**: {TIMESTAMP}

**Epic**: {EPIC_SLUG}

**Status**: {PASSED|FAILED}

---

## Executive Summary

**Total Migrations**: {total_migrations}

**Migrations Tested**: {tested_migrations}

**Passed**: {passed_count}

**Failed**: {failed_count}

**Data Corruption Detected**: {YES|NO}

**Rollback Safe**: {YES|NO}

---

## Migration Files Tested

| Migration | Version | Status | Up Duration | Down Duration | Data Integrity | Issues |
|-----------|---------|--------|-------------|---------------|----------------|--------|
| {migration_name} | {version} | ✅ PASS | {up_ms}ms | {down_ms}ms | ✅ Intact | None |
| {migration_name} | {version} | ❌ FAIL | {up_ms}ms | {down_ms}ms | ❌ Corrupted | Data loss |
| {migration_name} | {version} | ✅ PASS | {up_ms}ms | {down_ms}ms | ✅ Intact | None |

---

## Detailed Test Results

### Migration 1: {MIGRATION_NAME} ({VERSION})

**File**: `{migration_file_path}`

**Status**: {PASSED|FAILED}

**Description**: {migration_description}

**Type**: {additive | transformative | destructive}

#### Up Migration (Upgrade)

**Executed**: ✅ YES

**Duration**: {duration_ms} ms

**SQL Statements** (summary):
```sql
ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
CREATE INDEX idx_users_email ON users(email);
```

**Tables Affected**:
- `users`: 1 column added, 1 index created
- `sessions`: 0 changes

**Row Counts Before**:
- `users`: {row_count_before}
- `sessions`: {row_count_before}

**Row Counts After**:
- `users`: {row_count_after} (✅ unchanged)
- `sessions`: {row_count_after} (✅ unchanged)

**Data Integrity Checks**:
- ✅ No orphaned records (foreign key integrity maintained)
- ✅ No NULL values in required fields
- ✅ Unique constraints maintained
- ✅ Check constraints pass
- ✅ Data checksums match (no data corruption)

#### Down Migration (Rollback)

**Executed**: ✅ YES

**Duration**: {duration_ms} ms

**SQL Statements** (summary):
```sql
DROP INDEX idx_users_email;
ALTER TABLE users DROP COLUMN email_verified;
```

**Row Counts After Rollback**:
- `users`: {row_count_after_rollback} (✅ restored to {row_count_before})
- `sessions`: {row_count_after_rollback} (✅ restored to {row_count_before})

**Data Integrity Checks**:
- ✅ Row counts match pre-migration state
- ✅ Data checksums match pre-migration state
- ✅ No orphaned records
- ✅ Foreign key integrity maintained
- ✅ Schema matches pre-migration state

**Rollback Safety**: ✅ SAFE (data fully restored)

---

### Migration 2: {MIGRATION_NAME} ({VERSION})

**File**: `{migration_file_path}`

**Status**: {PASSED|FAILED}

**Description**: {migration_description}

**Type**: {additive | transformative | destructive}

#### Up Migration (Upgrade)

**Executed**: ✅ YES

**Duration**: {duration_ms} ms

**SQL Statements** (summary):
```sql
ALTER TABLE orders ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'pending';
UPDATE orders SET status = 'completed' WHERE completed_at IS NOT NULL;
CREATE INDEX idx_orders_status ON orders(status);
```

**Tables Affected**:
- `orders`: 1 column added, 1 index created, {rows_updated} rows updated

**Row Counts Before**:
- `orders`: {row_count_before}

**Row Counts After**:
- `orders`: {row_count_after} (✅ unchanged)

**Data Integrity Checks**:
- ✅ No orphaned records
- ✅ No NULL values in required fields
- ❌ **Data anomaly detected**: {anomaly_count} orders have inconsistent status
  - Issue: Orders with `completed_at` but status = 'pending'
  - Affected rows: {affected_row_ids}
  - Severity: HIGH

#### Down Migration (Rollback)

**Executed**: ✅ YES

**Duration**: {duration_ms} ms

**SQL Statements** (summary):
```sql
DROP INDEX idx_orders_status;
ALTER TABLE orders DROP COLUMN status;
```

**Row Counts After Rollback**:
- `orders`: {row_count_after_rollback}

**Data Integrity Checks**:
- ❌ **Data loss detected**: {lost_row_count} orders missing after rollback
  - Expected: {row_count_before} orders
  - Actual: {row_count_after_rollback} orders
  - Lost order IDs: {lost_order_ids}
  - Severity: CRITICAL

**Rollback Safety**: ❌ UNSAFE (data loss detected)

**Root Cause**: Migration uses `CASCADE DELETE` that removes related records

**Recommendation**:
1. Rewrite migration to use `ON DELETE SET NULL` instead of `CASCADE`
2. Add data backup step before migration
3. Test rollback with production-like data

---

### Migration 3: {MIGRATION_NAME} ({VERSION})

...

---

## Data Integrity Checks

### Check 1: Foreign Key Integrity

**Purpose**: Verify all foreign key relationships are maintained

**Method**:
```sql
SELECT
  t1.id AS orphaned_id,
  t1.foreign_key_column
FROM child_table t1
LEFT JOIN parent_table t2 ON t1.foreign_key_column = t2.id
WHERE t2.id IS NULL;
```

**Results**:
- `order_items.order_id → orders.id`: ✅ No orphans (0 rows)
- `orders.user_id → users.id`: ✅ No orphans (0 rows)
- `sessions.user_id → users.id`: ❌ **3 orphaned sessions**
  - Orphaned session IDs: {session_ids}
  - Likely cause: User deletion without cascade handling
  - Severity: HIGH

---

### Check 2: Unique Constraint Validation

**Purpose**: Verify unique constraints are maintained

**Method**:
```sql
SELECT column_name, COUNT(*) AS duplicate_count
FROM table_name
GROUP BY column_name
HAVING COUNT(*) > 1;
```

**Results**:
- `users.email`: ✅ No duplicates
- `products.sku`: ✅ No duplicates
- `sessions.token`: ✅ No duplicates

---

### Check 3: NOT NULL Constraint Validation

**Purpose**: Verify no NULL values in required fields

**Method**:
```sql
SELECT COUNT(*) AS null_count
FROM table_name
WHERE required_column IS NULL;
```

**Results**:
- `users.email`: ✅ No NULLs (0 rows)
- `orders.user_id`: ✅ No NULLs (0 rows)
- `products.price`: ❌ **5 products with NULL price**
  - Product IDs: {product_ids}
  - Likely cause: Migration didn't set DEFAULT value
  - Severity: MEDIUM

---

### Check 4: Check Constraint Validation

**Purpose**: Verify database check constraints pass

**Method**:
```sql
SELECT * FROM table_name
WHERE NOT (check_constraint_condition);
```

**Results**:
- `products.price >= 0`: ✅ All pass
- `users.age >= 18`: ✅ All pass
- `orders.quantity > 0`: ❌ **2 orders with quantity = 0**
  - Order IDs: {order_ids}
  - Likely cause: Migration update script error
  - Severity: HIGH

---

### Check 5: Data Checksum Validation

**Purpose**: Detect data corruption by comparing checksums

**Method**:
```sql
SELECT
  table_name,
  MD5(CAST(STRING_AGG(CAST(id AS TEXT), ',') AS TEXT)) AS checksum
FROM table_name
GROUP BY table_name;
```

**Checksums Before Migration**:
- `users`: `a3f2c8e9...`
- `orders`: `b8d4f1a2...`
- `products`: `c9e5a7b3...`

**Checksums After Up Migration**:
- `users`: `a3f2c8e9...` (✅ unchanged)
- `orders`: `f2a9d8c1...` (✅ expected change - data updated)
- `products`: `c9e5a7b3...` (✅ unchanged)

**Checksums After Rollback**:
- `users`: `a3f2c8e9...` (✅ matches pre-migration)
- `orders`: `b8d4f1a2...` (✅ matches pre-migration)
- `products`: `c9e5a7b3...` (✅ matches pre-migration)

**Result**: ✅ No data corruption detected

---

## Rollback Safety Analysis

### Safe Migrations (Reversible)

| Migration | Type | Rollback Method | Data Loss Risk |
|-----------|------|----------------|----------------|
| {migration_name} | Additive | Drop column/index | ✅ None |
| {migration_name} | Additive | Drop table | ✅ None (new table) |

**Additive migrations** (adding columns, tables, indexes) are inherently safe to rollback because they don't modify existing data.

---

### Unsafe Migrations (Risk of Data Loss)

| Migration | Type | Rollback Risk | Issue | Recommendation |
|-----------|------|--------------|-------|----------------|
| {migration_name} | Destructive | ❌ HIGH | Drops column with data | Backup data before migration |
| {migration_name} | Transformative | ⚠️ MEDIUM | Data transformation may be lossy | Add inverse transformation |

**Destructive migrations** (dropping columns, tables) risk data loss if rolled back after deployment.

**Transformative migrations** (updating data values) may not be perfectly reversible if transformation is lossy.

---

## Auto-Retry Summary

{IF auto_retry_used}
**Retry Attempts**: {retry_count}

**Strategies Used**:
1. `reset-test-db`: ✅ Succeeded (attempt 1)
   - Dropped and recreated test database
   - Reloaded seed data from dump file
   - Migration test passed after clean slate
2. `re-run-migration`: ❌ Failed (attempt 2)
   - Attempted to re-run migration without reset
   - Still detected data corruption
3. `fix-seed-data`: ✅ Succeeded (attempt 3)
   - Updated seed data to include required foreign key references
   - Migration integrity checks now pass

**Final Status**: {PASSED|FAILED} (after {total_attempts} retries)
{ELSE}
No auto-retry needed - all integrity checks passed on first attempt
{ENDIF}

---

## Performance Impact

### Migration Execution Time

| Migration | Up Duration | Down Duration | Tables Locked | Production Impact |
|-----------|-------------|---------------|---------------|-------------------|
| {migration_name} | {up_ms}ms | {down_ms}ms | users | ✅ LOW (<1s) |
| {migration_name} | {up_sec}s | {down_sec}s | orders, order_items | ⚠️ MEDIUM (5s) |
| {migration_name} | {up_min}min | {down_min}min | products | ❌ HIGH (>1min) |

**Recommendations**:
- Migrations with HIGH impact should be run during maintenance window
- Consider batching updates for large tables
- Use online schema change tools (pt-online-schema-change, gh-ost)

---

## Zero-Downtime Migration Strategy

{IF high_impact_migrations}
**High-Impact Migrations Detected**: {high_impact_count}

**Recommended Approach** (for zero-downtime):

### Phase 1: Additive Changes (Deploy V1)
```sql
-- Add new column with NULL allowed
ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT NULL;
```
- Deploy application version that writes to both old and new column
- No downtime, backward compatible

### Phase 2: Backfill Data (Background Job)
```sql
-- Backfill new column with data from old column
UPDATE users SET email_verified = (email_confirmed_at IS NOT NULL) WHERE email_verified IS NULL;
```
- Run as background job
- No application deployment needed

### Phase 3: Make Column Required (Deploy V2)
```sql
-- Make column NOT NULL after backfill complete
ALTER TABLE users ALTER COLUMN email_verified SET NOT NULL;
```
- Deploy application version that only uses new column
- Drop old column reference

### Phase 4: Cleanup (Deploy V3)
```sql
-- Drop old column after verification period
ALTER TABLE users DROP COLUMN email_confirmed_at;
```
- Can be done weeks later after confidence gained

**Benefits**:
- Zero downtime
- Each phase is independently rollbackable
- Gradual rollout reduces risk

{ENDIF}

---

## Recommendations

### Critical Actions (Must Fix)

{IF critical_issues}
1. **Fix data loss in migration {migration_name}**:
   - Root cause: {root_cause}
   - Impact: {impact_description}
   - Fix: {recommended_fix}

2. **Resolve data integrity issues**:
   - {issue_count} orphaned records in {table_name}
   - Add CASCADE handling or backup strategy

3. **Add missing rollback logic**:
   - Migration {migration_name} has no down() method
   - Implement rollback to enable safe deployments
{ELSE}
✅ No critical issues - all migrations are safe and reversible
{ENDIF}

### Best Practices

1. **Always test migrations**:
   - Test on production-like data (not just empty database)
   - Verify rollback works correctly
   - Check data integrity after up and down migrations

2. **Use migration patterns**:
   - **Additive**: Adding columns, tables, indexes (safest)
   - **Transformative**: Updating data (test thoroughly)
   - **Destructive**: Dropping columns, tables (avoid if possible, backup first)

3. **Zero-downtime migrations**:
   - Multi-phase rollout (additive → backfill → enforce → cleanup)
   - Use online schema change tools for large tables
   - Run during maintenance window if necessary

4. **Data backup**:
   - Backup production data before destructive migrations
   - Document rollback procedures
   - Test backups regularly

---

## Migration History

**Previous Migrations** (last 5):
1. `{version_1}` - {description_1} - ✅ Passed
2. `{version_2}` - {description_2} - ✅ Passed
3. `{version_3}` - {description_3} - ✅ Passed
4. `{version_4}` - {description_4} - ✅ Passed
5. `{version_5}` - {description_5} - ✅ Passed

**Total Migrations Applied**: {total_applied}

**Last Migration Date**: {last_migration_date}

---

## Test Environment

**Database**:
- Type: {PostgreSQL|MySQL|SQLite}
- Version: {version}
- Engine: {InnoDB|MyISAM|default}

**Test Data**:
- Tables: {table_count}
- Total Rows: {row_count}
- Data Size: {data_size_mb} MB

**Seed Data Source**: `{seed_data_path}`

---

## Exit Status

**Exit Code**: {0 if passed else 1}

**Blockers**: {blocker_count}

**Next Action**:
{IF passed}
✅ All migrations passed integrity checks - safe to deploy
{ELSE}
❌ Migration integrity failed - fix {blocker_count} critical issues before deployment
{ENDIF}

---

**Report Generated by**: Gate 10 (Migration Integrity) - /optimize phase

**Template Version**: 1.0

**Generated**: {ISO_TIMESTAMP}
