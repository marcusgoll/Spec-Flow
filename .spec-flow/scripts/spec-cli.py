#!/usr/bin/env python3
"""
Spec-Flow Workflow CLI - Centralized command dispatcher

Usage:
    python spec-cli.py <command> [options]

Commands:
    clarify <feature>           - Interactive clarification workflow
    compact <feature>           - Compact context for phase
    create-feature <name>       - Create new feature directory
    calculate-tokens <dir>      - Calculate token budget
    check-prereqs              - Validate environment
    detect-infra <feature>      - Detect infrastructure needs
    enable-auto-merge          - Enable auto-merge for PR
    branch-enforce             - Enforce branch naming

Examples:
    python spec-cli.py clarify my-feature
    python spec-cli.py check-prereqs --json
    python spec-cli.py create-feature "User Authentication"
    python spec-cli.py calculate-tokens --feature-dir specs/001-auth
"""

import sys
import os
import subprocess
import json
import argparse
from pathlib import Path

# Detect platform and choose script type
IS_WINDOWS = sys.platform == 'win32'
SCRIPT_DIR = Path(__file__).parent

def run_script(script_name, args=None, capture=False, shell_type='auto'):
    """
    Execute platform-specific script (bash or PowerShell)

    Args:
        script_name: Name of script without extension (e.g., 'check-prerequisites')
        args: List of arguments to pass to script
        capture: Whether to capture output (True) or stream to console (False)
        shell_type: 'auto', 'bash', or 'powershell'

    Returns:
        If capture=True: (stdout, returncode)
        If capture=False: returncode
    """
    if shell_type == 'auto':
        shell_type = 'powershell' if IS_WINDOWS else 'bash'

    if shell_type == 'powershell':
        script_path = SCRIPT_DIR / 'powershell' / f'{script_name}.ps1'
        if not script_path.exists():
            print(f"Error: PowerShell script not found: {script_path}", file=sys.stderr)
            return ("", 1) if capture else 1
        cmd = ['pwsh', '-File', str(script_path)]
    else:
        script_path = SCRIPT_DIR / 'bash' / f'{script_name}.sh'
        if not script_path.exists():
            print(f"Error: Bash script not found: {script_path}", file=sys.stderr)
            return ("", 1) if capture else 1
        cmd = ['bash', str(script_path)]

    if args:
        cmd.extend(args)

    try:
        if capture:
            result = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8')
            return result.stdout, result.returncode
        else:
            return subprocess.run(cmd).returncode
    except FileNotFoundError as e:
        print(f"Error: Required shell not found: {e}", file=sys.stderr)
        return ("", 1) if capture else 1
    except Exception as e:
        print(f"Error executing script: {e}", file=sys.stderr)
        return ("", 1) if capture else 1

def cmd_clarify(args):
    """Run clarification workflow"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    return run_script('clarify-workflow', script_args)

def cmd_plan(args):
    """Run planning workflow"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    if args.interactive:
        script_args.append('--interactive')
    if args.yes:
        script_args.append('--yes')
    if args.skip_clarify:
        script_args.append('--skip-clarify')
    return run_script('plan-workflow', script_args)

def cmd_preview(args):
    """Run preview workflow"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    return run_script('preview-workflow', script_args)

def cmd_validate(args):
    """Run validation workflow"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    return run_script('validate-workflow', script_args)

def cmd_tasks(args):
    """Run tasks generation workflow"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    if args.ui_first:
        script_args.append('--ui-first')
    return run_script('tasks-workflow', script_args)

def cmd_implement(args):
    """Run implementation workflow"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    return run_script('implement-workflow', script_args)

def cmd_debug(args):
    """Run debug workflow"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    if args.error:
        script_args.extend(['--error', args.error])
    return run_script('debug-workflow', script_args)

def cmd_optimize(args):
    """Run optimization workflow"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    return run_script('optimize-workflow', script_args)

def cmd_feature(args):
    """Run feature workflow orchestration"""
    script_args = []
    if args.arguments:
        script_args.append(args.arguments)
    return run_script('feature-workflow', script_args)

def cmd_ship_finalize(args):
    """Run ship finalization tasks"""
    script_args = [args.action]
    if args.feature_dir:
        script_args.append(args.feature_dir)
    return run_script('ship-finalization', script_args)

def cmd_ship_prod(args):
    """Run production deployment via tagged promotion"""
    script_args = []
    if args.feature_dir:
        script_args.append(args.feature_dir)
    return run_script('ship-prod-workflow', script_args)

def cmd_compact(args):
    """Run context compaction"""
    script_args = ['--feature-dir', args.feature_dir, '--phase', args.phase]
    return run_script('compact-context', script_args)

def cmd_create_feature(args):
    """Create new feature directory"""
    return run_script('create-new-feature', [args.name])

def cmd_calculate_tokens(args):
    """Calculate token budget"""
    return run_script('calculate-tokens', ['--feature-dir', args.feature_dir])

def cmd_check_prereqs(args):
    """Check prerequisites and return JSON"""
    script_args = []
    if args.json:
        script_args.append('--json')
    if args.paths_only:
        script_args.append('--paths-only')

    if args.json or args.paths_only:
        stdout, code = run_script('check-prerequisites', script_args, capture=True)
        print(stdout, end='')
        return code
    else:
        return run_script('check-prerequisites', script_args)

def cmd_detect_infra(args):
    """Detect infrastructure needs"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    return run_script('detect-infrastructure-needs', script_args)

def cmd_enable_auto_merge(args):
    """Enable auto-merge for PR"""
    script_args = []
    if args.pr_number:
        script_args.extend(['--pr', str(args.pr_number)])
    return run_script('enable-auto-merge', script_args)

def cmd_branch_enforce(args):
    """Enforce branch naming conventions"""
    return run_script('branch-enforce', [])

def cmd_contract_bump(args):
    """Bump API contract version"""
    script_args = ['--type', args.type]
    if args.file:
        script_args.extend(['--file', args.file])
    return run_script('contract-bump', script_args)

def cmd_contract_verify(args):
    """Verify API contract compatibility"""
    script_args = []
    if args.baseline:
        script_args.extend(['--baseline', args.baseline])
    return run_script('contract-verify', script_args)

def main():
    parser = argparse.ArgumentParser(
        description='Spec-Flow Workflow CLI',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python spec-cli.py clarify my-feature
  python spec-cli.py check-prereqs --json
  python spec-cli.py create-feature "User Authentication"
  python spec-cli.py calculate-tokens --feature-dir specs/001-auth
        """
    )
    subparsers = parser.add_subparsers(dest='command', help='Available commands')

    # clarify
    clarify_parser = subparsers.add_parser('clarify', help='Interactive clarification workflow')
    clarify_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')

    # plan
    plan_parser = subparsers.add_parser('plan', help='Generate implementation plan from spec')
    plan_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')
    plan_parser.add_argument('--interactive', action='store_true', help='Force wait for user confirmation')
    plan_parser.add_argument('--yes', action='store_true', help='Skip all HITL gates and auto-commit')
    plan_parser.add_argument('--skip-clarify', action='store_true', help='Skip spec ambiguity gate only')

    # preview
    preview_parser = subparsers.add_parser('preview', help='Manual UI/UX testing and backend validation')
    preview_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')

    # validate
    validate_parser = subparsers.add_parser('validate', help='Cross-artifact consistency analysis')
    validate_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')

    # tasks
    tasks_parser = subparsers.add_parser('tasks', help='Generate concrete TDD tasks from design artifacts')
    tasks_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')
    tasks_parser.add_argument('--ui-first', action='store_true', help='Generate HTML mockups before implementation')

    # implement
    implement_parser = subparsers.add_parser('implement', help='Execute tasks with TDD and parallel execution')
    implement_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')

    # debug
    debug_parser = subparsers.add_parser('debug', help='Debug errors and update error-log.md')
    debug_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')
    debug_parser.add_argument('--error', help='Error message or description')

    # optimize
    optimize_parser = subparsers.add_parser('optimize', help='Production-readiness validation')
    optimize_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')

    # feature
    feature_parser = subparsers.add_parser('feature', help='Orchestrate full feature workflow')
    feature_parser.add_argument('arguments', nargs='?', help='Feature description, slug, next, continue, epic:name, sprint:num')

    # ship-finalize
    ship_finalize_parser = subparsers.add_parser('ship-finalize', help='Run ship finalization tasks')
    ship_finalize_parser.add_argument('action', choices=['preflight', 'finalize'], help='Finalization action')
    ship_finalize_parser.add_argument('--feature-dir', help='Feature directory path')

    # ship-prod
    ship_prod_parser = subparsers.add_parser('ship-prod', help='Deploy to production via tagged promotion')
    ship_prod_parser.add_argument('feature_dir', nargs='?', help='Feature directory path (optional, auto-detected)')

    # compact
    compact_parser = subparsers.add_parser('compact', help='Compact context for phase')
    compact_parser.add_argument('--feature-dir', required=True, help='Feature directory path')
    compact_parser.add_argument('--phase', required=True, help='Phase name (planning, implementation, optimization)')

    # create-feature
    create_parser = subparsers.add_parser('create-feature', help='Create new feature directory')
    create_parser.add_argument('name', help='Feature name (e.g., "User Authentication")')

    # calculate-tokens
    tokens_parser = subparsers.add_parser('calculate-tokens', help='Calculate token budget')
    tokens_parser.add_argument('--feature-dir', required=True, help='Feature directory path')

    # check-prereqs
    prereq_parser = subparsers.add_parser('check-prereqs', help='Check prerequisites')
    prereq_parser.add_argument('--json', action='store_true', help='Output as JSON')
    prereq_parser.add_argument('--paths-only', action='store_true', help='Only return paths')

    # detect-infra
    infra_parser = subparsers.add_parser('detect-infra', help='Detect infrastructure needs')
    infra_parser.add_argument('feature', nargs='?', help='Feature slug (optional)')

    # enable-auto-merge
    merge_parser = subparsers.add_parser('enable-auto-merge', help='Enable auto-merge for PR')
    merge_parser.add_argument('--pr', dest='pr_number', type=int, help='PR number')

    # branch-enforce
    branch_parser = subparsers.add_parser('branch-enforce', help='Enforce branch naming')

    # contract-bump
    bump_parser = subparsers.add_parser('contract-bump', help='Bump API contract version')
    bump_parser.add_argument('--type', required=True, choices=['major', 'minor', 'patch'],
                            help='Version bump type')
    bump_parser.add_argument('--file', help='Contract file path')

    # contract-verify
    verify_parser = subparsers.add_parser('contract-verify', help='Verify API contract compatibility')
    verify_parser.add_argument('--baseline', help='Baseline contract version')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    # Dispatch to command handlers
    handlers = {
        'clarify': cmd_clarify,
        'plan': cmd_plan,
        'preview': cmd_preview,
        'validate': cmd_validate,
        'tasks': cmd_tasks,
        'implement': cmd_implement,
        'debug': cmd_debug,
        'optimize': cmd_optimize,
        'feature': cmd_feature,
        'ship-finalize': cmd_ship_finalize,
        'ship-prod': cmd_ship_prod,
        'compact': cmd_compact,
        'create-feature': cmd_create_feature,
        'calculate-tokens': cmd_calculate_tokens,
        'check-prereqs': cmd_check_prereqs,
        'detect-infra': cmd_detect_infra,
        'enable-auto-merge': cmd_enable_auto_merge,
        'branch-enforce': cmd_branch_enforce,
        'contract-bump': cmd_contract_bump,
        'contract-verify': cmd_contract_verify,
    }

    handler = handlers.get(args.command)
    if handler:
        return handler(args)
    else:
        print(f"Unknown command: {args.command}", file=sys.stderr)
        parser.print_help()
        return 1

if __name__ == '__main__':
    sys.exit(main())
