---
name: prototype
description: Create and manage project-wide clickable HTML prototype for holistic design iteration before feature implementation
argument-hint: [create|update|status] [--commit|--gitignore] [--screens screen1,screen2]
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash(git:*), AskUserQuestion, TodoWrite]
version: 1.0
created: 2025-11-27
---

# /prototype - Project-Wide Clickable Prototype

<context>
**Git Root**: !`git rev-parse --show-toplevel 2>$null || echo "."`

**Prototype Status**: !`test -f design/prototype/state.yaml && echo "exists" || echo "missing"`

**Design Tokens**: !`test -f design/systems/tokens.css && echo "available" || echo "missing"`

**Project Docs**: !`test -f docs/project/overview.md && echo "initialized" || echo "missing"`

**User Preference (git)**: !`yq eval '.prototype.git_persistence // "ask"' .spec-flow/config/user-preferences.yaml 2>/dev/null || echo "ask"`
</context>

<objective>
Create and manage a project-wide HTML prototype in `design/prototype/` for holistic design iteration.

**Purpose**: Unlike per-feature mockups (`specs/NNN/mockups/`), the prototype provides:
- Complete app navigation hub showing all screens
- Consistent themes and design patterns across features
- Early stakeholder design review before any implementation
- Foundation for per-feature mockups during `/tasks --ui-first`

**Modes**:
- `create`: Generate new prototype with screen questionnaire
- `update`: Add screens to existing prototype
- `status`: Show prototype overview and screen registry

**Git Persistence**:
- `--commit`: Add prototype to git (recommended for design assets)
- `--gitignore`: Exclude from git (rapid iteration)
- Default: Use preference or prompt user

**When to use**: After `/init-project`, before first `/feature` or `/epic` with UI components.
</objective>

## Anti-Hallucination Rules

1. **Never generate screens without user input**
   - Always ask about screen categories and navigation structure
   - Don't assume app structure

2. **Always verify tokens.css exists before referencing**
   - If missing, warn user and suggest `/init-brand-tokens` first
   - Use fallback colors in templates if tokens unavailable

3. **Read state.yaml before claiming status**
   - Quote actual screen registry
   - Report real last_updated timestamp

4. **Check prototype existence before operations**
   - `create`: Fail if prototype exists (use `update` instead)
   - `update`: Fail if prototype doesn't exist (use `create` instead)
   - `status`: Fail gracefully with "No prototype found" message

---

<process>

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

### Step 2: Screen Category Questionnaire

**Use AskUserQuestion (Round 1 - Categories):**

```json
{
  "question": "What screen categories does your app need?",
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

### Step 3: Layout Questionnaire

**Use AskUserQuestion (Round 3 - Layout):**

```json
{
  "question": "What is your app's primary layout pattern?",
  "header": "Layout",
  "multiSelect": false,
  "options": [
    {"label": "Sidebar + Content", "description": "Fixed sidebar with main content area (most common)"},
    {"label": "Top Nav + Content", "description": "Horizontal navigation bar at top"},
    {"label": "Dashboard Grid", "description": "Card-based grid layout for dashboards"},
    {"label": "Minimal", "description": "Clean, centered content (marketing sites, auth flows)"}
  ]
}
```

### Step 4: Git Persistence Decision

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

### Step 5: Generate Prototype Structure

1. **Create directory structure:**
   ```
   design/prototype/
   ├── index.html
   ├── screens/
   │   ├── auth/
   │   ├── dashboard/
   │   ├── settings/
   │   └── admin/
   ├── components/
   ├── _shared/
   │   ├── navigation.js
   │   └── state-switcher.js
   ├── state.yaml
   └── prototype-patterns.md
   ```

2. **Generate index.html** (navigation hub):
   - Use template from `.spec-flow/templates/prototype/index.html`
   - Populate with selected screen cards
   - Link to `design/systems/tokens.css`
   - Include keyboard navigation (1-9 jump, H hub)

3. **Generate individual screens**:
   - Use template from `.spec-flow/templates/prototype/screen.html`
   - Create one HTML file per selected screen
   - Include state switching (success, loading, error, empty)
   - Use layout pattern from questionnaire

4. **Create state.yaml**:
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

### Step 4: Generate New Screens

1. Create HTML files for each new screen
2. Update state.yaml with new screen entries
3. Update index.html to include new screen cards
4. Bump prototype version (minor increment)

### Step 5: Handle Git

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
