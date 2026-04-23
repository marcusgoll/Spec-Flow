# Spec-Flow Context

Last updated: 2026-04-23

## Bounded Context

This repository is the Spec-Flow source and distribution repo.

It owns the installable workflow assets, packaging surfaces, and documentation
that explain how Spec-Flow is installed and used.

## Owns

- Source workflow assets under `.claude/`, `.codex/`, and `.spec-flow/`
- Packaging and installer surfaces under `bin/`, `package.json`, and publish workflows
- Documentation that explains install, update, packaging, and workflow usage
- Templates and examples that illustrate downstream workflow behavior
- Canonical workflow semantics, shared rules, templates, and state-model references under `.spec-flow/`

## Does Not Own

- Live workflow state for a consuming project
- Consumer-project `epics/<slug>/`, `specs/<feature>/`, or `state.yaml` instances
- Repo-specific implementation work produced after Spec-Flow is installed into another project

## Canonical Terms

- `source repo`: this repository, which authors and distributes Spec-Flow
- `consumer project`: a separate repository where Spec-Flow is installed and used
- `installer CLI`: the packaged `spec-flow` Node CLI commands such as `init`, `update`, and `status`
- `slash command assets`: installed prompt assets such as `/feature`, `/spec`, `/plan`, and `/epic`
- `installer CLI commands`: concrete commands invoked as `npx spec-flow <subcommand>`
- `installed workflow commands`: slash-command or prompt assets installed into a consumer project or tool environment
- `shared canon`: the workflow semantics, schemas, templates, and rules owned by `.spec-flow/`
- `tool adapter surface`: a tool-specific tree such as `.claude/` or `.codex/` that exposes the shared canon in that tool's format
- `active source-repo surface`: a directory or surface that exists in this checkout and may be described as current repo structure
- `planned or illustrative surface`: a future target, consumer-project example, or hypothetical area that must not be described as a current source-repo path unless it exists here
- `checked-in example`: a repository-owned example that exists in this checkout and may be linked as a current source-repo example
- `public installer CLI inventory`: the end-user `npx spec-flow ...` command set
- `public installed workflow inventory`: the end-user slash-command or prompt asset set installed into a consumer project or tool environment
- `maintainer-only source-repo inventory`: authoring, migration, or maintenance commands that exist for Spec-Flow development but are not part of the public distributed operator surface
- `shared execution engine`: the canonical runtime layer for installed workflow commands, centered on `spec-cli.py` and shared `.spec-flow/scripts/*`
- `internal shared engine surface`: maintainer or adapter-facing direct access to the shared execution engine, such as `python .spec-flow/scripts/spec-cli.py ...`
- `public docs surface`: documentation in `docs/` intended for end users and consumer-project operators
- `maintainer docs surface`: source-repo implementation or authoring documentation intended for Spec-Flow maintainers

## Avoid Terms

- Do not call installed slash command assets "the Spec-Flow CLI"
- Do not describe consumer-project workflow state as if it is this repo's live runtime state
- Do not describe example or template paths as guaranteed source-repo paths unless they exist here
- Do not use unqualified `commands` when the distinction between installer CLI commands and installed workflow commands matters
- Do not point readers to consumer-project example paths as if they are checked-in source-repo examples unless those paths actually exist here
- Do not inflate public command counts with maintainer-only source-repo commands
- Do not describe tool-specific command markdown as the primary runtime logic when execution actually lives in the shared script engine
- Do not present direct `spec-cli.py` invocation as a co-equal public operator surface unless that model is intentionally restored
- Do not mix maintainer-only implementation guidance into public docs without explicit labeling or relocation

## Invariants

- This repo may ship templates, examples, and reference docs for `epics/`, `specs/`, and `state.yaml`, but those artifacts belong to consumer projects after installation
- The packaged `spec-flow` binary owns installation, update, health, and setup behaviors; it does not directly execute `/feature` or `/epic` workflows as Node subcommands
- Docs and help text must explicitly qualify whether a command reference means an installer CLI command or an installed workflow command when ambiguity is possible
- Docs must label whether a path or behavior refers to the source repo or to an installed consumer project
- `.spec-flow/` is the canonical owner of workflow semantics, state-model references, templates, and shared rules
- Tool-specific trees remain distinct: `.claude/` for Claude assets, `.codex/` for Codex assets, and `.spec-flow/` for shared workflow assets
- Tool-specific trees are adapter surfaces. They may tailor presentation or invocation for a tool, but they should not silently redefine the shared workflow model
- Only active source-repo surfaces may be documented as current repo structure
- Planned or illustrative surfaces must be labeled explicitly as future, example, or consumer-project-only surfaces
- Checked-in examples in the source repo should have one canonical home under `docs/examples/` unless the repo intentionally restores another real example location
- Command inventories must stay split between public installer CLI commands, public installed workflow commands, and maintainer-only source-repo commands
- Public docs and public command counts must include only the public installer CLI inventory and the public installed workflow inventory
- `spec-cli.py` plus shared `.spec-flow/scripts/*` is the canonical execution engine for installed workflow commands
- `.claude/commands/*` and `.codex/commands/*` are adapter or instruction surfaces and should not silently become a parallel runtime
- Epic workflows should follow the same ownership rule: epic state transitions and executable workflow logic belong to the shared canon or shared execution engine, while tool-native `/epic` surfaces handle interaction and tool-specific UX
- `spec-cli.py` is an internal shared engine surface, not a third public end-user command family
- `docs/` is the public docs surface for users and consumer-project operators
- Maintainer or source-repo implementation guidance belongs in an explicit maintainer docs surface such as `.spec-flow/docs/internal/`

## Active Source-Repo Surfaces

- `.claude/`
- `.codex/`
- `.spec-flow/`
- `.github/`
- `bin/`
- `docs/`
- `scripts/`
- package metadata and root documentation files

## Planned Or Illustrative Surfaces

- Consumer-project `epics/`, `specs/`, and workflow `state.yaml`
- Tool surfaces not present in this checkout, such as `.cursor/`
- Product or integration examples not present in this checkout, such as `api/`, `example-app/`, `example-workflow-app/`, and `docs/codex/`

## Checked-In Examples

- `docs/examples/` is the canonical home for checked-in source-repo examples
- References to `specs/001-example-feature/` describe a consumer-project-style example path, not a current checked-in example in this checkout

## Command Inventories

- `public installer CLI inventory`: `spec-flow` package commands such as `init`, `update`, and `status`
- `public installed workflow inventory`: public slash-command or prompt assets such as `/feature`, `/plan`, and `/epic`
- `maintainer-only source-repo inventory`: internal or repository-maintenance commands and docs that support authoring Spec-Flow itself and must not be counted as public operator surface

## Runtime Ownership

- `shared execution engine`: `spec-cli.py` and shared `.spec-flow/scripts/*` runtime logic
- `internal shared engine surface`: direct invocation of the shared execution engine for maintainers, advanced debugging, and adapter compatibility
- Tool command markdown should primarily expose, constrain, or document the shared execution engine
- Historical self-contained command implementations should be treated as legacy unless explicitly restored as the canonical model
- Epic orchestration is expected to converge on the same shared runtime ownership model as feature and phase workflows

## Documentation Audience

- `public docs surface`: `docs/` content for installation, configuration, workflow usage, and consumer-project operation
- `maintainer docs surface`: `.spec-flow/docs/internal/` and similar explicit maintainer namespaces for source-repo authoring, migration, and implementation details
- Mixed-audience files should be split, moved, or clearly labeled so readers know whether guidance is public or maintainer-only

## Flagged Ambiguities

- `README.md`, `docs/architecture.md`, `.spec-flow/repo-map.yaml`, and `AGENTS.md` currently mix source-repo structure with installed consumer-project structure
- Several documented directories are absent in this checkout and appear to describe downstream or example layouts rather than current source-repo layout
- The docs still need a clean distinction between packaged installer commands and installed slash command assets
- Public docs still contain maintainer-oriented command/runtime material that should be moved, split, or reclassified
