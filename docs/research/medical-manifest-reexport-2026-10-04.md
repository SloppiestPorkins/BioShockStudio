# 1-Medical manifest re-export after `CorrectedArraySize` (4 Oct 2026)

Investigation only. No Unreal run, production manifest not overwritten.

Production baseline: `C:/Users/Jack/Documents/BioShockUE5/Exports/slice/1-Medical/1-Medical.ue5-level.json`
(`generator: BioShockStudio`, `formatVersion: 4`, mtime 2026-09-25 20:44). Re-export with current
CLI (`export-level-manifest`, no OBJ writes). Diff tool: `tools/manifest_diff.py`.

| collection | old | new | added | removed | changed |
|---|---:|---:|---:|---:|---:|
| actors | 8089 | 8077 | 2 | 14 | 11 (all `door`) |
| instances | 5322 | 5310 | 2 | 14 | 0 |
| assets / lights | 1551 / 695 | same counts | 0 | 0 | every asset `file` → null (manifest-only export; not a decode change) |

Commit under test: `54cac6e` (adds `MeasureStructArray` / `CorrectedArraySize` in
`UnrealPropertyReader`). A/B in this worktree only; production code left at HEAD.

## Method

1. Re-export Medical with HEAD; diff vs production.
2. A/B: force `CorrectedArraySize` → `measure.Declared` (still calls `MeasureStructArray`).
3. A/B: restore `UnrealProperty.cs` from `54cac6e^` (no measure call at all).
4. Temporary stderr probes on HEAD: log `ARRAYFIX` / `ARRAYTHROW` per Array property, then revert.
5. `properties 1-Medical --index N` / class-default dumps for byte-level confirmation.

## Verdict table

| Change | Cause | NEW more correct? |
|---|---|---|
| 14 actors removed | `MeasureStructArray` throws `InvalidDataException: FCompactIndex overflow` on non-struct arrays (`MaterialModifiers` / `Skins` / `SpawnZones`); `ActorPayloadReader.TryRead` returns null; `LevelAnalyzer` skips the export | **No — regression** |
| 2 actors added (`SteamRoomBody`, `SteinmanTele`) | `CorrectedArraySize` enlarges short struct arrays so the actor property list finishes cleanly (`Truncated=false`) | **Yes — improvement** |
| 11 `door` fields gain attachments (or gain a `door` object) | Class-default `Attachments` arrays short by Object size bytes; after correction `ReadDoorAttachments` resolves the real meshes | **Yes — improvement** |

## 14 removed actors — regression

Keys (export index suffix): `PlacedGathererVent5_7897` and StaticMeshActors `_8640 _10489 _8248
_8982 _9089 _7455 _9274 _8885 _8860 _7513 _7415 _7991 _8032`.

On HEAD, `properties --index` for each shows `Range16777215` / no actor header: `TryRead` failed.
Instrumented walk:

| export | object | throwing Array | declared |
|---|---|---|---:|
| 7897 | PlacedGathererVent5 | `SpawnZones` | 7 |
| 8640, 8248, 8982, 9089, 7455, 9274, 8885, 8860, 7513 | StaticMeshActor* | `MaterialModifiers` | 4 |
| 10489, 7415, 7991, 8032 | StaticMeshActor* | `Skins` | 3–4 |

Those Arrays are **not** property-list struct arrays. `MeasureStructArray` still starts walking them;
an uncaught `InvalidDataException` from `ReadCompactIndex` aborts the whole property list. Catching
the exception (or skipping the measure call) restores a clean actor header and the same fields the
production manifest carried (e.g. StaticMeshActor1295 → `StaticMesh=light_wall`,
`MaterialModifiers` present, trailer 12 bytes).

Pre-`54cac6e` re-export: **0 actor add/remove vs production**. Declared-only A/B that still *calls*
`MeasureStructArray`: same 14 missing. So the drop is from the unguarded measure, not from returning
`measure.Needed`.

## 2 added actors — improvement

| key | label | Array corrected | declared → needed |
|---|---|---|---|
| `DeadBodyContainer_DeadBodyContainer15_11245` | SteamRoomBody | `AnimatedMeshAttachments` | 153 → 155 (+2 Object size bytes, count 2) |
| `TV_WallMounted_TV_WallMounted0_8930` | SteinmanTele | `DamagedReactions` | 909 → 910 (+1, count 5) |

Without the correction the walk stops early (`DeadBodyContainer15`: properties end +235, trailer 300
bytes; `TV_WallMounted0`: end +979, trailer 449). `LevelAnalyzer` drops `Truncated` actors, so both
were absent from production and from the declared-only export. With the correction: full property
list, trailer 12–20 bytes, `AnimatedMeshAttachments` elements resolve (`Wig_BJ_ShortHair` / `BirdMask`
on sockets Wig/Mask), `DamagedReactions` unpacks five reaction structs including
`ReactionChangeMaterial` → `tv_broken`. The TV export really is class `TV_WallMounted` label
`SteinmanTele`; the body really is `DeadBodyContainer` / `Agg_BabyJane` / `SteamRoomBody`.

## 11 door-field changes — improvement

All eleven keep identity; only `door` changes. Pattern: class-default `Attachments` was empty or
absent in production; NEW fills it from the corrected defaults array.

| actors | attachment mesh(es) now present | defaults Array fix |
|---|---|---|
| 3× `BulkheadDoors` | `BH_Door` | Attachments 85 → 86 |
| 1× `HighRentDoorWide` | `High_Rent_Door` | 85 → 86 |
| 3× `LowRentDoorsWide` | `Low_Rent_Door` | 85 → 86 |
| 2× `MedicalDoor` | `MedDoorClosedPreview` (door object was absent → present) | MedicalDoor class Attachments uses Object size encoding 5 |
| 2× `ResurrectionStation` | `ResStationBody`, `ResStationDoorA`, `ResStationDoorB` | Attachments 277 → 280 (+3) |

Byte check: class `BulkheadDoors` defaults dump shows `Attachments` element
`StaticMesh → BH_Door` only after the +1 correction; declared-only A/B leaves `attachments: []` on
the placed actors (NEW vs AB diff = exactly these 11 doors + the 2 added actors). Matches the
existing note in `LevelAnalyzer.ReadDoorAttachments` that BioShock stores door meshes on the class
default, not the instance.

## Improvements vs regressions

**Improvements (keep / re-export once the regression is fixed):** the 2 newly present actors; the 11
door attachment fills (importer can place real door geometry / Vita-Chamber doors instead of empty
attachment lists).

**Regression (must fix before trusting a production re-export):** the 14 dropped actors — plain
Arrays must not let `MeasureStructArray`'s compact-index walk throw out of `Read`. Until that is
guarded, a Medical re-export is a net loss of placed meshes (vents, lights, photos, etc.).

## Confidence

- **CONFIRMED_BYTES** for the two added actors' Array shortfalls and the door-default Attachments
  shortfalls (instrumented declared/needed/objBytes; `properties --raw` element names).
- **CONFIRMED_BYTES** for the 14 removals' throw site (`ARRAYTHROW` property name + exception).
- Production `generator` field is only the string `BioShockStudio` (no commit hash); timing ties it
  to 25 Sep 2026, before `54cac6e`.

## Addendum (integrator, same day): after the measure-walk guard

The 14 dropped actors above came from `MeasureStructArray` letting an `FCompactIndex overflow`
escape; its catches now include `InvalidDataException` (with
`ArraySizeTests.MeasuringArraysNeverAbortsAPropertyRead`, confirmed failing on the unguarded
reader). Re-exporting 1-Medical with the guard loses nothing and **adds 442 actors** the production
manifest never had: 185 StaticMeshActor, 81 Light, 63 Brush, 15 ZoneInfo, 12 ShrubLarge, 9
PathNode, 8 Script (`Gatherer_Saved`, `SurgicalBlockageRemoved`, `GotBerserk`,
`EnableAI_SecondGathererSpawnVolume`, `SteinmanMachinegunCleanup`, `CasketFlip`, `LocalizedQuar`,
`RyanPA`), 5 PlacedGathererVent (7 -> 12), 4 InPlayerViewTrigger, 2 CubemapProbe, pickups, a
vending station and a resurrection station - plus 297 instances, 80 lights and 71 assets. 435 of
the 442 sit where no existing actor of the same class does (the other 7 are stacked static meshes
sharing a pivot). Every count now matches the package's own export table where checked: 31
CubemapProbe, 308 Script, 504 PathNode (tests re-pinned with that evidence). Their property lists
used to misalign on struct arrays the reader under-sized, and the analyzer dropped them.
