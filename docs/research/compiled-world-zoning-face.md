# The compiled-world mesh's one null material slot (29 Sept 2026)

Live report: "so many broken textures" — two screenshots, both a large tan/white checkerboard
panel on a wall/cabinet-style surface, in what turned out to be different rooms.

## What it actually was

A full-level scan (`4208` `StaticMeshActor`s checked) found exactly **one** null-material issue in
`1-Medical`: `compiled world`'s (the `Model1_20761`/`BuiltWorld` mesh — the single combined static
mesh for all the level's compiled BSP architecture) material slot 0, out of 67 total slots. UE5
renders a null material slot as its own fallback (a visible grey checkerboard), not as nothing —
that's the pattern the user saw.

## Why slot 0 has no material

Confirmed at the exporter source, not guessed:

- `1-Medical.ue5-level.json`'s `Model_Model1_20761` asset section 0 (619 triangles) carries no
  `material`/`materialKey`/`materialClassName` at all, unlike its other 66 sections.
- `LevelSceneExporter.cs:204`: `Material = index < g.First().Materials.Count ? g.First().Materials[index]?.ObjectName : null` —
  the resolved `Materials[0]` entry for this mesh is genuinely `null`.
- `MeshSurfaceResolver.cs:15-18`'s own docstring: a slot resolves to `null` when it "names
  nothing, names something outside this package, or [the reference] could not be followed." Which
  of the three applies to this specific slot is not confirmed here — that needs the C# tool
  instrumented to log the reason, not attempted in this pass.

This is a decode-time gap in `BioShockStudio` (the C# exporter), not an import-side bug — nothing
in the exported manifest names a real material for this slot, so there was nothing for
`import_level.py` to correctly bind.

## Why this wasn't caught as new — and why it stayed unfixed

`repair_null_slot_materials.py` (landed 8 Sept 2026, commit `630f1f5`) already found this exact
slot and explicitly skipped it: `# compiled-world shell slot 0 is the zoning face, intentionally
null`. That reading is corroborated independently here, not just trusted: the guide mirror's
"Zones and Portals" chapter (`08-Zones-and-Portals.md`) describes a BSP surface flagged `Portal`
as "the surface is a zone portal" — used by the renderer's own visibility-culling system, not
meant to be seen. Section 0's own geometry is consistent with that: its 619 triangles span nearly
the entire level footprint (X -65027..-16528, Z -7357..12577, read from its face list in
`Meshes/Model1_20761.obj`) rather than one contiguous decorative surface — a spread that fits
sparse zone-boundary planes at room transitions throughout Medical far better than a missing wall
texture would. That also explains why it read as "so many" broken patches in different rooms: it
is the same slot, rendered wherever a zone boundary happens to fall, not many separate bugs.

The 8 Sept skip correctly avoided asserting a wrong texture over this slot, but left the actual
visible symptom unaddressed — UE5 has no native "zone portal, do not render" surface concept, so
"leave the material unset" is not equivalent to "hide this surface" the way it would have been in
the original UnrealEd-based engine.

## The fix

`tools/ue5/repair_compiled_world_null_material.py` (new): assigns a fully transparent
(`BLEND_TRANSLUCENT`, `Opacity=0`) placeholder material, `M_UnresolvedBspSection`, to the one null
slot, rather than a plausible-but-unverified solid colour. This hides the surfaces instead of
asserting they are real, texturable BioShock geometry the fix doesn't actually have data for.
Collision is untouched (a `StaticMeshComponent`'s material assignment doesn't change collision).
Wired into `setup_playable_slice.py` right after `repair_null_slot_materials`, since it targets
the exact slot that script's own comment already named and intentionally left alone.

Applied to the live slice and reverified: **0/4208 actors have a null or engine-fallback material**
(was 1). Regression-checked clean: `verify_gameplay_fidelity`, `verify_scripting_movers`,
`verify_vita_chamber`, `verify_import_scripts`.

## Still open

- Which of `MeshSurfaceResolver`'s three null-reasons this slot actually hits is not confirmed —
  would need the C# exporter instrumented to log it, not attempted here.
- If the "zoning face" reading turns out to be wrong, `M_UnresolvedBspSection` is the reversible
  point to fix from: swap its `Opacity` back to `1.0` and give it a real `BaseColor` once/if the
  real material is ever recovered.
