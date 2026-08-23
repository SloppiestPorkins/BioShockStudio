# Audio

**Implementation:** `src/BioShockStudio.Core/Audio/SoundEventReader.cs`
**Tests:** `tests/BioShockStudio.Tests/SoundEventTests.cs`
**Status:** the event→sound-name list and its chance/context declarations are decoded. Native MP3
and streamed FSB samples are both decoded/exportable through the later sections' implemented paths.

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

## 3. The sound name inside `Specification` — original narrow proof, superseded below

The original pistol-reload sample looked like an array with one 19-byte payload. Across those three reload responses
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
2. ~~**What are the other bytes of `Specification`?**~~ The whole-game array framing and its two
   shipped modes are decoded below; unknown tail bytes remain preserved per entry.
3. **Is mode 15 really Vorbis here?** Decode one sample and hear it, or do not claim it.
4. **Do all notify classes resolve this way?** Only `AnimNotify_EffectEvent` has been traced.
   `AnimNotify_UseAbility`, `AnimNotify_InitiateDamage` and
   `AnimNotify_StartedInteractingWithGatherer` may have nothing to do with sound, and an event with no
   response object is not evidence of a missing sound.
5. **How does an event choose between several responses?** `FilteredState`, `Chance` and
   `LevelContext` all suggest conditions this reader ignores.

## 7. Embedded FMOD sounds — `CONFIRMED_BYTES`

`Build/Final/BakedScripts/pc/FMODAudio.U` is an audio integration package, not just a script stub.
Its `FMODAudioSettings` source declares `array<Sound>` references for front-end and level-loading
audio, and the package holds 13 native `Sound` exports under `interface_audio`.

The native container follows UModel's BioShock `USound` layout: ordinary tagged properties, an
`FName` (compact index plus number), then a lazy byte array. At this game's version 142 the lazy
array carries `SkipPosition`, two unread int32 fields, and a compact byte count. For every one of the
13 exports, that count consumes its payload exactly. `SoundReader` accepts no other shape.

All 13 recovered payloads begin with valid MPEG Layer III frame headers. For example,
`GUI_shell_startGame_01` is 79,829 bytes beginning `FF FB 90 44`; it is an MP3 payload, not an FSB
bank or a name-only reference. `SoundEventTests.FMODAudioEmbeddedSoundsAreExtractedAsMp3Payloads`
pins the count, byte boundary, format identification and this known frame signature against the
installed game.

This settles the embedded `Sound` container and supplies real samples for extraction. It does **not**
yet locate `weapons_pistol_reload_one`: that name is not in `FMODAudio.U`, and no assertion is made
that every effect uses this container.

## 8. Native effect sound path — `CONFIRMED_BYTES`

The previous sentence in section 7 is superseded: `FMODAudio.U` is only one source of embedded
sounds. `1-Medical` contains both `SoundEffectSpecification weapons_pistol_reload_one` and a native
`Sound weapons_pistol_reload_one` export under `Weapons_audio`.

The recovered native sound is **8,358 bytes** and starts `FF FB 50 C4`, a valid MPEG Layer III frame
header. `SoundReader` extracts the lazy-array bytes exactly and `SoundExporter` writes them unchanged
as `.mp3`; the command below produces a standard MP3 payload without transcoding:

```bash
dotnet run --project src/BioShockStudio.Cli -- export-sounds 1-Medical out weapons_pistol_reload_one
```

`SoundEventTests.ThePistolReloadEventReachesAnEmbeddedMp3Sound` now holds the complete proven chain:
`FastReloadPistol`'s `ReloadPistolOne` event -> `HandsReloadPistolOne` response ->
`weapons_pistol_reload_one` -> native `Sound` -> MP3 frame. The export test separately requires the
written bytes to equal the package bytes.

The streamed route remains a separate task. `IGSoundEffectsSubsystem.U` defines `StreamSoundRef` as
an FMOD-native call with `SoundUnit`, `Stream`, `StreamingBlockIndex` and `StreamDuration`; its
`SoundEffectSpecification.SoundSpec` entries carry both Xenon and Windows streaming-block indices.
This explains why the FSB5 files contain dialogue, ambience and music while short weapon effects can
be embedded directly in `.bsm` packages. It is not evidence that every sound is embedded.

## 9. Native Sound coverage — `CONFIRMED_BYTES`

`audit-audio` reads every shipped map and baked-script package through `SoundReader`. On the installed
game it finds **25,848 native `Sound` exports in 21 packages**. Every lazy-array count reaches the
end of its export exactly, and every recovered payload identifies as MPEG Layer III: **25,848 MP3,
0 unknown, 0 package failures**. `SoundAuditTests` pins all four figures in the sweep tier.

The native extraction surface is therefore complete: `sounds <package>` reports it and
`export-sounds <package> <out-dir> [pattern]` writes the original bytes. The remaining audio work is
the distinct `StreamSoundRef`/FSB5 route for voice-over, ambience and music, plus presenting audio
in the application. Those are not blockers for extracting the embedded effect catalogue.

## 10. Streamed FSB5 decoder probe — `CONFIRMED_BYTES`, not yet integrated

The installed `Build/Final/fmodex.dll` is a **32-bit** FMOD Ex runtime. Under 32-bit PowerShell it
successfully creates an FMOD system, opens `streams_0_audio.fsb`, and reports **7 subsounds**. Its
first subsound reports PCM16 stereo and a declared **2,225,936 PCM bytes**; a direct `readData` probe
returns 65,536 decoded bytes. This confirms that the game runtime can decode its own FSB5/Vorbis
variant.

The application is 64-bit and cannot load that DLL directly. An attempted PowerShell wrapper was
deliberately removed rather than shipped after legacy FMOD call-boundary behaviour made it unsuitable
for a reliable exporter. The next correct implementation is a dedicated x86 compiled helper with the
exact FMOD Ex ABI, launched explicitly by the 64-bit app/CLI. Do not substitute a renamed `.fsb` or
an inferred WAV header: neither is a decoded sample.

### Implemented x86 bridge

`tools/fmod-x86/FmodFsbDecoder.cpp` is now that bridge. It dynamically loads the installed
`Build/Final/fmodex.dll` rather than redistributing it, opens one FSB5 bank and writes one selected
subsound as standard PCM WAV. The process is x86 because the game runtime is x86; the normal
application and CLI remain x64 and invoke it out of process.

The helper was compiled with the local x86 Visual C++ toolchain and tested against
`streams_0_audio.fsb`, subsound 0. FMOD returned **2,225,936 bytes** of **44,100 Hz, stereo,
16-bit PCM**. The written WAV is 2,225,980 bytes: a 44-byte RIFF header plus exactly those PCM
bytes. Its RIFF and data-size fields agree with the file boundary.

The helper first uses `FMOD_Sound_ReadData`. This build exposes a fully decoded non-streaming sound
through `FMOD_Sound_Lock` instead, so it falls back to that FMOD-owned PCM route and requires the
locked bytes to equal FMOD's declared `PCMBYTES` before writing. It never treats FSB bytes as WAV.

## 11. Streamed-audio application surface — `CONFIRMED_BYTES`

The application has a separate **Streamed audio** tab. It enumerates FSB5 files by validating their
`FSB5` header, including the localised `*.deu_fsb` / `*.fra_fsb` copies rather than assuming a
`.fsb` extension. The installed game exposes **65 banks and 10,882 subsounds**.

The x86 helper now asks the game FMOD runtime for every subsound's name. The UI lists every entry as
an index plus that FMOD name — `streams_0_audio.fsb`, for example, exposes `ambience_0_bathy` through
`vo_0_planedive`. A blank FMOD name is shown as **(unnamed stream)** rather than invented. English
`.fsb` banks and localised `*.deu_fsb` / `*.fra_fsb` copies are separate tabs.

**Decode + play** writes a cached standard WAV through `FmodFsbDecoder.exe` and Windows plays that
WAV; **Export WAV** writes the same FMOD-produced PCM result below the configured output folder.
This is separate from native `Sound` MP3 playback, and neither route fabricates a WAV header from
FSB bytes.

The CLI surface is:

```bash
dotnet run --project src/BioShockStudio.Cli -- decode-stream streams_0_audio.fsb output.wav 0
```

It finds `artifacts/app/tools/FmodFsbDecoder.exe` when run from the packaged application, or accepts
`--helper <path>` / `BIOSHOCK_FMOD_HELPER` for a development build.

## Sound actors carry no sound settings — the link is by name

**Status: `CONFIRMED_BYTES` across all 21 maps, 23 Aug 2026.** Pinned by `SoundActorSchemaTests`.
**Recorded by the Claude session while auditing the roadmap; the audio track itself is worked
concurrently by another session, and this deliberately stops at what the level actors declare.**

Gate 4 item 1 asks for "chance/variation, attenuation, pitch/volume" on sound actors. **None of
those exist.** 3,247 sound-bearing actors (`AmbientSound` 2,893, `SoundMarker` 352, `MusicBox` 2)
and **not one carries `SoundVolume`, `SoundPitch`, `SoundRadius` or an `AmbientSound` object
property**. They carry position, `Tag`, `Label`, `Region` and very little else.

So the item's premise is wrong for this game: those settings are not on the placed actor, and no
amount of actor decoding will produce them.

### What the actors do carry: names

| Class | Names its audio through | Examples |
|---|---|---|
| `AmbientSound` | `Tag` / `Label` | `2_sixtywattlight`, `1_water_lapping`, `sparksloop`, `LightNeon` |
| `SoundMarker` | `Schema1` / `Schema2` | `ambience_5_oneOff_machine`, `ambience_9_mainroom`, `ambience_4_beckoning` |

**`Schema1`/`Schema2` is a newly surfaced vocabulary** and is the more promising lead of the two:
the values are structured (`ambience_<n>_<name>`), 317 and 131 actors carry them, and they look like
direct keys into an ambience system rather than free-text labels.

**Only 7 of 3,247 tags name a `Sound` object present in the same package**, so resolution goes
through the sound-event system rather than the level package — which is exactly the blocker SS4
already records. This finding does not move that blocker; it shows what is waiting on the other side
of it, and gives the ambience-schema names as a concrete thing to resolve against once the sound
data is located.

## Exact placed-actor to FSB resolution

**Status: `CONFIRMED_BYTES` across all 65 banks and 21 maps, 23 Aug 2026.**
`StreamSampleCatalog` asks the shipped FMOD runtime for every subsound name and indexes the exact
name to bank/index/language locations. The banks contain **10,882 locations but 2,047 unique names**:
20 English banks hold those 2,047 entries, while 45 language banks repeat the appropriate names.

`AudioActorResolver` compares only the actor-declared `Tag`, `Label`, `Schema1` and `Schema2` FNames
with that exact index. It resolves **177 of 3,247 placed sound actors, all `SoundMarker`s**. No
`AmbientSound` (0 of 2,893) and no `MusicBox` (0 of 2) resolves directly. This is a useful negative:
labels such as `2_sixtywattlight`, `LightSquare` and `Bubbles` are not FSB sample names and must not
be normalised or fuzzily matched into one. Their remaining relationship is still the event/schema
route.

The full census also found a process-I/O deadlock: the managed service drained redirected stderr
before stdout, so a large FMOD `--list` response could fill the stdout pipe and block both sides.
`StreamAudioService` now drains both pipes concurrently. `AudioActorResolutionTests` retains the
65-bank/21-map census in the sweep tier.

## Response alternatives, chance and level contexts

**Status: `CONFIRMED_BYTES` across all 106,000 shipped response objects, 23 Aug 2026.** The old
single-19-byte `Specification` interpretation was wrong. The property is an array whose entries are
exactly 25 bytes in mode 6 or 26 bytes in mode 7. There are **110,120 entries** total: 62,084 mode 6
and 48,036 mode 7. **1,760 responses contain more than one sound alternative.** Another 420 response
objects intentionally omit `Specification`; absence is now distinct from malformed bytes.

`Chance` is a parallel compact-count array of int32 values and its count equals the specification
count on every response that has sounds. Shipped values are 0, 20, 30, 50, 70, 75, 80 and 100.
That pairing is `CONFIRMED_BYTES`; interpreting the integer as a percentage remains `LIKELY`, not
promoted to a rule. `LevelContext` is an exact numbered-FName array: 51,620 responses carry 123,500
context entries. `FilteredState` is a byte (0/1), and `bLevelContextsMoved` retains its serialized
bool value. These fields are exposed on `SoundEventResponse`; selecting the runtime winner remains
engine-behaviour work. `SoundEventCoverageTests` pins every count and full-array consumption.

