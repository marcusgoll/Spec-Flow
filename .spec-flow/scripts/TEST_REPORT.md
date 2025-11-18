# Spec-CLI Test Report

**Date**: 2025-11-18
**Tested By**: Claude Code Autonomous Testing
**Total Commands Tested**: 59 (40 help commands + 19 functional tests)

## Executive Summary

### Help Command Tests: ✅ 100% PASS (40/40)
All `--help` commands execute without errors and display usage information correctly.

### Functional Tests: ⚠️ 15.8% PASS (3/19)

**Passing Tests**:
1. ✅ `calculate-tokens --feature-dir nonexistent` - Fails gracefully with exit code 1 (expected)
2. ✅ `compact --feature-dir nonexistent --phase planning` - Fails gracefully with exit code 1 (expected)
3. ✅ `roadmap track --json` - Succeeds with exit code 0

**Failing Tests** (16 tests):
- ❌ Commands that succeed but return wrong exit code (exit 1 instead of 0)
- ❌ Commands missing underlying bash scripts

## Issues Found

### Issue #1: spec-cli.py Stderr Pollution (FIXED ✅)
**Location**: `.spec-flow/scripts/spec-cli.py:99`
**Problem**: Fallback message "Note: PowerShell script not found, using bash: ..." polluted stderr
**Impact**: Test failures, noise in LLM outputs
**Fix**: Removed stderr output unless `SPEC_CLI_VERBOSE=1` environment variable is set
**Status**: ✅ FIXED

### Issue #2: Bash Scripts Return Wrong Exit Codes (CRITICAL ❌)
**Affected Commands**:
- `check-prereqs --json`
- `health-check-docs --json`
- `scheduler-list --json`
- `metrics-dora --json`
- `design-health --json`
- `clarify nonexistent-feature --json`
- `plan nonexistent-feature --json`
- `tasks nonexistent-feature --json`
- `validate nonexistent-feature --json`
- `implement nonexistent-feature --json`
- `optimize nonexistent-feature --json`
- `preview nonexistent-feature --json`
- `debug nonexistent-feature --json`

**Problem**: Bash scripts return exit code 1 even when successfully outputting JSON
**Example**: `health-check-docs --json` outputs valid JSON but exits with code 1
**Impact**: LLM integration may interpret successful operations as failures
**Root Cause**: Bash scripts don't explicitly `exit 0` at the end
**Fix Needed**: Add `exit 0` to all bash scripts that succeed
**Status**: ❌ NOT FIXED

### Issue #3: Missing Bash Scripts (CRITICAL ❌)
**Affected Commands**:
- `contract-verify`
- `detect-infra`

**Problem**: Bash scripts don't exist:
- `D:\coding\workflow\.spec-flow\scripts\bash\contract-verify.sh` - Missing
- `D:\coding\workflow\.spec-flow\scripts\bash\detect-infrastructure-needs.sh` - Missing

**Impact**: Commands fail completely when PowerShell scripts don't exist
**Fix Needed**: Create missing bash scripts or ensure PowerShell scripts exist for all commands
**Status**: ❌ NOT FIXED

### Issue #4: Bash Path Resolution on Windows (WARNING ⚠️)
**Location**: spec-cli.py bash fallback logic
**Problem**: Windows paths with backslashes (`D:\coding\...`) passed to bash cause:
```
/bin/bash: D:codingworkflow.spec-flowscriptsbashcontract-verify.sh: No such file or directory
```

**Impact**: Bash can't execute scripts when given Windows paths
**Root Cause**: Bash on Windows expects Unix-style paths (`/d/coding/...`)
**Workaround**: spec-cli.py converts paths to strings, but bash interprets backslashes incorrectly
**Fix Needed**: Convert Windows paths to Unix-style before passing to bash:
```python
if shell_type == 'bash' and IS_WINDOWS:
    script_path = '/' + str(script_path).replace('\\', '/').replace(':', '', 1)
```
**Status**: ⚠️ PARTIAL (works for existing scripts, fails for missing ones)

## Recommendations

### Priority 1: Fix Exit Codes (Immediate)
Add `exit 0` to the end of all bash scripts in `.spec-flow/scripts/bash/`:
- `check-prerequisites.sh`
- `health-check-docs.sh`
- `scheduler-list.sh`
- `dora-calculate.sh`
- `design-health-check.sh`
- `clarify-workflow.sh`
- `plan-workflow.sh`
- `tasks-workflow.sh`
- `validate-workflow.sh`
- `implement-workflow.sh`
- `optimize-workflow.sh`
- `preview-workflow.sh`
- `debug-workflow.sh`

### Priority 2: Create Missing Scripts (High)
Create bash implementations for:
- `contract-verify.sh`
- `detect-infrastructure-needs.sh`

OR ensure PowerShell equivalents exist.

### Priority 3: Improve Windows Bash Path Handling (Medium)
Update spec-cli.py line 102 to convert Windows paths to Unix-style for bash:
```python
if shell_type == 'bash' and IS_WINDOWS:
    # Convert D:\path\to\script.sh to /d/path/to/script.sh
    unix_path = '/' + str(script_path).replace('\\', '/').replace(':', '', 1)
    cmd = ['bash', unix_path]
else:
    cmd = ['bash', str(script_path)]
```

### Priority 4: Add Verbose Mode Flag (Low)
Add `--verbose` flag to spec-cli.py to enable `SPEC_CLI_VERBOSE=1` debugging.

## Test Artifacts

### Test Suite Files
- `.spec-flow/scripts/test-spec-cli.py` - Help command tests (40 tests)
- `.spec-flow/scripts/test-spec-cli-functional.py` - Functional tests (19 tests)

### Running Tests
```bash
# Help tests (should pass 100%)
python .spec-flow/scripts/test-spec-cli.py

# Functional tests (currently 15.8% pass rate)
python .spec-flow/scripts/test-spec-cli-functional.py

# JSON output
python .spec-flow/scripts/test-spec-cli-functional.py --json

# Verbose output
python .spec-flow/scripts/test-spec-cli-functional.py --verbose
```

## LLM Integration Impact

### Current State
- LLM can call all 40 help commands without errors ✅
- LLM can call commands, but may misinterpret success as failure due to exit code 1 ❌
- Missing scripts cause hard failures that LLM cannot recover from ❌

### Post-Fix State (Expected)
- LLM can call all commands and correctly interpret success/failure based on exit codes ✅
- LLM gets clean JSON outputs without stderr pollution ✅
- All 50+ commands work reliably across Windows/macOS/Linux ✅

## Next Steps

1. ✅ Fix stderr pollution in spec-cli.py (DONE)
2. ❌ Fix bash script exit codes (add `exit 0`)
3. ❌ Create missing bash scripts
4. ❌ Fix Windows bash path handling
5. ❌ Re-run functional tests to verify 100% pass rate
6. ✅ Document findings in this report (DONE)

## Appendix A: Full Test Results

### Help Command Test Results (40 tests - 100% pass)
```json
{
  "total": 40,
  "passed": 40,
  "failed": 0,
  "pass_rate": "100.0%"
}
```

### Functional Test Results (19 tests - 15.8% pass)
```json
{
  "total": 19,
  "passed": 3,
  "failed": 16,
  "pass_rate": "15.8%"
}
```

---

**Report Generated**: 2025-11-18
**Tool Version**: spec-cli.py (centralized dispatcher)
**Platform**: Windows 11, Python 3.11, Git Bash
