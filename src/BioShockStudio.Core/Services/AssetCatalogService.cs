using System.Collections.Concurrent;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Game;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;
using BioShockStudio.Core.Audio;

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
    Sounds,
    Other,
}

/// <summary>One row in the asset browser.</summary>
public sealed record CatalogEntry
{
    public required AssetCategory Category { get; init; }
    public required string Name { get; init; }

    /// <summary>
    /// The package this asset is read from — the copy with the largest payload when the game ships
    /// it in several.
    /// </summary>
    public required string Package { get; init; }

    /// <summary>
    /// Every package that carries this asset, canonical one included.
    /// </summary>
    /// <remarks>
    /// The maps embed their own copy of everything they use, so a shared asset appears many times:
    /// <c>NEWPlayerHands</c> is in all twenty. They are collapsed to one row, and this is what the
    /// row was collapsed from.
    /// </remarks>
    public IReadOnlyList<string> Packages { get; init; } = [];

    public int PackageCount => Math.Max(1, Packages.Count);

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

    /// <summary>
    /// The catalogue, published as a whole array rather than mutated in place.
    /// </summary>
    /// <remarks>
    /// <b>The window reads these while <see cref="BuildAsync"/> is still writing them.</b> Typing in
    /// the search box during a build used to throw <c>Collection was modified; enumeration operation
    /// may not execute</c> out of <see cref="Search"/>, because the build cleared and refilled the
    /// same <c>List</c> the UI thread was walking. Swapping a finished array in with one assignment
    /// removes the race without a lock: a reader takes a local reference and enumerates a snapshot
    /// that nothing will ever mutate. <c>Enrich</c> then replaces elements of the published array in
    /// place, which is safe — a reference assignment is atomic, so a reader sees either the entry
    /// with its detail or the one without, never a torn value.
    /// </remarks>
    private volatile CatalogEntry[] _entries = [];

    private volatile CatalogFailure[] _failures = [];

    /// <summary>Written by the build thread and read by the window, so it must tolerate both.</summary>
    private readonly ConcurrentDictionary<string, string> _packageFiles = new(StringComparer.OrdinalIgnoreCase);

    public IReadOnlyList<CatalogEntry> Entries => _entries;
    public IReadOnlyList<CatalogFailure> Failures => _failures;

    /// <summary>Package names, in the order they were catalogued.</summary>
    public IReadOnlyList<string> Packages => _packageFiles.Keys.ToList();

    public bool IsLoaded => _entries.Length > 0;

    /// <summary>Resolves a package name back to the file it was read from.</summary>
    /// <summary>
    /// Opened packages, kept so that asking for the same one twice does not parse its tables twice.
    /// </summary>
    /// <remarks>
    /// It lives here because this is what already maps a package name to its file, so every service
    /// that borrows a package goes through one place. See <see cref="PackageCache"/> for the
    /// measurement that justifies it.
    /// </remarks>
    private readonly PackageCache _packages = new();

    /// <summary>Cache hits and misses since start-up, for diagnostics.</summary>
    public (int Hits, int Misses) PackageCacheCounters => (_packages.Hits, _packages.Misses);

    /// <summary>
    /// Borrows an opened package by name. Dispose the lease as usual — it returns the package to
    /// the cache rather than closing it.
    /// </summary>
    public PackageCache.Lease OpenShared(string packageName) => _packages.Rent(PackageFile(packageName));

    public string PackageFile(string packageName) =>
        _packageFiles.TryGetValue(packageName, out string? file)
            ? file
            : throw new FileNotFoundException($"Package '{packageName}' is not in the catalog.");

    /// <summary>
    /// The index into the bulk store, which holds the mips the packages had stripped out. Null when
    /// the install has no <c>BulkContent</c> beside it.
    /// </summary>
    public BulkTextureCatalog? Bulk { get; private set; }

    /// <summary>
    /// Resolves materials a mesh names by import — the shared shaders in the script packages.
    /// </summary>
    /// <remarks>
    /// Null until an install is registered. 433 material slots across the game are imports and none
    /// resolve inside their own package, so without this every security camera, ammo pickup and
    /// NPC-carried weapon draws untextured.
    /// </remarks>
    public Materials.IExternalMaterialSource? ExternalMaterials { get; private set; }

    /// <summary>
    /// Records where an install's packages are without reading any of them.
    /// </summary>
    /// <remarks>
    /// Cheap — a directory listing. It lets everything that only needs to open a package by name
    /// work the moment a game folder is chosen, rather than waiting for the catalogue to finish.
    /// </remarks>
    public IReadOnlyList<string> RegisterInstall(string gameRoot)
    {
        // Loading the bulk index is half a megabyte and one parse, and without it most textures
        // read as their 64-square tail.
        Bulk ??= BulkTextureCatalog.Load(gameRoot);
        ExternalMaterials ??= new PackageMaterialSource(gameRoot);

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
            _entries = [];
            _failures = [];
            _packageFiles.Clear();
            var collected = new List<CatalogEntry>();
            var failures = new List<CatalogFailure>();

            var files = GameLocator.EnumeratePackages(gameRoot).ToList();
            string? weapons = GameLocator.WeaponPackage(gameRoot);
            if (weapons is not null) files.Add(weapons);

            for (int i = 0; i < files.Count; i++)
            {
                cancellation.ThrowIfCancellationRequested();

                string file = files[i];
                string name = Path.GetFileNameWithoutExtension(file);
                progress?.Report(new CatalogProgress(i, files.Count, name, collected.Count));

                try
                {
                    _packageFiles[name] = file;
                    using var package = BioShockPackage.Open(file);
                    collected.AddRange(Catalogue(package, name));
                }
                catch (Exception ex)
                {
                    // One unreadable package must never cost the user the other twenty.
                    failures.Add(new CatalogFailure(name, ex.Message));
                }
            }

            _failures = failures.ToArray();

            // Published in one assignment, so a reader either sees the previous catalogue or this
            // one — never a list mid-refill.
            var built = Collapse(collected).ToArray();
            _entries = built;

            progress?.Report(new CatalogProgress(files.Count, files.Count, "describing textures and materials", built.Length));
            Enrich(built, PackageFile, cancellation);

            progress?.Report(new CatalogProgress(files.Count, files.Count, string.Empty, built.Length));
        }, cancellation);
    }

    /// <summary>
    /// Collapses the same asset appearing in several packages into one row.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Every map embeds its own copy of what it uses, so the raw catalogue is roughly five times
    /// larger than the set of distinct assets — 71,106 rows for 14,378 things. Browsing twenty
    /// identical <c>NEWPlayerHands</c> is not useful, and neither is a Textures list of 30,997 when
    /// there are 7,342 textures.
    /// </para>
    /// <para>
    /// The copies are not always byte-identical — payload sizes differ slightly between maps — so
    /// the largest is kept as the one to read from, and the rest are recorded rather than discarded
    /// so the package filter still finds the asset in any map that carries it.
    /// </para>
    /// </remarks>
    private static IEnumerable<CatalogEntry> Collapse(IEnumerable<CatalogEntry> entries) =>
        entries
            .GroupBy(e => (e.Category, e.ClassName, e.Group, e.Name), IdentityComparer.Instance)
            .Select(group =>
            {
                var canonical = group.MaxBy(e => e.SerialSize)!;
                var packages = group
                    .Select(e => e.Package)
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .Order(StringComparer.OrdinalIgnoreCase)
                    .ToList();

                return canonical with
                {
                    Packages = packages,
                    Detail = packages.Count > 1
                        ? $"{canonical.Detail} · in {packages.Count} packages"
                        : canonical.Detail,
                };
            });

    /// <summary>Identity of an asset across packages: what it is, where it sits, and its name.</summary>
    private sealed class IdentityComparer : IEqualityComparer<(AssetCategory, string, string, string)>
    {
        public static readonly IdentityComparer Instance = new();

        public bool Equals((AssetCategory, string, string, string) a, (AssetCategory, string, string, string) b) =>
            a.Item1 == b.Item1
            && string.Equals(a.Item2, b.Item2, StringComparison.OrdinalIgnoreCase)
            && string.Equals(a.Item3, b.Item3, StringComparison.OrdinalIgnoreCase)
            && string.Equals(a.Item4, b.Item4, StringComparison.OrdinalIgnoreCase);

        public int GetHashCode((AssetCategory, string, string, string) value) => HashCode.Combine(
            value.Item1,
            StringComparer.OrdinalIgnoreCase.GetHashCode(value.Item2),
            StringComparer.OrdinalIgnoreCase.GetHashCode(value.Item3),
            StringComparer.OrdinalIgnoreCase.GetHashCode(value.Item4));
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

            // A group holding several meshes is several characters sharing one rig — the thirteen
            // splicer variants, the corpses and Sander Cohen all hang off AggressorBabyJane. Each
            // one gets its own row below, so the group does not also get a fourteenth that stands
            // for none of them.
            if (character.Meshes.Count > 1) continue;

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
                Detail = $"{character.AnimationCount} anims · {character.Meshes.Count} "
                         + (character.Meshes.Count == 1 ? "mesh" : "meshes")
                         + $" · {character.TextureCount} textures"
                         + (character.HasRagdoll ? " · ragdoll" : string.Empty),
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
                SoundReader.ClassName => AssetCategory.Sounds,
                _ when MaterialReader.IsMaterialClass(className) => AssetCategory.Materials,
                _ => AssetCategory.Other,
            };

            // "Other" is every remaining Unreal class — notifies, packages, script objects. Listing
            // them all would bury the browser, so they stay out unless research mode asks for them.
            if (category == AssetCategory.Other) continue;

            string name = export.ObjectName;
            string? owner = null;
            string? detail = null;

            // A skeletal mesh in a group that owns several is one character among several sharing a
            // rig, not loose geometry. It is filed with the group and carries the group as its owner
            // so the shared animation package resolves — before this they landed in SkeletalMeshes
            // with no owner at all, which is why the splicer variants could not be animated and the
            // turret and security-bot meshes looked like scenery.
            if (category == AssetCategory.SkeletalMeshes
                && animatedGroups.TryGetValue(group, out var sharedRig)
                && sharedRig.Meshes.Count > 1)
            {
                category = CategoriseGroup(sharedRig);
                owner = group;
                detail = $"shares {group}'s rig · {sharedRig.AnimationCount} anims"
                         + (sharedRig.HasRagdoll ? " · ragdoll" : string.Empty);
            }

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
                Detail = detail ?? Summarise(category, group, export.SerialSize, animatedGroups),
                OwnerGroup = owner,
            });
        }

        return entries;
    }

    /// <summary>
    /// Which bucket an animated group belongs in.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A group is a character if its Havok packfile declares a <b>ragdoll</b> — the game's own
    /// statement that this is something it expects to go limp under physics. That replaced a pair of
    /// magic numbers, <c>AnimationCount >= 20 &amp;&amp; LargestMeshSize > 200_000</c>, which filed
    /// every security turret, the security bot, both security cameras and <c>Ryan</c> as props
    /// because they have two to six animations each.
    /// </para>
    /// <para>
    /// It is a signal, not a proof, and the row's detail says which one it fired on. Breakable
    /// scenery carries a ragdoll too — a slot machine, a wall safe, a flower vase — so those appear
    /// here as well. The alternative was to keep tuning thresholds until the answer looked right,
    /// which is how the browser came to hide the turrets in the first place.
    /// </para>
    /// </remarks>
    private static AssetCategory CategoriseGroup(CharacterEntry character)
    {
        if (character.Group.Contains("PlayerHands", StringComparison.OrdinalIgnoreCase))
            return AssetCategory.FirstPerson;
        if (character.Group.StartsWith("WP_", StringComparison.OrdinalIgnoreCase))
            return AssetCategory.Weapons;

        return character.HasRagdoll
               || (character.AnimationCount >= CharacterAnimationThreshold
                   && character.LargestMeshSize > CharacterMeshSizeThreshold)
            ? AssetCategory.Characters
            : AssetCategory.Props;
    }

    /// <summary>
    /// The cheap row summary, from the export table alone. Textures and materials are described
    /// properly later, once duplicates have been collapsed.
    /// </summary>
    private static string Summarise(
        AssetCategory category, string group, int size, IReadOnlyDictionary<string, CharacterEntry> animated)
    {
        if (category == AssetCategory.Animations && animated.TryGetValue(group, out var owner))
            return $"on {owner.Group}";

        string where = group.Length == 0 ? string.Empty : $"in {group}";
        return $"{Kilobytes(size)} {where}".Trim();
    }

    /// <summary>
    /// Replaces the byte count on texture and material rows with what they actually are.
    /// </summary>
    /// <remarks>
    /// <para>
    /// "4.2 MB" tells nobody whether a texture is the diffuse they want. A texture's format and
    /// dimensions live in the first few kilobytes of its payload and a shader is a few hundred bytes
    /// in total, so neither costs a mip chain to read.
    /// </para>
    /// <para>
    /// This runs <b>after</b> the collapse, not during cataloguing. Enriching every row first meant
    /// reading 44,000 payloads to describe 10,000 assets, and cost four times as much for the same
    /// answer.
    /// </para>
    /// </remarks>
    private static void Enrich(CatalogEntry[] entries, Func<string, string> packageFile, CancellationToken cancellation)
    {
        var wanted = entries
            .Select((entry, index) => (entry, index))
            .Where(pair => pair.entry.Category is AssetCategory.Textures or AssetCategory.Materials)
            .GroupBy(pair => pair.entry.Package, StringComparer.OrdinalIgnoreCase);

        foreach (var byPackage in wanted)
        {
            cancellation.ThrowIfCancellationRequested();

            BioShockPackage package;
            try { package = BioShockPackage.Open(packageFile(byPackage.Key)); }
            catch (Exception ex) when (ex is IOException or InvalidDataException) { continue; }

            using (package)
            {
                foreach (var (entry, index) in byPackage)
                {
                    if (entry.ExportIndex < 0 || entry.ExportIndex >= package.Exports.Count) continue;
                    var export = package.Exports[entry.ExportIndex];

                    string? detail = entry.Category == AssetCategory.Textures
                        ? DescribeTexture(package, export)
                        : DescribeMaterial(package, export);

                    if (detail is null) continue;

                    string suffix = entry.PackageCount > 1 ? $" · in {entry.PackageCount} packages" : string.Empty;
                    entries[index] = entry with { Detail = detail + suffix };
                }
            }
        }
    }

    private static string? DescribeTexture(BioShockPackage package, ObjectExport export)
    {
        var header = TextureReader.ReadHeader(package, export);
        return header is null
            ? "format not understood"
            : $"{header.Value.Width} × {header.Value.Height} · {header.Value.Format}";
    }

    private static string? DescribeMaterial(BioShockPackage package, ObjectExport export)
    {
        var material = MaterialReader.Read(package, export);
        if (material is null) return "could not be read";

        string maps = material.Textures.Count switch
        {
            0 => "no textures",
            1 => "1 texture",
            var n => $"{n} textures",
        };

        // A shader whose property walk stopped early is only partly known, and says so.
        return material.ClassName + " · " + maps + (material.Truncated ? " · partial" : string.Empty);
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
    /// <param name="categories">
    /// Restricts the result to a group of categories, which is what the browser's two workspaces
    /// are: "Everything" inside the rigged workspace means everything rigged, not everything in the
    /// game. Ignored when <paramref name="category"/> names one.
    /// </param>
    public IReadOnlyList<CatalogEntry> Search(
        string? query,
        AssetCategory? category = null,
        string? package = null,
        int limit = 2000,
        IReadOnlySet<AssetCategory>? categories = null)
    {
        // One read of the field, then walk that array. The build thread may publish a new one
        // meanwhile; this call finishes against the catalogue it started with.
        var entries = _entries;

        var results = new List<CatalogEntry>();
        bool hasQuery = !string.IsNullOrWhiteSpace(query);
        string term = query?.Trim() ?? string.Empty;

        foreach (var entry in entries)
        {
            if (category is not null && entry.Category != category) continue;
            if (category is null && categories is not null && !categories.Contains(entry.Category)) continue;
            // A collapsed row belongs to every package that carries it, not only the one it is read
            // from, or filtering by map would hide assets that map genuinely contains.
            if (package is not null && !InPackage(entry, package)) continue;
            if (hasQuery && !Matches(entry, term)) continue;

            results.Add(entry);
            if (results.Count >= limit) break;
        }

        return results;
    }

    private static bool InPackage(CatalogEntry entry, string package) =>
        string.Equals(entry.Package, package, StringComparison.OrdinalIgnoreCase)
        || entry.Packages.Contains(package, StringComparer.OrdinalIgnoreCase);

    /// <summary>
    /// The catalogue row for a named asset, preferring the copy in a given package.
    /// </summary>
    /// <param name="assetName">
    /// The name as another subsystem knows it — a diagnostic's asset, a related asset in the details
    /// panel, an object named by a material. Matched against both the row's display name and its
    /// object name, which differ for a grouped row.
    /// </param>
    /// <param name="preferredPackage">
    /// Where the caller found the reference. The copy in that package wins when the catalogue lists
    /// one; otherwise any row for the same asset is returned, because it is the same asset under a
    /// different map's name.
    /// </param>
    /// <param name="category">Restrict to one category, when the caller knows which it wants.</param>
    /// <returns>The row, or null when the catalogue has none — which is not the same as "no such asset".</returns>
    /// <remarks>
    /// <para>
    /// <b>This is the one place that turns a name into a browsable row.</b> The Problems panel and
    /// the relationship tree both navigate this way; when the logic lived in the view model it was
    /// already duplicated once, and the two copies could disagree about which asset a click opens.
    /// </para>
    /// <para>
    /// <b>A row's <c>Package</c> is not the only package it is in.</b> Every map embeds its own copy
    /// of what it uses, so the catalogue collapses duplicates into one row carrying all of them in
    /// <see cref="CatalogEntry.Packages"/>, and the one it reports is often a different map from the
    /// one the caller is looking at. Matching on name <i>and</i> reported package therefore fails on
    /// real data — it did, on <c>Cheese_Mould_Normal</c> — so this uses the same
    /// <see cref="InPackage"/> rule the search does.
    /// </para>
    /// </remarks>
    public CatalogEntry? Resolve(
        string assetName, string? preferredPackage = null, AssetCategory? category = null)
    {
        if (string.IsNullOrWhiteSpace(assetName)) return null;

        var entries = _entries;
        CatalogEntry? fallback = null;

        foreach (var entry in entries)
        {
            if (category is not null && entry.Category != category) continue;

            if (!string.Equals(entry.ObjectName, assetName, StringComparison.OrdinalIgnoreCase)
                && !string.Equals(entry.Name, assetName, StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            if (preferredPackage is not null && InPackage(entry, preferredPackage)) return entry;
            fallback ??= entry;
        }

        return fallback;
    }

    private static bool Matches(CatalogEntry entry, string term) =>
        entry.Name.Contains(term, StringComparison.OrdinalIgnoreCase)
        || entry.Group.Contains(term, StringComparison.OrdinalIgnoreCase)
        || entry.Packages.Any(p => p.Contains(term, StringComparison.OrdinalIgnoreCase))
        || entry.ClassName.Contains(term, StringComparison.OrdinalIgnoreCase);

    /// <summary>How many entries each category holds, for the browser's tree.</summary>
    public IReadOnlyDictionary<AssetCategory, int> CategoryCounts()
    {
        var counts = new Dictionary<AssetCategory, int>();
        foreach (var entry in _entries)   // one field read; the array itself is never mutated in length
            counts[entry.Category] = counts.GetValueOrDefault(entry.Category) + 1;
        return counts;
    }
}
