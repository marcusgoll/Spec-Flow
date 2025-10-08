---
description: Pre-flight deployment validation - Catch failures before consuming quota
---

# Pre-Flight: Deployment Readiness Check

**Command**: `/preflight`

**Purpose**: Simulate deployment locally before pushing. Catches deployment failures before they cost quota.

**When to use**:
- Before `/phase-1-ship` (automatically invoked)
- Before manual deployments
- After major configuration changes

**Workflow position**: `optimize → preview → **preflight** → phase-1-ship`

---

## MENTAL MODEL

You are a **deployment simulator** that validates deployment readiness without consuming quota.

**Philosophy**: Test in production-like conditions locally. Catch 90% of deployment failures before they reach CI/CD.

**Checks**:
1. Environment variables (all required vars present)
2. Production builds (marketing + app)
3. Docker images (API container)
4. Database migrations (on test DB)
5. Type safety (TypeScript errors)
6. Bundle sizes (Vercel limits)
7. Lighthouse scores (local preview)

**Token efficiency**: Fast validation, minimal output. Red/green status indicators.

---

## EXECUTION PHASES

### Phase 1: ENVIRONMENT VARIABLES

```bash
#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚦 PRE-FLIGHT CHECK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PREFLIGHT_FAILED=false

echo "Checking environment variables..."
echo ""

# Required backend vars
BACKEND_VARS=(
  "DATABASE_URL"
  "OPENAI_API_KEY"
  "SECRET_KEY"
  "ENVIRONMENT"
)

# Required frontend vars
FRONTEND_VARS=(
  "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY"
  "CLERK_SECRET_KEY"
  "NEXT_PUBLIC_API_URL"
)

# Check backend
cd api
for var in "${BACKEND_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "  ❌ Missing: $var (backend)"
    PREFLIGHT_FAILED=true
  else
    echo "  ✅ Found: $var"
  fi
done
cd ..

# Check frontend
cd apps/app
for var in "${FRONTEND_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "  ❌ Missing: $var (frontend)"
    PREFLIGHT_FAILED=true
  else
    echo "  ✅ Found: $var"
  fi
done
cd ../..

echo ""
```

---

### Phase 2: PRODUCTION BUILDS

```bash
echo "Testing production builds..."
echo ""

# Marketing build
echo "Building marketing site..."
cd apps/marketing
pnpm build 2>&1 | tee /tmp/preflight-marketing-build.log >/dev/null

if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "  ❌ Marketing build failed"
  echo ""
  echo "Last 10 errors:"
  grep -i "error" /tmp/preflight-marketing-build.log | tail -10 | sed 's/^/    /'
  PREFLIGHT_FAILED=true
else
  MARKETING_BUILD_TIME=$(grep -oE "completed in [0-9]+\.?[0-9]*s" /tmp/preflight-marketing-build.log | tail -1 | grep -oE "[0-9]+\.?[0-9]*" || echo "?")
  echo "  ✅ Marketing build succeeded (${MARKETING_BUILD_TIME}s)"
fi
cd ../..

# App build
echo "Building app..."
cd apps/app
pnpm build 2>&1 | tee /tmp/preflight-app-build.log >/dev/null

if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "  ❌ App build failed"
  echo ""
  echo "Last 10 errors:"
  grep -i "error" /tmp/preflight-app-build.log | tail -10 | sed 's/^/    /'
  PREFLIGHT_FAILED=true
else
  APP_BUILD_TIME=$(grep -oE "completed in [0-9]+\.?[0-9]*s" /tmp/preflight-app-build.log | tail -1 | grep -oE "[0-9]+\.?[0-9]*" || echo "?")
  echo "  ✅ App build succeeded (${APP_BUILD_TIME}s)"
fi
cd ../..

echo ""
```

---

### Phase 3: DOCKER IMAGE (API)

```bash
echo "Building Railway Docker image..."
echo ""

# Build image
docker build -t api-preflight -f api/Dockerfile . 2>&1 | tee /tmp/preflight-docker-build.log >/dev/null

if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "  ❌ Docker build failed"
  echo ""
  echo "Last 10 errors:"
  tail -10 /tmp/preflight-docker-build.log | sed 's/^/    /'
  PREFLIGHT_FAILED=true
else
  DOCKER_BUILD_TIME=$(grep -oE "[0-9]+\.?[0-9]*s" /tmp/preflight-docker-build.log | tail -1 | grep -oE "[0-9]+\.?[0-9]*" || echo "?")
  echo "  ✅ Docker image builds (${DOCKER_BUILD_TIME}s)"

  # Test container starts
  echo "  Testing container startup..."

  docker run --rm -d --name api-preflight-test \
    --env DATABASE_URL="${DATABASE_URL}" \
    --env SECRET_KEY="${SECRET_KEY}" \
    --env ENVIRONMENT="test" \
    api-preflight 2>/dev/null

  sleep 5

  if docker ps | grep -q api-preflight-test; then
    echo "  ✅ Container starts successfully"

    # Check health endpoint
    if docker exec api-preflight-test curl -sf http://localhost:8000/api/v1/health/healthz >/dev/null 2>&1; then
      echo "  ✅ Health endpoint responds"
    else
      echo "  ⚠️  Health endpoint not responding"
    fi

    docker stop api-preflight-test >/dev/null 2>&1
  else
    echo "  ❌ Container failed to start"
    docker logs api-preflight-test 2>&1 | tail -20 | sed 's/^/    /'
    PREFLIGHT_FAILED=true
  fi
fi

echo ""
```

---

### Phase 4: DATABASE MIGRATIONS

```bash
echo "Testing database migrations..."
echo ""

cd api

# Create test database (if doesn't exist)
TEST_DB_URL="${DATABASE_URL%/*}/test_preflight_$(date +%s)"

echo "  Test DB: $TEST_DB_URL"

# Run migrations on test DB
DATABASE_URL="$TEST_DB_URL" uv run alembic upgrade head 2>&1 | tee /tmp/preflight-migrations.log >/dev/null

if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "  ❌ Migrations failed"
  echo ""
  echo "Last 10 errors:"
  tail -10 /tmp/preflight-migrations.log | sed 's/^/    /'
  PREFLIGHT_FAILED=true
else
  echo "  ✅ Migrations succeed"

  # Check migration state
  CURRENT_MIGRATION=$(DATABASE_URL="$TEST_DB_URL" uv run alembic current 2>/dev/null | tail -1)
  echo "  Current revision: ${CURRENT_MIGRATION:0:12}..."
fi

# Cleanup test DB
psql "$TEST_DB_URL" -c "DROP DATABASE IF EXISTS $(basename $TEST_DB_URL)" 2>/dev/null || true

cd ..
echo ""
```

---

### Phase 5: TYPE CHECKING

```bash
echo "Running TypeScript checks..."
echo ""

# Backend types
cd api
uv run mypy app/ --no-error-summary 2>&1 | tee /tmp/preflight-backend-types.log >/dev/null

if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "  ❌ Backend type errors found"
  echo ""
  echo "First 5 errors:"
  head -5 /tmp/preflight-backend-types.log | sed 's/^/    /'
  PREFLIGHT_FAILED=true
else
  echo "  ✅ Backend types pass"
fi
cd ..

# Frontend types (app)
cd apps/app
pnpm type-check 2>&1 | tee /tmp/preflight-app-types.log >/dev/null

if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "  ❌ App type errors found"
  echo ""
  echo "First 5 errors:"
  grep "error TS" /tmp/preflight-app-types.log | head -5 | sed 's/^/    /'
  PREFLIGHT_FAILED=true
else
  echo "  ✅ App types pass"
fi
cd ../..

# Frontend types (marketing)
cd apps/marketing
pnpm type-check 2>&1 | tee /tmp/preflight-marketing-types.log >/dev/null

if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "  ❌ Marketing type errors found"
  echo ""
  echo "First 5 errors:"
  grep "error TS" /tmp/preflight-marketing-types.log | head -5 | sed 's/^/    /'
  PREFLIGHT_FAILED=true
else
  echo "  ✅ Marketing types pass"
fi
cd ../..

echo ""
```

---

### Phase 6: BUNDLE SIZES

```bash
echo "Checking bundle sizes..."
echo ""

# Marketing bundle
if [ -d "apps/marketing/.next" ]; then
  MARKETING_SIZE=$(du -sk apps/marketing/.next | cut -f1)
  MARKETING_SIZE_MB=$((MARKETING_SIZE / 1024))

  if [ "$MARKETING_SIZE" -gt 400000 ]; then
    echo "  ⚠️  Marketing bundle large: ${MARKETING_SIZE_MB}MB (limit: ~400MB)"
  else
    echo "  ✅ Marketing bundle: ${MARKETING_SIZE_MB}MB"
  fi
else
  echo "  ⚠️  Marketing .next not found (build first)"
fi

# App bundle
if [ -d "apps/app/.next" ]; then
  APP_SIZE=$(du -sk apps/app/.next | cut -f1)
  APP_SIZE_MB=$((APP_SIZE / 1024))

  if [ "$APP_SIZE" -gt 400000 ]; then
    echo "  ⚠️  App bundle large: ${APP_SIZE_MB}MB (limit: ~400MB)"
  else
    echo "  ✅ App bundle: ${APP_SIZE_MB}MB"
  fi
else
  echo "  ⚠️  App .next not found (build first)"
fi

echo ""
```

---

### Phase 7: LIGHTHOUSE (OPTIONAL)

```bash
if [ -f ".lighthouserc.json" ]; then
  echo "Running Lighthouse on local production build..."
  echo ""

  # Start production server
  cd apps/app
  pnpm start &
  SERVER_PID=$!
  cd ../..

  sleep 10

  # Run Lighthouse CI
  lhci autorun --config=.lighthouserc.json 2>&1 | tee /tmp/preflight-lighthouse.log >/dev/null
  LIGHTHOUSE_EXIT=${PIPESTATUS[0]}

  # Parse scores
  PERF_SCORE=$(grep -oE "performance: [0-9]+" /tmp/preflight-lighthouse.log | grep -oE "[0-9]+" || echo "?")
  A11Y_SCORE=$(grep -oE "accessibility: [0-9]+" /tmp/preflight-lighthouse.log | grep -oE "[0-9]+" || echo "?")

  kill $SERVER_PID 2>/dev/null || true

  if [ "$LIGHTHOUSE_EXIT" -ne 0 ]; then
    echo "  ⚠️  Lighthouse checks would fail in CI"
    echo "     Performance: $PERF_SCORE (target: ≥90)"
    echo "     Accessibility: $A11Y_SCORE (target: ≥95)"
  else
    echo "  ✅ Lighthouse: Performance $PERF_SCORE, A11y $A11Y_SCORE"
  fi

  echo ""
else
  echo "Lighthouse: Skipped (.lighthouserc.json not found)"
  echo ""
fi
```

---

### Phase 8: FINAL REPORT

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$PREFLIGHT_FAILED" = true ]; then
  echo "❌ PRE-FLIGHT FAILED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Fix issues above before deploying."
  echo ""
  echo "To skip preflight (not recommended):"
  echo "  /phase-1-ship --skip-preflight"
  echo ""

  # Cleanup
  rm -f /tmp/preflight-*.log
  docker rmi api-preflight 2>/dev/null || true

  exit 1
else
  echo "✅ READY TO DEPLOY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Deployment prediction:"
  echo "  Vercel: ✅ Should succeed"
  echo "  Railway: ✅ Should succeed"
  echo "  CI checks: ✅ Should pass"
  echo ""
  echo "Proceed with: /phase-1-ship"
  echo ""

  # Cleanup
  rm -f /tmp/preflight-*.log
  docker rmi api-preflight 2>/dev/null || true

  exit 0
fi
```

---

## ERROR HANDLING

**Missing environment variables**: Lists missing vars, exits with code 1

**Build failures**: Shows last 10 errors, exits with code 1

**Docker failures**: Shows container logs, exits with code 1

**Migration failures**: Shows migration errors, cleans up test DB

**Type errors**: Shows first 5 errors per component

**Bundle size warnings**: Non-blocking, shows warning only

**Lighthouse failures**: Non-blocking, shows scores for debugging

---

## CONSTRAINTS

- Run from repository root only
- Requires Docker daemon running (for API check)
- Requires test database access (for migrations)
- Creates temporary test database (cleaned up after)
- All temporary artifacts cleaned up on exit
- Fast execution: ~2-3 minutes total
- Non-destructive: No changes to working directory

---

## RETURN

**Success**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ READY TO DEPLOY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Deployment prediction:
  Vercel: ✅ Should succeed
  Railway: ✅ Should succeed
  CI checks: ✅ Should pass

Proceed with: /phase-1-ship
```

**Failure**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ PRE-FLIGHT FAILED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Specific failures listed above]

Fix issues above before deploying.

To skip preflight (not recommended):
  /phase-1-ship --skip-preflight
```
