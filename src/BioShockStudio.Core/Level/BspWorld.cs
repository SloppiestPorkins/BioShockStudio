using System.Buffers.Binary;
using System.Numerics;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Packages;

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

    /// <summary>The zone behind the node's plane. Vengeance allows 128, where stock UE2.5 allows 64.</summary>
    public required byte Zone { get; init; }

    public bool IsPolygon => VertexCount >= 3;
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

        var vectors = ReadVectors(data, ref offset, source, "Vectors");
        var points = ReadVectors(data, ref offset, source, "Points");
        var nodes = ReadNodes(data, ref offset, source);
        var surfaces = ReadSurfaces(data, ref offset, source);
        var pool = ReadVertexPool(data, ref offset, source);

        return new BspWorld
        {
            Source = source,
            Vectors = vectors,
            Points = points,
            Nodes = nodes,
            Surfaces = surfaces,
            VertexPool = pool,
        };
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
                Zone = data[at + 77],
                VertexCount = data[at + 78],      // A BYTE at +78. See the class remarks.
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
