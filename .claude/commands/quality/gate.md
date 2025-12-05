---
name: gate
description: Run quality gates (CI checks or security scanning)
argument-hint: <type> [args...] where type is: ci | sec
allowed-tools: [Read, Write, Edit, Bash(npm *), Bash(pnpm *), Bash(npx *), Bash(pytest *), Bash(black *), Bash(flake8 *), Bash(mypy *), Bash(cargo *), Bash(go *), Bash(jq *), Bash(cat *), Bash(grep *), Bash(.spec-flow/scripts/bash/gate-sec.sh:*), Bash(semgrep *), Bash(git-secrets *), Bash(git secrets:*), Bash(npm audit:*), Bash(pip-audit *), Bash(safety *), Bash(which:*), Bash(command -v:*), Bash(test:*), Bash(yq:*), AskUserQuestion]
---

# /gate — Consolidated Quality Gates

<context>
**Arguments**: $ARGUMENTS

**Current Branch**: !`git branch --show-current 2>$null || echo "none"`

**Git Status**: !`git status --short 2>$null || echo "clean"`

**Project Type Detection**:

- Node.js: !`test -f package.json && echo "node" || echo ""`
- Python: !`test -f requirements.txt && echo "python" || echo ""`
- Rust: !`test -f Cargo.toml && echo "rust" || echo ""`
- Go: !`test -f go.mod && echo "go" || echo ""`

**Security tools installed**: !`for tool in semgrep git-secrets npm pip-audit safety; do command -v $tool >/dev/null 2>&1 && echo "$tool: yes" || echo "$tool: no"; done`

**Workflow State**: @.spec-flow/memory/state.yaml
</context>

<objective>
Unified entry point for quality gate validation:

- `/gate ci` → Run CI quality checks (tests, linters, type checks, coverage ≥80%)
- `/gate sec` → Run security gate (SAST, secrets detection, dependency scanning)

These gates ensure code quality and security before deployment.
</objective>

<process>

## Step 1: Parse Type Argument

**Extract first argument as type:**

```
$type = first word of $ARGUMENTS
$remaining = rest of $ARGUMENTS
```

**If no type provided:**
Use AskUserQuestion to ask:
```json
{
  "question": "Which quality gate do you want to run?",
  "header": "Gate Type",
  "multiSelect": false,
  "options": [
    {
      "label": "ci",
      "description": "CI checks (tests, linters, types, coverage ≥80%)"
    },
    {
      "label": "sec",
      "description": "Security (SAST, secrets, dependencies)"
    }
  ]
}
```

## Step 2: Execute Gate Based on Type

<when_argument_is value="ci">

### CI Quality Gate

**Purpose**: Run CI quality checks as a blocking gate before epics can transition from Review → Integrated state.

**Checks**:
1. **Unit & Integration Tests**: All tests must pass
2. **Linters**: Code style compliance (ESLint/Prettier, Black/Flake8, clippy, golint)
3. **Type Checks**: TypeScript/Python/Rust/Go type safety
4. **Code Coverage**: Minimum 80% line coverage

**Pass Criteria**: ALL checks must pass (no failures allowed)

### Anti-Hallucination Rules

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

### Implementation Steps

1. **Parse Arguments**:
   - Extract `--epic <name>` if present for per-epic tracking
   - Extract `--verbose` flag for detailed output

2. **Detect Project Type**:
   ```bash
   PROJECT_TYPE="unknown"
   if [ -f "package.json" ]; then PROJECT_TYPE="node"; fi
   if [ -f "requirements.txt" ]; then PROJECT_TYPE="python"; fi
   if [ -f "Cargo.toml" ]; then PROJECT_TYPE="rust"; fi
   if [ -f "go.mod" ]; then PROJECT_TYPE="go"; fi

   if [ "$PROJECT_TYPE" = "unknown" ]; then
     echo "❌ Unknown project type"
     exit 1
   fi
   ```

3. **Run Tests**:
   ```bash
   TESTS_PASSED=false
   case "$PROJECT_TYPE" in
     node) npm test && TESTS_PASSED=true ;;
     python) pytest && TESTS_PASSED=true ;;
     rust) cargo test && TESTS_PASSED=true ;;
     go) go test ./... && TESTS_PASSED=true ;;
   esac
   ```

4. **Run Linters**:
   ```bash
   LINTERS_PASSED=false
   case "$PROJECT_TYPE" in
     node) npm run lint && LINTERS_PASSED=true ;;
     python) black --check . && flake8 && LINTERS_PASSED=true ;;
     rust) cargo clippy -- -D warnings && LINTERS_PASSED=true ;;
     go) golint ./... && LINTERS_PASSED=true ;;
   esac
   ```

5. **Run Type Checks**:
   ```bash
   TYPE_CHECK_PASSED=false
   case "$PROJECT_TYPE" in
     node) npx tsc --noEmit && TYPE_CHECK_PASSED=true ;;
     python) mypy . && TYPE_CHECK_PASSED=true ;;
     rust) cargo check && TYPE_CHECK_PASSED=true ;;
     go) go vet ./... && TYPE_CHECK_PASSED=true ;;
   esac
   ```

6. **Verify Code Coverage**:
   ```bash
   COVERAGE_PASSED=false
   case "$PROJECT_TYPE" in
     node)
       if [ -f "coverage/coverage-summary.json" ]; then
         COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
         if (( $(echo "$COVERAGE >= 80" | bc -l) )); then
           COVERAGE_PASSED=true
         fi
       fi
       ;;
     python)
       if [ -f "coverage.xml" ]; then
         COVERAGE=$(grep -oP 'line-rate="\K[0-9.]+' coverage.xml | head -1)
         COVERAGE_PCT=$(echo "$COVERAGE * 100" | bc)
         if (( $(echo "$COVERAGE_PCT >= 80" | bc -l) )); then
           COVERAGE_PASSED=true
         fi
       fi
       ;;
     rust|go)
       COVERAGE_PASSED=true  # Coverage check optional for Rust/Go
       ;;
   esac
   ```

7. **Determine Gate Status**:
   ```bash
   GATE_PASSED=false
   if [ "$TESTS_PASSED" = true ] && \
      [ "$LINTERS_PASSED" = true ] && \
      [ "$TYPE_CHECK_PASSED" = true ] && \
      [ "$COVERAGE_PASSED" = true ]; then
     GATE_PASSED=true
   fi
   ```

8. **Record Gate Result in state.yaml**:

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

9. **Display Gate Summary**:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   CI Quality Gate
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ℹ️  Project type: {node|python|rust|go}

   ✅ Tests passed (or ❌ Tests failed)
   ✅ Linters passed (or ❌ Linters failed)
   ✅ Type checks passed (or ❌ Type checks failed)
   ✅ Coverage sufficient (≥80%) (or ❌ Coverage insufficient)

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ✅ CI gate PASSED (or ❌ CI gate FAILED)

   {Next steps based on pass/fail}
   ```

</when_argument_is>

<when_argument_is value="sec">

### Security Quality Gate

**Purpose**: Run security quality gate to ensure no HIGH/CRITICAL security issues before deployment.

**Checks performed:**
1. **SAST** - Static Application Security Testing (Semgrep)
2. **Secrets Detection** - No hardcoded credentials (git-secrets or regex fallback)
3. **Dependency Scan** - No HIGH/CRITICAL vulnerabilities (npm audit, pip-audit, safety)

**Pass criteria:**
- SAST: Zero ERROR-level findings
- Secrets: Zero secrets detected
- Dependencies: Zero CRITICAL/HIGH vulnerabilities

### Implementation Steps

1. **Execute security gate script**:
   ```bash
   bash .spec-flow/scripts/bash/gate-sec.sh
   ```

   The gate-sec.sh script performs:
   - Detect project type (Node.js, Python, Rust, Go)
   - Check tool availability (Semgrep, git-secrets, npm audit, pip-audit)
   - Run SAST with `semgrep --config=auto --json .`
   - Run secrets detection (git-secrets or regex fallback)
   - Run dependency scan (npm audit, pip-audit, or safety check)
   - Aggregate results and count ERROR/CRITICAL/HIGH findings
   - Determine pass/fail (PASS: 0 ERROR, 0 secrets, 0 CRITICAL/HIGH deps)
   - Update state.yaml with gate results
   - Display formatted output with pass/fail status and remediation

2. **Read gate results**:
   - Load updated `.spec-flow/memory/state.yaml`
   - Extract `quality_gates.security.status` (passed or failed)
   - Extract `quality_gates.security.findings` (counts by severity)

3. **Present results to user**:

   **If PASSED:**
   ```
   Security Quality Gate
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ℹ️  Project type: {node|python|rust|go}

   ✅ SAST passed (no HIGH/CRITICAL issues)
   ✅ No secrets detected
   ✅ Dependencies secure

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ✅ Security gate PASSED

   Epic can transition: Review → Integrated
   ```

   **If FAILED:**
   ```
   Security Quality Gate
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ℹ️  Project type: {node|python|rust|go}

   ❌ SAST failed ({N} ERROR findings)
   ✅ No secrets detected
   ❌ Vulnerable dependencies found ({N} HIGH, {N} CRITICAL)

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ❌ Security gate FAILED

   Fix security issues before proceeding:
     • Review SAST findings: semgrep --config=auto .
     • Update vulnerable dependencies: npm audit fix

   Installation (if tools missing):
     • Semgrep: pip install semgrep
     • git-secrets: brew install git-secrets (macOS)
     • pip-audit: pip install pip-audit (Python)
   ```

4. **Suggest next action** based on gate status:
   - **If PASSED**: Epic can proceed to Integrated state
   - **If FAILED**: Epic remains in Review state, developer must fix issues and re-run gate

</when_argument_is>

</process>

<verification>
Before completing, verify:
- Gate type correctly identified (ci or sec)
- Appropriate checks executed for project type
- state.yaml updated with gate results
- Gate status matches actual check results
- User presented with clear pass/fail status
- Remediation instructions provided if failed
</verification>

<success_criteria>
**CI gate:**
- All checks executed (tests, linters, type checks, coverage)
- Results accurate from actual command output
- Gate status recorded in state.yaml
- Summary displayed with remediation steps if failed

**Security gate:**
- All security checks completed (SAST, secrets, dependencies)
- Results aggregated correctly
- Gate status recorded in state.yaml
- Remediation instructions provided for failed checks

**Both gates:**
- Pass/fail determination matches criteria
- Epic transition enabled/blocked appropriately
- Results persist in workflow state
</success_criteria>

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/gate ci` | Run CI quality checks |
| `/gate ci --epic <name>` | CI gate for epic |
| `/gate ci --verbose` | CI gate with detailed output |
| `/gate sec` | Run security scanning |

## What Each Gate Checks

**CI Gate (`/gate ci`):**
- Unit/integration tests pass
- Linter checks pass
- Type checks pass
- Coverage ≥80%

**Security Gate (`/gate sec`):**
- No HIGH/CRITICAL SAST findings
- No secrets in code
- No vulnerable dependencies

**Supported Project Types:**
- **Node.js**: Jest/Vitest, ESLint/Prettier, TypeScript
- **Python**: pytest, Black/Flake8, mypy
- **Rust**: cargo test, clippy, rustfmt
- **Go**: go test, golint, gofmt, go vet

**Gate Blocking**: Epic cannot transition from Review → Integrated until both gates pass.
