---
description: Generate 8 project design documents (overview, architecture, tech-stack, data, API, capacity, deployment, workflow) via interactive questionnaire or config file
allowed-tools: [Bash, Read, Write, Task, AskUserQuestion]
argument-hint: ["project-name"] [--with-design] [--update|--force|--write-missing-only] [--config FILE] [--ci | --no-input | --interactive]
version: 11.0
updated: 2025-12-09
---

# /init-project — Project Documentation Generator (Hybrid Pattern)

> **v11.0 Architecture**: Uses hybrid pattern - questionnaire in main context (good UX), document generation isolated via Task() (saves ~5-10k tokens).

<context>
**User Input**: $ARGUMENTS

Existing project docs: !`ls -1 docs/project/*.md 2>/dev/null | wc -l` file(s)

Package manager detected: !`test -f package.json && echo "npm/pnpm" || test -f pyproject.toml && echo "python" || test -f Cargo.toml && echo "rust" || test -f go.mod && echo "go" || echo "unknown"`

Brownfield indicators: !`ls package.json requirements.txt Cargo.toml go.mod docker-compose.yml 2>/dev/null | tr '\n' ', ' || echo "greenfield"`
</context>

<architecture>
## Hybrid Pattern (v11.0)

```
User: /init-project "My App"
         │
         ▼
┌──────────────────────────────────────────────────────┐
│ MAIN CONTEXT (questionnaire - good UX)               │
│                                                      │
│ 1. Detect brownfield/greenfield                      │
│ 2. Run 15-48 questions via AskUserQuestion           │
│ 3. Save answers to temp config                       │
│    → .spec-flow/temp/init-answers.yaml               │
└──────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────┐
│ Task(init-project-agent) ← ISOLATED                  │
│                                                      │
│ 1. Read answers from temp config                     │
│ 2. Generate 8 project docs                           │
│ 3. Run quality gates                                 │
│ 4. Create ADR                                        │
│ 5. Return summary                                    │
│ 6. EXIT                                              │
└──────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────┐
│ MAIN CONTEXT (results - minimal tokens)              │
│                                                      │
│ 1. Display success summary                           │
│ 2. Show generated files                              │
│ 3. Suggest next steps                                │
└──────────────────────────────────────────────────────┘
```

**Benefits:**
- Questionnaire has natural interactive UX
- Document generation isolated (saves 5-10k tokens)
- Can re-run generation if session ends mid-way (answers cached)
</architecture>

<objective>
Generate comprehensive project design documentation (8 core files, 4 optional design files) through interactive questionnaire or config file mode.

**Core outputs (always generated):**
1. `docs/project/overview.md` - Vision, users, scope, metrics
2. `docs/project/system-architecture.md` - C4 diagrams, data flows
3. `docs/project/tech-stack.md` - Technology choices with rationale
4. `docs/project/data-architecture.md` - ERD, entity schemas
5. `docs/project/api-strategy.md` - REST/GraphQL patterns, versioning
6. `docs/project/capacity-planning.md` - Scaling model, cost projections
7. `docs/project/deployment-strategy.md` - CI/CD, environments, rollback
8. `docs/project/development-workflow.md` - Git flow, PR process, DoD
9. `docs/adr/0001-project-architecture-baseline.md` - Baseline ADR

**Optional outputs (--with-design flag):**
- 4 design system docs in `docs/design/`
- `design/systems/tokens.css` - WCAG AA compliant design tokens
- `design/systems/tokens.json` - Programmatic token access

**Foundation:**
These docs establish the foundation for `/roadmap` and `/feature` workflows by documenting architectural decisions, tech stack, and development practices.

**Dependencies:**
- Git repository initialized
- Required tools: git, jq, yq (for config file mode)
- Optional: gh (for foundation issue), markdownlint, lychee

**Mode Flags:**
- `--interactive`: Interactive questionnaire mode (15 questions, ~10 min) - default
- `--ci` / `--no-input`: Non-interactive CI/CD mode (reads environment variables)
- `--with-design`: Include design system setup (extended questionnaire with 48 questions)

**Operation Flags:**
- `--update`: Fill `[NEEDS CLARIFICATION]` sections only (preserves existing content)
- `--force`: Overwrite all docs completely (destructive)
- `--write-missing-only`: Only create files that don't exist
- `--config FILE`: Load answers from JSON/YAML config file

**Preference System:**
The command uses 3-tier preferences to determine mode:
1. Config file: `.spec-flow/config/user-preferences.yaml` (default_mode, include_design)
2. Command history: Learns from past usage
3. Command-line flags: Explicit overrides
</objective>

<process>
0. **Load User Preferences (3-Tier System)**:

   **Determine initialization mode using 3-tier preference system:**

   a. **Load configuration file** (Tier 1 - lowest priority):
      ```powershell
      $preferences = & .spec-flow/scripts/utils/load-preferences.ps1 -Command "init-project"
      $configMode = $preferences.commands.'init-project'.default_mode  # "interactive" or "ci"
      $includeDesign = $preferences.commands.'init-project'.include_design  # true or false
      ```

   b. **Load command history** (Tier 2 - medium priority, overrides config):
      ```powershell
      $history = & .spec-flow/scripts/utils/load-command-history.ps1 -Command "init-project"

      if ($history.last_used_mode -and $history.total_uses -gt 0) {
          $preferredMode = $history.last_used_mode  # Use learned preference
      } else {
          $preferredMode = $configMode  # Fall back to config
      }
      ```

   c. **Check command-line flags** (Tier 3 - highest priority):
      ```javascript
      const args = "$ARGUMENTS".trim();
      const hasInteractiveFlag = args.includes('--interactive');
      const hasCIFlag = args.includes('--ci');
      const hasNoInput = args.includes('--no-input');
      const hasWithDesign = args.includes('--with-design');

      let selectedMode;
      let designFlag = '';

      // Determine mode
      if (hasCIFlag || hasNoInput) {
          selectedMode = 'ci';  // CI/automation override
      } else if (hasInteractiveFlag) {
          selectedMode = 'interactive';  // Explicit interactive override
      } else {
          selectedMode = preferredMode;  // Use config/history preference
      }

      // Determine design flag (from config or explicit flag)
      if (hasWithDesign || (includeDesign && !hasNoInput)) {
          designFlag = '--with-design';
      }

      // Build final arguments for script
      const finalArgs = args + ' ' + designFlag;
      ```

   d. **Track usage for learning system**:
      ```powershell
      # Record selection after command completes successfully
      & .spec-flow/scripts/utils/track-command-usage.ps1 -Command "init-project" -Mode $selectedMode
      ```

1. **Detect platform and mode** from processed arguments:
   - Platform: Windows → PowerShell, macOS/Linux → Bash
   - Mode: Use selectedMode from preference system
   - Flags: Pass through operational flags (--update, --force, --config, etc.)
   - Project name: Extract from first positional argument if present

2. **Execute appropriate script** based on platform:

   **Windows (PowerShell):**
   ```powershell
   pwsh -File .spec-flow/scripts/powershell/init-project.ps1 $ARGUMENTS
   ```

   **macOS/Linux (Bash):**
   ```bash
   .spec-flow/scripts/bash/init-project.sh $ARGUMENTS
   ```

   The scripts perform:
   - Parse arguments and flags
   - Detect brownfield project (scan for package.json, requirements.txt, etc.)
   - Load config file if --config flag provided
   - Run questionnaire (interactive) or read environment variables (--ci mode)
   - Auto-detect tech stack for brownfield projects (20-30% fewer clarifications)
   - **Save answers to** `.spec-flow/temp/init-answers.yaml` **(v11.0 hybrid)**

3. **Spawn Document Generation Agent (v11.0 Hybrid Pattern)**:

   After questionnaire completes, spawn isolated agent for document generation:

   ```javascript
   // Save answers to temp config (done by script or main context)
   const answersFile = ".spec-flow/temp/init-answers.yaml";

   // Spawn isolated agent for document generation
   const agentResult = await Task({
     subagent_type: "init-project-agent",
     prompt: `
       Generate 8 project documentation files from questionnaire answers:

       Answers file: ${answersFile}
       Project name: ${projectName}
       Flags:
         with_design: ${withDesign}
         update: ${updateMode}
         force: ${forceMode}

       Read answers from temp config, generate all project docs, run quality gates.
       Return structured phase_result with artifacts created.
     `
   });

   const result = agentResult.phase_result;
   ```

4. **Handle Agent Result**:

   ```javascript
   // Agent completed successfully
   if (result.status === "completed") {
     console.log(`✅ Project documentation generated`);

     // Display artifacts created
     if (result.artifacts_created) {
       console.log(`\n📄 Files created:`);
       result.artifacts_created.forEach(a => console.log(`   - ${a.path}`));
     }

     // Show next steps
     console.log(`\n🚀 Next steps:`);
     result.next_steps?.forEach(s => console.log(`   - ${s}`));
   }

   // Agent had warnings
   if (result.warnings) {
     console.log(`\n⚠️ Warnings:`);
     result.warnings.forEach(w => console.log(`   - ${w.message}`));
   }
   ```

5. **Legacy: Direct Script Execution** (fallback for CI/config mode):

   For `--ci`, `--no-input`, or `--config FILE` modes, the scripts still handle everything directly:
   - Generate 8 core project docs
   - Generate 4 design docs + tokens (if --with-design)
   - Create ADR-0001 baseline
   - Run quality gates (markdown lint, link check, C4 validation)
   - Commit all generated files
   - Create foundation GitHub issue (greenfield only, if gh available)
   - Display summary with next steps

3. **Monitor script output** for quality gate failures or errors

4. **Present summary** to user:
   - List of generated files
   - Brownfield vs greenfield detection
   - Tech stack detected or selected
   - Foundation issue created (greenfield) or skipped
   - Next steps based on project type
</process>

<verification>
Before completing, verify:
- All 8 core project docs exist in docs/project/
- ADR-0001 exists in docs/adr/
- If --with-design: 4 design docs + tokens.css + tokens.json exist
- No `[NEEDS CLARIFICATION]` tokens (or warning shown if any found)
- Git commit successful
- Foundation issue created (greenfield + gh available) or skipped appropriately
- Next-step suggestions presented
</verification>

<success_criteria>
**Core documentation:**
- 8 project docs generated in docs/project/
- Each doc follows template structure
- ADR-0001 created with baseline architecture decisions
- All docs committed to git

**Design system (--with-design only):**
- 4 design docs in docs/design/
- tokens.css with WCAG AA compliant colors (4.5:1 contrast)
- tokens.json for programmatic access
- OKLCH color space used for perceptual uniformity

**Quality gates:**
- `[NEEDS CLARIFICATION]` count: 0 (CI mode) or warnings shown (interactive)
- Markdown lint: Passed or warnings shown
- Link check: Passed or warnings shown
- C4 model validation: Context/Container/Component sections present

**Foundation issue (greenfield only):**
- Created via `gh issue create` if GitHub CLI available
- Title: "Project Foundation Setup"
- Priority: HIGH (blocks all other features)
- Checklist: Frontend, backend, database, deployment, auth, linting, CI/CD

**Next steps communicated:**
- Greenfield: Build foundation first (`/feature "project-foundation"`)
- Brownfield: Review docs, fill clarifications, start features
</success_criteria>

<mental_model>
**Workflow state machine:**
```
Setup
  ↓
[MODE DETECTION] (default | update | force | ci | config)
  ↓
[BROWNFIELD SCAN] (auto-detect tech stack from codebase)
  ↓
{IF interactive mode}
  → Questionnaire (15 or 48 questions)
{ELSE IF ci mode}
  → Read environment variables
{ELSE IF config mode}
  → Load from JSON/YAML file
{ENDIF}
  ↓
Generate Docs (8 core + optional 4 design + tokens)
  ↓
Quality Gates (markdown, links, C4 validation)
  ↓
Git Commit
  ↓
{IF greenfield + gh available}
  → Create Foundation Issue
{ENDIF}
  ↓
Display Summary
```

**Idempotent execution:**
- Default: Asks before overwriting existing files
- --update: Only fills `[NEEDS CLARIFICATION]` sections
- --force: Overwrites all files (destructive)
- --write-missing-only: Only creates missing files
</mental_model>

<operation_modes>
**6 operation modes** (see `.claude/skills/project-initialization-phase/reference.md` for full details):

1. **Default** - Interactive questionnaire, asks before overwriting
2. **Update** (--update) - Only fill `[NEEDS CLARIFICATION]` sections
3. **Force** (--force) - Overwrite all docs (destructive)
4. **Write Missing** (--write-missing-only) - Only create missing files
5. **CI/CD** (--ci) - Non-interactive, environment variables, fail on missing answers
6. **Config File** (--config FILE) - Load from JSON/YAML, optional --non-interactive

**Design system mode** (--with-design):
- Extends any mode above with 33 additional design questions
- Generates 4 design docs + design tokens
- WCAG AA compliant color system
- OKLCH color space for perceptual uniformity

See `.claude/skills/project-initialization-phase/reference.md` for detailed mode behaviors and examples.
</operation_modes>

<questionnaire>
**Core questions (15 - Required):**

Interactive mode (~10 minutes):
1. Project name
2. Vision (one sentence)
3. Primary users
4. Expected scale (Micro/Small/Medium/Large)
5. Team size (Solo/Small/Medium/Large)
6. Architecture (Monolith/Microservices/Serverless)
7. Database (PostgreSQL/MySQL/MongoDB/SQLite)
8. Deployment platform (Vercel/Railway/AWS/Render)
9. API style (REST/GraphQL/tRPC/gRPC)
10. Authentication (Clerk/Auth0/Supabase/Custom/None)
11. Monthly budget (USD for MVP)
12. Privacy (Public/PII/GDPR/HIPAA)
13. Git workflow (GitHub Flow/Git Flow/Trunk-Based)
14. Deployment model (staging-prod/direct-prod/local-only)
15. Frontend framework (Next.js/Vite+React/Vue/Svelte)

**Brownfield auto-detection:** Questions 6-8, 15 auto-detected from codebase (20-30% fewer manual answers)

**Design system questions (33 - Only with --with-design):**
- Brand personality (8 questions)
- Visual language (12 questions)
- Accessibility (6 questions)
- Layout & interaction (7 questions)

**Total with --with-design:** 48 questions (~20-30 minutes)

See `.claude/skills/project-initialization-phase/reference.md` for complete question list and auto-detection logic.
</questionnaire>

<brownfield_scanning>
**Auto-detection** when existing codebase found:

**Detected indicators:**
- `package.json` → Node.js project
- `requirements.txt` / `pyproject.toml` → Python project
- `Cargo.toml` → Rust project
- `go.mod` → Go project
- `docker-compose.yml` → Microservices architecture hint

**Auto-inferred values:**
- Database: Scanned from dependencies (`pg`, `mysql2`, `mongoose`, `psycopg2`)
- Frontend: Detected from package.json (`next`, `vite`, `vue`)
- Deployment: Detected from config files (`vercel.json`, `railway.json`)
- Architecture: Inferred from `docker-compose.yml` service count and directory structure

**Component library detection (UI-first workflow):**

| Dependency | Library Type | Detection Pattern |
|------------|--------------|-------------------|
| `@radix-ui/*` | Radix Primitives | Headless components |
| `@shadcn/ui` or `components/ui/` | shadcn/ui | Copy-paste components |
| `@chakra-ui/react` | Chakra UI | Styled system |
| `@mui/material` | Material UI | Design system |
| `@heroui/*` or `@nextui-org/*` | HeroUI/NextUI | Tailwind-based |
| `tailwind-variants` | TV | Variant API available |
| None detected | Custom | Generate new components |

**Design token source detection:**

| File/Pattern | Token Format | Integration |
|--------------|--------------|-------------|
| `tailwind.config.js` theme | Tailwind | Direct mapping |
| `tokens.json` / `tokens.css` | Style Dictionary | Variable extraction |
| `src/styles/variables.css` | CSS Custom Props | Parse and map |
| `theme.ts` / `theme.js` | JS Object | Convert to CSS vars |

**Output to tech-stack.md:**
```yaml
ui_components:
  library: "shadcn/ui"          # Detected or "custom"
  variant_api: "tailwind-variants"  # If installed
  primitives: "radix"           # Underlying primitives

design_tokens:
  source: "tailwind.config.js"
  format: "tailwind"
  custom_properties: true       # CSS var support
```

**Result:** 20-30% fewer `[NEEDS CLARIFICATION]` tokens in generated docs

See `.claude/skills/project-initialization-phase/reference.md` for full auto-detection rules.
</brownfield_scanning>

<quality_gates>
**Automated checks before commit:**

1. **[NEEDS CLARIFICATION] detection** - Scans all generated docs
   - CI mode: Fails (exit code 2) if any found
   - Interactive mode: Warning only

2. **Markdown linting** (if `markdownlint` installed)
   - Checks heading structure, list formatting, code blocks
   - Non-blocking (warnings only)

3. **Link checking** (if `lychee` installed)
   - Validates internal/external links, anchors
   - Non-blocking (warnings only)

4. **C4 model validation**
   - Ensures Context/Container/Component sections in system-architecture.md
   - CI mode: Fails if missing
   - Interactive mode: Warning only

**Exit codes:**
- 0: Success
- 1: Missing required input (CI mode)
- 2: Quality gate failure (CI mode)

See `.claude/skills/project-initialization-phase/reference.md` for detailed quality gate behaviors.
</quality_gates>

<generated_outputs>
**Project documentation (8 files in docs/project/):**
1. overview.md - Vision, users, scope, metrics
2. system-architecture.md - C4 diagrams, data flows
3. tech-stack.md - Technology choices with rationale
4. data-architecture.md - ERD, entity schemas
5. api-strategy.md - REST/GraphQL patterns, versioning
6. capacity-planning.md - Scaling model, cost projections
7. deployment-strategy.md - CI/CD, environments, rollback
8. development-workflow.md - Git flow, PR process, DoD

**ADR:**
- docs/adr/0001-project-architecture-baseline.md

**Design system (--with-design only):**
- docs/design/brand-guidelines.md
- docs/design/visual-language.md
- docs/design/accessibility-standards.md
- docs/design/component-governance.md
- design/systems/tokens.css (WCAG AA compliant)
- design/systems/tokens.json

**Project CLAUDE.md:**
- Auto-updated with tech stack summary (~2,000 tokens vs 12,000 for all docs)

**Foundation issue (greenfield only):**
- Created via `gh issue create` if GitHub CLI available
- Title: "Project Foundation Setup"
- Priority: HIGH (blocks all features)

See `.claude/skills/project-initialization-phase/reference.md` for complete output catalog.
</generated_outputs>

<standards>
**Industry Standards:**
- **C4 Model**: [C4 Model for Architecture](https://c4model.com/)
- **ADR**: [Architecture Decision Records](https://adr.github.io/)
- **WCAG 2.2 AA**: [Web Content Accessibility Guidelines](https://www.w3.org/TR/WCAG22/)
- **OKLCH Color Space**: [Perceptually uniform color](https://oklch.com/)
- **RFC 7807**: [Problem Details for HTTP APIs](https://datatracker.ietf.org/doc/html/rfc7807)

**Workflow Standards:**
- Idempotent execution (safe to run multiple times)
- Brownfield scanning reduces manual input by 20-30%
- Quality gates enforce documentation quality
- Git commit includes comprehensive change summary
- Foundation issue blocks all features (greenfield only)
</standards>

<notes>
**Script locations:**
- PowerShell: `.spec-flow/scripts/powershell/init-project.ps1`
- Bash: `.spec-flow/scripts/bash/init-project.sh`

**Reference documentation:** Operation modes, questionnaire details, brownfield scanning logic, quality gates, and complete output catalog are in `.claude/skills/project-initialization-phase/reference.md`.

**Version:** v2.0 (2025-11-17) - Added design system mode (--with-design), 33 design questions, auto-generated WCAG AA compliant tokens, OKLCH color space support.

**Next steps after initialization:**
- **Greenfield:** Build foundation first via `/feature "project-foundation"`
- **Brownfield:** Review docs, fill `[NEEDS CLARIFICATION]` sections, start features via `/roadmap`

**Workflow integration:**
```
/init-project → /roadmap (manage feature backlog) → /feature (implement features)
```
</notes>
