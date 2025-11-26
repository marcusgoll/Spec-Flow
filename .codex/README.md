# Spec-Flow + Codex CLI

Spec-Flow now provides repo-local Codex prompt templates so any Codex CLI session follows the same constitution as Claude Code or Cursor.

## Installing prompts

1. Run `spec-flow install-codex-prompts` to copy every file in `.codex/commands/` into `$CODEX_HOME/prompts/` (defaults to `~/.codex/prompts/`). Use `--dry-run` to preview and `--force` to skip confirmations.  
2. Manual option: copy the markdown files from `.codex/commands/` to your Codex home yourself. Do not overwrite existing prompts without reviewing diffs.

## Prompt catalog

- **Epic phases**: `spec-flow-epic-spec`, `spec-flow-epic-plan`, `spec-flow-epic-tasks`, `spec-flow-epic-implement`.
- **Guarded auto mode**: `spec-flow-epic-auto` reads `epics/<slug>/state.yaml` and advances only the next permissible phase (spec → clarify → plan) before stopping.
- **Feature phases**: `spec-flow-feature-spec`, `spec-flow-feature-plan`, `spec-flow-feature-tasks`, `spec-flow-feature-implement`.

All prompts share the same responsibilities:

1. Load `.spec-flow/repo-map.yaml` plus the appropriate domain maps (epics, workflow-engine, examples, etc.) to respect DRY rules and preferred locations.
2. Read the epic’s `state.yaml` (and feature `state.yaml` if present) to understand which phases are unlocked.
3. Follow `.spec-flow/commands/<phase>.md` when available; otherwise use the inline instructions baked into the prompt file.
4. Update the epic state file after each phase, keeping `sprints` and `features` arrays accurate and recording `last_updated`.

## Manual vs auto usage

- **Manual control**: Call the specific prompt for the phase you want to run (e.g., `/prompts:spec-flow-epic-plan`). This mode is required for tasks, implementation, optimize, and ship stages.
- **Auto mode**: `/prompts:spec-flow-epic-auto` can advance the epic through the next unfinished early phase (spec or clarify) and optionally the immediate next phase (clarify or plan). It will never run tasks or implementation automatically and always stops for review.
- **Feature prompts**: Use them only after the parent epic’s state says that feature work is active. They always read the epic’s state and refuse to diverge from it.

Regardless of the tool, updates must align with `.spec-flow/repo-map.yaml`, `.spec-flow/domains/*.yaml`, and the epic state file. That alignment keeps Spec-Flow multi-agent friendly across Codex, Claude, Cursor, and any future IDE integrations.

**Note:** `.claude/**` remains read-only for Codex. Use it strictly as a reference to mirror expected behavior, then place all Codex-specific assets under `.codex/`.
