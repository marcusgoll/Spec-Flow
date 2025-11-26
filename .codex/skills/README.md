# Codex Skills

- Drop Codex-specific helper prompts or adapters here when mirroring Claude skills.
- Reference `.spec-flow/repo-map.yaml`, `.spec-flow/docs/epic-workflow.md`, and `.spec-flow/docs/state-epic.yaml` before creating new skills.
- Keep filenames kebab-case and describe the shared Claude skill you are adapting; link back to the original `.claude/skills/**` file for parity.
- Run `node .codex/skills/export-skills.js` whenever you add or update a skill. The script reads each skill's front‑matter and regenerates `skills-index.yaml` so downstream prompts can load metadata dynamically.
- Other tools treat this directory as read-only. Codex owns change requests here.

### Quick skill call check

Use `node .codex/skills/test-skill-call.js --list` to see discoverable skills from `skills-index.yaml`, then `node .codex/skills/test-skill-call.js planning-phase` (replace with any skill name) to load the skill and preview its content.
