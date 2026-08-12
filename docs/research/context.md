# Asset context and relationships

**Implementation:** `src/BioShockStudio.Core/Assets/AssetContext.cs`, `AnimationMetadata.cs`
**Tests:** `tests/BioShockStudio.Tests/AssetContextTests.cs`

The question this document answers is not "how do I extract this animation" but "what does BioShock
need in order to reproduce it".

## The Package object is the game's own asset context (CONFIRMED)

BioShock groups related assets with `Package` export objects, and every export's outer chain leads
back to one. This is an explicit reference in the shipped data, not a naming convention.

`NEWPlayerHands` (0-Lighthouse) owns 285 objects:

| Class | Count | Examples |
|---|---|---|
| `SharedSkeletonAnimationMetadata` | 130 | one per animation |
| `AnimNotify_EffectEvent` | 130 | `ReloadPistolOne`, `EquipPistol` |
| `Texture` | 13 | `Hand_DIFF`, `Hand_NORM`, `Hand_SPEC` |
| `AnimNotify_UseAbility` | 9 | |
| `AnimNotify_InitiateDamage` | 5 | |
| `StaticMesh` | 3 | `CS_photo`, `CS_butt`, `Player_Wallet` |
| `SkeletalMesh` | 1 | `NEWPlayerHands` |
| `AnimationPackageWrapper` | 1 | `UAPW_NEWPlayerHands` |
| `AnimNotify_StartedInteractingWithGatherer` | 2 | |
| `AnimNotify_FinishedInteractingWithGatherer` | 2 | |

So the first-person context — mesh, skeleton, animations, materials, attachments and events — is
recoverable from one explicit relationship rather than assembled by guesswork.

The three static meshes line up with sockets on the hand skeleton: `CS_photo` with the `CSphoto`
socket, `CS_butt` with `butt`, and `Player_Wallet` with a wallet the player holds. Those are
attachments the animations expect to exist.

## Animation events (CONFIRMED)

`SharedSkeletonAnimationMetadata` is a per-animation event track, one object per animation.

```
+0   18 bytes  header shared with other BioShock export payloads
+18  13 bytes  UNKNOWN
+31  byte      event count
     per event: float time, FCompactIndex PackageIndex of an AnimNotify export
```

`FastReloadPistol` (1.80 s):

| Time | Event |
|---|---|
| 0.30 s | `ReloadPistolOne` |
| 1.06 s | `ReloadPistolTwo` |
| 1.53 s | `ReloadPistolThree` |
| 1.80 s | the same three, as untriggers |

`EquipPistol` (0.23 s) fires `EquipPistolSound` and `EquipClothes` at 0.00 s and `EquipPistol` at
0.23 s. Every event time falls inside its own animation, and the names match the game's audio
objects (`weapons_pistol_reload_one/two/three`). 74 of the 130 hands animations carry events.

Events export to Blender as pose markers on each Action.

## Little Sister ("Gatherer") — referenced, on the player side (CONFIRMED)

The hands package contains `AnimNotify_StartedInteractingWithGatherer` and
`AnimNotify_FinishedInteractingWithGatherer`, and the hand skeleton carries the sockets
`GatherSave`, `GathererAttach` and `PlayerGathererGun`.

"Gatherer" is BioShock's internal name for the Little Sister. So a companion relationship **is**
present in the asset data, expressed as animation notifies and sockets on the first-person hands
rather than as a direct object reference to a Little Sister asset.

`UNKNOWN`: whether any object reference points at a Little Sister *asset*. The notifies name an
interaction, not a mesh. Whether the Big Daddy side carries an equivalent reference has not yet been
checked.

## Weapon meshes (partly resolved)

`WP_*` package groups exist and are explicit: `WP_Pistol`, `WP_Shotgun`, `WP_TommyGun`,
`WP_Crossbow`, `WP_ChemicalThrower`, `WP_AI_RivetGun`.

In `0-Lighthouse` those groups contain only ammo and pickup meshes — `WP_Pistol` holds
`Ammo_Pickup_JHP` plus its three textures, a shader and an `HkMeshProxy`. `WP_AI_RivetGun` holds the
Big Daddy's weapon mesh.

`UNKNOWN`: where the first-person pistol viewmodel mesh lives. It is not in the `NEWPlayerHands`
group and not in `WP_Pistol` in this package. The hands skeleton's `Pistol` socket proves something
attaches at `R_Grip`; the mesh it attaches has not been located.

## Confidence model

Relationships carry `Confirmed`, `Likely` or `Heuristic` plus the evidence that produced them.
Only outer-chain ownership is currently emitted, and it is `Confirmed`.
