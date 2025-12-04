#!/usr/bin/env bash

# init-project.sh - Initialize project design documentation
#
# Idempotent project documentation generator with multiple operation modes.
#
# Usage:
#   init-project.sh [PROJECT_NAME] [OPTIONS]
#
# Options:
#   --force                Overwrite all existing docs (destructive)
#   --update               Only update [NEEDS CLARIFICATION] sections
#   --write-missing-only   Only create missing docs, preserve existing
#   --ci                   CI mode: non-interactive, exit 1 if questions unanswered
#   --non-interactive      Use environment variables or config file only
#   --config <file>        Load answers from YAML/JSON config file
#   --help                 Show this help message
#
# Environment Variables (used in non-interactive mode):
#   INIT_NAME, INIT_VISION, INIT_USERS, INIT_SCALE, INIT_TEAM_SIZE
#   INIT_ARCHITECTURE, INIT_DATABASE, INIT_DEPLOY_PLATFORM, INIT_API_STYLE
#   INIT_AUTH_PROVIDER, INIT_BUDGET_MVP, INIT_PRIVACY, INIT_GIT_WORKFLOW
#   INIT_DEPLOY_MODEL, INIT_FRONTEND, INIT_COMPONENT_LIBRARY
#
# Exit Codes:
#   0 - Success
#   1 - Error or missing required input in CI mode
#   2 - Quality gate failure

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || cd "$SCRIPT_DIR/../../.." && pwd)"

# Default values
MODE="default"  # default | force | update | write-missing-only
INTERACTIVE=true
CI_MODE=false
CONFIG_FILE=""
PROJECT_NAME=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --force)
      MODE="force"
      shift
      ;;
    --update)
      MODE="update"
      shift
      ;;
    --write-missing-only)
      MODE="write-missing-only"
      shift
      ;;
    --ci)
      CI_MODE=true
      INTERACTIVE=false
      shift
      ;;
    --non-interactive)
      INTERACTIVE=false
      shift
      ;;
    --config)
      CONFIG_FILE="$2"
      shift 2
      ;;
    --help)
      sed -n '2,24p' "$0" | sed 's/^# //'
      exit 0
      ;;
    -*)
      echo "Error: Unknown option: $1" >&2
      exit 1
      ;;
    *)
      PROJECT_NAME="$1"
      shift
      ;;
  esac
done

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() {
  echo -e "${BLUE}ℹ${NC} $*"
}

success() {
  echo -e "${GREEN}✓${NC} $*"
}

warning() {
  echo -e "${YELLOW}⚠${NC} $*"
}

error() {
  echo -e "${RED}✗${NC} $*" >&2
}

# Check prerequisites
check_prerequisites() {
  local missing=()

  # Node.js required for template rendering
  if ! command -v node > /dev/null 2>&1; then
    missing+=("node (Node.js)")
  fi

  # yq for YAML config parsing
  if [[ -n "$CONFIG_FILE" ]] && [[ "$CONFIG_FILE" == *.yaml || "$CONFIG_FILE" == *.yml ]]; then
    if ! command -v yq > /dev/null 2>&1; then
      missing+=("yq (YAML parser)")
    fi
  fi

  # jq for JSON parsing
  if ! command -v jq > /dev/null 2>&1; then
    missing+=("jq (JSON parser)")
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    error "Missing required tools:"
    for tool in "${missing[@]}"; do
      error "  - $tool"
    done
    exit 1
  fi
}

# Load config file (YAML or JSON)
load_config() {
  if [[ -z "$CONFIG_FILE" ]]; then
    return 0
  fi

  if [[ ! -f "$CONFIG_FILE" ]]; then
    error "Config file not found: $CONFIG_FILE"
    exit 1
  fi

  info "Loading config from: $CONFIG_FILE"

  if [[ "$CONFIG_FILE" == *.yaml || "$CONFIG_FILE" == *.yml ]]; then
    # Load YAML config
    INIT_NAME=$(yq eval '.project.name // ""' "$CONFIG_FILE")
    INIT_VISION=$(yq eval '.project.vision // ""' "$CONFIG_FILE")
    INIT_USERS=$(yq eval '.project.users // ""' "$CONFIG_FILE")
    INIT_SCALE=$(yq eval '.project.scale // ""' "$CONFIG_FILE")
    INIT_TEAM_SIZE=$(yq eval '.project.team_size // ""' "$CONFIG_FILE")
    INIT_ARCHITECTURE=$(yq eval '.project.architecture // ""' "$CONFIG_FILE")
    INIT_DATABASE=$(yq eval '.project.database // ""' "$CONFIG_FILE")
    INIT_DEPLOY_PLATFORM=$(yq eval '.project.deploy_platform // ""' "$CONFIG_FILE")
    INIT_API_STYLE=$(yq eval '.project.api_style // ""' "$CONFIG_FILE")
    INIT_AUTH_PROVIDER=$(yq eval '.project.auth_provider // ""' "$CONFIG_FILE")
    INIT_BUDGET_MVP=$(yq eval '.project.budget_mvp // ""' "$CONFIG_FILE")
    INIT_PRIVACY=$(yq eval '.project.privacy // ""' "$CONFIG_FILE")
    INIT_GIT_WORKFLOW=$(yq eval '.project.git_workflow // ""' "$CONFIG_FILE")
    INIT_DEPLOY_MODEL=$(yq eval '.project.deploy_model // ""' "$CONFIG_FILE")
    INIT_FRONTEND=$(yq eval '.project.frontend // ""' "$CONFIG_FILE")
    INIT_COMPONENT_LIBRARY=$(yq eval '.project.component_library // ""' "$CONFIG_FILE")
  elif [[ "$CONFIG_FILE" == *.json ]]; then
    # Load JSON config
    INIT_NAME=$(jq -r '.project.name // ""' "$CONFIG_FILE")
    INIT_VISION=$(jq -r '.project.vision // ""' "$CONFIG_FILE")
    INIT_USERS=$(jq -r '.project.users // ""' "$CONFIG_FILE")
    INIT_SCALE=$(jq -r '.project.scale // ""' "$CONFIG_FILE")
    INIT_TEAM_SIZE=$(jq -r '.project.team_size // ""' "$CONFIG_FILE")
    INIT_ARCHITECTURE=$(jq -r '.project.architecture // ""' "$CONFIG_FILE")
    INIT_DATABASE=$(jq -r '.project.database // ""' "$CONFIG_FILE")
    INIT_DEPLOY_PLATFORM=$(jq -r '.project.deploy_platform // ""' "$CONFIG_FILE")
    INIT_API_STYLE=$(jq -r '.project.api_style // ""' "$CONFIG_FILE")
    INIT_AUTH_PROVIDER=$(jq -r '.project.auth_provider // ""' "$CONFIG_FILE")
    INIT_BUDGET_MVP=$(jq -r '.project.budget_mvp // ""' "$CONFIG_FILE")
    INIT_PRIVACY=$(jq -r '.project.privacy // ""' "$CONFIG_FILE")
    INIT_GIT_WORKFLOW=$(jq -r '.project.git_workflow // ""' "$CONFIG_FILE")
    INIT_DEPLOY_MODEL=$(jq -r '.project.deploy_model // ""' "$CONFIG_FILE")
    INIT_FRONTEND=$(jq -r '.project.frontend // ""' "$CONFIG_FILE")
    INIT_COMPONENT_LIBRARY=$(jq -r '.project.component_library // ""' "$CONFIG_FILE")
  else
    error "Config file must be .yaml, .yml, or .json"
    exit 1
  fi

  success "Config loaded"
}

# Detect project type (greenfield vs brownfield)
detect_project_type() {
  if [[ -f "package.json" ]] || [[ -f "requirements.txt" ]] || [[ -f "Cargo.toml" ]] || [[ -f "go.mod" ]]; then
    echo "brownfield"
  else
    echo "greenfield"
  fi
}

# Scan brownfield codebase for tech stack
scan_brownfield() {
  info "Scanning existing codebase..."

  # Detect database
  if [[ -f "package.json" ]]; then
    if grep -q '"pg"' package.json; then
      INIT_DATABASE="${INIT_DATABASE:-PostgreSQL}"
    elif grep -q '"mysql' package.json; then
      INIT_DATABASE="${INIT_DATABASE:-MySQL}"
    elif grep -q '"mongoose"' package.json; then
      INIT_DATABASE="${INIT_DATABASE:-MongoDB}"
    fi

    # Detect frontend
    if grep -q '"next"' package.json; then
      INIT_FRONTEND="${INIT_FRONTEND:-Next.js}"
    elif grep -q '"react"' package.json && grep -q '"vite"' package.json; then
      INIT_FRONTEND="${INIT_FRONTEND:-Vite + React}"
    elif grep -q '"vue"' package.json; then
      INIT_FRONTEND="${INIT_FRONTEND:-Vue/Nuxt}"
    fi

    # Detect component library
    detect_component_library
  elif [[ -f "requirements.txt" ]]; then
    if grep -q "psycopg2" requirements.txt; then
      INIT_DATABASE="${INIT_DATABASE:-PostgreSQL}"
    elif grep -q "pymongo" requirements.txt; then
      INIT_DATABASE="${INIT_DATABASE:-MongoDB}"
    fi
  fi

  # Detect deployment platform
  if [[ -f "vercel.json" ]]; then
    INIT_DEPLOY_PLATFORM="${INIT_DEPLOY_PLATFORM:-Vercel}"
  elif [[ -f "railway.json" ]]; then
    INIT_DEPLOY_PLATFORM="${INIT_DEPLOY_PLATFORM:-Railway}"
  fi

  # Detect architecture
  if [[ -f "docker-compose.yml" ]] && grep -q "services:" docker-compose.yml; then
    local service_count=$(grep -c "^\s\+[a-z]" docker-compose.yml || echo "1")
    if [[ $service_count -gt 2 ]]; then
      INIT_ARCHITECTURE="${INIT_ARCHITECTURE:-microservices}"
    else
      INIT_ARCHITECTURE="${INIT_ARCHITECTURE:-monolith}"
    fi
  else
    INIT_ARCHITECTURE="${INIT_ARCHITECTURE:-monolith}"
  fi

  success "Brownfield scan complete"
}

# Detect component library from package.json
detect_component_library() {
  if [[ ! -f "package.json" ]]; then
    return 0
  fi

  local pkg_content
  pkg_content=$(cat package.json)

  # shadcn/ui detection (most common in Next.js)
  # shadcn uses @radix-ui primitives + custom components in src/components/ui
  if echo "$pkg_content" | grep -q '"@radix-ui/' && \
     [[ -d "src/components/ui" || -d "components/ui" ]]; then
    INIT_COMPONENT_LIBRARY="${INIT_COMPONENT_LIBRARY:-shadcn/ui}"
    success "Detected component library: shadcn/ui (Radix + custom components)"
    return 0
  fi

  # Chakra UI
  if echo "$pkg_content" | grep -q '"@chakra-ui/react"'; then
    INIT_COMPONENT_LIBRARY="${INIT_COMPONENT_LIBRARY:-Chakra UI}"
    success "Detected component library: Chakra UI"
    return 0
  fi

  # MUI (Material UI)
  if echo "$pkg_content" | grep -q '"@mui/material"'; then
    INIT_COMPONENT_LIBRARY="${INIT_COMPONENT_LIBRARY:-MUI}"
    success "Detected component library: MUI (Material UI)"
    return 0
  fi

  # HeroUI (newer library)
  if echo "$pkg_content" | grep -q '"@heroui/'; then
    INIT_COMPONENT_LIBRARY="${INIT_COMPONENT_LIBRARY:-HeroUI}"
    success "Detected component library: HeroUI"
    return 0
  fi

  # Ant Design
  if echo "$pkg_content" | grep -q '"antd"'; then
    INIT_COMPONENT_LIBRARY="${INIT_COMPONENT_LIBRARY:-Ant Design}"
    success "Detected component library: Ant Design"
    return 0
  fi

  # Mantine
  if echo "$pkg_content" | grep -q '"@mantine/core"'; then
    INIT_COMPONENT_LIBRARY="${INIT_COMPONENT_LIBRARY:-Mantine}"
    success "Detected component library: Mantine"
    return 0
  fi

  # Radix UI (standalone, without shadcn)
  if echo "$pkg_content" | grep -q '"@radix-ui/' && \
     [[ ! -d "src/components/ui" && ! -d "components/ui" ]]; then
    INIT_COMPONENT_LIBRARY="${INIT_COMPONENT_LIBRARY:-Radix UI}"
    success "Detected component library: Radix UI (primitives)"
    return 0
  fi

  # Headless UI (Tailwind)
  if echo "$pkg_content" | grep -q '"@headlessui/react"'; then
    INIT_COMPONENT_LIBRARY="${INIT_COMPONENT_LIBRARY:-Headless UI}"
    success "Detected component library: Headless UI"
    return 0
  fi

  # DaisyUI (Tailwind)
  if echo "$pkg_content" | grep -q '"daisyui"'; then
    INIT_COMPONENT_LIBRARY="${INIT_COMPONENT_LIBRARY:-DaisyUI}"
    success "Detected component library: DaisyUI"
    return 0
  fi

  # No known library detected
  info "No component library detected (custom components or none)"
  INIT_COMPONENT_LIBRARY="${INIT_COMPONENT_LIBRARY:-}"
}

# Interactive questionnaire
run_questionnaire() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 PROJECT INFORMATION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Q1: Project Name
  if [[ -z "$INIT_NAME" ]]; then
    if [[ -n "$PROJECT_NAME" ]]; then
      INIT_NAME="$PROJECT_NAME"
      echo "Q1. Project name: $INIT_NAME (from argument)"
    else
      read -r -p "Q1. Project name (e.g., 'FlightPro', 'AcmeApp'): " INIT_NAME
    fi
  fi

  # Q2: Vision
  if [[ -z "$INIT_VISION" ]]; then
    read -r -p "Q2. What does this project do? (1 sentence): " INIT_VISION
  fi

  # Q3: Target Users
  if [[ -z "$INIT_USERS" ]]; then
    read -r -p "Q3. Who are the primary users? (e.g., 'Flight instructors'): " INIT_USERS
  fi

  # Q4: Scale
  if [[ -z "$INIT_SCALE" ]]; then
    echo ""
    echo "Q4. Expected initial scale?"
    echo "  1. Micro (< 100 users)"
    echo "  2. Small (100-1K users)"
    echo "  3. Medium (1K-10K users)"
    echo "  4. Large (10K+ users)"
    read -r -p "Choice (1-4): " scale_choice
    case $scale_choice in
      1) INIT_SCALE="micro" ;;
      2) INIT_SCALE="small" ;;
      3) INIT_SCALE="medium" ;;
      4) INIT_SCALE="large" ;;
      *) INIT_SCALE="micro" ;;
    esac
  fi

  # Q5: Team Size
  if [[ -z "$INIT_TEAM_SIZE" ]]; then
    echo ""
    echo "Q5. Current team size?"
    echo "  1. Solo (1 developer)"
    echo "  2. Small (2-5 developers)"
    echo "  3. Medium (5-15 developers)"
    echo "  4. Large (15+ developers)"
    read -r -p "Choice (1-4): " team_choice
    case $team_choice in
      1) INIT_TEAM_SIZE="solo" ;;
      2) INIT_TEAM_SIZE="small" ;;
      3) INIT_TEAM_SIZE="medium" ;;
      4) INIT_TEAM_SIZE="large" ;;
      *) INIT_TEAM_SIZE="solo" ;;
    esac
  fi

  # Q6: Architecture
  if [[ -z "$INIT_ARCHITECTURE" ]]; then
    echo ""
    echo "Q6. System architecture?"
    echo "  1. Monolith (single deployable unit)"
    echo "  2. Microservices (multiple services)"
    echo "  3. Serverless (functions, lambdas)"
    echo "  4. Hybrid (mono + some services)"
    read -r -p "Choice (1-4): " arch_choice
    case $arch_choice in
      1) INIT_ARCHITECTURE="monolith" ;;
      2) INIT_ARCHITECTURE="microservices" ;;
      3) INIT_ARCHITECTURE="serverless" ;;
      4) INIT_ARCHITECTURE="hybrid" ;;
      *) INIT_ARCHITECTURE="monolith" ;;
    esac
  fi

  # Q7: Database
  if [[ -z "$INIT_DATABASE" ]]; then
    echo ""
    echo "Q7. Primary database?"
    echo "  1. PostgreSQL"
    echo "  2. MySQL"
    echo "  3. MongoDB"
    echo "  4. SQLite"
    echo "  5. None (static site)"
    read -r -p "Choice (1-5): " db_choice
    case $db_choice in
      1) INIT_DATABASE="PostgreSQL" ;;
      2) INIT_DATABASE="MySQL" ;;
      3) INIT_DATABASE="MongoDB" ;;
      4) INIT_DATABASE="SQLite" ;;
      5) INIT_DATABASE="None" ;;
      *) INIT_DATABASE="PostgreSQL" ;;
    esac
  fi

  # Q8: Deploy Platform
  if [[ -z "$INIT_DEPLOY_PLATFORM" ]]; then
    echo ""
    echo "Q8. Deployment platform?"
    echo "  1. Vercel"
    echo "  2. Railway"
    echo "  3. AWS (EC2/ECS)"
    echo "  4. Docker + VPS"
    echo "  5. Netlify"
    echo "  6. Fly.io"
    read -r -p "Choice (1-6): " deploy_choice
    case $deploy_choice in
      1) INIT_DEPLOY_PLATFORM="Vercel" ;;
      2) INIT_DEPLOY_PLATFORM="Railway" ;;
      3) INIT_DEPLOY_PLATFORM="AWS" ;;
      4) INIT_DEPLOY_PLATFORM="Docker" ;;
      5) INIT_DEPLOY_PLATFORM="Netlify" ;;
      6) INIT_DEPLOY_PLATFORM="Fly.io" ;;
      *) INIT_DEPLOY_PLATFORM="Vercel" ;;
    esac
  fi

  # Q9: API Style
  if [[ -z "$INIT_API_STYLE" ]]; then
    echo ""
    echo "Q9. API style?"
    echo "  1. REST (traditional endpoints)"
    echo "  2. GraphQL (query language)"
    echo "  3. tRPC (type-safe RPC)"
    echo "  4. gRPC (protocol buffers)"
    read -r -p "Choice (1-4): " api_choice
    case $api_choice in
      1) INIT_API_STYLE="REST" ;;
      2) INIT_API_STYLE="GraphQL" ;;
      3) INIT_API_STYLE="tRPC" ;;
      4) INIT_API_STYLE="gRPC" ;;
      *) INIT_API_STYLE="REST" ;;
    esac
  fi

  # Q10: Auth Provider
  if [[ -z "$INIT_AUTH_PROVIDER" ]]; then
    echo ""
    echo "Q10. Authentication provider?"
    echo "  1. Clerk (managed auth)"
    echo "  2. Auth0 (enterprise auth)"
    echo "  3. NextAuth.js (self-hosted)"
    echo "  4. Firebase Auth"
    echo "  5. Custom (roll your own)"
    echo "  6. None (public app)"
    read -r -p "Choice (1-6): " auth_choice
    case $auth_choice in
      1) INIT_AUTH_PROVIDER="Clerk" ;;
      2) INIT_AUTH_PROVIDER="Auth0" ;;
      3) INIT_AUTH_PROVIDER="NextAuth" ;;
      4) INIT_AUTH_PROVIDER="Firebase" ;;
      5) INIT_AUTH_PROVIDER="Custom" ;;
      6) INIT_AUTH_PROVIDER="None" ;;
      *) INIT_AUTH_PROVIDER="Clerk" ;;
    esac
  fi

  # Q11: Budget MVP
  if [[ -z "$INIT_BUDGET_MVP" ]]; then
    echo ""
    echo "Q11. Monthly infrastructure budget for MVP?"
    echo "  1. Free tier only (\$0)"
    echo "  2. Hobby (\$10-50/month)"
    echo "  3. Startup (\$50-200/month)"
    echo "  4. Growth (\$200-1000/month)"
    echo "  5. Enterprise (\$1000+/month)"
    read -r -p "Choice (1-5): " budget_choice
    case $budget_choice in
      1) INIT_BUDGET_MVP="0" ;;
      2) INIT_BUDGET_MVP="50" ;;
      3) INIT_BUDGET_MVP="200" ;;
      4) INIT_BUDGET_MVP="1000" ;;
      5) INIT_BUDGET_MVP="5000" ;;
      *) INIT_BUDGET_MVP="50" ;;
    esac
  fi

  # Q12: Privacy Requirements
  if [[ -z "$INIT_PRIVACY" ]]; then
    echo ""
    echo "Q12. Privacy/compliance requirements?"
    echo "  1. Basic PII (names, emails)"
    echo "  2. GDPR (EU users)"
    echo "  3. CCPA (California)"
    echo "  4. HIPAA (healthcare)"
    echo "  5. SOC2 (enterprise)"
    echo "  6. None (no user data)"
    read -r -p "Choice (1-6): " privacy_choice
    case $privacy_choice in
      1) INIT_PRIVACY="PII" ;;
      2) INIT_PRIVACY="GDPR" ;;
      3) INIT_PRIVACY="CCPA" ;;
      4) INIT_PRIVACY="HIPAA" ;;
      5) INIT_PRIVACY="SOC2" ;;
      6) INIT_PRIVACY="None" ;;
      *) INIT_PRIVACY="PII" ;;
    esac
  fi

  # Q13: Git Workflow
  if [[ -z "$INIT_GIT_WORKFLOW" ]]; then
    echo ""
    echo "Q13. Git workflow?"
    echo "  1. Trunk-based (main + short-lived branches)"
    echo "  2. GitHub Flow (main + feature branches + PRs)"
    echo "  3. GitFlow (main + develop + release branches)"
    read -r -p "Choice (1-3): " git_choice
    case $git_choice in
      1) INIT_GIT_WORKFLOW="trunk-based" ;;
      2) INIT_GIT_WORKFLOW="github-flow" ;;
      3) INIT_GIT_WORKFLOW="gitflow" ;;
      *) INIT_GIT_WORKFLOW="github-flow" ;;
    esac
  fi

  # Q14: Deployment Model
  if [[ -z "$INIT_DEPLOY_MODEL" ]]; then
    echo ""
    echo "Q14. Deployment model?"
    echo "  1. staging-prod (staging → validation → production)"
    echo "  2. direct-prod (direct to production)"
    echo "  3. local-only (local dev, no deployment)"
    read -r -p "Choice (1-3): " deploy_model_choice
    case $deploy_model_choice in
      1) INIT_DEPLOY_MODEL="staging-prod" ;;
      2) INIT_DEPLOY_MODEL="direct-prod" ;;
      3) INIT_DEPLOY_MODEL="local-only" ;;
      *) INIT_DEPLOY_MODEL="staging-prod" ;;
    esac
  fi

  # Q15: Frontend Framework
  if [[ -z "$INIT_FRONTEND" ]]; then
    echo ""
    echo "Q15. Frontend framework?"
    echo "  1. Next.js (React + SSR)"
    echo "  2. React + Vite (SPA)"
    echo "  3. Vue/Nuxt"
    echo "  4. SvelteKit"
    echo "  5. None (API only)"
    read -r -p "Choice (1-5): " frontend_choice
    case $frontend_choice in
      1) INIT_FRONTEND="Next.js" ;;
      2) INIT_FRONTEND="React+Vite" ;;
      3) INIT_FRONTEND="Vue/Nuxt" ;;
      4) INIT_FRONTEND="SvelteKit" ;;
      5) INIT_FRONTEND="None" ;;
      *) INIT_FRONTEND="Next.js" ;;
    esac
  fi

  success "Questionnaire complete"
}

# Generate answers JSON file
generate_answers_json() {
  local output_file="$1"

  cat > "$output_file" <<EOF
{
  "PROJECT_NAME": "${INIT_NAME:-[NEEDS CLARIFICATION]}",
  "VISION": "${INIT_VISION:-[NEEDS CLARIFICATION]}",
  "PRIMARY_USERS": "${INIT_USERS:-[NEEDS CLARIFICATION]}",
  "SCALE": "${INIT_SCALE:-micro}",
  "TEAM_SIZE": "${INIT_TEAM_SIZE:-solo}",
  "ARCHITECTURE": "${INIT_ARCHITECTURE:-monolith}",
  "DATABASE": "${INIT_DATABASE:-PostgreSQL}",
  "DEPLOY_PLATFORM": "${INIT_DEPLOY_PLATFORM:-Vercel}",
  "API_STYLE": "${INIT_API_STYLE:-REST}",
  "AUTH_PROVIDER": "${INIT_AUTH_PROVIDER:-Clerk}",
  "BUDGET_MVP": "${INIT_BUDGET_MVP:-50}",
  "PRIVACY": "${INIT_PRIVACY:-PII}",
  "GIT_WORKFLOW": "${INIT_GIT_WORKFLOW:-GitHub Flow}",
  "DEPLOY_MODEL": "${INIT_DEPLOY_MODEL:-staging-prod}",
  "FRONTEND": "${INIT_FRONTEND:-Next.js}",
  "COMPONENT_LIBRARY": "${INIT_COMPONENT_LIBRARY:-}",
  "DATE": "$(date +%Y-%m-%d)"
}
EOF
}

# Generate project-level CLAUDE.md
generate_project_claude_md() {
  local claude_script="$REPO_ROOT/.spec-flow/scripts/bash/generate-project-claude-md.sh"
  local output_file="$REPO_ROOT/docs/project/CLAUDE.md"

  if [[ ! -f "$claude_script" ]]; then
    warning "CLAUDE.md generator script not found, skipping"
    return 0
  fi

  # Check if should skip (write-missing-only mode)
  if [[ "$MODE" == "write-missing-only" ]] && [[ -f "$output_file" ]]; then
    info "Skipping existing: docs/project/CLAUDE.md"
    return 0
  fi

  info "Generating project CLAUDE.md..."

  if bash "$claude_script" --output "$output_file" 2>/dev/null; then
    success "Generated docs/project/CLAUDE.md"
  else
    warning "Failed to generate project CLAUDE.md (non-blocking)"
  fi
}

# Render project documentation
render_docs() {
  local answers_file="$1"
  local mode="$2"

  info "Generating project documentation..."

  # List of docs to generate
  local docs=(
    "overview"
    "system-architecture"
    "tech-stack"
    "data-architecture"
    "api-strategy"
    "capacity-planning"
    "deployment-strategy"
    "development-workflow"
  )

  for doc in "${docs[@]}"; do
    local template="$REPO_ROOT/.spec-flow/templates/project/${doc}.md"
    local output="$REPO_ROOT/docs/project/${doc}.md"

    # Check if should skip (write-missing-only mode)
    if [[ "$MODE" == "write-missing-only" ]] && [[ -f "$output" ]]; then
      info "Skipping existing: $doc.md"
      continue
    fi

    # Render with Node.js
    if [[ "$mode" == "update" ]]; then
      node "$REPO_ROOT/.spec-flow/scripts/node/render.js" \
        --template "$template" \
        --output "$output" \
        --answers "$answers_file" \
        --mode update
    else
      node "$REPO_ROOT/.spec-flow/scripts/node/render.js" \
        --template "$template" \
        --output "$output" \
        --answers "$answers_file"
    fi
  done

  success "Documentation generated"
}

# Create foundation roadmap issue for greenfield projects
create_foundation_issue() {
  # Only create for greenfield projects
  if [[ "$PROJECT_TYPE" != "greenfield" ]]; then
    return 0
  fi

  # Check if gh CLI is available and authenticated
  if ! command -v gh &> /dev/null; then
    info "GitHub CLI not found, skipping foundation issue creation"
    return 0
  fi

  # Check if repository has a remote
  if ! git remote -v | grep -q "origin"; then
    info "No git remote found, skipping foundation issue creation"
    return 0
  fi

  # Check if issues already exist with roadmap label
  local existing_issues
  existing_issues=$(gh issue list --label "roadmap" --limit 1 --json number --jq '.[0].number' 2>/dev/null || echo "")

  if [[ -n "$existing_issues" && "$existing_issues" != "null" ]]; then
    info "Roadmap issues already exist, skipping foundation issue"
    return 0
  fi

  info "Creating foundation roadmap issue..."

  # Create foundation issue body
  local issue_body
  issue_body=$(cat <<EOF
<!-- roadmap-metadata
feature_slug: foundation-setup
area: infrastructure
role: fullstack
priority: P0
complexity: M
status: next
-->

## Overview

Foundation setup for **${INIT_NAME}** - initial project scaffolding based on architecture decisions from project initialization.

## User Story

As a **developer**, I want **the foundational project structure in place** so that **I can start implementing features immediately**.

## Acceptance Criteria

### Core Setup
- [ ] Frontend framework initialized (${INIT_FRONTEND})
- [ ] Backend API scaffolding (${INIT_API_STYLE})
- [ ] Database connection configured (${INIT_DATABASE})
- [ ] Authentication provider integrated (${INIT_AUTH_PROVIDER})

### Development Infrastructure
- [ ] CI/CD pipeline configured (GitHub Actions)
- [ ] Environment variables documented
- [ ] Local development setup documented in README
- [ ] Development database seeded with test data

### Quality Gates
- [ ] ESLint/Prettier configured (frontend)
- [ ] Pre-commit hooks installed
- [ ] Type checking enabled (TypeScript)
- [ ] Basic test infrastructure in place

## Technical Notes

**Architecture**: ${INIT_ARCHITECTURE}
**Deployment**: ${INIT_DEPLOY_PLATFORM} (${INIT_DEPLOY_MODEL})
**Scale Tier**: ${INIT_SCALE}
**Team Size**: ${INIT_TEAM_SIZE}

## References

- [Tech Stack](docs/project/tech-stack.md)
- [System Architecture](docs/project/system-architecture.md)
- [Deployment Strategy](docs/project/deployment-strategy.md)
EOF
)

  # Create the issue
  local issue_url
  issue_url=$(gh issue create \
    --title "Foundation: Project Scaffolding for ${INIT_NAME}" \
    --body "$issue_body" \
    --label "roadmap,type:feature,status:next,area:infrastructure,priority:P0" \
    2>/dev/null || echo "")

  if [[ -n "$issue_url" ]]; then
    success "Created foundation issue: $issue_url"
  else
    warning "Could not create foundation issue (check GitHub permissions)"
  fi
}

# Create ADR-0001
create_adr_baseline() {
  local adr_dir="$REPO_ROOT/docs/adr"
  mkdir -p "$adr_dir"

  local adr_file="$adr_dir/0001-project-architecture-baseline.md"

  if [[ -f "$adr_file" ]] && [[ "$MODE" != "force" ]]; then
    info "ADR-0001 already exists, skipping"
    return 0
  fi

  cat > "$adr_file" <<EOF
# ADR-0001: Project Architecture Baseline

**Status**: Accepted
**Date**: $(date +%Y-%m-%d)
**Deciders**: Engineering Team

## Context

This is the initial architectural decision record documenting the baseline technology choices and architectural patterns for the ${INIT_NAME} project.

These decisions were made during project initialization and establish the foundation for all future architectural decisions.

## Decision

We have decided to build ${INIT_NAME} with the following architecture:

### Technology Stack

- **Frontend**: ${INIT_FRONTEND}
- **Component Library**: ${INIT_COMPONENT_LIBRARY:-None detected}
- **Backend**: [Based on API style: ${INIT_API_STYLE}]
- **Database**: ${INIT_DATABASE}
- **Authentication**: ${INIT_AUTH_PROVIDER}
- **Deployment**: ${INIT_DEPLOY_PLATFORM}

### Architectural Style

- **Pattern**: ${INIT_ARCHITECTURE}
- **API Style**: ${INIT_API_STYLE}
- **Scale Tier**: ${INIT_SCALE}

### Development Workflow

- **Git Workflow**: ${INIT_GIT_WORKFLOW}
- **Deployment Model**: ${INIT_DEPLOY_MODEL}
- **Team Size**: ${INIT_TEAM_SIZE}

## Consequences

### Positive

- Clear technology baseline for all engineers
- Consistent patterns across the codebase
- Documented rationale for technology choices

### Negative

- Technology choices constrain future flexibility
- Migration to different stack requires new ADR and significant effort

### Risks

- Technology may become outdated over time
- Team expertise may not align with chosen stack

## References

- [Tech Stack Documentation](../project/tech-stack.md)
- [System Architecture](../project/system-architecture.md)
- [Deployment Strategy](../project/deployment-strategy.md)

## Notes

This ADR serves as the baseline. All future architectural changes should reference this decision and explain deviations.
EOF

  success "Created ADR-0001"
}

# Run quality gates
run_quality_gates() {
  local exit_code=0

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔍 QUALITY GATES"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Gate 1: Check for [NEEDS CLARIFICATION] tokens
  if grep -r "NEEDS CLARIFICATION" "$REPO_ROOT/docs/project/" > /dev/null 2>&1; then
    warning "Found [NEEDS CLARIFICATION] tokens in documentation"
    warning "Review and fill missing information"

    if [[ "$CI_MODE" == true ]]; then
      error "CI mode: Unanswered questions not allowed"
      exit_code=2
    fi
  else
    success "No missing information"
  fi

  # Gate 2: Markdown linting (if markdownlint installed)
  if command -v markdownlint > /dev/null 2>&1; then
    info "Running markdownlint..."
    if markdownlint "$REPO_ROOT/docs/project/" > /dev/null 2>&1; then
      success "Markdown linting passed"
    else
      warning "Markdown linting failed (non-blocking)"
    fi
  fi

  # Gate 3: Link checking (if lychee installed)
  if command -v lychee > /dev/null 2>&1; then
    info "Running link checker..."
    if lychee "$REPO_ROOT/docs/project/" > /dev/null 2>&1; then
      success "Link checking passed"
    else
      warning "Link checking failed (non-blocking)"
    fi
  fi

  # Gate 4: Validate C4 model sections exist
  local required_sections=("Context" "Containers" "Components")
  if [[ -f "$REPO_ROOT/docs/project/system-architecture.md" ]]; then
    for section in "${required_sections[@]}"; do
      if grep -q "## $section" "$REPO_ROOT/docs/project/system-architecture.md"; then
        success "C4 section found: $section"
      else
        warning "Missing C4 section: $section"
        if [[ "$CI_MODE" == true ]]; then
          exit_code=2
        fi
      fi
    done
  fi

  echo ""

  if [[ $exit_code -ne 0 ]]; then
    error "Quality gates failed"
    return $exit_code
  fi

  success "All quality gates passed"
  return 0
}

# Git commit
commit_documentation() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 COMMITTING DOCUMENTATION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  cd "$REPO_ROOT"

  git add docs/project/
  git add docs/adr/
  git add CLAUDE.md 2>/dev/null || true

  local commit_msg="docs: initialize project design documentation

Project: ${INIT_NAME}
Architecture: ${INIT_ARCHITECTURE}
Database: ${INIT_DATABASE}
Deployment: ${INIT_DEPLOY_PLATFORM} (${INIT_DEPLOY_MODEL})
Scale: ${INIT_SCALE}

Generated comprehensive documentation:
- 8 project docs (overview, architecture, tech stack, data, API, capacity, deployment, workflow)
- ADR-0001 (architecture baseline)
- Project CLAUDE.md (AI context navigation)

Mode: $MODE

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

  if git commit -m "$commit_msg" > /dev/null 2>&1; then
    success "Documentation committed: $(git rev-parse --short HEAD)"
  else
    warning "No changes to commit (docs may be up to date)"
  fi
}

# Main execution
main() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🏗️  PROJECT INITIALIZATION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Check prerequisites
  check_prerequisites

  # Load config if provided
  load_config

  # Detect project type
  PROJECT_TYPE=$(detect_project_type)
  info "Project type: $PROJECT_TYPE"

  # Scan brownfield codebase
  if [[ "$PROJECT_TYPE" == "brownfield" ]]; then
    scan_brownfield
  fi

  # Run questionnaire if interactive
  if [[ "$INTERACTIVE" == true ]]; then
    run_questionnaire
  elif [[ "$CI_MODE" == true ]]; then
    # CI mode: validate all required vars
    local required_vars=(INIT_NAME INIT_VISION INIT_USERS)
    local missing=()
    for var in "${required_vars[@]}"; do
      if [[ -z "${!var}" ]]; then
        missing+=("$var")
      fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
      error "CI mode: Missing required environment variables:"
      for var in "${missing[@]}"; do
        error "  - $var"
      done
      exit 1
    fi
  fi

  # Generate answers JSON
  local answers_file="/tmp/init-project-answers-$$.json"
  generate_answers_json "$answers_file"

  # Render documentation
  local render_mode="default"
  if [[ "$MODE" == "update" ]]; then
    render_mode="update"
  fi
  render_docs "$answers_file" "$render_mode"

  # Generate project-level CLAUDE.md (aggregated context)
  generate_project_claude_md

  # Create ADR baseline
  create_adr_baseline

  # Create foundation issue for greenfield projects
  create_foundation_issue

  # Run quality gates
  if ! run_quality_gates; then
    error "Quality gates failed"
    rm -f "$answers_file"
    exit 2
  fi

  # Commit documentation
  commit_documentation

  # Cleanup
  rm -f "$answers_file"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ PROJECT INITIALIZATION COMPLETE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Project: $INIT_NAME"
  echo "Mode: $MODE"
  echo ""
  echo "Next steps:"
  echo "  1. Review docs/project/"
  echo "  2. Fill any [NEEDS CLARIFICATION] sections"
  echo "  3. Start building: /roadmap or /feature"
  echo ""
}

main
