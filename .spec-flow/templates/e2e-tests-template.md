# E2E Test Suite

## Overview

This document defines comprehensive End-to-End (E2E) tests for validating complete user workflows from start to finish. E2E tests validate the entire application stack, including external integrations, to ensure production readiness.

**Testing Philosophy**:
- **Complete user journeys**: Test flows as users experience them, not just individual APIs
- **External integrations**: Verify third-party services (GitHub CLI, APIs, webhooks)
- **Production-like environment**: Use Docker for reproducible, isolated testing
- **Verify outcomes**: Check actual results in production systems (commits, database, notifications)

---

## Critical User Journeys

### Journey 1: [Journey Name]

**User Story**: [Copy from spec.md - e.g., "As a user, I want to create an account so I can access the dashboard"]

**Priority**: [P1 (MVP) | P2 (Enhancement) | P3 (Nice-to-have)]

**Scenario**:
- **Given**: [Initial state - e.g., "User navigates to /signup page"]
- **When**: [User action - e.g., "User fills registration form and submits"]
- **Then**: [Expected outcome - e.g., "Account created, user redirected to /dashboard with welcome message"]

**Test Steps**:
1. [Step 1 - e.g., "Navigate to /signup"]
2. [Step 2 - e.g., "Fill email: test@example.com"]
3. [Step 3 - e.g., "Fill password: SecurePass123!"]
4. [Step 4 - e.g., "Click 'Create Account' button"]
5. [Step 5 - e.g., "Wait for redirect"]

**Expected Results**:
- [ ] HTTP 201 Created response from /api/auth/signup
- [ ] User record exists in database with correct email
- [ ] Verification email sent via SendGrid (or mocked)
- [ ] User redirected to /dashboard
- [ ] Dashboard shows personalized welcome message
- [ ] Session cookie set with valid JWT token

**External Integrations**:
- **Email Service** (SendGrid/Mailgun): Verification email sent
- **Database** (Postgres/MySQL): User record persisted
- **Authentication** (JWT/OAuth): Session token generated

**Test File**: `e2e/auth/registration.spec.ts` (or `.spec.js`, `.py`)

**Test Environment**:
- Docker container: `test-db` (Postgres with seed data)
- Docker container: `test-api` (Backend API server)
- Docker container: `test-frontend` (Frontend dev server)
- Mock services: SendGrid API (using msw or nock)

**Rollback/Cleanup**:
```bash
# Clean up test data after test completes
docker exec test-db psql -U postgres -d testdb -c "DELETE FROM users WHERE email='test@example.com';"
```

---

### Journey 2: [Journey Name]

**User Story**: [Copy from spec.md]

**Priority**: [P1 | P2 | P3]

**Scenario**:
- **Given**: [Initial state]
- **When**: [User action]
- **Then**: [Expected outcome]

**Test Steps**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Results**:
- [ ] [Result 1]
- [ ] [Result 2]
- [ ] [Result 3]

**External Integrations**:
- [Integration 1]
- [Integration 2]

**Test File**: `e2e/[domain]/[test-name].spec.ts`

**Test Environment**:
- [Docker setup]
- [Mock services]

**Rollback/Cleanup**:
```bash
[Cleanup commands]
```

---

### Journey 3: [Journey Name]

**User Story**: [Copy from spec.md]

**Priority**: [P1 | P2 | P3]

**Scenario**:
- **Given**: [Initial state]
- **When**: [User action]
- **Then**: [Expected outcome]

**Test Steps**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Results**:
- [ ] [Result 1]
- [ ] [Result 2]
- [ ] [Result 3]

**External Integrations**:
- [Integration 1]
- [Integration 2]

**Test File**: `e2e/[domain]/[test-name].spec.ts`

**Test Environment**:
- [Docker setup]
- [Mock services]

**Rollback/Cleanup**:
```bash
[Cleanup commands]
```

---

## Test Framework Selection

**Recommended Frameworks** (choose based on tech stack):

### Frontend-Heavy Applications
- **Playwright** (recommended): Multi-browser, fast, reliable
- **Cypress**: Developer-friendly, great debugging
- **Puppeteer**: Chrome-only, lightweight

### API-Heavy Applications
- **Jest + Supertest**: Node.js API testing
- **pytest + requests**: Python API testing
- **RestAssured**: Java API testing

### Full-Stack Applications
- **Playwright** (frontend) + **Supertest** (API backend)

---

## Test Isolation Strategy

**Docker Compose Setup**:
```yaml
# docker-compose.test.yml
version: '3.8'

services:
  test-db:
    image: postgres:15
    environment:
      POSTGRES_DB: testdb
      POSTGRES_USER: testuser
      POSTGRES_PASSWORD: testpass
    ports:
      - "5433:5432"  # Different port to avoid conflicts
    volumes:
      - ./test-seed-data.sql:/docker-entrypoint-initdb.d/seed.sql

  test-api:
    build: ./backend
    environment:
      DATABASE_URL: postgres://testuser:testpass@test-db:5432/testdb
      NODE_ENV: test
    ports:
      - "3001:3000"
    depends_on:
      - test-db

  test-frontend:
    build: ./frontend
    environment:
      VITE_API_URL: http://test-api:3000
      NODE_ENV: test
    ports:
      - "3002:3000"
    depends_on:
      - test-api
```

**Isolation Principles**:
1. **Separate test database**: Never use production or development DB
2. **Seed data**: Load known test data before each test suite
3. **Cleanup after tests**: Delete test records to prevent pollution
4. **Mock external APIs**: Use msw, nock, or WireMock
5. **Parallel execution**: Use unique test data per test (different email/ID)

---

## External Integration Testing

### Pattern 1: Mock External APIs

**When to use**: External service is slow, rate-limited, or costs money

**Example** (SendGrid email):
```typescript
// Mock SendGrid API
import { rest } from 'msw';
import { setupServer } from 'msw/node';

const server = setupServer(
  rest.post('https://api.sendgrid.com/v3/mail/send', (req, res, ctx) => {
    return res(ctx.status(202), ctx.json({ message: 'Email sent' }));
  })
);

beforeAll(() => server.listen());
afterAll(() => server.close());
```

### Pattern 2: Test Against Real APIs (Staging)

**When to use**: Integration is critical and must be validated end-to-end

**Example** (GitHub API):
```typescript
// Use GitHub staging API with test account
const GITHUB_TOKEN = process.env.GITHUB_TEST_TOKEN;
const TEST_REPO = 'test-org/test-repo';

test('Create GitHub issue via API', async () => {
  const response = await fetch(
    `https://api.github.com/repos/${TEST_REPO}/issues`,
    {
      method: 'POST',
      headers: {
        Authorization: `token ${GITHUB_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        title: 'Test issue from E2E test',
        body: 'This issue will be auto-closed'
      })
    }
  );

  expect(response.status).toBe(201);
  const issue = await response.json();

  // Cleanup: Close issue
  await fetch(
    `https://api.github.com/repos/${TEST_REPO}/issues/${issue.number}`,
    {
      method: 'PATCH',
      headers: { Authorization: `token ${GITHUB_TOKEN}` },
      body: JSON.stringify({ state: 'closed' })
    }
  );
});
```

### Pattern 3: Test CLI Tools

**When to use**: Application uses CLI tools (gh, docker, kubectl, etc.)

**Example** (GitHub CLI):
```bash
#!/bin/bash
# e2e/cli/github-integration.sh

# Test GitHub CLI integration
export GH_TOKEN=$GITHUB_TEST_TOKEN
export TEST_REPO="test-org/test-repo"

# Create issue via CLI
ISSUE_URL=$(gh issue create --repo $TEST_REPO \
  --title "Test issue from E2E" \
  --body "This will be auto-closed" \
  --label "test")

# Verify issue exists
gh issue view --repo $TEST_REPO "$ISSUE_URL"

# Cleanup: Close issue
gh issue close --repo $TEST_REPO "$ISSUE_URL"
```

---

## Verification in Production Systems

**Principle**: Don't just check API responses—verify outcomes in actual systems.

### Database Verification
```typescript
// After creating user, verify in database
const user = await db.query('SELECT * FROM users WHERE email = $1', ['test@example.com']);
expect(user.rows[0]).toMatchObject({
  email: 'test@example.com',
  status: 'active',
  email_verified: false
});
```

### File System Verification
```bash
# After git commit, verify commit exists
git log --oneline | grep "Test commit message"
test -f path/to/created/file.txt
```

### External Service Verification
```typescript
// After triggering webhook, verify event received
const webhookEvents = await fetchWebhookHistory();
expect(webhookEvents).toContainEqual(
  expect.objectContaining({
    event: 'user.created',
    data: { email: 'test@example.com' }
  })
);
```

---

## Test Execution

### Local Execution
```bash
# Start test environment
docker-compose -f docker-compose.test.yml up -d

# Wait for services to be ready
./wait-for-services.sh

# Run E2E tests
npm run test:e2e  # or pytest e2e/ or ./run-e2e-tests.sh

# Cleanup
docker-compose -f docker-compose.test.yml down -v
```

### CI/CD Execution
```yaml
# .github/workflows/e2e-tests.yml
name: E2E Tests

on: [pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Start test environment
        run: docker-compose -f docker-compose.test.yml up -d

      - name: Wait for services
        run: ./wait-for-services.sh

      - name: Run E2E tests
        run: npm run test:e2e

      - name: Cleanup
        if: always()
        run: docker-compose -f docker-compose.test.yml down -v
```

---

## Success Criteria

**Before marking E2E tests complete:**
- [ ] All critical user journeys (P1) have passing E2E tests
- [ ] External integrations tested (mocked or staging)
- [ ] Tests run in isolated Docker environment
- [ ] Outcomes verified in production systems (DB, files, APIs)
- [ ] Cleanup scripts prevent test data pollution
- [ ] Tests pass in CI/CD pipeline
- [ ] Test execution time < 10 minutes (total)

---

## Anti-Patterns to Avoid

### ❌ Don't: Test Internal APIs Only
```typescript
// BAD: Only tests API endpoint, not user workflow
test('POST /api/users creates user', async () => {
  const response = await request(app).post('/api/users').send({ email: 'test@example.com' });
  expect(response.status).toBe(201);
});
```

### ✅ Do: Test Complete User Journey
```typescript
// GOOD: Tests entire registration flow as user experiences it
test('User can register and access dashboard', async () => {
  await page.goto('/signup');
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="password"]', 'SecurePass123!');
  await page.click('[type="submit"]');

  // Verify redirect
  await expect(page).toHaveURL('/dashboard');

  // Verify welcome message
  await expect(page.locator('.welcome')).toContainText('Welcome, test@example.com');

  // Verify database
  const user = await db.query('SELECT * FROM users WHERE email = $1', ['test@example.com']);
  expect(user.rows).toHaveLength(1);
});
```

### ❌ Don't: Use Production Services
```typescript
// BAD: Sends real email in test
await sendEmail({ to: 'test@example.com', subject: 'Test' });
```

### ✅ Do: Mock External Services
```typescript
// GOOD: Mocks email service
server.use(
  rest.post('https://api.sendgrid.com/v3/mail/send', (req, res, ctx) => {
    return res(ctx.status(202));
  })
);
```

### ❌ Don't: Leave Test Data Behind
```typescript
// BAD: Creates test data but doesn't clean up
await createUser({ email: 'test@example.com' });
// Test ends without cleanup
```

### ✅ Do: Clean Up After Tests
```typescript
// GOOD: Cleanup in afterEach
afterEach(async () => {
  await db.query('DELETE FROM users WHERE email = $1', ['test@example.com']);
});
```

---

## Notes

**Template Version**: 1.0 (2025-11-20)

**Generated by**: /tasks phase (epic workflows only)

**Integration with /optimize**: E2E tests run as Gate 7 in /optimize phase

**CI/CD Integration**: E2E test results reviewed in /validate-staging phase

**Reference**: This template aligns with comprehensive validation meta-prompt philosophy—test complete user workflows, not just internal APIs.
