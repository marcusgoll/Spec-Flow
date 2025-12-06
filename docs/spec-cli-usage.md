# spec-cli.py - Centralized Workflow CLI

## Overview

The `spec-cli.py` is a unified command-line interface that provides a single entry point for all Spec-Flow workflow scripts. It replaces the need to embed raw bash/PowerShell scripts inside command markdown files, dramatically reducing file size and improving maintainability.

## Architecture

```
.spec-flow/scripts/
├── spec-cli.py                 # Single CLI entry point (~200 lines)
├── bash/                       # Bash implementations
│   ├── clarify-workflow.sh     # Extracted from clarify.md
│   ├── check-prerequisites.sh  # Existing script
│   ├── compact-context.sh      # Existing script
│   └── ...
└── powershell/                 # PowerShell implementations
    ├── check-prerequisites.ps1
    ├── compact-context.ps1
    └── ...
```

## Benefits

1. **Massive file size reduction**: Commands reduced by 50-70%
   - `clarify.md`: 721 lines → 323 lines (55% reduction)
   - Other commands: Similar reductions expected

2. **Single source of truth**: Scripts stay in `.spec-flow/scripts/` directory

3. **Cross-platform**: Auto-detects Windows/Mac/Linux and calls appropriate scripts

4. **One command interface**: `python .spec-flow/scripts/spec-cli.py <cmd>` for everything

5. **Easier maintenance**: Update scripts without touching command files

6. **Token efficiency**: Commands only describe **what** the workflow does, not **how**

## Usage

### Basic Syntax

```bash
python .spec-flow/scripts/spec-cli.py <command> [options]
```

### Available Commands

#### 1. clarify

Interactive clarification workflow

```bash
python .spec-flow/scripts/spec-cli.py clarify [feature-slug]
```

**Options:**

- `feature-slug` - Optional feature slug (auto-detected if in feature dir)

**Example:**

```bash
python .spec-flow/scripts/spec-cli.py clarify my-feature
```

#### 2. compact

Compact context for phase

```bash
python .spec-flow/scripts/spec-cli.py compact --feature-dir <dir> --phase <phase>
```

**Options:**

- `--feature-dir` - Feature directory path (required)
- `--phase` - Phase name: planning, implementation, or optimization (required)

**Example:**

```bash
python .spec-flow/scripts/spec-cli.py compact --feature-dir specs/001-auth --phase implementation
```

#### 3. create-feature

Create new feature directory

```bash
python .spec-flow/scripts/spec-cli.py create-feature "Feature Name"
```

**Example:**

```bash
python .spec-flow/scripts/spec-cli.py create-feature "User Authentication"
```

#### 4. calculate-tokens

Calculate token budget

```bash
python .spec-flow/scripts/spec-cli.py calculate-tokens --feature-dir <dir>
```

**Example:**

```bash
python .spec-flow/scripts/spec-cli.py calculate-tokens --feature-dir specs/001-auth
```

#### 5. check-prereqs

Check prerequisites and validate environment

```bash
python .spec-flow/scripts/spec-cli.py check-prereqs [--json] [--paths-only]
```

**Options:**

- `--json` - Output as JSON
- `--paths-only` - Only return paths (requires --json)

**Example:**

```bash
# Human-readable output
python .spec-flow/scripts/spec-cli.py check-prereqs

# JSON output for scripting
python .spec-flow/scripts/spec-cli.py check-prereqs --json

# Paths only (for parsing in scripts)
python .spec-flow/scripts/spec-cli.py check-prereqs --json --paths-only
```

#### 6. detect-infra

Detect infrastructure needs

```bash
python .spec-flow/scripts/spec-cli.py detect-infra [feature-slug]
```

#### 7. enable-auto-merge

Enable auto-merge for PR

```bash
python .spec-flow/scripts/spec-cli.py enable-auto-merge [--pr <number>]
```

**Example:**

```bash
python .spec-flow/scripts/spec-cli.py enable-auto-merge --pr 123
```

#### 8. branch-enforce

Enforce branch naming conventions

```bash
python .spec-flow/scripts/spec-cli.py branch-enforce
```

#### 9. debug

Run debug workflow

```bash
python .spec-flow/scripts/spec-cli.py debug [--error <message>]
```

**Example:**

```bash
python .spec-flow/scripts/spec-cli.py debug --error "TypeError: undefined is not a function"
```

#### 10. contract-bump

Bump API contract version

```bash
python .spec-flow/scripts/spec-cli.py contract-bump --type <type> [--file <path>]
```

**Options:**

- `--type` - Version bump type: major, minor, or patch (required)
- `--file` - Contract file path (optional)

**Example:**

```bash
python .spec-flow/scripts/spec-cli.py contract-bump --type minor
```

#### 11. contract-verify

Verify API contract compatibility

```bash
python .spec-flow/scripts/spec-cli.py contract-verify [--baseline <version>]
```

**Example:**

```bash
python .spec-flow/scripts/spec-cli.py contract-verify --baseline v1.2.0
```

## How It Works

### Platform Detection

The CLI automatically detects your platform and chooses the appropriate script:

- **Windows**: Uses PowerShell scripts (`.ps1`)
- **macOS/Linux**: Uses Bash scripts (`.sh`)

### Script Execution

When you run a command:

1. CLI parses arguments
2. Detects platform (Windows/Mac/Linux)
3. Finds corresponding script in `bash/` or `powershell/` directory
4. Executes script with provided arguments
5. Returns output or exit code

### Error Handling

- Exit code `0`: Success
- Exit code `1`: Error (script not found, execution failed)
- Exit code `2`: Partial completion (e.g., clarify with remaining ambiguities)

## Integration with Command Files

Command markdown files (`.claude/commands/phases/*.md`) now reference the CLI instead of embedding raw scripts.

### Before (721 lines)

```markdown
<instructions>
```bash
# 600+ lines of embedded bash
if command -v pwsh &> /dev/null; then
  PREREQ_JSON=$(pwsh -File scripts/powershell/check-prerequisites.ps1 -Json)
else
  PREREQ_JSON=$(scripts/bash/check-prerequisites.sh --json)
fi
# ... hundreds more lines
```

</instructions>
```

### After (323 lines)

```markdown
<instructions>
## Execute Clarification Workflow

Run the centralized spec-cli tool:

```bash
python .spec-flow/scripts/spec-cli.py clarify "$ARGUMENTS"
```

**What the script does:**

1. Prerequisite checks
2. Load spec + checkpoint
3. Fast coverage scan (10 categories)
4. Build coverage map
5. Repo-first precedent check

[Rest of LLM instructions for interactive Q/A...]
</instructions>

```

## Adding New Commands

To add a new command to spec-cli.py:

### 1. Create the bash/PowerShell scripts

```bash
# .spec-flow/scripts/bash/my-new-command.sh
#!/usr/bin/env bash
set -euo pipefail

# Your script logic here
echo "Running my new command with args: $@"
```

```powershell
# .spec-flow/scripts/powershell/my-new-command.ps1
param(
    [string]$Arg1,
    [string]$Arg2
)

# Your script logic here
Write-Host "Running my new command with args: $Arg1, $Arg2"
```

### 2. Add command handler to spec-cli.py

```python
def cmd_my_new_command(args):
    """Run my new command"""
    script_args = ['--arg1', args.arg1, '--arg2', args.arg2]
    return run_script('my-new-command', script_args)
```

### 3. Add argument parser

```python
# In main() function
my_parser = subparsers.add_parser('my-new-command', help='Description')
my_parser.add_argument('--arg1', required=True, help='First argument')
my_parser.add_argument('--arg2', help='Second argument')
```

### 4. Register handler

```python
handlers = {
    # ... existing handlers
    'my-new-command': cmd_my_new_command,
}
```

### 5. Update command markdown

```markdown
<instructions>
Run the command:

```bash
python .spec-flow/scripts/spec-cli.py my-new-command --arg1 value1 --arg2 value2
```

[LLM instructions for what to do after script runs...]
</instructions>

```

## Migration Strategy

To migrate existing commands:

1. **Extract** bash logic from command `.md` files to `.spec-flow/scripts/bash/<command>-workflow.sh`
2. **Update** command `.md` files to call `spec-cli.py <command>`
3. **Test** the command to ensure it works
4. **Document** the command in this file
5. **Backup** old version (`.md.backup`) before replacing

## Troubleshooting

### Script not found

```

Error: Bash script not found: /path/to/script.sh

```

**Solution**: Ensure the script exists in `.spec-flow/scripts/bash/` or `.spec-flow/scripts/powershell/`

### Required shell not found

```

Error: Required shell not found: pwsh

```

**Solution**: Install PowerShell (`pwsh`) on your system

### Permission denied

```

Permission denied: /path/to/script.sh

```

**Solution**: Make script executable:
```bash
chmod +x .spec-flow/scripts/bash/script.sh
```

## Future Enhancements

Potential improvements for spec-cli.py:

1. **Pure Python implementations**: Replace bash/PowerShell scripts with Python modules for better cross-platform support
2. **Plugin system**: Allow custom commands via plugins
3. **Configuration file**: Support `.spec-flow/config.yml` for defaults
4. **Parallel execution**: Run multiple commands concurrently
5. **Dry-run mode**: Preview what scripts will execute without running them
6. **Logging**: Structured logging to `.spec-flow/logs/`
7. **Progress bars**: Visual feedback for long-running commands

## References

- [CLAUDE.md](../CLAUDE.md) - Project overview
- [Architecture](architecture.md) - Workflow architecture
- [Commands](commands.md) - Command catalog
