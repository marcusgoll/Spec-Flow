---
description: Manage product roadmap (brainstorm, prioritize, track shipped features)
---

Manage the CFIPros roadmap: $ARGUMENTS

## MENTAL MODEL

**Workflow**: roadmap ->\spec-flow -> clarify -> plan -> tasks -> implement -> optimize -> ship

**State machine:**
- Parse intent -> Execute action -> Auto-sort -> Return summary

**Auto-actions:**
- Add/update -> Trigger auto-sort (see AUTO-SORT LOGIC)
- Large feature detected (>30 req OR effort >4) -> Suggest auto-split with scores
- Clarifications found -> Offer manual/recommend/skip (default: recommend)
- Brainstorm -> Generate ideas -> Offer to add

## INITIALIZE

Check if roadmap exists, create from template if missing:
```bash
if [ ! -f "\spec-flow/memory/roadmap.md" ]; then
  mkdir -p \spec-flow/memory
  cp \spec-flow/templates/roadmap-template.md \spec-flow/memory/roadmap.md
fi
```

## CONTEXT

**Location**: `\spec-flow/memory/roadmap.md`

**Sections** (priority order):
1. Shipped (done)
2. In Progress (active)
3. Next (queued)
4. Later (planned)
5. Backlog (ideas)

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

**Auto-sort trigger**: Any add/update/clarify action (see AUTO-SORT LOGIC)

## SCORING

**ICE Formula**: (Impact × Confidence) / Effort

**Defaults** (use when unclear):
- Impact: 3 (medium value)
- Effort: 3 (medium complexity)
- Confidence: 0.7 (medium certainty)

**Tie-breaker**: If scores match, preserve original order

**Examples:**
- High-value quick win: Impact 4, Effort 2, Confidence 1.0 → Score 2.0
- Strategic bet: Impact 5, Effort 4, Confidence 0.8 → Score 1.0
- Small experiment: Impact 2, Effort 1, Confidence 0.6 → Score 1.2

## ACTIONS

### 1. ADD FEATURE

**Parse natural language:**
- Extract: title, area, role, requirements
- Infer: Impact (1-5), Effort (1-5), Confidence (0-1)
- Generate: URL-friendly slug
- Calculate: ICE score (use SCORING defaults if unclear)

**Deduplicate:**
- Lowercase both titles
- Check if slug already exists in roadmap
- Check if `specs/[slug]/` directory exists
- If duplicate: Ask "Merge with existing [slug]?"

**Size validation with auto-split:**

**Trigger:** >30 requirements OR effort >4

**If triggered:**
1. Analyze requirements for natural boundaries:
   - **Phase split**: Look for "MVP", "core", "essential" vs "enhanced", "advanced"
   - **Layer split**: Look for "UI", "frontend" vs "API", "backend" vs "database", "schema"
   - **Tier split**: Look for "free", "anonymous" vs "authenticated", "paid", "premium"

2. Suggest specific split strategy with calculated scores:
```
⚠️  Large feature detected: [slug]
- Requirements: N components
- Effort: N weeks (recommended max: 4)

Suggested split (by [phase|layer|tier]):

A) [slug]-basic (I:N, E:2, C:0.9) → Score: N.NN
   - [MVP requirements extracted]

B) [slug]-enhanced (I:N, E:2, C:0.8) → Score: N.NN
   - [BLOCKED: [slug]-basic]
   - [Enhanced requirements extracted]

Create split features? (Y/n)
```

3. If "Y": Auto-create child features
   - Add [BLOCKED: parent-slug] to dependent features
   - Recalculate ICE scores for each
   - Add all to Backlog
   - Trigger auto-sort

4. If "n": Add original feature as-is with warning tag
   - Add `[LARGE: consider splitting before \spec-flow]` to requirements

**Example split:**
```
Input: "AI Study Plan Generator with export and cloud sync"
Requirements: 6 major components (AI, tracking, storage, export, sharing, cloud)
Effort: 4 weeks

Detection: Layer split (generation + storage + export)

Suggested:
1. study-plan-basic (I:5, E:2, C:0.9) → 2.25
   - AI-powered plan generation from AKTR
   - Progress tracking (local storage)
   - Mark codes as studying/mastered

2. study-plan-export (I:4, E:2, C:0.8) → 1.60
   - [BLOCKED: study-plan-basic]
   - PDF export
   - Shareable links
   - Cloud sync

Result: 2 focused features vs 1 over-scoped feature
```

**Add to Backlog:**
- Append feature with full metadata
- Add `[CLARIFY: question]` for unknowns
- Trigger auto-sort (see AUTO-SORT LOGIC)
- Update timestamp

**Auto-clarification (if `[CLARIFY]` found):**
Present 3 options:
```
🤔 Found N clarifications needed:
1. [First question]
2. [Second question]
...

Options:
A) Answer now (interactive)
B) Let Claude recommend (uses context)
C) Skip (clarify later)

Default: B
```

**If "A" (Manual)**: Interactive Q&A like `/clarify`
**If "B" (Recommend)** [DEFAULT]:
- Use CLAUDE.md, constitution, similar features
- Generate answers with rationale
- Update requirements
- Trigger auto-sort

**If "C" (Skip)**: Continue to summary

### 2. BRAINSTORM (research → plan → present)

**Trigger**: `/roadmap brainstorm [quick|deep] [area|role|topic]`

**Tiers:**
- `quick` (default): 2-3 searches, 5 ideas, ~30 seconds
- `deep`: 8-12 searches, 10 ideas, full industry research

---

**QUICK BRAINSTORM** (2-3 tool calls):

**Step 1 - CFIPros Context:**
- Read `\spec-flow/memory/constitution.md` (mission)
- Read `\spec-flow/memory/roadmap.md` (existing features)

**Step 2 - Focused Research:**
- WebSearch: "[user-specified topic] features 2025" (if args provided)
- OR WebSearch: "aviation education platform [area]" (if area specified)

**Step 3 - Generate 5 Ideas:**
- **Extension** (piggyback existing): Build on current features
- **Gap-fill** (address missing): Solve unmet user needs
- **Quick Wins** (Impact 3-4, Effort 1-2): Ship in 1-2 weeks

**Present** (simplified selection):
```
💡 Brainstormed Ideas (sorted by score):

1. student-progress-widget (Score: 1.5) [PIGGYBACK: aktr-results-core]
   Impact: 3 | Effort: 2 | Confidence: 1.0
   "Show mastery % on results page. Uses existing ACS data."

2. cfi-batch-csv-export (Score: 1.4) [PIGGYBACK: csv-export]
   Impact: 4 | Effort: 3 | Confidence: 0.9
   "Export all students in cohort. Reuses export modal."

...

Which to add? (1,2,3, all, skip)
```

---

**DEEP BRAINSTORM** (8-12 tool calls):

**Phase 1: RESEARCH**

**Step 1 - CFIPros Context:**
- Read `\spec-flow/memory/constitution.md` (mission: AKTR→ACS extraction for aviation education)
- Read `\spec-flow/memory/roadmap.md` (existing features, identify gaps)
- Glob `specs/*/spec.md` (patterns, user flows, reusable infra)

**Step 2 - Industry Research:**
- WebSearch: "aviation education platform features 2025"
- WebSearch: "flight instructor tools student tracking"
- WebSearch: "edtech personalization study plans"
- WebSearch: "[user-specified topic]" (if args provided)

**Step 3 - Gap Analysis:**
- Compare CFIPros vs industry leaders (Foreflight, Sporty's, etc.)
- Identify role gaps: free, student, CFI, school
- Find piggybacking opportunities (leverage existing features)

**Phase 2: PLAN**

**Step 1 - Generate 10 Ideas:**
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

**Phase 3: PRESENT**

```
🔬 Research Summary:
- Analyzed: N existing features, M industry trends
- Found: X gaps, Y piggybacking opportunities

💡 Brainstormed Ideas (sorted by category):

**Quick Wins** (ship in 1-2 weeks):
1. student-progress-widget (Score: 1.5) [PIGGYBACK: aktr-results-core]
   Impact: 3 | Effort: 2 | Confidence: 1.0
   "Show mastery % on results page. Uses existing ACS data."
   Source: WebSearch - "edtech student dashboards 2025"

**Strategic** (competitive advantage):
2. ai-study-plan-generator (Score: 1.2)
   Impact: 5 | Effort: 4 | Confidence: 0.8
   "GPT-4 generates personalized plans from ACS gaps. Foreflight lacks this."
   Source: WebSearch - "AI study plan generation edtech"

**Experimental** (test & learn):
3. social-study-groups (Score: 0.8)
   Impact: 3 | Effort: 4 | Confidence: 0.6
   "Students form study groups. Hypothesis: social = retention."
   Source: Industry trend - Duolingo social features

Which to add? (1,2,3, all, skip)
```

---

**Selection** (both tiers):
- `1,2,3...` - Add specific ideas by number
- `all` - Add everything
- `skip` - Cancel

**If selected**:
- Add to Backlog with full metadata
- Preserve `[PIGGYBACK]` tags in requirements
- Trigger auto-sort (see AUTO-SORT LOGIC)
- Show updated roadmap summary

### 3. MOVE FEATURE

**Parse**: "move [slug] to [section]"

**Valid moves:**
- Backlog -> Later -> Next -> In Progress -> Shipped
- Downgrade: Next -> Later -> Backlog (if deprioritized)

**Execute:**
- Move item to target section
- Trigger auto-sort in destination (see AUTO-SORT LOGIC)
- If "Shipped": Add date, remove Impact/Effort/Confidence/Score

### 4. DELETE FEATURE

**Parse**: "delete [slug]" or "remove [slug]"

**Confirm:**
```
⚠️  Delete [slug] from roadmap?

This will permanently remove:
- Title: [title]
- Section: [section]
- Requirements: [count] items

Note: If specs/[slug]/ exists, it will NOT be deleted.

Confirm? (yes/no)
```

**Execute:**
- Remove item from roadmap
- Keep specs/[slug]/ untouched (manual cleanup if needed)

### 5. PRIORITIZE

**Parse**: "prioritize [section]" or "sort [section]"

**Execute:**
- Trigger auto-sort for specified section (see AUTO-SORT LOGIC)
- Show updated section summary

### 6.\spec-flow HANDOFF

**Parse**: \spec-flow [slug]" or "create spec for [slug]"

**Execute:**
- Check if specs/[slug]/ exists
- Extract requirements from roadmap item
- Show `\spec-flow` command with context:

```
Run: \spec-flow [slug]

\spec-flow will:
1. Read \spec-flow/memory/roadmap.md
2. Find [slug] in roadmap
3. Extract requirements as context
4. Generate spec in specs/[slug]/spec.md
5. Update roadmap with "Spec: specs/[slug]/" link
```

**If clarifications remain:**
- Suggest: "Clarifications needed. Run `/roadmap clarify [slug]` first?"

### 7. SHIP FEATURE

**Parse**: "ship [slug]" or "shipped [slug] [version]"

**Execute:**
- Move to "Shipped" section
- Add: **Date**: YYYY-MM-DD
- Add: **Release**: vX.Y.Z - [one-line notes]
- Remove: Impact, Effort, Confidence, Score
- Keep: Spec link (if exists)
- Sort Shipped by date (newest first)

### 8. SEARCH

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
- Move feature to new section

**Sort rules:**
- **Backlog/Later/Next**: By ICE score (descending), then preserve original order for ties
- **In Progress**: Preserve manual order (user controls priority)
- **Shipped**: By date (newest first)

**Implementation:**
1. Extract all items from section
2. Calculate ICE for each (use SCORING formula)
3. Sort array by score (descending)
4. For ties: Preserve original order (stable sort)
5. Rewrite section with sorted items

## RETURN

**Concise summary:**
```
✅ Added: [slug] to Backlog (Impact: N, Effort: N, Score: N.NN)

📊 Roadmap (sorted by priority):
- Shipped: N | In Progress: N | Next: N | Later: N | Backlog: N

Backlog Top 3:
1. [slug-1] (Score: N.NN) - [title]
2. [slug-2] (Score: N.NN) - [title]
3. [slug-3] (Score: N.NN) - [title]

💡 Next: /roadmap clarify [slug] OR \spec-flow [slug]
```

**If auto-split created:**
```
✅ Split [original-slug] into N features:
- [slug-1] (Score: N.NN) - Basic version
- [slug-2] (Score: N.NN) - Enhanced version [BLOCKED: slug-1]

📊 Roadmap (sorted by priority):
- Backlog: N (including N new features)

Backlog Top 5:
1. [slug-1] (Score: N.NN) - [title]
2. [other-slug] (Score: N.NN) - [title]
3. [slug-2] (Score: N.NN) - [title] [BLOCKED]

💡 Next: \spec-flow [slug-1] (ship basic version first)
```

**If clarifications offered:**
```
🤔 Found N clarifications - How to proceed?
A) Answer now | B) Let Claude recommend | C) Skip

Default: B

[Waiting for A, B, or C]
```

**If brainstormed:**
```
💡 Generated N ideas - Which to add? (1,2,3, all, skip)

[Waiting for selection]
```

