#!/usr/bin/env python3
"""Send the latest git commit metadata to a Google Sheets webhook."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass
from datetime import datetime


WEBHOOK_ENV_VARS = ("GOOGLE_SHEETS_WEBHOOK_URL", "GOOGLE_SHEET_WEBHOOK_URL")
CONVENTIONAL_COMMIT_RE = re.compile(
    r"^(?P<type>feat|fix|docs|style|refactor|perf|test|chore)"
    r"(?:\((?P<scope>[^)]+)\))?(?P<breaking>!)?:\s*(?P<summary>.+)$",
    re.IGNORECASE,
)
STATUS_MARKER_RE = re.compile(r"\[(DONE|COMPLETED|WIP|PENDING)\]\s*", re.IGNORECASE)


@dataclass
class CommitInfo:
    commit_hash: str
    commit_short_hash: str
    author_name: str
    author_email: str
    committed_at_iso: str
    subject: str
    body: str
    branch: str

    @property
    def committed_at_display(self) -> str:
        parsed = datetime.fromisoformat(self.committed_at_iso)
        return parsed.strftime("%d %b %Y")


def run_git(args: list[str]) -> str:
    completed = subprocess.run(
        ["git", *args],
        capture_output=True,
        check=True,
        text=True,
        encoding="utf-8",
    )
    return completed.stdout.strip()


def get_latest_commit() -> CommitInfo:
    pretty_format = "%H%n%h%n%an%n%ae%n%aI%n%s%n%b"
    raw = run_git(["log", "-1", f"--pretty=format:{pretty_format}"])
    parts = raw.splitlines()

    if len(parts) < 6:
        raise RuntimeError("Unexpected git log output while reading the latest commit.")

    body = "\n".join(parts[6:]).strip() if len(parts) > 6 else ""

    return CommitInfo(
        commit_hash=parts[0],
        commit_short_hash=parts[1],
        author_name=parts[2],
        author_email=parts[3],
        committed_at_iso=parts[4],
        subject=parts[5],
        body=body,
        branch=run_git(["rev-parse", "--abbrev-ref", "HEAD"]),
    )


def clean_commit_text(text: str) -> str:
    cleaned = STATUS_MARKER_RE.sub("", text).strip()
    return re.sub(r"\s+", " ", cleaned)


def humanize_token(value: str) -> str:
    normalized = re.sub(r"[-_/]+", " ", value).strip()
    return " ".join(part.capitalize() for part in normalized.split())


def infer_status(commit: CommitInfo) -> str:
    full_text = f"{commit.subject}\n{commit.body}".upper()
    if "[PENDING]" in full_text:
        return "Pending"
    if "[WIP]" in full_text:
        return "In Progress"
    if "[DONE]" in full_text or "[COMPLETED]" in full_text:
        return "Completed"
    return "Completed"


def infer_category(commit_type: str | None, text: str) -> str:
    if commit_type:
        commit_type = commit_type.lower()
        if commit_type in {"feat", "fix", "refactor", "perf"}:
            return "Coding"
        if commit_type == "docs":
            return "Documentation"
        if commit_type == "test":
            return "Testing"
        if commit_type == "style":
            return "UI/UX"
        if commit_type == "chore":
            return "Maintenance"

    lowered = text.lower()
    if any(keyword in lowered for keyword in ("test", "qa", "verify")):
        return "Testing"
    if any(keyword in lowered for keyword in ("docs", "document", "readme")):
        return "Documentation"
    if any(keyword in lowered for keyword in ("ui", "ux", "layout", "style", "design")):
        return "UI/UX"
    return "Coding"


def build_payload(commit: CommitInfo) -> dict[str, str]:
    conventional = CONVENTIONAL_COMMIT_RE.match(clean_commit_text(commit.subject))
    commit_type = conventional.group("type").lower() if conventional else None
    scope = conventional.group("scope") if conventional else None
    summary = conventional.group("summary") if conventional else clean_commit_text(commit.subject)

    task = humanize_token(scope) if scope else humanize_token(commit_type) if commit_type else summary[:72]
    clean_subject = clean_commit_text(commit.subject)
    clean_body = clean_commit_text(commit.body)
    detail = clean_subject if not clean_body else f"{clean_subject} | {clean_body}"

    return {
        "task": task,
        "message": detail,
        "status": infer_status(commit),
        "jenis": infer_category(commit_type, detail),
        "date_override": commit.committed_at_display,
        "branch": commit.branch,
        "author": commit.author_name,
        "author_email": commit.author_email,
        "commit_hash": commit.commit_hash,
        "commit_short_hash": commit.commit_short_hash,
        "commit_iso_date": commit.committed_at_iso,
        "commit_type": commit_type or "",
        "commit_scope": scope or "",
        "commit_summary": summary,
    }


def resolve_webhook_url(cli_value: str | None) -> str | None:
    if cli_value:
        return cli_value

    for env_name in WEBHOOK_ENV_VARS:
        value = os.getenv(env_name, "").strip()
        if value:
            return value

    return None


def post_json(url: str, payload: dict[str, str], timeout_seconds: int = 5) -> None:
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json; charset=utf-8"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
        response.read()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Print the payload without sending it.")
    parser.add_argument("--webhook-url", help="Override the webhook URL for this run.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    try:
        commit = get_latest_commit()
    except (subprocess.CalledProcessError, RuntimeError) as error:
        print(f"Failed to read latest commit: {error}", file=sys.stderr)
        return 1

    payload = build_payload(commit)

    if args.dry_run:
        print(json.dumps(payload, indent=2))
        return 0

    webhook_url = resolve_webhook_url(args.webhook_url)
    if not webhook_url:
        print(
            "Skipped Google Sheets sync because GOOGLE_SHEETS_WEBHOOK_URL is not set.",
            file=sys.stderr,
        )
        return 0

    try:
        post_json(webhook_url, payload)
    except urllib.error.URLError as error:
        print(f"Failed to sync latest commit to Google Sheets: {error}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
