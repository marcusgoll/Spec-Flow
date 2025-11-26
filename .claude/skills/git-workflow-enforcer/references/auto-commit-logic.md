# Auto-Commit Generation Logic

## Context Detection

### Phase Completion Context

**Detection patterns:**

- Command completion: `/specify`, `/plan`, `/tasks`, `/analyze`, `/optimize`, `/preview`
- Verbal: "phase N complete", "specification done", "planning finished"
- File patterns: New files in `specs/*/` matching phase artifacts

**Extract variables:**

```bash
PHASE_NAME=$(detect_current_phase)  # spec, plan, tasks, analyze, optimize, preview
FEATURE_SLUG=$(basename $(pwd) | grep -oP 'specs/\K[^/]+')
ARTIFACTS=$(git status --porcelain | grep '^??' | awk '{print $2}')
```

**Generate commit:**

```bash
TYPE="docs"
SCOPE="$PHASE_NAME"
SUBJECT="create $(echo $ARTIFACTS | tr '\n' ', ') for $FEATURE_SLUG"

git commit -m "docs($PHASE_NAME): $SUBJECT"
```

---

### Epic Phase Completion Context

**Detection patterns:**

- Command completion: `/epic` (with phase indicators), epic-specific slash commands
- Verbal: "epic spec complete", "research finished", "layer N complete", "sprint breakdown done"
- File patterns: New files in `epics/*/` matching epic phase artifacts
- Branch pattern: Currently on `epic/*` branch

**Epic context detection:**

```bash
# Detect if we're in an epic workflow
IS_EPIC_BRANCH=$(git branch --show-current | grep -q '^epic/' && echo "true" || echo "false")
EPIC_DIR=$(find epics -maxdepth 1 -type d -name '[0-9]*-*' | head -1)
EPIC_SLUG=$(basename "$EPIC_DIR" 2>/dev/null || echo "unknown")
```

**Extract epic phase variables:**

```bash
# From epic state.yaml
CURRENT_PHASE=$(yq -r '.epic.current_phase // "unknown"' "$EPIC_DIR/state.yaml")
AUTO_MODE=$(yq -r '.epic.auto_mode // "false"' "$EPIC_DIR/state.yaml")

# Phase-specific metadata
case "$CURRENT_PHASE" in
  specification)
    EPIC_TYPE=$(yq -r '.epic.type // "unknown"' "$EPIC_DIR/epic-spec.md")
    COMPLEXITY=$(yq -r '.epic.complexity // "unknown"' "$EPIC_DIR/epic-spec.md")
    SUBSYSTEM_COUNT=$(yq -r '.epic.subsystems | length // 0' "$EPIC_DIR/epic-spec.md")
    ;;
  research)
    FINDINGS_COUNT=$(xmllint --xpath 'count(//finding)' "$EPIC_DIR/research.md" 2>/dev/null || echo "0")
    CONFIDENCE=$(xmllint --xpath 'string(//confidence_level)' "$EPIC_DIR/research.md" 2>/dev/null || echo "unknown")
    OPEN_QUESTIONS=$(xmllint --xpath 'count(//open_question)' "$EPIC_DIR/research.md" 2>/dev/null || echo "0")
    ;;
  planning)
    ARCH_DECISIONS=$(xmllint --xpath 'count(//architecture_decision)' "$EPIC_DIR/plan.md" 2>/dev/null || echo "0")
    PHASE_COUNT=$(xmllint --xpath 'count(//phase)' "$EPIC_DIR/plan.md" 2>/dev/null || echo "0")
    DEPENDENCY_COUNT=$(xmllint --xpath 'count(//dependency)' "$EPIC_DIR/plan.md" 2>/dev/null || echo "0")
    RISK_COUNT=$(xmllint --xpath 'count(//risk)' "$EPIC_DIR/plan.md" 2>/dev/null || echo "0")
    ;;
  sprint_breakdown)
    SPRINT_COUNT=$(xmllint --xpath 'count(//sprint)' "$EPIC_DIR/sprint-plan.md" 2>/dev/null || echo "0")
    LAYER_COUNT=$(xmllint --xpath 'count(//layer)' "$EPIC_DIR/sprint-plan.md" 2>/dev/null || echo "0")
    CONTRACT_COUNT=$(find "$EPIC_DIR/contracts" -name '*.yaml' 2>/dev/null | wc -l)
    TASK_COUNT=$(xmllint --xpath 'count(//task)' "$EPIC_DIR/tasks.md" 2>/dev/null || echo "0")
    ;;
  implementation_layer)
    # Layer-specific (detected from layer completion event)
    LAYER_NUM="$1"  # Passed as parameter
    SPRINT_IDS="$2"  # Comma-separated sprint IDs
    DURATION_HOURS=$(yq -r ".layers[$LAYER_NUM].duration_hours // 0" "$EPIC_DIR/state.yaml")
    TASKS_COMPLETED=$(yq -r ".layers[$LAYER_NUM].tasks_completed // 0" "$EPIC_DIR/state.yaml")
    TESTS_PASSING=$(yq -r ".layers[$LAYER_NUM].tests_passing // 0" "$EPIC_DIR/state.yaml")
    COVERAGE=$(yq -r ".layers[$LAYER_NUM].coverage_percent // 0" "$EPIC_DIR/state.yaml")
    CONTRACTS_LOCKED=$(yq -r ".layers[$LAYER_NUM].contracts_locked | length // 0" "$EPIC_DIR/state.yaml")
    LAYER_TOTAL=$(yq -r '.layers.total // 0' "$EPIC_DIR/state.yaml")
    SPRINTS_COMPLETED=$(yq -r '.sprints.completed // 0' "$EPIC_DIR/state.yaml")
    SPRINTS_TOTAL=$(yq -r '.sprints.total // 0' "$EPIC_DIR/state.yaml")
    ;;
  optimization)
    PERF_SCORE=$(yq -r '.performance.score // "N/A"' "$EPIC_DIR/optimization-report.md")
    SEC_SCORE=$(yq -r '.security.score // "N/A"' "$EPIC_DIR/optimization-report.md")
    A11Y_SCORE=$(yq -r '.accessibility.score // "N/A"' "$EPIC_DIR/optimization-report.md")
    QUALITY_SCORE=$(yq -r '.code_quality.score // "N/A"' "$EPIC_DIR/optimization-report.md")
    ;;
  preview)
    AUTO_CHECKS=$(yq -r '.preview.auto_checks // "N/A"' "$EPIC_DIR/state.yaml")
    MANUAL_STATUS=$(yq -r '.manual_gates.preview.status // "N/A"' "$EPIC_DIR/state.yaml")
    ;;
esac
```

**Generate epic commit based on phase:**

```bash
case "$CURRENT_PHASE" in
  specification)
    git commit -m "docs(epic-spec): create specification for $EPIC_SLUG

Type: $EPIC_TYPE
Complexity: $COMPLEXITY
Subsystems: $SUBSYSTEM_COUNT

Next: /clarify (if needed) or research phase"
    ;;

  research)
    git commit -m "docs(epic-research): complete technical research for $EPIC_SLUG

Findings: $FINDINGS_COUNT
Confidence: $CONFIDENCE
Open questions: $OPEN_QUESTIONS

Next: Planning phase"
    ;;

  planning)
    git commit -m "docs(epic-plan): create implementation plan for $EPIC_SLUG

Architecture decisions: $ARCH_DECISIONS
Phases: $PHASE_COUNT
Dependencies: $DEPENDENCY_COUNT
Risks: $RISK_COUNT

Next: Sprint breakdown"
    ;;

  sprint_breakdown)
    git commit -m "docs(epic-tasks): create sprint breakdown for $EPIC_SLUG ($SPRINT_COUNT sprints)

Sprints: $SPRINT_COUNT
Layers: $LAYER_COUNT
Contracts locked: $CONTRACT_COUNT
Total tasks: $TASK_COUNT

Next: /implement-epic (parallel sprint execution)"
    ;;

  implementation_layer)
    git commit -m "feat(epic): complete layer $LAYER_NUM (sprints $SPRINT_IDS)

Duration: ${DURATION_HOURS}h
Tasks: $TASKS_COMPLETED
Tests: $TESTS_PASSING passing
Coverage: ${COVERAGE}%
Contracts locked: $CONTRACTS_LOCKED

Layer $LAYER_NUM of $LAYER_TOTAL complete
Epic progress: $SPRINTS_COMPLETED/$SPRINTS_TOTAL sprints

Next layer: $((LAYER_NUM + 1)) (or optimization if final)"
    ;;

  optimization)
    git commit -m "docs(epic-optimize): complete optimization for $EPIC_SLUG

Performance: $PERF_SCORE/100
Security: $SEC_SCORE/100
Accessibility: $A11Y_SCORE/100
Code quality: $QUALITY_SCORE/100

All quality gates passed

Next: /preview (if needed) or /ship"
    ;;

  preview)
    git commit -m "docs(epic-preview): complete preview for $EPIC_SLUG

Auto-checks: $AUTO_CHECKS
Manual review: $MANUAL_STATUS

Ready for deployment

Next: /ship"
    ;;
esac
```

**Invoke via skill:**

```bash
# Auto-invoke after epic phase completion
/meta:enforce-git-commits --phase "epic-$CURRENT_PHASE"

# Or for layer completion
/meta:enforce-git-commits --phase "epic-layer-$LAYER_NUM"
```

---

### Task Completion Context

**Detection patterns:**

- task-tracker command: `mark-done-with-notes -TaskId T###`
- Verbal: "T### complete", "task ### done", "finished T###"
- File patterns: Modified files matching task file paths in tasks.md

**Extract variables:**

```bash
TASK_ID="T001"  # From task-tracker or conversation
TASK_DESC=$(grep "$TASK_ID" tasks.md | sed 's/.*\] T[0-9]* //')
PHASE_MARKER=$(grep "$TASK_ID" tasks.md | grep -oP '\[([A-Z]+)\]' | tr -d '[]')
NOTES="$1"  # From task-tracker -Notes parameter
EVIDENCE="$2"  # From task-tracker -Evidence parameter
COVERAGE="$3"  # From task-tracker -Coverage parameter
```

**Generate commit based on phase marker:**

```bash
if [[ "$PHASE_MARKER" == "RED" ]]; then
  TYPE="test"
  SCOPE="red"
  SUBJECT="$TASK_ID write failing test for $TASK_DESC"
  BODY="Test: $NOTES
Expected: FAILED
Evidence: $EVIDENCE"

elif [[ "$PHASE_MARKER" == "GREEN" ]]; then
  TYPE="feat"
  SCOPE="green"
  SUBJECT="$TASK_ID implement $TASK_DESC to pass test"
  BODY="Implementation: $NOTES
Tests: $EVIDENCE
Coverage: $COVERAGE"

elif [[ "$PHASE_MARKER" == "REFACTOR" ]]; then
  TYPE="refactor"
  SCOPE=""
  SUBJECT="$TASK_ID improve $TASK_DESC"
  BODY="Improvements:
- $NOTES

Tests: $EVIDENCE (still green)
Coverage: $COVERAGE (maintained)"
fi

git commit -m "$TYPE($SCOPE): $SUBJECT

$BODY"
```

---

### File Modification Context

**Detection patterns:**

- git status shows modified files
- No clear phase or task context
- User mentions "save progress", "commit changes"

**Extract variables:**

```bash
CHANGED_FILES=$(git status --porcelain | awk '{print $2}')
CHANGE_TYPE=$(infer_change_type_from_files)
```

**Infer change type:**

```bash
if [[ "$CHANGED_FILES" =~ test ]]; then
  TYPE="test"
  SCOPE=$(extract_scope_from_path)
  SUBJECT="add tests for $SCOPE"

elif [[ "$CHANGED_FILES" =~ README|\.md$ ]]; then
  TYPE="docs"
  SCOPE=$(extract_scope_from_path)
  SUBJECT="update documentation"

elif [[ "$CHANGED_FILES" =~ package\.json|requirements\.txt|Cargo\.toml ]]; then
  TYPE="chore"
  SCOPE="deps"
  SUBJECT="update dependencies"

else
  # Default to chore
  TYPE="chore"
  SCOPE=""
  SUBJECT="update $(basename $CHANGED_FILES | head -1)"
fi
```

---

## Variable Extraction Functions

### Extract Feature Slug

```bash
extract_feature_slug() {
  # From current directory
  pwd | grep -oP 'specs/\K[^/]+' || echo "unknown"

  # Or from workflow state
  cat .spec-flow/state/state.yaml | grep 'current_feature:' | awk '{print $2}'
}
```

### Extract Phase Name

```bash
extract_phase_name() {
  # From workflow state
  cat .spec-flow/state/state.yaml | grep 'current_phase:' | awk '{print $2}'

  # Or infer from artifacts
  if [ -f specs/*/spec.md ] && [ ! -f specs/*/plan.md ]; then
    echo "spec"
  elif [ -f specs/*/plan.md ] && [ ! -f specs/*/tasks.md ]; then
    echo "plan"
  elif [ -f specs/*/tasks.md ]; then
    echo "tasks"
  fi
}
```

### Extract Task ID

```bash
extract_task_id() {
  # From task-tracker parameters
  echo "$@" | grep -oP 'TaskId\s+\K T\d+'

  # Or from conversation/git diff
  git diff --cached | grep -oP '^[+-].*\KT\d{3}' | head -1

  # Or from most recent task-in-progress
  grep '\[~\]' specs/*/tasks.md | grep -oP 'T\d+' | head -1
}
```

### Extract Phase Marker

```bash
extract_phase_marker() {
  TASK_ID="$1"
  grep "$TASK_ID" specs/*/tasks.md | grep -oP '\[([A-Z]+)\]' | tr -d '[]'
}
```

### Extract Scope from File Path

```bash
extract_scope_from_path() {
  FILE="$1"

  # API files
  if [[ "$FILE" =~ api/ ]]; then
    echo "api"
  # Frontend files
  elif [[ "$FILE" =~ (web|frontend|ui)/ ]]; then
    echo "ui"
  # Tests
  elif [[ "$FILE" =~ test ]]; then
    echo "test"
  # Config
  elif [[ "$FILE" =~ (config|\.env) ]]; then
    echo "config"
  # Docs
  elif [[ "$FILE" =~ (docs|README|\.md) ]]; then
    echo "docs"
  else
    echo "chore"
  fi
}
```

---

## Auto-Commit Decision Tree

```
Uncommitted changes detected
│
├─ Phase completion context?
│  └─ Generate: docs($phase): create artifacts for $feature
│
├─ Task completion context?
│  ├─ Phase marker = [RED]?
│  │  └─ Generate: test(red): $taskId write failing test
│  ├─ Phase marker = [GREEN]?
│  │  └─ Generate: feat(green): $taskId implement feature
│  └─ Phase marker = [REFACTOR]?
│     └─ Generate: refactor: $taskId improve code
│
├─ File modification context?
│  ├─ Test files changed?
│  │  └─ Generate: test($scope): add tests
│  ├─ Docs changed?
│  │  └─ Generate: docs($scope): update documentation
│  ├─ Dependencies changed?
│  │  └─ Generate: chore(deps): update dependencies
│  └─ Other files?
│     └─ Generate: chore: update $filename
│
└─ No clear context?
   └─ Prompt user or default: chore: save progress
```

---

## Safety Validations Before Commit

### 1. Check Branch Safety

```bash
CURRENT_BRANCH=$(git branch --show-current)

if [[ "$CURRENT_BRANCH" =~ ^(main|master)$ ]]; then
  echo "❌ BLOCKED: Cannot commit directly to $CURRENT_BRANCH"
  echo "Create feature branch: git checkout -b feat/${FEATURE_SLUG}"
  return 1
fi

if [[ ! "$CURRENT_BRANCH" =~ ^(feat|feature|bugfix|fix|hotfix|chore)/ ]]; then
  echo "⚠️ WARNING: Branch name '$CURRENT_BRANCH' doesn't follow convention"
  echo "Expected: feat/*, bugfix/*, hotfix/*, chore/*"
fi
```

### 2. Check for Merge Conflicts

```bash
if grep -r "<<<<<<<" . --exclude-dir=.git 2>/dev/null; then
  echo "❌ BLOCKED: Unresolved merge conflicts detected"
  echo "Resolve conflicts before committing"
  return 1
fi
```

### 3. Validate Commit Message Format

```bash
validate_commit_message() {
  MSG="$1"

  # Check Conventional Commits format
  if ! [[ "$MSG" =~ ^(feat|fix|docs|test|refactor|perf|chore|ci|build|revert)(\([a-z0-9-]+\))?: ]]; then
    echo "⚠️ WARNING: Message doesn't follow Conventional Commits"
    echo "Auto-fixing: prepending 'chore: '"
    MSG="chore: $MSG"
  fi

  # Check subject length
  SUBJECT=$(echo "$MSG" | head -1)
  if [[ ${#SUBJECT} -gt 72 ]]; then
    echo "⚠️ WARNING: Subject line too long (${#SUBJECT} chars)"
    echo "Recommended: <50 chars"
  fi

  echo "$MSG"
}
```

---

## Example Auto-Commits

### Example 1: Phase Completion

**Context**: `/specify` command completed

**Detection**:

```bash
PHASE_NAME="spec"
FEATURE_SLUG="user-messaging"
ARTIFACTS="specs/user-messaging/spec.md"
```

**Generated commit**:

```bash
docs(spec): create specification for user-messaging

- Acceptance criteria: 15
- User stories: 3
- Technical requirements: Defined
```

---

### Example 2: RED Phase Task

**Context**: T001 completed with phase marker [RED]

**Detection**:

```bash
TASK_ID="T001"
TASK_DESC="Create Message model tests"
PHASE_MARKER="RED"
NOTES="Write unit tests for Message model"
EVIDENCE="pytest: 0/8 passing (failing as expected)"
```

**Generated commit**:

```bash
test(red): T001 write failing test for Create Message model tests

Test: Write unit tests for Message model
Expected: FAILED
Evidence: pytest: 0/8 passing (failing as expected)
```

---

### Example 3: GREEN Phase Task

**Context**: T002 completed with phase marker [GREEN]

**Detection**:

```bash
TASK_ID="T002"
TASK_DESC="Implement Message model"
PHASE_MARKER="GREEN"
NOTES="Created SQLAlchemy model with validation"
EVIDENCE="pytest: 8/8 passing"
COVERAGE="93% (+93%)"
```

**Generated commit**:

```bash
feat(green): T002 implement Implement Message model to pass test

Implementation: Created SQLAlchemy model with validation
Tests: pytest: 8/8 passing
Coverage: 93% (+93%)
```

---

### Example 4: File Modification

**Context**: README.md modified

**Detection**:

```bash
CHANGED_FILES="README.md"
CHANGE_TYPE="docs"
SCOPE="readme"
```

**Generated commit**:

```bash
docs(readme): update documentation
```
