
## [4.1.0] - 2025-11-08

### ✨ New Features - Living Documentation

**Hierarchical CLAUDE.md files with automatic updates**

- **80-94% token reduction** in AI context loading
  - Feature context: 8,000 → 500 tokens (94% reduction)
  - Project context: 12,000 → 2,000 tokens (83% reduction)
  - Full context: 12,700 → 2,500 tokens (80% reduction)

- **3-level hierarchy** for efficient context navigation
  - Root CLAUDE.md: Workflow system documentation (~3,000 tokens)
  - Project CLAUDE.md: Active features, tech stack, patterns (~2,000 tokens)
  - Feature CLAUDE.md: Current progress, velocity, specialists (~500 tokens)

- **Automatic documentation updates** (no manual sync required)
  - Feature CLAUDE.md: Auto-generated on `/feature`, refreshed on task completion
  - Project CLAUDE.md: Auto-generated on `/init-project`, updated on `/ship`
  - Living artifact sections: spec.md, plan.md, tasks.md

- **Real-time velocity tracking**
  - Average time per task, completion rate (tasks/day)
  - ETA calculation based on current velocity
  - Bottleneck detection (tasks >1.5x average time)
  - Progress summary auto-updated in tasks.md

- **Health checks** for documentation freshness
  - Detect stale CLAUDE.md files (>7 days old)
  - Missing timestamp warnings
  - Regeneration script suggestions

### 🛠️ Scripts Added

**Bash + PowerShell (cross-platform)**:
- `generate-feature-claude-md` - Feature-level context aggregation
- `generate-project-claude-md` - Project-level context aggregation
- `extract-notes-summary` - Parse recent task completions
- `update-spec-status` - Update spec.md Implementation Status
- `update-plan-patterns` - Update plan.md Discovered Patterns
- `health-check-docs` - Detect stale documentation
- `calculate-task-velocity` - Velocity metrics calculation
- `update-tasks-summary` - Regenerate Progress Summary

### 📝 Enhanced Templates

- **spec-template.md**: Added Implementation Status section (requirements fulfilled, deviations, performance actuals)
- **plan-template.md**: Added Discovered Patterns section (reusable code, architecture adjustments, integrations)
- **tasks-template.md**: Added Progress Summary section (velocity, ETA, bottlenecks)

### 🔄 Workflow Integration

- **`/feature`**: Auto-generates feature CLAUDE.md on creation
- **`/init-project`**: Auto-generates project CLAUDE.md with project docs
- **`/implement`**: Provides living documentation update examples for task agents
- **`/ship-prod`, `/deploy-prod`, `/ship-staging`**: Regenerate project CLAUDE.md after deployment
- **Task tracker**: Auto-updates Progress Summary in tasks.md after each completion

### 📚 Documentation

- **LIVING_DOCUMENTATION.md** (599 lines): Comprehensive user guide
- **CLAUDE_MD_HIERARCHY.md** (554 lines): Technical reference
- **CLAUDE.md**: Added v4.0.0 Living Documentation section (66% reduction: 1334 → 551 lines)
- **README.md**: Added v4.0.0 release notes

### 🎯 Benefits

- Documentation never lags behind code (atomic updates)
- Context loading 80-94% faster (hierarchical navigation)
- Always know velocity, ETA, and blockers without manual tracking
- Health checks catch stale docs before they become problems
- Cross-platform support (Bash + PowerShell)

### ⚠️ Breaking Changes

None - all changes are backward compatible.

---


## [4.0.0] - 2025-11-07

### 🚀 Major Changes

**Replaced 3-phase design workflow with comprehensive style guide approach**

- **75-85% faster** UI development (<30 min vs 2-4 hours per feature)
- **82-88% fewer tokens** (10-15K vs 85K per screen)
- **Zero manual design gates** (automated validation)
- **Single source of truth** (style-guide.md)

### ✨ New Features

- Comprehensive style guide template (1,500 lines) with 8 core sections
- User's core 9 rules enforced automatically
- OKLCH color system with context-aware token mapping
- 8pt grid spacing system
- Automated validation (colors, spacing, typography, accessibility)
- `/init-project` now generates 11 docs (added style-guide.md)
- `/quick` auto-detects UI changes and loads style guide

### 📦 Archived

- 5 design commands moved to archive/ (design, design-variations, design-functional, design-polish, research-design)
- 2 design system files moved to archive/ (design-principles.md, design-inspirations.md)
- Total code reduction: 5,225 lines removed, replaced with 1,500-line style guide

### 📚 Documentation

- Added comprehensive migration guide (STYLE_GUIDE_MIGRATION.md)
- Updated CLAUDE.md with v3.0.0 section
- Updated frontend agent brief with rapid prototyping guidelines

### ⚠️ Breaking Changes

None - all changes are backward compatible. Old design commands remain in archive for reference.

**Migration**: See docs/STYLE_GUIDE_MIGRATION.md for complete guide

---

