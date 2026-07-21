from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.error import URLError, HTTPError
from urllib.request import Request, urlopen

REPO_ROOT = Path(__file__).resolve().parent
DEFAULT_ROLE_DIR = Path(r"F:\AI SDLC rork\ai-sdlc-1.0-143\.claude\agents")
DEFAULT_AGENT_URL = "http://127.0.0.1:8283/v1/agents"
ORG_NAME = "jagmstar"


def run_gh_json(args: list[str]) -> Any:
    completed = subprocess.run(
        ["gh", *args],
        check=True,
        capture_output=True,
        text=True,
    )
    output = completed.stdout.strip()
    return json.loads(output) if output else []


def count_markdown_files(directory: Path) -> int:
    if not directory.exists():
        return 0
    return sum(1 for path in directory.rglob("*.md") if path.is_file())


def fetch_json(url: str) -> Any:
    request = Request(url, headers={"Accept": "application/json"})
    with urlopen(request, timeout=15) as response:
        return json.loads(response.read().decode("utf-8"))


def count_agents(payload: Any) -> int:
    if isinstance(payload, list):
        return len(payload)
    if isinstance(payload, dict):
        for key in ("agents", "data", "items", "results"):
            value = payload.get(key)
            if isinstance(value, list):
                return len(value)
        for key in ("count", "total", "totalCount"):
            value = payload.get(key)
            if isinstance(value, int):
                return value
    return 0


def count_open_issues(repo_full_name: str) -> int:
    try:
        issues = run_gh_json([
            "issue",
            "list",
            "--repo",
            repo_full_name,
            "--state",
            "open",
            "--limit",
            "1000",
            "--json",
            "number",
        ])
    except subprocess.CalledProcessError as exc:
        print(f"[warn] unable to count issues for {repo_full_name}: {exc.stderr.strip()}", file=sys.stderr)
        return 0
    return len(issues)


def build_data() -> dict[str, Any]:
    repo_list = run_gh_json(["repo", "list", ORG_NAME, "--limit", "50", "--json", "name,visibility"])
    repos: list[dict[str, Any]] = []
    total_open_issues = 0

    for repo in sorted(repo_list, key=lambda item: item["name"].lower()):
        full_name = f"{ORG_NAME}/{repo['name']}"
        open_issues = count_open_issues(full_name)
        total_open_issues += open_issues
        repos.append(
            {
                "name": repo["name"],
                "fullName": full_name,
                "url": f"https://github.com/{full_name}",
                "visibility": repo.get("visibility", "UNKNOWN"),
                "openIssuesCount": open_issues,
            }
        )

    role_profiles_count = count_markdown_files(Path(os.environ.get("JAGM_ROLE_PROFILE_DIR", str(DEFAULT_ROLE_DIR))))

    try:
        agents_payload = fetch_json(os.environ.get("JAGM_AGENT_URL", DEFAULT_AGENT_URL))
        agents_count = count_agents(agents_payload)
    except (URLError, HTTPError, TimeoutError, json.JSONDecodeError) as exc:
        print(f"[warn] unable to fetch agent registry: {exc}", file=sys.stderr)
        agents_count = 0

    now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    data = {
        "generatedAt": now,
        "revenue": 0,
        "departmentCount": 10,
        "memoryLayers": 4,
        "roleProfilesCount": role_profiles_count,
        "agentsCount": agents_count,
        "openIssuesCount": total_open_issues,
        "repoCount": len(repos),
        "repos": repos,
    }
    return data


def update_json_file(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


SCRIPT_TAG_RE = re.compile(
    r'<script id="dashboard-data" type="application/json">\s*.*?\s*</script>',
    re.DOTALL,
)


def embed_json_for_html(data: dict[str, Any]) -> str:
    payload = json.dumps(data, indent=2, ensure_ascii=False)
    payload = payload.replace("</", "<\\/")
    return f'<script id="dashboard-data" type="application/json">\n{payload}\n  </script>'


def update_index_html(path: Path, data: dict[str, Any]) -> None:
    html = path.read_text(encoding="utf-8")
    replacement = embed_json_for_html(data)
    if not SCRIPT_TAG_RE.search(html):
        raise RuntimeError("Could not find embedded dashboard data script tag in index.html")
    html = SCRIPT_TAG_RE.sub(replacement, html, count=1)
    path.write_text(html, encoding="utf-8")


def main() -> int:
    data = build_data()
    update_json_file(REPO_ROOT / "data.json", data)
    update_index_html(REPO_ROOT / "index.html", data)

    print(json.dumps(data, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
