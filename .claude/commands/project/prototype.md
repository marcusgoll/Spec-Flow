---
name: prototype
description: Discovery-first prototyping - explore app ideas with zero-risk iteration before committing to roadmap/features
argument-hint: [discover|explore|create|update|status|extract|outcome|lock-theme|unlock-theme|sync-tokens] [exploration-name] [--with-tokens|--skip-tokens] [--exploration name] [--adopt|--defer|--scrap]
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash(git:*), Bash(test:*), Bash(node:*), AskUserQuestion, TodoWrite]
version: 2.0
created: 2025-11-27
updated: 2025-12-02
---

# /prototype - Discovery-First Prototyping

<context>
**Check these files before proceeding:**
- Prototype state: `design/prototype/state.yaml`
- Design tokens: `design/systems/tokens.json` and `tokens.css`
- Project docs: `docs/project/overview.md`
- User preferences: `.spec-flow/config/user-preferences.yaml`
</context>

<objective>
**Discovery-first prototyping** - explore app ideas visually before committing to roadmap or features.

**Philosophy**: This is your zero-risk sandbox. Try ideas. Scrap what doesn't work. Nothing here commits you to building anything. The prototype informs your roadmap, not the other way around.

**Workflow Position**:
```
/init-project → /prototype discover → /roadmap import-from-prototype → /epic or /feature
```

**Modes**:
- `discover`: Full app exploration at project start, brainstorm screens, zero commitments
- `explore`: **Loop back** - Explore new feature/epic ideas within existing prototype
- `create`: Generate structured prototype (legacy, still works)
- `update`: Add screens to existing prototype
- `status`: Show prototype overview and screen registry
- `extract`: Analyze prototype → generate discovered-features.md + component-inventory.md
- `lock-theme`: Lock design decisions for production use
- `unlock-theme`: Unlock for further iteration (requires confirmation)
- `sync-tokens`: Update prototype to use refined tokens from /init-brand-tokens
- `sync [pasted-content]`: Import ideas/questions/scraps captured in browser (paste inline or when prompted)

**Token Integration**:
- `--with-tokens`: Force token generation (inline palette picker)
- `--skip-tokens`: Use placeholder grays (fastest start)
- `--use-existing`: Use tokens.json if exists, else error
- (default): Auto-detect: use existing tokens or prompt

**Git Persistence**:
- `--commit`: Add prototype to git (recommended for design assets)
- `--gitignore`: Exclude from git (rapid iteration)

**When to use**: After `/init-project`, BEFORE `/roadmap`. Discover what to build before planning.
</objective>

## Anti-Hallucination Rules

1. **Never generate screens without user input**
   - Always ask about screen categories and navigation structure
   - Don't assume app structure

2. **Token handling is flexible in discovery mode**
   - Check for existing tokens.json first
   - If missing, offer quick palette picker OR skip (use grays)
   - Never block discovery for missing tokens

3. **Read state.yaml before claiming status**
   - Quote actual screen registry
   - Report real last_updated timestamp

4. **Check prototype existence before operations**
   - `discover`: Can start fresh or add to existing (flexible)
   - `create`: Fail if prototype exists (use `update` instead)
   - `update`: Fail if prototype doesn't exist (use `create` instead)
   - `status`: Fail gracefully with "No prototype found" message

5. **Discovery mode is zero-risk**
   - Never warn about "losing work" - scrapping is expected
   - Encourage iteration and experimentation
   - Don't block on quality gates

---

<process>

## Mode: DISCOVER (Recommended Entry Point)

**Purpose**: Zero-risk exploration to discover what to build before committing to roadmap.

### Step 0: Display Discovery Banner

```
═══════════════════════════════════════════════════════════════════════════════
  PROTOTYPE DISCOVERY - Zero-risk exploration phase
═══════════════════════════════════════════════════════════════════════════════

  This is your sandbox. Try ideas. Scrap what doesn't work.
  Nothing here commits you to building anything.

  Press 'I' on any screen to log an idea.
  Press 'Q' to log a question.
  Press 'X' to scrap current screen.

═══════════════════════════════════════════════════════════════════════════════
```

### Step 1: Token Detection and Setup

**Check for existing tokens:**
```bash
test -f design/systems/tokens.json && echo "TOKENS_EXIST=true" || echo "TOKENS_EXIST=false"
```

**If tokens exist:**
```
✓ Found existing design tokens: design/systems/tokens.json
  Using your established color palette for prototype.
```

**If no tokens AND no --skip-tokens flag:**

```json
{
  "question": "No design tokens found. How should we handle colors?",
  "header": "Palette",
  "multiSelect": false,
  "options": [
    {"label": "Quick palette picker", "description": "Choose a vibe, get instant colors (recommended)"},
    {"label": "Skip for now", "description": "Use placeholder grays, add colors later"},
    {"label": "Run /init-brand-tokens", "description": "Full token generation (exits discovery)"}
  ]
}
```

### Step 2: Quick Palette Picker (If Selected)

```json
{
  "question": "What's your brand vibe?",
  "header": "Vibe",
  "multiSelect": false,
  "options": [
    {"label": "Professional", "description": "Blues and grays - SaaS, B2B, enterprise"},
    {"label": "Modern SaaS", "description": "Indigo/purple accents - startups, tech"},
    {"label": "Friendly", "description": "Warm oranges and teals - consumer, social"},
    {"label": "Bold", "description": "High contrast, saturated - creative, gaming"},
    {"label": "Minimal", "description": "Near-monochrome - content, editorial"},
    {"label": "Custom", "description": "Pick your own primary color"}
  ]
}
```

**Generate starter tokens based on vibe:**

| Vibe | Primary | Secondary | Accent |
|------|---------|-----------|--------|
| Professional | oklch(50% 0.15 240) Blue | oklch(45% 0.1 250) Slate | oklch(65% 0.2 180) Teal |
| Modern SaaS | oklch(55% 0.2 270) Indigo | oklch(60% 0.15 300) Purple | oklch(70% 0.18 180) Teal |
| Friendly | oklch(65% 0.2 50) Orange | oklch(55% 0.15 180) Teal | oklch(70% 0.15 330) Pink |
| Bold | oklch(55% 0.25 0) Red | oklch(50% 0.2 270) Purple | oklch(80% 0.2 90) Yellow |
| Minimal | oklch(25% 0.02 270) Charcoal | oklch(50% 0.02 270) Gray | oklch(55% 0.15 270) Accent |

**Write starter tokens to `design/prototype/theme.yaml`** (NOT design/systems/ - keep discovery separate):
```yaml
theme:
  name: "Discovery Prototype"
  source: "quick-palette"
  vibe: "[SELECTED_VIBE]"
  locked: false

  palette:
    primary: "[PRIMARY_OKLCH]"
    secondary: "[SECONDARY_OKLCH]"
    accent: "[ACCENT_OKLCH]"
    # Auto-generated semantic colors
    success: "oklch(65% 0.2 145)"
    warning: "oklch(75% 0.15 85)"
    error: "oklch(55% 0.25 25)"
    info: "oklch(60% 0.15 240)"
    # Auto-generated neutral scale (11 shades)
    neutral-50: "oklch(98% 0.01 270)"
    neutral-100: "oklch(96% 0.01 270)"
    # ... through neutral-950
```

### Step 3: App Vision Brainstorm

**Unlike structured CREATE mode, DISCOVER is conversational:**

```json
{
  "question": "In one sentence, what does your app help people do?",
  "header": "Vision",
  "multiSelect": false,
  "options": [
    {"label": "Manage tasks/projects", "description": "Todo lists, kanban, project tracking"},
    {"label": "Collaborate with teams", "description": "Chat, docs, shared workspaces"},
    {"label": "Track and analyze data", "description": "Dashboards, reports, metrics"},
    {"label": "Buy/sell products", "description": "E-commerce, marketplace, inventory"},
    {"label": "Create content", "description": "Writing, design, media production"},
    {"label": "Other", "description": "Type your own vision statement"}
  ]
}
```

### Step 4: Screen Brainstorm (Freeform)

```json
{
  "question": "What screens might your app need? (Select all that seem relevant - you can change later!)",
  "header": "Screens",
  "multiSelect": true,
  "options": [
    {"label": "Login / Signup", "description": "User authentication"},
    {"label": "Dashboard", "description": "Overview, metrics, quick actions"},
    {"label": "List / Browse", "description": "View multiple items, search, filter"},
    {"label": "Detail view", "description": "Single item with full info"},
    {"label": "Create / Edit form", "description": "Add or modify data"},
    {"label": "Settings", "description": "User preferences, account"},
    {"label": "Profile", "description": "User profile page"},
    {"label": "Notifications", "description": "Alerts, activity feed"}
  ]
}
```

**Follow-up:**
```json
{
  "question": "Any other screens you're thinking about? (Type names, comma-separated, or skip)",
  "header": "More screens",
  "multiSelect": false,
  "options": [
    {"label": "Skip", "description": "Start with selected screens"},
    {"label": "Add more", "description": "Type additional screen names"}
  ]
}
```

### Step 5: Generate Discovery Prototype

**Create directory structure:**
```
design/prototype/
├── index.html              # Navigation hub
├── theme.yaml              # Palette from quick picker
├── theme.css               # Generated CSS variables
├── shared.css              # Component styles
├── state.yaml              # Discovery state
├── screens/                # Generated screens
│   ├── dashboard.html
│   ├── list.html
│   └── ...
└── _discovery/             # NEW: Discovery artifacts
    ├── ideas.md            # Captured ideas (press 'I')
    ├── questions.md        # Open questions (press 'Q')
    ├── scrapped/           # Screens you tried and scrapped
    └── iterations/         # Version snapshots
```

**Generate `_discovery/ideas.md`:**
```markdown
# Ideas Log

> Press 'I' on any prototype screen to add ideas here.
> These may become features on your roadmap.

## Ideas

<!-- Ideas will be appended here -->
```

**Generate `_discovery/questions.md`:**
```markdown
# Open Questions

> Press 'Q' on any prototype screen to log questions.
> Resolve these before finalizing your roadmap.

## Questions

<!-- Questions will be appended here -->
```

### Step 6: Display Discovery Summary

```
═══════════════════════════════════════════════════════════════════════════════
  Discovery Prototype Created!
═══════════════════════════════════════════════════════════════════════════════

  Location: design/prototype/
  Palette: [VIBE] (from quick picker)
  Screens: [COUNT] initial screens

  Generated screens:
    • dashboard.html
    • list.html
    • detail.html
    • settings.html

  ┌─────────────────────────────────────────────────────────────────────────┐
  │  KEYBOARD SHORTCUTS (on any screen)                                     │
  │                                                                         │
  │  1-9     Jump to screen by number                                      │
  │  H       Return to hub                                                  │
  │  S       Cycle states (success/loading/error/empty)                    │
  │  I       Log an idea (saved to _discovery/ideas.md)                    │
  │  Q       Log a question (saved to _discovery/questions.md)             │
  │  X       Scrap current screen (moves to _discovery/scrapped/)          │
  └─────────────────────────────────────────────────────────────────────────┘

  NEXT STEPS:
  1. Open design/prototype/index.html in your browser
  2. Explore, iterate, scrap and retry - zero consequences!
  3. When ready: /prototype extract → analyze what you discovered
  4. Then: /roadmap import-from-prototype → plan what to build

═══════════════════════════════════════════════════════════════════════════════
```

---

## Mode: EXPLORE (Loop Back for New Ideas)

**Purpose**: Return to prototype discovery for a specific new feature or epic idea.

### When to Use

- You shipped some features and now have new ideas
- User feedback suggests a new feature direction
- You want to visually explore before committing to roadmap
- Theme is locked but you want to try variations for a specific feature

### Step 1: Check Existing Prototype

```bash
test -f design/prototype/state.yaml || echo "No prototype exists. Use '/prototype discover' instead."
```

### Step 2: Exploration Context

```json
{
  "question": "What are you exploring?",
  "header": "Explore",
  "multiSelect": false,
  "options": [
    {"label": "New feature idea", "description": "Explore screens for a potential new feature"},
    {"label": "New epic idea", "description": "Explore a larger multi-screen epic"},
    {"label": "Variation on existing", "description": "Try a different approach to existing screens"},
    {"label": "User feedback response", "description": "Explore based on user/stakeholder feedback"}
  ]
}
```

### Step 3: Name the Exploration

```json
{
  "question": "Give this exploration a name (e.g., 'notifications-v2', 'team-collaboration')",
  "header": "Name",
  "multiSelect": false,
  "options": [
    {"label": "Type a name", "description": "Short kebab-case name for this exploration"}
  ]
}
```

### Step 4: Create Exploration Sandbox

**Create isolated exploration directory:**
```
design/prototype/
├── _explorations/                    # NEW: Exploration sandboxes
│   └── [exploration-name]/
│       ├── context.md                # Why we're exploring this
│       ├── screens/
│       │   ├── screen-1.html
│       │   └── screen-2.html
│       ├── ideas.md                  # Ideas specific to this exploration
│       ├── questions.md              # Questions for this exploration
│       └── outcome.md                # Decision: adopt, defer, or scrap
```

**Note**: Explorations use the existing locked theme but can experiment with layout/components.

### Step 5: Brainstorm Screens for Exploration

```json
{
  "question": "What screens might this [feature/epic] need?",
  "header": "Screens",
  "multiSelect": true,
  "options": [
    {"label": "List view", "description": "Browse/filter items"},
    {"label": "Detail view", "description": "Single item deep-dive"},
    {"label": "Create/Edit form", "description": "Add or modify data"},
    {"label": "Dashboard widget", "description": "Summary card for main dashboard"},
    {"label": "Settings section", "description": "Configuration for this feature"},
    {"label": "Modal/Dialog", "description": "Overlay interaction"},
    {"label": "Empty state", "description": "What shows when no data"},
    {"label": "Other", "description": "Custom screen names"}
  ]
}
```

### Step 6: Generate Exploration Screens

- Use existing theme.yaml (locked or not)
- Generate screens in `_explorations/[name]/screens/`
- Add exploration to state.yaml registry
- Create context.md with exploration purpose

### Step 7: Display Exploration Summary

```
═══════════════════════════════════════════════════════════════════════════════
  Exploration Started: [exploration-name]
═══════════════════════════════════════════════════════════════════════════════

  Location: design/prototype/_explorations/[exploration-name]/
  Using theme: [locked/unlocked] (from main prototype)
  Screens: [N] exploration screens

  Generated:
    • screens/notification-list.html
    • screens/notification-detail.html
    • screens/notification-settings.html

  EXPLORATION SHORTCUTS:
    Same as main prototype (1-9, S, I, Q, X)

  WHEN DONE:
    /prototype outcome [exploration-name]
      → Decide: adopt (merge to main), defer (keep for later), or scrap

  ADOPT FLOW:
    /prototype outcome [name] --adopt
    /prototype extract --exploration [name]
    /roadmap import-from-prototype --exploration [name]

═══════════════════════════════════════════════════════════════════════════════
```

---

## Mode: OUTCOME (Finalize Exploration)

**Purpose**: Decide what to do with an exploration.

### Step 1: Select Exploration

```bash
ls design/prototype/_explorations/
```

### Step 2: Choose Outcome

```json
{
  "question": "What's the outcome of the '[exploration-name]' exploration?",
  "header": "Outcome",
  "multiSelect": false,
  "options": [
    {"label": "Adopt", "description": "Merge screens into main prototype, add to roadmap"},
    {"label": "Defer", "description": "Good idea but not now - keep for future reference"},
    {"label": "Scrap", "description": "Didn't work out - move to scrapped folder"}
  ]
}
```

### Step 3: Execute Outcome

**If Adopt:**
- Move screens from `_explorations/[name]/screens/` to `design/prototype/screens/`
- Update main prototype's index.html
- Update state.yaml with new screens
- Mark exploration as adopted in outcome.md
- Suggest: `/prototype extract --exploration [name]`

**If Defer:**
- Keep exploration in place
- Add to `_explorations/_deferred.md` list
- Record reason for deferral in outcome.md

**If Scrap:**
- Move to `_explorations/_scrapped/[name]/`
- Record why it didn't work in outcome.md
- Keep for historical reference

---

## Mode: SYNC (Import Browser Captures)

**Purpose**: Import ideas, questions, and scrap decisions captured while browsing the prototype.

### How the Browser → Claude Bridge Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   BROWSER (prototype screens)                CLAUDE (terminal)             │
│   ═══════════════════════════                ═══════════════════           │
│                                                                             │
│   User browses prototype...                                                │
│        │                                                                    │
│        ▼                                                                    │
│   Presses 'I' → Modal appears                                              │
│   Types: "Need a notifications badge"                                      │
│   Clicks Save                                                               │
│        │                                                                    │
│        ▼                                                                    │
│   Saved to localStorage:                                                   │
│   { ideas: [{ text: "Need a...", screen: "dashboard" }] }                 │
│        │                                                                    │
│        │    ... continues browsing, logs more ideas ...                    │
│        │                                                                    │
│        ▼                                                                    │
│   Presses 'E' (Export)                                                     │
│        │                                                                    │
│        ▼                                                                    │
│   Markdown copied to clipboard:                                            │
│   ┌─────────────────────────────────┐                                      │
│   │ # Prototype Discovery Export    │                                      │
│   │                                 │                                      │
│   │ ## Ideas (3)                    │                                      │
│   │ ### Idea 1                      │                                      │
│   │ - Text: Need a notifications... │                                      │
│   │ - Screen: dashboard             │                                      │
│   │ ...                             │                                      │
│   └─────────────────────────────────┘                                      │
│        │                                                                    │
│        └──────────────────────────────────────────────────────────────┐    │
│                                                                        │    │
│                                                        ┌───────────────▼──┐│
│                                                        │ /prototype sync  ││
│                                                        │                  ││
│                                                        │ "Paste export:"  ││
│                                                        │ [user pastes]    ││
│                                                        │                  ││
│                                                        │ Parses markdown  ││
│                                                        │ Updates files:   ││
│                                                        │ • ideas.md       ││
│                                                        │ • questions.md   ││
│                                                        │ • Scraps screens ││
│                                                        └──────────────────┘│
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Step 1: Get Export Content

**Two ways to provide content:**

**Option A: Inline paste (single command)**
```
/prototype sync # Prototype Discovery Export

## Ideas (2)
### Idea 1
- Text: Add notification badge to header
- Screen: dashboard
...
```

**Option B: Prompted paste (if no content provided)**
```
/prototype sync
```

Display:
```
═══════════════════════════════════════════════════════════════════════════════
  Prototype Sync - Import Browser Captures
═══════════════════════════════════════════════════════════════════════════════

  In your browser prototype, press 'E' to export captured data.
  Then paste the markdown here (or run: /prototype sync [paste-here])

  Waiting for paste...

═══════════════════════════════════════════════════════════════════════════════
```

**Detect content source:**
```javascript
const args = "$ARGUMENTS".trim();
const hasInlineContent = args.includes("# Prototype Discovery Export") ||
                         args.includes("## Ideas") ||
                         args.includes("## Questions");

if (hasInlineContent) {
  // Parse directly from args
  content = args.replace(/^sync\s*/, '');
} else {
  // Prompt user to paste
  // Use AskUserQuestion or wait for next message
}
```

### Step 2: Parse Exported Data

Parse the markdown structure:
- Extract ideas from `## Ideas` section
- Extract questions from `## Questions` section
- Extract screens to scrap from `## Screens to Scrap` section

### Step 3: Update Discovery Files

**Append to `_discovery/ideas.md`:**
```markdown
## Idea: [TEXT]
- **Screen**: [SCREEN]
- **Captured**: [TIMESTAMP]
- **Status**: New
```

**Append to `_discovery/questions.md`:**
```markdown
## Question: [TEXT]
- **Screen**: [SCREEN]
- **Impact**: [TBD]
- **Status**: Unresolved
```

**For scrapped screens:**
- Move screen file to `_discovery/scrapped/`
- Remove from state.yaml screen registry
- Update index.html to remove link

### Step 4: Display Sync Summary

```
═══════════════════════════════════════════════════════════════════════════════
  Sync Complete!
═══════════════════════════════════════════════════════════════════════════════

  Imported:
    💡 3 ideas → _discovery/ideas.md
    ❓ 2 questions → _discovery/questions.md
    🗑️ 1 screen scrapped → _discovery/scrapped/

  Files updated:
    • design/prototype/_discovery/ideas.md
    • design/prototype/_discovery/questions.md
    • design/prototype/state.yaml

  Browser localStorage will be cleared on next export.

  NEXT:
    • Continue exploring: open prototype in browser
    • Ready to extract: /prototype extract

═══════════════════════════════════════════════════════════════════════════════
```

---

## Mode: EXTRACT

**Purpose**: Analyze your discovery prototype and extract features + components for roadmap.

### Step 1: Verify Prototype Exists

```bash
test -f design/prototype/state.yaml || echo "ERROR: No prototype found. Run '/prototype discover' first."
```

### Step 2: Scan Prototype Screens

**For each screen in design/prototype/screens/:**
- Parse HTML for component patterns
- Count occurrences of each component type
- Detect variants and states
- Identify user flows (links between screens)

### Step 3: Read Discovery Artifacts

**Read ideas.md:**
```bash
cat design/prototype/_discovery/ideas.md
```

**Read questions.md:**
```bash
cat design/prototype/_discovery/questions.md
```

### Step 4: Generate discovered-features.md

**Write to `design/prototype/discovered-features.md`:**
```markdown
# Discovered Features from Prototype

> Extracted on [DATE] from [N] prototype screens

## Feature Summary

| Feature | Screens | Complexity | Priority Hint |
|---------|---------|------------|---------------|
| User Authentication | login, signup | Feature | Foundation |
| Dashboard Overview | dashboard | Feature | Core |
| Task Management | list, detail, create | Epic | Core |
| Settings & Profile | settings, profile | Feature | Enhancement |

## Detailed Features

### 1. User Authentication
**Screens**: login.html, signup.html
**Complexity**: Feature (single subsystem)
**Why**: Users need to access the app securely

**User Stories** (inferred from mockups):
- User can log in with email/password
- User can create new account
- User can reset forgotten password

### 2. Task Management
**Screens**: list.html, detail.html, create.html
**Complexity**: Epic (CRUD + interactions)
**Why**: Core value proposition of the app

**User Stories**:
- User can view list of tasks
- User can view task details
- User can create new task
- User can edit/delete task

## Ideas from Discovery
<!-- Copied from _discovery/ideas.md -->

## Open Questions
<!-- Copied from _discovery/questions.md -->

## Scrapped Screens (for reference)
<!-- List screens in _discovery/scrapped/ -->
```

### Step 5: Generate component-inventory.md

**Write to `design/prototype/component-inventory.md`:**
```markdown
# Component Inventory from Prototype

> Extracted on [DATE]

## Component Summary

| Component | Occurrences | Screens | Build Priority |
|-----------|-------------|---------|----------------|
| Button | 34 | all | Must build |
| Card | 18 | dashboard, list | Must build |
| Input | 12 | login, signup, create | Must build |
| Avatar | 8 | dashboard, detail | Should build |
| Badge | 6 | list, detail | Should build |
| Modal | 3 | detail | Consider |

## Recommended Build Order

1. **Button** (foundation - used everywhere)
2. **Input** (forms depend on this)
3. **Card** (layout building block)
4. **Avatar** (user-related features)
5. **Badge** (status indicators)
6. **Modal** (detail views)

## tv() Recommendations

Based on variants detected in prototype:

### Button
- Variants: primary, secondary, outline, ghost, danger
- Sizes: sm, md, lg
- States: disabled, loading

### Card
- Variants: default, elevated, interactive
- Slots: header, body, footer
```

### Step 6: Display Extraction Summary

```
═══════════════════════════════════════════════════════════════════════════════
  Prototype Extraction Complete!
═══════════════════════════════════════════════════════════════════════════════

  Analyzed: [N] screens, [M] components

  Features Discovered:
    • User Authentication (Feature)
    • Dashboard Overview (Feature)
    • Task Management (Epic)
    • Settings & Profile (Feature)

  Components to Build:
    • Button (34 occurrences) - Must build
    • Card (18 occurrences) - Must build
    • Input (12 occurrences) - Must build
    • Avatar (8 occurrences) - Should build

  Ideas Captured: [N]
  Questions Open: [M]

  Generated:
    • design/prototype/discovered-features.md
    • design/prototype/component-inventory.md

  NEXT STEP:
    /roadmap import-from-prototype

═══════════════════════════════════════════════════════════════════════════════
```

---

## Mode: LOCK-THEME

**Purpose**: Lock design decisions for production use after discovery is complete.

### Step 1: Confirm Lock

```json
{
  "question": "Ready to lock your design theme? This signals discovery is complete.",
  "header": "Lock Theme",
  "multiSelect": false,
  "options": [
    {"label": "Yes, lock theme", "description": "Design decisions finalized for production"},
    {"label": "Not yet", "description": "Continue iterating in discovery"}
  ]
}
```

### Step 2: Update theme.yaml

```yaml
theme:
  locked: true
  locked_at: "[TIMESTAMP]"
  locked_by: "[USER]"
```

### Step 3: Optionally Promote to System Tokens

```json
{
  "question": "Promote discovery palette to production tokens?",
  "header": "Tokens",
  "multiSelect": false,
  "options": [
    {"label": "Yes, create tokens.json", "description": "Copy palette to design/systems/tokens.json"},
    {"label": "Run /init-brand-tokens", "description": "Full token generation with WCAG validation"},
    {"label": "Keep separate", "description": "Prototype stays isolated from production"}
  ]
}
```

### Step 4: Display Lock Confirmation

```
Theme Locked! ✓

  design/prototype/theme.yaml is now locked.
  Future /feature and /epic workflows will use these design decisions.

  Theme Details:
    Vibe: Modern SaaS
    Primary: oklch(55% 0.2 270)
    Locked at: 2025-01-15T10:30:00Z

  To unlock: /prototype unlock-theme (will prompt for confirmation)
```

---

## Mode: SYNC-TOKENS

**Purpose**: Update prototype to use refined tokens after running /init-brand-tokens.

### Step 1: Check for Updated Tokens

```bash
test -f design/systems/tokens.json && echo "TOKENS_FOUND" || echo "NO_TOKENS"
```

### Step 2: Compare with Prototype Theme

- Read `design/systems/tokens.json`
- Read `design/prototype/theme.yaml`
- Identify differences

### Step 3: Update Prototype Theme

- Import system tokens as foundation
- Preserve any prototype-specific overrides
- Regenerate theme.css

### Step 4: Display Sync Summary

```
Tokens Synced! ✓

  Prototype now uses production tokens from:
    design/systems/tokens.json

  Changes:
    • Primary color updated (was quick-picker, now brand-approved)
    • Added 15 additional semantic tokens
    • Neutral scale aligned with production

  Prototype-specific overrides preserved:
    • experimental.drag_highlight
    • experimental.drop_zone
```

---

## User Input Handling

```text
$ARGUMENTS
```

**Parse mode from arguments:**
- `create` | empty → Create new prototype
- `update` → Add screens to existing prototype
- `status` → Show prototype overview

**Parse flags:**
- `--commit` → Force git commit
- `--gitignore` → Force gitignore
- `--screens X,Y,Z` → Specific screens to add (update mode)

---

## Mode: CREATE

### Step 1: Prerequisite Checks

1. **Check prototype doesn't exist:**
   ```bash
   test ! -f design/prototype/state.yaml || echo "ERROR: Prototype already exists. Use '/prototype update' to add screens."
   ```

2. **Check project docs exist:**
   ```bash
   test -f docs/project/overview.md || echo "WARNING: No project docs. Run '/init-project' first for better context."
   ```

3. **Check design tokens:**
   ```bash
   test -f design/systems/tokens.css && echo "Tokens available" || echo "WARNING: No tokens.css. Run '/init-brand-tokens' first."
   ```

### Step 2: Context Gathering Questionnaire

**IMPORTANT**: Capture context BEFORE screen selection to ensure theme consistency and inform category suggestions.

**Round 0A - App Type:**
```json
{
  "question": "What type of application are you building?",
  "header": "App Type",
  "multiSelect": false,
  "options": [
    {"label": "SaaS/B2B Tool", "description": "Dashboard-heavy, data management, team features"},
    {"label": "Consumer/B2C App", "description": "User-focused, social features, engagement"},
    {"label": "E-Commerce", "description": "Products, cart, checkout, order management"},
    {"label": "Content Platform", "description": "Blog, docs, media, publishing"}
  ]
}
```
→ Store in `context.app_type` and `theme.yaml`

**Round 0B - Core User Goal:**
```json
{
  "question": "What is the ONE primary thing users must accomplish?",
  "header": "Core Goal",
  "multiSelect": false,
  "options": [
    {"label": "Create/Manage Data", "description": "CRUD operations, forms, data entry, lists"},
    {"label": "Analyze Information", "description": "Charts, reports, insights, dashboards"},
    {"label": "Complete Transaction", "description": "Purchase, booking, payment, checkout"},
    {"label": "Consume Content", "description": "Read, watch, browse, discover"}
  ]
}
```
→ Store in `context.core_goal`

**Round 0C - User Journey:**
```json
{
  "question": "Describe the happy path in 3-5 steps (use 'Other' to type)",
  "header": "Journey",
  "multiSelect": false,
  "options": [
    {"label": "Auth → Dashboard → Create", "description": "Login, view overview, create new item"},
    {"label": "Browse → Detail → Action", "description": "Explore catalog, view item, take action"},
    {"label": "Onboard → Setup → Use", "description": "Sign up, configure, start using"},
    {"label": "Other", "description": "Describe your custom journey (e.g., Login → Search → Compare → Buy)"}
  ]
}
```
→ Store in `context.user_journey`

**Round 0D - Visual Tone:**
```json
{
  "question": "What visual tone fits your product?",
  "header": "Tone",
  "multiSelect": false,
  "options": [
    {"label": "Professional", "description": "Clean, corporate, trustworthy (SaaS, B2B)"},
    {"label": "Friendly", "description": "Warm, approachable, conversational (Consumer)"},
    {"label": "Playful", "description": "Bold, fun, energetic (Gaming, Social)"},
    {"label": "Minimal", "description": "Sparse, content-focused, no distractions (Content)"}
  ]
}
```
→ Store in `context.tone_style` and `theme.yaml`

**Round 0E - Content Density:**
```json
{
  "question": "How dense should the interface be?",
  "header": "Density",
  "multiSelect": false,
  "options": [
    {"label": "Compact", "description": "Information-dense, power users, lots of data (Trading, Analytics)"},
    {"label": "Comfortable", "description": "Balanced spacing, general use (Most apps)"},
    {"label": "Spacious", "description": "Generous whitespace, focus on content (Marketing, Editorial)"}
  ]
}
```
→ Store in `context.density` and `theme.yaml`

### Step 3: Theme Generation

Based on context answers, generate `design/prototype/theme.yaml`:
- Use template from `.spec-flow/templates/prototype/theme.yaml`
- Map app_type to suggested palette
- Set tone.style and tone.density from answers
- Set `locked: false` (will lock after first mockup approval)

Also generate `design/prototype/theme.css` from theme.yaml values.

### Step 4: Screen Category Questionnaire

**Suggest categories based on app_type:**

| App Type | Suggested Categories |
|----------|---------------------|
| SaaS/B2B | Dashboard, Settings, Team, Reports |
| Consumer | Home, Profile, Discovery, Notifications |
| E-Commerce | Catalog, Product, Cart, Checkout, Orders |
| Content | Browse, Article, Search, Collections |

**Use AskUserQuestion (Categories):**

```json
{
  "question": "What screen categories does your app need? (Suggested based on {APP_TYPE})",
  "header": "Categories",
  "multiSelect": true,
  "options": [
    {"label": "Authentication", "description": "Login, signup, forgot password, 2FA"},
    {"label": "Dashboard", "description": "Overview, analytics, metrics"},
    {"label": "Settings", "description": "Profile, preferences, account, billing"},
    {"label": "Admin", "description": "User management, system config, logs"}
  ]
}
```

**For each selected category, ask follow-up (Round 2):**

**If "Authentication" selected:**
```json
{
  "question": "Which authentication screens?",
  "header": "Auth screens",
  "multiSelect": true,
  "options": [
    {"label": "Login", "description": "Email/password sign in"},
    {"label": "Signup", "description": "New user registration"},
    {"label": "Forgot Password", "description": "Password reset flow"},
    {"label": "2FA", "description": "Two-factor authentication"}
  ]
}
```

**If "Dashboard" selected:**
```json
{
  "question": "Which dashboard screens?",
  "header": "Dashboard screens",
  "multiSelect": true,
  "options": [
    {"label": "Overview", "description": "Main dashboard landing"},
    {"label": "Analytics", "description": "Charts and data visualization"},
    {"label": "Activity", "description": "Recent events and notifications"},
    {"label": "Reports", "description": "Generated reports and exports"}
  ]
}
```

**If "Settings" selected:**
```json
{
  "question": "Which settings screens?",
  "header": "Settings screens",
  "multiSelect": true,
  "options": [
    {"label": "Profile", "description": "User profile management"},
    {"label": "Preferences", "description": "App preferences and themes"},
    {"label": "Account", "description": "Account security and data"},
    {"label": "Billing", "description": "Payment and subscription"}
  ]
}
```

**If "Admin" selected:**
```json
{
  "question": "Which admin screens?",
  "header": "Admin screens",
  "multiSelect": true,
  "options": [
    {"label": "Users", "description": "User management"},
    {"label": "Roles", "description": "Permissions and roles"},
    {"label": "System", "description": "System configuration"},
    {"label": "Logs", "description": "Audit and activity logs"}
  ]
}
```

### Step 5: Layout Selection

**Use AskUserQuestion (with recommendation based on app_type):**

| App Type | Recommended Layout |
|----------|-------------------|
| SaaS/B2B | Sidebar + Content |
| Consumer | Top Nav + Content |
| E-Commerce | Top Nav + Content |
| Content | Minimal |

```json
{
  "question": "What is your app's primary layout pattern? (Recommended: {RECOMMENDED_LAYOUT})",
  "header": "Layout",
  "multiSelect": false,
  "options": [
    {"label": "Sidebar + Content", "description": "Fixed sidebar with main content area (SaaS, dashboards)"},
    {"label": "Top Nav + Content", "description": "Horizontal navigation bar at top (consumer, e-commerce)"},
    {"label": "Dashboard Grid", "description": "Card-based grid layout for overview screens"},
    {"label": "Minimal", "description": "Clean, centered content (auth flows, content sites)"}
  ]
}
```
→ Store in `context.layout`

### Step 6: Git Persistence Decision

**If no --commit or --gitignore flag and preference is "ask":**

```json
{
  "question": "How should the prototype be handled in git?",
  "header": "Git",
  "multiSelect": false,
  "options": [
    {"label": "Commit (recommended)", "description": "Version control the prototype. Design changes tracked in history."},
    {"label": "Gitignore", "description": "Exclude from git. Regenerate as needed (rapid iteration)."}
  ]
}
```

### Step 7: Generate Prototype Structure

1. **Create directory structure:**
   ```
   design/prototype/
   ├── index.html           # Navigation hub
   ├── theme.yaml           # Theme definition (from questionnaire)
   ├── theme.css            # Generated CSS variables
   ├── base.html            # Shared template all screens inherit
   ├── shared.css           # Common component styles
   ├── state.yaml           # Prototype state and flow
   ├── screens/
   │   ├── auth/
   │   ├── dashboard/
   │   ├── settings/
   │   └── admin/
   ├── components/
   ├── _shared/
   │   ├── navigation.js
   │   └── state-switcher.js
   └── prototype-patterns.md
   ```

2. **Generate theme.yaml** (from context questionnaire):
   - Use template from `.spec-flow/templates/prototype/theme.yaml`
   - Populate with app_type, core_goal, journey, tone, density
   - Map tone to color palette suggestions
   - Set `locked: false` initially

3. **Generate theme.css** (from theme.yaml):
   - Use template from `.spec-flow/templates/prototype/theme.css`
   - Convert OKLCH colors to CSS variables
   - Include typography scale and spacing

4. **Copy shared assets**:
   - Copy `base.html` from `.spec-flow/templates/prototype/base.html`
   - Copy `shared.css` from `.spec-flow/templates/prototype/shared.css`

5. **Generate index.html** (navigation hub):
   - Use template from `.spec-flow/templates/prototype/index.html`
   - Populate with selected screen cards
   - Link to `theme.css` (not tokens.css)
   - Include keyboard navigation (1-9 jump, H hub)
   - Show app context (type, goal, journey) at top

6. **Generate individual screens**:
   - Use `base.html` template structure
   - Create one HTML file per selected screen
   - Include state switching (success, loading, error, empty)
   - Use layout pattern from questionnaire
   - Reference theme.css and shared.css

7. **Create state.yaml**:
   ```yaml
   prototype:
     version: "1.0.0"
     created_at: "[TIMESTAMP]"
     last_updated: "[TIMESTAMP]"
     git_committed: [true|false]
     layout: "[sidebar|topnav|grid|minimal]"

   screens:
     - id: "auth-login"
       path: "screens/auth/login.html"
       category: "Authentication"
       added: "[DATE]"

   components: []

   patterns:
     extracted_at: null
     pattern_file: "prototype-patterns.md"
   ```

5. **Copy shared JS helpers** from `.spec-flow/templates/mockups/_shared/`

### Step 6: Handle Git Persistence

**If commit mode:**
```bash
# Ensure design/prototype/ is NOT in .gitignore
grep -q "design/prototype" .gitignore && sed -i '/design\/prototype/d' .gitignore || true

# Stage and commit
git add design/prototype/
git commit -m "feat(prototype): initialize project-wide clickable prototype

Screens: [LIST]
Layout: [LAYOUT]

Generated by /prototype command"
```

**If gitignore mode:**
```bash
# Add to .gitignore if not present
grep -q "design/prototype" .gitignore || echo "design/prototype/" >> .gitignore
```

### Step 7: Display Summary

```
Prototype Created Successfully!

Location: design/prototype/
Layout: [sidebar|topnav|grid|minimal]
Git: [Committed to git | Added to .gitignore]

Screens Generated ([COUNT]):
  Authentication:
    - login.html
    - signup.html
  Dashboard:
    - overview.html
    - analytics.html
  Settings:
    - profile.html

Next Steps:
1. Open design/prototype/index.html in browser
2. Navigate screens with keyboard (1-9) or clicks
3. Press 'S' to cycle states (success/loading/error/empty)
4. Edit HTML files to iterate on design
5. Run /prototype update to add more screens
6. Start /feature or /epic - prototype will be detected

Press 'H' to return to hub from any screen.
```

---

## Mode: UPDATE

### Step 1: Verify Prototype Exists

```bash
test -f design/prototype/state.yaml || echo "ERROR: No prototype found. Use '/prototype create' first."
```

### Step 2: Read Current State

```bash
cat design/prototype/state.yaml
```

### Step 3: Determine Screens to Add

**If --screens flag provided:**
- Parse comma-separated screen names
- Generate those screens

**Otherwise, use AskUserQuestion:**

```json
{
  "question": "What screens do you want to add to the prototype?",
  "header": "New screens",
  "multiSelect": true,
  "options": [
    {"label": "Authentication screens", "description": "Login, signup, forgot password"},
    {"label": "Dashboard screens", "description": "Overview, analytics, reports"},
    {"label": "Settings screens", "description": "Profile, preferences, billing"},
    {"label": "Admin screens", "description": "Users, roles, system config"},
    {"label": "Custom screens", "description": "Specify custom screen names"}
  ]
}
```

### Step 4: Capture Screen Purpose

**For EACH new screen, ask:**

```json
{
  "question": "What is the primary purpose of {SCREEN_NAME}?",
  "header": "Purpose",
  "multiSelect": false,
  "options": [
    {"label": "Entry/Auth", "description": "Login, signup, onboarding, password reset"},
    {"label": "Overview/Dashboard", "description": "Summary, metrics, navigation hub"},
    {"label": "Create/Edit", "description": "Forms, data entry, configuration"},
    {"label": "Browse/List", "description": "Search, filter, discover items"},
    {"label": "Detail/View", "description": "Single item deep-dive, actions"}
  ]
}
```
→ Store in `screens[].purpose` and `flow.screens[id]`

**Also ask (for flow documentation):**

```json
{
  "question": "What does the user want to accomplish on this screen?",
  "header": "User Goal",
  "multiSelect": false,
  "options": [
    {"label": "Access the app", "description": "Login, authenticate, get started"},
    {"label": "Get an overview", "description": "Understand current state, decide next action"},
    {"label": "Create something", "description": "Add new data, complete a form"},
    {"label": "Find something", "description": "Search, browse, discover"},
    {"label": "Take action", "description": "Edit, delete, process, approve"}
  ]
}
```
→ Store in `flow.screens[id].user_goal`

### Step 5: Generate New Screens

1. **Use theme-consistency skill** to enforce theme variables
2. Use `base.html` template structure
3. Apply content guidelines based on screen purpose (from state.yaml)
4. Update state.yaml with new screen entries
5. Update flow.screens with purpose and user_goal
6. Update index.html to include new screen cards
7. Bump prototype version (minor increment)

**If this is the FIRST screen being generated:**
- Lock theme after screen approval
- Set `prototype.theme_locked: true` in state.yaml

### Step 6: Handle Git

**If prototype is git-committed (from state.yaml):**
```bash
git add design/prototype/
git commit -m "feat(prototype): add [SCREEN_NAMES] screens

Version: [NEW_VERSION]"
```

---

## Mode: STATUS

### Step 1: Check Prototype Exists

```bash
test -f design/prototype/state.yaml || echo "No prototype found. Run '/prototype create' to get started."
```

### Step 2: Read and Display Status

```bash
cat design/prototype/state.yaml
```

**Display formatted output:**

```
Prototype Status
================
Version: 1.2.0
Created: 2025-11-15
Last Updated: 2025-11-27
Git: Committed
Layout: Sidebar + Content

Screens (12 total):
  Authentication (3):
    - login.html
    - signup.html
    - forgot-password.html
  Dashboard (4):
    - overview.html
    - analytics.html
    - activity.html
    - reports.html
  Settings (3):
    - profile.html
    - preferences.html
    - billing.html
  Admin (2):
    - users.html
    - system.html

Components (2 shared):
  - navigation.html
  - sidebar.html

Commands:
  /prototype update    - Add more screens
  /prototype create    - Start fresh (will overwrite)
```

</process>

<success_criteria>
**Create mode:**
- Prototype directory structure created at `design/prototype/`
- Navigation hub (index.html) generated with all selected screens
- Individual screen HTML files generated with state switching
- state.yaml created with screen registry
- Git handled according to user preference
- Summary displayed with next steps

**Update mode:**
- New screens added to existing prototype
- state.yaml updated with new screen entries
- index.html updated with new screen cards
- Version incremented
- Git commit created (if committed mode)

**Status mode:**
- Prototype state displayed accurately
- Screen count and categories shown
- Git status indicated
- Available commands shown
</success_criteria>

<error_handling>
**Prototype already exists (create mode):**
- Display: "Prototype already exists at design/prototype/"
- Suggest: "Use '/prototype update' to add screens or '/prototype status' to view"

**Prototype doesn't exist (update/status mode):**
- Display: "No prototype found"
- Suggest: "Run '/prototype create' to get started"

**Missing design tokens:**
- Display warning but continue
- Use fallback colors in generated HTML
- Suggest: "Run '/init-brand-tokens' for consistent design tokens"

**Git commit fails:**
- Display git error
- Suggest checking git status and resolving conflicts
</error_handling>

<examples>
## Example 1: Create New Prototype

**User runs:** `/prototype create`

**Wizard flow:**
1. Categories: Authentication, Dashboard, Settings
2. Auth screens: Login, Signup
3. Dashboard screens: Overview, Analytics
4. Settings screens: Profile
5. Layout: Sidebar + Content
6. Git: Commit

**Result:**
```
design/prototype/
├── index.html
├── screens/
│   ├── auth/
│   │   ├── login.html
│   │   └── signup.html
│   ├── dashboard/
│   │   ├── overview.html
│   │   └── analytics.html
│   └── settings/
│       └── profile.html
├── _shared/
│   ├── navigation.js
│   └── state-switcher.js
└── state.yaml
```

## Example 2: Update Existing Prototype

**User runs:** `/prototype update --screens admin-users,admin-logs`

**Result:**
- Added: screens/admin/users.html, screens/admin/logs.html
- Updated: index.html, state.yaml
- Version: 1.0.0 → 1.1.0
- Git commit created

## Example 3: Check Status

**User runs:** `/prototype status`

**Output:**
```
Prototype Status
================
Version: 1.1.0
Screens: 7 total
Git: Committed

Run '/prototype update' to add more screens.
```
</examples>
