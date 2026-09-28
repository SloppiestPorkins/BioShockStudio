---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**, tmp/**
---

# Collision pass + god rays + movement pass + spawn-through-floor enemies

User reports (7 Sept 2026, in-editor / interactive-PIE test of `/Game/BioShockSlice/1-Medical`
— the playable slice, NOT `/Game/BioShockLevel/1-Medical`):
1. "collision pass — outside geo shouldn't have collision, also everything needs more complex collision"
2. "god rays"
3. "do a pass on movement"
4. "when i spawn, two enemy AI npcs spawn and fall through the ground, and damage the player"

Four sub-problems, one landable change. Research each, write it down, build the fix once, prove
it headless + with `-game` captures. Do them in the order below (4 is the quickest and most
concrete; 1–2 change what has collision so 4's spawn-snap should account for it).

---

## Probe of the slice as it stands (7 Sept 2026)

`4209` `StaticMeshActor`s:
- `3898` on `CTF_USE_DEFAULT`, `311` on `CTF_USE_COMPLEX_AS_SIMPLE` (the compiled-world
  `Model\d+_\d+` BSP shell, from `fix_compiled_world_collision.py`).
- `3934` `QUERY_AND_PHYSICS`, `275` `NO_COLLISION`.
- **`3625` "simple-only": exactly one auto-generated convex hull each, no box/sphere.** Samples:
  `Long_Couch_4114`, `sf_shelving02_3952`, `bio_sinklong_3842`, `med_surgical_cabinet_searched_3611`,
  `Broken_Pipe_4516`, `Pipe_512_3402`, `med_pillar_large_base_3354`, `ConcreteWall_Hole_4748`,
  `Cracked_BW_Tile_Pile_3526`. A single hull round-trips a hollow cabinet / a bent pipe / a
  wall-with-a-hole into a solid blob — that is the "not complex enough."
- **Exterior geometry with live `QUERY_AND_PHYSICS` collision** (should be render-only):
  `skybox_city_9724`, `Gen_Counter_90_Outside_4037` (×many), `Gen_Counter_90_Wide_Outside_4519`
  (×many), `Kelp_Clusters_01_6038`, `Kelp_Clusters_Single_02_12793`, `kelp_01_12798`. The
  name-substring probe only caught `outside/skybox/kelp/seabed/cityscape/exterior/distant` —
  there is almost certainly more exterior/backdrop geo that doesn't match those words.

---

## 4. Two enemies spawn through the floor and shoot the player — already located

`AShockGameMode::PostLogin` (`ShockGameMode.cpp` ~line 2150) calls **`SpawnSliceEncounter(Player, Start)`
unconditionally** on every real player spawn — it is NOT gated behind a `bioshockverify*` param
like the checks around it. `SpawnSliceEncounter` (~line 737):
- Spawns `SliceEnemy0/1/2` at `PlayerLoc + Forward*375 ± Right*100` and `Forward*800`, with
  `Center.Z = PlayerZ + 150` — **no downward line trace to find the floor** — and
  `SpawnCollisionHandlingOverride = AlwaysSpawn`. Land the offset over a stair gap / exterior
  geo / an un-navmeshed spot and the pawn drops through (`MOVE_Falling`, nothing under it).
- Calls `AI->AddTargetToAttackOnSight("SlicePlayer")` and gives ranged archetypes a hitscan
  weapon immediately → they shoot the player the instant they exist.
- Staggered `SliceEncounterSpawnTimer1/2` spawn the 2nd and 3rd on a delay.

`SpawnSliceEncounter` / `SpawnOneSliceEnemy` / `VerifySliceFire` / `VerifySliceEncounter` were
scaffolding for the `-bioshockverifypossess` / `-bioshockverifyencounter` headless checks
(README "Game-mode movement + weapon-track verifies"). They must not run in normal play.

**Fix:**
- Gate the whole slice-encounter spawn (and the ammo/consumable pickup spawns that hang off
  `PrimaryEnemy`, if those exist only for the encounter) behind the verify params. A normal
  PIE / Standalone spawn places NO debug enemies.
- The real level's enemies come from `AggressorSpawner` (×19) / `TurretSpawner` (×11) /
  `AISpawnPoint` actors in `1-Medical.ue5-level.json`, driven by the script system (E2's
  `ShockActionSpawnAI` / spawn-zone repopulation). Check whether anything imports/places those
  into the slice. If not, note it as a follow-up in the doc — don't scope-creep here. The
  immediate fix is "no debug encounter on a normal spawn."
- Under the verify path, floor-snap the spawn in `SpawnOneSliceEnemy`: line-trace down from
  `SpawnLoc + Z*200`, place the capsule half-height above the hit, skip the spawn if no
  walkable hit within a few metres; don't hand the enemy a target/weapon until it's on the
  navmesh.

---

## 3. Movement pass

Movement was fixed structurally in h11 (`MOVE_Walking` reached, gravity integrates, volume-scale
bug repaired — README "Movement — PASS"). This is a *feel* audit against BioShock 1, done in
interactive PIE, not just the headless displacement check.

Current config (`ShockPlayer.cpp` ~line 135): `MaxWalkSpeed = 450`, `JumpZVelocity = 525`.
Pull BioShock 1's real values from `tmp/uc_shockgame/` (`ShockPlayer`/`Pawn`/`PlayerMovement` UC:
`GroundSpeed`, `WalkingPct`, `JumpZ`, `AccelRate`, `AirControl`, crouch speed/height,
`MaxStepHeight`, `bCanCrouch`, ladder/mantle if present) and reconcile. Check specifically:
- Walk/run speed; whether BioShock has a run vs walk distinction or one speed.
- Acceleration / friction / braking — BioShock movement is snappy, not floaty; UE defaults feel
  mushy. Set `MaxAcceleration`, `BrakingDecelerationWalking`, `GroundFriction`.
- Air control + `FallingLateralFriction` — jump arcs.
- `MaxStepHeight` / `SetWalkableFloorAngle` — Medical has raised thresholds and rubble; step
  over small stuff without jumping.
- Crouch: height, speed, whether it's bound at all.
- Mouse look: sensitivity, any smoothing/acceleration that shouldn't be there, pitch clamp.
- Camera / eye height vs the capsule while moving and crouched (there's a note ~line 1528 about
  the camera walking up into the ceiling).
- Landing: hard stop, camera dip, fall-damage threshold (BioShock has fall damage).

---

## 1. Outside geo → no collision

Exterior/backdrop meshes visible through Medical's windows (the Rapture cityscape skybox, the
ocean-floor kelp, the "…_Outside" counter props dressing the view outside the glass) currently
block the player and block weapon/AI traces. They should be render-only.

- Find a robust way to identify "outside" geometry. Name patterns are a start (`*_Outside*`,
  `skybox*`, `Kelp*`/`kelp*`, `seabed*`, `*cityscape*`, `*_ext_*`, `ocean*`). Better: the source
  level almost certainly zones these (a decoration group with no `bWorldGeometry`, an "exterior"
  region, or placement outside every `BlockingVolume` / nav bound). Check the export
  (`1-Medical.ue5-level.json`), `dotnet run --project src/BioShockStudio.Cli -c Release -- properties 1-Medical <Actor>`,
  and `docs/research/interaction.md` / any zone docs. Decide and document the rule; don't ship
  a bare hand-list.
- New `tools/ue5/fix_exterior_collision.py` (idempotent, dry-run env flag like the other `fix_*`
  scripts) that sets `collision_enabled = NO_COLLISION` on the matched actors and saves the
  slice map. Wire it into `setup_playable_slice.py` `STEPS`.
- Don't sweep in interior geo that merely shares a word — there is a `Gen_Counter_90` interior
  variant; only `_Outside` / `_Wide_Outside` are exterior.

---

## 2. Props → complex collision

The ~3625 single-convex-hull props need collision that matches their real shape.

**The tension you must resolve** (read `ShockGameMode.cpp` ~lines 100-130 and the h11/h19 task
files first): `CTF_USE_COMPLEX_AS_SIMPLE` is only valid for **Static** mobility in Chaos. This
project imports every prop as **Movable** because there are no baked lightmaps — a Static mesh
with no lightmap renders black in `-game`. So the compiled-world shell's route (flip Static +
complex-as-simple) is exactly what you must NOT blanket-apply to props, or the slice goes dark.

Options to weigh and pick per prop-class (document the decision):
- **Multi-convex decomposition** on the mesh asset (Auto Convex Collision with a high hull
  count / the `unreal` convex-decomposition API) — accurate enough for a hollow cabinet or a
  bent pipe, works on **Movable**. Likely the right default for movable props.
- **`CTF_USE_COMPLEX_AS_SIMPLE`** only for large static walk-through architecture already Static
  or safe to make Static (pillars, wall sections, `ConcreteWall_Hole_*`, stairs) — extend
  `fix_walkable_prop_collision.py`'s size+keyword gate, don't do all 3625.
- Leave genuinely small/simple props (ammo pickups, bottles, tiles) on their single hull — a
  hull is correct and cheap there (see `verify_collision.py` docstring).
- Pickups (`Ammo_Pickup_*`, `*_Pickup_*`) may want `NO_COLLISION` / overlap-only, not a tighter
  blocking hull — check the pickup interaction before tightening them.
- Watch perf: per-poly collision on thousands of props is not free — state the trade.

Deliver `tools/ue5/fix_prop_collision.py` (or extend an existing `fix_*`) that classifies and
applies, idempotent + dry-run, wired into the slice setup. Update `verify_collision.py` so its
pass/fail reflects the new policy (no false alarms on intentionally-simple props; real alarms if
an exterior mesh still blocks or a walk-through arch piece is still a blob).

---

## God rays

BioShock's god rays are **additive translucent `LightBeamShader` static meshes**, not a UE
volumetric-light-shaft feature. In the slice they are currently **invisible**: `LightBeamShader`
exports with no BaseColor, and `import_bioshock._default_base_color_texture` correctly black-fills
additive masters (black = additive identity), so an old blown-out white wedge became nothing
(see `import_bioshock.py` ~line 467, `repair_placeholder_base_colours.py`).

Actors in the slice: `Light_Beam_01_12861`, `Light_Beams_Science_Yellow_28345`,
`Orange_Beams_12772`, `light_beam_02_7384`, `StaticMesh_Light_Beams_4400`, plus
`WallTechAnim_ShaftB` (a panned scrolling shaft) and `BioshockGlowSettings` / `GlowSettings`.

- Work out what `LightBeamShader` should sample: a soft edge-falloff gradient / the beam's own
  dust texture from the bulk catalog, panned or static, tinted per-instance (yellow / orange).
  Check `MaterialExporter` for whether the real texture is in the package and just wasn't bound,
  or whether it needs a generated radial/linear falloff.
- Bind it via the material pipeline (`src/**` `MaterialExporter` if that's where the miss is —
  note the lane is `tools/ue5` here, so prefer a `tools/ue5/repair_light_beams.py` that authors
  the additive beam material and assigns it to the `LightBeamShader` slots). Additive, depth-fade
  at the near plane so the beam doesn't hard-edge against geometry, subtle intensity — reference
  photos of Medical Pavilion: soft shafts from the skylights, not solid cones.
- `BioshockGlowSettings` — check if it carries bloom/glow params the beams (and neon signs)
  depend on; wire into a PostProcessVolume if so.
- Optional, only if cheap and it reads better: enable `bEnableLightShaftBloom` on the level's
  key directional/skylight.

---

## Deliverable

- `docs/research/collision.md` — exterior-identification rule; per-prop-class collision policy
  and why (Movable/lightmap/Chaos constraint front and centre); perf note.
- `docs/research/god-rays.md` — what `LightBeamShader` is, why the beams were invisible, what
  the material now does, per-instance tinting.
- `docs/research/movement.md` — BioShock 1's movement constants (sourced from UC), what this
  project was set to, what changed and why; rig-dependent items (mantle, ladders) called out as
  out-of-scope.
- `ShockGameMode.cpp` — debug encounter gated to verify-only; spawn floor-snap added.
- `ShockPlayer.cpp` — movement constants updated.
- `fix_exterior_collision.py` + `fix_prop_collision.py` + `repair_light_beams.py`, idempotent +
  dry-run, wired into `setup_playable_slice.py`.
- Headless, all green:
  - `run_game_movement.py` / `verify_game_movement.py` → `BIOSHOCK_MOVEMENT_OK`, `MOVE_Walking`
    start and end.
  - `verify_collision.py` → 0 errors under the new policy.
  - flagged exterior actors are `NO_COLLISION`; a sample hollow prop now has >1 collision
    primitive (or complex).
  - `LightBeamShader` slots resolve to a non-null, non-black material.
  - `-bioshockverifyencounter` still passes (enemies spawn under the verify param,
    floor-snapped); a **plain** spawn (no verify param) produces zero `ABaseShockAI`.
- `-game` captures (`tools/ue5/capture_shot.ps1 -Extra @('-bioshockstartslot=1')`, a few settle
  values): a plain spawn with no splicers falling through the floor; a window view with the
  god-ray shafts visible from the skylights.

## Constraints

- `tools/ue5/**` + `docs/research/**` + `tmp/**` only. Editor CLOSED for headless
  `UnrealEditor-Cmd` / `rebuild_runtime_fast.ps1` (`tasklist //FI "IMAGENAME eq UnrealEditor.exe"`
  → 0). Kill stray `UnrealEditor-Cmd` / `dotnet` / `BioShockStudio.Cli` between runs.
- `-run=pythonscript` swallows `unreal.log` — write results to JSON.
- MSYS: forward-slash Windows paths + `export MSYS_NO_PATHCONV=1`.
- Do NOT touch the h11 Static compiled-world-shell mobility or its collision (README "Checked
  first — h11 Static compiled-world shell"). Do NOT blanket-flip props Movable↔Static to "fix"
  anything — that's the h11↔h19 regression trap. If a prop must be Static for its collision,
  say so and note the lighting cost.
- Do NOT commit. No `docs/HANDOFF.md` claim row. Leave the diff for review; a human does the
  final visual + PIE QC in the editor.
- Read the reference projects (`external/UModel-master/`, `external/Unreal-Library-master/`, `tmp/uc_shockgame/`,
  gitignored at repo root) before deriving anything from bytes.
