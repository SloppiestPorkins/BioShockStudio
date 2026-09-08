---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, src/**, docs/research/**, tmp/**
---

# Ambient sounds don't play in PIE

w1 imported the audio and placed **258 `AmbientSound` actors** in `/Game/BioShockSlice/1-Medical`.
A headless probe confirms every one of them is wired correctly at the actor level:
`sound` assigned, `auto_activate = true`, `volume_multiplier = 1.0`, `is_ui_sound = false`.
Yet the user hears **no ambience at all** in Play. So the break is downstream of the actor —
one of:

- The `USoundCue` assets those actors point to are **empty** (no wave player connected to the
  output, or the output node missing) — `import_audio.py` built the cue graph wrong.
- The `USoundWave` assets imported with **no PCM data** / zero duration (the mp3→wave step in
  `AudioExporter.cs` / the import produced silent stubs). `_is_single_frame_mp3` only rejects 2.
- An **attenuation** override with a tiny radius (falloff distance ~0) so they're inaudible
  unless the listener is on top of the emitter.
- A **SoundClass / SoundMix** routing the ambience bus to 0, or no SoundClass so it lands on a
  muted default.
- The actors need `bIsVirtualizeWhenSilent` / concurrency isn't letting 258 sources play and
  they're all getting evicted.

## Do

1. Headless audit (`tools/ue5/audit_ambient_audio.py` → JSON): for a sample of the ambient cues
   walk the `USoundCue` node graph (has a wave player? connected to root? wave has
   `get_duration() > 0` and non-zero `compressed`/`raw` size?), dump attenuation settings,
   SoundClass, concurrency. Find which of the causes above is true (likely more than one).
2. Fix the pipeline in `import_audio.py` (+ `AudioExporter.cs` if the waves themselves are
   silent — check the exported `.wav`/`.mp3` payload sizes first; if the source payloads are
   fine it's purely the UE import/cue side).
3. Give the ambient actors a sane **attenuation** (BioShock ambience is mostly local loops —
   linear falloff, inner radius from the actor's placement, ~1500–4000 uu falloff) and route
   them through an `Ambient` SoundClass under the master, at a level that sits under gunfire and
   dialogue. Set `bCanPlayMultipleInstances` / virtualize-when-silent so distant loops resume.
4. Re-run the import so the 258 placed actors get the corrected cues/attenuation (or fix
   in-place with a repair pass if a full re-import is disruptive).

## Deliverable

- `docs/research/audio-ambient.md` — the root cause(s), the cue-graph shape `import_audio.py`
  now builds, the attenuation/SoundClass model, anything approximated.
- Headless: `audit_ambient_audio.py` passes — every sampled ambient cue has a connected wave
  player, a wave with real PCM, finite attenuation, and an `Ambient` SoundClass. Log
  `BIOSHOCK_AUDIO ambient cue=<x> wave=<y> dur=<s> atten=<r> class=Ambient`.
- `-game`: the audio-log capture path (or `preview_logs`) shows multiple `AmbientSound`
  components active and audible at the player spawn. Note in RESULT.json that a human needs to
  confirm they can actually hear it.

## Constraints

- `tools/ue5/**` + `src/**` + `docs/research/**` + `tmp/**`.
- Editor CLOSED for headless. `-run=pythonscript` → JSON. `MSYS_NO_PATHCONV=1` + forward-slash.
- Don't regress the w1 weapon / footstep / vocal audio wiring.
- Do NOT commit. Diff + RESULT.json; human confirms audible in Play.
