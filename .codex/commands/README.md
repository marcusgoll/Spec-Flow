# Slash Commands Reference

**Location**: `.codex/commands/`
**Purpose**: Codex adapter surfaces for the Spec-Flow workflow

> Codex compatibility: see `CODEX_COMPATIBILITY.md` for the substitutions to use when a command references Claude-only tools (Task, AskUserQuestion, Skill, SlashCommand). Run the embedded bash/PowerShell blocks directly and load skills via `.codex/skills/test-skill-call.js` instead of calling subagents.

These command files are primarily adapter surfaces over the shared execution
engine in `.spec-flow/scripts/`, with Codex-specific compatibility guidance
where the tool behavior differs from Claude.

---

## Command Index by Category

### Core Workflow Commands

**Primary orchestrators that users interact with directly**

| Command | Description | Status | Version |
|---------|-------------|--------|---------|
| `/feature` | Create and orchestrate complete feature workflow | ✅ Stable | - |
| `/help` | Show contextual workflow state and next steps | ✅ Stable | - |
| `/quick` | Quick implementation (skip spec/plan/tasks for small changes) | ✅ Stable | - |
| `/route-agent` | Internal helper to route tasks to specialist agents | ⚙️ Internal | - |

---

### Phase Commands

**Sequential workflow phases (invoked by `/feature` or manually)**

| Command | Description | Status | Version | Refactor |
|---------|-------------|--------|---------|----------|
| `/spec` | Create feature specification from natural language | ✅ Stable | v2.0 | ✅ Done |
| `/clarify` | Reduce spec ambiguity via targeted questions | ✅ Stable | v2.0 | ✅ Done |
| `/plan` | Generate design artifacts from feature spec | ✅ Stable | v2.0 | ✅ Done |
| `/tasks` | Generate concrete TDD tasks from design artifacts | ✅ Stable | v2.0 | ✅ Done |
| `/implement` | Execute tasks with TDD, anti-duplication checks | ✅ Stable | v2.0 | ✅ Done |
| `/validate` | Cross-artifact consistency analysis | ✅ Stable | - | ⏳ Needs v2.0 |
| `/optimize` | Production readiness validation (perf, security, a11y) | ✅ Stable | v2.0 | ✅ Done |
| `/preview` | Manual UI/UX testing on local dev server | ⚠️ Not shipped here | - | Compatibility shim only |
| `/finalize` | Workflow completion, artifact archival, roadmap update | ✅ Stable | - | ⏳ Needs v2.0 |
| `/debug` | Debug errors and update error-log.md | ✅ Stable | - | ⏳ Needs v2.0 |

---

### Deployment Commands

**Deployment orchestration and validation**

| Command | Description | Status | Version | Refactor |
|---------|-------------|--------|---------|----------|
| `/ship` | Unified deployment orchestrator (all models) | ✅ Stable | - | ⏳ Needs v2.0 |
| `/ship-staging` | Deploy to staging with auto-merge | ✅ Stable | - | ⏳ Needs v2.0 |
| `/validate-staging` | Manual staging validation before production | ✅ Stable | - | ⏳ Needs v2.0 |
| `/ship-prod` | Automated staging→production promotion | ✅ Stable | - | ⏳ Needs v2.0 |
| `/deploy-prod` | Direct production deployment (no staging) | ⚙️ Internal | v2.0 | ✅ Done |
| `/deploy-status` | Real-time deployment status display | ✅ Stable | - | ⏳ Needs v2.0 |
| `/validate-deploy` | Validate deployment configuration without deploying | ✅ Stable | - | ⏳ Needs v2.0 |
| `/test-deploy` | Test deployment configuration dry-run | ✅ Stable | - | ⏳ Needs v2.0 |
| `/deployment-budget` | Track deployment quota usage (Vercel limits) | ✅ Stable | - | ⏳ Needs v2.0 |
| `/check-env` | Validate environment variables before deployment | ✅ Stable | - | ⏳ Needs v2.0 |

---

### Quality Gates

**Pre-deployment quality validation**

| Command | Description | Status | Version | Refactor |
|---------|-------------|--------|---------|----------|
| `/gate-ci` | CI quality gate (tests, linters, coverage) | 🚧 Beta | - | ⏳ Needs v2.0 |
| `/gate-sec` | Security gate (SAST, secrets scan, dependencies) | 🚧 Beta | - | ⏳ Needs v2.0 |
| `/fix-ci` | Fix CI/deployment blockers after /ship creates PR | ✅ Stable | v2.0 | ✅ Done |

---

### Infrastructure Commands

Planned surfaces only. These infrastructure command files are not shipped in
this checkout.

**API contracts, feature flags, test fixtures**

| Command | Description | Status | Version | Refactor |
|---------|-------------|--------|---------|----------|
| `/contract-bump` | Planned contract-governance surface | 📝 Planned | - | Not shipped in this checkout |
| `/contract-verify` | Planned contract-governance surface | 📝 Planned | - | Not shipped in this checkout |
| `/flag-add` | Planned feature-flag creation surface | 📝 Planned | - | Not shipped in this checkout |
| `/flag-list` | Planned feature-flag inventory surface | 📝 Planned | - | Not shipped in this checkout |
| `/flag-cleanup` | Planned feature-flag cleanup surface | 📝 Planned | - | Not shipped in this checkout |
| `/fixture-refresh` | Planned fixture refresh surface | 📝 Planned | - | Not shipped in this checkout |

---

### Project Management

**Project initialization, roadmap, metrics**

| Command | Description | Status | Version | Refactor |
|---------|-------------|--------|---------|----------|
| `/init-project` | Initialize project design docs (one-time setup) | ✅ Stable | - | ⏳ Needs v2.0 |
| `/roadmap` | Manage product roadmap (brainstorm, prioritize, track) | ✅ Stable | - | ⏳ Needs v2.0 |
| `/constitution` | Update engineering principles (8 core standards) | ✅ Stable | v2.0 | ✅ Done |
| `/update-project-config` | Update project configuration (deployment model, scale tier) | ✅ Stable | - | ⏳ Needs v2.0 |
| `/init-brand-tokens` | Initialize design system brand tokens | 🚧 Beta | - | ⏳ Needs v2.0 |

---

### Metrics & Monitoring

Planned surfaces only. These metric command files are not shipped in this
checkout.

**Performance tracking, DORA metrics**

| Command | Description | Status | Version | Refactor |
|---------|-------------|--------|---------|----------|
| `/metrics` | Planned HEART metrics surface | 📝 Planned | - | Not shipped in this checkout |
| `/metrics-dora` | Planned DORA metrics surface | 📝 Planned | - | Not shipped in this checkout |

---

### Build & CI

**Local build, branch enforcement**

| Command | Description | Status | Version | Refactor |
|---------|-------------|--------|---------|----------|
| `/build-local` | Local build and validation (no deployment) | ✅ Stable | v2.0 | ✅ Done |
| `/branch-enforce` | Enforce trunk-based development (24h branch lifetime) | ✅ Stable | v2.0 | ✅ Done |

---

### Task Scheduling

Planned surfaces only. These scheduler commands and files are not shipped in
this checkout.

**Workload management across features**

| Command | Description | Status | Version | Refactor |
|---------|-------------|--------|---------|----------|
| `/scheduler-assign` | Planned epic-to-agent assignment surface | 📝 Planned | - | Not shipped in this checkout |
| `/scheduler-list` | Planned scheduler inventory surface | 📝 Planned | - | Not shipped in this checkout |
| `/scheduler-park` | Planned blocked-epic parking surface | 📝 Planned | - | Not shipped in this checkout |

---

### Internal Commands

**Workflow development and release management**

| Command | Description | Status | Version | Refactor |
|---------|-------------|--------|---------|----------|
| `/release` | Release new version of Spec-Flow package | ⚙️ Internal | - | ⏳ Needs v2.0 |

---

## Command Status Legend

- ✅ **Stable**: Production-ready, well-tested
- 🚧 **Beta**: Functional but may change
- ⚙️ **Internal**: Called by other commands, not for direct use
- ⏳ **Needs v2.0**: Requires refactoring to v2.0 pattern
- ✅ **Done**: Already refactored to v2.0

---

## v2.0 Refactor Pattern

Commands marked "Needs v2.0" should be refactored to include:

1. **Strict bash mode**: `set -Eeuo pipefail`
2. **Error trap**: `trap on_error ERR` for cleanup
3. **Tool preflight checks**: `need()` function
4. **Non-interactive**: No `read -p` prompts (fail fast with actionable errors)
5. **Deterministic repo root**: `cd "$(git rev-parse --show-toplevel)"`
6. **Actionable errors**: Clear fix instructions in error messages
7. **Concrete examples**: Evidence-backed with real commands/URLs
8. **Comprehensive docs**: Include REFACTOR-v2.md documentation

**Already refactored (v2.0)**:
- ✅ `/build-local` - Strict bash, Corepack, SBOM generation
- ✅ `/branch-enforce` - Robust detection, JSON output, auto-fix
- ✅ `/clarify` - Anti-hallucination, repo precedent, atomic commits
- ✅ `/constitution` - Structured actions, evidence-backed policies (WCAG, OWASP)
- ✅ `/deploy-prod` - Non-interactive, platform-specific rollback (Vercel, Railway, Netlify, Git)
- ✅ `/optimize` - Parallel checks, binary pass/fail, evidence-backed standards (WCAG, OWASP, Twelve-Factor)
- ✅ `/fix-ci` - Verified GitHub CLI commands, correct tool flags, generic quota handling
- ✅ `/spec` - Consolidated bash (15 blocks → 1), error trap with rollback, tool checks
- ✅ `/plan` - Consolidated bash (9 blocks → 1), removed interactive prompts, project docs mandatory
- ✅ `/tasks` - Consolidated bash sections, anti-hallucination rules, task organization by user stories
- ✅ `/implement` - Consolidated bash (4 blocks → 1), parallel batch execution, TDD workflow, domain-based grouping

---

## Directory Structure

**Current organization** (implemented 2025-11-10):

```
.claude/commands/
├── README.md (this file)
│
├── core/                   (4 commands)
│   ├── feature.md
│   ├── help.md
│   ├── quick.md
│   └── route-agent.md
│
├── phases/                 (10 commands)
│   ├── spec.md
│   ├── clarify.md
│   ├── plan.md
│   ├── tasks.md
│   ├── implement.md
│   ├── validate.md
│   ├── optimize.md
│   ├── preview.md
│   ├── finalize.md
│   └── debug.md
│
├── deployment/             (10 commands)
│   ├── ship.md
│   ├── ship-staging.md
│   ├── validate-staging.md
│   ├── ship-prod.md
│   ├── deploy-prod.md
│   ├── deploy-status.md
│   ├── validate-deploy.md
│   ├── test-deploy.md
│   ├── deployment-budget.md
│   └── check-env.md
│
├── quality/                (3 commands)
│   ├── gate-ci.md
│   ├── gate-sec.md
│   └── fix-ci.md
│
├── infrastructure/         (planned, not shipped here)
│   └── [no infrastructure command files in this checkout]
│
├── project/                (5 commands)
│   ├── init-project.md
│   ├── roadmap.md
│   ├── constitution.md
│   ├── update-project-config.md
│   └── init-brand-tokens.md
│
├── metrics/                (planned, not shipped here)
│   └── [no metrics command files in this checkout]
│
├── build/                  (2 commands)
│   ├── build-local.md
│   └── branch-enforce.md
│
├── scheduling/             (planned, not shipped here)
│   └── [no scheduler command files in this checkout]
│
└── internal/               (1 command)
    └── release.md
```

**Directory Benefits**:
- Improved navigation and discoverability
- Logical grouping by function
- Easier to find related commands
- Scalable as new commands are added

**Note**: Slash command loader automatically searches subdirectories

---

## Typical Workflows

### Greenfield Feature (Full Workflow)

```bash
/init-project              # One-time project setup
/roadmap                   # Brainstorm and prioritize features
/feature "User login"      # Orchestrates: spec → clarify → plan → tasks → implement
/ship                      # Orchestrates: optimize → preview → deploy (model-specific)
```

### Brownfield Feature (Existing Project)

```bash
/feature "Add password reset"
/ship
```

### Quick Fix (Skip Planning)

```bash
/quick "Fix typo in navbar"
```

### Debug Workflow

```bash
/implement                 # Fails with error
/debug                     # Investigate and track error
/implement                 # Retry after fix
```

### Manual Phase Control

```bash
/spec "Dark mode toggle"
/clarify                   # If ambiguities found
/plan
/tasks
/implement
/validate                  # Cross-artifact consistency check
/optimize                  # Quality gates
# /preview                 # Optional local/manual preview if your adapter ships it
/ship                      # Deploy
```

---

## Command Conventions

### Frontmatter (YAML)

All commands should have:

```yaml
---
description: Brief description (used in command list)
internal: true  # Optional: mark as internal-only
---
```

### Command Structure

**Recommended sections**:

1. **Purpose**: What the command does
2. **When to use**: Specific scenarios
3. **Prerequisites**: What must be complete before running
4. **Phases**: Numbered execution steps with bash/PowerShell code
5. **Error Recovery**: Common failures and fixes
6. **Success Criteria**: What "done" looks like
7. **Notes**: Important caveats or context

### Bash/PowerShell Blocks

**All scripts should**:
- Use strict mode (`set -Eeuo pipefail` for bash)
- Include error traps
- Check for required tools early
- Provide actionable error messages
- Be idempotent (safe to re-run)

---

## Adding New Commands

1. **Create command file**: `.claude/commands/your-command.md`
2. **Add frontmatter**:
   ```yaml
   ---
   description: What your command does
   ---
   ```
3. **Follow v2.0 pattern**: See "v2.0 Refactor Pattern" above
4. **Update this README**: Add to appropriate category table
5. **Test**: Verify command works on Windows and Unix
6. **Document**: Create `REFACTOR-v2.md` in `.spec-flow/memory/`
7. **Commit**: Use Conventional Commits format

---

## References

- **Workflow Overview**: `CLAUDE.md` (project root)
- **Architecture**: `docs/architecture.md`
- **Command Details**: `docs/commands.md`
- **Agent Briefs**: `.claude/agents/`
- **Refactor Docs**: `.spec-flow/memory/*-REFACTOR-v2.md`

---

**Last Updated**: 2025-11-10
**Commands**: 46 total (11 refactored to v2.0, 35 pending)
**Next Priority**: Refactor `/validate` and `/finalize`, and either restore or remove the `/preview` adapter surface
