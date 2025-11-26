---
name: repo-hygiene
description: Maintain public repository documentation, command inventory, installation guides, and file hygiene (internal use only - not in npm package)
argument-hint: [check|fix|docs|commands|install|all]
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash(git *), Bash(npm *), Bash(node *)]
---

<objective>
Maintain repository hygiene by ensuring:
1. All workflow commands are documented with usage examples
2. Installation and setup instructions are current and accurate
3. Public-facing documentation (README, CONTRIBUTING, CLAUDE.md) is synchronized
4. Deprecated files and outdated references are cleaned up
5. .npmignore properly excludes internal tooling

This is an **internal maintenance command** for repo maintainers, not shipped in the npm package.
</objective>

<context>
Current git status:
!`git status --short`

Current branch:
!`git branch --show-current`

Recent commits (last 5):
!`git log -5 --oneline`

Package version:
!`node -p "require('./package.json').version"`
</context>

<process>
## 1. Parse Operation Mode

**If $ARGUMENTS is empty or invalid:**
- Use AskUserQuestion to request operation:
  - **Question**: "What repo hygiene operation would you like to perform?"
  - **Options**:
    1. "check" - Audit documentation, find issues (read-only)
    2. "fix" - Auto-fix detected issues
    3. "docs" - Update README and CONTRIBUTING
    4. "commands" - Generate command inventory documentation
    5. "install" - Update installation instructions
    6. "all" - Run all operations (check → fix → docs → commands → install)
  - **Header**: "Repo Hygiene"
  - **Multi-select**: false

**Valid modes**: check, fix, docs, commands, install, all

**Store in OPERATION variable**

## 2. Audit Repository (All Modes)

**Run comprehensive audit:**

### A. Check Command Documentation

1. **List all slash commands:**
   - Glob: `.claude/commands/**/*.md`
   - Count total commands
   - Group by category (core, phases, deployment, meta, etc.)

2. **Verify command inventory exists:**
   - Read `docs/commands.md` (if exists)
   - Check if all discovered commands are documented
   - Flag missing command documentation

3. **Check command consistency:**
   - Verify all commands have YAML frontmatter with `description`
   - Check for XML structure tags (`<objective>`, `<process>`, `<success_criteria>`)
   - Flag commands without proper structure

### B. Check README Completeness

1. **Read README.md**
2. **Verify required sections exist:**
   - Installation instructions
   - Quick start guide
   - Command reference (or link to docs/commands.md)
   - Project structure overview
   - Contributing guidelines link
   - License information

3. **Check for outdated references:**
   - Old package versions
   - Deprecated commands
   - Dead links

### C. Check CONTRIBUTING.md

1. **Read CONTRIBUTING.md**
2. **Verify developer workflow documented:**
   - How to install dev dependencies
   - How to run tests
   - How to create slash commands
   - How to release new versions
   - Branching strategy

### D. Check .npmignore Coverage

1. **Read .npmignore**
2. **Verify internal tooling excluded:**
   - `.claude/commands/internal/` (this command and other internal tools)
   - `.claude/skills/` (development skills)
   - `temp/`, `scripts/` (if not needed in package)
   - Development-only documentation

3. **Check package size:**
   - Run: `npm pack --dry-run`
   - List files that would be included
   - Flag unexpectedly large package size

### E. Detect Stale Files

1. **Find potentially outdated files:**
   - Glob: `**/*.md.old`, `**/*.backup`, `**/*.deprecated`
   - Glob: `**/*.TODO`, `**/ARCHIVE-*`
   - Check git status for untracked files in internal directories

2. **Check for orphaned references:**
   - Grep for references to deleted files in documentation
   - Grep for TODO markers in production code paths

**Generate audit report:**
```markdown
# Repository Hygiene Audit Report

**Date:** [ISO 8601 timestamp]
**Branch:** [current branch]
**Version:** [package.json version]

## Command Documentation

- Total commands: N
- Documented: M
- Missing documentation: P (list them)
- Structural issues: Q (list them)

## README Status

- ✅ Complete sections: [list]
- ⚠️ Missing sections: [list]
- ❌ Outdated references: [list with line numbers]

## CONTRIBUTING Status

- ✅ Developer workflow documented
- ⚠️ Missing sections: [list]

## .npmignore Coverage

- ✅ Internal commands excluded
- ⚠️ Missing exclusions: [list]
- Package size: X MB (Y files)

## Stale Files Detected

- [list with recommended actions]

## Summary

- Critical issues: N (block release)
- Warnings: M (should fix)
- Info: P (nice to have)
```

## 3. Execute Operation

### Mode: check

- Display audit report
- Exit (no modifications)

### Mode: fix

**Auto-fix detected issues:**

1. **Remove stale files:**
   - Delete `.old`, `.backup`, `.deprecated` files
   - Stage deletions: `git add -u`

2. **Update .npmignore:**
   - Add missing internal exclusions
   - Add comment: `# Internal maintenance tooling (not in package)`
   - Write updated .npmignore

3. **Display summary of fixes applied**

### Mode: docs

**Update README.md and CONTRIBUTING.md:**

1. **README.md:**
   - Verify installation section matches current package.json setup
   - Add missing sections (use templates if needed)
   - Update package version references to current version
   - Fix broken links (if any detected)

2. **CONTRIBUTING.md:**
   - Ensure developer workflow section is complete
   - Add slash command creation guide if missing (link to docs/commands.md)
   - Update release process section

3. **Commit changes:**
   - Stage: `git add README.md CONTRIBUTING.md`
   - Commit message: `docs: update README and CONTRIBUTING for consistency`

### Mode: commands

**Generate/update command inventory documentation:**

1. **Glob all commands:** `.claude/commands/**/*.md`

2. **Parse each command file:**
   - Extract YAML frontmatter (name, description)
   - Categorize by directory structure

3. **Generate docs/commands.md:**
   ```markdown
   # Slash Command Reference

   Complete reference of all available workflow commands.

   ## Core Commands

   - `/feature` - (description from YAML)
   - `/quick` - (description from YAML)
   - ...

   ## Phase Commands

   - `/spec` - (description from YAML)
   - `/plan` - (description from YAML)
   - ...

   ## Deployment Commands

   - `/ship` - (description from YAML)
   - `/ship-staging` - (description from YAML)
   - ...

   ## Meta Commands (Internal)

   - `/meta:create-slash-command` - (description from YAML)
   - ...

   ## Internal Commands (Not in Package)

   These commands are for repository maintainers only:

   - `/internal:repo-hygiene` - (this command)
   - ...
   ```

4. **Update README.md command reference:**
   - Add/update "Available Commands" section with link to docs/commands.md

5. **Commit changes:**
   - Stage: `git add docs/commands.md README.md`
   - Commit: `docs: regenerate command inventory`

### Mode: install

**Update installation documentation:**

1. **Read package.json dependencies and installation hooks**

2. **Generate/update INSTALL.md (or README installation section):**
   ```markdown
   ## Installation

   ### For End Users

   ```bash
   npm install -g spec-flow
   # or
   npx spec-flow init
   ```

   ### For Contributors

   ```bash
   git clone https://github.com/your-org/spec-flow.git
   cd spec-flow
   npm install
   npm run build
   npm link
   ```

   ### Verifying Installation

   ```bash
   # Check version
   spec-flow --version

   # View available commands
   # (in a Claude Code session)
   /help
   ```

   ### Troubleshooting

   - Issue: Commands not showing up
     - Solution: Check .claude/commands/ directory exists

   - Issue: Permission errors
     - Solution: Run with appropriate permissions or use npx
   ```

3. **Verify installation instructions match package.json scripts:**
   - Check `bin` field in package.json
   - Check `postinstall` script (if any)
   - Ensure examples use correct command names

4. **Commit changes:**
   - Stage: `git add INSTALL.md README.md`
   - Commit: `docs: update installation instructions`

### Mode: all

**Execute operations in sequence:**
1. check (audit)
2. fix (auto-fix issues)
3. commands (regenerate command docs)
4. docs (update README/CONTRIBUTING)
5. install (update installation docs)

**Display comprehensive summary at end**

## 4. Verify Changes (fix/docs/commands/install/all modes)

**Run verification checks:**

1. **Git status check:**
   - Run: `git status`
   - List modified files
   - Confirm no unintended changes

2. **Package integrity check:**
   - Run: `npm pack --dry-run`
   - Verify internal commands NOT included in package
   - Confirm package size is reasonable

3. **Link validation (if applicable):**
   - Check all markdown links in modified files
   - Flag broken links

**Display verification summary:**
```
✅ Verification Complete

Modified files:
- README.md (installation section updated)
- docs/commands.md (regenerated)
- .npmignore (added internal exclusions)

Package check:
- Size: X MB (within acceptable range)
- Internal commands excluded: ✅
- Total files: N

Next steps:
- Review changes: git diff
- Commit if satisfied: git add -A && git commit -m "chore: repo hygiene maintenance"
- Push: git push origin [branch]
```

## 5. Generate Summary Report

**Display operation summary:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Repository Hygiene: [OPERATION]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Operation: [check|fix|docs|commands|install|all]
Duration: ~Nm

Actions Taken:
[IF check:]
- Audit completed (see report above)
- No modifications made

[IF fix:]
- Removed N stale files
- Updated .npmignore with M exclusions
- Fixed P documentation references

[IF docs:]
- Updated README.md (N sections)
- Updated CONTRIBUTING.md (M sections)
- Fixed P broken links

[IF commands:]
- Regenerated docs/commands.md (N commands documented)
- Updated README command reference

[IF install:]
- Updated installation instructions
- Verified package.json alignment

[IF all:]
- All operations completed successfully

Files Modified: N
Commits Created: M

Next Steps:
1. Review changes: git diff
2. Run tests (if applicable): npm test
3. Commit remaining changes (if any): git commit -am "chore: repo maintenance"
4. Push to remote: git push
```
</process>

<success_criteria>
Repository hygiene operation is complete when:

**For check mode:**
- Comprehensive audit report generated
- All issues categorized by severity (critical, warning, info)
- No modifications made to repository

**For fix mode:**
- Stale files removed
- .npmignore updated with internal exclusions
- Changes staged for commit

**For docs mode:**
- README.md and CONTRIBUTING.md synchronized
- All required sections present
- Broken links fixed
- Changes committed with clear message

**For commands mode:**
- docs/commands.md generated/updated with all commands
- Commands categorized by type
- Internal commands clearly marked
- README links to command reference

**For install mode:**
- Installation instructions current and accurate
- Instructions match package.json configuration
- Troubleshooting section includes common issues

**For all mode:**
- All operations executed successfully
- Verification checks passed
- Comprehensive summary displayed

**General criteria (all modes):**
- No unintended modifications
- Package integrity verified (internal commands excluded)
- Clear next steps provided
</success_criteria>

<verification>
After executing operations, verify:

1. **Git changes are intentional:**
   - Run: `git diff`
   - Confirm all modifications are expected

2. **Package excludes internals:**
   - Run: `npm pack --dry-run | grep -i internal`
   - Should return empty (internal files excluded)

3. **Documentation renders correctly:**
   - Check markdown syntax in modified files
   - Verify links are valid (no 404s)

4. **Command inventory complete:**
   - Count commands in docs/commands.md
   - Compare to actual command count from glob
   - Should match (no missing commands)
</verification>

<examples>
**Example 1: Audit Only**
```
/internal:repo-hygiene check
```
Output: Comprehensive audit report, no modifications

**Example 2: Auto-Fix Issues**
```
/internal:repo-hygiene fix
```
Output: Stale files removed, .npmignore updated

**Example 3: Update Documentation**
```
/internal:repo-hygiene docs
```
Output: README and CONTRIBUTING updated, committed

**Example 4: Regenerate Command Docs**
```
/internal:repo-hygiene commands
```
Output: docs/commands.md regenerated with current command list

**Example 5: Full Maintenance**
```
/internal:repo-hygiene all
```
Output: All operations executed, repository fully synchronized

**Example 6: Interactive Mode**
```
/internal:repo-hygiene
```
Output: Prompts for operation selection via AskUserQuestion
</examples>

<error_handling>
**If not in git repository:**
- Error: "This command requires a git repository. Initialize with `git init`."
- Abort execution

**If package.json not found:**
- Error: "package.json not found - is this a Node.js project?"
- Abort execution

**If on main/master branch (for fix/docs/commands/install/all):**
- Warn: "You are on the main branch. Consider creating a feature branch for changes."
- Ask user: Continue anyway or abort?

**If uncommitted changes exist (for fix/docs/commands/install/all):**
- Warn: "Uncommitted changes detected. This operation will create new changes."
- Display: `git status --short`
- Ask user: Stash, commit, or continue with mixed changes?

**If .npmignore missing:**
- Create new .npmignore with standard exclusions
- Note: "Created .npmignore with internal command exclusions"

**If docs/ directory missing:**
- Create docs/ directory
- Note: "Created docs/ directory for command inventory"

**If command parsing fails:**
- Log: "Failed to parse [file]: [error]"
- Skip that command
- Continue with remaining commands

**If npm pack fails:**
- Warn: "Could not verify package contents - ensure npm is installed"
- Skip package verification
- Continue with other operations
</error_handling>

<notes>
**Internal Use Only:**
This command is for repository maintainers and should NOT be included in the npm package distribution. Ensure `.claude/commands/internal/` is excluded in .npmignore.

**Frequency:**
Run this command:
- Before each release (use `all` mode)
- After adding new slash commands (use `commands` mode)
- When onboarding new contributors (use `docs` mode)
- Monthly for general maintenance (use `check` mode)

**Automation:**
Consider adding to GitHub Actions workflow:
- Run `check` mode on PRs (audit only, no modifications)
- Run `all` mode before releases (full synchronization)

**Related Commands:**
- `/meta:create-slash-command` - Create new commands (documents them automatically)
- `/internal:release` - Release workflow (should run repo-hygiene first)
</notes>
