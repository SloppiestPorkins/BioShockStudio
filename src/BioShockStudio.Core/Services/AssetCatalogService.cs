using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;

namespace BioShockStudio.Core.Services;

/// <summary>
/// What an asset is, in the user's terms rather than the format's.
/// </summary>
/// <remarks>
/// These are the categories the browser offers. Nothing is classified by guessing at names: a
/// character is a group that owns both a skeletal mesh and an animation package, and anything whose
/// role cannot be established from the data lands in <see cref="Other"/> rather than being assigned
/// a plausible-looking home.
/// </remarks>
public enum AssetCategory
{
    Characters,
    FirstPerson,
    Weapons,
    Props,
    SkeletalMeshes,
    StaticMeshes,
    Animations,
    Textures,
    Materials,
    Other,
}

/// <summary>One row in the asset browser.</summary>
public sealed record CatalogEntry
{
    public required AssetCategory Category { get; init; }
    public required string Name { get; init; }

    /// <summary>Package file name without extension.</summary>
    public required string Package { get; init; }

    /// <summary>The game's own grouping — the top-level <c>Package</c> object this belongs to.</summary>
    public required string Group { get; init; }

    /// <summary>Export object name, which is what the extractors resolve by.</summary>
    public required string ObjectName { get; init; }

    /// <summary>Unreal class, kept for research mode and for resolving the export again.</summary>
    public required string ClassName { get; init; }

    public required int ExportIndex { get; init; }
    public required int SerialSize { get; init; }

    /// <summary>A short human summary, cheap to compute — never requires decoding the payload.</summary>
    public required string Detail { get; init; }

    /// <summary>For an animation, the group whose skeleton it belongs to.</summary>
    public string? OwnerGroup { get; init; }

    public override string ToString() => $"{Category} {Name} ({Package})";
}

/// <summary>Progress while the catalog is being built.</summary>
public sealed record CatalogProgress(int PackagesDone, int PackagesTotal, string CurrentPackage, int EntriesSoFar);

/// <summary>A package that could not be catalogued, and why.</summary>
public sealed record CatalogFailure(string Package, string Reason);

/// <summary>
/// Builds and searches the browsable asset catalog.
/// </summary>
/// <remarks>
/// <para>
/// Nothing here decodes a payload. The catalog is built from package tables only — the same reads
/// <see cref="AssetIndex"/> does — so cataloguing the whole game costs seconds rather than minutes.
/// Dimensions, geometry, skeletons and materials are resolved on demand when something is selected,
/// which is what keeps typing in the search box from touching the disk at all.
/// </para>
/// <para>
/// The previous GUI decoded every texture in a package just to list it, which is why opening a
/// package was slow; a texture's size is not worth a mip-chain decode.
/// </para>
/// </remarks>
public sealed class AssetCatalogService
{
    /// <summary>An animated group with this many animations and this much mesh is a character.</summary>
    /// <remarks>
    /// Doors, gates and levers also carry animation packages, so the split is by substance. It is a
    /// heuristic and is treated as one: everything animated still appears, only the bucket differs.
    /// </remarks>
    private const int CharacterAnimationThreshold = 20;

    private const int CharacterMeshSizeThreshold = 200_000;

    private readonly List<CatalogEntry> _entries = [];
    private readonly List<CatalogFailure> _failures = [];
    private readonly Dictionary<string, string> _packageFiles = new(StringComparer.OrdinalIgnoreCase);

    public IReadOnlyList<CatalogEntry> Entries => _entries;
    public IReadOnlyList<CatalogFailure> Failures => _failures;

    /// <summary>Package names, in the order they were catalogued.</summary>
    public IReadOnlyList<string> Packages => _packageFiles.Keys.ToList();

    public bool IsLoaded => _entries.Count > 0;

    /// <summary>Resolves a package name back to the file it was read from.</summary>
    public string PackageFile(string packageName) =>
        _packageFiles.TryGetValue(packageName, out string? file)
            ? file
            : throw new FileNotFoundException($"Package '{packageName}' is not in the catalog.");

    /// <summary>
    /// Records where an install's packages are without reading any of them.
    /// </summary>
    /// <remarks>
    /// Cheap — a directory listing. It lets everything that only needs to open a package by name
    /// work the moment a game folder is chosen, rather than waiting for the catalogue to finish.
    /// </remarks>
    public IReadOnlyList<string> RegisterInstall(string gameRoot)
    {
        foreach (string file in GameLocator.EnumeratePackages(gameRoot))
            _packageFiles[Path.GetFileNameWithoutExtension(file)] = file;

        string? weapons = GameLocator.WeaponPackage(gameRoot);
        if (weapons is not null) _packageFiles[Path.GetFileNameWithoutExtension(weapons)] = weapons;

        return _packageFiles.Keys.ToList();
    }

    /// <summary>
    /// Catalogues every package under an install. Safe to call on a background thread; reports
    /// progress per package and never aborts the whole build because one package failed.
    /// </summary>
    public async Task BuildAsync(
        string gameRoot,
        IProgress<CatalogProgress>? progress = null,
        CancellationToken cancellation = default)
    {
        await Task.Run(() =>
        {
            _entries.Clear();
            _failures.Clear();
            _packageFiles.Clear();

            var files = GameLocator.EnumeratePackages(gameRoot).ToList();
            string? weapons = GameLocator.WeaponPackage(gameRoot);
            if (weapons is not null) files.Add(weapons);

            for (int i = 0; i < files.Count; i++)
            {
                cancellation.ThrowIfCancellationRequested();

                string file = files[i];
                string name = Path.GetFileNameWithoutExtension(file);
                progress?.Report(new CatalogProgress(i, files.Count, name, _entries.Count));

                try
                {
                    _packageFiles[name] = file;
                    using var package = BioShockPackage.Open(file);
                    _entries.AddRange(Catalogue(package, name));
                }
                catch (Exception ex)
                {
                    // One unreadable package must never cost the user the other twenty.
                    _failures.Add(new CatalogFailure(name, ex.Message));
                }
            }

            progress?.Report(new CatalogProgress(files.Count, files.Count, string.Empty, _entries.Count));
        }, cancellation);
    }

    /// <summary>
    /// Catalogues one open package. Reads the export table and the group chain only — no payloads —
    /// which is what keeps a whole-game catalogue to seconds.
    /// </summary>
    public static IReadOnlyList<CatalogEntry> Catalogue(BioShockPackage package, string packageName)
    {
        var entries = new List<CatalogEntry>();

        // Group membership is the game's own relationship, and resolving it per export is the one
        // moderately costly part, so it is done once and reused.
        var groupOf = new Dictionary<int, string>();
        foreach (var export in package.Exports)
            groupOf[export.Index] = AssetContextResolver.TopLevelGroup(package, export);

        var animatedGroups = new Dictionary<string, CharacterEntry>(StringComparer.OrdinalIgnoreCase);
        foreach (var character in CharacterCatalog.Find(package))
        {
            animatedGroups[character.Group] = character;

            entries.Add(new CatalogEntry
            {
                Category = CategoriseGroup(character),
                Name = character.Group,
                Package = packageName,
                Group = character.Group,
                ObjectName = character.AnimationPackageObject,
                ClassName = AssetClasses.AnimationPackageWrapper,
                ExportIndex = -1,
                SerialSize = character.LargestMeshSize,
                Detail = $"{character.AnimationCount} animations · {character.Meshes.Count} mesh(es) · "
                         + $"{character.TextureCount} textures",
            });
        }

        foreach (var export in package.Exports)
        {
            string className = package.GetClassName(export);
            string group = groupOf[export.Index];

            var category = className switch
            {
                AssetClasses.SkeletalMesh => AssetCategory.SkeletalMeshes,
                AssetClasses.StaticMesh => AssetCategory.StaticMeshes,
                TextureReader.ClassName => AssetCategory.Textures,
                AnimationMetadataReader.ClassName => AssetCategory.Animations,
                _ when MaterialReader.IsMaterialClass(className) => AssetCategory.Materials,
                _ => AssetCategory.Other,
            };

            // "Other" is every remaining Unreal class — notifies, packages, script objects. Listing
            // them all would bury the browser, so they stay out unless research mode asks for them.
            if (category == AssetCategory.Other) continue;

            string name = export.ObjectName;
            string? owner = null;

            if (category == AssetCategory.Animations)
            {
                // The metadata object is named after its animation; the animation is what the user
                // is looking for.
                if (name.StartsWith(AnimationMetadataReader.ObjectPrefix, StringComparison.Ordinal))
                    name = name[AnimationMetadataReader.ObjectPrefix.Length..];
                owner = group;
            }

            entries.Add(new CatalogEntry
            {
                Category = category,
                Name = name,
                Package = packageName,
                Group = group,
                ObjectName = export.ObjectName,
                ClassName = className,
                ExportIndex = export.Index,
                SerialSize = export.SerialSize,
                Detail = Describe(category, group, export.SerialSize, animatedGroups),
                OwnerGroup = owner,
            });
        }

        return entries;
    }

    private static AssetCategory CategoriseGroup(CharacterEntry character)
    {
        if (character.Group.Contains("PlayerHands", StringComparison.OrdinalIgnoreCase))
            return AssetCategory.FirstPerson;
        if (character.Group.StartsWith("WP_", StringComparison.OrdinalIgnoreCase))
            return AssetCategory.Weapons;

        return character.AnimationCount >= CharacterAnimationThreshold
               && character.LargestMeshSize > CharacterMeshSizeThreshold
            ? AssetCategory.Characters
            : AssetCategory.Props;
    }

    private static string Describe(
        AssetCategory category, string group, int size, IReadOnlyDictionary<string, CharacterEntry> animated)
    {
        string where = group.Length == 0 ? string.Empty : $"in {group}";

        return category switch
        {
            // Size is the only fact available without reading the payload, and it is a fair proxy
            // for whether a mesh or texture is substantial.
            AssetCategory.Textures => $"{Kilobytes(size)} {where}".Trim(),
            AssetCategory.Animations => animated.TryGetValue(group, out var owner)
                ? $"on {owner.Group}"
                : where,
            _ => $"{Kilobytes(size)} {where}".Trim(),
        };
    }

    private static string Kilobytes(int bytes) => bytes >= 1024 * 1024
        ? $"{bytes / (1024.0 * 1024.0):0.#} MB"
        : $"{Math.Max(1, bytes / 1024)} KB";

    /// <summary>
    /// Searches the catalog. Matches on name, group, package and class, so both
    /// <c>Hand_DIFF</c> and <c>NEWPlayerHands</c> find the hands' textures.
    /// </summary>
    /// <remarks>
    /// A linear pass over an in-memory list. At the scale this reaches — tens of thousands of
    /// entries — that is well under a frame, and it avoids a second index to keep in step.
    /// </remarks>
    public IReadOnlyList<CatalogEntry> Search(
        string? query,
        AssetCategory? category = null,
        string? package = null,
        int limit = 2000)
    {
        var results = new List<CatalogEntry>();
        bool hasQuery = !string.IsNullOrWhiteSpace(query);
        string term = query?.Trim() ?? string.Empty;

        foreach (var entry in _entries)
        {
            if (category is not null && entry.Category != category) continue;
            if (package is not null && !string.Equals(entry.Package, package, StringComparison.OrdinalIgnoreCase))
                continue;
            if (hasQuery && !Matches(entry, term)) continue;

            results.Add(entry);
            if (results.Count >= limit) break;
        }

        return results;
    }

    private static bool Matches(CatalogEntry entry, string term) =>
        entry.Name.Contains(term, StringComparison.OrdinalIgnoreCase)
        || entry.Group.Contains(term, StringComparison.OrdinalIgnoreCase)
        || entry.Package.Contains(term, StringComparison.OrdinalIgnoreCase)
        || entry.ClassName.Contains(term, StringComparison.OrdinalIgnoreCase);

    /// <summary>How many entries each category holds, for the browser's tree.</summary>
    public IReadOnlyDictionary<AssetCategory, int> CategoryCounts()
    {
        var counts = new Dictionary<AssetCategory, int>();
        foreach (var entry in _entries)
            counts[entry.Category] = counts.GetValueOrDefault(entry.Category) + 1;
        return counts;
    }
}
