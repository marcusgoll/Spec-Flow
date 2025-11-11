#!/usr/bin/env bash
#
# fixture-refresh.sh - Regenerate golden JSON fixtures from schemas
#
# Usage: fixture-refresh.sh [--verify] [--path contracts/api/vX.Y.Z]
#
# Required tools: jq or yq

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CONTRACTS_DIR="$PROJECT_ROOT/contracts"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Flags
VERIFY=false
TARGET_PATH=""
GENERATED_COUNT=0

#######################################
# Print usage
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Regenerate golden JSON fixtures from OpenAPI and JSON Schema contracts.

Options:
  --verify          Run CDC verification after regeneration
  --path PATH       Regenerate fixtures for specific version only
  -h, --help        Show this help message

Examples:
  $(basename "$0")
  $(basename "$0") --path contracts/api/v1.2.0
  $(basename "$0") --verify
EOF
  exit 1
}

#######################################
# Logging
#######################################
log_info() { echo -e "${BLUE}ℹ${NC}  $*"; }
log_success() { echo -e "${GREEN}✅${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC}  $*"; }
log_error() { echo -e "${RED}❌${NC} $*"; }

#######################################
# Discover contract versions
#######################################
discover_versions() {
  if [[ -n "$TARGET_PATH" ]]; then
    if [[ -d "$TARGET_PATH" ]]; then
      echo "$TARGET_PATH"
    fi
    return
  fi

  find "$CONTRACTS_DIR/api" -maxdepth 1 -type d -name 'v*' 2>/dev/null | sort -V || true
}

#######################################
# Get example value for JSON Schema type/format
#######################################
get_example_value() {
  local type=$1
  local format=${2:-}
  local prop_name=${3:-}

  case "$type:$format" in
    string:email)
      echo "\"user@example.com\""
      ;;
    string:uuid)
      echo "\"123e4567-e89b-12d3-a456-426614174000\""
      ;;
    string:date-time)
      echo "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
      ;;
    string:uri)
      echo "\"https://example.com\""
      ;;
    string:password)
      echo "\"securePassword123!\""
      ;;
    integer:*)
      echo "42"
      ;;
    number:*)
      echo "3.14"
      ;;
    boolean:*)
      echo "true"
      ;;
    string:*)
      # Use property name as hint
      if [[ "$prop_name" == *"id"* ]]; then
        echo "\"123\""
      elif [[ "$prop_name" == *"slug"* ]]; then
        echo "\"example-slug\""
      elif [[ "$prop_name" == *"url"* ]]; then
        echo "\"https://example.com\""
      else
        echo "\"example-string\""
      fi
      ;;
    *)
      echo "\"example-value\""
      ;;
  esac
}

#######################################
# Generate fixture from OpenAPI schema
#######################################
generate_fixture_from_schema() {
  local schema_name=$1
  local openapi_file=$2

  # Try to extract example first
  local example
  if command -v yq &> /dev/null; then
    example=$(yq eval ".components.schemas.${schema_name}.example" "$openapi_file" 2>/dev/null || echo "null")
  else
    example=$(jq -r ".components.schemas.${schema_name}.example // null" <(yq eval -j '.' "$openapi_file" 2>/dev/null || echo '{}'))
  fi

  if [[ "$example" != "null" ]] && [[ -n "$example" ]]; then
    echo "$example"
    return
  fi

  # Generate from properties
  generate_from_properties "$schema_name" "$openapi_file"
}

#######################################
# Generate fixture from schema properties
#######################################
generate_from_properties() {
  local schema_name=$1
  local openapi_file=$2

  local fixture="{"
  local first=true

  # Get properties
  local properties
  if command -v yq &> /dev/null; then
    properties=$(yq eval ".components.schemas.${schema_name}.properties | keys" "$openapi_file" 2>/dev/null | grep -v '^$' || echo "")
  else
    properties=$(jq -r ".components.schemas.${schema_name}.properties | keys[]" <(yq eval -j '.' "$openapi_file" 2>/dev/null || echo '{}') 2>/dev/null || echo "")
  fi

  if [[ -z "$properties" ]]; then
    echo "{}"
    return
  fi

  while IFS= read -r prop; do
    [[ -z "$prop" ]] && continue
    [[ "$prop" == "---" ]] && continue
    [[ "$prop" == "null" ]] && continue

    # Clean property name (remove leading dash and spaces)
    prop=$(echo "$prop" | sed 's/^[- ]*//')

    # Get property type and format
    local prop_type
    local prop_format
    if command -v yq &> /dev/null; then
      prop_type=$(yq eval ".components.schemas.${schema_name}.properties.${prop}.type" "$openapi_file" 2>/dev/null || echo "string")
      prop_format=$(yq eval ".components.schemas.${schema_name}.properties.${prop}.format" "$openapi_file" 2>/dev/null || echo "")

      # Check for inline example
      local prop_example
      prop_example=$(yq eval ".components.schemas.${schema_name}.properties.${prop}.example" "$openapi_file" 2>/dev/null || echo "null")

      if [[ "$prop_example" != "null" ]]; then
        if [[ "$first" == false ]]; then
          fixture+=","
        fi
        fixture+="\"$prop\": $prop_example"
        first=false
        continue
      fi
    else
      prop_type="string"
      prop_format=""
    fi

    # Generate value
    local value
    value=$(get_example_value "$prop_type" "$prop_format" "$prop")

    # Add to fixture
    if [[ "$first" == false ]]; then
      fixture+=","
    fi
    fixture+="\"$prop\": $value"
    first=false
  done <<< "$properties"

  fixture+="}"

  echo "$fixture" | jq '.' 2>/dev/null || echo "$fixture"
}

#######################################
# Process OpenAPI paths and generate fixtures
#######################################
process_openapi_paths() {
  local openapi_file=$1
  local examples_dir=$2

  # Create examples directory
  mkdir -p "$examples_dir"

  # Get all paths and operations
  local paths
  if command -v yq &> /dev/null; then
    paths=$(yq eval '.paths | keys' "$openapi_file" 2>/dev/null | grep -v '^---$' | grep -v '^$' || echo "")
  else
    log_warning "yq not found - limited fixture generation"
    return
  fi

  [[ -z "$paths" ]] && return

  # Process each path
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    [[ "$path" == "---" ]] && continue
    [[ "$path" == "null" ]] && continue

    # Clean path
    path=$(echo "$path" | sed 's/^[- ]*//')

    # Get operations for path (get, post, put, delete, etc.)
    local operations
    operations=$(yq eval ".paths.\"${path}\" | keys" "$openapi_file" 2>/dev/null | grep -v '^---$' | grep -v '^$' || echo "")

    [[ -z "$operations" ]] && continue

    while IFS= read -r operation; do
      [[ -z "$operation" ]] && continue
      [[ "$operation" == "---" ]] && continue
      [[ "$operation" == "null" ]] && continue

      operation=$(echo "$operation" | sed 's/^[- ]*//')

      # Generate fixture name from path and operation
      local fixture_base
      fixture_base=$(echo "$path" | sed 's/\///g' | sed 's/{[^}]*}//g' | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/^-*//' | sed 's/-*$//')

      # Request body fixture
      local request_schema
      request_schema=$(yq eval ".paths.\"${path}\".${operation}.requestBody.content.\"application/json\".schema.\"\$ref\"" "$openapi_file" 2>/dev/null || echo "null")

      if [[ "$request_schema" != "null" ]] && [[ -n "$request_schema" ]]; then
        # Extract schema name from $ref
        local schema_name
        schema_name=$(echo "$request_schema" | sed 's|#/components/schemas/||')

        local fixture_file="${examples_dir}/${fixture_base}-${operation}-request.json"
        local fixture_content
        fixture_content=$(generate_fixture_from_schema "$schema_name" "$openapi_file")

        echo "$fixture_content" | jq '.' > "$fixture_file" 2>/dev/null || echo "$fixture_content" > "$fixture_file"
        log_success "Generated $(basename "$fixture_file")"
        ((GENERATED_COUNT++))
      fi

      # Response fixtures
      local responses
      responses=$(yq eval ".paths.\"${path}\".${operation}.responses | keys" "$openapi_file" 2>/dev/null | grep -v '^---$' | grep -v '^$' || echo "")

      while IFS= read -r status; do
        [[ -z "$status" ]] && continue
        [[ "$status" == "---" ]] && continue
        [[ "$status" == "null" ]] && continue

        status=$(echo "$status" | sed 's/^[- ]*//')

        local response_schema
        response_schema=$(yq eval ".paths.\"${path}\".${operation}.responses.\"${status}\".content.\"application/json\".schema.\"\$ref\"" "$openapi_file" 2>/dev/null || echo "null")

        if [[ "$response_schema" != "null" ]] && [[ -n "$response_schema" ]]; then
          local schema_name
          schema_name=$(echo "$response_schema" | sed 's|#/components/schemas/||')

          local fixture_file="${examples_dir}/${fixture_base}-${operation}-response.json"
          local fixture_content
          fixture_content=$(generate_fixture_from_schema "$schema_name" "$openapi_file")

          echo "$fixture_content" | jq '.' > "$fixture_file" 2>/dev/null || echo "$fixture_content" > "$fixture_file"
          log_success "Generated $(basename "$fixture_file")"
          ((GENERATED_COUNT++))
        fi
      done <<< "$responses"
    done <<< "$operations"
  done <<< "$paths"
}

#######################################
# Process single version
#######################################
process_version() {
  local version_dir=$1

  local version
  version=$(basename "$version_dir")

  log_info "Processing $version..."

  local openapi_file="$version_dir/openapi.yaml"

  if [[ ! -f "$openapi_file" ]]; then
    log_warning "No openapi.yaml found in $version_dir - skipping"
    return
  fi

  local examples_dir="$version_dir/examples"

  process_openapi_paths "$openapi_file" "$examples_dir"
}

#######################################
# Run CDC verification
#######################################
run_verification() {
  log_info "Running CDC verification with new fixtures..."

  local verify_script="$SCRIPT_DIR/contract-verify.sh"

  if [[ ! -f "$verify_script" ]]; then
    log_warning "Contract verification script not found - skipping"
    return 0
  fi

  if "$verify_script"; then
    log_success "CDC verification passed"
    return 0
  else
    log_error "CDC verification failed"
    return 1
  fi
}

#######################################
# Main
#######################################
main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --verify)
        VERIFY=true
        shift
        ;;
      --path)
        TARGET_PATH="$2"
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

  # Check contracts directory
  if [[ ! -d "$CONTRACTS_DIR" ]]; then
    log_error "Contracts directory not found: $CONTRACTS_DIR"
    exit 1
  fi

  # Check for required tools
  if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed"
    exit 1
  fi

  if ! command -v yq &> /dev/null; then
    log_warning "yq not found - using limited fixture generation"
  fi

  # Discover versions
  log_info "Discovering contract versions..."

  local versions
  versions=$(discover_versions)

  if [[ -z "$versions" ]]; then
    log_warning "No contract versions found"
    exit 0
  fi

  local version_count
  version_count=$(echo "$versions" | wc -l | tr -d ' ')

  log_info "Found $version_count version(s)"
  echo ""

  # Process each version
  while IFS= read -r version_dir; do
    [[ -z "$version_dir" ]] && continue
    process_version "$version_dir"
  done <<< "$versions"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_success "Fixture refresh complete"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Generated $GENERATED_COUNT fixtures"
  echo ""

  # Run verification if requested
  if [[ "$VERIFY" == true ]]; then
    if ! run_verification; then
      exit 1
    fi
  fi
}

main "$@"
