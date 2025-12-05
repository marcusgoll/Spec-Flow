---
name: review
description: Run on-demand code review during development (voting-enabled)
argument-hint: [--voting | --single | --scope all|changes]
allowed-tools: [Bash, Read, Write, Edit, Task, Grep, Glob, AskUserQuestion]
---

<context>
Current workspace: Auto-detected via git branch or state.yaml

Feature directory: Auto-detected from specs/*/state.yaml

Uncommitted changes: Via git diff

Voting config: .spec-flow/config/voting.yaml
</context>

<objective>
Run on-demand code review at any point during feature development.

**Use cases:**
- Quick review before committing
- Second opinion on architectural decisions
- Comprehensive review with multi-agent voting (slower, more accurate)
- Review specific scope (changes only vs entire feature)

**Review types:**

1. **Single-agent review** (default):
   - Fast (~2-3 min)
   - Uses code-reviewer specialist agent
   - Good for quick checks

2. **Multi-agent voting review** (--voting):
   - Comprehensive (~5-8 min)
   - 3 agents with k=2 voting (MAKER algorithm)
   - Higher accuracy, error decorrelation
   - Recommended for critical decisions

**Scope options:**

- `changes` (default): Review only uncommitted changes
- `all`: Review entire feature directory

**Risk Level**: 🟢 LOW - Read-only analysis, no code modifications
</objective>

<process>

### Step 1: Parse Arguments and Detect Scope

**Parse command arguments:**

```bash
SCOPE="changes"  # Default: uncommitted changes only
USE_VOTING=false
OUTPUT_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --voting)
      USE_VOTING=true
      shift
      ;;
    --single)
      USE_VOTING=false
      shift
      ;;
    --scope)
      SCOPE=$2
      shift 2
      ;;
    --output)
      OUTPUT_FILE=$2
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
```

**Detect current feature:**

Use workflow detection to find active feature:

```bash
# Run detection utility
if command -v bash >/dev/null 2>&1; then
    WORKFLOW_INFO=$(bash .spec-flow/scripts/utils/detect-workflow-paths.sh 2>/dev/null)
else
    WORKFLOW_INFO=$(pwsh -File .spec-flow/scripts/utils/detect-workflow-paths.ps1 2>/dev/null)
fi

if [ $? -eq 0 ]; then
    WORKFLOW_TYPE=$(echo "$WORKFLOW_INFO" | jq -r '.type')
    BASE_DIR=$(echo "$WORKFLOW_INFO" | jq -r '.base_dir')
    SLUG=$(echo "$WORKFLOW_INFO" | jq -r '.slug')
    FEATURE_DIR="$BASE_DIR/$SLUG"
else
    echo "⚠️  Could not detect active feature"
    echo "Options:"
    echo "  1. Run /feature to start a feature workflow"
    echo "  2. Specify feature directory: /review --scope all"
    exit 1
fi
```

**Determine review scope:**

Based on `--scope` argument:

```bash
if [ "$SCOPE" = "changes" ]; then
    # Review only uncommitted changes
    CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || echo "")

    if [ -z "$CHANGED_FILES" ]; then
        echo "ℹ️  No uncommitted changes detected"
        echo "Switching to --scope all (review entire feature)"
        SCOPE="all"
    else
        FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
        echo "📝 Review scope: $FILE_COUNT changed files"
        echo "$CHANGED_FILES" | sed 's/^/  - /'
    fi
fi

if [ "$SCOPE" = "all" ]; then
    echo "📁 Review scope: Entire feature ($FEATURE_DIR)"
fi
```

---

### Step 2: Prepare Review Context

**Create review context file:**

Generate a context file for the agent(s) to review:

```bash
REVIEW_CONTEXT="$FEATURE_DIR/.review-context-$(date +%s).md"

cat > "$REVIEW_CONTEXT" <<EOF
# Code Review Context

## Feature
- **Name**: $(grep "^# " "$FEATURE_DIR/spec.md" | head -1 | sed 's/# //')
- **Directory**: $FEATURE_DIR
- **Type**: $WORKFLOW_TYPE

## Scope
- **Review Type**: $SCOPE
- **Voting**: $USE_VOTING

EOF

if [ "$SCOPE" = "changes" ]; then
    echo "## Changed Files" >> "$REVIEW_CONTEXT"
    echo "" >> "$REVIEW_CONTEXT"
    for file in $CHANGED_FILES; do
        echo "### $file" >> "$REVIEW_CONTEXT"
        echo "" >> "$REVIEW_CONTEXT"
        echo "\`\`\`diff" >> "$REVIEW_CONTEXT"
        git diff HEAD -- "$file" >> "$REVIEW_CONTEXT"
        echo "\`\`\`" >> "$REVIEW_CONTEXT"
        echo "" >> "$REVIEW_CONTEXT"
    done
else
    echo "## Feature Directory Structure" >> "$REVIEW_CONTEXT"
    echo "" >> "$REVIEW_CONTEXT"
    tree "$FEATURE_DIR" -L 3 >> "$REVIEW_CONTEXT" 2>/dev/null || \
        find "$FEATURE_DIR" -maxdepth 3 -type f >> "$REVIEW_CONTEXT"
fi

# Add quality focus areas
cat >> "$REVIEW_CONTEXT" <<EOF

## Review Focus Areas

1. **Code Quality**
   - KISS principle (Keep It Simple, Stupid)
   - DRY violations (Don't Repeat Yourself)
   - Clear variable/function naming
   - Appropriate abstractions

2. **Security**
   - Input validation
   - SQL injection risks
   - XSS vulnerabilities
   - Secrets in code

3. **Performance**
   - N+1 query patterns
   - Inefficient algorithms
   - Memory leaks
   - Unnecessary re-renders (React)

4. **Testing**
   - Test coverage for new code
   - Edge cases handled
   - Mocks used appropriately

5. **Architecture**
   - Separation of concerns
   - API design
   - Error handling
   - Logging and observability

EOF

echo "✅ Review context prepared: $REVIEW_CONTEXT"
```

---

### Step 3: Invoke Code Review

**Option A: Single-agent review (default)**

If `$USE_VOTING = false`:

Use the Task tool to invoke code-reviewer agent:

```javascript
Task({
  subagent_type: "code-reviewer",
  description: "Code review for $SLUG",
  prompt: `Review the code changes in the feature workspace.

Review Context:
${Read the REVIEW_CONTEXT file}

Instructions:
1. Analyze all code changes against the review focus areas
2. Categorize findings as CRITICAL, MAJOR, or MINOR
3. Provide specific file:line references for each issue
4. Suggest concrete fixes with code examples
5. Highlight positive patterns worth preserving

Output Format:
Generate a detailed review report in markdown with:
- Executive summary
- Issues categorized by severity
- Recommendations with priority
- Code quality score (0-100)

Save report to: ${OUTPUT_FILE || "$FEATURE_DIR/artifacts/review-$(date +%s).md"}`
});
```

**Option B: Multi-agent voting review** (--voting)

If `$USE_VOTING = true` and voting config exists:

```bash
# Check if voting is available
if [ -f ".spec-flow/config/voting.yaml" ] && [ -f ".claude/skills/multi-agent-voting/voting-engine.sh" ]; then
    echo "🗳️  Launching 3-agent voting review (k=2)..."
    echo "  This will take 5-8 minutes..."
    echo ""

    # Source voting engine
    source .claude/skills/multi-agent-voting/voting-engine.sh

    # Invoke voting for code review
    invoke_voting "code_review" "$REVIEW_CONTEXT" --output "${OUTPUT_FILE:-$FEATURE_DIR/artifacts/review-voting-$(date +%s).md}"

    REVIEW_STATUS=$?
else
    echo "⚠️  Voting system not available, falling back to single-agent review"
    USE_VOTING=false
    # Continue with Option A (single-agent)
fi
```

---

### Step 4: Display Results

**Parse review report and display summary:**

```bash
if [ -n "$OUTPUT_FILE" ]; then
    REPORT_FILE="$OUTPUT_FILE"
else
    REPORT_FILE=$(ls -t "$FEATURE_DIR"/artifacts/review-*.md 2>/dev/null | head -1)
fi

if [ -f "$REPORT_FILE" ]; then
    echo ""
    echo "══════════════════════════════════════════"
    echo "📊 Code Review Results"
    echo "══════════════════════════════════════════"
    echo ""

    # Extract summary sections
    if grep -q "CRITICAL" "$REPORT_FILE"; then
        CRITICAL_COUNT=$(grep -c "CRITICAL" "$REPORT_FILE")
        echo "🔴 CRITICAL issues: $CRITICAL_COUNT"
    fi

    if grep -q "MAJOR" "$REPORT_FILE"; then
        MAJOR_COUNT=$(grep -c "MAJOR" "$REPORT_FILE")
        echo "🟠 MAJOR issues: $MAJOR_COUNT"
    fi

    if grep -q "MINOR" "$REPORT_FILE"; then
        MINOR_COUNT=$(grep -c "MINOR" "$REPORT_FILE")
        echo "🟡 MINOR issues: $MINOR_COUNT"
    fi

    # Extract code quality score if present
    if grep -q "Code Quality Score" "$REPORT_FILE"; then
        SCORE=$(grep "Code Quality Score" "$REPORT_FILE" | grep -oP '\d+' | head -1)
        echo ""
        echo "📈 Code Quality Score: $SCORE/100"
    fi

    echo ""
    echo "Full report: $REPORT_FILE"
    echo ""

    # If voting was used, show voting details
    if [ "$USE_VOTING" = true ] && [ "$REVIEW_STATUS" -eq 0 ]; then
        echo "✅ Voting consensus: APPROVED"
        echo "  All $k agents agreed (or ahead by k=2)"
    elif [ "$USE_VOTING" = true ]; then
        echo "❌ Voting consensus: REJECTED"
        echo "  Critical issues found by majority"
    fi

else
    echo "⚠️  Review report not found"
fi
```

---

### Step 5: Offer Interactive Actions

**If issues found, offer auto-fix options:**

Use AskUserQuestion to present actions:

```javascript
if (CRITICAL_COUNT > 0 || MAJOR_COUNT > 0) {
  AskUserQuestion({
    questions: [
      {
        question: "Critical or major issues found. What would you like to do?",
        header: "Next Action",
        multiSelect: false,
        options: [
          {
            label: "Review detailed report",
            description: `Open ${REPORT_FILE} for full analysis`
          },
          {
            label: "Auto-fix linting issues",
            description: "Run automated fixes for style and formatting"
          },
          {
            label: "Show file:line references",
            description: "Extract all file:line references for quick navigation"
          },
          {
            label: "Continue without changes",
            description: "Acknowledge issues, address later"
          }
        ]
      }
    ]
  });
}
```

**Handle user response:**

Based on user selection:

**Option 1: Review detailed report**
```bash
# Display full report (use Read tool to show content)
Read("$REPORT_FILE")
```

**Option 2: Auto-fix linting issues**
```bash
echo "🔧 Running auto-fix for linting issues..."

# Frontend
if [ -d "apps" ]; then
    pnpm --filter @app lint --fix
    pnpm --filter @app format
fi

# Backend
if [ -d "api" ]; then
    cd api
    ruff check . --fix
    ruff format .
    cd - >/dev/null
fi

# Commit auto-fixes
git add .
git commit -m "style: auto-fix linting issues from code review

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

echo "✅ Auto-fixes applied and committed"
```

**Option 3: Show file:line references**
```bash
echo "📍 File:line references from review:"
echo ""
grep -E "^[a-zA-Z0-9/_\-\.]+:[0-9]+" "$REPORT_FILE" || \
grep -oP '[a-zA-Z0-9/_\-\.]+:[0-9]+' "$REPORT_FILE" | sort -u
```

**Option 4: Continue without changes**
```bash
echo "ℹ️  Issues acknowledged. Review report saved for later."
```

---

### Step 6: Cleanup

**Remove temporary review context:**

```bash
rm -f "$REVIEW_CONTEXT"
```

**Summary output:**

```bash
echo ""
echo "══════════════════════════════════════════"
echo "✅ Code review complete"
echo ""
echo "Review type: $([ "$USE_VOTING" = true ] && echo "Multi-agent voting (3 agents, k=2)" || echo "Single-agent")"
echo "Scope: $SCOPE"
echo "Report: $REPORT_FILE"
echo ""
echo "Next steps:"
echo "  - Address CRITICAL issues before committing"
echo "  - Plan fixes for MAJOR issues"
echo "  - Consider MINOR issues for refactoring"
echo "══════════════════════════════════════════"
```

</process>

<examples>

## Example 1: Quick review of uncommitted changes

```bash
# User has made changes but hasn't committed yet
/review
```

**Output:**
```
📝 Review scope: 3 changed files
  - apps/components/UserProfile.tsx
  - apps/lib/auth.ts
  - api/app/routes/users.py

✅ Review context prepared
🔄 Invoking code-reviewer agent...

📊 Code Review Results
══════════════════════════════════════════
🟠 MAJOR issues: 1
🟡 MINOR issues: 4
📈 Code Quality Score: 82/100

Full report: specs/042-user-profile/artifacts/review-1733458921.md
```

## Example 2: Comprehensive review with voting

```bash
# User wants high-confidence review before PR
/review --voting --scope all
```

**Output:**
```
📁 Review scope: Entire feature (specs/042-user-profile)

🗳️  Launching 3-agent voting review (k=2)...
  This will take 5-8 minutes...

🚀 Launching 3 agents in parallel...
  Agent 1: temperature=0.5
  Agent 2: temperature=0.7
  Agent 3: temperature=0.9
✅ All agents completed

📊 Aggregating votes with strategy: first_to_ahead_by_k

📊 Code Review Results
══════════════════════════════════════════
🔴 CRITICAL issues: 0
🟠 MAJOR issues: 2
🟡 MINOR issues: 7
📈 Code Quality Score: 78/100

✅ Voting consensus: APPROVED
  All 2 agents agreed (ahead by k=2)
```

## Example 3: Review with auto-fix

```bash
/review
```

**Output includes interactive prompt:**
```
Critical or major issues found. What would you like to do?

[ ] Review detailed report
[x] Auto-fix linting issues
[ ] Show file:line references
[ ] Continue without changes

🔧 Running auto-fix for linting issues...
✅ Auto-fixes applied and committed
```

</examples>

<notes>

## Integration with Workflow

The /review command can be used at any point:

1. **During /implement**: Review batch of tasks before moving to next
2. **Before git commit**: Quick sanity check
3. **Before /optimize**: Pre-check to catch obvious issues
4. **Before PR**: High-confidence review with --voting

## Voting Cost

Multi-agent voting costs 3x the tokens:
- Single-agent: ~2k tokens
- Voting (3 agents): ~6k tokens

Use voting for:
- Critical features (auth, payments, security)
- Before major refactors
- When uncertain about approach
- Before merging to main

## Performance

**Single-agent review:**
- Time: 2-3 minutes
- Cost: Low (1 agent invocation)

**Voting review:**
- Time: 5-8 minutes
- Cost: Medium (3 agent invocations)

## Output Files

Review reports saved to:
```
$FEATURE_DIR/artifacts/review-{timestamp}.md      # Single-agent
$FEATURE_DIR/artifacts/review-voting-{timestamp}.md  # Voting
```

## Limitations

- Reviews code only (no runtime analysis)
- Best for static issues (linting, architecture, patterns)
- Won't catch logic bugs requiring execution
- Limited to context window (large features may need --scope changes)

</notes>
