using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Assets;

/// <summary>How strongly the game data supports a relationship.</summary>
public enum RelationshipConfidence
{
    /// <summary>Backed by an explicit reference in the shipped data.</summary>
    Confirmed,

    /// <summary>Consistent with the data and with no contradicting evidence, but not explicit.</summary>
    Likely,

    /// <summary>Inferred from naming only.</summary>
    Heuristic,
}

/// <summary>The kind of link between two assets.</summary>
public enum RelationshipKind
{
    Owns,
    UsesSkeleton,
    UsesAnimation,
    UsesTexture,
    AttachesTo,
    FiresEvent,
    RequiresVisualContext,
}

/// <summary>One edge of the asset relationship graph, carrying the evidence that produced it.</summary>
public sealed record AssetRelationship
{
    public required string From { get; init; }
    public required string To { get; init; }
    public required RelationshipKind Kind { get; init; }
    public required RelationshipConfidence Confidence { get; init; }

    /// <summary>Why this relationship exists, in terms of the actual data.</summary>
    public required string Evidence { get; init; }

    public override string ToString() => $"{From} --{Kind}--> {To} [{Confidence}: {Evidence}]";
}

/// <summary>
/// The set of assets that belong together, as the shipped data groups them.
/// <para>
/// CONFIRMED_BYTES: BioShock's <c>Package</c> export objects are the grouping mechanism. Everything
/// the first-person hands need shares the <c>NEWPlayerHands</c> package: the skeletal mesh, its
/// animation package, its three textures, the static meshes that attach to its sockets, and the
/// animation notify objects.
/// </para>
/// </summary>
public sealed class AssetContext
{
    public required string Name { get; init; }
    public required string PackageName { get; init; }

    /// <summary>Every export whose outer chain leads back to this group.</summary>
    public required IReadOnlyList<ObjectExport> Members { get; init; }

    public required IReadOnlyList<AssetRelationship> Relationships { get; init; }

    public IEnumerable<ObjectExport> OfClass(BioShockPackage package, string className) =>
        Members.Where(e => package.GetClassName(e) == className);
}

/// <summary>
/// Groups a package's exports by the top-level <c>Package</c> object they hang off, and derives
/// relationships from explicit references only.
/// </summary>
public static class AssetContextResolver
{
    /// <summary>
    /// The name of the top-level ancestor of an export, following the outer chain. Returns the
    /// export's own name when it has no outer.
    /// </summary>
    public static string TopLevelGroup(BioShockPackage package, ObjectExport export)
    {
        var current = export;
        // Guard against a malformed self-referential outer chain.
        for (int guard = 0; guard < 32; guard++)
        {
            var outer = current.OuterIndex;
            if (!outer.IsExport) break;
            int index = outer.ExportIndex;
            if (index < 0 || index >= package.Exports.Count) break;
            current = package.Exports[index];
        }
        return current.ObjectName;
    }

    /// <summary>Builds the context for a named group, e.g. <c>NEWPlayerHands</c>.</summary>
    public static AssetContext Resolve(BioShockPackage package, string groupName)
    {
        var members = package.Exports
            .Where(e => string.Equals(TopLevelGroup(package, e), groupName, StringComparison.OrdinalIgnoreCase))
            .ToList();

        var relationships = new List<AssetRelationship>();

        foreach (var member in members)
        {
            string className = package.GetClassName(member);
            if (className == "Package") continue;

            relationships.Add(new AssetRelationship
            {
                From = groupName,
                To = member.ObjectName,
                Kind = RelationshipKind.Owns,
                Confidence = RelationshipConfidence.Confirmed,
                Evidence = "outer chain leads to the group's Package object",
            });
        }

        return new AssetContext
        {
            Name = groupName,
            PackageName = Path.GetFileNameWithoutExtension(package.FilePath),
            Members = members,
            Relationships = relationships,
        };
    }

    /// <summary>Every top-level group in a package, with the number of members in each.</summary>
    public static IReadOnlyDictionary<string, int> EnumerateGroups(BioShockPackage package)
    {
        var counts = new Dictionary<string, int>(StringComparer.Ordinal);
        foreach (var export in package.Exports)
        {
            string group = TopLevelGroup(package, export);
            counts[group] = counts.TryGetValue(group, out int n) ? n + 1 : 1;
        }
        return counts;
    }
}
