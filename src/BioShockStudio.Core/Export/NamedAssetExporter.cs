using System.Text.Json;
using System.Text.Json.Serialization;
using BioShockStudio.Core.Assets;
using BioShockStudio.Core.Level;
using BioShockStudio.Core.Materials;
using BioShockStudio.Core.Mesh;
using BioShockStudio.Core.Packages;
using BioShockStudio.Core.Textures;

namespace BioShockStudio.Core.Export;

/// <summary>
/// Exports named <c>StaticMesh</c> / <c>SkeletalMesh</c> objects found anywhere in the shipped
/// asset index — for stand-ins the level exporter never walked because they live only in class
/// defaults or other packages.
/// </summary>
public static class NamedAssetExporter
{
    public const string ManifestFileName = "assets.json";

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    };

    /// <summary>
    /// Intentionally empty placeholder the game uses when an actor has no real mesh. Confirmed in
    /// <c>ShockAI.U</c>: 5 vertices / 4 triangles / 1 bone — skip rather than import.
    /// </summary>
    public const string NullSkeletalMeshName = "NullSkeletalMesh";

    /// <summary>
    /// Searches the asset index for each name and writes meshes/rigs plus <see cref="ManifestFileName"/>.
    /// </summary>
    public static NamedAssetExportResult Export(
        string gameRoot,
        string outputDirectory,
        IReadOnlyList<string> names,
        AssetIndex? index = null,
        BulkTextureCatalog? bulk = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(gameRoot);
        ArgumentException.ThrowIfNullOrWhiteSpace(outputDirectory);
        ArgumentNullException.ThrowIfNull(names);

        Directory.CreateDirectory(outputDirectory);
        index ??= AssetIndex.Build(gameRoot, AssetClasses.Interesting);
        bulk ??= BulkTextureCatalog.Load(gameRoot);

        var reports = new List<NamedAssetReport>();
        var assets = new List<NamedAssetDocument>();
        var materials = new List<LevelMaterialDocument>();
        var textures = new List<FbxTextureEntry>();
        var seenMaterials = new HashSet<string>(StringComparer.Ordinal);
        var seenTextures = new HashSet<string>(StringComparer.Ordinal);

        foreach (string name in names)
        {
            if (string.IsNullOrWhiteSpace(name)) continue;

            if (string.Equals(name, NullSkeletalMeshName, StringComparison.OrdinalIgnoreCase))
            {
                var nullHits = ExactMeshHits(index, name).ToList();
                string where = nullHits.Count == 0
                    ? "(not in index)"
                    : string.Join(", ", nullHits.Select(h => h.PackageName).Distinct(StringComparer.OrdinalIgnoreCase));
                reports.Add(new NamedAssetReport
                {
                    Name = name,
                    Status = "skipped",
                    Detail = $"intentionally empty placeholder ({where}); confirmed tiny NullSkeletalMesh",
                    Candidates = nullHits.Count,
                });
                continue;
            }

            var hits = ExactMeshHits(index, name).ToList();
            if (hits.Count == 0)
            {
                reports.Add(new NamedAssetReport
                {
                    Name = name,
                    Status = "not-found",
                    Detail = "no StaticMesh/SkeletalMesh with this exact name in the asset index",
                    Candidates = 0,
                });
                continue;
            }

            var chosen = PickCanonical(hits);
            try
            {
                if (chosen.ClassName == AssetClasses.StaticMesh)
                {
                    var (asset, mats, texs) = ExportStatic(chosen, outputDirectory, bulk, seenMaterials, seenTextures);
                    assets.Add(asset);
                    materials.AddRange(mats);
                    textures.AddRange(texs);
                    reports.Add(new NamedAssetReport
                    {
                        Name = name,
                        Status = "exported",
                        Detail = $"StaticMesh from {chosen.PackageName}#{chosen.ExportIndex} → {asset.File}"
                                 + (hits.Count > 1 ? $" (picked among {hits.Count} copies)" : ""),
                        Package = chosen.PackageName,
                        Kind = chosen.ClassName,
                        File = asset.File,
                        Candidates = hits.Count,
                    });
                }
                else
                {
                    var (asset, detail) = ExportSkeletal(chosen, outputDirectory, bulk);
                    assets.Add(asset);
                    reports.Add(new NamedAssetReport
                    {
                        Name = name,
                        Status = "exported",
                        Detail = detail + (hits.Count > 1 ? $" (picked among {hits.Count} copies)" : ""),
                        Package = chosen.PackageName,
                        Kind = chosen.ClassName,
                        File = asset.File,
                        Candidates = hits.Count,
                    });
                }
            }
            catch (Exception ex) when (ex is IOException or InvalidDataException or InvalidOperationException
                                           or ArgumentException or KeyNotFoundException or FileNotFoundException)
            {
                reports.Add(new NamedAssetReport
                {
                    Name = name,
                    Status = "failed",
                    Detail = $"{chosen.ClassName} in {chosen.PackageName}#{chosen.ExportIndex}: {ex.Message}",
                    Package = chosen.PackageName,
                    Kind = chosen.ClassName,
                    Candidates = hits.Count,
                });
            }
        }

        var document = new NamedAssetsDocument
        {
            Assets = assets,
            Materials = materials,
            Textures = textures,
        };
        string manifestPath = Path.Combine(outputDirectory, ManifestFileName);
        File.WriteAllText(manifestPath, JsonSerializer.Serialize(document, JsonOptions));

        return new NamedAssetExportResult
        {
            ManifestPath = manifestPath,
            Document = document,
            Reports = reports,
        };
    }

    private static IEnumerable<AssetRecord> ExactMeshHits(AssetIndex index, string name) =>
        index.Assets.Where(a =>
            string.Equals(a.ObjectName, name, StringComparison.OrdinalIgnoreCase)
            && (a.ClassName == AssetClasses.StaticMesh || a.ClassName == AssetClasses.SkeletalMesh));

    /// <summary>
    /// Largest payload wins (canonical authored copy); ties prefer script packages over maps, then
    /// package name ascending for stability.
    /// </summary>
    public static AssetRecord PickCanonical(IReadOnlyList<AssetRecord> hits) =>
        hits
            .OrderByDescending(h => h.SerialSize)
            .ThenBy(h => IsMapPackage(h.PackageFile) ? 1 : 0)
            .ThenBy(h => h.PackageName, StringComparer.OrdinalIgnoreCase)
            .ThenBy(h => h.ExportIndex)
            .First();

    private static bool IsMapPackage(string packageFile) =>
        packageFile.EndsWith(".bsm", StringComparison.OrdinalIgnoreCase);

    private static (NamedAssetDocument Asset, List<LevelMaterialDocument> Materials, List<FbxTextureEntry> Textures)
        ExportStatic(
            AssetRecord record,
            string outputDirectory,
            BulkTextureCatalog? bulk,
            HashSet<string> seenMaterials,
            HashSet<string> seenTextures)
    {
        using var package = BioShockPackage.Open(record.PackageFile);
        var export = package.Exports[record.ExportIndex];
        byte[] payload = package.ReadExportData(export);
        var geometry = StaticMeshReader.ReadGeometry(payload)
            ?? throw new InvalidDataException(
                $"StaticMesh '{export.ObjectName}' did not decode (serialSize={export.SerialSize}).");

        if (geometry.Vertices.Count == 0)
            throw new InvalidDataException($"StaticMesh '{export.ObjectName}' has no vertices.");

        string relative = LevelSceneExporter.WriteLocalAssetObj(
            outputDirectory, export.ObjectName, export.Index, geometry);

        var slotIds = MaterialReader.ReadMeshMaterialSlots(payload, package)
            .Select(index => Describe(package, index))
            .ToList();

        var materials = new List<LevelMaterialDocument>();
        var textures = new List<FbxTextureEntry>();

        foreach (var id in slotIds)
        {
            if (id is null) continue;
            if (!seenMaterials.Add(id.Value.Key)) continue;
            if (id.Value.ExportIndex < 0 || id.Value.ExportIndex >= package.Exports.Count) continue;

            var resolved = MaterialExporter.ResolveMaterial(
                package, package.Exports[id.Value.ExportIndex], outputDirectory, bulk);
            if (resolved is null) continue;

            materials.Add(LevelSceneExporter.ToMaterialDocument(id.Value, resolved));
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

        var sections = geometry.Sections
            .Select((s, index) => new LevelSectionDocument
            {
                FirstIndex = s.FirstIndex,
                TriangleCount = s.TriangleCount,
                Material = index < slotIds.Count ? slotIds[index]?.ObjectName : null,
                MaterialKey = index < slotIds.Count ? slotIds[index]?.Key : null,
                MaterialPackage = index < slotIds.Count ? slotIds[index]?.Package : null,
                MaterialClassName = index < slotIds.Count ? slotIds[index]?.ClassName : null,
                MaterialExportIndex = index < slotIds.Count ? slotIds[index]?.ExportIndex : null,
            })
            .ToList();

        return (new NamedAssetDocument
        {
            Name = export.ObjectName,
            Package = record.PackageName,
            Kind = AssetClasses.StaticMesh,
            ExportIndex = export.Index,
            File = relative,
            VertexCount = geometry.Vertices.Count,
            TriangleCount = geometry.TriangleCount,
            Sections = sections,
        }, materials, textures);
    }

    private static (NamedAssetDocument Asset, string Detail) ExportSkeletal(
        AssetRecord record,
        string outputDirectory,
        BulkTextureCatalog? bulk)
    {
        using var package = BioShockPackage.Open(record.PackageFile);
        var export = package.Exports[record.ExportIndex];
        byte[] payload = package.ReadExportData(export);
        var geometry = SkeletalMeshReader.ReadGeometry(payload, package.Names)
            ?? throw new InvalidDataException(
                $"SkeletalMesh '{export.ObjectName}' did not decode (serialSize={export.SerialSize}).");

        if (geometry.Vertices.Count == 0)
            throw new InvalidDataException($"SkeletalMesh '{export.ObjectName}' has no vertices.");

        string? wrapperName = FindWrapperName(package, export.ObjectName);
        if (wrapperName is null)
            throw new InvalidOperationException(
                $"no AnimationPackageWrapper (UAPW_*) found for '{export.ObjectName}' in {record.PackageName}");

        var wrapper = package.Exports
            .Where(e => string.Equals(e.ObjectName, wrapperName, StringComparison.OrdinalIgnoreCase)
                        && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
            .MaxBy(e => e.SerialSize)
            ?? throw new FileNotFoundException(
                $"AnimationPackageWrapper '{wrapperName}' missing in {record.PackageName}.");

        var animationPackage = AnimationPackage.Load(package, wrapper);
        var sockets = SkeletalMeshReader.ReadSockets(payload, package.Names);
        string rigDirectory = Path.Combine(outputDirectory, "Rigs", export.ObjectName);
        Directory.CreateDirectory(rigDirectory);

        var material = MaterialExporter.Resolve(package, export, rigDirectory, bulk);
        var events = ResolveEvents(package, animationPackage);
        var scene = AnimationSceneExporter.Build(
            animationPackage, ownerFilter: null, sockets, geometry, events, material);
        FbxExporter.Write(scene, rigDirectory);

        string relative = "Rigs/" + export.ObjectName;
        var slotIds = MaterialReader.ReadMeshMaterialSlots(payload, package)
            .Select(index => Describe(package, index))
            .ToList();
        var sections = geometry.Sections
            .Select((s, index) => new LevelSectionDocument
            {
                FirstIndex = s.FirstIndex,
                TriangleCount = s.TriangleCount,
                Material = index < slotIds.Count ? slotIds[index]?.ObjectName : null,
                MaterialKey = index < slotIds.Count ? slotIds[index]?.Key : null,
                MaterialPackage = index < slotIds.Count ? slotIds[index]?.Package : null,
                MaterialClassName = index < slotIds.Count ? slotIds[index]?.ClassName : null,
                MaterialExportIndex = index < slotIds.Count ? slotIds[index]?.ExportIndex : null,
            })
            .ToList();

        return (new NamedAssetDocument
        {
            Name = export.ObjectName,
            Package = record.PackageName,
            Kind = AssetClasses.SkeletalMesh,
            ExportIndex = export.Index,
            File = relative,
            VertexCount = geometry.Vertices.Count,
            TriangleCount = geometry.TriangleCount,
            Sections = sections,
            Group = AssetContextResolver.TopLevelGroup(package, export),
        }, $"SkeletalMesh from {record.PackageName}#{export.Index} via {wrapperName} → {relative}/");
    }

    private static string? FindWrapperName(BioShockPackage package, string meshName)
    {
        foreach (var entry in CharacterCatalog.Find(package))
        {
            if (entry.Meshes.Any(m => string.Equals(m, meshName, StringComparison.OrdinalIgnoreCase)))
                return entry.AnimationPackageObject;
        }

        string guess = "UAPW_" + meshName;
        return package.Exports.Any(e =>
            string.Equals(e.ObjectName, guess, StringComparison.OrdinalIgnoreCase)
            && package.GetClassName(e) == AssetClasses.AnimationPackageWrapper)
            ? guess
            : null;
    }

    private static IReadOnlyDictionary<string, IReadOnlyList<AnimationEvent>> ResolveEvents(
        BioShockPackage package, AnimationPackage animationPackage)
    {
        var metadata = package.Exports
            .Where(e => package.GetClassName(e) == AnimationMetadataReader.ClassName)
            .GroupBy(e => e.ObjectName, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(g => g.Key, g => g.First(), StringComparer.OrdinalIgnoreCase);

        var result = new Dictionary<string, IReadOnlyList<AnimationEvent>>(StringComparer.Ordinal);
        foreach (var animation in animationPackage.Animations)
        {
            if (!metadata.TryGetValue(AnimationMetadataReader.ObjectPrefix + animation.Name, out var export))
                continue;
            var events = AnimationMetadataReader.ReadEvents(package, export, animation.Duration);
            if (events.Count > 0) result[animation.Name] = events;
        }

        return result;
    }

    private static SourceId? Describe(BioShockPackage package, PackageIndex index)
    {
        if (!index.IsExport || index.ExportIndex >= package.Exports.Count) return null;
        var export = package.Exports[index.ExportIndex];
        return new SourceId(
            Path.GetFileNameWithoutExtension(package.FilePath),
            export.Index, package.GetClassName(export), export.ObjectName);
    }
}

public sealed record NamedAssetExportResult
{
    public required string ManifestPath { get; init; }
    public required NamedAssetsDocument Document { get; init; }
    public required IReadOnlyList<NamedAssetReport> Reports { get; init; }
}

public sealed record NamedAssetReport
{
    public required string Name { get; init; }
    public required string Status { get; init; }
    public required string Detail { get; init; }
    public string? Package { get; init; }
    public string? Kind { get; init; }
    public string? File { get; init; }
    public int Candidates { get; init; }
}

public sealed record NamedAssetsDocument
{
    public required List<NamedAssetDocument> Assets { get; init; }
    public required List<LevelMaterialDocument> Materials { get; init; }
    public required List<FbxTextureEntry> Textures { get; init; }
}

public sealed record NamedAssetDocument
{
    public required string Name { get; init; }
    public required string Package { get; init; }
    public required string Kind { get; init; }
    public required int ExportIndex { get; init; }
    public string? File { get; init; }
    public required int VertexCount { get; init; }
    public required int TriangleCount { get; init; }
    public required List<LevelSectionDocument> Sections { get; init; }
    public string? Group { get; init; }
}
