"""Run UE-Python scripts headlessly against BioShockUE5 and print one honest verdict.

Replaces the hand-typed `UnrealEditor-Cmd <uproject> -run=pythonscript -script=... -nullrhi
-abslog=...` (typed ~930 times) and designs out its measured failure modes:

  - Git-Bash MSYS path conversion turns /Game/... into C:/Program Files/Git/Game/... before a
    Windows python ever sees it. Mangled args and --env values are repaired, with a warning.
  - Sibling imports failing with ModuleNotFoundError: each script's own directory goes first on
    sys.path, inside Unreal, before it runs.
  - Two Unreal processes against one project: the run holds ue_guard's shared lock and refuses to
    start while any Unreal process is alive. It never kills anything but its own child.
  - UE's exit code is unreliable (127 on runs whose script finished). The verdict comes only from
    explicit result markers the generated shim prints, read back out of the log.
  - A -nullrhi PASS read as proof something LOOKS right. It cannot render; the summary says so.

Usage:
    python tools/ue5/ue_run.py SCRIPT [SCRIPT ...] | --suite NAME
        [--render] [--env K=V ...] [--log PATH] [--timeout SEC] [--wait SEC] [--dry-run]
        [--uproject P] [--engine P]

Scripts are bare names (verify_water), file names (verify_water.py) or paths. Bare names and file
names resolve against the CURRENT checkout's tools/ue5 -- the checkout containing the working
directory, else the one holding this file -- so a worktree tests its own code. --suite NAME reads
tools/ue5/suites/NAME.txt (one script per line, # comments).

All scripts share ONE editor boot: a generated shim runs each via runpy as __main__, catches
everything, and prints per script
    UE_RUN_RESULT {"script": .., "status": "pass"|"fail", "seconds": .., "error": ..}
then UE_RUN_DONE. No UE_RUN_DONE in the log = infrastructure failure (crash, timeout, boot error).

Exit codes: 0 all pass, 1 some script failed, 2 infrastructure failure or Unreal busy.
"""

import argparse
import datetime
import difflib
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ue_guard  # noqa: E402

DEFAULT_UPROJECT = r"C:\Users\Jack\Documents\BioShockUE5\BioShockUE5.uproject"
DEFAULT_ENGINE = r"G:\Games\UE_5.7"
DEFAULT_TIMEOUT = 1800

NULLRHI_NOTE = "(nullrhi: render-blind - a PASS here proves nothing about how it looks)"
# Markers count only as a whole message (line start, or right after "LogPython: "), so a traceback
# quoting shim source can never fake one.
RESULT_RE = re.compile(r"(?:^|LogPython: )UE_RUN_RESULT (\{.*\})\s*$")
START_RE = re.compile(r"(?:^|LogPython: )UE_RUN_START (\{.*\})\s*$")
DONE_RE = re.compile(r"(?:^|LogPython: )UE_RUN_DONE\b")
RELEVANT_RE = re.compile(
    r"LogPython: Error|Fatal error|Critical error|Assertion failed|Ensure condition failed|"
    r"Unhandled Exception|EXCEPTION_ACCESS_VIOLATION|LogWindows: Error|LogOutputDevice: Error|"
    r"Error: appError|LogPythonScriptCommandlet: Error|LogInit: Error|LogCore: Error",
    re.IGNORECASE)
# UE repeats every error in a closing "Warning/Error Summary"; those copies add nothing.
SUMMARY_REPEAT_RE = re.compile(r"LogInit: Display: \S")


# ---------------------------------------------------------------- MSYS repair

_UE_ROOTS = r"(?:Game|Script|Engine)"


def _git_prefixes():
    """Git-for-Windows install roots that MSYS maps '/' onto, most specific first."""
    found = []
    exepath = os.environ.get("EXEPATH")  # set by git-bash.exe to its install dir
    if exepath:
        found.append(exepath)
    git = shutil.which("git")
    if git:
        parent = Path(git).resolve().parent  # <root>/cmd or <root>/mingw64/bin
        for candidate in (parent.parent, parent.parent.parent):
            if (candidate / "usr" / "bin").is_dir():
                found.append(str(candidate))
                break
    found += [r"C:\Program Files\Git", r"C:\Program Files (x86)\Git"]
    seen, unique = set(), []
    for prefix in found:
        key = prefix.replace("\\", "/").rstrip("/").lower()
        if key and key not in seen:
            seen.add(key)
            unique.append(prefix.replace("\\", "/").rstrip("/"))
    return unique


def repair_msys(value, prefixes=None):
    """Undo Git-Bash's /Game/... -> C:/Program Files/Git/Game/... mangling.

    Returns (repaired, changed). Only touches a Git-install prefix immediately followed by
    /Game/, /Script/ or /Engine/ -- a real Windows path never looks like that.
    """
    if not value:
        return value, False
    out = value
    for prefix in prefixes if prefixes is not None else _git_prefixes():
        pattern = re.escape(prefix).replace("/", r"[/\\]")
        out = re.sub(r"(?i)" + pattern + r"[/\\](" + _UE_ROOTS + r")(?=[/\\])",
                     lambda m: "/" + m.group(1), out)
    # Any other install location still ends in a Git directory: X:/.../Git/Game/...
    out = re.sub(r"(?i)\b[A-Z]:[/\\](?:[^=,;\"']*?[/\\])?Git[/\\](" + _UE_ROOTS + r")(?=[/\\])",
                 lambda m: "/" + m.group(1), out)
    if out != value:
        # MSYS output uses forward slashes, but normalise any backslashes inside the asset path.
        out = re.sub(r"/(" + _UE_ROOTS + r")([/\\][^,;\s\"']*)",
                     lambda m: "/" + m.group(1) + m.group(2).replace("\\", "/"), out)
    return out, out != value


def repair_argv(argv, warn=print):
    fixed = []
    for arg in argv:
        new, changed = repair_msys(arg)
        if changed:
            warn("ue_run: WARNING repaired MSYS-mangled argument %r -> %r "
                 "(Git Bash rewrote it; MSYS_NO_PATHCONV=1 avoids this)" % (arg, new))
        fixed.append(new)
    return fixed


# ---------------------------------------------------------------- arguments


def build_parser():
    parser = argparse.ArgumentParser(
        prog="ue_run.py",
        description="Run UE-Python scripts headlessly in one editor boot with a log-based verdict.")
    parser.add_argument("scripts", nargs="*", help="bare name, file name or path")
    parser.add_argument("--suite", help="tools/ue5/suites/NAME.txt (or a path to a .txt)")
    parser.add_argument("--render", action="store_true",
                        help="omit -nullrhi (a real RHI; still headless, still not a screenshot)")
    parser.add_argument("--env", action="append", default=[], metavar="K=V",
                        help="environment variable for the Unreal process (repeatable)")
    parser.add_argument("--log", help="log path (default: Saved/ue_run/<timestamp>_<name>.log)")
    parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT, help="seconds (1800)")
    parser.add_argument("--wait", type=int, default=0,
                        help="seconds to wait for a busy Unreal / lock before giving up (0)")
    parser.add_argument("--dry-run", action="store_true",
                        help="print the command and the shim; launch nothing")
    parser.add_argument("--uproject", default=DEFAULT_UPROJECT)
    parser.add_argument("--engine", default=DEFAULT_ENGINE,
                        help="engine root, Engine dir, or UnrealEditor-Cmd.exe path")
    return parser


def parse_args(argv, warn=print):
    parser = build_parser()
    args = parser.parse_args(repair_argv(list(argv), warn=warn))
    if not args.scripts and not args.suite:
        parser.error("give at least one SCRIPT or --suite NAME")
    env = {}
    for item in args.env:
        key, sep, value = item.partition("=")
        if not sep or not key.strip():
            parser.error("--env expects K=V, got %r" % item)
        env[key.strip()] = value
    args.env_pairs = env
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    return args


# ---------------------------------------------------------------- resolution


def checkout_tools_dir(cwd=None, here=None):
    """tools/ue5 of the checkout containing cwd; else the directory holding this file."""
    here = Path(here or os.path.dirname(os.path.abspath(__file__)))
    start = Path(cwd or os.getcwd()).resolve()
    for directory in (start, *start.parents):
        candidate = directory / "tools" / "ue5"
        if (candidate / "ue_run.py").is_file():
            return candidate
    return here


class ResolveError(Exception):
    pass


def resolve_script(token, tools_dir, cwd=None):
    """Absolute Path for a script token, or ResolveError naming close matches."""
    tools_dir = Path(tools_dir)
    cwd = Path(cwd or os.getcwd())
    raw = Path(token)
    looks_like_path = raw.is_absolute() or "/" in token or "\\" in token
    candidates = []
    if looks_like_path:
        candidates.append(raw if raw.is_absolute() else cwd / raw)
        if not raw.is_absolute():
            candidates.append(tools_dir / raw)
    else:
        name = token if token.endswith(".py") else token + ".py"
        candidates.append(tools_dir / name)
        candidates.append(cwd / name)
    for candidate in candidates:
        if candidate.is_file():
            return candidate.resolve()
    stem = raw.stem if raw.suffix == ".py" else raw.name
    pool = sorted(p.stem for p in tools_dir.glob("*.py"))
    close = difflib.get_close_matches(stem, pool, n=4, cutoff=0.6)
    hint = (" - did you mean: " + ", ".join(close)) if close else ""
    raise ResolveError("script not found: %s (looked in %s)%s" % (token, tools_dir, hint))


def read_suite(name, tools_dir):
    """Script tokens from a suite file. NAME is a suite name or a path to a .txt file."""
    path = Path(name)
    if not (path.suffix == ".txt" and path.is_file()):
        path = Path(tools_dir) / "suites" / (name if name.endswith(".txt") else name + ".txt")
    if not path.is_file():
        suites = sorted(p.stem for p in (Path(tools_dir) / "suites").glob("*.txt"))
        raise ResolveError("suite not found: %s (available: %s)" % (path, ", ".join(suites) or "none"))
    tokens = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            tokens.append(line)
    if not tokens:
        raise ResolveError("suite %s lists no scripts" % path)
    return tokens, path


def resolve_engine(engine):
    path = Path(engine)
    if path.suffix.lower() == ".exe":
        return path
    for candidate in (path / "Engine" / "Binaries" / "Win64" / "UnrealEditor-Cmd.exe",
                      path / "Binaries" / "Win64" / "UnrealEditor-Cmd.exe"):
        if candidate.is_file():
            return candidate
    return path / "Engine" / "Binaries" / "Win64" / "UnrealEditor-Cmd.exe"


# ---------------------------------------------------------------- shim + command


SHIM_TEMPLATE = '''"""Generated by tools/ue5/ue_run.py for one headless run. Regenerated every run; do not edit."""
import json
import os
import runpy
import sys
import time
import traceback

SCRIPTS = %(scripts)s


def _describe(exc):
    lines = traceback.format_exception_only(type(exc), exc)
    text = "".join(lines).strip().splitlines() or [type(exc).__name__]
    # First line is "Type: message"; fold any multi-line message (verify_* failure lists) onto it.
    out = text[0] + "".join(" | " + line.strip() for line in text[1:] if line.strip())
    return out[:600]


def _run_one(path):
    script_dir = os.path.dirname(path)
    sys.path.insert(0, script_dir)
    saved_argv = sys.argv
    sys.argv = [path]
    status, error = "pass", ""
    started = time.time()
    try:
        runpy.run_path(path, run_name="__main__")
    except SystemExit as exc:
        if exc.code not in (None, 0):
            status, error = "fail", "SystemExit: %%s" %% (exc.code,)
    except BaseException as exc:
        status, error = "fail", _describe(exc)
        traceback.print_exc()
    finally:
        sys.argv = saved_argv
        if script_dir in sys.path:
            sys.path.remove(script_dir)
    return status, error, round(time.time() - started, 2)


def _main():
    passed = 0
    for path in SCRIPTS:
        name = os.path.basename(path)
        print("UE_RUN_START " + json.dumps({"script": name}))
        status, error, seconds = _run_one(path)
        passed += status == "pass"
        print("UE_RUN_RESULT " + json.dumps(
            {"script": name, "status": status, "seconds": seconds, "error": error}))
    print("UE_RUN_DONE " + json.dumps({"passed": passed, "total": len(SCRIPTS)}))


_main()
'''


def generate_shim(script_paths):
    paths = [str(Path(p)).replace("\\", "/") for p in script_paths]
    return SHIM_TEMPLATE % {"scripts": json.dumps(paths, indent=4)}


def build_command(exe, uproject, shim_path, log_path, render=False):
    fwd = lambda p: str(p).replace("\\", "/")  # noqa: E731 -- UE wants forward slashes
    cmd = [str(exe), fwd(uproject), "-run=pythonscript", "-script=" + fwd(shim_path),
           "-unattended", "-nopause", "-nosplash"]
    if not render:
        cmd.append("-nullrhi")
    cmd.append("-abslog=" + fwd(log_path))
    return cmd


def child_environment(extra, warn=print):
    env = dict(os.environ)
    for key, value in list(env.items()):
        fixed, changed = repair_msys(value)
        if changed:
            warn("ue_run: WARNING repaired MSYS-mangled environment %s=%r -> %r" % (key, value, fixed))
            env[key] = fixed
    env.update(extra)
    return env


# ---------------------------------------------------------------- verdict


def parse_log(text):
    """Pull markers and failure evidence out of a UE log (or plain shim stdout)."""
    results, starts, relevant = [], [], []
    done = False
    commandlet = None
    for line in text.splitlines():
        match = RESULT_RE.search(line)
        if match:
            try:
                results.append(json.loads(match.group(1)))
            except ValueError:
                relevant.append(line.rstrip())
            continue
        match = START_RE.search(line)
        if match:
            try:
                starts.append(json.loads(match.group(1)).get("script"))
            except ValueError:
                pass
            continue
        if DONE_RE.search(line):
            done = True
            continue
        if "Python script executed successfully" in line:
            commandlet = "success"
        elif "Python script executed with errors" in line:
            commandlet = "errors"
        if RELEVANT_RE.search(line) and not SUMMARY_REPEAT_RE.search(line):
            relevant.append(line.rstrip())
    return {
        "results": results,
        "starts": starts,
        "done": done,
        "commandlet": commandlet,
        "relevant": relevant,
        "closed": "Log file closed" in text,
    }


def _strip_log_prefix(line):
    return re.sub(r"^\[[^\]]*\]\[\s*\d+\]", "", line)


def verdict(parsed, expected, log_path, nullrhi=True, infra_cause=None, tail=20):
    """(exit_code, [summary lines]) from parse_log output and the scripts that should have run."""
    lines = []
    by_name = {}
    for result in parsed["results"]:
        by_name.setdefault(result.get("script"), []).append(result)
    passed = 0
    for path in expected:
        name = Path(path).name
        queue = by_name.get(name) or []
        result = queue.pop(0) if queue else None
        if result is None:
            started = name in parsed["starts"]
            lines.append("%-5s %-44s %s" % ("FAIL", name, "started, never finished"
                                            if started else "not reached"))
            continue
        ok = result.get("status") == "pass"
        passed += ok
        seconds = result.get("seconds")
        sec = ("%.1fs" % seconds) if isinstance(seconds, (int, float)) else "?"
        error = result.get("error") or ""
        lines.append(("%-5s %-44s %7s  %s" % ("PASS" if ok else "FAIL", name, sec, error)).rstrip())

    total = len(expected)
    infra = not parsed["done"] or infra_cause is not None
    word = "PASS" if (passed == total and not infra) else "FAIL"
    summary = "UE_RUN %s %d/%d  log=%s" % (word, passed, total, str(log_path).replace("\\", "/"))
    if infra:
        cause = infra_cause or "no UE_RUN_DONE marker - Unreal crashed, was killed, or never ran the shim"
        lines.append("INFRA FAILURE: %s" % cause)
        if parsed["commandlet"] == "errors":
            lines.append("  commandlet reported: Python script executed with errors (shim itself failed?)")
        evidence = parsed["relevant"][-tail:]
        if evidence:
            lines.append("last relevant log lines:")
            lines.extend("  " + _strip_log_prefix(line)[:300] for line in evidence)
        elif not parsed["closed"]:
            lines.append("  (no error lines; log never closed - killed or still being written)")
        summary += "  [infra]"
    if nullrhi:
        summary += "  " + NULLRHI_NOTE
    lines.append(summary)
    if infra:
        return 2, lines
    return (0 if passed == total else 1), lines


# ---------------------------------------------------------------- run


def _label(args, scripts):
    if args.suite:
        base = Path(args.suite).stem
    else:
        base = Path(scripts[0]).stem + ("_plus%d" % (len(scripts) - 1) if len(scripts) > 1 else "")
    # The shim path goes into -script=, which UE's FParse splits on separators: keep it plain.
    return re.sub(r"[^A-Za-z0-9_.-]", "_", base)[:60]


def _tail_markers(log_path, offset, started_at):
    """Print UE_RUN_START lines that appeared since `offset`; return the new offset."""
    try:
        with open(log_path, "rb") as handle:
            handle.seek(offset)
            chunk = handle.read()
    except OSError:
        return offset
    end = chunk.rfind(b"\n")
    if end < 0:
        return offset
    for line in chunk[:end].decode("utf-8", "replace").splitlines():
        match = START_RE.search(line)
        if match:
            try:
                name = json.loads(match.group(1)).get("script")
            except ValueError:
                continue
            print("  running %s  (t+%ds)" % (name, time.time() - started_at), flush=True)
    return offset + end + 1


def ue_repo_dirty(project_dir):
    """Tracked files with uncommitted changes in the UE project's git repo, or None if unknown.

    Several verify scripts save the map or assets as a side effect (verify_vita_chamber saves
    1-Medical). Before the UE project was version-controlled that was invisible; now a run that
    leaves the repo dirty is reported so the change is committed or restored, never forgotten.
    """
    try:
        out = subprocess.run(["git", "-C", str(project_dir), "status", "--porcelain", "-uno"],
                             capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if out.returncode != 0:
        return None
    return {line[3:].strip() for line in out.stdout.splitlines() if len(line) > 3}


def ue_repo_report(before, after, project_dir):
    """Summary lines for files this run changed (dirty after, clean before)."""
    if before is None or after is None:
        return []
    changed = sorted(after - before)
    if not changed:
        return []
    lines = ["UE repo : this run changed %d tracked file(s) in %s - commit them "
             "(tools/git/ship.py --ue-files ...) or restore them (git -C \"%s\" checkout -- <file>):"
             % (len(changed), project_dir, project_dir)]
    lines += ["            %s" % path for path in changed[:15]]
    if len(changed) > 15:
        lines.append("            ... and %d more" % (len(changed) - 15))
    return lines


def run(argv=None):
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(errors="replace")
        except (AttributeError, ValueError):
            pass
    args = parse_args(sys.argv[1:] if argv is None else argv)
    tools_dir = checkout_tools_dir()
    try:
        tokens = []
        if args.suite:
            suite_tokens, suite_path = read_suite(args.suite, tools_dir)
            tokens += suite_tokens
            print("suite   : %s (%d scripts)" % (suite_path, len(suite_tokens)))
        tokens += args.scripts
        scripts = [resolve_script(t, tools_dir) for t in tokens]
    except ResolveError as exc:
        print("UE_RUN FAIL 0/0  %s" % exc)
        return 2

    uproject = Path(args.uproject)
    exe = resolve_engine(args.engine)
    run_dir = uproject.parent / "Saved" / "ue_run"
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    stem = "%s_%s" % (stamp, _label(args, scripts))
    log_path = Path(args.log).resolve() if args.log else run_dir / (stem + ".log")
    shim_path = run_dir / (stem + "_shim.py")
    shim = generate_shim(scripts)
    cmd = build_command(exe, uproject, shim_path, log_path, render=args.render)
    nullrhi = not args.render

    print("tools   : %s" % tools_dir)
    for script in scripts:
        print("script  : %s" % script)
    for key, value in args.env_pairs.items():
        print("env     : %s=%s" % (key, value))

    if args.dry_run:
        for path, what in ((exe, "engine"), (uproject, "uproject")):
            if not path.is_file():
                print("WARNING : %s not found: %s" % (what, path))
        try:
            reason = ue_guard.busy_reason("run")
        except RuntimeError as exc:
            reason = str(exc)
        print("guard   : %s" % ("BUSY - " + reason if reason else "free"))
        print("command : %s" % subprocess.list2cmdline(cmd))
        print("shim    : %s" % shim_path)
        print("-" * 72)
        print(shim.rstrip())
        print("-" * 72)
        print("UE_RUN DRY-RUN %d script(s), nothing launched" % len(scripts))
        return 0

    for path, what in ((exe, "UnrealEditor-Cmd.exe"), (uproject, "uproject")):
        if not path.is_file():
            print("UE_RUN FAIL 0/%d  %s not found: %s" % (len(scripts), what, path))
            return 2

    env = child_environment(args.env_pairs)
    task = "ue_run %s" % " ".join(Path(s).stem for s in scripts)
    guard = ue_guard.UnrealGuard(task[:200], purpose="run", wait_seconds=args.wait)
    try:
        guard.acquire()
    except ue_guard.GuardBusy as exc:
        print("UE_RUN BUSY: %s" % exc.reason)
        return 2
    except RuntimeError as exc:
        print("UE_RUN BUSY: guard error - %s" % exc)
        return 2

    infra_cause = None
    exit_code = None
    dirty_before = ue_repo_dirty(uproject.parent)
    try:
        run_dir.mkdir(parents=True, exist_ok=True)
        log_path.parent.mkdir(parents=True, exist_ok=True)
        shim_path.write_text(shim, encoding="utf-8")
        if log_path.exists():
            log_path.unlink()  # never read a previous run's markers as this run's
        print("log     : %s" % log_path)
        print("launch  : %d script(s), %s, timeout %ds" % (
            len(scripts), "-nullrhi" if nullrhi else "real RHI (--render)", args.timeout), flush=True)
        started = time.time()
        proc = subprocess.Popen(cmd, env=env, stdin=subprocess.DEVNULL,
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        offset = 0
        try:
            while True:
                try:
                    exit_code = proc.wait(timeout=2)
                    break
                except subprocess.TimeoutExpired:
                    offset = _tail_markers(log_path, offset, started)
                    if time.time() - started > args.timeout:
                        infra_cause = "timeout after %ds - killed our UnrealEditor-Cmd (pid %d)" % (
                            args.timeout, proc.pid)
                        proc.kill()
                        exit_code = proc.wait()
                        break
        except KeyboardInterrupt:
            proc.kill()
            proc.wait()
            print("UE_RUN FAIL interrupted - killed our UnrealEditor-Cmd (pid %d)  log=%s"
                  % (proc.pid, log_path))
            return 2
        _tail_markers(log_path, offset, started)
        print("exited  : code %s after %.0fs (UE's exit code is not the verdict)"
              % (exit_code, time.time() - started))
    finally:
        try:
            guard.release()
        except (OSError, RuntimeError) as exc:  # never let a release hiccup replace the verdict
            print("WARNING : could not release ue_run.lock (%s); the next run takes it over as stale"
                  % exc)

    for line in ue_repo_report(dirty_before, ue_repo_dirty(uproject.parent), uproject.parent):
        print(line)
    if not log_path.is_file():
        print("INFRA FAILURE: Unreal wrote no log at %s (exit code %s)" % (log_path, exit_code))
        print("UE_RUN FAIL 0/%d  log=%s  [infra]" % (len(scripts), str(log_path).replace("\\", "/")))
        return 2
    text = log_path.read_text(encoding="utf-8", errors="replace").lstrip("\ufeff")
    code, lines = verdict(parse_log(text), scripts, log_path, nullrhi=nullrhi,
                          infra_cause=infra_cause)
    for line in lines:
        print(line)
    return code


if __name__ == "__main__":
    sys.exit(run())
