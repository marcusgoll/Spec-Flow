# GitHub Setup and Authentication

## Step 1: Initialize GitHub Context

### Bash (macOS/Linux)

```bash
# Source GitHub roadmap manager
source .spec-flow/scripts/bash/github-roadmap-manager.sh

# Check authentication
AUTH_METHOD=$(check_github_auth)

if [ "$AUTH_METHOD" = "none" ]; then
  echo "❌ GitHub authentication required"
  echo ""
  echo "Choose one option:"
  echo "  A) GitHub CLI: gh auth login"
  echo "  B) API Token: export GITHUB_TOKEN=ghp_your_token"
  echo ""
  echo "See: docs/github-roadmap-migration.md"
  exit 1
fi

# Verify repository
REPO=$(get_repo_info)

if [ -z "$REPO" ]; then
  echo "❌ Could not determine repository"
  echo "Ensure you're in a git repository with a GitHub remote"
  exit 1
fi

echo "✅ GitHub authenticated ($AUTH_METHOD)"
echo "✅ Repository: $REPO"
```

### PowerShell (Windows)

```powershell
# Import GitHub roadmap manager
. .\.spec-flow\scripts\powershell\github-roadmap-manager.ps1

# Check authentication
$authMethod = Test-GitHubAuth

if ($authMethod -eq "none") {
  Write-Host "❌ GitHub authentication required" -ForegroundColor Red
  Write-Host ""
  Write-Host "Choose one option:"
  Write-Host "  A) GitHub CLI: gh auth login"
  Write-Host "  B) API Token: `$env:GITHUB_TOKEN = 'ghp_your_token'"
  Write-Host ""
  Write-Host "See: docs/github-roadmap-migration.md"
  exit 1
}

# Verify repository
$repo = Get-RepositoryInfo

if ([string]::IsNullOrEmpty($repo)) {
  Write-Host "❌ Could not determine repository" -ForegroundColor Red
  Write-Host "Ensure you're in a git repository with a GitHub remote"
  exit 1
}

Write-Host "✅ GitHub authenticated ($authMethod)" -ForegroundColor Green
Write-Host "✅ Repository: $repo" -ForegroundColor Green
```

## Authentication Methods

### Method 1: GitHub CLI (Recommended)

```bash
# Install gh CLI
# macOS: brew install gh
# Windows: winget install GitHub.cli
# Linux: See https://github.com/cli/cli#installation

# Authenticate
gh auth login

# Verify
gh auth status
```

**Advantages:**
- No manual token management
- Automatic token refresh
- Full GitHub API access
- Works across multiple repos

### Method 2: Personal Access Token

```bash
# Create token at https://github.com/settings/tokens
# Required scopes: repo, read:org

# Set environment variable
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# For persistent access (add to ~/.bashrc or ~/.zshrc)
echo 'export GITHUB_TOKEN="ghp_xxx..."' >> ~/.bashrc
```

**Advantages:**
- Works in CI/CD environments
- No interactive login required
- Scriptable

## Repository Detection

### get_repo_info() Function

```bash
get_repo_info() {
  # Try to get remote URL
  REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null)

  if [ -z "$REMOTE_URL" ]; then
    return 1
  fi

  # Extract owner/repo from URL
  # Handles both HTTPS and SSH formats
  # https://github.com/owner/repo.git
  # git@github.com:owner/repo.git

  REPO=$(echo "$REMOTE_URL" | sed -E 's/.*[:/]([^/]+\/[^/]+)(\.git)?$/\1/')

  echo "$REPO"
}
```

### PowerShell Version

```powershell
function Get-RepositoryInfo {
  # Try to get remote URL
  $remoteUrl = git config --get remote.origin.url 2>$null

  if ([string]::IsNullOrEmpty($remoteUrl)) {
    return $null
  }

  # Extract owner/repo from URL
  if ($remoteUrl -match '([^/:]+/[^/]+)(\.git)?$') {
    return $matches[1]
  }

  return $null
}
```

## Troubleshooting

### Error: "gh: command not found"

**Solution:** Install GitHub CLI
```bash
# macOS
brew install gh

# Windows
winget install GitHub.cli

# Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

### Error: "Could not determine repository"

**Causes:**
- Not in a git repository
- No remote named "origin"
- Remote URL is not a GitHub URL

**Solutions:**
```bash
# Check if in git repo
git status

# Check remotes
git remote -v

# Add GitHub remote if missing
git remote add origin https://github.com/owner/repo.git
```

### Error: "authentication required"

**Solutions:**
```bash
# Re-authenticate with gh CLI
gh auth logout
gh auth login

# Or set token
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

## Output Format

**Successful initialization:**
```
✅ GitHub authenticated (gh-cli)
✅ Repository: marcusgoll/Spec-Flow
```

**Failed initialization (no auth):**
```
❌ GitHub authentication required

Choose one option:
  A) GitHub CLI: gh auth login
  B) API Token: export GITHUB_TOKEN=ghp_your_token

See: docs/github-roadmap-migration.md
```

**Failed initialization (no repo):**
```
✅ GitHub authenticated (gh-cli)
❌ Could not determine repository
Ensure you're in a git repository with a GitHub remote
```
