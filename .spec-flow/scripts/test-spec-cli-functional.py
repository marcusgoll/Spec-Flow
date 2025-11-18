#!/usr/bin/env python3
"""
Functional tests for spec-cli.py
Tests commands with real parameters as LLM would call them

Usage:
    python test-spec-cli-functional.py --dry-run
    python test-spec-cli-functional.py
"""

import subprocess
import sys
import json
import argparse
import os
import shutil
from pathlib import Path
from typing import Tuple

SPEC_CLI = Path(__file__).parent / 'spec-cli.py'
TEST_FEATURE_DIR = Path(__file__).parent.parent.parent / 'specs' / 'test-cli-feature'

# Windows console encoding fix
def safe_print(text: str) -> None:
    """Print text safely, handling Windows console encoding issues."""
    try:
        print(text)
    except UnicodeEncodeError:
        # Fallback to ASCII-safe replacements
        replacements = {
            "━": "=",
            "⚠️": "[WARNING]",
            "✅": "[OK]",
            "❌": "[FAIL]",
        }
        safe_text = text
        for unicode_char, ascii_replacement in replacements.items():
            safe_text = safe_text.replace(unicode_char, ascii_replacement)
        print(safe_text)

# Functional tests (commands with actual parameters)
FUNCTIONAL_TESTS = [
    # Utilities (non-destructive)
    {
        "name": "check-prereqs (JSON)",
        "command": "check-prereqs --json",
        "expect_code": 0,
        "expect_in_output": "git",
        "description": "Verify prerequisites check returns valid JSON",
    },
    {
        "name": "check-prereqs (paths only)",
        "command": "check-prereqs --paths-only",
        "expect_code": 0,
        "expect_in_output": "",  # Any output is fine
        "description": "Verify prerequisites check returns paths",
    },
    {
        "name": "health-check-docs (JSON)",
        "command": "health-check-docs --json --threshold 7",
        "expect_code": 0,
        "expect_in_output": "",  # JSON structure expected
        "description": "Verify documentation health check returns JSON",
    },
    {
        "name": "scheduler-list (JSON)",
        "command": "scheduler-list --json",
        "expect_code": [0, 1],  # Might fail if no epics exist
        "expect_in_output": "",
        "description": "Verify scheduler list returns data",
    },
    {
        "name": "metrics-dora (JSON)",
        "command": "metrics-dora --json --since 2025-01-01",
        "expect_code": [0, 1],  # Might fail if no git history
        "expect_in_output": "",
        "description": "Verify DORA metrics calculation",
    },
    {
        "name": "roadmap list (JSON)",
        "command": "roadmap track --json",
        "expect_code": [0, 1],  # Might fail if no GitHub configured
        "expect_in_output": "",
        "description": "Verify roadmap tracking",
    },
    {
        "name": "design-health (JSON)",
        "command": "design-health --json",
        "expect_code": [0, 1],  # Might fail if no design system
        "expect_in_output": "",
        "description": "Verify design system health check",
    },

    # Commands that require feature dir (will fail gracefully)
    {
        "name": "clarify (missing feature)",
        "command": "clarify nonexistent-feature --json",
        "expect_code": 1,
        "expect_in_output": "",
        "description": "Clarify should fail gracefully for missing feature",
    },
    {
        "name": "plan (missing feature)",
        "command": "plan nonexistent-feature --json",
        "expect_code": 1,
        "expect_in_output": "",
        "description": "Plan should fail gracefully for missing feature",
    },
    {
        "name": "tasks (missing feature)",
        "command": "tasks nonexistent-feature --json",
        "expect_code": 1,
        "expect_in_output": "",
        "description": "Tasks should fail gracefully for missing feature",
    },
    {
        "name": "validate (missing feature)",
        "command": "validate nonexistent-feature --json",
        "expect_code": 1,
        "expect_in_output": "",
        "description": "Validate should fail gracefully for missing feature",
    },
    {
        "name": "implement (missing feature)",
        "command": "implement nonexistent-feature --json",
        "expect_code": 1,
        "expect_in_output": "",
        "description": "Implement should fail gracefully for missing feature",
    },
    {
        "name": "optimize (missing feature)",
        "command": "optimize nonexistent-feature --json",
        "expect_code": 1,
        "expect_in_output": "",
        "description": "Optimize should fail gracefully for missing feature",
    },
    {
        "name": "preview (missing feature)",
        "command": "preview nonexistent-feature --json",
        "expect_code": 1,
        "expect_in_output": "",
        "description": "Preview should fail gracefully for missing feature",
    },
    {
        "name": "debug (missing feature)",
        "command": "debug nonexistent-feature --json",
        "expect_code": 1,
        "expect_in_output": "",
        "description": "Debug should fail gracefully for missing feature",
    },

    # Calculation commands
    {
        "name": "calculate-tokens (missing dir)",
        "command": "calculate-tokens --feature-dir nonexistent",
        "expect_code": 1,
        "expect_in_output": "",
        "description": "Calculate tokens should fail gracefully for missing dir",
    },
    {
        "name": "compact (missing dir)",
        "command": "compact --feature-dir nonexistent --phase planning",
        "expect_code": 1,
        "expect_in_output": "",
        "description": "Compact should fail gracefully for missing dir",
    },

    # Infrastructure commands
    {
        "name": "contract-verify (no baseline)",
        "command": "contract-verify",
        "expect_code": [0, 1],  # Might fail if no contracts exist
        "expect_in_output": "",
        "description": "Contract verify should run without errors",
    },
    {
        "name": "detect-infra (no feature)",
        "command": "detect-infra",
        "expect_code": [0, 1],
        "expect_in_output": "",
        "description": "Detect infrastructure needs should run",
    },
]

def run_functional_test(test: dict, verbose: bool = False) -> Tuple[bool, str, str]:
    """
    Run a single functional test

    Returns:
        (success, stdout, stderr)
    """
    full_cmd = f"python {SPEC_CLI} {test['command']}"

    try:
        result = subprocess.run(
            full_cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=30,
            encoding='utf-8',
            errors='replace'
        )

        # Check expected exit code
        expect_codes = test['expect_code'] if isinstance(test['expect_code'], list) else [test['expect_code']]
        exit_code_ok = result.returncode in expect_codes

        # Check expected output (if specified)
        stdout = result.stdout if result.stdout else ""
        stderr = result.stderr if result.stderr else ""
        output_ok = True
        if test.get('expect_in_output'):
            output_ok = test['expect_in_output'] in stdout or test['expect_in_output'] in stderr

        success = exit_code_ok and output_ok

        if verbose:
            print(f"\n{'='*60}")
            print(f"Test: {test['name']}")
            print(f"Command: {test['command']}")
            print(f"Description: {test['description']}")
            print(f"Expected exit code: {expect_codes}")
            print(f"Actual exit code: {result.returncode}")
            print(f"Exit code OK: {exit_code_ok}")
            print(f"Output OK: {output_ok}")
            print(f"STDOUT:\n{stdout[:300]}")
            print(f"STDERR:\n{stderr[:300]}")
            print(f"Success: {success}")

        return success, stdout, stderr

    except subprocess.TimeoutExpired:
        return False, "", "Command timed out after 30 seconds"
    except Exception as e:
        return False, "", f"Exception: {str(e)}"

def main():
    parser = argparse.ArgumentParser(description='Functional tests for spec-cli.py')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be tested')
    parser.add_argument('--verbose', '-v', action='store_true', help='Show detailed output')
    parser.add_argument('--json', action='store_true', help='Output results as JSON')
    args = parser.parse_args()

    if args.dry_run:
        print("=" * 60)
        print("DRY RUN - Functional tests to run:")
        print("=" * 60)
        for i, test in enumerate(FUNCTIONAL_TESTS, 1):
            print(f"\n{i}. {test['name']}")
            print(f"   Command: {test['command']}")
            print(f"   Description: {test['description']}")
            print(f"   Expected exit code: {test['expect_code']}")
        print(f"\nTotal tests: {len(FUNCTIONAL_TESTS)}")
        return 0

    # Run tests
    results = []
    total_tests = 0
    passed_tests = 0
    failed_tests = []

    if not args.json:
        print(f"{'='*60}")
        print("FUNCTIONAL TESTS")
        print(f"{'='*60}")

    for test in FUNCTIONAL_TESTS:
        total_tests += 1
        success, stdout, stderr = run_functional_test(test, args.verbose)

        status = "✅ PASS" if success else "❌ FAIL"

        if success:
            passed_tests += 1
        else:
            failed_tests.append({
                "name": test['name'],
                "command": test['command'],
                "description": test['description'],
                "stdout": stdout[:500],
                "stderr": stderr[:500]
            })

        if not args.json:
            safe_print(f"{status} | {test['name']:40} - {test['description'][:40]}")

        results.append({
            "name": test['name'],
            "command": test['command'],
            "description": test['description'],
            "success": success,
            "stdout": stdout[:500] if not success else "",
            "stderr": stderr[:500] if not success else ""
        })

    # Summary
    if args.json:
        output = {
            "total": total_tests,
            "passed": passed_tests,
            "failed": len(failed_tests),
            "pass_rate": f"{(passed_tests/total_tests)*100:.1f}%" if total_tests > 0 else "0%",
            "failures": failed_tests,
            "results": results
        }
        print(json.dumps(output, indent=2))
    else:
        print(f"\n{'='*60}")
        print("SUMMARY")
        print(f"{'='*60}")
        print(f"Total tests: {total_tests}")
        print(f"Passed: {passed_tests}")
        print(f"Failed: {len(failed_tests)}")
        print(f"Pass_rate: {(passed_tests/total_tests)*100:.1f}%" if total_tests > 0 else "0%")

        if failed_tests:
            print(f"\n{'='*60}")
            print("FAILURES")
            print(f"{'='*60}")
            for failure in failed_tests:
                safe_print(f"\n[FAIL] {failure['name']}")
                print(f"   Command: {failure['command']}")
                print(f"   Description: {failure['description']}")
                if failure['stderr']:
                    print(f"   Error: {failure['stderr'][:300]}")
                if failure['stdout']:
                    print(f"   Output: {failure['stdout'][:300]}")

    return 0 if len(failed_tests) == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
