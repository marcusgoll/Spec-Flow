# Scenario 1: Greenfield Project

## Purpose

Test workflow initialization on a fresh project with no existing code.

## Tests

### 1. Directory Structure Validation

- Verifies scenario directory exists
- **Expected**: Directory present

### 2. /init-project Command Structure

- Validates init-project.md command file
- Checks for docs/project/ references
- **Expected**: Command file exists with proper structure

### 3. /feature Command Structure

- Validates feature.md command file
- Checks for state.yaml references
- **Expected**: Command file exists with workflow state management

### 4. Deployment Model Detection

- Verifies local-only deployment model (no git remote)
- **Expected**: No git remote configured

## Expected Artifacts

After running `/init-project`:

```
01-greenfield/
├── docs/
│   └── project/
│       ├── overview.md
│       ├── system-architecture.md
│       ├── tech-stack.md
│       ├── data-architecture.md
│       ├── api-strategy.md
│       ├── capacity-planning.md
│       ├── deployment-strategy.md
│       └── development-workflow.md
└── .spec-flow/
    └── memory/
        └── state.yaml
```

After running `/init-project --with-design`:

```
(plus)
├── docs/
│   └── design/
│       ├── brand-guidelines.md
│       ├── visual-language.md
│       ├── accessibility-standards.md
│       └── component-governance.md
└── design/
    └── systems/
        ├── tokens.css
        └── tokens.json
```

## Manual Test Steps

1. Navigate to this directory
2. Run `/init-project` (simulated)
3. Verify 8 project docs generated
4. Run `/init-project --with-design` (simulated)
5. Verify 4 design docs + tokens generated
6. Verify deployment model = local-only

## Success Criteria

- ✓ All command files exist and are properly structured
- ✓ Expected directory structure validated
- ✓ Deployment model detection works correctly
- ✓ No errors during command structure validation
