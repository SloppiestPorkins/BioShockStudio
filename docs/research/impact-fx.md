# Gun impact FX

Status: runtime implemented 8 Sep 2026; structural headless verification passed. The concrete
wall `-game` burst path ran and was inspected. Recovered BioShock particle/decal assets remain
`UNKNOWN`; the runtime therefore has explicit stand-ins and stable final asset paths.

## Evidence and limits

- `CONFIRMED_BYTES`: `docs/research/audio.md` records `bullet_hit` alternatives keyed by
  `Material.EMaterialVisualType`: default/concrete, thin/thick metal, wood, glass, water, dirt,
  and the other 28 enum values.
- `CONFIRMED_BYTES`: `docs/research/interaction.md` records `MachineGun_MuzzleFX`,
  `DynamicLight_MuzzleMG`, `MG_ShellEject`, and three `MG_Tracer` entries. Pistol declares
  `Pistol_MuzzleFX` plus `DynamicLightMuzzleFlash` and no tracer entry.
- The decompiled `*Impact*.uc`, `AmmoType*.uc`, `SurfaceType*.uc`, and `DecalManager` sources
  named in the task are not present in this isolated worktree or its available reference checkout.
  Consequently no decal dimension or lifetime is claimed as shipped data. The values below are
  labelled runtime stand-ins, not reconstructed UC values.
- Imported level materials still do not carry the MVT byte into UE physical materials. Runtime
  resolution therefore prefers `FHitResult.PhysMaterial`, then the hit face's material, then
  component/actor names, and defaults to concrete. This is the same documented approximation as
  footstep surface selection.

## Surface table

All particle and decal paths are under `/Game/BioShockFX/Impacts/`. A recovered Cascade asset at
the named path is used automatically. Until those assets exist, a registered
`UParticleSystemComponent` plus a short debug-rendered debris puff/spark fan/splash is used.
Missing decal art falls back to UE's deferred-decal material.

| Resolved surface | Name evidence | Decal path | Particle path | Sound cue | Size / life |
|---|---|---|---|---|---|
| Concrete | concrete, stone, plaster, tile, marble, or fallback | `M_BulletHole_Concrete` | `P_Impact_Concrete` | `bullet_hit__MVT_Concrete` | 5.5 uu / 20 s, `STAND-IN` |
| Metal | metal, steel, iron, grate, rail | `M_BulletHole_Metal` | `P_Impact_MetalSparks` | `bullet_hit__MVT_ThickMetal` | 5.5 uu / 20 s, `STAND-IN` |
| Wood | wood, timber, plank | `M_BulletHole_Wood` | `P_Impact_WoodSplinters` | `bullet_hit__MVT_Wood` | 6 uu / 20 s, `STAND-IN` |
| Glass | glass, window | `M_BulletHole_Glass` | `P_Impact_GlassShatter` | `bullet_hit__MVT_ThinGlass` | 7 uu / 15 s, `STAND-IN` |
| Water | water, liquid | none | `P_Impact_WaterSplash` | `bullet_hit__MVT_Water` | no solid decal |
| Dirt | dirt, mud, soil, earth | `M_BulletHole_Dirt` | `P_Impact_Dirt` | `bullet_hit__MVT_Dirt` | 6.5 uu / 18 s, `STAND-IN` |
| Beam | resolved surface still selects sound | `M_BeamScorch` | `P_BeamScorch` | surface cue above | 9 uu / 45 s, `STAND-IN` |

`import_audio.py` now creates `bullet_hit__MVT_*` derivatives from the already-exported
`surfaceType` field, just as it does for footsteps. This is required because the unsplit
`bullet_hit` cue has 78 alternatives and cannot preserve surface selection. Impact one-shots use
their own audio-component slot; they never overwrite the Tommy gun's held-fire component.

Hitscan and beam traces include pawn, world-static, and world-dynamic objects and request physical
material plus collision face index. Shotgun uses the same route per pellet but caps spawned world
impacts at four per shell. A beam repositions/reuses a nearby scorch decal and throttles impact
sound to 0.35 s while keeping its end effect active.

## Weapon side

- Every accepted ballistic shot retriggers a 0.04 s, 12,000-intensity muzzle light and a muzzle
  `UParticleSystemComponent`. Paths are `Pistol_MuzzleFX`, `MachineGun_MuzzleFX`, and
  `Shotgun_MuzzleFX` under `/Game/BioShockFX/Weapons/`; a bright-point stand-in is used when absent.
- Hitscan and shotgun weapons eject a short-lived physics cylinder from `shelleject`,
  `ShellEject`, or `SG_Shell`, falling back to the muzzle. `MG_ShellEject` is confirmed in the
  source table; pistol/shotgun cylinders are `STAND-IN`.
- Automatic hitscan emits a small smoke component every sixth round. Its final stand-in path is
  `/Game/BioShockFX/Weapons/P_AutomaticSmoke`.
- `CONFIRMED_BYTES` says the Tommy gun has tracers while Pistol has none, but the available decode
  exposes no cadence field. Runtime uses one Tommy tracer every third round (`APPROXIMATION`) rather
  than the old every-round solid streak.

## Verification

`verify_impact_fx.py` fires a ballistic shot for muzzle/eject setup, then simulates the post-trace
wall result because collision cooking is unavailable in the empty commandlet editor world. It
requires a decal component, impact particle component, sound dispatch, and distinct metal/concrete
profiles. Measured result: three decals, three FX components, three sound dispatches, one muzzle
component, one casing, a loaded concrete impact cue, and zero failures. `audioComponent` remains
false under Null RHI because that mode disables the audio device; the test separately requires the
real generated `USoundCue` asset and the runtime dispatch counter rather than misreporting Null RHI
as audible playback.

The real `-game` capture ran:

```powershell
& tools/ue5/capture_shot.ps1 -Out "$env:TEMP/impact_wall.png" -SettleTicks 12 `
  -FireAtWall -Extra @('-bioshockstartslot=2')
```

The log contains five concrete `BIOSHOCK_IMPACT` events with `soundcomponent=1` and five Tommy fire
lines, each with `loop=1 component=1`; the muzzle flash is visible in the inspected frame, so the
looped-audio fix did not stop per-shot visual retriggering. The impact point is behind the
viewmodel/airlock wheel, so this frame does **not** prove decal appearance. Dedicated metal-railing
and water framing coordinates are not known in this checkout; those two requested look checks
remain human Play verification rather than fabricated captures.

Every impact emits:

```text
BIOSHOCK_IMPACT surface=<x> decal=<asset> fx=<asset> sound=<event>
```

`capture_shot.ps1 -FireAtWall` fires on each of the final five capture ticks. It can be combined
with existing `-bioshockshotabs` / `-bioshockshotlook` arguments once a railing or water location
is selected in Play.
