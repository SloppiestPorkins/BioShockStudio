# BioShock 1 splicer behaviour

Scope: the UE5 `ABaseShockAI` playable-slice reconstruction. Source is the decompiled
`ShockAI` UnrealScript in `tmp/uc_shockai`; native Tyrion action bodies that did not decompile are
not claimed as known.

## State rhythm

**CONFIRMED_EXTERNAL (class/action declarations), approximated execution.**

`EcologyFighter.CharacterAICreated` installs `PatrolAction`, `SearchAction`, and
`InvestigateAction`; `Aggressor.CharacterAICreated` adds `FleeAction`. The runtime therefore uses:

`Idle/Patrol -> Alert -> Investigate -> Search -> Idle/Patrol`

Sight or intentional player damage enters `Combat`. Losing line of sight records the target's last
known location, waits the attacking vision decay, then enters `Investigate`. Seeing the target
during Search re-enters Combat. A named patrol remains at its authored spawn when patrol points are
not imported; choosing a random point would invent level data.

| Constant | Shipped declaration | UE5 use |
|---|---|---|
| perception update | `NormalLODVisionTickUpdateRange=0.25` | scan every 0.25 s |
| attacking memory | `Aggressor.AttackingVisionDecayTime=4` | Combat -> Investigate after 4 s hidden |
| search duration | `EcologyFighter.Min/MaxSearchTime=12/20` | randomized Search duration |
| investigate turn | `ShockAI.SpotEnemyTurnDelay=0.25` | Alert pause before Investigate |
| investigate arrival | `MaxDistanceToApproachVisibleInvestigateLocation=200` | 200 uu acceptance |
| investigate local sweep | `InvestigateAction.DistanceToSearch=500` | documented; UE5 turns in place |
| group propagation | `DistanceForAggressorsToJoinInvestigation=1000` | nearby AI enters Alert |
| flee distance | `FleeAction.MinDistanceToFlee=1000` | destination 1000 uu away |
| flee cooldown | `FleeCooldownTimeRange=20..40` | not used; one 1000 uu flight per low-health episode |

## Perception

**CONFIRMED_EXTERNAL.** `Aggressor.uc` defines layered cones rather than one UE cone. The current
direct-sight approximation uses its non-doubt forward cones: 40-degree full FOV to 700 uu and
20-degree full FOV to 2200 uu, plus a visibility trace. The shipped cone gain times range from
0.01 to 1.0 seconds; UE5 scans at 0.25 seconds but does not yet accumulate separate gain per cone.
`AttackingVisionDecayTime=4` supplies last-known-position memory.

**APPROXIMATION.** The shipped `ShockAI` default says `bHearingDisabledPermanently=true`, while
`AggressorCommanderAction.HandleSuspiciousEvent` clearly handles suspicious sound categories.
The missing native/config override prevents a byte-exact hearing falloff. UE5 wires player
footsteps at 700/1000 uu, weapon fire at 2000 uu, and exposes `NotifySuspiciousNoise` for broken
glass/script events. These radii are integration defaults, not claimed shipped constants.

## Combat profiles

**CONFIRMED_EXTERNAL constants.**

- Thuggish/melee: `MeleeThugAttackAction` closes to the weapon animation translation range,
  attacks, then moves laterally with `ChanceToMoveAfterAttacking=0.65`. UE5 has a visible 0.35 s
  wind-up and 220 uu/s lunge before damage. The exact initiate-damage time is native and
  **UNKNOWN**; 0.35 s is explicitly an approximation.
- Pistol/ranged: `RandomRangeBurstShots=5..7`,
  `RandomRangeBetweenBurstShots=0..0.75`, cover chance against the player `0.75`,
  cover checks every `0.25`, reload chance `0.5`, reload interval `8..12`, and
  `TimeToStartMovingAgainRange=2..4`. UE5 fires 5-7-shot bursts and strafes for 2-4 seconds.
  Imported cover nodes do not currently exist, so the strafe is an **APPROXIMATION**, not a claim
  that cover selection matches the native `FindPointToAttack` body.
- Grenadier-specific projectile cadence remains **UNKNOWN/not implemented**. The current ranged
  stand-in weapon is hitscan.
- Ceiling/wall movement for `CeilingCrawler` remains **not implemented**; no such archetype has
  been established in the current Medical spawn records.

The low-health threshold is 25%. `Aggressor.HealAtHealthStationHealthPct=0.25` is shipped, but the
native suspicious-event `ShouldFlee` condition did not decompile and no general morale scalar was
found. Reusing 25% for requested low-health Flee is therefore **APPROXIMATION**, not a recovered
morale constant.

## Speech and animation

State entry maps to shipped speech tags used by the actions:
`BeganAttackingSpeech`, `CurrentlyInvestigating`, `TargetLost`, `FinishedSearching`, and
`Terrified`; damage and death retain `DamagedSpeech` and `DiedSpeech`.

The intermittent reference pose was caused by treating cached `LastPlayedAnim` as proof that a
single-node animation was still installed. `SetSkeletalMesh` or anim-instance recreation can clear
the player without clearing that pointer. The driver now checks the live
`UAnimSingleNodeInstance`, reinstalls Idle (or Walk/Run fallback), refreshes bone transforms, and
retries asset resolution if all locomotion loops failed to load.

`verify_ai_behaviour.py` covers stationary untargeted behaviour, sight -> Combat, hidden target ->
Investigate, 25%-health Flee, and a non-reference animation after one second. It writes JSON under
`%TEMP%` through `run_ai_behaviour.py`.
