---
description: Manage product roadmap via GitHub Issues (brainstorm, prioritize, track). Auto-validates features against project vision (from overview.md) before adding to roadmap.
allowed-tools: [Read, Bash(.spec-flow/scripts/bash/github-roadmap-manager.sh:*), Bash(.spec-flow/scripts/powershell/github-roadmap-manager.ps1:*), Bash(gh issue:*), Bash(gh api:*), Bash(gh label:*), Bash(gh milestone:*), Bash(git remote:*), Bash(test:*), Bash(ls:*), Bash(jq:*), WebSearch, AskUserQuestion]
argument-hint: [add|brainstorm|move|delete|search|list|milestone|epic] [additional args]
---

<context>
GitHub authentication: !`gh auth status >/dev/null 2>&1 && echo "✅ Authenticated" || echo "❌ Not authenticated"`

Repository: !`gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "Not a GitHub repo"`

Project docs exist: !`test -f docs/project/overview.md && echo "✅ Found" || echo "❌ Missing"`

Roadmap issue count: !`gh issue list --label status:backlog,status:next,status:in-progress --json number --jq 'length' 2>/dev/null || echo "0"`

Open issues by status: !`gh issue list --json labels --jq '[.[] | .labels[] | select(.name | startswith("status:")) | .name] | group_by(.) | map({(.[0]): length}) | add' 2>/dev/null || echo "{}"`
</context>

<objective>
Manage product roadmap via GitHub Issues with vision alignment validation.

**Actions supported:**
- **add** — Add new feature with vision validation
- **brainstorm** — Generate feature ideas via web research
- **move** — Change feature status (Backlog → Next → In Progress → Shipped)
- **delete** — Remove feature from roadmap
- **search** — Find features by keyword/area/role
- **list** — Show roadmap summary
- **milestone** — Manage milestones (list, create, plan)
- **epic** — Manage epic labels (list, create)

**Workflow integration**: /roadmap → /feature → spec → plan → implement → ship

**Dependencies:**
- GitHub authentication (gh CLI or GITHUB_TOKEN)
- Git repository with remote
- Optional: docs/project/overview.md for vision validation
</objective>

<process>
1. **Verify GitHub authentication** from context:
   - If "❌ Not authenticated": Display authentication instructions and exit
   - If "✅ Authenticated": Proceed with action

2. **Parse user intent** from $ARGUMENTS to determine action type:
   - Extract action: add, brainstorm, move, delete, search, list, milestone, epic
   - Extract parameters based on action (feature name, slug, target status, etc.)

3. **Execute platform-specific script**:

   **Windows (PowerShell):**
   ```powershell
   . .\.spec-flow\scripts\powershell\github-roadmap-manager.ps1

   # Execute action-specific function
   # Examples:
   # - New-RoadmapIssue for "add"
   # - Search-Roadmap for "search"
   # - Move-IssueToSection for "move"
   # - Show-RoadmapSummary for "list"
   ```

   **macOS/Linux (Bash):**
   ```bash
   source .spec-flow/scripts/bash/github-roadmap-manager.sh

   # Execute action-specific function
   # Examples:
   # - create_roadmap_issue for "add"
   # - search_roadmap for "search"
   # - move_issue_to_section for "move"
   # - show_roadmap_summary for "list"
   ```

4. **For ADD/BRAINSTORM actions only** — Perform vision alignment validation:

   If docs/project/overview.md exists:
   a. Read overview.md and extract:
      - Vision (1 paragraph)
      - Out-of-Scope exclusions (bullet list)
      - Target Users (bullet list)

   b. For each proposed feature:
      - Check if feature is in Out-of-Scope list
        → If YES: Use AskUserQuestion (Skip / Update overview / Override)

      - Check if feature supports Vision
        → If NO: Use AskUserQuestion (Add anyway / Revise / Skip)

      - Confirm primary target user
        → Store as role label

   c. Only create GitHub Issue after validation passes or user overrides
      - If override: Add alignment_note to issue frontmatter

   If overview.md missing:
   - Display warning: "Run /init-project for vision-aligned roadmap"
   - Skip validation, create issue in Backlog

5. **For MOVE action** — Enforce state machine rules:
   - If moving to status:in-progress AND no milestone assigned:
     → Script prompts to assign milestone (REQUIRED)

   - If moving to status:shipped:
     → Script closes issue and adds status:shipped label

6. **For MILESTONE/EPIC actions** — Manage labels and groupings:
   - milestone list: Display all milestones with due dates
   - milestone create: Create new milestone
   - milestone plan: Interactively assign backlog issues
   - epic list: Display all epic:* labels
   - epic create: Create new epic label (purple, auto-namespaced)

7. **Present results** to user:
   - Show created/updated issue with metadata
   - Display roadmap summary (count by status)
   - Suggest next action based on context
</process>

<verification>
Before completing, verify:
- GitHub authentication confirmed
- Action executed via platform-specific script
- Vision validation performed for ADD/BRAINSTORM (if overview.md exists)
- State machine rules enforced for MOVE (milestone requirement, issue closing)
- Roadmap summary displayed to user
- Next-step suggestions provided
</verification>

<success_criteria>
**Issue creation (ADD/BRAINSTORM):**
- GitHub Issue created with metadata frontmatter
- Labels applied: area:*, role:*, type:*, status:backlog
- Vision alignment validated (if overview.md exists) or warning shown
- Issue includes Problem, Proposed Solution, Requirements sections

**State transitions (MOVE):**
- Exactly one status:* label on issue (old removed, new added)
- Milestone enforced for status:in-progress transitions
- Issue closed for status:shipped transitions
- Label invariants maintained

**Roadmap summary (ALL actions):**
- Current state displayed: Backlog, Next, In Progress, Shipped counts
- Top 3 in Backlog shown (sorted by creation order)
- Next action suggested based on roadmap state

**Vision validation:**
- Out-of-scope features flagged before creation
- Vision misalignment detected and user prompted
- Alignment overrides documented in alignment_note
</success_criteria>

<standards>
**Industry Standards:**
- **GitHub Labels**: [Namespaced label conventions](https://medium.com/@dave_lunny/github-issue-label-conventions-8a7e5d2d1a1e)
- **State Machines**: [Finite State Machines for Workflow](https://en.wikipedia.org/wiki/Finite-state_machine)

**Workflow Standards:**
- GitHub Issues as single source of truth
- Creation order = priority (oldest first)
- Label invariants enforced by scripts
- Milestone requirement for in-progress work
- Vision alignment for all new features
</standards>

<notes>
**Script locations:**
- Bash: `.spec-flow/scripts/bash/github-roadmap-manager.sh`
- PowerShell: `.spec-flow/scripts/powershell/github-roadmap-manager.ps1`

**Reference documentation:** State machine diagrams, label system details, vision validation workflow, milestone/epic/sprint management, script function catalog, and all detailed procedures are in `.claude/skills/roadmap-integration/references/reference.md`.

**Version:** v2.0 (2025-11-17) — Refactored to XML structure, added dynamic context, tool restrictions

**Workflow integration:**
```
/roadmap add → creates issue in Backlog
/feature next → claims oldest "Next" issue
/feature [slug] → claims specific issue
/ship → marks issue as Shipped
```
</notes>
