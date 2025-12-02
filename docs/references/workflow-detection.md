# Workflow Type Detection (v9.2+)

All phase commands auto-detect whether they're working with epic or feature workflows using centralized detection utilities.

## Detection Priority

Three-tier detection system (Files → Branch → State):

1. **Workspace files** (highest priority):

   - Checks for `epics/*/epic-spec.md` → Epic workflow
   - Checks for `specs/*/spec.md` → Feature workflow

2. **Git branch pattern** (fallback):

   - Branch matches `epic/*` → Epic workflow
   - Branch matches `feature/*` → Feature workflow

3. **Workflow state** (lowest priority):

   - Reads `workflow_type` field from state.yaml

4. **User prompt** (detection failed):
   - Uses AskUserQuestion if all detection methods fail

## Detection Utilities

Cross-platform utilities return structured JSON:

**Bash** (Linux/Mac/Git Bash):

```bash
bash .spec-flow/scripts/utils/detect-workflow-paths.sh
```

**PowerShell** (Windows):

```powershell
pwsh -File .spec-flow/scripts/utils/detect-workflow-paths.ps1
```

**Output format**:

```json
{
  "type": "epic",
  "base_dir": "epics",
  "slug": "001-auth-system",
  "branch": "epic/001-auth-system",
  "source": "files"
}
```

## Phase Command Integration

All phase commands include Step 0: Workflow Type Detection:

**Commands using detection**:

- /clarify — Locates correct spec file (epic-spec.md or spec.md)
- /plan — Reads from correct workspace directory
- /tasks — Generates tasks in correct location
- /validate — Validates artifacts in correct directory
- /implement — Executes tasks from detected workspace
- /optimize — Determines gate count (6 for features, 10 for epics)

**Dynamic path variables**:

```bash
$WORKFLOW_TYPE  # "epic" or "feature"
$BASE_DIR       # "epics" or "specs"
$SLUG           # "001-auth-system"
$SPEC_FILE      # "${BASE_DIR}/${SLUG}/epic-spec.md" or "spec.md"
$PLAN_FILE      # "${BASE_DIR}/${SLUG}/plan.md"
$TASKS_FILE     # "${BASE_DIR}/${SLUG}/tasks.md"
$REPORT_FILE    # "${BASE_DIR}/${SLUG}/analysis-report.md"
$CLAUDE_MD      # "${BASE_DIR}/${SLUG}/CLAUDE.md"
```

## Continue Mode Detection

Both `/epic continue` and `/feature continue` include branch detection:

**Epic continue**:

- Detects epic workspace via utility
- Verifies workflow type is "epic" (exits if feature)
- Checks if on `epic/*` branch
- Offers to switch branches if mismatch

**Feature continue**:

- Detects feature workspace via utility
- Verifies workflow type is "feature" (exits if epic)
- Checks if on `feature/*` branch
- Warns if not on correct branch

**Error handling**:

```bash
# If on wrong workflow type
Error: This is a feature workflow, not an epic
   Use /feature continue for feature workflows

# If detection fails
Warning: Could not auto-detect workflow type
   [Prompts user via AskUserQuestion]
```
