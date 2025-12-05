#!/usr/bin/env bash
# Finalization workflow - Documentation updates and housekeeping after production deployment
# Standards: Keep a Changelog, SemVer, Shields.io badges, GitHub CLI
# shellcheck disable=SC2086  # Word splitting intentional for $range in git log
# shellcheck disable=SC2155  # Declare and assign separately - performance trade-off accepted

set -euo pipefail

# Error handler for debugging
trap 'log_error "Error on line $LINENO. Exit code: $?"' ERR

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

    local walkthrough_file="${epic_dir}/walkthrough.md"
    local sprint_plan="${epic_dir}/sprint-plan.md"
    local epic_spec="${epic_dir}/epic-spec.md"
    local tasks_file="${epic_dir}/tasks.md"
    local notes_file="${epic_dir}/NOTES.md"
    local state_file="${epic_dir}/state.yaml"

    # Extract epic metadata
    local epic_title epic_slug start_date end_date
    epic_title="$(yq -r '.epic.title // "Unknown Epic"' "$state_file" 2>/dev/null || echo "Unknown Epic")"
    epic_slug="$(yq -r '.epic.slug // "unknown"' "$state_file" 2>/dev/null || basename "$epic_dir")"
    start_date="$(yq -r '.epic.started_at // ""' "$state_file" 2>/dev/null || echo "")"
    end_date="$(date +%F)"

    # Calculate duration
    local duration_days="N/A"
    if [ -n "$start_date" ]; then
        local start_epoch end_epoch
        start_epoch="$(date -d "$start_date" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$start_date" +%s 2>/dev/null || echo 0)"
        end_epoch="$(date +%s)"
        if [ "$start_epoch" -gt 0 ]; then
            duration_days="$(( (end_epoch - start_epoch) / 86400 ))"
        fi
    fi

    # Count sprints from sprint-plan.md
    local total_sprints=0
    local completed_sprints=0
    if [ -f "$sprint_plan" ]; then
        total_sprints="$(grep -c "^## Sprint" "$sprint_plan" 2>/dev/null || echo 0)"
        completed_sprints="$(grep -c "\[x\]" "$sprint_plan" 2>/dev/null || echo "$total_sprints")"
    fi

    # Count tasks from tasks.md
    local total_tasks=0
    local completed_tasks=0
    if [ -f "$tasks_file" ]; then
        total_tasks="$(grep -cE "^\s*-\s*\[" "$tasks_file" 2>/dev/null || echo 0)"
        completed_tasks="$(grep -cE "^\s*-\s*\[x\]" "$tasks_file" 2>/dev/null || echo 0)"
    fi

    # Calculate velocity (tasks per sprint)
    local velocity="N/A"
    if [ "$total_sprints" -gt 0 ]; then
        velocity="$(echo "scale=1; $completed_tasks / $total_sprints" | bc 2>/dev/null || echo "N/A")"
    fi

    # Extract blockers from NOTES.md
    local blockers_count=0
    if [ -f "$notes_file" ]; then
        blockers_count="$(grep -ciE "blocker|blocked|issue|problem|error" "$notes_file" 2>/dev/null || echo 0)"
    fi

    # Generate ASCII velocity chart
    local velocity_chart=""
    if [ -f "$sprint_plan" ]; then
        velocity_chart="$(generate_velocity_chart "$sprint_plan" "$tasks_file")"
    fi

    # Extract key decisions from NOTES.md
    local key_decisions=""
    if [ -f "$notes_file" ]; then
        key_decisions="$(grep -E "^[-*]\s*(Decision|Decided|Chose|Selected|Using)" "$notes_file" 2>/dev/null | head -10 || echo "- No key decisions recorded")"
    fi

    # Generate walkthrough file
    cat > "$walkthrough_file" <<EOF
# Epic Walkthrough: ${epic_title}

**Epic**: ${epic_slug}
**Duration**: ${start_date:-"Unknown"} → ${end_date} (${duration_days} days)
**Status**: ✅ Completed

---

## Executive Summary

This epic was completed in **${duration_days} days** across **${total_sprints} sprints**.

### Key Metrics

| Metric | Value |
|--------|-------|
| Total Sprints | ${total_sprints} |
| Completed Sprints | ${completed_sprints} |
| Total Tasks | ${total_tasks} |
| Completed Tasks | ${completed_tasks} |
| Average Velocity | ${velocity} tasks/sprint |
| Blockers Encountered | ${blockers_count} |

---

## Sprint-by-Sprint Breakdown

EOF

    # Add sprint details from sprint-plan.md
    if [ -f "$sprint_plan" ]; then
        # Extract sprint sections
        local sprint_num=1
        while IFS= read -r line; do
            if [[ "$line" =~ ^##[[:space:]]Sprint ]]; then
                echo "### Sprint ${sprint_num}" >> "$walkthrough_file"
                echo "" >> "$walkthrough_file"
                ((sprint_num++))
            elif [[ "$line" =~ ^\s*-\s*\[ ]]; then
                echo "$line" >> "$walkthrough_file"
            fi
        done < "$sprint_plan"
        echo "" >> "$walkthrough_file"
    else
        echo "*No sprint-plan.md found*" >> "$walkthrough_file"
        echo "" >> "$walkthrough_file"
    fi

    # Add velocity chart
    cat >> "$walkthrough_file" <<EOF
---

## Velocity Trends

\`\`\`
${velocity_chart:-"No velocity data available"}
\`\`\`

---

## Key Decisions

${key_decisions}

---

## Lessons Learned

<!-- Add lessons learned during epic execution -->

### What Went Well
-

### What Could Be Improved
-

### Action Items for Next Epic
-

---

## Files Modified

\`\`\`
$(git log --name-only --pretty=format: --since="${start_date:-"1 year ago"}" -- . 2>/dev/null | sort -u | head -30 || echo "Unable to retrieve file list")
\`\`\`

---

*Generated by Spec-Flow /finalize on ${end_date}*
EOF

    log_success "Epic walkthrough generated: ${walkthrough_file}"
}

# Generate ASCII velocity chart
generate_velocity_chart() {
    local sprint_plan="$1"
    local tasks_file="$2"

    # Simple ASCII bar chart of tasks per sprint
    local chart=""
    local sprint_num=1
    local max_tasks=10

    # Count tasks per sprint (simplified - counts all tasks divided by sprints)
    local total_tasks
    total_tasks="$(grep -cE "^\s*-\s*\[" "$tasks_file" 2>/dev/null || echo 0)"
    local total_sprints
    total_sprints="$(grep -c "^## Sprint" "$sprint_plan" 2>/dev/null || echo 1)"

    if [ "$total_sprints" -eq 0 ]; then
        total_sprints=1
    fi

    local avg_per_sprint=$(( total_tasks / total_sprints ))

    # Generate simple bar chart
    chart="Tasks per Sprint (avg: ${avg_per_sprint})\n"
    chart+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    for i in $(seq 1 "$total_sprints"); do
        local bar_len=$avg_per_sprint
        if [ "$bar_len" -gt 20 ]; then
            bar_len=20
        fi
        local bar=""
        for j in $(seq 1 "$bar_len"); do
            bar+="█"
        done
        chart+="Sprint $i: ${bar} (${avg_per_sprint})\n"
    done

    echo -e "$chart"
}

# Detect patterns across completed epics
detect_patterns() {
    log_info "Analyzing patterns across completed epics"

    local analytics_dir=".spec-flow/analytics"
    local patterns_file="${analytics_dir}/patterns.json"
    mkdir -p "$analytics_dir"

    # Count completed epics
    local completed_epics
    completed_epics="$(find epics -maxdepth 2 -name "completed" -type d 2>/dev/null | wc -l || echo 0)"

    if [ "$completed_epics" -lt 2 ]; then
        log_info "Need at least 2 completed epics for pattern detection (found: ${completed_epics})"
        return 0
    fi

    log_info "Found ${completed_epics} completed epics, analyzing patterns..."

    # Initialize pattern data
    local total_duration=0
    local total_tasks=0
    local total_sprints=0
    local total_blockers=0
    local epic_count=0

    # Collect common blocker keywords
    local blocker_keywords=""
    local task_types=""
    local quality_gate_failures=""

    # Iterate over completed epics
    for epic_dir in epics/*/; do
        local state_file="${epic_dir}state.yaml"
        local notes_file="${epic_dir}NOTES.md"
        local walkthrough="${epic_dir}completed/walkthrough.md"

        # Skip if no state file
        [ -f "$state_file" ] || continue

        # Check if epic is completed
        local status
        status="$(yq -r '.status // ""' "$state_file" 2>/dev/null || echo "")"
        if [ "$status" != "complete" ] && [ "$status" != "completed" ]; then
            continue
        fi

        ((epic_count++))

        # Extract metrics from state.yaml
        local start_date end_date
        start_date="$(yq -r '.epic.started_at // ""' "$state_file" 2>/dev/null || echo "")"
        end_date="$(yq -r '.epic.completed_at // ""' "$state_file" 2>/dev/null || echo "")"

        # Calculate duration if dates available
        if [ -n "$start_date" ] && [ -n "$end_date" ]; then
            local start_epoch end_epoch
            start_epoch="$(date -d "$start_date" +%s 2>/dev/null || echo 0)"
            end_epoch="$(date -d "$end_date" +%s 2>/dev/null || echo 0)"
            if [ "$start_epoch" -gt 0 ] && [ "$end_epoch" -gt 0 ]; then
                local duration=$(( (end_epoch - start_epoch) / 86400 ))
                total_duration=$((total_duration + duration))
            fi
        fi

        # Count tasks from tasks.md or walkthrough
        if [ -f "${epic_dir}tasks.md" ]; then
            local tasks
            tasks="$(grep -cE "^\s*-\s*\[" "${epic_dir}tasks.md" 2>/dev/null || echo 0)"
            total_tasks=$((total_tasks + tasks))
        fi

        # Count sprints
        if [ -f "${epic_dir}sprint-plan.md" ]; then
            local sprints
            sprints="$(grep -c "^## Sprint" "${epic_dir}sprint-plan.md" 2>/dev/null || echo 0)"
            total_sprints=$((total_sprints + sprints))
        fi

        # Extract blocker patterns from NOTES.md
        if [ -f "$notes_file" ]; then
            local blockers
            blockers="$(grep -iE "blocker|blocked|stuck|issue|problem" "$notes_file" 2>/dev/null || echo "")"
            if [ -n "$blockers" ]; then
                blocker_keywords+="$blockers\n"
                total_blockers=$((total_blockers + $(echo -e "$blockers" | wc -l)))
            fi
        fi

        # Extract quality gate failures
        if [ -f "${epic_dir}optimization-report.md" ]; then
            local failures
            failures="$(grep -E "❌|FAIL|failed" "${epic_dir}optimization-report.md" 2>/dev/null || echo "")"
            if [ -n "$failures" ]; then
                quality_gate_failures+="$failures\n"
            fi
        fi
    done

    # Calculate averages
    local avg_duration=0
    local avg_tasks=0
    local avg_sprints=0
    local avg_blockers=0

    if [ "$epic_count" -gt 0 ]; then
        avg_duration=$((total_duration / epic_count))
        avg_tasks=$((total_tasks / epic_count))
        avg_sprints=$((total_sprints / epic_count))
        avg_blockers=$((total_blockers / epic_count))
    fi

    # Extract common blocker themes
    local common_blockers=""
    if [ -n "$blocker_keywords" ]; then
        common_blockers="$(echo -e "$blocker_keywords" | grep -oE '\b(API|auth|database|CI|deploy|test|config|env)\b' | sort | uniq -c | sort -rn | head -5 | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')"
    fi

    # Write patterns.json
    cat > "$patterns_file" <<EOF
{
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "epic_count": ${epic_count},
  "averages": {
    "duration_days": ${avg_duration},
    "tasks_per_epic": ${avg_tasks},
    "sprints_per_epic": ${avg_sprints},
    "blockers_per_epic": ${avg_blockers}
  },
  "velocity": {
    "tasks_per_sprint": $(echo "scale=1; ${avg_tasks} / (${avg_sprints} + 1)" | bc 2>/dev/null || echo "0")
  },
  "common_blocker_themes": "${common_blockers:-none}",
  "quality_gate_failure_count": $(echo -e "$quality_gate_failures" | grep -c "." || echo 0),
  "recommendations": [
    $([ "$avg_blockers" -gt 3 ] && echo '"Consider adding more upfront clarification to reduce blockers",' || echo "")
    $([ "$avg_duration" -gt 14 ] && echo '"Average epic duration exceeds 2 weeks - consider smaller scope",' || echo "")
    $([ -n "$common_blockers" ] && echo "\"Focus on: ${common_blockers} - recurring blocker themes\"," || echo "")
    "Review patterns after next epic"
  ]
}
EOF

    log_success "Pattern analysis complete: ${patterns_file}"
    log_info "Analyzed ${epic_count} epics | Avg duration: ${avg_duration}d | Avg velocity: ${avg_tasks}/${avg_sprints} tasks/sprint"

    # Check if patterns suggest workflow improvements
    if [ "$avg_blockers" -gt 3 ] || [ "$avg_duration" -gt 14 ]; then
        log_warning "Patterns suggest workflow improvements may help"
        log_info "Run /heal-workflow to review and apply improvements"
        echo "PATTERNS_SUGGEST_HEALING=true"
    fi
}

# Load feature context
load_feature_context() {
    local feature_dir
    feature_dir="$(ls -td specs/*/ 2>/dev/null | head -1)"

    if [ -z "$feature_dir" ]; then
        log_error "No feature directory found in specs/"
        exit 1
    fi

    local state_file="${feature_dir%/}/state.yaml"

    if [ ! -f "$state_file" ]; then
        log_error "No state.yaml found in $feature_dir"
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

    # Add documentation files (ignore errors for missing files)
    for doc in CHANGELOG.md README.md; do
        [ -f "$doc" ] && git add "$doc" 2>/dev/null || log_info "Skipped $doc (not found or no changes)"
    done
    [ -d "docs/" ] && git add docs/ 2>/dev/null || log_info "Skipped docs/ (not found or no changes)"

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

# Cleanup feature branch and worktree
cleanup_branch() {
    log_info "Cleaning up feature branch and worktree"

    local feature_branch
    feature_branch="$(yq -r '.workflow.git.feature_branch // ""' "$STATE_FILE")"

    local worktree_enabled
    worktree_enabled="$(yq -r '.workflow.git.worktree_enabled // false' "$STATE_FILE")"

    local worktree_path
    worktree_path="$(yq -r '.workflow.git.worktree_path // ""' "$STATE_FILE")"

    # Step 1: Cleanup worktree if it was used
    if [ "$worktree_enabled" = "true" ] && [ -n "$worktree_path" ]; then
        log_info "Cleaning up worktree: $worktree_path"

        # Check if user preferences allow cleanup
        local cleanup_enabled
        cleanup_enabled="false"
        if [ -f ".spec-flow/config/user-preferences.yaml" ]; then
            cleanup_enabled=$(grep "cleanup_on_finalize:" .spec-flow/config/user-preferences.yaml 2>/dev/null | grep -A 1 "worktrees:" | tail -1 | awk '{print $2}')
        fi

        # Default to true if not configured
        if [ -z "$cleanup_enabled" ] || [ "$cleanup_enabled" = "true" ]; then
            # Extract slug from worktree path
            local slug
            slug="$(basename "$worktree_path")"

            # Use worktree manager to remove
            if bash .spec-flow/scripts/bash/worktree-manager.sh remove "$slug" >/dev/null 2>&1; then
                log_success "Worktree removed: $slug"
            else
                log_warn "Failed to remove worktree: $slug (may need manual cleanup)"
            fi
        else
            log_info "Worktree cleanup disabled in preferences, skipping"
        fi
    fi

    # Step 2: Cleanup regular branch
    if [ -n "$feature_branch" ]; then
        local current
        current="$(git branch --show-current)"

        # Switch to main if on feature branch (only if not in worktree)
        if [ "$worktree_enabled" != "true" ] && [ "$current" == "$feature_branch" ]; then
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

    # Step 2: Epic walkthrough and pattern detection (if applicable)
    local workspace_type
    workspace_type="$(detect_workspace_type)"
    export WORKFLOW_TYPE="$workspace_type"

    if [ "$workspace_type" == "epic" ]; then
        local epic_dir
        epic_dir="$(dirname "$(ls epics/*/epic-spec.xml 2>/dev/null | head -1)")"
        export WORKSPACE="$epic_dir"

        # Generate walkthrough
        generate_epic_walkthrough "$epic_dir"

        # Run pattern detection after epic completion
        detect_patterns
    else
        export WORKSPACE="${FEATURE_DIR%/}"
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
