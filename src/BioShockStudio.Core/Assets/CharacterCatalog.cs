using BioShockStudio.Core.Packages;

namespace BioShockStudio.Core.Assets;

/// <summary>A character-like asset group: a skeletal mesh with its own animation package.</summary>
public sealed record CharacterEntry
{
    public required string Group { get; init; }
    public required string PackageName { get; init; }
    public required string AnimationPackageObject { get; init; }
    public required IReadOnlyList<string> Meshes { get; init; }
    public required int AnimationCount { get; init; }
    public required int TextureCount { get; init; }

    /// <summary>Largest mesh payload, a rough proxy for how substantial the asset is.</summary>
    public required int LargestMeshSize { get; init; }

    public override string ToString() => $"{Group} ({AnimationCount} animations)";
}

/// <summary>
/// Finds animated character assets in a package.
/// <para>
/// A character is recognised structurally, not by name: an asset group that owns both a
/// <c>SkeletalMesh</c> and an <c>AnimationPackageWrapper</c>. That covers Big Daddies, Splicers,
/// the Little Sister and the player hands, and also picks up animated props, which are separated by
/// mesh size and animation count rather than by guessing from names.
/// </para>
/// </summary>
public static class CharacterCatalog
{
    public static IReadOnlyList<CharacterEntry> Find(BioShockPackage package)
    {
        var byGroup = new Dictionary<string, List<ObjectExport>>(StringComparer.Ordinal);

        foreach (var export in package.Exports)
        {
            string group = AssetContextResolver.TopLevelGroup(package, export);
            if (!byGroup.TryGetValue(group, out var members))
                byGroup[group] = members = [];
            members.Add(export);
        }

        var result = new List<CharacterEntry>();
        string packageName = Path.GetFileNameWithoutExtension(package.FilePath);

        foreach (var (group, members) in byGroup)
        {
            var wrapper = members
                .Where(e => package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
                .MaxBy(e => e.SerialSize);
            if (wrapper is null) continue;

            var meshes = members.Where(e => package.GetClassName(e) == AssetClasses.SkeletalMesh).ToList();
            if (meshes.Count == 0) continue;

            result.Add(new CharacterEntry
            {
                Group = group,
                PackageName = packageName,
                AnimationPackageObject = wrapper.ObjectName,
                Meshes = meshes.Select(e => e.ObjectName).ToList(),
                AnimationCount = members.Count(e => package.GetClassName(e) == AnimationMetadataReader.ClassName),
                TextureCount = members.Count(e => package.GetClassName(e) == "Texture"),
                LargestMeshSize = meshes.Max(e => e.SerialSize),
            });
        }

        return result.OrderByDescending(e => e.AnimationCount).ThenByDescending(e => e.LargestMeshSize).ToList();
    }
}
