"""One Unreal process at a time for the BioShockUE5 project: detect live ones, hold a shared lock.

Two Unreal processes against one project corrupt or kill each other's runs, and a plugin rebuild
while any editor is alive compiles for minutes and then fails to copy the locked DLL. Claude's
hooks cannot prevent this -- workers in git worktrees never see them -- so the guard lives in the
scripts themselves: ue_run.py, capture_shot.ps1 and rebuild_runtime_fast.ps1 all go through here.

Two signals, both checked every time:
  - live processes: UnrealEditor.exe, UnrealEditor-Cmd.exe, UnrealBuildTool / AutomationTool
    (as their own .exe or as dotnet.exe running the .dll -- the command line tells them apart from
    the repo's own dotnet builds);
  - the lock file C:/Users/Jack/Documents/BioShockUE5/Saved/ue_run.lock, shared by every checkout
    and worktree. It records pid, process creation time, task, start time and cwd. A lock whose
    pid is dead (or has been reused by another process) is stale and is taken over with a note.

It NEVER kills anything. If the user's editor is open the caller reports that and stops.

Importable:
    import ue_guard
    with ue_guard.UnrealGuard("ue_run verify_water", purpose="run", wait_seconds=0):
        ...                                      # raises ue_guard.GuardBusy(reason) if busy

CLI (all output on stdout, so PowerShell callers never need 2>&1):
    python ue_guard.py status                                 # exit 0 free, 1 busy
    python ue_guard.py check --for rebuild|run|capture        # exit 1 + one-line reason if busy
    python ue_guard.py acquire --for capture --task NAME --owner-pid PID [--wait SEC]
    python ue_guard.py adopt --owner-pid PID --new-pid CHILD  # hand the lock to a child process
    python ue_guard.py release --owner-pid PID                # only removes a lock PID owns
    python ue_guard.py release --force                        # clear a stuck lock (kills nothing)

Lock path override (tests): environment variable UE_GUARD_LOCK.
"""

import argparse
import base64
import csv
import datetime
import io
import json
import os
import subprocess
import sys
import time
from pathlib import Path

DEFAULT_LOCK = r"C:\Users\Jack\Documents\BioShockUE5\Saved\ue_run.lock"
POLL_SECONDS = 5.0

EDITOR_IMAGES = {"unrealeditor.exe", "unrealeditor-cmd.exe"}
BUILD_IMAGES = {"unrealbuildtool.exe", "automationtool.exe"}
# dotnet.exe hosts UBT/UAT in UE5; only its command line says which.
BUILD_DLL_MARKERS = ("UnrealBuildTool", "AutomationTool")

PURPOSES = ("run", "capture", "rebuild")


class GuardBusy(Exception):
    """Raised by acquire() when Unreal is busy. str(exc) is the one-line reason."""

    def __init__(self, reason):
        super().__init__(reason)
        self.reason = reason


def lock_path():
    return Path(os.environ.get("UE_GUARD_LOCK") or DEFAULT_LOCK)


# ---------------------------------------------------------------- processes


def _run_quiet(argv, timeout=20):
    try:
        done = subprocess.run(
            argv, capture_output=True, text=True, errors="replace", timeout=timeout,
            creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    except (OSError, subprocess.SubprocessError):
        return None
    return done.stdout if done.returncode == 0 else None


def parse_tasklist_csv(text):
    """[(image, pid)] from `tasklist /FO CSV /NH` output."""
    rows = []
    for row in csv.reader(io.StringIO(text)):
        if len(row) >= 2 and row[1].strip().isdigit():
            rows.append((row[0].strip(), int(row[1])))
    return rows


def _dotnet_command_lines():
    """{pid: command line} for dotnet.exe, via CIM (tasklist cannot show command lines)."""
    script = ("Get-CimInstance Win32_Process -Filter \"Name='dotnet.exe'\" | ForEach-Object { "
              "'{0}`t{1}' -f $_.ProcessId, $_.CommandLine }")
    encoded = base64.b64encode(script.encode("utf-16-le")).decode("ascii")
    out = _run_quiet(["powershell", "-NoProfile", "-NonInteractive", "-EncodedCommand", encoded])
    if out is None:
        return None
    lines = {}
    for line in out.splitlines():
        pid, _, cmd = line.partition("\t")
        if pid.strip().isdigit():
            lines[int(pid)] = cmd.strip()
    return lines


def classify_processes(rows, dotnet_cmdlines=None):
    """Pick the Unreal ones out of tasklist rows. Returns [{"pid", "name", "kind"}]."""
    found = []
    for image, pid in rows:
        low = image.lower()
        if low in EDITOR_IMAGES:
            found.append({"pid": pid, "name": image, "kind": "editor"})
        elif low in BUILD_IMAGES:
            found.append({"pid": pid, "name": image, "kind": "build"})
        elif low == "dotnet.exe" and dotnet_cmdlines:
            cmd = dotnet_cmdlines.get(pid, "")
            for marker in BUILD_DLL_MARKERS:
                if marker.lower() in cmd.lower():
                    found.append({"pid": pid, "name": "dotnet.exe (%s)" % marker, "kind": "build"})
                    break
    return found


def live_unreal_processes(include_build_tools=True):
    """Live Unreal processes as [{"pid", "name", "kind": "editor"|"build"}].

    Raises RuntimeError if tasklist itself fails -- a guard that cannot see must not say "free".
    """
    out = _run_quiet(["tasklist", "/FO", "CSV", "/NH"])
    if out is None:
        raise RuntimeError("tasklist failed; cannot tell whether Unreal is running")
    rows = parse_tasklist_csv(out)
    cmdlines = None
    if include_build_tools and any(image.lower() == "dotnet.exe" for image, _ in rows):
        cmdlines = _dotnet_command_lines()
    found = classify_processes(rows, cmdlines)
    if not include_build_tools:
        found = [p for p in found if p["kind"] == "editor"]
    return found


# ---------------------------------------------------------------- pid liveness


def _process_created(pid):
    """Creation FILETIME of a live pid, 0 if alive but unqueryable, None if not running."""
    if pid <= 0:
        return None
    if os.name != "nt":
        try:
            os.kill(pid, 0)
        except OSError:
            return None
        return 0
    import ctypes
    from ctypes import wintypes

    k32 = ctypes.WinDLL("kernel32", use_last_error=True)
    k32.OpenProcess.restype = wintypes.HANDLE
    k32.OpenProcess.argtypes = (wintypes.DWORD, wintypes.BOOL, wintypes.DWORD)
    k32.GetExitCodeProcess.argtypes = (wintypes.HANDLE, ctypes.POINTER(wintypes.DWORD))
    k32.GetProcessTimes.argtypes = (wintypes.HANDLE,) + (ctypes.POINTER(wintypes.FILETIME),) * 4
    k32.CloseHandle.argtypes = (wintypes.HANDLE,)
    handle = k32.OpenProcess(0x1000, False, pid)  # PROCESS_QUERY_LIMITED_INFORMATION
    if not handle:
        # Access denied means it exists (another user's / elevated process).
        return 0 if ctypes.get_last_error() == 5 else None
    try:
        code = wintypes.DWORD()
        if k32.GetExitCodeProcess(handle, ctypes.byref(code)) and code.value != 259:
            return None  # exited; someone still holds a handle to it
        times = [wintypes.FILETIME() for _ in range(4)]
        if not k32.GetProcessTimes(handle, *[ctypes.byref(t) for t in times]):
            return 0
        return (times[0].dwHighDateTime << 32) | times[0].dwLowDateTime
    finally:
        k32.CloseHandle(handle)


def pid_alive(pid, created=None):
    """True if pid is running and (when known) is the same process that wrote the lock."""
    now = _process_created(int(pid))
    if now is None:
        return False
    if created and now and int(created) != now:
        return False  # pid reused by an unrelated process
    return True


# ---------------------------------------------------------------- lock file


def read_lock(path=None):
    path = Path(path or lock_path())
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return None
    except (OSError, ValueError):
        return {"pid": 0, "task": "unreadable lock file", "corrupt": True}
    return data if isinstance(data, dict) else {"pid": 0, "task": "bad lock", "corrupt": True}


def lock_is_live(data):
    return bool(data) and not data.get("corrupt") and pid_alive(data.get("pid", 0),
                                                                data.get("created"))


def describe_lock(data):
    if not data:
        return "free"
    return "pid %s, task '%s', since %s, cwd %s" % (
        data.get("pid"), data.get("task", "?"), data.get("started", "?"), data.get("cwd", "?"))


class _Mutex:
    """Serialises the read-check-write of the lock file across processes (msvcrt byte lock)."""

    def __init__(self, path):
        self.path = Path(str(path) + ".mutex")
        self.handle = None

    def __enter__(self):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.handle = open(self.path, "a+b")
        if os.name == "nt":
            import msvcrt
            deadline = time.time() + 10
            while True:
                try:
                    self.handle.seek(0)
                    msvcrt.locking(self.handle.fileno(), msvcrt.LK_NBLCK, 1)
                    break
                except OSError:
                    if time.time() > deadline:
                        self.handle.close()
                        raise RuntimeError("could not lock %s for 10s" % self.path)
                    time.sleep(0.05)
        return self

    def __exit__(self, *exc):
        if os.name == "nt":
            import msvcrt
            try:
                self.handle.seek(0)
                msvcrt.locking(self.handle.fileno(), msvcrt.LK_UNLCK, 1)
            except OSError:
                pass
        self.handle.close()
        return False


def _retry_io(fn, *args):
    """Run a replace/unlink, retrying briefly: on Windows a concurrent reader without delete
    sharing makes them fail with PermissionError for a moment."""
    for attempt in range(20):
        try:
            return fn(*args)
        except PermissionError:
            if attempt == 19:
                raise
            time.sleep(0.05)


def _write_lock(path, owner_pid, task):
    data = {
        "pid": owner_pid,
        "created": _process_created(owner_pid) or 0,
        "task": task,
        "started": datetime.datetime.now().isoformat(timespec="seconds"),
        "cwd": os.getcwd(),
    }
    tmp = Path(str(path) + ".tmp")
    tmp.write_text(json.dumps(data, indent=2), encoding="utf-8")
    _retry_io(os.replace, tmp, path)
    return data


# ---------------------------------------------------------------- verdicts


def process_reason(purpose, procs):
    """One-line reason Unreal processes block `purpose`, or None."""
    if not procs:
        return None
    editors = [p for p in procs if p["kind"] == "editor"]
    listing = ", ".join("%s pid %d" % (p["name"], p["pid"]) for p in procs)
    if purpose == "rebuild" and editors:
        return ("%s running - it holds the BioShockRuntime DLL, so the rebuild would compile then "
                "fail to copy. Close it first; if it is the user's editor, ask them (never kill it)."
                % listing)
    return ("%s running - only one Unreal process may use the project at a time. If it is the "
            "user's editor, report it and stop (never kill it); otherwise wait for it to finish."
            % listing)


def busy_reason(purpose="run", path=None, procs=None, ignore_lock_pid=None):
    """One-line reason Unreal is busy for `purpose`, or None if free. Never modifies anything."""
    if procs is None:
        procs = live_unreal_processes()
    reason = process_reason(purpose, procs)
    if reason:
        return reason
    with _Mutex(Path(path or lock_path())):
        data = read_lock(path)
    if lock_is_live(data) and int(data.get("pid", 0)) != (ignore_lock_pid or -1):
        return "ue_run.lock held by %s" % describe_lock(data)
    return None


class UnrealGuard:
    """acquire()/release() or `with UnrealGuard(task):` -- holds the shared lock for a run."""

    def __init__(self, task, purpose="run", wait_seconds=0, owner_pid=None, path=None,
                 out=None, check_processes=True):
        if purpose not in PURPOSES:
            raise ValueError("purpose must be one of %s" % (PURPOSES,))
        self.task = task
        self.purpose = purpose
        self.wait_seconds = wait_seconds
        self.owner_pid = int(owner_pid or os.getpid())
        self.path = Path(path or lock_path())
        self.out = out or sys.stdout
        self.check_processes = check_processes
        self.held = False

    def _note(self, text):
        print("ue_guard: " + text, file=self.out, flush=True)

    def try_acquire(self):
        """Take the lock if free. Returns None on success, else the busy reason."""
        procs = live_unreal_processes() if self.check_processes else []
        reason = process_reason(self.purpose, procs)
        if reason:
            return reason
        with _Mutex(self.path):
            data = read_lock(self.path)
            if data and int(data.get("pid", 0)) != self.owner_pid:
                if lock_is_live(data):
                    return "ue_run.lock held by %s" % describe_lock(data)
                self._note("taking over stale lock (%s) - that process is gone"
                           % describe_lock(data))
            _write_lock(self.path, self.owner_pid, self.task)
        self.held = True
        return None

    def acquire(self):
        deadline = time.time() + max(0, self.wait_seconds)
        announced = None
        while True:
            reason = self.try_acquire()
            if reason is None:
                return self
            if time.time() >= deadline:
                raise GuardBusy(reason)
            if reason != announced:
                self._note("busy, waiting up to %ds: %s" % (self.wait_seconds, reason))
                announced = reason
            time.sleep(min(POLL_SECONDS, max(0.1, deadline - time.time())))

    def release(self):
        released = release(self.owner_pid, path=self.path)
        self.held = False
        return released

    def __enter__(self):
        return self.acquire()

    def __exit__(self, *exc):
        self.release()
        return False


def release(owner_pid, path=None, force=False):
    """Remove the lock if owner_pid holds it (or force). Returns True if a lock was removed."""
    path = Path(path or lock_path())
    with _Mutex(path):
        data = read_lock(path)
        if not data:
            return False
        if not force and int(data.get("pid", 0)) != int(owner_pid or -1):
            return False
        try:
            _retry_io(path.unlink)
        except FileNotFoundError:
            return False
    return True


def adopt(owner_pid, new_pid, path=None):
    """Hand a lock held by owner_pid to new_pid (e.g. the game process a script just started),
    so the lock dies with that process even if the launching shell lingers or crashes."""
    path = Path(path or lock_path())
    with _Mutex(path):
        data = read_lock(path)
        if not data or int(data.get("pid", 0)) != int(owner_pid):
            return False
        _write_lock(path, int(new_pid), data.get("task", "?"))
    return True


# ---------------------------------------------------------------- CLI


def _print_status(procs, data):
    if procs:
        print("Unreal processes:")
        for p in procs:
            print("  %-34s pid %d" % (p["name"], p["pid"]))
    else:
        print("Unreal processes: none")
    if not data:
        print("lock: free (%s)" % lock_path())
    elif lock_is_live(data):
        print("lock: HELD - %s" % describe_lock(data))
    else:
        print("lock: stale - %s (will be taken over)" % describe_lock(data))


def main(argv=None):
    parser = argparse.ArgumentParser(description="Single-Unreal-process guard for BioShockUE5.")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status", help="print Unreal processes and the lock; exit 0 free / 1 busy")
    p_check = sub.add_parser("check", help="exit 1 with a one-line reason if busy")
    p_check.add_argument("--for", dest="purpose", choices=PURPOSES, default="run")
    p_acq = sub.add_parser("acquire", help="check, then take the lock for --owner-pid")
    p_acq.add_argument("--for", dest="purpose", choices=PURPOSES, default="run")
    p_acq.add_argument("--task", default="manual")
    p_acq.add_argument("--owner-pid", type=int, default=None,
                       help="process that owns the lock (default: the calling shell)")
    p_acq.add_argument("--wait", type=int, default=0)
    p_adopt = sub.add_parser("adopt", help="transfer the lock to another pid")
    p_adopt.add_argument("--owner-pid", type=int, required=True)
    p_adopt.add_argument("--new-pid", type=int, required=True)
    p_rel = sub.add_parser("release", help="remove the lock if --owner-pid holds it")
    p_rel.add_argument("--owner-pid", type=int, default=None)
    p_rel.add_argument("--force", action="store_true",
                       help="remove whoever holds it (only after checking nothing Unreal runs)")
    args = parser.parse_args(argv)

    try:
        if args.cmd == "status":
            procs = live_unreal_processes()
            data = read_lock()
            _print_status(procs, data)
            reason = busy_reason("run", procs=procs)
            print("BUSY: " + reason if reason else "FREE")
            return 1 if reason else 0
        if args.cmd == "check":
            reason = busy_reason(args.purpose)
            if reason:
                print("BUSY (%s): %s" % (args.purpose, reason))
                return 1
            return 0
        if args.cmd == "acquire":
            owner = args.owner_pid or os.getppid()
            try:
                UnrealGuard(args.task, purpose=args.purpose, wait_seconds=args.wait,
                            owner_pid=owner).acquire()
            except GuardBusy as exc:
                print("BUSY (%s): %s" % (args.purpose, exc.reason))
                return 1
            return 0
        if args.cmd == "adopt":
            if not adopt(args.owner_pid, args.new_pid):
                print("ue_guard: pid %d does not hold the lock; nothing adopted" % args.owner_pid)
                return 1
            return 0
        if args.cmd == "release":
            if not args.force and args.owner_pid is None:
                parser.error("release needs --owner-pid or --force")
            removed = release(args.owner_pid, force=args.force)
            if args.force:
                print("ue_guard: lock %s" % ("removed" if removed else "was not present"))
            return 0
    except RuntimeError as exc:
        print("BUSY: guard error - %s" % exc)
        return 1
    return 2


if __name__ == "__main__":
    sys.exit(main())
