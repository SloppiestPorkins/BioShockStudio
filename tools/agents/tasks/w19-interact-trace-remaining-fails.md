---
worker: cursor
base: main
verify: git status --short
lane: tools/ue5/**, docs/research/**
---

# w19 — remaining interact-trace failures (roadmap priority 1, continuing w18)

> **Run mode:** non-interactive, sandboxed. Do NOT launch Unreal, do NOT build, do NOT touch
> `C:\Users\Jack\Documents\BioShockUE5`. Do NOT commit. Claude builds + runs the headless verify.

Context: `docs/research/w18-pie-regressions.md` "Landing follow-up" section and `docs/STATUS.md`'s
open-bug table. w18 fixed the pickup-collision root cause of "nothing interactable"
(prompt pass rate 1/94 → 48/94), but **29 pickups / 11 containers / 6 stations still fail** — a
consistent subset (same actor indices every run), not aim-dependent (ruled out by the w18 landing
fix), so something else specific to those placements is wrong.

**Investigate before guessing a fix.** Candidates already named in the research doc, not confirmed:
- The harness's `FaceActor` computes `Away = (Player->GetActorLocation() - TargetLoc).GetSafeNormal2D()`
  then stands the player at `TargetLoc + Away*120`. If the player's PRE-teleport position is already
  very close to the target (or exactly above/below it, making `Away` degenerate before the
  `IsNearlyZero()` fallback), the stand point could land inside geometry or on the wrong side of a
  wall, blocking the trace before it reaches the pickup's own collision sphere.
- A shelf/decoration mesh overlapping a pickup and winning the line trace instead of the pickup
  itself (trace returns the first blocking hit along the line — check `Hit.GetActor()` for the
  failing cases, not just whether the trace hit *something*).
- Multiple pickups/containers stacked close together (e.g. a corpse loot pile) where the 120uu
  standoff for one lands inside the collision of another.

Get real data first: extend `verify_interact_trace.py`'s failure reporting (or write a one-off dump)
to log, for every failing target, the actual `Hit.GetActor()` name and `Hit.Distance` from the
`FaceActor` stand point — that tells you whether the trace is hitting the wrong thing, nothing, or
the right thing at the wrong distance, which determines what actually needs fixing.

Also pick up the three **STATUS UNCLEAR** items from `docs/STATUS.md`'s bug table — investigate each,
do not assume an answer:
1. **Wrench viewmodel position.** `docs/archive/AUDIT_2026-09-06.md` recorded this as fixed
   (`35f459c`). Check whether anything since 6 Sept could have regressed it (grep the commit log for
   anything touching `ShockWeapon.cpp`'s wrench socket/rotation code, `NEWPlayerHands`, or the
   manifest-socket-transform system since then) before assuming a fresh bug. If you can't find a
   regression, say so plainly rather than guessing at a fix.
2. **Bathysphere room water/stairs.** No tracked doc names this specific room. Search the level
   manifest / placed-actor census for anything with "bathysphere" or "stairs" in its label near a
   water volume, and check whether `repair_water_surfaces.py` (or its water-volume-surface logic)
   ran against whatever map/room this is. If you cannot identify the room from data alone, say
   exactly what you checked and what's still unknown — this may need a live screenshot from the
   user, which you cannot get in this sandboxed pass.
3. **FisheriesAccordian locked-gate.** `docs/STATUS.md` already found the script chain
   (`ActionUnlockDoor`/`ActionOpenDoor` gated on `Global_Med_OpenedMedicalGate`) but nothing in
   Medical's exported script data ever SETS that flag. Check whether another already-imported
   script (in Medical or referencing this specific gate) is supposed to set it — search the full
   script-actions sidecar for any `ActionVariableAssignOverwrite`/similar targeting a name containing
   "OpenedMedicalGate" or "Global_Med". If nothing sets it anywhere in the exported data, that's a
   real, reportable finding (either the trigger condition for setting it lives in a system this
   project hasn't imported yet, e.g. a quest/fact completion, or it's a genuinely unauthored/dead
   flag in the shipped game) — do not invent a fix for a flag nothing sets.

## Deliverable

- Fixes only for what you can reproduce and verify (a log line, a counter, an asserted state) — not
  guesses.
- Updated `verify_interact_trace.py` (or a new diagnostic script) with the extra Hit.GetActor()/
  distance reporting.
- `docs/research/w19-remaining-interact-fails.md`: what you found for the 46 remaining interact
  failures and each of the three STATUS UNCLEAR items, own words, cite file:line/commit.
- Don't regress: `verify_weapon_impacts_pie.py`, `verify_ragdoll_coverage.py`,
  `verify_interact_trace.py`, `verify_gameplay_fidelity.py`.
