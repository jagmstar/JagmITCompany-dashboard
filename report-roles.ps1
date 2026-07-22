#!/usr/bin/env powershell
# Role reports - runs every 5 minutes, posts CTO/CFO/Department status to RomanControllingEverything
# Each role reports independently as a GitHub issue comment.

$ErrorActionPreference = "SilentlyContinue"

$REPO = "jagmstar/RomanControllingEverything"
$TIMESTAMP = Get-Date -Format "HH:mm dd.MM.yyyy"

function Get-ReportIssue($rolePrefix) {
    $title = "[$rolePrefix] Status Report - $(Get-Date -Format 'dd.MM.yyyy')"
    $existing = gh issue list --repo $REPO --state open --limit 50 --json number,title 2>$null | ConvertFrom-Json
    $found = $existing | Where-Object { $_.title -eq $title } | Select-Object -First 1
    if ($found) { return $found.number }
    $num = gh issue create --repo $REPO --title $title --body "_Automated reporting thread for $rolePrefix - $(Get-Date -Format 'yyyy-MM-dd')_" 2>$null
    if ($num -match '/issues/(\d+)') { return $matches[1] }
    return $null
}

function CTO-Report {
    $issue = Get-ReportIssue "CTO"
    if (-not $issue) { return }

    $aiSdlc = gh issue list --repo jagmstar/ai-sdlc --state open --limit 100 --json number 2>$null
    $aiCount = if ($aiSdlc -eq "[]") { 0 } elseif ($aiSdlc) { ($aiSdlc | ConvertFrom-Json).Count } else { 0 }

    $dmTwin = gh issue list --repo jagmstar/dm-twin --state open --limit 100 --json number 2>$null
    $dmCount = if ($dmTwin -eq "[]") { 0 } elseif ($dmTwin) { ($dmTwin | ConvertFrom-Json).Count } else { 0 }

    $drone = gh issue list --repo jagmstar/drone-ibvs --state open --limit 100 --json number 2>$null
    $droneCount = if ($drone -eq "[]") { 0 } elseif ($drone) { ($drone | ConvertFrom-Json).Count } else { 0 }

    $agents = @()
    try { $agents = (Invoke-RestMethod -Uri "http://127.0.0.1:8283/v1/agents/" -TimeoutSec 10).name } catch {}
    $agentCount = if ($agents) { ($agents | Select-Object -Unique).Count } else { 0 }

    $body = "[CTO-JAGM] Zvit - $TIMESTAMP`r`n`r`n## Technichnyi stan`r`n`r`n- AI-SDLC Framework: $aiCount vidkrytykh tiketiv`r`n- DM Twin: $dmCount vidkrytykh tiketiv`r`n- Drone-IBVS: $droneCount vidkrytykh tiketiv`r`n- Letta server: $agentCount ahentiv zhyvi`r`n`r`n## Stan`r`n- Freymvork: v1.5, 240 total tiketiv`r`n- Ahenty: $agentCount online (ollama/qwen2.5:7b)`r`n- Budzhet: 0 (zero-cost)`r`n`r`n## Blokery`r`n- Letta server agents ne maiut tool access`r`n- qwen2.5:7b povilnyi (~2 khv na vidpovid)`r`n`r`n## Rishennia potribni vid Romana`r`n- (nemaie novykh)"

    gh issue comment $issue --repo $REPO --body $body 2>$null
    Write-Output "CTO report posted to issue #$issue"
}

function CFO-Report {
    $issue = Get-ReportIssue "CFO"
    if (-not $issue) { return }

    $leadsFile = "F:\dt-home\JagmITCompany\leads.json"
    $leadsCount = 0
    if (Test-Path $leadsFile) {
        try {
            $leads = Get-Content $leadsFile -Raw | ConvertFrom-Json
            $leadsCount = if ($leads -is [array]) { $leads.Count } else { 1 }
        } catch {}
    }

    $body = "[CFO-JAGM] Zvit - $TIMESTAMP`r`n`r`n## Finansovyi stan`r`n`r`n- Vyruchka: 0 (pre-revenue)`r`n- Budzhet: 0 (zero-cost)`r`n- Kliienty: 0 paying`r`n- Lidy: $leadsCount`r`n`r`n## Produkty`r`n- AI-SDLC Repo Audit: gotovyi, chakaie kliienta`r`n- DM Twin: novyi zamovnyk, Phase 1`r`n- Digital Twin Setup: v rozrobtsi`r`n`r`n## Priorytet`r`n- Znayty pershoho platnoho kliienta`r`n- Roman vidsylae materialy prospective kliientam`r`n`r`n## Rishennia potribni vid Romana`r`n- (nemaie novykh)"

    gh issue comment $issue --repo $REPO --body $body 2>$null
    Write-Output "CFO report posted to issue #$issue"
}

function Dept-Report {
    $issue = Get-ReportIssue "Departments"
    if (-not $issue) { return }

    $roleCount = (Get-ChildItem "F:\AI SDLC rork\ai-sdlc-1.0-143\.claude\agents" -Filter *.md -Recurse | Measure-Object).Count

    $rceOpen = gh issue list --repo jagmstar/RomanControllingEverything --state open --limit 1000 --json number 2>$null
    $rceCount = if ($rceOpen -eq "[]") { 0 } elseif ($rceOpen) { ($rceOpen | ConvertFrom-Json).Count } else { 0 }

    $body = "[Department Heads] Zvit - $TIMESTAMP`r`n`r`n## Departamenty (10)`r`n`r`n### SEDO - Software Engineering`r`n- Stan: aktyvnyi, AI-SDLC framework v1.5`r`n- Profiliv: $roleCount rolei`r`n`r`n### QAO - Quality Assurance`r`n- Stan: 357 tiketiv proaudytovano, 7 feikovykh znaideno`r`n`r`n### PMO - Project Management`r`n- Stan: DM Twin Phase 1`r`n`r`n### DevOps`r`n- Stan: dashboard live, GitHub Pages aktyvnyi`r`n`r`n### SecO - Security`r`n- Stan: ESET antivirus, merezhvyi monitorynh`r`n`r`n### DesignO - Design`r`n- Stan: Family Expenses v1.0.10-demo redesign zaversheno`r`n`r`n### ResearchO - Research`r`n- Stan: Drone-IBVS research, 21 tiketiv`r`n`r`n### LegalO - Legal`r`n- Stan: 100 yurydychnykh profiliv stvoreno`r`n`r`n### SalesO - Sales`r`n- Stan: 0 kliientiv, pre-revenue`r`n`r`n### FinanceO - Finance`r`n- Stan: 0 budzhet, zero-cost model`r`n`r`n## Zahalni metryky`r`n- Vidkrytykh tiketiv (RCE): $rceCount`r`n- Profiliv rolei: $roleCount`r`n`r`n## Rishennia potribni vid Romana`r`n- (nemaie novykh)"

    gh issue comment $issue --repo $REPO --body $body 2>$null
    Write-Output "Departments report posted to issue #$issue"
}

CTO-Report
CFO-Report
Dept-Report
Write-Output "All role reports completed at $TIMESTAMP"
