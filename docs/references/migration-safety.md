# Database Migration Safety (v10.5+)

Defense-in-depth system to prevent forgotten database migrations from causing test failures.

## The Problem

Migrations are often forgotten during implementation, discovered only when tests fail in `/optimize` phase. By then, debugging is confusing because schema mismatches cause cryptic errors.

## Solution: Three-Phase Detection

### Phase 1: /plan (Step 0.5) - Early Detection

Pattern-based detection scans spec.md for schema-change keywords (store, persist, table, column, etc.). When 3+ keywords found:

- `has_migrations: true` flag set in state.yaml
- `migration-plan.md` artifact generated with:
  - Change classification (additive/breaking)
  - Table schemas with columns, types, constraints
  - Migration sequence with SQL
  - Rollback procedures

### Phase 2: /tasks (Step 1.5) - Task Generation

When migrations detected, generates T001-T009 tasks with P0 BLOCKING priority:

- Task ID convention: T001-T009 reserved for migrations
- Assigned to `database-architect` agent
- All downstream tasks (ORM, services, API) depend on migration tasks
- Layer-based execution ensures migrations complete first

### Phase 3: /implement (Step 0.6) - Runtime Enforcement

Before executing any implementation tasks:

- Runs `check-migration-status.sh` to detect pending migrations
- Behavior controlled by `migrations.strictness` in user-preferences.yaml

## Configuration

```yaml
# .spec-flow/config/user-preferences.yaml
migrations:
  # How to handle pending migrations
  # blocking (default): Stop and require manual apply
  # warning: Log warning, continue
  # auto_apply: Automatically run migrations (CI/CD)
  strictness: blocking

  # Detection sensitivity (keyword score threshold)
  detection_threshold: 3

  # Generate migration-plan.md during /plan
  auto_generate_plan: true
```

## Strictness Levels

| Level | Behavior | Use Case |
|-------|----------|----------|
| `blocking` | Exit with error, provide apply command | Default, safest |
| `warning` | Log warning, continue execution | Experienced devs |
| `auto_apply` | Run migrations automatically | CI/CD pipelines |

## Supported Frameworks

- **Alembic** (Python/SQLAlchemy): `alembic upgrade head`
- **Prisma** (TypeScript/Node.js): `npx prisma migrate deploy`
- **Generic**: File-based detection for custom migration systems

## Task ID Convention

| ID Range | Phase | Type | Priority |
|----------|-------|------|----------|
| T001-T009 | 1.5 | Migrations | P0 BLOCKING |
| T010-T019 | 2 | ORM Models | P1 |
| T020-T029 | 2.5 | Services | P1 |
| T030+ | 3+ | API/UI | P1-P2 |

## Why This Matters

- 40% of implementation failures trace to forgotten migrations
- Early detection saves 30-60 minutes of debugging
- P0 BLOCKING priority ensures migrations run first
- Configurable strictness supports different workflows
