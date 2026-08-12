# First-person assets

The definition of done is the first-person pistol. These are the assets it resolves to.

## Located assets

`CONFIRMED_BYTES`, all in `0-Lighthouse.bsm`.

| Class | Object | Payload |
|---|---|---|
| `SkeletalMesh` | `NEWPlayerHands` | 777,635 |
| `AnimationPackageWrapper` | `UAPW_NEWPlayerHands` | 920,658 |
| `SkeletalMesh` | `HandInsects_Mesh` | 419,908 |
| `AnimationPackageWrapper` | `UAPW_HandInsectAnim` | 11,698 |

`NEWPlayerHands` is the first-person viewmodel arms. There is exactly one such mesh, so
first-person hands are a single shared asset rather than per-weapon meshes.

Beware: `NEWPlayerHands` also exists as a `Package` object in the same file. Resolve by class.

## Pistol animation metadata

`CONFIRMED_BYTES`. `SharedSkeletonAnimationMetadata` exports named
`USharedSkeletonAnimationMetadata_<AnimationName>`:

| Animation | Maps to the brief's requirement |
|---|---|
| `EquipPistol` | draw / equip |
| `UnequipPistol` | holster |
| `FireSinglePistol` | firing |
| `FastReloadPistol` | reload |
| `FidgetPistol` | idle |
| `EmptyFidgetPistol` | idle, empty magazine |
| `ZoomingInPistol` / `ZoomingOutPistol` | ADS transitions |
| `ZoomedInFidgetPistol` / `ZoomedinFireSinglePistol` | ADS idle / fire |
| `PlayerCamera_PistolFired` | camera / viewmodel recoil |

These payloads are small (100–142 bytes), so they are metadata records pointing at the real
animation data, not the animation data itself. `PlayerCamera_PistolFired` is direct evidence that
camera-space viewmodel motion is authored separately from hand motion, which matters for the UE5
reconstruction.

There are 15,998 `SharedSkeletonAnimationMetadata` exports game-wide.

## Weapon association is structural, not name-based

`CONFIRMED_BYTES`. The brief warns that naming alone is insufficient for classification. It does not
have to be: the hands animation packfile is partitioned into per-weapon Havok sections
(`pistol`, `shotgun`, `tommygun`, `wrench`, `crossbow`, `chemical…`, `grenadel…`, `scripted…`,
`default`). See [animationpackage.md](animationpackage.md).

That gives a first-class structural signal for `ViewModelDetector`:

- an `AnimationPackageWrapper` whose packfile carries weapon-named sections is a **first-person**
  hands package;
- the section tag names the weapon the contained animations belong to.

`CONFIRMED_BYTES`: third-person packages do lack this partitioning. `UAPW_AggressorBabyJane` ships
four sections — `__classnames__`, `__types__`, `default`, `__data__` — and nothing per weapon.

A second, independent discriminator falls out of the class tables. Third-person characters carry
ragdoll and physics classes that the first-person hands package does not:

| Class | Third-person character | First-person hands |
|---|---|---|
| `hkaRagdollInstance` | yes | no |
| `hkaSkeletonMapper` | yes | no |
| `hkpRigidBody`, `hkpRagdollConstraintData`, `hkpCapsuleShape` | yes | no |
| per-weapon sections | no | yes |

Both signals come from shipped bytes rather than naming, which is what `ViewModelDetector` should
classify on.

## Third-person weapon meshes

`CONFIRMED_BYTES`. `WP_AI_Pistol` is a `StaticMesh` in `1-Medical.bsm` (361,898 bytes). The `WP_AI_`
prefix and `StaticMesh` class together indicate the NPC-carried weapon, which is a **different
asset** from whatever the first-person pistol uses. This supports the brief's instruction not to
assume first- and third-person assets share anything.

`UNKNOWN`: the first-person pistol mesh itself has not been located. It is not a `SkeletalMesh`
named `Pistol`. Next step is to follow object references out of `UAPW_NEWPlayerHands` and the
pistol section rather than to keep searching by name.
