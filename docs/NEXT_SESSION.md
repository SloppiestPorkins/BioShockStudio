# BioShockStudio — next session

Copy the block below as the opening prompt for a new agent. Everything it needs is in the
repository; this file only tells it where to look and what not to re-derive.

---

## How to start in Cursor (do this, not a full re-survey)

**The efficient pattern is a narrow prompt + one Gate item.** Do not open with "look through this
and start working" — that burns a turn re-reading the whole handoff/roadmap before any code moves.

**Best opening for a new chat**

1. `@docs/NEXT_SESSION.md` and `@docs/ROADMAP.md` (or paste this file's body).
2. Name one concrete ask from Part 2, e.g. `Gate 4 item 4: DecoyHumanAbility.TargetIndicatorClassString`
   or `fix the ClassDefaults mid-stream gap on BerserkRageAbility`.
3. Optionally `@` the research note for that area (`docs/research/interaction.md`, `audio.md`, …).

**What the agent should do then**

- Check `docs/HANDOFF.md`'s Active work claim table, add a row, then work **only** that item.
- Baseline: `dotnet build` + `dotnet test --filter Tier=Fast`. Not the full suite.
- Read `ROADMAP.md` Part 2 only far enough to confirm the named item and its open sub-parts; do not
  re-summarise every gate.
- Keep one track per chat until it lands; ask for small logical commits when a slice is done.

**Context handoff** — if a long session is running (especially unattended / "carry on while I nap")
and context is getting tight, the agent should **stop mid-track cleanly**: update this section's
"Resume here" block below, update the HANDOFF claim row, leave the tree buildable, and tell the
user the paste-ready opening for a **new** chat. Cursor has no tool that opens a Composer tab
from the agent — handoff is write-the-prompt, not auto-spawn.

### Resume here (keep current; wipe when the named item lands)

```
@docs/NEXT_SESSION.md @docs/ROADMAP.md @docs/UE5_FULL_PORT_PLAN.md
SendTriggerMessage→DispatchMessage verified; AShockScript + MessageQueue also landed.
Next: PIE possess (human Play), or Script actor import from level JSON.
Branch feature/fbx-materials-gui.
```

**What wastes time here**

- Full-repo "have a look / orient yourself" with no Gate ask.
- Full `dotnet test` on session start (~20+ min) — use Fast + named sweep classes; see Test-run
  economy in `docs/ENGINEERING_RULES.md` §60.
- Two agents on the same files without updating the claim table.

Standing rule copy: `docs/ENGINEERING_RULES.md` §60 "Cursor session start".

---

## Read first, in this order

*Only when the user did not already name a Gate item* — otherwise skip straight to that item's
research note and the claim table, and use this list as a lookup rather than a full read-through.

1. `CLAUDE.md`, then `docs/ENGINEERING_RULES.md` — how to work here. Non-negotiable. §2 (user
   instructions are the task boundary), §14 (curiosity control), §55 (a worked example of getting
   scope wrong), §60 (standing user instructions — Cursor session start, test-run economy, roadmap
   discipline; UE5 and audio are **reopened**, UE5-as-a-runtime is the end goal, and a second agent
   works this repo concurrently).
2. **`docs/ROADMAP.md` — the current source of truth for project status and what's next.** Supersedes
   this file for anything about priorities: what's done (Part 1), what's left in gate order
   (Part 2), and a Part 0 on process (commit hygiene, the cross-agent claim table, why WIP stays
   narrow). If this file and `ROADMAP.md` disagree, trust `ROADMAP.md` and fix this file.
3. **`docs/UE5_FULL_PORT_PLAN.md`** if the work is UE5-facing — the strategy for porting the whole
   game, including why the game logic is deliberately *not* auto-transpiled, and the measured
   action-usage curve that orders the AI work (top 20 actions cover 73% of all scripted
   behaviour).
4. `docs/HANDOFF.md` — institutional memory: the **Active work claim table at the very top** (add a
   row before touching a file, check before touching one someone else claims), architecture (§3), and
   §4's landmines list (things that cost real time to find — read before touching coordinate systems,
   Havok decoding, BSP zones, or the material walk).
5. `docs/research/ANIMATION_COORDINATE_SYSTEM.md` — the basis policy, required before touching any
   transform. `C = diag(1,-1,1)`, applied at five decode boundaries and nowhere else.
6. `docs/research/reference-comparison.md` and the individual `docs/research/*.md` files for
   whatever area you're touching — **read the reference projects before deriving from bytes.** That
   policy has paid off repeatedly, most recently handing over a working, BioShock-aware
   UnrealScript decompiler almost for free (`docs/research/bytecode.md`) and a per-node BSP
   visibility mask lifted straight from a reference level editor
   (`docs/research/bsp.md` §5.2). The four reference projects live gitignored at the repo root:
   `Bioshock1REMSDK-WIP--main`, `UModel-master`, `Unreal-Library-master`, `hk2012_2_0_r1`.

## First action — establish the baseline

```bash
dotnet build
dotnet test --filter Tier=Fast     # ~40s; run this constantly
```

**That is the whole baseline. Do not run the full suite as a first action** — it costs ~19 minutes to
re-measure what the previous session already measured, which is the specific waste
`docs/ENGINEERING_RULES.md` §60 "Test-run economy" (a standing user instruction) exists to stop.
Instead read the **verification stamp** at the top of `docs/ROADMAP.md` "Test health": it names the
commit the suite was last green at, and `git diff --stat <stamp>..HEAD` is then the complete list of
what could have moved. Run the sweep classes covering *that*, by name, and nothing else:

```bash
dotnet test --filter "FullyQualifiedName~<Class>"
```

**Don't trust a number written here** — it goes stale within a session or two, which is exactly the
failure mode `docs/ROADMAP.md` Part 0.6 exists to stop. Run the commands above and record what you
actually get; `docs/ROADMAP.md` "Test health" has the most recently measured figure if you want a
sanity check before running. If anything fails, classify per `docs/ENGINEERING_RULES.md` §24 before
touching code — `DocumentedFiguresTests` asserts the headline numbers in `docs/QUALITY.md`; if it goes
red, the code may have gotten better or worse, or the *documentation* may be what's wrong. Never relax
the assertion to make it pass.

**Do not build or run `dotnet test` while another `dotnet test` is running** — testhost locks the
DLLs (MSB3027) and both runs fail. If you kick off a long background test run, wait for it (or work
in a completely separate project, like the reference-decompiler tooling, which doesn't share the
lock) before building the main solution again.

## State of the tree

Branch `feature/fbx-materials-gui`, remote `origin` exists
(`github.com/jackwickens6-lgtm/BioShockStudio`) but **do not push without being asked**. Working
tree clean as of this writing. **A second AI agent (ChatGPT) works this same repository
concurrently** — read `HANDOFF.md`'s Active work table before starting, and never `git add -A`;
stage files by name. Commit in small, logical, buildable groups as you go — the user has asked for
this and it overrides the default "don't commit" rule — but only commit when the user has actually
asked for the work, and only push when explicitly asked.

Keep `artifacts/app` current if you touch the App project:
`dotnet publish src/BioShockStudio.App/BioShockStudio.App.csproj -c Release -o artifacts/app`
(close the app first — a running instance locks the DLLs).

## The one thing to internalise

**A numeric check cannot see a wrong quantity that is still present.** Textures tiled 512 times and
every count agreed. Rooms were missing and the scene was self-consistent. Six faults shipped in one
session, every one passing the full suite, and a user found five by looking at the screen. Where a
value has a magnitude, **measure the magnitude**. Where output is visual, **render it and look**
(`BIOSHOCK_LEVELCAM_SNAPSHOT`, `BIOSHOCK_WORLD_SNAPSHOT`, `BIOSHOCK_LEVEL_SNAPSHOT`,
`BIOSHOCK_UI_SNAPSHOT` all write PNGs) or **verify it in the real UE5.7 editor**, not just from a
clean import log. Full recipe for the latter: `tools/ue5/README.md`.

**A close second, learned hard this cycle:** before assuming something needs decoding, check
whether it's already done somewhere the tracking doc doesn't reflect. Three separate "already
done, just undercounted or mislabeled" findings this cycle (a diagnostic sweep blind to its own
mesh-section decode, a lightmap search heuristic excluding valid smaller maps, two "pending" actor
categories that already had full tested data schemas) were each worth more than an hour of fresh
research, and cost only a few minutes to find by reading the actual code and tests first.

## What to do, in priority order

**Follow `docs/ROADMAP.md` Part 2** (the gate structure). Deliberately not duplicated here as a
bulleted summary any more — every previous version of that summary went stale within a session or two
and started disagreeing with the real source of truth, which is exactly what Part 0.6 of that document
identified as the project's biggest process risk. Read Part 2 directly; it is kept current there and
nowhere else.

## Do not start

- **Bulk extraction size (~140 GB).** Explicitly deferred.
- **§6.0c, the collapsing fire animations** (`docs/HANDOFF.md` §6.0c). Four candidate causes
  eliminated with evidence, and the recorded next lead (`evaluateSimple1/2/3`) is now *also* confirmed
  closed — those functions don't exist in this SDK build either, same as `sampleTranslation`. Do not
  re-open without either the missing compiled bodies or a genuinely new lead.
- **Rewriting `Core/Level` or the BSP readers.** Both measured clean.

## Traps accumulated across sessions

- **`unreal.log()`/`print()` output from a UE5 Python script is not reliably captured** when run
  via `-run=pythonscript` from this shell — don't rely on grepping for it to confirm success.
  Instead: check the log's own `Success - N error(s)` summary line, and have the script raise a
  `RuntimeError` on any real failure (absence of a traceback is real evidence; absence of a print
  line is not).
- **UELib's own `.csproj` targets `net10.0`**, unsupported by this repo's installed SDK — don't try
  to build it via its own project file. `tools/uelib-bridge/uelib-standalone.csproj` compiles its
  sources directly against `net8.0` instead; copy that pattern for any similar third-party
  reference tool.
- **A rig's mesh export name, or a weapon's `ShockGame.U` group name, doesn't always match a
  `UAPW_`-stripped guess.** `export-fbx --mesh <name>` and `export-firstperson --group=<name>`
  override the guess; both silently produce 0 vertices / "not found" rather than erroring loudly when
  the guess is wrong, so check vertex/animation counts in the export log.
- **PowerShell destroys non-ASCII in source files.** Use .NET directly and check `git diff` for
  encoding churn before committing.
- **`IsVisible="{Binding !SomeObject}"` does not negate a non-boolean in Avalonia** — it renders
  always. Use `{Binding X, Converter={x:Static ObjectConverters.IsNull}}`.
- **A heredoc to `python` hangs** — python is not installed at the shell's default PATH; it waits on
  stdin until timeout. Use `Edit`, or a real script file.
- **A snapshot of the wrong tab proves nothing.** Selecting a level in the view model does not
  change which tab is showing.
- **UE5.7 is at `G:\Games\UE_5.7\`, not under `Program Files\Epic Games`** — only the Launcher lives
  there. The throwaway test project is `C:\Users\Jack\Documents\BioShockUE5\`. Both are outside this
  repo and gitignored/untracked, so a fresh environment needs them located, not assumed missing.

## The standard that applies

Never promote a hypothesis to a fact. Label confidence always (`CONFIRMED_BYTES` /
`CONFIRMED_EXTERNAL` / `PLAUSIBLE` / `UNKNOWN`). A measurement that *can fail* is worth more than
one that merely passes — check what your test is actually measuring, because a test averaging over
the wrong population can report "no change" while a real fix landed underneath it, and a self-bit
check with zero exceptions across 1,000+ samples is worth more than one plausible-looking example.
Unknown is a valid answer.
