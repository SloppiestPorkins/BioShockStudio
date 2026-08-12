# AnimationPackageWrapper / AnimationPackageRoot

These were flagged in the brief as the highest-priority unknowns, and as the point where UEViewer
historically fails on Remastered content. Both now have direct byte evidence.

## AnimationPackageWrapper

`CONFIRMED_BYTES`. An Unreal export class. 870 instances across the 21 shipped packages. Its
serialised payload is an Unreal wrapper with a **Havok packfile embedded inside it**.

For `UAPW_NEWPlayerHands` (`0-Lighthouse.bsm`):

```
export payload      920,658 bytes
havok packfile      920,624 bytes, starting at payload offset 34
```

So the Unreal wrapper is a 34-byte prefix plus the packfile. `UNKNOWN`: the meaning of those 34
bytes. They are preserved, not skipped blindly — detection is by magic search, not a hardcoded 34.

Naming convention `UAPW_<AssetName>` pairs the wrapper with its mesh: `UAPW_NEWPlayerHands` ↔
SkeletalMesh `NEWPlayerHands`. `LIKELY` as a resolution heuristic, but naming alone is explicitly
insufficient per the brief, so the real link must come from object references. Not yet extracted.

## AnimationPackageRoot

`CONFIRMED_BYTES`. This is the **Havok root object's class name**, resolved through the packfile
header's `ContentsClassNameSectionIndex` / `ContentsClassNameSectionOffset`:

```
root class: AnimationPackageRoot
```

It occupies the slot where stock Havok content carries `hkRootLevelContainer`. A generic Havok
reader looks up the root class, finds a name it has no reflection data for, and stops — which
matches the reported UEViewer failure mode:

```
Unknown Havok class: AnimationPackageRoot
```

The important structural consequence: **the container is custom, but the contents are not.** The
class-name table alongside it lists stock Havok classes (`hkaSkeleton`, `hkaAnimationBinding`,
`hkaSplineCompressedAnimation`). So the work is to decode 2K's root object and then hand off to
standard Havok 2012.2.0-r1 structures, rather than to reverse-engineer a bespoke animation format.

`UNKNOWN`: the layout of `AnimationPackageRoot` itself. It is the next target.

## Per-weapon sectioning

`CONFIRMED_BYTES`. This is the significant structural discovery. `UAPW_NEWPlayerHands` does not
carry one flat animation list. Its packfile has 12 sections, and the middle ten are **named per
weapon**:

| Section | Data bytes | Local fixups |
|---|---|---|
| `__classnames__` | 176 | 0 |
| `__types__` | 0 | 0 |
| `chemical200249441` | 60,960 | 4,160 |
| `crossbow` | 78,400 | 5,408 |
| `default` | 415,168 | 23,712 |
| `grenadel1663367201` | 75,232 | 4,992 |
| `pistol` | 46,112 | 4,160 |
| `scripted2306259077` | 19,776 | 416 |
| `shotgun` | 44,848 | 3,328 |
| `tommygun` | 52,656 | 4,160 |
| `wrench` | 53,104 | 3,744 |
| `__data__` | 10,608 | 2,496 |

The first-person hand animations for a given weapon are grouped into that weapon's section. This
gives the eventual `AnimationBindingResolver` and `ViewModelDetector` a structural signal that is
not name-based: **the section tag is the weapon association**, recorded in the shipped bytes.

For the pistol target case, `pistol` is 46,112 bytes of data with 4,160 bytes of local fixups.

`UNKNOWN`: whether the hand skeleton lives in `__data__` and is shared across weapon sections, or
whether each section carries its own. The `__data__` section is small (10,608 bytes) relative to
the weapon sections, which is `LIKELY` consistent with it holding the root object and shared
skeleton while the weapon sections hold the animations.
