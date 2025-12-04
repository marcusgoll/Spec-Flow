---
name: gate-ci
description: Run CI quality gate checks (tests, linters, type checks, coverage ≥80%) before epic state transition
argument-hint: [--epic <epic-name>] [--verbose]
allowed-tools: [Bash(npm *), Bash(pnpm *), Bash(npx *), Bash(pytest *), Bash(black *), Bash(flake8 *), Bash(mypy *), Bash(cargo *), Bash(go *), Bash(jq *), Bash(cat *), Bash(grep *), Read, Write, Edit]
---

# /gate-ci — CI Quality Gate

<context>
**Arguments**: $ARGUMENTS

**Current Branch**: !`git branch --show-current 2>$null || echo "none"`

**Git Status**: !`git status --short 2>$null || echo "clean"`

**Project Type Detection**:

- Node.js: !`test -f package.json && echo "node" || echo ""`
- Python: !`test -f requirements.txt && echo "python" || echo ""`
- Rust: !`test -f Cargo.toml && echo "rust" || echo ""`
- Go: !`test -f go.mod && echo "go" || echo ""`

**Workflow State**: @.spec-flow/memory/state.yaml
</context>

<objective>
Run CI quality checks as a blocking gate before epics can transition from Review → Integrated state.

**Checks**:

1. **Unit & Integration Tests**: All tests must pass
2. **Linters**: Code style compliance (ESLint/Prettier, Black/Flake8, clippy, golint)
3. **Type Checks**: TypeScript/Python/Rust/Go type safety
4. **Code Coverage**: Minimum 80% line coverage

**Pass Criteria**: ALL checks must pass (no failures allowed)

**Purpose**: Ensures code meets quality standards before deployment.

**Arguments**:

- `--epic <name>`: Track gate per-epic (optional)
- `--verbose`: Show detailed test/lint output (optional)
  </objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent fabricating gate results.

1. **Never claim tests pass without running them**

   - Always execute actual test commands: `npm test`, `pytest`, `cargo test`, `go test`
   - Report actual exit codes and output
   - Don't say "passed" until verification succeeds

2. **Quote real command output**

   - Show actual test failures, lint errors, type errors
   - Include file:line references from real output
   - Never invent error messages

3. **Verify coverage from actual reports**

   - Read coverage/coverage-summary.json (Node.js)
   - Read coverage.xml or .coverage (Python)
   - Parse actual coverage percentages
   - Don't guess at coverage numbers

4. **Check state.yaml was updated**

   - Read .spec-flow/memory/state.yaml after recording gate
   - Verify gate status matches actual results
   - Confirm timestamp recorded

5. **Report all failures, not just first one**
   - If tests fail AND linters fail, report both
   - Don't stop at first failure
   - Give complete picture of gate status

**Why this matters**: Fabricated gate passes allow broken code to deploy. Accurate reporting prevents production incidents.

---

<process>

### Step 1: Parse Arguments

**Extract epic name and verbose flag from $ARGUMENTS**:

Parse flags:

- If `--epic <name>` present, extract epic name for per-epic tracking
- If `--verbose` present, set verbose mode for detailed output
- Default: Run gate for current branch/project

### Step 2: Detect Project Type

**Auto-detect based on project files**:

```bash
PROJECT_TYPE="unknown"
if [ -f "package.json" ]; then PROJECT_TYPE="node"; fi
if [ -f "requirements.txt" ]; then PROJECT_TYPE="python"; fi
if [ -f "Cargo.toml" ]; then PROJECT_TYPE="rust"; fi
if [ -f "go.mod" ]; then PROJECT_TYPE="go"; fi

if [ "$PROJECT_TYPE" = "unknown" ]; then
  echo "❌ Unknown project type. No package.json, requirements.txt, Cargo.toml, or go.mod found."
  exit 1
fi

echo "ℹ️  Project type: $PROJECT_TYPE"
```

### Step 3: Run Tests

**Execute test suite for project type**:

```bash
TESTS_PASSED=false

case "$PROJECT_TYPE" in
  node)
    npm test && TESTS_PASSED=true
    ;;
  python)
    pytest && TESTS_PASSED=true
    ;;
  rust)
    cargo test && TESTS_PASSED=true
    ;;
  go)
    go test ./... && TESTS_PASSED=true
    ;;
esac

if [ "$TESTS_PASSED" = true ]; then
  echo "✅ Tests passed"
else
  echo "❌ Tests failed"
fi
```

### Step 4: Run Linters

**Execute linters for project type**:

```bash
LINTERS_PASSED=false

case "$PROJECT_TYPE" in
  node)
    npm run lint && LINTERS_PASSED=true
    ;;
  python)
    black --check . && flake8 && LINTERS_PASSED=true
    ;;
  rust)
    cargo clippy -- -D warnings && LINTERS_PASSED=true
    ;;
  go)
    golint ./... && gofmt -l . | wc -l | grep -q '^0$' && LINTERS_PASSED=true
    ;;
esac

if [ "$LINTERS_PASSED" = true ]; then
  echo "✅ Linters passed"
else
  echo "❌ Linters failed"
fi
```

### Step 5: Run Type Checks

**Execute type checkers for project type**:

```bash
TYPE_CHECK_PASSED=false

case "$PROJECT_TYPE" in
  node)
    npx tsc --noEmit && TYPE_CHECK_PASSED=true
    ;;
  python)
    mypy . && TYPE_CHECK_PASSED=true
    ;;
  rust)
    cargo check && TYPE_CHECK_PASSED=true
    ;;
  go)
    go vet ./... && TYPE_CHECK_PASSED=true
    ;;
esac

if [ "$TYPE_CHECK_PASSED" = true ]; then
  echo "✅ Type checks passed"
else
  echo "❌ Type checks failed"
fi
```

### Step 6: Verify Code Coverage

**Check coverage meets ≥80% threshold**:

```bash
COVERAGE_PASSED=false

case "$PROJECT_TYPE" in
  node)
    if [ -f "coverage/coverage-summary.json" ]; then
      COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
      if (( $(echo "$COVERAGE >= 80" | bc -l) )); then
        COVERAGE_PASSED=true
      fi
      echo "Coverage: ${COVERAGE}%"
    else
      echo "⚠️  No coverage report found. Run: npm test -- --coverage"
    fi
    ;;
  python)
    # pytest-cov generates coverage.xml
    if [ -f "coverage.xml" ]; then
      COVERAGE=$(grep -oP 'line-rate="\K[0-9.]+' coverage.xml | head -1)
      COVERAGE_PCT=$(echo "$COVERAGE * 100" | bc)
      if (( $(echo "$COVERAGE_PCT >= 80" | bc -l) )); then
        COVERAGE_PASSED=true
      fi
      echo "Coverage: ${COVERAGE_PCT}%"
    else
      echo "⚠️  No coverage report found. Run: pytest --cov=."
    fi
    ;;
  rust|go)
    # Coverage check optional for Rust/Go
    COVERAGE_PASSED=true
    echo "ℹ️  Coverage check skipped (Rust/Go)"
    ;;
esac

if [ "$COVERAGE_PASSED" = true ]; then
  echo "✅ Coverage sufficient (≥80%)"
else
  echo "❌ Coverage insufficient (<80%)"
fi
```

### Step 7: Determine Gate Status

**Calculate overall pass/fail**:

```bash
GATE_PASSED=false

if [ "$TESTS_PASSED" = true ] && \
   [ "$LINTERS_PASSED" = true ] && \
   [ "$TYPE_CHECK_PASSED" = true ] && \
   [ "$COVERAGE_PASSED" = true ]; then
  GATE_PASSED=true
fi
```

### Step 8: Record Gate Result in state.yaml

**Update workflow state with gate results**:

Use Edit tool to update `.spec-flow/memory/state.yaml`:

```yaml
quality_gates:
  ci:
    status: passed # or failed
    timestamp: 2025-11-20T10:00:00Z
    tests: true
    linters: true
    type_check: true
    coverage: true
```

**If epic-specific** (--epic flag provided):

```yaml
epics:
  - name: <epic-name>
    gates:
      ci:
        status: passed # or failed
        timestamp: 2025-11-20T10:00:00Z
```

### Step 9: Display Gate Summary

**Print gate results**:

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CI Quality Gate"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "ℹ️  Project type: $PROJECT_TYPE"
echo ""

if [ "$TESTS_PASSED" = true ]; then echo "✅ Tests passed"; else echo "❌ Tests failed"; fi
if [ "$LINTERS_PASSED" = true ]; then echo "✅ Linters passed"; else echo "❌ Linters failed"; fi
if [ "$TYPE_CHECK_PASSED" = true ]; then echo "✅ Type checks passed"; else echo "❌ Type checks failed"; fi
if [ "$COVERAGE_PASSED" = true ]; then echo "✅ Coverage sufficient (≥80%)"; else echo "❌ Coverage insufficient (<80%)"; fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$GATE_PASSED" = true ]; then
  echo "✅ CI gate PASSED"
  echo ""
  echo "Epic can transition: Review → Integrated"
else
  echo "❌ CI gate FAILED"
  echo ""
  echo "Fix failures before proceeding:"
  [ "$TESTS_PASSED" = false ] && echo "  • Run tests: npm test (or pytest)"
  [ "$LINTERS_PASSED" = false ] && echo "  • Fix linters: npm run lint --fix"
  [ "$TYPE_CHECK_PASSED" = false ] && echo "  • Fix type errors: npx tsc --noEmit"
  [ "$COVERAGE_PASSED" = false ] && echo "  • Improve coverage: Add more tests"
fi
```

</process>

<success_criteria>
**CI gate successfully completed when:**

1. **All checks executed**: Tests, linters, type checks, coverage all run
2. **Results accurate**: Exit codes and output match actual command results
3. **Gate status recorded**: state.yaml updated with pass/fail and timestamp
4. **Summary displayed**: Clear pass/fail status shown to user
5. **Failures detailed**: If failed, specific failures listed with remediation steps
6. **Epic tracking** (if --epic flag): Gate recorded per-epic in workflow state
   </success_criteria>

<verification>
**Before marking gate complete, verify:**

1. **Check state.yaml updated**:

   ```bash
   cat .spec-flow/memory/state.yaml | grep -A5 "quality_gates"
   ```

   Should show ci gate status and timestamp

2. **Verify test results match reported status**:

   - If tests reported as passing, exit code should be 0
   - If tests reported as failing, should have actual failure output

3. **Confirm coverage calculation**:

   ```bash
   cat coverage/coverage-summary.json | jq '.total.lines.pct'
   ```

   Should match reported coverage percentage

4. **Validate gate decision logic**:
   - If ALL checks passed → gate should be PASSED
   - If ANY check failed → gate should be FAILED

**Never claim gate passed without verifying all checks actually succeeded.**
</verification>

<output>
**Files created/modified by this command:**

**Workflow state**:

- `.spec-flow/memory/state.yaml` - Gate results and timestamp recorded

**Console output**:

- Gate summary (tests, linters, types, coverage status)
- Pass/fail verdict
- Remediation steps if failed
- Epic transition guidance if passed
  </output>

---

## Notes

**Supported Project Types**:

- **Node.js**: Jest/Vitest, ESLint/Prettier, TypeScript
- **Python**: pytest, Black/Flake8, mypy
- **Rust**: cargo test, clippy, rustfmt
- **Go**: go test, golint, gofmt, go vet

**Coverage Requirements**: Minimum 80% line coverage (configurable)

**Gate Blocking**: Epic cannot transition from Review → Integrated until gate passes

**Manual vs Automatic**:

- Automatic: Triggered by CI/CD on PR merge
- Manual: Developer runs locally before PR

**Troubleshooting**:

- Tests pass locally, fail in CI: Check Node/Python version, env vars
- Coverage not working: Regenerate report with `--coverage` flag
- Linters too strict: Customize rules in .eslintrc.js or .flake8
