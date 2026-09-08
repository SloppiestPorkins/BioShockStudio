---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, src/**, docs/research/**, tmp/**
---

# Gun impacts on walls and weapons

When you shoot in BioShock a round leaves a **mark and a spark** on whatever it hits — a bullet
hole decal + debris puff on concrete/metal/wood, a spark burst + ricochet ping on metal, a
splash on water, plus the muzzle flash and shell eject at the weapon. Right now hitscan that
misses the enemy hits nothing visible: `ApplyAmmoHitEffect` only runs on **pawn** hits, and
`PlayFireFeedback` gets a `bVisualWorldHit` bool but does nothing with the surface.

## Source of truth

- `ShockWeapon.cpp` — `FireAtHitscan` (~line 1004), `FireAtShotgun` (~1230), `FireAtBeam`
  (~1362); the existing visual trace that produces `bVisualWorldHit` / `VisualEnd`;
  `PlayFireFeedback(InstigatorActor, MuzzleLoc, VisualEnd, bVisualPawnHit, bVisualWorldHit)`;
  `ApplyAmmoHitEffect`.
- The decompiled UC impact/decal tables: `*Impact*.uc`, `AmmoType*.uc`, `SurfaceType*.uc` /
  the material-to-effect mapping, `DecalManager` — real decal sizes, lifetimes, per-surface
  particle names.
- `docs/research/audio.md` for the impact sound event keys already exported (w1).

## Do

1. **World-hit impact FX.** In the fire functions, when the damage/visual trace hits world
   geometry (not a pawn), resolve the surface: `UPhysicalMaterial` if present, else the hit
   component's material name (concrete / metal / wood / glass / water / dirt). Spawn:
   - a **decal** (bullet hole for solid surfaces, sized/lifetimed from the UC) oriented to the
     hit normal;
   - a **particle** impact (dust puff, metal sparks, wood splinters, glass shatter, water
     splash) — Niagara/Cascade under `/Game/BioShockFX/Impacts/`, stand-in where the shipped
     asset can't be recovered (say so in the doc);
   - an **impact sound** via `UShockAudioLibrary` keyed on surface (the events exist from w1).
   Shotgun = one per pellet (cap the count for perf); beam = a sustained scorch at the beam end.
2. **Weapon-side feedback.** Confirm / add: muzzle flash light + particle at the muzzle socket,
   shell-casing eject for the ballistic weapons, a bit of smoke on sustained fire. The tommy
   gun's looped-fire fix (`f1e0729`) must not regress — muzzle flash should still retrigger per
   shot while the audio stays one instance.
3. Tracer / round visual for the ballistic weapons if not already present (short bright streak
   muzzle→impact), matched to the UC tracer cadence (not every round).

## Deliverable

- `docs/research/impact-fx.md` — the surface→effect table (confirmed vs stand-in), decal
  sizes/lifetimes, the muzzle/eject setup, what's approximated.
- Runtime: world-hit decal + particle + sound for hitscan/shotgun/beam; muzzle flash + shell
  eject verified on the ballistic weapons.
- Headless: `verify_impact_fx.py` — a simulated shot into a wall spawns a decal component + an
  impact FX component + fires an impact sound event; surface resolution picks the right entry
  for a known metal vs concrete material. JSON out. Log
  `BIOSHOCK_IMPACT surface=<x> decal=<asset> fx=<asset> sound=<event>`.
- `-game` captures: a wall after a burst of tommy fire (holes + scorch), a metal railing
  (sparks), water surface (splash) — `capture_shot.ps1` with a fire-at-wall flag you add.

## Constraints

- `tools/ue5/**` + `src/**` (additive, Fast tests green) + `docs/research/**` + `tmp/**`.
- Editor CLOSED for headless. `-run=pythonscript` → JSON. `MSYS_NO_PATHCONV=1` + forward-slash.
- Don't regress the tommy-gun single-instance fire audio or the world-static damage trace
  (`919f252`).
- Do NOT commit. Diff + RESULT.json; human confirms in Play.
