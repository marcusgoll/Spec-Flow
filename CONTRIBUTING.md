# Contributing

Thanks for helping improve the Spec-Flow Workflow Kit! This project documents a reproducible Claude workflow, so clarity and traceability matter.

## Local Setup
1. Install PowerShell 7.3 or later.
2. Copy `.claude/settings.example.json` to `.claude/settings.local.json` and tailor the `allow` list.
3. Run `pwsh -NoProfile -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Json` to confirm the environment.
4. Create a feature sandbox via `pwsh -NoProfile -File .spec-flow/scripts/powershell/create-new-feature.ps1 -Name "your-feature"` if you want a sample spec tree.

## Branching & Commits
- Use feature branches named `feat/NNN-description` or `docs/NNN-description`.
- Follow Conventional Commits (`feat`, `fix`, `docs`, `chore`, `refactor`, `test`). Keep subjects under 75 characters and imperative (for example, `docs: add spec-flow launch guide`).
- Squash commits locally if they do not tell a meaningful story.

## Pull Request Checklist
- Provide a short summary plus screenshots or excerpts for documentation/template changes.
- List validation commands (for example, `pwsh -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Json`).
- Flag breaking changes or workflow changes explicitly.
- Request review from another maintainer before merging.

## Coding Standards
- Markdown: sentence-case headings, 100-character wrap target, bullet lists for checklists.
- PowerShell: four-space indentation, `Verb-Noun` functions, comment-based help, no aliases in scripts.
- Keep new assets ASCII unless a template already uses Unicode.

## Testing
- Prefer deterministic tests with Pester 5. Place suites under `tests/` and document `Invoke-Pester` commands.
- For scripts that touch the filesystem, support `-WhatIf` or dry-run flags when feasible.

## Release Process
1. Update `CHANGELOG.md` with notable changes (add this file if missing).
2. Tag releases as `vMAJOR.MINOR.PATCH` after merge.
3. Publish a short thread on X.com summarizing improvements using the #SpecFlow hashtag.

By contributing, you agree to abide by the `CODE_OF_CONDUCT.md`. Welcome aboard!
