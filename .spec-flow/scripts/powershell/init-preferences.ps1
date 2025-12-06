# init-preferences.ps1 - Interactive wizard for user preferences configuration
#
# Generates or updates .spec-flow/config/user-preferences.yaml through a guided
# questionnaire that covers all configurable aspects of the Spec-Flow workflow.
#
# Usage:
#   .\init-preferences.ps1 [OPTIONS]
#
# Options:
#   -Reset              Reset preferences to defaults before running wizard
#   -Section NAME       Only configure a specific section
#   -NonInteractive     Use default values without prompts
#   -Help               Show this help message

param(
    [switch]$Reset,
    [string]$Section = "",
    [switch]$NonInteractive,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Script paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ScriptDir))
$ConfigDir = Join-Path $RepoRoot ".spec-flow\config"
$PrefFile = Join-Path $ConfigDir "user-preferences.yaml"

# Show help
if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

# Preference storage
$Prefs = @{}

# Initialize defaults
function Initialize-Defaults {
    # Commands
    $script:Prefs["feature_default_mode"] = "interactive"
    $script:Prefs["feature_skip_mode_prompt"] = "false"
    $script:Prefs["epic_default_mode"] = "interactive"
    $script:Prefs["epic_skip_mode_prompt"] = "false"
    $script:Prefs["tasks_default_mode"] = "standard"
    $script:Prefs["init_project_default_mode"] = "interactive"
    $script:Prefs["init_project_include_design"] = "false"
    $script:Prefs["run_prompt_default_strategy"] = "auto-detect"

    # Automation
    $script:Prefs["auto_approve_minor_changes"] = "false"
    $script:Prefs["ci_mode_default"] = "false"

    # UI
    $script:Prefs["show_usage_stats"] = "true"
    $script:Prefs["recommend_last_used"] = "true"

    # Worktrees
    $script:Prefs["worktrees_auto_create"] = "false"
    $script:Prefs["worktrees_cleanup_on_finalize"] = "true"

    # Studio
    $script:Prefs["studio_auto_continue"] = "false"
    $script:Prefs["studio_default_agents"] = "3"

    # Prototype
    $script:Prefs["prototype_git_persistence"] = "ask"

    # E2E Visual
    $script:Prefs["e2e_visual_enabled"] = "true"
    $script:Prefs["e2e_visual_failure_mode"] = "blocking"
    $script:Prefs["e2e_visual_threshold"] = "0.1"
    $script:Prefs["e2e_visual_auto_commit_baselines"] = "true"

    # Learning
    $script:Prefs["learning_enabled"] = "true"
    $script:Prefs["learning_auto_apply_low_risk"] = "true"
    $script:Prefs["learning_require_approval_high_risk"] = "true"
    $script:Prefs["learning_claude_md_optimization"] = "true"

    # Migrations
    $script:Prefs["migrations_strictness"] = "blocking"
    $script:Prefs["migrations_auto_generate_plan"] = "true"
}

# Load existing preferences
function Import-ExistingPrefs {
    if (-not (Test-Path $PrefFile)) {
        return
    }

    Write-Host "`u{2139} Loading existing preferences..." -ForegroundColor Blue

    $yamlContent = Get-Content $PrefFile -Raw

    # Parse values using regex (simple YAML parsing)
    $patterns = @{
        "feature_default_mode"        = "feature:\s*\n\s*default_mode:\s*(\w+)"
        "feature_skip_mode_prompt"    = "feature:\s*\n\s*default_mode:\s*\w+\s*\n\s*skip_mode_prompt:\s*(\w+)"
        "epic_default_mode"           = "epic:\s*\n\s*default_mode:\s*(\w+)"
        "tasks_default_mode"          = "tasks:\s*\n\s*default_mode:\s*(\w+)"
        "init_project_include_design" = "init-project:\s*\n\s*default_mode:\s*\w+\s*\n\s*include_design:\s*(\w+)"
        "run_prompt_default_strategy" = "run-prompt:\s*\n\s*default_strategy:\s*([\w-]+)"
        "auto_approve_minor_changes"  = "auto_approve_minor_changes:\s*(\w+)"
        "ci_mode_default"             = "ci_mode_default:\s*(\w+)"
        "show_usage_stats"            = "show_usage_stats:\s*(\w+)"
        "recommend_last_used"         = "recommend_last_used:\s*(\w+)"
        "worktrees_auto_create"       = "worktrees:\s*\n\s*auto_create:\s*(\w+)"
        "studio_auto_continue"        = "studio:\s*\n\s*auto_continue:\s*(\w+)"
        "studio_default_agents"       = "studio:\s*\n\s*auto_continue:\s*\w+\s*\n\s*default_agents:\s*(\d+)"
        "e2e_visual_enabled"          = "e2e_visual:\s*\n\s*enabled:\s*(\w+)"
        "e2e_visual_failure_mode"     = "e2e_visual:\s*\n\s*enabled:\s*\w+\s*\n\s*failure_mode:\s*(\w+)"
        "learning_enabled"            = "learning:\s*\n\s*enabled:\s*(\w+)"
        "migrations_strictness"       = "migrations:\s*\n\s*strictness:\s*(\w+)"
    }

    foreach ($key in $patterns.Keys) {
        if ($yamlContent -match $patterns[$key]) {
            $script:Prefs[$key] = $Matches[1]
        }
    }

    Write-Host "`u{2713} Existing preferences loaded" -ForegroundColor Green
}

# Ask choice question
function Ask-Choice {
    param(
        [string]$Question,
        [string]$Key,
        [string[]]$Options
    )

    Write-Host ""
    Write-Host $Question -ForegroundColor White

    $current = $script:Prefs[$Key]
    $idx = 1
    foreach ($opt in $Options) {
        $marker = ""
        if ($opt -eq $current) {
            $marker = " (current)"
            Write-Host "  $idx. $opt" -NoNewline
            Write-Host $marker -ForegroundColor Green
        }
        else {
            Write-Host "  $idx. $opt"
        }
        $idx++
    }

    if ($NonInteractive) {
        Write-Host "  -> Using default: $current" -ForegroundColor Cyan
        return
    }

    $choice = Read-Host "Choice (1-$($Options.Length), Enter to keep current)"
    if ($choice -match '^\d+$') {
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $Options.Length) {
            $script:Prefs[$Key] = $Options[$index]
        }
    }
}

# Ask boolean question
function Ask-Bool {
    param(
        [string]$Question,
        [string]$Key,
        [string]$Description = ""
    )

    Write-Host ""
    Write-Host $Question -ForegroundColor White
    if ($Description) {
        Write-Host "  $Description" -ForegroundColor Cyan
    }

    $current = $script:Prefs[$Key]
    $defaultHint = "y"
    if ($current -eq "false") { $defaultHint = "n" }

    if ($NonInteractive) {
        Write-Host "  -> Using default: $current" -ForegroundColor Cyan
        return
    }

    $answer = Read-Host "y/n [$defaultHint]"
    switch ($answer.ToLower()) {
        "y" { $script:Prefs[$Key] = "true" }
        "yes" { $script:Prefs[$Key] = "true" }
        "n" { $script:Prefs[$Key] = "false" }
        "no" { $script:Prefs[$Key] = "false" }
    }
}

# Ask number question
function Ask-Number {
    param(
        [string]$Question,
        [string]$Key,
        [int]$Min,
        [int]$Max
    )

    Write-Host ""
    Write-Host $Question -ForegroundColor White

    $current = $script:Prefs[$Key]

    if ($NonInteractive) {
        Write-Host "  -> Using default: $current" -ForegroundColor Cyan
        return
    }

    $answer = Read-Host "Enter number ($Min-$Max) [$current]"
    if ($answer -match '^\d+$') {
        $num = [int]$answer
        if ($num -ge $Min -and $num -le $Max) {
            $script:Prefs[$Key] = $num.ToString()
        }
        else {
            Write-Host "`u{26A0} Value out of range, keeping $current" -ForegroundColor Yellow
        }
    }
}

# Section: Commands
function Configure-Commands {
    Write-Host "`n`u{2501}`u{2501} COMMAND DEFAULTS `u{2501}`u{2501}" -ForegroundColor Cyan

    Ask-Choice "Q1. Default mode for /feature command?" "feature_default_mode" @("auto", "interactive")
    Ask-Bool "Q2. Skip mode selection prompt for /feature?" "feature_skip_mode_prompt" "When true, uses default_mode without asking every time"
    Ask-Choice "Q3. Default mode for /epic command?" "epic_default_mode" @("auto", "interactive")
    Ask-Bool "Q4. Skip mode selection prompt for /epic?" "epic_skip_mode_prompt" "When true, uses default_mode without asking every time"
    Ask-Choice "Q5. Default mode for /tasks command?" "tasks_default_mode" @("standard", "ui-first")
    Ask-Bool "Q6. Auto-include design system with /init-project?" "init_project_include_design" "Equivalent to always using --with-design flag"
    Ask-Choice "Q7. Default strategy for /run-prompt?" "run_prompt_default_strategy" @("auto-detect", "parallel", "sequential")
}

# Section: Automation
function Configure-Automation {
    Write-Host "`n`u{2501}`u{2501} AUTOMATION SETTINGS `u{2501}`u{2501}" -ForegroundColor Cyan

    Ask-Bool "Q8. Auto-approve minor changes (formatting, comments)?" "auto_approve_minor_changes" "Skips confirmation prompts for trivial changes"
    Ask-Bool "Q9. Default to CI-friendly behavior?" "ci_mode_default" "Non-interactive mode, assumes --no-input"
}

# Section: UI
function Configure-UI {
    Write-Host "`n`u{2501}`u{2501} USER INTERFACE `u{2501}`u{2501}" -ForegroundColor Cyan

    Ask-Bool "Q10. Show command usage statistics in prompts?" "show_usage_stats" "e.g., 'auto (used 8/10 times)'"
    Ask-Bool "Q11. Mark last-used option with star?" "recommend_last_used" "Highlights your previous choice"
}

# Section: Worktrees
function Configure-Worktrees {
    Write-Host "`n`u{2501}`u{2501} GIT WORKTREES (Parallel Development) `u{2501}`u{2501}" -ForegroundColor Cyan

    Ask-Bool "Q12. Auto-create git worktrees for epics/features?" "worktrees_auto_create" "Enables parallel development with isolated directories"
    Ask-Bool "Q13. Auto-cleanup worktrees after /finalize?" "worktrees_cleanup_on_finalize" "Removes worktree directories when feature ships"
}

# Section: Studio
function Configure-Studio {
    Write-Host "`n`u{2501}`u{2501} DEV STUDIO (Parallel AI Development) `u{2501}`u{2501}" -ForegroundColor Cyan

    Ask-Bool "Q14. Auto-continue to next issue after /finalize?" "studio_auto_continue" "Skips 'Pick up next issue?' prompt"
    Ask-Number "Q15. Default number of agent worktrees for /studio?" "studio_default_agents" 1 10
}

# Section: Quality Gates
function Configure-Quality {
    Write-Host "`n`u{2501}`u{2501} QUALITY GATES `u{2501}`u{2501}" -ForegroundColor Cyan

    Ask-Bool "Q16. Enable E2E and visual regression testing?" "e2e_visual_enabled" "Part of /optimize quality gates"
    Ask-Choice "Q17. How to handle E2E/visual test failures?" "e2e_visual_failure_mode" @("blocking", "warning")
}

# Write preferences to file
function Write-Preferences {
    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }

    $content = @"
# User Preferences for Spec-Flow
# Generated by: init-preferences.ps1
# Last updated: $(Get-Date -Format "yyyy-MM-dd")
#
# Documentation: .spec-flow/config/user-preferences-schema.yaml

commands:
  feature:
    default_mode: $($script:Prefs["feature_default_mode"])
    skip_mode_prompt: $($script:Prefs["feature_skip_mode_prompt"])

  epic:
    default_mode: $($script:Prefs["epic_default_mode"])
    skip_mode_prompt: $($script:Prefs["epic_skip_mode_prompt"])

  tasks:
    default_mode: $($script:Prefs["tasks_default_mode"])

  init-project:
    default_mode: $($script:Prefs["init_project_default_mode"])
    include_design: $($script:Prefs["init_project_include_design"])

  run-prompt:
    default_strategy: $($script:Prefs["run_prompt_default_strategy"])

automation:
  auto_approve_minor_changes: $($script:Prefs["auto_approve_minor_changes"])
  ci_mode_default: $($script:Prefs["ci_mode_default"])

ui:
  show_usage_stats: $($script:Prefs["show_usage_stats"])
  recommend_last_used: $($script:Prefs["recommend_last_used"])

worktrees:
  auto_create: $($script:Prefs["worktrees_auto_create"])
  cleanup_on_finalize: $($script:Prefs["worktrees_cleanup_on_finalize"])

studio:
  auto_continue: $($script:Prefs["studio_auto_continue"])
  default_agents: $($script:Prefs["studio_default_agents"])

prototype:
  git_persistence: $($script:Prefs["prototype_git_persistence"])

e2e_visual:
  enabled: $($script:Prefs["e2e_visual_enabled"])
  failure_mode: $($script:Prefs["e2e_visual_failure_mode"])
  threshold: $($script:Prefs["e2e_visual_threshold"])
  auto_commit_baselines: $($script:Prefs["e2e_visual_auto_commit_baselines"])
  viewports:
    - name: desktop
      width: 1280
      height: 720
    - name: mobile
      width: 375
      height: 667

learning:
  enabled: $($script:Prefs["learning_enabled"])
  auto_apply_low_risk: $($script:Prefs["learning_auto_apply_low_risk"])
  require_approval_high_risk: $($script:Prefs["learning_require_approval_high_risk"])
  claude_md_optimization: $($script:Prefs["learning_claude_md_optimization"])
  thresholds:
    pattern_detection_min_occurrences: 3
    statistical_significance: 0.95

migrations:
  strictness: $($script:Prefs["migrations_strictness"])
  detection_threshold: 3
  auto_generate_plan: $($script:Prefs["migrations_auto_generate_plan"])
  llm_analysis_for_low_confidence: true
"@

    $content | Set-Content -Path $PrefFile -Encoding UTF8
    Write-Host "`u{2713} Preferences saved to $PrefFile" -ForegroundColor Green
}

# Main execution
function Main {
    Write-Host ""
    Write-Host "`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}"
    Write-Host "`u{2699} SPEC-FLOW PREFERENCES WIZARD" -ForegroundColor Cyan
    Write-Host "`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}"

    # Initialize defaults
    Initialize-Defaults

    # Handle reset
    if ($Reset) {
        Write-Host "`u{26A0} Resetting preferences to defaults..." -ForegroundColor Yellow
        if (Test-Path $PrefFile) {
            Remove-Item $PrefFile -Force
        }
    }
    else {
        # Load existing preferences
        Import-ExistingPrefs
    }

    # Run wizard sections
    if ([string]::IsNullOrEmpty($Section)) {
        # Full wizard (17 core questions)
        Configure-Commands
        Configure-Automation
        Configure-UI
        Configure-Worktrees
        Configure-Studio
        Configure-Quality
    }
    else {
        # Single section
        switch ($Section.ToLower()) {
            "commands" { Configure-Commands }
            "automation" { Configure-Automation }
            "ui" { Configure-UI }
            "worktrees" { Configure-Worktrees }
            "studio" { Configure-Studio }
            "e2e" { Configure-Quality }
            default {
                Write-Host "`u{2717} Unknown section: $Section" -ForegroundColor Red
                Write-Host "Valid sections: commands, automation, ui, worktrees, studio, e2e" -ForegroundColor Yellow
                exit 1
            }
        }
    }

    # Write preferences
    Write-Preferences

    Write-Host ""
    Write-Host "`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}"
    Write-Host "`u{2705} PREFERENCES CONFIGURED" -ForegroundColor Green
    Write-Host "`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}`u{2501}"
    Write-Host ""
    Write-Host "Config file: $PrefFile"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  - Preferences apply immediately to all commands"
    Write-Host "  - Re-run /init-preferences anytime to change"
    Write-Host "  - Or edit $PrefFile directly"
    Write-Host ""
}

Main

