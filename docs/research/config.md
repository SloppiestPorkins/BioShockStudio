# The baked config bundle

`ContentBaked/pc/ConfigINI.IBF` (2.0 MB) — every `PerObjIniFile` the engine declares
(`Default.ini` lists them), concatenated into one file. **This is the data layer for everything the
packages carry only by name.** `IniBundle` / `IniDocument` read it; `IniBundleTests` pins it;
`bioshock-tool config` browses it.

## Format — `CONFIRMED_BYTES`

A flat sequence of entries, no header:

```
FCompactIndex  nameLength      // characters, including the trailing NUL
UTF-16LE       fileName        // "Spawning.ini\0"
int32          contentLength   // bytes
byte[]         content         // the .ini text, single-byte, CRLF
```

21 files in the shipped bundle:

| File | Sections | What it holds |
|---|---|---|
| `Weapons.ini` | 511 | Weapon stats, damage, **the `[*ResistanceSet]` definitions** |
| `Spawning.ini` | 337 | **Every AI archetype** — all 313 `SpawningManager.ArchetypeNames`, including the ones no map ships as an export |
| `LootTables.ini` | 298 | Loot drop tables |
| `Speech.ini` | 240 | Voice-line routing |
| `Ai.ini` | 164 | AI tuning — turrets, cameras, security bots, per-deck config |
| `Quests.ini` | 139 | Quest definitions |
| `Plasmids.ini` | 112 | Plasmid stats |
| `Manual.ini` | 86 | In-game manual text |
| `Hacking.ini` | 83 | Hacking minigame config |
| `Gui.ini`, `Bindings.ini` (51), `Difficulty.ini` (29), `ResourceLimits.ini`, `Physics.ini`, `Default.ini` (47), `DefUser.ini`, `Animation.ini`, `AutoTest.ini`, `Bathysphere.ini`, `Version.ini`, `startup.ini` | | |

## What this unblocks

- **AI archetypes** — `Spawning.ini` carries the full record for all **312** archetype sections
  (the ~25 other sections are patrol/goal definitions with no `AIType`). `AiArchetypeConfig.Read`
  parses them into the same `AiArchetype` record `AiArchetypeCatalog` produces from package exports.
  `AiArchetypeCatalog` decodes the 267 that ship as exports byte-exact; `AiArchetypeConfig` covers
  all 312 including the one referenced archetype with no export
  (`PlayerEscortedGathererDLCCombat`) and the ~45 unreferenced. Section keys match the export
  property names exactly; `IniBundleTests` cross-validates the two decodes agree on Medical's
  shipped archetypes (the ini and the name table only differ in case — `...PISTOL` vs `...Pistol`).

- **Resistance sets** — **88** `[<name>ResistanceSet]` sections in `Weapons.ini`, 27 `Resistance=`
  lines each: `(Type=STIMULUS_Heat,AmountModification=3.0,ChanceModification=1.0)`. Stimulus types
  are weapon damage × player/AI, the `Shocked`/`Frozen`/`Burning`/`Diseased`/`Berserk` states, and
  specials. `[DefaultResistanceSet]` is neutral bar `STIMULUS_ElectricInWater` (0 for everyone);
  `[SteinmanResistanceSet]` zeroes every direct-fire stimulus (the scripted-invincible boss).
  `ResistanceSet.ReadAll(bundle["Weapons.ini"])` gives them typed. **On the level manifest** as
  `document.resistanceSets` — the sets a map's archetypes name, resolved once;
  `archetype.damageResistanceSetName` looks up there.

- **Player weapons** — `WeaponConfig.ReadAll` resolves the full chain:
  `[ShockGame.<Weapon>]` (magazine, accuracy, fire rate, reload, ammo types) →
  `[ShockGame.<Ammo>]` (stack size, credit value, `DamageStimuliSetName`) →
  `[<name>StimuliSet]` (`Stimulus=(Type=,Amount=,Chance=)` — the base damage). Final damage to an AI
  is `stimulus.Amount ×` that archetype's resistance-set modifier for the same `Type`. Pistol round
  = `AIGenericPiercing 40`; crossbow steel-tip bolt = `450`. `bioshock-tool weapons-config`.

- **`Difficulty.ini`** — the *adaptive* difficulty director (advisors sample player stats and nudge
  resource spawns), not a static "hard = 2× health" table. Behaviour config for a later phase, not
  data to wire.

- **Loot tables** — `LootTableConfig.ReadAll` → 239 named tables, each an ordered list of
  `LootSpec=(Chance=,ItemClass=,MinStackSize=,MaxStackSize=)` **or** `(Chance=,TableName=<sub>)`.
  Tables reference sub-tables, so a drop is a tree roll. `bioshock-tool loot-config [table]`.

- **Plasmids / tonics** — `PlasmidConfig.ReadAll` → 103 entries: friendly name, `Track`
  (`TRACK_Active` cast plasmids, `TRACK_Combat`/`Engineering`/`Physical` gene tonics), credit value,
  the four `Prereqs[1..4]` DNA-track counts, and `PlasmidPrerequisite` for the 3-tier upgrade
  chains. **Effect numbers** (bolt damage, EVE cost) are in the decompiled `ShockGame.<name>` class
  defaults, not here. `bioshock-tool plasmids-config`.

- **`Ai.ini`** (164 sections) — turret, security-camera and security-bot tuning, per-deck
  variants. Readable; a typed reader is Cursor-lane Phase 3 work (it consumes this directly when
  wiring turrets/bots).

## Notes

- Values are Unreal ini idioms: repeated `Key=` lines are array elements (`IniSection.Values`);
  struct literals `(A=x,B=y)` parse via `IniSection.ParseStruct`.
- The content is single-byte text — read as Latin-1 so no byte throws.
- `ConfigINI.IBF` is derived game data: not committed, read from the install at run time like the
  packages.
