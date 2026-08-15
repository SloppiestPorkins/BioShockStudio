using System.Buffers.Binary;
using System.Numerics;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Mesh;

/// <summary>An attachment point declared by a <c>SkeletalMesh</c>.</summary>
public sealed record MeshSocket
{
    /// <summary>Socket name, e.g. <c>Pistol</c>, <c>RivetGunSocket</c>.</summary>
    public required string Name { get; init; }

    /// <summary>Bone the socket hangs off, e.g. <c>R_Grip</c>.</summary>
    public required string BoneName { get; init; }

    /// <summary>
    /// Where the socket sits relative to its bone, already in the internal basis.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <c>CONFIRMED_EXTERNAL</c> then <c>CONFIRMED_BYTES</c>. UModel's <c>USkeletalMesh</c> — which
    /// carries its own <c>#if BIOSHOCK</c> branch for this game — serialises sockets as three
    /// parallel arrays, <c>AttachAliases</c>, <c>AttachBoneNames</c> and <b><c>AttachCoords</c></b>,
    /// the last being <c>FCoords</c>: an origin and three axis vectors, 48 bytes. Verified here on
    /// the shipped bytes — <b>33 of 33 sockets across three rigs decode to an exactly orthonormal
    /// frame</b>.
    /// </para>
    /// <para>
    /// Ignoring it is why some props line up and others do not: every first-person weapon socket has
    /// a <b>zero</b> origin and so looked perfect, while <c>FireballSocket</c> is 65.8 cm from its
    /// bone, <c>GathererAttach</c> 84.8 cm and the security bot's <c>Weapon</c> 37.8 cm. A prop on
    /// one of those was wrong by exactly that much.
    /// </para>
    /// </remarks>
    public Matrix4x4 Transform { get; init; } = Matrix4x4.Identity;

    /// <summary>Whether the socket actually offsets the prop, rather than sitting on the bone.</summary>
    public bool HasOffset => !Transform.IsIdentity;

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

            // AttachCoords: a TArray of FCoords, so an FCompactIndex count and 48 bytes each. It is
            // read only when the count agrees with the two name arrays; anything else means the walk
            // is not where it thinks it is, and a wrong transform is worse than none.
            var transforms = ReadSocketCoords(payload, offset, socketCount);

            var result = new MeshSocket[socketCount];
            for (int i = 0; i < socketCount; i++)
            {
                result[i] = new MeshSocket
                {
                    Name = socketNames[i],
                    BoneName = boneNames[i],
                    Transform = transforms is null ? Matrix4x4.Identity : transforms[i],
                };
            }

            return result;
        }
        catch (Exception ex) when (ex is IndexOutOfRangeException or ArgumentOutOfRangeException or InvalidDataException)
        {
            return [];
        }
    }

    /// <summary>
    /// Reads the <c>AttachCoords</c> array that follows the two socket name arrays, or null when it
    /// is not there in the shape the format states.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <c>FCoords</c> is <c>Origin, XAxis, YAxis, ZAxis</c> — twelve floats. The axes form the
    /// socket's rotation and the origin its offset, both relative to the bone.
    /// </para>
    /// <para>
    /// Accepted only if the count matches the socket count and <b>every</b> frame is orthonormal.
    /// That is the check that makes this a decode rather than a guess: two earlier readings of this
    /// region — 28-byte quaternion+translation records, and parallel quaternion/vector arrays — both
    /// produced NaNs and non-unit axes, and this one produces 33 of 33 exact frames.
    /// </para>
    /// <para>
    /// The result is converted into the internal basis here, at the decode boundary, by the same
    /// conjugation every other transform uses. Nothing downstream may convert it again.
    /// </para>
    /// </remarks>
    private static Matrix4x4[]? ReadSocketCoords(ReadOnlySpan<byte> payload, int offset, int socketCount)
    {
        try
        {
            if (ReadCompactIndex(payload, ref offset) != socketCount) return null;
            if (offset + socketCount * 48 > payload.Length) return null;

            var result = new Matrix4x4[socketCount];

            for (int i = 0; i < socketCount; i++)
            {
                int at = offset + i * 48;

                var origin = new Vector3(
                    BinaryPrimitives.ReadSingleLittleEndian(payload[at..]),
                    BinaryPrimitives.ReadSingleLittleEndian(payload[(at + 4)..]),
                    BinaryPrimitives.ReadSingleLittleEndian(payload[(at + 8)..]));

                var x = new Vector3(
                    BinaryPrimitives.ReadSingleLittleEndian(payload[(at + 12)..]),
                    BinaryPrimitives.ReadSingleLittleEndian(payload[(at + 16)..]),
                    BinaryPrimitives.ReadSingleLittleEndian(payload[(at + 20)..]));

                var y = new Vector3(
                    BinaryPrimitives.ReadSingleLittleEndian(payload[(at + 24)..]),
                    BinaryPrimitives.ReadSingleLittleEndian(payload[(at + 28)..]),
                    BinaryPrimitives.ReadSingleLittleEndian(payload[(at + 32)..]));

                var z = new Vector3(
                    BinaryPrimitives.ReadSingleLittleEndian(payload[(at + 36)..]),
                    BinaryPrimitives.ReadSingleLittleEndian(payload[(at + 40)..]),
                    BinaryPrimitives.ReadSingleLittleEndian(payload[(at + 44)..]));

                // A socket frame is a rotation. Anything else means this is not the array.
                if (!IsOrthonormal(x, y, z)) return null;

                var local = new Matrix4x4(
                    x.X, x.Y, x.Z, 0f,
                    y.X, y.Y, y.Z, 0f,
                    z.X, z.Y, z.Z, 0f,
                    origin.X, origin.Y, origin.Z, 1f);

                result[i] = Coordinates.GameBasis.Convert(local);
            }

            return result;
        }
        catch (Exception ex) when (ex is IndexOutOfRangeException or ArgumentOutOfRangeException or InvalidDataException)
        {
            return null;
        }
    }

    private static bool IsOrthonormal(Vector3 x, Vector3 y, Vector3 z)
    {
        const float tolerance = 0.01f;

        return Math.Abs(x.Length() - 1f) < tolerance
               && Math.Abs(y.Length() - 1f) < tolerance
               && Math.Abs(z.Length() - 1f) < tolerance
               && Math.Abs(Vector3.Dot(x, y)) < tolerance
               && Math.Abs(Vector3.Dot(x, z)) < tolerance
               && Math.Abs(Vector3.Dot(y, z)) < tolerance;
    }

    /// <summary>
    /// Where the socket table starts and ends, for looking at what follows it.
    /// <para>
    /// An Unreal socket carries a relative location and rotation as well as a bone; this reader only
    /// takes the two name arrays. Whether the transforms are stored here is <c>UNKNOWN</c>, and this
    /// exists so the bytes after the table can be inspected without re-deriving the walk.
    /// </para>
    /// <para>
    /// <b>Two readings have been tried and both are wrong</b> — recorded so they are not tried again:
    /// </para>
    /// <list type="bullet">
    /// <item>
    /// <b>28-byte records of quaternion plus translation</b>, immediately after an <c>int32</c> that
    /// does equal the socket count. On <c>NEWPlayerHands</c> this yields NaN, infinities and
    /// magnitudes around 1e38 from the fifth socket onward.
    /// </item>
    /// <item>
    /// <b>Parallel arrays — N quaternions then N vectors</b>, in the style of the two name arrays.
    /// <b>0 of 19</b> of the resulting quaternions are unit length, and the <c>int32</c> that follows
    /// is <c>-2147483648</c> on the hands, <c>179</c> on <c>SecurityBot</c>: not a count, so the
    /// array does not end where this reading says.
    /// </item>
    /// </list>
    /// <para>
    /// The <c>int32</c> equalling the socket count is suggestive but is not on its own evidence of a
    /// transform array — the values after it do not behave like transforms under either layout, and
    /// the recurring <c>-0.0058</c> and <c>8.7e-8</c> are what small integers look like when read as
    /// floats. Anything here is more likely the bone map or another index array. **Do not fit a
    /// third guess to it; find the layout in `UModel-master/Unreal/` or Nyko's SDK first.**
    /// </para>
    /// </summary>
    public static (int Start, int End, int Count) DescribeSocketTable(
        ReadOnlySpan<byte> payload, IReadOnlyList<NameEntry> names)
    {
        int offset = SocketTableOffset(payload);
        int start = offset;

        int socketCount = ReadCompactIndex(payload, ref offset);
        if (socketCount is <= 0 or > 256) return (start, start, 0);

        for (int i = 0; i < socketCount; i++) ReadFName(payload, ref offset, names);

        int boneCount = ReadCompactIndex(payload, ref offset);
        for (int i = 0; i < boneCount; i++) ReadFName(payload, ref offset, names);

        return (start, offset, socketCount);
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

    /// <summary>Byte size of a vertex carrying four skin influences.</summary>
    public const int SkinnedVertexStride = 64;

    /// <summary>Byte size of a vertex bound rigidly to one bone.</summary>
    public const int RigidVertexStride = 57;

    /// <summary>
    /// Reads the mesh geometry.
    /// <para>
    /// The relevant part of the payload is a chain of <c>FCompactIndex</c>-counted arrays:
    /// </para>
    /// <code>
    /// FCompactIndex boneMapCount,  boneMapCount x uint16    mesh bone slot -> skeleton bone
    /// FCompactIndex indexCount,    indexCount   x uint16    triangle indices
    /// 4 bytes                                               unknown, observed as 1
    /// FCompactIndex skinnedCount,  skinnedCount x 64 bytes  skinned vertices
    /// FCompactIndex rigidCount,    rigidCount   x 57 bytes  rigid vertices
    /// </code>
    /// <para>
    /// CONFIRMED_BYTES for <c>NEWPlayerHands</c>: the chain fits together exactly — the bone map
    /// ends on the index count, the 26,178 indices end on the vertex header, and the largest index
    /// (4851) is one less than the combined vertex pool (3469 skinned + 1383 rigid = 4852).
    /// </para>
    /// <para>
    /// The chain is located by search rather than by a hardcoded offset, because the variable-length
    /// data preceding it is not fully understood. Every constraint below has to hold simultaneously,
    /// which makes a false positive implausible.
    /// </para>
    /// </summary>
    public static MeshGeometry? ReadGeometry(ReadOnlySpan<byte> payload)
    {
        if (!TryLocateGeometry(payload, out var layout)) return null;

        var boneMap = new int[layout.BoneMapCount];
        for (int i = 0; i < boneMap.Length; i++)
            boneMap[i] = BinaryPrimitives.ReadUInt16LittleEndian(payload[(layout.BoneMapOffset + i * 2)..]);

        var indices = new int[layout.IndexCount];
        for (int i = 0; i < indices.Length; i++)
            indices[i] = BinaryPrimitives.ReadUInt16LittleEndian(payload[(layout.IndexOffset + i * 2)..]);

        var vertices = new List<MeshVertex>(layout.SkinnedCount + layout.RigidCount);

        // The index buffer addresses the rigid block first, even though the skinned block is stored
        // ahead of it in the file. CONFIRMED_BYTES: with rigid-first the median triangle edge is
        // 0.87 units; with skinned-first it is 44.04 against a mesh only ~140 units across, i.e. the
        // triangles would span the whole model. Rendering the wrong order produces visibly shattered
        // geometry.
        for (int v = 0; v < layout.RigidCount; v++)
        {
            int o = layout.RigidOffset + v * RigidVertexStride;
            int slot = payload[o + 56];
            var rigidInfluences = slot < boneMap.Length
                ? new List<SkinInfluence> { new(boneMap[slot], 1f) }
                : [];
            vertices.Add(ReadVertexCore(payload, o, rigidInfluences));
        }

        for (int v = 0; v < layout.SkinnedCount; v++)
        {
            int o = layout.SkinnedOffset + v * SkinnedVertexStride;
            var influences = new List<SkinInfluence>(4);

            for (int k = 0; k < 4; k++)
            {
                int slot = payload[o + 56 + k * 2];
                int weight = payload[o + 57 + k * 2];
                if (weight == 0) continue;
                if (slot >= boneMap.Length) continue;
                influences.Add(new SkinInfluence(boneMap[slot], weight / 255f));
            }

            vertices.Add(ReadVertexCore(payload, o, influences));
        }

        // As in StaticMeshReader: the raw decode ends here, and the basis conversion is applied once
        // at this boundary. See Coordinates/GameBasis.
        return GameBasis.Convert(new MeshGeometry
        {
            Vertices = vertices,
            Indices = indices,
            BoneMap = boneMap,
            SkinnedVertexCount = layout.SkinnedCount,
            RigidVertexCount = layout.RigidCount,
        });
    }

    private static MeshVertex ReadVertexCore(ReadOnlySpan<byte> payload, int offset, IReadOnlyList<SkinInfluence> influences) =>
        new()
        {
            Position = ReadVector(payload, offset),
            Tangent = ReadVector(payload, offset + 12),
            Binormal = ReadVector(payload, offset + 24),
            Normal = ReadVector(payload, offset + 36),
            Uv = new Vector2(
                BinaryPrimitives.ReadSingleLittleEndian(payload[(offset + 48)..]),
                BinaryPrimitives.ReadSingleLittleEndian(payload[(offset + 52)..])),
            Influences = influences,
        };

    private readonly record struct GeometryLayout(
        int BoneMapOffset, int BoneMapCount,
        int IndexOffset, int IndexCount,
        int SkinnedOffset, int SkinnedCount,
        int RigidOffset, int RigidCount);

    /// <summary>Where each part of the geometry chain was found, for research and diagnostics.</summary>
    public readonly record struct GeometryExtent(
        int BoneMapOffset, int BoneMapCount,
        int IndexOffset, int IndexCount,
        int SkinnedOffset, int SkinnedCount,
        int RigidOffset, int RigidCount,
        int End);

    /// <summary>
    /// Reports where the geometry chain sits in a payload without decoding it, so the bytes on
    /// either side can be examined. Null when the chain is not found.
    /// </summary>
    public static GeometryExtent? DescribeGeometry(ReadOnlySpan<byte> payload)
    {
        if (!TryLocateGeometry(payload, out var layout)) return null;

        int end = layout.RigidCount > 0
            ? layout.RigidOffset + layout.RigidCount * RigidVertexStride
            : layout.SkinnedOffset + layout.SkinnedCount * SkinnedVertexStride;

        return new GeometryExtent(
            layout.BoneMapOffset, layout.BoneMapCount,
            layout.IndexOffset, layout.IndexCount,
            layout.SkinnedOffset, layout.SkinnedCount,
            layout.RigidOffset, layout.RigidCount,
            end);
    }

    private static bool TryLocateGeometry(ReadOnlySpan<byte> payload, out GeometryLayout layout)
    {
        layout = default;
        bool found = false;

        for (int at = 0; at < payload.Length - 16; at++)
        {
            int cursor = at;
            int indexCount;
            try { indexCount = ReadCompactIndex(payload, ref cursor); }
            catch { continue; }

            // A real mesh has thousands of indices, always a whole number of triangles.
            if (indexCount < 3 || indexCount % 3 != 0) continue;
            long indexEnd = (long)cursor + indexCount * 2L;
            if (indexEnd + 8 > payload.Length) continue;

            int indexOffset = cursor;
            int afterIndices = (int)indexEnd + 4;

            int vertexCursor = afterIndices;
            int firstCount;
            try { firstCount = ReadCompactIndex(payload, ref vertexCursor); }
            catch { continue; }
            if (firstCount < 0) continue;

            // The first vertex block is skinned on character meshes and rigid on simple props, so
            // the stride is identified by validating the records rather than assumed.
            int skinnedCount = 0, skinnedOffset = vertexCursor;
            int rigidCount = 0, rigidOffset = vertexCursor;

            if (firstCount > 0 && Fits(payload, vertexCursor, firstCount, SkinnedVertexStride))
            {
                skinnedCount = firstCount;
                skinnedOffset = vertexCursor;

                // A rigid block may follow the skinned one.
                int probe = vertexCursor + firstCount * SkinnedVertexStride;
                if (probe < payload.Length - 8)
                {
                    try
                    {
                        int candidate = ReadCompactIndex(payload, ref probe);
                        if (candidate > 0 && Fits(payload, probe, candidate, RigidVertexStride))
                        {
                            rigidCount = candidate;
                            rigidOffset = probe;
                        }
                    }
                    catch { /* no rigid block */ }
                }
            }
            else if (firstCount > 0 && Fits(payload, vertexCursor, firstCount, RigidVertexStride))
            {
                rigidCount = firstCount;
                rigidOffset = vertexCursor;
            }
            else if (firstCount == 0)
            {
                // A skinned count of zero is not an absent block, it is an empty one: the rigid
                // count follows immediately. The weapon viewmodels are built this way — every vertex
                // of WP_GrenadeLauncherMesh is bound rigidly to one bone, because a gun's parts are
                // hinged rather than deformed. Rejecting the zero is what left them undrawable while
                // their sockets, skeletons, animations and materials all resolved.
                int probe = vertexCursor;
                int candidate;
                try { candidate = ReadCompactIndex(payload, ref probe); }
                catch { continue; }

                if (candidate <= 0 || !Fits(payload, probe, candidate, RigidVertexStride)) continue;

                rigidCount = candidate;
                rigidOffset = probe;
            }
            else
            {
                continue;
            }

            // The index buffer must address exactly the vertices that follow it.
            int pool = skinnedCount + rigidCount;
            int maxIndex = 0;
            for (int i = 0; i < indexCount; i++)
            {
                int value = BinaryPrimitives.ReadUInt16LittleEndian(payload[(indexOffset + i * 2)..]);
                if (value > maxIndex) maxIndex = value;
            }
            if (maxIndex != pool - 1) continue;

            // The bone map is the array immediately preceding the index count.
            if (!TryReadBoneMapEndingAt(payload, at, out int boneMapOffset, out int boneMapCount)) continue;

            // A payload holds several levels of detail. Keep looking and take the densest, rather
            // than the first one encountered — which is whichever the file happens to store first.
            if (!found || pool > layout.SkinnedCount + layout.RigidCount)
            {
                layout = new GeometryLayout(
                    boneMapOffset, boneMapCount, indexOffset, indexCount,
                    skinnedOffset, skinnedCount, rigidOffset, rigidCount);
                found = true;
            }

            // Resume past this chain rather than re-scanning inside it, so the whole payload costs
            // one pass instead of one per byte.
            int chainEnd = Math.Max(
                skinnedOffset + skinnedCount * SkinnedVertexStride,
                rigidOffset + rigidCount * RigidVertexStride);
            at = Math.Max(at, chainEnd - 1);
        }

        return found;
    }

    private static bool TryReadBoneMapEndingAt(ReadOnlySpan<byte> payload, int end, out int offset, out int count)
    {
        offset = 0;
        count = 0;

        for (int at = Math.Max(0, end - 600); at < end; at++)
        {
            int cursor = at;
            int candidate;
            try { candidate = ReadCompactIndex(payload, ref cursor); }
            catch { continue; }

            if (candidate is <= 0 or > 256) continue;
            if (cursor + candidate * 2 != end) continue;

            // Bone slots address a skeleton, so they are small and distinct.
            var seen = new HashSet<int>();
            bool ok = true;
            for (int i = 0; i < candidate; i++)
            {
                int value = BinaryPrimitives.ReadUInt16LittleEndian(payload[(cursor + i * 2)..]);
                if (value > 255 || !seen.Add(value)) { ok = false; break; }
            }
            if (!ok) continue;

            offset = cursor;
            count = candidate;
            return true;
        }

        return false;
    }

    private static bool Fits(ReadOnlySpan<byte> payload, int offset, int count, int stride)
    {
        long end = (long)offset + count * (long)stride;
        return end <= payload.Length && LooksLikeVertices(payload, offset, count, stride);
    }

    /// <summary>
    /// Whether a run of records looks like vertices: each carries a tangent basis at +12/+24/+36.
    /// </summary>
    /// <remarks>
    /// Any one of the three may be degenerate on a given vertex, so a record only has to carry one
    /// unit vector among them — the same tolerance <see cref="StaticMeshReader"/> needs, and for the
    /// same reason. Demanding all three is what kept the weapon viewmodels from decoding:
    /// <c>WP_GrenadeLauncherMesh</c> has 11,721 vertices at the ordinary 57-byte rigid stride, and
    /// the run was being broken by the handful with a null tangent.
    /// </remarks>
    private static bool LooksLikeVertices(ReadOnlySpan<byte> payload, int offset, int count, int stride)
    {
        int sampled = 0;
        int step = Math.Max(1, count / 24);

        for (int v = 0; v < count; v += step)
        {
            int o = offset + v * stride;
            if (o + stride > payload.Length) return false;
            if (!IsUnit(payload, o + 12) && !IsUnit(payload, o + 24) && !IsUnit(payload, o + 36)) return false;
            sampled++;
        }

        return sampled > 0;
    }

    private static bool IsUnit(ReadOnlySpan<byte> payload, int offset)
    {
        var v = ReadVector(payload, offset);
        float length = v.Length();
        return length is > 0.9f and < 1.1f;
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
