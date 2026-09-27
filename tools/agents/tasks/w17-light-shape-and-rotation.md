---
worker: cursor
base: main
verify: git status --short
lane: tools/ue5/**, docs/research/**
---

# w17 — spot/directional light shape + rotation (W-BUG-01)

> **Run mode:** non-interactive, sandboxed. Do NOT launch Unreal, do NOT build, do NOT touch
> `C:\Users\Jack\Documents\BioShockUE5`. Do NOT commit. Claude builds + runs the headless verify.
> **Copyright:** the SDK guide is unlicensed and this repo is public — never copy its prose.
> Facts only, own words. Guide (read-only): `C:\Users\Jack\AppData\Local\Temp\claude\C--Users-Jack-Documents-AI-Test\c7be037f-fb45-4801-8732-1d5df17a8bb3\scratchpad\unrealed-guide-mirror`.

Context: `docs/research/sdk-crossref-world.md` W-BUG-01. `import_level._import_lights` always
`spawn_actor_from_class(unreal.PointLight, ...)` regardless of the authored light's shape, and
drops the actor's rotation entirely — so every spot, sun and directional light in every imported
map renders as an omnidirectional point light. `LevelLightDocument` (C#) carries `cone`/`type`/
`effect` per light (confirmed present in the exported JSON — `effect` is the shape selector,
`cone` the half-angle byte, `type` the animation kind already wired by W-BUG-03/`_apply_light_effect`
in `import_level.py`) but `LevelLight.cs` does not export the actor's own rotation, so the light's
aim direction is not currently recoverable at all.

**Do this in order, verifying each claim against the current code first:**

1. **Add rotation export.** Find where `LevelLightDocument` is built in
   `src/BioShockStudio.Core/Export/LevelSceneExporter.cs` and add the light actor's own rotation
   (same UE2 rotator → degrees convention `import_level.py`'s `ROTATOR_TO_DEGREES` already uses for
   other actors — check `LevelActorDocument`/other actor documents for the existing rotation field
   shape and reuse it, don't invent a new one). Re-export is out of scope for you (Claude re-runs
   `export-level` for 1-Medical); just get the field into the manifest schema and add/update a C#
   test asserting a known light's rotation round-trips.
2. **Census the `effect` field** in the real Medical manifest
   (`C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json`, key
   `lights[].effect`) — note the distinct values seen and how many lights have `cone` set (cone
   only makes sense for a spotlight shape). Cross-reference the community SDK guide's light-effects
   chapter for the shape names in ordinal declaration order (own words only — do not quote the
   guide; a short enum-order fact, not its prose, is what you need) and propose which ordinal is
   which shape, same reasoning style as `import_level.py`'s existing
   `_UE2_LIGHT_TYPE_TO_EFFECT` comment for `type` (which you can use as a template for how this repo
   documents an inferred-from-declared-order enum mapping).
3. **Spawn the right UE5 light class.** In `_import_lights`, branch spawn class on the mapped
   shape: point light shape → `unreal.PointLight` (current behaviour, unchanged); spotlight shape →
   `unreal.SpotLight`, apply the light's own rotation (once exported) and map `cone` to
   `OuterConeAngle` (half-angle degrees — check the guide's stated formula relating the byte to an
   angle before picking a conversion, and say what you used); sun/directional shape →
   `unreal.DirectionalLight` (a directional light has no meaningful `AttenuationRadius` — do not
   set one; carry only colour/brightness/rotation and whatever `type`-driven effect still applies).
   An existing actor of the wrong light class must be destroyed and respawned as the previous
   `_import_lights` code already does for a non-PointLight squatter on a light's key — extend that
   same replace-if-wrong-class check to cover the new classes instead of assuming PointLight.
4. **Don't break W-BUG-03.** `_apply_light_effect` currently assumes it's decorating a light with
   an `attenuation_radius`/intensity `light_component` property already set the same way for every
   spawned light class — check it still applies correctly (or is skippable) for a spotlight/
   directional light's component, since `ULightComponent` (the common base) has `intensity` but a
   directional light has no attenuation radius property at all.

## Deliverable

- The exporter rotation field + C# test.
- The importer shape-branch + rotation/cone application.
- `tools/ue5/verify_light_shape.py` (headless, `-run=pythonscript`-compatible, house style
  `tools/ue5/verify_light_import.py`): run against the REAL Medical manifest (not synthetic data —
  a synthetic light with a hand-picked shape value proves nothing about the actual ordinal mapping),
  assert every spotlight-shaped light imports as `unreal.SpotLight` with attenuation radius +
  rotation matching the manifest and cone converted by your stated formula, every sun/directional
  imports as `unreal.DirectionalLight`, and point-shaped lights are unchanged from today (regression
  case). Include a negative case: an existing wrong-class actor at a light's key gets replaced, not
  reused.
- `docs/research/sdk-crossref-world.md`: update the W-BUG-01 row status, noting exactly which
  `effect` ordinal you mapped to which shape and the confidence (own words; cite the census numbers,
  not the guide's prose).
- Don't regress: `verify_light_import.py`, `run_light_look.py`, `verify_gameplay_fidelity.py`.
