---
name: prototype
description: Discovery-first prototyping - explore app ideas with zero-risk iteration before committing to roadmap/features
argument-hint: [discover|explore|create|update|status|extract|outcome|lock-theme|unlock-theme|sync-tokens] [exploration-name] [--with-tokens|--skip-tokens] [--to-epic "Epic Name"] [--exploration name] [--adopt|--defer|--scrap]
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash(git:*), Bash(test:*), Bash(node:*), AskUserQuestion, Task, TodoWrite]
version: 11.0
created: 2025-11-27
updated: 2025-12-09
---

# /prototype - Discovery-First Prototyping (Hybrid Pattern)

> **v11.0 Architecture**: Uses hybrid pattern for `discover` and `explore` modes - interactive questions in main context (good UX), prototype generation isolated via Task() (saves ~4-6k tokens).

<context>
**Check these files before proceeding:**
- Prototype state: `design/prototype/state.yaml`
- Design tokens: `design/systems/tokens.json` and `tokens.css`
- Project docs: `docs/project/overview.md`
- User preferences: `.spec-flow/config/user-preferences.yaml`

**Related skills (auto-loaded on demand):**
- `shadcn-integration` - Generates shadcn/ui compatible CSS variables and components.json
- `design-tokens` - OKLCH token generation and WCAG validation
- `theme-consistency` - Enforces token usage across prototype screens
</context>

<architecture>
## Hybrid Pattern (v11.0)

**For `discover` and `explore` modes:**

```
User: /prototype discover
         │
         ▼
┌──────────────────────────────────────────────────────┐
│ MAIN CONTEXT (interactive selection - good UX)       │
│                                                      │
│ 1. Check for existing tokens                         │
│ 2. Palette selection (vibe picker)                   │
│ 3. Vision brainstorm question                        │
│ 4. Screen selection (multiselect)                    │
│ 5. Save selections to temp config                    │
│    → .spec-flow/temp/prototype-selections.yaml       │
└──────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────┐
│ Task(prototype-discover-agent) ← ISOLATED            │
│                                                      │
│ 1. Read selections from temp config                  │
│ 2. Generate theme.yaml from palette                  │
│ 3. Generate theme.css with CSS variables             │
│ 4. Create discovery artifacts (ideas.md, etc)        │
│ 5. Generate HTML for all selected screens            │
│ 6. Generate navigation hub (index.html)              │
│ 7. Update state.yaml                                 │
│ 8. Return summary                                    │
│ 9. EXIT                                              │
└──────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────┐
│ MAIN CONTEXT (results - minimal tokens)              │
│                                                      │
│ 1. Display success summary                           │
│ 2. Show generated screens                            │
│ 3. Display keyboard shortcuts                        │
│ 4. Suggest next steps                                │
└──────────────────────────────────────────────────────┘
```

**For lightweight modes (`status`, `extract`, `outcome`, `lock-theme`, etc.):**
- Run directly in main context (no Task spawning needed)
- These modes are read-heavy with minimal generation
</architecture>

<objective>
**Discovery-first prototyping** - explore app ideas visually before committing to roadmap or features.

**Philosophy**: This is your zero-risk sandbox. Try ideas. Scrap what doesn't work. Nothing here commits you to building anything. The prototype informs your roadmap, not the other way around.

**Workflow Position**:
```
/init-project -> /prototype discover -> /prototype extract --to-epic "Name" -> /epic continue
                                    | OR
                                    -> /roadmap import-from-prototype -> /epic or /feature
```

**Modes**:
- `discover`: Full app exploration at project start, brainstorm screens, zero commitments
- `explore`: **Loop back** - Explore new feature/epic ideas within existing prototype
- `create`: Generate structured prototype (legacy, still works)
- `update`: Add screens to existing prototype
- `status`: Show prototype overview and screen registry
- `extract`: Analyze prototype -> generate discovered-features.md + component-inventory.md
  - `--to-epic "Name"`: One-shot epic creation (extract + create epic workspace)
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
PROTOTYPE DISCOVERY - Zero-risk exploration phase

  This is your sandbox. Try ideas. Scrap what doesn't work.
  Nothing here commits you to building anything.

  Press 'I' on any screen to log an idea.
  Press 'Q' to log a question.
  Press 'X' to scrap current screen.
```

### Step 1: Token Detection and Setup

**Check for existing tokens:**
```bash
test -f design/systems/tokens.json && echo "TOKENS_EXIST=true" || echo "TOKENS_EXIST=false"
```

**If tokens exist:**
```
Found existing design tokens: design/systems/tokens.json
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

### Step 2b: shadcn/ui Style Options (NEW)

**These questions integrate with shadcn/ui component library:**

```json
{
  "question": "shadcn/ui style preset?",
  "header": "Style",
  "multiSelect": false,
  "options": [
    {"label": "Default (Recommended)", "description": "Clean, balanced - shadcn 'default' style"},
    {"label": "New York", "description": "Refined, sophisticated - shadcn 'new-york' style"},
    {"label": "Minimal", "description": "Ultra-clean, lots of whitespace"},
    {"label": "Bold", "description": "Strong visual presence, compact density"}
  ]
}
```

```json
{
  "question": "Menu background style?",
  "header": "Menu Color",
  "multiSelect": false,
  "options": [
    {"label": "Background (Recommended)", "description": "Uses page background - clean and simple"},
    {"label": "Surface", "description": "Elevated card with subtle shadow"},
    {"label": "Primary Tint", "description": "5% wash of your primary color"},
    {"label": "Glass", "description": "Transparent with blur backdrop effect"}
  ]
}
```

```json
{
  "question": "Menu active indicator style?",
  "header": "Menu Accent",
  "multiSelect": false,
  "options": [
    {"label": "Left Border (Recommended)", "description": "3px border on active items"},
    {"label": "Background Highlight", "description": "Full background color change"},
    {"label": "Icon Tint", "description": "Only icon changes to primary color"},
    {"label": "Combined", "description": "Border + subtle background highlight"}
  ]
}
```

```json
{
  "question": "Border radius style?",
  "header": "Radius",
  "multiSelect": false,
  "options": [
    {"label": "None", "description": "Sharp corners - brutalist, stark"},
    {"label": "Small", "description": "4px - minimal, technical"},
    {"label": "Medium (Recommended)", "description": "8px - modern, balanced"},
    {"label": "Large", "description": "12px - friendly, soft"},
    {"label": "Full", "description": "Pill-shaped - playful"}
  ]
}
```

**Vibe → shadcn Style Mapping:**

| Vibe | shadcn Style | Density | Menu Color | Menu Accent |
|------|--------------|---------|------------|-------------|
| Professional | default | comfortable | background | border |
| Modern SaaS | new-york | comfortable | surface | combined |
| Friendly | default | spacious | primaryTint | background |
| Bold | new-york | compact | glass | combined |
| Minimal | default | spacious | background | iconTint |

**If user selects Custom for any option, prompt for specific values.**

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

  # Component defaults (from shadcn questions)
  components:
    radius_default: "[RADIUS]"  # none | sm | md | lg | full

    # Menu theming
    menu:
      color: "[MENU_COLOR]"    # background | surface | primaryTint | glass
      accent: "[MENU_ACCENT]"  # border | background | iconTint | combined

  # shadcn/ui integration
  shadcn:
    style: "[STYLE_PRESET]"         # default | new-york | minimal | bold
    icon_library: "lucide"          # Default for prototypes
    theme_mode: "system"            # light | dark | system | both
    rsc: true
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

### Step 5: Save Selections and Spawn Generation Agent (v11.0 Hybrid)

**Save all selections to temp config for isolated agent:**

```yaml
# .spec-flow/temp/prototype-selections.yaml
created: "${TIMESTAMP}"
mode: "discover"

palette:
  source: "${PALETTE_SOURCE}"  # quick-picker | existing-tokens | skip
  vibe: "${SELECTED_VIBE}"     # Professional | Modern SaaS | Friendly | Bold | Minimal | Custom
  custom_primary: null         # Only if Custom selected

# shadcn/ui Integration (NEW)
shadcn:
  style_preset: "${STYLE_PRESET}"      # default | new-york | minimal | bold
  menu_color: "${MENU_COLOR}"          # background | surface | primaryTint | glass
  menu_accent: "${MENU_ACCENT}"        # border | background | iconTint | combined
  border_radius: "${BORDER_RADIUS}"    # none | sm | md | lg | full
  icon_library: "lucide"               # Default to lucide for prototypes

vision:
  category: "${VISION_CATEGORY}"
  custom_text: "${CUSTOM_VISION}"

screens:
  selected: ${SELECTED_SCREENS}  # Array from multiselect
  additional: "${ADDITIONAL_SCREENS}"  # User-typed custom screens
```

**Spawn isolated agent for prototype generation:**

```javascript
// Save selections to temp config (done above)
const selectionsFile = ".spec-flow/temp/prototype-selections.yaml";

// Spawn isolated agent for heavy HTML generation
const agentResult = await Task({
  subagent_type: "prototype-discover-agent",
  prompt: `
    Generate discovery prototype from user selections:

    Selections file: ${selectionsFile}
    Mode: discover

    Read selections from temp config, generate all prototype files:
    - theme.yaml and theme.css from palette
    - index.html navigation hub
    - HTML screens for all selected screens
    - Discovery artifacts (ideas.md, questions.md)
    - state.yaml registry

    Return structured phase_result with artifacts created.
  `
});

const result = agentResult.phase_result;
```

**Handle agent result:**

```javascript
// Agent completed successfully
if (result.status === "completed") {
  console.log(`✅ Discovery prototype generated`);

  // Display metrics
  if (result.metrics) {
    console.log(`\n📊 Metrics:`);
    console.log(`   Screens: ${result.metrics.screens_created}`);
    console.log(`   Theme: ${result.metrics.vibe} (${result.metrics.theme_source})`);
  }

  // Display artifacts
  if (result.artifacts_created) {
    console.log(`\n📄 Files created:`);
    result.artifacts_created
      .filter(a => a.type === "screen")
      .forEach(a => console.log(`   - ${a.path}`));
  }
}

// Agent had warnings
if (result.warnings) {
  console.log(`\n⚠️ Warnings:`);
  result.warnings.forEach(w => console.log(`   - ${w.message}`));
}
```

### Step 6: Display Discovery Summary

```
Discovery Prototype Created!

  Location: design/prototype/
  Palette: [VIBE] (from quick picker)
  Screens: [COUNT] initial screens

  Generated screens:
    - dashboard.html
    - list.html
    - detail.html
    - settings.html

  KEYBOARD SHORTCUTS (on any screen)

  1-9     Jump to screen by number
  H       Return to hub
  S       Cycle states (success/loading/error/empty)
  I       Log an idea (saved to _discovery/ideas.md)
  Q       Log a question (saved to _discovery/questions.md)
  X       Scrap current screen (moves to _discovery/scrapped/)

  NEXT STEPS:
  1. Open design/prototype/index.html in your browser
  2. Explore, iterate, scrap and retry - zero consequences!
  3. When ready: /prototype extract -> analyze what you discovered
  4. Then: /roadmap import-from-prototype -> plan what to build
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
  _explorations/                    # NEW: Exploration sandboxes
    [exploration-name]/
      context.md                # Why we're exploring this
      screens/
        screen-1.html
        screen-2.html
      ideas.md                  # Ideas specific to this exploration
      questions.md              # Questions for this exploration
      outcome.md                # Decision: adopt, defer, or scrap
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
Exploration Started: [exploration-name]

  Location: design/prototype/_explorations/[exploration-name]/
  Using theme: [locked/unlocked] (from main prototype)
  Screens: [N] exploration screens

  Generated:
    - screens/notification-list.html
    - screens/notification-detail.html
    - screens/notification-settings.html

  EXPLORATION SHORTCUTS:
    Same as main prototype (1-9, S, I, Q, X)

  WHEN DONE:
    /prototype outcome [exploration-name]
      -> Decide: adopt (merge to main), defer (keep for later), or scrap

  ADOPT FLOW:
    /prototype outcome [name] --adopt
    /prototype extract --exploration [name]
    /roadmap import-from-prototype --exploration [name]
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
Prototype Extraction Complete!

  Analyzed: [N] screens, [M] components

  Features Discovered:
    - User Authentication (Feature)
    - Dashboard Overview (Feature)
    - Task Management (Epic)
    - Settings & Profile (Feature)

  Components to Build:
    - Button (34 occurrences) - Must build
    - Card (18 occurrences) - Must build
    - Input (12 occurrences) - Must build
    - Avatar (8 occurrences) - Should build

  Ideas Captured: [N]
  Questions Open: [M]

  Generated:
    - design/prototype/discovered-features.md
    - design/prototype/component-inventory.md

  NEXT STEP:
    /roadmap import-from-prototype
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
Theme Locked!

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
Tokens Synced!

  Prototype now uses production tokens from:
    design/systems/tokens.json

  Changes:
    - Primary color updated (was quick-picker, now brand-approved)
    - Added 15 additional semantic tokens
    - Neutral scale aligned with production

  Prototype-specific overrides preserved:
    - experimental.drag_highlight
    - experimental.drop_zone
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
