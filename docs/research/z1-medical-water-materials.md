# Medical water materials from decoded `FluidShader` data

**Status:** `CONFIRMED_BYTES` for the manifest relationships and decoded values; `APPROXIMATION`
for interpreting raw `UPan`/`VPan` as UE material-time UV rates. Scope is only `1-Medical`.

## The relationship that actually exists

The requested direct `FluidVolume -> FluidShader` reference does **not** exist in the current v4
Medical manifest. A census of all 27 `FluidVolume` / `CascadingWaterVolume` actors found an empty
`materialOverrides` array on every actor. Their brush assets have geometry-only sections with no
`materialKey`. `FluidVolume5` is a representative complete chain: actor -> `Model788`, empty
overrides, and a one-section brush with no material identity
(`C:/Users/Jack/Documents/BioShockUE5/Exports/slice/1-Medical/1-Medical.ue5-level.json:252979`,
`:253035`, `:253046`, `:27793`, `:71757`). Associating one of the 19 shaders to those volumes by
distance would therefore be a new heuristic, not decoded data, and was not done.

The confirmed render-surface relationship is the same one used by ordinary static meshes:

`materials[].key <- assets[].sections[].materialKey <- instances[].asset + actorKey -> actors[].key`

For example, `puddle_alt` section 0 names `FluidShader_WaterSpreadA_31858`, and five instances name
that asset; the first is `StaticMeshActor4907`
(`1-Medical.ue5-level.json:31630`, `:31636`, `:31640`, `:75285`). `FX_StairWater_C` demonstrates
that section identity matters: its first section uses `StairPour_Shader` and its second uses
`StairSpreadA` (`1-Medical.ue5-level.json:57574`, `:57580`, `:57585`, `:57594`); its first placed
instance is `StaticMeshActor2912` (`:106917`).

This chain covers 113 distinct manifest instances and all 19 FluidShaders. Twenty of those are
source CSG `Brush` instances which `import_level` intentionally omits; their water sections are
already represented in the single `BuiltWorld` instance. The remaining water meshes plus
`BuiltWorld` are the actual saved render surfaces.

## The 19 materials and decoded inputs

Panner shorthand is `role=(UPan, VPan; PanTime)`. A dash means the property is absent, not zero.
`D1/D2` are `DiffuseTextureAnimator1/2`; `N1/N2` are `NormalTextureAnimator1/2`. Texture paths and
values below are copied from the manifest, not inferred.

| Material (manifest line) | Diffuse / normal | Decoded diffuse + normal panners |
|---|---|---|
| `WaterSpreadA` (:597) | `waterspread2.png` / `waterspreadNORM.png` | D1/N1 `(-0.25, 0.15; 0.87)`; D2/N2 `(-0.2, -0.1; 1.13)` |
| `CalmwaterCube_Midref` (:843) | none / `CalmWater_Normal.png` | N1 `(14, 5; 300)`; N2 `(-14, -5; 320)` |
| `LongPuddleDrippy` (:1754) | none / none | N1 `(-0.01, -0.01; -)`; N2 `(0.01, 0.012; 0.9)` |
| `WaterCascadeA_Shader` (:2381) | `watercascade.png` / `watercascadeNORM.png` | D1/N1 `(-1, -22; 12)`; D2/N2 `(-, -20; 11.3)` |
| `WaterSpewA` (:2557) | `waterspewDIF.png` / `waterspewNORM.png` | D1/N1 `(-0.4, -2; -)`; D2/N2 `(0.3, -3; -)` |
| `RoughWaterLowRefCube_Shader` (:3333) | none / `roughwater.png` | N1 `(14, 5; 100)`; N2 `(-14, -5; 100)` |
| `RoundPuddleDrippy` (:4104) | none / none | N1 `(-0.01, -0.01; -)`; N2 `(0.01, 0.012; 0.9)` |
| `StairPour_Shader` (:4975) | `StairWater_Diffuse_O.png` / `StairWater_Normal_S.png` | D1/D2/N1/N2 `(0, -1; -)` |
| `StairSpreadA` (:5032) | none / `waterspread.png` | N1 `(0, -0.25; 0.5)`; N2 `(-0.05, -0.3; 0.5)` |
| `FloorFlowA_Shader` (:5729) | none / `waterspread.png` | N1 `(-0.1, -0.1; -)`; N2 `(0.05, -0.15; -)` |
| `WindowSpew_Shader` (:7085) | `WindowSpew_O.png` / `WindowSpew_Normal.png` | D1/N1 `(-0.4, -2; 1.5)`; D2/N2 `(0.3, -3; 1.5)` |
| `DrippingWaterB_Shader` (:7180) | none / none | none |
| `LongPuddleCalm` (:8096) | none / `roughwater.png` | N1 `(-0.01, -0.01; -)`; N2 `(0.01, 0.012; 0.9)` |
| `WaterTrickle_Shader` (:8130) | `WaterTrickle_OS.png` / `WaterTrickle_Normal.png` | D1/N1 `(0, -2.7; -)`; D2/N2 `(0, -2; -)` |
| `RoundPuddleCalm` (:8326) | none / `roughwater.png` | N1 `(-0.01, -0.01; -)`; N2 `(0.01, 0.012; 0.9)` |
| `SmallStream_Shader` (:8741) | `waterspewDIF.png` / `waterspewNORM.png` | D1/N1 `(-0.4, -1.7; -)`; D2/N2 `(-1.5, -; 0.3)` |
| `WallSheet_Shader` (:8817) | none / `VerticalWater_Normal.png` | N1 `(0.025, -0.8; -)`; N2 `(-0.05, -1.5; -)` |
| `CalmWater_MidRef` (:9123) | none / `CalmWater_Normal.png` | N1 `(14, 5; 300)`; N2 `(-14, -5; 320)` |
| `RoughWater_Shader` (:9487) | none / `roughwater.png` | N1 `(14, 5; 100)`; N2 `(-14, -5; 100)` |

## Which actors use which material

These are exact `instances[].actorKey` names grouped through each asset section. Counts are
manifest uses; multi-section assets (and `BuiltWorld`) appear in more than one row.

- `WaterSpreadA` -> `puddle_alt` (5): `StaticMeshActor4907`, `StaticMeshActor3340`,
  `StaticMeshActor3319`, `StaticMeshActor3350`, `StaticMeshActor1150`.
- `CalmwaterCube_Midref` -> `Model984/254/981/986/678/132/91/8` source brushes plus
  `Model_Model1_20761` (`BuiltWorld`) (9): `Brush302`, `Brush109`, `Brush94`, `Brush88`, `Brush31`,
  `Brush1109`, `Brush399`, `Brush5`, `Model_Model1_20761`.
- `LongPuddleDrippy` -> `LongPuddleDrippy` (7): `StaticMeshActor87`, `StaticMeshActor2769`,
  `StaticMeshActor4`, `StaticMeshActor4977`, `StaticMeshActor55`, `StaticMeshActor1489`,
  `StaticMeshActor557`.
- `WaterCascadeA_Shader` -> `Cascade_512`, `Cascade_1024` (14): `StaticMeshActor5119`,
  `StaticMeshActor4903`, `StaticMeshActor3040`, `StaticMeshActor3032`, `StaticMeshActor4138`,
  `StaticMeshActor1066`, `StaticMeshActor188`, `StaticMeshActor2063`, `StaticMeshActor2062`,
  `StaticMeshActor2053`, `StaticMeshActor57`, `StaticMeshActor480`, `StaticMeshActor2337`,
  `StaticMeshActor519`.
- `WaterSpewA` -> `WaterSpewB` (4): `StaticMeshActor3390`, `StaticMeshActor3361`,
  `StaticMeshActor3362`, `StaticMeshActor3465`.
- `RoughWaterLowRefCube_Shader` -> `Model75/486/120/779/523/572/170/176/947/528/156`
  source brushes plus `BuiltWorld` (12): `Brush1100`, `Brush247`, `Brush257`, `Brush267`,
  `Brush200`, `Brush250`, `Brush407`, `Brush115`, `Brush409`, `Brush546`, `Brush114`,
  `Model_Model1_20761`.
- `RoundPuddleDrippy` -> `RoundPuddleDrippy` (17): `StaticMeshActor3789`,
  `StaticMeshActor4641`, `StaticMeshActor2408`, `StaticMeshActor2375`, `StaticMeshActor1447`,
  `StaticMeshActor2405`, `StaticMeshActor2406`, `StaticMeshActor2407`, `StaticMeshActor2374`,
  `StaticMeshActor2378`, `StaticMeshActor2379`, `StaticMeshActor2377`, `StaticMeshActor2376`,
  `StaticMeshActor2409`, `NonPhysicalReactiveActor34`, `NonPhysicalReactiveActor50`,
  `NonPhysicalReactiveActor49`.
- `StairPour_Shader` and `StairSpreadA` -> separate sections of `FX_StairWater_C` (6 each):
  `StaticMeshActor2912`, `StaticMeshActor3030`, `StaticMeshActor2563`, `StaticMeshActor2561`,
  `StaticMeshActor948`, `StaticMeshActor2562`.
- `FloorFlowA_Shader` -> `FloorFlowA/B` (5): `StaticMeshActor5128`, `StaticMeshActor3044`,
  `StaticMeshActor1576`, `StaticMeshActor4041`, `StaticMeshActor766`.
- `WindowSpew_Shader` -> `WaterJetNew`, `Wel_WaterJetB` (6): `StaticMeshActor1125`,
  `NonPhysicalReactiveActor5`, `NonPhysicalReactiveActor7`, `NonPhysicalReactiveActor8`,
  `NonPhysicalReactiveActor6`, `NonPhysicalReactiveActor4`.
- `DrippingWaterB_Shader` -> `Drip_puddle` (3): `StaticMeshActor1888`,
  `StaticMeshActor2892`, `StaticMeshActor3008`.
- `LongPuddleCalm` -> `LongPuddle`, `UPuddle` (14): `StaticMeshActor1586`,
  `StaticMeshActor2310`, `StaticMeshActor2335`, `StaticMeshActor2331`, `StaticMeshActor2404`,
  `StaticMeshActor2358`, `StaticMeshActor2385`, `StaticMeshActor2325`, `StaticMeshActor2340`,
  `StaticMeshActor2359`, `StaticMeshActor2361`, `StaticMeshActor2334`, `StaticMeshActor2339`,
  `StaticMeshActor2357`.
- `WaterTrickle_Shader` -> `WaterTrickle_512` (2): `StaticMeshActor2926`,
  `StaticMeshActor4043`.
- `RoundPuddleCalm` -> `RoundPuddle` (2): `StaticMeshActor2528`, `StaticMeshActor2799`.
- `SmallStream_Shader` -> `SmallStream` (2): `StaticMeshActor1246`, `StaticMeshActor4042`.
- `WallSheet_Shader` -> `WallSheet` (3): `StaticMeshActor1584`, `StaticMeshActor2913`,
  `StaticMeshActor1177`.
- `CalmWater_MidRef` -> `Model637` source brush plus `BuiltWorld` (2): `Brush218`,
  `Model_Model1_20761`.
- `RoughWater_Shader` -> `autopsytable_waterplane` (2): `StaticMeshActor4133`,
  `StaticMeshActor4134`.

## UE5 implementation

`M_ShockWater` is upgraded in place to sample and blend `WaterDiffuse1/2` and
`WaterNormal1/2`, each with its own U/V parameters. This preserves the old asset path used by
`AShockWaterVolume` while allowing saved `MaterialInstanceConstant`s to carry distinct source data
(`tools/ue5/author_water_material.py:193`). Each FluidShader uses the one decoded diffuse texture
for both diffuse animator layers and the one decoded normal texture for both normal layers; the
manifest does not declare a second texture per role. Missing textures use neutral engine defaults,
not a guessed BioShock asset.

Medical retains the existing shared texture path: `_import_textures` imports declared PNGs with
their colour-space/address intent, then `_resolve_imported_texture` supplies the exact imported
objects. Only `package == "1-Medical"` enters the specialised reparent/configure pass
(`tools/ue5/import_level.py:629`, `:643`, `:681`). Other maps and rig imports keep their existing
material behaviour.

`configure_fluid_instance` writes both texture pairs, raw panner U/V values, `PanSpeed=1`, and a
neutral white tint so decoded diffuse pixels are not replaced by the old generic teal colour
(`tools/ue5/author_water_material.py:340`). Raw `PanTime` is retained in scalar overrides and asset
metadata but is not used in graph arithmetic: its units and whether it is a period remain
`UNKNOWN`. Coverage/specular animators are likewise retained in metadata and not promoted into a
new shader feature in this task.

`verify_water.py` now loads `/Game/BioShockSlice/1-Medical`, walks placed instance actors, selects
material slots parented to `M_ShockWater`, and requires at least two distinct `(WaterDiffuse1,
WaterNormal1)` signatures and two distinct panner tuples before running the pre-existing surface,
overlap, and underwater-fade checks (`tools/ue5/verify_water.py:60`, `:145`).

## Validation

Pending headless UE commandlet results. Python syntax and diff checks are run separately; this
section is updated only with measured commandlet output.
