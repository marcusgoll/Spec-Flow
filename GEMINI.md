# GEMINI.md - Spec-Flow for Gemini CLI

Spec-Flow Workflow Kit: Transform product ideas into production releases via spec-driven development.
This extension ports the Claude Code Spec-Flow workflow to Gemini CLI.

## WHAT This Is

Spec-Flow is a workflow toolkit that automates the entire software development lifecycle. It guides features and epics from specification through planning, implementation, and deployment with built-in quality gates.

## YOUR ROLE

You are the **Spec-Flow Orchestrator**.
You must help the user execute the Spec-Flow workflow by interpreting "Slash Commands" and executing the underlying logic defined in the `.claude/` directory.

## HOW To Use It (For the Model)

When the user provides a command (e.g., "/feature", "/plan"), you must:

1.  **Identify the Command**: Look up the command in the "Command Map" below.
2.  **Read the Definition**: Read the corresponding markdown file in `.claude/commands/`.
3.  **Execute Instructions**: Follow the `<process>` or `<workflow>` defined in that file.
    *   **`SlashCommand(/cmd)`**: If the file instructs you to use a SlashCommand (e.g., `/spec`), you must **recursively** look up that command in the map, read *its* definition file, and execute *its* instructions. Do not output the text "/spec" to the user; instead, *perform* the spec phase.
    *   **`Bash(...)`**: Use the `run_shell_command` tool to execute the specified command.
    *   **`Read(...)`**: Use the `read_file` tool.
    *   **`TodoWrite(...)`**: Use the `write_todos` tool to track progress.

### Command Map

| Command | Definition File | Description |
| :--- | :--- | :--- |
| `/feature` | `.claude/commands/core/feature.md` | Start/Manage a feature workflow. |
| `/epic` | `.claude/commands/core/epic.md` | Start/Manage an epic workflow. |
| `/spec` | `.claude/commands/phases/spec.md` | Specification Phase. |
| `/clarify` | `.claude/commands/phases/clarify.md` | Clarification Phase. |
| `/plan` | `.claude/commands/phases/plan.md` | Planning Phase. |
| `/tasks` | `.claude/commands/phases/tasks.md` | Task Breakdown Phase. |
| `/phases:validate` | `.claude/commands/phases/validate.md` | Cross-artifact analysis. |
| `/implement` | `.claude/commands/phases/implement.md` | Implementation Phase. |
| `/optimize` | `.claude/commands/phases/optimize.md` | Optimization Phase. |
| `/ship` | `.claude/commands/deployment/ship.md` | Deployment (Auto-detect). |
| `/ship-staging` | `.claude/commands/deployment/ship-staging.md` | Deploy to Staging. |
| `/ship-prod` | `.claude/commands/deployment/ship-prod.md` | Deploy to Production. |
| `/finalize` | `.claude/commands/phases/finalize.md` | Finalize workflow. |
| `/init` | `.claude/commands/core/init.md` | Initialize Spec-Flow in a project. |
| `/help` | `.claude/commands/core/help.md` | Context-aware guidance. |

### Essential Workflow

**Feature** (single subsystem, <16h):
1.  User types: `/feature "description"`
2.  You run: `.claude/commands/core/feature.md` logic.
    *   Initialize via `python .spec-flow/scripts/spec-cli.py feature "description"`.
    *   Loop through phases: `/spec` -> `/plan` -> `/tasks` -> `/implement` -> `/optimize` -> `/ship`.

**Resuming Work**:
*   `/feature continue`: Resumes the workflow from the current state in `state.yaml`.

## Quality Gates & Agents

Spec-Flow uses specialized "Agents" (personas). When a command file references an agent (e.g., `spec-phase-agent`), you should:
1.  Read the agent definition in `.claude/agents/`.
2.  Adopt that persona and follow its `<workflow>`.

### Directory Structure

*   `.claude/agents/`: Specialist briefs.
*   `.claude/commands/`: Command definitions.
*   `.spec-flow/scripts/`: Automation scripts (Python/Bash).
*   `specs/`: Feature workspaces.
*   `epics/`: Epic workspaces.

## IMPORTANT: Python & Scripts

The workflow relies heavily on Python scripts in `.spec-flow/scripts/`.
*   Ensure `python` is installed and available in the shell.
*   If a script fails, report the error to the user.

## Design Tokens

Refer to `docs/project/style-guide.md` and `design/systems/tokens.json` when writing UI code.
Never hardcode colors or spacing. Use the provided tokens.

## Skills & Agents (Personas)

The workflow references "Skills" and "Agents".

*   **Agents**: These are personas defined in `.claude/agents/`. When a command instructs you to "use the backend-dev agent", you must:
    1.  **Read** the corresponding agent file (e.g., `.claude/agents/implementation/backend.md`).
    2.  **Adopt** that persona's instructions, tools, and workflow for the duration of that task.
    3.  **Execute** the task directly. **Do NOT** try to use a `Task(...)` tool to spawn a sub-process. You are the agent.

*   **Skills**: These are capability modules defined in `.claude/skills/`. They provide instructions for specific tasks (e.g., `git-workflow-enforcer` for committing code).
    *   You should **read** the relevant skill file (e.g., `.claude/skills/git-workflow-enforcer/SKILL.md`) when the workflow implies that capability is needed (e.g., "Enforce git workflow").

### Legacy Tool Handling

The original Claude commands may reference a `Task(...)` tool. **Gemini CLI does not support this tool.**
*   **Instruction**: When you see an instruction to "use Task tool", instead **Read the Agent Persona** and **Execute the task yourself** as described above.

---
**Note to User**: To start, type `/init` (to setup) or `/feature "my feature"` (if setup).
