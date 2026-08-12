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

## Attachments are of three different kinds (CONFIRMED)

Sockets do not all point at the same sort of thing, which is why a resolver written for the
first-person weapons finds nothing on a Big Daddy.

**1. A skeletal weapon in its own `WP_` group.** The first-person case. The attachment has its own
skeleton and animations, rooted at the bone the socket names. Resolved and drawn.

**2. A static mesh in the host's own group.** The Big Daddy's drill:

```
NewProtectorBouncer sockets   Drill -> SocketDrillROTATION
                              DrillCage -> SocketDrillBase
                              backpack -> SocketBackpack
NewProtectorBouncer group     ConeDrill, ConeDrillCage, ConeDrillBackpack   (all StaticMesh)
```

Three sockets, three static meshes in the same group, names mapping one to one. The same shape
appears on `AggressorBabyJane` (`Wig` -> `Wig_BJ_ShortHair`) and on the hands (`CSphoto` ->
`CS_photo`, plus `Player_Wallet`).

`UNKNOWN`: nothing here can be drawn or exported yet, because **no `StaticMesh` geometry reader
exists**. `SkeletalMeshReader.ReadGeometry` returns nothing for `ConeDrill` as it does for
`WP_WrenchMesh`. The relationship is established; the vertices are not.

**3. A skeletal weapon in a `WP_` group named differently from the socket.** `ProtectorRosie`
declares `RivetGunSocket -> Dummy_GunParent` and carries no static meshes; her weapon is the separate
group `WP_AI_RivetGun`. The current name matcher does not strip the `Socket` suffix, so it misses
this.

Turrets and bots are the same third kind: `SecurityBot` declares `MGweapon -> MGattach` and
`Weapon -> sec_bot` with nothing in its own group.

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

## Weapon viewmodels live in ShockGame.U (CONFIRMED)

The first-person weapon meshes are **not** in the map packages. They are in
`Build/Final/BakedScripts/pc/ShockGame.U`, a 92 MB Unreal package in the same format as the maps —
it parses byte-exact with the same reader (11,647 exports).

The map `WP_*` groups contain only ammo and pickup meshes. Taking the union of `WP_Pistol` across
all 21 maps yields `Ammo_Pickup_JHP` and its textures, and nothing else. The catalog
(`Maps/Catalog.bdc`, which indexes the bulk texture chunks) references `WP_Pistol_Spec` and
`WP_Pistol_Attachments_Norm` under the `WP_Pistol` group, which is what showed the viewmodel had to
exist somewhere else.

`ShockGame.U` holds nine weapon groups:

| Group | Mesh | Animation package |
|---|---|---|
| `WP_Pistol` | `WP_PistolMesh` | `UAPW_WP_Pistol` |
| `WP_Shotgun` | `WP_ShotgunMesh` | `UAPW_WP_Shotgun` |
| `WP_TommyGun` | `TommyGunMESH` | — |
| `WP_Crossbow` | `WP_CrossbowMesh` | — |
| `WP_ChemicalThrower` | `WP_ChemicalThrowerMesh` | `UAPW_WP_ChemicalThrower` |
| `WP_GrenadeLauncher` | `WP_GrenadeLauncherMesh` | — |
| `WP_Wrench` | `WP_WrenchMesh` | — |
| `WP_PlasmidEquip` | `PlasmidEquipMESH` | `UAPW_WP_PlasmidEquip` |
| `WP_FragGrenade` | — | — |

Plus per-weapon upgrade meshes (`PI_UpgradeA`, `SG_UpgradeA`, `TG_upgradeA/B`, `XB_UpgradeA`,
`CT_UpgradeA/B`) and the viewmodel textures (`Pistol_DIFF` 5.6 MB, `Pistol_NORM` 2.8 MB).

## The weapon is not a static prop (CONFIRMED)

`UAPW_WP_Pistol` carries a skeleton and animations of its own:

```
R_grip
└── pistol_body
    ├── hammer
    ├── trigger
    └── barrel
        ├── over
        └── DrumParent
            └── drum
```

`WP_PistolMesh` is 3,736 vertices skinned to those 8 bones.

Two facts make the attachment relationship explicit rather than inferred:

1. **The weapon's root bone is the hands' socket.** The hands mesh declares a socket named `Pistol`
   bound to bone `R_Grip`; the pistol's own skeleton is rooted at `R_grip`. (Casing differs, as it
   does elsewhere in this format.)
2. **The animations are frame-identical.** `FastReload` is 55 frames / 1.80 s and `FireSingle` is
   8 frames / 0.23 s — exactly matching the hands' `FastReloadPistol` and `FireSinglePistol`.

So a first-person animation genuinely is a two-rig performance: the hands animate the arms, the
weapon animates its own moving parts, and the two are played together at the socket. Merging them
into one skeleton would destroy that structure, so the exporter keeps them separate and parents the
weapon rig to the socket bone.

Decoding `FastReload` shows the mechanism: the `barrel` bone hinges roughly 105° open at the
midpoint and returns to the closed pose — BioShock's pistol is a top-break revolver, not a
swing-cylinder one. The `drum` bone does not rotate.

`bioshock-tool export-firstperson Pistol <out>` assembles the whole thing.

## Textures (CONFIRMED)

`Texture` exports are an Unreal property list followed by a mip chain.

Formats, confirmed by measured bytes-per-pixel across 0-Lighthouse:

| `Format` | Meaning | bpp |
|---|---|---|
| 3 | DXT1 | 0.5 |
| 5 | RGBA8 (stored BGRA) | 4.0 |
| 7 | DXT3 | 1.0 |
| 8 | DXT5 | 1.0 |

Mips are located by their trailer rather than by walking the array header, which carries a field
whose meaning is still `UNKNOWN`:

```
int32 USize, int32 VSize, byte UBits, byte VBits     with USize == 1 << UBits
```

The data for a mip is the format's byte count immediately preceding its trailer. Coverage is 1054 of
1062 textures in 0-Lighthouse and 1937 of 1951 in 1-Medical; the rest return nothing rather than
garbage.

`SourcePath` preserves the authoring path — the hands' diffuse came from
`..\..\..\Art\Source\Weapons\1stPersonHands...`.
