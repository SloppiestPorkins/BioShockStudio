---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Decal meshes (Wall_Leak, blood smears, scorch marks, drips) block the player like solid geometry

User report (in-editor, 5 Sept 2026): "all decals have collision." Confirmed by code
audit: there is NO decal-specific collision handling anywhere in the import pipeline
(`import_level.py`, `import_bioshock.py`) — every imported StaticMesh gets whatever
default collision UE5's OBJ importer generates (an auto convex hull), including thin
cosmetic overlay meshes that were never meant to physically exist (Wall_Leak_1024/512,
blood_smear, damdec_01-04, ScorchMark, drip/puddle meshes, etc.). This is a pre-existing
gap, not something introduced by tonight's collision or material work.

## Do not guess the identification signal — verify it first

The obvious-looking heuristic (any material with `outputBlending in (1, 2)` — the
codebase's own documented signal for "blood splats, drips, decals," see
`import_bioshock.py`'s `_material_rendering_kind` comment) is NOT clean on its own:
`Wall_Leak_diff_shader` and `reinforcedglass_diffuse_shader` (real glass, not a decal —
fixed earlier tonight for an unrelated sampler-type bug) both carry `outputBlending: 1`.
outputBlending alone does not distinguish "decal painted flat against a surface" from
"a real, currently-transparent panel."

A decal's actual distinguishing structural property is that it's placed as a thin
mesh (near-zero depth in one dimension) directly flush against another surface, and it is
never meant to be walked into. Before writing any fix, confirm this by direct
inspection: for a sample of known decal actors (Wall_Leak_*, blood_smear, damdec_01-04,
ScorchMark) and a sample of known non-decals with similar-looking materials (the reinforced
glass panels, window glass), compare: (a) bounding-box thinness (one dimension's extent
tiny relative to the other two — quantify it, don't eyeball), (b) mesh naming, (c) whether
the mesh is shared by many actors at different rotations (typical decal reuse pattern) vs.
a handful of unique architectural placements. Report the actual measured distribution the
way `fix_walkable_prop_collision.py`'s size-cutoff investigation did (dry-run report of
candidates and their measured properties, reviewed before applying) — do not ship a
one-shot classifier without seeing where the real cutoff falls in this project's own data.

## What to do

Once a reliable identification rule is confirmed against real data (likely a combination
of thinness ratio + mesh-name keyword list + explicit exclusions, mirroring
`fix_walkable_prop_collision.py`'s pattern of keywords + size filter + exclude list), set
matched actors' mesh collision to `NoCollision` (not complex-as-simple, not a convex
hull — decals should never block anything or be traced against). Write this as a
standalone, scoped script (`fix_decal_collision.py` or similar) following this session's
established pattern: dry-run mode first, review the candidate list by hand, then apply for
real. Do not touch collision on anything that isn't confirmed to be a decal — reinforced
glass, real windows, and puddle/water surfaces the player might legitimately interact with
must keep their current collision behavior.

## Tests / verify

Re-run `run_collision.py`/`verify_collision.py` after the fix — must still report 0
errors (this is the canonical collision health check this project already relies on).
Additionally spawn-check (or otherwise confirm) that a player-sized capsule swept through
a few decal locations no longer blocks, while the same sweep still blocks against a real
wall/glass panel location.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only.
- No live UE session needed for the dry-run investigation and the fix script itself — both
  run headless via `-run=pythonscript`, same as every other fix in this session.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once verified,
  including the actual measured thinness/keyword cutoff data your investigation found (not
  just the final rule) so a human reviewing it can sanity-check the same way h11/h12's
  entries do.
