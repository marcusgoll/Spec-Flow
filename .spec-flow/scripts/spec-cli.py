#!/usr/bin/env python3
"""
Spec-Flow Workflow CLI - Centralized command dispatcher

This dispatcher is the shared execution engine behind installed workflow
commands. It is not the primary public product CLI; use `npx spec-flow ...`
for install and maintenance operations, and use installed workflow commands in
your tool environment for normal feature work.

Usage:
    python spec-cli.py <command> [options]

Workflow Commands:
    clarify <feature>           - Interactive clarification workflow
    plan <feature>              - Generate implementation plan from spec
    tasks <feature>             - Task-phase compatibility shim
    validate <feature>          - Validation-phase compatibility shim
    implement <feature>         - Implementation-phase compatibility shim
    debug <feature>             - Debug errors and update error-log.md
    optimize <feature>          - Production-readiness validation
    preview <feature>           - Preview-phase compatibility shim
    finalize <feature>          - Post-deploy documentation and housekeeping
    feature <args>              - Orchestrate full feature workflow

Living Documentation:
    generate-feature-claude     - Generate feature-level CLAUDE.md
    generate-project-claude     - Generate project-level CLAUDE.md
    update-living-docs          - Trigger living documentation update
    health-check-docs           - Scan for stale documentation

Project Management:
    init-project                - Initialize project with 8-document generation
    roadmap <action>            - Manage product roadmap via GitHub Issues
    design-health               - Monitor design system health

Epic & Sprint:
    epic <action>               - Manage epic groupings
    sprint <action>             - Manage sprint cycles

Quality & Metrics:
    gate <type>                 - Manage quality gates
    metrics <type>              - Metrics compatibility shim (planned)

Utilities:
    compact <feature>           - Compact context for phase
    create-feature <name>       - Create new feature directory
    calculate-tokens <dir>      - Calculate token budget
    check-prereqs               - Validate environment
    detect-infra <feature>      - Detect infrastructure needs
    enable-auto-merge           - Enable auto-merge for PR
    branch-enforce              - Enforce branch naming
    flag <action>               - Feature-flag compatibility shim (planned)
    schedule <action>           - Epic scheduler compatibility shim (planned)
    version <type>              - Manage version bumps
    deps <action>               - Manage dependency updates
    contract-bump <type>        - Contract-governance compatibility shim (planned)
    contract-verify             - Contract-governance compatibility shim (planned)

Examples:
    python spec-cli.py clarify my-feature
    python spec-cli.py check-prereqs --json
    python spec-cli.py create-feature "User Authentication"
    python spec-cli.py calculate-tokens --feature-dir specs/001-auth
    python spec-cli.py health-check-docs --json
    python spec-cli.py roadmap brainstorm

Compatibility-only or preflight-only surfaces in this checkout:
    preview, tasks, validate, implement,
    contract-bump, contract-verify, fixture-refresh, flag, metrics,
    metrics-dora, schedule, scheduler-assign, scheduler-list, scheduler-park
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

def missing_shared_script(script_name, capture=False):
    """Return a consistent error when a referenced shared script is absent."""
    print(f"Error: Shared script not shipped for command '{script_name}'.", file=sys.stderr)
    print(
        "spec-cli.py references this surface, but no bash or PowerShell "
        "implementation exists in this checkout.",
        file=sys.stderr,
    )
    return ("", 1) if capture else 1

def convert_windows_path_for_bash(path):
    r"""
    Convert Windows path to Unix-style path for Git Bash on Windows.

    Examples:
        D:\coding\workflow\script.sh -> /d/coding/workflow/script.sh
        C:\Users\file.txt -> /c/Users/file.txt
    """
    path_str = str(path)

    # Check if it's a Windows absolute path (contains drive letter)
    if len(path_str) >= 2 and path_str[1] == ':':
        drive = path_str[0].lower()
        rest = path_str[2:].replace('\\', '/')
        return f'/{drive}{rest}'

    # Already Unix-style or relative path
    return path_str.replace('\\', '/')

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

    script_path = None
    cmd = []

    if shell_type == 'powershell':
        script_path = SCRIPT_DIR / 'powershell' / f'{script_name}.ps1'
        # Fall back to bash if PowerShell script doesn't exist
        if not script_path.exists():
            bash_fallback = SCRIPT_DIR / 'bash' / f'{script_name}.sh'
            if bash_fallback.exists():
                # SILENT: Don't print fallback notice to avoid polluting stderr
                script_path = bash_fallback
                shell_type = 'bash'
                # On Windows, use relative path (subprocess bash can't access /d/ style paths)
                # On Unix, use absolute path
                if IS_WINDOWS:
                    bash_path = f'bash/{script_name}.sh'
                else:
                    bash_path = str(script_path)
                cmd = ['bash', bash_path]
            else:
                return missing_shared_script(script_name, capture)
        else:
            cmd = ['pwsh', '-File', str(script_path)]

    elif shell_type == 'bash':
        script_path = SCRIPT_DIR / 'bash' / f'{script_name}.sh'
        if not script_path.exists():
            return missing_shared_script(script_name, capture)
        # On Windows, use relative path (subprocess bash can't access /d/ style paths)
        # On Unix, use absolute path
        if IS_WINDOWS:
            bash_path = f'bash/{script_name}.sh'
        else:
            bash_path = str(script_path)
        cmd = ['bash', bash_path]

    if args:
        cmd.extend(args)

    try:
        if capture:
            result = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', cwd=SCRIPT_DIR)
            output = result.stdout
            if result.stderr:
                output = f"{output}{result.stderr}" if output else result.stderr
            return output, result.returncode
        else:
            return subprocess.run(cmd, cwd=SCRIPT_DIR).returncode
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
    if hasattr(args, 'json') and args.json:
        script_args.append('--json')
        stdout, code = run_script('clarify-workflow', script_args, capture=True)
        print(stdout, end='')
        return code
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
    if hasattr(args, 'json') and args.json:
        script_args.append('--json')
        stdout, code = run_script('plan-workflow', script_args, capture=True)
        print(stdout, end='')
        return code
    return run_script('plan-workflow', script_args)

def cmd_preview(args):
    """Run preview workflow"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    if hasattr(args, 'json') and args.json:
        script_args.append('--json')
        stdout, code = run_script('preview-workflow', script_args, capture=True)
        print(stdout, end='')
        return code
    return run_script('preview-workflow', script_args)

def cmd_validate(args):
    """Run validation workflow"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    if hasattr(args, 'json') and args.json:
        script_args.append('--json')
        stdout, code = run_script('validate-workflow', script_args, capture=True)
        print(stdout, end='')
        return code
    return run_script('validate-workflow', script_args)

def cmd_tasks(args):
    """Run tasks generation workflow"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    if args.ui_first:
        script_args.append('--ui-first')
    if hasattr(args, 'json') and args.json:
        script_args.append('--json')
        stdout, code = run_script('tasks-workflow', script_args, capture=True)
        print(stdout, end='')
        return code
    return run_script('tasks-workflow', script_args)

def cmd_implement(args):
    """Run implementation workflow"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    if hasattr(args, 'json') and args.json:
        script_args.append('--json')
        stdout, code = run_script('implement-workflow', script_args, capture=True)
        print(stdout, end='')
        return code
    return run_script('implement-workflow', script_args)

def cmd_debug(args):
    """Run debug workflow"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    if args.error:
        script_args.extend(['--error', args.error])
    if hasattr(args, 'json') and args.json:
        script_args.append('--json')
        stdout, code = run_script('debug', script_args, capture=True)
        print(stdout, end='')
        return code
    return run_script('debug', script_args)

def cmd_optimize(args):
    """Run optimization workflow"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    if hasattr(args, 'json') and args.json:
        script_args.append('--json')
        stdout, code = run_script('optimize-workflow', script_args, capture=True)
        print(stdout, end='')
        return code
    return run_script('optimize-workflow', script_args)

def cmd_finalize(args):
    """Run finalization workflow"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    if hasattr(args, 'json') and args.json:
        script_args.append('--json')
        stdout, code = run_script('finalize-workflow', script_args, capture=True)
        print(stdout, end='')
        return code
    return run_script('finalize-workflow', script_args)

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

def cmd_ship_rollback(args):
    """Rollback to previous deployment version"""
    script_args = []
    if args.version:
        script_args.append(args.version)
    if args.feature_dir:
        script_args.extend(['--feature-dir', args.feature_dir])
    if args.no_input:
        script_args.append('--no-input')
    return run_script('ship-rollback', script_args)

def cmd_ship_recover(args):
    """Recover corrupted state.yaml from git history"""
    script_args = []
    if args.feature_dir:
        script_args.extend(['--feature-dir', args.feature_dir])
    return run_script('ship-recover', script_args)

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
    """Contract-governance compatibility shim"""
    script_args = ['--type', args.type]
    if args.file:
        script_args.extend(['--file', args.file])
    return run_script('contract-bump', script_args)

def cmd_contract_verify(args):
    """Contract-governance compatibility shim"""
    script_args = []
    if args.baseline:
        script_args.extend(['--baseline', args.baseline])
    return run_script('contract-verify', script_args)

def cmd_fixture_refresh(args):
    """Fixture refresh compatibility shim"""
    script_args = []
    if args.contract:
        script_args.extend(['--contract', args.contract])
    if args.output:
        script_args.extend(['--output', args.output])
    return run_script('fixture-refresh', script_args)

# Living Documentation Commands

def cmd_generate_feature_claude(args):
    """Generate feature-level CLAUDE.md file"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    if args.force:
        script_args.append('--force')
    return run_script('generate-feature-claude-md', script_args)

def cmd_generate_project_claude(args):
    """Generate project-level CLAUDE.md file"""
    script_args = []
    if args.force:
        script_args.append('--force')
    return run_script('generate-project-claude-md', script_args)

def cmd_update_living_docs(args):
    """Trigger living documentation update"""
    script_args = []
    if args.feature:
        script_args.append(args.feature)
    if args.scope:
        script_args.extend(['--scope', args.scope])
    return run_script('update-living-docs', script_args)

def cmd_health_check_docs(args):
    """Scan for stale documentation"""
    script_args = []
    if args.json:
        script_args.append('--json')
    if args.threshold:
        script_args.extend(['--threshold', str(args.threshold)])

    if args.json:
        stdout, code = run_script('health-check-docs', script_args, capture=True)
        print(stdout, end='')
        return code
    else:
        return run_script('health-check-docs', script_args)

# Project Initialization

def cmd_init_project(args):
    """Initialize project with 8-document generation"""
    script_args = []
    if args.project_type:
        script_args.extend(['--type', args.project_type])
    if args.yes:
        script_args.append('--yes')
    return run_script('init-project', script_args)

# Roadmap Management

def cmd_roadmap(args):
    """Manage product roadmap via GitHub Issues"""
    script_args = []
    if args.action:
        script_args.append(args.action)
    if args.feature:
        script_args.extend(['--feature', args.feature])
    if args.priority:
        script_args.extend(['--priority', args.priority])
    if args.json:
        script_args.append('--json')

    if args.json:
        stdout, code = run_script('roadmap-manager', script_args, capture=True)
        print(stdout, end='')
        return code
    else:
        return run_script('roadmap-manager', script_args)

# Design System Health

def cmd_design_health(args):
    """Monitor design system health and staleness"""
    script_args = []
    if args.verbose:
        script_args.append('--verbose')
    if args.json:
        script_args.append('--json')

    if args.json:
        stdout, code = run_script('design-health-check', script_args, capture=True)
        print(stdout, end='')
        return code
    else:
        return run_script('design-health-check', script_args)

# Epic & Sprint Management

def cmd_epic(args):
    """Run shared epic engine operations"""
    if not args.action:
        print("Epic runtime support in spec-cli.py is limited to shared engine operations:")
        print("  create        Scaffold a new epic directory and state file")
        print("  list          List GitHub epic labels")
        print("  progress      Show sprint progress for an epic label")
        print("  auto-assign   Assign unlabeled epic issues to a sprint")
        print("  list-sprint   List issues in a sprint label")
        print("\nFull interactive epic orchestration still runs through tool-specific")
        print("/epic adapter surfaces while runtime ownership converges.")
        return 0

    if args.action == 'create':
        description = args.description or args.target or args.epic_name
        if not description:
            print("Error: epic create requires a description via positional target or --description", file=sys.stderr)
            return 1

        script_args = []
        if args.json:
            script_args.append('--json')
        script_args.append(description)

        if args.json:
            stdout, code = run_script('create-new-epic', script_args, capture=True)
            print(stdout, end='')
            return code
        return run_script('create-new-epic', script_args)

    if args.json:
        print("Error: --json is only supported for epic create", file=sys.stderr)
        return 1

    if args.action == 'list':
        return run_script('epic-manager', ['list'])

    if args.action == 'progress':
        epic_name = args.target or args.epic_name
        if not epic_name:
            print("Error: epic progress requires an epic name or slug", file=sys.stderr)
            return 1
        return run_script('epic-manager', ['progress', epic_name])

    if args.action == 'auto-assign':
        epic_name = args.target or args.epic_name
        if not epic_name:
            print("Error: epic auto-assign requires an epic name or slug", file=sys.stderr)
            return 1
        script_args = ['auto-assign', epic_name]
        if args.sprint_label:
            script_args.append(args.sprint_label)
        return run_script('epic-manager', script_args)

    if args.action == 'list-sprint':
        sprint_label = args.target or args.sprint_label
        if not sprint_label:
            print("Error: epic list-sprint requires a sprint label (for example S01)", file=sys.stderr)
            return 1
        return run_script('epic-manager', ['list-sprint', sprint_label])

    print(f"Error: Unsupported epic action: {args.action}", file=sys.stderr)
    return 1

def cmd_sprint(args):
    """Manage sprint cycles"""
    script_args = []
    if args.action:
        script_args.append(args.action)
    if args.sprint_num:
        script_args.extend(['--sprint', str(args.sprint_num)])
    if args.features:
        script_args.extend(['--features', args.features])
    return run_script('sprint-manage', script_args)

# Feature Flags & Scheduling

def cmd_flag(args):
    """Feature-flag compatibility shim"""
    script_args = []
    if args.action:
        script_args.append(args.action)
    if args.flag_name:
        script_args.extend(['--flag', args.flag_name])
    if args.enabled is not None:
        script_args.extend(['--enabled', str(args.enabled).lower()])
    return run_script('flag-manage', script_args)

def cmd_schedule(args):
    """Epic scheduler compatibility shim during runtime transition"""
    script_args = []
    if args.action:
        script_args.append(args.action)
    if args.epic:
        script_args.append(args.epic)
    if args.agent:
        script_args.extend(['--agent', args.agent])
    if args.reason:
        script_args.extend(['--reason', args.reason])
    if args.json:
        script_args.append('--json')
    return run_script('schedule-manage', script_args)

def cmd_scheduler_assign(args):
    """Assign epic to agent (max 1 epic per agent)"""
    return run_script('schedule-manage', ['assign', args.epic, '--agent', args.agent])

def cmd_scheduler_list(args):
    """List all epics with state and WIP utilization"""
    script_args = []
    if args.json:
        script_args.append('--json')

    if args.json:
        stdout, code = run_script('schedule-manage', ['list', *script_args], capture=True)
        print(stdout, end='')
        return code
    else:
        return run_script('schedule-manage', ['list', *script_args])

def cmd_scheduler_park(args):
    """Park blocked epic and release WIP slot"""
    return run_script('schedule-manage', ['park', args.epic, '--reason', args.reason])

# Quality Gates & Metrics

def cmd_gate(args):
    """Manage quality gates"""
    script_args = []
    if args.gate_type:
        script_args.append(args.gate_type)
    if args.action:
        script_args.extend(['--action', args.action])
    if args.json:
        script_args.append('--json')

    if args.json:
        stdout, code = run_script('gate-check', script_args, capture=True)
        print(stdout, end='')
        return code
    else:
        return run_script('gate-check', script_args)

def cmd_metrics(args):
    """Metrics compatibility shim"""
    script_args = []
    if args.metric_type:
        script_args.append(args.metric_type)
    if args.period:
        script_args.extend(['--period', args.period])
    if args.json:
        script_args.append('--json')

    if args.json:
        stdout, code = run_script('metrics-track', script_args, capture=True)
        print(stdout, end='')
        return code
    else:
        return run_script('metrics-track', script_args)

def cmd_metrics_dora(args):
    """DORA metrics compatibility shim"""
    script_args = []
    if args.since:
        script_args.extend(['--since', args.since])
    if args.output:
        script_args.extend(['--output', args.output])
    if args.json:
        script_args.append('--json')

    if args.json:
        stdout, code = run_script('dora-calculate', script_args, capture=True)
        print(stdout, end='')
        return code
    else:
        return run_script('dora-calculate', script_args)

# Version & Dependency Management

def cmd_version(args):
    """Manage version bumps"""
    script_args = []
    if args.bump_type:
        script_args.append(args.bump_type)
    if args.message:
        script_args.extend(['--message', args.message])
    return run_script('version-manager', script_args)

def cmd_deps(args):
    """Manage dependency updates"""
    script_args = []
    if args.action:
        script_args.append(args.action)
    if args.package:
        script_args.extend(['--package', args.package])
    if args.security_only:
        script_args.append('--security-only')
    return run_script('deps-manage', script_args)

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
    clarify_parser.add_argument('--json', action='store_true', help='Output as JSON')

    # plan
    plan_parser = subparsers.add_parser('plan', help='Generate implementation plan from spec')
    plan_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')
    plan_parser.add_argument('--interactive', action='store_true', help='Force wait for user confirmation')
    plan_parser.add_argument('--yes', action='store_true', help='Skip all HITL gates and auto-commit')
    plan_parser.add_argument('--skip-clarify', action='store_true', help='Skip spec ambiguity gate only')
    plan_parser.add_argument('--json', action='store_true', help='Output as JSON')

    # preview
    preview_parser = subparsers.add_parser(
        'preview',
        help='Preview compatibility shim (shared runtime not shipped here)',
        description='Direct shared /preview execution is not shipped in this checkout. The shim only performs compatibility preflight.',
    )
    preview_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')
    preview_parser.add_argument('--json', action='store_true', help='Output as JSON')

    # validate
    validate_parser = subparsers.add_parser(
        'validate',
        help='Validation compatibility shim (preflight only here)',
        description='Direct shared /validate execution is not shipped in this checkout. The shim only performs compatibility preflight.',
    )
    validate_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')
    validate_parser.add_argument('--json', action='store_true', help='Output as JSON')

    # tasks
    tasks_parser = subparsers.add_parser(
        'tasks',
        help='Task-generation compatibility shim (adapter-owned here)',
        description='Direct shared /tasks generation is not shipped in this checkout. The shim only performs compatibility preflight.',
    )
    tasks_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')
    tasks_parser.add_argument('--ui-first', action='store_true', help='Generate HTML mockups before implementation')
    tasks_parser.add_argument('--json', action='store_true', help='Output as JSON')

    # implement
    implement_parser = subparsers.add_parser(
        'implement',
        help='Implementation compatibility shim (preflight only here)',
        description='Direct shared /implement execution is not shipped in this checkout. The shim only performs compatibility preflight.',
    )
    implement_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')
    implement_parser.add_argument('--json', action='store_true', help='Output as JSON')

    # debug
    debug_parser = subparsers.add_parser('debug', help='Debug errors and update error-log.md')
    debug_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')
    debug_parser.add_argument('--error', help='Error message or description')
    debug_parser.add_argument('--json', action='store_true', help='Output as JSON')

    # optimize
    optimize_parser = subparsers.add_parser('optimize', help='Production-readiness validation')
    optimize_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')
    optimize_parser.add_argument('--json', action='store_true', help='Output as JSON')

    # finalize
    finalize_parser = subparsers.add_parser('finalize', help='Post-deploy documentation and housekeeping')
    finalize_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')
    finalize_parser.add_argument('--json', action='store_true', help='Output as JSON')

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

    # ship-rollback
    ship_rollback_parser = subparsers.add_parser('ship-rollback', help='Rollback to previous deployment version')
    ship_rollback_parser.add_argument('version', nargs='?', help='Version to rollback to (e.g., v1.2.3)')
    ship_rollback_parser.add_argument('--feature-dir', help='Feature directory path')
    ship_rollback_parser.add_argument('--no-input', action='store_true', help='Non-interactive mode')

    # ship-recover
    ship_recover_parser = subparsers.add_parser('ship-recover', help='Recover corrupted state.yaml from git history')
    ship_recover_parser.add_argument('--feature-dir', help='Feature directory path')

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
    bump_parser = subparsers.add_parser(
        'contract-bump',
        help='Contract-governance compatibility shim (not shipped here)',
        description='Planned contract-governance surface. No shared script is shipped in this checkout.',
    )
    bump_parser.add_argument('--type', required=True, choices=['major', 'minor', 'patch'],
                            help='Version bump type')
    bump_parser.add_argument('--file', help='Contract file path')

    # contract-verify
    verify_parser = subparsers.add_parser(
        'contract-verify',
        help='Contract-governance compatibility shim (not shipped here)',
        description='Planned contract-governance surface. No shared script is shipped in this checkout.',
    )
    verify_parser.add_argument('--baseline', help='Baseline contract version')

    # fixture-refresh
    fixture_parser = subparsers.add_parser(
        'fixture-refresh',
        help='Fixture refresh compatibility shim (not shipped here)',
        description='Planned fixture-refresh surface. No shared script is shipped in this checkout.',
    )
    fixture_parser.add_argument('--contract', help='Contract version to use')
    fixture_parser.add_argument('--output', help='Output directory for fixtures')

    # Living Documentation Commands

    # generate-feature-claude
    gen_feature_parser = subparsers.add_parser('generate-feature-claude', help='Generate feature-level CLAUDE.md')
    gen_feature_parser.add_argument('feature', nargs='?', help='Feature slug (optional, auto-detected if in feature dir)')
    gen_feature_parser.add_argument('--force', action='store_true', help='Force regeneration even if file exists')

    # generate-project-claude
    gen_project_parser = subparsers.add_parser('generate-project-claude', help='Generate project-level CLAUDE.md')
    gen_project_parser.add_argument('--force', action='store_true', help='Force regeneration even if file exists')

    # update-living-docs
    update_docs_parser = subparsers.add_parser('update-living-docs', help='Trigger living documentation update')
    update_docs_parser.add_argument('feature', nargs='?', help='Feature slug (optional, updates all if not specified)')
    update_docs_parser.add_argument('--scope', choices=['feature', 'project', 'all'], help='Update scope')

    # health-check-docs
    health_docs_parser = subparsers.add_parser('health-check-docs', help='Scan for stale documentation')
    health_docs_parser.add_argument('--json', action='store_true', help='Output as JSON')
    health_docs_parser.add_argument('--threshold', type=int, default=7, help='Staleness threshold in days (default: 7)')

    # Project Initialization

    # init-project
    init_project_parser = subparsers.add_parser('init-project', help='Initialize project with 8-document generation')
    init_project_parser.add_argument('--type', dest='project_type', choices=['greenfield', 'brownfield'], help='Project type')
    init_project_parser.add_argument('--yes', action='store_true', help='Skip interactive prompts (use defaults)')

    # Roadmap Management

    # roadmap
    roadmap_parser = subparsers.add_parser('roadmap', help='Manage product roadmap via GitHub Issues')
    roadmap_parser.add_argument('action', nargs='?', choices=['brainstorm', 'prioritize', 'track'], help='Roadmap action')
    roadmap_parser.add_argument('--feature', help='Feature name or ID')
    roadmap_parser.add_argument('--priority', choices=['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'], help='Feature priority')
    roadmap_parser.add_argument('--json', action='store_true', help='Output as JSON')

    # Design System Health

    # design-health
    design_health_parser = subparsers.add_parser('design-health', help='Monitor design system health and staleness')
    design_health_parser.add_argument('--verbose', action='store_true', help='Show detailed output')
    design_health_parser.add_argument('--json', action='store_true', help='Output as JSON')

    # Epic & Sprint Management

    # epic
    epic_parser = subparsers.add_parser('epic', help='Run shared epic engine operations')
    epic_parser.add_argument('action', nargs='?', choices=['create', 'list', 'progress', 'auto-assign', 'list-sprint'], help='Epic action')
    epic_parser.add_argument('target', nargs='?', help='Epic description or identifier, depending on action')
    epic_parser.add_argument('--name', '--epic', dest='epic_name', help='Epic name or slug')
    epic_parser.add_argument('--description', help='Epic description')
    epic_parser.add_argument('--sprint', dest='sprint_label', help='Sprint label (e.g. S01)')
    epic_parser.add_argument('--json', action='store_true', help='Output JSON when supported')

    # sprint
    sprint_parser = subparsers.add_parser('sprint', help='Manage sprint cycles')
    sprint_parser.add_argument('action', nargs='?', choices=['start', 'end', 'status'], help='Sprint action')
    sprint_parser.add_argument('--sprint', dest='sprint_num', type=int, help='Sprint number')
    sprint_parser.add_argument('--features', help='Comma-separated feature slugs')

    # Feature Flags & Scheduling

    # flag
    flag_parser = subparsers.add_parser(
        'flag',
        help='Feature-flag compatibility shim (not shipped here)',
        description='Planned feature-flag surface. No shared script is shipped in this checkout.',
    )
    flag_parser.add_argument('action', nargs='?', choices=['create', 'toggle', 'list'], help='Flag action')
    flag_parser.add_argument('--flag', dest='flag_name', help='Flag name')
    flag_parser.add_argument('--enabled', type=bool, help='Enable/disable flag')

    # schedule
    schedule_parser = subparsers.add_parser(
        'schedule',
        help='Epic scheduler compatibility shim (planned)',
        description='Planned scheduler surface. The shared scheduler runtime is not shipped in this checkout.',
    )
    schedule_parser.add_argument('action', nargs='?', choices=['assign', 'list', 'park'], help='Scheduler action')
    schedule_parser.add_argument('epic', nargs='?', help='Epic ID or slug')
    schedule_parser.add_argument('--agent', help='Agent name for assignment')
    schedule_parser.add_argument('--reason', help='Reason for parking or scheduler note')
    schedule_parser.add_argument('--json', action='store_true', help='Output JSON when supported')

    # scheduler-assign
    scheduler_assign_parser = subparsers.add_parser(
        'scheduler-assign',
        help='Planned scheduler shim for epic assignment',
        description='Planned scheduler surface. The shared scheduler runtime is not shipped in this checkout.',
    )
    scheduler_assign_parser.add_argument('epic', help='Epic ID or slug')
    scheduler_assign_parser.add_argument('agent', help='Agent name (backend/frontend/database/etc)')

    # scheduler-list
    scheduler_list_parser = subparsers.add_parser(
        'scheduler-list',
        help='Planned scheduler shim for epic listing',
        description='Planned scheduler surface. The shared scheduler runtime is not shipped in this checkout.',
    )
    scheduler_list_parser.add_argument('--json', action='store_true', help='Output as JSON')

    # scheduler-park
    scheduler_park_parser = subparsers.add_parser(
        'scheduler-park',
        help='Planned scheduler shim for parked epics',
        description='Planned scheduler surface. The shared scheduler runtime is not shipped in this checkout.',
    )
    scheduler_park_parser.add_argument('epic', help='Epic ID or slug')
    scheduler_park_parser.add_argument('reason', help='Reason for parking (e.g., "blocked by infrastructure")')

    # Quality Gates & Metrics

    # gate
    gate_parser = subparsers.add_parser('gate', help='Manage quality gates')
    gate_parser.add_argument('gate_type', nargs='?', choices=['preflight', 'code-review', 'rollback'], help='Gate type')
    gate_parser.add_argument('--action', choices=['check', 'override'], help='Gate action')
    gate_parser.add_argument('--json', action='store_true', help='Output as JSON')

    # metrics
    metrics_parser = subparsers.add_parser(
        'metrics',
        help='Metrics compatibility shim (not shipped here)',
        description='Planned metrics surface. No shared script is shipped in this checkout.',
    )
    metrics_parser.add_argument('metric_type', nargs='?', choices=['happiness', 'engagement', 'adoption', 'retention', 'task-success'], help='Metric type')
    metrics_parser.add_argument('--period', choices=['daily', 'weekly', 'monthly'], help='Time period')
    metrics_parser.add_argument('--json', action='store_true', help='Output as JSON')

    # metrics-dora
    dora_parser = subparsers.add_parser(
        'metrics-dora',
        help='DORA metrics compatibility shim (not shipped here)',
        description='Planned DORA metrics surface. No shared script is shipped in this checkout.',
    )
    dora_parser.add_argument('--since', help='Start date for analysis (YYYY-MM-DD, default: 90 days ago)')
    dora_parser.add_argument('--output', help='Output file path (default: .spec-flow/reports/dora-report.md)')
    dora_parser.add_argument('--json', action='store_true', help='Output as JSON')

    # Version & Dependency Management

    # version
    version_parser = subparsers.add_parser('version', help='Manage version bumps')
    version_parser.add_argument('bump_type', nargs='?', choices=['major', 'minor', 'patch'], help='Version bump type')
    version_parser.add_argument('--message', help='Version message')

    # deps
    deps_parser = subparsers.add_parser('deps', help='Manage dependency updates')
    deps_parser.add_argument('action', nargs='?', choices=['update', 'audit', 'outdated'], help='Dependency action')
    deps_parser.add_argument('--package', help='Specific package name')
    deps_parser.add_argument('--security-only', action='store_true', help='Only security updates')

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
        'finalize': cmd_finalize,
        'feature': cmd_feature,
        'ship-finalize': cmd_ship_finalize,
        'ship-prod': cmd_ship_prod,
        'ship-rollback': cmd_ship_rollback,
        'ship-recover': cmd_ship_recover,
        'compact': cmd_compact,
        'create-feature': cmd_create_feature,
        'calculate-tokens': cmd_calculate_tokens,
        'check-prereqs': cmd_check_prereqs,
        'detect-infra': cmd_detect_infra,
        'enable-auto-merge': cmd_enable_auto_merge,
        'branch-enforce': cmd_branch_enforce,
        'contract-bump': cmd_contract_bump,
        'contract-verify': cmd_contract_verify,
        'fixture-refresh': cmd_fixture_refresh,
        # Living Documentation
        'generate-feature-claude': cmd_generate_feature_claude,
        'generate-project-claude': cmd_generate_project_claude,
        'update-living-docs': cmd_update_living_docs,
        'health-check-docs': cmd_health_check_docs,
        # Project Initialization
        'init-project': cmd_init_project,
        # Roadmap Management
        'roadmap': cmd_roadmap,
        # Design System Health
        'design-health': cmd_design_health,
        # Epic & Sprint Management
        'epic': cmd_epic,
        'sprint': cmd_sprint,
        # Feature Flags & Scheduling
        'flag': cmd_flag,
        'schedule': cmd_schedule,
        'scheduler-assign': cmd_scheduler_assign,
        'scheduler-list': cmd_scheduler_list,
        'scheduler-park': cmd_scheduler_park,
        # Quality Gates & Metrics
        'gate': cmd_gate,
        'metrics': cmd_metrics,
        'metrics-dora': cmd_metrics_dora,
        # Version & Dependency Management
        'version': cmd_version,
        'deps': cmd_deps,
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
