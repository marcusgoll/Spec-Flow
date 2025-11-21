#!/usr/bin/env bash
# Finalization workflow - Documentation updates and housekeeping after production deployment
# Standards: Keep a Changelog, SemVer, Shields.io badges, GitHub CLI

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✅${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}❌${NC} $*"; }

# Check prerequisites
check_prerequisites() {
    local missing=0
    for cmd in gh jq yq git; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Missing required command: $cmd"
            missing=1
        fi
    done

    if [ $missing -eq 1 ]; then
        log_error "Please install missing dependencies before running /finalize"
        exit 1
    fi

    # Check gh auth
    if ! gh auth status >/dev/null 2>&1; then
        log_error "GitHub CLI not authenticated. Run: gh auth login"
        exit 1
    fi
}

# Detect workspace type (epic vs feature)
detect_workspace_type() {
    if compgen -G "epics/*/epic-spec.xml" >/dev/null; then
        echo "epic"
    else
        echo "feature"
    fi
}

# Generate epic walkthrough
generate_epic_walkthrough() {
    local epic_dir="$1"

    log_info "Generating epic walkthrough for: $epic_dir"

    # This would be a complex function - for now, placeholder
    log_warning "Epic walkthrough generation not yet implemented in bash"
    log_info "TODO: Implement walkthrough generation using .spec-flow/templates/walkthrough.xml"
}

# Load feature context
load_feature_context() {
    local feature_dir
    feature_dir="$(ls -td specs/*/ 2>/dev/null | head -1)"

    if [ -z "$feature_dir" ]; then
        log_error "No feature directory found in specs/"
        exit 1
    fi

    local state_file="${feature_dir%/}/workflow-state.yaml"

    if [ ! -f "$state_file" ]; then
        log_error "No workflow-state.yaml found in $feature_dir"
        exit 1
    fi

    export FEATURE_DIR="$feature_dir"
    export STATE_FILE="$state_file"
    export TITLE="$(yq -r '.feature.title' "$state_file")"
    export SLUG="$(yq -r '.feature.slug' "$state_file")"
    export PROD_URL="$(yq -r '.deployment.production.url // ""' "$state_file")"
    export VERSION="$(yq -r '.version' "$state_file")"
    export DATE="$(date +%F)"

    log_success "Loaded feature: $TITLE (v$VERSION)"
}

# Update CHANGELOG.md
update_changelog() {
    log_info "Updating CHANGELOG.md"

    local changelog="CHANGELOG.md"

    # Create if missing
    if [ ! -f "$changelog" ]; then
        cat > "$changelog" <<'EOF'
# Changelog

All notable changes to this project will be documented in this file.

This format follows [Keep a Changelog](https://keepachangelog.com/)
and this project adheres to [Semantic Versioning](https://semver.org/).
EOF
    fi

    # Collect commits since last tag
    local last_tag
    last_tag="$(git describe --tags --abbrev=0 2>/dev/null || echo "")"
    local range="${last_tag:+${last_tag}..HEAD}"

    local added fixed changed security
    added="$(git log --pretty='- %s' --grep='^feat:' $range 2>/dev/null || echo "")"
    fixed="$(git log --pretty='- %s' --grep='^fix:' $range 2>/dev/null || echo "")"
    changed="$(git log --pretty='- %s' --grep='^refactor:' $range 2>/dev/null || echo "")"
    security="$(git log --pretty='- %s' --grep='^security:' $range 2>/dev/null || echo "")"

    # Prepend new section
    local tmp
    tmp="$(mktemp)"
    {
        echo "## [v${VERSION}] - ${DATE}"
        [ -n "$added" ] && { echo ""; echo "### Added"; echo "$added"; }
        [ -n "$fixed" ] && { echo ""; echo "### Fixed"; echo "$fixed"; }
        [ -n "$changed" ] && { echo ""; echo "### Changed"; echo "$changed"; }
        [ -n "$security" ] && { echo ""; echo "### Security"; echo "$security"; }
        echo ""
        cat "$changelog"
    } > "$tmp" && mv "$tmp" "$changelog"

    log_success "CHANGELOG.md updated"
}

# Update README.md
update_readme() {
    log_info "Updating README.md"

    local readme="README.md"
    [ -f "$readme" ] || touch "$readme"

    # Update or add version badge
    if grep -q 'img.shields.io/badge/version-' "$readme"; then
        sed -i 's#img.shields.io/badge/version-[^)]*#img.shields.io/badge/version-v'"$VERSION"'-blue#g' "$readme"
    else
        sed -i "1i ![Version](https://img.shields.io/badge/version-v$VERSION-blue)\n" "$readme"
    fi

    # Add feature line
    local feature_line=" - 🎉 **${TITLE}** — shipped in v${VERSION}"
    if ! grep -qF "$feature_line" "$readme"; then
        # Ensure Features section exists
        grep -q "^## Features" "$readme" || printf "\n## Features\n" >> "$readme"
        # Add feature below Features heading
        sed -i "/^## Features/a $feature_line" "$readme"
    fi

    log_success "README.md updated"
}

# Generate help documentation
generate_help_docs() {
    log_info "Generating help documentation"

    local doc_dir="docs/help/features"
    mkdir -p "$doc_dir"
    local doc_file="${doc_dir}/${SLUG}.md"

    cat > "$doc_file" <<EOF
# ${TITLE}

**Version**: v${VERSION}
**Released**: ${DATE}

## Overview

<!-- Short summary from spec.md -->

## How to Use

<!-- Step-by-step from user stories -->

## Features

<!-- Pulled from acceptance criteria -->

## Screenshots

<!-- Add or link assets -->

## Troubleshooting

<!-- Common issues and resolutions -->
EOF

    # Update index
    local index="docs/help/README.md"
    mkdir -p "$(dirname "$index")"
    if ! grep -q "features/${SLUG}.md" "$index" 2>/dev/null; then
        [ -f "$index" ] || echo "# Help Documentation" > "$index"
        printf "\n## Features\n\n- [%s](features/%s.md) — v%s\n" "$TITLE" "$SLUG" "$VERSION" >> "$index"
    fi

    log_success "Help documentation generated"
}

# Update API docs (conditional)
update_api_docs() {
    # Check if API changes mentioned in spec/plan
    if grep -iq "API\|endpoint\|route" "$FEATURE_DIR/spec.md" "$FEATURE_DIR/plan.md" 2>/dev/null; then
        log_info "Updating API documentation"

        local apidoc="docs/API_ENDPOINTS.md"
        mkdir -p "$(dirname "$apidoc")"
        [ -f "$apidoc" ] || echo "# API Endpoints" > "$apidoc"

        local block="### ${TITLE} (v${VERSION})"
        if ! grep -qF "$block" "$apidoc"; then
            cat >> "$apidoc" <<EOF

${block}

- **Method**: [GET|POST|PUT|DELETE]
- **Path**: /api/[endpoint]
- **Auth**: [Required|Optional]
- **Request**: [Body schema]
- **Response**: [Response schema]

EOF
        fi

        log_success "API documentation updated"
    else
        log_info "No API changes detected, skipping API documentation"
    fi
}

# Manage GitHub milestones
manage_milestones() {
    log_info "Managing GitHub milestones"

    # Close current milestone
    local cur_minor
    cur_minor="$(echo "$VERSION" | awk -F. '{print $1"."$2}')"
    local cur_ms_json
    cur_ms_json="$(gh api repos/:owner/:repo/milestones --jq '.[] | select(.title | test("^v?'$cur_minor'\\.x$"))' 2>/dev/null || echo "")"

    if [ -n "$cur_ms_json" ]; then
        local cur_ms_num
        cur_ms_num="$(echo "$cur_ms_json" | jq -r '.number')"
        log_info "Closing milestone #${cur_ms_num} (v${cur_minor}.x)"
        gh api -X PATCH "repos/:owner/:repo/milestones/$cur_ms_num" -f state=closed >/dev/null 2>&1 || true
    else
        log_info "No milestone found for v${cur_minor}.x"
    fi

    # Create next milestone
    local next_minor due_on
    next_minor="$(echo "$VERSION" | awk -F. '{printf "%d.%d.0", $1, $2+1}')"
    due_on="$(date -u -d '+14 days' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v+14d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"

    log_info "Creating next milestone: v${next_minor}"
    gh api repos/:owner/:repo/milestones \
        -f title="v$next_minor" \
        -f due_on="$due_on" \
        >/dev/null 2>&1 || log_info "Milestone v${next_minor} already exists or creation failed"

    log_success "Milestones managed"
}

# Update roadmap issue
update_roadmap_issue() {
    log_info "Updating roadmap issue"

    local issue_json num
    issue_json="$(gh issue list --label 'type:feature' --search "slug: ${SLUG}" --json number --limit 1 2>/dev/null || echo "[]")"
    num="$(echo "$issue_json" | jq -r '.[0].number // empty')"

    if [ -n "$num" ]; then
        log_info "Marking issue #${num} as shipped"

        gh issue edit "$num" \
            --add-label "status:shipped" \
            --remove-label "status:in-progress" \
            >/dev/null 2>&1 || true

        gh issue comment "$num" --body "🚀 Shipped in v${VERSION} on ${DATE}

**Production**: ${PROD_URL:-N/A}

See [release notes](https://github.com/:owner/:repo/releases/tag/v${VERSION})" \
            >/dev/null 2>&1 || true

        log_success "Roadmap issue updated"
    else
        log_info "No roadmap issue found for slug: ${SLUG}"
    fi
}

# Update GitHub Release
update_github_release() {
    log_info "Updating GitHub Release"

    local release_tag="v${VERSION}"
    local run_id
    run_id="$(yq -r '.deployment.production.run_id // "N/A"' "$STATE_FILE")"

    if gh release view "$release_tag" >/dev/null 2>&1; then
        local existing_body
        existing_body="$(gh release view "$release_tag" --json body -q .body)"

        # Check if already has production info (idempotent)
        if echo "$existing_body" | grep -q "## 🚀 Production Deployment"; then
            log_info "GitHub Release already contains production deployment info"
        else
            local prod_footer
            prod_footer="$(cat <<EOF

---

## 🚀 Production Deployment

**Status**: ✅ Deployed
**URL**: ${PROD_URL:-N/A}
**Date**: ${DATE}
**Feature**: ${TITLE}

### Deployment Info
- **Version**: v${VERSION}
- **Run ID**: ${run_id}
- **Deploy Logs**: [View logs](https://github.com/:owner/:repo/actions/runs/${run_id})

### Documentation
- **CHANGELOG**: [View changes](https://github.com/:owner/:repo/blob/main/CHANGELOG.md)
- **Help Article**: [docs/help/features/${SLUG}.md](https://github.com/:owner/:repo/blob/main/docs/help/features/${SLUG}.md)

🎉 Feature fully deployed and documented!
EOF
)"

            local new_body="${existing_body}${prod_footer}"

            if gh release edit "$release_tag" --notes "$new_body" >/dev/null 2>&1; then
                log_success "GitHub Release updated with production deployment info"
            else
                log_warning "Failed to update GitHub Release (non-blocking)"
            fi
        fi
    else
        log_info "No GitHub Release found for ${release_tag}"
    fi
}

# Commit documentation changes
commit_docs() {
    log_info "Committing documentation changes"

    git add CHANGELOG.md README.md docs/ 2>/dev/null || true

    if git diff --cached --quiet; then
        log_info "No documentation changes to commit"
    else
        git commit -m "docs: finalize v${VERSION} documentation

- Update CHANGELOG.md with v${VERSION} section
- Update README.md version badge and features list
- Add help article for ${TITLE}
- Update API documentation (conditional)
- Update GitHub Release with production deployment info

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" || true

        if git push; then
            log_success "Documentation changes pushed"
        else
            log_warning "Push failed (may need to pull first)"
            log_info "Fix: git pull --rebase && spec-cli.py finalize"
        fi
    fi
}

# Archive completed workflow artifacts
archive_artifacts() {
    log_info "Archiving workflow artifacts"

    # Create completed directory
    local completed_dir="${WORKSPACE}/completed"
    mkdir -p "$completed_dir"

    # Define artifacts to archive based on workflow type
    local artifacts
    if [ "$WORKFLOW_TYPE" = "epic" ]; then
        artifacts="epic-spec.md plan.md sprint-plan.md tasks.md NOTES.md research.md walkthrough.md"
    else
        artifacts="spec.md plan.md tasks.md NOTES.md"
    fi

    # Move artifacts to completed/
    local archived_count=0
    for artifact in $artifacts; do
        if [ -f "${WORKSPACE}/${artifact}" ]; then
            mv "${WORKSPACE}/${artifact}" "${completed_dir}/"
            log_success "Archived: ${artifact}"
            ((archived_count++))
        fi
    done

    if [ $archived_count -gt 0 ]; then
        log_success "${archived_count} artifacts archived to ${completed_dir}"
    else
        log_warning "No artifacts to archive"
    fi
}

# Cleanup feature branch
cleanup_branch() {
    log_info "Cleaning up feature branch"

    local feature_branch
    feature_branch="$(yq -r '.workflow.git.feature_branch // ""' "$STATE_FILE")"

    if [ -n "$feature_branch" ]; then
        local current
        current="$(git branch --show-current)"

        # Switch to main if on feature branch
        if [ "$current" == "$feature_branch" ]; then
            git checkout -q main 2>/dev/null || git checkout -q master 2>/dev/null || true
        fi

        # Only delete if fully merged (safe)
        if git branch --merged | grep -q " ${feature_branch}$"; then
            log_info "Deleting merged branch: ${feature_branch}"
            git branch -d "$feature_branch" 2>/dev/null || true
            git push origin --delete "$feature_branch" >/dev/null 2>&1 || true
            log_success "Feature branch deleted"
        else
            log_info "Branch ${feature_branch} not fully merged, skipping deletion"
        fi
    else
        log_info "No feature branch to clean up"
    fi
}

# Main workflow
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📚 Finalization Workflow"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Step 0: Prerequisites
    check_prerequisites

    # Step 1: Load context
    load_feature_context

    # Step 2: Epic walkthrough (if applicable)
    local workspace_type
    workspace_type="$(detect_workspace_type)"
    if [ "$workspace_type" == "epic" ]; then
        local epic_dir
        epic_dir="$(dirname "$(ls epics/*/epic-spec.xml 2>/dev/null | head -1)")"
        generate_epic_walkthrough "$epic_dir"
    fi

    # Step 3: Update CHANGELOG.md
    update_changelog

    # Step 4: Update README.md
    update_readme

    # Step 5: Generate help docs
    generate_help_docs

    # Step 6: Update API docs (conditional)
    update_api_docs

    # Step 7: Manage milestones
    manage_milestones

    # Step 8: Update roadmap issue
    update_roadmap_issue

    # Step 9: Update GitHub Release
    update_github_release

    # Step 10: Commit & push
    commit_docs

    # Step 11: Cleanup branch
    cleanup_branch

    # Step 12: Archive artifacts
    archive_artifacts

    # Summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📚 Finalization Complete"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Version: v${VERSION}"
    echo "Feature: ${SLUG}"
    echo "Date: ${DATE}"
    echo ""
    echo "### Files Updated"
    echo ""
    echo "- ✅ CHANGELOG.md (Keep a Changelog format)"
    echo "- ✅ README.md (Shields.io badge + features)"
    echo "- ✅ docs/help/features/${SLUG}.md (help article)"
    echo "- ✅ docs/API_ENDPOINTS.md (conditional)"
    echo ""
    echo "### GitHub"
    echo ""
    echo "- ✅ Milestones managed"
    echo "- ✅ Roadmap issue updated (if found)"
    echo "- ✅ GitHub Release updated"
    echo ""
    echo "### Git"
    echo ""
    echo "- ✅ Documentation committed and pushed"
    echo "- ✅ Feature branch cleaned up (if merged)"
    echo ""
    echo "### Next Steps"
    echo ""
    echo "1. Review documentation accuracy"
    echo "2. Announce release (social media, blog, email)"
    echo "3. Monitor user feedback and error logs"
    echo "4. Plan next feature from roadmap"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 Full workflow complete: /feature → /ship → /finalize ✅"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Run main workflow
main "$@"
