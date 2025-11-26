<error_log_template>

<overview>
Complete template for documenting errors in error-log.md with ERR-XXXX IDs. Use this template in Step 7 of debugging workflow to create comprehensive error documentation.
</overview>

<template>

```markdown
## ERR-XXXX: [Brief Error Title]

**Date**: YYYY-MM-DD
**Severity**: [Critical|High|Medium|Low]
**Type**: [Syntax|Runtime|Logic|Integration|Performance]
**Component**: [ComponentName.methodName() or file:line]
**Reporter**: [Who found it: QA, user, monitoring, dev]

### Error Description

[1-2 sentences describing what happened from user perspective]

**Reproduction Steps**:
1. [Step 1]
2. [Step 2]
3. [Error occurs]

**Expected Behavior**: [What should happen]
**Actual Behavior**: [What actually happens]

### Stack Trace / Error Message

```
[Paste full stack trace or error message here]
```

### Root Cause

[1-2 paragraphs explaining the underlying issue, not symptoms]

**5 Whys Analysis**:
1. Why? [Symptom level]
2. Why? [Deeper]
3. Why? [Deeper]
4. Why? [Deeper]
5. Why? [Root cause]

**Root cause**: [Concise statement of actual problem]

### Fix Implemented

[What was changed to fix the root cause]

**Changes**:
- [Change 1 with rationale]
- [Change 2 with rationale]

**Performance Impact**: [Before → After metrics if applicable]

### Files Changed

- `path/to/file1.ext` (lines X-Y) - [What changed]
- `path/to/file2.ext` (lines A-B) - [What changed]

### Tests Added

**Unit Tests**:
- `test_name()` - [What it validates]

**Integration Tests**:
- `test_name()` - [What it validates]

**Regression Prevention**: [How tests prevent recurrence]

### Prevention

[What was added to prevent this class of errors in the future]

- [ ] Tests added (unit + integration)
- [ ] Monitoring/alerting added
- [ ] Documentation updated
- [ ] Code review checklist updated
- [ ] Validation added (input, schema, type)

### Related Errors

[Link to similar past errors if pattern exists]

- Similar to ERR-XXXX ([link])
- Pattern: [Common root cause across errors]
- Recommendation: [System-level fix if applicable]

### Rollback Plan

[How to undo this fix if it causes issues]

**Rollback Steps**:
1. [Step 1]
2. [Step 2]

**Rollback Risk**: [None|Low|Medium|High]
```

</template>

<examples>

<example scenario="integration_error">

```markdown
## ERR-0042: Dashboard Timeout Due to Missing Pagination

**Date**: 2025-11-19
**Severity**: High
**Type**: Integration
**Component**: StudentProgressService.fetchExternalData()
**Reporter**: QA team (staging environment)

### Error Description

Dashboard fails to load student progress data, showing timeout error after 30 seconds. Affects all teachers attempting to view student progress.

**Reproduction Steps**:
1. Log in as teacher
2. Navigate to /dashboard/student/123
3. Page loads for 30 seconds, then shows "Request timeout" error

**Expected Behavior**: Dashboard loads in <3 seconds with student data
**Actual Behavior**: Page times out after 30 seconds

### Stack Trace / Error Message

```
Error: Request timeout after 30000ms
  at StudentProgressService.fetchExternalData (services/progress.ts:45)
  at DashboardController.getStudentProgress (controllers/dashboard.ts:89)
  at async fetch (/dashboard/student/123)
```

### Root Cause

API call to external service was missing pagination parameter, causing over-fetching of 1000+ records instead of paginated 10 records. External service took 45 seconds to respond with large dataset, exceeding 30-second client timeout.

**5 Whys Analysis**:
1. Why did dashboard fail to load?
   → API call to external service timed out
2. Why did API call timeout?
   → Request took >30 seconds (timeout limit)
3. Why did request take >30 seconds?
   → External service response time was 45 seconds
4. Why was external service so slow?
   → Requesting too much data (1000 records instead of 10)
5. Why requesting 1000 records?
   → Missing pagination parameter in API call

**Root cause**: Missing pagination parameter causes over-fetching

### Fix Implemented

Added `page_size` parameter (default 10) to `fetchExternalData()` method. Modified API call to include pagination params.

**Changes**:
- Added optional `page_size` parameter with default value 10
- Modified API request to include `?page_size=10` query parameter
- Response now includes pagination metadata (`has_next_page`, `next_cursor`)

**Performance Impact**: Response time reduced from 45s → 2s (95% improvement)

### Files Changed

- `src/services/StudentProgressService.ts` (lines 45-52) - Added page_size parameter, modified API call
- `tests/StudentProgressService.test.ts` (new file) - Added unit and integration tests

### Tests Added

**Unit Tests**:
- `test_pagination_parameter_included()` - Verifies pagination parameter passed to API

**Integration Tests**:
- `test_dashboard_loads_with_large_datasets()` - Ensures dashboard loads within 5s with large datasets

**Regression Prevention**: Tests will fail if pagination parameter is removed or API call times out >5s

### Prevention

- [x] Tests added (2 unit tests, 1 integration test)
- [x] Monitoring/alerting added (alert if response time >10s)
- [x] Documentation updated (API usage guide: always paginate)
- [x] Code review checklist updated (check for pagination in external API calls)
- [ ] Validation added (not applicable)

### Related Errors

- Similar to ERR-0015 (pagination missing in different service)
- Pattern: Always include pagination for external API calls
- Recommendation: Create shared API client utility with pagination built-in

### Rollback Plan

Rollback removes pagination parameter, restoring original behavior (slow but functional)

**Rollback Steps**:
1. Git revert commit abc123
2. Deploy to staging
3. Verify dashboard loads (slowly)

**Rollback Risk**: Low (original code works, just slow)
```

</example>

<example scenario="runtime_error">

```markdown
## ERR-0091: Null Pointer Exception in Profile Edit

**Date**: 2025-11-20
**Severity**: High
**Type**: Runtime
**Component**: ProfileController.updateProfile()
**Reporter**: User report (production crash)

### Error Description

Application crashes when user attempts to update profile without uploading a new avatar image. Affects ~20% of profile updates.

**Reproduction Steps**:
1. Log in as user
2. Navigate to /profile/edit
3. Change name (do NOT upload new avatar)
4. Click "Save"
5. Application crashes with "Cannot read property 'url' of undefined"

**Expected Behavior**: Profile updates successfully without avatar upload
**Actual Behavior**: Application crashes

### Stack Trace / Error Message

```
TypeError: Cannot read property 'url' of undefined
  at ProfileController.updateProfile (controllers/profile.ts:78)
  at async POST /api/profile/update
```

### Root Cause

Code assumed avatar file would always be present in request, but avatar upload is optional. When user doesn't upload new avatar, `req.files.avatar` is undefined, causing null pointer exception when accessing `avatar.url`.

**5 Whys Analysis**:
1. Why did application crash?
   → Tried to access `avatar.url` but `avatar` was undefined
2. Why was avatar undefined?
   → User didn't upload new avatar (optional field)
3. Why did code try to access undefined avatar?
   → No null check before accessing `avatar.url`
4. Why no null check?
   → Developer assumed avatar always present
5. Why assume avatar always present?
   → Missing validation, no type guards

**Root cause**: Missing null check for optional avatar upload

### Fix Implemented

Added null check and type guard for optional avatar upload. If avatar present, update URL; if not, keep existing avatar.

**Changes**:
- Added null check: `if (req.files?.avatar) { ... }`
- Preserve existing avatar if no new upload
- Added TypeScript type guard for type safety

**Performance Impact**: None (logic fix only)

### Files Changed

- `src/controllers/ProfileController.ts` (lines 75-82) - Added null check and type guard
- `tests/ProfileController.test.ts` (lines 120-135) - Added test for optional avatar

### Tests Added

**Unit Tests**:
- `test_update_profile_without_avatar()` - Verifies profile updates work without avatar upload
- `test_update_profile_with_avatar()` - Verifies avatar URL updates when uploaded

**Regression Prevention**: Test explicitly checks optional avatar scenario, will fail if null check removed

### Prevention

- [x] Tests added (2 unit tests)
- [x] Monitoring/alerting added (alert on runtime exceptions)
- [ ] Documentation updated (not needed, code self-documenting)
- [x] Code review checklist updated (check for null safety on optional fields)
- [x] Validation added (TypeScript optional type `avatar?: File`)

### Related Errors

- Similar to ERR-0023 (null pointer on optional field)
- Pattern: Always validate optional fields before accessing properties
- Recommendation: Enable TypeScript strict mode (`strictNullChecks: true`)

### Rollback Plan

Rollback removes null check, restoring crash behavior (not recommended)

**Rollback Steps**:
1. Git revert commit def456
2. Deploy to staging
3. Verify crash reproduces (for testing only)

**Rollback Risk**: High (crash will recur, not recommended to rollback)
```

</example>

</examples>

<filling_out_template>

**ERR-XXXX ID**:
- Sequential number (e.g., ERR-0001, ERR-0042, ERR-0091)
- Check existing error-log.md for next available number
- Format: ERR-[four digits]

**Brief Error Title**:
- Concise, descriptive (≤10 words)
- Examples: "Dashboard Timeout Due to Missing Pagination", "Null Pointer Exception in Profile Edit"

**Date**:
- Date error was first reported or discovered
- Format: YYYY-MM-DD

**Severity**:
- Critical, High, Medium, or Low
- See error-classification.md for criteria

**Type**:
- Syntax, Runtime, Logic, Integration, or Performance
- See error-classification.md for definitions

**Component**:
- Specific function or file causing error
- Format: `ClassName.methodName()` or `path/to/file.ts:line`

**Reporter**:
- Who discovered the error: QA, user report, monitoring alert, developer

**Error Description**:
- 1-2 sentences from user perspective
- Include reproduction steps (numbered list)
- State expected vs actual behavior

**Stack Trace / Error Message**:
- Paste full stack trace or error message
- Include file paths and line numbers
- Wrap in code block for readability

**Root Cause**:
- 1-2 paragraphs explaining underlying issue
- Use 5 Whys analysis to drill down
- State root cause concisely at end

**Fix Implemented**:
- What was changed (not how)
- Include performance metrics if applicable (before → after)

**Files Changed**:
- List each file with line numbers
- Brief description of what changed

**Tests Added**:
- List unit tests with descriptions
- List integration tests with descriptions
- Explain how tests prevent recurrence

**Prevention**:
- Checklist of preventive measures
- Tests, monitoring, documentation, validation

**Related Errors**:
- Link to similar past errors
- Identify patterns across errors
- Recommend system-level fixes if applicable

**Rollback Plan**:
- Steps to undo fix if it causes issues
- Assess rollback risk (None/Low/Medium/High)

</filling_out_template>

<best_practices>

**Do**:
- Use 5 Whys to find root cause (not symptoms)
- Include full stack trace for runtime errors
- Document performance impact (before → after)
- Link related errors to identify patterns
- Write rollback plan for high-risk fixes

**Don't**:
- Document symptoms instead of root causes
- Skip tests section (regression prevention critical)
- Leave "Related Errors" empty (always check for patterns)
- Forget to update error-log.md after every fix
- Use vague descriptions ("fixed bug" → specific change)

</best_practices>

</error_log_template>
