#!/bin/bash

# workflow-state.sh - Workflow state management functions for Spec-Flow
#
# Provides functions to initialize, update, and query workflow state across
# the entire feature delivery lifecycle. State is stored in workflow-state.yaml
# within each feature directory.
#
# Version: 2.0.0 (YAML format)
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
  local yaml_file="$feature_dir/workflow-state.yaml"

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

  local state_file="$feature_dir/workflow-state.yaml"

  # Detect deployment model
  local deployment_model
  deployment_model=$(get_deployment_model)

  # Create initial state in YAML format
  cat > "$state_file" <<EOF
# Spec-Flow Workflow State
# Schema version: 2.0.0
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

metadata:
  schema_version: "2.0.0"
  workflow_version: "2.0.0"
EOF

  echo "✅ Workflow state initialized: $state_file"
}

update_workflow_phase() {
  local feature_dir="$1"
  local phase="$2"
  local status="${3:-completed}"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/workflow-state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  # Update timestamp
  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Update workflow phase and status
  yq eval -i ".workflow.phase = \"$phase\"" "$state_file"
  yq eval -i ".workflow.status = \"$status\"" "$state_file"
  yq eval -i ".feature.last_updated = \"$timestamp\"" "$state_file"

  # Add to completed or failed phases array
  if [ "$status" = "completed" ]; then
    # Check if phase already in completed_phases
    if ! yq eval ".workflow.completed_phases | contains([\"$phase\"])" "$state_file" | grep -q "true"; then
      yq eval -i ".workflow.completed_phases += [\"$phase\"]" "$state_file"
    fi
  elif [ "$status" = "failed" ]; then
    # Check if phase already in failed_phases
    if ! yq eval ".workflow.failed_phases | contains([\"$phase\"])" "$state_file" | grep -q "true"; then
      yq eval -i ".workflow.failed_phases += [\"$phase\"]" "$state_file"
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

  local state_file="$feature_dir/workflow-state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Update deployment state
  yq eval -i ".deployment.$environment.deployed = true" "$state_file"
  yq eval -i ".deployment.$environment.timestamp = \"$timestamp\"" "$state_file"
  yq eval -i ".deployment.$environment.commit_sha = \"$commit_sha\"" "$state_file"
  yq eval -i ".deployment.$environment.run_id = \"$run_id\"" "$state_file"
  yq eval -i ".feature.last_updated = \"$timestamp\"" "$state_file"
}

update_deployment_ids() {
  local feature_dir="$1"
  local environment="$2"
  local marketing_id="$3"
  local app_id="$4"
  local api_image="$5"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/workflow-state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  # Update deployment IDs (only if provided)
  if [ -n "$marketing_id" ]; then
    yq eval -i ".deployment.$environment.deployment_ids.marketing = \"$marketing_id\"" "$state_file"
  fi

  if [ -n "$app_id" ]; then
    yq eval -i ".deployment.$environment.deployment_ids.app = \"$app_id\"" "$state_file"
  fi

  if [ -n "$api_image" ]; then
    yq eval -i ".deployment.$environment.deployment_ids.api = \"$api_image\"" "$state_file"
  fi
}

update_quality_gate() {
  local feature_dir="$1"
  local gate_name="$2"
  local passed="$3"  # true or false

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/workflow-state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Update quality gate
  yq eval -i ".quality_gates.\"$gate_name\".passed = $passed" "$state_file"
  yq eval -i ".quality_gates.\"$gate_name\".timestamp = \"$timestamp\"" "$state_file"
}

update_quality_gate_detailed() {
  local feature_dir="$1"
  local gate_name="$2"
  local gate_data_json="$3"  # JSON string with gate data

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/workflow-state.yaml"

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

  local state_file="$feature_dir/workflow-state.yaml"

  if [ ! -f "$state_file" ]; then
    echo "Error: Workflow state not found: $state_file" >&2
    return 1
  fi

  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Update manual gate status
  yq eval -i ".workflow.manual_gates.\"$gate_name\".status = \"$status\"" "$state_file"

  case "$status" in
    pending)
      yq eval -i ".workflow.manual_gates.\"$gate_name\".started_at = \"$timestamp\"" "$state_file"
      ;;
    approved)
      yq eval -i ".workflow.manual_gates.\"$gate_name\".approved_at = \"$timestamp\"" "$state_file"
      if [ -n "$approved_by" ]; then
        yq eval -i ".workflow.manual_gates.\"$gate_name\".approved_by = \"$approved_by\"" "$state_file"
      fi
      ;;
    rejected)
      yq eval -i ".workflow.manual_gates.\"$gate_name\".rejected_at = \"$timestamp\"" "$state_file"
      ;;
  esac
}

get_workflow_state() {
  local feature_dir="$1"

  # Auto-migrate if needed
  migrate_json_to_yaml_if_needed "$feature_dir"

  local state_file="$feature_dir/workflow-state.yaml"

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

  local state_file="$feature_dir/workflow-state.yaml"

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

  local state_file="$feature_dir/workflow-state.yaml"

  if [ ! -f "$state_file" ]; then
    echo ""
    return 1
  fi

  local model
  local current_phase
  model=$(yq eval '.deployment_model' "$state_file")
  current_phase=$(yq eval '.workflow.phase' "$state_file")

  # Define sequences based on deployment model
  case "$model" in
    staging-prod)
      case "$current_phase" in
        "spec-flow") echo "clarify" ;;
        "clarify") echo "plan" ;;
        "plan") echo "tasks" ;;
        "tasks") echo "analyze" ;;
        "analyze") echo "implement" ;;
        "implement") echo "ship:optimize" ;;
        "ship:optimize") echo "ship:preview" ;;
        "ship:preview") echo "ship:phase-1-ship" ;;
        "ship:phase-1-ship") echo "ship:validate-staging" ;;
        "ship:validate-staging") echo "ship:phase-2-ship" ;;
        "ship:phase-2-ship") echo "ship:finalize" ;;
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
        "ship:optimize") echo "ship:preview" ;;
        "ship:preview") echo "ship:deploy-prod" ;;
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
        "ship:optimize") echo "ship:preview" ;;
        "ship:preview") echo "ship:build-local" ;;
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
