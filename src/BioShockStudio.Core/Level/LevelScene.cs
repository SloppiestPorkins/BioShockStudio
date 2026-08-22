using System.Numerics;
using BioShockStudio.Core.Coordinates;
using BioShockStudio.Core.Materials;
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

    /// <summary>
    /// Atlas-specific render batches for a compiled world. Empty for ordinary meshes, brushes, and
    /// maps whose lightmap atlas pool has not been proven from the package bytes.
    /// </summary>
    public IReadOnlyList<BspGeometry.LightMapBatch> LightMapBatches { get; init; } = [];

    /// <summary>
    /// The drawn compiled-world surfaces that <see cref="LightMapBatches"/> does <b>not</b> cover,
    /// with <see cref="LightMapRemainderMaterials"/> as their section-ordered material list.
    /// </summary>
    /// <remarks>
    /// <b>This exists because the atlas-batched path used to lose them.</b> A map with a proven
    /// atlas pool is drawn from its batches, and a drawn surface whose first baked-light layer names
    /// no atlas this world carries is in no batch — so it reached the screen through nothing at all:
    /// 23,714 of 206,742 compiled-world triangles across the 20 affected maps, up to 49.5% of a
    /// single one. The remainder is carried here so the lightmapped path can draw it unlit rather
    /// than drop it. Null when the map has no batches, since then the whole world is drawn the
    /// ordinary way. See <see cref="BspGeometry.HasLightMapAtlas"/>.
    /// </remarks>
    public MeshGeometry? LightMapRemainder { get; init; }

    /// <summary>
    /// Section-ordered material references for <see cref="LightMapRemainder"/>. Raw rather than
    /// described, for the reason given on <see cref="MaterialReferences"/>.
    /// </summary>
    public IReadOnlyList<PackageIndex> LightMapRemainderMaterials { get; init; } = [];

    /// <summary>The materials the geometry's sections index, in section order. Entries may be null.</summary>
    public required IReadOnlyList<SourceId?> Materials { get; init; }

    /// <summary>
    /// The same list as <see cref="Materials"/>, as the raw references the BSP actually stores.
    /// Empty for a static or skeletal mesh, which resolves its own slots.
    /// </summary>
    /// <remarks>
    /// <b><see cref="Materials"/> cannot represent an import, and BSP surfaces have them.</b> A
    /// <see cref="SourceId"/> names an export in one package, so <c>Describe</c> returns null for a
    /// reference into another — which made a cross-package BSP material indistinguishable from a
    /// surface that names nothing. Measured: <b>1,530 of the game's 74,091 drawn compiled-world
    /// polygons name an import</b>, and every one of them drew untextured for it, while
    /// <b>0 name nothing at all</b>. The mesh path has resolved these since
    /// <c>MeshSurfaceResolver</c> gained <c>IExternalMaterialSource</c>; this is the same references
    /// kept intact so the BSP path can use it too.
    /// </remarks>
    public IReadOnlyList<PackageIndex> MaterialReferences { get; init; } = [];

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

    /// <summary>Every placed UE2 actor, including non-renderable gameplay and audio objects.</summary>
    public required IReadOnlyList<LevelActor> Actors { get; init; }

    /// <summary>
    /// The complete placed-actor ledger that produced this scene. Geometry is only one subset of a
    /// UE2 level; retaining the rest makes a future UE5 importer report gaps instead of dropping
    /// sound, triggers, effects, or gameplay actors on the floor.
    /// </summary>
    public LevelCoverageReport? Coverage { get; init; }

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
            else if (actor.SkeletalMesh is { Source: { } skeletalSource })
            {
                // These are deliberately a reference/bind-pose representation. The bytes establish
                // the mesh, sections and actor transform; they do not yet establish the runtime
                // animation or physics pose that the shipped game selects for this actor.
                Add(actor, skeletalSource, LevelGeometryKind.SkeletalMesh, meshCache, MeshPlacement(actor.Transform));
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
            Actors = context.Actors,
            Coverage = LevelCoverageReport.Build(context),
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

        var batches = BspGeometry.ToLightMapBatches(world);

        // The drawn surfaces those batches leave behind. Only meaningful when the map is going to be
        // drawn from batches at all — otherwise the whole world goes through Geometry above, and a
        // second copy of part of it would draw those triangles twice.
        MeshGeometry? remainder = null;
        IReadOnlyList<PackageIndex> remainderMaterials = [];
        if (batches.Count > 0)
        {
            bool Unbatched(BspNode node) => !BspGeometry.HasLightMapAtlas(world, node);
            var leftover = BspGeometry.ToGeometry(world, Unbatched);
            if (leftover.Indices.Count >= 3)
            {
                remainder = leftover;
                remainderMaterials = BspGeometry.Materials(world, Unbatched);
            }
        }

        instances.Add(new LevelInstance
        {
            Actor = world.Source,
            Kind = LevelGeometryKind.BuiltWorld,
            Asset = world.Source,
            Transform = Matrix4x4.Identity,
            Geometry = geometry,
            LightMapBatches = batches,
            LightMapRemainder = remainder,
            LightMapRemainderMaterials = remainderMaterials,
            Materials = [.. BspGeometry.Materials(world).Select(m => Describe(package, m))],
            MaterialReferences = BspGeometry.Materials(world),
            Label = "compiled world",
        });
    }

    /// <summary>
    /// A mesh actor's placement: the actor transform, conjugated into the studio's basis.
    /// </summary>
    /// <remarks>
    /// <c>ActorTransform.ToMatrix</c> composes pre-pivot, scale, rotation and translation in
    /// Unreal's order. That label used to read <c>LIKELY</c>, "awaiting a rendered level as
    /// evidence"; it is now <c>CONFIRMED_EXTERNAL</c>, checked component-by-component against the
    /// reference level editor's own <c>BuildActorTransform</c> on all 12,557 distinct rotation/scale
    /// pairs the shipped game places an actor at — <c>ActorTransformReferenceTests</c>.
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
    /// <b>Status: <c>CONFIRMED_BYTES</c> for the translation, measured against the compiled world.</b>
    /// CSG built the world from these same brushes and every <c>FBspSurf</c> names the brush actor it
    /// came from, so the same polygon exists twice — once in brush space, once in world space.
    /// <c>33,631 of 33,632</c> world polygons across six maps land in a plane of the brush they name,
    /// within 1 cm, once placed by this rule; the worst matched offset is 0.82 cm and the one that
    /// misses (<c>0-Lighthouse Brush12</c>) misses by 2.1 cm. Dropping the pre-pivot drops the match
    /// to <c>2.9%</c>, so the comparison distinguishes the rules rather than accepting anything.
    /// <c>BrushPlacementTests</c>.
    /// </para>
    /// <para>
    /// <b>What is still not established is the rotation and the scale.</b> This rule discards both,
    /// and the full actor transform scores identically above — because <b>no CSG brush carries
    /// either</b>. A sweep of all shipped maps finds <c>0 of 13,443</c> brush actors scaled and
    /// <c>17</c> rotated, and every one of the 17 is a <c>ShockDamageVolume</c>: a gameplay region,
    /// never drawn, never part of the built world. So nothing visible in the shipped game
    /// distinguishes this rule from the full transform, and for those 17 volumes the composition
    /// order remains <c>UNKNOWN</c>. <c>LevelSceneTests</c> holds both censuses.
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

            var meshExport = package.Exports[asset.ExportIndex];
            var meshData = package.ReadExportData(meshExport);
            var geometry2 = kind == LevelGeometryKind.SkeletalMesh
                ? SkeletalMeshReader.ReadGeometry(meshData, package.Names)
                : StaticMeshReader.ReadGeometry(meshData);

            // A mesh's section ordinal addresses its own Materials array. Retaining only
            // section geometry made the UE5 handoff know that a mesh had sections, but not which
            // material each section used; that is enough to reconstruct a grey level, not its
            // authored surfaces.  Keep nulls for external/unresolved references so ordinal N never
            // shifts onto a neighbour's material.
            var meshMaterials = MaterialReader.ReadMeshMaterialSlots(meshData, package)
                .Select(index => Describe(package, index))
                .ToList();
            return (geometry2, meshMaterials, geometry2 is null ? "no vertex data was found in this mesh" : null);
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
