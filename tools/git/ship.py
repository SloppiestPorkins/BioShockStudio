#!/usr/bin/env python3
"""Commit an explicit list of files to BioshockHavok (and optionally BioShockUE5), then push.

    python tools/git/ship.py -m SUBJECT [-b BODY_FILE] --files f1 f2 ... [--ue-files g1 g2 ...]
                             [--no-push] [--skip-tests] [--dry-run]

Why this exists: every commit used to be typed by hand, and the same mistakes kept recurring --
blanket "git add -A" sweeping up other agents' work, the identity or Co-Authored-By trailer
missing, src/ changes committed without the fast tests, the paired UE project commit forgotten,
and unpushed commits piling up (the 1 Oct 2026 repo loss took everything that was only local,
including tools/fmod-x86/FmodFsbDecoder.cpp, which sat in an ignored folder). Since 3 Oct 2026
the policy is to push after each verified batch, so pushing is the default here.

Rules enforced:
  * Explicit file paths only. ".", "-A", "--all", globs and directories are refused. Every path
    must exist or be a tracked file that was deleted. Relative paths are taken relative to the
    repo they belong to (BioshockHavok for --files, BioShockUE5 for --ue-files).
  * Only the listed files go into the commit (git commit --only), even if other changes are
    already staged.
  * Before committing BioshockHavok: warn about gitignored files with source-like extensions
    outside the known generated/third-party folders, and run tools/verify_changed.py when any
    listed file is under src/ or tests/ (unless --skip-tests).
  * --ue-files is refused while Unreal is running (the editor holds the project's files).
  * Commits use -c user.name/-c user.email; git config is never modified.
  * The UE project repo has no remote and is never pushed.

--dry-run runs every check and prints every command, but changes nothing and skips the tests.

Environment overrides (for the tooling tests): BIOSHOCK_REPO, BIOSHOCK_UE_REPO, and
SHIP_ASSUME_UNREAL=running|stopped to bypass the live process check.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

DEFAULT_REPO = Path(__file__).resolve().parents[2]
DEFAULT_UE_REPO = Path("C:/Users/Jack/Documents/BioShockUE5")

USER_NAME = "Jack"
USER_EMAIL = "jackwickens6@googlemail.com"
TRAILER = "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
PUSH_REMOTE = "origin"
PUSH_BRANCH = "main"

BLANKET_ARGS = {".", "./", "..", "-A", "--all", "-a", "-u", "--update", ":/", "*"}
GLOB_CHARS = set("*?[")

SOURCE_EXTENSIONS = {".cpp", ".h", ".cs", ".py", ".ps1", ".md", ".txt", ".json", ".uc"}
# Single-segment names match at any depth (src/X/bin/); multi-segment ones are repo-root prefixes.
GENERATED_DIRS = (
    "bin", "obj", "artifacts", "external", "tmp", "__pycache__", "TestResults", ".vs",
    "tools/ue5/_reports", "tools/ue5/_shots", "tools/agents/runs", ".agent-control",
)

TEST_TRIGGER_PREFIXES = ("src/", "tests/")


class Refusal(Exception):
    """A rule was broken; nothing (further) is changed."""


def log(message: str = "") -> None:
    print(message, flush=True)


def no_window_flags() -> int:
    return getattr(subprocess, "CREATE_NO_WINDOW", 0) if os.name == "nt" else 0


def git_env() -> dict[str, str]:
    env = dict(os.environ)
    # Paths are always literal: no ":(glob)" magic, no wildcard expansion inside git.
    env["GIT_LITERAL_PATHSPECS"] = "1"
    env.pop("GIT_DIR", None)
    env.pop("GIT_WORK_TREE", None)
    return env


def run(cmd: list[str], cwd: Path, check: bool = True, timeout: float | None = None) -> subprocess.CompletedProcess:
    proc = subprocess.run(
        cmd, cwd=str(cwd), env=git_env(), capture_output=True, text=True,
        encoding="utf-8", errors="replace", timeout=timeout, creationflags=no_window_flags(),
    )
    if check and proc.returncode != 0:
        detail = (proc.stderr or proc.stdout).strip()
        raise Refusal(f"command failed ({proc.returncode}): {' '.join(cmd)}\n{detail}")
    return proc


def git(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess:
    return run(["git", "--no-optional-locks", *args], repo, check=check)


def identity_git(repo: Path, *args: str) -> list[str]:
    return ["git", "-c", f"user.name={USER_NAME}", "-c", f"user.email={USER_EMAIL}", *args]


def show(cmd: list[str], repo: Path) -> str:
    def quote(part: str) -> str:
        return f'"{part}"' if (" " in part or not part) else part
    return f"  [{repo.name}] " + " ".join(quote(p) for p in cmd)


# --------------------------------------------------------------------------- path validation

def is_tracked(repo: Path, rel: str) -> bool:
    return git(repo, "ls-files", "--error-unmatch", "--", rel, check=False).returncode == 0


def validate_paths(repo: Path, raw_paths: list[str], flag: str) -> list[str]:
    """Return repo-relative forward-slash paths, or raise Refusal naming every bad one."""
    if not raw_paths:
        return []
    repo_resolved = repo.resolve()
    problems: list[str] = []
    result: list[str] = []
    for raw in raw_paths:
        token = raw.strip()
        if token in BLANKET_ARGS or token.startswith(":"):
            problems.append(f"{raw!r}: blanket staging is not allowed; list the files explicitly")
            continue
        if any(ch in GLOB_CHARS for ch in token):
            problems.append(f"{raw!r}: globs are not allowed; list the files explicitly")
            continue
        candidate = Path(token)
        if not candidate.is_absolute():
            candidate = repo / candidate
        # resolve(strict=False) normalises ".." and case on Windows without requiring existence.
        resolved = candidate.resolve()
        try:
            rel = resolved.relative_to(repo_resolved).as_posix()
        except ValueError:
            problems.append(f"{raw!r}: outside {repo}")
            continue
        if rel in ("", "."):
            problems.append(f"{raw!r}: that is the repo root; list the files explicitly")
            continue
        if rel == ".git" or rel.startswith(".git/"):
            problems.append(f"{raw!r}: inside .git")
            continue
        if resolved.is_dir():
            problems.append(f"{raw!r}: is a directory; list the files explicitly")
            continue
        if not resolved.exists() and not is_tracked(repo, rel):
            problems.append(f"{raw!r}: does not exist and is not a tracked deletion")
            continue
        if resolved.exists() and not is_tracked(repo, rel):
            # check-ignore rejects literal pathspecs; the path is already known to hold no globs.
            if git(repo, "--no-literal-pathspecs", "check-ignore", "-q", "--", rel, check=False).returncode == 0:
                problems.append(f"{raw!r}: is gitignored; un-ignore it in .gitignore first")
                continue
        if rel not in result:
            result.append(rel)
    if problems:
        raise Refusal(f"{flag} refused:\n  " + "\n  ".join(problems))
    return result


def porcelain_paths(repo: Path, *args: str) -> list[tuple[str, str]]:
    """(XY status, path) pairs from git status -z, which needs no unquoting of odd names."""
    fields = git(repo, "status", "--porcelain", "-z", *args).stdout.split("\0")
    entries: list[tuple[str, str]] = []
    i = 0
    while i < len(fields):
        field = fields[i]
        i += 1
        if len(field) < 4:
            continue
        status, path = field[:2], field[3:]
        entries.append((status, path))
        if "R" in status or "C" in status:
            i += 1  # the rename/copy source follows as its own field
    return entries


def changed_paths(repo: Path, rels: list[str]) -> list[str]:
    """The subset of rels that differ from HEAD (staged, unstaged, untracked or deleted)."""
    changed = {path for _, path in porcelain_paths(repo, "-uall", "--", *rels)}
    return [r for r in rels if r in changed]


def other_staged(repo: Path, rels: list[str]) -> list[str]:
    out = git(repo, "diff", "--cached", "--name-only").stdout
    return [p for p in out.splitlines() if p and p not in rels]


# --------------------------------------------------------------------------- checks

def is_generated(rel: str) -> bool:
    rel = rel.rstrip("/")
    segments = rel.split("/")
    for known in GENERATED_DIRS:
        if "/" in known:
            if rel == known or rel.startswith(known + "/"):
                return True
        elif known in segments:
            return True
    return False


def ignored_source_files(repo: Path) -> list[str]:
    """Ignored files with source-like extensions outside known generated/third-party folders.

    git collapses a wholly ignored folder to one "!! dir/" line; folders that are not known to be
    generated are walked here, so a source file hidden in one is still found.
    """
    found: list[str] = []
    for status, rel in porcelain_paths(repo, "--ignored"):
        if status != "!!" or is_generated(rel):
            continue
        if rel.endswith("/"):
            base = repo / rel
            for root, dirs, files in os.walk(base):
                root_rel = Path(root).relative_to(repo).as_posix()
                dirs[:] = [d for d in dirs if not is_generated(f"{root_rel}/{d}") and d != ".git"]
                for name in files:
                    if Path(name).suffix.lower() in SOURCE_EXTENSIONS:
                        found.append(f"{root_rel}/{name}")
        elif Path(rel).suffix.lower() in SOURCE_EXTENSIONS:
            found.append(rel)
    return sorted(found)


def unreal_running(repo: Path) -> tuple[bool, str]:
    assumed = os.environ.get("SHIP_ASSUME_UNREAL", "").strip().lower()
    if assumed in ("running", "stopped"):
        return assumed == "running", f"SHIP_ASSUME_UNREAL={assumed}"
    guard = repo / "tools" / "ue5" / "ue_guard.py"
    if guard.is_file():
        proc = run([sys.executable, str(guard), "check"], repo, check=False, timeout=60)
        detail = (proc.stdout + proc.stderr).strip()
        return proc.returncode != 0, f"ue_guard.py check exit {proc.returncode}" + (f": {detail}" if detail else "")
    proc = run(["tasklist", "/FO", "CSV", "/NH"], repo, check=False, timeout=30)
    if proc.returncode != 0:
        raise Refusal("tasklist failed; cannot tell whether Unreal is running")
    names = set()
    for line in proc.stdout.splitlines():
        name = line.split(",", 1)[0].strip().strip('"')
        if name.lower().startswith("unrealeditor"):
            names.add(name)
    if names:
        return True, "tasklist: " + ", ".join(sorted(names))
    return False, "tasklist: no UnrealEditor*.exe"


def build_message(subject: str, body: str) -> str:
    parts = [subject.strip()]
    body = body.strip("\n").rstrip()
    if body:
        parts.append(body)
    text = "\n\n".join(parts)
    has_trailer = any(line.strip().lower() == TRAILER.lower() for line in text.splitlines())
    if not has_trailer:
        text += "\n\n" + TRAILER
    return text + "\n"


def commit(repo: Path, rels: list[str], message: str, dry_run: bool) -> str | None:
    add_cmd = ["git", "add", "--", *rels]
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".txt", delete=False) as handle:
        handle.write(message)
        msg_path = handle.name
    try:
        commit_args = ["commit", "--cleanup=whitespace", "-F", msg_path, "--only", "--", *rels]
        commit_cmd = identity_git(repo, *commit_args)
        log(show(add_cmd, repo))
        log(show(identity_git(repo, *[("<message file>" if a == msg_path else a) for a in commit_args]), repo))
        if dry_run:
            return None
        run(add_cmd, repo)
        run(commit_cmd, repo)
    finally:
        try:
            os.unlink(msg_path)
        except OSError:
            pass
    sha = git(repo, "rev-parse", "HEAD").stdout.strip()
    return sha


# --------------------------------------------------------------------------- main

def refuse_blanket_flags(argv: list[str]) -> None:
    # argparse would report "--files -A" as a missing argument; say what is actually wrong.
    takes_value = {"-m", "--message", "-b", "--body-file"}
    skip = False
    for token in argv:
        if skip:
            skip = False
            continue
        if token in takes_value:
            skip = True
            continue
        if token in BLANKET_ARGS and token.startswith("-"):
            raise Refusal(f"blanket staging is not allowed ({token}); list the files explicitly")


def parse_args(argv: list[str]) -> argparse.Namespace:
    refuse_blanket_flags(argv)
    parser = argparse.ArgumentParser(
        description="Commit explicit files to BioshockHavok (+ optional BioShockUE5) and push.")
    parser.add_argument("-m", "--message", required=True, help="commit subject (one line)")
    parser.add_argument("-b", "--body-file", help="file holding the commit body")
    parser.add_argument("--files", nargs="+", default=[], help="BioshockHavok files to commit")
    parser.add_argument("--ue-files", nargs="+", default=[], help="BioShockUE5 files to commit")
    parser.add_argument("--no-push", action="store_true", help="commit but do not push")
    parser.add_argument("--skip-tests", action="store_true", help="do not run tools/verify_changed.py")
    parser.add_argument("--dry-run", action="store_true", help="show everything, change nothing")
    return parser.parse_args(argv)


def ship(argv: list[str]) -> int:
    args = parse_args(argv)
    repo = Path(os.environ.get("BIOSHOCK_REPO") or DEFAULT_REPO)
    ue_repo = Path(os.environ.get("BIOSHOCK_UE_REPO") or DEFAULT_UE_REPO)
    dry = args.dry_run
    if dry:
        log("DRY RUN: nothing will be staged, committed or pushed.")

    subject = args.message.strip()
    if not subject:
        raise Refusal("empty subject")
    if "\n" in subject:
        raise Refusal("the subject must be one line; put the rest in a body file (-b)")
    body = ""
    if args.body_file:
        body_path = Path(args.body_file)
        if not body_path.is_file():
            raise Refusal(f"body file not found: {body_path}")
        body = body_path.read_text(encoding="utf-8-sig")
    if not args.files:
        raise Refusal("--files is required: list the BioshockHavok files to commit explicitly")
    if not (repo / ".git").exists():
        raise Refusal(f"not a git repo: {repo}")

    log(f"[1] Checking paths in {repo}")
    files = validate_paths(repo, args.files, "--files")
    ue_files: list[str] = []
    if args.ue_files:
        if not (ue_repo / ".git").exists():
            raise Refusal(f"not a git repo: {ue_repo}")
        ue_files = validate_paths(ue_repo, args.ue_files, "--ue-files")

    changed = changed_paths(repo, files)
    unchanged = [f for f in files if f not in changed]
    if not changed:
        raise Refusal("none of the listed --files has changes to commit")
    for f in unchanged:
        log(f"  warning: no changes in {f}; skipping it")
    files = changed
    log("  files: " + ", ".join(files))
    for f in other_staged(repo, files):
        log(f"  note: {f} is already staged but not listed; it stays staged and is not committed")

    if ue_files:
        ue_changed = changed_paths(ue_repo, ue_files)
        if not ue_changed:
            raise Refusal("none of the listed --ue-files has changes to commit")
        for f in ue_files:
            if f not in ue_changed:
                log(f"  warning: no changes in BioShockUE5 {f}; skipping it")
        ue_files = ue_changed
        log("  ue files: " + ", ".join(ue_files))

    log("[2] Checking for gitignored source files")
    hidden = ignored_source_files(repo)
    if hidden:
        log(f"  WARNING: {len(hidden)} gitignored source-like file(s) outside known generated folders.")
        log("  These are not in git and would be lost with the working copy (FmodFsbDecoder.cpp, 1 Oct):")
        for path in hidden[:50]:
            log(f"    {path}")
        if len(hidden) > 50:
            log(f"    ... and {len(hidden) - 50} more")
    else:
        log("  none")

    if ue_files:
        log("[3] Checking that Unreal is not running")
        running, detail = unreal_running(repo)
        log(f"  {detail}")
        if running:
            raise Refusal("Unreal is running; close it before committing BioShockUE5 files (nothing was committed)")
    else:
        log("[3] No --ue-files; Unreal check not needed")

    needs_tests = any(f.startswith(TEST_TRIGGER_PREFIXES) for f in files)
    verify = repo / "tools" / "verify_changed.py"
    if not needs_tests:
        log("[4] No src/ or tests/ files; tests not needed")
    elif args.skip_tests:
        log("[4] --skip-tests given; not running tools/verify_changed.py")
    elif not verify.is_file():
        log("[4] WARNING: tools/verify_changed.py not found; committing without running tests")
    elif dry:
        log("[4] Would run: " + show([sys.executable, str(verify)], repo).strip())
    else:
        # verify_changed tests the working tree, but only the listed files get committed. If other
        # src/ or tests/ changes sit uncommitted beside them, a pass proves nothing about the commit
        # (a listed file may depend on an unlisted one), so refuse rather than push a broken main.
        unlisted = sorted(p for _, p in porcelain_paths(repo, "-uall")
                          if p.startswith(TEST_TRIGGER_PREFIXES) and p not in files)
        if unlisted:
            raise Refusal("uncommitted src/ or tests/ changes not in --files would be tested but not "
                          "committed: " + ", ".join(unlisted[:10])
                          + (" ..." if len(unlisted) > 10 else "")
                          + " - list them too, or stash them first (nothing was committed)")
        log("[4] Running tools/verify_changed.py")
        proc = subprocess.run([sys.executable, str(verify)], cwd=str(repo))
        if proc.returncode != 0:
            raise Refusal(f"tools/verify_changed.py failed (exit {proc.returncode}); nothing was committed")
        log("  tests passed")

    message = build_message(subject, body)
    log(f"[5] Committing {len(files)} file(s) to BioshockHavok")
    log("  message:")
    for line in message.rstrip("\n").splitlines():
        log(f"  | {line}")
    sha = commit(repo, files, message, dry)
    log(f"  BioshockHavok commit: {sha or '(dry run)'}")

    ue_sha = None
    if ue_files:
        ue_message = f"{subject}\n\nPaired with BioshockHavok {sha or '<sha>'}.\n"
        log(f"[6] Committing {len(ue_files)} file(s) to BioShockUE5 (local only; no remote)")
        for line in ue_message.rstrip("\n").splitlines():
            log(f"  | {line}")
        try:
            ue_sha = commit(ue_repo, ue_files, ue_message, dry)
        except Refusal as error:
            raise Refusal(f"{error}\nBioshockHavok was already committed as {sha}; the UE commit did not happen.")
        log(f"  BioShockUE5 commit: {ue_sha or '(dry run)'}")
    else:
        log("[6] No --ue-files")

    if args.no_push:
        log("[7] --no-push given; not pushing")
    else:
        branch = git(repo, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
        push_cmd = ["git", "push", PUSH_REMOTE, PUSH_BRANCH]
        if branch != PUSH_BRANCH:
            log(f"[7] WARNING: on branch {branch!r}, not {PUSH_BRANCH!r}; not pushing")
        else:
            log(f"[7] Pushing BioshockHavok {PUSH_BRANCH} to {PUSH_REMOTE}")
            log(show(push_cmd, repo))
            if not dry:
                proc = run(push_cmd, repo, check=False, timeout=300)
                if proc.returncode != 0:
                    raise Refusal(f"push failed (exit {proc.returncode}); the commit {sha} is local only\n"
                                  + (proc.stderr or proc.stdout).strip())
                log("  pushed")

    log("")
    log(f"Done. BioshockHavok {sha or '(dry run)'}" + (f", BioShockUE5 {ue_sha or '(dry run)'}" if ue_files else ""))
    return 0


def main() -> int:
    try:
        return ship(sys.argv[1:])
    except Refusal as error:
        print(f"REFUSED: {error}", file=sys.stderr, flush=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
