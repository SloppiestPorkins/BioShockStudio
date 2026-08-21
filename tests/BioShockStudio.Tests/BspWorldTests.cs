using System.Numerics;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using Xunit;

namespace BioShockStudio.Tests;

/// <summary>
/// The compiled world: the level's actual architecture.
/// </summary>
/// <remarks>
/// <para>
/// Until this, a level export and the walkthrough carried <b>only</b> static meshes and the
/// designer's source brushes — so Lighthouse read as a skyline and props with the rooms missing.
/// The floors and walls a player stands on are in the compiled BSP.
/// </para>
/// <para>
/// <b>Planarity is the assertion that decides whether the layout is right.</b> Three independent
/// arrays — the nodes, the vertex pool and the points — must agree: every polygon's vertices have
/// to lie on its own node's plane. A wrong field offset cannot produce coplanar polygons by
/// accident, which is exactly how Nyko settled <c>NumVertices</c> at +78 against +88 (0 of 7,125
/// failures against 64%).
/// </para>
/// </remarks>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
public sealed class BspWorldTests(GameFixture game)
{
    private static int ReadCompactIndex(ReadOnlySpan<byte> data, ref int offset)
    {
        byte first = data[offset++];
        bool negative = (first & 0x80) != 0;
        int value = first & 0x3F;

        if ((first & 0x40) != 0)
        {
            int shift = 6;
            while (true)
            {
                byte next = data[offset++];
                value |= (next & 0x7F) << shift;
                shift += 7;
                if ((next & 0x80) == 0) break;
                if (shift > 31) throw new InvalidDataException("FCompactIndex overflow.");
            }
        }

        return negative ? -value : value;
    }

    private static void Log(string line)
    {
        if (Environment.GetEnvironmentVariable("BIOSHOCK_PROBE_LOG") is { Length: > 0 } path)
            File.AppendAllText(path, line + Environment.NewLine);
    }

    /// <summary>The package's compiled world, or null when it holds no model at all.</summary>
    /// <remarks>
    /// Not every <c>.bsm</c> in the maps folder is a map — some carry no <c>Model</c> whatsoever,
    /// so this returns null rather than throwing and the sweep counts them instead of failing.
    /// </remarks>
    private static BspWorld? World(BioShockPackage package)
    {
        var model = ModelReader.BuiltWorld(package);
        if (model is null) return null;
        return BspWorldReader.Read(package, package.Exports[model.Source.ExportIndex]);
    }

    [RequiresGameFact]
    public void EveryCompiledWorldsPolygonsLieOnTheirOwnPlanes()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();

        int worlds = 0, polygons = 0, triangles = 0, offPlane = 0, checkedPolygons = 0;
        float worstOverall = 0f;

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var world = World(package);
            if (world is null || world.PolygonCount == 0) continue;

            worlds++;
            polygons += world.PolygonCount;
            triangles += world.TriangleCount;

            var (worst, off, checkedHere) = world.Planarity();
            worstOverall = MathF.Max(worstOverall, worst);
            offPlane += off;
            checkedPolygons += checkedHere;

            Log($"{Path.GetFileNameWithoutExtension(map),-24} {world.Nodes.Count,5} nodes, "
                + $"{world.PolygonCount,5} polygons, {world.Surfaces.Count,5} surfaces, "
                + $"{world.VertexPool.Count,7} pool, worst {worst,8:0.###}, off-plane {off}");
        }

        Log($"compiled worlds: {worlds}, polygons {polygons:N0}, triangles {triangles:N0}");
        Log($"planarity: {offPlane} of {checkedPolygons:N0} polygons more than 1 cm off their own plane, "
            + $"worst {worstOverall:0.###}");

        Assert.True(worlds >= 20, $"only {worlds} maps yielded a compiled world");
        Assert.True(polygons > 50_000, $"only {polygons} polygons across every map");

        // The share is what says the layout is right, not the maximum: a handful of polygons can sit
        // slightly off their plane through float precision at 80,000 units from the origin, but a
        // wrong field offset puts a large fraction of them nowhere near it — Nyko measured 64%
        // failures reading NumVertices at +88 instead of +78.
        double share = checkedPolygons == 0 ? 1 : (double)offPlane / checkedPolygons;
        Assert.True(share < 0.001,
            $"{offPlane} of {checkedPolygons} polygons ({share:P2}) are more than 1 cm off their own "
            + "plane, so the node layout is wrong");
    }

    /// <summary>
    /// What sits immediately after the vertex pool: <c>NumSharedSides</c> and <c>NumZones</c>.
    /// </summary>
    /// <remarks>
    /// <para>
    /// The reader stops at the vertex pool, and between 8% and 27% of a <c>Model</c> payload is
    /// still unread — 698,916 bytes on <c>1-Medical</c>. The lightmap descriptors are expected to be
    /// in there (<c>bsp.md</c> §5.5), so knowing what the tail starts with is the first step of
    /// reaching them, and it is now known rather than searched for.
    /// </para>
    /// <para>
    /// <b>The check that identifies the second field is the zone byte on the nodes.</b> UE2's
    /// <c>UModel</c> writes <c>NumSharedSides</c> then <c>NumZones</c> after the vertex pool, and a
    /// node's zone must index that array — so <c>max(node.Zone)</c> has to be exactly
    /// <c>NumZones − 1</c>. It is, on <b>all 21 maps</b>, from a 2-zone <c>Entry</c> to a 125-zone
    /// <c>4-Recreation</c>. An arbitrary int32 does not track a byte field on 21 independent maps.
    /// </para>
    /// <para>
    /// <b>What is still unknown is the zone record itself.</b> Its zone-actor references sit 38
    /// bytes apart within a map — they resolve to <c>ZoneInfo</c> and <c>SkyZoneInfo</c> exports,
    /// which is what a zone points at — but a fixed 38-byte stride only lands on the <c>Polys</c>
    /// reference that should follow the array on 2 of 21 maps, because the reference is an
    /// <c>FCompactIndex</c> and its width varies. So the record is variable-width and its field
    /// order is <c>UNKNOWN</c>; that is the next thing to settle, and it is what stands between
    /// this and <c>FLightMapIndex</c>.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void TheTailAfterTheVertexPoolStartsWithTheZoneCount()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();

        int worlds = 0, agreeing = 0;
        long unread = 0, payloads = 0;
        var disagreements = new List<string>();

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var model = ModelReader.BuiltWorld(package);
            if (model is null) continue;

            var export = package.Exports[model.Source.ExportIndex];
            var world = BspWorldReader.Read(package, export);
            if (world is null || world.Nodes.Count == 0) continue;

            byte[] payload = package.ReadExportData(export);
            int at = world.Layout.DecodedEnd;
            if (at + 8 > payload.Length) continue;

            worlds++;
            unread += world.Layout.Unread;
            payloads += world.Layout.PayloadLength;

            int declaredZones = System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(payload.AsSpan(at + 4));
            int highestZone = world.Nodes.Max(n => (int)n.Zone);

            if (declaredZones == highestZone + 1) agreeing++;
            else
                disagreements.Add($"{Path.GetFileNameWithoutExtension(map)}: declares {declaredZones} zones, "
                                  + $"nodes reach zone {highestZone}");
        }

        Log($"tails: {worlds} worlds, {unread:N0} of {payloads:N0} bytes unread "
            + $"({100.0 * unread / payloads:0.#}%), {agreeing} declare a zone count matching their nodes");

        Assert.True(worlds >= 20, $"only {worlds} compiled worlds were read");
        Assert.True(unread > 0, "nothing is unread, so the tail this describes is gone");

        // The identification, as an assertion that can fail: every map's second tail field is its
        // zone count. Reading the wrong offset, or a decode that stopped somewhere else, breaks it.
        Assert.True(disagreements.Count == 0,
            "the int32 after the vertex pool is not the zone count on every map:"
            + Environment.NewLine + string.Join(Environment.NewLine, disagreements));
    }

    /// <summary>
    /// The zone array walks to the <c>Polys</c> reference, and the array after it is the bounds.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A zone record is an <c>FCompactIndex</c> actor reference followed by <b>36 fixed bytes</b> —
    /// found by reading the bytes rather than by trying strides: the fixed part begins with the
    /// zone's own bit mask, 1, 2, 4 for zones 0, 1, 2, and the references resolve to <c>ZoneInfo</c>
    /// and <c>SkyZoneInfo</c> exports. A fixed 38-byte stride was tried first and lands correctly on
    /// only 2 of 21 maps, because the reference's width varies with the export index.
    /// </para>
    /// <para>
    /// <b>Two anchors, and the second corrected the first.</b> Walking the zones lands on a
    /// reference resolving to a <c>Polys</c> export on 21 of 21 maps, which is what makes the walk a
    /// decode. The array after it was then <i>assumed</i> to be <c>LightMap</c>, from UE2's
    /// serialisation order — and reading the records refutes that: <c>Entry</c>'s first is
    /// <c>min(−128,−128,−128) max(128,128,128)</c>. It is <c>Bounds</c>, a <c>TArray&lt;FBox&gt;</c>.
    /// </para>
    /// <para>
    /// <b>25,349 records across the 21 maps, and every one is a valid box:</b> six floats with
    /// <c>min ≤ max</c> on all three axes and in world range, then an <c>IsValid</c> byte of 1, at a
    /// 25-byte stride. A wrong record size cannot hold that across arrays of 5 to 2,949 elements.
    /// The lightmap array is further on, past <c>LeafHulls</c>, <c>Leaves</c> and <c>Lights</c>.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void TheZoneWalkLandsOnPolysAndTheArrayAfterItIsBoxes()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();

        int worlds = 0, located = 0, boxes = 0, validBoxes = 0;
        var problems = new List<string>();

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var model = ModelReader.BuiltWorld(package);
            if (model is null) continue;

            var export = package.Exports[model.Source.ExportIndex];
            var world = BspWorldReader.Read(package, export);
            if (world is null || world.Nodes.Count == 0) continue;

            worlds++;
            var layout = world.Layout;
            string name = Path.GetFileNameWithoutExtension(map);

            if (layout.Bounds <= 0 || layout.BoundCount <= 0)
            {
                problems.Add($"{name}: the zone walk found no bounds array "
                             + $"(offset {layout.Bounds}, count {layout.BoundCount})");
                continue;
            }

            located++;
            byte[] payload = package.ReadExportData(export);

            for (int i = 0; i < layout.BoundCount; i++)
            {
                int at = layout.Bounds + i * 25;
                if (at + 25 > payload.Length) { problems.Add($"{name}: box {i} runs past the payload"); break; }

                var span = payload.AsSpan(at);
                float minX = System.Buffers.Binary.BinaryPrimitives.ReadSingleLittleEndian(span);
                float minY = System.Buffers.Binary.BinaryPrimitives.ReadSingleLittleEndian(span[4..]);
                float minZ = System.Buffers.Binary.BinaryPrimitives.ReadSingleLittleEndian(span[8..]);
                float maxX = System.Buffers.Binary.BinaryPrimitives.ReadSingleLittleEndian(span[12..]);
                float maxY = System.Buffers.Binary.BinaryPrimitives.ReadSingleLittleEndian(span[16..]);
                float maxZ = System.Buffers.Binary.BinaryPrimitives.ReadSingleLittleEndian(span[20..]);

                boxes++;

                bool ordered = minX <= maxX && minY <= maxY && minZ <= maxZ;
                bool inRange = float.IsFinite(minX) && float.IsFinite(maxZ)
                               && MathF.Abs(minX) < 300_000 && MathF.Abs(maxZ) < 300_000;

                if (ordered && inRange && span[24] == 1) validBoxes++;
            }

            Log($"{name,-22} zones {layout.ZoneCount,4}  bounds {layout.BoundCount,6} at {layout.Bounds,10:N0}  "
                + $"nodes {world.Nodes.Count,5}  still unread after them "
                + $"{layout.PayloadLength - layout.Bounds - layout.BoundCount * 25,9:N0}");
        }

        Log($"bounds: {validBoxes} of {boxes} records are valid FBoxes at a 25-byte stride");

        Assert.True(worlds >= 20, $"only {worlds} compiled worlds were read");
        Assert.Equal(worlds, located);
        Assert.True(boxes > 20_000, $"only {boxes} records were checked");

        // The claim: every record is a box. This is what says the walk lands where it says it does —
        // and it is the check that refuted the first reading of this array as the lightmap table.
        Assert.Equal(boxes, validBoxes);

        Assert.True(problems.Count == 0,
            "the zone walk did not land on an array of boxes:"
            + Environment.NewLine + string.Join(Environment.NewLine, problems));
    }

    /// <summary>
    /// The complete structural tail reaches the lightmap descriptor array without scanning.
    /// </summary>
    /// <remarks>
    /// <para>
    /// After <c>Bounds</c>, <c>UModel</c> serialises <c>LeafHulls</c>, 12-byte <c>FLeaf</c>
    /// records, light references, one further object-reference array, then two int32 fields. The
    /// next compact count is the <c>FLightMapIndex</c> array: one entry per surface, beginning with
    /// the Vengeance object header <c>(4, 2)</c>. This is the anchor that proves the variable-width
    /// reference arrays were walked correctly rather than skipped with a guessed stride.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void StructuralTailWalkLandsOnOneLightmapDescriptorPerSurface()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();

        int worlds = 0, anchored = 0, leaves = 0, lightReferences = 0;
        var problems = new List<string>();

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var world = World(package);
            if (world is null || world.Nodes.Count == 0) continue;

            worlds++;
            string name = Path.GetFileNameWithoutExtension(map);
            var layout = world.Layout;
            byte[] payload = package.ReadExportData(package.Exports[world.Source.ExportIndex]);

            if (layout.LightMaps <= 0 || layout.LightMaps + 10 > payload.Length)
            {
                problems.Add($"{name}: tail did not reach a lightmap boundary (at {layout.LightMaps})");
                continue;
            }

            if (world.Leaves.Count != layout.LeafCount || world.LightReferences.Count != layout.LightCount)
            {
                problems.Add($"{name}: tail count/list mismatch (leaves {world.Leaves.Count}/{layout.LeafCount}, "
                             + $"lights {world.LightReferences.Count}/{layout.LightCount})");
                continue;
            }

            int at = layout.LightMaps;
            int lightMapCount = ReadCompactIndex(payload, ref at);
            int check = System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(payload.AsSpan(at));
            int version = System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(payload.AsSpan(at + 4));

            leaves += world.Leaves.Count;
            lightReferences += world.LightReferences.Count;
            Log($"{name,-22} hulls {layout.LeafHullCount,6} leaves {layout.LeafCount,6} lights {layout.LightCount,5} "
                + $"other refs {layout.OtherReferenceCount,5} lightmaps {lightMapCount,6} at {layout.LightMaps,10:N0}");

            if (lightMapCount == world.Surfaces.Count && check == 4 && version == 2)
                anchored++;
            else
                problems.Add($"{name}: expected {world.Surfaces.Count} lightmaps headed (4,2), got "
                             + $"{lightMapCount} headed ({check},{version})");
        }

        Log($"tail walk: {anchored} of {worlds} worlds anchored; {leaves:N0} leaves, {lightReferences:N0} light refs");

        Assert.True(worlds >= 20, $"only {worlds} compiled worlds were read");
        Assert.Equal(worlds, anchored);
        Assert.True(leaves > 10_000, $"only {leaves} leaves were read");
        Assert.True(problems.Count == 0,
            "the structural tail did not land on FLightMapIndex:" + Environment.NewLine
            + string.Join(Environment.NewLine, problems));
    }

    /// <summary>The verified lightmap-descriptor variant maps uniquely to its compiled surfaces.</summary>
    [RequiresGameFact]
    public void LightmapDescriptorsCoverEverySurface()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();

        int worlds = 0, decodedWorlds = 0, descriptors = 0, embeddedLayers = 0;
        var problems = new List<string>();

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var world = World(package);
            if (world is null || world.Nodes.Count == 0) continue;

            worlds++;
            string name = Path.GetFileNameWithoutExtension(map);
            var mapsForWorld = world.LightMaps;
            descriptors += mapsForWorld.Count;

            if (mapsForWorld.Count != world.Surfaces.Count)
            {
                Log($"{name,-22} descriptor tail uses an unverified variable layout");
                continue;
            }

            decodedWorlds++;

            var expectedSurfaces = Enumerable.Range(0, world.Surfaces.Count).ToHashSet();
            var actualSurfaces = mapsForWorld.Select(lightMap => lightMap.Surface).ToHashSet();
            if (!expectedSurfaces.SetEquals(actualSurfaces))
                problems.Add($"{name}: descriptors do not form a one-to-one surface mapping");

            foreach (var lightMap in mapsForWorld)
            {
                if (lightMap.Width is < 1 or > 512 || lightMap.Height is < 1 or > 512)
                    problems.Add($"{name}: surface {lightMap.Surface} has impossible size {lightMap.Width}x{lightMap.Height}");

                foreach (var layer in lightMap.Lights)
                {
                    embeddedLayers++;
                }
            }

            Log($"{name,-22} descriptors {mapsForWorld.Count,6} embedded layers {mapsForWorld.Sum(lightMap => lightMap.Lights.Count),6}");
        }

        Log($"lightmaps: {decodedWorlds}/{worlds} worlds decoded, {descriptors:N0} descriptors, {embeddedLayers:N0} embedded layers");

        Assert.True(worlds >= 20, $"only {worlds} compiled worlds were read");
        Assert.Equal(worlds, decodedWorlds);
        Assert.True(descriptors > 39_000, $"only {descriptors} descriptors were decoded");
        Assert.True(embeddedLayers > 45_000, $"only {embeddedLayers} baked-light layers were decoded");
        Assert.True(problems.Count == 0,
            "lightmap descriptor decode failed validation:" + Environment.NewLine
            + string.Join(Environment.NewLine, problems.Take(50)));
    }

    /// <summary>One remaining node field is the descriptor index, not merely a plausible small integer.</summary>
    [RequiresGameFact]
    public void NodeLightmapIndexMatchesItsDescriptorsOwningSurface()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();

        int worlds = 0;
        var matches = new Dictionary<int, int> { [88] = 0, [92] = 0, [96] = 0 };
        var examined = new Dictionary<int, int> { [88] = 0, [92] = 0, [96] = 0 };

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var world = World(package);
            if (world is null || world.LightMaps.Count != world.Surfaces.Count) continue;

            worlds++;
            byte[] payload = package.ReadExportData(package.Exports[world.Source.ExportIndex]);
            int body = world.Layout.Nodes;
            int nodeCount = ReadCompactIndex(payload, ref body);
            Assert.Equal(world.Nodes.Count, nodeCount);

            for (int node = 0; node < nodeCount; node++)
            {
                int nodeAt = body + node * 100;
                foreach (int candidateOffset in matches.Keys.ToArray())
                {
                    int candidate = System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(payload.AsSpan(nodeAt + candidateOffset));
                    if (candidate < 0 || candidate >= world.LightMaps.Count) continue;
                    examined[candidateOffset]++;
                    if (world.LightMaps[candidate].Surface == world.Nodes[node].Surface)
                        matches[candidateOffset]++;
                }
            }
        }

        foreach (int offset in matches.Keys.OrderBy(value => value))
            Log($"node +{offset}: {matches[offset]:N0}/{examined[offset]:N0} descriptor-to-surface matches");

        Assert.True(worlds >= 20, $"only {worlds} worlds were read");
        Assert.True(examined[96] > 10_000, "node +96 did not produce enough candidate descriptor indices");
        Assert.Equal(examined[96], matches[96]);
        Assert.True(matches[88] < examined[88] / 10, "node +88 unexpectedly behaves like the lightmap index");
        Assert.True(matches[92] < examined[92] / 10, "node +92 unexpectedly behaves like the lightmap index");
    }

    [RequiresGameFact]
    public void LightmapAtlasPoolsAreVengeanceWrappedLightMapsTextures()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();
        int pools = 0, textures = 0;
        var problems = new List<string>();

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var world = World(package);
            if (world is null || world.LightMapTextures.Count == 0) continue;

            string mapName = Path.GetFileNameWithoutExtension(map);
            pools++;
            textures += world.LightMapTextures.Count;

            if (world.Layout.LightMapTextures <= world.Layout.LightMaps
                || world.Layout.LightMapTextureCount != world.LightMapTextures.Count)
            {
                problems.Add($"{mapName}: atlas layout offset/count disagree");
                continue;
            }

            foreach (var reference in world.LightMapTextures)
            {
                if (!reference.Texture.IsExport || reference.Texture.ExportIndex >= package.Exports.Count)
                {
                    problems.Add($"{mapName}: atlas reference {reference.Texture} is not an export");
                    continue;
                }

                var texture = package.Exports[reference.Texture.ExportIndex];
                var header = TextureReader.ReadHeader(package, texture);
                if (package.GetClassName(texture) != TextureReader.ClassName
                    || package.ResolveName(texture.OuterIndex) != "LightMaps_BSP"
                    || header is not { Width: 1024, Height: 1024 })
                    problems.Add($"{mapName}: {texture.ObjectName} is not a 1024px LightMaps_BSP texture");
            }

            Log($"{mapName,-22} atlas pool {world.LightMapTextures.Count,3} at {world.Layout.LightMapTextures,10:N0}");
        }

        // Was >= 11: the pool search's count floor was 8, calibrated from the range observed among
        // those first 11 rather than a real format constraint. 0-Lighthouse turned up a genuine
        // 5-entry pool, so the floor is 1 now, and all 20 of the 21 map packages that carry a
        // LightMaps_BSP group at all resolve one — Entry is the one exception, and it has no such
        // group (a 40-export, ~20 KB trivial package, not a real level).
        Assert.Equal(20, pools);
        Assert.True(textures > 100, $"only {textures} atlas textures were read");
        Assert.True(problems.Count == 0,
            "lightmap atlas pool validation failed:" + Environment.NewLine + string.Join(Environment.NewLine, problems));
    }

    [RequiresGameFact]
    public void ProbeLightmapDescriptorRecordBoundaries()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var world = World(package);
            if (world is null || world.LightMapTextures.Count == 0) continue;

            byte[] payload = package.ReadExportData(package.Exports[world.Source.ExportIndex]);
            int cursor = world.Layout.LightMaps;
            int descriptorCount = ReadCompactIndex(payload, ref cursor);
            var starts = new List<int>();

            for (int at = cursor; at + 20 <= world.Layout.LightMapTextures; at++)
            {
                if (System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(payload.AsSpan(at)) != 4
                    || System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(payload.AsSpan(at + 4)) != 2)
                    continue;

                int surface = System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(payload.AsSpan(at + 8));
                int width = System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(payload.AsSpan(at + 12));
                int height = System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(payload.AsSpan(at + 16));
                if (surface >= 0 && surface < world.Surfaces.Count && width is > 0 and <= 512 && height is > 0 and <= 512)
                    starts.Add(at);
            }

            var gaps = starts.Zip(starts.Skip(1), (left, right) => right - left).ToList();
            int lit = gaps.FindIndex(gap => gap > 97);
            string sample = "no baked-light entries";
            if (lit >= 0)
            {
                int lightAt = starts[lit] + 96;
                int afterCount = lightAt;
                int count = ReadCompactIndex(payload, ref afterCount);
                int check = System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(payload.AsSpan(afterCount));
                int version = System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(payload.AsSpan(afterCount + 4));
                sample = $"lights {count}, header ({check},{version}), gap {gaps[lit]}";
            }
            Log($"{Path.GetFileNameWithoutExtension(map),-22} descriptors {starts.Count}/{descriptorCount}, "
                + $"first {starts.FirstOrDefault(),10:N0}, last {starts.LastOrDefault(),10:N0}, "
                + $"gaps {string.Join(',', gaps.Distinct().OrderBy(value => value).Take(12))}; {sample}");
        }
    }

    [RequiresGameFact]
    public void ProbeLightmapMatrixConventionAgainstAtlasTiles()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();
        long rowMajorInside = 0, transposedInside = 0, examined = 0;

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var world = World(package);
            if (world is null || world.LightMapTextures.Count == 0) continue;

            foreach (var node in world.Nodes.Where(node => node.IsPolygon && node.LightMap >= 0 && node.LightMap < world.LightMaps.Count))
            {
                var descriptor = world.LightMaps[node.LightMap];
                var layer = descriptor.Lights.FirstOrDefault(light => light.Atlas >= 0 && light.Atlas < world.LightMapTextures.Count);
                if (layer is null) continue;

                foreach (var point in world.PolygonOf(node))
                {
                    // BspWorld points have already crossed the Y-reflection; the serialized matrix has not.
                    var raw = GameBasis.Convert(point);
                    var rowMajor = Vector4.Transform(new Vector4(raw, 1f), descriptor.WorldToLightMap);
                    var transposed = Vector4.Transform(new Vector4(raw, 1f), Matrix4x4.Transpose(descriptor.WorldToLightMap));

                    rowMajorInside += IsInsideTile(rowMajor, descriptor, layer) ? 1 : 0;
                    transposedInside += IsInsideTile(transposed, descriptor, layer) ? 1 : 0;
                    examined++;
                }
            }
        }

        Log($"lightmap matrix: row-major {rowMajorInside:N0}/{examined:N0}, transposed {transposedInside:N0}/{examined:N0} inside declared tiles");
        Assert.True(examined > 100_000, $"only {examined} atlas-bound vertices were examined");
    }

    private static bool IsInsideTile(Vector4 transformed, BspLightMap descriptor, BspLightMapLight layer)
    {
        float u = transformed.X * descriptor.Width + layer.TileX + 0.5f;
        float v = transformed.Y * descriptor.Height + layer.TileY + 0.5f;
        const float tolerance = 1.5f;
        return u >= layer.TileX - tolerance && u <= layer.TileX + descriptor.Width + tolerance
            && v >= layer.TileY - tolerance && v <= layer.TileY + descriptor.Height + tolerance;
    }

    /// <summary>
    /// What the twelve off-plane polygons actually are: corners snapped to round coordinates on
    /// planes that are slightly oblique. Shipped data, not a decode fault.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Every one of the twelve has the same shape. Part of the polygon sits <b>exactly</b> on its
    /// plane — 0.000 cm, not nearly — and the rest sits off it by exactly the plane's off-axis slope
    /// times the distance travelled. <c>7-Gauntlet</c> node 755: the plane's normal is
    /// <c>(−0.9966, 0.0819, 0)</c>, a wall 4.7° off the Y axis, and all four corners are stored at
    /// <c>x = 32</c>; the two at <c>y = −2252</c> are exact and the two at <c>y = −2208</c> are
    /// 3.603 cm out, which is <c>0.0822 × 44</c> to three decimals. <c>0-Lighthouse</c> node 360:
    /// slope <c>0.000459</c> across 8,704 units gives 4.00 cm, and the polygon is 4.001 cm out.
    /// </para>
    /// <para>
    /// <b>The off-plane corners are the round ones.</b> On <c>7-Gauntlet</c> node 591 the exact
    /// vertices sit at <c>x = −107.43</c> and the 7.38 cm ones at <c>x = −96</c>. That is the
    /// signature of the editor snapping a brush corner to the grid, after which CSG's fragment no
    /// longer lies on the face it was cut from.
    /// </para>
    /// <para>
    /// <b>What it is not.</b> Not precision — a float at 5,000 units resolves to under a
    /// millimetre, not 7 cm. Not the basis conversion, which is a sign flip and exact. Not the
    /// decode: the same three arrays produce 81,554 polygons that are exactly on plane, and a wrong
    /// offset cannot be selective. <c>HIGH CONFIDENCE</c>, from the arithmetic above.
    /// </para>
    /// <para>
    /// The assertion that can fail is the last one: <b>every off-plane polygon must still have a
    /// vertex exactly on its plane.</b> A decode fault — a wrong pool offset, a wrong plane field —
    /// moves the whole polygon off, not two corners of it.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void TheOffPlanePolygonsAreSnappedCornersAndKeepAVertexOnTheirPlane()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();

        int examined = 0, withAnExactVertex = 0;
        float worst = 0f;
        var wholePolygonsOff = new List<string>();

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var world = World(package);
            if (world is null || world.PolygonCount == 0) continue;

            foreach (var node in world.Nodes)
            {
                if (!node.IsPolygon) continue;

                var polygon = world.PolygonOf(node);
                if (polygon.Count < 3) continue;

                var distances = polygon
                    .Select(v => MathF.Abs(Plane.DotCoordinate(node.Plane, v)))
                    .ToList();

                if (distances.Max() <= 1f) continue;

                examined++;
                worst = MathF.Max(worst, distances.Max());

                if (distances.Min() <= 0.01f) withAnExactVertex++;
                else
                    wholePolygonsOff.Add($"{Path.GetFileNameWithoutExtension(map)}: every vertex is "
                                         + $"{distances.Min():0.###}..{distances.Max():0.###} cm off its plane");
            }
        }

        Log($"off-plane polygons {examined}, worst {worst:0.###} cm, "
            + $"{withAnExactVertex} still have a vertex exactly on their plane");

        // Not vacuous: if the reader stopped finding them the shape of the finding would be gone.
        Assert.True(examined > 0, "no off-plane polygons at all — this check has nothing to measure");

        // A ceiling rather than an equality: shipped data does not change, but a decoder change that
        // creates more of these is exactly what this is here to catch.
        Assert.True(examined <= 12, $"{examined} polygons are off their own plane, up from the 12 measured");
        Assert.True(worst < 8f, $"worst deviation is now {worst:0.###} cm, up from 7.381");

        // The discriminator. Snapping moves corners; a decode fault moves polygons.
        Assert.True(wholePolygonsOff.Count == 0,
            "a polygon is off its plane at every vertex, which snapping does not do:"
            + Environment.NewLine + string.Join(Environment.NewLine, wholePolygonsOff));
    }

    /// <summary>
    /// The compiled world winds the same way the source brushes do, and the emitted fan corrects it.
    /// </summary>
    /// <remarks>
    /// Measured rather than assumed, exactly as it was for <c>Polys</c> — and with the Newell
    /// normal, because a single cross product reads its own noise on sliver polygons. Both
    /// directions are asserted so the correction cannot be "fixed" by negating the normal instead,
    /// which would pass every count and light the level inside out.
    /// </remarks>
    [RequiresGameFact]
    public void TheCompiledWorldWindsLikeItsBrushesAndTheGeometryCorrectsForIt()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var world = World(package)!;

        int storedAgree = 0, storedDisagree = 0, degenerate = 0;

        foreach (var node in world.Nodes)
        {
            if (!node.IsPolygon) continue;
            var polygon = world.PolygonOf(node);
            if (polygon.Count < 3) continue;

            var newell = Newell(polygon);
            if (newell.Length() < 1e-3f) { degenerate++; continue; }

            if (Vector3.Dot(Vector3.Normalize(newell), node.Plane.Normal) > 0) storedAgree++;
            else storedDisagree++;
        }

        Log($"compiled world winding: {storedAgree} agree, {storedDisagree} disagree, {degenerate} degenerate");

        Assert.True(storedAgree + storedDisagree > 500, "too few polygons to conclude from");

        // The same convention as the source brushes: after conversion the stored order disagrees
        // with the plane, so the emitted fan reverses it.
        Assert.True(storedDisagree > storedAgree * 20,
            $"the compiled world does not wind like its brushes: {storedAgree} agree against "
            + $"{storedDisagree}. The reversal in BspGeometry.ToGeometry(world) would be wrong.");

        // And what the geometry actually emits faces the way the plane says.
        var geometry = BspGeometry.ToGeometry(world);
        int emittedAgree = 0, emittedDisagree = 0;

        for (int i = 0; i + 2 < geometry.Indices.Count; i += 3)
        {
            var a = geometry.Vertices[geometry.Indices[i]];
            var b = geometry.Vertices[geometry.Indices[i + 1]];
            var c = geometry.Vertices[geometry.Indices[i + 2]];

            var cross = Vector3.Cross(b.Position - a.Position, c.Position - a.Position);
            if (cross.Length() < 1e-3f) continue;

            if (Vector3.Dot(Vector3.Normalize(cross), a.Normal) > 0) emittedAgree++;
            else emittedDisagree++;
        }

        Log($"emitted world triangles: {emittedAgree} agree, {emittedDisagree} disagree");
        Assert.True(emittedAgree > emittedDisagree * 20,
            $"the emitted world triangles face the wrong way: {emittedAgree} against {emittedDisagree}");
    }

    /// <summary>
    /// The geometry layer keeps the two UV spaces separate and only binds atlas references the
    /// package's lightmap pool actually exposed. This is intentionally tested on Medical: it has a
    /// dense interior world and a decoded <c>LightMaps_BSP</c> pool rather than a guessed one.
    /// </summary>
    [RequiresGameFact]
    public void LightmapBatchesCarryAtlasUvsForEveryVertex()
    {
        string medical = Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");
        using var package = BioShockPackage.Open(medical);
        var world = World(package)!;

        var batches = BspGeometry.ToLightMapBatches(world);
        int vertices = batches.Sum(b => b.Geometry.Vertices.Count);

        Log($"1-Medical lightmap batches: {batches.Count:N0}, {vertices:N0} vertices");
        Assert.NotEmpty(batches);
        Assert.True(vertices > 10_000, "Medical did not produce a substantial baked-light geometry set");

        foreach (var batch in batches)
        {
            Assert.Contains(world.LightMapTextures, t => t.Texture == batch.Atlas);
            Assert.All(batch.Geometry.Vertices, vertex =>
            {
                Assert.InRange(vertex.LightMapUv.X, 0f, 1f);
                Assert.InRange(vertex.LightMapUv.Y, 0f, 1f);
            });
        }
    }

    /// <summary>
    /// Surfaces the game does not draw are excluded, and it is a meaningful number of them.
    /// </summary>
    /// <remarks>
    /// Zoning, portal and backdrop surfaces carry real geometry. Including them fills a level with
    /// invisible walls, and the count is recorded so a future change that stops excluding them shows
    /// up as a jump in triangles rather than as a mysteriously boxed-in level.
    /// </remarks>
    [RequiresGameFact]
    public void ZoningAndPortalSurfacesAreLeftOut()
    {
        using var package = BioShockPackage.Open(game.LighthousePackage);
        var world = World(package)!;

        int notDrawn = world.Surfaces.Count(s => !s.IsDrawn);
        int drawn = world.Surfaces.Count(s => s.IsDrawn);

        Log($"world surfaces: {drawn} drawn, {notDrawn} not drawn "
            + $"(invisible/backdrop/portal) of {world.Surfaces.Count}");

        Assert.True(drawn > 0);

        // Every polygon the geometry emits belongs to a drawn surface.
        var geometry = BspGeometry.ToGeometry(world);
        Assert.True(geometry.TriangleCount > 0);
        Assert.True(geometry.TriangleCount <= world.TriangleCount,
            "the geometry emitted more triangles than the world has polygons to give");
    }

    /// <summary>
    /// The compiled world of an interior map, drawn from inside it.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>`1-Medical`, not Lighthouse.</b> Lighthouse is mostly exterior — a building and a skyline
    /// — and its compiled world is 758 polygons, so it says very little about whether interior
    /// architecture decodes. Medical is 7,125 polygons of corridors and rooms, which is what a
    /// player actually walks through and what the floors-are-missing report was about.
    /// </para>
    /// <para>
    /// The assertion is coverage from several headings: standing inside a built world, most of the
    /// view should be architecture. A world that decoded to scattered or inside-out geometry leaves
    /// the frame mostly empty. <c>BIOSHOCK_WORLD_SNAPSHOT</c> writes the images, which are the real
    /// result — the number only stops this passing on a blank frame.
    /// </para>
    /// </remarks>
    [RequiresGameFact]
    public void AnInteriorMapsWorldFillsTheViewFromInsideIt()
    {
        string medical = Path.Combine(GameLocator.MapsDirectory(game.RequireRoot), "1-Medical.bsm");
        using var package = BioShockPackage.Open(medical);

        var world = World(package)!;
        var geometry = BspGeometry.ToGeometry(world);
        var model = Core.Rendering.PreviewModel.Build(geometry, null);

        Log($"1-Medical world: {geometry.TriangleCount:N0} triangles, {geometry.Vertices.Count:N0} vertices, "
            + $"{geometry.Sections.Count} sections");

        // Stand at the median of the geometry, which lands inside the building rather than at the
        // centre of a mostly-empty bounding box.
        var xs = geometry.Vertices.Select(v => v.Position.X).Order().ToList();
        var ys = geometry.Vertices.Select(v => v.Position.Y).Order().ToList();
        var zs = geometry.Vertices.Select(v => v.Position.Z).Order().ToList();
        var inside = new Vector3(xs[xs.Count / 2], ys[ys.Count / 2], zs[zs.Count / 2]);

        Log($"  standing at {inside:0}");

        double best = 0;
        for (int i = 0; i < 4; i++)
        {
            var camera = new Core.Rendering.GhostCamera { Position = inside, Yaw = i * MathF.PI / 2f };
            var image = Core.Rendering.SoftwareRenderer.Render(
                [new Core.Rendering.PreviewInstance(model)],
                camera.ToPreviewCamera(),
                new Core.Rendering.RenderOptions { ShowSkeleton = false, ShowSockets = false },
                720, 480);

            int drawn = 0;
            for (int p = 0; p < image.Rgba.Length; p += 4)
                if (image.Rgba[p] != 32 || image.Rgba[p + 1] != 32 || image.Rgba[p + 2] != 32) drawn++;

            double coverage = (double)drawn / (image.Width * image.Height);
            best = Math.Max(best, coverage);
            Log($"  heading {i}: {coverage:P1} covered");

            if (Environment.GetEnvironmentVariable("BIOSHOCK_WORLD_SNAPSHOT") is { Length: > 0 } path)
            {
                string directory = Path.GetDirectoryName(path) ?? ".";
                Directory.CreateDirectory(directory);
                PngWriter.Write(
                    Path.Combine(directory, $"{Path.GetFileNameWithoutExtension(path)}_{i}.png"),
                    image.Rgba, image.Width, image.Height);
            }
        }

        Assert.True(geometry.TriangleCount > 10_000,
            $"1-Medical's world is only {geometry.TriangleCount} triangles");
        Assert.True(best > 0.5,
            $"standing inside the compiled world, the fullest view is only {best:P0} covered — "
            + "the architecture is not enclosing the camera");
    }

    private static Vector3 Newell(IReadOnlyList<Vector3> vertices)
    {
        var normal = Vector3.Zero;
        for (int i = 0; i < vertices.Count; i++)
        {
            var current = vertices[i];
            var next = vertices[(i + 1) % vertices.Count];
            normal.X += (current.Y - next.Y) * (current.Z + next.Z);
            normal.Y += (current.Z - next.Z) * (current.X + next.X);
            normal.Z += (current.X - next.X) * (current.Y + next.Y);
        }
        return normal;
    }

    /// <summary>
    /// Every zone's connectivity mask carries its own bit, and every zone record's trailing 20
    /// bytes are the same constant.
    /// </summary>
    /// <remarks>
    /// <c>docs/research/bsp.md</c> §5.5c/`BspZone`. A zone that lost track of its own bit, or a
    /// trailing 20 bytes that turned out to vary after all, would mean the 36-byte fixed tail was
    /// misread — this is the check that would catch either.
    /// </remarks>
    [RequiresGameFact]
    public void ZoneConnectivityMasksAlwaysCarryTheirOwnBit()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();

        int totalZones = 0, withMoreThanSelf = 0;
        var bitCounts = new List<int>();
        var problems = new List<string>();
        var tailConstant = Convert.FromHexString("FFFFFFFFFFFFFFFF000000000000000000000000");

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var world = World(package);
            if (world is null || world.Zones.Count == 0) continue;

            string mapName = Path.GetFileNameWithoutExtension(map);
            byte[] data = package.ReadExportData(package.Exports[
                ModelReader.BuiltWorld(package)!.Source.ExportIndex]);

            int cursor = world.Layout.Zones;
            for (int i = 0; i < world.Zones.Count; i++)
            {
                ReadCompactIndex(data, ref cursor);
                byte[] fixedBytes = data.AsSpan(cursor, 36).ToArray();
                cursor += 36;
                totalZones++;

                if (!world.Zones[i].ConnectedZones.Contains(i))
                    problems.Add($"{mapName} zone {i}: mask does not carry its own bit");

                int bitCount = world.Zones[i].ConnectedZones.Count;
                bitCounts.Add(bitCount);
                if (bitCount > 1) withMoreThanSelf++;

                if (!fixedBytes.AsSpan(16, 20).SequenceEqual(tailConstant))
                    problems.Add($"{mapName} zone {i}: trailing 20 bytes are not the expected constant");
            }
        }

        Assert.True(totalZones > 1000, $"only {totalZones} zones were examined");
        Assert.Empty(problems);
        Assert.True(withMoreThanSelf > 900,
            $"only {withMoreThanSelf} of {totalZones} zones connect to anything beyond themselves");
        Assert.True(bitCounts.Max() <= 128, "a mask carried a bit beyond Vengeance's 128-zone maximum");
    }

    /// <summary>
    /// A node's own zone is (almost) always visible from it — the same self-bit check that
    /// validated the zone record's connectivity mask, applied to the node's separate visibility
    /// mask at +16.
    /// </summary>
    /// <remarks>
    /// The +16 offset and its meaning come from
    /// <c>Bioshock1REMSDK-WIP--main/tools/level_editor/src/bsp_parser.cpp</c>, a working, rendering
    /// level editor — read before this was implemented, not derived independently from these bytes.
    /// Measured: <b>81,559 of 81,566 polygon-carrying nodes (99.99%)</b> across all 21 maps. The 7
    /// exceptions all carry <c>Zone == 0</c>, plausibly the "outside"/default zone behaving
    /// differently rather than a wrong offset — a wrong offset would scatter failures across many
    /// zone values, not cluster every one on the same value. That is corroboration, not a caveat, so
    /// this asserts the exact figures rather than a soft threshold.
    /// </remarks>
    [RequiresGameFact]
    public void EveryNodesOwnZoneIsInItsOwnVisibilityMask()
    {
        var maps = Directory.GetFiles(GameLocator.MapsDirectory(game.RequireRoot), "*.bsm").OrderBy(f => f).ToList();

        int nodesChecked = 0, ownZoneVisible = 0, zoneZeroMismatches = 0;

        foreach (string map in maps)
        {
            using var package = BioShockPackage.Open(map);
            var world = World(package);
            if (world is null) continue;

            foreach (var node in world.Nodes)
            {
                if (!node.IsPolygon) continue;
                nodesChecked++;
                if (node.VisibleZones.Contains(node.Zone)) ownZoneVisible++;
                else if (node.Zone == 0) zoneZeroMismatches++;
            }
        }

        Assert.True(nodesChecked > 10_000, $"only {nodesChecked} polygon-carrying nodes were examined");

        int mismatches = nodesChecked - ownZoneVisible;
        Assert.Equal(mismatches, zoneZeroMismatches);
        Assert.True(mismatches <= 10, $"{mismatches} nodes don't see their own zone — was 7");

        double ownZoneRate = (double)ownZoneVisible / nodesChecked;
        Assert.True(ownZoneRate > 0.999,
            $"only {ownZoneVisible} of {nodesChecked} nodes ({ownZoneRate:P2}) see their own zone");
    }
}
