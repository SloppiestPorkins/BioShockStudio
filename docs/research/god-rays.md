# Medical Pavilion god rays

Status: material inputs **VERIFIED** in the current `1-Medical.ue5-level.json`; UE rendering awaits
the headless repair run and `-game` capture.

BioShock's shafts are mesh-based `LightBeamShader` materials, not directional-light volumetric
shafts. Medical places `Light_Beams` / `light_beam_02` static meshes and overrides some instances
with `Light_Beams_Science_Yellow` or `Orange_Beams`.

The base `Light_Beam_01` manifest record resolves two shipped textures:

- `FalloffMap` → `Light_beam_LowFalloff.png`
- `DustMap` → `LightDust_Dif.png`

It also carries `DustTextureAnimator`, a panner with U/V direction 0.7/0.2 and seven-second source
duration. This settles the texture question: a generated gradient is unnecessary.

The beams became invisible because the generic material pipeline has no semantic BaseColor for a
`LightBeamShader`. Additive masters correctly use black for a missing input (black is additive
identity), but that honest fallback also makes the beam draw nothing.

`repair_light_beams.py` authors one unlit, two-sided additive master. It multiplies the shipped
falloff by a 65%-base/35%-scrolling-dust modulation (so the dust's dark field cannot erase the
shaft), then applies a `BeamTint`, a 0.8 intensity, and a 120 uu
`DepthFade` before emissive output. The same fade and falloff drive opacity, avoiding hard geometry
intersections. Material overrides are recovered by joining each imported actor's `BioShockKey`
tag back to the manifest actor record; yellow/science and orange instances receive separate
material instances and tints.

`BioshockGlowSettings` is present only as a resolved `Class` reference on `LevelInfo`; the export
does not carry usable bloom parameter values. Mapping it to UE post-process settings would therefore
be speculative and is not part of this repair. Existing level exposure/bloom remains unchanged.

Confidence: **VERIFIED** for texture identity, panner direction, actor overrides, and additive class;
**MEDIUM** for UE intensity/tint until visual QC, because `BeamColor`/`BeamBrightness` class-default
values are not in this manifest.
