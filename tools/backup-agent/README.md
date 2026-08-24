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
  failure. Skips a task once it has a `task-NN-*.done` marker next to it (see "After it runs"
  below), and refuses to start a second overlapping run via `.run.lock` (auto-considered stale
  after 2 hours, in case a previous run was killed rather than exiting cleanly).
- **A `SessionEnd` hook** in `C:\Users\Jack\Documents\AI Test\.claude\settings.local.json` (that
  project's own local settings, not this repo's — see below for why) launches `run.ps1` in a
  detached background PowerShell process when a Claude Code session in that project ends, so the
  backup agent picks up automatically rather than needing to be started by hand every time.

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

**Once a task's work is reviewed and committed, mark it done** so a later automatic run doesn't
redo it: `New-Item -ItemType File tools\backup-agent\task-01-export-character-rigs.done` (matching
the task's own base filename). `run.ps1` skips any task with a `.done` marker. These markers are
tracked in git deliberately — they're a fact about the project's progress, not local machine state.

If a task's log shows it got stuck, made a wrong call, or explicitly said it couldn't verify
something (see each task file's point about live UE5 verification) — that's expected, not a
failure of the setup. Read the log, decide whether to fix it by hand, re-run the task with a
follow-up instruction, or leave it for Claude.

## Why the SessionEnd hook lives in a different project's settings

This repo (BioshockHavok) isn't the Claude Code project root this work has actually been done
through this session — `C:\Users\Jack\Documents\AI Test` is, with BioshockHavok worked in via
absolute paths as an additional directory. Claude Code project-scoped settings
(`.claude/settings.local.json`) are read relative to the actual project root, so the hook has to
live in *that* project's settings to fire when *this kind of session* ends. It was **not** placed
in the global `~/.claude/settings.json`, since that would fire this repo-specific automation for
every unrelated Claude Code session on the machine, not just ones doing BioShockHavok work.

`SessionEnd` was used rather than `Stop` — `Stop` fires after every single turn (including
`/clear`, `/resume`, `/compact`), which would mean starting a multi-minute aider+test run after
nearly every message. `SessionEnd` only fires when the session itself concludes.
