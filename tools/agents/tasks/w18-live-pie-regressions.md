---
worker: cursor
base: main
verify: git status --short
lane: tools/ue5/**
---

# w18 — live PIE bug reports: impacts, ragdolls, interactables

> **Run mode:** non-interactive, sandboxed. Do NOT launch Unreal, do NOT build, do NOT touch
> `C:\Users\Jack\Documents\BioShockUE5`. Do NOT commit. Claude builds + runs the headless verify.

The user played the `1-Medical` slice live (28 Sept) and reported, among other things: **gun impacts
aren't registering on walls**, **ragdolls aren't working**, and **nothing is interactable**. None of
these are explained by the day's own landed work (B12 vita-chamber default, W-BUG-03 light effects,
w17 light shape — none touch weapons, physics, or the interact trace). Investigate each
independently; they may be three separate bugs, not one root cause. **Re-verify every claim against
the current code before proposing a fix — read the cited file:line first.**

## 1. World impacts (decals/FX) not appearing on wall hits

Entry point: `AShockWeapon::PlayFireFeedback` (`ShockWeapon.cpp`) receives a `bWorldHit`/`WorldHit`
pair computed by each weapon-specific fire function (hitscan pistol/tommy/shotgun-pellets each do
their own `LineTraceSingleByObjectType`/`ByChannel` — check all of them, they may not share one
helper). `SpawnWorldImpact` → `SpawnResolvedWorldImpact` (same file) does the actual decal +
particle spawn, gated on `Profile.DecalPath` resolving via `LoadObject<UMaterialInterface>` and
`ImpactProfileFor(Surface, bBeamImpact)` resolving a surface from `ResolveImpactSurface(Hit)`.
Possible failure points to check in order:
  - Does the fire trace actually hit the compiled-world BSP shell at all? (a nullrhi commandlet
    can't tell you this — use `-game` with `-bioshockverifypossess`-style added logging, or add a
    temporary `UE_LOG` on `bVisualWorldHit` per weapon and read `capture_shot.ps1`-adjacent log
    output; don't guess from source alone).
  - Does `ResolveImpactSurface` return a surface name that `ImpactProfileFor` actually has an entry
    for, or does an unmapped surface fall through to a profile with `DecalPath = nullptr`
    (decal-less by design vs a genuine gap — check the fallback default)?
  - Is `LoadObject<UMaterialInterface>(nullptr, Profile.DecalPath)` failing because the referenced
    decal material path doesn't exist/was renamed/moved — check the actual asset path against
    what's on disk.
  Write `verify_weapon_impacts_pie.py`: fire each weapon (pistol/tommy/shotgun/GL/chem/crossbow) at
  a known compiled-world wall face from a fixed position via `-game` (reuse the existing
  `run_encounter.py`/possess-prep pattern — don't reinvent it), and assert `ImpactDecalCount` (or
  whatever the equivalent counter is called — check `AShockWeapon` for existing `*Count` verify
  fields) increments per shot. A synthetic `SimulateWorldImpactForVerify` call is NOT sufficient
  evidence here — it bypasses the actual trace and profile resolution the bug report is about.

## 2. Ragdolls not activating

`ABaseShockAI::StartRagdoll` (`BaseShockAI.cpp`) refuses (logs `BIOSHOCK_RAGDOLL_UNAVAILABLE`, no
ragdoll) when `Body->GetPhysicsAsset()` is null. `verify_gameplay_fidelity`'s existing ragdoll check
(`ShockGameMode.cpp`'s `bioshockverifyragdoll` path) apparently passes for at least one archetype —
find out which, and then check EVERY enemy archetype actually placed in `1-Medical` (grep the
manifest/`ApplyArchetypeLookup` table) for a physics asset on its skeletal mesh. A missing physics
asset on some but not all archetypes would exactly match "ragdolls aren't working" as a live,
inconsistent report. Also check `OnDeathFromDamage`'s call site — is it reachable from every death
path (melee, gunfire, environmental), or only some? Grep `OnDeathFromDamage` callers.
Write `verify_ragdoll_coverage.py`: for every enemy archetype actually used in the Medical slice
(not just one hand-picked one), spawn it, kill it, and assert `IsRagdollActiveForVerify()` (or the
housed equivalent) — report which archetypes fail and why (`BIOSHOCK_RAGDOLL_UNAVAILABLE` in the log
vs some other silent path).

## 3. "Nothing is interactable"

`AShockPlayer::TickInteractionTrace` (`ShockPlayer.cpp`) traces 260uu forward on `ECC_Visibility`
and only recognises three actor types: `AShockConsumablePickup`, `AShockSearchableContainer`,
`AShockStationBase`. `HandleInteractInput` (F key, `DefaultInput.ini` confirms the binding exists)
acts on whichever of those the trace found, or falls back to `TryInteractNearbyStation` (proximity,
not trace-based). **There is no generic switch/lever/valve interact path in this runtime at all** —
`ShockActionEnableOrDisableLevelSwitching.h` exists but there is no placed interactive switch actor
class. Before assuming a regression, check:
  - Are there ANY `AShockConsumablePickup`/`AShockSearchableContainer`/`AShockStationBase` actors
    actually placed in the current `1-Medical` slice map (not just importable in principle)? If the
    slice's pickup/container import step was never re-run after a recent map edit, "nothing
    interactable" could just mean nothing of the three recognised types is currently placed.
  - Does the 260uu trace distance/`ECC_Visibility` channel actually hit these actors' collision (are
    their collision profiles set to respond to `ECC_Visibility`)?
  - Is `CachedInteractPrompt`/HUD feedback actually reaching the screen (a UI wiring gap could look
    exactly like "nothing is interactable" even if `HandleInteractInput` would work if pressed
    blind — check both independently).
  Write `verify_interact_trace.py`: in the live slice map (not a synthetic scene), enumerate every
  placed `AShockConsumablePickup`/`AShockSearchableContainer`/`AShockStationBase`, teleport a
  possessed player in front of each, run `TickInteractionTrace` for a tick, and assert
  `CachedInteractActor`/`CachedInteractPrompt` populate; then call `HandleInteractInput` and assert
  the expected effect (item collected / container opened / station used). Report how many placed
  actors of each type exist in the slice at all — if the count is zero for a type, say so plainly
  rather than treating it as this bug.

## Deliverable

- Root-cause note per item (own words; cite file:line) in `docs/research/w18-pie-regressions.md`:
  what you found, whether it's a genuine bug vs a known-missing feature (e.g. switches were never
  built), and the fix if you made one.
- Fix only what you can verify headlessly via `-game` with real evidence (a log line, a counter, an
  asserted state) — do not guess at a fix for something you could not reproduce a check for.
- The three verify scripts above (or fewer, if investigation shows an item is a documented
  known-gap, not a bug — say so instead of inventing a fix).
- Don't regress: `run_encounter.py`, `run_game_possess.py`, `verify_gameplay_fidelity.py`,
  `run_verify_pickups.py`.
