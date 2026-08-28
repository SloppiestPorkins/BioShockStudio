#!/usr/bin/env python3
"""Stop hook: auto-submit the NEXT_SESSION resume block so census work continues."""

import json
import os
import re
import sys

# Safety cap per conversation (hooks.json loop_limit is a second backstop).
MAX_LOOPS = 25

DEFAULT_FOLLOWUP = (
    "Keep going on the Cursor lane (docs/DUAL_AGENT_ROADMAP.md). The action census is COMPLETE "
    "- do NOT run more census batches. Read the docs/NEXT_SESSION.md resume block, take the next "
    "Phase 4 execution-wiring item (move one stub from record-the-request to do-it-in-world, "
    "most-used first per the Phase 2.2 census), verify live, commit, update docs. No status pauses."
)


def _resume_from_next_session(repo_root: str) -> str:
    path = os.path.join(repo_root, "docs", "NEXT_SESSION.md")
    if not os.path.isfile(path):
        return DEFAULT_FOLLOWUP
    text = open(path, encoding="utf-8").read()
    # First fenced block under "Resume here"
    m = re.search(
        r"### Resume here[\s\S]*?```\n([\s\S]*?)```",
        text,
    )
    if not m:
        return DEFAULT_FOLLOWUP
    block = m.group(1).strip()
    # A well-formed resume block starts with the paste-ready "@docs/..." context line.
    if not block or "@docs/" not in block:
        return DEFAULT_FOLLOWUP
    return block


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        print("{}")
        return 0

    status = payload.get("status", "")
    loop_count = int(payload.get("loop_count", 0) or 0)

    # Only chain on a clean completion; don't loop on abort/error.
    if status != "completed":
        print("{}")
        return 0

    if loop_count >= MAX_LOOPS:
        print("{}")
        return 0

    roots = payload.get("workspace_roots") or []
    repo_root = roots[0] if roots else os.getcwd()
    followup = _resume_from_next_session(repo_root)

    out = json.dumps({"followup_message": followup}) + "\n"
    sys.stdout.write(out)
    sys.stdout.flush()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
