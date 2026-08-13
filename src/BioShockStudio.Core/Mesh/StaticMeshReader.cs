using System.Buffers.Binary;
using System.Numerics;

namespace BioShockStudio.Core.Mesh;

/// <summary>
/// Reader for <c>StaticMesh</c> geometry — props, weapons without moving parts, and the pieces
/// that hang off a character's sockets.
/// <para>
/// The container is the same idea as <see cref="SkeletalMeshReader"/>'s but shorter, because a
/// static mesh binds to no skeleton: there is no bone map and no skin weights, and the UVs live in
/// their own streams rather than inside the vertex record.
/// </para>
/// <code>
/// FCompactIndex vertexCount, vertexCount x 48 bytes    position, tangent, binormal, normal
/// FCompactIndex streamCount                            UV streams, 1..3 observed
///   per stream: FCompactIndex uvCount (== vertexCount)
///               uvCount x 8 bytes                      u, v
///               int32                                  stream ordinal, 0 for the first
/// FCompactIndex indexCount,  indexCount x uint16       triangle indices
/// </code>
/// <para>
/// <b>CONFIRMED_BYTES.</b> All 8,668 <c>StaticMesh</c> exports across the 21 shipped map packages
/// and <c>ShockGame.U</c> decode, and every one of them passes the containment check below. See
/// <c>docs/research/staticmesh.md</c>.
/// </para>
/// </summary>
public static class StaticMeshReader
{
    /// <summary>Byte size of a static vertex: position, tangent, binormal and normal, no UV.</summary>
    public const int VertexStride = 48;

    /// <summary>Byte size of one UV pair in a UV stream.</summary>
    private const int UvStride = 8;

    /// <summary>
    /// Slack allowed when checking decoded positions against the mesh's own bounding box. The worst
    /// case across every shipped mesh is 0.0, so this only absorbs float noise.
    /// </summary>
    private const float BoundsSlack = 0.05f;

    /// <summary>
    /// Reads the geometry, or returns null when nothing in the payload satisfies the layout.
    /// <para>
    /// Returning null is the honest outcome for an unrecognised variant: the caller reports that the
    /// mesh cannot be drawn yet rather than showing invented triangles.
    /// </para>
    /// </summary>
    public static MeshGeometry? ReadGeometry(ReadOnlySpan<byte> payload)
    {
        if (!TryLocateGeometry(payload, out var layout)) return null;

        var vertices = new List<MeshVertex>(layout.VertexCount);
        for (int v = 0; v < layout.VertexCount; v++)
        {
            int o = layout.VertexOffset + v * VertexStride;
            vertices.Add(new MeshVertex
            {
                Position = ReadVector(payload, o),
                Tangent = ReadVector(payload, o + 12),
                Binormal = ReadVector(payload, o + 24),
                Normal = ReadVector(payload, o + 36),
                Uv = ReadUv(payload, layout.UvOffset + v * UvStride),
                Influences = [],
            });
        }

        var indices = new int[layout.IndexCount];
        for (int i = 0; i < indices.Length; i++)
            indices[i] = BinaryPrimitives.ReadUInt16LittleEndian(payload[(layout.IndexOffset + i * 2)..]);

        return new MeshGeometry
        {
            Vertices = vertices,
            Indices = indices,
            BoneMap = [],
            SkinnedVertexCount = 0,
            RigidVertexCount = 0,
            ExtraUvStreamCount = layout.StreamCount - 1,
        };
    }

    private readonly record struct GeometryLayout(
        int CountOffset, int VertexOffset, int VertexCount,
        int UvOffset, int StreamCount,
        int IndexOffset, int IndexCount);

    /// <summary>
    /// Locates the chain by search, because the header preceding it is not a fixed length — the
    /// vertex count starts at offset 144 on most meshes but at 134, 142, 152, 181 and others too.
    /// <para>
    /// Every constraint has to hold at once: the UV stream is exactly as long as the vertex array,
    /// the index count is a whole number of triangles, the largest index is the last vertex, and —
    /// the check that actually proves it — every decoded position falls inside the bounding box
    /// stored immediately ahead of the vertex count. That box is not consulted while searching, so
    /// it is independent evidence that the block found is the mesh's own geometry.
    /// </para>
    /// </summary>
    private static bool TryLocateGeometry(ReadOnlySpan<byte> payload, out GeometryLayout layout)
    {
        layout = default;

        for (int at = 0; at < payload.Length - 16; at++)
        {
            int cursor = at;
            int vertexCount;
            try { vertexCount = ReadCompactIndex(payload, ref cursor); }
            catch { continue; }

            if (vertexCount < 3) continue;
            if ((long)cursor + (long)vertexCount * VertexStride > payload.Length) continue;

            int vertexOffset = cursor;
            if (!LooksLikeVertices(payload, vertexOffset, vertexCount)) continue;

            int p = vertexOffset + vertexCount * VertexStride;
            if (p + 8 > payload.Length) continue;

            int streamCount;
            try { streamCount = ReadCompactIndex(payload, ref p); }
            catch { continue; }
            if (streamCount is < 1 or > 8) continue;

            int uvOffset = 0;
            bool bad = false;
            for (int s = 0; s < streamCount; s++)
            {
                int uvCount;
                try { uvCount = ReadCompactIndex(payload, ref p); }
                catch { bad = true; break; }

                // A UV stream covers the whole vertex array or it is not this mesh's UV stream.
                if (uvCount != vertexCount) { bad = true; break; }
                if (s == 0) uvOffset = p;

                p += uvCount * UvStride;
                if (p + 8 > payload.Length) { bad = true; break; }
                p += 4; // stream ordinal
            }
            if (bad) continue;

            int indexCount;
            try { indexCount = ReadCompactIndex(payload, ref p); }
            catch { continue; }
            if (indexCount < 3 || indexCount % 3 != 0) continue;
            if ((long)p + (long)indexCount * 2 > payload.Length) continue;

            int indexOffset = p;
            int maxIndex = 0;
            for (int i = 0; i < indexCount; i++)
            {
                int value = BinaryPrimitives.ReadUInt16LittleEndian(payload[(indexOffset + i * 2)..]);
                if (value > maxIndex) maxIndex = value;
            }
            if (maxIndex != vertexCount - 1) continue;

            if (!WithinDeclaredBounds(payload, at, vertexOffset, vertexCount)) continue;

            layout = new GeometryLayout(
                at, vertexOffset, vertexCount, uvOffset, streamCount, indexOffset, indexCount);
            return true;
        }

        return false;
    }

    /// <summary>
    /// Checks the decoded positions against the <c>FBox</c> stored immediately before the vertex
    /// count: 24 bytes of min and max, then the one-byte valid flag.
    /// </summary>
    private static bool WithinDeclaredBounds(ReadOnlySpan<byte> payload, int countOffset, int vertexOffset, int count)
    {
        const int BoxSize = 24;
        const int FlagSize = 1;
        int boxOffset = countOffset - BoxSize - FlagSize;
        if (boxOffset < 0) return false;
        if (payload[countOffset - 1] > 1) return false;

        var boundsMin = ReadVector(payload, boxOffset);
        var boundsMax = ReadVector(payload, boxOffset + 12);
        if (!IsFinite(boundsMin) || !IsFinite(boundsMax)) return false;
        if (boundsMin.X > boundsMax.X || boundsMin.Y > boundsMax.Y || boundsMin.Z > boundsMax.Z) return false;

        for (int v = 0; v < count; v++)
        {
            var p = ReadVector(payload, vertexOffset + v * VertexStride);
            if (p.X < boundsMin.X - BoundsSlack || p.X > boundsMax.X + BoundsSlack) return false;
            if (p.Y < boundsMin.Y - BoundsSlack || p.Y > boundsMax.Y + BoundsSlack) return false;
            if (p.Z < boundsMin.Z - BoundsSlack || p.Z > boundsMax.Z + BoundsSlack) return false;
        }

        return true;
    }

    /// <summary>
    /// A vertex record carries a tangent, a binormal and a normal. Any one of the three may be
    /// degenerate — <c>Turret_Cover</c> ships vertices with a null tangent and a good normal,
    /// <c>LS_Hat</c> the other way round — so each sampled record only has to carry one unit vector
    /// among the three. Requiring all three drops 33 of 610 meshes in a single package.
    /// </summary>
    private static bool LooksLikeVertices(ReadOnlySpan<byte> payload, int offset, int count)
    {
        int step = Math.Max(1, count / 32);
        for (int v = 0; v < count; v += step)
        {
            int o = offset + v * VertexStride;
            if (!IsUnit(payload, o + 12) && !IsUnit(payload, o + 24) && !IsUnit(payload, o + 36)) return false;
        }
        return true;
    }

    private static bool IsUnit(ReadOnlySpan<byte> payload, int offset)
    {
        float length = ReadVector(payload, offset).Length();
        return length is > 0.9f and < 1.1f;
    }

    private static bool IsFinite(Vector3 v) =>
        float.IsFinite(v.X) && float.IsFinite(v.Y) && float.IsFinite(v.Z);

    private static Vector2 ReadUv(ReadOnlySpan<byte> data, int offset) => new(
        BinaryPrimitives.ReadSingleLittleEndian(data[offset..]),
        BinaryPrimitives.ReadSingleLittleEndian(data[(offset + 4)..]));

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
}
