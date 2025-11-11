#!/usr/bin/env bash
set -Eeuo pipefail

# -----------------------------------------------------------------------------
# /debug [feature-slug] [flags]
# Systematic error resolution with machine-readable outputs
# -----------------------------------------------------------------------------

# --- traps -------------------------------------------------------------------
on_err() {
  local exit=$?
  echo "❌ debug failed (exit ${exit}) at line ${BASH_LINENO[0]}" >&2
  exit "$exit"
}
trap on_err ERR

# --- helpers -----------------------------------------------------------------
die() { echo "❌ $*" >&2; exit 1; }
has() { command -v "$1" >/dev/null 2>&1; }
ts() { date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ; }

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$root"

# --- args --------------------------------------------------------------------
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
    --help|-h)
      echo "Usage: debug.sh [feature-slug] [flags]"
      echo ""
      echo "Flags:"
      echo "  --from-optimize         Structured mode (from /optimize)"
      echo "  --issue-id=CR###        Code review issue ID"
      echo "  --severity=LEVEL        CRITICAL|HIGH|MEDIUM|LOW"
      echo "  --category=TYPE         Contract|KISS|DRY|Security|Type|Test|Database"
      echo "  --file=PATH             File path with issue"
      echo "  --line=N                Line number"
      echo "  --description=\"TEXT\"    Issue description"
      echo "  --recommendation=\"TEXT\" Suggested fix"
      echo "  --type=TYPE             test|build|runtime|ui|performance"
      echo "  --component=COMP        backend|frontend|database|integration"
      echo "  --non-interactive       Never prompt (default)"
      echo "  --json                  Output JSON to stdout"
      echo "  --deploy-diag           Include platform diagnostics"
      echo "  --push                  Push after committing"
      exit 0
      ;;
    --*) die "unknown flag: $1" ;;
    *) FEATURE="${FEATURE:-$1}" ;;
  esac
  shift || true
done

# --- resolve feature ---------------------------------------------------------
FEATURE="${FEATURE:-$(git branch --show-current 2>/dev/null || echo '')}"
[[ -n "$FEATURE" ]] || die "feature-slug not provided and current branch not found"

FEATURE_DIR="$root/specs/$FEATURE"
[[ -d "$FEATURE_DIR" ]] || die "feature not found: $FEATURE_DIR"

ERROR_LOG="$FEATURE_DIR/error-log.md"
SESSION_DIR="$FEATURE_DIR/debug"
mkdir -p "$SESSION_DIR"
SESSION_JSON="$FEATURE_DIR/debug-session.json"

NOTES_FILE="$FEATURE_DIR/NOTES.md"
SPEC_FILE="$FEATURE_DIR/spec.md"
TASKS_FILE="$FEATURE_DIR/tasks.md"

# --- validate structured mode ------------------------------------------------
if [[ "$STRUCTURED" == true ]]; then
  [[ -n "$ISSUE_ID" && -n "$SEVERITY" && -n "$CATEGORY" && -n "$FILEPATH" ]] \
    || die "structured mode requires: --issue-id, --severity, --category, --file"

  # Infer FEATURE from FILEPATH if possible
  if [[ "$FILEPATH" =~ specs/([^/]+)/ ]]; then
    FEATURE="${BASH_REMATCH[1]}"
    FEATURE_DIR="$root/specs/$FEATURE"
  fi
fi

# --- ensure error-log exists -------------------------------------------------
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

# --- load context snippets ---------------------------------------------------
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Debug: Systematic Error Resolution  ($(ts))"
echo "Feature: $FEATURE"
echo "Dir: $FEATURE_DIR"
echo "Mode: $([[ "$STRUCTURED" == true ]] && echo "Structured" || echo "Manual")"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

if [[ -s "$ERROR_LOG" ]]; then
  echo "Recent error-log entries:"
  grep -A 6 "^### Entry" "$ERROR_LOG" 2>/dev/null | tail -24 || true
  echo
fi

if [[ -f "$NOTES_FILE" ]]; then
  echo "Notes (past blockers):"
  sed -n '/## Blockers/,/^## /p' "$NOTES_FILE" 2>/dev/null | head -24 || true
  echo
fi

# --- create session log dir --------------------------------------------------
if has mktemp; then
  log_dir=$(mktemp -d "$SESSION_DIR/run-XXXXXX")
else
  # Fallback for systems without mktemp
  log_dir="$SESSION_DIR/run-$(date +%s)"
  mkdir -p "$log_dir"
fi

TEST_LOG="$log_dir/test.log"

# --- verification functions --------------------------------------------------
verify_api() {
  pushd api >/dev/null 2>&1 || return 0
  if has uv; then
    echo "  ruff…"
    uv run ruff check . --quiet 2>&1 | tee "$log_dir/ruff.log" >/dev/null || true
    echo "  mypy…"
    uv run mypy app/ --no-error-summary 2>&1 | tee "$log_dir/mypy.log" >/dev/null || true
    echo "  pytest…"
    uv run pytest -q 2>&1 | tee "$TEST_LOG" || true
  else
    echo "  [warn] uv not installed, skipping backend checks" >&2
  fi
  popd >/dev/null 2>&1 || true
}

verify_app() {
  APP_DIR="apps/app"
  [[ -d "$APP_DIR" ]] || return 0
  pushd "$APP_DIR" >/dev/null 2>&1 || return 0
  if has pnpm; then
    echo "  eslint…"
    pnpm lint --quiet 2>&1 | tee "$log_dir/eslint.log" >/dev/null || true
    echo "  tsc…"
    pnpm type-check 2>&1 | tee "$log_dir/tsc.log" >/dev/null || true
    echo "  vitest…"
    pnpm test --run --silent 2>&1 | tee "$TEST_LOG" || true
  else
    echo "  [warn] pnpm not installed, skipping frontend checks" >&2
  fi
  popd >/dev/null 2>&1 || true
}

# --- reproduce & verify ------------------------------------------------------
echo "Verification (${TYPE}/${COMPONENT}):"
case "$TYPE:$COMPONENT" in
  test:backend|build:backend|runtime:backend|performance:backend) verify_api ;;
  test:frontend|build:frontend|ui:frontend|performance:frontend) verify_app ;;
  *) echo "  (no automated checks for ${TYPE}/${COMPONENT})" ;;
esac
echo

# --- optional deployment diagnostics ----------------------------------------
if [[ "$DEPLOY_DIAG" == true ]]; then
  echo "Deployment diagnostics:"
  diag_file="$log_dir/deploy-diag.txt"
  {
    echo "== vercel =="
    if has vercel; then
      vercel ls --limit 5 2>&1 || true
    else
      echo "vercel cli missing"
    fi

    echo; echo "== railway =="
    if has railway; then
      railway deployments --limit 5 --json 2>&1 || true
    else
      echo "railway cli missing"
    fi

    echo; echo "== gh actions failures =="
    if has gh; then
      gh run list --status=failure --limit 3 2>&1 || true
    else
      echo "gh cli missing"
    fi
  } > "$diag_file" 2>&1
  echo "  Saved to: $(basename "$diag_file")"
  echo
fi

# --- verification summary ----------------------------------------------------
lint_ok=true; types_ok=true; tests_ok=true

if [[ -f "$log_dir/ruff.log" ]] && grep -q . "$log_dir/ruff.log" 2>/dev/null; then
  lint_ok=true
elif [[ -f "$log_dir/eslint.log" ]] && ! grep -qi "error" "$log_dir/eslint.log" 2>/dev/null; then
  lint_ok=true
fi

if [[ -f "$log_dir/mypy.log" ]] && grep -qi "error:" "$log_dir/mypy.log" 2>/dev/null; then
  types_ok=false
elif [[ -f "$log_dir/tsc.log" ]] && grep -qi "error TS" "$log_dir/tsc.log" 2>/dev/null; then
  types_ok=false
fi

if [[ -f "$TEST_LOG" ]] && grep -qiE "FAIL|ERROR|failed" "$TEST_LOG" 2>/dev/null; then
  tests_ok=false
fi

VERIFICATION_STATUS="passed"
$lint_ok || VERIFICATION_STATUS="failed"
$types_ok || VERIFICATION_STATUS="failed"
$tests_ok || VERIFICATION_STATUS="failed"

echo "Verification result: $VERIFICATION_STATUS"
echo "  Lint: $($lint_ok && echo "✅" || echo "❌")"
echo "  Types: $($types_ok && echo "✅" || echo "❌")"
echo "  Tests: $($tests_ok && echo "✅" || echo "❌")"
echo

# --- update error-log --------------------------------------------------------
last_num=$(grep -oE '^### Entry [0-9]+' "$ERROR_LOG" 2>/dev/null | awk '{print $3}' | tail -1 || echo "0")
next_num=$(( ${last_num:-0} + 1 ))
title="${STRUCTURED:+[$ISSUE_ID] }${CATEGORY:-${TYPE^}} Fix"

# Relative path to log dir
if has realpath; then
  rel_log_dir=$(realpath --relative-to="$FEATURE_DIR" "$log_dir" 2>/dev/null || basename "$log_dir")
else
  rel_log_dir=$(basename "$log_dir")
fi

SYMPTOM="See session logs in $rel_log_dir"
LEARN="Verification: $VERIFICATION_STATUS (lint:$($lint_ok && echo "✅" || echo "❌"), types:$($types_ok && echo "✅" || echo "❌"), tests:$($tests_ok && echo "✅" || echo "❌"))"

cat >> "$ERROR_LOG" <<EOF

### Entry $next_num: $(date +%F) - $title

**Failure**: ${DESC:-Debug session for ${TYPE}/${COMPONENT}}
**Symptom**: $SYMPTOM
**Learning**: $LEARN
**Ghost Context Cleanup**: None

$( [[ "$STRUCTURED" == true ]] && echo "**From /optimize auto-fix** (Issue ID: $ISSUE_ID)" || echo "" )
EOF

echo "Error log updated: Entry $next_num"
echo

# --- emit session json -------------------------------------------------------
if has jq; then
  jq -n \
    --arg feature "$FEATURE" \
    --arg mode "$([[ "$STRUCTURED" == true ]] && echo "structured" || echo "manual")" \
    --arg type "$TYPE" \
    --arg component "$COMPONENT" \
    --arg status "$VERIFICATION_STATUS" \
    --arg logDir "$log_dir" \
    --arg issue "$ISSUE_ID" \
    --arg severity "$SEVERITY" \
    --arg category "$CATEGORY" \
    --arg file "$FILEPATH" \
    --arg line "$LINE" \
    --arg desc "$DESC" \
    --arg rec "$RECO" \
    --arg ts "$(ts)" \
    --argjson lintOk "$($lint_ok && echo true || echo false)" \
    --argjson typesOk "$($types_ok && echo true || echo false)" \
    --argjson testsOk "$($tests_ok && echo true || echo false)" \
    '{
       feature: $feature,
       mode: $mode,
       type: $type,
       component: $component,
       verification: {
         status: $status,
         lint: $lintOk,
         types: $typesOk,
         tests: $testsOk
       },
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
     }' > "$SESSION_JSON"
else
  # Fallback if jq not available
  cat > "$SESSION_JSON" <<EOF
{
  "feature": "$FEATURE",
  "mode": "$([[ "$STRUCTURED" == true ]] && echo "structured" || echo "manual")",
  "type": "$TYPE",
  "component": "$COMPONENT",
  "verification": {
    "status": "$VERIFICATION_STATUS",
    "lint": $($lint_ok && echo "true" || echo "false"),
    "types": $($types_ok && echo "true" || echo "false"),
    "tests": $($tests_ok && echo "true" || echo "false")
  },
  "logs": "$log_dir",
  "issue": {
    "id": "$ISSUE_ID",
    "severity": "$SEVERITY",
    "category": "$CATEGORY",
    "file": "$FILEPATH",
    "line": "$LINE",
    "description": "$DESC",
    "recommendation": "$RECO"
  },
  "timestamp": "$(ts)"
}
EOF
fi

echo "Session JSON: $(basename "$SESSION_JSON")"
echo

# --- commit & optional push --------------------------------------------------
if [[ "$STRUCTURED" == true ]]; then
  commit_msg="fix: resolve ${CATEGORY,,} issue (${ISSUE_ID})

${DESC:-}

Verification: $VERIFICATION_STATUS
Updated error-log.md (entry $next_num)"
else
  commit_msg="fix: debug ${TYPE}/${COMPONENT} in ${FEATURE}

Verification: $VERIFICATION_STATUS
Updated error-log.md (entry $next_num)"
fi

git add "$ERROR_LOG" "$SESSION_JSON" >/dev/null 2>&1 || true
[[ -d "$SESSION_DIR" ]] && git add "$SESSION_DIR" >/dev/null 2>&1 || true

if [[ "$VERIFICATION_STATUS" == "passed" ]]; then
  if git commit -m "$commit_msg

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" >/dev/null 2>&1; then
    echo "✅ Committed error-log and session artifacts"

    if [[ "$PUSH_AFTER" == true ]]; then
      current_branch=$(git branch --show-current 2>/dev/null || echo "")
      if [[ -n "$current_branch" ]] && git push origin "$current_branch" 2>&1; then
        echo "⬆️  Pushed to ${current_branch}"
      fi
    fi
  else
    echo "⚠️  Commit failed (maybe nothing to commit)"
  fi
else
  echo "⚠️  Verification failed; artifacts staged but not committed"
fi
echo

# --- output summary ----------------------------------------------------------
if [[ "$EMIT_JSON" == true ]]; then
  cat "$SESSION_JSON"
else
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Status: $VERIFICATION_STATUS"
  echo "Logs: $log_dir"
  echo "Session: $SESSION_JSON"
  echo "Error log: $ERROR_LOG (entry $next_num)"
  echo

  if [[ "$VERIFICATION_STATUS" == "failed" ]]; then
    echo "Next: Fix verification failures and re-run /debug"
    exit 2
  elif [[ "$STRUCTURED" == true ]]; then
    echo "Next: Return to /optimize for next issue"
  else
    echo "Next: Continue with /implement or run /optimize"
  fi
fi

exit 0
