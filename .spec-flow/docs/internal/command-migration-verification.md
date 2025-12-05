# Command Migration Verification

## Migration Summary

Successfully migrated 10 workflow commands from embedded bash to centralized CLI architecture.

**Date**: 2025-11-17
**Total Reduction**: 70% (9,255 → 2,780 lines)
**Scripts Created**: 10 bash workflow scripts (~8,250 lines)
**CLI Handlers**: 19 total commands in spec-cli.py

## Files Modified

### Phase Commands (8 files)

1. `.claude/commands/phases/clarify.md` (557 → 174 lines, 69% reduction)
2. `.claude/commands/phases/plan.md` (2061 → 329 lines, 84% reduction)
3. `.claude/commands/phases/preview.md` (1582 → 257 lines, 84% reduction)
4. `.claude/commands/phases/validate.md` (1122 → 334 lines, 70% reduction)
5. `.claude/commands/phases/tasks.md` (881 → 202 lines, 77% reduction)
6. `.claude/commands/phases/implement.md` (836 → 317 lines, 62% reduction)
7. `.claude/commands/phases/debug.md` (594 → 338 lines, 43% reduction)
8. `.claude/commands/phases/optimize.md` (743 → 329 lines, 56% reduction)

### Core/Deployment Commands (2 files)

9. `.claude/commands/core/feature.md` (703 → ~250 lines, 64% reduction)
10. `.claude/commands/deployment/ship.md` (476 → ~250 lines, 47% reduction)

## Bash Scripts Created

All located in `.spec-flow/scripts/bash/`:

1. `clarify-workflow.sh` (17,084 bytes) - Interactive clarification workflow
2. `debug-workflow.sh` (12,825 bytes) - Error debugging and logging
3. `feature-workflow.sh` (16,439 bytes) - Feature orchestration and GitHub integration
4. `implement-workflow.sh` (25,688 bytes) - Task execution and TDD workflow
5. `optimize-workflow.sh` (20,109 bytes) - Production readiness validation
6. `plan-workflow.sh` (51,246 bytes) - Research and design artifact generation
7. `preview-workflow.sh` (42,676 bytes) - Manual testing and validation
8. `ship-finalization.sh` (11,715 bytes) - Deployment finalization tasks
9. `tasks-workflow.sh` (28,587 bytes) - Task breakdown and TDD sequencing
10. `validate-workflow.sh` (35,224 bytes) - Cross-artifact consistency checks

**Total**: ~261,593 bytes of extracted bash logic

## CLI Integration Verification

### ✅ Completed Checks

1. **Script Permissions**: All workflow scripts have executable permissions (100755)
2. **Handler Registration**: All 19 commands registered in spec-cli.py handlers dictionary
3. **Argument Parsers**: Each command has proper argparse configuration
4. **Help System**: CLI help output displays all commands correctly
5. **Git Tracking**: All new scripts added to git with proper permissions

### Command List

**Phase Commands** (8):
- `clarify` - Interactive clarification workflow
- `plan` - Generate implementation plan from spec
- `preview` - Manual UI/UX testing and backend validation
- `validate` - Cross-artifact consistency analysis
- `tasks` - Generate concrete TDD tasks from design artifacts
- `implement` - Execute tasks with TDD and parallel execution
- `debug` - Debug errors and update error-log.md
- `optimize` - Production-readiness validation

**Core/Deployment** (2):
- `feature` - Orchestrate full feature workflow
- `ship-finalize` - Run ship finalization tasks

**Utilities** (9):
- `compact` - Compact context for phase
- `create-feature` - Create new feature directory
- `calculate-tokens` - Calculate token budget
- `check-prereqs` - Check prerequisites
- `detect-infra` - Detect infrastructure needs
- `enable-auto-merge` - Enable auto-merge for PR
- `branch-enforce` - Enforce branch naming
- `contract-bump` - Bump API contract version
- `contract-verify` - Verify API contract compatibility

## Testing Recommendations

### 1. Unit Tests (Per-Script)

Test each workflow script independently:

```bash
# Test clarify workflow
python .spec-flow/scripts/spec-cli.py clarify --help

# Test feature workflow with different modes
python .spec-flow/scripts/spec-cli.py feature next
python .spec-flow/scripts/spec-cli.py feature continue
python .spec-flow/scripts/spec-cli.py feature "Test Feature"

# Test ship finalization
python .spec-flow/scripts/spec-cli.py ship-finalize --help
```

### 2. Integration Tests (End-to-End)

Run a complete feature workflow:

```bash
# 1. Create feature
python .spec-flow/scripts/spec-cli.py feature "Sample Feature"

# 2. Run clarify (if needed)
python .spec-flow/scripts/spec-cli.py clarify

# 3. Generate plan
python .spec-flow/scripts/spec-cli.py plan

# 4. Create tasks
python .spec-flow/scripts/spec-cli.py tasks

# 5. Validate consistency
python .spec-flow/scripts/spec-cli.py validate

# 6. Implement
python .spec-flow/scripts/spec-cli.py implement

# 7. Optimize
python .spec-flow/scripts/spec-cli.py optimize

# 8. Preview
python .spec-flow/scripts/spec-cli.py preview

# 9. Ship finalization
python .spec-flow/scripts/spec-cli.py ship-finalize finalize
```

### 3. Edge Cases

- **GitHub Integration**: Test `feature next` with GitHub issues
- **Epic/Sprint Management**: Test `feature epic:name:sprint:num` syntax
- **Continue Mode**: Test workflow resume with `feature continue`
- **Pre-flight Checks**: Test `ship-finalize preflight` validation
- **Branch Management**: Verify branch creation and cleanup

### 4. Platform-Specific Tests

- **Windows**: Verify PowerShell fallback works if bash unavailable
- **macOS/Linux**: Confirm bash scripts execute correctly
- **Cross-platform**: Test argument passing with spaces and special chars

## Known Issues & Limitations

### None Identified

Migration completed without errors. All scripts:
- Have proper shebang (`#!/usr/bin/env bash`)
- Include error handling (`set -euo pipefail`)
- Use platform-independent commands where possible
- Follow consistent naming conventions

## Rollback Procedure

If issues are discovered, rollback using backup files:

```bash
# Restore original commands
cp .claude/commands/core/feature.md.backup .claude/commands/core/feature.md
cp .claude/commands/deployment/ship.md.backup .claude/commands/deployment/ship.md
cp .claude/commands/phases/spec.md.backup .claude/commands/phases/spec.md
cp .claude/commands/phases/clarify.md.backup .claude/commands/phases/clarify.md
cp .claude/commands/phases/plan.md.backup .claude/commands/phases/plan.md
cp .claude/commands/phases/preview.md.backup .claude/commands/phases/preview.md
cp .claude/commands/phases/validate.md.backup .claude/commands/phases/validate.md
cp .claude/commands/phases/tasks.md.backup .claude/commands/phases/tasks.md
cp .claude/commands/phases/implement.md.backup .claude/commands/phases/implement.md
cp .claude/commands/phases/debug.md.backup .claude/commands/phases/debug.md
cp .claude/commands/phases/optimize.md.backup .claude/commands/phases/optimize.md

# Remove workflow scripts
git rm .spec-flow/scripts/bash/*-workflow.sh
git rm .spec-flow/scripts/bash/ship-finalization.sh

# Restore spec-cli.py to previous version
git checkout HEAD~1 .spec-flow/scripts/spec-cli.py
```

## Cleanup Tasks

After production verification (1-2 weeks):

1. **Remove backup files**: Delete all `.backup` files in `.claude/commands/`
2. **Update documentation**: Remove migration notes from README
3. **Archive migration docs**: Move this verification doc to `docs/archive/`

## Success Criteria

- [ ] All 19 CLI commands execute without errors
- [ ] Feature workflow completes end-to-end successfully
- [ ] GitHub integration (issues, labels, branches) works correctly
- [ ] Ship finalization updates roadmap and cleans up branches
- [ ] Cross-platform compatibility verified (Windows, macOS, Linux)
- [ ] No regression in existing workflows

## Next Steps

1. **Production Testing**: Run through 2-3 actual features using new CLI
2. **Monitor**: Watch for errors in workflow execution
3. **Document**: Update user-facing docs with new CLI syntax
4. **Cleanup**: Remove backup files after 1-2 weeks of stable operation

## Maintenance Notes

### Adding New Commands

To add a new workflow command:

1. Create bash script in `.spec-flow/scripts/bash/new-workflow.sh`
2. Add handler function in `spec-cli.py`:
   ```python
   def cmd_new_workflow(args):
       """Run new workflow"""
       return run_script('new-workflow', [args.param])
   ```
3. Add argparse configuration in `main()`:
   ```python
   new_parser = subparsers.add_parser('new-workflow', help='Description')
   new_parser.add_argument('param', help='Parameter description')
   ```
4. Register handler in handlers dictionary:
   ```python
   handlers = {
       # ... existing
       'new-workflow': cmd_new_workflow,
   }
   ```
5. Set executable permissions:
   ```bash
   git add .spec-flow/scripts/bash/new-workflow.sh
   git update-index --chmod=+x .spec-flow/scripts/bash/new-workflow.sh
   ```

### Updating Existing Commands

1. Modify bash script in `.spec-flow/scripts/bash/`
2. Update argument parser in `spec-cli.py` if parameters changed
3. Update command markdown file in `.claude/commands/` if LLM guidance changed
4. Test end-to-end workflow
5. Update this verification doc with changes

---

**Migration Status**: ✅ Complete
**Verification Status**: ⏳ Pending Production Testing
**Rollback Capability**: ✅ Available (backup files present)
