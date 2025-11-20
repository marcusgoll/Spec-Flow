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
  cat .spec-flow/state/workflow-state.yaml | grep 'current_feature:' | awk '{print $2}'
}
```

### Extract Phase Name

```bash
extract_phase_name() {
  # From workflow state
  cat .spec-flow/state/workflow-state.yaml | grep 'current_phase:' | awk '{print $2}'

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
