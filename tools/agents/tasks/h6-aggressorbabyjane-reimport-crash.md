---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Forced reimport of AggressorBabyJane crashes UE with an int32 narrowing-conversion assertion

## Severity: the live project's character asset is currently broken

`Content/BioShockCharacters/AggressorBabyJane/AggressorBabyJane.uasset` is presently
**1.2 GB** and takes **over 2 minutes to load** (measured: `unreal.load_asset()` took
129.7 seconds). It should be a normal-sized character mesh asset. This happened as a
side effect of `h4-aggressor-babyjane-inverted-import`'s reimport attempt, which
crashed UE mid-import — the asset was left in whatever half-written state existed at
the moment of the crash. There is no backup; `Content/` is outside git by design (game-
derived data). **Recovering a healthy AggressorBabyJane is the actual goal of this
task** — the upside-down orientation from h4 is a real but secondary problem, address
it only once the asset loads normally again.

## The crash, reproduced three times, always identical

```
LogWindows: Error: appError called: Assertion failed: IntFitsIn<OutType>(In)
[File:.../Engine/Source/Runtime/Core/Public/Templates/UnrealTemplate.h] [Line: 170]
Loss of data caused by narrowing conversion, In = 2499805188
```

Same file, same line, **same exact value** (`2499805188`, ≈2.33 GiB) all three times,
across three different reimport attempts run this session (4 Sept 2026):

1. Full reimport (mesh + all 457 animations), the new Z-up/-Y-front normalizer from h4.
2. Full reimport (mesh + all 457 animations), the *original* Y-up normalizer — ruling
   out h4's axis change as the cause.
3. **Mesh + skeleton only, zero animations** (manifest's `animations` list emptied
   before running) — ruling out animation data as the cause too. This one still took
   about 9 minutes sitting at `LogSkinnedAsset: Waiting for skinned assets to be ready
   0/1 (AggressorBabyJane)` before crashing with the identical value.

That third result is the important one: **this is not about animations, and not about
axis normalization.** It reproduces on the mesh alone, during what looks like async
derived-data compilation for the skeletal mesh itself.

**The raw exported FBX is not the problem either** — confirmed by inspection:
`AggressorBabyJane.fbx` (the C# `export-fbx` output, before any Blender normalization)
is 404.7 KB; the Blender-normalized sibling is 491.5 KB. Both are entirely normal sizes
for a character mesh with no animations. Whatever produces a ~2.33 GiB value happens
**entirely inside Unreal's own import/compile pipeline**, not from oversized or
corrupted source data.

## Why this has never happened before

`import_bioshock.py`'s `reuse_existing=True` default skips reimport entirely when a
fingerprint match is found — which is presumably why AggressorBabyJane has sat
untouched (and apparently fine, until now) since it was first imported. `h4`'s
`run_reimport_aggressor_babyjane.py` sets `BIOSHOCK_FORCE_IMPORT=1`, which is very
likely the **first time this exact asset has ever gone through a full forced
reimport**. This looks like a pre-existing, latent bug in the import path (or possibly
a UE 5.7.4-specific issue with this mesh's particular data — bone count, socket count,
morph targets, whatever makes it unusual) that simply had never been exercised before.

## What to do

1. **Reproduce it yourself first**, with the exact command run this session (mesh-only
   is fastest to get to, ~9-11 minutes to crash — still slow, budget for it):
   ```
   $env:BIOSHOCK_REMASTERED_PATH = "G:\SteamLibrary\steamapps\common\BioShock Remastered"
   UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript ^
       -script=tools\ue5\run_reimport_aggressor_babyjane.py -unattended -nopause -nosplash
   ```
   (Export is already cached under `%TEMP%\bioshock-h4-aggressor-babyjane\` from this
   session — reuse it rather than re-exporting, `_ensure_export()` in that script
   already does this automatically.)
2. Read `_skeletal_mesh_options()` in `import_bioshock.py` (~line 55-90) and identify
   every `FbxSkeletalMeshImportData` / `FbxImportUI` option being set. Look for anything
   that could push the async skeletal-mesh compiler down a pathological path for this
   specific mesh: adjacency buffer generation, tangent/normal recomputation, morph
   target import, nanite settings for skeletal meshes if applicable to UE5.7, LOD
   generation. Try disabling/changing options one at a time rather than guessing a
   combination — this task needs to isolate which setting (if any) is responsible, not
   just find *a* combination that happens to avoid the crash.
3. If nothing in the import options explains it, consider whether this is a known UE
   5.7.4 engine bug (search release notes / issue tracker if accessible) triggered by
   something structural about this mesh (bone count? the "missing from bind pose"
   socket warnings already logged for `SOCKET_GutBlood`, `SOCKET_rose`, `SOCKET_Mask`,
   etc. — 14 sockets not vertex-weighted, might be relevant or might be a red herring,
   confirm rather than assume either way).
4. **Recovery is the priority over root-causing the engine internals.** If you can get
   a healthy AggressorBabyJane back — even via an import-option change whose *why* isn't
   fully understood — do that first and say clearly what's understood versus what's a
   working-but-unexplained mitigation. A correctly-sized, fast-loading, right-side-up
   character is the deliverable; a fully explained engine bug report is a bonus, not a
   requirement.
5. Once mesh+skeleton import cleanly, animations still need re-adding (457 of them,
   currently sitting untouched in
   `%TEMP%\bioshock-h4-aggressor-babyjane\AggressorBabyJane_Animations\` from the
   original export). Confirm whether the same crash risk applies to a full animation
   batch even with the mesh issue fixed — if it does, importing animations in smaller
   chunks rather than all 457 in one `import_bioshock.main()` call may be necessary; if
   the mesh fix resolves it entirely, say so.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only. This may only need Python
  changes (`import_bioshock.py`'s skeletal mesh import options); don't touch C++ unless
  the investigation genuinely points there.
- Every reimport attempt takes 9+ minutes and risks leaving the asset in a worse state
  if it crashes again — budget your attempts, don't brute-force many option
  combinations back to back without a hypothesis for each one.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once
  AggressorBabyJane loads correctly (report the load time and file size as evidence —
  both are cheap, fast checks that catch a regression immediately, unlike waiting to
  notice visually).
