---
description: Debug errors and update error-log.md with systematic tracking
version: 2.0
updated: 2025-11-17
---

# /debug — Systematic Error Resolution

**Command**: `/debug [feature-slug] [flags]`

**Purpose**: Diagnose errors, route to the right specialist, apply fixes, and update `error-log.md` plus a machine-readable session report.

**When to use**:
- Test failures, build errors, runtime bugs, UI issues
- Performance regressions
- Auto-invoked by `/optimize` for code review issues

**Workflow position**: `implement → **debug** → optimize → preview → phase-1-ship`

---

## MENTAL MODEL

You are a **systematic debugger** with deterministic outputs and no interactive dead-ends.

**Modes**:

- **Manual**: You specify surface and error type (non-interactive by default)
- **Structured**: Called from `/optimize` with `--from-optimize` and issue metadata

**Philosophy**: Every error is a learning opportunity. Document failures, symptoms, root causes, and what was retired/corrected. The error-log.md becomes the project's debugging knowledge base.

**Outputs**:
- `specs/<slug>/error-log.md` (human-readable postmortem)
- `specs/<slug>/debug-session.json` (machine-readable session data)
- `specs/<slug>/debug/run-XXXXXX/` (step logs per session)

**Token efficiency**: Delegate to specialists, emit structured artifacts, fail fast with actionable errors.

---

## FLAGS

```bash
/debug [feature-slug] \
  [--from-optimize] \
  [--issue-id=CR### --severity=CRITICAL|HIGH|MEDIUM|LOW \
   --category=Contract|KISS|DRY|Security|Type|Test|Database \
   --file=path --line=N --description="..." --recommendation="..."] \
  [--type=test|build|runtime|ui|performance] \
  [--component=backend|frontend|database|integration] \
  [--non-interactive] [--json] [--deploy-diag] [--push]
```

**Flags**:

- `--from-optimize` — Structured mode (requires issue metadata)
- `--issue-id=CR###` — Code review issue ID
- `--severity=LEVEL` — CRITICAL|HIGH|MEDIUM|LOW
- `--category=TYPE` — Contract|KISS|DRY|Security|Type|Test|Database
- `--file=PATH` — File path with issue
- `--line=N` — Line number
- `--description="TEXT"` — Issue description
- `--recommendation="TEXT"` — Suggested fix
- `--type=TYPE` — Error type (test|build|runtime|ui|performance)
- `--component=COMP` — Component (backend|frontend|database|integration)
- `--non-interactive` — Never prompt; fail with actionable output
- `--json` — Print machine-readable summary to stdout
- `--deploy-diag` — Include optional platform diagnostics (slow)
- `--push` — Git push current branch after committing fix

---

<instructions>
## USER INPUT

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Execute Debug Workflow

Run the centralized spec-cli tool:

```bash
python .spec-flow/scripts/spec-cli.py debug "$ARGUMENTS"
```

**What the script does:**

1. **Parse arguments** — Extracts feature slug, flags, issue metadata
2. **Load feature** — Validates feature directory exists
3. **Create error log** — Initializes error-log.md template if missing
4. **Load debug context** — Shows recent error log entries and past blockers
5. **Reproduce & verify** — Runs lints, type checks, tests based on type/component
6. **Deployment diagnostics** — Optional platform checks (Vercel, Railway, GitHub Actions)
7. **Verification summary** — Aggregates lint_ok, types_ok, tests_ok status
8. **Update error log** — Appends new entry with timestamp, failure, symptom, learning
9. **Emit session JSON** — Creates debug-session.json with machine-readable data
10. **Commit & push** — Commits error-log.md and session artifacts (if verification passed)
11. **Output summary** — Displays verification status, logs location, session path

**After script completes, you (LLM) must:**

## 1) Review Debug Session Results

**Read session artifacts:**
- `specs/*/debug-session.json` (verification status, logs path, issue details)
- `specs/*/debug/run-XXXXXX/*.log` (test, lint, type check logs)
- `specs/*/error-log.md` (updated with new entry)

**Check verification status:**
```json
{
  "verification": "passed" | "failed",
  "logs": "/path/to/debug/run-XXXXXX"
}
```

## 2) Analyze Logs

**If verification failed:**
- Read log files in debug/run-XXXXXX/ directory
- Identify root cause from test failures, lint errors, type errors
- Determine fix strategy

**Common log files:**
- `ruff.log` — Backend linting errors
- `mypy.log` — Backend type errors
- `pytest.log` — Backend test failures
- `eslint.log` — Frontend linting errors
- `tsc.log` — Frontend type errors
- `test.log` — Frontend test failures
- `deploy-diag.txt` — Deployment platform diagnostics (if --deploy-diag used)

## 3) Present Results to User

**Summary format:**

```
Debug Session Complete

Feature: {slug}
Mode: {manual|structured}
Verification: {PASSED|FAILED}

Session logs: {path to debug/run-XXXXXX}
Session JSON: {path to debug-session.json}
Error log: {path to error-log.md (entry #)}

{If structured mode}
Issue: {issue_id}
Severity: {severity}
Category: {category}
File: {file}:{line}
```

## 4) Suggest Next Action

**If verification passed:**
```
✅ Debug session complete. Verification passed.

Error log updated with entry #{entry_num}
Session artifacts committed.

{If --push flag used}
⬆️ Changes pushed to {branch}

Next: Continue with /optimize or /implement
```

**If verification failed:**
```
❌ Verification failed

Check logs: {path to debug/run-XXXXXX}

Issues found:
  {List key errors from logs}

Artifacts staged but not committed.
Fix issues and re-run /debug.
```

**If from /optimize:**
```
{Return control to /optimize with issue resolution status}
```

</instructions>

---

## EXIT CODES

- `0` — All verification passed or at least artifacts committed cleanly
- `1` — Bad arguments, missing feature, or script error
- `2` — Verification failed (lint/types/tests)

---

## USAGE EXAMPLES

**Manual, non-interactive backend test run**:
```bash
/debug my-feature --type=test --component=backend --non-interactive
```

**From optimize (structured mode)**:
```bash
/debug --from-optimize --issue-id=CR031 --severity=HIGH \
  --category=Type --file=apps/app/src/foo.ts --line=88 \
  --description="Type mismatch..." --recommendation="Narrow union..." \
  --non-interactive --json
```

**With deploy diagnostics and push**:
```bash
/debug my-feature --type=build --component=frontend --deploy-diag --push
```

**Auto-detect from branch**:
```bash
/debug --type=runtime --component=backend --non-interactive
```

**JSON output for CI**:
```bash
/debug my-feature --type=test --component=backend --json > debug-report.json
```

---

## ERROR HANDLING

**Missing feature**: Dies with actionable error message and usage hint

**Missing tools (uv, pnpm, vercel, etc.)**: Warns in stderr, continues with available tools

**Verification failures**: Documents in session JSON and error-log.md, exits with code 2

**Git conflicts**: Aborts commit, instructs user to resolve conflicts first

**No reproduction**: Documents attempted steps in error-log with "Unable to reproduce" note

---

## OUTPUTS

**error-log.md** (human-readable):
```markdown
### Entry 3: 2025-11-10 - [CR031] Type Fix

**Failure**: Type mismatch in apps/app/src/foo.ts:88
**Symptom**: See session logs in debug/run-abc123
**Learning**: See delegation summary; root cause captured in session JSON
**Ghost Context Cleanup**: None

**From /optimize auto-fix** (Issue ID: CR031)
```

**debug-session.json** (machine-readable):
```json
{
  "feature": "my-feature",
  "mode": "structured",
  "type": "test",
  "component": "backend",
  "verification": "passed",
  "logs": "/absolute/path/to/debug/run-abc123",
  "issue": {
    "id": "CR031",
    "severity": "HIGH",
    "category": "Type",
    "file": "apps/app/src/foo.ts",
    "line": "88",
    "description": "Type mismatch...",
    "recommendation": "Narrow union..."
  },
  "timestamp": "2025-11-10T14:32:15Z"
}
```

---

## CONSTRAINTS

- ALWAYS update error-log.md (even if fix unsuccessful)
- Include timestamps (ISO-8601 UTC)
- Redact secret-like values in logs
- Commit error-log.md with fix (single atomic commit)
- One debugging session per `/debug` invocation
- In structured mode, return control to `/optimize` after completion
- Non-interactive by default (use `--non-interactive` to enforce)
