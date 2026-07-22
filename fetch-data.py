#!/usr/bin/env python3
"""Fetch real company data from GitHub + Letta server and write data.json."""
from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.error import URLError
from urllib.request import Request, urlopen

REPO_ROOT = Path(__file__).resolve().parent
ROLE_PROFILE_DIR = Path(r"F:\AI SDLC rork\ai-sdlc-1.0-143\.claude\agents")
AGENT_URL = "http://127.0.0.1:8283/v1/agents/"
ORG = "jagmstar"

# Company-relevant repos (not personal/legacy repos)
COMPANY_REPOS = [
    "ai-sdlc",
    "drone-ibvs",
    "JagmITCompany",
    "family-expenses",
    "RomanControllingEverything",
    "dm-twin",
    "dm-twin-web",
    "JagmITCompany-dashboard",
]

DEPARTMENTS = [
    {"id": "SEDO", "name": "Software Engineering", "head": "SEDO-Lead"},
    {"id": "QAO", "name": "Quality Assurance", "head": "QAO-Lead"},
    {"id": "PMO", "name": "Project Management", "head": "PMO-Lead"},
    {"id": "DevOps", "name": "DevOps", "head": "DevOps-Lead"},
    {"id": "SecO", "name": "Security", "head": "CISO-JAGM"},
    {"id": "DesignO", "name": "Design", "head": "DesignO-Lead"},
    {"id": "ResearchO", "name": "Research", "head": "ResearchO-Lead"},
    {"id": "LegalO", "name": "Legal", "head": "LegalO-Lead"},
    {"id": "SalesO", "name": "Sales", "head": "CMO-JAGM"},
    {"id": "FinanceO", "name": "Finance", "head": "CFO-JAGM"},
]

C_LEVEL = [
    {"role": "CEO", "agent": "CEO-JAGM", "focus": "Strategy & vision"},
    {"role": "CTO", "agent": "CTO-JAGM", "focus": "Technical architecture"},
    {"role": "CFO", "agent": "CFO-JAGM", "focus": "Revenue & finance"},
    {"role": "CMO", "agent": "CMO-JAGM", "focus": "Market & sales"},
    {"role": "CISO", "agent": "CISO-JAGM", "focus": "Security & compliance"},
]

PROJECTS = [
    {"name": "AI-SDLC Framework", "repo": "ai-sdlc", "status": "active", "phase": "v1.5 — 240 tickets, 0 open"},
    {"name": "Drone-IBVS", "repo": "drone-ibvs", "status": "active", "phase": "Research — 21 tickets, 0 open"},
    {"name": "Family Expenses", "repo": "family-expenses", "status": "deployed", "phase": "Live on Render/Vercel — 3 open"},
    {"name": "DM Twin", "repo": "dm-twin", "status": "active", "phase": "Phase 1 — 14 tickets, 2 open"},
    {"name": "JagmITCompany", "repo": "JagmITCompany", "status": "active", "phase": "Operational — 70 tickets, 0 open"},
    {"name": "Control Board", "repo": "RomanControllingEverything", "status": "active", "phase": "152 open tickets"},
]


def run_gh_json(args: list[str]) -> Any:
    try:
        result = subprocess.run(
            ["gh", *args],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode != 0:
            print(f"[warn] gh {' '.join(args)}: {result.stderr.strip()}", file=sys.stderr)
            return []
        output = result.stdout.strip()
        return json.loads(output) if output else []
    except Exception as exc:
        print(f"[warn] gh failed: {exc}", file=sys.stderr)
        return []


def count_open_issues(repo: str) -> int:
    issues = run_gh_json(["issue", "list", "--repo", f"{ORG}/{repo}", "--state", "open", "--limit", "1000", "--json", "number"])
    return len(issues) if isinstance(issues, list) else 0


def count_total_issues(repo: str) -> int:
    issues = run_gh_json(["issue", "list", "--repo", f"{ORG}/{repo}", "--state", "all", "--limit", "1000", "--json", "number"])
    return len(issues) if isinstance(issues, list) else 0


def count_role_profiles() -> int:
    if not ROLE_PROFILE_DIR.exists():
        return 0
    return sum(1 for p in ROLE_PROFILE_DIR.rglob("*.md") if p.is_file())


def fetch_agents() -> list[dict]:
    try:
        req = Request(AGENT_URL, headers={"Accept": "application/json"})
        with urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        if isinstance(data, list):
            return data
        if isinstance(data, dict):
            for key in ("agents", "data", "items"):
                if isinstance(data.get(key), list):
                    return data[key]
        return []
    except (URLError, TimeoutError, json.JSONDecodeError) as exc:
        print(f"[warn] agent fetch failed: {exc}", file=sys.stderr)
        return []


def build_data() -> dict[str, Any]:
    repos = []
    total_open = 0
    total_all = 0

    for name in COMPANY_REPOS:
        open_count = count_open_issues(name)
        total_count = count_total_issues(name)
        total_open += open_count
        total_all += total_count
        repos.append({
            "name": name,
            "url": f"https://github.com/{ORG}/{name}",
            "openIssues": open_count,
            "totalIssues": total_count,
        })

    agents = fetch_agents()
    agent_names = [a.get("name", "unknown") for a in agents]
    # Deduplicate by name
    unique_agents = list(set(agent_names))

    role_count = count_role_profiles()

    now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

    return {
        "generatedAt": now,
        "summary": {
            "repos": len(COMPANY_REPOS),
            "openIssues": total_open,
            "totalIssues": total_all,
            "liveAgents": len(unique_agents),
            "roleProfiles": role_count,
            "departments": len(DEPARTMENTS),
            "revenue": 0,
            "revenueLabel": "$0",
            "clients": 0,
            "budget": 0,
            "status": "pre-revenue",
            "statusUk": "Без виручки",
        },
        "repos": repos,
        "agents": unique_agents,
        "departments": DEPARTMENTS,
        "cLevel": C_LEVEL,
        "projects": PROJECTS,
    }


def main() -> int:
    data = build_data()
    out_path = REPO_ROOT / "data.json"
    out_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(data["summary"], indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
