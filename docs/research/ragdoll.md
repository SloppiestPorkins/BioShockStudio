# Medical ragdolls and lightweight physics (7 September 2026)

## Evidence

- **CONFIRMED_SOURCE:** `DeadBodyContainer.uc` starts with
  `StartingPose=(...,PoseRagdollState=1)` and does not block players.
- **CONFIRMED_SOURCE:** UModel's BioShock animation-package reader identifies
  `m_masterRagdollInstance` plus high/low skeleton mappers in the shipped Havok package. It does
  not decode the rigid bodies or constraints, so those bytes cannot be transferred faithfully.
- **CONFIRMED_RUNTIME:** a lethal verify hit logged
  `BIOSHOCK_RAGDOLL_ACTIVE ... physicsAsset=AggressorBabyJane_PhysicsAsset` followed by
  `BIOSHOCK_RAGDOLL_OK dead=1 active=1`.

## Physics assets and placed corpses

`repair_ragdoll_physics.ps1` imports one rig per editor process, then
`repair_ragdoll_physics.py` generates and assigns UE physics assets. The process boundary is
required: UE5.7's async loader asserted when a second skeletal replacement followed the first in
one commandlet. `SkeletalMeshEditorSubsystem.create_physics_asset` does persist headlessly (unlike
Static Mesh Auto Convex).

Medical uses six body meshes: `Agg_BabyJane`, `Agg_Doctor_Mesh`, `Agg_LadySmith`,
`CorpseCrispy`, `CorpseFemale`, and `CorpseMale`. The source rig exports all call their FBX object
`AggressorBabyJane`; importing them naively overwrote one package. The repair gives the five
non-combat meshes unique destination folders and restores Baby Jane last. The measured slice pass
assigned those six physics assets and configured 21 placed corpse actors as sleeping ragdolls.
A stale static-mesh corpse placement is replaced with a `SkeletalMeshActor`.

Sleeping is best-effort because UE5.7 does not expose `PutAllRigidBodiesToSleep` to Python on every
build. They still simulate with gravity and the Ragdoll profile, so they settle on load and react
to world impulses. This is a UE auto-generated capsule/constraint approximation, not a claim that
the original Havok limits or masses were recovered.

## AI death flow

`ABaseShockAI::OnDeathFromDamage` now:

1. preserves the existing death animation pose;
2. disables capsule and character movement;
3. switches the body to Query+Physics with the Ragdoll profile (WorldStatic blocks; Pawn and
   Camera ignore);
4. enables all rigid bodies and wakes them;
5. blends animation-to-physics from 0.2 to 1.0 over 0.2 seconds;
6. applies the killing hit's world direction, impact point, and bone when supplied by a weapon.

Non-hit damage derives direction from the instigator. Scripted/environmental damage with no
source gets no fabricated impulse. `CorpseFadeSeconds` remains intact; physics does not alter
health, dead state, death notification count, or encounter targeting.

## Dynamic prop set

`fix_prop_collision.py` makes only deliberately lightweight, simple-hull actors dynamic:
bottles, standalone cans/cups/plates, ashtrays, serving/food trays, small debris, standalone
bricks, wooden chairs, and trash cans. Medical currently selects 25 placements. Mass is bounded
to 0.35, 1.5, or 4 kg from size. Heavy furniture, fixtures, architecture, trash piles, and
diamond-plate panels stay non-simulating; the latter two are explicit regression exclusions.
