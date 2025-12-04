#!/usr/bin/env bash

# init-preferences.sh - Interactive wizard for user preferences configuration
#
# Generates or updates .spec-flow/config/user-preferences.yaml through a guided
# questionnaire that covers all configurable aspects of the Spec-Flow workflow.
#
# Usage:
#   init-preferences.sh [OPTIONS]
#
# Options:
#   --reset          Reset preferences to defaults before running wizard
#   --section NAME   Only configure a specific section (commands|automation|ui|worktrees|studio|prototype|e2e|learning|migrations)
#   --non-interactive  Use default values without prompts
#   --help           Show this help message
#
# Exit Codes:
#   0 - Success
#   1 - Error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CONFIG_DIR="$REPO_ROOT/.spec-flow/config"
PREF_FILE="$CONFIG_DIR/user-preferences.yaml"

# Default values
RESET_PREFS=false
SECTION=""
INTERACTIVE=true

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --reset)
      RESET_PREFS=true
      shift
      ;;
    --section)
      SECTION="$2"
      shift 2
      ;;
    --non-interactive)
      INTERACTIVE=false
      shift
      ;;
    --help)
      sed -n '2,17p' "$0" | sed 's/^# //'
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warning() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*" >&2; }
header() { echo -e "\n${BOLD}${CYAN}$*${NC}\n"; }

# Preference storage
declare -A PREFS

# Initialize defaults
init_defaults() {
  # Commands
  PREFS[feature_default_mode]="interactive"
  PREFS[feature_skip_mode_prompt]="false"
  PREFS[epic_default_mode]="interactive"
  PREFS[epic_skip_mode_prompt]="false"
  PREFS[tasks_default_mode]="standard"
  PREFS[init_project_default_mode]="interactive"
  PREFS[init_project_include_design]="false"
  PREFS[run_prompt_default_strategy]="auto-detect"

  # Automation
  PREFS[auto_approve_minor_changes]="false"
  PREFS[ci_mode_default]="false"

  # UI
  PREFS[show_usage_stats]="true"
  PREFS[recommend_last_used]="true"

  # Worktrees
  PREFS[worktrees_auto_create]="false"
  PREFS[worktrees_cleanup_on_finalize]="true"

  # Studio
  PREFS[studio_auto_continue]="false"
  PREFS[studio_default_agents]="3"

  # Prototype
  PREFS[prototype_git_persistence]="ask"

  # E2E Visual
  PREFS[e2e_visual_enabled]="true"
  PREFS[e2e_visual_failure_mode]="blocking"
  PREFS[e2e_visual_threshold]="0.1"
  PREFS[e2e_visual_auto_commit_baselines]="true"

  # Learning
  PREFS[learning_enabled]="true"
  PREFS[learning_auto_apply_low_risk]="true"
  PREFS[learning_require_approval_high_risk]="true"
  PREFS[learning_claude_md_optimization]="true"

  # Migrations
  PREFS[migrations_strictness]="blocking"
  PREFS[migrations_auto_generate_plan]="true"
}

# Load existing preferences
load_existing_prefs() {
  if [[ ! -f "$PREF_FILE" ]]; then
    return 0
  fi

  info "Loading existing preferences..."

  # Parse YAML file (simple grep-based parser)
  local yaml_content
  yaml_content=$(cat "$PREF_FILE")

  # Commands - Feature
  local val
  val=$(echo "$yaml_content" | grep -A 2 "feature:" | grep "default_mode:" | sed 's/.*default_mode: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[feature_default_mode]="$val"

  val=$(echo "$yaml_content" | grep -A 3 "feature:" | grep "skip_mode_prompt:" | sed 's/.*skip_mode_prompt: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[feature_skip_mode_prompt]="$val"

  # Commands - Epic
  val=$(echo "$yaml_content" | grep -A 2 "epic:" | grep "default_mode:" | sed 's/.*default_mode: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[epic_default_mode]="$val"

  # Commands - Tasks
  val=$(echo "$yaml_content" | grep -A 1 "tasks:" | grep "default_mode:" | sed 's/.*default_mode: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[tasks_default_mode]="$val"

  # Commands - Init-project
  val=$(echo "$yaml_content" | grep -A 2 "init-project:" | grep "include_design:" | sed 's/.*include_design: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[init_project_include_design]="$val"

  # Commands - Run-prompt
  val=$(echo "$yaml_content" | grep -A 1 "run-prompt:" | grep "default_strategy:" | sed 's/.*default_strategy: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[run_prompt_default_strategy]="$val"

  # Automation
  val=$(echo "$yaml_content" | grep "auto_approve_minor_changes:" | sed 's/.*auto_approve_minor_changes: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[auto_approve_minor_changes]="$val"

  val=$(echo "$yaml_content" | grep "ci_mode_default:" | sed 's/.*ci_mode_default: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[ci_mode_default]="$val"

  # UI
  val=$(echo "$yaml_content" | grep "show_usage_stats:" | sed 's/.*show_usage_stats: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[show_usage_stats]="$val"

  val=$(echo "$yaml_content" | grep "recommend_last_used:" | sed 's/.*recommend_last_used: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[recommend_last_used]="$val"

  # Worktrees
  val=$(echo "$yaml_content" | grep -A 2 "worktrees:" | grep "auto_create:" | sed 's/.*auto_create: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[worktrees_auto_create]="$val"

  # Studio
  val=$(echo "$yaml_content" | grep -A 2 "studio:" | grep "auto_continue:" | sed 's/.*auto_continue: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[studio_auto_continue]="$val"

  val=$(echo "$yaml_content" | grep -A 2 "studio:" | grep "default_agents:" | sed 's/.*default_agents: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[studio_default_agents]="$val"

  # Prototype
  val=$(echo "$yaml_content" | grep -A 1 "prototype:" | grep "git_persistence:" | sed 's/.*git_persistence: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[prototype_git_persistence]="$val"

  # E2E Visual
  val=$(echo "$yaml_content" | grep -A 3 "e2e_visual:" | grep "enabled:" | sed 's/.*enabled: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[e2e_visual_enabled]="$val"

  val=$(echo "$yaml_content" | grep -A 3 "e2e_visual:" | grep "failure_mode:" | sed 's/.*failure_mode: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[e2e_visual_failure_mode]="$val"

  # Learning
  val=$(echo "$yaml_content" | grep -A 3 "learning:" | grep "^    enabled:" | sed 's/.*enabled: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[learning_enabled]="$val"

  # Migrations
  val=$(echo "$yaml_content" | grep -A 2 "migrations:" | grep "strictness:" | sed 's/.*strictness: *//' | tr -d '[:space:]' || echo "")
  [[ -n "$val" ]] && PREFS[migrations_strictness]="$val"

  success "Existing preferences loaded"
}

# Ask a question with options
ask_choice() {
  local question="$1"
  local key="$2"
  shift 2
  local options=("$@")

  echo ""
  echo -e "${BOLD}$question${NC}"

  local current="${PREFS[$key]}"
  local idx=1
  for opt in "${options[@]}"; do
    local marker=""
    if [[ "$opt" == "$current" ]]; then
      marker=" ${GREEN}(current)${NC}"
    fi
    echo "  $idx. $opt$marker"
    idx=$((idx + 1))
  done

  if [[ "$INTERACTIVE" == false ]]; then
    echo "  → Using default: $current"
    return 0
  fi

  read -r -p "Choice (1-${#options[@]}, Enter to keep current): " choice
  if [[ -n "$choice" ]] && [[ "$choice" =~ ^[0-9]+$ ]]; then
    local index=$((choice - 1))
    if [[ $index -ge 0 && $index -lt ${#options[@]} ]]; then
      PREFS[$key]="${options[$index]}"
    fi
  fi
}

# Ask a yes/no question
ask_bool() {
  local question="$1"
  local key="$2"
  local description="${3:-}"

  echo ""
  echo -e "${BOLD}$question${NC}"
  [[ -n "$description" ]] && echo -e "  ${CYAN}$description${NC}"

  local current="${PREFS[$key]}"
  local default_hint="y"
  [[ "$current" == "false" ]] && default_hint="n"

  if [[ "$INTERACTIVE" == false ]]; then
    echo "  → Using default: $current"
    return 0
  fi

  read -r -p "y/n [$default_hint]: " answer
  case "$answer" in
    y|Y|yes|Yes) PREFS[$key]="true" ;;
    n|N|no|No) PREFS[$key]="false" ;;
    # Empty = keep current
  esac
}

# Ask for a number
ask_number() {
  local question="$1"
  local key="$2"
  local min="$3"
  local max="$4"

  echo ""
  echo -e "${BOLD}$question${NC}"

  local current="${PREFS[$key]}"

  if [[ "$INTERACTIVE" == false ]]; then
    echo "  → Using default: $current"
    return 0
  fi

  read -r -p "Enter number ($min-$max) [$current]: " answer
  if [[ -n "$answer" ]] && [[ "$answer" =~ ^[0-9]+$ ]]; then
    if [[ "$answer" -ge "$min" && "$answer" -le "$max" ]]; then
      PREFS[$key]="$answer"
    else
      warning "Value out of range, keeping $current"
    fi
  fi
}

# Section: Commands
configure_commands() {
  header "COMMAND DEFAULTS"

  # Q1: Feature mode
  ask_choice "Q1. Default mode for /feature command?" "feature_default_mode" \
    "auto" "interactive"

  # Q2: Skip mode prompt for feature
  ask_bool "Q2. Skip mode selection prompt for /feature?" "feature_skip_mode_prompt" \
    "When true, uses default_mode without asking every time"

  # Q3: Epic mode
  ask_choice "Q3. Default mode for /epic command?" "epic_default_mode" \
    "auto" "interactive"

  # Q4: Skip mode prompt for epic
  ask_bool "Q4. Skip mode selection prompt for /epic?" "epic_skip_mode_prompt" \
    "When true, uses default_mode without asking every time"

  # Q5: Tasks mode
  ask_choice "Q5. Default mode for /tasks command?" "tasks_default_mode" \
    "standard" "ui-first"

  # Q6: Init-project include design
  ask_bool "Q6. Auto-include design system with /init-project?" "init_project_include_design" \
    "Equivalent to always using --with-design flag"

  # Q7: Run-prompt strategy
  ask_choice "Q7. Default strategy for /run-prompt?" "run_prompt_default_strategy" \
    "auto-detect" "parallel" "sequential"
}

# Section: Automation
configure_automation() {
  header "AUTOMATION SETTINGS"

  # Q8: Auto-approve minor
  ask_bool "Q8. Auto-approve minor changes (formatting, comments)?" "auto_approve_minor_changes" \
    "Skips confirmation prompts for trivial changes"

  # Q9: CI mode default
  ask_bool "Q9. Default to CI-friendly behavior?" "ci_mode_default" \
    "Non-interactive mode, assumes --no-input"
}

# Section: UI
configure_ui() {
  header "USER INTERFACE"

  # Q10: Show usage stats
  ask_bool "Q10. Show command usage statistics in prompts?" "show_usage_stats" \
    "e.g., 'auto (used 8/10 times)'"

  # Q11: Recommend last used
  ask_bool "Q11. Mark last-used option with star?" "recommend_last_used" \
    "Highlights your previous choice"
}

# Section: Worktrees
configure_worktrees() {
  header "GIT WORKTREES (Parallel Development)"

  # Q12: Auto-create worktrees
  ask_bool "Q12. Auto-create git worktrees for epics/features?" "worktrees_auto_create" \
    "Enables parallel development with isolated directories"

  # Q13: Cleanup on finalize
  ask_bool "Q13. Auto-cleanup worktrees after /finalize?" "worktrees_cleanup_on_finalize" \
    "Removes worktree directories when feature ships"
}

# Section: Studio
configure_studio() {
  header "DEV STUDIO (Parallel AI Development)"

  # Q14: Auto-continue
  ask_bool "Q14. Auto-continue to next issue after /finalize?" "studio_auto_continue" \
    "Skips 'Pick up next issue?' prompt"

  # Q15: Default agents
  ask_number "Q15. Default number of agent worktrees for /studio?" "studio_default_agents" 1 10
}

# Section: Quality Gates
configure_quality() {
  header "QUALITY GATES"

  # Q16: E2E Visual enabled
  ask_bool "Q16. Enable E2E and visual regression testing?" "e2e_visual_enabled" \
    "Part of /optimize quality gates"

  # Q17: E2E failure mode
  ask_choice "Q17. How to handle E2E/visual test failures?" "e2e_visual_failure_mode" \
    "blocking" "warning"
}

# Section: Learning
configure_learning() {
  header "PERPETUAL LEARNING"

  ask_bool "Enable perpetual learning system?" "learning_enabled" \
    "Pattern detection and workflow self-improvement"

  if [[ "${PREFS[learning_enabled]}" == "true" ]]; then
    ask_bool "Auto-apply low-risk learnings (90%+ confidence)?" "learning_auto_apply_low_risk"
    ask_bool "Require approval for high-risk changes?" "learning_require_approval_high_risk"
  fi
}

# Section: Migrations
configure_migrations() {
  header "DATABASE MIGRATIONS"

  ask_choice "Migration handling during /implement?" "migrations_strictness" \
    "blocking" "warning" "auto_apply"

  ask_bool "Auto-generate migration-plan.md during /plan?" "migrations_auto_generate_plan"
}

# Write preferences to file
write_preferences() {
  mkdir -p "$CONFIG_DIR"

  cat > "$PREF_FILE" <<EOF
# User Preferences for Spec-Flow
# Generated by: init-preferences.sh
# Last updated: $(date +%Y-%m-%d)
#
# Documentation: .spec-flow/config/user-preferences-schema.yaml

commands:
  feature:
    default_mode: ${PREFS[feature_default_mode]}
    skip_mode_prompt: ${PREFS[feature_skip_mode_prompt]}

  epic:
    default_mode: ${PREFS[epic_default_mode]}
    skip_mode_prompt: ${PREFS[epic_skip_mode_prompt]}

  tasks:
    default_mode: ${PREFS[tasks_default_mode]}

  init-project:
    default_mode: ${PREFS[init_project_default_mode]}
    include_design: ${PREFS[init_project_include_design]}

  run-prompt:
    default_strategy: ${PREFS[run_prompt_default_strategy]}

automation:
  auto_approve_minor_changes: ${PREFS[auto_approve_minor_changes]}
  ci_mode_default: ${PREFS[ci_mode_default]}

ui:
  show_usage_stats: ${PREFS[show_usage_stats]}
  recommend_last_used: ${PREFS[recommend_last_used]}

worktrees:
  auto_create: ${PREFS[worktrees_auto_create]}
  cleanup_on_finalize: ${PREFS[worktrees_cleanup_on_finalize]}

studio:
  auto_continue: ${PREFS[studio_auto_continue]}
  default_agents: ${PREFS[studio_default_agents]}

prototype:
  git_persistence: ${PREFS[prototype_git_persistence]}

e2e_visual:
  enabled: ${PREFS[e2e_visual_enabled]}
  failure_mode: ${PREFS[e2e_visual_failure_mode]}
  threshold: ${PREFS[e2e_visual_threshold]}
  auto_commit_baselines: ${PREFS[e2e_visual_auto_commit_baselines]}
  viewports:
    - name: desktop
      width: 1280
      height: 720
    - name: mobile
      width: 375
      height: 667

learning:
  enabled: ${PREFS[learning_enabled]}
  auto_apply_low_risk: ${PREFS[learning_auto_apply_low_risk]}
  require_approval_high_risk: ${PREFS[learning_require_approval_high_risk]}
  claude_md_optimization: ${PREFS[learning_claude_md_optimization]}
  thresholds:
    pattern_detection_min_occurrences: 3
    statistical_significance: 0.95

migrations:
  strictness: ${PREFS[migrations_strictness]}
  detection_threshold: 3
  auto_generate_plan: ${PREFS[migrations_auto_generate_plan]}
  llm_analysis_for_low_confidence: true
EOF

  success "Preferences saved to $PREF_FILE"
}

# Main execution
main() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${BOLD}⚙️  SPEC-FLOW PREFERENCES WIZARD${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Initialize defaults
  init_defaults

  # Handle reset
  if [[ "$RESET_PREFS" == true ]]; then
    warning "Resetting preferences to defaults..."
    rm -f "$PREF_FILE"
  else
    # Load existing preferences
    load_existing_prefs
  fi

  # Run wizard sections
  if [[ -z "$SECTION" ]]; then
    # Full wizard (17 core questions)
    configure_commands
    configure_automation
    configure_ui
    configure_worktrees
    configure_studio
    configure_quality
  else
    # Single section
    case "$SECTION" in
      commands) configure_commands ;;
      automation) configure_automation ;;
      ui) configure_ui ;;
      worktrees) configure_worktrees ;;
      studio) configure_studio ;;
      e2e) configure_quality ;;
      learning) configure_learning ;;
      migrations) configure_migrations ;;
      prototype)
        header "PROTOTYPE"
        ask_choice "How to handle prototype in git?" "prototype_git_persistence" \
          "commit" "gitignore" "ask"
        ;;
      *)
        error "Unknown section: $SECTION"
        error "Valid sections: commands, automation, ui, worktrees, studio, e2e, learning, migrations, prototype"
        exit 1
        ;;
    esac
  fi

  # Write preferences
  write_preferences

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${GREEN}✅ PREFERENCES CONFIGURED${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Config file: $PREF_FILE"
  echo ""
  echo "Next steps:"
  echo "  • Preferences apply immediately to all commands"
  echo "  • Re-run /init-preferences anytime to change"
  echo "  • Or edit $PREF_FILE directly"
  echo ""
}

main
