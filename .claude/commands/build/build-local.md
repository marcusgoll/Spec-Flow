---
description: Local build and validation without deployment
internal: true
---

> **⚠️ INTERNAL COMMAND**
> Called automatically by `/ship` when deployment model is `local-only`. Most users should run `/ship`, not this.

# /build-local — Local Build & Validation

**Purpose**: Build and validate locally for projects without remote deployment.

**Use when**:
- No git remote / local-only dev
- Prototypes, experiments, desktop apps, learning projects

**Risk Level**: 🟢 LOW (no production deploy)

**Prereqs**:
- `/implement` complete
- `/optimize` complete
- `/preview` gate approved
- Pre-flight validation passed

---

## Phase BL.1: Initialize

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# Always start at repo root
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Normalize PATH for Windows Git Bash vs *nix
OS="${OSTYPE:-unknown}"

# Require tools early to fail fast
need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Missing tool: $1"; exit 1; }; }
need git
need jq
need yq

# Source workflow helpers (cross-platform)
if [[ "$OS" == msys* || "$OS" == win32* ]]; then
  # shellcheck disable=SC1091
  source ".spec-flow/scripts/bash/workflow-state.sh"
else
  # shellcheck disable=SC1091
  source ".spec-flow/scripts/bash/workflow-state.sh"
fi

# Find newest feature directory
FEATURE_DIR="$(ls -td specs/*/ 2>/dev/null | head -1 || true)"
[[ -z "${FEATURE_DIR:-}" ]] && { echo "❌ No specs/*/ directory found"; exit 1; }

STATE_FILE="$FEATURE_DIR/workflow-state.yaml"

# Auto-migrate old JSON state
if [[ ! -f "$STATE_FILE" && -f "$FEATURE_DIR/workflow-state.json" ]]; then
  yq -P "$FEATURE_DIR/workflow-state.json" > "$STATE_FILE"
fi
[[ -f "$STATE_FILE" ]] || { echo "❌ No workflow state found at $STATE_FILE"; exit 1; }

# Record phase timing and guard with trap
on_error() {
  echo ""
  echo "⚠️  Error in /build-local. Marking phase as failed."
  complete_phase_timing "$FEATURE_DIR" "ship:build-local" || true
  update_workflow_phase "$FEATURE_DIR" "ship:build-local" "failed" || true
}
trap on_error ERR

update_workflow_phase "$FEATURE_DIR" "ship:build-local" "in_progress"
start_phase_timing "$FEATURE_DIR" "ship:build-local"

echo "🏠 Local Build & Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Gates
echo "📋 Pre-Build Checklist"
echo "─────────────────────────────────────────────"
CHECKS_PASSED=true

yq -e '.quality_gates.pre_flight.passed == true' "$STATE_FILE" >/dev/null 2>&1 \
  && echo "✅ Pre-flight validation passed" || { echo "❌ Pre-flight validation not passed"; CHECKS_PASSED=false; }

test_phase_completed "$FEATURE_DIR" "ship:optimize" \
  && echo "✅ Optimization complete" || { echo "❌ Optimization phase not complete"; CHECKS_PASSED=false; }

PREVIEW_STATUS="$(yq -r '.workflow.manual_gates.preview.status // "pending"' "$STATE_FILE")"
[[ "$PREVIEW_STATUS" == "approved" ]] \
  && echo "✅ Preview approved" || { echo "❌ Preview gate not approved"; CHECKS_PASSED=false; }

echo ""
[[ "$CHECKS_PASSED" == true ]] || { echo "❌ Pre-build checks failed"; exit 1; }
echo "✅ All pre-build checks passed"
echo ""
```

---

## Phase BL.2: Production Build

```bash
echo "🔨 Phase BL.2: Production Build"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Prefer Node Corepack to lock package manager versions if available
if command -v corepack >/dev/null 2>&1; then
  corepack enable >/dev/null 2>&1 || true
fi

# Detect build system
PKG_MANAGER=""
if   [[ -f package-lock.json ]]; then PKG_MANAGER="npm"
elif [[ -f yarn.lock ]];        then PKG_MANAGER="yarn"
elif [[ -f pnpm-lock.yaml ]];   then PKG_MANAGER="pnpm"
elif [[ -f Makefile ]];         then PKG_MANAGER="make"
elif [[ -f Cargo.toml ]];       then PKG_MANAGER="cargo"
elif [[ -f go.mod ]];           then PKG_MANAGER="go"
elif [[ -f setup.py || -f pyproject.toml ]]; then PKG_MANAGER="python"
else
  echo "❌ No build system detected (npm/yarn/pnpm/make/cargo/go/python)"
  exit 1
fi
echo "Build system: $PKG_MANAGER"
echo ""

# Clean previous build output
echo "🧹 Cleaning previous build..."
rm -rf dist build .next out target 2>/dev/null || true
[[ "$PKG_MANAGER" == "make" ]] && make clean 2>/dev/null || true
[[ "$PKG_MANAGER" == "cargo" ]] && cargo clean 2>/dev/null || true
[[ "$PKG_MANAGER" == "go"    ]] && go clean   2>/dev/null || true
echo "✅ Clean complete"
echo ""

# Run build (capture logs)
echo "🔨 Running production build..."
echo ""
BUILD_START="$(date +%s)"

# Disable framework telemetry during local builds
export CI="${CI:-1}"
export NEXT_TELEMETRY_DISABLED=1

case "$PKG_MANAGER" in
  npm)   need npm;   npm run build   2>&1 | tee "$FEATURE_DIR/build-local.log";;
  yarn)  need yarn;  yarn build      2>&1 | tee "$FEATURE_DIR/build-local.log";;
  pnpm)  need pnpm;  pnpm build      2>&1 | tee "$FEATURE_DIR/build-local.log";;
  make)  need make;  make            2>&1 | tee "$FEATURE_DIR/build-local.log";;
  cargo) need cargo; cargo build --release 2>&1 | tee "$FEATURE_DIR/build-local.log";;
  go)    need go;    go build -o ./dist/ ./... 2>&1 | tee "$FEATURE_DIR/build-local.log";;
  python)
    need python
    if [[ -f setup.py ]]; then
      python setup.py build 2>&1 | tee "$FEATURE_DIR/build-local.log"
    else
      python -m pip install --upgrade build 2>/dev/null || true
      python -m build 2>&1 | tee "$FEATURE_DIR/build-local.log"
    fi
    ;;
esac

BUILD_EXIT=${PIPESTATUS[0]:-0}
BUILD_END="$(date +%s)"
BUILD_DURATION="$((BUILD_END - BUILD_START))"
echo ""

if [[ "$BUILD_EXIT" -ne 0 ]]; then
  echo "❌ Build FAILED (exit $BUILD_EXIT)"
  echo "Build took: ${BUILD_DURATION}s"
  echo "Full log: $FEATURE_DIR/build-local.log"
  echo ""
  echo "Last 30 lines:"
  echo "─────────────────────────────────────────────"
  tail -30 "$FEATURE_DIR/build-local.log" || true
  echo "─────────────────────────────────────────────"
  exit "$BUILD_EXIT"
fi

echo "✅ Build completed successfully in ${BUILD_DURATION}s"
echo ""

cat > "$FEATURE_DIR/build-info.json" <<EOF
{"build_system":"$PKG_MANAGER","timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","duration_seconds":$BUILD_DURATION,"success":true,"commit":"$(git rev-parse HEAD 2>/dev/null || echo no-git)"}
EOF
echo "💾 Build info saved: $FEATURE_DIR/build-info.json"
echo ""
```

---

## Phase BL.3: Run Tests

```bash
echo "🧪 Phase BL.3: Run Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

HAS_TESTS=false
case "$PKG_MANAGER" in
  npm|yarn|pnpm) grep -q '"test"' package.json 2>/dev/null && HAS_TESTS=true ;;
  make)          make -n test >/dev/null 2>&1 && HAS_TESTS=true ;;
  cargo)         [[ -d tests ]] || grep -q "\[\[test\]\]" Cargo.toml 2>/dev/null && HAS_TESTS=true ;;
  go)            find . -name "*_test.go" -not -path "*/vendor/*" | grep -q . && HAS_TESTS=true ;;
  python)        [[ -d tests || -f pytest.ini ]] || grep -qi pytest setup.py pyproject.toml 2>/dev/null && HAS_TESTS=true ;;
esac

if [[ "$HAS_TESTS" == false ]]; then
  echo "⏭️  No tests detected — skipping"
  echo ""
else
  echo "Running test suite..."
  echo ""
  TEST_START="$(date +%s)"
  case "$PKG_MANAGER" in
    npm)   npm test   2>&1 | tee "$FEATURE_DIR/test-local.log";;
    yarn)  yarn test  2>&1 | tee "$FEATURE_DIR/test-local.log";;
    pnpm)  pnpm test  2>&1 | tee "$FEATURE_DIR/test-local.log";;
    make)  make test  2>&1 | tee "$FEATURE_DIR/test-local.log";;
    cargo) cargo test 2>&1 | tee "$FEATURE_DIR/test-local.log";;
    go)    go test ./... 2>&1 | tee "$FEATURE_DIR/test-local.log";;
    python)
      if command -v pytest >/dev/null 2>&1; then
        pytest 2>&1 | tee "$FEATURE_DIR/test-local.log"
      else
        python -m unittest discover 2>&1 | tee "$FEATURE_DIR/test-local.log"
      fi
      ;;
  esac
  TEST_EXIT=${PIPESTATUS[0]:-0}
  TEST_DURATION="$(( $(date +%s) - TEST_START ))"
  echo ""
  if [[ "$TEST_EXIT" -ne 0 ]]; then
    echo "❌ Tests FAILED (exit $TEST_EXIT) in ${TEST_DURATION}s"
    echo "Full log: $FEATURE_DIR/test-local.log"
    echo ""
    echo "Failures (tail):"
    echo "─────────────────────────────────────────────"
    tail -50 "$FEATURE_DIR/test-local.log" || true
    echo "─────────────────────────────────────────────"
    exit "$TEST_EXIT"
  fi
  echo "✅ All tests passed in ${TEST_DURATION}s"
  echo ""
fi
```

---

## Phase BL.4: Analyze Build Artifacts

```bash
echo "📊 Phase BL.4: Analyze Build Artifacts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

BUILD_DIR=""
for dir in dist build out .next target; do [[ -d "$dir" ]] && BUILD_DIR="$dir" && break; done

if [[ -z "$BUILD_DIR" ]]; then
  echo "⚠️  No build directory found (expected: dist, build, out, .next, target)"
  FILE_COUNT=0; TOTAL_SIZE="unknown"; SOURCE_MAPS=0
else
  echo "Build directory: $BUILD_DIR"
  FILE_COUNT="$(find "$BUILD_DIR" -type f | wc -l | xargs)"
  TOTAL_SIZE="$( (du -sh "$BUILD_DIR" 2>/dev/null || echo unknown) | awk '{print $1}')"
  echo "Files: $FILE_COUNT"
  echo "Total size: $TOTAL_SIZE"
  echo ""
  echo "Top 10 largest files:"
  echo "─────────────────────────────────────────────"
  if command -v du >/dev/null 2>&1; then
    find "$BUILD_DIR" -type f -exec du -h {} + | sort -rh | head -10
  else
    find "$BUILD_DIR" -type f -ls | sort -k7 -rn | head -10 | awk '{print $7, $11}'
  fi
  echo "─────────────────────────────────────────────"
  SOURCE_MAPS="$(find "$BUILD_DIR" -name "*.map" | wc -l | xargs)"
  [[ "$SOURCE_MAPS" -gt 0 ]] && echo "✅ Source maps: $SOURCE_MAPS" || echo "⚠️  No source maps found"
  echo ""
fi

cat > "$FEATURE_DIR/build-artifacts.json" <<EOF
{"build_dir":"${BUILD_DIR:-none}","file_count":${FILE_COUNT:-0},"total_size":"${TOTAL_SIZE:-unknown}","source_maps":${SOURCE_MAPS:-0},"analyzed_at":"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
EOF
echo "💾 Artifact analysis saved: $FEATURE_DIR/build-artifacts.json"
echo ""
```

---

## Phase BL.5: Security Scan (Optional, non-blocking)

```bash
echo "🔒 Phase BL.5: Security Scan"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
SECURITY_ISSUES=0

case "$PKG_MANAGER" in
  npm)   if command -v npm  >/dev/null; then npm audit --json > "$FEATURE_DIR/security-audit.json" 2>&1 || true; SECURITY_ISSUES=$(jq -r '.metadata.vulnerabilities.total // 0' "$FEATURE_DIR/security-audit.json" 2>/dev/null || echo 0); fi ;;
  yarn)  if command -v yarn >/dev/null; then yarn audit --json > "$FEATURE_DIR/security-audit.json" 2>&1 || true; fi ;;
  pnpm)  if command -v pnpm >/dev/null; then pnpm audit --json > "$FEATURE_DIR/security-audit.json" 2>&1 || true; fi ;;
  cargo) if command -v cargo-audit >/dev/null; then cargo audit > "$FEATURE_DIR/security-audit.txt" 2>&1 || true; fi ;;
  go)    if command -v go >/dev/null; then go mod verify > "$FEATURE_DIR/security-audit.txt" 2>&1 || true; fi ;;
  python)
    if command -v safety >/dev/null 2>&1; then safety check --json > "$FEATURE_DIR/security-audit.json" 2>&1 || true; fi
    ;;
esac

if [[ "$SECURITY_ISSUES" -gt 0 ]]; then
  echo "⚠️  Found $SECURITY_ISSUES security issues"
  echo "   Run: $PKG_MANAGER audit fix"
  echo "   Report: $FEATURE_DIR/security-audit.json"
else
  echo "✅ No security issues found (or scan not available)"
fi

# Optional SBOM if CycloneDX cdxgen is present
if command -v cdxgen >/dev/null 2>&1; then
  echo ""
  echo "Generating CycloneDX SBOM..."
  cdxgen -o "$FEATURE_DIR/sbom.cdx.json" >/dev/null 2>&1 || true
  [[ -f "$FEATURE_DIR/sbom.cdx.json" ]] && echo "✅ SBOM generated: sbom.cdx.json"
fi
echo ""
```

> **References**:
> - **Node Corepack**: Stabilizes package-manager selection for reproducibility ([npm docs](https://docs.npmjs.com/cli/v8/commands/npm-audit))
> - **Rust cargo-audit**: Dependency vulnerability scanner ([RustSec](https://rustsec.org/))
> - **Python Safety**: Checks Python dependencies against known CVEs ([Safety](https://pyup.io/safety/))
> - **CycloneDX**: Vendor-neutral SBOM standard ([CycloneDX](https://cyclonedx.org/))

---

## Phase BL.6: Local Build Report

```bash
echo "📝 Phase BL.6: Local Build Report"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

FEATURE_SLUG="$(yq -r '.feature.slug' "$STATE_FILE")"
FEATURE_TITLE="$(yq -r '.feature.title' "$STATE_FILE")"

{
  echo "# Local Build Report"
  echo ""
  echo "**Feature**: ${FEATURE_TITLE:-unknown}"
  echo "**Slug**: ${FEATURE_SLUG:-unknown}"
  echo "**Built**: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "**Commit**: $(git rev-parse HEAD 2>/dev/null || echo 'no-git')"
  echo ""
  echo "---"
  echo ""
  echo "## Build Summary"
  echo ""
  echo "**Build System**: $PKG_MANAGER"
  echo "**Build Duration**: ${BUILD_DURATION}s"
  echo "**Status**: ✅ SUCCESS"
  echo ""
  if [[ -f "$FEATURE_DIR/test-local.log" ]]; then
    echo "**Tests**: ✅ PASSED (${TEST_DURATION}s)"
  else
    echo "**Tests**: ⏭️  SKIPPED (no tests found)"
  fi
  echo ""
  echo "---"
  echo ""
  echo "## Build Artifacts"
  echo ""
  if [[ -n "${BUILD_DIR:-}" ]]; then
    echo "**Location**: \`$BUILD_DIR/\`"
    echo "**Files**: ${FILE_COUNT:-0}"
    echo "**Total Size**: ${TOTAL_SIZE:-unknown}"
    echo "**Source Maps**: ${SOURCE_MAPS:-0}"
  else
    echo "**Location**: _Not detected_"
  fi
  echo ""
  echo "---"
  echo ""
  echo "## Security"
  if ls "$FEATURE_DIR"/security-audit.* >/dev/null 2>&1; then
    if [[ "$SECURITY_ISSUES" -gt 0 ]]; then
      echo "⚠️  **$SECURITY_ISSUES security issues found**"
      echo ""
      echo "Run \`$PKG_MANAGER audit\` for details."
    else
      echo "✅ **No security issues found**"
    fi
  else
    echo "⏭️  **Security scan not available**"
  fi
  if [[ -f "$FEATURE_DIR/sbom.cdx.json" ]]; then
    echo ""
    echo "**SBOM**: sbom.cdx.json (CycloneDX)"
  fi
  echo ""
  echo "---"
  echo ""
  echo "## Next Steps"
  echo ""
  echo "1. **Continue /ship workflow**:"
  echo "   - Run \`/ship continue\` to merge to main and update roadmap"
  echo "   - Handles branch merge, version bump, tag creation"
  echo ""
  echo "2. **Manual Testing** (before \`/ship continue\`):"
  echo "   - Test the built application thoroughly"
  echo "   - Check for runtime errors"
  echo "   - Verify all features work as expected"
  echo ""
  echo "3. **Performance Checks**:"
  echo "   - Measure load times"
  echo "   - Check memory usage"
  echo "   - Profile CPU if applicable"
  echo ""
  echo "4. **Distribution** (after \`/ship\` completes):"
  echo "   - Package for distribution"
  echo "   - Create installers"
  echo "   - Prepare release artifacts"
  echo ""
  echo "**Important**: Do NOT manually merge to main. Use \`/ship continue\`."
  echo ""
  echo "---"
  echo ""
  echo "## Logs"
  echo "- Build: \`build-local.log\`"
  [[ -f "$FEATURE_DIR/test-local.log" ]] && echo "- Tests: \`test-local.log\`"
  ls "$FEATURE_DIR"/security-audit.* >/dev/null 2>&1 && echo "- Security: \`security-audit.*\`"
  echo "- Build info: \`build-info.json\`"
  echo "- Artifact analysis: \`build-artifacts.json\`"
  echo ""
  echo "---"
  echo ""
  echo "**Generated**: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$FEATURE_DIR/local-build-report.md"

echo "📄 Local build report created: $FEATURE_DIR/local-build-report.md"
echo ""

# Phase success
complete_phase_timing "$FEATURE_DIR" "ship:build-local"
update_workflow_phase "$FEATURE_DIR" "ship:build-local" "completed"

echo ""
echo "✅ Local build complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Build Successful"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 Build output: ${BUILD_DIR:-<none>}/"
echo "📊 Report: $FEATURE_DIR/local-build-report.md"
echo "📁 All artifacts: $FEATURE_DIR/"
echo ""
[[ "$SECURITY_ISSUES" -gt 0 ]] && echo "⚠️  $SECURITY_ISSUES security issues found — run \`$PKG_MANAGER audit fix\`" && echo ""
echo "✅ Ready for integration to main branch"
echo ""
echo "Next: Run \`/ship continue\` to merge to main and update roadmap"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

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

4. **Missing tools**
   ```bash
   # Install required tools
   # npm/yarn/pnpm: Install Node.js from nodejs.org
   # make: Install build-essential (Linux) or Xcode CLI (macOS)
   # cargo: Install Rust from rustup.rs
   # go: Install Go from go.dev
   # python: Install Python from python.org

   # Enable Corepack (Node projects)
   corepack enable

   # Optional: Install security scanners
   cargo install cargo-audit  # Rust
   pip install safety         # Python
   npm i -g @cyclonedx/cdxgen # SBOM generation
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
- **Reproducibility**: Corepack locks package manager versions (Node projects)
- **Telemetry**: Disabled during local builds (Next.js, etc.)

This command is automatically called by `/ship` when deployment model is `local-only`.

**Workflow**:
1. `/build-local` - Build and test locally (this command)
2. `/ship continue` - Merge to main, version bump, roadmap update
3. Manual distribution (if applicable)
