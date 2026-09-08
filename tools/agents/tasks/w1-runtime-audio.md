---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, src/**, docs/research/**, tmp/**
---

# Runtime audio — the game is silent

`BioShockRuntime/` has **zero audio code** (no `UAudioComponent` / `USoundBase` / `PlaySound` /
`UGameplayStatics::SpawnSound*`). No weapon fire, footsteps, ambience, music, player/AI vocals,
or audio diaries. This is the single biggest gap for "1:1 with the game" — every playtest notices
it. Build the core audible loop first, phase the rest.

## What's already done (decode side — do NOT redo it)

`docs/research/audio.md` §4: **5,722 of 5,726 named samples (99.93%) located** across four shipped
stores; **3,068 of 3,247 placed sound actors reach a `SoundEffectSpecification`** that names their
samples. Native `Sound` exports: 25,848 across 21 packages, 100% decode as MP3. Streamed samples:
65 FSB5 files (2.1 GB) in `ContentBaked/pc/Sounds_Windows/`, decodable via the FMOD bridge.

- `dotnet run --project src/BioShockStudio.Cli -c Release -- export-audio 1-Medical <out-dir> --locate`
  writes payloads + a **UE5 SoundWave/SoundCue manifest** (`src/.../Audio/AudioExporter.cs`).
- `sounds` / `export-sounds` / `audit-audio` also exist.
- `SoundEventReader` resolves an animation notify event (`ReloadPistolOne`) →
  `EventResponse_SoundEffectsSubsystem` → sample name, keyed on `SourceClassName`.
- The slice manifest (`1-Medical.ue5-level.json`) places **309 `AmbientSound`**, **36
  `SoundMarker`**, **1 `MusicBox`**.
- `ShockActionAISpeech` already records a speech request (`RequestSpeech`); `ShockActionPlayHUD`
  / `PlayMovie` / `AISpeech` etc. are request-record stubs.

So the missing work is entirely **UE5**: import the samples as `USoundWave`/`USoundCue`, and
wire playback into the runtime plugin.

## Phase 1 — core loop (the deliverable for this task)

1. **Import pipeline.** `tools/ue5/import_audio.py` (+ a dotnet wrapper if `export-audio` needs
   running first): run `export-audio` for the slice, import the MP3/WAV payloads as `USoundWave`
   under `/Game/BioShockAudio/…`, build `USoundCue`s where the manifest declares one (random/
   attenuated/looping nodes), set attenuation + concurrency sensibly. Idempotent; wired into
   `setup_playable_slice.py` STEPS (after the dotnet export).
2. **Weapon fire + reload.** `AShockWeapon::FireAt*` / reload paths → `SpawnSoundAttached` on the
   muzzle / weapon. Resolve the sample from the weapon's `SourceClassName` + event via
   `SoundEventReader`'s data (thread the resolved name through the weapon def import, or add a
   lookup asset). Pistol/Tommy/Shotgun/GL at minimum; wrench swing + melee impact.
3. **Footsteps.** Anim-notify on the locomotion clips, or a CMC-driven step timer if the notify
   isn't imported — surface type → footstep sample (metal / tile / water). Player + AI.
4. **Ambient loops.** Place the 309 `AmbientSound` actors as `UAmbientSound` with the manifest's
   sample, radius, and volume; the `MusicBox` as a looping music source. This alone transforms
   the slice.
5. **Player + AI vocals.** Player pain/death; AI aggro/pain/death via `ABaseShockAI` hooks and
   make `ShockActionAISpeech::ApplyInWorld` actually play the speech sample.

## Phase 2 — follow-ups (document, don't build here unless cheap)

- Music state machine (combat vs explore), reverb volumes (`ReverbVolume` actors), the
  `SoundMarker` one-shots, `ShockActionPlayMovie` audio, occlusion / `SoundPropagation`.
- **Audio diaries** — pickup → play the VO + append the transcript to the status menu's
  Messages tab (currently "Audio diary collection is not wired yet"). Needs the diary actor
  class + transcript data located; scope it as its own task if the data isn't readily there.

## Deliverable

- `docs/research/audio.md` extended with the UE import + playback wiring (what resolves how,
  what's approximated).
- `import_audio.py` + wiring, in `setup_playable_slice` STEPS.
- Runtime: weapon fire, footsteps, ambient loops, basic vocals audible.
- Headless: a `verify_audio.py` that asserts the slice has N `USoundWave` assets imported, the
  weapon classes resolve a fire sound, and `AmbientSound` actors carry a sample. A `-game`
  check that firing spawns an audio component (count before/after) — Null-RHI has no device so
  assert the component/sound-asset wiring, not actual playback.
- `-game` capture is pointless for audio; instead log lines
  (`BIOSHOCK_AUDIO fire weapon=Pistol sound=weapons_pistol_fire` etc.) that a human can confirm
  match on a real Play session.

## Constraints

- `tools/ue5/**` + `src/**` + `docs/research/**` + `tmp/**`. If you touch `src/**`, keep it to
  additive audio-export helpers — do not refactor the decode side, it's pinned by tests
  (`dotnet test --filter Tier=Fast` must stay green).
- Editor CLOSED for headless ops. `-run=pythonscript` → JSON out. MSYS forward-slash paths +
  `MSYS_NO_PATHCONV=1`. Kill stray procs between runs.
- Don't touch h11 compiled-world mobility/collision.
- Do NOT commit. Diff for review; a human confirms audio on a real Play session.
- Read `docs/research/audio.md` fully + the reference projects before deriving anything.
