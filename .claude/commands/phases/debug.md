---
name: debug
description: Execute systematic debugging workflow via spec-cli.py, track failures in error-log.md, and generate session reports
argument-hint: "[feature-slug] [--from-optimize] [--issue-id=...] [--severity=...] [--type=...] [--component=...] [--non-interactive] [--json] [--deploy-diag] [--push] [--dry-run]"
allowed-tools: [Bash(python .spec-flow/scripts/spec-cli.py:*), Read, Grep, Glob]
---

# /debug — Systematic Error Resolution

<context>
**User Input**: $ARGUMENTS

**Current Branch**: !`git branch --show-current 2>/dev/null || echo "none"`

**Feature Slug**: !`git branch --show-current 2>/dev/null | sed 's/^feature\///' || echo "unknown"`

**Recent Debug Sessions**: !`ls -1t specs/*/debug-session.json 2>/dev/null | head -3 || echo "none"`

**Recent Errors**: !`tail -20 specs/*/error-log.md 2>/dev/null | grep "^###" | head -3 || echo "none"`

**Git Status**: !`git status --short 2>/dev/null || echo "clean"`

**Debug Session Artifacts** (after script execution):
- @specs/*/debug-session.json
- @specs/*/debug/run-XXXXXX/*.log
- @specs/*/error-log.md
</context>

<objective>
Systematically debug errors using spec-cli.py, track failures in error-log.md, and generate machine-readable session reports.

Execute debugging workflow by:
1. Running centralized debug script with arguments: $ARGUMENTS
2. Analyzing verification status (lint, types, tests)
3. Reading log files if verification failed
4. Presenting results with actionable next steps
5. Updating error knowledge base (error-log.md)

**Modes**:
- **Manual**: User specifies error type and component (non-interactive by default)
- **Structured**: Auto-invoked by `/optimize` with issue metadata (--from-optimize)

**Philosophy**: Every error is a learning opportunity. Document failures, symptoms, root causes, and fixes. The error-log.md becomes the project's debugging knowledge base.

**Workflow position**: `implement → debug → optimize → preview → ship`
</objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent fabricating debug results.

1. **Never claim script success without reading artifacts**
   - Always Read debug-session.json to verify status
   - Quote actual verification result: "passed" or "failed"
   - Cite log files: "See specs/my-feature/debug/run-abc123/pytest.log:45"

2. **Always read log files if verification failed**
   - Don't guess at errors - read actual log content
   - Quote verbatim error messages with file:line references
   - Show stack traces or lint errors from logs

3. **Never invent fix recommendations**
   - If script provides recommendation, quote it exactly
   - If no recommendation, say "Manual investigation required"
   - Don't suggest fixes without analyzing actual error output

4. **Verify artifacts exist before claiming completion**
   - Check error-log.md was updated (read latest entry)
   - Confirm debug-session.json exists and is valid JSON
   - Verify log directory created: specs/*/debug/run-XXXXXX/

5. **Never assume git operations succeeded**
   - If --push flag used, verify with git log
   - Check git status after script to confirm commits
   - Quote actual commit message from git log

**Why this matters**: Fabricated debug results hide real issues. Accurate artifact reading ensures debugging sessions are reproducible and errors are properly documented.

---

<process>

### Step 0: Dry-Run Mode Detection

**Check for --dry-run flag** (see `.claude/skills/dry-run/SKILL.md`):

```bash
DRY_RUN="false"
if [[ "$ARGUMENTS" == *"--dry-run"* ]]; then
  DRY_RUN="true"
  ARGUMENTS=$(echo "$ARGUMENTS" | sed 's/--dry-run//g' | xargs)
  echo "DRY-RUN MODE ENABLED"
fi
```

**If DRY_RUN is true:**

Output dry-run summary and exit:

```
════════════════════════════════════════════════════════════════════════════════
DRY-RUN MODE: No changes will be made
════════════════════════════════════════════════════════════════════════════════

📋 COMMAND: /debug $ARGUMENTS

📋 CONTEXT THAT WOULD BE READ:
  • Current branch: $(git branch --show-current)
  • Feature slug: extracted from branch or argument
  • Recent debug sessions: specs/*/debug-session.json
  • Recent errors: specs/*/error-log.md

🔧 SCRIPT THAT WOULD EXECUTE:
  python .spec-flow/scripts/spec-cli.py debug "$ARGUMENTS"

  Script operations:
    1. Parse arguments (feature slug, flags, issue metadata)
    2. Load feature directory and validate existence
    3. Initialize error-log.md template if missing
    4. Show recent error log entries (context)
    5. Run verification (lint, types, tests based on --type/--component)
    6. Optional: Deployment diagnostics (if --deploy-diag)
    7. Aggregate verification summary
    8. Update error-log.md with timestamped entry
    9. Emit debug-session.json
    10. Commit artifacts if verification passed
    11. Display summary

📁 FILES THAT WOULD BE CREATED:
  ✚ specs/[slug]/debug-session.json (machine-readable session data)
  ✚ specs/[slug]/debug/run-XXXXXX/ (directory for this session)
  ✚ specs/[slug]/debug/run-XXXXXX/*.log (verification logs)

📝 FILES THAT WOULD BE MODIFIED:
  ✎ specs/[slug]/error-log.md
    + New entry: "### Entry N: YYYY-MM-DD HH:MM:SS UTC"
    + Symptoms, root cause, fix applied
    + Regression test reference (if generated)

🧪 REGRESSION TEST (if bug found):
  ✚ tests/regression/regression-ERR-XXXX-[slug].test.ts
    - Arrange-Act-Assert pattern
    - Linked to error-log.md entry

🔀 GIT OPERATIONS (if verification passes):
  • git add specs/[slug]/error-log.md specs/[slug]/debug-session.json
  • git commit -m "debug: session complete for [feature-slug]"
  • git push origin [branch] (if --push flag)

📊 EXIT CODES:
  • 0 = Verification passed, artifacts committed
  • 1 = Bad arguments or script error
  • 2 = Verification failed, artifacts created but not committed

════════════════════════════════════════════════════════════════════════════════
DRY-RUN COMPLETE: 0 actual changes made
Run `/debug $ARGUMENTS` (without --dry-run) to execute
════════════════════════════════════════════════════════════════════════════════
```

**Exit after dry-run summary. Do NOT proceed to script execution.**

---

### Step 1: Execute Debug Script

Run the centralized spec-cli tool with user arguments:

```bash
python .spec-flow/scripts/spec-cli.py debug "$ARGUMENTS"
```

**Script operations** (automated):
1. Parse arguments (feature slug, flags, issue metadata)
2. Load feature directory and validate existence
3. Initialize error-log.md template if missing
4. Show recent error log entries and past blockers (context)
5. Reproduce & verify (runs lints, type checks, tests based on --type/--component)
6. Optional: Deployment diagnostics (if --deploy-diag flag)
7. Aggregate verification summary (lint_ok, types_ok, tests_ok)
8. Update error-log.md with new timestamped entry
9. Emit debug-session.json (machine-readable session data)
10. Commit artifacts if verification passed (optional: --push to remote)
11. Display summary (verification status, logs location, session path)

### Step 2: Review Debug Session Results

**Read session artifacts** using Read tool:
- `specs/*/debug-session.json` — Verification status, logs path, issue details
- `specs/*/error-log.md` — Latest entry added by script

**Check verification status** from debug-session.json:
```json
{
  "verification": "passed" | "failed",
  "logs": "/absolute/path/to/debug/run-XXXXXX",
  "feature": "feature-slug",
  "mode": "manual" | "structured"
}
```

### Step 3: Analyze Logs (If Verification Failed)

**If verification = "failed"**:
1. Read log files in `specs/*/debug/run-XXXXXX/` directory
2. Identify root cause from error messages
3. Quote verbatim errors with file:line references
4. Determine fix strategy

**Common log files**:
- `ruff.log` — Backend linting errors
- `mypy.log` — Backend type errors
- `pytest.log` — Backend test failures
- `eslint.log` — Frontend linting errors
- `tsc.log` — Frontend type errors
- `test.log` — Frontend test failures
- `deploy-diag.txt` — Deployment diagnostics (if --deploy-diag used)

### Step 3.5: Generate Regression Test (Auto)

After identifying root cause, automatically generate a regression test to prevent bug recurrence.

**Extract bug details**:
- Error ID (from error-log.md entry number, e.g., `ERR-XXXX`)
- Title (brief description of the bug)
- Symptoms (observable behavior from logs)
- Root cause (from 5 Whys analysis in Step 3)
- Component (affected file:function from stack trace)

**Generate regression test**:

```bash
.spec-flow/scripts/bash/regression-test-generator.sh \
  --error-id "ERR-XXXX" \
  --title "Brief bug description" \
  --symptoms "Observable error behavior" \
  --root-cause "Why the bug occurred" \
  --component "src/path/file.ts:functionName" \
  --feature-dir "$FEATURE_DIR"
```

**Present to user for review**:

```
=== Regression Test Generated ===

Error: ERR-XXXX - {title}
File:  tests/regression/regression-ERR-XXXX-slug.test.ts

[Generated test code displayed]

This test will:
- Capture the bug scenario to prevent regression
- Fail before fix (proves bug exists)
- Pass after fix (validates solution)

What would you like to do?
  [A] Save test and continue
  [B] Edit test before saving
  [C] Skip generation (add to tech debt)
```

**User response handling**:
- **A (Save)**: Test file already written by script, update error-log.md with reference
- **B (Edit)**: Allow user to modify, then save updated version
- **C (Skip)**: Log skip reason in NOTES.md as technical debt

**Update error-log.md** with regression test reference:

```markdown
**Regression Test**:
- **File**: `tests/regression/regression-ERR-XXXX-slug.test.ts`
- **Status**: Generated
- **Validates**: {what the test checks}
```

**Verify test behavior**:
- If bug not yet fixed: Test should FAIL (proves bug exists)
- If bug already fixed: Test should PASS (validates fix)

**Skip conditions**:
- Skip if `--from-optimize` with `--non-interactive` (auto-fix mode)
- Skip if user explicitly declines with option C

### Step 4: Present Results to User

**Summary format**:

```
Debug Session Complete

Feature: {slug from debug-session.json}
Mode: {manual|structured from debug-session.json}
Verification: {PASSED|FAILED from debug-session.json}

Session logs: {logs path from debug-session.json}
Session JSON: {path to debug-session.json}
Error log: {path to error-log.md with entry number}

{If structured mode (--from-optimize)}
Issue: {issue_id from debug-session.json}
Severity: {severity}
Category: {category}
File: {file}:{line}
```

### Step 5: Suggest Next Action

**If verification = "passed"**:
```
✅ Debug session complete. Verification passed.

Error log updated with entry #{entry_num from error-log.md}
Session artifacts committed to git.

{If --push flag used}
⬆️ Changes pushed to {branch from git log}

Next: Continue with /optimize or /implement
```

**If verification = "failed"**:
```
❌ Verification failed

Check logs: {logs path from debug-session.json}

Issues found:
{List key errors quoted from log files}

Artifacts staged but not committed.
Fix issues and re-run /debug.
```

**If from /optimize (--from-optimize flag)**:
```
{Return control to /optimize with issue resolution status}
Status: {verification status}
Issue {issue_id}: {resolved|requires manual fix}
```

</process>

<success_criteria>
**Debug session successfully completed when:**

1. **Script executed without errors**:
   - Exit code 0 (verification passed and artifacts committed)
   - OR exit code 2 (verification failed but artifacts created)
   - Not exit code 1 (script error or bad arguments)

2. **Artifacts created**:
   - debug-session.json exists with valid JSON
   - error-log.md updated with new timestamped entry
   - Log directory created: specs/*/debug/run-XXXXXX/
   - Log files present (ruff.log, pytest.log, etc.)

3. **Verification status determined**:
   - debug-session.json contains "verification": "passed" or "failed"
   - Status matches actual log analysis

4. **Results presented to user**:
   - Summary displayed with feature, mode, verification status
   - Log paths provided for failed verification
   - Next action suggested based on verification outcome

5. **Git operations completed** (if verification passed):
   - error-log.md and debug-session.json committed
   - If --push flag: changes pushed to remote branch
   - Git status clean or only working tree changes remain

6. **Structured mode completion** (if --from-optimize):
   - Control returned to /optimize with resolution status
   - Issue metadata preserved in debug-session.json

7. **Regression test generated** (unless skipped):
   - Test file created in `tests/regression/` or project test location
   - Test follows Arrange-Act-Assert pattern
   - Test linked in error-log.md entry
   - Test staged for commit (or skip reason logged in NOTES.md)
</success_criteria>

<verification>
**Before marking debug session complete, verify:**

1. **Read debug-session.json**:
   ```bash
   cat specs/*/debug-session.json
   ```
   Confirm valid JSON with verification status

2. **Check error-log.md updated**:
   ```bash
   tail -20 specs/*/error-log.md
   ```
   Should show new entry with current timestamp

3. **Verify log directory exists**:
   ```bash
   ls -la specs/*/debug/run-*/
   ```
   Should show recent run-XXXXXX directory with log files

4. **Confirm git commits** (if verification passed):
   ```bash
   git log -1 --oneline
   ```
   Should show "debug: session complete" or similar commit

5. **Validate log files** (if verification failed):
   ```bash
   ls specs/*/debug/run-XXXXXX/*.log
   ```
   Should contain relevant log files for component type

6. **Check push status** (if --push flag used):
   ```bash
   git status
   ```
   Should show "Your branch is up to date" or ahead/behind status

**Never claim completion without reading debug-session.json and error-log.md.**
</verification>

<output>
**Files created/modified by this command:**

**Debug artifacts** (specs/NNN-slug/):
- error-log.md — Updated with new timestamped entry (### Entry N: YYYY-MM-DD)
- debug-session.json — Machine-readable session data with verification status
- debug/run-XXXXXX/ — Directory containing log files for this session

**Log files** (specs/NNN-slug/debug/run-XXXXXX/):
- ruff.log — Backend linting errors (if backend component)
- mypy.log — Backend type errors (if backend component)
- pytest.log — Backend test failures (if backend component)
- eslint.log — Frontend linting errors (if frontend component)
- tsc.log — Frontend type errors (if frontend component)
- test.log — Frontend test failures (if frontend component)
- deploy-diag.txt — Deployment diagnostics (if --deploy-diag flag)

**Git commits** (if verification passed):
- Commit message: "debug: session complete for [feature-slug]"
- Changed files: error-log.md, debug-session.json

**Console output**:
- Verification summary (PASSED or FAILED)
- Log paths for investigation
- Next action recommendation
</output>

---

## Quick Reference

### Exit Codes
- `0` — Verification passed, artifacts committed
- `1` — Bad arguments, missing feature, or script error
- `2` — Verification failed (lint/types/tests), artifacts created but not committed

### Common Usage Patterns

**Manual backend test debugging**:
```bash
/debug my-feature --type=test --component=backend --non-interactive
```

**From /optimize (structured mode)**:
```bash
/debug --from-optimize --issue-id=CR031 --severity=HIGH \
  --category=Type --file=src/foo.ts --line=88 \
  --description="Type mismatch" --recommendation="Narrow union"
```

**With deployment diagnostics**:
```bash
/debug my-feature --type=build --component=frontend --deploy-diag --push
```

### Available Flags

**Mode flags**:
- `--from-optimize` — Structured mode (requires issue metadata)
- `--non-interactive` — Never prompt; fail with actionable output
- `--json` — Print machine-readable summary to stdout
- `--dry-run` — Preview operations without executing (no files created, no scripts run)

**Issue metadata** (required with --from-optimize):
- `--issue-id=CR###` — Code review issue ID
- `--severity=CRITICAL|HIGH|MEDIUM|LOW`
- `--category=Contract|KISS|DRY|Security|Type|Test|Database`
- `--file=PATH --line=N` — Issue location
- `--description="TEXT"` — Issue description
- `--recommendation="TEXT"` — Suggested fix

**Debug options**:
- `--type=test|build|runtime|ui|performance` — Error type
- `--component=backend|frontend|database|integration` — Component to check
- `--deploy-diag` — Include platform diagnostics (slower)
- `--push` — Git push after successful commit

### Constraints
- ALWAYS update error-log.md (even if verification fails)
- Include ISO-8601 UTC timestamps
- Redact secret-like values in logs
- Single atomic commit per debugging session
- In structured mode, return control to /optimize after completion
