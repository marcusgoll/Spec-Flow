#!/usr/bin/env bash
#
# dependency-graph-parser.sh - Parse epic dependencies from plan.md
#
# Usage: dependency-graph-parser.sh <plan-file> [--format FORMAT]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || cd "$SCRIPT_DIR/../../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parameters
PLAN_FILE=""
OUTPUT_FORMAT="text"  # text, json, yaml, dot

#######################################
# Usage
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") <plan-file> [OPTIONS]

Parse epic dependencies from plan.md and build dependency graph.

Arguments:
  plan-file   Path to plan.md file

Options:
  --format FORMAT  Output format (text, json, yaml, dot) [default: text]
  -h, --help       Show this help

Examples:
  $(basename "$0") specs/002-auth/plan.md
  $(basename "$0") specs/002-auth/plan.md --format json
  $(basename "$0") specs/002-auth/plan.md --format dot > graph.dot
EOF
  exit 1
}

#######################################
# Logging
#######################################
log_info() { echo -e "${BLUE}ℹ${NC}  $*" >&2; }
log_success() { echo -e "${GREEN}✅${NC} $*" >&2; }
log_warning() { echo -e "${YELLOW}⚠${NC}  $*" >&2; }
log_error() { echo -e "${RED}❌${NC} $*" >&2; }

#######################################
# Parse epic breakdown from plan.md
#######################################
parse_epic_breakdown() {
  local plan_file=$1

  if [[ ! -f "$plan_file" ]]; then
    log_error "Plan file not found: $plan_file"
    exit 1
  fi

  # Extract epic breakdown section
  local in_epic_section=false
  local current_epic=""
  declare -A epic_deps  # epic_name -> comma-separated deps

  while IFS= read -r line; do
    # Detect section start
    if [[ "$line" =~ ^##[[:space:]]*Epic[[:space:]]*Breakdown ]]; then
      in_epic_section=true
      continue
    fi

    # Detect section end (next ## heading)
    if [[ "$in_epic_section" == true ]] && [[ "$line" =~ ^##[[:space:]] ]] && [[ ! "$line" =~ Epic[[:space:]]*Breakdown ]]; then
      break
    fi

    if [[ "$in_epic_section" == true ]]; then
      # Parse epic name (### Epic N: Name)
      if [[ "$line" =~ ^###[[:space:]]*(Epic[[:space:]]+[0-9]+):[[:space:]]*(.+)$ ]]; then
        local epic_num="${BASH_REMATCH[1]}"
        local epic_name="${BASH_REMATCH[2]}"
        # Convert to epic identifier (kebab-case with "epic-" prefix)
        current_epic=$(echo "epic-${epic_name}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
        epic_deps["$current_epic"]=""
      fi

      # Parse dependencies line (**Dependencies**: Epic 1, Epic 2)
      if [[ "$line" =~ ^\*\*Dependencies\*\*:[[:space:]]*(.+)$ ]]; then
        local deps_raw="${BASH_REMATCH[1]}"

        # Check for "None"
        if [[ "$deps_raw" =~ None|none|N/A ]]; then
          epic_deps["$current_epic"]=""
          continue
        fi

        # Extract epic numbers (Epic 1, Epic 2, etc.)
        local deps=""
        while [[ "$deps_raw" =~ Epic[[:space:]]+([0-9]+) ]]; do
          local dep_num="${BASH_REMATCH[1]}"

          # Find epic name by number
          local dep_epic=""
          for epic in "${!epic_deps[@]}"; do
            if [[ "$epic" =~ epic-.*-$dep_num$ ]] || [[ "$epic" == *"$dep_num"* ]]; then
              dep_epic="$epic"
              break
            fi
          done

          # If not found yet, try to extract from previous epics
          if [[ -z "$dep_epic" ]]; then
            # Fallback: create placeholder
            dep_epic="epic-unknown-$dep_num"
          fi

          if [[ -n "$deps" ]]; then
            deps="${deps},${dep_epic}"
          else
            deps="$dep_epic"
          fi

          # Remove matched part to continue
          deps_raw="${deps_raw/${BASH_REMATCH[0]}/}"
        done

        if [[ -n "$current_epic" ]]; then
          epic_deps["$current_epic"]="$deps"
        fi
      fi
    fi
  done < "$plan_file"

  # Output dependency graph
  for epic in "${!epic_deps[@]}"; do
    echo "$epic|${epic_deps[$epic]}"
  done
}

#######################################
# Build adjacency list
#######################################
build_adjacency_list() {
  declare -A adj_list

  while IFS='|' read -r epic deps; do
    adj_list["$epic"]="$deps"
  done

  # Print adjacency list
  for epic in "${!adj_list[@]}"; do
    echo "$epic -> ${adj_list[$epic]}"
  done
}

#######################################
# Topological sort (Kahn's algorithm)
#######################################
topological_sort() {
  declare -A in_degree
  declare -A adj_list
  declare -a zero_in_degree
  declare -a sorted

  # Parse input
  while IFS='|' read -r epic deps; do
    adj_list["$epic"]="$deps"
    in_degree["$epic"]=0
  done

  # Calculate in-degrees
  for epic in "${!adj_list[@]}"; do
    local deps="${adj_list[$epic]}"
    if [[ -n "$deps" ]]; then
      IFS=',' read -ra dep_array <<< "$deps"
      for dep in "${dep_array[@]}"; do
        if [[ -n "$dep" ]]; then
          ((in_degree["$epic"]++))
        fi
      done
    fi
  done

  # Find zero in-degree nodes
  for epic in "${!in_degree[@]}"; do
    if [[ ${in_degree[$epic]} -eq 0 ]]; then
      zero_in_degree+=("$epic")
    fi
  done

  # Kahn's algorithm
  while [[ ${#zero_in_degree[@]} -gt 0 ]]; do
    local current="${zero_in_degree[0]}"
    zero_in_degree=("${zero_in_degree[@]:1}")
    sorted+=("$current")

    # Reduce in-degree of neighbors
    for epic in "${!adj_list[@]}"; do
      local deps="${adj_list[$epic]}"
      if [[ "$deps" =~ $current ]]; then
        ((in_degree["$epic"]--))
        if [[ ${in_degree["$epic"]} -eq 0 ]]; then
          zero_in_degree+=("$epic")
        fi
      fi
    done
  done

  # Check for cycles
  if [[ ${#sorted[@]} -ne ${#adj_list[@]} ]]; then
    log_error "Circular dependency detected"
    exit 1
  fi

  # Print sorted order
  for epic in "${sorted[@]}"; do
    echo "$epic"
  done
}

#######################################
# Output format: Text
#######################################
output_text() {
  local graph=$1

  echo ""
  echo "Epic Dependency Graph"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  while IFS='|' read -r epic deps; do
    echo -e "${CYAN}$epic${NC}"
    if [[ -n "$deps" ]]; then
      IFS=',' read -ra dep_array <<< "$deps"
      for dep in "${dep_array[@]}"; do
        if [[ -n "$dep" ]]; then
          echo "  ├─ depends on: $dep"
        fi
      done
    else
      echo "  └─ no dependencies"
    fi
    echo ""
  done

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Execution Order (Topological Sort):"
  echo ""

  local count=1
  echo "$graph" | topological_sort | while read -r epic; do
    echo "  $count. $epic"
    ((count++))
  done

  echo ""
}

#######################################
# Output format: JSON
#######################################
output_json() {
  local graph=$1

  echo "{"
  echo "  \"epics\": ["

  local first=true
  while IFS='|' read -r epic deps; do
    if [[ "$first" == false ]]; then
      echo ","
    fi
    first=false

    echo -n "    {\"name\": \"$epic\", \"dependencies\": ["

    if [[ -n "$deps" ]]; then
      IFS=',' read -ra dep_array <<< "$deps"
      local dep_first=true
      for dep in "${dep_array[@]}"; do
        if [[ -n "$dep" ]]; then
          if [[ "$dep_first" == false ]]; then
            echo -n ", "
          fi
          dep_first=false
          echo -n "\"$dep\""
        fi
      done
    fi

    echo -n "]}"
  done <<< "$graph"

  echo ""
  echo "  ],"
  echo "  \"execution_order\": ["

  first=true
  echo "$graph" | topological_sort | while read -r epic; do
    if [[ "$first" == false ]]; then
      echo ","
    fi
    first=false
    echo -n "    \"$epic\""
  done

  echo ""
  echo "  ]"
  echo "}"
}

#######################################
# Output format: DOT (Graphviz)
#######################################
output_dot() {
  local graph=$1

  echo "digraph epic_dependencies {"
  echo "  rankdir=LR;"
  echo "  node [shape=box, style=rounded];"
  echo ""

  while IFS='|' read -r epic deps; do
    # Sanitize names for DOT
    local epic_clean=$(echo "$epic" | sed 's/-/_/g')

    if [[ -n "$deps" ]]; then
      IFS=',' read -ra dep_array <<< "$deps"
      for dep in "${dep_array[@]}"; do
        if [[ -n "$dep" ]]; then
          local dep_clean=$(echo "$dep" | sed 's/-/_/g')
          echo "  $dep_clean -> $epic_clean;"
        fi
      done
    else
      echo "  $epic_clean;"
    fi
  done <<< "$graph"

  echo "}"
}

#######################################
# Main
#######################################
main() {
  # Parse arguments
  if [[ $# -eq 0 ]]; then
    usage
  fi

  PLAN_FILE="$1"
  shift

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --format)
        OUTPUT_FORMAT="$2"
        shift 2
        ;;
      -h|--help)
        usage
        ;;
      *)
        log_error "Unknown argument: $1"
        usage
        ;;
    esac
  done

  # Parse epic breakdown
  local graph
  graph=$(parse_epic_breakdown "$PLAN_FILE")

  if [[ -z "$graph" ]]; then
    log_warning "No epic breakdown found in $PLAN_FILE"
    echo ""
    echo "Add an Epic Breakdown section to plan.md:"
    echo ""
    echo "## Epic Breakdown"
    echo ""
    echo "### Epic 1: Authentication API"
    echo "**Dependencies**: None"
    echo ""
    echo "### Epic 2: Authentication UI"
    echo "**Dependencies**: Epic 1"
    echo ""
    exit 0
  fi

  # Output in requested format
  case "$OUTPUT_FORMAT" in
    text)
      output_text "$graph"
      ;;
    json)
      output_json "$graph"
      ;;
    dot)
      output_dot "$graph"
      ;;
    *)
      log_error "Unknown format: $OUTPUT_FORMAT"
      echo ""
      echo "Supported formats: text, json, dot"
      echo ""
      exit 1
      ;;
  esac
}

main "$@"
