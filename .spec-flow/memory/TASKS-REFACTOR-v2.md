# Tasks Command v2.0 Refactor

**Date**: 2025-11-10
**Version**: 2.0.0
**Status**: Complete

## Overview

Refactored the `/tasks` command from a hand-wavy Markdown generator into a deterministic, verifiable task generation system with machine-readable canonical output.

## Key Changes

### 1. Dual-Artifact System

**Before**: Generated only `tasks.md` (human-readable Markdown)

**After**: Generates two files:
- `tasks.json` — **Canonical source of truth** (machine-readable, structured)
- `tasks.md` — **Rendered view** (generated from tasks.json, human-readable)

**Relationship**: tasks.md is derived from tasks.json and should never be edited manually.

### 2. Hard Verification (Fail-Fast)

**Before**: Relied on textual anti-hallucination rules in prompts

**After**: Enforces verification at generation time:

```bash
# File path verification via git
exists_in_repo() {
  git ls-files --error-unmatch "$1" >/dev/null 2>&1
}

# Section verification
grep -qF "$section" "$plan.md" || fail "Missing section"

# AC verification
quote_verbatim_from_spec_md() || warn "No AC quoted"
```

**Failures**: Generation stops with precise error messages listing:
- Missing file paths
- Missing sections
- Missing acceptance criteria
- Line numbers where issues occur

### 3. Stable Task IDs

**Before**: Sequential IDs (T001, T002...) could change across reruns

**After**: Deterministic ID generation:
1. Sort tasks by: phase → priority → appearance order
2. Generate content hash: `sha1(description + files + from.section)`
3. Assign sequential IDs in deterministic order
4. Store hash in JSON for cross-run verification

**Result**: Same inputs → identical IDs across runs

### 4. Dependency Graph Validation (DAG)

**Before**: Dependencies allowed but not validated

**After**: Mandatory DAG validation using DFS:

```bash
detect_cycles(graph):
  for each node:
    if dfs(node) detects cycle:
      fail with cycle path

# Fails generation if cycles detected
```

**Failures**: Lists exact cycle paths (e.g., "T005 → T012 → T005")

### 5. Quoted Acceptance Criteria

**Before**: Paraphrased or invented AC

**After**: Verbatim quotes from spec.md:

```json
{
  "acceptance_criteria": [
    {
      "text": "Given a valid email, When user submits registration, Then account is created in database",
      "from_spec": true,
      "spec_line": 85
    }
  ]
}
```

**Format**: Gherkin Given-When-Then where present in spec.md

### 6. Traceability

Every task links to exact source:

```json
{
  "from": {
    "doc": "data-model.md",
    "section": "User Entity",
    "start_line": 42,
    "end_line": 78
  }
}
```

**Benefits**:
- Audit trail from requirement → task
- Fast navigation to source context
- Verification that task derives from real design artifacts

### 7. Schema Validation

**Schema**: `.spec-flow/templates/tasks.schema.json` (JSON Schema Draft-07)

**Validation**: Automatic after JSON generation:

```bash
# Node.js
npx ajv validate -s tasks.schema.json -d tasks.json

# Python
jsonschema.validate(tasks_data, schema)
```

**Failures**: Generation stops if schema validation fails

## Guarantees

The refactored `/tasks` command provides six guarantees:

1. **Deterministic**: Same inputs → identical outputs (IDs, order, hashes)
2. **Verifiable**: Every file path and section reference exists before emit
3. **Traceable**: Each task cites exact plan/spec sections (line ranges)
4. **Machine-readable**: JSON is source of truth; MD is derived
5. **Acyclic**: Dependency graph must be a DAG or generation fails
6. **No placeholders**: Zero "[Entity]" or "[file]" strings permitted

## Workflow Changes

### Before (v1.x)

```bash
/tasks
# Generates specs/NNN-slug/tasks.md
# Manual verification required
# Hallucination risk moderate
```

### After (v2.0)

```bash
/tasks
# Phase 0: Load feature
# Phase 1: Parse & verify inputs (fail-fast)
# Phase 2: Codebase discovery (git ls-files)
# Phase 3: Generate canonical tasks.json
# Phase 4: Build dependency graph & validate DAG
# Phase 5: Write tasks.json
# Phase 6: Validate against schema
# Phase 7: Render tasks.md from tasks.json
# Phase 8: Diff check
# Phase 9: Update NOTES.md
# Phase 10: Git commit (Conventional Commits)
# Phase 11: Return summary

# Outputs:
#   - specs/NNN-slug/tasks.json (canonical)
#   - specs/NNN-slug/tasks.md (rendered)
#   - specs/NNN-slug/NOTES.md (updated)
```

## File Structure

### tasks.json (Canonical)

```json
{
  "version": "1.0",
  "feature": {
    "slug": "user-auth",
    "name": "User Authentication",
    "feature_dir": "specs/001-user-auth"
  },
  "metadata": {
    "generated_at": "2025-11-10T14:30:00Z",
    "plan_file": "specs/001-user-auth/plan.md",
    "spec_file": "specs/001-user-auth/spec.md",
    "data_model_file": "specs/001-user-auth/data-model.md"
  },
  "tasks": [
    {
      "id": "T012",
      "hash": "a3f5c89e",
      "story": "US1",
      "priority": 1,
      "description": "Create User model in api/src/models/user.py",
      "phase": "story",
      "phase_label": "Phase 3: User Story 1 [P1]",
      "files": ["api/src/models/user.py"],
      "from": {
        "doc": "data-model.md",
        "section": "User Entity",
        "start_line": 42,
        "end_line": 78
      },
      "reuse": [
        {"name": "BaseModel", "path": "api/src/models/base.py"}
      ],
      "pattern": ["api/src/models/notification.py"],
      "depends_on": ["T005"],
      "parallelizable": true,
      "acceptance_criteria": [
        {
          "text": "Given a valid email, When user submits registration, Then account is created in database",
          "from_spec": true,
          "spec_line": 85
        }
      ],
      "test_required": true
    }
  ],
  "dependency_graph": {
    "is_acyclic": true,
    "cycles": [],
    "story_order": [
      {"story": "Foundational", "phase": 2, "depends_on": []},
      {"story": "US1", "phase": 3, "priority": 1, "depends_on": ["Foundational"]},
      {"story": "US2", "phase": 4, "priority": 2, "depends_on": ["US1"]}
    ],
    "parallel_opportunities": [
      {"phase": "story", "task_ids": ["T010", "T011", "T012"]}
    ]
  },
  "implementation_strategy": {
    "mvp_scope": "Phase 3 (US1) only",
    "incremental_delivery": ["US1 → staging", "US2 → staging", "US3 → production"],
    "testing_approach": "TDD required"
  },
  "statistics": {
    "total_tasks": 25,
    "setup_tasks": 2,
    "foundational_tasks": 5,
    "story_tasks": 15,
    "polish_tasks": 3,
    "parallel_tasks": 12,
    "test_tasks": 8,
    "reuse_count": 6
  }
}
```

### tasks.md (Rendered)

```markdown
# Tasks: User Authentication

> **Source of truth**: `tasks.json` (canonical)
> **This file**: Generated from tasks.json on 2025-11-10 14:30:00
> **Do not edit manually** — changes will be overwritten

## [CODEBASE REUSE ANALYSIS]
...

## [DEPENDENCY GRAPH]
...

## Phase 1: Setup

- [ ] T001 Create project structure per plan.md tech stack
  - Files: src/, tests/, config/
  - Pattern: existing-feature/ structure
  - From: plan.md L45-L67 [PROJECT STRUCTURE]

## Phase 3: User Story 1 [P1] - User can register account

- [ ] T012 [P] [US1] Create User model in api/src/models/user.py
  - Fields: id, email, password_hash, created_at
  - Methods: validate_email(), set_password()
  - REUSE: BaseModel (api/src/models/base.py)
  - Pattern: api/src/models/notification.py
  - From: data-model.md L42-L78 [User Entity]
  - AC:
    - "Given a valid email, When user submits registration, Then account is created in database" (spec.md L85)
```

## Usage

### Generate Tasks

```bash
# From feature branch
/tasks

# Explicit feature
/tasks user-auth
```

### Read Tasks (Human)

```bash
cat specs/001-user-auth/tasks.md
```

### Read Tasks (Machine/CI)

```bash
# Parse JSON for automation
jq '.tasks[] | select(.parallelizable == true)' specs/001-user-auth/tasks.json

# Extract task IDs for CI
jq -r '.tasks[].id' specs/001-user-auth/tasks.json

# Check if DAG is valid
jq -r '.dependency_graph.is_acyclic' specs/001-user-auth/tasks.json
```

### Validate Tasks

```bash
# Schema validation (Node.js)
npx ajv validate \
  -s .spec-flow/templates/tasks.schema.json \
  -d specs/001-user-auth/tasks.json

# Schema validation (Python)
python3 -c "
import json
import jsonschema

with open('.spec-flow/templates/tasks.schema.json') as f:
  schema = json.load(f)

with open('specs/001-user-auth/tasks.json') as f:
  data = json.load(f)

jsonschema.validate(data, schema)
print('✅ Valid')
"
```

## CI Integration (Future)

### Enforcement

```yaml
# .github/workflows/validate-tasks.yml
name: Validate Tasks

on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate tasks.json schema
        run: |
          npm install -g ajv-cli
          find specs -name "tasks.json" -exec ajv validate -s .spec-flow/templates/tasks.schema.json -d {} \;

      - name: Check tasks.md sync
        run: |
          # Regenerate tasks.md from tasks.json
          # Fail if diff exists (tasks.md manually edited)
          for dir in specs/*/; do
            jq -r '.tasks[] | "- [ ] \(.id) \(.description)"' "$dir/tasks.json" > /tmp/rendered.md
            diff "$dir/tasks.md" /tmp/rendered.md || {
              echo "❌ tasks.md out of sync with tasks.json in $dir"
              exit 1
            }
          done
```

## Migration from v1.x

### Existing Features

**For features with old tasks.md files**:

1. **Regenerate**:
   ```bash
   /tasks existing-feature-slug
   ```

2. **Manual tasks.md edits will be lost** — this is intentional

3. **Review diff**:
   ```bash
   git diff specs/NNN-slug/tasks.md
   ```

4. **Merge any custom notes** back into spec/plan if needed

### Backward Compatibility

**The refactored /tasks command is NOT backward compatible**:

- Old tasks.md files lack the JSON source
- Old files may have hallucinated paths/sections
- No traceability metadata

**Recommendation**: Regenerate all tasks.md files for active features

## Error Handling

### Missing File Path

```
❌ Task generation failed with 3 errors:
  - T012: missing file api/src/models/user.py
  - T015: REUSE path missing api/src/services/auth.py
  - T020: pattern missing apps/web/components/LoginForm.tsx

Fix paths or mark as [NEW] before generation.
```

### Missing Section

```
❌ plan.md missing required headings:
  - ## \[SCHEMA\]
  - ## \[CI/CD IMPACT\]

Run /plan first to generate complete plan.
```

### Cycle Detected

```
❌ Dependency graph contains cycles:
  - Cycle: T005 → T012 → T015 → T005
  - Cycle: T008 → T010 → T008

Fix dependency cycles in task definitions.
```

### Schema Validation Failed

```
❌ Schema validation failed:
  - tasks[0].from.start_line: must be >= 1
  - tasks[5].acceptance_criteria[0]: missing required property 'text'

Fix JSON structure to match schema.
```

## Benefits

### For Developers

- **No hallucinations**: All paths/sections verified before task creation
- **Traceable**: Click through to exact source lines in plan/spec
- **Stable IDs**: Task IDs don't change across regenerations
- **Automation-ready**: JSON enables CI validation, task routing

### For AI Agents

- **Structured input**: Parse JSON instead of fragile Markdown regex
- **Dependency-aware**: Follow DAG for parallel execution
- **Quoted AC**: No interpretation needed, use verbatim text
- **Provenance**: Know exactly where each task came from

### For QA/Audit

- **Verify coverage**: Machine-check that all requirements → tasks
- **Detect drift**: Compare tasks.json to spec.md programmatically
- **Enforce standards**: Schema validation in CI prevents regressions

## Technical Debt Resolved

1. ✅ **No more hallucinated file paths** — verified via `git ls-files`
2. ✅ **No more invented AC** — quoted verbatim from spec.md or warned
3. ✅ **No more unstable IDs** — content hash + deterministic sort
4. ✅ **No more cycles** — DAG validation with DFS cycle detection
5. ✅ **No more placeholders** — "[Entity]" syntax forbidden and detected
6. ✅ **No more Markdown-only output** — JSON canonical, MD derived

## Future Enhancements

### Planned for v2.1

- [ ] Automated task.md → task.json migration script
- [ ] CI enforcement workflow (schema + sync check)
- [ ] Task dependency visualizer (Mermaid graph from JSON)
- [ ] Task estimation based on similar tasks (ML-based)
- [ ] Auto-update tasks.json when plan/spec changes (delta sync)

### Considered for v2.2

- [ ] Multi-repo task coordination (monorepo support)
- [ ] Task templates library (common patterns)
- [ ] Task routing to specialist agents based on task.phase
- [ ] Parallel execution framework (consume tasks.json DAG)

## References

- **Schema**: `.spec-flow/templates/tasks.schema.json`
- **Command**: `.claude/commands/tasks.md`
- **Conventional Commits**: https://www.conventionalcommits.org/
- **Gherkin AC Format**: https://cucumber.io/docs/gherkin/reference/

## Rollback Plan

If the refactored `/tasks` command causes issues:

```bash
# Revert to v1.x tasks.md command
git checkout HEAD~1 .claude/commands/tasks.md

# Or manually restore from archive
cp .claude/commands/archive/tasks-v1.md .claude/commands/tasks.md
```

**Note**: This will lose v2.0 guarantees (no verification, no JSON, no DAG validation)

---

**Refactored by**: Claude Code
**Date**: 2025-11-10
**Commit**: `design:tasks: v2.0 refactor - deterministic, verifiable, machine-readable`
