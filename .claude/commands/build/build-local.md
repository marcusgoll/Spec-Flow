---
name: build-local
description: Build and validate locally for projects without remote deployment (prototypes, experiments, local-only dev)
internal: true
argument-hint: (automatically called by /ship)
allowed-tools: [Bash(python .spec-flow/*), Bash(git *), Bash(npm *), Bash(pnpm *), Bash(yarn *), Bash(make *), Bash(cargo *), Bash(go *), Read, Write, Grep]
---

> **⚠️ INTERNAL COMMAND**: This command is automatically called by `/ship` when deployment model is `local-only`.
> Most users should use `/ship` instead of calling this directly.

# /build-local — Local Build & Validation

<context>
**Current Feature Directory**: !`find specs/ -maxdepth 1 -type d -name "[0-9]*" | sort -n | tail -1 2>$null || echo "none"`

**Workflow State**: @specs/*/workflow-state.yaml

**Git Status**: !`git status --short 2>$null || echo "clean"`

**Git Remote**: !`git remote get-url origin 2>$null || echo "no-remote"`

**Previous Phases**:
- Pre-flight: !`yq eval '.quality_gates.pre_flight.passed' specs/*/workflow-state.yaml 2>$null || echo "unknown"`
- Optimize: !`yq eval '.phases.optimize.status' specs/*/workflow-state.yaml 2>$null || echo "unknown"`
- Preview: !`yq eval '.workflow.manual_gates.preview.status' specs/*/workflow-state.yaml 2>$null || echo "unknown"`

**Project Type Detection**:
- Node.js: !`test -f package.json && echo "yes" || echo "no"`
- Makefile: !`test -f Makefile && echo "yes" || echo "no"`
- Rust: !`test -f Cargo.toml && echo "yes" || echo "no"`
- Go: !`test -f go.mod && echo "yes" || echo "no"`
- Python: !`test -f setup.py && echo "yes" || test -f pyproject.toml && echo "yes" || echo "no"`

**Package Manager**: !`command -v pnpm >/dev/null 2>&1 && echo "pnpm" || (command -v yarn >/dev/null 2>&1 && echo "yarn" || (command -v npm >/dev/null 2>&1 && echo "npm" || echo "unknown"))`

**Build Tools Available**: !`command -v make >/dev/null 2>&1 && echo "make" || echo "none"`
</context>

<objective>
Build and validate the project locally for projects without remote deployment (local-only deployment model).

**Purpose**: For projects without git remote or deployment infrastructure (prototypes, experiments, desktop apps, learning projects).

**Risk Level**: 🟢 LOW - No production deployment, all operations local

**When Used**: Automatically called by `/ship` when:
- No git remote configured
- Deployment model detected as `local-only`
- Project is development/learning focused (not production-bound)

**Build Phases** (executed in order):
1. **Initialize**: Verify prerequisites, load workflow state
2. **Production Build**: Run build commands based on project type
3. **Run Tests**: Execute test suite (if available)
4. **Analyze Build Artifacts**: Check bundle sizes, dependencies
5. **Security Scan** (optional): Run security audit, generate SBOM
6. **Local Build Report**: Generate comprehensive build summary

**Prerequisites** (verified before execution):
- `/implement` phase complete
- `/optimize` phase complete
- `/preview` manual gate approved
- Pre-flight validation passed

**Timing**: 2-5 minutes (depends on project size and test suite)
</objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent false build success claims.

1. **Never claim build succeeded without actual exit code 0**
   - Check actual bash exit code from build commands
   - Exit code 0 = build succeeded
   - Exit code != 0 = build failed
   - Don't claim success if build was interrupted or errored

2. **Quote actual build errors from command output**
   - Report actual compiler errors, test failures, lint violations
   - Include file:line references from actual output
   - Don't invent or summarize errors - quote them exactly

3. **Verify build artifacts actually exist**
   - Check for actual build output (dist/, build/, target/, bin/)
   - Don't assume artifacts exist without verification
   - Report "Build artifacts not found" if missing

4. **Quote actual test results from test output**
   - Report actual test counts (passed/failed/skipped)
   - Include test names that failed
   - Don't claim "all tests passed" without actual test runner output

5. **Read actual build report content**
   - Read generated local-build-report.md file
   - Quote actual metrics (bundle size, dependency count, test coverage)
   - Don't fabricate report content

**Why this matters**: False build success claims waste time debugging later. Accurate reporting of actual build status prevents confusion and ensures code quality.

---

<process>

### Step 1: Verify Prerequisites

**Check workflow state exists**:
```bash
FEATURE_DIR=$(find specs/ -maxdepth 1 -type d -name "[0-9]*" | sort -n | tail -1)
test -f "$FEATURE_DIR/workflow-state.yaml"
```

If workflow state doesn't exist:
```
❌ No workflow state found

Expected: specs/{feature-slug}/workflow-state.yaml

Cannot proceed with build without workflow state.
Run /feature to create feature context first.
```
EXIT immediately

**Verify prerequisite phases completed**:

```bash
# Check pre-flight validation
yq eval '.quality_gates.pre_flight.passed == true' "$FEATURE_DIR/workflow-state.yaml"
```
If not passed: Display "❌ Pre-flight validation not passed" and EXIT

```bash
# Check optimize phase
yq eval '.phases.optimize.status == "completed"' "$FEATURE_DIR/workflow-state.yaml"
```
If not completed: Display "❌ Optimization phase not complete" and EXIT

```bash
# Check preview gate
yq eval '.workflow.manual_gates.preview.status' "$FEATURE_DIR/workflow-state.yaml"
```
If not "approved": Display "❌ Preview gate not approved" and EXIT

If all checks pass:
```
✅ All pre-build checks passed
```

### Step 2: Execute Local Build

**Update workflow phase to in_progress**:
```bash
yq eval -i '.phases.ship:build-local.status = "in_progress"' "$FEATURE_DIR/workflow-state.yaml"
yq eval -i '.phases.ship:build-local.started_at = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' "$FEATURE_DIR/workflow-state.yaml"
```

**Display build banner**:
```
🏠 Local Build & Validation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {feature-slug}
Build Type: Local (no deployment)

Starting build phases...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Detect project type and run appropriate build commands**:

**For Node.js projects** (package.json exists):
```bash
# Detect package manager
if command -v pnpm >/dev/null 2>&1; then
  PKG_MGR="pnpm"
elif command -v yarn >/dev/null 2>&1; then
  PKG_MGR="yarn"
else
  PKG_MGR="npm"
fi

echo "Phase BL.2: Production Build"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Run build
$PKG_MGR run build

if [ $? -eq 0 ]; then
  echo "✅ Build passed"
else
  echo "❌ Build failed"
  exit 1
fi
```

**For Makefile projects**:
```bash
echo "Phase BL.2: Production Build"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

make build || make all

if [ $? -eq 0 ]; then
  echo "✅ Build passed"
else
  echo "❌ Build failed"
  exit 1
fi
```

**For Rust projects** (Cargo.toml exists):
```bash
echo "Phase BL.2: Production Build"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cargo build --release

if [ $? -eq 0 ]; then
  echo "✅ Build passed"
else
  echo "❌ Build failed"
  exit 1
fi
```

**For Go projects** (go.mod exists):
```bash
echo "Phase BL.2: Production Build"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

go build ./...

if [ $? -eq 0 ]; then
  echo "✅ Build passed"
else
  echo "❌ Build failed"
  exit 1
fi
```

**For Python projects** (setup.py or pyproject.toml exists):
```bash
echo "Phase BL.2: Production Build"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Python typically doesn't have a "build" step for local dev
# Run syntax check instead
python -m py_compile **/*.py

if [ $? -eq 0 ]; then
  echo "✅ Syntax check passed"
else
  echo "❌ Syntax errors found"
  exit 1
fi
```

### Step 3: Run Tests (If Available)

**For Node.js projects**:
```bash
echo ""
echo "Phase BL.3: Run Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if test script exists
if grep -q '"test"' package.json; then
  $PKG_MGR test

  if [ $? -eq 0 ]; then
    echo "✅ Tests passed"
  else
    echo "❌ Tests failed"
    exit 1
  fi
else
  echo "⏭️  No test script found (skipped)"
fi
```

**For other project types**: Similar pattern - check for test command, run if available, skip if not

### Step 4: Analyze Build Artifacts

**Check build output exists**:

```bash
echo ""
echo "Phase BL.4: Analyze Build Artifacts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Node.js
if [ -d "dist" ] || [ -d "build" ] || [ -d ".next" ]; then
  BUILD_SIZE=$(du -sh dist build .next 2>/dev/null | awk '{print $1}' | head -1)
  echo "Build output: $BUILD_SIZE"
  echo "✅ Build artifacts found"
fi

# Rust
if [ -d "target/release" ]; then
  BUILD_SIZE=$(du -sh target/release 2>/dev/null | awk '{print $1}')
  echo "Build output: $BUILD_SIZE"
  echo "✅ Build artifacts found"
fi

# Go
if [ -d "bin" ]; then
  BUILD_SIZE=$(du -sh bin 2>/dev/null | awk '{print $1}')
  echo "Build output: $BUILD_SIZE"
  echo "✅ Build artifacts found"
fi
```

### Step 5: Security Scan (Optional, Non-Blocking)

**Run if available**:

```bash
echo ""
echo "Phase BL.5: Security Scan (Optional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Node.js - npm audit
if command -v npm >/dev/null 2>&1 && [ -f "package.json" ]; then
  npm audit --json > "$FEATURE_DIR/npm-audit.json" 2>/dev/null || true

  VULNERABILITIES=$(jq '.metadata.vulnerabilities.total' "$FEATURE_DIR/npm-audit.json" 2>/dev/null || echo "0")

  if [ "$VULNERABILITIES" -gt 0 ]; then
    echo "⚠️  $VULNERABILITIES vulnerabilities found (non-blocking)"
  else
    echo "✅ No vulnerabilities detected"
  fi
else
  echo "⏭️  Security scan skipped (no npm available)"
fi
```

### Step 6: Generate Local Build Report

**Create build report**:

```bash
echo ""
echo "Phase BL.6: Local Build Report"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Use spec-cli to generate report (or create manually)
python .spec-flow/scripts/spec-cli.py generate-build-report \
  --feature-dir "$FEATURE_DIR" \
  --build-type "local" \
  --project-type "$PROJECT_TYPE" \
  --build-size "$BUILD_SIZE" \
  --test-results "$TEST_RESULTS"

echo "✅ Build report generated: $FEATURE_DIR/local-build-report.md"
```

**Update workflow state to completed**:
```bash
yq eval -i '.phases.ship:build-local.status = "completed"' "$FEATURE_DIR/workflow-state.yaml"
yq eval -i '.phases.ship:build-local.completed_at = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' "$FEATURE_DIR/workflow-state.yaml"
```

### Step 7: Display Build Summary

**Read build report and display summary**:

```bash
Read("$FEATURE_DIR/local-build-report.md")
```

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ LOCAL BUILD COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {feature-slug}
Project Type: {project-type}

Build Results:
  ✅ Production build passed
  ✅ Tests passed ({test-count} tests)
  ✅ Build artifacts: {build-size}
  {If security scan ran} ⚠️  Vulnerabilities: {count}

Build Report: specs/{feature-slug}/local-build-report.md

Next Steps:
1. Review build artifacts in dist/ or build/
2. Test the built application locally
3. Commit changes: git add . && git commit
4. Workflow complete (no remote deployment for local-only projects)

Total build time: {duration}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

</process>

<success_criteria>
**Local build successfully completed when:**

1. **Prerequisites verified**:
   - Workflow state file exists
   - Pre-flight validation passed
   - Optimize phase completed
   - Preview gate approved

2. **Build executed successfully**:
   - Build command ran without errors (exit code 0)
   - Build artifacts generated (dist/, build/, target/, bin/ exists)
   - No compilation errors, type errors, or build failures

3. **Tests passed** (if available):
   - Test suite executed
   - All tests passed (or test suite skipped if no tests)
   - Test results recorded in build report

4. **Build artifacts analyzed**:
   - Build output size calculated
   - Build artifacts verified to exist
   - Artifact analysis included in build report

5. **Security scan completed** (if available):
   - npm audit or equivalent ran (non-blocking)
   - Vulnerability count recorded
   - Results included in build report

6. **Build report generated**:
   - local-build-report.md created at specs/{feature-slug}/
   - Report contains actual build metrics (not placeholders)
   - Report includes pass/fail status for each phase

7. **Workflow state updated**:
   - Phase marked as "completed" in workflow-state.yaml
   - Start and completion timestamps recorded
   - Build type ("local") recorded

8. **User informed**:
   - Build summary displayed
   - Build artifacts location shown
   - Next steps provided
   - Total build time shown
</success_criteria>

<verification>
**Before marking build-local complete, verify:**

1. **Check build command exit code**:
   - Actual bash exit code from build commands
   - 0 = success, != 0 = failure
   - Don't claim success without verifying exit code

2. **Verify build artifacts exist**:
   ```bash
   # Node.js
   ls -la dist/ || ls -la build/ || ls -la .next/
   # Should show actual files

   # Rust
   ls -la target/release/
   # Should show compiled binaries

   # Go
   ls -la bin/
   # Should show compiled binaries
   ```

3. **Verify test results from actual output** (if tests ran):
   ```bash
   # Count passed tests from test runner output
   grep -E "passed|✓" test-output.log | wc -l
   # Should match reported test count
   ```

4. **Check build report exists and has content**:
   ```bash
   test -f "$FEATURE_DIR/local-build-report.md"
   # Should exist

   wc -l "$FEATURE_DIR/local-build-report.md"
   # Should have >10 lines (not empty)
   ```

5. **Verify workflow state updated**:
   ```bash
   yq eval '.phases.ship:build-local.status' "$FEATURE_DIR/workflow-state.yaml"
   # Should show: completed

   yq eval '.phases.ship:build-local.completed_at' "$FEATURE_DIR/workflow-state.yaml"
   # Should show actual timestamp
   ```

6. **Check no fabricated data**:
   - Build size from actual `du` command (not guessed)
   - Test count from actual test runner output (not assumed)
   - Vulnerability count from actual npm audit (not invented)
   - All metrics in build report from actual tool output

**Never claim build complete without:**
- Actual build command exit code 0
- Actual build artifacts existing on filesystem
- Actual build report file with real metrics
- Actual workflow state update confirming completed status
</verification>

<output>
**Files created/modified by this command:**

**Build artifacts** (project-specific):
- Node.js: `dist/` or `build/` or `.next/` - Compiled JavaScript/TypeScript
- Rust: `target/release/` - Compiled Rust binaries
- Go: `bin/` - Compiled Go binaries
- Python: `__pycache__/`, `*.pyc` - Compiled Python bytecode

**Build report**:
- `specs/{feature-slug}/local-build-report.md` - Comprehensive build summary with:
  - Build phase results (passed/failed for each phase)
  - Project type and build tool used
  - Build artifact size and location
  - Test results (passed/failed/skipped counts)
  - Security scan results (vulnerability count)
  - Build timing (start/end timestamps, duration)
  - Next steps recommendations

**Security artifacts** (if security scan ran):
- `specs/{feature-slug}/npm-audit.json` - npm audit results (Node.js projects)

**Workflow state**:
- `specs/{feature-slug}/workflow-state.yaml` - Updated with:
  - `phases.ship:build-local.status = "completed"` (or "failed")
  - `phases.ship:build-local.started_at` - ISO 8601 timestamp
  - `phases.ship:build-local.completed_at` - ISO 8601 timestamp
  - `phases.ship:build-local.build_type = "local"`

**Console output**:
- Build phase headers and progress
- Build command output (compiler messages, warnings, errors)
- Test results (passed/failed counts, test names)
- Build artifact analysis (sizes, locations)
- Security scan results (vulnerability counts)
- Build summary with next steps
- Total build time
</output>

---

## Notes

**Local-Only Projects**: This command is for projects without remote deployment:
- Prototypes and experiments
- Learning projects and tutorials
- Desktop applications (Electron, Tauri, etc.)
- Internal tools without hosted infrastructure
- Development/testing environments

**No Deployment**: Build artifacts remain local, no push to remote servers or hosting platforms.

**Quality Gates Still Apply**:
- Pre-flight validation required (ensures code quality)
- Optimize phase required (code review, performance, accessibility)
- Preview gate required (manual testing before finalizing)

**Multi-Language Support**:
- **Node.js**: npm/yarn/pnpm build, supports Next.js, Vite, Create React App, etc.
- **Rust**: cargo build --release
- **Go**: go build ./...
- **Python**: Syntax checking (no traditional "build" step)
- **Makefile**: make build or make all
- **Custom**: Can extend for other languages/frameworks

**Security Scanning**:
- Node.js: npm audit (checks dependencies for known vulnerabilities)
- Rust: cargo audit (if installed)
- Go: govulncheck (if installed)
- Non-blocking: Warnings displayed but build proceeds

**Build Artifact Analysis**:
- Calculates total size of build output
- Lists generated files
- Checks for common issues (missing sourcemaps, large bundles)

**Common Build Failures**:
1. **TypeScript errors**: Missing types, type mismatches
2. **Missing dependencies**: npm install not run, lockfile out of date
3. **Environment variables**: Required vars not set (even for local builds)
4. **Out of memory**: Large projects may need `NODE_OPTIONS=--max-old-space-size=4096`
5. **Syntax errors**: Compilation failures in source code

**Troubleshooting**:
- Check build logs in terminal output
- Verify dependencies installed: `pnpm install` or `npm install`
- Check for TypeScript errors: `pnpm tsc --noEmit`
- Verify build script exists in package.json: `grep '"build"' package.json`
- For Rust: Check `Cargo.lock` is up to date: `cargo update`
- For Go: Verify Go version: `go version` (check go.mod for minimum version)

**Manual Build** (if command fails):
```bash
# Node.js
pnpm run build

# Rust
cargo build --release

# Go
go build ./...

# Makefile
make build
```

**Next Steps After Build**:
1. Test built application locally
2. Review build artifacts for size/content
3. Address any security vulnerabilities (if found)
4. Commit changes to git
5. Workflow complete (no further deployment for local-only projects)
