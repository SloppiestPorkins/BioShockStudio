namespace BioShockStudio.Core.Level;

/// <summary>
/// The present export status of one placed UE2 actor. These values describe what the tool has
/// actually decoded, not what the actor's class name suggests it might do at runtime.
/// </summary>
public enum LevelActorCoverage
{
    /// <summary>A local static mesh or BSP brush that the level scene can export today.</summary>
    GeometryInScene,

    /// <summary>
    /// A local skeletal mesh placed as its decoded reference (bind) pose. Geometry and material
    /// sections are present, but animation and physics-driven pose reconstruction are not.
    /// </summary>
    SkeletalMeshBindPose,

    /// <summary>A mesh or brush reference outside the map package, so it needs cross-package resolution.</summary>
    ExternalGeometryPending,

    /// <summary>A decoded actor light, retained in the scene document but not yet rendered faithfully.</summary>
    LightPending,

    /// <summary>A zone, trigger, or volume whose brush/property graph is retained but not exported as gameplay.</summary>
    RegionPending,

    /// <summary>An actor whose decoded <c>Emitters</c> property identifies an effect template still awaiting a Niagara mapping.</summary>
    EffectPending,

    /// <summary>An ambient or point sound actor retained for a future SoundWave/SoundCue mapping.</summary>
    AudioPending,

    /// <summary>An actor carrying the decoded path/navigation property family, retained as a navigation placeholder.</summary>
    NavigationPending,

    /// <summary>An actor carrying a decoded script action graph, retained without selecting a Blueprint representation.</summary>
    ScriptPending,

    /// <summary>A placed editor/gameplay marker with no class-specific payload beyond the common actor fields.</summary>
    MarkerPending,

    /// <summary>A decoded AI population spawner awaiting a UE5 gameplay representation.</summary>
    SpawnerPending,

    /// <summary>A decoded cubemap probe awaiting a UE5 reflection-capture representation.</summary>
    ReflectionProbePending,

    /// <summary>A decoded UE2 projector/decal awaiting a UE5 decal representation.</summary>
    ProjectorPending,

    /// <summary>A decoded Havok force declaration awaiting a UE5 physics-field representation.</summary>
    PhysicsForcePending,

    /// <summary>A decoded pickup/interaction declaration awaiting a UE5 gameplay representation.</summary>
    InteractionPending,

    /// <summary>A decoded Havok actor constraint awaiting a UE5 physics-constraint representation.</summary>
    PhysicsConstraintPending,

    /// <summary>An actor whose bytes are retained but whose UE5 representation has not been selected.</summary>
    Unclassified,
}

/// <summary>A class-level row in a level's decode ledger.</summary>
public sealed record LevelCoverageRow
{
    public required string ClassName { get; init; }
    public required int ActorCount { get; init; }
    public required IReadOnlyDictionary<LevelActorCoverage, int> StatusCounts { get; init; }
    public required IReadOnlyList<string> OutstandingProperties { get; init; }

    public int DecodedCount => StatusCounts.GetValueOrDefault(LevelActorCoverage.GeometryInScene)
        + StatusCounts.GetValueOrDefault(LevelActorCoverage.SkeletalMeshBindPose);
}

/// <summary>
/// A byte-backed inventory of every actor in one map. It deliberately includes the things the
/// viewport cannot draw: silent omission is the primary failure mode for a future UE5 importer.
/// </summary>
public sealed record LevelCoverageReport
{
    public required string PackageName { get; init; }
    public required int ActorCount { get; init; }
    public required IReadOnlyList<LevelCoverageRow> Classes { get; init; }

    public int ClassifiedCount => Classes.Sum(row => row.StatusCounts.Values.Sum());

    /// <summary>Builds a deterministic ledger from the actor data already retained by <see cref="LevelAnalyzer"/>.</summary>
    public static LevelCoverageReport Build(LevelContext context)
    {
        var rows = context.Actors
            .GroupBy(actor => actor.Source.ClassName, StringComparer.Ordinal)
            .OrderBy(group => group.Key, StringComparer.Ordinal)
            .Select(group => new LevelCoverageRow
            {
                ClassName = group.Key,
                ActorCount = group.Count(),
                StatusCounts = group
                    .GroupBy(Classify)
                    .OrderBy(status => status.Key)
                    .ToDictionary(status => status.Key, status => status.Count()),
                OutstandingProperties = group
                    .SelectMany(actor => actor.Properties)
                    .Select(property => property.Name)
                    .Where(property => !LevelAnalyzer.IsInterpretedProperty(property))
                    .Distinct(StringComparer.Ordinal)
                    .OrderBy(property => property, StringComparer.Ordinal)
                    .ToList(),
            })
            .ToList();

        return new LevelCoverageReport
        {
            PackageName = context.PackageName,
            ActorCount = context.Actors.Count,
            Classes = rows,
        };
    }

    private static LevelActorCoverage Classify(LevelActor actor)
    {
        // A gameplay volume often owns a source brush. The brush can be shown by the diagnostic
        // viewport, but that is not a UE5 gameplay export, so the semantic actor category wins.
        if (actor.Source.ClassName.EndsWith("Volume", StringComparison.Ordinal)
            || actor.Source.ClassName.Contains("Trigger", StringComparison.Ordinal)
            || actor.Source.ClassName.Contains("Zone", StringComparison.Ordinal))
            return LevelActorCoverage.RegionPending;

        if (actor.Brush?.Status == ResolutionStatus.Resolved
            || actor.StaticMesh?.Status == ResolutionStatus.Resolved)
            return LevelActorCoverage.GeometryInScene;

        if (actor.SkeletalMesh?.Status == ResolutionStatus.Resolved)
            return LevelActorCoverage.SkeletalMeshBindPose;

        if (actor.Brush?.Status == ResolutionStatus.External
            || actor.StaticMesh?.Status == ResolutionStatus.External
            || actor.SkeletalMesh?.Status == ResolutionStatus.External)
            return LevelActorCoverage.ExternalGeometryPending;

        // The property family identifies actual light actors even where a BioShock class uses a
        // name such as DefaultSecurityCameraSpotlight rather than ending in "Light". This comes
        // after geometry: a decorative mesh can legitimately carry LightColor without becoming an
        // invisible light placeholder.
        if (actor.Source.ClassName.EndsWith("Light", StringComparison.Ordinal)
            || HasAny(actor, "LightBrightness", "LightRadius", "LightColor", "LightType"))
            return LevelActorCoverage.LightPending;

        // These categories are selected by the bytes the actor actually stores, not a fuzzy name
        // convention. They are still placeholders: the status says what mapping needs to be built,
        // not that an emitter, sound, navigation node or script has been reconstructed.
        if (HasAny(actor, "Emitters")) return LevelActorCoverage.EffectPending;
        if (actor.Source.ClassName is "AmbientSound" or "SoundMarker"
            || HasAny(actor, "AmbientSound", "Sound", "Schema1", "Schema2"))
            return LevelActorCoverage.AudioPending;
        if (HasAny(actor, "PathList", "PathCollisionRadius", "bIsAutoGenerated"))
            return LevelActorCoverage.NavigationPending;
        if (HasAny(actor, "Actions", "Concepts")) return LevelActorCoverage.ScriptPending;
        if (actor.Source.ClassName is "Marker" or "TrainingMarker") return LevelActorCoverage.MarkerPending;
        if (actor.Spawner is not null) return LevelActorCoverage.SpawnerPending;
        if (actor.Cubemap is not null) return LevelActorCoverage.ReflectionProbePending;
        if (actor.Projector is not null) return LevelActorCoverage.ProjectorPending;
        if (actor.HavokForce is not null) return LevelActorCoverage.PhysicsForcePending;
        if (actor.LootSlot is not null) return LevelActorCoverage.InteractionPending;
        if (actor.HavokConstraint is not null) return LevelActorCoverage.PhysicsConstraintPending;

        return LevelActorCoverage.Unclassified;
    }

    private static bool HasAny(LevelActor actor, params string[] names) => actor.Properties
        .Any(property => names.Contains(property.Name, StringComparer.Ordinal));
}
