# w21 — interact-trace placement nudge for the remaining 36

Sandboxed Cursor pass (28 Sept 2026). Did **not** launch Unreal, rebuild, or touch
`BioShockRuntime/**`. Claude owns: run `dump_interact_fail_bounds.py`, re-import
pickups/stations (or `clear_interactable_placement.main()`), re-run
`run_verify_interact_trace.py`, and fill the after-counts below.

Scope: `1-Medical` only. `wrong_interactable` (7) stays out of scope — stacked
first-hit-wins, deliberate design question (w19 §6e).

## 1. Baseline (from live report, pre-this-change)

Source: `%TEMP%\interact_trace_report.json` (`result.traceHits` / `traceHitClasses`),
dated 28 Sept 2026 after the w19/w20 rebuild. Regenerated figure matches the task table:

```
promptFail=36
wrong_interactable     7   (OUT OF SCOPE)
wrong_mesh_or_blocker 20
no_hit                  9
```

In-scope = 29 (20 + 9). Breakdown by kind:

```
container  wrong_mesh_or_blocker  6
pickup     no_hit                 4
pickup     wrong_mesh_or_blocker  9
station    no_hit                 5
station    wrong_mesh_or_blocker  5
```

## 2. How the cases were classified (without a live bounds dump)

This pass cannot call `get_actor_bounds` (no Unreal). Evidence used instead:

1. w19's measured sample for `ShockConsumablePickup_12` / `StaticMeshActor_1517`
   (`docs/research/w19-remaining-interact-fails.md` §6b): sphere radius 48, sphere top
   Z≈8143, shelf underside Z≈8142.5 — **overlap under 1uu on Z**.
2. Per-row `hitDist` vs `standToTarget` from the trace report (below).
3. C++ collision sizes: pickup sphere 48 (`ShockConsumablePickup.cpp:35-37`), container
   Reach sphere 120 (`ShockSearchableContainer.cpp:14-15`), station root = Mesh with
   QueryAndPhysics (`ShockStationActor.cpp:16-19`).
4. `awayDegenerate=0` on every in-scope row — FaceActor's Away fallback was not the
   degenerate single-axis case.

A dump script that *does* read live bounds is at
`tools/ue5/dump_interact_fail_bounds.py` → `%TEMP%\w21_interact_fail_bounds.json`.
Claude should run it once and paste measured overlap depths into §4 if they disagree
with the inference below.

### hitDist − standToTarget buckets (wrong_mesh only)

| Bucket | Meaning | Count |
|---|---|---|
| **grazing** (\|Δ\| < 15) | First hit lands at roughly the target distance — blocker and target collision are flush on the aim ray | 4 |
| **early_blocker** (Δ ≪ 0) | Something between stand and target wins Visibility | 8 |
| **past_target** (Δ ≫ 0) | Aim ray missed the target's own collision and hit world/other beyond `targetAim` | 8 |

## 3. What was built (as originally proposed by this worker — see §5a for why it was rewritten)

### Placement-clearance pass — `tools/ue5/clear_interactable_placement.py` (original design)

After `_place` in `import_slice_pickups.py` (pickups + containers) and again after station
placement in `import_slice_stations.py`, scan every
`ShockConsumablePickup` / `ShockSearchableContainer` / `ShockStationBase` and:

1. Take collision-only AABB via `get_actor_bounds(True)`.
2. Compare against neighbouring `StaticMeshActor`s that have modest colliding bounds
   (extent ≤ 2500uu on every axis — skips Compiled World / exterior shells).
3. If the AABBs overlap on all three axes with shortest-axis depth in
   **(0.5, 8.0] uu** (the flush-graze band w19 measured), nudge the interactable along
   that axis by `overlap + 2uu` clearance.
4. Deep overlaps (> 8uu) are recorded under `skippedDeep` and **not** moved — a few-uu
   nudge cannot fix a 120uu container sphere swallowing a prop, and would detach loot
   from its resting surface (explicitly out of the "only measured flush overlap" rule).

Wired at:

- `import_slice_pickups.py` — after the place loop, before `save_current_level`
- `import_slice_stations.py` — same, so stations placed later also get cleared

**Claude's landing pass found this whole-level-scan design produces ~65% false positives
(137/212) when actually run — see §5a.** The file shipped in this commit is a rewritten,
narrower version: it reads the live interact-trace report and only measures/nudges an actor
against its own specifically-reported `hitActor`, nothing else. The wiring into
`import_slice_pickups.py`/`import_slice_stations.py` is unchanged; the scan strategy inside
`clear_overlaps()` is not what's described above any more. No slice-specific location override
file existed; the fix lives in the shared placement path, not a one-off Medical JSON. Standalone
re-run: `clear_interactable_placement.main()` (saves the level; no-op if no interact-trace report
exists yet — see the module docstring).

### Deliberately not done

- No change to `BioShockRuntime/**` / FaceActor / interact trace order.
- No nudge away from other interactables (pickup→pickup, container→container) — those
  are the stacked-loot family, same design question as `wrong_interactable`.
- No nudge away from `SkeletalMeshActor` corpses for containers — early hits on the
  corpse mesh with a 120uu Reach sphere are deep embeds / LOS, not flush placement.
- No invented stand-point harness fix for `no_hit` (see §4).

## 4. Per-case findings (29 in-scope)

### 4a. Pickup `wrong_mesh_or_blocker` (9)

| Target | hitActor | Δ hit−stand | Finding | Action |
|---|---|---|---|---|
| `ShockConsumablePickup_12` | `StaticMeshActor_1517` | +2.9 | **CONFIRMED flush overlap** (w19 §6b). Sphere under shelf. | Clearance pass — expected fix |
| `ShockConsumablePickup_16` | `StaticMeshActor_1510` | −11.4 | Grazing / near-target StaticMesh — same pattern family | Clearance pass if measured overlap in band |
| `ShockConsumablePickup_81` | `StaticMeshActor_3036` | +2.7 | Grazing StaticMesh — same pattern | Clearance pass if measured overlap in band |
| `ShockConsumablePickup_138` | `StaticMeshActor_4521` | −34.4 | Early blocker on the aim ray; may not overlap the pickup sphere at all | Leave unless dump shows flush overlap |
| `ShockConsumablePickup_113` | `StaticMeshActor_1627` | +92.1 | Past-target — ray missed the 48uu sphere, hit decoration beyond. Not a sphere/shelf flush | Open — not a placement-nudge case |
| `ShockConsumablePickup_136` | `StaticMeshActor_5311` | +110.0 | Past-target onto the giant world hull (`5311` also blocks four stations). Sphere miss / stand-inside-world, not flush decoration | Open — not a placement-nudge case |
| `ShockConsumablePickup_88` | `ShockConsumablePickup_72` | +29.6 | Hit another pickup; `cached=None` so classifier says `wrong_mesh` not `wrong_interactable` | **Out of placement scope** — stacked interactables |
| `ShockConsumablePickup_89` | `ShockConsumablePickup_34` | +44.8 | Same stacked-pickup family | Open (design) |
| `ShockConsumablePickup_90` | `ShockConsumablePickup_139` | +1.1 | Same stacked-pickup family | Open (design) |

### 4b. Container `wrong_mesh_or_blocker` (6)

Containers use a **120uu** Visibility Reach sphere. Almost any nearby prop sits inside that
AABB — deep overlap, not flush. Early hits at ~40–60uu with `standToTarget=150` mean the
harness ring never got a probe that reached the container itself.

| Target | hitActor | Δ | Finding | Action |
|---|---|---|---|---|
| `_2` | `SkeletalMeshActor_3` | −92.4 | Corpse mesh in front of / inside Reach | Skip (skeletal + deep) |
| `_11` | `SkeletalMeshActor_17` | −91.4 | Same | Skip |
| `_46` | `SkeletalMeshActor_41` | −92.4 | Same | Skip |
| `_21` | `StaticMeshActor_1356` | −97.2 | Early StaticMesh; deep vs 120uu sphere | Skip unless dump shows ≤8uu (unlikely) |
| `_24` | `StaticMeshActor_3205` | −108.4 | Same | Skip |
| `_54` | `ShockSearchableContainer_48` | −99.5 | Stacked containers | Open (design) |

### 4c. Station `wrong_mesh_or_blocker` (5)

| Target | hitActor | Δ | Finding | Action |
|---|---|---|---|---|
| `_0`, `_3`, `_4`, `_6` | `StaticMeshActor_5311` | +60…+104 | Past-target onto the world hull. Station mesh collision did not register on the aim ray (missing mesh / zero collision bounds / ray through non-blocking geo). FaceActor's probe stops at `targetAim`; the interact trace continues to 260uu and hits `5311` | **Not an overlap-nudge problem** — station mesh / collision coverage |
| `_8` | `StaticMeshActor_2635` | −65.6 | Early StaticMesh on the path | Clearance only if dump shows flush mesh-bounds overlap; otherwise open LOS |

### 4d. `no_hit` (9) — not forced into the placement narrative

Every row has `awayDegenerate=0` and a finite `stand=` / `targetAim=` with
`standToTarget` ≈ 150 (201 for `ShockStationBase_9`). So this is **not** the
Away-degenerate FaceActor fallback. The Visibility trace from stand through aim hit
nothing within interact range.

| Target | Notes | Likely class | Action |
|---|---|---|---|
| Pickups `_17` (Wrench), `_33`, `_66`, `_87` | Manifest loc matches `targetAim` (sphere center). A 48uu Visibility sphere at 150uu should be hittable unless the stand is inside solid (start-penetrating traces often return no hit) or collision was stripped | Harness / stand-inside-geometry limitation, **not** measured flush overlap | **Left open** — do not invent a content nudge |
| Stations `_1`, `_2`, `_5`, `_7`, `_9` | Same empty-hit pattern; stations need a blocking mesh. `_9` has longer `standToTarget=201.2` (ring fell through to a farther candidate) | Missing/non-blocking station mesh and/or stand-inside-world | **Left open** |

## 5. Before / after failure counts — Claude's live pass, 28 Sept 2026

Cursor's sandboxed version above could not run Unreal; everything below is a real headless
measurement, not a projection.

### 5a. The worker's first script was too broad — caught before landing, not applied

`clear_interactable_placement.py`'s original design scanned **every** placed interactable
against **every** nearby `StaticMeshActor` in the whole level and flagged any AABB overlap
in a small band. A dry run found **137 of 212** interactables "overlapping" something — almost
entirely false positives:

- **33** were an actor's own display label colliding with a *different* object that happens to
  share the same label (e.g. two separate placed actors both labelled `AdamPickup2` — a
  pre-existing, previously-undiscovered duplicate-label/stale-ghost-actor issue in the level,
  unrelated to interact-trace and **out of scope here**, worth its own investigation later).
- **104** were ordinary close-together loot placement (items sitting near each other on a
  shelf/table — completely normal scene composition) that was never reported as an interact
  failure by the verify at all.

None of that corresponds to a real bug; nudging any of it would have been pure scope creep with
real risk (displacing correctly-placed loot). **Rewrote `clear_interactable_placement.py`**
before running it for real: it now reads the live `%TEMP%\interact_trace_report.json`
`wrong_mesh_or_blocker` rows and only measures/nudges an actor against its own specifically
reported `hitActor` — nothing else. Re-run: **20 cases considered, 3 nudged, 17 correctly
skipped** as out-of-band (overlaps of 24–200uu — genuine deep embeds/stacking, matching §4's
per-case table above almost exactly).

### 5b. The 3 precise nudges did not close the gap — reverted, not left half-done

Widened `MAX_FIXABLE_OVERLAP` 8.0 → 12.0 first: `dump_interact_fail_bounds.py` (fixed — see
below) measured the confirmed flagship case (`ShockConsumablePickup_12` vs
`StaticMeshActor_1517`) at **8.544uu** via `get_actor_bounds`' precise collision-only AABB, a
hair over the worker's original 8.0 guess. Applied the 3 nudges for real, re-ran
`run_verify_interact_trace.py`:

```
promptFail STILL 36 after the nudge (was 36).
```

Per-case:

- `ShockConsumablePickup_12`: moved -10.5uu on Z (down, away from the shelf). New trace:
  `hitActor=StaticMeshActor_1629` (a **different** mesh than before) at `hitDist=142.7` vs
  `standToTarget=150.0` — traded one flush graze for another. The shelf recess this pickup sits
  in is tight on more than one side; a single-axis push cleared the reported blocker but landed
  inside a neighbour.
- `ShockConsumablePickup_113`: moved +5.3uu on X. New trace: **same** `hitActor=StaticMeshActor_1627`,
  but now at `hitDist=248.7` (vs `standToTarget=150.0`) — the `FaceActor` ring-probe picked an
  entirely different stand candidate for the new position and now travels well past the target
  before hitting the same mesh elsewhere. The nudge changed which of the 32 ring candidates
  "wins", not whether the trace succeeds.
- `ShockConsumablePickup_138`: moved -4.1uu on X. New trace: same `hitActor=StaticMeshActor_4521`
  at `hitDist=110.5` — similar ring-candidate reshuffle, still blocked.

**Reverted all 3 positions** (back to their exact original coordinates, level re-saved,
re-verified: `promptFail=36`, same `{wrong_mesh_or_blocker:20, no_hit:9, wrong_interactable:7}`
distribution as before this task) rather than leave an unvalidated few-uu position drift in the
live map for zero measured benefit.

### 5c. Why a small single-axis nudge doesn't work here

Two compounding effects, both real findings, neither fixed in this pass:

1. **Tight multi-sided clutter.** A shelf recess or cabinet interior can have collidable geometry
   on more than one side within a few uu; clearing the one reported blocker along the shortest
   axis can walk straight into a different neighbour that wasn't even in the failure report
   (because the original position never grazed it).
2. **`FaceActor`'s ring-probe is position-sensitive.** w19 already found the multi-candidate ring
   probe doesn't reliably converge on the "right" stand point; a few-uu source-position change is
   enough to make it choose a different one of the 32 candidates, which can turn a near-miss into
   a completely different miss rather than a hit. This means **the interact-trace failure and the
   measured collision overlap are not as tightly coupled as §2–§4 assumed** — fixing the measured
   geometry issue does not reliably fix the trace outcome, because the trace's own stand-point
   choice is close to chaotic at this scale.

**Conclusion: a single-axis AABB-overlap nudge is not a reliable fix for this failure class.**
Closing these specific 3 (and likely the rest of the 20 `wrong_mesh_or_blocker` cohort) would need
either a placement search that verifies clearance from *all* nearby geometry (not just the one
reported blocker) before accepting a new position, or a fundamentally different `FaceActor`
stand-point strategy that isn't sensitive to uu-scale target movement — both bigger than this
task's scope. Recorded here rather than forcing a fix that doesn't hold up under test.

### 5d. Two more tooling bugs fixed along the way (same pattern as w19/z1)

- `dump_interact_fail_bounds.py`'s `_index_by_label` matched actors by
  `get_actor_label()` (the World Outliner display name), but the interact-trace report's
  `target`/`hitActor` fields come from C++ `GetName()` (the object's internal name) — same
  label-vs-name mismatch class of bug found during z1's landing pass this session, confirmed
  again here (`targetFound` was `False` for all 29 rows before the fix). Fixed to index by
  `get_name()`; all 29 cases resolved after the fix.
- `clear_interactable_placement.py`'s original whole-level scan (see §5a) is not just imprecise
  but was never actually exercised against real data before this landing pass — the sandboxed
  worker could not run it. Rewritten as described above.

### Final counts

| | promptFail | no_hit | wrong_mesh_or_blocker | wrong_interactable |
|---|---|---|---|---|
| Before this task | 36 | 9 | 20 | 7 |
| After this task | 36 | 9 | 20 | 7 |

**No net change — an honest negative result**, not a silent no-op: real tooling bugs were found
and fixed (both now committed and reusable for a future pass), real overlap data was measured for
all 29 in-scope cases, and a specific, previously-plausible fix strategy (single-axis AABB nudge)
was tried, measured, and shown not to work, with the reason understood (ring-probe stand-point
sensitivity, multi-sided clutter) rather than just "still broken."

Do not regress: `verify_gameplay_fidelity.py`, `verify_scripting_movers.py`,
`verify_vita_chamber.py` (untouched systems; clearance only moves interactables with
measured flush StaticMesh overlap).

## 6. Files touched

| File | Change |
|---|---|
| `tools/ue5/clear_interactable_placement.py` | New — flush-overlap AABB nudge for Medical interactables |
| `tools/ue5/dump_interact_fail_bounds.py` | New — one-off bounds dump for the 29 in-scope fails |
| `tools/ue5/import_slice_pickups.py` | Call clearance after place, before save |
| `tools/ue5/import_slice_stations.py` | Same |
| `docs/research/w21-interact-trace-placement-nudge.md` | This note |

## 7. Claude's verify checklist

1. `dump_interact_fail_bounds.py` → confirm which grazing rows have `overlap.minDepth` in
   (0.5, 8]; paste into §4 if numbers differ.
2. Re-run `import_slice_pickups.main()` + `import_slice_stations.main()` (or
   `clear_interactable_placement.main()` on the already-placed slice) so nudges land in
   `/Game/BioShockSlice/1-Medical`.
3. `run_verify_interact_trace.py` — fill the After row in §5.
4. Smoke the three named regression verifies if the shared import path is what Claude
   re-runs as part of a wider slice refresh.
