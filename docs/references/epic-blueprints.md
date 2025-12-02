# Epic Frontend Blueprint Workflow (v9.4+)

**For epics with Frontend subsystem**, HTML blueprints are automatically generated for design iteration before TSX implementation.

## Workflow

```
/epic → /plan → [Epic Overview Generated] → /tasks → [Sprint Blueprints Generated] →
/implement-epic → [Blueprint Approval Gate] → TSX Implementation → /optimize → [Cleanup Blueprints] → /ship
```

## Blueprint Generation Phases

1. **/plan phase**: Generates `epic-overview.html` (navigation hub showing all sprints/screens)
2. **/tasks phase**: Generates individual `sprint-N/screen-*.html` files from sprint-plan.md

## Blueprint Characteristics

- Pure HTML + Tailwind CSS classes
- Design token integration (tokens.css)
- State switching (success, loading, error, empty)
- Keyboard navigation (H for hub, S for state cycling)
- WCAG 2.1 AA accessibility baseline

## Approval Gate

During /implement-epic:

- **Auto-mode** (`--auto`): Notify and continue automatically
- **Interactive mode**: Optional pause for iteration
- Default: "Continue" (no pause unless requested)
- User can edit HTML files, refresh browser to preview

## TSX Conversion Workflow

1. Blueprint patterns extracted to `blueprint-patterns.md`
2. Edge case checklist generated (`conversion-edge-cases.md`)
3. Developers mirror Tailwind classes in TSX components
4. Optional validation via `validate-tsx-conversion.sh` (skippable with `--skip-validation`)

## Cleanup Strategy

Before production:

- Mockups deleted during /optimize phase
- `**/mockups/` gitignored (never committed)
- `blueprint-patterns.md` preserved for reference
- Only TSX components deploy to production

## Blueprint Location

`epics/NNN-slug/mockups/`

- `epic-overview.html` - Navigation hub
- `sprint-N/screen-NN-*.html` - Individual screens

## Skip Options

- `--skip-validation`: Skip pattern extraction and validation
- `--no-guidance`: Skip edge case checklist
- `--auto`: Skip all approval gates
