---
description: Production readiness validation (performance, security, a11y, code review)
---

Validate production readiness for feature.

<context>
## PROGRESS TRACKING

**IMPORTANT**: Use the TodoWrite tool to track optimization phases throughout this command.

**At start** - Create todo list for all validation phases:

```javascript
TodoWrite({
  todos: [
    {content: "Load optimization targets from plan.md", status: "pending", activeForm: "Loading targets"},
    {content: "Run performance benchmarks", status: "pending", activeForm: "Running performance benchmarks"},
    {content: "Run security scan", status: "pending", activeForm: "Running security scan"},
    {content: "Run accessibility audit", status: "pending", activeForm: "Running accessibility audit"},
    {content: "Run code review", status: "pending", activeForm: "Running code review"},
    {content: "Validate bundle sizes", status: "pending", activeForm: "Validating bundle sizes"},
    {content: "Check test coverage", status: "pending", activeForm: "Checking test coverage"},
    {content: "Generate optimization report", status: "pending", activeForm: "Generating report"},
  ]
})
```

**During execution**:
- Mark each phase as `in_progress` when starting
- Mark as `completed` IMMEDIATELY after finishing
- Only ONE phase should be `in_progress` at a time

**Why**: Optimization involves multiple independent validation checks that can take 10-20 minutes total. Users need to see progress.
</context>

<constraints>
## ANTI-HALLUCINATION RULES

**CRITICAL**: Follow these rules to prevent false performance/security findings.

1. **Never report metrics you haven't measured**
   - ❌ BAD: "Performance looks good, probably under 200ms"
   - ✅ GOOD: Run actual benchmarks, report measured values
   - Use tools: `pytest --benchmark`, `lighthouse`, `npm run build -- --stats`

2. **Cite actual test results with file paths**
   - When reporting coverage: "Test coverage is 85% per coverage/index.html"
   - When reporting bundle size: "Main bundle is 245KB per webpack stats"
   - Don't estimate - measure and cite reports

3. **Verify tools exist before running them**
   - Before running `lighthouse`, check if installed: `which lighthouse`
   - Before `pytest --cov`, verify coverage package exists
   - Use Bash tool to check, don't assume tool availability

4. **Quote plan.md performance targets exactly**
   - Don't paraphrase targets - quote them: "plan.md:120 specifies <200ms API response"
   - Compare actual measurements to quoted targets
   - If no target specified, say so - don't invent benchmarks

5. **Never fabricate security vulnerabilities or fixes**
   - Only report vulnerabilities found by actual scans (npm audit, bandit, etc.)
   - Don't say "should add rate limiting" unless spec/plan requires it
   - Cite scan output files when reporting issues

**Why this matters**: False performance claims lead to production issues. Invented security vulnerabilities waste time. Accurate measurements based on actual tool output build confidence in deployments.

## REASONING APPROACH

For complex optimization decisions, show your step-by-step reasoning:

<thinking>
Let me analyze this optimization opportunity:
1. What is the current performance? [Quote actual metrics]
2. What does plan.md target? [Quote performance requirements]
3. What are potential optimizations? [List 2-3 approaches]
4. What are the trade-offs? [Complexity vs gain, maintainability vs performance]
5. What does profiling show? [Cite bottlenecks from actual measurements]
6. Conclusion: [Recommended optimization with justification]
</thinking>

<answer>
[Optimization decision based on reasoning]
</answer>

**When to use structured thinking:**
- Prioritizing performance optimizations (biggest impact first)
- Deciding between multiple optimization approaches
- Evaluating security vs usability trade-offs
- Choosing accessibility improvements
- Assessing code quality vs delivery speed

**Benefits**: Explicit reasoning prevents premature optimization and focuses effort on high-impact changes (30-40% efficiency gain).
</constraints>

<instructions>
## LOAD FEATURE

**Get feature from argument or current branch:**

```bash
if [ -n "$ARGUMENTS" ]; then
  SLUG="$ARGUMENTS"
else
  SLUG=$(git branch --show-current)
fi

FEATURE_DIR="specs/$SLUG"
PLAN_FILE="$FEATURE_DIR/plan.md"
TASKS_FILE="$FEATURE_DIR/tasks.md"
ERROR_LOG="$FEATURE_DIR/error-log.md"
```

**Validate feature exists:**

```bash
if [ ! -d "$FEATURE_DIR" ]; then
  echo "❌ Feature not found: $FEATURE_DIR"
  exit 1
fi
```

**Validate implementation complete:**

```bash
if ! grep -q "✅ Phase 3 (Implementation): Complete" "$FEATURE_DIR/NOTES.md" 2>/dev/null; then
  echo "❌ Implementation not complete"
  echo "Run /implement first"
  exit 1
fi

echo "✅ Feature loaded: $SLUG"
echo "✅ Implementation complete, starting optimization..."
echo ""
```

## LOAD TARGETS

**Read from plan.md:**

```bash
# Extract performance targets
PERF_TARGETS=$(sed -n '/## \[PERFORMANCE TARGETS\]/,/## \[/p' "$PLAN_FILE")

# Extract security requirements
SECURITY=$(sed -n '/## \[SECURITY\]/,/## \[/p' "$PLAN_FILE")

# Extract accessibility level
A11Y_LEVEL=$(echo "$SECURITY" | grep -i "WCAG" | head -1)

echo "Targets loaded from plan.md"
echo "  Performance: $(echo "$PERF_TARGETS" | grep -o "p95.*" | head -1)"
echo "  Security: $(echo "$SECURITY" | grep -o "authentication.*" | head -1)"
echo "  Accessibility: $A11Y_LEVEL"
echo ""
```

## VALIDATE UI IMPLEMENTATION (if UI feature)

**Check if polished designs were implemented:**

```bash
if [ -d "apps/web/mock/$SLUG" ]; then
  echo "Validating UI implementation..."
  echo ""

  # List polished screens
  POLISHED_SCREENS=$(find apps/web/mock/$SLUG -path "*/polished/page.tsx" | \
                     sed 's|.*/\([^/]*\)/polished/.*|\1|' | \
                     sort -u)

  UNIMPLEMENTED=()

  while IFS= read -r screen; do
    # Check if production route exists
    PROD_ROUTE="apps/app/$SLUG/$screen/page.tsx"

    if [ ! -f "$PROD_ROUTE" ]; then
      UNIMPLEMENTED+=("$screen")
      echo "  ❌ $screen: No production route found"
    else
      echo "  ✅ $screen: Implemented at $PROD_ROUTE"

      # Check if route imports from polished mockup (should NOT)
      if grep -q "apps/web/mock" "$PROD_ROUTE"; then
        echo "     ⚠️  Imports from mockup (should be standalone)"
      fi

      # Check if route has real API integration (not mock data)
      if grep -q "console.log.*Mock\|// TODO.*API" "$PROD_ROUTE"; then
        echo "     ⚠️  Contains mock data or TODOs"
      fi
    fi
  done <<< "$POLISHED_SCREENS"

  if [ ${#UNIMPLEMENTED[@]} -gt 0 ]; then
    echo ""
    echo "❌ BLOCKER: ${#UNIMPLEMENTED[@]} screen(s) not implemented"
    echo ""
    echo "Missing production routes:"
    for screen in "${UNIMPLEMENTED[@]}"; do
      echo "  - apps/app/$SLUG/$screen/page.tsx"
    done
    echo ""
    echo "Run /implement to build production routes from polished mockups"
    exit 1
  fi

  echo ""
  echo "✅ All polished screens implemented in production routes"
  echo ""
else
  echo "ℹ️  No polished mockups (backend-only or direct implementation)"
  echo ""
fi
```

## VALIDATE DESIGN SYSTEM COMPLIANCE (if UI feature)

**Check production routes use design tokens:**

```bash
if [ -d "apps/app/$SLUG" ]; then
  echo "Validating design system compliance..."
  echo ""

  PROD_ROUTES=$(find apps/app/$SLUG -name "page.tsx" -o -name "*.tsx")

  VIOLATIONS=()

  while IFS= read -r route; do
    # Check for hardcoded colors
    HARDCODED=$(grep -nE "#[0-9A-Fa-f]{3,8}|rgb\(|rgba\(" "$route" | \
                grep -v "// Design token:" | \
                wc -l)

    if [ "$HARDCODED" -gt 0 ]; then
      VIOLATIONS+=("$route: $HARDCODED hardcoded color(s)")
    fi

    # Check for arbitrary spacing
    ARBITRARY=$(grep -nE "p-\[|m-\[|space-\[|gap-\[" "$route" | wc -l)

    if [ "$ARBITRARY" -gt 0 ]; then
      VIOLATIONS+=("$route: $ARBITRARY arbitrary spacing value(s)")
    fi
  done <<< "$PROD_ROUTES"

  if [ ${#VIOLATIONS[@]} -gt 0 ]; then
    echo "⚠️  Design system violations:"
    for violation in "${VIOLATIONS[@]}"; do
      echo "    - $violation"
    done
    echo ""
    echo "Recommendation: Replace with design tokens"
    echo "  Colors: bg-brand-primary, text-neutral-600"
    echo "  Spacing: p-4, m-6 (system scale)"
    echo ""
  else
    echo "✅ All routes use design tokens"
    echo ""
  fi
fi
```

n# Source timing functions
source .spec-flow/scripts/bash/workflow-state.sh

# Start timing for optimize phase
start_phase_timing "$FEATURE_DIR" "optimize"

## PARALLEL OPTIMIZATION CHECKS

**Launch all optimization checks in parallel for 4-5x speedup:**

```javascript
// IMPORTANT: All 5 checks must be launched in a SINGLE message with multiple Task() calls
// This ensures parallel execution rather than sequential

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Launching Parallel Optimization Checks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Running in parallel:"
echo "  - Performance benchmarks (frontend + backend)"
echo "  - Security scans (dependencies + penetration tests)"
echo "  - Accessibility audits (WCAG + a11y tests)"
echo "  - Senior code review (contracts + quality)"
echo "  - Migration validation (if schema changes)"
echo ""

// Check 1: Performance Benchmarks
Task({
  subagent_type: "general-purpose",
  description: "Performance benchmarks",
  prompt: `Run performance validation for feature at ${FEATURE_DIR}:
n# Start sub-phase timing
source .spec-flow/scripts/bash/workflow-state.sh
start_sub_phase_timing "$FEATURE_DIR" "optimize" "performance"


1. Backend Performance:
   - Run API benchmark tests: cd api && uv run pytest tests/performance/ -v
   - Extract p50, p95, p99 response times
   - Compare against targets in ${PLAN_FILE}
   - Report: ${FEATURE_DIR}/perf-backend.log

2. Frontend Performance (if UI feature):
   - Check if dev server running on port 3000
   - If not running, start: cd apps/app && pnpm dev (background)
   - Run Lighthouse on main routes (if polished designs exist in apps/web/mock/${SLUG})
   - Extract performance and accessibility scores
   - Report: ${FEATURE_DIR}/perf-frontend.log

3. Bundle Size (if UI feature):
   - Run build: cd apps/app && pnpm build
   - Extract bundle size from build output
   - Compare against targets in plan.md
   - Report: ${FEATURE_DIR}/bundle-size.log

Output summary to ${FEATURE_DIR}/optimization-performance.md with:
- Performance metrics (actual vs targets)
n# Complete sub-phase timing
complete_sub_phase_timing "$FEATURE_DIR" "optimize" "performance"
- Issues found (if any)
- Status: PASSED/FAILED
`
})

// Check 2: Security Scans
Task({
  subagent_type: "general-purpose",
  description: "Security scans",
  prompt: `Run security validation for feature at ${FEATURE_DIR}:

1. Backend Security:
   - Dependency scan: cd api && uv run bandit -r app/ -ll
n# Start sub-phase timing
source .spec-flow/scripts/bash/workflow-state.sh
start_sub_phase_timing "$FEATURE_DIR" "optimize" "security"

   - Safety check: cd api && uv run safety check
   - Report vulnerabilities: ${FEATURE_DIR}/security-backend.log

2. Frontend Security:
   - Audit: pnpm --filter @cfipros/marketing audit || true
   - Audit: pnpm --filter @cfipros/app audit || true
   - Report vulnerabilities: ${FEATURE_DIR}/security-frontend.log

3. Penetration Tests:
   - API security tests: cd api && uv run pytest tests/security/ -v
   - Check auth/authz on protected routes
   - Report: ${FEATURE_DIR}/security-tests.log
n# Complete sub-phase timing
complete_sub_phase_timing "$FEATURE_DIR" "optimize" "security"

Output summary to ${FEATURE_DIR}/optimization-security.md with:
- Vulnerability count by severity (critical/high/medium/low)
- Critical issues (must fix before deployment)
- Status: PASSED/FAILED (fail if critical vulnerabilities)
`
})

// Check 3: Accessibility Audits
Task({
  subagent_type: "general-purpose",
  description: "Accessibility audits",
  prompt: `Run accessibility validation for feature at ${FEATURE_DIR}:

1. WCAG Compliance:
   - Extract WCAG level requirement from ${PLAN_FILE}
n# Start sub-phase timing
source .spec-flow/scripts/bash/workflow-state.sh
start_sub_phase_timing "$FEATURE_DIR" "optimize" "accessibility"

   - Run a11y tests: pnpm --filter @cfipros/marketing test -- --runInBand
   - Run a11y tests: pnpm --filter @cfipros/app test -- --runInBand
   - Report: ${FEATURE_DIR}/a11y-tests.log

2. Lighthouse A11y (if UI feature):
   - Use Lighthouse results from performance check (if available)
   - Extract accessibility score
   - Target: ≥95
   - Report: ${FEATURE_DIR}/a11y-lighthouse.log

n# Complete sub-phase timing
complete_sub_phase_timing "$FEATURE_DIR" "optimize" "accessibility"
3. Manual Checklist Validation:
   - Keyboard navigation (check aria labels, focus indicators)
   - Color contrast ratios (4.5:1 text, 3:1 UI)
   - Screen reader compatibility
   - Report: ${FEATURE_DIR}/a11y-manual.log

Output summary to ${FEATURE_DIR}/optimization-accessibility.md with:
- WCAG compliance status
- Lighthouse a11y score
- Issues found
- Status: PASSED/FAILED (fail if Lighthouse <95 or WCAG violations)
`
})

// Check 4: Senior Code Review
Task({
n# Start sub-phase timing
source .spec-flow/scripts/bash/workflow-state.sh
start_sub_phase_timing "$FEATURE_DIR" "optimize" "code_review"

  subagent_type: "senior-code-reviewer",
  description: "Senior code review",
  prompt: `Review feature at ${FEATURE_DIR} for contract compliance and quality gates:

Focus on:
1. API Contract Compliance:
   - Check ${FEATURE_DIR}/api-contracts/*.yaml (if exists)
   - Verify OpenAPI spec alignment
   - Check request/response schemas match implementation

2. KISS/DRY Principle Violations:
   - Check for over-engineering
   - Check for code duplication
   - Check for unnecessary complexity

3. Security Vulnerabilities:
   - SQL injection risks (parameterized queries?)
   - XSS risks (input sanitization?)
   - Authentication/authorization gaps

4. Test Coverage:
   - Run coverage: cd api && uv run pytest --cov=app tests/
   - Run coverage: pnpm --filter @cfipros/app test --coverage
   - Target: ≥80%

5. Quality Gates:
n# Complete sub-phase timing
complete_sub_phase_timing "$FEATURE_DIR" "optimize" "code_review"
   - Lint: cd api && uv run ruff check .
   - Types: cd api && uv run mypy app/ --strict
   - Lint: pnpm --filter @cfipros/app lint
   - Types: pnpm --filter @cfipros/app type-check

Output detailed findings to ${FEATURE_DIR}/code-review.md with:
- Critical issues (Severity: CRITICAL) - must fix before deployment
- High priority issues (Severity: HIGH) - should fix
- Minor suggestions (Severity: MEDIUM/LOW) - consider
- Quality metrics (lint, types, tests, coverage)
- Status: PASSED/FAILED (fail if critical issues found)
`
})

// Check 5: Migration Validation (if schema changes)
Task({
  subagent_type: "general-purpose",
  description: "Migration validation",
  prompt: `Validate database migrations for feature at ${FEATURE_DIR}:

n# Start sub-phase timing
source .spec-flow/scripts/bash/workflow-state.sh
start_sub_phase_timing "$FEATURE_DIR" "optimize" "migrations"

1. Check if migrations exist:
   - Look for ${FEATURE_DIR}/migration-plan.md
   - If not found, skip validation (no schema changes)

2. If migrations exist:
   - Find migration files: find api/alembic/versions -name "*.py" -newer ${FEATURE_DIR}/migration-plan.md
   - Check reversibility: verify all have downgrade() function
   - Test upgrade/downgrade cycle:
     cd api && uv run alembic upgrade head
     cd api && uv run alembic downgrade -1
     cd api && uv run alembic upgrade +1
   - Check schema drift: cd api && uv run alembic check

3. Report:
   - ${FEATURE_DIR}/migration-validation.log

Output summary to ${FEATURE_DIR}/optimization-migrations.md with:
- Migration files found
- Reversibility status
- Upgrade/downgrade test results
- Schema drift status
- Status: PASSED/FAILED/SKIPPED
`
})

n# Complete sub-phase timing
complete_sub_phase_timing "$FEATURE_DIR" "optimize" "migrations"
echo ""
echo "⏳ Waiting for all checks to complete..."
echo ""

// Wait for all Task() calls to complete
// Claude Code will execute these in parallel and aggregate results
```

**After all parallel checks complete, aggregate results:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Aggregating Optimization Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Initialize aggregation
CRITICAL_ISSUES=0
BLOCKING_CHECKS=()
FAILED_CHECKS=()
PASSED_CHECKS=()

# Check 1: Performance
if [ -f "$FEATURE_DIR/optimization-performance.md" ]; then
  if grep -q "Status: FAILED" "$FEATURE_DIR/optimization-performance.md"; then
    FAILED_CHECKS+=("Performance")
    echo "⚠️  Performance: Some targets missed"
  elif grep -q "Status: PASSED" "$FEATURE_DIR/optimization-performance.md"; then
    PASSED_CHECKS+=("Performance")
    echo "✅ Performance: All targets met"
  fi
fi

# Check 2: Security
if [ -f "$FEATURE_DIR/optimization-security.md" ]; then
  CRITICAL_VULNS=$(grep -c "Severity: CRITICAL\|Severity: HIGH" "$FEATURE_DIR/optimization-security.md" 2>/dev/null || echo 0)

  if [ "$CRITICAL_VULNS" -gt 0 ]; then
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + CRITICAL_VULNS))
    BLOCKING_CHECKS+=("Security: $CRITICAL_VULNS critical vulnerabilities")
    echo "❌ Security: $CRITICAL_VULNS critical vulnerabilities found"
  else
    PASSED_CHECKS+=("Security")
    echo "✅ Security: No critical vulnerabilities"
  fi
fi

# Check 3: Accessibility
if [ -f "$FEATURE_DIR/optimization-accessibility.md" ]; then
  if grep -q "Status: FAILED" "$FEATURE_DIR/optimization-accessibility.md"; then
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
    BLOCKING_CHECKS+=("Accessibility: WCAG violations or score <95")
    echo "❌ Accessibility: WCAG violations or score <95"
  else
    PASSED_CHECKS+=("Accessibility")
    echo "✅ Accessibility: WCAG compliant"
  fi
fi

# Check 4: Code Review
if [ -f "$FEATURE_DIR/code-review.md" ]; then
  CODE_REVIEW_CRITICAL=$(grep -c "Severity: CRITICAL" "$FEATURE_DIR/code-review.md" 2>/dev/null || echo 0)

  if [ "$CODE_REVIEW_CRITICAL" -gt 0 ]; then
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + CODE_REVIEW_CRITICAL))
    BLOCKING_CHECKS+=("Code Review: $CODE_REVIEW_CRITICAL critical issues")
    echo "❌ Code Review: $CODE_REVIEW_CRITICAL critical issues found"
  else
    PASSED_CHECKS+=("Code Review")
    echo "✅ Code Review: No critical issues"
  fi
fi

# Check 5: Migrations
if [ -f "$FEATURE_DIR/optimization-migrations.md" ]; then
  if grep -q "Status: FAILED" "$FEATURE_DIR/optimization-migrations.md"; then
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
    BLOCKING_CHECKS+=("Migrations: Reversibility or drift issues")
    echo "❌ Migrations: Reversibility or drift issues"
  elif grep -q "Status: PASSED" "$FEATURE_DIR/optimization-migrations.md"; then
    PASSED_CHECKS+=("Migrations")
    echo "✅ Migrations: All checks passed"
  else
    echo "⏭️  Migrations: Skipped (no schema changes)"
  fi
fi

echo ""
echo "Summary:"
echo "  Passed: ${#PASSED_CHECKS[@]}"
echo "  Failed: ${#FAILED_CHECKS[@]}"
echo "  Blocking: ${#BLOCKING_CHECKS[@]}"
echo ""

# If critical issues found, offer auto-fix or block
if [ "$CRITICAL_ISSUES" -gt 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "❌ CRITICAL ISSUES FOUND ($CRITICAL_ISSUES)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Blocking issues:"
  for issue in "${BLOCKING_CHECKS[@]}"; do
    echo "  - $issue"
  done
  echo ""
  echo "Review detailed reports:"
  echo "  - Security: $FEATURE_DIR/optimization-security.md"
  echo "  - Accessibility: $FEATURE_DIR/optimization-accessibility.md"
  echo "  - Code Review: $FEATURE_DIR/code-review.md"
  echo "  - Migrations: $FEATURE_DIR/optimization-migrations.md"
  echo ""

  # Update workflow state to failed
  update_workflow_phase "$FEATURE_DIR" "optimize" "failed"

  echo "Options:"
  echo "  1. Fix issues manually and run: /feature continue"
  echo "  2. Run auto-fix: /optimize with auto-fix enabled"
  echo ""
  exit 1
fi

echo "✅ All optimization checks passed"
echo ""

# Update workflow state to completed
n# Complete timing for optimize phase
complete_phase_timing "$FEATURE_DIR" "optimize"
update_workflow_phase "$FEATURE_DIR" "optimize" "completed"

echo "Next: /feature auto-continues to /ship"
echo ""
```

## DETAILED PHASE DESCRIPTIONS (Reference)

The following sections provide detailed documentation for each optimization phase.
The actual execution uses the parallel Task() calls above for 4-5x speedup.

## PHASE 5.1: FRONTEND PERFORMANCE

**Local Lighthouse validation:**

```bash
echo "Running local Lighthouse checks..."
echo ""

# Check if dev server running
if ! lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
  echo "Starting dev server..."
  cd apps/app
  pnpm dev &
  DEV_PID=$!
  sleep 10
else
  echo "✅ Dev server running on port 3000"
fi

# Run Lighthouse on main routes
if command -v lighthouse &> /dev/null; then
  # Check if polished designs exist
  if [ -d "apps/web/mock/$SLUG" ]; then
    SCREENS=$(find apps/web/mock/$SLUG -path "*/polished/page.tsx" | \
              sed 's|.*/\([^/]*\)/polished/.*|\1|' | \
              sort -u)

    echo "Running Lighthouse on implemented screens..."

    while IFS= read -r screen; do
      URL="http://localhost:3000/$SLUG/$screen"

      echo "  Testing: $URL"

      lighthouse "$URL" \
        --output=json \
        --output-path="$FEATURE_DIR/lighthouse-$screen-local.json" \
        --only-categories=performance,accessibility \
        --preset=desktop \
        --quiet \
        --chrome-flags="--headless"

      # Parse scores
      PERF=$(jq '.categories.performance.score * 100' "$FEATURE_DIR/lighthouse-$screen-local.json")
      A11Y=$(jq '.categories.accessibility.score * 100' "$FEATURE_DIR/lighthouse-$screen-local.json")

      echo "    Performance: $PERF / 100"
      echo "    A11y: $A11Y / 100"

      # Check against targets
      if (( $(echo "$PERF < 90" | bc -l) )); then
        echo "    ⚠️  Performance below 90"
      fi

      if (( $(echo "$A11Y < 95" | bc -l) )); then
        echo "    ❌ Accessibility below 95 (BLOCKER)"
        BLOCKERS+=("Lighthouse a11y score <95 on $screen")
      fi

    done <<< "$SCREENS"
  else
    echo "ℹ️  No UI screens (backend-only feature)"
  fi
else
  echo "⚠️  Lighthouse not installed"
  echo "Install: npm install -g lighthouse"
  echo ""
  echo "Skipping local Lighthouse checks"
  echo "Will validate in staging after /phase-1-ship"
fi

# Stop dev server if we started it
if [ -n "$DEV_PID" ]; then
  kill $DEV_PID 2>/dev/null
fi

echo ""
```

**Note**: Full Lighthouse CI runs in staging deployment. This local check catches major issues early.

**Validation checklist:**

### Frontend Performance

**Local validation** (pre-deployment):
- [ ] Lighthouse performance ≥90 (local dev server)
- [ ] Lighthouse a11y ≥95 (local dev server)
- [ ] Bundle size < target from plan.md
- [ ] No console errors/warnings

**Staging validation** (post /phase-1-ship):
- [ ] Lighthouse CI in deploy-staging.yml
- [ ] Results in GitHub Actions artifacts
- [ ] FCP < 1.5s, TTI < 3s, LCP < 2.5s
- [ ] Performance score ≥90, A11y ≥95

### Backend Performance

```bash
# Load testing endpoints
cd api
uv run pytest tests/performance/ -v

# Check response times against targets
grep "p95" "$PLAN_FILE"
# Example target: API <500ms p95, extraction <10s p95
```

**Validation checklist:**
- [ ] Database queries indexed (check EXPLAIN plans)
- [ ] N+1 queries eliminated (use eager loading)
- [ ] Response time targets met (p50, p95, p99)
- [ ] Batch operations use concurrency
- [ ] Redis caching where appropriate

## PHASE 5.2: SECURITY

### Dependency Scanning

```bash
# Backend
cd api
uv run bandit -r app/ -ll
uv run safety check

# Frontend packages
pnpm --filter @cfipros/marketing audit
pnpm --filter @cfipros/app audit
```

**Validation checklist:**
- [ ] No high/critical vulnerabilities
- [ ] Dependencies up to date
- [ ] No hardcoded secrets (detect-secrets)
- [ ] Input validation on all endpoints
- [ ] CORS configured correctly
- [ ] Rate limiting on public endpoints

### Penetration Testing

```bash
# API security tests
cd api
uv run pytest tests/security/ -v

# Check authentication/authorization
grep "require_auth" api/app/api/v1/
```

**Validation checklist:**
- [ ] Authentication required on protected routes
- [ ] Authorization checks per role (RBAC)
- [ ] SQL injection prevented (parameterized queries)
- [ ] XSS prevented (input sanitization)
- [ ] CSRF tokens where needed

## PHASE 5.3: ACCESSIBILITY

```bash
# Frontend a11y smoke tests
pnpm --filter @cfipros/marketing test -- --runInBand
pnpm --filter @cfipros/app test -- --runInBand
```

**Validation checklist:**
- [ ] WCAG 2.1 AA compliance (or level from plan.md)
- [ ] Keyboard navigation works
- [ ] Screen reader tested (NVDA/VoiceOver)
- [ ] ARIA labels on interactive elements
- [ ] Color contrast ratios met (4.5:1 text, 3:1 UI)
- [ ] Focus indicators visible

**Auto-fix common issues:**
- Add or update `jest-axe` assertions in relevant Vitest suites
- Use `pnpm format` to normalize accessible markup helpers

## PHASE 5.4: ERROR HANDLING

### Graceful Degradation

```bash
# Test error scenarios
cd api
uv run pytest tests/integration/test_error_handling.py -v

# Frontend error boundaries
pnpm --filter @cfipros/marketing test -- --runInBand ErrorBoundary
pnpm --filter @cfipros/app test -- --runInBand ErrorBoundary
```

**Validation checklist:**
- [ ] All API endpoints have try/catch
- [ ] User-friendly error messages (no stack traces)
- [ ] Logging with structured context
- [ ] Frontend error boundaries present
- [ ] Network failure handling
- [ ] Timeout handling (API requests)

### Observability

```bash
# Check logging coverage
grep -r "logger\." api/app/ | wc -l

# Metrics instrumentation
grep -r "track\|posthog" apps/app/ apps/marketing/
```

**Validation checklist:**
- [ ] Structured logging (JSON format)
- [ ] Error tracking configured (Sentry/PostHog)
- [ ] Performance metrics tracked
- [ ] Business events tracked
- [ ] Debug logs removed from production code

## PHASE 5.5: SENIOR CODE REVIEW

Delegate comprehensive code review to senior-code-reviewer agent:

```bash
# Launch senior code reviewer agent
Task tool with:
  subagent_type: "senior-code-reviewer"
  description: "Review feature for contract compliance and quality gates"
  prompt: "Review feature at $FEATURE_DIR for:

  1. API contract compliance (OpenAPI spec alignment)
  2. KISS/DRY principle violations
  3. Security vulnerabilities
  4. Test coverage and contract tests
  5. Quality gate validation

  Focus on:
  - Files changed since last merge to main
  - Contract alignment with $FEATURE_DIR/api-contracts/*.yaml (if exists)
  - Test completeness per $FEATURE_DIR/spec.md

  Provide review summary with:
  - Critical issues (must fix before ship)
  - Important improvements (should fix)
  - Minor suggestions (consider)
  - Quality metrics (lint, types, tests, coverage)

  Write detailed findings to $FEATURE_DIR/code-review.md"
```

**Validation checklist:**
- [ ] Senior code reviewer completed analysis
- [ ] Code review report generated at code-review.md
- [ ] No critical contract violations
- [ ] Quality gates passing (lint, types, tests)
- [ ] Test coverage ≥80% (or approved exception)
- [ ] KISS/DRY principles followed
- [ ] Security issues addressed

**If critical issues found:**
- Offer AUTO-FIX (see Phase 5.6 below)
- If user declines auto-fix or auto-fix fails:

```bash
# Block optimization until fixed
echo "❌ CRITICAL ISSUES FOUND - Cannot proceed to /phase-1-ship"
echo "Review: $FEATURE_DIR/code-review.md"
echo ""
echo "Fix critical issues then re-run /optimize"
exit 1
```

## PHASE 5.6: AUTO-FIX (Optional)

After code review finds issues, offer automatic fixing via `/debug`:

### Parse Review Report

```bash
# Count issues by severity
CRITICAL=$(grep -c "Severity: CRITICAL" "$FEATURE_DIR/code-review.md" || echo 0)
HIGH=$(grep -c "Severity: HIGH" "$FEATURE_DIR/code-review.md" || echo 0)
MEDIUM=$(grep -c "Severity: MEDIUM" "$FEATURE_DIR/code-review.md" || echo 0)
```

### Offer Auto-Fix

Prompt user:
```
Senior code review found:
- $CRITICAL critical issues (must fix)
- $HIGH high priority issues (should fix)
- $MEDIUM minor suggestions (optional)

Auto-fix these issues using /debug?
A) Yes - fix all critical + high priority issues automatically
B) Selective - choose which issues to fix
C) No - show report and exit for manual fixes
```

### Auto-Fix Iteration Loop (with Think Tool)

If user selects A or B:

```bash
echo ""
echo "Starting auto-fix ($AUTO_FIX_MODE mode)..."
echo ""

ITERATION=1
MAX_ITERATIONS=3
ISSUES_FIXED=0

# Extract issues from code-review.md
ISSUES=$(grep -A 10 "^### Issue" "$FEATURE_DIR/code-review.md")

while [ $ITERATION -le $MAX_ITERATIONS ]; do
  echo "Auto-fix iteration $ITERATION/$MAX_ITERATIONS"
  echo ""

  # Get next issue to fix
  NEXT_ISSUE=$(parse_next_issue "$ISSUES" "$AUTO_FIX_MODE")

  if [ -z "$NEXT_ISSUE" ]; then
    echo "✅ All auto-fixable issues resolved"
    break
  fi

  ISSUE_ID=$(echo "$NEXT_ISSUE" | grep "ID:" | sed 's/ID: //')
  SEVERITY=$(echo "$NEXT_ISSUE" | grep "Severity:" | sed 's/Severity: //')
  CATEGORY=$(echo "$NEXT_ISSUE" | grep "Category:" | sed 's/Category: //')
  FILE=$(echo "$NEXT_ISSUE" | grep "File:" | sed 's/File: //')

  echo "Fixing: $ISSUE_ID ($SEVERITY)"
  echo "  Category: $CATEGORY"
  echo "  File: $FILE"
  echo ""

  # Analyze with think tool
  # (Claude performs analysis, determines fix strategy)

  # Route to appropriate fix method
  case "$CATEGORY" in
    "Contract Violation"|"KISS"|"DRY")
      # Call /debug with issue context
      /debug --from-optimize \
        --issue-id="$ISSUE_ID" \
        --file="$FILE" \
        --category="$CATEGORY"
      ;;
    "Security")
      # Delegate to security specialist
      /route-agent security-specialist "$FILE" \
        --issue="$NEXT_ISSUE"
      ;;
    *)
      # General fix
      /debug --from-optimize --issue-id="$ISSUE_ID"
      ;;
  esac

  if [ $? -eq 0 ]; then
    echo "  ✅ Fixed"
    ((ISSUES_FIXED++))
  else
    echo "  ⚠️  Manual review required"
  fi

  echo ""
  ((ITERATION++))
done

echo ""
echo "Auto-fix complete: $ISSUES_FIXED issue(s) fixed"
echo ""

# Re-run code review
echo "Re-running code review to verify fixes..."
# (Re-invoke senior-code-reviewer agent)
```

**For each auto-fixable issue:**

1. **Parse issue from code-review.md**:
   ```bash
   # Extract structured fields:
   ISSUE_ID     # e.g., CR001
   SEVERITY     # CRITICAL, HIGH, MEDIUM, LOW
   CATEGORY     # Contract Violation, KISS, DRY, Security, Type Safety, Test Coverage
   FILE         # File path
   LINE         # Line number
   DESCRIPTION  # Issue description
   RECOMMENDATION  # Fix recommendation
   ```

2. **Analyze with Think Tool** (per Anthropic best practices - 54% improvement):
   ```markdown
   **Thinking about issue $ISSUE_ID:**

   **Root cause analysis:**
   - What is the actual problem? (not just symptom)
   - Why did this get through initial implementation?
   - Is this a pattern repeated elsewhere in codebase?

   **Fix strategy evaluation:**
   - What are the trade-offs of fixing now vs later?
   - Could this fix introduce new bugs or regressions?
   - Does this require cascading changes to other files?
   - Should we delegate to specialist agent or fix directly?

   **Risk assessment:**
   - Complexity: LOW/MEDIUM/HIGH
   - Test coverage impact: Will existing tests catch regressions?
   - Side effects: Could affect other features?
   - Context budget: Will fix add significant tokens?

   **Decision:**
   - Fix directly via /debug (LOW complexity, clear fix)
   - Delegate to specialist agent (MEDIUM/HIGH complexity)
   - Skip and mark for manual review (HIGH risk, unclear impact)
   - Batch with related issues (DRY violations across files)
   ```

3. **Route fix based on analysis:**
   ```bash
   # Decision tree from Think Tool analysis
   if [ "$COMPLEXITY" = "LOW" ] && [ "$RISK" = "LOW" ]; then
     # Direct fix via /debug
     FIX_METHOD="debug"
   elif [ "$CATEGORY" = "Contract Violation" ] || [ "$CATEGORY" = "KISS" ]; then
     # Delegate to appropriate specialist
     FIX_METHOD="route-agent"
     AGENT=$(determine-agent-from-category "$CATEGORY" "$FILE")
   else
     # Manual review needed
     FIX_METHOD="manual"
     echo "⏸️  Issue $ISSUE_ID requires manual review (complexity: $COMPLEXITY, risk: $RISK)"
     continue
   fi
   ```

4. **Verify fix**:
   ```bash
   # Run quality gates after each fix
   if [ "$FILE" = api/* ]; then
     cd api && uv run ruff check . && uv run mypy . && uv run pytest
   elif [ "$FILE" = apps/* ]; then
     cd apps/app && pnpm lint && pnpm type-check && pnpm test
   fi
   ```

5. **Track progress**:
   - Update error-log.md with fix details
   - Mark issue as fixed in code-review.md
   - Commit fix with reference to issue ID

### Safety Guardrails

- **Git commits**: After each fix for rollback capability
- **Quality gates**: Verify after each fix
- **Error logging**: Track all fixes in error-log.md
- **Manual fallback**: If 3 iterations fail, exit to manual
- **User control**: Optional auto-fix, can decline at any time

## VALIDATE MIGRATIONS (if schema changes)

**Check migrations match plan.md schema:**

```bash
if grep -q "## \[SCHEMA\]" "$PLAN_FILE"; then
  echo "Validating database migrations..."
  echo ""

  # Extract entities from plan.md
  ENTITIES=$(sed -n '/## \[SCHEMA\]/,/## \[/p' "$PLAN_FILE" | \
             grep -E "^-|^\*" | \
             grep -oE "[A-Z][a-z]+" | \
             sort -u)

  ENTITY_COUNT=$(echo "$ENTITIES" | wc -l)

  echo "Entities in plan.md: $ENTITY_COUNT"
  echo ""

  # Check each entity has migration
  MISSING_MIGRATIONS=()

  while IFS= read -r entity; do
    # Check if migration file exists
    MIGRATION=$(find api/alembic/versions -name "*${entity,,}*" 2>/dev/null | head -1)

    if [ -z "$MIGRATION" ]; then
      MISSING_MIGRATIONS+=("$entity")
      echo "  ❌ $entity: No migration file"
    else
      echo "  ✅ $entity: $(basename "$MIGRATION")"

      # Check reversibility
      if ! grep -q "def downgrade" "$MIGRATION"; then
        echo "     ⚠️  Not reversible (missing downgrade())"
      fi
    fi
  done <<< "$ENTITIES"

  if [ ${#MISSING_MIGRATIONS[@]} -gt 0 ]; then
    echo ""
    echo "❌ BLOCKER: ${#MISSING_MIGRATIONS[@]} entities without migrations"
    echo ""
    echo "Missing migrations for:"
    for entity in "${MISSING_MIGRATIONS[@]}"; do
      echo "  - $entity"
    done
    echo ""
    echo "Generate: alembic revision -m \"Add $entity table\""
    exit 1
  fi

  echo ""
  echo "✅ All entities have migrations"
  echo ""
fi
```

### Migration Safety

**Validate database migrations are reversible and safe:**

```bash
if [ -f "$FEATURE_DIR/migration-plan.md" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🗄️  DATABASE MIGRATION VALIDATION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  cd api

  # Find migrations created for this feature
  MIGRATIONS=$(find alembic/versions -name "*.py" -newer "$FEATURE_DIR/migration-plan.md" 2>/dev/null || echo "")

  if [ -z "$MIGRATIONS" ]; then
    echo "⚠️  migration-plan.md exists but no migrations found"
    echo "Run: alembic revision -m 'description'"
  else
    # Check each migration for reversibility
    for migration in $MIGRATIONS; do
      if ! grep -q "def downgrade()" "$migration"; then
        echo "  ❌ Missing downgrade() in $migration"
        echo "     Migrations must be reversible for safe rollback"
        exit 1
      fi
      echo "  ✅ Reversible: $(basename $migration)"
    done

    # Test migration upgrade/downgrade cycle
    echo ""
    echo "Testing migration reversibility..."
    uv run alembic upgrade head
    uv run alembic downgrade -1
    uv run alembic upgrade +1
    echo "  ✅ Migration upgrade/downgrade cycle works"

    # Check for schema drift
    uv run alembic check
    if [ $? -eq 0 ]; then
      echo "  ✅ No schema drift detected"
    else
      echo "  ❌ Schema drift detected - models don't match migrations"
      exit 1
    fi
  fi

  cd ..
  echo ""
fi
```

**Validation checklist:**
- [ ] All migrations have `downgrade()` function (reversible)
- [ ] Migration upgrade/downgrade cycle tested
- [ ] No schema drift (`alembic check` passes)
- [ ] Migrations use expand-contract pattern (backward compatible)
- [ ] Code handles both old and new schema during migration window

## VALIDATE SMOKE TESTS

**Check smoke tests cover critical user flows:**

```bash
echo "Validating smoke test coverage..."
echo ""

# Check smoke tests exist
SMOKE_TESTS=$(find tests/smoke -name "*.spec.ts" -o -name "test_*.py" 2>/dev/null)

if [ -z "$SMOKE_TESTS" ]; then
  echo "❌ BLOCKER: No smoke tests found"
  echo ""
  echo "Create smoke tests for critical flows:"
  echo "  - tests/smoke/critical-flow.spec.ts"
  echo "  - Tag with @smoke (Playwright) or @pytest.mark.smoke (Python)"
  exit 1
fi

SMOKE_COUNT=$(echo "$SMOKE_TESTS" | wc -l)
echo "Found $SMOKE_COUNT smoke test file(s)"
echo ""

# Extract critical flows from spec.md
CRITICAL_FLOWS=$(sed -n '/## User Scenarios/,/^## /p' "$FEATURE_DIR/spec.md" | \
                 grep "^- " | \
                 sed 's/^- //')

if [ -z "$CRITICAL_FLOWS" ]; then
  echo "⚠️  No user scenarios in spec.md"
  echo "Recommendation: Document critical flows to validate smoke test coverage"
else
  FLOW_COUNT=$(echo "$CRITICAL_FLOWS" | wc -l)
  echo "Critical flows in spec.md: $FLOW_COUNT"
  echo ""

  # Check each flow has smoke test
  UNCOVERED=()

  while IFS= read -r flow; do
    # Extract key terms
    KEY_TERMS=$(echo "$flow" | grep -oE "[A-Z][a-z]+" | head -2 | tr '\n' ' ')

    # Search smoke tests for coverage
    if grep -qi "$KEY_TERMS" $SMOKE_TESTS 2>/dev/null; then
      echo "  ✅ $flow"
    else
      UNCOVERED+=("$flow")
      echo "  ⚠️  $flow (no smoke test found)"
    fi
  done <<< "$CRITICAL_FLOWS"

  if [ ${#UNCOVERED[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  ${#UNCOVERED[@]} critical flow(s) without smoke tests"
    echo "Recommendation: Add smoke tests for full coverage"
  fi
fi

echo ""

# Run smoke tests
echo "Running smoke tests..."

# Frontend
cd apps/app
pnpm playwright test -g "@smoke"
FRONTEND_RESULT=$?

# Backend
cd ../../api
pytest -m smoke
BACKEND_RESULT=$?

if [ $FRONTEND_RESULT -ne 0 ] || [ $BACKEND_RESULT -ne 0 ]; then
  echo ""
  echo "❌ BLOCKER: Smoke tests failed"
  exit 1
fi

echo ""
echo "✅ All smoke tests passed"
echo ""
```

## VALIDATE ANALYTICS INSTRUMENTATION (if UI feature)

**Check analytics events are implemented:**

```bash
if [ -f "$FEATURE_DIR/design/analytics.md" ]; then
  echo "Validating analytics instrumentation..."
  echo ""

  # Extract expected events
  EXPECTED_EVENTS=$(grep -oE "[a-z_]+\.[a-z_]+" "$FEATURE_DIR/design/analytics.md" | sort -u)

  EVENT_COUNT=$(echo "$EXPECTED_EVENTS" | wc -l)

  echo "Expected events in analytics.md: $EVENT_COUNT"
  echo ""

  # Check production routes for instrumentation
  PROD_ROUTES=$(find apps/app/$SLUG -name "*.tsx")

  MISSING_EVENTS=()

  while IFS= read -r event; do
    # Search for event in production code
    if grep -q "$event" $PROD_ROUTES 2>/dev/null; then
      echo "  ✅ $event"
    else
      MISSING_EVENTS+=("$event")
      echo "  ❌ $event (not instrumented)"
    fi
  done <<< "$EXPECTED_EVENTS"

  if [ ${#MISSING_EVENTS[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  ${#MISSING_EVENTS[@]} event(s) not instrumented"
    echo "Recommendation: Add analytics.track() calls"
  else
    echo ""
    echo "✅ All analytics events instrumented"
  fi

  echo ""
else
  echo "ℹ️  No analytics.md (skipping analytics validation)"
  echo ""
fi
```

## VALIDATE FEATURE FLAGS (if required)

**Check feature flag implementation:**

```bash
if grep -q "Feature flag:" "$PLAN_FILE"; then
  echo "Validating feature flag implementation..."
  echo ""

  # Extract flag name
  FLAG_NAME=$(grep "Feature flag:" "$PLAN_FILE" | sed 's/.*Feature flag: //' | sed 's/ .*//')

  echo "Expected flag: $FLAG_NAME"
  echo ""

  # Check implementation
  if grep -q "useFeatureFlag.*$FLAG_NAME" apps/app/**/*.tsx 2>/dev/null; then
    echo "  ✅ Flag check implemented"
  else
    echo "  ❌ Flag check not found in code"
  fi

  # Check environment variable exists
  ENV_VAR="NEXT_PUBLIC_${FLAG_NAME^^}_ENABLED"

  if grep -q "$ENV_VAR" .env.example 2>/dev/null; then
    echo "  ✅ Environment variable documented"
  else
    echo "  ⚠️  $ENV_VAR not in .env.example"
  fi

  # Check rollout percentage variable
  PERCENT_VAR="NEXT_PUBLIC_${FLAG_NAME^^}_PERCENT"

  if grep -q "$PERCENT_VAR" .env.example 2>/dev/null; then
    echo "  ✅ Rollout percentage variable documented"
  else
    echo "  ⚠️  $PERCENT_VAR not in .env.example"
  fi

  echo ""
else
  echo "ℹ️  No feature flags required"
  echo ""
fi
```

## PHASE 5.8: DEPLOYMENT READINESS

### Build Validation

**Local build smoke test before deploying:**

```bash
# Frontend build check
cd apps/app
pnpm build
if [ $? -ne 0 ]; then
  echo "❌ Frontend build failed - fix before deploying"
  exit 1
fi
echo "✅ Frontend builds successfully"

# Backend Docker build check
cd ../../api
docker build -t cfipros-api:test .
if [ $? -ne 0 ]; then
  echo "❌ API Docker build failed - fix before deploying"
  exit 1
fi
echo "✅ API Docker image builds successfully"

# Scripts executable check
chmod +x scripts/*.sh
echo "✅ Scripts are executable"
```

**Validation checklist:**
- [ ] `pnpm build` succeeds in apps/app
- [ ] `docker build api/` succeeds
- [ ] All scripts in scripts/ are executable
- [ ] No build warnings that indicate errors

### Environment Variables

**Validate secrets schema and required environment variables:**

```bash
# Check secrets.schema.json exists and is updated
if [ ! -f "secrets.schema.json" ]; then
  echo "❌ secrets.schema.json not found"
  echo "Create schema documenting all required environment variables"
  exit 1
fi

# Validate current environment against schema
node scripts/require-env.js $(jq -r '.required[]' secrets.schema.json 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ Missing required environment variables"
  echo "See secrets.schema.json for required variables"
  exit 1
fi
echo "✅ All required environment variables present"

# Check if feature added new variables
NEW_VARS=$(grep "New required:" "$PLAN_FILE" 2>/dev/null || echo "")

if [ -n "$NEW_VARS" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔐 NEW ENVIRONMENT VARIABLES"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "$NEW_VARS"
  echo ""
  echo "Validation:"
  echo "  [ ] Added to secrets.schema.json"
  echo "  [ ] Staging values configured in Vercel/Railway"
  echo "  [ ] Production values prepared (not applied yet)"
  echo "  [ ] verify.yml validates schema with require-env.js"
  echo ""
fi
```

**Validation checklist:**
- [ ] `secrets.schema.json` exists and documents all required variables
- [ ] `node scripts/require-env.js` passes (all vars present)
- [ ] New variables (if any) added to secrets.schema.json
- [ ] Staging environment configured with new variables
- [ ] Production values documented (not applied until promotion)

### Validate Portable Artifacts

**Guardrail #1: Build-once, promote-many**

Check that feature uses portable artifacts (not rebuild per environment):

```bash
# Check plan.md for artifact strategy
ARTIFACT_STRATEGY=$(grep -A 10 "Artifact Strategy" "$PLAN_FILE" || echo "")

if [[ -z "$ARTIFACT_STRATEGY" ]]; then
  echo "⚠️  No artifact strategy documented in plan.md"
  echo "Feature should document portable artifacts:"
  echo "  - Web apps: Vercel .vercel/output/ (via 'vercel build')"
  echo "  - API: Docker image with commit SHA tag (NOT :latest)"
  echo ""
  echo "See: standards/deploy-acceptance.md (Artifact Strategy section)"
else
  echo "✅ Artifact strategy documented in plan.md"
fi
```

**Validation checklist:**
- [ ] Artifact strategy in plan.md [DEPLOYMENT ACCEPTANCE]
- [ ] Web apps use `vercel build` (not `vercel deploy --prod`)
- [ ] API uses commit SHA tags: `ghcr.io/.../api:$COMMIT_SHA`
- [ ] Artifacts uploaded to GitHub Actions artifacts (verify.yml)

### Validate Drift Protection

**Guardrail #3: Env/schema drift blockers**

Check environment variables and migration alignment:

```bash
# Check for new environment variables
NEW_ENV_VARS=$(grep -h "New required:" "$PLAN_FILE" | sed 's/.*: //' || echo "")

if [[ -n "$NEW_ENV_VARS" ]]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔐 ENVIRONMENT VARIABLES CHANGED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "New variables documented: $NEW_ENV_VARS"
  echo ""
  echo "Validation checklist:"
  echo "  [ ] Added to secrets.schema.json"
  echo "  [ ] Staging values documented in plan.md"
  echo "  [ ] Production values documented in plan.md"
  echo "  [ ] verify.yml validates schema (require-env.js)"
  echo ""
fi

# Check migration alignment
if [[ -f "$FEATURE_DIR/migration-plan.md" ]]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🗄️  DATABASE MIGRATION DETECTED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Migration validation:"
  cd api

  # Check migration reversibility
  MIGRATIONS=$(find alembic/versions -name "*.py" -newer "$FEATURE_DIR/migration-plan.md" 2>/dev/null || echo "")

  if [[ -n "$MIGRATIONS" ]]; then
    for migration in $MIGRATIONS; do
      if ! grep -q "def downgrade()" "$migration"; then
        echo "  ❌ Missing downgrade() in $migration"
      else
        echo "  ✅ Reversible migration: $migration"
      fi
    done
  fi

  # Check Alembic alignment
  uv run alembic check
  if [[ $? -eq 0 ]]; then
    echo "  ✅ No schema drift detected"
  else
    echo "  ❌ Schema drift detected - run 'alembic upgrade head'"
  fi

  cd ..
  echo ""
fi
```

**Validation checklist:**
- [ ] Environment schema updated (secrets.schema.json)
- [ ] Migration has downgrade() (reversible)
- [ ] No schema drift (alembic check passes)
- [ ] verify.yml checks env schema and migration alignment

### Validate Rollback Readiness

**Guardrail #2: Promotion gate with instant rollback**

Ensure NOTES.md tracks deployment metadata for 3-command rollback:

```bash
# Check if NOTES.md has Deployment Metadata section
if ! grep -q "## Deployment Metadata" "$FEATURE_DIR/NOTES.md"; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📝 ROLLBACK TRACKING REQUIRED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Adding Deployment Metadata section to NOTES.md..."
  echo ""

  cat >> "$FEATURE_DIR/NOTES.md" << 'METADATA'

## Deployment Metadata

**Purpose**: Track deploy IDs for instant 3-command rollback (see runbook/rollback.md)

### Staging Deploys

| Date | Marketing Deploy ID | App Deploy ID | API Image SHA | Status |
|------|---------------------|---------------|---------------|--------|
| YYYY-MM-DD | marketing-xyz123.vercel.app | app-abc456.vercel.app | ghcr.io/.../api:sha123 | ✅ Validated |

### Production Deploys

| Date | Marketing Deploy ID | App Deploy ID | API Image SHA | Status |
|------|---------------------|---------------|---------------|--------|
| YYYY-MM-DD | marketing-prod789.vercel.app | app-prod012.vercel.app | ghcr.io/.../api:sha789 | ✅ Live |

**Rollback Commands** (from runbook/rollback.md):
```bash
# 1. Get deploy ID from table above
# 2. Set alias to previous deploy
vercel alias set <previous-deploy-id> cfipros.com --token=$VERCEL_TOKEN

# 3. Update API image
railway service update --image ghcr.io/.../api:<previous-sha> --environment production
```
METADATA

  echo "✅ Deployment Metadata section added to NOTES.md"
  echo ""
else
  echo "✅ Deployment Metadata section exists in NOTES.md"
fi
```

**Validation checklist:**
- [ ] NOTES.md has Deployment Metadata section
- [ ] Table structure ready for deploy IDs
- [ ] Rollback commands documented
- [ ] promote.yml outputs deploy IDs (captured in workflow logs)

### Validate Deployment Strategy

**Check if feature modifies CI/CD workflows:**

```bash
MODIFIED_WORKFLOWS=$(git diff staging...HEAD --name-only | grep "\.github/workflows" || echo "")

if [[ -n "$MODIFIED_WORKFLOWS" ]]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀 DEPLOYMENT WORKFLOW CHANGES DETECTED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Modified workflows:"
  echo "$MODIFIED_WORKFLOWS" | sed 's/^/  - /'
  echo ""
  echo "✅ Rate Limit Prevention Checklist:"
  echo ""
  echo "  [ ] Workflow supports preview mode (no --prod flag by default)"
  echo "  [ ] Workflow defaults to preview (deployment_mode: 'preview')"
  echo "  [ ] Local testing documented (act dry-run, vercel build)"
  echo "  [ ] Concurrency controls configured (cancel-in-progress)"
  echo "  [ ] Retry logic uses exponential backoff (not aggressive)"
  echo ""
  echo "⚠️  Vercel Rate Limits: 100 deployments/day"
  echo "    Manual trigger = 2 apps × 3 retries = 6 deployments"
  echo "    17 manual triggers = 102 deployments = RATE LIMIT ❌"
  echo ""
  echo "📖 Reference: docs/CI-CD-GUIDE.md (CI Debugging Without Burning Deployments)"
  echo ""
fi
```

**Validation steps:**

1. **Detect workflow changes** - Check git diff for .github/workflows modifications
2. **Show checklist** - Display rate limit prevention requirements
3. **Reference docs** - Point to CI-CD-GUIDE.md for complete guidance
4. **Non-blocking** - Informational only, doesn't block /optimize

**Workflow best practices:**

- **Default to preview mode**: `deployment_mode: 'preview'` for manual triggers
- **Gate production deploys**: Only use `staging` mode when explicitly selected
- **Local testing first**: Run `pnpm run ci:validate` before triggering workflows
- **Concurrency controls**: Use `cancel-in-progress: true` to stop duplicate builds
- **Label-gated previews**: Only deploy PR previews when labeled 'preview'

### Type Coverage

```bash
# Backend: MyPy strict mode
cd api
uv run mypy app/ --strict

# Frontend: TypeScript strict
pnpm --filter @cfipros/marketing run type-check
pnpm --filter @cfipros/app run type-check
```

**Validation checklist:**
- [ ] 100% type coverage (no `any` in TS, no `type: ignore` in Python)
- [ ] Strict mode enabled
- [ ] All imports typed

## TOOL FAILURE HANDLING

- **Lighthouse unavailable**: Skip performance audit, warn user, suggest manual Lighthouse run
- **Bandit/Safety missing**: Try `uv pip install bandit safety`, if fails skip security scan with warning
- **pnpm audit fails**: Log vulnerabilities, continue if only low/moderate, block on high/critical
- **Test timeout (>5min)**: Cancel test run, ask "Debug failing test or skip validation?"
- **Type-check crashes**: Show error, suggest fixing incrementally, don't block on single file
- **Build fails**: Critical blocker, must fix before proceeding to `/phase-1-ship`

## ERROR RECOVERY

- **Performance targets missed**: Show actual vs target, suggest optimizations, ask "Fix now or ship with known issue?"
- **Accessibility failures**: List specific WCAG violations, offer "Auto-fix where possible" or "Manual review"
- **Security vulnerabilities**: Categorize by severity, block on critical/high, warn on medium/low
- **Coverage below 80%**: Identify untested files, suggest "Add tests now" or "Document as tech debt"
- **Optimization script errors**: Log error, continue with remaining validations, report partial results

## QUALITY GATE

All must pass before `/phase-1-ship`:

```markdown
## Optimization Checklist

### Performance
- [ ] Backend: p95 < target from plan.md
- [ ] Frontend: Bundle size < target, images optimized
- [ ] Lighthouse metrics: Validated locally (or in staging deployment)

### Security
- [ ] Zero high/critical vulnerabilities
- [ ] Authentication/authorization enforced
- [ ] Input validation complete
- [ ] Penetration tests passing

### Accessibility
- [ ] WCAG level met (from plan.md)
- [ ] Keyboard navigation works
- [ ] Screen reader compatible
- [ ] Lighthouse a11y score: ≥95

### Error Handling
- [ ] Graceful degradation implemented
- [ ] Structured logging present
- [ ] Error tracking configured

### Code Quality
- [ ] Senior code review completed (see code-review.md)
- [ ] Auto-fix applied (if critical/high issues found)
- [ ] Contract compliance verified
- [ ] KISS/DRY principles followed
- [ ] All tests passing (80%+ coverage)

### Deployment Readiness
- [ ] Build validation: `pnpm build` and `docker build` succeed
- [ ] Smoke tests: `@smoke` tagged tests pass in <90s
- [ ] Environment variables: All required vars in secrets.schema.json
- [ ] Migration safety: Reversible migrations with downgrade()
- [ ] Portable artifacts: Build-once strategy documented in plan.md
- [ ] Drift protection: No schema drift, env vars validated
- [ ] Rollback tracking: Deployment Metadata section in NOTES.md
- [ ] Workflow changes follow rate limit prevention (if workflows modified)
- [ ] CI/CD validation complete (see docs/CI-CD-GUIDE.md)

### UI Implementation (if UI feature)
- [ ] All polished screens implemented in production routes
- [ ] Design tokens used (no hardcoded colors/spacing)
- [ ] Analytics events instrumented (if analytics.md exists)
- [ ] Feature flags implemented (if required)
```

## CONTEXT BUDGET TRACKING

**Optimization Phase Budget (Phase 5-7):**
- **Budget**: 125k tokens
- **Compact at**: 100k tokens (80% threshold)
- **Strategy**: Minimal (30% reduction - preserve code review + all checkpoints)

**After optimization phases complete:**

```bash
# Token tracking is automatic via Claude Code hooks
# Hooks update $FEATURE_DIR/NOTES.md after each response
# Check NOTES.md for "Context Budget Update" sections

# Check if compaction warning exists in NOTES.md
if grep -q "Compaction needed: true" "$FEATURE_DIR/NOTES.md" 2>/dev/null; then
  echo "⚠️  Token threshold exceeded (see NOTES.md for details)"
  echo "Run: /compact or compact-context.ps1 -Phase optimization"
fi
```

**What gets preserved (minimal strategy):**
- ✅ All decisions and rationale
- ✅ All architecture decisions
- ✅ All task checkpoints (no limit)
- ✅ Full error log
- ✅ **Complete code review report** (critical for review context)
- ❌ Only redundant research details removed

**Why minimal compaction in optimization?**
- Code review needs full context for accurate analysis
- All checkpoints preserve feature history
- Error log shows patterns and learnings
- Optimization phase is final quality gate

## WRITE OPTIMIZATION REPORT

Create optimization report:

```bash
cat > "$FEATURE_DIR/optimization-report.md" << 'EOF'
# Production Readiness Report
**Date**: $(date +%Y-%m-%d\ %H:%M)
**Feature**: $SLUG

## Performance
- Backend p95: XXXms (target: XXXms) ✅/❌
- Bundle size: XXkB (target: XXkB) ✅/❌
- Lighthouse metrics: See local results or staging deployment artifacts

## Security
- Critical vulnerabilities: N
- High vulnerabilities: N
- Medium/Low vulnerabilities: N
- Auth/authz enforced: ✅/❌
- Rate limiting configured: ✅/❌

## Accessibility
- WCAG level: AA ✅/❌
- Lighthouse a11y score: XX/100
- Keyboard navigation: ✅/❌
- Screen reader compatible: ✅/❌

## Code Quality
- Senior code review: ✅ Passed / ❌ Critical issues found
- Auto-fix applied: ✅ N issues fixed / ⏭️ Skipped / N/A
- Contract compliance: ✅/❌
- KISS/DRY violations: N issues
- Type coverage: NN%
- Test coverage: NN%
- ESLint compliance: ✅/❌

**Code Review Report**: $FEATURE_DIR/code-review.md

## Auto-Fix Summary

[If auto-fix was enabled, include detailed summary. Otherwise: "N/A - manual fixes only"]

**Auto-fix enabled**: [Yes/No]
**Iterations**: [N/3]
**Issues fixed**: [N]

**Before/After**:
- Critical: [N → N]
- High: [N → N]

**Error Log Entries**: [N entries added] (see $FEATURE_DIR/error-log.md)

## Blockers
[List specific issues or "None - ready for `/phase-1-ship`"]

## Next Steps
- [ ] Fix remaining blockers (if any)
- [ ] Run `/phase-1-ship` to deploy to staging
EOF
```

Display summary to user:
- Path to report: `$FEATURE_DIR/optimization-report.md`
- Blocker count
- Ready for `/phase-1-ship`? Y/N

## GIT COMMIT

After optimization complete:
```bash
git add .
git commit -m "polish:optimize: production readiness validation

Performance:
- Backend p95: XXXms (target: XXXms) ✅
- Frontend FCP: X.Xs (target: 1.5s) ✅
- Bundle size: XXkB (target: XXkB) ✅

Security:
- Zero critical vulnerabilities ✅
- Auth/authz enforced ✅
- Rate limiting configured ✅

Accessibility:
- WCAG 2.1 AA compliance ✅
- Lighthouse a11y score: XX ✅

Code Quality:
- Senior code review: ✅ Passed
- Type coverage: 100% ✅
- Test coverage: XX% ✅

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# Verify commit succeeded
COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""
echo "✅ Optimization committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""
```

## UPDATE NOTES.md

After completing optimization, update NOTES.md with Phase 5 checkpoint:

```bash
# Source the template
source \spec-flow/templates/notes-update-template.sh

# Collect optimization results
PERF_STATUS=$(grep -q "Performance: ✅" "$OPTIMIZATION_REPORT" && echo "All targets met" || echo "Issues found")
SECURITY_STATUS=$(grep -q "Security: ✅" "$OPTIMIZATION_REPORT" && echo "Zero vulnerabilities" || echo "Issues found")
A11Y_STATUS=$(grep -q "Accessibility: ✅" "$OPTIMIZATION_REPORT" && echo "WCAG AA compliant" || echo "Issues found")
REVIEW_STATUS=$(grep -q "Senior Code Review: ✅" "$OPTIMIZATION_REPORT" && echo "Passed" || echo "Issues found")

# Add Phase 5 checkpoint
update_notes_checkpoint "$FEATURE_DIR" "5" "Optimize" \
  "Performance: $PERF_STATUS" \
  "Security: $SECURITY_STATUS" \
  "Accessibility: $A11Y_STATUS" \
  "Senior code review: $REVIEW_STATUS" \
  "Ready for: /preview"

update_notes_timestamp "$FEATURE_DIR"
```

## CONTEXT MANAGEMENT

Check if compaction needed before proceeding:

```bash
if grep -q "Compaction needed: true" "$FEATURE_DIR/NOTES.md" 2>/dev/null; then
  echo "⚠️  Context compaction recommended before /preview"
  echo ""
  echo "Run: /compact \"preserve code review report, all quality metrics, and all checkpoints\""
fi
```

**If compaction not needed**, proceed directly to `/preview`.

## RETURN

Brief summary:
- ✅ Performance: Backend XXXms p95, bundle size optimized
- 🔒 Security: 0 critical vulnerabilities, auth enforced
- ♿ Accessibility: WCAG level met
- 📋 Code Quality: Senior review passed, tests passing XX% coverage
- ⚠️  Blockers: N issues found (fix before /preview) OR 0 (ready for /preview)
- Next: `/preview` (manual UI/UX testing before shipping) (or /compact if threshold exceeded)

</instructions>
