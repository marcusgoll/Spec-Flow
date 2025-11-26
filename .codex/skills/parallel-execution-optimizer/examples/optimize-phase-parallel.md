# Example: /optimize Phase Parallelization

Complete walkthrough of parallelizing the /optimize phase quality checks.

## Context

Running /optimize on a full-stack feature with:
- Backend API endpoints (authentication)
- Frontend UI components (login form)
- TypeScript codebase
- npm dependencies

## Traditional Sequential Execution

**Workflow**:
```
1. Run security-sentry (3 minutes)
   - Scan for SQL injection, XSS, CSRF
   - Check for secrets in code
   - Validate authentication logic

2. Run performance-profiler (4 minutes)
   - Benchmark API endpoints
   - Measure p50/p95 latency
   - Detect N+1 queries

3. Run accessibility-auditor (3 minutes)
   - WCAG 2.1 AA compliance check
   - Keyboard navigation testing
   - Screen reader compatibility

4. Run type-enforcer (2 minutes)
   - TypeScript strict mode validation
   - Check for implicit any
   - Validate null safety

5. Run dependency-curator (2 minutes)
   - npm audit for vulnerabilities
   - Check for outdated packages
   - Detect duplicate dependencies

6. Generate optimization-report.md (1 minute)
   - Aggregate findings from steps 1-5
   - Categorize by severity
   - Generate recommendations

Total time: 15 minutes
```

**Issues**:
- Each check waits for previous to complete
- Checks 1-5 are independent (all read-only operations)
- Total time = sum of all operations
- User waits 15 minutes despite checks being independent

## Parallel Execution Approach

### Step 1: Analyze Dependencies

**Operations**:
1. security-sentry - Reads src/, auth/, API code
2. performance-profiler - Reads src/, runs benchmarks
3. accessibility-auditor - Reads src/components/
4. type-enforcer - Reads **/*.ts files
5. dependency-curator - Reads package.json, package-lock.json
6. Generate report - Reads outputs from 1-5

**Dependencies**:
- Operations 1-5: **No dependencies** (all read-only, disjoint or shared read-only access)
- Operation 6: **Depends on 1-5** (needs their outputs to aggregate)

**Dependency graph**:
```
Layer 0 (parallel):
  - security-sentry
  - performance-profiler
  - accessibility-auditor
  - type-enforcer
  - dependency-curator

Layer 1 (sequential):
  - Generate optimization-report.md
```

### Step 2: Group into Batches

**Batch 1 (Layer 0)**: All 5 quality checks in single message (parallel)
**Batch 2 (Layer 1)**: Generate report after Batch 1 completes

### Step 3: Execute Parallel Batch

**Single message with 5 tool calls**:

```
I'm launching all 5 quality checks in parallel. This will take approximately 4-5 minutes (the time of the longest check).

<function_calls>
<invoke name="Task">
<parameter name="subagent_type">security-sentry</parameter>
<parameter name="description">Security audit</parameter>
<parameter name="prompt">
Audit the authentication implementation in src/auth/ for security vulnerabilities.

Check for:
1. SQL injection in database queries
2. XSS vulnerabilities in user input handling
3. CSRF protection on state-changing endpoints
4. Secrets or API keys in code
5. Weak password hashing (check for bcrypt with ≥12 rounds)
6. Session management vulnerabilities

Scan these directories:
- src/auth/
- src/api/endpoints/
- src/middleware/

Report findings categorized by severity (CRITICAL, HIGH, MEDIUM, LOW).
</parameter>
</invoke>

<invoke name="Task">
<parameter name="subagent_type">performance-profiler</parameter>
<parameter name="description">Performance benchmarking</parameter>
<parameter name="prompt">
Benchmark all API endpoints and identify performance bottlenecks.

Targets:
- API p50 latency: <200ms
- API p95 latency: <500ms
- Page load time: <2s

Check for:
1. N+1 database queries
2. Missing database indexes
3. Slow synchronous operations
4. Large payload sizes
5. Inefficient algorithms

Endpoints to benchmark:
- POST /api/auth/login
- POST /api/auth/register
- GET /api/user/profile

Report p50/p95 latencies and recommendations.
</parameter>
</invoke>

<invoke name="Task">
<parameter name="subagent_type">accessibility-auditor</parameter>
<parameter name="description">Accessibility audit</parameter>
<parameter name="prompt">
Audit UI components for WCAG 2.1 AA compliance.

Check for:
1. Keyboard navigation support (tab order, focus indicators)
2. ARIA labels on interactive elements
3. Color contrast ratios (≥4.5:1 for text)
4. Screen reader compatibility
5. Form labels and error messages

Components to audit:
- src/components/LoginForm.tsx
- src/components/RegistrationForm.tsx
- src/components/UserProfile.tsx

Report violations with severity and remediation steps.
</parameter>
</invoke>

<invoke name="Task">
<parameter name="subagent_type">type-enforcer</parameter>
<parameter name="description">Type safety validation</parameter>
<parameter name="prompt">
Scan TypeScript codebase for type safety violations.

Check for:
1. Implicit any types
2. Unsafe type assertions (as any)
3. Missing null/undefined checks
4. Untyped external API responses
5. Strict mode violations

Files to scan:
- src/**/*.ts
- src/**/*.tsx

Ensure strict TypeScript configuration is enabled:
- strictNullChecks: true
- noImplicitAny: true
- strictFunctionTypes: true

Report violations with file paths and line numbers.
</parameter>
</invoke>

<invoke name="Task">
<parameter name="subagent_type">dependency-curator</parameter>
<parameter name="description">Dependency audit</parameter>
<parameter name="prompt">
Audit npm dependencies for vulnerabilities and issues.

Check for:
1. Critical/high severity vulnerabilities (npm audit)
2. Outdated packages (>6 months behind latest)
3. Duplicate dependencies (multiple versions of same package)
4. Unused dependencies (installed but not imported)

Run:
- npm audit --production
- Check package.json vs package-lock.json consistency
- Identify packages with no recent updates (abandoned)

Report findings with recommended actions (update, replace, remove).
</parameter>
</invoke>
</function_calls>
```

All 5 agents launch simultaneously and run concurrently.

### Step 4: Wait for Results

While checks run in parallel (4-5 minutes), user sees:
```
Running parallel quality checks:
✓ Security audit in progress...
✓ Performance benchmarking in progress...
✓ Accessibility audit in progress...
✓ Type safety validation in progress...
✓ Dependency audit in progress...
```

### Step 5: Aggregate Results

After all 5 checks complete, collect results:

```
Results:
✓ security-sentry: 2 MEDIUM issues found (CSRF protection missing on 2 endpoints)
✓ performance-profiler: 1 HIGH issue (N+1 query in user profile endpoint - 450ms p95)
✓ accessibility-auditor: 3 LOW issues (missing ARIA labels on 3 buttons)
✓ type-enforcer: 0 violations (strict mode compliant)
✓ dependency-curator: 1 CRITICAL (lodash vulnerability CVE-2024-XXXX), 3 outdated packages
```

**Decision logic**:
- CRITICAL dependency vulnerability → BLOCKING (must fix before deployment)
- Other issues → Non-blocking warnings (document in report)

**Action**: Generate optimization report and halt workflow due to critical dependency issue.

### Step 6: Generate Report

```
Creating optimization-report.md:

# Optimization Report

## Summary
- **Status**: BLOCKED - Critical dependency vulnerability
- **Quality checks run**: 5/5 passed
- **Blocking issues**: 1 (dependency vulnerability)
- **Warnings**: 6 (performance, security, accessibility)

## Critical Issues (Blocking)
1. **Dependency Vulnerability** (CRITICAL)
   - Package: lodash@4.17.20
   - Vulnerability: CVE-2024-XXXX (prototype pollution)
   - Fix: Update to lodash@4.17.21

## Warnings (Non-blocking)
1. **Performance** (HIGH)
   - N+1 query in GET /api/user/profile (p95: 450ms)
   - Fix: Add database index on user_id

2. **Security** (MEDIUM)
   - CSRF protection missing on POST /api/auth/logout
   - Fix: Add CSRF token validation

3. **Accessibility** (LOW)
   - Missing ARIA labels on 3 buttons
   - Fix: Add aria-label attributes

## Recommendations
1. Fix critical lodash vulnerability immediately
2. Address N+1 query for better performance
3. Add CSRF protection to state-changing endpoints
4. Improve accessibility with ARIA labels

## Next Steps
- Fix critical dependency vulnerability
- Re-run /optimize to verify fix
- Proceed to /preview after all checks pass
```

## Time Comparison

**Sequential execution**:
```
security-sentry:        3 min
performance-profiler:   4 min
accessibility-auditor:  3 min
type-enforcer:          2 min
dependency-curator:     2 min
generate report:        1 min
------------------------
Total:                 15 min
```

**Parallel execution**:
```
Batch 1 (parallel):     4 min  (longest of 5 checks)
Batch 2 (sequential):   1 min  (generate report)
------------------------
Total:                  5 min
```

**Speedup**: 3x (15 minutes → 5 minutes)

## Key Takeaways

1. **Independence enables parallelism**: All 5 checks were read-only operations with no dependencies
2. **Single message required**: All 5 Task() calls in ONE message to enable parallel execution
3. **Longest operation determines time**: Total time = max(3,4,3,2,2) + 1 = 5 minutes
4. **Blocking issues handled**: Critical vulnerability halts workflow appropriately
5. **Significant speedup**: 3x faster with identical results

## Gotchas to Avoid

**DON'T** send 5 separate messages:
```
Message 1: Task(security-sentry, ...)
Message 2: Task(performance-profiler, ...)
... (sequential, not parallel)
```

**DO** send 1 message with 5 tool calls:
```
Message 1:
  Task(security-sentry, ...)
  Task(performance-profiler, ...)
  Task(accessibility-auditor, ...)
  Task(type-enforcer, ...)
  Task(dependency-curator, ...)
```

**DON'T** parallelize report generation with checks:
```
Batch 1: All 5 checks + report generation
(Report needs check outputs - race condition)
```

**DO** sequence report after checks:
```
Batch 1: All 5 checks (parallel)
Batch 2: Report generation (after Batch 1)
```

## Validation

**Correctness check**:
1. Run /optimize sequentially (baseline)
2. Run /optimize with parallelization
3. Compare optimization-report.md (should be identical)
4. Verify all issues detected in both runs
5. Confirm time savings (sequential: 15min, parallel: 5min)

**Success criteria**:
- ✓ All 5 checks completed successfully
- ✓ Results identical to sequential run
- ✓ Time reduced by ~3x
- ✓ Critical issues properly block workflow
- ✓ Report generated with all findings

This demonstrates successful application of parallel execution optimization to the /optimize phase.
