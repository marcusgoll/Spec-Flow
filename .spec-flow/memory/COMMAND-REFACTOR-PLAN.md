# Command Refactor Plan - v2.0 Migration

**Created**: 2025-11-10
**Status**: 5 of 47 commands refactored (11%)
**Goal**: Migrate all commands to v2.0 pattern (strict bash, non-interactive, deterministic)

---

## Completed Refactors (v2.0)

| Command | Date | Lines | Key Improvements | Documentation |
|---------|------|-------|------------------|---------------|
| `/build-local` | 2025-11-10 | 878→559 (-36%) | Strict bash, Corepack, SBOM, tool checks | BUILD-LOCAL-REFACTOR-v2.md |
| `/branch-enforce` | 2025-11-10 | 501→533 (+6%) | Robust detection, JSON output, auto-fix | BRANCH-ENFORCE-REFACTOR-v2.md |
| `/clarify` | 2025-11-10 | 825→641 (-22%) | Anti-hallucination, repo precedent, atomic commits | CLARIFY-REFACTOR-v2.md |
| `/constitution` | 2025-11-10 | 165→437 (+165%) | Structured actions, evidence-backed (WCAG, OWASP) | CONSTITUTION-REFACTOR-v2.md |
| `/deploy-prod` | 2025-11-10 | 804→907 (+13%) | Non-interactive, platform-specific rollback | DEPLOY-PROD-REFACTOR-v2.md |

**Pattern established**: Strict bash, error traps, tool checks, no prompts, actionable errors, comprehensive docs

---

## Prioritized Refactor Queue

### Priority 1: Critical Path (High Usage, High Impact)

**Must be refactored next** - These are the core workflow commands users interact with most.

| Command | Priority | Reason | Estimated Effort | Issues |
|---------|----------|--------|------------------|--------|
| `/spec` | 🔴 Critical | Entry point for all features | Medium | Likely has interactive prompts |
| `/plan` | 🔴 Critical | Core planning phase | Medium | May have editor opening |
| `/tasks` | 🔴 Critical | Task breakdown phase | Medium | Unknown interactive elements |
| `/implement` | 🔴 Critical | Main implementation orchestrator | High | Complex, likely has prompts |
| `/ship` | 🔴 Critical | Unified deployment orchestrator | High | Complex state machine |

**Estimated time**: 2-3 days for all 5 commands

---

### Priority 2: Deployment Pipeline (Medium-High Usage)

**Stabilize deployment workflow** - After `/ship` is refactored, these support commands should follow.

| Command | Priority | Reason | Estimated Effort | Issues |
|---------|----------|--------|------------------|--------|
| `/ship-staging` | 🟡 High | Staging deployment | Medium | May have interactive merge confirmation |
| `/validate-staging` | 🟡 High | Manual gate before prod | Low | Likely just checklist display |
| `/ship-prod` | 🟡 High | Production promotion | Medium | Similar to `/deploy-prod` (done) |
| `/optimize` | 🟡 High | Quality gates | High | Multiple sub-checks, complex |
| `/preview` | 🟡 High | Manual testing gate | Low | Checklist + dev server instructions |

**Estimated time**: 2 days for all 5 commands

---

### Priority 3: Quality & Validation (Medium Usage)

**Strengthen quality gates** - Less frequent but important for production readiness.

| Command | Priority | Reason | Estimated Effort | Issues |
|---------|----------|--------|------------------|--------|
| `/validate` | 🟡 High | Cross-artifact consistency | Medium | Analysis-heavy, may have interactive fixes |
| `/fix-ci` | 🟢 Medium | CI blocker resolution | Medium | Debugging workflow, may prompt for fixes |
| `/debug` | 🟢 Medium | Error investigation | Medium | Interactive debugging prompts likely |
| `/gate-ci` | 🟢 Medium | CI quality gate | Low | Beta status, may be simple |
| `/gate-sec` | 🟢 Medium | Security gate | Low | Beta status, may be simple |

**Estimated time**: 1.5 days for all 5 commands

---

### Priority 4: Project Management (Low-Medium Usage)

**One-time or infrequent commands** - Important but not on critical path.

| Command | Priority | Reason | Estimated Effort | Issues |
|---------|----------|--------|------------------|--------|
| `/init-project` | 🟢 Medium | One-time setup | High | Interactive questionnaire (15 questions) |
| `/roadmap` | 🟢 Medium | Feature planning | Medium | May have interactive brainstorming |
| `/update-project-config` | 🔵 Low | Infrequent updates | Low | Simple config updates |
| `/finalize` | 🟢 Medium | Workflow completion | Low | Cleanup tasks, likely safe |
| `/feature` | 🔴 Critical | Main orchestrator | High | **Complex: orchestrates all phases** |

**Estimated time**: 2 days for all 5 commands

**Note**: `/feature` is critical but should be refactored **after** all phase commands, since it orchestrates them.

---

### Priority 5: Deployment Support (Low Usage)

**Supporting deployment commands** - Used in specific scenarios.

| Command | Priority | Reason | Estimated Effort | Issues |
|---------|----------|--------|------------------|--------|
| `/deploy-status` | 🔵 Low | Status display | Low | Read-only, safe |
| `/validate-deploy` | 🔵 Low | Pre-deployment validation | Low | Validation checks, safe |
| `/test-deploy` | 🔵 Low | Dry-run testing | Low | Non-destructive test |
| `/deployment-budget` | 🔵 Low | Quota tracking | Low | Metrics display, safe |
| `/check-env` | 🔵 Low | Env var validation | Low | Simple checks |

**Estimated time**: 1 day for all 5 commands

---

### Priority 6: Infrastructure (Beta, Low Usage)

**Feature flags, contracts, fixtures** - Beta features, can wait.

| Command | Priority | Reason | Estimated Effort | Issues |
|---------|----------|--------|------------------|--------|
| `/contract-bump` | 🔵 Low | API versioning | Medium | Beta status |
| `/contract-verify` | 🔵 Low | Contract compatibility | Medium | Beta status |
| `/flag-add` | 🔵 Low | Feature flag creation | Low | Beta status |
| `/flag-list` | 🔵 Low | Flag inventory | Low | Beta status |
| `/flag-cleanup` | 🔵 Low | Flag removal | Low | Beta status |
| `/fixture-refresh` | 🔵 Low | Test data sync | Medium | Beta status |

**Estimated time**: 1.5 days for all 6 commands

---

### Priority 7: Metrics & Scheduling (Beta, Low Usage)

**Non-critical supporting features** - Can be refactored last.

| Command | Priority | Reason | Estimated Effort | Issues |
|---------|----------|--------|------------------|--------|
| `/metrics` | 🔵 Low | HEART metrics | Medium | Complex Lighthouse integration |
| `/metrics-dora` | 🔵 Low | DORA metrics | Medium | Beta status |
| `/scheduler-assign` | 🔵 Low | Task scheduling | Low | Beta status |
| `/scheduler-list` | 🔵 Low | Task inventory | Low | Beta status |
| `/scheduler-park` | 🔵 Low | Feature parking | Low | Beta status |
| `/dev-docs` | 🔵 Low | Doc generation | Low | Beta status |
| `/init-brand-tokens` | 🔵 Low | Design system init | Low | Beta status |

**Estimated time**: 2 days for all 7 commands

---

### Priority 8: Internal/Special (Internal Use)

**Workflow development commands** - Low priority.

| Command | Priority | Reason | Estimated Effort | Issues |
|---------|----------|--------|------------------|--------|
| `/release` | 🔵 Low | Package release | Medium | Internal use only |
| `/route-agent` | 🔵 Low | Agent routing | Low | Internal helper |
| `/help` | 🟢 Medium | Help system | Low | Read-only, but high visibility |
| `/quick` | 🟢 Medium | Skip-phases workflow | Medium | Orchestrator like `/feature` |

**Estimated time**: 1 day for all 4 commands

---

## Refactor Effort Summary

| Priority Tier | Commands | Estimated Days | Critical Path |
|---------------|----------|----------------|---------------|
| **P1: Critical Path** | 5 | 2-3 | ✅ Yes |
| **P2: Deployment Pipeline** | 5 | 2 | ✅ Yes |
| **P3: Quality & Validation** | 5 | 1.5 | ⚠️ Partial |
| **P4: Project Management** | 5 | 2 | ✅ Yes (`/feature`) |
| **P5: Deployment Support** | 5 | 1 | ❌ No |
| **P6: Infrastructure (Beta)** | 6 | 1.5 | ❌ No |
| **P7: Metrics & Scheduling** | 7 | 2 | ❌ No |
| **P8: Internal/Special** | 4 | 1 | ❌ No |
| **Total** | **42 pending** | **13-14 days** | - |

**Already completed**: 5 commands (3 days of work)
**Total project**: 47 commands, ~16-17 days

---

## Recommended Execution Plan

### Sprint 1: Core Workflow (Week 1)

**Goal**: Make the primary user workflow non-interactive and deterministic

1. `/spec` (1 day)
2. `/plan` (1 day)
3. `/tasks` (0.5 day)
4. `/implement` (1.5 days)
5. `/ship` (1.5 days)

**Total**: 5.5 days

**Benefits**:
- Users can run full workflow without prompts
- CI/CD integration possible
- Most common path is stable

---

### Sprint 2: Deployment & Quality (Week 2)

**Goal**: Stabilize deployment pipeline and quality gates

1. `/optimize` (1.5 days)
2. `/preview` (0.5 day)
3. `/ship-staging` (1 day)
4. `/validate-staging` (0.5 day)
5. `/ship-prod` (1 day)
6. `/validate` (1 day)

**Total**: 5.5 days

**Benefits**:
- Complete deployment workflow is deterministic
- Quality gates are enforceable in CI
- Production deployments are safer

---

### Sprint 3: Orchestrators & Support (Week 3)

**Goal**: Refactor high-level orchestrators and supporting commands

1. `/feature` (2 days)
2. `/quick` (1 day)
3. `/init-project` (1.5 days)
4. `/roadmap` (1 day)

**Total**: 5.5 days

**Benefits**:
- All primary user-facing commands refactored
- Project initialization is non-interactive
- Feature planning is deterministic

---

### Sprint 4: Cleanup & Beta (Week 4)

**Goal**: Finish remaining commands and beta features

1. All P5-P8 commands (13 commands, 5.5 days)

**Total**: 5.5 days

**Benefits**:
- 100% command coverage
- Beta features are production-ready
- Infrastructure commands are stable

---

## Common Issues to Watch For

Based on the 5 refactors already completed, expect these patterns:

### 1. Interactive Editor Opening

**Before**:
```bash
code --wait "$FILE"
```

**After**: Remove entirely, use LLM-based edits or structured updates

**Examples**: `/constitution`, potentially `/plan`

---

### 2. Interactive Prompts

**Before**:
```bash
read -p "Commit changes? (yes/no): " SHOULD_COMMIT
```

**After**: Fail fast with actionable error

```bash
if ! git diff --quiet; then
  echo "❌ Uncommitted changes detected"
  echo "Fix: git add . && git commit -m 'message'"
  exit 1
fi
```

**Examples**: `/deploy-prod`, potentially `/spec`, `/implement`

---

### 3. Missing Tool Checks

**Before**: Assumes tools exist, fails deep in script

**After**: Preflight checks with `need()` function

```bash
need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ Missing required tool: $1"
    echo "   Install via: brew install $1"
    exit 1
  }
}

need git
need gh
need yq
need jq
```

**Examples**: All commands

---

### 4. Typos and Syntax Errors

**Before**: `n#` instead of `#`, missing quotes

**After**: Clean syntax, shellcheck validation

**Examples**: `/build-local`, `/deploy-prod` (both had `n#` typos)

---

### 5. Missing Error Traps

**Before**: Failures leave orphaned state

**After**: Trap ensures cleanup

```bash
on_error() {
  echo "⚠️  Error in /command. Marking phase as failed."
  complete_phase_timing "$FEATURE_DIR" "phase" 2>/dev/null || true
  update_workflow_phase "$FEATURE_DIR" "phase" "failed" 2>/dev/null || true
}
trap on_error ERR
```

**Examples**: All commands should have this

---

### 6. Vague Error Messages

**Before**: "Error occurred"

**After**: Actionable instructions

```bash
echo "❌ Workflow missing 'on: workflow_dispatch' trigger"
echo "   Required for manual deployment via gh CLI"
echo ""
echo "Add to .github/workflows/deploy.yml:"
echo "  on:"
echo "    workflow_dispatch:"
```

**Examples**: `/deploy-prod`, should be applied to all commands

---

### 7. Hardcoded Paths

**Before**: Assumes current directory is correct

**After**: Deterministic repo root

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
```

**Examples**: All commands

---

### 8. Platform-Specific Assumptions

**Before**: Bash-only or Windows-only

**After**: OS detection and branching

```bash
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  # Windows
  pwsh -Command "..."
else
  # Unix
  bash script.sh
fi
```

**Examples**: Commands with PowerShell/bash alternatives

---

## Metrics & Success Criteria

### Per-Command Success Criteria

- ✅ No interactive prompts (`read -p`, `code --wait`)
- ✅ Strict bash mode (`set -Eeuo pipefail`)
- ✅ Error trap (`trap on_error ERR`)
- ✅ Tool preflight checks (`need()` function)
- ✅ Deterministic repo root
- ✅ Actionable error messages
- ✅ Concrete examples (no vague instructions)
- ✅ Comprehensive documentation (`*-REFACTOR-v2.md`)
- ✅ Cross-platform (Windows + Unix tested)
- ✅ Idempotent (safe to re-run)

### Project-Wide Metrics

**Current state**:
- 5 / 47 commands refactored (11%)
- ~3 days of work completed
- 0 interactive prompts in refactored commands
- 100% error trap coverage in refactored commands

**Target state** (after Sprint 1):
- 10 / 47 commands refactored (21%)
- Core workflow is non-interactive
- CI/CD integration is possible

**Target state** (after Sprint 2):
- 16 / 47 commands refactored (34%)
- Deployment pipeline is deterministic
- Production deployments are safe

**Target state** (after Sprint 4):
- 47 / 47 commands refactored (100%)
- All commands follow v2.0 pattern
- Workflow is fully automated

---

## Directory Reorganization

**After refactors complete**, reorganize into subdirectories:

1. Create subdirectories (`core/`, `phases/`, `deployment/`, etc.)
2. Move commands to appropriate subdirectories
3. Update slash command loader to search subdirectories
4. Update references in skills and agents
5. Add symlinks for backward compatibility
6. Update README.md with new structure
7. Migrate over 2-3 weeks with feature flags

**Estimated effort**: 1-2 days after all refactors complete

---

## Testing Strategy

### Per-Command Testing

1. **Syntax check**: `shellcheck command.md` (extract bash blocks)
2. **Dry-run test**: Run command in test feature directory
3. **Error path test**: Trigger each error condition and verify messages
4. **Windows test**: Run on Windows with PowerShell
5. **Unix test**: Run on macOS/Linux with bash
6. **CI test**: Run in GitHub Actions (if applicable)

### Integration Testing

1. **Full workflow test**: `/feature` → `/ship` end-to-end
2. **Error recovery test**: Trigger failure, verify state cleanup
3. **Idempotency test**: Run same command twice, verify no side effects
4. **Parallel test**: Run multiple features concurrently

---

## Resources & References

- **v2.0 Pattern Examples**:
  - `.spec-flow/memory/BUILD-LOCAL-REFACTOR-v2.md`
  - `.spec-flow/memory/BRANCH-ENFORCE-REFACTOR-v2.md`
  - `.spec-flow/memory/CLARIFY-REFACTOR-v2.md`
  - `.spec-flow/memory/CONSTITUTION-REFACTOR-v2.md`
  - `.spec-flow/memory/DEPLOY-PROD-REFACTOR-v2.md`

- **Evidence-Backed Standards**:
  - WCAG 2.2 AA: https://www.w3.org/TR/WCAG22/
  - OWASP ASVS L2: https://owasp.org/www-project-application-security-verification-standard/
  - Google Code Review: https://google.github.io/eng-practices/review/
  - Conventional Commits: https://www.conventionalcommits.org/
  - Keep a Changelog: https://keepachangelog.com/
  - SemVer: https://semver.org/

- **Bash Best Practices**:
  - Use shellcheck: https://www.shellcheck.net/
  - Google Shell Style Guide: https://google.github.io/styleguide/shellguide.html
  - Bash strict mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/

---

## Next Actions

1. **Start Sprint 1**: Refactor `/spec` command
2. **Update README.md**: Mark commands as refactored in progress
3. **Create tracking board**: GitHub Project or similar
4. **Set up CI**: Add shellcheck to PR checks
5. **Document patterns**: Create shared bash library for common functions (`need()`, `on_error()`)

---

**Status**: 11% complete (5/47 commands)
**Next Command**: `/spec` (P1: Critical Path)
**Estimated Completion**: 16-17 days total, 13-14 days remaining
**Last Updated**: 2025-11-10
