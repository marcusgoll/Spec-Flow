#!/usr/bin/env bash
# Learning Analysis and Suggestion Generator
# Orchestrates pattern detection and generates actionable suggestions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Configuration
# ============================================================================

REPO_ROOT="$(resolve_repo_root)"
LEARNINGS_DIR="$REPO_ROOT/.spec-flow/learnings"
METADATA_FILE="$LEARNINGS_DIR/learning-metadata.yaml"
PATTERN_DETECTOR="$SCRIPT_DIR/../python/pattern-detector.py"

JSON_OUT=false
APPLY_AUTO=false

# ============================================================================
# Helper Functions
# ============================================================================

show_help() {
    cat <<'EOF'
Usage: analyze-learnings.sh [options]

Options:
  --json                  Output in JSON format
  --apply-auto            Auto-apply low-risk patterns
  -h, --help              Show this help

Description:
  Analyzes collected observations to detect patterns and generate suggestions.
  Runs pattern detection, risk classification, and generates reports.

Examples:
  # Analyze and show results
  analyze-learnings.sh

  # Analyze and auto-apply low-risk patterns
  analyze-learnings.sh --apply-auto

  # Get JSON output for scripting
  analyze-learnings.sh --json
EOF
}

check_prerequisites() {
    # Check if Python is available
    if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
        log_error "Python not found. Pattern detection requires Python 3.6+"
        return 1
    fi

    # Check if PyYAML is installed
    local python_cmd="python3"
    command -v python3 &>/dev/null || python_cmd="python"

    if ! $python_cmd -c "import yaml" 2>/dev/null; then
        log_warn "PyYAML not installed. Installing..."
        $python_cmd -m pip install --quiet PyYAML || {
            log_error "Failed to install PyYAML"
            return 1
        }
    fi

    return 0
}

run_pattern_detection() {
    log_info "Running pattern detection..."

    local python_cmd="python3"
    command -v python3 &>/dev/null || python_cmd="python"

    local results
    results=$($python_cmd "$PATTERN_DETECTOR" "$LEARNINGS_DIR" --json 2>/dev/null)

    if [ $? -ne 0 ]; then
        log_error "Pattern detection failed"
        return 1
    fi

    echo "$results"
}

update_pattern_files() {
    local results="$1"

    log_info "Updating pattern files..."

    # Extract patterns by type
    local perf_patterns
    perf_patterns=$(echo "$results" | python3 -c "import json, sys; data=json.load(sys.stdin); print(json.dumps(data.get('performance_patterns', [])))")

    local anti_patterns
    anti_patterns=$(echo "$results" | python3 -c "import json, sys; data=json.load(sys.stdin); print(json.dumps(data.get('anti_patterns', [])))")

    local abbreviations
    abbreviations=$(echo "$results" | python3 -c "import json, sys; data=json.load(sys.stdin); print(json.dumps(data.get('abbreviations', [])))")

    local tweaks
    tweaks=$(echo "$results" | python3 -c "import json, sys; data=json.load(sys.stdin); print(json.dumps(data.get('claude_md_tweaks', [])))")

    # Update performance patterns
    if [ "$(echo "$perf_patterns" | python3 -c "import json, sys; print(len(json.load(sys.stdin)))")" -gt 0 ]; then
        merge_patterns "$perf_patterns" "$LEARNINGS_DIR/performance-patterns.yaml"
        log_success "Updated performance patterns"
    fi

    # Update anti-patterns
    if [ "$(echo "$anti_patterns" | python3 -c "import json, sys; print(len(json.load(sys.stdin)))")" -gt 0 ]; then
        merge_patterns "$anti_patterns" "$LEARNINGS_DIR/anti-patterns.yaml" "antipatterns"
        log_success "Updated anti-patterns"
    fi

    # Update abbreviations
    if [ "$(echo "$abbreviations" | python3 -c "import json, sys; print(len(json.load(sys.stdin)))")" -gt 0 ]; then
        merge_patterns "$abbreviations" "$LEARNINGS_DIR/custom-abbreviations.yaml" "abbreviations"
        log_success "Updated abbreviations"
    fi

    # Update tweaks
    if [ "$(echo "$tweaks" | python3 -c "import json, sys; print(len(json.load(sys.stdin)))")" -gt 0 ]; then
        merge_patterns "$tweaks" "$LEARNINGS_DIR/claude-md-tweaks.yaml" "tweaks"
        log_success "Updated CLAUDE.md tweaks"
    fi
}

merge_patterns() {
    local new_patterns="$1"
    local target_file="$2"
    local key="${3:-patterns}"

    # Load existing patterns
    local existing=""
    if [ -f "$target_file" ]; then
        existing=$(yq eval ".$key" "$target_file" 2>/dev/null || echo "[]")
    else
        existing="[]"
    fi

    # Merge new patterns (avoid duplicates by ID)
    local python_cmd="python3"
    command -v python3 &>/dev/null || python_cmd="python"

    local merged
    merged=$($python_cmd - <<EOF
import json, sys
new = json.loads('$new_patterns')
existing = json.loads('$existing')

# Build map of existing patterns by ID
existing_map = {p.get('id', p.get('abbr', '')): p for p in existing}

# Add or update with new patterns
for pattern in new:
    pattern_id = pattern.get('id', pattern.get('abbr', ''))
    if pattern_id:
        existing_map[pattern_id] = pattern

# Convert back to list
merged = list(existing_map.values())
print(json.dumps(merged, indent=2))
EOF
)

    # Update file
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    yq eval ".$key = $merged | .last_updated = \"$timestamp\"" -i "$target_file" 2>/dev/null || {
        # Fallback: write directly
        cat > "$target_file" <<YAML
schema_version: "1.0"
last_updated: "$timestamp"
$key: $merged
YAML
    }
}

apply_low_risk_patterns() {
    local results="$1"

    log_info "Applying low-risk patterns..."

    # Count auto-applied patterns
    local auto_applied=0

    # Performance patterns (low-risk)
    local perf_count
    perf_count=$(echo "$results" | python3 -c "import json, sys; data=json.load(sys.stdin); print(sum(1 for p in data.get('performance_patterns', []) if p.get('auto_applied', False) and p.get('risk_level') == 'low'))")

    # Anti-patterns (low-risk, just warnings)
    local anti_count
    anti_count=$(echo "$results" | python3 -c "import json, sys; data=json.load(sys.stdin); print(sum(1 for p in data.get('anti_patterns', []) if p.get('auto_warn', False) and p.get('risk_level') == 'low'))")

    # Abbreviations (low-risk)
    local abbr_count
    abbr_count=$(echo "$results" | python3 -c "import json, sys; data=json.load(sys.stdin); print(sum(1 for p in data.get('abbreviations', []) if p.get('auto_expand', False) and p.get('risk_level') == 'low'))")

    auto_applied=$((perf_count + anti_count + abbr_count))

    if [ $auto_applied -gt 0 ]; then
        log_success "✓ Applied $auto_applied low-risk learnings automatically"

        # Update metadata
        if [ -f "$METADATA_FILE" ]; then
            local current_count
            current_count=$(yq eval '.auto_applied_count // 0' "$METADATA_FILE" 2>/dev/null || echo "0")
            local new_count=$((current_count + auto_applied))

            yq eval ".auto_applied_count = $new_count" -i "$METADATA_FILE" 2>/dev/null || true
        fi

        # Log details
        if [ $perf_count -gt 0 ]; then
            log_info "  - Performance patterns: $perf_count"
        fi
        if [ $anti_count -gt 0 ]; then
            log_info "  - Anti-pattern warnings: $anti_count"
        fi
        if [ $abbr_count -gt 0 ]; then
            log_info "  - Custom abbreviations: $abbr_count"
        fi
    else
        log_info "No low-risk patterns to apply"
    fi
}

generate_summary() {
    local results="$1"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Learning Analysis Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Performance patterns
    local perf_count
    perf_count=$(echo "$results" | python3 -c "import json, sys; print(len(json.load(sys.stdin).get('performance_patterns', [])))")
    echo "✓ Performance Patterns: $perf_count detected"

    if [ "$perf_count" -gt 0 ]; then
        echo "$results" | python3 -c "import json, sys; patterns=json.load(sys.stdin).get('performance_patterns', []); [print(f\"  • {p['name']} (confidence: {p['confidence']:.0%})\") for p in patterns[:5]]"
    fi
    echo ""

    # Anti-patterns
    local anti_count
    anti_count=$(echo "$results" | python3 -c "import json, sys; print(len(json.load(sys.stdin).get('anti_patterns', [])))")
    echo "⚠️  Anti-Patterns: $anti_count detected"

    if [ "$anti_count" -gt 0 ]; then
        echo "$results" | python3 -c "import json, sys; patterns=json.load(sys.stdin).get('anti_patterns', []); [print(f\"  • {p['name']} ({p['severity']} severity)\") for p in patterns[:5]]"
    fi
    echo ""

    # Abbreviations
    local abbr_count
    abbr_count=$(echo "$results" | python3 -c "import json, sys; print(len(json.load(sys.stdin).get('abbreviations', [])))")
    echo "📝 Custom Abbreviations: $abbr_count detected"

    if [ "$abbr_count" -gt 0 ]; then
        echo "$results" | python3 -c "import json, sys; abbrs=json.load(sys.stdin).get('abbreviations', []); [print(f\"  • '{a['abbr']}' → {a['expansion'][:50]}...\") for a in abbrs[:5]]"
    fi
    echo ""

    # CLAUDE.md tweaks
    local tweak_count
    tweak_count=$(echo "$results" | python3 -c "import json, sys; print(len(json.load(sys.stdin).get('claude_md_tweaks', [])))")
    echo "🔧 CLAUDE.md Tweaks: $tweak_count pending approval"

    if [ "$tweak_count" -gt 0 ]; then
        echo "$results" | python3 -c "import json, sys; tweaks=json.load(sys.stdin).get('claude_md_tweaks', []); [print(f\"  • {t['name']} ({t['impact']} impact)\") for t in tweaks[:5]]"
        echo ""
        echo "  Run /heal-workflow to review and approve tweaks"
    fi
    echo ""

    # Next steps
    echo "Next Steps:"
    if [ "$tweak_count" -gt 0 ]; then
        echo "  1. Review high-risk tweaks: /heal-workflow"
    fi
    if [ $((perf_count + anti_count + abbr_count)) -gt 0 ]; then
        echo "  2. View detailed learnings: /show-learnings all"
    fi
    echo "  3. Continue workflow as normal - learnings auto-apply"
    echo ""
}

update_metadata() {
    local results="$1"

    if [ ! -f "$METADATA_FILE" ]; then
        log_warn "Metadata file not found, skipping update"
        return
    fi

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Count totals
    local perf_count
    perf_count=$(echo "$results" | python3 -c "import json, sys; print(len(json.load(sys.stdin).get('performance_patterns', [])))")

    local anti_count
    anti_count=$(echo "$results" | python3 -c "import json, sys; print(len(json.load(sys.stdin).get('anti_patterns', [])))")

    local abbr_count
    abbr_count=$(echo "$results" | python3 -c "import json, sys; print(len(json.load(sys.stdin).get('abbreviations', [])))")

    local tweak_count
    tweak_count=$(echo "$results" | python3 -c "import json, sys; print(len(json.load(sys.stdin).get('claude_md_tweaks', [])))")

    # Update metadata
    yq eval ".last_analyzed = \"$timestamp\"" -i "$METADATA_FILE" 2>/dev/null || true
    yq eval ".total_learnings.performance_patterns = $perf_count" -i "$METADATA_FILE" 2>/dev/null || true
    yq eval ".total_learnings.anti_patterns = $anti_count" -i "$METADATA_FILE" 2>/dev/null || true
    yq eval ".total_learnings.custom_abbreviations = $abbr_count" -i "$METADATA_FILE" 2>/dev/null || true
    yq eval ".total_learnings.claude_md_tweaks = $tweak_count" -i "$METADATA_FILE" 2>/dev/null || true
    yq eval ".pending_approval_count = $tweak_count" -i "$METADATA_FILE" 2>/dev/null || true
}

# ============================================================================
# Main Workflow
# ============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                JSON_OUT=true
                shift
                ;;
            --apply-auto)
                APPLY_AUTO=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi

    # Run pattern detection
    local results
    results=$(run_pattern_detection)

    if [ $? -ne 0 ]; then
        log_error "Analysis failed"
        exit 1
    fi

    # Update pattern files
    update_pattern_files "$results"

    # Apply low-risk patterns if requested
    if [ "$APPLY_AUTO" = true ]; then
        apply_low_risk_patterns "$results"
    fi

    # Update metadata
    update_metadata "$results"

    # Output results
    if [ "$JSON_OUT" = true ]; then
        echo "$results"
    else
        generate_summary "$results"
    fi

    log_success "Analysis complete"
}

# Run main
main "$@"
