# External projects and the cross-game Havok matrix

The purpose here is reusable **technique**, not copied formats. Another game's Havok layout is a
hint, never an assumption about BioShock.

## Consulted so far

| Project | What we took | Confidence |
|---|---|---|
| [gildor2/UEViewer](https://github.com/gildor2/UEViewer) | `GAME_Bioshock` FName serialisation: FCompactIndex index + int32 extra, suffix appended with no separator. Read directly from `UnPackage.cpp`. | `CONFIRMED_EXTERNAL`, and independently `CONFIRMED_BYTES` here. |
| UEViewer, same file | No BioShock-specific branch exists for `FObjectExport` / `FObjectImport` / `FPackageFileSummary`. | `CONFIRMED_EXTERNAL` |
| **Havok 2012.2.0-r1 SDK** (`hk2012_2_0_r1/`) | `hkaSplineCompressedAnimation::recompose` — a channel component that is neither static nor spline takes **identity**, not the bone's reference pose. Also confirms `ScalarQuantization` is only BITS8/BITS16, the per-quantization quaternion sizes `{4,5,6,3,2,16}` and alignments `{4,1,2,1,2,4}`, `unpackQuantizationTypes`' bit layout, and `getBlockAndTime`'s `frame / (maxFramesPerBlock - 1)` block stride. | `CONFIRMED_EXTERNAL` |

| **Nyko's `Bioshock1REMSDK-WIP--main`** | `bioshock1-bsm.md` §C.4 `UStaticMesh`: the **section table** — `CI NumSections`, then 14 bytes per section, before the vertex block — and that a section's ordinal indexes the object's `Materials` array. Verified against Remastered bytes here. Also that its `Materials` array is an ordinary tagged property, and that struct elements need recursive tagged-property serialisation with an unknown-property skip path. | `CONFIRMED_EXTERNAL`, and independently `CONFIRMED_BYTES` here |

**The Havok SDK is the highest-value thing on this list.** The identity-fallback line settled a
blocker that three sessions of internal measurement could not, because the fault was in an
assumption that had already been labelled `CONFIRMED_BYTES` on circular evidence — nothing internal
was going to challenge it. Note the build shipped here is "NO SOURCE PC DOWNLOAD": headers and
`.inl` only, no `.cpp`, so the inline and reflection detail is available and the sampling functions
are not. See `docs/research/havok-compression.md` and `FIRST_PERSON_ANIMATION.md`.

Nyko's SDK is the second most valuable, and the two projects answer different questions: it is an
in-engine SDK, so it knows the *engine's* structures — sections, material binding, the shader
factories, lightmaps, BSP — where this project knows the shipped *bytes* in more depth. Its
`docs/reverse-engineering/` also holds `BioShock_Materials_And_Shaders.md` (the full material class
tree and the `EMaterialType` ordinals), `BioShock_Texture_Lightmap_Format.md` and
`BioShock_Bulk_Files_And_Catalog.md`, none of which have been read against our own notes yet.

**Beware of one divergence.** Its `UStaticMesh` vertex is 24 bytes with packed normals, cross-
validated against UEViewer; Remastered's is 48 with full float basis vectors. Both are right for
their own target. A finding ported from UEViewer or the original game may need the record widening.

Also present and not yet mined: `UModel-master` (UEViewer source) and `Unreal-Library-master`
(UELib, C#).

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
