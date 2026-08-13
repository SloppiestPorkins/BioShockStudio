using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Level;

/// <summary>
/// How far a piece of reconstruction got. A level that reports honestly is more useful than one
/// that reports success, so nothing in this layer throws away the difference.
/// </summary>
public enum ResolutionStatus
{
    /// <summary>Everything needed was found and decoded.</summary>
    Resolved,

    /// <summary>Some of it was found; what is missing is named.</summary>
    Partial,

    /// <summary>The reference exists but points outside what this package can supply.</summary>
    External,

    /// <summary>Nothing of the kind was found. Not an error — most actors have no mesh.</summary>
    Absent,

    /// <summary>A reference was found and did not resolve, or a decode failed.</summary>
    Failed,
}

/// <summary>
/// A stable identity for one shipped object: the package it lives in, its export index, its class
/// and its name. Names are not unique within a package and classes repeat across packages, so
/// deduplication and debugging both need all four.
/// </summary>
public readonly record struct SourceId(string Package, int ExportIndex, string ClassName, string ObjectName)
{
    public override string ToString() => $"{Package}:{ExportIndex} {ClassName} {ObjectName}";

    /// <summary>A filesystem- and asset-name-safe key, unique within a package.</summary>
    public string Key => $"{ClassName}_{ObjectName}_{ExportIndex}";
}

/// <summary>A reference from an actor to an asset, with what became of it.</summary>
public sealed record AssetReference
{
    public required PackageIndex Index { get; init; }
    public required string ObjectName { get; init; }
    public required string ClassName { get; init; }

    /// <summary>Where the reference was found: the actor's own properties, or its class defaults.</summary>
    public required string Origin { get; init; }

    /// <summary>Set when the reference resolves to an export in this package.</summary>
    public SourceId? Source { get; init; }

    public ResolutionStatus Status =>
        Index.IsNull ? ResolutionStatus.Absent
        : Source is not null ? ResolutionStatus.Resolved
        : Index.IsImport ? ResolutionStatus.External
        : ResolutionStatus.Failed;

    public override string ToString() => $"{ObjectName} [{ClassName}] ({Status})";
}

/// <summary>One placed world object.</summary>
public sealed record LevelActor
{
    public required SourceId Source { get; init; }

    /// <summary>The actor's designer-facing name, from its <c>Label</c> property. Null when it has none.</summary>
    public string? Label { get; init; }

    /// <summary>The actor's <c>Tag</c>, which the game uses to group behaviour.</summary>
    public string? Tag { get; init; }

    public required ActorTransform Transform { get; init; }

    /// <summary>The static mesh this actor draws, from its own properties or its class defaults.</summary>
    public AssetReference? StaticMesh { get; init; }

    /// <summary>The skeletal mesh this actor draws, if it is a skeletal actor.</summary>
    public AssetReference? SkeletalMesh { get; init; }

    /// <summary>Per-actor material overrides, from the <c>Skins</c> array.</summary>
    public IReadOnlyList<AssetReference> MaterialOverrides { get; init; } = [];

    /// <summary>The actor's parent, when it declares one — <c>Owner</c> or <c>Base</c>.</summary>
    public AssetReference? Attachment { get; init; }

    /// <summary>The <c>Brush</c> reference of a BSP actor: the <c>Model</c> holding its geometry.</summary>
    public AssetReference? Brush { get; init; }

    /// <summary>Groups the level editor put this actor in, from <c>OwnerGroups</c>.</summary>
    public IReadOnlyList<string> Groups { get; init; } = [];

    /// <summary>Every property the actor stored, by name, including ones nothing yet interprets.</summary>
    public required IReadOnlyList<UnrealProperty> Properties { get; init; }

    /// <summary>True when the property walk lost alignment, so the actor's data is incomplete.</summary>
    public required bool Truncated { get; init; }

    /// <summary>The twelve-byte trailer, kept rather than discarded.</summary>
    public required byte[] Trailer { get; init; }

    /// <summary>The header field nothing has explained yet.</summary>
    public required int UnknownHeaderField { get; init; }

    public bool HasGeometry => StaticMesh?.Status is ResolutionStatus.Resolved or ResolutionStatus.External
                               || SkeletalMesh?.Status is ResolutionStatus.Resolved or ResolutionStatus.External
                               || Brush?.Status == ResolutionStatus.Resolved;

    public override string ToString() => $"{Source.ClassName} {Source.ObjectName} at {Transform.Location:0.#}";
}

/// <summary>
/// Everything the analyzer found in one level package: the actors, the assets they reference, and
/// what did not resolve.
/// </summary>
public sealed record LevelContext
{
    public required string PackageFile { get; init; }
    public required string PackageName { get; init; }
    public required int ExportCount { get; init; }
    public required int ImportCount { get; init; }
    public required int NameCount { get; init; }

    public required IReadOnlyList<LevelActor> Actors { get; init; }

    /// <summary>Exports carrying the actor header whose property list would not walk cleanly.</summary>
    public required IReadOnlyList<SourceId> FailedActors { get; init; }

    /// <summary>Distinct static meshes the level's actors reference, each with the actors that use it.</summary>
    public required IReadOnlyDictionary<SourceId, List<int>> StaticMeshUsage { get; init; }

    public required IReadOnlyDictionary<SourceId, List<int>> SkeletalMeshUsage { get; init; }

    /// <summary>References that named an object this package does not contain.</summary>
    public required IReadOnlyList<AssetReference> ExternalReferences { get; init; }

    /// <summary>References that resolved to nothing at all.</summary>
    public required IReadOnlyList<AssetReference> UnresolvedReferences { get; init; }

    /// <summary>Actor classes with no mesh of any kind, and how many there are of each.</summary>
    public required IReadOnlyDictionary<string, int> ClassesWithoutGeometry { get; init; }

    /// <summary>Property names seen on actors that nothing in this layer interprets, with counts.</summary>
    public required IReadOnlyDictionary<string, int> UninterpretedProperties { get; init; }

    public IEnumerable<LevelActor> WithStaticMesh => Actors.Where(a => a.StaticMesh is { Index.IsNull: false });
    public IEnumerable<LevelActor> WithSkeletalMesh => Actors.Where(a => a.SkeletalMesh is { Index.IsNull: false });
    public IEnumerable<LevelActor> Brushes => Actors.Where(a => a.Brush is { Index.IsNull: false });
    public IEnumerable<LevelActor> Lights => Actors.Where(a => a.Source.ClassName.EndsWith("Light", StringComparison.Ordinal));
    public IEnumerable<LevelActor> Volumes => Actors.Where(a => a.Source.ClassName.EndsWith("Volume", StringComparison.Ordinal));
}
