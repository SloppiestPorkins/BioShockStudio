---
name: ue-run
description: Use whenever you are about to run any Unreal headless, commandlet or UE-Python script (verify_*, run_*, probes) against the BioShockUE5 project, rebuild the BioShockRuntime plugin, or check whether Unreal is running for the BioShock project. It gives the one command to use, how to read its verdict, and the one-Unreal-process rule.
---

# ue-run: headless Unreal for BioShockUE5

> Commands below run from the repo root. Sessions usually start in `C:/Users/Jack/Documents/AI Test`,
> so `cd C:/Users/Jack/Documents/BioshockHavok` first (or the worktree you are testing).


Never hand-type `UnrealEditor-Cmd.exe ... -run=pythonscript`. Use `tools/ue5/ue_run.py`. It
repairs Git-Bash path mangling, fixes sibling imports, holds the shared single-process lock, and
gives a verdict read from result markers in the log. UE's exit code is not the verdict: it has
returned 127 on runs whose script finished.

## Run scripts

```bash
python tools/ue5/ue_run.py verify_water                    # bare name, file name or path
python tools/ue5/ue_run.py verify_water verify_door        # several scripts, ONE editor boot
python tools/ue5/ue_run.py --suite medical-core            # tools/ue5/suites/medical-core.txt
python tools/ue5/ue_run.py verify_water --env BIOSHOCK_WATER_MAP=/Game/BioShockSlice/1-Medical
python tools/ue5/ue_run.py verify_water --dry-run          # print the command + shim, launch nothing
```

| flag | meaning |
|---|---|
| `--render` | leave out `-nullrhi` (a real RHI, but still headless, still not a screenshot) |
| `--env K=V` | env var for the Unreal process, repeatable. Scripts read their options this way |
| `--log PATH` | log path. Default `BioShockUE5/Saved/ue_run/<timestamp>_<name>.log` |
| `--timeout SEC` | default 1800. On timeout it kills only its own child |
| `--wait SEC` | wait this long for a busy Unreal or lock (default 0, which refuses at once) |
| `--uproject P` / `--engine P` | defaults `BioShockUE5.uproject` / `G:/Games/UE_5.7` |

- Run it from the checkout you are testing. Bare names resolve against the `tools/ue5` of the
  checkout that holds the working directory, so a worktree runs its own code.
- Works from Git Bash and from PowerShell. Mangled `/Game/...` args are repaired with a warning.
  Even so, prefer `MSYS_NO_PATHCONV=1` when you pass asset paths from Git Bash.
- A full boot takes about 30-90 s. Put longer runs in the background (`run_in_background`); the
  output prints a `running <script>` line as each script starts.

## Read the verdict

```
PASS  verify_water.py                           12.3s
FAIL  verify_vita_chamber.py                     4.1s  RuntimeError: vita-chamber: | - no chamber
UE_RUN FAIL 1/2  log=C:/Users/Jack/Documents/BioShockUE5/Saved/ue_run/....log  (nullrhi: render-blind - ...)
```

- Exit `0`: everything passed. Exit `1`: at least one script failed; the error is on its line, and
  the full traceback is in the log as `LogPython: Error:` lines.
- Exit `2`: an infrastructure failure, or Unreal was busy. `INFRA FAILURE` means the shim never
  printed `UE_RUN_DONE`: Unreal crashed, timed out or failed to boot. The last relevant log lines
  (Fatal, Assertion, Ensure, LogPython: Error) are printed below it. Scripts marked
  `not reached` never ran, so they are neither passes nor failures. Fix the crash first.
- `UE_RUN BUSY: ...` means another Unreal process or the lock was in the way (see below).
- Report the `UE_RUN ...` line word for word, including the log path.
- `UE repo : this run changed N tracked file(s)` means a script saved the map or assets (e.g.
  verify_vita_chamber saves 1-Medical). Decide: commit them (`tools/git/ship.py --ue-files ...`)
  if the change is wanted, or restore them with `git -C C:/Users/Jack/Documents/BioShockUE5
  checkout -- <file>` if they are test side effects. Never leave the UE repo silently dirty.

## Render-blind caveat

By default runs use `-nullrhi`, which draws nothing. A PASS proves data and gameplay state only.
It **never** closes a visual bug (grey walls, wrong materials, lighting, decals, glass, water,
viewmodel framing). For anything about how it looks, use the `visual-done` skill (a rendered
capture you actually look at). `--render` does not change this: it is still not a picture.

## One Unreal process at a time

Two Unreal processes against one project corrupt or kill each other's runs. `ue_run.py`,
`capture_shot.ps1` and `rebuild_runtime_fast.ps1` all check through `tools/ue5/ue_guard.py`, using
the lock `BioShockUE5/Saved/ue_run.lock` that every checkout and worktree shares.

```bash
python tools/ue5/ue_guard.py status                  # processes + lock; exit 0 free, 1 busy
python tools/ue5/ue_guard.py check --for rebuild     # or run / capture; one-line reason if busy
```

- If `UnrealEditor.exe` is running, it is probably the user's editor. **Never kill it**, and never
  kill any Unreal process you did not start. Tell the user which PID is blocking you and stop, or
  retry later with `--wait`.
- A lock whose owner has died is stale; the next run takes it over and prints a note.
  `python tools/ue5/ue_guard.py release --force` clears a stuck lock. Use it only after `status`
  shows no Unreal process and you have confirmed the holding PID is not doing Unreal work.
- Run Unreal jobs one after another. Never start two in parallel, even from different worktrees.

## Throwaway probe scripts

- Write probes to the session scratchpad, never into `tools/ue5/`, unless the probe is meant to
  be kept. Run one by path: `python tools/ue5/ue_run.py <scratchpad>/probe_x.py`. Its own folder
  goes first on `sys.path`. To import repo modules, add `tools/ue5` yourself.
- Before you call any `unreal` API, look it up in `references/unreal-api-in-use.md` and copy a
  known-good call from its example file:line. If a name is not listed, it is a guess. Guard it
  with `hasattr(unreal, "Name")` and fail loudly. Guessed names killed 41 runs with AttributeError.
- Use keyword args for rotators: `unreal.Rotator(pitch=..., yaw=..., roll=...)`. The positional
  order is roll, pitch, yaw, not what you would expect.
- Put `main()` under `if __name__ == "__main__":`. Raise on failure (`RuntimeError` listing every
  failure) and do not swallow exceptions. Write any JSON report to `%TEMP%`.
- Runtime switches for `-game` captures (`-bioshockshot...`, `-bioshockverify...`) are listed in
  `references/bioshock-switches.md`.

## Rebuild the BioShockRuntime plugin

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1 -CleanModule
```

- It refuses before compiling if any Unreal process is alive (an open editor locks the DLL).
- Its last line is exactly `Result: Succeeded` or `FAILED: <reason>`. Judge the rebuild by that
  line only. UBT's own result line appears as `UBT Result: ...`.
- Rebuild, then `ue_run`. Never do both at once.

## Suites

`tools/ue5/suites/NAME.txt` lists one script per line; `#` starts a comment. Every script in a
suite shares one editor boot, so world state can leak from one script to the next. If a script
fails only inside a suite, rerun it alone before you call it a regression. `medical-core` is the
29 Sept Medical regression set.

## Regenerate the references

```bash
python tools/ue5/gen_ue_reference.py <this skill>/references [--logs <dir-with-ue-logs>]
```

Regenerate after adding UE-Python scripts or `-bioshock*` switches. `--logs` mines extra logs for
AttributeErrors, which it flags as known-missing APIs.
