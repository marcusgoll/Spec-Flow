---
name: gate
description: Run quality gates (CI checks or security scanning)
argument-hint: <type> [args...] where type is: ci | sec
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Task]
---

# /gate — Quality Gates

<context>
**Arguments**: $ARGUMENTS

**Current Branch**: !`git branch --show-current 2>/dev/null || echo "none"`

**Project Detection**:
- Node.js: !`test -f package.json && echo "yes" || echo "no"`
- Python: !`test -f pyproject.toml -o -f requirements.txt && echo "yes" || echo "no"`
- Rust: !`test -f Cargo.toml && echo "yes" || echo "no"`
- Go: !`test -f go.mod && echo "yes" || echo "no"`

**Workflow State**: @.spec-flow/memory/state.yaml
</context>

<objective>
Unified quality gate validation:

| Command | Purpose | Pass Criteria |
|---------|---------|---------------|
| `/gate ci` | CI quality checks | All checks pass |
| `/gate sec` | Security scanning | No CRITICAL/HIGH issues |

Gates block deployment until passed.
</objective>

<process>

## Step 1: Parse Gate Type

Extract first argument as gate type:
- `ci` → Run CI quality checks
- `sec` → Run security scanning

**If no argument provided**, use AskUserQuestion:

```json
{
  "questions": [{
    "question": "Which quality gate do you want to run?",
    "header": "Gate",
    "multiSelect": false,
    "options": [
      {"label": "ci", "description": "Tests, linting, types, coverage (Recommended)"},
      {"label": "sec", "description": "SAST, secrets detection, dependency audit"}
    ]
  }]
}
```

---

## Gate: CI (`/gate ci`)

### Purpose

Validate code quality before deployment:
1. All tests pass
2. Linting checks pass
3. Type checks pass
4. Coverage meets threshold (if configured)

### Step CI-1: Detect Project Type

Use Glob to detect project files:

| File Found | Project Type | Test Command | Lint Command | Type Command |
|------------|--------------|--------------|--------------|--------------|
| `package.json` | Node.js | `npm test` or `pnpm test` | `npm run lint` | `npx tsc --noEmit` |
| `pyproject.toml` | Python | `pytest` | `ruff check .` | `mypy .` |
| `Cargo.toml` | Rust | `cargo test` | `cargo clippy` | `cargo check` |
| `go.mod` | Go | `go test ./...` | `go vet ./...` | (included in vet) |

**If multiple project types detected**, run checks for each.

### Step CI-2: Run Tests

Execute test command for detected project type:

```bash
# Node.js
npm test 2>&1

# Python
pytest 2>&1

# Rust
cargo test 2>&1

# Go
go test ./... 2>&1
```

**Capture**: Exit code and output
**Record**: TESTS_PASSED = (exit code == 0)

### Step CI-3: Run Linters

Execute lint command:

```bash
# Node.js
npm run lint 2>&1

# Python
ruff check . 2>&1

# Rust
cargo clippy -- -D warnings 2>&1

# Go
go vet ./... 2>&1
```

**Capture**: Exit code and output
**Record**: LINTERS_PASSED = (exit code == 0)

### Step CI-4: Run Type Checks

Execute type check command:

```bash
# Node.js (if tsconfig.json exists)
npx tsc --noEmit 2>&1

# Python (if mypy configured)
mypy . 2>&1

# Rust (built into cargo check)
cargo check 2>&1

# Go (included in go vet)
# Already run in linter step
```

**Capture**: Exit code and output
**Record**: TYPE_CHECK_PASSED = (exit code == 0)

### Step CI-5: Check Coverage (If Configured)

**Node.js** — Check `coverage/coverage-summary.json`:
```bash
# Read coverage file if exists
test -f coverage/coverage-summary.json && cat coverage/coverage-summary.json
```

Extract `total.lines.pct` using Read tool and JSON parsing.

**Python** — Check `coverage.xml` or `.coverage`:
```bash
# Generate coverage report if .coverage exists
test -f .coverage && coverage report --format=total
```

**Rust/Go** — Coverage optional, mark as SKIPPED (not PASSED).

**Coverage Evaluation**:
| Coverage | Status |
|----------|--------|
| >= 80% | PASSED |
| < 80% | FAILED |
| Not configured | SKIPPED |

**IMPORTANT**: SKIPPED is NOT the same as PASSED. Display honestly:
- `PASSED (87%)` — Coverage meets threshold
- `FAILED (62%)` — Coverage below threshold
- `SKIPPED` — Coverage not configured for this project type

### Step CI-6: Determine Gate Status

```
GATE_STATUS = "PASSED" if:
  - TESTS_PASSED == true
  - LINTERS_PASSED == true
  - TYPE_CHECK_PASSED == true
  - COVERAGE_STATUS != "FAILED"  (SKIPPED is acceptable)

GATE_STATUS = "FAILED" otherwise
```

### Step CI-7: Record Results

Update `.spec-flow/memory/state.yaml`:

```yaml
quality_gates:
  ci:
    status: passed  # or failed
    timestamp: 2025-12-14T18:00:00Z
    checks:
      tests: passed
      linters: passed
      type_check: passed
      coverage: passed  # or failed or skipped
    coverage_pct: 87  # if available
```

### Step CI-8: Display Results

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CI Quality Gate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project: {Node.js | Python | Rust | Go}

Tests:      {PASSED | FAILED}
Linting:    {PASSED | FAILED}
Type Check: {PASSED | FAILED}
Coverage:   {PASSED (N%) | FAILED (N%) | SKIPPED}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{PASSED: Gate passed. Ready for deployment.}
{FAILED: Gate failed. Fix issues before proceeding.}

{If FAILED, show first error from each failing check}
```

---

## Gate: Security (`/gate sec`)

### Purpose

Ensure no security vulnerabilities before deployment:
1. Static Application Security Testing (SAST)
2. Secrets detection (no hardcoded credentials)
3. Dependency vulnerability scanning

### Step SEC-1: Check Available Tools

Detect which security tools are installed:

```bash
# Check each tool
command -v semgrep >/dev/null 2>&1 && echo "semgrep: available"
command -v git-secrets >/dev/null 2>&1 && echo "git-secrets: available"
command -v npm >/dev/null 2>&1 && echo "npm audit: available"
command -v pip-audit >/dev/null 2>&1 && echo "pip-audit: available"
```

**If no tools available**, provide installation guidance:

```
Security tools not found. Install one or more:

SAST:
  pip install semgrep

Secrets Detection:
  brew install git-secrets  (macOS)
  choco install git-secrets (Windows)

Dependency Scanning:
  npm audit (Node.js - built-in)
  pip install pip-audit (Python)
```

### Step SEC-2: Run SAST (if available)

```bash
# Semgrep with auto config
semgrep --config=auto --json . 2>&1
```

**Parse output**:
- Count findings by severity: ERROR, WARNING, INFO
- Extract file:line references for ERROR findings

**Record**: SAST_PASSED = (ERROR count == 0)

**If semgrep unavailable**: SAST_STATUS = "SKIPPED"

### Step SEC-3: Run Secrets Detection

**Option A: git-secrets (if available)**
```bash
git secrets --scan 2>&1
```

**Option B: Regex fallback**
Use Grep tool to search for common secret patterns:
- `password\s*=\s*['"][^'"]+['"]`
- `api[_-]?key\s*=\s*['"][^'"]+['"]`
- `secret\s*=\s*['"][^'"]+['"]`
- AWS access keys: `AKIA[0-9A-Z]{16}`
- Private keys: `-----BEGIN.*PRIVATE KEY-----`

**Record**: SECRETS_PASSED = (no secrets found)

### Step SEC-4: Run Dependency Scan

**Node.js**:
```bash
npm audit --json 2>&1
```

**Python**:
```bash
pip-audit --format=json 2>&1
# or
safety check --json 2>&1
```

**Parse output**:
- Count vulnerabilities by severity: CRITICAL, HIGH, MODERATE, LOW
- Extract package names and CVE IDs for CRITICAL/HIGH

**Record**: DEPS_PASSED = (CRITICAL + HIGH count == 0)

### Step SEC-5: Determine Gate Status

```
GATE_STATUS = "PASSED" if:
  - SAST_PASSED == true OR SAST_STATUS == "SKIPPED"
  - SECRETS_PASSED == true
  - DEPS_PASSED == true OR DEPS_STATUS == "SKIPPED"

GATE_STATUS = "FAILED" otherwise
```

**Note**: Secrets detection is NEVER skipped. It must pass.

### Step SEC-6: Record Results

Update `.spec-flow/memory/state.yaml`:

```yaml
quality_gates:
  security:
    status: passed  # or failed
    timestamp: 2025-12-14T18:00:00Z
    checks:
      sast: passed  # or failed or skipped
      secrets: passed  # or failed (never skipped)
      dependencies: passed  # or failed or skipped
    findings:
      sast_errors: 0
      secrets_found: 0
      critical_deps: 0
      high_deps: 0
```

### Step SEC-7: Display Results

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Security Quality Gate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project: {Node.js | Python | Rust | Go}

SAST:         {PASSED | FAILED (N errors) | SKIPPED}
Secrets:      {PASSED | FAILED (N found)}
Dependencies: {PASSED | FAILED (N critical, N high) | SKIPPED}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{PASSED: Security gate passed. No blocking issues.}
{FAILED: Security gate failed. Fix issues before deployment.}

{If FAILED, show remediation steps:}
  - SAST: Run `semgrep --config=auto .` for details
  - Secrets: Remove hardcoded credentials, use env vars
  - Deps: Run `npm audit fix` or update vulnerable packages
```

</process>

<anti-hallucination>
## Rules to Prevent Fabricated Results

1. **Run actual commands** — Never claim tests pass without executing them
2. **Report real output** — Quote actual error messages, not invented ones
3. **Verify before recording** — Read state.yaml after update to confirm
4. **Honest about skipped** — SKIPPED means not checked, NOT passed
5. **Show all failures** — If tests AND lint fail, report both
6. **No fake coverage** — Only report coverage from actual reports
</anti-hallucination>

<verification>
Before completing, verify:

1. **Commands actually ran**:
   ```bash
   # Check command history or output
   ```

2. **State was updated**:
   - Read `.spec-flow/memory/state.yaml`
   - Verify gate status matches actual results

3. **All checks reported**:
   - Each check shows PASSED, FAILED, or SKIPPED
   - No check is silently ignored

4. **Failures include details**:
   - File:line references for errors
   - Specific error messages
   - Remediation guidance
</verification>

<examples>

## Example 1: CI Gate Passes

```
> /gate ci

Detecting project type...
Found: Node.js (package.json)

Running tests...
  npm test
  ✓ 47 tests passed

Running linters...
  npm run lint
  ✓ No issues found

Running type check...
  npx tsc --noEmit
  ✓ No type errors

Checking coverage...
  Reading coverage/coverage-summary.json
  ✓ Coverage: 87.3%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CI Quality Gate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project: Node.js

Tests:      PASSED
Linting:    PASSED
Type Check: PASSED
Coverage:   PASSED (87%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ CI gate PASSED. Ready for deployment.
```

## Example 2: CI Gate Fails

```
> /gate ci

Detecting project type...
Found: Python (pyproject.toml)

Running tests...
  pytest
  ✗ 2 tests failed

Running linters...
  ruff check .
  ✓ No issues found

Running type check...
  mypy .
  ✗ 3 type errors found

Checking coverage...
  Coverage not configured (no .coverage file)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CI Quality Gate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project: Python

Tests:      FAILED
Linting:    PASSED
Type Check: FAILED
Coverage:   SKIPPED

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✗ CI gate FAILED. Fix issues before proceeding.

Test failures:
  tests/test_api.py:45: AssertionError
  tests/test_auth.py:23: TypeError

Type errors:
  app/models.py:12: Incompatible return type
  app/routes.py:34: Missing argument
  app/routes.py:56: Missing argument
```

## Example 3: Security Gate

```
> /gate sec

Checking security tools...
  semgrep: available
  git-secrets: not found (using regex fallback)
  npm audit: available

Running SAST...
  semgrep --config=auto --json .
  ✓ 0 errors, 2 warnings, 5 info

Running secrets scan...
  Scanning for common secret patterns...
  ✓ No secrets detected

Running dependency audit...
  npm audit --json
  ✗ 1 critical, 2 high vulnerabilities

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Security Quality Gate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project: Node.js

SAST:         PASSED
Secrets:      PASSED
Dependencies: FAILED (1 critical, 2 high)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✗ Security gate FAILED.

Vulnerable packages:
  lodash@4.17.20 (critical) - CVE-2021-23337
  axios@0.21.0 (high) - CVE-2021-3749
  minimist@1.2.5 (high) - CVE-2021-44906

Fix: npm audit fix --force
```

</examples>

<notes>

## Gate Requirements by Deployment Phase

| Phase | Required Gates |
|-------|---------------|
| Feature development | None (optional) |
| Before PR | `/gate ci` |
| Before merge | `/gate ci` + `/gate sec` |
| Before production | Both gates must be PASSED in state.yaml |

## Tool Installation

**SAST**:
```bash
pip install semgrep
```

**Secrets Detection**:
```bash
# macOS
brew install git-secrets

# Windows
choco install git-secrets

# Linux
git clone https://github.com/awslabs/git-secrets && cd git-secrets && make install
```

**Dependency Scanning**:
```bash
# Node.js (built-in)
npm audit

# Python
pip install pip-audit
# or
pip install safety
```

## Gate Status in State

Gates record their status in `.spec-flow/memory/state.yaml` for workflow continuity:

```yaml
quality_gates:
  ci:
    status: passed
    timestamp: 2025-12-14T18:00:00Z
  security:
    status: passed
    timestamp: 2025-12-14T18:05:00Z
```

</notes>
