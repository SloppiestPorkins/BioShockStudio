---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: src/BioShockStudio.Cli/**, src/BioShockStudio.Core/**, tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Get the Wrench viewmodel rendering (it is a StaticMesh, not a skeletal rig)

User (in-editor, 5 Sept 2026), emphatic: "PLEASE look at the wrench and fix it. i want
the wrench." The Wrench weapon *works* (melee def resolves, damage 20) but is invisible
in first person — no mesh.

## Why it's still missing (confirmed, do not re-litigate)

`WP_Wrench` group in `Build/Final/BakedScripts/pc/ShockGame.U` contains only
`WP_WrenchMesh`, and that is a **`StaticMesh`** — no `UAPW_` / no `SkeletalMesh`. h3 and
h14 both correctly refused to substitute another asset. `export-firstperson Wrench` and
`import_weapon_meshes.py` only ingest skeletal FBX, so `UShockWeaponDef::MeshAssetPath`
for Wrench is deliberately empty.

The swing animation is NOT on the wrench — it comes from the ViewHands (NEWPlayerHands)
rig, same as every other first-person weapon. The wrench mesh just needs to be pinned to
the hands' grip socket and ride the hands animation.

## What already exists to build on

- `src/BioShockStudio.Core/Mesh/StaticMeshReader.cs` — `ReadGeometry(ReadOnlySpan<byte>)`
  returns a `MeshGeometry`. CONFIRMED to decode every StaticMesh export in `ShockGame.U`
  (see the class doc + `docs/research/staticmesh.md`). This is the decoder you need; do
  NOT modify it.
- `src/BioShockStudio.Core/Level/LevelScene.cs` ~line 400 already calls
  `StaticMeshReader.ReadGeometry` and its output flows through `FbxExporter` — so the FBX
  writer already handles a boneless `MeshGeometry`. Study how the level path turns a
  `MeshGeometry` (+ resolved material via `MaterialExporter.Resolve`) into an FBX and
  mirror the minimal version of that.
- `src/BioShockStudio.Cli/Program.cs` — `ExportFbx` (~line 1896) and its `ResolveMesh`
  helper (~line 719) are the skeletal path; `ResolveMesh` filters to
  `AssetClasses.SkeletalMesh` only. `swf-*`/`export-*` command dispatch is at the top
  (~line 40-75); usage text ~line 140-160.
- `BioShockPackage.Open` / `.Exports` / `.GetClassName` / `.ReadExportData` /
  `MaterialExporter.Resolve` — the primitives `ResolveMesh` already uses.
- `GameLocator.WeaponPackage(root)` resolves `ShockGame.U`.
- `AShockWeapon` (`tools/ue5/BioShockRuntime/.../ShockWeapon.h/.cpp`): has only
  `USkeletalMeshComponent* Mesh`. `ApplyDef` (~line 90) loads `Def->MeshAssetPath` and
  `Cast<USkeletalMesh>` — a StaticMesh path falls through silently today.
- `AShockPlayer::ResolveGripSocketForWeapon` (`ShockPlayer.cpp` ~line 253) and the equip
  flow that `AttachToComponent`s the weapon to the ViewHands socket. Grip alias pattern
  for `Launcher`/`Chem` is there — add `Wrench` the same way if the hands socket name
  differs from the def name (check with `probe_weapon_visuals.py` / the hands socket
  dump; BioShock's hands mesh may expose the wrench socket as `Wrench`, `R_Grip`, or
  similar — confirm, don't guess).

## What to do

1. **CLI**: add `export-staticmesh <package> <object> <out-dir>` to Program.cs (name it
   to match the existing verb style). Open the package, find the export whose
   `ObjectName` matches and `GetClassName == AssetClasses.StaticMesh`, `ReadExportData`,
   `StaticMeshReader.ReadGeometry`, `MaterialExporter.Resolve` for textures, and write an
   FBX + `ue5_manifest.json` into `out-dir` using the same exporter path the level
   importer uses for static props. Print the same "To import into Unreal…" hint
   `WriteFbx` prints. Add a usage line.
2. **Export the wrench** to a scratch dir under `%TEMP%/bioshock-h22-wrench/` (do NOT
   commit decoded game art — same rule as every other import).
3. **Python import**: add `tools/ue5/import_wrench_mesh.py` (mirror
   `import_weapon_meshes.py` structure) that imports that FBX as a UE5 `StaticMesh` to
   `/Game/BioShockWeapons/WP_Wrench/WP_Wrench` and its material/textures alongside, then
   sets `UShockWeaponDef`… no — the def is C++-baked, see step 4.
4. **C++**:
   - Give `AShockWeapon` a `UStaticMeshComponent* StaticMesh` subobject (child of the
     root, hidden until used).
   - In `ApplyDef`: if `MeshAssetPath` loads as a `UStaticMesh`, assign it to the new
     component, hide the skeletal `Mesh`, and use the static component as the visible
     viewmodel; otherwise keep today's skeletal behaviour.
   - In `ShockWeaponDef.cpp` Wrench branch (~line 139), set
     `Def->MeshAssetPath = FSoftObjectPath(TEXT("/Game/BioShockWeapons/WP_Wrench/WP_Wrench.WP_Wrench"))`
     and drop the "stays empty" comment (leave a one-line note that it's a StaticMesh
     viewmodel, gripped via the hands rig).
   - In the equip/attach flow (`ShockPlayer.cpp`), make whatever attaches
     `EquippedWeapon->Mesh` to the grip socket also handle the static-viewmodel case
     (attach the weapon actor — or its static component — to the resolved grip socket).
     Add the `Wrench` grip-socket alias if needed.
5. **Verify** (`verify_weapon_meshes.py` or a new `verify_wrench.py`, headless): assert
   Wrench resolves through the real `GiveWeaponByDef` path to a non-null **StaticMesh**
   on the new component, that the component is attached under the ViewHands grip socket
   after equip, and that the skeletal `Mesh` is hidden for the Wrench. Keep the existing
   `wrench=static_mesh_blocked` assertion? No — replace it with the positive assertion.

## Constraints

- Do NOT modify `StaticMeshReader.cs` or the SWF pipeline.
- Do NOT commit or push. Leave scratch under `%TEMP%`. Update `tools/ue5/README.md` with
  a dated entry once `rebuild_runtime_fast.ps1` passes.
- If `-CleanModule` is needed for the new UPROPERTY (stale UHT), the verify command is
  `powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1 -CleanModule`.
- Grip alignment / how it looks in-hand is a human PIE check afterwards — get it
  rendering and attached; say so explicitly rather than asserting "looks right".
- If the StaticMesh export genuinely won't decode or the FBX won't import, say exactly
  what failed (object name, class, byte offset / importer error) — do not fall back to a
  substitute mesh.
