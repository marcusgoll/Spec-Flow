---
name: checks-phase
description: "Standard Operating Procedure for /fix-ci phase. Fix CI/deployment blockers after PR creation."
allowed-tools: Read, Edit, Grep, Bash
---

# Checks Phase: Standard Operating Procedure

> **Training Guide**: Fix CI failures and deployment check failures that block merge.

## Phase Overview
**Purpose**: Fix CI/deployment blockers discovered after PR creation
**Inputs**: CI/deployment check results
**Outputs**: Fixed code, passing checks
**Expected duration**: 30 minutes - 2 hours

## Execution Steps
1. Review failed checks
2. Categorize failures (linting, tests, build, deploy config)
3. Fix issues systematically
4. Re-run checks
5. Verify all pass

## Common Mistakes
- Recurring check failures
- Unclear error messages
- Insufficient fix documentation

## Completion Criteria
- [ ] All CI checks pass
- [ ] All deployment checks pass
- [ ] Fixes committed

_This SOP guides fixing CI/deployment blockers._
