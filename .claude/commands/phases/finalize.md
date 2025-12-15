---
description: Finalize documentation (CHANGELOG, README, help docs), update GitHub milestones/releases, and cleanup branches after production deployment
allowed-tools: [Read, Bash, Task]
internal: true
version: 11.0
updated: 2025-12-09
---

# /finalize — Post-Deployment Finalization (Thin Wrapper)

> **v11.0 Architecture**: This command spawns the isolated `finalize-phase-agent` via Task(). Documentation and archival runs in isolated context.

<context>
**Active Feature**: !`ls -td specs/[0-9]*-* 2>/dev/null | head -1 || echo "none"`

**Interaction State**: !`cat specs/*/interaction-state.yaml 2>/dev/null | head -10 || echo "none"`
</context>

<objective>
Spawn isolated finalize-phase-agent to complete post-deployment documentation and archival.

**Architecture (v11.0 - Phase Isolation):**
```
/finalize → Task(finalize-phase-agent) → CHANGELOG, walkthrough, archive
```

**Agent responsibilities:**
- Generate CHANGELOG.md entry
- Update README.md if user-facing changes
- Create walkthrough.md (comprehensive for epics)
- Create GitHub release
- Archive feature to completed/
- Clean up feature branch

**Execution model**:
- **Idempotent**: Safe to re-run; completed tasks are skipped
- **Deterministic**: No prompts, no editors
- **Tracked**: Every step logged with clear progress indicators

**Workflow position**: `implement → optimize → validate → ship → finalize`
</objective>

## Legacy Context (for agent reference)

<legacy_context>
Current workflow state: !`cat specs/*/state.yaml 2>/dev/null | grep -E '(feature\.|deployment\.production\.|version:)' | head -20`

Recent production deployment: !`yq -r '.deployment.production | "URL: \(.url // "N/A"), Date: \(.completed_at // "N/A"), Status: \(.status // "unknown")"' specs/*/state.yaml 2>/dev/null`

Required tools check: !`for c in gh jq yq git python; do command -v "$c" >/dev/null 2>&1 && echo "✅ $c" || echo "❌ $c"; done`
</legacy_context>

<process>
1. **Check prerequisites** - Verify gh, jq, yq, git, python are installed and gh is authenticated

2. **Execute finalization workflow** via spec-cli.py:

   ```bash
   python .spec-flow/scripts/spec-cli.py finalize
   ```

   The finalize-workflow.sh script performs:

   a. **Epic workflows only** (v5.0+):

   - Generate walkthrough.md with velocity metrics
   - Calculate sprint results and lessons learned
   - Run pattern detection across completed epics (if 2+ completed)
   - **Auto-offer workflow healing** (v10.14+):
     - Check `.spec-flow/analytics/patterns.json` for recommendations
     - If `avg_blockers > 3` or `avg_duration > 14 days`, prompt user:

     ```
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     Pattern Analysis Suggests Improvements
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

     Detected patterns across {N} completed epics:
     - Average blockers per epic: {avg_blockers}
     - Average duration: {avg_duration} days
     - Common blocker themes: {themes}

     Recommendations:
     {recommendations from patterns.json}
     ```

     Use AskUserQuestion:
     - Question: "Apply workflow improvements?"
     - Header: "Healing"
     - Options:
       - "Yes" - Run `/heal-workflow` to create improvement issues
       - "No" - Skip healing, continue finalization

     **If user selects "Yes"**:
     - Invoke `/heal-workflow` via SlashCommand tool
     - Continue to standard finalization after healing completes

   b. **Standard finalization** (all workflows):

   - Update CHANGELOG.md (Keep a Changelog format)
   - Update README.md (Shields.io version badge + features)
   - Generate help article at docs/help/features/{slug}.md
   - Update API docs (conditional if endpoints changed)
   - Close current milestone, create next milestone
   - Update roadmap issue to "shipped" status
   - Update GitHub Release with production deployment info
   - Commit and push documentation changes
   - Cleanup feature branch (safe delete if merged)
   - **Archive workflow artifacts** (v9.3+):
     - Move all planning artifacts to {workspace}/completed/
     - Epic: epic-spec.md, plan.md, sprint-plan.md, tasks.md, NOTES.md, research.md, walkthrough.md
     - Feature: spec.md, plan.md, tasks.md, NOTES.md
     - state.yaml remains in root (for metrics/history)

   - **Cleanup worktree** (v11.8 - if worktrees.cleanup_on_finalize is true):
     - Check if current feature/epic has a worktree
     - If cleanup_on_finalize is enabled (default: true):
       ```bash
       CLEANUP_ENABLED=$(bash .spec-flow/scripts/utils/load-preferences.sh --key "worktrees.cleanup_on_finalize" --default "true" 2>/dev/null || echo "true")
       if [ "$CLEANUP_ENABLED" = "true" ]; then
         WORKFLOW_TYPE=$(yq eval '.workflow_type // "feature"' "$WORKSPACE_DIR/state.yaml" 2>/dev/null)
         SLUG=$(basename "$WORKSPACE_DIR")
         WORKTREE_PATH=$(bash .spec-flow/scripts/bash/worktree-context.sh get-worktree "$WORKFLOW_TYPE" "$SLUG" 2>/dev/null)

         if [ -n "$WORKTREE_PATH" ] && [ -d "$WORKTREE_PATH" ]; then
           echo "Cleaning up worktree: $WORKTREE_PATH"
           bash .spec-flow/scripts/bash/worktree-manager.sh remove "$SLUG" --force
         fi
       fi
       ```
     - Output: "Worktree cleaned up. Returning to root repository."

3. **Review summary output** - Verify all tasks completed successfully

4. **Next steps** (displayed in output):
   - Review documentation accuracy
   - Announce release (social media, blog, email)
   - Monitor user feedback and error logs
   - Plan next feature from roadmap

5. **Offer next feature (Studio Mode)** - Auto-continue workflow loop:

   After successful finalization, check if more work is available:

   ```bash
   # Count remaining roadmap items
   NEXT_COUNT=$(gh issue list --label "status:next,type:feature" --json number --jq 'length' 2>/dev/null || echo "0")
   BACKLOG_COUNT=$(gh issue list --label "status:backlog,type:feature" --json number --jq 'length' 2>/dev/null || echo "0")
   TOTAL_REMAINING=$((NEXT_COUNT + BACKLOG_COUNT))
   ```

   **If roadmap is empty** (TOTAL_REMAINING = 0):
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Roadmap Complete!
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   No more issues with status:next or status:backlog.
   All planned work has been completed!

   To add more work: /roadmap add "feature description"
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```
   Exit normally.

   **If roadmap has work** (TOTAL_REMAINING > 0):

   Display summary and prompt:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Feature Finalized Successfully!
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Remaining roadmap items:
     Next:    {NEXT_COUNT} issues
     Backlog: {BACKLOG_COUNT} issues
   ```

   Use AskUserQuestion:
   - Question: "Pick up next issue from roadmap?"
   - Header: "Continue"
   - Options:
     - "Yes" - Claim and start the next priority issue
     - "No" - Stop here, return to idle

   **If user selects "Yes"**:
   - Invoke `/feature next` via SlashCommand tool
   - This creates the continuous work loop for Dev Studio

   **If user selects "No"**:
   - Display: "Agent returning to idle. Run `/feature next` when ready."
   - Exit normally
     </process>

<verification>
Before completing, verify:
- All required tools (gh, jq, yq, git, python) are available
- GitHub CLI is authenticated (`gh auth status`)
- CHANGELOG.md has new version section with date
- README.md version badge matches deployed version
- Help documentation exists at docs/help/features/{slug}.md
- GitHub Release contains production deployment section (if release exists)
- Documentation changes committed and pushed to main
- Feature branch deleted if fully merged (or noted as unmerged)
- **Workflow artifacts archived** (v9.3+):
  * All planning artifacts moved to {workspace}/completed/
  * state.yaml remains in root directory
  * Completed directory contains expected files based on workflow type
- **Auto-continue prompt** (v10.12+):
  * Roadmap status checked for remaining work
  * User prompted if work available
  * Next feature started if user confirms (or roadmap exhausted)
- **Worktree cleanup** (v11.8+):
  * If worktrees.cleanup_on_finalize is true, worktree removed
  * User returned to root repository for next work
</verification>

<success_criteria>

- All documentation files updated and committed
- GitHub Release contains production deployment section (if exists)
- Roadmap issue marked as "shipped" (if exists)
- Current milestone closed, next milestone created
- Feature branch deleted if fully merged
- **Workflow artifacts archived to {workspace}/completed/** (v9.3+)
- Finalization script exits with status 0
- No bash commands executed beyond allowed tools
- Idempotent: Safe to re-run if interrupted
  </success_criteria>

<standards>
**Industry Standards**:
- **CHANGELOG**: [Keep a Changelog](https://keepachangelog.com/) - Categorize changes as Added/Fixed/Changed/Security
- **Versioning**: [Semantic Versioning](https://semver.org/) - MAJOR.MINOR.PATCH format
- **Badges**: [Shields.io](https://shields.io/) - Static version badges
- **GitHub**: [GitHub CLI Manual](https://cli.github.com/manual/) and [REST API](https://docs.github.com/en/rest)

**Workflow Standards**:

- No prompts or interactive editors (vi, nano)
- All operations are deterministic and scriptable
- Safe for CI/CD execution
- Graceful degradation for optional operations (milestones, roadmap)
  </standards>

<error_recovery>
**Idempotency**: Re-running `/finalize` is safe. The finalize-workflow.sh script checks for existing state before modifying files.

**Common errors and fixes**:

1. **Git push fails**

   - Cause: Need to pull changes first
   - Fix: `git pull --rebase && /finalize`

2. **GitHub CLI not authenticated**

   - Cause: Missing gh credentials
   - Fix: `gh auth login` then retry `/finalize`

3. **Missing required tool**

   - Cause: gh, jq, yq, or git not installed
   - Fix: Install missing tool (see prerequisites output), then retry

4. **Branch cleanup fails**
   - Cause: Branch has unmerged commits
   - Note: Script uses safe delete (`-d`), never force delete (`-D`)
   - Result: Branch preserved, manual review required

**GitHub API safety**:

- All `gh` commands use `|| true` to avoid blocking workflow
- Optional steps (milestones, roadmap) log warnings but don't fail finalization
- Rate limiting handled gracefully with warnings

**Resume capability**:
If finalization is interrupted, simply re-run `/finalize`. The script will skip already-completed tasks.
</error_recovery>

<epic_walkthrough>
**Epic workflows only** (v5.0+):

When /finalize detects an epic workflow (presence of `epics/*/epic-spec.md`), it generates a comprehensive walkthrough before standard finalization.

**Walkthrough generation**:

1. Load all epic artifacts (epic-spec.md, research.md, plan.md, sprint-plan.md, state.yaml, audit-report.xml)
2. Calculate velocity metrics (expected vs actual multiplier, time saved)
3. Extract sprint results (tasks completed, duration, tests passed)
4. Generate walkthrough.md using .spec-flow/templates/walkthrough.md
5. Run post-mortem audit for final analysis
6. Detect patterns if 2-3+ epics completed
7. Offer workflow healing via /heal-workflow

**Walkthrough includes**:

- Epic goal and success metrics
- Velocity metrics (expected vs actual)
- Sprint execution results
- Validation results (optimization, preview)
- Key files modified
- Next steps (enhancements, technical debt, monitoring)
- Lessons learned (what worked, what struggled)

**Pattern detection** (after 2-3 epics):
Analyzes patterns across completed epics and suggests:

- Estimation multiplier adjustments
- API contract locking strategies
- Design system Phase 0.5 opportunities
- Sprint sizing heuristic improvements
- Custom tooling generation via /create-custom-tooling

See finalize-workflow.sh:59-408 for full walkthrough generation logic.
</epic_walkthrough>

<notes>
**Version compatibility**: This command works with both feature and epic workflows. Epic-specific features (walkthrough, pattern detection) only activate for epic workflows.

**Milestone naming**: Assumes milestones are named `vX.Y.x` (e.g., `v1.2.x`). Adjust regex in finalize-workflow.sh:611 if using different naming.

**Date format**: Uses ISO-8601 (`YYYY-MM-DD`) for CHANGELOG dates per Keep a Changelog standard.

**Artifact linking**: Production deployment logs can be viewed via:

```bash
gh run view $(yq -r '.deployment.production.run_id' specs/*/state.yaml) --log
```

**Workflow dispatch**: For automated releases via GitHub Actions, ensure target workflow declares `on: workflow_dispatch`. Use `gh workflow run` and `gh run watch` to dispatch and monitor.

**Script location**: The bash implementation is at `.spec-flow/scripts/bash/finalize-workflow.sh`. It is invoked via spec-cli.py for cross-platform compatibility.

**Auto-continue (v10.12+)**: After finalization, the command checks for remaining roadmap items and prompts "Pick up next issue?". This enables the Dev Studio workflow where agents continuously process features until the roadmap is empty. Use `/studio init N` to set up parallel agent worktrees.
</notes>
