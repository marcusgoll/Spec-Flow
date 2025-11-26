# Scenario 5: UI-First Workflow

## Purpose

Test mockup-first workflow with approval gates and design system integration.

## Tests

### 1. Directory Structure Validation

- Verifies scenario directory exists
- **Expected**: Directory present

### 2. /tasks --ui-first Flag Validation

- Validates tasks.md command supports --ui-first
- **Expected**: Command file mentions ui-first mode

### 3. Mockup Approval Checklist Template

- Validates mockup-approval-checklist.md template exists
- **Expected**: Template file present

### 4. Design System Skills Validation

- Validates design-scout and design-lint agents exist
- **Expected**: Design system agents present

## Workflow Phases

```
/feature "Add user dashboard"
    ↓
/spec
    ↓
/plan
    ↓
/tasks --ui-first
    ↓
Multi-screen detection (≥3 screens → navigation hub)
    ↓
Mockup approval gate (BLOCKS implementation)
    ↓
User approves mockup
    ↓
/feature continue
    ↓
/implement (execution continues)
```

## Expected Artifacts

After `/tasks --ui-first`:

```
specs/001-user-dashboard/
├── spec.md
├── plan.md
├── tasks.md (mockup generation tasks)
├── state.yaml (manual_gates.mockup_approval: pending)
└── mockups/
    ├── mockup-approval-checklist.md
    └── (awaiting mockup generation)
```

After mockup generation (≥3 screens):

```
mockups/
├── index.html (navigation hub)
├── screen-01-overview.html
├── screen-02-analytics.html
├── screen-03-settings.html
└── mockup-approval-checklist.md
```

After mockup generation (1-2 screens):

```
mockups/
├── dashboard.html
└── mockup-approval-checklist.md
```

## Mockup Navigation Hub Features

For multi-screen mockups (≥3 screens):

**Keyboard Shortcuts**:

- `H` → Return to hub (index.html)
- `1-9` → Jump to screen N
- `S` → Cycle through states (Success, Loading, Error, Empty)

**State Switcher**:

- Success state (default)
- Loading state (spinners, skeletons)
- Error state (error messages)
- Empty state (no data)

## Approval Gate Blocking

```yaml
# state.yaml
manual_gates:
  mockup_approval:
    status: pending # BLOCKS /implement
    blocking: true
    mockups_directory: specs/001-user-dashboard/mockups/
    checklist_path: specs/001-user-dashboard/mockups/mockup-approval-checklist.md
```

After user approval:

```yaml
manual_gates:
  mockup_approval:
    status: approved
    approved_at: "2025-01-20T10:30:00Z"
    approved_by: user
    blocking: false
```

## Design System Integration

UI-first mode reads:

- `docs/design/visual-language.md` → Design tokens, spacing, typography
- `docs/design/brand-guidelines.md` → Colors, logos, voice
- `docs/design/accessibility-standards.md` → WCAG 2.1 AA requirements
- `docs/design/component-governance.md` → Component library

## Manual Test Steps

1. Navigate to this directory
2. Run `/tasks --ui-first` (simulated)
3. Verify mockup approval checklist template exists
4. Verify design system agents exist
5. Verify command supports UI-first mode

## Success Criteria

- ✓ /tasks command supports --ui-first flag
- ✓ Mockup approval checklist template exists
- ✓ Design system agents (design-scout, design-lint) exist
- ✓ Template references design docs correctly
- ✓ No errors during validation

## Mockup Approval Checklist

The checklist includes:

- [ ] Visual hierarchy clear and consistent
- [ ] Color contrast meets WCAG 2.1 AA
- [ ] Typography follows design system
- [ ] Spacing uses 8pt grid
- [ ] Interactive elements have hover/focus states
- [ ] Loading states for async operations
- [ ] Error states with clear messaging
- [ ] Empty states with helpful guidance
- [ ] Keyboard navigation works (Tab, Enter, Esc)
- [ ] Screen reader compatibility (semantic HTML)

## Notes

UI-first workflow benefits:

- Earlier design validation
- Reduced rework from late-stage design changes
- Better stakeholder alignment
- Accessibility considered upfront
- Component reuse identified early
- Implementation guided by approved mockups
