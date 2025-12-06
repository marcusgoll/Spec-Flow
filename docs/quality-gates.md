# Quality Gates Reference

This document defines the responsibilities and boundaries of each quality gate command.

## Overview

Spec-Flow provides three quality gate commands with distinct scopes:

| Command | Scope | When to Use |
|---------|-------|-------------|
| `/optimize` | Comprehensive (10 gates) | Before deployment (features/epics) |
| `/gate-ci` | CI pipeline (4 gates) | In GitHub Actions, PR validation |
| `/gate-sec` | Security (3 gates) | Pre-deployment security review |

## /optimize (Authoritative Quality Gate)

**Purpose:** Comprehensive production readiness validation.

**When to use:**

- Before any deployment (staging, production, local)
- After `/implement` completes
- Part of the standard workflow (auto-invoked by `/ship`)

**Gates included (10 parallel checks):**

| # | Gate | Blocker | Description |
|---|------|---------|-------------|
| 1 | Performance | CRITICAL | API <500ms, page load <3s, no N+1 queries |
| 2 | Security | CRITICAL | No OWASP Top 10, secrets scan, dep vulnerabilities |
| 3 | Accessibility | CRITICAL | WCAG 2.1 AA compliance, keyboard nav, screen reader |
| 4 | Code Review | CRITICAL | No critical issues, KISS/DRY adherence |
| 5 | Migrations | CRITICAL | Zero-downtime, rollback tested, data integrity |
| 6 | Docker Build | CRITICAL | Dockerfile builds, image scans clean |
| 7 | E2E Tests | HIGH (epic) | Critical user flows pass, contracts honored |
| 8 | Contract Validation | HIGH (epic) | API contracts match implementation |
| 9 | Load Testing | MEDIUM (epic) | Handles expected traffic, no degradation |
| 10 | Migration Integrity | HIGH (epic) | Production data safe, reversible |

**Output:** `optimization-report.md`, `code-review-report.md`

**Behavior:**

- CRITICAL blockers halt deployment
- HIGH issues require acknowledgment
- MEDIUM issues logged as warnings
- Epic workflows get all 10 gates
- Feature workflows get gates 1-6

## /gate-ci (CI Pipeline Gate)

**Purpose:** Fast automated checks for pull request validation.

**When to use:**

- GitHub Actions CI pipeline
- PR creation/update
- Pre-merge validation

**Gates included (4 checks):**

| # | Gate | Threshold | Tool |
|---|------|-----------|------|
| 1 | Tests | 100% pass | Jest, Pytest, etc. |
| 2 | Lint | 0 errors | ESLint, ruff, etc. |
| 3 | Type Check | 0 errors | TypeScript, mypy |
| 4 | Coverage | ≥80% | coverage.py, c8 |

**Output:** Exit code 0 (pass) or 1 (fail) + CI logs

**Behavior:**

- Blocks PR merge on failure
- Runs in ~2-5 minutes
- No manual intervention required
- Integrated with GitHub Actions workflow

**When NOT to use:**

- Security deep scans (use `/gate-sec`)
- Performance benchmarking (use `/optimize`)
- Accessibility audits (use `/optimize`)

## /gate-sec (Security Gate)

**Purpose:** Security-focused validation before deployment.

**When to use:**

- Pre-deployment security review
- Dependency update validation
- Security audit requests

**Gates included (3 checks):**

| # | Gate | Blocker | Tool |
|---|------|---------|------|
| 1 | SAST | CRITICAL/HIGH | Semgrep, CodeQL |
| 2 | Secrets Detection | CRITICAL | TruffleHog, gitleaks |
| 3 | Dependency Scan | HIGH/CRITICAL | npm audit, safety |

**Severity thresholds:**

- CRITICAL: Blocks deployment immediately
- HIGH: Requires explicit acknowledgment
- MEDIUM/LOW: Logged as warnings

**Output:** Security findings report, exit code

**Behavior:**

- Scans entire codebase (not just changed files)
- Checks committed history for leaked secrets
- Validates dependency tree for known CVEs

## Gate Boundaries

### What Each Gate Owns

```
┌──────────────────────────────────────────────────────────────────┐
│                        /optimize                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ Performance | Security | Accessibility | Code Review |      │ │
│  │ Migrations | Docker | E2E | Contracts | Load | Integrity    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                     (authoritative, pre-deployment)              │
└──────────────────────────────────────────────────────────────────┘

┌────────────────────────────┐  ┌────────────────────────────────┐
│        /gate-ci            │  │         /gate-sec              │
│  ┌──────────────────────┐  │  │  ┌──────────────────────────┐  │
│  │ Tests | Lint | Types │  │  │  │ SAST | Secrets | Deps    │  │
│  │ Coverage             │  │  │  └──────────────────────────┘  │
│  └──────────────────────┘  │  │  (security-focused)            │
│  (fast CI feedback)        │  │                                │
└────────────────────────────┘  └────────────────────────────────┘
```

### Overlap Handling

| Check | /optimize | /gate-ci | /gate-sec |
|-------|-----------|----------|-----------|
| Unit tests | ✅ (via code review) | ✅ (primary) | ❌ |
| Lint | ✅ (via code review) | ✅ (primary) | ❌ |
| Type check | ✅ (via code review) | ✅ (primary) | ❌ |
| Coverage | ✅ (via code review) | ✅ (primary) | ❌ |
| Security scan | ✅ (primary) | ❌ | ✅ (deep scan) |
| Dependency audit | ✅ (primary) | ❌ | ✅ (deep scan) |
| Performance | ✅ (primary) | ❌ | ❌ |
| Accessibility | ✅ (primary) | ❌ | ❌ |
| E2E tests | ✅ (epic only) | ❌ | ❌ |

**Rule:** If a check appears in multiple gates, `/optimize` is authoritative for deployment decisions.

## Usage Examples

### Standard Feature Workflow

```bash
/implement
/optimize         # Full quality validation
/ship             # Deploys if gates pass
```

### CI Pipeline (GitHub Actions)

```yaml
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npx spec-flow gate-ci
```

### Pre-Deployment Security Review

```bash
/optimize         # Standard gates
/gate-sec         # Additional security deep scan
/ship-staging     # Deploy to staging
```

### Epic Quality Validation

```bash
/implement-epic   # Execute sprints
/optimize         # All 10 gates (epic mode)
/ship             # Deploy
```

## Troubleshooting

### Gate Failures

| Error | Cause | Resolution |
|-------|-------|------------|
| "Coverage below 80%" | Insufficient tests | Add tests, run `/gate-ci` again |
| "CRITICAL security issue" | Vulnerability found | Fix issue, run `/gate-sec` again |
| "Performance degradation" | Slow queries/rendering | Profile and optimize |
| "Accessibility violation" | WCAG non-compliance | Fix a11y issues |

### Skipping Gates (Not Recommended)

Gates can be skipped for emergencies only:

```bash
# Skip specific gate (requires justification)
/optimize --skip performance --reason "Hotfix for critical bug"
```

**Warning:** Skipped gates are logged in deployment metadata for audit.

## See Also

- [Deployment Guide](deployment-guide.md) - Deployment models
- [Commands](commands.md) - Full command reference
- [Architecture](architecture.md) - System overview
