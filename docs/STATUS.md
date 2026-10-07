Supersedes docs/archive/HANDOFF.md, docs/archive/NEXT_SESSION.md, docs/archive/AUDIT_2026-09-06.md.

# Status — as of 2 Oct 2026

For the forward plan (systems, priority order, what's still unbuilt), see **[`docs/ROADMAP.md`](ROADMAP.md)**.
This file is the current-state snapshot: what's done and verified, what's landed but not yet
confirmed by the user in a live PIE session, what's an open bug, and what's a known-missing feature.
Where a claim below could not be confirmed against the repository (commits, task files, source), it
says **STATUS UNCLEAR — verify** rather than guessing.

## Repo lost and rebuilt (1–2 Oct 2026)

Between 30 Sept 22:57 and 1 Oct 03:02 the whole `C:\Users\Jack\Documents\BioshockHavok` folder
disappeared: not moved, not in the Recycle Bin, and no Claude tool call in any session removed it
(cause unknown). GitHub had everything up to `60c6d3b` (29 Sept 16:12). Rebuilt 2 Oct from the
Claude session logs:

- **The 20 unpushed commits** (`d796872` … `fe31834`) were replayed at their original times with
  their original messages. They have new hashes; each message ends with `original commit <sha>`, so
  an old hash cited in these docs resolves with `git log --grep "original commit e51e8cb"`. Every
  rebuilt commit matches its original's recorded file count and +/− line counts exactly, and the
  plugin C++ is byte-identical (612/612 files) to the copy in `BioShockUE5/Plugins` (UE baseline
  `2d528550`). Cursor-agent changes, which were copied in with `cp` rather than edited, came from
  the `git diff main` output printed before each copy.
- **The uncommitted 30 Sept doc rewrite** (ROADMAP Phase 0–3, §61, CLAUDE.md, this file) was
  restored and committed.
- **`tools/fmod-x86/FmodFsbDecoder.cpp`** was gitignored with its folder and lost; rebuilt from
  Codex's patch log, verified decoding a real FSB, and now tracked.
- **Gone, never in git:** `artifacts/` (4.5 GB of build output and local evidence;
  `artifacts/tools/FmodFsbDecoder.exe` rebuilt), `external/` (Unreal-Library-master and
  UModel-master, which `tools/uelib-bridge` needs, plus Nyko's SDK and the Havok 2012.2 SDK — must
  be re-fetched), `tmp/`, `tools/ue5/_reports|_shots/`, `tools/agents/runs/`. The 15 worktrees in
  `../BioShockHavok-agents/` are orphaned (their gitdir went with the old `.git`).
- Verification also turned up 2 fast-tier tests broken since `export-level-manifest` (only
  `LevelSceneTests` was run when it landed); fixed.

## Most recent landed work (30 Sept 2026)

The most recent landed work: **Census of Medical's remaining `_import_door_attachments` skips —
the "31 other doors still skipped" claim from the entry below was wrong.** Measured against the
live `1-Medical` manifest + slice (new `tools/ue5/audit_remaining_doors.py`, and a fresh
`import_slice_doors` run after the location/rotation fallback): Medical has **44** actors with a
`door` field; **all 44 place as `AShockDoor`** (`doorsPlaced=44`, `doorAttachmentsPlaced=62`,
`doorAttachmentsSkipped=0`). Pre-fallback there were exactly **4** whole-door skips — the three
`LowRentDoorsWide` instances *and* `HighRentDoorWide0` (same gap, missed in the writeup below) —
all of which hit the new `location`/`rotation` path. The other 40 already placed via matrix
transforms. Residual that is *not* a placement skip: the same 4 doors reference
`LowRentDoor_Mesh`, one of the four permanently-undecoded door skeletal meshes (ROADMAP cut line /
Claude's decode lane), so they are real, label-addressable, lock/unlock-correct `AShockDoor`s with
no skeletal visual. The 9 other no-attachment doors (`AccordianGateDoor` ×6, `BulkheadDoors` ×3)
resolve `AccGateAnim` / `BulkheadDoor` proxies fine. No further importer fix in this lane.
(Made `audit_remaining_doors.py` runnable standalone like every other script here — it was
missing the `sys.path.append(...)` line before `import import_level` and originally shipped with
a separate `run_audit_remaining_doors.py` wrapper to work around that; removed the wrapper now
that the main script carries its own fix.)

The prior landed work: **Fixed the `LowRentDoorsWide` placement gap the keypad fix below
found — `MorgueClosetDoor` (and its 2 siblings) are now real, functional `AShockDoor`s.**
`import_level._import_door_attachments` only ever resolved a door's transform from an
`instances[]` entry's matrix or a raw `"transform"` field on the actor — and silently skipped the
door entirely (`doorAttachmentsSkipped`) when neither existed, with no fallback to the actor's own
perfectly ordinary `location`/`rotation` fields that every *other* actor-placement function in this
pipeline already uses directly. All 3 of Medical's `LowRentDoorsWide` instances hit exactly this
case — they have real `location`/`rotation` data, just not in either of the two matrix-shaped forms
the function checked for. Added the fallback (`_rotation()` needs no `GameBasis` reversal for this
field, unlike `_decompose`'s matrix case — confirmed via its own docstring — so this is the same
plain path every non-door actor already takes). Re-ran `_import_door_attachments` live against
`1-Medical`: all 3 previously-skipped doors (`LowRentDoorsWide0`, `MorgueClosetDoor`,
`MorgueClosetTurretDoor`) now exist as real `ShockDoor` actors with the correct locked state.
(The contemporaneous "31 other doors are still skipped" note was a misread of the remaining
population — corrected in the entry above; only `HighRentDoorWide0` shared the same gap, and
there are zero whole-door skips left.) Regression-verified: `verify_scripting_movers` (29/29),
`verify_gameplay_fidelity` (27/27), `verify_import_scripts`, `verify_stations`.

The prior landed work: **`DoorKeypadControl` is now a real, interactive actor — Medical's
one keypad (`TwilightFieldsKeypad`) unlocks its door and fires the script gating on it.** Found via
the systematic class sweep two entries down: `TwilightFieldsKeypadScript`
(`TriggeredBy=TwilightFieldsKeypad`, `scriptMessageClass=MessageDoorKeypadUsed`) was one of only
two real hits, deliberately deferred at the time because the consuming action,
`ShockActionDoorKeypadUsed::ApplyInWorld`, has its own long-standing comment admitting "no
DoorKeypad / keypad-control actor class exists in BioShockRuntime yet, so Success cannot be
delivered to a control." Built the missing actor class instead of touching that stub: new
`AShockDoorKeypadControl` (mirrors `AShockSwitchActor`'s shape — mesh optional, `Press F to use`,
one-shot) — on interact, unlocks every `AShockDoor` matching its configured `DoorLabel` via
`AShockDoor::CollectByLabel` (the same pattern `ActionUnlockDoor` already uses) and dispatches
`MessageDoorKeypadUsed` via the existing `DispatchDoorKeypadUsed` path, so the associated Script's
own action list still runs exactly as authored. Deliberately does NOT implement a real numeric
code-entry minigame — no such UI exists in this project and no decoded keycode value is available
anywhere in the pipeline, so interacting always succeeds; documented clearly in the class comment
rather than pretending otherwise. Wired into `ShockPlayer.cpp`'s interact-trace and input handling
exactly like switches. New `import_slice_door_keypads.py` places the one instance (no mesh data in
this export, same invisible-but-functional degradation as other meshless props).

Found a second, separate, pre-existing gap while verifying: `MorgueClosetDoor` (the door this
keypad controls) is not actually placed as a functional `AShockDoor` in the live slice at all —
none of Medical's 3 `LowRentDoorsWide` instances (including this one) have a manifest `instances[]`
entry or a raw `transform` field, so `import_level._import_door_attachments` skips all three
entirely (`doorAttachmentsSkipped`, not a bug in this fix). **Fixed in the LowRentDoorsWide
placement entry above** (same session, right after landing the keypad); the subsequent census
also caught `HighRentDoorWide0` in the same gap and confirmed 44/44 Medical door-field actors
now place. The keypad mechanism itself is fully
verified working end-to-end (interact → unlock → dispatch → script fires) against a fresh scratch
door; the real live `MorgueClosetDoor` now resolves the same way. Verified end-to-end headless
(11 checks): the interact/one-shot/unlock/
dispatch mechanism on a scratch door+script, and the real live `TwilightFieldsKeypad` instance
resolving as a real `AShockDoorKeypadControl` with the correct `DoorLabel`. Regression-verified:
`verify_scripting_movers` (29/29), `verify_gameplay_fidelity` (27/27), `verify_import_scripts`.

The prior landed work: **`verify_ai_archetypes.py`'s false `spawn Agg_BabyJane failed`
cleared.** The spawn probe was hardcoded to `unreal.Vector(500.0, 0.0, 100.0)` since the original
Phase-3 commit (`27bc69e`, 30 Aug 2026) — world origin, with no Medical floor under it.
`ActionSpawnAI::SpawnAtLocation` calls `FindGroundedSpawnLocation` (Visibility line-trace) *before*
any archetype lookup, so the failure was a bad test fixture, not an archetype bug (already flagged
as a follow-up under the 29 Sept weapon-resolution slice). Also fixed a separate, pre-existing bug this same pass:
`verify_ai_archetypes.py` was missing the `sys.path.append(os.path.dirname(os.path.abspath(__file__)))`
line every other script in this project has before importing a sibling module (`import
import_ai_archetypes`) — without it, `-run=pythonscript -script=<abs path>` (this project's own
standard headless invocation) fails with `ModuleNotFoundError` before the script body ever runs.

Measured further while fixing: simply moving the probe into Medical space is **not** enough in this
headless editor commandlet — Visibility traces against Medical's compiled-world mesh return no hit
at MedicalStart, the pavilion movement start (`-18096, 2480, 7794`), authored AggressorSpawner
markers, *and* world origin. (MedicalStart also sits inside BlockingVolumes that would fail the
subsequent `AdjustIfPossibleButDontSpawnIfColliding` capsule spawn even if a floor were found —
same landmine `ShockGameMode::SpawnDefaultPawn` works around with `AlwaysSpawn`.) Fix: probe at
the pavilion movement-start XY (Medical playable space), place a temporary BlockAll
`/Engine/BasicShapes/Cube` slab under it so `FindGroundedSpawnLocation` can succeed, assert
archetype-applied spawn health, destroy both. Headless `verify_ai_archetypes` now PASSes
(`spawnedHealth` 80.0 == `expectedBabyJaneHealth` 80.0). Regression-clean:
`verify_gameplay_fidelity` (27/27), `verify_import_scripts` (0 failures).

The prior landed work: **Brigid Tenenbaum's 200-ADAM gift (`TenenbaumPresent`) can now
actually be received — and fixed a real bug in the container-loot path that would have silently
swallowed it even after placement.** Systematically re-swept every Medical className with zero
import-script references (220 candidates after fixing a CRLF bug in the sweep itself) against
every Script's `TriggeredBy`/`messageFilter` target, to catch anything the earlier one-class-at-a-
time hunt missed. Only two real hits survived: the already-known, already-deferred
`DoorKeypadControl` (needs a whole keypad-UI system, see below), and `TenenbaumPresent` — 1
instance, labeled `TenenbaumGift`, holding a scripted reward two Scripts key off
(`Present_PickedUp`/`Present_PickedUpBackup`, `ContainerLabel=TenenbaumGift, ItemClass=ADAM,
ItemCount=200`). It never matched `import_slice_pickups.py`'s "Pickup"/"Container"/"Booty"
substring fallback either, so it fell straight to an invisible `TargetPoint`, same as the safes.

Added it to `CONTAINERS` (extended the dict's tuple shape to carry an item amount, not just money,
since every existing entry defaults to `1` and this one genuinely needs `200`) — but configuring
`LootItemClass="Adam"` alone would NOT have worked: `AShockSearchableContainer::Search()`
unconditionally routed every item class through `AddStackToInventory`, which treats `"Adam"` as
just another generic inventory stack key, not real ADAM currency (`PlayerAdam`/`AddAdam`/
`GetAdam()` are a separate system entirely). `AShockConsumablePickup`'s own `K_ADAM` kind already
special-cases this correctly for world pickups; `Search()` had no equivalent branch, so a
container promising ADAM would have silently handed the player a meaningless, unrecognized
`InventoryStacks["Adam"]` entry instead — worse than the TargetPoint it replaced, since it would
have looked fixed while still not delivering the reward. Added the same special case to `Search()`.
The two `Present_PickedUp*` scripts still can't fire (their own `TriggeredBy` is empty in this
export, and nothing anywhere dispatches `MessagePlayerRemovedItemFromContainer` — a separate,
deeper gap, not blocking here since the actual ADAM grant never depended on those scripts firing
in the first place, exactly like every other container in this project). Verified end-to-end
headless: the real live `TenenbaumGift` instance resolves as a real `AShockSearchableContainer`
configured with the correct item/amount, and — on a disposable scratch container, not the real
one-shot live instance — searching it actually adds 200 to `GetAdam()`. Regression-verified:
`verify_pickups` (9/9), `verify_stations`, `verify_gameplay_fidelity` (27/27).

The prior landed work: **stations/movers duplicate-collider audit (`task_977a74fe`) —
closed.** Manifest-audited Medical against the same `instance:<actorKey>:<asset>` overlap that
hit switches/pickups:

| Class family | Has `instances[]`? | Generic mesh placed by `_import_instances`? | Interact-trace risk? | Verdict |
|---|---|---|---|---|
| PlaceableHealth/Growth/Vending stations (10) | 7/10 yes (all Health + Growth; Vendings meshless) | **Yes** — not denylisted | **Yes** — `TickInteractionTrace` casts to `AShockStationBase` | **Already fixed** as a side effect of `import_slice_stations` reusing `import_slice_pickups._place` (which gained `destroy_instance_duplicates` in b0466aa). |
| ScriptableMover (8) | 8/8 yes | **No** — denylisted via `_is_animated_prop_class`; deferred to `_import_animated_props` (which already destroys leftover `instance:` meshes) | No — movers are script-driven, not on the F-interact Visibility cast list (the spin-off note overstated this) | **Not affected** |
| ResurrectionStation / VitaChamber (2) | 2/2 yes | **Was yes** — `_import_vita_chambers` placed the chamber, then `_import_instances` still stacked a `StaticMeshActor` on top (`handled` only stops the TargetPoint fallback, not instance meshes) | **Yes** — `GetPlayerStartTransform`'s Visibility clearance probe ignores only `this`, so a co-located duplicate reports near-zero clearance through the machine body | **Fixed this pass**: denylist in `_should_place_mesh_instance` + `destroy_instance_duplicates` inside `_import_vita_chambers`; `verify_vita_chamber` now asserts the policy and flags leftover instance meshes |

This pass was produced by `cursor-agent` (dispatched to an isolated worktree) and reviewed/merged
by hand, not run directly against the live editor by the agent itself — its own check was a
C#/.NET "fast tier" (288/290, see below), not a UE5 headless verify. So the actual live-slice
confirmation was done separately after merging: re-ran `import_slice_stations` (0 errors) and
found both real `ResurrectionStation` instances in `1-Medical` still carrying the pre-fix leftover
`StaticMeshActor` (the denylist only prevents a *future* `_import_instances` pass from recreating
it, it does not retroactively clean an already-saved map) — a small one-off script called
`destroy_instance_duplicates` directly on both keys rather than re-running the full, heavy
`import_level.main()` pipeline. Confirmed live afterward: 0 leftover duplicates anywhere across
all 10 stations and both vita chambers, `verify_vita_chamber`/`verify_stations` PASS, and the
broader regression subset (`verify_gameplay_fidelity`, `verify_import_scripts`,
`verify_scripting_movers`) clean.

Documented the stations/movers findings in those scripts' module docs. Fast tier on this
worktree (cursor-agent's own C#/.NET check, not a UE5 run): 288/290 passed; the 2 failures
(`CubemapTests` / `MaterialAnimatorTests` Lighthouse probes) are empty-collection asserts against
a missing Lighthouse install path in that worktree — unrelated to this Python/import-policy
change (no C# diff).

The prior landed work: **5 real safes (`SecurityCrate_WallSafe`/`SecurityCrate_Safe`) can
now be opened for loot, and the same duplicate-collider bug (see below) is fixed retroactively
across the entire ~230-instance pickup/container economy, not just the 3 fixes it was caught in.**
`import_slice_pickups.py`'s own class-routing only ever had a *reporting* catch-all for anything
containing "Pickup"/"Container"/"Booty" in its className — `SecurityCrate_WallSafe`/
`SecurityCrate_Safe` don't contain any of those substrings, so they weren't even counted as
"unmapped," they silently never reached this script at all and fell straight to `import_level`'s
bare `TargetPoint` fallback: 5 real containers a player could never search. Added both classes to
the existing `CONTAINERS` dict (reusing `AShockSearchableContainer`, no new class needed) with a
higher loot range than `CashRegister` (safes are the better-hidden loot tier in BioShock's own loot
design). Neither has a resolvable mesh in this level's export, so both land invisible-but-
searchable — the same honest-degradation convention already used for other meshless containers.
While touching `_place()` here, also applied `import_level.destroy_instance_duplicates` (see
below) to this script — confirmed via live spot-check across ~30 pickups/containers/safes that
every one is now a single actor per key, where before this same script (like switches/reactive-
props/damageable-props) was quietly leaving a duplicate `StaticMeshActor` under nearly every
pickup and container in the slice. Verified: `verify_pickups` (9/9 checks), `verify_gameplay_fidelity`
(27/27). Spun off a task (`task_977a74fe`) to audit whether `import_slice_stations.py` and
`import_slice_animated_props.py` (doors/lifts) have the same gap — **closed by the most-recent
entry above**.

The prior landed work: **fixed a real correctness bug in the last three fixes below —
duplicate overlapping colliders at every switch/reactive-prop/damageable-prop's own location.**
While auditing whether any other Medical classes had the same "invisible TargetPoint" problem
(they didn't — `OilSlick_Reactive`, `IcicleMeltable`, `PhysicalReactiveActor`,
`VisualFXProxyReactiveActor` all turned out to already be placed by `_import_instances`, the
generic geometry-instance pipeline, so they were never actually invisible), found that
`_should_place_mesh_instance` has no class denylist for most gameplay classes either — meaning
switches, `NonPhysicalReactiveActor`, and the damageable props (`Padlock`, `dyn_grate64`,
`TV_WallMounted`, ...) were *also* already getting a plain, real, visible `StaticMeshActor` from
that same generic pipeline, in parallel with the dedicated gameplay actor each of the last three
fixes spawned at the identical location. Confirmed live: `GatePadlock` had two actors stacked at
the exact same transform — a `StaticMeshActor` from `_import_instances` and the new
`AShockDamageableProp`, each with its own `BlockAll` collider. This is not just cosmetic
z-fighting: `LineTraceSingleByObjectType` returns whichever blocking primitive the physics engine
resolves first among two identical-transform colliders, not necessarily the gameplay actor, so a
weapon shot at a padlock/grate/TV could silently resolve to the dead duplicate instead of the
`AShockDamageableProp` that's supposed to react — a real-play failure mode a headless unit test
that calls `ReactToDamage`/`TryInteract` directly (bypassing the actual trace) can never catch.
New `import_level.destroy_instance_duplicates(existing, actor_key)`, called from all three
scripts' `_place()` right when placing the dedicated actor. Re-ran all three import passes and
confirmed live: the duplicate `StaticMeshActor` is gone at every spot-checked key (the padlock,
all 4 checked `DoorSwitch`/`Switch` instances, 7 `TV_WallMounted` instances, all 4 `dyn_grate64`
grates) — exactly one actor per key now. Re-ran all four feature verify scripts plus the combat/
import regression subset (`verify_import_scripts`, `verify_gameplay_fidelity`,
`verify_scripting_movers`, `verify_ai_combat`, `verify_weapon_beam`) clean.

The prior landed work: **`InPlayerViewTrigger` (look-at cutscene/tutorial gates) — all 14
instances in 1-Medical are real `TriggeredBy` targets for real Scripts, and every one of them was
completely dead.** `SteinmanIntro`, `Quarantine_PistolIntro`, `Ghost_TwoTwo` (the first ghost
sequence), `EternalFlameBlast`, `QuarSwitch_UnlockMaintenanceHall`, `TrainingHackTurret`, and 8
more all gate on one of these labels via `TriggeredBy`, and every one of those Scripts'
`scriptMessageClass` resolves to UE2's base `Message` class, which `MatchesMessageClass` accepts
from any dispatched class — so only the label needed to exist and fire, and it never did.
`InPlayerViewTrigger` never had a dedicated actor class wired (`import_level.py`'s fallback), so
these imported as inert `TargetPoint`s with no line-of-sight/FOV logic behind them at all. New
`AShockInPlayerViewTrigger`: a location-only actor (no mesh, no collision) that ticks a few times
a second, checks whether the player's own camera has an unoccluded line of sight to it within a
view cone, and dispatches once it does — or, for `TriggerWhenNotSeen` (2 of the 14: a "look at the
present, then look away" pair and a patient-body-swap cutscene gimmick), once the player looks away
*after* having seen it, never immediately just because it was never looked at (would make no
narrative sense for a look-away trigger to fire before ever being looked at). PLAUSIBLE stand-ins
where the original UE2 class isn't decoded anywhere available: a 60-degree view cone, and
`MinimumDistance` read as a maximum range gate (2 of the 14 use it — the ghost sequence and the
hacking-turret tutorial). Also deliberately does NOT read the manifest's own `enabled` property:
this exporter only serializes non-default values, so a bare bool's presence is ambiguous about
which direction is default, and there's no `ActionEnableOrDisable...`-style action anywhere in the
plugin that could ever turn one on later if it started disabled — so importing every instance
active is both the safer and the more narratively plausible reading. Caught and fixed a real bug
during verification, not just a design guess: the actor had no `RootComponent` (no mesh, so none
was ever created), which silently means `SetActorLocation`/spawn-with-location is a no-op in UE5 —
every placed instance was sitting at world origin (0,0,0) until a plain `USceneComponent` root was
added. Verified end-to-end headless (16 checks): view-cone fire/no-fire, the one-shot guard, the
seen→not-seen edge semantics (including the "never fires before ever being seen" case), the
distance gate, the real dispatch reaching a listening script, and 4 of the real live-slice
instances (including the two with a distance gate) resolving as genuine
`AShockInPlayerViewTrigger` actors. Regression-verified clean: `verify_import_scripts`,
`verify_gameplay_fidelity`, `verify_scripting_movers`.

The prior landed work: **shootable/damageable reactive props — padlocks, grates, ice,
oil slicks, TVs — now real actors that unlock real scripts, closing a genuine "the player cannot
progress/experience content" gap, the same class of bug as switches.** `Padlock`, `dyn_grate64`,
`NonPhysicalNonPathBlockingReactiveActor`, `OilSlick02_Reactive`/`OilSlick04_Reactive`, and
`TV_WallMounted` (17 instances total in 1-Medical) never had a dedicated actor class wired, so —
same root cause as switches and the NonPhysicalReactiveActor debris above — they fell through
`import_level.py`'s fallback as invisible, non-collidable `TargetPoint`s. Unlike the debris, these
ARE script-load-bearing: real Scripts gate on these exact labels (`OpenSteinmanGate` waits on
`GatePadlock`/Reason=Shattered, `KureAllGrate1Damaged` waits on `KureAllGrate1`/Reason=Damaged,
`TurnOffLightOnDynamicTelevision` waits on `TV_WallMountedWIthLight`/Reason=Damaged, `MeltedIce`
waits on `IceBlockage`, `IncinerateOilSlickSpread` waits on `ScriptedOilSlick1,ScriptedOilSlick2`).
Went deeper than the actor class itself: `UShockDamageLibrary::ApplyDamage` only ever recognized
`AShockPawn` targets (`Cast<AShockPawn>(Target); if (!Pawn) return 0.0f;`), and — worse — each of
`ShockWeapon.cpp`'s three real damage call sites (hitscan, shotgun, the chemical-thrower beam)
gated on `Cast<AShockPawn>(Hit.GetActor())` *before* ever calling `ApplyDamage`, so a shot hitting
one of these props wasn't just a no-op inside the damage library, it never reached the damage
library at all. New `AShockDamageableProp` (mirrors `AShockSwitchActor`'s shape, but reacts to a
weapon hit instead of a player interact-press, one-shot) is now handled at both the library choke
point and each weapon call site's `else if`. Confirmed the Reason-based message filters (e.g.
Reason=Damaged) don't need extra plumbing: `UShockScriptRunner::MatchesMessageFilter` only rejects
a Want field that's *present* with the wrong value, never one that's simply absent from the
dispatched fields, so the existing Reason-less `NotifyReactedWithActor` dispatch already satisfies
them. New `import_slice_damageable_props.py` places all 17 with their real manifest mesh (17/17
resolved, 0 misses). Verified end-to-end headless: unit dispatch + one-shot guard, the actual
`UShockDamageLibrary.apply_damage` C++ path (not just the direct method call), and all 6 real
live-slice instances (GatePadlock, KureAllGrate1, TV_WallMountedWIthLight, IceBlockage,
ScriptedOilSlick1/2) resolved as genuine `AShockDamageableProp` actors with the correct label.
Regression-verified clean (touched shared combat code, `ShockDamageLibrary.cpp`/`ShockWeapon.cpp`):
`verify_ai_combat`, `verify_weapon_beam`, `verify_script_damage_exec` (also fixed a pre-existing,
unrelated `EditorActorSubsystem.get_editor_world()` AttributeError that was blocking this check
from ever running), `verify_script_damage_level`, `verify_gameplay_fidelity`.

The prior landed work: **54 `NonPhysicalReactiveActor` debris/set-dressing instances in
1-Medical are now real, visible, collidable level geometry — a level-fidelity gap, not an
"unlocks dead content" one.** Same root cause as switches: `NonPhysicalReactiveActor` never had a
dedicated actor class wired, so all 54 instances (`TunnelBlock`, `CollapsedTunnel`,
`SteinmanBrokenGlass`, `ShatterGlass`, `CremationContainer`, `EternalFlameBlast` prop dressing,
`SteinmanBed`, ...) fell through `import_level.py`'s fallback into invisible, non-collidable
`TargetPoint`s. Checked first whether this was script-load-bearing the same way switches were
(`quarswitch` → Fisheries gate): it is not — grepped every Script's `TriggeredBy`/`scriptMessageClass`
and every other actor's action-target property in the manifest for these 54 labels and found zero
references anywhere, so unlike switches this doesn't unlock any dead content. It's still a real
playability bug: several `TunnelBlock`/`CollapsedTunnel` instances carry `bBlockActors`/
`bBlockPlayers`/`bBlockHavok`/`bCollideActors` in their own manifest property list — and since the
original .lvl format only serializes non-default properties, that presence means the level design
explicitly wants that rubble to physically block a corridor (forcing a detour) — right now that
corridor is wide open with nothing there at all. New `import_slice_reactive_props.py` places all 54
directly as engine `StaticMeshActor`/`SkeletalMeshActor` (no custom class needed — these aren't
interactable) with the manifest mesh and a `BlockAll` collision profile, respecting `bHidden` where
the manifest carries it (24/54 start hidden by design, matching the same non-default-property
convention). Live result: 54/54 resolved a real mesh (better than switches' 8/10 — no manifest
className-mismatch cases here), 30 visible + collidable, 24 hidden per manifest intent, 0 errors.
Verified end-to-end headless: every placed actor confirmed to have a real mesh assigned, `BlockAll`
collision profile, and the correct hidden/visible split against the import report.

The prior landed work: **levers/switches/buttons are real, interactive actors — a genuine
content gap closed, not a roadmap-breadth item.** `1-Medical` places 10 `DoorSwitch`/`Switch`/
`IncineratorSwitch`/`BathysphereSwitch`/`Med_MedicalGateSwitch`/`ChompersDentalButton` actors, and
none of them ever had a dedicated actor class wired — `import_level.py`'s "other decoded-but-
unplaced classes" fallback left every one as an invisible, non-interactive `TargetPoint`. Real
scripts already gate on these actors' own labels via `TriggeredBy` (Medical's `quarswitch` unlocks
the Fisheries quarantine gate; `ToNeptuneSwitch` is the bathysphere departure switch), so this was a
genuine "the player cannot progress" gap, not cosmetic. New `AShockSwitchActor`: a mesh the player
walks up to and presses (Press F), which dispatches `MessageRAReacted` with the actor's own label as
the source — the exact mechanism `AShockPlayer::NotifyReactedWithActor` already implements for
`NonPhysicalReactiveActor`, reused rather than duplicated. New `import_slice_switches.py` places all
10 with their real manifest mesh (8/10 resolve a real static/skeletal mesh; 2 `Med_MedicalGateSwitch`
records fall back to invisible-but-functional, same graceful-degradation convention as pickups
without an imported mesh — see the script for why). Verified end-to-end, not just "it compiles": a
fresh headless test spawns a switch and a script gated on its message class + label, interacts with
the switch, and confirms the script's own action actually ran; separately confirms the real
`quarswitch` actor in the live slice is now a genuine `AShockSwitchActor` with the correct label, not
the old stand-in. Regression-verified clean: `verify_gameplay_fidelity`, `verify_scripting_movers`,
`verify_vita_chamber`, `verify_import_scripts`, `verify_water`.

The prior landed work: **roadmap priority 4, AI archetype weapon resolution — a real,
grounded first slice, not the whole priority.** Investigated `1-Medical`'s 23 placed archetypes
(the actual bounded test surface, not the full 267-archetype census) and found
`SpawnArchetypeWeaponIfNeeded` (`BaseShockAI.cpp`) gave every ranged archetype the *identical* flat
20-damage/10000-range hitscan stand-in regardless of type — a Grenadier fired hitscan bullets
instead of lobbing grenades, an SMG used the Pistol's pacing. Root cause: the archetype's real
BioShock AI type (`aiType`, e.g. `"SpawnedGrenadier"`) was never read for weapon resolution, only
for a boolean "is this ranged at all" gate. Fixed: `ResolveArchetypeWeaponDefName` maps `aiType` to
a real `UShockWeaponDef::Resolve` name (Pistol/TommyGun/GrenadeLauncher/Shotgun/Crossbow), keeping
AI ammo-infinite (`SetEnforceAmmo(false)`) since there's no AI reload behaviour. Along the way found
a second, more severe pre-existing bug in the SAME ranged-detection heuristic (`SlotNameLooksRanged`,
both the C++ copy and its Python mirror in `import_ai_archetypes.py`): "Thug" alone was treated as a
ranged signal, so melee splicers (`aiType` `"SpawnedMeleeThug"`, which also contains "Thug") were
incorrectly flagged ranged and equipped with a gun. Fixed with an explicit "Melee" exclusion checked
first, on both the C++ and Python sides. Verified with a new dedicated headless test spawning all 3
distinct ranged archetypes present in Medical (Grenadier/SMG/Pistol, confirmed genuinely distinct
fire mode + damage, none matching the old flat stand-in) plus all 3 melee archetypes (confirmed none
now equip a weapon) — 0 failures. Regression-verified clean: `verify_gameplay_fidelity`,
`verify_scripting_movers`, `verify_vita_chamber`, `verify_import_scripts`, `verify_water`,
`verify_ai_combat`, `verify_ai_nav`, `verify_weapon_impacts_pie` (6/6). **Not done**: the other 20
maps' archetypes are unaudited (this pass only inspected Medical's 23), and `ArchetypeName` values
found so far only cover Pistol/SMG/Grenadier/Melee — Shotgun/Crossbow/ChemicalThrower archetypes may
exist elsewhere with their own naming quirks, unverified. A separate, unrelated pre-existing bug was
found (not fixed) in `verify_ai_archetypes.py`'s own spawn test — hardcoded coordinates that don't
correspond to real floor geometry in Medical's coordinate space, failing upstream of any archetype
code — **fixed 30 Sept 2026** (see "Most recent landed work" above): Medical-space probe + temporary
BlockAll ground slab; headless verify now PASSes with `spawnedHealth` 80.0.

The prior landed work: **roadmap priority 3, script-graph import on the 20 non-Medical
maps, done.** Previously proven on `1-Medical` only. Added `export-level-manifest`, a new CLI verb
(`src/BioShockStudio.Cli`) that does the same scene analysis as `export-level` but writes only the
`.ue5-level.json` handoff — no OBJ/mesh/rig/texture/cubemap writes, which `import_scripts.py` never
reads anyway (it only touches the manifest's `actors` array filtered to Script-class). Cut a real
story map's export from ~5.5 minutes to ~10 seconds, which is what actually made running this
batch across 20 maps practical instead of needing a whole separate tool (see commit `187dbab`
and `docs/research/` — the backward-compat regression this briefly caused,
`LevelSceneTests.MaterialsResolveAndTheirTexturesAreWrittenForAPlacedLevel`, was caught and fixed
before landing; 15/15 C# tests pass). Ran `import_scripts_all_maps.py` for real against all 20
maps (never dispatched before): **20/20 succeeded, 0 unmapped top-level actions, only 100 nested
actions unmapped across 3 distinct classes out of many thousands mapped** (4-Recreation: 88,
ChallengeRoomCombat: 12). Built the best-scoped of the three, `ActionSaveGame` (3 occurrences) —
a name-based scripted checkpoint save, extracted a widget-free `UShockSaveGame::SaveScripted`
helper from `UShockSaveLoadMenu::SaveToSlot`'s core logic (menu itself untouched, no regression
risk) and wired a new `UShockActionSaveGame` through it; re-ran the batch, confirmed closed. The
other two are deliberately NOT built here, each needing a real system this task's scope does not
cover: `ActionSetNextAssassinTeleportInRunDestination` (29 occurrences, 2 maps) needs an `Assassin`
AI archetype that does not exist at all yet (roadmap priority 4's job); `ActionChangeSkinToPhoto`
(68 occurrences, 1 map) needs Research Camera photo storage that isn't built (tracked separately
under Weapons' "Research Camera rewards" gap). Regression-verified clean: `verify_gameplay_fidelity`,
`verify_scripting_movers`, `verify_vita_chamber`, `verify_import_scripts`, `verify_water`,
`verify_weapon_impacts_pie` (6/6).

The prior landed work, newest first: `ActionEnableOrDisableTrainingMessages`'s mute gate
(roadmap priority 2's last remaining scripting-VM stub — see "Known-missing features" below for
detail; `verify_scripting_vm_stubs.py` now 37/37), a live-PIE weapon fix (ejected Tommy Gun shell
casings used the engine's bare default `Cylinder` mesh with no material ever assigned, rendering as
a flat grey artifact at the eject socket — reported live, gave it a real brass-toned master
material, `verify_weapon_impacts_pie` still 6/6 clean), and the real root cause of the SM5 "Sampler
type is Color,
should be Masks" family of compile errors, found only because the user's real (non-nullrhi) editor
session kept showing the live compile-error banner for `Wall_Leak_diff_shader` after TWO prior
"complete" fixes in this same saga. The actual defect was never just a node's own `sampler_type` —
it's that a node's `sampler_type` is checked against the TEXTURE ASSET it references, and no
earlier pass in this saga ever verified the asset side. Three distinct root causes, all fixed:
(1) a texture-asset naming collision — when Diffuse and Opacity slots share one source file, both
used to import to the SAME destination asset path, so whichever ran second silently overwrote the
first's colour-space settings (fixed: give the opacity-intent import its own `_Opacity`-suffixed
asset, plus a slot-based identity check replacing a broken file-based one, plus always resetting
`compression_settings` explicitly instead of leaving it inherited); (2) 30 further "mask"-kind
masters whose OpacityMask node was already correctly separate and already `SAMPLERTYPE_MASKS`, but
still pointed at the shared, correctly-`TC_DEFAULT` diffuse asset (fixed: `_masks_compressed_variant`
gives them a dedicated `_Mask`-suffixed duplicate); (3) the inverse on 2 `opaque`-kind masters
whose BaseColor node was itself stuck at `SAMPLERTYPE_MASKS` from a stale earlier build. A full
sampler-vs-texture-compression sweep across all 427 masters actually placed in `1-Medical` — not
just a sampler-vs-sampler one, which is exactly what missed this the first two times — now reads 0
mismatches. Regression-verified clean: `verify_gameplay_fidelity`, `verify_scripting_movers`,
`verify_vita_chamber`, `verify_import_scripts`, `verify_water`. See
`docs/research/medical-opacity-sampler-texture-compression-mismatch.md` (supersedes the
`docs/research/medical-opacity-sampler-legacy-shapes.md` fix, which was itself incomplete).

The prior landed work, newest first: a second material-shader fix (`WallTechAnim_Fan` and 39
siblings were misclassified opaque despite genuine cutout data, and a second instance of the 4
Sept SM5 "Sampler type is Color, should be Masks" compile bug existed in the mask-kind code path
the whole time, unfixed — see `docs/research/medical-mask-material-fix.md`), a live-PIE lighting
fix (raw BioShock light intensities
were never actually rescaled on the live slice — applied for real, all 666 lights), a Medical
glass-material opacity wiring fix (glass read the diffuse texture's own alpha instead of a real,
separately-exported opacity texture when one existed — `docs/research/medical-glass-opacity-fix.md`),
a weapon tracer visual fix (the debug-line tracer started inside the viewmodel's own close-range
render space and visually sliced through the gun), and the compiled-world mesh's one null material
slot (a genuine exporter-side gap, read as scattered "broken texture" checkerboard patches
level-wide — hidden rather than textured with an unverified guess, see
`docs/research/compiled-world-zoning-face.md`). All 29 Sept, all live-PIE-report-driven, all
regression-verified clean. Prior day's landings, newest first: `w20` (watchers, critical/immediate
execution flush,
`TestFact`, training-message HUD, `d9e8830`), `z1` (Medical's 19 per-instance water materials,
`ffa4f5a`/`b8b6777`), `w19` (interact-trace pipeline bugs fixed + real aim-point root-cause fix,
46→36 failures, `5b6eb43`), a light-shape/rotation fix and a same-day regression fix for it
(`977f7c4`, `a7f2b41`, `8705199`), the w18 live-PIE-bug fixes (`12e8b9c`), the B12 Vita-Chamber
default fix (`a247c4c`), and the y5–y8 scripting-fidelity SDK-audit batch (`957ed72` … `fa3332b`,
25–27 Sept 2026). All are described in their own sections below.

## Active work

| Who | Item | Files |
|---|---|---|
| — | (none claimed in this worktree) | — |

Cleared 7 Oct 2026 after landing BSP UV divisor = 2× original (`BIOSHOCK_BSP_UV_AUTHORED_SCALE`, default 2).


---

## Done and verified

**Verified** here means: a headless verify script passed, and — for anything visual — a human looked
at it running in PIE or a capture. Where only the headless half is confirmed, it says so.

- **Asset/decode pipeline** (the C# tool): essentially complete. See `docs/QUALITY.md` for the
  current sweep figures; not re-summarized here, per `docs/ROADMAP.md`'s "Asset & decode pipeline".
- **All 21 story maps imported** into `/Game/BioShockLevel/*`, geometry/materials/UVs/collision
  correct, lighting mapped. Spot-checked visually on several maps (3-Arcadia, 6-Slums, 1-Welcome).
- **`1-Medical` playable slice** (`/Game/BioShockSlice/1-Medical`): boots menu → possess → HUD →
  weapons → plasmids → AI encounter → pickups → vendors → death/Vita-Chamber respawn. This is the
  main target for live PIE testing; the open bug list below is entirely against this slice.
- **All seven weapons + Research Camera**, ammo-type switching, holster slots — headless-verified;
  human-confirmed in the 6 Sept audit for wrench and shotgun specifically (see "Weapon viewmodels"
  below for the live caveat).
- **Six plasmids** (Electro Bolt, Incinerate, Telekinesis, Winter Blast, Insect Swarm, Enrage) —
  headless-verified (`verify_plasmid.py`, 44 checks).
- **Hacking, security devices, the hacking minigame** — headless-verified (`verify_security.py`,
  `verify_hacking_minigame.py`).
- **AI**: goal/ability brain, combat loop, navigation, hit reactions, archetype-driven spawning — all
  headless-verified (`verify_ai_combat.py`, `verify_ai_nav.py`, `verify_hit_reaction.py`,
  `verify_ai_archetypes.py`, `verify_ai_brain.py`).
- **Scripting VM**: the y5–y8 SDK-audit batch (message senders, `messageFilter`, `Global_`
  variables, per-runner timers, nested boolean/arithmetic statements, door multi-match,
  `ScriptableMover` open/close messages) all landed with headless verifies
  (`verify_scripting_fidelity.py`, `verify_scripting_movers.py`) — **not yet re-confirmed live in
  PIE** beyond what the w18 pass touched.
- **Runtime audio**: weapon fire, footsteps, looping ambient sound with distance falloff and a
  dedicated Ambient sound-mix class. Landed 8 Sept 2026 (`8b29ac8`, `5f4e14e`) and refined 28 Sept
  2026 (`1ff4b04`, fixing ambient water blaring from 40 m everywhere). **This directly contradicts a
  stale note in `docs/ENGINEERING_RULES.md` §60** claiming runtime audio is "a separate, untouched
  gap" — see "Contradictions" below.
- **UI**: every screen (HUD, radial, full select, status/pause, all five station UIs, hacking
  minigame widget, main menu/frontend) recreated in UMG with the game's own decoded art. Headless
  verifies all green; visual likeness confirmed close-to-1:1 for HUD, main menu, and pause menu in
  the 6 Sept audit capture pass (`hud_hud.png`, etc.) — the other screens are headless-verified only,
  visual correctness not separately re-confirmed since.
- **Lighting**: light shape/rotation import (spot vs. sun/directional vs. point, from the authored
  `effect` byte) landed 28 Sept 2026 (`1b4d2db`), including a same-day fix for a regression it
  introduced (multiple scene-wide `DirectionalLight`s spawning, `977f7c4`) and a false-pass in the
  light-effect-drives-animation verify (`8705199`, `a7f2b41`).
- **Vita-Chambers**: fixed 28 Sept 2026 (`a247c4c`) to start inactive until the player approaches —
  previously both Medical chambers were usable from spawn with no player action, because `bActive`
  defaulted true and was force-set again by the importer.

## Landed but not yet PIE-confirmed by the user

Everything in this section has a green headless verify but has **not** had a human look at it running
in the actual editor/PIE session since it landed. Per this project's own standing rule ("a numeric
check cannot see a wrong quantity that is still present" — `docs/archive/NEXT_SESSION.md`), treat
these as provisional until someone plays them:

- The y5–y8 scripting-fidelity fixes (message fields, timers, movers, nested statements) — headless
  only.
- The 28 Sept light-shape/rotation import — headless only; the regression it introduced and its
  fix were both also caught and re-verified headlessly, not by a human looking at the result in PIE.
- **The user's 30 Sept screenshot bugs (3 Oct 2026).** Rendered captures confirm each fix; neither
  has been seen in PIE yet.
  - White translucent wedge at the arrival porthole: 11 of 14 beam actors had been put back on a
    raw white additive material by an importer rerun. import_bioshock now leaves repaired beam
    instances alone; the beam master fades out near the camera (you stand inside one beam tube there).
    Capture: viewpoint `arrival-porthole-steinman`.
  - Black octagon on the Machine Gun: debug-draw stand-ins for unrecovered weapon FX (grey impact
    puff, grey smoke sphere every 6th round, hit-marker spheres) drawn in the player's view. Now off
    unless `bioshock.FxStandIns 1`. The capture harness doesn't render the viewmodel, so the
    "on the receiver" part still needs a PIE look.
  - Saturated red light wash: **open, not a decode bug.** Light609 (194,37,20, radius 2000,
    LightType 7 SubtlePulse) and Light90 are authored deep red around the Neptune's Bounty
    quarantine gate. Candidates: Unreal mixes lights in linear space where the 2007 renderer
    mixed in gamma (overlaps stay redder), and LightPeriod (93) is treated as 93 s so the pulse is
    effectively frozen. 4 Oct: no reference screenshot is available. Walkthroughs place it at the
    Emergency Access lever, where an alarm sounds, so the red reads as authored alarm lighting.
    Fixed the one clear defect: LightPeriod is now LightPeriod/35 s per cycle (UE1/UE2's
    `time * 35 / LightPeriod`, PLAUSIBLE), applied by import_level and, for the saved slice, by
    repair_light_periods.py (30 lights; Light609 93 s -> 2.66 s). Still open, low priority: linear
    vs gamma-space light mixing keeps overlaps redder than the 2007 renderer would.
- The w18 fixes below **were** re-verified against the real Medical slice by the landing session
  (not just the sandboxed worker pass) — see the w18 entry for what was actually re-checked and what
  wasn't.

## Medical critical path (4 Oct 2026)

`verify_medical_critical_path` drives the slice's own imported scripts through Medical's 10
progression gates in game order (hallway switch, maintenance-hall look trigger, Steinman's waiting
room, the padlock, Eternal Flame, Steinman's death, the quarantine key, the Fisheries gate with and
without the key, the bathysphere). 10/10 pass. Getting there fixed four real blockers, any one of
which made Medical impossible to finish:

1. **Core reader:** an array of structs declares a size that omits each nested Object property's
   explicit size byte. Census over all 21 packages: 8,296 arrays affected (Materials 6,406,
   resolveInfoList 1,581, MaterialSlot 184, SequenceItems 121, PatrolEntries 4), none exact. The
   reader now corrects it exactly like the struct-size rule (`ArraySizeTests`). This dropped script
   getter links everywhere, including the Fisheries gate's "holds Steinman's key" check.
2. **Runtime:** no `ActionGetNumItemsInPlayersInventory` getter; added.
3. **Runtime:** resolve sources were evaluated once and cached, freezing live getters; now
   re-evaluated on every resolve.
4. **Importer:** `ActionUnlockBathysphereDestination` never got its MapName, so ToFisheries never
   unlocked 2-Fisheries.

The script-actions export (`1-Medical.script-actions.json`) is now format 3 (was a 27 Aug format 2
file) and also carries Object references by name (e.g. ItemClass).

**Follow-up, not yet done:** the reader fix also changes how 6,406 static meshes' `Materials`
arrays decode game-wide. The 1-Medical level manifest predates it; re-exporting it and checking the
capture set is the next step for material slots.

**Pre-existing failing verifies (not regressions — same failure with the old code):**
verify_script_ai_spawn ("no spawned turret"), verify_script_ai_tweak, verify_script_physics_exec
("impulse_velocity"), verify_script_spawn_attack ("no spawned AI"). verify_script_movement fails
only when run after other scripts in one boot (state leakage), and passes alone.

## Open bugs — the live PIE bug list

The user played the `1-Medical` slice live on 28 Sept 2026 and reported three groups of problems.
Cursor's investigation is `docs/research/w18-pie-regressions.md`; the fix commit is `12e8b9c`.

| Bug | Status | Detail |
|---|---|---|
| Gun impacts not registering on walls | **Fixed** | Root cause: Grenade Launcher / Crossbow projectiles never called into the impact-FX path at all (`AShockProjectile::Detonate`). Re-verified against the real slice, not just the sandboxed pass — the original verify script itself was checking the wrong return value and always failed; fixed and all 6 weapons now genuinely pass. |
| Ragdolls not activating | **Fixed** | `StartRagdoll` now re-pulls the physics asset from the skeletal mesh instead of trusting a possibly-stale component pointer. |
| Nothing interactable | **Mostly fixed, 36 interact-trace failures remain (was 46)** | Root cause 1 (fixed): pickup collision ignored `ECC_Visibility` on every channel except a Pawn overlap, so the interact trace (which uses `ECC_Visibility`) could never hit a pickup. Fixed for newly-spawned actors; the 147 already-placed pickups in the live slice were destroyed and respawned to pick up the fix. Root cause 2 (w19, fixed): the verify harness's `FaceActor` aimed at a flat `actor location + (0,0,40)` point regardless of the target's actual collision size — for a pickup sitting flush under a shelf (e.g. `ShockConsumablePickup_12`, sphere center Z=8095, sphere top Z=8143, shelf underside Z=8142.5) that fixed offset landed within a few uu of the shelf's own collision, so the trace sometimes clipped the shelf instead depending on stand angle. Switched to `GetActorBounds(true)`'s collision-only origin (the true center of whatever collision volume blocks the trace) — 46 → 36 failures, confirmed by a real headless re-run, not guessed. **Still failing (36, unchanged after a w21 attempt): 20 `wrong_mesh_or_blocker`, 9 `no_hit`, 7 `wrong_interactable`** (stacked loot — confirmed cause, first-hit-wins is a deliberate behaviour not changed). w21 measured real per-case collision overlap for all 29 in-scope cases and tried a single-axis placement nudge on the 3 with a genuine flush overlap (8.5uu, 3.3uu, 2.1uu) — the nudge didn't close the gap (moving `ShockConsumablePickup_12` traded one flush graze for a different one; the other two just made `FaceActor`'s multi-candidate ring probe pick a different stand point, still blocked) and was reverted rather than left as an unvalidated position drift. Real finding: the interact-trace failure and the measured collision overlap are not as tightly coupled as they looked — `FaceActor`'s ring probe is sensitive enough to uu-scale position changes that fixing the geometry doesn't reliably fix the trace outcome. See `docs/research/w19-remaining-interact-fails.md` and `docs/research/w21-interact-trace-placement-nudge.md`. Next real attempt needs either a placement search that checks clearance against *all* nearby geometry (not just the one reported blocker) or a `FaceActor` strategy that isn't ring-probe-sensitive — both bigger than either task's scope so far. |
| Wrench viewmodel position | **No regression found — needs a live screenshot to confirm, not a code question** | `docs/archive/AUDIT_2026-09-06.md` (6 Sept) recorded the wrench viewmodel as fixed (`35f459c`, held by the handle, head up-forward); the same day `d479fbe` moved that correction onto the hands-rig socket via the manifest and removed the now-redundant component-level hack. Later viewmodel commits (`d256b09`, `41c0e1a`) and w18 (`12e8b9c`) never touched socket/wrench orientation code. No later commit undoes the manifest socket rotation. If it still looks wrong live, it's a fresh capture needed against the current socketed mesh (headless attach verifies can't see grip orientation), not a known bug to fix blind. |
| Bathysphere room water/stairs | **STATUS UNCLEAR — verify** | No tracked doc describes this specific room or bug. Medical does contain a bathysphere pavilion with `FX_StairWater_C` instances and nearby `FluidVolume`/`CascadingWaterVolume` actors (see `docs/research/w19-remaining-interact-fails.md` §3 for the actor census), and `FX_StairWater` is deliberately kept non-colliding by `restore_floor_prop_hulls.py` (matched the `_FLOOR` regex) — a known prior fix for a different problem, not evidence this room's complaint is fixed. Still unknown without a live screenshot: whether the complaint is water material look, a colliding water sheet, a missing walkable stair hull, or something else near the airlock. |
| FisheriesAccordian locked-gate question | **Resolved — the gate is real and correctly gated, just not on the flag first suspected** | `AccordianGateDoor1` (`FisheriesAccordian`) unlocks via `ActionUnlockDoor18`/`ActionOpenDoor6` on Script label `quarswitched`, gated by `ActionIf929` testing `BooleanStatement61`: an **inventory item-count check** (`Get Number of Items in Inventory == 1`, quarantine-key style), not a global flag. `Global_Med_OpenedMedicalGate` is a real flag but is only ever read once (a quest-hint on label `NeedSteinmansKey`) and never assigned anywhere in the exported script data — it does not gate this door. See `docs/research/w19-remaining-interact-fails.md` §4 for the full trace. |

## Known-missing features

Systems that don't exist yet, not content gaps within an existing system (see `docs/ROADMAP.md` for
the per-system detail and priority order — this is a summary, not a repeat of every line):

- **Tonics** — no system at all; Gene Bank UI is plasmids-only.
- **Quest hints/content** — the state machine itself is real and live (`AShockPlayer`, see
  `docs/ROADMAP.md`'s "Inventory, economy, and player systems" for the corrected description,
  28 Sept 2026); what's actually missing is quest hint/objective text beyond a bare name, and
  nothing in script import yet calls `InitiateQuest` from real Medical script data.
- **U-Invent crafting** — runs against generic inventory stacks, no component bag or recipes.
- **Weapon/plasmid icon art** — never located in any decoded SWF; UI shows name + brass ring only.
- **Level-to-level travel at scale** — the mechanism works, proven on one synthetic test map only;
  the real 21-map bathysphere graph is unbuilt.
- **Scripted cinematic sequences** — the Medical set-pieces (doctor-killer intro, Steinman surgery,
  first Big Daddy sighting) are unbuilt; the data exists in the decoded scripts.
- **Gatherer/Protector ecology** — Little Sister harvest, Big Daddy AI, the ADAM choice. Explicitly
  its own later project.
- **God rays** — decal/particle stand-ins exist for some effects; not yet real UE5 material work.
  Water is done (`z1`, 28 Sept 2026) — Medical's 19 `FluidShader` surfaces now carry their own
  decoded textures/pan values, not one generic stand-in. **Glass is also done, corrected 29 Sept
  2026** — this file previously said glass material slots were "not yet real UE5 material work";
  that was wrong. All 25 of Medical's glass materials were already correctly built (real textures,
  correct translucent classification); the actual bug was a wiring mistake (Opacity always read
  the diffuse texture's own alpha instead of a separately-exported opacity texture when one
  existed), fixed live — see `docs/research/medical-glass-opacity-fix.md`. Decals remain a real,
  separate, un-fixed gap: they are genuinely textureless by design (a procedural radial-falloff
  stand-in, no bullet-hole art was ever recovered), not a bug.
- **Watchers, critical/immediate script execution mode, `TestFact`, training-message HUD** — all
  landed 28 Sept 2026 (`w20`). `ActionEnableOrDisableTrainingMessages` landed 29 Sept 2026: sets a
  real mute gate on `AShockPlayer` (`bTrainingMessagesEnabled`, default true); while disabled,
  `ActionShowTrainingMessage` is a no-op (`ActionClearTrainingMessage` still always goes through).
  Verified headless: 6 new checks in `verify_scripting_vm_stubs.py` (mute suppresses a new toast,
  unmute restores it), 37/37 pass. Still open: nested-loop critical-sub-action expansion during a
  travel flush (the flush walks the flat remaining run queue only).
- **Menu stubs** — Options, Credits, Director's Commentary, Museum, Challenge Rooms.
- **HUD liquid-fill material** (`M_Hud_LiquidFill`) — renders invisible, flat-tint fallback forced.
- **Audio diaries, music, per-language audio routing** — audio playback exists for weapons/footsteps/
  ambience; diaries and music are not wired.

## Never dispatched (queued in an old plan, superseded, not completed under that name)

`docs/archive/FULL_GAME_CONVERSION.md`'s task queue named `x1`–`x12`. Only `x1`, `x3`, `x5`, `x6`,
`x7` were ever created and landed (prop-mesh import, VM param resolution, actions reflection,
actions visibility/AI/items, the EffectsSystem subsystem). **`x2`, `x4`, `x8`, `x9`, `x10`, `x11`,
`x12` were never dispatched under those names** (confirmed: no `tools/agents/tasks/x2*` etc. file and
no "queue x2" commit exists). Their underlying goals were partially reached by later, differently-named
work:

- `x2` (material-slot fixes) — substantially covered by the later `g4`/`h9`/`d`-series texture work.
- `x4` (VM watchers/timers) — timers landed (`y6`); watchers landed (`w20`, 28 Sept 2026).
- `x8` (effects stand-in FX pack) — partially covered by `w15` (impact FX) and `w9` (plasmid VFX);
  not confirmed as a complete stand-in pack.
- `x9` (skeletal-prop idle animation) — **STATUS UNCLEAR — verify**, no evidence found either way.
- `x10` (latent AI actions / cinematic sequences) — **not done**; see "Scripted sequences /
  cinematic AI" in `docs/ROADMAP.md`.
- `x11` (security goals) — substantially covered: `AShockSecurityBot`/`AShockSecurityCamera`/
  `UShockSecuritySubsystem` all landed under different task names. Patrol/protect/return-home goal
  paths for bots are still open.
- `x12` (Gatherer ecology) — **not started**, confirmed as its own later project.

## Contradictions found between the old docs (flag to the user)

1. **Runtime audio.** `docs/ENGINEERING_RULES.md` §60 "Audio — current standing state" says (dated
   "noted 6 Sept 2026"): *"Runtime audio is a separate, untouched gap... do not start wiring runtime
   audio unless the user asks."* This was already false two days later: `w1-runtime-audio` landed
   8 Sept 2026 (`8b29ac8`, weapon fire/footsteps/ambience/vocals) and was refined again 28 Sept 2026
   (`1ff4b04`). **This is stale status embedded in a rules document** — flagged per the consolidation
   task's instructions rather than silently edited, since `ENGINEERING_RULES.md` itself was out of
   scope for this pass.
2. **The `1-Medical` "unsupported" actor count.** `docs/archive/UE5_FULL_PORT_PLAN.md` and
   `docs/archive/ROADMAP.md` both quote 7,337 unsupported actors on `1-Medical` in several places;
   `docs/archive/UE5_FULL_PORT_PLAN.md` §9 itself later corrects this to 2,018, identifying the
   7,337 figure as a double-counting bug in `import_level.py` present since the importer was first
   written. Both documents keep the wrong 7,337 figure in earlier sections after the correction is
   recorded later in the same document — not fixed retroactively in the old docs (they are now
   archived unmodified). Use 2,018 as the correct historical figure if it comes up.
3. **Cursor-lane task-list currency.** `docs/archive/DUAL_AGENT_ROADMAP.md` says its own "Cursor
   lane" work-item list is a stale 28 Aug snapshot not re-derived against
   `docs/archive/FULL_GAME_CONVERSION.md`'s Phase A/B/C/D structure, and to treat it as historical
   framing rather than a live queue. It was left in the document rather than removed. No action
   needed — already self-flagged in the source, noted here only for completeness.
4. **`docs/archive/HANDOFF.md` §6.0c vs. `docs/archive/ROADMAP.md` Gate 2 item 1** both describe the
   54-track bone-collapse animation family and reach the same conclusion (blocked on missing Havok SDK
   function bodies, declined on licence grounds) — not a contradiction, but the same investigation is
   fully duplicated across two files. Read either; they agree.

## Where the process/rules docs are accurate vs. stale

Per this consolidation task's scope, `docs/ENGINEERING_RULES.md`, `docs/QUALITY.md`,
`docs/EFFICIENCY_RULES.md` and `docs/GUI.md` were read but not modified or merged — they are process
docs, not status docs. One stale-status-in-a-rule was found and is recorded above (runtime audio).
No other embedded status claims were found to be contradicted by current repository state in the
sections reviewed; `docs/QUALITY.md` in particular is an evidence/measurement record (pinned by
`DocumentedFiguresTests`) and is explicitly treated elsewhere as authoritative over prose status docs
— that role is unchanged by this consolidation.
