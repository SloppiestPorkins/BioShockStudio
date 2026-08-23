using System.Globalization;
using System.Numerics;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Security.Cryptography;
using BioShockStudio.Core.Level;

namespace BioShockStudio.Core.Export;

/// <summary>What a level extraction writes.</summary>
[Flags]
public enum LevelExportFormats
{
    None = 0,

    /// <summary>The scene as JSON: every instance, its transform, its materials, and the lights.</summary>
    SceneJson = 1,

    /// <summary>Wavefront OBJ — geometry only, but openable in anything.</summary>
    Obj = 2,

    /// <summary>Compact UE5 handoff: actor graph and asset identities, with no duplicated mesh buffers.</summary>
    Ue5Manifest = 4,

    /// <summary>
    /// One OBJ per unique asset, in <b>local</b> space, for import as individual UE5 static meshes.
    /// </summary>
    /// <remarks>
    /// Distinct from <see cref="Obj"/>, which bakes every instance into world space in one file.
    /// That is right for opening a level in a viewer and wrong for an engine import: it discards
    /// instancing entirely, so a brush used 40 times arrives as 40 copies of its geometry. These
    /// files keep one mesh per asset and let the manifest's per-instance transforms place them.
    /// </remarks>
    AssetMeshes = 8,

    All = SceneJson | Obj | Ue5Manifest | AssetMeshes,
}

/// <summary>
/// Writes a <see cref="LevelScene"/> to disk.
/// </summary>
/// <remarks>
/// <para>
/// Two formats, for two different jobs. The <b>scene JSON</b> is the lossless hand-off: it keeps
/// instancing, so a mesh placed 300 times is one asset and 300 transforms, and it carries the
/// lights and the material references that OBJ cannot express. The <b>OBJ</b> bakes every instance
/// into world-space triangles — much larger, and lossy — and exists because a format anyone can
/// open in any tool is what actually gets a level looked at, which is this project's standing rule.
/// </para>
/// <para>
/// <b>OBJ is 1-based and this writer is where that goes wrong.</b> Vertex indices in OBJ start at 1,
/// and every instance appends to one shared vertex list, so the running offset has to be added per
/// instance. An off-by-one here produces a mesh that opens, has the right triangle count, and is
/// subtly wrong — so <c>LevelExportTests</c> reads the file back and compares triangles against the
/// scene rather than trusting the count.
/// </para>
/// </remarks>
public static class LevelSceneExporter
{
    /// <summary>Schema version for the level-to-UE5 handoff. Bump only for incompatible changes.</summary>
    public const int LevelManifestVersion = 4;
    private static readonly JsonSerializerOptions Options = new()
    {
        WriteIndented = false,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    };

    private static readonly JsonSerializerOptions ReadableOptions = new(Options) { WriteIndented = true };

    /// <summary>Writes the requested formats into <paramref name="directory"/> and returns the paths.</summary>
    public static IReadOnlyList<string> Write(
        LevelScene scene, string directory, LevelExportFormats formats = LevelExportFormats.All,
        bool readable = false)
    {
        Directory.CreateDirectory(directory);
        var written = new List<string>();

        if (formats.HasFlag(LevelExportFormats.SceneJson))
        {
            string path = Path.Combine(directory, scene.PackageName + ".level.json");
            File.WriteAllText(path, JsonSerializer.Serialize(ToDocument(scene), readable ? ReadableOptions : Options));
            written.Add(path);
        }

        // Written before the manifest, because the manifest records each asset's mesh path.
        var assetFiles = new Dictionary<string, string>(StringComparer.Ordinal);
        if (formats.HasFlag(LevelExportFormats.AssetMeshes))
        {
            assetFiles = WriteAssetMeshes(scene, directory, written);
        }

        if (formats.HasFlag(LevelExportFormats.Ue5Manifest))
        {
            string path = Path.Combine(directory, scene.PackageName + ".ue5-level.json");
            File.WriteAllText(path, JsonSerializer.Serialize(
                ToDocument(scene, includeGeometry: false, assetFiles),
                readable ? ReadableOptions : Options));
            written.Add(path);
        }

        if (formats.HasFlag(LevelExportFormats.Obj))
        {
            string path = Path.Combine(directory, scene.PackageName + ".obj");
            File.WriteAllText(path, BuildObj(scene));
            written.Add(path);
        }

        return written;
    }

    /// <summary>The scene as a serialisable document.</summary>
    public static LevelDocument ToDocument(
        LevelScene scene,
        bool includeGeometry = true,
        IReadOnlyDictionary<string, string>? assetFiles = null) => new()
    {
        FormatVersion = LevelManifestVersion,
        Package = scene.PackageName,
        Generator = "BioShockStudio",
        Basis = "right-handed, +X forward, +Y left, +Z up, centimetres",
        BoundsMin = ToArray(scene.Bounds.Min),
        BoundsMax = ToArray(scene.Bounds.Max),
        GeometryEmbedded = includeGeometry,
        Assets = scene.Instances
            .GroupBy(i => i.Asset)
            .Select(g => new LevelAssetDocument
            {
                Key = g.Key.Key,
                Name = g.Key.ObjectName,
                Kind = g.First().Kind.ToString(),
                ExportIndex = g.Key.ExportIndex,
                File = assetFiles is not null && assetFiles.TryGetValue(g.Key.Key, out string? file) ? file : null,
                VertexCount = g.First().Geometry.Vertices.Count,
                TriangleCount = g.First().Geometry.TriangleCount,
                Vertices = includeGeometry ? g.First().Geometry.Vertices.Select(v => ToArray(v.Position)).ToList() : null,
                Normals = includeGeometry ? g.First().Geometry.Vertices.Select(v => ToArray(v.Normal)).ToList() : null,
                Uvs = includeGeometry ? g.First().Geometry.Vertices.Select(v => new[] { v.Uv.X, v.Uv.Y }).ToList() : null,
                Indices = includeGeometry ? g.First().Geometry.Indices.ToList() : null,
                Sections = g.First().Geometry.Sections
                    .Select((s, index) => new LevelSectionDocument
                    {
                        FirstIndex = s.FirstIndex,
                        TriangleCount = s.TriangleCount,
                        Material = index < g.First().Materials.Count ? g.First().Materials[index]?.ObjectName : null,
                        MaterialKey = index < g.First().Materials.Count ? g.First().Materials[index]?.Key : null,
                        MaterialPackage = index < g.First().Materials.Count ? g.First().Materials[index]?.Package : null,
                        MaterialClassName = index < g.First().Materials.Count ? g.First().Materials[index]?.ClassName : null,
                        MaterialExportIndex = index < g.First().Materials.Count
                            ? g.First().Materials[index]?.ExportIndex
                            : null,
                    })
                    .ToList(),
            })
            .ToList(),
        Instances = scene.Instances
            .Select(i => new LevelInstanceDocument
            {
                Asset = i.Asset.Key,
                ActorKey = i.Actor.Key,
                Actor = i.Actor.ObjectName,
                Label = i.Label,
                Transform = ToArray(i.Transform),
            })
            .ToList(),
        Actors = scene.Actors
            .Select(actor => new LevelActorDocument
            {
                Key = actor.Source.Key,
                Name = actor.Source.ObjectName,
                ClassName = actor.Source.ClassName,
                ExportIndex = actor.Source.ExportIndex,
                Label = actor.Label,
                Tag = actor.Tag,
                Location = ToArray(actor.Transform.Location),
                Rotation = [actor.Transform.Rotation.Pitch, actor.Transform.Rotation.Yaw, actor.Transform.Rotation.Roll],
                DrawScale = actor.Transform.DrawScale,
                DrawScale3D = ToArray(actor.Transform.DrawScale3D),
                PrePivot = ToArray(actor.Transform.PrePivot),
                Region = actor.Region is null ? null : new LevelRegionDocument
                {
                    Leaf = actor.Region.Leaf,
                    ZoneNumber = actor.Region.ZoneNumber,
                },
                RegionActor = actor.RegionActor is null ? null : new LevelRegionActorDocument
                {
                    MainScale = ScaleDocument(actor.RegionActor.MainScale),
                    PostScale = ScaleDocument(actor.RegionActor.PostScale),
                    BlockActors = actor.RegionActor.BlockActors,
                    BlockHavok = actor.RegionActor.BlockHavok,
                    BlockNonZeroExtentTraces = actor.RegionActor.BlockNonZeroExtentTraces,
                    BlockPlayers = actor.RegionActor.BlockPlayers,
                    BlockZeroExtentTraces = actor.RegionActor.BlockZeroExtentTraces,
                    CollideActors = actor.RegionActor.CollideActors,
                    Disabled = actor.RegionActor.Disabled,
                    Enabled = actor.RegionActor.Enabled,
                    TriggerOnlyOnce = actor.RegionActor.TriggerOnlyOnce,
                    TriggerWhenNotSeen = actor.RegionActor.TriggerWhenNotSeen,
                    CollisionRadius = actor.RegionActor.CollisionRadius,
                    CollisionHeight = actor.RegionActor.CollisionHeight,
                    MinimumDistance = actor.RegionActor.MinimumDistance,
                    TriggeredBy = actor.RegionActor.TriggeredBy,
                    TriggerOnlyByLabels = actor.RegionActor.TriggerOnlyByLabels.ToList(),
                    TriggeredByFilter = actor.RegionActor.TriggeredByFilter.ToList(),
                    TriggerOnlyByClasses = actor.RegionActor.TriggerOnlyByClasses.Select(Describe).ToList(),
                    WaterMesh = Describe(actor.RegionActor.WaterMesh),
                    WaterAxis = actor.RegionActor.WaterAxis,
                    MovingInWaterPenalty = actor.RegionActor.MovingInWaterPenalty,
                    Priority = actor.RegionActor.Priority,
                    NoDelete = actor.RegionActor.NoDelete,
                    Zone = ZoneDocument(actor.RegionActor.Zone),
                    Complete = actor.RegionActor.Complete,
                },
                TrainingConcepts = actor.TrainingConcepts.ToList(),
                Spawner = actor.Spawner is null ? null : new LevelSpawnerActorDocument
                {
                    GlobalPatrol = actor.Spawner.GlobalPatrol,
                    InitialPatrol = actor.Spawner.InitialPatrol,
                    RepopulationPatrol = actor.Spawner.RepopulationPatrol,
                    InitialLabel = actor.Spawner.InitialLabel,
                    GlobalAiTypes = actor.Spawner.GlobalAiTypes.ToList(),
                    InitialAiTypes = actor.Spawner.InitialAiTypes.ToList(),
                    RepopulationAiTypes = actor.Spawner.RepopulationAiTypes.ToList(),
                    OverriddenAiArchetypeNames = actor.Spawner.OverriddenAiArchetypeNames.ToList(),
                    SpawnZones = actor.Spawner.SpawnZones.ToList(),
                    Complete = actor.Spawner.Complete,
                },
                Cubemap = Describe(actor.Cubemap),
                Projector = actor.Projector is null ? null : new LevelProjectorActorDocument
                {
                    Material = Describe(actor.Projector.Material),
                    Tile = actor.Projector.Tile is { } tile ? ToArray(tile) : null,
                    MaxTraceDistance = actor.Projector.MaxTraceDistance,
                    ZBiasOverride = actor.Projector.ZBiasOverride,
                    ScaleInTime = actor.Projector.ScaleInTime,
                    FadeInEnd = actor.Projector.AngleGradient?.FadeInEnd,
                    FadeOutStart = actor.Projector.AngleGradient?.FadeOutStart,
                    ProjectOnBackfaces = actor.Projector.ProjectOnBackfaces,
                    ProjectStaticMesh = actor.Projector.ProjectStaticMesh,
                    ProjectSkeletalMesh = actor.Projector.ProjectSkeletalMesh,
                    ShouldBeAttached = actor.Projector.ShouldBeAttached,
                    Complete = actor.Projector.Complete,
                },
                HavokForce = actor.HavokForce is null ? null : new LevelHavokForceActorDocument
                {
                    ForceType = Describe(actor.HavokForce.ForceType)!,
                    ForceShape = Describe(actor.HavokForce.ForceShape)!,
                    ForceFilter = Describe(actor.HavokForce.ForceFilter),
                    Complete = actor.HavokForce.Complete,
                },
                LootSlot = Describe(actor.LootSlot),
                StaticMesh = actor.StaticMesh?.ObjectName,
                SkeletalMesh = actor.SkeletalMesh?.ObjectName,
                Brush = actor.Brush?.ObjectName,
                Attachment = actor.Attachment?.ObjectName,
                StaticMeshReference = Describe(actor.StaticMesh),
                SkeletalMeshReference = Describe(actor.SkeletalMesh),
                BrushReference = Describe(actor.Brush),
                AttachmentReference = Describe(actor.Attachment),
                MaterialOverrides = actor.MaterialOverrides.Select(Describe).ToList(),
                Navigation = actor.Navigation is null ? null : new LevelNavigationDocument
                {
                    PathLinks = actor.Navigation.PathLinks.Select(Describe).ToList(),
                    AutoGeneratedFlyingPathNodes = actor.Navigation.AutoGeneratedFlyingPathNodes.Select(Describe).ToList(),
                    PathCollisionRadius = actor.Navigation.PathCollisionRadius,
                    AutoGeneratedFlagSerialized = actor.Navigation.AutoGeneratedFlagSerialized,
                },
                ScriptActions = actor.ScriptActions is null ? null : new LevelScriptActionsDocument
                {
                    Complete = actor.ScriptActions.Complete,
                    Actions = actor.ScriptActions.Actions.Select(Describe).ToList(),
                },
                Emitters = actor.Emitters is null ? null : new LevelEmittersDocument
                {
                    Complete = actor.Emitters.Complete,
                    Templates = actor.Emitters.Templates.Select(template => new LevelEmitterTemplateDocument
                    {
                        Source = Describe(template.Source),
                        Material = Describe(template.Material),
                        MaxParticles = template.MaxParticles,
                        ParticlesPerSecond = template.ParticlesPerSecond,
                        InitialParticlesPerSecond = template.InitialParticlesPerSecond,
                        PropertiesComplete = template.PropertiesComplete,
                    }).ToList(),
                },
                Groups = actor.Groups.ToList(),
                Properties = actor.Properties.Select(property => new LevelPropertyDocument
                {
                    Name = property.Name,
                    Type = property.Type.ToString(),
                    StructName = property.StructName,
                    ArrayIndex = property.ArrayIndex,
                    // Large arrays (navigation, emitter and script payloads) make a map manifest
                    // enormous when hex-encoded. Keep inspectable small values inline; larger ones
                    // remain byte-identifiable and recoverable from the immutable source export.
                    ValueHex = property.Value.Length <= 256 ? Convert.ToHexString(property.Value) : null,
                    ValueLength = property.Value.Length,
                    ValueSha256 = Convert.ToHexString(SHA256.HashData(property.Value)),
                }).ToList(),
                TrailerHex = Convert.ToHexString(actor.Trailer),
                Truncated = actor.Truncated,
            })
            .ToList(),
        Lights = scene.Lights
            .Select(l => new LevelLightDocument
            {
                Key = l.Source.Key,
                Name = l.Source.ObjectName,
                ClassName = l.ClassName,
                ExportIndex = l.Source.ExportIndex,
                Location = ToArray(l.Location),
                Color = l.Color is { } c ? [c.R, c.G, c.B, c.A] : null,
                Brightness = l.Brightness,
                Radius = l.Radius,
            })
            .ToList(),
        ActorCoverage = scene.Coverage?.Classes
            .Select(row => new LevelActorCoverageDocument
            {
                ClassName = row.ClassName,
                ActorCount = row.ActorCount,
                Status = row.StatusCounts.ToDictionary(status => status.Key.ToString(), status => status.Value),
                OutstandingProperties = row.OutstandingProperties.ToList(),
            })
            .ToList() ?? [],
        Skipped = scene.Skipped.Select(s => $"{s.Actor}: {s.Reason}").ToList(),
    };

    private static LevelZoneActorDocument? ZoneDocument(ZoneActorData? zone) => zone is null ? null : new()
    {
        CurrentAmbient = AmbientDocument(zone.CurrentAmbient),
        NormalPressureAmbient = AmbientDocument(zone.NormalPressureAmbient),
        HighPressureAmbient = AmbientDocument(zone.HighPressureAmbient),
        LowPressureAmbient = AmbientDocument(zone.LowPressureAmbient),
        CurrentFog = FogDocument(zone.CurrentFog),
        NormalFog = FogDocument(zone.NormalFog),
        HighFog = FogDocument(zone.HighFog),
        ReverbType = zone.ReverbType,
        MapUiRegion = zone.MapUiRegion,
        PressureRegion = zone.PressureRegion,
        PressureEffectsDuration = zone.PressureEffectsDuration,
        TimeLastPressureChange = zone.TimeLastPressureChange,
        SpawnZones = zone.SpawnZones.ToList(),
        EffectsContexts = zone.EffectsContexts.ToList(),
        ManualExcludes = zone.ManualExcludes.Select(Describe).ToList(),
    };

    private static LevelActorScaleDocument? ScaleDocument(ActorScaleData? scale) => scale is null ? null : new()
    {
        Scale = ToArray(scale.Scale),
        SheerRate = scale.SheerRate,
        SheerAxis = scale.SheerAxis,
    };

    private static LevelZoneAmbientDocument? AmbientDocument(ZoneAmbientData? ambient) => ambient is null ? null : new()
    {
        VectorHigh = ambient.VectorHigh is { } vector ? ToArray(vector) : null,
        ColorHigh = ambient.ColorHigh is { } color ? [color.R, color.G, color.B, color.A] : null,
        ColorHighMultiplier = ambient.ColorHighMultiplier,
        ColorLowMultiplier = ambient.ColorLowMultiplier,
        ContrastPower = ambient.ContrastPower,
        XGroundRatio = ambient.XGroundRatio,
    };

    private static LevelZoneFogDocument? FogDocument(ZoneFogData? fog) => fog is null ? null : new()
    {
        Enabled = fog.Enabled,
        Clip = fog.Clip,
        Color = fog.Color is { } color ? [color.R, color.G, color.B, color.A] : null,
        Start = fog.Start,
        End = fog.End,
        MaxContribution = fog.MaxContribution,
    };

    /// <summary>
    /// The scene as Wavefront OBJ, in world space.
    /// </summary>
    /// <remarks>
    /// Instancing is lost here — every placement is baked — which is exactly why the scene JSON
    /// exists beside it. Normals are transformed by the instance matrix too; for the rigid,
    /// uniformly-scaled placements a level uses this is correct, and a non-uniform scale would need
    /// the inverse transpose. No shipped level actor has been measured with one, so rather than
    /// silently applying the cheap rule this writes what it does and
    /// <c>LevelExportTests.NoLevelInstanceCarriesANonUniformScale</c> checks the assumption still
    /// holds — the check fails loudly if the game ever disagrees.
    /// </remarks>
    /// <summary>
    /// Writes one local-space OBJ per unique asset and returns their paths by asset key.
    /// </summary>
    /// <remarks>
    /// Grouped by asset rather than walked per instance: a level's 1,274 instances resolve to a few
    /// hundred distinct assets, and writing per instance would duplicate every shared brush.
    /// </remarks>
    private static Dictionary<string, string> WriteAssetMeshes(
        LevelScene scene, string directory, List<string> written)
    {
        const string subdirectory = "Meshes";
        string meshDirectory = Path.Combine(directory, subdirectory);
        Directory.CreateDirectory(meshDirectory);

        var files = new Dictionary<string, string>(StringComparer.Ordinal);

        foreach (var group in scene.Instances.GroupBy(i => i.Asset))
        {
            var geometry = group.First().Geometry;
            if (geometry.Vertices.Count == 0) continue;

            string stem = Sanitise(group.Key.ObjectName) + "_" + group.Key.ExportIndex;
            string relative = subdirectory + "/" + stem + ".obj";
            string path = Path.Combine(meshDirectory, stem + ".obj");

            File.WriteAllText(path, BuildAssetObj(group.Key.ObjectName, geometry));
            files[group.Key.Key] = relative;
            written.Add(path);
        }

        return files;
    }

    /// <summary>One asset's geometry, untransformed.</summary>
    private static string BuildAssetObj(string name, Mesh.MeshGeometry geometry)
    {
        var builder = new StringBuilder();
        var culture = CultureInfo.InvariantCulture;

        builder.Append("# BioShockStudio asset mesh: ").AppendLine(name);
        builder.AppendLine("# local space, right-handed, +X forward, +Y left, +Z up, centimetres");
        builder.Append("o ").AppendLine(Sanitise(name));

        foreach (var vertex in geometry.Vertices)
        {
            builder.Append("v ").Append(vertex.Position.X.ToString("0.####", culture)).Append(' ')
                   .Append(vertex.Position.Y.ToString("0.####", culture)).Append(' ')
                   .Append(vertex.Position.Z.ToString("0.####", culture)).AppendLine();
        }

        var indices = geometry.Indices;
        for (int i = 0; i + 2 < indices.Count; i += 3)
        {
            builder.Append("f ")
                   .Append(indices[i] + 1).Append(' ')
                   .Append(indices[i + 1] + 1).Append(' ')
                   .Append(indices[i + 2] + 1).AppendLine();
        }

        return builder.ToString();
    }

    public static string BuildObj(LevelScene scene)
    {
        var builder = new StringBuilder();
        var culture = CultureInfo.InvariantCulture;

        builder.Append("# BioShockStudio level export: ").AppendLine(scene.PackageName);
        builder.AppendLine("# right-handed, +X forward, +Y left, +Z up, centimetres");
        builder.Append("# ").Append(scene.Instances.Count).Append(" instances, ")
               .Append(scene.TriangleCount).AppendLine(" triangles");

        int vertexOffset = 1;   // OBJ indices are 1-based.

        foreach (var instance in scene.Instances)
        {
            builder.Append("o ").Append(Sanitise(instance.Actor.ObjectName)).Append('_')
                   .Append(instance.Actor.ExportIndex).AppendLine();

            foreach (var vertex in instance.Geometry.Vertices)
            {
                var p = Vector3.Transform(vertex.Position, instance.Transform);
                builder.Append("v ").Append(p.X.ToString("0.####", culture)).Append(' ')
                       .Append(p.Y.ToString("0.####", culture)).Append(' ')
                       .Append(p.Z.ToString("0.####", culture)).AppendLine();
            }

            var indices = instance.Geometry.Indices;
            for (int i = 0; i + 2 < indices.Count; i += 3)
            {
                builder.Append("f ")
                       .Append(indices[i] + vertexOffset).Append(' ')
                       .Append(indices[i + 1] + vertexOffset).Append(' ')
                       .Append(indices[i + 2] + vertexOffset).AppendLine();
            }

            vertexOffset += instance.Geometry.Vertices.Count;
        }

        return builder.ToString();
    }

    private static string Sanitise(string name)
    {
        var builder = new StringBuilder(name.Length);
        foreach (char c in name) builder.Append(char.IsLetterOrDigit(c) || c is '_' or '-' ? c : '_');
        return builder.ToString();
    }

    private static float[] ToArray(Vector3 v) => [v.X, v.Y, v.Z];

    private static float[] ToArray(Matrix4x4 m) =>
    [
        m.M11, m.M12, m.M13, m.M14,
        m.M21, m.M22, m.M23, m.M24,
        m.M31, m.M32, m.M33, m.M34,
        m.M41, m.M42, m.M43, m.M44,
    ];

    /// <summary>
    /// Preserves the actual UE package reference alongside the convenient display name. A name is
    /// not an identity: it can repeat under different outers and an import can name a different
    /// package entirely.
    /// </summary>
    private static LevelReferenceDocument? Describe(AssetReference? reference) => reference is null
        ? null
        : new LevelReferenceDocument
        {
            Index = reference.Index.Value,
            ObjectName = reference.ObjectName,
            ClassName = reference.ClassName,
            Origin = reference.Origin,
            Status = reference.Status.ToString(),
            SourceKey = reference.Source?.Key,
            SourcePackage = reference.Source?.Package,
            SourceExportIndex = reference.Source?.ExportIndex,
        };
}

/// <summary>The level scene's serialised shape.</summary>
public sealed record LevelDocument
{
    public required int FormatVersion { get; init; }
    public required string Package { get; init; }
    public required string Generator { get; init; }
    public required string Basis { get; init; }
    public required float[] BoundsMin { get; init; }
    public required float[] BoundsMax { get; init; }
    public required bool GeometryEmbedded { get; init; }
    public required List<LevelAssetDocument> Assets { get; init; }
    public required List<LevelInstanceDocument> Instances { get; init; }
    public required List<LevelActorDocument> Actors { get; init; }
    public required List<LevelLightDocument> Lights { get; init; }

    /// <summary>Every placed actor class, including those the current geometry exporter cannot yet represent.</summary>
    public required List<LevelActorCoverageDocument> ActorCoverage { get; init; }

    /// <summary>Actors whose geometry did not decode. Written even when empty, so the file states it.</summary>
    public required List<string> Skipped { get; init; }
}

public sealed record LevelAssetDocument
{
    public required string Key { get; init; }
    public required string Name { get; init; }
    public required string Kind { get; init; }
    public required int ExportIndex { get; init; }
    public required int VertexCount { get; init; }
    public required int TriangleCount { get; init; }
    public List<float[]>? Vertices { get; init; }
    public List<float[]>? Normals { get; init; }
    public List<float[]>? Uvs { get; init; }
    public List<int>? Indices { get; init; }
    public required List<LevelSectionDocument> Sections { get; init; }

    /// <summary>
    /// Path of this asset's local-space mesh, relative to the manifest, when one was written.
    /// </summary>
    /// <remarks>
    /// Null when the export did not request <see cref="LevelExportFormats.AssetMeshes"/>. An
    /// importer with no file here can still place the actor, it just has no geometry to attach.
    /// </remarks>
    public string? File { get; init; }
}

public sealed record LevelSectionDocument
{
    public required int FirstIndex { get; init; }
    public required int TriangleCount { get; init; }

    /// <summary>Material object name, retained for quick human inspection.</summary>
    public string? Material { get; init; }

    /// <summary>
    /// Stable source identity for <see cref="Material"/>. Names alone are not unique in a
    /// package, so an importer must use this identity when locating or creating a UE5 material.
    /// </summary>
    public string? MaterialKey { get; init; }
    public string? MaterialPackage { get; init; }
    public string? MaterialClassName { get; init; }
    public int? MaterialExportIndex { get; init; }
}

public sealed record LevelInstanceDocument
{
    public required string Asset { get; init; }

    /// <summary>Stable key of the actor that placed this instance; unlike <see cref="Actor"/> it is unique.</summary>
    public required string ActorKey { get; init; }
    public required string Actor { get; init; }
    public string? Label { get; init; }
    public required float[] Transform { get; init; }
}

/// <summary>
/// A typed placeholder for one placed UE2 actor. The raw property bytes are retained alongside
/// their declared type so an unsupported UE5 component can be revisited without reparsing the map.
/// </summary>
public sealed record LevelActorDocument
{
    public required string Key { get; init; }
    public required string Name { get; init; }
    public required string ClassName { get; init; }
    public required int ExportIndex { get; init; }
    public string? Label { get; init; }
    public string? Tag { get; init; }
    public required float[] Location { get; init; }
    public required int[] Rotation { get; init; }
    public required float DrawScale { get; init; }
    public required float[] DrawScale3D { get; init; }
    public required float[] PrePivot { get; init; }
    public LevelRegionDocument? Region { get; init; }
    public List<string> TrainingConcepts { get; init; } = [];
    public LevelSpawnerActorDocument? Spawner { get; init; }
    public LevelReferenceDocument? Cubemap { get; init; }
    public LevelProjectorActorDocument? Projector { get; init; }
    public LevelHavokForceActorDocument? HavokForce { get; init; }
    public LevelReferenceDocument? LootSlot { get; init; }
    public LevelRegionActorDocument? RegionActor { get; init; }
    public string? StaticMesh { get; init; }
    public string? SkeletalMesh { get; init; }
    public string? Brush { get; init; }
    public string? Attachment { get; init; }
    public LevelReferenceDocument? StaticMeshReference { get; init; }
    public LevelReferenceDocument? SkeletalMeshReference { get; init; }
    public LevelReferenceDocument? BrushReference { get; init; }
    public LevelReferenceDocument? AttachmentReference { get; init; }
    public required List<LevelReferenceDocument?> MaterialOverrides { get; init; }
    public LevelNavigationDocument? Navigation { get; init; }
    public LevelScriptActionsDocument? ScriptActions { get; init; }
    public LevelEmittersDocument? Emitters { get; init; }
    public required List<string> Groups { get; init; }
    public required List<LevelPropertyDocument> Properties { get; init; }
    public required string TrailerHex { get; init; }
    public required bool Truncated { get; init; }
}

public sealed record LevelSpawnerActorDocument
{
    public string? GlobalPatrol { get; init; }
    public string? InitialPatrol { get; init; }
    public string? RepopulationPatrol { get; init; }
    public string? InitialLabel { get; init; }
    public required List<string> GlobalAiTypes { get; init; }
    public required List<string> InitialAiTypes { get; init; }
    public required List<string> RepopulationAiTypes { get; init; }
    public required List<string> OverriddenAiArchetypeNames { get; init; }
    public required List<string> SpawnZones { get; init; }
    public required bool Complete { get; init; }
}

public sealed record LevelProjectorActorDocument
{
    public LevelReferenceDocument? Material { get; init; }
    public float[]? Tile { get; init; }
    public int? MaxTraceDistance { get; init; }
    public int? ZBiasOverride { get; init; }
    public float? ScaleInTime { get; init; }
    public float? FadeInEnd { get; init; }
    public float? FadeOutStart { get; init; }
    public bool? ProjectOnBackfaces { get; init; }
    public bool? ProjectStaticMesh { get; init; }
    public bool? ProjectSkeletalMesh { get; init; }
    public bool? ShouldBeAttached { get; init; }
    public required bool Complete { get; init; }
}

public sealed record LevelHavokForceActorDocument
{
    public required LevelReferenceDocument ForceType { get; init; }
    public required LevelReferenceDocument ForceShape { get; init; }
    public LevelReferenceDocument? ForceFilter { get; init; }
    public required bool Complete { get; init; }
}

public sealed record LevelRegionDocument
{
    public required int Leaf { get; init; }
    public required byte ZoneNumber { get; init; }
}

/// <summary>Byte-backed collision and trigger schema for UE2 region actors.</summary>
public sealed record LevelRegionActorDocument
{
    public LevelActorScaleDocument? MainScale { get; init; }
    public LevelActorScaleDocument? PostScale { get; init; }
    public bool? BlockActors { get; init; }
    public bool? BlockHavok { get; init; }
    public bool? BlockNonZeroExtentTraces { get; init; }
    public bool? BlockPlayers { get; init; }
    public bool? BlockZeroExtentTraces { get; init; }
    public bool? CollideActors { get; init; }
    public bool? Disabled { get; init; }
    public bool? Enabled { get; init; }
    public bool? TriggerOnlyOnce { get; init; }
    public bool? TriggerWhenNotSeen { get; init; }
    public float? CollisionRadius { get; init; }
    public float? CollisionHeight { get; init; }
    public float? MinimumDistance { get; init; }
    public string? TriggeredBy { get; init; }
    public required List<string> TriggerOnlyByLabels { get; init; }
    public required List<string> TriggeredByFilter { get; init; }
    public required List<LevelReferenceDocument?> TriggerOnlyByClasses { get; init; }
    public LevelReferenceDocument? WaterMesh { get; init; }
    public byte? WaterAxis { get; init; }
    public float? MovingInWaterPenalty { get; init; }
    public int? Priority { get; init; }
    public bool? NoDelete { get; init; }
    public LevelZoneActorDocument? Zone { get; init; }
    public required bool Complete { get; init; }
}

public sealed record LevelActorScaleDocument
{
    public required float[] Scale { get; init; }
    public required float SheerRate { get; init; }
    public required byte SheerAxis { get; init; }
}

public sealed record LevelZoneAmbientDocument
{
    public float[]? VectorHigh { get; init; }
    public int[]? ColorHigh { get; init; }
    public float? ColorHighMultiplier { get; init; }
    public float? ColorLowMultiplier { get; init; }
    public float? ContrastPower { get; init; }
    public float? XGroundRatio { get; init; }
}

public sealed record LevelZoneFogDocument
{
    public bool? Enabled { get; init; }
    public bool? Clip { get; init; }
    public int[]? Color { get; init; }
    public float? Start { get; init; }
    public float? End { get; init; }
    public float? MaxContribution { get; init; }
}

public sealed record LevelZoneActorDocument
{
    public LevelZoneAmbientDocument? CurrentAmbient { get; init; }
    public LevelZoneAmbientDocument? NormalPressureAmbient { get; init; }
    public LevelZoneAmbientDocument? HighPressureAmbient { get; init; }
    public LevelZoneAmbientDocument? LowPressureAmbient { get; init; }
    public LevelZoneFogDocument? CurrentFog { get; init; }
    public LevelZoneFogDocument? NormalFog { get; init; }
    public LevelZoneFogDocument? HighFog { get; init; }
    public byte? ReverbType { get; init; }
    public string? MapUiRegion { get; init; }
    public string? PressureRegion { get; init; }
    public float? PressureEffectsDuration { get; init; }
    public float? TimeLastPressureChange { get; init; }
    public required List<string> SpawnZones { get; init; }
    public required List<string> EffectsContexts { get; init; }
    public required List<LevelReferenceDocument?> ManualExcludes { get; init; }
}

/// <summary>One actor property reference exactly as its package table identifies it.</summary>
public sealed record LevelReferenceDocument
{
    /// <summary>Signed UE package index: positive export, negative import.</summary>
    public required int Index { get; init; }
    public required string ObjectName { get; init; }
    public required string ClassName { get; init; }
    public required string Origin { get; init; }
    public required string Status { get; init; }
    public string? SourceKey { get; init; }
    public string? SourcePackage { get; init; }
    public int? SourceExportIndex { get; init; }
}

/// <summary>Byte-backed navigation references retained for a later UE5 NavGraph/SmartObject decision.</summary>
public sealed record LevelNavigationDocument
{
    public required List<LevelReferenceDocument?> PathLinks { get; init; }
    public required List<LevelReferenceDocument?> AutoGeneratedFlyingPathNodes { get; init; }
    public float? PathCollisionRadius { get; init; }
    public required bool AutoGeneratedFlagSerialized { get; init; }
}

/// <summary>Byte-backed Script action identities; no UE5 behavioural mapping is implied.</summary>
public sealed record LevelScriptActionsDocument
{
    public required bool Complete { get; init; }
    public required List<LevelReferenceDocument?> Actions { get; init; }
}

/// <summary>Byte-backed effect-template identities; no Niagara conversion is implied.</summary>
public sealed record LevelEmittersDocument
{
    public required bool Complete { get; init; }
    public required List<LevelEmitterTemplateDocument> Templates { get; init; }
}

/// <summary>Known emitter-template fields; unsupported template properties remain in source bytes.</summary>
public sealed record LevelEmitterTemplateDocument
{
    public required LevelReferenceDocument? Source { get; init; }
    public LevelReferenceDocument? Material { get; init; }
    public int? MaxParticles { get; init; }
    public float? ParticlesPerSecond { get; init; }
    public float? InitialParticlesPerSecond { get; init; }
    public required bool PropertiesComplete { get; init; }
}

public sealed record LevelPropertyDocument
{
    public required string Name { get; init; }
    public required string Type { get; init; }
    public string? StructName { get; init; }
    public required int ArrayIndex { get; init; }
    public string? ValueHex { get; init; }
    public required int ValueLength { get; init; }
    public required string ValueSha256 { get; init; }
}

public sealed record LevelLightDocument
{
    /// <summary>Stable source identity; display names are not used for UE5 update matching.</summary>
    public required string Key { get; init; }
    public required string Name { get; init; }
    public required string ClassName { get; init; }
    public required int ExportIndex { get; init; }
    public required float[] Location { get; init; }
    public int[]? Color { get; init; }
    public float? Brightness { get; init; }
    public float? Radius { get; init; }
}

public sealed record LevelActorCoverageDocument
{
    public required string ClassName { get; init; }
    public required int ActorCount { get; init; }
    public required Dictionary<string, int> Status { get; init; }
    public required List<string> OutstandingProperties { get; init; }
}
