---
description: Manage design inspirations with interactive wizard for visual consistency
---

Manage design inspirations: $ARGUMENTS

## MODE DETECTION

**If design-inspirations.md is empty or only has template placeholders:**
- Launch interactive Q&A wizard (see INTERACTIVE SETUP below)

**If $ARGUMENTS provided:**
- Execute action: $ARGUMENTS (see ACTIONS below)

**If design-inspirations.md has entries:**
- Ask: "Add new inspiration, update existing, or remove?"

---

## INTERACTIVE SETUP

**Purpose**: First-time setup - guide users through adding design references for visual consistency.

**Workflow**:

1. **Welcome message**:
   ```
   Let's curate your design inspirations!

   Design inspirations help maintain visual consistency by referencing:
   - Color palettes and typography
   - Component styles and patterns
   - Layout and spacing systems
   - Animation and interaction patterns

   I'll help you add 1-3 reference sites/apps to get started.
   ```

2. **Project context** (auto-detect):
   - Read constitution.md to understand project type
   - Suggest relevant categories:
     - Web App: SaaS dashboards, marketing sites
     - Mobile: iOS/Android apps
     - API Docs: Developer portals
     - Design System: Component libraries

3. **Add first inspiration**:
   - "What site or app should we reference for design inspiration?"
   - "What's the URL?" (validate format)
   - "What aspects inspire you?"
     - Options: Colors, Typography, Layout, Components, Animations, All
     - Multi-select allowed

4. **Capture details**:
   - "What specific elements stand out? (e.g., 'Gradient buttons', 'Card hover effects')"
   - Auto-extract if user provides detailed description
   - "Any color codes or design tokens to note? (optional)"
   - Format: `#RRGGBB` or `--token-name: value`

5. **Screenshot recommendation**:
   ```
   💡 Pro tip: Add screenshots to .spec-flow/memory/visuals/inspirations/

   Would you like me to:
   A) Remind you to add screenshots later
   B) Create visuals folder structure now
   C) Skip
   ```

6. **Add more inspirations** (repeat 2-4 times):
   - "Add another inspiration? (Y/n)"
   - If yes, repeat steps 3-5
   - If no, continue to summary

7. **Show summary and guidance**:
   ```
   ✓ Added N design inspirations:
   1. [Site Name] - Colors, Typography
   2. [Site Name] - Components, Layout

   Next steps:
   - Reference these during /spec-flow for consistent visual requirements
   - Update with new finds: /design-inspiration add [url]
   - Add screenshots to: .spec-flow/memory/visuals/inspirations/
   ```

---

## INITIALIZE

Check if design-inspirations.md exists, create from template if missing:
```bash
if [ ! -f ".spec-flow/memory/design-inspirations.md" ]; then
  mkdir -p .spec-flow/memory
  cp .spec-flow/templates/design-inspirations-template.md .spec-flow/memory/design-inspirations.md
fi
```

## CONTEXT

**Location**: `.spec-flow/memory/design-inspirations.md`
**Format**: Markdown with categorized entries

**Entry structure:**
```markdown
### [Site/App Name]
- **URL**: https://example.com
- **Inspiration**: Colors, Typography, Layout, Components, Animations
- **Notes**: [Specific elements that inspire]
- **Design Tokens**: [Optional color codes, spacing values]
- **Screenshot**: [Optional path to visual reference]
- **Added**: YYYY-MM-DD
```

**Categories:**
- **Primary References** - Main design direction
- **Component Inspiration** - Specific UI patterns
- **Color & Typography** - Visual identity
- **Interaction Patterns** - Animations and micro-interactions
- **Layout Systems** - Grid and spacing

## ACTIONS

### 1. ADD INSPIRATION

**Parse natural language:**
- Extract: Name, URL, inspiration aspects, notes
- Validate URL format
- Auto-categorize based on aspects

**Interactive flow:**
```
Adding design inspiration...

Site/App name: [extract from user or URL]
URL: [validate https://...]
Inspiration aspects: (Colors, Typography, Layout, Components, Animations, All)
Specific elements: [free text]
Design tokens (optional): [color codes, values]
```

**Add to file:**
- Append to appropriate category
- Add timestamp
- Update last modified date
- Create visuals folder if screenshot path provided

### 2. UPDATE INSPIRATION

**Parse**: "update [name]" or "edit [name]"

**Execute:**
- Find entry by name (fuzzy match)
- Show current values
- Ask what to update:
  - URL
  - Inspiration aspects
  - Notes
  - Design tokens
  - Screenshot path
- Update and re-save

### 3. REMOVE INSPIRATION

**Parse**: "remove [name]" or "delete [name]"

**Execute:**
- Find entry by name
- Confirm: "Remove [name]? (y/N)"
- Remove from file
- Update last modified date

### 4. SEARCH INSPIRATIONS

**Parse**: Keywords, aspect filter (colors, typography, etc.)

**Execute:**
- Find matches across all entries
- Show: name, URL, aspects, notes
- Group by category

### 5. EXTRACT TO SPEC

**Parse**: "extract for spec" or "use in spec [slug]"

**Execute:**
- Compile relevant inspirations for a spec
- Format as visual requirements:
  ```
  ## Visual Requirements

  **Design References:**
  - [Site 1]: Color palette, card components
  - [Site 2]: Typography hierarchy, button styles

  **Color Tokens:**
  - Primary: #RRGGBB (from Site 1)
  - Accent: #RRGGBB (from Site 2)
  ```
- Copy to clipboard or append to spec visuals/README.md

### 6. SUGGEST INSPIRATIONS

**Parse**: "suggest" or "recommend [category]"

**Execute:**
- Read constitution.md for project type
- Read roadmap.md for target users
- WebSearch for relevant design trends:
  - "best [project-type] UI design 2025"
  - "[industry] design inspiration"
- Present 5-8 curated suggestions:
  ```
  Based on your [project-type] project, here are design inspirations:

  1. [Site Name] - [URL]
     Why: [Relevance to your project]
     Aspects: [What to focus on]

  2. [Site Name] - [URL]
     Why: [Relevance]

  Which to add? (1,2,3, all, skip)
  ```

## INTEGRATION

**During /spec-flow:**
- Auto-load design-inspirations.md
- Include in visuals/README.md template
- Reference in visual requirements section

**During /plan:**
- Extract design tokens for component planning
- Reference interaction patterns for UX planning

**During /implement:**
- Link to inspirations in component tasks
- Include screenshot paths for developer reference

## RETURN

**Concise summary:**
```
✓ Added: [Name] ([URL])
  Inspiration: [Aspects]
  Category: [Primary/Component/Color/etc]

✓ Design Inspirations: N total
  - Primary: N
  - Components: N
  - Colors: N

→ Next: Reference during /spec-flow or add screenshots to visuals/
```

**If suggesting:**
```
✓ Found N design inspirations for [project-type]

Which to add? (1,2,3, all, skip)
[Waiting for selection]
```

## CONSTRAINTS

- Keep total inspirations focused (10-15 max)
- Archive outdated inspirations to separate section
- Validate all URLs before adding
- Encourage screenshot documentation
- Update design-inspirations.md last modified date on changes
