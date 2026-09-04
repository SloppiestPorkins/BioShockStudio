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

`CONFIRMED_BYTES`. The hands animation packfile is partitioned into per-weapon Havok sections
(`pistol`, `shotgun`, `tommygun`, `wrench`, `crossbow`, `chemical…`, `grenadel…`, `scripted…`,
`default`), and third-person characters carry ragdoll/physics classes the hands package does not
(`hkaRagdollInstance`, `hkaSkeletonMapper`, `hkpRigidBody`…). Both are structural signals from
shipped bytes rather than naming. Full detail, including the third-person contrast table:
[animationpackage.md](animationpackage.md).

## Third-person and NPC-carried weapon meshes

`CONFIRMED_BYTES`. `WP_AI_Pistol` is a `StaticMesh` in `1-Medical.bsm` (361,898 bytes) — the
`WP_AI_` prefix marks the NPC-carried weapon, a different asset from the first-person viewmodel.
The full `WP_AI_*` census and resolver logic live in [context.md](context.md) §4.

## The first-person pistol mesh — CLOSED

`CONFIRMED_BYTES`. It is `WP_PistolMesh`, in `Build/Final/BakedScripts/pc/ShockGame.U` — not in any
map package, and not found by following references out of `UAPW_NEWPlayerHands`, which is why it
took a script-package search rather than an object-graph walk. Has its own skeleton and animations.
Full resolution: [context.md](context.md) §"Weapon viewmodels live in ShockGame.U".
