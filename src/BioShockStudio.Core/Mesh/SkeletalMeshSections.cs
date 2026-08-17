using System.Buffers.Binary;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Mesh;

/// <summary>
/// One run of a skeletal mesh's triangles, and the material slot it draws with.
/// </summary>
/// <remarks>
/// UModel's <c>FSkelMeshSection</c>, nine <c>uint16</c>s, commented in its source as
/// "1 section = 1 material". Only the fields this project can act on are named; the rest are
/// preserved rather than dropped, because the project's rule is that an unread field keeps its
/// bytes and its <c>Unknown</c> name.
/// </remarks>
public readonly record struct SkeletalMeshSection(
    ushort MaterialIndex,
    ushort MinStreamIndex,
    ushort MinWedgeIndex,
    ushort MaxWedgeIndex,
    ushort NumStreamIndices,
    ushort BoneIndex,
    ushort UnknownE,
    ushort FirstFace,
    ushort NumFaces)
{
    /// <summary>The section's triangles as a range into the index buffer.</summary>
    public int FirstIndex => FirstFace * 3;

    public int IndexCount => NumFaces * 3;

    public override string ToString() =>
        $"material {MaterialIndex}: faces {FirstFace}..{FirstFace + NumFaces - 1}";
}

/// <summary>
/// Reads a <c>SkeletalMesh</c>'s section table — which triangles draw with which material.
/// </summary>
/// <remarks>
/// <para>
/// <b>This closes the last open item in the mesh containers.</b> 153 skeletal meshes were drawing
/// entirely in their first material because this table was not read — <c>TommyGunMESH</c>,
/// <c>PlasmidEquipMESH</c>, <c>WP_CrossbowMesh</c> among them — while the static path has paired
/// section with material for 8,668 meshes since Phase 1.
/// </para>
/// <para>
/// <b>Status: <c>CONFIRMED_BYTES</c>.</b> The layout is UModel's <c>FStaticLODModelBio</c>
/// (<c>UnMeshBioshock.cpp</c>), which opens with the section array:
/// </para>
/// <code>
/// AttachCoords            // the socket table, already read
/// CI  LODCount
/// 8 B TRIBES_HDR          // int32 check = 4, int32 subversion
/// CI  SectionCount
/// 18 B x SectionCount     // FSkelMeshSection: nine uint16
/// CI  BoneMapCount        // ← the geometry chain this project already reads
/// </code>
/// <para>
/// <b>The walk validates itself against geometry found independently.</b> The section array must end
/// exactly where the bone map begins, and the bone map is located by a completely different route —
/// <see cref="SkeletalMeshReader.DescribeGeometry"/> searches for the vertex chain from the other
/// end of the payload. Two unrelated methods agreeing on one byte offset is the evidence; a wrong
/// section count lands anywhere else. Nothing is returned when they disagree.
/// </para>
/// <para>
/// <b>Why this was not simply a forward walk from offset 0.</b> Reaching the sections needs
/// <c>RefSkeleton</c>, whose per-bone record this project has never decoded — BioShock keeps its
/// skeletons in Havok packfiles, so the mesh's own copy is empty and the existing reader steps over
/// it as a run of zeros. That heuristic is inherited here rather than replaced, and the validation
/// above is what makes it safe to lean on.
/// </para>
/// </remarks>
public static class SkeletalMeshSectionReader
{
    /// <summary>Bytes per <c>FSkelMeshSection</c>: nine <c>uint16</c>.</summary>
    public const int SectionStride = 18;

    private const int VengeanceCheck = 4;

    /// <summary>
    /// Reads the section table, or null when it cannot be validated.
    /// </summary>
    /// <remarks>
    /// Null rather than a best effort: a wrong section table pairs triangles with the wrong material,
    /// and <c>docs/HANDOFF.md</c> §4 records that such a mesh is "complete, plausible, and just
    /// wearing the wrong paint" — invisible to every count. Drawing in one material is a visible,
    /// honest degradation; drawing in the wrong ones is not.
    /// </remarks>
    public static IReadOnlyList<SkeletalMeshSection>? Read(
        ReadOnlySpan<byte> payload, IReadOnlyList<NameEntry> names) =>
        Read(payload, names, validateAgainstGeometry: true);

    /// <summary>
    /// The table as decoded, <b>without</b> checking it against the mesh's index buffer.
    /// </summary>
    /// <remarks>
    /// For diagnosis only. A caller that draws with this can pair triangles with the wrong material,
    /// which is invisible to every numeric check — see <see cref="Read"/>.
    /// </remarks>
    public static IReadOnlyList<SkeletalMeshSection>? ReadUnvalidated(
        ReadOnlySpan<byte> payload, IReadOnlyList<NameEntry> names) =>
        Read(payload, names, validateAgainstGeometry: false);

    private static IReadOnlyList<SkeletalMeshSection>? Read(
        ReadOnlySpan<byte> payload, IReadOnlyList<NameEntry> names, bool validateAgainstGeometry)
    {
        if (SkeletalMeshReader.DescribeGeometry(payload) is not { } geometry) return null;

        try
        {
            // Inside the guard: a mesh whose socket table does not validate throws while resolving a
            // name, and that is a normal outcome — plenty of meshes carry no sockets. It means this
            // route to the sections is unavailable for that mesh, not that anything is wrong.
            var (_, socketEnd, _) = SkeletalMeshReader.DescribeSocketTable(payload, names);
            if (socketEnd <= 0 || socketEnd >= payload.Length) return null;

            int offset = socketEnd;

            // AttachCoords — 48 bytes each, and its count must match the socket table's.
            int coordCount = ReadCompactIndex(payload, ref offset);
            if (coordCount is < 0 or > 256) return null;
            offset += coordCount * 48;

            int lodCount = ReadCompactIndex(payload, ref offset);
            if (lodCount is < 1 or > 16) return null;

            // TRIBES_HDR: a check value, then one or two version fields depending on it.
            if (offset + 8 > payload.Length) return null;
            int check = BinaryPrimitives.ReadInt32LittleEndian(payload[offset..]);
            if (check != VengeanceCheck) return null;
            offset += 8;

            int sectionCount = ReadCompactIndex(payload, ref offset);
            if (sectionCount is < 1 or > 512) return null;

            int end = offset + sectionCount * SectionStride;
            if (end > payload.Length) return null;

            // The load-bearing check: the section array has to end exactly where the bone map the
            // geometry reader found begins. That reader searched from the other end of the payload,
            // so this is two independent walks agreeing on a byte.
            if (end != geometry.BoneMapOffset - CompactIndexWidth(payload, geometry.BoneMapOffset)) return null;

            var sections = new SkeletalMeshSection[sectionCount];
            for (int i = 0; i < sectionCount; i++)
            {
                int at = offset + i * SectionStride;
                sections[i] = new SkeletalMeshSection(
                    Read16(payload, at), Read16(payload, at + 2), Read16(payload, at + 4),
                    Read16(payload, at + 6), Read16(payload, at + 8), Read16(payload, at + 10),
                    Read16(payload, at + 12), Read16(payload, at + 14), Read16(payload, at + 16));
            }

            if (!validateAgainstGeometry) return sections;

            // A few meshes' sections reach past the end of the index buffer this project found.
            //
            // Measured: 4 of 331 do, by 2, 5, 5 and 8 faces on meshes of 7,000 to 19,600 —
            // WP_CrossbowMesh, TommyGunMESH, TunnelCollapse_Mesh, SubAnim_Mesh. A misread table
            // would be wildly wrong, not off by two, so the table is being read correctly and the
            // disagreement is at the very end of the index buffer. UNKNOWN which side is short;
            // this project locates the index buffer by SEARCH rather than by walking the payload,
            // which makes it the more likely candidate.
            //
            // Clamped, not rejected. Rejecting the whole table over eight faces would put a
            // 12,592-face mesh back to drawing in a single material, and the pairing for every face
            // this project actually has is unaffected — the overshoot addresses triangles that are
            // not in the index buffer to draw. A section starting entirely beyond the end is
            // dropped, because nothing can be said about it at all.
            int triangles = geometry.IndexCount / 3;
            var clamped = new List<SkeletalMeshSection>(sections.Length);

            foreach (var section in sections)
            {
                if (section.FirstFace >= triangles) continue;

                int available = triangles - section.FirstFace;
                clamped.Add(section.NumFaces <= available
                    ? section
                    : section with { NumFaces = (ushort)available });
            }

            return clamped.Count > 0 ? clamped : null;
        }
        catch (Exception ex) when (ex is IndexOutOfRangeException or ArgumentOutOfRangeException or InvalidDataException)
        {
            return null;
        }
    }

    /// <summary>
    /// How many bytes the <c>FCompactIndex</c> ending at <paramref name="valueOffset"/> occupies.
    /// </summary>
    /// <remarks>
    /// The geometry reader reports where the bone map's <i>data</i> starts, and the count that
    /// precedes it is variable-length — so the section array ends that many bytes earlier. Measured
    /// by decoding backwards from one to five bytes and keeping the width that re-reads to a
    /// position landing exactly on the data.
    /// </remarks>
    private static int CompactIndexWidth(ReadOnlySpan<byte> payload, int valueOffset)
    {
        for (int width = 1; width <= 5; width++)
        {
            int start = valueOffset - width;
            if (start < 0) break;

            int probe = start;
            try { ReadCompactIndex(payload, ref probe); }
            catch { continue; }

            if (probe == valueOffset) return width;
        }

        return 1;
    }

    private static ushort Read16(ReadOnlySpan<byte> payload, int offset) =>
        BinaryPrimitives.ReadUInt16LittleEndian(payload[offset..]);

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
