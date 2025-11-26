# Spec-Flow Agents

Spec-Flow coordinates multiple coding tools through a single shared canon. Every agent must read the same rules, reuse the same artifacts, and only write in its designated areas.

## Shared brain

- `.spec-flow/` holds the canonical workflow docs, repo map, state schemas, memory, and automation scripts.
- `epics/<slug>/state.yaml` is the single source of truth for epic phase progress; feature-level `specs/<feature>/state.yaml` is optional and must mirror the epic.
- Roadmaps, specs, plans, tasks, and ship notes all inherit the phase order: `spec → clarify → plan → tasks → implement → optimize → preview → ship → finalize`.

## Tool boundaries

- `.claude/` — Claude Code-only prompts, commands, and hooks. Readable by other tools, but **only Claude edits this tree**.
- `.codex/` — Codex CLI-specific prompts, commands, adapters, and skills. Codex writes here; other tools leave it alone.
- `.cursor/` — Cursor-specific prompts and adapters. Cursor writes here; other tools treat it as read-only.
- Shared assets may live elsewhere (api/, example-app/, docs/), but every tool must honor `.spec-flow/repo-map.yaml` and `.spec-flow/domains/*.yaml` when deciding where to add code.

## Hard rules

1. Never fork new “top-level religions.” Add new integrations under their dedicated folder and mirror the shared canon from `.spec-flow/`.
2. All tools may read `.claude/**` for reference, yet non-Claude edits are prohibited.
3. Epic work begins under `epics/<slug>/`; features live in `specs/<feature>/` and must link back to their parent epic inside `state.yaml`.
4. When progressing any phase, update the relevant `state.yaml` and stop at the documented review boundaries (no macro “run everything” flows).
5. Persistent learnings or roadmap shifts belong in `.spec-flow/memory/` and should be reflected in the shared docs before modifying tool-specific trees.

Follow these rules and every agent—Claude, Codex, Cursor, or future additions—will operate from the same source of truth.
