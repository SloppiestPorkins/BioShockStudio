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

## Scoped, not yet attempted

Ordered by what would unblock the most next, not by ease.

### 1. `hkaRagdollInstance` — small, high-value, recommended next

```
+?  hkArray<hkpRigidBody*>       m_rigidBodies
+?  hkArray<hkpConstraintInstance*>  m_constraints
+?  hkArray<int>                 m_boneToRigidBodyMap
+?  hkRefPtr<const hkaSkeleton>  m_skeleton
```

Four fields, all arrays or a single pointer — the same shapes (`hkArray`, `hkRefPtr`) this project
already reads correctly for `hkaAnimationBinding` and `m_extractedMotion`. **This is the highest-value
target of the six remaining classes**: `m_boneToRigidBodyMap` directly answers which of the 73 bones
get a physics body, without inference from bone names or positions, and the two arrays are the object
graph's own index into every rigid body and constraint this character owns — reading this one object
would turn "17 capsules float in the packfile" into "here is bone N's capsule."

### 2. `hkpRigidBody` — the dynamics half of each capsule

Substantially deeper than `hkpCapsuleShape`: its base, `hkpEntity`, carries a material
(`hkpMaterial`), a full motion state (`hkpMaxSizeMotion` — position, rotation, linear/angular
velocity, inertia tensor, centre of mass), and constraint-owning arrays. Many `hkpEntity` fields are
marked `+serialized(false)` or `+nosave` in the SDK header (listener lists, cached indices, a
constraint-master array) — **not written to the packfile at all**, which narrows what actually needs
byte-offset work considerably, but the motion state itself (mass, inertia, centre of mass — the part
a UE5 Physics Asset actually needs) is real, serialized data that hasn't been located yet.

### 3. `hkpConstraintInstance` + `hkpRagdollConstraintData` — the deepest of the six

A `hkpConstraintInstance` mostly holds housekeeping (priority, a name, a `hkpConstraintData*`
pointer) and points at the real joint data. `hkpRagdollConstraintData::Atoms` is a fixed sequence of
seven nested "atom" structs — `hkpSetLocalTransformsConstraintAtom`, `hkpSetupStabilizationAtom`,
`hkpRagdollMotorConstraintAtom`, `hkpAngFrictionConstraintAtom`, `hkpTwistLimitConstraintAtom`,
`hkpConeLimitConstraintAtom` (twice — cone and "planes"), `hkpBallSocketConstraintAtom` — each its own
class with its own fields (joint limit angles, per-body local transforms, motor parameters). This is
genuinely the largest remaining piece, comparable in scope to the lightmap descriptor chain that took
a full session on its own. Recommend attempting only after `hkaRagdollInstance` and `hkpRigidBody` are
both read, since by then the object graph (which constraint belongs to which pair of bodies) is
already known and this becomes "decode one joint's field values" rather than "decode one joint's
field values and also work out which bodies it connects."

### 4. `hkaSkeletonMapper` — lower priority

Maps the 17-bone ragdoll skeleton onto the 73-bone animation skeleton. Needed for a complete runtime
ragdoll blend, not needed to place static capsules on their bones — deprioritised until 1–3 above are
done and something actually consumes the mapping.

## What this unblocks, and what it does not

Reading `hkaRagdollInstance` and `hkpRigidBody` would be enough to place every character's collision
capsules on their correct bones — a real, useful UE5 Physics Asset skeleton, even before constraints
are decoded (UE5 can import bodies without constraints; it just won't hold together as a ragdoll yet).
Constraints (item 3) are what turn "capsules placed on bones" into "a ragdoll that behaves like one."
Neither has been started; this note is the map for whoever does.
