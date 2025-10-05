---
description: Production readiness validation (performance, security, a11y, code review)
---

Validate production readiness for: specs/$FEATURE

## LOAD TARGETS

Read from `specs/NNN-feature/plan.md`:
- **[PERFORMANCE TARGETS]**  response times, bundle sizes, FCP/TTI
- **[SECURITY]**  authentication, authorization, input validation
- **[ACCESSIBILITY]**  WCAG level required

## PHASE 5.1: PERFORMANCE

### Backend Performance

```bash
# Load testing endpoints
cd api
uv run pytest tests/performance/ -v

# Check response times against targets
grep "p95" specs/NNN-feature/plan.md
# Example target: API <500ms p95, extraction <10s p95
```

**Validation checklist:**
- [ ] Database queries indexed (check EXPLAIN plans)
- [ ] N+1 queries eliminated (use eager loading)
- [ ] Response time targets met (p50, p95, p99)
- [ ] Batch operations use concurrency
- [ ] Redis caching where appropriate

### Frontend Performance

**Note**: Frontend performance metrics are collected during staging deployment via Lighthouse CI (see `.github/workflows/deploy-staging.yml`).

**Local validation checklist:**
- [ ] Bundle size < target (from plan.md)
- [ ] Images optimized (Next.js Image, lazy loading)
- [ ] Code splitting for large components
- [ ] No console errors/warnings in browser

**Staging metrics** (captured after /ship Phase 1):
- FCP < 1.5s (First Contentful Paint)
- TTI < 3s (Time to Interactive)
- LCP < 2.5s (Largest Contentful Paint)
- Lighthouse Performance > 90
- Lighthouse Accessibility > 95

Review Lighthouse results in GitHub Actions artifacts after staging deployment.

## PHASE 5.2: SECURITY

### Dependency Scanning

```bash
# Backend
cd api
uv run bandit -r app/ -ll
uv run safety check

# Frontend
cd frontend
pnpm audit
pnpm run security:scan
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
# Frontend a11y tests
cd frontend
pnpm run test:a11y

# Lighthouse accessibility score
pnpm run lighthouse:a11y
```

**Validation checklist:**
- [ ] WCAG 2.1 AA compliance (or level from plan.md)
- [ ] Keyboard navigation works
- [ ] Screen reader tested (NVDA/VoiceOver)
- [ ] ARIA labels on interactive elements
- [ ] Color contrast ratios met (4.5:1 text, 3:1 UI)
- [ ] Focus indicators visible

**Auto-fix common issues:**
```bash
# Add missing alt text
pnpm run fix:a11y
```

## PHASE 5.4: ERROR HANDLING

### Graceful Degradation

```bash
# Test error scenarios
cd api
uv run pytest tests/integration/test_error_handling.py -v

# Frontend error boundaries
cd frontend
pnpm run test -- ErrorBoundary
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
grep -r "track\|posthog" frontend/
```

**Validation checklist:**
- [ ] Structured logging (JSON format)
- [ ] Error tracking configured (Sentry/PostHog)
- [ ] Performance metrics tracked
- [ ] Business events tracked
- [ ] Debug logs removed from production code

## PHASE 5.5: SENIOR CODE REVIEW

Delegate comprehensive code review to spec-flow-senior-code-reviewer agent:

```bash
# Launch senior code reviewer agent
Task tool with:
  subagent_type: "spec-flow-senior-code-reviewer"
  description: "Review feature for contract compliance and quality gates"
  prompt: "Review feature at specs/$FEATURE for:

  1. API contract compliance (OpenAPI spec alignment)
  2. KISS/DRY principle violations
  3. Security vulnerabilities
  4. Test coverage and contract tests
  5. Quality gate validation

  Focus on:
  - Files changed since last merge to main
  - Contract alignment with specs/$FEATURE/api-contracts/*.yaml (if exists)
  - Test completeness per specs/$FEATURE/spec.md

  Provide review summary with:
  - Critical issues (must fix before ship)
  - Important improvements (should fix)
  - Minor suggestions (consider)
  - Quality metrics (lint, types, tests, coverage)

  Write detailed findings to specs/$FEATURE/artifacts/code-review-report.md"
```

**Validation checklist:**
- [ ] Senior code reviewer completed analysis
- [ ] Code review report generated at artifacts/code-review-report.md
- [ ] No critical contract violations
- [ ] Quality gates passing (lint, types, tests)
- [ ] Test coverage 80% (or approved exception)
- [ ] KISS/DRY principles followed
- [ ] Security issues addressed

**If critical issues found:**
- Offer AUTO-FIX (see Phase 5.6 below)
- If user declines auto-fix or auto-fix fails:
```bash
# Block optimization until fixed
echo " CRITICAL ISSUES FOUND - Cannot proceed to /ship"
echo "Review: specs/$FEATURE/artifacts/code-review-report.md"
echo ""
echo "Fix critical issues then re-run /optimize"
exit 1
```

## PHASE 5.6: AUTO-FIX (Optional)

After code review finds issues, offer automatic fixing via `/debug`:

### Parse Review Report

```bash
# Count issues by severity
CRITICAL=$(grep -c "Severity: CRITICAL" specs/$FEATURE/artifacts/code-review-report.md || echo 0)
HIGH=$(grep -c "Severity: HIGH" specs/$FEATURE/artifacts/code-review-report.md || echo 0)
MEDIUM=$(grep -c "Severity: MEDIUM" specs/$FEATURE/artifacts/code-review-report.md || echo 0)
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

**For each auto-fixable issue:**

1. **Parse issue from code-review-report.md**:
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
     echo "  Issue $ISSUE_ID requires manual review (complexity: $COMPLEXITY, risk: $RISK)"
     continue
   fi
   ```

4. **Invoke fix method:**

   **Option A: Direct fix via /debug:**
   ```bash
   # Call /debug command with --from-optimize flag
   /debug --from-optimize \
     --issue-id="$ISSUE_ID" \
     --severity="$SEVERITY" \
     --category="$CATEGORY" \
     --file="$FILE" \
     --line="$LINE" \
     --description="$DESCRIPTION" \
     --recommendation="$RECOMMENDATION"
   ```

   **Option B: Delegate to specialist agent:**
   ```bash
   # Use /route-agent for complex fixes
   /route-agent "$CATEGORY" "$FILE" \
     --issue-id="$ISSUE_ID" \
     --description="$DESCRIPTION" \
     --recommendation="$RECOMMENDATION"
   ```

5. **Invoke /debug with structured input** (DEPRECATED - see above):
   ```bash
   # Call /debug command with --from-optimize flag
   /debug --from-optimize \
     --issue-id="$ISSUE_ID" \
     --severity="$SEVERITY" \
     --category="$CATEGORY" \
     --file="$FILE" \
     --line="$LINE" \
     --description="$DESCRIPTION" \
     --recommendation="$RECOMMENDATION"
   ```

3. **Verify fix**:
   ```bash
   # Run quality gates after each fix
   if [ "$FILE" = api/* ]; then
     cd api && uv run ruff check . && uv run mypy . && uv run pytest
   elif [ "$FILE" = apps/* ]; then
     cd apps/app && pnpm lint && pnpm type-check && pnpm test
   fi
   ```

4. **Track progress**:
   - Update error-log.md with fix details
   - Mark issue as fixed in code-review-report.md
   - Commit fix with reference to issue ID

### Iteration Limits

**MAX 3 iterations** to prevent infinite loops:

```bash
ITERATION=1
MAX_ITERATIONS=3
ISSUES_FIXED=0

while [ $ITERATION -le $MAX_ITERATIONS ]; do
  echo "Auto-fix iteration $ITERATION/$MAX_ITERATIONS"

  # Get next critical/high issue
  NEXT_ISSUE=$(get_next_auto_fixable_issue)

  if [ -z "$NEXT_ISSUE" ]; then
    echo " All auto-fixable issues resolved"
    break
  fi

  # Attempt fix via /debug
  if /debug --from-optimize $NEXT_ISSUE; then
    echo " Issue $ISSUE_ID fixed"
    ISSUES_FIXED=$((ISSUES_FIXED + 1))
  else
    echo " Issue $ISSUE_ID requires manual review"
  fi

  ITERATION=$((ITERATION + 1))
done
```

### Re-run Code Review

After auto-fix completes:

```bash
# Re-run spec-flow-senior-code-reviewer to verify fixes
echo "Re-running senior code review to verify fixes..."

Task tool with spec-flow-senior-code-reviewer (same prompt as Phase 5.5)

# Compare before/after
CRITICAL_AFTER=$(grep -c "Severity: CRITICAL" specs/$FEATURE/artifacts/code-review-report.md || echo 0)
HIGH_AFTER=$(grep -c "Severity: HIGH" specs/$FEATURE/artifacts/code-review-report.md || echo 0)

echo "Auto-fix results:"
echo "  Critical: $CRITICAL  $CRITICAL_AFTER"
echo "  High: $HIGH  $HIGH_AFTER"
echo "  Issues fixed: $ISSUES_FIXED"
```

### Update Optimization Report

Add Auto-Fix Summary to optimization-report.md:

```markdown
## Auto-Fix Summary

**Auto-fix enabled**: Yes
**Iterations**: $ITERATION/$MAX_ITERATIONS
**Issues fixed**: $ISSUES_FIXED

**Before/After**:
- Critical: $CRITICAL  $CRITICAL_AFTER
- High: $HIGH  $HIGH_AFTER

**Issues Fixed**:
- CR001: Contract Violation in User Response [ Fixed]
- CR002: DRY Violation in validation logic [ Fixed]
- CR003: Missing test coverage for auth flow [ Fixed]

**Issues Remaining**:
- CR005: Performance optimization [Manual review needed]

**Error Log Entries**: [N entries added]
- Entry 5: Fixed contract violation
- Entry 6: Refactored validation logic
- Entry 7: Added missing tests

**Verification**:
- All fixes passed quality gates: [/]
- Code review re-run: [$CRITICAL critical  $CRITICAL_AFTER critical]
- Ready for ship: [/]
```

### Safety Guardrails

- **Git commits**: After each fix for rollback capability
- **Quality gates**: Verify after each fix
- **Error logging**: Track all fixes in error-log.md
- **Manual fallback**: If 3 iterations fail, exit to manual
- **User control**: Optional auto-fix, can decline at any time

### Type Coverage

```bash
# Backend: MyPy strict mode
cd api
uv run mypy app/ --strict

# Frontend: TypeScript strict
cd frontend
pnpm run type-check
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
- **Build fails**: Critical blocker, must fix before proceeding to /ship

## ERROR RECOVERY

- **Performance targets missed**: Show actual vs target, suggest optimizations, ask "Fix now or ship with known issue?"
- **Accessibility failures**: List specific WCAG violations, offer "Auto-fix where possible" or "Manual review"
- **Security vulnerabilities**: Categorize by severity, block on critical/high, warn on medium/low
- **Coverage below 80%**: Identify untested files, suggest "Add tests now" or "Document as tech debt"
- **Optimization script errors**: Log error, continue with remaining validations, report partial results

## QUALITY GATE

All must pass before `/ship`:

```markdown
## Optimization Checklist

### Performance
- [ ] Backend: p95 < target from plan.md
- [ ] Frontend: Bundle size < target, images optimized
- [ ] Lighthouse metrics: Validated in staging deployment (see GitHub Actions artifacts)

### Security
- [ ] Zero high/critical vulnerabilities
- [ ] Authentication/authorization enforced
- [ ] Input validation complete
- [ ] Penetration tests passing

### Accessibility
- [ ] WCAG level met (from plan.md)
- [ ] Keyboard navigation works
- [ ] Screen reader compatible
- [ ] Lighthouse a11y score: Validated in staging deployment (see GitHub Actions artifacts)

### Error Handling
- [ ] Graceful degradation implemented
- [ ] Structured logging present
- [ ] Error tracking configured

### Code Quality
- [ ] Senior code review completed (see artifacts/code-review-report.md)
- [ ] Auto-fix applied (if critical/high issues found)
- [ ] Contract compliance verified
- [ ] KISS/DRY principles followed
- [ ] All tests passing (80%+ coverage)
```

## CONTEXT BUDGET TRACKING

**Optimization Phase Budget (Phase 5-7):**
- **Budget**: 125k tokens
- **Compact at**: 100k tokens (80% threshold)
- **Strategy**: Minimal (30% reduction - preserve code review + all checkpoints)

**After optimization phases complete:**

```bash
# Calculate current context (auto-detects optimization phase)
# POSIX: replace 'pwsh -File' with matching .spec-flow/scripts/bash/*.sh helper
FEATURE_DIR=$(find specs -maxdepth 1 -type d -name "*-*" | sort -n | tail -1)
CONTEXT_CHECK=$(pwsh -File .spec-flow/scripts/powershell/calculate-tokens.ps1 \
  -FeatureDir "$FEATURE_DIR" -Phase "optimization" -Json)

CONTEXT_TOKENS=$(echo "$CONTEXT_CHECK" | jq -r '.totalTokens')
SHOULD_COMPACT=$(echo "$CONTEXT_CHECK" | jq -r '.shouldCompact')
BUDGET=$(echo "$CONTEXT_CHECK" | jq -r '.budget')
THRESHOLD=$(echo "$CONTEXT_CHECK" | jq -r '.threshold')

echo "Context: ${CONTEXT_TOKENS}/${BUDGET} tokens (optimization phase)"

if [ "$SHOULD_COMPACT" = "true" ]; then
  echo "  Exceeds threshold (${THRESHOLD} tokens)"
  echo "Auto-compacting with minimal strategy (30% reduction, preserve code review)..."

  pwsh -File .spec-flow/scripts/powershell/compact-context.ps1 \
    -FeatureDir "$FEATURE_DIR" \
    -Phase "optimization"

  # Verify compaction
  NEW_TOKENS=$(pwsh -File .spec-flow/scripts/powershell/calculate-tokens.ps1 \
    -FeatureDir "$FEATURE_DIR" -Phase "optimization" -Json | jq -r '.totalTokens')
  echo " Compacted: ${CONTEXT_TOKENS}  ${NEW_TOKENS} tokens"
fi
```

**What gets preserved (minimal strategy):**
-  All decisions and rationale
-  All architecture decisions
-  All task checkpoints (no limit)
-  Full error log
-  **Complete code review report** (critical for review context)
-  Only redundant research details removed

**Why minimal compaction in optimization?**
- Code review needs full context for accurate analysis
- All checkpoints preserve feature history
- Error log shows patterns and learnings
- Optimization phase is final quality gate

## WRITE OPTIMIZATION REPORT

Create artifacts directory and write comprehensive report:

```bash
mkdir -p specs/$FEATURE/artifacts

cat > specs/$FEATURE/artifacts/optimization-report.md << 'EOF'
# Production Readiness Report
**Date**: $(date +%Y-%m-%d\ %H:%M)
**Feature**: $FEATURE

## Performance
- Backend p95: XXXms (target: XXXms) /
- Bundle size: XXkB (target: XXkB) /
- Lighthouse metrics: See staging deployment artifacts (GitHub Actions)

## Security
- Critical vulnerabilities: N
- High vulnerabilities: N
- Medium/Low vulnerabilities: N
- Auth/authz enforced: /
- Rate limiting configured: /

## Accessibility
- WCAG level: AA /
- Lighthouse a11y score: XX/100
- Keyboard navigation: /
- Screen reader compatible: /

## Code Quality
- Senior code review:  Passed /  Critical issues found
- Auto-fix applied:  N issues fixed /  Skipped / N/A
- Contract compliance: /
- KISS/DRY violations: N issues
- Type coverage: NN%
- Test coverage: NN%
- ESLint compliance: /

**Code Review Report**: specs/$FEATURE/artifacts/code-review-report.md

## Auto-Fix Summary

[If auto-fix was enabled, include detailed summary. Otherwise: "N/A - manual fixes only"]

**Auto-fix enabled**: [Yes/No]
**Iterations**: [N/3]
**Issues fixed**: [N]

**Before/After**:
- Critical: [N  N]
- High: [N  N]

**Error Log Entries**: [N entries added] (see specs/$FEATURE/error-log.md)

## Blockers
[List specific issues or "None - ready for /ship"]

## Next Steps
- [ ] Fix remaining blockers (if any)
- [ ] Run /ship to deploy
EOF
```

Display summary to user:
- Path to report: `specs/$FEATURE/artifacts/optimization-report.md`
- Blocker count
- Ready for /ship? Y/N

## GIT COMMIT

After optimization complete:
```bash
git add .
git commit -m "polish:optimize: production readiness validation

Performance:
- Backend p95: XXXms (target: XXXms) 
- Frontend FCP: X.Xs (target: 1.5s) 
- Bundle size: XXkB (target: XXkB) 

Security:
- Zero critical vulnerabilities 
- Auth/authz enforced 
- Rate limiting configured 

Accessibility:
- WCAG 2.1 AA compliance 
- Lighthouse a11y score: XX 

Code Quality:
- JSDoc/TSDoc on all exports 
- Type coverage: 100% 
- Test coverage: XX% 

 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

## UPDATE NOTES.md

```markdown
## Checkpoints
-  Phase 5 (Optimize): Completed [date]
  - Performance: All targets met
  - Security: Zero vulnerabilities
  - Accessibility: WCAG AA compliant
  - JSDoc: 100% coverage
  - Ready for production
```

## RETURN

Brief summary:
-  Performance: Backend XXXms p95, bundle size optimized
-  Security: 0 critical vulnerabilities, auth enforced
-  Accessibility: WCAG level met
-  Code Quality: Senior review passed, tests passing XX% coverage
-   Blockers: N issues found (fix before /preview) OR 0 (ready for /preview)
- Next: `/preview` (manual UI/UX testing before shipping)

