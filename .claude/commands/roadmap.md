---
description: Manage product roadmap with interactive setup wizard for first-time users
---

Manage the Spec-Flow roadmap: $ARGUMENTS

## MODE DETECTION

**If roadmap is empty or only has template placeholders:**
- Launch interactive Q&A wizard (see INTERACTIVE SETUP below)

**If $ARGUMENTS provided:**
- Execute action: $ARGUMENTS (see ACTIONS below)

**If roadmap has features:**
- Continue to action parsing

---

## INTERACTIVE SETUP

**Purpose**: First-time roadmap setup - guide users through adding initial features.

**Workflow**:

1. **Welcome message**:
   ```
   Let's build your product roadmap!

   I'll help you add your first few features and prioritize them using ICE scoring:
   - Impact (1-5): How much value does this bring to users?
   - Effort (1-5): How complex is the implementation?
   - Confidence (0-1): How certain are you about the estimates?
   - ICE Score: (Impact × Confidence) ÷ Effort
   ```

2. **Add first feature**:
   - "What's the first feature you want to build?"
   - Extract title from user response
   - "What area is this? (marketing|app|api|infra|design|other)"
   - "Who is this for? (free|student|cfi|school|all)"

3. **ICE scoring (interactive)**:
   - "Impact (1-5): How much value for users?"
     - 1 = Nice to have
     - 3 = Important improvement
     - 5 = Game changer
   - "Effort (1-5): How complex to build?"
     - 1 = Few hours
     - 2 = 1-2 days
     - 3 = 3-5 days
     - 4 = 1-2 weeks
     - 5 = 2+ weeks
   - "Confidence (0-1): How certain are these estimates?"
     - 0.5 = Wild guess
     - 0.7 = Rough estimate
     - 0.9 = Very confident
     - 1.0 = Certain

4. **Requirements gathering**:
   - "What are the key requirements? (bullet points)"
   - Auto-detect missing info and add `[CLARIFY: question]` tags

5. **Show calculated score**:
   ```
   ✓ Feature added: [slug]
   - Impact: N | Effort: N | Confidence: N
   - ICE Score: N.NN

   Higher scores = higher priority
   ```

6. **Add more features** (repeat 2-4 times):
   - "Add another feature? (Y/n)"
   - If yes, repeat steps 2-5
   - If no, continue to summary

7. **Auto-prioritize and show summary**:
   - Sort all features by ICE score
   - Show top 3 with scores
   - Guide next steps: `/spec-flow [top-slug]` to start building

---

## MENTAL MODEL

**Workflow**: roadmap -> spec-flow -> clarify -> plan -> tasks -> implement -> optimize -> ship

**State machine:**
- Parse intent -> Execute action -> Auto-sort -> Return summary

**Auto-actions:**
- Add/update -> Auto-sort by ICE score
- Clarifications found -> Offer manual/recommend/skip
- Brainstorm -> Generate ideas -> Offer to add

## INITIALIZE

Check if roadmap exists, create from template if missing:
```bash
if [ ! -f ".spec-flow/memory/roadmap.md" ]; then
  mkdir -p .spec-flow/memory
  cp .spec-flow/templates/roadmap-template.md .spec-flow/memory/roadmap.md
fi
```

## CONTEXT

**Location**: `.spec-flow/memory/roadmap.md`
**Format**: Markdown sections (Shipped, In Progress, Next, Later, Backlog)

**Item structure:**
- **Slug**: URL-friendly identifier
- **Title**: Human-readable name
- **Area**: marketing|app|api|infra|design
- **Role**: free|student|cfi|school|all
- **Impact**: 1-5 (user value)
- **Effort**: 1-5 (implementation complexity)
- **Confidence**: 0-1 (estimate certainty)
- **Score**: ICE = (Impact × Confidence) / Effort
- **Requirements**: Bullets or `[CLARIFY: ...]`

## ACTIONS

### 1. ADD FEATURE

**Parse natural language:**
- Extract: title, area, role, requirements
- Infer: Impact (1-5), Effort (1-5), Confidence (0-1)
- Generate: URL-friendly slug
- Calculate: ICE score

**Deduplicate:**
- Fuzzy match roadmap titles (~70% similarity)
- Check `specs/*-slug/` directory exists
- If duplicate: Ask "Merge with existing [slug]?"

**Add to Backlog:**
- Append feature with full metadata
- Add `[CLARIFY: question]` for unknowns
- **Auto-sort Backlog by ICE score (descending)**
- Update timestamp

**Auto-clarification (if `[CLARIFY]` found):**
Present 3 options:
```
✓ Found N clarifications needed:
1. [First question]
2. [Second question]
...

How to proceed?
A) Manual - Answer questions interactively
B) Recommend - Claude generates answers using Spec-Flow context
C) Skip - Add as-is, clarify later

[Recommend B for faster workflow]
```

**If "Manual"**: Interactive Q&A like `/clarify`
**If "Recommend"**:
- Use CLAUDE.md, constitution, similar features
- Generate answers with rationale
- Update requirements
- Re-sort

**If "Skip"**: Continue to summary

### 2. BRAINSTORM (research → plan → present)

**Trigger**: `/roadmap brainstorm [area|role|topic]`

**Phase 1: RESEARCH (8-12 tool calls)**

**Step 1 - Spec-Flow Context:**
- Read `.spec-flow/memory/constitution.md` (mission: AKTRACS extraction for aviation education)
- Read `.spec-flow/memory/roadmap.md` (existing features, identify gaps)
- Glob `specs/*/spec.md` (patterns, user flows, reusable infra)

**Step 2 - Industry Research:**
- WebSearch: "aviation education platform features 2025"
- WebSearch: "flight instructor tools student tracking"
- WebSearch: "edtech personalization study plans"
- WebSearch: "[user-Specified topic]" (if args provided)

**Step 3 - Gap Analysis:**
- Compare Spec-Flow vs industry leaders (Foreflight, Sporty's, etc.)
- Identify role gaps: free, student, CFI, school
- Find piggybacking opportunities (leverage existing features)

**Phase 2: PLAN (categorize & group)**

**Step 1 - Generate 8-10 Ideas:**
- **Extension** (piggyback existing): Build on current features
- **Gap-fill** (address missing): Solve unmet user needs
- **Innovation** (differentiation): New value propositions

**Step 2 - Group by Strategy:**
- **Quick Wins** (Impact 3-4, Effort 1-2): Ship in 1-2 weeks
- **Strategic** (Impact 4-5, Effort 3-4): Long-term competitive advantage
- **Experimental** (Impact 2-3, Effort 1-2): Test hypotheses

**Step 3 - Identify Dependencies:**
- Tag piggybacking: `[PIGGYBACK: feature-slug]`
- Tag blockers: `[BLOCKED: missing-infra]`

**Phase 3: PRESENT (interactive selection)**

```
✓ Research Summary:
- Analyzed: N existing features, M industry trends
- Found: X gaps, Y piggybacking opportunities

✓ Brainstormed Ideas (sorted by category):

**Quick Wins** (ship in 1-2 weeks):
1. student-progress-widget (Score: 1.5) [PIGGYBACK: aktr-results-core]
   Impact: 3 | Effort: 2 | Confidence: 1.0
   "Show mastery % on results page. Uses existing ACS data."
   Source: WebSearch - "edtech student dashboards 2025"

2. cfi-batch-csv-export (Score: 1.4) [PIGGYBACK: csv-export]
   Impact: 4 | Effort: 3 | Confidence: 0.9
   "Export all students in cohort. Reuses export modal."
   Source: Gap analysis - CFIs need batch operations

**Strategic** (competitive advantage):
3. ai-study-plan-generator (Score: 1.2)
   Impact: 5 | Effort: 4 | Confidence: 0.8
   "GPT-4 generates personalized plans from ACS gaps. Foreflight lacks this."
   Source: WebSearch - "AI study plan generation edtech"

**Experimental** (test & learn):
4. social-study-groups (Score: 0.8)
   Impact: 3 | Effort: 4 | Confidence: 0.6
   "Students form study groups. Hypothesis: social = retention."
   Source: Industry trend - Duolingo social features

Which to add? (1,2,3,4, quick-wins, strategic, experimental, all, skip)
```

**Selection options:**
- `1,2,3...` - Add specific ideas by number
- `quick-wins` - Add all quick wins
- `strategic` - Add all strategic
- `experimental` - Add all experimental
- `all` - Add everything
- `skip` - Cancel

**If selected**:
- Add to Backlog with full metadata
- Preserve `[PIGGYBACK]` tags in requirements
- Auto-sort by ICE score
- Show updated roadmap summary

### 3. MOVE FEATURE

**Parse**: "move [slug] to [section]"

**Execute:**
- Move between: Backlog -> Later -> Next -> In Progress -> Shipped
- **Auto-sort destination section by ICE** (except In Progress/Shipped)
- If "Shipped": Add date/version, remove Impact/Effort/Confidence/Score

### 4. PRIORITIZE

**Parse**: "prioritize [section]" or "sort [section]"

**Execute:**
- Calculate ICE scores for all items in section
- **Sort by ICE descending** (Backlog/Later/Next only)
- In Progress: Sort by Phase then date
- Shipped: Sort by date (newest first)

### 5. spec-flow HANDOFF

**Parse**: "spec-flow [slug]" or "create spec for [slug]"

**Execute:**
- Extract requirements from roadmap item
- Show `/spec-flow` command with context:
  ```
  Run: /spec-flow [slug]

  Note: /spec-flow will auto-detect roadmap context for [slug]
  ```

**If clarifications remain:**
- Suggest: "Clarifications needed. Run `/roadmap clarify [slug]` first?"

### 6. SHIP FEATURE

**Parse**: "ship [slug]" or "shipped [slug] [version]"

**Execute:**
- Move to "Shipped" section
- Add: **Date**: YYYY-MM-DD
- Add: **Release**: vX.Y.Z - [one-line notes]
- Remove: Branch, Phase, Impact, Effort, Confidence, Score
- Keep: Spec link (if exists)

### 7. SEARCH

**Parse**: Keywords, area filter, role filter

**Execute:**
- Find matches across all sections
- Show: slug, title, score, section
- Count by section

## AUTO-SORT LOGIC

**Trigger on:**
- Add new feature
- Update existing feature
- Change Impact/Effort/Confidence
- Resolve clarifications

**Sort rules:**
- **Backlog/Later/Next**: By ICE score (descending)
- **In Progress**: By Phase, then date
- **Shipped**: By date (newest first)
- Preserve order within same score

**Implementation:**
1. Extract all items from section
2. Calculate ICE for each
3. Sort array by score
4. Rewrite section with sorted items

## FEATURE SIZING

Keep `/spec-flow`-sized: 30 tasks, 1-2 weeks. If larger: Suggest breaking into smaller features.

## RETURN

**Concise summary:**
```
✓ Added: [slug] to Backlog (Impact: N, Effort: N, Score: N.NN)

✓ Roadmap (sorted by priority):
- Shipped: N | In Progress: N | Next: N | Later: N | Backlog: N

Backlog Top 3:
1. [slug-1] (Score: N.NN) - [title]
2. [slug-2] (Score: N.NN) - [title]
3. [slug-3] (Score: N.NN) - [title]

→ Next: /roadmap clarify [slug] OR /spec-flow [slug]
```

**If clarifications offered:**
```
✓ Found N clarifications - How to proceed?
A) Manual | B) Recommend | C) Skip

[Waiting for A, B, or C]
```

**If brainstormed:**
```
✓ Generated N ideas - Which to add? (1,2,3, all, skip)

[Waiting for selection]
```
