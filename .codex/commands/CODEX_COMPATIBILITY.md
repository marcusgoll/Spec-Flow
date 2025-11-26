# Codex Compatibility Guide (for `.codex/commands/`)

Codex CLI cannot invoke Claude-specific tools (`Task`, `SlashCommand`, `AskUserQuestion`, `Skill`, `TodoWrite`) or spawn subagents. Use this shim to keep the same behaviors with Codex-only capabilities (shell + file edits).

**Supported tools in this repo:** shell (`bash`/`pwsh`/`python`), file read/write, and the skills index loader (`node .codex/skills/test-skill-call.js`).

## Tool Substitutions

- `SlashCommand(/phase)` → Run the underlying script shown in the command (typically `python .spec-flow/scripts/spec-cli.py <phase> ...`), or execute the bash/PowerShell block verbatim.
- `Task` / subagents → Execute the described steps yourself, sequentially. Use the routing logic as guidance, but do not call Task; stay in the same conversation and run the shell steps directly.
- `AskUserQuestion` → Ask the user inline in chat. Keep the same batching/option structure manually.
- `Skill(name)` → Load the skill content with `node .codex/skills/test-skill-call.js <name>` and follow its SOP manually (no Skill tool).
- `TodoWrite` → Edit `tasks.md`/`state.yaml` directly with `apply_patch`, keeping atomic updates.

## When a command says…

- “Launch X agents in parallel” → Run those steps one-by-one; note the intended parallelism.
- “Call /spec /plan /tasks …” → Invoke the scripts already embedded in the command (bash/ps) instead of slash commands.
- “Use question bank via AskUserQuestion” → Manually present the same options/questions in chat, then proceed with the user’s answers.

## Quick workflow shims

- Feature phases: `python .spec-flow/scripts/spec-cli.py spec|clarify|plan|tasks|implement|optimize|finalize "$ARGS"`
- Deployment: Follow the bash/ps blocks inside `deployment/*.md`; they are executable as-is.
- Skills: `node .codex/skills/test-skill-call.js --list` then `node .codex/skills/test-skill-call.js <skill>`

Apply these substitutions before executing any command text in this directory. This preserves intent without relying on Claude-only tools.
