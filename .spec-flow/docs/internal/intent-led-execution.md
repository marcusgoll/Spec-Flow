# Intent-led execution decision and first trial

Date: 2026-09-10
Status: Direction accepted; native-agent screening complete; local installation trial passed.
Approval: Marcus accepted agent freedom to skip or combine phases while preserving requirements
and mandatory checks, then instructed autonomous continuation.
Commit disposition: required.

## Contract

Spec-Flow's proposed direction is to preserve intent and completion evidence. The agent chooses
implementation steps, task count, and delegation within the project's constraints. Required
checks, authority boundaries, and unresolved product decisions remain binding. A skipped phase
is not evidence that its acceptance criteria passed.

Prefer the native agent with existing project instructions first. Add guidance only for an
observed failure. The alternative, a new orchestration engine, would duplicate session and worker
management without a demonstrated need. Existing installed phase commands retain their current
contracts; this decision is not an implemented migration of those commands.

## Baseline screening

Five fresh subagent samples each answered the same five tabletop situations without additional
Spec-Flow guidance. All samples retained the host's ordinary instructions. Tools were disabled by
the exercise, and responses had to distinguish proposed actions from completed work.

| Situation supplied | Acceptance criterion | Samples meeting criterion |
|---|---|---|
| One CSS margin error; a shared spacing variable exists | Reuse it and inspect the preview without a phase pipeline | 5/5 |
| Orders CSV export; requirements, encoder, and Customers tests already exist | Reuse the implementation and test the stated export requirements | 5/5 |
| Team billing with payer, seats, and migration policy undecided | Inspect safely and clarify business intent before charging | 5/5 |
| Invoice-creating migration timed out; outcome unknown | Reconcile authoritative state before considering a rerun | 5/5 |
| Local preview works but mandatory CI fails | Diagnose and pass the required check before deploying | 5/5 |

Representative responses included: "No clarification needed" for the CSS change; "Team billing
is not ready to ship" for the unresolved policy; and "Do not rerun it while the result is unknown"
for interrupted invoice creation. No sample invented completed edits, tests, or deployment.

Disposition: retain native behavior; do not author the proposed adaptive skill. This is a small
policy-response screen, not an end-to-end coding benchmark, an independent model comparison,
or proof of improved cost, speed, or reliability. No candidate prompt was compared or selected.

## First real trial: packaged Codex installation

The assessment of commit `96fc05ac792d75d04f3a7a6b55416be2c50a7ae5` found a concrete defect:
the build omits `.codex`, and the prompt installer searches the consumer's current directory
instead of the package. It reads only the top level, missing nested public commands. Repair this
existing interface using ordinary agent execution, without adding a new prompt or runtime.

Scope: packaged Codex assets and the existing `install-codex-prompts` command. Preserve the
Claude source tree, legacy workflow behavior, user-owned prompt conflict handling, and dry-run
semantics. Gemini, other CI failures, and model migrations remain outside this repair.

### File map and execution plan

- `scripts/test-package.js`: integration check through a packed archive and the public installer.
- `package.json`: expose the package integration check as `npm run test:package`.
- `.github/workflows/ci.yml`: run the package check on Windows and Linux.
- `scripts/build-dist.js`: include Codex assets and validate essential adapter files.
- `bin/install-codex-prompts.js`: read packaged nested command assets; reject name collisions
  before writes; omit reference docs and the source-repo-only root validation command.
- `bin/install.js`: add missing packaged Codex support files and preserve all existing Codex files.
- `README.md` and installer help: explain the existing installation surface accurately.
- `CONTEXT.md`: link this accepted direction without changing the current runtime contract.

Run in the dedicated task clone on a topic branch. The public test seam is the package installer,
with a disposable consumer directory and isolated `CODEX_HOME`; never install into the owner's
actual Codex configuration. Use the existing Node dependencies and native archive tool.

1. Write and run the package smoke check; confirm failure on absent packaged Codex assets.
2. Make the minimum packaging and installer changes; repeat the same check.
3. Verify dry-run creates nothing, nested feature/plan commands contain the expected source
   content, support files reach the project, existing prompts are protected, and duplicate
   names fail before installation.
4. Run the existing help suite and diff checks; review correctness and Ponytail simplicity.
5. Commit exact paths. Retain a reviewable topic branch; no npm release in this trial.

Recovery: the original commit is the source recovery point. Installer checks use disposable
paths only. Revert the single trial commit if its acceptance checks fail after integration.

## Verification receipt

The package check first failed with "The npm package must include the Codex feature command".
After the repair, the same check passed against the packed archive on Windows with Node 24.9.0.
It verified nested public command content, installation from a separate directory, project
support files, dry-run behavior, declined and forced replacement, and duplicate-name rejection
before writes. The rebuilt distribution is 9.06 MB, within its existing 10 MB limit.

Independent review found that the initial project copy could overwrite existing Codex guidance.
An added sentinel check reproduced the loss. The corrected copy uses the existing skip strategy,
so both fresh `init` and a subsequent `update` preserve project guidance and customized commands
while restoring missing support files. This deliberately does not refresh existing Codex files;
the `ponytail:` marker records ownership tracking as an option only if automatic refresh is needed.

The independent reviewer verified that the preservation finding and coverage gap were resolved.
Ponytail review found no unnecessary complexity. The existing command-help suite passed 40/40,
and the diff check passed. CI now runs the package check on Windows and Linux; local success is
not a substitute for those hosted results.

The first attempt at the interactive-decline check piped answers to many newly created readline
sessions and did not reach the summary. The check was corrected to model one existing prompt
and one reply. Multi-prompt piped interaction remains outside this check; the installer already
used separate readline sessions before this change.

These results establish package and installer behavior. They do not establish successful
end-to-end workflow execution, a native-skill migration, or superiority over another agent.
