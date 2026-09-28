# w17 — light shape + rotation (W-BUG-01)

Scratch notes for the 28 Sept 2026 fix. Status summary lives in `sdk-crossref-world.md`.

## Medical `lights[].effect` census

Source: `Exports/slice/1-Medical/1-Medical.ue5-level.json` (695 lights).

| effect | count | with `cone` | notes |
| --- | --- | --- | --- |
| absent | 514 | 82 | guide default = point |
| 2 | 175 | 148 | almost all non-identity actor rotation |
| 3 | 6 | 2 | two omit `radius` entirely (sun signature) |

`cone` set on **232** lights total. Security-camera spotlight *classes* in this export write neither `effect` nor `cone` (they stay point under the effect map until packages write those fields).

## Ordinal map used by the importer

Guide lighting chapter lists four shape names in declaration order: Pointlight, Spotlight, Sunlight, Directionallight. Combined with the census above (not stock UE2's 20-value waver enum):

| byte | shape | UE5 class |
| --- | --- | --- |
| absent / 0 / 1 | point | `PointLight` |
| 2 | spot | `SpotLight` |
| 3 | sun | `DirectionalLight` |
| 4 | directional | `DirectionalLight` |

Confidence: **PLAUSIBLE**. `Engine.u` confirmation remains W-UNK-01.

## Cone formula

`cos(half_angle) = 1 − LightCone/255` → degrees → `USpotLightComponent.OuterConeAngle`. Default byte when spot omits cone: **128** (guide default).

## Rotation

`LevelLight.Rotation` / `LevelLightDocument.Rotation` = raw UE2 `[pitch, yaw, roll]` integers — same field shape as `LevelActorDocument.Rotation`. Importer applies via existing `_place` / `ROTATOR_TO_DEGREES`. Until Medical is re-exported, `_with_light_rotation` copies `actors[].rotation` by key.

## Verify

`tools/ue5/verify_light_shape.py` — headless, real Medical manifest only. Claude runs it; this worktree does not launch Unreal.
