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
is readable end to end. **What it does not close on its own**: correlating the ragdoll's own 17-bone
skeleton back onto the 73-bone *animation* skeleton — that gap is closed next.

## Decoded: `hkaSkeletonMapper` — `CONFIRMED_BYTES`, 22 Aug 2026

```
hkaSkeletonMapper : hkReferencedObject
+0   hkReferencedObject                              (vtable + refcount, zero on disk)
                                                       (m_mapping is padded to +16, not +8 — the
                                                        embedded hkaSkeletonMapperData needs 16-byte
                                                        alignment for its later hkQsTransform fields)
+16  hkRefPtr<const hkaSkeleton>  m_skeletonA
+20  hkRefPtr<const hkaSkeleton>  m_skeletonB
+24  hkArray<hkInt16>             m_partitionMap                        (empty on this character)
+36  hkArray<PartitionMappingRange> m_simpleMappingPartitionRanges      (empty)
+48  hkArray<PartitionMappingRange> m_chainMappingPartitionRanges       (empty)
+60  hkArray<SimpleMapping>       m_simpleMappings   (21 or 29 entries — see below)
+72  hkArray<ChainMapping>        m_chainMappings    (1 entry, not individually decoded)
+84  hkArray<hkInt16>             m_unmappedBones    (0 or 42 entries, count only)
```

Both of `AggressorBabyJane`'s two mappers resolve `SkeletonA`/`SkeletonB` to real, class-named,
bone-counted `hkaSkeleton` objects: one mapper is 73-bone `"Bip01"` → 17-bone
`"Ragdoll_Bip01 Pelvis01"`, the other is close to (not exactly) the inverse. Each `SimpleMapping`
entry is `{hkInt16 boneA, hkInt16 boneB, hkQsTransform aFromBTransform}` — a fixed 64-byte stride
(4 bytes of indices, 12 bytes padding, 48 bytes of transform, the transform itself not yet decoded).
**20 of the 21 entries in the sparser (73→17) direction have an exact reverse counterpart in the
richer (17→73) direction's 29** — e.g. one mapper's `(boneA: 65, boneB: 2)` against the other's
`(boneA: 2, boneB: 65)` — and every index on both sides falls inside its own skeleton's real bone
count. **The one exception is understood, not reader error**: bone 4 also maps to ragdoll bone 1 in
the sparser direction with no reverse entry, plausibly because ragdoll bone 1 is one of the richer
mapper's 42 separately-counted `m_unmappedBones` rather than a simple mapping — i.e. the sparser
direction still names a nearest bone where the richer direction considers it genuinely unmapped.
`HkaSkeletonMapperReader`, `HavokPhysicsTests.SkeletonMappersAreNearExactInversesOfEachOther`.

**What this closes**: a capsule can now be traced end to end to a named animation bone — rigid body
index → `HkaRagdollInstanceReader`'s `BoneToRigidBodyMap` → ragdoll bone index →
`HkaSkeletonMapperReader`'s `SimpleMappings` → animation bone index (73-bone `Bip01`). **What it does
not close**: `ChainMapping`s (1 per mapper, for bone ranges rather than single bones) and the
`SimpleMapping`/`ChainMapping` transforms themselves are counted but not individually decoded — not
needed for "which named bone," but would matter for anything that needs the actual retargeting math.

## Partially decoded: `hkpRigidBody` — shape pointer only, `CONFIRMED_BYTES`; the rest is open

`hkpRigidBody`'s inheritance chain (`hkpEntity` → `hkpWorldObject` → an embedded `hkpLinkedCollidable`
→ `hkpCollidable` → `hkpCdBody`, plus a separately-embedded `hkpMaxSizeMotion` for the dynamics side)
is materially deeper than every other class decoded so far — genuinely deep enough that guessing at
the rest risked publishing wrong offsets as fact, so this note stops at what's actually confirmed.

**Confirmed**: `m_collidable`'s shape pointer resolves to a real `hkpCapsuleShape` on **all 17 of
`AggressorBabyJane`'s rigid bodies, 0 disagreements** — `HkpRigidBodyReader.ReadShape`,
`HavokPhysicsTests.EveryRigidBodyPointsAtARealCapsuleShape`. Reachable because
`hkMultiThreadCheck` (debug-only) and `hkpLinkedCollidable`'s own field (`m_collisionEntries`) are
both entirely `+nosave`/`+serialized(false)` — they contribute zero bytes to the packfile, so the
shape pointer sits close to the object's start despite the deep class chain.

**Tried and inconclusive, not published as fact**: a first byte dump of one rigid body found
plausible-looking candidates — a `0.5`/`0.1` float pair that could be friction/restitution, and a
`(-0.009282, 0.005066, 0.999944, 0)` quadruple that normalises to almost exactly 1 (a valid unit
quaternion, or equally plausibly one row of `hkTransform`'s rotation matrix — the two are not
distinguishable by eyeballing one sample). A principled cross-reference was attempted: this rig's own
`hkaRagdollInstance` + `hkaSkeletonMapper` chain (above) says rigid body 0 corresponds to animation
skeleton bone 1 (`Bip01_Pelvis`), so that bone's own bind-pose local translation should show up
somewhere in the rigid body's bytes, in some scale/frame. It didn't help: `Bip01_Pelvis`'s local
translation is exactly `(0, 0, 0)` — an unlucky first pick, not diagnostic either way — and a rigid
body's own transform is in **world space**, not parent-relative, so even a non-zero bone translation
would need the whole parent chain composed (not one bone read in isolation) before it's comparable.
**Concrete next step for whoever picks this up**: repeat the cross-reference against a bone with a
non-zero *world-space* position (composing the chain from root), rather than reading one local
translation directly.

## Decoded: `hkpConstraintInstance` — `CONFIRMED_BYTES`, 22 Aug 2026 — the full constraint topology

```
hkpConstraintInstance : hkReferencedObject
+0   hkReferencedObject                (vtable + refcount, zero on disk)
+8   hkpConstraintOwner*  m_owner      (+nosave — occupies its slot, permanently null, no fixup)
+12  hkpConstraintData*   m_data
+16  hkpModifierConstraintAtom* m_constraintModifiers   (null on every constraint checked)
+20  hkpEntity*  m_entities[0]
+24  hkpEntity*  m_entities[1]
+28  hkUint8 m_priority, hkBool m_wantRuntime, hkUint8 m_destructionRemapInfo (+ padding)
+32  hkStringPtr m_name                (null on every constraint checked — unnamed)
+36  hkUlong m_userData
```

`Data`, `EntityA` and `EntityB` all resolve on **all 16 of this character's constraints, 0
disagreements** — `Data` to a real `hkpRagdollConstraintData`, both entities to real `hkpRigidBody`
objects (`HkpConstraintInstanceReader`,
`HavokPhysicsTests.EveryConstraintConnectsTwoRealRigidBodiesToRealConstraintData`). The resulting
graph is coherent, not just individually plausible: several constraints connect directly to rigid
body 0 (this character's pelvis), which is the shape a real hierarchy radiating from a root produces.

**A correction to an assumption this investigation had been carrying too far**: `m_owner` is
`+nosave` but the byte dump shows it still occupies its 4-byte slot at `+8` (permanently null, no
fixup entry) rather than being omitted from the layout the way this note previously assumed for
every `+nosave` field. The two readings are indistinguishable when the skipped field happens to sit
inside alignment padding anyway (as with `hkaAnimatedReferenceFrame`'s `m_frameType` in
`root-motion.md`, where the next field needed 16-byte alignment regardless) — this class, where the
following field has no such alignment requirement, is what made the difference visible.

**What this closes**: the full constraint graph — which two bodies each joint connects — is readable,
on top of the shape/bone/rigid-body correlation the earlier classes already closed. **What remains**:
`hkpRagdollConstraintData::Atoms` — the actual joint limits, motor parameters and per-body local
transforms — is a fixed sequence of seven nested "atom" structs
(`hkpSetLocalTransformsConstraintAtom`, `hkpSetupStabilizationAtom`, `hkpRagdollMotorConstraintAtom`,
`hkpAngFrictionConstraintAtom`, `hkpTwistLimitConstraintAtom`, `hkpConeLimitConstraintAtom` twice —
cone and "planes" — `hkpBallSocketConstraintAtom`), each its own class with its own fields.

**Checked, 22 Aug 2026, and genuinely out of reach — not merely unattempted.** None of the seven atom
classes have a header anywhere in this SDK: `Physics/Constraint/Atom/` contains only the abstract
`hkpConstraintAtom` base and a bridge helper, and a case-insensitive search of the whole `Source` tree
for any of the seven class names finds zero declarations — they exist only as compiled symbols in the
`.obj`/`.lib`/`.pdb` binaries. This is a different situation from every other class in this document,
not just a harder version of the same thing: for `hkpCapsuleShape`, `hkaRagdollInstance`,
`hkaSkeletonMapper`, `hkpRigidBody` and `hkpConstraintInstance`, a header gave the actual field
declarations and this project verified them against real bytes — checking a documented schema against
real files. For these seven, there is no schema to check *against*; recovering their field layout
would mean inferring Havok's own undisclosed, proprietary struct design purely by experimenting on the
bytes. That is black-box reverse engineering of the Havok product's design, not of BioShock's file
format, regardless of which file the encoded bytes happen to live in — the same category of thing
Havok's license (§4.2, `hk2012_2_0_r1/Havok Limited Use License Agreement...txt`) prohibits, considered
and declined for the same reason as the `sampleTranslation`/`evaluateSimple1-3` disassembly question
in `docs/HANDOFF.md` §6.0c. **Do not attempt this** — the topology (which shape belongs to which body,
which bodies a constraint connects, which bone a body maps to) is fully solved and `CONFIRMED_BYTES`;
the specific numeric joint limits inside each constraint are the one piece that stays out of reach,
for the same reason §6.0c does.

## Scoped, not yet attempted

### 1. The rest of `hkpRigidBody` — mass, inertia, velocities, friction/restitution, world transform

See its own section above for what's confirmed and what was tried. `hkpMotion`'s own header
(`hkpMotion.h`) is worth reading closely before the next attempt — it names the fields directly:
`m_motionState` (which starts with the `hkTransform` — 48-byte rotation matrix + 16-byte translation —
this rigid body's own world-space pose), `m_inertiaAndMassInv` (one `hkVector4`: inverse inertia
diagonal in `xyz`, inverse mass in `w` — a well-known Havok packing, worth checking for directly),
`m_linearVelocity`, `m_angularVelocity`. All plausible in the byte dump already taken; none
cross-validated yet.

`hkpRagdollConstraintData::Atoms` is not listed as item 2 here — see the constraint section above for
why it is closed, not merely unattempted.

## What this unblocks, and what it does not

`hkaRagdollInstance` + `hkpCapsuleShape` + `hkaSkeletonMapper` + `hkpConstraintInstance` together
already place every character's collision capsules against a *named animation bone*, know which body
belongs to which shape, and know the *full joint graph* connecting every body — everything a UE5
Physics Asset's skeleton-of-bodies-and-constraints structure needs at the topology level. Two things
stay open, for two different reasons: each body's own world-space transform/mass (`hkpRigidBody`'s
remaining fields — genuinely just unattempted, a header exists, a future session can pick this up
directly) and the constraints' own limit angles/motor parameters
(`hkpRagdollConstraintData::Atoms` — genuinely inaccessible without violating Havok's license, not a
scoping choice). A UE5 import built on what's decoded here would place every body correctly-shaped and
correctly-connected; it just couldn't enforce joint limits without either the missing data or values
supplied from elsewhere (e.g. reasonable defaults, or hand-authored per the target skeleton).
