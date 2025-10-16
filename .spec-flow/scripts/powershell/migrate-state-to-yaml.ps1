<#
.SYNOPSIS
    Migrate workflow-state.json files to YAML format

.DESCRIPTION
    This utility script migrates all existing workflow-state.json files in the
    specs/ directory to the new YAML format (workflow-state.yaml).

    Features:
    - Batch conversion of all features
    - Preserves original JSON files as backups
    - Validates YAML output
    - Reports progress and errors
    - Dry-run mode for testing

.PARAMETER DryRun
    Show what would be migrated without making changes

.PARAMETER Force
    Overwrite existing YAML files

.PARAMETER BackupDir
    Specify backup directory (default: .spec-flow/backups/json-migration-TIMESTAMP)

.PARAMETER SpecsDir
    Specify specs directory (default: specs)

.EXAMPLE
    .\migrate-state-to-yaml.ps1

.EXAMPLE
    .\migrate-state-to-yaml.ps1 -DryRun

.EXAMPLE
    .\migrate-state-to-yaml.ps1 -Force -BackupDir "D:\backups"

.NOTES
    Version: 1.0.0
    Requires: powershell-yaml module (Install-Module -Name powershell-yaml)
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [switch]$Force,

    [Parameter(Mandatory=$false)]
    [string]$BackupDir = ".spec-flow/backups/json-migration-$(Get-Date -Format 'yyyyMMdd-HHmmss')",

    [Parameter(Mandatory=$false)]
    [string]$SpecsDir = "specs"
)

# Check for powershell-yaml module
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host ""
    Write-Host "Error: powershell-yaml module required" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install instructions:" -ForegroundColor Yellow
    Write-Host "  Install-Module -Name powershell-yaml -Scope CurrentUser" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Import-Module powershell-yaml

# Print banner
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "  Workflow State Migration: JSON → YAML" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
    Write-Host ""
}

# Find all workflow-state.json files
Write-Host "🔎 Scanning for workflow-state.json files..." -ForegroundColor Blue
Write-Host ""

if (-not (Test-Path $SpecsDir)) {
    Write-Host "✓ No specs directory found - nothing to migrate" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

$jsonFiles = Get-ChildItem -Path $SpecsDir -Recurse -Filter "workflow-state.json" -File

if ($jsonFiles.Count -eq 0) {
    Write-Host "✓ No JSON files found to migrate" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "All features are already using YAML format or no features exist yet." -ForegroundColor Gray
    exit 0
}

Write-Host "Found $($jsonFiles.Count) file(s) to migrate" -ForegroundColor Green
Write-Host ""

# Statistics
$migrated = 0
$skipped = 0
$failed = 0

# Create backup directory
if (-not $DryRun) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Host "📁 Backup directory: $BackupDir" -ForegroundColor Blue
    Write-Host ""
}

# Migrate each file
foreach ($jsonFile in $jsonFiles) {
    $featureDir = $jsonFile.DirectoryName
    $yamlFile = Join-Path $featureDir "workflow-state.yaml"
    $slug = Split-Path $featureDir -Leaf

    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host "Feature: $slug" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  Source: $($jsonFile.FullName)"
    Write-Host "  Target: $yamlFile"

    # Check if YAML already exists
    if ((Test-Path $yamlFile) -and -not $Force) {
        Write-Host "  ⏭️  SKIPPED - YAML file already exists (use -Force to overwrite)" -ForegroundColor Yellow
        Write-Host ""
        $skipped++
        continue
    }

    if ($DryRun) {
        Write-Host "  ✓ Would migrate" -ForegroundColor Green
        Write-Host ""
        $migrated++
        continue
    }

    # Perform migration
    try {
        # Read JSON and convert to YAML
        $jsonContent = Get-Content $jsonFile.FullName -Raw | ConvertFrom-Json -AsHashtable
        $yamlContent = $jsonContent | ConvertTo-Yaml

        # Write YAML
        $yamlContent | Set-Content -Path $yamlFile -Encoding UTF8

        # Validate YAML
        $testLoad = Get-Content $yamlFile -Raw | ConvertFrom-Yaml

        # Copy JSON to backup
        $backupFile = Join-Path $BackupDir "$slug-workflow-state.json"
        Copy-Item -Path $jsonFile.FullName -Destination $backupFile -Force

        Write-Host "  ✅ MIGRATED" -ForegroundColor Green
        Write-Host "  Backup: $backupFile" -ForegroundColor Gray
        Write-Host ""

        $migrated++
    }
    catch {
        Write-Host "  ❌ FAILED - $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        $failed++
    }
}

# Summary
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "  Migration Summary" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""
Write-Host "✅ Migrated: $migrated" -ForegroundColor Green
Write-Host "⏭️  Skipped:  $skipped" -ForegroundColor Yellow
Write-Host "❌ Failed:   $failed" -ForegroundColor Red
Write-Host ""

if (-not $DryRun -and $migrated -gt 0) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "✓ Migration complete!" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host ""
    Write-Host "Original JSON files have been preserved in:" -ForegroundColor Gray
    Write-Host "  $BackupDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "You can safely delete them after verifying the YAML files work correctly." -ForegroundColor Gray
    Write-Host ""
    Write-Host "To verify, run your workflow commands and check that state is read/written correctly." -ForegroundColor Gray
}

if ($DryRun) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "Dry run complete - no changes made" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Run without -DryRun to perform actual migration." -ForegroundColor Gray
}

Write-Host ""

# Exit with appropriate code
if ($failed -gt 0) {
    exit 1
}

exit 0
