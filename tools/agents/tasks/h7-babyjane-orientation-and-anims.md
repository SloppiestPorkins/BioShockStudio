---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# AggressorBabyJane: fix orientation, bring back animations, fix the secondary reimport crash

## Where things stand (4 Sept 2026, all measured live this session)

h6's mitigation (delete mesh/skeleton/physics before reimport; `AssetImportTask.save=False`
+ explicit `save_loaded_asset`) **worked** — the asset corruption from h4's crash is fixed:

| | Before h6 | After h6 (mesh-only) |
|---|---|---|
| `AggressorBabyJane.uasset` size | 1.2 GiB | **1.14 MiB** |
| Load time | 129.7 s | **0.011 s** |
| `verify_aggressor_babyjane_health.py` | fail | **ok** |

Two things are still open, run in this order:

## 1. Orientation is still wrong (do this first — cheap to check, blocks nothing else)

`run_test_arena_verify.py` against the live `/Game/BioShockSlice/TestArena` map, right
after the h6 mesh-only recovery, still reports:

```
Enemy_Melee / Enemy_Ranged_A / Enemy_Ranged_B: headZ-feetZ = -124.6 (mesh) / -136.0 (log)
```

Same magnitude as before h4's Z-up/-Y-front normalizer fix. That normalizer is applied
during `_normalize_fbx()`, upstream of the actual UE import — confirm it actually ran as
part of this recovery (check `%TEMP%\bioshock-h6-aggressor-babyjane-mesh-only\` or
wherever the mesh-only manifest pointed for a `_ue5_normalized` sibling next to the FBX,
and check its timestamp/existence) before concluding the axis fix itself is wrong. It's
equally possible the mesh-only recovery path skipped normalization somehow, or normalized
correctly but the actual bind-pose inversion has a different cause than axis convention
(h4's own patch already anticipated this — it logs a warning and does not guess a
compensating rotation for exactly this reason). Investigate for real, don't assume either
direction.

## 2. The reimport crashes on a secondary step, after the mesh already saved successfully

Same `run_reimport_aggressor_babyjane.py` (`BIOSHOCK_MESH_ONLY=1`) run that produced the
healthy 1.14 MiB mesh above **still crashes** before exiting cleanly:

```
LogLinker: Warning: [AssetLog] .../AggressorBabyJane_Skeleton.uasset: Error opening file.
(repeated twice)
Script Stack (1 frames): /Script/EditorScriptingUtilities.EditorAssetLibrary.LoadAsset
LogWindows: Error: appError called: Assertion failed: !bHasFailed
[File: .../CoreUObject/Private/Serialization/AsyncLoading2.cpp] [Line: 1426]
```

This happens *after* `Recreating bind pose succeeded`, skinned-asset compilation, and
texture import all complete — the mesh and skeleton are already correctly built and (per
the health check above) already saved to disk healthy by this point. Something *later*
in `import_bioshock.py`'s flow calls `unreal.EditorAssetLibrary.load_asset(...)` on the
`AggressorBabyJane_Skeleton` path and gets "Error opening file" — most likely because
`AssetImportTask.save=False` means the asset isn't written to disk at the moment
something tries to re-load it by path rather than using the in-memory object reference
already returned from the import task. Find that call site (a good place to start:
anything between `_import()` returning and the end of the per-rig loop that re-fetches
the skeleton or mesh via `load_asset`/`does_asset_exist` instead of using the `mesh`/
`skeleton` variables already in hand — `_restore_manifest_sockets` is one candidate,
check what it does with its `mesh` argument). Fix by using the already-in-memory object,
or by ensuring `save_loaded_asset` runs before any such reload.

This crash did not prevent recovery this time (mesh-only import happened to finish and
save before the crash), but it means the process still exits with an error and needs
manual "did it actually work" checking — and it will matter once animations import
proper (more work happening after the mesh save, more chances for the same reload-before-
save race to hit something that isn't already safely on disk).

## 3. Bring back the 457 animations

Currently untouched from the original export, sitting at
`%TEMP%\bioshock-h4-aggressor-babyjane\AggressorBabyJane_Animations\` (or wherever the
mesh-only recovery's export root ended up — confirm the path). They were authored
against the *old* Skeleton object, which h6's delete-first step removed and recreated —
confirm whether AnimSequences re-bind to the new Skeleton asset cleanly (same package
path, but Unreal may treat it as a different object identity) or whether they need
re-importing too. Only attempt this once #1 and #2 above are resolved — do not risk the
now-healthy mesh on a large animation batch while the secondary crash is still
unexplained. If a full 457-animation import risks the same crash class, chunk it (e.g.
50 at a time) rather than one `import_bioshock.main()` call for all of them, and say
whether that was actually necessary or the h6 fix already covers it.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only.
- The asset is healthy right now — do not risk it on a speculative fix. Reproduce,
  understand, then change. If an attempt makes things worse, stop and report rather than
  trying a second speculative fix on top.
- No live UE session in this worktree — headless assertions
  (`GetMeshUprightDeltaForVerify`, `verify_aggressor_babyjane_health.py`) are the
  evidence; a human confirms the actual look in the editor afterward.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once verified.
