# Deployment Guide

This guide explains Spec-Flow's deployment models and when to use each command.

## Deployment Model Overview

Spec-Flow auto-detects your deployment model based on repository configuration:

```
                    ┌─────────────────────────────────┐
                    │           /ship                 │
                    │    (unified entry point)        │
                    └──────────────┬──────────────────┘
                                   │
                          auto-detects model
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
        ▼                          ▼                          ▼
┌───────────────┐        ┌─────────────────┐        ┌─────────────────┐
│  staging-prod │        │   direct-prod   │        │    local-only   │
│               │        │                 │        │                 │
│ Full staging  │        │ Direct to       │        │ No remote       │
│ validation    │        │ production      │        │ deployment      │
└───────┬───────┘        └────────┬────────┘        └────────┬────────┘
        │                         │                          │
        ▼                         ▼                          ▼
┌───────────────┐        ┌─────────────────┐        ┌─────────────────┐
│/ship-staging  │        │  /deploy-prod   │        │  /build-local   │
│/validate-stag │        │                 │        │                 │
│/ship-prod     │        │                 │        │                 │
└───────────────┘        └─────────────────┘        └─────────────────┘
        │                         │                          │
        └─────────────────────────┴──────────────────────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │   /finalize     │
                         │                 │
                         │ CHANGELOG,      │
                         │ README, cleanup │
                         └─────────────────┘
```

## Model Detection

Spec-Flow automatically detects your deployment model:

| Model | Detection Criteria |
|-------|-------------------|
| **staging-prod** | Git remote + staging branch + `.github/workflows/deploy-staging.yml` |
| **direct-prod** | Git remote + no staging infrastructure |
| **local-only** | No git remote (local development only) |

## Command Reference

### Unified Entry Point (Recommended)

```bash
/ship                    # Auto-detects model and runs appropriate workflow
/ship continue           # Resume after manual gates
/ship status             # Check current deployment status
```

The `/ship` command is the recommended entry point. It:

1. Detects your deployment model
2. Runs the appropriate command sequence
3. Handles manual gates and resume logic

### staging-prod Model

For projects with staging environments and production promotion:

```bash
# Full sequence
/optimize                # 10 parallel quality gates
/ship-staging            # Create PR, wait for CI, deploy to staging
/validate-staging        # Manual staging testing (pause point)
/ship-prod               # Tag and promote to production
/finalize                # Update docs, cleanup branches

# Individual commands
/ship-staging [slug]     # Deploy feature to staging
/validate-staging        # Run staging validation checklist
/ship-prod               # Promote staging to production
```

**Workflow:**

```
/optimize → /ship-staging → [manual validation] → /ship-prod → /finalize
```

**Manual Gate:** `/validate-staging` pauses for human testing. Resume with `/ship continue`.

### direct-prod Model

For projects that deploy directly to production without staging:

```bash
# Full sequence
/optimize                # 10 parallel quality gates
/deploy-prod             # Deploy directly to production
/finalize                # Update docs, cleanup branches

# Individual command
/deploy-prod             # Direct production deployment
```

**Workflow:**

```
/optimize → /deploy-prod → /finalize
```

**No manual gates** - quality gates in /optimize provide the safety net.

### local-only Model

For projects without remote deployment (prototypes, experiments, local tools):

```bash
# Full sequence
/optimize                # Quality gates (6 checks, skips deployment-specific)
/build-local             # Validate local build
/finalize                # Update docs, merge to main

# Individual command
/build-local             # Run local build validation
```

**Workflow:**

```
/optimize → /build-local → /finalize
```

**Includes:** Merge to main branch, version tagging (local git operations).

## Quality Gates by Model

| Gate | staging-prod | direct-prod | local-only |
|------|-------------|-------------|------------|
| Performance | ✅ | ✅ | ✅ |
| Security | ✅ | ✅ | ✅ |
| Accessibility | ✅ | ✅ | ✅ |
| Code Review | ✅ | ✅ | ✅ |
| Migrations | ✅ | ✅ | ❌ |
| Docker Build | ✅ | ✅ | ❌ |
| E2E Tests | ✅ (epic) | ✅ (epic) | ❌ |
| Contract Validation | ✅ (epic) | ✅ (epic) | ❌ |
| Load Testing | ✅ (epic, optional) | ✅ (epic, optional) | ❌ |
| Migration Integrity | ✅ (epic) | ✅ (epic) | ❌ |

## Decision Flowchart

Use this flowchart to determine which command to run:

```
                    ┌─────────────────────────┐
                    │ Want to deploy feature? │
                    └───────────┬─────────────┘
                                │
                     ┌──────────▼──────────┐
                     │ Have git remote?    │
                     └──────────┬──────────┘
                          │           │
                         Yes          No
                          │           │
              ┌───────────▼───┐       ▼
              │ Have staging  │   ┌─────────────┐
              │ environment?  │   │ /build-local│
              └───────┬───────┘   └─────────────┘
                │           │
               Yes          No
                │           │
                ▼           ▼
        ┌───────────┐  ┌─────────────┐
        │/ship-stag │  │/deploy-prod │
        │/val-stag  │  └─────────────┘
        │/ship-prod │
        └───────────┘
```

**Or simply run `/ship`** - it handles the detection automatically.

## Common Scenarios

### Scenario 1: First-time deployment

```bash
# Let /ship detect and guide you
/ship

# Or explicitly for staging-prod:
/ship-staging
# Wait for CI, review staging
/ship continue  # After validation
```

### Scenario 2: Resume after staging validation

```bash
# Check current state
/help

# Resume from where you left off
/ship continue
# or
/feature continue
```

### Scenario 3: Hotfix to production

```bash
# For staging-prod (recommended)
/quick "fix critical bug"
/ship-staging
/validate-staging
/ship-prod

# For direct-prod
/quick "fix critical bug"
/deploy-prod
```

### Scenario 4: Epic deployment

Epics follow the same deployment models but with additional quality gates:

```bash
/epic "feature"
# ... implementation ...
/optimize           # 10 gates for epics
/ship               # Auto-detects model
```

## Troubleshooting

### "No deployment model detected"

Ensure one of:

- Git remote exists (`git remote -v`)
- `.github/workflows/deploy-staging.yml` for staging-prod
- No remote for local-only

### "Staging validation required"

Run `/validate-staging` to complete manual testing, then `/ship continue`.

### "CI failed during ship-staging"

Check GitHub Actions, fix issues, then:

```bash
/ship continue  # Retries from last checkpoint
```

## See Also

- [Architecture](architecture.md) - Workflow structure
- [Commands](commands.md) - Full command reference
- [Troubleshooting](troubleshooting.md) - Common issues
