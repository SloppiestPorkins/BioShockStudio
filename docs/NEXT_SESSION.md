# BioShockStudio — next session

Copy the block below as the opening prompt for a new agent. Everything it needs is in the
repository; this file only tells it where to look and what not to re-derive.

---

## Read first, in this order

1. `CLAUDE.md`, then `docs/ENGINEERING_RULES.md` — how to work here. Non-negotiable. §2 (user
   instructions are the task boundary), §14 (curiosity control), §55 (a worked example of getting
   scope wrong), §60 (standing user instructions — UE5 and audio are **reopened**, UE5-as-a-runtime
   is the project's actual end goal, and a second agent works this repo concurrently).
2. **`docs/ROADMAP.md` — the current source of truth for project status and what's next.** Supersedes
   this file for anything about priorities: what's done (Part 1), what's left in gate order
   (Part 2), and a Part 0 on process (commit hygiene, the cross-agent claim table, why WIP stays
   narrow). If this file and `ROADMAP.md` disagree, trust `ROADMAP.md` and fix this file.
3. `docs/HANDOFF.md` — institutional memory: the **Active work claim table at the very top** (add a
   row before touching a file, check before touching one someone else claims), the current-state
   table, architecture, and §4's landmines list (things that cost real time to find — read before
   touching coordinate systems, Havok decoding, BSP zones, or the material walk).
4. `docs/research/ANIMATION_COORDINATE_SYSTEM.md` — the basis policy, required before touching any
   transform. `C = diag(1,-1,1)`, applied at five decode boundaries and nowhere else.
5. `docs/research/reference-comparison.md` and the individual `docs/research/*.md` files for
   whatever area you're touching — **read the reference projects before deriving from bytes.** That
   policy has paid off repeatedly, most recently handing over a working, BioShock-aware
   UnrealScript decompiler almost for free (`docs/research/bytecode.md`) and a per-node BSP
   visibility mask lifted straight from a reference level editor
   (`docs/research/bsp.md` §5.2). The four reference projects live gitignored at the repo root:
   `Bioshock1REMSDK-WIP--main`, `UModel-master`, `Unreal-Library-master`, `hk2012_2_0_r1`.

## First action — establish the baseline

```bash
dotnet build
dotnet test --filter Tier=Fast     # ~30s; run this constantly
dotnet test                        # ~25-28 min; the figure to report
```

Expect **439 passed, 0 failed, 0 skipped** (measured 22 Aug 2026, HEAD `4e4caa4`). Record what you
actually get. If anything fails, classify per §24 before touching code — `DocumentedFiguresTests`
asserts the headline numbers in `docs/QUALITY.md`; if it goes red, the code may have gotten better
or worse, or the *documentation* may be what's wrong. Never relax the assertion to make it pass.

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

**Follow `docs/ROADMAP.md` Part 2** (the gate structure) rather than a list duplicated here, since
that document is kept current and this one isn't reliably. As of 22 Aug 2026, in short:

- **Gate 0** (trustworthy level viewer): window-placement fidelity, material fidelity, and the
  viewer visibility matrix are open. Lightmap atlas-pool binding is done (20/21 maps); per-pixel
  binding and a lit/unlit comparison render remain before it defaults on.
- **Gate 1** (asset containers): static-mesh collision is deliberately blocked pending a UE5-target
  decision. Skeletal section-table reachability is at 35% (socket-table-dependent locator); a more
  robust one would close the rest. Texture UE5-metadata export and material panners/rotators/cubemap
  inputs are genuinely unstarted.
- **Gate 2** (animation/rigs/physics): four character skeleton families now verified live in
  UE5.7 (pistol, TommyGun, splicer, both Big Daddy variants, Little Sister) — extend to other
  weapons, doors, props using the same recipe (`export-fbx` [+ `--mesh <name>` if the rig has more
  than one mesh] → `tools/ue5/import_bioshock.py` or the minimal mesh-only pattern in recent commit
  messages → verify the resulting asset directly in a headless editor run). Havok physics/ragdoll
  mapping is unstarted; §6.0c's bone-rigidity collapses are genuinely blocked (need
  `sampleTranslation`, absent from this SDK build).
- **Gate 3** (levels/UE2 actors): BSP zone connectivity and per-node visibility both decode
  (`CONFIRMED_BYTES`). Light and script-action placed-actor data both already have full, tested
  schemas — what's open there is turning that into placed UE5 actors, not decoding more. Audio
  actors, region/volume actors and effect actors are the next genuinely-open categories in
  shipped-count order.
- **Gate 4/5**: mostly untouched this cycle; Gate 5 (a real UE5 importer workflow) is the actual
  end goal and depends on the earlier gates.
- **Track B** (UnrealScript bytecode): BioShock's own game logic is readable right now via
  `tools/uelib-bridge/` — 1,445 classes across 11 of 12 script packages, 0 failures. Use it as
  documentation when a specific class's behaviour is in question elsewhere in the project, rather
  than re-researching from bytes. `Engine.U` crashes on load (a real, lower-priority gap); an
  independent from-scratch bytecode decoder is scoped but not started (`docs/research/bytecode.md`
  §7) if that's ever wanted separately from reading the decompiled output.

## Do not start

- **Bulk extraction size (~140 GB).** Explicitly deferred.
- **§6.0c, the collapsing fire animations.** Four causes eliminated with evidence; needs
  `sampleTranslation`, absent from this SDK build.
- **Rewriting `Core/Level` or the BSP readers.** Both measured clean.

## Traps that bit this session (22 Aug 2026)

- **`unreal.log()`/`print()` output from a UE5 Python script is not reliably captured** when run
  via `-run=pythonscript` from this shell — don't rely on grepping for it to confirm success.
  Instead: check the log's own `Success - N error(s)` summary line, and have the script raise a
  `RuntimeError` on any real failure (absence of a traceback is real evidence; absence of a print
  line is not).
- **UELib's own `.csproj` targets `net10.0`**, unsupported by this repo's installed SDK — don't try
  to build it via its own project file. `tools/uelib-bridge/uelib-standalone.csproj` compiles its
  sources directly against `net8.0` instead; copy that pattern for any similar third-party
  reference tool.
- **`export-fbx`'s mesh-name guess (strip `UAPW_` off the wrapper name) only holds for a
  single-mesh rig.** A multi-mesh group sharing one animation rig (several character variants, or a
  weapon/prop whose mesh is named differently from its wrapper) needs the `--mesh <name>` override
  added this cycle, or it silently exports 0 vertices with no error.
- **PowerShell destroys non-ASCII in source files.** Use .NET directly and check `git diff` for
  encoding churn before committing.
- **`IsVisible="{Binding !SomeObject}"` does not negate a non-boolean in Avalonia** — it renders
  always. Use `{Binding X, Converter={x:Static ObjectConverters.IsNull}}`.
- **A heredoc to `python` hangs** — python is not installed at the shell's default PATH; it waits on
  stdin until timeout. Use `Edit`, or a real script file.
- **A snapshot of the wrong tab proves nothing.** Selecting a level in the view model does not
  change which tab is showing.

## The standard that applies

Never promote a hypothesis to a fact. Label confidence always (`CONFIRMED_BYTES` /
`CONFIRMED_EXTERNAL` / `PLAUSIBLE` / `UNKNOWN`). A measurement that *can fail* is worth more than
one that merely passes — check what your test is actually measuring, because a test averaging over
the wrong population can report "no change" while a real fix landed underneath it, and a self-bit
check with zero exceptions across 1,000+ samples is worth more than one plausible-looking example.
Unknown is a valid answer.
