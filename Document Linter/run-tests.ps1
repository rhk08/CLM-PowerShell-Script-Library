# ============================
# Run Document Linter Tests
# ============================

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$TestPath = Join-Path $Root "tests"

Write-Host "Running Document Linter Pester tests..."
Write-Host "Test path: $TestPath"

Invoke-Pester -Script @{ Path = $TestPath }

Write-Host "Done."