using System.Buffers.Binary;
using System.Numerics;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Mesh;

/// <summary>An attachment point declared by a <c>SkeletalMesh</c>.</summary>
public sealed record MeshSocket
{
    /// <summary>Socket name, e.g. <c>Pistol</c>, <c>RivetGunSocket</c>.</summary>
    public required string Name { get; init; }

    /// <summary>Bone the socket hangs off, e.g. <c>R_Grip</c>.</summary>
    public required string BoneName { get; init; }

    public override string ToString() => $"{Name} -> {BoneName}";
}

/// <summary>Header fields of a <c>SkeletalMesh</c> payload.</summary>
public sealed record SkeletalMeshHeader
{
    public required Vector3 BoundsMin { get; init; }
    public required Vector3 BoundsMax { get; init; }
    public required bool BoundsValid { get; init; }
    public required Vector3 SphereCenter { get; init; }
    public required float SphereRadius { get; init; }
    public required Vector3 Scale { get; init; }
    public required Vector3 Origin { get; init; }
}

/// <summary>
/// Partial reader for <c>SkeletalMesh</c> payloads.
/// <para>
/// <b>Incomplete by design.</b> The header, bounds and socket table are decoded; the vertex, index
/// and bone tables are not. What is implemented here is only what has byte evidence behind it — see
/// <c>docs/research/skeletalmesh.md</c> for what is still unknown and why the mesh cannot yet be
/// skinned.
/// </para>
/// <code>
/// +0   23 bytes   header, shared with AnimationPackageWrapper for its first 18
/// +23  FBox       bounds min, bounds max
/// +47  byte       bounds valid flag
/// +48  FSphere    centre, radius
/// +64  9 bytes    fixed tag block
/// +73  FCompactIndex
///      float3     scale
///      float3     origin
///      int3       rotation
///      float, float, int32
///      zero padding
///      FCompactIndex socketCount, socketCount x FName   socket names
///      FCompactIndex boneCount,   boneCount   x FName   attachment bone per socket
/// </code>
/// </summary>
public static class SkeletalMeshReader
{
    private const int BoundsOffset = 23;
    private const int TagBlockOffset = 64;
    private const int CompactIndexOffset = 73;

    public static SkeletalMeshHeader ReadHeader(ReadOnlySpan<byte> payload)
    {
        if (payload.Length < 128) throw new InvalidDataException("SkeletalMesh payload is too small.");

        var (scale, origin) = ReadScaleAndOrigin(payload);

        return new SkeletalMeshHeader
        {
            BoundsMin = ReadVector(payload, BoundsOffset),
            BoundsMax = ReadVector(payload, BoundsOffset + 12),
            BoundsValid = payload[BoundsOffset + 24] != 0,
            SphereCenter = ReadVector(payload, 48),
            SphereRadius = BinaryPrimitives.ReadSingleLittleEndian(payload[60..]),
            Scale = scale,
            Origin = origin,
        };
    }

    /// <summary>
    /// Reads the socket table. Returns an empty list rather than guessing when the table does not
    /// validate — several meshes carry no sockets and the surrounding layout is not yet fully
    /// understood, so a plausibility guard is the honest behaviour.
    /// </summary>
    public static IReadOnlyList<MeshSocket> ReadSockets(ReadOnlySpan<byte> payload, IReadOnlyList<NameEntry> names)
    {
        try
        {
            int offset = SocketTableOffset(payload);

            int socketCount = ReadCompactIndex(payload, ref offset);
            if (socketCount is <= 0 or > 256) return [];

            var socketNames = new string[socketCount];
            for (int i = 0; i < socketCount; i++) socketNames[i] = ReadFName(payload, ref offset, names);

            int boneCount = ReadCompactIndex(payload, ref offset);
            if (boneCount != socketCount) return [];

            var boneNames = new string[boneCount];
            for (int i = 0; i < boneCount; i++) boneNames[i] = ReadFName(payload, ref offset, names);

            // A real socket table names real things. "None" entries mean the offset search landed on
            // unrelated data, so the whole result is discarded rather than partially trusted.
            for (int i = 0; i < socketCount; i++)
            {
                if (socketNames[i] is "None" or "" || boneNames[i] is "None" or "") return [];
            }

            var result = new MeshSocket[socketCount];
            for (int i = 0; i < socketCount; i++)
                result[i] = new MeshSocket { Name = socketNames[i], BoneName = boneNames[i] };
            return result;
        }
        catch (Exception ex) when (ex is IndexOutOfRangeException or ArgumentOutOfRangeException or InvalidDataException)
        {
            return [];
        }
    }

    private static (Vector3 Scale, Vector3 Origin) ReadScaleAndOrigin(ReadOnlySpan<byte> payload)
    {
        int offset = CompactIndexOffset;
        ReadCompactIndex(payload, ref offset);
        var scale = ReadVector(payload, offset);
        var origin = ReadVector(payload, offset + 12);
        return (scale, origin);
    }

    /// <summary>
    /// Locates the socket table: the fixed fields after the tag block, then the zero padding that
    /// separates them from it.
    /// </summary>
    private static int SocketTableOffset(ReadOnlySpan<byte> payload)
    {
        int offset = CompactIndexOffset;
        ReadCompactIndex(payload, ref offset);
        offset += 12; // scale
        offset += 12; // origin
        offset += 12; // rotation
        offset += 4 + 4 + 4;

        while (offset < payload.Length && payload[offset] == 0) offset++;
        return offset;
    }

    private static Vector3 ReadVector(ReadOnlySpan<byte> data, int offset) => new(
        BinaryPrimitives.ReadSingleLittleEndian(data[offset..]),
        BinaryPrimitives.ReadSingleLittleEndian(data[(offset + 4)..]),
        BinaryPrimitives.ReadSingleLittleEndian(data[(offset + 8)..]));

    private static int ReadCompactIndex(ReadOnlySpan<byte> data, ref int offset)
    {
        byte b = data[offset++];
        bool negative = (b & 0x80) != 0;
        int value = b & 0x3F;

        if ((b & 0x40) != 0)
        {
            int shift = 6;
            while (true)
            {
                byte c = data[offset++];
                value |= (c & 0x7F) << shift;
                shift += 7;
                if ((c & 0x80) == 0) break;
                if (shift > 31) throw new InvalidDataException("FCompactIndex overflow.");
            }
        }

        return negative ? -value : value;
    }

    private static string ReadFName(ReadOnlySpan<byte> data, ref int offset, IReadOnlyList<NameEntry> names)
    {
        int index = ReadCompactIndex(data, ref offset);
        int extra = BinaryPrimitives.ReadInt32LittleEndian(data[offset..]);
        offset += 4;

        if (index < 0 || index >= names.Count) throw new InvalidDataException($"Name index {index} out of range.");
        string baseName = names[index].Name;
        return extra == 0 ? baseName : baseName + (extra - 1);
    }
}
