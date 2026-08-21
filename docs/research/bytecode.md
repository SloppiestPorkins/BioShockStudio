# UnrealScript bytecode / game logic

**Status, 19 Aug 2026: a working decompiler exists and runs against the real, shipped game.**
This started as a reference survey (Track B step 1) and went further: `Unreal-Library-master`
(UELib) — third-party, gitignored at the repo root alongside the other reference projects — builds
against this repo's installed SDK with a small workaround, and its `.Decompile()` produces real,
mostly-correct UnrealScript source directly from BioShock's shipped `.U` packages. This is
`CONFIRMED_BYTES` in the strongest sense available for this kind of claim: not "the reference says
so," but "ran it against the real game and read the output."

**What this is not**: an independent, from-scratch decoder built and verified byte-by-byte the way
this project's other CONFIRMED_BYTES findings are (the BSP zone record, the lightmap descriptors).
This is a third-party tool's output, read and spot-checked, not re-derived. Treat specific claims
below accordingly — the *existence and general correctness* of the decompiled output is
well-evidenced (§2); *exactly why* it works, byte-for-byte, has not been independently re-derived.

## 1. The reference: `Unreal-Library-master` (UELib), and it is unusually direct

UELib is a C# UnrealScript bytecode decompiler with **explicit, first-class BioShock support**, not
a generic UE2 tool that happens to also parse BioShock files:

- `src/UnrealBuild.cs:58` names the engine outright: *"Heavily modified Unreal Engine 2.5 for
  Vengeance: Tribes; also used by Swat4 and BioShock."*
- `src/ByteCodeDecompiler.cs` has a `#if BIOSHOCK` block keyed on
  `UnrealPackage.GameBuild.BuildName.BioShock` specifically, setting BioShock's own VM memory-layout
  constants (§3).
- `src/Core/Classes/UStruct.cs` has `#if VENGEANCE` blocks for Vengeance-specific fields.
- There is a `src/Branch/UE2/VG/` folder (VG = Vengeance) with one file,
  `Tokens/LogFunctionToken.cs` — a single native-function-logging token override. No
  `EngineBranch.VG.cs` exists, so Vengeance otherwise inherits `DefaultEngineBranch`'s token map
  directly rather than replacing it wholesale.

This project's own `docs/research/reference-comparison.md` §6 tracks four reference projects and
records which paid off for which subsystem. UELib had not paid off for anything before this; it now
has, more directly than any other reference this project has used.

## 2. Running it against the real game — `CONFIRMED_BYTES`

**The build problem and the fix.** UELib's own `.csproj` multi-targets
`netstandard2.0;netstandard2.1;net10.0` (plus `net48` for a Windows-Forms build), and this repo's
installed SDK (8.0.423) doesn't support `net10.0` — the project fails to even restore. Fix: compile
UELib's `.cs` sources directly into a throwaway `net8.0` class library rather than using its own
project file. `tools/uelib-bridge/` in this repo does exactly that (see its `README.md`) and wraps
loading a package plus calling `.Decompile()` on every `UClass` into a small driver.

**Build constants needed**: `DECOMPILE;BINARYMETADATA;UE1;UE2;UE3;UE4;VENGEANCE;SWAT4;BIOSHOCK;UT`.
The last one is not obviously required — BioShock is not a UT-derived game — but three enum members
BioShock's own code paths reference (`PackageFlag.Official`, `PropertyFlagsLO.Cache`/`Automated`,
`ClassFlags.CacheExempt`) are gated `#if UT` in UELib's flag definitions, so it has to be defined
for the build to compile at all. This says nothing about BioShock actually being UT-derived — it's
a quirk of how UELib's conditional compilation is organized, not a genealogy claim.

**Result, run against the actual installed game's `Build/Final/BakedScripts/pc/*.U`:**

| package | classes | decompiled | failed |
|---|---|---|---|
| `Core.U` | 10 | 10 | 0 |
| `Engine.U` | — | — | **crashes during package init**, see below |
| `ShockGame.U` | 654 | 654 | 0 |
| `ShockAI.U` | 540 | 540 | 0 |
| `Scripting.U` | 99 | 99 | 0 |
| `VengeanceShared.U` | 80 | 80 | 0 |
| `Tyrion.U` | 27 | 27 | 0 |
| `FMODAudio.U` | 1 | 1 | 0 |
| `IGEffectsSystem.U` | 8 | 8 | 0 |
| `IGModEffectsSubsystem.U` | 3 | 3 | 0 |
| `IGSoundEffectsSubsystem.U` | 14 | 14 | 0 |
| `IGVisualEffectsSubsystem.U` | 9 | 9 | 0 |
| **total** | **1,445** | **1,445** | **0** |

**`Engine.U` fails outright** during `UnrealPackage.InitializePackage` →`DeserializeObjects`, before
any class-level decompilation is attempted: `Assertion failed. Unexpected value '1191182336' for a
boolean` in `UClass.Dependency.Deserialize` — a version-gated field UELib reads incorrectly for
BioShock's copy of that one specific package. Not investigated further: `Engine.U` is mostly stock
engine base classes, not BioShock's own game logic, so this is a real but low-priority gap.

**Independent cross-validation, not just "it ran without crashing"**: `Pistol.uc`'s decompiled
`defaultproperties` block names `FastReloadPistol`, `FireSinglePistol`, `EmptyFidgetPistol`,
`ZoomingInPistol`, `ZoomedInFidgetPistol` and `WeaponModel=SkeletalMesh'ShockGame.WP_Pistol.
WP_PistolMesh'` — **exactly** the animation and mesh names this project already decoded completely
independently, from raw Havok/mesh bytes, with no connection to this decompiler. Two unrelated
decode paths (byte-level animation package reading vs. bytecode-level class-default decompilation)
agreeing exactly on names neither derived from the other is strong, if informal, corroboration that
both are reading the real game correctly.

## 3. What's imperfect, and what it means

- **Native function calls decompile as `__NFUN_<id>__(...)` placeholders.** The native ID-to-name
  table is per-game and isn't part of UELib generically.
  `Bioshock1REMSDK-WIP--main/docs/reverse-engineering/coop-natives-map.md` already resolves several
  dozen common ones by call-site context — operators (`__NFUN_112__` = `$` string concat,
  `__NFUN_119__` = `!=` on an Object, `__NFUN_130__` = `&&`, `__NFUN_150__` = `>` on int, etc.),
  `GotoState`, `FRand()`, vector math (`VSize`, `Normal`) — but it is a partial map built for one
  purpose (co-op modding), not an exhaustive table.
- **A handful of array properties fail to parse in class defaults** — `Emitters`, `Skins`,
  `EventResponse` all threw "Couldn't acquire array type" / "PropertyTag value size error" on
  specific classes. This is a property-tag array-type-inference gap in UELib, not a bytecode issue,
  and it's the same `Emitters` property this project's own `LevelCoverage.cs` already treats as a
  known, deliberately-unparsed field (`EffectPending`) — consistent, not contradictory.
- **A small number of individual statements produce inline `/* Statement decompilation error */`
  comments** (e.g. one spot in `Pistol.PostBeginPlay`), isolated to that one statement — the
  surrounding function otherwise decompiles correctly, and the file is still usable as a whole.
- **Control-flow reconstruction artifacts**: stray `goto J0x50`, bare `@NULL`/`Item`/`stop;` lines
  after a `return` — cosmetic decompiler noise from imperfect basic-block reconstruction, not
  evidence of a bytecode misread.

None of these are blockers for *reading* the decompiled output as documentation of game logic; they
would matter more for anyone trying to use this as a byte-exact specification to write an
independent decoder against.

## 4. Bytecode length framing — from reading UELib's source, not yet independently re-derived

`Unreal-Library-master/src/Core/Classes/UStruct.cs`, in `UStruct.Serialize()`, after whatever header
fields a given build/version serializes (mostly false for BioShock's low version):

```
serializeByteCode:
    ByteScriptSize = ReadInt32()
    if (Version >= AddedDataScriptSizeToUStruct)   // = 639 — far above BioShock's file version 142
        DataScriptSize = ReadInt32()
    else
        DataScriptSize = ByteScriptSize
    // DataScriptSize bytes of bytecode follow here, then the property defaults
```

For BioShock (version 142), `DataScriptSize` isn't separately serialized — it equals
`ByteScriptSize`, a single `int32` immediately preceding the bytecode blob. This directly explains
`ClassDefaults.cs`'s own doc comment (*"a `Class` payload begins with script bytecode of unknown
length"*) and its brute-force byte-by-byte search for where the property list resumes: the length
is not unknown if this framing holds, it's one `int32` at a computable offset. **Not yet checked
against this project's own byte reader independently** — UELib's own successful run (§2) is strong
indirect evidence this framing is right (it has to get this correct to find the property defaults
that follow, which is exactly what its `defaultproperties` output requires), but no one has read the
`int32` at the hypothesized offset in this project's own reader and confirmed it lines up with
`ClassDefaults.cs`'s existing search result on a real export.

## 5. VM constants — `CONFIRMED_EXTERNAL`

From `ByteCodeDecompiler.cs`'s `SetupMemorySizes()`, gated `#if BIOSHOCK`:

| constant | BioShock | stock UE2 (low version) |
|---|---|---|
| `_NameMemorySize` (in-memory `FName` operand size) | **8 bytes**, unconditionally | 4 bytes, until `NumberAddedToName` version |
| `_ObjectMemorySize` (in-memory `UObject*` operand size) | 4 bytes (BioShock's version 142 is far below the 587 threshold for 8-byte pointers) | 4 bytes |

The `_NameMemorySize` special-case — BioShock gets 8-byte name operands *without* meeting the
generic version gate stock UE2 games use — matches this project's own already-established finding
in an unrelated subsystem (`docs/research/skeletalmesh.md`'s `FPoly` discussion,
`reference-comparison.md` §7a: "the linker's `FName` operator widening"). A second, independent
recurrence of the same underlying engine change.

## 6. The opcode table — `CONFIRMED_EXTERNAL`

`Unreal-Library-master/src/UnrealTokens.cs` declares `ExprToken` as a plain sequential C# enum — its
numeric values are **not** the on-disk byte values. The real byte-to-token mapping is version-gated,
in `DefaultEngineBranch.cs`'s `BuildTokenMap(UnrealPackage linker)`. Since no `EngineBranch.VG.cs`
exists, Vengeance/BioShock uses this table as-is (bar the one `LogFunctionToken` addition) — and
§2's successful decompilation across 1,445 classes is strong indirect evidence this table is correct
for BioShock, since UELib has to walk every opcode correctly to produce readable output at all.

## 7. What's next

The practical outcome of this session's work: **BioShock's own game logic is now readable**, via
`tools/uelib-bridge/`, for every script package except `Engine.U`. That may already be enough to
answer most "what does this class/function actually do" questions this project runs into elsewhere
(e.g. Level actor classification, `docs/HANDOFF.md` open questions about specific gameplay behavior)
without needing an independent decoder at all.

Remaining, in descending value:

1. **Use the decompiled output as documentation** when a specific class's behavior is in question
   elsewhere in this project, the same way `Bioshock1REMSDK-WIP--main`'s other docs already get
   read as reference material. Regenerate via `tools/uelib-bridge/` per its README; don't commit
   the output (game-derived, same reason no extracted textures/meshes/audio are committed).
2. **If an independent, from-scratch decoder is still wanted** (rather than relying on UELib's
   output as documentation): verify §4's framing hypothesis against this project's own byte reader,
   then hand-walk one simple function's bytecode against §6's table before generalizing — the same
   discipline used for the BSP zone record and lightmap descriptors.
3. Investigate `Engine.U`'s crash, if its classes turn out to matter for anything this project needs
   (currently unclear that they do — it's mostly stock engine base classes).
4. Expand the native-function ID table beyond `coop-natives-map.md`'s partial coverage, if resolving
   more `__NFUN_XXX__` placeholders becomes valuable for a specific investigation.

## What this deliberately did not do

Did not build an independent decoder — this is a third-party tool's output, read and spot-checked.
Did not verify the bytecode-length framing against this project's own byte reader (§4). Did not
resolve the native-function table beyond what the existing reference already covers. Did not
investigate the `Engine.U` crash. All are real, separate pieces of work, recorded as open rather
than silently skipped.
