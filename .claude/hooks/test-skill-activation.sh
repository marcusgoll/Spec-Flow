#!/bin/bash
# Test script for skill-activation-prompt hook
# Simulates UserPromptSubmit event with various prompts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Export required environment variable
export CLAUDE_PROJECT_DIR="$(cd ../.. && pwd)"

echo "Testing Skill Auto-Activation Hook"
echo "==================================="
echo ""

# Test 1: Specification phase
echo "Test 1: Specification keyword"
echo '{"session_id":"test-session","transcript_path":"/dev/null","cwd":"'$CLAUDE_PROJECT_DIR'","permission_mode":"normal","prompt":"create spec for user authentication"}' | bash skill-activation-prompt.sh
echo ""

# Test 2: Implementation phase
echo "Test 2: Implementation keyword"
echo '{"session_id":"test-session","transcript_path":"/dev/null","cwd":"'$CLAUDE_PROJECT_DIR'","permission_mode":"normal","prompt":"implement login endpoint with TDD"}' | bash skill-activation-prompt.sh
echo ""

# Test 3: Planning phase
echo "Test 3: Planning keyword"
echo '{"session_id":"test-session","transcript_path":"/dev/null","cwd":"'$CLAUDE_PROJECT_DIR'","permission_mode":"normal","prompt":"how should I approach building the architecture for this feature"}' | bash skill-activation-prompt.sh
echo ""

# Test 4: Deployment phase
echo "Test 4: Production deployment"
echo '{"session_id":"test-session","transcript_path":"/dev/null","cwd":"'$CLAUDE_PROJECT_DIR'","permission_mode":"normal","prompt":"deploy to production"}' | bash skill-activation-prompt.sh
echo ""

# Test 5: No match
echo "Test 5: No matching skills"
echo '{"session_id":"test-session","transcript_path":"/dev/null","cwd":"'$CLAUDE_PROJECT_DIR'","permission_mode":"normal","prompt":"what is the weather today"}' | bash skill-activation-prompt.sh
echo ""

echo "==================================="
echo "Test completed!"
