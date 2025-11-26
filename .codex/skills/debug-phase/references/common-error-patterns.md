<common_error_patterns>

<overview>
Frequently occurring error patterns with root causes, fixes, and prevention strategies. Use this reference to quickly identify and resolve common issues.
</overview>

<patterns>

<pattern name="missing_pagination">
**Missing Pagination**

**Symptoms**:
- API timeout when fetching large datasets
- Slow page load times (>5 seconds)
- Memory exhaustion (OOM errors)
- Database query scans entire table

**Root Cause**:
- Fetching all records instead of paginating (e.g., 1000 records instead of 10)
- No LIMIT clause in SQL queries
- API client doesn't request pagination

**Example**:

```python
# ❌ BAD: Fetches all records
def get_users():
    return db.query("SELECT * FROM users")  # Could be 10,000 users

# ✅ GOOD: Paginated query
def get_users(page=1, page_size=10):
    offset = (page - 1) * page_size
    return db.query(
        "SELECT * FROM users LIMIT :limit OFFSET :offset",
        limit=page_size,
        offset=offset
    )
```

**Fix**:
- Add pagination parameters (`page`, `page_size`, `limit`, `offset`)
- Implement cursor-based pagination for large datasets
- Add LIMIT clause to SQL queries

**Prevention**:
- Always paginate external API calls
- Set default page size (e.g., 10, 25, 50)
- Add performance tests for large datasets
- Monitor query response times

**Related Errors**: ERR-0042, ERR-0015, ERR-0089
</pattern>

<pattern name="null_pointer">
**Null Pointer / Undefined Property Access**

**Symptoms**:
- `TypeError: Cannot read property 'x' of undefined` (JavaScript)
- `NullPointerException` (Java)
- `AttributeError: 'NoneType' object has no attribute 'x'` (Python)
- Application crashes when accessing optional field

**Root Cause**:
- Accessing property of null/undefined object
- Missing null check before property access
- Assuming optional field always present

**Example**:

```javascript
// ❌ BAD: No null check
function getUserEmail(user) {
    return user.profile.email;  // Crashes if profile is null
}

// ✅ GOOD: Null check
function getUserEmail(user) {
    return user?.profile?.email ?? 'No email';  // Optional chaining
}

// ✅ GOOD: Validation
function getUserEmail(user) {
    if (!user || !user.profile) {
        throw new Error('Invalid user object');
    }
    return user.profile.email;
}
```

**Fix**:
- Add null checks before property access
- Use optional chaining (`?.`) in JavaScript/TypeScript
- Use default values (`??`, `||`)
- Validate input at function entry

**Prevention**:
- Enable TypeScript strict mode (`strictNullChecks: true`)
- Use type guards for optional fields
- Validate API responses before processing
- Add unit tests for null/undefined scenarios

**Related Errors**: ERR-0091, ERR-0023, ERR-0067
</pattern>

<pattern name="race_condition">
**Race Condition**

**Symptoms**:
- Intermittent errors (works sometimes, fails other times)
- Data inconsistency (wrong values, duplicates)
- Deadlocks or timeouts
- Tests pass individually but fail when run together

**Root Cause**:
- Multiple operations on shared state without synchronization
- Async operations complete in unexpected order
- No locking mechanism for critical sections

**Example**:

```javascript
// ❌ BAD: Race condition
let counter = 0;

async function incrementCounter() {
    const current = counter;  // Read
    await delay(10);          // Simulate async work
    counter = current + 1;    // Write
}

// If called twice concurrently:
// Thread 1: Read 0 → Write 1
// Thread 2: Read 0 → Write 1
// Result: counter = 1 (should be 2)

// ✅ GOOD: Atomic operation
let counter = 0;

async function incrementCounter() {
    counter++;  // Atomic in JavaScript (single-threaded)
}

// ✅ GOOD: Mutex lock (for complex operations)
const mutex = new Mutex();

async function updateBalance(amount) {
    await mutex.acquire();
    try {
        const balance = await getBalance();
        await setBalance(balance + amount);
    } finally {
        mutex.release();
    }
}
```

**Fix**:
- Use atomic operations (e.g., `counter++`, `INCR` in Redis)
- Use mutex/lock for critical sections
- Use database transactions for multi-step updates
- Use queue for ordered processing

**Prevention**:
- Identify shared state in code
- Use immutability where possible
- Add concurrency tests (spawn multiple threads/promises)
- Use linting rules to detect race conditions

**Related Errors**: ERR-0134, ERR-0201, ERR-0098
</pattern>

<pattern name="n_plus_one">
**N+1 Query Problem**

**Symptoms**:
- Slow API responses (>1s)
- Hundreds of database queries for single request
- Database CPU spike
- ORM generates excessive queries

**Root Cause**:
- Fetching related data in loop (1 query + N queries)
- ORM lazy-loading relationships
- No eager loading or JOIN

**Example**:

```python
# ❌ BAD: N+1 queries
users = User.query.all()  # 1 query: SELECT * FROM users
for user in users:
    print(user.posts)  # N queries: SELECT * FROM posts WHERE user_id = ?

# Total: 1 + N queries (if 100 users → 101 queries)

# ✅ GOOD: Single query with JOIN
users = User.query.options(
    joinedload(User.posts)
).all()  # 1 query: SELECT * FROM users LEFT JOIN posts ...

for user in users:
    print(user.posts)  # No additional queries

# Total: 1 query
```

**Fix**:
- Use eager loading (`joinedload`, `includes`, `preload`)
- Use database JOINs instead of loops
- Batch queries (fetch all IDs, then query once)
- Use DataLoader pattern (GraphQL)

**Prevention**:
- Monitor database query count per request
- Use query profiling tools (Django Debug Toolbar, Rails Bullet)
- Add performance tests (assert query count < threshold)
- Review ORM queries in development

**Related Errors**: ERR-0056, ERR-0178, ERR-0203
</pattern>

<pattern name="off_by_one">
**Off-by-One Error**

**Symptoms**:
- Array index out of bounds
- Loop executes one too many/few times
- Wrong calculation results (e.g., discount = 11% instead of 10%)
- Missing first or last item

**Root Cause**:
- Inclusive vs exclusive range confusion
- Zero-indexed vs one-indexed arrays
- Incorrect loop boundary (`<` vs `<=`)

**Example**:

```python
# ❌ BAD: Off-by-one (misses last item)
items = [1, 2, 3, 4, 5]
for i in range(len(items) - 1):  # Range: 0-3, misses index 4
    print(items[i])
# Output: 1, 2, 3, 4 (missing 5)

# ✅ GOOD: Correct range
items = [1, 2, 3, 4, 5]
for i in range(len(items)):  # Range: 0-4, all items
    print(items[i])
# Output: 1, 2, 3, 4, 5

# ✅ BETTER: Pythonic iteration
items = [1, 2, 3, 4, 5]
for item in items:
    print(item)
```

**Fix**:
- Use inclusive iteration (`for item in items`) instead of indices
- Double-check loop boundaries (`<` vs `<=`)
- Test with edge cases (empty array, single item, multiple items)

**Prevention**:
- Prefer high-level iteration over manual indexing
- Write tests for boundary cases (0, 1, n-1, n)
- Use linting rules to catch common patterns
- Review loop logic during code review

**Related Errors**: ERR-0045, ERR-0123, ERR-0189
</pattern>

<pattern name="uncaught_promise">
**Uncaught Promise Rejection**

**Symptoms**:
- `UnhandledPromiseRejectionWarning` in Node.js
- Silent failures (no error shown)
- Application doesn't crash but feature broken

**Root Cause**:
- Promise rejection not caught with `.catch()` or `try/catch`
- Async function error not handled
- Missing error handler in Promise chain

**Example**:

```javascript
// ❌ BAD: Uncaught rejection
async function fetchData() {
    const response = await fetch('/api/data');
    return response.json();  // May fail if response not JSON
}

fetchData();  // If fails, rejection unhandled

// ✅ GOOD: Error handling
async function fetchData() {
    try {
        const response = await fetch('/api/data');
        if (!response.ok) {
            throw new Error(`HTTP error: ${response.status}`);
        }
        return await response.json();
    } catch (error) {
        console.error('Failed to fetch data:', error);
        throw error;  // Re-throw or handle appropriately
    }
}

// ✅ GOOD: .catch() handler
fetchData()
    .then(data => console.log(data))
    .catch(error => console.error('Error:', error));
```

**Fix**:
- Add `.catch()` to all Promise chains
- Wrap async calls in `try/catch`
- Add global unhandled rejection handler (for logging)

**Prevention**:
- Enable strict promise handling in linter (ESLint)
- Add global error handlers:
  ```javascript
  process.on('unhandledRejection', (reason, promise) => {
      console.error('Unhandled Rejection:', reason);
  });
  ```
- Use async/await with try/catch (clearer than .catch())
- Add error handling tests

**Related Errors**: ERR-0078, ERR-0156, ERR-0234
</pattern>

<pattern name="memory_leak">
**Memory Leak**

**Symptoms**:
- Application memory usage grows over time
- Application crashes with OOM (Out of Memory)
- Slow performance after hours/days of uptime
- Heap size increases continuously

**Root Cause**:
- Event listeners not removed
- Timers not cleared (`setTimeout`, `setInterval`)
- References held in closures
- Large objects not garbage collected

**Example**:

```javascript
// ❌ BAD: Memory leak (event listener not removed)
class Component {
    constructor() {
        window.addEventListener('resize', this.handleResize);
    }

    handleResize() {
        // Handle resize
    }

    destroy() {
        // ❌ Forgot to remove event listener
        // Component instance never garbage collected
    }
}

// ✅ GOOD: Remove event listener
class Component {
    constructor() {
        this.handleResize = this.handleResize.bind(this);
        window.addEventListener('resize', this.handleResize);
    }

    handleResize() {
        // Handle resize
    }

    destroy() {
        window.removeEventListener('resize', this.handleResize);
        // Component can now be garbage collected
    }
}
```

**Fix**:
- Remove event listeners in cleanup (`destroy`, `componentWillUnmount`)
- Clear timers (`clearTimeout`, `clearInterval`)
- Remove references to large objects
- Use WeakMap/WeakSet for caches

**Prevention**:
- Monitor memory usage in production (Datadog, New Relic)
- Profile with heap snapshots (Chrome DevTools, Node.js `--inspect`)
- Add cleanup methods to all components
- Use memory profiling tools during development

**Related Errors**: ERR-0098, ERR-0167, ERR-0221
</pattern>

<pattern name="timezone_date">
**Timezone/Date Handling Issues**

**Symptoms**:
- Dates off by one day
- Time shows incorrectly in different timezones
- Date calculations wrong (e.g., age calculation)

**Root Cause**:
- Mixing UTC and local time
- Using `new Date()` without timezone consideration
- Daylight saving time transitions

**Example**:

```javascript
// ❌ BAD: Timezone issues
const date = new Date('2025-11-19');  // Parsed as UTC 00:00
console.log(date.toLocaleDateString());  // May show 11/18 in PST

// ✅ GOOD: Explicit UTC handling
const date = new Date('2025-11-19T00:00:00Z');  // Explicit UTC
console.log(date.toISOString());  // Always UTC

// ✅ GOOD: Use date library (date-fns, luxon)
import { parseISO, format } from 'date-fns';
const date = parseISO('2025-11-19');
console.log(format(date, 'yyyy-MM-dd'));
```

**Fix**:
- Store dates in UTC (database, API)
- Convert to local timezone only for display
- Use ISO 8601 format (`YYYY-MM-DDTHH:mm:ssZ`)
- Use date libraries (date-fns, luxon, moment.js)

**Prevention**:
- Always use UTC in backend
- Use timezone-aware date libraries
- Test with different timezones (UTC, PST, EST, GMT)
- Validate date inputs (reject ambiguous formats)

**Related Errors**: ERR-0089, ERR-0145, ERR-0198
</pattern>

<pattern name="encoding_issues">
**Character Encoding Issues**

**Symptoms**:
- Special characters display as � or ???
- Emoji broken (shows as boxes)
- Text truncated or corrupted
- Different languages display incorrectly

**Root Cause**:
- Incorrect character encoding (ASCII instead of UTF-8)
- Mixing encodings (UTF-8 → Latin-1)
- Database column charset mismatch

**Example**:

```python
# ❌ BAD: Encoding issues
with open('file.txt', 'r') as f:  # Defaults to system encoding
    data = f.read()  # May fail on non-ASCII characters

# ✅ GOOD: Explicit UTF-8
with open('file.txt', 'r', encoding='utf-8') as f:
    data = f.read()
```

**Fix**:
- Use UTF-8 everywhere (files, database, API)
- Set encoding explicitly in file operations
- Configure database with UTF-8 charset
- Set HTTP `Content-Type: charset=utf-8` header

**Prevention**:
- Standardize on UTF-8 across entire stack
- Test with non-ASCII characters (emoji, Chinese, accents)
- Validate text encoding in CI pipeline
- Use Unicode-aware string functions

**Related Errors**: ERR-0112, ERR-0176, ERR-0209
</pattern>

</patterns>

<detection_checklist>

When debugging, check for these common patterns:

**Performance Issues**:
- [ ] Missing pagination (fetching all records)
- [ ] N+1 query problem (loop with database calls)
- [ ] Memory leak (event listeners, timers)

**Crash Issues**:
- [ ] Null pointer (accessing property of undefined)
- [ ] Uncaught promise rejection (missing .catch())
- [ ] Off-by-one error (array bounds)

**Data Issues**:
- [ ] Race condition (concurrent access to shared state)
- [ ] Timezone/date handling (mixing UTC and local)
- [ ] Character encoding (non-ASCII characters)

If error matches known pattern, apply documented fix. If new pattern emerges (>3 similar errors), document in this file.

</detection_checklist>

</common_error_patterns>
