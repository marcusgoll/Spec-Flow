---
description: Manage product roadmap via GitHub Issues (brainstorm, prioritize, track). Auto-validates features against project vision (from overview.md) before adding to roadmap.
allowed-tools: [Read, Bash(.spec-flow/scripts/bash/github-roadmap-manager.sh:*), Bash(.spec-flow/scripts/powershell/github-roadmap-manager.ps1:*), Bash(gh issue:*), Bash(gh api:*), Bash(gh label:*), Bash(gh milestone:*), Bash(git remote:*), Bash(test:*), Bash(ls:*), Bash(jq:*), WebSearch, AskUserQuestion, Task]
argument-hint: "[add|brainstorm|from-ultrathink|move|delete|search|list|milestone|epic] [additional args]"
version: 11.0
updated: 2025-12-09
---

<context>
GitHub authentication: !`gh auth status >/dev/null 2>&1 && echo "✅ Authenticated" || echo "❌ Not authenticated"`

Repository: !`gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "Not a GitHub repo"`

Project docs exist: !`test -f docs/project/overview.md && echo "✅ Found" || echo "❌ Missing"`

Roadmap issue count: !`gh issue list --label status:backlog,status:next,status:in-progress --json number --jq 'length' 2>/dev/null || echo "0"`

Open issues by status: !`gh issue list --json labels --jq '[.[] | .labels[] | select(.name | startswith("status:")) | .name] | group_by(.) | map({(.[0]): length}) | add' 2>/dev/null || echo "{}"`
</context>

<architecture>
## Hybrid Pattern (v11.0)

**For `brainstorm` action (heavy web research):**

```
User: /roadmap brainstorm "user onboarding"
         │
         ▼
┌──────────────────────────────────────────────────────┐
│ MAIN CONTEXT (context gathering - lightweight)       │
│                                                      │
│ 1. Verify GitHub authentication                      │
│ 2. Load project vision from overview.md              │
│ 3. Get existing roadmap items (avoid duplicates)     │
│ 4. Save context to temp config                       │
│    → .spec-flow/temp/brainstorm-context.yaml         │
└──────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────┐
│ Task(roadmap-brainstorm-agent) ← ISOLATED            │
│                                                      │
│ 1. Read context from temp config                     │
│ 2. Web search for similar products                   │
│ 3. Research best practices                           │
│ 4. Generate feature ideas (up to 15)                 │
│ 5. Validate against project vision                   │
│ 6. Deduplicate against existing features             │
│ 7. Return ranked list of ideas                       │
│ 8. EXIT                                              │
└──────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────┐
│ MAIN CONTEXT (user selection - interactive)          │
│                                                      │
│ 1. Display generated ideas with alignment status     │
│ 2. AskUserQuestion: which ideas to add to roadmap?   │
│ 3. Create GitHub Issues for selected ideas           │
│ 4. Display roadmap summary                           │
└──────────────────────────────────────────────────────┘
```

**For lightweight actions (`add`, `move`, `delete`, `list`, etc.):**
- Run directly in main context (no Task spawning needed)
- These are simple GitHub CLI operations
</architecture>

<objective>
Manage product roadmap via GitHub Issues with vision alignment validation.

**Actions supported:**
- **add** — Add new feature with vision validation
- **brainstorm** — Generate feature ideas via web research
- **from-ultrathink** — Materialize features from ultrathink session (v2.0)
- **move** — Change feature status (Backlog → Next → In Progress → Shipped)
- **delete** — Remove feature from roadmap
- **search** — Find features by keyword/area/role
- **list** — Show roadmap summary
- **milestone** — Manage milestones (list, create, plan)
- **epic** — Manage epic labels (list, create)

**Workflow integration**:
```
/init-project → /roadmap add|brainstorm → /feature or /epic
```

**Dependencies:**
- GitHub authentication (gh CLI or GITHUB_TOKEN)
- Git repository with remote
- Optional: docs/project/overview.md for vision validation
</objective>

<process>
1. **Verify GitHub authentication** from context:
   - If "❌ Not authenticated": Display authentication instructions and exit
   - If "✅ Authenticated": Proceed with action

2. **Parse user intent** from $ARGUMENTS and route to action:

   **Action routing:**
   ```
   If $ARGUMENTS starts with "add "            → ADD action (remaining = feature description)
   If $ARGUMENTS starts with "brainstorm "     → BRAINSTORM action (remaining = topic)
   If $ARGUMENTS starts with "from-ultrathink" → FROM-ULTRATHINK action (remaining = path or --list)
   If $ARGUMENTS starts with "move "           → MOVE action (parse: slug, target status)
   If $ARGUMENTS starts with "delete "         → DELETE action (remaining = slug)
   If $ARGUMENTS starts with "search "         → SEARCH action (remaining = query)
   If $ARGUMENTS equals "list"                 → LIST action (no params)
   If $ARGUMENTS starts with "milestone "      → MILESTONE sub-actions:
      - "milestone list"                       → list all milestones
      - "milestone create <name> [date]"       → create milestone
      - "milestone plan <name>"                → interactive assignment
   If $ARGUMENTS starts with "epic "           → EPIC sub-actions:
      - "epic list"                            → list all epic labels
      - "epic create <name> [description]"     → create epic label
   ```

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

4. **For BRAINSTORM action — Spawn Research Agent (v11.0 Hybrid)**:

   **Step 4a: Gather context for agent:**
   ```javascript
   // Get existing roadmap items to avoid duplicates
   const existingFeatures = await exec(
     `gh issue list --label status:backlog,status:next --json number,title,labels --jq '.[] | {slug: .number, title: .title}'`
   );

   // Save context for agent
   const context = {
     created: new Date().toISOString(),
     topic: parsedTopic,  // from $ARGUMENTS
     overview_path: "docs/project/overview.md",
     existing_features: existingFeatures
   };
   await writeYaml(".spec-flow/temp/brainstorm-context.yaml", context);
   ```

   **Step 4b: Spawn isolated brainstorm agent:**
   ```javascript
   const agentResult = await Task({
     subagent_type: "roadmap-brainstorm-agent",
     prompt: `
       Research and generate feature ideas for: "${parsedTopic}"

       Context file: .spec-flow/temp/brainstorm-context.yaml

       Read project context, perform web research, generate feature ideas,
       validate against vision, and return ranked list of ideas.
     `
   });

   const result = agentResult.phase_result;
   ```

   **Step 4c: Present ideas for user selection:**
   ```javascript
   if (result.status === "completed" && result.ideas.length > 0) {
     // Display ideas grouped by alignment status
     console.log(`\n🧠 Brainstorm Results: ${result.ideas.length} ideas generated`);

     // Group and display
     const inScope = result.ideas.filter(i => i.alignment.status === "in_scope");
     const ambiguous = result.ideas.filter(i => i.alignment.status === "ambiguous");
     const outOfScope = result.ideas.filter(i => i.alignment.status === "out_of_scope");

     // Use AskUserQuestion for selection
     const selectedIdeas = await AskUserQuestion({
       question: "Which ideas should we add to the roadmap?",
       header: "Select Ideas",
       multiSelect: true,
       options: inScope.concat(ambiguous).map(idea => ({
         label: idea.name,
         description: `${idea.complexity} • ${idea.priority_hint} priority • ${idea.alignment.reason}`
       }))
     });

     // Create GitHub Issues for selected ideas
     for (const idea of selectedIdeas) {
       await exec(`gh issue create --title "${idea.name}" --body "..." --label "status:backlog"`);
     }
   }
   ```

   **If agent returns warnings:**
   - Display warnings to user
   - Suggest alternative approaches if no ideas found

4b. **For FROM-ULTRATHINK action (v2.0)** — Materialize features from ultrathink session:

   **If `--list` flag:**
   ```bash
   # List available ultrathink sessions
   echo "📚 Available Ultrathink Sessions:"
   for file in specs/ultrathink/*.yaml; do
     if [ -f "$file" ]; then
       topic=$(yq eval '.metadata.topic' "$file")
       created=$(yq eval '.metadata.created' "$file")
       count=$(yq eval '.extracted_features | length' "$file")
       materialized=$(yq eval '.roadmap_status.materialized' "$file")
       echo "  • $(basename $file .yaml): $topic ($count features, materialized: $materialized)"
     fi
   done
   ```

   **If path provided:**
   ```bash
   ULTRATHINK_FILE="$REMAINING_ARGS"
   if [ ! -f "$ULTRATHINK_FILE" ]; then
     echo "❌ File not found: $ULTRATHINK_FILE"
     echo "💡 Use: /roadmap from-ultrathink --list to see available sessions"
     exit 1
   fi
   ```

   **Extract features from ultrathink output:**
   ```javascript
   const ultrathinkData = await readYaml(ultrathinkFile);
   const features = ultrathinkData.extracted_features || [];

   if (features.length === 0) {
     console.log("⚠️ No extracted features found in this ultrathink session");
     console.log("💡 Run /ultrathink again and ensure features are extracted");
     return;
   }

   // Display features from the thinking session
   console.log(`\n🧠 Features from: ${ultrathinkData.metadata.topic}`);
   console.log(`   Session: ${ultrathinkData.metadata.created}\n`);

   for (const feature of features) {
     const icon = feature.type === 'epic' ? '📦' : '⚡';
     console.log(`${icon} ${feature.type}: ${feature.name}`);
     console.log(`   ${feature.description}`);
     console.log(`   Priority: ${feature.priority} • ${feature.complexity_rationale}`);
     console.log();
   }
   ```

   **Prompt user for selection:**
   ```javascript
   const selection = await AskUserQuestion({
     question: "Which features should be added to the roadmap?",
     header: "Select Features",
     multiSelect: true,
     options: features.map(f => ({
       label: `${f.type === 'epic' ? '📦' : '⚡'} ${f.name}`,
       description: `${f.priority} priority • ${f.description}`
     }))
   });
   ```

   **Create GitHub Issues for selected features:**
   ```bash
   for feature in selected_features; do
     # Create issue with traceability back to ultrathink session
     gh issue create \
       --title "${feature.type}: ${feature.name}" \
       --body "$(cat <<EOF
   ## Origin

   This ${feature.type} emerged from ultrathink session:
   \`${ULTRATHINK_FILE}\`

   **Topic**: ${ultrathinkData.metadata.topic}
   **Session Date**: ${ultrathinkData.metadata.created}

   ## Description

   ${feature.description}

   ## Complexity Rationale

   ${feature.complexity_rationale}

   ## From the Vision

   > ${feature.from_vision}

   ## Dependencies

   ${feature.dependencies.length > 0 ? feature.dependencies.join(', ') : 'None'}

   ---
   *Generated by /roadmap from-ultrathink on $(date -Idate)*
   EOF
   )" \
       --label "status:backlog" \
       --label "type:${feature.type}" \
       --label "priority:${feature.priority}"

     echo "✅ Created #$ISSUE_NUMBER: ${feature.name}"
   done
   ```

   **Update ultrathink file with materialization status:**
   ```bash
   yq eval '.roadmap_status.materialized = true' -i "$ULTRATHINK_FILE"
   yq eval '.roadmap_status.issues_created = ['"$CREATED_ISSUES"']' -i "$ULTRATHINK_FILE"
   yq eval '.roadmap_status.materialized_at = "'"$(date -Iseconds)"'"' -i "$ULTRATHINK_FILE"
   ```

   **Display summary:**
   ```
   ✅ Materialized ultrathink session to roadmap:

   Source: specs/ultrathink/notification-system-redesign.yaml
   Features created: 3

   #42 📦 Epic: Notification Service
   #43 ⚡ Feature: Push Notification API
   #44 ⚡ Feature: Notification Preferences

   Next: /feature #43 or /epic #42 to start implementing
   ```

5. **For ADD action only** — Perform vision alignment validation:

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

6. **For MOVE action** — Enforce state machine rules:
   - If moving to status:in-progress AND no milestone assigned:
     → Script prompts to assign milestone (REQUIRED)

   - If moving to status:shipped:
     → Script closes issue and adds status:shipped label

7. **For MILESTONE/EPIC actions** — Manage labels and groupings:
   - milestone list: Display all milestones with due dates
   - milestone create: Create new milestone
   - milestone plan: Interactively assign backlog issues
   - epic list: Display all epic:* labels
   - epic create: Create new epic label (purple, auto-namespaced)

8. **Present results** to user:
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
