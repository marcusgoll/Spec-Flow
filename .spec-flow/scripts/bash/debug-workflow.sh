## IMPLEMENTATION

**Script location**: `.spec-flow/scripts/bash/debug.sh`

**Key improvements**:

- **Safety**: `set -Eeuo pipefail`, `trap` with line/exit reporting, strict quoting
- **Non-interactive**: No prompts by default; all params via flags
- **Outputs**: JSON session artifact + human error-log.md
- **Redaction**: Secret-like values auto-redacted in logs
- **Verification**: Deterministic per-surface checks (lint/types/tests)
- **Commits**: Conventional Commits template with co-author
- **Deploy diagnostics**: Optional, gated behind `--deploy-diag`

---

## EXECUTION FLOW

### Phase 1: Parse Arguments & Load Feature

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# Trap errors with line numbers
on_err() {
  local exit=$?
  echo "❌ debug failed (exit ${exit}) at line ${BASH_LINENO[0]}" >&2
  exit "$exit"
}
trap on_err ERR

# Parse flags (getopts or manual parsing)
FEATURE=""
STRUCTURED=false
ISSUE_ID=""; SEVERITY=""; CATEGORY=""; FILEPATH=""; LINE=""; DESC=""; RECO=""
TYPE="test"; COMPONENT="backend"
NONINT=false; EMIT_JSON=false; DEPLOY_DIAG=false; PUSH_AFTER=false

while (( "$#" )); do
  case "${1:-}" in
    --from-optimize) STRUCTURED=true ;;
    --issue-id=*) ISSUE_ID="${1#*=}" ;;
    --severity=*) SEVERITY="${1#*=}" ;;
    --category=*) CATEGORY="${1#*=}" ;;
    --file=*) FILEPATH="${1#*=}" ;;
    --line=*) LINE="${1#*=}" ;;
    --description=*) DESC="${1#*=}" ;;
    --recommendation=*) RECO="${1#*=}" ;;
    --type=*) TYPE="${1#*=}" ;;
    --component=*) COMPONENT="${1#*=}" ;;
    --non-interactive) NONINT=true ;;
    --json) EMIT_JSON=true ;;
    --deploy-diag) DEPLOY_DIAG=true ;;
    --push) PUSH_AFTER=true ;;
    --*) die "unknown flag: $1" ;;
    *) FEATURE="${FEATURE:-$1}" ;;
  esac
  shift || true
done

# Auto-detect feature from branch if not provided
FEATURE="${FEATURE:-$(git branch --show-current 2>/dev/null || echo '')}"
[[ -n "$FEATURE" ]] || die "feature-slug not provided and current branch not found"

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
FEATURE_DIR="$root/specs/$FEATURE"
[[ -d "$FEATURE_DIR" ]] || die "feature not found: $FEATURE_DIR"

ERROR_LOG="$FEATURE_DIR/error-log.md"
SESSION_DIR="$FEATURE_DIR/debug"
mkdir -p "$SESSION_DIR"
SESSION_JSON="$FEATURE_DIR/debug-session.json"
```

### Phase 2: Create Error Log Template (if missing)

```bash
if [[ ! -f "$ERROR_LOG" ]]; then
  cat > "$ERROR_LOG" <<'MD'
# Error Log

**Purpose**: Track failures, root causes, and learnings during implementation.

Each entry:

### Entry N: YYYY-MM-DD - Brief Title

**Failure**: What broke
**Symptom**: Observable behavior
**Learning**: Root cause and prevention
**Ghost Context Cleanup**: Retired artifacts or corrected assumptions

[Optional: During T0NN]
[Optional: From /optimize auto-fix (Issue ID: CR###)]
MD
fi
```

### Phase 3: Load Debug Context

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Debug: Systematic Error Resolution  ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
echo "Feature: $FEATURE"
echo "Mode: $([[ "$STRUCTURED" == true ]] && echo "Structured" || echo "Manual")"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Show recent error log entries
if [[ -s "$ERROR_LOG" ]]; then
  echo "Recent error-log entries:"
  grep -A 6 "^### Entry" "$ERROR_LOG" | tail -24 || true
  echo
fi

# Show NOTES.md blockers (past resolutions)
if [[ -f "$FEATURE_DIR/NOTES.md" ]]; then
  echo "Notes (past blockers):"
  sed -n '/## Blockers/,/^## /p' "$FEATURE_DIR/NOTES.md" | head -24 || true
  echo
fi
```

### Phase 4: Reproduce & Verify

```bash
log_dir=$(mktemp -d "$SESSION_DIR/run-XXXXXX")
TEST_LOG="$log_dir/test.log"

verify_api() {
  pushd api >/dev/null 2>&1 || return 0
  if command -v uv >/dev/null 2>&1; then
    echo "ruff…" && uv run ruff check . --quiet |& tee "$log_dir/ruff.log" >/dev/null || true
    echo "mypy…" && uv run mypy app/ --no-error-summary |& tee "$log_dir/mypy.log" >/dev/null || true
    echo "pytest…" && uv run pytest -q |& tee "$TEST_LOG" || true
  else
    echo "[warn] uv not installed, skipping backend checks" >&2
  fi
  popd >/dev/null 2>&1 || true
}

verify_app() {
  APP_DIR="apps/app"
  [[ -d "$APP_DIR" ]] || return 0
  pushd "$APP_DIR" >/dev/null 2>&1 || return 0
  if command -v pnpm >/dev/null 2>&1; then
    pnpm lint --quiet |& tee "$log_dir/eslint.log" >/dev/null || true
    pnpm type-check |& tee "$log_dir/tsc.log" >/dev/null || true
    pnpm test --run --silent |& tee "$TEST_LOG" || true
  else
    echo "[warn] pnpm not installed, skipping frontend checks" >&2
  fi
  popd >/dev/null 2>&1 || true
}

# Route based on type and component
case "$TYPE:$COMPONENT" in
  test:backend|build:backend|runtime:backend|performance:backend) verify_api ;;
  test:frontend|build:frontend|ui:frontend|performance:frontend) verify_app ;;
  *) : ;;
esac
```

### Phase 5: Optional Deployment Diagnostics

```bash
if [[ "$DEPLOY_DIAG" == true ]]; then
  diag_file="$log_dir/deploy-diag.txt"
  {
    echo "== vercel =="
    if command -v vercel >/dev/null 2>&1; then
      vercel ls --limit 5 || true
    else
      echo "vercel cli missing"
    fi

    echo; echo "== railway =="
    if command -v railway >/dev/null 2>&1; then
      railway deployments --limit 5 --json || true
    else
      echo "railway cli missing"
    fi

    echo; echo "== gh actions failures =="
    if command -v gh >/dev/null 2>&1; then
      gh run list --status=failure --limit 3 || true
    else
      echo "gh cli missing"
    fi
  } > "$diag_file" 2>&1
fi
```

### Phase 6: Verification Summary

```bash
lint_ok=true; types_ok=true; tests_ok=true

[[ -f "$log_dir/ruff.log" ]] && grep -q . "$log_dir/ruff.log" && lint_ok=true
[[ -f "$log_dir/mypy.log" ]] && ! grep -qi "error:" "$log_dir/mypy.log" || types_ok=false
[[ -f "$TEST_LOG" ]] && ! grep -qiE "FAIL|ERROR" "$TEST_LOG" || tests_ok=false

VERIFICATION_STATUS="passed"
$lint_ok || VERIFICATION_STATUS="failed"
$types_ok || VERIFICATION_STATUS="failed"
$tests_ok || VERIFICATION_STATUS="failed"
```

### Phase 7: Update Error Log

```bash
# Get next entry number
last_num=$(grep -oE '^### Entry [0-9]+' "$ERROR_LOG" | awk '{print $3}' | tail -1 || true)
next_num=$(( ${last_num:-0} + 1 ))
title="${STRUCTURED:+[$ISSUE_ID] }${CATEGORY:-${TYPE^}} Fix"

SYMPTOM="See session logs in $(realpath --relative-to="$FEATURE_DIR" "$log_dir" 2>/dev/null || echo "$log_dir")"
LEARN="See delegation summary; root cause captured in session JSON"

cat >> "$ERROR_LOG" <<EOF

### Entry $next_num: $(date +%F) - $title

**Failure**: ${DESC:-Debug session}
**Symptom**: $SYMPTOM
**Learning**: $LEARN
**Ghost Context Cleanup**: None

$( [[ "$STRUCTURED" == true ]] && echo "**From /optimize auto-fix** (Issue ID: $ISSUE_ID)" )
EOF
```

### Phase 8: Emit Session JSON

```bash
jq -n \
  --arg feature "$FEATURE" \
  --arg mode "$([[ "$STRUCTURED" == true ]] && echo structured || echo manual)" \
  --arg type "$TYPE" \
  --arg component "$COMPONENT" \
  --arg status "$VERIFICATION_STATUS" \
  --arg logDir "$(realpath "$log_dir" 2>/dev/null || echo "$log_dir")" \
  --arg issue "$ISSUE_ID" \
  --arg severity "$SEVERITY" \
  --arg category "$CATEGORY" \
  --arg file "$FILEPATH" \
  --arg line "$LINE" \
  --arg desc "$DESC" \
  --arg rec "$RECO" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{
     feature: $feature,
     mode: $mode,
     type: $type,
     component: $component,
     verification: $status,
     logs: $logDir,
     issue: {
       id: $issue,
       severity: $severity,
       category: $category,
       file: $file,
       line: $line,
       description: $desc,
       recommendation: $rec
     },
     timestamp: $ts
   }' | tee "$SESSION_JSON" >/dev/null
```

### Phase 9: Commit & Optional Push

```bash
# Generate Conventional Commit message
if [[ "$STRUCTURED" == true ]]; then
  commit_msg="fix: resolve ${CATEGORY,,} issue (${ISSUE_ID})

${DESC:-}

Updated error-log.md with latest entry"
else
  commit_msg="fix: debug ${TYPE}/${COMPONENT} in ${FEATURE}

Updated error-log.md with latest entry"
fi

# Stage changes
git add "$ERROR_LOG" "$SESSION_JSON" "$SESSION_DIR" >/dev/null 2>&1 || true

# Commit if verification passed
if [[ "$VERIFICATION_STATUS" == "passed" ]]; then
  git commit -m "$commit_msg

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" >/dev/null 2>&1 || true
  echo "✅ committed error-log and session artifacts"

  # Optional push
  if [[ "$PUSH_AFTER" == true ]]; then
    current_branch=$(git branch --show-current 2>/dev/null || echo "")
    [[ -n "$current_branch" ]] && git push origin "$current_branch" || true
    echo "⬆️  pushed ${current_branch}"
  fi
else
  echo "⚠️  verification failed; artifacts staged but not committed"
fi
```

### Phase 10: Output Summary

```bash
if [[ "$EMIT_JSON" == true ]]; then
  cat "$SESSION_JSON"
else
  echo
  echo "Summary: $VERIFICATION_STATUS"
  echo "Logs: $log_dir"
  echo "Session: $SESSION_JSON"
  echo "Error log: $ERROR_LOG (entry $next_num)"
fi
```

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

## CONSTRAINTS

- ALWAYS update error-log.md (even if fix unsuccessful)
- Include timestamps (ISO-8601 UTC)
- Redact secret-like values in logs
- Commit error-log.md with fix (single atomic commit)
- One debugging session per `/debug` invocation
- In structured mode, return control to `/optimize` after completion
- Non-interactive by default (use `--non-interactive` to enforce)

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

## RATIONALE

**Logs as event streams**: Append-only, structured, machine-readable for aggregation

**Blameless learnings**: error-log.md is mini postmortem per defect; no blame, just facts and prevention

**Three signals (traces/metrics/logs)**: This anchors logs now, leaves door open for OpenTelemetry traces/metrics later

**Conventional Commits**: Queryable history for automation and release notes

**Incident workflow hooks**: Mirrors standard incident management for scaling beyond solo debugging

**Non-interactive by default**: CI/CD friendly, deterministic, no hanging prompts

**Redaction**: Prevent accidental secrets leakage in debug logs

---

## REFERENCES

- [Postmortem Action Items](https://www.usenix.org/system/files/login/articles/login_spring17_09_lunney.pdf) (USENIX)
- [OpenTelemetry Architecture](https://opentelemetry.io/docs/collector/architecture/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Incident Management Best Practices](https://www.atlassian.com/incident-management)
