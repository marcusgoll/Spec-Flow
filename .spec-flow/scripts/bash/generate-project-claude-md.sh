#!/usr/bin/env bash
#
# generate-project-claude-md.sh - Generate project-level CLAUDE.md aggregation
#
# Purpose: Aggregate active features, tech stack, common patterns into single
#          2k-token file (vs 12k tokens for reading 10 separate project docs)
#
# IMPORTANT: This script generates STATUS and CONTEXT aggregation, NOT behavioral
# instructions. Behavioral instructions live in the root CLAUDE.md (human-written).
# This follows the "don't auto-generate instructions" best practice.
#
# Usage:
#   ./generate-project-claude-md.sh [--output PATH]
#
# Options:
#   --output PATH    Output file path (default: docs/project/CLAUDE.md)
#   --json           Output JSON instead of markdown
#   --help           Show this help message
#
# Requirements:
#   - yq >= 4.0 (YAML parsing)
#   - Project docs in docs/project/
#   - Feature specs in specs/*/
#
# Output: CLAUDE.md with aggregated project context

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source common utilities
if [[ -f "$SCRIPT_DIR/common.sh" ]]; then
  source "$SCRIPT_DIR/common.sh"
fi

# Default values
OUTPUT_FILE="$REPO_ROOT/docs/project/CLAUDE.md"
JSON_OUTPUT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    --help)
      sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Check prerequisites
if ! command -v yq &> /dev/null; then
  echo "[spec-flow][error] yq not found. Install with: brew install yq (macOS) or choco install yq (Windows)" >&2
  exit 1
fi

# Function: Find all active features
find_active_features() {
  local features=()

  if [[ ! -d "$REPO_ROOT/specs" ]]; then
    echo "[]"
    return
  fi

  for state_file in "$REPO_ROOT/specs"/*/state.yaml; do
    [[ -f "$state_file" ]] || continue

    local feature_dir
    feature_dir="$(dirname "$state_file")"
    local feature_name
    feature_name="$(basename "$feature_dir")"

    # Extract current phase and status
    local phase
    phase="$(yq eval '.workflow.phase // "unknown"' "$state_file" 2>/dev/null || echo "unknown")"
    local status
    status="$(yq eval '.workflow.status // "unknown"' "$state_file" 2>/dev/null || echo "unknown")"

    # Only include active features (not completed or failed)
    if [[ "$status" != "completed" && "$status" != "failed" ]]; then
      features+=("$feature_name|$phase|$status")
    fi
  done

  printf '%s\n' "${features[@]}" | jq -R -s -c 'split("\n") | map(select(length > 0))'
}

# Function: Extract tech stack summary
extract_tech_stack() {
  local tech_stack_file="$REPO_ROOT/docs/project/tech-stack.md"

  if [[ ! -f "$tech_stack_file" ]]; then
    echo "{}"
    return
  fi

  # Extract key sections (Frontend, Backend, Database, Deployment)
  local frontend
  frontend="$(sed -n '/## Frontend/,/^##/p' "$tech_stack_file" | grep -E '^\*\*' | head -5 | sed 's/^\*\*/  - /; s/\*\*:/:/;' || echo "")"

  local backend
  backend="$(sed -n '/## Backend/,/^##/p' "$tech_stack_file" | grep -E '^\*\*' | head -5 | sed 's/^\*\*/  - /; s/\*\*:/:/;' || echo "")"

  local database
  database="$(sed -n '/## Database/,/^##/p' "$tech_stack_file" | grep -E '^\*\*' | head -3 | sed 's/^\*\*/  - /; s/\*\*:/:/;' || echo "")"

  local deployment
  deployment="$(sed -n '/## Deployment/,/^##/p' "$tech_stack_file" | grep -E '^\*\*' | head -3 | sed 's/^\*\*/  - /; s/\*\*:/:/;' || echo "")"

  jq -n \
    --arg frontend "$frontend" \
    --arg backend "$backend" \
    --arg database "$database" \
    --arg deployment "$deployment" \
    '{frontend: $frontend, backend: $backend, database: $database, deployment: $deployment}'
}

# Function: Extract common patterns from all plan.md files
extract_common_patterns() {
  local patterns=()

  if [[ ! -d "$REPO_ROOT/specs" ]]; then
    echo "[]"
    return
  fi

  for plan_file in "$REPO_ROOT/specs"/*/plan.md; do
    [[ -f "$plan_file" ]] || continue

    # Extract REUSE section patterns
    local in_reuse_section=false
    while IFS= read -r line; do
      if [[ "$line" =~ ^###[[:space:]]*Reuse[[:space:]]*Additions ]]; then
        in_reuse_section=true
        continue
      elif [[ "$line" =~ ^### ]] && [[ "$in_reuse_section" == true ]]; then
        break
      fi

      if [[ "$in_reuse_section" == true ]] && [[ "$line" =~ ^-[[:space:]]*✅[[:space:]]*\*\*(.+)\*\* ]]; then
        local pattern_name="${BASH_REMATCH[1]}"

        # Extract path (next line pattern)
        local path=""
        local pattern='`([^`]+)`'
        if IFS= read -r next_line && [[ "$next_line" =~ $pattern ]]; then
          path="${BASH_REMATCH[1]}"
        fi

        if [[ -n "$pattern_name" ]]; then
          patterns+=("$pattern_name|$path")
        fi
      fi
    done < "$plan_file"
  done

  # Deduplicate patterns by name
  printf '%s\n' "${patterns[@]}" | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))'
}

# Function: Generate markdown output
generate_markdown() {
  local active_features="$1"
  local tech_stack="$2"
  local patterns="$3"

  local timestamp
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%S")"

  cat <<EOF
# Project Context

> **Purpose**: High-level project navigation and context aggregation
> **Token Cost**: ~2,000 tokens (vs 12,000 for reading all project docs)
> **Last Updated**: $timestamp

## Active Features

EOF

  # Parse and display active features
  local feature_count
  feature_count="$(echo "$active_features" | jq 'length')"

  if [[ "$feature_count" -eq 0 ]]; then
    echo "No active features."
  else
    echo "$active_features" | jq -r '.[] | split("|") | "- **\(.[0])**: Phase \(.[1]) (\(.[2]))"'
  fi

  cat <<EOF

## Tech Stack Summary

EOF

  # Display tech stack
  local frontend
  frontend="$(echo "$tech_stack" | jq -r '.frontend // ""')"
  local backend
  backend="$(echo "$tech_stack" | jq -r '.backend // ""')"
  local database
  database="$(echo "$tech_stack" | jq -r '.database // ""')"
  local deployment
  deployment="$(echo "$tech_stack" | jq -r '.deployment // ""')"

  if [[ -n "$frontend" ]]; then
    echo "### Frontend"
    echo "$frontend"
    echo
  fi

  if [[ -n "$backend" ]]; then
    echo "### Backend"
    echo "$backend"
    echo
  fi

  if [[ -n "$database" ]]; then
    echo "### Database"
    echo "$database"
    echo
  fi

  if [[ -n "$deployment" ]]; then
    echo "### Deployment"
    echo "$deployment"
    echo
  fi

  if [[ -z "$frontend" && -z "$backend" && -z "$database" && -z "$deployment" ]]; then
    echo "Tech stack not documented yet. Run \`/init-project\` to generate."
    echo
  fi

  cat <<EOF
## Common Patterns

EOF

  # Parse and display common patterns
  local pattern_count
  pattern_count="$(echo "$patterns" | jq 'length')"

  if [[ "$pattern_count" -eq 0 ]]; then
    echo "No common patterns discovered yet. Patterns are extracted during feature implementation."
  else
    echo "$patterns" | jq -r '.[] | split("|") | "- **\(.[0])** - \`\(.[1])\`"'
  fi

  cat <<EOF

## Quick Links

**Project Documentation**:
- [Overview](docs/project/overview.md) - Vision, users, scope
- [System Architecture](docs/project/system-architecture.md) - C4 diagrams, components
- [Tech Stack](docs/project/tech-stack.md) - Technology choices (full details)
- [Data Architecture](docs/project/data-architecture.md) - ERD, schemas
- [API Strategy](docs/project/api-strategy.md) - REST/GraphQL patterns
- [Capacity Planning](docs/project/capacity-planning.md) - Scaling tiers
- [Deployment Strategy](docs/project/deployment-strategy.md) - CI/CD pipeline
- [Development Workflow](docs/project/development-workflow.md) - Git flow, PR process
- [Engineering Principles](docs/project/engineering-principles.md) - 8 core standards
- [Project Configuration](docs/project/project-configuration.md) - Deployment model, scale tier

**Features**:
EOF

  # List feature CLAUDE.md files
  if [[ -d "$REPO_ROOT/specs" ]]; then
    for feature_dir in "$REPO_ROOT/specs"/*; do
      [[ -d "$feature_dir" ]] || continue

      local feature_name
      feature_name="$(basename "$feature_dir")"
      local claude_file="$feature_dir/CLAUDE.md"

      if [[ -f "$claude_file" ]]; then
        echo "- [$feature_name](specs/$feature_name/CLAUDE.md)"
      fi
    done
  fi

  echo
  echo "---"
  echo
  cat <<'EOF'
<!--
This file aggregates current STATUS and CONTEXT from project artifacts.
It is NOT behavioral instructions - those are in the root CLAUDE.md.
Auto-regenerated by: .spec-flow/scripts/bash/generate-project-claude-md.sh
-->
EOF
  echo
  echo "*Regenerate with:* \`.spec-flow/scripts/bash/generate-project-claude-md.sh\`"
}

# Main execution
main() {
  log_info "Generating project-level CLAUDE.md..."

  # Gather data
  local active_features
  active_features="$(find_active_features)"

  local tech_stack
  tech_stack="$(extract_tech_stack)"

  local patterns
  patterns="$(extract_common_patterns)"

  # Generate output
  if [[ "$JSON_OUTPUT" == true ]]; then
    jq -n \
      --argjson features "$active_features" \
      --argjson tech_stack "$tech_stack" \
      --argjson patterns "$patterns" \
      '{active_features: $features, tech_stack: $tech_stack, common_patterns: $patterns}'
  else
    generate_markdown "$active_features" "$tech_stack" "$patterns" > "$OUTPUT_FILE"

    # Quality gate: warn if output exceeds threshold
    local line_count
    line_count=$(wc -l < "$OUTPUT_FILE" 2>/dev/null || echo "0")
    if [[ "$line_count" -gt 300 ]]; then
      log_warn "Generated CLAUDE.md exceeds 300 lines ($line_count). Consider simplifying."
    elif [[ "$line_count" -gt 150 ]]; then
      log_info "Generated CLAUDE.md has $line_count lines (threshold: 150 warn, 300 max)"
    fi

    log_success "Generated project CLAUDE.md at $OUTPUT_FILE"
  fi
}

main
