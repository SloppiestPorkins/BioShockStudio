# BioShock 1 Remastered package format (`.bsm`)

**Source:** shipped game files, `ContentBaked/pc/Maps/*.bsm`
**Implementation:** `src/BioShockStudio.Core/Packages/`
**Tests:** `tests/BioShockStudio.Tests/PackageParsingTests.cs`

BioShock is Unreal Engine 2.5. `.bsm` files are Unreal packages with a 2K-modified layout.

## Whole-file validation

`CONFIRMED_BYTES`. The import table ends exactly on `ExportOffset`, and the export table ends
exactly on the file length, for **all 21** non-localised shipped packages (20 KB to 230 MB).
Export payloads chain contiguously from offset 64 with no gaps. A layout error anywhere in
the record would break these chains immediately, so this is a strong whole-file proof rather than
a single lucky sample.

```
21/21 packages parsed byte-exact; 812,435 exports indexed.
```

## Header

`CONFIRMED_BYTES`.

| Offset | Type | Field | Value in Remastered |
|---|---|---|---|
| 0 | uint32 | Magic | `0x9E2A83C1` |
| 4 | uint16 | FileVersion | `142` |
| 6 | uint16 | LicenseeVersion | `56` |
| 8 | uint32 | PackageFlags | e.g. `0x00340001` |
| 12 | int32 | NameCount | |
| 16 | int32 | NameOffset | |
| 20 | int32 | ExportCount | |
| 24 | int32 | ExportOffset | |
| 28 | int32 | ImportCount | |
| 32 | int32 | ImportOffset | |
| 36 | Guid | PackageGuid | |
| 52 | int32 | GenerationCount | |
| 56 | … | Generations | `{ int32 ExportCount, int32 NameCount }` each |

Version `142` / licensee `56` identifies Remastered. The reader rejects anything else rather than
guessing, because this project deliberately targets one game.

## FCompactIndex

`CONFIRMED_BYTES`. Stock Unreal variable-length signed integer.

- Byte 0: bit 7 = sign, bit 6 = continue, bits 0–5 = value.
- Continuation bytes: bit 7 = continue, bits 0–6 = value, shifted 6, then 7 per byte.

## Name table

`CONFIRMED_BYTES`. Per entry:

```
FCompactIndex  charCount     // includes the null terminator
UTF-16LE       text[charCount]
uint64         flags
```

Two departures from stock UE2: names are UTF-16, and the flags field is 64-bit rather than 32-bit.
The table has no length field, so ending precisely on `ImportOffset` is the proof of correctness.

## FName references

`CONFIRMED_BYTES`, and `CONFIRMED_EXTERNAL` via UEViewer's `GAME_Bioshock` branch.

```
FCompactIndex  nameIndex
int32          extraIndex
```

`extraIndex == 0` means the bare name. Otherwise the suffix `extraIndex - 1` is appended **with no
separator** — `Polys` + `12` becomes `Polys11`, not `Polys_11`.

## Import table

`CONFIRMED_BYTES`. Per entry:

```
FName   ClassPackage
FName   ClassName
int32   OuterIndex        // PackageIndex
FName   ObjectName
```

## Export table

`CONFIRMED_BYTES` except where noted. Per entry:

```
FCompactIndex  ClassIndex          // PackageIndex; 0 means the export is itself a UClass
FCompactIndex  SuperIndex
int32          OuterIndex
int32          Unknown32           // HYPOTHESIS: archetype/template index. Zero in every sample inspected.
FName          ObjectName
uint64         ObjectFlags         // widened from UE2's 32-bit flags
FCompactIndex  SerialSize
FCompactIndex  SerialOffset        // present even when SerialSize == 0, unlike stock UE2
int32          TrailingUnknown32   // UNKNOWN. Observed values: 0 and 1.
```

The two unknown int32s are **not** guessed at in code; they are surfaced under neutral names so a
later sample can settle them. See [open-questions.md](open-questions.md).

### PackageIndex convention

`CONFIRMED_BYTES`. Negative → import table at `-value - 1`. Positive → export table at `value - 1`.
Zero → null. A null `ClassIndex` means the export is a `UClass`.

## Gotcha: object names are not unique

`CONFIRMED_BYTES`. A package can hold a `Package` object and a `SkeletalMesh` that share a name —
`NEWPlayerHands` exists as both. Any lookup by name alone is ambiguous; resolve by class as well.

## Class census across all 21 packages

`CONFIRMED_BYTES`. Classes relevant to this project:

| Count | Class |
|---|---|
| 15,998 | `SharedSkeletonAnimationMetadata` |
| 8,961 | `HkMeshProxy` |
| 8,668 | `StaticMesh` |
| 962 | `SkeletalMesh` |
| 870 | `AnimationPackageWrapper` |

`HkMeshProxy` is a 2K class and a likely bridge between mesh and Havok data — an open question.
