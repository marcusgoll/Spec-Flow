---
name: heal-workflow
description: Apply workflow improvements discovered during audit with approval workflow
argument-hint: [epic-slug | auto]
allowed-tools: [Read, Write, Edit, Grep, Glob, AskUserQuestion]
version: 5.0
updated: 2025-11-19
---

# /heal-workflow — Self-Healing Workflow Improvements

**Purpose**: Apply improvements to workflow system based on audit findings. Enables workflow to adapt and self-improve over time.

**Command**: `/heal-workflow [epic-slug | auto]`

**When to use**:
- After `/audit-workflow` identifies improvement opportunities
- Manual invocation to review and apply pending improvements
- After pattern detection suggests custom tooling

---

<instructions>

## Healing Workflow Process

### Step 1: Load Audit Report

**Locate most recent audit:**
```bash
if [ -n "$ARGUMENTS" ] && [ "$ARGUMENTS" != "auto" ]; then
  EPIC_DIR="epics/$ARGUMENTS"
else
  # Find most recent epic with audit report
  EPIC_DIR=$(find epics -name "audit-report.xml" -printf '%T@ %p\n' | sort -rn | head -1 | cut -d' ' -f2- | xargs dirname)
fi

AUDIT_REPORT="$EPIC_DIR/audit-report.xml"
```

**Validate audit exists:**
```bash
test -f "$AUDIT_REPORT" || error "No audit report found. Run /audit-workflow first."
```

### Step 2: Parse Improvement Recommendations

**Extract actionable recommendations:**
```javascript
const audit = readXML(AUDIT_REPORT);

const improvements = {
  immediate: audit.recommendations.immediate.filter(r => r.priority === 'high'),
  short_term: audit.recommendations.short_term.filter(r => r.priority === 'medium'),
  long_term: audit.recommendations.long_term.filter(r => r.priority === 'low'),
  custom_tooling: audit.custom_tooling_suggestions
};
```

**Categorize by type:**
```javascript
const improvementTypes = {
  phase_modifications: [],    // Change phase behavior
  gate_adjustments: [],        // Modify quality gates
  template_updates: [],        // Update XML templates
  skill_generation: [],        // Generate custom skills
  command_generation: [],      // Generate custom commands
  config_changes: []          // Update workflow configuration
};
```

### Step 3: Present Improvement Options

**Display recommendations with impact:**
```
Workflow Healing: 001-auth-epic
─────────────────────────────────────────

Audit Score: 85/100 (B+)
Found 8 improvement opportunities

IMMEDIATE (High Priority - Apply Now)
══════════════════════════════════════════
[1] Reduce clarification phase overhead
    Type: phase_modification
    Current: Asks 6 questions regardless of clarity
    Proposed: Adaptive questioning (2-6 based on ambiguity)
    Impact: Save ~45min per epic
    Risk: Low
    Effort: 1 hour to update clarify.md

[2] Auto-skip preview for non-UI epics
    Type: gate_adjustment
    Current: Manual preview required for all epics
    Proposed: Auto-skip if no UI changes detected
    Impact: Save ~1.5h for backend-only epics (40% of epics)
    Risk: Low (AI pre-flight checks still run)
    Effort: 30min to update preview.md

SHORT-TERM (Medium Priority - Next 2-3 Epics)
══════════════════════════════════════════════
[3] Generate service boilerplate skill
    Type: skill_generation
    Pattern: Detected 3x (DI + Repository pattern)
    Impact: Save 30min per service, ensure consistency
    Effort: 2 hours to build skill

[4] Improve sprint estimation for frontend
    Type: config_changes
    Current: Frontend sprints underestimated by avg 80%
    Proposed: Increase frontend complexity multiplier 1.0x → 1.8x
    Impact: More accurate estimates, better planning
    Risk: Low
    Effort: 5min config update

LONG-TERM (Low Priority - Strategic)
══════════════════════════════════════════
[5] Contract-first workflow enforcement
    Type: phase_modification
    Proposed: Lock contracts before any implementation starts
    Impact: Prevent integration bugs proactively
    Risk: Medium (adds overhead to planning phase)
    Effort: 4 hours to build contract-locking mechanism

... (3 more)
```

### Step 4: Get User Approval

**Use AskUserQuestion for selections:**
```javascript
AskUserQuestion({
  questions: [
    {
      question: "Which immediate improvements should I apply?",
      header: "Immediate",
      multiSelect: true,
      options: [
        {
          label: "[1] Adaptive clarification",
          description: "Save ~45min per epic, low risk"
        },
        {
          label: "[2] Auto-skip preview",
          description: "Save ~1.5h for backend epics, low risk"
        }
      ]
    },
    {
      question: "Which short-term improvements should I apply?",
      header: "Short-term",
      multiSelect: true,
      options: [
        {
          label: "[3] Service boilerplate skill",
          description: "2h effort, save 30min per service"
        },
        {
          label: "[4] Frontend estimation fix",
          description: "5min effort, better planning"
        }
      ]
    },
    {
      question: "Apply long-term improvements?",
      header: "Long-term",
      multiSelect: false,
      options: [
        {
          label: "Yes, apply selected",
          description: "I'll select which ones in next question"
        },
        {
          label: "No, skip for now",
          description: "Focus on immediate and short-term"
        }
      ]
    }
  ]
})
```

**If user selects improvements, proceed to application.**

### Step 5: Apply Phase Modifications

**Example: Adaptive clarification**
```javascript
// User approved: [1] Adaptive clarification

// Read current clarify.md
const clarifyCommand = read('.claude/commands/phases/clarify.md');

// Apply modification
const updated = clarifyCommand.replace(
  /Ask 6 standard questions/,
  `Analyze epic-spec.md ambiguity score:
   - If score < 30: Ask 2 questions
   - If score 30-60: Ask 4 questions
   - If score > 60: Ask 6 questions`
);

// Show diff
console.log(`
Proposed Change to: .claude/commands/phases/clarify.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- Ask 6 standard questions
+ Analyze epic-spec.md ambiguity score:
+   - If score < 30: Ask 2 questions
+   - If score 30-60: Ask 4 questions
+   - If score > 60: Ask 6 questions

Apply this change?
`);

// Get confirmation
if (confirm()) {
  write('.claude/commands/phases/clarify.md', updated);
  log('✓ Updated clarify.md with adaptive questioning');
}
```

### Step 6: Apply Gate Adjustments

**Example: Auto-skip preview**
```javascript
// User approved: [2] Auto-skip preview

// Read preview.md
const previewCommand = read('.claude/commands/phases/preview.md');

// Add complexity detection logic
const updated = previewCommand.replace(
  /<instructions>/,
  `<instructions>

## Auto-Skip Detection

**Analyze epic complexity before preview:**
\`\`\`javascript
const shouldSkip = detectAutoSkip({
  ui_changes: countUIFiles(epic_dir),
  sprint_count: sprints.length,
  subsystems: epic_spec.subsystems
});

if (shouldSkip) {
  log('Preview auto-skipped: No UI changes detected');
  updateWorkflowState({
    preview: { status: 'skipped', reason: 'No UI changes' }
  });
  return;
}
\`\`\`

`
);

// Show diff and apply
if (confirm()) {
  write('.claude/commands/phases/preview.md', updated);
  log('✓ Updated preview.md with auto-skip logic');
}
```

### Step 7: Generate Custom Skills

**Example: Service boilerplate skill**
```javascript
// User approved: [3] Service boilerplate skill

// Invoke create-agent-skills
Skill('create-agent-skills', {
  context: `
  Detected pattern: All services follow DI + Repository pattern (3 instances)

  Examples:
  - src/auth/AuthService.ts
  - src/users/UserService.ts
  - src/orders/OrderService.ts

  Common structure:
  - Constructor with repository injection
  - CRUD methods (create, findById, update, delete)
  - Business logic methods
  - Error handling with custom exceptions

  Generate skill: create-service-boilerplate

  Inputs:
  - Service name (e.g., "Product")
  - Repository interface
  - Business methods

  Outputs:
  - Service class with DI
  - Interface definition
  - Unit test scaffold
  - Registration in DI container
  `
});

// Skill generates:
// .claude/skills/project-custom/create-service-boilerplate/
//   ├── SKILL.md
//   ├── references/
//   │   └── service-template.ts
//   └── scripts/
//       └── generate-service.ts

log('✓ Generated skill: create-service-boilerplate');
log('  Location: .claude/skills/project-custom/create-service-boilerplate/');
```

### Step 8: Update Configuration

**Example: Frontend estimation multiplier**
```javascript
// User approved: [4] Frontend estimation fix

// Read workflow config
const config = readYAML('docs/project/engineering-principles.md');

// Update estimation multipliers
config.estimation = config.estimation || {};
config.estimation.complexity_multipliers = config.estimation.complexity_multipliers || {};
config.estimation.complexity_multipliers.frontend = 1.8; // was 1.0

// Write updated config
writeYAML('docs/project/engineering-principles.md', config);

log('✓ Updated estimation multiplier for frontend tasks: 1.0x → 1.8x');
log('  Impact: More accurate sprint time estimates');
```

### Step 9: Validate Changes

**Run validation checks:**
```javascript
// Validate all modified files
const modifiedFiles = [
  '.claude/commands/phases/clarify.md',
  '.claude/commands/phases/preview.md',
  'docs/project/engineering-principles.md'
];

for (const file of modifiedFiles) {
  // Check file is valid (readable, no syntax errors)
  validateFile(file);

  // For commands, check required tags present
  if (file.endsWith('.md') && file.includes('/commands/')) {
    validateCommandStructure(file);
  }
}

log('✓ All changes validated successfully');
```

### Step 10: Generate Healing Report

**Create healing-report.xml:**
```xml
<healing_report>
  <metadata>
    <epic_slug>001-auth-epic</epic_slug>
    <audit_report>epics/001-auth-epic/audit-report.xml</audit_report>
    <healing_timestamp>2025-11-19T14:30:00Z</healing_timestamp>
    <healer_version>5.0</healer_version>
  </metadata>

  <improvements_applied>
    <improvement id="1" type="phase_modification" priority="high">
      <name>Adaptive clarification questioning</name>
      <files_modified>
        <file>.claude/commands/phases/clarify.md</file>
      </files_modified>
      <impact>Save ~45min per epic</impact>
      <risk>low</risk>
      <applied_timestamp>2025-11-19T14:25:00Z</applied_timestamp>
      <validation_status>passed</validation_status>
    </improvement>

    <improvement id="2" type="gate_adjustment" priority="high">
      <name>Auto-skip preview for non-UI epics</name>
      <files_modified>
        <file>.claude/commands/phases/preview.md</file>
      </files_modified>
      <impact>Save ~1.5h for 40% of epics</impact>
      <risk>low</risk>
      <applied_timestamp>2025-11-19T14:26:00Z</applied_timestamp>
      <validation_status>passed</validation_status>
    </improvement>

    <improvement id="3" type="skill_generation" priority="medium">
      <name>Service boilerplate skill</name>
      <files_created>
        <file>.claude/skills/project-custom/create-service-boilerplate/SKILL.md</file>
        <file>.claude/skills/project-custom/create-service-boilerplate/references/service-template.ts</file>
      </files_created>
      <impact>Save 30min per service</impact>
      <effort>2 hours</effort>
      <applied_timestamp>2025-11-19T14:28:00Z</applied_timestamp>
      <validation_status>passed</validation_status>
    </improvement>

    <improvement id="4" type="config_changes" priority="medium">
      <name>Frontend estimation multiplier</name>
      <files_modified>
        <file>docs/project/engineering-principles.md</file>
      </files_modified>
      <changes>
        <change>complexity_multipliers.frontend: 1.0 → 1.8</change>
      </changes>
      <impact>More accurate sprint estimates</impact>
      <applied_timestamp>2025-11-19T14:29:00Z</applied_timestamp>
      <validation_status>passed</validation_status>
    </improvement>
  </improvements_applied>

  <improvements_deferred>
    <improvement id="5" type="phase_modification" priority="low">
      <name>Contract-first workflow enforcement</name>
      <reason>User deferred - will apply in future epic</reason>
    </improvement>
  </improvements_deferred>

  <summary>
    <applied_count>4</applied_count>
    <deferred_count>1</deferred_count>
    <failed_count>0</failed_count>
    <estimated_time_saved_per_epic>2.25h</estimated_time_saved_per_epic>
    <estimated_roi>High (2h improvement effort, 2.25h saved per epic, breaks even after 1 epic)</estimated_roi>
  </summary>

  <next_healing_recommendations>
    <recommendation>
      Apply deferred improvements after 2 more epics to validate current changes
    </recommendation>
    <recommendation>
      Run /audit-workflow after next epic to measure effectiveness of applied improvements
    </recommendation>
  </next_healing_recommendations>
</healing_report>
```

### Step 11: Present Results

**Display summary:**
```
Workflow Healing Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Applied 4 improvements from audit report

✓ [1] Adaptive clarification
    Modified: .claude/commands/phases/clarify.md
    Impact: Save ~45min per epic

✓ [2] Auto-skip preview
    Modified: .claude/commands/phases/preview.md
    Impact: Save ~1.5h for backend-only epics

✓ [3] Service boilerplate skill
    Created: .claude/skills/project-custom/create-service-boilerplate/
    Impact: Save 30min per service

✓ [4] Frontend estimation multiplier
    Modified: docs/project/engineering-principles.md
    Change: 1.0x → 1.8x
    Impact: More accurate sprint estimates

Deferred 1 improvement (low priority):
  [5] Contract-first workflow enforcement

Total Time Saved Per Epic: ~2.25 hours
ROI: High (breaks even after 1 epic)

Full report: epics/001-auth-epic/healing-report.xml

Next Steps:
→ Run next epic to validate improvements
→ Run /audit-workflow after next epic to measure effectiveness
→ Consider applying deferred improvements after 2 more epics
```

**Offer commit:**
```
Would you like to commit these workflow improvements?

1. Yes, commit all changes
2. No, I'll review and commit manually
3. Show me the diff first
```

</instructions>

---

## Success Criteria

- Audit report loaded and parsed
- Improvement recommendations categorized by priority and type
- User presented with clear options and impact analysis
- Approved improvements applied with validation
- Modified files validated for correctness
- healing-report.xml generated with summary
- Results presented with estimated time savings
- Optional commit offered

---

## Anti-Hallucination Rules

1. **Never apply improvements without user approval**
   Always use AskUserQuestion before modifying files.

2. **Show diffs before applying changes**
   User must see exactly what will change.

3. **Validate all modifications**
   Run validation checks after each change.

4. **Don't invent improvements not in audit report**
   Only apply recommendations from audit-report.xml.

5. **Track all changes in healing-report.xml**
   Complete audit trail required.

---

## Integration Points

**Auto-triggered by:**
- `/finalize` (offers to heal after post-mortem audit)

**Depends on:**
- `/audit-workflow` (must run first to generate recommendations)

**Outputs used by:**
- `/workflow-health` (tracks cumulative improvements)
- Git commit history (documents workflow evolution)

---

## References

- [Skill Auditor Agent](.claude/agents/infrastructure/skill-auditor.md)
- [Self-Healing Systems](docs/self-healing-workflow.md)
