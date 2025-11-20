<#
.SYNOPSIS
    Load user preferences from config file with fallback to defaults

.DESCRIPTION
    Reads .spec-flow/config/user-preferences.yaml and returns preference object.
    Falls back to schema defaults if file doesn't exist or is invalid.

.PARAMETER Command
    Command name to load preferences for (epic, tasks, init-project, run-prompt)

.PARAMETER PreferencePath
    Optional path to preferences file (defaults to .spec-flow/config/user-preferences.yaml)

.EXAMPLE
    $prefs = & .\.spec-flow\scripts\utils\load-preferences.ps1 -Command "epic"
    $prefs.commands.epic.default_mode  # Returns: "interactive" or "auto"

.NOTES
    Returns hashtable with structure matching user-preferences-schema.yaml
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Command,

    [Parameter(Mandatory=$false)]
    [string]$PreferencePath = ".spec-flow/config/user-preferences.yaml"
)

# Default preferences (matches schema defaults)
$defaultPreferences = @{
    commands = @{
        epic = @{
            default_mode = "interactive"
        }
        tasks = @{
            default_mode = "standard"
        }
        "init-project" = @{
            default_mode = "interactive"
            include_design = $false
        }
        "run-prompt" = @{
            default_strategy = "auto-detect"
        }
    }
    automation = @{
        auto_approve_minor_changes = $false
        ci_mode_default = $false
    }
    ui = @{
        show_usage_stats = $true
        recommend_last_used = $true
    }
}

# Check if preferences file exists
if (-not (Test-Path $PreferencePath)) {
    Write-Verbose "Preferences file not found at $PreferencePath, using defaults"
    return $defaultPreferences
}

try {
    # Read YAML file
    $yamlContent = Get-Content -Path $PreferencePath -Raw

    # Parse YAML to PowerShell object
    # Note: This is a simple parser. For production, consider using powershell-yaml module
    $preferences = @{}

    # Parse commands section
    if ($yamlContent -match 'commands:\s*\n((?:  \w+:[\s\S]*?(?=\n\w+:|$))*)') {
        $commandsSection = $matches[1]
        $preferences['commands'] = @{}

        # Parse each command
        if ($commandsSection -match 'epic:\s*\n\s+default_mode:\s+(\w+)') {
            $preferences['commands']['epic'] = @{ default_mode = $matches[1] }
        }
        if ($commandsSection -match 'tasks:\s*\n\s+default_mode:\s+(\w+)') {
            $preferences['commands']['tasks'] = @{ default_mode = $matches[1] }
        }
        if ($commandsSection -match 'init-project:\s*\n\s+default_mode:\s+(\w+)\s*\n\s+include_design:\s+(true|false)') {
            $preferences['commands']['init-project'] = @{
                default_mode = $matches[1]
                include_design = ($matches[2] -eq 'true')
            }
        }
        if ($commandsSection -match 'run-prompt:\s*\n\s+default_strategy:\s+([\w-]+)') {
            $preferences['commands']['run-prompt'] = @{ default_strategy = $matches[1] }
        }
    }

    # Parse automation section
    if ($yamlContent -match 'automation:\s*\n((?:  \w+:[\s\S]*?(?=\n\w+:|$))*)') {
        $automationSection = $matches[1]
        $preferences['automation'] = @{}

        if ($automationSection -match 'auto_approve_minor_changes:\s+(true|false)') {
            $preferences['automation']['auto_approve_minor_changes'] = ($matches[1] -eq 'true')
        }
        if ($automationSection -match 'ci_mode_default:\s+(true|false)') {
            $preferences['automation']['ci_mode_default'] = ($matches[1] -eq 'true')
        }
    }

    # Parse ui section
    if ($yamlContent -match 'ui:\s*\n((?:  \w+:[\s\S]*?(?=\n\w+:|$))*)') {
        $uiSection = $matches[1]
        $preferences['ui'] = @{}

        if ($uiSection -match 'show_usage_stats:\s+(true|false)') {
            $preferences['ui']['show_usage_stats'] = ($matches[1] -eq 'true')
        }
        if ($uiSection -match 'recommend_last_used:\s+(true|false)') {
            $preferences['ui']['recommend_last_used'] = ($matches[1] -eq 'true')
        }
    }

    # Merge with defaults (fill in any missing values)
    $mergedPreferences = $defaultPreferences.Clone()

    foreach ($key in $preferences.Keys) {
        if ($preferences[$key] -is [hashtable]) {
            foreach ($subKey in $preferences[$key].Keys) {
                if ($mergedPreferences[$key].ContainsKey($subKey)) {
                    $mergedPreferences[$key][$subKey] = $preferences[$key][$subKey]
                }
            }
        }
    }

    return $mergedPreferences

} catch {
    Write-Warning "Failed to parse preferences file: $($_.Exception.Message)"
    Write-Warning "Using default preferences"
    return $defaultPreferences
}
