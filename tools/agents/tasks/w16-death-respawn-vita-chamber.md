---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, src/**, docs/research/**, tmp/**
---

# Dying and respawning sends the player back to the Vita-Chamber (res station)

In BioShock, when you die you re-materialise at the **nearest active Vita-Chamber** with partial
health/EVE, the world state persists (damaged enemies stay damaged), and there's a short
regen/fade-in. Right now death handling is stubbed: `ShockDeathRespawnHandler`,
`BindPlayerDeathHandling(Player, Start)` and `ShockActionActivateResurrectionStation` exist as
scaffolding, and the Medical manifest has **2 `ResurrectionStation` actors**. Wire it up.

## Source of truth

- The decompiled UC: `VitaChamber*.uc` / `ResurrectionStation*.uc`, the player death path
  (`ShockPlayer*.uc` `Died` / `PlayerDied`), `ShockActionActivateResurrectionStation.uc` —
  real respawn health/EVE fractions, which chamber is chosen, activation cost/state, the
  "no active chamber" fallback.
- `ShockGameMode.cpp` — `BindPlayerDeathHandling`, `ShockDeathRespawnHandler`, the existing
  screenshot/verify possession flow. `ShockPlayer.cpp` health/death.
- Manifest import for `ResurrectionStation` — where the 2 actors are and whether they're
  currently spawned as anything functional (`import_slice_*`).

## Do

1. Import the 2 `ResurrectionStation` actors as a real `AShockVitaChamber` — the shipped mesh +
   the machine's glow/idle, an activation volume, an "active" state (BioShock lets you
   toggle them; default all active for the slice).
2. On player death (`ShockPlayer` health <= 0): stop input, ragdoll/black-out, pick the nearest
   **active** chamber (path/line distance per the UC), teleport the player pawn there, restore
   the UC-specified health/EVE fraction, fade back in, brief invuln. Enemies keep their current
   health and go back to search/idle (don't fully reset the encounter).
3. If no chamber is active/reachable — the UC fallback (in the shipped game with Vita-Chambers
   off it's a full reload; for the slice a respawn at the level `PlayerStart` is acceptable —
   document the choice).
4. Hook the Vita-Chamber materialise SFX/VFX (audio events from w1).

## Deliverable

- `docs/research/vita-chamber.md` — the death→respawn sequence, chamber-selection rule, the
  health/EVE restore fractions (UC-sourced), world-persistence scope, the no-chamber fallback.
- Runtime: `AShockVitaChamber`, death detection → nearest-active-chamber respawn, world state
  preserved, materialise FX/SFX.
- Headless: `verify_vita_chamber.py` — the 2 actors import as `AShockVitaChamber`; a simulated
  player death teleports the pawn to the nearer chamber, restores health to the expected
  fraction, and leaves a pre-damaged AI's health unchanged. JSON out. Log
  `BIOSHOCK_RESPAWN chamber=<name> dist=<x> healthRestored=<h> eveRestored=<e>`.
- `-game` capture: player death → fade → standing at the Vita-Chamber (a death-trigger flag you
  add + `capture_shot.ps1`).

## Constraints

- `tools/ue5/**` + `src/**` (additive, Fast tests green) + `docs/research/**` + `tmp/**`.
- Editor CLOSED for headless. `-run=pythonscript` → JSON. `MSYS_NO_PATHCONV=1` + forward-slash.
- This overlaps w11 (vendors/Vita-Chamber) — this task owns the **death/respawn** behaviour;
  leave the Gatherer's Garden / vendor UI to w11. If w11 already landed an `AShockVitaChamber`,
  extend it, don't duplicate.
- Don't touch h11 compiled-world mobility/collision or the collision policy.
- Do NOT commit. Diff + RESULT.json; human confirms in Play.
