# UE5 ambient audio

## Status

**VERIFIED in UE5.7, 8 September 2026.** The 1-Medical ambient actors pointed at
real cue graphs and real imported audio. The failure was playback policy: the
placed cues were one-shot wave players, most had a very small audible radius,
and they had no dedicated mix class.

Human listening is still required. The `-game` probe proves that the audio
device has active components inside their attenuation bounds; it cannot prove
that the resulting mix sounds right to a person.

## Evidence and root causes

The pre-fix headless audit loaded `/Game/BioShockSlice/1-Medical` and found:

- **Cue graph and payload are not the break (VERIFIED).** All 32 sampled cues
  had a `FirstNode`, at least one root-reachable `SoundNodeWavePlayer`, and a
  loadable `SoundWave`. Sample durations were positive (for example 0.313 s,
  4.022 s, and 7.810 s), channels/sample rates were non-zero, source MP3s were
  non-empty, and serialized `.uasset` sizes were non-zero. The existing audio
  regression found 2,040 payload-backed waves and no missing imports. Therefore
  `AudioExporter.cs` was not changed.
- **The cues did not persist (VERIFIED).** `import_audio._is_looping` interpreted
  the shipped `monoloop`/`polyloopRange` values of `-1..-1` as non-looping.
  Its attempted wave-player edit used `SoundCue.all_nodes`, which UE5.7 does
  not expose to Python, and the exception was swallowed. All 32 sampled placed
  cues consequently had `bLooping=false`; short machinery samples ended after
  roughly 0.3-2 seconds.
- **Most attenuation was too local for the slice (VERIFIED).** 28 of the 32
  pre-fix sampled cues had an outer radius below 1,500 uu; the smallest was
  100 uu. Correct actor placement therefore did not imply that any emitter was
  in range of the player.
- **Routing was absent, but not proven muted (VERIFIED / NOT A ROOT CAUSE BY
  ITSELF).** All sampled cues had no `SoundClass`, so they used UE's default
  route. No evidence showed that default route was muted.
- **Concurrency was not the initial break (VERIFIED).** The cue virtualization
  mode already read `Restart`. It is now set explicitly for placed ambience so
  a culled looping cue restarts when realized.

## Import model

Only cues referenced by exported `AmbientSound` or `MusicBox` actors receive
the ambient policy. Weapon, footstep, impact, and vocal cue graph construction
is unchanged.

The generated graph remains the UE `SoundCueFactoryNew` graph:

```text
one alternative:   Cue output -> SoundNodeWavePlayer(looping) -> SoundWave
many alternatives: Cue output -> SoundNodeRandom -> SoundNodeWavePlayer(looping) ... -> SoundWave
```

The importer now walks from `FirstNode` through `ChildNodes`, so only nodes
connected to the cue output are modified. Placed ambient wave players loop,
their cues use `VirtualizationMode.Restart`, and fixed `volumeRange` /
`pitchRange` values are honored where the ambient specification omits the
scalar field.

## Attenuation and mix approximation

**APPROXIMATION:** BioShock's exact runtime falloff curve and category mix are
not decoded.

- Sphere attenuation, linear falloff.
- Preserve the authored inner radius.
- Raise the outer radius to at least **4,000 uu** (40 m); preserve an authored
  radius if it is larger.
- Route through `/Game/BioShockAudio/Ambient`, a child of UE's `Master`
  SoundClass, with class volume **0.65**.
- Keep per-cue concurrency and explicitly use restart virtualization. This
  avoids retaining all 258 voices while allowing culled loops to resume.

The 4,000 uu floor is measured against the actual spawn, not presented as a
decode: the final `-game` probe reported **258 wired, 258 active, 44 inside
their audible bounds**.

## Verification

`tools/ue5/audit_ambient_audio.py` writes JSON under `%TEMP%` and fails unless
every sampled placed cue has a connected looping wave player, positive duration
and payload/asset size, finite attenuation, `Ambient -> Master` routing, and
restart-capable virtualization. Final result: **32 sampled cues, 0 failures**;
the map still contains **258/258 auto-activate ambient components**.

The runtime `-bioshockverifyambient` probe logs up to eight in-range components
and a summary. Final capture:

```text
BIOSHOCK_AUDIO ambient actor=AmbientSound_1 active=1 audible=1 distance=2708 max=4000
BIOSHOCK_AUDIO ambient actor=AmbientSound_2 active=1 audible=1 distance=1257 max=4000
BIOSHOCK_AUDIO_AMBIENT_OK wired=258 active=258 audible=44
```

The existing audio regression also passed: 2,040/2,040 waves, 258/258 placed
ambient actors, all five weapon cue lookups, and the live pistol-fire component.

**UE5.7 headless save landmine (VERIFIED):** recursively saving the complete
audio folder after rebuilding 928 cues and 1,327 event aliases ended in an
Engine access violation. The importer now asks each wave import task to save its
asset, continues saving each generated cue directly, and does not issue the
redundant recursive folder save. The focused `repair_ambient_audio.py` path
completed successfully and is the appropriate non-disruptive pass for an
already-imported slice.

Four ambient cue documents have no imported cue because no usable payload was
available (`ambience_1_light_bathroom`, `ambience_1_med`,
`ambience_1_medsignmain`, `music_1_radioFuneral`). The repair pass reports
these and creates no silent substitute. This is unchanged payload coverage,
not a regression.
