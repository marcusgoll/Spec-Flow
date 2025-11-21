# CLAUDE.md

Spec-Flow Workflow Kit: Slash commands transform product ideas into production releases via spec-driven development.

## Workflow State Machines

### Feature (≤16h, single subsystem, clear requirements)

```
/feature → /clarify? → /plan → /tasks → /validate → /implement → /ship
```

Ship workflows (model auto-detected):
- **staging-prod**: /optimize → /ship-staging → /validate-staging → /ship-prod → /finalize
- **direct-prod**: /optimize → /deploy-prod → /finalize
- **local-only**: /optimize → /build-local → /finalize

Deployment detection:
- staging-prod: git remote + staging branch + `.github/workflows/deploy-staging.yml`
- direct-prod: git remote + no staging
- local-only: no git remote

### Epic (>16h, multiple subsystems, research required)

```
/epic → /init-project? → /clarify? → /plan → /tasks → /implement-epic → /optimize → /ship → /finalize
```

Differences from /feature:
- Auto-triggers /init-project if missing
- /clarify auto-invoked if ambiguity >30
- /plan uses meta-prompting (research → plan via sub-agents)
- /tasks builds dependency graph, locks API contracts
- /implement-epic executes sprints in parallel layers
- Artifacts: Markdown (epic-spec.md, plan.md, sprint-plan.md, walkthrough.md)
- Auto-triggers /audit-workflow after implementation

### UI-First Workflow

```
/feature → /clarify → /plan → /tasks --ui-first → [MOCKUP APPROVAL] → /implement → /ship
```

Mockup approval gate:
- Trigger: After /tasks --ui-first
- Location: specs/NNN-slug/mockups/*.html
- Checklist: mockup-approval-checklist.md
- Blocks /implement until: workflow-state.yaml manual_gates.mockup_approval.status = approved
- Continue: /feature continue

### Epic Frontend Blueprint Workflow (v9.4+)

**For epics with Frontend subsystem**, HTML blueprints are automatically generated for design iteration before TSX implementation.

```
/epic → /plan → [Epic Overview Generated] → /tasks → [Sprint Blueprints Generated] →
/implement-epic → [Blueprint Approval Gate] → TSX Implementation → /optimize → [Cleanup Blueprints] → /ship
```

**Blueprint generation phases**:
1. **/plan phase**: Generates `epic-overview.html` (navigation hub showing all sprints/screens)
2. **/tasks phase**: Generates individual `sprint-N/screen-*.html` files from sprint-plan.md

**Blueprint characteristics**:
- Pure HTML + Tailwind CSS classes
- Design token integration (tokens.css)
- State switching (success, loading, error, empty)
- Keyboard navigation (H for hub, S for state cycling)
- WCAG 2.1 AA accessibility baseline

**Approval gate** (during /implement-epic):
- **Auto-mode** (`--auto`): Notify and continue automatically
- **Interactive mode**: Optional pause for iteration
- Default: "Continue" (no pause unless requested)
- User can edit HTML files, refresh browser to preview

**TSX conversion workflow**:
1. Blueprint patterns extracted to `blueprint-patterns.md`
2. Edge case checklist generated (`conversion-edge-cases.md`)
3. Developers mirror Tailwind classes in TSX components
4. Optional validation via `validate-tsx-conversion.sh` (skippable with `--skip-validation`)

**Cleanup strategy** (before production):
- Mockups deleted during /optimize phase
- `**/mockups/` gitignored (never committed)
- `blueprint-patterns.md` preserved for reference
- Only TSX components deploy to production

**Blueprint location**: `epics/NNN-slug/mockups/`
- `epic-overview.html` - Navigation hub
- `sprint-N/screen-NN-*.html` - Individual screens

**Skip options**:
- `--skip-validation`: Skip pattern extraction and validation
- `--no-guidance`: Skip edge case checklist
- `--auto`: Skip all approval gates

### Feedback Loops (v10.0+)

Discovered implementation gaps during preview/validation can be addressed without creating new epics.

**When to use**: During staging validation, you discover a missing endpoint or feature that was in the original scope but not implemented.

**Workflow**:
```
/ship-staging → discover gap → /validate-staging --capture-gaps → scope validation →
supplemental tasks generated → /epic continue (iteration 2) → /optimize → /ship
```

**Process**:
1. **Gap Discovery**: During `/validate-staging`, identify missing implementations
2. **Capture Gaps**: Run `/validate-staging --capture-gaps` to launch interactive wizard
3. **Scope Validation**: System auto-validates against epic-spec.md/spec.md
   - ✅ IN SCOPE: Generates supplemental tasks
   - ❌ OUT OF SCOPE: Blocks as feature creep (create new epic)
   - ⚠️ AMBIGUOUS: Requires user decision
4. **Loop Back**: Workflow returns to `/implement` for iteration 2
5. **Execute**: `/epic continue` or `/feature continue` runs only supplemental tasks
6. **Re-validate**: Quality gates re-run, deploy to staging again
7. **Converge**: Max 3 iterations to prevent infinite loops

**Example**:
```bash
# Iteration 1 complete, deployed to staging
/ship-staging

# During testing, discover missing /v1/auth/me endpoint
/validate-staging --capture-gaps
# → System validates: IN SCOPE ✅
# → Generates 3 supplemental tasks (T031, T032, T033)
# → Returns to /implement phase (iteration 2)

# Execute iteration 2 (only 3 tasks, not full re-implementation)
/epic continue
# → Runs T031-T033
# → Re-runs /optimize
# → Deploys to staging again

# No more gaps found
/ship-prod
```

**Artifacts**:
- `gaps.md` — Documented gaps with scope validation results
- `scope-validation-report.md` — Evidence for IN/OUT of scope decisions
- `tasks.md` — Appended supplemental tasks (marked with iteration number)
- `workflow-state.yaml` — Iteration tracking and gap statistics

**Scope Validation Algorithm**:
1. Check if gap mentioned in Objective/Requirements
2. Check if gap excluded in "Out of Scope" section
3. Check if gap aligns with involved subsystems
4. Check if gap relates to acceptance criteria

**Iteration Limits**:
- Max iterations: 3 (prevents infinite loops and scope creep)
- After 3 iterations, remaining gaps → new epic
- Iteration tracking in workflow-state.yaml

## Project Initialization

### /init-project

Generates 8 docs in docs/project/:
1. overview.md — Vision, users, scope, metrics
2. system-architecture.md — C4 diagrams, components, data flows
3. tech-stack.md — Technology choices, rationale
4. data-architecture.md — ERD, schemas, storage
5. api-strategy.md — REST/GraphQL patterns, auth, versioning
6. capacity-planning.md — Scaling model, cost
7. deployment-strategy.md — CI/CD, environments, rollback
8. development-workflow.md — Git flow, PR process, DoD

Interactive: 15 questions (~10min)
Brownfield: Auto-scans package.json, migrations, docker-compose.yml

### /init-project --with-design

Adds 4 design docs in docs/design/:
1. brand-guidelines.md
2. visual-language.md
3. accessibility-standards.md
4. component-governance.md

Generates design/systems/:
- tokens.css — WCAG AA compliant, OKLCH color space
- tokens.json

Interactive: 48 questions (~20-30min)
Brownfield: Scans existing tokens.css, flags WCAG violations

Greenfield: Auto-creates GitHub Issue #1 project-foundation (HIGH priority)
Foundation blocks all other features

## Commands

### Phase Commands
- /feature "name" — Create feature spec
- /epic "goal" [--auto | --interactive | --no-input] — Multi-sprint complex work
- /clarify — Reduce ambiguity via AskUserQuestion
- /plan — Generate design artifacts
- /tasks [--ui-first | --standard | --no-input] — Generate concrete TDD tasks
- /validate — Cross-artifact consistency
- /implement — Execute tasks with TDD (feature workflow)
- /implement-epic — Execute sprints in parallel layers (epic workflow)
- /optimize — 10 parallel quality gates (performance, security, accessibility, code, migrations, Docker, E2E, contracts, load testing, migration integrity) with auto-retry
- /ship — Unified deployment orchestrator
- /ship-staging — Deploy to staging
- /validate-staging — Manual staging testing
- /ship-prod — Tagged promotion to production
- /deploy-prod — Direct production deployment
- /build-local — Local build validation
- /finalize — Documentation, housekeeping

### Workflow Health (v5.0)
- /audit-workflow — Analyze effectiveness (auto-runs after /implement, /implement-epic, /optimize, /finalize)
- /heal-workflow — Apply improvements with approval
- /workflow-health — Aggregate metrics dashboard (--detailed, --trends, --compare)

### Context Management
- /create-prompt — Generate Claude-to-Claude prompts
- /run-prompt <N> [--auto-detect | --parallel | --sequential | --no-input] — Execute prompts in sub-agents
- /whats-next — Handoff document for fresh context
- /add-to-todos — Capture ideas for later
- /check-todos — Resume from backlog
- /audit-skill — Evaluate skill quality
- /audit-slash-command — Audit command effectiveness
- /heal-skill — Apply skill corrections

### Project & Roadmap
- /init-project [--interactive | --ci | --no-input] [--with-design] — Initialize design docs
- /init-preferences [--reset] — Configure command defaults (one-time setup)
- /roadmap — Manage features via GitHub Issues (brainstorm, prioritize, track)
- /help — Context-aware workflow guidance (--verbose for state details)

### Infrastructure (Deprecated/Removed)
Contract, flag, metrics, scheduler commands removed in v6.0+

## Preference System (v7.0+)

Commands use a 3-tier preference system to eliminate flag memorization:

1. **Config File** (`.spec-flow/config/user-preferences.yaml`) - Set once, use forever
2. **Command History** (`.spec-flow/memory/command-history.yaml`) - Learns from usage
3. **Command Flags** - Explicit overrides

### Setup

Run once to configure defaults:
```
/init-preferences
```

12-question wizard configures:
- Command default modes (/epic, /tasks, /init-project, /run-prompt)
- UI preferences (show usage stats, recommend last-used)
- Automation behavior (CI/CD mode)
- Git worktree preferences (auto-creation, cleanup)
- Perpetual learning system (enable, auto-apply, CLAUDE.md optimization)

### How It Works

**Without preferences:**
```
/epic "add auth"
→ Prompts: "Run in auto or interactive mode?"
```

**With preferences (default: interactive):**
```
/epic "add auth"
→ Runs in interactive mode (no prompt)
```

**After learning (used auto 8/10 times):**
```
/epic "add auth"
→ Suggests: "Auto (last used, 8/10 times) ⭐"
```

**Override with flags:**
```
/epic "add auth" --auto
→ Uses auto mode (ignores preferences)
```

**CI/CD automation:**
```
/epic "add auth" --no-input
→ Non-interactive mode for automation
```

### Configuration Files

- `.spec-flow/config/user-preferences.yaml` - User configuration
- `.spec-flow/config/user-preferences.example.yaml` - Template
- `.spec-flow/config/user-preferences-schema.yaml` - Validation schema
- `.spec-flow/memory/command-history.yaml` - Usage tracking

### Universal Flags

All commands support:
- `--no-input` - Disable all prompts for CI/CD
- Mode-specific flags override preferences

## Perpetual Learning System (v10.0+)

Continuously improves workflow efficiency through pattern detection and self-learning capabilities. Learnings persist across npm package updates and accumulate over time.

### Overview

The learning system passively observes workflow execution, detects patterns, and auto-applies safe optimizations while requiring approval for high-risk changes.

**Key capabilities**:
- Performance pattern detection (tool selection, context-aware recommendations)
- Anti-pattern detection (failure prevention, warning system)
- Custom abbreviation learning (project-specific terminology)
- CLAUDE.md optimization (system prompt improvements with approval)

### Learning Categories

**1. Performance Patterns** (`.spec-flow/learnings/performance-patterns.yaml`)
- Auto-applied optimizations
- Tool selection recommendations based on context
- Time-saving strategies
- Confidence threshold: ≥0.90 for auto-apply

Example pattern:
```yaml
id: "grep-before-read-001"
name: "Use Grep before Read for large files"
confidence: 0.95
time_saved_avg: 2.5s
recommendation: "Use Grep with pattern before Read for files >1000 lines"
auto_applied: true
```

**2. Anti-Patterns** (`.spec-flow/learnings/anti-patterns.yaml`)
- Failure pattern detection
- Automatic warnings before risky operations
- Prevention strategies
- Triggers on operations with ≥2 historical failures

Example anti-pattern:
```yaml
id: "schema-without-migration-001"
name: "Editing schema without migration"
severity: "high"
failure_rate: 1.0
warning_message: "⚠️  Never edit schema.prisma directly"
prevention: "Run migration first: prisma migrate dev"
auto_warn: true
```

**3. Custom Abbreviations** (`.spec-flow/learnings/custom-abbreviations.yaml`)
- Project-specific terminology expansion
- Consistent naming patterns
- Auto-expansion in specs and tasks
- Confidence threshold: ≥0.80

Example abbreviation:
```yaml
abbr: "auth"
expansion: "JWT-based authentication with refresh tokens"
confidence: 0.98
usage_count: 15
auto_expand: true
```

**4. CLAUDE.md Tweaks** (`.spec-flow/learnings/claude-md-tweaks.yaml`)
- System prompt optimizations (requires approval)
- Agent preference patterns
- Workflow-specific guidance
- Always marked as high-risk

Example tweak:
```yaml
id: "prefer-backend-dev-agent-001"
category: "agent_preference"
confidence: 0.92
impact: "medium"
status: "pending"
content: |
  ### Agent Selection
  - For FastAPI endpoints, prefer backend-dev agent over general-purpose
approval_required: true
```

### Risk Classification

Learnings are classified into three risk levels:

**Low Risk** (auto-apply):
- Confidence ≥0.90
- Impact: "low" or "none"
- Examples: performance patterns, abbreviations
- Applied automatically without user approval

**Medium Risk** (suggest):
- Confidence 0.70-0.89
- Impact: "medium"
- Presented to user for approval

**High Risk** (require approval):
- CLAUDE.md modifications (always high-risk)
- Confidence <0.70
- Impact: "high"
- Requires explicit user approval via `/heal-workflow`

### Learning Workflow

**Phase 1: Passive Observation**
```bash
# Non-blocking data collection during workflow phases
.spec-flow/scripts/bash/learning-collector.sh collect-after-phase /implement
```

Collects:
- Task execution metrics (duration, success, tools used, retries)
- Tool performance (operation type, file sizes, duration)
- Quality gate results (failures, issues found)
- Agent effectiveness (success rates, patterns)

**Phase 2: Pattern Detection**
```bash
# Statistical analysis (runs during /audit-workflow)
.spec-flow/scripts/bash/analyze-learnings.sh --apply-auto
```

Analyzes:
- Groups observations by context
- Calculates confidence scores (statistical significance ≥0.95)
- Detects patterns with ≥3 occurrences (configurable)
- Classifies risk levels

**Phase 3: Auto-Apply or Approval**

Low-risk patterns:
- Automatically applied to learning files
- Used immediately in next workflow execution
- Logged in `.spec-flow/learnings/learning-metadata.yaml`

High-risk patterns:
- Added to pending approval queue
- Reviewed via `/workflow-health --detailed`
- Applied via `/heal-workflow` after user approval

### Storage Structure

```
.spec-flow/learnings/
├── performance-patterns.yaml      # Auto-applied optimizations
├── anti-patterns.yaml             # Failure prevention
├── custom-abbreviations.yaml      # Project terminology
├── claude-md-tweaks.yaml          # System prompt improvements (pending)
├── learning-metadata.yaml         # Statistics, health, migration history
├── observations/                  # Raw data (temporary)
│   ├── task-observations-YYYYMMDD.yaml
│   ├── tool-observations-YYYYMMDD.yaml
│   └── quality-gate-observations-YYYYMMDD.yaml
└── archive/                       # Version archives
    ├── v9.4.0/
    └── v10.0.0/
```

### Migration System

Learnings persist across npm package updates via migration system:

**Before npm update**:
```bash
# Archive current learnings
.spec-flow/scripts/bash/migrate-learnings.sh --from 9.4.0 --to 10.0.0 --dry-run
```

**After npm update**:
```bash
# Auto-detect and migrate
.spec-flow/scripts/bash/migrate-learnings.sh --auto
```

**Migration workflow**:
1. Archives current learnings to `.spec-flow/learnings/archive/v{version}/`
2. Applies schema migrations (add fields, rename keys)
3. Merges archived learnings with new schema
4. Updates metadata with migration history

**Committed to git**: All learning files should be committed to preserve knowledge across team members and machines.

### Configuration

Enable/disable via `/init-preferences` or edit `.spec-flow/config/user-preferences.yaml`:

```yaml
learning:
  # Master switch
  enabled: true

  # Auto-apply low-risk patterns
  auto_apply_low_risk: true

  # Require approval for high-risk changes
  require_approval_high_risk: true

  # Allow CLAUDE.md optimization (with approval)
  claude_md_optimization: true

  # Detection thresholds
  thresholds:
    pattern_detection_min_occurrences: 3
    statistical_significance: 0.95
```

### Scripts and Utilities

**Collection**:
- `.spec-flow/scripts/bash/learning-collector.sh` - Passive observation
- `.spec-flow/scripts/powershell/learning-collector.ps1` - Windows version

**Analysis**:
- `.spec-flow/scripts/python/pattern-detector.py` - Statistical analysis
- `.spec-flow/scripts/bash/analyze-learnings.sh` - Orchestration

**Application**:
- `.spec-flow/scripts/bash/auto-apply-learnings.sh` - Apply low-risk patterns
- `.spec-flow/scripts/bash/optimize-claude-md.sh` - Append to CLAUDE.md (with approval)

**Migration**:
- `.spec-flow/scripts/bash/migrate-learnings.sh` - Preserve across updates

### Usage Examples

**Check pending learnings**:
```bash
bash .spec-flow/scripts/bash/optimize-claude-md.sh --list-pending
```

**Apply approved CLAUDE.md tweak**:
```bash
bash .spec-flow/scripts/bash/optimize-claude-md.sh --apply tweak-001 --approve
```

**View learning statistics**:
```bash
/workflow-health --detailed
```

**Manual pattern analysis**:
```bash
bash .spec-flow/scripts/bash/analyze-learnings.sh --apply-auto
```

## Artifacts by Command

| Command | Outputs |
|---------|---------|
| /feature | spec.md, NOTES.md, visuals/README.md, workflow-state.yaml |
| /plan | plan.md, research.md |
| /tasks | tasks.md, mockup-approval-checklist.md (UI-first), e2e-tests.md (epic) |
| /validate | analysis-report.md |
| /implement | Task completions (feature workflow) |
| /implement-epic | Sprint results, contracts/*.yaml, audit-report.xml (epic workflow) |
| /optimize | optimization-report.md, code-review-report.md, e2e-test-results.log (epic), contract-validation-report.md (epic), load-test-results.log (epic, optional), migration-integrity-report.md (epic) |
| /ship-staging | staging-ship-report.md, deployment-metadata.json |
| /ship-prod | production-ship-report.md, GitHub release |
| /deploy-prod | production-ship-report.md |
| /build-local | local-build-report.md |
| /epic | epic-spec.md, plan.md, sprint-plan.md, walkthrough.md |
| /finalize | Archives all artifacts to {workspace}/completed/ (automatic) |

## State Management

workflow-state.yaml tracks:
- Current phase, status
- Completed/failed phases
- Quality gates (pre-flight, code-review, rollback)
- Manual gates (mockup-approval, preview, staging-validation)
- Deployment info (URLs, IDs, timestamps)
- Artifact paths
- Workflow type (epic/feature) and base directory (v2.1.0)

## Artifact Archival (v9.3+)

After `/finalize` completes successfully, all workflow artifacts are automatically archived to maintain a clean workspace while preserving historical context.

### Epic Workflows

```
epics/001-auth-system/
├── completed/              # Archived after /finalize
│   ├── epic-spec.md
│   ├── plan.md
│   ├── sprint-plan.md
│   ├── tasks.md
│   ├── NOTES.md
│   ├── research.md
│   └── walkthrough.md
└── workflow-state.yaml     # Stays in root for metrics
```

### Feature Workflows

```
specs/001-user-login/
├── completed/              # Archived after /finalize
│   ├── spec.md
│   ├── plan.md
│   ├── tasks.md
│   └── NOTES.md
└── workflow-state.yaml     # Stays in root
```

### Archival Pattern

**Trigger**: Automatic during `/finalize` command (Step 12)

**What gets archived**:
- All planning and implementation artifacts
- Documentation and notes
- Sprint plans (epics only)

**What stays**:
- workflow-state.yaml (for metrics and history)
- contracts/ directory (if exists)
- Any build/deployment artifacts

**Provenance**: Completed artifacts stay with the epic/spec for historical context

**Recovery**: Restore by moving files back from completed/ subfolder:
```bash
mv epics/001-auth-system/completed/* epics/001-auth-system/
```

## Workflow Type Detection (v9.2+)

All phase commands auto-detect whether they're working with epic or feature workflows using centralized detection utilities.

### Detection Priority

Three-tier detection system (Files → Branch → State):

1. **Workspace files** (highest priority):
   - Checks for `epics/*/epic-spec.md` → Epic workflow
   - Checks for `specs/*/spec.md` → Feature workflow

2. **Git branch pattern** (fallback):
   - Branch matches `epic/*` → Epic workflow
   - Branch matches `feature/*` → Feature workflow

3. **Workflow state** (lowest priority):
   - Reads `workflow_type` field from workflow-state.yaml

4. **User prompt** (detection failed):
   - Uses AskUserQuestion if all detection methods fail

### Detection Utilities

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

### Phase Command Integration

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

### Continue Mode Detection

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
❌ Error: This is a feature workflow, not an epic
   Use /feature continue for feature workflows

# If detection fails
⚠️ Could not auto-detect workflow type
   [Prompts user via AskUserQuestion]
```

## Git Worktrees (v10.0+)

Enables parallel development of multiple epics and features by running separate Claude Code instances in isolated git worktrees.

### Overview

Git worktrees allow multiple working directories for the same repository, enabling simultaneous work on different branches without conflicts. Each epic/feature gets its own worktree with shared memory linking for observability and learning data.

**Key benefits**:
- Run multiple Claude Code instances simultaneously
- Work on multiple epics/features in parallel
- Isolated workspaces prevent branch conflicts
- Shared memory for cross-worktree observability
- Automatic cleanup after feature completion

### How It Works

**Traditional workflow** (single branch):
```bash
# Must switch branches and stash changes
git checkout main
git checkout -b feature/login
# Work on login
git checkout main
git checkout -b feature/dashboard  # Can't work on both simultaneously
```

**Worktree workflow** (parallel development):
```bash
# Epic 1 in main directory
/epic "auth system"
# → Creates worktree: worktrees/epic/001-auth-system/

# Epic 2 in new Claude Code instance
cd worktrees/epic/002-user-dashboard/
/epic continue
# → Both epics work independently without conflicts
```

### Automatic Worktree Creation

When enabled via `/init-preferences`, worktrees are automatically created during `/epic` and `/feature` commands:

**Epic workflow**:
```bash
/epic "auth system"
# → Step 1: Branch and worktree creation
#   - Creates branch: epic/001-auth-system
#   - Creates worktree: worktrees/epic/001-auth-system/
#   - Links .spec-flow/memory/ via symlink
#   - Switches context to worktree directory
```

**Feature workflow**:
```bash
/feature "user login"
# → Creates branch: feature/001-user-login
# → Creates worktree: worktrees/feature/001-user-login/
# → Links shared memory
```

### Workspace Isolation

Each worktree maintains isolated workspace:

**Isolated** (per-worktree):
- Working directory files
- Branch-specific code
- Epic/feature artifacts (specs/, epics/)
- Git staging area

**Shared** (via symlinks):
- `.spec-flow/memory/` — Workflow mechanics and observation data
- Learning observations collected in main repo
- Command history and execution logs

### Directory Structure

```
my-project/                        # Main repository
├── .git/                          # Git database
├── .spec-flow/
│   ├── memory/                    # Shared across worktrees (symlinked)
│   ├── learnings/                 # Shared learning data
│   └── config/
├── worktrees/                     # Worktree container (gitignored)
│   ├── epic/
│   │   ├── 001-auth-system/       # Epic 1 workspace
│   │   │   ├── .spec-flow/
│   │   │   │   └── memory -> ../../../.spec-flow/memory  # Symlink
│   │   │   ├── epics/
│   │   │   │   └── 001-auth-system/
│   │   │   └── [project files]
│   │   └── 002-user-dashboard/    # Epic 2 workspace
│   │       └── [isolated files]
│   └── feature/
│       ├── 001-user-login/        # Feature 1 workspace
│       └── 002-password-reset/    # Feature 2 workspace
```

### Memory Linking Strategy

**Symlink creation** (Linux/Mac/Git Bash):
```bash
ln -s ../../../.spec-flow/memory worktrees/epic/001-auth-system/.spec-flow/memory
```

**Junction creation** (Windows PowerShell):
```powershell
New-Item -ItemType Junction -Path "worktrees\epic\001-auth-system\.spec-flow\memory" `
         -Target ".spec-flow\memory"
```

**Benefits**:
- Observations from all worktrees collected centrally
- Learning system sees patterns across all parallel work
- Workflow health metrics aggregate across epics
- No data duplication or synchronization needed

### Worktree Lifecycle

**1. Creation** (automatic):
```bash
# Via /epic or /feature with worktrees.auto_create: true
bash .spec-flow/scripts/bash/worktree-manager.sh create epic 001-auth-system epic/001-auth-system
```

**2. Active Development**:
- Work proceeds normally in worktree directory
- All workflow commands function identically
- Observations collected to shared memory

**3. Cleanup** (automatic on /finalize):
```bash
# After /ship-prod or /deploy-prod completes
# Triggered during /finalize if worktrees.cleanup_on_finalize: true
bash .spec-flow/scripts/bash/worktree-manager.sh remove 001-auth-system
```

**Manual cleanup**:
```bash
# List all worktrees
bash .spec-flow/scripts/bash/worktree-manager.sh list

# Cleanup merged worktrees
bash .spec-flow/scripts/bash/worktree-manager.sh cleanup

# Remove specific worktree
bash .spec-flow/scripts/bash/worktree-manager.sh remove 001-auth-system
```

### Configuration

Enable/disable via `/init-preferences` or edit `.spec-flow/config/user-preferences.yaml`:

```yaml
worktrees:
  # Automatically create worktrees for epics/features
  # Default: false (use regular branches)
  auto_create: false

  # Automatically cleanup worktrees after /finalize
  # Default: true (recommended)
  cleanup_on_finalize: true
```

**Recommendation**: Keep `auto_create: false` unless you regularly work on multiple epics/features simultaneously.

### Detection and Path Resolution

Worktree detection is integrated into `detect-workflow-paths.sh/ps1`:

**Output includes worktree info**:
```json
{
  "type": "epic",
  "base_dir": "epics",
  "slug": "001-auth-system",
  "branch": "epic/001-auth-system",
  "source": "files",
  "is_worktree": true,
  "worktree_path": "worktrees/epic/001-auth-system",
  "worktree_type": "epic",
  "worktree_slug": "001-auth-system"
}
```

### Scripts and Utilities

**Worktree Management**:
- `.spec-flow/scripts/bash/worktree-manager.sh` - CRUD operations
- `.spec-flow/scripts/powershell/worktree-manager.ps1` - Windows version

**Commands**:
```bash
# Create worktree
worktree-manager.sh create <type> <slug> <branch>

# List all worktrees
worktree-manager.sh list [--json]

# Remove worktree
worktree-manager.sh remove <slug> [--force]

# Cleanup merged worktrees
worktree-manager.sh cleanup [--dry-run]

# Check if path is a worktree
worktree-manager.sh is-worktree [path]
```

**Detection**:
- `.spec-flow/scripts/utils/detect-workflow-paths.sh` - Enhanced with worktree detection
- `.spec-flow/scripts/utils/detect-workflow-paths.ps1` - Windows version

### Integration with Commands

**Epic command** (`.claude/commands/epic/epic.md`):
- Step 1: Checks `worktrees.auto_create` preference
- Creates worktree instead of regular branch if enabled
- Switches to worktree directory automatically

**Feature command** (`.spec-flow/scripts/bash/create-new-feature.sh`):
- Integrated worktree creation with fallback to branches
- Updates feature directory path to worktree location

**Finalize command** (`.spec-flow/scripts/bash/finalize-workflow.sh`):
- Step 11: Checks `worktrees.cleanup_on_finalize` preference
- Removes worktree after successful deployment
- Preserves main repository state

### Use Cases

**1. Parallel Epic Development**:
```bash
# Terminal 1 - Backend epic
cd ~/projects/myapp
/epic "authentication system"

# Terminal 2 - Frontend epic (new Claude Code instance)
cd ~/projects/myapp/worktrees/epic/002-dashboard-redesign
/epic continue
```

**2. Epic + Urgent Hotfix**:
```bash
# Working on epic in main directory
/epic continue  # Long-running implementation

# Urgent bug reported (new terminal)
cd ~/projects/myapp/worktrees/feature/urgent-fix
/feature "fix critical login bug"
/implement
/ship
# → Epic work continues uninterrupted in main directory
```

**3. Multiple Team Members**:
```bash
# Developer A - Epic 1
/epic "payment integration"

# Developer B - Epic 2 (different machine/worktree)
/epic "notification system"

# Both share learnings via git-committed .spec-flow/learnings/
```

### Troubleshooting

**Symlink creation fails**:
- Windows: Run as Administrator or enable Developer Mode
- Linux/Mac: Check permissions on .spec-flow/memory/

**Worktree not detected**:
```bash
# Verify git worktree list
git worktree list

# Check detection utility
bash .spec-flow/scripts/utils/detect-workflow-paths.sh
```

**Cleanup fails**:
```bash
# Force remove worktree
bash .spec-flow/scripts/bash/worktree-manager.sh remove 001-auth-system --force

# Manually remove via git
git worktree remove worktrees/epic/001-auth-system --force
```

## Quality Gates

### Blocking
- Pre-flight: env vars, build, docker, CI config
- Code review: No critical issues, performance, WCAG 2.1 AA, security
- Rollback (staging-prod only): Test actual rollback before production

### Manual (pause for approval)
- Mockup approval (UI-first only)
- Staging validation (staging-prod only)

Resume: /ship continue or /feature continue

## Living Documentation (v4.0)

Hierarchical CLAUDE.md:
```
Root CLAUDE.md (workflow overview)
  ↓ Project CLAUDE.md (active features, tech stack)
    ↓ Feature CLAUDE.md (current progress, specialists)
```

Token cost:
- Traditional: 12,700 tokens
- Hierarchical: 2,500 tokens (80% reduction)
- Resume work: 500 tokens (94% reduction)

Auto-updates:
- Feature CLAUDE.md: /feature, task completion, /feature continue
- Project CLAUDE.md: /init-project, /ship-staging, /ship-prod, /deploy-prod

Living sections:
- spec.md → Implementation Status
- plan.md → Discovered Patterns
- tasks.md → Progress Summary (velocity, ETA, bottlenecks)

Health check: `.spec-flow/scripts/bash/health-check-docs.sh`

## Directory Structure

- .claude/agents/ — Specialist briefs
- .claude/commands/ — Command specs
- .claude/skills/ — Reusable workflows
- .spec-flow/memory/ — Workflow mechanics
- .spec-flow/templates/ — Artifact scaffolds
- .spec-flow/scripts/ — Automation (powershell/, bash/, python/, utils/)
- .spec-flow/learnings/ — Perpetual learning data (v10.0+)
- .spec-flow/config/ — User preferences and schemas
- specs/NNN-slug/ — Feature working directories
- epics/NNN-slug/ — Epic working directories
- worktrees/ — Git worktrees for parallel development (v10.0+, gitignored)
- docs/project/ — Project design docs
- docs/design/ — Design system (if --with-design)
- design/systems/ — tokens.css, tokens.json

## Agent Organization

Phase: spec, clarify, plan, tasks, validate, implement, optimize, ship-staging, ship-prod, finalize, epic

Implementation: backend, frontend, database, api-contracts, test-architect

Quality/Code: code-reviewer, refactor-planner, refactor-surgeon, type-enforcer, cleanup-janitor

Quality/Testing: qa-tester, test-coverage, api-fuzzer, accessibility-auditor, ux-polisher

Quality/Security: security-sentry, performance-profiler, error-budget-guardian

Quality/DevTools: debug, auto-error-resolver, web-research-specialist

Quality/Operations: dependency-curator, data-modeler, observability-plumber, ci-sentry

Quality/Deployment: release, git-steward, docs-scribe, release-manager

Load briefs from .claude/agents/ for context

## Coding Standards

Markdown: Sentence-case headings, wrap ~100 chars, imperative voice, bullets for checklists

PowerShell: 4-space indent, Verb-Noun names, comment help, no aliases, support -WhatIf

Shell: POSIX-friendly, set -e, document required tools

Naming: kebab-case files, CamelCase only for PowerShell modules

Commits: Conventional Commits (feat/fix/docs/chore/refactor/test), <75 chars, imperative

## Context Management

Token budgets: Planning (75k), Implementation (100k), Optimization (125k)
Auto-compact at 80% threshold
Scripts:
- .spec-flow/scripts/bash/calculate-tokens.sh
- .spec-flow/scripts/bash/compact-context.sh
- .spec-flow/scripts/powershell/calculate-tokens.ps1
- .spec-flow/scripts/powershell/compact-context.ps1

## Question Banks (v5.0)

Use AskUserQuestion extensively:
- .claude/skills/clarify/references/question-bank.md (40+ feature questions)
- .claude/skills/epic/references/question-bank.md (8-9 epic scoping questions)

Batch 2-3 related questions, multiSelect for subsystems, conditional rounds for progressive refinement

## Workflow Integration

/roadmap reads: overview.md, tech-stack.md, capacity-planning.md

/spec reads: tech-stack.md, api-strategy.md, data-architecture.md, system-architecture.md

/plan reads: ALL 8 project docs (generates research.md)

/tasks --ui-first reads: visual-language.md, brand-guidelines.md, accessibility-standards.md

/implement reads: component-governance.md, visual-language.md

/implement-epic reads: sprint-plan.md, epic-spec.md, plan.md, locked API contracts

## References

- README.md — Quick start
- docs/architecture.md — Workflow structure
- docs/commands.md — Command catalog
- docs/LIVING_DOCUMENTATION.md — Hierarchical context guide
- CONTRIBUTING.md — Branching, PRs, releases
- AGENTS.md — Contributor guide
- CHANGELOG.md — Version history
