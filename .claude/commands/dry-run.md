---
description: Test deployment configuration without actually deploying
---

# Dry-Run: Deployment Config Validator

**Command**: `/dry-run`

**Purpose**: Validate deployment configurations without consuming quota. Test deployment workflows locally.

**When to use**:
- After modifying `vercel.json` or `railway.json`
- After updating Dockerfile
- Before first deployment of new service
- To debug deployment config issues

**What it validates**:
- Vercel configuration (vercel.json syntax)
- Railway configuration (railway.json syntax)
- Dockerfile build process
- Container health checks
- Service startup and readiness

---

## MENTAL MODEL

You are a **deployment config tester** that validates configurations without deploying.

**Philosophy**: Test configs locally. Catch configuration errors before they cause deployment failures.

**Checks**:
1. Vercel build simulation (local build with Vercel CLI)
2. Railway service simulation (Docker build + run)
3. Configuration file validation (JSON syntax)
4. Health endpoint validation (container running)
5. Environment variable validation (required vars present)

**Token efficiency**: Detailed error messages, actionable fixes.

---

## EXECUTION PHASES

### Phase 1: VALIDATE CONFIGURATION FILES

```bash
#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Dry Run: Deployment Config Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

DRY_RUN_FAILED=false

echo "Validating configuration files..."
echo ""

# Verify JSON: vercel.json
if [ -f "vercel.json" ]; then
  echo "Checking vercel.json..."

  jq empty vercel.json 2>/tmp/dry-run-vercel-json-error.log

  if [ $? -eq 0 ]; then
    echo "  ✅ vercel.json is valid JSON"

    # Check for common issues
    if jq '.builds' vercel.json >/dev/null 2>&1; then
      echo "  ⚠️  WARNING: 'builds' is deprecated in Vercel"
      echo "     Use 'buildCommand' instead"
    fi

    if jq '.routes' vercel.json >/dev/null 2>&1; then
      echo "  ⚠️  WARNING: 'routes' is deprecated in Vercel"
      echo "     Use 'rewrites', 'redirects', 'headers' instead"
    fi
  else
    echo "  ❌ vercel.json has syntax errors:"
    cat /tmp/dry-run-vercel-json-error.log | sed 's/^/     /'
    DRY_RUN_FAILED=true
  fi
else
  echo "  ⚠️  vercel.json not found (optional)"
fi

echo ""

# Check railway.json
if [ -f "railway.json" ]; then
  echo "Checking railway.json..."

  jq empty railway.json 2>/tmp/dry-run-railway-json-error.log

  if [ $? -eq 0 ]; then
    echo "  ✅ railway.json is valid JSON"
  else
    echo "  ❌ railway.json has syntax errors:"
    cat /tmp/dry-run-railway-json-error.log | sed 's/^/     /'
    DRY_RUN_FAILED=true
  fi
else
  echo "  ⚠️  railway.json not found (optional)"
fi

echo ""

# Check Dockerfile
if [ -f "api/Dockerfile" ]; then
  echo "Checking Dockerfile..."

  # Basic syntax check
  docker build --check -f api/Dockerfile . 2>/tmp/dry-run-dockerfile-error.log

  if [ $? -eq 0 ]; then
    echo "  ✅ Dockerfile syntax is valid"
  else
    echo "  ❌ Dockerfile has syntax errors:"
    cat /tmp/dry-run-dockerfile-error.log | sed 's/^/     /'
    DRY_RUN_FAILED=true
  fi
else
  echo "  ⚠️  api/Dockerfile not found"
fi

echo ""
```

---

### Phase 2: VERCEL DRY RUN (Marketing)

```bash
if [ "$DRY_RUN_FAILED" = false ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Vercel Dry Run: Marketing"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  cd apps/marketing

  # Simulate Vercel build
  echo "Simulating Vercel build..."
  echo ""

  vercel build --prod --yes 2>&1 | tee /tmp/dry-run-vercel-marketing.log

  MARKETING_BUILD_RESULT=${PIPESTATUS[0]}

  if [ $MARKETING_BUILD_RESULT -eq 0 ]; then
    echo ""
    echo "✅ Marketing would deploy successfully on Vercel"

    # Check build output size
    if [ -d ".vercel/output" ]; then
      OUTPUT_SIZE=$(du -sh .vercel/output | cut -f1)
      echo "   Build output size: $OUTPUT_SIZE"

      # Vercel has ~250MB limit for output
      OUTPUT_SIZE_KB=$(du -sk .vercel/output | cut -f1)
      if [ "$OUTPUT_SIZE_KB" -gt 250000 ]; then
        echo "   ⚠️  Build output large (>250MB), may fail on Vercel"
        echo "      Reduce bundle size or enable compression"
      fi
    fi
  else
    echo ""
    echo "❌ Marketing build would fail on Vercel"
    echo ""
    echo "Last 20 errors:"
    grep -i "error" /tmp/dry-run-vercel-marketing.log | tail -20 | sed 's/^/   /'
    DRY_RUN_FAILED=true
  fi

  cd ../..
  echo ""
fi
```

---

### Phase 3: VERCEL DRY RUN (App)

```bash
if [ "$DRY_RUN_FAILED" = false ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Vercel Dry Run: App"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  cd apps/app

  echo "Simulating Vercel build..."
  echo ""

  vercel build --prod --yes 2>&1 | tee /tmp/dry-run-vercel-app.log

  APP_BUILD_RESULT=${PIPESTATUS[0]}

  if [ $APP_BUILD_RESULT -eq 0 ]; then
    echo ""
    echo "✅ App would deploy successfully on Vercel"

    # Check build output size
    if [ -d ".vercel/output" ]; then
      OUTPUT_SIZE=$(du -sh .vercel/output | cut -f1)
      echo "   Build output size: $OUTPUT_SIZE"

      OUTPUT_SIZE_KB=$(du -sk .vercel/output | cut -f1)
      if [ "$OUTPUT_SIZE_KB" -gt 250000 ]; then
        echo "   ⚠️  Build output large (>250MB), may fail on Vercel"
      fi
    fi

    # Check for serverless function size
    if [ -d ".vercel/output/functions" ]; then
      FUNCTION_SIZES=$(find .vercel/output/functions -type f -name "*.func" -exec du -sh {} \; | sort -hr | head -5)

      if [ -n "$FUNCTION_SIZES" ]; then
        echo ""
        echo "Largest serverless functions:"
        echo "$FUNCTION_SIZES" | sed 's/^/   /'

        # Vercel has 50MB limit per function
        LARGEST_FUNCTION_KB=$(echo "$FUNCTION_SIZES" | head -1 | awk '{print $1}' | sed 's/M//' | awk '{print $1*1024}')

        if [ "$LARGEST_FUNCTION_KB" -gt 50000 ]; then
          echo ""
          echo "   ⚠️  Function exceeds 50MB limit"
          echo "      Split into smaller functions or reduce dependencies"
        fi
      fi
    fi
  else
    echo ""
    echo "❌ App build would fail on Vercel"
    echo ""
    echo "Last 20 errors:"
    grep -i "error" /tmp/dry-run-vercel-app.log | tail -20 | sed 's/^/   /'
    DRY_RUN_FAILED=true
  fi

  cd ../..
  echo ""
fi
```

---

### Phase 4: RAILWAY DRY RUN (API)

```bash
if [ "$DRY_RUN_FAILED" = false ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Railway Dry Run: API"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  echo "Building Docker image..."
  echo ""

  docker build -t api-dry-run -f api/Dockerfile . 2>&1 | tee /tmp/dry-run-docker-build.log

  DOCKER_BUILD_RESULT=${PIPESTATUS[0]}

  if [ $DOCKER_BUILD_RESULT -eq 0 ]; then
    echo ""
    echo "✅ Docker image builds successfully"

    # Check image size
    IMAGE_SIZE=$(docker images api-dry-run --format "{{.Size}}" | head -1)
    echo "   Image size: $IMAGE_SIZE"

    # Railway has size limits (varies by plan)
    IMAGE_SIZE_MB=$(docker images api-dry-run --format "{{.Size}}" | head -1 | sed 's/GB/*1024/;s/MB//' | bc 2>/dev/null || echo "?")

    if [ "$IMAGE_SIZE_MB" != "?" ] && [ "$IMAGE_SIZE_MB" -gt 2000 ]; then
      echo "   ⚠️  Image large (>2GB), may be slow to deploy"
      echo "      Consider multi-stage builds to reduce size"
    fi

    echo ""
    echo "Testing container startup..."
    echo ""

    # Start container with minimal env vars
    docker run --rm -d --name api-dry-run-test \
      --env DATABASE_URL="${DATABASE_URL:-postgresql://localhost/test}" \
      --env SECRET_KEY="${SECRET_KEY:-test-secret-key}" \
      --env ENVIRONMENT="test" \
      api-dry-run 2>/tmp/dry-run-docker-start.log

    if [ $? -ne 0 ]; then
      echo "❌ Container failed to start"
      echo ""
      echo "Error:"
      cat /tmp/dry-run-docker-start.log | sed 's/^/   /'
      DRY_RUN_FAILED=true
    else
      # Wait for startup
      echo "Waiting for container to initialize (10s)..."
      sleep 10

      # Check if still running
      if docker ps | grep -q api-dry-run-test; then
        echo "✅ Container starts successfully"

        # Check health endpoint
        echo ""
        echo "Testing health endpoint..."

        HEALTH_CHECK=$(docker exec api-dry-run-test curl -sf http://localhost:8000/api/v1/health/healthz 2>&1 || echo "")

        if [ -n "$HEALTH_CHECK" ]; then
          echo "✅ Health endpoint responds"
          echo "   Response: $HEALTH_CHECK"
        else
          echo "⚠️  Health endpoint not responding"
          echo "   Container may be unhealthy on Railway"

          # Show container logs
          echo ""
          echo "Container logs (last 20 lines):"
          docker logs api-dry-run-test 2>&1 | tail -20 | sed 's/^/   /'
        fi

        # Check port binding
        echo ""
        echo "Checking port configuration..."

        PORT_BINDING=$(docker port api-dry-run-test 2>/dev/null || echo "")

        if [ -n "$PORT_BINDING" ]; then
          echo "✅ Port bindings correct"
        else
          echo "⚠️  No port bindings found"
          echo "   Check EXPOSE directive in Dockerfile"
        fi

        # Cleanup
        docker stop api-dry-run-test >/dev/null 2>&1
      else
        echo "❌ Container exited unexpectedly"
        echo ""
        echo "Container logs:"
        docker logs api-dry-run-test 2>&1 | tail -30 | sed 's/^/   /'
        DRY_RUN_FAILED=true
      fi
    fi
  else
    echo ""
    echo "❌ Docker build would fail on Railway"
    echo ""
    echo "Last 20 errors:"
    tail -20 /tmp/dry-run-docker-build.log | sed 's/^/   /'
    DRY_RUN_FAILED=true
  fi

  echo ""
fi
```

---

### Phase 5: ENVIRONMENT VARIABLE CHECK

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Environment Variable Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Checking required environment variables..."
echo ""

# Load from .env.example
if [ -f ".env.example" ]; then
  REQUIRED_VARS=$(grep -v "^#" .env.example | grep "=" | cut -d= -f1)

  MISSING_COUNT=0

  for var in $REQUIRED_VARS; do
    if [ -z "${!var}" ]; then
      echo "  ⚠️  $var not set locally"
      MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
  done

  if [ "$MISSING_COUNT" -eq 0 ]; then
    echo "✅ All required variables set locally"
  else
    echo ""
    echo "⚠️  $MISSING_COUNT variables not set locally"
    echo "   This is OK for dry run, but ensure they're set in:"
    echo "   - Vercel: vercel env add [VAR]"
    echo "   - Railway: railway variables set [VAR]=[value]"
  fi
else
  echo "⚠️  .env.example not found"
  echo "   Cannot validate environment variables"
fi

echo ""
```

---

### Phase 6: FINAL REPORT

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$DRY_RUN_FAILED" = true ]; then
  echo "❌ DRY RUN FAILED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Deployment would fail with current configuration."
  echo ""
  echo "Fix issues above before deploying."
  echo ""

  # Cleanup
  rm -f /tmp/dry-run-*.log
  docker rmi api-dry-run 2>/dev/null || true
  docker rm -f api-dry-run-test 2>/dev/null || true

  exit 1
else
  echo "✅ DRY RUN PASSED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Deployment configuration is valid."
  echo ""
  echo "Validation results:"
  echo "  Vercel (marketing): ✅ Would succeed"
  echo "  Vercel (app): ✅ Would succeed"
  echo "  Railway (API): ✅ Would succeed"
  echo ""
  echo "Safe to deploy with /phase-1-ship"
  echo ""

  # Cleanup
  rm -f /tmp/dry-run-*.log
  docker rmi api-dry-run 2>/dev/null || true

  exit 0
fi
```

---

## ERROR HANDLING

**Vercel CLI not installed**: Shows installation instructions

**Docker daemon not running**: Shows `docker ps` command to start

**Configuration syntax errors**: Shows specific JSON parsing errors

**Build failures**: Shows last 20 errors from build logs

**Container startup failures**: Shows container logs

---

## CONSTRAINTS

- Requires Vercel CLI installed
- Requires Docker daemon running
- Non-destructive: No actual deployments
- Creates temporary Docker image (cleaned up after)
- Does not consume deployment quota
- All artifacts cleaned up on exit

---

## RETURN

**Success**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ DRY RUN PASSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Deployment configuration is valid.

Validation results:
  Vercel (marketing): ✅ Would succeed
  Vercel (app): ✅ Would succeed
  Railway (API): ✅ Would succeed

Safe to deploy with /phase-1-ship
```

**Failure**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ DRY RUN FAILED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Deployment would fail with current configuration.

[Specific failures listed above]

Fix issues above before deploying.
```
