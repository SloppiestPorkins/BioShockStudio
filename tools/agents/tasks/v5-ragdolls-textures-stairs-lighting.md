---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**, tmp/**
---

# Ragdolls, awful textures, un-walkable stairs, and blown-out lighting

User reports (7 Sept 2026, interactive PIE test of `/Game/BioShockSlice/1-Medical`, after v4
landed at `7ab882d` / door fix `55ef637`):
1. "ragdolls aren't working" — dead enemies don't ragdoll.
2. "certain textures are awful compared to what they should be" — texture-quality regression on
   some surfaces.
3. "collision is messed up as i cant walk up the stairs in front of the medical pavilion sign".
4. "light is SUPER bright".

Do 3 and 4 first — both are quick, and 4 is already fully diagnosed. Then 1, then 2.

---

## 3. Stairs are un-walkable — a v4 regression, root cause known

v4's `fix_prop_collision.py` put `stairs_3461`, `stairs_open_3473`, `railing_stairs_open_3512`,
`FX_StairWater_C_5312` (and anything matching `_ARCHITECTURE = stairs?|ramp|walkway|catwalk|…`
with `largest >= 200`) into the `static_complex_proxy` bucket: it clears the mesh's convex hull,
sets `CTF_USE_COMPLEX_AS_SIMPLE`, disables collision on the visible render actor, and spawns an
invisible Static per-poly proxy.

**A single convex hull over a staircase is a smooth walkable wedge — exactly what you want.**
Per-poly collision on the same mesh makes the character-movement step-up logic catch on every
riser / on the open gaps between treads, so the player can't climb. v4 made stairs *worse*.

Fix `fix_prop_collision.py`:
- Remove `stairs?`, `ramp`, `walkway`, `catwalk`, `bridge`, `platform` from the proxy trigger.
  Stairs/ramps must keep (or be given back) a **simple convex hull** — walkable wedge, not
  per-poly. If a mesh already had its hull cleared by an earlier v4 run, regenerate one
  (`unreal` simple-collision / `KDOP` box or a single convex from the render mesh) or restore
  `CTF_USE_DEFAULT` with a rebuilt hull.
- Keep the complex-proxy route only for genuinely hollow/concave *enclosing* geometry (cabinet,
  shelving, wall-with-hole, tunnel interiors) where a hull would seal the opening.
- Add a `verify_collision.py` check that a known staircase mesh is walkable: either it has
  `convex/box` simple collision and `CTF_USE_DEFAULT`, or (better) a `-game` walk test that
  drives the player up the Medical Pavilion sign stairs and asserts Z increased.
- Re-run `fix_prop_collision` on the slice and re-save; confirm the stairs render actors have
  collision back.

Also sanity-check the new movement values from v4 (`ShockPlayer.cpp`: `MaxStepHeight = 35`,
`SetWalkableFloorAngle(44)`): if the Medical stairs have risers taller than 35uu or a pitch
steeper than 44°, bump these. Measure the actual stair mesh, don't guess.

---

## 4. Lighting is blown out — `repair_level_lighting.py` never ran on the slice

`repair_level_lighting.py` already exists and its docstring has the full diagnosis:

> import_level turns inverse-square OFF so authored `LightBrightness` stays a scale; in that mode
> UE5 shapes reach with `pow(saturate(1 - d/radius), exponent)` and **the exponent defaults to 8**.
> Across all 664 lights that put 10% brightness at ~1 m in 3–5 m corridors: blown-out white
> within arm's reach of each bulb, near-black elsewhere. "god rays super bright and just white"
> and "walls dark" are the same one number. Exponent near 2 is the curve UE2.5 approximated.

The problem: this script defaults `BIOSHOCK_LIGHT_MAP = /Game/BioShockLevel/1-Medical` (the
**non-slice** map) and **is not in `setup_playable_slice.py` STEPS**. The playable slice never
got it — it's running raw exponent-8 lights, now with v4's newly-visible additive god-ray meshes
on top.

- Wire `repair_level_lighting` into `setup_playable_slice.py` STEPS (after the collision/beam
  steps, before doors), parameterised for `/Game/BioShockSlice/1-Medical`.
- Run it on the slice: light-falloff exponent → ~2, intensity rescale + clamp, SkyLight ambient,
  pinned exposure via an unbound `PostProcessVolume`. Tune `BIOSHOCK_LIGHT_FALLOFF` /
  `_FACTOR` / `_EV` by looking at captures — Rapture reads on light/shadow contrast, so a dim
  ambient + bright practicals, not a uniform lift.
- Check the v4 god-ray `BeamIntensity` (0.8) against the corrected lighting — it may want
  lowering once the point lights aren't blowing out.
- `-game` captures before/after from the bathysphere spawn and the Pavilion.

---

## 1. Ragdolls

`ABaseShockAI::OnDeathFromDamage` (`BaseShockAI.cpp` ~696) plays an `AnimDeath` clip then fades
the corpse — **there is no physics ragdoll anywhere**. `SetSimulatePhysics` / a "Ragdoll"
collision profile / `SetAllBodiesSimulatePhysics` appear nowhere in the runtime. `ApplyCombatSkeletalMesh`
also explicitly `SetCollisionEnabled(NoCollision)` on the body mesh.

BioShock 1 ragdolls on death (Havok). Build it:
- The AI character skeletal meshes almost certainly have no `PhysicsAsset` (the door rig didn't;
  see `LoadRoomDoorAnim_PhysicsAsset` missing note). Generate one per combat rig headless
  (`unreal` physics-asset creation from the skeleton, capsule bodies per bone, sensible
  constraints) as an import/repair step, or at minimum for `Agg_BabyJane` / `ThuggishSplicer` /
  `LeadheadSplicer`.
- On death: switch the body mesh to its physics asset, set collision to a ragdoll profile
  (block WorldStatic, ignore Pawn/Camera), `SetAllBodiesSimulatePhysics(true)` +
  `WakeAllRigidBodies`, detach from the capsule (or shrink/disable the capsule as it already
  does), and apply an impulse along the killing hit direction/impact bone so they fall away from
  the shot. Blend from the current pose (`SetAllBodiesBelowPhysicsBlendWeight` ramp) rather than
  snapping.
- Keep `CorpseFadeSeconds` behaviour (fade/sink the settled ragdoll), but let it settle first.
- Gate cleanly so the headless encounter/possess verifies still pass (they check health/target,
  not physics) and a dead AI still reports dead.
- `docs/research/ragdoll.md` — what physics assets exist/were generated, the death→sim flow,
  impulse sourcing, what's approximated.

---

## 2. Awful textures

This one is under-specified — the user hasn't named the surfaces yet. Do a census pass and fix
the clear offenders; leave a list for the user to point at the rest.

- `verify`/scan the slice's materials for: slot 0 resolving to an engine stub / `WorldGrid` /
  `DefaultDiffuse` / a 4×4 placeholder, a mip-stripped texture showing only its top mip
  (`StrippedNumMips > 0` with the bulk mips not applied — `BulkTextureCatalog`,
  `recover_stripped_textures.py`), sRGB/linear mismatch (albedo looking washed or crushed),
  a normal map bound as base colour or vice-versa, `repair_placeholder_base_colours.py`
  candidates that got the wrong default.
- Cross-check against `ContentBaked/pc/BulkContent` — a texture with a real high-res source that
  isn't being used is the most likely "awful compared to what it should be".
- Fix the mechanism (in `src/**` `MaterialExporter` / `BulkTextureCatalog` if that's the miss —
  note the lane is `tools/ue5` so prefer a `tools/ue5/recover_*` / `repair_*` script) and
  re-import/re-apply for the slice.
- `docs/research/` note listing every surface changed and every remaining suspect, so the user
  can confirm which ones they meant.

---

## Deliverable

- `fix_prop_collision.py` fixed (stairs/ramps keep a walkable hull); re-run on the slice.
- `repair_level_lighting.py` wired into `setup_playable_slice.py` and run on the slice.
- Ragdoll on death in `BaseShockAI.cpp` + physics-asset generation step; `docs/research/ragdoll.md`.
- Texture census + fixes for clear offenders; `docs/research/` note with the remaining list.
- Headless, all green: `verify_collision.py` (+ new stair-walkability check), `run_game_movement`
  (`MOVE_Walking`), `verify_light_beams` (14/14), `run_encounter` under the verify param,
  plain-spawn `BIOSHOCK_SCREENSHOT_AI count=0`.
- `-game` captures: player climbing the Pavilion-sign stairs (Z increases); the Pavilion with
  corrected lighting (before/after); an enemy killed and ragdolling.

## Constraints

- `tools/ue5/**` + `docs/research/**` + `tmp/**` only. Editor CLOSED for headless
  `UnrealEditor-Cmd` / `rebuild_runtime_fast.ps1` (`tasklist //FI "IMAGENAME eq UnrealEditor.exe"`
  → 0). Kill stray `UnrealEditor-Cmd` / `dotnet` / `BioShockStudio.Cli` between runs.
- `-run=pythonscript` swallows `unreal.log` — write results to JSON.
- MSYS: forward-slash Windows paths + `export MSYS_NO_PATHCONV=1`.
- Do NOT touch the h11 Static compiled-world-shell mobility/collision, and do NOT re-introduce
  the h11↔h19 Movable↔Static trap for props.
- Do NOT commit. No `docs/HANDOFF.md` claim row. Leave the diff for review; a human does the
  final PIE + visual QC.
- Read `tmp/uc_shockgame/` (Havok death / `TakeDamage` / `PlayDying`), `UModel-master/`,
  `Unreal-Library-master/` (all gitignored at repo root) before deriving behaviour from bytes.
