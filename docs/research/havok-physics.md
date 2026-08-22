# Havok collision and ragdoll data

**Implementation so far:** `HkpCapsuleShapeReader` (`Havok/Physics/`)
**Tests:** `HavokPhysicsTests`

Gate 2 item 3 of `docs/ROADMAP.md` ("map Havok collision/ragdoll data to UE5 Physics Assets") was
genuinely unstarted before this note — only *presence* had ever been checked
(`CharacterCatalog.DeclaresRagdoll`, a literal search for the string `hkaRagdollInstance` used purely
to classify an asset as a character, never to read a payload). This is the scoping pass: what the
game actually ships, one class fully decoded as the first case, and what each remaining class would
need.

## Scale — `CONFIRMED_BYTES`

**207 of the game's 870 animation wrappers declare a ragdoll** (`CharacterCatalog`'s existing
census). One representative character, `AggressorBabyJane` (73-bone humanoid rig), carries in its own
Havok packfile:

| Class | Count | What it is |
|---|---|---|
| `hkpRigidBody` | 17 | One per ragdoll bone — the dynamics half of the body. |
| `hkpCapsuleShape` | 17 | One per rigid body — the collision volume. **Decoded, see below.** |
| `hkpConstraintInstance` | 16 | One per joint (17 bodies, 16 joints connecting them). |
| `hkpRagdollConstraintData` | 16 | The actual joint — limits, motor, local transforms — that each `hkpConstraintInstance` points at. |
| `hkaRagdollInstance` | 1 | The top-level object: which rigid bodies, which constraints, and the bone-to-body map. |
| `hkaSkeletonMapper` | 2 | Maps the ragdoll's own (17-bone) skeleton onto the animation skeleton (73-bone) and back. |
| `hkpPositionConstraintMotor` | 1 | A motor on one specific constraint (not yet identified which). |

17 rigid bodies against a 73-bone skeleton is deliberate simplification — not every bone gets its own
physics body; a ragdoll typically merges small bones (fingers, individual spine vertebrae) into their
nearest simulated parent. Which 17 of the 73 is not yet read — that is exactly what
`hkaRagdollInstance::m_boneToRigidBodyMap` (below) would answer directly, without inference.

## Decoded: `hkpCapsuleShape` — `CONFIRMED_BYTES`

The simplest of the seven classes, and the first fully read. See the reader's own doc comment for the
full record; summary:

```
hkpCapsuleShape : hkpConvexShape : hkpSphereRepShape : hkpShape : hkpShapeBase : hkcdShape : hkReferencedObject
+16  hkReal      m_radius     (hkpConvexShape's own field)
+32  hkVector4   m_vertexA    (xyz = local position, w = radius again — an hkSphere)
+48  hkVector4   m_vertexB    (same)
```

Held across **all 17 capsules on this character, 0 disagreements**: `m_vertexA.w` and `m_vertexB.w`
both equal `m_radius` exactly (`HavokPhysicsTests.EveryCapsuleShapeDecodesToAPlausibleBodyProportion`).
Every decoded radius (0.06–0.24) and length (0.09–0.92) is a plausible human-body proportion — **in
metres**, three orders of magnitude smaller than the same character's mesh/animation data, which is
centimetre-scaled. That is the expected Havok authoring convention (physics content in metres
regardless of the art scale), not a bug, and it means **nothing decoded here should be combined with
mesh/animation coordinates without an explicitly confirmed, separately-tested scale factor** — a
UE5 Physics Asset importer would need that conversion, and it has not been derived yet.

## Decoded: `hkaRagdollInstance` — `CONFIRMED_BYTES`, 22 Aug 2026

```
hkaRagdollInstance : hkReferencedObject
+0   hkReferencedObject                    (vtable + refcount, zero on disk)
+8   hkArray<hkpRigidBody*>       m_rigidBodies
+20  hkArray<hkpConstraintInstance*>  m_constraints
+32  hkArray<int>                 m_boneToRigidBodyMap
+44  hkRefPtr<const hkaSkeleton>  m_skeleton
```

Every field cross-validates against the whole-packfile census, not just its own header shape:
`m_rigidBodies` resolves to exactly **17** elements (matching the independently-counted `hkpRigidBody`
total above), `m_constraints` to exactly **16**; the array's own data lands exactly at
`objectOffset + 48` — the object's own size, i.e. Havok packed the array contents immediately after
the referencing object, with no gap — and its first four resolved pointers land exactly on the
offsets of the first four `hkpRigidBody` objects `HavokPackfile.EnumerateObjects` finds independently,
in order. `m_boneToRigidBodyMap` is `[0, 1, ..., 16]` — identity — meaning this ragdoll's *own*
17-bone skeleton (not the 73-bone animation skeleton) maps every one of its bones straight onto a
rigid body; `m_skeleton` resolves to a real, class-named `hkaSkeleton`, confirmed distinct from
`AnimationPackage.Skeleton` (the 73-bone one this project already exposes) rather than assumed to be
the same object. `HkaRagdollInstanceReader`, `HavokPhysicsTests.RagdollInstanceCountsAgreeWithTheWholePackfileCensus`.

**What this closes**: "17 capsules float in the packfile" is now "here is rigid body N's capsule, and
here is the constraint list" — the object graph connecting collision shapes to bodies to constraints
is readable end to end. **What it does not close**: correlating the ragdoll's own 17-bone skeleton
back onto the 73-bone *animation* skeleton (so a UE5 Physics Asset could say "this capsule is bone
`Bip01_L_UpperArm`" rather than "rigid body 3") needs either the two `hkaSkeletonMapper` objects this
character's packfile also carries (unread, still scoped below) or a name/hierarchy correlation between
the two `hkaSkeleton` objects, neither attempted here.

## Scoped, not yet attempted

Ordered by what would unblock the most next, not by ease.

### 1. `hkaSkeletonMapper` — re-prioritised up, now the real blocker for "which bone"

**This project's own read of `hkaRagdollInstance` changed the priority order here.** Originally
scoped as "lower priority... not needed to place static capsules on their bones" — that was wrong.
`m_boneToRigidBodyMap` maps the *ragdoll's own* 17-bone skeleton to rigid bodies, and
`hkaRagdollInstance::m_skeleton` is that same 17-bone skeleton, confirmed distinct from the 73-bone
*animation* skeleton this project already exposes. Without correlating the two, a decoded capsule can
only be labelled "rigid body 3," not "`Bip01_L_UpperArm`" — which is what a usable UE5 Physics Asset
needs. `hkaSkeletonMapper` (2 objects on this character) is the game's own answer to that
correlation and should be read before `hkpRigidBody`, not after.

### 2. `hkpRigidBody` — the dynamics half of each capsule

Substantially deeper than `hkpCapsuleShape`: its base, `hkpEntity`, carries a material
(`hkpMaterial`), a full motion state (`hkpMaxSizeMotion` — position, rotation, linear/angular
velocity, inertia tensor, centre of mass), and constraint-owning arrays. Many `hkpEntity` fields are
marked `+serialized(false)` or `+nosave` in the SDK header (listener lists, cached indices, a
constraint-master array) — **not written to the packfile at all**, which narrows what actually needs
byte-offset work considerably, but the motion state itself (mass, inertia, centre of mass — the part
a UE5 Physics Asset actually needs) is real, serialized data that hasn't been located yet.

### 3. `hkpConstraintInstance` + `hkpRagdollConstraintData` — the deepest of the remaining classes

A `hkpConstraintInstance` mostly holds housekeeping (priority, a name, a `hkpConstraintData*`
pointer) and points at the real joint data. `hkpRagdollConstraintData::Atoms` is a fixed sequence of
seven nested "atom" structs — `hkpSetLocalTransformsConstraintAtom`, `hkpSetupStabilizationAtom`,
`hkpRagdollMotorConstraintAtom`, `hkpAngFrictionConstraintAtom`, `hkpTwistLimitConstraintAtom`,
`hkpConeLimitConstraintAtom` (twice — cone and "planes"), `hkpBallSocketConstraintAtom` — each its own
class with its own fields (joint limit angles, per-body local transforms, motor parameters). This is
genuinely the largest remaining piece, comparable in scope to the lightmap descriptor chain that took
a full session on its own. `hkaRagdollInstance::m_constraints` already gives the object graph (which
constraint belongs to this character, in order) — the reachability problem items 1–2 still had is
solved; what's left is purely "decode each joint's field values."

## What this unblocks, and what it does not

`hkaRagdollInstance` + `hkpCapsuleShape` are already enough to place every character's collision
capsules at their correct local transforms relative to *a* rigid body — a real, useful skeleton of
shapes, even before constraints are decoded (UE5 can import bodies without constraints; it just won't
hold together as a ragdoll yet). What's still missing before that's a *labelled* UE5 Physics Asset is
item 1 (which animation bone each rigid body corresponds to) and item 2 (each body's own transform —
`hkpCapsuleShape` is in the body's *local* space, and nothing yet reads where that local space sits
in the world/bone frame). Constraints (item 3) are what turn "capsules placed on bones" into "a
ragdoll that behaves like one." None of the three has been started; this note is the map for whoever
does.
