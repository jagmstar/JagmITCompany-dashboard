#!/usr/bin/env pwsh
# Dashboard auto-refresh: runs fetch-data.py, commits and pushes data.json
$ErrorActionPreference = "SilentlyContinue"
$DASH_DIR = "F:\dt-home\JagmITCompany-dashboard"

Set-Location $DASH_DIR
python fetch-data.py 2>$null

git add data.json 2>$null
$hasChanges = $false
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) { $hasChanges = $true }

if ($hasChanges) {
    git commit -m "auto: refresh dashboard data — $(Get-Date -Format 'HH:mm dd.MM')" 2>$null
    git push origin master 2>$null
    Write-Output "Dashboard refreshed and pushed at $(Get-Date -Format 'HH:mm')"
} else {
    Write-Output "No changes at $(Get-Date -Format 'HH:mm')"
}
