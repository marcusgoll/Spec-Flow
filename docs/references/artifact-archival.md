# Artifact Archival (v9.3+)

After `/finalize` completes successfully, all workflow artifacts are automatically archived to maintain a clean workspace while preserving historical context.

## Epic Workflows

```
epics/001-auth-system/
├── completed/              # Archived after /finalize
│   ├── epic-spec.md
│   ├── plan.md
│   ├── sprint-plan.md
│   ├── tasks.md
│   ├── NOTES.md
│   ├── research.md
│   └── walkthrough.md
└── state.yaml     # Stays in root for metrics
```

## Feature Workflows

```
specs/001-user-login/
├── completed/              # Archived after /finalize
│   ├── spec.md
│   ├── plan.md
│   ├── tasks.md
│   └── NOTES.md
└── state.yaml     # Stays in root
```

## Archival Pattern

**Trigger**: Automatic during `/finalize` command (Step 12)

**What gets archived**:

- All planning and implementation artifacts
- Documentation and notes
- Sprint plans (epics only)

**What stays**:

- state.yaml (for metrics and history)
- contracts/ directory (if exists)
- Any build/deployment artifacts

**Provenance**: Completed artifacts stay with the epic/spec for historical context

**Recovery**: Restore by moving files back from completed/ subfolder:

```bash
mv epics/001-auth-system/completed/* epics/001-auth-system/
```
