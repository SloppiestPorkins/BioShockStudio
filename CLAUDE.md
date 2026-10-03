# CLAUDE.md

**Read `docs/ENGINEERING_RULES.md` in full before changing anything.** It is the canonical ruleset;
this file is the entry point, and it is deliberately short so the two cannot drift apart.

**`docs/EFFICIENCY_RULES.md` is the peer document for iteration speed and verification economy** —
how to not repeat an expensive, unreliable, or unmeasured verification step. `ENGINEERING_RULES.md`
governs rigor; that one governs not wasting a day proving it slowly.

**Starting a Cursor chat:** do not re-survey the whole repo. Name one concrete item from
`docs/ROADMAP.md` in the first message, Fast tier only, claim table before touching shared files.
Full rule: `ENGINEERING_RULES.md` §60 "Cursor session start" (the pattern used to live in
`docs/archive/NEXT_SESSION.md` §"How to start in Cursor" — archived 28 Sept 2026, see
`docs/STATUS.md`).

**One integrator, several workers.** `ENGINEERING_RULES.md` §61 (rewritten 30 Sept 2026): Claude Code
plans, reviews and merges; `cursor-agent` / `codex` / the `tools/fleet/` local models do scoped tasks
in isolated worktrees; nothing merges until the integrator has re-verified it. Only one Unreal
process at a time against the UE project, and the UE project (`C:/Users/Jack/Documents/BioShockUE5`)
has its own local git repo — commit there after any map/asset change.

## The rules that get broken most often


Full text in `docs/ENGINEERING_RULES.md`; these are the ones worth having in front of you.

- **Make the smallest correct, tested change.** Not the most code, not the most investigation.
- **User scope beats agent curiosity.** "Write it up and move on" means stop, document, and move on —
  not keep pulling the thread because a new clue appeared. §55 has a worked example of getting this
  exactly wrong.
- **Work a roadmap in order — no jumping around.** Take the next undone item in `docs/ROADMAP.md`'s
  priority order and finish it *fully* before starting another. §60 "Roadmap discipline".
- **Capture discoveries; do not chase them.** `DISCOVER → VERIFY → RECORD → DEFER → CONTINUE`.
- **Never guess when the bytes can be inspected**, and never promote a hypothesis to a fact. Label
  confidence, always.
- **Never trust a single sample.** A structure that works in one package may be package-local — this
  has already happened.
- **Every reverse-engineered structure gets a regression test against real game bytes.** There are no
  synthetic fixtures.
- **Render it.** Numeric validation has passed on visibly wrong output more than once here.
- **Unknown is a valid answer.** A truthful partial result beats a plausible wrong one.
- **Never claim success without evidence.** "Resolves correctly, sample storage not located" is a
  better sentence than "audio works".

## Baseline

The suite is split into two tiers, because a ten-minute suite changes how carefully changes get
verified:

```bash
dotnet build
dotnet test --filter Tier=Fast                       # ~40s — run this constantly, while working
dotnet test --filter "FullyQualifiedName~<Class>"    # minutes — the sweep classes your diff touches
dotnet test --filter Tier=Sweep                      # ~19min — only when the diff reaches shared code
dotnet test                                          # both; only when reporting a whole-suite total
```

**Do not re-run the full suite to re-confirm a figure another session just measured.** Standing user
instruction — `docs/ENGINEERING_RULES.md` §60 "Test-run economy". Read the verification stamp
(the last-known-green commit for the suite) before running anything — it last lived in the old
`docs/ROADMAP.md` "Test health" section, now `docs/archive/ROADMAP.md` "Test health" (28 Sept 2026,
may be stale — check `docs/QUALITY.md` and a fresh `dotnet test --filter Tier=Fast` if in doubt).
`git diff --stat <stamp>..HEAD` tells you the only thing that needs re-running. An unrun tier is
reported as unrun, never as passing.

**The split is by how much real data a test reads, never by faking any.** There are no synthetic
fixtures and this does not introduce one: a fast test still reads real shipped bytes, just from one
package instead of all 33. Every test class declares its tier and `TierCoverageTests` fails if one
does not, so nothing can fall out of both tiers and stop running.

Tests read the installed game. Close the app before `dotnet publish` — a running instance locks the
DLLs. Commit small and often, by filename (never `git add -A`) — see `docs/EFFICIENCY_RULES.md` and
`docs/ENGINEERING_RULES.md` §60's "Do not commit unless asked" entry, superseded 4 Sept 2026.

**Tools for the repetitive steps (3 Oct 2026) — use them instead of hand-typed commands:**
`tools/ue5/ue_run.py` runs any UE-Python script or `--suite` headless (one Unreal process at a
time via `tools/ue5/ue_guard.py`; its verdict, not UE's exit code, decides pass/fail; a `-nullrhi`
pass is render-blind). `tools/ue5/capture_set.ps1 -Set medical` renders the validated viewpoints in
`tools/ue5/viewpoints/` and diffs them against baselines kept in the UE repo — a visual bug is done
only when a capture from the reported spot shows it fixed. `tools/manifest_query.py` queries level
manifests. `tools/git/ship.py` commits by filename (both repos), runs `tools/verify_changed.py`
for C# changes, and pushes. `tools/ue5/check_repairs_registered.py` lists repairs a rebuild would
not re-run. Matching Claude Code skills and the repo-guard hook live in `tools/claude/`.
