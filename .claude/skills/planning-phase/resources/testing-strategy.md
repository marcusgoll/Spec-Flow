# Testing Strategy

**Purpose**: Plan test coverage before implementation (test-first mindset).

---

## Test Types

### Unit Tests (Fastest)
- **What**: Individual functions, methods
- **Coverage**: 80%+ required
- **Tools**: pytest, Jest, Vitest

### Integration Tests (Medium)
- **What**: Multiple components together (API + DB)
- **Coverage**: Critical paths
- **Tools**: pytest with test DB, Supertest

### E2E Tests (Slowest)
- **What**: Complete user flows
- **Coverage**: Happy paths only
- **Tools**: Playwright, Cypress

---

## Coverage Plan

**Minimum requirements**:
- [ ] 80%+ unit test coverage
- [ ] All API endpoints tested (integration)
- [ ] 1-3 critical E2E flows tested

**Example**:
```
Feature: User Authentication
- Unit: 15 tests (password hashing, token generation)
- Integration: 8 tests (login endpoint, signup endpoint)
- E2E: 2 tests (signup flow, login flow)
```

**See [../reference.md](../reference.md#testing) for complete test plans**
