# Continuous Testing

## Test Cadence

**Run tests frequently during implementation:**

### After Each Task Triplet (RED-GREEN-REFACTOR)
```bash
npm test  # or pytest, cargo test, etc.
```

### Before Every Commit
```bash
npm test && git commit -m "feat: add feature"
```

### After Each Batch (3-5 tasks)
```bash
npm test
npm run lint
npm run type-check  # TypeScript only
```

**TypeScript Type Safety Enforcement**:

For TypeScript projects, invoke `type-enforcer` agent after completing a batch of tasks:
- Eliminates implicit `any` types
- Enforces null-safety guards (`strictNullChecks`)
- Validates discriminated unions have exhaustive pattern matching
- Blocks unsafe type assertions (`as` keyword)
- Ensures `noImplicitAny` and `strict` mode compliance

**When to use type-enforcer**:
- ✅ After implementing new modules/functions
- ✅ After refactoring that changes type signatures
- ✅ Before committing TypeScript code
- ✅ When adding external library integrations
- ❌ Not applicable for JavaScript-only projects

---

## Test Types

### Unit Tests (Fastest)
- Test individual functions/methods
- No external dependencies
- Run after each task

### Integration Tests (Medium)
- Test multiple components together
- Use test database
- Run after each batch

### Security Validation (Selective)
- Run after implementing security-sensitive features
- **Tool**: `security-sentry` agent
- **Checks**: SQL injection, XSS, CSRF, hardcoded secrets, missing auth
- **Blocking**: CRITICAL vulnerabilities block deployment

**When to use security-sentry**:
- ✅ Authentication/authorization flows (login, signup, password reset)
- ✅ User input handling (forms, API endpoints)
- ✅ File upload functionality
- ✅ Payment processing or financial transactions
- ✅ External API integrations with secrets
- ❌ Internal utility functions (no security risk)

**Example security checks**:
- SQL injection: Parameterized queries used?
- XSS: User input escaped/sanitized?
- CSRF: CSRF tokens on state-changing endpoints?
- Secrets: No hardcoded API keys/passwords?
- Auth: Protected routes require authentication?

### E2E Tests (Slowest)
- Test complete user flows
- Run before deployment only
- Optional during implementation

---

## Coverage Requirements

**Minimum**: 80% coverage (unit + integration)

**Check coverage**:
```bash
npm test -- --coverage
```

**See [../reference.md](../reference.md#continuous-testing) for complete testing guide**
