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
