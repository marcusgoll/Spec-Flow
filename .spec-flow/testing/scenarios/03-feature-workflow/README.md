# Scenario 3: Feature Workflow

## Purpose

Test standard feature workflow from specification through deployment.

## Tests

### 1. Directory Structure Validation

- Verifies scenario directory exists
- **Expected**: Directory present

### 2. /spec Command Validation

- Validates spec.md command file exists
- **Expected**: Command file properly structured

### 3. /plan Command Validation

- Validates plan.md command file exists
- **Expected**: Command file properly structured

### 4. /tasks Command Validation

- Validates tasks.md command file exists
- **Expected**: Command file properly structured

### 5. Workflow State Schema Validation

- Checks workflow-state-schema.md exists
- **Expected**: Schema file with proper version

## Workflow Phases

```
/feature "Add dark mode"
    ↓
/spec (Manual Gate #1: Spec Review)
    ↓
/plan (Manual Gate #2: Plan Review)
    ↓
/tasks (auto)
    ↓
/validate (auto)
    ↓
/implement (auto)
    ↓
/optimize (auto, quality gates)
    ↓
/ship-staging (auto, staging-prod model)
    ↓
Staging Validation (Manual Gate #3)
    ↓
/ship-prod (auto)
    ↓
/finalize (auto)
```

## Expected Artifacts

After `/spec`:

```
specs/001-dark-mode/
├── spec.md
├── NOTES.md
├── state.yaml (phase: specification)
└── visuals/
    └── README.md
```

After `/plan`:

```
(plus)
├── plan.md
├── research.md
└── state.yaml (phase: planning)
```

After `/tasks`:

```
(plus)
├── tasks.md (20-30 tasks)
└── state.yaml (phase: task_breakdown)
```

After `/validate`:

```
(plus)
├── analysis-report.md
└── state.yaml (phase: validation)
```

After `/implement`:

```
(plus)
├── NOTES.md (updated with implementation notes)
└── state.yaml (phase: implementation)
```

After `/optimize`:

```
(plus)
├── optimization-report.md
├── code-review-report.md
└── state.yaml (phase: optimization)
```

## Manual Test Steps

1. Navigate to this directory
2. Run through each phase in sequence (simulated)
3. Verify each phase's command file exists
4. Verify workflow state schema exists
5. Verify expected state transitions

## Success Criteria

- ✓ All phase command files exist
- ✓ Command files reference correct artifacts
- ✓ Workflow state schema properly versioned
- ✓ State transitions follow sequential pattern
- ✓ No errors during validation

## Deployment Models

- **staging-prod**: Full workflow with staging validation
- **direct-prod**: Skip staging, go directly to production
- **local-only**: No deployment, local build only
