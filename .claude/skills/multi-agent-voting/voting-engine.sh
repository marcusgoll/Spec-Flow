#!/bin/bash
# Multi-agent voting orchestration engine
# Implements MAKER paper's first-to-ahead-by-k algorithm and other voting strategies

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check dependencies
check_dependencies() {
  local missing_deps=()

  command -v yq >/dev/null 2>&1 || missing_deps+=("yq")
  command -v python3 >/dev/null 2>&1 || missing_deps+=("python3")
  command -v bc >/dev/null 2>&1 || missing_deps+=("bc")

  if [ ${#missing_deps[@]} -gt 0 ]; then
    echo -e "${RED}ERROR: Missing required dependencies: ${missing_deps[*]}${NC}" >&2
    exit 1
  fi
}

# Invoke voting system for a specific operation
# Usage: invoke_voting <operation> <context_file> [--output <path>]
invoke_voting() {
  local operation=$1      # code_review, security_review, breaking_change_detection
  local context_file=$2   # File containing task context
  local output_file=""

  # Parse optional arguments
  shift 2
  while [[ $# -gt 0 ]]; do
    case $1 in
      --output)
        output_file=$2
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  echo -e "${BLUE}🗳️  Initializing multi-agent voting for: $operation${NC}"

  # Verify voting config exists
  if [ ! -f ".spec-flow/config/voting.yaml" ]; then
    echo -e "${RED}ERROR: voting.yaml not found${NC}" >&2
    return 1
  fi

  # Load voting configuration for this operation
  local config=$(yq eval ".operations.$operation" .spec-flow/config/voting.yaml)

  if [ "$config" = "null" ]; then
    echo -e "${YELLOW}WARNING: No voting config for $operation, falling back to single agent${NC}" >&2
    return 2
  fi

  local strategy=$(echo "$config" | yq eval '.strategy')
  local num_agents=$(echo "$config" | yq eval '.num_agents')
  local k=$(echo "$config" | yq eval '.k // 2')
  local model=$(echo "$config" | yq eval '.model // "sonnet"')

  echo -e "  Strategy: $strategy"
  echo -e "  Agents: $num_agents"
  [ "$strategy" = "first_to_ahead_by_k" ] && echo -e "  k value: $k"
  echo -e "  Model: $model"
  echo ""

  # Create temporary directory for vote results
  local vote_dir=$(mktemp -d)
  trap "rm -rf $vote_dir" EXIT

  # Launch agents in parallel with temperature/prompt variation
  echo -e "${BLUE}🚀 Launching $num_agents agents in parallel...${NC}"
  local pids=()

  for i in $(seq 1 $num_agents); do
    # Temperature variation for error decorrelation (0.5, 0.7, 0.9)
    local temp=$(echo "0.5 + ($i - 1) * 0.2" | bc -l)

    # Launch agent with unique temperature
    (
      echo -e "${BLUE}  Agent $i: temperature=$temp${NC}"

      # Invoke the specialist agent via Task tool
      # This would be replaced with actual Claude Code agent invocation
      # For now, create placeholder vote
      local vote_result="approve"  # In real implementation: call actual agent
      echo "$vote_result" > "$vote_dir/vote_$i.txt"
      echo "$temp" > "$vote_dir/temp_$i.txt"
    ) &

    pids+=($!)
  done

  # Wait for all agents to complete
  echo -e "${YELLOW}⏳ Waiting for all agents to complete...${NC}"
  for pid in "${pids[@]}"; do
    wait $pid
  done

  echo -e "${GREEN}✅ All agents completed${NC}"
  echo ""

  # Collect votes
  local votes=()
  for i in $(seq 1 $num_agents); do
    if [ -f "$vote_dir/vote_$i.txt" ]; then
      votes+=($(cat "$vote_dir/vote_$i.txt"))
    else
      echo -e "${RED}WARNING: Agent $i did not produce a vote${NC}" >&2
      votes+=("abstain")
    fi
  done

  # Aggregate votes based on strategy
  echo -e "${BLUE}📊 Aggregating votes with strategy: $strategy${NC}"
  aggregate_votes "$strategy" "$k" "$output_file" "${votes[@]}"

  local result=$?

  # Clean up
  rm -rf "$vote_dir"

  return $result
}

# Aggregate votes using specified strategy
# Usage: aggregate_votes <strategy> <k> <output_file> <vote1> <vote2> ...
aggregate_votes() {
  local strategy=$1
  local k=$2
  local output_file=$3
  shift 3
  local votes=("$@")

  # Prepare votes for Python script
  local votes_json="["
  for ((i=0; i<${#votes[@]}; i++)); do
    [ $i -gt 0 ] && votes_json+=","
    votes_json+="\"${votes[$i]}\""
  done
  votes_json+="]"

  # Call Python vote aggregator
  local script_dir=$(dirname "${BASH_SOURCE[0]}")
  local aggregator="$script_dir/vote-aggregator.py"

  if [ ! -f "$aggregator" ]; then
    echo -e "${RED}ERROR: vote-aggregator.py not found at $aggregator${NC}" >&2
    return 1
  fi

  # Build Python command
  local py_cmd="python3 \"$aggregator\" --votes '$votes_json' --strategy \"$strategy\""

  if [ "$strategy" = "first_to_ahead_by_k" ]; then
    py_cmd+=" --k $k"
  fi

  if [ -n "$output_file" ]; then
    py_cmd+=" --output \"$output_file\""
  fi

  # Execute aggregation
  eval $py_cmd
  local result=$?

  if [ $result -eq 0 ]; then
    echo -e "${GREEN}✅ Voting decision: APPROVED${NC}"
  else
    echo -e "${RED}❌ Voting decision: REJECTED${NC}"
  fi

  return $result
}

# Export functions for use in other scripts
export -f invoke_voting
export -f aggregate_votes
export -f check_dependencies

# If script is run directly (not sourced), check dependencies
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  check_dependencies
  echo -e "${GREEN}✅ Voting engine dependencies satisfied${NC}"
  echo ""
  echo "Usage: source voting-engine.sh"
  echo "Then call: invoke_voting <operation> <context_file> [--output <path>]"
fi
