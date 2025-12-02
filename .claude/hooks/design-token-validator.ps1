# Design Token Validator Hook (PowerShell)
# Validates Write/Edit operations for hardcoded design values
# Behavior: Block with remediation guidance

param()

$ErrorActionPreference = "Stop"

# Read input from stdin
$inputJson = [Console]::In.ReadToEnd()

try {
    $input = $inputJson | ConvertFrom-Json
} catch {
    Write-Output '{"decision": "approve"}'
    exit 0
}

$filePath = $input.tool_input.file_path
$toolName = $input.tool_name

# Get content based on tool type
if ($toolName -eq "Write") {
    $content = $input.tool_input.content
} elseif ($toolName -eq "Edit") {
    $content = $input.tool_input.new_string
} else {
    Write-Output '{"decision": "approve"}'
    exit 0
}

# Skip if no file path
if (-not $filePath) {
    Write-Output '{"decision": "approve"}'
    exit 0
}

# Only validate style-related files
$styleExtensions = @('.css', '.scss', '.sass', '.less', '.tsx', '.jsx', '.ts', '.js', '.vue', '.svelte')
$ext = [System.IO.Path]::GetExtension($filePath)

if ($ext -notin $styleExtensions) {
    Write-Output '{"decision": "approve"}'
    exit 0
}

# Skip node_modules, dist, build directories
if ($filePath -match '(node_modules|dist|build|\.next|\.cache|\.git)[/\\]') {
    Write-Output '{"decision": "approve"}'
    exit 0
}

# Skip test files
if ($filePath -match '\.(test|spec)\.(tsx?|jsx?)$') {
    Write-Output '{"decision": "approve"}'
    exit 0
}

# Skip if no content
if (-not $content) {
    Write-Output '{"decision": "approve"}'
    exit 0
}

$violations = @()
$fixes = @()

# 1. Detect hardcoded hex colors
$hexMatches = [regex]::Matches($content, '#[0-9a-fA-F]{3,8}\b')
foreach ($match in $hexMatches) {
    $violations += "Hardcoded hex color: $($match.Value)"
    $fixes += "Use token: var(--brand-primary), var(--neutral-900), etc."
}

# 2. Detect rgb/rgba/hsl colors
$colorFuncMatches = [regex]::Matches($content, '(rgb|rgba|hsl|hsla)\s*\([^)]+\)')
foreach ($match in $colorFuncMatches) {
    $violations += "Hardcoded color function: $($match.Value)"
    $fixes += "Use token: var(--semantic-success), var(--semantic-error), etc."
}

# 3. Detect arbitrary Tailwind values
$arbMatches = [regex]::Matches($content, '(bg|text|border|p|m|w|h|gap|space|rounded|shadow)-\[[^\]]+\]')
foreach ($match in $arbMatches) {
    $violations += "Tailwind arbitrary value: $($match.Value)"

    if ($match.Value -match '^(bg|text|border)-') {
        $fixes += "Use Tailwind token: bg-brand-primary, text-neutral-900, etc."
    } elseif ($match.Value -match '^(p|m|gap|space|w|h)-') {
        $fixes += "Use spacing class: p-4 (16px), gap-6 (24px), etc."
    } else {
        $fixes += "Use design token class instead of arbitrary value"
    }
}

# Return approve if no violations
if ($violations.Count -eq 0) {
    Write-Output '{"decision": "approve"}'
    exit 0
}

# Build violation message
$maxShow = 5
$total = $violations.Count

$message = "Design Token Violations ($total found):\n\n"

for ($i = 0; $i -lt [Math]::Min($maxShow, $total); $i++) {
    $message += "$($i + 1). $($violations[$i])\n"
    $message += "   Fix: $($fixes[$i])\n\n"
}

if ($total -gt $maxShow) {
    $message += "... and $($total - $maxShow) more violations\n"
}

$message += "\n**Token Reference:**\n"
$message += "- Colors: var(--brand-primary), var(--semantic-error), var(--neutral-900)\n"
$message += "- Spacing: var(--space-1)=4px, var(--space-4)=16px, Tailwind p-4, gap-6\n"
$message += "- See: design/systems/tokens.css for full list"

# Escape for JSON
$escapedMessage = $message -replace '"', '\"' -replace "`n", '\n' -replace "`r", ''

Write-Output "{`"decision`": `"block`", `"reason`": `"$escapedMessage`"}"
