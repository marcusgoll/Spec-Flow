# Getting Started with Spec-Flow

Welcome to Spec-Flow! This guide will walk you through building your first feature using the Spec-Driven Development workflow.

## What You'll Build

In this tutorial, you'll use Spec-Flow to plan and implement a Dark Mode Toggle
feature. For a checked-in example, refer to
`docs/examples/flightpro-sample-project/`. By the end, you'll understand how
to:

- Build and prioritize your roadmap with ICE scoring
- Create a feature specification from a roadmap entry
- Generate an implementation plan
- Break down work into tasks
- Track progress through the workflow phases
- Ship to production

**Estimated time**: 30 minutes (reading) + 2-4 hours (implementation)

## Prerequisites

Before starting, ensure you have:

- ✅ **Git 2.39+** installed
- ✅ **PowerShell 7.3+** (Windows/Mac/Linux) OR **Bash 5+** (Mac/Linux)
- ✅ **Python 3.10+** installed
- ✅ **Claude Code** access with slash command support
- ✅ **Your project repository** cloned and ready

### Verify Prerequisites

**Windows (PowerShell)**:

```powershell
pwsh -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Json
```

**Mac/Linux (Bash)**:

```bash
.spec-flow/scripts/bash/check-prerequisites.sh --json
```

If all checks pass ✅, you're ready to go!

## Step 1: Set Up Your Claude Code Permissions

Before Claude can work with Spec-Flow, configure access permissions:

1. Copy the example settings:

   ```bash
   cp .claude/settings.example.json .claude/settings.local.json
   ```

2. Edit `.claude/settings.local.json` and add your project path:

   ```json
   {
     "permissions": {
       "allow": [
         "Read(/path/to/your/project)",
         "Write(/path/to/your/project)",
         "Edit(/path/to/your/project)"
       ]
     }
   }
   ```

3. Restart Claude Code to apply the changes

## Step 2: Understand the Workflow

Spec-Flow follows a fixed sequence of phases:

```
┌─────────────┐
│  /roadmap   │  Phase -1: Add features, prioritize with ICE scoring
└─────┬───────┘
      │
┌─────▼───────┐
│   /spec     │  Phase 0: Write the specification (from roadmap)
└─────┬───────┘
      │
┌─────▼───────┐
│  /clarify   │  Phase 0.5: Resolve ambiguities (if needed)
└─────┬───────┘
      │
┌─────▼───────┐
│   /plan     │  Phase 1: Create implementation plan
└─────┬───────┘
      │
┌─────▼───────┐
│   /tasks    │  Phase 2: Break into 20-30 tasks
└─────┬───────┘
      │
┌─────▼───────┐
│  /validate  │  Phase 3: Check consistency & risks
└─────┬───────┘
      │
┌─────▼────────┐
│ /implement   │  Phase 4: Execute all tasks
└─────┬────────┘
      │
┌─────▼────────┐
│ /optimize    │  Phase 5: Code review & optimization
└─────┬────────┘
      │
┌─────▼────────┐
│ Local Preview│  Optional: Validate UI/UX locally
└─────┬────────┘
      │
┌─────▼─────────┐
│/ship-staging  │  Phase 7: Deploy to staging
└─────┬─────────┘
      │
┌─────▼──────────────┐
│ /validate-staging  │  Manual Gate: Test on staging
└─────┬──────────────┘
      │
┌─────▼─────────┐
│  /ship-prod   │  Phase 9: Deploy to production
└───────────────┘
```

**Pro tip**: Use `/feature "Feature name"` to automate progression through phases with manual gates.

## Step 3: Document Your Engineering Principles

Before building features, establish your team's engineering principles:

```bash
# In Claude Code
/constitution
```

This creates `.spec-flow/memory/constitution.md` with principles that govern every feature. Review and customize it for your project.

**Example principles** (from our AKTRACS project):

- Specification first - every artifact traces to requirements
- Do not overengineer - ship value, iterate later
- Testing standards - ≥80% coverage required
- Performance requirements - define and enforce thresholds

## Step 4: Build Your Roadmap

Before implementing features, plan what you want to build:

```bash
# In Claude Code
/roadmap
```

This will:

1. Create or update roadmap items as GitHub Issues
2. Help you add new feature ideas
3. Prioritize features using ICE scoring (Impact × Confidence / Effort)
4. Organize features into: Backlog → Next → In Progress → Shipped

**Add a feature to your roadmap**:

- **Title**: "Dark Mode Toggle"
- **Area**: app (marketing/app/api/infra)
- **Role**: all (student/cfi/school/all)
- **Impact**: 4 (how much value for users?)
- **Effort**: 2 (how many weeks?)
- **Confidence**: 0.9 (how certain are estimates?)
- **ICE Score**: (4 × 0.9) / 2 = 1.8

Roadmap will sort features by ICE score automatically.

## Step 5: Create Your First Feature

Now select a feature from your roadmap and build it!

### 5.1 Start the Specification

```bash
# In Claude Code
/spec "dark-mode-toggle"  # Use the slug from your roadmap
```

Claude will:

1. Look up the feature in your GitHub Issues roadmap
2. Create `specs/001-dark-mode-toggle/` directory
3. Generate `spec.md` with requirements and acceptance criteria (using roadmap context)
4. Create `NOTES.md` for tracking progress
5. Scaffold `visuals/README.md` for design references
6. Move the roadmap feature from "Backlog" or "Next" to "In Progress"

### 5.2 Review the Specification

Open `specs/001-dark-mode-toggle/spec.md` and review:

- **User Scenarios**: Who uses this and how?
- **Acceptance Scenarios**: Given/When/Then test cases
- **Functional Requirements**: Testable capabilities (FR-001, FR-002, etc.)
- **Non-Functional Requirements**: Performance, accessibility, mobile

Look for `[NEEDS CLARIFICATION]` markers. If you find any, continue to Step 5.3. Otherwise, skip to Step 6.

### 5.3 Clarify Ambiguities (If Needed)

```bash
/clarify
```

Claude will:

1. Ask questions about ambiguous requirements
2. Update the spec with clarifications
3. Mark the spec as "clear for planning"

## Step 6: Generate Implementation Plan

```bash
/plan
```

Claude creates `artifacts/plan.md` with:

- **Architecture decisions** (with rationale and alternatives considered)
- **Implementation phases** (infrastructure, components, testing)
- **Risk assessment** (identified risks and mitigation strategies)
- **File structure** (what files to create/modify)
- **Timeline estimate** (breakdown by phase)

**What to review**:

- Are the architecture decisions sound?
- Do the risks make sense?
- Is the timeline reasonable?

## Step 7: Break Down Into Tasks

```bash
/tasks
```

Claude generates `artifacts/tasks.md` with 20-30 specific tasks:

- Each task has clear acceptance criteria
- Dependencies are mapped
- Effort estimates provided
- Priority assigned (P0 = critical, P1 = high, P2 = medium)

**Example tasks**:

- T001: Create ThemeContext boilerplate (0.5 hours, P0)
- T002: Implement theme state management (1 hour, P0)
- T015: Create ThemeToggle component (0.5 hours, P0)

## Step 8: Validate Consistency & Risks

```bash
/validate
```

Claude reviews:

- **Spec ↔ Plan alignment**: Are all requirements covered?
- **Plan ↔ Tasks alignment**: Do tasks match phases?
- **Risk assessment**: Are risks adequately mitigated?
- **Test coverage**: Are critical paths tested?

If **critical issues** are found, Claude pauses and asks you to fix them before continuing.

## Step 9: Implement the Feature

```bash
/implement
```

Claude will:

1. Route tasks to appropriate specialist agents (frontend, backend, QA)
2. Execute tasks in dependency order
3. Write code, tests, and documentation
4. Update NOTES.md with checkpoints
5. Track progress (e.g., "28/28 tasks completed")

**Your role**:

- Review code as it's written
- Run tests locally to verify
- Provide feedback if something doesn't look right

**Monitoring context budget**:

```powershell
# Check current token usage
pwsh -File .spec-flow/scripts/powershell/calculate-tokens.ps1 -FeatureDir specs/001-dark-mode-toggle
```

If you exceed the budget (75k/100k/125k depending on phase), Claude will auto-compact context.

## Step 10: Optimize & Code Review

```bash
/optimize
```

Claude performs:

- **Code review** (KISS, DRY, naming, test coverage)
- **Performance analysis** (benchmarks vs targets)
- **Accessibility audit** (WCAG 2.1 AA compliance)
- **Security review** (no vulnerabilities)

If **blockers** are found, Claude may offer auto-fix or ask you to resolve manually.

## Step 11: Optional Local Preview

```bash
# If your installed workflow adapter ships /preview
/preview
```

If `/preview` is installed in your tool adapter, it can generate:

- **Release notes** draft
- **Preview checklist** for manual testing

Whether or not `/preview` is installed, your action is the same:

1. Run local dev server (`npm run dev`, `make dev`, etc.)
2. Test the feature manually
3. Verify it matches the spec
4. Check visuals against `visuals/README.md` patterns

If your adapter does not ship `/preview`, treat this as a manual local gate and continue to staging when satisfied.

## Step 12: Ship to Staging

```bash
/ship-staging
```

Claude will:

1. Create a pull request to the `staging` branch
2. Wait for CI checks to pass
3. Auto-merge (if configured)
4. Trigger deployment to staging environment

**What happens**:

- PR created with full context
- Tests run automatically
- Code review requested (if CODEOWNERS configured)
- Merged when all checks pass ✅

## Step 13: Validate on Staging (Manual Gate)

```bash
/validate-staging
```

Claude generates a validation checklist:

**Your action**:

1. Test the feature on staging environment
2. Run E2E tests (if automated)
3. Check Lighthouse scores (performance, accessibility)
4. Confirm no regressions

If validation passes, approve for production.

## Step 14: Ship to Production

```bash
/ship-prod
```

Claude will:

1. Switch to the `staging` branch
2. Create a pull request to `main`
3. Wait for CI checks
4. Auto-merge and deploy to production
5. Create a GitHub release with version tag
6. Update the roadmap (move feature to "Shipped")

🎉 **Congratulations!** Your feature is now live in production.

**Note**: The `/ship-prod` command automatically:

- Moves your feature from "In Progress" to "Shipped" in the roadmap
- Updates the roadmap with release version and date
- Allows you to start building the next feature from your roadmap

## What's Next?

### Learn More About Spec-Flow

- **Architecture**: Read [docs/architecture.md](architecture.md) for system design
- **Commands**: See [docs/commands.md](commands.md) for full command reference
- **Contributing**: Review [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines
- **Examples**: Explore `docs/examples/flightpro-sample-project/` for a
  checked-in example project

### Advanced Workflows

**Resume after interruption**:

```bash
/feature continue
```

Claude detects the last completed phase and resumes automatically.

**Debug failures**:

```bash
/debug
```

Claude analyzes error logs and suggests fixes.

**Fix CI failures**:

```bash
/checks pr 123
```

Claude identifies and fixes deployment blockers.

### Tips for Success

1. **Start small** - Begin with a simple feature (like dark mode) to learn the workflow
2. **Review incrementally** - Don't wait until implementation is done; review code as it's written
3. **Use checkpoints** - NOTES.md tracks decisions; refer back when you need context
4. **Compact proactively** - If approaching token limits, run `compact-context.ps1` manually
5. **Validate early** - Test on staging thoroughly before production deployment

### Common Patterns

**Create multiple features**:

```bash
/spec "User authentication"
# Work through phases...
/ship-prod

# Start next feature
/spec "Profile settings page"
```

**Batch operations**:

```bash
# Create several specs, then bulk plan them
/spec "Feature A"
/spec "Feature B"
/spec "Feature C"

# Then plan each
/plan  # for Feature A
# Switch to Feature B directory
/plan  # for Feature B
```

## Troubleshooting

### "No feature directory found"

**Solution**: Run `/spec "Feature name"` first to create the directory structure.

### "Context budget exceeded"

**Solution**: Run the compact-context script:

```powershell
pwsh -File .spec-flow/scripts/powershell/compact-context.ps1 -FeatureDir specs/001-feature-name -Phase implementation
```

### "Permission denied" errors

**Solution**: Check `.claude/settings.local.json` has the correct paths in the `allow` list.

### "Command not found: /spec"

**Solution**: Ensure slash commands are enabled in Claude Code. Check `.claude/commands/` exists.

For more troubleshooting, see [docs/troubleshooting.md](troubleshooting.md).

## Get Help

- **GitHub Issues**: [Report bugs or request features](https://github.com/marcusgoll/Spec-Flow/issues)
- **Repository**: [Spec-Flow on GitHub](https://github.com/marcusgoll/Spec-Flow)
- **Examples**: Browse `docs/examples/flightpro-sample-project/` for reference

## Next Steps

Now that you've completed your first feature, try:

1. Building a more complex feature with backend + frontend changes
2. Customizing the templates in `.spec-flow/templates/`
3. Adding custom agent briefs in `.claude/agents/`
4. Contributing improvements back to Spec-Flow!

Happy building! 🚀
