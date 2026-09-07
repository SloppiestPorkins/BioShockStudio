# In-level water surfaces and underwater look

**Status.** UE5 presentation slice — `APPROXIMATION` of BioShock's flooded-room look, not a
byte-accurate port of `FluidShader` / `FluidSurfaceShader`. Ocean-beyond-the-glass / skybox
water is out of scope (separate backdrop task).

## Medical census (1-Medical.ue5-level.json)

| Class | Count | Shape |
|---|---|---|
| `CascadingWaterVolume` | 14 | Tall/narrow AABB (waterfall shafts) |
| `FluidVolume` | 13 | Wide/shallow AABB (pools / flooded floors) |
| `TunnelCollapseWaterVolume` | 0 in this slice export | Same treatment when present |
| `WaterSplash_Small` | 18 | Ambient drip markers (location only) |

Example pool: `FluidVolume5` center ≈ `(-24568, -4304, 7588)`, half-extent `(648, 560, 36)`.
Example cascade: `CascadingWaterVolume3` half-extent `(19, 88, 256.5)`.

## What was wrong

`import_level` spawned water volumes as `PhysicsVolume` and hid the brush
(`_hide_volume_in_game`) because Unreal draws volume brushes **green** in `-game` captures.
Result: correct overlap regions, **no visible water**.

`AShockWaterVolume` already existed as logic-only (Electro Bolt water chain via
`IsActorInWater`). It had no render component.

## Material recipe (`tools/ue5/author_water_material.py`)

Authored under `/Game/BioShock/Water/` (no binary `.uasset` in git):

| Asset | Role |
|---|---|
| `T_ShockWater_Normal` | Procedural 256² sine-ripple normal (PNG staged under `%TEMP%/bioshock-water`; import once in editor if missing — headless AssetImportTask trips Slate) |
| `M_ShockWater` | Translucent default-lit master |
| `MI_ShockWater_Cascading` | Faster pan / stronger normal / greener tint |

**Master graph (cheap, whole-level):**

- `WaterColor` vector ≈ `(0.08, 0.32, 0.34)` — deco-era blue-green
- Panned `RippleNormal` (`PanSpeed` × Time offset on UVs)
- `NormalStrength` lerp toward flat `(0,0,1)`
- Opacity = `OpacityScale` × `(0.25 + Fresnel)` × `DepthFade(DepthFadeDistance)`
- Low `Roughness` (~0.12), two-sided translucent

Cascading MI overrides: `PanSpeed=0.18`, `NormalStrength=1.0`, `OpacityScale=0.55`, greener
`WaterColor`.

## Surface placement

`AShockWaterVolume` owns:

- `Volume` — `UBoxComponent`, query-only, **hidden** (overlap / `IsActorInWater`)
- `Surface` — `UStaticMeshComponent` on `/Engine/BasicShapes/Plane`, **visible**, no collision

`ConfigureFromHalfExtent(HalfExtent, bCascading)`:

1. Sets the box extent.
2. Places the plane on the **top face** (`relative Z = extent.Z`), scaled to XY
   (`scale = extent / 50` because the engine plane is 100 uu).
3. Assigns `M_ShockWater` or `MI_ShockWater_Cascading`.

`import_level._import_region_volumes` now resolves water classes to `ShockWaterVolume`, calls
`author_water_material.ensure_water_materials`, then `ConfigureFromHalfExtent`. Brush hide still
runs but skips the `Surface` component.

`repair_water_surfaces.py` converts already-imported `PhysicsVolume` water actors on a saved map
without a full re-import.

## Underwater post-process

Gated in `AShockPlayer::Tick` → `TickUnderwaterPostProcess`:

- Target blend = `IsActorInWater(this) ? 1 : 0`
- `FInterpConstantTo` over **0.3 s** (no pop)
- On `FirstPersonCamera` post-process (blend weight stays 1 so manual EV=11 is preserved):
  - blue-green `SceneColorTint`
  - slight desaturation / contrast shift
  - bloom + vignette (murk stand-in for exponential fog)
  - `SceneFringeIntensity` chromatic edge
  - soft DOF blur

**Out of scope / approximated:** muffled audio; true exponential height fog / far-clip change;
shipped BioShock underwater LUT; swimming movement.

## Splashes

`WaterSplash_Small` (18 markers) — **deferred**. Lowest priority; 1–3 (material, surface,
underwater PP) land first. Ambient drip decals/particles can hook the marker `location` field
later.

## Verify

```text
tools/ue5/verify_water.py
```

Headless checks: materials exist, still + cascading surfaces visible with materials,
`IsInWaterForVerify` inside/outside, underwater blend fades in/out over ~0.3 s.

Visual confirmation (human): `-game` / `capture_shot.ps1` looking across a flooded Medical room
and standing inside a `FluidVolume` with the grade active.

## Confidence

| Claim | Label |
|---|---|
| Medical water volume counts / AABB placement from brush OBJ | `CONFIRMED_BYTES` (manifest) |
| Green brush was the prior `-game` failure mode | `CONFIRMED` (prior capture) |
| Surface/PP look matches shipped BioShock | `APPROXIMATION` |
| Procedural ripple normal ≈ game fluid normals | `APPROXIMATION` |
