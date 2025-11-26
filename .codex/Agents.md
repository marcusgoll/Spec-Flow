# Codex Agents

Codex mirrors Claude’s skills by reading shared docs plus Codex-specific metadata.

## Loading skills dynamically

1. Run `node .codex/skills/export-skills.js` after adding or editing any Codex skill (`.codex/skills/*.md`).  
2. The script parses each skill’s front‑matter and regenerates `.codex/skills/skills-index.yaml`:

```yaml
skills:
  - file: planning-skill.md
    name: Epic Planning
    capability: plan
    owner: codex
```

3. Codex prompts can now load this YAML file to discover available skills at runtime:

```bash
# Example prompt snippet
/prompts:spec-flow-epic --skills-from .codex/skills/skills-index.yaml
```

During execution:

- Read `.codex/skills/skills-index.yaml` to determine which `SKILL.md` files apply to the current phase.
- Pull the referenced Markdown skill files (stored under `.codex/skills/`) into context when needed.
- Keep `.claude/skills/**` as the reference canon; Codex copies the relevant sections into `.codex/skills/` when adaptations are required.

This pattern keeps Codex synchronized with Claude’s capabilities without writing inside `.claude/`.
