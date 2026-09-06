---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/*.py, tools/ue5/BioShockImportTools/**, docs/research/**, tmp/**
---

# The first-person shotgun draws as a flat unlit green blob. Fix its textures.

The viewmodel architecture rework (`d256b09`, `docs/research/viewmodel.md`) landed and the
shotgun now attaches correctly to the `Launcher` socket with the hands posing around it. But the
**mesh itself renders as a flat green shape with no detail** — see
`../BioShockHavok-agent-v1-viewmodel-match-bioshock/runs/v1-viewmodel-match-bioshock/3_shotgun_idle.png`.

Root cause is almost certainly the textures. On disk:

```
Content/BioShockWeapons/WP_Shotgun/Textures/Shotgun_NoUpgrades_Diffuse.uasset   10688 bytes
Content/BioShockWeapons/WP_Shotgun/Textures/Shotgun_NoUpgrades_Normal.uasset     9944 bytes
Content/BioShockWeapons/WP_Shotgun/Textures/Shotgun_NoUpgrades_Specular.uasset  10939 bytes
```

vs a healthy weapon (Pistol): `Pistol_DIFF.uasset` is **5.2 MB**. The shotgun's are ~10 KB —
empty / 4×4 placeholder mips. The material samples black → unlit base colour → the green you see
is just scene light on a flat surface.

## Investigate

1. **Why did the shotgun texture export come out empty?** The clean weapon re-import on 6 Sept
   (`export-fbx UAPW_WP_Shotgun --mesh WP_ShotgunMesh`, ~16:44) produced these stubs. Check:
   - What does `dotnet run --project src/BioShockStudio.Cli -c Release -- export-fbx UAPW_WP_Shotgun --mesh WP_ShotgunMesh`
     write for the material/texture sidecar? Compare to `UAPW_WP_Pistol`.
   - Are the source texture names right? `Shotgun_NoUpgrades_Diffuse` vs what the `.upk` / mesh
     material actually references. The shotgun has upgrade variants (`_NoUpgrades`, `_Damage`,
     `_RateOfFire`) — the base-game first-person shotgun uses the `_NoUpgrades` set.
   - Is the texture a format the decoder chokes on silently (writes a stub, logs nothing)? Check
     `src/BioShockStudio.Core` texture reader against the shotgun diffuse's pixel format.
   - `tmp/uc_shockgame/Shotgun.uc` + the shotgun `.upk` package for the real material/texture
     asset names.
2. `docs/research/materials.md`, `docs/research/textures.md`, `docs/research/flat-textures.md`,
   `docs/HANDOFF.md` §Landmines for known texture-import failure modes.

## Fix

Re-export + re-import the WP_Shotgun textures (and material instance if needed) so the
first-person shotgun renders with its real receiver/wood/metal detail — the gold "TIGER"
engraving on the receiver should be legible, like the user's reference screenshot. Scope to
`WP_Shotgun` only; do not re-import other weapons or touch the runtime.

## Constraints

- Editor CLOSED for headless ops (`tasklist //FI "IMAGENAME eq UnrealEditor.exe"` → 0). Kill
  stray `UnrealEditor-Cmd` / `dotnet` / `BioShockStudio.Cli` between runs (a leftover CLI proc
  locks `BioShockStudio.Core.dll` → next `dotnet run` silently no-ops, MSB3027).
- `-run=pythonscript` swallows `unreal.log`; write probe output to JSON.
- MSYS: forward-slash Windows paths + `export MSYS_NO_PATHCONV=1`.
- Do NOT commit. Do NOT add a `docs/HANDOFF.md` claim-table row. Leave the diff for review.

## Deliverable

The fix (import-script / decoder change + the re-import command run), a note in
`docs/research/viewmodel.md` §6 or a short `docs/research/` entry on the root cause, and a fresh
`-bioshockstartslot=3` capture (via `tools/ue5/capture_shot.ps1`) showing the shotgun with real
textures. Report walks through the root cause and shows before/after.
