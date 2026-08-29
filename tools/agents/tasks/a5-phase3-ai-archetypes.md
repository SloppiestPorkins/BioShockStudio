---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase 3 depth: populate `AShockAI` spawn parameters from the decoded AI-archetype data instead
of hand-authored defaults, for the `1-Medical` slice.

## Context (`docs/UE5_FULL_PORT_PLAN.md` §5 Phase 3, §9 "AI-archetype system — decoded")
The C# side already decodes archetypes: `AiArchetypeCatalog` / `AiArchetypeTests`, all 267
shipped `AIArchetype` exports parse. The level manifest carries them as `document.archetypes`
(commit `b5a5520`) — per archetype: `AIType` (`Class<ShockAI>` name), `Mesh`, `Health` /
`FrozenHealth`, resistances (`DamageResistanceSetName` → `Weapons.ini`), chance-weighted
loadout slots. Spawners carry `OverriddenAiArchetypeNames` + `*AiTypes`.

Right now `AShockAI` / the spawner path use hand-authored values. This task makes the spawn
read the real archetype record.

## Do
1. A `UShockAiArchetype` `UDataAsset` (or `USTRUCT` table row — match how this project already
   models imported data; check existing `U*DataAsset` / import patterns): `ArchetypeName`,
   `AITypeClassName`, `MeshPath`, `Health`, `FrozenHealth`, `DamageResistanceSetName`, and the
   resolved loadout slot list. Keep it a faithful mirror of `document.archetypes` — no invented
   fields.
2. A headless import step `tools/ue5/import_ai_archetypes.py` (+ `run_` driver) that reads a
   level manifest's `document.archetypes` and creates/updates one archetype asset per entry in
   the throwaway project, idempotently (fingerprint like `import_bioshock.py` does). Run it for
   `1-Medical`.
3. Wire the spawn path: when `ShockGameMode` / the spawner spawns an `AShockAI` for a labeled
   archetype, set Health / FrozenHealth / mesh / AIType from the archetype asset rather than the
   hardcoded default. Keep the change minimal and behind the archetype lookup — a missing
   archetype falls back to today's behaviour, not a crash.
4. `verify_ai_archetypes.py` (+ driver): assert the 1-Medical archetype assets exist, that their
   Health/Mesh match `document.archetypes` from a fresh `export-level`, and that a spawned
   `AShockAI` for `Agg_BabyJane` (the slice's existing enemy) picks up its archetype Health.
   Report `Success - N error(s)`.
5. `docs/UE5_FULL_PORT_PLAN.md` §9: dated line on what Phase 3 now reads from data.

## Constraints
- `tools/ue5/**` + the one §9 line only. **No `src/**`, no `tests/**`** — the C# decode is done
  and pinned; if you think it's wrong, STOP and write a `docs/HANDOFF.md` row, don't touch it.
- Do NOT commit generated `.uasset` — assets live in the throwaway project. Committable output is
  the C++ + `tools/ue5/*.py`.
- No commit, no push. Scratch to `$env:TEMP`.
- `rebuild_runtime_fast.ps1` must compile your C++ before you finish. Fast tier stays green.
- `docs/ENGINEERING_RULES.md`: smallest correct change, confidence labels, real data only,
  faithful-first (don't "improve" the archetype values).
