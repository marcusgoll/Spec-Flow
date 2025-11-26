# Scenario 4: Epic Workflow

## Purpose

Test multi-sprint epic workflow with parallel execution and dependency management.

## Tests

### 1. Directory Structure Validation

- Verifies scenario directory exists
- **Expected**: Directory present

### 2. /epic Command Validation

- Validates epic.md command file exists
- Checks for epic-spec.md references
- **Expected**: Command file properly structured

### 3. /implement-epic Command Validation

- Validates implement-epic.md command file exists
- Checks for sprint-plan.md references
- **Expected**: Command file properly structured

### 4. Epic Skill Validation

- Validates epic/SKILL.md exists
- **Expected**: Skill file properly structured

### 5. Epic Question Bank Validation

- Validates question-bank.md exists
- Checks for Round 1-5 structure
- **Expected**: Question bank with 8-9 questions

## Workflow Phases

```
/epic "User authentication system"
    ↓
Auto-invoke /init-project (if missing)
    ↓
Interactive Scoping (8-9 questions across 5 rounds)
    ↓
Auto-invoke /clarify (if ambiguity >30%)
    ↓
Meta-Prompting (Research Agent → Plan Agent)
    ↓
Sprint Breakdown (Dependency graph, contract locking)
    ↓
/implement-epic (Parallel execution by dependency layer)
    ↓
Auto /audit-workflow
    ↓
/optimize (Quality gates)
    ↓
/ship (Unified deployment)
    ↓
/finalize (Walkthrough generation)
```

## Expected Artifacts

After `/epic`:

```
epics/001-auth-system/
├── epic-spec.md
├── research.md
├── plan.md
├── sprint-plan.md
├── state.yaml (epic_mode: true)
└── sprints/
    ├── S01/  # Backend + Database
    ├── S02/  # Frontend
    └── S03/  # Integration
```

After `/implement-epic`:

```
(plus)
├── contracts/
│   └── api/
│       └── auth-api-v1.yaml
├── sprints/
│   ├── S01/ (completed)
│   ├── S02/ (completed)
│   └── S03/ (completed)
├── tasks.xml
└── audit-report.xml
```

After `/finalize`:

```
(plus)
└── walkthrough.md  # Epic walkthrough with lessons learned
```

## Parallel Execution Layers

```
Layer 1: S01 (Backend + DB)
         ↓
Layer 2: S02 (Frontend)     [depends on S01]
         ↓
Layer 3: S03 (Integration)  [depends on S01 + S02]
```

## Execution Modes

### Auto Mode (--auto)

- Skip manual pauses
- Run until blocker
- Fastest execution

### Interactive Mode (--interactive)

- Pause at spec review
- Pause at plan review
- User approval required

### 3-Tier Preference System

1. Config file (lowest priority)
2. Command history (medium)
3. Command-line flags (highest)

## Manual Test Steps

1. Navigate to this directory
2. Run `/epic "User authentication system"` (simulated)
3. Verify epic command file structure
4. Verify implement-epic command file structure
5. Verify epic skill exists
6. Verify question bank has proper rounds

## Success Criteria

- ✓ Epic command file references epic-spec.md
- ✓ Implement-epic references sprint-plan.md
- ✓ Epic skill properly structured
- ✓ Question bank has 5 rounds with questions
- ✓ No errors during validation

## Notes

Epic workflow differences from feature workflow:

- Auto-triggers /init-project if missing
- Auto-invokes /clarify if ambiguity >30%
- Uses meta-prompting (research → plan)
- Parallel sprint execution by dependency layer
- Contract locking for API versioning
- Auto-triggers /audit-workflow after implementation
- Generates walkthrough.md with lessons learned
