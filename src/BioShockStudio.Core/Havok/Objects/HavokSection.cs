using System.Buffers.Binary;
using System.Numerics;
using System.Text;
using BioShockStudio.Core.Havok.Packfile;

namespace BioShockStudio.Core.Havok.Objects;

/// <summary>An <c>hkArray</c> field: pointer, element count, capacity-and-flags.</summary>
public readonly record struct HkArray(int? DataOffset, int Count, int CapacityAndFlags)
{
    public bool IsEmpty => Count == 0 || DataOffset is null;
}

/// <summary>One Havok object located by a virtual fixup.</summary>
public sealed record HavokObject
{
    public required int SectionIndex { get; init; }
    public required string SectionTag { get; init; }
    public required int Offset { get; init; }
    public required string ClassName { get; init; }

    public override string ToString() => $"{ClassName}@{SectionTag}+{Offset}";
}

/// <summary>
/// A section's object data plus its resolved fixup tables — the layer that turns raw bytes into a
/// navigable object graph.
/// <para>
/// Havok serialises pointers as zero and records their targets in the fixup tables, so a pointer
/// field is only meaningful via <see cref="ResolvePointer"/>. Reading the stored value directly
/// always yields 0.
/// </para>
/// </summary>
public sealed class HavokSection
{
    private readonly Dictionary<int, int> _localBySource;
    private readonly Dictionary<int, GlobalFixup> _globalBySource;

    public int Index { get; }
    public PackfileSectionHeader Header { get; }

    /// <summary>The object data region, excluding the fixup tables.</summary>
    public ReadOnlyMemory<byte> Data { get; }

    public IReadOnlyList<LocalFixup> LocalFixups { get; }
    public IReadOnlyList<GlobalFixup> GlobalFixups { get; }
    public IReadOnlyList<VirtualFixup> VirtualFixups { get; }

    public string Tag => Header.SectionTag;

    internal HavokSection(int index, PackfileSectionHeader header, ReadOnlyMemory<byte> packfile)
    {
        Index = index;
        Header = header;
        Data = packfile.Slice(header.AbsoluteDataStart, header.DataSize);

        var span = packfile.Span;
        LocalFixups = PackfileFixups.ReadLocal(
            span.Slice(header.AbsoluteDataStart + header.LocalFixupsOffset, header.LocalFixupsSize));
        GlobalFixups = PackfileFixups.ReadGlobal(
            span.Slice(header.AbsoluteDataStart + header.GlobalFixupsOffset, header.GlobalFixupsSize));
        VirtualFixups = PackfileFixups.ReadVirtual(
            span.Slice(header.AbsoluteDataStart + header.VirtualFixupsOffset, header.VirtualFixupsSize));

        _localBySource = new Dictionary<int, int>(LocalFixups.Count);
        foreach (var fixup in LocalFixups) _localBySource[fixup.SourceOffset] = fixup.DestinationOffset;

        _globalBySource = new Dictionary<int, GlobalFixup>(GlobalFixups.Count);
        foreach (var fixup in GlobalFixups) _globalBySource[fixup.SourceOffset] = fixup;
    }

    /// <summary>Resolves a within-section pointer stored at <paramref name="fieldOffset"/>.</summary>
    public int? ResolvePointer(int fieldOffset) =>
        _localBySource.TryGetValue(fieldOffset, out int destination) ? destination : null;

    /// <summary>Resolves a cross-section pointer stored at <paramref name="fieldOffset"/>.</summary>
    public GlobalFixup? ResolveGlobalPointer(int fieldOffset) =>
        _globalBySource.TryGetValue(fieldOffset, out var fixup) ? fixup : null;

    public byte ReadByte(int offset) => Data.Span[offset];
    public short ReadInt16(int offset) => BinaryPrimitives.ReadInt16LittleEndian(Data.Span[offset..]);
    public int ReadInt32(int offset) => BinaryPrimitives.ReadInt32LittleEndian(Data.Span[offset..]);
    public uint ReadUInt32(int offset) => BinaryPrimitives.ReadUInt32LittleEndian(Data.Span[offset..]);
    public float ReadSingle(int offset) => BinaryPrimitives.ReadSingleLittleEndian(Data.Span[offset..]);

    /// <summary>Reads an <c>hkArray</c> (pointer, size, capacityAndFlags) at <paramref name="offset"/>.</summary>
    public HkArray ReadArray(int offset) =>
        new(ResolvePointer(offset), ReadInt32(offset + 4), ReadInt32(offset + 8));

    /// <summary>Reads the null-terminated string a pointer field at <paramref name="offset"/> refers to.</summary>
    public string? ReadStringPointer(int offset)
    {
        int? target = ResolvePointer(offset);
        return target is null ? null : ReadStringAt(target.Value);
    }

    public string ReadStringAt(int offset)
    {
        var span = Data.Span[offset..];
        int end = span.IndexOf((byte)0);
        return Encoding.UTF8.GetString(end >= 0 ? span[..end] : span);
    }

    /// <summary>
    /// Reads an <c>hkQsTransform</c>: three 16-byte vectors — translation, rotation quaternion,
    /// scale — each padded to four floats.
    /// </summary>
    public (Vector3 Translation, Quaternion Rotation, Vector3 Scale) ReadQsTransform(int offset) =>
        (
            new Vector3(ReadSingle(offset), ReadSingle(offset + 4), ReadSingle(offset + 8)),
            new Quaternion(ReadSingle(offset + 16), ReadSingle(offset + 20), ReadSingle(offset + 24), ReadSingle(offset + 28)),
            new Vector3(ReadSingle(offset + 32), ReadSingle(offset + 36), ReadSingle(offset + 40))
        );

    /// <summary>Size of an <c>hkQsTransform</c> in bytes.</summary>
    public const int QsTransformSize = 48;
}
