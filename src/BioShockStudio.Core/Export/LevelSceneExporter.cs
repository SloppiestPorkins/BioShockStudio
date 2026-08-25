using System.Globalization;
using System.Numerics;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Security.Cryptography;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;

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

    /// <summary>
    /// Writes the requested formats into <paramref name="directory"/> and returns the paths.
    /// </summary>
    /// <param name="package">
    /// The package <paramref name="scene"/> was built from, still open. Optional — materials and
    /// cubemap faces only. Everything else <see cref="LevelScene"/> already carries in memory. Omit
    /// it and the export proceeds with neither resolved, rather than failing; the caller must keep
    /// the package open across this call if it wants them, since resolving means reading export bytes.
    /// </param>
    public static IReadOnlyList<string> Write(
        LevelScene scene, string directory, LevelExportFormats formats = LevelExportFormats.All,
        bool readable = false, BioShockPackage? package = null, BulkTextureCatalog? bulk = null)
    {
        Directory.CreateDirectory(directory);
        var written = new List<string>();

        // Written before either JSON, because both manifests record each material's texture paths.
        List<(Level.SourceId Id, SceneMaterial Material)> materials = [];
        List<FbxTextureEntry> textures = [];
        List<LevelCubemapDocument> cubemaps = [];
        if (package is not null
            && (formats.HasFlag(LevelExportFormats.SceneJson) || formats.HasFlag(LevelExportFormats.Ue5Manifest)))
        {
            (materials, textures) = WriteMaterials(package, scene, directory, written, bulk);
            cubemaps = WriteCubemaps(package, scene, directory, written, bulk);
        }

        if (formats.HasFlag(LevelExportFormats.SceneJson))
        {
            string path = Path.Combine(directory, scene.PackageName + ".level.json");
            File.WriteAllText(path, JsonSerializer.Serialize(
                ToDocument(scene, materials: materials, textures: textures, cubemaps: cubemaps, package: package),
                readable ? ReadableOptions : Options));
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
                ToDocument(scene, includeGeometry: false, assetFiles, materials, textures, cubemaps, package: package),
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
        IReadOnlyDictionary<string, string>? assetFiles = null,
        IReadOnlyList<(Level.SourceId Id, SceneMaterial Material)>? materials = null,
        IReadOnlyList<FbxTextureEntry>? textures = null,
        IReadOnlyList<LevelCubemapDocument>? cubemaps = null,
        BioShockPackage? package = null) => new()
    {
        FormatVersion = LevelManifestVersion,
        Package = scene.PackageName,
        Generator = "BioShockStudio",
        Basis = "right-handed, +X forward, +Y left, +Z up, centimetres",
        BoundsMin = ToArray(scene.Bounds.Min),
        BoundsMax = ToArray(scene.Bounds.Max),
        GeometryEmbedded = includeGeometry,
        Materials = materials?.Select(pair => MaterialDocument(pair.Id, pair.Material)).ToList() ?? [],
        Textures = textures?.ToList() ?? [],
        Cubemaps = cubemaps?.ToList() ?? [],
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
                Group = AssetGroup(package, g.First()),
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
                HavokConstraint = actor.HavokConstraint is null ? null : new LevelHavokConstraintActorDocument
                {
                    AttachedActorA = Describe(actor.HavokConstraint.AttachedActorA)!,
                    AttachedActorB = Describe(actor.HavokConstraint.AttachedActorB),
                    DisableCollisions = actor.HavokConstraint.DisableCollisions,
                    UseLimitedHinge = actor.HavokConstraint.UseLimitedHinge,
                    LimitedHingeFrictionValue = actor.HavokConstraint.LimitedHingeFrictionValue,
                    LimitedHingeTauFactor = actor.HavokConstraint.LimitedHingeTauFactor,
                    Complete = actor.HavokConstraint.Complete,
                },
                AntiPortal = Describe(actor.AntiPortal),
                MapUiMarker = actor.MapUiMarker is null ? null : new LevelMapUiMarkerDocument
                {
                    LayerName = actor.MapUiMarker.LayerName,
                    ScaleMarkerName = actor.MapUiMarker.ScaleMarkerName,
                    RegionNames = actor.MapUiMarker.RegionNames.ToList(),
                    Complete = actor.MapUiMarker.Complete,
                },
                Vending = actor.Vending is null ? null : new LevelVendingActorDocument
                {
                    VendingTableName = actor.Vending.VendingTableName,
                    VendingTable = Describe(actor.Vending.VendingTable)!,
                    HackInfoName = actor.Vending.HackInfoName,
                    StaticMeshInstance = Describe(actor.Vending.StaticMeshInstance)!,
                    DestructionNotification = actor.Vending.DestructionNotification,
                    CanBeHacked = actor.Vending.CanBeHacked,
                    Complete = actor.Vending.Complete,
                },
                Interaction = actor.Interaction is null ? null : new LevelInteractionActorDocument
                {
                    DoorLabel = actor.Interaction.DoorLabel,
                    HackInfoName = actor.Interaction.HackInfoName,
                    Hackable = actor.Interaction.Hackable,
                    ShowHudElements = actor.Interaction.ShowHudElements,
                },
                LevelInfo = actor.LevelInfo is null ? null : new LevelInfoActorDocument
                {
                    TimeSeconds = actor.LevelInfo.TimeSeconds,
                    Title = actor.LevelInfo.Title,
                    FictionalMapName = actor.LevelInfo.FictionalMapName,
                    Summary = Describe(actor.LevelInfo.Summary),
                    SpawningManager = Describe(actor.LevelInfo.SpawningManager),
                    GlowSettings = Describe(actor.LevelInfo.GlowSettings),
                    ToneMapSettings = Describe(actor.LevelInfo.ToneMapSettings),
                    LevelAnimInfo = Describe(actor.LevelInfo.LevelAnimInfo),
                    HasPathNodes = actor.LevelInfo.HasPathNodes,
                    CameraLocationDynamic = actor.LevelInfo.CameraLocationDynamic is { } dynamicLocation ? ToArray(dynamicLocation) : null,
                    CameraLocationTop = actor.LevelInfo.CameraLocationTop is { } top ? ToArray(top) : null,
                    CameraLocationFront = actor.LevelInfo.CameraLocationFront is { } front ? ToArray(front) : null,
                    CameraLocationSide = actor.LevelInfo.CameraLocationSide is { } side ? ToArray(side) : null,
                    CameraRotationDynamic = actor.LevelInfo.CameraRotationDynamic is { } rotation
                        ? [rotation.Pitch, rotation.Yaw, rotation.Roll] : null,
                    NavigationPoints = actor.LevelInfo.NavigationPoints.Select(reference => Describe(reference)!).ToList(),
                    PressureRegions = actor.LevelInfo.PressureRegions.Select(region =>
                        new LevelPressureRegionDocument(region.Name, region.Pressure, region.EffectsDuration)).ToList(),
                    MapUiRegions = actor.LevelInfo.MapUiRegions.Select(region =>
                        new LevelMapUiRegionDocument(region.MapUiRegion, region.HudRegion, region.Revealed, region.LastVisited)).ToList(),
                    MapHudRegions = actor.LevelInfo.MapHudRegions.Select(region =>
                        new LevelMapHudRegionDocument(region.HudRegion, region.Description)).ToList(),
                    RequiredAnimationGroups = actor.LevelInfo.RequiredAnimationGroups.Select(group =>
                        new LevelRequiredAnimationGroupDocument(group.PackageName, group.GroupName)).ToList(),
                    AmbientXGroundRatio = actor.LevelInfo.AmbientXGroundRatio,
                    AmbientColorHighMultiplier = actor.LevelInfo.AmbientColorHighMultiplier,
                    AmbientColorLowMultiplier = actor.LevelInfo.AmbientColorLowMultiplier,
                    AmbientContrastPower = actor.LevelInfo.AmbientContrastPower,
                    Complete = actor.LevelInfo.Complete,
                },
                ShockAiScout = actor.ShockAiScout is null ? null : new LevelShockAiScoutDocument
                {
                    PointCollectionReferences = actor.ShockAiScout.PointCollectionReferences.ToList(),
                    LastPathfindingOrigin = actor.ShockAiScout.LastPathfindingOrigin is { } origin ? ToArray(origin) : null,
                    LastPathfindingLocation = actor.ShockAiScout.LastPathfindingLocation is { } pathLocation ? ToArray(pathLocation) : null,
                    LastPathfindingTime = actor.ShockAiScout.LastPathfindingTime,
                    LastPathfindingFailedTime = actor.ShockAiScout.LastPathfindingFailedTime,
                    LastPathfindingResult = actor.ShockAiScout.LastPathfindingResult,
                    Controller = Describe(actor.ShockAiScout.Controller),
                    JumpCapable = actor.ShockAiScout.JumpCapable,
                    CanFly = actor.ShockAiScout.CanFly,
                    CanUseCeiling = actor.ShockAiScout.CanUseCeiling,
                    LastValidAnchorTime = actor.ShockAiScout.LastValidAnchorTime,
                    Floor = actor.ShockAiScout.Floor is { } floor ? ToArray(floor) : null,
                    HeadVolume = Describe(actor.ShockAiScout.HeadVolume),
                    CollisionRadius = actor.ShockAiScout.CollisionRadius,
                    CollisionHeight = actor.ShockAiScout.CollisionHeight,
                    DestructionNotification = actor.ShockAiScout.DestructionNotification,
                    Complete = actor.ShockAiScout.Complete,
                },
                Mover = actor.Mover is null ? null : new LevelMoverActorDocument
                {
                    InitialState = actor.Mover.InitialState,
                    TriggeredBy = actor.Mover.TriggeredBy,
                    BasePos = actor.Mover.BasePos is { } basePos ? ToArray(basePos) : null,
                    BaseRot = actor.Mover.BaseRot is { } baseRot
                        ? [baseRot.Pitch, baseRot.Yaw, baseRot.Roll] : null,
                    MoveTime = actor.Mover.MoveTime,
                    StayOpenTime = actor.Mover.StayOpenTime,
                    UseTriggered = actor.Mover.UseTriggered,
                    TriggerOnceOnly = actor.Mover.TriggerOnceOnly,
                    MoverEncroachType = actor.Mover.MoverEncroachType,
                    MoverGlideType = actor.Mover.MoverGlideType,
                    ResolvedTriggers = actor.Mover.ResolvedTriggers.Select(target => new LevelMoverTriggerTargetDocument
                    {
                        Name = target.Name,
                        Resolved = target.Resolved,
                        TargetExportIndex = target.TargetExportIndex,
                        TargetClassName = target.TargetClassName,
                    }).ToList(),
                    Complete = actor.Mover.Complete,
                },
                Door = actor.Door is null ? null : new LevelDoorActorDocument
                {
                    Portal = Describe(actor.Door.Portal),
                    Locked = actor.Door.Locked,
                    InitiallyOpen = actor.Door.InitiallyOpen,
                    OpenAnimationRate = actor.Door.OpenAnimationRate,
                    CloseAnimationRate = actor.Door.CloseAnimationRate,
                    DelayBeforeOpening = actor.Door.DelayBeforeOpening,
                    StayOpenDuration = actor.Door.StayOpenDuration,
                    Attachments = actor.Door.Attachments.Select(attachment => new LevelDoorAttachmentDocument
                    {
                        StaticMesh = Describe(attachment.StaticMesh),
                        AttachSocket = attachment.AttachSocket,
                        LocationOffset = attachment.LocationOffset is { } loc ? ToArray(loc) : null,
                        RotationOffset = attachment.RotationOffset is { } rot
                            ? [rot.Pitch, rot.Yaw, rot.Roll] : null,
                        InteractWithPhysicalObjects = attachment.InteractWithPhysicalObjects,
                    }).ToList(),
                    Complete = actor.Door.Complete,
                },
                DoorSwitch = actor.DoorSwitch is null ? null : new LevelDoorSwitchActorDocument
                {
                    DamageResistanceSetName = actor.DoorSwitch.DamageResistanceSetName,
                    UseVerbText = actor.DoorSwitch.UseVerbText,
                    OverlayMaterial = Describe(actor.DoorSwitch.OverlayMaterial),
                    Complete = actor.DoorSwitch.Complete,
                },
                ScriptedSequence = actor.ScriptedSequence is null ? null : new LevelScriptedSequenceDocument
                {
                    Entries = actor.ScriptedSequence.Entries.Select(entry => new LevelScriptedSequenceEntryDocument
                    {
                        Animations = entry.Animations.Select(choice => new LevelScriptedAnimationChoiceDocument
                        {
                            Animation = choice.Animation,
                            Chance = choice.Chance,
                        }).ToList(),
                        LoopCount = entry.LoopCount is { } loop ? ToArray(loop) : null,
                        RunNext = entry.RunNext,
                        TotalChance = entry.TotalChance,
                    }).ToList(),
                    Complete = actor.ScriptedSequence.Complete,
                },
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
                        AutomaticInitialSpawning = template.AutomaticInitialSpawning,
                        RespawnDeadParticles = template.RespawnDeadParticles,
                        LifetimeRange = ToArray(template.LifetimeRange),
                        StartSizeRange = ToArray(template.StartSizeRange),
                        UniformSize = template.UniformSize,
                        UseSizeScale = template.UseSizeScale,
                        UseRegularSizeScale = template.UseRegularSizeScale,
                        SizeScale = ToDocument(template.SizeScale),
                        StartVelocityRange = ToArray(template.StartVelocityRange),
                        Acceleration = template.Acceleration is { } acceleration ? ToArray(acceleration) : null,
                        VelocityScale = ToDocument(template.VelocityScale),
                        StartLocationRange = ToArray(template.StartLocationRange),
                        StartLocationOffset = template.StartLocationOffset is { } offset ? ToArray(offset) : null,
                        StartLocationShape = template.StartLocationShape,
                        StartSpinRange = ToArray(template.StartSpinRange),
                        SpinsPerSecondRange = ToArray(template.SpinsPerSecondRange),
                        SpinParticles = template.SpinParticles,
                        UseColorScale = template.UseColorScale,
                        ColorScale = ToDocument(template.ColorScale),
                        Blending = template.Blending,
                        CoordinateSystem = template.CoordinateSystem,
                        TextureUSubdivisions = template.TextureUSubdivisions,
                        TextureVSubdivisions = template.TextureVSubdivisions,
                        StaticMesh = Describe(template.StaticMesh),
                        SegmentSizeScale = ToDocument(template.SegmentSizeScale),
                        SegmentColorScale = ToDocument(template.SegmentColorScale),
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

    /// <summary>
    /// For a SkeletalMesh instance, the game's own top-level character/rig grouping — the identity
    /// a later import step needs to find or trigger that rig's own export, since this level export
    /// only ever decodes bind-pose geometry for it. Null for anything else, or when no package was
    /// open to resolve it (materials-only, like <see cref="WriteMaterials"/>).
    /// </summary>
    private static string? AssetGroup(BioShockPackage? package, LevelInstance instance)
    {
        if (package is null || instance.Kind != LevelGeometryKind.SkeletalMesh) return null;

        int exportIndex = instance.Asset.ExportIndex;
        if (exportIndex < 0 || exportIndex >= package.Exports.Count) return null;

        return AssetContextResolver.TopLevelGroup(package, package.Exports[exportIndex]);
    }

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

    /// <summary>
    /// Resolves every distinct material a placed asset's sections name and writes its textures
    /// beside the scene, the same way <see cref="WriteAssetMeshes"/> does for geometry. Needs the
    /// package the scene was built from still open — <see cref="LevelScene"/> itself only carries
    /// each material's identity (<see cref="Level.SourceId"/>), not its resolved texture bindings,
    /// because resolving means reading the material export's own bytes.
    /// </summary>
    /// <remarks>
    /// Each result is paired with the <see cref="Level.SourceId"/> a section actually names —
    /// <b>not</b> necessarily the same export the returned <see cref="SceneMaterial"/> describes.
    /// A <c>MaterialSwitch</c> reference resolves to its default child (<see cref="MaterialReader"/>
    /// follows it), so the child's own class/name/index ride in the <see cref="SceneMaterial"/> while
    /// the section's <c>MaterialKey</c> still names the switch. Keying the written
    /// <see cref="LevelMaterialDocument"/> by the child's identity instead of the switch's would
    /// build a manifest that looks complete — non-empty materials, real textures on disk — while
    /// every switch-routed section's key silently finds nothing. Pinned by
    /// <c>LevelSceneTests.MaterialsResolveAndTheirTexturesAreWrittenForAPlacedLevel</c>.
    /// </remarks>
    private static (List<(Level.SourceId Id, SceneMaterial Material)> Materials, List<FbxTextureEntry> Textures)
        WriteMaterials(BioShockPackage package, LevelScene scene, string directory, List<string> written, BulkTextureCatalog? bulk = null)
    {
        var materials = new List<(Level.SourceId Id, SceneMaterial Material)>();
        var textures = new List<FbxTextureEntry>();
        var seenMaterials = new HashSet<Level.SourceId>();
        var seenTextures = new HashSet<string>(StringComparer.Ordinal);

        foreach (var group in scene.Instances.GroupBy(i => i.Asset))
        {
            foreach (var materialId in group.First().Materials)
            {
                if (materialId is not { } id || !seenMaterials.Add(id)) continue;
                if (id.ExportIndex >= package.Exports.Count) continue;

                var resolved = MaterialExporter.ResolveMaterial(package, package.Exports[id.ExportIndex], directory, bulk);
                if (resolved is null) continue;
                materials.Add((id, resolved));

                foreach (var (slot, file) in resolved.Textures)
                {
                    if (!resolved.TextureIntents.TryGetValue(slot, out var intent)) continue;
                    if (!seenTextures.Add(resolved.Name + "|" + slot)) continue;

                    textures.Add(new FbxTextureEntry
                    {
                        File = file,
                        Slot = slot,
                        Material = resolved.Name,
                        Usage = intent.Usage.ToString(),
                        ColourSpace = intent.ColourSpace.ToString(),
                        AddressU = intent.AddressU.ToString(),
                        AddressV = intent.AddressV.ToString(),
                        DeclaresMasked = intent.DeclaresMasked,
                        DeclaresAlphaTexture = intent.DeclaresAlphaTexture,
                    });
                }
            }
        }

        foreach (string relative in materials.SelectMany(m => m.Material.Textures.Values).Distinct(StringComparer.Ordinal))
            written.Add(Path.Combine(directory, relative));

        return (materials, textures);
    }

    /// <summary>
    /// Writes the six face PNGs for every <c>Cubemap</c> a <c>CubemapProbe</c> names, in the
    /// array's declaration order. Face-to-axis mapping stays <c>UNKNOWN</c>
    /// (<c>docs/research/textures.md</c>) — this does not assemble a TextureCube.
    /// </summary>
    private static List<LevelCubemapDocument> WriteCubemaps(
        BioShockPackage package, LevelScene scene, string directory, List<string> written,
        BulkTextureCatalog? bulk)
    {
        var result = new List<LevelCubemapDocument>();
        var seen = new HashSet<int>();

        foreach (var actor in scene.Actors)
        {
            if (actor.Cubemap is not { Status: ResolutionStatus.Resolved, Source: { } source }) continue;
            if (!seen.Add(source.ExportIndex)) continue;
            if (source.ExportIndex < 0 || source.ExportIndex >= package.Exports.Count) continue;

            var decoded = CubemapReader.Read(package, package.Exports[source.ExportIndex], bulk);
            if (decoded is null) continue;

            var faces = new List<LevelCubemapFaceDocument>(decoded.Faces.Count);
            for (int i = 0; i < decoded.Faces.Count; i++)
            {
                var face = decoded.Faces[i];
                string? file = MaterialExporter.WritePng(face, directory);
                if (file is not null) written.Add(Path.Combine(directory, file.Replace('/', Path.DirectorySeparatorChar)));
                faces.Add(new LevelCubemapFaceDocument
                {
                    Index = i,
                    ObjectName = face.Name,
                    File = file,
                });
            }

            result.Add(new LevelCubemapDocument
            {
                Name = decoded.Name,
                ExportIndex = source.ExportIndex,
                Complete = decoded.IsComplete,
                UnreadableFaces = decoded.UnreadableFaces.ToList(),
                Faces = faces,
            });
        }

        return result;
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

        // UE5's OBJ importer has no other source of texture coordinates for this path, so a
        // missing "vt" here is not a cosmetic gap: every material assigned post-import samples
        // whatever default/absent UV the importer falls back to. Same V-flip as FbxSceneBuilder's
        // proven-correct convention (`1 - v`), for the same reason — kept consistent so this path
        // and the rig FBX path cannot disagree about which way up a texture reads.
        foreach (var vertex in geometry.Vertices)
        {
            builder.Append("vt ").Append(vertex.Uv.X.ToString("0.####", culture)).Append(' ')
                   .Append((1.0f - vertex.Uv.Y).ToString("0.####", culture)).AppendLine();
        }

        var indices = geometry.Indices;
        if (geometry.Sections.Count == 0)
        {
            // No section table -- some geometry (compiled-world brushes) carries none. Every face
            // in one ungrouped run, exactly as before this method split by section.
            for (int i = 0; i + 2 < indices.Count; i += 3)
            {
                builder.Append("f ")
                       .Append(indices[i] + 1).Append('/').Append(indices[i] + 1).Append(' ')
                       .Append(indices[i + 1] + 1).Append('/').Append(indices[i + 1] + 1).Append(' ')
                       .Append(indices[i + 2] + 1).Append('/').Append(indices[i + 2] + 1).AppendLine();
            }
        }
        else
        {
            // One "usemtl" per section, no "g" -- a "g" line would make some importers treat each
            // section as a separate mesh object rather than one mesh with several material slots,
            // the opposite of what section-per-material assignment needs. The name only has to be
            // distinct and stable in order: the importer assigns real materials by this position,
            // not by parsing the string.
            for (int s = 0; s < geometry.Sections.Count; s++)
            {
                var section = geometry.Sections[s];
                builder.Append("usemtl BioShock_").Append(s).AppendLine();

                int end = section.FirstIndex + section.TriangleCount * 3;
                for (int i = section.FirstIndex; i < end; i += 3)
                {
                    builder.Append("f ")
                           .Append(indices[i] + 1).Append('/').Append(indices[i] + 1).Append(' ')
                           .Append(indices[i + 1] + 1).Append('/').Append(indices[i + 1] + 1).Append(' ')
                           .Append(indices[i + 2] + 1).Append('/').Append(indices[i + 2] + 1).AppendLine();
                }
            }
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

    /// <summary>A <c>Range</c> as <c>[Min, Max]</c>, or null when the field was not serialised.</summary>
    private static float[]? ToArray(FloatRange? range) =>
        range is { } r ? [r.Min, r.Max] : null;

    /// <summary>A <c>RangeVector</c> as <c>[MinX, MaxX, MinY, MaxY, MinZ, MaxZ]</c>.</summary>
    private static float[]? ToArray(AxisRange? axis) =>
        axis is { } a ? [a.X.Min, a.X.Max, a.Y.Min, a.Y.Max, a.Z.Min, a.Z.Max] : null;

    private static List<LevelFloatCurveKeyDocument>? ToDocument(IReadOnlyList<FloatCurveKey>? curve) =>
        curve?.Select(key => new LevelFloatCurveKeyDocument { RelativeTime = key.RelativeTime, Value = key.Value }).ToList();

    private static List<LevelColorCurveKeyDocument>? ToDocument(IReadOnlyList<ColorCurveKey>? curve) =>
        curve?.Select(key => new LevelColorCurveKeyDocument
        {
            RelativeTime = key.RelativeTime,
            Color = [key.Color.R, key.Color.G, key.Color.B, key.Color.A],
        }).ToList();

    private static List<LevelVectorCurveKeyDocument>? ToDocument(IReadOnlyList<VectorCurveKey>? curve) =>
        curve?.Select(key => new LevelVectorCurveKeyDocument { RelativeTime = key.RelativeTime, Value = ToArray(key.Value) }).ToList();

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

    /// <summary>
    /// Keyed by the <see cref="Level.SourceId"/> a section actually names, not by the resolved
    /// material's own class/name/index — see <see cref="WriteMaterials"/>'s remarks on why those
    /// two can differ for a <c>MaterialSwitch</c>. This is what lets a
    /// <see cref="LevelSectionDocument.MaterialKey"/> find its entry in
    /// <see cref="LevelDocument.Materials"/> unconditionally.
    /// </summary>
    private static LevelMaterialDocument MaterialDocument(Level.SourceId id, SceneMaterial material) => new()
    {
        Key = id.Key,
        Name = material.Name,
        ClassName = material.ClassName,
        SourceFile = material.SourceFile,
        SourceExportIndex = material.SourceExportIndex,
        Diffuse = material.Diffuse,
        NormalMap = material.NormalMap,
        Specular = material.Specular,
        Glossiness = material.Glossiness,
        SpecularBrightness = material.SpecularBrightness,
        EmissiveBrightness = material.EmissiveBrightness,
        DiffuseColor = material.DiffuseColor,
        SpecularColor = material.SpecularColor,
        EmissiveColor = material.EmissiveColor,
        TwoSided = material.TwoSided,
        Masked = material.Masked,
        OutputBlending = material.OutputBlending,
        Animators = material.Animators.ToList(),
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

    /// <summary>
    /// Every distinct material a placed asset's sections name, resolved and with its textures
    /// already written beside the scene. Empty when the caller did not provide an open package to
    /// resolve them (<see cref="Write"/> only does this when a <c>package</c> is given, for the
    /// scene JSON and the UE5 manifest alike) — that is a scope choice, not a claim that the level
    /// has no materials.
    /// </summary>
    public required List<LevelMaterialDocument> Materials { get; init; }

    public required List<FbxTextureEntry> Textures { get; init; }

    /// <summary>
    /// Cubemaps named by this level's <c>CubemapProbe</c> actors, with face PNGs in declaration
    /// order. Empty when no package was open, or the map has no probes. Face-to-axis mapping is
    /// not recorded — it is <c>UNKNOWN</c>.
    /// </summary>
    public List<LevelCubemapDocument> Cubemaps { get; init; } = [];

    public required List<LevelAssetDocument> Assets { get; init; }
    public required List<LevelInstanceDocument> Instances { get; init; }
    public required List<LevelActorDocument> Actors { get; init; }
    public required List<LevelLightDocument> Lights { get; init; }

    /// <summary>Every placed actor class, including those the current geometry exporter cannot yet represent.</summary>
    public required List<LevelActorCoverageDocument> ActorCoverage { get; init; }

    /// <summary>Actors whose geometry did not decode. Written even when empty, so the file states it.</summary>
    public required List<string> Skipped { get; init; }
}

/// <summary>One shipped <c>Cubemap</c> named by a probe, faces in declaration order.</summary>
public sealed record LevelCubemapDocument
{
    public required string Name { get; init; }
    public required int ExportIndex { get; init; }
    public required bool Complete { get; init; }
    public required List<string> UnreadableFaces { get; init; }
    public required List<LevelCubemapFaceDocument> Faces { get; init; }
}

public sealed record LevelCubemapFaceDocument
{
    /// <summary>Index in the serialised <c>Faces</c> array, not a cube axis.</summary>
    public required int Index { get; init; }
    public required string ObjectName { get; init; }
    public string? File { get; init; }
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
    /// For a SkeletalMesh, the game's own top-level character/rig grouping its animation set and
    /// other mesh variants share — null for anything else, or when no package was open to resolve
    /// it.
    /// </summary>
    public string? Group { get; init; }

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

/// <summary>
/// One material a placed asset's sections name, resolved and with its textures already written
/// beside the scene. Field shape matches <c>SceneMaterial</c>/the rig manifest's own material
/// entries deliberately, so an importer can share the same UE5-side code between the two.
/// </summary>
public sealed record LevelMaterialDocument
{
    /// <summary>Matches a <see cref="LevelSectionDocument.MaterialKey"/>.</summary>
    public required string Key { get; init; }

    public required string Name { get; init; }
    public required string ClassName { get; init; }
    public string? SourceFile { get; init; }
    public required int SourceExportIndex { get; init; }
    public string? Diffuse { get; init; }
    public string? NormalMap { get; init; }
    public string? Specular { get; init; }
    public float? Glossiness { get; init; }
    public float? SpecularBrightness { get; init; }
    public float? EmissiveBrightness { get; init; }
    public float[]? DiffuseColor { get; init; }
    public float[]? SpecularColor { get; init; }
    public float[]? EmissiveColor { get; init; }
    public bool TwoSided { get; init; }
    public bool Masked { get; init; }
    public byte? OutputBlending { get; init; }

    /// <summary>
    /// UV/colour animators already decoded on <see cref="SceneMaterial.Animators"/>. Carried, not
    /// interpreted — panner/rotator units are <c>UNKNOWN</c>, so the UE5 importer must not invent
    /// a <c>MaterialExpressionPanner</c> from these numbers.
    /// </summary>
    public List<MaterialAnimator> Animators { get; init; } = [];
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
    public LevelHavokConstraintActorDocument? HavokConstraint { get; init; }
    public LevelReferenceDocument? AntiPortal { get; init; }
    public LevelMapUiMarkerDocument? MapUiMarker { get; init; }
    public LevelVendingActorDocument? Vending { get; init; }
    public LevelInteractionActorDocument? Interaction { get; init; }
    public LevelInfoActorDocument? LevelInfo { get; init; }
    public LevelShockAiScoutDocument? ShockAiScout { get; init; }
    public LevelMoverActorDocument? Mover { get; init; }
    public LevelDoorActorDocument? Door { get; init; }
    public LevelDoorSwitchActorDocument? DoorSwitch { get; init; }
    public LevelScriptedSequenceDocument? ScriptedSequence { get; init; }
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

public sealed record LevelHavokConstraintActorDocument
{
    public required LevelReferenceDocument AttachedActorA { get; init; }
    public LevelReferenceDocument? AttachedActorB { get; init; }
    public bool? DisableCollisions { get; init; }
    public bool? UseLimitedHinge { get; init; }
    public float? LimitedHingeFrictionValue { get; init; }
    public float? LimitedHingeTauFactor { get; init; }
    public required bool Complete { get; init; }
}

public sealed record LevelMapUiMarkerDocument
{
    public required string LayerName { get; init; }
    public required string ScaleMarkerName { get; init; }
    public required List<string> RegionNames { get; init; }
    public required bool Complete { get; init; }
}

public sealed record LevelVendingActorDocument
{
    public required string VendingTableName { get; init; }
    public required LevelReferenceDocument VendingTable { get; init; }
    public required string HackInfoName { get; init; }
    public required LevelReferenceDocument StaticMeshInstance { get; init; }
    public int? DestructionNotification { get; init; }
    public bool? CanBeHacked { get; init; }
    public required bool Complete { get; init; }
}

public sealed record LevelInteractionActorDocument
{
    public string? DoorLabel { get; init; }
    public string? HackInfoName { get; init; }
    public bool? Hackable { get; init; }
    public bool? ShowHudElements { get; init; }
}

public sealed record LevelInfoActorDocument
{
    public float? TimeSeconds { get; init; }
    public string? Title { get; init; }
    public string? FictionalMapName { get; init; }
    public LevelReferenceDocument? Summary { get; init; }
    public LevelReferenceDocument? SpawningManager { get; init; }
    public LevelReferenceDocument? GlowSettings { get; init; }
    public LevelReferenceDocument? ToneMapSettings { get; init; }
    public LevelReferenceDocument? LevelAnimInfo { get; init; }
    public bool? HasPathNodes { get; init; }
    public float[]? CameraLocationDynamic { get; init; }
    public float[]? CameraLocationTop { get; init; }
    public float[]? CameraLocationFront { get; init; }
    public float[]? CameraLocationSide { get; init; }
    public int[]? CameraRotationDynamic { get; init; }
    public required List<LevelReferenceDocument> NavigationPoints { get; init; }
    public required List<LevelPressureRegionDocument> PressureRegions { get; init; }
    public required List<LevelMapUiRegionDocument> MapUiRegions { get; init; }
    public required List<LevelMapHudRegionDocument> MapHudRegions { get; init; }
    public required List<LevelRequiredAnimationGroupDocument> RequiredAnimationGroups { get; init; }
    public float? AmbientXGroundRatio { get; init; }
    public float? AmbientColorHighMultiplier { get; init; }
    public float? AmbientColorLowMultiplier { get; init; }
    public float? AmbientContrastPower { get; init; }
    public required bool Complete { get; init; }
}

public sealed record LevelShockAiScoutDocument
{
    public required List<int> PointCollectionReferences { get; init; }
    public float[]? LastPathfindingOrigin { get; init; }
    public float[]? LastPathfindingLocation { get; init; }
    public float? LastPathfindingTime { get; init; }
    public float? LastPathfindingFailedTime { get; init; }
    public float? LastPathfindingResult { get; init; }
    public LevelReferenceDocument? Controller { get; init; }
    public bool? JumpCapable { get; init; }
    public bool? CanFly { get; init; }
    public bool? CanUseCeiling { get; init; }
    public float? LastValidAnchorTime { get; init; }
    public float[]? Floor { get; init; }
    public LevelReferenceDocument? HeadVolume { get; init; }
    public float? CollisionRadius { get; init; }
    public float? CollisionHeight { get; init; }
    public int? DestructionNotification { get; init; }
    public required bool Complete { get; init; }
}

/// <summary>
/// The typed subset of a <c>Mover</c>/<c>ScriptableMover</c>. The keyframe path
/// (<c>KeyPos</c>/<c>KeyRot</c>) is not included — see <c>docs/research/interaction.md</c>.
/// </summary>
public sealed record LevelMoverActorDocument
{
    public string? InitialState { get; init; }
    public string? TriggeredBy { get; init; }
    public float[]? BasePos { get; init; }
    public int[]? BaseRot { get; init; }
    public float? MoveTime { get; init; }
    public float? StayOpenTime { get; init; }
    public bool? UseTriggered { get; init; }
    public bool? TriggerOnceOnly { get; init; }
    public byte? MoverEncroachType { get; init; }
    public byte? MoverGlideType { get; init; }
    public required List<LevelMoverTriggerTargetDocument> ResolvedTriggers { get; init; }
    public required bool Complete { get; init; }
}

/// <summary>One <c>TriggeredBy</c> name, resolved against another actor's <c>Label</c> in the same package.</summary>
public sealed record LevelMoverTriggerTargetDocument
{
    public required string Name { get; init; }
    public required bool Resolved { get; init; }
    public int? TargetExportIndex { get; init; }
    public string? TargetClassName { get; init; }
}

public sealed record LevelDoorActorDocument
{
    public LevelReferenceDocument? Portal { get; init; }
    public bool? Locked { get; init; }
    public bool? InitiallyOpen { get; init; }
    public float? OpenAnimationRate { get; init; }
    public float? CloseAnimationRate { get; init; }
    public float? DelayBeforeOpening { get; init; }
    public float? StayOpenDuration { get; init; }
    public required List<LevelDoorAttachmentDocument> Attachments { get; init; }
    public required bool Complete { get; init; }
}

public sealed record LevelDoorAttachmentDocument
{
    public LevelReferenceDocument? StaticMesh { get; init; }
    public string? AttachSocket { get; init; }
    public float[]? LocationOffset { get; init; }
    public int[]? RotationOffset { get; init; }
    public required bool InteractWithPhysicalObjects { get; init; }
}

public sealed record LevelDoorSwitchActorDocument
{
    public string? DamageResistanceSetName { get; init; }
    public string? UseVerbText { get; init; }
    public LevelReferenceDocument? OverlayMaterial { get; init; }
    public required bool Complete { get; init; }
}

public sealed record LevelScriptedSequenceDocument
{
    public required List<LevelScriptedSequenceEntryDocument> Entries { get; init; }
    public required bool Complete { get; init; }
}

public sealed record LevelScriptedSequenceEntryDocument
{
    public required List<LevelScriptedAnimationChoiceDocument> Animations { get; init; }
    public float[]? LoopCount { get; init; }
    public int? RunNext { get; init; }
    public int? TotalChance { get; init; }
}

public sealed record LevelScriptedAnimationChoiceDocument
{
    public string? Animation { get; init; }
    public int? Chance { get; init; }
}

public sealed record LevelPressureRegionDocument(string Name, byte Pressure, float EffectsDuration);
public sealed record LevelMapUiRegionDocument(string MapUiRegion, string HudRegion, bool? Revealed, float LastVisited);
public sealed record LevelMapHudRegionDocument(string HudRegion, string Description);
public sealed record LevelRequiredAnimationGroupDocument(string PackageName, string GroupName);

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

/// <summary>
/// Known emitter-template fields; unsupported template properties remain in source bytes. Range
/// fields serialise as <c>[Min, Max]</c> (<see cref="LevelEmittersDocument"/>'s source type is UE2's
/// <c>Range</c>) or, for an axis range, <c>[MinX, MaxX, MinY, MaxY, MinZ, MaxZ]</c>. <c>Blending</c>,
/// <c>CoordinateSystem</c> and <c>StartLocationShape</c> are raw bytes — their enum meanings are
/// `UNKNOWN`, see <c>docs/research/effects.md</c> §6.
/// </summary>
public sealed record LevelEmitterTemplateDocument
{
    public required LevelReferenceDocument? Source { get; init; }
    public LevelReferenceDocument? Material { get; init; }
    public int? MaxParticles { get; init; }
    public float? ParticlesPerSecond { get; init; }
    public float? InitialParticlesPerSecond { get; init; }
    public bool? AutomaticInitialSpawning { get; init; }
    public bool? RespawnDeadParticles { get; init; }
    public float[]? LifetimeRange { get; init; }
    public float[]? StartSizeRange { get; init; }
    public bool? UniformSize { get; init; }
    public bool? UseSizeScale { get; init; }
    public bool? UseRegularSizeScale { get; init; }
    public List<LevelFloatCurveKeyDocument>? SizeScale { get; init; }
    public float[]? StartVelocityRange { get; init; }
    public float[]? Acceleration { get; init; }
    public List<LevelVectorCurveKeyDocument>? VelocityScale { get; init; }
    public float[]? StartLocationRange { get; init; }
    public float[]? StartLocationOffset { get; init; }
    public byte? StartLocationShape { get; init; }
    public float[]? StartSpinRange { get; init; }
    public float[]? SpinsPerSecondRange { get; init; }
    public bool? SpinParticles { get; init; }
    public bool? UseColorScale { get; init; }
    public List<LevelColorCurveKeyDocument>? ColorScale { get; init; }
    public byte? Blending { get; init; }
    public byte? CoordinateSystem { get; init; }
    public int? TextureUSubdivisions { get; init; }
    public int? TextureVSubdivisions { get; init; }
    public LevelReferenceDocument? StaticMesh { get; init; }
    public List<LevelFloatCurveKeyDocument>? SegmentSizeScale { get; init; }
    public List<LevelColorCurveKeyDocument>? SegmentColorScale { get; init; }
    public required bool PropertiesComplete { get; init; }
}

/// <summary>One key of a <c>{ RelativeTime, RelativeSize }</c>-shaped curve, e.g. <c>SizeScale</c>.</summary>
public sealed record LevelFloatCurveKeyDocument
{
    public required float RelativeTime { get; init; }
    public required float Value { get; init; }
}

/// <summary>One key of a <c>{ RelativeTime, Color }</c>-shaped curve, e.g. <c>ColorScale</c>. <c>Color</c> is <c>[R, G, B, A]</c>.</summary>
public sealed record LevelColorCurveKeyDocument
{
    public required float RelativeTime { get; init; }
    public required byte[] Color { get; init; }
}

/// <summary>One key of a <c>{ RelativeTime, RelativeVelocity }</c>-shaped curve, i.e. <c>VelocityScale</c>.</summary>
public sealed record LevelVectorCurveKeyDocument
{
    public required float RelativeTime { get; init; }
    public required float[] Value { get; init; }
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
