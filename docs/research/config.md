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

- **AI archetypes** — `Spawning.ini` carries the full record for all 313 names.
  `AiArchetypeCatalog` decodes the 267 that ship as package exports (validated byte-for-byte
  against these ini sections); the rest — one referenced (`PlayerEscortedGathererDLCCombat`) plus
  ~45 unreferenced — are here only. Section keys match the export property names exactly:
  `AIType`, `Mesh`, `Health`, `DamageResistanceSetName`, `MaterialSlot`, `AttachmentSlot1..4`,
  `MaxBurningEfficacy`, `bDoNotDoBurningBehavior`, …

- **Resistance sets** — `[<name>ResistanceSet]` in `Weapons.ini`, one `Resistance=` line per
  stimulus: `(Type=STIMULUS_Heat,AmountModification=3.0,ChanceModification=1.0)`. ~30 stimulus
  types (weapon damage × player/AI, plus `Shocked`/`Frozen`/`Burning`/`Diseased`/`Berserk` states
  and specials). `[DefaultResistanceSet]` is all-1.0; `[SteinmanResistanceSet]` zeroes every
  direct-fire stimulus (the scripted-invincible boss).

- **Loot, weapons, plasmids, difficulty** — not yet consumed, but readable.

## Notes

- Values are Unreal ini idioms: repeated `Key=` lines are array elements (`IniSection.Values`);
  struct literals `(A=x,B=y)` parse via `IniSection.ParseStruct`.
- The content is single-byte text — read as Latin-1 so no byte throws.
- `ConfigINI.IBF` is derived game data: not committed, read from the install at run time like the
  packages.
