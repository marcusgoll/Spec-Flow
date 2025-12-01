---
name: init-preferences
description: Interactive wizard to configure user preferences for command defaults and behavior
argument-hint: [--reset] (optional flag to reset to defaults)
allowed-tools: [Read, Write, AskUserQuestion]
version: 1.0
created: 2025-11-20
---

<objective>
Guide users through interactive preference configuration to customize Spec-Flow command defaults and behavior.

**What it configures:**
- Command default modes (/epic, /tasks, /init-project, /run-prompt)
- UI preferences (usage stats, last-used recommendations)
- Automation behavior (CI/CD defaults)
- Git worktree preferences (parallel development)
- Prototype workflow preferences
- E2E and visual regression testing (v10.4)
- Database migration safety (v10.5)
- Perpetual learning system

**Output:**
- Creates/updates `.spec-flow/config/user-preferences.yaml`
- Provides configuration summary
- Shows example commands using new preferences

**Flags:**
- `--reset`: Reset all preferences to defaults (interactive confirmation)
</objective>

<context>
Existing preferences: @.spec-flow/config/user-preferences.yaml
Preference schema: @.spec-flow/config/user-preferences-schema.yaml
</context>

<process>
### Step 0: Check for Reset Flag

**If $ARGUMENTS contains "--reset":**

1. Read existing preferences to show what will be reset
2. Use AskUserQuestion to confirm:
   ```
   Question: "Reset all preferences to defaults?"
   Options:
     - "Yes, reset everything" - All preferences will be set to defaults
     - "No, keep current preferences" - Cancel reset operation
   ```

3. If confirmed:
   - Copy `.spec-flow/config/user-preferences.example.yaml` to `.spec-flow/config/user-preferences.yaml`
   - Display: "✓ Preferences reset to defaults"
   - End command

4. If cancelled: End command

### Step 1: Welcome and Introduction

Display welcome message:

```
╔════════════════════════════════════════════════════════════════╗
║  Spec-Flow Preference Configuration Wizard                     ║
╚════════════════════════════════════════════════════════════════╝

This wizard will help you configure default behavior for Spec-Flow commands.

Your preferences are saved to: .spec-flow/config/user-preferences.yaml

You can always:
- Re-run this wizard to update preferences
- Edit the config file directly
- Override preferences with command-line flags
- Reset with: /init-preferences --reset

Let's get started! 🚀
```

### Step 2: Command Preferences (Round 1 - Epic & Tasks)

**Use AskUserQuestion with 2 questions:**

**Question 1: Epic Command Default Mode**
```json
{
  "question": "What default mode should /epic use?",
  "header": "/epic mode",
  "multiSelect": false,
  "options": [
    {
      "label": "Interactive (recommended for new users)",
      "description": "Pause at spec review and plan review for manual approval. Safer for learning the workflow."
    },
    {
      "label": "Auto (recommended for experienced users)",
      "description": "Skip all prompts and run until blocker. Faster for experienced users who trust the workflow."
    }
  ]
}
```

**Question 2: Tasks Command Default Mode**
```json
{
  "question": "What default mode should /tasks use?",
  "header": "/tasks mode",
  "multiSelect": false,
  "options": [
    {
      "label": "Standard (recommended for most projects)",
      "description": "Generate TDD tasks for direct implementation. Best for API-heavy or backend-focused features."
    },
    {
      "label": "UI-first (recommended for design-heavy projects)",
      "description": "Generate HTML mockups first, then implementation tasks. Best for UI-heavy features requiring design approval."
    }
  ]
}
```

### Step 3: Command Preferences (Round 2 - Init-Project & Run-Prompt)

**Use AskUserQuestion with 2 questions:**

**Question 3: Init-Project Command Default Mode**
```json
{
  "question": "What default mode should /init-project use?",
  "header": "/init-project mode",
  "multiSelect": false,
  "options": [
    {
      "label": "Interactive (recommended)",
      "description": "Run questionnaire (15-48 questions depending on --with-design). Best for most users."
    },
    {
      "label": "CI (for automation only)",
      "description": "Non-interactive mode using environment variables. Only use if you're automating project initialization in CI/CD."
    }
  ]
}
```

**Question 4: Should /init-project include design system by default?**
```json
{
  "question": "Include design system setup (--with-design) by default?",
  "header": "Design system",
  "multiSelect": false,
  "options": [
    {
      "label": "No (recommended for most projects)",
      "description": "Skip design system setup. You can always add it later with /init-project --with-design --update."
    },
    {
      "label": "Yes (for design-focused projects)",
      "description": "Always include design tokens, brand guidelines, and accessibility standards. Adds ~30 questions to initialization."
    }
  ]
}
```

### Step 4: Command Preferences (Round 3 - Run-Prompt)

**Use AskUserQuestion with 1 question:**

**Question 5: Run-Prompt Command Default Strategy**
```json
{
  "question": "What execution strategy should /run-prompt use for multiple prompts?",
  "header": "/run-prompt strategy",
  "multiSelect": false,
  "options": [
    {
      "label": "Auto-detect (recommended)",
      "description": "Analyze prompt dependencies and choose parallel or sequential automatically. Safest and usually fastest."
    },
    {
      "label": "Parallel (fast but risky)",
      "description": "Always run prompts simultaneously. Faster but can cause conflicts if prompts modify the same files."
    },
    {
      "label": "Sequential (safe but slow)",
      "description": "Always run prompts one-by-one. Slowest but guarantees no conflicts."
    }
  ]
}
```

### Step 5: UI Preferences

**Use AskUserQuestion with 2 questions:**

**Question 6: Show Usage Statistics**
```json
{
  "question": "Show usage statistics in command prompts?",
  "header": "Usage stats",
  "multiSelect": false,
  "options": [
    {
      "label": "Yes (recommended)",
      "description": "Display 'used 8/10 times' in mode selection prompts. Helps you see your own patterns."
    },
    {
      "label": "No (minimal UI)",
      "description": "Hide usage statistics. Cleaner but less informative."
    }
  ]
}
```

**Question 7: Recommend Last-Used Option**
```json
{
  "question": "Mark last-used option with ⭐ in prompts?",
  "header": "Last-used marker",
  "multiSelect": false,
  "options": [
    {
      "label": "Yes (recommended)",
      "description": "Show ⭐ next to your most recent choice. Makes it easy to repeat common workflows."
    },
    {
      "label": "No (treat all options equally)",
      "description": "Don't highlight any option. All choices appear the same."
    }
  ]
}
```

### Step 6: Automation Preferences

**Use AskUserQuestion with 1 question:**

**Question 8: CI Mode Default**
```json
{
  "question": "Is this primarily used in CI/CD automation?",
  "header": "Automation mode",
  "multiSelect": false,
  "options": [
    {
      "label": "No (interactive use, recommended)",
      "description": "Normal interactive mode. Commands will prompt for input when needed."
    },
    {
      "label": "Yes (CI/CD only)",
      "description": "Default to non-interactive mode. All commands assume --no-input. Only set this for fully automated environments."
    }
  ]
}
```

### Step 7: Git Worktree Preferences

**Use AskUserQuestion with 2 questions:**

**Question 9: Auto-Create Worktrees**
```json
{
  "question": "Automatically create git worktrees for epics/features?",
  "header": "Worktrees",
  "multiSelect": false,
  "options": [
    {
      "label": "No (use regular branches, recommended)",
      "description": "Use standard git branches. Simpler but can't run multiple features in parallel."
    },
    {
      "label": "Yes (enable parallel development)",
      "description": "Create git worktrees automatically. Allows multiple Claude Code instances to work on different features simultaneously."
    }
  ]
}
```

**Question 10: Cleanup Worktrees After Finalize**
```json
{
  "question": "Automatically cleanup worktrees after /finalize?",
  "header": "Cleanup",
  "multiSelect": false,
  "options": [
    {
      "label": "Yes (recommended)",
      "description": "Remove worktrees when features are finalized. Keeps workspace clean."
    },
    {
      "label": "No (keep for review)",
      "description": "Keep worktrees after finalize. Useful if you want to review completed work."
    }
  ]
}
```

### Step 8: Perpetual Learning System

**Use AskUserQuestion with 2 questions:**

**Question 11: Enable Perpetual Learning**
```json
{
  "question": "Enable perpetual learning system?",
  "header": "Learning",
  "multiSelect": false,
  "options": [
    {
      "label": "Yes (recommended)",
      "description": "Learn from patterns and continuously improve workflow efficiency. Learnings stored locally and committed to git."
    },
    {
      "label": "No (disable learning)",
      "description": "Disable all learning features. Workflow won't adapt to project-specific patterns."
    }
  ]
}
```

**Question 12: Allow CLAUDE.md Optimization**
```json
{
  "question": "Allow CLAUDE.md optimization from learnings?",
  "header": "CLAUDE.md tweaks",
  "multiSelect": false,
  "options": [
    {
      "label": "Yes, with approval (recommended)",
      "description": "Allow system to suggest CLAUDE.md improvements based on learnings. You must explicitly approve all changes."
    },
    {
      "label": "No (never modify CLAUDE.md)",
      "description": "Never suggest CLAUDE.md changes. Learning system will only apply low-risk patterns."
    }
  ]
}
```

### Step 8.5: Prototype Workflow Preferences

**Use AskUserQuestion with 1 question:**

**Question 13: Prototype Git Persistence**
```json
{
  "question": "How should the project prototype be handled in git?",
  "header": "Prototype",
  "multiSelect": false,
  "options": [
    {
      "label": "Commit (recommended for design-focused projects)",
      "description": "Version control the prototype. Design changes are tracked in git history."
    },
    {
      "label": "Gitignore (for rapid iteration)",
      "description": "Exclude prototype from git. Regenerate as needed during design exploration."
    },
    {
      "label": "Ask each time",
      "description": "Prompt when creating prototype. Decide on a case-by-case basis."
    }
  ]
}
```

### Step 8.6: E2E and Visual Regression Testing (v10.4)

**Use AskUserQuestion with 2 questions:**

**Question 14: Enable E2E Visual Testing**
```json
{
  "question": "Enable E2E and visual regression testing during /optimize?",
  "header": "E2E/Visual",
  "multiSelect": false,
  "options": [
    {
      "label": "Yes, blocking (recommended)",
      "description": "Run Playwright E2E tests with visual screenshots. Failures block deployment. Best for UI-heavy projects."
    },
    {
      "label": "Yes, warning only",
      "description": "Run tests but only warn on failures. Deployment continues. Use when establishing baselines."
    },
    {
      "label": "No (disable Gate 7)",
      "description": "Skip E2E and visual testing entirely. Use for API-only or backend projects."
    }
  ]
}
```

**Question 15: Visual Regression Threshold**
```json
{
  "question": "What pixel difference threshold for visual regression?",
  "header": "Threshold",
  "multiSelect": false,
  "options": [
    {
      "label": "Strict (5%)",
      "description": "Catch subtle visual changes. May have false positives from anti-aliasing. Best for design-critical UIs."
    },
    {
      "label": "Normal (10%, recommended)",
      "description": "Balance between catching real issues and tolerating rendering differences. Works well for most projects."
    },
    {
      "label": "Lenient (20%)",
      "description": "Only catch significant visual changes. Fewer false positives but may miss subtle regressions."
    }
  ]
}
```

### Step 8.7: Database Migration Safety (v10.5)

**Use AskUserQuestion with 2 questions:**

**Question 16: Migration Enforcement Strictness**
```json
{
  "question": "How should pending migrations be handled during /implement?",
  "header": "Migrations",
  "multiSelect": false,
  "options": [
    {
      "label": "Blocking (recommended)",
      "description": "Stop implementation if pending migrations detected. Safest option to prevent schema mismatches."
    },
    {
      "label": "Warning",
      "description": "Log warning but continue execution. Use when you know what you're doing."
    },
    {
      "label": "Auto-apply (CI/CD only)",
      "description": "Automatically run migrations before implementation. Only use in fully automated pipelines."
    }
  ]
}
```

**Question 17: Migration Detection Sensitivity**
```json
{
  "question": "How sensitive should migration detection be?",
  "header": "Sensitivity",
  "multiSelect": false,
  "options": [
    {
      "label": "High (2+ keywords)",
      "description": "More sensitive - detect migrations earlier. May have more false positives. Use for critical data projects."
    },
    {
      "label": "Normal (3+ keywords, recommended)",
      "description": "Balanced detection. Triggers on 'store', 'persist', 'table', 'column', etc. Good for most projects."
    },
    {
      "label": "Low (5+ keywords)",
      "description": "Less sensitive - fewer false positives. May miss some migrations. Use for projects with few schema changes."
    }
  ]
}
```

### Step 9: Build Configuration Object

**Map answers to preference structure:**

```javascript
// Map user-friendly answers to config values
const preferences = {
  commands: {
    epic: {
      default_mode: answer1.includes('Auto') ? 'auto' : 'interactive'
    },
    tasks: {
      default_mode: answer2.includes('UI-first') ? 'ui-first' : 'standard'
    },
    'init-project': {
      default_mode: answer3.includes('Interactive') ? 'interactive' : 'ci',
      include_design: answer4.includes('Yes') ? true : false
    },
    'run-prompt': {
      default_strategy: answer5.includes('Auto-detect') ? 'auto-detect'
                      : answer5.includes('Parallel') ? 'parallel'
                      : 'sequential'
    }
  },
  automation: {
    auto_approve_minor_changes: false,  // Always false for now
    ci_mode_default: answer8.includes('Yes') ? true : false
  },
  ui: {
    show_usage_stats: answer6.includes('Yes') ? true : false,
    recommend_last_used: answer7.includes('Yes') ? true : false
  },
  worktrees: {
    auto_create: answer9.includes('Yes') ? true : false,
    cleanup_on_finalize: answer10.includes('Yes') ? true : false
  },
  prototype: {
    git_persistence: answer13.includes('Commit') ? 'commit'
                   : answer13.includes('Gitignore') ? 'gitignore'
                   : 'ask'
  },
  e2e_visual: {
    enabled: !answer14.includes('No'),
    failure_mode: answer14.includes('blocking') ? 'blocking' : 'warning',
    threshold: answer15.includes('5%') ? 0.05
             : answer15.includes('20%') ? 0.20
             : 0.10,
    auto_commit_baselines: true,
    viewports: [
      { name: 'desktop', width: 1280, height: 720 },
      { name: 'mobile', width: 375, height: 667 }
    ]
  },
  migrations: {
    strictness: answer16.includes('Blocking') ? 'blocking'
              : answer16.includes('Warning') ? 'warning'
              : 'auto_apply',
    detection_threshold: answer17.includes('2+') ? 2
                       : answer17.includes('5+') ? 5
                       : 3,
    auto_generate_plan: true,
    llm_analysis_for_low_confidence: true
  },
  learning: {
    enabled: answer11.includes('Yes') ? true : false,
    auto_apply_low_risk: true,  // Always true if learning enabled
    require_approval_high_risk: true,  // Always true
    claude_md_optimization: answer12.includes('Yes') ? true : false,
    thresholds: {
      pattern_detection_min_occurrences: 3,
      statistical_significance: 0.95
    }
  }
};
```

### Step 8: Write Configuration File

**Write preferences to `.spec-flow/config/user-preferences.yaml`:**

```yaml
# Spec-Flow User Preferences
# Generated by /init-preferences wizard on [TIMESTAMP]
# Documentation: docs/configuration.md

commands:
  epic:
    default_mode: [VALUE]

  tasks:
    default_mode: [VALUE]

  init-project:
    default_mode: [VALUE]
    include_design: [VALUE]

  run-prompt:
    default_strategy: [VALUE]

automation:
  auto_approve_minor_changes: false
  ci_mode_default: [VALUE]

ui:
  show_usage_stats: [VALUE]
  recommend_last_used: [VALUE]
```

### Step 9: Display Configuration Summary

**Show user-friendly summary:**

```
╔════════════════════════════════════════════════════════════════╗
║  ✅ Preferences Configured Successfully                        ║
╚════════════════════════════════════════════════════════════════╝

Your preferences have been saved to:
  .spec-flow/config/user-preferences.yaml

┌─────────────────────────────────────────────────────────────────┐
│ Command Defaults                                                │
├─────────────────────────────────────────────────────────────────┤
│ /epic           → [interactive|auto] mode                       │
│ /tasks          → [standard|ui-first] mode                      │
│ /init-project   → [interactive|ci] mode                         │
│                   [with|without] design system                  │
│ /run-prompt     → [auto-detect|parallel|sequential] strategy   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ UI Preferences                                                  │
├─────────────────────────────────────────────────────────────────┤
│ Show usage stats:        [Yes|No]                              │
│ Recommend last-used:     [Yes|No]                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ Automation                                                      │
├─────────────────────────────────────────────────────────────────┤
│ CI mode default:         [Yes|No]                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ E2E & Visual Testing (Gate 7)                                   │
├─────────────────────────────────────────────────────────────────┤
│ Enabled:                 [Yes|No]                              │
│ Failure mode:            [blocking|warning]                    │
│ Pixel threshold:         [5%|10%|20%]                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ Database Migrations                                             │
├─────────────────────────────────────────────────────────────────┤
│ Strictness:              [blocking|warning|auto_apply]         │
│ Detection threshold:     [2+|3+|5+] keywords                   │
└─────────────────────────────────────────────────────────────────┘

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

How Your Commands Will Behave:

Example 1: /epic "add authentication"
  → Runs in [interactive|auto] mode by default
  → Override: /epic "add authentication" --[auto|interactive]

Example 2: /tasks
  → Generates [standard|ui-first] tasks by default
  → Override: /tasks --[ui-first|standard]

Example 3: /init-project
  → Uses [interactive|ci] mode
  → [Includes|Skips] design system (--with-design)
  → Override: /init-project --[interactive|ci]

Example 4: /run-prompt 005 006 007
  → Uses [auto-detect|parallel|sequential] strategy
  → Override: /run-prompt 005 006 007 --[parallel|sequential]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next Steps:

✓ Your preferences are active immediately
✓ Commands will remember your mode choices over time
✓ Override any preference with flags when needed
✓ Edit .spec-flow/config/user-preferences.yaml directly anytime
✓ Re-run /init-preferences to change preferences
✓ Run /init-preferences --reset to restore defaults

Happy building! 🚀
```

</process>

<verification>
Before completing, verify:
- user-preferences.yaml was created/updated successfully
- File contains valid YAML syntax
- All 17 questions were answered
- Configuration summary matches user selections
- File permissions allow reading/writing
</verification>

<success_criteria>
- ✅ User completed all 17 preference questions
- ✅ Configuration file created at .spec-flow/config/user-preferences.yaml
- ✅ Valid YAML format with all required fields
- ✅ Summary displayed showing configured preferences
- ✅ Example commands shown demonstrating new behavior
</success_criteria>

<examples>

## Example 1: First-Time User (Interactive Preferences)

**User runs:** `/init-preferences`

**Wizard shows:**
```
╔════════════════════════════════════════════════════════════════╗
║  Spec-Flow Preference Configuration Wizard                     ║
╚════════════════════════════════════════════════════════════════╝
...
```

**User answers 8 questions:**
1. Epic mode: Interactive ✓
2. Tasks mode: Standard ✓
3. Init-project mode: Interactive ✓
4. Include design: No ✓
5. Run-prompt strategy: Auto-detect ✓
6. Show usage stats: Yes ✓
7. Recommend last-used: Yes ✓
8. CI mode: No ✓

**Result:**
```yaml
commands:
  epic:
    default_mode: interactive
  tasks:
    default_mode: standard
  init-project:
    default_mode: interactive
    include_design: false
  run-prompt:
    default_strategy: auto-detect
automation:
  ci_mode_default: false
ui:
  show_usage_stats: true
  recommend_last_used: true
```

## Example 2: Power User (Automation-Focused)

**User runs:** `/init-preferences`

**User answers:**
1. Epic mode: Auto ✓
2. Tasks mode: Standard ✓
3. Init-project mode: Interactive ✓
4. Include design: No ✓
5. Run-prompt strategy: Parallel ✓
6. Show usage stats: No ✓
7. Recommend last-used: No ✓
8. CI mode: No ✓

**Result:**
```yaml
commands:
  epic:
    default_mode: auto
  tasks:
    default_mode: standard
  init-project:
    default_mode: interactive
    include_design: false
  run-prompt:
    default_strategy: parallel
automation:
  ci_mode_default: false
ui:
  show_usage_stats: false
  recommend_last_used: false
```

## Example 3: Design-Focused User

**User runs:** `/init-preferences`

**User answers:**
1. Epic mode: Interactive ✓
2. Tasks mode: UI-first ✓
3. Init-project mode: Interactive ✓
4. Include design: Yes ✓
5. Run-prompt strategy: Auto-detect ✓
6. Show usage stats: Yes ✓
7. Recommend last-used: Yes ✓
8. CI mode: No ✓

**Result:**
```yaml
commands:
  epic:
    default_mode: interactive
  tasks:
    default_mode: ui-first
  init-project:
    default_mode: interactive
    include_design: true
  run-prompt:
    default_strategy: auto-detect
automation:
  ci_mode_default: false
ui:
  show_usage_stats: true
  recommend_last_used: true
```

## Example 4: Reset Preferences

**User runs:** `/init-preferences --reset`

**Wizard shows:**
```
Current preferences will be reset to defaults:
  - /epic: interactive mode
  - /tasks: standard mode
  - /init-project: interactive mode, no design
  - /run-prompt: auto-detect strategy
  - UI: show stats, recommend last-used
  - Automation: interactive (not CI mode)

Reset all preferences to defaults?
  1. Yes, reset everything
  2. No, keep current preferences
```

**User selects:** "Yes, reset everything"

**Result:**
```
✓ Preferences reset to defaults
✓ File: .spec-flow/config/user-preferences.yaml

All command preferences have been restored to defaults.
Run /init-preferences again to customize.
```

</examples>

<error_handling>

**If user-preferences.yaml already exists:**
- Show message: "Found existing preferences. This wizard will update your configuration."
- Proceed normally (overwrite with new preferences)

**If .spec-flow/config/ directory doesn't exist:**
- Create directory automatically
- Proceed with wizard

**If write fails (permissions):**
- Show error: "Failed to write preferences file. Check file permissions."
- Display configuration as JSON so user can manually create file

**If user cancels wizard (e.g., selects "Other" and cancels):**
- Show message: "Preference configuration cancelled. No changes made."
- Existing preferences remain unchanged

</error_handling>

<meta_instructions>
- Use AskUserQuestion for all 17 questions (rounds: 2+2+1+2+1+2+2+1+2+2)
- Write valid YAML with proper indentation (2 spaces)
- Include timestamp comment at top of generated file
- Use clear, user-friendly language in all prompts
- Provide examples showing how preferences affect behavior
- Validate that all answers were received before writing file
</meta_instructions>
