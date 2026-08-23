# Contingency: running the agent team without Claude Code

For when Claude Code usage is exhausted or unavailable and you want to keep using the four local
agents. **This works** — `.agent-control/agent.ps1` doesn't call out to Claude for anything; it
dispatches directly to Ollama (`http://127.0.0.1:11434`). The only thing missing without Claude Code
is the Lead. You become the Lead. This file is that handover.

## What you lose without a Lead

- **The hard reverse-engineering reasoning.** This session, TASK-000/002/009's actual root-cause work
  (reading `git diff`s across a dozen commits, cross-referencing a dozen test files' independent
  assertions to prove an exact number) was done by the Lead directly, not delegated — the local model
  wasn't asked to do it because it isn't reliable at that depth. Expect to do this part yourself, or
  pick only the tasks in `.agent/TASK_QUEUE.md` marked `Agent: Research`/`Tester` where the work is
  genuinely mechanical (grep, read, run, report — not multi-step inference).
- **Diff scrutiny.** Every real bug caught this session was caught by *reading the diff*, not by
  trusting the coder's own report. The local model has, in one session: dropped string-literal quotes
  (a hard compile error, `row.ClassName == Marker` instead of `== "Marker"`), added a stray file
  encoding, and once mis-scoped a change until given exact before/after text. None of that showed up
  in its own summary — only in the actual diff.
- **Judgment on ambiguous findings.** `SoundActorSchemaTests`' scope this session was left explicitly
  unfixed rather than guessed at, because intent wasn't clear from the code alone. Don't let a
  READY-looking task talk you into resolving genuine ambiguity by coin flip.

## What still works exactly the same

Every `agent.ps1` command, the GPU lock, the worktree dirty-check, the patch-apply/revert for
tester validation — all of it is pure PowerShell + Ollama, zero Claude dependency. Full command
reference: `CLAUDE_ORCHESTRATION.md` in this directory.

## The manual runbook

This mirrors exactly what the Lead does — just performed by you instead of read/decided by an AI.

1. **Pick a task.** Open `.agent/TASK_QUEUE.md`, take the next `READY` item in priority order. Don't
   invent one — the queue exists so nobody works from vibes.
2. **Research first if the task's own `Agent:` line says so.**
   ```
   powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 research "<the task's Goal, verbatim>" -Files <files it names> -Grep <a pattern if useful>
   ```
3. **Read the result yourself — do not skim.**
   ```
   powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 result <id>
   ```
   If the report classifies or counts things from a grep (e.g. "N files use pattern X"), spot-check
   2–3 of its claims by opening the actual file. This session's research agent misclassified a
   single-package path lookup as a whole-game census because it matched a helper-method name without
   reading how it was called — the raw grep hits were correct, the *interpretation* wasn't.
4. **Decide whether to code.** If yes, write the coder's instructions as literally as you can — exact
   before/after text blocks, not a paraphrased description. This session: a loosely-described task
   produced a diff with a missing string quote (compile error); the same fix redispatched with exact
   before/after text compiled clean on the first attempt. The model needs the answer spelled out, not
   just the goal.
   ```
   powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 code "<task>" -Files <files> -Context "<exact before/after text>"
   ```
5. **Read the diff. Every line. Don't skip this step.**
   ```
   powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 diff <coder-id>
   ```
   Specifically look for: missing quotes around string literals, any file outside what you named, a
   comment or doc-string that describes the wrong thing (copy-paste residue), an encoding change
   (`file <path>` should say plain ASCII/UTF-8, not "with BOM").
6. **Test independently.**
   ```
   powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 test "<what to verify>" -Parent <coder-id> -TestFilter "FullyQualifiedName~<Class>"
   ```
   Trust the **"Controller-verified test exit code"** line and the raw `Passed!`/`Failed!` line in the
   result — those come from a real `dotnet test` the controller ran, not the model's opinion. The
   model's prose has claimed a run "passed" once when the ground-truth section showed the build had
   actually failed first — always check the ground-truth block, not the summary above it.
7. **Review.**
   ```
   powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 review "<what changed and why>" -Parent <coder-id>
   ```
   Treat `APPROVE` as informational, not authoritative — this session's reviewer flagged one real
   concern and one non-issue (a misunderstanding of C# enum-cast semantics) in the same report. You
   still have to be the one who can tell which is which.
8. **Integrate by hand.** The system deliberately never merges a worktree branch into main. Open the
   changed file(s) in the coder worktree, and either re-apply the exact same edit in the main worktree
   or copy the new file content across. Then, in the **main** worktree:
   ```
   dotnet build
   dotnet test --filter "FullyQualifiedName~<the classes you touched>"
   ```
   Only proceed once both are clean.
9. **Commit by hand**, staging specific files (never `git add -A`):
   ```
   git add <exact files>
   git commit -m "..."
   ```
10. **Reset the coder worktree** so it's ready for the next dispatch:
    ```
    git -C C:\Users\Jack\Documents\BioshockHavok-agents\coder checkout -- <the files you integrated>
    ```
11. **Update `.agent/TASK_QUEUE.md` yourself** — mark the task `DONE` with a short evidence paragraph
    (what was found, what changed, how it was verified). This file is the institutional memory the
    *next* session — local or Claude — reads first. An undocumented fix is close to an unfixed one.

## Hard rules — same ones the Lead follows, now yours

- Never integrate a diff you haven't personally read.
- Never trust "N passed" in the model's prose — check the controller's ground-truth block.
- Never let the model touch a file you didn't name (the diff/status commands will show you if it
  tried — the path-safety check in `Controller.ps1` already rejects anything escaping the worktree,
  but a file *inside* the worktree it wasn't asked to touch can still slip through).
- Never skip the `.agent/KNOWN_ASSUMPTIONS.md` entry for whatever area you're touching, before you
  touch it.
- Never dispatch `code` for a task the queue marks as needing `Research` first, without actually doing
  that research pass — the local model cannot be trusted to make that judgment call for itself, and
  neither, honestly, should you skip it just because Claude isn't available to nag you about it.
- Never auto-chain research → code → test → review → integrate without stopping to read each stage.
  `agent.ps1 pipeline` deliberately only dispatches research and then stops — that design choice
  applies double when you're doing the deciding yourself.

## Known model failure modes, concretely (all observed this session)

| What happened | How it was caught |
|---|---|
| Dropped string-literal quotes (`== Marker` not `== "Marker"`) — compile error | Reading the diff before dispatch to tester |
| Added a stray UTF-8 BOM to every file it wrote | `file <path>` after the fact; now fixed at the controller level, but re-check if you ever modify the write path |
| Copy-pasted the wrong XML doc comment onto a new type | Reading the diff |
| Reported "5/5 passed" in prose while ground truth showed a build failure first | Checking the `Controller-run build/test` block, not the prose above it |
| Classified a single-package `Path.Combine` lookup as a whole-game census, from a bare grep match | Opening the actual file and reading the surrounding code |
| A `git apply` failed on one file of a four-file patch despite an exact base-blob match | Reading the actual `git apply --check -v` error, not assuming "patch failed" meant the change was wrong |

None of these are reasons to distrust the *system* — every one was caught before it reached the main
worktree, which is the whole point of the pipeline. They're reasons to never skip a step.

## Quick command reference

Full detail in `CLAUDE_ORCHESTRATION.md`. The essentials:

```
agent.ps1 research "<task>" [-Files a.cs,b.cs] [-Grep pattern] [-Glob *.cs]
agent.ps1 code     "<task>" [-Files ...] [-Parent <id>] [-Context "..."]
agent.ps1 test     "<task>" -Parent <coder-id> [-TestFilter Tier=Fast]
agent.ps1 review   "<task>" -Parent <coder-id>
agent.ps1 status                       # tasks, GPU lock, worktree cleanliness
agent.ps1 result   <id>                # the concise report
agent.ps1 log      <id>                # full prompt + raw response, when a result looks wrong
agent.ps1 diff     <id>                # the coder's actual change — read this every time
```
