#!/usr/bin/env python3
"""Stop hook: auto-submit the NEXT_SESSION resume block so census work continues."""

import json
import os
import re
import sys

# Safety cap per conversation (hooks.json loop_limit is a second backstop).
# Raised 28 Aug 2026 at the user's instruction — keep the Cursor lane grinding
# through Phase 4 execution wiring without a manual restart every 25 turns.
MAX_LOOPS = 500

# 28 Sept 2026: docs/NEXT_SESSION.md and docs/DUAL_AGENT_ROADMAP.md (the Aug-28-era Phase 4 census
# workflow this hook was written for) were archived to docs/archive/ during a documentation
# consolidation -- both are stale, superseded by docs/ROADMAP.md + docs/STATUS.md. The Cursor lane
# now runs one task at a time via tools/agents/orchestrator.ps1 (see docs/ENGINEERING_RULES.md), not
# this hook's auto-continuation loop, so DEFAULT_FOLLOWUP should not resurrect Phase 4 instructions
# -- it should point at where real work is actually tracked now.
DEFAULT_FOLLOWUP = (
    "Read docs/STATUS.md for current state and the open bug list, and tools/agents/tasks/*.md "
    "(files without a matching *.done) for queued work. Do not resume the old Phase 4 census "
    "workflow (docs/archive/NEXT_SESSION.md, docs/archive/DUAL_AGENT_ROADMAP.md) -- it is retired."
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
