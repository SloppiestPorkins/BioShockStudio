#!/usr/bin/env python3
"""Claude Code hook: warn when the BioShock repos have unpushed or uncommitted work.

    python bioshock_repo_guard.py --mode sessionstart|stop

Why: on 1 Oct 2026 the BioshockHavok folder vanished and everything that was only local went with
it. Since 3 Oct the policy is to push after each verified batch, and to commit the UE project
(BioShockUE5, local git + LFS, no remote) after any map change. This hook makes drift visible.

Checks (read-only; no fetch, no index lock):
  * BioshockHavok: commits ahead of origin/main and the age of the oldest one; uncommitted
    changes to tracked files.
  * BioShockUE5: uncommitted changes to tracked files.
  * BioShockHavok-agents: worktree folders whose .git file points at a gitdir that no longer
    exists (left behind when a worktree was pruned or the main repo was rebuilt).

Output contract:
  sessionstart: plain text on stdout, only when something needs attention (Claude Code adds it
                to the session context). Nothing when everything is clean.
  stop:         {"systemMessage": "..."} on stdout when something needs attention (a warning,
                never a block). Nothing when clean.
Always exits 0 and never raises: a broken check must not get in the way of a session. Each git
call has a short timeout and the checks run in parallel, so the whole hook stays under ~2 s.

Environment overrides (for tests): BIOSHOCK_REPO, BIOSHOCK_UE_REPO, BIOSHOCK_AGENTS_DIR.
"""

import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

DEFAULT_REPO = "C:/Users/Jack/Documents/BioshockHavok"
DEFAULT_UE_REPO = "C:/Users/Jack/Documents/BioShockUE5"
DEFAULT_AGENTS_DIR = "C:/Users/Jack/Documents/BioShockHavok-agents"
UPSTREAM = "origin/main"
GIT_TIMEOUT = 1.5
OVERALL_TIMEOUT = 1.8


def git(repo, *args):
    """stdout of a read-only git command, or None on any failure or timeout."""
    try:
        proc = subprocess.run(
            ["git", "--no-optional-locks", "-C", str(repo), *args],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=GIT_TIMEOUT, stdin=subprocess.DEVNULL,
            creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0) if os.name == "nt" else 0,
        )
    except Exception:
        return None
    if proc.returncode != 0:
        return None
    return proc.stdout


def format_age(seconds):
    seconds = max(0, int(seconds))
    if seconds < 3600:
        return "%dm" % max(1, seconds // 60)
    if seconds < 86400:
        return "%dh" % (seconds // 3600)
    return "%dd" % (seconds // 86400)


def is_repo(path):
    return path.is_dir() and (path / ".git").exists()


def check_unpushed(repo):
    if not is_repo(repo):
        return None
    out = git(repo, "log", "--format=%ct", UPSTREAM + "..HEAD")
    if out is None:
        return None
    stamps = [int(line) for line in out.split() if line.strip().isdigit()]
    if not stamps:
        return None
    age = format_age(time.time() - min(stamps))
    noun = "commit" if len(stamps) == 1 else "commits"
    return "%d unpushed %s (oldest %s) in %s" % (len(stamps), noun, age, repo.name)


def check_uncommitted(repo):
    if not is_repo(repo):
        return None
    out = git(repo, "status", "--porcelain", "-uno")
    if out is None:
        return None
    # One line per entry; renames are one "old -> new" line, odd names are quoted.
    n = len([line for line in out.splitlines() if line.strip()])
    if not n:
        return None
    return "%d uncommitted %s in %s" % (n, "file" if n == 1 else "files", repo.name)


def check_orphans(agents_dir):
    if not agents_dir.is_dir():
        return None
    orphans = []
    for entry in sorted(agents_dir.iterdir()):
        dot_git = entry / ".git"
        if not entry.is_dir() or not dot_git.is_file():
            continue
        try:
            first = dot_git.read_text(encoding="utf-8", errors="replace").strip().splitlines()[0]
        except Exception:
            continue
        if not first.startswith("gitdir:"):
            continue
        target = Path(first[len("gitdir:"):].strip())
        if not target.is_absolute():
            target = entry / target
        if not target.exists():
            orphans.append(entry.name)
    if not orphans:
        return None
    noun = "dir" if len(orphans) == 1 else "dirs"
    return "%d orphan worktree %s in %s (gitdir gone)" % (len(orphans), noun, agents_dir.name)


def collect(mode="sessionstart"):
    repo = Path(os.environ.get("BIOSHOCK_REPO") or DEFAULT_REPO)
    ue_repo = Path(os.environ.get("BIOSHOCK_UE_REPO") or DEFAULT_UE_REPO)
    agents_dir = Path(os.environ.get("BIOSHOCK_AGENTS_DIR") or DEFAULT_AGENTS_DIR)
    jobs = [
        (check_unpushed, repo),
        (check_uncommitted, repo),
        (check_uncommitted, ue_repo),
        (check_orphans, agents_dir),
    ]
    if mode == "stop":
        # Stop fires at the end of every turn: only report what a turn should leave clean.
        # Uncommitted BioshockHavok edits are normal mid-task, and orphan dirs need a human
        # decision, so both are session-start news only.
        jobs = [(check_unpushed, repo), (check_uncommitted, ue_repo)]
    pool = ThreadPoolExecutor(max_workers=len(jobs))
    futures = [pool.submit(fn, arg) for fn, arg in jobs]
    deadline = time.monotonic() + OVERALL_TIMEOUT
    findings = []
    for future in futures:
        try:
            result = future.result(timeout=max(0.0, deadline - time.monotonic()))
        except Exception:
            result = None
        if result:
            findings.append(result)
    # Don't wait for a straggler; its git child is bounded by GIT_TIMEOUT anyway.
    pool.shutdown(wait=False, cancel_futures=True)
    return findings


def main():
    mode = None
    argv = sys.argv[1:]
    for i, token in enumerate(argv):
        if token == "--mode" and i + 1 < len(argv):
            mode = argv[i + 1].lower()
        elif token.startswith("--mode="):
            mode = token.split("=", 1)[1].lower()
    if mode not in ("sessionstart", "stop"):
        return
    findings = collect(mode)
    if not findings:
        if mode == "stop":  # all clean: forget the last warning so a recurrence is reported again
            try:
                (Path(os.environ.get("TEMP") or os.environ.get("TMP") or ".")
                 / "bioshock_repo_guard.last").unlink()
            except OSError:
                pass
        return
    summary = "BioShock repos: " + "; ".join(findings)
    if mode == "stop":
        # Same warning as the last turn? Stay quiet: repeating it every turn trains people to
        # ignore it. It shows again whenever the numbers change.
        state = Path(os.environ.get("TEMP") or os.environ.get("TMP") or ".") / "bioshock_repo_guard.last"
        try:
            if state.read_text(encoding="utf-8") == summary:
                return
        except OSError:
            pass
        try:
            state.write_text(summary, encoding="utf-8")
        except OSError:
            pass
    if mode == "sessionstart":
        sys.stdout.write(summary + "\n")
    else:
        sys.stdout.write(json.dumps({"systemMessage": summary}) + "\n")
    sys.stdout.flush()


if __name__ == "__main__":
    try:
        main()
    except BaseException:
        pass
    os._exit(0)
