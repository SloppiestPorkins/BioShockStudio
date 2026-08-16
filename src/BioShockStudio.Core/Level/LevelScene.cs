using System.Numerics;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Level;

/// <summary>What kind of thing a placed instance draws.</summary>
public enum LevelGeometryKind
{
    StaticMesh,
    SkeletalMesh,

    /// <summary>A BSP brush: the designer's convex solid, from a <c>Polys</c> export.</summary>
    Brush,

    /// <summary>
    /// The compiled world — the level's actual architecture, from the largest <c>Model</c>'s node
    /// tree. One per map, already in world space.
    /// </summary>
    BuiltWorld,
}

/// <summary>
/// One drawable thing, placed in the world.
/// </summary>
/// <remarks>
/// The geometry is <b>shared, not baked</b>: <see cref="Geometry"/> is the asset in its own space
/// and <see cref="Transform"/> puts it in the world. A map instances the same mesh hundreds of
/// times, so baking every instance's vertices would multiply the level's size by its repetition
/// count for no gain — the exporters already understand an instance.
/// </remarks>
public sealed record LevelInstance
{
    public required SourceId Actor { get; init; }
    public required LevelGeometryKind Kind { get; init; }

    /// <summary>The asset this draws, for deduplication and for naming the export.</summary>
    public required SourceId Asset { get; init; }

    /// <summary>Local-to-world, in the studio's basis. Row-vector convention.</summary>
    public required Matrix4x4 Transform { get; init; }

    public required MeshGeometry Geometry { get; init; }

    /// <summary>The materials the geometry's sections index, in section order. Entries may be null.</summary>
    public required IReadOnlyList<SourceId?> Materials { get; init; }

    public string? Label { get; init; }

    public override string ToString() => $"{Kind} {Asset.ObjectName} for {Actor.ObjectName}";
}

/// <summary>
/// A level assembled into something that can be drawn or written out: placed geometry, lights, and
/// what did not resolve.
/// </summary>
/// <remarks>
/// <para>
/// <b>This is the consumer <c>LevelContext</c> never had.</b> The actor layer resolved 1,877 actors
/// on <c>0-Lighthouse</c> and then went nowhere — no scene, no export, nothing in the window.
/// </para>
/// <para>
/// <b>Everything here is in the studio's basis.</b> <see cref="LevelContext"/> holds an actor's
/// transform as the level stores it, which is the game's left-handed basis; this layer is where a
/// level crosses into the studio's, and it is the only place that conversion happens for a level.
/// See <see cref="LevelSceneBuilder"/>.
/// </para>
/// </remarks>
public sealed record LevelScene
{
    public required string PackageName { get; init; }
    public required IReadOnlyList<LevelInstance> Instances { get; init; }
    public required IReadOnlyList<LevelLight> Lights { get; init; }

    /// <summary>Actors that named geometry which could not be decoded, with the reason.</summary>
    public required IReadOnlyList<(SourceId Actor, string Reason)> Skipped { get; init; }

    /// <summary>
    /// The bounds of the placed geometry, which is <b>not</b> the bounds of the actor list.
    /// </summary>
    /// <remarks>
    /// The actor list's extent is set by a sentinel: exactly one <c>Script</c> actor of 1,874 sits
    /// at <c>Z = 262144</c>, Unreal's <c>HALF_WORLD_MAX</c>, and excluding it the level's maximum Z
    /// is 12,288 — a twenty-fold difference. An exporter that sized a scene from the raw extents
    /// would size it from that one actor, so this measures what is actually drawn.
    /// </remarks>
    public required (Vector3 Min, Vector3 Max) Bounds { get; init; }

    public int TriangleCount => Instances.Sum(i => i.Geometry.TriangleCount);
    public int VertexCount => Instances.Sum(i => i.Geometry.Vertices.Count);

    public IEnumerable<LevelInstance> Brushes => Instances.Where(i => i.Kind == LevelGeometryKind.Brush);

    /// <summary>The compiled world, if the map has one. At most one instance.</summary>
    public IEnumerable<LevelInstance> World => Instances.Where(i => i.Kind == LevelGeometryKind.BuiltWorld);

    /// <summary>
    /// Placed meshes — <b>not</b> the compiled world, which is counted on its own.
    /// </summary>
    /// <remarks>
    /// This was <c>Kind != Brush</c>, which quietly filed the compiled world as a static mesh the
    /// moment one existed. A count that silently absorbs a new kind is how a number stops meaning
    /// what its label says.
    /// </remarks>
    public IEnumerable<LevelInstance> Meshes => Instances.Where(
        i => i.Kind is LevelGeometryKind.StaticMesh or LevelGeometryKind.SkeletalMesh);
}

/// <summary>
/// Builds a <see cref="LevelScene"/> from a map package.
/// </summary>
/// <remarks>
/// <para>
/// <b>The basis boundary.</b> Geometry arrives already converted — every mesh and brush reader
/// converts at its own decode, per <c>ANIMATION_COORDINATE_SYSTEM.md</c> §9 — but an actor's
/// <i>placement</i> does not, because <see cref="ActorTransform"/> deliberately holds the raw
/// properties. So the placement is converted here, once, by the same <c>C · M · C⁻¹</c> conjugation
/// that sockets use, and geometry is never touched again. Converting either one twice is the
/// failure that note exists to prevent.
/// </para>
/// <para>
/// <b>A brush is placed differently from a mesh, and that is measured, not assumed.</b> See
/// <see cref="BrushPlacement"/>.
/// </para>
/// </remarks>
public static class LevelSceneBuilder
{
    public static LevelScene Build(BioShockPackage package, LevelContext context, IProgress<string>? progress = null)
    {
        var instances = new List<LevelInstance>();
        var lights = new List<LevelLight>();
        var skipped = new List<(SourceId, string)>();

        // One decode per distinct asset, not per actor: a map instances the same mesh hundreds of
        // times and decoding it each time is the difference between seconds and minutes.
        var meshCache = new Dictionary<int, (MeshGeometry? Geometry, IReadOnlyList<SourceId?> Materials, string? Error)>();
        var brushCache = new Dictionary<int, (MeshGeometry? Geometry, IReadOnlyList<SourceId?> Materials, string? Error)>();

        foreach (var actor in context.Actors)
        {
            if (LevelLightReader.Read(actor) is { } light) lights.Add(light);

            if (actor.Brush is { Source: { } brushSource })
            {
                Add(actor, brushSource, LevelGeometryKind.Brush, brushCache, BrushPlacement(actor.Transform));
            }
            else if (actor.StaticMesh is { Source: { } meshSource })
            {
                Add(actor, meshSource, LevelGeometryKind.StaticMesh, meshCache, MeshPlacement(actor.Transform));
            }

            if (instances.Count % 500 == 0 && instances.Count > 0)
                progress?.Report($"{instances.Count} instances, {lights.Count} lights");
        }

        // The compiled world, which belongs to no actor: it is the level's own architecture, built
        // by CSG from the source brushes, and it is where the floors and walls a player stands on
        // actually live. Without it a map is its props and its skyline with the rooms missing.
        progress?.Report("Reading the compiled world…");
        AddBuiltWorld(package, instances, skipped);

        return new LevelScene
        {
            PackageName = context.PackageName,
            Instances = instances,
            Lights = lights,
            Skipped = skipped,
            Bounds = MeasureBounds(instances),
        };

        void Add(
            LevelActor actor, SourceId asset, LevelGeometryKind kind,
            Dictionary<int, (MeshGeometry?, IReadOnlyList<SourceId?>, string?)> cache,
            Matrix4x4 transform)
        {
            if (!cache.TryGetValue(asset.ExportIndex, out var decoded))
                cache[asset.ExportIndex] = decoded = Decode(package, asset, kind);

            if (decoded.Item1 is not { } geometry || geometry.Indices.Count < 3)
            {
                skipped.Add((actor.Source, decoded.Item3 ?? "the asset decoded to no geometry"));
                return;
            }

            instances.Add(new LevelInstance
            {
                Actor = actor.Source,
                Kind = kind,
                Asset = asset,
                Transform = transform,
                Geometry = geometry,
                Materials = decoded.Item2,
                Label = actor.Label,
            });
        }
    }

    /// <summary>
    /// Adds the package's compiled world as a single instance, if it has one.
    /// </summary>
    /// <remarks>
    /// <b>Its transform is identity</b>, because the compiled world's points are already absolute —
    /// CSG produced them in world space. Giving it an actor's placement would move the level away
    /// from the props standing in it.
    /// </remarks>
    private static void AddBuiltWorld(
        BioShockPackage package, List<LevelInstance> instances, List<(SourceId, string)> skipped)
    {
        var model = ModelReader.BuiltWorld(package);
        if (model is null) return;

        BspWorld? world;
        try { world = BspWorldReader.Read(package, package.Exports[model.Source.ExportIndex]); }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException)
        {
            skipped.Add((model.Source, "the compiled world would not decode: " + ex.Message));
            return;
        }

        if (world is null || world.PolygonCount == 0) return;

        var geometry = BspGeometry.ToGeometry(world);
        if (geometry.Indices.Count < 3) return;

        instances.Add(new LevelInstance
        {
            Actor = world.Source,
            Kind = LevelGeometryKind.BuiltWorld,
            Asset = world.Source,
            Transform = Matrix4x4.Identity,
            Geometry = geometry,
            Materials = [.. BspGeometry.Materials(world).Select(m => Describe(package, m))],
            Label = "compiled world",
        });
    }

    /// <summary>
    /// A mesh actor's placement: the actor transform, conjugated into the studio's basis.
    /// </summary>
    /// <remarks>
    /// <c>ActorTransform.ToMatrix</c> composes pre-pivot, scale, rotation and translation in
    /// Unreal's order and is labelled <c>LIKELY</c> there — inherited from the engine rather than
    /// derived from BioShock's bytes, and explicitly awaiting a rendered level as evidence.
    /// <c>LevelRenderingTests</c> is now that evidence.
    /// </remarks>
    public static Matrix4x4 MeshPlacement(ActorTransform transform) => GameBasis.Convert(transform.ToMatrix());

    /// <summary>
    /// A brush actor's placement, which is <b>not</b> the same as a mesh's.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>A brush's polygons are already in world space, offset by the actor's location.</b> Unreal
    /// stores brush geometry relative to the brush's own origin and the editor keeps
    /// <c>Location</c> and <c>PrePivot</c> in step, so the placement that reproduces the built level
    /// is <c>Location − PrePivot</c> with no rotation or scale — not the full actor transform a mesh
    /// takes.
    /// </para>
    /// <para>
    /// <b>Status: <c>LIKELY</c>, and it is the weakest claim in this file.</b> It is what makes the
    /// shipped brushes assemble into a coherent level rather than a heap at the origin, which is
    /// evidence, but "the rooms line up" is not the same as "the composition order is right" — a
    /// level whose brushes are all unrotated would look identical under several wrong rules.
    /// <c>LevelGeometryPlacementTests</c> records how many brush actors carry a rotation or a scale
    /// at all, which is the measurement that says how much this claim is actually being exercised.
    /// </para>
    /// </remarks>
    public static Matrix4x4 BrushPlacement(ActorTransform transform) =>
        Matrix4x4.CreateTranslation(GameBasis.Convert(transform.Location - transform.PrePivot));

    private static (MeshGeometry?, IReadOnlyList<SourceId?>, string?) Decode(
        BioShockPackage package, SourceId asset, LevelGeometryKind kind)
    {
        try
        {
            if (kind == LevelGeometryKind.Brush)
            {
                // An actor's Brush property names a MODEL, not the polygons. The export table does
                // not state the link — most Polys exports have no outer, or the wrong one — so it
                // comes from the reference inside UModel's own body. See ModelReader.
                var model = ModelReader.Read(package, package.Exports[asset.ExportIndex]);
                if (model is null) return (null, [], "the Model export carries no body");
                if (ModelReader.ResolvePolys(package, model) is not { } polysExport)
                    return (null, [], $"the Model's Polys reference ({model.Polys}) resolves to nothing");

                var polys = PolysReader.Read(package, polysExport);
                var geometry = BspGeometry.ToGeometry(polys.Polygons);
                var materials = BspGeometry.Materials(polys.Polygons)
                    .Select(m => Describe(package, m))
                    .ToList();
                return (geometry, materials, null);
            }

            var geometry2 = StaticMeshReader.ReadGeometry(package.ReadExportData(package.Exports[asset.ExportIndex]));
            return (geometry2, [], geometry2 is null ? "no vertex data was found in this mesh" : null);
        }
        catch (Exception ex)
        {
            return (null, [], ex.Message);
        }
    }

    private static SourceId? Describe(BioShockPackage package, PackageIndex index)
    {
        if (!index.IsExport || index.ExportIndex >= package.Exports.Count) return null;
        var export = package.Exports[index.ExportIndex];
        return new SourceId(
            Path.GetFileNameWithoutExtension(package.FilePath),
            export.Index, package.GetClassName(export), export.ObjectName);
    }

    private static (Vector3, Vector3) MeasureBounds(IReadOnlyList<LevelInstance> instances)
    {
        var min = new Vector3(float.MaxValue);
        var max = new Vector3(float.MinValue);
        bool any = false;

        foreach (var instance in instances)
        {
            foreach (var vertex in instance.Geometry.Vertices)
            {
                var world = Vector3.Transform(vertex.Position, instance.Transform);
                min = Vector3.Min(min, world);
                max = Vector3.Max(max, world);
                any = true;
            }
        }

        return any ? (min, max) : (Vector3.Zero, Vector3.Zero);
    }
}
