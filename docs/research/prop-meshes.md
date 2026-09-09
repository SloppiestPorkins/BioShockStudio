# Prop meshes for the slice pickups / containers / movers / stations

`docs/FULL_RUNTIME_PORT.md` R0.1. Before this pass the slice had 284 `/Engine/BasicShapes`
placeholder meshes; w10/w11/w3 placed `AShockConsumablePickup` / `AShockSearchableContainer` /
`AShockAnimatedProp` / `AShockStationBase` actors carrying a marker sphere because the real
BioShock prop meshes were never imported into slice content.

## Pipeline

1. `export_slice_prop_meshes.ps1` (dotnet, editor closed) — `export-staticmesh 1-Medical <name>`
   for the 31 mesh names that the manifest `staticMesh` field puts on those actors. Writes
   FBX + `ue5_manifest.json` (materials + diffuse/normal textures resolved from the map `.bsm`).
2. `import_slice_prop_meshes.py` (STEPS, before the placement steps):
   - The CLI's FBX trips UE5.7's legacy reader ("File is corrupted") and the Interchange path
     asserts on Slate under `-run=pythonscript`. So: **Blender-normalise** each FBX
     (`import_bioshock._normalize_fbx`), then import with a legacy `FbxImportUI` task
     (`import_as_skeletal=False`, `original_import_type=FBXIT_STATIC_MESH`).
   - Import the diffuse (sRGB) + normal (`TC_NORMALMAP`) PNGs with an explicit
     `unreal.TextureFactory()` (also bypasses Interchange/Slate).
   - Build a `MaterialInstanceConstant` off
     `M_BioShock_Shader_alan_metal_mat_opaque_V5` (params `BaseColor` / `Normal` / `Roughness`),
     bind the two textures, assign to every mesh slot.
   - `CTF_USE_COMPLEX_AS_SIMPLE` on the body (the slice-wide policy).
   - `save=False` on every task; `EditorAssetLibrary.save_loaded_asset` afterwards (the task
     save path prompts for checkout → Slate assert headless).
3. `import_slice_pickups` / `_stations` / `_animated_props` re-run and resolve the real mesh
   via `_load_mesh` (checks `/Game/BioShockSlice/Content/Meshes/<name>`); `SetPickupMesh` /
   `SetContainerMesh` reset the marker scale to 1.

## Result (9 Sept)

`/Engine/BasicShapes` on pickup/container/mover/station actors: **284 → 0**. The 67 remaining
`/Engine/BasicShapes` in the slice are `AShockDoor` DoorBlocker boxes (40) and
`AShockWaterVolume` surface planes (27) — deliberately invisible proxies, not eyesores.

27 of 31 meshes got real diffuse+normal. 4 (`PU_TommyGunMESH`, `Pickup`, `WP_AI_Pistol`,
`tommygun_ammo_*`) had no material in the export — the same weapon-def / rig import path that
leaves 22 decoration `StaticMeshActor`s (`SecCameraSmall`, `Resurrection`, Steinman `banner*`,
`Model1`) with null slots. Those get the master material (flat, no texture) here and are the
**R0.2** task (export + bind their real materials from the `.bsm`).

`MedHypoPickup` has no `staticMesh` in the manifest — `_MESH_FALLBACK` in `import_slice_pickups`
maps it to `Med` (the EVE-hypo syringe mesh).

Corpse / booty containers (`DeadBodyContainer`, `*Booty`) carry no mesh — the ragdoll body is a
separate actor — so `SetContainerMesh(nullptr)` hides the component; the w10 interaction trace +
"Press F to search" prompt is how the player finds them.

## Verify

`verify_prop_meshes.py`: 0 *visible* pickup/container/mover/station actors on a marker sphere.
