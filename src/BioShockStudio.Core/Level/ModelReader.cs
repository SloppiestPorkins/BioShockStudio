using System.Buffers.Binary;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Level;

/// <summary>What one <c>Model</c> export declares.</summary>
public sealed record BspModel
{
    public required SourceId Source { get; init; }

    /// <summary>The <c>Polys</c> export holding this model's source geometry, when it names one.</summary>
    public required PackageIndex Polys { get; init; }

    public required int VectorCount { get; init; }
    public required int PointCount { get; init; }
    public required int NodeCount { get; init; }
    public required int SurfCount { get; init; }
    public required int VertCount { get; init; }
    public required int ZoneCount { get; init; }

    /// <summary>
    /// How large this model's own BSP is. <b>Not</b> a test for the built world — see
    /// <see cref="ModelReader.BuiltWorld"/>.
    /// </summary>
    /// <remarks>
    /// A first attempt defined "this is the compiled world" as <c>NodeCount &gt; 0</c> and it was
    /// wrong: a source brush carries its own small node tree, six nodes for a six-sided box, so that
    /// test called all 285 of Lighthouse's models the built world. The difference is scale, not
    /// presence.
    /// </remarks>
    public int Complexity => NodeCount;

    public override string ToString() =>
        $"{Source.ObjectName}: {NodeCount} nodes, {SurfCount} surfs, {PointCount} points";
}

/// <summary>
/// Reads a <c>Model</c> export as far as its <c>Polys</c> reference.
/// </summary>
/// <remarks>
/// <para>
/// <b>Why this exists at all.</b> A brush actor's <c>Brush</c> property names a <c>Model</c>, and the
/// geometry is in a separate <c>Polys</c> export. The export table does <b>not</b> reliably state
/// the link — measured on <c>0-Lighthouse</c>, of 285 <c>Polys</c> exports only 60 have a
/// <c>Model</c> as their outer, 54 have a <c>SkeletalMesh</c>, and 171 have none; no <c>Model</c> is
/// immediately followed by its <c>Polys</c> either. So the link has to come from where the format
/// actually puts it: an object reference inside <c>UModel</c>'s own binary body.
/// </para>
/// <para>
/// <b>Status: <c>CONFIRMED_BYTES</c>, and this is the first time the layout has been checked against
/// shipped data by this project.</b> It comes from Nyko's SDK §C.1.1 (see
/// <c>docs/research/bsp.md</c> §5), which this project had recorded as <c>CONFIRMED_EXTERNAL</c> —
/// read from someone else's source and verified against nothing here.
/// </para>
/// <code>
/// Super::Serialize                     // Vengeance object header + tagged property list
/// FBox(25) + FSphere(16)               // UPrimitive base — 41 bytes
/// 8 B     Vengeance class header (check = 4, sv = 7)
/// TArray&lt;FVector&gt; Vectors           // CI count + 12 bytes each
/// TArray&lt;FVector&gt; Points
/// CI NumNodes  + 100 B each
/// CI NumSurfs  + variable each
/// CI NumVerts  + 8 B each
/// int32 NumSharedSides
/// int32 NumZones + FZoneProperties each
/// CI    Polys                          // ← what this reader is for
/// </code>
/// <para>
/// <b>The walk is required to land on a reference that resolves to a <c>Polys</c> export.</b> That
/// is the check that makes this a decode: every array length ahead of it is read from the data, so
/// a single wrong field size puts the final read somewhere arbitrary, and an arbitrary
/// <c>FCompactIndex</c> resolving to an export of exactly the right class 285 times is not something
/// that happens by chance. <c>ModelReaderTests</c> asserts it across every map package.
/// </para>
/// <para>
/// <b>Deliberately partial.</b> Everything after the <c>Polys</c> reference — bounds, leaf hulls,
/// leaves, lights, and the lightmap arrays — is not read, because nothing needs it yet. The node,
/// surface and vertex arrays are <i>skipped by length</i> rather than decoded, so this reader does
/// <b>not</b> implement the built world; it only proves the container walks. Decoding
/// <c>FBspNode</c> and <c>FBspSurf</c> is still open, and <c>bsp.md</c> §5 records the one field
/// where the references contradict each other.
/// </para>
/// </remarks>
public static class ModelReader
{
    public const string ClassName = "Model";

    /// <summary>The Vengeance class-header check value that precedes <c>UModel</c>'s own body.</summary>
    private const int VengeanceCheck = 4;

    public static IEnumerable<ObjectExport> Enumerate(BioShockPackage package) =>
        package.Exports.Where(e => package.GetClassName(e) == ClassName);

    /// <summary>
    /// The package's compiled world: the <c>Model</c> with the most nodes.
    /// </summary>
    /// <remarks>
    /// <b>This rule is Nyko's SDK's own</b> — its level scaffolding says to "find the largest UModel
    /// object in the package by node count and assign it as <c>Level->Model</c> (this is the main
    /// BSP)". It is a comparison rather than a threshold on purpose: every source brush also carries
    /// a small node tree, so there is no absolute count that separates them, but the separation
    /// within a package is enormous — on <c>0-Lighthouse</c> the source brushes have about six nodes
    /// each and the world has thousands.
    /// <para>
    /// Returns null for a package with no models. The result is <b>not</b> guaranteed to be a
    /// compiled world: a package containing only brushes returns its largest brush, so a caller that
    /// needs certainty should check the node count against the runners-up.
    /// </para>
    /// </remarks>
    public static BspModel? BuiltWorld(BioShockPackage package)
    {
        BspModel? best = null;

        foreach (var export in Enumerate(package))
        {
            BspModel? model;
            try { model = Read(package, export); }
            catch (InvalidDataException) { continue; }

            if (model is not null && (best is null || model.NodeCount > best.NodeCount)) best = model;
        }

        return best;
    }

    /// <summary>Reads a <c>Model</c>, or null when it is too small to hold a body.</summary>
    /// <exception cref="InvalidDataException">The walk left the payload or hit an impossible length.</exception>
    public static BspModel? Read(BioShockPackage package, ObjectExport export)
    {
        byte[] data = package.ReadExportData(export);
        string packageName = Path.GetFileNameWithoutExtension(package.FilePath);
        var source = new SourceId(packageName, export.Index, package.GetClassName(export), export.ObjectName);

        UnrealPropertyReader.Read(data, package.Names, out int offset);

        // UPrimitive: FBox (two FVectors plus a validity byte) then FSphere.
        offset += 25 + 16;

        // The Vengeance class header. Reading it is what confirms the walk is still aligned before
        // any length is trusted — an empty Model has no body at all and stops cleanly here.
        if (offset + 8 > data.Length) return null;
        int check = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset));
        if (check != VengeanceCheck)
            throw new InvalidDataException(
                $"{source}: expected the Vengeance class header ({VengeanceCheck}) at {offset}, found {check}.");
        offset += 8;

        int vectors = SkipArray(data, ref offset, 12, source, "Vectors");
        int points = SkipArray(data, ref offset, 12, source, "Points");
        int nodes = SkipArray(data, ref offset, 100, source, "Nodes");
        int surfs = SkipSurfs(data, ref offset, source);
        int verts = SkipArray(data, ref offset, 8, source, "Verts");

        if (offset + 8 > data.Length)
            throw new InvalidDataException($"{source}: ran out of payload before the zone counts.");

        offset += 4;                                                        // NumSharedSides
        int zones = BinaryPrimitives.ReadInt32LittleEndian(data.AsSpan(offset)); offset += 4;
        if (zones is < 0 or > 128)
            throw new InvalidDataException($"{source}: {zones} zones is outside Vengeance's MAX_ZONES of 128.");

        for (int i = 0; i < zones; i++)
        {
            PropertyValues.ReadCompactIndex(data, ref offset);               // ZoneActor
            offset += 16 + 16 + 4;                                           // Connectivity, Visibility, LastRenderTime
            if (offset > data.Length)
                throw new InvalidDataException($"{source}: zone {i} ran past the end of the payload.");
        }

        if (offset >= data.Length)
            throw new InvalidDataException($"{source}: ran out of payload before the Polys reference.");

        var polys = new PackageIndex(PropertyValues.ReadCompactIndex(data, ref offset));

        return new BspModel
        {
            Source = source,
            Polys = polys,
            VectorCount = vectors,
            PointCount = points,
            NodeCount = nodes,
            SurfCount = surfs,
            VertCount = verts,
            ZoneCount = zones,
        };
    }

    /// <summary>
    /// The <c>Polys</c> export a <c>Model</c> names, resolved, or null when it names none or the
    /// reference does not point at a <c>Polys</c>.
    /// </summary>
    /// <remarks>
    /// The class is checked rather than assumed. A reference that resolves to the wrong class means
    /// the walk landed somewhere plausible and wrong, and returning it would put another object's
    /// bytes through the polygon reader.
    /// </remarks>
    public static ObjectExport? ResolvePolys(BioShockPackage package, BspModel model)
    {
        if (!model.Polys.IsExport || model.Polys.ExportIndex >= package.Exports.Count) return null;
        var export = package.Exports[model.Polys.ExportIndex];
        return package.GetClassName(export) == PolysReader.ClassName ? export : null;
    }

    private static int SkipArray(byte[] data, ref int offset, int stride, SourceId source, string what)
    {
        int count = PropertyValues.ReadCompactIndex(data, ref offset);
        if (count < 0 || (long)count * stride > data.Length - offset)
            throw new InvalidDataException(
                $"{source}: {what} declares {count} elements of {stride} bytes, which does not fit in the "
                + $"{data.Length - offset} bytes remaining.");
        offset += count * stride;
        return count;
    }

    /// <summary>
    /// Skips the surface array, whose elements are <b>variable length</b> — two of the fields are
    /// <c>FCompactIndex</c> object references, so the stride is 54 to 58 bytes and cannot be
    /// multiplied through.
    /// </summary>
    private static int SkipSurfs(byte[] data, ref int offset, SourceId source)
    {
        int count = PropertyValues.ReadCompactIndex(data, ref offset);
        if (count < 0 || count > data.Length)
            throw new InvalidDataException($"{source}: {count} surfaces is impossible in {data.Length} bytes.");

        for (int i = 0; i < count; i++)
        {
            offset += 8;                                                     // per-element Vengeance header
            PropertyValues.ReadCompactIndex(data, ref offset);               // Material
            offset += 24;                                                    // PolyFlags, pBase, vNormal, vTextureU, vTextureV, +20
            PropertyValues.ReadCompactIndex(data, ref offset);               // Actor
            offset += 20;                                                    // FPlane + LightMapScale

            if (offset > data.Length)
                throw new InvalidDataException($"{source}: surface {i} of {count} ran past the end of the payload.");
        }

        return count;
    }
}
