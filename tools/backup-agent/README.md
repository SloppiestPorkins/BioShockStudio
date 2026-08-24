# Backup agent

A way for this repo's work to keep moving when Claude usage runs out, using local Ollama models
through [aider](https://aider.chat) instead. Set up 24 Aug 2026, at the user's request.

## Safety model — read this before running it

**It never commits.** `../.aider.conf.yml` sets `auto-commits: false`. Every edit lands in the
working tree only, exactly like this session's own qwen-drafted changes did before Claude reviewed,
built, tested and committed them. Commit review is deliberately kept a human (or Claude) step, not
something the local model does unsupervised — this project holds itself to a high correctness bar
(`docs/ENGINEERING_RULES.md`), and the local model has already produced real bugs earlier this
session that needed catching before landing (a hallucinated struct property, a stale-variable
scoping bug, an empty-slot regression) — the same thing could happen here with nobody watching.

**It runs the fast test tier after every task** (`auto-test: true` in `.aider.conf.yml`) and the
wrapper script (`run.ps1`) stops the whole queue if that fails, rather than piling more edits on a
broken tree. This catches an obviously broken change; it does not replace review, and it cannot
catch the "numerically fine, visibly wrong" failure mode this project's own `docs/HANDOFF.md` §4
records repeatedly — several of those needed a live UE5 run or a render to actually catch.

## What's set up

- **`../.aider.conf.yml`** — model (`ollama_chat/qwen3-coder:30b`, `qwen2.5-coder:14b` as the weak
  model for commit-message-style small tasks), no auto-commits, non-interactive, fast-tier auto-test.
- **A dedicated Python 3.12 venv** at `C:\Users\Jack\.backup-agent-venv\` (not the system Python) with
  `aider-chat` installed, so this doesn't collide with anything else on the machine.
- **`task-01-export-character-rigs.md`**, **`task-02-import-character-rigs-into-levels.md`** — the
  two remaining pieces of the level-placed-character-animation feature scoped this session (the
  first piece, the `Group` field on `LevelAssetDocument`, already landed and is committed). Each
  file is a self-contained brief: what's already known, what to read before assuming, and what
  "done" means for that task specifically, including "say so plainly" instructions for the parts
  that can't be verified without a live UE5 editor run.
- **`run.ps1`** — runs the task queue in order, logs each run under `logs/`, stops on a fast-tier
  failure.

## Running it

```powershell
powershell -File tools\backup-agent\run.ps1
```

Or drive a single task by hand, e.g. to iterate on one without running the whole queue:

```powershell
$env:OLLAMA_API_BASE = "http://localhost:11434"
C:\Users\Jack\.backup-agent-venv\Scripts\aider.exe --message-file tools\backup-agent\task-01-export-character-rigs.md
```

Ollama must already be running (`ollama serve`, or the tray app) with `qwen3-coder:30b` pulled —
both were true as of this session. `deepseek-coder-v2:16b` was also pulled this session as a
lighter/faster alternative if `qwen3-coder:30b`'s VRAM footprint (~11.5 GB, most of this machine's
12 GB card) is too tight alongside anything else running — swap it in via `--model
ollama_chat/deepseek-coder-v2:16b` if needed.

## After it runs

`git status` / `git diff` in the repo root to see what it did. Nothing is committed. If it looks
right: commit it yourself, or hand it to Claude next session to review and commit (mention this
file so it knows to look here first, rather than re-deriving what's already been scoped).

If a task's log shows it got stuck, made a wrong call, or explicitly said it couldn't verify
something (see each task file's point about live UE5 verification) — that's expected, not a
failure of the setup. Read the log, decide whether to fix it by hand, re-run the task with a
follow-up instruction, or leave it for Claude.
