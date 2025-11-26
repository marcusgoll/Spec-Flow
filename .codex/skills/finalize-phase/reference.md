<finalization_reference>

<overview>
Comprehensive reference guide for finalization phase procedures, checklists, and best practices. Includes epic walkthrough generation (v5.0+) for self-improving workflow system. Use when executing workflow closure after production deployment.
</overview>

<epic_walkthrough_generation>
<overview_epic>
**NEW in v5.0**: Epic workflows generate comprehensive walkthrough.md before standard finalization. Walkthrough captures velocity metrics, sprint results, lessons learned, and enables self-improving workflow system.

**Purpose**: Preserve knowledge, measure effectiveness, detect patterns for automation
</overview_epic>

<detection>
**Detect epic vs feature workflow**:

```bash
# Check for epic-spec.xml
if [ -f "epics/*/epic-spec.xml" ]; then
  WORKSPACE_TYPE="epic"
  EPIC_DIR=$(find epics/ -name "epic-spec.xml" -type f | head -1 | xargs dirname)
  echo "Epic workflow detected: ${EPIC_DIR}"
else
  WORKSPACE_TYPE="feature"
  echo "Feature workflow detected - skip walkthrough generation"
fi
```

**Epic indicators**:

- epics/NNN-slug/ directory exists
- epic-spec.xml present
- sprint-plan.xml with multiple sprints
- Parallel sprint execution in state.yaml

**Feature indicators**:

- specs/NNN-slug/ directory exists
- spec.md present (not epic-spec.xml)
- tasks.md with sequential task list
- No sprint subdirectories
  </detection>

<artifacts_collection>
**Required epic artifacts**:

```bash
# Navigate to epic directory
cd ${EPIC_DIR}

# Load all artifacts
EPIC_SPEC="epic-spec.xml"
RESEARCH="research.xml"
PLAN="plan.xml"
SPRINT_PLAN="sprint-plan.xml"
WORKFLOW_STATE="state.yaml"
AUDIT_REPORT="audit-report.xml"
PREVIEW_REPORT="preview-report.xml"

# Verify artifacts exist
for artifact in "$EPIC_SPEC" "$RESEARCH" "$PLAN" "$SPRINT_PLAN" "$WORKFLOW_STATE" "$AUDIT_REPORT"; do
  test -f "$artifact" && echo "✅ $artifact" || echo "❌ $artifact MISSING"
done

# Load sprint results
for sprint_dir in sprints/*/; do
  sprint_id=$(basename "$sprint_dir")
  test -f "${sprint_dir}state.yaml" && echo "✅ Sprint ${sprint_id} state" || echo "❌ Sprint ${sprint_id} MISSING"
  test -f "${sprint_dir}tasks.md" && echo "✅ Sprint ${sprint_id} tasks" || echo "❌ Sprint ${sprint_id} tasks MISSING"
done
```

**Artifact purposes**:

- epic-spec.xml: Epic goal, success metrics, business value
- research.xml: Research phase findings (if meta-prompting used)
- plan.xml: Implementation plan with architecture decisions
- sprint-plan.xml: Sprint breakdown with dependency graph, execution strategy
- state.yaml: State tracking across all phases
- audit-report.xml: Workflow effectiveness analysis with recommendations
- preview-report.xml: Manual testing decision (auto-skip vs required)
- Sprint states: Individual sprint completion, duration, tests passed
  </artifacts_collection>

<metrics_calculation>
**Velocity metrics**:

```javascript
// Extract from sprint-plan.xml
const expectedMultiplier =
  sprint_plan.critical_path.parallelization_opportunity; // e.g., "3.5x"

// Extract from audit-report.xml
const actualMultiplier = audit_report.velocity_analysis.actual_multiplier; // e.g., "3.2x"

// Calculate time saved
const sequentialDuration =
  audit_report.velocity_analysis.sequential_duration_hours; // e.g., 120
const parallelDuration = audit_report.velocity_analysis.parallel_duration_hours; // e.g., 38
const timeSaved = sequentialDuration - parallelDuration; // 82 hours
```

**Quality metrics**:

```javascript
// Extract from audit-report.xml
const overallScore = audit_report.summary.overall_score; // e.g., 88/100
const phaseEfficiency = audit_report.phase_analysis.efficiency_score; // e.g., 92/100
const parallelizationScore = audit_report.sprint_analysis.parallelization_score; // e.g., 85/100
```

**Sprint metrics**:

```javascript
// Load all sprint results
const sprints = sprint_plan.sprints.sprint.map((sprint) => {
  const state = readYAML(`sprints/${sprint.id}/state.yaml`);
  const tasks = readMarkdown(`sprints/${sprint.id}/tasks.md`);

  return {
    id: sprint.id,
    name: sprint.name,
    status: state.status, // 'completed', 'blocked', 'skipped'
    tasks_completed: state.tasks_completed,
    total_tasks: tasks.length,
    duration_hours: state.duration_hours,
    contracts_locked: state.contracts_locked || [],
    tests_passed: state.tests_passed,
  };
});

// Calculate totals
const totalSprints = sprints.length;
const completedSprints = sprints.filter((s) => s.status === "completed").length;
const totalTasks = sprints.reduce((sum, s) => sum + s.total_tasks, 0);
const completedTasks = sprints.reduce((sum, s) => sum + s.tasks_completed, 0);
```

</metrics_calculation>

<walkthrough_template>
**Template location**: `.spec-flow/templates/walkthrough.xml`

**Structure**:

```xml
<epic_walkthrough>
  <metadata>
    <epic_number>{{EPIC_NUMBER}}</epic_number>
    <epic_slug>{{EPIC_SLUG}}</epic_slug>
    <generated_date>{{DATE}}</generated_date>
  </metadata>

  <overview>
    <goal>{{EPIC_GOAL}}</goal>
    <success_metrics>{{SUCCESS_METRICS}}</success_metrics>
    <velocity_metrics>
      <expected>{{EXPECTED_VELOCITY}}</expected>
      <actual>{{ACTUAL_VELOCITY}}</actual>
      <time_saved>{{TIME_SAVED}}</time_saved>
    </velocity_metrics>
  </overview>

  <phases_completed>{{PHASES_COMPLETED_XML}}</phases_completed>

  <sprint_execution>{{SPRINT_EXECUTION_XML}}</sprint_execution>

  <validation_results>{{VALIDATION_RESULTS_XML}}</validation_results>

  <key_files>{{KEY_FILES_XML}}</key_files>

  <next_steps>{{NEXT_STEPS_XML}}</next_steps>

  <summary>
    <what_worked>{{WHAT_WORKED}}</what_worked>
    <what_struggled>{{WHAT_STRUGGLED}}</what_struggled>
    <lessons_learned>{{LESSONS_LEARNED}}</lessons_learned>
  </summary>
</epic_walkthrough>
```

**Markdown conversion**:

- Convert XML to human-readable Markdown format
- Write to walkthrough.md alongside walkthrough.xml
- Include tables for sprint results and metrics
  </walkthrough_template>

<pattern_detection>
**When to run**: After 2+ epics completed

**Detection logic**:

```bash
# Count completed epics
COMPLETED_EPICS=$(find epics/ -name "state.yaml" -type f -exec grep -l "status: completed" {} \; | wc -l)

if [ "$COMPLETED_EPICS" -ge 2 ]; then
  echo "Pattern detection available (${COMPLETED_EPICS} epics completed)"
  # Run pattern detection
fi
```

**Pattern types detected**:

1. **Code generation patterns**:

   - Service boilerplate repeated 3+ times → Suggest custom skill
   - Component structure consistent → Suggest generator
   - Example: "All services use DI + Repository pattern → Create /create-service skill"

2. **Architectural patterns**:

   - Always use same authentication approach → Pre-configure
   - Consistent database migration strategy → Automate
   - Example: "All features use OAuth 2.1 → Add to project defaults"

3. **Workflow patterns**:
   - Always clarify specific requirements → Add pre-prompts
   - Specific phase always takes 1.8x estimate → Adjust multiplier
   - Example: "Frontend tasks consistently 1.8x estimate → Update estimation config"

**Confidence threshold**: ≥80% to suggest automation

**Output**:

```
📊 Pattern Detection: ${patterns_count} patterns detected

Strong patterns (confidence ≥80%):
  1. Service boilerplate pattern
     Occurrences: 5/5 epics
     Confidence: 95%
     Suggested Action: Create /create-service skill

  2. OAuth clarification pattern
     Occurrences: 4/5 epics
     Confidence: 85%
     Suggested Action: Add pre-prompt to /clarify phase

💡 Run /create-custom-tooling to generate automation
```

</pattern_detection>

<workflow_healing>
**When to offer**: If audit-report.xml contains recommendations

**Recommendation categories**:

```xml
<recommendations>
  <recommendation priority="immediate">
    <title>Adjust frontend estimation multiplier</title>
    <description>Frontend tasks consistently take 1.8x estimate. Increase multiplier from 1.5x to 1.8x.</description>
    <estimated_impact>20% more accurate estimates</estimated_impact>
    <estimated_effort>2 minutes (config file update)</estimated_effort>
    <roi>10x (1 minute per sprint × 10 sprints = 10min saved vs 2min effort)</roi>
  </recommendation>

  <recommendation priority="deferred">
    <title>Create service boilerplate generator</title>
    <description>Service creation pattern detected 5 times. Generate custom skill.</description>
    <estimated_impact>30 min saved per service</estimated_impact>
    <estimated_effort>2 hours to build skill</estimated_effort>
    <roi>Breaks even after 4 services</roi>
  </recommendation>
</recommendations>
```

**Display to user**:

```
🔧 Workflow Improvements Available (3)

Immediate improvements:
  1. Adjust frontend estimation multiplier
     Impact: 20% more accurate estimates
     Effort: 2 minutes
     ROI: 10x

  2. Add pre-prompt for OAuth clarification
     Impact: Skip 1 round of questions per feature
     Effort: 5 minutes
     ROI: 6x

Apply these now? Run: /heal-workflow

Deferred improvements:
  1. Create service boilerplate generator
     Effort: 2 hours
     ROI: Breaks even after 4 services

These can be applied after 2-3 more epics for pattern-based optimization.
```

</workflow_healing>

<commit_format>
**Epic walkthrough commit**:

```bash
git commit -m "docs: generate epic walkthrough

[EPIC SUMMARY]
Epic: user-authentication-system
Duration: 38h
Velocity: 3.2x (saved 82h vs sequential execution)

[SPRINTS COMPLETED]
Total: 4 sprints
Execution: parallel (layer-based dependency graph)
Tasks: 87/92 (5 blocked by external API keys)

[QUALITY METRICS]
Audit Score: 88/100
Phase Efficiency: 92/100
Parallelization: 85/100

[LESSONS LEARNED]
- What worked: Parallel sprint execution saved 82h
- What struggled: External dependency blocked S03 for 12h
- Key insight: API contract locking prevented integration bugs

Improvement recommendations: 3 immediate
Run /heal-workflow to apply immediate improvements

Pattern detection: 2 strong patterns (confidence ≥80%)
Run /create-custom-tooling to generate automation

Next: Standard finalization (CHANGELOG, README, GitHub Release)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

</commit_format>

</epic_walkthrough_generation>

<roadmap_updates>
<required_information>
When moving feature to "Shipped" section in `.spec-flow/memory/roadmap.md`, include:

**Mandatory fields**:

- Feature name (human-readable, from spec.md)
- Version number (from CHANGELOG.md or ship-summary.md)
- Completion date (production deployment date, YYYY-MM-DD)
- Production URL (if user-facing feature with public endpoint)
- Ship report link (relative path: `specs/NNN-slug/ship-summary.md`)
- Release notes link (CHANGELOG.md anchor: `#vX.Y.Z`)

**Optional fields**:

- Business impact summary (1 sentence, metrics if available)
- Lessons learned link (if retrospective conducted)
- Related features (links to other shipped features in same epic)
  </required_information>

<roadmap_format>
**Template**:

```markdown
## Shipped

### [Feature Name] (vX.Y.Z) - Shipped YYYY-MM-DD

- **Production URL**: https://app.example.com/feature-path
- **Ship Report**: specs/NNN-feature-slug/ship-summary.md
- **Release Notes**: CHANGELOG.md#vX.Y.Z
- **Impact**: [Business impact summary with metrics]
```

**Example** (good):

```markdown
## Shipped

### Student Progress Dashboard (v1.3.0) - Shipped 2025-10-21

- **Production URL**: https://app.example.com/students/progress
- **Ship Report**: specs/042-student-progress-dashboard/ship-summary.md
- **Release Notes**: CHANGELOG.md#v1.3.0
- **Impact**: Teachers can now track student progress with completion rates and time spent. Initial adoption: 85% of teachers in first week.
```

**Example** (incomplete - missing fields):

```markdown
## Shipped

### Dashboard Feature - Done
```

**Issues**: No version, no date, no links, no impact, vague name
</roadmap_format>

<moving_feature>
**Steps to move feature from "In Progress" to "Shipped"**:

1. Open `.spec-flow/memory/roadmap.md`
2. Locate feature in "## In Progress" section
3. Copy entire feature entry (all bullet points)
4. Find "## Shipped" section
5. Paste feature at TOP of shipped list (most recent first)
6. Update status line: "In Progress" → "Shipped YYYY-MM-DD"
7. Add version number if not present
8. Add production URL if applicable
9. Verify all required links present
10. Remove feature from "In Progress" section
11. Save file
12. Commit change with finalization commit (see commit_best_practices)

**Validation**:

- Feature no longer in "In Progress"
- Feature appears in "Shipped" with all required fields
- Links are valid (files exist)
- Date is deployment date (not finalization date)
  </moving_feature>
  </roadmap_updates>

<artifact_archival>
<complete_checklist>
**Required artifacts** (all features):

Core phase artifacts:

- [ ] `spec.md` - Feature specification
- [ ] `plan.md` - Implementation plan
- [ ] `tasks.md` - Task breakdown with completion tracking
- [ ] `optimization-report.md` - Quality gates results
- [ ] `ship-summary.md` - Deployment report
- [ ] `release-notes.md` - User-facing release notes
- [ ] `state.yaml` - Workflow state tracking

**Optional artifacts** (conditional):

- [ ] `clarifications.md` - If `/clarify` phase ran
- [ ] `research.md` - If `/plan` ran with research phase
- [ ] `analysis-report.md` - If `/validate` phase ran
- [ ] `preview-checklist.md` - If `/preview` manual gate completed
- [ ] `code-review-report.md` - If code review conducted
- [ ] `staging-ship-report.md` - If staging deployment happened
- [ ] `mockups/*.html` - If UI-first workflow used

**UI-first artifacts** (if `--ui-first` flag used):

- [ ] `mockups/*.html` - HTML mockups for each screen
- [ ] `mockup-approval-checklist.md` - Mockup review checklist

**Epic artifacts** (if feature is part of epic):

- [ ] `epic-spec.xml` - Epic specification
- [ ] `sprint-plan.xml` - Sprint breakdown
- [ ] `walkthrough.md` - Epic summary
      </complete_checklist>

<validation_procedure>
**How to verify artifact archival**:

```bash
# 1. Navigate to feature directory
cd specs/NNN-slug/

# 2. List all files
ls -la

# 3. Check required artifacts
test -f spec.md && echo "✅ spec.md" || echo "❌ spec.md MISSING"
test -f plan.md && echo "✅ plan.md" || echo "❌ plan.md MISSING"
test -f tasks.md && echo "✅ tasks.md" || echo "❌ tasks.md MISSING"
test -f optimization-report.md && echo "✅ optimization-report.md" || echo "❌ optimization-report.md MISSING"
test -f ship-summary.md && echo "✅ ship-summary.md" || echo "❌ ship-summary.md MISSING"
test -f release-notes.md && echo "✅ release-notes.md" || echo "❌ release-notes.md MISSING"
test -f state.yaml && echo "✅ state.yaml" || echo "❌ state.yaml MISSING"

# 4. Check for temporary files (should not exist)
ls *.tmp *.bak *~ 2>/dev/null && echo "❌ Temporary files found" || echo "✅ No temporary files"

# 5. Verify no artifacts in wrong locations
cd ../..
find . -maxdepth 1 -name "*-report.md" -o -name "spec.md" -o -name "plan.md" | grep -v specs/ && echo "❌ Artifacts in root" || echo "✅ All artifacts in specs/"
```

**Expected output**:

```
✅ spec.md
✅ plan.md
✅ tasks.md
✅ optimization-report.md
✅ ship-summary.md
✅ release-notes.md
✅ state.yaml
✅ No temporary files
✅ All artifacts in specs/
```

</validation_procedure>

<missing_artifacts>
**What to do if artifacts missing**:

**Scenario 1**: Artifact exists but in wrong location (e.g., root directory)

```bash
# Move to correct location
mv spec.md specs/NNN-slug/spec.md
```

**Scenario 2**: Artifact never generated (phase skipped or failed)

- Check state.yaml for skipped phases
- If phase critical: Regenerate artifact (re-run phase if possible)
- If phase optional: Document missing artifact in finalization commit message
- Example: "chore: finalize feature (v1.2.0) - missing clarifications.md (phase not run)"

**Scenario 3**: Artifact deleted accidentally

- Check git history: `git log --all --full-history -- "specs/NNN-slug/missing-file.md"`
- If found: Restore from git: `git checkout <commit-hash> -- specs/NNN-slug/missing-file.md`
- If not in git: Document loss in commit message, mark as unrecoverable

**Scenario 4**: Temporary files present (.tmp, .bak, \*~)

- Remove all temporary files: `find specs/NNN-slug/ -name "*.tmp" -o -name "*.bak" -o -name "*~" -delete`
- Do not commit temporary files
  </missing_artifacts>
  </artifact_archival>

<documentation_updates>
<readme_standards>
**When to update README.md**:

- User-facing features (new screens, API endpoints, functionality)
- Developer-facing features (new tools, workflows, integrations)

**When to skip README.md**:

- Internal refactorings (no visible behavior change)
- Bug fixes (unless fixing documented behavior)

**README.md format**:

```markdown
## Features

- **[Feature Name]** - One-sentence description of user value
  - Sub-capability 1
  - Sub-capability 2
  - Sub-capability 3
```

**Example** (good):

```markdown
## Features

- **Student Progress Dashboard** - Track student completion rates and time spent
  - View individual student progress
  - Filter by class, subject, or time period
  - Export progress reports to CSV
```

**Example** (bad - too technical):

```markdown
## Features

- **Dashboard** - Implemented with React, PostgreSQL, Redis caching
```

**Issue**: Focuses on implementation, not user value
</readme_standards>

<changelog_standards>
**CHANGELOG.md format** (Keep a Changelog standard):

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added

- New functionality visible to users

### Changed

- Modifications to existing functionality

### Fixed

- Bug fixes

### Removed

- Removed functionality (breaking change)

### Deprecated

- Soon-to-be-removed features (warning)

### Security

- Security fixes (CVEs, vulnerabilities)
```

**Example** (good):

```markdown
## [1.3.0] - 2025-10-21

### Added

- Student progress dashboard with completion tracking
- CSV export for progress reports
- Filtering by class, subject, and time period

### Changed

- Improved dashboard load time from 3s to 1.2s (pagination added)

### Fixed

- Fixed timeout issue with large datasets (added pagination, limit 10 records per page)
```

**Version numbering** (Semantic Versioning):

- **Major (X.0.0)**: Breaking changes (API changes, removed features)
- **Minor (0.Y.0)**: New features (backward-compatible additions)
- **Patch (0.0.Z)**: Bug fixes only (no new features)

**Unreleased section**:

- Keep `## [Unreleased]` section at top for WIP changes
- Move to versioned section on release
  </changelog_standards>

<user_guides>
**When to create user guide**:

- Complex features (>3 screens, >5 interactions)
- Features requiring configuration (API keys, settings)
- Features with non-obvious workflows (multi-step processes)

**User guide location**: `docs/features/[feature-name].md`

**User guide template**:

```markdown
# [Feature Name]

## Overview

[1-2 sentence summary of feature purpose]

## Prerequisites

- [Required configuration]
- [Required permissions]

## Getting Started

[Step-by-step guide with screenshots]

## Common Workflows

### [Workflow 1 Name]

1. [Step 1]
2. [Step 2]

### [Workflow 2 Name]

1. [Step 1]
2. [Step 2]

## Troubleshooting

**Issue**: [Common problem]
**Solution**: [How to fix]

## FAQ

**Q**: [Question]
**A**: [Answer]
```

**Link from README.md**:

```markdown
- **[Feature Name]** - [Description] ([User Guide](docs/features/feature-name.md))
```

</user_guides>
</documentation_updates>

<branch_cleanup>
<safe_deletion_procedure>
**Steps to delete feature branch safely**:

1. **Verify branch merged to main**:

```bash
git branch --merged main | grep feature/NNN-slug
```

**Expected output**: Branch name appears (merged)

2. **Delete local branch**:

```bash
git branch -d feature/NNN-slug
```

**Expected output**: `Deleted branch feature/NNN-slug (was abc123).`

3. **Delete remote branch** (if pushed):

```bash
git push origin --delete feature/NNN-slug
```

**Expected output**: `To github.com:user/repo.git - [deleted] feature/NNN-slug`

4. **Verify deletion**:

```bash
# Local branches
git branch | grep feature/NNN-slug
# Should return nothing

# Remote branches
git branch -r | grep feature/NNN-slug
# Should return nothing
```

</safe_deletion_procedure>

<branch_not_merged>
**What to do if branch not merged**:

**Scenario 1**: Feature deployed but branch not merged (direct-prod or build-local model)

- Verify feature deployed successfully (check production URL or build artifacts)
- If deployed: Force delete branch with `-D`: `git branch -D feature/NNN-slug`
- Document in finalization commit: "Branch not merged (direct-prod deployment model)"

**Scenario 2**: Feature merged via squash commit

- Check if commits appear in main: `git log --oneline main | grep "feat: [feature-name]"`
- If found: Safe to delete, branch commits squashed into main
- Delete with `-D`: `git branch -D feature/NNN-slug`

**Scenario 3**: Feature deployed via staging-prod with tagged promotion

- Check if tag exists: `git tag -l "v*" | grep [version]`
- If tag exists: Safe to delete, deployment tagged
- Delete with `-D`: `git branch -D feature/NNN-slug`

**Never force delete if**:

- Feature NOT deployed
- No evidence of merge (squash or tag)
- Unsure of deployment status (verify first)
  </branch_not_merged>

<branch_cleanup_verification>
**Verification checklist**:

- [ ] Local branch deleted: `git branch | grep feature/NNN-slug` returns nothing
- [ ] Remote branch deleted: `git branch -r | grep feature/NNN-slug` returns nothing
- [ ] Feature merged or deployed: Evidence in git log, tags, or production
- [ ] No uncommitted work on branch: `git status` clean before deletion
      </branch_cleanup_verification>
      </branch_cleanup>

<commit_best_practices>
<finalization_commit_format>
**Type**: `chore` (finalization is housekeeping, not a feature)

**Subject format**:

```
chore: finalize [feature-slug] (vX.Y.Z)
```

**Body format**:

```
Updated roadmap, README, and CHANGELOG
Archived artifacts in specs/NNN-feature-slug/
Cleaned up feature/NNN-feature-slug branch
```

**Full example**:

```bash
git add .spec-flow/memory/roadmap.md README.md CHANGELOG.md
git commit -m "chore: finalize student-progress-dashboard (v1.3.0)

Updated roadmap (moved to Shipped section with v1.3.0)
Updated README (added Student Progress Dashboard feature)
Updated CHANGELOG (added v1.3.0 release notes)
Archived artifacts in specs/042-student-progress-dashboard/
Deleted feature/042-student-progress-dashboard branch"
```

</finalization_commit_format>

<commit_message_rules>
**Rules**:

1. **Type** must be `chore` (not feat, fix, docs)
2. **Subject** must include feature name and version
3. **Subject** must be <75 characters
4. **Body** must list what was updated (roadmap, README, CHANGELOG, artifacts, branch)
5. **Body** must be imperative mood ("Updated" not "Update" or "Updates")

**Common mistakes**:

- ❌ `feat: finalize feature` (wrong type - finalization is not a feature)
- ❌ `chore: update docs` (too vague - what docs? what feature?)
- ❌ `chore: finalize` (missing feature name and version)
- ✅ `chore: finalize auth-api (v2.1.0)` (correct)
  </commit_message_rules>

<workflow_state_update>
**Update state.yaml before commit**:

```yaml
finalization:
  status: completed
  completion_date: 2025-10-21
  version: v1.3.0
  artifacts_archived: true
  documentation_updated: true
  branches_cleaned: true
  finalization_commit: abc123 # Commit hash (add after commit)
```

**Steps**:

1. Update state.yaml with finalization details
2. Add state.yaml to commit
3. Create finalization commit
4. Get commit hash: `git rev-parse HEAD`
5. Update state.yaml with commit hash
6. Amend commit: `git commit --amend --no-edit`

**Alternative** (simpler):

1. Update state.yaml (omit commit hash)
2. Add to finalization commit
3. Manually add hash later if needed
   </workflow_state_update>
   </commit_best_practices>

<troubleshooting>
<issue name="feature_not_in_roadmap">
**Issue**: Can't find feature in "In Progress" section of roadmap

**Possible causes**:

- Feature in "Backlog" or "Planned" section instead
- Feature never added to roadmap
- Feature name differs from spec.md

**Solutions**:

1. Search entire roadmap file: `grep -i "feature-name" .spec-flow/memory/roadmap.md`
2. Check other sections (Backlog, Planned, Parking Lot)
3. If not found: Add to Shipped section directly (document in commit message)
4. If found with different name: Use roadmap name, not spec.md name
   </issue>

<issue name="unclear_version">
**Issue**: Don't know what version number to use

**Solutions**:

1. **Check CHANGELOG.md**: Look for `## [Unreleased]` section, determine version based on changes:

   - Breaking changes → Major version (v2.0.0)
   - New features → Minor version (v1.3.0)
   - Bug fixes only → Patch version (v1.2.1)

2. **Check ship-summary.md**: Version may be documented in deployment report

3. **Check git tags**: `git tag -l "v*" | tail -1` → Increment from last tag

4. **Default**: If completely unclear, use deployment date as version: `v2025.10.21`
   </issue>

<issue name="missing_changelog_content">
**Issue**: Don't know what to put in CHANGELOG for this feature

**Solutions**:

1. **Read ship-summary.md**: User-facing changes documented in deployment report
2. **Read release-notes.md**: User-facing changes prepared for release
3. **Read spec.md success criteria**: What user can now do (Added section)
4. **Read tasks.md completed tasks**: What was built (convert to user language)
5. **Focus on user value**: "Users can now X" not "Implemented Y service"

**Template**:

```markdown
### Added

- [What users can now do that they couldn't before]

### Changed

- [What existing functionality was improved]

### Fixed

- [What bugs were fixed]
```

</issue>

<issue name="branch_wont_delete">
**Issue**: `git branch -d feature/NNN-slug` fails with "not fully merged"

**Cause**: Branch has commits not in main (direct-prod or squash merge)

**Solutions**:

1. **Verify feature deployed**: Check production URL or build artifacts
2. **If deployed**: Force delete with `-D`: `git branch -D feature/NNN-slug`
3. **Document in commit**: "Branch not merged (squash commit / direct-prod deployment)"

**Anti-pattern**: Don't force delete without verifying deployment first
</issue>
</troubleshooting>

</finalization_reference>
