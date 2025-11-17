#!/usr/bin/env bash
#
# Design Health Check Script
# Scans design system for staleness, inconsistencies, and missing documentation
#
# Usage:
#   ./design-health-check.sh [--verbose] [--json]
#
# Flags:
#   --verbose    Show detailed output
#   --json       Output results as JSON
#
# Exit codes:
#   0 - All checks passed
#   1 - Warnings found (non-blocking)
#   2 - Critical issues found (requires attention)

set -Eeuo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
VERBOSE=false
JSON_OUTPUT=false

# Counters
CRITICAL_COUNT=0
WARNING_COUNT=0
INFO_COUNT=0

# Get repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$REPO_ROOT"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--verbose] [--json]"
      exit 1
      ;;
  esac
done

# Logging functions
log_critical() {
  ((CRITICAL_COUNT++))
  if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo -e "${RED}❌ CRITICAL:${NC} $1"
  fi
}

log_warning() {
  ((WARNING_COUNT++))
  if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
  fi
}

log_info() {
  ((INFO_COUNT++))
  if [[ "$JSON_OUTPUT" == "false" && "$VERBOSE" == "true" ]]; then
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
  fi
}

log_success() {
  if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo -e "${GREEN}✅ $1${NC}"
  fi
}

print_header() {
  if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
  fi
}

# Check 1: Design System Core Files Exist
check_core_files() {
  print_header "Check 1: Design System Core Files"

  local required_files=(
    "design/systems/tokens.css"
    "design/systems/ui-inventory.md"
    "docs/project/style-guide.md"
  )

  local optional_files=(
    "design/systems/approved-patterns.md"
    "design/inspirations.md"
    "design/systems/health.md"
  )

  for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      log_critical "Required file missing: $file"
      log_info "  Run /init-project or /init-brand-tokens to create it"
    else
      log_success "Found required file: $file"
    fi
  done

  for file in "${optional_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      log_info "Optional file missing: $file"
    else
      log_success "Found optional file: $file"
    fi
  done
}

# Check 2: CLAUDE.md Staleness
check_claude_md_staleness() {
  print_header "Check 2: CLAUDE.md File Staleness"

  local stale_threshold=7 # days
  local now=$(date +%s)

  # Check project-level CLAUDE.md
  if [[ -f "CLAUDE.md" ]]; then
    local file_age=$(stat -c %Y "CLAUDE.md" 2>/dev/null || stat -f %m "CLAUDE.md" 2>/dev/null || echo 0)
    local days_old=$(( (now - file_age) / 86400 ))

    if [[ $days_old -gt $stale_threshold ]]; then
      log_warning "Project CLAUDE.md is $days_old days old (threshold: $stale_threshold days)"
      log_info "  Last updated: $(date -r CLAUDE.md +%Y-%m-%d 2>/dev/null || stat -f %Sm -t %Y-%m-%d CLAUDE.md 2>/dev/null)"
    else
      log_success "Project CLAUDE.md is fresh ($days_old days old)"
    fi
  else
    log_warning "Project CLAUDE.md missing"
    log_info "  Living documentation not enabled"
  fi

  # Check feature-level CLAUDE.md files
  local stale_features=0
  if [[ -d "specs" ]]; then
    while IFS= read -r -d '' feature_claude; do
      local file_age=$(stat -c %Y "$feature_claude" 2>/dev/null || stat -f %m "$feature_claude" 2>/dev/null || echo 0)
      local days_old=$(( (now - file_age) / 86400 ))

      if [[ $days_old -gt $stale_threshold ]]; then
        ((stale_features++))
        log_warning "Stale feature CLAUDE.md: $feature_claude ($days_old days old)"
      elif [[ "$VERBOSE" == "true" ]]; then
        log_success "Fresh feature CLAUDE.md: $feature_claude ($days_old days old)"
      fi
    done < <(find specs -name "CLAUDE.md" -type f -print0 2>/dev/null || true)
  fi

  if [[ $stale_features -eq 0 ]]; then
    log_success "All feature CLAUDE.md files are fresh"
  fi
}

# Check 3: UI Inventory Sync
check_ui_inventory_sync() {
  print_header "Check 3: UI Inventory Synchronization"

  if [[ ! -f "design/systems/ui-inventory.md" ]]; then
    log_critical "ui-inventory.md missing - cannot verify component sync"
    return
  fi

  # Check if components directory exists
  local components_found=false
  local component_dirs=(
    "components/ui"
    "app/components/ui"
    "src/components/ui"
    "components"
  )

  local actual_components_dir=""
  for dir in "${component_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
      actual_components_dir="$dir"
      components_found=true
      break
    fi
  done

  if [[ "$components_found" == "false" ]]; then
    log_info "No components directory found - skipping sync check"
    return
  fi

  log_success "Found components directory: $actual_components_dir"

  # Count components in inventory vs actual files
  local inventory_count=$(grep -c "^### " design/systems/ui-inventory.md 2>/dev/null || echo 0)
  local actual_count=$(find "$actual_components_dir" -name "*.tsx" -o -name "*.jsx" -o -name "*.vue" 2>/dev/null | wc -l)

  local diff=$((actual_count - inventory_count))

  if [[ $diff -gt 5 ]]; then
    log_warning "ui-inventory.md may be out of sync"
    log_info "  Inventory components: $inventory_count"
    log_info "  Actual component files: $actual_count"
    log_info "  Difference: $diff components not documented"
    log_info "  Run frontend agent to update ui-inventory.md"
  elif [[ $diff -lt -5 ]]; then
    log_info "ui-inventory.md may have stale entries ($diff components removed)"
  else
    log_success "ui-inventory.md appears synchronized (±$diff components)"
  fi
}

# Check 4: Approved Patterns Coverage
check_approved_patterns() {
  print_header "Check 4: Approved Patterns Coverage"

  if [[ ! -f "design/systems/approved-patterns.md" ]]; then
    log_info "approved-patterns.md not found - no patterns documented yet"
    return
  fi

  # Count approved features (those with mockups)
  local mockup_features=0
  if [[ -d "specs" ]]; then
    mockup_features=$(find specs -type d -name "mockups" 2>/dev/null | wc -l)
  fi

  # Count documented patterns
  local pattern_count=$(grep -c "^## Pattern:" design/systems/approved-patterns.md 2>/dev/null || echo 0)

  if [[ $mockup_features -gt 0 ]]; then
    local coverage=$((pattern_count * 100 / mockup_features))

    if [[ $coverage -lt 50 ]]; then
      log_warning "Low pattern documentation coverage: $coverage%"
      log_info "  Features with mockups: $mockup_features"
      log_info "  Documented patterns: $pattern_count"
      log_info "  Expected: At least 1 pattern per 2 features"
    else
      log_success "Pattern coverage: $coverage% ($pattern_count patterns for $mockup_features features)"
    fi
  else
    log_info "No features with mockups yet - pattern documentation N/A"
  fi
}

# Check 5: Design Token Usage
check_token_usage() {
  print_header "Check 5: Design Token Usage in Recent Features"

  if [[ ! -f "design/systems/tokens.css" ]]; then
    log_critical "tokens.css missing - cannot verify token usage"
    return
  fi

  # Check if recent mockups use tokens
  local recent_mockups=0
  local mockups_with_tokens=0

  if [[ -d "specs" ]]; then
    # Find mockups modified in last 30 days
    while IFS= read -r -d '' mockup; do
      ((recent_mockups++))

      # Check if mockup links to tokens.css
      if grep -q "tokens.css" "$mockup" 2>/dev/null; then
        ((mockups_with_tokens++))
      else
        log_warning "Mockup missing tokens.css link: $mockup"
      fi
    done < <(find specs -name "*.html" -type f -mtime -30 -print0 2>/dev/null || true)
  fi

  if [[ $recent_mockups -eq 0 ]]; then
    log_info "No recent mockups found (last 30 days)"
  elif [[ $mockups_with_tokens -eq $recent_mockups ]]; then
    log_success "All recent mockups use tokens.css ($mockups_with_tokens/$recent_mockups)"
  else
    log_warning "Some mockups missing tokens.css link: $mockups_with_tokens/$recent_mockups"
  fi
}

# Check 6: Style Guide Freshness
check_style_guide_freshness() {
  print_header "Check 6: Style Guide Freshness"

  if [[ ! -f "docs/project/style-guide.md" ]]; then
    log_critical "style-guide.md missing"
    return
  fi

  local file_age=$(stat -c %Y "docs/project/style-guide.md" 2>/dev/null || stat -f %m "docs/project/style-guide.md" 2>/dev/null || echo 0)
  local now=$(date +%s)
  local days_old=$(( (now - file_age) / 86400 ))

  if [[ $days_old -gt 90 ]]; then
    log_warning "style-guide.md is $days_old days old (>90 days)"
    log_info "  Consider reviewing and updating Core 9 Rules"
  else
    log_success "style-guide.md is fresh ($days_old days old)"
  fi

  # Check if Core 9 Rules section exists
  if grep -q "## Core 9 Rules" "docs/project/style-guide.md" 2>/dev/null; then
    log_success "Core 9 Rules section found in style-guide.md"
  else
    log_warning "Core 9 Rules section missing from style-guide.md"
    log_info "  Expected section: '## Core 9 Rules'"
  fi
}

# Check 7: Mockup Template Availability
check_mockup_templates() {
  print_header "Check 7: Mockup Template Availability"

  local template_files=(
    ".spec-flow/templates/mockups/index.html"
    ".spec-flow/templates/mockups/screen.html"
    ".spec-flow/templates/mockups/_shared/navigation.js"
    ".spec-flow/templates/mockups/_shared/state-switcher.js"
  )

  local missing_templates=0
  for file in "${template_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      ((missing_templates++))
      log_warning "Mockup template missing: $file"
    elif [[ "$VERBOSE" == "true" ]]; then
      log_success "Found template: $file"
    fi
  done

  if [[ $missing_templates -eq 0 ]]; then
    log_success "All mockup templates available"
  else
    log_warning "$missing_templates mockup templates missing"
    log_info "  Multi-screen mockups may not work correctly"
  fi
}

# Generate JSON report
generate_json_report() {
  local exit_code=0
  if [[ $CRITICAL_COUNT -gt 0 ]]; then
    exit_code=2
  elif [[ $WARNING_COUNT -gt 0 ]]; then
    exit_code=1
  fi

  cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "summary": {
    "critical": $CRITICAL_COUNT,
    "warnings": $WARNING_COUNT,
    "info": $INFO_COUNT,
    "exit_code": $exit_code
  },
  "health_score": $((100 - (CRITICAL_COUNT * 20) - (WARNING_COUNT * 5))),
  "status": "$([ $CRITICAL_COUNT -eq 0 ] && echo "healthy" || echo "needs_attention")"
}
EOF
}

# Print summary
print_summary() {
  if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE} Summary${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    if [[ $CRITICAL_COUNT -eq 0 && $WARNING_COUNT -eq 0 ]]; then
      echo -e "${GREEN}🎉 Design system health check passed!${NC}"
    else
      echo -e "${RED}Critical Issues: $CRITICAL_COUNT${NC}"
      echo -e "${YELLOW}Warnings: $WARNING_COUNT${NC}"
      if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}Info Messages: $INFO_COUNT${NC}"
      fi
    fi

    local health_score=$((100 - (CRITICAL_COUNT * 20) - (WARNING_COUNT * 5)))
    echo ""
    echo -e "Health Score: ${BLUE}${health_score}%${NC}"
    echo ""

    if [[ $health_score -ge 90 ]]; then
      echo -e "Status: ${GREEN}Excellent${NC}"
    elif [[ $health_score -ge 70 ]]; then
      echo -e "Status: ${YELLOW}Good${NC}"
    elif [[ $health_score -ge 50 ]]; then
      echo -e "Status: ${YELLOW}Needs Attention${NC}"
    else
      echo -e "Status: ${RED}Poor - Action Required${NC}"
    fi

    echo ""
    echo "Run with --verbose for detailed output"
    echo "Run with --json for machine-readable output"
    echo ""
  fi
}

# Main execution
main() {
  if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        Design System Health Check                        ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
  fi

  check_core_files
  check_claude_md_staleness
  check_ui_inventory_sync
  check_approved_patterns
  check_token_usage
  check_style_guide_freshness
  check_mockup_templates

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    generate_json_report
  else
    print_summary
  fi

  # Determine exit code
  if [[ $CRITICAL_COUNT -gt 0 ]]; then
    exit 2
  elif [[ $WARNING_COUNT -gt 0 ]]; then
    exit 1
  else
    exit 0
  fi
}

main "$@"
