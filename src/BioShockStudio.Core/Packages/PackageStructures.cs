namespace BioShockStudio.Core.Packages;

/// <summary>
/// Header of a BioShock Remastered <c>.bsm</c> package.
/// CONFIRMED_BYTES against all 21 non-localised shipped packages: every one parses to the exact file length.
/// </summary>
public sealed record PackageSummary
{
    public const uint UnrealPackageMagic = 0x9E2A83C1;

    /// <summary>142 for BioShock 1 Remastered.</summary>
    public required ushort FileVersion { get; init; }

    /// <summary>56 for BioShock 1 Remastered.</summary>
    public required ushort LicenseeVersion { get; init; }

    public required uint PackageFlags { get; init; }
    public required int NameCount { get; init; }
    public required int NameOffset { get; init; }
    public required int ExportCount { get; init; }
    public required int ExportOffset { get; init; }
    public required int ImportCount { get; init; }
    public required int ImportOffset { get; init; }
    public required Guid Guid { get; init; }
    public required IReadOnlyList<PackageGeneration> Generations { get; init; }
}

public readonly record struct PackageGeneration(int ExportCount, int NameCount);

/// <summary>
/// One entry of the name table: FCompactIndex character count, UTF-16LE text, then 8 bytes of flags.
/// CONFIRMED_BYTES — the table always ends exactly on <see cref="PackageSummary.ImportOffset"/>.
/// </summary>
public readonly record struct NameEntry(string Name, ulong Flags)
{
    public override string ToString() => Name;
}

/// <summary>
/// An object reference into the name/import/export tables.
/// Negative values index the import table as <c>-Value - 1</c>; positive values index the export
/// table as <c>Value - 1</c>; zero is the null reference.
/// </summary>
public readonly record struct PackageIndex(int Value)
{
    public bool IsNull => Value == 0;
    public bool IsImport => Value < 0;
    public bool IsExport => Value > 0;
    public int ImportIndex => -Value - 1;
    public int ExportIndex => Value - 1;
    public override string ToString() => Value.ToString();
}

/// <summary>
/// Import table entry. CONFIRMED_BYTES — the table always ends exactly on
/// <see cref="PackageSummary.ExportOffset"/> for every shipped package.
/// </summary>
public sealed record ObjectImport
{
    public required string ClassPackage { get; init; }
    public required string ClassName { get; init; }
    public required PackageIndex Outer { get; init; }
    public required string ObjectName { get; init; }

    public override string ToString() => $"{ClassPackage}.{ClassName} {ObjectName}";
}

/// <summary>
/// Export table entry.
/// <para>
/// Layout (CONFIRMED_BYTES — every shipped package's export table ends exactly on EOF, and every
/// non-zero <see cref="SerialOffset"/> chains contiguously from 64):
/// </para>
/// <code>
/// FCompactIndex ClassIndex
/// FCompactIndex SuperIndex
/// int32         OuterIndex
/// int32         Unknown32          // HYPOTHESIS: archetype/template index; zero in every sample seen so far
/// FName         ObjectName         // FCompactIndex nameIndex + int32 number
/// uint64        ObjectFlags        // widened from UE2's 32-bit flags
/// FCompactIndex SerialSize
/// FCompactIndex SerialOffset       // present even when SerialSize is 0, unlike stock UE2
/// int32         TrailingUnknown32  // UNKNOWN: observed 0 or 1
/// </code>
/// </summary>
public sealed record ObjectExport
{
    public required int Index { get; init; }
    public required PackageIndex ClassIndex { get; init; }
    public required PackageIndex SuperIndex { get; init; }
    public required PackageIndex OuterIndex { get; init; }
    public required int Unknown32 { get; init; }
    public required string ObjectName { get; init; }
    public required ulong ObjectFlags { get; init; }
    public required int SerialSize { get; init; }
    public required int SerialOffset { get; init; }
    public required int TrailingUnknown32 { get; init; }

    public override string ToString() => ObjectName;
}
