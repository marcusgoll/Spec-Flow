# Design System Context Injection Hook (PowerShell)
# Injects design token reminder at session start
# Behavior: Warn if tokens missing, remind if present

param()

$ErrorActionPreference = "SilentlyContinue"

# Read input from stdin
$inputJson = [Console]::In.ReadToEnd()

try {
    $input = $inputJson | ConvertFrom-Json
    $cwd = $input.cwd
} catch {
    $cwd = Get-Location
}

if (-not $cwd) {
    $cwd = Get-Location
}

# Check for design tokens
$tokensCss = Join-Path $cwd "design/systems/tokens.css"
$tokensJson = Join-Path $cwd "design/systems/tokens.json"

if ((Test-Path $tokensJson) -or (Test-Path $tokensCss)) {
    # Tokens exist - remind about enforcement
    $context = @"
## Design System Active

PreToolUse hook enforcing design tokens. When writing styles:

**BLOCKED patterns:**
- Hardcoded hex: #3b82f6, #ffffff
- Color functions: rgb(), hsl()
- Arbitrary Tailwind: bg-[#xxx], p-[15px]

**Required patterns:**
- Colors: var(--brand-primary), var(--neutral-900)
- Spacing: var(--space-4), Tailwind p-4, gap-6
- See: design/systems/tokens.css
"@
} else {
    # Tokens missing - warn user
    $context = @"
## Design Tokens Not Configured

Run ``/init-brand-tokens`` before UI work to generate:
- design/systems/tokens.css
- design/systems/tokens.json

This enables design system enforcement hooks.
"@
}

# Escape for JSON
$contextEscaped = $context -replace '"', '\"' -replace "`n", '\n' -replace "`r", ''

# Output SessionStart response
Write-Output "{`"hookSpecificOutput`": {`"hookEventName`": `"SessionStart`", `"additionalContext`": `"$contextEscaped`"}}"
