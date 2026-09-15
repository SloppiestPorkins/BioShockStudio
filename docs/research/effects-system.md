# R3.1/3.2 — the EffectsSystem (`ActionPlayEffect` finally does something)

`docs/FULL_RUNTIME_PORT.md` R3. Per `docs/research/runtime-brain.md` §6/§7, this was the single
biggest *visible* gap in the whole port: `ActionPlayEffect` fires 167 times in Medical alone and,
before this, did nothing — no particle, no sound, no decal, ever.

## What BioShock actually does vs. what this port does

The real EffectsSystem keys a bundle lookup on **three** axes: `(EventName,
EffectsSystemContext, SurfaceType)`. The per-axis authoring tables (which Niagara/Cascade system,
which sound cue, which decal, for every event in every context on every surface) were never
recovered from the shipped assets — that data lives in a binary table format that hasn't been
decoded, not in anything `export-script-actions` or the level JSON carries. Building the real
table is a content-authoring project, not a code one; it isn't attempted here.

**What this port does instead — event/tag name resolution:**
1. Exact match on `EffectTag` (more specific when a script sets one), then `EffectEvent`, against
   a small hand-seeded bundle table (`Steam`, `Electric`, `Fire`, `Blood`, `Water`, `Smoke`,
   `Explosion`, `Ice`, `Generic`).
2. A keyword heuristic over the combined event+tag text (`"SteamHiss"` contains `"steam"` →
   `Steam` bundle; `"WoodSplinterIgnite"` contains `"ignite"` → `Fire`) — BioShock's real event
   names are self-describing enough that this catches most of them without curated data.
3. A generic fallback bundle (a small white/grey burst, no sound) so an effect this port has
   never seen still visibly does *something* rather than silently nothing.

This is a deliberate, honest simplification: not 1:1 with BioShock's actual data, but a real
system that turns 167 dead calls into 167 visible ones, and is structured so a future curated
bundle table (once/if the real EffectsSystem tables are decoded) drops in without touching the
action classes — only `UShockEffectsSubsystem::EnsureDefaultBundles`/`RegisterBundle` change.

## `UShockEffectsSubsystem` (`UWorldSubsystem`, mirrors `UShockScriptSubsystem`'s convention)

- `FShockEffectBundle` — optional Niagara asset path (empty in every seeded bundle — none were
  recovered; see above), a tint color, life/radius, an optional sound cue name (resolved via the
  existing `UShockAudioLibrary::LoadCue` — never fabricates a cue that wasn't actually imported),
  an optional decal material path.
- `PlayEffect(Target, Event, Tag)` — resolves a bundle, spawns it **attached to `Target`'s root
  component** via `AShockPlasmidFx::SpawnBurst` (w9's plasmid-cast stand-in actor, reused as-is —
  nothing in its implementation is plasmid-specific: real Niagara system if the asset path
  resolves, else its own emissive-orb fallback, tinted). Optionally spawns a positional sound and/
  or a decal (`UGameplayStatics::SpawnDecalAtLocation`, same call `ShockWeapon.cpp`'s bullet-impact
  decals already use). Tracks the spawned FX actor + audio component keyed by `(Owner, Event)` so
  `StopEffect` can tear them down individually.
- `StopEffect(Target, Event)` — destroys the tracked FX actor and stops the tracked audio for that
  `(Target, Event)` pair.
- `PushContext` / `RemoveContext` / `GetCurrentContext` — a real context stack.
  `ActionSetEffectsSystemContext` now actually mutates it (previously: recorded `LastContext`,
  did nothing). The bundle resolver does not yet branch on the active context — that's the
  natural next increment once/if a context-aware table exists — but the plumbing is real so a
  future resolver can read `GetCurrentContext()`.

## The 4 actions, before → after

| Action | Before | After |
|---|---|---|
| `ActionPlayEffect` | records `LastFiredEvent`/`Tag`/actor name, returns true | same, **plus** calls `PlayEffect` |
| `ActionPlayEffectAndWaitForStart` | records `LastEffectEventToPlay`, no `ApplyInWorld` at all (dispatch-dead — the base class's always-false no-op ran instead) | new `ApplyInWorld` override: resolves `ActorLabel`, calls `PlayEffect`. "Wait for start" and "started" collapse to the same instant since the spawn is synchronous — no latent async handle to poll like the UE2 original |
| `ActionStopEffect` | records `LastStoppedEvent`/`Tag`/actor name, returns true | same, **plus** calls `StopEffect` |
| `ActionSetEffectsSystemContext` | records `LastContext`, no `ApplyInWorld` at all (also dispatch-dead) | new `ApplyInWorld` override: pushes/removes on the subsystem's real context stack |

Both actions that gained an `ApplyInWorld` also gained a Python/Blueprint-visible
`ApplyInWorld(UWorld*)` overload alongside the native `ApplyInWorld(const FShockActionContext&)`
override — `FShockActionContext` is a plain C++ struct (deliberately not a `USTRUCT`, per
`ShockAction.h`) and can't cross the Python boundary, so every action that needs to be driven
directly from a headless verify carries this same two-overload pattern
(`ActionGetProperty`/`ActionSetProperty` established it in R2.1).

## Verify

`verify_effects_system.py`: a keyword-matched event resolves the right named bundle (not
Generic), an unrecognised event falls back to Generic and still spawns, `ActionStopEffect` tears
an instance down, `ActionSetEffectsSystemContext` push/remove round-trips through the action's own
`ApplyInWorld`, `ActionPlayEffectAndWaitForStart` resolves its `ActorLabel` and spawns. 5/5 green.
Did not regress `verify_reflection_actions` (7/7), `run_import_scripts` (R1.1 parameter
resolution, still 5/5), `run_weapon_feedback`, `run_verify_audio`, or `verify_plasmid` (55) — the
weapon-impact and plasmid-cast FX paths call `AShockPlasmidFx`/`UShockAudioLibrary` directly and
don't go through the new subsystem, so they were never at risk, but a spot-check confirms the
shared actor class still behaves under both callers.

## Known follow-ups (not this pass)

- **R3.3 — curated stand-in FX pack.** Right now every bundle is a tinted burst; a Niagara system
  per category (steam wisp, spark shower, blood spray, splash, smoke puff, explosion) would read
  far closer to BioShock than a colored sphere. Drop the asset path into
  `EnsureDefaultBundles` — the dispatch code does not change.
- **R3.4 — skeletal-prop idle animation** (`AccGateAnim`, `WallTechAnim_*`, `LiveWireAnim`,
  `IceBulge*`, fish/whale rigs) is unrelated to this pass and still not driven.
- **Context-aware bundle resolution** — `GetCurrentContext()` is real but unused by
  `ResolveBundle`; a context-keyed table (`(Event, Context) -> Bundle`) is a natural follow-up
  once there's a reason to have more than one context change presentation (e.g. "underwater"
  muffling/tinting every effect).
- The keyword table is a best-effort heuristic over ~15 substrings, not exhaustive — an event
  name with no keyword match and no exact bundle gets the Generic fallback, which is correct
  behaviour (visible, not wrong) but not category-accurate.
