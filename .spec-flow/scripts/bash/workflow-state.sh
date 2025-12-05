#!/bin/bash

# workflow-state.sh - Workflow state management functions for Spec-Flow
#
# Provides functions to initialize, update, and query workflow state across
# the entire feature delivery lifecycle. State is stored in state.yaml
# within each feature directory.
#
# Version: 2.1.0 (YAML format + Timing Functions)
# Requires: yq (YAML processor) >= 4.0

set -e

# Check for yq
if ! command -v yq &> /dev/null; then
  echo "Error: yq is required for state management" >&2
  echo "Install instructions:" >&2
  echo "  macOS: brew install yq" >&2
  echo "  Linux: https://github.com/mikefarah/yq#install" >&2
  echo "  Windows: choco install yq" >&2
  exit 1
fi

# Auto-migrate from JSON to YAML if needed
migrate_json_to_yaml_if_needed() {
  local feature_dir="$1"
  local json_file="$feature_dir/workflow-state.json"
  local yaml_file="$feature_dir/state.yaml"

  # If YAML exists, we're good
  if [ -f "$yaml_file" ]; then
    return 0
  fi

  # If JSON exists, migrate it
  if [ -f "$json_file" ]; then
    echo "🔄 Migrating workflow state from JSON to YAML..." >&2
    yq eval -P "$json_file" > "$yaml_file"
    echo "✅ Migration complete: $yaml_file" >&2
    echo "📁 Backup preserved: $json_file" >&2
    return 0
  fi

  # Neither exists - will be created as YAML
  return 1
}

initialize_workflow_state() {
  local feature_dir="$1"
  local slug="$2"
  local title="$3"
  local branch_name="${4:-local}"

  local state_file="$feature_dir/state.yaml"

  # Detect deployment model
  local deployment_model
  deployment_model=$(get_deployment_model)

  # Create initial state in YAML format
  cat > "$state_file" <<EOF
# Spec-Flow Workflow State
# Schema version: 2.1.0
# Created: $(date -u +%Y-%m-%dT%H:%M:%SZ)

feature:
  slug: $slug
  title: $title
  branch_name: $branch_name
  created: $(date -u +%Y-%m-%dT%H:%M:%SZ)
  last_updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
  roadmap_status: in_progress  # Options: backlog, next, in_progress, shipped

deployment_model: $deployment_model  # Options: staging-prod, direct-prod, local-only

workflow:
  phase: spec-flow
  status: in_progress  # Options: in_progress, completed, failed, pending
  completed_phases: []
  failed_phases: []
  manual_gates: {}
  phase_timing: {}
  metrics: {}

context:
  token_budget:
    phase: planning
    budget: 75000
    estimated_usage: 0
    compaction_needed: false

deployment:
  staging:
    deployed: false
    url: null
    deployment_ids: {}
    health_checks: {}
  production:
    deployed: false
    version: null
    url: null
    deployment_ids: {}

artifacts:
  spec: specs/$slug/spec.md
  plan: null
  tasks: null
  optimization_report: null
  staging_validation: null
  ship_report: null

quality_gates: {}

session:
  id: null
  started_at: null
  last_activity: $(date -u +%Y-%m-%dT%H:%M:%SZ)
  phase_at_start: spec-flow
  tasks_at_start: 0
  tasks_completed_this_session: 0
  decisions_made: []
  handoffs: []
  autopilot_enabled: false

metadata:
  schema_version: "2.2.0"
  workflow_version: "2.2.0"
EOF

  echo "✅ Workflow state initialized: $state_file"
}

update_workflow_phase() {
  local feature_dir="$1"
  local phase="$2"
  local status="${3:-completed}"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  # Update timestamp
  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Update workflow phase and status (using --arg to prevent injection)
  yq eval -i --arg phase "$phase" --arg status "$status" --arg ts "$timestamp" \
    '.workflow.phase = $phase | .workflow.status = $status | .feature.last_updated = $ts' \
    "$state_file"

  # Add to completed or failed phases array
  if [ "$status" = "completed" ]; then
    # Check if phase already in completed_phases
    if ! yq eval --arg phase "$phase" '.workflow.completed_phases | contains([$phase])' "$state_file" | grep -q "true"; then
      yq eval -i --arg phase "$phase" '.workflow.completed_phases += [$phase]' "$state_file"
    fi
  elif [ "$status" = "failed" ]; then
    # Check if phase already in failed_phases
    if ! yq eval --arg phase "$phase" '.workflow.failed_phases | contains([$phase])' "$state_file" | grep -q "true"; then
      yq eval -i --arg phase "$phase" '.workflow.failed_phases += [$phase]' "$state_file"
    fi
  fi
}

update_deployment_state() {
  local feature_dir="$1"
  local environment="$2"  # "staging" or "production"
  local commit_sha="$3"
  local run_id="$4"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Update deployment state (using --arg to prevent injection)
  yq eval -i --arg env "$environment" --arg ts "$timestamp" --arg sha "$commit_sha" --arg rid "$run_id" \
    '.deployment.[env].deployed = true | .deployment.[env].timestamp = $ts | .deployment.[env].commit_sha = $sha | .deployment.[env].run_id = $rid | .feature.last_updated = $ts' \
    "$state_file"
}

update_deployment_ids() {
  local feature_dir="$1"
  local environment="$2"
  local marketing_id="$3"
  local app_id="$4"
  local api_image="$5"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  # Update deployment IDs (only if provided, using --arg to prevent injection)
  if [ -n "$marketing_id" ]; then
    yq eval -i --arg env "$environment" --arg mid "$marketing_id" \
      '.deployment.[env].deployment_ids.marketing = $mid' "$state_file"
  fi

  if [ -n "$app_id" ]; then
    yq eval -i --arg env "$environment" --arg aid "$app_id" \
      '.deployment.[env].deployment_ids.app = $aid' "$state_file"
  fi

  if [ -n "$api_image" ]; then
    yq eval -i --arg env "$environment" --arg api "$api_image" \
      '.deployment.[env].deployment_ids.api = $api' "$state_file"
  fi
}

update_quality_gate() {
  local feature_dir="$1"
  local gate_name="$2"
  local passed="$3"  # true or false

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Update quality gate (using --arg to prevent injection)
  # Note: $passed is a boolean (true/false), safe to interpolate directly
  yq eval -i --arg gate "$gate_name" --arg ts "$timestamp" \
    ".quality_gates.[\$gate].passed = $passed | .quality_gates.[\$gate].timestamp = \$ts" \
    "$state_file"
}

update_quality_gate_detailed() {
  local feature_dir="$1"
  local gate_name="$2"
  local gate_data_json="$3"  # JSON string with gate data

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  # Convert JSON to YAML and merge into quality_gates
  echo "$gate_data_json" | yq eval -P - | yq eval ".quality_gates.\"$gate_name\" = $(cat -)" "$state_file" > "$state_file.tmp"
  mv "$state_file.tmp" "$state_file"
}

update_manual_gate() {
  local feature_dir="$1"
  local gate_name="$2"
  local status="$3"  # pending, approved, rejected
  local approved_by="${4:-}"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Update manual gate status (using --arg to prevent injection)
  yq eval -i --arg gate "$gate_name" --arg st "$status" \
    '.workflow.manual_gates.[$gate].status = $st' "$state_file"

  case "$status" in
    pending)
      yq eval -i --arg gate "$gate_name" --arg ts "$timestamp" \
        '.workflow.manual_gates.[$gate].started_at = $ts' "$state_file"
      ;;
    approved)
      yq eval -i --arg gate "$gate_name" --arg ts "$timestamp" \
        '.workflow.manual_gates.[$gate].approved_at = $ts' "$state_file"
      if [ -n "$approved_by" ]; then
        yq eval -i --arg gate "$gate_name" --arg by "$approved_by" \
          '.workflow.manual_gates.[$gate].approved_by = $by' "$state_file"
      fi
      ;;
    rejected)
      yq eval -i --arg gate "$gate_name" --arg ts "$timestamp" \
        '.workflow.manual_gates.[$gate].rejected_at = $ts' "$state_file"
      ;;
  esac
}

get_workflow_state() {
  local feature_dir="$1"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  cat "$state_file"
}

test_phase_completed() {
  local feature_dir="$1"
  local phase="$2"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    return 1
  fi

  # Check if phase is in completed_phases array
  yq eval ".workflow.completed_phases | contains([\"$phase\"])" "$state_file" | grep -q "true"
}

get_next_phase() {
  local feature_dir="$1"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo ""
    return 1
  fi

  local model
  local current_phase
  model=$(yq eval '.deployment_model' "$state_file")
  current_phase=$(yq eval '.workflow.phase' "$state_file")

  # Try to read from phases.yaml config (externalized sequences)
  local phases_config
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
  phases_config="$repo_root/.spec-flow/config/phases.yaml"

  if [ -f "$phases_config" ]; then
    # Read next phase from config using safe yq with --arg
    local next_phase
    next_phase=$(yq eval --arg model "$model" --arg phase "$current_phase" \
      '.models[$model].transitions[$phase] // ""' "$phases_config" 2>/dev/null)

    if [ -n "$next_phase" ]; then
      echo "$next_phase"
      return 0
    fi
  fi

  # Fallback to hardcoded sequences if config not found or lookup failed
  case "$model" in
    staging-prod)
      case "$current_phase" in
        "spec-flow") echo "clarify" ;;
        "clarify") echo "plan" ;;
        "plan") echo "tasks" ;;
        "tasks") echo "analyze" ;;
        "analyze") echo "implement" ;;
        "implement") echo "ship:optimize" ;;
        "ship:optimize") echo "ship:ship-staging" ;;
        "ship:ship-staging") echo "ship:validate-staging" ;;
        "ship:validate-staging") echo "ship:ship-prod" ;;
        "ship:ship-prod") echo "ship:finalize" ;;
        "ship:finalize") echo "" ;;
        *) echo "" ;;
      esac
      ;;
    direct-prod)
      case "$current_phase" in
        "spec-flow") echo "clarify" ;;
        "clarify") echo "plan" ;;
        "plan") echo "tasks" ;;
        "tasks") echo "analyze" ;;
        "analyze") echo "implement" ;;
        "implement") echo "ship:optimize" ;;
        "ship:optimize") echo "ship:deploy-prod" ;;
        "ship:deploy-prod") echo "ship:finalize" ;;
        "ship:finalize") echo "" ;;
        *) echo "" ;;
      esac
      ;;
    local-only)
      case "$current_phase" in
        "spec-flow") echo "clarify" ;;
        "clarify") echo "plan" ;;
        "plan") echo "tasks" ;;
        "tasks") echo "analyze" ;;
        "analyze") echo "implement" ;;
        "implement") echo "ship:optimize" ;;
        "ship:optimize") echo "ship:build-local" ;;
        "ship:build-local") echo "ship:finalize" ;;
        "ship:finalize") echo "" ;;
        *) echo "" ;;
      esac
      ;;
    *)
      echo ""
      ;;
  esac
}

get_deployment_model() {
  # Check constitution.md first
  local constitution_path=".spec-flow/memory/constitution.md"

  if [ -f "$constitution_path" ]; then
    local model
    model=$(grep -E "^Deployment Model:\s*\S+" "$constitution_path" | sed -E 's/.*Deployment Model:\s*(\S+).*/\1/' || echo "")

    if [ -n "$model" ] && [[ "$model" =~ ^(staging-prod|direct-prod|local-only)$ ]]; then
      echo "$model"
      return 0
    fi
  fi

  # Auto-detect
  local has_remote
  local has_staging_branch
  local has_staging_workflow

  has_remote=$(git remote -v 2>/dev/null | grep -q "origin" && echo "true" || echo "false")
  has_staging_branch=$(git show-ref --verify refs/heads/staging 2>/dev/null || git show-ref --verify refs/remotes/origin/staging 2>/dev/null)
  has_staging_workflow=$([ -f ".github/workflows/deploy-staging.yml" ] && echo "true" || echo "false")

  if [ "$has_remote" = "true" ] && [ -n "$has_staging_branch" ] && [ "$has_staging_workflow" = "true" ]; then
    echo "staging-prod"
  elif [ "$has_remote" = "true" ]; then
    echo "direct-prod"
  else
    echo "local-only"
  fi
}

# Export functions (for sourcing)
export -f initialize_workflow_state
export -f update_workflow_phase
export -f update_deployment_state
export -f update_deployment_ids
export -f update_quality_gate
export -f update_quality_gate_detailed
export -f update_manual_gate
export -f get_workflow_state
export -f test_phase_completed
export -f get_next_phase
export -f get_deployment_model

# ============================================================================
# Timing Functions
# ============================================================================

start_phase_timing() {
  local feature_dir="$1"
  local phase="$2"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Initialize phase timing entry (using --arg to prevent injection)
  yq eval -i --arg phase "$phase" --arg ts "$timestamp" \
    '.workflow.phase_timing.[$phase].started_at = $ts | .workflow.phase_timing.[$phase].status = "in_progress" | .feature.last_updated = $ts' \
    "$state_file"
}

complete_phase_timing() {
  local feature_dir="$1"
  local phase="$2"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Get started_at timestamp (using --arg to prevent injection)
  local started_at
  started_at=$(yq eval --arg phase "$phase" '.workflow.phase_timing.[$phase].started_at' "$state_file")

  if [ "$started_at" = "null" ] || [ -z "$started_at" ]; then
    echo "Warning: Phase $phase has no start time, skipping duration calculation" >&2
    yq eval -i --arg phase "$phase" --arg ts "$timestamp" \
      '.workflow.phase_timing.[$phase].completed_at = $ts | .workflow.phase_timing.[$phase].status = "completed"' "$state_file"
    return 0
  fi

  # Calculate duration (cross-platform date parsing)
  local started_epoch completed_epoch duration

  # Try GNU date first (Linux), then BSD date (macOS)
  if date -d "$started_at" +%s &>/dev/null; then
    # GNU date (Linux)
    started_epoch=$(date -d "$started_at" +%s)
    completed_epoch=$(date +%s)
  elif date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started_at" +%s &>/dev/null; then
    # BSD date (macOS)
    started_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started_at" +%s)
    completed_epoch=$(date +%s)
  else
    echo "Warning: Unable to parse date format, skipping duration calculation" >&2
    yq eval -i --arg phase "$phase" --arg ts "$timestamp" \
      '.workflow.phase_timing.[$phase].completed_at = $ts | .workflow.phase_timing.[$phase].status = "completed"' "$state_file"
    return 0
  fi

  duration=$((completed_epoch - started_epoch))

  # Update phase timing (using --arg to prevent injection)
  # Note: $duration is a numeric value, safe to interpolate directly
  yq eval -i --arg phase "$phase" --arg ts "$timestamp" \
    ".workflow.phase_timing.[\$phase].completed_at = \$ts | .workflow.phase_timing.[\$phase].duration_seconds = $duration | .workflow.phase_timing.[\$phase].status = \"completed\" | .feature.last_updated = \$ts" \
    "$state_file"
}

start_sub_phase_timing() {
  local feature_dir="$1"
  local parent_phase="$2"
  local sub_phase="$3"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Initialize sub-phase timing entry (using --arg to prevent injection)
  yq eval -i --arg parent "$parent_phase" --arg sub "$sub_phase" --arg ts "$timestamp" \
    '.workflow.phase_timing.[$parent].sub_phases.[$sub].started_at = $ts' "$state_file"
}

complete_sub_phase_timing() {
  local feature_dir="$1"
  local parent_phase="$2"
  local sub_phase="$3"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Get started_at timestamp (using --arg to prevent injection)
  local started_at
  started_at=$(yq eval --arg parent "$parent_phase" --arg sub "$sub_phase" \
    '.workflow.phase_timing.[$parent].sub_phases.[$sub].started_at' "$state_file")

  if [ "$started_at" = "null" ] || [ -z "$started_at" ]; then
    echo "Warning: Sub-phase $sub_phase has no start time, skipping duration calculation" >&2
    yq eval -i --arg parent "$parent_phase" --arg sub "$sub_phase" --arg ts "$timestamp" \
      '.workflow.phase_timing.[$parent].sub_phases.[$sub].completed_at = $ts' "$state_file"
    return 0
  fi

  # Calculate duration (cross-platform)
  local started_epoch completed_epoch duration

  if date -d "$started_at" +%s &>/dev/null; then
    started_epoch=$(date -d "$started_at" +%s)
    completed_epoch=$(date +%s)
  elif date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started_at" +%s &>/dev/null; then
    started_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started_at" +%s)
    completed_epoch=$(date +%s)
  else
    echo "Warning: Unable to parse date format, skipping duration calculation" >&2
    yq eval -i --arg parent "$parent_phase" --arg sub "$sub_phase" --arg ts "$timestamp" \
      '.workflow.phase_timing.[$parent].sub_phases.[$sub].completed_at = $ts' "$state_file"
    return 0
  fi

  duration=$((completed_epoch - started_epoch))

  # Update sub-phase timing (using --arg to prevent injection)
  # Note: $duration is a numeric value, safe to interpolate directly
  yq eval -i --arg parent "$parent_phase" --arg sub "$sub_phase" --arg ts "$timestamp" \
    ".workflow.phase_timing.[\$parent].sub_phases.[\$sub].completed_at = \$ts | .workflow.phase_timing.[\$parent].sub_phases.[\$sub].duration_seconds = $duration" \
    "$state_file"
}

calculate_workflow_metrics() {
  local feature_dir="$1"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  # Sum all phase durations
  local total_duration
  total_duration=$(yq eval ".workflow.phase_timing.[].duration_seconds" "$state_file" 2>/dev/null | awk '{sum+=$1} END {print sum+0}' || echo "0")

  # Calculate manual wait time
  local manual_wait
  manual_wait=0

  # Iterate through manual gates and calculate wait durations
  local gate_names
  gate_names=$(yq eval '.workflow.manual_gates | keys | .[]' "$state_file" 2>/dev/null)

  if [ -n "$gate_names" ]; then
    for gate in $gate_names; do
      local started_at approved_at
      # Using --arg to prevent injection
      started_at=$(yq eval --arg gate "$gate" '.workflow.manual_gates.[$gate].started_at' "$state_file")
      approved_at=$(yq eval --arg gate "$gate" '.workflow.manual_gates.[$gate].approved_at' "$state_file")

      if [ "$started_at" != "null" ] && [ "$approved_at" != "null" ]; then
        local started_epoch approved_epoch gate_wait

        if date -d "$started_at" +%s &>/dev/null; then
          started_epoch=$(date -d "$started_at" +%s)
          approved_epoch=$(date -d "$approved_at" +%s)
        elif date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started_at" +%s &>/dev/null; then
          started_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started_at" +%s)
          approved_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$approved_at" +%s)
        else
          continue
        fi

        gate_wait=$((approved_epoch - started_epoch))
        manual_wait=$((manual_wait + gate_wait))

        # Store wait duration in gate entry (using --arg to prevent injection)
        # Note: $gate_wait is a numeric value, safe to interpolate directly
        yq eval -i --arg gate "$gate" ".workflow.manual_gates.[\$gate].wait_duration_seconds = $gate_wait" "$state_file"
      fi
    done
  fi

  # Calculate active work time (total - manual waits)
  local active_work
  active_work=$((total_duration - manual_wait))

  # Count phases and gates
  local phases_count gates_count
  phases_count=$(yq eval '.workflow.phase_timing | length' "$state_file")
  gates_count=$(yq eval '.workflow.manual_gates | length' "$state_file" 2>/dev/null || echo 0)

  # Update metrics
  yq eval -i ".workflow.metrics.total_duration_seconds = $total_duration" "$state_file"
  yq eval -i ".workflow.metrics.active_work_seconds = $active_work" "$state_file"
  yq eval -i ".workflow.metrics.manual_wait_seconds = $manual_wait" "$state_file"
  yq eval -i ".workflow.metrics.phases_count = $phases_count" "$state_file"
  yq eval -i ".workflow.metrics.manual_gates_count = $gates_count" "$state_file"
}

format_duration() {
  local seconds=$1

  if [ "$seconds" -lt 60 ]; then
    echo "${seconds}s"
  elif [ "$seconds" -lt 3600 ]; then
    local minutes=$((seconds / 60))
    local secs=$((seconds % 60))
    echo "${minutes}m ${secs}s"
  else
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    echo "${hours}h ${minutes}m"
  fi
}

display_workflow_summary() {
  local feature_dir="$1"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  # Calculate metrics first
  calculate_workflow_metrics "$feature_dir"

  # Extract feature info
  local feature_slug feature_title deployment_model
  feature_slug=$(yq eval '.feature.slug' "$state_file")
  feature_title=$(yq eval '.feature.title' "$state_file")
  deployment_model=$(yq eval '.deployment_model' "$state_file")

  # Extract metrics
  local total_duration active_work manual_wait phases_count gates_count
  total_duration=$(yq eval '.workflow.metrics.total_duration_seconds' "$state_file")
  active_work=$(yq eval '.workflow.metrics.active_work_seconds' "$state_file")
  manual_wait=$(yq eval '.workflow.metrics.manual_wait_seconds' "$state_file")
  phases_count=$(yq eval '.workflow.metrics.phases_count' "$state_file")
  gates_count=$(yq eval '.workflow.metrics.manual_gates_count' "$state_file")

  # Format durations
  local total_fmt active_fmt manual_fmt
  total_fmt=$(format_duration "$total_duration")
  active_fmt=$(format_duration "$active_work")
  manual_fmt=$(format_duration "$manual_wait")

  # Extract deployment info
  local prod_url prod_version
  prod_url=$(yq eval '.deployment.production.url' "$state_file")
  prod_version=$(yq eval '.deployment.production.version' "$state_file")

  # Display summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Feature Workflow Complete: $feature_title"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "📊 Workflow Timing Summary"
  echo ""
  echo "Total Duration:        $total_fmt ($total_duration seconds)"
  echo "Active Work:           $active_fmt ($active_work seconds)"
  if [ "$manual_wait" -gt 0 ]; then
    echo "Manual Waiting:        $manual_fmt ($manual_wait seconds)"
  fi
  echo ""
  echo "Phase Breakdown:"
  echo "┌────────────────────────────┬──────────────────┬─────────────┬──────────┐"
  echo "│ Phase                      │ Started (UTC)    │ Duration    │ Status   │"
  echo "├────────────────────────────┼──────────────────┼─────────────┼──────────┤"

  # Get all phases
  local phase_names
  phase_names=$(yq eval '.workflow.phase_timing | keys | .[]' "$state_file" 2>/dev/null)

  if [ -n "$phase_names" ]; then
    for phase in $phase_names; do
      local started_at duration status
      started_at=$(yq eval ".workflow.phase_timing.\"$phase\".started_at" "$state_file")
      duration=$(yq eval ".workflow.phase_timing.\"$phase\".duration_seconds" "$state_file")
      status=$(yq eval ".workflow.phase_timing.\"$phase\".status" "$state_file")

      # Format time
      local time_part
      time_part=$(echo "$started_at" | cut -d'T' -f2 | cut -d'Z' -f1)

      # Format duration
      local duration_fmt
      if [ "$duration" != "null" ]; then
        duration_fmt=$(format_duration "$duration")
      else
        duration_fmt="—"
      fi

      # Status icon
      local status_icon
      case "$status" in
        completed) status_icon="✅" ;;
        in_progress) status_icon="🔄" ;;
        failed) status_icon="❌" ;;
        *) status_icon="—" ;;
      esac

      printf "│ %-26s │ %-16s │ %-11s │ %-8s │\n" "$phase" "$time_part" "$duration_fmt" "$status_icon"

      # Display sub-phases if present
      local sub_phase_names
      sub_phase_names=$(yq eval ".workflow.phase_timing.\"$phase\".sub_phases | keys | .[]" "$state_file" 2>/dev/null)

      if [ -n "$sub_phase_names" ]; then
        for sub_phase in $sub_phase_names; do
          local sub_duration
          sub_duration=$(yq eval ".workflow.phase_timing.\"$phase\".sub_phases.\"$sub_phase\".duration_seconds" "$state_file")

          if [ "$sub_duration" != "null" ]; then
            local sub_duration_fmt
            sub_duration_fmt=$(format_duration "$sub_duration")
            printf "│   ├─ %-22s │                  │ %-11s │          │\n" "$sub_phase" "$sub_duration_fmt"
          fi
        done
      fi
    done
  fi

  # Display manual gates
  local gate_names
  gate_names=$(yq eval '.workflow.manual_gates | keys | .[]' "$state_file" 2>/dev/null)

  if [ -n "$gate_names" ]; then
    for gate in $gate_names; do
      local gate_status wait_duration started_at
      gate_status=$(yq eval ".workflow.manual_gates.\"$gate\".status" "$state_file")
      wait_duration=$(yq eval ".workflow.manual_gates.\"$gate\".wait_duration_seconds" "$state_file")
      started_at=$(yq eval ".workflow.manual_gates.\"$gate\".started_at" "$state_file")

      local time_part
      time_part=$(echo "$started_at" | cut -d'T' -f2 | cut -d'Z' -f1)

      local wait_fmt
      if [ "$wait_duration" != "null" ]; then
        wait_fmt=$(format_duration "$wait_duration")
      else
        wait_fmt="—"
      fi

      local status_icon
      case "$gate_status" in
        approved) status_icon="✅" ;;
        pending) status_icon="⏳" ;;
        rejected) status_icon="❌" ;;
        *) status_icon="—" ;;
      esac

      printf "│ [Manual Gate: %-12s │ %-16s │ %-11s │ %-8s │\n" "$gate]" "$time_part" "$wait_fmt" "$status_icon"
    done
  fi

  echo "└────────────────────────────┴──────────────────┴─────────────┴──────────┘"
  echo ""
  echo "Deployment Model: $deployment_model"

  if [ "$prod_url" != "null" ] && [ -n "$prod_url" ]; then
    echo "Production URL: $prod_url"
  fi

  if [ "$prod_version" != "null" ] && [ -n "$prod_version" ]; then
    echo "Version: $prod_version"
  fi

  echo ""
  echo "For detailed metrics: cat $state_file"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# ============================================================================
# Session Management Functions
# ============================================================================

start_session() {
  local feature_dir="$1"
  local session_id="${2:-session-$(date +%Y%m%d-%H%M%S)}"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Get current phase and task count
  local current_phase tasks_count
  current_phase=$(yq eval '.workflow.phase' "$state_file")

  # Count tasks if tasks.md exists
  local tasks_file="$feature_dir/tasks.md"
  if [ -f "$tasks_file" ]; then
    tasks_count=$(grep -c '^\- \[' "$tasks_file" 2>/dev/null || echo "0")
  else
    tasks_count=0
  fi

  # Update session info
  yq eval -i --arg sid "$session_id" --arg ts "$timestamp" --arg phase "$current_phase" \
    '.session.id = $sid | .session.started_at = $ts | .session.last_activity = $ts | .session.phase_at_start = $phase | .session.tasks_completed_this_session = 0' \
    "$state_file"

  # Note: tasks_count is numeric, safe to interpolate
  yq eval -i ".session.tasks_at_start = $tasks_count" "$state_file"

  echo "Session started: $session_id"
}

end_session() {
  local feature_dir="$1"
  local session_summary="${2:-}"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Get session info
  local session_id started_at
  session_id=$(yq eval '.session.id' "$state_file")
  started_at=$(yq eval '.session.started_at' "$state_file")

  # Calculate session duration if we have start time
  if [ "$started_at" != "null" ] && [ -n "$started_at" ]; then
    local started_epoch ended_epoch duration

    if date -d "$started_at" +%s &>/dev/null; then
      started_epoch=$(date -d "$started_at" +%s)
      ended_epoch=$(date +%s)
    elif date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started_at" +%s &>/dev/null; then
      started_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started_at" +%s)
      ended_epoch=$(date +%s)
    else
      duration=0
    fi

    if [ -z "$duration" ]; then
      duration=$((ended_epoch - started_epoch))
    fi

    # Update with duration
    yq eval -i --arg ts "$timestamp" ".session.ended_at = \$ts | .session.duration_seconds = $duration" "$state_file"
  else
    yq eval -i --arg ts "$timestamp" '.session.ended_at = $ts' "$state_file"
  fi

  # Add summary if provided
  if [ -n "$session_summary" ]; then
    yq eval -i --arg summary "$session_summary" '.session.summary = $summary' "$state_file"
  fi

  echo "Session ended: $session_id"
}

update_session_activity() {
  local feature_dir="$1"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    return 1
  fi

  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  yq eval -i --arg ts "$timestamp" '.session.last_activity = $ts' "$state_file"
}

record_session_decision() {
  local feature_dir="$1"
  local decision="$2"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  # Add decision to array
  yq eval -i --arg dec "$decision" '.session.decisions_made += [$dec]' "$state_file"
}

increment_session_tasks() {
  local feature_dir="$1"
  local count="${2:-1}"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    return 1
  fi

  # Increment tasks completed this session
  local current
  current=$(yq eval '.session.tasks_completed_this_session' "$state_file")
  current=${current:-0}

  local new_count=$((current + count))
  yq eval -i ".session.tasks_completed_this_session = $new_count" "$state_file"
}

record_session_handoff() {
  local feature_dir="$1"
  local handoff_id="$2"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Add handoff to array with timestamp
  yq eval -i --arg hid "$handoff_id" --arg ts "$timestamp" \
    '.session.handoffs += [{"id": $hid, "at": $ts}]' "$state_file"

  # Also update last handoff fields
  yq eval -i --arg hid "$handoff_id" --arg ts "$timestamp" \
    '.session.last_handoff_id = $hid | .session.last_handoff_at = $ts' "$state_file"
}

enable_autopilot() {
  local feature_dir="$1"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    return 1
  fi

  yq eval -i '.session.autopilot_enabled = true' "$state_file"
  echo "Autopilot mode enabled for current workflow"
}

disable_autopilot() {
  local feature_dir="$1"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    return 1
  fi

  yq eval -i '.session.autopilot_enabled = false' "$state_file"
  echo "Autopilot mode disabled"
}

get_session_summary() {
  local feature_dir="$1"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "No workflow state found"
    return 1
  fi

  # Extract session info
  local session_id started_at last_activity phase_at_start tasks_completed decisions_count
  session_id=$(yq eval '.session.id // "none"' "$state_file")
  started_at=$(yq eval '.session.started_at // "N/A"' "$state_file")
  last_activity=$(yq eval '.session.last_activity // "N/A"' "$state_file")
  phase_at_start=$(yq eval '.session.phase_at_start // "N/A"' "$state_file")
  tasks_completed=$(yq eval '.session.tasks_completed_this_session // 0' "$state_file")
  decisions_count=$(yq eval '.session.decisions_made | length' "$state_file" 2>/dev/null || echo "0")

  echo ""
  echo "Session Summary"
  echo "==============="
  echo "ID:              $session_id"
  echo "Started:         $started_at"
  echo "Last Activity:   $last_activity"
  echo "Phase at Start:  $phase_at_start"
  echo "Tasks Completed: $tasks_completed"
  echo "Decisions Made:  $decisions_count"
  echo ""
}

# Export new timing functions
export -f start_phase_timing
export -f complete_phase_timing
export -f start_sub_phase_timing
export -f complete_sub_phase_timing
export -f calculate_workflow_metrics
export -f format_duration
export -f display_workflow_summary

# Export session management functions
export -f start_session
export -f end_session
export -f update_session_activity
export -f record_session_decision
export -f increment_session_tasks
export -f record_session_handoff
export -f enable_autopilot
export -f disable_autopilot
export -f get_session_summary
