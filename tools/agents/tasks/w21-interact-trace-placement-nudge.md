---
worker: cursor
base: main
verify: git status --short
lane: tools/ue5/*.py, docs/research/**
---

# w21 — interact-trace: per-actor placement nudge for the remaining 36 (roadmap priority 1)

> **Run mode:** non-interactive, sandboxed. Do NOT launch Unreal, do NOT build, do NOT touch
> `C:\Users\Jack\Documents\BioShockUE5`. Do NOT commit. Claude builds + runs the headless verify.
> **Do not touch `tools/ue5/BioShockRuntime/**` (C++)** — this is a content/import-time fix, not
> another harness change; w19/w20 already fixed the harness-side and VM-side issues in this area.
> Scope is `1-Medical` only.

Context: `docs/research/w19-remaining-interact-fails.md` §6 (Claude's follow-up pass, same repo,
28 Sept 2026). After fixing the verify harness's aim-point bug (`GetActorBounds` origin instead of
a flat `+40uu` guess), interact-trace failures went 46 → 36 and stayed there through `w20` (a
separate, unrelated C++ landing). Current breakdown, by kind and classification (re-derived from
`%TEMP%\interact_trace_report.json`'s `result.traceHits` after the w19/w20 rebuild — regenerate it
yourself with `run_verify_interact_trace.py` rather than trusting this table if it's gone stale):

```
container  wrong_mesh_or_blocker  6
pickup     no_hit                 4
pickup     wrong_interactable     7   <- OUT OF SCOPE, see below
pickup     wrong_mesh_or_blocker  9
station    no_hit                 5
station    wrong_mesh_or_blocker  5
```

**`wrong_interactable` (7, all pickups) is explicitly OUT OF SCOPE for this task** — w19 confirmed
these are stacked interactables where first-hit-wins is a deliberate current behaviour, not a
placement bug; changing trace resolution order is a design decision, not made here.

## What w19 already proved for one case, confirm/extend for the rest

`docs/research/w19-remaining-interact-fails.md` §6b: `ShockConsumablePickup_12` (a
`wrong_mesh_or_blocker` case) sits with its 48uu-radius collision sphere (root `Collision`
component, `ShockConsumablePickup.cpp:35-37`) overlapping the shelf mesh `StaticMeshActor_1517`
directly above it by under 1uu (sphere top ≈ Z 8143, shelf underside ≈ Z 8142.5) — even a
dead-center aim still sometimes grazes the shelf. This is content placement, not a harness bug.

**Get real data for all 20 `wrong_mesh_or_blocker` + 9 `no_hit` cases** before proposing any fix —
a one-off dump script (pattern already used in w19's landing pass, not committed anywhere — write
your own) that, for each failing actor, loads `/Game/BioShockSlice/1-Medical` and reads:
`actor.get_actor_location()`, `actor.get_actor_bounds(True)` (collision-only), and for
`wrong_mesh_or_blocker` cases also the `hitActor` named in the trace report's `hitActor` field
(same bounds query). This tells you, per case: how much (if any) the target's own collision
overlaps the blocker's, in which axis, by how much.

## What to build

1. A `1-Medical`-scoped placement-clearance pass, run as part of (or right after) the existing
   slice import pickup/container/station placement step (`import_slice_pickups.py:132` `_place`,
   and whatever the equivalent container/station placement entry points are — check
   `import_slice_doors.py`/`import_slice_stations.py`/wherever containers place, don't assume
   pickups' pattern applies unchanged). For any placed interactable whose collision volume
   (sphere for pickups/containers, mesh bounds for stations) overlaps a neighbouring static
   mesh's bounds by more than a small epsilon (a few uu — namely enough to explain the observed
   grazing, not an arbitrary large number), nudge the interactable's position along the
   shortest-separating axis just clear of the overlap. **Only touch cases with a real, measured
   overlap** — do not nudge every interactable defensively; that would be scope creep past what's
   asked and could visually detach pickups from their intended resting surface.
2. If a case's `no_hit` (9 total: 4 pickup, 5 station) turns out NOT to be an overlap problem
   (check the `stand=`/`awayDegenerate=` fields already in the trace report — a genuinely
   unreachable stand point, e.g. inside a wall, is a different bug from a collision-overlap one),
   say so plainly per-case rather than forcing every failure into the placement-nudge narrative.
   A stand-point problem may need reporting back as a still-open harness limitation, not a content
   fix — don't invent one.
3. Re-run `run_verify_interact_trace.py` after your fix; report the before/after failure count and
   the new classification breakdown, same format as the table above.

## Deliverable

- The placement-clearance fix (wherever it actually belongs — check both the raw manifest-driven
  placement and any slice-specific override before picking one).
- `docs/research/w21-interact-trace-placement-nudge.md`: per-case data for all 29 in-scope
  failures (the 20 `wrong_mesh_or_blocker` + 9 `no_hit`), what you found, what you fixed and why,
  what you left open and why, cite file:line, own words. Update the before/after failure count
  honestly even if it doesn't reach zero — a partial, well-explained reduction is a valid outcome
  (that's what w19 delivered too).
- Don't regress: `verify_gameplay_fidelity.py`, `verify_scripting_movers.py`,
  `verify_vita_chamber.py` (unrelated systems, but this task touches shared slice-import code
  paths).
