# Plasmid presentation and the four added abilities

Status: **runtime implemented + headless-verified 9 Sept 2026.** Cast logic already existed
(`UShockPlasmid` + 6 subclasses, `verify_plasmid` green). This pass adds the first-person
plasmid arm, cast presentation FX, and the four plasmids the framework was missing. Appearance
is a human `-game` check — the shipped UE2 particle graphs are not recovered, so the FX are
emissive stand-ins.

## First-person plasmid arm

`AShockPlayer::PlasmidHands` is a second `USkeletalMeshComponent` on the camera, sharing the
`NEWPlayerHands` mesh but never sharing animation state with the weapon `ViewHands`
(separate `UShockViewHandsAnimInstance`).

- `SetPlasmidHandActive(bool)` switches presentation: equipping/selecting/cycling a plasmid
  raises the arm and hides the weapon + `ViewHands`; `EquipWeapon` lowers it again.
- `ResolvePlasmidHandsPresentation()` tints the arm per plasmid (`UShockPlasmid::HandTint`)
  through a `M_PlasmidHand_Base` dynamic material and loads the idle/cast clips named by
  `HandIdleAnimation` / `HandCastAnimation` (default `Generic_Fidget` / `Generic_Fire`).
- On cast, `PlayActivePlasmidCastAnimation()` plays the one-shot cast clip;
  `TickPlasmidHandsAnimation` returns to idle when it finishes.
- **APPROXIMATION**: the exact per-plasmid `UAPW_NEWPlayerHands` leaf names (`EveArmJab`, the
  `Irritant_*` / `Vortex_*` / `TK_*` families) are not confirmed against the imported anim set,
  so every plasmid currently uses the generic pair. `Generic_Fidget` / `Generic_Fire` are not
  in the slice content yet — `LoadViewHandsAnim` returns null and the arm holds a static pose
  until those clips are imported. The tint, the switch, and the FX all work regardless.

## Cast FX

`AShockPlasmidFx` — a cheap, short-lived actor that owns a Niagara component **and** an emissive
orb/beam static mesh. `SpawnBurst` / `SpawnBeam` set the mesh visible and tint it through
`M_PlasmidFx_Base` (authored by `author_plasmid_fx_standins.py`), so a cast is visible even
though the `NS_*` Niagara systems don't exist. `CastActivePlasmid` spawns a burst at the hand
and, for a targeted cast, a second at the impact point. The four new plasmids also spawn their
own shaped burst/beam.

**STAND-IN**: all `/Game/BioShockFX/Plasmids/NS_*` asset paths are contracts for later Niagara
authoring; nothing is decoded from the shipped particles. The 6 pre-existing plasmids keep their
`DrawDebug` spark/arc draws on top of the generic burst.

## The four added abilities

Constants are **CONFIRMED_EXTERNAL** from `tmp/uc_shockgame/*Ability.uc` (`BioAmmoCost`); force
curves, decoy meshes and beacon flight are native and marked PLAUSIBLE.

| Class | UC source | Behaviour in the slice |
|---|---|---|
| `UShockAirBlastPlasmid` | `AirBlastAbility`, cost 15 | 20° forward cone to 800 uu: light damage + `LaunchCharacter` knockback. |
| `UShockSecurityBullseyePlasmid` | `SecurityBeaconAbility`, cost 5 | Marks the hit `ABaseShockAI`; every placed `AShockSecurityBot` gets `CommandAttackLabel(target)`. Camera-summon is not modelled. |
| `UShockTargetDummyPlasmid` (+ `AShockPlasmidDecoy`) | `DecoyHumanAbility`, cost 8 | Spawns a decoy that pulses `ABaseShockAI::BroadcastSuspiciousNoise` every 0.75 s for 12 s (reuses w13 hearing) — nearby splicers break off to investigate it. |
| `UShockCycloneTrapPlasmid` (+ `AShockCycloneTrap`) | `SpringBoardTrapAbility`, cost 16 | Places a 90 uu overlap trap at the aim point; the first character to step on it is launched straight up, then it expires. |

All four resolve through `UShockPlasmid::ResolvePlasmidClass` under both their display name and
their `.uc` script alias (`SonicBoom`, `SecurityBeacon`, `DecoyHuman`, `SpringBoardTrap`), so
the existing Gatherer's Garden / Gene Bank equip flow needs no new cases.

## Regression fixed in passing

w13's `TickCombat` / `TickBehaviour` gate everything on `BehaviourState == Combat`.
`ApplyEnrage` cleared the player target without entering Combat, so an enraged splicer just
stood still (`verify_plasmid` `enrage_hits_other` = 0). `ApplyEnrage` now enters Combat and the
behaviour/combat ticks tolerate an enraged AI with no current target while the brain
re-acquires the victim.

## Verification

`verify_plasmid.py` (now 55 checks): the four classes resolve under name + alias; a fresh
caster equips and casts each (≥3/4 land headlessly — Security Bullseye needs a real AI under the
aim trace); the plasmid arm reports visible; each cast spawns an `AShockPlasmidFx`.
`run_ai_behaviour` / `run_ai_combat` / `run_encounter` green. Seeing the arm + FX in first
person is a human `-game` check (equip a plasmid on Q, cast on Left Alt).
