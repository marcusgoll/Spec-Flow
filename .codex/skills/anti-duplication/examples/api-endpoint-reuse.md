# Example: API Endpoint Reuse

Complete walkthrough of preventing API endpoint duplication through systematic search and reuse.

## Scenario

**User request**: "Create an API endpoint to update user email"

**Context**: Express + TypeScript application with existing user management endpoints

## Without Anti-Duplication Skill (Bad)

**Immediate implementation**:

```typescript
// routes/user.ts (DUPLICATE APPROACH)
router.patch('/api/user/email', async (req, res) => {
  try {
    // Custom auth logic (different from other endpoints)
    const token = req.headers.authorization?.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Inline validation (different from other endpoints)
    if (!req.body.email || !isValidEmail(req.body.email)) {
      return res.status(400).json({ error: 'Invalid email' });
    }

    // Direct database access (bypassing service layer)
    await prisma.user.update({
      where: { id: decoded.userId },
      data: { email: req.body.email }
    });

    res.json({ success: true });
  } catch (error) {
    // Custom error handling (different from other endpoints)
    res.status(500).json({ error: error.message });
  }
});
```

**Problems**:
- ❌ Different auth logic from other endpoints (inline JWT verification)
- ❌ Different validation approach (inline vs middleware)
- ❌ Bypasses service layer (direct Prisma access)
- ❌ Different error handling (try/catch vs middleware)
- ❌ Inconsistent response format
- ❌ No request logging
- ❌ No rate limiting

**Result**: 5th variation of user update endpoint, maintenance nightmare

## With Anti-Duplication Skill (Good)

### Step 1: Trigger Detection

User says "Create an API endpoint to update user email"

**Keywords detected**: "Create", "API endpoint", "update", "user", "email"

**Auto-trigger**: Anti-duplication skill activates immediately BEFORE writing code

### Step 2: Parse Request

**Extraction**:
```
Type: API endpoint
Domain: User
Operation: Update (PATCH/PUT)
Resource: Email
HTTP Method: PATCH (partial update)
Technology: Express, TypeScript
```

### Step 3: Generate Search Strategies

**Multi-pronged search**:

1. **Find existing user endpoints**:
   - Grep: `router.(patch|put).*user` in `**/*.ts`
   - Glob: `**/routes/**/user*.ts`

2. **Find update operations**:
   - Grep: `update.*user|user.*update` in `**/*.ts`

3. **Find middleware patterns**:
   - Grep: `authMiddleware|authenticate` in `**/*routes*.ts`
   - Grep: `validateUserInput|validate.*user` in `**/*.ts`

4. **Find similar resource endpoints**:
   - Grep: `router.(patch|put)` in `**/routes/*.ts` (see all update endpoints)

### Step 4: Execute Searches

**Search results** (parallel execution):

**Search 1**: User endpoints
```typescript
// routes/user.ts
router.patch('/api/user/profile',
  authMiddleware,
  validateUserInput,
  userController.updateProfile
);

router.patch('/api/user/password',
  authMiddleware,
  validatePasswordInput,
  userController.updatePassword
);

router.put('/api/user/settings',
  authMiddleware,
  validateSettingsInput,
  userController.updateSettings
);
```

**Search 2**: UserController methods
```typescript
// controllers/UserController.ts
class UserController {
  async updateProfile(req, res) {
    await this.userService.update(req.user.id, 'profile', req.body);
    res.json({ success: true, message: 'Profile updated' });
  }

  async updatePassword(req, res) {
    await this.userService.update(req.user.id, 'password', req.body);
    res.json({ success: true, message: 'Password updated' });
  }

  async updateSettings(req, res) {
    await this.userService.update(req.user.id, 'settings', req.body);
    res.json({ success: true, message: 'Settings updated' });
  }
}
```

**Search 3**: Middleware
```typescript
// middleware/auth.ts
export const authMiddleware = async (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token' });

  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  req.user = await prisma.user.findUnique({ where: { id: decoded.userId } });
  next();
};

// middleware/validation.ts
export const validateUserInput = (req, res, next) => {
  const schema = Joi.object({ /* validation */ });
  const { error } = schema.validate(req.body);
  if (error) return res.status(400).json({ error: error.message });
  next();
};
```

### Step 5: Analyze Findings

**Pattern identified**: All user update endpoints follow consistent structure:

```
Structure:
1. Route: PATCH /api/user/{field}
2. Middleware chain:
   - authMiddleware (JWT auth + load user into req.user)
   - validate{Field}Input (Joi schema validation)
3. Controller: userController.update{Field}
4. Response: { success: true, message: '...' }

Controller pattern:
- Method: async update{Field}(req, res)
- Service call: this.userService.update(userId, field, data)
- Response: Consistent format

Service pattern:
- Centralized update method
- Handles all user field updates
- Database transaction
- Audit logging
```

**Similarity score**:
- Domain match: 100% (User domain)
- Operation match: 100% (Update operation)
- Structure match: 100% (Same middleware, controller, service pattern)
- Technology match: 100% (Express, TypeScript, Joi, JWT)

**Overall: 100% - EXACT PATTERN MATCH**

### Step 6: Present Reuse Options

**Recommendation to user**:

"🔍 **Anti-Duplication Analysis**

Found 3 existing user update endpoints that follow a consistent pattern:
- PATCH /api/user/profile
- PATCH /api/user/password
- PUT /api/user/settings

**Pattern identified**:
```
router.patch('/api/user/{field}',
  authMiddleware,           // JWT auth (consistent)
  validate{Field}Input,     // Joi validation (consistent)
  userController.update{Field}  // Controller method (consistent)
);
```

**Reuse options**:

**Option A (Recommended)**: Extend existing pattern
- Add `PATCH /api/user/email` following the same structure
- Add `validateEmailInput` middleware
- Add `userController.updateEmail` method
- Benefits: Consistent, tested, reuses existing auth/service

**Option B**: Modify controller to be more generic
- Change `update{Field}` methods to single `update` method with field param
- Reduces endpoint count (3 endpoints → 1 generic endpoint)
- Benefits: Even more DRY, but requires refactoring existing endpoints

**Option C**: Create new endpoint (not recommended)
- Would create inconsistency
- Would bypass established middleware chain
- Justification required

**Which option do you prefer? I recommend Option A (extend pattern).**"

### Step 7: User Chooses Option A

### Step 8: Implement with Reuse

**Implementation**:

```typescript
// middleware/validation.ts (ADD new validator)
export const validateEmailInput = (req, res, next) => {
  const schema = Joi.object({
    email: Joi.string().email().required()
  });

  const { error } = schema.validate(req.body);
  if (error) return res.status(400).json({ error: error.message });
  next();
};

// routes/user.ts (ADD new route following pattern)
router.patch('/api/user/email',
  authMiddleware,          // ✅ REUSE existing auth
  validateEmailInput,      // ✅ NEW validator (same pattern)
  userController.updateEmail  // ✅ NEW controller method (same pattern)
);

// controllers/UserController.ts (ADD new method following pattern)
class UserController {
  // ... existing methods ...

  async updateEmail(req, res) {
    // ✅ REUSE existing service.update method
    await this.userService.update(req.user.id, 'email', req.body);

    // ✅ FOLLOW consistent response format
    res.json({ success: true, message: 'Email updated' });
  }
}

// services/UserService.ts (EXTEND existing method)
class UserService {
  async update(userId: string, field: string, data: any) {
    const allowedFields = ['profile', 'password', 'settings', 'email'];  // ADD email

    if (!allowedFields.includes(field)) {
      throw new BadRequestError(`Cannot update field: ${field}`);
    }

    // Field-specific logic
    if (field === 'email') {
      await this.verifyEmailNotTaken(data.email);  // Email-specific validation
    }

    // ✅ REUSE existing transaction + audit logging
    await prisma.$transaction([
      prisma.user.update({
        where: { id: userId },
        data: { [field]: data }
      }),
      prisma.auditLog.create({
        data: {
          userId,
          action: `update_${field}`,
          timestamp: new Date()
        }
      })
    ]);
  }

  private async verifyEmailNotTaken(email: string) {
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictError('Email already in use');
  }
}
```

### Step 9: Validate Reuse

**Checklist**:
- ✅ Uses same authMiddleware (JWT auth)
- ✅ Uses same validation pattern (Joi middleware)
- ✅ Uses same controller structure (async method, service call)
- ✅ Uses same service method (centralized update logic)
- ✅ Uses same response format ({ success, message })
- ✅ Maintains consistency with other user endpoints
- ✅ No code duplication
- ✅ Reuses existing audit logging
- ✅ Reuses existing transaction handling

**Code added**:
- 10 lines (validation middleware)
- 5 lines (route definition)
- 5 lines (controller method)
- 3 lines (service update - added 'email' to allowedFields)
- 5 lines (email verification helper)
- **Total: 28 lines**

**Code reused**:
- authMiddleware (~30 lines)
- Service update logic (~40 lines)
- Transaction handling (~20 lines)
- Audit logging (~15 lines)
- Error handling (global middleware ~50 lines)
- **Total: ~155 lines**

**Duplication prevented**: 155 lines of potentially duplicated code

## Comparison

### Without Anti-Duplication

```
Code written: ~80 lines (inline auth, validation, error handling, database access)
Code reused: 0 lines
Duplication: High
Consistency: Low (different from other endpoints)
Maintainability: Poor (5th variation of same pattern)
```

### With Anti-Duplication

```
Code written: 28 lines (minimal additions to existing pattern)
Code reused: 155 lines
Duplication: None
Consistency: High (identical to other user update endpoints)
Maintainability: Excellent (single source of truth)
```

## Benefits Realized

**Development time**:
- Without: 45 minutes (write from scratch, test, debug)
- With: 15 minutes (search 5 min, implement 10 min)
- **Saved: 30 minutes (67% faster)**

**Code quality**:
- Consistent auth across all endpoints
- Consistent validation approach
- Centralized update logic (easy to modify)
- Reused transaction handling (no race conditions)
- Reused audit logging (compliance tracking)

**Future maintenance**:
- Bug fix in auth? Fixed once, applies to all endpoints
- Change validation library? Update validator pattern, applies to all
- Add rate limiting? Add to middleware chain, applies to all
- Security audit? Review once, validates all similar endpoints

## Lessons Learned

1. **Search before implementing**: Takes 5 minutes, saves hours of refactoring
2. **Present options**: User makes informed decision on reuse vs new
3. **Follow patterns**: Consistency > cleverness
4. **Extend, don't duplicate**: Add to existing structure rather than creating parallel structure
5. **Centralize logic**: Service layer handles complexity, routes/controllers stay thin
6. **Validate reuse**: Checklist ensures full pattern compliance

This example demonstrates the power of anti-duplication: 28 lines written, 155 lines reused, perfect consistency, 67% faster development.
