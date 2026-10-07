using System.Buffers.Binary;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Level;

/// <summary>
/// One baked light layer on a <c>StaticMeshInstance</c>: up to three light actors and a pointer
/// into the level's per-vertex luminance pool.
/// </summary>
/// <remarks>
/// Matches the BSP lightmap rule that baked light is stored in groups of three (SDK guide ch.14).
/// Each vertex contributes four bytes in the pool: <c>[pad, L0, L1, L2]</c> — one 0–255 luminance
/// per light slot. Colour and N·L are applied live, not stored.
/// </remarks>
public sealed record StaticMeshInstanceLayer(
    IReadOnlyList<PackageIndex> Lights,
    int FieldA,
    int PageIndex,
    int PageOffset,
    long PoolOffset);

/// <summary>Decoded <c>StaticMeshInstance</c> export: mesh link, light layers, vertex count.</summary>
public sealed record StaticMeshInstance(
    SourceId Source,
    PackageIndex Mesh,
    IReadOnlyList<StaticMeshInstanceLayer> Layers,
    int VertexCount);

/// <summary>
/// Reads BioShock <c>StaticMeshInstance</c> exports and the level-wide per-vertex luminance pool.
/// </summary>
/// <remarks>
/// <para>
/// <b>CONFIRMED_BYTES</b> on <c>1-Medical</c> (every live instance with a resolvable mesh): after the
/// tagged property list and the Vengeance <c>(4, 5)</c> header the body is
/// </para>
/// <code>
/// CI  StaticMesh
/// CI  NumLayers
/// per layer:
///   int32 4, int32 2
///   CI NumLights (1..3)
///   NumLights × CI light actor
///   int32 FieldA          // always 1 on Medical
///   int32 PageIndex       // 256 KiB bank
///   int32 PageOffset      // byte offset within the bank (4-aligned)
/// int32 VertexCount
/// int32 4, int32 2
/// int32 VertexCount       // repeat
/// int32 1
/// [padding zeros]
/// </code>
/// <para>
/// Pool address is <c>PageIndex * 262144 + PageOffset</c>. Across Medical the merged coverage of
/// <c>[addr, addr + VertexCount*4)</c> equals Σ VertexCount*4 with zero overlaps. Multi-layer
/// instances on the same page advance by exactly <c>VertexCount*4</c>; a handful of page-boundary
/// placements leave padding and resume at the next page start.
/// </para>
/// </remarks>
public static class StaticMeshInstanceReader
{
    /// <summary>Byte size of one 256 KiB luminance bank.</summary>
    public const int PoolPageSize = 262144;

    /// <summary>Bytes per vertex in the luminance pool: pad + three light-slot luminances.</summary>
    public const int BytesPerVertex = 4;

    /// <summary>Reads one <c>StaticMeshInstance</c> export, or null when the class/layout does not match.</summary>
    public static StaticMeshInstance? Read(BioShockPackage package, ObjectExport export)
    {
        if (package.GetClassName(export) != "StaticMeshInstance") return null;
        byte[] data;
        try { data = package.ReadExportData(export); }
        catch (IOException) { return null; }
        catch (InvalidDataException) { return null; }

        List<UnrealProperty> props;
        int end;
        try { props = UnrealPropertyReader.Read(data, package.Names, out end, out _); }
        catch (Exception ex) when (ex is InvalidDataException or ArgumentOutOfRangeException
                                       or IndexOutOfRangeException)
        {
            return null;
        }

        if (!TryParseBody(data.AsSpan(end), out var mesh, out var layers, out int vertexCount))
            return null;

        string packageName = Path.GetFileNameWithoutExtension(package.FilePath);
        return new StaticMeshInstance(
            new SourceId(packageName, export.Index, "StaticMeshInstance", export.ObjectName),
            mesh,
            layers,
            vertexCount);
    }

    /// <summary>
    /// Locates the luminance pool inside the package's <c>Level</c> export. Returns null when no
    /// <c>Level</c> export exists or the pool cannot be placed so that single-light layers show
    /// energy in luminance slot 0 (byte 1).
    /// </summary>
    public static (int BaseOffset, byte[] LevelData)? LocateLuminancePool(
        BioShockPackage package, IReadOnlyList<StaticMeshInstance> instances)
    {
        var levelExport = package.Exports.FirstOrDefault(e => package.GetClassName(e) == "Level");
        if (levelExport is null) return null;
        byte[] level = package.ReadExportData(levelExport);

        var probes = instances
            .SelectMany(i => i.Layers.Select(l => (i.VertexCount, Layer: l)))
            .Where(x => x.Layer.Lights.Count == 1 && x.VertexCount >= 32)
            .Take(48)
            .ToList();
        if (probes.Count == 0) return null;

        long maxEnd = 0;
        foreach (var instance in instances)
        foreach (var layer in instance.Layers)
            maxEnd = Math.Max(maxEnd, layer.PoolOffset + instance.VertexCount * (long)BytesPerVertex);
        if (maxEnd <= 0 || maxEnd > level.Length) return null;

        int bestBase = -1, bestScore = -1;
        for (int b = 0; b + maxEnd <= level.Length; b += 64)
        {
            int score = ScoreBase(level, b, probes);
            if (score > bestScore)
            {
                bestScore = score;
                bestBase = b;
            }
        }

        if (bestBase < 0 || bestScore < probes.Count / 2) return null;
        return (bestBase, level);
    }

    /// <summary>
    /// Copies one layer's per-vertex luminances (three slots, 0–1) from a previously located pool.
    /// </summary>
    public static bool TryReadLuminances(
        byte[] levelData, int poolBase, StaticMeshInstanceLayer layer, int vertexCount,
        out float[] slot0, out float[] slot1, out float[] slot2)
    {
        slot0 = new float[vertexCount];
        slot1 = new float[vertexCount];
        slot2 = new float[vertexCount];
        long at = poolBase + layer.PoolOffset;
        long need = at + vertexCount * (long)BytesPerVertex;
        if (at < 0 || need > levelData.Length) return false;

        int o = (int)at;
        for (int v = 0; v < vertexCount; v++, o += BytesPerVertex)
        {
            // Layout CONFIRMED on Medical L=1 layers: byte1 carries the sole occupied slot.
            slot0[v] = levelData[o + 1] / 255f;
            slot1[v] = levelData[o + 2] / 255f;
            slot2[v] = levelData[o + 3] / 255f;
        }

        return true;
    }

    /// <summary>
    /// Every placed actor that references a <c>StaticMeshInstance</c>, paired with the decoded
    /// instance when the export reads cleanly.
    /// </summary>
    public static IReadOnlyList<(LevelActor Actor, StaticMeshInstance? Instance)> EnumerateLive(
        BioShockPackage package, LevelContext context)
    {
        var result = new List<(LevelActor, StaticMeshInstance?)>();
        foreach (var actor in context.Actors)
        {
            var prop = actor.Properties.FirstOrDefault(p => p.Name == "StaticMeshInstance");
            if (prop is not { Type: UnrealPropertyType.Object }) continue;
            if (!prop.TryAsObjectReference(out var index) || !index.IsExport) continue;
            var instance = Read(package, package.Exports[index.ExportIndex]);
            result.Add((actor, instance));
        }

        return result;
    }

    /// <summary>
    /// Vertex count of the referenced <c>StaticMesh</c>, or -1 when the mesh will not decode.
    /// </summary>
    public static int MeshVertexCount(BioShockPackage package, PackageIndex mesh)
    {
        if (!mesh.IsExport || mesh.ExportIndex >= package.Exports.Count) return -1;
        var geom = StaticMeshReader.ReadGeometry(package.ReadExportData(package.Exports[mesh.ExportIndex]));
        return geom?.Vertices.Count ?? -1;
    }

    private static int ScoreBase(
        byte[] level, int poolBase,
        List<(int VertexCount, StaticMeshInstanceLayer Layer)> probes)
    {
        int score = 0;
        foreach (var (verts, layer) in probes)
        {
            long at = poolBase + layer.PoolOffset;
            if (at < 0 || at + 64 > level.Length) continue;
            int slot0 = 0, other = 0;
            int n = Math.Min(16, verts);
            for (int v = 0; v < n; v++)
            {
                int p = (int)at + v * BytesPerVertex;
                slot0 += level[p + 1];
                other += level[p] + level[p + 2] + level[p + 3];
            }

            if (slot0 > other && slot0 > 16) score++;
        }

        return score;
    }

    private static bool TryParseBody(
        ReadOnlySpan<byte> body, out PackageIndex mesh,
        out List<StaticMeshInstanceLayer> layers, out int vertexCount)
    {
        mesh = default;
        layers = [];
        vertexCount = 0;
        if (body.Length < 28) return false;
        if (BinaryPrimitives.ReadInt32LittleEndian(body) != 4) return false;
        if (BinaryPrimitives.ReadInt32LittleEndian(body[4..]) != 5) return false;

        int o = 8;
        try
        {
            mesh = new PackageIndex(ReadCompactIndex(body, ref o));
            int numLayers = ReadCompactIndex(body, ref o);
            if (numLayers is < 0 or > 32) return false;

            for (int li = 0; li < numLayers; li++)
            {
                if (ReadInt32(body, ref o) != 4 || ReadInt32(body, ref o) != 2) return false;
                int numLights = ReadCompactIndex(body, ref o);
                if (numLights is < 1 or > 3) return false;
                var lights = new List<PackageIndex>(numLights);
                for (int i = 0; i < numLights; i++)
                    lights.Add(new PackageIndex(ReadCompactIndex(body, ref o)));
                int fieldA = ReadInt32(body, ref o);
                int page = ReadInt32(body, ref o);
                int pageOffset = ReadInt32(body, ref o);
                if (page is < 0 or > 63) return false;
                if (pageOffset < 0 || pageOffset >= PoolPageSize || (pageOffset & 3) != 0) return false;
                layers.Add(new StaticMeshInstanceLayer(
                    lights, fieldA, page, pageOffset, page * (long)PoolPageSize + pageOffset));
            }

            int v1 = ReadInt32(body, ref o);
            if (ReadInt32(body, ref o) != 4 || ReadInt32(body, ref o) != 2) return false;
            int v2 = ReadInt32(body, ref o);
            if (ReadInt32(body, ref o) != 1 || v1 != v2 || v1 < 0) return false;
            vertexCount = v1;
            return true;
        }
        catch (Exception ex) when (ex is InvalidDataException or ArgumentOutOfRangeException
                                       or IndexOutOfRangeException)
        {
            return false;
        }
    }

    private static int ReadInt32(ReadOnlySpan<byte> data, ref int offset)
    {
        int value = BinaryPrimitives.ReadInt32LittleEndian(data[offset..]);
        offset += 4;
        return value;
    }

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
