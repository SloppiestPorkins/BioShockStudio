using System.Buffers.Binary;
using System.Numerics;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;

namespace BioShockStudio.Core.Level;

/// <summary>
/// Flags on a BSP surface. Only the ones that decide whether a surface is architecture are named.
/// </summary>
/// <remarks>
/// Values from Unreal's <c>EPolyFlags</c>, and the three that matter here are the ones Nyko's level
/// editor skips when it draws a map. <b>An exporter that ignores them fills the level with invisible
/// walls</b> — zone boundaries, portals and backdrop panes are all real surfaces carrying real
/// geometry that the game never draws.
/// </remarks>
[Flags]
public enum BspSurfaceFlags : uint
{
    None = 0,
    Invisible = 0x00000001,
    Masked = 0x00000002,
    Translucent = 0x00000004,
    TwoSided = 0x00000100,
    FakeBackdrop = 0x00000080,
    Portal = 0x04000000,

    /// <summary>Everything that means "this is not architecture".</summary>
    NotDrawn = Invisible | FakeBackdrop | Portal,
}

/// <summary>One node of the compiled BSP tree, and the polygon it carries.</summary>
public sealed record BspNode
{
    public required Plane Plane { get; init; }

    /// <summary>Index of this node's first entry in the vertex pool.</summary>
    public required int FirstVertex { get; init; }

    /// <summary>How many pool entries the node's polygon uses. Zero for a node that carries none.</summary>
    public required int VertexCount { get; init; }

    /// <summary>The surface this polygon draws with, indexing the model's surface list.</summary>
    public required int Surface { get; init; }

    public required int Front { get; init; }
    public required int Back { get; init; }

    /// <summary>Index into <see cref="BspWorld.LightMaps"/> for this polygon's baked-light descriptor.</summary>
    public required int LightMap { get; init; }

    /// <summary>The zone behind the node's plane. Vengeance allows 128, where stock UE2.5 allows 64.</summary>
    public required byte Zone { get; init; }

    /// <summary>
    /// The zone on this node's other side — <c>iZone[0]</c> at <c>+76</c>, where <see cref="Zone"/>
    /// is <c>iZone[1]</c> at <c>+77</c>.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <c>CONFIRMED_BYTES</c>, 23 Aug 2026, and <b>this corrects the reference</b>. Nyko's SDK notes
    /// label <c>+76</c> as <c>NodeFlags</c> and <c>+79</c> as "iZone[1] / Pad"; the shipped bytes
    /// say the opposite. <c>+76</c> takes <b>121 distinct values</b> across the game — the range of
    /// a zone index, not a flag byte — and is 0 on 78,062 of 81,566 polygon nodes, which is the
    /// "solid / outside" side of an ordinary wall.
    /// </para>
    /// <para>
    /// <b>Together with <see cref="Zone"/> this is portal adjacency, and it cross-validates
    /// perfectly.</b> On the game's 2,386 portal surfaces the pair names two different zones 2,259
    /// times, and <b>every one of those 2,259 pairs is already claimed by both zones' connectivity
    /// masks — 0 disagreements</b>. Those masks were decoded from the zone records, a completely
    /// different part of the file, so the agreement is independent rather than circular.
    /// </para>
    /// </remarks>
    public required byte FrontZone { get; init; }

    /// <summary>
    /// <c>NodeFlags</c> at <c>+79</c> — the byte the reference labels "iZone[1] / Pad".
    /// </summary>
    /// <remarks>
    /// <c>CONFIRMED_BYTES</c> that it is a flag byte and not a zone: only <b>four</b> distinct
    /// values exist across all 81,566 polygon nodes (0, 1, 4, 5), which is a two-bit field rather
    /// than an index. <b>Value 5 marks every portal in the game — all 2,386, no exceptions</b>, and
    /// appears on only 36 non-portal nodes.
    /// <para>
    /// <c>UNKNOWN</c>: what the individual bits are named. The pattern is consistent with UE2's
    /// <c>NF_NotCsg</c> (1) and <c>NF_NotVisBlocking</c> (4) — "not solid geometry, does not block
    /// visibility", which is exactly what a portal is — but no reference available here declares
    /// those constants, so the reading is <c>PLAUSIBLE</c> and the raw byte is what gets stored.
    /// </para>
    /// </remarks>
    public required byte NodeFlags { get; init; }

    /// <summary>True when this node carries a portal surface, by its flags byte.</summary>
    public bool IsPortalNode => NodeFlags == PortalNodeFlags;

    /// <summary>The flags value every portal in the game carries.</summary>
    public const byte PortalNodeFlags = 5;

    /// <summary>
    /// Every zone index visible from this node — the node's own 128-bit mask at <c>+16</c>, per
    /// <c>Bioshock1REMSDK-WIP--main/tools/level_editor/src/bsp_parser.cpp</c> (a working, rendering
    /// level editor's reading, exercised there as a per-node visibility mask, not derived from these
    /// bytes independently). See <see cref="BspZone"/> for the separate per-zone connectivity mask.
    /// </summary>
    public required IReadOnlyList<int> VisibleZones { get; init; }

    public bool IsPolygon => VertexCount >= 3;
}

/// <summary>One BSP leaf: its zone and the two lighting lookup indices the renderer serialises.</summary>
public sealed record BspLeaf
{
    public required int Zone { get; init; }
    public required int Permeating { get; init; }
    public required int Volumetric { get; init; }
}

/// <summary>
/// One BSP zone: its actor, and the zone connectivity mask found in its 36-byte fixed tail.
/// </summary>
/// <remarks>
/// <b>`CONFIRMED_BYTES`.</b> The tail's first 16 bytes are a little-endian 128-bit mask — sized for
/// Vengeance's 128-zone maximum (stock UE2.5 is 64) — where bit <c>N</c> is the zone's own index.
/// Measured across all 1,042 zones in the game: bit <c>N</c> is set for zone <c>N</c> on
/// <b>1,042 of 1,042 (100%)</b>, and the trailing 20 bytes of the tail are the exact constant
/// <c>FFFFFFFFFFFFFFFF000000000000000000000000</c> on every one, with no exceptions. Bits beyond a
/// zone's own are set on 982 of 1,042 zones, and the distribution (1 to 15 bits, average 3.2) is the
/// shape of a real portal-adjacency graph, not noise: most zones connect to a small number of
/// neighbours, a few are hubs. This is <c>ConnectivityBitMask</c> in UE2 terms; whether the game
/// ships a separate <c>VisibilityBitMask</c> (usually a superset, computed by a PVS pre-pass) is
/// `UNKNOWN` — the constant trailing 20 bytes may be it, defaulted/unused, or something else
/// entirely, and asserting which is not supported by evidence yet.
/// </remarks>
public sealed record BspZone
{
    public required PackageIndex Actor { get; init; }

    /// <summary>
    /// Every zone index this zone's mask carries, including its own. Portal-adjacency in UE2 terms.
    /// </summary>
    public required IReadOnlyList<int> ConnectedZones { get; init; }
}

/// <summary>One baked-light layer for a BSP surface, including its atlas tile.</summary>
public sealed record BspLightMapLight
{
    public required IReadOnlyList<PackageIndex> LightActors { get; init; }
    public required int Atlas { get; init; }
    public required int TileX { get; init; }
    public required int TileY { get; init; }
}

/// <summary>The baked-light descriptor belonging to one compiled BSP surface.</summary>
public sealed record BspLightMap
{
    public required int Surface { get; init; }
    public required int Width { get; init; }
    public required int Height { get; init; }

    /// <summary>Raw, row-major game-space matrix. It is deliberately not basis-converted here.</summary>
    public required Matrix4x4 WorldToLightMap { get; init; }
    public required IReadOnlyList<BspLightMapLight> Lights { get; init; }
}

/// <summary>One entry in the UModel lightmap-atlas pool.</summary>
public sealed record BspLightMapTexture
{
    public required PackageIndex Texture { get; init; }
}

/// <summary>One compiled surface: what a run of polygons is painted with, and how.</summary>
public sealed record BspSurface
{
    public required PackageIndex Material { get; init; }
    public required BspSurfaceFlags Flags { get; init; }

    /// <summary>Index into the model's points — the origin of this surface's texture space.</summary>
    public required int Base { get; init; }

    /// <summary>Indices into the model's vectors.</summary>
    public required int Normal { get; init; }
    public required int TextureU { get; init; }
    public required int TextureV { get; init; }

    /// <summary>
    /// <c>iBrushPoly</c>: which polygon of the source brush this surface was cut from.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>`CONFIRMED_BYTES`, and it settles a three-way contest.</b> Nyko's spec §C.1.3 calls the
    /// int32 at +20 <c>iBrushPoly</c>; his own level editor's parser reads the same position as
    /// <c>iLightMap</c> and picks a lightmap atlas with it; his lightmap note puts <c>iLightMap</c>
    /// on the <i>node</i> instead. The spec is right.
    /// </para>
    /// <para>
    /// Measured over <c>0-Lighthouse</c>, <c>1-Medical</c> and <c>3-Arcadia</c>: of 6,662 surfaces,
    /// <b>6,372 resolve to a brush actor and every one of them names a polygon inside that brush's
    /// own polygon list — and the named polygon's normal matches the surface's normal, 6,372 of
    /// 6,372.</b> An unrelated index would agree by chance about a sixth of the time on a box brush.
    /// </para>
    /// <para>
    /// The value range says the same thing from the other side: 0..31 on Lighthouse and 0..9 on
    /// Medical, with ten distinct values across 3,386 surfaces. A lightmap index needs roughly one
    /// value per surface; a brush-polygon index needs one per face of a brush, which is what this is.
    /// So <b>the lightmap index is not here</b>, and the note that puts it on the node is where to
    /// look next. <c>docs/research/bsp.md</c> §5.3.
    /// </para>
    /// </remarks>
    public required int BrushPoly { get; init; }

    /// <summary>
    /// The brush actor CSG built this surface from, as the surface itself names it.
    /// </summary>
    /// <remarks>
    /// Read rather than skipped because it is the only stated link between the compiled world and
    /// the source brushes, and therefore the only ground truth available for how a brush actor's
    /// transform composes: the same polygon exists twice, once in brush space and once in world
    /// space, and the placement rule is whatever maps one onto the other.
    /// <c>BrushPlacementTests</c> is that measurement.
    /// </remarks>
    public required PackageIndex Actor { get; init; }

    public required float LightMapScale { get; init; }

    /// <summary>Whether this surface is architecture rather than a zone, portal or backdrop pane.</summary>
    public bool IsDrawn => (Flags & BspSurfaceFlags.NotDrawn) == 0;
}

/// <summary>
/// Where each of the compiled world's arrays begins in the export payload, and where the decode
/// stopped.
/// </summary>
/// <remarks>
/// <b>The payload does not end where this reader does.</b> On <c>0-Lighthouse</c> the walk consumes
/// 145,712 of 312,400 bytes; what follows is unread, and §5.5 expects the lightmap descriptors to be
/// in it. Reporting the boundary is what lets the next investigation start from a known offset
/// rather than searching for a plausible-looking count — a search that has already produced a false
/// positive on <c>1-Medical</c>.
/// </remarks>
public sealed record BspWorldLayout
{
    public required int Vectors { get; init; }
    public required int Points { get; init; }
    public required int Nodes { get; init; }
    public required int Surfaces { get; init; }
    public required int VertexPool { get; init; }

    /// <summary>The zone array, and how many zones it holds.</summary>
    public required int Zones { get; init; }
    public required int ZoneCount { get; init; }

    /// <summary>
    /// The <c>Bounds</c> array — one <c>FBox</c> per leaf — and where its first element begins.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>This was first named <c>LightMap</c>, and that was wrong.</b> The reasoning was that UE2's
    /// <c>UModel</c> writes <c>Polys</c> after the zones and <c>LightMap</c> after that — inherited
    /// ordering, promoted to a fact without reading the records. Reading them settles it:
    /// <c>Entry</c>'s first record is <c>min(−128,−128,−128) max(128,128,128)</c>, which is a box,
    /// not a lightmap descriptor.
    /// </para>
    /// <para>
    /// <b>Measured over every map: 25,000+ records, and every one is a valid <c>FBox</c></b> — six
    /// floats with <c>min ≤ max</c> on all three axes, in world range, followed by an
    /// <c>IsValid</c> byte that is 1. A 25-byte stride reproduces that on all 21 maps, which a wrong
    /// record size cannot do across arrays of 5 to 2,949 elements.
    /// </para>
    /// <para>
    /// So <b>the lightmap array is further on</b>: <c>LeafHulls</c>, <c>Leaves</c> and <c>Lights</c>
    /// follow, and between 74,712 and 680,357 bytes remain unread after the boxes. §5.5c.
    /// </para>
    /// </remarks>
    public required int BoundCount { get; init; }
    public required int Bounds { get; init; }

    /// <summary>The collision leaf-hull index array, immediately after <see cref="Bounds"/>.</summary>
    public required int LeafHullCount { get; init; }
    public required int LeafHulls { get; init; }

    /// <summary>The 12-byte <c>FLeaf</c> array.</summary>
    public required int LeafCount { get; init; }
    public required int Leaves { get; init; }

    /// <summary>The compact object-reference array for lights.</summary>
    public required int LightCount { get; init; }
    public required int Lights { get; init; }

    /// <summary>An additional compact object-reference array whose semantic purpose remains unknown.</summary>
    public required int OtherReferenceCount { get; init; }
    public required int OtherReferences { get; init; }

    /// <summary>Offsets of the two raw fields just before the rendering data.</summary>
    public required int RootOutside { get; init; }
    public required int Linked { get; init; }

    /// <summary>The first byte of the lightmap/rendering arrays, after the proven structural tail.</summary>
    public required int LightMaps { get; init; }
    public required int LightMapCount { get; init; }
    public required int LightBits { get; init; }
    public required int LightBitCount { get; init; }
    public required int LightMapTextures { get; init; }
    public required int LightMapTextureCount { get; init; }

    /// <summary>One past the last byte this reader consumed.</summary>
    public required int DecodedEnd { get; init; }

    /// <summary>The whole export payload.</summary>
    public required int PayloadLength { get; init; }

    /// <summary>Bytes after the vertex pool that nothing has read.</summary>
    public int Unread => PayloadLength - DecodedEnd;
}

/// <summary>The compiled world: everything needed to draw a level's architecture.</summary>
public sealed record BspWorld
{
    public required SourceId Source { get; init; }

    /// <summary>Texture axes and plane normals, indexed by the surfaces.</summary>
    public required IReadOnlyList<Vector3> Vectors { get; init; }

    /// <summary>The vertex pool's positions, in the studio's basis.</summary>
    public required IReadOnlyList<Vector3> Points { get; init; }

    public required IReadOnlyList<BspNode> Nodes { get; init; }
    public required IReadOnlyList<BspSurface> Surfaces { get; init; }

    /// <summary>The vertex pool: each entry names a point. A node's polygon is a run of these.</summary>
    public required IReadOnlyList<int> VertexPool { get; init; }

    /// <summary>Leaves in the structural UModel tail.</summary>
    public required IReadOnlyList<BspLeaf> Leaves { get; init; }

    /// <summary>Zones and their connectivity, in the package's own order. See <see cref="BspZone"/>.</summary>
    public required IReadOnlyList<BspZone> Zones { get; init; }

    /// <summary>References to the light actors carried by the UModel tail.</summary>
    public required IReadOnlyList<PackageIndex> LightReferences { get; init; }

    /// <summary>One baked-light descriptor per surface, in the package's own order.</summary>
    public required IReadOnlyList<BspLightMap> LightMaps { get; init; }

    /// <summary>The atlas texture pool addressed by <see cref="BspLightMapLight.Atlas"/>.</summary>
    public required IReadOnlyList<BspLightMapTexture> LightMapTextures { get; init; }

    /// <summary>Where each array begins in the payload, and where the decode stopped.</summary>
    /// <remarks>
    /// Kept because the payload does not end where this reader does — the lightmap descriptors are
    /// believed to follow (§5.5) — and locating an array by searching for a plausible count lands on
    /// false positives, which is exactly what a lightmap probe did on <c>1-Medical</c>. A reader that
    /// walked there should say where it got to rather than make the next investigation guess.
    /// </remarks>
    public required BspWorldLayout Layout { get; init; }

    public int PolygonCount => Nodes.Count(n => n.IsPolygon);

    public int TriangleCount => Nodes.Where(n => n.IsPolygon).Sum(n => n.VertexCount - 2);

    /// <summary>The world-space positions of one node's polygon, in stored order.</summary>
    public IReadOnlyList<Vector3> PolygonOf(BspNode node)
    {
        var result = new List<Vector3>(node.VertexCount);

        for (int i = 0; i < node.VertexCount; i++)
        {
            int entry = node.FirstVertex + i;
            if (entry < 0 || entry >= VertexPool.Count) return [];

            int point = VertexPool[entry];
            if (point < 0 || point >= Points.Count) return [];

            result.Add(Points[point]);
        }

        return result;
    }

    /// <summary>
    /// The texel-space texture coordinate of a point on a surface.
    /// </summary>
    /// <remarks>
    /// The same parameterisation a source brush uses — <c>dot(v − Base, TextureU)</c> — except that
    /// the origin and the axes are <i>indices</i> here, into the model's points and vectors, rather
    /// than being stored on the polygon. In texels: the caller divides by the bound texture's size,
    /// exactly as with <see cref="BspGeometry.NormaliseUvs"/>.
    /// </remarks>
    public Vector2 TexelsAt(BspSurface surface, Vector3 point)
    {
        if (surface.Base < 0 || surface.Base >= Points.Count) return Vector2.Zero;
        if (surface.TextureU < 0 || surface.TextureU >= Vectors.Count) return Vector2.Zero;
        if (surface.TextureV < 0 || surface.TextureV >= Vectors.Count) return Vector2.Zero;

        var offset = point - Points[surface.Base];
        return new Vector2(
            Vector3.Dot(offset, Vectors[surface.TextureU]),
            Vector3.Dot(offset, Vectors[surface.TextureV]));
    }

    /// <summary>
    /// Whether a node's polygon vertices actually lie on the node's own plane.
    /// </summary>
    /// <remarks>
    /// <b>This is the check that decides whether the node layout is right</b>, and it is the one
    /// Nyko used to settle <c>NumVertices</c> at +78 against +88 — reading the wrong field gives 64%
    /// planarity failures and a maximum distance of 37,618, reading the right one gives 0 of 7,125
    /// failures. A wrong offset cannot produce coplanar polygons by accident.
    /// </remarks>
    public (float Worst, int PolygonsOffPlane, int PolygonsChecked) Planarity(float tolerance = 1f)
    {
        float worst = 0f;
        int off = 0, checkedCount = 0;

        foreach (var node in Nodes)
        {
            if (!node.IsPolygon) continue;

            float furthest = 0f;
            bool usable = true;

            for (int i = 0; i < node.VertexCount; i++)
            {
                int entry = node.FirstVertex + i;
                if (entry < 0 || entry >= VertexPool.Count) { usable = false; break; }

                int point = VertexPool[entry];
                if (point < 0 || point >= Points.Count) { usable = false; break; }

                furthest = MathF.Max(furthest, MathF.Abs(Plane.DotCoordinate(node.Plane, Points[point])));
            }

            if (!usable) continue;

            checkedCount++;
            worst = MathF.Max(worst, furthest);
            if (furthest > tolerance) off++;
        }

        return (worst, off, checkedCount);
    }

    /// <summary>Builds the atlas UV for one vertex and one baked-light layer.</summary>
    /// <remarks>
    /// The stored matrix is in game space while <paramref name="position"/> is in the studio
    /// basis, so the Y reflection is reversed before multiplying. The matrix is consumed row-major:
    /// on the eleven maps exposing atlas pools, this places <b>234,404 of 234,404</b> checked
    /// polygon vertices inside their descriptor's declared tile; transposing it places only 1,096
    /// inside. The half-texel term addresses texel centres, not edges.
    /// </remarks>
    public Vector2 LightMapUv(BspNode node, Vector3 position, BspLightMapLight layer)
    {
        if (node.LightMap < 0 || node.LightMap >= LightMaps.Count) return Vector2.Zero;

        var descriptor = LightMaps[node.LightMap];
        Vector3 rawPosition = GameBasis.Convert(position);
        Vector4 projected = Vector4.Transform(new Vector4(rawPosition, 1f), descriptor.WorldToLightMap);
        return new Vector2(
            (projected.X * descriptor.Width + layer.TileX + 0.5f) / 1024f,
            (projected.Y * descriptor.Height + layer.TileY + 0.5f) / 1024f);
    }
}

/// <summary>
/// Reads the compiled world out of a <c>Model</c> export.
/// </summary>
/// <remarks>
/// <para>
/// <b>Status: <c>CONFIRMED_BYTES</c>.</b> The layout is Nyko's §C.1.1–§C.1.4 (see
/// <c>docs/research/bsp.md</c> §5), cross-checked against his level editor's own parser, which
/// renders it. What makes this a decode rather than a transcription is the <b>planarity</b> check:
/// every polygon's vertices must lie on its node's own plane, which is three independent arrays —
/// nodes, the vertex pool, and the points — having to agree.
/// </para>
/// <para>
/// <b>The landmine is <c>NumVertices</c>.</b> It is a <i>byte at +78</i>, not the int32 at +88 that
/// an initial reading suggests. Nyko settled it by scoring all 68 candidate byte offsets on
/// planarity across 800 nodes; +78 scores 100%. <b>So does +97</b> — noted here because the score
/// alone does not choose between them, and the field layout is what does.
/// </para>
/// </remarks>
public static class BspWorldReader
{
    private const int NodeStride = 100;
    private const int VengeanceCheck = 4;

    /// <summary>
    /// Reads the compiled world, or null when the export carries no body.
    /// </summary>
    /// <remarks>
    /// Every source brush is also a <c>Model</c> with its own small tree, so this reads whatever it
    /// is given; <see cref="ModelReader.BuiltWorld"/> is what picks the level's own out of a package.
    /// </remarks>
    public static BspWorld? Read(BioShockPackage package, ObjectExport export)
    {
        byte[] data = package.ReadExportData(export);
        string packageName = Path.GetFileNameWithoutExtension(package.FilePath);
        var source = new SourceId(packageName, export.Index, package.GetClassName(export), export.ObjectName);

        UnrealPropertyReader.Read(data, package.Names, out int offset);
        offset += 25 + 16;                                                  // UPrimitive: FBox + FSphere

        if (offset + 8 > data.Length) return null;
        if (BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset)) != VengeanceCheck)
            throw new InvalidDataException($"{source}: the Vengeance class header is not where it should be.");
        offset += 8;

        int vectorsAt = offset;
        var vectors = ReadVectors(data, ref offset, source, "Vectors");
        int pointsAt = offset;
        var points = ReadVectors(data, ref offset, source, "Points");
        int nodesAt = offset;
        var nodes = ReadNodes(data, ref offset, source);
        int surfacesAt = offset;
        var surfaces = ReadSurfaces(data, ref offset, source);
        int poolAt = offset;
        var pool = ReadVertexPool(data, ref offset, source);

        // Past the arrays this reader decodes, UE2's UModel writes NumSharedSides, NumZones, the
        // zones, the Polys reference and then the LightMap array. None of that is interpreted here —
        // the walk exists so the lightmap descriptors can be found without searching for them, which
        // has already produced a false positive once. See BspWorldLayout.
        int zonesAt = 0, zoneCount = 0, boundsAt = 0, boundCount = 0;
        int leafHullsAt = 0, leafHullCount = 0, leavesAt = 0, leafCount = 0;
        int lightsAt = 0, lightCount = 0, otherReferencesAt = 0, otherReferenceCount = 0;
        int rootOutsideAt = 0, linkedAt = 0, lightMapsAt = 0;
        int lightMapCount = 0, lightBitsAt = 0, lightBitCount = 0, lightMapTexturesAt = 0, lightMapTextureCount = 0;
        IReadOnlyList<BspLeaf> leaves = [];
        IReadOnlyList<BspZone> zones = [];
        IReadOnlyList<PackageIndex> lightReferences = [];
        IReadOnlyList<BspLightMap> lightMaps = [];
        IReadOnlyList<BspLightMapTexture> lightMapTextures = [];

        if (offset + 8 <= data.Length)
        {
            zoneCount = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset + 4));
            zonesAt = offset + 8;

            var parsedZones = new List<BspZone>(zoneCount >= 0 ? zoneCount : 0);

            if (zoneCount >= 0 && zoneCount <= 256)
            {
                int cursor = zonesAt;
                bool walked = true;

                // A zone is an FCompactIndex actor reference followed by 36 fixed bytes: a 128-bit
                // little-endian connectivity mask (bit N always set for zone N itself, plus a bit
                // per connected zone — CONFIRMED_BYTES over all 1,042 zones in the game, see
                // BspZone), then a constant, unvarying 20 bytes. Measured: walking this lands on the
                // Polys reference on 21 of 21 maps.
                for (int i = 0; i < zoneCount && walked; i++)
                {
                    int actorReference = PropertyValues.ReadCompactIndex(data, ref cursor);
                    if (cursor + 36 > data.Length) { walked = false; break; }

                    ulong low = BinaryPrimitives.ReadUInt64LittleEndian(data.AsSpan(cursor));
                    ulong high = BinaryPrimitives.ReadUInt64LittleEndian(data.AsSpan(cursor + 8));
                    cursor += 36;

                    var connected = new List<int>();
                    for (int bit = 0; bit < 64; bit++)
                        if ((low & (1UL << bit)) != 0) connected.Add(bit);
                    for (int bit = 0; bit < 64; bit++)
                        if ((high & (1UL << bit)) != 0) connected.Add(64 + bit);

                    parsedZones.Add(new BspZone
                    {
                        Actor = new PackageIndex(actorReference),
                        ConnectedZones = connected,
                    });
                }

                if (walked) zones = parsedZones;

                if (walked && cursor + 2 <= data.Length)
                {
                    PropertyValues.ReadCompactIndex(data, ref cursor);          // Polys
                    boundCount = PropertyValues.ReadCompactIndex(data, ref cursor);
                    boundsAt = cursor;

                    if (boundCount >= 0 && (long)boundCount * 25 <= data.Length - cursor)
                    {
                        cursor += boundCount * 25;                               // FBox: six floats + IsValid
                        leafHullCount = PropertyValues.ReadCompactIndex(data, ref cursor);
                        leafHullsAt = cursor;

                        if (leafHullCount >= 0 && (long)leafHullCount * 4 <= data.Length - cursor)
                        {
                            cursor += leafHullCount * 4;
                            leafCount = PropertyValues.ReadCompactIndex(data, ref cursor);
                            leavesAt = cursor;

                            if (leafCount >= 0 && (long)leafCount * 12 <= data.Length - cursor)
                            {
                                var parsedLeaves = new List<BspLeaf>(leafCount);
                                for (int i = 0; i < leafCount; i++)
                                {
                                    parsedLeaves.Add(new BspLeaf
                                    {
                                        Zone = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor)),
                                        Permeating = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor + 4)),
                                        Volumetric = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor + 8)),
                                    });
                                    cursor += 12;
                                }

                                lightCount = PropertyValues.ReadCompactIndex(data, ref cursor);
                                lightsAt = cursor;
                                if (lightCount >= 0 && lightCount <= data.Length - cursor)
                                {
                                    var parsedLights = new List<PackageIndex>(lightCount);
                                    for (int i = 0; i < lightCount; i++)
                                        parsedLights.Add(new PackageIndex(PropertyValues.ReadCompactIndex(data, ref cursor)));

                                    otherReferenceCount = PropertyValues.ReadCompactIndex(data, ref cursor);
                                    otherReferencesAt = cursor;
                                    if (otherReferenceCount >= 0 && otherReferenceCount <= data.Length - cursor)
                                    {
                                        for (int i = 0; i < otherReferenceCount; i++)
                                            PropertyValues.ReadCompactIndex(data, ref cursor);

                                        if (cursor + 8 <= data.Length)
                                        {
                                            rootOutsideAt = cursor;
                                            linkedAt = cursor + 4;
                                            lightMapsAt = cursor + 8;
                                            leaves = parsedLeaves;
                                            lightReferences = parsedLights;

                                            if (TryReadLightMaps(data, lightMapsAt, surfaces.Count, out var parsedLightMaps,
                                                    out lightMapCount, out lightBitsAt, out lightBitCount,
                                                    out lightMapTexturesAt, out lightMapTextureCount,
                                                    out var parsedLightMapTextures))
                                            {
                                                lightMaps = parsedLightMaps;
                                                lightMapTextures = parsedLightMapTextures;
                                            }

                                            // The Remastered tail has a second descriptor variant whose variable
                                            // light entries are not established yet. Its atlas pool is still
                                            // independently identifiable: a Vengeance v1 array of local Texture
                                            // exports, all in the package-declared LightMaps_BSP group. Taking the
                                            // first such array after the descriptor boundary rejects overlapping
                                            // false starts inside its own compact references.
                                            if (TryFindLightMapTexturePool(package, data, lightMapsAt,
                                                    out int atlasAt, out int atlasCount, out var atlasTextures))
                                            {
                                                lightMapTexturesAt = atlasAt;
                                                lightMapTextureCount = atlasCount;
                                                lightMapTextures = atlasTextures;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }


        return new BspWorld
        {
            Source = source,
            Vectors = vectors,
            Points = points,
            Nodes = nodes,
            Surfaces = surfaces,
            VertexPool = pool,
            Leaves = leaves,
            Zones = zones,
            LightReferences = lightReferences,
            LightMaps = lightMaps,
            LightMapTextures = lightMapTextures,
            Layout = new BspWorldLayout
            {
                Vectors = vectorsAt,
                Points = pointsAt,
                Nodes = nodesAt,
                Surfaces = surfacesAt,
                VertexPool = poolAt,
                Zones = zonesAt,
                ZoneCount = zoneCount,
                BoundCount = boundCount,
                Bounds = boundsAt,
                LeafHullCount = leafHullCount,
                LeafHulls = leafHullsAt,
                LeafCount = leafCount,
                Leaves = leavesAt,
                LightCount = lightCount,
                Lights = lightsAt,
                OtherReferenceCount = otherReferenceCount,
                OtherReferences = otherReferencesAt,
                RootOutside = rootOutsideAt,
                Linked = linkedAt,
                LightMaps = lightMapsAt,
                LightMapCount = lightMapCount,
                LightBits = lightBitsAt,
                LightBitCount = lightBitCount,
                LightMapTextures = lightMapTexturesAt,
                LightMapTextureCount = lightMapTextureCount,
                DecodedEnd = offset,
                PayloadLength = data.Length,
            },
        };
    }

    private static bool TryReadLightMaps(
        byte[] data,
        int offset,
        int surfaceCount,
        out IReadOnlyList<BspLightMap> lightMaps,
        out int lightMapCount,
        out int lightBitsAt,
        out int lightBitCount,
        out int texturesAt,
        out int textureCount,
        out IReadOnlyList<BspLightMapTexture> textures)
    {
        lightMaps = [];
        lightMapCount = 0;
        lightBitsAt = 0;
        lightBitCount = 0;
        texturesAt = 0;
        textureCount = 0;
        textures = [];

        try
        {
            int cursor = offset;
            int count = PropertyValues.ReadCompactIndex(data, ref cursor);
            if (count != surfaceCount || count < 0) return false;

            var result = new List<BspLightMap>(count);
            for (int i = 0; i < count; i++)
            {
                if (cursor + 96 > data.Length
                    || BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor)) != VengeanceCheck)
                    return false;
                cursor += 8;

                int surface = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor));
                int width = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor + 4));
                int height = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor + 8));
                if (surface < 0 || surface >= surfaceCount || width < 1 || height < 1) return false;
                cursor += 12;

                var matrix = new Matrix4x4(
                    BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor)), BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor + 4)), BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor + 8)), BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor + 12)),
                    BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor + 16)), BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor + 20)), BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor + 24)), BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor + 28)),
                    BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor + 32)), BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor + 36)), BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor + 40)), BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor + 44)),
                    BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor + 48)), BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor + 52)), BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor + 56)), BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(cursor + 60)));
                cursor += 64 + 12; // matrix, then Pan/UVBias fields not used by the renderer path yet

                int bakedLightCount = PropertyValues.ReadCompactIndex(data, ref cursor);
                if (bakedLightCount < 0 || bakedLightCount > 4_096) return false;
                var bakedLights = new List<BspLightMapLight>(bakedLightCount);
                for (int light = 0; light < bakedLightCount; light++)
                {
                    if (cursor + 8 > data.Length
                        || BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor)) != VengeanceCheck)
                        return false;
                    cursor += 8;

                    var actors = new PackageIndex[3];
                    for (int actor = 0; actor < actors.Length; actor++)
                        actors[actor] = new PackageIndex(PropertyValues.ReadCompactIndex(data, ref cursor));

                    if (cursor + 12 > data.Length) return false;
                    bakedLights.Add(new BspLightMapLight
                    {
                        LightActors = actors,
                        Atlas = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor)),
                        TileX = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor + 4)),
                        TileY = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor + 8)),
                    });
                    cursor += 12;
                }

                result.Add(new BspLightMap
                {
                    Surface = surface,
                    Width = width,
                    Height = height,
                    WorldToLightMap = matrix,
                    Lights = bakedLights,
                });
            }

            // The descriptor records are fully bounded by their own headers and compact counts.
            // Preserve them even when the rendering arrays that follow use a different Remastered
            // layout: tying both claims together previously discarded valid descriptors on ten maps.
            lightMaps = result;
            lightMapCount = count;
            lightBitsAt = cursor;

            try
            {
                lightBitCount = PropertyValues.ReadCompactIndex(data, ref cursor);
                if (lightBitCount < 0 || lightBitCount > data.Length - cursor) return true;
                cursor += lightBitCount;

                textureCount = PropertyValues.ReadCompactIndex(data, ref cursor);
                texturesAt = cursor;
                if (textureCount < 0 || textureCount > 256) return true;
                var textureResult = new List<BspLightMapTexture>(textureCount);
                for (int i = 0; i < textureCount; i++)
                {
                    if (cursor + 8 > data.Length
                        || BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor)) != VengeanceCheck)
                        return true;
                    cursor += 8;
                    textureResult.Add(new BspLightMapTexture
                    {
                        Texture = new PackageIndex(PropertyValues.ReadCompactIndex(data, ref cursor)),
                    });
                }

                textures = textureResult;
            }
            catch (IndexOutOfRangeException) { return true; }
            catch (InvalidDataException) { return true; }
            return true;
        }
        catch (IndexOutOfRangeException) { return false; }
        catch (InvalidDataException) { return false; }
    }

    private static bool TryFindLightMapTexturePool(
        BioShockPackage package,
        byte[] data,
        int start,
        out int poolAt,
        out int poolCount,
        out IReadOnlyList<BspLightMapTexture> textures)
    {
        poolAt = 0;
        poolCount = 0;
        textures = [];

        for (int candidateAt = start; candidateAt + 10 < data.Length; candidateAt++)
        {
            // Atlas pools are small enough to use the one-byte compact form. Starting on a later
            // reference inside a real pool creates a plausible overlapping sequence, so accepting
            // the first complete, independently validated one is significant. The lower bound was
            // 8 (the smallest observed among the first 11 proven maps) until 0-Lighthouse turned up
            // a genuine 5-entry LightMaps_BSP pool — that was the range of what had been checked,
            // not a format constraint, so it is 1 here instead.
            if (data[candidateAt] is < 1 or > 63) continue;

            try
            {
                int cursor = candidateAt;
                int count = PropertyValues.ReadCompactIndex(data, ref cursor);
                if (count is < 1 or > 64 || cursor + 9 > data.Length) continue;

                if (BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor)) != VengeanceCheck
                    || BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor + 4)) != 1)
                    continue;

                var result = new List<BspLightMapTexture>(count);
                bool valid = true;
                for (int i = 0; i < count; i++)
                {
                    if (cursor + 9 > data.Length
                        || BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor)) != VengeanceCheck
                        || BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(cursor + 4)) != 1)
                    {
                        valid = false;
                        break;
                    }

                    cursor += 8;
                    int reference = PropertyValues.ReadCompactIndex(data, ref cursor);
                    if (reference <= 0 || reference > package.Exports.Count)
                    {
                        valid = false;
                        break;
                    }

                    var texture = package.Exports[reference - 1];
                    if (package.GetClassName(texture) != TextureReader.ClassName
                        || package.ResolveName(texture.OuterIndex) != "LightMaps_BSP")
                    {
                        valid = false;
                        break;
                    }

                    result.Add(new BspLightMapTexture { Texture = new PackageIndex(reference) });
                }

                if (!valid || result.Count != count) continue;

                poolAt = candidateAt;
                poolCount = count;
                textures = result;
                return true;
            }
            catch (IndexOutOfRangeException) { }
            catch (InvalidDataException) { }
        }

        return false;
    }

    /// <summary>
    /// Reads a <c>TArray&lt;FVector&gt;</c>, converting to the studio's basis.
    /// </summary>
    /// <remarks>
    /// <b>Both arrays convert, and that is not obviously right for <c>Vectors</c>.</b> It holds plane
    /// normals and texture axes rather than positions — but a normal converts by the same map as a
    /// position under this basis (<c>C</c> is diagonal, orthogonal and symmetric, so
    /// <c>(C⁻¹)ᵀ = C</c>), and a texture axis is a direction in the same space. See
    /// <c>ANIMATION_COORDINATE_SYSTEM.md</c> §7.
    /// </remarks>
    private static List<Vector3> ReadVectors(byte[] data, ref int offset, SourceId source, string what)
    {
        int count = PropertyValues.ReadCompactIndex(data, ref offset);
        if (count < 0 || (long)count * 12 > data.Length - offset)
            throw new InvalidDataException($"{source}: {what} declares {count} vectors, which does not fit.");

        var result = new List<Vector3>(count);
        for (int i = 0; i < count; i++)
        {
            result.Add(GameBasis.Convert(new Vector3(
                BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(offset)),
                BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(offset + 4)),
                BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(offset + 8)))));
            offset += 12;
        }

        return result;
    }

    private static List<BspNode> ReadNodes(byte[] data, ref int offset, SourceId source)
    {
        int count = PropertyValues.ReadCompactIndex(data, ref offset);
        if (count < 0 || (long)count * NodeStride > data.Length - offset)
            throw new InvalidDataException($"{source}: {count} nodes of {NodeStride} bytes does not fit.");

        var result = new List<BspNode>(count);

        for (int i = 0; i < count; i++)
        {
            int at = offset + i * NodeStride;

            // The plane's normal is a direction and converts like one; its distance term is a length
            // along that normal and is untouched by a reflection.
            var normal = GameBasis.Convert(new Vector3(
                BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(at)),
                BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(at + 4)),
                BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(at + 8))));
            float distance = BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(at + 12));

            // +16: a 128-bit visible-zone mask, per the reference above. Read the same way as the
            // zone record's own connectivity mask (BspZone), as two ulongs.
            ulong visibleLow = BinaryPrimitives.ReadUInt64LittleEndian(data.AsSpan(at + 16));
            ulong visibleHigh = BinaryPrimitives.ReadUInt64LittleEndian(data.AsSpan(at + 24));
            var visibleZones = new List<int>();
            for (int bit = 0; bit < 64; bit++)
                if ((visibleLow & (1UL << bit)) != 0) visibleZones.Add(bit);
            for (int bit = 0; bit < 64; bit++)
                if ((visibleHigh & (1UL << bit)) != 0) visibleZones.Add(64 + bit);

            result.Add(new BspNode
            {
                // Unreal stores the plane as normal plus a POSITIVE distance along it, so the plane
                // equation is dot(n, p) = w — hence the negated D for System.Numerics, which uses
                // dot(n, p) + D = 0. Getting this sign wrong makes every planarity check fail by
                // twice the distance from the origin, which looks like a decode fault and is not.
                Plane = new Plane(normal, -distance),
                FirstVertex = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(at + 32)),
                Surface = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(at + 36)),
                Back = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(at + 40)),
                Front = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(at + 44)),
                LightMap = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(at + 96)),
                Zone = data[at + 77],
                FrontZone = data[at + 76],
                NodeFlags = data[at + 79],
                VertexCount = data[at + 78],      // A BYTE at +78. See the class remarks.
                VisibleZones = visibleZones,
            });
        }

        offset += count * NodeStride;
        return result;
    }

    private static List<BspSurface> ReadSurfaces(byte[] data, ref int offset, SourceId source)
    {
        int count = PropertyValues.ReadCompactIndex(data, ref offset);
        if (count < 0 || count > data.Length)
            throw new InvalidDataException($"{source}: {count} surfaces is impossible in {data.Length} bytes.");

        var result = new List<BspSurface>(count);

        for (int i = 0; i < count; i++)
        {
            offset += 8;                                                     // per-element Vengeance header
            var material = new PackageIndex(PropertyValues.ReadCompactIndex(data, ref offset));

            if (offset + 24 > data.Length)
                throw new InvalidDataException($"{source}: surface {i} of {count} ran past the payload.");

            var flags = (BspSurfaceFlags)BinaryPrimitives.ReadUInt32LittleEndian(data.AsSpan(offset));
            int basePoint = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset + 4));
            int normal = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset + 8));
            int textureU = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset + 12));
            int textureV = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset + 16));
            int brushPoly = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset + 20));
            offset += 24;

            var actor = new PackageIndex(PropertyValues.ReadCompactIndex(data, ref offset));

            if (offset + 20 > data.Length)
                throw new InvalidDataException($"{source}: surface {i} of {count} ran past the payload.");

            float lightMapScale = BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(offset + 16));
            offset += 20;                                                    // FPlane + LightMapScale

            result.Add(new BspSurface
            {
                Material = material,
                Flags = flags,
                Base = basePoint,
                Normal = normal,
                TextureU = textureU,
                TextureV = textureV,
                BrushPoly = brushPoly,
                Actor = actor,
                LightMapScale = lightMapScale,
            });
        }

        return result;
    }

    /// <summary>
    /// The vertex pool. Each entry is <c>pVertex</c> plus <c>iSide</c>, both <b>raw int32</b> —
    /// stock UE2.5 uses an <c>FCompactIndex</c> for each and BioShock does not.
    /// </summary>
    private static List<int> ReadVertexPool(byte[] data, ref int offset, SourceId source)
    {
        int count = PropertyValues.ReadCompactIndex(data, ref offset);
        if (count < 0 || (long)count * 8 > data.Length - offset)
            throw new InvalidDataException($"{source}: {count} pool entries of 8 bytes does not fit.");

        var result = new List<int>(count);
        for (int i = 0; i < count; i++)
        {
            result.Add(BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset)));
            offset += 8;                                                     // pVertex, then iSide
        }

        return result;
    }
}
