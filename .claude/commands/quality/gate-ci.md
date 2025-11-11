# /gate.ci

**Purpose**: CI quality gate - tests, linters, coverage checks.

**Phase**: Review

**Inputs**:
- Epic name (optional) - Track gate per-epic
- Verbose flag (optional) - Show detailed output

**Outputs**:
- Gate pass/fail status
- Updated `workflow-state.yaml` with gate results
- Detailed failure report if failed

## Command Specification

### Synopsis

```bash
/gate.ci [--epic EPIC] [--verbose]
```

### Description

Runs CI quality checks as a blocking gate before epics can transition from Review → Integrated state. Ensures code meets quality standards before deployment.

**Checks**:
1. **Unit & Integration Tests**: All tests must pass
2. **Linters**: Code style compliance (ESLint, Prettier, Black, Flake8)
3. **Type Checks**: TypeScript/Python type safety
4. **Code Coverage**: Minimum 80% line coverage

**Pass Criteria**: ALL checks must pass (no failures allowed)

### Prerequisites

- Code complete and merged to main
- Epic in `Review` state

### Arguments

| Argument    | Required | Description                            |
| ----------- | -------- | -------------------------------------- |
| `--epic`    | No       | Epic name for per-epic tracking        |
| `--verbose` | No       | Show detailed test/lint output         |

### Examples

**Run CI gate for feature**:
```bash
/gate.ci
```

**Output (passing)**:
```
CI Quality Gate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️  Project type: node

✅ Tests passed
✅ Linters passed
✅ Type checks passed
✅ Coverage sufficient (≥80%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ CI gate PASSED

Epic can transition: Review → Integrated
```

**Run CI gate for specific epic**:
```bash
/gate.ci --epic epic-auth-api
```

**Output (failing)**:
```
CI Quality Gate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️  Project type: node

❌ Tests failed
✅ Linters passed
❌ Type checks failed
✅ Coverage sufficient (≥80%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ CI gate FAILED

Fix failures before proceeding:
  • Run tests: npm test (or pytest)
  • Fix type errors: npx tsc --noEmit
```

**Verbose output**:
```bash
/gate.ci --verbose
```

## Supported Project Types

| Type     | Test Runner     | Linters                | Type Checker |
| -------- | --------------- | ---------------------- | ------------ |
| Node.js  | Jest, Vitest    | ESLint, Prettier       | TypeScript   |
| Python   | pytest          | Black, Flake8          | mypy         |
| Rust     | cargo test      | clippy, rustfmt        | rustc        |
| Go       | go test         | golint, gofmt          | go vet       |

**Detection**: Automatic based on project files (package.json, requirements.txt, etc.)

## State Transitions

### Success Path

```
Review → (CI gate passes) → Integrated
```

**Effects**:
1. Gate status recorded as "passed" in `workflow-state.yaml`
2. Epic allowed to transition to `Integrated`
3. Timestamp recorded for DORA metrics

### Failure Path

```
Review → (CI gate fails) → Review (blocked)
```

**Effects**:
1. Gate status recorded as "failed"
2. Epic remains in `Review` state
3. Detailed failure report generated
4. Agent notified to fix issues

## Integration with Epic State Machine

**Called During**: `Review` state entry

**Workflow**:
1. Epic completes all tasks → transitions to `Review`
2. `/gate.ci` runs automatically (or manually)
3. If passed: Epic transitions to `Integrated`
4. If failed: Epic stays in `Review`, agent fixes issues

### Automatic vs Manual

**Automatic (recommended)**:
```bash
# In CI/CD pipeline
.github/workflows/gates.yml triggers /gate.ci on PR merge
```

**Manual**:
```bash
# Developer runs locally before PR
/gate.ci --verbose
```

## Error Conditions

| Error                 | Cause                              | Resolution                  |
| --------------------- | ---------------------------------- | --------------------------- |
| Unknown project type  | No package.json, requirements.txt  | Add project config file     |
| Tests failed          | Unit/integration test failures     | Fix failing tests           |
| Linters failed        | Code style violations              | Run linter auto-fix         |
| Type check failed     | TypeScript/mypy errors             | Fix type annotations        |
| Coverage insufficient | <80% line coverage                 | Add more tests              |

## Quality Standards

### Coverage Requirements

**Minimum**: 80% line coverage

**Measurement**:
- Node.js: Istanbul/NYC (coverage/coverage-summary.json)
- Python: pytest-cov
- Rust: tarpaulin
- Go: go test -cover

**Exclusions** (configurable):
- Test files (*_test.js, test_*.py)
- Generated code (protobuf, GraphQL)
- Configuration files

### Linter Rules

**Node.js**:
- ESLint: Airbnb style guide (or project-specific)
- Prettier: Default formatting rules

**Python**:
- Black: Default formatting (line length 88)
- Flake8: PEP 8 compliance

**Enforcement**: All linter errors must be fixed (warnings allowed)

## Files Modified

- `.spec-flow/memory/workflow-state.yaml` - Gate results recorded

**Gate Status Schema**:
```yaml
quality_gates:
  ci:
    status: passed  # or failed
    timestamp: 2025-11-10T18:00:00Z
    tests: true
    linters: true
    type_check: true
    coverage: true
```

**Epic-Specific Gates**:
```yaml
epics:
  - name: epic-auth-api
    state: Review
    gates:
      ci:
        status: passed
        timestamp: 2025-11-10T18:00:00Z
```

## Performance

**Typical Runtime**:
- Small project (<1000 LOC): 10-30 seconds
- Medium project (1000-10k LOC): 30-90 seconds
- Large project (>10k LOC): 2-5 minutes

**Optimization Tips**:
- Run tests in parallel (Jest --maxWorkers)
- Cache dependencies in CI
- Use incremental builds (TypeScript)

## Best Practices

1. **Run locally first**: Verify gate passes before pushing
2. **Fix quickly**: Don't let gate failures linger >1h
3. **Monitor flaky tests**: Track tests that fail intermittently
4. **Maintain standards**: Don't lower coverage requirements

## Troubleshooting

**Tests pass locally, fail in CI**:
```bash
# Check for environment differences
# - Node/Python version mismatch
# - Missing environment variables
# - Timezone/locale differences
```

**Coverage reporting not working**:
```bash
# Node.js: Regenerate coverage report
npm test -- --coverage

# Python: Install pytest-cov
pip install pytest-cov
pytest --cov=.
```

**Linters too strict**:
```bash
# Customize linter rules
# .eslintrc.js - Disable specific rules
# .flake8 - Adjust max line length
```

## References

- Jest Documentation: https://jestjs.io/
- ESLint Rules: https://eslint.org/docs/rules/
- pytest: https://docs.pytest.org/
- Coverage Standards: https://testing.googleblog.com/2020/08/code-coverage-best-practices.html

---

**Implementation**: `.spec-flow/scripts/bash/gate-ci.sh`
