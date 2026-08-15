# Audio

**Implementation:** `src/BioShockStudio.Core/Audio/SoundEventReader.cs`
**Tests:** `tests/BioShockStudio.Tests/SoundEventTests.cs`
**Status:** the event→sound-name link is decoded. **No audio sample has been decoded, and none is
played.** Where the sound effect data lives is `UNKNOWN`.

This note exists because an animation's events are the authoritative timing source for anything
audio, and the project already reads them: 47,560 events across the game, each with a time, a name
and a notify class. What was missing was what a given event *means*.

---

## 1. The chain, end to end — `CONFIRMED_BYTES`

```
FastReloadPistol      event "ReloadPistolOne" @ 0.30s   AnimNotify_EffectEvent
        │
        │   Event name matches exactly; SourceClassName says which actor
        ▼
EventResponse_SoundEffectsSubsystem   "HandsReloadPistolOne"
        Event            = ReloadPistolOne
        SourceClassName  = Hands
        Specification    = 19-byte blob
        │
        │   FCompactIndex into the package's own name table
        ▼
weapons_pistol_reload_one
        │
        ▼
    ???  no sample located — see §4
```

The first two steps are shipped data read field by field. The third is arithmetic on the name table.
The fourth is an open question, and the honest state of audio in this project is: **a resolved name,
not a sound.**

## 2. `EventResponse_SoundEffectsSubsystem`

An ordinary tagged-property object. `1-Medical` ships three for the pistol reload, and every map that
carries the hands carries its own copies:

```
EventResponse_SoundEffectsSubsystem HandsReloadPistolOne  [41235] 115 bytes
  FilteredState         Byte    1
  Event                 Name    ReloadPistolOne
  SourceClassName       Name    Hands
  SourceClass           Object  import Class 'Hands'
  Chance                Array   01 64000000
  Specification         Array   01 13000000 00 56 06414F 00000000 14000000 00 05 84000000
  bLevelContextsMoved   Bool    true
```

**`Event` is the same string the animation's notify carries.** That is what makes this a structural
link rather than a name resemblance: nothing is being matched by similarity, the two objects name the
same event.

**`SourceClassName` is load-bearing.** Event names are not unique on their own — `ReloadPistolOne`
means one thing for the first-person `Hands` and could mean another for a different actor — so the
actor class is what stops one actor's event resolving to another's sound. A resolver that ignores it
would be guessing.

## 3. The sound name inside `Specification` — how it was read

`Specification` is an array property with one 19-byte element. Across the three reload responses
**only one field varies**, in the same position:

```
One:    01 13000000 00 56 06 41 4F 00000000 14000000 00 05 84000000
Two:    01 13000000 00 56 06 49 4F 00000000 14000000 00 05 84000000
Three:  01 13000000 00 56 06 47 4F 00000000 14000000 00 05 84000000
                          ▲▲ ▲▲
```

Read as an `FCompactIndex` — six value bits in the first byte, seven in each continuation, which is
this era's variable-length index and the primitive that already caught this project out once on
`AttachCoords`:

| bytes | index | name table entry |
|---|---|---|
| `41 4F` | 1 + (79 << 6) = **5057** | `weapons_pistol_reload_one` |
| `49 4F` | 9 + (79 << 6) = **5065** | `weapons_pistol_reload_two` |
| `47 4F` | 7 + (79 << 6) = **5063** | `weapons_pistol_reload_three` |

**Three independent values each landing on the semantically correct sound is the evidence.** A wrong
framing does not do that three times; it was tried, and reading the same field as a little-endian
`uint16` gives 20289/20297/20295 — `machines_damage_sparks_04`, `door_lowrent_01`,
`door_highrent_02`. Those are real sound names, in the right domain, and completely wrong. **Being in
the right domain is not being right.**

### What is deliberately not claimed

**Most of the surrounding bytes are package-local and vary.** The same object in another map:

```
1-Medical      01 13000000 00 56 06  41 4F  00000000 14000000 00 05 84000000
0-Lighthouse   01 09000000 00 56 06  44 2C  00000000 08000000 00 05 83000000
               ▲▲          ▲▲ ▲▲ ▲▲  name
```

Only `[0]`, `[5]`, `[6]` and `[7]` hold across packages. The name index differs because name tables
are per-package — `2820` is `weapons_pistol_reload_one` in `0-Lighthouse`, `5057` in `1-Medical` —
which is expected and is itself a second confirmation of the reading.

`SoundEventReader` checks only those four bytes and returns *unresolved* otherwise, so a
specification of a different shape cannot be decoded into a plausible wrong name. That is the same
self-validating pattern as the `MaskMaterial` struct-size correction. Requiring the whole
`1-Medical` pattern was the first attempt and it silently unresolved every other package.

**One event can have several responses.** `EveArmJab` has two on the `Hands` class. `FilteredState`,
`Chance` and `LevelContext` presumably choose between them; nothing here does. See §6.

`Chance` (`01 64000000` — one element, value 100) is `LIKELY` a percentage, and is not read.

## 4. Where the sound data is — `UNKNOWN`, and this is the blocker

`ContentBaked/pc/Sounds_Windows/` holds **65 `.fsb` files, 2.1 GB**.

### The container is FSB5 — `CONFIRMED_BYTES`

```
+0   char[4]  magic          "FSB5"
+4   u32      version        1
+8   u32      sampleCount
+12  u32      sampleHeadersSize
+16  u32      nameTableSize
+20  u32      dataSize
+24  u32      mode           15
+28  ...      flags, then a 16-byte hash
```

**`60 + sampleHeadersSize + nameTableSize + dataSize` equals the file length exactly on all 65
banks**, which is the same standard of proof the package layout is trusted on. Version 1 and mode 15
on every bank; **10,882 samples**, 2,047 distinct names.

`mode` 15 is `CONFIRMED_EXTERNAL` only — FSB5's codec enum is documented outside this project and
gives 15 = Vorbis. **Nothing here has verified that against the bytes**, no sample has been decoded,
and the FSB5 Vorbis variant is known to rebuild stripped headers from a shared codebook, so "it is
Vorbis" should be treated as a starting point rather than a result.

### But the banks do not contain sound effects

The name table is readable and the content is unambiguous:

| prefix | samples |
|---|---|
| `vo_` | 9,463 |
| `ambience_` | 1,020 |
| `music_` | 247 |
| `scripted_`, announcements, ads | ~150 |

**Zero names contain `reload`, `pistol`, `shotgun` or `equip`.** The only `wrench` hits are
voice-over lines (`vo_R_1_At_GotWrench`). Every file is named `streams_*`, and what they hold is
streamed audio: dialogue, ambience, music.

So `weapons_pistol_reload_one` — a name the game itself resolves, from a shipped object — **has no
sample in `Sounds_Windows/`**, and a search of the install finds no other `.fsb`, `.bnk`, `.wav` or
`.ogg` anywhere.

### Candidates, none confirmed

- **`BulkContent/`.** 202 `.blk` chunks indexed by `Catalog.bdc`. This is where stripped texture mips
  live, and it is the obvious place for non-streamed audio. A raw byte search of the catalogue for
  `weapons_pistol_reload_one` misses — **but so does a search for `Hand_DIFF`**, a texture that is
  certainly in there, so the catalogue encodes its names and a raw search proves nothing either way.
  **This has not been tested with the project's own `BulkTextureCatalog` reader, which is the correct
  next step and is cheap.**
- Embedded in the `.bsm` packages. `--class Sound` finds nothing; `SoundMarker` and `AmbientSound`
  exist but are level actors, not sample data.
- Not shipped in a form this project has found yet.

**Until a sample is located, decoded and heard, there is no audio feature here — only a resolved
name.** Naming a `.wav` after `weapons_pistol_reload_one` without having decoded one would be exactly
the kind of plausible wrong result this project exists to avoid.

## 5. What is implemented

`SoundEventReader` — reads `EventResponse_SoundEffectsSubsystem` objects and exposes
`(ObjectName, Event, SourceClassName, SoundName)`, with `SoundName` null when the specification does
not match the known shape. It resolves a name. It decodes no audio, opens no bank and plays nothing.

Nothing in the application or the exporters consumes it yet.

## 6. Open questions

1. **Where do sound-effect samples ship?** §4. Test `BulkTextureCatalog` against a known sound name
   first — it is a few lines and it either finds them or rules the bulk store out.
2. **What are the other 18 bytes of `Specification`?** Constant across everything inspected. More
   responses, from actors other than `Hands`, would show which of them vary.
3. **Is mode 15 really Vorbis here?** Decode one sample and hear it, or do not claim it.
4. **Do all notify classes resolve this way?** Only `AnimNotify_EffectEvent` has been traced.
   `AnimNotify_UseAbility`, `AnimNotify_InitiateDamage` and
   `AnimNotify_StartedInteractingWithGatherer` may have nothing to do with sound, and an event with no
   response object is not evidence of a missing sound.
5. **How does an event choose between several responses?** `FilteredState`, `Chance` and
   `LevelContext` all suggest conditions this reader ignores.
