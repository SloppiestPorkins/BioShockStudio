using System.Buffers.Binary;
using System.Numerics;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Level;

/// <summary>
/// One convex polygon of a BSP brush — Unreal's <c>FPoly</c>.
/// </summary>
/// <remarks>
/// Positions and axes are in the <b>studio's</b> basis: the reader converts once, at the decode
/// boundary, exactly as the mesh and skeleton readers do. See
/// <c>docs/research/ANIMATION_COORDINATE_SYSTEM.md</c> — nothing downstream may convert again.
/// </remarks>
public sealed record BspPolygon
{
    /// <summary>A point on the polygon's plane, and the origin of its texture parameterisation.</summary>
    public required Vector3 Base { get; init; }

    /// <summary>The plane's outward normal.</summary>
    public required Vector3 Normal { get; init; }

    /// <summary>The texture space's U axis. Zero on a polygon that carries no parameterisation.</summary>
    public required Vector3 TextureU { get; init; }

    /// <summary>The texture space's V axis.</summary>
    public required Vector3 TextureV { get; init; }

    /// <summary>The polygon's vertices, in winding order.</summary>
    public required IReadOnlyList<Vector3> Vertices { get; init; }

    public required uint PolyFlags { get; init; }

    /// <summary>
    /// The actor this polygon belongs to. <b>Null in all 93,264 shipped polygons</b> across the
    /// game's 21 map packages, which is what leaves the field's position settled by arithmetic
    /// rather than by a decoded value.
    /// </summary>
    public required PackageIndex Actor { get; init; }

    /// <summary>
    /// The surface this polygon draws with. Set on <b>59,495 of 93,264</b> shipped polygons, and
    /// every one of them resolves to a material class — so a brush is textured, not bare geometry.
    /// </summary>
    public required PackageIndex Material { get; init; }

    /// <summary>The polygon's <c>ItemName</c>, resolved against the package's name table.</summary>
    public required string ItemName { get; init; }

    /// <summary>The surface this polygon links to. Counts from zero within a brush in shipped data.</summary>
    public required int Link { get; init; }

    /// <summary>The index of the polygon in its source brush. <c>-1</c> in shipped data.</summary>
    public required int BrushPoly { get; init; }

    public required float LightMapScale { get; init; }

    /// <summary>
    /// The polygon triangulated as a fan, <b>wound to agree with <see cref="Normal"/></b>. A fan is
    /// valid here because an <c>FPoly</c> is convex by construction — the editor splits any polygon
    /// that is not.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>The fan is emitted in reverse of the shipped vertex order, and that is a measured
    /// divergence from the mesh containers rather than a preference.</b>
    /// <c>docs/research/ANIMATION_COORDINATE_SYSTEM.md</c> §6 establishes that the game's *meshes*
    /// are front-face clockwise — their geometric normal points against their shipped normal — so
    /// the basis reflection alone brings them into agreement and the index buffer must be left
    /// alone. BSP does the opposite: taken in shipped order, a converted brush polygon's geometric
    /// normal disagrees with its own stored normal on <b>93,264 of 93,264</b> shipped polygons,
    /// unanimously. Since the reflection negates that agreement (§6's derivation), the game's own
    /// BSP data <i>agrees</i> — counter-clockwise front-facing, the opposite convention from its
    /// meshes.
    /// </para>
    /// <para>
    /// So the reversal here restores exactly what the mesh path gets for free, and both end up
    /// counter-clockwise front-facing as FBX, Blender and glTF expect. <b>The shipped order is not
    /// altered</b> — <see cref="Vertices"/> is what the package holds; only this projection of it is
    /// wound. <c>BspGeometryTests</c> pins both halves: that the shipped order disagrees, and that
    /// what this emits agrees. Reversing the reasoning and "fixing" it by negating the normal would
    /// pass every count and light the level inside out.
    /// </para>
    /// </remarks>
    public IEnumerable<(Vector3 A, Vector3 B, Vector3 C)> Triangles()
    {
        foreach (var (a, b, c) in TriangleIndices())
            yield return (Vertices[a], Vertices[b], Vertices[c]);
    }

    /// <summary>
    /// The same fan as <see cref="Triangles"/>, as indices into <see cref="Vertices"/>.
    /// </summary>
    /// <remarks>
    /// This is the single place the winding correction lives. A consumer building an index buffer
    /// must go through it rather than re-deriving a fan of its own, or it silently undoes the
    /// correction that <see cref="Triangles"/> documents and the level comes out inside out.
    /// </remarks>
    public IEnumerable<(int A, int B, int C)> TriangleIndices()
    {
        for (int i = Vertices.Count - 1; i - 1 > 0; i--)
            yield return (0, i, i - 1);
    }
}

/// <summary>Everything one <c>Polys</c> export holds.</summary>
public sealed record BspPolys
{
    public required SourceId Source { get; init; }

    /// <summary>The <c>Model</c> this belongs to, from the export table's outer link.</summary>
    public required SourceId? Model { get; init; }

    public required IReadOnlyList<BspPolygon> Polygons { get; init; }

    /// <summary>
    /// The <c>Max</c> the container declares beside its count. Preserved rather than dropped: it is
    /// the array's capacity, and a value that differs from the count would be worth knowing about.
    /// </summary>
    public required int DeclaredMax { get; init; }

    public int VertexCount => Polygons.Sum(p => p.Vertices.Count);
}

/// <summary>
/// Reads a <c>Polys</c> export — the polygon soup of one BSP brush.
/// </summary>
/// <remarks>
/// <para>
/// <b>Status: <c>CONFIRMED_BYTES</c>.</b> The layout below came from
/// <c>Unreal-Library-master</c>'s <c>UPolys.cs</c> and <c>Poly.cs</c> — the first finding taken from
/// the one reference project the handoff listed as entirely unmined — with every version gate
/// resolved against this game's own file version, <b>142</b>. It was then corrected against shipped
/// bytes in exactly one place, and that correction is the interesting part: see below.
/// </para>
/// <code>
/// UPolys:  [Vengeance object header + property list]
///          int32 num
///          int32 max
///          FPoly[num]
///
/// FPoly:   FCompactIndex numVertices      // version &lt; 227 stores a count, not an array
///          FVector Base, Normal, TextureU, TextureV
///          FVector Vertex[numVertices]
///          uint32  PolyFlags
///          index   Actor
///          index   Material               // version &lt; 170: the slot UELib calls Texture
///          FName   ItemName               // index + int32 number
///          index   Link
///          index   BrushPoly
///          float   LightMapScale          // version >= 106 and &lt; 300
/// </code>
/// <para>
/// <b>The one divergence from UELib, and it is this game's own convention:</b> <c>ItemName</c> is an
/// <c>FCompactIndex</c> <i>plus a four-byte number</i>, not a bare index. UELib's
/// <c>ReadNameReference</c> reads the number for the branches that have one; this game writes it
/// here. It is the same shape <see cref="PropertyValues.AsName"/> already reads for a <c>Name</c>
/// property, so the correction made the container agree with the rest of the package rather than
/// making it special. Four bytes is exactly what a mis-sized field costs, and the arithmetic below
/// is what caught it.
/// </para>
/// <para>
/// <b>Why this is a decode and not a fit.</b> The walk is required to consume each export to its
/// <i>exact</i> final byte. A wrong field list cannot land on the boundary across hundreds of
/// independent exports whose sizes, polygon counts and vertex counts all differ — every surplus or
/// missing byte accumulates. <c>BspGeometryTests</c> asserts the landing across every map package,
/// so the reader fails loudly rather than returning plausible polygons.
/// </para>
/// <para>
/// <b>The two object references are told apart by what they resolve to, not by their order.</b>
/// Both are plausible on a brush polygon, and the arithmetic only constrains the group's total
/// size. The discriminator is the target's class: of the 59,495 shipped polygons that set the
/// second reference, <b>every one resolves to a material class</b> — 42,772 <c>Shader</c>, 16,353
/// <c>Texture</c>, 249 <c>FluidShader</c>, 101 <c>MaterialSwitch</c>, 16 <c>LayeredShader</c>, 4
/// <c>FluidSurfaceShader</c> — and <b>none to an actor class</b>, while the first reference is null
/// in all 93,264. That is a positive measurement rather than a deduction from silence, and it is
/// what promotes the field order to <c>CONFIRMED_BYTES</c>. <c>BspGeometryTests</c> holds it.
/// </para>
/// <para>
/// <b>So a brush carries its own surface</b>, which is more than the actor layer knew: brush
/// geometry can be textured by the same material resolver the meshes use, rather than drawing bare.
/// <b>What is still <c>UNKNOWN</c>:</b> how the <i>built</i> world BSP names its surfaces.
/// <c>0-Lighthouse</c> ships one <c>Model</c> of 312,400 bytes beside 284 of about 1,700 — the
/// built world beside the editor's source brushes — and that large container is not read here.
/// </para>
/// </remarks>
public static class PolysReader
{
    /// <summary>The class name of the export this reads.</summary>
    public const string ClassName = "Polys";

    /// <summary>The class name of the container that owns one.</summary>
    public const string ModelClassName = "Model";

    /// <summary>Every <c>Polys</c> export in a package, in export order.</summary>
    public static IEnumerable<ObjectExport> Enumerate(BioShockPackage package) =>
        package.Exports.Where(e => package.GetClassName(e) == ClassName);

    /// <summary>
    /// Reads one <c>Polys</c> export.
    /// </summary>
    /// <exception cref="InvalidDataException">
    /// The walk did not consume the payload exactly. Thrown rather than returning what was read,
    /// because a partially-walked polygon list is the plausible-but-wrong result this reader is
    /// shaped to avoid — the caller gets an actionable message naming the export and the shortfall.
    /// </exception>
    public static BspPolys Read(BioShockPackage package, ObjectExport export)
    {
        byte[] data = package.ReadExportData(export);
        string packageName = Path.GetFileNameWithoutExtension(package.FilePath);
        var source = new SourceId(packageName, export.Index, package.GetClassName(export), export.ObjectName);

        UnrealPropertyReader.Read(data, package.Names, out int offset);

        if (offset + 8 > data.Length)
            throw new InvalidDataException(
                $"{source}: the property list ends at {offset} of {data.Length}, leaving no room for the polygon count.");

        int count = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset)); offset += 4;
        int max = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset)); offset += 4;

        if (count < 0 || count > data.Length)
            throw new InvalidDataException($"{source}: polygon count {count} is impossible in {data.Length} bytes.");

        var polygons = new List<BspPolygon>(count);
        for (int i = 0; i < count; i++)
            polygons.Add(ReadPolygon(package, source, data, ref offset, i));

        if (offset != data.Length)
            throw new InvalidDataException(
                $"{source}: {count} polygons consumed to {offset} of {data.Length} bytes " +
                $"({offset - data.Length:+#;-#;0}). The layout does not hold for this export.");

        return new BspPolys
        {
            Source = source,
            Model = OuterModel(package, export, packageName),
            Polygons = polygons,
            DeclaredMax = max,
        };
    }

    /// <summary>
    /// The <c>Model</c> a <c>Polys</c> belongs to, taken from the export table's outer link. That is
    /// a stated relationship — a <c>Polys</c> object's outer <i>is</i> its model — rather than a name
    /// match, and it avoids having to walk <c>UModel</c>'s own binary to find the reference.
    /// </summary>
    private static SourceId? OuterModel(BioShockPackage package, ObjectExport export, string packageName)
    {
        if (!export.OuterIndex.IsExport || export.OuterIndex.ExportIndex >= package.Exports.Count) return null;
        var outer = package.Exports[export.OuterIndex.ExportIndex];
        string className = package.GetClassName(outer);
        if (className != ModelClassName) return null;
        return new SourceId(packageName, outer.Index, className, outer.ObjectName);
    }

    private static BspPolygon ReadPolygon(
        BioShockPackage package, SourceId source, byte[] data, ref int offset, int ordinal)
    {
        int vertexCount = PropertyValues.ReadCompactIndex(data, ref offset);
        if (vertexCount < 3 || vertexCount > 64)
            throw new InvalidDataException(
                $"{source}: polygon {ordinal} declares {vertexCount} vertices, which is not a polygon.");

        var basePoint = ReadVector(data, ref offset);
        var normal = ReadVector(data, ref offset);
        var textureU = ReadVector(data, ref offset);
        var textureV = ReadVector(data, ref offset);

        var vertices = new Vector3[vertexCount];
        for (int i = 0; i < vertexCount; i++) vertices[i] = ReadVector(data, ref offset);

        uint polyFlags = BinaryPrimitives.ReadUInt32LittleEndian(data.AsSpan(offset)); offset += 4;

        var actor = new PackageIndex(PropertyValues.ReadCompactIndex(data, ref offset));
        var material = new PackageIndex(PropertyValues.ReadCompactIndex(data, ref offset));

        int nameIndex = PropertyValues.ReadCompactIndex(data, ref offset);
        int nameNumber = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset)); offset += 4;
        if (nameIndex < 0 || nameIndex >= package.Names.Count)
            throw new InvalidDataException(
                $"{source}: polygon {ordinal} names index {nameIndex}, outside the package's {package.Names.Count} names.");
        string itemName = package.Names[nameIndex].Name;
        if (nameNumber != 0) itemName += nameNumber - 1;

        int link = PropertyValues.ReadCompactIndex(data, ref offset);
        int brushPoly = PropertyValues.ReadCompactIndex(data, ref offset);

        float lightMapScale = BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(offset)); offset += 4;

        return new BspPolygon
        {
            // Converted once, here, at the decode boundary — the same rule every other reader follows.
            Base = GameBasis.Convert(basePoint),
            Normal = GameBasis.Convert(normal),
            TextureU = GameBasis.Convert(textureU),
            TextureV = GameBasis.Convert(textureV),
            Vertices = vertices.Select(GameBasis.Convert).ToArray(),
            PolyFlags = polyFlags,
            Actor = actor,
            Material = material,
            ItemName = itemName,
            Link = link,
            BrushPoly = brushPoly,
            LightMapScale = lightMapScale,
        };
    }

    private static Vector3 ReadVector(byte[] data, ref int offset)
    {
        var value = new Vector3(
            BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(offset)),
            BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(offset + 4)),
            BinaryPrimitives.ReadSingleLittleEndian(data.AsSpan(offset + 8)));
        offset += 12;
        return value;
    }
}
