<debugging_techniques>

<overview>
Systematic techniques for isolating root causes during debugging. Use these methods in Step 4 of debugging workflow.
</overview>

<techniques>

<technique name="binary_search">
**Binary Search Debugging**

**When to use**: Large codebase, unclear where error originates

**How it works**: Divide suspected code in half repeatedly until error isolated

**Steps**:
1. Identify suspected code region (e.g., lines 1-1000)
2. Add logging at midpoint (line 500)
3. Run code, check if error before or after midpoint
4. If before → investigate lines 1-500, if after → investigate lines 501-1000
5. Repeat until narrowed to specific function (5-10 iterations)

**Example**:

```python
# Suspected region: lines 1-1000
# Iteration 1: Add log at line 500
def process_data(data):
    # ... lines 1-499
    print(f"DEBUG: Checkpoint 1, data={data}")  # Line 500
    # ... lines 501-1000

# Error occurs before checkpoint → investigate lines 1-499
# Iteration 2: Add log at line 250
def process_data(data):
    # ... lines 1-249
    print(f"DEBUG: Checkpoint 2, data={data}")  # Line 250
    # ... lines 251-499

# Error occurs after checkpoint → investigate lines 251-499
# Iteration 3: Add log at line 375
# ... continue until error isolated to specific function
```

**Benefits**:
- Quickly narrows down error location (log₂(N) iterations)
- Works when stack trace unclear or misleading
- Minimal code changes required

**Tools**:
- `git bisect` (find commit that introduced bug)
- `console.log()`, `print()`, `logger.debug()` (manual checkpoints)
</technique>

<technique name="logging">
**Strategic Logging**

**When to use**: Unclear variable values, execution flow, or state

**How it works**: Add targeted logs to capture program state at key points

**Logging Levels**:
- **DEBUG**: Detailed information for debugging (variable values, execution flow)
- **INFO**: General informational messages (request started, user logged in)
- **WARN**: Warning messages (deprecated API used, slow query)
- **ERROR**: Error messages (exceptions, failures)

**Strategic Log Placement**:

```python
def fetchExternalData(student_id):
    # Entry log
    logger.debug(f"fetchExternalData called: student_id={student_id}")

    # Before external call
    logger.debug(f"Calling external API: url={api_url}, params={params}")
    response = api.get(api_url, params=params)

    # After external call
    logger.debug(f"API response: status={response.status}, data_len={len(response.data)}")

    # Before processing
    logger.debug(f"Processing data: count={len(response.data)}")
    processed = process(response.data)

    # Exit log
    logger.debug(f"fetchExternalData complete: result_count={len(processed)}")
    return processed
```

**What to Log**:
- Function entry/exit (with parameters and return values)
- External calls (API, database, file I/O)
- Conditional branches (which branch taken)
- Loop iterations (iteration count, current item)
- Error conditions (exceptions, validation failures)

**What NOT to Log**:
- Sensitive data (passwords, tokens, PII)
- Large payloads (entire response bodies, big arrays)
- Inside tight loops (causes performance issues)

**Tools**:
- Python: `logging` module
- Node.js: `winston`, `pino`, `bunyan`
- Browser: `console.log()`, `console.table()`, `console.trace()`

**Best Practices**:
- Use structured logging (JSON format for parsing)
- Include context (request ID, user ID, timestamp)
- Log at appropriate level (DEBUG in dev, INFO+ in prod)
- Use log rotation (prevent disk fill-up)
</technique>

<technique name="breakpoints">
**Interactive Debugging with Breakpoints**

**When to use**: Need to inspect live program state, step through execution

**How it works**: Pause execution at specific line, inspect variables, step through code

**Python (pdb)**:

```python
import pdb

def calculate_discount(price, discount_percent):
    pdb.set_trace()  # Breakpoint: execution pauses here
    discount = price * (discount_percent / 100)
    final_price = price - discount
    return final_price

# Run: python script.py
# Commands:
#   n (next) - execute next line
#   s (step) - step into function
#   c (continue) - continue execution
#   p variable - print variable value
#   l (list) - show current code location
#   q (quit) - exit debugger
```

**Node.js (node inspect)**:

```bash
# Run with debugger
node inspect server.js

# Commands:
#   n (next) - next line
#   s (step in) - step into function
#   o (step out) - step out of function
#   c (continue) - continue execution
#   repl - open REPL to inspect variables
```

**Browser (Chrome DevTools)**:

1. Open DevTools (F12)
2. Navigate to Sources tab
3. Click line number to set breakpoint
4. Reload page or trigger code
5. Execution pauses at breakpoint
6. Inspect variables in Scope panel
7. Step through code with controls

**VSCode Debugger**:

1. Add breakpoint (click left margin)
2. Press F5 to start debugging
3. Use debug controls (Step Over, Step Into, Continue)
4. Inspect variables in Variables panel
5. Watch expressions in Watch panel

**When Breakpoints Fail**:
- Production environment (can't attach debugger) → use logging
- Asynchronous code (breakpoint skipped) → use conditional breakpoints
- Intermittent errors (can't reliably trigger) → use logging with conditions

**Best Practices**:
- Set breakpoint just before suspected error
- Inspect all relevant variables
- Step through execution line-by-line
- Use conditional breakpoints (e.g., "only pause if user_id == 123")
</technique>

<technique name="rubber_duck">
**Rubber Duck Debugging**

**When to use**: Stuck on problem, no clear direction

**How it works**: Explain problem out loud to inanimate object (rubber duck)

**Steps**:
1. Get rubber duck (or any inanimate object)
2. Explain code line-by-line to duck
3. Describe what each line should do
4. Explain what's actually happening
5. Often, solution becomes obvious during explanation

**Why it works**:
- Forces you to articulate assumptions
- Slows down thinking (reveals overlooked details)
- Activates different brain pathways (verbal vs visual)

**Example**:

```
You: "Okay duck, so this function takes a user ID and fetches their profile."
You: "First, it calls the database... wait, it's calling getUserById() but passing 'name' instead of 'id'."
You: "Oh! That's the bug. I'm passing the wrong parameter."

[Bug found without duck saying a word]
```

**Alternative**: Explain to colleague, write detailed bug report, or use AI assistant
</technique>

<technique name="hypothesis_testing">
**Scientific Method: Hypothesis Testing**

**When to use**: Multiple possible causes, unclear which is root cause

**How it works**: Form hypothesis, test with minimal change, validate or reject

**Steps**:
1. Observe error
2. Form hypothesis (educated guess about cause)
3. Design experiment (minimal code change to test hypothesis)
4. Run experiment
5. Validate or reject hypothesis
6. Repeat until root cause found

**Example**:

```
Error: Dashboard timeout after 30 seconds

Hypothesis 1: Timeout value too short
Test: Increase timeout from 30s → 60s
Result: Still times out after 60s → Hypothesis REJECTED

Hypothesis 2: API response too slow
Test: Log API response time
Result: API takes 45 seconds → Hypothesis CONFIRMED

Hypothesis 3: Requesting too much data
Test: Log data size
Result: 1000 records fetched, should be 10 → Hypothesis CONFIRMED

Root cause: Missing pagination parameter causes over-fetching
```

**Best Practices**:
- Change ONE thing at a time (isolate variable)
- Document each hypothesis and result
- Don't skip hypotheses (test systematically)
- Accept when hypothesis rejected (learn from failures)

**Anti-pattern**: Trial and error (random changes without hypothesis)
</technique>

<technique name="divide_and_conquer">
**Divide and Conquer**

**When to use**: Complex system with many components, unclear which failing

**How it works**: Test components in isolation to identify failing component

**Steps**:
1. Identify system components (frontend, backend, database, external API)
2. Test each component independently
3. Isolate failing component
4. Narrow down within component (repeat divide and conquer)

**Example**:

```
Error: Dashboard shows "No data available"

Test 1: Frontend fetch() call
- Open Network tab in DevTools
- Check if API request sent: ✅ Yes
- Check if response received: ✅ Yes (200 OK)
- Conclusion: Frontend OK, not the issue

Test 2: Backend API response
- Check API logs
- Verify API received request: ✅ Yes
- Verify API queried database: ✅ Yes
- Check response payload: ❌ Empty array
- Conclusion: Backend returns empty data, possible issue

Test 3: Database query
- Run SQL query directly in database
- Check if data exists: ✅ Yes, 100 records
- Check if query correct: ❌ WHERE clause filters out all records
- Conclusion: Database query has incorrect WHERE clause

Root cause: Incorrect WHERE clause in database query
```

**Tools**:
- cURL (test API endpoints directly)
- Database client (test queries directly)
- Postman (test API with different inputs)
- Unit tests (test functions in isolation)

**Benefits**:
- Quickly eliminates large sections of code
- Identifies integration issues (component A → B handoff)
- Works for distributed systems (microservices, APIs)
</technique>

<technique name="git_bisect">
**Git Bisect (Find Breaking Commit)**

**When to use**: Error didn't exist before, need to find commit that introduced it

**How it works**: Binary search through git history to find breaking commit

**Steps**:

```bash
# Start bisect
git bisect start

# Mark current commit as bad (error present)
git bisect bad

# Mark known good commit (error not present)
git bisect good abc123

# Git checks out middle commit, test it
npm test

# If test passes (good)
git bisect good

# If test fails (bad)
git bisect bad

# Repeat until git identifies breaking commit
# Git will output: "abc123 is the first bad commit"

# End bisect
git bisect reset
```

**Example**:

```
Current commit (HEAD): Error present → mark as bad
Commit from 2 weeks ago: Error not present → mark as good

Git bisects:
- Commit from 1 week ago: Test → FAIL (bad)
- Commit from 10 days ago: Test → PASS (good)
- Commit from 9 days ago: Test → FAIL (bad)

Result: Commit abc123 (9 days ago) introduced error
Review commit: "feat: add pagination to API"
Root cause identified: Pagination logic broken
```

**Best Practices**:
- Use automated tests (faster than manual testing)
- Start with wide range (recent good commit far back)
- Document breaking commit hash for future reference

**Tools**:
- `git bisect run <test-command>` (automate bisect with test script)
</technique>

<technique name="printf_debugging">
**Printf Debugging (Caveman Debugging)**

**When to use**: Quick debugging, no debugger available, simple issues

**How it works**: Add print statements to trace execution

**Python**:

```python
def calculate_total(items):
    print(f"DEBUG: calculate_total called with {len(items)} items")
    total = 0
    for item in items:
        print(f"DEBUG: Processing item: {item}, current total: {total}")
        total += item.price
    print(f"DEBUG: Final total: {total}")
    return total
```

**JavaScript**:

```javascript
function calculateTotal(items) {
    console.log('DEBUG: calculate_total called with', items.length, 'items');
    let total = 0;
    for (const item of items) {
        console.log('DEBUG: Processing item:', item, 'current total:', total);
        total += item.price;
    }
    console.log('DEBUG: Final total:', total);
    return total;
}
```

**Benefits**:
- Fast (no debugger setup)
- Works in any environment (even production with logging)
- Simple to understand

**Drawbacks**:
- Requires code changes (add/remove prints)
- Output can be overwhelming (too many prints)
- Can't inspect complex objects easily

**Best Practices**:
- Prefix with "DEBUG:" for easy filtering
- Remove print statements after debugging
- Use proper logging framework in production
</technique>

</techniques>

<choosing_technique>

**Quick Reference**:

| Situation | Recommended Technique |
|-----------|----------------------|
| Large codebase, unclear location | Binary Search, Git Bisect |
| Need variable values | Logging, Printf Debugging |
| Complex execution flow | Breakpoints, Debugger |
| Stuck, no ideas | Rubber Duck Debugging |
| Multiple possible causes | Hypothesis Testing |
| Distributed system | Divide and Conquer |
| Regression (worked before) | Git Bisect |
| Quick check | Printf Debugging |

**Combine Techniques**:
- Git Bisect → find breaking commit → Breakpoints to debug that commit
- Hypothesis Testing → form hypothesis → Logging to validate
- Divide and Conquer → isolate component → Binary Search within component

</choosing_technique>

</debugging_techniques>
