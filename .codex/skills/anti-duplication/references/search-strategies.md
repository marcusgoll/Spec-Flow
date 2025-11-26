# Search Strategies for Anti-Duplication

Comprehensive guide to searching codebases for existing implementations before writing new code.

## Core Search Principles

### Multi-Strategy Approach

Never rely on a single search. Use multiple complementary strategies:

1. **Keyword search** (Grep): Find by content
2. **File pattern search** (Glob): Find by naming
3. **Structural search** (Grep with regex): Find by code structure
4. **Domain search**: Find by business domain
5. **Technology search**: Find by framework/library patterns

### Search Order

**Narrow → Broad**:
1. Start with specific domain terms ("ProductDetailCard")
2. Expand to broader terms ("Product", "Detail", "Card")
3. Search for patterns ("*DetailCard", "Detail*")
4. Search for operations ("display", "render", "show")

**Exact → Fuzzy**:
1. Search for exact matches first
2. Then partial matches
3. Then related patterns
4. Finally similar operations in different domains

## Search Strategies by Artifact Type

### API Endpoints

**Express/Fastify patterns**:
```bash
# Find all GET endpoints
grep -r "router\.get\|app\.get" --include="*.ts" --include="*.js"

# Find specific resource endpoints
grep -r "router\.\(get\|post\|put\|patch\|delete\).*user" --include="*.ts"

# Find parameterized routes
grep -r "/:id\|/:.*Id" --include="*.ts"

# Find middleware usage
grep -r "authMiddleware\|authenticate" --include="*.ts"
```

**NestJS patterns**:
```bash
# Find controller decorators
grep -r "@Get\|@Post\|@Put\|@Patch\|@Delete" --include="*.ts"

# Find specific controllers
grep -r "@Controller.*user" --include="*.ts"

# Find guards/interceptors
grep -r "@UseGuards\|@UseInterceptors" --include="*.ts"
```

**File patterns**:
```bash
# Find route files
**/routes/**/*.ts
**/controllers/**/*.ts
**/api/**/*.ts

# Find specific resource routes
**/routes/**/user*.ts
**/routes/**/product*.ts
```

**Structural patterns**:
```typescript
// Find handler functions
grep -r "async.*req.*res\|function.*req.*res" --include="*.ts"

// Find validation middleware
grep -r "validate.*schema\|.*validator" --include="*.ts"

// Find error handlers
grep -r "catch.*error\|errorHandler" --include="*.ts"
```

### React Components

**Functional components**:
```bash
# Find function components
grep -r "function.*Component\|const.*=.*=>.*{" --include="*.tsx"

# Find React.FC components
grep -r "React\.FC\|FC<" --include="*.tsx"

# Find exported components
grep -r "export.*function.*\|export.*const.*=.*=>" --include="*.tsx"
```

**Component naming patterns**:
```bash
# Find by naming convention
grep -r "function.*Card\|const.*Card.*=" --include="*.tsx"
grep -r "function.*Modal\|const.*Modal.*=" --include="*.tsx"
grep -r "function.*Form\|const.*Form.*=" --include="*.tsx"
```

**File patterns**:
```bash
# Find component files
**/components/**/*.tsx
**/components/**/*.jsx

# Find specific domain components
**/components/**/Product*.tsx
**/components/**/User*.tsx

# Find by component type
**/components/**/\*Card.tsx
**/components/**/\*Modal.tsx
**/components/**/\*Form.tsx
```

**Hook patterns**:
```bash
# Find custom hooks
grep -r "export.*use[A-Z].*=\|function.*use[A-Z]" --include="*.ts" --include="*.tsx"

# Find specific hooks
grep -r "useState\|useEffect\|useQuery\|useMutation" --include="*.tsx"
```

### Services/Business Logic

**Class-based services**:
```bash
# Find service classes
grep -r "class.*Service" --include="*.ts"

# Find specific domain services
grep -r "class.*User.*Service\|class.*Product.*Service" --include="*.ts"

# Find dependency injection
grep -r "@Injectable\|@Inject" --include="*.ts"
```

**Function-based services**:
```bash
# Find exported service functions
grep -r "export.*async.*function\|export.*function" --include="*.ts"

# Find service utilities
grep -r "createService\|makeService" --include="*.ts"
```

**File patterns**:
```bash
# Find service files
**/services/**/*.ts
**/lib/**/*.ts
**/utils/**/*.ts

# Find specific domain services
**/services/**/*user*.ts
**/services/**/*product*.ts
**/services/**/*email*.ts
```

### Database Models

**Prisma**:
```bash
# Find model definitions
grep -r "model.*{" --include="*.prisma"

# Find specific models
grep -r "model User\|model Product" --include="*.prisma"

# Find relationships
grep -r "@relation" --include="*.prisma"
```

**TypeORM**:
```bash
# Find entity classes
grep -r "@Entity" --include="*.ts"

# Find column definitions
grep -r "@Column\|@PrimaryGeneratedColumn" --include="*.ts"

# Find relationships
grep -r "@OneToMany\|@ManyToOne\|@ManyToMany" --include="*.ts"
```

**Sequelize**:
```bash
# Find model definitions
grep -r "sequelize\.define\|Model\.init" --include="*.ts"

# Find model files
**/models/**/*.ts
**/models/**/*.js
```

**File patterns**:
```bash
# Find model files
**/models/**/*.ts
**/entities/**/*.ts
**/schema/**/*.prisma

# Find specific domain models
**/models/**/user*.ts
**/models/**/product*.ts
```

### GraphQL Resolvers

**Schema definitions**:
```bash
# Find type definitions
grep -r "type.*{" --include="*.graphql" --include="*.ts"

# Find queries/mutations
grep -r "type Query\|type Mutation" --include="*.graphql"

# Find specific types
grep -r "type User\|type Product" --include="*.graphql"
```

**Resolver implementations**:
```bash
# Find resolver objects
grep -r "Query:.*{\|Mutation:.*{" --include="*.ts"

# Find resolver functions
grep -r "async.*parent.*args.*context" --include="*.ts"

# Find specific resolvers
grep -r "user.*:\|product.*:" --include="*resolver*.ts"
```

**File patterns**:
```bash
# Find schema files
**/*.graphql
**/schema/**/*.ts

# Find resolver files
**/resolvers/**/*.ts
**/*resolver*.ts
```

## Domain-Driven Search

### Identifying Business Domains

Common domains in applications:
- **User/Auth**: Users, authentication, authorization, profiles
- **Product/Catalog**: Products, categories, inventory
- **Order/Commerce**: Orders, cart, checkout, payments
- **Content**: Posts, articles, comments, media
- **Communication**: Messages, notifications, emails
- **Analytics**: Metrics, reports, dashboards

### Domain-Specific Keywords

**User/Auth domain**:
```
Primary: user, User, USER, account, profile
Related: authentication, auth, login, signup, register, session, token, jwt
Operations: createUser, getUser, updateUser, deleteUser, authenticate, authorize
```

**Product domain**:
```
Primary: product, Product, PRODUCT, item, catalog
Related: inventory, stock, SKU, variant, category
Operations: createProduct, getProduct, updateProduct, deleteProduct, searchProducts
```

**Order domain**:
```
Primary: order, Order, ORDER, cart, checkout
Related: payment, shipping, fulfillment, transaction
Operations: createOrder, getOrder, updateOrder, cancelOrder, processPayment
```

### Cross-Domain Pattern Search

Find similar operations across different domains:

```bash
# Find all "detail" components across domains
grep -r "DetailCard\|DetailView\|Detail.*Component" --include="*.tsx"

# Find all CRUD services
grep -r "class.*Service.*{" --include="*.ts" | grep "create\|read\|update\|delete"

# Find all list/table components
grep -r "List\|Table\|Grid.*Component" --include="*.tsx"
```

## Technology-Specific Search

### TypeScript Patterns

**Type definitions**:
```bash
# Find interfaces
grep -r "interface.*{" --include="*.ts"

# Find type aliases
grep -r "type.*=" --include="*.ts"

# Find enums
grep -r "enum.*{" --include="*.ts"

# Find generics
grep -r "function.*<T>\|class.*<T>" --include="*.ts"
```

**Specific searches**:
```typescript
// Find all User types
grep -r "interface User\|type User.*=\|class User" --include="*.ts"

// Find nullable types
grep -r ".*\| null\|.*\| undefined\|.*?" --include="*.ts"

// Find type guards
grep -r "is [A-Z].*{" --include="*.ts"
```

### React-Specific Patterns

**Hooks**:
```bash
# Find useState usage
grep -r "useState<" --include="*.tsx"

# Find useEffect patterns
grep -r "useEffect\(\(\)" --include="*.tsx"

# Find custom hooks
grep -r "export.*function use[A-Z]" --include="*.ts" --include="*.tsx"
```

**Context**:
```bash
# Find context providers
grep -r "createContext\|React\.createContext" --include="*.tsx"

# Find context consumers
grep -r "useContext\|Context\.Consumer" --include="*.tsx"
```

**Props patterns**:
```bash
# Find props interfaces
grep -r "interface.*Props.*{" --include="*.tsx"

# Find prop destructuring
grep -r "function.*{.*}:.*Props" --include="*.tsx"
```

### GraphQL Patterns

**Queries**:
```bash
# Find query hooks
grep -r "useQuery\|useLazyQuery" --include="*.tsx"

# Find query definitions
grep -r "gql\`.*query" --include="*.ts" --include="*.tsx"
```

**Mutations**:
```bash
# Find mutation hooks
grep -r "useMutation" --include="*.tsx"

# Find mutation definitions
grep -r "gql\`.*mutation" --include="*.ts" --include="*.tsx"
```

### Database Patterns

**Prisma**:
```bash
# Find Prisma client usage
grep -r "prisma\.[a-z]*\.(findMany\|findUnique\|create\|update\|delete)" --include="*.ts"

# Find transactions
grep -r "prisma\.\$transaction" --include="*.ts"

# Find raw queries
grep -r "prisma\.\$queryRaw" --include="*.ts"
```

**SQL patterns**:
```bash
# Find SELECT queries
grep -r "SELECT.*FROM" --include="*.ts" --include="*.sql"

# Find INSERT queries
grep -r "INSERT INTO" --include="*.ts" --include="*.sql"

# Find parameterized queries
grep -r "\\$[0-9]\|\?" --include="*.ts"
```

## Advanced Search Techniques

### Regex Patterns

**Find function definitions**:
```bash
# Any function
grep -rE "(function|const|let|var).*=.*(\(|=>)" --include="*.ts"

# Async functions
grep -rE "async.*(function|\(.*\).*=>)" --include="*.ts"

# Arrow functions
grep -rE "(const|let|var).*=.*=>.*{" --include="*.ts"
```

**Find class patterns**:
```bash
# Class definitions
grep -rE "class [A-Z][a-zA-Z]*" --include="*.ts"

# Class with inheritance
grep -rE "class.*extends [A-Z]" --include="*.ts"

# Class with decorators
grep -rE "@[A-Z].*\nclass" --include="*.ts"
```

### Combining Searches

**Multi-step search strategy**:

1. **Broad domain search** (cast wide net):
```bash
grep -r "product" --include="*.ts" --include="*.tsx"
```

2. **Filter by artifact type** (narrow to components):
```bash
grep -r "product" --include="*.tsx" | grep "function\|const.*="
```

3. **Filter by operation** (narrow to detail views):
```bash
grep -r "product.*detail\|product.*card" --include="*.tsx"
```

4. **Verify with file glob** (confirm file structure):
```bash
ls **/components/**/Product*.tsx
```

### Performance Optimization

**Use ripgrep (rg) for speed**:
```bash
# Fast multi-pattern search
rg "product|Product|PRODUCT" --type ts --type tsx

# With context lines
rg "class.*Service" -A 5 -B 2

# Case-insensitive
rg -i "user.*service"
```

**Limit search scope**:
```bash
# Only search src/ directory
grep -r "pattern" src/

# Exclude node_modules, dist, build
grep -r "pattern" --exclude-dir={node_modules,dist,build}
```

## Search Result Analysis

### Categorizing Findings

After search completes, categorize results:

**Exact matches** (95-100% similar):
- Same domain, same operation, same structure
- Example: Found UserService.sendEmail(), need ProductService.sendEmail()
- Action: Direct reuse or minimal adaptation

**Close matches** (75-94% similar):
- Same domain, different operation OR different domain, same operation
- Example: Found UserList component, need UserDetail component
- Action: Extend existing or extract shared pattern

**Pattern matches** (50-74% similar):
- Similar structure, different domain
- Example: Found CRUD endpoints for User, need CRUD for Product
- Action: Follow established pattern

**Distant matches** (<50% similar):
- Loosely related
- Example: Found authentication service, need email service
- Action: Learn from approach, but implement differently

### Ranking by Relevance

Score findings:
- **Domain match**: +40 points (same domain like User/User)
- **Operation match**: +30 points (same operation like create/create)
- **Structure match**: +20 points (same artifact type like component/component)
- **Technology match**: +10 points (same framework like React/React)

**Relevance score**:
- 90-100: Exact match (reuse directly)
- 70-89: Close match (extend or adapt)
- 50-69: Pattern match (follow structure)
- <50: Distant match (reference only)

## Common Search Patterns

### "Create API endpoint" searches:
```bash
grep -r "router\.(get|post|put|patch|delete)" --include="*.ts"
grep -r "/api/.*${domain}" --include="*.ts"
ls **/routes/**/*${domain}*.ts
grep -r "authMiddleware\|authenticate" --include="*.ts"
```

### "Create React component" searches:
```bash
grep -r "function.*${ComponentName}" --include="*.tsx"
grep -r "const.*${ComponentName}.*=" --include="*.tsx"
ls **/components/**/*${ComponentName}*.tsx
grep -r "interface.*${ComponentName}Props" --include="*.tsx"
```

### "Create service" searches:
```bash
grep -r "class.*${DomainName}.*Service" --include="*.ts"
grep -r "export.*${operationName}" --include="*.ts"
ls **/services/**/*${domain}*.ts
grep -r "@Injectable.*${DomainName}" --include="*.ts"
```

### "Create database model" searches:
```bash
grep -r "model ${ModelName}" --include="*.prisma"
grep -r "@Entity.*${ModelName}" --include="*.ts"
ls **/models/**/*${domain}*.ts
grep -r "interface ${ModelName}.*{" --include="*.ts"
```

## Summary

**Core principles**:
- Use multiple search strategies (keywords, files, patterns, domain, technology)
- Start narrow (specific terms), expand broad (related patterns)
- Combine Grep (content) + Glob (files) + Regex (structure)
- Categorize results (exact, close, pattern, distant)
- Rank by relevance (domain + operation + structure + technology)

**Time budget**:
- Simple search: 5 seconds
- Comprehensive search: 10-15 seconds
- Complex multi-domain search: 20-30 seconds

**Coverage goal**:
- Find 80%+ of relevant existing code
- Miss rate <20% (acceptable trade-off for speed)

The goal is not 100% coverage (too slow), but high-probability detection of existing similar code to prevent duplication.
