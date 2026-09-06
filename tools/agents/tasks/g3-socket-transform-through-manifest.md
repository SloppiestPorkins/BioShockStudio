---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: src/BioShockStudio.Cli/**, src/BioShockStudio.Core/**, tests/**, tools/ue5/import_bioshock.py, tools/ue5/BioShockImportTools/**, tools/ue5/import_weapon_meshes.py, tools/ue5/run_import_weapon_meshes.py
---

# Carry each SkeletalMesh socket's transform all the way into the created UE socket

## Why

`MeshSocket.Transform` is fully decoded from the shipped bytes
(`src/BioShockStudio.Core/Mesh/SkeletalMeshReader.cs` — 33/33 sockets decode to an
orthonormal frame, `CONFIRMED_BYTES`). It then gets **dropped three times** on the way to
Unreal, so every imported UE socket ends up identity-on-bone:

1. The `ue5_manifest.json` writer emits each socket as `{ "name", "bone" }` only — no
   translation/rotation. (Confirmed: `Exports/Crossbow/ue5_manifest.json` →
   `rigs[].sockets[]` entries are name+bone.)
2. `tools/ue5/import_bioshock.py::_restore_manifest_sockets` reads only `item["name"]` and
   `item["bone"]`.
3. `tools/ue5/BioShockImportTools/.../BioShockSocketLibrary.cpp::RestoreSockets` takes only
   `TArray<FName> SocketNames, TArray<FName> BoneNames` and never sets `RelativeLocation` /
   `RelativeRotation` on the `USkeletalMeshSocket`.

Effect: the first-person "Wrench" socket carries ~180° in the game data, the "Pistol"
socket is identity — but after import both are identity, so the static wrench and several
props sit at the wrong orientation/offset. `AShockPlayer::AlignEquippedWeaponRootToGripSocket`
and a hand-tuned `ShotgunRot`/`ShotgunOff` in `ShockPlayer.cpp` are compensating per-weapon
for what should be one general fix.

The AnimationScene path (`AnimationSceneExporter.ToSceneSocket`) ALREADY writes
`Translation`/`Rotation` into `SceneSocket` — use that as the reference for basis/units. The
`ue5_manifest.json` path is the one missing it.

## What to change

### 1. C# — emit the transform in `ue5_manifest.json`

Find the writer that produces `ue5_manifest.json`'s `rigs[].sockets[]` (it is the
`export-fbx` / weapon-mesh manifest path driven from `src/BioShockStudio.Cli/Program.cs`
around `ResolveMesh` at line 729, which already returns `IReadOnlyList<MeshSocket>`). Add
two fields to each socket object:

```json
{ "name": "Wrench", "bone": "R_Grip",
  "translation": [x, y, z],
  "rotation": [x, y, z, w] }
```

- `translation` in **centimetres, internal basis** (the same basis + unit as the bone
  `translation` already written elsewhere in the manifest — match it exactly, do not invent
  a conversion).
- `rotation` as a quaternion `[x, y, z, w]`, same handedness as the bone `rotation`.
- Decompose `MeshSocket.Transform` with `Matrix4x4.Decompose`; on failure, **omit both
  fields** (do not write identity — absence must stay distinguishable from "measured
  identity", exactly as `ToSceneSocket` does).
- Keep `name` and `bone` exactly as they are. Additive change only.

Add or extend a unit test in `tests/` that builds a `MeshSocket` with a known non-identity
transform, runs it through the manifest writer, and asserts the emitted `translation` /
`rotation` round-trip. Reuse whatever fixture the socket-decode tests already use. `dotnet
test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast` must stay
green.

### 2. C++ — apply it in `RestoreSockets`

`tools/ue5/BioShockImportTools/Source/BioShockImportTools/Private/BioShockSocketLibrary.cpp`
(+ the `.h`). Add an overload / extra params so a transform can be passed per socket, e.g.

```cpp
static int32 RestoreSockets(
    USkeletalMesh* Mesh,
    const TArray<FName>& SocketNames,
    const TArray<FName>& BoneNames,
    const TArray<FVector>& RelativeLocations,   // cm, UE left-handed Z-up
    const TArray<FRotator>& RelativeRotations); // degrees
```

Set `Socket->RelativeLocation` and `Socket->RelativeRotation` from the arrays when they are
provided and the same length; when an entry is absent (arrays shorter, or a sentinel), leave
the socket on its bone as today. Keep the existing 3-arg form working (call the new one with
empty arrays) so nothing else that calls it breaks. Bump the `.uplugin` / rebuild the editor
plugin as the existing build step does.

### 3. python — pass the transform through

`tools/ue5/import_bioshock.py::_restore_manifest_sockets` (and the `rig["sockets"]`
projection near line 919 / the `BioShockSockets` metadata near line 1113): read the new
`translation` / `rotation` keys when present, convert **internal basis (cm) → UE basis
(cm, Z-up, left-handed)** using the SAME conversion `import_bioshock` already applies to
bone transforms elsewhere in the file (find it — do not write a fresh one), convert the
quaternion to an `FRotator`, and pass them to the new `RestoreSockets` signature. When the
keys are absent, call it the old way. Keep the `PistolBody` guard (line 234) as-is.

## Re-export + re-import + verify

After the code builds:

1. Re-run `tools/ue5/run_import_weapon_meshes.py` (it wraps `export-fbx ... WP_* --mesh
   WP_*Mesh` then imports) for at least `WP_Shotgun` and the hands rig
   `UAPW_NEWPlayerHands`, so the new manifest + socket transforms land in
   `/Game/BioShockWeapons/NEWPlayerHands` and the weapon meshes. Editor must be closed for
   the headless import (`tasklist //FI "IMAGENAME eq UnrealEditor.exe"` returns 0).
2. Capture the wrench and pistol viewmodels and LOOK at them:
   `powershell -Command "& tools/ue5/capture_shot.ps1 -Out <tmp>/g3_wrench.png -SettleTicks 16 -Extra @('-bioshockstartslot=0')"`
   and `-bioshockstartslot=1` for the pistol. The wrench must still be held by the handle
   with the head up-forward (it currently is, via a 180° yaw hack in
   `AShockWeapon::ApplyDef` — commit `35f459c`); the pistol must still point forward, not
   back over the forearm.
3. Save both PNGs into `runs/g3-socket-transform-through-manifest/` and describe what you
   see in your final report — the reviewer will judge them.

## Do NOT

- Do not remove the `35f459c` wrench-yaw hack or the `ShockPlayer.cpp` `ShotgunRot`/
  `ShotgunOff` defaults in THIS task — a follow-up will retire them once the socket
  transforms are confirmed landing. Removing them now risks a double-correction.
- Do not touch `AShockPlayer` / `AShockWeapon` / anything under
  `tools/ue5/BioShockRuntime/**`.
- Do not add a claim-table row to `docs/HANDOFF.md`.
- Do not commit. Leave the diff for review.
