#!/usr/bin/env bash
# Cross-platform epic creation script with worktree support
# Mirrors create-new-feature.sh but for epic workflows

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

show_help() {
    cat <<'EOF'
Usage: create-new-epic.sh [--json] <epic description>

Scaffold a new Spec-Flow epic directory and optionally create a git branch/worktree.

Options:
  --json    Output results as JSON
  -h, --help Show this help message

Examples:
  create-new-epic.sh "user authentication system"
  create-new-epic.sh --json "multi-tenant dashboard"

Output:
  Creates epics/NNN-slug/ directory with:
  - epic-spec.md (specification template)
  - visuals/ directory
  - artifacts/ directory
  - state.yaml (workflow state)

  If git is available:
  - Creates epic/NNN-slug branch
  - Or creates worktree if worktrees.auto_create is enabled
EOF
}

JSON_OUT=false

while (( $# )); do
    case "$1" in
        --json) JSON_OUT=true ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --*)
            log_error "Unknown option: $1"
            exit 1
            ;;
        *)
            break
            ;;
    esac
    shift
done

if [ $# -eq 0 ]; then
    log_error "Provide an epic description."
    show_help
    exit 1
fi

desc="$*"

REPO_ROOT="$(resolve_repo_root)"
EPICS_DIR="$REPO_ROOT/epics"
ensure_directory "$EPICS_DIR"

# Determine next epic number
max_num=0
if [ -d "$EPICS_DIR" ]; then
    while IFS= read -r entry; do
        if [[ $entry =~ /([0-9]{3})- ]]; then
            num=$((10#${BASH_REMATCH[1]}))
            if (( num > max_num )); then
                max_num=$num
            fi
        fi
    done < <(find "$EPICS_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
fi
epic_num=$(printf '%03d' $((max_num + 1)))

# Generate slug from description
slug_full=$(sanitize_slug "$desc")
IFS='-' read -r -a words <<< "$slug_full"
short_slug=""
for word in "${words[@]:0:6}"; do
    [ -z "$word" ] && continue
    if [ -z "$short_slug" ]; then
        short_slug="$word"
    else
        short_slug="$short_slug-$word"
    fi
    if [ ${#short_slug} -ge 40 ]; then
        short_slug="${short_slug:0:40}"
        short_slug="${short_slug%-}"
        break
    fi
done
[ -z "$short_slug" ] && short_slug="epic"

base_name="$epic_num-$short_slug"
dir_name="$base_name"
branch_name="epic/$dir_name"
counter=2

branch_exists() {
    git rev-parse --verify --quiet "$1" >/dev/null 2>&1
}

# Handle naming collisions
while [ -d "$EPICS_DIR/$dir_name" ] || (git rev-parse --is-inside-work-tree >/dev/null 2>&1 && branch_exists "$branch_name"); do
    dir_name="$base_name-$counter"
    branch_name="epic/$dir_name"
    counter=$((counter + 1))
done

has_git=false
worktree_enabled=false
worktree_path=""

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    has_git=true

    # Check if worktrees are enabled in user preferences
    if [ -f "$REPO_ROOT/.spec-flow/config/user-preferences.yaml" ]; then
        # Look for worktrees.auto_create setting
        worktree_section=$(grep -A 5 "^worktrees:" "$REPO_ROOT/.spec-flow/config/user-preferences.yaml" 2>/dev/null || true)
        if [ -n "$worktree_section" ]; then
            worktree_pref=$(echo "$worktree_section" | grep "auto_create:" | head -1 | awk '{print $2}')
            if [ "$worktree_pref" = "true" ]; then
                worktree_enabled=true
            fi
        fi
    fi

    if [ "$worktree_enabled" = "true" ]; then
        # Create worktree instead of regular branch
        log_info "Creating worktree for epic: $dir_name"

        # Use worktree manager
        if worktree_result=$("$SCRIPT_DIR/worktree-manager.sh" --json create "epic" "$dir_name" "$branch_name" 2>&1); then
            # Extract JSON line (last line containing status)
            json_line=$(echo "$worktree_result" | grep '"status"')
            worktree_path=$(echo "$json_line" | grep -o '"worktree_path": *"[^"]*"' | sed 's/"worktree_path": *"//' | sed 's/"$//')
            status=$(echo "$json_line" | grep -o '"status": *"[^"]*"' | sed 's/"status": *"//' | sed 's/"$//')

            if [ "$status" = "created" ]; then
                log_success "Worktree created: $worktree_path"
                epic_dir="$worktree_path/epics/$dir_name"
            elif [ "$status" = "exists" ]; then
                log_info "Using existing worktree: $worktree_path"
                epic_dir="$worktree_path/epics/$dir_name"
            else
                log_warn "Unexpected worktree status: $status, falling back to regular branch"
                worktree_enabled=false
            fi
        else
            log_warn "Failed to create worktree, falling back to regular branch"
            worktree_enabled=false
        fi
    fi

    # Fallback to regular branch if worktrees disabled or failed
    if [ "$worktree_enabled" != "true" ]; then
        if branch_exists "$branch_name"; then
            git checkout "$branch_name" >/dev/null 2>&1 || log_warn "Failed to checkout $branch_name"
        else
            git checkout -b "$branch_name" >/dev/null 2>&1 || log_warn "Failed to create branch $branch_name"
        fi
        epic_dir="$EPICS_DIR/$dir_name"
    fi
else
    log_warn "Git not detected; skipping branch creation (planned: $branch_name)"
    epic_dir="$EPICS_DIR/$dir_name"
fi

# Create epic directory structure
ensure_directory "$epic_dir"
ensure_directory "$epic_dir/visuals"
ensure_directory "$epic_dir/artifacts"
ensure_directory "$epic_dir/mockups"

# Create epic-spec.md
spec_file="$epic_dir/epic-spec.md"
template_candidates=( "$REPO_ROOT/.spec-flow/templates/epic-spec-template.md" "$REPO_ROOT/templates/epic-spec-template.md" )
template_used=""
for tpl in "${template_candidates[@]}"; do
    if [ -f "$tpl" ]; then
        cp "$tpl" "$spec_file"
        template_used="$tpl"
        break
    fi
done

if [ -z "$template_used" ]; then
    cat <<EOF >"$spec_file"
# Epic Specification: $desc

**Epic Branch**: $branch_name
**Created**: $(date +%Y-%m-%d)
**Status**: Draft

## Objective

[One-paragraph summary of the business goal and desired outcome.]

## Background

[Context and motivation for this epic. What problem are we solving?]

## Involved Subsystems

- [ ] Backend
- [ ] Frontend
- [ ] Database
- [ ] Infrastructure
- [ ] Other: ___

## Requirements

### Functional Requirements

- **FR-001**: [Requirement description]

### Non-Functional Requirements

- **NFR-001**: [Performance/security/scalability requirement]

## Success Metrics

- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]

## Constraints

- [Technical constraints]
- [Business constraints]
- [Timeline constraints]

## Out of Scope

- [Explicitly excluded items]

## Dependencies

- [External dependencies]
- [Internal dependencies]

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| [Risk 1] | High/Medium/Low | [Mitigation strategy] |

## Notes

- Created by create-new-epic.sh
EOF
fi

# Create state.yaml
state_file="$epic_dir/state.yaml"
cat <<EOF >"$state_file"
# Epic Workflow State
# Auto-generated by create-new-epic.sh

slug: "$dir_name"
description: "$desc"
workflow_type: epic
created_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

current_phase: specification
status: in_progress

phases:
  specification:
    status: in_progress
    started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  clarification:
    status: pending
  planning:
    status: pending
  tasks:
    status: pending
  validation:
    status: pending
  implementation:
    status: pending
  optimization:
    status: pending
  deployment:
    status: pending
  finalization:
    status: pending

git:
  branch: "$branch_name"
  has_git: $has_git
  worktree_enabled: $worktree_enabled
  worktree_path: "$worktree_path"

artifacts:
  epic_spec: "$spec_file"
  research: null
  plan: null
  sprint_plan: null
  tasks: null

iteration: 1
EOF

# Create NOTES.md for tracking
notes_file="$epic_dir/NOTES.md"
cat <<EOF >"$notes_file"
# Epic Notes: $desc

## Progress Tracking

**Current Phase**: Specification
**Started**: $(date +%Y-%m-%d)

## Session Notes

### $(date +%Y-%m-%d)

- Epic initialized
- Branch: $branch_name
EOF

if $JSON_OUT; then
    # Use here-doc with proper escaping for JSON
    cat <<JSONEOF
{
    "BRANCH_NAME": "$branch_name",
    "EPIC_DIR": "$epic_dir",
    "SPEC_FILE": "$spec_file",
    "STATE_FILE": "$state_file",
    "EPIC_NUM": "$epic_num",
    "SLUG": "$dir_name",
    "HAS_GIT": $has_git,
    "WORKTREE_ENABLED": $worktree_enabled,
    "WORKTREE_PATH": "$worktree_path"
}
JSONEOF
else
    echo "BRANCH_NAME: $branch_name"
    echo "EPIC_DIR: $epic_dir"
    echo "SPEC_FILE: $spec_file"
    echo "STATE_FILE: $state_file"
    echo "EPIC_NUM: $epic_num"
    echo "SLUG: $dir_name"
    echo "HAS_GIT: $has_git"
    echo "WORKTREE_ENABLED: $worktree_enabled"
    if [ "$worktree_enabled" = "true" ]; then
        echo "WORKTREE_PATH: $worktree_path"
    fi
    echo "export SPEC_FLOW_EPIC=$branch_name"
fi
