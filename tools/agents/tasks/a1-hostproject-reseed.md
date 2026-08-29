---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Re-seed the BioShockRuntime HostProject so `tools/ue5/rebuild_runtime_fast.ps1` works again,
and add a small idempotent seed script so this never becomes a silent blocker.

## Why
`tools/ue5/rebuild_runtime_fast.ps1` throws:
`HostProject missing at C:\Users\Jack\Documents\BioShockUE5\PluginBuild\BioShockRuntime\HostProject`
Every Phase 4 C++ task (`ShockAction*.cpp`) is blocked until an incremental rebuild works again.
The runtime DLL currently in the project
(`C:\Users\Jack\Documents\BioShockUE5\Plugins\BioShockRuntime\Binaries\Win64\UnrealEditor-BioShockRuntime.dll`)
loads fine — only the *rebuild* path is broken.

## Environment
- Engine: `G:\Games\UE_5.7\` (RunUAT at `Engine\Build\BatchFiles\RunUAT.bat`)
- Plugin source of truth: `tools/ue5/BioShockRuntime/` (uplugin + Source/)
- Throwaway project: `C:\Users\Jack\Documents\BioShockUE5\`
- `rebuild_runtime_fast.ps1` expects: `$UeProject\PluginBuild\BioShockRuntime\HostProject\HostProject.uproject`
  with a warm `Intermediate\`. Read that script in full first — match exactly what it expects.

## Do
1. Add `tools/ue5/seed_hostproject.ps1`: runs `RunUAT BuildPlugin` for `BioShockRuntime` into a
   layout that leaves `PluginBuild\BioShockRuntime\HostProject` in place (the flag that keeps the
   host project, e.g. `-NoHostProjectCleanup` / equivalent for UE 5.7 — verify against the engine's
   RunUAT source, do not guess). Idempotent: if a valid HostProject already exists and no source
   changed, print that and exit 0. `-ExecutionPolicy Bypass` friendly, PS 5.1.
2. Run it. Then run `tools/ue5/rebuild_runtime_fast.ps1` and confirm it completes and copies a
   fresh `UnrealEditor-BioShockRuntime.dll` into the live project. Capture the timing.
3. Update `rebuild_runtime_fast.ps1`'s "HostProject missing" throw to point at
   `seed_hostproject.ps1` by name, and update the `docs/NEXT_SESSION.md` "Resume here" line that
   says `PluginBuild/HostProject is currently missing ... will throw until re-seeded`.
4. Brief note in `tools/ue5/README.md` on when/how to reseed.

## Constraints
- `tools/ue5/**` and the one `docs/NEXT_SESSION.md` line only. No `src/**`, no `tests/**`.
- Do not commit, do not push. Scratch/build logs to `$env:TEMP`, not the worktree.
- If RunUAT genuinely cannot produce a reusable HostProject on this engine version, say so
  explicitly in the result and leave `seed_hostproject.ps1` doing the closest working thing
  (even if that is a full BuildPlugin every time) with a comment explaining why.
- Fast tier must stay green (you are not touching C#).
