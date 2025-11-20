# Reuse Patterns

Guide to effectively reusing existing code: when to reuse directly, when to extend, when to extract abstractions, and when to create new implementations.

## Reuse vs. New Implementation Decision Matrix

| Similarity | Domain Match | Operation Match | Recommended Action |
|-----------|--------------|-----------------|-------------------|
| 95-100% | ✅ Same | ✅ Same | **Reuse directly** |
| 80-94% | ✅ Same | ❌ Different | **Extend existing** |
| 80-94% | ❌ Different | ✅ Same | **Extract pattern** (if 3+ similar) |
| 60-79% | Either | Either | **Follow pattern**, adapt as needed |
| <60% | Either | Either | **New implementation**, document why |

## Reuse Pattern 1: Direct Reuse

### When to Apply
- Found code that does exactly what you need
- No modifications required
- Same inputs, same outputs, same behavior

### Example: Reusing Email Service

**Request**: "Send a welcome email when user registers"

**Found**:
```typescript
// services/EmailService.ts
class EmailService {
  async sendEmail(to: string, subject: string, template: string, data: any) {
    // ... implementation
  }

  async sendWelcomeEmail(user: User) {
    await this.sendEmail(
      user.email,
      'Welcome to App!',
      'welcome',
      { userName: user.name }
    );
  }
}
```

**Action**: **Reuse directly**

```typescript
// controllers/AuthController.ts
import { EmailService } from '@/services/EmailService';

async register(req, res) {
  const user = await this.userService.create(req.body);

  // REUSE existing method
  await this.emailService.sendWelcomeEmail(user);

  res.json({ user });
}
```

**Benefits**:
- Zero new code
- Tested and working
- Consistent email sending across app

## Reuse Pattern 2: Extend Existing

### When to Apply
- Found code in same domain but different operation
- Core logic is reusable, needs new method/variant
- Extending is simpler than creating new class/module

### Example: Extending UserController

**Request**: "Create endpoint to update user email"

**Found**:
```typescript
// controllers/UserController.ts
class UserController {
  async updateProfile(req, res) {
    await this.userService.update(req.user.id, 'profile', req.body);
    res.json({ success: true });
  }

  async updatePassword(req, res) {
    await this.userService.update(req.user.id, 'password', req.body);
    res.json({ success: true });
  }
}
```

**Pattern identified**: Generic `update` method with field parameter

**Action**: **Extend existing controller**

```typescript
// controllers/UserController.ts (EXTEND)
class UserController {
  // ... existing methods ...

  async updateEmail(req, res) {
    // ADD email validation
    const { email } = req.body;
    await this.validateEmail(email);

    // REUSE existing update pattern
    await this.userService.update(req.user.id, 'email', { email });
    res.json({ success: true });
  }

  private async validateEmail(email: string) {
    // Validation logic
  }
}
```

**Benefits**:
- Reuses existing `userService.update` logic
- Maintains consistency with other update endpoints
- Centralized in one controller (not scattered)

### Extension Guidelines

**DO extend when**:
- New functionality is closely related to existing
- Extension is natural (doesn't force the abstraction)
- <50 lines of new code
- No breaking changes to existing methods

**DON'T extend when**:
- New functionality is orthogonal (different concern)
- Extension would make class/module too large (>500 lines)
- Would require breaking changes
- Different lifecycle or dependencies

## Reuse Pattern 3: Extract Shared Pattern

### When to Apply
- Found 3+ similar implementations in different domains
- Clear repeating structure
- Abstraction would reduce duplication and improve consistency

### Example: Extracting DetailCard Pattern

**Request**: "Create a component to display product details"

**Found 3 similar components**:

```typescript
// UserDetailCard.tsx
function UserDetailCard({ user }: { user: User }) {
  return (
    <Card>
      <CardHeader>{user.name}</CardHeader>
      <CardBody>
        <Field label="Email" value={user.email} />
        <Field label="Role" value={user.role} />
      </CardBody>
      <CardActions>
        <Button>Edit</Button>
      </CardActions>
    </Card>
  );
}

// OrderDetailCard.tsx
function OrderDetailCard({ order }: { order: Order }) {
  return (
    <Card>
      <CardHeader>{order.id}</CardHeader>
      <CardBody>
        <Field label="Status" value={order.status} />
        <Field label="Total" value={order.total} />
      </CardBody>
      <CardActions>
        <Button>Cancel</Button>
      </CardActions>
    </Card>
  );
}

// CustomerDetailCard.tsx (similar structure)
```

**Pattern identified**: DetailCard with header, body (fields), and actions

**Action**: **Extract generic pattern** (Rule of Three applies: 3+ similar → abstract)

```typescript
// components/common/DetailCard.tsx (NEW GENERIC)
interface DetailCardProps<T> {
  title: string;
  data: T;
  fields: Array<{
    label: string;
    key: keyof T;
    render?: (value: any) => ReactNode;
  }>;
  actions?: ReactNode;
}

export function DetailCard<T>({ title, data, fields, actions }: DetailCardProps<T>) {
  return (
    <Card>
      <CardHeader>{title}</CardHeader>
      <CardBody>
        {fields.map((field) => (
          <Field
            key={String(field.key)}
            label={field.label}
            value={field.render ? field.render(data[field.key]) : data[field.key]}
          />
        ))}
      </CardBody>
      {actions && <CardActions>{actions}</CardActions>}
    </Card>
  );
}

// components/users/UserDetailCard.tsx (REFACTOR to use generic)
export function UserDetailCard({ user }: { user: User }) {
  return (
    <DetailCard
      title={user.name}
      data={user}
      fields={[
        { label: 'Email', key: 'email' },
        { label: 'Role', key: 'role' },
      ]}
      actions={<Button>Edit</Button>}
    />
  );
}

// components/products/ProductDetailCard.tsx (NEW, uses generic)
export function ProductDetailCard({ product }: { product: Product }) {
  return (
    <DetailCard
      title={product.name}
      data={product}
      fields={[
        { label: 'Price', key: 'price', render: (val) => `$${val}` },
        { label: 'Stock', key: 'stock', render: (val) => `${val} units` },
        { label: 'Category', key: 'category' },
      ]}
      actions={<Button>Edit</Button>}
    />
  );
}
```

**Benefits**:
- 4 components now share 1 generic implementation
- Consistent UI/UX across all detail views
- Easy to add new entity detail cards
- Centralized changes (update DetailCard updates all entities)

### Extraction Guidelines

**Rule of Three**: Extract abstraction when you have 3+ similar implementations

**DO extract when**:
- 3+ similar pieces of code
- Clear common structure
- Variation is in data, not logic
- Abstraction simplifies (not complicates)

**DON'T extract when**:
- Only 2 similar pieces (not worth abstraction yet)
- Similarities are superficial
- Abstraction adds more complexity than it removes
- Edge cases would require many configuration options

### Abstraction Levels

**Level 1: Utility function** (simplest)
- Extract repeated logic into shared function
- Example: `formatCurrency`, `validateEmail`

**Level 2: Higher-order function**
- Extract repeated pattern, parameterize differences
- Example: `withAuth(handler)`, `withErrorHandling(fn)`

**Level 3: Generic component/class**
- Extract repeated structure, parameterize data type
- Example: `DetailCard<T>`, `List<T>`

**Level 4: Framework/library**
- Extract entire subsystem (only for very mature, stable patterns)
- Example: Form library, data-fetching library

Start with Level 1, move to higher levels only when justified.

## Reuse Pattern 4: Follow Established Pattern

### When to Apply
- Found similar code but not similar enough to reuse directly
- Clear pattern/convention in codebase
- New code should maintain consistency

### Example: Following API Endpoint Pattern

**Request**: "Create endpoint GET /api/products/:id"

**Found existing endpoints**:

```typescript
// routes/user.ts
router.get('/api/user/:id',
  authMiddleware,           // Pattern: Auth first
  validateParams,           // Pattern: Validation second
  userController.getById,   // Pattern: Controller method
  errorHandler              // Pattern: Error handling last
);

// routes/order.ts
router.get('/api/order/:id',
  authMiddleware,
  validateParams,
  orderController.getById,
  errorHandler
);
```

**Pattern identified**:
1. Auth middleware
2. Validation middleware
3. Controller method (named `getById`)
4. Error handler

**Action**: **Follow pattern** for new endpoint

```typescript
// routes/product.ts (NEW, follows established pattern)
router.get('/api/product/:id',
  authMiddleware,              // ✅ Same as other endpoints
  validateParams,              // ✅ Same as other endpoints
  productController.getById,   // ✅ Following naming convention
  errorHandler                 // ✅ Same as other endpoints
);

// controllers/ProductController.ts (NEW, follows controller pattern)
class ProductController {
  async getById(req: Request, res: Response) {  // ✅ Consistent method name
    const product = await this.productService.findById(req.params.id);

    if (!product) {
      throw new NotFoundError('Product not found');  // ✅ Same error handling
    }

    res.json({ product });  // ✅ Consistent response structure
  }
}
```

**Benefits**:
- Consistent middleware chain across all endpoints
- Predictable error handling
- Easy to understand (follows established convention)
- Easier onboarding (learn pattern once, applies everywhere)

### Pattern Following Guidelines

**Identify patterns by**:
- Consistent naming conventions
- Repeated code structure
- Common middleware chains
- Shared configuration

**Document patterns when**:
- Used in 3+ places
- Important for consistency
- Not obvious from code alone

**Enforce patterns through**:
- Code reviews
- Linting rules (ESLint custom rules)
- Templates/scaffolding
- Anti-duplication checks (this skill!)

## Reuse Pattern 5: Adapt with Justification

### When to Apply
- Found similar code but it doesn't fit well
- Reusing would require awkward workarounds
- New approach is justified by specific requirements

### Example: Justified New Implementation

**Request**: "Create a real-time product availability tracker"

**Found**:
```typescript
// services/ProductService.ts
class ProductService {
  async getProductAvailability(productId: string): Promise<boolean> {
    const product = await prisma.product.findUnique({ where: { id: productId } });
    return product.stock > 0;
  }
}
```

**Why not reuse**:
- Existing method is synchronous polling (fetch when needed)
- New requirement is real-time updates (WebSocket stream)
- Different architecture (pub/sub vs request/response)

**Action**: **New implementation with documented justification**

```typescript
// services/ProductAvailabilityTracker.ts (NEW)
/**
 * Real-time product availability tracking via WebSocket
 *
 * DOES NOT REUSE: ProductService.getProductAvailability()
 *
 * Justification:
 * - Existing method is synchronous polling (fetch-on-demand)
 * - New requirement is real-time push updates (WebSocket streams)
 * - Incompatible architectures:
 *   - Existing: HTTP request/response
 *   - New: WebSocket pub/sub
 *
 * Future refactoring:
 * - Consider extracting shared stock checking logic
 * - Existing method could subscribe to this tracker for updates
 */
class ProductAvailabilityTracker {
  private wsServer: WebSocketServer;
  private subscribers: Map<string, Set<WebSocket>>;

  constructor() {
    // WebSocket setup
    this.subscribeToInventoryChanges();
  }

  subscribe(productId: string, ws: WebSocket) {
    // Real-time subscription logic
  }

  private subscribeToInventoryChanges() {
    // Listen to inventory database changes
    // Publish updates to subscribers
  }
}
```

**Justification documented**:
- Why existing code doesn't fit
- What's fundamentally different
- Future refactoring possibilities

### Justification Guidelines

**Always document**:
- Why existing code can't be reused
- What makes this implementation different
- Whether this indicates missing abstraction
- Future refactoring opportunities

**Good justifications**:
- "Different architecture (sync vs async, polling vs streaming)"
- "Different performance requirements (batch vs real-time)"
- "Different security model (public vs authenticated)"
- "Existing implementation is anti-pattern (will be refactored)"

**Bad justifications**:
- "I didn't find existing code" (search harder)
- "Existing code is in different file" (import it)
- "It's easier to write from scratch" (not a valid reason)
- "I don't like the existing code" (refactor it, don't duplicate)

## Anti-Patterns to Avoid

### Anti-Pattern: Copy-Paste Programming

**Problem**: Copying code and modifying slightly

```typescript
// Bad: UserService.ts
async createUser(data) {
  const validation = this.validateUserData(data);
  if (!validation.valid) throw new Error(validation.error);

  const user = await prisma.user.create({ data });
  await this.emailService.send(user.email, 'Welcome');
  return user;
}

// Bad: ProductService.ts (copy-pasted from UserService)
async createProduct(data) {
  const validation = this.validateProductData(data);  // Slightly different
  if (!validation.valid) throw new Error(validation.error);

  const product = await prisma.product.create({ data });
  await this.emailService.send('admin@app.com', 'New product');  // Slightly different
  return product;
}
```

**Solution**: Extract shared pattern

```typescript
// Good: BaseService.ts
abstract class BaseService<T> {
  abstract validate(data: any): ValidationResult;
  abstract onCreate(entity: T): Promise<void>;

  async create(data: any): Promise<T> {
    const validation = this.validate(data);
    if (!validation.valid) throw new Error(validation.error);

    const entity = await this.repository.create({ data });
    await this.onCreate(entity);
    return entity;
  }
}

// Good: UserService.ts
class UserService extends BaseService<User> {
  validate(data: any) { /* user validation */ }

  async onCreate(user: User) {
    await this.emailService.send(user.email, 'Welcome');
  }
}

// Good: ProductService.ts
class ProductService extends BaseService<Product> {
  validate(data: any) { /* product validation */ }

  async onCreate(product: Product) {
    await this.emailService.send('admin@app.com', 'New product');
  }
}
```

### Anti-Pattern: Ignoring Existing Patterns

**Problem**: Implementing new feature without checking existing patterns

**Solution**: Always search first, follow established patterns

### Anti-Pattern: Premature Abstraction

**Problem**: Creating generic abstraction after finding only 2 similar pieces

**Solution**: Wait for 3+ similar pieces (Rule of Three)

### Anti-Pattern: Over-Abstraction

**Problem**: Creating overly complex generic that's harder to use than duplicating code

```typescript
// Bad: Over-abstracted
function createGenericCRUDController<
  T,
  CreateDTO,
  UpdateDTO,
  QueryDTO,
  ResponseDTO,
  FilterOptions,
  SortOptions
>(config: ControllerConfig<T, CreateDTO, UpdateDTO...>) {
  // 500 lines of complex generic logic
  // 20 configuration options
  // Hard to understand, hard to debug
}
```

**Solution**: Keep abstractions simple, only add complexity when needed

```typescript
// Good: Simple abstraction
abstract class CRUDController<T> {
  abstract create(data: any): Promise<T>;
  abstract findAll(query?: any): Promise<T[]>;
  abstract findOne(id: string): Promise<T>;
  abstract update(id: string, data: any): Promise<T>;
  abstract delete(id: string): Promise<void>;
}

// Concrete implementations can add complexity as needed
```

## Summary

**Decision flow**:
1. **Search** for existing similar code
2. **Categorize** findings (exact, close, pattern, distant)
3. **Decide**:
   - 95-100% similar + same domain → **Reuse directly**
   - 80-94% similar + same domain → **Extend existing**
   - 80-94% similar + 3+ instances → **Extract pattern** (Rule of Three)
   - 60-79% similar → **Follow pattern**, adapt as needed
   - <60% similar → **New implementation**, document justification

**Key principles**:
- Reuse is better than reimplementation
- Consistency is better than cleverness
- Simple abstraction is better than duplication
- Complex abstraction is worse than duplication
- Always justify when NOT reusing existing code

**Rule of Three**: Only create abstraction when you have 3 or more similar pieces
