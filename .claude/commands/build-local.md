---
description: Local build and validation without deployment
internal: true
---

> **⚠️  INTERNAL COMMAND**: This command is called automatically by `/ship` when deployment model is `local-only`.
> Most users should use `/ship` instead of calling this directly.

# /build-local - Local Build & Validation

**Purpose**: Build and validate locally for projects without remote deployment. This command is called by `/ship` when deployment model is `local-only`.

**When to Use**:
- Projects without git remote
- Local development only
- Prototypes and experiments
- Desktop applications
- Learning projects

**Risk Level**: 🟢 LOW - no production deployment

**Prerequisites**:
- `/implement` phase complete
- `/optimize` phase complete
- `/preview` manual gate approved
- Pre-flight validation passed

---

## Phase BL.1: Initialize Local Build

**Purpose**: Prepare for local build and validation

```bash
#!/bin/bash
set -e

# Source state management functions
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../../.spec-flow/scripts/bash/workflow-state.sh"
else
  source .spec-flow/scripts/bash/workflow-state.sh
fi

# Find feature directory
FEATURE_DIR=$(ls -td specs/*/ | head -1)
STATE_FILE="$FEATURE_DIR/workflow-state.yaml"

# Auto-migrate from JSON if needed
if [ ! -f "$STATE_FILE" ] && [ -f "$FEATURE_DIR/workflow-state.json" ]; then
  yq eval -P "$FEATURE_DIR/workflow-state.json" > "$STATE_FILE"
fi

if [ ! -f "$STATE_FILE" ]; then
  echo "❌ No workflow state found"
  exit 1
fi

# Update phase
update_workflow_phase "$FEATURE_DIR" "ship:build-local" "in_progress"

echo "🏠 Local Build & Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 Building locally (no remote deployment)"
echo ""

# Verify prerequisites
echo "📋 Pre-Build Checklist"
echo "─────────────────────────────────────────────"

CHECKS_PASSED=true

# Check 1: Pre-flight validation completed
if ! yq eval '.quality_gates.pre_flight.passed == true' "$STATE_FILE" > /dev/null 2>&1; then
  echo "❌ Pre-flight validation not completed or failed"
  CHECKS_PASSED=false
else
  echo "✅ Pre-flight validation passed"
fi

# Check 2: Optimize phase completed
if ! test_phase_completed "$FEATURE_DIR" "ship:optimize"; then
  echo "❌ Optimization phase not completed"
  CHECKS_PASSED=false
else
  echo "✅ Optimization complete"
fi

# Check 3: Preview approved
PREVIEW_STATUS=$(yq eval '.workflow.manual_gates.preview.status // "pending"' "$STATE_FILE")
if [ "$PREVIEW_STATUS" != "approved" ]; then
  echo "❌ Preview gate not approved"
  CHECKS_PASSED=false
else
  echo "✅ Preview approved"
fi

echo ""

if [ "$CHECKS_PASSED" = false ]; then
  echo "❌ Pre-build checks failed"
  update_workflow_phase "$FEATURE_DIR" "ship:build-local" "failed"
  exit 1
fi

echo "✅ All pre-build checks passed"
echo ""
```

**Blocking Conditions**:
- Pre-flight validation failed
- Optimization not complete
- Preview not approved

---

## Phase BL.2: Run Production Build

**Purpose**: Execute production build locally

```bash
echo "🔨 Phase BL.2: Production Build"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detect package manager
PKG_MANAGER=""
if [ -f "package-lock.json" ]; then
  PKG_MANAGER="npm"
elif [ -f "yarn.lock" ]; then
  PKG_MANAGER="yarn"
elif [ -f "pnpm-lock.yaml" ]; then
  PKG_MANAGER="pnpm"
elif [ -f "Makefile" ]; then
  PKG_MANAGER="make"
elif [ -f "Cargo.toml" ]; then
  PKG_MANAGER="cargo"
elif [ -f "go.mod" ]; then
  PKG_MANAGER="go"
elif [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
  PKG_MANAGER="python"
else
  echo "❌ No build system detected"
  echo "   Supported: npm, yarn, pnpm, make, cargo, go, python"
  exit 1
fi

echo "Build system: $PKG_MANAGER"
echo ""

# Clean previous build
echo "🧹 Cleaning previous build..."

case "$PKG_MANAGER" in
  npm|yarn|pnpm)
    if [ -d "dist" ]; then rm -rf dist; fi
    if [ -d "build" ]; then rm -rf build; fi
    if [ -d ".next" ]; then rm -rf .next; fi
    if [ -d "out" ]; then rm -rf out; fi
    ;;
  make)
    make clean 2>/dev/null || echo "No clean target"
    ;;
  cargo)
    cargo clean
    ;;
  go)
    go clean
    ;;
  python)
    if [ -d "dist" ]; then rm -rf dist; fi
    if [ -d "build" ]; then rm -rf build; fi
    ;;
esac

echo "✅ Clean complete"
echo ""

# Run build
echo "🔨 Running production build..."
echo ""

BUILD_START=$(date +%s)

case "$PKG_MANAGER" in
  npm)
    npm run build 2>&1 | tee "$FEATURE_DIR/build-local.log"
    BUILD_EXIT=${PIPESTATUS[0]}
    ;;
  yarn)
    yarn build 2>&1 | tee "$FEATURE_DIR/build-local.log"
    BUILD_EXIT=${PIPESTATUS[0]}
    ;;
  pnpm)
    pnpm build 2>&1 | tee "$FEATURE_DIR/build-local.log"
    BUILD_EXIT=${PIPESTATUS[0]}
    ;;
  make)
    make 2>&1 | tee "$FEATURE_DIR/build-local.log"
    BUILD_EXIT=${PIPESTATUS[0]}
    ;;
  cargo)
    cargo build --release 2>&1 | tee "$FEATURE_DIR/build-local.log"
    BUILD_EXIT=${PIPESTATUS[0]}
    ;;
  go)
    go build -o ./dist/ ./... 2>&1 | tee "$FEATURE_DIR/build-local.log"
    BUILD_EXIT=${PIPESTATUS[0]}
    ;;
  python)
    if [ -f "setup.py" ]; then
      python setup.py build 2>&1 | tee "$FEATURE_DIR/build-local.log"
      BUILD_EXIT=${PIPESTATUS[0]}
    elif [ -f "pyproject.toml" ]; then
      pip install build 2>/dev/null || true
      python -m build 2>&1 | tee "$FEATURE_DIR/build-local.log"
      BUILD_EXIT=${PIPESTATUS[0]}
    fi
    ;;
esac

BUILD_END=$(date +%s)
BUILD_DURATION=$((BUILD_END - BUILD_START))

echo ""

if [ $BUILD_EXIT -ne 0 ]; then
  echo "❌ Build FAILED (exit code: $BUILD_EXIT)"
  echo ""
  echo "Build took: ${BUILD_DURATION}s"
  echo "Full log: $FEATURE_DIR/build-local.log"
  echo ""

  # Show last 30 lines of error
  echo "Last 30 lines of output:"
  echo "─────────────────────────────────────────────"
  tail -30 "$FEATURE_DIR/build-local.log"
  echo "─────────────────────────────────────────────"
  echo ""

  update_workflow_phase "$FEATURE_DIR" "ship:build-local" "failed"
  exit 1
fi

echo "✅ Build completed successfully"
echo "   Duration: ${BUILD_DURATION}s"
echo ""

# Store build info
cat > "$FEATURE_DIR/build-info.json" <<EOF
{
  "build_system": "$PKG_MANAGER",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "duration_seconds": $BUILD_DURATION,
  "success": true,
  "commit": "$(git rev-parse HEAD 2>/dev/null || echo 'no-git')"
}
EOF

echo "💾 Build info saved: $FEATURE_DIR/build-info.json"
echo ""
```

**Build Process**:
- Auto-detect build system (npm, yarn, pnpm, make, cargo, go, python)
- Clean previous build artifacts
- Run production build
- Capture build logs
- Measure build duration
- Store build metadata

**Blocking**: Build failures stop the workflow

---

## Phase BL.3: Run Tests

**Purpose**: Execute test suite on built code

```bash
echo "🧪 Phase BL.3: Run Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if tests are available
HAS_TESTS=false

case "$PKG_MANAGER" in
  npm|yarn|pnpm)
    if grep -q '"test"' package.json 2>/dev/null; then
      HAS_TESTS=true
    fi
    ;;
  make)
    if make -n test >/dev/null 2>&1; then
      HAS_TESTS=true
    fi
    ;;
  cargo)
    if [ -d "tests" ] || grep -q "\[\[test\]\]" Cargo.toml 2>/dev/null; then
      HAS_TESTS=true
    fi
    ;;
  go)
    if find . -name "*_test.go" -not -path "*/vendor/*" | grep -q .; then
      HAS_TESTS=true
    fi
    ;;
  python)
    if [ -d "tests" ] || [ -f "pytest.ini" ] || grep -q "pytest" setup.py pyproject.toml 2>/dev/null; then
      HAS_TESTS=true
    fi
    ;;
esac

if [ "$HAS_TESTS" = false ]; then
  echo "⚠️  No tests detected - skipping test phase"
  echo ""
else
  echo "Running test suite..."
  echo ""

  TEST_START=$(date +%s)

  case "$PKG_MANAGER" in
    npm)
      npm test 2>&1 | tee "$FEATURE_DIR/test-local.log"
      TEST_EXIT=${PIPESTATUS[0]}
      ;;
    yarn)
      yarn test 2>&1 | tee "$FEATURE_DIR/test-local.log"
      TEST_EXIT=${PIPESTATUS[0]}
      ;;
    pnpm)
      pnpm test 2>&1 | tee "$FEATURE_DIR/test-local.log"
      TEST_EXIT=${PIPESTATUS[0]}
      ;;
    make)
      make test 2>&1 | tee "$FEATURE_DIR/test-local.log"
      TEST_EXIT=${PIPESTATUS[0]}
      ;;
    cargo)
      cargo test 2>&1 | tee "$FEATURE_DIR/test-local.log"
      TEST_EXIT=${PIPESTATUS[0]}
      ;;
    go)
      go test ./... 2>&1 | tee "$FEATURE_DIR/test-local.log"
      TEST_EXIT=${PIPESTATUS[0]}
      ;;
    python)
      if command -v pytest &> /dev/null; then
        pytest 2>&1 | tee "$FEATURE_DIR/test-local.log"
        TEST_EXIT=${PIPESTATUS[0]}
      else
        python -m unittest discover 2>&1 | tee "$FEATURE_DIR/test-local.log"
        TEST_EXIT=${PIPESTATUS[0]}
      fi
      ;;
  esac

  TEST_END=$(date +%s)
  TEST_DURATION=$((TEST_END - TEST_START))

  echo ""

  if [ $TEST_EXIT -ne 0 ]; then
    echo "❌ Tests FAILED (exit code: $TEST_EXIT)"
    echo ""
    echo "Test duration: ${TEST_DURATION}s"
    echo "Full log: $FEATURE_DIR/test-local.log"
    echo ""

    # Show test failures
    echo "Test failures:"
    echo "─────────────────────────────────────────────"
    tail -50 "$FEATURE_DIR/test-local.log" | grep -A 5 -i "failed\|error" || tail -30 "$FEATURE_DIR/test-local.log"
    echo "─────────────────────────────────────────────"
    echo ""

    update_workflow_phase "$FEATURE_DIR" "ship:build-local" "failed"
    exit 1
  fi

  echo "✅ All tests passed"
  echo "   Duration: ${TEST_DURATION}s"
  echo ""
fi
```

**Test Execution**:
- Auto-detect test framework
- Run test suite if available
- Capture test logs
- Display failures if any
- Non-blocking if no tests found

**Blocking**: Test failures stop the workflow

---

## Phase BL.4: Analyze Build Artifacts

**Purpose**: Validate and analyze build output

```bash
echo "📊 Phase BL.4: Analyze Build Artifacts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Find build directory
BUILD_DIR=""
for dir in dist build out .next target; do
  if [ -d "$dir" ]; then
    BUILD_DIR="$dir"
    break
  fi
done

if [ -z "$BUILD_DIR" ]; then
  echo "⚠️  No build directory found"
  echo "   Expected: dist, build, out, .next, or target"
  echo ""
else
  echo "Build directory: $BUILD_DIR"
  echo ""

  # Count files
  FILE_COUNT=$(find "$BUILD_DIR" -type f | wc -l)
  echo "Files: $FILE_COUNT"

  # Calculate total size
  if command -v du &> /dev/null; then
    TOTAL_SIZE=$(du -sh "$BUILD_DIR" | cut -f1)
    echo "Total size: $TOTAL_SIZE"
  fi

  # Find largest files
  echo ""
  echo "Top 10 largest files:"
  echo "─────────────────────────────────────────────"

  if command -v du &> /dev/null; then
    find "$BUILD_DIR" -type f -exec du -h {} + | sort -rh | head -10
  else
    find "$BUILD_DIR" -type f -ls | sort -k7 -rn | head -10 | awk '{print $7, $11}'
  fi

  echo "─────────────────────────────────────────────"
  echo ""

  # Check for source maps (should be present for debugging)
  SOURCE_MAPS=$(find "$BUILD_DIR" -name "*.map" | wc -l)

  if [ $SOURCE_MAPS -gt 0 ]; then
    echo "✅ Source maps found: $SOURCE_MAPS"
  else
    echo "⚠️  No source maps found (debugging may be difficult)"
  fi

  echo ""

  # Check for uncompressed files (potential optimization)
  if command -v gzip &> /dev/null; then
    UNCOMPRESSED_JS=$(find "$BUILD_DIR" -name "*.js" -not -name "*.min.js" | wc -l)

    if [ $UNCOMPRESSED_JS -gt 0 ]; then
      echo "💡 Consider minifying $UNCOMPRESSED_JS JavaScript files"
    else
      echo "✅ JavaScript files are minified"
    fi
  fi

  echo ""
fi

# Store artifact analysis
cat > "$FEATURE_DIR/build-artifacts.json" <<EOF
{
  "build_dir": "${BUILD_DIR:-none}",
  "file_count": ${FILE_COUNT:-0},
  "total_size": "${TOTAL_SIZE:-unknown}",
  "source_maps": ${SOURCE_MAPS:-0},
  "analyzed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "💾 Artifact analysis saved: $FEATURE_DIR/build-artifacts.json"
echo ""
```

**Analysis**:
- Locate build directory
- Count files and calculate size
- Identify largest files
- Check for source maps
- Suggest optimizations

**Non-Blocking**: Analysis failures don't stop workflow

---

## Phase BL.5: Security Scan (Optional)

**Purpose**: Run basic security checks on dependencies

```bash
echo "🔒 Phase BL.5: Security Scan"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SECURITY_ISSUES=0

case "$PKG_MANAGER" in
  npm)
    if command -v npm &> /dev/null; then
      echo "Running npm audit..."
      npm audit --json > "$FEATURE_DIR/security-audit.json" 2>&1 || true

      # Count vulnerabilities
      SECURITY_ISSUES=$(jq '.metadata.vulnerabilities.total // 0' "$FEATURE_DIR/security-audit.json" 2>/dev/null || echo "0")

      if [ "$SECURITY_ISSUES" -gt 0 ]; then
        echo "⚠️  Found $SECURITY_ISSUES security issues"
        echo "   Run: npm audit fix"
        echo "   Report: $FEATURE_DIR/security-audit.json"
      else
        echo "✅ No security issues found"
      fi
    fi
    ;;

  yarn)
    if command -v yarn &> /dev/null; then
      echo "Running yarn audit..."
      yarn audit --json > "$FEATURE_DIR/security-audit.json" 2>&1 || true
      echo "⚠️  Check report: $FEATURE_DIR/security-audit.json"
    fi
    ;;

  pnpm)
    if command -v pnpm &> /dev/null; then
      echo "Running pnpm audit..."
      pnpm audit --json > "$FEATURE_DIR/security-audit.json" 2>&1 || true

      if grep -q "vulnerabilities" "$FEATURE_DIR/security-audit.json"; then
        echo "⚠️  Security issues found"
        echo "   Run: pnpm audit --fix"
        echo "   Report: $FEATURE_DIR/security-audit.json"
      else
        echo "✅ No security issues found"
      fi
    fi
    ;;

  cargo)
    if command -v cargo &> /dev/null && command -v cargo-audit &> /dev/null; then
      echo "Running cargo audit..."
      cargo audit > "$FEATURE_DIR/security-audit.txt" 2>&1 || true
      echo "📄 Report: $FEATURE_DIR/security-audit.txt"
    else
      echo "⚠️  cargo-audit not installed"
      echo "   Install: cargo install cargo-audit"
    fi
    ;;

  go)
    if command -v go &> /dev/null; then
      echo "Running go mod verify..."
      go mod verify > "$FEATURE_DIR/security-audit.txt" 2>&1 || true
      echo "📄 Report: $FEATURE_DIR/security-audit.txt"
    fi
    ;;

  python)
    if command -v pip &> /dev/null && command -v safety &> /dev/null; then
      echo "Running safety check..."
      safety check --json > "$FEATURE_DIR/security-audit.json" 2>&1 || true
      echo "📄 Report: $FEATURE_DIR/security-audit.json"
    else
      echo "⚠️  safety not installed"
      echo "   Install: pip install safety"
    fi
    ;;

  *)
    echo "⚠️  No security scanner available for $PKG_MANAGER"
    ;;
esac

echo ""

# Security scan is informational only - don't block on issues
```

**Security Checks**:
- npm/yarn/pnpm audit
- cargo audit (if installed)
- go mod verify
- Python safety check (if installed)

**Non-Blocking**: Security issues are reported but don't stop workflow

---

## Phase BL.6: Generate Local Build Report

**Purpose**: Create comprehensive report of local build

```bash
echo "📝 Phase BL.6: Local Build Report"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Generate report
FEATURE_SLUG=$(yq eval '.feature.slug' "$STATE_FILE")
FEATURE_TITLE=$(yq eval '.feature.title' "$STATE_FILE")

cat > "$FEATURE_DIR/local-build-report.md" <<EOF
# Local Build Report

**Feature**: $FEATURE_TITLE
**Slug**: $FEATURE_SLUG
**Built**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Commit**: $(git rev-parse HEAD 2>/dev/null || echo 'no-git')

---

## Build Summary

**Build System**: $PKG_MANAGER
**Build Duration**: ${BUILD_DURATION}s
**Status**: ✅ SUCCESS

EOF

if [ "$HAS_TESTS" = true ]; then
  cat >> "$FEATURE_DIR/local-build-report.md" <<EOF
**Test Duration**: ${TEST_DURATION}s
**Tests**: ✅ PASSED

EOF
else
  cat >> "$FEATURE_DIR/local-build-report.md" <<EOF
**Tests**: ⏭️  SKIPPED (no tests found)

EOF
fi

cat >> "$FEATURE_DIR/local-build-report.md" <<EOF
---

## Build Artifacts

EOF

if [ -n "$BUILD_DIR" ]; then
  cat >> "$FEATURE_DIR/local-build-report.md" <<EOF
**Location**: \`$BUILD_DIR/\`
**Files**: $FILE_COUNT
**Total Size**: ${TOTAL_SIZE:-unknown}
**Source Maps**: ${SOURCE_MAPS:-0}

EOF
else
  cat >> "$FEATURE_DIR/local-build-report.md" <<EOF
**Location**: _Not detected_

EOF
fi

cat >> "$FEATURE_DIR/local-build-report.md" <<EOF
---

## Security

EOF

if [ -f "$FEATURE_DIR/security-audit.json" ] || [ -f "$FEATURE_DIR/security-audit.txt" ]; then
  if [ "$SECURITY_ISSUES" -gt 0 ]; then
    cat >> "$FEATURE_DIR/local-build-report.md" <<EOF
⚠️  **$SECURITY_ISSUES security issues found**

Run \`$PKG_MANAGER audit\` for details.

EOF
  else
    cat >> "$FEATURE_DIR/local-build-report.md" <<EOF
✅ **No security issues found**

EOF
  fi
else
  cat >> "$FEATURE_DIR/local-build-report.md" <<EOF
⏭️  **Security scan not available**

EOF
fi

cat >> "$FEATURE_DIR/local-build-report.md" <<EOF
---

## Next Steps

Since this is a local-only build:

1. **Continue `/ship` workflow**
   - Run `/ship continue` to merge feature to main branch
   - The workflow will automatically:
     - Merge your feature branch to main/master
     - Push to origin (if remote exists)
     - Bump version and create git tag
     - Update roadmap to mark feature as "Shipped"

2. **Manual Testing** (before `/ship continue`)
   - Test the built application thoroughly
   - Check for any runtime errors
   - Verify all features work as expected

3. **Performance Checks**
   - Measure load times
   - Check memory usage
   - Profile CPU usage if applicable

4. **Distribution** (after `/ship` completes)
   - Package for distribution
   - Create installers
   - Prepare release artifacts

**Important**: Do NOT manually merge to main. The `/ship` workflow handles:
- Merging feature branch → main/master
- Version bumping (package.json)
- Roadmap updates
- Git tag creation

---

## Build Logs

- Build log: \`build-local.log\`
EOF

if [ "$HAS_TESTS" = true ]; then
  echo "- Test log: \`test-local.log\`" >> "$FEATURE_DIR/local-build-report.md"
fi

if [ -f "$FEATURE_DIR/security-audit.json" ] || [ -f "$FEATURE_DIR/security-audit.txt" ]; then
  echo "- Security audit: \`security-audit.*\`" >> "$FEATURE_DIR/local-build-report.md"
fi

cat >> "$FEATURE_DIR/local-build-report.md" <<EOF
- Build info: \`build-info.json\`
- Artifact analysis: \`build-artifacts.json\`

---

**Generated**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

echo "📄 Local build report created: $FEATURE_DIR/local-build-report.md"
echo ""

# Update workflow state
update_workflow_phase "$FEATURE_DIR" "ship:build-local" "completed"

echo "✅ Local build complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Build Successful"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -n "$BUILD_DIR" ]; then
  echo "📦 Build output: $BUILD_DIR/"
fi

echo "📊 Full report: $FEATURE_DIR/local-build-report.md"
echo "📁 All artifacts: $FEATURE_DIR/"
echo ""

if [ "$SECURITY_ISSUES" -gt 0 ]; then
  echo "⚠️  $SECURITY_ISSUES security issues found"
  echo "   Run: $PKG_MANAGER audit fix"
  echo ""
fi

echo "✅ Ready for integration to main branch"
echo ""
echo "Next: Run /ship continue to merge to main and update roadmap"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

**Report Contents**:
- Build summary with duration
- Test results
- Build artifact analysis
- Security scan results
- Next steps for local development
- Links to all logs and artifacts

**State Updates**:
- Mark `ship:build-local` as completed
- Workflow ready for finalization

---

## Error Recovery

**Common Failures**:

1. **Build failure**
   ```bash
   # Check build logs
   cat specs/NNN-slug/build-local.log

   # Fix issues and retry
   /ship continue
   ```

2. **Test failure**
   ```bash
   # Check test logs
   cat specs/NNN-slug/test-local.log

   # Run tests locally to debug
   npm test  # or appropriate command

   # Fix and retry
   /ship continue
   ```

3. **No build system detected**
   ```bash
   # Ensure you have package.json, Makefile, Cargo.toml, etc.
   # Add build configuration if missing
   ```

**Recovery Steps**:
- Fix the issue causing failure
- Run `/ship continue` to retry
- Check logs in feature directory for details

---

## Success Criteria

- ✅ Pre-build checks passed
- ✅ Production build completed
- ✅ Tests passed (if available)
- ✅ Build artifacts analyzed
- ✅ Security scan completed (informational)
- ✅ Build report generated
- ✅ State updated to completed

---

## Notes

- **No deployment**: This command only builds locally
- **Integration**: After build, `/ship continue` will merge to main and update roadmap
- **Manual testing**: User responsible for testing built artifacts before merging
- **Distribution**: User handles packaging and distribution after `/ship` completes
- **Best for**: Local development, prototypes, learning projects
- **Security**: Security scan is informational, not blocking
- **Testing**: Tests are run if available, skipped if not

This command is automatically called by `/ship` when deployment model is `local-only`.

**Workflow**:
1. `/build-local` - Build and test locally (this command)
2. `/ship continue` - Merge to main, version bump, roadmap update
3. Manual distribution (if applicable)
