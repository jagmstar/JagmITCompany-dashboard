#!/usr/bin/env powershell
# Dashboard auto-refresh: runs fetch-data.py, commits and pushes refreshed dashboard data.
$ErrorActionPreference = "Stop"
$repoDir = $PSScriptRoot

Set-Location $repoDir
python fetch-data.py
if ($LASTEXITCODE -ne 0) {
    throw "fetch-data.py failed with exit code $LASTEXITCODE"
}

git add data.json live-status.json
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Output "No changes at $(Get-Date -Format 'HH:mm')"
    exit 0
}

git config user.name 'github-actions[bot]'
git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
git commit -m "auto: refresh dashboard data - $(Get-Date -Format 'HH:mm dd.MM')"
git push origin master
Write-Output "Dashboard refreshed and pushed at $(Get-Date -Format 'HH:mm')"
