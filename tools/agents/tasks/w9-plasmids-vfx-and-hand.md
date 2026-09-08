---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, src/**, docs/research/**, tmp/**
---

# Make plasmids actually work — first-person hand, cast animation, real VFX, the missing plasmids

The plasmid **logic** is done: `UShockPlasmid` base + `CastActivePlasmid` (EVE check, trace,
cooldown), and 6 subclasses — `ElectroBolt`, `Incinerate`, `WinterBlast`, `Telekinesis`,
`InsectSwarm`, `Enrage` — apply damage / stun / burn / freeze / grab-throw / aggro-flip.
`verify_plasmid` (53 checks) passes. **But in-game a plasmid cast is invisible**: every effect
draws a `DrawDebugSphere` / `DrawDebugLine`, there is no first-person plasmid hand, no cast
animation, and ~5 of the game's plasmids don't exist yet. It doesn't read as BioShock at all.

## 1. First-person plasmid hand

BioShock shows your **left arm** doing the plasmid — a bare/veined arm, tinted per plasmid
(electric blue, fire orange, ice, the bee hand), with its own idle and cast animations, separate
from the weapon `ViewHands`.

- The rig is the `Hands` / `NEWPlayerHands` export's plasmid side. Materials exist in the bulk
  catalog: `eve_diffuse`, `handfire_ice_o`, `handsanc_normal`, `plasmid_glass_diffuse`. The
  weapon-hands anim sets have `EveArm*` / plasmid clips (`docs/research/audio.md` mentions
  `EveArmJab`) — `dotnet run --project src/BioShockStudio.Cli -c Release -- animations
  <package> UAPW_NEWPlayerHands` to list them; `export-firstperson` / `export-fbx` to get them.
- Add a `PlasmidHands` skeletal component on `AShockPlayer` (mirror `ViewHands` setup — fixed
  eye-relative transform, no shadow), shown when a plasmid is the active hand, hidden when the
  weapon is up (BioShock switches; `Q` / the plasmid-cast context). Tint its material per the
  active plasmid.

## 2. Cast animation

- Play the plasmid idle loop on `PlasmidHands`; on cast, play the cast/jab clip (per plasmid
  where the game has distinct ones — ElectroBolt flick vs Incinerate throw vs Telekinesis pull).
- Reuse the crossfading `UShockViewHandsAnimInstance` pattern (`ba2973f`) if it fits, or a
  simpler `PlayAnimation` for the one-shot.

## 3. Real VFX (replace the debug draws)

Per plasmid, a Niagara or Cascade system (author under `/Game/BioShockFX/`), triggered from
`UShock*Plasmid::Cast` / `Apply*`:
- **ElectroBolt** — an arc from the hand to the hit, blue crackle at the target, chain arcs in
  water (`ChainInWater` already computes the targets — attach an arc to each).
- **Incinerate** — a short fire burst from the hand + a burning decal/flame on the target while
  `BurningRemaining > 0` (the AI already tracks burn — hook the visual to it).
- **WinterBlast** — an ice cone + frost buildup on a frozen target (`ClearFrozenState` exists).
- **Telekinesis** — a glow around the grabbed object + a distortion at the hand.
- **InsectSwarm** — the bee cloud: `ShockInsectSwarm` actor should carry a particle/mesh swarm
  orbiting the target, not just a damage volume.
- **Enrage** — a brief haze on the affected AI.
Keep them cheap. Where the shipped particle asset can't be recovered, author a stand-in and say
so in the doc.

## 4. The missing plasmids

The decompiled UC has `AirBlastAbility` (Sonic Boom / the knockback), `SecurityBeaconAbility`
(Security Bullseye), `DecoyHumanAbility` (Target Dummy), `SummonProtectorAbility`,
`SpringBoardTrapAbility` (Cyclone Trap), `IcicleAssaultAbility`. Add `UShockPlasmid` subclasses
for at least **AirBlast, Security Bullseye, Target Dummy, Cyclone Trap** — EVE cost from the
`.uc` `BioAmmoCost`, behaviour faithful to the ability (AirBlast = radial impulse + light
damage; Bullseye = mark an AI so turrets/bots attack it; Target Dummy = spawn a decoy that
draws aggro; Cyclone Trap = a placed trap that launches whoever steps on it). Wire them into
`ResolvePlasmidClass` and the Gatherer's Garden / gene-bank equip flow.

## Deliverable

- `docs/research/plasmids.md` — the hand rig + anims, per-plasmid VFX (confirmed vs stand-in),
  the new plasmid classes with their `.uc`-sourced constants, what's approximated.
- Runtime: FP plasmid hand + cast anim + VFX for the 6 + 4 new plasmids.
- Headless: `verify_plasmid` still 53/53; new checks that casting spawns an FX component and the
  new plasmid classes resolve + apply their effect. Log lines
  (`BIOSHOCK_PLASMID cast=ElectroBolt fx=<asset> hand=1`).
- `-game` captures: each plasmid mid-cast (`capture_shot.ps1` + a plasmid-cast capture flag you
  add, a few settle values) showing the hand + the effect.

## Constraints

- `tools/ue5/**` + `src/**` (additive, Fast tests green) + `docs/research/**` + `tmp/**`.
- Editor CLOSED for headless. `-run=pythonscript` → JSON. MSYS forward-slash + `MSYS_NO_PATHCONV=1`.
  Kill stray procs between runs.
- Don't touch h11 compiled-world mobility/collision.
- Do NOT commit. Diff for review; human confirms the plasmids in Play.
- Read the `*Ability.uc` files + `docs/research/` before deriving behaviour or constants.
