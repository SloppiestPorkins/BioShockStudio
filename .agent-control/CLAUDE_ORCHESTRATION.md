# Orchestration — how the Lead (this Claude Code session) uses it

This is the non-interactive replacement for `Start-AgentTeam.ps1` (four manual terminal windows). It
lets the Lead dispatch a local worker, get back a small structured result, and decide what happens
next — without a human relaying text between windows.

`Start-ClaudeLocal.ps1` / `Start-AgentTeam.ps1` / `Start-ClaudeCloud.ps1` are left in place (the
user's original interactive launchers) but are superseded by `agent.ps1` for orchestration. They are
useful if the user wants to sit down and drive a worker by hand.

**Why this doesn't route through the `claude` CLI itself:** tested directly (23 Aug 2026) — Ollama
0.32.15 does speak the Anthropic `/v1/messages` shape, so `claude --model qwen3-coder:30b` *starts*,
but non-interactive calls (`-p`) came back with `"result":""` on a successful turn, and adding `--bare`
or `--debug` made it hang past a 90s timeout. Non-deterministic and empty-result failures are worse
than a plain HTTP call for scripted dispatch. The controller instead calls Ollama's native
`/api/chat` directly — confirmed reliable, ~1–50s per call depending on prompt size.

## Commands

All run from the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 research "<task>" [options]
powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 code     "<task>" [options]
powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 test    "<task>" [options]
powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 review  "<task>" [options]
powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 status
powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 list
powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 result <TASK-ID>
powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 log    <TASK-ID>
powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 diff   <TASK-ID>
powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 pipeline "<goal>"
```

Options on `research`/`code`/`test`/`review`:

| Option | Meaning |
|---|---|
| `-Files a.cs,b.cs` | Repo-relative paths to inline as read-only context (or, for `code`, the files it's expected to touch). **The Lead picks these** — the controller does not auto-discover a task's files. |
| `-Parent TASK-ID` | Links to a prior task. Pulls that task's result as evidence; `code` inherits its `-Files` from the parent's `files`/`filesChanged` if none given; `review` gets the coder's actual diff inlined automatically; `test` applies the coder's uncommitted patch onto the tester worktree automatically. |
| `-Context "..."` | Free text the Lead wants inlined verbatim (a specific hypothesis, a byte offset, a constraint). |
| `-Grep pattern` | Controller runs `git grep -n` in the worker's worktree and inlines the first 200 hits — offload a repo-wide search instead of pasting one. |
| `-Glob *.cs` | Controller lists matching filenames (not content) in the worktree. |
| `-TestFilter Tier=Fast` | `test` only — passed to `dotnet test --filter`. Defaults to `Tier=Fast`. |
| `-TimeoutMinutes N` | Overrides the role's default (research 20 / code 30 / test 20 / review 15). |
| `-SkipBuild` | Skip the controller's automatic `dotnet build` (coder) / build+test (tester). |

## The Lead's actual workflow (matches AGENT_PROTOCOL.md §5)

1. `research "<narrow question>"` with `-Files`/`-Grep` pointing at what's relevant. **Read the result
   yourself** (`agent.ps1 result <id>`) — don't just trust the worker's own confidence label. Verify
   anything load-bearing by reading the cited file yourself, the same as you would for any subagent.
2. Decide whether implementation is justified. If not, stop here — a recorded negative is a valid
   outcome.
3. `code "<narrowly scoped task>" -Parent <research-id>`. Read the diff yourself:
   `agent.ps1 diff <coder-id>`. Never approve from the worker's own summary.
4. `test "<what to verify>" -Parent <coder-id>`. The controller applies the coder's uncommitted patch
   onto the tester worktree, runs `dotnet build` + `dotnet test` for real, feeds the actual output to
   the model as ground truth, and reverts the patch when done — the tester worktree is never left
   holding someone else's change. Read `controllerBuildExit`/`controllerTestExit` in the result, not
   just the model's prose.
5. `review "<what changed and why>" -Parent <coder-id>`. The reviewer gets the actual diff inlined
   automatically (never just the coder's description of it) plus the current content of the touched
   files for context. Look for its `APPROVE` / `APPROVE WITH FOLLOW-UP` / `REQUEST CHANGES` line.
6. **Make the integration call yourself.** The controller never merges, commits, or pushes anything —
   an approved change sits as an uncommitted diff in the coder worktree until the Lead decides to pull
   it in (e.g. `git -C <coder-worktree> diff` piped into the main worktree, reviewed, then applied and
   committed there in the normal way).

Treat every worker result as a junior engineer's first draft: plausible, occasionally wrong, never
self-certifying. The controller's job is to make dispatch and evidence-gathering cheap; the judgment
stays with the Lead.

## `pipeline`

`agent.ps1 pipeline "<goal>"` dispatches **Research only**, then stops and prints how to continue. It
does not chain into code/test/review automatically — per the user's instruction, the Lead stays in
control at every gate. There is no fully-automatic mode.

## Where things land

- `.agent-control/tasks/<ID>.json` — task lifecycle state (`QUEUED → RUNNING → COMPLETE / FAILED /
  TIMEOUT / BLOCKED`), machine-readable, read by `status`/`list`.
- `.agent-control/results/<ID>.md` — the concise, human-readable result. This is what `agent.ps1
  result` prints.
- `.agent-control/logs/<ID>.log` — the full system+user prompt and the raw model response, for when
  a result looks wrong and you need to see exactly what the worker was given and said.
- **These three directories are gitignored — they are run state, not the coordination layer.** The
  tracked coordination layer is `.agent/` (`PROJECT_STATE.md`, `KNOWN_ASSUMPTIONS.md`,
  `AGENT_PROTOCOL.md`, `TASK_QUEUE.md`, `reports/…`). When a worker result is worth keeping as
  evidence, the Lead copies the relevant part into `.agent/reports/REPORT-<TASK-ID>.md` by hand — the
  controller does not do this automatically, so nothing gets promoted to tracked evidence without the
  Lead's judgment.

## Safety, concretely

- **Worktree isolation.** Every role has its own worktree and branch (`agent/research`,
  `agent/coder`, `agent/tests`, `agent/review`). `code` only ever writes inside the coder worktree;
  path-safety checks reject any file path from the model containing `..`, a drive letter, a leading
  slash, or that resolves outside the worktree root, before anything is written.
- **Dirty-worktree gate.** Before dispatch, the controller runs `git status --porcelain` in the
  target worktree (excluding the pre-existing `.agent/` scaffolding folder, which is expected
  content, not work-in-progress). Anything else dirty → the task is marked `BLOCKED` and nothing
  runs. This is what stops two dispatches from clobbering each other.
- **No shell execution of model output, structurally, not by blocklist.** The controller never takes
  a string the model wrote and runs it as a command. The only commands it ever executes are a fixed,
  hardcoded set (`git status`, `git diff`, `git add -N`, `git apply` / `git apply -R`, `dotnet build`,
  `dotnet test`), always with controller-supplied arguments. The model's only channel to affect the
  filesystem is the `<<<FILE: path>>>` block, which is path-checked before every write. There is
  therefore no command-injection surface to defend with a blocklist; `blockedCommandSubstrings` in
  `agent-config.json` is kept as a documented intent for anyone who later adds real command execution,
  not as an active runtime check today.
- **Tester validation without merging.** `Sync-CoderChangesToTester` (in `lib/Controller.ps1`) takes
  the coder's live, uncommitted `git diff` and applies it with `git apply` onto the tester worktree —
  never a merge, never touching the coder's or main worktree. `Undo-CoderChangesInTester` reverses it
  with `git apply -R` in a `finally` block, so it runs even if the model call fails or times out. If
  the reverse-apply leaves residue, the controller prints a warning naming the worktree to check by
  hand rather than silently discarding anything.
- **No auto-commit, no auto-merge, no force-anything.** Grep `lib/Controller.ps1` — there is no
  `git commit`, `git merge`, `git push`, `git reset --hard`, or `git clean` call anywhere in it.
- **GPU serialization.** `.agent-control/.gpu.lock` is created with `FileMode.CreateNew` (atomic
  create-or-fail). A second dispatch waits and polls every 5s; if the lock's owning PID is dead, it's
  treated as stale and cleared. Only one model call runs at a time by default
  (`maxConcurrentInference` in `agent-config.json`, currently unused beyond documenting the intent —
  the lock itself is what enforces "one at a time").
- **Timeouts are real, not advisory.** The Ollama call uses `Invoke-RestMethod -TimeoutSec`, which
  aborts client-side regardless of server behavior. `dotnet build`/`dotnet test` run through
  `Invoke-TimedProcess`, which calls `Process.Kill()` if `WaitForExit` doesn't return in time. A
  timed-out task is marked `TIMEOUT`, not silently retried — the controller never retries a task on
  its own.

## Known limitations (see the final report for the complete list)

- File selection for a task's context is manual (`-Files`/`-Grep`/`-Glob`), not automatic
  repository-wide discovery. This was a deliberate simplification: the Lead already does task
  decomposition and knows which files matter, and auto-discovery over a 32k-context local model is a
  much larger and more fragile feature.
- The coder role can only write whole-file replacements (via `<<<FILE: path>>>` blocks), not apply a
  diff — chosen because LLM-generated unified diffs fail to apply far more often than they succeed,
  especially from a smaller local model. This is fine for the "small, narrowly scoped change" tasks
  this whole setup is meant for; it is a poor fit for a task that should touch a large file lightly.
- One HTTP call, one response. There is no multi-turn tool loop (the worker cannot itself run `grep`,
  read an extra file mid-task, or ask a clarifying question) — everything it needs must be supplied
  via `-Files`/`-Grep`/`-Glob`/`-Context`/`-Parent` at dispatch time.
