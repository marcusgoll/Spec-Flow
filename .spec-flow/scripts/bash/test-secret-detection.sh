#!/usr/bin/env bash
#
# test-secret-detection.sh - Scan report files for exposed secrets
#
# PURPOSE:
#   Validates that report files do not contain exposed secrets.
#   Scans specs/*/artifacts/* for common secret patterns.
#   Returns non-zero exit code if secrets detected.
#
# USAGE:
#   # Scan all report files
#   bash .spec-flow/scripts/bash/test-secret-detection.sh
#
#   # Scan specific directory
#   bash .spec-flow/scripts/bash/test-secret-detection.sh specs/001-feature
#
#   # Use as pre-commit hook (recommended)
#   # In .git/hooks/pre-commit:
#   bash .spec-flow/scripts/bash/test-secret-detection.sh
#
# EXIT CODES:
#   0 - No secrets detected (safe to commit)
#   1 - Secrets detected (blocked)
#   2 - Error running scan
#
# AUTHOR: Spec-Flow Security
# VERSION: 1.0.0

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Secret patterns to detect
declare -A SECRET_PATTERNS=(
  ["API_KEY"]='(api[_-]?key|apikey)[\s]*[=:]\s*["]?[a-zA-Z0-9_-]{20,}["]?'
  ["TOKEN"]='(token|bearer)[\s]*[=:]\s*["]?[a-zA-Z0-9_-]{20,}["]?'
  ["PASSWORD"]='(password|passwd|pwd)[\s]*[=:]\s*["]?[^ \n]{8,}["]?'
  ["DATABASE_URL"]='(postgresql|mysql|mongodb|redis)://[^:]+:[^@]+@'
  ["URL_CREDS"]='https?://[^:]+:[^@]+@[^ \n]+'
  ["JWT"]='eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'
  ["AWS_KEY"]='AKIA[0-9A-Z]{16}'
  ["GITHUB_TOKEN"]='gh[ps]_[A-Za-z0-9_]{36,255}'
  ["PRIVATE_KEY"]='-----BEGIN[^-]*PRIVATE KEY-----'
  ["VERCEL_TOKEN"]='vercel[_-]?token[\s]*[=:]\s*["]?[a-zA-Z0-9_-]{20,}["]?'
  ["RAILWAY_TOKEN"]='railway[_-]?token[\s]*[=:]\s*["]?[a-zA-Z0-9_-]{20,}["]?'
)

# Exception patterns (false positives to ignore)
declare -A EXCEPTION_PATTERNS=(
  ["PLACEHOLDER"]='(\*\*\*REDACTED\*\*\*|\[.*from environment\]|\[VARIABLE\])'
  ["EXAMPLE"]='(example\.com|test\.com|localhost|127\.0\.0\.1)'
  ["TEMPLATE"]='(\[.*\]|<.*>|{.*})'
)

# Track findings
SECRETS_FOUND=0
FILES_SCANNED=0
FILES_WITH_SECRETS=0

#
# scan_directory - Scan all report files in directory
#
scan_directory() {
  local dir="${1:-specs}"

  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Secret Detection Scanner${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  if [ ! -d "$dir" ]; then
    echo -e "${RED}❌ Directory not found: $dir${NC}"
    exit 2
  fi

  echo "Scanning directory: $dir"
  echo ""

  # Find all markdown files in specs directories
  local files=()
  while IFS= read -r -d '' file; do
    files+=("$file")
  done < <(find "$dir" -type f \( -name "*.md" -o -name "*.txt" -o -name "*.log" \) -print0 2>/dev/null)

  if [ ${#files[@]} -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No report files found in $dir${NC}"
    exit 0
  fi

  echo "Found ${#files[@]} files to scan"
  echo ""

  # Scan each file
  for file in "${files[@]}"; do
    scan_file "$file"
  done

  # Print summary
  print_summary
}

#
# scan_file - Scan single file for secrets
#
scan_file() {
  local file="$1"
  local file_has_secrets=false

  FILES_SCANNED=$((FILES_SCANNED + 1))

  # Check each secret pattern
  for pattern_name in "${!SECRET_PATTERNS[@]}"; do
    local pattern="${SECRET_PATTERNS[$pattern_name]}"

    # Search for pattern
    local matches
    matches=$(grep -Pino "$pattern" "$file" 2>/dev/null || true)

    if [ -n "$matches" ]; then
      # Check if match is in exception patterns
      local is_exception=false

      while IFS= read -r match_line; do
        for exception_name in "${!EXCEPTION_PATTERNS[@]}"; do
          local exception="${EXCEPTION_PATTERNS[$exception_name]}"

          if echo "$match_line" | grep -Piq "$exception"; then
            is_exception=true
            break
          fi
        done

        # If not an exception, report it
        if [ "$is_exception" = false ]; then
          if [ "$file_has_secrets" = false ]; then
            echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${RED}❌ Secrets detected in: $file${NC}"
            echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            file_has_secrets=true
            FILES_WITH_SECRETS=$((FILES_WITH_SECRETS + 1))
          fi

          # Extract line number and content
          local line_num
          line_num=$(echo "$match_line" | cut -d: -f1)
          local line_content
          line_content=$(echo "$match_line" | cut -d: -f2-)

          # Redact the actual secret in output
          local redacted_content
          redacted_content=$(echo "$line_content" | sed -E "s/$pattern/[***REDACTED***]/gi")

          echo ""
          echo -e "${YELLOW}Pattern: $pattern_name${NC}"
          echo -e "${YELLOW}Line $line_num:${NC} $redacted_content"

          SECRETS_FOUND=$((SECRETS_FOUND + 1))
        fi
      done <<< "$matches"
    fi
  done

  if [ "$file_has_secrets" = true ]; then
    echo ""
  fi
}

#
# print_summary - Print scan results summary
#
print_summary() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Scan Summary${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Files scanned: $FILES_SCANNED"
  echo "Files with secrets: $FILES_WITH_SECRETS"
  echo "Total secrets found: $SECRETS_FOUND"
  echo ""

  if [ $SECRETS_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ No secrets detected!${NC}"
    echo -e "${GREEN}All report files are safe to commit.${NC}"
    echo ""
    exit 0
  else
    echo -e "${RED}❌ SECRETS DETECTED!${NC}"
    echo ""
    echo -e "${RED}Action required:${NC}"
    echo "1. Review the files listed above"
    echo "2. Replace exposed secrets with placeholders (***REDACTED***)"
    echo "3. Use environment variables instead of hardcoding values"
    echo "4. Run this scan again to verify fixes"
    echo ""
    echo "Sanitization tool:"
    echo "  source .spec-flow/scripts/bash/sanitize-secrets.sh"
    echo "  sanitize_secrets < report.md > report-clean.md"
    echo ""
    echo "See docs/security-guidelines.md for best practices"
    echo ""
    exit 1
  fi
}

#
# Main execution
#
main() {
  local scan_dir="${1:-specs}"

  # Check if grep supports -P (Perl regex)
  if ! grep -P "" /dev/null 2>/dev/null; then
    echo -e "${RED}❌ Error: grep does not support Perl regex (-P flag)${NC}"
    echo ""
    echo "This script requires GNU grep with PCRE support."
    echo ""
    echo "Install:"
    echo "  macOS: brew install grep (use ggrep)"
    echo "  Linux: Already installed"
    echo "  Windows: Install via Git Bash or WSL"
    exit 2
  fi

  scan_directory "$scan_dir"
}

# Run main function
main "$@"
