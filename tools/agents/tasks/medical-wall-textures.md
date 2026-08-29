---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Diagnose and fix the broken wall textures on the `1-Medical` UE5 playable slice.

## Symptom
Human PIE on `1-Medical` on 29 Aug 2026 showed wall/architecture surfaces rendering wrong —
`docs/NEXT_SESSION.md` "Resume here" calls it "wall textures broken"; `docs/HANDOFF.md` Active
work row calls it "unbuilt-lighting walls". Prior sessions flagged it but never pinned the cause.
Decide from evidence whether this is (a) missing/incorrect material or texture bindings on the
imported level, (b) unbuilt static lighting / Lightmass making lit surfaces read as black/flat,
(c) a PIE-only lighting/exposure setup problem, or (d) something else. Do not guess — measure.

## Environment (this machine)
- UE 5.7 engine: `G:\Games\UE_5.7\`
- Throwaway project (outside the repo): `C:\Users\Jack\Documents\BioShockUE5\`
  - `BioShockUE5.uproject`
  - `1-Medical` imported at `Content/BioShockLevel/1-Medical/` (has a `Materials/` folder of
    `MI_Medical_*` material instances)
  - `Plugins/BioShockRuntime/Binaries/Win64/UnrealEditor-BioShockRuntime.dll` is already built —
    the editor loads. You do NOT need to rebuild C++.
  - **Do NOT run `tools/ue5/rebuild_runtime_fast.ps1`** — `PluginBuild/BioShockRuntime/HostProject`
    is missing and it will throw. If you genuinely need a C++ change (you probably don't for a
    texture/lighting bug), stop and write that up instead.
- Latest editor/PIE log: `C:\Users\Jack\Documents\BioShockUE5\Saved\Logs\BioShockUE5.log`
  (older ones alongside it). Grep it for `LogTexture`, `LogMaterial`, `Warning`, `Error`,
  `Missing`, `Failed to load`, `LogTextureCompressor`, `LogStaticLightingSystem`, `needs to be
  rebuilt`, `LIGHTING NEEDS TO BE REBUILT`.
- Headless UE Python is the tool for inspection:
  `& 'G:\Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor-Cmd.exe' "C:\Users\Jack\Documents\BioShockUE5\BioShockUE5.uproject" -run=pythonscript -script="<abs path to a .py you write under tools/ue5/>" -unattended -nop4 -nosplash`
  Evidence rule from ENGINEERING_RULES: `unreal.log()`/`print()` under `-run=pythonscript` is NOT
  reliable — assert with `Success - N error(s)` / raise `RuntimeError` on failure, and write your
  findings to a file you then read.

## What to produce (all under tools/ue5/**)
1. A reusable inspection script, e.g. `tools/ue5/audit_level_materials.py`, that for a given map
   loads every `StaticMeshActor` / BSP model in the level and reports, as a written report file:
   per material slot — the material/instance asset, whether it resolves, its base-colour/normal
   texture parameters, whether each bound texture asset exists and is non-default, and any slot
   left on `WorldGridMaterial` / `DefaultMaterial`. Run it on `1-Medical`.
2. A short PIE screenshot helper, e.g. `tools/ue5/capture_pie_shot.py`, that starts PIE on a given
   map, waits a few frames, writes a screenshot (`HighResShot` or
   `unreal.AutomationLibrary.take_high_res_screenshot`) to `tools/ue5/_shots/<map>-<stamp>.png`,
   and exits. Capture one shot of the broken wall area on `1-Medical`. (Add `tools/ue5/_shots/`
   to `.gitignore` — the PNGs are not committed.)
3. `docs/NEXT_SESSION.md` "Resume here" and the `docs/HANDOFF.md` Active-work row: update the
   wall-texture line with the diagnosis and confidence label.
4. The actual fix, if it is small and clearly correct and lives in `tools/ue5/**` (e.g. an
   `import_level.py` / import-policy change, a lighting-import fix, a PIE fill-light/exposure fix
   in the runtime Python, a "build lighting on import" step). If the root cause is in the C#
   exporter (`src/**`) — bad material or texture data coming out of `export-level` — do NOT touch
   `src/**`: write the precise hand-off (which asset, which field, expected vs actual bytes) into
   `docs/HANDOFF.md` Active-work as a new row for the Claude Code lane, and stop.

## Constraints
- Stay entirely inside `tools/ue5/**` (plus the two doc files named above). Do not touch `src/**`
  or `tests/**`. Do not commit, do not push.
- Smallest correct change. `DISCOVER → VERIFY → RECORD → DEFER → CONTINUE`. Label every claim
  `CONFIRMED_BYTES` / `PLAUSIBLE` / `UNKNOWN`.
- If PIE cannot be launched headless on this setup, say so explicitly in the report and fall back
  to the static asset + log audit — that is still a valid result.
