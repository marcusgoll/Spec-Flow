# Workflow Detection Skill

Provides centralized workflow type detection for all phase and deployment commands.

## Purpose

Eliminates 50+ lines of duplicated detection code across 44 commands by providing a single source of truth for workflow type detection.

## Quick Reference

```bash
# Bash (Linux/Mac/Git Bash)
WORKFLOW_INFO=$(bash .spec-flow/scripts/utils/detect-workflow-paths.sh)

# PowerShell (Windows)
$workflowInfo = pwsh -File .spec-flow/scripts/utils/detect-workflow-paths.ps1
```

## Output Format

Returns JSON with workflow information:

```json
{
  "type": "epic",
  "base_dir": "epics",
  "slug": "001-auth-system",
  "branch": "epic/001-auth-system",
  "source": "files",
  "is_worktree": false
}
```

### Fields

| Field | Values | Description |
|-------|--------|-------------|
| `type` | `epic`, `feature`, `unknown` | Workflow type |
| `base_dir` | `epics`, `specs`, `unknown` | Base directory for artifacts |
| `slug` | string | Feature/epic identifier (e.g., `001-auth-system`) |
| `branch` | string | Current git branch |
| `source` | `files`, `branch`, `state`, `none` | How type was detected |
| `is_worktree` | boolean | Whether in a git worktree |

### Worktree Fields (when `is_worktree: true`)

| Field | Description |
|-------|-------------|
| `worktree_path` | Absolute path to worktree |
| `worktree_type` | `epic`, `feature`, or `unknown` |
| `worktree_slug` | Extracted slug from worktree path |

## Detection Priority

1. **Workspace Files** (highest priority)
   - Checks for `epics/*/epic-spec.md` → Epic workflow
   - Checks for `specs/*/spec.md` → Feature workflow

2. **Git Branch Pattern**
   - Branch matches `epic/*` → Epic workflow
   - Branch matches `feature/*` → Feature workflow

3. **Workflow State**
   - Reads `workflow_type` from `state.yaml`

4. **User Prompt** (detection failed)
   - Returns `type: unknown` with exit code 1
   - Command should use AskUserQuestion as fallback

## Usage in Commands

### Standard Pattern (Recommended)

```yaml
# In command's <process> section:

### Step 0: Workflow Type Detection

**Detect workflow type using centralized utility:**

<bash>
# Cross-platform detection
if command -v bash >/dev/null 2>&1; then
    WORKFLOW_INFO=$(bash .spec-flow/scripts/utils/detect-workflow-paths.sh 2>/dev/null)
elif command -v pwsh >/dev/null 2>&1; then
    WORKFLOW_INFO=$(pwsh -File .spec-flow/scripts/utils/detect-workflow-paths.ps1 2>/dev/null)
fi

if [ -n "$WORKFLOW_INFO" ]; then
    WORKFLOW_TYPE=$(echo "$WORKFLOW_INFO" | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
    BASE_DIR=$(echo "$WORKFLOW_INFO" | grep -o '"base_dir":"[^"]*"' | cut -d'"' -f4)
    SLUG=$(echo "$WORKFLOW_INFO" | grep -o '"slug":"[^"]*"' | cut -d'"' -f4)
fi
</bash>

**If detection fails, prompt user:**

Use AskUserQuestion with options: "Epic workflow", "Feature workflow"
```

### Path Variables

After detection, use these standardized variables:

```bash
$WORKFLOW_TYPE  # "epic" or "feature"
$BASE_DIR       # "epics" or "specs"
$SLUG           # "001-auth-system"
$SPEC_FILE      # "${BASE_DIR}/${SLUG}/epic-spec.md" or "spec.md"
$PLAN_FILE      # "${BASE_DIR}/${SLUG}/plan.md"
$TASKS_FILE     # "${BASE_DIR}/${SLUG}/tasks.md"
$STATE_FILE     # "${BASE_DIR}/${SLUG}/state.yaml"
$NOTES_FILE     # "${BASE_DIR}/${SLUG}/NOTES.md"
```

## Commands Using This Skill

### Phase Commands
- `/clarify` - Locates correct spec file
- `/plan` - Reads from correct workspace
- `/tasks` - Generates tasks in correct location
- `/validate` - Validates artifacts in correct directory
- `/implement` - Executes tasks from detected workspace
- `/optimize` - Determines gate count (6 for features, 10 for epics)
- `/finalize` - Archives to correct completed/ directory

### Deployment Commands
- `/ship` - Routes to correct deployment workflow
- `/ship-staging` - Uses correct workspace for PR
- `/ship-prod` - Promotes correct branch
- `/deploy-prod` - Deploys from correct source

### Epic Commands
- `/epic continue` - Detects and resumes epic workspace
- `/implement-epic` - Reads sprint plan from epics/ directory

## Error Handling

### Detection Failure

When detection returns `type: unknown`:

```markdown
**Detection failed. Ask user:**

<AskUserQuestion>
question: "What type of workflow are you working on?"
options:
  - label: "Epic workflow"
    description: "Multi-sprint project in epics/ directory"
  - label: "Feature workflow"
    description: "Single feature in specs/ directory"
</AskUserQuestion>
```

### Worktree Handling

When `is_worktree: true`, paths are relative to worktree root:

```bash
# Standard workflow
FEATURE_DIR="specs/$SLUG"

# Worktree workflow (same path structure, different root)
FEATURE_DIR="specs/$SLUG"  # Still works, relative to worktree
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Detection successful |
| 1 | Detection failed (use fallback) |

## Cross-Platform Notes

- **Windows**: Requires Git Bash or PowerShell with pwsh
- **macOS/Linux**: Uses bash directly
- **CI/CD**: Works in GitHub Actions, GitLab CI, etc.

## Related Files

- `.spec-flow/scripts/utils/detect-workflow-paths.sh` - Bash implementation
- `.spec-flow/scripts/utils/detect-workflow-paths.ps1` - PowerShell implementation
- `.spec-flow/scripts/bash/shared-lib.sh` - Contains `detect_workflow_type()` helper
