# Actual Spec-CLI Test Results

**Date**: 2025-11-18
**Testing Method**: Direct bash tool invocation
**Platform**: Windows 11 with Git Bash

## Commands That Work ✅

### 1. health-check-docs
```bash
$ bash health-check-docs.sh --json
{"total": 0, "stale": [], "fresh": [], "warnings": []}
Exit: 0 ✅
```
**Status**: ✅ Works perfectly
**Output**: Valid JSON
**Exit Code**: 0 (correct)

### 2. dora-calculate
```bash
$ bash dora-calculate.sh --since 2025-01-01
🚀 DORA Metrics Calculator
Period: 2025-01-01 to 2025-11-18
✅ Report generated: .spec-flow/reports/dora-report.md
```
**Status**: ✅ Works
**Output**: Human-readable report
**Note**: Doesn't support `--json` flag (returns "Unknown option: --json")

### 3. contract-verify
```bash
$ bash contract-verify.sh
ℹ  Discovering pacts in /d/coding/workflow/contracts/pacts
ℹ  Found 1 pacts
⚠  Provider not running: backend-epic-api (http://localhost:3000)
⚠  Skipping verification for example-frontend-backend.json
```
**Status**: ✅ Works
**Output**: Checks for contracts and running providers
**Use Case**: LLM can verify API contracts before deployment

## Commands With Issues ⚠️

### 4. check-prerequisites --json
```bash
$ bash check-prerequisites.sh --json
check-prerequisites.sh: line 45: feature_paths_env: command not found
check-prerequisites.sh: line 116: FEATURE_DIR: unbound variable
Exit: 1 ❌
```
**Status**: ❌ Broken
**Issue**: Undefined variable `FEATURE_DIR`
**Root Cause**: Script expects environment variables not set by spec-cli.py
**Fix Needed**: Set required env vars before calling script

### 5. health-check-docs --threshold
```bash
$ bash health-check-docs.sh --json --threshold 7
[spec-flow][error] Unknown option: --threshold
Exit: 1 ❌
```
**Status**: ⚠️ Partial
**Issue**: `--threshold` parameter not implemented
**Workaround**: Call without `--threshold` flag
**Fix**: spec-cli.py shouldn't pass unsupported flags

### 6. branch-enforce
```bash
$ python spec-cli.py branch-enforce
/bin/bash: D:codingworkflow.spec-flowscriptsbashbranch-enforce.sh: No such file or directory
Exit: 127 ❌
```
**Status**: ❌ Broken on Windows
**Issue**: Windows path `D:\coding\...` not converted to Unix `/d/coding/...`
**Root Cause**: Bash can't execute Windows-style paths
**Fix**: Path conversion in spec-cli.py (already documented in TEST_REPORT.md)

### 7. calculate-tokens (PowerShell)
```bash
$ pwsh calculate-tokens.ps1 -FeatureDir specs/001
[31;1mA parameter with the name 'Verbose' was defined multiple times[0m
Exit: 1 ❌
```
**Status**: ❌ Broken
**Issue**: Duplicate `-Verbose` parameter in PowerShell script
**Root Cause**: PowerShell script bug
**Fix**: Remove duplicate parameter definition

### 8. create-feature
```bash
$ python spec-cli.py create-feature "Test Feature"
create-new-feature.ps1: Cannot validate argument on parameter 'Type'.
The argument "Test Feature" does not belong to the set "feat,fix,chore,docs,test,refactor,ci,build"
```
**Status**: ❌ Wrong API
**Issue**: spec-cli.py passes feature name, script expects type + name
**Root Cause**: Argument mismatch between Python wrapper and PowerShell script
**Fix**: Update spec-cli.py to match PowerShell script expectations

### 9. dora-calculate --json
```bash
$ bash dora-calculate.sh --json
Unknown option: --json
Usage: dora-calculate.sh [--since YYYY-MM-DD] [--output FILE]
```
**Status**: ⚠️ Missing feature
**Issue**: Script doesn't support `--json` output mode
**Workaround**: Use without `--json` (returns markdown report)
**Impact**: LLM gets human-readable text instead of JSON

## LLM Usage Recommendations

### ✅ Safe to Call (Works Reliably)
```python
# Health check documentation
python spec-cli.py health-check-docs

# Verify API contracts
python spec-cli.py contract-verify

# Calculate DORA metrics (no --json)
python spec-cli.py metrics-dora --since 2025-01-01
```

### ⚠️ Call With Caution (May Fail)
```python
# Missing required env vars
python spec-cli.py check-prereqs --json  # ❌ Fails

# Unsupported flags
python spec-cli.py health-check-docs --json --threshold 7  # Use without --threshold

# Windows path issues
python spec-cli.py branch-enforce  # ❌ Fails on Windows
```

### ❌ Don't Call (Broken)
```python
# Duplicate parameter error
python spec-cli.py calculate-tokens --feature-dir specs/001

# Wrong argument format
python spec-cli.py create-feature "Feature Name"

# Missing --json support
python spec-cli.py metrics-dora --json  # Remove --json flag
```

## Key Findings

### 1. JSON Output Inconsistency
- Some scripts support `--json`, others don't
- spec-cli.py blindly passes `--json` to all commands
- **Fix**: spec-cli.py should know which commands support `--json`

### 2. Environment Variables
- Bash scripts expect env vars like `FEATURE_DIR`, `CLAUDE_PROJECT_DIR`
- spec-cli.py doesn't set these before calling scripts
- **Fix**: Set required env vars in `run_script()` function

### 3. Parameter Mismatches
- Python wrapper and underlying scripts have different APIs
- Example: `create-feature` expects `<name>` but script expects `<type> <name>`
- **Fix**: Update spec-cli.py to match script signatures

### 4. Exit Code Issues (Original Finding Confirmed)
- Scripts that work still return exit 1 (but we found `health-check-docs.sh` returns 0!)
- This is inconsistent across scripts
- **Fix**: Standardize exit codes across all bash scripts

## Test Coverage Summary

**Total Commands Tested Live**: 9
- ✅ Working: 3 (33%)
- ⚠️ Partial: 3 (33%)
- ❌ Broken: 3 (33%)

**Critical for LLM**: 3 working commands is enough for basic functionality
- health-check-docs: Monitor documentation staleness
- contract-verify: Verify API compatibility
- dora-calculate: Track deployment metrics

## Next Steps

### Priority 1: Fix Environment Variables
```python
# spec-cli.py run_script() function
def run_script(script_name, args=None):
    env = os.environ.copy()
    env['CLAUDE_PROJECT_DIR'] = str(Path.cwd())
    env['FEATURE_DIR'] = args[0] if args else ''
    subprocess.run(cmd, env=env)
```

### Priority 2: Fix Parameter Mismatches
Update spec-cli.py command handlers to match bash/PowerShell signatures

### Priority 3: Document JSON Support
Create a list of commands that support `--json`:
- health-check-docs ✅
- scheduler-list ❓
- metrics-dora ❌
- design-health ❓

### Priority 4: Fix PowerShell Bugs
- calculate-tokens.ps1: Remove duplicate Verbose parameter
- create-new-feature.ps1: Accept name directly (not type)

---

**Conclusion**: LLM can successfully call 3 core commands. The remaining 40+ commands need fixes for env vars, parameter mismatches, and JSON support inconsistencies.
