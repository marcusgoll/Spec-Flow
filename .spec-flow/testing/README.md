# Spec-Flow Testing Sandbox

Comprehensive testing infrastructure for smoke testing slash commands, skills, and subagents across multiple workflow scenarios.

## Overview

This testing sandbox provides:
- **Automated smoke tests** for command/skill/agent validation
- **Multiple test scenarios** (greenfield, brownfield, feature, epic, UI-first)
- **Validation modules** for artifacts, state, and structure
- **Test reporting** with automated validation and detailed reports

## Directory Structure

```
.spec-flow/testing/
├── test-harness.mjs          # Main test orchestrator
├── test-report-template.md   # Sample test report format
├── validators/
│   ├── artifact-validator.mjs    # Validate generated files
│   ├── state-validator.mjs       # Validate workflow-state.yaml
│   └── structure-validator.mjs   # Validate directory structure
├── scenarios/
│   ├── 01-greenfield/        # Empty project scenario
│   ├── 02-brownfield/        # Existing codebase scenario
│   ├── 03-feature-workflow/  # Standard feature test
│   ├── 04-epic-workflow/     # Multi-sprint epic test
│   └── 05-ui-first/          # Mockup-first workflow test
├── fixtures/
│   ├── package.json          # Mock existing project
│   ├── migrations/           # Mock database migrations
│   └── docker-compose.yml    # Mock Docker setup
└── reports/
    └── (generated test reports)
```

## Quick Start

### Prerequisites

- Node.js 18+ (for test harness)
- Access to Spec-Flow workflow files (.claude/, .spec-flow/)

### Running Tests

Run all scenarios:
```bash
node .spec-flow/testing/test-harness.mjs
```

Run specific scenario:
```bash
node .spec-flow/testing/test-harness.mjs --scenario greenfield
```

### Expected Output

```
╔════════════════════════════════════════════════════════════════╗
║         Spec-Flow Testing Harness - Smoke Test Suite          ║
╚════════════════════════════════════════════════════════════════╝

================================================================================
📋 Scenario: Greenfield Project
   Test workflow initialization on fresh project
================================================================================
   ✓ Directory structure exists
   ✓ /init-project command structure validation
   ✓ /feature command structure validation
   ✓ Deployment model detection (local-only)

[... more scenarios ...]

================================================================================
📊 Generating test report...
================================================================================

✓ Report saved to: .spec-flow/testing/reports/test-report-1234567890.md

================================================================================
Summary: 20/20 tests passed
================================================================================
```

## Test Scenarios

### 1. Greenfield Project
**Purpose**: Verify workflow on fresh project with no existing code

**Tests**:
- Directory structure validation
- `/init-project` command structure
- `/feature` command structure
- Deployment model detection (local-only)

**Key Validations**:
- 8 project docs generation capability
- Design system initialization (--with-design)
- Foundation issue creation (#1)

[See scenarios/01-greenfield/README.md for details]

---

### 2. Brownfield Project
**Purpose**: Verify workflow on existing codebase with auto-scan

**Tests**:
- Fixture files present (package.json, docker-compose.yml)
- Anti-duplication skill validation
- Technology detection capability

**Key Validations**:
- Tech stack extraction from package.json
- ERD generation from migrations
- Reuse analysis for existing patterns

[See scenarios/02-brownfield/README.md for details]

---

### 3. Feature Workflow
**Purpose**: Verify standard feature workflow end-to-end

**Tests**:
- `/spec` command validation
- `/plan` command validation
- `/tasks` command validation
- Workflow state schema validation

**Key Validations**:
- Sequential phase progression
- Manual gates (spec, plan, staging validation)
- Artifact generation (spec.md, plan.md, tasks.md)
- State transitions (pending → in_progress → completed)

[See scenarios/03-feature-workflow/README.md for details]

---

### 4. Epic Workflow
**Purpose**: Verify multi-sprint epic workflow with parallel execution

**Tests**:
- `/epic` command validation
- `/implement-epic` command validation
- Epic skill validation
- Question bank validation (5 rounds, 8-9 questions)

**Key Validations**:
- Interactive scoping questionnaire
- Meta-prompting (research → plan)
- Sprint breakdown with dependency graph
- Parallel execution by dependency layer
- Contract locking for API versioning

[See scenarios/04-epic-workflow/README.md for details]

---

### 5. UI-First Workflow
**Purpose**: Verify mockup-first workflow with approval gates

**Tests**:
- `/tasks --ui-first` flag validation
- Mockup approval checklist template
- Design system skills validation

**Key Validations**:
- Mockup generation (HTML files)
- Navigation hub for multi-screen (≥3 screens)
- Approval gate blocking mechanism
- Design system integration

[See scenarios/05-ui-first/README.md for details]

---

## Validators

### Artifact Validator
Validates generated files match expected templates.

**Functions**:
- `validateSpec(specPath)` - Validate spec.md structure
- `validatePlan(planPath)` - Validate plan.md structure
- `validateTasks(tasksPath)` - Validate tasks.md (5-30 tasks)
- `validateProjectDocs(docsDir)` - Validate 8 project docs
- `validateEpicSpec(epicSpecPath)` - Validate epic-spec.xml
- `validateSprintPlan(sprintPlanPath)` - Validate sprint-plan.xml
- `validateMockups(mockupsDir)` - Validate HTML mockups

**Usage**:
```javascript
import { validateSpec } from './validators/artifact-validator.mjs';

const result = validateSpec('specs/001-feature/spec.md');
if (!result.valid) {
  console.error('Validation errors:', result.errors);
}
```

---

### State Validator
Validates workflow-state.yaml structure and transitions.

**Functions**:
- `validateWorkflowState(statePath)` - Validate YAML structure
- `validateEpicState(epicState)` - Validate epic state machine
- `validatePhaseTransition(current, next)` - Validate transitions
- `validateManualGates(state)` - Validate approval gates
- `validateQualityGates(state)` - Validate quality gates
- `validateDeploymentInfo(state)` - Validate deployment metadata

**Valid Phases**:
```
initialization → specification → clarification → planning →
task_breakdown → validation → implementation → optimization →
ship_staging → validate_staging → ship_prod/deploy_prod/build_local →
finalization → completed
```

**Valid Statuses**: pending, in_progress, blocked, completed, failed, skipped

**Valid Epic States**: Planned, ContractsLocked, Implementing, Review, Integrated, Released

**Usage**:
```javascript
import { validateWorkflowState } from './validators/state-validator.mjs';

const result = validateWorkflowState('specs/001-feature/workflow-state.yaml');
if (!result.valid) {
  console.error('State validation errors:', result.errors);
}
```

---

### Structure Validator
Validates directory structure and file organization.

**Functions**:
- `validateFeatureStructure(featureDir)` - Validate feature workspace
- `validateEpicStructure(epicDir)` - Validate epic workspace
- `validateProjectStructure(projectDir)` - Validate project structure
- `validateProjectDocsStructure(projectDir)` - Validate 8 project docs
- `validateDesignSystemStructure(projectDir)` - Validate design docs + tokens
- `validateMockupStructure(featureDir, screenCount)` - Validate mockups
- `validateContractsStructure(projectDir)` - Validate API contracts (epic)
- `validateGitStructure(projectDir)` - Validate git repository
- `validateGitHubActionsStructure(projectDir)` - Validate CI/CD workflows

**Usage**:
```javascript
import { validateFeatureStructure } from './validators/structure-validator.mjs';

const result = validateFeatureStructure('specs/001-feature');
if (!result.valid) {
  console.error('Structure validation errors:', result.errors);
}
```

---

## Test Reports

### Report Format

Test reports are generated in Markdown format with:
- Summary statistics (total, passed, failed, skipped, success rate)
- Per-scenario results with test details
- Error details for failures
- Duration metrics
- Recommendations

### Sample Report

```markdown
# Spec-Flow Testing Report

**Generated**: 2025-01-20T10:30:00Z
**Total Duration**: 12.45s

## Summary

- **Total Tests**: 20
- **Passed**: 20 ✓
- **Failed**: 0 ✗
- **Skipped**: 0 ⊘
- **Success Rate**: 100.0%

## Scenarios

### Greenfield Project

**Results**: 4/4 passed

| Test | Status | Duration |
|------|--------|----------|
| Directory structure exists | ✓ passed | 45ms |
| /init-project command structure | ✓ passed | 120ms |
| /feature command structure | ✓ passed | 95ms |
| Deployment model detection | ✓ passed | 80ms |
```

### Report Location

Reports are saved to: `.spec-flow/testing/reports/test-report-[timestamp].md`

---

## Extending Tests

### Adding New Test Scenarios

1. Create scenario directory:
```bash
mkdir -p .spec-flow/testing/scenarios/06-my-scenario
```

2. Create README.md documenting the scenario

3. Add scenario to test-harness.mjs:
```javascript
function createMyScenario() {
  return new TestScenario(
    'My Scenario',
    'Description of what this tests',
    [
      new Test('Test 1', async () => {
        // Test implementation
      }),
      new Test('Test 2', async () => {
        // Test implementation
      })
    ]
  );
}

// Add to scenarios array
const scenarios = [
  // ... existing scenarios
  createMyScenario()
];
```

### Adding New Validators

1. Create validator file:
```bash
touch .spec-flow/testing/validators/my-validator.mjs
```

2. Implement validator:
```javascript
export function validateMyArtifact(path) {
  const errors = [];

  // Validation logic

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}
```

3. Import and use in tests

---

## Troubleshooting

### Tests Failing

1. **Command files not found**
   - Check `.claude/commands/` directory structure
   - Verify command file names match expectations
   - Ensure working directory is project root

2. **Validator errors**
   - Check Node.js version (requires 18+)
   - Install dependencies: `npm install js-yaml`
   - Verify file paths are correct

3. **Timeout errors**
   - Increase timeout in test-harness.mjs (default: 5 minutes)
   - Check for infinite loops in test logic

### Missing Dependencies

Install required packages:
```bash
npm install js-yaml
```

### Permission Errors

Ensure read access to:
- `.claude/` directory
- `.spec-flow/` directory
- `specs/` directory (if testing feature workflows)

---

## Best Practices

### Test Isolation

Each scenario should be independent:
- Don't rely on state from other scenarios
- Use fixtures for test data
- Clean up temporary files

### Validation Depth

Smoke tests should validate:
- File existence and structure
- Command/skill/agent configuration
- Basic YAML/XML parsing
- Required sections present

Smoke tests should NOT:
- Execute actual commands (use mocks)
- Generate real artifacts (use templates)
- Make external API calls
- Modify the codebase

### Test Coverage

Prioritize testing:
1. Critical paths (feature, epic workflows)
2. Integration points (GitHub, deployment)
3. State management (workflow-state.yaml)
4. Manual gates (approval blocking)
5. Error handling (validation failures)

---

## Future Enhancements

Planned improvements:
- [ ] Integration tests (actual command execution)
- [ ] End-to-end workflow tests
- [ ] Performance benchmarking
- [ ] Coverage reporting
- [ ] CI/CD integration (GitHub Actions)
- [ ] Snapshot testing for artifacts
- [ ] Mocking framework for SlashCommand/Skill/Task tools

---

## Contributing

To contribute new tests:

1. Document the test scenario in a README.md
2. Add tests to test-harness.mjs
3. Create fixtures if needed
4. Update this documentation
5. Run tests to verify: `node test-harness.mjs`

---

## Support

For issues or questions:
- Check scenario README files for details
- Review validator documentation
- Examine sample test reports
- Consult CLAUDE.md for workflow documentation

---

## License

Part of the Spec-Flow Workflow Kit.
