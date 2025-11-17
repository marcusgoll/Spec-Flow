
## SETUP CLEANUP HANDLER

**Ensure dev servers stop on exit:**

```bash
# Trap cleanup on exit
cleanup() {
  echo ""
  echo "Cleaning up..."

  # Stop dev servers
  if [ -f /tmp/preview-server-pids.txt ]; then
    PIDS=$(cat /tmp/preview-server-pids.txt)
    if [ -n "$PIDS" ]; then
      kill $PIDS 2>/dev/null || true
    fi
    rm /tmp/preview-server-pids.txt
  fi

  # Remove temp files
  rm -f /tmp/pr-body-*.md
  rm -f /tmp/capture-screenshots-*.spec.ts
  rm -f /tmp/marketing-dev.log
  rm -f /tmp/app-dev.log
  rm -f /tmp/api-dev.log
  rm -f /tmp/celery-worker.log
  rm -f /tmp/web-dev.log
}

trap cleanup EXIT INT TERM
```

---

## LOAD FEATURE

**Get feature from argument or current branch:**

```bash
if [ -n "$ARGUMENTS" ]; then
  SLUG="$ARGUMENTS"
else
  SLUG=$(git branch --show-current)
fi

FEATURE_DIR="specs/$SLUG"
```

**Validate feature exists:**

```bash
if [ ! -d "$FEATURE_DIR" ]; then
  echo "❌ Feature not found: $FEATURE_DIR"
  echo ""
  echo "Available features:"
  find specs/ -maxdepth 1 -type d -name "*-*" | sed 's|specs/||' | sort
  exit 1
fi
```

**Validate optimization complete:**

```bash
if ! grep -q "✅ Phase 5 (Optimize): Completed" "$FEATURE_DIR/NOTES.md" 2>/dev/null; then
  echo "⚠️  Optimization not complete"
  echo ""
  echo "Recommended workflow:"
  echo "  1. Run /optimize to validate production readiness"
  echo "  2. Fix any blockers"
  echo "  3. Then run /preview"
  echo ""
  read -p "Continue anyway? (y/N): " CONTINUE
  if [ "$CONTINUE" != "y" ]; then
    exit 1
  fi
fi
```

**Check for optimization blockers:**

```bash
if [ -f "$FEATURE_DIR/optimization-report.md" ]; then
  BLOCKERS=$(grep -c "❌ BLOCKER" "$FEATURE_DIR/optimization-report.md" 2>/dev/null || echo 0)

  if [ "$BLOCKERS" -gt 0 ]; then
    echo "❌ Found $BLOCKERS blocker(s) in optimization report"
    echo ""
    echo "Preview blocked. Fix blockers first:"
    grep "❌ BLOCKER" "$FEATURE_DIR/optimization-report.md" | head -5
    echo ""
    echo "Run /optimize to see full report"
    exit 1
  fi
fi
```

**Display feature info:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Preview Testing: $SLUG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Feature: $SLUG"
echo "Directory: $FEATURE_DIR"
echo ""
```

---

## DETECT AFFECTED APPS

**Check which apps have routes for this feature:**

```bash
echo "Detecting affected applications..."
echo ""

AFFECTED_APPS=()
ROUTES=()

# Check marketing app
if [ -d "apps/marketing/app/$SLUG" ] || find apps/marketing -path "*/$SLUG/*" -name "page.tsx" 2>/dev/null | grep -q .; then
  AFFECTED_APPS+=("marketing")

  MARKETING_ROUTES=$(find apps/marketing/app -path "*/$SLUG/*" -name "page.tsx" 2>/dev/null | sed 's|apps/marketing/app||' | sed 's|/page.tsx||')
  if [ -n "$MARKETING_ROUTES" ]; then
    while IFS= read -r route; do
      if [ -n "$route" ]; then
        ROUTES+=("http://localhost:3000$route")
      fi
    done <<< "$MARKETING_ROUTES"
  fi
fi

# Check app
if [ -d "apps/app/app/$SLUG" ] || find apps/app -path "*/$SLUG/*" -name "page.tsx" 2>/dev/null | grep -q .; then
  AFFECTED_APPS+=("app")

  APP_ROUTES=$(find apps/app/app -path "*/$SLUG/*" -name "page.tsx" 2>/dev/null | sed 's|apps/app/app||' | sed 's|/page.tsx||')
  if [ -n "$APP_ROUTES" ]; then
    while IFS= read -r route; do
      if [ -n "$route" ]; then
        ROUTES+=("http://localhost:3001$route")
      fi
    done <<< "$APP_ROUTES"
  fi
fi

if [ ${#AFFECTED_APPS[@]} -eq 0 ]; then
  echo "⚠️  No UI routes found for this feature"
  echo ""
  echo "This might be:"
  echo "  1. Backend-only feature (API endpoints)"
  echo "  2. Routes not yet implemented"
  echo "  3. Routes in unexpected location"
  echo ""
  echo "Searched in:"
  echo "  - apps/marketing/app/$SLUG/"
  echo "  - apps/app/app/$SLUG/"
  echo ""
  read -p "Continue with preview? (y/N): " CONTINUE
  if [ "$CONTINUE" != "y" ]; then
    exit 0
  fi
fi

echo "Affected apps: ${AFFECTED_APPS[*]}"
echo "Routes found: ${#ROUTES[@]}"
for route in "${ROUTES[@]}"; do
  echo "  🌐 $route"
done
echo ""
```

---

## DETECT NON-UI FEATURES / PREVIEW MODE

**Auto-detect API, Data/Infra, and Worker modes:**

```bash
echo "Detecting Non-UI changes..."
echo ""

API_MODE=false
DATA_MODE=false
WORKER_MODE=false

# Gather changed files (reuse CHANGED_FILES if available)
if [ -z "$CHANGED_FILES" ]; then
  CHANGED_FILES=$(gh pr view "$PR_NUMBER" --json files -q '.files[].path' 2>/dev/null || git diff --name-only HEAD~1)
fi

if echo "$CHANGED_FILES" | grep -Eq '^api/|^backend/|^services/'; then API_MODE=true; fi
if echo "$CHANGED_FILES" | grep -Eq '^api/migrations/|^migrations/|alembic.ini|^db/'; then DATA_MODE=true; fi
if echo "$CHANGED_FILES" | grep -Eq '^api/.+worker|^api/.+tasks|^api/.+celery'; then WORKER_MODE=true; API_MODE=true; fi

# If spec mentions API changes, enable API mode
if grep -q "## API Changes" "$FEATURE_DIR/spec.md" 2>/dev/null; then API_MODE=true; fi

# Try to find OpenAPI files
OPENAPI_FILE=""
for f in api/openapi.json api/openapi.yaml api/openapi.yml; do
  [ -f "$f" ] && OPENAPI_FILE="$f" && break
done

if [ -n "$OPENAPI_FILE" ]; then API_MODE=true; fi

echo "Preview modes:"
$API_MODE && echo "  • API mode"
$DATA_MODE && echo "  • Data/Infra mode"
$WORKER_MODE && echo "  • Worker mode"
if ! $API_MODE && ! $DATA_MODE && ! $WORKER_MODE; then
  echo "  • None (UI-only or no backend changes)"
fi
echo ""
```

---

## GENERATE TESTING CHECKLIST

**Extract scenarios and acceptance criteria from spec.md:**

```bash
echo "Generating testing checklist from spec.md..."
echo ""

SPEC_FILE="$FEATURE_DIR/spec.md"

if [ ! -f "$SPEC_FILE" ]; then
  echo "⚠️  spec.md not found"
  echo ""
  read -p "Create minimal checklist anyway? (y/N): " CREATE
  if [ "$CREATE" != "y" ]; then
    exit 1
  fi

  SCENARIOS=""
  CRITERIA=""
  SCENARIO_COUNT=0
  CRITERIA_COUNT=0
else
  # Extract user scenarios
  SCENARIOS=$(sed -n '/## User Scenarios/,/^## /p' "$SPEC_FILE" | \
              grep "^- " | \
              sed 's/^- //')

  SCENARIO_COUNT=$(echo "$SCENARIOS" | grep -c . || echo 0)

  # Extract acceptance criteria
  CRITERIA=$(sed -n '/## Acceptance Criteria/,/^## /p' "$SPEC_FILE" | \
             grep "^- " | \
             sed 's/^- //')

  CRITERIA_COUNT=$(echo "$CRITERIA" | grep -c . || echo 0)
fi

# Check for visual specs
VISUALS_DIR="$FEATURE_DIR/visuals"
if [ -f "$VISUALS_DIR/README.md" ]; then
  HAS_VISUAL_SPECS=true
  VISUAL_REQUIREMENTS=$(sed -n '/## Design Requirements/,/^## /p' "$VISUALS_DIR/README.md" 2>/dev/null | \
                        grep "^- " | \
                        sed 's/^- //')
else
  HAS_VISUAL_SPECS=false
  VISUAL_REQUIREMENTS=""
fi

echo "Scenarios: $SCENARIO_COUNT"
echo "Criteria: $CRITERIA_COUNT"
echo "Visual specs: $([ "$HAS_VISUAL_SPECS" = true ] && echo "Yes" || echo "No")"
echo ""

# Create checklist file
CHECKLIST_FILE="$FEATURE_DIR/preview-checklist.md"

cat > "$CHECKLIST_FILE" <<EOF
# Preview Testing Checklist: $SLUG

**Generated**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Tester**: [Your name]

---

## Routes to Test

EOF

# Add routes
if [ ${#ROUTES[@]} -gt 0 ]; then
  for route in "${ROUTES[@]}"; do
    echo "- [ ] $route" >> "$CHECKLIST_FILE"
  done
else
  echo "- [ ] No UI routes found (backend-only feature)" >> "$CHECKLIST_FILE"
fi

cat >> "$CHECKLIST_FILE" <<EOF

---

## User Scenarios

EOF

# Add scenarios
if [ "$SCENARIO_COUNT" -gt 0 ]; then
  SCENARIO_NUM=1
  while IFS= read -r scenario; do
    if [ -n "$scenario" ]; then
      cat >> "$CHECKLIST_FILE" <<SCENARIO

### Scenario $SCENARIO_NUM

- [ ] **Test**: $scenario
- [ ] **Result**: [Pass/Fail]
- [ ] **Notes**: [Any issues or observations]

SCENARIO
      ((SCENARIO_NUM++))
    fi
  done <<< "$SCENARIOS"
else
  echo "- [ ] No scenarios defined in spec.md" >> "$CHECKLIST_FILE"
fi

cat >> "$CHECKLIST_FILE" <<EOF

---

## Acceptance Criteria

EOF

# Add criteria
if [ "$CRITERIA_COUNT" -gt 0 ]; then
  while IFS= read -r criterion; do
    if [ -n "$criterion" ]; then
      echo "- [ ] $criterion" >> "$CHECKLIST_FILE"
    fi
  done <<< "$CRITERIA"
else
  echo "- [ ] No criteria defined in spec.md" >> "$CHECKLIST_FILE"
fi

cat >> "$CHECKLIST_FILE" <<EOF

---

## Visual Validation

EOF

# Add visual requirements
if [ "$HAS_VISUAL_SPECS" = true ] && [ -n "$VISUAL_REQUIREMENTS" ]; then
  echo "$VISUAL_REQUIREMENTS" | sed 's/^/- [ ] /' >> "$CHECKLIST_FILE"
else
  cat >> "$CHECKLIST_FILE" <<EOF
- [ ] Layout is clean and professional
- [ ] Colors match brand guidelines
- [ ] Typography is readable (font families, sizes, weights)
- [ ] Spacing is consistent
- [ ] Interactive elements have clear affordances (buttons, links, inputs)
- [ ] Responsive design works (mobile, tablet, desktop)
EOF
fi

cat >> "$CHECKLIST_FILE" <<EOF

---

## Browser Testing

- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile Safari (iOS)
- [ ] Chrome Mobile (Android)

**Testing device**: [Device name/OS]

---

## Accessibility

- [ ] Keyboard navigation (Tab, Shift+Tab, Enter, Esc)
- [ ] Screen reader (NVDA/VoiceOver/JAWS)
- [ ] Focus indicators visible
- [ ] Color contrast sufficient (4.5:1 normal, 3:1 large)
- [ ] Touch targets ≥44px
- [ ] ARIA labels present and correct

**Screen reader tested**: [Name/None]

---

## Performance

- [ ] No console errors
- [ ] No console warnings
- [ ] Initial load feels fast (<3s perceived)
- [ ] Interactions feel smooth (no janks)
- [ ] Images load properly (no 404s)
- [ ] API calls complete reasonably (<5s)

---

## Issues Found

*Document any issues below with format:*

### Issue 1: [Title]
- **Severity**: Critical | High | Medium | Low
- **Location**: [URL or component]
- **Description**: [What's wrong]
- **Expected**: [What should happen]
- **Actual**: [What actually happens]
- **Browser**: [Affected browsers]

---

## Test Results Summary

**Total scenarios tested**: ___ / $SCENARIO_COUNT
**Total criteria validated**: ___ / $CRITERIA_COUNT
**Browsers tested**: ___ / 6
**Issues found**: ___

**Overall status**: ✅ Ready to ship | ⚠️ Minor issues | ❌ Blocking issues

**Tester signature**: _______________
**Date**: _______________

EOF

echo "✅ Checklist generated: $CHECKLIST_FILE"
echo ""
```

**Add API-specific checklist items (Non-UI):**

```bash
if $API_MODE; then
  echo "" >> "$CHECKLIST_FILE"
  echo "---" >> "$CHECKLIST_FILE"
  echo "" >> "$CHECKLIST_FILE"
  echo "## API Preview" >> "$CHECKLIST_FILE"
  echo "" >> "$CHECKLIST_FILE"

  if [ -n "$OPENAPI_FILE" ]; then
    echo "- [ ] OpenAPI served at /openapi.json or /docs (FastAPI default)" >> "$CHECKLIST_FILE"
    echo "- [ ] Changed endpoints return 2xx with valid schema" >> "$CHECKLIST_FILE"
    echo "- [ ] Error responses include machine-readable codes" >> "$CHECKLIST_FILE"
    echo "- [ ] Auth required endpoints reject anonymous as 401/403" >> "$CHECKLIST_FILE"
    echo "- [ ] Idempotent writes behave correctly (replay safe)" >> "$CHECKLIST_FILE"
  else
    echo "- [ ] Document API changes (no OpenAPI found)" >> "$CHECKLIST_FILE"
  fi

  if $WORKER_MODE; then
    echo "- [ ] Background task enqueues and completes" >> "$CHECKLIST_FILE"
    echo "- [ ] Retry/backoff observed for transient failures" >> "$CHECKLIST_FILE"
  fi

  if $DATA_MODE; then
    echo "- [ ] Migration applies and downgrades cleanly" >> "$CHECKLIST_FILE"
    echo "- [ ] New constraints enforced (insert fails where expected)" >> "$CHECKLIST_FILE"
  fi
fi
```

---

## COMPARE TO POLISHED MOCKUP

**If polished mockup exists, add comparison section:**

```bash
if [ -d "apps/web/mock/$SLUG" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Design Comparison"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Polished mockups found in apps/web/mock/$SLUG"
  echo ""

  # List polished screens
  POLISHED_SCREENS=$(find apps/web/mock/$SLUG -path "*/polished/page.tsx" 2>/dev/null | \
                     sed 's|.*/\([^/]*\)/polished/.*|\1|' | \
                     sort -u)

  if [ -n "$POLISHED_SCREENS" ]; then
    # Add comparison section to checklist
    cat >> "$CHECKLIST_FILE" <<EOF

---

## Design Comparison (Mockup vs Production)

*Compare production implementation to polished mockup*

EOF

    while IFS= read -r screen; do
      if [ -n "$screen" ]; then
        MOCKUP_URL="http://localhost:3002/mock/$SLUG/$screen/polished"
        PROD_URL=$(printf '%s\n' "${ROUTES[@]}" | grep "/$screen" | head -1)

        if [ -z "$PROD_URL" ]; then
          # Try to find production URL by screen name
          PROD_URL=$(printf '%s\n' "${ROUTES[@]}" | head -1)
        fi

        cat >> "$CHECKLIST_FILE" <<COMP

### Screen: $screen

**Mockup**: $MOCKUP_URL
**Production**: ${PROD_URL:-[Not found]}

- [ ] Layout matches (spacing, alignment, grid)
- [ ] Colors match design tokens (no hardcoded colors)
- [ ] Typography matches (family, size, weight, line-height)
- [ ] Components match (buttons, inputs, cards, etc.)
- [ ] Interactions match (hover, focus, active states)
- [ ] Transitions/animations match

**Differences noted**: [List any intentional or unintentional differences]

COMP
      fi
    done <<< "$POLISHED_SCREENS"

    echo "Added mockup comparison to checklist"
    echo ""
    echo "Remember to start mock server:"
    echo "  cd apps/web && pnpm dev  # Port 3002"
    echo ""
  fi
fi
```

---

## OPENAPI CONTRACT DIFF

**Compare current spec against baseline:**

```bash
if $API_MODE && [ -n "$OPENAPI_FILE" ]; then
  echo "Contract diff against baseline (if present)..."
  BASELINE="api/openapi-baseline.json"
  DIFF_OUT="$FEATURE_DIR/openapi-diff.txt"

  if [ -f "$BASELINE" ]; then
    if command -v openapi-diff >/dev/null 2>&1; then
      openapi-diff "$BASELINE" "$OPENAPI_FILE" > "$DIFF_OUT" 2>&1 || true
    elif command -v oasdiff >/dev/null 2>&1; then
      oasdiff breaking "$BASELINE" "$OPENAPI_FILE" > "$DIFF_OUT" 2>&1 || true
    else
      echo "openapi-diff/oasdiff not installed; skipping diff." > "$DIFF_OUT"
    fi
    echo "✅ Contract diff written: $DIFF_OUT"
  else
    echo "No baseline spec at $BASELINE; skipping diff."
  fi
fi
```

---

## API SMOKE / PROPERTY TESTS

**Run schema-driven API tests:**

```bash
if $API_MODE; then
  echo "Running API smoke tests..."

  # Schemathesis (property-based tests from OpenAPI)
  if [ -n "$OPENAPI_FILE" ] && command -v schemathesis >/dev/null 2>&1; then
    SCHEMA_URL="http://localhost:8000/openapi.json"
    [ -f "$OPENAPI_FILE" ] && SCHEMA_URL="$OPENAPI_FILE"
    schemathesis run "$SCHEMA_URL" --checks all --stateful=links \
      --hypothesis-deadline=500 \
      --hypothesis-max-examples=30 \
      --report "$FEATURE_DIR/schemathesis-report.json" || true
    echo "✅ Schemathesis report: $FEATURE_DIR/schemathesis-report.json"
  fi

  # Postman collection (if present)
  if [ -f "api/tests/postman/collection.json" ] && command -v newman >/dev/null 2>&1; then
    newman run api/tests/postman/collection.json \
      --env-var baseUrl=http://localhost:8000 \
      --reporters cli,json \
      --reporter-json-export "$FEATURE_DIR/newman-report.json" || true
    echo "✅ Newman report: $FEATURE_DIR/newman-report.json"
  fi
fi
```

---

## DB MIGRATION SAFETY + WORKER DRY-RUN

**Validate migrations and background jobs:**

```bash
if $DATA_MODE && [ -f "api/alembic.ini" ]; then
  echo "Validating migrations..."
  cd api

  # Install deps silently if needed
  uv pip install -q alembic >/dev/null 2>&1 || true

  set +e
  uv run alembic upgrade head > /tmp/alembic-up.log 2>&1
  UP_RC=$?
  uv run alembic downgrade -1 > /tmp/alembic-down.log 2>&1
  DN_RC=$?
  set -e
  cd ..

  if [ $UP_RC -ne 0 ] || [ $DN_RC -ne 0 ]; then
    echo "❌ Migration apply/downgrade failed. See /tmp/alembic-*.log"
    echo "- [ ] Migration failed during preview" >> "$CHECKLIST_FILE"
  else
    echo "✅ Migration upgrade/downgrade cycle OK"
    echo "- [ ] Migration reversible" >> "$CHECKLIST_FILE"
  fi
fi

if $WORKER_MODE; then
  echo "Dry-running background job..."
  # Optional: fire a test endpoint or Celery ping if available
  if curl -sf http://localhost:8000/api/v1/health/workerz >/dev/null 2>&1; then
    echo "✅ Worker health endpoint OK"
  else
    echo "ℹ️  No worker health endpoint; skipping"
  fi
fi
```

---

## API PERFORMANCE (quick check)

**Lightweight load test with k6:**

```bash
if $API_MODE; then
  echo "API performance quick check..."
  if command -v k6 >/dev/null 2>&1; then
    K6_SCRIPT="$FEATURE_DIR/k6-smoke.js"
    cat > "$K6_SCRIPT" <<'K6'
import http from 'k6/http';
import { sleep } from 'k6';
export const options = { vus: 10, duration: '30s' };
export default function () {
  const res = http.get(`${__ENV.BASE_URL}/api/v1/health/healthz`);
  sleep(0.2);
}
K6
    BASE_URL="http://localhost:8000" k6 run --quiet "$K6_SCRIPT" > "$FEATURE_DIR/k6-output.txt" 2>&1 || true
    echo "✅ k6 output: $FEATURE_DIR/k6-output.txt"
  else
    echo "k6 not installed; skipping perf."
  fi
fi
```

---

## OPTIONAL SECURITY BASELINE (ZAP)

**Quick security scan:**

```bash
if $API_MODE && command -v docker >/dev/null 2>&1; then
  echo "Run ZAP API baseline scan? (y/N)"
  read -r RUN_ZAP
  if [ "$RUN_ZAP" = "y" ]; then
    docker run --rm -t -u zap -v "$PWD:$PWD" -w "$PWD" \
      ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
      -t http://localhost:8000/openapi.json -r "$FEATURE_DIR/zap-baseline.html" || true
    echo "✅ ZAP baseline: $FEATURE_DIR/zap-baseline.html"
  fi
fi
```

---

## START DEV SERVERS

**Launch dev servers for affected apps:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Starting Dev Servers"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Kill existing processes on ports
echo "Killing existing processes on ports 3000, 3001, 3002..."
npx kill-port 3000 3001 3002 2>/dev/null || true
sleep 2

SERVER_PIDS=()

# Start marketing if affected
if printf '%s\n' "${AFFECTED_APPS[@]}" | grep -q "marketing"; then
  echo "Starting marketing (port 3000)..."
  cd apps/marketing
  pnpm install --silent > /dev/null 2>&1 || true
  pnpm dev > /tmp/marketing-dev.log 2>&1 &
  MARKETING_PID=$!
  SERVER_PIDS+=($MARKETING_PID)
  cd ../..
  echo "  PID: $MARKETING_PID"
fi

# Start app if affected
if printf '%s\n' "${AFFECTED_APPS[@]}" | grep -q "app"; then
  echo "Starting app (port 3001)..."
  cd apps/app
  pnpm install --silent > /dev/null 2>&1 || true
  pnpm dev > /tmp/app-dev.log 2>&1 &
  APP_PID=$!
  SERVER_PIDS+=($APP_PID)
  cd ../..
  echo "  PID: $APP_PID"
fi

# Start mock server if polished mockups exist
if [ -d "apps/web/mock/$SLUG" ]; then
  echo "Starting mock server (port 3002)..."
  cd apps/web
  pnpm install --silent > /dev/null 2>&1 || true
  pnpm dev > /tmp/web-dev.log 2>&1 &
  WEB_PID=$!
  SERVER_PIDS+=($WEB_PID)
  cd ../..
  echo "  PID: $WEB_PID"
fi

echo ""
echo "Waiting for servers to start..."
sleep 15

# Verify servers are running
SERVERS_READY=true

if printf '%s\n' "${AFFECTED_APPS[@]}" | grep -q "marketing"; then
  if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200\|301\|302"; then
    echo "✅ Marketing ready: http://localhost:3000"
  else
    echo "❌ Marketing not responding"
    echo "   Check logs: tail -f /tmp/marketing-dev.log"
    SERVERS_READY=false
  fi
fi

if printf '%s\n' "${AFFECTED_APPS[@]}" | grep -q "app"; then
  if curl -s -o /dev/null -w "%{http_code}" http://localhost:3001 | grep -q "200\|301\|302"; then
    echo "✅ App ready: http://localhost:3001"
  else
    echo "❌ App not responding"
    echo "   Check logs: tail -f /tmp/app-dev.log"
    SERVERS_READY=false
  fi
fi

if [ -d "apps/web/mock/$SLUG" ]; then
  if curl -s -o /dev/null -w "%{http_code}" http://localhost:3002 | grep -q "200\|301\|302"; then
    echo "✅ Mock server ready: http://localhost:3002"
  else
    echo "⚠️  Mock server not responding (optional)"
    echo "   Check logs: tail -f /tmp/web-dev.log"
  fi
fi

echo ""

if [ "$SERVERS_READY" = false ]; then
  echo "❌ Dev servers failed to start"
  echo ""
  echo "Troubleshooting:"
  echo "  1. Check logs in /tmp/"
  echo "  2. Run 'pnpm install' in affected apps"
  echo "  3. Check for port conflicts: lsof -i :3000,3001,3002"
  echo "  4. Check for build errors in logs"
  exit 1
fi

# Save PIDs for cleanup
echo "${SERVER_PIDS[@]}" > /tmp/preview-server-pids.txt

echo "Dev servers running"
echo "  Stop: kill \$(cat /tmp/preview-server-pids.txt)"
echo ""
```

---

## START BACKEND & WORKERS (Non-UI)

**Launch API server and background workers:**

```bash
if $API_MODE || $DATA_MODE || $WORKER_MODE; then
  echo "Starting backend services..."
  npx kill-port 8000 8010 2>/dev/null || true
  sleep 1

  BACKEND_PIDS=()

  # Start FastAPI dev server if app exists
  if [ -d "api/app" ]; then
    echo "Starting FastAPI (port 8000)..."
    cd api
    uv run uvicorn app.main:app --reload --port 8000 > /tmp/api-dev.log 2>&1 &
    API_PID=$!
    BACKEND_PIDS+=($API_PID)
    cd ..
    echo "  PID: $API_PID"
    sleep 3
    if ! curl -sf http://localhost:8000/api/v1/health/healthz >/dev/null 2>&1; then
      echo "⚠️  API health probe failed. Check /tmp/api-dev.log"
    else
      echo "✅ API responding at http://localhost:8000"
    fi
  fi

  # Start Celery worker if Celery app exists
  if $WORKER_MODE && grep -q "celery" api/app/** 2>/dev/null; then
    echo "Starting Celery worker..."
    cd api
    # Try typical entrypoint names; adjust if your app differs
    (uv run celery -A app.worker worker -l info > /tmp/celery-worker.log 2>&1 &)
    CELERY_PID=$!
    BACKEND_PIDS+=($CELERY_PID)
    cd ..
    echo "  PID: $CELERY_PID"
  fi

  # Save PIDs for cleanup
  if [ ${#BACKEND_PIDS[@]} -gt 0 ]; then
    echo "${BACKEND_PIDS[@]}" >> /tmp/preview-server-pids.txt
  fi

  echo ""
fi
```

---

## INTERACTIVE TESTING SESSION

**Open checklist and guide user through testing:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Manual Testing Session"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Checklist: $CHECKLIST_FILE"
echo ""
echo "Routes to test:"
for route in "${ROUTES[@]}"; do
  echo "  🌐 $route"
done
echo ""

# Open checklist in editor
echo "Opening checklist..."
if command -v code &> /dev/null; then
  code "$CHECKLIST_FILE"
elif command -v vim &> /dev/null; then
  vim "$CHECKLIST_FILE"
elif command -v nano &> /dev/null; then
  nano "$CHECKLIST_FILE"
else
  echo "No editor found. Edit manually: $CHECKLIST_FILE"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Instructions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Open routes in browser"
echo "2. Test each scenario in checklist"
echo "3. Check all browsers listed"
echo "4. Document issues in checklist"
echo "5. Check off completed items (- [x])"
echo "6. Return here when done"
echo ""
echo "Press Enter when testing is complete..."
read

echo ""
```

---

## MOBILE TESTING GUIDANCE

**Provide mobile testing options:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Mobile Testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Test on mobile devices? (y/N)"
read -p "> " TEST_MOBILE

if [ "$TEST_MOBILE" = "y" ]; then
  echo ""
  echo "Mobile testing options:"
  echo ""
  echo "1. Physical device (recommended)"
  echo "   - Connect device to same network as dev machine"
  echo "   - Get local IP: ipconfig getifaddr en0 (Mac) or hostname -I (Linux)"
  echo "   - Open: http://[LOCAL_IP]:3000 on mobile browser"
  echo ""
  echo "2. Chrome DevTools device emulation"
  echo "   - Open DevTools (F12)"
  echo "   - Toggle device toolbar (Cmd+Shift+M / Ctrl+Shift+M)"
  echo "   - Select device from dropdown"
  echo ""
  echo "3. Playwright mobile emulation"
  echo "   - Use 'iPhone 13' or 'Pixel 5' device config"
  echo "   - Run tests with: pnpm exec playwright test --project=mobile"
  echo ""

  # Get local IP for convenience
  LOCAL_IP=""
  if command -v ipconfig &> /dev/null; then
    LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "")
  elif command -v hostname &> /dev/null; then
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
  fi

  if [ -n "$LOCAL_IP" ]; then
    echo "Your local IP: $LOCAL_IP"
    echo ""
    echo "Mobile URLs:"
    for route in "${ROUTES[@]}"; do
      MOBILE_URL=$(echo "$route" | sed "s|localhost|$LOCAL_IP|")
      echo "  📱 $MOBILE_URL"
    done
    echo ""
  fi

  echo "Press Enter after mobile testing..."
  read
fi

echo ""
```

---

## ACCESSIBILITY TESTING

**Run automated accessibility checks:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Accessibility Testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Run axe-core accessibility scan? (y/N)"
read -p "> " RUN_AXE

if [ "$RUN_AXE" = "y" ]; then
  echo ""
  echo "Installing @axe-core/cli..."
  if ! command -v axe &> /dev/null; then
    npm install -g @axe-core/cli 2>/dev/null || echo "Install failed, skipping axe tests"
  fi

  if command -v axe &> /dev/null; then
    echo ""
    echo "Running axe on routes..."
    echo ""

    for route in "${ROUTES[@]}"; do
      ROUTE_NAME=$(echo "$route" | sed 's|http://localhost:[0-9]*/||' | sed 's|/|_|g' | sed 's|^_||')
      if [ -z "$ROUTE_NAME" ]; then
        ROUTE_NAME="index"
      fi

      echo "Scanning: $route"

      axe "$route" \
        --save "$FEATURE_DIR/axe-$ROUTE_NAME.json" \
        --tags wcag2a,wcag2aa \
        --exit 2>/dev/null || true

      # Parse violations
      if [ -f "$FEATURE_DIR/axe-$ROUTE_NAME.json" ]; then
        VIOLATIONS=$(jq '.violations | length' "$FEATURE_DIR/axe-$ROUTE_NAME.json" 2>/dev/null || echo 0)
        CRITICAL=$(jq '[.violations[] | select(.impact=="critical")] | length' "$FEATURE_DIR/axe-$ROUTE_NAME.json" 2>/dev/null || echo 0)
        SERIOUS=$(jq '[.violations[] | select(.impact=="serious")] | length' "$FEATURE_DIR/axe-$ROUTE_NAME.json" 2>/dev/null || echo 0)

        echo "  Violations: $VIOLATIONS (Critical: $CRITICAL, Serious: $SERIOUS)"

        if [ "$CRITICAL" -gt 0 ] || [ "$SERIOUS" -gt 0 ]; then
          echo "  ⚠️  Review axe-$ROUTE_NAME.json for details"
        fi
      else
        echo "  ⚠️  Scan failed or no file created"
      fi

      echo ""
    done

    echo "✅ Accessibility scan complete"
    echo "   Reports: $FEATURE_DIR/axe-*.json"
    echo ""
  fi
fi
```

---

## PERFORMANCE VALIDATION

**Measure actual performance metrics:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Performance Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Run Lighthouse on preview? (y/N)"
read -p "> " RUN_LIGHTHOUSE

if [ "$RUN_LIGHTHOUSE" = "y" ]; then
  echo ""
  echo "Running Lighthouse on preview routes..."
  echo ""

  # Check if lighthouse is installed
  if ! command -v lighthouse &> /dev/null; then
    echo "Installing lighthouse..."
    npm install -g lighthouse 2>/dev/null || echo "Install failed, skipping lighthouse"
  fi

  if command -v lighthouse &> /dev/null; then
    for route in "${ROUTES[@]}"; do
      ROUTE_NAME=$(echo "$route" | sed 's|http://localhost:[0-9]*/||' | sed 's|/|_|g' | sed 's|^_||')
      if [ -z "$ROUTE_NAME" ]; then
        ROUTE_NAME="index"
      fi

      echo "Testing: $route"

      lighthouse "$route" \
        --output=json \
        --output-path="$FEATURE_DIR/lighthouse-preview-$ROUTE_NAME.json" \
        --only-categories=performance,accessibility,best-practices \
        --preset=desktop \
        --quiet \
        --chrome-flags="--headless" 2>/dev/null || true

      # Parse scores
      if [ -f "$FEATURE_DIR/lighthouse-preview-$ROUTE_NAME.json" ]; then
        PERF=$(jq '.categories.performance.score * 100' "$FEATURE_DIR/lighthouse-preview-$ROUTE_NAME.json" 2>/dev/null || echo 0)
        A11Y=$(jq '.categories.accessibility.score * 100' "$FEATURE_DIR/lighthouse-preview-$ROUTE_NAME.json" 2>/dev/null || echo 0)
        BP=$(jq '.categories["best-practices"].score * 100' "$FEATURE_DIR/lighthouse-preview-$ROUTE_NAME.json" 2>/dev/null || echo 0)

        echo "  Performance: $PERF / 100"
        echo "  A11y: $A11Y / 100"
        echo "  Best Practices: $BP / 100"
        echo ""

        # Add to checklist
        cat >> "$CHECKLIST_FILE" <<EOF

### Lighthouse: $ROUTE_NAME
- Performance: $PERF / 100 $(awk "BEGIN {print ($PERF >= 90) ? \"✅\" : \"⚠️\"}")
- Accessibility: $A11Y / 100 $(awk "BEGIN {print ($A11Y >= 95) ? \"✅\" : \"⚠️\"}")
- Best Practices: $BP / 100 $(awk "BEGIN {print ($BP >= 90) ? \"✅\" : \"⚠️\"}")

EOF
      else
        echo "  ⚠️  Lighthouse scan failed"
        echo ""
      fi
    done

    echo "✅ Lighthouse reports saved"
    echo ""
  fi
fi
```

---

## OPTIONAL: PLAYWRIGHT VISUAL TESTING

**Offer automated visual regression:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Automated Visual Testing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Run Playwright visual regression tests? (y/N)"
read -p "> " RUN_VISUAL_TESTS

if [ "$RUN_VISUAL_TESTS" = "y" ]; then
  echo ""
  echo "Starting Playwright UI mode..."
  echo ""
  echo "Use Playwright UI to:"
  echo "  1. Record new test scenarios"
  echo "  2. Update visual snapshots"
  echo "  3. Debug failing tests"
  echo ""

  # Determine which app to test
  if printf '%s\n' "${AFFECTED_APPS[@]}" | grep -q "app"; then
    cd apps/app
  elif printf '%s\n' "${AFFECTED_APPS[@]}" | grep -q "marketing"; then
    cd apps/marketing
  else
    echo "No app found, skipping"
    cd .
  fi

  if [ -f "package.json" ]; then
    # Launch Playwright UI
    pnpm exec playwright test --ui || true
    cd ../..
  fi

  echo ""
  echo "✅ Playwright testing complete"
  echo ""
fi
```

---

## SCREENSHOT CAPTURE

**Offer to capture screenshots of issues:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Screenshot Capture"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Capture screenshots? (y/N)"
read -p "> " CAPTURE_SCREENSHOTS

if [ "$CAPTURE_SCREENSHOTS" = "y" ]; then
  # Create screenshots directory
  SCREENSHOTS_DIR="$FEATURE_DIR/preview-screenshots"
  mkdir -p "$SCREENSHOTS_DIR"

  echo ""
  echo "Screenshot directory: $SCREENSHOTS_DIR"
  echo ""
  echo "Options for capturing:"
  echo "  1. Playwright screenshots (automated)"
  echo "  2. Manual (take screenshots, save to directory)"
  echo ""
  read -p "Choose (1/2): " SCREENSHOT_METHOD

  if [ "$SCREENSHOT_METHOD" = "1" ]; then
    echo ""
    echo "Starting Playwright for screenshot capture..."
    echo ""

    # Generate Playwright script to capture routes
    cat > /tmp/capture-screenshots-$SLUG.spec.ts <<EOF
import { test } from '@playwright/test';

EOF

    ROUTE_NUM=1
    for route in "${ROUTES[@]}"; do
      ROUTE_NAME=$(echo "$route" | sed 's|http://localhost:[0-9]*/||' | sed 's|/|_|g' | sed 's|^_||')
      if [ -z "$ROUTE_NAME" ]; then
        ROUTE_NAME="index"
      fi

      cat >> /tmp/capture-screenshots-$SLUG.spec.ts <<EOF
test('capture $ROUTE_NAME', async ({ page }) => {
  await page.goto('$route');
  await page.waitForLoadState('networkidle');
  await page.screenshot({ path: '$SCREENSHOTS_DIR/${ROUTE_NUM}_${ROUTE_NAME}.png', fullPage: true });
});

EOF
      ((ROUTE_NUM++))
    done

    # Run Playwright to capture
    if printf '%s\n' "${AFFECTED_APPS[@]}" | grep -q "app"; then
      cd apps/app
      pnpm exec playwright test /tmp/capture-screenshots-$SLUG.spec.ts --headed || true
      cd ../..
    elif printf '%s\n' "${AFFECTED_APPS[@]}" | grep -q "marketing"; then
      cd apps/marketing
      pnpm exec playwright test /tmp/capture-screenshots-$SLUG.spec.ts --headed || true
      cd ../..
    fi

    echo "✅ Screenshots saved to $SCREENSHOTS_DIR"

  else
    echo ""
    echo "Manual screenshot capture:"
    echo "  1. Take screenshots of issues"
    echo "  2. Save to: $SCREENSHOTS_DIR"
    echo "  3. Name files descriptively (e.g., issue-1-button-misaligned.png)"
    echo ""
    echo "Press Enter when done..."
    read
  fi

  # Reference screenshots in checklist
  SCREENSHOT_COUNT=$(find "$SCREENSHOTS_DIR" -name "*.png" 2>/dev/null | wc -l)
  if [ "$SCREENSHOT_COUNT" -gt 0 ]; then
    cat >> "$CHECKLIST_FILE" <<EOF

---

## Screenshots

EOF

    find "$SCREENSHOTS_DIR" -name "*.png" 2>/dev/null | sort | while read screenshot; do
      SCREENSHOT_BASENAME=$(basename "$screenshot")
      echo "- ![](./$SCREENSHOTS_DIR/$SCREENSHOT_BASENAME)" >> "$CHECKLIST_FILE"
    done

    echo "✅ $SCREENSHOT_COUNT screenshots referenced in checklist"
  fi

  echo ""
fi
```

---

## PARSE TEST RESULTS

**Analyze checklist completion:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Parse checklist for results
TOTAL_CHECKS=$(grep -c "^- \[ \]" "$CHECKLIST_FILE" 2>/dev/null || echo 0)
COMPLETED_CHECKS=$(grep -c "^- \[x\]" "$CHECKLIST_FILE" 2>/dev/null || echo 0)
ISSUES_FOUND=$(grep -c "^### Issue" "$CHECKLIST_FILE" 2>/dev/null || echo 0)

echo "Checklist progress: $COMPLETED_CHECKS / $TOTAL_CHECKS items checked"
echo "Issues documented: $ISSUES_FOUND"
echo ""

PREVIEW_STATUS="unknown"

if [ "$ISSUES_FOUND" -gt 0 ]; then
  echo "⚠️  Issues found"
  echo ""
  echo "Options:"
  echo "  A) Fix now with /debug"
  echo "  B) Document and ship (minor issues only)"
  echo "  C) Cancel preview"
  echo ""
  read -p "Choose (A/B/C): " OPTION

  case "$OPTION" in
    A|a)
      echo "Stopping dev servers..."
      cleanup
      echo ""
      echo "Next: /debug to fix issues"
      echo "      Then re-run /preview to verify"
      exit 0
      ;;
    B|b)
      echo "Documenting issues and proceeding..."
      PREVIEW_STATUS="issues_documented"
      ;;
    C|c)
      echo "Preview cancelled"
      exit 0
      ;;
    *)
      echo "Invalid choice, defaulting to cancel"
      exit 0
      ;;
  esac
elif [ "$COMPLETED_CHECKS" -lt "$TOTAL_CHECKS" ]; then
  echo "⚠️  Testing incomplete ($COMPLETED_CHECKS / $TOTAL_CHECKS)"
  echo ""
  read -p "Proceed anyway? (y/N): " PROCEED
  if [ "$PROCEED" != "y" ]; then
    echo "Preview incomplete"
    exit 0
  fi
  PREVIEW_STATUS="incomplete"
else
  echo "✅ All tests passed!"
  echo ""
  PREVIEW_STATUS="passed"
fi

echo ""
```

---

## UPDATE NOTES.MD

**Record preview results:**

```bash
echo "Updating NOTES.md..."

# Source the template
source \spec-flow/templates/notes-update-template.sh

TESTED_BROWSERS=$(grep -A 6 "## Browser Testing" "$CHECKLIST_FILE" | grep "\[x\]" | wc -l || echo 0)
CHECKLIST_TOKENS=$(cat "$CHECKLIST_FILE" | wc -w)

# Add Phase 6 checkpoint
update_notes_checkpoint "$FEATURE_DIR" "6" "Preview" \
  "Manual testing: $PREVIEW_STATUS" \
  "Scenarios tested: $COMPLETED_CHECKS / $TOTAL_CHECKS" \
  "Issues found: $ISSUES_FOUND" \
  "Browser coverage: $TESTED_BROWSERS / 6" \
  "Routes tested: ${#ROUTES[@]}"

# Add context budget tracking
update_notes_context_budget "$FEATURE_DIR" "6" "$CHECKLIST_TOKENS" "checklist"

# Include Non-UI artifacts in NOTES
if $API_MODE || $DATA_MODE || $WORKER_MODE; then
  EXTRA_ARTIFACTS=""
  [ -f "$FEATURE_DIR/openapi-diff.txt" ] && EXTRA_ARTIFACTS="$EXTRA_ARTIFACTS\n- openapi-diff.txt"
  ls "$FEATURE_DIR"/schemathesis-report.json >/dev/null 2>&1 && EXTRA_ARTIFACTS="$EXTRA_ARTIFACTS\n- schemathesis-report.json"
  ls "$FEATURE_DIR"/newman-report.json >/dev/null 2>&1 && EXTRA_ARTIFACTS="$EXTRA_ARTIFACTS\n- newman-report.json"
  ls "$FEATURE_DIR"/k6-output.txt >/dev/null 2>&1 && EXTRA_ARTIFACTS="$EXTRA_ARTIFACTS\n- k6-output.txt"

  update_notes_checkpoint "$FEATURE_DIR" "6A" "Preview (Non-UI)" \
    "API mode: $API_MODE, Data/Infra: $DATA_MODE, Workers: $WORKER_MODE" \
    "Artifacts: $(echo -e "$EXTRA_ARTIFACTS")" \
    "OpenAPI: $OPENAPI_FILE" \
    "Baseline: $( [ -f api/openapi-baseline.json ] && echo yes || echo no )" \
    "k6: $( [ -f "$FEATURE_DIR/k6-output.txt" ] && echo yes || echo no )"
fi

update_notes_timestamp "$FEATURE_DIR"

echo "✅ NOTES.md updated"
echo ""
```

---

## GIT COMMIT

**Commit preview results:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Committing Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Add all preview artifacts
git add "$FEATURE_DIR/NOTES.md" "$FEATURE_DIR/preview-checklist.md"

# Add screenshots if any
if [ -d "$FEATURE_DIR/preview-screenshots" ]; then
  git add "$FEATURE_DIR/preview-screenshots/"
fi

# Add lighthouse reports if any
if ls "$FEATURE_DIR"/lighthouse-preview-*.json 1> /dev/null 2>&1; then
  git add "$FEATURE_DIR"/lighthouse-preview-*.json
fi

# Add axe reports if any
if ls "$FEATURE_DIR"/axe-*.json 1> /dev/null 2>&1; then
  git add "$FEATURE_DIR"/axe-*.json
fi

# Add backend/API artifacts if any
if [ -f "$FEATURE_DIR/openapi-diff.txt" ]; then
  git add "$FEATURE_DIR/openapi-diff.txt"
fi
if [ -f "$FEATURE_DIR/schemathesis-report.json" ]; then
  git add "$FEATURE_DIR/schemathesis-report.json"
fi
if [ -f "$FEATURE_DIR/newman-report.json" ]; then
  git add "$FEATURE_DIR/newman-report.json"
fi
if [ -f "$FEATURE_DIR/k6-output.txt" ]; then
  git add "$FEATURE_DIR/k6-output.txt"
fi
if [ -f "$FEATURE_DIR/zap-baseline.html" ]; then
  git add "$FEATURE_DIR/zap-baseline.html"
fi

# Create commit
COMMIT_MSG="design:preview: manual UI/UX testing complete

Feature: $SLUG
Status: $PREVIEW_STATUS
Scenarios tested: $COMPLETED_CHECKS / $TOTAL_CHECKS
Issues found: $ISSUES_FOUND
Browser coverage: $TESTED_BROWSERS / 6

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git commit -m "$COMMIT_MSG"

# Verify commit succeeded
COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""
echo "✅ Preview results committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""
```

---

## SUGGEST NEXT STEP

**Based on preview results:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Next Steps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$PREVIEW_STATUS" = "passed" ]; then
  echo "✅ Preview passed! Ready to ship to staging."
  echo ""
  echo "Next: /phase-1-ship"
  echo ""
  echo "This will:"
  echo "  1. Create pull request"
  echo "  2. Enable auto-merge"
  echo "  3. Wait for CI to pass"
  echo "  4. Auto-merge to main"
  echo "  5. Deploy to staging environment"

elif [ "$PREVIEW_STATUS" = "issues_documented" ]; then
  echo "⚠️  Issues found but proceeding"
  echo ""
  echo "Options:"
  echo "  1. /debug - Fix issues first (recommended for critical issues)"
  echo "  2. /phase-1-ship - Ship with known issues (minor issues only)"
  echo ""
  echo "Documented issues:"
  grep "^### Issue" "$CHECKLIST_FILE" | head -5

elif [ "$PREVIEW_STATUS" = "incomplete" ]; then
  echo "⚠️  Testing incomplete"
  echo ""
  echo "Options:"
  echo "  1. Re-run /preview - Complete testing"
  echo "  2. /phase-1-ship - Ship anyway (not recommended)"

else
  echo "❓ Preview status unclear"
  echo ""
  echo "Check: $CHECKLIST_FILE"
fi

echo ""
```

---

## RETURN

**Final summary:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Preview Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Feature: $SLUG"
echo "Status: $PREVIEW_STATUS"
echo ""
echo "Testing results:"
echo "  Scenarios tested: $COMPLETED_CHECKS / $TOTAL_CHECKS"
echo "  Issues found: $ISSUES_FOUND"
echo "  Browser coverage: $TESTED_BROWSERS / 6"
echo "  Routes tested: ${#ROUTES[@]}"
echo ""
echo "Artifacts:"
echo "  Checklist: $CHECKLIST_FILE"
if [ -d "$FEATURE_DIR/preview-screenshots" ]; then
  SCREENSHOT_COUNT=$(find "$FEATURE_DIR/preview-screenshots" -name "*.png" 2>/dev/null | wc -l)
  echo "  Screenshots: $SCREENSHOT_COUNT"
fi
if ls "$FEATURE_DIR"/lighthouse-preview-*.json 1> /dev/null 2>&1; then
  LIGHTHOUSE_COUNT=$(ls "$FEATURE_DIR"/lighthouse-preview-*.json 2>/dev/null | wc -l)
  echo "  Lighthouse reports: $LIGHTHOUSE_COUNT"
fi
if ls "$FEATURE_DIR"/axe-*.json 1> /dev/null 2>&1; then
  AXE_COUNT=$(ls "$FEATURE_DIR"/axe-*.json 2>/dev/null | wc -l)
  echo "  Axe reports: $AXE_COUNT"
fi

# Backend/API artifacts
if [ -f "$FEATURE_DIR/openapi-diff.txt" ]; then
  echo "  OpenAPI diff: Yes"
fi
if [ -f "$FEATURE_DIR/schemathesis-report.json" ]; then
  echo "  Schemathesis report: Yes"
fi
if [ -f "$FEATURE_DIR/newman-report.json" ]; then
  echo "  Newman report: Yes"
fi
if [ -f "$FEATURE_DIR/k6-output.txt" ]; then
  echo "  k6 performance: Yes"
fi
if [ -f "$FEATURE_DIR/zap-baseline.html" ]; then
  echo "  ZAP security scan: Yes"
fi

echo ""
```

