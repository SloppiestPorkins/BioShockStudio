# w19 — remaining interact-trace failures + three STATUS UNCLEAR items

Sandboxed pass (28 Sept 2026). Did **not** launch Unreal or rebuild; Claude owns the
headless re-verify. Evidence below comes from (a) the post-w18 interact log already on disk,
(b) exported Medical / whole-game script-actions sidecars, (c) the Medical ue5-level
manifest, and (d) `git log` since the 6 Sept audit. No runtime fix is claimed without a
counter Claude can re-measure.

## 1. The 46 remaining interact-trace failures

### Prior result (unchanged figure)

From `%TEMP%/interact_trace_run.log` after the w18 landing fixes
(`12e8b9c` + FaceActor stale-rotation fix in `ShockGameMode.cpp`):

```
BIOSHOCK_INTERACT_COUNTS pickups=147 containers=55 stations=10
BIOSHOCK_INTERACT_FAIL targets=94 promptFail=46 actionFail=3
  pickupsInteract=29 containers=55 stations=10
```

Same 46 actor names every time (29 pickups / 11 containers / 6 stations). Not aim-dependent
— that was ruled out when FaceActor started forcing `SetActorRotation` + camera world
rotation before the synchronous trace.

### What the existing PROMPT_FAIL lines already prove

Each fail logs `cached=` (the interactable `TickInteractionTrace` accepted, if any):

| Mode | Count | Evidence |
|---|---|---|
| `cached=None` | **39 / 46** | Trace either hit nothing, or hit a non-interactable (shelf / wall / BSP). Old log cannot tell these apart. |
| `cached=` a *different* interactable | **7 / 46** | Target lost to a nearer pickup/container/station on the same Visibility ray. |

Wrong-interactable cases (CONFIRMED from the log, not a hypothesis):

- `ShockConsumablePickup_99` → cached `ShockSearchableContainer_22`
- `ShockConsumablePickup_106` → `ShockSearchableContainer_13`
- `ShockConsumablePickup_110` → `ShockSearchableContainer_0`
- `ShockConsumablePickup_119` → `ShockSearchableContainer_23`
- `ShockConsumablePickup_135` → `ShockSearchableContainer_2`
- `ShockConsumablePickup_136` → `ShockSearchableContainer_28`
- `ShockStationBase_3` → `ShockConsumablePickup_21`

That is the "stacked loot / overlapping collision" candidate from
`docs/research/w18-pie-regressions.md`, confirmed for a minority of the remaining fails.
The majority (39) still need the raw `Hit.GetActor()` to classify.

### Diagnostic added this pass (not yet re-run)

Harness changes (Cursor lane only):

1. `AShockPlayer::TickInteractionTrace` now stores the raw Visibility hit on every call —
   `LastInteractTraceHitActor` / `LastInteractTraceHitDistance` / `bLastInteractTraceDidHit`
   (`ShockPlayer.cpp` ~2420–2445, accessors in `ShockPlayer.h` ~243–253).
2. `BeginVerifyInteractTrace` emits one `BIOSHOCK_INTERACT_TRACE_HIT` line after every
   `BIOSHOCK_INTERACT_PROMPT_FAIL`, with `hit` / `hitActor` / `hitDist`, FaceActor
   `stand` / `targetAim` / `standToTarget`, and `awayDegenerate`
   (`ShockGameMode.cpp` ~2730–2795, called from the three PROMPT_FAIL branches).
3. `tools/ue5/verify_interact_trace.py` parses those lines into `result.traceHits` and a
   `traceHitClasses` histogram (`no_hit` / `wrong_mesh_or_blocker` / `wrong_interactable` /
   `hit_target_but_no_prompt` / `hit_null_actor`).

Once Claude rebuilds and re-runs `-bioshockverifyinteract`, the 39 `cached=None` rows split
into "hit a StaticMeshActor / BSP" vs "hit nothing (stand inside geometry or Away
degenerate)". That is the input needed before changing FaceActor or collision — not guessed
here.

### Candidates still open (not fixed)

| Candidate | Status after this pass |
|---|---|
| FaceActor `Away` degenerate / stand inside geometry | **Instrumentable now** via `awayDegenerate` + `stand=`. No count yet without a fresh run. |
| Non-interactable mesh wins the Visibility trace | **Instrumentable now** via `hitActor`. Expected to cover most of the 39 `cached=None`. |
| Stacked interactables | **CONFIRMED** for 7/46 from the old `cached=` field. Gameplay still uses first-hit; a fix would be a deliberate behaviour change (multi-trace / ignore nearer interactables), not applied here. |

No FaceActor or collision change shipped in this pass: nothing new was reproducible under
the sandboxed "do not launch Unreal" rule.

## 2. STATUS UNCLEAR — Wrench viewmodel position

**Finding: no code regression found since the 6 Sept audit. Do not treat as a fresh bug
without a new live capture.**

- `docs/archive/AUDIT_2026-09-06.md` recorded wrench as **Fixed / good** (`wr_final.png`,
  held by the handle, head up-forward) at commit `35f459c` (component-level 180° on the
  static wrench mesh).
- Same day, `d479fbe` moved that 180° onto the imported hands-rig **Wrench socket** via the
  manifest (`BioShockSocketLibrary::RestoreSockets`) and **removed** the component hack in
  `ShockWeapon.cpp` (~232–237 today) so SnapToTarget does not double-correct. That is the
  intended end state of the audit fix, not a silent revert.
- Later viewmodel commits (`d256b09` fixed eye-relative hands, `41c0e1a` wrench swing A/B)
  still describe the wrench as reading correctly in capture notes. `12e8b9c` (w18) did not
  touch socket / wrench orientation code.
- Grep of `ShockWeapon.cpp` / `NEWPlayerHands` / socket-transform commits since 6 Sept shows
  no later change that undoes the manifest socket rotation.

If the live PIE report still looks wrong, it needs a fresh screenshot against the current
socketed mesh — headless attach verifies cannot see grip orientation
(`ENGINEERING_RULES.md` §60 "First-person viewmodels are a look-at-it problem"). No wrench
code change in this pass.

## 3. STATUS UNCLEAR — Bathysphere room water / stairs

**Finding: Medical does contain a bathysphere pavilion with stair-water FX and water
volumes; the specific live bug cannot be identified from data alone.**

Checked:

- Collision harness route `bathysphere_pavilion`
  (`verify_collision.py` ~287: `-18096,2480,7794` → `-19120,2224,7808`) — flat approach
  only; stairs deliberately not asserted (capsule/riser note in the same file).
- Medical ue5-level (`Exports/slice/1-Medical/1-Medical.ue5-level.json`):
  - `BathysphereSwitch1` (`ToNeptuneSwitch`) at approx `(-17102, 5303, 7708)`.
  - Six `StaticMeshActor*` instances of `FX_StairWater_C` (e.g. `(-21890, 528, 7492)`,
    `(-24832, 3914, 8002)`, cluster around `(-2668x, 48xx–64xx, 79xx)`).
  - Many `FluidVolume` / `CascadingWaterVolume` actors across Medical (including near the
    bathysphere / tunnel-collapse region).
- `repair_water_surfaces.py` defaults `BIOSHOCK_WATER_MAP` to `/Game/BioShockSlice/1-Medical`
  — i.e. it is authored to run on this slice. This sandboxed pass did **not** re-run it and
  did not read a live repair report from the UE project.
- `ceab1c1` / `restore_floor_prop_hulls.py` ~117–120: `FX_StairWater` is intentionally
  **kept non-colliding** (it matched the `_FLOOR` name regex via `"stair"`). That is a
  known prior fix for walkable-hull false positives, not evidence the pavilion stairs are
  broken or fixed.

Still unknown without a live screenshot / player description: whether the complaint is
(a) water material look, (b) colliding water sheet, (c) missing walkable stair hull,
(d) something else near the bathysphere airlock. No code change.

## 4. STATUS UNCLEAR — FisheriesAccordian locked gate

**Finding: the unlock chain is real, but it is not gated on `Global_Med_OpenedMedicalGate`.
Nothing in any exported script-actions sidecar ever assigns that flag.**

### What actually unlocks `FisheriesAccordian`

In `1-Medical.script-actions.json`:

- `ActionUnlockDoor18` / `ActionOpenDoor6` both target `DoorLabel: "FisheriesAccordian"`.
- Their parent is `ActionIf929` (`ActionIf_ActionIf929_24539`), whose `testsOr` is
  `BooleanStatement61` with `lhs: "        Get Number of Items in Inventory"` / `rhs: "1"`
  — i.e. an inventory-count check (quarantine-key style), **not** a global flag.
- That ActionIf lives on Script label **`quarswitched`** (`Script16` in the ue5-level).
  True branch also clears `NeptuneGateBV`, completes quests, sets `global_quarlifted`, etc.

Door actor: `AccordianGateDoor1`, label `FisheriesAccordian`, transform translation
approx `(-17104, -4368, 7681)` in the level instances list.

### What `Global_Med_OpenedMedicalGate` actually does

- Single reference game-wide across every `*.script-actions.json` under
  `Exports/`: `BooleanStatement267` (`lhs: Global_Med_OpenedMedicalGate`, `rhs: True`).
- Used only by `ActionIf52` on Script label **`NeedSteinmansKey`** (`Script299`), whose
  true branch is solely `actionSetQuestHint62` — a quest-hint, not an unlock/open.
- **Zero** `ActionVariableAssign` / `ActionVariableAssignIfNotExist` / Increment / Decrement
  (or any other assign-class) targets `OpenedMedicalGate` or `Global_Med_OpenedMedicalGate`
  in any map sidecar.

So the earlier STATUS.md wording that unlock/open is "gated on
`Global_Med_OpenedMedicalGate`" was wrong on the exported data. The flag is read once for a
hint and never written anywhere this project has exported. Reportable outcomes:

1. The writer lives in a system not imported yet (quest/fact completion outside script
   actions, bytecode-only, another package not in the sidecar set), or
2. It is an unauthored / dead flag in the shipped Medical scripts.

No unlock hack and no forced assign of the flag in this pass — inventing a setter would
be guessing.

## 5. Files touched

| File | Change |
|---|---|
| `ShockPlayer.h` / `.cpp` | Raw interact-trace hit cached for verify |
| `ShockGameMode.cpp` | `BIOSHOCK_INTERACT_TRACE_HIT` on every PROMPT_FAIL |
| `verify_interact_trace.py` | Parse + classify TRACE_HIT lines into the JSON report |
| `docs/research/w19-remaining-interact-fails.md` | This note |

Not touched (do not regress): `verify_weapon_impacts_pie.py`, `verify_ragdoll_coverage.py`,
`verify_gameplay_fidelity.py`. Interact verify still fails until the 46 are fixed; the
script now fails *with* a classifiable hit dump instead of name-only PROMPT_FAIL lines.

## 6. Claude's live follow-up pass (28 Sept 2026, same day) — real classified data + a real fix

Cursor's pass above was sandboxed (no build, no run). This section is the actual build +
re-run + fix, with numbers pulled from real headless verifies, not hypotheses.

### 6a. Two bugs found in the diagnostic pipeline itself before any real data could be read

1. **`run_verify_*.py`'s except-block clobbered the report.** Every wrapper in
   `tools/ue5/run_verify_*.py` (and `run_game_possess.py`) wrote `{"error", "traceback"}`
   over the OUT file on failure — destroying the full report `main()` had already written
   to the same path immediately before raising. First surfaced as a misleading
   "traceHitClasses: null" read. Fixed in all 9 wrappers: on exception, read back the
   existing OUT file (if any) and merge `error`/`traceback` into it instead of overwriting.
2. **`TRACE_HIT_RE` never matched.** `verify_interact_trace.py`'s regex ended in `...$`
   without `re.MULTILINE`. Python's `$` without that flag only anchors at the true end of
   the whole string (or just before a trailing final newline) — not at each line break in a
   multi-line log — so `finditer` over the full log text silently matched zero of the 46
   `BIOSHOCK_INTERACT_TRACE_HIT` lines that were genuinely present in the raw log.
   `traceHitClasses` read back as `{}` every time despite the C++ instrumentation working
   correctly. Fixed by adding `re.MULTILINE` to the compiled pattern.

Also: `verify_interact_trace.py` runs the actual interact-trace game pass as a **separate
`-game -bioshockverifyinteract` subprocess**, writing to `%TEMP%\interact_trace_run.log` —
not the outer `-run=pythonscript` commandlet's own `-abslog`. Read `%TEMP%\interact_trace_run.log`
/ `%TEMP%\interact_trace_report.json` directly, not the outer wrapper's log, when debugging
this verify by hand.

### 6b. First real classification (46 failures, pre-fix)

```
traceHitClasses: {"no_hit": 17, "wrong_mesh_or_blocker": 22, "wrong_interactable": 7}
```

`wrong_mesh_or_blocker` dominated. Dumped world positions + collision bounds for a sample
(`ShockConsumablePickup_12` and its blocker `StaticMeshActor_1517`) via a one-off
`EditorActorSubsystem`/`get_actor_bounds` script:

- `ShockConsumablePickup_12`: `GetActorLocation()` Z=8095.0, collision-only bounds extent
  ≈48–56uu → sphere spans roughly Z 8038–8151.
- `StaticMeshActor_1517` (the shelf it sits under): bounds Z 8142.5–8245.5, X range
  overlapping the pickup's X almost exactly.
- The **aim point** the harness actually used, `targetAim=(-26066,4056,8135)`, came from
  `FaceActor`'s then-current `TargetLoc = Target->GetActorLocation() + FVector(0,0,40)`
  (`ShockGameMode.cpp` ~2741) — Z=8095+40=8135, which sits **7uu inside the pickup's own
  sphere but essentially flush against the shelf's underside (8142.5)**. A hard-coded +40uu
  "aim slightly above the pivot" guess, applied uniformly to pickups/containers/stations
  regardless of their actual size, happened to land right on the boundary between two
  collision volumes for any pickup sitting close under a shelf.

### 6c. The fix

`ShockGameMode.cpp`'s `FaceActor` now prefers `Target->GetActorBounds(true, Origin, Extent)`
(collision-only bounds origin) over the flat `+40` offset, falling back to the offset only
if the actor reports zero bounds extent. This adapts per actor: sphere-rooted pickups and
containers get their true sphere center (safely mid-volume, not near an edge); floor-pivoted
stations (root = `Mesh`, per `ShockStationActor.cpp` ~16–17) get the vertical center of
their actual mesh bounding box instead of a guessed height.

### 6d. Result (verified, not estimated)

Rebuilt, re-ran `run_verify_interact_trace.py` headlessly against the live `1-Medical` slice:

```
Before: promptFail=46  {"no_hit": 17, "wrong_mesh_or_blocker": 22, "wrong_interactable": 7}
After:  promptFail=36  {"no_hit": 9,  "wrong_mesh_or_blocker": 20, "wrong_interactable": 7}
```

46 → 36 (10 fixed, ~22%). `wrong_interactable` unchanged as expected (unrelated to aim
point — that's the stacked-loot first-hit-wins behaviour, a deliberate design question, not
a bug). `no_hit` nearly halved (17 → 9). `wrong_mesh_or_blocker` dropped only 2 (22 → 20):
re-checking `ShockConsumablePickup_12` specifically after the fix, it **still** fails
(`hitActor=StaticMeshActor_1517 hitDist=152.9` vs `standToTarget=150.0` — the ray now aims
dead-center at the sphere but still ends up grazing the shelf). For this specific case the
pickup's collision sphere (radius 48, spanning up to Z≈8143) and the shelf's collision
(starting at Z≈8142.5) overlap by under 1uu — the two volumes are placed almost exactly
touching. No amount of harness aim-point tuning fixes that; the sphere and the shelf are
authored (or imported) close enough to overlap. **This looks like a real, minor import-time
placement issue** (a subset of pickups sitting flush enough against decoration that their
own collision sphere pokes into the decoration's), not a further harness bug — worth a
follow-up pass that nudges pickup placement away from overlapping static geometry during
import, rather than more FaceActor changes. Not attempted in this pass (out of scope for a
harness fix; needs its own investigation into how much clearance the import step should
enforce).

### 6e. Updated candidate table

| Candidate | Status |
|---|---|
| FaceActor aim point landing on a collision-volume boundary | **Fixed** — `GetActorBounds` origin replaces the flat `+40` offset. 10/46 resolved. |
| Pickup collision sphere overlapping neighbouring decoration collision (shelf, etc.) | **Confirmed for at least 1 case (`ShockConsumablePickup_12`), likely explains a chunk of the remaining 20 `wrong_mesh_or_blocker`.** Not fixed — needs an import-time placement pass, out of scope here. |
| Stacked interactables (first-hit-wins) | **Confirmed for 7/36.** Unchanged; a deliberate gameplay-behaviour question, not applied here. |
| Remaining 9 `no_hit` | Not yet individually diagnosed — candidates are stand-inside-geometry or genuinely > trace range (260uu); the per-actor `stand=`/`awayDegenerate=` fields in the report make this diagnosable without another blind pass. |

### 6f. Files touched (this follow-up)

| File | Change |
|---|---|
| `run_verify_ai_archetypes.py`, `run_verify_audio.py`, `run_verify_impact_fx.py`, `run_verify_interact_trace.py`, `run_verify_main_menu.py`, `run_verify_pickups.py`, `run_verify_ragdoll_coverage.py`, `run_verify_weapon_impacts_pie.py`, `run_game_possess.py` | Except-block now merges into the existing report instead of clobbering it |
| `verify_interact_trace.py` | `TRACE_HIT_RE` compiled with `re.MULTILINE` |
| `ShockGameMode.cpp` (`FaceActor`) | `TargetLoc` uses `GetActorBounds(true)` origin, falling back to the old `+40` offset only when bounds are degenerate |

Regression sweep after this pass, all headless against the live slice: `verify_weapon_impacts_pie`
PASS, `verify_ragdoll_coverage` PASS (23 archetypes), `verify_vita_chamber` PASS,
`verify_gameplay_fidelity` PASS (27 checks), `verify_scripting_movers` PASS (29 checks). No
regressions from the `FaceActor` or wrapper changes.

## 7. Next step (for a future pass)

1. Individually diagnose the 9 remaining `no_hit` cases using `stand=`/`awayDegenerate=` from
   the (now-working) `traceHits` report field.
2. Decide whether to nudge pickup placement during import when it's found sitting flush
   against another collider's bounds (the `ShockConsumablePickup_12`/`StaticMeshActor_1517`
   pattern) — a content-side fix, not another harness change.
3. Decide, as a deliberate design call (not a bug fix), whether the interact trace should
   resolve stacked interactables by nearest-to-camera-center rather than pure first-hit,
   for the 7 `wrong_interactable` cases.
