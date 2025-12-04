#!/usr/bin/env bash
# Cross-platform equivalent of create-new-feature.ps1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

show_help() {
    cat <<'EOF'
Usage: create-new-feature.sh [--json] [--type feat|fix|chore|docs|test|refactor|ci|build] <feature description>

Scaffold a new Spec-Flow feature directory and optionally create a git branch.
EOF
}

JSON_OUT=false
TYPE="feat"

while (( $# )); do
    case "$1" in
        --json) JSON_OUT=true ;;
        --type)
            shift
            if [ $# -eq 0 ]; then
                log_error "--type requires a value"
                exit 1
            fi
            TYPE="$1"
            ;;
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
    log_error "Provide a feature description."
    show_help
    exit 1
fi

desc="$*"

REPO_ROOT="$(resolve_repo_root)"
SPECS_DIR="$REPO_ROOT/specs"
ensure_directory "$SPECS_DIR"

# Determine next feature number
max_num=0
if [ -d "$SPECS_DIR" ]; then
    while IFS= read -r entry; do
        if [[ $entry =~ /([0-9]{3})- ]]; then
            num=$((10#${BASH_REMATCH[1]}))
            if (( num > max_num )); then
                max_num=$num
            fi
        fi
    done < <(find "$SPECS_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
fi
feature_num=$(printf '%03d' $((max_num + 1)))

# Use generate-slug.sh for normalized slug generation
SLUG_SCRIPT="$SCRIPT_DIR/generate-slug.sh"
if [ -f "$SLUG_SCRIPT" ]; then
    short_slug=$(bash "$SLUG_SCRIPT" "$desc")
else
    # Fallback to sanitize_slug from common.sh
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
fi
[ -z "$short_slug" ] && short_slug="feature"

# Use classify-feature.sh for feature classification
CLASSIFY_SCRIPT="$SCRIPT_DIR/classify-feature.sh"
HAS_UI=false
IS_IMPROVEMENT=false
HAS_METRICS=false
HAS_DEPLOYMENT_IMPACT=false
RECOMMENDED_WORKFLOW="standard"

if [ -f "$CLASSIFY_SCRIPT" ]; then
    classification_json=$(bash "$CLASSIFY_SCRIPT" "$desc" 2>/dev/null || echo '{}')
    if [ -n "$classification_json" ] && [ "$classification_json" != "{}" ]; then
        HAS_UI=$(echo "$classification_json" | grep -o '"HAS_UI": *[^,}]*' | grep -o 'true\|false' || echo "false")
        IS_IMPROVEMENT=$(echo "$classification_json" | grep -o '"IS_IMPROVEMENT": *[^,}]*' | grep -o 'true\|false' || echo "false")
        HAS_METRICS=$(echo "$classification_json" | grep -o '"HAS_METRICS": *[^,}]*' | grep -o 'true\|false' || echo "false")
        HAS_DEPLOYMENT_IMPACT=$(echo "$classification_json" | grep -o '"HAS_DEPLOYMENT_IMPACT": *[^,}]*' | grep -o 'true\|false' || echo "false")
        RECOMMENDED_WORKFLOW=$(echo "$classification_json" | grep -o '"recommended_workflow": *"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//' || echo "standard")
    fi
fi

base_name="$feature_num-$short_slug"
dir_name="$base_name"
branch_name="$TYPE/$dir_name"
counter=2

branch_exists() {
    git rev-parse --verify --quiet "$1" >/dev/null 2>&1
}

while [ -d "$SPECS_DIR/$dir_name" ] || (git rev-parse --is-inside-work-tree >/dev/null 2>&1 && branch_exists "$branch_name"); do
    dir_name="$base_name-$counter"
    branch_name="$TYPE/$dir_name"
    counter=$((counter + 1))
done

has_git=false
worktree_enabled=false
worktree_path=""

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    has_git=true

    # Check if worktrees are enabled in user preferences
    if [ -f "$REPO_ROOT/.spec-flow/config/user-preferences.yaml" ]; then
        worktree_pref=$(grep "auto_create:" "$REPO_ROOT/.spec-flow/config/user-preferences.yaml" 2>/dev/null | grep -A 1 "worktrees:" | tail -1 | awk '{print $2}')
        if [ "$worktree_pref" = "true" ]; then
            worktree_enabled=true
        fi
    fi

    if [ "$worktree_enabled" = "true" ]; then
        # Create worktree instead of regular branch
        log_info "Creating worktree for feature: $dir_name"

        # Determine feature type from branch prefix
        feature_type="feature"
        if [[ "$TYPE" == "feat" || "$TYPE" == "feature" ]]; then
            feature_type="feature"
        fi

        # Use worktree manager
        worktree_result=$("$SCRIPT_DIR/worktree-manager.sh" --json create "$feature_type" "$dir_name" "$branch_name" 2>/dev/null)

        if [ $? -eq 0 ]; then
            # Extract JSON line (last line containing status)
            json_line=$(echo "$worktree_result" | grep '"status"')
            worktree_path=$(echo "$json_line" | grep -o '"worktree_path": *"[^"]*"' | sed 's/"worktree_path": *"//' | sed 's/"$//')
            status=$(echo "$json_line" | grep -o '"status": *"[^"]*"' | sed 's/"status": *"//' | sed 's/"$//')

            if [ "$status" = "created" ]; then
                log_success "Worktree created: $worktree_path"
                feature_dir="$worktree_path/specs/$dir_name"
            elif [ "$status" = "exists" ]; then
                log_info "Using existing worktree: $worktree_path"
                feature_dir="$worktree_path/specs/$dir_name"
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
    fi
else
    log_warn "Git not detected; skipping branch creation (planned: $branch_name)"
fi

feature_dir="$SPECS_DIR/$dir_name"
ensure_directory "$feature_dir"
ensure_directory "$feature_dir/visuals"
ensure_directory "$feature_dir/artifacts"

spec_file="$feature_dir/spec.md"
template_candidates=( "$REPO_ROOT/.spec-flow/templates/spec-template.md" "$REPO_ROOT/templates/spec-template.md" )
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
# Feature Specification: $desc

**Feature Branch**: $branch_name
**Created**: $(date +%Y-%m-%d)
**Status**: Draft

## Classification
| Flag | Value |
|------|-------|
| HAS_UI | $HAS_UI |
| IS_IMPROVEMENT | $IS_IMPROVEMENT |
| HAS_METRICS | $HAS_METRICS |
| HAS_DEPLOYMENT_IMPACT | $HAS_DEPLOYMENT_IMPACT |

**Recommended Workflow**: $RECOMMENDED_WORKFLOW

## Problem Statement
[Describe the user problem this feature solves. Who is affected? What is the impact?]

## Goals
- [ ] **G1**: [SMART goal - Specific, Measurable, Achievable, Relevant, Time-bound]
- [ ] **G2**: [Additional goal if needed]

## User Scenarios
\`\`\`gherkin
Scenario: [Primary user flow]
  Given [initial context]
  When [user action]
  Then [expected outcome]
\`\`\`

\`\`\`gherkin
Scenario: [Error/edge case]
  Given [error condition]
  When [user action]
  Then [graceful handling]
\`\`\`

## Functional Requirements
- **FR-001**: [User-facing capability using SHALL/SHOULD/MAY]
- **FR-002**: [Additional requirement]

## Non-Functional Requirements
- **NFR-001**: Performance - [Latency targets, throughput]
- **NFR-002**: Security - [Auth, validation requirements]
- **NFR-003**: Accessibility - [WCAG compliance level]

## Success Criteria
- [ ] [Measurable outcome that can be verified]
- [ ] [Quantifiable metric with target]

## Out of Scope
- [Explicitly excluded items to prevent scope creep]

## Open Questions
- [ ] [NEEDS CLARIFICATION] [Ambiguous requirement needing stakeholder input]

## Notes
- Created by create-new-feature.sh
- Classification auto-detected from description
EOF
fi

# Create state.yaml with classification metadata
state_file="$feature_dir/state.yaml"
cat <<EOF >"$state_file"
# Feature State - Auto-generated
feature:
  slug: $dir_name
  branch: $branch_name
  created: $(date +%Y-%m-%dT%H:%M:%S)
  description: "$desc"

classification:
  HAS_UI: $HAS_UI
  IS_IMPROVEMENT: $IS_IMPROVEMENT
  HAS_METRICS: $HAS_METRICS
  HAS_DEPLOYMENT_IMPACT: $HAS_DEPLOYMENT_IMPACT
  recommended_workflow: $RECOMMENDED_WORKFLOW

phases:
  - name: spec
    status: in_progress
    started_at: $(date +%Y-%m-%dT%H:%M:%S)

current_phase: spec
EOF

if $JSON_OUT; then
    python - <<PY
import json
print(json.dumps({
    "BRANCH_NAME": "$branch_name",
    "FEATURE_DIR": "$feature_dir",
    "SPEC_FILE": "$spec_file",
    "STATE_FILE": "$state_file",
    "FEATURE_NUM": "$feature_num",
    "HAS_GIT": $has_git,
    "WORKTREE_ENABLED": $worktree_enabled,
    "WORKTREE_PATH": "$worktree_path",
    "classification": {
        "HAS_UI": $HAS_UI,
        "IS_IMPROVEMENT": $IS_IMPROVEMENT,
        "HAS_METRICS": $HAS_METRICS,
        "HAS_DEPLOYMENT_IMPACT": $HAS_DEPLOYMENT_IMPACT,
        "recommended_workflow": "$RECOMMENDED_WORKFLOW"
    }
}))
PY
else
    echo "BRANCH_NAME: $branch_name"
    echo "FEATURE_DIR: $feature_dir"
    echo "SPEC_FILE: $spec_file"
    echo "STATE_FILE: $state_file"
    echo "FEATURE_NUM: $feature_num"
    echo "HAS_GIT: $has_git"
    echo "WORKTREE_ENABLED: $worktree_enabled"
    if [ "$worktree_enabled" = "true" ]; then
        echo "WORKTREE_PATH: $worktree_path"
    fi
    echo "Classification:"
    echo "  HAS_UI: $HAS_UI"
    echo "  IS_IMPROVEMENT: $IS_IMPROVEMENT"
    echo "  HAS_METRICS: $HAS_METRICS"
    echo "  HAS_DEPLOYMENT_IMPACT: $HAS_DEPLOYMENT_IMPACT"
    echo "  RECOMMENDED_WORKFLOW: $RECOMMENDED_WORKFLOW"
    echo "export SPEC_FLOW_FEATURE=$branch_name"
fi
