# Framework Templates for Regression Tests

Templates for generating regression tests across different test frameworks. Each template follows the Arrange-Act-Assert pattern and includes error traceability.

## Template Variables

All templates use these variables (replace with actual values):

| Variable | Description | Example |
|----------|-------------|---------|
| `{ERROR_ID}` | Error log ID | `ERR-0042` |
| `{ERROR_TITLE}` | Full error title | `Dashboard Timeout Due to Missing Pagination` |
| `{ERROR_TITLE_SHORT}` | Short title (for test name) | `Dashboard Timeout` |
| `{BUG_DESCRIPTION}` | What went wrong | `Dashboard fails to load, timeout after 30s` |
| `{ROOT_CAUSE}` | Why it happened | `Missing pagination parameter causes over-fetching` |
| `{DATE}` | Date fixed (ISO) | `2025-11-19` |
| `{ERROR_LOG_PATH}` | Path to error-log.md | `specs/001-dashboard/error-log.md` |
| `{SOURCE_PATH}` | Source file path | `src/services/StudentProgressService` |
| `{IMPORTS}` | Required imports | `StudentProgressService, fetchData` |
| `{TEST_NAME}` | Descriptive test name | `should_load_within_5s_when_fetching_student_data` |
| `{CONDITION}` | Trigger condition | `fetching large dataset` |
| `{EXPECTED_BEHAVIOR}` | What should happen | `return paginated results within 5 seconds` |
| `{ARRANGE_CODE}` | Setup code | `const service = new StudentProgressService();` |
| `{ACT_CODE}` | Action code | `const result = await service.fetchData(studentId);` |
| `{ASSERT_CODE}` | Assertion code | `expect(result.length).toBeLessThanOrEqual(10);` |
| `{ADDITIONAL_TESTS}` | Extra edge case tests | (optional) |
| `{FIXTURES}` | Test fixtures | (optional) |

---

## Jest / Vitest Template

**File extension**: `.test.ts` or `.test.js`
**Location**: `tests/regression/` or `__tests__/regression/`

```typescript
/**
 * Regression Test for {ERROR_ID}: {ERROR_TITLE}
 *
 * Bug: {BUG_DESCRIPTION}
 * Date Fixed: {DATE}
 * Root Cause: {ROOT_CAUSE}
 *
 * This test reproduces the bug scenario to prevent regression.
 * If this test fails, the bug from {ERROR_ID} may have been reintroduced.
 *
 * @see {ERROR_LOG_PATH}#{ERROR_ID}
 */
import { describe, test, expect, beforeEach, afterEach } from 'vitest'; // or '@jest/globals'
import { {IMPORTS} } from '{SOURCE_PATH}';

describe('Regression: {ERROR_ID} - {ERROR_TITLE_SHORT}', () => {
  // Setup and teardown
  beforeEach(() => {
    // Reset state before each test
  });

  afterEach(() => {
    // Cleanup after each test
  });

  test('should {EXPECTED_BEHAVIOR} when {CONDITION}', async () => {
    // ===== ARRANGE =====
    // Set up the bug scenario
    {ARRANGE_CODE}

    // ===== ACT =====
    // Execute the action that caused the bug
    {ACT_CODE}

    // ===== ASSERT =====
    // Verify correct behavior (would have failed before fix)
    {ASSERT_CODE}
  });

  {ADDITIONAL_TESTS}
});
```

### Jest Example (Completed)

```typescript
/**
 * Regression Test for ERR-0042: Dashboard Timeout Due to Missing Pagination
 *
 * Bug: Dashboard fails to load student data, timeout after 30 seconds
 * Date Fixed: 2025-11-19
 * Root Cause: API call fetched all records (1000+) without pagination parameter
 *
 * This test reproduces the bug scenario to prevent regression.
 * If this test fails, the bug from ERR-0042 may have been reintroduced.
 *
 * @see specs/001-dashboard/error-log.md#ERR-0042
 */
import { describe, test, expect, beforeEach } from '@jest/globals';
import { StudentProgressService } from '@/services/StudentProgressService';

describe('Regression: ERR-0042 - Dashboard Timeout', () => {
  let service: StudentProgressService;

  beforeEach(() => {
    service = new StudentProgressService();
  });

  test('should return paginated results within 5 seconds when fetching large dataset', async () => {
    // ===== ARRANGE =====
    const studentId = 123;
    const startTime = Date.now();

    // ===== ACT =====
    const result = await service.fetchExternalData(studentId);
    const duration = Date.now() - startTime;

    // ===== ASSERT =====
    // Results should be paginated (max 10 per page)
    expect(result.length).toBeLessThanOrEqual(10);
    // Should complete within 5 seconds (was 45s before fix)
    expect(duration).toBeLessThan(5000);
    // Pagination metadata should be present
    expect(result).toHaveProperty('hasNextPage');
  });

  test('should include pagination parameter in API call', async () => {
    // ===== ARRANGE =====
    const mockFetch = jest.spyOn(global, 'fetch');

    // ===== ACT =====
    await service.fetchExternalData(123);

    // ===== ASSERT =====
    expect(mockFetch).toHaveBeenCalledWith(
      expect.stringContaining('page_size=10'),
      expect.any(Object)
    );
  });
});
```

---

## pytest Template

**File extension**: `_test.py` or `test_*.py`
**Location**: `tests/regression/`

```python
"""
Regression Test for {ERROR_ID}: {ERROR_TITLE}

Bug: {BUG_DESCRIPTION}
Date Fixed: {DATE}
Root Cause: {ROOT_CAUSE}

This test reproduces the bug scenario to prevent regression.
If this test fails, the bug from {ERROR_ID} may have been reintroduced.

See: {ERROR_LOG_PATH}#{ERROR_ID}
"""
import pytest
from unittest.mock import patch, MagicMock
from {SOURCE_PATH} import {IMPORTS}


class TestRegression{ERROR_ID}:
    """Regression tests for {ERROR_ID}: {ERROR_TITLE_SHORT}"""

    {FIXTURES}

    def test_{TEST_NAME}_when_{CONDITION}(self):
        """Verify {EXPECTED_BEHAVIOR}

        This test would have failed before the fix was applied.
        Root cause: {ROOT_CAUSE}
        """
        # ===== ARRANGE =====
        {ARRANGE_CODE}

        # ===== ACT =====
        {ACT_CODE}

        # ===== ASSERT =====
        {ASSERT_CODE}

    {ADDITIONAL_TESTS}
```

### pytest Example (Completed)

```python
"""
Regression Test for ERR-0042: Dashboard Timeout Due to Missing Pagination

Bug: Dashboard fails to load student data, timeout after 30 seconds
Date Fixed: 2025-11-19
Root Cause: API call fetched all records (1000+) without pagination parameter

This test reproduces the bug scenario to prevent regression.
If this test fails, the bug from ERR-0042 may have been reintroduced.

See: specs/001-dashboard/error-log.md#ERR-0042
"""
import pytest
import time
from unittest.mock import patch
from app.services.student_progress_service import StudentProgressService


class TestRegressionERR0042:
    """Regression tests for ERR-0042: Dashboard Timeout"""

    @pytest.fixture
    def service(self):
        return StudentProgressService()

    @pytest.fixture
    def student_with_large_dataset(self):
        return 123  # Student ID with 1000+ records

    def test_returns_paginated_results_within_5_seconds_when_fetching_large_dataset(
        self, service, student_with_large_dataset
    ):
        """Verify paginated results returned quickly for large datasets

        This test would have failed before the fix was applied.
        Root cause: Missing pagination parameter caused 45s response time.
        """
        # ===== ARRANGE =====
        start_time = time.time()

        # ===== ACT =====
        result = service.fetch_external_data(student_with_large_dataset)
        duration = time.time() - start_time

        # ===== ASSERT =====
        # Results should be paginated (max 10 per page)
        assert len(result) <= 10
        # Should complete within 5 seconds (was 45s before fix)
        assert duration < 5.0
        # Pagination metadata should be present
        assert hasattr(result, 'has_next_page')

    def test_includes_pagination_parameter_in_api_call(self, service):
        """Verify API call includes pagination parameter"""
        # ===== ARRANGE =====
        with patch('app.services.external_api.get') as mock_get:
            mock_get.return_value = {'data': [], 'has_next_page': False}

            # ===== ACT =====
            service.fetch_external_data(student_id=123)

            # ===== ASSERT =====
            mock_get.assert_called_once()
            call_kwargs = mock_get.call_args[1]
            assert 'params' in call_kwargs
            assert call_kwargs['params'].get('page_size') == 10
```

---

## Playwright Template (E2E)

**File extension**: `.spec.ts`
**Location**: `tests/e2e/regression/` or `e2e/regression/`

```typescript
/**
 * Regression Test for {ERROR_ID}: {ERROR_TITLE}
 *
 * Bug: {BUG_DESCRIPTION}
 * Date Fixed: {DATE}
 * Root Cause: {ROOT_CAUSE}
 *
 * This E2E test reproduces the user flow that triggered the bug.
 *
 * @see {ERROR_LOG_PATH}#{ERROR_ID}
 */
import { test, expect } from '@playwright/test';

test.describe('Regression: {ERROR_ID} - {ERROR_TITLE_SHORT}', () => {
  test.beforeEach(async ({ page }) => {
    // Setup: Navigate to starting point
  });

  test('should {EXPECTED_BEHAVIOR} when {CONDITION}', async ({ page }) => {
    // ===== ARRANGE =====
    {ARRANGE_CODE}

    // ===== ACT =====
    {ACT_CODE}

    // ===== ASSERT =====
    {ASSERT_CODE}
  });

  {ADDITIONAL_TESTS}
});
```

### Playwright Example (Completed)

```typescript
/**
 * Regression Test for ERR-0042: Dashboard Timeout Due to Missing Pagination
 *
 * Bug: Dashboard page times out when loading student with large dataset
 * Date Fixed: 2025-11-19
 * Root Cause: Missing pagination caused 45s API response, exceeding 30s timeout
 *
 * This E2E test reproduces the user flow that triggered the bug.
 *
 * @see specs/001-dashboard/error-log.md#ERR-0042
 */
import { test, expect } from '@playwright/test';

test.describe('Regression: ERR-0042 - Dashboard Timeout', () => {
  test.beforeEach(async ({ page }) => {
    // Login as teacher
    await page.goto('/login');
    await page.getByLabel('Email').fill('teacher@example.com');
    await page.getByLabel('Password').fill('password');
    await page.getByRole('button', { name: 'Sign In' }).click();
    await expect(page).toHaveURL('/dashboard');
  });

  test('should load student dashboard within 5 seconds for large datasets', async ({ page }) => {
    // ===== ARRANGE =====
    const studentWithLargeDataset = 123;
    const startTime = Date.now();

    // ===== ACT =====
    await page.goto(`/dashboard/student/${studentWithLargeDataset}`);

    // Wait for data to load (should be fast with pagination)
    await expect(page.getByTestId('student-progress')).toBeVisible();
    const duration = Date.now() - startTime;

    // ===== ASSERT =====
    // Page should load within 5 seconds (was timing out at 30s before fix)
    expect(duration).toBeLessThan(5000);

    // Pagination controls should be visible (indicates paginated response)
    await expect(page.getByRole('button', { name: 'Next Page' })).toBeVisible();

    // Should show limited records (10 per page)
    const rows = page.getByTestId('progress-row');
    await expect(rows).toHaveCount(10);
  });

  test('should not show timeout error when loading large dataset', async ({ page }) => {
    // ===== ARRANGE =====
    const studentWithLargeDataset = 123;

    // ===== ACT =====
    await page.goto(`/dashboard/student/${studentWithLargeDataset}`);

    // ===== ASSERT =====
    // Error message should NOT appear
    await expect(page.getByText('Request timed out')).not.toBeVisible();
    await expect(page.getByText('Error loading data')).not.toBeVisible();

    // Success state should be shown
    await expect(page.getByTestId('student-progress')).toBeVisible();
  });
});
```

---

## Mocha/Chai Template

**File extension**: `.test.js` or `.spec.js`
**Location**: `test/regression/`

```javascript
/**
 * Regression Test for {ERROR_ID}: {ERROR_TITLE}
 *
 * Bug: {BUG_DESCRIPTION}
 * Date Fixed: {DATE}
 * Root Cause: {ROOT_CAUSE}
 *
 * @see {ERROR_LOG_PATH}#{ERROR_ID}
 */
const { expect } = require('chai');
const { {IMPORTS} } = require('{SOURCE_PATH}');

describe('Regression: {ERROR_ID} - {ERROR_TITLE_SHORT}', function() {
  beforeEach(function() {
    // Setup
  });

  afterEach(function() {
    // Cleanup
  });

  it('should {EXPECTED_BEHAVIOR} when {CONDITION}', async function() {
    // ===== ARRANGE =====
    {ARRANGE_CODE}

    // ===== ACT =====
    {ACT_CODE}

    // ===== ASSERT =====
    {ASSERT_CODE}
  });

  {ADDITIONAL_TESTS}
});
```

---

## Go Template

**File extension**: `_test.go`
**Location**: Same package as source or `regression/`

```go
// Regression Test for {ERROR_ID}: {ERROR_TITLE}
//
// Bug: {BUG_DESCRIPTION}
// Date Fixed: {DATE}
// Root Cause: {ROOT_CAUSE}
//
// See: {ERROR_LOG_PATH}#{ERROR_ID}
package {PACKAGE}

import (
	"testing"
	"time"
)

func TestRegression{ERROR_ID}_{TEST_NAME}(t *testing.T) {
	// ===== ARRANGE =====
	{ARRANGE_CODE}

	// ===== ACT =====
	start := time.Now()
	{ACT_CODE}
	duration := time.Since(start)

	// ===== ASSERT =====
	{ASSERT_CODE}
}

{ADDITIONAL_TESTS}
```

---

## Selection Guide

| Project Type | Framework | Extension | Location |
|--------------|-----------|-----------|----------|
| React/Next.js | Jest or Vitest | `.test.tsx` | `__tests__/regression/` |
| Node.js API | Jest | `.test.ts` | `tests/regression/` |
| Vue/Nuxt | Vitest | `.test.ts` | `tests/regression/` |
| Python/FastAPI | pytest | `test_*.py` | `tests/regression/` |
| Python/Django | pytest | `test_*.py` | `app/tests/regression/` |
| E2E (any) | Playwright | `.spec.ts` | `e2e/regression/` |
| Go | Go testing | `_test.go` | Same package |

---

## Best Practices for Templates

1. **Always include error ID** in file name, class/describe name, and comments
2. **Link to error-log.md** with full path
3. **Use descriptive test names** that explain expected behavior
4. **Keep setup minimal** - only what's needed to reproduce
5. **Assert specifically** - test the exact behavior that was broken
6. **Use accessible selectors** in E2E tests (getByRole, getByLabel)
7. **Document why** the test exists in comments
