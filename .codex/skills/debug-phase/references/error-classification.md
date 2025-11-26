<error_classification_matrix>

<overview>
Decision framework for classifying errors by type and severity. Use this matrix to categorize errors during Step 3 of debugging workflow.
</overview>

<error_types>

<type name="syntax">
**Syntax Errors**

**Definition**: Code doesn't compile or parse

**Characteristics**:
- Caught before runtime (compilation/transpilation)
- Clear error messages with line numbers
- Prevents code execution entirely

**Examples**:
- Missing semicolons, brackets, parentheses
- Typos in keywords (`fucntion` vs `function`)
- Invalid syntax (`const x = ;`)
- Linting errors (ESLint, Pylint)

**Detection**:
```bash
# TypeScript/JavaScript
npm run build  # Compilation errors
npm run lint   # ESLint errors

# Python
python -m py_compile script.py  # Syntax check
pylint script.py                # Static analysis
```

**Fix Approach**:
- Read error message (usually accurate)
- Check line number indicated
- Fix syntax issue
- Re-compile/re-lint
</type>

<type name="runtime">
**Runtime Errors**

**Definition**: Code compiles but crashes during execution

**Characteristics**:
- Occurs during program execution
- Uncaught exceptions, null pointers, type errors
- Stack trace available
- Crashes program or request

**Examples**:
- `TypeError: Cannot read property 'name' of undefined` (JavaScript)
- `NullPointerException` (Java)
- `AttributeError: 'NoneType' object has no attribute 'x'` (Python)
- Division by zero
- Array index out of bounds

**Detection**:
```bash
# Check application logs
tail -f logs/app.log

# Check error tracking (Sentry, Rollbar)
# Look for stack traces
```

**Fix Approach**:
- Reproduce error to get stack trace
- Identify exact line causing crash
- Add null checks, bounds checks, type guards
- Add error handling (try/catch) if appropriate
- Write test to prevent recurrence
</type>

<type name="logic">
**Logic Errors**

**Definition**: Code runs without crashing but produces wrong results

**Characteristics**:
- No error messages or stack traces
- Incorrect output or behavior
- Off-by-one errors, wrong calculations, incorrect branching

**Examples**:
- Calculator returns `2 + 2 = 5`
- User sees wrong dashboard data
- Discount applied incorrectly (10% instead of 20%)
- Wrong user logged in after authentication

**Detection**:
```bash
# Unit tests fail with wrong output
npm test

# Manual testing reveals incorrect behavior
# User reports bug: "Expected X, got Y"
```

**Fix Approach**:
- Trace execution with debugger
- Add logging to verify values at each step
- Compare expected vs actual output
- Identify incorrect calculation or condition
- Write test with expected behavior
- Fix logic error
</type>

<type name="integration">
**Integration Errors**

**Definition**: External dependency or service fails

**Characteristics**:
- Network timeouts, connection refused
- API returns error status (500, 503, 429)
- Database connection fails
- Third-party service unavailable

**Examples**:
- `ECONNREFUSED` (connection refused)
- `ETIMEDOUT` (timeout)
- `503 Service Unavailable` from API
- Database connection pool exhausted
- Stripe API rate limit exceeded

**Detection**:
```bash
# Check external service health
curl https://api.example.com/health

# Check network connectivity
ping api.example.com

# Check logs for timeout errors
grep "timeout" logs/app.log
```

**Fix Approach**:
- Verify external service is up (health check)
- Check API credentials, tokens, keys
- Add retry logic with exponential backoff
- Increase timeout if reasonable
- Add circuit breaker for repeated failures
- Consider fallback or caching
</type>

<type name="performance">
**Performance Errors**

**Definition**: Code works but too slow, causing timeouts or degraded UX

**Characteristics**:
- Slow response times (>3s for web pages)
- Timeouts due to slow execution
- Memory leaks causing crashes over time
- N+1 query problems
- CPU/memory usage spikes

**Examples**:
- Dashboard takes 30 seconds to load
- API endpoint times out after 60 seconds
- Memory usage grows unbounded (leak)
- Database query scans entire table (missing index)
- Loop executes 10,000 times unnecessarily

**Detection**:
```bash
# Measure response time
curl -w "@curl-format.txt" -o /dev/null -s https://example.com

# Profile code
node --prof server.js   # Node.js profiling
python -m cProfile script.py  # Python profiling

# Database query analysis
EXPLAIN ANALYZE SELECT ...  # PostgreSQL
```

**Fix Approach**:
- Profile to find bottleneck
- Add indexes to database queries
- Implement caching (Redis, CDN)
- Optimize algorithm (O(n²) → O(n log n))
- Use pagination instead of fetching all records
- Add memory profiling to detect leaks
</type>

</error_types>

<severity_levels>

<severity level="critical">
**Critical Severity**

**Definition**: Data loss, security breach, total system failure

**Impact**:
- Users cannot access system at all
- Data permanently lost or corrupted
- Security vulnerability actively exploited
- Financial loss or legal liability

**Examples**:
- Database corruption, data deletion
- Authentication bypass (anyone can log in as admin)
- SQL injection vulnerability
- Production server crashed, site down
- Payment processing broken (money lost)

**Response**:
- **Immediate** fix required (drop everything)
- Roll back deployment if necessary
- Hotfix and deploy ASAP
- Notify stakeholders immediately
- Post-mortem required

**SLA**: Fix within 1-4 hours
</severity>

<severity level="high">
**High Severity**

**Definition**: Feature broken, blocks users from core functionality

**Impact**:
- Core feature unusable (login, checkout, dashboard)
- Affects majority of users
- Workaround does not exist or is unreasonable
- Business impact significant

**Examples**:
- Login broken (users can't authenticate)
- Checkout fails (can't complete purchase)
- Dashboard doesn't load (shows blank page)
- Search returns no results (when data exists)

**Response**:
- Fix within 1 business day
- Prioritize over new features
- Consider rollback if recent deployment
- Communicate status to affected users

**SLA**: Fix within 24 hours
</severity>

<severity level="medium">
**Medium Severity**

**Definition**: Feature degraded, workaround exists

**Impact**:
- Feature works but degraded performance
- Affects subset of users or edge cases
- Workaround available (manual process, alternative flow)
- Business impact moderate

**Examples**:
- Slow page load (10s instead of 1s)
- Export button requires 2 clicks instead of 1
- Mobile layout broken, desktop works
- Error message unclear but functionality works

**Response**:
- Fix within 1 week
- Schedule in next sprint
- Document workaround for users
- Monitor to ensure doesn't escalate

**SLA**: Fix within 7 days
</severity>

<severity level="low">
**Low Severity**

**Definition**: Minor UX issue, cosmetic, no functional impact

**Impact**:
- Visual inconsistency or cosmetic issue
- Affects very small subset of users
- Minimal business impact
- Nice-to-have fix

**Examples**:
- Text alignment slightly off
- Button color wrong (still readable)
- Tooltip typo
- Console warning (not error)
- Minor accessibility issue

**Response**:
- Fix when convenient (next sprint or later)
- Can be bundled with other fixes
- May defer indefinitely if low priority

**SLA**: Fix within 30 days or defer
</severity>

</severity_levels>

<decision_matrix>

| Type \ Severity | Critical | High | Medium | Low |
|-----------------|----------|------|--------|-----|
| **Syntax** | Blocks deployment | Blocks feature | Review in PR | Fix when convenient |
| **Runtime** | Production crash | Feature broken | Degraded UX | Edge case |
| **Logic** | Data corruption | Wrong results | Incorrect edge case | Cosmetic |
| **Integration** | Service down | API broken | Slow response | Timeout edge case |
| **Performance** | Memory leak crash | Timeout | Slow (>3s) | Slow (>1s) |

**Examples**:

- **Syntax + Critical**: Production build fails (blocks deployment)
- **Runtime + High**: Login crashes on submit (feature broken)
- **Logic + Medium**: Discount calculates wrong for edge case (workaround: manual discount)
- **Integration + Critical**: Database connection fails (service down)
- **Performance + High**: Dashboard times out (feature broken)

</decision_matrix>

<classification_workflow>

**Step 1: Identify Error Type**

Ask:
- Does code compile? → **No** = Syntax, **Yes** = Continue
- Does code crash? → **Yes** = Runtime, **No** = Continue
- Does code produce wrong results? → **Yes** = Logic, **No** = Continue
- Does external service fail? → **Yes** = Integration, **No** = Continue
- Is code too slow? → **Yes** = Performance

**Step 2: Assess Severity**

Ask:
- Data loss or security breach? → **Critical**
- Core feature broken? → **High**
- Workaround exists? → **Medium**
- Cosmetic only? → **Low**

**Step 3: Document Classification**

```markdown
Type: Integration (API call fails)
Severity: High (dashboard broken, no workaround)
Component: StudentProgressService.fetchExternalData()
Frequency: 30% of requests (intermittent)
Impact: Teachers cannot view student progress
```

**Step 4: Prioritize Fix**

- **Critical**: Drop everything, fix immediately
- **High**: Fix within 24 hours
- **Medium**: Schedule in next sprint
- **Low**: Fix when convenient or defer

</classification_workflow>

<edge_cases>

**Multiple Types**:
- Error can be multiple types (e.g., logic error causing performance issue)
- Classify by **root cause** (logic) not symptom (performance)

**Severity Escalation**:
- Medium error affecting 80% of users → escalate to High
- Low frequency error (1%) but critical impact (data loss) → escalate to Critical

**Intermittent Errors**:
- Document frequency (10%, 50%, 90%)
- Intermittent + Critical = still Critical (must fix)
- Intermittent + Low = may defer (monitor frequency)

</edge_cases>

</error_classification_matrix>
