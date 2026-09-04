# 1-Medical: why 54 StaticMeshActor Element0 slots resolve to nothing

> **CLOSED, kept for the record.** Both root causes this file diagnoses are fixed. Category A
> (doors placing the animation-proxy mesh instead of the real door) — `LevelAnalyzer.Door`/
> `ReadDoorAttachments` now fall back to the class default `Attachments` property, landed with the
> door-placement work (`docs/HANDOFF.md`, `ea5f0cc`). Category B (cross-package BSP material
> imports silently dropped) — `LevelInstance.MaterialReferences` now carries the raw
> `PackageIndex` past `Describe`'s single-package limit, and `bsp.md` §5.6d measures **0 of 74,091**
> drawn compiled-world polygons unresolved for it, down from the 1,530 this file found. The
> byte-level diagnosis below is still accurate as a worked example of how the bug was found; do not
> read either category as still open.

Analysis only. Nothing was run in Unreal, nothing outside this file was modified.

Evidence sources:
- `…/scratchpad/exp2/1-Medical/1-Medical.ue5-level.json` (43 MB manifest, parsed with Python)
- `…/scratchpad/exp2/1-Medical/Meshes/*.obj`
- `C:\Users\Jack\Documents\BioshockHavok\tools\ue5\import_level.py`
- `C:\Users\Jack\Documents\BioshockHavok\src\BioShockStudio.Core\Level\LevelScene.cs`
- `C:\Users\Jack\Documents\BioshockHavok\src\BioShockStudio.Core\Level\LevelAnalyzer.cs`
- `C:\Users\Jack\Documents\BioshockHavok\src\BioShockStudio.Core\Materials\MaterialReader.cs`
- `C:\Users\Jack\Documents\BioshockHavok\src\BioShockStudio.Core\Export\LevelSceneExporter.cs`
- the shipped package itself, read via `src/BioShockStudio.Cli/bin/Release/net8.0/BioShockStudio.Cli.exe`
  (`properties`, `materials`, `context` — all read-only commands)

---

## Answers to the five questions, up front

1. **Do the door assets have a `sections` list?** Yes. `Med_DoorAnim` has exactly one section.
   **The early return in `_assign_asset_material` is NOT the bug for the doors.** (Zero assets in
   the whole manifest have an empty/absent `sections` list — 1551 / 1551 have one.)
2. **What is the section's `materialKey`?** `null`. In fact the section record for the door asset
   carries *only* `firstIndex` and `triangleCount` — all five material fields
   (`material`, `materialKey`, `materialPackage`, `materialClassName`, `materialExportIndex`)
   are absent/null.
3. **Dangling keys?** None anywhere. Every non-null `materialKey` in the manifest resolves against
   `materials[]` (455 entries, 455 unique keys, 0 duplicates, **0 dangling references**). So
   hypothesis 3 is ruled out for the whole level.
4. **Cross-package import?** **Yes — but only for the weapon/pickup meshes, not for the doors.**
   Two genuinely different root causes are in play; see the breakdown.
5. **Counts:** see below.

---

## Category breakdown

Counted as *placed* Element0 slots (brush instances are never placed — `_should_place_mesh_instance`
in `import_level.py:571` returns `False` for `kind == "Brush"` on a non-volume actor, so their
failures never reach the level).

| # | Category | Assets | Placed Element0 slots |
|---|---|---|---|
| A | **Door / camera / banner animation-proxy SkeletalMeshes** — the mesh's own material slot names nothing in the source data, because the visible geometry is not this mesh | 4 | **37** (31 of them doors) |
| B | **Cross-package material IMPORT dropped by the exporter** | 6 | **12** |
| C | **Source data genuinely has no material** (`Material Object <none>`) | 1 | **1** |
| D | **Compiled world (`Model1`) section 0** names a non-export material | 1 | **1** |
| — | *(not placed)* Brush/CSG assets with a null section-0 material | 547 | 0 |
|   | **Total placed** | **12** | **51** |

**Reconciliation with the audit's 54.** This export produces 51, not 54. Three labels from the audit
list do not exist in this manifest at all (`MedicalDoors_Solid3`, `MachineGunBulletPickup4`,
`banner_Constrained_lightair010`), and this export has **39 instances with a `label` of `null`**
(including one `Med_DoorAnim` instance and the `banner` instance). The audit was clearly run against
a slightly earlier export. The 3-slot difference is bookkeeping, not a different failure mode — every
category above is stable.

Category A is 72% of the failures and 100% of the doors, so it is the one that matters.

---

## Category A — the doors. Root cause.

### The manifest record

```json
{ "key": "SkeletalMesh_Med_DoorAnim_12858", "name": "Med_DoorAnim", "kind": "SkeletalMesh",
  "exportIndex": 12858, "vertexCount": 26, "triangleCount": 16,
  "sections": [ { "firstIndex": 0, "triangleCount": 16 } ],
  "group": "Med_DoorAnim", "file": "Meshes/Med_DoorAnim_12858.obj" }
```

**26 vertices, 16 triangles.** That is not a door. Its OBJ (`Meshes/Med_DoorAnim_12858.obj`) has
`usemtl BioShock_0` and **no `mtllib` line at all**, versus e.g. `tv_wall_mounted_4268.obj` which has
`mtllib tv_wall_mounted_4268.mtl` + two `usemtl` groups.

### Where the material went — byte-level

`bioshock-tool properties 1-Medical Med_DoorAnim`:

```
SkeletalMesh Med_DoorAnim  [12858] 6520 bytes  outer=export Package 'Med_DoorAnim'
  CheckpointTypePadding        Int   -842150451
  +23 trailing 6497 bytes: 000000C10000DCC200000CC3000000410000DC4200000C43 01 000000000000000000000000 00002043 04000000 05000000 01 00 0000803F…
```

`MaterialReader.TagBlock` is `[4,0,0,0,5,0,0,0]` (`MaterialReader.cs:298`). It is present, at payload
offset 64, well inside the 256-byte search window. After it: compact index `01` = **one** material
slot, then compact index `00` = **`PackageIndex` 0 = None**. `NamesAMaterial` (`MaterialReader.cs:806`)
returns `false` for a reference that is neither export nor import, so `ReadMeshMaterialSlots` returns
an empty list. `bioshock-tool materials 1-Medical Med_DoorAnim` agrees: **"no material reference"**.

So the exporter is reading the bytes correctly. The mesh really does declare one section and zero
materials.

### Why: the door's visible geometry is somewhere else entirely

`bioshock-tool properties 1-Medical --index 1` (the `MedicalDoors` class default object, outer
`Package 'Doors'`):

```
Class MedicalDoors  [1] 441 bytes  outer=export Package 'Doors'
  Attachments   Array
    [0]  StaticMesh Object  export StaticMesh 'Med_DoorRight'   AttachSocket Name  LeftDoor
    [1]  StaticMesh Object  export StaticMesh 'Med_DoorRight'   AttachSocket Name  rIGHTdOOR
  OpenAnimationName  Name  Med_DoorOPEN
  Mesh               Object  export SkeletalMesh 'Med_DoorAnim'
```

`Med_DoorAnim` is the **animation proxy** — a 26-vertex skeleton driver with two sockets. The door
the player sees is `Med_DoorRight`, attached twice. And `Med_DoorRight` is fully healthy in the
manifest:

```
StaticMesh_Med_DoorRight_5540   1824 verts / 2292 tris, 2 sections:
  ['Shader_medical_door_shader_9978', 'Shader_reinforcedglass_diffuse_shader_5841']   <- both resolve
```

`bioshock-tool context 1-Medical Med_DoorAnim` confirms the `Med_DoorAnim` group holds **no shader or
material export at all** — 10 objects, all of them skeleton/animation metadata.

But `Med_DoorRight` has only **2 instances** in the manifest, against **31** `Med_DoorAnim` instances.

### Why the attachments never made it into the manifest

The exporter does have a door-attachment path — `LevelSceneExporter.cs:430` writes
`actors[].door.attachments`. It is empty for every door:

```
37 actors carry a "door" block; 0 of them have a non-empty "attachments" array.
MedicalDoors35 -> {"locked": true, "attachments": [], "complete": true}
```

`LevelAnalyzer.Door(...)` (`LevelAnalyzer.cs:911`) receives `ClassDefaults defaults` and correctly
uses it for the portal (`Reference(package, defaults, payload, "DoorPortal", null)`), but:

```csharp
bool hasAttachments = payload.Find("Attachments") is { Type: UnrealPropertyType.Array };   // line 927
…
var attachments = ReadDoorAttachments(package, payload, out bool attachmentsComplete);      // line 933
```

`ReadDoorAttachments(package, payload, …)` (`LevelAnalyzer.cs:955`) reads **only the actor payload**
and never falls back to `defaults`. BioShock stores `Attachments` on the *class default object*, not on
the placed actor — the actor `MedicalDoors35` payload has no `Attachments` property at all (verified:
its full property dump is PathList/Base/Level/Region/Tag/Location/Rotation/…/Label, nothing else).
The same manifest proves the class-defaults path exists and works for the mesh:
`"skeletalMeshReference": { "objectName": "Med_DoorAnim", "origin": "class defaults", … }`.

Downstream, `tools/ue5/import_level.py` contains **zero** references to `door` or `attachment`
(grep for `[Dd]oor` returns nothing), so even a populated `door.attachments` would not currently be
placed.

**Root cause, stated plainly:** the doors are grey because the pipeline places the wrong mesh. It
places the door's `Mesh` — a 26-vertex animation proxy whose single material slot is `None` in the
shipped game data, by design — and never places the class-default `Attachments[]` static meshes that
carry the actual door geometry and its two (already correctly resolved) shaders. The empty `Element0`
is a symptom of the proxy being drawn at all, not of a material lookup failing.

---

## Category B — cross-package material imports (12 slots)

Here the user's hypothesis 4 is exactly right. `bioshock-tool properties`:

| Asset | `Materials[0].Material` | Placed instances |
|---|---|---|
| `StaticMesh_tommygun_ammo_standard_6885` (outer `WP_TommyGun`) | `import FacingShader 'ammostandard'` | 5 |
| `StaticMesh_WP_AI_Pistol_7028` (outer `WP_AI_Pistol`) | `import Shader 'PistolShader'` | 3 |
| `StaticMesh_PU_TommyGunMESH_14200` (outer `WP_TommyGun`) | `import Shader 'tommygun2_diffuse'` + `import Shader 'ammostandard_diffuse_shader'` | 1 |
| `StaticMesh_Pickup_12674` (outer `WP_Wrench`) | `import Shader 'WP_WrenchMesh_diffuse_shader'` | 1 |
| `StaticMesh_Pickup_14514` (outer `WP_Shotgun`) | `import Shader 'Shotgun_NoUpgrades_Diffuse_shader'` | 1 |
| `StaticMesh_tommygun_ammo_frozen_12671` (outer `WP_TommyGun`) | `import FacingShader 'ammostandard'` | 1 |

The reference is read fine — `MaterialReader.NamesAMaterial` (`MaterialReader.cs:806`) explicitly
accepts imports and checks their `ClassName`. It is thrown away one layer up:

```csharp
// src/BioShockStudio.Core/Level/LevelScene.cs:414
private static SourceId? Describe(BioShockPackage package, PackageIndex index)
{
    if (!index.IsExport || index.ExportIndex >= package.Exports.Count) return null;   // <-- imports die here
    …
}
```

`LevelScene.Decode` maps every slot through `Describe` (`LevelScene.cs:403-405`), so an import becomes
`null`, and `LevelSceneExporter.cs:205` writes `MaterialKey = null`. `WriteMaterials`
(`LevelSceneExporter.cs:~722`) also guards with `if (id.ExportIndex >= package.Exports.Count) continue;`,
so it could not resolve a cross-package id even if one arrived.

---

## Categories C and D (1 slot each)

- `StaticMesh_banners_9675` (outer `Gen_Signs`): `Materials[0].Material = Object <none>`. The shipped
  data has no material for this slot. Nothing to fix in the pipeline.
- `Model_Model1_20761` (the compiled world) has 67 sections; **66 resolve**, section 0 does not. Because
  66 do resolve, `_assign_asset_material` does set `static_materials`, so this one really is a single
  empty `Element0` slot on an otherwise-correct mesh.

---

## Three worked examples

1. **`MedicalDoors35` → `SkeletalMesh_Med_DoorAnim_12858`, section 0.**
   `materialKey = null` (all five material fields absent). Source bytes: tag block `4,0,0,0,5,0,0,0`
   → count `1` → reference `0` (`None`). Does **not** resolve, and cannot — the game stores no material
   on this mesh. Correct material lives on `StaticMesh_Med_DoorRight_5540` §0 =
   `Shader_medical_door_shader_9978`, which *is* in `materials[]` and *does* resolve. 31 instances.

2. **`PistolPickup0` → `StaticMesh_WP_AI_Pistol_7028`, section 0.**
   `materialKey = null` in the manifest, but the package says
   `Materials[0].Material = import Shader 'PistolShader'`. The reference exists and is a material class;
   `LevelScene.Describe` returns `null` for it purely because `index.IsExport` is false. 3 instances.

3. **`TV_WallMounted6` → `StaticMesh_tv_wall_mounted_4268` (control, works).**
   2 sections, `materialKey` = `Shader_tv_wall_mounted_diffuse_shader_28365` and
   `MaterialSequence_tv_sequence_static_28366`; both present in `materials[]` with
   `sourceFile = …/Maps/1-Medical.bsm`. Its OBJ has `mtllib tv_wall_mounted_4268.mtl` +
   `usemtl BioShock_0/BioShock_1`. Structurally the asset record is *identical in shape* to the door's —
   same keys, same `sections` array — the only difference is that the section objects carry the five
   material fields instead of omitting them. (`dyn_Floor_Lamp_0` → `Floor_Lamp_02_5409` and
   `SteamRoomSurgicalLight` → `med_lampset_3836` behave the same way, 1 resolving section each.)

---

## Note on `_assign_asset_material`'s behaviour (symptom, not cause)

For all 11 non-compiled-world failing assets, **every** section is unresolved, so
`resolved_any` stays `False` and `_assign_asset_material` (`tools/ue5/import_level.py:418`) hits:

```python
if not resolved_any:
    return
```

`static_materials` is never set, the mesh keeps whatever the OBJ import gave it, and since these OBJs
have no `mtllib`, Unreal assigns its default material. That is precisely the grey the audit sees. The
early return is *correct* behaviour given null input — but it is silent, which is why 51 slots went
unreported until the audit.

---

## Recommended code changes

**1. Doors — the 37-slot fix. `ReadDoorAttachments` must consult class defaults.**

*File:* `src/BioShockStudio.Core/Level/LevelAnalyzer.cs`
*Functions:* `Door` (line 911) and `ReadDoorAttachments` (line 955)

Pass the already-available `ClassDefaults defaults` into `ReadDoorAttachments` and look `Attachments`
up there when the actor payload does not carry it — the same fallback `Reference(package, defaults,
payload, "DoorPortal", null)` on line 923 already uses, and the same one that makes
`skeletalMeshReference.origin == "class defaults"` work. Widen the `hasAttachments` gate on line 927
the same way. This is the single change that turns `door.attachments` from `[]` into the two
`Med_DoorRight` / socket pairs for all 37 door actors.

**2. Doors — placement.** *File:* `tools/ue5/import_level.py`. Nothing in `_assign_asset_material`
can fix this; the proxy mesh has no material to bind. `_import_mesh_instances` (around line 841) needs
to place each `actors[].door.attachments[]` entry as its own StaticMeshActor at the socket transform
(and, ideally, stop placing the bare `*_DoorAnim` proxy as visible geometry — see
`_should_place_mesh_instance`, line 571, which is where an "animation-proxy mesh" exclusion belongs).
Once placed, `Med_DoorRight`'s two sections already resolve, so no material work is needed.

**3. Cross-package imports — the 12-slot fix.**

*File:* `src/BioShockStudio.Core/Level/LevelScene.cs`, *function:* `Describe` (line 414)

Stop discarding imports. Emit a `SourceId` for an import reference too, taking the package name from
the import's outermost entry and the class/object name from the import record (`package.Imports[i]`
already exposes `ClassName`, which `NamesAMaterial` reads at `MaterialReader.cs:817`). Paired change in
`LevelSceneExporter.WriteMaterials` (`src/BioShockStudio.Core/Export/LevelSceneExporter.cs`, ~line 722):
replace `if (id.ExportIndex >= package.Exports.Count) continue;` with a branch that opens the named
package and resolves the material there, so the emitted `materialKey` actually lands in `materials[]`.
Without the second half, `Describe` would start emitting keys that dangle — which would be worse than
today, so **these two must land together**.

**4. Diagnostics (small, cheap, prevents recurrence).**

*File:* `tools/ue5/import_level.py`, *function:* `_assign_asset_material` (line 418)

Both early returns are silent. Increment a counter (e.g. `report["materialSlotsUnresolved"]` and
`report["assetsWithNoResolvedMaterial"]`) before returning, and log the asset key. 51 grey slots
should not need an out-of-band audit to discover.

---

## What is *not* ambiguous, and what is

**Not ambiguous:** the door root cause. The byte evidence (`PackageIndex 0`), the class-default
`Attachments[]` naming `Med_DoorRight`, the healthy `Med_DoorRight` asset record with two resolving
shaders, and the empty `door.attachments` in the manifest all agree, and `ReadDoorAttachments`'s
missing `defaults` argument is visible in the source.

**Not ambiguous:** the import case — `properties` prints `import Shader 'PistolShader'` and `Describe`
visibly returns `null` for non-exports.

**Genuinely open:** whether the correct UE5 representation of a door is "two static meshes at the two
sockets" or "one skinned mesh driven by `Med_DoorAnim`'s skeleton". This report establishes *where the
geometry and materials are*; it does not establish which of those the runtime should build, and the
`LeftDoor` / `rIGHTdOOR` socket transforms have not been checked against `Med_DoorAnim`'s skeleton here.

**Also open (minor):** the 3 door/pickup instances present in the audit but absent from this export,
and the 39 instances that now have `label: null`. Both point at an export-side change between the
audited run and this one. Worth a separate look, unrelated to materials.
