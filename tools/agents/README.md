# tools/agents — parallel coding workers

Farm queued tasks out to coding agents so BioShock work runs **in parallel** with the interactive
Claude session and with Cursor. Each worker gets its own throwaway git worktree beside the repo, so
no two of them (and not the main tree) ever edit the same files at once.

This is the wider sibling of `tools/backup-agent/` (which drives aider + Ollama when Claude usage
runs out). Same safety model, more workers, and it isolates with worktrees instead of sharing one
tree.

## Workers

| `worker:` | Backed by | Cost | Parallelism | Notes |
|---|---|---|---|---|
| `chatgpt`  | `codex exec`, signed in with the machine's **ChatGPT account** | ChatGPT plan quota | full (cloud) | The "use ChatGPT as a worker" path. `codex login status` shows the account. Smoke-tested working. |
| `qwen`     | `codex exec --oss --local-provider ollama -m qwen2.5-coder:14b` | free | one at a time | ~9 GB (fits the 12 GB card) **and** exposes tool-calling, which codex needs. The reliable local worker. |
| `qwen-big` | `codex exec --oss --local-provider ollama -m qwen3-coder:30b` | free | one at a time | Stronger, but 18 GB on a 12 GB card — has hung 600 s+ before (`.aider.conf.yml`). Only with someone watching. |
| `cursor`   | standalone `cursor-agent` CLI | Cursor plan quota | full (cloud) | Installed at `%LOCALAPPDATA%\cursor-agent\` (3.x), logged in. The orchestrator resolves the `.cmd` shim directly (it is on the *user* PATH, not always this process's, and bypasses Restricted execution policy). The Cursor **GUI** is a separate lane via `.cursor/hooks`. |

`deepseek-coder-v2:16b` is **not** an option here — it doesn't expose tools to codex. It still works
via `tools/backup-agent/` (aider parses its own edit blocks).

Local workers share one GPU, so the orchestrator serialises them with a lock regardless of
`-Parallel`.

### The `cursor` worker

Cursor's headless agent (`cursor-agent`, 3.x) is a separate binary from the `cursor` editor
launcher. It is installed at `%LOCALAPPDATA%\cursor-agent\` and logged in. `Get-WorkerSpec`
resolves `cursor-agent.cmd` by explicit path (the install dir is on the *user* PATH but not
always the orchestrator process's, and the bare name can hit `cursor-agent.ps1` which Restricted
execution policy blocks — the `.cmd` shim re-invokes it with `-ExecutionPolicy Bypass`).
cursor-agent 3.x uses `--workspace <dir>` (not `--cwd`) and needs `--trust` for headless runs.

If it is ever missing, `run` refuses `worker: cursor` tasks with a clear message; reinstall per
Cursor's CLI docs and `cursor-agent login`. The Cursor desktop app is a separate lane
(`.cursor/hooks/continue-phase4.py`) and needs nothing.

## Use

This machine has Windows PowerShell 5.1 only, with script execution Restricted, so every call needs
`-ExecutionPolicy Bypass`:

```bat
set A=powershell -NoProfile -ExecutionPolicy Bypass -File tools\agents\orchestrator.ps1

%A% list                 :: pending tasks
%A% run                  :: dispatch all pending, up to -Parallel at once
%A% run -Task ai-ini     :: just one
%A% status               :: results table + patch paths
%A% apply -Task ai-ini   :: git apply the patch into the main tree (no commit)
%A% clean                :: remove the agent-* worktrees
```

`run` blocks while workers finish, but Ctrl-C is safe — the background jobs keep going and
`status` re-reads their results. Worktrees are left in place (`../BioShockHavok-agent-<id>`) so you
can open a failing one and look.

## Writing a task

Copy `tasks/_TEMPLATE.md` to `tasks/<id>.md`. Frontmatter + a free-text brief:

```markdown
---
worker: chatgpt
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: src/**, tests/**
---
Create src/BioShockStudio.Core/Config/AiTuningConfig.cs. Parse [Ai.ini] ...
Check: [SecurityCamera] TrackingSpeed = 2.0 ...
Do not touch tools/ue5/**.
```

One task = one landable change. Brief it like an engineer who can't ask questions: exact files,
the shape of the result, a concrete value to check, what not to touch.

## Safety model

- Workers **never commit and never push.** Changes stay in the worker's worktree, are captured as
  `runs/<id>/changes.patch`, and wait for review.
- Local worktree edits run under `codex --sandbox workspace-write` (writes confined to the
  worktree). `-Yolo` drops that — don't, unless you're watching.
- `verify` runs in the worktree after the edit; PASS/FAIL is recorded. A failing task doesn't block
  the others (they're isolated).
- `apply` stages a reviewed patch into the main tree for a human/Claude to check. It still does not
  commit. After you commit, create `tasks/<id>.done` so the task isn't re-run.

## What's tracked vs transient

Tracked: `orchestrator.ps1`, `README.md`, `tasks/*.md`, `tasks/*.done`.
Ignored (`.gitignore`): `runs/` (logs, patches, verify output), `.local.lock`.
Worktrees live outside the repo, so they need no ignore rule.
