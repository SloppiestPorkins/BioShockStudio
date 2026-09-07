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

## 3. Prop collision — the invisible wall is fixed; make the fidelity pass actually good

UPDATE (`3288d5c`): the "huge invisible wall at the top of the Medical Pavilion sign stairs"
was one of v4's **invisible Static proxies** (`fix_prop_collision._sync_proxy` spawned an
invisible complex-as-simple collider beside each proxied prop and disabled the render actor's
collision — a mis-placed/duplicated one blocked the stairs). That scheme is **already reverted**:
all 580 proxies destroyed, `fix_prop_collision` removed from `setup_playable_slice` STEPS,
`verify_collision.py` back to its pre-v4 form. The 71 formerly-proxied meshes now carry
`CTF_USE_COMPLEX_AS_SIMPLE` **directly on the visible render mesh** (Movable — fine for
query/sweep) via `undo_prop_collision_proxies.py`. `run_game_movement` is green again.

So the interim state is: you collide with exactly what you see, no invisible geometry. Your job
is to turn `fix_prop_collision.py` into something worth wiring back in:
- Per-poly (`CTF_USE_COMPLEX_AS_SIMPLE`) is right for a couch or a pipe, and acceptable for a
  proper open tunnel/archway tube. It is **wrong** for anything the movement step-up logic has
  to climb (`stairs*`, `ramp`, `Broken_Stairs`) — a single convex hull there is a smooth
  walkable wedge; per-poly catches on every riser. And it is wrong for a mesh with interior
  caps / back-faces that seal a space.
- UE5.7's headless Auto Convex / `set_convex_decomposition_collision` / `add_simple_collisions`
  all silently produce **zero** geometry in `-run=pythonscript` (confirmed this session and by
  v4). If you need generated hulls, they have to come from an **in-editor** pass (the editor
  UI's "Auto Convex Collision" works) scripted through the editor, or from re-importing the OBJ
  (auto-collision regenerates on import). Work out which is reproducible and document it.
- Rebuild the classifier: stairs/ramps → simple hull (regen via re-import if needed);
  hollow/concave enclosing props → per-poly on the render mesh (no proxy); small/simple props →
  keep their single hull; walk-through tubes → per-poly is OK but **walk-test them**.
- `verify_collision.py`: add a `-game` check that drives the player up the Medical Pavilion sign
  stairs and asserts Z increased, and one that walks the bathysphere→Pavilion path without
  entering `MOVE_Falling`.

Also sanity-check v4's movement values (`ShockPlayer.cpp`: `MaxStepHeight = 35`,
`SetWalkableFloorAngle(44)`) against the real Medical stair mesh — measure riser height / pitch,
bump if needed.

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

## 1. Ragdolls + world physics

`ABaseShockAI::OnDeathFromDamage` (`BaseShockAI.cpp` ~696) plays an `AnimDeath` clip then fades
the corpse — **there is no physics ragdoll anywhere**. `SetSimulatePhysics` / a "Ragdoll"
collision profile / `SetAllBodiesSimulatePhysics` appear nowhere in the runtime. `ApplyCombatSkeletalMesh`
also explicitly `SetCollisionEnabled(NoCollision)` on the body mesh.

The user wants **three** things physics-driven, not just the one:
  a. **AI death → ragdoll** (Havok in the original).
  b. **Pre-placed dead bodies** that aren't AI-driven — corpses dressed into the level (Medical
     has several). Find how they're placed (`Corpse*` / `DeadBody*` / `Body*` actor classes or
     skeletal-mesh actors in `1-Medical.ue5-level.json`); they should spawn as settled ragdolls
     (or at least physics-enabled skeletal meshes that react to being shot / walked into), not
     frozen T-pose / frozen-anim props.
  c. **Props with physics** — the small dynamic clutter BioShock lets you knock around (bottles,
     cans, trays, chairs, debris, trash). Identify the movable-prop classes / meshes, give them
     `Simulate Physics` + a simple collision + mass, so shooting or bumping them moves them.
     Don't make heavy furniture or fixtures dynamic — pick the set deliberately and document it.

For all three:
- The skeletal meshes almost certainly have no `PhysicsAsset` (the door rig didn't — see the
  `LoadRoomDoorAnim_PhysicsAsset` missing note). Generate one per combat rig + per corpse rig
  (`unreal` physics-asset creation from the skeleton, capsule bodies per bone, sensible
  constraints) as an import/repair step. As with §3's collision gen, if the headless API won't
  cook them, do it via an in-editor scripted pass or on re-import — work out what's reproducible.
- AI death: switch the body mesh to its physics asset, ragdoll collision profile (block
  WorldStatic, ignore Pawn/Camera), `SetAllBodiesSimulatePhysics(true)` + `WakeAllRigidBodies`,
  disable/shrink the capsule (it already does), apply an impulse along the killing hit
  direction/impact bone. Blend from the death pose (`SetAllBodiesBelowPhysicsBlendWeight` ramp),
  don't snap. Keep `CorpseFadeSeconds` but let it settle first.
- Gate cleanly so the headless encounter/possess verifies still pass (they check health/target,
  not physics) and a dead AI still reports dead.
- `docs/research/ragdoll.md` — physics assets generated, the death→sim flow, impulse sourcing,
  the pre-placed-corpse path, the dynamic-prop set and why, what's approximated.

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
