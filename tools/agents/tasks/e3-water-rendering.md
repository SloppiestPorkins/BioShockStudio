---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**, tmp/**
---

# Water has no visual — give it a surface and an underwater look

BioShock's Medical is full of flooded rooms, dripping ceilings, pools and the ocean beyond the
glass. Right now **water renders as nothing.** The `CascadingWaterVolume` / `FluidVolume` /
`TunnelCollapseWaterVolume` actors import as `PhysicsVolume` and their brushes are deliberately
**hidden** (`import_level._hide_volume_in_game` — they were showing as green bars). So the player
walks into invisible water.

## Level data (Medical slice)

- `CascadingWaterVolume` ×14, `FluidVolume` ×13, `WaterSplash_Small` ×18, plus
  `TunnelCollapseWaterVolume`. Dump their bounds (box extent + transform) from
  `1-Medical.ue5-level.json`.
- `AShockWaterVolume` (`ShockWaterVolume.cpp`, 61 lines) — **logic only**: `IsActorInWater(Actor)`
  iterates volumes and bounds-tests. No component renders. This is the "am I swimming / taking
  drowning damage" hook and should stay, but it needs a rendered counterpart.

## What to build

1. **A water-surface material** (`M_ShockWater`, authored in a `tools/ue5/*.py` script — no
   binary .uasset in git; build it the way the HUD/other materials are script-authored). Deco-era
   Rapture water: translucent blue-green, a panning normal map for ripples, fresnel edge, a hint
   of depth fade. Keep it cheap — this is a whole-level effect. A second variant or a parameter
   for "cascading / turbulent" surfaces (the flooding waterfalls) vs "still pool".
2. **Surface placement** — for each water volume, place a plane (or a thin box) at the volume's
   top face, sized to its XY extent, with `M_ShockWater`. Extend `AShockWaterVolume` to own this
   surface component, or a sibling `AShockWaterSurface` actor keyed to the volume. Wire it into
   the level import (`import_level.py`) alongside the existing volume spawn — replace the "hide
   the brush" behaviour with "hide the brush, add a surface".
3. **Underwater post-process** — when `AShockWaterVolume::IsActorInWater(player)` is true, drive a
   post-process: blue-green colour grade, exponential fog / reduced far clip, slight blur or
   chromatic edge, muffled (the audio side is out of scope — note it). Gate it in `AShockPlayer`
   Tick (or a lightweight component) off the existing `IsActorInWater`. Fade in/out over ~0.3s,
   don't pop.
4. **Splashes** — a decal or a short particle/decal burst at each `WaterSplash_Small` marker
   (ambient drips). If a full particle system is heavy, an animated-opacity decal loop is fine.
   Lowest priority of the four — do it only if 1–3 land cleanly.

## Deliverable

`-game` captures: looking across a flooded room and seeing a water surface; the player standing
in a water volume with the underwater grade active. `docs/research/water.md` — the material
recipe, how surfaces are placed, how the underwater PP is gated, what's approximated. Headless:
a check that each water volume gets a surface component and that `IsActorInWater` still returns
correctly (extend `verify` for `AShockWaterVolume` if one exists, else add one).

## Constraints

- `tools/ue5/**` only. Editor CLOSED for headless ops; kill stray procs between runs.
- `-run=pythonscript` swallows `unreal.log` — JSON out. Materials authored via Python
  (`unreal.MaterialEditingLibrary` etc.), not hand-placed in an editor.
- The ocean-beyond-the-glass backdrop (skybox / distant water) is a SEPARATE concern — not this
  task. Scope to the in-level water volumes and the underwater look.
- MSYS: forward-slash Windows paths + `MSYS_NO_PATHCONV=1`.
- Do NOT commit. No `docs/HANDOFF.md` claim row. Diff for review. A human confirms the look in
  the editor after.
