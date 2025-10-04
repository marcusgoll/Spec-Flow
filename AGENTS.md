# Repository Guidelines

## Project Structure & Module Organization
Spec-Flow keeps agent collateral under `.claude/`. Briefs live in `.claude/agents/`, and command playbooks sit in `.claude/commands/`. Repo-level preferences start from `.claude/settings.example.json` (copy to `.claude/settings.local.json` locally). Automation assets are mirrored for each platform: PowerShell scripts in `.spec-flow/scripts/powershell/`, shell scripts in `.spec-flow/scripts/bash/`, long-term memory in `.spec-flow/memory/`, and reusable templates inside `.spec-flow/templates/`. Create new assets beside their peers and stick to kebab-case filenames.

## Build, Test, and Development Commands
Check your environment with either `pwsh -NoProfile -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Json` or `.spec-flow/scripts/bash/check-prerequisites.sh --json`. Scaffold features via the matching `create-new-feature` script. Estimate token usage with `.spec-flow/scripts/{powershell|bash}/calculate-tokens.*`, and trim stale context using `.spec-flow/scripts/{powershell|bash}/compact-context.*`. Prefer the PowerShell versions on Windows and the `.sh` versions on macOS/Linux.

## Coding Style & Naming Conventions
Markdown guides should open with an H1, use sentence-case headings, and wrap near 100 characters. Favor imperative voice for instructions and keep decisions as bullets. PowerShell scripts live in `.spec-flow/scripts/powershell/`, using four-space indentation, `Verb-Noun` functions, and comment-based help. Shell scripts in `.spec-flow/scripts/bash/` should be POSIX-friendly, exit on error, and document required tools. Name documents with kebab-case (for example, `agent-operating-manual.md`) and CamelCase only for PowerShell modules.

## Testing Guidelines
There is no CI yet, so run scripts locally (`-WhatIf` where available) before submitting changes. When adding non-trivial automation, include a Pester or shell-based test under `tests/` and document how to execute it (`Invoke-Pester -Path tests` or `pytest`). For Markdown templates, preview them in a renderer and confirm token estimates stay inside the active phase budget.

## Commit & Pull Request Guidelines
Follow Conventional Commits (`feat`, `fix`, `docs`, `chore`) with imperative subjects such as `docs: refresh debugger brief`. Keep related template and script updates together; large reorganisations should land in a sequence of small commits. Pull requests must describe the change, link to supporting issues, provide before/after snippets for documentation updates, and list the validation commands you ran.

## Agent-Specific Instructions
Keep personas focused on goals, list capabilities in priority order, and cross-link to supporting templates. Mirror persistent decisions in `.spec-flow/memory/` and rerun the appropriate roadmap script (`roadmap-init` in PowerShell or shell) whenever strategy shifts.

