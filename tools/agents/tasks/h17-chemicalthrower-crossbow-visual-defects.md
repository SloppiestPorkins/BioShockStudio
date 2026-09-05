---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Chemical Thrower "looks borked"; Crossbow textures are wrong

Two user reports (in-editor, 5 Sept 2026), vague on specifics since this is the first
real chance to look at these weapons up close (movement/collision only started working
a few hours before this report). Diagnose precisely before fixing — "looks borked" isn't
actionable on its own; get an exact description of the failure mode first if the cause
isn't obvious from asset inspection (null/default material, wrong UV scale, missing
texture, wrong mesh scale, bad skeleton binding, etc.) — this session has already had to
revert one fix tonight that was built on an assumed-rather-than-confirmed diagnosis
(materials/opacity-sampler track, see recent commits) — do not repeat that pattern.

## Investigation starting points

Both `WP_ChemicalThrower` and `WP_Crossbow` were imported in the same h3 pass as
Pistol/Shotgun (the only two of the five that DID land cleanly the first time, per h3's
own hand-off notes) — TommyGun/Pistol/Shotgun have all been directly exercised and look
fine per earlier user testing tonight; ChemicalThrower/Crossbow have not been visually
confirmed by a human until now. Check:

1. Material/texture bindings on `WP_ChemicalThrower` and `WP_Crossbow`'s skeletal meshes —
   null textures, wrong sampler types (this session found and fixed a real "Sampler type
   is Color, should be Masks" class of bug affecting 94 other materials tonight via
   `fix_masked_texture_sampler_mismatch.py` — check whether either weapon's materials hit
   the same pattern and simply weren't in that scan's scope, since that scan targeted
   `/Game/BioShockSlice/Content/Materials/Masters`, not `/Game/BioShockWeapons/`).
2. Mesh scale/pivot — compare against the working TommyGun/Pistol/Shotgun import
   parameters for anything that differs (uniform_scale, socket bone, etc.).
3. ChemicalThrower specifically: it's a beam weapon (`EWeaponFireMode::Beam`), the only
   one of the six starters with that fire mode — check whether its beam-effect rendering
   (whatever draws the flame/goo stream, `StopBeam`/beam-active state in `ShockWeapon.cpp`)
   is what looks wrong, as opposed to the held viewmodel mesh itself. Narrow down which
   before proposing a fix.

## Tests / verify

Once the actual defect is identified (not assumed), add whatever headless assertion can
catch it going forward — e.g. if it's a null/default-material texture, extend
`verify_weapon_meshes.py`'s pattern to check texture parameters resolve, similar to
`audit_level_materials.py`'s slot checks.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only.
- If you cannot narrow down the exact defect from asset inspection alone (i.e. it
  genuinely requires a human to look at the rendered result and describe what's wrong),
  say so explicitly and report what you *did* rule out, rather than guessing a fix for an
  undiagnosed symptom.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once verified.
