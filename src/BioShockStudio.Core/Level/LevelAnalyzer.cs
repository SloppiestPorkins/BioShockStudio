using System.Numerics;
using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Level;

/// <summary>
/// Builds a <see cref="LevelContext"/> from a map package: which exports are placed world objects,
/// where each one is, and what it draws.
/// <para>
/// Nothing here works from names. An actor is an actor because its payload carries the actor header,
/// which validates against the export table; its mesh is whatever its <c>StaticMesh</c> property or
/// its class's defaults point at; its position is its own <c>Location</c>. Filenames and class-name
/// prefixes are used only to describe what was found, never to decide it.
/// </para>
/// </summary>
public static class LevelAnalyzer
{
    /// <summary>Actor properties this layer reads. Everything else is counted as uninterpreted.</summary>
    private static readonly IReadOnlySet<string> Interpreted = new HashSet<string>(StringComparer.Ordinal)
    {
        "Location", "Rotation", "DrawScale", "DrawScale3D", "PrePivot",
        "StaticMesh", "Mesh", "SkeletalMesh", "Skins", "Brush",
        "Owner", "Base", "Label", "Tag", "OwnerGroups",
        "Actions",
    };

    /// <summary>Whether a property already has a typed representation in <see cref="LevelActor"/>.</summary>
    public static bool IsInterpretedProperty(string property) => Interpreted.Contains(property);

    public static LevelContext Analyze(string packageFile, IProgress<string>? progress = null)
    {
        using var package = BioShockPackage.Open(packageFile);
        return Analyze(package, progress);
    }

    public static LevelContext Analyze(BioShockPackage package, IProgress<string>? progress = null)
    {
        var defaults = new ClassDefaults(package);
        var actors = new List<LevelActor>();
        var failed = new List<SourceId>();
        var uninterpreted = new Dictionary<string, int>(StringComparer.Ordinal);
        string packageName = Path.GetFileNameWithoutExtension(package.FilePath);

        for (int i = 0; i < package.Exports.Count; i++)
        {
            var export = package.Exports[i];
            if (export.SerialSize < 64) continue;

            byte[] data;
            try { data = package.ReadExportData(export); }
            catch { continue; }

            var payload = ActorPayloadReader.TryRead(package, export, data);
            if (payload is null) continue;

            var source = new SourceId(packageName, export.Index, payload.ClassName, export.ObjectName);
            if (payload.Truncated)
            {
                failed.Add(source);
                continue;
            }

            actors.Add(BuildActor(package, defaults, source, payload, uninterpreted));

            if (progress is not null && actors.Count % 1000 == 0)
                progress.Report($"{actors.Count} actors");
        }

        return Summarise(package, packageName, actors, failed, uninterpreted);
    }

    private static LevelActor BuildActor(
        BioShockPackage package, ClassDefaults defaults, SourceId source, ActorPayload payload,
        Dictionary<string, int> uninterpreted)
    {
        foreach (var property in payload.Properties)
            if (!Interpreted.Contains(property.Name))
                uninterpreted[property.Name] = uninterpreted.GetValueOrDefault(property.Name) + 1;

        return new LevelActor
        {
            Source = source,
            Label = ReadName(package, payload, "Label"),
            Tag = ReadName(package, payload, "Tag"),
            Transform = ReadTransform(payload),
            StaticMesh = Reference(package, defaults, payload, "StaticMesh", "StaticMesh"),
            SkeletalMesh = Reference(package, defaults, payload, "Mesh", "SkeletalMesh")
                           ?? Reference(package, defaults, payload, "SkeletalMesh", "SkeletalMesh"),
            Brush = Reference(package, defaults, payload, "Brush", "Model"),
            Attachment = Reference(package, defaults, payload, "Base", null)
                         ?? Reference(package, defaults, payload, "Owner", null),
            Navigation = Navigation(package, payload),
            ScriptActions = ScriptActions(package, payload),
            Emitters = Emitters(package, payload),
            MaterialOverrides = ReferenceArray(package, payload, "Skins"),
            Groups = ReferenceArray(package, payload, "OwnerGroups").Select(r => r.ObjectName).ToList(),
            Properties = payload.Properties,
            Truncated = payload.Truncated,
            Trailer = payload.Trailer,
            UnknownHeaderField = payload.UnknownHeaderField,
        };
    }

    /// <summary>
    /// Reads the transform properties. Each is optional and each absence means the engine default,
    /// so which ones were present is recorded rather than inferred back from the values.
    /// </summary>
    public static ActorTransform ReadTransform(ActorPayload payload)
    {
        var present = new List<string>();
        var transform = ActorTransform.Default;

        if (payload.Find("Location") is { } location && PropertyValues.AsVector(location) is { } l)
        {
            transform = transform with { Location = l };
            present.Add("Location");
        }
        if (payload.Find("Rotation") is { } rotation && PropertyValues.AsRotator(rotation) is { } r)
        {
            transform = transform with { Rotation = r };
            present.Add("Rotation");
        }
        if (payload.Find("DrawScale") is { } drawScale && drawScale.Value.Length >= 4)
        {
            transform = transform with { DrawScale = drawScale.AsFloat() };
            present.Add("DrawScale");
        }
        if (payload.Find("DrawScale3D") is { } drawScale3D && PropertyValues.AsVector(drawScale3D) is { } s)
        {
            transform = transform with { DrawScale3D = s };
            present.Add("DrawScale3D");
        }
        if (payload.Find("PrePivot") is { } prePivot && PropertyValues.AsVector(prePivot) is { } p)
        {
            transform = transform with { PrePivot = p };
            present.Add("PrePivot");
        }

        return transform with { Present = present };
    }

    private static string? ReadName(BioShockPackage package, ActorPayload payload, string property) =>
        payload.Find(property) is { } found ? PropertyValues.AsName(found, package) : null;

    private static NavigationActorData? Navigation(BioShockPackage package, ActorPayload payload)
    {
        var pathList = ReferenceArray(package, payload, "PathList");
        var autoGenerated = ReferenceArray(package, payload, "AutoGeneratedFlyingPathNodes");
        float? radius = payload.Find("PathCollisionRadius") is { Type: UnrealPropertyType.Float } collision
            && collision.Value.Length >= 4
            ? collision.AsFloat()
            : null;
        bool flagPresent = payload.Find("bIsAutoGenerated") is { Type: UnrealPropertyType.Bool };

        return pathList.Count > 0 || autoGenerated.Count > 0 || radius is not null || flagPresent
            ? new NavigationActorData
            {
                PathLinks = pathList,
                AutoGeneratedFlyingPathNodes = autoGenerated,
                PathCollisionRadius = radius,
                AutoGeneratedFlagSerialized = flagPresent,
            }
            : null;
    }

    private static ScriptActorData? ScriptActions(BioShockPackage package, ActorPayload payload)
    {
        if (payload.Find("Actions") is not { Type: UnrealPropertyType.Array } actions) return null;
        if (!PropertyValues.TryAsReferenceArrayExact(actions, out var indices))
            return new ScriptActorData { Complete = false };

        var references = new List<AssetReference>(indices.Count);
        foreach (var index in indices)
        {
            if (index.IsNull || Describe(package, index, "actor", null) is not { } reference)
                return new ScriptActorData { Complete = false };
            references.Add(reference);
        }

        return new ScriptActorData { Actions = references, Complete = true };
    }

    private static EmitterActorData? Emitters(BioShockPackage package, ActorPayload payload)
    {
        if (payload.Find("Emitters") is not { Type: UnrealPropertyType.Array } emitters) return null;
        if (!PropertyValues.TryAsReferenceArrayExact(emitters, out var indices))
            return new EmitterActorData { Complete = false };

        var templates = new List<EmitterTemplateData>(indices.Count);
        foreach (var index in indices)
        {
            if (index.IsNull || Describe(package, index, "actor", null) is not { } reference)
                return new EmitterActorData { Complete = false };
            templates.Add(ReadEmitterTemplate(package, reference));
        }

        return new EmitterActorData { Templates = templates, Complete = true };
    }

    private static EmitterTemplateData ReadEmitterTemplate(BioShockPackage package, AssetReference source)
    {
        if (source.Source is not { } local)
            return new EmitterTemplateData { Source = source, PropertiesComplete = false };

        List<UnrealProperty> properties;
        bool truncated;
        try
        {
            properties = UnrealPropertyReader.Read(package.ReadExportData(package.Exports[local.ExportIndex]),
                package.Names, out _, out truncated);
        }
        catch (Exception ex) when (ex is InvalidDataException or IndexOutOfRangeException
                                       or ArgumentOutOfRangeException)
        {
            return new EmitterTemplateData { Source = source, PropertiesComplete = false };
        }

        AssetReference? material = properties.FirstOrDefault(property => property.Name == "Material"
                                                               && property.Type == UnrealPropertyType.Object) is { } found
            && PropertyValues.AsReference(found) is { } materialIndex
            ? Describe(package, materialIndex, "emitter template", null)
            : null;
        int? maxParticles = properties.FirstOrDefault(property => property.Name == "MaxParticles"
                                                                  && property.Type == UnrealPropertyType.Int) is { } max
            ? max.AsInt()
            : null;
        float? particlesPerSecond = properties.FirstOrDefault(property => property.Name == "ParticlesPerSecond"
                                                                         && property.Type == UnrealPropertyType.Float) is { } rate
            ? rate.AsFloat()
            : null;
        float? initialParticlesPerSecond = properties.FirstOrDefault(property => property.Name == "InitialParticlesPerSecond"
                                                                                && property.Type == UnrealPropertyType.Float) is { } initialRate
            ? initialRate.AsFloat()
            : null;

        return new EmitterTemplateData
        {
            Source = source,
            Material = material,
            MaxParticles = maxParticles,
            ParticlesPerSecond = particlesPerSecond,
            InitialParticlesPerSecond = initialParticlesPerSecond,
            PropertiesComplete = !truncated,
        };
    }

    /// <summary>
    /// Resolves one object reference, looking first at the actor and then at its class defaults.
    /// <paramref name="expectedClass"/> rejects a reference whose target is of another class, which
    /// is what stops a name-shaped match from standing in for an identity.
    /// </summary>
    private static AssetReference? Reference(
        BioShockPackage package, ClassDefaults defaults, ActorPayload payload, string property, string? expectedClass)
    {
        string origin = "actor";
        var found = payload.Find(property);
        if (found is null)
        {
            found = defaults.Lookup(payload.Export.ClassIndex, property);
            origin = "class defaults";
        }
        if (found is null) return null;

        var index = PropertyValues.AsReference(found);
        if (index is null || index.Value.IsNull) return null;

        return Describe(package, index.Value, origin, expectedClass);
    }

    private static AssetReference? Describe(
        BioShockPackage package, PackageIndex index, string origin, string? expectedClass)
    {
        string objectName;
        string className;
        SourceId? source = null;

        if (index.IsExport)
        {
            if (index.ExportIndex >= package.Exports.Count) return null;
            var target = package.Exports[index.ExportIndex];
            className = package.GetClassName(target);
            objectName = target.ObjectName;
            if (expectedClass is not null && className != expectedClass) return null;
            source = new SourceId(
                Path.GetFileNameWithoutExtension(package.FilePath), target.Index, className, target.ObjectName);
        }
        else if (index.IsImport)
        {
            if (index.ImportIndex >= package.Imports.Count) return null;
            var import = package.Imports[index.ImportIndex];
            className = import.ClassName;
            objectName = import.ObjectName;
            if (expectedClass is not null && className != expectedClass) return null;
        }
        else return null;

        return new AssetReference
        {
            Index = index,
            ObjectName = objectName,
            ClassName = className,
            Origin = origin,
            Source = source,
        };
    }

    private static IReadOnlyList<AssetReference> ReferenceArray(
        BioShockPackage package, ActorPayload payload, string property)
    {
        if (payload.Find(property) is not { } found) return [];
        var result = new List<AssetReference>();
        foreach (var index in PropertyValues.AsReferenceArray(found))
        {
            if (Describe(package, index, "actor", null) is { } reference) result.Add(reference);
        }
        return result;
    }

    private static LevelContext Summarise(
        BioShockPackage package, string packageName, List<LevelActor> actors, List<SourceId> failed,
        Dictionary<string, int> uninterpreted)
    {
        var staticUsage = new Dictionary<SourceId, List<int>>();
        var skeletalUsage = new Dictionary<SourceId, List<int>>();
        var external = new List<AssetReference>();
        var unresolved = new List<AssetReference>();
        var withoutGeometry = new Dictionary<string, int>(StringComparer.Ordinal);

        for (int i = 0; i < actors.Count; i++)
        {
            var actor = actors[i];

            Record(actor.StaticMesh, staticUsage, i);
            Record(actor.SkeletalMesh, skeletalUsage, i);

            foreach (var reference in Enumerate(actor))
            {
                if (reference.Status == ResolutionStatus.External) external.Add(reference);
                else if (reference.Status == ResolutionStatus.Failed) unresolved.Add(reference);
            }

            if (!actor.HasGeometry)
                withoutGeometry[actor.Source.ClassName] = withoutGeometry.GetValueOrDefault(actor.Source.ClassName) + 1;
        }

        return new LevelContext
        {
            PackageFile = package.FilePath,
            PackageName = packageName,
            ExportCount = package.Exports.Count,
            ImportCount = package.Imports.Count,
            NameCount = package.Names.Count,
            Actors = actors,
            FailedActors = failed,
            StaticMeshUsage = staticUsage,
            SkeletalMeshUsage = skeletalUsage,
            ExternalReferences = external,
            UnresolvedReferences = unresolved,
            ClassesWithoutGeometry = withoutGeometry,
            UninterpretedProperties = uninterpreted,
        };

        static void Record(AssetReference? reference, Dictionary<SourceId, List<int>> usage, int actorIndex)
        {
            if (reference?.Source is not { } source) return;
            if (!usage.TryGetValue(source, out var users)) usage[source] = users = [];
            users.Add(actorIndex);
        }

        static IEnumerable<AssetReference> Enumerate(LevelActor actor)
        {
            if (actor.StaticMesh is not null) yield return actor.StaticMesh;
            if (actor.SkeletalMesh is not null) yield return actor.SkeletalMesh;
            if (actor.Brush is not null) yield return actor.Brush;
            foreach (var skin in actor.MaterialOverrides) yield return skin;
        }
    }

    /// <summary>
    /// The bounding box of every actor that has a position. Cheap sanity check on a level: Medical
    /// Pavilion should be tens of thousands of centimetres across, not millions.
    /// </summary>
    public static (Vector3 Min, Vector3 Max) Bounds(IEnumerable<LevelActor> actors)
    {
        var min = new Vector3(float.MaxValue);
        var max = new Vector3(float.MinValue);
        bool any = false;

        foreach (var actor in actors)
        {
            if (!actor.Transform.Present.Contains("Location")) continue;
            min = Vector3.Min(min, actor.Transform.Location);
            max = Vector3.Max(max, actor.Transform.Location);
            any = true;
        }

        return any ? (min, max) : (Vector3.Zero, Vector3.Zero);
    }
}
