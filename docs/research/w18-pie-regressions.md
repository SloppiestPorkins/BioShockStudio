# w18 live PIE regressions — impacts, ragdolls, interactables

Live play report on `1-Medical` (28 Sept 2026): gun impacts missing on walls, ragdolls not
working, nothing interactable. Investigated as three independent failure modes. Headless `-game`
verify scripts are in `tools/ue5/`; Claude builds + runs them (this session did not launch Unreal).

## 1. World impacts (decals / FX)

### What the code does

- Hitscan (`FireAtHitscan`, `ShockWeapon.cpp` ~1495–1559), shotgun pellets (~1740–1817), and beam
  (`FireAtBeam`, ~1887–1987) each run a `LineTraceSingleByObjectType` that includes
  `ECC_WorldStatic` / `WorldDynamic`, then pass `bVisualWorldHit` + `&VisualHit` into
  `PlayFireFeedback` → `SpawnWorldImpact` → `SpawnResolvedWorldImpact`.
- `ImpactProfileFor` (`ShockWeapon.cpp` ~49–126) always returns a Concrete fallback with a non-null
  `DecalPath` when the surface is unmapped; missing art falls back to
  `UMaterial::GetDefaultMaterial(MD_DeferredDecal)` (`~1168–1173`). So profile / LoadObject gaps
  alone do not explain a total miss.
- **Projectile gap (genuine bug, fixed):** `FireAtProjectile` (`~1633`) calls
  `PlayFireFeedback(..., false, false)` with no world hit. `AShockProjectile::Detonate` previously
  never called into the impact spawn path. Grenade Launcher and Crossbow therefore never produced
  wall decals/FX even when the projectile hit WorldStatic. Fix: `Detonate` now forwards non-pawn
  hits to `AShockWeapon::SpawnWorldImpactFromHit` via the owning weapon.

### Hitscan / Tommy / Shotgun

Code path looks correct and prior `docs/research/impact-fx.md` already logged `BIOSHOCK_IMPACT` on
`-bioshockshotfireatwall`. No hitscan-side fix without a failing counter from
`verify_weapon_impacts_pie.py`. If that script reports `decalDelta=0` with `no_world_static_wall`
or `fired=1 decalDelta=0`, suspect compiled-world collision cooking (`fix_compiled_world_collision.py`)
rather than profile resolution.

### Verify

`tools/ue5/verify_weapon_impacts_pie.py` → `-bioshockverifyweaponimpacts`. Asserts
`ImpactDecalCount` advances per weapon after a real WorldStatic aim (not
`SimulateWorldImpactForVerify`).

## 2. Ragdolls

### What the code does

- `ABaseShockAI::OnDeathFromDamage` (`BaseShockAI.cpp` ~855–915) is reached from
  `UShockDamageLibrary::ApplyDamage` on the first transition to dead (~196–199) — melee, gunfire,
  and environmental damage that goes through that library all hit the same path. Grep shows no
  alternate AI death path that skips it.
- `StartRagdoll` (`~924+`) refuses with `BIOSHOCK_RAGDOLL_UNAVAILABLE` when
  `Body->GetPhysicsAsset()` is null.
- Existing `-bioshockverifyragdoll` only kills `SliceEnemy0` (`ShockGameMode.cpp`), which is
  `Agg_BabyJane` — the one mesh `repair_ragdoll_physics.py` defaults `BIOSHOCK_RAGDOLL_COMBAT` to.
  That matches “verify passes” while other Medical archetypes can still fail live.

### Fix applied

`StartRagdoll` now re-pulls `USkeletalMesh::GetPhysicsAsset()` onto the component before refusing.
That covers the case where archetype/`ApplyCombatSkeletalMesh` left the component pointer empty
while the mesh asset still carries the repair-generated asset.

### Remaining (content, not guessed in runtime)

Archetypes whose skeletal meshes never ran `repair_ragdoll_physics` still log
`BIOSHOCK_RAGDOLL_UNAVAILABLE`. Expand `BIOSHOCK_RAGDOLL_COMBAT` / re-run the repair for every
combat mesh named by Medical archetypes; do not invent a runtime physics-asset generator.

### Verify

`tools/ue5/verify_ragdoll_coverage.py` → `-bioshockverifyragdollcoverage` with
`-bioshockragdollkeys=` from the level manifest. Reports per-archetype OK / fail / unavailable.

## 3. “Nothing is interactable”

### What the code does

- `TickInteractionTrace` (`ShockPlayer.cpp` ~2414–2458): 260uu `ECC_Visibility` trace; only
  `AShockConsumablePickup` (if `RequiresInteract()`), `AShockSearchableContainer`,
  `AShockStationBase`.
- HUD prompt wiring exists (`ShockHudWidget.cpp` ~888–898 reads `GetInteractionPrompt()`).
- **No DoorSwitch / lever / valve actor class** exists in this runtime. `ShockActionEnableOrDisableLevelSwitching`
  only gates level travel. Switches are a **known-missing feature**, not a regression from w17/B12.

### Genuine bugs fixed

1. **Pickup Visibility** (`ShockConsumablePickup.cpp` ctor): collision was `Ignore` on all channels
   except `ECC_Pawn` Overlap. Containers already `Block` `ECC_Visibility`; pickups did not, so
   keypress pickups (weapons / plasmids / diaries) never became `CachedInteractActor`. Fixed to
   `ECR_Block` on `ECC_Visibility`.
2. **Station F vs prompt** (`HandleInteractInput`): trace reach 260uu > `InteractRadius` 200uu.
   Prompt could show for a looked-at station while F only ran `TryInteractNearbyStation` (proximity).
   F now calls `TryInteract` on a cached station first.

### Placement census

If `import_slice_pickups` / `import_slice_stations` were not re-run after a map wipe, placed counts
can be zero — the verify script reports that plainly via `BIOSHOCK_INTERACT_COUNTS`.

### Verify

`tools/ue5/verify_interact_trace.py` → `-bioshockverifyinteract`.

## Landing follow-up (Claude, 28 Sept, after the editor was closed)

Applied, built, and re-verified against the real `1-Medical` slice rather than trusting the
worker's own sandboxed pass. Found and fixed three more issues surfaced only by real data:

1. **Weapon impact verify was checking the wrong signal.** `TryFireEquippedWeapon()`'s bool return
   is `FireAt`'s own `bDamaged` — whether a PAWN was hit — not whether the weapon fired at all.
   Aimed at a wall on purpose, it's always false regardless of whether the shot (and its decal)
   happened. `GetFireCount()` (already `UFUNCTION`-exposed) is the real "did a shot leave the
   barrel" signal; `BeginVerifyWeaponImpacts` now compares that before/after instead. All 6 weapons
   pass for real once this was fixed — the underlying impact system was never broken.
2. **Pickup collision fix needed re-applying to the 147 already-placed actors.** The constructor
   fix (`ECC_Visibility` → Block) only affects newly-spawned instances; actors already saved into
   `1-Medical`'s `.umap` keep their old serialized collision response regardless of a later class
   default change (the same pattern hit earlier today with the Vita-Chamber `bActive` default and
   the w17 light-shape mapping). Destroyed and respawned all 147 via `import_slice_pickups.main()`
   to pick up the new constructor.
3. **Interact-trace verify harness aimed the player at the STALE direction.** `FaceActor` (the
   `-game` harness's teleport-and-look helper) only called `PC->SetControlRotation(...)`.
   `bUseControllerRotationYaw` only turns the actor (and its attached camera) to match
   `ControlRotation` during a normal `Tick`/`FaceRotation` pass; the harness calls
   `RunInteractionTraceForVerify()` synchronously right after teleporting, with no world tick in
   between, so `TickInteractionTrace`'s `FirstPersonCamera->GetForwardVector()` was still reading
   wherever the camera faced *before* the teleport. (The weapon-impact harness reads
   `Controller->GetControlRotation()` directly instead of the camera's transform, which is why it
   was never affected by the same gap.) Fixed by also forcing `Player->SetActorRotation` and
   `FirstPersonCamera->SetWorldRotation` directly. Prompt pass rate went from 1/~94 to 48/94.

**Still open (real, not yet root-caused):** 29 pickups / 11 containers / 6 stations still fail to
produce a prompt even after both fixes above — a consistent subset (same actor indices every run),
not aim-dependent, so something else specific to those placements is still wrong (candidates not
yet checked: the `Away` vector degenerating when the harness's pre-teleport player position is
already very close to the target, standing the player inside geometry; a mesh/decoration
overlapping and blocking the trace before it reaches the pickup's own collision sphere). Needs
another investigation pass, not a guess.

## Files touched (Cursor lane)

| Area | Files |
|---|---|
| Pickup Visibility + station F | `ShockConsumablePickup.cpp`, `ShockPlayer.cpp` / `.h` |
| Projectile wall FX | `ShockProjectile.cpp` / `.h`, `ShockWeapon.cpp` / `.h` |
| Ragdoll physics re-pull | `BaseShockAI.cpp` |
| `-game` harnesses | `ShockGameMode.cpp` / `.h` |
| Verify scripts | `verify_weapon_impacts_pie.py`, `verify_ragdoll_coverage.py`, `verify_interact_trace.py` |
