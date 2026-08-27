# BioShockStudio — next session

Copy the block below as the opening prompt for a new agent. Everything it needs is in the
repository; this file only tells it where to look and what not to re-derive.

---

## How to start in Cursor (do this, not a full re-survey)

**The efficient pattern is a narrow prompt + one Gate item.** Do not open with "look through this
and start working" — that burns a turn re-reading the whole handoff/roadmap before any code moves.

**Best opening for a new chat**

1. `@docs/NEXT_SESSION.md` and `@docs/ROADMAP.md` (or paste this file's body).
2. Name one concrete ask from Part 2 / the resume block, e.g. nested If/Loop script import, or
   `Gate 4 item 4: DecoyHumanAbility.TargetIndicatorClassString`.
3. Optionally `@` the research note for that area (`docs/research/interaction.md`, `audio.md`, …).

**What the agent should do then**

- Check `docs/HANDOFF.md`'s Active work claim table, add a row, then work **only** that item.
- Baseline: `dotnet build` + `dotnet test --filter Tier=Fast`. Not the full suite.
- Read `ROADMAP.md` Part 2 only far enough to confirm the named item; do not re-summarise every gate.
- Keep one track per chat until it lands; commit in small logical groups when the user asks (or when
  standing "carry on / commit as you go" applies). Push only when explicitly asked.
- **Work on `main` only.** There is no feature branch for day-to-day work.

**Context handoff** — if a long session is running and context is getting tight, **stop mid-track
cleanly**: update this section's "Resume here" block, update the HANDOFF claim row, leave the tree
buildable, and give the user the paste-ready opening for a **new** chat.

### Resume here (keep current; wipe when the named item lands)

```
@docs/NEXT_SESSION.md @docs/ROADMAP.md @docs/UE5_FULL_PORT_PLAN.md
Phase 4 script track on main: runner + MessageQueue + AShockScript + JSON import with
schema defaults, instance-prop overlay, and nested If/Loop childArrays expansion.
Next: human PIE possess check, or ActionPropertyTest / remaining ActionBool for testsOr.
Branch: main only.
```

**What wastes time here**

- Full-repo "have a look / orient yourself" with no Gate ask.
- Full `dotnet test` on session start (~20+ min) — use Fast + named sweep classes; see Test-run
  economy in `docs/ENGINEERING_RULES.md` §60.
- Two agents on the same files without updating the claim table.
- Opening or creating feature branches for routine Phase 4 work.

Standing rule copy: `docs/ENGINEERING_RULES.md` §60 "Cursor session start".

---

## Read first, in this order

*Only when the user did not already name a Gate item* — otherwise skip straight to that item's
research note and the claim table, and use this list as a lookup rather than a full read-through.

1. `CLAUDE.md`, then `docs/ENGINEERING_RULES.md` — how to work here. Non-negotiable.
2. **`docs/ROADMAP.md`** — status and what's next (Part 1 done / Part 2 gates). If this file and
   `ROADMAP.md` disagree, trust `ROADMAP.md` and fix this file.
3. **`docs/UE5_FULL_PORT_PLAN.md`** if the work is UE5-facing — strategy + Phase 4 record.
4. `docs/HANDOFF.md` — Active work claim table at the top, then architecture / landmines as needed.
5. Area research notes under `docs/research/` for the files you will touch.

## State of the tree

- **Branch:** `main` only. Remote: `https://github.com/SloppiestPorkins/BioShockStudio.git`.
- **Claim table:** use `docs/HANDOFF.md` Active work before touching shared files.
- Never `git add -A`; stage by name. Do not commit `tmp/`, game-derived exports, or secrets.
- UE5.7: `G:\Games\UE_5.7\`. Throwaway project: `C:\Users\Jack\Documents\BioShockUE5\` (outside
  repo). Plugin SoT: `tools/ue5/BioShockRuntime/`. Headless verify pattern: UAT BuildPlugin → copy
  Binaries → `UnrealEditor-Cmd -run=pythonscript -script="…"`.
- Script import: `export-script-actions` → `1-Medical.script-actions.json` sidecar (not committed;
  regenerate locally), then `run_import_scripts.py`.

Keep `artifacts/app` current if you touch the App project:
`dotnet publish src/BioShockStudio.App/BioShockStudio.App.csproj -c Release -o artifacts/app`
(close the app first — a running instance locks the DLLs).

## The one thing to internalise

**A numeric check cannot see a wrong quantity that is still present.** Where a value has a
magnitude, **measure the magnitude**. Where output is visual, **render it** or **verify in the
real UE5.7 editor** (`tools/ue5/README.md`), not just from a clean import log.

## What to do, in priority order

**Follow `docs/ROADMAP.md` Part 2** (and the resume block above for the live UE5 Phase 4 head).
Deliberately not duplicated here as a long bullet list — that always goes stale.

## Do not start

- **Bulk extraction size (~140 GB).** Explicitly deferred.
- **§6.0c collapsing fire animations** (`docs/HANDOFF.md` §6.0c) without a new lead.
- **Rewriting `Core/Level` or the BSP readers.** Both measured clean.

## Traps accumulated across sessions

- **`unreal.log()`/`print()` from UE5 Python is not reliable evidence** under `-run=pythonscript`.
  Use `Success - N error(s)` plus `RuntimeError` on failure.
- **UELib's own `.csproj` targets `net10.0`** — use `tools/uelib-bridge/uelib-standalone.csproj`.
- **PowerShell can destroy non-ASCII** in source files — check `git diff` for encoding churn.
- **A heredoc to `python` can hang** if python is not on PATH — use a real script file.
- **UE5.7 is at `G:\Games\UE_5.7\`**, throwaway project under Documents — both outside this repo.

## The standard that applies

Never promote a hypothesis to a fact. Label confidence always (`CONFIRMED_BYTES` /
`CONFIRMED_EXTERNAL` / `PLAUSIBLE` / `UNKNOWN`). Unknown is a valid answer.
