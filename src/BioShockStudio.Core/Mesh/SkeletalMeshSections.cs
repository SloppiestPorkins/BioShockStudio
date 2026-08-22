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
    /// <summary>
    /// Where this section actually begins in the index buffer, in faces: the running total of the
    /// sections stored before it.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>Not <see cref="FirstFace"/>, and that is measured.</b> Across all 337 shipped section
    /// tables the sections' <c>NumFaces</c> add up to <b>exactly</b> the index buffer's face count —
    /// 337 of 337, no exceptions — so the sections tile the buffer with no gaps. <c>FirstFace</c>
    /// agrees with that running total on 333 of them and disagrees on four, by 2, 5, 6 and 8 faces:
    /// <c>TommyGunMESH</c>, <c>WP_CrossbowMesh</c>, <c>TunnelCollapse_Mesh</c>,
    /// <c>SubAnim_Mesh</c>. Those four are the meshes previously recorded as "sections overrun the
    /// index buffer".
    /// </para>
    /// <para>
    /// <b>Nothing was ever short.</b> The note in <c>skeletalmesh.md</c> suspected the index buffer,
    /// because this project locates it by search — that suspicion is refuted by the sum identity
    /// above. <see cref="MinStreamIndex"/> confirms it independently: it equals the running index
    /// total on 336 of 337, and the one exception, <c>CoreTop_Mesh</c>, is a <c>uint16</c> wrap —
    /// 25,260 faces × 3 = 75,780, and 75,780 − 65,536 = 10,244, which is the value stored.
    /// </para>
    /// <para>
    /// What <c>FirstFace</c> means on those four is <b>UNKNOWN</b>; it is preserved rather than
    /// corrected. Placing a section by the running total cannot overrun by construction, which is
    /// why the clamp this reader used to apply is gone.
    /// </para>
    /// </remarks>
    public int FirstFaceInBuffer { get; init; }

    /// <summary>The section's triangles as a range into the index buffer.</summary>
    public int FirstIndex => FirstFaceInBuffer * 3;

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

    /// <summary>
    /// The table as found by walking forward from the socket table. Exposed so the two routes can be
    /// compared against each other — see <c>SkeletalMeshSectionCoverageTests</c>.
    /// </summary>
    public static IReadOnlyList<SkeletalMeshSection>? ReadViaSockets(
        ReadOnlySpan<byte> payload, IReadOnlyList<NameEntry> names) =>
        SkeletalMeshReader.DescribeGeometry(payload) is { } geometry
            ? ReadForwardFromSockets(payload, names, geometry, validateAgainstGeometry: true)
            : null;

    /// <summary>
    /// The table as found by counting backward from the bone map, needing no socket table.
    /// </summary>
    public static IReadOnlyList<SkeletalMeshSection>? ReadViaBoneMap(ReadOnlySpan<byte> payload) =>
        SkeletalMeshReader.DescribeGeometry(payload) is { } geometry
            ? ReadBackwardFromBoneMap(payload, geometry, validateAgainstGeometry: true)
            : null;

    private static IReadOnlyList<SkeletalMeshSection>? Read(
        ReadOnlySpan<byte> payload, IReadOnlyList<NameEntry> names, bool validateAgainstGeometry)
    {
        if (SkeletalMeshReader.DescribeGeometry(payload) is not { } geometry) return null;

        return ReadForwardFromSockets(payload, names, geometry, validateAgainstGeometry)
               ?? ReadBackwardFromBoneMap(payload, geometry, validateAgainstGeometry);
    }

    /// <summary>
    /// Finds the table by counting <b>backwards</b> from the bone map, without the socket table.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>The forward walk is only available when a mesh's socket table validates, and most do
    /// not.</b> It starts at the sockets and steps over <c>AttachCoords</c>, the LOD count and the
    /// header to reach the sections — so a mesh that carries no sockets, or whose socket names will
    /// not resolve, loses its section table for a reason that has nothing to do with the sections.
    /// Measured before this existed: <b>331 of 944</b> skeletal meshes with geometry (35%) got a
    /// table. The rest drew entirely in their first material.
    /// </para>
    /// <para>
    /// <b>The layout allows the search to run the other way, and the other way needs nothing but the
    /// geometry.</b> The section array ends exactly where the bone map's count begins, so for a
    /// candidate count <c>N</c> the array occupies <c>18N</c> bytes ending at that anchor — and the
    /// <c>FCompactIndex</c> encoding <c>N</c> must itself end exactly where the array starts. That is
    /// a strong constraint: the count has to describe the very gap it precedes, at a variable-width
    /// encoding, and a wrong <c>N</c> lands the index somewhere that does not decode to <c>N</c>.
    /// </para>
    /// <para>
    /// <b>Corroborated by the header and settled by the face sum.</b> Where the eight bytes before
    /// the count are the <c>TRIBES_HDR</c> — a <c>check</c> of 4 — that candidate is preferred; and
    /// every candidate still has to pass the same test the forward walk does, that the sections'
    /// face counts add up to exactly the index buffer's triangles. A table that fails it is reported
    /// as no table rather than clamped, because a wrong material pairing is invisible to every count
    /// (<c>docs/HANDOFF.md</c> §4).
    /// </para>
    /// </remarks>
    private static IReadOnlyList<SkeletalMeshSection>? ReadBackwardFromBoneMap(
        ReadOnlySpan<byte> payload, SkeletalMeshReader.GeometryExtent geometry, bool validateAgainstGeometry)
    {
        int anchor = geometry.BoneMapOffset - CompactIndexWidth(payload, geometry.BoneMapOffset);
        if (anchor <= 0 || anchor > payload.Length) return null;

        IReadOnlyList<SkeletalMeshSection>? withoutHeader = null;

        for (int sectionCount = 1; sectionCount <= 512; sectionCount++)
        {
            int sectionsStart = anchor - sectionCount * SectionStride;
            if (sectionsStart < 1) break;

            if (!CountEndsAt(payload, sectionsStart, sectionCount)) continue;

            var sections = Decode(payload, sectionsStart, sectionCount, geometry, validateAgainstGeometry);
            if (sections is null) continue;

            // The header is corroboration, not a requirement: prefer a candidate that has it, but do
            // not discard one that does not — the face sum has already had to agree.
            int countStart = sectionsStart - CompactIndexWidth(payload, sectionsStart);
            if (countStart >= 8
                && BinaryPrimitives.ReadInt32LittleEndian(payload[(countStart - 8)..]) == VengeanceCheck)
                return sections;

            withoutHeader ??= sections;
        }

        return withoutHeader;
    }

    /// <summary>Whether an <c>FCompactIndex</c> encoding <paramref name="value"/> ends exactly at <paramref name="end"/>.</summary>
    private static bool CountEndsAt(ReadOnlySpan<byte> payload, int end, int value)
    {
        for (int width = 1; width <= 5; width++)
        {
            int start = end - width;
            if (start < 0) return false;

            int probe = start;
            int decoded;
            try { decoded = ReadCompactIndex(payload, ref probe); }
            catch { continue; }

            if (probe == end && decoded == value) return true;
        }

        return false;
    }

    /// <summary>Builds and validates the table sitting at a known offset.</summary>
    private static IReadOnlyList<SkeletalMeshSection>? Decode(
        ReadOnlySpan<byte> payload, int offset, int sectionCount,
        SkeletalMeshReader.GeometryExtent geometry, bool validateAgainstGeometry)
    {
        if (offset < 0 || offset + sectionCount * SectionStride > payload.Length) return null;

        var sections = new SkeletalMeshSection[sectionCount];
        int runningFace = 0;

        for (int i = 0; i < sectionCount; i++)
        {
            int at = offset + i * SectionStride;
            sections[i] = new SkeletalMeshSection(
                Read16(payload, at), Read16(payload, at + 2), Read16(payload, at + 4),
                Read16(payload, at + 6), Read16(payload, at + 8), Read16(payload, at + 10),
                Read16(payload, at + 12), Read16(payload, at + 14), Read16(payload, at + 16))
            {
                FirstFaceInBuffer = runningFace,
            };
            runningFace += sections[i].NumFaces;
        }

        if (!validateAgainstGeometry) return sections;
        return runningFace == geometry.IndexCount / 3 ? sections : null;
    }

    private static IReadOnlyList<SkeletalMeshSection>? ReadForwardFromSockets(
        ReadOnlySpan<byte> payload, IReadOnlyList<NameEntry> names,
        SkeletalMeshReader.GeometryExtent geometry, bool validateAgainstGeometry)
    {
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
            int runningFace = 0;

            for (int i = 0; i < sectionCount; i++)
            {
                int at = offset + i * SectionStride;
                sections[i] = new SkeletalMeshSection(
                    Read16(payload, at), Read16(payload, at + 2), Read16(payload, at + 4),
                    Read16(payload, at + 6), Read16(payload, at + 8), Read16(payload, at + 10),
                    Read16(payload, at + 12), Read16(payload, at + 14), Read16(payload, at + 16))
                {
                    // Sections tile the buffer in stored order. See FirstFaceInBuffer.
                    FirstFaceInBuffer = runningFace,
                };
                runningFace += sections[i].NumFaces;
            }

            if (!validateAgainstGeometry) return sections;

            // The table has to describe THIS index buffer, and the test of that is arithmetic: the
            // sections' face counts must add up to exactly the buffer's faces. Measured across every
            // shipped table, 337 of 337 do.
            //
            // This replaces a clamp. The clamp existed because four meshes' sections appeared to
            // reach past the end of the buffer — they do not, and never did: FirstFace is simply not
            // where a section starts. Placing sections by their running total makes an overrun
            // impossible by construction, and the sum below is what makes that safe rather than
            // assumed.
            //
            // A table that fails it is not clamped into agreement: nothing can be said about which
            // triangles it means, and a wrong material pairing is invisible to every count. So it is
            // reported as no table, which degrades the mesh to one material — visible and honest.
            int triangles = geometry.IndexCount / 3;
            if (runningFace != triangles) return null;

            return sections;
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
