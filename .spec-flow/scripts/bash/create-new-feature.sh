#!/usr/bin/env bash
# Cross-platform equivalent of create-new-feature.ps1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
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
        short_slug="$(echo "$short_slug" | sed -e 's/-$//' )"
        break
    fi
done
[ -z "$short_slug" ] && short_slug="feature"

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
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    has_git=true
    if branch_exists "$branch_name"; then
        git checkout "$branch_name" >/dev/null 2>&1 || log_warn "Failed to checkout $branch_name"
    else
        git checkout -b "$branch_name" >/dev/null 2>&1 || log_warn "Failed to create branch $branch_name"
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

**Feature Branch**: \\`$branch_name\\`
**Created**: $(date +%Y-%m-%d)
**Status**: Draft

## Summary
[One-paragraph summary of the user problem and desired outcome.]

## User Scenarios & Testing *(mandatory)*
- [ ] Primary flow
- [ ] Edge cases

## Visual References (optional)
- [ ] ./visuals/<filename>.png - description
- [ ] External reference (optional): https://...

## Requirements *(mandatory)*
- **FR-001** ...
- **NFR-001** ...

## Notes
- Created by create-new-feature.sh
EOF
fi

if $JSON_OUT; then
    python - <<PY
import json
print(json.dumps({
    "BRANCH_NAME": "$branch_name",
    "FEATURE_DIR": "$feature_dir",
    "SPEC_FILE": "$spec_file",
    "FEATURE_NUM": "$feature_num",
    "HAS_GIT": $has_git
}))
PY
else
    echo "BRANCH_NAME: $branch_name"
    echo "FEATURE_DIR: $feature_dir"
    echo "SPEC_FILE: $spec_file"
    echo "FEATURE_NUM: $feature_num"
    echo "HAS_GIT: $has_git"
    echo "export SPEC_FLOW_FEATURE=$branch_name"
fi

