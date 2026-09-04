# Efficiency rules

**`docs/ENGINEERING_RULES.md` governs rigor: never guess, label confidence, test against real
bytes.** This document governs a different axis — **iteration speed and verification economy** —
and exists because a change can follow every rigor rule in that file and still cost ten times what
it should, or ship a regression, by looping on an expensive, unreliable, or unmeasured verification
step. Nothing here weakens a rigor rule. Where the two could be read as conflicting (§9 below vs.
"no synthetic fixtures"), the rigor rule wins and the scope is narrowed until they don't conflict.

Written 4 Sept 2026, after a single BSP-UV fix (the compiled-world texture-origin saga,
`44e5e7a`..`83e1804`) took most of a day and something like a dozen 10-20-minute UE5
export/reimport/capture round trips — several of them spent re-discovering the same class of
mistake. Every rule below names the concrete cost it would have cut. Add to this file the same way;
a rule with no incident behind it is a guess.

---

## 1. Cross-check a transform against one known landmark before trusting it anywhere else

**Cost this session: three separate coordinate-system bugs, each found only after a UE5 capture
came back blank or wrong**, because the axis convention between the studio's export basis, an
OBJ export's Y-up convention, and UE5's own world space was assumed rather than checked. The fix,
once applied, was one line: the manifest's `PlayerStart` location and the game's own logged spawn
position matched exactly, which is what confirmed "manifest coordinates == UE world coordinates,
no conversion" — a fact that then made every other placement calculation trustworthy.

**Before computing a derived position, transform, or coordinate mapping that a slow verification
step will exercise, check it against one thing you already independently know the right answer
for.** A player-spawn position, a landmark actor, a bounding-box corner — anything with a value you
can read from two sources and compare. Do this *before* the first expensive attempt, not after the
third failed one.

## 2. Grep for a working call before guessing an unfamiliar API

**Cost this session: at least five UE5.7 Python calls that turned out not to exist or not to work
as guessed** (`unreal.MaterialEditingLibrary.get_material_expressions`, `HitResult.blocking_hit` as
a readable property, `unreal.SystemLibrary.break_hit_result`, `get_editor_property("bounds")` on a
component, `get_editor_property("component")` on a `HitResult`) — each one discovered only after a
~9-minute level load, because the script that used it ran inside a full headless commandlet rather
than something cheap.

**Before writing an unfamiliar `unreal.*` (or any other large, sparsely-documented API's) call into
a script that will run inside an expensive harness, grep this repo's own `tools/ue5/*.py` for an
existing working usage of it first.** Hundreds of `run_*.py` scripts already exercise this API
successfully; a method already called somewhere is proven, a method you are about to call for the
first time is not. If nothing in the repo uses it, that itself is a signal to verify cheaply (a
tiny standalone script, or ask whether a different, already-proven call gets the same result)
before it goes into the expensive path.

## 3. Reproduce the bug in a synthetic test before spending a production round trip on it

**Cost this session: two real bugs in the same 30-line function (`RescaleFace`'s centre-scaling,
then its index-buffer compounding) that a 15-20-minute production re-export/re-import cycle showed
only as "still wrong" — no localisation, just aggregate statistics.** Both were found in under a
second once a synthetic 4-vertex quad with hand-picked UVs was fed through the function directly.

**When a fix's correctness is about what the *code* does with a given input — not about what the
game's bytes say — write the smallest input that exercises it and assert the expected output,
before spending an expensive round trip confirming it against real data.** This does not conflict
with "no synthetic fixtures" (`ENGINEERING_RULES.md` §22, `README.md`): that rule stops a decoder
from being validated against invented bytes standing in for a format nobody has read. A synthetic
quad tests arithmetic (does this rescale preserve `frac(uv)`?), not a file format — it has nothing
to say about what BioShock's bytes contain, and it is not a substitute for the real-game-data test
that must still exist for the reverse-engineered part. Use both: the synthetic test for the
transform's own correctness, the real-data test for whether it applies to the actual game.

## 4. Measure the real distribution before picking a threshold

**Cost this session: a clamp threshold tuned 16 → 5 → 12 against production data, and the middle
value was a real regression** — it silently squashed every legitimately-tiled floor in the level,
found only because the user complained ("you had the floor tiles nearly right... but ya fucked
it"). The number that actually held (12) came from measuring the real per-material tiling
distribution first (a diagnostic test dumping texels-per-unit per material) and picking a value
with headroom over it — the same measurement that should have been the *first* step, not the
fourth.

**Before choosing a clamp, cap, or other magic-number threshold that real data will be measured
against, measure that data's own distribution first and derive the number from it.** A round
number chosen by feel, then corrected against user-visible regressions one at a time, costs a full
verification round trip *per wrong guess* and ships each wrong guess in between.

## 5. Two "still broken" reports mean fix the verification, not the fix

**Cost this session: two rounds of "still borked" on the same claimed fix before the actual problem
— that verification itself was unreliable (blank-frame captures, a camera pointed at the wrong part
of the level) — was addressed.** Each round produced another plausible-sounding variant of the same
repair, applied and reported with the same confidence as the first, without ever actually having
seen the thing render correctly.

**A second consecutive "still broken" on a change already reported fixed is a stop condition on
trying a third variant.** Stop, and check whether the verification method itself can show the
problem at all — a fix confirmed only by statistics about the data (UV percentiles, a passing
test) is not confirmed for a claim about how something *looks*. `ENGINEERING_RULES.md`'s "Render
it" already says a reader is not finished until something has been drawn from it and looked at;
this is the same rule applied to *re*-verification after a claimed fix, where the temptation to
trust the same untrustworthy method a second time is stronger, not weaker.

## 6. Prefer the cheapest reliable verification actually available — often, the user's own eyes

**Cost this session: an entire afternoon of headless UE5 capture tooling** (camera placement,
coordinate transforms, API guesses — see §§1-2) attempting to automate a screenshot, when the user
had the editor open the whole time and could confirm or refute a fix by looking, in seconds, for
free.

**When a human with eyes on the actual result is available and willing, that is usually the
cheapest reliable check — use it before building automation to replace it**, especially for a
"does this look right" question rather than a "does this number match" question. Build the
automated capture path when it will be run many times or when no one is available to look; don't
default to it because it feels more rigorous. This project's own CPU-rasterizer viewport
(`docs/GUI.md`) is the counter-example done right: it exists because a *headless test* needed to
assert on pixels, not because looking was ever in doubt as the fastest first check.

## 7. Delegate what's mechanical and well-scoped; keep what needs judgement

**Evidence this session, both directions.** Two delegated tasks (`g1-bsp-texture-origin`,
`g2-bsp-uv-phase`) landed clean, tested, and correct on the first try, each in 12-13 minutes,
because the brief named the exact existing test to model the resolution chain on
(`SurfaceBrushPolyTests`), gave concrete numeric acceptance criteria (seam `Δfrac` near zero, a
specific percentile ceiling), and pointed at already-`CONFIRMED_BYTES` building blocks rather than
asking the worker to rediscover them. An earlier, vaguer task (`f1-bsm-version-141`) failed — the
brief assumed a table layout without verifying it first, which is exactly the guess `verify, don't
assume` exists to prevent, at the brief-writing stage rather than the coding stage.

**A delegated task's success rate is dominated by brief specificity, not by the worker's raw
capability.** Brief it the way `tools/agents/README.md` already asks: exact files, the shape of the
result, one or two concrete values to check, what not to touch — and additionally, whenever
possible, an existing piece of code or test in this repo to use as the template. Reserve delegation
for mechanical or well-evidenced work; keep judgement calls (which fix to pursue, whether a finding
changes the plan) for direct work.

## 8. Check for a live dependency before deleting or restructuring a file that looks dead

**Cost avoided, not incurred, this session — because this check was made.** `docs/NEXT_SESSION.md`
looked exactly like a stale, safe-to-fold-away snapshot doc, and two independent full read-throughs
both recommended deleting it. A repo-wide grep first found `.cursor/hooks/continue-phase4.py`
reading its "Resume here" block as a live auto-continue prompt on every Cursor session stop — the
file survived, rewritten in place instead of deleted, and the hook still works.

**Before deleting, merging, or substantially restructuring a file — doc, script, or config — grep
the whole repository for references to it, not just the docs.** Include scripts, hooks, CI config
and task briefs, not only other markdown files. A reference search takes seconds; discovering the
dependency by breaking it does not.

## 9. Commit as you go, small and often

Superseded the opposite standing rule in `ENGINEERING_RULES.md` §60 4 Sept 2026 — see that entry
for why. Small, frequent, filename-staged commits (never `git add -A`) are what let this session's
BSP work be bisected, reviewed and partially reverted (the cap-5 regression) without losing the
surrounding fixes. Ask before a commit only when it is genuinely ambiguous or destructive: a
force-push, a history rewrite, committing something explicitly marked never-committed (game-derived
data, secrets), or a change that has drifted outside the task the user actually asked for.

## 10. One state per fact, and say which instance a fix targets

**Cost this session, twice over, at two different scales.** At the asset scale: two live
instances of `1-Medical` exist (`/Game/BioShockSlice/1-Medical`, `/Game/BioShockLevel/1-Medical`),
a fix landed in one, and "still broken" reports were ambiguous about which one was being looked at
until that was made explicit. At the documentation scale: seven different "here is where the
project stands" tracker docs had accumulated, each correctly redirecting to the next but requiring
three hops to reach current truth — the same failure shape, one level up.

**When more than one instance, copy, or record of the same logical thing exists, name which one
every fix, verification, and status claim applies to — and prefer collapsing to one authoritative
instance over maintaining several in parallel.** A second copy is exactly how two truths quietly
disagree (this project's own `README.md` makes the identical point about status docs specifically);
the fix is the same whether the duplicate is a map, a config value, or a paragraph of prose.

## 11. Retire a superseded document in the same session you find it, not just banner it

**Cost avoided by doing this promptly during the 4 Sept documentation pass**, and the pattern that
would have cost more had it continued: the same fact (a DXT5N-vs-3DC texture-format contest) was
found duplicated across three files, each a legitimate write-up in its own right but only one of
which — `reference-comparison.md` — was ever meant to be canonical. A "superseded, see X" banner
left on the other two, without also trimming their own copy, is a half-fix: the next reader can
still find and read the stale copy first, particularly if they arrive by search rather than by the
index.

**When a passage is confirmed superseded, cut it to a pointer at the canonical source in the same
edit that adds the banner — don't leave the full stale content sitting alongside a note saying not
to trust it.** The banner is for the reader who arrives mid-document; the trim is what stops the
duplication from being findable at all. Archive full sections (move, don't delete) when the content
has narrative or historical value and cutting it would lose something — as with `HANDOFF.md`'s
session-log tail — but even then, replace it in place with a short pointer rather than leaving it
where it can still be mistaken for current.

## 12. A stray worktree is a silent place for work to go missing

**Found, not caused, this session:** a second git worktree (`claude/magical-sammet-c69481`) sitting
beside the main tree with two modified files, uncommitted, three days stale — invisible to `git
status` in the main tree and easy to overwrite or lose without ever being seen.

**Before a broad "make sure everything is committed" pass, run `git worktree list` and check each
one's own `git status`**, not just the tree you're sitting in. Don't act on what's found there
without asking — it may be another session's live work — but surface it rather than silently
stepping around it.

---

## What this replaces

Nothing here overrides `ENGINEERING_RULES.md`'s evidence and confidence discipline. Read together:
that file says *never ship an unverified claim*; this one says *verify it the cheapest way that
actually works, the first time, and don't repeat an expensive check that already told you it
doesn't answer the question you're asking.*
