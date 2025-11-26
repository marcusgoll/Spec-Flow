# Migration Strategies for Breaking Changes

Complete playbook for safely migrating through breaking API, schema, and interface changes.

## Core Migration Principles

### Principle 1: Never Break Clients Abruptly

**Bad**: Remove endpoint immediately
**Good**: Deprecate → Monitor → Remove

### Principle 2: Provide Transition Period

Minimum deprecation periods:
- **Public APIs**: 6-12 months
- **Partner APIs**: 12 months (contractual obligation)
- **Internal APIs**: 3-6 months
- **Database schemas**: 6 months
- **Library interfaces**: 1 major version

### Principle 3: Communicate Early and Often

Timeline for notifications:
- **T-90 days**: Announce deprecation
- **T-60 days**: Email reminder
- **T-30 days**: Final warning
- **T-7 days**: Last chance notification
- **T-0**: Removal (if usage at 0)

## API Endpoint Migration Strategies

### Strategy 1: Deprecation Headers

**When to use**: Removing endpoint, clients need to migrate

**Implementation**:
```typescript
// Add deprecation middleware
router.get('/api/users',
  deprecationMiddleware({
    sunset: '2025-06-01',
    replacement: '/api/v2/users',
    message: 'Use /api/v2/users for improved performance'
  }),
  usersController.list
);

// Middleware implementation
function deprecationMiddleware(options) {
  return (req, res, next) => {
    // Standard deprecation headers
    res.header('Deprecation', 'true');
    res.header('Sunset', options.sunset);
    res.header('Link', `<${options.replacement}>; rel="successor-version"`);

    // Custom warning in response
    res.header('X-API-Warn', options.message);

    // Log usage for monitoring
    logger.warn('Deprecated endpoint called', {
      endpoint: req.path,
      client: req.get('User-Agent'),
      ip: req.ip,
      sunset: options.sunset
    });

    next();
  };
}
```

**Response headers**:
```
HTTP/1.1 200 OK
Deprecation: true
Sunset: Sat, 01 Jun 2025 00:00:00 GMT
Link: </api/v2/users>; rel="successor-version"
X-API-Warn: Use /api/v2/users for improved performance
```

**Timeline**:
1. Day 0: Add deprecation headers
2. Day 30: Send email to known clients
3. Day 60: Monitor usage, reach out to high-volume clients
4. Day 90: Return 410 Gone if usage < 10 req/day
5. Day 120: Remove endpoint if usage at 0

### Strategy 2: API Versioning (URL)

**When to use**: Breaking changes to request/response format

**Implementation**:
```typescript
// routes/v1/users.ts (OLD, keep running)
router.get('/api/v1/users', (req, res) => {
  const users = await getUsersLegacy();
  res.json(users);  // Old format: array
});

// routes/v2/users.ts (NEW, breaking changes)
router.get('/api/v2/users', (req, res) => {
  const result = await getUsersPaginated(req.query);
  res.json({
    items: result.users,    // New format: paginated object
    total: result.total,
    page: result.page
  });
});
```

**Versioning strategy**:
```markdown
# API Versioning Policy

- **v1**: Current production (maintain for 12 months)
- **v2**: New version (introduce breaking changes)
- **v3**: Future version

When v3 launches:
- v1 sunsets (410 Gone)
- v2 becomes stable
- v3 is new

Clients choose version in URL: /api/v1/* or /api/v2/*
```

**Migration path**:
1. Release v2 with breaking changes
2. Run v1 and v2 in parallel for 12 months
3. Monitor v1 usage
4. Sunset v1 when usage < 1%
5. v2 becomes primary version

### Strategy 3: Feature Flags (Gradual Rollout)

**When to use**: Risky changes, want gradual rollout

**Implementation**:
```typescript
router.get('/api/users', async (req, res) => {
  const useNewFormat = await featureFlags.isEnabled(
    'new-user-format',
    req.user.id
  );

  if (useNewFormat) {
    // New breaking format (for opted-in users)
    res.json({ items: users, total: count });
  } else {
    // Old format (for everyone else)
    res.json(users);
  }
});
```

**Rollout timeline**:
1. Week 1: Enable for internal users (1%)
2. Week 2: Enable for beta users (5%)
3. Week 3: Enable for 25% of users
4. Week 4: Enable for 50% of users
5. Week 5: Enable for 100% of users
6. Week 6: Remove old code path

### Strategy 4: Redirect (Soft Transition)

**When to use**: Endpoint moved, can redirect automatically

**Implementation**:
```typescript
// Old endpoint (redirect)
router.get('/api/users', (req, res) => {
  res.redirect(301, '/api/v2/users');
});

// Or proxy transparently
router.get('/api/users', async (req, res) => {
  const result = await v2Controller.getUsers(req, res);
  // Adapt v2 response to v1 format
  res.json(adaptToLegacyFormat(result));
});
```

**Use cases**:
- Endpoint renamed/moved
- Minor format changes (can adapt)
- Temporary during migration period

## Database Schema Migration Strategies

### Strategy 1: Additive Migration (Safest)

**When to use**: Changing column, want zero downtime

**Problem**: Rename `email` column to `email_address`

**Migration steps**:

**Phase 1: Add new column**
```sql
-- Migration 001: Add new column
ALTER TABLE users ADD COLUMN email_address VARCHAR(255);
```

**Phase 2: Dual-write**
```typescript
// Write to both columns
await prisma.user.create({
  data: {
    email: data.email,         // Old column
    email_address: data.email  // New column (dual write)
  }
});
```

**Phase 3: Backfill**
```sql
-- Migration 002: Copy existing data
UPDATE users
SET email_address = email
WHERE email_address IS NULL;
```

**Phase 4: Switch reads**
```typescript
// Read from new column
const user = await prisma.user.findUnique({
  select: {
    id: true,
    email_address: true  // New column
  }
});
```

**Phase 5: Stop writing to old column**
```typescript
// Only write to new column
await prisma.user.create({
  data: {
    email_address: data.email  // New column only
  }
});
```

**Phase 6: Drop old column**
```sql
-- Migration 003: Drop old column (6 months later)
ALTER TABLE users DROP COLUMN email;
```

**Timeline**: 6 months (allows rollback at each phase)

### Strategy 2: Archive Before Delete

**When to use**: Dropping column with valuable data

**Problem**: Drop `legacy_id` column

**Migration steps**:

**Phase 1: Create archive table**
```sql
CREATE TABLE users_legacy_data (
  id UUID PRIMARY KEY REFERENCES users(id),
  legacy_id VARCHAR(255),
  archived_at TIMESTAMP DEFAULT NOW()
);
```

**Phase 2: Copy data**
```sql
INSERT INTO users_legacy_data (id, legacy_id)
SELECT id, legacy_id FROM users
WHERE legacy_id IS NOT NULL;
```

**Phase 3: Verify**
```sql
-- Check counts match
SELECT COUNT(*) FROM users WHERE legacy_id IS NOT NULL;
SELECT COUNT(*) FROM users_legacy_data;
-- Must be equal
```

**Phase 4: Drop column**
```sql
ALTER TABLE users DROP COLUMN legacy_id;
```

**Phase 5: Retain archive**
```sql
-- Keep archive table for 12 months
-- Add to data retention policy
-- Can query if needed: SELECT legacy_id FROM users_legacy_data WHERE id = ?
```

### Strategy 3: Make Nullable (Don't Drop)

**When to use**: Unsure if data will be needed, want safety

**Problem**: Want to stop using `phone` column

**Migration steps**:

**Phase 1: Make nullable**
```sql
ALTER TABLE users ALTER COLUMN phone DROP NOT NULL;
```

**Phase 2: Stop writing**
```typescript
// Don't populate phone anymore
await prisma.user.create({
  data: {
    name: data.name,
    email: data.email
    // phone: omitted
  }
});
```

**Phase 3: Verify not needed**
```sql
-- Monitor: Is anything querying phone?
-- Wait 6 months
-- If no queries, safe to drop
```

**Phase 4: Drop (later)**
```sql
-- Only after 6 months of zero usage
ALTER TABLE users DROP COLUMN phone;
```

**Benefit**: Reversible (can start using column again)

### Strategy 4: Type Change with Conversion

**When to use**: Changing column type (e.g., varchar → integer)

**Problem**: Change `age` from varchar to integer

**Migration steps**:

**Phase 1: Add new typed column**
```sql
ALTER TABLE users ADD COLUMN age_int INTEGER;
```

**Phase 2: Migrate data**
```sql
UPDATE users
SET age_int = CAST(age AS INTEGER)
WHERE age ~ '^[0-9]+$';  -- Only valid integers
```

**Phase 3: Handle invalid**
```sql
-- Log invalid data
INSERT INTO migration_errors (table_name, row_id, error)
SELECT 'users', id, 'Invalid age: ' || age
FROM users
WHERE age_int IS NULL AND age IS NOT NULL;

-- Set default or null
UPDATE users
SET age_int = NULL
WHERE age_int IS NULL;
```

**Phase 4: Switch code**
```typescript
// Use new column
const user = await prisma.user.findUnique({
  select: { age_int: true }
});
```

**Phase 5: Drop old column**
```sql
ALTER TABLE users DROP COLUMN age;
ALTER TABLE users RENAME COLUMN age_int TO age;
```

## Interface Migration Strategies

### Strategy 1: Deprecate + Replace Pattern

**When to use**: Changing function signature

**Problem**: Change `getUserById` to return `User | null` instead of `User`

**Migration steps**:

**Phase 1: Create new function**
```typescript
// OLD (keep for backward compatibility)
/**
 * @deprecated Use findUserById instead. Will be removed in v2.0.
 * @throws NotFoundError if user doesn't exist
 */
async getUserById(id: string): Promise<User> {
  const user = await this.findUserById(id);
  if (!user) throw new NotFoundError();
  return user;
}

// NEW (with breaking change)
/**
 * Find user by ID
 * @returns User if found, null if not found
 */
async findUserById(id: string): Promise<User | null> {
  return await prisma.user.findUnique({ where: { id } });
}
```

**Phase 2: Update callers gradually**
```typescript
// Update call sites one by one
- const user = await getUserById(id);
+ const user = await findUserById(id);
+ if (!user) throw new NotFoundError();
```

**Phase 3: Mark as deprecated**
```typescript
// Add deprecation warning
import { deprecated } from 'core-decorators';

@deprecated('Use findUserById instead')
async getUserById(id: string): Promise<User> {
  // Implementation
}
```

**Phase 4: Remove old function**
```typescript
// After all callers migrated (6 months)
- async getUserById(id: string): Promise<User> { }  // REMOVED
```

### Strategy 2: Overload (TypeScript)

**When to use**: Adding optional parameters

**Problem**: Add `options` parameter to `getUsers`

**Migration steps**:

**Phase 1: Add overload**
```typescript
// Overload 1: Old signature (backward compatible)
function getUsers(): Promise<User[]>;

// Overload 2: New signature (with options)
function getUsers(options: GetUsersOptions): Promise<User[]>;

// Implementation
function getUsers(options?: GetUsersOptions): Promise<User[]> {
  if (options) {
    // New behavior
    return this.getUsersWithOptions(options);
  } else {
    // Old behavior
    return this.getAllUsers();
  }
}
```

**Benefit**: Backward compatible, no breaking change

### Strategy 3: Default Parameters

**When to use**: Adding new required functionality, but can default

**Problem**: Add `includeDeleted` parameter

**Migration**:
```typescript
// OLD
function getUsers(): Promise<User[]>

// NEW (with default)
function getUsers(includeDeleted: boolean = false): Promise<User[]>
```

**Benefit**: Old callers work (use default), new callers can opt-in

## Communication Strategies

### Deprecation Notice Template

**Email to clients**:
```
Subject: [API Deprecation] GET /api/v1/users will be removed on June 1, 2025

Hello,

We're reaching out to notify you that the following API endpoint will be deprecated:

Endpoint: GET /api/v1/users
Sunset Date: June 1, 2025 (90 days from now)
Replacement: GET /api/v2/users

What's changing:
- v1 returns array: [{ id: 1, name: "Alice" }]
- v2 returns paginated object: { items: [...], total: 100, page: 1 }

Migration guide:
https://docs.example.com/api/migration/v1-to-v2

Your action required:
1. Update your integration to use /api/v2/users
2. Test in staging environment
3. Deploy before June 1, 2025

Need help? Reply to this email or contact support@example.com

Timeline:
- March 1: Deprecation announced (today)
- April 1: Reminder email (30 days)
- May 1: Final warning (60 days)
- June 1: Endpoint removed (90 days)

Thank you,
API Team
```

### Deprecation Docs Template

**In API documentation**:
```markdown
# GET /api/v1/users [DEPRECATED]

⚠️ **This endpoint is deprecated and will be removed on June 1, 2025.**

**Use instead**: [GET /api/v2/users](/api/v2/users)

## Why is this deprecated?

The v1 endpoint returns an unbounded array, which causes performance issues
for large datasets. The v2 endpoint uses pagination for better performance.

## Migration guide

### Old (v1) request:
\`\`\`
GET /api/v1/users
\`\`\`

### Old response:
\`\`\`json
[
  { "id": 1, "name": "Alice" },
  { "id": 2, "name": "Bob" }
]
\`\`\`

### New (v2) request:
\`\`\`
GET /api/v2/users?page=1&limit=20
\`\`\`

### New response:
\`\`\`json
{
  "items": [
    { "id": 1, "name": "Alice" },
    { "id": 2, "name": "Bob" }
  ],
  "total": 100,
  "page": 1,
  "limit": 20
}
\`\`\`

### Code example:
\`\`\`typescript
// Old
const users = await fetch('/api/v1/users').then(r => r.json());

// New
const response = await fetch('/api/v2/users?page=1&limit=20').then(r => r.json());
const users = response.items;
\`\`\`

## Timeline

- **March 1, 2025**: Deprecation announced
- **June 1, 2025**: Endpoint removed (returns 410 Gone)

## Need help?

Contact support@example.com
```

## Rollback Strategies

### API Rollback

**If removal causes issues**:

```typescript
// Emergency rollback (re-enable endpoint)
router.get('/api/users', (req, res) => {
  // Log emergency usage
  logger.error('Emergency endpoint usage after removal', {
    endpoint: req.path,
    client: req.get('User-Agent')
  });

  // Proxy to v2 and adapt response
  const v2Response = await fetch('/api/v2/users');
  const v1Response = adaptToLegacyFormat(v2Response);

  res.json(v1Response);
});
```

### Database Rollback

**If migration causes issues**:

```sql
-- Rollback plan for column rename

-- Emergency: Restore old column
ALTER TABLE users ADD COLUMN email VARCHAR(255);

-- Restore data from new column
UPDATE users SET email = email_address;

-- Resume dual-write
-- (code change to write to both columns again)
```

## Summary

**Key takeaways**:
1. **Never break abruptly**: Use deprecation periods
2. **Communicate early**: 90-day notice minimum
3. **Provide alternatives**: Always offer migration path
4. **Monitor usage**: Track who's still using deprecated features
5. **Archive data**: Never delete data without backup
6. **Rollback plan**: Be ready to restore if issues arise

**Minimum timelines**:
- Public APIs: 6 months deprecation
- Database changes: 6 months (additive migration)
- Interface changes: 1 major version

**Always ask**:
- Who will this break?
- How can we avoid breaking them?
- What's the migration path?
- Can we roll back if needed?
