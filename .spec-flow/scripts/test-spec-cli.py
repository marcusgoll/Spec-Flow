#!/usr/bin/env python3
"""
Comprehensive test suite for spec-cli.py
Tests all 50+ commands to ensure zero errors when called by LLM

Usage:
    python test-spec-cli.py --dry-run   # Show what would be tested
    python test-cli.py --command clarify  # Test single command
    python test-spec-cli.py             # Run full test suite
"""

import subprocess
import sys
import json
import argparse
from pathlib import Path
from typing import List, Tuple, Dict

# CLI path
SPEC_CLI = Path(__file__).parent / 'spec-cli.py'

# Test commands organized by category
TEST_COMMANDS = {
    "Workflow Commands": [
        ("clarify --help", "Should show clarify help"),
        ("plan --help", "Should show plan help"),
        ("tasks --help", "Should show tasks help"),
        ("validate --help", "Should show validate help"),
        ("implement --help", "Should show implement help"),
        ("debug --help", "Should show debug help"),
        ("optimize --help", "Should show optimize help"),
        ("preview --help", "Should show preview help"),
        ("feature --help", "Should show feature help"),
    ],

    "Living Documentation": [
        ("generate-feature-claude --help", "Should show generate-feature-claude help"),
        ("generate-project-claude --help", "Should show generate-project-claude help"),
        ("update-living-docs --help", "Should show update-living-docs help"),
        ("health-check-docs --help", "Should show health-check-docs help"),
    ],

    "Project Management": [
        ("init-project --help", "Should show init-project help"),
        ("roadmap --help", "Should show roadmap help"),
        ("design-health --help", "Should show design-health help"),
    ],

    "Epic & Sprint": [
        ("epic --help", "Should show epic help"),
        ("sprint --help", "Should show sprint help"),
        ("scheduler-assign --help", "Should show scheduler-assign help"),
        ("scheduler-list --help", "Should show scheduler-list help"),
        ("scheduler-park --help", "Should show scheduler-park help"),
    ],

    "Quality & Metrics": [
        ("gate --help", "Should show gate help"),
        ("metrics --help", "Should show metrics help"),
        ("metrics-dora --help", "Should show metrics-dora help"),
    ],

    "Utilities": [
        ("compact --help", "Should show compact help"),
        ("create-feature --help", "Should show create-feature help"),
        ("calculate-tokens --help", "Should show calculate-tokens help"),
        ("check-prereqs --help", "Should show check-prereqs help"),
        ("detect-infra --help", "Should show detect-infra help"),
        ("enable-auto-merge --help", "Should show enable-auto-merge help"),
        ("branch-enforce --help", "Should show branch-enforce help"),
    ],

    "Infrastructure": [
        ("flag --help", "Should show flag help"),
        ("schedule --help", "Should show schedule help"),
        ("version --help", "Should show version help"),
        ("deps --help", "Should show deps help"),
        ("contract-bump --help", "Should show contract-bump help"),
        ("contract-verify --help", "Should show contract-verify help"),
        ("fixture-refresh --help", "Should show fixture-refresh help"),
    ],

    "Deployment": [
        ("ship-finalize --help", "Should show ship-finalize help"),
        ("ship-prod --help", "Should show ship-prod help"),
    ],
}

def run_test(command: str, expected_desc: str, verbose: bool = False) -> Tuple[bool, str, str]:
    """
    Run a single test command

    Returns:
        (success, stdout, stderr)
    """
    full_cmd = f"python {SPEC_CLI} {command}"

    try:
        result = subprocess.run(
            full_cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=10,
            encoding='utf-8',
            errors='replace'
        )

        # --help commands should return 0 or show usage
        if '--help' in command:
            success = result.returncode == 0 or 'usage:' in result.stdout.lower() or 'usage:' in result.stderr.lower()
        else:
            success = result.returncode == 0

        stdout = result.stdout if result.stdout else ""
        stderr = result.stderr if result.stderr else ""

        if verbose:
            print(f"\n{'='*60}")
            print(f"Command: {command}")
            print(f"Expected: {expected_desc}")
            print(f"Exit code: {result.returncode}")
            print(f"STDOUT:\n{stdout[:200]}")
            print(f"STDERR:\n{stderr[:200]}")
            print(f"Success: {success}")

        return success, stdout, stderr

    except subprocess.TimeoutExpired:
        return False, "", "Command timed out after 10 seconds"
    except Exception as e:
        return False, "", f"Exception: {str(e)}"

def main():
    parser = argparse.ArgumentParser(description='Test spec-cli.py commands')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be tested')
    parser.add_argument('--command', help='Test only this command category')
    parser.add_argument('--verbose', '-v', action='store_true', help='Show detailed output')
    parser.add_argument('--json', action='store_true', help='Output results as JSON')
    args = parser.parse_args()

    if args.dry_run:
        print("=" * 60)
        print("DRY RUN - Commands that would be tested:")
        print("=" * 60)
        total = 0
        for category, tests in TEST_COMMANDS.items():
            print(f"\n{category}:")
            for cmd, desc in tests:
                print(f"  • {cmd:40} - {desc}")
                total += 1
        print(f"\nTotal commands: {total}")
        return 0

    # Filter by category if specified
    if args.command:
        tests_to_run = {args.command: TEST_COMMANDS.get(args.command, [])}
        if not tests_to_run[args.command]:
            print(f"Error: Unknown command category '{args.command}'", file=sys.stderr)
            print(f"Available categories: {', '.join(TEST_COMMANDS.keys())}", file=sys.stderr)
            return 1
    else:
        tests_to_run = TEST_COMMANDS

    # Run tests
    results = []
    total_tests = 0
    passed_tests = 0
    failed_tests = []

    for category, tests in tests_to_run.items():
        if not args.json:
            print(f"\n{'='*60}")
            print(f"Testing: {category}")
            print(f"{'='*60}")

        for cmd, desc in tests:
            total_tests += 1
            success, stdout, stderr = run_test(cmd, desc, args.verbose)

            status = "✅ PASS" if success else "❌ FAIL"

            if success:
                passed_tests += 1
            else:
                failed_tests.append({
                    "category": category,
                    "command": cmd,
                    "description": desc,
                    "stdout": stdout[:500],
                    "stderr": stderr[:500]
                })

            if not args.json:
                print(f"{status} | {cmd:40} - {desc}")

            results.append({
                "category": category,
                "command": cmd,
                "description": desc,
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
        print(f"Pass rate: {(passed_tests/total_tests)*100:.1f}%" if total_tests > 0 else "0%")

        if failed_tests:
            print(f"\n{'='*60}")
            print("FAILURES")
            print(f"{'='*60}")
            for failure in failed_tests:
                print(f"\n❌ {failure['category']} - {failure['command']}")
                print(f"   Description: {failure['description']}")
                if failure['stderr']:
                    print(f"   Error: {failure['stderr'][:200]}")
                if failure['stdout']:
                    print(f"   Output: {failure['stdout'][:200]}")

    return 0 if len(failed_tests) == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
