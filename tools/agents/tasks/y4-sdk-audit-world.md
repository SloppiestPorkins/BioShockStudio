---
worker: cursor
base: main
verify: git status --short
lane: docs/research/**
---

# y4-sdk-audit-world: SDK cross-reference audit — Chapters 06-19 and 33-36 (mapping guidelines, BSP, zones/portals, actors/properties, static/skeletal meshes, doors stub, materials/textures, lighting, water/fluids, sound stub, visual effects, build/bake, retail maps, UCC/packages, asset import, commandlets, troubleshooting)

> **Run mode:** non-interactive. This is a READ-AND-REPORT audit: change NO code. Do NOT launch
> Unreal, do NOT build, do NOT touch `C:\Users\Jack\Documents\BioShockUE5` (shared live project).
> Do NOT commit. Your only output is ONE new markdown file (named below) plus a short RESULT note.

## What this is

BioshockHavok is a UE5.7 port of BioShock 1 Remastered (repo = your worktree; runtime plugin in
`tools/ue5/BioShockRuntime/Source/BioShockRuntime/{Public,Private}`, importers/verifies in
`tools/ue5/*.py`, C# extractor in `src/BioShockStudio.Core` + `src/BioShockStudio.Cli`, research notes
in `docs/research/*.md`). The runtime was built from decompiled UnrealScript. A real BioShock SDK
guide (a 38-chapter document written by the SDK's users) is now available. It is ground truth for
how the original systems behave. Your job: **cross-reference the guide chapters listed below
against what we actually built, and find every place they disagree or that we never built.** In a
prior pass this method found real bugs (e.g. `ActionWaitForGoal` returning the wrong code for a
missing goal, `ActionExitScript` ignoring its target, a Health Station charging an invented
scaled price instead of a flat 16/10, hack failures able to kill the player, a security subsystem
that never ticked outside tests). Find more of that class: **silently wrong, not just missing.**

## Where the guide is (READ-ONLY, outside the repo)

`C:\Users\Jack\AppData\Local\Temp\claude\C--Users-Jack-Documents-AI-Test\c7be037f-fb45-4801-8732-1d5df17a8bb3\scratchpad\unrealed-guide-mirror` — one `NN-Title.md` per chapter. Read the chapters assigned to you IN FULL, not by grep.

## COPYRIGHT — hard rule

The guide has no licence and this repo is PUBLIC. **Never copy or closely paraphrase the guide's
prose into the repo.** Facts are fine (a field name, an enum value, a number, a return code, a
class relationship, "X happens when Y"); sentences are not. Write everything in your own words,
cite by chapter number + section heading only, and keep any quoted phrase under ~8 words. Do not
copy tables or ini listings.

## How to audit

For every mechanic/number/field/behaviour a chapter states, locate the implementing code (or
confirm none exists) and READ it. Do not assume; do not trust comments in our code or old docs
(`docs/research/*.md` are hypotheses — several were already wrong). Classify each item:

- **BUG** — we implemented it and behaviour contradicts the guide.
- **GAP** — the guide describes a mechanic/field we have not built or only partly built.
- **OK** — verified match (list briefly; proves you looked).
- **UNKNOWN** — cannot tell without running the game / data we don't have.

Already fixed this session (do NOT re-report): ActionSetProperty `enabled`/`Disabled` routing,
ActionWaitForGoal no-goal=0, ActionExitScript TargetScript, message-class names + `scriptMessageClass`
gating + real senders for PawnDied/TookDamage/ReceivedInventory/AIWeaponFired/trigger enter-exit,
security subsystem tick + 60 s alarm expiry, hack-failure non-lethal cap, Health Station 16/10.
Known open, don't re-report as new: `messageFilter` decoding, switch/grate interact paths,
LootTables.ini weighted rolls, spawn-manager/archetype system, EffectsSystemContext per-actor
semantics, ActionToggleAIReactions 7 of 9 switches, ActionSpawnAI missing fields, Gatherer ecology.

## Output

Write `docs/research/sdk-crossref-world.md` with:
1. A one-paragraph summary + counts (BUG / GAP / OK / UNKNOWN).
2. **BUG table first**, ordered by player-visible impact: `id | what the guide says (your words) |
   guide ref (chapter + heading) | our code (file:line) | what we do instead | proposed fix | effort S/M/L`.
3. GAP table, same columns (no "what we do instead").
4. OK list (one line each).
5. UNKNOWN list with what would resolve each.
Be specific and verifiable — every BUG needs a file:line a reviewer can open in seconds.

## Your chapters (read every one fully)

- `06-BioShock-Mapping-Guidelines.md`
- `07-BSP-Geometry.md`
- `08-Zones-and-Portals.md`
- `09-Actors-and-Properties.md`
- `10-Static-Meshes.md`
- `11-Skeletal-Meshes-and-Animation.md`
- `12-Doors.md`
- `13-Materials-and-Textures.md`
- `14-Lighting.md`
- `15-Water-and-Fluids.md`
- `16-Sound-and-Music.md`
- `17-Visual-Effects.md`
- `18-Build-Save-Bake-and-Play.md`
- `19-Working-with-Retail-Maps.md`
- `33-UCC-and-Script-Packages.md`
- `34-Importing-Assets-with-UCC.md`
- `35-UCC-Commandlet-Reference.md`
- `36-Troubleshooting.md`

## Where to look in our code

Our side: the C# level/asset extractor (`src/BioShockStudio.Core/{Level,Materials,Textures,Mesh,Export,Config,Audio}`), the UE5 importers (`tools/ue5/import_level.py`, `import_bioshock.py`, `import_slice_*.py`, material/light/water/decal authoring scripts), and runtime rendering/world code (`ShockWaterVolume`, `ShockOilSlickVolume`, lighting/ambient, zone and pressure handling in `ShockPlayer`/scripts, `ShockAudioLibrary`, `ShockEffectsSubsystem`, `ShockDoor`). Focus on how the original engine INTERPRETS data we import: zone ambient/lighting presets and how light properties (type, brightness, radius, flicker/pulse, bake vs dynamic) map to ours; material/shader classes and their slots (which our importer might mishandle or drop); water/fluid volume behaviour and caustics; pressure regions; the ready-made effects and decal projectors; door/mover data; known limits and troubleshooting entries that explain symptoms we have seen (grey walls, untextured meshes, missing decals, lighting differences — see `docs/research/fidelity.md` and `docs/ENGINEERING_RULES.md` for our own symptom history). Chapters that are pure editor-UI how-to with no data/behaviour content can be marked N/A in one line.
