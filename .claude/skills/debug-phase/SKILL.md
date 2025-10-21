---
name: debug-phase
description: "Standard Operating Procedure for /debug phase. Covers error investigation, root cause analysis, systematic debugging, and error documentation."
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Debug Phase: Standard Operating Procedure

> **Training Guide**: Step-by-step procedures for executing the `/debug` command with systematic error investigation and documentation.

**Supporting references**:
- [reference.md](reference.md) - Error classification matrix, debugging workflow, logging best practices
- [examples.md](examples.md) - Good debugging (systematic, documented) vs bad (trial-and-error)
- [scripts/error-classifier.sh](scripts/error-classifier.sh) - Classifies errors by type and severity

---

## Phase Overview

**Purpose**: Systematically investigate errors, identify root causes, implement fixes, and document findings to prevent recurrence.

**Inputs**:
- Error reports (logs, stack traces, user reports)
- `error-log.md` (if exists) - Historical error records

**Outputs**:
- `error-log.md` - Updated with new error entry (ERR-XXXX)
- Fix implementation (code changes)
- Test cases to prevent recurrence
- Updated `workflow-state.yaml`

**Expected duration**: 30 minutes - 4 hours (depends on error complexity)

---

## Prerequisites

**Environment checks**:
- [ ] Error can be reproduced
- [ ] Logs available (application logs, error logs, stack traces)
- [ ] Development environment set up

**Knowledge requirements**:
- Debugging techniques (binary search, logging, breakpoints)
- Error classification (syntax, runtime, logic, integration)
- Root cause analysis (5 Whys, fishbone diagram)

---

## Execution Steps

### Step 1: Search for Similar Errors

**Actions**:
1. Check if `error-log.md` exists and search for similar errors:
   ```bash
   # Search by error message
   grep -i "connection timeout" error-log.md

   # Search by component
   grep "Component: StudentProgressService" error-log.md

   # Search by error type
   grep "Type: Integration" error-log.md
   ```

2. If similar error found:
   - Review previous fix (was it a workaround or root cause fix?)
   - Check if error recurred (implement permanent fix this time)
   - Note patterns (same component? same conditions?)

**Quality check**: If recurring error (>2 occurrences), prioritize permanent fix over workaround.

---

### Step 2: Reproduce Error Consistently

**Actions**:
1. **Gather error context**:
   - Error message and stack trace
   - Timestamp and frequency
   - User actions that triggered error
   - Environment (dev, staging, production)
   - Browser/OS (if frontend error)

2. **Create minimal reproduction**:
   ```bash
   # Example: API error
   curl -X POST http://localhost:3000/api/endpoint \
     -H "Content-Type: application/json" \
     -d '{"field": "value"}'

   # Example: Frontend error
   # Open browser, navigate to /page, click button X
   ```

3. **Verify reproduction**:
   - Can you trigger error reliably (100% of time)?
   - If intermittent: identify conditions (timing, data, state)

**Quality check**: Error reproduces consistently before proceeding to investigation.

---

### Step 3: Classify Error

**Actions**:
Use error classification matrix (see [reference.md](reference.md)):

**By type**:
- **Syntax**: Code doesn't compile/parse (typos, missing brackets)
- **Runtime**: Code runs but crashes (null pointer, type error)
- **Logic**: Code runs but produces wrong result
- **Integration**: External dependency fails (API, database, service)
- **Performance**: Code works but too slow (timeout, memory)

**By severity**:
- **Critical**: Data loss, security breach, total system failure
- **High**: Feature broken, blocks users
- **Medium**: Feature degraded, workaround exists
- **Low**: Minor UX issue, no functional impact

**Example**:
```markdown
## Error Classification

**Type**: Integration (API call to external service fails)
**Severity**: High (dashboard doesn't load, blocks teachers)
**Component**: StudentProgressService.fetchExternalData()
**Frequency**: 30% of requests (intermittent)
```

**Quality check**: Error type and severity correctly identified.

---

### Step 4: Isolate Root Cause

**Actions**:
Use systematic debugging techniques:

**1. Binary search** (for large codebases):
```bash
# Add logging at midpoint
# If error before midpoint: investigate first half
# If error after midpoint: investigate second half
# Repeat until narrowed to specific function
```

**2. Increase logging**:
```python
# Add debug logs around suspected area
logger.debug(f"Before API call: student_id={student_id}")
response = api.fetch_data(student_id)
logger.debug(f"After API call: response={response}")
```

**3. Use breakpoints** (if applicable):
```bash
# Python debugger
python -m pdb script.py

# Node.js debugger
node inspect server.js

# Browser debugger (Frontend)
# Set breakpoints in Chrome DevTools
```

**4. Check assumptions**:
- Is variable the value you expect?
- Is function being called when you expect?
- Are external dependencies available?

**5. Apply 5 Whys**:
```markdown
1. Why did the dashboard fail to load?
   → API call to external service timed out

2. Why did the API call timeout?
   → Request took >30 seconds (timeout limit)

3. Why did the request take >30 seconds?
   → External service response time was 45 seconds

4. Why was external service so slow?
   → Requesting too much data (1000 records instead of 10)

5. Why requesting 1000 records?
   → Missing pagination parameter in API call

**Root cause**: Missing pagination parameter causes over-fetching
```

**Quality check**: Root cause identified (not just symptoms).

---

### Step 5: Implement Fix

**Actions**:
1. **Write failing test** (if not exists):
   ```python
   def test_fetch_external_data_with_pagination():
       """Test that API call includes pagination parameter"""
       service = StudentProgressService()
       result = service.fetchExternalData(student_id=123)

       # Verify pagination applied
       assert len(result) <= 10  # Max 10 records per page
       assert result.has_next_page  # Pagination metadata present
   ```

2. **Implement fix**:
   ```python
   # Before (broken)
   def fetchExternalData(self, student_id):
       return api.get(f"/students/{student_id}/data")

   # After (fixed)
   def fetchExternalData(self, student_id, page_size=10):
       return api.get(
           f"/students/{student_id}/data",
           params={"page_size": page_size}
       )
   ```

3. **Verify fix**:
   ```bash
   # Run test
   pytest tests/test_student_progress_service.py::test_fetch_external_data_with_pagination
   # Should pass

   # Manually test reproduction steps
   # Error should no longer occur
   ```

**Quality check**: Fix addresses root cause (not just symptoms), tests pass.

---

### Step 6: Prevent Recurrence

**Actions**:
1. **Add tests for error scenario**:
   - Unit test for the specific bug
   - Integration test for the user flow
   - Regression test to catch if bug reintroduced

2. **Add defensive code** (if applicable):
   ```python
   # Validate inputs
   if page_size > 100:
       raise ValueError("page_size must be ≤100")

   # Handle errors gracefully
   try:
       result = api.get(url, params=params, timeout=5)
   except requests.Timeout:
       logger.error(f"API timeout: {url}")
       raise ServiceUnavailable("External service unavailable")
   ```

3. **Improve logging** (if needed):
   ```python
   # Log API calls with parameters
   logger.info(f"Fetching external data: student_id={student_id}, page_size={page_size}")

   # Log errors with context
   logger.error(
       f"API call failed: {url}",
       extra={"student_id": student_id, "params": params, "status_code": response.status_code}
   )
   ```

**Quality check**: Tests added, defensive code in place, logging improved.

---

### Step 7: Document in error-log.md

**Actions**:
1. Assign error ID (ERR-XXXX):
   ```bash
   # Get next available ID
   LAST_ID=$(grep -oP "ERR-\K\d+" error-log.md | sort -n | tail -1)
   NEXT_ID=$((LAST_ID + 1))
   # e.g., ERR-0042
   ```

2. Add error entry to `error-log.md`:
   ```markdown
   ## ERR-0042: Dashboard timeout due to missing pagination

   **Date**: 2025-10-21
   **Reporter**: John Doe (teacher)
   **Component**: StudentProgressService.fetchExternalData()
   **Type**: Integration
   **Severity**: High

   **Error Message**:
   ```
   TimeoutError: Request exceeded 30 second timeout
   at api.get (/src/services/api.ts:45)
   ```

   **Steps to Reproduce**:
   1. Navigate to /dashboard as teacher
   2. Click "View Progress" for student with 1000+ activities
   3. Dashboard hangs for 45 seconds, then shows timeout error

   **Root Cause**:
   Missing pagination parameter in API call to external service caused over-fetching (1000 records instead of 10), resulting in >30s response time exceeding timeout.

   **Fix**:
   Added `page_size=10` parameter to API call in StudentProgressService.fetchExternalData()

   **Files Changed**:
   - `api/app/services/student_progress_service.py`: Added pagination parameter
   - `api/app/tests/services/test_student_progress_service.py`: Added regression test

   **Prevention**:
   - Added unit test to verify pagination parameter included
   - Added input validation (max page_size=100)
   - Improved API logging to track parameters

   **Related Errors**: None
   **Status**: Fixed (2025-10-21)
   ```

**Quality check**: Error documented with all required fields.

---

### Step 8: Commit Fix

**Actions**:
```bash
git add api/app/services/student_progress_service.py \
        api/app/tests/services/test_student_progress_service.py \
        error-log.md

git commit -m "fix: add pagination to external data fetch (ERR-0042)

Root cause: Missing pagination parameter caused over-fetching
Impact: Dashboard timeout for students with 1000+ activities
Fix: Added page_size=10 parameter to API call

Changes:
- Added pagination parameter to fetchExternalData()
- Added regression test for pagination
- Updated error-log.md with ERR-0042

Prevents recurrence: Input validation + logging + tests
"
```

**Quality check**: Fix committed with detailed message referencing error ID.

---

## Common Mistakes to Avoid

### 🚫 Recurring Errors Not Recognized

**Impact**: Wasted debugging time, user frustration, technical debt

**Scenario**:
```
Same "Connection timeout" error debugged 3 times
Each time: Added 5-second delay as workaround
Never investigated root cause (connection pool exhaustion)
```

**Prevention**:
1. Search error-log.md BEFORE debugging
2. If error seen before: Review previous fix
3. If workaround was used: Implement permanent fix this time
4. Document patterns for future reference

---

### 🚫 Insufficient Error Context

**Impact**: Hard to reproduce, longer debug time, incomplete fixes

**Bad error log**:
```markdown
## Error: Something broke
**Date**: 2025-10-21
**Fix**: Restarted server
```

**Good error log**:
```markdown
## ERR-0042: Dashboard timeout due to missing pagination
**Date**: 2025-10-21 14:30:00 UTC
**Component**: StudentProgressService.fetchExternalData()
**Error Message**: [full stack trace]
**Steps to Reproduce**: [detailed steps]
**Root Cause**: [5 Whys analysis]
**Fix**: [specific code changes]
**Prevention**: [tests + logging added]
```

**Prevention**: Use error-log template with required fields

---

### 🚫 Treating Symptoms Instead of Root Cause

**Impact**: Error recurs, user frustration, wasted time

**Scenario**:
```
Symptom: API timeout
Quick fix: Increase timeout from 30s to 60s
Result: Still times out, just takes longer

Root cause: Over-fetching 1000 records
Real fix: Add pagination (response <1s)
```

**Prevention**: Use 5 Whys to find root cause, don't stop at first symptom

---

### 🚫 No Tests for Bug Fix

**Impact**: Bug can be reintroduced, no regression detection

**Prevention**:
- Always add regression test for the bug
- Test should fail before fix, pass after fix
- Run test suite to ensure no other breakage

---

### 🚫 Trial-and-Error Debugging

**Impact**: Wasted time, incomplete understanding, fragile fixes

**Bad approach**:
```
1. Change timeout value → still broken
2. Add try/catch → hides error
3. Restart service → works temporarily
4. Don't know why it works, ship it
```

**Good approach**:
```
1. Reproduce error consistently
2. Add logging to isolate cause
3. Identify root cause with 5 Whys
4. Implement targeted fix
5. Add tests to prevent recurrence
6. Document in error-log.md
```

**Prevention**: Follow systematic debugging workflow

---

## Best Practices

### ✅ Systematic Debugging Workflow

**Follow consistent process**:
```markdown
1. Search error-log.md for similar errors
2. Reproduce error consistently
3. Classify error (type + severity)
4. Isolate root cause (5 Whys, logging, breakpoints)
5. Implement fix + tests
6. Prevent recurrence (defensive code + logging)
7. Document in error-log.md with ERR-XXXX
8. Commit with detailed message
```

**Result**: Faster debugging, knowledge accumulation, no recurrence

---

### ✅ Error Log Template

**Use consistent format**:
```markdown
## ERR-XXXX: [Short description]

**Date**: [ISO 8601 timestamp]
**Reporter**: [Name/email]
**Component**: [File/function name]
**Type**: [Syntax/Runtime/Logic/Integration/Performance]
**Severity**: [Critical/High/Medium/Low]

**Error Message**:
```
[Full stack trace]
```

**Steps to Reproduce**:
1. [Step 1]
2. [Step 2]
3. [Expected vs actual]

**Root Cause**:
[5 Whys analysis]

**Fix**:
[Specific code changes]

**Files Changed**:
- [file1]: [what changed]
- [file2]: [what changed]

**Prevention**:
- [Tests added]
- [Logging improved]
- [Defensive code]

**Related Errors**: [ERR-YYYY, ERR-ZZZZ] or None
**Status**: Fixed ([date]) or In Progress
```

---

### ✅ 5 Whys Root Cause Analysis

**Ask "why" 5 times**:
```markdown
1. Why did X fail? → Because Y
2. Why did Y happen? → Because Z
3. Why did Z happen? → Because A
4. Why did A happen? → Because B
5. Why did B happen? → Because [root cause]
```

**Stop when**: Reached actionable root cause (not symptoms)

---

## Phase Checklist

**Pre-phase checks**:
- [ ] Error can be reproduced
- [ ] Logs/stack traces available
- [ ] Development environment ready

**During phase**:
- [ ] Searched error-log.md for similar errors
- [ ] Error reproduced consistently
- [ ] Error classified (type + severity)
- [ ] Root cause identified (not symptoms)
- [ ] Fix implemented and tested
- [ ] Regression tests added
- [ ] Error documented in error-log.md

**Post-phase validation**:
- [ ] Fix verified (error no longer occurs)
- [ ] Tests pass (including new regression tests)
- [ ] error-log.md updated with ERR-XXXX
- [ ] Fix committed with detailed message
- [ ] workflow-state.yaml updated

---

## Quality Standards

**Debugging quality targets**:
- Average debug time: <2 hours
- Error recurrence rate: <10%
- Errors documented: 100%

**What makes good debugging**:
- Systematic approach (consistent workflow)
- Root cause identified (not symptoms)
- Fix tested (regression tests added)
- Well documented (error-log.md entry complete)
- Knowledge shared (prevents recurrence)

**What makes bad debugging**:
- Trial-and-error (no systematic approach)
- Treats symptoms (root cause unknown)
- No tests (bug can recur)
- Undocumented (knowledge lost)
- Quick workarounds (technical debt)

---

## Completion Criteria

**Phase is complete when**:
- [ ] Error no longer reproduces
- [ ] Root cause identified and fixed
- [ ] Tests added (regression + prevention)
- [ ] error-log.md updated with ERR-XXXX
- [ ] Fix committed
- [ ] workflow-state.yaml shows `currentPhase: debug` and `status: completed`

**Ready to proceed**:
- [ ] All tests pass
- [ ] Feature works as expected
- [ ] No known errors remaining

---

## Troubleshooting

**Issue**: Cannot reproduce error
**Solution**: Gather more context (logs, user steps, environment), check for timing/data dependencies

**Issue**: Error is intermittent
**Solution**: Identify conditions (timing, load, data state), add logging to narrow down triggers

**Issue**: Root cause unclear
**Solution**: Use 5 Whys, add more logging, use debugger/breakpoints, consult error-log.md patterns

**Issue**: Fix works but not sure why
**Solution**: Insufficient understanding - continue investigation, don't ship unclear fixes

---

_This SOP guides the debug phase. Refer to reference.md for debugging techniques and examples.md for debugging patterns._
