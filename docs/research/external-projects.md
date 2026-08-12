# External projects and the cross-game Havok matrix

The purpose here is reusable **technique**, not copied formats. Another game's Havok layout is a
hint, never an assumption about BioShock.

## Consulted so far

| Project | What we took | Confidence |
|---|---|---|
| [gildor2/UEViewer](https://github.com/gildor2/UEViewer) | `GAME_Bioshock` FName serialisation: FCompactIndex index + int32 extra, suffix appended with no separator. Read directly from `UnPackage.cpp`. | `CONFIRMED_EXTERNAL`, and independently `CONFIRMED_BYTES` here. |
| UEViewer, same file | No BioShock-specific branch exists for `FObjectExport` / `FObjectImport` / `FPackageFileSummary`. | `CONFIRMED_EXTERNAL` |

That second finding is load-bearing. UEViewer handles BioShock's export table through its generic
UE2 path, but the Remastered export record is **not** stock UE2 — it carries an extra int32 after
the outer index, 64-bit object flags, an unconditional serial offset, and a trailing int32. That
divergence was resolved here from bytes, not from prior art, and it is plausibly related to
UEViewer's difficulties with Remastered content.

## Still to consult

Priority order, driven by what the pistol target actually needs.

| Project | Why it matters here |
|---|---|
| DSAnimStudio, HavokLib | Havok **spline compression** decoding. Now known to be on the critical path — BioShock uses `hkaSplineCompressedAnimation`. Highest priority. |
| Skyrim `blender-hkx`, PyNifly | Bone-order and track-to-bone index handling; the brief's warning about not binding by name. |
| Soulstruct / Soulstruct-Blender | `hkaAnimationBinding` handling and Blender-side armature construction. |
| Alien: Isolation tools | Closest available 2012.2.0-r1 container reference; the game is installed locally. |
| Sonic Lost World research | Second 2012.2.0-r1 data point. |
| NykoDesigns Remastered SDK/WIP, BSM_HEX | BioShock-specific `SkeletalMesh` and `HkMeshProxy` layout. |

## Havok research matrix

Populated only where we have direct evidence. Empty cells are honest gaps, not defaults.

| Game | Havok version | Animation format | Skeleton | Compression | Binding | Bone index handling | Tool |
|---|---|---|---|---|---|---|---|
| **BioShock 1 Remastered** | `hk_2012.2.0-r1` (`CONFIRMED_BYTES`) | packfile embedded in Unreal export | `hkaSkeleton` present in class table | `hkaSplineCompressedAnimation` (`CONFIRMED_BYTES`) | `hkaAnimationBinding` present | unknown | this project |
| Skyrim | 2010.2 | — | — | spline / delta | — | index-ordered | blender-hkx, PyNifly |
| Fallout 4 | 2014.x | — | — | — | — | — | — |
| Dark Souls / 2 / 3 | 2010–2014 | — | — | spline | — | — | DSAnimStudio, HavokLib |
| Bloodborne, Sekiro, Elden Ring | 2014+ | — | — | — | — | — | Soulstruct |
| Alien: Isolation | `hk_2012.2.0-r1` (`CORROBORATED`) | — | — | — | — | — | community tools |
| Sonic Lost World | `hk_2012.2.0-r1` (`CORROBORATED`) | — | — | — | — | — | — |

The two other 2012.2.0-r1 titles are the most valuable comparisons because the container and
reflection layout should match even where the game-specific root objects do not.
