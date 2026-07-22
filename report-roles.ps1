#!/usr/bin/env pwsh
# Role reports — runs every 5 minutes, posts CTO/CFO/Department status to RomanControllingEverything
# Each role reports independently as a GitHub issue comment.

$ErrorActionPreference = "SilentlyContinue"

$REPO = "jagmstar/RomanControllingEverything"
$TIMESTAMP = Get-Date -Format "HH:mm dd.MM.yyyy"

# --- Helper: find or create the daily reporting issue ---
function Get-ReportIssue($rolePrefix) {
    $title = "[$rolePrefix] Status Report — $(Get-Date -Format 'dd.MM.yyyy')"
    $existing = gh issue list --repo $REPO --state open --limit 50 --json number,title 2>$null | ConvertFrom-Json
    $found = $existing | Where-Object { $_.title -eq $title } | Select-Object -First 1
    if ($found) { return $found.number }
    $num = gh issue create --repo $REPO --title $title --body "_Automated reporting thread for $rolePrefix — $(Get-Date -Format 'yyyy-MM-dd')_" 2>$null
    # Parse issue number from gh create output (it outputs URL)
    if ($num -match '/issues/(\d+)') { return $matches[1] }
    return $null
}

# --- CTO Report ---
function CTO-Report {
    $issue = Get-ReportIssue "CTO"
    if (-not $issue) { return }

    $aiSdlc = gh issue list --repo jagmstar/ai-sdlc --state open --limit 100 --json number 2>$null
    $aiCount = if ($aiSdlc -eq "[]") { 0 } elseif ($aiSdlc) { ($aiSdlc | ConvertFrom-Json).Count } else { 0 }

    $dmTwin = gh issue list --repo jagmstar/dm-twin --state open --limit 100 --json number 2>$null
    $dmCount = if ($dmTwin -eq "[]") { 0 } elseif ($dmTwin) { ($dmTwin | ConvertFrom-Json).Count } else { 0 }

    $drone = gh issue list --repo jagmstar/drone-ibvs --state open --limit 100 --json number 2>$null
    $droneCount = if ($drone -eq "[]") { 0 } elseif ($drone) { ($drone | ConvertFrom-Json).Count } else { 0 }

    $agents = try { (Invoke-RestMethod -Uri "http://127.0.0.1:8283/v1/agents/" -TimeoutSec 10).name } catch { @() }
    $agentCount = if ($agents) { ($agents | Select-Object -Unique).Count } else { 0 }

    $body = @"
[CTO-JAGM] Звіт — $TIMESTAMP

## Технічний стан

- AI-SDLC Framework: $aiCount відкритих тікетів
- DM Twin: $dmCount відкритих тікетів
- Drone-IBVS: $droneCount відкритих тікетів
- Letta сервер: $agentCount агентів живі

## Стан
- Фреймворк: v1.5, 240 total тікетів
- Агенти: $agentCount онлайн (ollama/qwen2.5:7b)
- Бюджет: \$0 (zero-cost)

## Блокери
- Letta server agents не мають tool access (no Bash/Read/Write)
- qwen2.5:7b повільний (~2 хв на відповідь)

## Рішення потрібні від Романа
- (немає нових)
"@

    gh issue comment $issue --repo $REPO --body $body 2>$null
    Write-Output "CTO report posted to issue #$issue"
}

# --- CFO Report ---
function CFO-Report {
    $issue = Get-ReportIssue "CFO"
    if (-not $issue) { return }

    $leadsFile = "F:\dt-home\JagmITCompany\leads.json"
    $leadsCount = 0
    if (Test-Path $leadsFile) {
        $leads = Get-Content $leadsFile -Raw | ConvertFrom-Json
        $leadsCount = if ($leads -is [array]) { $leads.Count } else { 1 }
    }

    $body = @"
[CFO-JAGM] Звіт — $TIMESTAMP

## Фінансовий стан

- Виручка: \$0 (pre-revenue)
- Бюджет: \$0 (zero-cost)
- Клієнти: 0 paying
- Ліди: $leadsCount

## Продукти
- AI-SDLC Repo Audit: готовий, чекає клієнта
- DM Twin: новий замовник, Phase 1
- Digital Twin Setup: в розробці

## Пріоритет
- Знайти першого платного клієнта
- Roman відсилає матеріали prospective клієнтам

## Рішення потрібні від Романа
- (немає нових)
"@

    gh issue comment $issue --repo $REPO --body $body 2>$null
    Write-Output "CFO report posted to issue #$issue"
}

# --- Department Heads Report ---
function Dept-Report {
    $issue = Get-ReportIssue "Departments"
    if (-not $issue) { return }

    $roleCount = (Get-ChildItem "F:\AI SDLC rork\ai-sdlc-1.0-143\.claude\agents" -Filter *.md -Recurse | Measure-Object).Count

    $familyOpen = gh issue list --repo jagmstar/family-expenses --state open --limit 100 --json number 2>$null
    $famCount = if ($familyOpen -eq "[]") { 0 } elseif ($familyOpen) { ($familyOpen | ConvertFrom-Json).Count } else { 0 }

    $rceOpen = gh issue list --repo jagmstar/RomanControllingEverything --state open --limit 1000 --json number 2>$null
    $rceCount = if ($rceOpen -eq "[]") { 0 } elseif ($rceOpen) { ($rceOpen | ConvertFrom-Json).Count } else { 0 }

    $body = @"
[Department Heads] Звіт — $TIMESTAMP

## Департаменти (10)

### SEDO — Software Engineering
- Стан: активний, AI-SDLC framework v1.5
- Профілів: $roleCount ролей

### QAO — Quality Assurance
- Стан: 357 тікетів проаудитовано, 7 фейкових знайдено

### PMO — Project Management
- Стан: DM Twin Phase 1, 2 відкритих тікетів

### DevOps
- Стан: dashboard live, GitHub Pages активний

### SecO — Security
- Стан: ESET antivirus, мережевий моніторинг

### DesignO — Design
- Стан: Family Expenses v1.0.10-demo redesign завершено

### ResearchO — Research
- Стан: Drone-IBVS research, 21 тікетів

### LegalO — Legal
- Стан: 100 юридичних профілів створено (20 юрисдикцій)

### SalesO — Sales
- Стан: 0 клієнтів, $leadsCount лідів, pre-revenue

### FinanceO — Finance
- Стан: \$0 бюджет, zero-cost модель

## Загальні метрики
- Відкритих тікетів (RCE): $rceCount
- Профілів ролей: $roleCount

## Рішення потрібні від Романа
- (немає нових)
"@

    gh issue comment $issue --repo $REPO --body $body 2>$null
    Write-Output "Departments report posted to issue #$issue"
}

# --- Run all reports ---
CTO-Report
CFO-Report
Dept-Report
Write-Output "All role reports completed at $TIMESTAMP"
